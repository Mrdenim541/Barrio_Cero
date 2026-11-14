import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Bounded presentation cache. Detail is texture, not extra resources/terrain.
class PlanetTerrain {
  static const colors = [
    Color(0xff7e9460),
    Color(0xff405b47),
    Color(0xffb69c6c),
    Color(0xff767875),
    Color(0xff8c9b87),
    Color(0xff426c75),
  ];
  static const maxCacheBytes = 64 * 1024 * 1024;
  final Map<String, Picture> _pictures = <String, Picture>{};
  final Map<String, Image> _images = <String, Image>{};
  final Set<String> _pending = {};
  int _epoch = 0, _pendingBytes = 0;
  List<int> _tokens = [];
  int extent = 0, cachedBytes = 0, lastDrawnBlocks = 0;
  int revision = 0;
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
    final changed =
        nextExtent != extent ||
        next.length != _tokens.length ||
        Iterable<int>.generate(next.length).any((i) => next[i] != _tokens[i]);
    if (!changed) return false;
    clear();
    extent = nextExtent;
    _tokens = next;
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
    final epoch = _epoch, bytes = extent * extent * 4;
    _evict(bytes);
    if (cachedBytes + _pendingBytes + bytes > maxCacheBytes) return null;
    _pending.add('$epoch:$key');
    _pendingBytes += bytes;
    final rgba = Uint8List(bytes);
    for (var i = 0; i < extent * extent; i++) {
      final color = _color(
        i < _tokens.length ? _tokens[i] : 5,
        filter,
      ).toARGB32();
      rgba[i * 4] = (color >> 16) & 255;
      rgba[i * 4 + 1] = (color >> 8) & 255;
      rgba[i * 4 + 2] = color & 255;
      rgba[i * 4 + 3] = 255;
    }
    decodeImageFromPixels(
      rgba,
      extent,
      extent,
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
    int pixels,
  ) async {
    if (_pending.contains('$_epoch:$key')) return;
    final bytes = pixels * pixels * 4, epoch = _epoch;
    _evict(bytes);
    if (cachedBytes + _pendingBytes + bytes > maxCacheBytes) return;
    _pending.add('$epoch:$key');
    _pendingBytes += bytes;
    final recorder = PictureRecorder();
    Canvas(recorder)
      ..scale(pixels.toDouble())
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
      canvas.drawImageRect(
        overview,
        Rect.fromLTWH(0, 0, extent.toDouble(), extent.toDouble()),
        Rect.fromLTWH(0, 0, extent.toDouble(), extent.toDouble()),
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
    if (density < 4) return;
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
          final base = _color(_tokens[i], filter);
          for (var my = 0; my < 32; my++) {
            for (var mx = 0; mx < 32; mx++) {
              final shade = (mx * 17 + my * 31 + x * 7 + y * 13) % 5;
              paint.color = Color.lerp(
                base,
                const Color(0xff405345),
                shade * .018,
              )!;
              c.drawRect(
                Rect.fromLTWH(x + mx / 32, y + my / 32, 1 / 32, 1 / 32),
                paint,
              );
              if (shade == 0) {
                paint.color = Color.lerp(base, const Color(0xffd8cfad), .16)!;
                c.drawRect(
                  Rect.fromLTWH(
                    x + (mx + .25) / 32,
                    y + (my + .65) / 32,
                    .18 / 32,
                    .08 / 32,
                  ),
                  paint,
                );
              }
              // Biome scenery only: no extra trees/resources are added to
              // simulation. Buildings are drawn afterwards over their ground.
              final biome = _tokens[i] & 7;
              if ([0, 1, 4].contains(biome) &&
                  (mx * 13 + my * 7 + x * 3 + y * 5) % (biome == 1 ? 11 : 29) ==
                      0) {
                final px = x + (mx + .2) / 32;
                final py = y + (my + .15) / 32;
                paint.color = const Color(0xff675645);
                c.drawRect(
                  Rect.fromLTWH(px + .2 / 32, py + .3 / 32, .15 / 32, .55 / 32),
                  paint,
                );
                paint.color = const Color(0xff435b43);
                c.drawRect(Rect.fromLTWH(px, py, .65 / 32, .55 / 32), paint);
                paint.color = const Color(0xff567453);
                c.drawRect(
                  Rect.fromLTWH(px + .12 / 32, py - .1 / 32, .4 / 32, .32 / 32),
                  paint,
                );
              }
            }
          }
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
