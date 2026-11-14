import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/simulation/v2/local_paths.dart';
import 'package:barrio_cero_eras/presentation/local_work.dart';
import 'package:barrio_cero_eras/presentation/world_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final content =
      jsonDecode(File('assets/content/core.json').readAsStringSync())
          as Map<String, dynamic>;
  WorldState scenario({bool local = true}) {
    final world = WorldState.generate(
      seed: 73,
      size: 64,
      origin: 'prehistory',
      geographyVersion: 2,
    )..controlledId = null;
    if (local) {
      for (final s in world.societies) {
        s.localLife = LocalLife(0)
          ..advance(
            0,
            [for (final p in s.people) p.toJson()],
            [for (final b in s.sites) b.toJson()],
          );
      }
    }
    return world;
  }

  test('Walking residents do not move the city marker', () {
    final world = scenario(), game = WorldGame((_) {});
    addTearDown(game.terrainCache.clear);
    game.present(world.toJson(), generation: 1);
    final before = game.position(game.societies.first);
    (Simulation(world)..registerContent(content)).advanceDays(1);
    game.present(world.toJson(), generation: 1);
    expect(game.position(game.societies.first), before);
  });
  test(
    'Residents move on clear neighboring cells; saving preserves intent',
    () {
      final world = scenario(), s = world.societies.first;
      final initial = s.localLife!.toJson();
      final sim = Simulation(world)..registerContent(content);
      for (var day = 0; day < 90; day++) {
        sim.advanceDays(1);
        final grid = LocalPaths([for (final b in s.sites) b.toJson()]);
        for (final r in s.localLife!.residents.values) {
          expect(grid.free(r.cell), isTrue);
          expect(grid.distance(r.previous, r.cell), lessThanOrEqualTo(1));
        }
      }
      expect(s.localLife!.toJson(), isNot(initial));
      final restored = WorldState.fromJson(world.toJson());
      final next = Simulation(restored)..registerContent(content);
      sim.advanceDays(270);
      next.advanceDays(270);
      expect(restored.canonical(), world.canonical());
      world.validate();
    },
  );
  test(
    'Local visits consume no simulation randomness or economic quantities',
    () {
      final moving = scenario(), legacy = scenario(local: false);
      (Simulation(moving)..registerContent(content)).advanceDays(360);
      (Simulation(legacy)..registerContent(content)).advanceDays(360);
      final raw = moving.toJson();
      for (final s in raw['societies']) {
        s.remove('localLife');
      }
      expect(jsonEncode(raw), legacy.canonical());
    },
  );
  test(
    'Collective crews stay within real common adults and allocated labor',
    () {
      final world = scenario();
      (Simulation(world)..registerContent(content)).advanceDays(30);
      final raw = world.toJson(), before = world.canonical();
      for (final s in raw['societies']) {
        final view = LocalWorkday.read(raw, Map<String, dynamic>.from(s));
        final grid = LocalPaths((s['sites'] as List).cast<Map>());
        expect(
          view.crews.fold<int>(0, (n, c) => n + c.adults),
          lessThanOrEqualTo(view.commonAdults),
        );
        final allocations = s['lastProduction']['flows']['allocations'] as Map;
        final used = <String, int>{};
        for (final crew in view.crews) {
          used.update(
            crew.building,
            (n) => n + crew.laborMillis,
            ifAbsent: () => crew.laborMillis,
          );
          expect(crew.route.every(grid.free), isTrue);
          for (var i = 1; i < crew.route.length; i++) {
            expect(grid.distance(crew.route[i - 1], crew.route[i]), 1);
          }
          if (crew.route.length > 1) {
            expect(
              {
                for (var frame = 0; frame < 24; frame++)
                  crew.position(frame * .5),
              }.length,
              greaterThan(1),
            );
          }
        }
        for (final e in used.entries) {
          expect(e.value, lessThanOrEqualTo(allocations[e.key]));
        }
      }
      expect(world.canonical(), before);
    },
  );
  test(
    'Unknown life versions, teleporting routes and deceased actors rejected',
    () {
      expect(
        () => LocalLife.fromJson({'version': 2, 'day': 0, 'residents': []}),
        throwsFormatException,
      );
      final world = scenario(), raw = world.toJson();
      raw['societies'][0]['localLife']['residents'][0]['route'] = [0, 100];
      expect(() => WorldState.fromJson(raw), throwsFormatException);
      final s = world.societies.first, dead = s.people.first;
      dead.diedDay = world.day;
      s.localLife!.advance(
        world.day,
        [
          for (final p in s.people)
            if (p.alive) p.toJson(),
        ],
        [for (final b in s.sites) b.toJson()],
      );
      expect(s.localLife!.residents.containsKey(dead.id), isFalse);
    },
  );
}
