/// Read-only projection used during generation. No terrain is carved or
/// resources added to make the opening pass its connectivity requirement.
abstract interface class PlacementCell {
  int get x;
  int get y;
  int get biome;
  int get richness;
  bool get passable;
}

List<int> connectedOpeningSites(
  List<PlacementCell> cells,
  int size, {
  required Set<int> biomes,
  required int minimumRichness,
  int count = 6,
  int spacing = 5,
}) {
  if (cells.length != size * size || count < 1 || spacing < 1) {
    throw const FormatException('Plano de apertura inválido');
  }
  bool eligible(int i) =>
      cells[i].passable &&
      biomes.contains(cells[i].biome) &&
      cells[i].richness >= minimumRichness;
  final seen = <int>{}, components = <List<int>>[];
  for (var start = 0; start < cells.length; start++) {
    if (seen.contains(start) || !cells[start].passable) continue;
    final queue = <int>[start], viable = <int>[];
    seen.add(start);
    for (var head = 0; head < queue.length; head++) {
      final i = queue[head], x = i % size, y = i ~/ size;
      if (eligible(i)) viable.add(i);
      for (final q in [
        if (x > 0) i - 1,
        if (x < size - 1) i + 1,
        if (y > 0) i - size,
        if (y < size - 1) i + size,
      ]) {
        if (!seen.contains(q) && cells[q].passable) {
          seen.add(q);
          queue.add(q);
        }
      }
    }
    if (viable.length >= count) {
      viable.sort();
      components.add(viable);
    }
  }
  components.sort((a, b) {
    final n = b.length.compareTo(a.length);
    return n == 0 ? a.first.compareTo(b.first) : n;
  });
  bool fits(int i, List<int> selected) => selected.every(
    (j) =>
        (cells[i].x - cells[j].x).abs() + (cells[i].y - cells[j].y).abs() >=
        spacing,
  );
  for (final component in components) {
    final selected = <int>[];
    for (var city = 0; city < count; city++) {
      final x = (size * (.2 + (city % 3) * .28)).round(),
          y = (size * (.25 + (city ~/ 3) * .45)).round();
      final choices = component.where((i) => fits(i, selected)).toList()
        ..sort((a, b) {
          final da = (cells[a].x - x).abs() + (cells[a].y - y).abs(),
              db = (cells[b].x - x).abs() + (cells[b].y - y).abs();
          return da == db ? a.compareTo(b) : da.compareTo(db);
        });
      if (choices.isEmpty) break;
      selected.add(choices.first);
    }
    if (selected.length == count) return List.unmodifiable(selected);
    // Narrow components may need another packing order. This fallback is
    // deterministic and checks spacing again; it does not relax viability.
    final scanned = <int>[];
    for (final i in component) {
      if (fits(i, scanned)) scanned.add(i);
      if (scanned.length == count) return List.unmodifiable(scanned);
    }
  }
  throw const FormatException(
    'No hay terreno conectado y viable para todas las comunidades iniciales',
  );
}
