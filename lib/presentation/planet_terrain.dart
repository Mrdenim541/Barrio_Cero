import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'art_assets.dart';

/// Bounded presentation cache. Detail is texture, not extra resources/terrain.
class PlanetTerrain {
  static const colors = [
    Color(0xff82964d),
    Color(0xff577b42),
    Color(0xffc1aa6c),
    Color(0xff8d9f8d),
    Color(0xff6b8b62),
    Color(0xff286d85),
  ];
  static const maxCacheBytes = 64 * 1024 * 1024;
  final Map<String, Picture> _pictures = <String, Picture>{};
  final Map<String, Image> _images = <String, Image>{};
  final Set<String> _pending = {};
  int _epoch = 0, _pendingBytes = 0;
  List<int> _tokens = [];
  int extent = 0, cachedBytes = 0, lastDrawnBlocks = 0;
  int revision = 0;
  Image? landscape;
  AtlasLayout? landscapeLayout;
  int _seed = 0;
  String _maskKey = '';
  final Map<int, List<Rect>> _masks = {};

  void attachLandscape(Image image, AtlasLayout layout) {
    landscape = image;
    landscapeLayout = layout;
    clear();
  }

  int _hash(int x, int y, [int salt = 0]) {
    var n =
        (x * 374761393 + y * 668265263 + _seed * 1447 + salt * 1013) &
        0x7fffffff;
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff;
    return n ^ (n >> 16);
  }

  bool _sea(int x, int y) =>
      x < 0 ||
      y < 0 ||
      x >= extent ||
      y >= extent ||
      (y * extent + x < _tokens.length && (_tokens[y * extent + x] & 7) == 5);

  bool _clearGround(Rect rect) =>
      !(_masks[rect.center.dy.floor() * extent + rect.center.dx.floor()] ?? [])
          .any((plot) => plot.overlaps(rect));

  void _sprite(Canvas c, String id, Rect bounds, Paint paint) {
    final source = landscapeLayout?.frame(id);
    if (landscape != null && source != null) {
      c.drawImageRect(landscape!, source, bounds, paint);
    }
  }

  void _scenery(Canvas c, int x, int y, Paint paint, {bool distant = false}) {
    final index = y * extent + x;
    if (index >= _tokens.length) return;
    final biome = _tokens[index] & 7;
    if (biome == 5) return;
    for (var gy = 0; gy < 8; gy++) {
      for (var gx = 0; gx < 8; gx++) {
        final h = _hash(x * 8 + gx, y * 8 + gy);
        if (distant && (gx.isOdd || gy.isOdd)) continue;
        final threshold = [13, 64, 5, 18, 26, 0][biome.clamp(0, 5)];
        if (h % 100 >= threshold || (distant && h % 3 == 0)) continue;
        final id = switch (biome) {
          1 => h % 4 == 0 ? 'pine' : 'oak',
          3 => h % 3 == 0 ? 'peak' : 'boulder',
          4 => h % 3 == 0 ? 'oak' : 'reeds',
          2 => 'boulder',
          _ =>
            h % 4 == 0
                ? 'oak'
                : h % 3 == 0
                ? 'flowers'
                : 'shrub',
        };
        final width =
            (id == 'peak'
                ? .14
                : id == 'oak' || id == 'pine'
                ? .10
                : .064) *
            (distant ? 2.6 : 1);
        final bounds = Rect.fromLTWH(
          x + (gx + .5) / 8 - width / 2,
          y + (gy + .5) / 8 - width * .75,
          width,
          width,
        );
        if (_clearGround(bounds)) _sprite(c, id, bounds, paint);
      }
    }
    if (_tokens[index] & (1 << 9) != 0) {
      final rect = Rect.fromLTWH(x + .43, y + .42, .14, .14);
      if (_clearGround(rect)) _sprite(c, 'ruins', rect, paint);
    }
  }

  Color _overviewColor(int x, int y, int sx, int sy, String filter) {
    final token = y * extent + x < _tokens.length ? _tokens[y * extent + x] : 5;
    final sea = (token & 7) == 5;
    final edges = [
      !_sea(x - 1, y),
      !_sea(x + 1, y),
      !_sea(x, y - 1),
      !_sea(x, y + 1),
    ];
    final shore = sea && edges.any((e) => e);
    if (sea) {
      if (shore &&
          ((sx == 0 && edges[0]) ||
              (sx == 3 && edges[1]) ||
              (sy == 0 && edges[2]) ||
              (sy == 3 && edges[3]))) {
        return const Color(0xff7bb7ae);
      }
      return shore
          ? const Color(0xff388c9d)
          : (_hash(x, y) % 7 == 0 && sy == 1 && sx < 3
                ? const Color(0xff2a7289)
                : const Color(0xff235f78));
    }
    if ((sx == 0 && _sea(x - 1, y)) ||
        (sx == 3 && _sea(x + 1, y)) ||
        (sy == 0 && _sea(x, y - 1)) ||
        (sy == 3 && _sea(x, y + 1))) {
      return const Color(0xffd2bd7e);
    }
    var base = _color(token, filter);
    if ((token & 7) == 3) {
      base = Color.lerp(
        base,
        sx < sy ? const Color(0xffd3dbc2) : const Color(0xff526d64),
        .35,
      )!;
    }
    return Color.lerp(
      base,
      const Color(0xffd8d89b),
      (_hash(x * 4 + sx, y * 4 + sy) % 4) * .025,
    )!;
  }

  Image? get overviewImage => _images['overview:'];
  bool sync(Map<String, dynamic> data) {
    final nextExtent = (data['size'] as num?)?.toInt() ?? 96;
    final input = data['tiles'] as List? ?? const [];
    final next = <int>[
      for (final t in input)
        t is Map
            ? ((t['biome'] as num?)?.toInt() ?? 0) |
                  (((t['richness'] as num?)?.toInt() ?? 0) << 3) |
                  ((t['damage'] as num? ?? 0) > 0 ? 1 << 8 : 0) |
                  (t['ruin'] == true ? 1 << 9 : 0)
            : (t as num).toInt(),
    ];
    final mask = StringBuffer();
    final masks = <int, List<Rect>>{};
    for (final town in data['societies'] as List? ?? []) {
      for (final site in town['sites'] as List? ?? []) {
        final rect = Rect.fromLTWH(
          (town['x'] as num).toDouble() + (site['x'] as num) / 32 - .025,
          (town['y'] as num).toDouble() + (site['y'] as num) / 32 - .025,
          .13,
          .15,
        );
        mask.write('${rect.left}:${rect.top};');
        for (var y = rect.top.floor(); y <= rect.bottom.ceil(); y++) {
          for (var x = rect.left.floor(); x <= rect.right.ceil(); x++) {
            masks.putIfAbsent(y * nextExtent + x, () => []).add(rect);
          }
        }
      }
    }
    final maskKey = mask.toString();
    final nextSeed = (data['seed'] as num?)?.toInt() ?? 0;
    final changed =
        nextExtent != extent ||
        nextSeed != _seed ||
        maskKey != _maskKey ||
        next.length != _tokens.length ||
        Iterable<int>.generate(next.length).any((i) => next[i] != _tokens[i]);
    if (!changed) return false;
    clear();
    extent = nextExtent;
    _tokens = next;
    _seed = nextSeed;
    _maskKey = maskKey;
    _masks
      ..clear()
      ..addAll(masks);
    revision++;
    return true;
  }

  Picture _picture(String key, void Function(Canvas) draw) {
    final previous = _pictures.remove(key);
    if (previous != null) {
      _pictures[key] = previous;
      return previous;
    }
    final recorder = PictureRecorder();
    draw(Canvas(recorder));
    final result = recorder.endRecording();
    _pictures[key] = result;
    cachedBytes += result.approximateBytesUsed;
    _evict();
    return result;
  }

  void _evict([int reserve = 0]) {
    while (cachedBytes + _pendingBytes + reserve > maxCacheBytes &&
        _pictures.length > 1) {
      final oldest = _pictures.remove(_pictures.keys.first)!;
      cachedBytes -= oldest.approximateBytesUsed;
      oldest.dispose();
    }
    while (cachedBytes + _pendingBytes + reserve > maxCacheBytes &&
        _images.isNotEmpty) {
      final oldest = _images.remove(_images.keys.first)!;
      cachedBytes -= oldest.width * oldest.height * 4;
      oldest.dispose();
    }
  }

  Image? _cachedImage(String key) {
    final image = _images.remove(key);
    if (image != null) _images[key] = image;
    return image;
  }

  void _storeImage(String key, Image image, int epoch) {
    final bytes = image.width * image.height * 4;
    if (_pending.remove('$epoch:$key')) _pendingBytes -= bytes;
    if (epoch != _epoch) {
      image.dispose();
      return;
    }
    _evict(bytes);
    _images[key] = image;
    cachedBytes += bytes;
  }

  Image? _overview(String filter) {
    final key = 'overview:$filter';
    final existing = _cachedImage(key);
    if (existing != null || _pending.contains('$_epoch:$key')) return existing;
    final edge = extent * 4;
    final epoch = _epoch, bytes = edge * edge * 4;
    _evict(bytes);
    if (cachedBytes + _pendingBytes + bytes > maxCacheBytes) return null;
    _pending.add('$epoch:$key');
    _pendingBytes += bytes;
    final rgba = Uint8List(bytes);
    for (var py = 0; py < edge; py++) {
      for (var px = 0; px < edge; px++) {
        final color = _overviewColor(
          px ~/ 4,
          py ~/ 4,
          px % 4,
          py % 4,
          filter,
        ).toARGB32();
        final i = py * edge + px;
        rgba[i * 4] = (color >> 16) & 255;
        rgba[i * 4 + 1] = (color >> 8) & 255;
        rgba[i * 4 + 2] = color & 255;
        rgba[i * 4 + 3] = 255;
      }
    }
    decodeImageFromPixels(
      rgba,
      edge,
      edge,
      PixelFormat.rgba8888,
      (image) => _storeImage(key, image, epoch),
    );
    return null;
  }

  Future<void> _rasterCell(
    String key,
    Picture source,
    int x,
    int y,
    int pixels, {
    double span = 1,
  }) async {
    if (_pending.contains('$_epoch:$key')) return;
    final bytes = pixels * pixels * 4, epoch = _epoch;
    _evict(bytes);
    if (cachedBytes + _pendingBytes + bytes > maxCacheBytes) return;
    _pending.add('$epoch:$key');
    _pendingBytes += bytes;
    final recorder = PictureRecorder();
    Canvas(recorder)
      ..scale(pixels / span)
      ..translate(-x.toDouble(), -y.toDouble())
      ..drawPicture(source);
    final transformed = recorder.endRecording();
    try {
      _storeImage(key, await transformed.toImage(pixels, pixels), epoch);
    } catch (_) {
      if (_pending.remove('$epoch:$key')) {
        _pendingBytes -= bytes;
      }
    } finally {
      transformed.dispose();
    }
  }

  Color _color(int token, String filter) {
    if (filter == 'Recursos' && ((token >> 3) & 31) >= 4) {
      return const Color(0xffd0ab57);
    }
    if (filter == 'Entorno' && token & (1 << 8) != 0) {
      return const Color(0xffb36d57);
    }
    return colors[(token & 7).clamp(0, 5)];
  }

  void draw(Canvas canvas, Rect visible, double density, String filter) {
    lastDrawnBlocks = 0;
    if (extent == 0) return;
    final area = visible.intersect(
      Rect.fromLTWH(0, 0, extent.toDouble(), extent.toDouble()),
    );
    if (area.isEmpty) return;
    filter = ['Recursos', 'Entorno'].contains(filter) ? filter : '';
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final overview = _overview(filter);
    if (overview != null) {
      final scale = overview.width / extent;
      canvas.drawImageRect(
        overview,
        Rect.fromLTRB(
          area.left * scale,
          area.top * scale,
          area.right * scale,
          area.bottom * scale,
        ),
        area,
        paint,
      );
      lastDrawnBlocks++;
    }
    const block = 16;
    for (
      var by = math.max(0, area.top.floor() ~/ block);
      by <= math.min((extent - 1) ~/ block, area.bottom.floor() ~/ block);
      by++
    ) {
      for (
        var bx = math.max(0, area.left.floor() ~/ block);
        bx <= math.min((extent - 1) ~/ block, area.right.floor() ~/ block);
        bx++
      ) {
        if (overview != null) continue;
        canvas.drawPicture(
          _picture('base:$bx:$by:$filter', (c) {
            for (
              var y = by * block;
              y < math.min(extent, (by + 1) * block);
              y++
            ) {
              for (
                var x = bx * block;
                x < math.min(extent, (bx + 1) * block);
                x++
              ) {
                final i = y * extent + x;
                if (i >= _tokens.length) continue;
                paint.color = _color(_tokens[i], filter);
                c.drawRect(
                  Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
                  paint,
                );
              }
            }
          }),
        );
        lastDrawnBlocks++;
      }
    }
    if (density < .25 || landscape == null) return;
    if (density < 4) {
      const span = 8;
      for (
        var by = math.max(0, area.top.floor() ~/ span);
        by <= math.min((extent - 1) ~/ span, area.bottom.floor() ~/ span);
        by++
      ) {
        for (
          var bx = math.max(0, area.left.floor() ~/ span);
          bx <= math.min((extent - 1) ~/ span, area.right.floor() ~/ span);
          bx++
        ) {
          final x = bx * span, y = by * span;
          final key = 'scenery_raster:$bx:$by';
          final cached = _cachedImage(key);
          if (cached != null) {
            canvas.drawImageRect(
              cached,
              Rect.fromLTWH(0, 0, 512, 512),
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 8, 8),
              paint,
            );
          } else {
            final picture = _picture('scenery:$bx:$by', (c) {
              for (var cy = y; cy < math.min(extent, y + span); cy++) {
                for (var cx = x; cx < math.min(extent, x + span); cx++) {
                  _scenery(c, cx, cy, paint, distant: true);
                }
              }
            });
            canvas.drawPicture(picture);
            _rasterCell(key, picture, x, y, 512, span: 8);
          }
          lastDrawnBlocks++;
        }
      }
      return;
    }
    for (
      var y = math.max(0, area.top.floor());
      y < math.min(extent, area.bottom.ceil());
      y++
    ) {
      for (
        var x = math.max(0, area.left.floor());
        x < math.min(extent, area.right.ceil());
        x++
      ) {
        final i = y * extent + x;
        if (i >= _tokens.length) continue;
        final pixels = density < 8
            ? 256
            : density < 16
            ? 512
            : 1024;
        final imageKey = 'raster:$x:$y:$pixels:$filter';
        final cached = _cachedImage(imageKey);
        if (cached != null) {
          canvas.drawImageRect(
            cached,
            Rect.fromLTWH(0, 0, pixels.toDouble(), pixels.toDouble()),
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
            paint,
          );
          lastDrawnBlocks++;
          continue;
        }
        final detail = _picture('detail:$x:$y:$filter', (c) {
          final biome = (_tokens[i] & 7).clamp(0, 5);
          const names = [
            'plains',
            'forest',
            'desert',
            'mountain',
            'wetland',
            'water',
          ];
          for (var gy = 0; gy < 8; gy++) {
            for (var gx = 0; gx < 8; gx++) {
              final variant = _hash(x * 8 + gx, y * 8 + gy) % 4;
              _sprite(
                c,
                '${names[biome]}_$variant',
                Rect.fromLTWH(x + gx / 8, y + gy / 8, .125, .125),
                paint,
              );
            }
          }
          if (filter.isNotEmpty || _tokens[i] & (1 << 8) != 0) {
            c.drawRect(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
              Paint()
                ..color = _color(_tokens[i], filter).withValues(alpha: .22),
            );
          }
          _scenery(c, x, y, paint);
        });
        canvas.drawPicture(detail);
        _rasterCell(imageKey, detail, x, y, pixels);
        lastDrawnBlocks++;
      }
    }
  }

  void clear() {
    _epoch++;
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
    cachedBytes = 0;
  }
}
