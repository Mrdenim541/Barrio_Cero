import '../simulation/engine.dart';

/// Volatile map data only. No history, packages or save are transported here.
Map<String, dynamic> historyProjection(
  WorldState world,
  Map<int, String> terrain,
) {
  final changed = <Map<String, dynamic>>[];
  for (var i = 0; i < world.tiles.length; i++) {
    final tile = world.tiles[i], token = '${tile.damage}:${tile.ruin}';
    if (terrain[i] != token) {
      terrain[i] = token;
      changed.add({'index': i, 'tile': tile.toJson()});
    }
  }
  return {
    'day': world.day,
    'societies': [
      for (final s in world.societies)
        {
          'id': s.id,
          'name': s.name,
          'x': s.x,
          'y': s.y,
          'population': s.population,
          'adults': s.adults,
          'extinct': s.extinct,
          'health': s.health,
          'sites': [for (final b in s.sites) b.toJson()],
          'people': [for (final p in s.people) p.toJson()],
          if (s.localLife != null) 'localLife': s.localLife!.toJson(),
          'tech': s.tech.toList(),
          'relations': Map<String, int>.from(s.relations),
        },
    ],
    'routes': [for (final r in world.routes) r.toJson()],
    'migrations': [for (final m in world.migrations) m.toJson()],
    'tileUpdates': changed,
  };
}
