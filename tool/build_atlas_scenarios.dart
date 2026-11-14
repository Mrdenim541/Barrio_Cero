import 'dart:convert';
import 'dart:io';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

/// Reproducible normal openings and their autonomous year, not staged rewards.
void main() {
  final out = Directory('build/validation/atlas-scenarios')
    ..createSync(recursive: true);
  final source = File('assets/content/core.json').readAsStringSync();
  final content = jsonDecode(source) as Map<String, dynamic>;
  final records = <Map<String, dynamic>>[];
  for (final origin in ['prehistory', 'reconstruction']) {
    final generated = WorldState.generate(
      seed: 73,
      size: 96,
      origin: origin,
      geographyVersion: 2,
      extraordinary: false,
    )..controlledId = null;
    for (final s in generated.societies) {
      s.localLife = LocalLife(0)
        ..advance(
          0,
          [for (final p in s.people) p.toJson()],
          [for (final b in s.sites) b.toJson()],
        );
    }
    final opening = Checkpoint.create(
      world: generated,
      coreSource: source,
      stopCrisis: false,
    );
    File(
      '${out.path}/$origin-initial.json',
    ).writeAsStringSync(opening.encode());
    final year = WorldState.fromJson(opening.world.toJson());
    (Simulation(year)..registerContent(content)).advanceDays(360);
    year.validate();
    File('${out.path}/$origin-year.json').writeAsStringSync(
      Checkpoint.create(
        world: year,
        coreSource: source,
        stopCrisis: false,
      ).encode(),
    );
    records.add({
      'origin': origin,
      'seed': 73,
      'size': 96,
      'geographyVersion': 2,
      'initialSites': generated.societies.fold<int>(
        0,
        (n, s) => n + s.sites.length,
      ),
      'yearSites': year.societies.fold<int>(0, (n, s) => n + s.sites.length),
      'initialPopulation': generated.societies.fold<int>(
        0,
        (n, s) => n + s.population,
      ),
      'yearPopulation': year.societies.fold<int>(0, (n, s) => n + s.population),
      'firstBiome': generated
          .tiles[generated.societies.first.y * 96 + generated.societies.first.x]
          .biome,
      'finalDay': year.day,
      'playerCommands': year.commandReceipts.length,
      'runtimeInjections': false,
    });
  }
  final metadata = const JsonEncoder.withIndent('  ').convert({
    'scope': 'normal starting scenarios, no user orders or hidden rewards',
    'scenarios': records,
  });
  File('${out.path}/metadata.json').writeAsStringSync('$metadata\n');
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(records));
}
