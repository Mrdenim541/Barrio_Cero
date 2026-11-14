import 'dart:convert';
import 'dart:io';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

/// Declared verification opening: one community starts with an illness and a
/// pending request. Counts, birthdays, inventory and geography are not changed;
/// neither resources nor residents are injected while the scenario is played.
void main(List<String> args){
  if(args.length!=1)throw ArgumentError('Output checkpoint path required');
  final core=File('assets/content/core.json').readAsStringSync();
  for(final seed in [17,31,42,73]){
    final checkpoint=Checkpoint.create(world:WorldState.generate(seed:seed,size:64,extraordinary:false),coreSource:core);
    final w=checkpoint.world,sim=Simulation(checkpoint.world)..registerContent(checkpoint.content);
    final others=w.societies.where((s)=>s.id!='s0'&&sim.findPath(s,w.controlled).isNotEmpty).toList();if(others.isEmpty)continue;
    final origin=others.first;origin.health=30;
    final cause=sim.record(origin,'Una fiebre alcanza la comunidad','Una enfermedad ficticia dificulta el trabajo y algunos residentes solicitan protección.','salud');
    w.pending.add(ScheduledEvent('scenario-refugee-choice','content_choice','s0',3600000,cause:cause.id,data:{'eventId':'refugee_letter'}));
    if(!sim.eligibleEvents('s0').any((e)=>e['id']=='refugee_letter')||sim.previewMigration('s0',5)?.source!=origin.id)throw StateError('The declared opening does not meet actual migration rules');
    w.validate();File(args.single).writeAsStringSync(Checkpoint.create(world:w,coreSource:core).encode());
    stdout.writeln(jsonEncode({'kind':'declared initial-condition test fixture','seed':seed,'rules':w.rulesVersion,'initialCondition':{'source':origin.id,'health':30,'reason':'illness'},'population':w.populationState!.total,'resourcesInjectedDuringPlay':false,'peopleInjected':false,'mapAltered':false,'pendingDefinition':'refugee_letter'}));return;
  }
  throw StateError('No connected source in the candidate seeds');
}
