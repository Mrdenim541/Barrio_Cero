import 'dart:convert';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/world_game.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  test(
    'Zoom follows the same settlement through planet, region, local and back without simulation effects',
    () {
      final world = WorldState.generate(seed: 17, size: 64);
      var changes = 0;
      final game = WorldGame((_) {}, onViewChanged: () => changes++);
      game.onGameResize(Vector2(320, 400));
      game.present(world.toJson(), generation: 1);
      final before = jsonEncode(game.data);
      game.locate('s0');
      game.zoomAt(3, game.center);
      expect(game.mode, 'Región');
      game.zoomAt(6, game.center);
      expect(game.mode, 'Asentamiento');
      expect(game.selected, 's0');
      final scene = SettlementScene(world.societies.first.toJson());
      const focus = Offset(100, 140);
      final local = scene.toLocal(
        focus,
        const Size(320, 400),
        game.pan,
        game.zoom,
      );
      game.zoomAt(2.2, focus);
      expect(
        (scene.toLocal(focus, const Size(320, 400), game.pan, game.zoom) -
                local)
            .distance,
        lessThan(.001),
      );
      game.zoomAt(.6, game.center);
      expect(game.mode, 'Región');
      expect(game.selected, 's0');
      game.zoomAt(1, game.center);
      expect(game.mode, 'Mundo');
      expect(changes, 4);
      expect(jsonEncode(game.data), before);
      expect(world.day, 0);
    },
  );

  test(
    'Zooming empty territory never opens an unrelated selected settlement',
    () {
      final world = WorldState.generate(seed: 17, size: 64);
      final game = WorldGame((_) {});
      game.onGameResize(Vector2(320, 400));
      game.present(world.toJson(), generation: 1);
      game.selected = 's0';
      final empty = world.tiles.firstWhere(
        (t) => world.societies.every(
          (s) =>
              (Offset(s.x.toDouble(), s.y.toDouble()) -
                      Offset(t.x.toDouble(), t.y.toDouble()))
                  .distance >
              4,
        ),
      );
      final focus =
          game.center +
          (Offset(empty.x.toDouble(), empty.y.toDouble()) -
                  const Offset(32, 32)) *
              game.unit;
      game.zoomAt(9, focus);
      expect(game.mode, 'Región');
      expect(game.selected, 's0');
    },
  );
}
