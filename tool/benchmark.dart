import 'dart:convert';
import 'dart:io';
import '../lib/simulation/engine.dart';

/// Actual measurements only. A run losing its initial population is explicitly
/// not evidence of sustained 32-settlement performance.
void main() {
  final pack = Map<String, dynamic>.from(
    jsonDecode(File('assets/content/core.json').readAsStringSync()),
  );
  for (final size in [64, 96]) {
    final world = WorldState.generate(seed: 73, size: size);
    world.controlledId = null;
    for (var i = world.societies.length; i < 32; i++) {
      var index = (i * 127) % (size * size);
      var attempts = 0;
      while (!world.tiles[index].passable ||
          world.societies.any((s) => s.x == index % size && s.y == index ~/ size)) {
        index = (index + 1) % (size * size);
        if (++attempts > size * size) throw StateError('No viable benchmark location');
      }
      final s = Society('bench$i', 'Puesto $i', 'cooperativa', index % size, index ~/ size);
      final leader = Person('benchLeader$i', 'Vera $i', 'dirigente', -30 * 360, traitNames[i % 12]);
      s.people = [leader];
      s.leaderId = leader.id;
      s.ensureSites();
      world.societies.add(s);
    }
    world.validate();
    final sim = Simulation(world)..registerContent(pack);
    final watch = Stopwatch()..start();
    var sustainedDays = 0;
    var largestYearMicros = 0;
    var minLivingSettlements = 32;
    while (world.day < 36000 && !world.extinct) {
      final year = Stopwatch()..start();
      final advanced = sim.advanceDays(360, delegateDecisions: true);
      year.stop();
      world.validate();
      if (year.elapsedMicroseconds > largestYearMicros) largestYearMicros = year.elapsedMicroseconds;
      final living = world.societies.where((s) => s.alive).length;
      if (living < minLivingSettlements) minLivingSettlements = living;
      if (minLivingSettlements >= 32) sustainedDays += advanced;
      if (advanced < 360 && !world.extinct) throw StateError('Unexpected benchmark interruption');
    }
    watch.stop();
    print(jsonEncode({
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'processors': Platform.numberOfProcessors,
      'dart': Platform.version,
      'map': size,
      'seed': 73,
      'initialSettlements': 32,
      'minimumLivingSettlements': minLivingSettlements,
      'requestedDays': 36000,
      'simulatedDays': world.day,
      'terminal': world.extinct ? 'global_extinction' : 'target_reached',
      'daysWithAtLeast32LivingSettlements': sustainedDays,
      'sustained32SettlementScenario': sustainedDays == 36000,
      'milliseconds': watch.elapsedMilliseconds,
      'slowestYearMicroseconds': largestYearMicros,
      'rssBytes': ProcessInfo.currentRss,
      'peakProcessRssBytes': ProcessInfo.maxRss,
      'saveBytes': utf8.encode(jsonEncode(world.toJson())).length,
      'livingSettlements': world.societies.where((s) => s.alive).length,
      'historyEntries': world.chronicle.length,
      'pending': world.pending.length,
      'measuresFps': false,
    }));
  }
}
