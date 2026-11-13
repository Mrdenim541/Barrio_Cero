import 'dart:convert';

/// Rule-v2 quantities use thousandths. Decimal input is exact; no double rounding.
class Quantity {
  static const maxMillis = 1000000000000;
  final int millis;
  Quantity(this.millis) {
    if (millis.abs() > maxMillis) throw RangeError('Cantidad fuera de rango');
  }
  factory Quantity.parse(String text) {
    if (!RegExp(r'^-?\d+(\.\d{1,3})?$').hasMatch(text)) {
      throw const FormatException('Se admiten hasta tres decimales');
    }
    final negative = text.startsWith('-');
    final parts = (negative ? text.substring(1) : text).split('.');
    final whole = int.parse(parts.first);
    if (whole > maxMillis ~/ 1000) {
      throw RangeError('Cantidad fuera de rango');
    }
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(3, '0'));
    return Quantity((whole * 1000 + fraction) * (negative ? -1 : 1));
  }
  factory Quantity.fromNumber(num value) {
    if (!value.isFinite || value.abs() > maxMillis / 1000) {
      throw const FormatException('Cantidad fuera de rango');
    }
    final scaled = value * 1000;
    final rounded = scaled.round();
    if ((scaled - rounded).abs() > 0.000001 || (value != 0 && rounded == 0)) {
      throw const FormatException('Cantidad no representable en milésimas');
    }
    return Quantity(rounded);
  }
  @override
  String toString() {
    final value = millis.abs();
    return '${millis < 0 ? '-' : ''}${value ~/ 1000}.${(value % 1000).toString().padLeft(3, '0')}';
  }
}

/// Double-entry material book for rule-v2. Ordinary accounts cannot overdraw.
/// Source/sink accounts explicitly identify production, extraction or loss.
/// One transfer is atomic across all resources and idempotent by operation ID.
class MaterialLedger {
  final Set<String> resources;
  final Map<String, Map<String, int>> _accounts = {};
  final Map<String, String> _receipts = {};
  MaterialLedger(Set<String> resources)
    : resources = Set.unmodifiable(resources) {
    if (resources.isEmpty || resources.any((r) => !_validId(r))) {
      throw const FormatException('Catálogo de recursos inválido');
    }
  }
  static bool _validId(String id) =>
      RegExp(r'^[a-zA-Z0-9_.:-]{1,160}$').hasMatch(id);
  int balance(String account, String resource) =>
      _accounts[account]?[resource] ?? 0;
  Map<String, int> balances(String account) =>
      Map.unmodifiable(_accounts[account] ?? {});

  /// Returns false for an identical retry. Rejections leave the book untouched.
  bool transfer({
    required String id,
    required String from,
    required String to,
    required Map<String, int> amounts,
  }) {
    if (!_validId(id) ||
        !_validId(from) ||
        !_validId(to) ||
        from == to ||
        amounts.isEmpty) {
      throw const FormatException('Transferencia inválida');
    }
    final keys = amounts.keys.toList()..sort();
    for (final r in keys) {
      final value = amounts[r]!;
      if (!resources.contains(r) || value <= 0 || value > Quantity.maxMillis) {
        throw const FormatException('Material o cantidad inválidos');
      }
    }
    final signature = jsonEncode([
      from,
      to,
      {for (final r in keys) r: amounts[r]},
    ]);
    final receipt = _receipts[id];
    if (receipt != null) {
      if (receipt != signature) {
        throw StateError('Identificador de operación reutilizado');
      }
      return false;
    }
    final source = Map<String, int>.from(_accounts[from] ?? {});
    final destination = Map<String, int>.from(_accounts[to] ?? {});
    for (final r in keys) {
      final debit = (source[r] ?? 0) - amounts[r]!;
      final credit = (destination[r] ?? 0) + amounts[r]!;
      if (!from.startsWith('source:') && debit < 0) {
        throw StateError('Reservas insuficientes');
      }
      if (debit.abs() > Quantity.maxMillis ||
          credit.abs() > Quantity.maxMillis) {
        throw RangeError('Inventario fuera de rango');
      }
      if (to.startsWith('source:') || from.startsWith('sink:')) {
        throw StateError('Dirección causal inválida');
      }
      source[r] = debit;
      destination[r] = credit;
    }
    _accounts[from] = source;
    _accounts[to] = destination;
    _receipts[id] = signature;
    return true;
  }

  Map<String, dynamic> toJson() {
    final names = _accounts.keys.toList()..sort();
    final ids = _receipts.keys.toList();
    final catalog = resources.toList()..sort();
    return {
      'version': 1,
      'resources': catalog,
      'accounts': {
        for (final name in names)
          name: {
            for (final r in (_accounts[name]!.keys.toList()..sort()))
              r: _accounts[name]![r],
          },
      },
      'operations': [
        for (final id in ids) {'id': id, 'signature': _receipts[id]},
      ],
    };
  }

  factory MaterialLedger.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['resources'] is! List ||
        json['accounts'] is! Map ||
        json['operations'] is! List) {
      throw const FormatException('Libro de materiales incompatible');
    }
    final catalog = json['resources'] as List;
    if (catalog.any((r) => r is! String) ||
        catalog.toSet().length != catalog.length) {
      throw const FormatException('Recursos duplicados o inválidos');
    }
    final result = MaterialLedger(catalog.cast<String>().toSet());
    final totals = <String, int>{};
    final accounts = json['accounts'] as Map;
    if (accounts.length > 100000 ||
        (json['operations'] as List).length > 1000000) {
      throw const FormatException('Libro demasiado grande');
    }
    for (final entry in accounts.entries) {
      if (entry.key is! String || !_validId(entry.key) || entry.value is! Map) {
        throw const FormatException('Cuenta inválida');
      }
      final values = <String, int>{};
      for (final amount in (entry.value as Map).entries) {
        if (!result.resources.contains(amount.key) ||
            amount.value is! int ||
            (amount.value as int).abs() > Quantity.maxMillis ||
            (!entry.key.startsWith('source:') && amount.value < 0)) {
          throw const FormatException('Saldo inválido');
        }
        values[amount.key] = amount.value;
        totals[amount.key] = (totals[amount.key] ?? 0) + amount.value as int;
      }
      result._accounts[entry.key] = values;
    }
    if (totals.values.any((value) => value != 0)) {
      throw const FormatException('Material sin origen o destino');
    }
    final replay = MaterialLedger(result.resources);
    try {
      for (final op in json['operations'] as List) {
        if (op is! Map || op['id'] is! String || op['signature'] is! String) {
          throw const FormatException('Operación inválida');
        }
        final parts = jsonDecode(op['signature']);
        if (parts is! List ||
            parts.length != 3 ||
            parts[0] is! String ||
            parts[1] is! String ||
            parts[2] is! Map) {
          throw const FormatException('Operación inválida');
        }
        final amounts = <String, int>{};
        for (final e in (parts[2] as Map).entries) {
          if (e.key is! String || e.value is! int) {
            throw const FormatException('Cantidad inválida');
          }
          amounts[e.key] = e.value;
        }
        if (!replay.transfer(
          id: op['id'],
          from: parts[0],
          to: parts[1],
          amounts: amounts,
        )) {
          throw const FormatException('Operación duplicada');
        }
      }
    } catch (e) {
      throw FormatException('Historial de materiales inválido: $e');
    }
    if (replay._accounts.length != result._accounts.length) {
      throw const FormatException('Cuentas sin historial');
    }
    for (final entry in result._accounts.entries) {
      final actual = replay._accounts[entry.key];
      if (actual == null ||
          actual.length != entry.value.length ||
          entry.value.entries.any((e) => actual[e.key] != e.value)) {
        throw const FormatException('Los saldos no corresponden al historial');
      }
    }
    return replay;
  }
}

/// Validate declared costs before binding a package to fixed-material rules.
void validateMaterialCosts(dynamic node) {
  if (node is List) {
    for (final value in node) {
      validateMaterialCosts(value);
    }
  }
  if (node is Map) {
    for (final entry in node.entries) {
      if (entry.key == 'cost' || entry.key == 'costs') {
        final raw = entry.value;
        if (raw is num) {
          Quantity.fromNumber(raw);
        }
        if (raw is Map) {
          for (final amount in raw.values) {
            if (amount is num) {
              Quantity.fromNumber(amount);
            }
            if (amount is Map) {
              for (final key in ['base', 'perUnit']) {
                if (amount[key] is num) Quantity.fromNumber(amount[key]);
              }
            }
          }
        }
      }
      validateMaterialCosts(entry.value);
    }
  }
}
