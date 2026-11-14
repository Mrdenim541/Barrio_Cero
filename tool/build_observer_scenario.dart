import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:barrio_cero_eras/session/session_controller.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

/// Reproducible product-created world, with no injected supplies or choices.
/// The reference advances the same frozen rules for a native worker comparison.
Future<void> main() async {
  final directory = Directory('build/validation/observer-scenario')
    ..createSync(recursive: true);
  final values = <String, String>{};
  final session = SessionController(
    read: (key, {backup = false}) async => values[key],
    write: (key, value) async {
      values[key] = value;
    },
    loadCore: () => File('assets/content/core.json').readAsString(),
  );
  await session.createWorld(
    seed: 17,
    size: 64,
    origin: 'prehistory',
    extraordinary: false,
  );
  final source = values['world_0']!;
  File('${directory.path}/initial.checkpoint.json').writeAsStringSync(source);
  final initial = session.worldCopy()!;
  final reference = session.worldCopy()!;
  final simulation = Simulation(reference)
    ..registerContent(session.snapshot!.content);
  final advanced = simulation.advanceDays(360);
  reference.validate();
  if (advanced != 360 ||
      reference.controlledId != null ||
      reference.commandReceipts.isNotEmpty) {
    throw StateError('The zero-input observer reference failed');
  }
  File(
    '${directory.path}/one-year-world.json',
  ).writeAsStringSync(jsonEncode(reference.toJson()));
  Map<String, Object> metrics(WorldState w) => {
    'day': w.day,
    'population': w.populationState!.total,
    'sites': w.societies.fold<int>(0, (n, s) => n + s.sites.length),
    'technologies': w.societies.fold<int>(0, (n, s) => n + s.tech.length),
    'playerOrders': w.commandReceipts.length,
  };
  final result = {
    'source':
        'SessionController.createWorld with default autonomy; no world edits',
    'seed': 17,
    'size': 64,
    'origin': 'prehistory',
    'extraordinary': false,
    'rulesVersion': initial.rulesVersion,
    'initialCheckpointSha256': sha256.convert(utf8.encode(source)).toString(),
    'initial': metrics(initial),
    'oneYear': metrics(reference),
    'oneYearCanonicalSha256': sha256
        .convert(utf8.encode(reference.canonical()))
        .toString(),
    'reference': 'one-year-world.json',
    'scope': 'One reproducible year, not long-matrix or full-game acceptance',
  };
  File('${directory.path}/metadata.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(result)}\n',
  );
  stdout.writeln(jsonEncode(result));
  session.dispose();
}
