import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/world_game.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  test(
    'Visual completion follows a confirmed site, expires in reduced motion, and never changes time',
    () {
      final world = WorldState.generate(
        seed: 17,
        size: 64,
        origin: 'prehistory',
      );
      final game = WorldGame((_) {});
      game.present(world.toJson(), generation: 1);
      expect(
        game.recentSites,
        isEmpty,
        reason: 'Restoring a world is not a new construction',
      );
      final simulation = Simulation(world);
      expect(
        simulation
            .submit(
              Command(
                id: 'real-refuge',
                action: 'build',
                actorId: world.controlledId,
                issuedDay: 0,
                target: 'shelter',
              ),
            )
            .ok,
        isTrue,
      );
      game.present(world.toJson(), generation: 1);
      expect(
        game.recentSites,
        isEmpty,
        reason: 'An ordered project is not a finished site',
      );
      simulation.advanceDays(10);
      world.validate();
      final before = world.canonical();
      game.present(world.toJson(), generation: 1);
      expect(game.recentSites.length, 1);
      game.reduceMotion = true;
      game.update(2);
      game.present(world.toJson(), generation: 1);
      game.update(2);
      expect(
        game.recentSites,
        isEmpty,
        reason: 'A repeated notification cannot keep a highlight alive',
      );
      expect(game.phase, 0);
      expect(world.canonical(), before);
      game.present(
        WorldState.generate(seed: 18, size: 64).toJson(),
        generation: 2,
      );
      expect(
        game.recentSites,
        isEmpty,
        reason: 'Changing worlds does not celebrate all sites',
      );
    },
  );
}
