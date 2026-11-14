import 'dart:convert';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/world_game.dart';
import 'package:barrio_cero_eras/presentation/planet_camera.dart';
import 'package:barrio_cero_eras/presentation/planet_terrain.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import '../tool/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'The focal point keeps its planet coordinates across all levels of detail',
    () {
      final world = WorldState.generate(seed: 17, size: 64);
      var changes = 0;
      final game = WorldGame((_) {}, onViewChanged: () => changes++);
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(320, 400));
      game.present(world.toJson(), generation: 1);
      game.locate('s0');
      final before = jsonEncode(game.data);
      const focus = Offset(110, 165);
      final point = game.toWorld(focus);
      final levels = <String>{game.mode};
      for (final scale in [3.0, 20.0, 80.0, 140.0, 30.0, 2.0, 1.0]) {
        game.zoomAt(scale, focus);
        levels.add(game.mode);
        expect((game.toWorld(focus) - point).distance, lessThan(1e-9));
      }
      expect(game.mode, 'Mundo');
      expect(levels, containsAll(['Mundo', 'Región', 'Asentamiento']));
      expect(changes, greaterThan(0));
      expect(jsonEncode(game.data), before);
      expect(world.day, 0);
    },
  );
  test(
    'Deep zoom on empty ground never opens or centers an unrelated town',
    () {
      final w = WorldState.generate(seed: 17, size: 64);
      final game = WorldGame((_) {});
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(320, 400));
      game.present(w.toJson(), generation: 1);
      game.selected = 's0';
      final empty = w.tiles.firstWhere(
        (t) =>
            w.societies.every((s) => (s.x - t.x).abs() + (s.y - t.y).abs() > 5),
      );
      final point = Offset(empty.x + .5, empty.y + .5),
          screen = game.toScreen(Offset(empty.x + .5, empty.y + .5));
      game.zoomAt(120, screen);
      expect(game.mode, 'Asentamiento');
      expect((game.toWorld(screen) - point).distance, lessThan(1e-9));
      expect(game.selected, 's0');
      expect(game.localSelected, isNull);
    },
  );
  test(
    'Panning reaches a second city and picks it in the same coordinate frame',
    () {
      final w = WorldState.generate(seed: 17, size: 64);
      String? actor;
      LocalSelection? hit;
      final game = WorldGame((id) => actor = id, onLocalSelect: (e) => hit = e);
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(360, 440));
      game.present(w.toJson(), generation: 1);
      game.focusSettlement('s0');
      final scale = game.zoom,
          a = game.position(game.societies[0]),
          b = game.position(game.societies[1]);
      game.pan -= (b - a) * game.unit;
      expect((game.toWorld(game.center) - b).distance, lessThan(1e-9));
      final target = SettlementScene(w.societies[1].toJson()).entities.first;
      game.touch(game.entityScreenPosition('s1', target));
      expect(actor, 's1');
      expect(hit?.id, target.id);
      expect(game.zoom, scale);
      expect(game.mode, 'Asentamiento');
      final origin = Offset(
        w.societies[1].x.toDouble(),
        w.societies[1].y.toDouble(),
      );
      expect(
        game.entityWorldBounds('s1', target),
        PlanetCamera.localRectToWorld(origin, target.bounds),
      );
    },
  );
  test(
    '32 valid settlements render, reuse caches and cull hidden detail without changing the world',
    () {
      final w = WorldState.generate(seed: 73, size: 96);
      for (var i = w.societies.length; i < 32; i++) {
        final tile = w.tiles.firstWhere(
          (t) =>
              t.passable &&
              w.societies.every(
                (s) => (s.x - t.x).abs() + (s.y - t.y).abs() >= 3,
              ),
        );
        final s = Society(
          'load$i',
          'Comunidad $i',
          'cooperativa',
          tile.x,
          tile.y,
          materialRules: 2,
        );
        s.catalog = w.catalog;
        s.people = [
          Person('load:$i', 'Ada $i', 'técnica', -28 * 360, 'inventive'),
        ];
        s.leaderId = s.people.single.id;
        s.ensureSites();
        w.societies.add(s);
      }
      fixturePopulation(w);
      w.validate();
      final before = w.canonical();
      final game = WorldGame((_) {});
      addTearDown(game.terrainCache.clear);
      game.onGameResize(Vector2(360, 440));
      game.present(w.toJson(), generation: 1);
      game.selected = 's0';
      game.mini = false;
      void render() {
        final recorder = PictureRecorder();
        game.render(Canvas(recorder));
        recorder.endRecording().dispose();
      }

      render();
      expect(game.lastSettlementsDrawn, 32);
      expect(game.lastSitesDrawn, 0);
      final blocks = game.lastTerrainBlocksDrawn;
      game.focusSettlement('s0');
      render();
      expect(game.lastSettlementsDrawn, 1);
      expect(game.lastSitesDrawn, w.societies.first.sites.length);
      expect(
        game.lastPeopleDrawn,
        w.societies.first.people.where((p) => p.alive).length,
      );
      expect(game.lastTerrainBlocksDrawn, lessThan(blocks));
      final cache = game.terrainCache.cachedBytes;
      game.present(w.toJson(), generation: 1);
      render();
      expect(game.terrainCache.cachedBytes, cache);
      expect(cache, lessThanOrEqualTo(PlanetTerrain.maxCacheBytes));
      expect(w.canonical(), before);
      expect(jsonEncode(game.data), jsonEncode(w.toJson()));
    },
  );
}
