import 'dart:async';
import 'dart:isolate';

import '../simulation/engine.dart';

/// Each batch, including the final one, waits for durable confirmation. Cancel
/// requests stop at a daily boundary; they never acknowledge an unwritten batch.
void historyWorker(Map<String, dynamic> args) async {
  final send = args['port'] as SendPort;
  final controls = ReceivePort();
  var cancel = false;
  Completer<void>? confirmation;
  controls.listen((message) {
    if (message == 'cancel') cancel = true;
    if (message == 'ack' && confirmation != null && !confirmation.isCompleted) {
      confirmation.complete();
    }
  });
  send.send({'control': controls.sendPort});
  try {
    final world = WorldState.fromJson(
      Map<String, dynamic>.from(args['world'] as Map),
    );
    final sim = Simulation(world);
    if (args['content'] is Map) {
      sim.registerContent(Map<String, dynamic>.from(args['content'] as Map));
    }
    final target = args['target'] as int;
    final stop = args['stop'] as bool;
    while (world.day < target && !cancel) {
      final before = world.day;
      final days = (target - before).clamp(0, 30).toInt();
      sim.advanceDays(days, stopOnCrisis: stop, delegateDecisions: !stop);
      final done = world.day >= target || world.day < before + days;
      confirmation = Completer<void>();
      send.send({'world': world.toJson(), 'done': done, 'target': target});
      await confirmation.future;
      if (done) return;
      await Future<void>.delayed(Duration.zero);
    }
    confirmation = Completer<void>();
    send.send({
      'world': world.toJson(),
      'done': true,
      'cancelled': cancel,
      'target': target,
    });
    await confirmation.future;
  } catch (error) {
    send.send({'error': error.toString()});
  } finally {
    controls.close();
  }
}
