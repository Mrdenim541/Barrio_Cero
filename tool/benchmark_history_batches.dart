import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:barrio_cero_eras/session/history_slice.dart';
import 'package:barrio_cero_eras/session/session_controller.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

/// Development comparison using the real checkpoint path and temporary files.
/// It measures this host, not Android FPS or the reference phone.
Future<void> main(List<String> args) async {
  final years = args.isEmpty ? 10 : int.parse(args.first);
  if (![1, 10, 100].contains(years)) {
    throw ArgumentError('Usa 1, 10 o 100 años.');
  }
  final core = File('assets/content/core.json').readAsStringSync();
  final results = <Map<String, dynamic>>[];
  String? reference;
  for (final mode in ['monthly', 'adaptive']) {
    final directory = await Directory.systemTemp.createTemp('barrio-history-');
    var writes = 0, bytes = 0;
    final session = SessionController(
      loadCore: () async => core,
      read: (slot, {backup = false}) async {
        final file = File('${directory.path}/$slot');
        return await file.exists() ? file.readAsString() : null;
      },
      write: (slot, text) async {
        writes++;
        bytes += utf8.encode(text).length;
        final file = File('${directory.path}/$slot.tmp');
        await file.writeAsString(text, flush: true);
        await file.rename('${directory.path}/$slot');
      },
    );
    try {
      await session.createWorld(
        seed: 17,
        size: 64,
        origin: 'prehistory',
        extraordinary: false,
      );
      var lease = await session.beginHistory(years);
      final sim = Simulation(WorldState.fromJson(lease.snapshot.world))
        ..registerContent(lease.snapshot.content);
      writes = 0;
      bytes = 0;
      var batches = 0;
      final clock = Stopwatch()..start();
      while (true) {
        final slice = await advanceHistorySlice(
          sim,
          targetDay: lease.target,
          stopOnCrisis: false,
          maxDays: mode == 'monthly' ? 30 : 360,
        );
        final next = await session.commitHistoryBatch(
          lease,
          sim.world.toJson(),
          done: slice.done,
        );
        batches++;
        if (next == null) break;
        lease = next;
      }
      clock.stop();
      final canonical = sim.world.canonical();
      reference ??= canonical;
      if (reference != canonical) {
        throw StateError('La agrupación cambió la simulación.');
      }
      results.add({
        'mode': mode,
        'elapsedMs': clock.elapsedMilliseconds,
        'checkpointBatches': batches,
        'writes': writes,
        'bytesWritten': bytes,
        'day': sim.world.day,
        'extinct': sim.world.extinct,
        'canonicalSha256': sha256.convert(utf8.encode(canonical)).toString(),
      });
    } finally {
      session.dispose();
      await directory.delete(recursive: true);
    }
  }
  stdout.writeln(
    jsonEncode({
      'scope':
          'Single development-host AOT comparison, sequential runs; not phone performance',
      'yearsRequested': years,
      'seed': 17,
      'origin': 'prehistory',
      'extraordinary': false,
      'completeCanonicalMatch': true,
      'runs': results,
    }),
  );
}
