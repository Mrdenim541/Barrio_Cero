import 'dart:convert';
import 'dart:io';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'fixtures.dart';

/// Declared regression fixture: old routes already occupy every adult while
/// stored water has run out. Conversion may change staffing, never population,
/// inventories, geography or the outstanding caravan cargo.
void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Output checkpoint path required');
  final w = WorldState.generate(seed: 73, size: 64, extraordinary: false);
  w.rulesVersion = 9;
  final town = w.controlled;
  town.children = 12;
  town.adults = 8;
  town.elders = 0;
  town.health = 100;
  town.built = {'farm': 2, 'well': 1, 'house': 4};
  town.sites = [];
  town.ensureSites();
  town.resources['food'] = 1000;
  town.resources['water'] = 1000;
  town.resources['textiles'] = 100;
  town.policy.trade = false;
  town.policy.expansion = false;
  fixturePopulation(w);
  final sim = Simulation(w);
  for (final neighbor in w.societies.skip(1).take(4)) {
    town.relations[neighbor.id] = 50;
    if (!sim.command('trade', target: neighbor.id).ok) {
      throw StateError('No real route to ${neighbor.id}');
    }
  }
  town.resources['water'] = 0;
  w.validate();
  File(args.single).writeAsStringSync(Checkpoint.create(
    world: w,
    coreSource: File('assets/content/core.json').readAsStringSync(),
  ).encode());
  stdout.writeln(jsonEncode({
    'kind': 'declared initial-condition regression fixture',
    'sourceRules': 9,
    'population': town.population,
    'adults': town.adults,
    'transportWorkersReserved': town.transportWorkers,
    'actualRoutes': w.routes.length,
    'water': 0,
    'mapAltered': false,
    'runtimeAid': false,
  }));
}
