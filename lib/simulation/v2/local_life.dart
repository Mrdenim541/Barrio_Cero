import 'local_paths.dart';

/// Optional versioned local positions. Visits do not manufacture production or
/// assign a featured person to collective labor. They advance without a camera.
class LocalResident {
  final String id;
  List<int> route;
  int progress, previous, wait;
  String? destination;
  LocalResident(this.id, int cell)
    : route = [cell],
      progress = 0,
      previous = cell,
      wait = 0;
  int get cell => route[progress];
  Map<String, dynamic> toJson() => {
    'id': id,
    'route': route,
    'progress': progress,
    'previous': previous,
    'wait': wait,
    'destination': destination,
  };
  factory LocalResident.fromJson(Map raw) {
    if (raw['id'] is! String ||
        raw['route'] is! List ||
        (raw['route'] as List).isEmpty ||
        (raw['route'] as List).length > 1024 ||
        (raw['route'] as List).any((c) => c is! int || c < 0 || c >= 1024) ||
        raw['progress'] is! int ||
        raw['progress'] < 0 ||
        raw['progress'] >= raw['route'].length ||
        raw['previous'] is! int ||
        raw['previous'] < 0 ||
        raw['previous'] >= 1024 ||
        raw['wait'] is! int ||
        raw['wait'] < 0 ||
        raw['wait'] > 30 ||
        (raw['destination'] != null && raw['destination'] is! String)) {
      throw const FormatException('Recorrido local inválido');
    }
    final value = LocalResident(raw['id'], raw['route'][0]);
    value.route = List<int>.from(raw['route']);
    value.progress = raw['progress'];
    value.previous = raw['previous'];
    value.wait = raw['wait'];
    value.destination = raw['destination'];
    for (var i = 1; i < value.route.length; i++) {
      if ((value.route[i] % 32 - value.route[i - 1] % 32).abs() +
              (value.route[i] ~/ 32 - value.route[i - 1] ~/ 32).abs() !=
          1) {
        throw const FormatException('Salto en un recorrido local');
      }
    }
    return value;
  }
}

class LocalLife {
  int day;
  final Map<String, LocalResident> residents = {};
  LocalPaths? _grid;
  String _layout = '';
  LocalLife(this.day);
  void advance(int date, List<Map> people, List<Map> sites) {
    if (date < day) throw const FormatException('Retroceso de vida local');
    final layout = sites.map((s) => '${s['id']}:${s['x']}:${s['y']}').join('|');
    final ids = people.map((p) => p['id']).toSet();
    if (date == day &&
        _grid != null &&
        layout == _layout &&
        residents.length == ids.length &&
        residents.keys.every(ids.contains)) {
      return;
    }
    if (_grid == null || layout != _layout) {
      _layout = layout;
      _grid = LocalPaths(sites);
    }
    final grid = _grid!;
    residents.removeWhere((id, _) => !ids.contains(id));
    final ordered = people.toList()
      ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    for (final person in ordered) {
      final id = '${person['id']}';
      var value = residents[id];
      if (value == null) {
        final start = grid.nearestFree(
          (16 * 32 + 16 + ordered.indexOf(person) * 2) % 1024,
        );
        if (start == null) continue;
        value = LocalResident(id, start);
        residents[id] = value;
      }
      final r=value;
      if (!grid.free(r.cell)) {
        final cell = grid.nearestFree(r.cell);
        if (cell == null) continue;
        r.route = [cell];
        r.progress = 0;
        r.previous = cell;
      }
      if (date != day) r.previous = r.cell;
      if (r.destination != null &&
          !sites.any((s) => s['id'] == r.destination)) {
        r.destination = null;
        r.route = [r.cell];
        r.progress = 0;
        r.wait = 0;
      }
      if (r.route.skip(r.progress).any((c) => !grid.free(c))) {
        r.route = [r.cell];
        r.progress = 0;
        r.wait = 0;
      }
      if (date == day) continue;
      if (r.progress < r.route.length - 1) {
        r.progress++;
        continue;
      }
      if (r.wait > 0) {
        r.wait--;
        continue;
      }
      if (sites.isEmpty) continue;
      final salt = id.codeUnits.fold<int>(0, (a, b) => a * 31 + b) & 0x7fffffff;
      for (var n = 0; n < sites.length; n++) {
        final site = sites[(salt + date ~/ 7 + n) % sites.length];
        if (site['id'] == r.destination && sites.length > 1) continue;
        final entries = grid.entrances(site)
          ..sort(
            (a, b) =>
                grid.distance(a, r.cell).compareTo(grid.distance(b, r.cell)),
          );
        List<int> path = [];
        for (final end in entries) {
          path = grid.path(r.cell, end);
          if (path.isNotEmpty) break;
        }
        if (path.isEmpty) continue;
        r.route = path;
        r.progress = path.length > 1 ? 1 : 0;
        r.wait = 3;
        r.destination = site['id'];
        break;
      }
    }
    day = date;
  }

  void validate(Set<String> living, Set<String> sites, int date) {
    if (day != date ||
        residents.length != living.length ||
        residents.keys.any((id) => !living.contains(id)) ||
        residents.values.any(
          (r) => r.destination != null && !sites.contains(r.destination),
        )) {
      throw const FormatException('Vida local sin residente o lugar válido');
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'day': day,
    'residents': [
      for (final id in (residents.keys.toList()..sort()))
        residents[id]!.toJson(),
    ],
  };
  factory LocalLife.fromJson(Map raw) {
    if (raw['version'] != 1 ||
        raw['day'] is! int ||
        raw['day'] < 0 ||
        raw['residents'] is! List) {
      throw const FormatException('Versión de vida local inválida');
    }
    final value = LocalLife(raw['day']);
    for (final row in raw['residents']) {
      final r = LocalResident.fromJson(row as Map);
      if (value.residents.containsKey(r.id)) {
        throw const FormatException('Residente local duplicado');
      }
      value.residents[r.id] = r;
    }
    return value;
  }
}
