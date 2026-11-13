import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/v2/materials.dart';

void main() {
  test('Exact quantities and range checks', () {
    expect(Quantity.parse('0.001').millis, 1);
    expect(Quantity.parse('-12.12').millis, -12120);
    expect(Quantity.parse('10').toString(), '10.000');
    expect(() => Quantity.parse('1.0001'), throwsFormatException);
    expect(() => Quantity.parse('NaN'), throwsFormatException);
    expect(() => Quantity.parse('9223372036854775807'), throwsRangeError);
    expect(() => Quantity(Quantity.maxMillis + 1), throwsRangeError);
  });
  MaterialLedger funded() {
    final l = MaterialLedger({'food', 'wood'});
    l.transfer(
      id: 'harvest',
      from: 'source:harvest',
      to: 'village',
      amounts: {'food': 10000, 'wood': 5000},
    );
    return l;
  }

  test(
    'Multi-resource rejection is atomic and idempotent transfer charges once',
    () {
      final l = funded();
      final before = jsonEncode(l.toJson());
      expect(
        () => l.transfer(
          id: 'bad',
          from: 'village',
          to: 'escrow:build',
          amounts: {'food': 1, 'wood': 5001},
        ),
        throwsStateError,
      );
      expect(jsonEncode(l.toJson()), before);
      expect(
        l.transfer(
          id: 'build',
          from: 'village',
          to: 'escrow:build',
          amounts: {'wood': 1000, 'food': 2000},
        ),
        isTrue,
      );
      expect(
        l.transfer(
          id: 'build',
          from: 'village',
          to: 'escrow:build',
          amounts: {'food': 2000, 'wood': 1000},
        ),
        isFalse,
      );
      expect(l.balance('village', 'wood'), 4000);
      expect(
        () => l.transfer(
          id: 'build',
          from: 'village',
          to: 'escrow:build',
          amounts: {'food': 1},
        ),
        throwsStateError,
      );
    },
  );
  test('Reservation, cancellation and consumption preserve every material', () {
    final l = funded();
    l.transfer(
      id: 'reserve',
      from: 'village',
      to: 'escrow:work',
      amounts: {'wood': 3000},
    );
    l.transfer(
      id: 'cancel',
      from: 'escrow:work',
      to: 'village',
      amounts: {'wood': 3000},
    );
    l.transfer(
      id: 'eat',
      from: 'village',
      to: 'sink:food',
      amounts: {'food': 1000},
    );
    final restored = MaterialLedger.fromJson(
      jsonDecode(jsonEncode(l.toJson())),
    );
    expect(restored.toJson(), l.toJson());
    expect(restored.balance('village', 'wood'), 5000);
    expect(
      () => restored.balances('village')['wood'] = 0,
      throwsUnsupportedError,
    );
  });
  test('Corrupt material creation and reverse causal transfers rejected', () {
    final l = funded();
    final raw = l.toJson();
    raw['accounts']['village']['wood'] += 1;
    expect(() => MaterialLedger.fromJson(raw), throwsFormatException);
    final before = l.toJson();
    expect(
      () => l.transfer(
        id: 'reverse',
        from: 'village',
        to: 'source:harvest',
        amounts: {'food': 1},
      ),
      throwsStateError,
    );
    expect(l.toJson(), before);
  });
  test('Balanced forgery and fabricated receipts fail journal replay', () {
    final l = funded();
    final raw = l.toJson();
    raw['accounts']['village']['wood'] += 1;
    raw['accounts']['source:harvest']['wood'] -= 1;
    expect(() => MaterialLedger.fromJson(raw), throwsFormatException);
    final duplicate = l.toJson();
    duplicate['operations'].add(duplicate['operations'].first);
    expect(() => MaterialLedger.fromJson(duplicate), throwsFormatException);
  });
  test(
    'Calculated decimal costs tolerate floating noise but never charge zero for positive fractions',
    () {
      expect(Quantity.fromNumber(0.1 + 0.2).millis, 300);
      expect(() => Quantity.fromNumber(0.0001), throwsFormatException);
      expect(
        () => validateMaterialCosts({
          'events': [
            {
              'costs': {'wood': 0.0001},
            },
          ],
        }),
        throwsFormatException,
      );
    },
  );
}
