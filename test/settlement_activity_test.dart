import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/settlement_activity.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  test('Activity accounts for all real labor without changing the world', () {
    final world = WorldState.generate(
      seed: 73,
      size: 64,
      origin: 'prehistory',
      geographyVersion: 2,
    )..controlledId = null;
    final sim = Simulation(world)
      ..registerContent(
        jsonDecode(File('assets/content/core.json').readAsStringSync()),
      );
    sim.advanceDays(30);
    final before = world.canonical();
    final raw = world.toJson();
    for (final town
        in (raw['societies'] as List).cast<Map<String, dynamic>>()) {
      final activity = SettlementActivity.fromWorld(raw, town);
      final allocations =
          (town['lastProduction']['flows']['allocations'] as Map).values
              .cast<int>();
      expect(activity.laborMillis, allocations.fold<int>(0, (a, b) => a + b));
      expect(
        activity.sites.fold<int>(0, (a, b) => a + b.laborMillis) +
            activity.otherLabor.values.fold<int>(0, (a, b) => a + b),
        activity.laborMillis,
      );
      for (final site in activity.sites) {
        expect(
          (town['sites'] as List)
              .where((s) => s['building'] == site.building)
              .length,
          1,
        );
      }
    }
    expect(world.canonical(), before);
  });

  Map<String, dynamic> town() => {
    'id': 'a',
    'population': 10,
    'sites': [
      {'id': 'a:1', 'building': 'water'},
    ],
    'lastProduction': {
      'day': 12,
      'flows': {
        'allocations': {'water': 1500, 'work:gather_wood': 2000},
        'produced': {'water': 1800},
      },
    },
    'projects': [
      {
        'building': 'shelter',
        'work': {
          'id': 'p',
          'remaining': 30,
          'totalWork': 100,
          'workers': 4,
          'paused': true,
        },
      },
    ],
    'lessons': [
      {
        'course': 'healing',
        'work': {
          'id': 'l',
          'remaining': 45,
          'totalWork': 60,
          'workers': 2,
          'paused': false,
        },
      },
    ],
  };
  test(
    'Stale production and extinct settlements never animate productive work',
    () {
      final s = town();
      expect(SettlementActivity.fromWorld({'day': 13}, s).sites, isEmpty);
      s['extinct'] = true;
      final activity = SettlementActivity.fromWorld({'day': 12}, s);
      expect(activity.productionDay, isNull);
      expect(activity.laborMillis, 0);
      expect(activity.produced, isEmpty);
    },
  );
  test(
    'Shared building allocation does not invent individual site assignments',
    () {
      final s = town();
      (s['sites'] as List).add({'id': 'a:2', 'building': 'water'});
      final activity = SettlementActivity.fromWorld({'day': 12}, s);
      expect(activity.sites, isEmpty);
      expect(activity.otherLabor['water'], 1500);
    },
  );
  test(
    'Construction and learning show committed remaining work and pause state',
    () {
      final activity = SettlementActivity.fromWorld({'day': 12}, town());
      expect(activity.projects[0].fraction, .7);
      expect(activity.projects[0].paused, isTrue);
      expect(activity.projects[1].fraction, .25);
      expect(activity.projects[1].kind, 'learning');
    },
  );
}
