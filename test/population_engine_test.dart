import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import '../tool/fixtures.dart';

void main() {
  Map<String, dynamic> event(int population) => {
    'events': [
      {
        'id': 'population_probe',
        'title': 'Movimiento confirmado',
        'body':
            'Una decisión material afecta a residentes que pertenecen a grupos reales.',
        'trigger': 'director',
        'conditions': <String, dynamic>{},
        'repeatable': false,
        'category': 'politics',
        'options': [
          {
            'id': 'apply',
            'label': 'Confirmar',
            'costs': <String, num>{},
            'effects': [
              {'type': 'population', 'value': population},
            ],
            'followUps': [],
          },
        ],
      },
    ],
  };
  Command decision(WorldState w, String id) => Command(
    id: id,
    action: 'resolve_event',
    actorId: 's0',
    issuedDay: w.day,
    target: 'population_probe',
    choice: 'apply',
  );

  test('New worlds reconcile every living person with their exact cohort', () {
    for (final origin in ['reconstruction', 'prehistory']) {
      final w = WorldState.generate(size: 64, origin: origin);
      expect(w.populationState, totalPopulation(w));
    }
  });

  test('A population loss also removes its featured residents once', () {
    final w = WorldState.generate(size: 64);
    final sim = Simulation(w)..registerContent(event(-56));
    final before = w.populationState!.total;
    final command = decision(w, 'loss');
    expect(sim.submit(command).ok, isTrue);
    expect(w.controlled.population, 0);
    expect(w.populationState!.total, before - 56);
    expect(w.controlled.people.every((p) => !p.alive), isTrue);
    expect(
      w.controlled.people.every(
        (p) => !w.populationState!.members.containsKey(p.id),
      ),
      isTrue,
    );
    final ended = w.canonical();
    expect(sim.submit(command).replayed, isTrue);
    expect(w.canonical(), ended);
    expect(sim.submit(decision(w, 'another')).ok, isFalse);
    w.validate();
  });

  test('Immigration moves actual residents and preserves source culture', () {
    final w = WorldState.generate(size: 64);
    final sim = Simulation(w)..registerContent(event(4));
    final total = w.populationState!.total;
    final culture = w.entities!.cityFor('s1')!.cultureId;
    expect(sim.submit(decision(w, 'arrivals')).ok, isTrue);
    expect(w.society('s0')!.population, 60);
    expect(w.society('s1')!.population, 52);
    expect(w.populationState!.total, total);
    expect(
      w.populationState!.cohorts
          .where((c) => c.settlement == 's0' && c.culture == culture)
          .fold<int>(0, (n, c) => n + c.count),
      4,
    );
    for (final s in w.societies) {
      for (final p in s.people.where((p) => p.alive)) {
        expect(
          w.populationState!
              .cohort(w.populationState!.cohortOf(p.id)!)!
              .settlement,
          s.id,
        );
      }
    }
    w.validate();
  });

  test('Leadership promotes a resident without increasing the population', () {
    final w = WorldState.generate(size: 64);
    final s = w.controlled;
    final old = List<Person>.from(s.people);
    for (final p in old) {
      final cohort = w.populationState!.cohortOf(p.id)!;
      final killed = w.populationState!.killCohort(cohort, 1, (_) => 0);
      expect(killed.people, [p.id]);
      p.diedDay = w.day;
    }
    w.syncPopulation();
    w.entities!.reconcile(w.identityRecords);
    final population = s.population;
    Simulation(w).advanceDays(1);
    expect(s.population, population);
    final leader = s.people.singleWhere((p) => p.id == s.leaderId);
    expect(leader.alive, isTrue);
    expect(leader.birthEstimated, isTrue);
    expect(w.populationState!.members.containsKey(leader.id), isTrue);
    expect(s.people.where((p) => p.alive).length, 1);
    w.validate();
  });

  test('A maximum-age leader dies and cannot continue acting', () {
    final w = WorldState.generate(size: 64);
    final old = w.controlled.people.last;
    old.bornDay = -119 * 360;
    fixturePopulation(w);
    final sim = Simulation(w);
    sim.advanceDays(360);
    expect(old.diedDay, 360);
    expect(w.populationState!.members.containsKey(old.id), isFalse);
    expect(w.controlled.leaderId, isNot(old.id));
    expect(
      w.controlled.people.any((p) => p.alive && p.id == w.controlled.leaderId),
      isTrue,
    );
    w.validate();
  });

  test(
    'Rehashed count, birthday and membership contradictions are rejected',
    () {
      final w = WorldState.generate(size: 64);
      for (final edit in <void Function(Map<String, dynamic>)>[
        (m) => m['societies'][0]['adults']++,
        (m) => m['societies'][0]['people'][0]['bornDay']--,
        (m) => m['societies'][0]['people'][0]['diedDay'] = 0,
        (m) => m['populationState']['day'] = 1,
      ]) {
        final raw = jsonDecode(jsonEncode(w.toJson())) as Map<String, dynamic>;
        edit(raw);
        expect(() => WorldState.fromJson(raw), throwsFormatException);
      }
    },
  );

  test(
    'Generations survive checkpoint recovery with the same causal sequence',
    () {
      final core = File('assets/content/core.json').readAsStringSync();
      final a = Checkpoint.create(
        world: WorldState.generate(size: 64, seed: 17),
        coreSource: core,
      );
      var b = Checkpoint.decode(a.encode());
      final direct = a.world;
      final content = a.content;
      final directSim = Simulation(direct)..registerContent(content);
      directSim.advanceDays(720, delegateDecisions: true);
      var resumed = b.world;
      for (var step = 0; step < 24; step++) {
        (Simulation(
          resumed,
        )..registerContent(content)).advanceDays(30, delegateDecisions: true);
        b = Checkpoint.decode(
          Checkpoint.create(world: resumed, coreSource: core).encode(),
        );
        resumed = b.world;
      }
      expect(resumed.canonical(), direct.canonical());
      direct.validate();
    },
  );
}

Matcher totalPopulation(WorldState w) => predicate<PopulationLedger?>((ledger) {
  if (ledger == null) return false;
  w.validate();
  return ledger.total == w.societies.fold<int>(0, (n, s) => n + s.population) &&
      ledger.members.length ==
          w.societies.fold<int>(
            0,
            (n, s) => n + s.people.where((p) => p.alive).length,
          );
}, 'cohort counts and every living person agree');
