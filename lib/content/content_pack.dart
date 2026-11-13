import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'rule_catalog.dart';

/// Immutable declarative package. Bytes are hashed before parsing so worlds pin
/// exactly the shipped/imported content, including its original serialization.
class ContentPack {
  final String id;
  final String version;
  final String hash;
  final Map<String, dynamic> data;
  ContentPack._(this.id, this.version, this.hash, this.data);

  static const maxBytes = 2000000;
  static const conditionKeys = {
    'resource_min', 'resource_max', 'minPopulation', 'maxPopulation',
    'minHousing', 'maxHousing', 'minMorale', 'maxMorale', 'minRelation',
    'maxRelation', 'minHealth', 'maxHealth', 'minDay', 'maxDay',
    'technologies', 'missingTechnologies', 'flags', 'flagsMissing', 'facilityFound',
  };
  static const effects = {
    'resource', 'population', 'health', 'morale', 'environment', 'relation',
    'housing', 'defense', 'flag', 'technology', 'schedule',
  };

  factory ContentPack.parse(String source, {ContentPack? base, String? expectedHash}) {
    final bytes = utf8.encode(source);
    if (bytes.length > maxBytes) throw const FormatException('Paquete demasiado grande');
    final digest = sha256.convert(bytes).toString();
    if (expectedHash != null && digest != expectedHash) {
      throw const FormatException('El hash del paquete no coincide');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Se esperaba un objeto');
    final pack = decoded;
    if (pack['schemaVersion'] != 1 ||
        !RegExp(r'^[a-z][a-z0-9_.-]{1,63}$').hasMatch('${pack['id']}') ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch('${pack['version']}')) {
      throw const FormatException('Identidad o versión incompatible');
    }
    final known = <String, Set<String>>{};
    for (final kind in ['resources', 'biomes', 'buildings', 'technologies', 'traits',
      'profiles', 'characters', 'families', 'events', 'arcs', 'templates']) {
      final raw = pack[kind] ?? <dynamic>[];
      if (raw is! List || raw.length > 1000) throw FormatException('Tamaño inválido: $kind');
      final ids = <String>{};
      for (final entry in raw) {
        if (entry is! Map || entry['id'] is! String ||
            !RegExp(r'^[a-z][a-z0-9_]{1,63}$').hasMatch(entry['id'] as String) ||
            !ids.add(entry['id'] as String)) {
          throw FormatException('Identificador repetido o inválido: $kind');
        }
      }
      known[kind] = {
        ...((base?.data[kind] as List?) ?? []).map((e) => e['id'] as String), ...ids,
      };
    }
    if (base != null) {
      final requirements = pack['requires'];
      if (requirements is! Map || requirements[base.id] != base.version) {
        throw const FormatException('Dependencia de paquete incompatible');
      }
      for (final kind in ['events', 'technologies', 'resources']) {
        final baseIds = ((base.data[kind] as List?) ?? []).map((e) => e['id']).toSet();
        if (((pack[kind] as List?) ?? []).any((e) => baseIds.contains(e['id']))) {
          throw FormatException('El paquete intenta reemplazar $kind');
        }
      }
    }
    void costs(dynamic raw) {
      if (raw is! Map) throw const FormatException('Costes inválidos');
      for (final entry in raw.entries) {
        if (!known['resources']!.contains(entry.key) || entry.value is! num ||
            !(entry.value as num).isFinite || entry.value < 0 || entry.value > 100000) {
          throw const FormatException('Recurso o coste inválido');
        }
      }
    }
    void condition(dynamic raw) {
      if (raw is! Map || raw.keys.any((key) => !conditionKeys.contains(key))) {
        throw const FormatException('Condición no permitida');
      }
      for (final entry in raw.entries) {
        final key = entry.key as String;
        final value = entry.value;
        if (key == 'resource_min' || key == 'resource_max') {
          costs(value);
        } else if (key == 'facilityFound') {
          if (value is! bool) throw const FormatException('Condición booleana inválida');
        } else if (['flags', 'flagsMissing', 'technologies', 'missingTechnologies'].contains(key)) {
          if (value is! List || value.length > 100 || value.any((v) => v is! String)) {
            throw const FormatException('Referencias de condición inválidas');
          }
          for (final id in value) {
            if (key == 'technologies' || key == 'missingTechnologies') {
              if (!known['technologies']!.contains(id)) throw const FormatException('Tecnología de condición desconocida');
            } else if (!RegExp(r'^[a-z][a-z0-9_]{1,80}$').hasMatch(id as String)) {
              throw const FormatException('Bandera de condición inválida');
            }
          }
        } else if (value is! num || !value.isFinite || value < -100 || value > 3600000) {
          throw const FormatException('Límite de condición inválido');
        }
      }
    }
    void validateEffect(dynamic raw, {bool template = false}) {
      if (raw is! Map || !effects.contains(raw['type'])) {
        throw const FormatException('Operación no permitida');
      }
      if (raw['type'] == 'resource' && !known['resources']!.contains(raw['resource'])) {
        throw const FormatException('Recurso desconocido');
      }
      if (raw['type'] == 'technology' && !known['technologies']!.contains(raw['technology'])) {
        throw const FormatException('Tecnología desconocida');
      }
      const allowedKeys = {'type', 'resource', 'value', 'amount', 'technology',
        'eventId', 'delayDays', 'target', 'enabled', 'base', 'perUnit'};
      if (raw.keys.any((key) => !allowedKeys.contains(key))) {
        throw const FormatException('Campo de efecto desconocido');
      }
      if (raw['type'] == 'schedule') {
        final delay = raw['delayDays'];
        if (!known['events']!.contains(raw['eventId']) || delay is! int || delay < 1 || delay > 360000) {
          throw const FormatException('Programación inválida');
        }
      }
      if (raw['type'] == 'relation' && raw['target'] != null && raw['target'] is! String) {
        throw const FormatException('Participante inválido');
      }
      if (raw.containsKey('enabled') && raw['enabled'] is! bool) {
        throw const FormatException('Estado de bandera inválido');
      }
      if (template) {
        for (final key in ['base', 'perUnit']) {
          if (raw[key] != null && (raw[key] is! num || !(raw[key] as num).isFinite || (raw[key] as num).abs() > 100000)) {
            throw const FormatException('Fórmula inválida');
          }
        }
      } else if (!['flag', 'technology', 'schedule'].contains(raw['type']) && raw['value'] == null && raw['amount'] == null) {
        throw const FormatException('Falta magnitud del efecto');
      }
      final value = raw['value'] ?? raw['amount'];
      if (raw['type'] == 'flag') {
        if (value is! String || !RegExp(r'^[a-z][a-z0-9_]{1,80}$').hasMatch(value)) {
          throw const FormatException('Bandera inválida');
        }
      } else if (value != null && (value is! num || !value.isFinite || value.abs() > 100000)) {
        throw const FormatException('Magnitud inválida');
      }
    }
    for (final event in (pack['events'] as List?) ?? []) {
      if (event['body'] is! String || (event['body'] as String).length < 30 ||
          !['director', 'scheduled'].contains(event['trigger'])) {
        throw const FormatException('Evento incompleto');
      }
      condition(event['conditions']);
      if (!['needs', 'relations', 'exploration', 'economy', 'politics', 'technology', 'conflict', 'environment'].contains(event['category'])) {
        throw const FormatException('Categoría desconocida');
      }
      final probability = event['baseProbability'];
      if (probability is! num || !probability.isFinite || probability < 0 || probability > 1) {
        throw const FormatException('Probabilidad inválida');
      }
      final modifiers = event['conditionalProbability'] ?? [];
      if (modifiers is! List || modifiers.length > 32) throw const FormatException('Demasiados modificadores');
      for (final modifier in modifiers) {
        if (modifier is! Map) throw const FormatException('Modificador inválido');
        condition(modifier['conditions']);
        final multiplier = modifier['multiplier'];
        if (multiplier is! num || !multiplier.isFinite || multiplier < 0 || multiplier > 100) {
          throw const FormatException('Multiplicador inválido');
        }
      }
      if (event['family'] != null && !known['families']!.contains(event['family'])) {
        throw const FormatException('Familia desconocida');
      }
      final options = event['options'];
      if (options is! List || options.isEmpty || options.length > 8 ||
          options.map((e) => e['id']).toSet().length != options.length) {
        throw const FormatException('Opciones inválidas');
      }
      for (final option in options) {
        costs(option['costs']);
        if (option['effects'] is! List || option['followUps'] is! List) {
          throw const FormatException('Efectos o consecuencias inválidos');
        }
        for (final fx in option['effects']) { validateEffect(fx); }
        for (final follow in option['followUps']) {
          final delay = follow['delayDays'];
          final probability = follow['probability'];
          if (!known['events']!.contains(follow['eventId']) || delay is! int ||
              delay < 1 || delay > 360000 || probability is! num ||
              !probability.isFinite || probability < 0 || probability > 1) {
            throw const FormatException('Consecuencia desconocida o insegura');
          }
        }
      }
    }
    final technologies = <String, dynamic>{
      for (final t in ((base?.data['technologies'] as List?) ?? [])) t['id'] as String: t,
      for (final t in ((pack['technologies'] as List?) ?? [])) t['id'] as String: t,
    };
    final visited = <String>{};
    void visit(String id, Set<String> stack) {
      if (!technologies.containsKey(id) || stack.contains(id)) {
        throw const FormatException('Dependencia ausente o ciclo tecnológico');
      }
      if (visited.contains(id)) return;
      final requirements = technologies[id]['requires'];
      if (requirements is! List) throw const FormatException('Requisitos inválidos');
      for (final dep in requirements) { visit(dep as String, {...stack, id}); }
      visited.add(id);
    }
    for (final id in technologies.keys) { visit(id, {}); }
    for (final building in (pack['buildings'] as List?) ?? []) {
      costs(building['costs']);
      if (!(building['requires'] as List).every((id) => known['technologies']!.contains(id))) {
        throw const FormatException('Edificio con requisito desconocido');
      }
    }
    final localEvents = {for (final event in (pack['events'] as List?) ?? []) event['id']: event};
    for (final arc in (pack['arcs'] as List?) ?? []) {
      final nodes = arc['events'];
      final endings = arc['endings'];
      if (nodes is! List || nodes.length < 4 || nodes.length > 7 || endings is! List || endings.length < 2 ||
          !nodes.contains(arc['entryEvent']) || !nodes.every(localEvents.containsKey) || !endings.every(nodes.contains)) {
        throw const FormatException('Arco incompleto');
      }
      final reachable = <String>{};
      void walk(String id) {
        if (!reachable.add(id)) return;
        for (final option in localEvents[id]['options']) {
          for (final follow in option['followUps']) {
            if (nodes.contains(follow['eventId'])) walk(follow['eventId'] as String);
          }
        }
      }
      walk(arc['entryEvent'] as String);
      if (!nodes.every(reachable.contains)) throw const FormatException('Rama inaccesible');
      final signatures = endings.map((id) => jsonEncode(localEvents[id]['options'][0]['effects'])).toSet();
      if (signatures.length < 2) throw const FormatException('Desenlaces idénticos');
    }
    for (final template in (pack['templates'] as List?) ?? []) {
      condition(template['conditions']);
      final parameter = template['parameter'];
      if (parameter is! Map || parameter['type'] != 'integer' || parameter['minimum'] is! int || parameter['maximum'] is! int ||
          parameter['minimum'] < 1 || parameter['maximum'] > 100 || parameter['minimum'] > parameter['maximum']) {
        throw const FormatException('Parámetro de plantilla inválido');
      }
      final options = template['options'];
      if (options is! List || options.isEmpty || options.length > 8) throw const FormatException('Opciones de plantilla inválidas');
      for (final option in options) {
        if (option['costs'] is! Map || option['effects'] is! List) throw const FormatException('Plantilla inválida');
        for (final entry in (option['costs'] as Map).entries) {
          if (!known['resources']!.contains(entry.key) || entry.value is! Map) throw const FormatException('Coste de plantilla inválido');
          final formula = entry.value as Map;
          if (formula.length != 2 || !formula.containsKey('base') || !formula.containsKey('perUnit') ||
              formula.values.any((v) => v is! num || !v.isFinite || v < 0 || v > 100000)) {
            throw const FormatException('Fórmula de coste inválida');
          }
        }
        for (final fx in option['effects']) { validateEffect(fx, template: true); }
      }
    }
    // Validate executable definitions at import, before persisting a package
    // that the simulation would otherwise accept and then silently ignore.
    RuleCatalog.fromContent({
      'buildings': [
        ...((base?.data['buildings'] as List?) ?? []),
        ...((pack['buildings'] as List?) ?? []),
      ],
      'technologies': [
        ...((base?.data['technologies'] as List?) ?? []),
        ...((pack['technologies'] as List?) ?? []),
      ],
    });
    dynamic freeze(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.unmodifiable(value.map((key, item) => MapEntry(key as String, freeze(item))));
      }
      if (value is List) return List<dynamic>.unmodifiable(value.map(freeze));
      return value;
    }
    return ContentPack._(pack['id'] as String, pack['version'] as String,
      digest, freeze(pack) as Map<String, dynamic>);
  }

  Map<String, String> get pin => {'id': id, 'version': version, 'sha256': hash};
}

/// Importing registers a package for NEW worlds only. Existing pins never mutate.
class ContentRegistry {
  final Map<String, ContentPack> _packages = {};
  void importPack(ContentPack pack) {
    final key = '${pack.id}@${pack.version}';
    final old = _packages[key];
    if (old != null && old.hash != pack.hash) {
      throw const FormatException('La misma versión tiene contenido diferente');
    }
    _packages[key] = pack;
  }

  Map<String, dynamic> compose(List<Map<String, String>> pins) {
    final result = <String, dynamic>{'schemaVersion': 1};
    final seen = <String>{};
    final ids = <String, Set<String>>{};
    for (final pin in pins) {
      if (!seen.add(pin['id']!)) throw const FormatException('Paquete duplicado');
      final pack = _packages['${pin['id']}@${pin['version']}'];
      if (pack == null || pack.hash != pin['sha256']) {
        throw const FormatException('Falta la versión exacta del contenido guardado');
      }
      final requires = pack.data['requires'];
      if (requires is Map) {
        for (final dependency in requires.entries) {
          if (!pins.any((pin) => pin['id'] == dependency.key && pin['version'] == dependency.value)) {
            throw const FormatException('Falta una dependencia de contenido');
          }
        }
      }
      for (final entry in pack.data.entries) {
        if (entry.value is List) {
          final categoryIds = ids.putIfAbsent(entry.key, () => <String>{});
          for (final definition in entry.value as List) {
            if (definition is! Map || definition['id'] is! String || !categoryIds.add(definition['id'] as String)) {
              throw const FormatException('Dos paquetes definen el mismo identificador');
            }
          }
          final list = result.putIfAbsent(entry.key, () => <dynamic>[]) as List;
          list.addAll(entry.value as List);
        }
      }
    }
    result['packagePins'] = pins;
    return result;
  }

  /// An explicit migration must account for every queued content-event id before
  /// the caller atomically commits both the changed pins and the migrated queue.
  Map<String, dynamic> prepareMigration({
    required List<Map<String, String>> pins,
    required Iterable<String> pendingEventIds,
  }) {
    final candidate = compose(pins);
    final available = ((candidate['events'] as List?) ?? []).map((e) => e['id']).toSet();
    if (!pendingEventIds.every(available.contains)) {
      throw const FormatException('La migración dejaría acontecimientos pendientes sin definición');
    }
    return candidate;
  }
}
