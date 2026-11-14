import '../tool/fixtures.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  Command order(
    WorldState w,
    String action, {
    String? target,
    String id = 'order',
  }) => Command(
    id: id,
    action: action,
    actorId: w.controlledId,
    issuedDay: w.day,
    target: target,
  );
  test('Construction pauses without adults and resumes using real work', () {
    final w = WorldState.generate(size: 64);
    final sim = Simulation(w);
    expect(sim.submit(order(w, 'build', target: 'farm')).ok, isTrue);
    w.controlled.adults = 0;
    for (final p in w.controlled.people) {
      p.diedDay = 0;
    }
    fixturePopulation(w,trimFeatures:true);
    sim.advanceDays(20);
    expect(w.controlled.built['farm'], 2);
    expect(w.controlled.projects.single.work!.remaining, 48);
    expect(w.controlled.projects.single.work!.paused, isTrue);
    w.controlled.adults = 4;fixturePopulation(w,trimFeatures:true);
    sim.advanceDays(12);
    expect(w.controlled.projects, isEmpty);
    expect(w.controlled.built['farm'], 3);
    w.validate();
  });
  test('Workers finishing construction cannot also produce that day', () {
    final w = WorldState.generate(size: 64);
    w.controlled.adults = 4;fixturePopulation(w,trimFeatures:true);
    w.controlled.children = 0;
    w.controlled.elders = 0;fixturePopulation(w,trimFeatures:true);
    final sim = Simulation(w);
    sim.submit(order(w, 'build', target: 'farm'));
    sim.advanceDays(12);
    expect(w.controlled.built['farm'], 3);
    expect(w.controlled.resources['wood'], 80);
    sim.advanceDays(1);
    expect(w.controlled.resources['wood'], 80.06);
  });
  test('Cancellation refunds unused recorded material once and frees work', () {
    final w = WorldState.generate(size: 64);
    final sim = Simulation(w);
    sim.submit(order(w, 'build', target: 'farm'));
    sim.advanceDays(3);
    final work = w.controlled.projects.single.work!;
    final wood = w.controlled.resources['wood']!,
        stone = w.controlled.resources['stone']!;
    final cancel = order(w, 'cancel_build', target: work.id, id: 'cancel');
    expect(sim.submit(cancel).ok, isTrue);
    expect(w.controlled.resources['wood'], wood + 15);
    expect(w.controlled.resources['stone'], stone + 3.75);
    expect(w.controlled.projects, isEmpty);
    final before = w.canonical();
    expect(sim.submit(cancel).replayed, isTrue);
    expect(w.canonical(), before);
  });
  test(
    'Expedition staffing delays both exploration and construction without double assignment',
    () {
      final w = WorldState.generate(size: 64);
      final sim = Simulation(w);
      sim.submit(order(w, 'build', target: 'farm'));
      sim.submit(order(w, 'explore', id: 'explore'));
      w.controlled.adults = 2;fixturePopulation(w,trimFeatures:true);
      sim.advanceDays(8);
      expect(w.controlled.facilityFound, isFalse);
      expect(w.controlled.projects.single.work!.remaining, 48);
      final discovery = w.pending.singleWhere((e) => e.type == 'discovery');
      expect(discovery.data['remainingWork'], 16);
      w.controlled.adults = 8;fixturePopulation(w,trimFeatures:true);
      sim.advanceDays(4);
      expect(w.controlled.facilityFound, isTrue);
      expect(w.controlled.projects.single.work!.remaining, 32);
    },
  );
  WorldState routeWorld() {
    final w = WorldState.generate(size: 64);
    w.tiles = w.tiles.map((t) => Tile(t.x, t.y, 0, t.richness)).toList();
    final a = w.societies[0], b = w.societies[1];
    b.x = a.x + 2;
    b.y = a.y;
    for (final s in w.societies) {
      s.built.clear();
      s.sites.clear();
      s.resources['food'] = 1000;
      s.resources['water'] = 1000;
    }
    a.resources['metal'] = 0;
    b.resources['metal'] = 50;
    a.relations[b.id] = 50;
    return w;
  }

  test('Caravan traverses outward and return legs with conserved cargo', () {
    final w = routeWorld();
    final sim = Simulation(w);
    expect(sim.submit(order(w, 'trade', target: 's1')).ok, isTrue);
    expect(w.routes.single.path.length, 3);
    expect(w.controlled.transportWorkers, 2);
    for (var day = 1; day <= 4; day++) {
      sim.advanceDays(1);
      final r = w.routes.single;
      final food =
          w.societies[0].resources['food']! +
          w.societies[1].resources['food']! +
          r.cargo +
          day * 5.04;
      expect(food, closeTo(2000, .00001));
      final metal =
          w.societies[0].resources['metal']! +
          w.societies[1].resources['metal']! +
          r.metalMillis / 1000;
      expect(metal, 50);
      if (day < 4) expect(w.controlled.resources['metal'], 0);
    }
    expect(w.controlled.resources['metal'], 3);
    expect(w.routes.single.progress, 0);
    w.validate();
  });
  test(
    'Cut route retains its cargo, and a return order does not teleport it',
    () {
      final w = routeWorld();
      final sim = Simulation(w);
      sim.submit(order(w, 'trade', target: 's1'));
      sim.advanceDays(1);
      final routeId = w.routes.single.id;
      final position = w.routes.single.progress;
      w.tiles[w.routes.single.path.last].damage = 1;
      sim.advanceDays(1);
      expect(w.routes.single.blocked, isTrue);
      expect(w.routes.single.progress, position);
      expect(w.routes.single.cargo, 12);
      final wood = w.controlled.resources['wood']!;
      expect(
        sim.submit(order(w, 'close_route', target: routeId, id: 'close')).ok,
        isTrue,
      );
      expect(w.routes, isNotEmpty);
      sim.advanceDays(1);
      expect(w.routes, isEmpty);
      expect(w.controlled.transportWorkers, 0);
      expect(w.controlled.resources['wood'], wood + .54);
      w.validate();
    },
  );
  test(
    'Route crew shortages stop movement and save/resume keeps return cargo',
    () {
      final w = routeWorld();
      final sim = Simulation(w);
      sim.submit(order(w, 'trade', target: 's1'));
      w.controlled.adults = 1;fixturePopulation(w,trimFeatures:true);
      sim.advanceDays(1);
      expect(w.routes.single.progress, 0);
      expect(w.routes.single.blocked, isTrue);
      w.controlled.adults = 38;fixturePopulation(w,trimFeatures:true);
      sim.advanceDays(2);
      expect(w.routes.single.returning, isTrue);
      expect(w.routes.single.metalMillis, 3000);
      final core = File('assets/content/core.json').readAsStringSync();
      final checkpoint = Checkpoint.create(world: w, coreSource: core);
      expect(checkpoint.version, 3);
      final restored = Checkpoint.decode(checkpoint.encode()).world;
      final original = checkpoint.world;
      Simulation(original).advanceDays(2);
      Simulation(restored).advanceDays(2);
      expect(restored.canonical(), original.canonical());
    },
  );
}
