import 'rule_catalog.dart';

/// An opening state, not an era label. The generator must still find viable
/// terrain and every subsequent change is processed by the ordinary engine.
class StartingScenario {
  final String id, name, description;
  final int children, adults, elders, minRichness;
  final Set<int> biomes;
  final Map<String, double> stocks;
  final Map<String, int> built;
  final Set<String> knowledge;
  final List<Map<String, dynamic>> people;
  StartingScenario._(
    this.id,
    this.name,
    this.description,
    this.children,
    this.adults,
    this.elders,
    this.minRichness,
    this.biomes,
    this.stocks,
    this.built,
    this.knowledge,
    this.people,
  );

  factory StartingScenario.fromJson(
    Map<String, dynamic> raw,
    RuleCatalog catalog,
  ) {
    const keys = {
      'id',
      'name',
      'description',
      'population',
      'minRichness',
      'biomes',
      'stocks',
      'buildings',
      'knowledge',
      'people',
    };
    if (raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        !['prehistory', 'reconstruction'].contains(raw['id']) ||
        raw['name'] is! String ||
        raw['description'] is! String ||
        raw['population'] is! Map ||
        raw['stocks'] is! Map ||
        raw['buildings'] is! Map ||
        raw['knowledge'] is! List ||
        raw['biomes'] is! List ||
        raw['people'] is! List ||
        raw['minRichness'] is! int ||
        raw['minRichness'] < 1 ||
        raw['minRichness'] > 5) {
      throw const FormatException('Origen incompatible');
    }
    final p = raw['population'] as Map;
    if (p.length != 3 ||
        [
          'children',
          'adults',
          'elders',
        ].any((k) => p[k] is! int || p[k] < 0 || p[k] > 1000) ||
        p['adults'] < 4) {
      throw const FormatException('Población inicial inválida');
    }
    final stocks = <String, double>{};
    for (final r in RuleCatalog.resources) {
      final value = raw['stocks'][r];
      if (value is! num ||
          !value.isFinite ||
          value < 0 ||
          value > 100000 ||
          (value * 1000 - (value * 1000).round()).abs() > .000001) {
        throw const FormatException('Reservas iniciales inválidas');
      }
      stocks[r] = value.toDouble();
    }
    if ((raw['stocks'] as Map).length != stocks.length) {
      throw const FormatException('Recurso inicial desconocido');
    }
    final built = <String, int>{};
    for (final e in (raw['buildings'] as Map).entries) {
      if (e.key is! String ||
          e.value is! int ||
          e.value < 1 ||
          e.value > 196 ||
          !catalog.buildings.any((b) => b.id == e.key)) {
        throw const FormatException('Edificio inicial desconocido');
      }
      built[e.key] = e.value;
    }
    final known = Set<String>.from(raw['knowledge']);
    if (known.any((id) => !catalog.technologies.any((t) => t.id == id)) ||
        built.values.fold<int>(0, (a, b) => a + b) > 196) {
      throw const FormatException('Conocimientos o espacio inicial inválidos');
    }
    final biomes = Set<int>.from(raw['biomes']);
    if (biomes.isEmpty || biomes.any((b) => ![0, 1, 2, 4].contains(b))) {
      throw const FormatException('Biomas iniciales no transitables');
    }
    final people = <Map<String, dynamic>>[];
    for (final person in raw['people']) {
      if (person is! Map ||
          person.length != 4 ||
          person['name'] is! String ||
          person['role'] is! String ||
          person['trait'] is! String ||
          person['age'] is! int ||
          person['age'] < 16 ||
          person['age'] >= 65) {
        throw const FormatException('Habitante inicial inválido');
      }
      people.add(Map.unmodifiable(Map<String, dynamic>.from(person)));
    }
    if (people.isEmpty || people.length > p['adults']) {
      throw const FormatException(
        'Habitantes destacados fuera de su población',
      );
    }
    final capacity = catalog.buildings.fold<int>(
      0,
      (total, b) => total + (built[b.id] ?? 0) * b.housingCapacity,
    );
    if (capacity < p['children'] + p['adults'] + p['elders']) {
      throw const FormatException(
        'El origen carece de refugio para su población',
      );
    }
    return StartingScenario._(
      raw['id'],
      raw['name'],
      raw['description'],
      p['children'],
      p['adults'],
      p['elders'],
      raw['minRichness'],
      Set.unmodifiable(biomes),
      Map.unmodifiable(stocks),
      Map.unmodifiable(built),
      Set.unmodifiable(known),
      List.unmodifiable(people),
    );
  }
}
