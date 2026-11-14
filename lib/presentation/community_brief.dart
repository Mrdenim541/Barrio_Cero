import 'dart:convert';
import '../content/rule_catalog.dart';

/// Presentation queries. Reading a brief or the guide never issues an order.
class CommunityFocus {
  final String title, explanation, destination;
  final String? action, target, choice;
  const CommunityFocus(
    this.title,
    this.explanation,
    this.destination, {
    this.action,
    this.target,
    this.choice,
  });
}

class CommunityBrief {
  final int population, housing;
  final bool foodLow, waterLow;
  final CommunityFocus focus;
  const CommunityBrief(
    this.population,
    this.housing,
    this.foodLow,
    this.waterLow,
    this.focus,
  );

  factory CommunityBrief.read(
    Map<String, dynamic> world,
    Map<String, dynamic> town,
    RuleCatalog? catalog,
  ) {
    int count(dynamic n) => n is num ? n.toInt() : 0;
    final population = count(town['population']);
    final resources = town['resources'] as Map? ?? {};
    final built = town['built'] as Map? ?? {};
    final known = Set<String>.from(town['tech'] ?? []);
    final primitive = world['origin'] == 'prehistory';
    final housing = catalog == null
        ? count(built['house']) * (known.contains('masonry') ? 22 : 18) +
              count(built['habitat']) * 50 +
              count(town['housingModifier'])
        : catalog.buildings.fold<int>(
                count(town['housingModifier']),
                (n, b) => n + count(built[b.id]) * b.housingCapacity,
              ) +
              (catalog.provides(known, 'masonry')
                  ? count(built['house']) * 4
                  : 0);
    // Reserve thresholds, not a forecast: ongoing production is not subtracted.
    final foodLow = (resources['food'] as num? ?? 0) < population * .045 * 14;
    final waterLow = (resources['water'] as num? ?? 0) < population * .035 * 14;
    final projects = town['projects'] as List? ?? [];
    CommunityFocus building(String id, String title, String explanation) =>
        projects.any((p) => p['building'] == id)
        ? CommunityFocus(
            'Revisar la obra',
            '$explanation Ya hay una mejora en marcha.',
            'details',
          )
        : CommunityFocus(
            title,
            explanation,
            'command',
            action: 'build',
            target: id,
          );
    late CommunityFocus focus;
    final waiting = (world['pending'] as List? ?? []).where(
      (e) => e['type'] == 'content_choice' && e['societyId'] == town['id'],
    );
    final homes = ((world['socialState'] as Map?)?['requests'] as List? ?? [])
        .where(
          (r) => r['settlement'] == town['id'] && r['status'] == 'pending',
        );
    if (town['extinct'] == true || population == 0) {
      focus = const CommunityFocus(
        'Consultar el legado',
        'Esta comunidad ya no tiene habitantes. Su historia permanece.',
        'history',
      );
    } else if (town['id'] != world['controlledId']) {
      focus = const CommunityFocus(
        'Conocer esta comunidad',
        'Su gobierno decide por sí mismo. Observar no cambia quién diriges.',
        'details',
      );
    } else if (waiting.isNotEmpty) {
      focus = const CommunityFocus(
        'Atender una decisión',
        'Hay una decisión pendiente para esta comunidad.',
        'stories',
      );
    } else if (waterLow) {
      focus = building(
        primitive && !(catalog?.provides(known, 'masonry') ?? false)
            ? 'water_collect'
            : 'well',
        'Asegurar el agua',
        'La reserva de agua es baja. Revisa producción y trabajo antes de gastar.',
      );
    } else if (foodLow) {
      focus = building(
        primitive && !(catalog?.provides(known, 'agriculture') ?? false)
            ? 'foraging_camp'
            : 'farm',
        'Asegurar alimento',
        'La reserva de alimento es baja. Una mejora necesita materiales y trabajadores.',
      );
    } else if (homes.isNotEmpty) {
      focus = const CommunityFocus(
        'Revisar petición de hogar',
        'Dos residentes solicitan ayuda para convivir. La petición tiene vencimiento.',
        'families',
      );
    } else if (projects.isNotEmpty) {
      final paused = projects.any(
        (p) => (p['work'] as Map?)?['paused'] == true,
      );
      focus = CommunityFocus(
        'Revisar la obra',
        paused
            ? 'Hay una obra en espera de trabajadores. Puedes revisar sus compromisos.'
            : 'Hay trabajo en marcha. Avanza días para observar su progreso.',
        'details',
      );
    } else if (housing <= population) {
      focus = building(
        primitive && !(catalog?.provides(known, 'masonry') ?? false)
            ? 'shelter'
            : 'house',
        'Ampliar refugios',
        'Las plazas de vivienda están ocupadas. Crear espacio permite acoger y crecer.',
      );
    } else if (primitive && !(catalog?.provides(known, 'handcraft') ?? false)) {
      final technology = catalog?.technologies
          .where((t) => t.capabilities.contains('handcraft'))
          .firstOrNull;
      focus = technology == null
          ? const CommunityFocus(
              'Consultar conocimientos',
              'Revisa qué puede aprender esta comunidad.',
              'research',
            )
          : CommunityFocus(
              'Aprender un oficio',
              'El círculo de memoria reúne conocimientos; las técnicas abren nuevas mejoras.',
              'command',
              action: 'research',
              target: technology.id,
            );
    } else if (primitive && count(built['knapping_shed']) == 0) {
      focus = building(
        'knapping_shed',
        'Preparar herramientas',
        'Un taller de talla convierte materiales reales en herramientas para explorar.',
      );
    } else if (town['facilityFound'] != true) {
      focus = const CommunityFocus(
        'Preparar exploración',
        'Una expedición compromete provisiones y personal. Revisa si puedes mantenerla.',
        'command',
        action: 'explore',
      );
    } else if (town['facilityChoice'] == null) {
      focus = const CommunityFocus(
        'Revisar el descubrimiento',
        'La expedición encontró una instalación. Cada respuesta tiene costes y consecuencias.',
        'facility',
      );
    } else {
      focus = const CommunityFocus(
        'Conectar con vecinos',
        'Conoce otras comunidades y revisa un intercambio antes de comprometer reservas.',
        'diplomacy',
      );
    }
    return CommunityBrief(population, housing, foodLow, waterLow, focus);
  }
}

class CommunityGuideGoal {
  final String title, explanation, destination;
  final bool decided;
  const CommunityGuideGoal(
    this.title,
    this.explanation,
    this.destination,
    this.decided,
  );

  static List<CommunityGuideGoal> read(
    Map<String, dynamic> world,
    String actor,
  ) {
    final orders = <Map<String, dynamic>>[];
    for (final raw in (world['commandReceipts'] as Map? ?? {}).values) {
      try {
        final command = jsonDecode(raw['fingerprint'] as String);
        if (command is Map && command['actorId'] == actor) {
          orders.add(Map<String, dynamic>.from(command));
        }
      } on FormatException {
        // A legacy receipt without readable command data cannot prove a decision.
      } on TypeError {
        // Presentation remains readable when no usable receipt is available.
      }
    }
    bool did(String action, [Set<String>? targets]) => orders.any(
      (o) =>
          o['action'] == action &&
          (targets == null || targets.contains(o['target'])),
    );
    return [
      CommunityGuideGoal(
        'Reservar para el futuro',
        'Elige una prioridad de gobierno y revisa sus efectos.',
        'policy',
        did('policy'),
      ),
      CommunityGuideGoal(
        'Cuidar el agua',
        'Decide si ampliar la captación justifica su coste y el trabajo.',
        'water',
        did('build', {'water_collect', 'well'}),
      ),
      CommunityGuideGoal(
        'Dar espacio a la comunidad',
        'Compromete una mejora de vivienda; aparecerá al terminar.',
        'housing',
        did('build', {'shelter', 'house', 'habitat'}),
      ),
      CommunityGuideGoal(
        'Transmitir un oficio',
        'Maestro y aprendiz dejan de producir mientras se forman.',
        'learning',
        did('train'),
      ),
      CommunityGuideGoal(
        'Explorar con provisiones',
        'Prepara una expedición cuando dispongas de herramientas.',
        'explore',
        did('explore'),
      ),
      CommunityGuideGoal(
        'Tratar con un vecino',
        'Compara las reservas y los riesgos de abrir comercio.',
        'diplomacy',
        did('trade'),
      ),
      CommunityGuideGoal(
        'Atender a una familia',
        'Responde a una petición real o considera una tutela disponible.',
        'families',
        did('home') || did('foster'),
      ),
      CommunityGuideGoal(
        'Responder a lo ocurrido',
        'Revisa las decisiones y los descubrimientos que trae el tiempo.',
        'stories',
        did('facility') || did('resolve_event'),
      ),
      CommunityGuideGoal(
        'Adoptar un conocimiento',
        'Investiga una técnica y revisa qué posibilidades abre.',
        'research',
        did('research'),
      ),
      CommunityGuideGoal(
        'Delegar con intención',
        'Fija prioridades, delega y observa las consecuencias en Historia.',
        'policy',
        did('delegate'),
      ),
    ];
  }
}
