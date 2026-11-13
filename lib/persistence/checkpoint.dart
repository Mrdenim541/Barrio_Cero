import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../content/content_pack.dart';
import '../simulation/engine.dart';
import '../simulation/v2/materials.dart';
import '../simulation/v2/world_entities.dart';
import '../simulation/v2/inventory.dart';

/// Complete, self-contained committed state. The envelope version is separate
/// from the world/engine schema. Hashes detect corruption, not authorship.
class Checkpoint {
  static const maxBytes = 25000000;
  static const _settingKeys = {'reduceMotion', 'sound', 'vibration'};
  final WorldState world;
  final int? target;
  final bool stopCrisis;
  final Map<String, bool> settings;
  final String coreSource;
  final List<String> additionalSources;
  final ContentPack basePack;
  final Map<String, dynamic> content;
  final Map<String, dynamic> _payload;

  Checkpoint._(
    this.world,
    this.target,
    this.stopCrisis,
    this.settings,
    this.coreSource,
    this.additionalSources,
    this.basePack,
    this.content,
    this._payload,
  );

  /// Copies the supplied world; binding content cannot mutate the running world.
  /// Existing bindings must match. Unbound new worlds acquire complete pins.
  factory Checkpoint.create({
    required WorldState world,
    required String coreSource,
    List<String> additionalSources = const [],
    int? target,
    bool stopCrisis = true,
    Map<String, bool> settings = const {},
  }) {
    final sources = [coreSource, ...additionalSources];
    final packs = _readPacks(sources);
    final bindings = _bindings(packs);
    for (final entry in world.contentVersions.entries) {
      if (bindings[entry.key] != entry.value) {
        throw const FormatException('El contenido no coincide con el mundo');
      }
    }
    final state = _map(jsonDecode(jsonEncode(world.toJson())));
    state['contentVersions'] = bindings;
    final payload = <String, dynamic>{
      'world': state,
      'target': target,
      'stopCrisis': stopCrisis,
      'settings': {for (final key in _settingKeys) key: settings[key] ?? false},
      'packages': [
        for (var i = 0; i < packs.length; i++)
          {...packs[i].pin, 'source': sources[i]},
      ],
    };
    if (settings.keys.any((key) => !_settingKeys.contains(key))) {
      throw const FormatException('Ajuste desconocido');
    }
    return _fromPayload(payload);
  }

  factory Checkpoint.decode(String source) {
    final envelope = _parseEnvelope(source);
    _keys(envelope, {'format', 'version', 'payload', 'sha256'});
    if (envelope['format'] != 'barrio-cero-save' ||
        envelope['version'] is! int ||
        envelope['version'] != 2) {
      throw const FormatException(
        'Versión incompatible: requiere migración explícita',
      );
    }
    final payload = _map(envelope['payload']);
    if (envelope['sha256'] is! String ||
        envelope['sha256'] != _digest(payload)) {
      throw const FormatException('Integridad del punto de guardado no válida');
    }
    return _fromPayload(payload);
  }

  /// Caller must preserve the exact original before replacing a legacy file.
  /// v1 only covered world bytes: target/settings cannot retroactively be
  /// authenticated, so they are strictly validated and then protected by v2.
  factory Checkpoint.migrateLegacy(
    String source, {
    required String expectedCoreSource,
  }) {
    final old = _parseEnvelope(source);
    _keys(
      old,
      {
        'format',
        'version',
        'sha256',
        'world',
        'target',
        'stopCrisis',
        'packs',
        'settings',
      },
      requiredKeys: {'format', 'version', 'sha256', 'world'},
    );
    if (old['format'] != 'barrio-cero-save' ||
        old['version'] is! int ||
        old['version'] != 1) {
      throw const FormatException('No es una partida del prototipo');
    }
    final state = _map(old['world']);
    // Preserve v1 JSON insertion-order digest exactly as the old app wrote it.
    if (old['sha256'] !=
        sha256.convert(utf8.encode(jsonEncode(state))).toString()) {
      throw const FormatException('Partida antigua corrupta');
    }
    final extra = old['packs'] ?? <dynamic>[];
    if (extra is! List || extra.any((item) => item is! String)) {
      throw const FormatException('Paquetes antiguos inválidos');
    }
    final packs = _readPacks([expectedCoreSource, ...extra.cast<String>()]);
    final existing = _map(state['contentVersions']);
    final expected = _bindings(packs);
    // Require every embedded package, including the externally supplied core,
    // to have been pinned in the old world. Reject missing or surplus sources.
    for (final pack in packs) {
      if (existing['${pack.id}.sha256'] != pack.hash) {
        throw const FormatException(
          'Falta el contenido exacto de la partida antigua',
        );
      }
    }
    if (existing.entries.any((entry) => expected[entry.key] != entry.value)) {
      throw const FormatException(
        'Versiones antiguas incompatibles o paquetes ausentes',
      );
    }
    final stop = old['stopCrisis'] ?? true;
    if (stop is! bool) {
      throw const FormatException('Política histórica inválida');
    }
    final settings = _settings(
      old['settings'] ?? <String, dynamic>{},
      complete: false,
    );
    final target = old['target'];
    if (target != null && target is! int) {
      throw const FormatException('Fecha objetivo inválida');
    }
    return Checkpoint.create(
      world: _world(state),
      coreSource: expectedCoreSource,
      additionalSources: extra.cast<String>(),
      target: target as int?,
      stopCrisis: stop,
      settings: settings,
    );
  }

  /// Builds a candidate only. SessionController must preserve source bytes first.
  factory Checkpoint.upgradeRules(String source) {
    final previous = Checkpoint.decode(source);
    if (previous.world.societies.every((s) => s.materialRules == 2) &&
        previous.world.entities != null) {
      throw const FormatException('Estas reglas ya están activas');
    }
    final raw = _map(jsonDecode(jsonEncode(previous.world.toJson())));
    final adjustments = <Map<String, dynamic>>[];
    for (final actor in raw['societies'] as List) {
      final alive = (actor['people'] as List).where(
        (p) => p['diedDay'] == null,
      );
      final counts = {'children': 0, 'adults': 0, 'elders': 0};
      for (final p in alive) {
        final age = (previous.world.day - (p['bornDay'] as int)) ~/ 360;
        final key = age < 16
            ? 'children'
            : age >= 65
            ? 'elders'
            : 'adults';
        counts[key] = counts[key]! + 1;
      }
      if (counts.entries.any((e) => e.value > (actor[e.key] as int))) {
        throw const FormatException(
          'No se pueden reconciliar personajes y población; la partida antigua sigue disponible',
        );
      }
      final resources = (actor['resources'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      );
      final inventory = FixedInventory(resources);
      for (final e in resources.entries) {
        if (e.value != inventory[e.key]) {
          adjustments.add({
            'actor': actor['id'],
            'resource': e.key,
            'before': e.value.toString(),
            'afterMillis': inventory.millis[e.key],
          });
        }
      }
      actor['materialRules'] = 2;
      actor['resourceMillis'] = Map.from(inventory.millis);
      actor['resources'] = Map<String, double>.from(inventory);
      final carries = actor['demographicCarry'] as Map? ?? {};
      final micros = <String, int>{};
      for (final e in carries.entries) {
        if (!['grown', 'aged', 'oldDeaths', 'births'].contains(e.key) ||
            e.value is! num ||
            !e.value.isFinite ||
            e.value < 0 ||
            e.value >= 1) {
          throw const FormatException('Resto demográfico antiguo inválido');
        }
        micros[e.key] = (e.value * 1000000).floor();
      }
      actor['demographicMicros'] = micros;
      actor['demographicCarry'] = {
        for (final e in micros.entries) e.key: e.value / 1000000,
      };
    }
    raw['rulesVersion'] = 2;
    raw['randomAlgorithm'] = RandomState.algorithm;
    final candidate = WorldState.fromJson(raw);
    candidate.entities ??= WorldEntities.fromSettlements(
      candidate.societies.map((s) => s.identityView()),
    );
    candidate.ruleChanges.add({
      'day': candidate.day,
      'from': previous.world.toJson()['rulesVersion'] ?? 1,
      'to': 2,
      'sourceSha256': sha256.convert(utf8.encode(source)).toString(),
      'amountAdjustments': adjustments,
    });
    final id = 'h${candidate.serial++}';
    final home = candidate.controlled;
    candidate.chronicle.add(
      HistoryEntry(
        id,
        candidate.day,
        'Una nueva forma de organizar el mundo',
        'Se registran sociedades y asentamientos separados, materiales en milésimas y la copia anterior de la partida. No se reconstruyen parentescos desconocidos.',
        'reglas',
        home.id,
        home.x,
        home.y,
      ),
    );
    candidate.validate();
    return Checkpoint.create(
      world: candidate,
      coreSource: previous.coreSource,
      additionalSources: previous.additionalSources,
      target: previous.target,
      stopCrisis: previous.stopCrisis,
      settings: previous.settings,
    );
  }

  /// Encodes the committed snapshot captured at construction, not later edits
  /// to the exposed world used by the simulation. Create a new checkpoint after
  /// advancing the world.
  String encode() {
    final result = jsonEncode({
      'format': 'barrio-cero-save',
      'version': 2,
      'payload': _payload,
      'sha256': _digest(_payload),
    });
    if (utf8.encode(result).length > maxBytes) {
      throw const FormatException('Partida demasiado grande');
    }
    return result;
  }

  static Checkpoint _fromPayload(Map<String, dynamic> payload) {
    if (utf8.encode(jsonEncode(payload)).length > maxBytes) {
      throw const FormatException('Partida demasiado grande');
    }
    _keys(payload, {'world', 'target', 'stopCrisis', 'settings', 'packages'});
    final records = payload['packages'];
    if (records is! List || records.isEmpty || records.length > 9) {
      throw const FormatException('Conjunto de paquetes inválido');
    }
    final sources = <String>[];
    for (final raw in records) {
      final record = _map(raw);
      _keys(record, {'id', 'version', 'sha256', 'source'});
      if (record.values.any((value) => value is! String)) {
        throw const FormatException('Identidad de paquete inválida');
      }
      sources.add(record['source'] as String);
    }
    final packs = _readPacks(sources);
    for (var i = 0; i < packs.length; i++) {
      final record = _map(records[i]);
      if (packs[i].pin.entries.any((pin) => record[pin.key] != pin.value)) {
        throw const FormatException('Pin y bytes de contenido no coinciden');
      }
    }
    final state = _map(payload['world']);
    final bindings = _map(state['contentVersions']);
    if (_canonical(bindings) != _canonical(_bindings(packs))) {
      throw const FormatException(
        'El conjunto exacto de contenido no coincide',
      );
    }
    final candidate = _world(state);
    final target = payload['target'];
    if (target != null &&
        (target is! int ||
            target < candidate.day ||
            target > candidate.day + 360000)) {
      throw const FormatException('Fecha objetivo inválida');
    }
    if (payload['stopCrisis'] is! bool) {
      throw const FormatException('Política histórica inválida');
    }
    final settings = _settings(payload['settings']);
    final registry = ContentRegistry();
    for (final pack in packs) {
      registry.importPack(pack);
    }
    final content = registry.prepareMigration(
      pins: packs.map((pack) => pack.pin).toList(),
      pendingEventIds: candidate.pending
          .where(
            (event) =>
                event.type == 'content' || event.type == 'content_choice',
          )
          .map((event) {
            final id = event.data['eventId'];
            if (id is! String) {
              throw const FormatException('Evento pendiente sin definición');
            }
            return id;
          }),
    );
    if (candidate.societies.any((s) => s.materialRules == 2)) {
      for (final pack in packs) {
        validateMaterialCosts(pack.data);
      }
    }
    return Checkpoint._(
      candidate,
      target as int?,
      payload['stopCrisis'] as bool,
      Map.unmodifiable(settings),
      sources.first,
      List.unmodifiable(sources.skip(1)),
      packs.first,
      content,
      _map(jsonDecode(jsonEncode(payload))),
    );
  }

  static List<ContentPack> _readPacks(List<String> sources) {
    if (sources.isEmpty || sources.length > 9) {
      throw const FormatException('Conjunto de paquetes inválido');
    }
    final base = ContentPack.parse(sources.first);
    if (base.id != 'barrio.core') {
      throw const FormatException('Falta el paquete base');
    }
    final result = [base];
    final ids = {base.id};
    for (final source in sources.skip(1)) {
      final pack = ContentPack.parse(source, base: base);
      if (!ids.add(pack.id)) throw const FormatException('Paquete duplicado');
      result.add(pack);
    }
    return result;
  }

  static Map<String, String> _bindings(List<ContentPack> packs) => {
    'core': packs.first.version,
    for (final pack in packs) '${pack.id}.version': pack.version,
    for (final pack in packs) '${pack.id}.sha256': pack.hash,
  };

  static Map<String, bool> _settings(dynamic raw, {bool complete = true}) {
    final map = _map(raw);
    _keys(
      map,
      _settingKeys,
      requiredKeys: complete ? _settingKeys : <String>{},
    );
    if (map.values.any((value) => value is! bool)) {
      throw const FormatException('Tipo de ajuste inválido');
    }
    return {for (final key in _settingKeys) key: map[key] as bool? ?? false};
  }

  static WorldState _world(Map<String, dynamic> state) {
    try {
      return WorldState.fromJson(state);
    } catch (_) {
      throw const FormatException('Estado del mundo inválido');
    }
  }

  static Map<String, dynamic> _parseEnvelope(String source) {
    if (utf8.encode(source).length > maxBytes) {
      throw const FormatException('Partida demasiado grande');
    }
    return _map(jsonDecode(source));
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Objeto inválido');
    }
    return value;
  }

  static void _keys(
    Map<String, dynamic> value,
    Set<String> allowed, {
    Set<String>? requiredKeys,
  }) {
    if (value.keys.any((key) => !allowed.contains(key)) ||
        !(requiredKeys ?? allowed).every(value.containsKey)) {
      throw const FormatException('Campos desconocidos o incompletos');
    }
  }

  static String _digest(dynamic value) =>
      sha256.convert(utf8.encode(_canonical(value))).toString();

  static String _canonical(dynamic value) {
    dynamic ordered(dynamic item) {
      if (item is Map) {
        final keys = item.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: ordered(item[key])};
      }
      if (item is List) return item.map(ordered).toList();
      return item;
    }

    return jsonEncode(ordered(value));
  }
}
