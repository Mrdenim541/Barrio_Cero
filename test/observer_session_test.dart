import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/session/session_controller.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

class ObserverStore {
  final values = <String, String>{};
  bool fail = false;
  int writes = 0;
  Future<String?> read(String key, {bool backup = false}) async => values[key];
  Future<void> write(String key, String value) async {
    if (fail) throw const FileSystemException('Disco lleno');
    values[key] = value;
    writes++;
  }
}

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  late ObserverStore store;
  late SessionController session;
  setUp(() {
    store = ObserverStore();
    session = SessionController(
      read: store.read,
      write: store.write,
      loadCore: () async => core,
    );
  });
  tearDown(() => session.dispose());

  test(
    'A year with zero player orders builds and researches; inspecting every community changes nothing',
    () async {
      final otherStore = ObserverStore();
      final other = SessionController(
        read: otherStore.read,
        write: otherStore.write,
        loadCore: () async => core,
      );
      addTearDown(other.dispose);
      await session.createWorld(
        seed: 17,
        size: 64,
        origin: 'prehistory',
        extraordinary: false,
      );
      await other.createWorld(
        seed: 17,
        size: 64,
        origin: 'prehistory',
        extraordinary: false,
      );
      expect(session.worldCopy()!.controlledId, isNull);
      expect(session.stopCrisis, isFalse);
      final initial = session.worldCopy()!;
      final buildingsBefore = initial.societies.fold<int>(
        0,
        (n, s) => n + s.sites.length,
      );
      for (var month = 0; month < 12; month++) {
        final current = session.worldCopy()!;
        final before = current.canonical();
        session.previewIntervention(
          Command(
            id: 'inspection-$month',
            action: 'build',
            actorId: 's${month % 6}',
            issuedDay: current.day,
            target: 'shelter',
          ),
        );
        expect(session.worldCopy()!.canonical(), before);
        expect(await session.advance(30), 30);
        expect(await other.advance(30), 30);
        expect(
          session.worldCopy()!.canonical(),
          other.worldCopy()!.canonical(),
        );
      }
      final world = session.worldCopy()!;
      world.validate();
      expect(world.day, 360);
      expect(world.commandReceipts, isEmpty);
      expect(
        world.societies.fold<int>(0, (n, s) => n + s.sites.length),
        greaterThan(buildingsBefore),
      );
      expect(world.societies.any((s) => s.tech.isNotEmpty), isTrue);
      for (final town in world.societies) {
        expect(
          world.chronicle.any((e) => e.societyId == town.id),
          isTrue,
          reason: '${town.name} must act without player approval',
        );
      }
    },
  );

  test(
    'Intervention pays only its actor, preserves autonomous government and replays once',
    () async {
      await session.createWorld(seed: 17, size: 64, origin: 'prehistory');
      final initial = session.worldCopy()!;
      const request = Command(
        id: 'foreign-refuge',
        action: 'build',
        actorId: 's1',
        issuedDay: 0,
        target: 'shelter',
      );
      final quote = session.previewIntervention(request);
      expect(quote.allowed, isTrue);
      expect(quote.costs, {'wood': 8, 'stone': 2});
      expect(session.worldCopy()!.canonical(), initial.canonical());
      expect((await session.submitIntervention(request)).ok, isTrue);
      final committed = session.worldCopy()!;
      expect(committed.controlledId, isNull);
      expect(
        committed.society('s1')!.resources['wood'],
        initial.society('s1')!.resources['wood']! - 8,
      );
      expect(committed.society('s1')!.projects.single.building, 'shelter');
      expect(
        committed.society('s0')!.toJson(),
        initial.society('s0')!.toJson(),
      );
      final writes = store.writes;
      expect((await session.submitIntervention(request)).replayed, isTrue);
      expect(store.writes, writes);
      expect(session.worldCopy()!.canonical(), committed.canonical());
      await session.advance(30);
      expect(session.worldCopy()!.controlledId, isNull);
      expect(
        session.worldCopy()!.society('s1')!.sites.length,
        greaterThan(initial.society('s1')!.sites.length),
      );
    },
  );

  test(
    'Invalid, stale, conflicting and takeover interventions cannot change state',
    () async {
      await session.createWorld(seed: 17, size: 64, origin: 'prehistory');
      const valid = Command(
        id: 'once',
        action: 'build',
        actorId: 's0',
        issuedDay: 0,
        target: 'shelter',
      );
      expect((await session.submitIntervention(valid)).ok, isTrue);
      final before = session.worldCopy()!.canonical();
      final writes = store.writes;
      for (final request in [
        const Command(
          id: 'invalid',
          action: 'build',
          actorId: 's0',
          issuedDay: 0,
          target: 'missing',
        ),
        const Command(
          id: 'takeover',
          action: 'control',
          actorId: 's0',
          issuedDay: 0,
          target: 's1',
        ),
        const Command(
          id: 'stale',
          action: 'build',
          actorId: 's0',
          issuedDay: 1,
          target: 'shelter',
        ),
        const Command(
          id: 'once',
          action: 'build',
          actorId: 's1',
          issuedDay: 0,
          target: 'shelter',
        ),
        const Command(
          id: 'absent',
          action: 'build',
          actorId: 'missing',
          issuedDay: 0,
          target: 'shelter',
        ),
      ]) {
        expect(session.previewIntervention(request).allowed, isFalse);
        expect((await session.submitIntervention(request)).ok, isFalse);
        expect(session.worldCopy()!.canonical(), before);
        expect(store.writes, writes);
      }
    },
  );

  test(
    'A failed durable intervention leaves no receipt, payment or takeover',
    () async {
      await session.createWorld(seed: 17, size: 64, origin: 'prehistory');
      final snapshot = session.snapshot;
      final stored = store.values['world_0'];
      store.fail = true;
      await expectLater(
        session.intervene('s0', 'build', target: 'shelter'),
        throwsA(isA<FileSystemException>()),
      );
      expect(session.snapshot, same(snapshot));
      expect(store.values['world_0'], stored);
      expect(session.worldCopy()!.controlledId, isNull);
      expect(session.worldCopy()!.commandReceipts, isEmpty);
    },
  );

  test('A queued intervention cannot cross into a different imported world', () async {
    await session.createWorld(seed:17,size:64,origin:'prehistory');
    final snapshot=session.snapshot!;
    final replacement=WorldState.generate(seed:18,size:64,origin:'prehistory')..controlledId=null;
    final source=Checkpoint.create(world:replacement,coreSource:core).encode();
    final importing=session.importCheckpoint(source);
    final intervening=session.intervene('s0','build',target:'shelter',
        expectedGeneration:snapshot.generation,expectedRevision:snapshot.revision);
    await importing;
    expect((await intervening).code,'stale_session');
    expect(session.worldCopy()!.canonical(),Checkpoint.decode(source).world.canonical());
    expect(session.worldCopy()!.commandReceipts,isEmpty);
  });

  test(
    'Loading preserves a manual save; explicit observation returns its pending decision exactly once',
    () async {
      final world = WorldState.generate(
        seed: 17,
        size: 64,
        origin: 'prehistory',
        extraordinary: false,
      );
      world.pending.add(
        ScheduledEvent(
          'waiting',
          'content_choice',
          's0',
          3600000,
          data: {'eventId': 'prehistoric_reserves'},
        ),
      );
      final source = Checkpoint.create(world: world, coreSource: core).encode();
      store.values['world_0'] = source;
      await session.loadSlot(0);
      expect(store.values['world_0'], source);
      expect(session.worldCopy()!.controlledId, 's0');
      await session.observe();
      final handed = session.worldCopy()!;
      expect(handed.controlledId, isNull);
      expect(session.stopCrisis, isFalse);
      expect(handed.pending.single.type, 'content');
      expect(handed.pending.single.day, 1);
      expect(handed.pending.single.data['previousChoiceDay'], 3600000);
      expect(
        handed.societies.map((s) => s.resources),
        world.societies.map((s) => s.resources),
      );
      expect(await session.advance(1), 1);
      final resolved = session.worldCopy()!;
      expect(resolved.pending.any((e) => e.id == 'waiting'), isFalse);
      expect(resolved.contentHistory['s0:prehistoric_reserves'], 1);
      expect(
        resolved.society('s0')!.flags.contains('prehistoric_reserved') ||
            resolved.society('s0')!.morale > world.society('s0')!.morale + 4,
        isTrue,
        reason:
            'The council must apply a real option, not merely remove the pending card',
      );
      await session.advance(1);
      expect(session.worldCopy()!.contentHistory['s0:prehistoric_reserves'], 1);
      final reopened = Checkpoint.decode(store.values['world_0']!);
      expect(reopened.world.canonical(), session.worldCopy()!.canonical());
      expect(reopened.world.controlledId, isNull);
    },
  );
}
