import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/community_brief.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  final content =
      jsonDecode(File('assets/content/core.json').readAsStringSync())
          as Map<String, dynamic>;
  WorldState start() => WorldState.generate(
    seed: 42,
    size: 64,
    origin: 'prehistory',
    extraordinary: false,
  );
  CommunityBrief brief(WorldState world) => CommunityBrief.read(
    world.toJson(),
    world.controlled.toJson(),
    world.catalog,
  );

  test(
    'Needs and the next real action are queries without RNG or world changes',
    () {
      final world = start();
      final sim = Simulation(world)..registerContent(content);
      final before = world.canonical();
      final value = brief(world);
      expect(value.housing, world.controlled.housing);
      expect(value.population, 24);
      expect(value.focus.target, 'shelter');
      final quote = sim.preview(
        Command(
          id: 'quote',
          action: value.focus.action!,
          actorId: world.controlledId,
          issuedDay: world.day,
          target: value.focus.target,
        ),
      );
      expect(quote.allowed, isTrue);
      expect(quote.costs, {'wood': 8, 'stone': 2});
      expect(
        CommunityGuideGoal.read(
          world.toJson(),
          world.controlledId!,
        ).any((g) => g.decided),
        isFalse,
      );
      expect(world.canonical(), before);
    },
  );

  test(
    'Low reserves take priority; an existing relevant work is not ordered twice',
    () {
      final world = start();
      final sim = Simulation(world)..registerContent(content);
      world.controlled.resources['water'] = 0;
      expect(brief(world).focus.target, 'water_collect');
      expect(
        sim
            .submit(
              Command(
                id: 'water',
                action: 'build',
                actorId: world.controlledId,
                issuedDay: 0,
                target: 'water_collect',
              ),
            )
            .ok,
        isTrue,
      );
      expect(brief(world).focus.destination, 'details');
      expect(brief(world).focus.action, isNull);
      world.controlled.resources['water'] = 60;
      world.controlled.resources['food'] = 0;
      expect(brief(world).focus.target, 'foraging_camp');
    },
  );

  test(
    'Only accepted orders of the selected community mark guide decisions',
    () {
      final world = start();
      final sim = Simulation(world)..registerContent(content);
      Command order(String id, String target) => Command(
        id: id,
        action: 'build',
        actorId: world.controlledId,
        issuedDay: 0,
        target: target,
      );
      expect(sim.submit(order('invalid', 'generator')).ok, isFalse);
      expect(sim.submit(order('home', 'shelter')).ok, isTrue);
      expect(sim.submit(order('home', 'shelter')).replayed, isTrue);
      final before = world.canonical();
      final goals = CommunityGuideGoal.read(
        world.toJson(),
        world.controlledId!,
      );
      expect(goals.length, 10);
      expect(goals.where((g) => g.decided).map((g) => g.destination), [
        'housing',
      ]);
      expect(
        CommunityGuideGoal.read(world.toJson(), 's1').any((g) => g.decided),
        isFalse,
      );
      expect(world.canonical(), before);
      final reopened = WorldState.fromJson(world.toJson());
      expect(
        CommunityGuideGoal.read(
          reopened.toJson(),
          reopened.controlledId!,
        ).where((g) => g.decided).length,
        1,
      );
    },
  );

  test(
    'Observation and a real pending decision do not imply unsolicited commands',
    () {
      final world = start();
      world.pending.add(
        ScheduledEvent(
          'choice',
          'content_choice',
          's0',
          5,
          data: {'eventId': 'fixture'},
          cause: 'a real earlier commitment',
        ),
      );
      expect(brief(world).focus.destination, 'stories');
      final other = CommunityBrief.read(
        world.toJson(),
        world.societies[1].toJson(),
        world.catalog,
      );
      expect(other.focus.destination, 'details');
      expect(other.focus.action, isNull);
      expect(world.commandReceipts, isEmpty);
    },
  );
}
