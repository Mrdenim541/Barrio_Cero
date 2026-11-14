import 'fixtures.dart';
import 'dart:convert';
import 'dart:io';
import 'package:barrio_cero_eras/simulation/engine.dart';

/// Actual measurements only. A run losing its initial population is explicitly
/// not evidence of sustained 32-settlement performance.
void main() {
  var sustainedWorkload = true;
  final pack = Map<String, dynamic>.from(
    jsonDecode(File('assets/content/core.json').readAsStringSync()),
  );
  for (final size in [64]) {
    final world = WorldState.generate(seed: 73, size: size);
    world.controlledId = null;
    for (var i = world.societies.length; i < 32; i++) {
      var index = (i * 127) % (size * size);
      var attempts = 0;
      while (!world.tiles[index].passable ||
          world.societies.any(
            (s) => s.x == index % size && s.y == index ~/ size,
          )) {
        index = (index + 1) % (size * size);
        if (++attempts > size * size) {
          throw StateError('No viable benchmark location');
        }
      }
      final s = Society(
        'bench$i',
        'Puesto $i',
        'cooperativa',
        index % size,
        index ~/ size,
        materialRules: world.societies.first.materialRules,
      );
      final leader = Person(
        'benchLeader$i',
        'Vera $i',
        'dirigente',
        -30 * 360,
        traitNames[i % 12],
      );
      s.people = [leader];
      s.leaderId = leader.id;
      s.ensureSites();
      world.societies.add(s);
      world.entities?.reconcile(world.societies.map((s) => s.identityView()));
    }
    fixturePopulation(world);world.validate();
    final sim = Simulation(world)..registerContent(pack);
    final watch = Stopwatch()..start();
    final recent=<String,List<Map<String,dynamic>>>{};
    var sustainedDays = 0;
    var largestYearMicros = 0;
    var minLivingSettlements = 32;
    while (world.day < 36000 && !world.extinct) {
      final year = Stopwatch()..start();
      // Count the populated workload daily: annual samples could miss a
      // collapse and later recolonization within the same year.
      var advanced = 0;
      for (var day = 0; day < 360 && !world.extinct; day++) {
        final actual = sim.advanceDays(1, delegateDecisions: true);
        if (actual != 1) throw StateError('Unexpected benchmark interruption');
        advanced += actual;
        if(world.day%30==0){for(final town in world.societies){final rows=recent.putIfAbsent(town.id,()=>[]);rows.add({'day':world.day,'population':town.population,'adults':town.adults,'children':town.children,'elders':town.elders,'health':town.health,'morale':town.morale,'food':town.resources['food'],'water':town.resources['water'],'workers':town.workers,'transportWorkers':town.transportWorkers});if(rows.length>24)rows.removeAt(0);}}
        final fallen=world.societies.where((s)=>!s.alive).toList();
        if(fallen.isNotEmpty){
          final town=fallen.first;stdout.writeln(jsonEncode({'diagnosticOnly':true,'day':world.day,'fallenId':town.id,'fallenName':town.name,'recent':recent[town.id], 'relatedHistory':world.chronicle.where((h)=>h.societyId==town.id||h.title.contains(town.name)||h.text.contains(town.name)).toList().reversed.take(30).map((h)=>h.toJson()).toList()}));
          File('population-first-loss-world.json').writeAsStringSync(jsonEncode(world.toJson()));return;
        }
        final living = world.societies.where((s) => s.alive).length;
        if (living < minLivingSettlements) minLivingSettlements = living;
        if (living >= 32) sustainedDays += actual;
      }
      year.stop();
      world.validate();
      if (year.elapsedMicroseconds > largestYearMicros) {
        largestYearMicros = year.elapsedMicroseconds;
      }
      if (advanced < 360 && !world.extinct) {
        throw StateError('Unexpected benchmark interruption');
      }
    }
    watch.stop();
    sustainedWorkload &= sustainedDays == 36000 && minLivingSettlements >= 32;
    stdout.writeln(
      jsonEncode({
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
        'sustained32SettlementScenario':
            sustainedDays == 36000 && minLivingSettlements >= 32,
        'populationSampleIntervalDays': 1,
        'milliseconds': watch.elapsedMilliseconds,
        'slowestYearMicroseconds': largestYearMicros,
        'rssBytes': ProcessInfo.currentRss,
        'peakProcessRssBytes': ProcessInfo.maxRss,
        'saveBytes': utf8.encode(jsonEncode(world.toJson())).length,
        'livingSettlements': world.societies.where((s) => s.alive).length,
        'historyEntries': world.chronicle.length,
        'pending': world.pending.length,
        'measuresFps': false,
      }),
    );
  }
  // Measurements are retained, but an underpopulated scenario cannot pass the
  // acceptance runner as proof of the required 32-settlement workload.
  if (!sustainedWorkload) {
    stderr.writeln(
      'FAIL: the full century did not sustain 32 living settlements.',
    );
    exitCode = 1;
  }
}
