import 'v2/learning.dart';
import 'v2/social.dart';
import 'v2/operating_plan.dart';
import 'v2/opening_placement.dart';
export 'v2/operating_plan.dart';
export 'v2/learning.dart';
export 'v2/social.dart';
import 'v2/population.dart';
export 'v2/population.dart';
import '../content/definitions.dart';
import '../content/legacy_catalog.dart';
import '../content/catalog_generated.dart' show baseCatalogData,baseScenarioData;
import '../content/starting_scenario.dart';
import '../content/rule_catalog.dart';
export '../content/definitions.dart';
export '../content/legacy_catalog.dart';
export '../content/rule_catalog.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'v2/materials.dart';
import 'v2/inventory.dart';
import 'advance.dart';
import 'v2/world_entities.dart';
import 'v2/work_order.dart';
export 'advance.dart';

/// Calendar: 30 days/month, 12 months/year. All transitions use daily ticks.
const daysPerYear = 360;
const resourceIds = ['food','wood','stone','metal','water','medicine','tools','energy','knowledge','textiles','crystal','fuel'];
const biomeNames = ['Pradera','Bosque','Desierto','Montaña','Humedal','Costa'];

class RandomState {
 static const algorithm='lcg31-v1';
  int state;
  RandomState(int seed) : state = seed & 0x7fffffff;
  int nextInt(int n) {state = (1103515245 * state + 12345) & 0x7fffffff; return state % n;}
  double nextDouble()=>nextInt(1000000)/1000000;
}
class Tile implements PlacementCell {
  @override
  final int x;
  @override
  final int y;
  @override
  final int biome;
  @override
  final int richness;
  bool ruin; double damage;
  Tile(this.x,this.y,this.biome,this.richness,{this.ruin=false,this.damage=0});
  @override
  bool get passable => biome!=5 && biome!=3;
  Map<String,dynamic> toJson()=>{'x':x,'y':y,'biome':biome,'richness':richness,'ruin':ruin,'damage':damage};
  factory Tile.fromJson(Map<String,dynamic> j)=>Tile(j['x'],j['y'],j['biome'],j['richness'],ruin:j['ruin'],damage:(j['damage'] as num).toDouble());
}
const traitNames=['prudent','bold','generous','guarded','inventive','traditional','patient','restless','conciliatory','severe','green','pragmatic'];
class Person {
 String id,name,role,trait; int bornDay; int? diedDay; double skill; bool birthEstimated; Map<String,int> skills={};
 Person(this.id,this.name,this.role,this.bornDay,this.trait,{this.diedDay,this.skill=1,this.birthEstimated=false});
 bool get alive=>diedDay==null;
 Map<String,dynamic> toJson()=>{'id':id,'name':name,'role':role,if(birthEstimated)'birthEstimated':true,'bornDay':bornDay,'trait':trait,'diedDay':diedDay,'skill':skill,if(skills.isNotEmpty)'skills':skills};
 int competence(String course){final explicit=skills[course];if(explicit!=null)return explicit;final c=courses.where((c)=>c.id==course).firstOrNull;return c!=null&&c.teacherRoles.contains(role)?(skill*1000).round():0;}
 factory Person.fromJson(Map<String,dynamic> j){final p=Person(j['id'],j['name'],j['role'],j['bornDay'],j['trait'],diedDay:j['diedDay'],skill:(j['skill'] as num).toDouble(),birthEstimated:j['birthEstimated']??false);if(j['skills']!=null){final raw=j['skills'];if(raw is! Map||raw.entries.any((e)=>e.value is! int||e.value<0||e.value>1000||!courses.any((c)=>c.id==e.key)))throw const FormatException('Competencia personal inválida');p.skills=Map<String,int>.from(raw);}return p;}

}
class Policy {
 double reserve=120,risk=0.35; bool expansion=true,trade=true; String research='agriculture', diplomacy='cooperate';
 Map<String,dynamic> toJson()=>{'reserve':reserve,'risk':risk,'expansion':expansion,'trade':trade,'research':research,'diplomacy':diplomacy};
 factory Policy.fromJson(Map<String,dynamic> j)=>Policy()..reserve=(j['reserve'] as num).toDouble()..risk=(j['risk'] as num).toDouble()..expansion=j['expansion']..trade=j['trade']..research=j['research']..diplomacy=j['diplomacy'];
 Policy();
}
class Project {
 String building; int finish; WorkOrder? work; Project(this.building,this.finish,{this.work});
 Map<String,dynamic> toJson()=>{'building':building,'finish':finish,if(work!=null)'work':work!.toJson()};
 factory Project.fromJson(Map<String,dynamic> j)=>Project(j['building'],j['finish'],work:j['work']==null?null:WorkOrder.fromJson(Map<String,dynamic>.from(j['work'])));
}
class BuildingSite { final String id,building; final int x,y; BuildingSite(this.id,this.building,this.x,this.y); Map<String,dynamic> toJson()=>{'id':id,'building':building,'x':x,'y':y}; factory BuildingSite.fromJson(Map<String,dynamic> j)=>BuildingSite(j['id'],j['building'],j['x'],j['y']);}
Map<String,int> _resourcesMillis(Society s)=>(s.resources as FixedInventory).millis;
class Society {
 String id,name,profile,culture,leaderId; int x,y,founded; int siteLayout; int children,adults,elders; double health=90,morale=70,environment=0;
 RuleCatalog? catalog;
 bool supports(String capability)=>catalog?.provides(tech,capability)??tech.contains(capability);
 int materialRules;
 Map<String,double> _resources={for(final r in resourceIds) r:0};
 Map<String,double> get resources=>_resources;
 set resources(Map<String,double> value){_resources=materialRules==2?FixedInventory(value):Map<String,double>.from(value);}
 Map<String,int> built={}; List<Project> projects=[]; Set<String> tech={}; Map<String,int> relations={};
 List<LearningProject> lessons=[];Map<String,dynamic>? lastProduction;
 List<BuildingSite> sites=[]; List<Person> people=[]; Policy policy=Policy(); bool facilityFound=false; String? facilityChoice; bool extinct=false; int housingModifier=0,defenseModifier=0; int discoveries=0; int expeditionWorkers=0; int transportWorkers=0; Set<String> flags={}; Map<String,double> demographicCarry={}; Map<String,int> demographicMicros={};
 Society(this.id,this.name,this.profile,this.x,this.y,{this.children=12,this.adults=38,this.elders=6,this.founded=0,this.culture='Cero',this.leaderId='',this.siteLayout=2,this.materialRules=1}) {resources={for(final r in resourceIds)r:0};resources.addAll({'food':260,'wood':100,'stone':75,'metal':25,'water':250,'medicine':12,'tools':20,'energy':5,'knowledge':35,'textiles':20,'crystal':5,'fuel':30});built={'farm':2,'well':1,'house':4};}
 void addSite(String building){
   final i=sites.length;
   if(siteLayout==1){sites.add(BuildingSite('$id:b$i',building,2+(i%14)*2,2+(i~/14)*2));return;}
   final candidates=<List<int>>[
     for(var y=6;y<=18;y+=6)for(var x=6;x<=18;x+=6)[x,y],
     for(var y=2;y<=28;y+=2)for(var x=2;x<=28;x+=2)[x,y],
   ];
   for(final p in candidates){
     if(sites.every((s)=>(s.x-p[0]).abs()>=2||(s.y-p[1]).abs()>=2)){
       sites.add(BuildingSite('$id:b$i',building,p[0],p[1]));return;
     }
   }
   // Never overlap an occupied footprint when the local map is full.
   throw StateError('No queda espacio local para el edificio');
 }

 void ensureSites(){if(sites.isEmpty){for(final e in built.entries){for(int i=0;i<e.value;i++) {
   addSite(e.key);
 }}}}
 String get leaderTrait=>people.where((p)=>p.id==leaderId&&p.alive).map((p)=>p.trait).firstOrNull??'prudent';
 double get risk=>(policy.risk+(leaderTrait=='bold'?0.3:leaderTrait=='prudent'?-0.25:0)).clamp(0,1).toDouble();
 int get population=>children+adults+elders;
 int get housing=>math.max(0,catalog==null?(built['house']??0)*(supports('masonry')?22:18)+(built['habitat']??0)*50+housingModifier:catalog!.buildings.fold<int>(housingModifier,(total,b)=>total+(built[b.id]??0)*b.housingCapacity)+(supports('masonry')?(built['house']??0)*4:0));
 int get workers=>math.max(0,adults-projects.length*4-expeditionWorkers-transportWorkers-lessons.fold<int>(0,(n,l)=>n+l.work.workers));
 bool get alive=>!extinct&&population>0;
 Map<String,dynamic> identityView({int? day})=>{'id':id,'name':name,'culture':culture,'leaderId':leaderId,'population':population,'extinct':extinct,'people':[for(final p in people)if(p.alive){'id':p.id,'diedDay':null,if(day!=null)'eligibleLeader':day-p.bornDay>=18*360}]};
 Map<String,dynamic> toJson()=>{if(materialRules==2)'materialRules':2,if(materialRules==2)'resourceMillis':(_resources as FixedInventory).millis,if(siteLayout!=1)'siteLayout':siteLayout,if(lastProduction!=null)'lastProduction':lastProduction,'id':id,'name':name,'profile':profile,'culture':culture,'leaderId':leaderId,'x':x,'y':y,'founded':founded,'population':population,'children':children,'adults':adults,'elders':elders,'health':health,'morale':morale,'environment':environment,'resources':resources,'built':built,'projects':projects.map((e)=>e.toJson()).toList(),if(lessons.isNotEmpty)'lessons':lessons.map((l)=>l.toJson()).toList(),'tech':tech.toList()..sort(),'relations':relations,'sites':sites.map((e)=>e.toJson()).toList(),'people':people.map((e)=>e.toJson()).toList(),'policy':policy.toJson(),'facilityFound':facilityFound,'facilityChoice':facilityChoice,'extinct':extinct,'discoveries':discoveries,'expeditionWorkers':expeditionWorkers,if(transportWorkers>0)'transportWorkers':transportWorkers,'housingModifier':housingModifier,'defenseModifier':defenseModifier,'flags':flags.toList()..sort(),'demographicCarry':materialRules==2?{for(final e in demographicMicros.entries)e.key:e.value/1000000}:demographicCarry,if(materialRules==2)'demographicMicros':demographicMicros};
 factory Society.fromJson(Map<String,dynamic> j){final s=Society(j['id'],j['name'],j['profile'],j['x'],j['y'],children:j['children'],adults:j['adults'],elders:j['elders'],materialRules:j['materialRules']??1,siteLayout:j['siteLayout']??1,founded:j['founded'],culture:j['culture'],leaderId:j['leaderId']);s.health=(j['health'] as num).toDouble();s.morale=(j['morale'] as num).toDouble();s.environment=(j['environment'] as num).toDouble();s.resources=(j['resources'] as Map).map((k,v)=>MapEntry(k as String,(v as num).toDouble()));if(s.materialRules==2){final raw=j['resourceMillis'];if(raw is! Map||raw.length!=s.resources.length||s.resources.keys.any((r)=>raw[r] is! int||raw[r]!=(_resourcesMillis(s))[r]||(j['resources'][r] as num).toDouble()!=s.resources[r]))throw const FormatException('Inventario entero incoherente');}if(s.materialRules==1&&j.containsKey('resourceMillis'))throw const FormatException('Materiales enteros sin versión');s.built=Map<String,int>.from(j['built']);s.projects=(j['projects'] as List).map((e)=>Project.fromJson(Map<String,dynamic>.from(e))).toList();s.lessons=(j['lessons'] as List? ?? []).map((l)=>LearningProject.fromJson(Map<String,dynamic>.from(l))).toList();if(j['lastProduction']!=null)s.lastProduction=Map<String,dynamic>.from(j['lastProduction']);s.tech=Set<String>.from(j['tech']);s.relations=Map<String,int>.from(j['relations']);s.sites=(j['sites'] as List? ?? []).map((e)=>BuildingSite.fromJson(Map<String,dynamic>.from(e))).toList();s.ensureSites();s.people=(j['people'] as List).map((e)=>Person.fromJson(Map<String,dynamic>.from(e))).toList();s.policy=Policy.fromJson(Map<String,dynamic>.from(j['policy']));s.facilityFound=j['facilityFound'];s.facilityChoice=j['facilityChoice'];s.extinct=j['extinct'];s.discoveries=j['discoveries'];s.expeditionWorkers=j['expeditionWorkers']??0;s.transportWorkers=j['transportWorkers']??0;s.housingModifier=j['housingModifier']??0;s.defenseModifier=j['defenseModifier']??0;s.flags=Set<String>.from(j['flags']??[]);if(s.materialRules==2){final raw=j['demographicMicros'];if(raw is! Map||raw.entries.any((e)=>!['grown','aged','oldDeaths','births'].contains(e.key)||e.value is! int||e.value<0||e.value>=1000000))throw const FormatException('Resto demográfico inválido');s.demographicMicros=Map<String,int>.from(raw);final projection=j['demographicCarry'];if(projection is! Map||projection.length!=raw.length||raw.entries.any((e)=>projection[e.key]!=e.value/1000000))throw const FormatException('Resto demográfico incoherente');}s.demographicCarry=(j['demographicCarry'] as Map? ?? {}).map((k,v)=>MapEntry(k as String,(v as num).toDouble()));return s;}
}
class HistoryEntry {
 final String id,title,text,category,societyId; final int day,x,y; final String? cause;
 HistoryEntry(this.id,this.day,this.title,this.text,this.category,this.societyId,this.x,this.y,{this.cause});
 Map<String,dynamic> toJson()=>{'id':id,'day':day,'title':title,'text':text,'category':category,'societyId':societyId,'x':x,'y':y,'cause':cause};
 factory HistoryEntry.fromJson(Map<String,dynamic> j)=>HistoryEntry(j['id'],j['day'],j['title'],j['text'],j['category'],j['societyId'],j['x'],j['y'],cause:j['cause']);
}
class ScheduledEvent {
 String id,type,societyId; int day; String? cause; Map<String,dynamic> data;
 ScheduledEvent(this.id,this.type,this.societyId,this.day,{this.cause,this.data=const {}});
 Map<String,dynamic> toJson()=>{'id':id,'type':type,'societyId':societyId,'day':day,'cause':cause,'data':data};
 factory ScheduledEvent.fromJson(Map<String,dynamic> j)=>ScheduledEvent(j['id'],j['type'],j['societyId'],j['day'],cause:j['cause'],data:Map<String,dynamic>.from(j['data']));
}
class TradeRoute {
 String id,from,to; List<int> path; double cargo; int progress; bool blocked; int transportRules,metalMillis,crewAssigned; bool returning,closing;
 TradeRoute(this.id,this.from,this.to,this.path,{this.cargo=12,this.progress=0,this.blocked=false,this.transportRules=1,this.metalMillis=0,this.returning=false,this.closing=false,this.crewAssigned=0}){if(![1,2].contains(transportRules)||metalMillis<0||metalMillis>Quantity.maxMillis||![0,2].contains(crewAssigned))throw const FormatException('Datos de transporte inválidos');}
 Map<String,dynamic> toJson()=>{'id':id,'from':from,'to':to,'path':path,'cargo':cargo,'progress':progress,'blocked':blocked,if(transportRules==2)'transportRules':2,if(transportRules==2)'foodMillis':Quantity.fromNumber(cargo).millis,if(transportRules==2)'metalMillis':metalMillis,if(transportRules==2)'returning':returning,if(transportRules==2)'closing':closing,if(transportRules==2)'crewAssigned':crewAssigned};
 factory TradeRoute.fromJson(Map<String,dynamic> j){final rules=j['transportRules']??1;if(![1,2].contains(rules))throw const FormatException('Reglas de transporte desconocidas');if(rules==2&&(j['foodMillis'] is! int||j['foodMillis']!=Quantity.fromNumber(j['cargo']).millis||j['metalMillis'] is! int||j['returning'] is! bool||j['closing'] is! bool||j['crewAssigned'] is! int))throw const FormatException('Carga de transporte inválida');return TradeRoute(j['id'],j['from'],j['to'],List<int>.from(j['path']),cargo:(j['cargo'] as num).toDouble(),progress:j['progress'],blocked:j['blocked'],transportRules:rules,metalMillis:j['metalMillis']??0,returning:j['returning']??false,closing:j['closing']??false,crewAssigned:j['crewAssigned']??0);}
}
class WorldState {
 static const currentRules=10;
 SocialState? socialState;
 Map<String,SocialResident> get socialResidents=>{for(final s in societies)for(final p in s.people)p.id:SocialResident(p.id,s.id,p.bornDay,p.diedDay)};
 PopulationLedger? populationState;
 Iterable<Map<String,dynamic>> get identityRecords=>societies.map((s)=>s.identityView(day:populationState==null?null:day));
 String origin='reconstruction';
 RuleCatalog? catalog;
 List<BuildingDefinition> get buildingDefinitions=>catalog?.buildings??buildings;
 List<Technology> get technologyDefinitions=>catalog?.technologies??technologies;
 int rulesVersion=1;
 int seed,size,day=0,serial=0; String intensity; bool extraordinary; RandomState random; String? controlledId='s0';
 WorldEntities? entities;
 List<Map<String,dynamic>> ruleChanges=[];
 List<Tile> tiles=[]; List<Society> societies=[]; List<HistoryEntry> chronicle=[]; List<ScheduledEvent> pending=[]; List<TradeRoute> routes=[];
 Map<String,Map<String,dynamic>> commandReceipts={};
 Map<String,int> contentHistory={}; Map<String,Map<String,num>> annualSnapshots={}; Map<String,String> contentVersions={'core':'2.1.0'}; bool get extinct=>societies.every((s)=>!s.alive);
 WorldState._(this.seed,this.size,this.intensity,this.extraordinary):random=RandomState(seed);
 factory WorldState.generate({int seed=42,int size=96,String intensity='normal',bool extraordinary=true,bool fixedMaterials=true,String origin='reconstruction'}) {
 final w=WorldState._(seed,size,intensity,extraordinary);w.rulesVersion=fixedMaterials?currentRules:1;if(fixedMaterials)w.catalog=RuleCatalog.fromJson(baseCatalogData);w.origin=fixedMaterials?origin:'reconstruction';final scenario=fixedMaterials?StartingScenario.fromJson(Map<String,dynamic>.from(baseScenarioData.firstWhere((s)=>s['id']==origin,orElse:()=>throw const FormatException('Origen desconocido'))),w.catalog!):null;final r=w.random;
 for(int y=0;y<size;y++){for(int x=0;x<size;x++) {final n=((math.sin(x/9)+math.cos(y/11)+math.sin((x+y+seed%17)/6))*1.2+3).floor().clamp(0,5).toInt();w.tiles.add(Tile(x,y,n,r.nextInt(5)+1,ruin:r.nextInt(80)==0));}}
 final openingSites=fixedMaterials&&w.rulesVersion>=9?connectedOpeningSites(w.tiles,size,biomes:scenario!.biomes.toSet(),minimumRichness:scenario.minRichness):null;
 const names=['Barrio Cero','Liga del Junco','Forja Gris','Archivo del Alba','Vigías del Sur','Nómadas de Sal'];const profiles=['cooperativa','ecologista','industrial','científica','defensiva','mercantil'];
 for(int i=0;i<6;i++){int x=(size*(0.2+(i%3)*0.28)).round(),y=(size*(0.25+(i~/3)*0.45)).round();if(openingSites!=null){final tile=w.tiles[openingSites[i]];x=tile.x;y=tile.y;}else{while(!w.tiles[y*size+x].passable){x=(x+1)%size;}if(scenario!=null){Tile? best;var distance=1<<30;for(final t in w.tiles){if(!scenario.biomes.contains(t.biome)||t.richness<scenario.minRichness||w.societies.any((s)=>(s.x-t.x).abs()+(s.y-t.y).abs()<5))continue;final d=(t.x-x).abs()+(t.y-y).abs();if(d<distance){best=t;distance=d;}}if(best==null)throw const FormatException('No hay emplazamiento viable para el origen');x=best.x;y=best.y;}}final s=Society('s$i',names[i],profiles[i],x,y,culture:names[i],materialRules:fixedMaterials?2:1);s.policy.research=['agriculture','sanitation','mining','writing','masonry','trade'][i];s.policy.risk=i==2?0.7:0.35;s.policy.diplomacy=i==4?'defend':'cooperate';s.people=[Person('p${i}a',i==0?'Ana':'Iria $i','técnica',-28*360,'inventive'),Person('p${i}b',i==0?'Leo':'Nilo $i','explorador',-24*360,'bold'),Person('p${i}c',i==0?'Tito':'Sol $i','suministros',-42*360,'prudent')];if(scenario!=null){s.children=scenario.children;s.adults=scenario.adults;s.elders=scenario.elders;s.resources=Map.from(scenario.stocks);s.built=Map.from(scenario.built);s.tech=Set.from(scenario.knowledge);s.people=[for(var k=0;k<scenario.people.length;k++)Person('p$i${String.fromCharCode(97+k)}',i==0?scenario.people[k]['name']:'${scenario.people[k]['name']} $i',scenario.people[k]['role'],-(scenario.people[k]['age'] as int)*360,scenario.people[k]['trait'])];if(origin=='prehistory')s.policy.reserve=48;}s.leaderId=s.people.last.id;for(int j=0;j<6;j++){if(i!=j)s.relations['s$j']=r.nextInt(41)-10;}s.ensureSites();w.societies.add(s);}
 w.chronicle.add(HistoryEntry('h0',0,origin=='prehistory'?'Junto al primer fuego':'Un mundo vuelve a respirar',scenario==null?'Ana, Leo y Tito reúnen a 56 habitantes junto a las ruinas. Cada decisión tendrá memoria.':'${scenario.people.map((p)=>p['name']).join(', ')} reúnen a ${scenario.children+scenario.adults+scenario.elders} habitantes. ${scenario.description}','inicio','s0',w.societies.first.x,w.societies.first.y));w.serial=1;if(fixedMaterials)w.entities=WorldEntities.fromSettlements(w.identityRecords);for(final s in w.societies){s.catalog=w.catalog;}if(fixedMaterials){w.populationState=estimatePopulation(w.day,w.societies.map((s)=>s.toJson()),w.entities!);w.socialState=SocialState();}return w;
 }

 static PopulationLedger estimatePopulation(int day,Iterable<Map<String,dynamic>> actors,WorldEntities entities){
   final values=actors.toList();
   final result=PopulationLedger.fromProjections(day:day,settlements:values.map((s)=>{
     'id':s['id'],'cultureId':entities.cityFor(s['id'])!.cultureId,
     'children':s['children'],'adults':s['adults'],'elders':s['elders'],'people':s['people'],
   }));
   for(final s in values){result.birthCredits[s['id']]={entities.cityFor(s['id'])!.cultureId:((s['demographicMicros'] as Map?)?['births']??0) as int};}
   return result;
 }
 void syncPopulation(){
   final ledger=populationState;if(ledger==null)return;
   for(final s in societies){final n=ledger.totals(s.id);s.children=n.children;s.adults=n.adults;s.elders=n.elders;}
 }
 void assertPopulation({bool deep=true}){
   final ledger=populationState;if(ledger==null)return;
   if(ledger.day!=day||entities==null)throw const FormatException('Calendario o identidades de población incoherentes');
   for(final s in societies){final n=ledger.totals(s.id);if(n.children!=s.children||n.adults!=s.adults||n.elders!=s.elders)throw const FormatException('Población agregada distinta de sus grupos');}
   if(!deep)return;
   ledger.validate();final actors=societies.map((s)=>s.id).toSet();
   for(final c in ledger.cohorts){if(!actors.contains(c.settlement)||!entities!.cultures.containsKey(c.culture))throw const FormatException('Grupo sin asentamiento o cultura');}
   if(ledger.birthCredits.keys.any((s)=>!actors.contains(s))||ledger.birthCredits.values.any((c)=>c.keys.any((id)=>!entities!.cultures.containsKey(id))))throw const FormatException('Natalidad sin asentamiento');
   final alive=<String>{};
   for(final s in societies){for(final p in s.people.where((p)=>p.alive)){
     final c=ledger.cohort(ledger.cohortOf(p.id)??'');
     if(c==null||c.settlement!=s.id||c.bornDay!=p.bornDay)throw const FormatException('Persona fuera de su población real');
     alive.add(p.id);
   }}
   final people={for(final s in societies)for(final p in s.people)p.id:p};
   for(final e in ledger.archives.entries){final p=people[e.key];if(p==null||p.alive||p.bornDay!=e.value['bornDay']||p.diedDay!=e.value['diedDay']||!actors.contains(e.value['settlement'])||!entities!.cultures.containsKey(e.value['culture']))throw const FormatException('Legado personal incompatible con sus bajas');}
   if(ledger.members.length!=alive.length||ledger.members.keys.any((p)=>!alive.contains(p)))throw const FormatException('Personas fallecidas o duplicadas en los grupos');
 }
 Society? society(String? id){for(final s in societies){if(s.id==id)return s;}return null;}
 Society get controlled=>society(controlledId)??societies.first;
 String get date=>'Año ${day~/360+1} · mes ${(day%360)~/30+1} · día ${day%30+1}';
 Map<String,dynamic> toJson()=>{'schema':1,if(socialState!=null)'socialState':socialState!.toJson(),if(rulesVersion>=5)'origin':origin,if(populationState!=null)'populationState':populationState!.toJson(),if(catalog!=null)'catalog':catalog!.toJson(),if(entities!=null)'entities':entities!.toJson(),if(ruleChanges.isNotEmpty)'ruleChanges':ruleChanges,if(rulesVersion>1)'rulesVersion':rulesVersion,if(rulesVersion>1)'randomAlgorithm':RandomState.algorithm,'seed':seed,'size':size,'day':day,'serial':serial,'intensity':intensity,'extraordinary':extraordinary,'rng':random.state,'controlledId':controlledId,'tiles':tiles.map((t)=>t.toJson()).toList(),'societies':societies.map((s)=>s.toJson()).toList(),'chronicle':chronicle.map((h)=>h.toJson()).toList(),'pending':pending.map((e)=>e.toJson()).toList(),'routes':routes.map((r)=>r.toJson()).toList(),'annualSnapshots':annualSnapshots,'contentVersions':contentVersions,'contentHistory':contentHistory,'commandReceipts':commandReceipts};
 factory WorldState.fromJson(Map<String,dynamic> j){if(j.containsKey('rulesVersion')&&(![2,3,4,5,6,7,8,9,10].contains(j['rulesVersion'])||j['randomAlgorithm']!=RandomState.algorithm))throw const FormatException('Versión de reglas o azar no compatible');if(j['schema']!=1)throw FormatException('Esquema incompatible');final w=WorldState._(j['seed'],j['size'],j['intensity'],j['extraordinary']);w.rulesVersion=j['rulesVersion']??1;w.origin=j['origin']??'reconstruction';if(j['catalog']!=null)w.catalog=RuleCatalog.fromJson(Map<String,dynamic>.from(j['catalog']));w.day=j['day'];w.serial=j['serial'];w.random.state=j['rng'];w.controlledId=j['controlledId'];w.tiles=(j['tiles'] as List).map((e)=>Tile.fromJson(Map<String,dynamic>.from(e))).toList();w.societies=(j['societies'] as List).map((e)=>Society.fromJson(Map<String,dynamic>.from(e))).toList();w.chronicle=(j['chronicle'] as List).map((e)=>HistoryEntry.fromJson(Map<String,dynamic>.from(e))).toList();w.pending=(j['pending'] as List).map((e)=>ScheduledEvent.fromJson(Map<String,dynamic>.from(e))).toList();w.routes=(j['routes'] as List).map((e)=>TradeRoute.fromJson(Map<String,dynamic>.from(e))).toList();w.annualSnapshots=(j['annualSnapshots'] as Map).map((k,v)=>MapEntry(k as String,Map<String,num>.from(v)));w.contentVersions=Map<String,String>.from(j['contentVersions']);w.contentHistory=Map<String,int>.from(j['contentHistory']??{});w.commandReceipts=(j['commandReceipts'] as Map? ?? {}).map((k,v)=>MapEntry(k as String,Map<String,dynamic>.from(v as Map)));if(j['populationState']!=null)w.populationState=PopulationLedger.fromJson(Map<String,dynamic>.from(j['populationState']));w.ruleChanges=(j['ruleChanges'] as List? ?? []).map((r)=>Map<String,dynamic>.from(r as Map)).toList();if(j['entities']!=null)w.entities=WorldEntities.fromJson(Map<String,dynamic>.from(j['entities']));if(j['socialState']!=null)w.socialState=SocialState.fromJson(Map<String,dynamic>.from(j['socialState']));w.validate();return w;}
 void validate(){
 if((rulesVersion>=7)!=(socialState!=null))throw const FormatException('Registro personal sin su versión de reglas');
 socialState?.validate(day,socialResidents,societies.map((s)=>s.id).toSet());
 if((rulesVersion>=6)!=(populationState!=null))throw const FormatException('Población sin su versión de reglas');
 assertPopulation();
 for(final s in societies){s.catalog=catalog;}
 if(!['prehistory','reconstruction'].contains(origin)||(rulesVersion<5&&origin!='reconstruction'))throw const FormatException('Origen o versión incompatibles');
 if((rulesVersion>=4)!=(catalog!=null))throw const FormatException('Catálogo y versión de reglas incompatibles');
 final buildings=buildingDefinitions;final technologies=technologyDefinitions;
 for(final change in ruleChanges){if(change['day'] is! int||change['day']<0||change['day']>day||![2,3,4,5,6,7,8,9,10].contains(change['to'])||change['sourceSha256'] is! String||!RegExp(r'^[a-f0-9]{64}$').hasMatch(change['sourceSha256']))throw const FormatException('Historial de reglas inválido');}
 entities?.validate(identityRecords);
 if(![1,2,3,4,5,6,7,8,9,10].contains(rulesVersion)||random.state<0||random.state>0x7fffffff)throw const FormatException('Reglas o estado de azar inválidos');
 if(size!=64&&size!=96)throw const FormatException('Tamaño de mundo inválido');
 if(day<0||serial<0||tiles.length!=size*size)throw const FormatException('Calendario o terreno inválido');
 if(societies.isEmpty||societies.length>100)throw const FormatException('Número de sociedades inválido');
 final ids=societies.map((s)=>s.id).toSet();if(ids.length!=societies.length)throw const FormatException('Sociedades duplicadas');
 if(controlledId!=null&&!ids.contains(controlledId))throw const FormatException('Control sin sociedad');
 final personIds=<String>{};final workIds=<String>{};
 for(int i=0;i<tiles.length;i++){final t=tiles[i];if(t.x!=i%size||t.y!=i~/size||t.biome<0||t.biome>=6||t.richness<1||t.richness>5||!t.damage.isFinite||t.damage<0||t.damage>1)throw const FormatException('Celda inválida');}
 for(final s in societies){
 if(s.lastProduction!=null){
   final raw=s.lastProduction!;const keys={'day','flows','foodNeed','waterNeed','foodUsed','waterUsed'};
   if(rulesVersion<8||raw.length!=keys.length||raw.keys.any((k)=>!keys.contains(k))||['day','foodNeed','waterNeed','foodUsed','waterUsed'].any((k)=>raw[k] is! int||raw[k]<0)||raw['day']<1||raw['day']>day||raw['flows'] is! Map)throw const FormatException('Jornadas productivas incompatibles');
   final flow=DailyProduction.fromJson(Map<String,dynamic>.from(raw['flows']));
   if(flow.opening.length!=resourceIds.length||flow.opening.keys.any((r)=>!resourceIds.contains(r))||flow.allocations.keys.any((id)=>id!='work:gather_wood'&&!buildings.any((b)=>b.id==id))||raw['foodUsed']!=math.min(raw['foodNeed'] as int,flow.closing['food']!)||raw['waterUsed']!=math.min(raw['waterNeed'] as int,flow.closing['water']!))throw const FormatException('Balance alimentario incompatible');
 }
 if(s.materialRules!=1&&s.materialRules!=2)throw const FormatException('Reglas de materiales desconocidas');
 if(s.siteLayout!=1&&s.siteLayout!=2)throw const FormatException('Versión de plano local no compatible');
 if(s.siteLayout==2){final occupied=<int>{};for(final site in s.sites){if(site.x<0||site.y<0||site.x>30||site.y>30)throw const FormatException('Edificio fuera del plano local');for(var dy=0;dy<2;dy++){for(var dx=0;dx<2;dx++){if(!occupied.add((site.y+dy)*32+site.x+dx))throw const FormatException('Edificios superpuestos');}}}}
 if(s.x<0||s.x>=size||s.y<0||s.y>=size||s.children<0||s.adults<0||s.elders<0||s.population>10000000)throw StateError('Población o posición imposible: ${s.id}');
 if(!resourceIds.every(s.resources.containsKey)||s.resources.keys.any((id)=>!resourceIds.contains(id))||s.resources.values.any((v)=>!v.isFinite||v<0||v>100000000))throw StateError('Recursos imposibles: ${s.id}');
 if(s.transportWorkers<0||s.transportWorkers!=routes.where((r)=>r.from==s.id&&r.transportRules==2).length*2)throw const FormatException('Reserva de transporte inválida');
 if(s.expeditionWorkers!=0&&s.expeditionWorkers!=4)throw const FormatException('Reserva de expedición inválida');
 if(s.built.entries.any((e)=>e.value<0||!buildings.any((b)=>b.id==e.key)))throw const FormatException('Edificio inválido');
 final siteIds=<String>{};final sitePositions=<String>{};final siteCounts=<String,int>{};for(final site in s.sites){if(!siteIds.add(site.id)||!sitePositions.add('${site.x}:${site.y}')||site.x<0||site.x>=32||site.y<0||site.y>=32||!buildings.any((b)=>b.id==site.building))throw const FormatException('Plano local inválido');siteCounts[site.building]=(siteCounts[site.building]??0)+1;}if(s.built.entries.any((e)=>(siteCounts[e.key]??0)!=e.value))throw const FormatException('Plano y edificios no coinciden');
 if(rulesVersion>=3&&s.projects.any((p)=>p.work==null))throw const FormatException('Obra sin compromiso de trabajo');
 for(final p in s.projects){final work=p.work;if(work==null)continue;if(!workIds.add(work.id)||work.workers!=4)throw const FormatException('Compromiso de obra duplicado o inválido');if(work.committed.isNotEmpty){final definition=buildings.where((b)=>b.id==p.building).firstOrNull;if(definition==null)throw const FormatException('Edificio de obra desconocido');final expected={for(final e in definition.cost.entries)if(e.value>0)e.key:Quantity.fromNumber(e.value).millis};if(expected.length!=work.committed.length||expected.entries.any((e)=>work.committed[e.key]!=e.value))throw const FormatException('Coste reservado incoherente');}}
 if(rulesVersion<6&&s.lessons.isNotEmpty)throw const FormatException('Formación sin reglas compatibles');
 final named=<String>{};
 for(final l in s.lessons){
   if(!workIds.add(l.id)||l.work.createdDay>day||l.work.remaining==0||l.work.committed.keys.any((r)=>!['food','knowledge'].contains(r)))throw const FormatException('Reserva de formación inválida');
   for(final id in [l.learner,if(l.teacher!=null)l.teacher!]){if(!named.add(id)||!s.people.any((p)=>p.id==id&&p.alive&&day-p.bornDay>=18*360&&day-p.bornDay<65*360))throw const FormatException('Participante de formación incompatible');}
   final fraction=1000-l.startingSkill;
   final expectedWork=(180*fraction/1000).ceil();final expectedCost={'food':((l.teacher==null?20000:10000)*fraction/1000).ceil(),'knowledge':((l.teacher==null?15000:5000)*fraction/1000).ceil()};
   if(l.work.totalWork!=expectedWork||l.work.committed.length!=expectedCost.length||expectedCost.entries.any((e)=>l.work.committed[e.key]!=e.value))throw const FormatException('Coste o duración de formación incoherente');
   final learner=s.people.firstWhere((p)=>p.id==l.learner);final progress=l.startingSkill+(1000-l.startingSkill)*(l.work.totalWork-l.work.remaining)~/l.work.totalWork;
   if(learner.competence(l.course)!=progress||l.teacher!=null&&!s.people.any((p)=>p.id==l.teacher&&p.competence(l.course)>=1000))throw const FormatException('Aprendizaje y progreso incompatibles');
 }
 if(pending.any((e)=>e.type=='discovery'&&e.societyId==s.id&&named.contains(e.data['explorerId'])))throw const FormatException('Persona reservada dos veces');
 if(s.projects.any((p)=>p.work!=null&&p.work!.committed.keys.any((r)=>!resourceIds.contains(r))))throw const FormatException('Material de obra inválido');
 if(s.projects.any((p)=>p.finish<0||!buildings.any((b)=>b.id==p.building)))throw const FormatException('Proyecto inválido');
 if(s.tech.any((id)=>!technologies.any((t)=>t.id==id)))throw const FormatException('Tecnología inválida');
 if(s.relations.entries.any((e)=>!ids.contains(e.key)||e.value< -100||e.value>100))throw const FormatException('Relación inválida');
 if([s.health,s.morale,s.environment].any((v)=>!v.isFinite||v<0||v>100))throw const FormatException('Indicador inválido');
 if(!s.policy.reserve.isFinite||s.policy.reserve<0||!s.policy.risk.isFinite||s.policy.risk<0||s.policy.risk>1)throw const FormatException('Política inválida');
 for(final p in s.people){if(!p.skill.isFinite||p.skill<0||p.skill>100||p.skills.entries.any((e)=>!courses.any((c)=>c.id==e.key)||e.value<0||e.value>1000)||(socialState!=null&&p.id.contains('|'))||!personIds.add(p.id)||p.bornDay>day||(p.diedDay!=null&&(p.diedDay!>day||p.diedDay!<p.bornDay)))throw const FormatException('Persona inválida');}
 if(s.alive&&!(populationState!=null&&s.leaderId=='')&&!s.people.any((p)=>p.id==s.leaderId))throw const FormatException('Dirigente inexistente');
 }
 for(final receipt in commandReceipts.entries){if(receipt.key.isEmpty||receipt.key.length>128||receipt.value['fingerprint'] is! String||receipt.value['message'] is! String||receipt.value['day'] is! int||(receipt.value['day'] as int)>day||(receipt.value['day'] as int)<0)throw const FormatException('Recibo de orden inválido');}
 for(final receipt in commandReceipts.values){
  final payments=receipt['materials'];if(payments==null)continue;
  if(payments is! List||payments.length>100)throw const FormatException('Pagos de orden inválidos');
  for(final payment in payments){if(payment is! Map||!ids.contains(payment['society'])||payment['day']!=receipt['day']||payment['ledger'] is! Map)throw const FormatException('Pago sin actor o fecha');final ledger=MaterialLedger.fromJson(Map<String,dynamic>.from(payment['ledger']));if(ledger.resources.length!=resourceIds.length||!ledger.resources.containsAll(resourceIds))throw const FormatException('Catálogo de pago inválido');}
 }

 final eventIds=<String>{};for(final e in pending){if(!eventIds.add(e.id)||!ids.contains(e.societyId)||e.day<0)throw const FormatException('Consecuencia inválida');}
 for(final r in routes){if(![1,2].contains(r.transportRules)||r.metalMillis<0||r.metalMillis>Quantity.maxMillis||![0,2].contains(r.crewAssigned)||(rulesVersion<3&&r.transportRules==2))throw const FormatException('Transporte no compatible');if(!ids.contains(r.from)||!ids.contains(r.to)||r.from==r.to||r.path.isEmpty||r.path.any((p)=>p<0||p>=tiles.length)||!r.cargo.isFinite||r.cargo<0||r.progress<0||r.progress>=r.path.length)throw const FormatException('Ruta inválida');for(int i=1;i<r.path.length;i++){final a=tiles[r.path[i-1]],b=tiles[r.path[i]];if((a.x-b.x).abs()+(a.y-b.y).abs()!=1)throw const FormatException('Ruta desconectada');}}
 }

 /// Commits an already validated candidate without changing the WorldState identity.
 /// References to nested entities must be reacquired after a successful submit.
 void _adopt(WorldState value) {
  socialState=value.socialState;populationState=value.populationState;origin=value.origin;catalog=value.catalog;rulesVersion=value.rulesVersion;ruleChanges=value.ruleChanges;entities=value.entities;seed=value.seed;size=value.size;day=value.day;serial=value.serial;
  intensity=value.intensity;extraordinary=value.extraordinary;random=value.random;
  controlledId=value.controlledId;tiles=value.tiles;societies=value.societies;
  chronicle=value.chronicle;pending=value.pending;routes=value.routes;
  contentHistory=value.contentHistory;annualSnapshots=value.annualSnapshots;
  contentVersions=value.contentVersions;commandReceipts=value.commandReceipts;
 }
 String canonical()=>jsonEncode(toJson());
}
/// A player command applies on its exact simulation day. IDs are stable across retries.
class Command {
 final String id,action;
 final String? actorId,target,choice;
 final int issuedDay;
 const Command({required this.id,required this.action,required this.actorId,
  required this.issuedDay,this.target,this.choice});
 Map<String,dynamic> toJson()=>{'id':id,'action':action,'actorId':actorId,
  'issuedDay':issuedDay,'target':target,'choice':choice};
 factory Command.fromJson(Map<String,dynamic> value)=>Command(id:value['id'] as String,
  action:value['action'] as String,actorId:value['actorId'] as String?,
  issuedDay:value['issuedDay'] as int,target:value['target'] as String?,choice:value['choice'] as String?);
 String get fingerprint=>jsonEncode(toJson());
}
class MigrationOffer {
 final String source,destination,reason;final int count,distance,pressure;
 const MigrationOffer(this.source,this.destination,this.count,this.distance,this.pressure,this.reason);
}
class CommandResult {
 final bool ok,replayed;
 final String message,code;
 const CommandResult(this.ok,this.message,{this.code='ok',this.replayed=false});
}


/// A quote for the current state only; submitting still revalidates the order.
/// durationDays == 0 means an immediate rule effect; null means no finite estimate.
class CommandPreview {
 final bool allowed,replayed;
 final String reason,code,outcome;
 final Map<String,double> costs;
 final int workers;
 final int? durationDays;
 final List<String> prerequisites;
 CommandPreview({required this.allowed,required this.reason,required this.code,
  required this.outcome,Map<String,double> costs=const {},this.workers=0,
  this.durationDays,this.replayed=false,List<String> prerequisites=const []})
  :costs=Map.unmodifiable(costs),prerequisites=List.unmodifiable(prerequisites);
}
class _CommandEvaluation {
 final CommandResult result;
 final WorldState? candidate;
 final List<HistoryEntry> history;
 const _CommandEvaluation(this.result,{this.candidate,this.history=const []});
}
const _repairCost=<String,double>{'wood':10,'stone':8,'tools':2};
const _explorationCost=<String,double>{'food':12,'tools':2};
const _facilityCosts=<String,Map<String,double>>{
 'seal':{'stone':15},'salvage':{'tools':4},
 'study':{'knowledge':20,'tools':5},'share':{'food':15},
};
int _constructionDays(BuildingDefinition building,Society society)=>
 society.supports('engineering')?(building.days*0.75).ceil():building.days;

class Simulation {
 final WorldState world; Map<String,dynamic>? content;
 List<BuildingDefinition> get buildings=>world.buildingDefinitions;
 List<Technology> get technologies=>world.technologyDefinitions;
 bool captureMaterialPayments=false;
 final List<Map<String,dynamic>> materialPayments=[];
 final void Function(HistoryEntry)? onHistory;
 Simulation(this.world,{this.onHistory});
 void registerContent(Map<String,dynamic> package){if(world.rulesVersion>=4&&(package.containsKey('buildings')||package.containsKey('technologies'))&&!world.catalog!.matches(RuleCatalog.fromContent(package)))throw const FormatException('Las definiciones no coinciden con el catálogo fijado del mundo');content=package;}
 /// Player authority and atomicity live at this boundary, not in widgets.
 /// A rejected command does not change resources, RNG, history, or receipts.
 CommandResult submit(Command request) {
  final evaluated=_evaluate(request);
  if(evaluated.candidate!=null)world._adopt(evaluated.candidate!);
  // Observers see only committed changes; preview never publishes this history.
  for(final entry in evaluated.history){onHistory?.call(entry);}
  return evaluated.result;
 }
 _CommandEvaluation _evaluate(Command request) {
  if(request.id.isEmpty||request.id.length>128){
   return const _CommandEvaluation(CommandResult(false,'Identificador de orden inválido.',code:'invalid_id'));
  }
  final previous=world.commandReceipts[request.id];
  if(previous!=null){
   if(previous['fingerprint']!=request.fingerprint){
    return const _CommandEvaluation(CommandResult(false,'Ese identificador pertenece a otra orden.',code:'id_conflict'));
   }
   return _CommandEvaluation(CommandResult(true,previous['message'] as String,replayed:true));
  }
  if(request.issuedDay!=world.day){
   return const _CommandEvaluation(CommandResult(false,'La fecha de la orden ya no coincide con el mundo.',code:'stale_day'));
  }
  if(request.actorId!=world.controlledId ||
     (request.actorId==null&&request.action!='control'&&request.action!='delegate')){
   return const _CommandEvaluation(CommandResult(false,'Asume la dirección de la comunidad antes de darle órdenes.',code:'not_controlled'));
  }
  if(world.populationState!=null&&!['control','delegate'].contains(request.action)){
   final actor=world.society(request.actorId);
   if(actor==null||!actor.alive)return const _CommandEvaluation(CommandResult(false,'No hay una comunidad viva seleccionada.',code:'rejected'));
   if(!actor.people.any((p)=>p.id==actor.leaderId&&p.alive&&world.day-p.bornDay>=18*360))return const _CommandEvaluation(CommandResult(false,'No hay una dirección adulta capaz de confirmar la orden.',code:'rejected'));
  }
  final emitted=<HistoryEntry>[];
  try {
   final candidate=WorldState.fromJson(world.toJson());
   final trial=Simulation(candidate,onHistory:emitted.add)..captureMaterialPayments=true;
   if(content!=null)trial.registerContent(content!);
   final result=request.action=='resolve_event'
    ? trial.resolveContentEvent(request.target??'',request.choice??'',societyId:request.actorId)
    : trial.command(request.action,societyId:request.actorId,
      target:request.target,choice:request.choice);
   if(!result.ok)return _CommandEvaluation(CommandResult(false,result.message,code:'rejected'));
   candidate.commandReceipts[request.id]={'fingerprint':request.fingerprint,
    'message':result.message,'day':candidate.day,if(trial.materialPayments.isNotEmpty)'materials':trial.materialPayments};
   candidate.socialState?.reconcile(candidate.day,candidate.socialResidents);candidate.entities?.reconcile(candidate.identityRecords);
   candidate.validate();
   return _CommandEvaluation(result,candidate:candidate,history:emitted);
  } catch(error) {
   return _CommandEvaluation(CommandResult(false,'La orden no pudo validarse: $error',code:'invalid_state'));
  }
 }

 /// Executes the same transaction evaluator as submit on a disposable candidate.
 /// The live world, RNG, receipts and history observers remain untouched.
 CommandPreview preview(Command request) {
  final evaluated=_evaluate(request);
  final result=evaluated.result;
  if(result.replayed){
   return CommandPreview(allowed:true,reason:result.message,
    code:result.code,replayed:true,durationDays:0,
    outcome:'Orden ya confirmada; no vuelve a consumir recursos ni trabajo.');
  }
  if(result.code!='ok'&&result.code!='rejected'){
   return CommandPreview(allowed:false,reason:result.message,code:result.code,
    outcome:'Revisa la disponibilidad antes de preparar esta orden.');
  }
  final society=world.society(request.actorId);
  Map<String,double> costs={};
  var workers=0;
  int? duration;
  var outcome='Consulta la respuesta de esta acción antes de confirmarla.';
  final prerequisites=<String>[];
  String technologyName(String id)=>technologies.where((t)=>t.id==id).firstOrNull?.name??id;
  switch(request.action){
   case 'home':
    if(request.choice=='support'){costs={'wood':4,'food':6};}duration=0;outcome='Atiende una petición real de convivencia. No impone afecto ni crea habitantes.';break;
   case 'foster':
    costs={'food':2,'water':1};duration=0;outcome='Un adulto con hogar asume el cuidado de un menor ya residente. Su parentesco biológico desconocido permanece desconocido.';break;
   case 'train':
    if(society!=null){final quote=_learningQuote(society,request.target,request.choice);costs=quote.costs;workers=quote.workers;duration=quote.days;outcome=quote.allowed?'Forma un residente existente. Maestro y aprendiz dejan de producir mientras trabajan; el aprendizaje parcial se conserva.':'Formación: ${quote.reason}';}
    break;
   case 'cancel_train':
    duration=0;outcome='Libera al maestro y al aprendiz, conserva lo aprendido y devuelve las provisiones que aún no se han utilizado.';break;
   case 'federate':
    costs={'food':20,'knowledge':10};duration=0;prerequisites.add('Confianza mutua: 40 / 30');outcome='Une las sociedades conservando las reservas, habitantes y culturas locales.';break;
   case 'cancel_build':
    duration=0;final project=society?.projects.where((p)=>p.work?.id==request.target).firstOrNull;outcome=project?.work==null?'La obra no está disponible.':project!.work!.committed.isEmpty?'Detiene una obra heredada; el coste original no registrado no permite calcular devolución.':'Devuelve materiales sin utilizar: ${project.work!.refund.entries.map((e)=>'${e.key} ${e.value/1000}').join(', ')}. El trabajo realizado no se recupera.';break;
   case 'capital':
    duration=0;outcome='Traslada la capital a una ciudad propia sin mover sus reservas.';break;
   case 'build':
    final building=buildings.where((b)=>b.id==request.target).firstOrNull;
    if(building!=null){
     costs=building.cost;workers=4;
     duration=society==null?building.days:_constructionDays(building,society);
     if(building.technology!=null)prerequisites.add('Conocimiento: ${technologyName(building.technology!)}');
     prerequisites.addAll(['Cuatro trabajadores disponibles','Espacio local y capacidad de coordinación']);
     outcome=building.description;
    }
    break;
   case 'research':
    final technology=technologies.where((t)=>t.id==request.target).firstOrNull;
    if(technology!=null){
     costs={'knowledge':technology.cost};duration=0;
     prerequisites.addAll(technology.requires.map((id)=>'Conocimiento: ${technologyName(id)}'));
     outcome=technology.effect;
    }
    break;
   case 'explore':
    costs=_explorationCost;workers=4;duration=society==null?null:_explorationDays(society);
    prerequisites.addAll(['Cuatro trabajadores disponibles','Sin otra expedición en marcha']);
    outcome='Una expedición buscará vestigios. Su resultado se conocerá al regresar.';
    break;
   case 'repair':
    costs=_repairCost;duration=0;
    prerequisites.add('Daños en el territorio, viviendas o defensas');
    outcome='Reduce daño territorial y repara capacidad de vivienda o defensa dañada.';
    break;
   case 'facility':
    costs=_facilityCosts[request.choice]??{};
    duration=request.choice=='study'?25:10;
    prerequisites.add('Instalación descubierta y todavía sin resolver');
    outcome='Compromete una respuesta; sus consecuencias se resolverán después.';
    break;
   case 'close_route':
    duration=0;outcome='Ordena regresar y cerrar la ruta. La carga se recupera al llegar al origen, no al pulsar la orden.';break;
   case 'trade':
    workers=world.rulesVersion>=3?2:0;costs={'food':12,'textiles':5};
    prerequisites.addAll(['Otra comunidad viva','Paso terrestre seguro','Relación que permita comerciar','Sin ruta previa entre ambas comunidades']);
    outcome='Abre una ruta y retira su carga inicial de las reservas.';
    break;
   case 'diplomacy':
    costs={'food':10};duration=0;
    prerequisites.add('Otra comunidad viva');
    outcome='Una delegación mejora la confianza entre ambas comunidades.';
    break;
   case 'resolve_event':
    final event=contentEvents.where((e)=>e['id']==request.target).firstOrNull;
    final option=((event?['options'] as List?)??[]).where((o)=>o['id']==request.choice).firstOrNull;
    if(option!=null){
     costs=(option['costs'] as Map).map((key,value)=>MapEntry(_resource(key as String),(value as num).toDouble()));
     outcome=option['description'] as String? ?? 'Aplica la decisión y compromete sus consecuencias.';
     if(world.rulesVersion>=9&&society!=null&&result.ok){var count=0;for(final effect in (option['effects'] as List? ?? [])){if(effect['type']=='population'&&effect['value'] is num&&(effect['value'] as num)>0)count+=(effect['value'] as num).toInt();}if(count>0){final offer=previewMigration(society.id,count);if(offer!=null)outcome+=' Grupo previsto: $count adultos de ${world.society(offer.source)!.name}. Motivo: ${offer.reason}.';}}
    }
    duration=0;
    break;
   case 'policy':
    duration=0;outcome='Actualiza las prioridades que seguirá el gobierno.';
    break;
   case 'control':
    duration=0;outcome='Asume la dirección; las otras comunidades conservan su estado y compromisos.';
    break;
   case 'delegate':
    duration=0;outcome='Los gobiernos siguen sus políticas mientras observas.';
    break;
  }
  return CommandPreview(allowed:result.ok,reason:result.message,code:result.code,
   costs:costs,workers:workers,durationDays:duration,
   prerequisites:prerequisites,outcome:outcome);
 }

 String _id(String prefix){var id='$prefix${world.serial++}';if(world.populationState!=null){while(prefix=='s'&&world.society(id)!=null||prefix=='p'&&world.societies.any((s)=>s.people.any((p)=>p.id==id))){id='$prefix${world.serial++}';}}return id;}
 HistoryEntry record(Society s,String title,String text,String category,{String? cause}){final h=HistoryEntry(_id('h'),world.day,title,text,category,s.id,s.x,s.y,cause:cause);world.chronicle.add(h);if(world.chronicle.length>2400){final referenced={...world.chronicle.map((e)=>e.cause),...world.pending.map((e)=>e.cause),for(final actor in world.societies)for(final lesson in actor.lessons)lesson.cause};int removed=0;world.chronicle.removeWhere((entry){if(removed<400&&!referenced.contains(entry.id)&&entry.id!=h.id){removed++;return true;}return false;});}onHistory?.call(h);return h;}
 bool _pay(Society s,Map<String,double> cost,{String destination='sink:committed',Map<String,String> allocations=const {}}){
 if(s.materialRules==2){
   final amounts=<String,int>{};
   for(final e in cost.entries){if(!resourceIds.contains(e.key)||!e.value.isFinite||e.value<0)throw const FormatException('Coste inválido');final exact=Quantity.fromNumber(e.value);if(exact.millis>0)amounts[e.key]=exact.millis;}
   if(amounts.isEmpty)return true;
   final ledger=MaterialLedger(resourceIds.toSet());
   final initial={for(final e in _resourcesMillis(s).entries)if(e.value>0)e.key:e.value};
   if(initial.isNotEmpty)ledger.transfer(id:'opening',from:'source:opening',to:'inventory',amounts:initial);
   if(amounts.entries.any((e)=>ledger.balance('inventory',e.key)<e.value))return false;
   final groups=<String,Map<String,int>>{};for(final e in amounts.entries){(groups[allocations[e.key]??destination]??={})[e.key]=e.value;}var payment=0;for(final e in groups.entries){ledger.transfer(id:'payment:${payment++}',from:'inventory',to:e.key,amounts:e.value);}
   final updated={for(final r in resourceIds)r:ledger.balance('inventory',r)/1000};
   s.resources=updated;if(captureMaterialPayments)materialPayments.add({'society':s.id,'day':world.day,'ledger':ledger.toJson()});return true;
 }
 if(cost.entries.any((e)=>(s.resources[e.key]??0)<e.value))return false;
 for(final e in cost.entries){s.resources[e.key]=s.resources[e.key]!-e.value;}return true;
 }


 Set<String> _reservedPeople(Society s)=>{
   for(final l in s.lessons)...[l.learner,if(l.teacher!=null)l.teacher!],
   for(final e in world.pending.where((e)=>e.type=='discovery'&&e.societyId==s.id))
     if(e.data['explorerId'] is String)e.data['explorerId'] as String,
 };
 Person? _scout(Society s)=>s.people.where((p)=>p.alive&&
   (world.populationState==null?p.role=='explorador':world.day-p.bornDay>=18*360&&p.competence('scout')>=1000&&!_reservedPeople(s).contains(p.id))).firstOrNull;
 int _explorationDays(Society s)=>world.populationState==null||_scout(s)!=null?8:12;
 LearningQuote _learningQuote(Society s,String? target,String? courseId){
   if(world.populationState==null)return const LearningQuote.rejected('Esta partida necesita convertir sus reglas antes de formar aprendices.');
   final course=courses.where((c)=>c.id==courseId).firstOrNull;
   if(course==null)return const LearningQuote.rejected('Oficio desconocido.');
   final reserved=_reservedPeople(s);Person? learner;PopulationCohort? group;
   if(target=='resident'){
     if(s.people.where((p)=>p.alive).length>=24)return const LearningQuote.rejected('Ya hay 24 habitantes destacados; elige uno de ellos.');
     group=world.populationState!.candidate(s.id,minimumAge:18,maximumAge:60);
     if(group==null)return const LearningQuote.rejected('No hay residentes adultos disponibles para destacar como aprendices.');
   }else{
     learner=s.people.where((p)=>p.id==target&&p.alive&&world.day-p.bornDay>=18*360&&world.day-p.bornDay<65*360&&!reserved.contains(p.id)).firstOrNull;
     if(learner==null)return const LearningQuote.rejected('El aprendiz debe ser un residente adulto libre.');
   }
   final initial=learner?.competence(course.id)??0;
   if(initial>=1000)return const LearningQuote.rejected('Esta persona ya domina ese oficio.');
   final teachers=s.people.where((p)=>p.alive&&p.id!=learner?.id&&world.day-p.bornDay>=18*360&&world.day-p.bornDay<65*360&&p.competence(course.id)>=1000&&!reserved.contains(p.id)).toList()..sort((a,b)=>a.id.compareTo(b.id));
   final teacher=teachers.firstOrNull;
   if(teacher==null&&((s.built['school']??0)==0||!s.supports('writing')||!s.supports(course.manualTechnology)))return const LearningQuote.rejected('Hace falta un maestro vivo disponible, o escuela, escritura y conocimientos especializados para estudiar manuales.');
   final workers=teacher==null?1:2;
   if(s.workers<workers)return const LearningQuote.rejected('No queda personal libre para maestro y aprendiz.');
   final remaining=1000-initial;
   final costs={'food':((teacher==null?20000:10000)*remaining/1000).ceil()/1000,'knowledge':((teacher==null?15000:5000)*remaining/1000).ceil()/1000};
   if(costs.entries.any((e)=>s.resources[e.key]!<e.value))return const LearningQuote.rejected('Faltan alimentos o conocimientos para reservar la formación.');
   return LearningQuote(course:course,teacher:teacher?.id,learner:learner?.id,cohort:group?.id,workers:workers,totalWork:(180*remaining/1000).ceil(),costs:costs);
 }
 void _refundWork(Society s,WorkOrder order){
   if(order.committed.isEmpty)return;
   final ledger=MaterialLedger(resourceIds.toSet());final opening={for(final e in _resourcesMillis(s).entries)if(e.value>0)e.key:e.value};
   if(opening.isNotEmpty)ledger.transfer(id:'opening',from:'source:opening',to:'inventory',amounts:opening);
   ledger.transfer(id:'reserved',from:'source:opening',to:'escrow:work',amounts:order.committed);
   final refund=order.refund,returned={for(final e in order.refund.entries)if(e.value>0)e.key:e.value};
   if(returned.isNotEmpty)ledger.transfer(id:'refund',from:'escrow:work',to:'inventory',amounts:returned);
   final spent={for(final e in order.committed.entries)if(e.value>(refund[e.key]??0))e.key:e.value-(refund[e.key]??0)};
   if(spent.isNotEmpty)ledger.transfer(id:'abandoned',from:'escrow:work',to:'sink:abandoned',amounts:spent);
   s.resources={for(final r in resourceIds)r:ledger.balance('inventory',r)/1000};
   if(captureMaterialPayments)materialPayments.add({'society':s.id,'day':world.day,'ledger':ledger.toJson()});
 }
 void _cancelLearning(Society s,LearningProject l,String reason){
   _refundWork(s,l.work);s.lessons.remove(l);
   record(s,'Formación interrumpida','$reason Se conserva el aprendizaje logrado y se devuelven provisiones no utilizadas.','formación',cause:l.cause);
 }
 void _cleanupLearning(){
   for(final s in world.societies){for(final l in List<LearningProject>.from(s.lessons)){
     bool valid(String id)=>s.people.any((p)=>p.id==id&&p.alive&&world.day-p.bornDay>=18*360&&world.day-p.bornDay<65*360);
     if(!valid(l.learner)||l.teacher!=null&&!valid(l.teacher!))_cancelLearning(s,l,'Un participante ha fallecido, se ha trasladado o se ha retirado.');
   }}
 }
 int _learningTick(Society s,int available){
   var used=0;
   for(final l in List<LearningProject>.from(s.lessons)..sort((a,b)=>a.work.sequence.compareTo(b.work.sequence))){
     final work=l.work;
     if(available<work.workers){work.paused=true;continue;}
     final n=work.advance(available);available-=n;used+=n;
     final learner=s.people.firstWhere((p)=>p.id==l.learner);
     learner.skills[l.course]=l.startingSkill+(1000-l.startingSkill)*(work.totalWork-work.remaining)~/work.totalWork;
     if(work.remaining==0){
       for(final c in courses){learner.skills.putIfAbsent(c.id,()=>learner.competence(c.id));}
       learner.role=courses.firstWhere((c)=>c.id==l.course).role;learner.skill=1;s.lessons.remove(l);
       record(s,'${learner.name} completa su aprendizaje','La formación en ${courses.firstWhere((c)=>c.id==l.course).name.toLowerCase()} ha consumido trabajo y provisiones. Su conocimiento permanece con esa persona.','formación',cause:l.cause);
     }
   }
   return used;
 }
 /// Trusted rule interface for autonomous actions; player callers use submit.
 CommandResult command(String action,{String? societyId,String? target,String? choice}) {
 final s=world.society(societyId??world.controlledId);if(action=='delegate'){world.controlledId=null;return const CommandResult(true,'Todas las comunidades quedan delegadas.');}if(action=='control'){final t=world.society(target);if(t==null||!t.alive)return const CommandResult(false,'Comunidad no disponible.');world.controlledId=t.id;return CommandResult(true,'Ahora guías ${t.name}.');}if(s==null||!s.alive)return const CommandResult(false,'No hay una comunidad viva seleccionada.');if(world.populationState!=null&&!s.people.any((p)=>p.id==s.leaderId&&p.alive&&world.day-p.bornDay>=18*360))return const CommandResult(false,'No hay una dirección adulta capaz de confirmar la orden.');
 if(action=='home'){
   final social=world.socialState,request=world.socialState?.requests[target];
   if(social==null||request==null||request.settlement!=s.id)return const CommandResult(false,'No existe esa petición en tu comunidad.');
   final error=social.canResolve(request.id,world.day,world.socialResidents);if(error!=null)return CommandResult(false,error);
   if(choice=='decline'){social.decline(request.id,world.day,world.socialResidents);record(s,'Una ayuda que no llega','El consejo rechaza financiar el hogar. Sus habitantes conservan autonomía y vínculos.','vida personal');return const CommandResult(true,'Ayuda rechazada; no se imponen sentimientos.');}
   if(choice!='support')return const CommandResult(false,'Respuesta de hogar desconocida.');
   if(s.housing<s.population)return const CommandResult(false,'Hace falta espacio habitable para atender a todos los residentes.');
   if(!_pay(s,{'wood':4,'food':6},destination:'sink:household_setup'))return const CommandResult(false,'El hogar necesita 4 maderas y 6 alimentos.');
   final home=social.resolve(request.id,world.day,world.socialResidents);s.morale=math.min(100,s.morale+2);
   record(s,'Un hogar compartido','Los miembros de ${home.id} establecen su hogar con provisiones reales. No se crean residentes ni parentescos desconocidos.','vida personal');
   return const CommandResult(true,'Hogar establecido; sus miembros y recuerdos se conservarán.');
 }
 if(action=='foster'){
   final social=world.socialState;final adult=s.people.where((p)=>p.id==target&&p.alive&&world.day-p.bornDay>=18*360).firstOrNull;
   final home=adult==null?null:social?.homeOf(adult.id);
   if(social==null||adult==null||home==null)return const CommandResult(false,'La tutela necesita un hogar y un adulto residente.');
   if(s.people.where((p)=>p.alive).length>=24)return const CommandResult(false,'El seguimiento personal está ocupado; los demás cuidados continúan agregados.');
   final group=world.populationState!.candidate(s.id,minimumAge:0,maximumAge:15);
   if(group==null)return const CommandResult(false,'No hay un menor sin identidad destacada disponible para este cuidado.');
   if(!_pay(s,{'food':2,'water':1},destination:'sink:foster_care'))return const CommandResult(false,'El cuidado necesita 2 alimentos y 1 agua.');
   final child=Person(_id('p'),'Menor ${world.serial}','infante',group.bornDay,traitNames[world.random.nextInt(traitNames.length)],skill:0,birthEstimated:group.estimated);
   world.populationState!.register(child.id,group.id);s.people.add(child);
   social.addGuardian(adult.id,child.id,world.day,world.socialResidents);
   record(s,'Una responsabilidad de cuidado','${adult.name} asume la tutela de ${child.name}, que ya vivía en la comunidad. Su parentesco biológico sigue sin documentar.','vida personal');
   return const CommandResult(true,'Tutela registrada sin añadir habitantes ni inventar ascendencia.');
 }
 if(action=='train'){
   final q=_learningQuote(s,target,choice);if(!q.allowed)return CommandResult(false,q.reason);
   final id='learning:${s.id}:${world.day}:${world.serial++}';
   if(!_pay(s,q.costs,destination:'escrow:$id'))return const CommandResult(false,'No se pudieron reservar las provisiones.');
   Person learner;
   if(q.learner!=null){learner=s.people.firstWhere((p)=>p.id==q.learner);}else{
     final group=world.populationState!.cohort(q.cohort!)!;
     learner=Person(_id('p'),'Aprendiz ${world.serial}','aprendiz',group.bornDay,traitNames[world.random.nextInt(traitNames.length)],skill:0,birthEstimated:group.estimated);
     world.populationState!.register(learner.id,group.id);s.people.add(learner);
   }
   final h=record(s,'${learner.name} comienza su aprendizaje',q.teacher==null?'Estudiará manuales en la escuela.':'Aprenderá junto a ${s.people.firstWhere((p)=>p.id==q.teacher).name}.','formación');
   final work=WorkOrder(id:id,totalWork:q.totalWork,remaining:q.totalWork,workers:q.workers,createdDay:world.day,sequence:world.serial++,committed:{for(final e in q.costs.entries)e.key:Quantity.fromNumber(e.value).millis});
   s.lessons.add(LearningProject(id,learner.id,q.course!.id,h.id,work,teacher:q.teacher,startingSkill:learner.competence(q.course!.id)));
   return CommandResult(true,'Formación reservada: ${q.days} días de trabajo.');
 }
 if(action=='cancel_train'){
   final lesson=s.lessons.where((l)=>l.id==target).firstOrNull;
   if(lesson==null)return const CommandResult(false,'No existe esa formación activa.');
   _cancelLearning(s,lesson,'El consejo detiene la formación.');return const CommandResult(true,'Formación cancelada; progreso y devolución registrados.');
 }
 if(action=='close_route'){
   final found=world.routes.where((r)=>r.id==target&&r.transportRules==2&&(r.from==s.id||world.entities?.sameSociety(r.from,s.id)==true));
   if(found.isEmpty)return const CommandResult(false,'No hay una ruta propia que pueda cerrarse.');
   final route=found.first;route.closing=true;if(route.progress==0) {
     _finishRouteAtHome(route);
   } else {
     route.returning=true;
   }
   return const CommandResult(true,'Se ha ordenado el regreso. La carga solo se recupera al llegar al origen.');
 }
 if(action=='cancel_build'){
   final matches=s.projects.where((p)=>p.work?.id==target);if(matches.isEmpty)return const CommandResult(false,'No hay una obra activa con esa identidad.');
   final project=matches.first;_refundWork(s,project.work!);
   s.projects.remove(project);record(s,'Obra cancelada','Se detiene el trabajo y se devuelve la parte no utilizada de los materiales registrados.','construcción');return const CommandResult(true,'Obra cancelada; se libera el trabajo comprometido.');
 }
 if(action=='capital'){
   final graph=world.entities;final city=target==null?null:graph?.cityFor(target);final owner=graph?.societyFor(s.id);
   if(graph==null||city==null||owner==null||city.societyId!=owner.id||world.society(target)?.alive!=true)return const CommandResult(false,'La capital debe ser un asentamiento vivo de tu sociedad.');
   if(owner.capitalId==city.id)return const CommandResult(false,'Ese asentamiento ya es la capital.');
   graph.changeCapital(owner.id,city.id);record(s,'La capital cambia','${world.society(target)!.name} alberga la capital. Los recursos permanecen en sus asentamientos.','política');return const CommandResult(true,'Capital trasladada; se conservan las identidades y reservas locales.');
 }
 if(action=='federate'){
   final graph=world.entities;final other=world.society(target);final owner=graph?.societyFor(s.id);final joining=target==null?null:graph?.societyFor(target);
   if(graph==null||owner==null||joining==null||owner.id==joining.id||other==null||!other.alive)return const CommandResult(false,'No hay dos sociedades vivas distintas.');
   if((s.relations[other.id]??0)<40||(other.relations[s.id]??0)<30)return const CommandResult(false,'La unión requiere confianza mutua: 40 hacia el vecino y 30 de su parte.');
   if(!_pay(s,{'food':20,'knowledge':10}))return const CommandResult(false,'El acuerdo requiere 20 alimentos y 10 conocimientos.');
   graph.federate(owner.id,joining.id);graph.reconcile(world.identityRecords);record(s,'Un pacto de unión','${joining.name} se une a ${owner.name}. Sus ciudades, habitantes y culturas conservan identidad propia.','política');return const CommandResult(true,'Sociedades unidas; las reservas siguen perteneciendo a cada asentamiento.');
 }
 if(action=='policy'){switch(target){case 'balanced':s.policy=Policy();break;case 'food':s.policy.reserve=240;s.policy.expansion=false;s.policy.research='agriculture';s.policy.risk=0.2;break;case 'science':s.policy.research='science';s.policy.risk=0.65;break;case 'trade':s.policy.trade=true;s.policy.diplomacy='cooperate';s.policy.risk=0.25;break;case 'defense':s.policy.diplomacy='defend';s.policy.risk=0.3;s.policy.expansion=false;break;case 'expansion':s.policy.expansion=true;s.policy.risk=0.6;break;case 'isolation':s.policy.trade=false;s.policy.diplomacy='isolate';s.policy.expansion=false;s.policy.risk=0.2;break;default:return const CommandResult(false,'Política desconocida.');}record(s,'Prioridades de gobierno', 'El consejo adopta $target; se conservan al cambiar de comunidad.','política');return const CommandResult(true,'Prioridades actualizadas.');}
 if(action=='repair'){if(world.tiles[s.y*world.size+s.x].damage<=0&&s.housingModifier>=0&&s.defenseModifier>=0)return const CommandResult(false,'No hay daños que reparar.');if(!_pay(s,_repairCost))return const CommandResult(false,'Reparar requiere 10 madera, 8 piedra y 2 herramientas.');final tile=world.tiles[s.y*world.size+s.x];tile.damage=math.max(0.0,tile.damage-0.5);if(s.housingModifier<0)s.housingModifier=math.min(0,s.housingModifier+18);if(s.defenseModifier<0)s.defenseModifier=math.min(0,s.defenseModifier+5);record(s,'Manos que reparan','Se recuperan viviendas dañadas y se limpia parte del territorio.','reparación');return const CommandResult(true,'Reparación completada.');}
 if(action=='build'){if(s.sites.length+s.projects.length>=196)return const CommandResult(false,'La cuadrícula local está ocupada. Funda otro asentamiento.');final matches=buildings.where((b)=>b.id==target);if(matches.isEmpty)return const CommandResult(false,'Edificio desconocido.');final b=matches.first;if(world.rulesVersion>=5){final terrain=world.tiles[s.y*world.size+s.x];if(!b.allowedBiomes.contains(terrain.biome)||terrain.richness<b.minimumRichness)return const CommandResult(false,'El lugar no ofrece el terreno o los recursos necesarios.');final required=b.scenarioRequirements[world.origin];if(required!=null&&!s.supports(required)){final name=technologies.where((t)=>t.capabilities.contains(required)).firstOrNull?.name??'nuevas técnicas';return CommandResult(false,'Este origen necesita desarrollar $name antes de construir aquí.');}}
 if(b.technology!=null&&!s.tech.contains(b.technology))return const CommandResult(false,'Falta la tecnología requerida.');if(s.workers<4||s.projects.length>=math.max(1,s.adults~/12))return const CommandResult(false,'No quedan cuatro trabajadores y capacidad de coordinación disponibles.');final workId='project:${s.id}:${world.day}:${world.serial}';if(!_pay(s,b.cost,destination:world.rulesVersion>=3?'escrow:$workId':'sink:committed'))return const CommandResult(false,'Faltan materiales; no se reservó nada.');
 WorkOrder? work;if(world.rulesVersion>=3){work=WorkOrder(id:workId,totalWork:_constructionDays(b,s)*4,remaining:_constructionDays(b,s)*4,createdDay:world.day,sequence:world.serial++,committed:{for(final e in b.cost.entries)e.key:Quantity.fromNumber(e.value).millis});}
 s.projects.add(Project(b.id,world.day+_constructionDays(b,s),work:work));record(s,'Obra: ${b.name}','Materiales y cuatro trabajadores reservados.','construcción');return CommandResult(true,'${b.name}: ${_constructionDays(b,s)} días.');}
 if(action=='research'){final t=technologies.where((t)=>t.id==target);if(t.isEmpty)return const CommandResult(false,'Tecnología desconocida.');final tech=t.first;if(s.tech.contains(tech.id))return const CommandResult(false,'Conocimiento ya adquirido.');if(!tech.requires.every(s.tech.contains))return const CommandResult(false,'Faltan conocimientos previos.');if(!_pay(s,{'knowledge':tech.cost}))return const CommandResult(false,'Conocimiento insuficiente.');s.tech.add(tech.id);record(s,'Avance: ${tech.name}',tech.effect,'tecnología');return CommandResult(true,'${tech.name} incorporada.');}
 if(action=='explore'){
  if(s.expeditionWorkers>0||world.pending.any((e)=>e.type=='discovery'&&e.societyId==s.id))return const CommandResult(false,'La expedición anterior todavía no ha regresado.');
  if(s.workers<4)return const CommandResult(false,'La expedición necesita cuatro adultos disponibles.');
  final explorer=_scout(s);
  if(!_pay(s,_explorationCost))return const CommandResult(false,'Se necesitan 12 alimentos y 2 herramientas.');
  s.expeditionWorkers=4;
  final h=record(s,explorer==null?'Parte un equipo de exploración':'${explorer.name} parte de expedición','Cuatro adultos buscarán rutas y vestigios durante ${_explorationDays(s)} días.','exploración');
  world.pending.add(ScheduledEvent(_id('e'),'discovery',s.id,world.day+_explorationDays(s),cause:h.id,data:{'workers':4,'explorerId':explorer?.id,if(world.rulesVersion>=3)'remainingWork':_explorationDays(s)*4,if(world.rulesVersion>=3)'assigned':0,if(world.rulesVersion>=3)'paused':false}));
  return const CommandResult(true,'Expedición en camino; cuatro trabajadores reservados.');
 }
 if(action=='facility'){if(!s.facilityFound||s.facilityChoice!=null)return const CommandResult(false,'No hay una instalación pendiente.');final options=_facilityCosts;if(!options.containsKey(choice))return const CommandResult(false,'Respuesta desconocida.');if(!_pay(s,options[choice]!))return const CommandResult(false,'Faltan recursos para esa respuesta.');s.facilityChoice=choice;s.flags.add('facility_committed');final h=record(s,'El destino de la instalación',{'seal':'La entrada queda sellada. Se preserva el entorno.','salvage':'Se recuperan piezas, pero se pierde el archivo.','study':'El equipo técnico estudia el núcleo. El resultado depende de salud y conocimientos.','share':'Se invita a vecinos a compartir el hallazgo.'}[choice]!,'decisión');world.pending.add(ScheduledEvent(_id('e'),'facility_$choice',s.id,world.day+(choice=='study'?25:10),cause:h.id));return const CommandResult(true,'Decisión comprometida; sus consecuencias llegarán.');}
 if(action=='trade'||action=='diplomacy'){final other=world.society(target);if(other==null||other.id==s.id||!other.alive)return const CommandResult(false,'Destino inválido.');if(action=='diplomacy'){if(world.entities?.sameSociety(s.id,other.id)==true)return const CommandResult(false,'Los asentamientos ya pertenecen a la misma sociedad.');if(!_pay(s,{'food':10}))return const CommandResult(false,'Faltan víveres para la delegación.');s.relations[other.id]=math.min(100,(s.relations[other.id]??0)+(s.leaderTrait=='conciliatory'?30:s.leaderTrait=='guarded'?10:20));other.relations[s.id]=math.min(100,(other.relations[s.id]??0)+15);record(s,'Una mesa compartida','El pacto con ${other.name} mejora la confianza.','diplomacia');return const CommandResult(true,'Relaciones mejoradas.');}return _openRoute(s,other);}
 return const CommandResult(false,'Orden desconocida.');
 }
 List<int> findPath(Society a,Society b){final size=world.size,start=a.y*size+a.x,end=b.y*size+b.x;final queue=<int>[start];final prev=<int,int>{start:-1};int head=0;while(head<queue.length){final p=queue[head++];if(p==end)break;final x=p%size,y=p~/size;for(final q in [if(x>0)p-1,if(x<size-1)p+1,if(y>0)p-size,if(y<size-1)p+size]){if(!prev.containsKey(q)&&world.tiles[q].passable&&world.tiles[q].damage<0.9){prev[q]=p;queue.add(q);}}}if(!prev.containsKey(end))return [];final path=<int>[];for(int p=end;p!=-1;p=prev[p]!) {
   path.add(p);
 }return path.reversed.toList();}
 CommandResult _openRoute(Society s,Society other){if(world.routes.any((r)=>(r.from==s.id&&r.to==other.id)||(r.from==other.id&&r.to==s.id)))return const CommandResult(false,'La ruta ya existe.');if((s.relations[other.id]??0)<-20)return const CommandResult(false,'La hostilidad impide comerciar.');final path=findPath(s,other);if(path.isEmpty)return const CommandResult(false,'No existe un paso terrestre seguro.');if(world.rulesVersion>=3&&s.workers<2)return const CommandResult(false,'La ruta necesita dos trabajadores disponibles.');if(!_pay(s,{'food':12,'textiles':5},allocations:world.rulesVersion>=3?{'food':'escrow:route:r${world.serial}','textiles':'sink:transport_gear'}:const {}))return const CommandResult(false,'Falta carga para la caravana.');world.routes.add(TradeRoute(_id('r'),s.id,other.id,path,transportRules:world.rulesVersion>=3?2:1));if(world.rulesVersion>=3)s.transportWorkers+=2;record(s,'Caravana hacia ${other.name}','Transporta 12 alimentos por ${path.length} celdas transitables.','comercio');return const CommandResult(true,'Ruta terrestre establecida.');}
 AdvanceResult advance(AdvanceRequest request){
   if(request.days<0||request.days>360000)throw RangeError.range(request.days,0,360000,'days');
   final advanced=advanceDays(request.days,stopOnCrisis:request.stopOnCrisis,delegateDecisions:request.delegateDecisions);
   final stop=advanced==request.days?AdvanceStop.completed:world.extinct?AdvanceStop.extinct:AdvanceStop.crisis;
   return AdvanceResult(advanced,world.day,stop,world.pending.where((e)=>e.type=='content_choice').map((e)=>e.id));
 }
 bool delegateDecisions=false;
 int advanceDays(int count,{bool stopOnCrisis=false,bool delegateDecisions=false}){world.assertPopulation();this.delegateDecisions=delegateDecisions;int advanced=0;for(int i=0;i<count;i++){if(world.extinct)break;_tick();advanced++;if(stopOnCrisis&&(world.pending.any((e)=>e.type=='content_choice')||world.societies.any((s)=>s.alive&&(s.health<35||(s.resources['food']??0)<s.population*0.5||(s.facilityFound&&s.facilityChoice==null)))))break;}return advanced;}
 void _recordPopulationDeaths(List<String> ids,{String? cause}){
   if(ids.isEmpty)return;final victims=ids.toSet();
   for(final s in world.societies){for(final p in s.people){if(p.alive&&victims.contains(p.id)){p.diedDay=world.day;record(s,'Muere ${p.name}','Su grupo registra la baja; sus vínculos e historia conservan su identidad.','generación',cause:cause);}}}
   _cleanupLearning();world.socialState?.reconcile(world.day,world.socialResidents);
 }
 Person? _promoteResident(Society s,String role){
   final ledger=world.populationState!;final group=ledger.candidate(s.id,minimumAge:18);
   if(group==null)return null;
   final id=_id('p');final person=Person(id,['Alma','Dara','Bruno','Nerea','Elio','Maia'][world.random.nextInt(6)],role,group.bornDay,traitNames[world.random.nextInt(traitNames.length)],birthEstimated:group.estimated);
   ledger.register(id,group.id);s.people.add(person);return person;
 }
 void _ensureLeadership(Society s){
   if(!s.alive){s.leaderId='';return;}
   if(s.people.any((p)=>p.alive&&p.id==s.leaderId&&world.day-p.bornDay>=18*360))return;
   final options=s.people.where((p)=>p.alive&&world.day-p.bornDay>=18*360).toList()..sort((a,b)=>a.id.compareTo(b.id));
   final leader=options.firstOrNull??_promoteResident(s,'dirigente');
   s.leaderId=leader?.id??'';
   if(leader!=null)record(s,'El consejo elige a ${leader.name}','La persona elegida ya formaba parte de la población. Asume los compromisos de la comunidad.','generación');
 }
 void _populationDay(){
   final ledger=world.populationState!;world.assertPopulation(deep:false);
   final expired=ledger.advanceTo(world.day+1);world.day++;
   for(final id in expired){final group=ledger.cohort(id);if(group!=null)_recordPopulationDeaths(ledger.killCohort(id,group.count,world.random.nextInt).people);}
   world.syncPopulation();_cleanupLearning();
   if(world.socialState!=null){for(final s in world.societies){for(final p in s.people.where((p)=>p.alive&&p.role=='infante'&&world.day-p.bornDay>=18*360)){p.role='habitante';record(s,'${p.name} alcanza la edad adulta','Conserva su hogar, cuidados recibidos e identidad. Puede emprender un aprendizaje propio.','vida personal');}}}
   for(final s in world.societies){if(s.population==0)s.extinct=true;_ensureLeadership(s);}
   world.entities?.reconcile(world.identityRecords);
 }
 MigrationOffer? previewMigration(String destination,int count)=>_migrationOffer(world.society(destination),count);
 MigrationOffer? _migrationOffer(Society? to,int count){
   if(to==null||count<1||count>100000||!to.alive||to.policy.diplomacy=='isolate'||to.housing<to.population+count||to.health<40||to.resources['food']!<(to.population+count)*.045*14||to.resources['water']!<(to.population+count)*.035*14)return null;
   final options=<MigrationOffer>[];
   for(final from in world.societies){
     if(!from.alive||from.id==to.id||from.policy.diplomacy=='isolate'||(from.relations[to.id]??0)< -35)continue;
     final eligible=world.populationState!.availableToMove(from.id,1,minimumAge:18,commonOnly:true);
     if(count>math.max(1,eligible~/4)||eligible<count||from.workers-count<4)continue;
     final reasons=<String>[];var pressure=0;
     if(from.housing<from.population){reasons.add('falta de vivienda');pressure+=20+from.population-from.housing;}
     if(from.health<50){reasons.add('problemas de salud');pressure+=((50-from.health)*2).ceil();}
     if(from.morale<35){reasons.add('malestar persistente');pressure+=(35-from.morale).ceil();}
     if(from.resources['food']!<from.population*.045*14){reasons.add('escasez de alimentos');pressure+=40;}
     if(from.resources['water']!<from.population*.035*14){reasons.add('escasez de agua');pressure+=40;}
     if(world.tiles[from.y*world.size+from.x].damage>=.5){reasons.add('daños en el territorio');pressure+=40;}
     if(reasons.isEmpty)continue;
     final before=_production(from,from.workers),after=_production(from,from.workers-count,population:from.population-count);
     if(before.sustainsNeeds&&!after.sustainsNeeds)continue;
     int cover(DailyProduction p,int population){final food=math.max(0,p.closing['food']!-p.opening['food']!),water=math.max(0,p.closing['water']!-p.opening['water']!);return math.min(food*1000000~/math.max(1,population*45),water*1000000~/math.max(1,population*35));}
     if(!before.sustainsNeeds&&cover(after,from.population-count)<cover(before,from.population))continue;
     final path=findPath(from,to);if(path.isEmpty)continue;
     options.add(MigrationOffer(from.id,to.id,count,path.length-1,pressure,reasons.join(', ')));
   }
   options.sort((a,b){var order=b.pressure.compareTo(a.pressure);if(order==0)order=a.distance.compareTo(b.distance);return order==0?a.source.compareTo(b.source):order;});return options.firstOrNull;
 }
 bool _migrationEventContext(Society s,Map event){
   if(world.rulesVersion<9||event['trigger']=='scheduled')return true;
   final counts=<int>[];for(final option in (event['options'] as List? ?? [])){for(final effect in (option['effects'] as List? ?? [])){if(effect['type']=='population'&&effect['value'] is num&&(effect['value'] as num)>0)counts.add((effect['value'] as num).toInt());}}
   if(counts.isEmpty)return true;
   return _migrationOffer(s,counts.reduce(math.min))!=null;
 }
 String? _migrationOptionIssue(Society s,Map option){
   if(world.rulesVersion<9)return null;
   final effects=(option['effects'] as List?)??[];var count=0;
   for(final e in effects){if(e['type']=='population'&&e['value'] is num&&(e['value'] as num)>0)count+=(e['value'] as num).toInt();}
   if(count==0)return null;
   final projected=Society.fromJson(s.toJson())..catalog=s.catalog;
   for(final entry in ((option['costs']??{}) as Map).entries){final r=_resource(entry.key.toString());if(resourceIds.contains(r))projected.resources[r]=math.max(0,projected.resources[r]!-(entry.value as num).toDouble());}
   for(final e in effects){final value=e['value'];
     if(e['type']=='resource'&&value is num){final r=_resource(e['resource'].toString());if(resourceIds.contains(r))projected.resources[r]=(projected.resources[r]!+value).clamp(0,100000).toDouble();}
     if(e['type']=='housing'&&value is num)projected.housingModifier+=value.toInt();
     if(e['type']=='health'&&value is num)projected.health=(projected.health+value).clamp(0,100).toDouble();
     if(e['type']=='technology'&&e['technology'] is String)projected.tech.add(e['technology']);
   }
   if(projected.housing<projected.population+count)return 'Falta vivienda para recibir al grupo completo.';
   if(projected.policy.diplomacy=='isolate')return 'Las fronteras están cerradas por las prioridades del gobierno.';
   if(_migrationOffer(projected,count)==null)return 'No hay una comunidad con motivos de salida, paso seguro y personal suficiente para enviar ese grupo.';
   return null;
 }
 int _receiveMigrants(Society to,int count,{String? cause}){
   final offer=_migrationOffer(to,count);if(offer==null){record(to,'La invitación no reúne condiciones','No se trasladan habitantes: faltan motivos de salida, acceso o capacidad de cuidado.','migración',cause:cause);return 0;}
   final from=world.society(offer.source)!;
   final actual=_transferResidents(from,to,count,1,cause:cause,commonOnly:true,minimumAge:18);
   record(from,'Residentes parten hacia ${to.name}','$actual adultos comunes salen por ${offer.reason}. Se mantienen el cuidado y las identidades de quienes permanecen.','migración',cause:cause);
   record(to,'Llegan residentes de ${from.name}','$actual adultos cambian de residencia conservando edad, cultura y población total.','migración',cause:cause);return actual;
 }
 int _transferResidents(Society from,Society to,int count,int band,{String? cause,bool commonOnly=false,int minimumAge=0}){
   if(count<=0)return 0;
   final moved=world.populationState!.transfer(from.id,to.id,count,band,world.random.nextInt,commonOnly:commonOnly,minimumAge:minimumAge);
   final ids=moved.people.toSet();final people=from.people.where((p)=>ids.contains(p.id)).toList();
   from.people.removeWhere((p)=>ids.contains(p.id));to.people.addAll(people);_cleanupLearning();world.socialState?.reconcile(world.day,world.socialResidents);
   world.syncPopulation();
   if(from.population==0){from.extinct=true;record(from,'Los últimos habitantes parten','La ciudad queda deshabitada; sus residentes y su cultura continúan en otro lugar.','migración',cause:cause);}
   _ensureLeadership(from);_ensureLeadership(to);world.entities?.reconcile(world.identityRecords);
   return moved.count;
 }
 void _populationYear(Society s){
   final ledger=world.populationState!;var deaths=0;
   final groups=ledger.cohorts.where((c)=>c.settlement==s.id).toList()..sort((a,b)=>a.id.compareTo(b.id));
   for(final c in groups){
     final age=ledger.age(c);var rate=age<1?8000:age<16?2000:age<65?3000:(25000+(age-65)*2500).clamp(0,500000).toInt();
     if(s.supports('medicine'))rate=rate*7~/10;
     final expected=c.count*rate;var n=expected~/1000000;
     if(world.random.nextInt(1000000)<expected%1000000)n++;
     n=math.min(n,c.count);if(n>0){final loss=ledger.killCohort(c.id,n,world.random.nextInt);deaths+=loss.count;_recordPopulationDeaths(loss.people);}
   }
   world.syncPopulation();
   if(deaths>0)record(s,'Balance de una generación','$deaths habitantes fallecen por causas naturales; la población y sus grupos registran las mismas bajas.','generación');
   if(s.alive&&s.health>55&&s.housing>s.population&&s.resources['food']!>s.population){
     final parents=<String,int>{};
     for(final group in ledger.cohorts.where((c)=>c.settlement==s.id&&ledger.band(c)==1)){
       final common=ledger.commonIn(group.id);if(common>0)parents[group.culture]=(parents[group.culture]??0)+common;
     }
     final rate=s.supports('biotech')?55000:45000;
     final credits=ledger.birthCredits.putIfAbsent(s.id,()=>{}),due=<String,int>{};
     for(final culture in (parents.keys.toList()..sort())){final total=(credits[culture]??0)+parents[culture]!*rate;credits[culture]=total%1000000;if(total>=1000000)due[culture]=total~/1000000;}
     final intended=due.values.fold<int>(0,(n,v)=>n+v);
     final births=[intended,s.housing-s.population,(s.resources['food']!/2).floor(),s.resources['water']!.floor()].reduce(math.min);
     if(births>0&&_pay(s,{'food':births*2.0,'water':births.toDouble()},destination:'sink:birth_care')){
       final allocated=<String,int>{};var remaining=intended;
       for(var i=0;i<births;i++){
         var draw=world.random.nextInt(remaining);for(final culture in (due.keys.toList()..sort())){if(draw<due[culture]!){due[culture]=due[culture]!-1;allocated[culture]=(allocated[culture]??0)+1;break;}draw-=due[culture]!;}remaining--;
       }
       for(final culture in (allocated.keys.toList()..sort())){ledger.add(settlement:s.id,culture:culture,bornDay:world.day,count:allocated[culture]!);}
       world.syncPopulation();record(s,'Nace una nueva generación','$births nacimientos incorporan grupos infantiles, conservan sus culturas y consumen provisiones de cuidado.','generación');
     }
   }
   if(s.population==0&&!s.extinct){s.extinct=true;record(s,'Silencio en ${s.name}','La comunidad desaparece; sus ruinas y su historia permanecen.','legado');}
   _ensureLeadership(s);world.entities?.reconcile(world.identityRecords);
   if(s.alive&&s.policy.expansion&&s.population>(s.leaderTrait=='restless'?80:95)&&s.resources['food']!>300&&world.societies.length<40)_foundPopulationColony(s);
 }
 void _foundPopulationColony(Society s){
   if(s.children<5||s.adults<20)return;
   final x=(s.x+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt(),y=(s.y+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt();
   if(!world.tiles[y*world.size+x].passable||world.societies.any((o)=>(o.x-x).abs()+(o.y-y).abs()<5))return;
   const cost={'food':150.0,'water':150.0,'wood':80.0,'stone':40.0,'tools':10.0};
   if(!_pay(s,cost,destination:'escrow:founding'))return;
   final c=Society(_id('s'),'${s.culture} · ${world.societies.length+1}',s.profile,x,y,children:0,adults:0,elders:0,founded:world.day,culture:s.culture,siteLayout:s.siteLayout,materialRules:s.materialRules);
   c.catalog=world.catalog;c.resources={for(final r in resourceIds)r:0};c.resources.addAll(cost);
   c.built={};c.sites=[];c.tech=Set.from(s.tech);c.people=[];c.leaderId='';
   final city=world.entities!.cityFor(s.id)!;
   world.societies.add(c);world.entities!.addColony(actorId:c.id,ownerId:city.societyId,cultureId:city.cultureId);
   _transferResidents(s,c,5,0);_transferResidents(s,c,20,1);
   c.relations[s.id]=50;s.relations[c.id]=50;
   // The first refuge uses the ordinary command, costs and actual work. No
   // finished buildings are duplicated out of the founding supplies.
   command('build',societyId:c.id,target:world.buildingDefinitions.any((b)=>b.id=='shelter')?'shelter':'house');
   record(s,'Se funda ${c.name}','25 residentes y sus provisiones establecen una ciudad de la misma sociedad. El refugio aún necesita trabajo.','expansión');
 }

 void _tick(){if(world.populationState!=null){_populationDay();}else{world.day++;}final actors=List<Society>.from(world.societies);final worked=<String,int>{};final dailyAdults={for(final s in actors)s.id:s.adults};
 if(world.rulesVersion>=3){
   actors.sort((a,b)=>a.id.compareTo(b.id));
   if(world.rulesVersion>=9){for(final s in actors){if(world.rulesVersion>=10)_trimAutonomousTransport(s);_urgentAutonomy(s);}}
   for(final s in actors){
     if(!s.alive)continue;var available=math.max(0,s.adults-(world.rulesVersion>=10?_essentialWorkers(s):0)),used=0;
     final routes=world.routes.where((r)=>r.from==s.id&&r.transportRules==2).toList()..sort((a,b){if(world.rulesVersion>=10){final priority=(a.closing?0:1).compareTo(b.closing?0:1);if(priority!=0)return priority;final distance=a.progress.compareTo(b.progress);if(a.closing&&distance!=0)return distance;}return a.id.compareTo(b.id);});
     for(final r in routes){r.crewAssigned=available>=2?2:0;available-=r.crewAssigned;used+=r.crewAssigned;}
     final expeditions=world.pending.where((e)=>e.type=='discovery'&&e.societyId==s.id).toList()..sort((a,b)=>a.id.compareTo(b.id));
     for(final e in expeditions){e.data=Map<String,dynamic>.from(e.data);final remaining=(e.data['remainingWork'] as int? ?? math.max(0,e.day-world.day+1)*4);final assigned=math.min(4,math.min(available,remaining));available-=assigned;used+=assigned;e.data['remainingWork']=remaining-assigned;e.data['assigned']=assigned;e.data['paused']=remaining>0&&assigned==0;e.day=remaining-assigned==0?world.day:world.day+(assigned==0?1:((remaining-assigned)/assigned).ceil());}
     final learning=_learningTick(s,available);available-=learning;used+=learning;used+=_projects(s,available:available);worked[s.id]=used;
   }
   final travel=List<TradeRoute>.from(world.routes)..sort((a,b)=>a.id.compareTo(b.id));for(final r in travel){_routeTick(r);}
 }
 for(final s in actors){if(!s.alive)continue;_economy(s,laborAvailable:world.rulesVersion>=3?math.max(0,(world.populationState==null?s.adults:math.min(s.adults,dailyAdults[s.id]??0))-(worked[s.id]??0)):null);if(world.rulesVersion<3)_projects(s);if(world.day%30==0){_monthly(s);_directContent(s);}if(world.day%360==0)_yearly(s);}final due=world.pending.where((e)=>e.day<=world.day).toList()..sort((a,b){final c=a.day.compareTo(b.day);return c==0?a.id.compareTo(b.id):c;});for(final e in due){world.pending.remove(e);final s=world.society(e.societyId);if(s!=null&&e.type=='discovery')s.expeditionWorkers=0;if(s==null||!s.alive)continue;_resolve(s,e);}if(world.rulesVersion<3){for(final r in List<TradeRoute>.from(world.routes)) {
   _routeTick(r);
 }}world.assertPopulation(deep:false);world.entities?.reconcile(world.identityRecords);if(world.day%360==0){world.annualSnapshots['${world.day}']={'population':world.societies.fold<int>(0,(int p,s)=>p+s.population),'settlements':world.societies.where((s)=>s.alive).length,'technologies':world.societies.fold<int>(0,(int p,s)=>p+s.tech.length),'damage':world.societies.fold<double>(0.0,(double p,s)=>p+s.environment)};if(world.annualSnapshots.length>1000)world.annualSnapshots.remove(world.annualSnapshots.keys.first);}}
 int _exportDemand(Society s){
   var total=0;for(final r in world.routes.where((r)=>r.from==s.id&&r.transportRules==2&&!r.closing)){total+=((s.supports('trade')||s.leaderTrait=='generous'?16000:12000)/math.max(1,(r.path.length-1)*2)).ceil();}return total;
 }
 Map<String,int> _reserveGoals(Society s,int population){
   final food=math.max((s.policy.reserve*1000).ceil(),population*45*60);
   return {'food':world.rulesVersion>=9&&s.leaderTrait=='patient'?(food*13+9)~/10:food,'water':population*35*60};
 }
 void _urgentAutonomy(Society s){
   if(world.rulesVersion<9||!s.alive||(s.id==world.controlledId&&!delegateDecisions))return;
   if(s.resources['food']!>=s.population*.045*14&&s.resources['water']!>=s.population*.035*14)return;
   final target=_autonomousVitalBuilding(s);if(target==null||s.projects.any((p)=>p.building==target))return;
   command('build',societyId:s.id,target:target);
 }
 /// Reserve only work that can actually produce scarce daily rations. Missing
 /// infrastructure must not lock every adult out of building the needed well.
 int _essentialWorkers(Society s){
   if(s.resources['food']!>=s.population*.045*14&&s.resources['water']!>=s.population*.035*14)return 0;
   final plan=_production(s,s.adults,essentialOnly:true);
   return math.min(s.adults,(plan.laborUsed+999)~/1000);
 }
 void _trimAutonomousTransport(Society s){
   if(!s.alive||(s.id==world.controlledId&&!delegateDecisions))return;
   final care=_essentialWorkers(s);if(care==0)return;
   final routes=world.routes.where((r)=>r.from==s.id&&r.transportRules==2).toList();
   final excess=routes.length-math.max<int>(0,(s.adults-care)~/2);
   if(excess<=0)return;
   final closing=routes.where((r)=>r.closing).length;
   final candidates=routes.where((r)=>!r.closing).toList()..sort((a,b){final home=a.progress.compareTo(b.progress);return home!=0?home:a.id.compareTo(b.id);});
   final selected=candidates.take(math.max(0,excess-closing)).toList();
   for(final route in selected){command('close_route',societyId:s.id,target:route.id);}
   if(selected.isNotEmpty)record(s,'Se reorganiza el transporte','${selected.length} caravanas reciben orden de regreso para sostener alimento y agua. Las cargas que están en camino regresarán por su trayecto.','trabajo');
 }
 String? _autonomousVitalBuilding(Society s){
   final plan=_production(s,s.workers),reserve=_reserveGoals(s,s.population);
   final minimum={'food':s.population*45+_exportDemand(s),'water':s.population*35};
   final needed=<String,bool>{};
   for(final r in ['food','water']){final refill=(math.max(0,reserve[r]!-Quantity.fromNumber(s.resources[r]!).millis)+29)~/30;needed[r]=plan.closing[r]!-plan.opening[r]!<minimum[r]!+refill;}
   final food=world.origin=='prehistory'&&!s.supports('agriculture')?'foraging_camp':'farm';
   final water=world.origin=='prehistory'&&!s.supports('masonry')?'water_collect':'well';
   bool more(String id){final b=buildings.where((b)=>b.id==id).firstOrNull;if(b==null)return false;final tile=world.tiles[s.y*world.size+s.x];return b.allowedBiomes.contains(tile.biome)&&tile.richness>=b.minimumRichness&&(b.capacityPerRichness==0||(s.built[id]??0)+s.projects.where((p)=>p.building==id).length<tile.richness*b.capacityPerRichness);}
   final foodNeed=needed['food']!&&more(food),waterNeed=needed['water']!&&more(water);
   if(foodNeed&&waterNeed){final foodDays=s.resources['food']!/math.max(.001,minimum['food']!/1000),waterDays=s.resources['water']!/math.max(.001,minimum['water']!/1000);return waterDays<foodDays?water:food;}
   return foodNeed?food:waterNeed?water:null;
 }
 DailyProduction _production(Society s,int available,{int? population,bool essentialOnly=false}){
   var efficiency=s.health/100;
   efficiency*=s.leaderTrait=='pragmatic'?1.25:1;
   efficiency*=s.supports('cybernetics')?1.2:1;efficiency*=s.supports('automation')?1.5:1;
   efficiency*=s.supports('metallurgy')?1.15:1;efficiency*=s.supports('industry')?1.25:1;efficiency*=s.supports('robotics')?1.2:1;
   final tile=world.tiles[s.y*world.size+s.x],reserved=_reservedPeople(s);
   final craft=s.people.any((p)=>p.alive&&world.day-p.bornDay>=18*360&&world.day-p.bornDay<65*360&&p.competence('craft')>=1000&&!reserved.contains(p.id));
   final capacities=<ProducerCapacity>[];
   for(final b in buildings){
     var n=s.built[b.id]??0;if(n==0||b.yield.isEmpty||!b.allowedBiomes.contains(tile.biome)||tile.richness<b.minimumRichness)continue;
     if(b.capacityPerRichness>0)n=math.min(n,tile.richness*b.capacityPerRichness);
     final outputs=<String,int>{};
     for(final e in b.yield.entries){var value=e.value*efficiency;
       if(e.key=='knowledge'){if(b.id=='oral_circle'&&s.supports('oral_teaching'))value*=1.4;value*=s.leaderTrait=='inventive'?1.3:s.leaderTrait=='traditional'?0.85:1;value*=s.supports('writing')?1.15:1;value*=s.supports('computing')?1.3:1;}
       if(e.key=='medicine'&&s.supports('chemistry'))value*=1.5;if(e.key=='energy'&&s.supports('fusion'))value*=3;
       if(e.key=='food'){value*=[1.15,1.0,.65,.6,1.1,.8][tile.biome];value*=s.supports('agriculture')?1.4:1;value*=s.supports('irrigation')?1.3:1;value*=1-s.environment*.004;}
       outputs[e.key]=math.max(0,(value*1000).floor());
     }
     final inputFactor=craft&&['knapping_shed','fiber_weave','workshop'].contains(b.id)?0.9:1.0;
     capacities.add(ProducerCapacity(b.id,n,outputs,inputs:{for(final e in b.dailyInputs.entries)e.key:(e.value*inputFactor*1000).ceil()}));
   }
   final export=_exportDemand(s);
   final pop=population??s.population;
   return planProduction(stocks:_resourcesMillis(s),producers:capacities,workers:math.max(0,available),
     minimumYield:{'food':pop*45+export,'water':pop*35},
     reserveStocks:essentialOnly?{}:_reserveGoals(s,pop),
     otherTargets:essentialOnly?{}:{'wood':(200+pop)*1000,'stone':(100+pop)*1000,'tools':math.max(20000,pop*500),'knowledge':math.max(120000,pop*2000),'medicine':math.max(20000,pop*500),'textiles':math.max(20000,pop*500),'energy':60000,'fuel':60000,'crystal':20000},educated:s.supports('education'));
 }
 bool _canOpenAutonomousRoute(Society s){
   if(world.rulesVersion<8)return true;
   final plan=_production(s,s.workers);
   return plan.sustainsNeeds&&s.workers*1000>=plan.essentialLabor+6000;
 }
 void _allocatedEconomy(Society s,int workers){
   final plan=_production(s,workers);final resources={for(final e in plan.closing.entries)e.key:e.value/1000};
   final food=s.population*45,water=s.population*35;
   final foodUsed=math.min(food,plan.closing['food']!),waterUsed=math.min(water,plan.closing['water']!);
   resources['food']=(plan.closing['food']!-foodUsed)/1000;resources['water']=(plan.closing['water']!-waterUsed)/1000;s.resources=resources;
   s.lastProduction={'day':world.day,'flows':plan.toJson(),'foodNeed':food,'waterNeed':water,'foodUsed':foodUsed,'waterUsed':waterUsed};
   final hunger=foodUsed<food,thirst=waterUsed<water;
   s.health=(s.health+(hunger?-.65:.04)+(thirst?-.9:.02)+(s.supports('sanitation')?0.02:0)).clamp(0,100).toDouble();
   s.morale=(s.morale+(s.supports('synthesis')?0.02:0)+(hunger?-.25:.015)+(s.population>s.housing?-.03:.01)).clamp(0,100).toDouble();
   if((hunger||thirst)&&world.day%30==0)record(s,'Reservas agotadas','La escasez reduce salud y obliga a cambiar prioridades.','necesidad');
   s.environment=(s.environment+(s.built['generator']??0)*.001+(s.built['mine']??0)*.001-(s.supports('ecology')||s.leaderTrait=='green'?0.008:.001)).clamp(0,100).toDouble();
 }
 void _economy(Society s,{int? laborAvailable}){if(world.rulesVersion>=8){_allocatedEconomy(s,laborAvailable??s.workers);return;}final workers=laborAvailable??s.workers;double multiplier=math.min(1,workers/math.max(1,s.built.values.fold<int>(0,(int a,b)=>a+b)*2));multiplier*=s.health/100;multiplier*=s.leaderTrait=='pragmatic'?1.25:1;multiplier*=s.supports('cybernetics')?1.2:1;multiplier*=world.rulesVersion>=4?1:1+s.tech.length*0.01;multiplier*=s.supports('automation')?1.5:1;if(s.supports('metallurgy'))multiplier*=1.15;if(s.supports('industry'))multiplier*=1.25;if(s.supports('robotics'))multiplier*=1.2;for(final b in buildings){final total=s.built[b.id]??0;final n=world.rulesVersion>=5&&b.capacityPerRichness>0?math.min(total,world.tiles[s.y*world.size+s.x].richness*b.capacityPerRichness):total;if(n==0)continue;if(world.rulesVersion>=5){final tile=world.tiles[s.y*world.size+s.x];if(!b.allowedBiomes.contains(tile.biome)||tile.richness<b.minimumRichness)continue;}var activity=n*multiplier;final craft=world.populationState!=null&&workers>0&&s.people.any((p)=>p.alive&&world.day-p.bornDay>=18*360&&world.day-p.bornDay<65*360&&p.competence('craft')>=1000&&!_reservedPeople(s).contains(p.id))&&['knapping_shed','fiber_weave','workshop'].contains(b.id)?0.9:1.0;
 if(world.rulesVersion>=4){
   for(final input in b.dailyInputs.entries){if(input.value>0)activity=math.min(activity,s.resources[input.key]!/(input.value*craft));}
   if(activity<=0)continue;
   for(final input in b.dailyInputs.entries){final available=Quantity.fromNumber(s.resources[input.key]!).millis;final required=(input.value*craft*activity*1000).ceil();s.resources[input.key]=(available-math.min(available,required))/1000;}
 }else{if(b.id=='generator'&&(s.resources['fuel']??0)<0.08*n)continue;if(b.id=='generator')s.resources['fuel']=math.max(0.0,s.resources['fuel']!-0.08*n);if(b.id=='workshop'&&(s.resources['metal']??0)<0.04*n)continue;if(b.id=='workshop')s.resources['metal']=math.max(0.0,s.resources['metal']!-0.04*n);}
 for(final e in b.yield.entries){double output=e.value*(world.rulesVersion>=4?activity:n*multiplier);if(e.key=='knowledge'){if(b.id=='oral_circle'&&s.supports('oral_teaching'))output*=1.4;output*=s.leaderTrait=='inventive'?1.3:s.leaderTrait=='traditional'?0.85:1;output*=s.supports('writing')?1.15:1;output*=s.supports('computing')?1.3:1;}if(e.key=='medicine'&&s.supports('chemistry'))output*=1.5;if(e.key=='energy'&&s.supports('fusion'))output*=3;if(e.key=='food'){output*=[1.15,1.0,0.65,0.6,1.1,0.8][world.tiles[s.y*world.size+s.x].biome];output*=s.supports('agriculture')?1.4:1;output*=s.supports('irrigation')?1.3:1;output*=1-s.environment*0.004;}s.resources[e.key]=math.min(100000.0,(s.resources[e.key]??0)+math.max(0.0,output));}}
 s.resources['wood']=math.min(100000.0,s.resources['wood']!+workers*0.015);s.resources['knowledge']=math.min(100000.0,s.resources['knowledge']!+workers*(s.supports('education')?0.012:0.006));final foodNeed=s.population*0.045,waterNeed=s.population*0.035;bool hunger=s.resources['food']!<foodNeed,thirst=s.resources['water']!<waterNeed;s.resources['food']=math.max(0.0,s.resources['food']!-foodNeed);s.resources['water']=math.max(0.0,s.resources['water']!-waterNeed);s.health=(s.health+(hunger?-0.65:0.04)+(thirst?-0.9:0.02)+(s.supports('sanitation')?0.02:0)).clamp(0,100).toDouble();s.morale=(s.morale+(s.supports('synthesis')?0.02:0)+(hunger?-0.25:0.015)+(s.population>s.housing?-0.03:0.01)).clamp(0,100).toDouble();if(hunger||thirst){if(world.day%30==0)record(s,'Reservas agotadas','La escasez reduce salud y obliga a cambiar prioridades.','necesidad');}s.environment=(s.environment+(s.built['generator']??0)*0.001+(s.built['mine']??0)*0.001-(s.supports('ecology')||s.leaderTrait=='green'?0.008:0.001)).clamp(0,100).toDouble();
 }
 int _projects(Society s,{int? available}){
   var budget=available??math.max(0,s.adults-s.expeditionWorkers-s.transportWorkers);var usedTotal=0;
   final ordered=List<Project>.from(s.projects);
   if(world.rulesVersion>=3)ordered.sort((a,b){final day=(a.work?.createdDay??0).compareTo(b.work?.createdDay??0);if(day!=0)return day;return (a.work?.sequence??0).compareTo(b.work?.sequence??0);});
   for(final p in ordered){
     if(p.work!=null){final used=p.work!.advance(budget);budget-=used;usedTotal+=used;if(p.work!.remaining>0){if(used>0)p.finish=world.day+(p.work!.remaining/used).ceil();continue;}}
     else if(p.finish>world.day){continue;}
     s.projects.remove(p);s.built[p.building]=(s.built[p.building]??0)+1;s.addSite(p.building);final b=buildings.firstWhere((b)=>b.id==p.building);record(s,'${b.name} terminado','El edificio ya produce y ocupa su lugar en ${s.name}.','construcción');
   }
   return usedTotal;
 }

 void _socialMonth(Society s){
   final social=world.socialState;if(social==null)return;
   final residents=world.socialResidents;social.reconcile(world.day,residents);
   final adults=s.people.where((p)=>p.alive&&world.day-p.bornDay>=18*360).toList()..sort((a,b)=>a.id.compareTo(b.id));
   if(adults.length>=2){
     final first=world.random.nextInt(adults.length),second=(first+1+world.random.nextInt(adults.length-1))%adults.length;
     final a=adults[first],b=adults[second];
     final bond=social.meet(a.id,b.id,world.day,wantsA:world.random.nextInt(100)<35,wantsB:world.random.nextInt(100)<35);
     final friction=s.morale<25&&world.random.nextInt(3)==0;
     bond.friendship=(bond.friendship+(friction?-8:5)).clamp(-100,100).toInt();bond.trust=(bond.trust+(friction?-6:4)).clamp(-100,100).toInt();
     bond.rivalry=(bond.rivalry+(friction?5:-1)).clamp(0,100).toInt();
     bond.affectionA=(bond.affectionA+(friction?-4:3)).clamp(-100,100).toInt();bond.affectionB=(bond.affectionB+(friction?-4:3)).clamp(-100,100).toInt();
     if(bond.status=='acquaintance'&&bond.friendship>=15)bond.status='friends';
     if(['friends','separated'].contains(bond.status)&&bond.wantsA&&bond.wantsB&&!social.related(a.id,b.id)&&bond.affectionA>=30&&bond.affectionB>=30&&bond.trust>=30){
       bond.status='romance';record(s,'${a.name} y ${b.name} se acercan','Dos adultos deciden iniciar una relación por voluntad mutua. Su vida íntima queda fuera de la crónica pública.','vida personal');
     }
     if(bond.status=='romance'&&bond.trust< -20){bond.status='separated';final home=social.homeOf(b.id);if(home!=null&&home==social.homeOf(a.id)){home.left[b.id]=world.day;social.memories.add({'kind':'separation','people':[a.id,b.id],'day':world.day,'reference':home.id});}record(s,'Una relación termina','${a.name} y ${b.name} dejan de ser pareja. Su historia compartida permanece.','vida personal');}
     final request=social.requestHome(a.id,b.id,s.id,world.day,residents);
     if(request!=null)record(s,'Una petición de hogar','${a.name} y ${b.name} quieren organizar un hogar compartido. Puedes ayudar con provisiones; su relación personal no depende de una orden.','vida personal');
   }
   if(s.id!=world.controlledId||delegateDecisions){
     final pending=social.requests.values.where((r)=>r.settlement==s.id&&r.status=='pending').toList();
     for(final r in pending){if(s.resources['food']!>s.policy.reserve+6&&s.resources['wood']!>=4)command('home',societyId:s.id,target:r.id,choice:'support');}
   }
   social.reconcile(world.day,world.socialResidents);
 }
 void _monthly(Society s){_socialMonth(s);if(s.health<30&&s.population>0){final losses=math.max(1,(s.population*0.03).floor());_removePeople(s,losses);record(s,'Pérdidas por privación','$losses habitantes murieron; la comunidad recuerda la pérdida.','necesidad');}if(!s.alive)return;if(s.population==0){s.extinct=true;return;}if(s.id!=world.controlledId||delegateDecisions)_autonomy(s);if(world.random.nextInt(18)==0)_ambient(s);if(s.facilityFound&&s.facilityChoice==null&&(s.id!=world.controlledId||delegateDecisions)){final c=s.risk>0.6?'study':s.policy.diplomacy=='cooperate'?'share':'seal';command('facility',societyId:s.id,choice:c);record(s,'Resolución delegada','El consejo eligió $c según su política.','política');}}
 void _autonomy(Society s){final autonomous=s.id!=world.controlledId||(world.rulesVersion>=5&&delegateDecisions);final food=s.resources['food']!;final foodReserve=world.rulesVersion>=8?math.max(s.policy.reserve,s.population*.045*60):s.policy.reserve;if(s.projects.length<math.max(1,s.adults~/12)){String? target;if(world.rulesVersion>=9)target=_autonomousVitalBuilding(s);if(target==null&&world.rulesVersion<9&&(food<foodReserve*(s.leaderTrait=='patient'?1.3:1)||(s.built[world.origin=='prehistory'&&!s.supports('agriculture')?'foraging_camp':'farm']??0)<(s.population/(world.origin=='prehistory'&&!s.supports('agriculture')?20:35)).ceil())) {
   target=world.origin=='prehistory'&&!s.supports('agriculture')?'foraging_camp':'farm';
 } else if(target==null&&world.rulesVersion<9&&s.resources['water']!<(world.rulesVersion>=8?math.max(100,s.population*.035*60):100)){target=world.origin=='prehistory'&&!s.supports('masonry')?'water_collect':'well';}else if(target==null&&s.housing<s.population+12){target=world.origin=='prehistory'&&!s.supports('masonry')?'shelter':'house';}else if(target==null&&autonomous&&world.random.nextInt(3)==0){if(world.origin=='prehistory'){world.random.nextInt(4);target=(s.built['surface_stone']??0)==0?'surface_stone':s.supports('handcraft')&&(s.built['knapping_shed']??0)==0?'knapping_shed':s.supports('handcraft')&&(s.built['fiber_weave']??0)==0?'fiber_weave':null;}else{target=['sawmill','school','quarry','loom'][world.random.nextInt(4)];}}if(world.rulesVersion>=8&&target!=null&&!['farm','foraging_camp','well','water_collect','house','shelter'].contains(target)&&(s.built[target]??0)>=math.max(1,s.adults~/40))target=null;if(target!=null)command('build',societyId:s.id,target:target);}
 if(autonomous&&world.populationState!=null&&s.lessons.isEmpty&&food>s.population*3&&s.resources['water']!>s.population*2&&s.workers>=4){for(final c in courses){final experts=s.people.where((p)=>p.alive&&p.competence(c.id)>=1000);if(experts.length==1&&(world.day-experts.first.bornDay)~/360>=50){if(command('train',societyId:s.id,target:'resident',choice:c.id).ok)break;}}}
 if(autonomous){final preferred=technologies.where((t)=>t.id==s.policy.research&&!s.tech.contains(t.id)&&t.requires.every(s.tech.contains)&&(world.rulesVersion<5||s.resources['knowledge']!>=t.cost));final available=technologies.where((t)=>!s.tech.contains(t.id)&&t.requires.every(s.tech.contains)&&(world.rulesVersion<5||s.resources['knowledge']!>=t.cost)).toList();if(world.origin=='prehistory')available.sort((a,b)=>a.cost==b.cost?a.id.compareTo(b.id):a.cost.compareTo(b.cost));if(preferred.isNotEmpty) {
   command('research',societyId:s.id,target:preferred.first.id);
 } else if(available.isNotEmpty){command('research',societyId:s.id,target:available.first.id);}if(s.policy.trade&&world.day%180==0&&_canOpenAutonomousRoute(s)){final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isNotEmpty)command('trade',societyId:s.id,target:others[world.random.nextInt(others.length)].id);}if(!s.facilityFound&&world.day%(s.supports('orbital')?360:720)==0)command('explore',societyId:s.id);}
 if(s.health<45&&s.population>15){final candidates=world.societies.where((o)=>o.alive&&o.id!=s.id&&o.health>65&&o.housing>o.population+4).toList();if(candidates.isNotEmpty){final to=candidates.first;final n=math.min(4,s.adults);if(world.rulesVersion>=9){final offer=_migrationOffer(to,n);if(offer==null||offer.source!=s.id)return;_receiveMigrants(to,n);return;}if(world.populationState!=null){_transferResidents(s,to,n,1);}else{s.adults-=n;to.adults+=n;}record(s,'Familias emigran','$n adultos se trasladan a ${to.name} buscando seguridad.','migración');record(to,'Llegan refugiados','$n adultos de ${s.name} se incorporan sin duplicar población.','migración');}}
 }
 void _yearly(Society s){if(world.populationState!=null){_populationYear(s);return;}final r=world.random;int cohort(String id,double rate){if(s.materialRules==2){final total=(s.demographicMicros[id]??0)+(rate*1000000).round();s.demographicMicros[id]=total%1000000;return total~/1000000;}final total=(s.demographicCarry[id]??0)+rate;final count=total.floor();s.demographicCarry[id]=total-count;return count;} final grown=math.min(s.children,cohort('grown',s.children/16));s.children-=grown;s.adults+=grown;final aged=math.min(s.adults,cohort('aged',s.adults/45));s.adults-=aged;s.elders+=aged;final oldDeaths=math.min(s.elders,cohort('oldDeaths',s.elders*(s.supports('medicine')?0.05:0.09)));s.elders-=oldDeaths;final births=(s.health>55&&s.housing>s.population&&s.resources['food']!>s.population)?cohort('births',s.adults*(s.supports('biotech')?0.055:0.045)):0;s.children+=math.min(births,math.max(0,s.housing-s.population));for(final p in s.people.where((p)=>p.alive)){final age=(world.day-p.bornDay)~/360;if(age>72&&(r.nextInt(100)<(age-70)*5||age>100)){p.diedDay=world.day;record(s,'Muere ${p.name}','Su trabajo y sus decisiones quedan en la memoria de ${s.culture}.','generación');}}
 if(!s.people.any((p)=>p.alive&&p.id==s.leaderId)&&s.adults>0){final id=_id('p');final p=Person(id,['Alma','Dara','Bruno','Nerea','Elio','Maia'][r.nextInt(6)],'dirigente',world.day-(22+r.nextInt(24))*360,traitNames[r.nextInt(traitNames.length)]);s.people.add(p);s.leaderId=id;record(s,'Una nueva generación dirige','${p.name}, de carácter ${p.trait}, asume los compromisos existentes.','generación');}if(s.people.where((p)=>p.alive&&p.role=='técnica').isEmpty&&s.adults>10){s.people.add(Person(_id('p'),'Aprendiz ${world.day~/360}','técnica',world.day-24*360,'inventive'));}
 if(s.policy.expansion&&s.population>(s.leaderTrait=='restless'?80:95)&&s.resources['food']!>300&&world.societies.length<40){_colonize(s);}if(s.population==0&&!s.extinct){s.extinct=true;record(s,'Silencio en ${s.name}','La comunidad desaparece; sus ruinas y su historia permanecen.','legado');}world.entities?.reconcile(world.identityRecords);}
 void _colonize(Society s){if(world.populationState!=null){_foundPopulationColony(s);return;}if(s.children<5||s.adults<20)return;final x=(s.x+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt(),y=(s.y+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt();if(!world.tiles[y*world.size+x].passable||world.societies.any((o)=>((o.x-x).abs()+(o.y-y).abs())<5))return;const cost={'food':150.0,'wood':80.0,'stone':40.0,'tools':10.0};if(!_pay(s,cost))return;final c=Society(_id('s'),'${s.culture} · ${world.societies.length+1}',s.profile,x,y,children:5,adults:20,elders:0,founded:world.day,culture:s.culture,siteLayout:s.siteLayout,materialRules:s.materialRules);c.catalog=world.catalog;c.resources={for(final r in resourceIds)r:0};c.resources.addAll(cost);c.built={'farm':1,'well':1,'house':2};c.tech=Set.from(s.tech);c.people=[Person(_id('p'),'Vera','dirigente',world.day-30*360,'patient')];c.leaderId=c.people.first.id;s.children-=5;s.adults-=20;c.relations[s.id]=50;s.relations[c.id]=50;c.ensureSites();world.societies.add(c);record(s,'Nace ${c.name}','25 habitantes y recursos reales fundan una colonia vinculada a su cultura.','expansión');}
 void _removePeople(Society s,int n,{String? cause}){if(world.populationState!=null){final loss=world.populationState!.remove(s.id,math.min(n,s.population),world.random.nextInt);_recordPopulationDeaths(loss.people,cause:cause);world.syncPopulation();if(s.population==0&&!s.extinct){s.extinct=true;record(s,'La comunidad cae','No queda población capaz de actuar. Sus ruinas conservan su legado.','legado',cause:cause);}_ensureLeadership(s);world.entities?.reconcile(world.identityRecords);return;}int v=math.min(n,s.elders);s.elders-=v;n-=v;v=math.min(n,s.adults);s.adults-=v;n-=v;s.children=math.max(0,s.children-n);if(s.population==0){s.extinct=true;for(final p in s.people.where((p)=>p.alive)) {
   p.diedDay=world.day;
 }record(s,'La comunidad cae','No queda población capaz de actuar. Las ruinas conservan su legado.','legado');world.entities?.reconcile(world.identityRecords);}}
 void _finishRouteAtHome(TradeRoute r){
   final source=world.society(r.from);if(source==null||!source.alive){r.blocked=true;return;}
   source.resources['food']=source.resources['food']!+r.cargo;source.resources['metal']=source.resources['metal']!+r.metalMillis/1000;
   r.cargo=0;r.metalMillis=0;source.transportWorkers=math.max(0,source.transportWorkers-2);world.routes.remove(r);
   record(source,'Una ruta se cierra','La caravana regresa y entrega su carga restante.','comercio');
 }
 void _transportTick(TradeRoute r){
   final a=world.society(r.from),b=world.society(r.to);
   if(a==null||b==null||!a.alive){r.blocked=true;return;}
   if(!b.alive){r.closing=true;r.returning=true;}
   if(r.closing&&r.progress==0){_finishRouteAtHome(r);return;}
   if(r.crewAssigned<2){r.blocked=true;return;}
   final remaining=r.returning?r.path.take(r.progress+1):r.path.skip(r.progress);
   r.blocked=(!r.returning&&(a.relations[b.id]??0)<-35)||remaining.any((p)=>!world.tiles[p].passable||world.tiles[p].damage>=0.9);
   if(r.blocked)return;
   if(!r.returning&&r.cargo<=0){if(r.progress>0){r.returning=true;}else{r.cargo=math.min(a.supports('trade')||a.leaderTrait=='generous'?16.0:12.0,a.resources['food']!);a.resources['food']=a.resources['food']!-r.cargo;if(r.cargo<=0)return;}}
   final speed=a.supports('logistics')?2:1;
   if(r.returning){
     r.progress=math.max(0,r.progress-speed);
     if(r.progress==0){
       if(r.closing){_finishRouteAtHome(r);return;}
       a.resources['metal']=a.resources['metal']!+r.metalMillis/1000;r.metalMillis=0;
       a.resources['food']=a.resources['food']!+r.cargo;r.cargo=0;r.returning=false;
     }
   }else{
     r.progress=math.min(r.path.length-1,r.progress+speed);
     if(r.progress==r.path.length-1){
       b.resources['food']=b.resources['food']!+r.cargo;r.cargo=0;
       r.metalMillis=math.min(3000,Quantity.fromNumber(b.resources['metal']!).millis);b.resources['metal']=b.resources['metal']!-r.metalMillis/1000;r.returning=true;
     }
   }
 }
 void _routeTick(TradeRoute r){if(r.transportRules==2){_transportTick(r);return;}final a=world.society(r.from),b=world.society(r.to);if(a==null||b==null||!a.alive||!b.alive){r.blocked=true;return;}r.blocked=(a.relations[b.id]??0)<-35||r.path.any((p)=>world.tiles[p].damage>=0.9);if(r.blocked)return;r.progress+=a.supports('logistics')?2:1;if(r.progress>=r.path.length){r.progress=0;if(r.cargo>0){b.resources['food']=b.resources['food']!+r.cargo;final metal=math.min(3.0,b.resources['metal']!);b.resources['metal']=b.resources['metal']!-metal;a.resources['metal']=a.resources['metal']!+metal;}r.cargo=math.min(a.supports('trade')||a.leaderTrait=='generous'?16.0:12.0,a.resources['food']!);a.resources['food']=a.resources['food']!-r.cargo;}}
 void _ambient(Society s){final r=world.random;final roll=r.nextInt(8),severity=(world.intensity=='extrema'||world.intensity=='extreme')?3:(world.intensity=='caótica'||world.intensity=='chaotic')?2:1;if(roll==0){final loss=math.min(s.resources['food']!,20.0*severity);s.resources['food']=s.resources['food']!-loss;record(s,'Sequía sobre los cultivos','Una variación climática destruye ${loss.round()} alimentos. No es consecuencia de una orden.','entorno');}else if(roll==1){s.resources['wood']=s.resources['wood']!+15;record(s,'Madera recuperada','Los habitantes rescatan 15 maderas de una estructura caída.','economía');}else if(roll==2){s.health=(s.health-8*severity).clamp(0,100).toDouble();record(s,'Fiebre del polvo','Una epidemia ficticia exige cuidados y reduce salud.','salud');}else if(roll==3){s.resources['knowledge']=s.resources['knowledge']!+12;record(s,'Lecciones compartidas','La escuela y los mayores conservan 12 conocimientos.','tecnología');}else if(roll==4&&s.risk>0.6){final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isNotEmpty){final o=others[r.nextInt(others.length)];s.relations[o.id]=((s.relations[o.id]??0)-(s.supports('diplomacy')?8:15)).clamp(-100,100).toInt();if(s.relations[o.id]!<-40){final supply=math.min(20.0,s.resources['food']!);s.resources['food']=s.resources['food']!-supply;final strength=s.adults*(1+s.defenseModifier*0.02)*(s.catalog==null?(s.built['wall']!=null?1.3:1):1+s.catalog!.buildings.fold<int>(0,(n,b)=>n+(s.built[b.id]??0)*b.defense)*0.3)*(1+s.tech.length*0.03);final defense=o.adults*(o.leaderTrait=='severe'?1.3:1)*(1+o.defenseModifier*0.02)*(o.catalog==null?(o.built['wall']!=null?1.5:1):1+o.catalog!.buildings.fold<int>(0,(n,b)=>n+(o.built[b.id]??0)*b.defense)*0.5);_removePeople(strength>defense?o:s,2*severity);record(s,'Conflicto con ${o.name}','La rivalidad y el riesgo político producen bajas y consumo de suministros.','conflicto');}}}else if(roll==5&&world.extraordinary&&r.nextInt(10)<severity){world.pending.add(ScheduledEvent(_id('e'),'anomaly',s.id,world.day+15));record(s,'Luces bajo la tierra','La señal anticipa una anomalía de origen desconocido.','extraordinario');}}
 void _resolve(Society s,ScheduledEvent e){if(e.type=='content'){_resolveScheduledContent(s,e);return;}switch(e.type){case 'discovery':final explorerId=e.data['explorerId'];if(explorerId!=null&&!s.people.any((p)=>p.id==explorerId&&p.alive)){record(s,'Expedición interrumpida','La pérdida de su responsable obliga al equipo a regresar sin completar la búsqueda.','exploración',cause:e.cause);break;}s.discoveries++;if(!s.facilityFound){s.facilityFound=true;record(s,'La instalación antigua','La expedición encuentra un núcleo sellado. Puedes sellarlo, desmontarlo, estudiarlo o compartirlo.','exploración',cause:e.cause);}else{s.resources['metal']=s.resources['metal']!+12;record(s,'Regreso de la expedición','La exploración recupera 12 metales de un vestigio.','exploración',cause:e.cause);}break;
 case 'facility_seal':s.environment=math.max(0.0,s.environment-10);s.morale=(s.morale+8).clamp(0,100).toDouble();record(s,'El jardín del umbral','El sellado evita riesgos y deja una zona protegida.','consecuencia',cause:e.cause);break;
 case 'facility_salvage':s.resources['metal']=s.resources['metal']!+65;s.resources['tools']=s.resources['tools']!+15;s.environment=(s.environment+8).clamp(0,100).toDouble();record(s,'Metal a cambio de memoria','Se recuperan materiales; el archivo antiguo queda destruido.','consecuencia',cause:e.cause);break;
 case 'facility_share':final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isEmpty){record(s,'Una invitación sin respuesta','No queda otra comunidad capaz de aceptar; el núcleo se conserva.','consecuencia',cause:e.cause);break;}final o=others.first;s.relations[o.id]=math.min(100,(s.relations[o.id]??0)+35);o.relations[s.id]=math.min(100,(o.relations[s.id]??0)+35);s.resources['knowledge']=s.resources['knowledge']!+45;o.resources['knowledge']=o.resources['knowledge']!+25;record(s,'El pacto del umbral','${o.name} comparte estudios y conserva una deuda de cooperación.','consecuencia',cause:e.cause);_openRoute(s,o);break;
 case 'facility_study':if(!s.people.any((p)=>p.alive&&(world.populationState==null?p.role=='técnica':p.competence('technical')>=1000))){record(s,'Estudio suspendido','No queda especialista; el proyecto espera una generación formada.','consecuencia',cause:e.cause);world.pending.add(ScheduledEvent(_id('e'),'facility_study',s.id,world.day+360,cause:e.cause));break;}final safe=s.supports('science')||world.random.nextInt(100)<s.health*0.7;if(safe){s.resources['energy']=s.resources['energy']!+90;s.tech.add('electricity');final discovery=record(s,'El núcleo despierta','La investigación produce energía y una tecnología recuperada.','consecuencia',cause:e.cause);world.pending.add(ScheduledEvent(_id('e'),'energy_growth',s.id,world.day+120,cause:discovery.id));if(world.extraordinary)world.pending.add(ScheduledEvent(_id('e'),'signal',s.id,world.day+720,cause:discovery.id));}else{s.health=(s.health-20).clamp(0,100).toDouble();_removePeople(s,3);record(s,'Accidente del núcleo','La investigación sin garantías libera una descarga y causa tres bajas.','consecuencia',cause:e.cause);}break;
 case 'energy_growth':if(world.rulesVersion>=9){_receiveMigrants(s,4,cause:e.cause);break;}final room=math.max(0,s.housing-s.population);if(room>=4){final source=world.societies.where((o)=>o.alive&&o.id!=s.id&&o.adults>=4).toList();if(source.isNotEmpty){if(world.populationState!=null){_transferResidents(source.first,s,4,1,cause:e.cause);}else{source.first.adults-=4;s.adults+=4;}record(s,'La luz atrae familias','Cuatro adultos llegan desde ${source.first.name}; aumentan la demanda de alimentos.','migración',cause:e.cause);}}else{record(s,'Una ciudad demasiado estrecha','La energía atrajo interés, pero la falta de vivienda impide recibir familias.','consecuencia',cause:e.cause);}break;
 case 'signal':final allied=s.relations.values.where((v)=>v>35).length;final peaceful=s.policy.diplomacy=='cooperate'&&(allied>0||s.supports('xenology'));if(peaceful){s.resources['knowledge']=s.resources['knowledge']!+120;s.tech.add('radio');record(s,'Voces entre estrellas','La señal recibe respuesta: intercambio bajo un pacto de convivencia.','extraordinario',cause:e.cause);}else if(s.risk>0.6){_removePeople(s,math.min(s.adults,12));s.resources['energy']=0;record(s,'La visita hostil','La señal y una respuesta agresiva desembocan en incursión y resistencia.','extraordinario',cause:e.cause);}else{s.morale=(s.morale-12).clamp(0,100).toDouble();s.resources['knowledge']=s.resources['knowledge']!+50;record(s,'Los tutores del silencio','El contacto entrega conocimiento a cambio de influencia política.','extraordinario',cause:e.cause);}break;
 case 'anomaly':final response=s.supports('ecology')||s.risk<0.3;if(response){s.resources['crystal']=s.resources['crystal']!+10;record(s,'Anomalía contenida','La preparación permite recuperar cristales sin pérdidas.','extraordinario',cause:e.cause);}else{s.environment=(s.environment+20).clamp(0,100).toDouble();s.health=(s.health-15).clamp(0,100).toDouble();world.tiles[s.y*world.size+s.x].damage=1;record(s,'La tierra cambia de voz','Una instalación autónoma daña el territorio e interrumpe sus rutas.','extraordinario',cause:e.cause);}break;
 }}
}

/// Declarative content interpreter. No executable code is accepted from packages.
extension ContentSimulation on Simulation {
 List<Map<String,dynamic>> get contentEvents {
 final result=((content?['events']??[]) as List).map((e)=>Map<String,dynamic>.from(e)).toList();
 for(final raw in (content?['templates']??[]) as List){final t=Map<String,dynamic>.from(raw);final p=t['parameter'] as Map;final low=p['minimum'] as int,high=p['maximum'] as int;final parameter=low+((world.seed+(t['id'] as String).codeUnits.fold<int>(0,(int a,b)=>a+b)+world.day~/180)%(high-low+1));
 final options=<Map<String,dynamic>>[];for(final option in t['options'] as List){final o=Map<String,dynamic>.from(option);final costs=<String,num>{};for(final cost in ((o['costs']??{}) as Map).entries){final value=cost.value;costs[cost.key]=value is Map?(value['base'] as num)+(value['perUnit'] as num)*parameter:value as num;}
 final effects=<Map<String,dynamic>>[];for(final effect in (o['effects']??[]) as List){final e=Map<String,dynamic>.from(effect);if(e.containsKey('base'))e['value']=(e['base'] as num)+(e['perUnit'] as num)*parameter;effects.add(e);}options.add({...o,'costs':costs,'effects':effects});}
 result.add({if(t['origins']!=null)'origins':t['origins'],'id':'template_${t['id']}','category':t['category'],'title':t['title'],'body':'${t['title']}: ${p['name']} $parameter. El alcance cambia costes y rendimientos.','conditions':t['conditions'],'trigger':'director','baseProbability':0.08,'repeatable':true,'cooldownDays':t['cooldownDays'],'options':options});}
 return result;
 }
 String _resource(String id)=>id=='fiber'?'textiles':id=='relics'?'crystal':id;
 bool _conditions(Society s,Map<String,dynamic> c){final originRequirements=c['originCapabilities'];if(originRequirements is Map&&((originRequirements[world.origin] as List?)??[]).any((capability)=>!s.supports(capability)))return false;
 for(final field in ['resource_min','resource_max']){final values=c[field];if(values is Map){for(final e in values.entries){final amount=s.resources[_resource(e.key.toString())]??0;if(field=='resource_min'&&amount<(e.value as num))return false;if(field=='resource_max'&&amount>(e.value as num))return false;}}}
 if(c['minPopulation']!=null&&s.population<(c['minPopulation'] as num))return false;
 if(c['maxPopulation']!=null&&s.population>(c['maxPopulation'] as num))return false;
 if(c['maxHousing']!=null&&s.housing>(c['maxHousing'] as num))return false;
 if(c['minMorale']!=null&&s.morale<(c['minMorale'] as num))return false;
 if(c['minRelation']!=null&&s.relations.values.any((v)=>v<(c['minRelation'] as num)))return false;
 if(c['minHousing']!=null&&s.housing<(c['minHousing'] as num))return false;
 if(c['maxMorale']!=null&&s.morale>(c['maxMorale'] as num))return false;
 if(c['maxRelation']!=null&&s.relations.values.any((v)=>v>(c['maxRelation'] as num)))return false;
 if(c['minHealth']!=null&&s.health<(c['minHealth'] as num))return false;
 if(c['maxHealth']!=null&&s.health>(c['maxHealth'] as num))return false;
 if(c['minDay']!=null&&world.day<(c['minDay'] as num))return false;
 if(c['maxDay']!=null&&world.day>(c['maxDay'] as num))return false;
 if(c['facilityFound']!=null&&s.facilityFound!=c['facilityFound'])return false;
 for(final id in (c['technologies']??[]) as List){if(!s.tech.contains(id))return false;}
 for(final id in (c['missingTechnologies']??[]) as List){if(s.tech.contains(id))return false;}
 for(final id in (c['flags']??[]) as List){if(!s.flags.contains(id))return false;}
 for(final id in (c['flagsMissing']??[]) as List){if(s.flags.contains(id))return false;}
 return true;
 }
 List<Map<String,dynamic>> get pendingContentEvents {final ids=world.pending.where((e)=>e.type=='content_choice'&&e.societyId==world.controlledId).map((e)=>e.data['eventId']).toSet();return contentEvents.where((e)=>ids.contains(e['id'])).toList();}
 List<Map<String,dynamic>> eligibleEvents([String? societyId]){final s=world.society(societyId??world.controlledId);if(s==null||!s.alive)return [];return contentEvents.where((e){if(world.rulesVersion>=5&&e['origins'] is List&&!(e['origins'] as List).contains(world.origin))return false;if(e['trigger']=='scheduled'&&!world.pending.any((p)=>p.type=='content_choice'&&p.societyId==s.id&&p.data['eventId']==e['id']))return false;if(e['family']!=null&&!world.extraordinary)return false;final key='${s.id}:${e['id']}';final last=world.contentHistory[key];if(last!=null&&(e['repeatable']!=true||world.day-last<(e['cooldownDays']??360)))return false;if(!_conditions(s,Map<String,dynamic>.from(e['conditions']??{})))return false;return _migrationEventContext(s,e);}).toList();}
 Map<String,dynamic> _delegatedOption(Society s,List options){
 final affordable=options.where((raw){final o=raw as Map;if(_migrationOptionIssue(s,o)!=null)return false;return ((o['costs']??{}) as Map).entries.every((e)=>(s.resources[_resource(e.key.toString())]??0)>=(e.value as num));}).toList();if(affordable.isEmpty)return Map<String,dynamic>.from(options.last);
 if(s.risk>0.5)return Map<String,dynamic>.from(affordable.first);
 // A cautious council prefers affordable protective investments while keeping reserves.
 final first=Map<String,dynamic>.from(affordable.first);final costs=(first['costs']??{}) as Map;final food=(costs['food']??0) as num;if((s.resources['food']??0)-food>=math.min(s.policy.reserve,s.population*2))return first;return Map<String,dynamic>.from(affordable.last);
 }
 void _directContent(Society s){if(content==null||(s.id==world.controlledId&&!delegateDecisions)||!s.alive)return;final eligible=eligibleEvents(s.id);if(eligible.isEmpty)return;final candidates=eligible.where((event){double chance=((event['baseProbability']??0.1) as num).toDouble();for(final conditional in (event['conditionalProbability']??[]) as List){if(_conditions(s,Map<String,dynamic>.from(conditional['conditions']??{})))chance*=(conditional['multiplier'] as num).toDouble();}return world.random.nextDouble()<chance.clamp(0,1);}).toList();if(candidates.isEmpty)return;final e=candidates[world.random.nextInt(candidates.length)];final options=e['options'] as List;if(options.isEmpty)return;final option=_delegatedOption(s,options);resolveContentEvent(e['id'],option['id'],societyId:s.id,delegated:true);}
 CommandResult resolveContentEvent(String eventId,String optionId,{String? societyId,bool delegated=false,bool scheduled=false,String? cause}) {
 final s=world.society(societyId??world.controlledId);if(s==null||!s.alive)return const CommandResult(false,'No queda una comunidad capaz de decidir.');if(world.populationState!=null&&!s.people.any((p)=>p.id==s.leaderId&&p.alive&&world.day-p.bornDay>=18*360))return const CommandResult(false,'No hay una dirección adulta capaz de resolver la decisión.');final es=contentEvents.where((e)=>e['id']==eventId);if(es.isEmpty)return const CommandResult(false,'Acontecimiento no encontrado.');final e=es.first;
 if(world.rulesVersion>=5&&e['origins'] is List&&!(e['origins'] as List).contains(world.origin))return const CommandResult(false,'Este acontecimiento no pertenece al origen de este mundo.');
 final queued=world.pending.where((p)=>p.type=='content_choice'&&p.societyId==s.id&&p.data['eventId']==eventId).toList();
 if(!scheduled&&queued.isEmpty&&!eligibleEvents(s.id).any((x)=>x['id']==eventId))return const CommandResult(false,'Las condiciones ya no se cumplen.');if(!_conditions(s,Map<String,dynamic>.from(e['conditions']??{})))return const CommandResult(false,'Consecuencia cancelada: el contexto cambió.');if(!_migrationEventContext(s,e))return const CommandResult(false,'No hay un grupo real con condiciones de salida para este acontecimiento.');
 final options=(e['options'] as List).where((o)=>o['id']==optionId);if(options.isEmpty)return const CommandResult(false,'Opción desconocida.');final o=Map<String,dynamic>.from(options.first);final costs=(o['costs']??o['cost']??{}) as Map;final paid=<String,double>{};for(final entry in costs.entries){paid[_resource(entry.key.toString())]=(entry.value as num).toDouble();}final migrationIssue=_migrationOptionIssue(s,o);if(migrationIssue!=null)return CommandResult(false,migrationIssue);if(!_pay(s,paid))return const CommandResult(false,'Recursos insuficientes para esta decisión.');
 if(eventId=='facility_found'){s.facilityChoice=optionId;s.flags.add('facility_committed');}world.pending.removeWhere((p)=>queued.contains(p));world.contentHistory['${s.id}:$eventId']=world.day;final h=record(s,e['title'], '${e['body']} ${delegated?'El consejo resolvió:':'Decisión:'} ${o['label']}',e['category'],cause:cause??(world.rulesVersion>=5?queued.firstOrNull?.cause:null));
 for(final raw in (o['effects']??[]) as List){final effect=Map<String,dynamic>.from(raw);_applyContentEffect(s,effect,h.id);}
 for(final raw in (o['followUps']??[]) as List){final f=Map<String,dynamic>.from(raw);final probability=(f['probability']??1) as num;if(world.random.nextDouble()<probability){world.pending.add(ScheduledEvent(_id('e'),'content',s.id,world.day+math.max(1,(f['delayDays'] as num).toInt()),cause:h.id,data:{'eventId':f['eventId']}));}}
 world.validate();return CommandResult(true,'${e['title']}: ${o['label']}');
 }
 void _applyContentEffect(Society s,Map<String,dynamic> e,String cause){final rawValue=e['value']??e['amount']??0;final n=rawValue is num?rawValue.toDouble():0.0;switch(e['type']){
 case 'resource':final id=_resource(e['resource']);if(resourceIds.contains(id))s.resources[id]=(s.resources[id]!+n).clamp(0,100000).toDouble();break;
 case 'population':if(world.rulesVersion>=9&&n>0){_receiveMigrants(s,n.toInt(),cause:cause);break;}if(n<0){_removePeople(s,-n.toInt(),cause:cause);}else{final count=math.min(n.toInt(),math.max(0,s.housing-s.population));if(world.populationState!=null){final origins=world.societies.where((o)=>o.id!=s.id&&o.alive&&o.adults>=count).toList()..sort((a,b)=>a.id.compareTo(b.id));if(count>0&&origins.isNotEmpty){_transferResidents(origins.first,s,count,1,cause:cause);record(s,'Llegan residentes de ${origins.first.name}','$count adultos cambian de residencia conservando identidad, edad y cultura.','migración',cause:cause);}}else{s.adults+=count;}}break;
 case 'health':s.health=(s.health+n).clamp(0,100).toDouble();break;
 case 'morale':case 'mood':s.morale=(s.morale+n).clamp(0,100).toDouble();break;
 case 'environment':s.environment=(s.environment+n).clamp(0,100).toDouble();break;
 case 'housing':s.housingModifier+=n.toInt();break;
 case 'defense':s.defenseModifier=(s.defenseModifier+n.toInt()).clamp(-30,100).toInt();break;
 case 'relation':final target=e['target'];final others=world.societies.where((o)=>o.id!=s.id&&o.alive&&(target==null||o.id==target));for(final o in others){s.relations[o.id]=((s.relations[o.id]??0)+n.toInt()).clamp(-100,100).toInt();o.relations[s.id]=((o.relations[s.id]??0)+n.toInt()).clamp(-100,100).toInt();}break;
 case 'flag':final flag=e['flag']??e['id']??e['target']??e['value'];if(flag is String){if(e['enabled']==false) {
   s.flags.remove(flag);
 } else {
   s.flags.add(flag);
 }}break;
 case 'technology':final id=e['technology']??e['id']??e['value'];if(technologies.any((t)=>t.id==id))s.tech.add(id);break;
 case 'schedule':final id=e['eventId'];if(id is String)world.pending.add(ScheduledEvent(_id('e'),'content',s.id,world.day+math.max(1,(e['delayDays']??30) as int),cause:cause,data:{'eventId':id}));break;
 }}
 void _resolveScheduledContent(Society s,ScheduledEvent event){final es=contentEvents.where((e)=>e['id']==event.data['eventId']);if(es.isEmpty){record(s,'Consecuencia cancelada','Su definición de contenido no está disponible.','contenido',cause:event.cause);return;}final e=es.first;if(world.rulesVersion>=5&&e['origins'] is List&&!(e['origins'] as List).contains(world.origin)){record(s,'Consecuencia incompatible con el origen','Se cancela antes de aplicar efectos.','contenido',cause:event.cause);return;}if(e['family']!=null&&!world.extraordinary){record(s,'Escenario extraordinario omitido','Esta familia está desactivada en las reglas del mundo.','consecuencia',cause:event.cause);return;}if(!_conditions(s,Map<String,dynamic>.from(e['conditions']??{}))||!_migrationEventContext(s,e)){record(s,'La historia cambia de curso','${e['title']}: ya no se cumplen sus condiciones.','consecuencia',cause:event.cause);return;}if(s.id==world.controlledId&&!delegateDecisions){world.pending.add(ScheduledEvent(_id('e'),'content_choice',s.id,world.day+3600000,cause:event.cause,data:event.data));record(s,e['title'],'Una decisión espera tu respuesta.','decisión',cause:event.cause);return;}final options=e['options'] as List;if(options.isEmpty)return;final option=_delegatedOption(s,options);final result=resolveContentEvent(e['id'],option['id'],societyId:s.id,scheduled:true,delegated:true,cause:event.cause);if(!result.ok)record(s,'Consecuencia aplazada sin efecto',result.message,'consecuencia',cause:event.cause);}
}
