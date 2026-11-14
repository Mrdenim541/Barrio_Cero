import '../simulation/engine.dart';

/// A bounded amount of historical computation, independent of drawing or saves.
/// Wall time chooses checkpoints only; it never changes simulation rules.
class HistorySlice {
  final bool done, cancelled;
  final int advancedDays;
  const HistorySlice({
    required this.done,
    required this.cancelled,
    required this.advancedDays,
  });
}

Future<HistorySlice> advanceHistorySlice(
  Simulation simulation, {
  required int targetDay,
  required bool stopOnCrisis,
  bool Function()? isCancelled,
  int maxDays = 1800,
  Duration budget = const Duration(seconds: 1),
  void Function()? onQuantum,
}) async {
  if (maxDays < 1 || budget.isNegative) {
    throw ArgumentError('El lote requiere días y presupuesto válidos.');
  }
  final world = simulation.world;
  final startDay = world.day;
  final clock = Stopwatch()..start();
  var done = world.day >= targetDay || world.extinct;
  while (!done && !(isCancelled?.call() ?? false)) {
    final remaining = maxDays - (world.day - startDay);
    final days = (targetDay - world.day)
        .clamp(0, remaining.clamp(0, 30))
        .toInt();
    if (days == 0) break;
    final before = world.day;
    simulation.advance(
      AdvanceRequest(
        days: days,
        stopOnCrisis: stopOnCrisis,
        delegateDecisions: !stopOnCrisis,
      ),
    );
    done = world.day >= targetDay || world.extinct || world.day < before + days;
    onQuantum?.call();
    // Let the isolate receive cancellation, or the web UI handle input, between
    // simulation quanta. Nothing is published before the caller saves the slice.
    await Future<void>.delayed(Duration.zero);
    if (world.day - startDay >= maxDays || clock.elapsed >= budget) break;
  }
  return HistorySlice(
    done: done,
    cancelled: isCancelled?.call() ?? false,
    advancedDays: world.day - startDay,
  );
}
