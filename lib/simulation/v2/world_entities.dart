import 'dart:convert';
import 'package:crypto/crypto.dart';

class CultureIdentity {
  final String id, name, speciesId;
  const CultureIdentity(this.id, this.name, this.speciesId);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'speciesId': speciesId,
  };
}

class SocietyIdentity {
  final String id, name, cultureId;
  String? capitalId, leaderId;
  SocietyIdentity(
    this.id,
    this.name,
    this.cultureId,
    this.capitalId,
    this.leaderId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cultureId': cultureId,
    'capitalId': capitalId,
    'leaderId': leaderId,
  };
}

class SettlementIdentity {
  final String id, actorId, cultureId, speciesId;
  String societyId;
  SettlementIdentity(
    this.id,
    this.actorId,
    this.societyId,
    this.cultureId,
    this.speciesId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'actorId': actorId,
    'societyId': societyId,
    'cultureId': cultureId,
    'speciesId': speciesId,
  };
}

/// Political identity is independent of the compatibility engine's local actors.
/// Resource/population state remains local; moving ownership never copies it.
class WorldEntities {
  final Map<String, CultureIdentity> cultures = {};
  final Map<String, SocietyIdentity> societies = {};
  final Map<String, SettlementIdentity> settlements = {};
  final Set<String> species = {'human'};
  Map<String, SettlementIdentity>? _actors;
  Map<String, List<SettlementIdentity>>? _owners;
  void _reindex() {
    _actors = {for (final c in settlements.values) c.actorId: c};
    _owners = {};
    for (final c in settlements.values) {
      (_owners![c.societyId] ??= []).add(c);
    }
    for (final list in _owners!.values) {
      list.sort((a, b) => a.id.compareTo(b.id));
    }
  }

  void _invalidate() {
    _actors = null;
    _owners = null;
  }

  WorldEntities();
  factory WorldEntities.fromSettlements(Iterable<Map<String, dynamic>> actors) {
    final result = WorldEntities();
    result.reconcile(actors);
    return result;
  }
  SettlementIdentity? cityFor(String actorId) {
    if (_actors == null) _reindex();
    return _actors![actorId];
  }

  SocietyIdentity? societyFor(String actorId) {
    final city = cityFor(actorId);
    return city == null ? null : societies[city.societyId];
  }

  List<SettlementIdentity> citiesOf(String societyId) {
    if (_owners == null) _reindex();
    return List.unmodifiable(
      _owners![societyId] ?? const <SettlementIdentity>[],
    );
  }

  bool sameSociety(String a, String b) =>
      cityFor(a)?.societyId != null &&
      cityFor(a)?.societyId == cityFor(b)?.societyId;
  void reconcile(Iterable<Map<String, dynamic>> input) {
    final actors = {for (final a in input) a['id'] as String: a};
    for (final a in actors.values) {
      final id = a['id'] as String;
      if (cityFor(id) != null) continue;
      final name = a['culture'] as String;
      final cultureId = 'culture:${sha256.convert(utf8.encode(name))}';
      cultures.putIfAbsent(
        cultureId,
        () => CultureIdentity(cultureId, name, 'human'),
      );
      final city = SettlementIdentity(
        'settlement:$id',
        id,
        id,
        cultureId,
        'human',
      );
      if (settlements.containsKey(city.id) || societies.containsKey(id)) {
        throw const FormatException('Identidad política duplicada');
      }
      settlements[city.id] = city;
      _invalidate();
      societies[id] = SocietyIdentity(
        id,
        a['name'] as String,
        cultureId,
        city.id,
        a['leaderId'] as String?,
      );
    }
    for (final society in societies.values) {
      final owned = citiesOf(society.id);
      final living = owned.where((c) => _alive(actors[c.actorId]!)).toList();
      if (living.isEmpty) {
        society.capitalId = null;
        society.leaderId = null;
        continue;
      }
      if (!living.any((c) => c.id == society.capitalId)) {
        society.capitalId = living.first.id;
      }
      final alivePeople = living
          .expand(
            (c) => (actors[c.actorId]!['people'] as List).where(
              (p) => p['diedDay'] == null,
            ),
          )
          .toList();
      if (!alivePeople.any((p) => p['id'] == society.leaderId)) {
        final capital = settlements[society.capitalId]!;
        final preferred = actors[capital.actorId]!['leaderId'];
        society.leaderId =
            alivePeople.where((p) => p['id'] == preferred).firstOrNull?['id']
                as String? ??
            alivePeople.firstOrNull?['id'] as String?;
      }
    }
  }

  static bool _alive(Map<String, dynamic> actor) =>
      actor['extinct'] != true && (actor['population'] as num) > 0;
  void changeCapital(String societyId, String cityId) {
    final society = societies[societyId], city = settlements[cityId];
    if (society == null || city == null || city.societyId != societyId) {
      throw const FormatException('Capital fuera de la sociedad');
    }
    society.capitalId = cityId;
  }

  void federate(String recipientId, String joiningId) {
    if (recipientId == joiningId ||
        !societies.containsKey(recipientId) ||
        !societies.containsKey(joiningId)) {
      throw const FormatException('Unión política inválida');
    }
    final joining = citiesOf(joiningId);
    if (joining.isEmpty) {
      throw const FormatException('Sociedad sin asentamientos');
    }
    for (final c in joining) {
      c.societyId = recipientId;
    }
    _invalidate();
    societies[joiningId]!.capitalId = null;
    societies[joiningId]!.leaderId = null;
  }

  void validate(Iterable<Map<String, dynamic>> input) {
    _reindex();
    final actors = {for (final a in input) a['id'] as String: a};
    if (settlements.length != actors.length ||
        settlements.values.map((s) => s.actorId).toSet().length !=
            actors.length) {
      throw const FormatException('Asentamientos sin correspondencia local');
    }
    for (final c in cultures.values) {
      if (!species.contains(c.speciesId)) {
        throw const FormatException('Cultura sin especie');
      }
    }
    for (final c in settlements.values) {
      final actor = actors[c.actorId];
      if (actor == null ||
          !societies.containsKey(c.societyId) ||
          !cultures.containsKey(c.cultureId) ||
          !species.contains(c.speciesId) ||
          cultures[c.cultureId]!.speciesId != c.speciesId ||
          cultures[c.cultureId]!.name != actor['culture']) {
        throw const FormatException('Asentamiento sin identidad válida');
      }
    }
    for (final s in societies.values) {
      if (!cultures.containsKey(s.cultureId)) {
        throw const FormatException('Sociedad sin cultura');
      }
      final owned = citiesOf(s.id);
      if (s.capitalId != null && !owned.any((c) => c.id == s.capitalId)) {
        throw const FormatException('Capital ajena');
      }
      if (s.leaderId != null &&
          !owned.any(
            (c) => (actors[c.actorId]!['people'] as List).any(
              (p) => p['id'] == s.leaderId && p['diedDay'] == null,
            ),
          )) {
        throw const FormatException('Dirigente político inválido');
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'species': species.toList()..sort(),
    'cultures': [
      for (final id in cultures.keys.toList()..sort()) cultures[id]!.toJson(),
    ],
    'societies': [
      for (final id in societies.keys.toList()..sort()) societies[id]!.toJson(),
    ],
    'settlements': [
      for (final id in settlements.keys.toList()..sort())
        settlements[id]!.toJson(),
    ],
  };
  factory WorldEntities.fromJson(Map<String, dynamic> raw) {
    if (raw['version'] != 1 ||
        raw['species'] is! List ||
        raw['cultures'] is! List ||
        raw['societies'] is! List ||
        raw['settlements'] is! List ||
        raw.keys.any(
          (k) => !{
            'version',
            'species',
            'cultures',
            'societies',
            'settlements',
          }.contains(k),
        )) {
      throw const FormatException('Modelo político incompatible');
    }
    String text(dynamic value) {
      if (value is! String || value.isEmpty || value.length > 180) {
        throw const FormatException('Identidad inválida');
      }
      return value;
    }

    if ((raw['species'] as List).length != 1 ||
        raw['species'][0] != 'human' ||
        (raw['cultures'] as List).length > 100 ||
        (raw['societies'] as List).length > 100 ||
        (raw['settlements'] as List).length > 100) {
      throw const FormatException(
        'Especies o capacidad de entidades no compatibles',
      );
    }
    void row(dynamic value, Set<String> fields) {
      if (value is! Map ||
          value.length != fields.length ||
          value.keys.any((k) => !fields.contains(k))) {
        throw const FormatException('Campos de entidad no compatibles');
      }
    }

    final result = WorldEntities()..species.clear();
    for (final id in raw['species']) {
      if (!result.species.add(text(id))) {
        throw const FormatException('Especie duplicada');
      }
    }
    for (final c in raw['cultures']) {
      row(c, {'id', 'name', 'speciesId'});
      final id = text(c['id']);
      if (result.cultures.containsKey(id)) {
        throw const FormatException('Cultura duplicada');
      }
      result.cultures[id] = CultureIdentity(
        id,
        text(c['name']),
        text(c['speciesId']),
      );
    }
    for (final s in raw['societies']) {
      row(s, {'id', 'name', 'cultureId', 'capitalId', 'leaderId'});
      final id = text(s['id']);
      if (result.societies.containsKey(id)) {
        throw const FormatException('Sociedad duplicada');
      }
      result.societies[id] = SocietyIdentity(
        id,
        text(s['name']),
        text(s['cultureId']),
        s['capitalId'] == null ? null : text(s['capitalId']),
        s['leaderId'] == null ? null : text(s['leaderId']),
      );
    }
    for (final c in raw['settlements']) {
      row(c, {'id', 'actorId', 'societyId', 'cultureId', 'speciesId'});
      final id = text(c['id']);
      if (result.settlements.containsKey(id)) {
        throw const FormatException('Asentamiento duplicado');
      }
      result.settlements[id] = SettlementIdentity(
        id,
        text(c['actorId']),
        text(c['societyId']),
        text(c['cultureId']),
        text(c['speciesId']),
      );
    }
    return result;
  }
}
