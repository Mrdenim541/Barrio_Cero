import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'art_assets.dart';
import 'planet_camera.dart';
import 'planet_terrain.dart';
import 'settlement_scene.dart';
import 'settlement_activity.dart';
import 'local_work.dart';

const earth = Color(0xffcaba91);
const ink = Color(0xff103239);
const gold = Color(0xffefc375);
const moss = Color(0xffa6bf83);

/// Cities and their entities share a regional coordinate frame. LOD changes
/// representation only; there is no selected-city scene or camera reset.
class WorldGame extends FlameGame {
  final planetCamera = PlanetCamera();
  final terrainCache = PlanetTerrain();
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> _societies = [];
  final Map<String, SettlementScene> _scenes = {};
  final Map<String, Map<String, SiteWork>> _siteWork = {};
  final Map<String, LocalWorkday> _workdays = {};
  final Map<String, String> _workdayKeys = {};
  bool playing = false;
  double activitySeconds = 0;
  double dayDuration = 1.2, _dayArrived = 0;
  double _workPulseUntil = 0;
  String? selected, localSelected;
  String? followedIndividualId;
  String _mode = 'Mundo';
  String get mode => _mode;
  String filter = 'Territorios';
  Offset get pan => planetCamera.pan;
  set pan(Offset value) => planetCamera.pan = value;
  double get zoom => planetCamera.zoom;
  double get unit => planetCamera.unit;
  double get phase => reduceMotion ? 0 : _visualTime;
  double _visualTime = 0;
  Object? _generation;
  Set<String> _knownSites = {};
  final Map<String, double> recentSites = {};
  bool reduceMotion = false, mini = true;
  ui.Image? people, buildings;
  AtlasLayout? peopleLayout, buildingLayout;
  int lastSettlementsDrawn = 0,
      lastSitesDrawn = 0,
      lastPeopleDrawn = 0,
      lastTerrainBlocksDrawn = 0;
  String? _pendingFitId;
  final List<ui.FrameTiming> _frameWindow = [];
  String? _frameKey;
  final void Function(String) onSelect;
  final void Function(LocalSelection)? onLocalSelect;
  final void Function()? onViewChanged;
  WorldGame(this.onSelect, {this.onLocalSelect, this.onViewChanged});

  List<Map<String, dynamic>> get societies => _societies;
  int number(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
  int get extent => planetCamera.extent;
  Offset get center => planetCamera.center;
  Offset toWorld(Offset p) => planetCamera.toWorld(p);
  Offset toScreen(Offset p) => planetCamera.toScreen(p);
  Offset _origin(Map<String, dynamic> s) =>
      Offset(number(s['x']).toDouble(), number(s['y']).toDouble());
  Rect settlementBounds(Map<String, dynamic> s) =>
      PlanetCamera.localRectToWorld(_origin(s), _scenes[s['id']]!.bounds);
  Offset position(Map<String, dynamic> s) => PlanetCamera.localRectToWorld(
    _origin(s),
    _scenes[s['id']]!.siteBounds,
  ).center;
  Rect entityWorldBounds(String actorId, LocalSelection entity) {
    final s = societies.firstWhere((s) => s['id'] == actorId);
    return PlanetCamera.localRectToWorld(_origin(s), _displayBounds(entity));
  }

  Rect _displayBounds(LocalSelection entity) {
    final previous = entity.entity['_previousCell'];
    if (entity.kind != 'person' ||
        previous is! int ||
        !playing ||
        reduceMotion) {
      return entity.bounds;
    }
    final before = Rect.fromLTWH(
      (previous % 32 + .5) * 32 - 16,
      (previous ~/ 32 + .5) * 32 - 36,
      32,
      48,
    );
    return Rect.lerp(
      before,
      entity.bounds,
      ((_visualTime - _dayArrived) / dayDuration).clamp(0.0, 1.0),
    )!;
  }

  Offset entityScreenPosition(String actorId, LocalSelection entity) =>
      toScreen(entityWorldBounds(actorId, entity).center);

  void _updateLevel() {
    final old = _mode;
    final density = planetCamera.pixelsPerMicrocell;
    if (_mode == 'Asentamiento' && density < 3.5) _mode = 'Región';
    if (_mode != 'Asentamiento' && density >= 4) _mode = 'Asentamiento';
    if (_mode != 'Asentamiento') {
      if (_mode == 'Mundo' && zoom > 2.8) _mode = 'Región';
      if (_mode == 'Región' && zoom < 2.2) _mode = 'Mundo';
    }
    if (_mode != old) onViewChanged?.call();
  }

  void zoomAt(double value, Offset focus) {
    planetCamera.zoomAt(value, focus);
    _updateLevel();
  }

  void fitWorld() {
    stopFollowing();
    planetCamera.fitWorld();
    _updateLevel();
  }

  void locate(String id) {
    final s = societies.where((s) => s['id'] == id).firstOrNull;
    if (s == null) return;
    selected = id;
    planetCamera.centerOn(position(s));
  }

  void focusSettlement(String id) {
    stopFollowing();
    final s = societies.where((s) => s['id'] == id).firstOrNull;
    if (s == null) return;
    selected = id;
    if (planetCamera.viewport.isEmpty) {
      _pendingFitId = id;
      return;
    }
    planetCamera.fitBounds(settlementBounds(s));
    _updateLevel();
  }

  void focusRegion(String? id) {
    stopFollowing();
    zoomAt(4, center);
    if (id != null) locate(id);
  }

  void locateCell(int cell) {
    stopFollowing();
    zoomAt(4, center);
    planetCamera.centerOn(Offset(cell % extent + .5, cell ~/ extent + .5));
  }

  void stopFollowing() => followedIndividualId = null;

  /// Resolve by identity on every confirmed snapshot, including relocation.
  bool followIndividual(String id, {bool focus = true, bool notify = true}) {
    for (final s in societies) {
      final entity = _scenes[s['id']]?.entities
          .where((e) => e.kind == 'person' && e.id == id)
          .firstOrNull;
      if (entity == null) continue;
      followedIndividualId = id;
      selected = s['id'];
      localSelected = id;
      if (planetCamera.viewport.isEmpty) return true;
      if (focus) {
        planetCamera.zoomAt(
          24 / planetCamera.pixelsPerMicrocell * zoom,
          center,
        );
      }
      planetCamera.centerOn(entityWorldBounds(selected!, entity).center);
      if (notify) {
        _updateLevel();
      } else {
        _mode = 'Asentamiento';
      }
      return true;
    }
    stopFollowing();
    return false;
  }

  void present(Map<String, dynamic> snapshot, {required Object? generation}) {
    if (_generation == generation && data['day'] != snapshot['day']) {
      _workPulseUntil = _visualTime + 1.4;
      _dayArrived = _visualTime;
    }
    final sites = <String>{
      for (final s in snapshot['societies'] as List? ?? [])
        for (final b in s['sites'] as List? ?? []) '${s['id']}:${b['id']}',
    };
    if (_generation == generation && data.isNotEmpty) {
      for (final id in sites.difference(_knownSites)) {
        recentSites[id] = _visualTime + 3;
      }
    } else {
      recentSites.clear();
      _workdays.clear();
      _workdayKeys.clear();
      activitySeconds = 0;
      localSelected = null;
      _pendingFitId = null;
      stopFollowing();
      planetCamera.fitWorld();
      _mode = 'Mundo';
    }
    _generation = generation;
    _knownSites = sites;
    data = snapshot;
    planetCamera.extent = number(snapshot['size'], 96);
    _societies = (snapshot['societies'] as List? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    _scenes.clear();
    _siteWork.clear();
    for (final s in societies) {
      _scenes[s['id']] = SettlementScene(s);
      final activity = SettlementActivity.fromWorld(snapshot, s);
      _siteWork[s['id']] = {
        for (final work in activity.sites) work.siteId: work,
      };
      final key = jsonEncode([
        snapshot['day'],
        s['adults'],
        s['extinct'],
        s['sites'],
        s['people'],
        s['lastProduction'],
      ]);
      if (_workdayKeys[s['id']] != key) {
        _workdayKeys[s['id']] = key;
        _workdays[s['id']] = LocalWorkday.read(snapshot, s);
      }
    }
    terrainCache.sync(snapshot);
    final id = followedIndividualId;
    if (id != null) followIndividual(id, focus: false);
  }

  @override
  Color backgroundColor() => const Color(0xff174554);
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final previousMode = _mode;
    planetCamera.resize(Size(size.x, size.y));
    final followed = followedIndividualId;
    if (followed != null) {
      followIndividual(followed, focus: true, notify: false);
    }
    final id = _pendingFitId;
    if (id != null && _scenes.containsKey(id)) {
      _pendingFitId = null;
      planetCamera.fitBounds(
        settlementBounds(societies.firstWhere((s) => s['id'] == id)),
      );
      _mode = 'Asentamiento';
    }
    if (_mode != previousMode) {
      // A restored target may arrive before the viewport. Update Flutter's
      // view label after layout, never with setState during game resize.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onViewChanged?.call(),
      );
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    final manifest =
        jsonDecode(await rootBundle.loadString('assets/art/atlas.json')) as Map;
    peopleLayout = AtlasLayout.fromJson(
      Map<String, dynamic>.from(manifest['characters']),
    );
    buildingLayout = AtlasLayout.fromJson(
      Map<String, dynamic>.from(manifest['buildings']),
    );
    Future<ui.Image> load(AtlasLayout atlas) => loadArtPixels(
      rootBundle,
      'assets/art/${atlas.pixels}',
      atlas.pixelWidth,
      atlas.pixelHeight,
    );
    people = await load(peopleLayout!);
    buildings = await load(buildingLayout!);
    final scenery = AtlasLayout.fromJson(
      Map<String, dynamic>.from(manifest['landscape']),
    );
    terrainCache.attachLandscape(await load(scenery), scenery);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    if (playing && !reduceMotion) activitySeconds += dt;
    if (playing && followedIndividualId != null && selected != null) {
      final person = _scenes[selected]?.entities
          .where((e) => e.kind == 'person' && e.id == followedIndividualId)
          .firstOrNull;
      if (person != null) {
        planetCamera.centerOn(entityWorldBounds(selected!, person).center);
      }
    }
    recentSites.removeWhere((_, expiry) => expiry <= _visualTime);
  }

  @override
  void onRemove() {
    if (kProfileMode) {
      WidgetsBinding.instance.removeTimingsCallback(_frameTimings);
    }
    terrainCache.clear();
    super.onRemove();
  }

  @override
  void onMount() {
    super.onMount();
    if (kProfileMode) {
      WidgetsBinding.instance.addTimingsCallback(_frameTimings);
    }
  }

  /// Local profile diagnostics, not a gameplay setting. These describe rendered
  /// Flutter frames for the whole UI; native acceptance records the visible scene.
  void _frameTimings(List<ui.FrameTiming> timings) {
    if (data.isEmpty) return;
    final key =
        '$extent:$mode:${zoom.toStringAsFixed(2)}:${pan.dx.toStringAsFixed(1)}:${pan.dy.toStringAsFixed(1)}';
    if (_frameKey != key) {
      _frameKey = key;
      _frameWindow.clear();
    }
    _frameWindow.addAll(timings);
    if (_frameWindow.length < 60) return;
    final first = _frameWindow.first.timestampInMicroseconds(
      ui.FramePhase.buildStart,
    );
    final last = _frameWindow.last.timestampInMicroseconds(
      ui.FramePhase.buildStart,
    );
    final raster =
        _frameWindow.map((f) => f.rasterDuration.inMicroseconds).toList()
          ..sort();
    final build =
        _frameWindow.map((f) => f.buildDuration.inMicroseconds).toList()
          ..sort();
    // This remains in local adb diagnostics; it sends nothing over the network.
    debugPrint(
      'BARRIO_SCENE_STATS ${jsonEncode({'sceneProfile': 'planet-camera-v1', 'map': extent, 'lod': mode, 'zoom': zoom, 'frames': _frameWindow.length, 'renderedFramesPerSecond': last > first ? (_frameWindow.length - 1) * 1000000 / (last - first) : null, 'buildP90Micros': build[(build.length * .9).floor()], 'rasterP90Micros': raster[(raster.length * .9).floor()], 'visibleSettlements': lastSettlementsDrawn, 'visibleSites': lastSitesDrawn, 'visiblePeople': lastPeopleDrawn, 'terrainBlocks': lastTerrainBlocksDrawn, 'pictureCacheBytes': terrainCache.cachedBytes, 'scope': 'profile whole-UI frames; host/device identity supplied by harness'})}',
    );
    _frameWindow.clear();
  }

  void touch(Offset screen) {
    final point = toWorld(screen);
    if (planetCamera.pixelsPerMicrocell >= 4) {
      for (final s in societies.reversed) {
        if (!settlementBounds(s).contains(point)) continue;
        final local = (point - _origin(s)) * PlanetCamera.localPixels;
        if (planetCamera.pixelsPerMicrocell >= 4) {
          for (final crew in _workdays[s['id']]?.crews ?? const <WorkCrew>[]) {
            final p = crew.position(activitySeconds),
                bounds = Rect.fromLTWH(p.dx - 14, p.dy - 30, 42, 40);
            if (!bounds.contains(local)) continue;
            selected = s['id'].toString();
            localSelected = crew.id;
            onSelect(selected!);
            onLocalSelect?.call(
              LocalSelection('crew', crew.id, {
                'building': crew.building,
                'adults': crew.adults,
                'laborMillis': crew.laborMillis,
                'action': crew.action(activitySeconds),
              }, bounds),
            );
            return;
          }
        }
        final hit = _scenes[s['id']]!.entities.reversed
            .where(
              (e) =>
                  (e.kind == 'site' || planetCamera.pixelsPerMicrocell >= 8) &&
                  _displayBounds(e).contains(local),
            )
            .firstOrNull;
        if (hit == null) continue;
        selected = s['id'].toString();
        localSelected = hit.id;
        onSelect(selected!);
        onLocalSelect?.call(hit);
        return;
      }
    }
    Map<String, dynamic>? closest;
    var distance = double.infinity;
    for (final s in societies) {
      final d = (toScreen(position(s)) - screen).distance;
      if (d < distance) {
        closest = s;
        distance = d;
      }
    }
    if (closest != null && distance <= 24) {
      selected = closest['id'].toString();
      localSelected = null;
      onSelect(selected!);
    }
  }

  Color _societyColor(Map<String, dynamic> s) {
    final owner =
        ((data['entities'] as Map?)?['settlements'] as List? ?? [])
            .where((c) => c['actorId'] == s['id'])
            .firstOrNull?['societyId']
            ?.toString() ??
        s['id'].toString();
    const colors = [
      Color(0xffeac27b),
      Color(0xff8cb3b0),
      Color(0xffca886b),
      Color(0xffa7bc87),
      Color(0xffb3a0b8),
      Color(0xffd7d0b5),
    ];
    return colors[owner.codeUnits.fold<int>(
          0,
          (a, c) => (a * 17 + c) & 0x7fffffff,
        ) %
        colors.length];
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (data.isEmpty || size.x <= 0 || size.y <= 0) return;
    final visible = planetCamera.visibleWorld;
    final density = planetCamera.pixelsPerMicrocell;
    lastSettlementsDrawn = 0;
    lastSitesDrawn = 0;
    lastPeopleDrawn = 0;
    canvas.save();
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.scale(unit);
    canvas.translate(-extent / 2, -extent / 2);
    terrainCache.draw(canvas, visible, density, filter);
    lastTerrainBlocksDrawn = terrainCache.lastDrawnBlocks;
    _drawJourneys(canvas, visible);
    for (final s in societies) {
      final bounds = settlementBounds(s);
      if (!visible.inflate(24 / unit).overlaps(bounds)) continue;
      lastSettlementsDrawn++;
      if (density < 2) {
        final mark = Rect.fromCenter(
          center: bounds.center,
          width: math.max(bounds.width, 18 / unit),
          height: math.max(bounds.height, 18 / unit),
        );
        final buildingId =
            ((s['sites'] as List? ?? [])
                        .where(
                          (site) => [
                            'house',
                            'shelter',
                            'habitat',
                          ].contains(site['building']),
                        )
                        .firstOrNull?['building'] ??
                    (s['sites'] as List? ?? []).firstOrNull?['building'])
                ?.toString();
        final source = buildingId == null
            ? null
            : buildingLayout?.frame(buildingId);
        canvas.drawRect(
          mark.inflate(2 / unit),
          Paint()..color = ink.withValues(alpha: .65),
        );
        if (source != null && buildings != null) {
          canvas.drawImageRect(
            buildings!,
            source,
            mark.inflate(3 / unit),
            Paint()..filterQuality = FilterQuality.none,
          );
        } else {
          canvas.drawRect(
            mark.deflate(2 / unit),
            Paint()..color = _societyColor(s),
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(
            mark.left,
            mark.bottom + 2 / unit,
            mark.width,
            2 / unit,
          ),
          Paint()..color = _societyColor(s),
        );
        if (s['id'] == selected) {
          canvas.drawRect(
            mark.inflate(3 / unit),
            Paint()
              ..color = gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 / unit,
          );
        }
      } else {
        _drawSettlement(canvas, s, visible, density);
      }
      if (filter == 'Población') {
        canvas.drawCircle(
          bounds.center,
          math.sqrt(number(s['population'])) / 64,
          Paint()..color = _societyColor(s).withValues(alpha: .25),
        );
      }
    }
    canvas.restore();
    _drawLabels(canvas, density);
    if (mini) _mini(canvas);
  }

  void _drawJourneys(Canvas c, Rect visible) {
    void draw(
      List<dynamic> cells,
      int progress,
      bool blocked,
      Color color, {
      bool caravan = false,
      bool loaded = false,
    }) {
      if (cells.isEmpty || progress < 0 || progress >= cells.length) return;
      final path = Path();
      for (var i = 0; i < cells.length; i++) {
        final cell = number(cells[i]),
            p = Offset(
              number(cells[i]) % extent + .5,
              number(cells[i]) ~/ extent + .5,
            );
        if (cell < 0) continue;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (visible.overlaps(path.getBounds().inflate(.1))) {
        c.drawPath(
          path,
          Paint()
            ..color = blocked
                ? const Color(0xffbb715d)
                : color.withValues(alpha: .65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.min(.12, 2 / unit)
            ..isAntiAlias = false,
        );
      }
      final cell = number(cells[progress]),
          p = Offset(
            number(cells[progress]) % extent + .5,
            number(cells[progress]) ~/ extent + .5,
          );
      if (cell >= 0 && visible.inflate(.1).contains(p)) {
        if (caravan && planetCamera.pixelsPerMicrocell >= .25) {
          final u = math.min(.025, 1 / unit);
          c.save();
          c.translate(p.dx, p.dy);
          c.scale(u);
          final paint = Paint()..isAntiAlias = false;
          c.drawRect(const Rect.fromLTWH(-8, -5, 16, 9), paint..color = ink);
          c.drawRect(
            const Rect.fromLTWH(-7, -4, 14, 7),
            paint..color = const Color(0xffb9874f),
          );
          c.drawRect(const Rect.fromLTWH(-6, -2, 12, 2), paint..color = gold);
          if (loaded) {
            c.drawRect(
              const Rect.fromLTWH(-4, -9, 9, 6),
              paint..color = const Color(0xffd9bd7d),
            );
          }
          for (final x in [-6.0, 5.0]) {
            c.drawRect(Rect.fromLTWH(x, 3, 3, 4), paint..color = ink);
          }
          if (blocked) {
            c.drawRect(
              const Rect.fromLTWH(-1, -12, 2, 5),
              paint..color = const Color(0xffed9277),
            );
          }
          c.restore();
          return;
        }
        c.drawRect(
          Rect.fromCenter(
            center: p,
            width: math.max(.04, 5 / unit),
            height: math.max(.04, 5 / unit),
          ),
          Paint()..color = blocked ? const Color(0xffbb715d) : color,
        );
      }
    }

    for (final r in data['routes'] as List? ?? []) {
      draw(
        r['path'] as List? ?? [],
        number(r['progress']),
        r['blocked'] == true,
        gold,
        caravan: true,
        loaded:
            number(r['foodMillis']) > 0 ||
            number(r['metalMillis']) > 0 ||
            (r['transportRules'] != 2 && number(r['cargo']) > 0),
      );
    }
    for (final r in data['migrations'] as List? ?? []) {
      if (['outbound', 'returning'].contains(r['status'])) {
        draw(
          r['path'] as List? ?? [],
          number(r['progress']),
          r['blocked'] == true,
          const Color(0xff68b8b1),
        );
      }
    }
    if (filter == 'Conflictos') {
      for (final a in societies) {
        for (final b in societies) {
          if (a['id'].toString().compareTo(b['id'].toString()) < 0 &&
              number((a['relations'] as Map?)?[b['id']]) < -40) {
            c.drawLine(
              position(a),
              position(b),
              Paint()
                ..color = const Color(0xffda8469)
                ..strokeWidth = 1 / unit,
            );
          }
        }
      }
    }
  }

  void _drawSettlement(
    Canvas c,
    Map<String, dynamic> s,
    Rect visible,
    double density,
  ) {
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    for (final e in _scenes[s['id']]!.entities) {
      final rect = entityWorldBounds(s['id'].toString(), e);
      if (!visible.overlaps(rect.inflate(1 / 32))) continue;
      if (e.kind == 'site') {
        lastSitesDrawn++;
        // Worn ground decorates a confirmed plot; it is not a transport route.
        paint.color = const Color(0xffb8a678);
        final ground = rect.inflate(9 / 1024);
        final pad = Path()
          ..moveTo(ground.left + ground.width * .18, ground.top)
          ..lineTo(
            ground.right - ground.width * .12,
            ground.top + ground.height * .06,
          )
          ..lineTo(ground.right, ground.top + ground.height * .28)
          ..lineTo(
            ground.right - ground.width * .05,
            ground.bottom - ground.height * .16,
          )
          ..lineTo(ground.right - ground.width * .23, ground.bottom)
          ..lineTo(
            ground.left + ground.width * .12,
            ground.bottom - ground.height * .04,
          )
          ..lineTo(ground.left, ground.bottom - ground.height * .3)
          ..lineTo(
            ground.left + ground.width * .04,
            ground.top + ground.height * .16,
          )
          ..close();
        c.drawPath(pad, paint);
        for (var n = 0; n < 8; n++) {
          paint.color = n.isEven
              ? const Color(0xffc6b584)
              : const Color(0xffa9956d);
          c.drawRect(
            Rect.fromLTWH(
              ground.left + (n * 13 % 72) / 1024,
              ground.top + (n * 23 % 72) / 1024,
              3 / 1024,
              1 / 1024,
            ),
            paint,
          );
        }
        paint.color = const Color(0x55000000);
        c.drawOval(
          Rect.fromLTWH(rect.left + .006, rect.bottom - .006, rect.width, .016),
          paint,
        );
        final source = buildingLayout?.frame(e.entity['building'].toString());
        if (buildings != null && source != null) {
          paint.color = Colors.white;
          paint.colorFilter = s['extinct'] == true
              ? const ColorFilter.mode(Color(0xff80766b), BlendMode.saturation)
              : null;
          c.drawImageRect(buildings!, source, rect, paint);
          paint.colorFilter = null;
        } else {
          c.drawRect(
            rect.deflate(.004),
            paint..color = const Color(0xffc0a47a),
          );
        }
        if (recentSites.containsKey('${s['id']}:${e.id}')) {
          c.drawRect(
            rect.inflate(.004),
            Paint()
              ..color = gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.min(.003, 2 / unit),
          );
        }
        final work = _siteWork[s['id']]?[e.id];
        if (work != null && density >= 8) _workSign(c, rect, work);
      } else if (density >= 8) {
        lastPeopleDrawn++;
        final p = e.entity;
        final ancestral = data['origin'] == 'prehistory';
        final roleId = ancestral
            ? p['role'] == 'artesana'
                  ? 'ancestral_artisan'
                  : p['role'] == 'explorador'
                  ? 'ancestral_scout'
                  : 'ancestral_elder'
            : p['name'] == 'Ana' || p['role'] == 'técnica'
            ? 'ana'
            : p['name'] == 'Leo' || p['role'] == 'explorador'
            ? 'leo'
            : 'tito';
        final found = peopleLayout?.roles.indexOf(roleId) ?? -1;
        final role = found >= 0
            ? found
            : ancestral
            ? 6
            : 0;
        final action = number(s['health'], 100) < 35
            ? 6
            : playing &&
                  p['_walking'] == true &&
                  _visualTime - _dayArrived < dayDuration
            ? 1
            : 0;
        paint.color = Colors.white;
        if (people != null && peopleLayout != null) {
          final frame = reduceMotion ? 0 : (phase * 4).floor() % 4;
          final child = number(data['day']) - number(p['bornDay']) < 16 * 360;
          final destination = child
              ? Rect.fromLTWH(
                  rect.left + rect.width * .15,
                  rect.top + rect.height * .3,
                  rect.width * .7,
                  rect.height * .7,
                )
              : rect;
          c.drawImageRect(
            people!,
            peopleLayout!.cell(
              role * peopleLayout!.actions.length + action,
              frame,
            ),
            destination,
            paint,
          );
        } else {
          c.drawRect(rect, paint..color = earth);
        }
      }
      if (e.id == localSelected) {
        c.drawRect(
          rect.inflate(.004),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / unit,
        );
      }
    }
    if (density >= 4) _drawCrews(c, s, visible);
  }

  void _drawCrews(Canvas canvas, Map<String, dynamic> town, Rect visible) {
    final crews = _workdays[town['id']]?.crews ?? const <WorkCrew>[];
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final roleId = data['origin'] == 'prehistory'
        ? 'ancestral_artisan'
        : 'farmer';
    final role = peopleLayout?.roles.indexOf(roleId) ?? -1;
    for (final crew in crews) {
      final local = crew.position(activitySeconds);
      for (var person = 0; person < crew.adults; person++) {
        final box = Rect.fromLTWH(
          local.dx - 12 + person * 11,
          local.dy - 27,
          24,
          36,
        );
        final rect = PlanetCamera.localRectToWorld(_origin(town), box);
        if (!visible.overlaps(rect)) continue;
        lastPeopleDrawn++;
        canvas.drawOval(
          Rect.fromLTWH(rect.left, rect.bottom - .004, rect.width, .008),
          paint..color = const Color(0x55000000),
        );
        if (people != null && peopleLayout != null && role >= 0) {
          final frame = playing && !reduceMotion
              ? (activitySeconds * 6).floor() % 4
              : 0;
          canvas.drawImageRect(
            people!,
            peopleLayout!.cell(
              role * peopleLayout!.actions.length +
                  crew.action(activitySeconds),
              frame,
            ),
            rect,
            paint..color = Colors.white,
          );
        } else {
          canvas.drawRect(rect, paint..color = moss);
        }
      }
    }
  }

  /// A collective labor signal, not a second named inhabitant or a new job.
  void _workSign(Canvas c, Rect rect, SiteWork work) {
    final u = math.min(.003, 1 / unit),
        pulse = reduceMotion || _visualTime > _workPulseUntil
            ? 0.0
            : math.sin(phase * 14) * 1.5;
    c.save();
    c.translate(rect.right - 2 * u, rect.top + 2 * u);
    c.scale(u);
    final paint = Paint()..isAntiAlias = false;
    c.drawRect(
      const Rect.fromLTWH(-7, -7, 14, 14),
      paint..color = ink.withValues(alpha: .94),
    );
    c.drawRect(
      const Rect.fromLTWH(-6, 5, 12, 2),
      paint..color = const Color(0xff34594e),
    );
    c.drawRect(
      Rect.fromLTWH(-6, 5, 12 * work.laborMillis / 2000, 2),
      paint..color = moss,
    );
    c.drawLine(
      Offset(-3, 2 + pulse),
      Offset(3, -4 + pulse),
      paint
        ..color = gold
        ..strokeWidth = 2,
    );
    c.drawRect(Rect.fromLTWH(0, -5 + pulse, 6, 3), paint..color = earth);
    c.restore();
  }

  void _drawLabels(Canvas c, double density) {
    final occupied = <Rect>[];
    final definitions = (data['catalog'] as Map?)?['buildings'] as List? ?? [];
    void label(String text, Offset p, {Color color = earth}) {
      if (p.dx < -100 || p.dx > size.x || p.dy < 28 || p.dy > size.y - 20) {
        return;
      }
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 160);
      final box = Rect.fromLTWH(
        p.dx - 3,
        p.dy - 2,
        tp.width + 6,
        tp.height + 4,
      );
      if (occupied.any((r) => r.inflate(2).overlaps(box))) return;
      occupied.add(box);
      c.drawRect(box, Paint()..color = ink.withValues(alpha: .85));
      tp.paint(c, p);
    }

    for (final s in societies) {
      if (density < 2) {
        if (zoom > 2 || s['id'] == selected) {
          label(
            '${s['name']}',
            toScreen(position(s)) + const Offset(8, -14),
            color: gold,
          );
        }
        continue;
      }
      if (!planetCamera.visibleWorld.overlaps(settlementBounds(s))) continue;
      for (final e in _scenes[s['id']]!.entities) {
        if (e.kind == 'person' && density < 12) continue;
        if (e.kind == 'site' && e.id != localSelected) continue;
        if (e.kind == 'person' &&
            e.id != followedIndividualId &&
            e.id != localSelected &&
            density < 20) {
          continue;
        }
        final rect = entityWorldBounds(s['id'].toString(), e);
        final text = e.kind == 'person'
            ? '${e.entity['name']}'
            : definitions
                      .where((b) => b['id'] == e.entity['building'])
                      .firstOrNull?['name']
                      ?.toString() ??
                  '${e.entity['building']}';
        label(
          text,
          toScreen(e.kind == 'site' ? rect.topLeft : rect.bottomLeft) +
              const Offset(0, -14),
        );
      }
    }
  }

  void _mini(Canvas c) {
    final rect = Rect.fromLTWH(size.x - 80, math.max(8, size.y - 80), 68, 68),
        scale = 68 / extent;
    c.drawRect(rect.inflate(3), Paint()..color = ink.withValues(alpha: .9));
    c.save();
    c.translate(rect.left, rect.top);
    c.clipRect(Rect.fromLTWH(0, 0, 68, 68));
    c.scale(scale);
    terrainCache.draw(
      c,
      Rect.fromLTWH(0, 0, extent.toDouble(), extent.toDouble()),
      0,
      '',
    );
    for (final s in societies) {
      c.drawRect(
        Rect.fromCenter(
          center: position(s),
          width: 2 / scale,
          height: 2 / scale,
        ),
        Paint()..color = s['id'] == selected ? gold : Colors.white,
      );
    }
    c.drawRect(
      planetCamera.visibleWorld,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / scale,
    );
    c.restore();
  }
}
