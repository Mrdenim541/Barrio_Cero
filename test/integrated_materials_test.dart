import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/simulation/v2/inventory.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  test(
    'New inventory stores integers, payments survive checkpoint and replay once',
    () {
      final w = WorldState.generate(seed: 17, size: 64);
      final sim = Simulation(w);
      final c = Command(
        id: 'build',
        action: 'build',
        actorId: w.controlledId,
        issuedDay: 0,
        target: 'farm',
      );
      expect(w.controlled.resources, isA<FixedInventory>());
      expect(sim.submit(c).ok, isTrue);
      expect(sim.submit(c).replayed, isTrue);
      expect(w.controlled.resources['wood'], 80);
      expect(w.controlled.projects.length, 1);
      final saved = Checkpoint.create(world: w, coreSource: core).encode();
      final restored = Checkpoint.decode(saved).world;
      expect(restored.commandReceipts['build']!['materials'], isNotEmpty);
      expect(restored.controlled.resources['wood'], 80);
      expect(Simulation(restored).submit(c).replayed, isTrue);
    },
  );
  test(
    'Rejected requests leave all integer balances, workers and audit intact',
    () {
      final w = WorldState.generate(size: 64);
      w.controlled.resources['wood'] = 0;
      final before = w.canonical();
      final result = Simulation(w).submit(
        Command(
          id: 'fail',
          action: 'build',
          actorId: w.controlledId,
          issuedDay: 0,
          target: 'farm',
        ),
      );
      expect(result.ok, isFalse);
      expect(w.canonical(), before);
    },
  );
  test(
    'Integer resources remain canonical across daily, batches and saves',
    () {
      final initial = WorldState.generate(seed: 17, size: 64).toJson();
      final a = WorldState.fromJson(initial), b = WorldState.fromJson(initial);
      final sa = Simulation(a);
      for (var i = 0; i < 1080; i++) {
        sa.advanceDays(1);
      }
      var resumed = b;
      for (var day = 0; day < 1080; day += 37) {
        Simulation(resumed).advanceDays(min(37, 1080 - day));
        resumed = Checkpoint.decode(
          Checkpoint.create(world: resumed, coreSource: core).encode(),
        ).world;
      }
      // Bind exactly the same content pins before comparing the worlds.
      final pinned = Checkpoint.create(world: a, coreSource: core).world;
      expect(resumed.canonical(), pinned.canonical());
      for (final s in resumed.societies) {
        expect(
          (s.toJson()['resourceMillis'] as Map).values.every((v) => v is int),
          isTrue,
        );
      }
    },
  );
  test('Legacy resource rules round trip without new keys or quantization', () {
    final w = WorldState.generate(size: 64, fixedMaterials: false);
    w.controlled.resources['food'] = 123.123456789;
    final original = w.toJson();
    final restored = WorldState.fromJson(jsonDecode(jsonEncode(original)));
    expect(restored.toJson(), original);
    expect(restored.controlled.toJson().containsKey('resourceMillis'), isFalse);
    expect(restored.controlled.resources['food'], 123.123456789);
  });
  test('Tampered integer balance and payment history are rejected', () {
    final w = WorldState.generate(size: 64);
    final sim = Simulation(w);
    sim.submit(
      Command(
        id: 'build',
        action: 'build',
        actorId: w.controlledId,
        issuedDay: 0,
        target: 'farm',
      ),
    );
    final mismatch = jsonDecode(jsonEncode(w.toJson()));
    mismatch['societies'][0]['resourceMillis']['food'] += 1;
    expect(() => WorldState.fromJson(mismatch), throwsFormatException);
    final bad = jsonDecode(jsonEncode(w.toJson()));
    bad['commandReceipts']['build']['materials'][0]['ledger']['accounts']['inventory']['wood'] +=
        1;
    expect(() => WorldState.fromJson(bad), throwsFormatException);
  });
  test(
    'Demographic remainders and PRNG rule version are persisted and validated',
    () {
      final w = WorldState.generate(size: 64);
      Simulation(w).advanceDays(360);
      final raw = jsonDecode(jsonEncode(w.toJson()));
      expect(raw['rulesVersion'], WorldState.currentRules);
      expect(raw['randomAlgorithm'], 'lcg31-v1');
      expect(
        (raw['societies'][0]['demographicMicros'] as Map).values.every(
          (v) => v is int && v >= 0 && v < 1000000,
        ),
        isTrue,
      );
      raw['societies'][0]['demographicMicros']['grown'] = 1000000;
      expect(() => WorldState.fromJson(raw), throwsFormatException);
    },
  );
  test(
    'Advance reports actual endpoint and rejects bad requests without mutation',
    () {
      final w = WorldState.generate(size: 64);
      final sim = Simulation(w);
      final before = w.canonical();
      expect(
        () => sim.advance(const AdvanceRequest(days: -1)),
        throwsRangeError,
      );
      expect(w.canonical(), before);
      final result = sim.advance(const AdvanceRequest(days: 3));
      expect(result.advancedDays, 3);
      expect(result.reachedDay, 3);
      expect(result.stop, AdvanceStop.completed);
      for (final s in w.societies) {
        s.children = 0;
        s.adults = 0;
        s.elders = 0;
        s.extinct = true;
      }
      final ended = sim.advance(const AdvanceRequest(days: 10));
      expect(ended.advancedDays, 0);
      expect(ended.stop, AdvanceStop.extinct);
    },
  );
}
