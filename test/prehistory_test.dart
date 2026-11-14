import '../tool/fixtures.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  final source = File('assets/content/core.json').readAsStringSync();
  final content = jsonDecode(source) as Map<String, dynamic>;
  WorldState start({int seed = 17, int size = 64}) => WorldState.generate(
    seed: seed,
    size: size,
    origin: 'prehistory',
    extraordinary: false,
  );

  test(
    'Thirty seeds start with viable terrain and real primitive inventories',
    () {
      for (var seed = 1; seed <= 30; seed++) {
        final w = start(seed: seed, size: seed.isEven ? 64 : 96);
        final locations = <int>{};
        for (final s in w.societies) {
          final tile = w.tiles[s.y * w.size + s.x];
          expect(locations.add(s.y * w.size + s.x), isTrue);
          expect([0, 1, 4], contains(tile.biome));
          expect(tile.richness, greaterThanOrEqualTo(3));
          expect(s.population, 24);
          expect(s.housing, 24);
          expect(s.resources['food'], 60);
          expect(s.resources['water'], 60);
          for (final r in [
            'metal',
            'energy',
            'tools',
            'fuel',
            'medicine',
            'crystal',
          ]) {
            expect(s.resources[r], 0, reason: 'No advanced opening resources');
          }
          expect(s.built['farm'], isNull);
          expect(s.built['generator'], isNull);
          expect(s.people.map((p) => p.role), contains('artesana'));
        }
        w.validate();
      }
    },
  );

  test('Primitive survival, a persistent refuge and actual crafted tools', () {
    final w = start();
    final sim = Simulation(w)..registerContent(content);
    final before = w.canonical();
    expect(sim.command('build', target: 'farm').ok, isFalse);
    expect(w.canonical(), before);
    expect(sim.command('build', target: 'shelter').ok, isTrue);
    sim.advanceDays(10);
    expect(w.controlled.housing, 32);
    expect(w.controlled.sites.where((s) => s.building == 'shelter').length, 4);
    sim.advanceDays(8);
    expect(sim.command('research', target: 'stone_tools').ok, isTrue);
    expect(sim.command('build', target: 'knapping_shed').ok, isTrue);
    sim.advanceDays(8);
    expect(w.controlled.built['knapping_shed'], 1);
    sim.advanceDays(60);
    expect(w.controlled.alive, isTrue);
    expect(w.controlled.health, greaterThan(55));
    expect(w.controlled.resources['food'], greaterThan(0));
    expect(w.controlled.resources['water'], greaterThan(0));
    expect(w.controlled.resources['tools'], greaterThanOrEqualTo(2));
    final checkpoint = Checkpoint.create(world: w, coreSource: source);
    expect(
      Checkpoint.decode(checkpoint.encode()).world.canonical(),
      checkpoint.world.canonical(),
    );
    final saved = checkpoint.world;
    expect(Simulation(saved).command('explore').ok, isTrue);
    expect(
      saved.controlled.resources['tools'],
      lessThan(w.controlled.resources['tools']!),
    );
    w.validate();
  });

  test('Oral teaching changes transmission without granting a free era', () {
    final a = start();
    a.controlled.resources['knowledge'] = 10;
    final b = WorldState.fromJson(a.toJson());
    final simA = Simulation(a), simB = Simulation(b);
    expect(simB.command('research', target: 'oral_tradition').ok, isTrue);
    final beforeA = a.controlled.resources['knowledge']!;
    final beforeB = b.controlled.resources['knowledge']!;
    simA.advanceDays(1);
    simB.advanceDays(1);
    expect(
      b.controlled.resources['knowledge']! - beforeB,
      greaterThan(a.controlled.resources['knowledge']! - beforeA),
    );
    expect(b.controlled.resources['energy'], 0);
    expect(b.controlled.tech, {'oral_tradition'});
  });

  test(
    'A funded experiment delivers later exactly once with its causal link',
    () {
      final w = start();
      final sim = Simulation(w)..registerContent(content);
      expect(sim.resolveContentEvent('prehistoric_lascas', 'trial').ok, isTrue);
      final parent = w.pending.singleWhere(
        (e) => e.data['eventId'] == 'prehistoric_lascas_result',
      );
      expect(parent.day, 14);
      expect(w.controlled.resources['tools'], 0);
      expect(
        sim.resolveContentEvent('prehistoric_lascas_result', 'receive').ok,
        isFalse,
      );
      sim.advanceDays(14);
      expect(w.controlled.resources['tools'], 0);
      expect(
        sim.resolveContentEvent('prehistoric_lascas_result', 'receive').ok,
        isTrue,
      );
      expect(w.controlled.resources['tools'], 2);
      expect(w.chronicle.last.cause, parent.cause);
      final before = w.canonical();
      expect(
        sim.resolveContentEvent('prehistoric_lascas_result', 'receive').ok,
        isFalse,
      );
      expect(w.canonical(), before);
    },
  );

  test(
    'Terrain rejects unsuitable water collection and limits wild production',
    () {
      final w = start();
      final sim = Simulation(w);
      final s = w.controlled;
      w.tiles[s.y * w.size + s.x] = Tile(s.x, s.y, 2, 1);
      final before = w.canonical();
      expect(sim.command('build', target: 'water_collect').ok, isFalse);
      expect(w.canonical(), before);
      final water = w.controlled.resources['water']!;
      sim.advanceDays(1);
      expect(w.controlled.resources['water'], lessThan(water));
      final valid = start();
      valid.controlled.adults = 200;fixturePopulation(valid);
      final v = valid.controlled;
      valid.tiles[v.y * valid.size + v.x] = Tile(v.x, v.y, 0, 3);
      valid.controlled.built['foraging_camp'] = 3;
      valid.controlled.sites.clear();
      valid.controlled.ensureSites();
      final overloaded = WorldState.fromJson(valid.toJson());
      overloaded.controlled.built['foraging_camp'] = 20;
      overloaded.controlled.sites.clear();
      overloaded.controlled.ensureSites();
      // More posts cannot create twenty times the food from a finite local capacity.
      Simulation(valid).advanceDays(1);
      Simulation(overloaded).advanceDays(1);
      expect(
        overloaded.controlled.resources['food'],
        valid.controlled.resources['food'],
      );
    },
  );

  test('Origins keep their narrative contexts and saved rules', () {
    final prehistoric = start();
    final p = Simulation(prehistoric)..registerContent(content);
    expect(
      p.eligibleEvents().every(
        (e) => (e['origins'] as List).contains('prehistory'),
      ),
      isTrue,
    );
    expect(
      p.resolveContentEvent('granary_mold', 'accept', scheduled: true).ok,
      isFalse,
    );
    p.advanceDays(200);
    expect(p.command('research', target: 'writing').ok, isTrue);
    expect(
      p.eligibleEvents().any((e) => e['id'] == 'cold_roofs'),
      isTrue,
      reason:
          'A prehistoric origin does not permanently exclude later chronicles',
    );
    final rebuilt = WorldState.generate(size: 64, origin: 'reconstruction');
    expect(rebuilt.controlled.population, 56);
    expect(rebuilt.controlled.resources['metal'], 25);
    expect(rebuilt.controlled.built['farm'], 2);
    expect(
      Checkpoint.create(world: rebuilt, coreSource: source).world.origin,
      'reconstruction',
    );
  });
}
