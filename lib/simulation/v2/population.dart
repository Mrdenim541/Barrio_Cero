import 'dart:convert';

/// Dates use the simulation's 360-day year. These human life-history boundaries
/// are versioned with this ledger; they are not the political or cultural era.
class PopulationCohort {
  final String id, settlement, culture, species;
  final int bornDay;
  final bool estimated;
  int _count;
  int get count => _count;
  PopulationCohort._(
    this.id,
    this.settlement,
    this.culture,
    this.species,
    this.bornDay,
    this._count, {
    this.estimated = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'settlement': settlement,
    'culture': culture,
    'species': species,
    'bornDay': bornDay,
    'count': count,
    'estimated': estimated,
  };
}

class PopulationTotals {
  final int children, adults, elders;
  const PopulationTotals(this.children, this.adults, this.elders);
  int get total => children + adults + elders;
  int at(int band) => [children, adults, elders][band];
  Map<String, int> toJson() => {
    'children': children,
    'adults': adults,
    'elders': elders,
  };
}

class PopulationChange {
  final int count;
  final List<String> people;
  const PopulationChange(this.count, this.people);
}

/// Authoritative counts and membership. A featured person is one of the
/// residents of a cohort, never an extra resident alongside its count.
class PopulationLedger {
  int day, serial;
  final Map<String, PopulationCohort> _cohorts = {};
  final Map<String, String> _members = {};
  final Map<String, Map<String, dynamic>> _archives = {};
  final Map<String, Set<String>> _featured = {};
  final Map<String, List<int>> _totals = {};
  final Map<String, String> _groups = {};
  final Map<int, Set<String>> _anniversaries = {};
  int? _nextDue;
  final Map<String, Map<String, int>> birthCredits = {};
  PopulationLedger({this.day = 0, this.serial = 0}) {
    if (day < 0 || serial < 0) {
      throw const FormatException('Calendario poblacional inválido');
    }
  }
  Iterable<PopulationCohort> get cohorts => List.unmodifiable(_cohorts.values);
  Map<String, String> get members => Map.unmodifiable(_members);
  Map<String, Map<String, dynamic>> get archives => Map.unmodifiable(_archives);
  PopulationCohort? cohort(String id) => _cohorts[id];
  String? cohortOf(String person) => _members[person];
  int commonIn(String cohortId) =>
      (_cohorts[cohortId]?.count ?? 0) - (_featured[cohortId]?.length ?? 0);
  PopulationTotals totals(String settlement) {
    final n = _totals[settlement] ?? const [0, 0, 0];
    return PopulationTotals(n[0], n[1], n[2]);
  }

  int get total => _cohorts.values.fold(0, (n, c) => n + c.count);
  int age(PopulationCohort c) => (day - c.bornDay) ~/ 360;
  int band(PopulationCohort c) {
    final years = age(c);
    return years < 16
        ? 0
        : years < 65
        ? 1
        : 2;
  }

  static String _group(
    String settlement,
    String culture,
    String species,
    int born,
    bool estimated,
  ) => jsonEncode([settlement, culture, species, born, estimated]);
  void _adjust(String settlement, int band, int amount) {
    final counts = _totals.putIfAbsent(settlement, () => [0, 0, 0]);
    if (counts[band] + amount < 0) {
      throw const FormatException('Recuento poblacional negativo');
    }
    counts[band] += amount;
  }

  void _index(PopulationCohort c) {
    _groups[_group(
          c.settlement,
          c.culture,
          c.species,
          c.bornDay,
          c.estimated,
        )] =
        c.id;
    _adjust(c.settlement, band(c), c.count);
    for (final years in [16, 65, 120]) {
      final date = c.bornDay + years * 360;
      if (date > day) {
        (_anniversaries[date] ??= {}).add(c.id);
        if (_nextDue == null || date < _nextDue!) _nextDue = date;
      }
    }
  }

  String add({
    required String settlement,
    required String culture,
    String species = 'human',
    required int bornDay,
    required int count,
    bool estimated = false,
  }) {
    if (settlement.isEmpty ||
        settlement.length > 128 ||
        culture.isEmpty ||
        culture.length > 128 ||
        species != 'human' ||
        count < 1 ||
        count > 10000000 ||
        bornDay > day ||
        day - bornDay >= 120 * 360 ||
        totals(settlement).total + count > 10000000) {
      throw const FormatException('Grupo poblacional inválido');
    }
    final key = _group(settlement, culture, species, bornDay, estimated);
    final existing = _groups[key];
    if (existing != null) {
      final c = _cohorts[existing]!;
      if (c.count + count > 10000000) {
        throw const FormatException('Grupo demasiado grande');
      }
      c._count += count;
      _adjust(settlement, band(c), count);
      return c.id;
    }
    final id = 'cohort:${serial++}';
    final c = PopulationCohort._(
      id,
      settlement,
      culture,
      species,
      bornDay,
      count,
      estimated: estimated,
    );
    _cohorts[id] = c;
    _index(c);
    return id;
  }

  void register(String person, String cohortId) {
    final c = _cohorts[cohortId];
    if (person.isEmpty ||
        person.length > 128 ||
        _members.containsKey(person) ||
        c == null ||
        (_featured[cohortId]?.length ?? 0) >= c.count) {
      throw const FormatException('Persona duplicada o sin plaza en su grupo');
    }
    _members[person] = cohortId;
    (_featured[cohortId] ??= {}).add(person);
  }

  /// Advances only due age boundaries. The caller must resolve returned maximum
  /// age cohorts as deaths before confirming the day; they cannot act forever.
  List<String> advanceTo(int nextDay) {
    if (nextDay < day) {
      throw const FormatException('La población no retrocede en el tiempo');
    }
    if (_nextDue == null || nextDay < _nextDue!) {
      day = nextDay;
      return [];
    }
    final due = _anniversaries.keys.where((d) => d <= nextDay).toList()..sort();
    final expired = <String>{};
    for (final date in due) {
      final ids = _anniversaries.remove(date)!.toList()..sort();
      for (final id in ids) {
        final c = _cohorts[id];
        if (c == null) continue;
        final years = (date - c.bornDay) ~/ 360;
        if (years == 120) {
          expired.add(id);
          continue;
        }
        _adjust(c.settlement, years == 16 ? 0 : 1, -c.count);
        _adjust(c.settlement, years == 16 ? 1 : 2, c.count);
      }
    }
    day = nextDay;
    _nextDue = _anniversaries.isEmpty
        ? null
        : _anniversaries.keys.reduce((a, b) => a < b ? a : b);
    return expired.toList()..sort();
  }

  List<String> _sampleMembers(
    PopulationCohort c,
    int amount,
    int Function(int) pick,
  ) {
    final ids = (_featured[c.id] ?? {}).toList()..sort();
    var remaining = c.count, selected = amount;
    final result = <String>[];
    for (final id in ids) {
      if (selected > 0 && pick(remaining) < selected) {
        result.add(id);
        selected--;
      }
      remaining--;
    }
    return result;
  }

  void _removeMembers(List<String> ids, String cohortId, {bool died = false}) {
    for (final id in ids) {
      if (died) {
        final c = _cohorts[cohortId]!;
        _archives[id] = Map.unmodifiable({
          'cohort': c.id,
          'settlement': c.settlement,
          'culture': c.culture,
          'species': c.species,
          'bornDay': c.bornDay,
          'estimated': c.estimated,
          'diedDay': day,
        });
      }
      _members.remove(id);
      _featured[cohortId]?.remove(id);
    }
  }

  void _reduce(PopulationCohort c, int count) {
    _adjust(c.settlement, band(c), -count);
    c._count -= count;
    if (c.count == 0) {
      if ((_featured[c.id]?.length ?? 0) > 0) {
        throw const FormatException('Personas sin población');
      }
      _cohorts.remove(c.id);
      _featured.remove(c.id);
      _groups.remove(
        _group(c.settlement, c.culture, c.species, c.bornDay, c.estimated),
      );
      for (final years in [16, 65, 120]) {
        final date = c.bornDay + years * 360;
        _anniversaries[date]?.remove(c.id);
        if (_anniversaries[date]?.isEmpty ?? false) _anniversaries.remove(date);
      }
    }
  }

  PopulationChange killCohort(String id, int count, int Function(int) pick) {
    final c = _cohorts[id];
    if (c == null || count < 0 || count > c.count) {
      throw const FormatException('Bajas fuera de su población');
    }
    final people = _sampleMembers(c, count, pick);
    _removeMembers(people, c.id, died: true);
    _reduce(c, count);
    return PopulationChange(count, List.unmodifiable(people));
  }

  PopulationChange remove(
    String settlement,
    int amount,
    int Function(int) pick, {
    List<int> priority = const [2, 1, 0],
  }) {
    if (amount < 0 ||
        amount > totals(settlement).total ||
        priority.toSet().length != 3 ||
        !priority.toSet().containsAll([0, 1, 2])) {
      throw const FormatException('Bajas no disponibles');
    }
    final people = <String>[];
    var remaining = amount;
    for (final ageBand in priority) {
      final groups =
          _cohorts.values
              .where((c) => c.settlement == settlement && band(c) == ageBand)
              .toList()
            ..sort(
              (a, b) => a.bornDay == b.bornDay
                  ? a.id.compareTo(b.id)
                  : a.bornDay.compareTo(b.bornDay),
            );
      for (final c in groups) {
        final n = remaining < c.count ? remaining : c.count;
        if (n == 0) break;
        people.addAll(killCohort(c.id, n, pick).people);
        remaining -= n;
      }
    }
    return PopulationChange(amount, List.unmodifiable(people));
  }

  PopulationChange transfer(
    String from,
    String to,
    int amount,
    int ageBand,
    int Function(int) pick,
  ) {
    if (from == to ||
        to.isEmpty ||
        to.length > 128 ||
        ageBand < 0 ||
        ageBand > 2 ||
        amount < 0 ||
        amount > totals(from).at(ageBand) ||
        totals(to).total + amount > 10000000) {
      throw const FormatException('Traslado poblacional inválido');
    }
    final groups =
        _cohorts.values
            .where((c) => c.settlement == from && band(c) == ageBand)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (groups.any((c) => age(c) >= 120)) {
      throw const FormatException('No pueden viajar grupos de edad vencida');
    }
    var remaining = amount;
    final people = <String>[];
    for (final c in groups) {
      final n = remaining < c.count ? remaining : c.count;
      if (n == 0) break;
      final moving = _sampleMembers(c, n, pick);
      _removeMembers(moving, c.id);
      _reduce(c, n);
      final target = add(
        settlement: to,
        culture: c.culture,
        species: c.species,
        bornDay: c.bornDay,
        count: n,
        estimated: c.estimated,
      );
      for (final id in moving) {
        register(id, target);
        people.add(id);
      }
      remaining -= n;
    }
    return PopulationChange(amount, List.unmodifiable(people));
  }

  PopulationCohort? candidate(
    String settlement, {
    int minimumAge = 16,
    int maximumAge = 119,
  }) {
    final options =
        _cohorts.values
            .where(
              (c) =>
                  c.settlement == settlement &&
                  age(c) >= minimumAge &&
                  age(c) <= maximumAge &&
                  (_featured[c.id]?.length ?? 0) < c.count,
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    return options.firstOrNull;
  }

  /// Used only when creating a world or an explicit rules conversion. Known
  /// birthdays stay exact; common residents receive a marked age estimate.
  factory PopulationLedger.fromProjections({
    required int day,
    required Iterable<Map<String, dynamic>> settlements,
  }) {
    final result = PopulationLedger(day: day);
    for (final s in settlements) {
      final remaining = [
        s['children'] as int,
        s['adults'] as int,
        s['elders'] as int,
      ];
      if (remaining.any((n) => n < 0)) {
        throw const FormatException('Proyección negativa');
      }
      for (final p in (s['people'] as List).where(
        (p) => p['diedDay'] == null,
      )) {
        final born = p['bornDay'] as int;
        final years = (day - born) ~/ 360;
        final band = years < 16
            ? 0
            : years < 65
            ? 1
            : 2;
        if (born > day || years >= 120 || remaining[band] <= 0) {
          throw const FormatException(
            'Personajes incompatibles con la población',
          );
        }
        remaining[band]--;
        final group = result.add(
          settlement: s['id'],
          culture: s['cultureId'],
          bornDay: born,
          count: 1,
          estimated: p['birthEstimated'] == true,
        );
        result.register(p['id'], group);
      }
      for (var band = 0; band < 3; band++) {
        final start = [0, 16, 65][band],
            span = [16, 49, 26][band],
            count = remaining[band];
        for (var i = 0; i < span; i++) {
          final n = count * (i + 1) ~/ span - count * i ~/ span;
          if (n > 0) {
            result.add(
              settlement: s['id'],
              culture: s['cultureId'],
              bornDay: day - (start + i) * 360,
              count: n,
              estimated: true,
            );
          }
        }
      }
    }
    result.validate();
    return result;
  }
  void validate() {
    if (day < 0 ||
        serial < 0 ||
        _cohorts.length > 100000 ||
        _members.length > 100000 ||
        _archives.length > 100000) {
      throw const FormatException('Capacidad poblacional inválida');
    }
    final counts = <String, List<int>>{};
    for (final c in _cohorts.values) {
      final sequence = int.tryParse(c.id.replaceFirst('cohort:', ''));
      if (!c.id.startsWith('cohort:') ||
          sequence == null ||
          sequence < 0 ||
          sequence >= serial ||
          c.count < 1 ||
          c.count > 10000000 ||
          c.bornDay > day ||
          age(c) >= 120 ||
          c.species != 'human') {
        throw const FormatException('Grupo poblacional imposible');
      }
      final n = counts.putIfAbsent(c.settlement, () => [0, 0, 0]);
      n[band(c)] += c.count;
      if ((_featured[c.id]?.length ?? 0) > c.count) {
        throw const FormatException('Personas duplican habitantes');
      }
    }
    for (final e in _members.entries) {
      if (!_cohorts.containsKey(e.value) ||
          !(_featured[e.value]?.contains(e.key) ?? false)) {
        throw const FormatException('Persona sin grupo');
      }
    }
    for (final e in _archives.entries) {
      final a = e.value;
      if (_members.containsKey(e.key) ||
          e.key.isEmpty ||
          e.key.length > 128 ||
          a.length != 7 ||
          [
            'cohort',
            'settlement',
            'culture',
            'species',
          ].any((k) => a[k] is! String || a[k].isEmpty || a[k].length > 128) ||
          a['species'] != 'human' ||
          a['bornDay'] is! int ||
          a['diedDay'] is! int ||
          a['diedDay'] > day ||
          a['diedDay'] < a['bornDay'] ||
          a['estimated'] is! bool) {
        throw const FormatException('Archivo de pertenencia inválido');
      }
    }
    for (final s in {...counts.keys, ..._totals.keys}) {
      final actual = counts[s] ?? [0, 0, 0], expected = _totals[s] ?? [0, 0, 0];
      if (actual[0] != expected[0] ||
          actual[1] != expected[1] ||
          actual[2] != expected[2]) {
        throw const FormatException('Proyección poblacional incoherente');
      }
    }
    if (birthCredits.entries.any(
      (e) =>
          e.key.isEmpty ||
          e.key.length > 128 ||
          e.value.entries.any(
            (c) =>
                c.key.isEmpty ||
                c.key.length > 128 ||
                c.value < 0 ||
                c.value >= 1000000,
          ),
    )) {
      throw const FormatException('Resto de natalidad inválido');
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'day': day,
    'serial': serial,
    'cohorts': (List<PopulationCohort>.from(
      _cohorts.values,
    )..sort((a, b) => a.id.compareTo(b.id))).map((c) => c.toJson()).toList(),
    'members': {
      for (final id in (_members.keys.toList()..sort())) id: _members[id],
    },
    'archives': {
      for (final id in (_archives.keys.toList()..sort())) id: _archives[id],
    },
    'birthCredits': {
      for (final id in (birthCredits.keys.toList()..sort()))
        id: {
          for (final culture in (birthCredits[id]!.keys.toList()..sort()))
            culture: birthCredits[id]![culture],
        },
    },
  };
  factory PopulationLedger.fromJson(Map<String, dynamic> raw) {
    const keys = {
      'version',
      'day',
      'serial',
      'cohorts',
      'members',
      'archives',
      'birthCredits',
    };
    if (raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        raw['version'] != 1 ||
        raw['day'] is! int ||
        raw['serial'] is! int ||
        raw['cohorts'] is! List ||
        raw['members'] is! Map ||
        raw['archives'] is! Map ||
        raw['birthCredits'] is! Map ||
        (raw['cohorts'] as List).length > 100000) {
      throw const FormatException('Modelo poblacional incompatible');
    }
    final result = PopulationLedger(day: raw['day'], serial: raw['serial']);
    const fields = {
      'id',
      'settlement',
      'culture',
      'species',
      'bornDay',
      'count',
      'estimated',
    };
    for (final c in raw['cohorts']) {
      if (c is! Map ||
          c.length != fields.length ||
          c.keys.any((k) => !fields.contains(k)) ||
          [
            'id',
            'settlement',
            'culture',
            'species',
          ].any((k) => c[k] is! String || c[k].isEmpty || c[k].length > 128) ||
          c['bornDay'] is! int ||
          c['count'] is! int ||
          c['estimated'] is! bool ||
          result._cohorts.containsKey(c['id'])) {
        throw const FormatException('Grupo guardado inválido');
      }
      final cohort = PopulationCohort._(
        c['id'],
        c['settlement'],
        c['culture'],
        c['species'],
        c['bornDay'],
        c['count'],
        estimated: c['estimated'],
      );
      final key = _group(
        cohort.settlement,
        cohort.culture,
        cohort.species,
        cohort.bornDay,
        cohort.estimated,
      );
      if (result._groups.containsKey(key)) {
        throw const FormatException('Grupos duplicados');
      }
      result._cohorts[cohort.id] = cohort;
      result._index(cohort);
    }
    for (final e in (raw['members'] as Map).entries) {
      if (e.key is! String || e.value is! String) {
        throw const FormatException('Pertenencia inválida');
      }
      result.register(e.key, e.value);
    }
    for (final e in (raw['archives'] as Map).entries) {
      if (e.key is! String || e.value is! Map) {
        throw const FormatException('Archivo de población inválido');
      }
      result._archives[e.key] = Map.unmodifiable(
        Map<String, dynamic>.from(e.value),
      );
    }
    for (final e in (raw['birthCredits'] as Map).entries) {
      if (e.key is! String ||
          e.value is! Map ||
          (e.value as Map).entries.any(
            (c) => c.key is! String || c.value is! int,
          )) {
        throw const FormatException('Resto de natalidad inválido');
      }
      result.birthCredits[e.key] = Map<String, int>.from(e.value);
    }
    result.validate();
    return result;
  }
}
