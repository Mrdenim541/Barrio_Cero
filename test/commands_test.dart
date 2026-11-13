import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

Command order(WorldState world, String id, String action,
        {String? actor, String? target, String? choice, int? day}) =>
    Command(id: id, action: action, actorId: actor ?? world.controlledId,
        issuedDay: day ?? world.day, target: target, choice: choice);

void main() {
  test('rejection preserves every serialized field including RNG and receipts', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    world.controlled.resources['wood'] = 0;
    final before = world.canonical();
    final result = simulation.submit(order(world, 'build-1', 'build', target: 'farm'));
    expect(result.ok, isFalse);
    expect(world.canonical(), before);
    expect(world.commandReceipts, isEmpty);
  });

  test('failed effect resolution rolls back payment, history and RNG', () {
    final world = WorldState.generate(size: 64);
    final observed = <HistoryEntry>[];
    final simulation = Simulation(world, onHistory: observed.add);
    // Deliberately bypass the package validator to test transaction isolation.
    simulation.registerContent({'events': [
      {'id': 'broken', 'title': 'Broken fixture', 'body': 'Invalid delayed effect',
        'category': 'test', 'trigger': 'director', 'conditions': {},
        'options': [
          {'id': 'choose', 'label': 'Try', 'costs': {'food': 12},
            'effects': [{'type': 'resource', 'resource': 'wood', 'value': 5}],
            'followUps': [{'eventId': 'broken', 'probability': 1, 'delayDays': 'invalid'}]},
        ]},
    ]});
    final before = world.canonical();
    final result = simulation.submit(order(world, 'broken-command', 'resolve_event',
        target: 'broken', choice: 'choose'));
    expect(result.code, 'invalid_state');
    expect(world.canonical(), before);
    expect(observed, isEmpty);
  });

  test('one accepted ID charges once and survives persistence', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final request = order(world, 'build-once', 'build', target: 'farm');
    expect(simulation.submit(request).ok, isTrue);
    expect(world.controlled.resources['wood'], 80);
    expect(world.controlled.projects, hasLength(1));
    final resumed = WorldState.fromJson(jsonDecode(jsonEncode(world.toJson())));
    final before = resumed.canonical();
    final replay = Simulation(resumed).submit(request);
    expect(replay.ok, isTrue);
    expect(replay.replayed, isTrue);
    expect(resumed.canonical(), before);
    final changed = Simulation(resumed).submit(order(resumed, 'build-once', 'build', target: 'house'));
    expect(changed.code, 'id_conflict');
    expect(resumed.canonical(), before);
  });

  test('two paused orders cannot spend the same available resources', () {
    final world = WorldState.generate(size: 64);
    world.controlled.resources['wood'] = 20;
    final simulation = Simulation(world);
    expect(simulation.submit(order(world, 'a', 'build', target: 'farm')).ok, isTrue);
    final before = world.canonical();
    expect(simulation.submit(order(world, 'b', 'build', target: 'farm')).ok, isFalse);
    expect(world.canonical(), before);
  });

  test('player cannot order a foreign society before assuming control', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final before = world.canonical();
    expect(simulation.submit(order(world, 'foreign', 'build', actor: 's1', target: 'farm')).code,
        'not_controlled');
    expect(world.canonical(), before);
    expect(simulation.submit(order(world, 'take-control', 'control', target: 's1')).ok, isTrue);
    expect(world.controlledId, 's1');
    expect(simulation.submit(order(world, 'foreign', 'build', actor: 's1', target: 'farm')).ok, isTrue);
    expect(world.society('s0')!.resources['wood'], 100);
  });

  test('old dates and observers cannot issue material commands', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final before = world.canonical();
    expect(simulation.submit(order(world, 'late', 'build', target: 'farm', day: 1)).code, 'stale_day');
    expect(world.canonical(), before);
    expect(simulation.submit(order(world, 'delegate', 'delegate')).ok, isTrue);
    final delegated = world.canonical();
    expect(simulation.submit(order(world, 'observer-build', 'build', target: 'farm')).code,
        'not_controlled');
    expect(world.canonical(), delegated);
    expect(simulation.submit(order(world, 'resume-control', 'control', target: 's0')).ok, isTrue);
  });

  test('balanced policy resets every previous government preference', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    expect(simulation.submit(order(world, 'isolate', 'policy', target: 'isolation')).ok, isTrue);
    expect(simulation.submit(order(world, 'food', 'policy', target: 'food')).ok, isTrue);
    expect(simulation.submit(order(world, 'balance', 'policy', target: 'balanced')).ok, isTrue);
    expect(world.controlled.policy.toJson(), Policy().toJson());
  });

  test('build and exploration require four available adults', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    for (final adults in [0, 3]) {
      world.controlled.adults = adults;
      final before = world.canonical();
      expect(simulation.command('build', target: 'farm').ok, isFalse);
      expect(simulation.command('explore').ok, isFalse);
      expect(world.canonical(), before);
    }
    world.controlled.adults = 4;
    expect(simulation.command('build', target: 'farm').ok, isTrue);
    expect(world.controlled.workers, 0);
    final before = world.canonical();
    expect(simulation.command('explore').ok, isFalse);
    expect(world.canonical(), before);
  });

  test('expedition reserves labor, prevents overlap and releases on return', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final workers = world.controlled.workers;
    expect(simulation.command('explore').ok, isTrue);
    expect(world.controlled.workers, workers - 4);
    final before = world.canonical();
    expect(simulation.command('explore').ok, isFalse);
    expect(world.canonical(), before);
    final restored = WorldState.fromJson(jsonDecode(jsonEncode(world.toJson())));
    expect(restored.controlled.expeditionWorkers, 4);
    Simulation(restored).advanceDays(8);
    expect(restored.controlled.expeditionWorkers, 0);
    expect(restored.controlled.facilityFound, isTrue);
  });

  test('dead explorer is not named and loss during expedition cancels discovery', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final leo = world.controlled.people.firstWhere((p) => p.name == 'Leo');
    expect(simulation.command('explore').ok, isTrue);
    leo.diedDay = world.day;
    simulation.advanceDays(8);
    expect(world.controlled.facilityFound, isFalse);
    expect(world.controlled.expeditionWorkers, 0);
    expect(world.chronicle.last.title, 'Expedición interrumpida');
    expect(simulation.command('explore').ok, isTrue);
    expect(world.chronicle.last.title, 'Parte un equipo de exploración');
  });

  test('observers receive accepted command histories only once', () {
    final world = WorldState.generate(size: 64);
    final seen = <HistoryEntry>[];
    final simulation = Simulation(world, onHistory: seen.add);
    final request = order(world, 'observed', 'build', target: 'farm');
    expect(simulation.submit(request).ok, isTrue);
    expect(seen, hasLength(1));
    expect(simulation.submit(request).replayed, isTrue);
    expect(simulation.submit(order(world, 'invalid', 'build', target: 'missing')).ok, isFalse);
    expect(seen, hasLength(1));
  });

  test('repair rejects undamaged targets and preserves positive capacity bonuses', () {
    final world = WorldState.generate(size: 64);
    final simulation = Simulation(world);
    final before = world.canonical();
    expect(simulation.command('repair').ok, isFalse);
    expect(world.canonical(), before);
    world.controlled.housingModifier = 18;
    world.controlled.defenseModifier = 5;
    world.tiles[world.controlled.y * world.size + world.controlled.x].damage = 1;
    expect(simulation.command('repair').ok, isTrue);
    expect(world.controlled.housingModifier, 18);
    expect(world.controlled.defenseModifier, 5);
  });
}
