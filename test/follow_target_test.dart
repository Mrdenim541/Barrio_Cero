import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/follow_target.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:barrio_cero_eras/presentation/world_game.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Following survives relocation and reload without acquiring authority',
    () {
      final w = WorldState.generate(seed: 17, size: 64);
      final person = w.societies.first.people.first;
      final snapshot = w.toJson();
      final target = FollowTarget.person(snapshot, person.toJson());
      final saved = FollowTarget.decode(target.encode(active: true))!;
      final game = WorldGame((_) {});
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(360, 440));
      game.present(snapshot, generation: 1);
      final before = w.canonical();
      expect(game.followIndividual(saved.target.individualId), isTrue);
      expect(saved.target.resolve(snapshot)!.actorId, 's0');
      expect(w.canonical(), before);

      // A projected relocation: camera-contract fixture, not migration acceptance.
      final relocated =
          jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
      (relocated['societies'][0]['people'] as List).removeWhere(
        (p) => p['id'] == person.id,
      );
      (relocated['societies'][1]['people'] as List).add(person.toJson());
      final confirmed = jsonEncode(relocated);
      game.present(relocated, generation: 1);
      final resolved = saved.target.resolve(relocated)!;
      expect(resolved.actorId, 's1');
      expect(game.selected, 's1');
      final entity = SettlementScene(
        resolved.settlement,
      ).entities.firstWhere((e) => e.id == person.id);
      expect(
        (game.entityScreenPosition('s1', entity) - game.center).distance,
        lessThan(1e-8),
      );
      expect(jsonEncode(relocated), confirmed);
      expect(relocated['controlledId'], w.controlledId);

      game.fitWorld();
      expect(game.followedIndividualId, isNull);
      expect(saved.target.resolve(relocated)!.name, person.name);
      expect(game.followIndividual(person.id), isTrue);
      game.onGameResize(Vector2(412, 560));
      expect(
        (game.entityScreenPosition('s1', entity) - game.center).distance,
        lessThan(1e-8),
      );

      relocated['societies'][1]['people'].last['diedDay'] = 30;
      game.present(relocated, generation: 1);
      expect(game.followedIndividualId, isNull);
      expect(saved.target.resolve(relocated)!.alive, isFalse);
      expect(game.followIndividual(person.id), isFalse);
    },
  );

  test(
    'Camera preference rejects corruption and another world or identity',
    () {
      final w = WorldState.generate(seed: 17, size: 64).toJson();
      final p = Map<String, dynamic>.from(w['societies'][0]['people'][0]);
      final target = FollowTarget.person(w, p);
      expect(FollowTarget.decode('{'), isNull);
      expect(FollowTarget.decode('{}'), isNull);
      expect(
        FollowTarget.decode(target.encode(active: false))!.active,
        isFalse,
      );
      expect(target.resolve({...w, 'seed': 18}), isNull);
      expect(
        FollowTarget(
          target.worldKey,
          target.individualId,
          target.bornDay + 1,
        ).resolve(w),
        isNull,
      );
      final game = WorldGame((_) {});
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(320, 400));
      game.present(w, generation: 1);
      game.followIndividual(target.individualId);
      game.present(w, generation: 2);
      expect(game.followedIndividualId, isNull);
      expect(game.toWorld(game.center), const Offset(32, 32));
    },
  );
}
