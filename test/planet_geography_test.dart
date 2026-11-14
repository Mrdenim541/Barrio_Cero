import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  test('Compact settlement layout preserves all 196 non-overlapping plots', () {
    final town = Society('layout', 'Prueba', 'balanced', 0, 0, siteLayout: 3)
      ..sites.clear();
    for (var n = 0; n < 196; n++) {
      town.addSite('house');
    }
    final occupied = <int>{};
    for (final site in town.sites) {
      for (var dy = 0; dy < 2; dy++) {
        for (var dx = 0; dx < 2; dx++) {
          expect(occupied.add((site.y + dy) * 32 + site.x + dx), isTrue);
        }
      }
    }
    expect(() => town.addSite('house'), throwsStateError);
    expect(town.sites.length, 196);
  });
  final source = File('assets/content/core.json').readAsStringSync();
  final content = jsonDecode(source) as Map<String, dynamic>;
  test('Legacy recipe remains byte-equivalent to the 0.17 source vectors', () {
    // Captured by executing 2a590bf's archived source, before this change.
    const vectors = {
      'prehistory:17':
          'a5f3b726a3ae32a6456e906c04d251f4cd17a2f3ff1cadf84786ac469ae14d31',
      'prehistory:42':
          'e2406bc72ad241f7437faaad543704c2520071f7faef3fcb076ebc768652e0b5',
      'reconstruction:17':
          'e44c6458fc7657663da9dd55d280712b62f7f280d88dbdb6bd623cf9c6b54219',
      'reconstruction:42':
          'be026627a1ddc945cbe98bfd307bed817dde0c90c4985c3553064c5b1a1a462c',
    };
    for (final origin in ['prehistory', 'reconstruction']) {
      for (final seed in [17, 42]) {
        final world = WorldState.generate(seed: seed, size: 64, origin: origin);
        expect(
          sha256.convert(utf8.encode(world.canonical())).toString(),
          vectors['$origin:$seed'],
        );
        expect(world.toJson().containsKey('geographyVersion'), isFalse);
        expect(
          WorldState.fromJson(world.toJson()).canonical(),
          world.canonical(),
        );
      }
    }
  });

  test(
    'Continents have ocean margins and six viable, connected societies for both origins',
    () {
      final biomes = <int>{};
      for (final size in [64, 96]) {
        for (var seed = 0; seed < 8; seed++) {
          for (final origin in ['prehistory', 'reconstruction']) {
            final world = WorldState.generate(
              seed: seed,
              size: size,
              origin: origin,
              geographyVersion: 2,
            );
            world.validate();
            final ocean = world.tiles.where((t) => t.biome == 5).length;
            expect(ocean, greaterThan(size * size * .20));
            expect(ocean, lessThan(size * size * .85));
            expect(
              world.tiles
                  .where(
                    (t) =>
                        t.x == 0 ||
                        t.y == 0 ||
                        t.x == size - 1 ||
                        t.y == size - 1,
                  )
                  .every((t) => t.biome == 5),
              isTrue,
            );
            expect(world.societies.length, 6);
            expect(
              world.societies.every(
                (s) => world.tiles[s.y * size + s.x].passable,
              ),
              isTrue,
            );
            biomes.addAll(world.tiles.map((t) => t.biome));
            final checkpoint = Checkpoint.create(
              world: world,
              coreSource: source,
            );
            final loaded = Checkpoint.decode(checkpoint.encode());
            expect(loaded.world.geographyVersion, 2);
            expect(loaded.world.canonical(), checkpoint.world.canonical());
          }
        }
      }
      expect(biomes, {0, 1, 2, 3, 4, 5});
      final bad = WorldState.generate(size: 64).toJson()
        ..['geographyVersion'] = 99;
      expect(() => WorldState.fromJson(bad), throwsFormatException);
    },
  );

  test(
    'New geography retains daily equivalence with a saved autonomous year',
    () {
      final a = WorldState.generate(
        seed: 73,
        size: 64,
        origin: 'prehistory',
        geographyVersion: 2,
        extraordinary: false,
      )..controlledId = null;
      final b = WorldState.fromJson(a.toJson());
      final daily = Simulation(a)..registerContent(content);
      for (var i = 0; i < 360; i++) {
        daily.advanceDays(1);
      }
      (Simulation(b)..registerContent(content)).advanceDays(180);
      final checkpoint = Checkpoint.create(
        world: b,
        coreSource: source,
        stopCrisis: false,
      );
      final loaded = Checkpoint.decode(checkpoint.encode()).world;
      (Simulation(loaded)..registerContent(content)).advanceDays(180);
      // Bind the same pinned content before comparing complete states.
      final finalA = Checkpoint.create(
        world: a,
        coreSource: source,
        stopCrisis: false,
      ).world;
      expect(loaded.canonical(), finalA.canonical());
      expect(loaded.day, 360);
    },
  );
}
