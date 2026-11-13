import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../content/content_pack.dart';
import '../persistence/checkpoint.dart';
import '../simulation/engine.dart';
import '../simulation/v2/materials.dart';

typedef SessionRead = Future<String?> Function(String slot, {bool backup});
typedef SessionWrite = Future<void> Function(String slot, String value);
typedef LegacyConsent = Future<bool> Function();

dynamic _freeze(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key as String, _freeze(item))),
    );
  }
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freeze));
  return value;
}

/// Detached, deeply immutable view of the last durable session confirmation.
class SessionSnapshot {
  final Map<String, dynamic> world, content;
  final Map<String, bool> settings;
  final String coreSource;
  final List<String> additionalSources;
  final int slot, generation, revision;
  final int? target;
  final bool stopCrisis;

  SessionSnapshot._(Checkpoint value, this.slot, this.generation, this.revision)
    : world = _freeze(value.world.toJson()) as Map<String, dynamic>,
      content = _freeze(value.content) as Map<String, dynamic>,
      settings = Map.unmodifiable(value.settings),
      coreSource = value.coreSource,
      additionalSources = List.unmodifiable(value.additionalSources),
      target = value.target,
      stopCrisis = value.stopCrisis;
}

class SessionLoadResult {
  final bool found, accepted, recovered, migrated;
  const SessionLoadResult({
    this.found = true,
    this.accepted = true,
    this.recovered = false,
    this.migrated = false,
  });
}

/// A worker may commit only the revision from which its current batch started.
class HistoryLease {
  final int generation, revision, slot, target;
  final SessionSnapshot snapshot;
  HistoryLease._(this.snapshot, this.target)
    : generation = snapshot.generation,
      revision = snapshot.revision,
      slot = snapshot.slot;
}

/// The only owner of a running world. Storage confirmation precedes publication.
/// Every operation captures state when it executes in this queue, never when an
/// autosave was requested. SaveStore's own queue remains the disk write boundary.
class SessionController {
  final SessionRead read;
  final SessionWrite write;
  final Future<String> Function() loadCore;
  final Future<String?> Function(String hash)? resolveLegacyCore;
  final Set<void Function()> _listeners = {};
  Future<void> _tail = Future.value();
  Future<void>? _initialization;
  Checkpoint? _checkpoint;
  SessionSnapshot? _snapshot;
  HistoryLease? _history;
  String? _installedCore;
  List<String> _available = const [];
  Map<String, bool> _settings = const {
    'reduceMotion': false,
    'sound': false,
    'vibration': false,
  };
  bool _stopCrisis = true, _disposed = false;
  int _slot = 0, _generation = 0, _revision = 0, _pending = 0;
  String? registryWarning;

  SessionController({
    required this.read,
    required this.write,
    required this.loadCore,
    this.resolveLegacyCore,
  });

  SessionSnapshot? get snapshot => _snapshot;
  bool get busy => _pending > 0 || _history != null;
  Future<void> get idle => _tail;
  int get slot => _slot;
  Map<String, bool> get settings => Map.unmodifiable(_settings);
  bool get stopCrisis => _stopCrisis;
  List<String> get availablePackSources => List.unmodifiable(_available);
  ContentPack? get basePack =>
      _installedCore == null ? null : ContentPack.parse(_installedCore!);
  String? get coreHash => basePack?.hash;
  WorldState? worldCopy() =>
      _snapshot == null ? null : WorldState.fromJson(_snapshot!.world);
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void dispose() {
    _disposed = true;
    _listeners.clear();
  }

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      // Observers cannot roll back a committed disk write or poison the queue.
      try {
        listener();
      } catch (_) {
        /* observer owns its rendering error */
      }
    }
  }

  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    final source = await loadCore();
    ContentPack.parse(source);
    _installedCore = source;
    final registry = await read('packages');
    if (registry != null) {
      try {
        final decoded = jsonDecode(registry);
        if (decoded is! List || decoded.any((item) => item is! String)) {
          throw const FormatException('Registro de paquetes inválido');
        }
        final sources = decoded.cast<String>();
        _validatePackages(sources);
        _available = List.unmodifiable(sources);
      } catch (error) {
        registryWarning = 'No se cargó el registro de paquetes: $error';
      }
    }
    _notify();
  }

  void _validatePackages(List<String> sources) {
    if (sources.length > 8) {
      throw const FormatException('Máximo ocho paquetes adicionales');
    }
    final base = ContentPack.parse(_installedCore!);
    final packs = [
      base,
      ...sources.map((source) => ContentPack.parse(source, base: base)),
    ];
    final registry = ContentRegistry();
    for (final pack in packs) {
      registry.importPack(pack);
    }
    registry.compose(packs.map((pack) => pack.pin).toList());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    if (_disposed) return Future.error(StateError('Sesión cerrada'));
    _pending++;
    _notify();
    final result = _tail.then((_) async {
      if (_disposed) throw StateError('Sesión cerrada');
      await initialize();
      return operation();
    });
    final finished = result.whenComplete(() {
      _pending--;
      _notify();
    });
    _tail = finished.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return finished;
  }

  void _checkSlot(int value) {
    if (value < 0 || value > 2) throw RangeError.range(value, 0, 2, 'slot');
  }

  Checkpoint _current() =>
      _checkpoint ?? (throw StateError('No hay una partida activa'));
  void _requireNoWorker() {
    if (_history != null) {
      throw StateError('Detén el avance histórico antes de cambiar la partida');
    }
  }

  Checkpoint _candidate(
    WorldState world, {
    int? target,
    Map<String, bool>? settings,
    bool? stopCrisis,
  }) {
    final current = _current();
    return Checkpoint.create(
      world: world,
      coreSource: current.coreSource,
      additionalSources: current.additionalSources,
      target: target,
      settings: settings ?? _settings,
      stopCrisis: stopCrisis ?? _stopCrisis,
    );
  }

  void _publish(Checkpoint value, int destination, {bool replace = false}) {
    if (replace) {
      _generation++;
      _history = null;
    }
    _revision++;
    _slot = destination;
    _checkpoint = value;
    _settings = Map.unmodifiable(value.settings);
    _stopCrisis = value.stopCrisis;
    _snapshot = SessionSnapshot._(value, destination, _generation, _revision);
    _notify();
  }

  Future<void> _commit(
    Checkpoint value, {
    int? destination,
    bool replace = false,
  }) async {
    final selected = destination ?? _slot;
    await write('world_$selected', value.encode());
    _publish(value, selected, replace: replace);
  }

  Future<void> createWorld({
    int seed = 42,
    int size = 96,
    String intensity = 'normal',
    bool extraordinary = true,
    int? slot,
  }) => _enqueue(() async {
    final destination = slot ?? _slot;
    _checkSlot(destination);
    final candidate = Checkpoint.create(
      world: WorldState.generate(
        seed: seed,
        size: size,
        intensity: intensity,
        extraordinary: extraordinary,
      ),
      coreSource: _installedCore!,
      additionalSources: _available,
      settings: _settings,
      stopCrisis: _stopCrisis,
    );
    await _commit(candidate, destination: destination, replace: true);
  });

  Future<SessionLoadResult> _import(
    String raw, {
    required int destination,
    required bool persist,
    LegacyConsent? acceptLegacy,
    bool recovered = false,
  }) async {
    _checkSlot(destination);
    if (utf8.encode(raw).length > Checkpoint.maxBytes) {
      throw const FormatException('Archivo demasiado grande');
    }
    final envelope = jsonDecode(raw);
    final legacy = envelope is Map && envelope['version'] == 1;
    var coreSource = _installedCore!;
    if (legacy && envelope['world'] is Map) {
      final versions = envelope['world']['contentVersions'];
      final hash = versions is Map ? versions['barrio.core.sha256'] : null;
      if (hash is String && hash != ContentPack.parse(coreSource).hash) {
        final archived = await resolveLegacyCore?.call(hash);
        if (archived == null || ContentPack.parse(archived).hash != hash) {
          throw const FormatException(
            'Falta el contenido original exacto; la partida se conserva',
          );
        }
        coreSource = archived;
      }
    }
    final candidate = legacy
        ? Checkpoint.migrateLegacy(raw, expectedCoreSource: coreSource)
        : Checkpoint.decode(raw);
    if (legacy) {
      if (acceptLegacy == null || !await acceptLegacy()) {
        return SessionLoadResult(
          accepted: false,
          recovered: recovered,
          migrated: false,
        );
      }
      await write('legacy_$destination', raw);
    }
    if (persist || legacy) {
      await _commit(candidate, destination: destination, replace: true);
    } else {
      _publish(candidate, destination, replace: true);
    }
    return SessionLoadResult(recovered: recovered, migrated: legacy);
  }

  Future<SessionLoadResult> importCheckpoint(
    String raw, {
    int? destinationSlot,
    bool persist = true,
    LegacyConsent? acceptLegacy,
  }) => _enqueue(
    () => _import(
      raw,
      destination: destinationSlot ?? _slot,
      persist: persist,
      acceptLegacy: acceptLegacy,
    ),
  );

  Future<SessionLoadResult> loadSlot(
    int slot, {
    bool backup = false,
    LegacyConsent? acceptLegacy,
  }) => _enqueue(() async {
    _checkSlot(slot);
    final raw = await read('world_$slot', backup: backup);
    if (raw == null) {
      return const SessionLoadResult(found: false, accepted: false);
    }
    try {
      return await _import(
        raw,
        destination: slot,
        persist: false,
        acceptLegacy: acceptLegacy,
        recovered: backup,
      );
    } on FormatException {
      if (backup) rethrow;
      final recovery = await read('world_$slot', backup: true);
      if (recovery == null) rethrow;
      return _import(
        recovery,
        destination: slot,
        persist: false,
        acceptLegacy: acceptLegacy,
        recovered: true,
      );
    }
  });

  Future<void> save() => _enqueue(() async {
    if (_checkpoint != null) await write('world_$_slot', _checkpoint!.encode());
  });
  Future<String> exportCurrent() => _enqueue(() async => _current().encode());
  Future<void> duplicateTo(int slot) => _enqueue(() async {
    _checkSlot(slot);
    await write('world_$slot', _current().encode());
  });
  Future<void> returnToWelcome() => _enqueue(() async {
    _requireNoWorker();
    if (_checkpoint != null) await write('world_$_slot', _checkpoint!.encode());
    _generation++;
    _revision++;
    _checkpoint = null;
    _snapshot = null;
    _notify();
  });
  Future<SessionLoadResult> restorePreviousBranch({
    LegacyConsent? acceptLegacy,
  }) => _enqueue(() async {
    _requireNoWorker();
    final source = await read('branch_$_slot');
    if (source == null) {
      return const SessionLoadResult(found: false, accepted: false);
    }
    return _import(
      source,
      destination: _slot,
      persist: true,
      acceptLegacy: acceptLegacy,
    );
  });

  Future<SessionLoadResult> upgradeRules({required LegacyConsent confirm}) =>
      _enqueue(() async {
        _requireNoWorker();
        final source = await read('world_$_slot');
        if (source == null) {
          throw const FormatException('No hay archivo original que conservar');
        }
        final disk = Checkpoint.decode(source);
        if (disk.encode() != _current().encode()) {
          throw StateError('El archivo cambió fuera de la sesión');
        }
        final candidate = Checkpoint.upgradeRules(source);
        if (!await confirm()) return const SessionLoadResult(accepted: false);
        final hash = sha256.convert(utf8.encode(source)).toString();
        final key = 'rules_${_slot}_$hash';
        final existing = await read(key);
        if (existing != null && existing != source) {
          throw const FormatException('Conflicto en copia original');
        }
        if (existing == null) await write(key, source);
        await _commit(candidate, replace: true);
        return const SessionLoadResult(migrated: true);
      });
  Future<SessionLoadResult> restoreRulesBackup() => _enqueue(() async {
    _requireNoWorker();
    final changes = _current().world.ruleChanges;
    if (changes.isEmpty) {
      return const SessionLoadResult(found: false, accepted: false);
    }
    final hash = changes.last['sourceSha256'];
    final raw = await read('rules_${_slot}_$hash');
    if (raw == null) {
      throw const FormatException('La copia original no está disponible');
    }
    if (sha256.convert(utf8.encode(raw)).toString() != hash) {
      throw const FormatException('La copia original está dañada');
    }
    return _import(raw, destination: _slot, persist: true);
  });

  Future<CommandResult> _submit(Command request) async {
    _requireNoWorker();
    final world =
        worldCopy() ?? (throw StateError('No hay una partida activa'));
    final sim = Simulation(world)..registerContent(_current().content);
    final result = sim.submit(request);
    if (result.ok && !result.replayed) {
      await _commit(_candidate(world, target: _current().target));
    }
    return result;
  }

  Future<CommandResult> submit(Command request) =>
      _enqueue(() => _submit(request));
  Future<CommandResult> command(
    String action, {
    String? target,
    String? choice,
  }) => _enqueue(() {
    final world = _current().world;
    return _submit(
      Command(
        id: 'session-$_generation-$_revision-${world.day}-${world.commandReceipts.length}',
        action: action,
        actorId: world.controlledId,
        issuedDay: world.day,
        target: target,
        choice: choice,
      ),
    );
  });
  Future<CommandResult> resolveEvent(String event, String option) =>
      command('resolve_event', target: event, choice: option);
  Future<int> advance(int days) => _enqueue(() async {
    _requireNoWorker();
    if (days < 0 || days > 30) throw RangeError.range(days, 0, 30, 'days');
    final world =
        worldCopy() ?? (throw StateError('No hay una partida activa'));
    final sim = Simulation(world)..registerContent(_current().content);
    final advanced = sim
        .advance(AdvanceRequest(days: days, stopOnCrisis: _stopCrisis))
        .advancedDays;
    final target = _current().target;
    await _commit(
      _candidate(
        world,
        target: target != null && world.day >= target ? null : target,
      ),
    );
    return advanced;
  });

  Future<void> updateSettings({
    bool? reduceMotion,
    bool? sound,
    bool? vibration,
    bool? stopCrisis,
  }) => _enqueue(() async {
    _requireNoWorker();
    final settings = {
      ..._settings,
      if (reduceMotion != null) 'reduceMotion': reduceMotion,
      if (sound != null) 'sound': sound,
      if (vibration != null) 'vibration': vibration,
    };
    if (_checkpoint == null) {
      _settings = Map.unmodifiable(settings);
      _stopCrisis = stopCrisis ?? _stopCrisis;
      _notify();
    } else {
      await _commit(
        _candidate(
          worldCopy()!,
          target: _current().target,
          settings: settings,
          stopCrisis: stopCrisis,
        ),
      );
    }
  });
  Future<void> importPackage(String raw) => _enqueue(() async {
    final candidate = [..._available, raw];
    _validatePackages(candidate);
    validateMaterialCosts(ContentPack.parse(raw, base: basePack).data);
    await write('packages', jsonEncode(candidate));
    _available = List.unmodifiable(candidate);
    registryWarning = null;
    _notify();
  });

  Future<HistoryLease> beginHistory(int years, {bool resume = false}) =>
      _enqueue(() async {
        _requireNoWorker();
        if (![1, 10, 100].contains(years)) {
          throw ArgumentError.value(years, 'years');
        }
        final current = _current();
        final target = resume
            ? current.target
            : current.world.day + years * 360;
        if (target == null || target <= current.world.day) {
          throw StateError('No hay un avance pendiente');
        }
        if (!resume) await write('branch_$_slot', current.encode());
        await _commit(_candidate(worldCopy()!, target: target));
        _history = HistoryLease._(_snapshot!, target);
        return _history!;
      });
  void _checkLease(HistoryLease lease) {
    if (_history == null ||
        lease.generation != _generation ||
        lease.revision != _revision ||
        lease.slot != _slot ||
        lease.target != _history!.target) {
      throw StateError('Resultado histórico obsoleto');
    }
  }

  Future<HistoryLease?> commitHistoryBatch(
    HistoryLease lease,
    Map<String, dynamic> state, {
    required bool done,
  }) => _enqueue(() async {
    _checkLease(lease);
    final world = WorldState.fromJson(state);
    final current = _current().world;
    if (world.seed != current.seed ||
        world.size != current.size ||
        world.day < current.day ||
        world.day > lease.target) {
      throw const FormatException('El lote no pertenece al avance actual');
    }
    await _commit(
      _candidate(
        world,
        target: world.day >= lease.target ? null : lease.target,
      ),
    );
    _history = done ? null : HistoryLease._(_snapshot!, lease.target);
    return _history;
  });
  Future<void> endHistory(HistoryLease lease) => _enqueue(() async {
    _checkLease(lease);
    _history = null;
    _notify();
  });
}
