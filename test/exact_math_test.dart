import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/v2/exact_math.dart';

void main() {
  test('Fast and fallback arithmetic equal BigInt at material boundaries', () {
    final random = Random(73);
    final values = [
      0,
      1,
      1999,
      2000,
      100000000,
      1000000000000,
      9007199254740991,
    ];
    for (final a in values) {
      for (final b in [0, 1, 3, 2000, 1000000000]) {
        for (final c in [1, 3, 2000, 1000000000]) {
          final product = BigInt.from(a) * BigInt.from(b),
              divisor = BigInt.from(c);
          expect(scaledFloor(a, b, c), (product ~/ divisor).toInt());
          expect(
            scaledCeil(a, b, c),
            ((product + divisor - BigInt.one) ~/ divisor).toInt(),
          );
        }
      }
    }
    for (var i = 0; i < 2000; i++) {
      final a = random.nextInt(1000000000),
          b = random.nextInt(1000000),
          c = random.nextInt(1000000) + 1;
      final product = BigInt.from(a) * BigInt.from(b), divisor = BigInt.from(c);
      expect(scaledFloor(a, b, c), (product ~/ divisor).toInt());
      expect(
        scaledCeil(a, b, c),
        ((product + divisor - BigInt.one) ~/ divisor).toInt(),
      );
    }
  });
}
