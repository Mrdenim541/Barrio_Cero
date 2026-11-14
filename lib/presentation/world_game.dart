import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'art_assets.dart';
import 'settlement_scene.dart';

const earth = Color(0xffbda576);
const ink = Color(0xff1d282b);
const gold = Color(0xffe7bb70);
const moss = Color(0xff91a86c);

class WorldGame extends FlameGame {
  Map<String, dynamic> data = {};
  String? selected;
  String mode = 'Mundo';
  String filter = 'Territorios';
  Offset pan = Offset.zero;
  double zoom = 1;
  double phase = 0;
  double _visualTime = 0;
  Object? _generation;
  Set<String> _knownSites = {};
  final Map<String, double> recentSites = {};
  bool reduceMotion = false;
  bool mini = true;
  ui.Image? people, buildings, terrain;
  AtlasLayout? peopleLayout,buildingLayout,terrainLayout;
  final void Function(String) onSelect;
  final void Function(LocalSelection)? onLocalSelect;
  final void Function()? onViewChanged;
  String? localSelected;
  WorldGame(this.onSelect, {this.onLocalSelect, this.onViewChanged});

  /// Semantic zoom changes presentation only. A settlement is entered only
  /// when the zoom focus actually reaches its world position.
  void zoomAt(double value, Offset focus) {
    final previous = mode;
    value = value.clamp(.6, 9).toDouble();
    if (mode == 'Asentamiento') {
      final town = societies.where((s) => s['id'] == selected).firstOrNull;
      if (value < .95) {
        mode = 'Región';
        zoom = 5;
        pan = Offset.zero;
        if (selected != null) locate(selected!);
        pan += focus - center;
        localSelected = null;
      } else {
        if (town != null) {
          final scene = SettlementScene(town);
          final local = scene.toLocal(focus, Size(size.x, size.y), pan, zoom);
          pan = focus - center - (local - scene.bounds.center) * scene.scale(Size(size.x, size.y), value);
        }
        zoom = value;
      }
    } else {
      final anchor = (focus - center - pan) / unit + Offset(extent / 2, extent / 2);
      zoom = value;
      pan = focus - center - (anchor - Offset(extent / 2, extent / 2)) * unit;
      if (zoom >= 6) {
        final point = (focus - center - pan) / unit + Offset(extent / 2, extent / 2);
        final nearby = societies.where((s) => (position(s) - point).distance <= 2.5).toList()
          ..sort((a, b) => (position(a) - point).distance.compareTo((position(b) - point).distance));
        if (nearby.isNotEmpty) {
          selected = nearby.first['id'].toString();
          mode = 'Asentamiento';
          zoom = 1.15;
          pan = focus - center;
          localSelected = null;
        }
      }
      if (mode != 'Asentamiento') {
        if (mode == 'Mundo' && zoom > 2.8) mode = 'Región';
        if (mode == 'Región' && zoom < 2.2) mode = 'Mundo';
        if (zoom <= 1) pan = Offset.zero;
      }
    }
    if (mode != previous) onViewChanged?.call();
  }

  /// Visual feedback follows confirmed snapshots; it does not create buildings.
  void present(Map<String, dynamic> snapshot, {required Object? generation}) {
    final sites = <String>{
      for (final town in snapshot['societies'] as List? ?? [])
        for (final site in town['sites'] as List? ?? []) '${town['id']}:${site['id']}',
    };
    if (_generation == generation && data.isNotEmpty) {
      for (final id in sites.difference(_knownSites)) {
        recentSites[id] = _visualTime + 3;
      }
    } else {
      recentSites.clear();
    }
    _generation = generation;
    _knownSites = sites;
    data = snapshot;
  }
  @override
  Color backgroundColor() => const Color(0xff283d40);
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    final manifest=jsonDecode(await rootBundle.loadString('assets/art/atlas.json')) as Map;
    peopleLayout=AtlasLayout.fromJson(Map<String,dynamic>.from(manifest['characters']));
    buildingLayout=AtlasLayout.fromJson(Map<String,dynamic>.from(manifest['buildings']));
    terrainLayout=AtlasLayout.fromJson(Map<String,dynamic>.from(manifest['terrain']));
    Future<ui.Image> load(AtlasLayout atlas)=>loadArtPixels(rootBundle,
      'assets/art/${atlas.pixels}',atlas.pixelWidth,atlas.pixelHeight);
    people=await load(peopleLayout!);buildings=await load(buildingLayout!);terrain=await load(terrainLayout!);
    images.add('art/characters.png', people!);
    images.add('art/buildings.png', buildings!);
    images.add('art/terrain.png', terrain!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    recentSites.removeWhere((_, expiry) => expiry <= _visualTime);
    if (!reduceMotion) phase += dt;
  }

  List<Map<String, dynamic>> get societies => (data['societies'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  int number(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
  int get extent => number(data['size'], 96);
  Offset position(Map<String, dynamic> s) => Offset(
    number(s['x'], extent ~/ 2).toDouble(),
    number(s['y'], extent ~/ 2).toDouble(),
  );
  Offset get center => Offset(size.x / 2, size.y / 2);
  double get unit => math.min(size.x, size.y) / extent * zoom;
  void touch(Offset screen) {
    if (mode == 'Asentamiento') {
      final society = societies.where((s) => s['id'] == selected).firstOrNull;
      if (society == null) return;
      final scene = SettlementScene(society);
      final hit = scene.pick(
        scene.toLocal(screen, Size(size.x, size.y), pan, zoom),
      );
      if (hit != null) {
        localSelected = hit.id;
        onLocalSelect?.call(hit);
      }
      return;
    }
    final p = (screen - center - pan) / unit + Offset(extent / 2, extent / 2);
    Map<String, dynamic>? best;
    double distance = double.infinity;
    for (final s in societies) {
      final d = (position(s) - p).distance;
      if (d < distance) {
        distance = d;
        best = s;
      }
    }
    if (best != null && distance < math.max(5, 18 / unit)) {
      selected = best['id'].toString();
      onSelect(selected!);
    }
  }

  void locate(String id) {
    selected = id;
    if (mode == 'Asentamiento') {
      pan = Offset.zero;
      return;
    }
    final s = societies.where((s) => s['id'] == id).firstOrNull;
    if (s != null) pan = -(position(s) - Offset(extent / 2, extent / 2)) * unit;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (data.isEmpty) return;
    if (mode == 'Asentamiento') {
      _settlement(canvas);
      return;
    }
    canvas.save();
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.scale(unit);
    canvas.translate(-extent / 2, -extent / 2);
    final tiles = data['tiles'] as List? ?? [];
    final colors = [
      const Color(0xff7e9460),
      const Color(0xff405b47),
      const Color(0xffb69c6c),
      const Color(0xff767875),
      const Color(0xff8c9b87),
      const Color(0xff426c75),
    ];
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    for (var y = 0; y < extent; y++) {
      for (var x = 0; x < extent; x++) {
        final sx = center.dx + pan.dx + (x - extent / 2) * unit;
        final sy = center.dy + pan.dy + (y - extent / 2) * unit;
        if (sx < -unit ||
            sy < -unit ||
            sx > size.x + unit ||
            sy > size.y + unit) {
          continue;
        }
        final index = y * extent + x;
        final dynamic t = index < tiles.length ? tiles[index] : null;
        final b = t is Map ? t['biome'] : t;
        int biome = b is num
            ? b.toInt()
            : [
                'water',
                'plains',
                'forest',
                'desert',
                'mountain',
                'wetland',
              ].indexOf('$b');
        if (biome < 0) biome = 1;
        paint.color = colors[biome % colors.length];
        if (filter == 'Recursos' && t is Map && number(t['richness']) >= 4) {
          paint.color = gold;
        }
        if (filter == 'Entorno' && t is Map && number(t['damage']) > 0) {
          paint.color = const Color(0xffb36d57);
        }
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.04, 1.04),
          paint,
        );
        if (zoom > 2 && (x * 17 + y * 13) % 11 == 0) {
          paint.color = const Color(0x22000000);
          canvas.drawRect(Rect.fromLTWH(x + .2, y + .3, .3, .2), paint);
        }
      }
    }
    final routes = data['routes'] as List? ?? [];
    for (final dynamic route in routes) {
      if (route is! Map) continue;
      final cells = route['path'] as List? ?? [];
      if (cells.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < cells.length; i++) {
        final index = number(cells[i]);
        final p = Offset((index % extent) + .5, (index ~/ extent) + .5);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = route['blocked'] == true
              ? const Color(0xffbb715d)
              : const Color(0xffc7b38b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .32
          ..isAntiAlias = false,
      );
      final cursor = number(route['progress']) % cells.length;
      final index = number(cells[cursor]);
      canvas.drawRect(
        Rect.fromLTWH(index % extent - .4, index ~/ extent - .4, 1.4, 1.4),
        Paint()..color = gold,
      );
    }
    for(final raw in data['migrations'] as List? ?? []){
      if(!['outbound','returning'].contains(raw['status']))continue;
      final cells=List<int>.from(raw['path']),cursor=number(raw['progress']);
      if(cells.isEmpty||cursor<0||cursor>=cells.length)continue;
      final route=Path();
      for(var i=cursor;i<cells.length;i++){final cell=cells[i],p=Offset(cell%extent+.5,cell~/extent+.5);if(i==cursor){route.moveTo(p.dx,p.dy);}else{route.lineTo(p.dx,p.dy);}}
      canvas.drawPath(route,Paint()..color=const Color(0xff68b8b1)..style=PaintingStyle.stroke..strokeWidth=.2..isAntiAlias=false);
      final cell=cells[cursor],x=cell%extent+.5,y=cell~/extent+.5;
      canvas.drawRect(Rect.fromCenter(center:Offset(x,y),width:2,height:2),Paint()..color=ink);
      canvas.drawRect(Rect.fromCenter(center:Offset(x,y),width:1.3,height:1.3),Paint()..color=raw['blocked']==true?const Color(0xffbb715d):const Color(0xff68b8b1));
    }
    final colorsSoc = [
      const Color(0xffeac27b),
      const Color(0xff8cb3b0),
      const Color(0xffca886b),
      const Color(0xffa7bc87),
      const Color(0xffb3a0b8),
      const Color(0xffd7d0b5),
    ];
    for (var i = 0; i < societies.length; i++) {
      final s = societies[i];
      final p = position(s);
      final owner = ((data['entities'] as Map?)?['settlements'] as List? ?? [])
          .where((c) => c['actorId'] == s['id'])
          .firstOrNull?['societyId']
          ?.toString();
      final color =
          colorsSoc[owner == null
              ? i % colorsSoc.length
              : owner.codeUnits.fold<int>(0, (n, c) => n * 17 + c) %
                    colorsSoc.length];
      if (filter == 'Población') {
        canvas.drawCircle(
          p,
          math.max(1, math.sqrt(number(s['population'], 40)) / 3),
          Paint()..color = color.withValues(alpha: .45),
        );
      }
      if (filter == 'Entorno') {
        canvas.drawCircle(
          p,
          2 + number(s['environment']) / 5,
          Paint()..color = const Color(0x88bc6b55),
        );
      }
      if (filter == 'Conflictos') {
        final relations = s['relations'] as Map? ?? {};
        for (final other in societies) {
          if (number(relations[other['id']]) < -40) {
            canvas.drawLine(
              p,
              position(other),
              Paint()
                ..color = const Color(0xffda8469)
                ..strokeWidth = .7,
            );
          }
        }
      }
      if (filter == 'Territorios') {
        canvas.drawCircle(
          p,
          math.max(2, math.sqrt(number(s['population'], 40)) / 2),
          Paint()
            ..color = color.withValues(alpha: .2)
            ..isAntiAlias = false,
        );
      }
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 2.6, height: 2.6),
        Paint()..color = ink,
      );
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 1.8, height: 1.8),
        Paint()..color = color,
      );
      if (s['id'] == selected) {
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 4, height: 4),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = .4,
        );
      }
      if (mode == 'Región' || s['id'] == selected) {
        canvas.save();
        canvas.translate(p.dx + 2, p.dy - 2);
        canvas.scale(1 / unit);
        _text(
          canvas,
          '${s['name']}',
          Offset.zero,
          color: const Color(0xfff3e4c9),
          fontSize: 11,
        );
        canvas.restore();
      }
    }
    canvas.restore();
    if (mini) _mini(canvas);
    _text(
      canvas,
      '${mode.toUpperCase()}  •  $filter',
      const Offset(14, 14),
      color: const Color(0xffe5ddc7),
      fontSize: 10,
    );
  }

  void _mini(Canvas c) {
    final r = Rect.fromLTWH(size.x - 88, 12, 74, 74);
    c.drawRect(r, Paint()..color = ink.withValues(alpha: .85));
    c.drawRect(r.deflate(4), Paint()..color = const Color(0xff566b53));
    for (final s in societies) {
      final p = position(s);
      c.drawRect(
        Rect.fromLTWH(
          r.left + 5 + p.dx / extent * 62,
          r.top + 5 + p.dy / extent * 62,
          3,
          3,
        ),
        Paint()..color = s['id'] == selected ? gold : const Color(0xffe8e2ca),
      );
    }
  }

  void _settlement(Canvas c) {
    final s =
        societies.where((s) => s['id'] == selected).firstOrNull ??
        societies.firstOrNull;
    if (s == null) return;
    final scene = SettlementScene(s);
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final scale = scene.scale(Size(size.x, size.y), zoom);
    c.save();
    c.translate(center.dx + pan.dx, center.dy + pan.dy);
    c.scale(scale);
    c.translate(-scene.bounds.center.dx, -scene.bounds.center.dy);
    final area = scene.bounds.inflate(320);
    final tiles = data['tiles'] as List? ?? [];
    final tileIndex = number(s['y']) * extent + number(s['x']);
    final tile = tileIndex >= 0 && tileIndex < tiles.length ? tiles[tileIndex] : null;
    final biome = (tile is Map ? number(tile['biome']) : 0).clamp(0, 5);
    final ground = const [Color(0xff829365), Color(0xff657e58),
      Color(0xffb69c6c), Color(0xff85887b), Color(0xff748c77),
      Color(0xff6c8580)][biome];
    // Ground texture and worn entrances are presentation, not transport routes.
    for (
      var y = math.max(0, area.top ~/ 32);
      y < math.min(32, area.bottom / 32);
      y++
    ) {
      for (
        var x = math.max(0, area.left ~/ 32);
        x < math.min(32, area.right / 32);
        x++
      ) {
        final shade = (x * 17 + y * 31) % 5;
        paint.color = Color.lerp(ground, const Color(0xff405345), shade * .025)!;
        c.drawRect(Rect.fromLTWH(x * 32.0, y * 32.0, 32, 32), paint);
        paint.color = Color.lerp(ground, const Color(0xffd8cfad), .25)!;
        c.drawRect(
          Rect.fromLTWH(
            x * 32.0 + (x * 7 + y * 3) % 26,
            y * 32.0 + (x * 3 + y * 7) % 26,
            3,
            2,
          ),
          paint,
        );
        if ([0, 1, 4].contains(biome) && (x * 13 + y * 7) % (biome == 1 ? 11 : 23) == 0 &&
            !scene.entities.any(
              (e) => e.bounds
                  .inflate(26)
                  .overlaps(Rect.fromLTWH(x * 32.0, y * 32.0, 32, 32)),
            )) {
          _tree(c, Offset(x * 32.0, y * 32.0));
        }
      }
    }
    for (final e in scene.entities) {
      final r = e.bounds;
      if (e.kind == 'site') {
        paint.color = const Color(0xffb7a77c);
        c.drawRect(r.inflate(12), paint);
        paint.color = const Color(0xffa2926c);
        c.drawRect(Rect.fromLTWH(r.left + 20, r.bottom, 24, 28), paint);
        paint.color = const Color(0x55000000);
        c.drawOval(Rect.fromLTWH(r.left + 6, r.bottom - 8, 64, 16), paint);
        final source=buildingLayout?.frame(e.entity['building'].toString());
        if (buildings != null && source != null) {
          paint.color = Colors.white;
          paint.colorFilter = s['extinct'] == true
              ? const ColorFilter.mode(Color(0xff80766b), BlendMode.saturation)
              : null;
          c.drawImageRect(
            buildings!,
            source,
            r,
            paint,
          );
          paint.colorFilter = null;
        } else {
          _house(c, r.topLeft);
        }
        if (recentSites.containsKey('${s['id']}:${e.id}')) {
          c.drawRect(r.inflate(4), Paint()..color = gold
            ..style = PaintingStyle.stroke..strokeWidth = 3);
        }
      } else {
        final p = e.entity;
        final role = data['origin']=='prehistory'
            ? peopleLayout!.roles.indexOf(p['role']=='artesana'?'ancestral_artisan':p['role']=='explorador'?'ancestral_scout':'ancestral_elder')
            : p['name'] == 'Ana' || p['role'] == 'técnica'
            ? 0
            : p['name'] == 'Leo' || p['role'] == 'explorador'
            ? 1
            : p['name'] == 'Tito'
            ? 2
            : 3;
        // A project does not assign a named person as its builder. Named work
        // animations need an actual assignment, not an inference from their role.
        final action = number(s['health'], 100) < 35 ? 6 : 0;
        paint.color = const Color(0x66000000);
        c.drawOval(Rect.fromLTWH(r.left + 4, r.bottom - 5, 28, 9), paint);
        paint.color = Colors.white;
        if (people != null) {
          final frame = reduceMotion ? 0 : (phase * 4).floor() % 4;
          c.drawImageRect(
            people!,
            peopleLayout!.cell(role*peopleLayout!.actions.length+action,frame),
            number(data['day'])-number(p['bornDay'])<16*360?Rect.fromLTWH(r.left+r.width*.15,r.top+r.height*.3,r.width*.7,r.height*.7):r,
            paint,
          );
        } else {
          _person(c, r.topLeft, role);
        }
        if (scale > .45) {
          _text(
            c,
            '${p['name']}',
            Offset(r.left - 4, r.bottom + 4),
            color: const Color(0xfff8edd7),
            fontSize: 12,
          );
        }
      }
      if (localSelected == e.id) {
        paint
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        c.drawRect(r.inflate(4), paint);
        paint.style = PaintingStyle.fill;
      }
    }
    c.restore();
    // Labels stay readable while geometry and picking retain confirmed positions.
    final catalog = data['catalog'] as Map?;
    final definitions = catalog?['buildings'] as List? ?? [];
    final labels = <Rect>[];
    if (scale > .28) {
      for (final e in scene.entities.where((e) => e.kind == 'site')) {
        if (e.id != localSelected && scale < .75) continue;
        final p = scene.toScreen(Offset(e.bounds.left, e.bounds.top - 22),
            Size(size.x, size.y), pan, zoom);
        if (p.dx < -90 || p.dx > size.x || p.dy < 36 || p.dy > size.y - 30) continue;
        final definition = definitions.where((b) => b['id'] == e.entity['building']).firstOrNull;
        final label = TextPainter(
          text: TextSpan(text: definition?['name']?.toString() ?? 'Edificio',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: Color(0xfff8edd7))),
          textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…',
        )..layout(maxWidth: 88);
        final box = Rect.fromLTWH(p.dx - 2, p.dy - 1, label.width + 4, label.height + 2);
        final controls = Rect.fromLTWH(size.x - 56, 0, 56, 104);
        if (box.left < 4 || box.right > size.x - 4 || box.overlaps(controls) ||
            labels.any((previous) => previous.inflate(3).overlaps(box))) {
          continue;
        }
        labels.add(box);
        c.drawRect(box, Paint()..color = ink.withValues(alpha: .8));
        label.paint(c, p);
      }
    }
  }

  void _tree(Canvas c, Offset p) {
    c.drawRect(
      Rect.fromLTWH(p.dx + 6, p.dy + 13, 5, 13),
      Paint()..color = const Color(0xff675645),
    );
    c.drawRect(
      Rect.fromLTWH(p.dx, p.dy, 20, 17),
      Paint()..color = const Color(0xff435b43),
    );
    c.drawRect(
      Rect.fromLTWH(p.dx + 4, p.dy - 4, 12, 10),
      Paint()..color = const Color(0xff567453),
    );
  }

  void _house(Canvas c, Offset p) {
    c.drawRect(Rect.fromLTWH(p.dx, p.dy + 14, 48, 34), Paint()..color = ink);
    c.drawRect(
      Rect.fromLTWH(p.dx + 3, p.dy + 17, 42, 27),
      Paint()..color = const Color(0xffc0a47a),
    );
    c.drawRect(
      Rect.fromLTWH(p.dx - 3, p.dy + 7, 54, 14),
      Paint()..color = const Color(0xff64574b),
    );
    c.drawRect(
      Rect.fromLTWH(p.dx + 19, p.dy + 30, 12, 18),
      Paint()..color = ink,
    );
  }

  void _person(Canvas c, Offset p, int i) {
    c.drawRect(Rect.fromLTWH(p.dx + 3, p.dy + 1, 14, 13), Paint()..color = ink);
    c.drawRect(
      Rect.fromLTWH(p.dx + 5, p.dy + 4, 10, 8),
      Paint()..color = const Color(0xffce9b74),
    );
    c.drawRect(
      Rect.fromLTWH(p.dx + 4, p.dy + 14, 12, 13),
      Paint()
        ..color = i % 2 == 0
            ? const Color(0xff5b858c)
            : const Color(0xffa47a4d),
    );
    c.drawRect(Rect.fromLTWH(p.dx + 4, p.dy + 27, 5, 7), Paint()..color = ink);
    c.drawRect(Rect.fromLTWH(p.dx + 12, p.dy + 27, 5, 7), Paint()..color = ink);
  }

  void _text(
    Canvas c,
    String text,
    Offset p, {
    Color color = gold,
    double fontSize = 12,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: ink, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 400);
    tp.paint(c, p);
  }
}
