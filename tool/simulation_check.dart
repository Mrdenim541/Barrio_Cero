import 'dart:convert';
import 'dart:io';
import '../lib/simulation/engine.dart';

void check(bool ok,String message){if(!ok)throw StateError(message);}
void main(){
 final watch=Stopwatch()..start();
 var count=0;
 void test(String name,void Function() fn){fn();count++;print('PASS $name');}
 test('full-content 100-year daily/decade/whole/save equivalence',(){
  WorldState initial(List<String> trace){
   final w=WorldState.generate(seed:17,size:64);
   final e=withContent(w,trace:trace);
   check(e.command('build',target:'farm').ok,'dated initial construction rejected');
   check(e.command('policy',target:'food').ok,'dated initial policy rejected');
   check(e.command('delegate').ok,'initial delegation rejected');
   return w;
  }
  final traceA=<String>[],traceB=<String>[],traceC=<String>[],traceD=<String>[];
  final a=initial(traceA), b=initial(traceB), c=initial(traceC);
  final daily=withContent(a,trace:traceA), decades=withContent(b,trace:traceB), whole=withContent(c,trace:traceC);
  for(int i=0;i<36000 && !a.extinct;i++){
   daily.advanceDays(1,delegateDecisions:true);
   if(a.day%360==0)a.validate();
  }
  for(int i=0;i<10 && !b.extinct;i++){
   decades.advanceDays(3600,delegateDecisions:true);b.validate();
  }
  whole.advanceDays(36000,delegateDecisions:true);c.validate();
  var resumed=initial(traceD);
  while(resumed.day<36000 && !resumed.extinct){
   final remaining=36000-resumed.day;
   final n=remaining<137?remaining:137;
   withContent(resumed,trace:traceD).advanceDays(n,delegateDecisions:true);
   resumed=WorldState.fromJson(jsonDecode(jsonEncode(resumed.toJson())));
  }
  check(a.canonical()==b.canonical(),'decade boundaries changed full-content history');
  check(a.canonical()==c.canonical(),'single hundred-year jump changed full-content history');
  check(a.canonical()==resumed.canonical(),'irregular batches/save changed full-content history');
  final sequence=jsonEncode(traceA);
  check(sequence==jsonEncode(traceB)&&sequence==jsonEncode(traceC)&&sequence==jsonEncode(traceD),'complete event sequence differs (including pruned entries)');
  // A terminal run is reported explicitly; it does not establish century coverage.
  check(a.day==36000,'equivalence scenario became extinct before a century; choose an additional viable fixture, do not count as century coverage');
  print(jsonEncode({'check':'temporal_equivalence','seed':17,'days':a.day,'catalogEvents':(catalog['events'] as List).length,'retainedChronicleEntries':a.chronicle.length,'totalRecordedEvents':traceA.length}));
 });
 test('dated orders and observation do not depend on batching',(){
  Map<String,dynamic> run(int batch,{bool save=false,bool observe=false}){
   var w=WorldState.generate(seed:29,size:64);
   final receipts=<String>[];
   const orders=<int,List<String>>{0:['explore','',''],8:['facility','','seal'],30:['policy','food',''],360:['policy','trade','']};
   final applied=<int>{};
   while(w.day<1080&&!w.extinct){
    final sim=withContent(w);
    final order=orders[w.day];
    if(order!=null&&applied.add(w.day)){
     final result=sim.command(order[0],target:order[1].isEmpty?null:order[1],choice:order[2].isEmpty?null:order[2]);
     receipts.add('${w.day}:${result.ok}:${result.message}');
    }
    if(observe){
     final before=w.canonical();
     sim.eligibleEvents();w.toJson();
     for(final s in w.societies){sim.eligibleEvents(s.id);}
     check(before==w.canonical(),'inspection consumed simulation state or RNG');
    }
    var count=batch;
    for(final boundary in [...orders.keys,1080]){
     if(boundary>w.day && boundary-w.day<count)count=boundary-w.day;
    }
    sim.advanceDays(count,delegateDecisions:false);w.validate();
    if(save)w=WorldState.fromJson(jsonDecode(jsonEncode(w.toJson())));
   }
   check(applied.length==orders.length,'dated order schedule did not execute completely');
   return {'state':w.toJson(),'receipts':receipts};
  }
  final expected=jsonEncode(run(1));
  check(expected==jsonEncode(run(137,save:true,observe:true)),'observation/save/batch changed dated order result');
  check(expected==jsonEncode(run(36000)),'large batch changed dated order result');
 });
 test('paused construction reserves resources and prevents double spend',(){final w=WorldState.generate(size:64);final e=withContent(w),s=w.controlled;final before=s.resources['wood']!;check(e.command('build',target:'farm').ok,'build failed');check(s.resources['wood']==before-20,'payment');s.resources['wood']=0;check(!e.command('build',target:'farm').ok,'double spend');e.advanceDays(12);check(s.built['farm']==3,'not completed');});
 test('facility routes seal/salvage/share have real distinct effects',(){final states=<String>{};for(final choice in ['seal','salvage','share']){final w=WorldState.generate(seed:42,size:64);final e=withContent(w);check(e.command('explore').ok,'explore');e.advanceDays(8);check(w.controlled.facilityFound,'no discovery');check(e.command('facility',choice:choice).ok,'decision');e.advanceDays(12);check(w.chronicle.any((h)=>h.cause!=null&&h.category=='consecuencia'),'missing cause');states.add(jsonEncode(w.controlled.toJson()));}check(states.length==3,'branches identical');});
 test('study provides short and historical consequences',(){final w=WorldState.generate(seed:2,size:64);final e=withContent(w);w.controlled.tech.add('science');e.command('explore');e.advanceDays(8);e.command('facility',choice:'study');e.advanceDays(25);check(w.controlled.tech.contains('electricity'),'study did not unlock power');e.advanceDays(730);check(w.chronicle.any((h)=>h.title=='Voces entre estrellas'||h.title=='La visita hostil'||h.title=='Los tutores del silencio'),'historical contact missing');});
 test('leadership succession and extinct populations',(){final w=WorldState.generate(size:64);final e=withContent(w);e.advanceDays(36000);for(final s in w.societies){for(final p in s.people.where((p)=>p.alive)){check(w.day-p.bornDay<=101*360,'immortal character');}if(s.alive)check(s.people.any((p)=>p.id==s.leaderId&&p.alive),'dead leader');}for(final s in w.societies){s.children=0;s.adults=0;s.elders=0;s.extinct=true;}check(e.advanceDays(100)==0,'extinct world acts');});
 test('full-content 30 seeds x 200 years and two millennia',(){
  const strategies=['food','science','trade','defense','expansion','isolation'];
  const intensities=['normal','caótica','extrema'];
  for(int seed=1;seed<=30;seed++){
   final strategy=strategies[(seed-1)%strategies.length];
   final intensity=intensities[((seed-1)~/strategies.length)%intensities.length];
   final w=WorldState.generate(seed:seed,size:seed.isEven?64:96,intensity:intensity,extraordinary:seed.isEven);
   final sim=withContent(w);
   for(final s in w.societies){check(sim.command('policy',societyId:s.id,target:strategy).ok,'policy not applied');}
   sim.command('delegate');
   runLong(sim,72000,{'seed':seed,'strategy':strategy,'intensity':intensity,'extraordinary':w.extraordinary});
  }
  for(final extraordinary in [false,true]){
   final w=WorldState.generate(seed:extraordinary?73:74,size:96,extraordinary:extraordinary);
   w.controlledId=null;
   runLong(withContent(w),360000,{'seed':w.seed,'strategy':'default autonomous','intensity':'normal','extraordinary':extraordinary});
  }
 });
 test('corrupt saves rejected',(){final j=WorldState.generate(size:64).toJson();j['schema']=99;bool rejected=false;try{WorldState.fromJson(j);}catch(_){rejected=true;}check(rejected,'unsupported accepted');});
 test('actual content every arc option, declarative flags and scheduled nodes',(){
 final pack=Map<String,dynamic>.from(jsonDecode(File('assets/content/core.json').readAsStringSync()));
 final events=(pack['events'] as List);int branches=0;
 for(final event in events){for(final option in event['options'] as List){
  final w=WorldState.generate(seed:42,size:64);final s=w.controlled;final e=Simulation(w)..registerContent(pack);
  // Fixture meets every declared precondition while testing actual effects.
  final c=Map<String,dynamic>.from(event['conditions']??{});if(c['facilityFound']!=null)s.facilityFound=c['facilityFound'];w.day=(c['minDay']??1) as int;
  for(final r in resourceIds)s.resources[r]=1000;
  for(final entry in ((c['resource_max']??{}) as Map).entries)s.resources[entry.key]=(entry.value as num).toDouble();
  for(final entry in ((c['resource_min']??{}) as Map).entries)s.resources[entry.key]=(entry.value as num).toDouble()+100;
  if(c['maxHealth']!=null)s.health=(c['maxHealth'] as num).toDouble();
  if(c['minHealth']!=null)s.health=(c['minHealth'] as num).toDouble();
  if(c['maxMorale']!=null)s.morale=(c['maxMorale'] as num).toDouble();
  if(c['maxRelation']!=null)for(final id in s.relations.keys.toList())s.relations[id]=(c['maxRelation'] as num).toInt();
  if(c['minPopulation']!=null)s.adults=mathMax(s.adults,(c['minPopulation'] as num).toInt());
  if(c['maxPopulation']!=null){s.children=0;s.elders=0;s.adults=(c['maxPopulation'] as num).toInt();}
  if(c['minHousing']!=null)s.housingModifier+=(c['minHousing'] as num).toInt();
  s.flags.addAll(List<String>.from(c['flags']??[]));s.tech.addAll(List<String>.from(c['technologies']??[]));
  final result=e.resolveContentEvent(event['id'],option['id'],scheduled:true);check(result.ok,'${event['id']} ${option['id']}: ${result.message}');
  w.validate();branches++;
 }}
 check(branches>=300,'catalog did not execute');print('Executed $branches real content options');
 });
 test('procedural templates instantiate costs, local buildings and repairs',(){
 final pack=Map<String,dynamic>.from(jsonDecode(File('assets/content/core.json').readAsStringSync()));final w=WorldState.generate(size:64);final e=Simulation(w)..registerContent(pack);
 final templates=e.contentEvents.where((event)=>(event['id'] as String).startsWith('template_')).toList();check(templates.length==16,'template coverage');for(final template in templates){check(template['body'].contains('alcance'),'missing concrete instance');check((template['options'] as List).every((o)=>(o['costs'] as Map).values.every((n)=>n is num)),'uninstantiated parameter');}
 check(w.controlled.sites.length==w.controlled.built.values.fold(0,(int a,b)=>a+b),'initial sites mismatch');final old=w.controlled.sites.length;e.command('build',target:'house');e.advanceDays(20);check(w.controlled.sites.length==old+1,'new building has no position');final cell=w.tiles[w.controlled.y*w.size+w.controlled.x];cell.damage=1;w.controlled.housingModifier=-12;check(e.command('repair').ok,'repair rejected');check(cell.damage==0.5&&w.controlled.housingModifier==0,'repair had no effect');
 });
 watch.stop();print('$count groups passed in ${watch.elapsedMilliseconds} ms');
}

int mathMax(int a,int b)=>a>b?a:b;

final Map<String,dynamic> catalog=Map<String,dynamic>.from(jsonDecode(File('assets/content/core.json').readAsStringSync()));
Simulation withContent(WorldState world,{List<String>? trace})=>Simulation(world,onHistory:trace==null?null:(entry)=>trace.add(jsonEncode(entry.toJson())))..registerContent(catalog);

void runLong(Simulation sim,int target,Map<String,Object> configuration){
 final watch=Stopwatch()..start();final w=sim.world;
 var yearsChecked=0,peakPending=0,peakHistory=0;
 while(w.day<target&&!w.extinct){
  final requested=(target-w.day)<360?(target-w.day):360;
  final actual=sim.advanceDays(requested,delegateDecisions:true);
  w.validate();yearsChecked++;
  check(actual==requested||w.extinct,'unexplained early simulation stop');
  peakPending=mathMax(peakPending,w.pending.length);
  peakHistory=mathMax(peakHistory,w.chronicle.length);
  check(w.pending.length<10000,'unbounded pending consequences');
  check(w.chronicle.length<20000,'unbounded causal history');
  check(w.annualSnapshots.length<=1000,'unbounded annual snapshots');
  if(actual==0&&!w.extinct)throw StateError('simulation made no progress');
 }
 if(w.extinct){
  check(w.societies.every((s)=>s.population==0),'extinction flag with surviving population');
  check(w.societies.every((s)=>s.people.every((p)=>!p.alive)),'extinct community has living named people');
  check(sim.advanceDays(30,delegateDecisions:true)==0,'extinct world continues acting');
 }
 check(w.day==target||w.extinct,'run did not reach target or valid terminal state');
 watch.stop();
 print(jsonEncode({...configuration,'requestedDays':target,'actualDays':w.day,'terminal':w.extinct?'global_extinction':'target_reached','annualChecks':yearsChecked,'peakPending':peakPending,'peakHistory':peakHistory,'milliseconds':watch.elapsedMilliseconds,'peakRssBytes':ProcessInfo.maxRss}));
}
