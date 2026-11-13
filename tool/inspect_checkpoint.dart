import 'dart:convert';
import 'dart:io';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    throw ArgumentError('Usage: dart run tool/inspect_checkpoint.dart <save.json>');
  }
  final checkpoint = Checkpoint.decode(File(arguments.single).readAsStringSync());
  final world = checkpoint.world;
  world.validate();
  stdout.writeln(jsonEncode({
    'valid': true,
    'seed': world.seed,
    'map': world.size,
    'day': world.day,
    'target': checkpoint.target,
    'controlledId': world.controlledId,
    'commandReceipts': world.commandReceipts.length,
    'societies': world.societies.length,
    'controlled': world.controlled.toJson(),
  }));
}
