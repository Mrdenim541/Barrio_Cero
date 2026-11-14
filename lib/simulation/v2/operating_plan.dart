import 'dart:math' as math;
import 'exact_math.dart';

int _floor(int amount, int part, int whole) => scaledFloor(amount, part, whole);
int _ceil(int amount, int part, int whole) => scaledCeil(amount, part, whole);

/// Capacity is an existing productive site, not a building project or dwelling.
/// Labor is expressed in thousandths of one adult's working day. Production
/// and inputs are material thousandths per complete two-worker operating unit.
class ProducerCapacity {
  final String id;
  final int units;
  final Map<String, int> outputs, inputs;
  ProducerCapacity(
    this.id,
    this.units,
    Map<String, int> outputs, {
    Map<String, int> inputs = const {},
  }) : outputs = Map.unmodifiable(outputs),
       inputs = Map.unmodifiable(inputs) {
    if (id.isEmpty ||
        units < 0 ||
        units > 100000 ||
        outputs.values.any((n) => n < 0) ||
        inputs.values.any((n) => n < 0)) {
      throw const FormatException('Capacidad productiva inválida');
    }
  }
  int get laborCapacity => units * 2000;
}

class DailyProduction {
  final Map<String, int> opening,
      closing,
      produced,
      consumed,
      wasted,
      allocations;
  final int availableLabor, essentialLabor;
  final bool sustainsNeeds;
  DailyProduction._(
    this.opening,
    this.closing,
    this.produced,
    this.consumed,
    this.wasted,
    this.allocations,
    this.availableLabor,
    this.essentialLabor,
    this.sustainsNeeds,
  );
  int get laborUsed => allocations.values.fold(0, (a, b) => a + b);
  void validate() {
    if (availableLabor < 0 ||
        essentialLabor < 0 ||
        laborUsed > availableLabor ||
        allocations.values.any((v) => v < 0)) {
      throw const FormatException('Trabajo productivo duplicado');
    }
    if (closing.length != opening.length ||
        closing.keys.any((r) => !opening.containsKey(r)) ||
        [produced, consumed, wasted].any(
          (m) =>
              m.entries.any((e) => !opening.containsKey(e.key) || e.value < 0),
        ) ||
        opening.values.any((v) => v < 0)) {
      throw const FormatException('Recursos de producción inválidos');
    }
    for (final r in opening.keys) {
      if ((closing[r] ?? -1) < 0 ||
          opening[r]! +
                  (produced[r] ?? 0) -
                  (consumed[r] ?? 0) -
                  (wasted[r] ?? 0) !=
              closing[r]) {
        throw const FormatException('Balance de producción incoherente');
      }
    }
  }

  factory DailyProduction.fromJson(Map<String, dynamic> raw) {
    const keys = {
      'opening',
      'closing',
      'produced',
      'consumed',
      'wasted',
      'allocations',
      'availableLabor',
      'essentialLabor',
      'sustainsNeeds',
    };
    if (raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        raw['availableLabor'] is! int ||
        raw['essentialLabor'] is! int ||
        raw['sustainsNeeds'] is! bool) {
      throw const FormatException('Registro productivo incompatible');
    }
    final maps = <Map<String, int>>[];
    for (final key in [
      'opening',
      'closing',
      'produced',
      'consumed',
      'wasted',
      'allocations',
    ]) {
      final value = raw[key];
      if (value is! Map ||
          value.entries.any((e) => e.key is! String || e.value is! int)) {
        throw const FormatException('Cantidades productivas incompatibles');
      }
      maps.add(Map.unmodifiable(Map<String, int>.from(value)));
    }
    final result = DailyProduction._(
      maps[0],
      maps[1],
      maps[2],
      maps[3],
      maps[4],
      maps[5],
      raw['availableLabor'],
      raw['essentialLabor'],
      raw['sustainsNeeds'],
    );
    result.validate();
    return result;
  }
  Map<String, dynamic> toJson() => {
    'opening': opening,
    'closing': closing,
    'produced': produced,
    'consumed': consumed,
    'wasted': wasted,
    'allocations': allocations,
    'availableLabor': availableLabor,
    'essentialLabor': essentialLabor,
    'sustainsNeeds': sustainsNeeds,
  };
}

/// Pure query: uses copies, has no PRNG and cannot reserve workers or materials
/// in the live world. The engine commits the returned balances once per day.
DailyProduction planProduction({
  required Map<String, int> stocks,
  required Iterable<ProducerCapacity> producers,
  required int workers,
  required Map<String, int> minimumYield,
  required Map<String, int> reserveStocks,
  required Map<String, int> otherTargets,
  bool educated = false,
  List<String> priorities = const [
    'medicine',
    'tools',
    'knowledge',
    'wood',
    'stone',
    'metal',
    'textiles',
    'energy',
    'fuel',
    'crystal',
  ],
}) {
  if (workers < 0 ||
      stocks.values.any((n) => n < 0) ||
      minimumYield.values.any((n) => n < 0) ||
      reserveStocks.values.any((n) => n < 0) ||
      otherTargets.values.any((n) => n < 0)) {
    throw const FormatException('Disponibilidad productiva inválida');
  }
  final planner = _Planner(stocks, producers.toList(), workers * 1000);
  // Plan minimum survival capacity first. If labor is insufficient, both vital
  // needs receive a proportional share instead of one consuming the whole day.
  final needed = <String, int>{};
  var impossible = false;
  final vital = minimumYield.keys.toList()..sort();
  for (final resource in vital) {
    var remaining = minimumYield[resource]!;
    final candidates =
        planner.jobs.where((j) => (j.outputs[resource] ?? 0) > 0).toList()
          ..sort((a, b) {
            final n = b.outputs[resource]!.compareTo(a.outputs[resource]!);
            return n == 0 ? a.id.compareTo(b.id) : n;
          });
    for (final j in candidates) {
      if (remaining <= 0) break;
      final work = math.min(
        j.laborCapacity,
        _ceil(remaining, 2000, j.outputs[resource]!),
      );
      needed[j.id] = math.max(needed[j.id] ?? 0, work);
      remaining -= math.min(
        remaining,
        _floor(j.outputs[resource]!, work, 2000),
      );
    }
    if (remaining > 0) impossible = true;
  }
  final total = needed.values.fold<int>(0, (n, v) => n + v);
  final essential = impossible ? math.max(total, workers * 1000 + 1) : total;
  final budget = planner.remaining;
  for (final id in (needed.keys.toList()..sort())) {
    final amount = total <= budget
        ? needed[id]!
        : _floor(needed[id]!, budget, total);
    planner.offer(planner.byId[id]!, amount);
  }
  // Rounding or unavailable recipe inputs can leave a little work unassigned.
  // Existing capacities may use it, still subject to the same shared budget.
  for (final r in vital) {
    planner.fill(r, stocks[r]! + minimumYield[r]!);
  }
  final sustains = vital.every(
    (r) => planner.balance[r]! >= stocks[r]! + minimumYield[r]!,
  );
  // Reserve replenishment is secondary to meeting today's needs.
  final reserveOrder = List<String>.from(vital)
    ..sort((a, b) {
      final aa = _floor(stocks[a]!, 1000, math.max(1, minimumYield[a]!)),
          bb = _floor(stocks[b]!, 1000, math.max(1, minimumYield[b]!));
      return aa == bb ? a.compareTo(b) : aa.compareTo(bb);
    });
  for (final r in reserveOrder) {
    final deficit = math.max(0, (reserveStocks[r] ?? 0) - stocks[r]!);
    planner.fill(r, stocks[r]! + minimumYield[r]! + (deficit / 30).ceil());
  }
  // Two bounded passes permit a producer earlier in the catalog to use inputs
  // produced by a later recipe. There is no recursive production cascade.
  for (var pass = 0; pass < 2; pass++) {
    for (final r in priorities) {
      if (vital.contains(r) || !stocks.containsKey(r)) continue;
      final deficit = math.max(0, (otherTargets[r] ?? 0) - stocks[r]!);
      if (deficit > 0) planner.fill(r, stocks[r]! + (deficit / 30).ceil());
    }
  }
  // Gathering consumes only remaining work; occupied housing consumes none.
  final woodMissing = math.max(
    0,
    (otherTargets['wood'] ?? 0) - planner.balance['wood']!,
  );
  final gather = math.min(
    planner.remaining,
    _ceil((woodMissing / 30).ceil(), 1000, 15),
  );
  if (gather > 0) {
    planner.allocations['work:gather_wood'] = gather;
    planner.remaining -= gather;
    planner.credit('wood', _floor(15, gather, 1000));
  }
  final worked = planner.allocations.values.fold<int>(0, (n, v) => n + v);
  // Learning by doing is an explicit coproduct of performed work, not a second
  // job performed by the same adults. Schools retain their declared output.
  planner.credit('knowledge', _floor(educated ? 12 : 6, worked, 1000));
  final result = DailyProduction._(
    Map.unmodifiable(stocks),
    Map.unmodifiable(planner.balance),
    Map.unmodifiable(planner.produced),
    Map.unmodifiable(planner.consumed),
    Map.unmodifiable(planner.wasted),
    Map.unmodifiable(planner.allocations),
    workers * 1000,
    essential,
    sustains,
  );
  result.validate();
  return result;
}

class _Planner {
  final List<ProducerCapacity> jobs;
  final Map<String, ProducerCapacity> byId;
  final Map<String, int> balance,
      produced = {},
      consumed = {},
      wasted = {},
      allocations = {};
  int remaining;
  _Planner(Map<String, int> stocks, this.jobs, this.remaining)
    : balance = Map.from(stocks),
      byId = {for (final j in jobs) j.id: j} {
    if (byId.length != jobs.length) {
      throw const FormatException('Capacidad duplicada');
    }
    for (final j in jobs) {
      if ([
        ...j.outputs.keys,
        ...j.inputs.keys,
      ].any((r) => !balance.containsKey(r))) {
        throw const FormatException('Recurso productivo desconocido');
      }
    }
  }
  void credit(String resource, int amount) {
    if (amount <= 0) return;
    produced[resource] = (produced[resource] ?? 0) + amount;
    final room = math.max(0, 100000000 - balance[resource]!);
    final kept = math.min(room, amount);
    balance[resource] = balance[resource]! + kept;
    if (kept < amount) {
      wasted[resource] = (wasted[resource] ?? 0) + amount - kept;
    }
  }

  int offer(ProducerCapacity job, int requested) {
    final before = allocations[job.id] ?? 0;
    int after = math
        .min(
          job.laborCapacity,
          before + math.min(remaining, math.max(0, requested)),
        )
        .toInt();
    for (final input in job.inputs.entries) {
      if (input.value <= 0) continue;
      final paid = _ceil(input.value, before, 2000);
      after = math
          .min(after, _floor(balance[input.key]! + paid, 2000, input.value))
          .toInt();
    }
    final used = math.max(0, after - before);
    if (used == 0) return 0;
    for (final input in job.inputs.entries) {
      final cost =
          _ceil(input.value, after, 2000) - _ceil(input.value, before, 2000);
      balance[input.key] = balance[input.key]! - cost;
      consumed[input.key] = (consumed[input.key] ?? 0) + cost;
    }
    for (final output in job.outputs.entries) {
      credit(
        output.key,
        _floor(output.value, after, 2000) - _floor(output.value, before, 2000),
      );
    }
    allocations[job.id] = after;
    remaining -= used;
    return used;
  }

  void fill(String resource, int target) {
    if (balance[resource]! >= target || remaining == 0) return;
    final candidates =
        jobs.where((j) => (j.outputs[resource] ?? 0) > 0).toList()
          ..sort((a, b) {
            final n = b.outputs[resource]!.compareTo(a.outputs[resource]!);
            return n == 0 ? a.id.compareTo(b.id) : n;
          });
    for (final j in candidates) {
      if (balance[resource]! >= target || remaining == 0) break;
      final previous = allocations[j.id] ?? 0;
      final already = _floor(j.outputs[resource]!, previous, 2000);
      final desired =
          _ceil(
            target - balance[resource]! + already,
            2000,
            j.outputs[resource]!,
          ) -
          previous;
      offer(j, desired);
    }
  }
}
