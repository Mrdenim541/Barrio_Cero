import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/simulation/v2/materials.dart';
import 'package:barrio_cero_eras/session/history_worker.dart';

final core = jsonDecode(File('assets/content/core.json').readAsStringSync()) as Map<String,dynamic>;

WorldState opening() {
  final w = WorldState.generate(seed:17,size:64,extraordinary:false);
  // Declared six-cell corridor, functioning settlements and one real illness.
  w.tiles = w.tiles.map((t)=>Tile(t.x,t.y,0,t.richness)).toList();
  w.society('s1')!..x=w.controlled.x+6 ..y=w.controlled.y ..health=30;
  for(final s in w.societies){s.policy.trade=false;s.policy.expansion=false;s.policy.risk=0;}
  w.validate();return w;
}
Simulation engine(WorldState w)=>Simulation(w)..registerContent(core);
Command request(WorldState w,{String id='journey',String event='refugee_letter'})=>Command(id:id,action:'resolve_event',actorId:'s0',issuedDay:w.day,target:event,choice:'accept');
void launch(WorldState w){final r=engine(w).submit(request(w));expect(r.ok,isTrue,reason:r.message);}
Map<String,dynamic> copyWorld(WorldState w)=>jsonDecode(jsonEncode(w.toJson())) as Map<String,dynamic>;

void main(){
  test('Quote includes the real journey supplies without consuming anything',(){
    final w=opening(),before=w.canonical(),sim=engine(w);
    final quote=sim.preview(request(w));
    expect(quote.allowed,isTrue,reason:quote.reason);
    expect(quote.durationDays,6);expect(quote.costs,{'food':24.5,'water':3.5});
    expect(quote.outcome,contains('solo se incorporará al llegar'));
    expect(w.canonical(),before);
  });
  test('Residents live in transit, consume rations and arrive exactly once',(){
    final w=opening(),total=w.populationState!.total;
    final culture=w.entities!.cityFor('s1')!.cultureId;
    final people=w.society('s1')!.people.map((p)=>p.id).toList();
    launch(w);final j=w.migrations.single;
    expect(w.controlled.population,56);expect(w.society('s1')!.population,51);
    expect(w.populationInTransit,5);expect(w.populationState!.total,total);
    expect(w.controlled.resources['food'],235.5);expect(w.controlled.resources['water'],246.5);
    expect(w.populationState!.cohorts.where((c)=>c.settlement==j.residence).every((c)=>c.culture==culture),isTrue);
    final sim=engine(w);sim.advanceDays(5);
    expect(j.progress,5);expect(w.controlled.population,56);expect(w.populationInTransit,5);w.validate();
    sim.advanceDays(1);expect(j.status,'arrived');expect(w.controlled.population,61);
    expect(w.populationInTransit,0);expect(w.populationState!.total,total);
    expect(w.society('s1')!.people.map((p)=>p.id).toList(),people);
    expect(j.consumed,{'food':1350,'water':1050});expect(j.delivered,{'food':3150,'water':2450});
    expect(w.populationState!.totals(j.residence).total,0);
    final finalState=w.canonical();expect(sim.submit(request(opening())).replayed,isTrue);expect(w.canonical(),finalState);w.validate();
  });
  test('Arrival-day rations are consumed on the journey and not twice in the city',(){
    final w=opening();launch(w);engine(w).advanceDays(6);
    final s=w.controlled,flow=DailyProduction.fromJson(Map<String,dynamic>.from(s.lastProduction!['flows']));
    expect(s.lastProduction!['foodNeed'],56*45);expect(s.lastProduction!['waterNeed'],56*35);
    final delivered=w.migrations.single.delivered;
    expect(Quantity.fromNumber(s.resources['food']!).millis,flow.closing['food']!-s.lastProduction!['foodUsed']+delivered['food']!);
  });
  test('A blocked cell causes a real detour rather than a position jump',(){
    final w=opening();launch(w);final sim=engine(w);sim.advanceDays(2);
    final j=w.migrations.single,cut=j.path[j.progress+1];w.tiles[cut].damage=1;
    for(var days=0;days<20&&j.active;days++){
      final before=j.cell;sim.advanceDays(1);
      final distance=(before%w.size-j.cell%w.size).abs()+(before~/w.size-j.cell~/w.size).abs();
      expect(distance,1);expect(j.cell,isNot(cut));w.validate();
    }
    expect(j.status,'arrived');expect(j.lastDay,greaterThan(6));expect(j.deaths,0);
  });
  test('A closed border sends the actual group home with its remaining supplies',(){
    final w=opening();launch(w);final sim=engine(w);sim.advanceDays(2);
    w.controlled.policy.diplomacy='isolate';sim.advanceDays(2);
    final j=w.migrations.single;expect(j.status,'returned');expect(j.resolvedSettlement,'s1');
    expect(w.society('s1')!.population,56);expect(w.controlled.population,56);expect(w.populationInTransit,0);
    expect(j.arrived,5);expect(j.deaths,0);w.validate();
  });
  test('Stranded residents consume finite supplies and register real deaths',(){
    final w=opening();launch(w);final sim=Simulation(w);sim.advanceDays(1);
    final j=w.migrations.single,cell=j.cell,x=cell%w.size,y=cell~/w.size;
    for(final index in [y*w.size+x-1,y*w.size+x+1,(y-1)*w.size+x,(y+1)*w.size+x]){w.tiles[index].damage=1;}
    sim.advanceDays(1);expect(j.blocked,isTrue);expect(j.cell,cell);
    expect(j.carried['food'],4500-2*5*45);
    for(var day=0;day<180&&j.active;day++){sim.advanceDays(1);w.validate();}
    expect(j.status,'lost');expect(j.deaths,5);expect(j.arrived,0);expect(w.populationInTransit,0);
    for(final r in ['food','water']){expect(j.initial[r],j.consumed[r]!+j.lost[r]!);}
  });
  test('An unblocked route resumes from the saved cell',(){
    final w=opening();launch(w);final sim=engine(w);sim.advanceDays(1);
    final j=w.migrations.single,cell=j.cell,x=cell%w.size,y=cell~/w.size;
    final cuts=[cell-1,cell+1,(y-1)*w.size+x,(y+1)*w.size+x];
    for(final i in cuts){w.tiles[i].damage=1;}sim.advanceDays(3);
    expect(j.cell,cell);expect(j.blocked,isTrue);
    for(final i in cuts){w.tiles[i].damage=0;}sim.advanceDays(5);
    expect(j.status,'arrived');expect(j.lastDay,9);expect(j.deaths,0);w.validate();
  });
  test('Checkpoint and batch boundaries preserve in-flight positions, counts and balances',(){
    final a=opening();launch(a);engine(a).advanceDays(3);
    final checkpoint=Checkpoint.create(world:a,coreSource:File('assets/content/core.json').readAsStringSync());
    final b=Checkpoint.decode(checkpoint.encode()).world,baseline=checkpoint.world;
    engine(baseline).advanceDays(3);for(var i=0;i<3;i++){engine(b).advanceDays(1);}
    expect(b.canonical()==baseline.canonical(),isTrue);expect(b.migrations.single.status,'arrived');b.validate();
  });
  test('A blocked return remains a valid recoverable journey',(){
    final w=opening();launch(w);final sim=engine(w);sim.advanceDays(1);
    final j=w.migrations.single,cell=j.cell,x=cell%w.size,y=cell~/w.size;
    final cuts=[cell-1,cell+1,(y-1)*w.size+x,(y+1)*w.size+x];
    for(final i in cuts){w.tiles[i].damage=1;}
    w.controlled.policy.diplomacy='isolate';sim.advanceDays(1);
    expect(j.status,'returning');expect(j.blocked,isTrue);expect(j.cell,cell);w.validate();
    final checkpoint=Checkpoint.create(world:w,coreSource:File('assets/content/core.json').readAsStringSync());
    final restored=Checkpoint.decode(checkpoint.encode()).world;
    for(final i in cuts){restored.tiles[i].damage=0;}
    engine(restored).advanceDays(1);expect(restored.migrations.single.status,'returned');restored.validate();
  });
  test('Committed arrivals reserve housing before anyone reaches the city',(){
    final w=opening(),pack=jsonDecode(jsonEncode(core)) as Map<String,dynamic>;
    final event=(pack['events'] as List).firstWhere((e)=>e['id']=='refugee_letter');
    for(var i=0;i<4;i++){(pack['events'] as List).add({...event,'id':'invitation_$i'});}
    final sim=Simulation(w)..registerContent(pack);
    for(var i=0;i<3;i++){final r=sim.submit(request(w,id:'order_$i',event:'invitation_$i'));expect(r.ok,isTrue,reason:r.message);}
    expect(w.controlled.population,56);expect(w.incomingResidents('s0'),15);
    final before=w.canonical();expect(sim.submit(request(w,id:'fourth',event:'invitation_3')).ok,isFalse);expect(w.canonical(),before);w.validate();
  });
  test('Losing all cities does not erase a surviving group in transit',(){
    final w=opening();launch(w);final sim=Simulation(w);sim.advanceDays(1);
    for(final s in w.societies){final dead=w.populationState!.remove(s.id,s.population,(_) => 0).people;for(final p in s.people.where((p)=>dead.contains(p.id))){p.diedDay=w.day;}s.extinct=true;}
    w.syncPopulation();w.entities!.reconcile(w.identityRecords);w.validate();
    expect(w.extinct,isFalse);expect(w.populationState!.total,5);
    sim.advanceDays(1);expect(w.migrations.single.status,'returned');expect(w.society('s1')!.population,5);expect(w.society('s1')!.alive,isTrue);w.validate();
  });
  test('Import rejects unbalanced supplies, phantom residents and broken route history',(){
    final w=opening();launch(w);
    for(final mutate in <void Function(Map<String,dynamic>)>[
      (raw)=>raw['migrations'][0]['initial']['food']+=1,
      (raw)=>raw['migrations'][0]['carried'].remove('water'),
      (raw)=>raw['migrations'][0]['departed']+=1,
      (raw)=>raw['migrations'][0]['path'][1]=0,
      (raw)=>raw['migrations'][0]['lastDay']=1,
      (raw)=>raw['populationState']['cohorts'].firstWhere((c)=>c['settlement'].toString().startsWith('transit:'))['settlement']='transit:unknown',
      (raw)=>raw['rulesVersion']=10,
    ]){final raw=copyWorld(w);mutate(raw);expect(()=>WorldState.fromJson(raw),throwsA(anything));}
    w.validate();
  });
  test('Converting an old completed transfer preserves it without inventing a past journey',(){
    final w=opening()..rulesVersion=10;launch(w);
    expect(w.controlled.population,61);expect(w.migrations,isEmpty);
    final previous=Checkpoint.create(world:w,coreSource:File('assets/content/core.json').readAsStringSync());
    final upgraded=Checkpoint.upgradeRules(previous.encode());
    expect(upgraded.world.migrations,isEmpty);
    expect(upgraded.world.populationState!.toJson(),previous.world.populationState!.toJson());
    expect(upgraded.world.controlled.population,61);
    expect(upgraded.world.random.state,previous.world.random.state);
    expect(upgraded.world.ruleChanges.last['sourceSha256'],isNotEmpty);
    upgraded.world.validate();
  });
  test('An option with several positive population effects funds one complete group',(){
    for(final count in [5,9]){
      final w=opening();
      final event=jsonDecode(jsonEncode((core['events'] as List).firstWhere((e)=>e['id']=='refugee_letter'))) as Map<String,dynamic>;
      event['id']='split';event['options']=[{...(event['options'] as List).first,'effects':[{'type':'population','value':2},{'type':'population','value':count-2}]}];
      final sim=Simulation(w)..registerContent({'events':[event]});final before=w.canonical();
      final result=sim.submit(request(w,event:'split'));
      if(count==5){expect(result.ok,isTrue,reason:result.message);expect(w.migrations.single.departed,5);expect(w.populationInTransit,5);}
      else{expect(sim.eligibleEvents(),isEmpty);expect(result.ok,isFalse);expect(w.canonical(),before);}
      w.validate();
    }
  });
  test('Monthly narrative validates a journey after its current daily step',(){
    final w=opening();Simulation(w).advanceDays(29);launch(w);
    final original=w.migrations.single.id;
    final sim=Simulation(w)..registerContent({'events':[{
      'id':'monthly_probe','title':'Una tarea cotidiana','body':'El consejo atiende una necesidad.','category':'needs','trigger':'director',
      'conditions':<String,dynamic>{},'baseProbability':1,'repeatable':false,
      'options':[{'id':'ok','label':'Atender','costs':<String,num>{},'effects':[{'type':'flag','flag':'monthly_seen'}],'followUps':[]}],
    }]});
    sim.advanceDays(1);
    final trip=w.migrations.firstWhere((j)=>j.id==original);
    expect(w.day,30);expect(trip.lastDay,30);expect(trip.progress,1);
    expect(w.migrations.every((j)=>j.lastDay==30),isTrue);
    expect(w.society('s1')!.flags,contains('monthly_seen'));w.validate();
  });
  test('Historical worker checkpoints preserve an in-flight group across restart',() async {
    final initial=opening();launch(initial);
    var checkpoint=Checkpoint.create(world:initial,coreSource:File('assets/content/core.json').readAsStringSync());
    final baseline=Checkpoint.decode(checkpoint.encode()).world;
    for(final target in [3,6]){
      final port=ReceivePort();final iterator=StreamIterator<dynamic>(port);
      final worker=await Isolate.spawn(historyWorker,{'port':port.sendPort,'world':checkpoint.world.toJson(),'content':checkpoint.content,'target':target,'stop':false});
      try{
        expect(await iterator.moveNext().timeout(const Duration(seconds:15)),isTrue);
        final control=iterator.current['control'] as SendPort;
        expect(await iterator.moveNext().timeout(const Duration(seconds:15)),isTrue);
        final batch=iterator.current as Map;expect(batch['error'],isNull);expect(batch['done'],isTrue);
        final advanced=WorldState.fromJson(Map<String,dynamic>.from(batch['world']));
        checkpoint=Checkpoint.decode(Checkpoint.create(world:advanced,coreSource:checkpoint.coreSource).encode());
        expect(checkpoint.world.migrations.single.status,target==3?'outbound':'arrived');
        expect(checkpoint.world.migrations.single.lastDay,target);
        control.send('ack');
      }finally{worker.kill(priority:Isolate.immediate);await iterator.cancel();port.close();}
    }
    engine(baseline).advanceDays(6,delegateDecisions:true);
    expect(checkpoint.world.canonical()==baseline.canonical(),isTrue);
  });
}
