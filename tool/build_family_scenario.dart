import 'dart:io';
import 'dart:convert';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

/// Native verification fixture generated only by ordinary daily rules. No
/// people, feelings, provisions, birthdays or PRNG draws are injected.
void main(List<String> arguments){
  if(arguments.length!=1)throw ArgumentError('Output checkpoint path required');
  final core=File('assets/content/core.json').readAsStringSync();
  final bound=Checkpoint.create(world:WorldState.generate(seed:31,size:64,origin:'prehistory'),coreSource:core);
  final world=bound.world,sim=Simulation(bound.world)..registerContent(bound.content);
  while(world.day<3600&&!world.extinct){
    sim.advanceDays(1);world.validate();
    if(world.socialState!.requests.values.any((r)=>r.settlement==world.controlledId&&r.status=='pending')&&world.controlled.housing>=world.controlled.population&&world.controlled.resources['wood']!>=4&&world.controlled.resources['food']!>=6){
      File(arguments.single).writeAsStringSync(Checkpoint.create(world:world,coreSource:core).encode());
      stdout.writeln(jsonEncode({'seed':31,'origin':world.origin,'day':world.day,'rules':world.rulesVersion,'population':world.populationState!.total,'generation':'ordinary daily rules; no fixture injections'}));return;
    }
  }
  throw StateError('No viable pending household in the ordinary scenario');
}
