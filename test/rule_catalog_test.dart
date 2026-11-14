import '../tool/fixtures.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  Map<String, dynamic> modified() {
    final pack = jsonDecode(core) as Map<String, dynamic>;
    pack['version'] = '1.1.0';
    final farm = (pack['buildings'] as List).firstWhere(
      (b) => b['id'] == 'farm',
    );
    farm['costs'] = {'wood': 7.5, 'stone': 2};
    farm['days'] = 2;
    farm['dailyYield'] = {'food': 9};
    pack['technologies'][0]['knowledgeCost'] = 1;
    return pack;
  }

  test('Pinned definitions drive actual costs, completion and production', () {
    final pack = modified();
    final w = WorldState.generate(size: 64);
    w.contentVersions = {'core': '1.1.0'};
    final bound = Checkpoint.create(world: w, coreSource: jsonEncode(pack));
    final world = bound.world;
    final sim = Simulation(world)..registerContent(bound.content);
    final preview = sim.preview(
      Command(
        id: 'farm',
        action: 'build',
        actorId: 's0',
        issuedDay: 0,
        target: 'farm',
      ),
    );
    expect(preview.costs['wood'], 7.5);
    expect(preview.durationDays, 2);
    final wood = world.controlled.resources['wood']!;
    expect(sim.command('build', target: 'farm').ok, isTrue);
    expect(world.controlled.resources['wood'], wood - 7.5);
    sim.advanceDays(2);
    expect(world.controlled.projects, isEmpty);
    expect(world.controlled.built['farm'], 3);
    final knowledge = world.controlled.resources['knowledge']!;
    expect(sim.command('research', target: 'agriculture').ok, isTrue);
    expect(world.controlled.resources['knowledge'], knowledge - 1);

    final s = world.controlled;
    s.tech.clear();
    s.built = {'farm': 1};
    s.sites.clear();
    s.ensureSites();
    s.health = 100;
    s.resources['food'] = 100;
    s.policy.reserve=100000; // Isolate declared maximum yield from reserve-driven work allocation.
    world.tiles[s.y * world.size + s.x] = Tile(s.x, s.y, 0, 2);
    sim.advanceDays(1);
    expect(s.resources['food'], closeTo(107.83, .001));
    final saved = Checkpoint.create(world: world, coreSource: bound.coreSource);
    expect(
      Checkpoint.decode(saved.encode()).world.canonical(),
      world.canonical(),
    );
  });

  test('Bound worlds reject different definitions without changing state', () {
    final original = Checkpoint.create(
      world: WorldState.generate(size: 64),
      coreSource: core,
    );
    final w = original.world;
    final before = w.canonical();
    final changed = modified();
    expect(() => Simulation(w).registerContent(changed), throwsFormatException);
    expect(w.canonical(), before);
    final raw = w.toJson();
    raw['catalog'] = RuleCatalog.fromContent(changed).toJson();
    final forged = WorldState.fromJson(raw);
    expect(
      () => Checkpoint.create(world: forged, coreSource: core),
      throwsFormatException,
    );
  });

  test('Declared capacities and technology effects change actual behavior', () {
    final pack = modified();
    pack['technologies'][0]['effects'] = [
      {'type': 'flag', 'value': 'technology_irrigation'},
    ];
    (pack['buildings'] as List).firstWhere(
      (b) => b['id'] == 'house',
    )['effect'] = {
      'type': 'housing',
      'value': 8,
    };
    // The declared opening remains viable while testing a later world's capacity.
    (pack['origins'] as List).firstWhere(
      (o) => o['id'] == 'reconstruction',
    )['buildings']['house'] = 8;
    final generated = WorldState.generate(size: 64);
    generated.contentVersions = {'core': '1.1.0'};
    final checkpoint = Checkpoint.create(
      world: generated,
      coreSource: jsonEncode(pack),
    );
    final w = checkpoint.world;
    final s = w.controlled;
    expect(s.housing, 32);
    s.tech.add('agriculture');
    expect(s.supports('agriculture'), isFalse);
    expect(s.supports('irrigation'), isTrue);
    s.built = {'farm': 1};
    s.sites.clear();
    s.ensureSites();
    s.resources['food'] = 100;
    s.policy.reserve=100000; // Isolate declared maximum yield from reserve-driven work allocation.
    s.health = 100;
    w.tiles[s.y * w.size + s.x] = Tile(s.x, s.y, 0, 2);
    (Simulation(w)..registerContent(checkpoint.content)).advanceDays(1);
    expect(s.resources['food'], closeTo(110.935, .001));
  });

  test('Legacy rules use frozen tables and retain exact serialization', () {
    final raw = WorldState.generate(size: 64).toJson();
    raw['rulesVersion'] = 3;raw.remove('migrations');
    raw.remove('catalog');raw.remove('populationState');raw.remove('socialState');
    final w = WorldState.fromJson(raw);
    final before = w.canonical();
    final copy = WorldState.fromJson(jsonDecode(before));
    expect(copy.canonical(), before);
    expect(
      Simulation(w)
          .preview(
            const Command(
              id: 'x',
              action: 'build',
              actorId: 's0',
              issuedDay: 0,
              target: 'farm',
            ),
          )
          .costs['wood'],
      20,
    );
    final checkpoint = Checkpoint.create(world: w, coreSource: core);
    expect(checkpoint.world.catalog, isNull);
    expect(
      Checkpoint.upgradeRules(checkpoint.encode()).world.catalog,
      isNotNull,
    );
  });

  test(
    'Production consumes declared inputs and stops without labor or supplies',
    () {
      final w = WorldState.generate(size: 64);
      final s = w.controlled;
      s.built = {'generator': 1};
      s.sites.clear();
      s.ensureSites();
      s.resources['fuel'] = .08;
      s.resources['energy'] = 5;
      s.health = 100;
      s.adults = 0;fixturePopulation(w,trimFeatures:true);
      final sim = Simulation(w);
      sim.advanceDays(1);
      expect(s.resources['fuel'], .08);
      expect(s.resources['energy'], 5);
      s.adults = 2;fixturePopulation(w,trimFeatures:true);
      s.health = 100;
      sim.advanceDays(1);
      expect(s.resources['fuel'], 0);
      expect(s.resources['energy'], 6.5);
      sim.advanceDays(1);
      expect(s.resources['energy'], 6.5);
    },
  );

  test('Insufficient input permits only proportional output', () {
    final w = WorldState.generate(size: 64);
    final s = w.controlled;
    s.built = {'workshop': 1};
    s.sites.clear();
    s.ensureSites();
    // Isolate recipe stoichiometry from the separate trained-craft bonus.
    for(final person in s.people){person.skills['craft']=0;}
    s.resources['metal'] = .02;
    s.resources['tools'] = 20;
    s.health = 100;
    final sim = Simulation(w);
    sim.advanceDays(1);
    expect(s.resources['metal'], 0);
    expect(s.resources['tools'], 20.075);
    sim.advanceDays(1);
    expect(s.resources['tools'], 20.075);
  });

  test(
    'Unknown executable fields, material precision and cycles are rejected',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (p) => p['buildings'][0]['execute'] = 'anything',
        (p) => p['buildings'][0]['costs']['wood'] = .0001,
        (p) => p['buildings'][0]['requires'] = ['agriculture', 'writing'],
        (p) => p['technologies'][0]['requires'] = ['agriculture'],
        (p) => p['technologies'][0]['effects'] = [
          {'type': 'execute', 'value': 'x'},
        ],
        (p) => p['technologies'][0]['effects'] = [
          {'type': 'flag', 'value': 'technology_unknown'},
        ],
        (p) => p['buildings'][0]['effect'] = {'type': 'unused', 'value': 1},
      ]) {
        final raw = modified();
        mutate(raw);
        expect(() => RuleCatalog.fromContent(raw), throwsFormatException);
      }
    },
  );
}
