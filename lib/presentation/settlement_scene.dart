import 'dart:math' as math;
import 'dart:ui';

/// Display geometry derived only from confirmed sites and living people.
class LocalSelection {
  final String kind, id;
  final Map<String, dynamic> entity;
  final Rect bounds;
  const LocalSelection(this.kind, this.id, this.entity, this.bounds);
}

class SettlementScene {
  final List<LocalSelection> entities;
  SettlementScene(Map<String, dynamic> society) : entities = _entities(society);
  static List<LocalSelection> _entities(Map<String, dynamic> society) {
    final sites = (society['sites'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    final result = <LocalSelection>[
      for (final s in sites)
        LocalSelection(
          'site',
          s['id'].toString(),
          s,
          Rect.fromLTWH(
            (s['x'] as num).toDouble() * 32,
            (s['y'] as num).toDouble() * 32,
            64,
            64,
          ),
        ),
    ];
    final people = (society['people'] as List? ?? [])
        .where((p) => p['diedDay'] == null)
        .toList();
    for (var i = 0; i < people.length; i++) {
      final p = Map<String, dynamic>.from(people[i] as Map);
      final life = ((society['localLife'] as Map?)?['residents'] as List? ?? [])
          .where((r) => r['id'] == p['id'])
          .firstOrNull;
      if (life != null) {
        final cell = life['route'][life['progress']] as int;
        p['_previousCell'] = life['previous'];
        p['_destination'] = life['destination'];
        p['_walking'] = life['previous'] != cell;
        result.add(
          LocalSelection(
            'person',
            '${p['id']}',
            p,
            Rect.fromLTWH(
              (cell % 32 + .5) * 32 - 16,
              (cell ~/ 32 + .5) * 32 - 36,
              32,
              48,
            ),
          ),
        );
        continue;
      }
      final site = sites.isEmpty ? null : sites[i % sites.length];
      final x = site == null ? 224.0 : (site['x'] as num).toDouble() * 32 + 16;
      final y = site == null ? 224.0 : (site['y'] as num).toDouble() * 32 + 72;
      result.add(
        LocalSelection(
          'person',
          p['id'].toString(),
          p,
          Rect.fromLTWH(x + (i ~/ math.max(1, sites.length)) * 36, y, 32, 48),
        ),
      );
    }
    return result;
  }

  Rect get bounds => entities.isEmpty
      ? const Rect.fromLTWH(128, 128, 384, 320)
      : entities
            .map((e) => e.bounds)
            .reduce((a, b) => a.expandToInclude(b))
            .inflate(32);
  Rect get siteBounds {
    final sites = entities.where((e) => e.kind == 'site');
    return sites.isEmpty
        ? bounds
        : sites
              .map((e) => e.bounds)
              .reduce((a, b) => a.expandToInclude(b))
              .inflate(32);
  }

  double scale(Size viewport, double zoom) =>
      math.min(
        viewport.width / math.max(320, bounds.width),
        viewport.height / math.max(256, bounds.height),
      ) *
      (zoom / 1.7);
  Offset toLocal(Offset point, Size viewport, Offset pan, double zoom) =>
      (point - Offset(viewport.width / 2, viewport.height / 2) - pan) /
          scale(viewport, zoom) +
      bounds.center;
  Offset toScreen(Offset point, Size viewport, Offset pan, double zoom) =>
      (point - bounds.center) * scale(viewport, zoom) +
      Offset(viewport.width / 2, viewport.height / 2) +
      pan;
  LocalSelection? pick(Offset point) => entities.reversed
      .where((e) => e.bounds.inflate(6).contains(point))
      .firstOrNull;
}
