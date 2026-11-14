import 'dart:async';
import 'dart:isolate';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import '../simulation/engine.dart';
import '../content/content_pack.dart';
import 'storage.dart';
import '../platform/document_exchange.dart';
import '../session/session_controller.dart';
import '../session/history_worker.dart';
import 'world_game.dart';
import 'settlement_scene.dart';

class BarrioApp extends StatelessWidget {
  const BarrioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Barrio Cero: Eras',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: moss,
        surface: ink,
      ),
      scaffoldBackgroundColor: ink,
      fontFamily: 'sans-serif',
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
    home: const ErasScreen(),
  );
}

class ErasScreen extends StatefulWidget {
  const ErasScreen({super.key});
  @override
  State<ErasScreen> createState() => _ErasScreenState();
}

class _ErasScreenState extends State<ErasScreen> with WidgetsBindingObserver {
  late final SessionController session;
  WorldState? get world => session.worldCopy();
  late WorldGame game;
  final store = SaveStore();
  final documents = DocumentExchange();
  Map<String, dynamic> state = {};
  RuleCatalog? _catalog;
  List<BuildingDefinition> get _buildings=>_catalog?.buildings??buildings;
  List<Technology> get _technologies=>_catalog?.technologies??technologies;
  String? selected;
  int preferredSlot = 0;
  int get slot => session.snapshot?.slot ?? preferredSlot;
  int section = 0;
  Timer? timer;
  bool get reduceMotion => session.settings['reduceMotion'] ?? false;
  bool get sound => session.settings['sound'] ?? false;
  bool get vibration => session.settings['vibration'] ?? false;
  bool get stopCrisis => session.stopCrisis;
  bool get advancing => session.busy;
  bool busy = false;
  int speed = 1;
  int? get jumpTarget => session.snapshot?.target;
  int jumpStart = 0;
  Map<String, dynamic>? jumpBefore;
  SendPort? jumpControl;
  Isolate? worker;
  bool webCancel = false;
  HistoryLease? historyLease;
  void _cancelJump() {
    webCancel = true;
    jumpControl?.send('cancel');
  }

  ReceivePort? results;
  Future<void> commitQueue = Future.value();
  Future<void> get saveQueue => session.idle;
  late final Future<void> initialization;
  String note = '';
  Map<String, dynamic>? get core => session.snapshot?.content;
  String? get coreHash => session.coreHash;
  ContentPack? get basePack => session.basePack;
  List<String> get availablePackSources => session.availablePackSources;
  Simulation _sim() {
    final value = Simulation(session.worldCopy()!);
    if (core != null) value.registerContent(core!);
    return value;
  }

  Offset gesturePan = Offset.zero;
  double gestureZoom = 1;
  int get day => number(state['day']);
  int number(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
  List<Map<String, dynamic>> get societies =>
      (state['societies'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Map<String, dynamic>? get society =>
      societies.where((s) => s['id'] == selected).firstOrNull;
  String get controlled => '${state['controlledId'] ?? ''}';
  String date(int d) =>
      'Año ${d ~/ 360 + 1} · mes ${(d % 360) ~/ 30 + 1} · día ${d % 30 + 1}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game = WorldGame((id) {
      if (mounted) {
        setState(() {
          selected = id;
          game.selected = id;
        });
      }
    }, onLocalSelect: _inspectLocal);
    session = SessionController(
      read: store.read,
      write: store.write,
      loadCore: () => rootBundle.loadString('assets/content/core.json'),
      resolveLegacyCore: (hash) async => hash==
          'a751baac02f9a32bbd2e5058e507e53c50d118d95c9dad527c66f5e3db40e568'
          ? await rootBundle.loadString('assets/content/legacy_core_1.json') : null,
    );
    session.addListener(_sessionChanged);
    initialization = session.initialize().catchError((Object error) {
      _message('No se pudo preparar el juego: $error');
    });
  }

  void _sessionChanged() {
    if (mounted) setState(refresh);
  }

  void refresh() {
    state = session.snapshot?.world ?? {};
    _catalog=state['catalog']==null?null:RuleCatalog.fromJson(Map<String,dynamic>.from(state['catalog']));
    if (selected == null || !societies.any((s) => s['id'] == selected)) {
      selected = controlled.isNotEmpty
          ? controlled
          : societies.firstOrNull?['id']?.toString();
    }
    game.data = state;
    game.selected = selected;
    game.reduceMotion = reduceMotion;
  }

  void _focusHome() {
    selected = controlled.isNotEmpty
        ? controlled
        : societies.firstOrNull?['id']?.toString();
    _navigate(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    jumpControl?.send('cancel');
    results?.close();
    worker?.kill();
    session.removeListener(_sessionChanged);
    session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value != AppLifecycleState.resumed) {
      timer?.cancel();
      timer = null;
      if (busy) {
        _cancelJump();
      } else {
        _save().catchError((Object error) {
          _message('No se pudo guardar al pausar: $error');
        });
      }
    }
  }

  Future<void> _save() => session.save();
  Future<bool> _acceptLegacy() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Actualizar guardado del prototipo'),
            content: const Text(
              'Se conservará una copia del archivo original. El nuevo formato protege el objetivo temporal, los ajustes y el contenido. Se conservan las reglas actuales del mundo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Conservar copia y actualizar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _load({bool backup = false, int? fromSlot}) async {
    if (busy || advancing) return;
    timer?.cancel();
    timer = null;
    try {
      final result = await session.loadSlot(
        fromSlot ?? slot,
        backup: backup,
        acceptLegacy: _acceptLegacy,
      );
      if (!result.found) {
        _message('No hay una partida en este espacio.');
        return;
      }
      if (!result.accepted) return;
      if (mounted) _focusHome();
      if (result.recovered) _message('Copia anterior recuperada.');
      if (jumpTarget != null && jumpTarget! > day) {
        _message('Salto recuperado. Puedes continuarlo desde Avanzar.');
      }
    } catch (e) {
      _message('No se pudo cargar. Prueba Recuperar copia: $e');
    }
  }

  Future<bool> _import(
    String raw, {
    bool persist = true,
    int? destinationSlot,
  }) async {
    if (busy) throw StateError('Pausa el salto antes de importar.');
    timer?.cancel();
    timer = null;
    final result = await session.importCheckpoint(
      raw,
      persist: persist,
      destinationSlot: destinationSlot ?? slot,
      acceptLegacy: _acceptLegacy,
    );
    if (result.accepted && mounted) _focusHome();
    return result.accepted;
  }

  void _message(String text) {
    if (!mounted) return;
    setState(() => note = text);
    if (session.snapshot != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _newWorld() async {
    await initialization;
    if (busy || advancing || !mounted) return;
    timer?.cancel();
    timer = null;
    var seed = '${DateTime.now().millisecondsSinceEpoch % 100000}';
    String intensity = 'normal';
    String origin='prehistory';
    int size = 96;
    bool extraordinary = true;
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: const Text('Un mundo por escribir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cada decisión deja memoria. El tiempo se detiene cuando cierras el juego.',
                  style: TextStyle(color: earth),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue:origin,
                  isExpanded:true,
                  decoration:const InputDecoration(labelText:'Origen'),
                  items:const [
                    DropdownMenuItem(value:'prehistory',child:Text('Prehistoria')),
                    DropdownMenuItem(value:'reconstruction',child:Text('Reconstrucción')),
                  ],
                  onChanged:(v)=>change(()=>origin=v!),
                ),
                const SizedBox(height:8),
                Text(origin=='prehistory'
                  ?'24 habitantes, refugios y recolección. Aprende a tallar y a cultivar sin empezar con metal ni electricidad.'
                  :'56 habitantes recuperan huertos, pozos y materiales del mundo anterior.',
                  style:const TextStyle(color:earth)),
                const SizedBox(height:12),
                TextFormField(
                  initialValue: seed,
                  onChanged: (value) => seed = value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Semilla reproducible',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: intensity,
                  decoration: const InputDecoration(labelText: 'Intensidad'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'caótica', child: Text('Caótica')),
                    DropdownMenuItem(value: 'extrema', child: Text('Extrema')),
                  ],
                  onChanged: (v) => change(() => intensity = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: size,
                  decoration: const InputDecoration(labelText: 'Mapa'),
                  items: const [
                    DropdownMenuItem(
                      value: 64,
                      child: Text('Pequeño · 64 × 64'),
                    ),
                    DropdownMenuItem(
                      value: 96,
                      child: Text('Normal · 96 × 96'),
                    ),
                  ],
                  onChanged: (v) => change(() => size = v!),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Familias extraordinarias'),
                  subtitle: const Text('Contacto, máquinas y transformaciones'),
                  value: extraordinary,
                  onChanged: (v) => change(() => extraordinary = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fundar Barrio Cero'),
            ),
          ],
        ),
      ),
    );
    if (create != true) return;
    try {
      await session.createWorld(
        seed: int.tryParse(seed) ?? 42,
        size: size,
        intensity: intensity,
        extraordinary: extraordinary,
        origin:origin,
        slot: slot,
      );
      if (!mounted) return;
      _focusHome();
      setState(() => note = '');
    } catch (e) {
      _message('No se pudo crear el mundo: $e');
    }
  }

  Future<void> _command(String action, {String? target, String? choice}) async {
    if (busy || session.snapshot == null || advancing) return;
    if (!['control', 'delegate'].contains(action) && selected != controlled) {
      _message(
        'Asume la dirección de esta comunidad desde su ficha para darle órdenes.',
      );
      return;
    }
    try {
      final result = await session.command(
        action,
        target: target,
        choice: choice,
      );
      if (result.ok) {
        if (action == 'control' && mounted) _focusHome();
        if (vibration) HapticFeedback.lightImpact();
        if (sound) SystemSound.play(SystemSoundType.click);
      }
      _message(result.message);
    } catch (e) {
      _message('La orden no pudo aplicarse: $e');
    }
  }

  Future<void> _advance(int days) async {
    if (busy || session.snapshot == null || advancing) return;
    try {
      await session.advance(days);
    } catch (e) {
      timer?.cancel();
      timer = null;
      _message('Simulación detenida: $e');
    }
  }

  void _play() {
    if (timer != null) {
      timer!.cancel();
      setState(() => timer = null);
    } else {
      timer = Timer.periodic(Duration(milliseconds: 1200 ~/ speed), (t) {
        _advance(1);
      });
      setState(() {});
    }
  }

  Future<void> _endJump({
    String? error,
    bool report = false,
    bool cancelled = false,
  }) async {
    final lease = historyLease;
    historyLease = null;
    if (lease != null) {
      try {
        await session.endHistory(lease);
      } catch (_) {
        /* a replacement already invalidated this worker */
      }
    }
    results?.close();
    results = null;
    jumpControl = null;
    if (error != null) worker?.kill();
    worker = null;
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      _message(error);
    } else if (report) {
      _jumpReport(cancelled);
    }
  }

  Future<void> _jump(int years, {bool resume = false}) async {
    if (advancing || busy) {
      _message('Espera a que se confirme el avance actual.');
      return;
    }
    setState(() => busy = true);
    webCancel = false;
    timer?.cancel();
    timer = null;
    jumpBefore = Map<String, dynamic>.from(state);
    jumpStart = day;
    try {
      historyLease = await session.beginHistory(
        resume ? 1 : years,
        resume: resume,
      );
      if (!mounted) return;
      if (webCancel) {
        await _endJump(report: true, cancelled: true);
        return;
      }
      if (kIsWeb) {
        await _jumpWeb();
        return;
      }
      results = ReceivePort();
      results!.listen((dynamic message) {
        commitQueue = commitQueue
            .then((_) async {
              if (!mounted) return;
              final m = Map<String, dynamic>.from(message as Map);
              if (m['control'] != null) {
                jumpControl = m['control'] as SendPort;
                if (webCancel) jumpControl?.send('cancel');
                return;
              }
              if (m['error'] != null) {
                await _endJump(error: 'Salto detenido: ${m['error']}');
                return;
              }
              if (m['world'] != null) {
                final done = m['done'] == true;
                historyLease = await session.commitHistoryBatch(
                  historyLease!,
                  Map<String, dynamic>.from(m['world'] as Map),
                  done: done,
                );
                // Every batch, including the last, is acknowledged only after disk confirmation.
                jumpControl?.send('ack');
                if (done) {
                  await _endJump(
                    report: true,
                    cancelled: m['cancelled'] == true,
                  );
                }
              }
            })
            .catchError((Object error) async {
              jumpControl?.send('cancel');
              await _endJump(
                error:
                    'No se confirmó el último lote: $error. Se conserva la fecha guardada.',
              );
            });
      });
      final lease = historyLease!;
      worker = await Isolate.spawn(historyWorker, {
        'port': results!.sendPort,
        'world': lease.snapshot.world,
        'target': lease.target,
        'stop': lease.snapshot.stopCrisis,
        'content': lease.snapshot.content,
      });
    } catch (e) {
      await _endJump(error: 'No se pudo iniciar el avance: $e');
    }
  }

  Future<void> _jumpWeb() async {
    try {
      while (historyLease != null && !webCancel) {
        final lease = historyLease!;
        final candidate = WorldState.fromJson(lease.snapshot.world);
        final sim = Simulation(candidate)
          ..registerContent(lease.snapshot.content);
        final days = (lease.target - candidate.day).clamp(0, 30).toInt();
        final advanced = sim.advanceDays(
          days,
          stopOnCrisis: lease.snapshot.stopCrisis,
          delegateDecisions: !lease.snapshot.stopCrisis,
        );
        final done = candidate.day >= lease.target || advanced < days;
        historyLease = await session.commitHistoryBatch(
          lease,
          candidate.toJson(),
          done: done,
        );
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await _endJump(report: true, cancelled: webCancel);
    } catch (e) {
      await _endJump(error: 'No se confirmó el avance: $e');
    }
  }

  void _jumpReport(bool cancelled) {
    final before = jumpBefore ?? {};
    int pop(Map<String, dynamic> d) => (d['societies'] as List? ?? [])
        .fold<int>(0, (n, s) => n + number(s['population']));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cancelled ? 'Historia pausada' : 'Una nueva era'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${date(jumpStart)} → ${date(day)}'),
              const SizedBox(height: 16),
              Text('Población mundial: ${pop(before)} → ${pop(state)}'),
              Text(
                'Sociedades: ${(before['societies'] as List? ?? []).length} → ${societies.length}',
              ),
              Text('Tecnologías: ${_totalTech(before)} → ${_totalTech(state)}'),
              Text(
                'Daño ambiental medio: ${_environment(before).toStringAsFixed(1)} → ${_environment(state).toStringAsFixed(1)}',
              ),
              Text(
                'Pactos y tensiones: ${_relations(before)} → ${_relations(state)}',
              ),
              const SizedBox(height: 12),
              ...((state['chronicle'] as List? ?? [])
                  .where((e) => number(e['day']) > jumpStart)
                  .toList()
                  .reversed
                  .take(3)
                  .map(
                    (e) => Text(
                      '• ${e['title']}',
                      style: const TextStyle(fontSize: 11, color: earth),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text(
                'La crónica conserva las causas de los cambios. Cancelar conserva todo el periodo confirmado.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al mundo'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _chronicle();
            },
            child: const Text('Leer crónica'),
          ),
        ],
      ),
    );
  }

  int _totalTech(Map<String, dynamic> data) =>
      (data['societies'] as List? ?? []).fold<int>(
        0,
        (n, s) => n + (s['tech'] as List? ?? []).length,
      );
  double _environment(Map<String, dynamic> data) {
    final list = data['societies'] as List? ?? [];
    return list.isEmpty
        ? 0
        : list.fold<double>(
                0,
                (n, s) => n + (s['environment'] as num? ?? 0).toDouble(),
              ) /
              list.length;
  }

  String _relations(Map<String, dynamic> data) {
    var good = 0, bad = 0;
    for (final s in data['societies'] as List? ?? []) {
      for (final value in (s['relations'] as Map? ?? {}).values) {
        if (number(value) > 30) good++;
        if (number(value) < -30) bad++;
      }
    }
    return '${good ~/ 2} amistades / ${bad ~/ 2} rivalidades';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: session.snapshot == null ? _welcome() : _world()),
  );
  Widget _welcome() => Center(
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CRÓNICAS DE UN PLANETA',
                textAlign: TextAlign.center,
                style: TextStyle(color: earth, fontSize: 11, letterSpacing: 3),
              ),
              const SizedBox(height: 12),
              const Text(
                'BARRIO\nCERO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 64,
                  height: .95,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'E R A S',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: moss,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  height: 2,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'De un pequeño barrio al legado de siglos.\nConstruye. Decide. Observa lo que permanece.',
                textAlign: TextAlign.center,
                style: TextStyle(color: earth, height: 1.6),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _newWorld,
                child: const Text('CREAR UN MUNDO'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Continuar historia'),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Espacio de guardado  '),
                  DropdownButton<int>(
                    value: slot,
                    items: List.generate(
                      3,
                      (i) =>
                          DropdownMenuItem(value: i, child: Text('${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => preferredSlot = v!),
                  ),
                ],
              ),
              TextButton(
                onPressed: _archive,
                child: const Text('Importar / recuperar partida'),
              ),
              if (kIsWeb)
                const Text(
                  'Vista web: guardado temporal. Exporta tu partida antes de cerrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: earth),
                ),
              const SizedBox(height: 22),
              const Text(
                'Sin conexión · Sin cuentas · Tu historia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: moss),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void _navigate(int value) {
    setState(() {
      section = value;
      if (value == 0) {
        if (controlled.isNotEmpty) selected = controlled;
        game.mode = 'Asentamiento';
        game.zoom = 1.7;
      } else if (value == 1) {
        game.mode = 'Mundo';
        game.zoom = 1;
      }
      if (selected != null) {
        game.selected = selected;
        game.locate(selected!);
      }
    });
  }

  Widget _world() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date(day),
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    controlled.isEmpty
                        ? 'Observando · gobiernos autónomos'
                        : 'Diriges ${societies.where((s) => s['id'] == controlled).firstOrNull?['name'] ?? controlled}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: moss),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: busy || advancing ? null : _menu,
              child: const Text('MENÚ'),
            ),
          ],
        ),
      ),
      Expanded(
        child: section == 2
            ? _historyPage()
            : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onScaleStart: (d) {
                              gesturePan = game.pan;
                              gestureZoom = game.zoom;
                            },
                            onScaleUpdate: (d) {
                              game.pan = gesturePan + d.focalPointDelta;
                              gesturePan = game.pan;
                              game.zoom = (gestureZoom * d.scale)
                                  .clamp(.6, 9)
                                  .toDouble();
                            },
                            onTapUp: (d) => game.touch(d.localPosition),
                            child: ClipRect(child: GameWidget(game: game)),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Column(
                            children: [
                              _mapButton(
                                Icons.add,
                                'Acercar',
                                () => game.zoom = (game.zoom * 1.4)
                                    .clamp(.6, 9)
                                    .toDouble(),
                              ),
                              _mapButton(
                                Icons.remove,
                                'Alejar',
                                () => game.zoom = (game.zoom / 1.4)
                                    .clamp(.6, 9)
                                    .toDouble(),
                              ),
                              _mapButton(
                                Icons.my_location,
                                'Centrar comunidad',
                                () {
                                  if (selected != null) game.locate(selected!);
                                },
                              ),
                            ],
                          ),
                        ),
                        if (section == 1)
                          Positioned(
                            left: 8,
                            bottom: 4,
                            child: Container(
                              color: ink.withValues(alpha: .95),
                              child: Wrap(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        game.mode = game.mode == 'Región'
                                            ? 'Mundo'
                                            : 'Región';
                                        game.zoom = game.mode == 'Región'
                                            ? 3
                                            : 1;
                                        if (selected != null) {
                                          game.locate(selected!);
                                        }
                                      });
                                    },
                                    child: Text(
                                      game.mode == 'Región'
                                          ? 'Ver planeta'
                                          : 'Ver región',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _mapOptions,
                                    child: const Text('Filtros'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .40,
                    ),
                    child: SingleChildScrollView(child: _selection()),
                  ),
                ],
              ),
      ),
      if (note.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _sheet('Último resultado', [Text(note)]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: earth),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar mensaje',
                onPressed: () => setState(() => note = ''),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      if (busy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: jumpTarget == null || jumpTarget == jumpStart
                    ? null
                    : ((day - jumpStart) / (jumpTarget! - jumpStart))
                          .clamp(0.0, 1.0)
                          .toDouble(),
              ),
              TextButton(
                onPressed: _cancelJump,
                child: const Text('Pausar salto y conservar avance'),
              ),
            ],
          ),
        ),
      Container(
        color: const Color(0xff253235),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: timer == null
                    ? 'Reproducir un día por paso'
                    : 'Pausar tiempo',
                child: TextButton(
                  onPressed: busy || advancing ? null : _play,
                  child: Icon(timer == null ? Icons.play_arrow : Icons.pause),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: busy || advancing ? null : () => _advance(1),
                child: const Text('+ Día'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: busy || advancing ? null : _timeOptions,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Avanzar', maxLines: 1),
              ),
            ),
          ],
        ),
      ),
      NavigationBar(
        height: 64,
        selectedIndex: section,
        onDestinationSelected: _navigate,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Barrio',
          ),
          NavigationDestination(icon: Icon(Icons.public), label: 'Mundo'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historia'),
        ],
      ),
    ],
  );
  Widget _mapButton(IconData icon, String label, VoidCallback tap) => SizedBox(
    width: 48,
    height: 48,
    child: IconButton(
      tooltip: label,
      style: IconButton.styleFrom(backgroundColor: ink.withValues(alpha: .85)),
      onPressed: tap,
      icon: Icon(icon, size: 20),
    ),
  );
  void _mapOptions() => _sheet('Leer el mundo', [
    ListTile(
      title: const Text('Rutas y caravanas'),
      onTap: () {
        Navigator.pop(context);
        _routes();
      },
    ),
    ...['Territorios', 'Población', 'Recursos', 'Conflictos', 'Entorno'].map(
      (filter) => ListTile(
        title: Text(filter),
        leading: Icon(
          game.filter == filter
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
        ),
        onTap: () {
          setState(() => game.filter = filter);
          Navigator.pop(context);
        },
      ),
    ),
    SwitchListTile(
      title: const Text('Minimapa'),
      value: game.mini,
      onChanged: (v) {
        game.mini = v;
        Navigator.pop(context);
      },
    ),
  ]);
  void _timeOptions() => _sheet('Avanzar el tiempo', [
    const Text(
      'Cada avance confirma y guarda días completos. Las crisis pueden detenerlo antes de la fecha elegida.',
      style: TextStyle(color: earth),
    ),
    ListTile(
      title: const Text('Avanzar un mes'),
      subtitle: const Text('30 días con las mismas reglas diarias'),
      onTap: () {
        Navigator.pop(context);
        _advance(30);
      },
    ),
    ListTile(
      title: const Text('Años y delegación'),
      subtitle: const Text('Uno, diez o cien años · pausa y continuación'),
      onTap: () {
        Navigator.pop(context);
        _years();
      },
    ),
  ]);
  Widget _selection() {
    final s = society;
    if (s == null) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text('Toca una comunidad para conocerla.'),
      );
    }
    final resources = s['resources'] as Map? ?? {};
    final own = s['id'] == controlled;
    final projects = s['projects'] as List? ?? [];
    final alive = s['extinct'] != true && number(s['population']) > 0;
    final leader = (s['people'] as List? ?? [])
        .where((dynamic p) => p['id'] == s['leaderId'] && p['diedDay'] == null)
        .firstOrNull;
    final suggestion = !alive
        ? 'Esta comunidad dejó un legado. Puedes revisar su historia.'
        : !own
        ? 'Observas una comunidad autónoma. Consultar su ficha no cambia su gobierno.'
        : projects.isNotEmpty
        ? 'Trabajo en marcha: ${_buildingName(projects.first['building'])}. Termina en ${date(number(projects.first['finish']))}.'
        : state['origin']=='prehistory'
        ? _primitiveSuggestion(s)
        : 'Una oportunidad: amplía tus reservas con un huerto o mejora los hogares.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: const BoxDecoration(
        color: ink,
        border: Border(top: BorderSide(color: Color(0xff47514b))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s['name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _details(s),
                child: const Text('Comunidad'),
              ),
            ],
          ),
          Text(
            '${number(s['population'])} habitantes${leader == null ? '' : ' · Lidera ${leader['name']}'}',
            style: const TextStyle(color: moss, fontSize: 12),
          ),
          Text(
            'Alimento ${number(resources['food'])} · Agua ${number(resources['water'])} · Salud ${number(s['health'])}%',
            style: const TextStyle(color: earth, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
              projects.isNotEmpty &&
                      (projects.first['work'] as Map?)?['paused'] == true
                  ? 'Obra detenida: faltan trabajadores disponibles.'
                  : suggestion,
              style: const TextStyle(fontSize: 12),
            ),
          if (own && alive)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: busy || advancing ? null : _build,
                    child: const Text('Construir'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: busy || advancing ? null : _communityActions,
                    child: const Text('Más acciones'),
                  ),
                ),
              ],
            ),
          if (!own && alive)
            TextButton(
              onPressed: busy || advancing
                  ? null
                  : () => _confirmCommand(
                      'Dirigir esta comunidad',
                      'control',
                      target: s['id'].toString(),
                    ),
              child: const Text('Asumir dirección'),
            ),
        ],
      ),
    );
  }

  String _buildingName(dynamic id) =>
      _buildings.where((b) => b.id == id).firstOrNull?.name ?? '$id';
  String _technologyName(dynamic id) =>
      _technologies.where((t) => t.id == id).firstOrNull?.name ?? '$id';
  String _primitiveSuggestion(Map<String,dynamic> s) {
    if(_housing(s)<=number(s['population']))return 'Primer paso: un refugio añade ocho plazas. Revisa el coste y elige dónde invertir.';
    final known=Set<String>.from(s['tech']??[]);
    final resources=s['resources'] as Map? ?? {};
    if(!(_catalog?.provides(known,'handcraft')??false)) {
      final technique=_technologies.where((t)=>t.capabilities.contains('handcraft')).firstOrNull;
      if(technique!=null&&(resources['knowledge'] as num? ??0)>=technique.cost&&technique.requires.every(known.contains))return 'Ya puedes aprender ${technique.name.toLowerCase()}: Más acciones → Investigar.';
      return 'El círculo de memoria sigue aprendiendo. Protege las reservas mientras reúnes conocimientos.';
    }
    if(number((s['built'] as Map?)?['knapping_shed'])==0)return 'Consulta el taller de talla para convertir piedra y madera en herramientas.';
    if((resources['tools'] as num? ??0)>=2&&s['facilityFound']!=true)return 'Las herramientas permiten preparar una expedición desde Más acciones → Explorar.';
    return 'Observa a otras comunidades y revisa sus necesidades antes de comprometer un intercambio.';
  }

  Map<String,dynamic>? _personPopulation(String id) {
    final population=state['populationState'] as Map?;
    if(population==null)return null;
    final cohortId=(population['members'] as Map?)?[id];
    final cohort=((population['cohorts'] as List?)??[]).where((c)=>c['id']==cohortId).firstOrNull;
    final record=cohort??(population['archives'] as Map?)?[id];
    return record is Map?Map<String,dynamic>.from(record):null;
  }
  String _cultureName(dynamic id)=>
    (((state['entities'] as Map?)?['cultures'] as List?)??[])
      .where((c)=>c['id']==id).firstOrNull?['name']?.toString()??'Sin registro';
  void _communityActions() => _sheet('Dirigir la comunidad', [
    ListTile(
      title: const Text('Investigar'),
      subtitle: const Text('Conocimientos disponibles y requisitos'),
      onTap: () {
        Navigator.pop(context);
        _research();
      },
    ),
    if (state['populationState'] != null)
      ListTile(title: const Text('Formar aprendices'),
        subtitle: const Text('Transmitir oficios con trabajo y provisiones'),
        onTap: () {Navigator.pop(context);_learning();}),
    ListTile(
      title: const Text('Explorar'),
      subtitle: const Text('Preparar una expedición y conocer su coste'),
      onTap: () {
        Navigator.pop(context);
        _confirmCommand('Preparar expedición', 'explore');
      },
    ),
    ListTile(
      title: const Text('Decisiones'),
      subtitle: const Text('Consultar oportunidades de la comunidad'),
      onTap: () {
        Navigator.pop(context);
        _stories();
      },
    ),
    ListTile(
      title: const Text('Diplomacia'),
      subtitle: const Text('Comercio y acuerdos con otras comunidades'),
      onTap: () {
        Navigator.pop(context);
        _diplomacy();
      },
    ),
    if (state['entities'] != null)
      ListTile(
        title: const Text('Sociedad y capital'),
        subtitle: const Text('Ciudades, reservas locales y gobierno'),
        onTap: () {
          Navigator.pop(context);
          _politicalSheet();
        },
      ),
    ListTile(
      title: const Text('Políticas y delegación'),
      subtitle: const Text('Prioridades para el gobierno autónomo'),
      onTap: () {
        Navigator.pop(context);
        _policies();
      },
    ),
    if (society?['facilityFound'] == true)
      ListTile(
        title: const Text('Instalación antigua'),
        onTap: () {
          Navigator.pop(context);
          _facility();
        },
      ),
    ListTile(
      title: const Text('Reparar'),
      subtitle: const Text('Consultar materiales y efectos'),
      onTap: () {
        Navigator.pop(context);
        _confirmCommand('Reparar la comunidad', 'repair');
      },
    ),
  ]);
  Widget _historyPage() {
    final entries = (state['chronicle'] as List? ?? []).reversed
        .take(180)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'La memoria del mundo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: gold,
          ),
        ),
        if (controlled.isNotEmpty)
          TextButton(
            onPressed: () {
              selected = controlled;
              _stories();
            },
            child: const Text('Consultar decisiones de tu comunidad'),
          ),
        Text(
          '${entries.length} noticias recientes. Toca una para localizarla.',
          style: const TextStyle(color: earth),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Tu historia empieza con las primeras decisiones.'),
          ),
        ...entries.map((dynamic entry) {
          final m = entry as Map;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${m['title'] ?? ''}'),
            subtitle: Text(
              '${date(number(m['day']))} · ${m['text'] ?? ''}${m['cause'] == null ? '' : ' · Causa: ${m['cause']}'}',
            ),
            onTap: () {
              final id = m['societyId']?.toString();
              if (id != null) {
                selected = id;
                _navigate(1);
              }
            },
          );
        }),
        TextButton(
          onPressed: _chronicle,
          child: const Text('Abrir crónica en panel'),
        ),
      ],
    );
  }

  Future<void> _sheet(String title, List<Widget> children) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      );
  void _inspectLocal(LocalSelection hit) {
    timer?.cancel();
    timer = null;
    final s = society;
    if (s == null) return;
    if (hit.kind == 'person') {
      final p = hit.entity;
      final population=_personPopulation(p['id'].toString());
      _sheet('${p['name']}', [
        Text(
          '${p['role']} · ${p['birthEstimated']==true?'aprox. ':''}${(day - number(p['bornDay'])) ~/ 360} años',
          style: const TextStyle(color: moss, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          p['id'] == s['leaderId']
              ? 'Dirige esta comunidad.'
              : 'Habitante destacado de ${s['name']}.',
        ),
        Text('Experiencia: ${((p['skill'] as num? ?? 1) * 100).round()}%'),
        for(final c in courses)if(((p['skills'] as Map?)?[c.id] as int? ??0)>0)Text('${c.name}: ${((p['skills'][c.id] as int)/10).round()}%'),
        if(s['id']==controlled&&state['populationState']!=null)OutlinedButton(onPressed:(){Navigator.pop(context);_learning(target:p['id'].toString());},child:const Text('Aprender un oficio')),
        if(population!=null)Text('Cultura: ${_cultureName(population['culture'])}'),
        if(p['birthEstimated']==true)const Text('Su fecha de nacimiento procede de la estimación inicial de su grupo de población.'),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            _details(s);
          },
          child: const Text('Ver comunidad'),
        ),
      ]);
      return;
    }
    final definition = _buildings
        .where((b) => b.id == hit.entity['building'])
        .firstOrNull;
    if (definition == null) return;
    _sheet(definition.name, [
      Text(definition.description, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 12),
      Text('Edificio terminado · ${s['name']}'),
      Text(
        'Hay ${(s['built'] as Map? ?? {})[definition.id] ?? 0} en la comunidad.',
      ),
      const SizedBox(height: 16),
      if (s['id'] == controlled)
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _confirmCommand(
              'Construir ${definition.name}',
              'build',
              target: definition.id,
            );
          },
          child: const Text('Construir otro'),
        ),
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _details(s);
        },
        child: const Text('Ver obras y reservas'),
      ),
    ]);
  }

  void _details(Map<String, dynamic> s) {
    final people = (s['people'] as List? ?? []).where(
      (dynamic p) => p['diedDay'] == null,
    );
    final projects = s['projects'] as List? ?? [];
    final built = s['built'] as Map? ?? {};
    final tech = s['tech'] as List? ?? [];
    _sheet('${s['name']}', [
      Text(
        '${number(s['population'])} habitantes · Salud ${number(s['health'])}% · Ánimo ${number(s['morale'])}%',
      ),
      Text('${_housing(s)} plazas habitables · ${state['origin']=='prehistory'?'Origen prehistórico':'Origen de reconstrucción'}'),
      if (_polity(s['id']) != null)
        Text(
          'Sociedad: ${_polity(s['id'])?['name']}',
          style: const TextStyle(color: gold),
        ),
      Text(
        s['id'] == controlled
            ? 'Diriges esta comunidad.'
            : 'Su gobierno decide de forma autónoma.',
        style: const TextStyle(color: moss),
      ),
      const SizedBox(height: 18),
      const Text(
        'Habitantes destacados',
        style: TextStyle(color: gold, fontSize: 18),
      ),
      ...people.map(
        (dynamic p) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${p['name']}${p['id'] == s['leaderId'] ? ' · dirige la comunidad' : ''}',
          ),
          subtitle: Text(
            '${p['role']} · ${(day - number(p['bornDay'])) ~/ 360} años',
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Obras y edificios',
        style: TextStyle(color: gold, fontSize: 18),
      ),
      ...projects.map(
        (dynamic p) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_buildingName(p['building'])),
          subtitle: Text(
            (p['work'] as Map?)?['paused'] == true
                ? 'Sin trabajadores disponibles'
                : 'En construcción · termina ${date(number(p['finish']))}',
          ),
          trailing: p['work'] is Map && s['id'] == controlled
              ? TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmCommand(
                      'Cancelar ${_buildingName(p['building'])}',
                      'cancel_build',
                      target: p['work']['id'],
                    );
                  },
                  child: const Text('Cancelar'),
                )
              : null,
        ),
      ),
      ...built.entries.map((e) => Text('${_buildingName(e.key)}: ${e.value}')),
      const SizedBox(height: 18),
      const Text('Reservas', style: TextStyle(color: gold, fontSize: 18)),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: (s['resources'] as Map? ?? {}).entries
            .map((e) => Text('${_label(e.key.toString())}: ${number(e.value)}'))
            .toList(),
      ),
      const SizedBox(height: 18),
      const Text('Conocimientos', style: TextStyle(color: gold, fontSize: 18)),
      Text(
        tech.isEmpty
            ? 'Aún no hay conocimientos investigados.'
            : tech.map(_technologyName).join(' · '),
      ),
      const SizedBox(height: 18),
      if (s['id'] != controlled && s['extinct'] != true)
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _confirmCommand(
              'Dirigir esta comunidad',
              'control',
              target: s['id'].toString(),
            );
          },
          child: const Text('Asumir dirección de esta comunidad'),
        ),
      if (s['id'] == controlled)
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            _policies();
          },
          child: const Text('Gobierno y prioridades'),
        ),
    ]);
  }

  String _label(String key) =>
      {
        'food': 'Alimento',
        'water': 'Agua',
        'wood': 'Madera',
        'stone': 'Piedra',
        'metal': 'Metal',
        'medicine': 'Medicina',
        'energy': 'Energía',
        'knowledge': 'Conocimiento',
        'textiles': 'Tejidos',
        'crystal': 'Cristal',
        'fuel': 'Combustible',
        'tools': 'Herramientas',
      }[key] ??
      key;
  Command _queryCommand(
    String action, {
    String? target,
    String? choice,
  }) => Command(
    id: 'preview-${session.snapshot?.generation}-${session.snapshot?.revision}',
    action: action,
    actorId: controlled.isEmpty ? null : controlled,
    issuedDay: day,
    target: target,
    choice: choice,
  );
  String _costText(CommandPreview preview) => preview.costs.isEmpty
      ? 'Sin gasto de materiales'
      : preview.costs.entries
            .map(
              (e) =>
                  '${_label(e.key)} ${e.value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '')}',
            )
            .join(' · ');
  Future<void> _confirmCommand(
    String title,
    String action, {
    String? target,
    String? choice,
  }) async {
    if (session.snapshot == null || busy || advancing) return;
    timer?.cancel();
    timer = null;
    final revision = session.snapshot!.revision;
    final preview = _sim().preview(
      _queryCommand(action, target: target, choice: choice),
    );
    await _sheet(title, [
      Text(preview.outcome, style: const TextStyle(height: 1.5)),
      const SizedBox(height: 14),
      Text(_costText(preview), style: const TextStyle(color: gold)),
      if (preview.workers > 0)
        Text('${preview.workers} trabajadores comprometidos'),
      Text(
        preview.durationDays == null
            ? 'Duración según las condiciones del mundo'
            : preview.durationDays == 0
            ? 'Efecto inmediato'
            : 'Duración: ${preview.durationDays} días',
      ),
      if (!preview.allowed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(preview.reason, style: const TextStyle(color: earth)),
        ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: preview.allowed
            ? () async {
                Navigator.pop(context);
                if (session.snapshot?.revision != revision) {
                  _message(
                    'La situación cambió. Revisa la orden de nuevo antes de confirmar.',
                  );
                  return;
                }
                await _command(action, target: target, choice: choice);
              }
            : null,
        child: const Text('Confirmar orden'),
      ),
    ]);
  }

  int _housing(Map<String,dynamic> s) {
    final built=s['built'] as Map? ?? {};
    final known=Set<String>.from(s['tech']??[]);
    if(_catalog==null) {
      return number(built['house'])*(known.contains('masonry')?22:18)+number(built['habitat'])*50+number(s['housingModifier']);
    }
    return _catalog!.buildings.fold<int>(number(s['housingModifier']),
      (n,b)=>n+number(built[b.id])*b.housingCapacity)+
      (_catalog!.provides(known,'masonry')?number(built['house'])*4:0);
  }

  void _build({bool showLocked=false}) {
    final sim = _sim();
    final recommended=state['origin']=='prehistory'&&society!=null&&
        _housing(society!)<=number(society!['population'])?'shelter':'farm';
    final entries = _buildings
        .map((b) => (b, sim.preview(_queryCommand('build', target: b.id))))
        .toList();
    entries.sort(
      (a, b) {
        final availability=(a.$2.allowed?0:1).compareTo(b.$2.allowed?0:1);
        if(availability!=0)return availability;
        final suggestion=(a.$1.id==recommended?0:1).compareTo(b.$1.id==recommended?0:1);
        if(suggestion!=0)return suggestion;
        final duration=a.$1.days.compareTo(b.$1.days);
        return duration==0?a.$1.id.compareTo(b.$1.id):duration;
      },
    );
    _sheet('Construir con propósito', [
      const Text(
        'Elige una mejora para revisar su coste antes de confirmar. Los edificios aparecen al terminar el trabajo.',
        style: TextStyle(color: earth),
      ),
      const SizedBox(height: 12),
      if(entries.every((e)=>!e.$2.allowed))const Text('Ahora falta algún material, conocimiento o personal. Consulta los requisitos para elegir el siguiente paso.'),
      ...entries.where((e)=>showLocked||e.$2.allowed).map((entry) {
        final b = entry.$1;
        final p = entry.$2;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(b.name),
          subtitle: Text(
            '${b.description}\n${_costText(p)} · ${p.durationDays ?? b.days} días${p.allowed ? '' : '\n${p.reason}'}',
          ),
          trailing: Icon(
            p.allowed ? Icons.chevron_right : Icons.lock_outline,
            color: p.allowed ? gold : earth,
          ),
          onTap: () {
            Navigator.pop(context);
            _confirmCommand(b.name, 'build', target: b.id);
          },
        );
      }),
      if(!showLocked&&entries.any((e)=>!e.$2.allowed))TextButton(
        onPressed:(){Navigator.pop(context);_build(showLocked:true);},
        child:Text('Ver construcciones y requisitos (${entries.where((e)=>!e.$2.allowed).length} bloqueadas)')),
    ]);
  }

  void _learning({String target='resident'}) {
    final s=society;if(s==null)return;
    final sim=_sim();final people=(s['people'] as List).where((p)=>p['diedDay']==null).toList();
    final learner=people.where((p)=>p['id']==target).firstOrNull;
    _sheet('Formar aprendices',[
      Text(target=='resident'?'Destacar un residente adulto de la población. No añade habitantes.':'Aprendiz: ${learner?['name']??target}'),
      const Text('El maestro y el aprendiz reservan tiempo de trabajo. Sin maestro se necesitan escuela y manuales adecuados.'),
      const SizedBox(height:12),
      for(final c in courses)Builder(builder:(context){
        final preview=sim.preview(_queryCommand('train',target:target,choice:c.id));
        return ListTile(title:Text(c.name),subtitle:Text(preview.allowed?'${c.description}\n${_costText(preview)} · ${preview.durationDays} días':preview.reason),
          trailing:preview.allowed?const Icon(Icons.chevron_right):const Icon(Icons.lock_outline),
          onTap:preview.allowed?(){Navigator.pop(context);_confirmCommand('Aprender ${c.name.toLowerCase()}','train',target:target,choice:c.id);}:null);
      }),
      if(target=='resident')ExpansionTile(title:const Text('Elegir un habitante destacado'),children:[
        for(final p in people.where((p)=>day-number(p['bornDay'])>=18*360&&day-number(p['bornDay'])<65*360))ListTile(title:Text(p['name'].toString()),subtitle:Text(p['role'].toString()),onTap:(){Navigator.pop(context);_learning(target:p['id'].toString());}),
      ]),
      if(((s['lessons'] as List?)??[]).isNotEmpty)const Text('Formación en curso',style:TextStyle(color:gold)),
      for(final l in ((s['lessons'] as List?)??[]))ListTile(
        title:Text('${people.where((p)=>p['id']==l['learner']).firstOrNull?['name']??'Aprendiz'} · ${courses.where((c)=>c.id==l['course']).firstOrNull?.name??l['course']}'),
        subtitle:Text('${((1-number(l['work']['remaining'])/number(l['work']['totalWork']))*100).floor()}% · ${l['work']['paused']==true?'En espera de personal':'Trabajando'}'),
        trailing:IconButton(tooltip:'Detener formación',icon:const Icon(Icons.close),onPressed:(){Navigator.pop(context);_confirmCommand('Detener aprendizaje','cancel_train',target:l['id']);})),
    ]);
  }

  void _research({bool showLocked=false}) {
    final sim = _sim();
    final entries = _technologies
        .map((t) => (t, sim.preview(_queryCommand('research', target: t.id))))
        .toList();
    entries.sort(
      (a, b) => (a.$2.allowed ? 0 : 1).compareTo(b.$2.allowed ? 0 : 1),
    );
    _sheet('Conocimiento heredado', [
      const Text(
        'Cada conocimiento requiere reservas y conocimientos anteriores. Consulta sus efectos antes de adoptarlo.',
        style: TextStyle(color: earth),
      ),
      if(entries.every((e)=>!e.$2.allowed))const Text('Todavía necesitas conocimientos o cumplir algún requisito. El círculo de memoria y el trabajo diario permiten aprender.'),
      ...entries.where((e)=>showLocked||e.$2.allowed).map((entry) {
        final t = entry.$1;
        final p = entry.$2;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.name),
          subtitle: Text(
            '${t.effect} · ${_costText(p)}\n${p.allowed ? 'Disponible' : p.reason}',
          ),
          trailing: Icon(p.allowed ? Icons.chevron_right : Icons.lock_outline),
          onTap: () {
            Navigator.pop(context);
            _confirmCommand(t.name, 'research', target: t.id);
          },
        );
      }),
      if(!showLocked&&entries.any((e)=>!e.$2.allowed))TextButton(
        onPressed:(){Navigator.pop(context);_research(showLocked:true);},
        child:const Text('Ver conocimientos y requisitos')),
    ]);
  }

  void _stories({bool showAll=false}) {
    if (selected != controlled) {
      _message(
        'Asume la dirección desde la ficha antes de resolver sus decisiones.',
      );
      return;
    }
    final all = _sim().eligibleEvents(selected);
    final events = all.take(showAll?1000:3).toList();
    _sheet('Decisiones de la comunidad', [
      if (events.isEmpty)
        const Text(
          'No hay decisiones compatibles ahora. Explora, construye y deja pasar el tiempo.',
          style: TextStyle(color: earth),
        ),
      ...events.map(
        (e) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e['title'] ?? e['id']}',
                  style: const TextStyle(
                    fontSize: 17,
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${e['body'] ?? e['text'] ?? e['description'] ?? ''}',
                  style: const TextStyle(color: earth),
                ),
                const SizedBox(height: 12),
                ...(e['options'] as List? ?? []).map(
                  (dynamic o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _confirmCommand(
                          '${o['label'] ?? o['text'] ?? o['id']}',
                          'resolve_event',
                          target: e['id'],
                          choice: o['id'],
                        );
                      },
                      child: Text('${o['label'] ?? o['text'] ?? o['id']}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if(!showAll&&all.length>3)TextButton(
        onPressed:(){Navigator.pop(context);_stories(showAll:true);},
        child:Text('Ver las ${all.length} oportunidades disponibles')),
    ]);
  }

  void _facility() => _sheet('La instalación antigua', [
    const Text(
      'Una expedición encontró una estructura bajo las ruinas. Revisa el coste y las consecuencias de cada respuesta.',
      style: TextStyle(color: earth, height: 1.5),
    ),
    const SizedBox(height: 16),
    ...{
      'seal': ('Sellar', 'Aislar el riesgo y conservar el secreto.'),
      'salvage': (
        'Desmontar',
        'Recuperar materiales; perder el conocimiento interior.',
      ),
      'study': ('Estudiar', 'Invertir en ciencia. Energía, accidente o señal.'),
      'share': ('Ofrecer acceso', 'Compartir el hallazgo con otra sociedad.'),
    }.entries.map(
      (e) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(e.value.$1),
        subtitle: Text(e.value.$2),
        onTap: () {
          Navigator.pop(context);
          _confirmCommand(e.value.$1, 'facility', choice: e.key);
        },
      ),
    ),
  ]);
  String? _ownerOf(String actor) {
    final cities = (state['entities'] as Map?)?['settlements'] as List? ?? [];
    return cities.where((c) => c['actorId'] == actor).firstOrNull?['societyId']
        as String?;
  }

  Map? _polity(String actor) {
    final id = _ownerOf(actor);
    return ((state['entities'] as Map?)?['societies'] as List? ?? [])
            .where((s) => s['id'] == id)
            .firstOrNull
        as Map?;
  }

  void _politicalSheet() {
    final owner = _polity(controlled);
    if (owner == null) return;
    final cities = societies
        .where((s) => _ownerOf(s['id']) == owner['id'])
        .toList();
    final graphCities = (state['entities'] as Map)['settlements'] as List;
    final capitalActor = graphCities
        .where((c) => c['id'] == owner['capitalId'])
        .firstOrNull?['actorId'];
    _sheet('${owner['name']}', [
      Text(
        '${cities.length} asentamientos · ${cities.fold<int>(0, (n, c) => n + number(c['population']))} habitantes',
        style: const TextStyle(color: moss, fontSize: 18),
      ),
      const Text(
        'Cada asentamiento conserva sus reservas, obras y habitantes. La capital representa a la sociedad.',
      ),
      ...cities.map(
        (c) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c['name']}${c['id'] == capitalActor ? ' · Capital' : ''}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  '${number(c['population'])} habitantes · Alimento ${number((c['resources'] as Map)['food'])}',
                ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmCommand(
                          'Dirigir ${c['name']}',
                          'control',
                          target: c['id'],
                        );
                      },
                      child: const Text('Dirigir asentamiento'),
                    ),
                    if (c['id'] != capitalActor)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmCommand(
                            'Trasladar capital',
                            'capital',
                            target: c['id'],
                          );
                        },
                        child: const Text('Capital aquí'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  void _diplomacy() => _sheet('Más allá del barrio', [
    ...societies.where((s) => s['id'] != selected).map((s) {
      final own = _ownerOf(controlled), other = _ownerOf(s['id']);
      final internal = own != null && own == other;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s['name']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              Text(
                '${number(s['population'])} habitantes${other == null ? '' : ' · Sociedad ${_polity(s['id'])?['name']}'}',
                style: const TextStyle(color: earth),
              ),
              if (!internal)
                Text(
                  'Confianza: ${number((society?['relations'] as Map?)?[s['id']])} / ${number((s['relations'] as Map?)?[controlled])}',
                ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmCommand(
                        'Abrir comercio',
                        'trade',
                        target: s['id'],
                      );
                    },
                    child: const Text('Abrir comercio'),
                  ),
                  if (!internal)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmCommand(
                          'Negociar',
                          'diplomacy',
                          target: s['id'],
                        );
                      },
                      child: const Text('Negociar'),
                    ),
                  if (own != null && other != null && !internal)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmCommand(
                          'Proponer unión',
                          'federate',
                          target: s['id'],
                        );
                      },
                      child: const Text('Proponer unión'),
                    ),
                  if (internal)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Misma sociedad',
                        style: TextStyle(color: moss),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }),
  ]);
  void _routes() => _sheet('Rutas y caravanas', [
    if ((state['routes'] as List? ?? []).isEmpty)
      const Text('Aún no hay rutas. Negocia y abre comercio desde Diplomacia.'),
    ...((state['routes'] as List? ?? []).map((dynamic r) {
      final from = societies.where((s) => s['id'] == r['from']).firstOrNull;
      final to = societies.where((s) => s['id'] == r['to']).firstOrNull;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${from?['name'] ?? 'Origen'} → ${to?['name'] ?? 'Destino'}',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                r['blocked'] == true
                    ? 'Detenida: revisa personal, acceso o relaciones'
                    : r['returning'] == true
                    ? 'De regreso al origen'
                    : 'Viajando al destino',
              ),
              Text(
                'Alimento a bordo: ${r['cargo']} · Metal a bordo: ${number(r['metalMillis']) / 1000}',
              ),
              if (r['transportRules'] == 2 &&
                  (r['from'] == controlled ||
                      _ownerOf(r['from']) == _ownerOf(controlled)))
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmCommand(
                      'Cerrar ruta',
                      'close_route',
                      target: r['id'],
                    );
                  },
                  child: const Text('Ordenar regreso y cierre'),
                ),
            ],
          ),
        ),
      );
    })),
  ]);
  void _policies() {
    _sheet('Gobernar a largo plazo', [
      const Text(
        'Las prioridades guían las decisiones autónomas. Cambiar de sociedad conserva sus recursos y sus compromisos.',
        style: TextStyle(color: earth),
      ),
      const SizedBox(height: 14),
      ...{
        'balanced': 'Equilibrio',
        'food': 'Reservas y alimentación',
        'science': 'Investigación',
        'expansion': 'Expansión',
        'trade': 'Cooperación comercial',
        'defense': 'Protección',
        'isolation': 'Aislamiento',
      }.entries.map(
        (e) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.value),
          onTap: () {
            Navigator.pop(context);
            _confirmCommand(e.value, 'policy', target: e.key);
          },
        ),
      ),
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _confirmCommand('Delegar y observar', 'delegate');
        },
        child: const Text('Delegar todas y observar'),
      ),
    ]);
  }

  void _years() => _sheet('Observar una era', [
    StatefulBuilder(
      builder: (context, change) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: stopCrisis,
        onChanged: (v) async {
          await _changeSettings(stop: v);
          if (context.mounted) change(() {});
        },
        title: const Text('Detener ante crisis'),
        subtitle: Text(
          stopCrisis
              ? 'Las decisiones importantes interrumpen el salto.'
              : 'Los dirigentes aplican sus políticas y registran sus decisiones.',
        ),
      ),
    ),
    const SizedBox(height: 12),
    const Text(
      'Se guardará un punto anterior. El avance usa las mismas reglas diarias. Pausar conserva los días ya confirmados.',
      style: TextStyle(color: earth, height: 1.5),
    ),
    const SizedBox(height: 18),
    ...[1, 10, 100].map(
      (years) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _jump(years);
          },
          child: Text('Avanzar $years ${years == 1 ? 'año' : 'años'}'),
        ),
      ),
    ),
    if (jumpTarget != null && jumpTarget! > day)
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _jump(0, resume: true);
        },
        child: Text('Continuar hasta ${date(jumpTarget!)}'),
      ),
  ]);
  void _chronicle() {
    final entries = (state['chronicle'] as List? ?? []).reversed
        .take(180)
        .toList();
    _sheet('La memoria del mundo', [
      Text(
        '${entries.length} noticias recientes · Toca una noticia para localizar su comunidad.',
        style: const TextStyle(color: earth, fontSize: 11),
      ),
      const SizedBox(height: 12),
      ...entries.map((dynamic e) {
        final m = e is Map ? e : {};
        final id = (m['societyId'] ?? m['location'] ?? m['society'])
            ?.toString();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${m['title'] ?? m['text'] ?? m['message'] ?? e}',
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            '${date(number(m['day']))}\n${m['text'] ?? m['description'] ?? m['detail'] ?? ''}${m['cause'] == null ? '' : ' · Causa: ${m['cause']}'}',
            style: const TextStyle(fontSize: 10, color: earth),
          ),
          onTap: () {
            if (id != null) {
              setState(() => selected = id);
              game.locate(id);
            }
            Navigator.pop(context);
          },
        );
      }),
      if (entries.isEmpty)
        const Text('La historia empieza con tus primeras decisiones.'),
    ]);
  }

  Future<void> _changeSettings({
    bool? motion,
    bool? audio,
    bool? haptic,
    bool? stop,
  }) async {
    try {
      await session.updateSettings(
        reduceMotion: motion,
        sound: audio,
        vibration: haptic,
        stopCrisis: stop,
      );
    } catch (e) {
      _message('No se pudo guardar el ajuste: $e');
    }
  }

  Future<void> _upgradeRules() async {
    try {
      final result = await session.upgradeRules(
        confirm: () async =>
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Actualizar reglas de esta partida'),
                content: const Text(
                  'Se conservará una copia exacta del archivo original. Las reservas se expresarán en milésimas y se separarán las sociedades de sus asentamientos. Reservas y cargas se redondearán a milésimas. Obras y caravanas pueden detenerse si falta personal. Las edades de la población común se estimarán; se conservan las fechas conocidas y no se inventarán parentescos. Puedes continuar con las reglas antiguas.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Conservar reglas actuales'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Copiar y actualizar'),
                  ),
                ],
              ),
            ) ??
            false,
      );
      if (result.accepted) {
        _focusHome();
        _message('Reglas actualizadas; se conserva la copia original.');
      }
    } catch (e) {
      _message('La partida se conserva con sus reglas actuales. $e');
    }
  }

  void _menu() {
    if (busy || advancing) {
      _message('Pausa el salto antes de cambiar de partida o configuración.');
      return;
    }
    _sheet('Tu mundo, tus reglas', [
      ListTile(
        title: const Text('Guardar ahora'),
        onTap: () async {
          Navigator.pop(context);
          try {
            await _save();
            _message('Partida guardada.');
          } catch (error) {
            _message('No se pudo guardar: $error');
          }
        },
      ),
      if (state['entities'] == null ||
          state['rulesVersion'] != WorldState.currentRules)
        ListTile(
          title: const Text('Actualizar reglas de la partida'),
          subtitle: const Text(
            'Conservar copia y habilitar sociedades y materiales nuevos',
          ),
          onTap: () {
            Navigator.pop(context);
            _upgradeRules();
          },
        ),
      if ((state['ruleChanges'] as List? ?? []).isNotEmpty)
        ListTile(
          title: const Text('Restaurar reglas anteriores'),
          subtitle: const Text('Carga la copia anterior a la actualización'),
          onTap: () async {
            Navigator.pop(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Volver a la copia anterior'),
                content: const Text(
                  'Se recuperará la fecha anterior a actualizar las reglas. El guardado actual pasará a la copia de recuperación.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Restaurar copia'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              try {
                await session.restoreRulesBackup();
                _focusHome();
              } catch (e) {
                _message('No se pudo restaurar: $e');
              }
            }
          },
        ),
      ListTile(
        title: const Text('Paquetes de contenido'),
        onTap: () {
          Navigator.pop(context);
          _packages();
        },
      ),
      ListTile(
        title: const Text('Archivo de mundos'),
        onTap: () {
          Navigator.pop(context);
          _archive();
        },
      ),
      ListTile(
        title: const Text('Restaurar punto anterior al salto'),
        subtitle: const Text('Reemplaza este mundo por su rama anterior.'),
        onTap: () async {
          Navigator.pop(context);
          try {
            final result = await session.restorePreviousBranch(
              acceptLegacy: _acceptLegacy,
            );
            if (!result.found) {
              _message('No hay un punto anterior.');
            } else if (result.accepted && mounted) {
              _focusHome();
            }
          } catch (e) {
            _message('No se pudo restaurar: $e');
          }
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Reducir movimiento'),
        value: reduceMotion,
        onChanged: (v) {
          Navigator.pop(context);
          _changeSettings(motion: v);
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sonido de decisiones'),
        value: sound,
        onChanged: (v) {
          Navigator.pop(context);
          _changeSettings(audio: v);
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Respuesta táctil'),
        value: vibration,
        onChanged: (v) {
          Navigator.pop(context);
          _changeSettings(haptic: v);
        },
      ),
      ListTile(
        title: const Text('Velocidad automática'),
        subtitle: Text('$speed×'),
        onTap: () {
          setState(
            () => speed = speed == 1
                ? 2
                : speed == 2
                ? 4
                : 1,
          );
          if (timer != null) {
            timer!.cancel();
            timer = null;
            _play();
          }
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('Cómo empezar'),
        onTap: () {
          Navigator.pop(context);
          _sheet('Tus primeras decisiones', [
            const Text(
              'Barrio: tu comunidad y sus obras. Abre Comunidad para conocer a sus habitantes.\n\nConstruir: elige una mejora, revisa coste y duración, y confirma. Avanzar permite observar cómo termina.\n\nMás acciones: investiga, explora, negocia o define prioridades. Delegar deja las decisiones al gobierno autónomo.\n\nMundo: observa otras comunidades sin cambiar quién diriges.\n\nHistoria: consulta consecuencias y localiza sus protagonistas.\n\nEl tiempo empieza en pausa y no avanza al cerrar. El calendario tiene 12 meses de 30 días.',
              style: TextStyle(height: 1.8, color: earth),
            ),
          ]);
        },
      ),
      ListTile(
        title: const Text('Crear otro mundo'),
        onTap: () {
          Navigator.pop(context);
          _newWorld();
        },
      ),
      ListTile(
        title: const Text('Volver al inicio'),
        onTap: () async {
          Navigator.pop(context);
          timer?.cancel();
          timer = null;
          try {
            await session.returnToWelcome();
          } catch (e) {
            _message('No se pudo cerrar la partida: $e');
          }
        },
      ),
    ]);
  }

  void _packages() => _sheet('Contenido versionado', [
    Text(
      'Base: barrio.core 1.0.0\nSHA-256: ${coreHash ?? "cargando"}',
      style: const TextStyle(fontSize: 10, color: earth),
    ),
    const SizedBox(height: 12),
    const Text(
      'Importar agrega contenido para los próximos mundos. La historia actual conserva su conjunto exacto; no se migra automáticamente.',
      style: TextStyle(color: earth, height: 1.5),
    ),
    ...availablePackSources.map((source) {
      final p = ContentPack.parse(source, base: basePack);
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${p.id} ${p.version}'),
        subtitle: Text(p.hash, style: const TextStyle(fontSize: 9)),
      );
    }),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: () async {
        Navigator.pop(context);
        final input = TextEditingController();
        final accept = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Importar paquete'),
            content: TextField(
              controller: input,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'JSON declarativo del paquete',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Validar'),
              ),
            ],
          ),
        );
        if (accept == true) {
          try {
            await session.importPackage(input.text);
            _message('Paquete validado. Se aplicará al crear un nuevo mundo.');
          } catch (e) {
            _message('Paquete rechazado: $e');
          }
        }
      },
      child: const Text('Importar paquete JSON'),
    ),
  ]);
  void _archive({int? chosenSlot}) {
    final selectedSlot = chosenSlot ?? slot;
    final duplicateSlot = selectedSlot == slot ? (slot + 1) % 3 : selectedSlot;
    _sheet('Archivo de mundos', [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Espacio elegido: '),
          DropdownButton<int>(
            value: selectedSlot,
            items: List.generate(
              3,
              (i) => DropdownMenuItem(value: i, child: Text('${i + 1}')),
            ),
            onChanged: (v) {
              Navigator.pop(context);
              _archive(chosenSlot: v);
            },
          ),
        ],
      ),
      FilledButton(
        onPressed: () {
          Navigator.pop(context);
          _load(fromSlot: selectedSlot);
        },
        child: const Text('Cargar este espacio'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _load(backup: true, fromSlot: selectedSlot);
        },
        child: const Text('Recuperar copia anterior'),
      ),
      const SizedBox(height: 8),
      if (session.snapshot != null) ...[
        OutlinedButton(
          onPressed: () async {
            final destination = duplicateSlot;
            try {
              await session.duplicateTo(destination);
            } catch (e) {
              _message('No se pudo duplicar: $e');
              return;
            }
            if (mounted) {
              Navigator.pop(context);
              _message('Mundo duplicado en espacio ${destination + 1}.');
            }
          },
          child: Text('Duplicar en espacio ${duplicateSlot + 1}'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            _export();
          },
          child: const Text('Exportar partida (JSON)'),
        ),
      ],
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _importDialog(destinationSlot: selectedSlot);
        },
        child: const Text('Importar partida (JSON)'),
      ),
      if (kIsWeb)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'En esta previsualización el almacenamiento es temporal. Android conserva archivos locales al cerrar.',
            style: TextStyle(color: earth, fontSize: 11),
          ),
        ),
    ]);
  }

  Future<void> _export() async {
    if (advancing || busy) {
      _message('Espera a que se confirme el avance actual.');
      return;
    }
    late final String data;
    try {
      data = await session.exportCurrent();
    } catch (e) {
      _message('No se pudo exportar: $e');
      return;
    }
    if (documents.supported) {
      try {
        final uri = await documents.exportDocument(
          text: data,
          suggestedName: 'barrio-cero-$slot-dia-$day.json',
        );
        if (uri != null) _message('Partida exportada al documento elegido.');
      } catch (e) {
        _message('No se pudo exportar: $e');
      }
      return;
    }
    _sheet('Exportar historia', [
      const Text(
        'Copia el JSON y guárdalo en un archivo .json. Permite trasladar el mundo sin cuentas ni conexión.',
        style: TextStyle(color: earth),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: data));
          _message('Partida copiada al portapapeles.');
        },
        child: const Text('Copiar partida completa'),
      ),
      const SizedBox(height: 12),
      SelectableText(
        '${data.substring(0, data.length.clamp(0, 800).toInt())}…',
        style: const TextStyle(fontSize: 10),
      ),
    ]);
  }

  Future<void> _importDialog({int? destinationSlot}) async {
    if (advancing || busy) {
      _message('Pausa el avance antes de importar.');
      return;
    }
    timer?.cancel();
    timer = null;
    if (documents.supported) {
      try {
        final raw = await documents.importDocument();
        if (raw != null) {
          if (await _import(raw, destinationSlot: destinationSlot)) {
            _message('Historia importada.');
          }
        }
      } catch (e) {
        _message('Importación rechazada; la partida actual se conserva. $e');
      }
      return;
    }
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar historia'),
        content: TextField(
          controller: input,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Pega el contenido del archivo JSON',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Validar e importar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        if (await _import(input.text, destinationSlot: destinationSlot)) {
          _message('Historia importada.');
        }
      } catch (e) {
        _message('Importación rechazada; la partida actual se conserva. $e');
      }
    }
  }
}
