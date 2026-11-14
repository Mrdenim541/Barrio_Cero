import 'dart:math' as math;
import 'dart:ui';
import '../simulation/v2/local_paths.dart';

/// Cohort figures illustrate confirmed collective labor, never extra population
/// or a named person's invented occupation. Local paths avoid built footprints.
class WorkCrew {
  final String id, building, siteId;
  final int adults, laborMillis;
  final List<int> route;
  const WorkCrew(
    this.id,
    this.building,
    this.siteId,
    this.adults,
    this.laborMillis,
    this.route,
  );
  double phase(double seconds) =>
      (seconds / 12 + id.codeUnits.fold<int>(0, (a, b) => a + b) % 17 / 17) % 1;
  int action(double seconds) {
    final p = phase(seconds);
    return p < .25
        ? 1
        : p < .65
        ? 2
        : p < .9
        ? 3
        : 4;
  }

  Offset position(double seconds) {
    final p = phase(seconds);
    final t = p < .25
        ? p / .25
        : p < .65
        ? 1.0
        : p < .9
        ? 1 - (p - .65) / .25
        : 0.0;
    final distance = t * (route.length - 1), i = distance.floor();
    Offset at(int c) => Offset((c % 32 + .5) * 32, (c ~/ 32 + .5) * 32);
    return Offset.lerp(
      at(route[i]),
      at(route[math.min(i + 1, route.length - 1)]),
      distance - i,
    )!;
  }
}

class LocalWorkday {
  final List<WorkCrew> crews;
  final int commonAdults;
  const LocalWorkday(this.crews, this.commonAdults);
  factory LocalWorkday.read(
    Map<String, dynamic> world,
    Map<String, dynamic> town,
  ) {
    final day = world['day'] as int? ?? 0, balance = town['lastProduction'];
    if (town['extinct'] == true || balance is! Map || balance['day'] != day) {
      return const LocalWorkday([], 0);
    }
    final named = (town['people'] as List? ?? [])
        .where(
          (p) =>
              p['diedDay'] == null &&
              day - (p['bornDay'] as int) >= 16 * 360 &&
              day - (p['bornDay'] as int) < 65 * 360,
        )
        .length;
    final common = math.max(0, (town['adults'] as int? ?? 0) - named);
    var remaining = common;
    final sites = (town['sites'] as List? ?? []).cast<Map>().toList()
      ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    final grid = LocalPaths(sites);
    final houses = sites.where(
      (s) => ['house', 'shelter', 'habitat'].contains(s['building']),
    );
    final start = houses.isEmpty
        ? grid.nearestFree(16 * 32 + 16)
        : grid.entrances(houses.first).firstOrNull;
    if (start == null) return LocalWorkday(const [], common);
    final allocations = balance['flows']['allocations'] as Map;
    final crews = <WorkCrew>[];
    final keys = allocations.keys.map((k) => '$k').toList()..sort();
    for (final key in keys) {
      var labor = allocations[key] as int;
      for (final site in sites.where((s) => s['building'] == key)) {
        if (labor <= 0 || remaining == 0 || crews.length >= 16) break;
        final assigned = math.min(labor, math.min(2000, remaining * 1000));
        final entrances = grid.entrances(site)
          ..sort(
            (a, b) =>
                grid.distance(a, start).compareTo(grid.distance(b, start)),
          );
        List<int> path = [];
        for (final end in entrances) {
          path = grid.path(start, end);
          if (path.isNotEmpty) break;
        }
        if (path.isEmpty) continue;
        final count = (assigned + 999) ~/ 1000;
        crews.add(
          WorkCrew(
            '${town['id']}:${site['id']}',
            key,
            '${site['id']}',
            count,
            assigned,
            List.unmodifiable(path),
          ),
        );
        remaining -= count;
        labor -= assigned;
      }
    }
    return LocalWorkday(List.unmodifiable(crews), common);
  }
}
