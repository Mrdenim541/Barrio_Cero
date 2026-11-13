import 'dart:convert';
import 'dart:io';
import '../lib/simulation/engine.dart';

void check(bool ok,String message){if(!ok)throw StateError(message);}
void main(){
 final watch=Stopwatch()..start();
 var count=0;
 void test(String name,void Function() fn){fn();count++;print('PASS $name');}
 test('deterministic 100-year tick/batches/save equivalence',(){
  final a=WorldState.generate(seed:17,size:64), b=WorldState.generate(seed:17,size:64), c=WorldState.generate(seed:17,size:64);
  final aa=Simulation(a), bb=Simulation(b);for(int i=0;i<36000;i++)aa.advanceDays(1);for(int i=0;i<10;i++)bb.advanceDays(3600);Simulation(c).advanceDays(18000);final resumed=WorldState.fromJson(jsonDecode(jsonEncode(c.toJson())));Simulation(resumed).advanceDays(18000);check(a.canonical()==b.canonical(),'batch changed history');check(a.canonical()==resumed.canonical(),'save changed history');
 });
 test('paused construction reserves resources and prevents double spend',(){final w=WorldState.generate(size:64);final e=Simulation(w),s=w.controlled;final before=s.resources['wood']!;check(e.command('build',target:'farm').ok,'build failed');check(s.resources['wood']==before-20,'payment');s.resources['wood']=0;check(!e.command('build',target:'farm').ok,'double spend');e.advanceDays(12);check(s.built['farm']==3,'not completed');});
 test('facility routes seal/salvage/share have real distinct effects',(){final states=<String>{};for(final choice in ['seal','salvage','share']){final w=WorldState.generate(seed:42,size:64);final e=Simulation(w);check(e.command('explore').ok,'explore');e.advanceDays(8);check(w.controlled.facilityFound,'no discovery');check(e.command('facility',choice:choice).ok,'decision');e.advanceDays(12);check(w.chronicle.any((h)=>h.cause!=null&&h.category=='consecuencia'),'missing cause');states.add(jsonEncode(w.controlled.toJson()));}check(states.length==3,'branches identical');});
 test('study provides short and historical consequences',(){final w=WorldState.generate(seed:2,size:64);final e=Simulation(w);w.controlled.tech.add('science');e.command('explore');e.advanceDays(8);e.command('facility',choice:'study');e.advanceDays(25);check(w.controlled.tech.contains('electricity'),'study did not unlock power');e.advanceDays(730);check(w.chronicle.any((h)=>h.title=='Voces entre estrellas'||h.title=='La visita hostil'||h.title=='Los tutores del silencio'),'historical contact missing');});
 test('leadership succession and extinct populations',(){final w=WorldState.generate(size:64);final e=Simulation(w);e.advanceDays(36000);for(final s in w.societies){for(final p in s.people.where((p)=>p.alive)){check(w.day-p.bornDay<=101*360,'immortal character');}if(s.alive)check(s.people.any((p)=>p.id==s.leaderId&&p.alive),'dead leader');}for(final s in w.societies){s.children=0;s.adults=0;s.elders=0;s.extinct=true;}check(e.advanceDays(100)==0,'extinct world acts');});
 test('30 seeds x 200 years plus 1000-year bounded history',(){for(int seed=1;seed<=30;seed++){final w=WorldState.generate(seed:seed,size:seed.isEven?64:96,intensity:['normal','caótica','extrema'][seed%3]);w.controlledId=null;Simulation(w).advanceDays(72000);w.validate();check(w.pending.length<1000,'unbounded pending');check(w.chronicle.length<=2400,'unbounded history');}final w=WorldState.generate(size:64);w.controlledId=null;Simulation(w).advanceDays(360000);w.validate();check(w.annualSnapshots.length<=1000,'unbounded snapshots');});
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
