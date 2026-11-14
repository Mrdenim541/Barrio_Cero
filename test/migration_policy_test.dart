import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import '../tool/fixtures.dart';

void main() {
  Map<String, dynamic> content() => {
    'events': [
      {
        'id': 'arrival',
        'title': 'Una petición de refugio',
        'body': 'Un grupo real solicita cambiar de comunidad.',
        'trigger': 'director',
        'category': 'politics',
        'conditions': <String, dynamic>{},
        'repeatable': false,
        'options': [
          {
            'id': 'receive',
            'label': 'Recibir',
            'costs': {'food': 20},
            'effects': [
              {'type': 'population', 'value': 4},
            ],
            'followUps': [],
          },
          {
            'id': 'decline',
            'label': 'No recibir',
            'costs': <String, num>{},
            'effects': [],
            'followUps': [],
          },
        ],
      },
    ],
  };
  Command arrival(WorldState w, String id) => Command(
    id: id,
    action: 'resolve_event',
    actorId: 's0',
    issuedDay: w.day,
    target: 'arrival',
    choice: 'receive',
  );
  test(
    'Healthy communities cannot be drained by a fictional refugee event',
    () {
      final w = WorldState.generate(size: 64);
      final engine = Simulation(w)..registerContent(content());
      final before = w.canonical();
      expect(engine.previewMigration('s0', 4), isNull);
      expect(engine.eligibleEvents(), isEmpty);
      expect(engine.submit(arrival(w, 'refused')).ok, isFalse);
      expect(w.canonical(), before);
    },
  );
  test(
    'Rules10 invites common adults without taking leaders or creating residents',
    () {
      final w = WorldState.generate(size: 64);
      w.rulesVersion = 10;
      w.society('s1')!.health = 30;
      fixturePath(w, 's1', 's0');
      final engine = Simulation(w)..registerContent(content());
      final before = w.canonical();
      final total = w.populationState!.total;
      final originPeople = w.society('s1')!.people.map((p) => p.id).toList();
      final offer = engine.previewMigration('s0', 4);
      expect(offer?.source, 's1');
      expect(w.canonical(), before);
      final cmd = arrival(w, 'receive'), result = engine.submit(cmd);
      expect(result.ok, isTrue, reason: result.message);
      expect(w.controlled.population, 60);
      expect(w.society('s1')!.population, 52);
      expect(w.populationState!.total, total);
      expect(w.society('s1')!.people.map((p) => p.id).toList(), originPeople);
      expect(w.controlled.resources['food'], 240);
      expect(
        w.chronicle.any(
          (h) => h.societyId == 's1' && h.category == 'migración',
        ),
        isTrue,
      );
      final committed = w.canonical();
      expect(engine.submit(cmd).replayed, isTrue);
      expect(w.canonical(), committed);
      w.validate();
    },
  );
  test(
    'A closed path prevents the invitation instead of teleporting residents',
    () {
      final w = WorldState.generate(size: 64);
      w.society('s1')!.health = 30;
      final town = w.controlled;
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final x = town.x + dx, y = town.y + dy;
        w.tiles[y * w.size + x] = Tile(x, y, 5, 3);
      }
      w.validate();
      expect(Simulation(w).previewMigration('s0', 4), isNull);
    },
  );
  test(
    'A constrained source cannot abandon the adults needed by dependents',
    () {
      final w = WorldState.generate(size: 64);
      final source = w.society('s1')!;
      source.adults = 7;
      source.health = 30;
      fixturePopulation(w);
      fixturePath(w, 's1', 's0');
      expect(Simulation(w).previewMigration('s0', 4), isNull);
      w.validate();
    },
  );
  test('Selection follows actual needs rather than the first source ID', () {
    final w = WorldState.generate(size: 64);
    w.society('s3')!.housingModifier = -40;
    fixturePath(w, 's3', 's0');
    expect(Simulation(w).previewMigration('s0', 4)?.source, 's3');
    expect(w.society('s1')!.health, 90);
  });
  test(
    'Rules8 checkpoints retain previous invitation semantics until explicit conversion',
    () {
      final raw = WorldState.generate(size: 64).toJson();
      raw['rulesVersion'] = 8;raw.remove('migrations');
      final w = WorldState.fromJson(raw);
      final engine = Simulation(w)..registerContent(content());
      final result = engine.submit(arrival(w, 'legacy'));
      expect(result.ok, isTrue, reason: result.message);
      expect(w.society('s1')!.population, 52);
      w.validate();
    },
  );
  test(
    'A common-only transfer excludes named residents and underage cohorts without using random draws',
    () {
      final ledger = PopulationLedger();
      ledger.add(settlement: 'a', culture: 'c', bornDay: -17 * 360, count: 4);
      final adult = ledger.add(
        settlement: 'a',
        culture: 'c',
        bornDay: -18 * 360,
        count: 4,
      );
      ledger.register('known', adult);
      ledger.add(settlement: 'a', culture: 'c', bornDay: -40 * 360, count: 2);
      final moved = ledger.transfer(
        'a',
        'b',
        4,
        1,
        (n) => throw StateError('No random selection needed'),
        minimumAge: 18,
        commonOnly: true,
      );
      expect(moved.people, isEmpty);
      expect(ledger.cohort(ledger.cohortOf('known')!)!.settlement, 'a');
      expect(ledger.total, 10);
      expect(ledger.totals('a').total, 6);
      expect(ledger.totals('b').adults, 4);
      ledger.validate();
    },
  );
  test(
    'New openings connect all six viable societies without changing the seeded terrain',
    () {
      for (final origin in ['prehistory', 'reconstruction']) {
        for (var seed = 1; seed <= 30; seed++) {
          final world = WorldState.generate(
            seed: seed,
            size: seed.isEven ? 64 : 96,
            origin: origin,
          );
          final terrain = WorldState.generate(
            seed: seed,
            size: world.size,
            fixedMaterials: false,
          );
          expect(
            world.tiles.map((t) => t.toJson()).toList(),
            terrain.tiles.map((t) => t.toJson()).toList(),
          );
          final sim = Simulation(world);
          for (final town in world.societies.skip(1)) {
            expect(
              sim.findPath(world.societies.first, town),
              isNotEmpty,
              reason: '$origin seed $seed ${town.id}',
            );
          }
          world.validate();
        }
      }
    },
  );
}
