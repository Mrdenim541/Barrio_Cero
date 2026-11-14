import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import '../tool/fixtures.dart';

WorldState overcommittedTown({bool legacy = false}) {
  final world = WorldState.generate(seed: 73, size: 64, extraordinary: false);
  if (legacy) world.rulesVersion = 9;
  final town = world.controlled;
  town.children = 12;
  town.adults = 8;
  town.elders = 0;
  town.built = {'farm': 2, 'well': 1, 'house': 4};
  town.sites = [];
  town.ensureSites();
  town.health = 100;
  town.resources['food'] = 1000;
  town.resources['water'] = 1000;
  town.policy.trade = false;
  town.policy.expansion = false;
  town.resources['textiles'] = 100;
  fixturePopulation(world);
  final sim = Simulation(world);
  for (final neighbor in world.societies.skip(1).take(4)) {
    town.relations[neighbor.id] = 50;
    if (!sim.command('trade', target: neighbor.id).ok) {
      throw StateError('Fixture route was rejected');
    }
  }
  // Initial crisis: old route commitments survived a labor shortage. No
  // supplies are injected after this point, and the real well must operate.
  town.resources['water'] = 0;
  world.validate();
  return world;
}

void main() {
  test('Existing caravans cannot take all workers away from a thirsty town', () {
    final w = overcommittedTown();
    Simulation(w).advanceDays(1);
    final town = w.controlled, record = town.lastProduction!;
    expect(record['waterUsed'], record['waterNeed']);
    expect(town.health, 100);
    expect(w.routes.where((r) => r.crewAssigned == 2).length, lessThan(4));
    expect(w.routes.any((r) => r.crewAssigned == 0 && r.blocked), isTrue);
    expect(town.transportWorkers, 8); // A pause does not erase the commitment.
    w.validate();
  });

  test('Rules9 retains the old route-first staffing until explicit conversion', () {
    final w = overcommittedTown(legacy: true);
    Simulation(w).advanceDays(1);
    expect(w.controlled.lastProduction!['waterUsed'], 0);
    expect(w.routes.where((r) => r.crewAssigned == 2).length, 4);
  });

  test('Autonomy orders a physical return without refunding cargo from afar', () {
    final w = overcommittedTown();
    w.controlledId = null;
    for (final route in w.routes) {
      expect(route.path.length, greaterThan(3));
      route.progress = 3;
    }
    final food = w.societies.first.resources['food']!;
    final engine = Simulation(w);
    engine.advanceDays(1, delegateDecisions: true);
    final returning = w.routes.where((r) => r.closing).toList();
    expect(returning, isNotEmpty);
    expect(returning.every((r) => r.returning && [2, 3].contains(r.progress)), isTrue,
        reason: returning.map((r) => r.toJson()).toString());
    expect(returning.any((r) => r.progress == 2), isTrue);
    expect(returning.where((r) => r.progress == 3).every((r) => r.crewAssigned == 0 && r.blocked), isTrue);
    expect(returning.every((r) => r.cargo == 12), isTrue);
    expect(w.societies.first.resources['food']!, lessThan(food + 12));
    expect(w.societies.first.lastProduction!['waterUsed'], 700);
    final recovered = WorldState.fromJson(w.toJson());
    engine.advanceDays(59, delegateDecisions: true);
    Simulation(recovered).advanceDays(59, delegateDecisions: true);
    expect(recovered.canonical(), w.canonical());
    expect(w.societies.first.transportWorkers, lessThan(8));
    expect(w.routes.any((r) => returning.any((old) => old.id == r.id)), isFalse);
    w.validate();
  });

  test('Ration protection does not reserve nonexistent productive capacity', () {
    final w = WorldState.generate(size: 64, origin: 'prehistory', extraordinary: false);
    final town = w.controlled;
    town.built.remove('water_collect');
    town.sites.removeWhere((s) => s.building == 'water_collect');
    town.resources['water'] = 0;
    final sim = Simulation(w);
    expect(sim.command('build', target: 'water_collect').ok, isTrue);
    sim.advanceDays(1);
    final work = town.projects.single.work!;
    expect(work.remaining, lessThan(work.totalWork));
    w.validate();
  });
}
