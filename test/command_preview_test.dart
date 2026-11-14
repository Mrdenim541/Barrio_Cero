import '../tool/fixtures.dart';
import 'dart:convert';
import 'dart:io';

import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:flutter_test/flutter_test.dart';

Command request(
  WorldState world,
  String action, {
  String? target,
  String? actor,
  String? choice,
  String id = 'quote',
  int? day,
}) => Command(
  id: id,
  action: action,
  actorId: actor ?? world.controlledId,
  issuedDay: day ?? world.day,
  target: target,
  choice: choice,
);

void main() {
  test(
    'build quote matches confirmed costs and duration without any side effects',
    () {
      final world = WorldState.generate(size: 64);
      final published = <HistoryEntry>[];
      final sim = Simulation(world, onHistory: published.add);
      final command = request(world, 'build', target: 'farm');
      final before = world.canonical();
      final preview = sim.preview(command);
      expect(preview.allowed, isTrue);
      expect(preview.costs, {'wood': 20, 'stone': 5});
      expect(preview.workers, 4);
      expect(preview.durationDays, 12);
      expect(preview.outcome, contains('Alimento'));
      expect(world.canonical(), before);
      expect(published, isEmpty);
      expect(() => preview.costs['wood'] = 0, throwsUnsupportedError);
      expect(sim.submit(command).ok, preview.allowed);
      expect(world.controlled.resources['wood'], 80);
      expect(world.controlled.resources['stone'], 70);
      expect(
        world.controlled.projects.single.finish - world.day,
        preview.durationDays,
      );
      expect(published, hasLength(1));
    },
  );

  test('engineering quote uses actual accelerated work duration', () {
    final world = WorldState.generate(size: 64);
    world.controlled.tech.add('engineering');
    final sim = Simulation(world);
    final command = request(world, 'build', target: 'farm');
    final preview = sim.preview(command);
    expect(preview.durationDays, 9);
    expect(sim.submit(command).message, contains('9 días'));
    expect(world.controlled.projects.single.finish, 9);
  });

  test(
    'quotes and submit agree on materials, workers, prerequisites and invalid targets',
    () {
      final cases = <(String, String?, void Function(WorldState))>[
        ('build', 'farm', (w) => w.controlled.resources['wood'] = 0),
        ('build', 'farm', (w) => w.controlled.adults = 3),
        ('build', 'mine', (_) {}),
        ('build', 'missing', (_) {}),
        ('research', 'science', (_) {}),
        (
          'research',
          'agriculture',
          (w) => w.controlled.resources['knowledge'] = 0,
        ),
        ('research', 'missing', (_) {}),
        ('explore', null, (w) => w.controlled.adults = 3),
        ('repair', null, (_) {}),
      ];
      for (final (action, target, setup) in cases) {
        final world = WorldState.generate(size: 64);
        setup(world);fixturePopulation(world,trimFeatures:true);
        final sim = Simulation(world);
        final command = request(world, action, target: target);
        final before = world.canonical();
        final preview = sim.preview(command);
        expect(preview.allowed, isFalse, reason: '$action $target');
        expect(preview.reason, isNotEmpty);
        expect(world.canonical(), before);
        final submitted = sim.submit(command);
        expect(submitted.ok, preview.allowed);
        expect(submitted.code, preview.code);
        expect(submitted.message, preview.reason);
        expect(world.canonical(), before);
      }
      final mine = Simulation(WorldState.generate(size: 64));
      expect(
        mine
            .preview(request(mine.world, 'build', target: 'mine'))
            .prerequisites,
        contains('Conocimiento: Minería'),
      );
    },
  );

  test('research is honestly quoted as immediate under the existing rules', () {
    final world = WorldState.generate(size: 64);
    final sim = Simulation(world);
    final command = request(world, 'research', target: 'agriculture');
    final before = world.canonical();
    final preview = sim.preview(command);
    expect(preview.allowed, isTrue);
    expect(preview.durationDays, 0);
    expect(preview.workers, 0);
    expect(preview.costs, {'knowledge': 30});
    expect(world.canonical(), before);
    expect(sim.submit(command).ok, isTrue);
    expect(world.controlled.tech, contains('agriculture'));
    expect(world.controlled.resources['knowledge'], 5);
  });

  test('expedition quote has real labor, provisions and return time', () {
    final world = WorldState.generate(size: 64);
    final sim = Simulation(world);
    final command = request(world, 'explore');
    final before = world.canonical();
    final preview = sim.preview(command);
    expect(preview.allowed, isTrue);
    expect(preview.costs, {'food': 12, 'tools': 2});
    expect(preview.workers, 4);
    expect(preview.durationDays, 8);
    expect(world.canonical(), before);
    expect(sim.submit(command).ok, isTrue);
    expect(world.controlled.expeditionWorkers, 4);
    expect(world.pending.single.day, world.day + 8);
    final waiting = world.canonical();
    expect(
      sim.preview(request(world, 'explore', id: 'second')).allowed,
      isFalse,
    );
    expect(world.canonical(), waiting);
  });

  test('repair quote describes only work the present rule can actually do', () {
    final world = WorldState.generate(size: 64);
    final sim = Simulation(world);
    world.tiles[world.controlled.y * world.size + world.controlled.x].damage =
        1;
    world.controlled.housingModifier = -10;
    final command = request(world, 'repair');
    final before = world.canonical();
    final preview = sim.preview(command);
    expect(preview.allowed, isTrue);
    expect(preview.costs, {'wood': 10, 'stone': 8, 'tools': 2});
    expect(preview.durationDays, 0);
    expect(preview.workers, 0);
    expect(world.canonical(), before);
    expect(sim.submit(command).ok, isTrue);
    expect(world.controlled.housingModifier, 0);
  });

  test(
    'foreign, stale and dead actors are rejected without changing RNG or history',
    () {
      final world = WorldState.generate(size: 64);
      final sim = Simulation(world);
      final before = world.canonical();
      expect(
        sim.preview(request(world, 'build', actor: 's1', target: 'farm')).code,
        'not_controlled',
      );
      expect(
        sim.preview(request(world, 'build', target: 'farm', day: 9)).code,
        'stale_day',
      );
      expect(
        sim.preview(request(world, 'build', target: 'farm', id: '')).code,
        'invalid_id',
      );
      expect(world.canonical(), before);
      world.controlled.children = 0;
      world.controlled.adults = 0;
      world.controlled.elders = 0;
      world.controlled.extinct = true;fixturePopulation(world,trimFeatures:true);
      final extinct = world.canonical();
      final preview = sim.preview(request(world, 'build', target: 'farm'));
      expect(preview.allowed, isFalse);
      expect(preview.reason, contains('viva'));
      expect(world.canonical(), extinct);
    },
  );

  test(
    'unknown targets and malformed state return rejection rather than throwing',
    () {
      final world = WorldState.generate(size: 64);
      final sim = Simulation(world);
      final before = world.canonical();
      for (final action in [
        'build',
        'research',
        'control',
        'trade',
        'diplomacy',
        'resolve_event',
        'missing',
      ]) {
        final command = request(
          world,
          action,
          target: 'missing',
          choice: 'missing',
        );
        final preview = sim.preview(command);
        expect(preview.allowed, isFalse, reason: action);
        expect(preview.reason, sim.submit(command).message);
        expect(world.canonical(), before);
      }
      // Metadata must not bypass a rejection or parse malformed content after it.
      sim.registerContent({
        'events': ['malformed'],
      });
      expect(
        sim.preview(request(world, 'resolve_event', id: '')).code,
        'invalid_id',
      );
      expect(
        () => world.controlled.resources['wood'] = -1,
        throwsFormatException,
      );
      world.controlled.health = -1;
      final invalid = world.canonical();
      expect(
        sim.preview(request(world, 'build', target: 'farm')).code,
        'invalid_state',
      );
      expect(world.canonical(), invalid);
    },
  );

  test(
    'already confirmed IDs quote no second payment and conflicts remain rejected',
    () {
      final world = WorldState.generate(size: 64);
      final sim = Simulation(world);
      final command = request(world, 'build', target: 'farm');
      expect(sim.submit(command).ok, isTrue);
      final restored = WorldState.fromJson(jsonDecode(world.canonical()));
      final before = restored.canonical();
      final replay = Simulation(restored).preview(command);
      expect(replay.allowed, isTrue);
      expect(replay.replayed, isTrue);
      expect(replay.costs, isEmpty);
      expect(replay.workers, 0);
      expect(
        Simulation(
          restored,
        ).preview(request(restored, 'build', target: 'house')).code,
        'id_conflict',
      );
      expect(restored.canonical(), before);
    },
  );

  test(
    'content option preview never publishes a future branch or consumes live randomness',
    () {
      final world = WorldState.generate(seed: 42, size: 64);
      final published = <HistoryEntry>[];
      final sim = Simulation(world, onHistory: published.add);
      sim.registerContent(
        jsonDecode(File('assets/content/core.json').readAsStringSync()),
      );
      final event = sim.eligibleEvents().first;
      final option = (event['options'] as List).first;
      final command = request(
        world,
        'resolve_event',
        target: event['id'],
        choice: option['id'],
      );
      final before = world.canonical();
      final preview = sim.preview(command);
      expect(world.canonical(), before);
      expect(published, isEmpty);
      final clone = Simulation(WorldState.fromJson(world.toJson()))
        ..registerContent(sim.content!);
      expect(clone.submit(command).ok, preview.allowed);
      expect(world.canonical(), before);
    },
  );
}
