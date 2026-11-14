import 'dart:math' as math;

/// Generation version 2 only. Saved terrain remains authoritative on reload.
/// A separate coordinate hash never consumes the simulation PRNG.
class PlanetGeography {
  final int seed, size;
  const PlanetGeography(this.seed, this.size);
  double _hash(int x, int y, int salt) {
    var n =
        (x * 374761393 + y * 668265263 + seed * 1447 + salt * 1013) &
        0x7fffffff;
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff;
    return (n ^ (n >> 16)) / 0x7fffffff;
  }

  double _noise(double x, double y, int salt) {
    final ix = x.floor(), iy = y.floor();
    double ease(double f) => f * f * (3 - 2 * f);
    final fx = ease(x - ix), fy = ease(y - iy);
    final a = _hash(ix, iy, salt) * (1 - fx) + _hash(ix + 1, iy, salt) * fx;
    final b =
        _hash(ix, iy + 1, salt) * (1 - fx) + _hash(ix + 1, iy + 1, salt) * fx;
    return a * (1 - fy) + b * fy;
  }

  int biome(int x, int y) {
    if (x < 2 || y < 2 || x >= size - 2 || y >= size - 2) return 5;
    final nx = x / size, ny = y / size;
    final wx = nx + (_noise(nx * 4, ny * 4, 7) - .5) * .16;
    final wy = ny + (_noise(nx * 4, ny * 4, 8) - .5) * .16;
    final offset = (_hash(0, 0, 19) - .5) * .08;
    double plate(double cx, double cy, double rx, double ry) =>
        1 -
        math.pow((wx - cx - offset) / rx, 2).toDouble() -
        math.pow((wy - cy + offset) / ry, 2).toDouble();
    final land = [
      plate(.31, .39, .29, .34),
      plate(.63, .72, .29, .21),
      plate(.78, .23, .14, .15),
      plate(.13, .83, .105, .10),
    ].reduce(math.max);
    final rough =
        (_noise(nx * 7, ny * 7, 1) - .5) * .44 +
        (_noise(nx * 19, ny * 19, 2) - .5) * .16;
    final height = land + rough;
    if (height < .13) return 5;
    final moisture =
        _noise(nx * 8, ny * 8, 3) * .7 + _noise(nx * 21, ny * 21, 4) * .3;
    final ridge = 1 - (_noise(nx * 12, ny * 12, 5) * 2 - 1).abs();
    if (height > .64 && ridge > .93) return 3;
    if (height < .29 && moisture > .54) return 4;
    if (ny > .27 && ny < .76 && moisture < .37) return 2;
    return moisture > .48 ? 1 : 0;
  }
}
