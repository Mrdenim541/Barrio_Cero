import 'dart:math' as math;
import 'dart:ui';

/// A single coordinate frame. Regional cells contain 32 microcells; local
/// sprite pixels are 1/1024 of a regional cell. No simulation state is owned.
class PlanetCamera {
  static const microcells = 32;
  static const localPixels = 1024.0;
  Size viewport = Size.zero;
  int extent = 96;
  Offset pan = Offset.zero;
  double zoom = 1;
  Offset get center => Offset(viewport.width / 2, viewport.height / 2);
  double get baseUnit =>
      math.max(1, math.min(viewport.width, viewport.height)) / extent;
  double get unit => baseUnit * zoom;
  double get pixelsPerMicrocell => unit / microcells;
  Rect get visibleWorld => Rect.fromPoints(
    toWorld(Offset.zero),
    toWorld(Offset(viewport.width, viewport.height)),
  );
  Offset toWorld(Offset p) =>
      (p - center - pan) / unit + Offset(extent / 2, extent / 2);
  Offset toScreen(Offset p) =>
      center + pan + (p - Offset(extent / 2, extent / 2)) * unit;
  void resize(Size next) {
    final anchor = viewport.isEmpty ? null : toWorld(center);
    viewport = next;
    if (anchor != null) centerOn(anchor);
  }

  void zoomAt(double next, Offset focus) {
    final anchor = toWorld(focus);
    zoom = next.clamp(.6, math.max(1, 64 * microcells / baseUnit)).toDouble();
    pan = focus - center - (anchor - Offset(extent / 2, extent / 2)) * unit;
  }

  void centerOn(Offset p) => pan = -(p - Offset(extent / 2, extent / 2)) * unit;
  void fitWorld() {
    zoom = 1;
    pan = Offset.zero;
  }

  void fitBounds(Rect bounds) {
    final wanted =
        .82 *
        math.min(
          viewport.width / math.max(bounds.width, 1 / 32),
          viewport.height / math.max(bounds.height, 1 / 32),
        );
    zoomAt(wanted / baseUnit, center);
    centerOn(bounds.center);
  }

  static Offset localToWorld(Offset origin, Offset local) =>
      origin + local / localPixels;
  static Rect localRectToWorld(Offset origin, Rect r) => Rect.fromLTRB(
    origin.dx + r.left / localPixels,
    origin.dy + r.top / localPixels,
    origin.dx + r.right / localPixels,
    origin.dy + r.bottom / localPixels,
  );
}
