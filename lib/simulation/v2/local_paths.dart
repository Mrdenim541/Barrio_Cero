import 'dart:collection';

class LocalPaths {
  final blocked = <int>{};
  final Map<int, List<int>> _cache = {};
  LocalPaths(List<Map> sites) {
    for (final s in sites) {
      for (var y = s['y'] as int; y < (s['y'] as int) + 2; y++) {
        for (var x = s['x'] as int; x < (s['x'] as int) + 2; x++) {
          blocked.add(y * 32 + x);
        }
      }
    }
  }
  bool free(int c) => c >= 0 && c < 1024 && !blocked.contains(c);
  int distance(int a, int b) =>
      (a % 32 - b % 32).abs() + (a ~/ 32 - b ~/ 32).abs();
  Iterable<int> neighbors(int c) sync* {
    if (c % 32 > 0) yield c - 1;
    if (c % 32 < 31) yield c + 1;
    if (c >= 32) yield c - 32;
    if (c < 992) yield c + 32;
  }

  int? nearestFree(int start) {
    if (free(start)) return start;
    for (var radius = 0; radius < 64; radius++) {
      for (var c = 0; c < 1024; c++) {
        if (free(c) && distance(start, c) == radius) return c;
      }
    }
    return null;
  }

  List<int> entrances(Map site) {
    final x = site['x'] as int, y = site['y'] as int;
    final result = <int>[];
    void add(int xx, int yy) {
      if (xx >= 0 && xx < 32 && yy >= 0 && yy < 32 && free(yy * 32 + xx)) {
        result.add(yy * 32 + xx);
      }
    }

    for (var i = 0; i < 2; i++) {
      add(x + i, y - 1);
      add(x + i, y + 2);
      add(x - 1, y + i);
      add(x + 2, y + i);
    }
    return result..sort();
  }

  List<int> path(int start, int end) {
    if (!free(start) || !free(end)) return [];
    final key = start * 1024 + end, cached = _cache[key];
    if (cached != null) return cached;
    final queue = Queue<int>()..add(start), previous = <int, int>{start: start};
    while (queue.isNotEmpty && !previous.containsKey(end)) {
      final c = queue.removeFirst();
      for (final n in neighbors(c)) {
        if (free(n) && !previous.containsKey(n)) {
          previous[n] = c;
          queue.add(n);
        }
      }
    }
    if (!previous.containsKey(end)) return [];
    final result = [end];
    while (result.last != start) {
      result.add(previous[result.last]!);
    }
    final path = List<int>.unmodifiable(result.reversed);
    if (_cache.length >= 256) _cache.remove(_cache.keys.first);
    _cache[key] = path;
    return path;
  }
}
