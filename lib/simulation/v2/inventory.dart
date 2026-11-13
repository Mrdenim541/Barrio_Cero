import 'dart:collection';
import 'materials.dart';

/// Compatibility view for existing rules; authoritative storage is integer.
class FixedInventory extends MapBase<String, double> {
  final Map<String, int> _millis = {};
  FixedInventory(Map<String, double> values) {
    addAll(values);
  }
  Map<String, int> get millis => Map.unmodifiable(_millis);
  @override
  double? operator [](Object? key) =>
      _millis[key] == null ? null : _millis[key]! / 1000;
  @override
  void operator []=(String key, double value) {
    if (!value.isFinite || value < 0 || value > 100000000) {
      throw const FormatException('Inventario inválido');
    }
    final amount = (value * 1000).round();
    Quantity(amount);
    _millis[key] = amount;
  }

  @override
  Iterable<String> get keys => _millis.keys;
  @override
  double? remove(Object? key) {
    final old = _millis.remove(key);
    return old == null ? null : old / 1000;
  }

  @override
  void clear() => _millis.clear();
}
