import 'dart:convert';
import 'definitions.dart';

/// Immutable executable definitions, carried with a world and checked against
/// its exact package pins. Updating the installed catalog cannot rewrite them.
class RuleCatalog {
  final List<BuildingDefinition> buildings;
  final List<Technology> technologies;
  final String _source;
  final Map<String, Set<String>> _grants;
  RuleCatalog._(this.buildings, this.technologies, this._source)
    : _grants = {
        for (final capability in capabilities)
          capability: Set.unmodifiable(
            technologies
                .where((t) => t.capabilities.contains(capability))
                .map((t) => t.id),
          ),
      };

  bool provides(Set<String> knowledge, String capability) =>
      _grants[capability]?.any(knowledge.contains) ?? false;

  static const capabilities = {
    'agriculture',
    'sanitation',
    'masonry',
    'mining',
    'metallurgy',
    'trade',
    'writing',
    'education',
    'science',
    'medicine',
    'engineering',
    'electricity',
    'radio',
    'recycling',
    'chemistry',
    'irrigation',
    'ecology',
    'diplomacy',
    'logistics',
    'industry',
    'automation',
    'computing',
    'robotics',
    'biotech',
    'adaptation',
    'cybernetics',
    'fusion',
    'xenology',
    'orbital',
    'synthesis',
  };

  static const resources = {
    'food',
    'wood',
    'stone',
    'metal',
    'water',
    'medicine',
    'tools',
    'energy',
    'knowledge',
    'textiles',
    'crystal',
    'fuel',
  };

  factory RuleCatalog.fromContent(Map<String, dynamic> content) =>
      RuleCatalog.fromJson({
        'schemaVersion': 1,
        'buildings': content['buildings'] ?? [],
        'technologies': content['technologies'] ?? [],
      });

  factory RuleCatalog.fromJson(Map<String, dynamic> raw) {
    if (raw.length != 3 ||
        raw['schemaVersion'] != 1 ||
        raw['buildings'] is! List ||
        raw['technologies'] is! List) {
      throw const FormatException('Catálogo de reglas incompatible');
    }
    String text(dynamic value) {
      if (value is! String || value.isEmpty || value.length > 500) {
        throw const FormatException('Texto de definición inválido');
      }
      return value;
    }

    Map<String, double> quantities(dynamic raw) {
      if (raw is! Map || raw.length > resources.length) {
        throw const FormatException('Cantidades de definición inválidas');
      }
      final values = <String, double>{};
      for (final e in raw.entries) {
        if (!resources.contains(e.key) ||
            e.value is! num ||
            !e.value.isFinite ||
            e.value < 0 ||
            e.value > 100000 ||
            (e.value * 1000 - (e.value * 1000).round()).abs() > .000001) {
          throw const FormatException('Material de definición inválido');
        }
        values[e.key] = (e.value as num).toDouble();
      }
      return Map.unmodifiable(values);
    }

    final techs = <Technology>[];
    final ids = <String>{};
    if ((raw['technologies'] as List).isEmpty ||
        (raw['technologies'] as List).length > 256 ||
        (raw['buildings'] as List).isEmpty ||
        (raw['buildings'] as List).length > 128) {
      throw const FormatException('Capacidad de catálogo inválida');
    }
    for (final t in raw['technologies']) {
      if (t is! Map ||
          t.keys.any(
            (k) => !{
              'id',
              'name',
              'requires',
              'knowledgeCost',
              'description',
              'effects',
            }.contains(k),
          ) ||
          t['requires'] is! List ||
          t['knowledgeCost'] is! num ||
          !t['knowledgeCost'].isFinite ||
          t['knowledgeCost'] < 0 ||
          t['knowledgeCost'] > 100000 ||
          !ids.add(text(t['id']))) {
        throw const FormatException('Tecnología ejecutable inválida');
      }
      final effects = t['effects'];
      final grants = <String>{};
      if (effects is! List || effects.isEmpty || effects.length > 8) {
        throw const FormatException(
          'Faltan capacidades tecnológicas ejecutables',
        );
      }
      for (final fx in effects) {
        if (fx is! Map ||
            fx.length != 2 ||
            fx['type'] != 'flag' ||
            fx['value'] is! String ||
            !fx['value'].startsWith('technology_')) {
          throw const FormatException('Operación tecnológica no implementada');
        }
        final capability = (fx['value'] as String).substring(11);
        if (!capabilities.contains(capability) || !grants.add(capability)) {
          throw const FormatException(
            'Capacidad tecnológica desconocida o duplicada',
          );
        }
      }
      techs.add(
        Technology(
          text(t['id']),
          text(t['name']),
          List.unmodifiable((t['requires'] as List).map(text)),
          (t['knowledgeCost'] as num).toDouble(),
          text(t['description']),
          Set.unmodifiable(grants),
        ),
      );
    }
    final byId = {for (final t in techs) t.id: t};
    final visited = <String>{};
    void visit(String id, Set<String> path) {
      if (path.contains(id) || !byId.containsKey(id)) {
        throw const FormatException('Ciclo o referencia tecnológica inválida');
      }
      if (!visited.add(id)) return;
      for (final dep in byId[id]!.requires) {
        visit(dep, {...path, id});
      }
    }

    for (final t in techs) {
      visit(t.id, {});
    }
    final definitions = <BuildingDefinition>[];
    ids.clear();
    for (final b in raw['buildings']) {
      if (b is! Map ||
          b.keys.any(
            (k) => !{
              'id',
              'name',
              'description',
              'costs',
              'dailyYield',
              'days',
              'workers',
              'requires',
              'effect',
              'dailyInputs',
            }.contains(k),
          ) ||
          b['requires'] is! List ||
          (b['requires'] as List).length > 1 ||
          !(b['requires'] as List).every(byId.containsKey) ||
          b['days'] is! int ||
          b['days'] < 1 ||
          b['days'] > 36000 ||
          !ids.add(text(b['id']))) {
        throw const FormatException('Edificio ejecutable inválido');
      }
      final effect = b['effect'];
      if (effect is! Map ||
          effect.length != 2 ||
          !['production', 'housing', 'defense'].contains(effect['type']) ||
          effect['value'] is! int ||
          effect['value'] < 0 ||
          effect['value'] > 10000 ||
          ![2, 4].contains(b['workers'])) {
        throw const FormatException(
          'Función o personal de edificio no implementados',
        );
      }
      definitions.add(
        BuildingDefinition(
          text(b['id']),
          text(b['name']),
          text(b['description']),
          quantities(b['costs']),
          quantities(b['dailyYield']),
          b['days'],
          (b['requires'] as List).isEmpty ? null : b['requires'][0],
          effect['type'] == 'housing' ? effect['value'] : 0,
          effect['type'] == 'defense' ? effect['value'] : 0,
          quantities(
            b['dailyInputs'] ??
                (b['id'] == 'generator'
                    ? {'fuel': .08}
                    : b['id'] == 'workshop'
                    ? {'metal': .04}
                    : <String, num>{}),
          ),
        ),
      );
    }
    return RuleCatalog._(
      List.unmodifiable(definitions),
      List.unmodifiable(techs),
      jsonEncode(raw),
    );
  }

  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(jsonDecode(_source));

  bool matches(RuleCatalog other) {
    dynamic canonical(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: canonical(value[key])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    return jsonEncode(canonical(toJson())) ==
        jsonEncode(canonical(other.toJson()));
  }
}
