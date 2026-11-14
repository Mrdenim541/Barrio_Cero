import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/session/history_worker.dart';
import 'package:barrio_cero_eras/session/session_controller.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

class MemoryStore {
  final values = <String, String>{};
  final writes = <String>[];
  Completer<void>? gate;
  Completer<void>? entered;
  bool fail = false;
  Future<String?> read(String slot, {bool backup = false}) async =>
      values['$slot${backup ? '.backup' : ''}'];
  Future<void> write(String slot, String value) async {
    entered?.complete();
    entered = null;
    await gate?.future;
    if (fail) throw const FileSystemException('disco lleno');
    values[slot] = value;
    writes.add(slot);
  }
}

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  final addon = File('assets/content/example_pack.json').readAsStringSync();
  late MemoryStore store;
  late SessionController session;
  setUp(() {
    store = MemoryStore();
    session = SessionController(
      read: store.read,
      write: store.write,
      loadCore: () async => core,
    );
  });
  tearDown(() => session.dispose());
  Checkpoint fixture(int seed) => Checkpoint.create(
    world: WorldState.generate(seed: seed, size: 64),
    coreSource: core,
  );

  test(
    'publication waits for durable write; snapshots and copies cannot mutate authority',
    () async {
      store.gate = Completer();
      store.entered = Completer();
      final entered = store.entered!.future;
      final operation = session.createWorld(autonomous: false, seed: 11, size: 64, slot: 2);
      await entered;
      expect(session.busy, isTrue);
      expect(session.snapshot, isNull);
      expect(session.slot, 0);
      store.gate!.complete();
      await operation;
      expect(session.snapshot!.slot, 2);
      expect(session.busy, isFalse);
      expect(() => session.snapshot!.world['day'] = 2, throwsUnsupportedError);
      expect(
        () => (session.snapshot!.world['societies'] as List).clear(),
        throwsUnsupportedError,
      );
      session.worldCopy()!.day = 99;
      expect(session.worldCopy()!.day, 0);
    },
  );

  test(
    'failed import preserves world and slot; queued save cannot overwrite imported world',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      final before = session.snapshot;
      store.fail = true;
      await expectLater(
        session.importCheckpoint(fixture(22).encode(), destinationSlot: 1),
        throwsA(isA<FileSystemException>()),
      );
      expect(session.snapshot, same(before));
      expect(session.slot, 0);
      store.fail = false;
      // Simulates lifecycle autosaves issued before and after an import request.
      final savedBefore = session.save();
      final imported = session.importCheckpoint(
        fixture(22).encode(),
        destinationSlot: 1,
      );
      final savedAfter = session.save();
      await Future.wait([savedBefore, imported, savedAfter]);
      expect(Checkpoint.decode(store.values['world_0']!).world.seed, 11);
      expect(Checkpoint.decode(store.values['world_1']!).world.seed, 22);
      expect(session.slot, 1);
      expect(session.worldCopy()!.seed, 22);
    },
  );

  test(
    'loads switch slot and world together and recover valid backup',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      store.values['world_2'] = 'corrupt';
      store.values['world_2.backup'] = fixture(33).encode();
      final result = await session.loadSlot(2);
      expect(result.recovered, isTrue);
      expect(session.snapshot!.slot, 2);
      expect(session.worldCopy()!.seed, 33);
      final snapshot = session.snapshot;
      expect((await session.loadSlot(1)).found, isFalse);
      expect(session.snapshot, same(snapshot));
      await expectLater(
        session.importCheckpoint('{}', destinationSlot: 0),
        throwsFormatException,
      );
      expect(session.snapshot, same(snapshot));
    },
  );

  test(
    'rejection does not persist and replay does not double-charge',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      final count = store.writes.length;
      final rejected = await session.command('build', target: 'missing');
      expect(rejected.ok, isFalse);
      expect(store.writes.length, count);
      final world = session.worldCopy()!;
      final request = Command(
        id: 'test-order',
        action: 'explore',
        actorId: world.controlledId,
        issuedDay: world.day,
      );
      final accepted = await session.submit(request);
      expect(accepted.ok, isTrue);
      final committed = session.worldCopy()!.canonical();
      final savedCount = store.writes.length;
      expect((await session.submit(request)).replayed, isTrue);
      expect(session.worldCopy()!.canonical(), committed);
      expect(store.writes.length, savedCount);
    },
  );

  test(
    'package import commits registry before exposing it and never changes active pins',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      final pins = Map.of(session.worldCopy()!.contentVersions);
      store.fail = true;
      await expectLater(
        session.importPackage(addon),
        throwsA(isA<FileSystemException>()),
      );
      expect(session.availablePackSources, isEmpty);
      store.fail = false;
      await session.importPackage(addon);
      expect(session.availablePackSources, [addon]);
      expect(session.worldCopy()!.contentVersions, pins);
      await expectLater(session.importPackage(addon), throwsFormatException);
      expect(session.availablePackSources, hasLength(1));
    },
  );

  test(
    'history rejects stale revisions and foreign sessions; failed writes preserve last commit',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      final lease = await session.beginHistory(1);
      final candidate = WorldState.fromJson(lease.snapshot.world);
      Simulation(candidate).advanceDays(1);
      final before = session.snapshot;
      store.fail = true;
      await expectLater(
        session.commitHistoryBatch(lease, candidate.toJson(), done: false),
        throwsA(isA<FileSystemException>()),
      );
      expect(session.snapshot, same(before));
      store.fail = false;
      final next = (await session.commitHistoryBatch(
        lease,
        candidate.toJson(),
        done: false,
      ))!;
      await expectLater(
        session.commitHistoryBatch(lease, candidate.toJson(), done: true),
        throwsStateError,
      );
      await expectLater(session.advance(1), throwsStateError);
      expect(
        await session.commitHistoryBatch(next, candidate.toJson(), done: true),
        isNull,
      );
      expect(session.snapshot!.target, 360);
      expect(session.busy, isFalse);
      final resumed = await session.beginHistory(1, resume: true);
      await session.createWorld(autonomous: false, seed: 44, size: 64, slot: 1);
      await expectLater(
        session.commitHistoryBatch(resumed, candidate.toJson(), done: true),
        throwsStateError,
      );
      expect(session.worldCopy()!.seed, 44);
    },
  );

  test(
    'settings and advances are confirmed together; previous branch is recoverable',
    () async {
      await session.createWorld(autonomous: false, seed: 11, size: 64);
      await session.updateSettings(sound: true, stopCrisis: false);
      expect(await session.advance(1), 1);
      final saved = Checkpoint.decode(await session.exportCurrent());
      expect(saved.world.day, 1);
      expect(saved.settings['sound'], isTrue);
      expect(saved.stopCrisis, isFalse);
      final lease = await session.beginHistory(1);
      await session.endHistory(lease);
      await session.advance(1);
      expect((await session.restorePreviousBranch()).accepted, isTrue);
      expect(session.worldCopy()!.day, 1);
      expect(session.snapshot!.target, isNull);
      await session.returnToWelcome();
      expect(session.snapshot, isNull);
    },
  );

  test(
    'legacy conversion requires consent and preserves exact original',
    () async {
      final cp = fixture(11);
      final oldWorld = cp.world.toJson();
      final raw = jsonEncode({
        'format': 'barrio-cero-save',
        'version': 1,
        'world': oldWorld,
        'sha256': sha256.convert(utf8.encode(jsonEncode(oldWorld))).toString(),
        'packs': [],
        'target': null,
        'stopCrisis': true,
        'settings': {},
      });
      final declined = await session.importCheckpoint(
        raw,
        destinationSlot: 2,
        acceptLegacy: () async => false,
      );
      expect(declined.accepted, isFalse);
      expect(store.writes, isEmpty);
      expect(session.snapshot, isNull);
      final accepted = await session.importCheckpoint(
        raw,
        destinationSlot: 2,
        acceptLegacy: () async => true,
      );
      expect(accepted.migrated, isTrue);
      expect(store.values['legacy_2'], raw);
      expect(Checkpoint.decode(store.values['world_2']!).world.seed, 11);
    },
  );

  test(
    'Legacy prototype resolves its exact archived core after a catalog update',
    () async {
      final oldCore = File(
        'assets/content/legacy_core_1.json',
      ).readAsStringSync();
      final w = WorldState.generate(size: 64, fixedMaterials: false);
      w.contentVersions = {'core': '1.0.0'};
      final oldWorld = Checkpoint.create(
        world: w,
        coreSource: oldCore,
      ).world.toJson();
      final raw = jsonEncode({
        'format': 'barrio-cero-save',
        'version': 1,
        'world': oldWorld,
        'sha256': sha256.convert(utf8.encode(jsonEncode(oldWorld))).toString(),
      });
      final expectedHash = sha256.convert(utf8.encode(oldCore)).toString();
      final upgraded = SessionController(
        read: store.read,
        write: store.write,
        loadCore: () async => core,
        resolveLegacyCore: (hash) async =>
            hash == expectedHash ? oldCore : null,
      );
      await upgraded.initialize();
      final result = await upgraded.importCheckpoint(
        raw,
        acceptLegacy: () async => true,
      );
      expect(result.migrated, isTrue);
      expect(upgraded.snapshot!.coreSource, oldCore);
      expect(upgraded.worldCopy()!.rulesVersion, 1);
      expect(store.values['legacy_0'], raw);
      final missing = SessionController(
        read: store.read,
        write: store.write,
        loadCore: () async => core,
      );
      await missing.initialize();
      final before = Map.from(store.values);
      await expectLater(
        missing.importCheckpoint(raw, acceptLegacy: () async => true),
        throwsFormatException,
      );
      expect(store.values, before);
    },
  );

  test(
    'initialization caches source load and reports invalid registry without editing it',
    () async {
      store.values['packages'] = '[42]';
      expect(identical(session.initialize(), session.initialize()), isTrue);
      await session.initialize();
      expect(session.registryWarning, isNotNull);
      expect(session.availablePackSources, isEmpty);
      expect(store.values['packages'], '[42]');
    },
  );

  test(
    'worker cancellation does not acknowledge pending batch and final batch waits for ack',
    () async {
      final port = ReceivePort();
      final iterator = StreamIterator<dynamic>(port);
      final exits = ReceivePort();
      var exited = false;
      exits.listen((_) => exited = true);
      final world = fixture(11);
      final worker = await Isolate.spawn(historyWorker, {
        'port': port.sendPort,
        'world': world.world.toJson(),
        'content': world.content,
        'target': 360,
        'stop': false,
      }, onExit: exits.sendPort);
      try {
        await iterator.moveNext();
        final control = iterator.current['control'] as SendPort;
        await iterator.moveNext();
        final batch = iterator.current as Map;
        expect(batch['done'], isFalse);
        control.send('cancel');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(exited, isFalse);
        control.send('ack');
        await iterator.moveNext();
        final finalBatch = iterator.current as Map;
        expect(finalBatch['done'], isTrue);
        expect(finalBatch['cancelled'], isTrue);
        expect(finalBatch['world'], batch['world']);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(exited, isFalse);
        control.send('ack');
      } finally {
        worker.kill(priority: Isolate.immediate);
        await iterator.cancel();
        port.close();
        exits.close();
      }
    },
  );
}
