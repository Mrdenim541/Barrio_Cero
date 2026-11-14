/// Personal records are queries over the population authority, not additional
/// residents. Unknown biological ancestry stays unknown.
class SocialResident {
  final String id, settlement;
  final int bornDay;
  final int? diedDay;
  const SocialResident(this.id, this.settlement, this.bornDay, this.diedDay);
  bool adultAt(int day) =>
      bornDay + 18 * 360 <= day && (diedDay == null || diedDay! > day);
  bool wasAdultAt(int day)=>bornDay+18*360<=day&&(diedDay==null||diedDay!>=day);
  bool get alive => diedDay == null;
}

class PersonalBond {
  final String a, b;
  final int since;
  int affectionA, affectionB, trust, friendship, rivalry;
  bool wantsA, wantsB;
  String status;
  PersonalBond(
    this.a,
    this.b,
    this.since, {
    this.affectionA = 0,
    this.affectionB = 0,
    this.trust = 0,
    this.friendship = 0,
    this.rivalry = 0,
    this.wantsA = false,
    this.wantsB = false,
    this.status = 'acquaintance',
  });
  String get id => '$a|$b';
  Map<String, dynamic> toJson() => {
    'a': a,
    'b': b,
    'since': since,
    'affectionA': affectionA,
    'affectionB': affectionB,
    'trust': trust,
    'friendship': friendship,
    'rivalry': rivalry,
    'wantsA': wantsA,
    'wantsB': wantsB,
    'status': status,
  };
  factory PersonalBond.fromJson(Map<String, dynamic> j) {
    _keys(j, {
      'a',
      'b',
      'since',
      'affectionA',
      'affectionB',
      'trust',
      'friendship',
      'rivalry',
      'wantsA',
      'wantsB',
      'status',
    });
    if (j['a'] is! String ||
        j['b'] is! String ||
        j['a'].isEmpty ||
        j['a'].contains('|') ||
        j['b'].contains('|') ||
        j['a'].compareTo(j['b']) >= 0 ||
        j['since'] is! int ||
        j['since'] < 0 ||
        j['wantsA'] is! bool ||
        j['wantsB'] is! bool ||
        ![
          'acquaintance',
          'friends',
          'romance',
          'separated',
          'bereaved',
        ].contains(j['status']) ||
        [
          'affectionA',
          'affectionB',
          'trust',
          'friendship',
          'rivalry',
        ].any((k) => j[k] is! int || j[k] < -100 || j[k] > 100)) {
      throw const FormatException('Vínculo personal inválido');
    }
    return PersonalBond(
      j['a'],
      j['b'],
      j['since'],
      affectionA: j['affectionA'],
      affectionB: j['affectionB'],
      trust: j['trust'],
      friendship: j['friendship'],
      rivalry: j['rivalry'],
      wantsA: j['wantsA'],
      wantsB: j['wantsB'],
      status: j['status'],
    );
  }
}

class Household {
  final String id, settlement;
  final int founded;
  // Historical membership is retained after death, separation or migration.
  final Map<String, int> joined, left;
  Household(
    this.id,
    this.settlement,
    this.founded,
    Map<String, int> joined, {
    Map<String, int> left = const {},
  }) : joined = Map.from(joined),
       left = Map.from(left);
  Iterable<String> get members =>
      joined.keys.where((p) => !left.containsKey(p));
  Map<String, dynamic> toJson() => {
    'id': id,
    'settlement': settlement,
    'founded': founded,
    'joined': joined,
    'left': left,
  };
  factory Household.fromJson(Map<String, dynamic> j) {
    _keys(j, {'id', 'settlement', 'founded', 'joined', 'left'});
    if (j['id'] is! String ||
        j['settlement'] is! String ||
        j['founded'] is! int ||
        j['founded'] < 0 ||
        j['joined'] is! Map ||
        j['left'] is! Map ||
        [
          ...(j['joined'] as Map).values,
          ...(j['left'] as Map).values,
        ].any((d) => d is! int || d < j['founded'])) {
      throw const FormatException('Hogar inválido');
    }
    return Household(
      j['id'],
      j['settlement'],
      j['founded'],
      Map<String, int>.from(j['joined']),
      left: Map<String, int>.from(j['left']),
    );
  }
}

class HomeRequest {
  final String id, a, b, settlement;
  final int created, expires;
  String status;
  HomeRequest(
    this.id,
    this.a,
    this.b,
    this.settlement,
    this.created,
    this.expires, {
    this.status = 'pending',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'a': a,
    'b': b,
    'settlement': settlement,
    'created': created,
    'expires': expires,
    'status': status,
  };
  factory HomeRequest.fromJson(Map<String, dynamic> j) {
    _keys(j, {'id', 'a', 'b', 'settlement', 'created', 'expires', 'status'});
    if ([
          'id',
          'a',
          'b',
          'settlement',
        ].any((k) => j[k] is! String || j[k].isEmpty) ||
        j['a'] == j['b'] ||
        j['created'] is! int ||
        j['expires'] is! int ||
        j['created'] < 0 ||
        j['expires'] <= j['created'] ||
        ![
          'pending',
          'accepted',
          'declined',
          'expired',
          'cancelled',
        ].contains(j['status'])) {
      throw const FormatException('Petición de hogar inválida');
    }
    return HomeRequest(
      j['id'],
      j['a'],
      j['b'],
      j['settlement'],
      j['created'],
      j['expires'],
      status: j['status'],
    );
  }
}

/// Living relationships and historical facts are separate: a presentation
/// preference cannot remove a victim, a guardian or a past shared home.
class SocialState {
  int serial;
  final Map<String, PersonalBond> bonds = {};
  final Map<String, Household> households = {};
  final Map<String, HomeRequest> requests = {};
  final List<Map<String, dynamic>> guardians = [];
  final List<Map<String, dynamic>> memories = [];
  SocialState({this.serial = 0});
  static String pair(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
  bool related(String a, String b) {
    Set<String> ancestors(String person) {
      final result = <String>{}, queue = <String>[person];
      while (queue.isNotEmpty) {
        final p = queue.removeLast();
        for (final g in guardians.where((g) => g['child'] == p)) {
          final parent = g['adult'] as String;
          if (result.add(parent)) queue.add(parent);
        }
      }
      return result;
    }

    final first = ancestors(a), second = ancestors(b);
    return first.contains(b) ||
        second.contains(a) ||
        first.intersection(second).isNotEmpty;
  }

  PersonalBond? bond(String a, String b) => bonds[pair(a, b)];
  Household? homeOf(String person) =>
      households.values.where((h) => h.members.contains(person)).firstOrNull;
  PersonalBond meet(
    String a,
    String b,
    int day, {
    required bool wantsA,
    required bool wantsB,
  }) {
    if (a == b || a.contains('|') || b.contains('|') || day < 0) {
      throw const FormatException('Encuentro inválido');
    }
    final ordered = a.compareTo(b) < 0;
    return bonds.putIfAbsent(
      pair(a, b),
      () => PersonalBond(
        ordered ? a : b,
        ordered ? b : a,
        day,
        wantsA: ordered ? wantsA : wantsB,
        wantsB: ordered ? wantsB : wantsA,
      ),
    );
  }

  HomeRequest? requestHome(
    String a,
    String b,
    String settlement,
    int day,
    Map<String, SocialResident> people,
  ) {
    final relation = bond(a, b), first = people[a], second = people[b];
    if (first == null ||
        second == null ||
        !first.adultAt(day) ||
        !second.adultAt(day) ||
        first.settlement != settlement ||
        second.settlement != settlement ||
        relation == null ||
        relation.friendship < 15 ||
        homeOf(a) != null ||
        homeOf(b) != null ||
        requests.values.any(
          (r) =>
              pair(r.a, r.b) == pair(a, b) &&
              ['pending', 'accepted', 'declined'].contains(r.status),
        )) {
      return null;
    }
    final request = HomeRequest(
      'home-request:${serial++}',
      a,
      b,
      settlement,
      day,
      day + 90,
    );
    requests[request.id] = request;
    return request;
  }

  String? canResolve(String id, int day, Map<String, SocialResident> people) {
    final r = requests[id];
    if (r == null || r.status != 'pending') {
      return 'La petición ya no está pendiente.';
    }
    if (day >= r.expires) return 'La petición ha vencido.';
    final a = people[r.a], b = people[r.b];
    if (a == null ||
        b == null ||
        !a.adultAt(day) ||
        !b.adultAt(day) ||
        a.settlement != r.settlement ||
        b.settlement != r.settlement ||
        homeOf(r.a) != null ||
        homeOf(r.b) != null) {
      return 'Los participantes ya no pueden establecer ese hogar.';
    }
    final relation = bond(r.a, r.b);
    if (relation == null || relation.friendship < 15 || relation.trust < 0) {
      return 'Los habitantes ya no mantienen su acuerdo.';
    }
    return null;
  }

  Household resolve(String id, int day, Map<String, SocialResident> people) {
    final error = canResolve(id, day, people);
    if (error != null) throw StateError(error);
    final r = requests[id]!;
    final h = Household('household:${serial++}', r.settlement, day, {
      r.a: day,
      r.b: day,
    });
    households[h.id] = h;
    r.status = 'accepted';
    memories.add({
      'kind': 'home',
      'people': [r.a, r.b],
      'day': day,
      'reference': h.id,
    });
    return h;
  }

  void decline(String id, int day, Map<String, SocialResident> people) {
    final error = canResolve(id, day, people);
    if (error != null) throw StateError(error);
    requests[id]!.status = 'declined';
  }

  void addGuardian(
    String parent,
    String child,
    int day,
    Map<String, SocialResident> people,
  ) {
    final adult = people[parent], minor = people[child], home = homeOf(parent);
    if (adult == null ||
        minor == null ||
        !adult.adultAt(day) ||
        !minor.alive ||
        day - minor.bornDay >= 18 * 360 ||
        minor.bornDay > day ||
        adult.settlement != minor.settlement ||
        home == null ||
        homeOf(child) != null ||
        guardians.any((g) => g['child'] == child)) {
      throw const FormatException('Tutela incompatible con habitantes reales');
    }
    home.joined[child] = day;
    guardians.add({
      'adult': parent,
      'child': child,
      'day': day,
      'kind': 'guardian',
    });
    memories.add({
      'kind': 'care',
      'people': [parent, child],
      'day': day,
      'reference': home.id,
    });
  }

  void reconcile(int day, Map<String, SocialResident> people) {
    for (final r in requests.values.where((r) => r.status == 'pending')) {
      if (day >= r.expires) {
        r.status = 'expired';
        continue;
      }
      if ([
        people[r.a],
        people[r.b],
      ].any((p) => p == null || !p.alive || p.settlement != r.settlement)) {
        r.status = 'cancelled';
      }
    }
    for (final r in requests.values.where((r) => r.status == 'pending')) {
      if (canResolve(r.id, day, people) != null) r.status = 'cancelled';
    }
    for (final h in households.values) {
      for (final id in h.members.toList()) {
        final p = people[id];
        if (p == null) {
          throw const FormatException('Hogar con identidad perdida');
        }
        if (!p.alive || p.settlement != h.settlement) {
          h.left[id] = day;
          memories.add({
            'kind': p.alive ? 'distance' : 'loss',
            'people': [id, ...h.members.where((other) => other != id)],
            'day': day,
            'reference': h.id,
          });
        }
      }
    }
    for (final b in bonds.values) {
      if ((people[b.a]?.alive != true || people[b.b]?.alive != true) &&
          b.status == 'romance') {
        b.status = 'bereaved';
      }
    }
  }

  void validate(
    int day,
    Map<String, SocialResident> people,
    Set<String> settlements,
  ) {
    if (serial < 0 ||
        bonds.length > 100000 ||
        households.length > 100000 ||
        requests.length > 100000 ||
        memories.length > 500000 ||
        guardians.length > 100000) {
      throw const FormatException('Límite de historia personal');
    }
    var largest = -1;
    for (final id in [...households.keys, ...requests.keys]) {
      final match = RegExp(
        r'^(household|home-request):([0-9]+)$',
      ).firstMatch(id);
      if (match == null) {
        throw const FormatException(
          'Identificador de historia personal inválido',
        );
      }
      final value = int.tryParse(match.group(2)!);
      if (value == null) {
        throw const FormatException('Identificador personal fuera de rango');
      }
      if (value > largest) largest = value;
    }
    if (serial <= largest) {
      throw const FormatException('Secuencia personal reutilizada');
    }
    final active = <String>{};
    for (final b in bonds.values) {
      PersonalBond.fromJson(b.toJson());
      if (!people.containsKey(b.a) ||
          !people.containsKey(b.b) ||
          b.since > day) {
        throw const FormatException('Vínculo sin personas o fecha válida');
      }
      if (b.status == 'romance' &&
          (!people[b.a]!.adultAt(day) ||
              !people[b.b]!.adultAt(day) ||
              !b.wantsA ||
              !b.wantsB ||
              related(b.a, b.b))) {
        throw const FormatException('Relación sin acuerdo entre adultos');
      }
    }
    for (final h in households.values) {
      Household.fromJson(h.toJson());
      if (h.id.isEmpty ||
          !settlements.contains(h.settlement) ||
          h.founded > day ||
          h.joined.length < 2 ||
          h.joined.entries
                  .where((e) => e.value == h.founded)
                  .where((e) => people[e.key]?.wasAdultAt(h.founded) == true)
                  .length <
              2 ||
          h.left.keys.any((p) => !h.joined.containsKey(p))) {
        throw const FormatException('Historia del hogar inválida');
      }
      for (final e in h.joined.entries) {
        final p = people[e.key];
        if (p == null ||
            e.value > day ||
            e.value < p.bornDay ||
            (h.left[e.key] ?? day) < e.value ||
            (h.left[e.key] ?? day) > day) {
          throw const FormatException('Residencia histórica inválida');
        }
      }
      for (final id in h.members) {
        if (!active.add(id) ||
            people[id]!.settlement != h.settlement ||
            !people[id]!.alive) {
          throw const FormatException(
            'Residencia activa duplicada o incompatible',
          );
        }
      }
    }
    for (final r in requests.values) {
      HomeRequest.fromJson(r.toJson());
      if (r.status == 'accepted' &&
          !households.values.any(
            (h) =>
                h.settlement == r.settlement &&
                h.founded >= r.created &&
                h.founded < r.expires &&
                h.joined[r.a] == h.founded &&
                h.joined[r.b] == h.founded,
          )) {
        throw const FormatException('Petición aceptada sin hogar confirmado');
      }
      if (!people.containsKey(r.a) ||
          !people.containsKey(r.b) ||
          !settlements.contains(r.settlement) ||
          r.created > day ||
          r.status == 'pending' && canResolve(r.id, day, people) != null) {
        throw const FormatException('Petición personal incompatible');
      }
    }
    final children = <String>{};
    for (final g in guardians) {
      _keys(g, {'adult', 'child', 'day', 'kind'});
      final a = people[g['adult']], c = people[g['child']], date = g['day'];
      if (a == null ||
          c == null ||
          date is! int ||
          date > day ||
          date < c.bornDay ||
          !a.wasAdultAt(date) ||
          date - c.bornDay >= 18 * 360 ||
          g['kind'] != 'guardian' ||
          !children.add(c.id)) {
        throw const FormatException('Tutela histórica inválida');
      }
    }
    for (final m in memories) {
      _keys(m, {'kind', 'people', 'day', 'reference'});
      if (![
            'home',
            'care',
            'distance',
            'loss',
            'separation',
            'legacy',
          ].contains(m['kind']) ||
          m['day'] is! int ||
          m['day'] < 0 ||
          m['day'] > day ||
          m['people'] is! List ||
          (m['people'] as List).isEmpty ||
          (m['people'] as List).any((p) => !people.containsKey(p)) ||
          m['reference'] is! String ||
          !households.containsKey(m['reference'])) {
        throw const FormatException('Memoria familiar inválida');
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'serial': serial,
    'bonds': bonds.values.map((b) => b.toJson()).toList(),
    'households': households.values.map((h) => h.toJson()).toList(),
    'requests': requests.values.map((r) => r.toJson()).toList(),
    'guardians': guardians,
    'memories': memories,
  };
  factory SocialState.fromJson(Map<String, dynamic> j) {
    _keys(j, {
      'serial',
      'bonds',
      'households',
      'requests',
      'guardians',
      'memories',
    });
    if (j['serial'] is! int ||
        j['serial'] < 0 ||
        [
          'bonds',
          'households',
          'requests',
          'guardians',
          'memories',
        ].any((k) => j[k] is! List)) {
      throw const FormatException('Registro personal incompatible');
    }
    final s = SocialState(serial: j['serial']);
    for (final raw in j['bonds']) {
      final b = PersonalBond.fromJson(Map<String, dynamic>.from(raw));
      if (s.bonds.containsKey(b.id)) {
        throw const FormatException('Vínculo duplicado');
      }
      s.bonds[b.id] = b;
    }
    for (final raw in j['households']) {
      final h = Household.fromJson(Map<String, dynamic>.from(raw));
      if (s.households.containsKey(h.id)) {
        throw const FormatException('Hogar duplicado');
      }
      s.households[h.id] = h;
    }
    for (final raw in j['requests']) {
      final r = HomeRequest.fromJson(Map<String, dynamic>.from(raw));
      if (s.requests.containsKey(r.id)) {
        throw const FormatException('Petición duplicada');
      }
      s.requests[r.id] = r;
    }
    s.guardians.addAll(
      (j['guardians'] as List).map((g) => Map<String, dynamic>.from(g)),
    );
    s.memories.addAll(
      (j['memories'] as List).map((m) => Map<String, dynamic>.from(m)),
    );
    return s;
  }
}

void _keys(Map<String, dynamic> j, Set<String> keys) {
  if (j.length != keys.length || j.keys.any((k) => !keys.contains(k))) {
    throw const FormatException('Campos personales incompatibles');
  }
}
