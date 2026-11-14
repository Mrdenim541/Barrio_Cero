import '../tool/fixtures.dart';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  test('New local layouts fit 196 distinct 2x2 footprints and round trip', () {
    final s = Society('s', 'Test', 'balanced', 0, 0);
    for (var i = 0; i < 196; i++) {
      s.addSite('house');
    }
    for (var i = 0; i < s.sites.length; i++) {
      final a = s.sites[i];
      expect(a.x, inInclusiveRange(0, 30));
      expect(a.y, inInclusiveRange(0, 30));
      for (final b in s.sites.skip(i + 1)) {
        expect((a.x - b.x).abs() >= 2 || (a.y - b.y).abs() >= 2, isTrue);
      }
    }
    expect(s.sites.map((s) => s.y).take(7).toSet().length, greaterThan(1));
    expect(Society.fromJson(s.toJson()).toJson(), s.toJson());
  });
  test(
    'Legacy layout preserves bytes, positions and future placement rule',
    () {
      final old = Society('s', 'Test', 'balanced', 0, 0, siteLayout: 1)
        ..ensureSites();
      final raw = old.toJson();
      expect(raw.containsKey('siteLayout'), isFalse);
      final copy = Society.fromJson(raw);
      expect(copy.toJson(), raw);
      copy.addSite('house');
      expect(copy.sites.last.x, 2 + 7 * 2);
      expect(copy.sites.last.y, 2);
    },
  );
  test(
    'Picking uses camera transform at several screen sizes and ignores dead people',
    () {
      final s = WorldState.generate(seed: 42, size: 64).societies.first;
      s.people.first.diedDay = 1;
      final scene = SettlementScene(s.toJson());
      expect(scene.entities.any((e) => e.id == s.people.first.id), isFalse);
      for (final viewport in [const Size(320, 260), const Size(412, 480)]) {
        for (final e in scene.entities) {
          final screen = scene.toScreen(
            e.bounds.center,
            viewport,
            const Offset(10, 12),
            2.3,
          );
          final local = scene.toLocal(
            screen,
            viewport,
            const Offset(10, 12),
            2.3,
          );
          expect((local - e.bounds.center).distance, lessThan(.001));
          expect(scene.pick(local)?.id, e.id);
        }
      }
      expect(scene.pick(const Offset(-100, -100)), isNull);
    },
  );
  test(
    'Invalid layout versions and overlapping new footprints are rejected',
    () {
      final world = WorldState.generate(seed: 42, size: 64);
      final raw = world.toJson();
      (raw['societies'] as List).first['siteLayout'] = 99;
      expect(() => WorldState.fromJson(raw), throwsFormatException);
      final overlap = world.toJson();
      final sites = (overlap['societies'] as List).first['sites'] as List;
      sites[1]['x'] = sites[0]['x'] + 1;
      sites[1]['y'] = sites[0]['y'];
      expect(() => WorldState.fromJson(overlap), throwsFormatException);
    },
  );
  test('Legacy colonies inherit legacy placement rules', () {
    final world = WorldState.generate(seed: 42, size: 64);
    for (final s in world.societies) {
      s.siteLayout = 1;
      s.sites.clear();
      s.ensureSites();
    }
    world.day = 359;
    world.tiles = world.tiles
        .map(
          (t) => Tile(t.x, t.y, 0, t.richness, ruin: t.ruin, damage: t.damage),
        )
        .toList();
    for (final s in world.societies) {
      s.adults = 100;
      s.children = 20;
      for (final r in resourceIds) {
        s.resources[r] = 10000;
      }
    }
    fixturePopulation(world);Simulation(world).advanceDays(1);
    expect(world.societies.length, greaterThan(6));
    expect(world.societies.every((s) => s.siteLayout == 1), isTrue);
    world.validate();
  });
}
