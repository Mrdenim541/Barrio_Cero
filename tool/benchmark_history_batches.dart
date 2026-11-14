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
  final modes = args.length > 1
      ? args[1].split(',')
      : ['adaptive', 'historical'];
  if (modes.any((m) => !['adaptive', 'historical'].contains(m))) {
    throw ArgumentError('Modo desconocido');
  }
  for (final mode in modes) {
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
        localLife: args.contains('--local-life'),
      );
      var lease = await session.beginHistory(years);
      final sim = Simulation(WorldState.fromJson(lease.snapshot.world))
        ..registerContent(lease.snapshot.content);
      writes = 0;
      bytes = 0;
      var batches = 0;
      var calculationMicros = 0, snapshotMicros = 0, commitMicros = 0;
      final clock = Stopwatch()..start();
      while (true) {
        final phase = Stopwatch()..start();
        final slice = await advanceHistorySlice(
          sim,
          targetDay: lease.target,
          stopOnCrisis: false,
          maxDays: mode == 'adaptive' ? 360 : 1800,
        );
        calculationMicros += phase.elapsedMicroseconds;
        phase.reset();
        final snapshot = sim.world.toJson();
        snapshotMicros += phase.elapsedMicroseconds;
        phase.reset();
        final next = await session.commitHistoryBatch(
          lease,
          snapshot,
          done: slice.done,
        );
        commitMicros += phase.elapsedMicroseconds;
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
        'calculationMs': calculationMicros / 1000,
        'snapshotMs': snapshotMicros / 1000,
        'commitMs': commitMicros / 1000,
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
      'completeCanonicalMatch': results.length > 1 ? true : null,
      'localLifeEnabled': args.contains('--local-life'),
      'runs': results,
    }),
  );
}
