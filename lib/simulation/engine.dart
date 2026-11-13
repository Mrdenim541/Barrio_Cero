import 'dart:convert';
import 'dart:math' as math;

/// Calendar: 30 days/month, 12 months/year. All transitions use daily ticks.
const daysPerYear = 360;
const resourceIds = ['food','wood','stone','metal','water','medicine','tools','energy','knowledge','textiles','crystal','fuel'];
const biomeNames = ['Pradera','Bosque','Desierto','Montaña','Humedal','Costa'];

class RandomState {
  int state;
  RandomState(int seed) : state = seed & 0x7fffffff;
  int nextInt(int n) {state = (1103515245 * state + 12345) & 0x7fffffff; return state % n;}
  double nextDouble()=>nextInt(1000000)/1000000;
}
class Tile {
  final int x,y,biome; final int richness; bool ruin; double damage;
  Tile(this.x,this.y,this.biome,this.richness,{this.ruin=false,this.damage=0});
  bool get passable => biome!=5 && biome!=3;
  Map<String,dynamic> toJson()=>{'x':x,'y':y,'biome':biome,'richness':richness,'ruin':ruin,'damage':damage};
  factory Tile.fromJson(Map<String,dynamic> j)=>Tile(j['x'],j['y'],j['biome'],j['richness'],ruin:j['ruin'],damage:(j['damage'] as num).toDouble());
}
class BuildingDefinition {
 final String id,name,description; final Map<String,double> cost,yield; final int days; final String? technology;
 const BuildingDefinition(this.id,this.name,this.description,this.cost,this.yield,this.days,[this.technology]);
}
const buildings = <BuildingDefinition>[
 BuildingDefinition('farm','Huerto','Alimento cultivado; reduce el hambre.',{'wood':20,'stone':5},{'food':1.8},12),
 BuildingDefinition('well','Pozo','Agua limpia y salud.',{'stone':20,'wood':10},{'water':2},15),
 BuildingDefinition('house','Viviendas','Aloja a 18 personas.',{'wood':30,'stone':15},{},20),
 BuildingDefinition('sawmill','Aserradero','Trabaja madera.',{'wood':25,'tools':3},{'wood':1.4},18),
 BuildingDefinition('quarry','Cantera','Extrae piedra.',{'wood':20,'tools':4},{'stone':1.2},20),
 BuildingDefinition('workshop','Taller','Fabrica herramientas usando metal.',{'wood':35,'stone':20},{'tools':0.15},25),
 BuildingDefinition('clinic','Dispensario','Cuidados y medicamentos.',{'wood':30,'textiles':10},{'medicine':0.12},24,'sanitation'),
 BuildingDefinition('school','Escuela','Forma especialistas.',{'wood':35,'stone':25},{'knowledge':0.7},30),
 BuildingDefinition('market','Mercado','Facilita rutas y comercio.',{'wood':40,'textiles':10},{},25),
 BuildingDefinition('wall','Empalizada','Protección territorial.',{'wood':60,'stone':30},{},35),
 BuildingDefinition('mine','Mina','Extrae mineral.',{'wood':40,'tools':8},{'metal':0.6},35,'mining'),
 BuildingDefinition('laboratory','Laboratorio','Investiga tecnologías avanzadas.',{'metal':35,'tools':10},{'knowledge':1.5},45,'science'),
 BuildingDefinition('generator','Generador','Produce energía consumiendo combustible.',{'metal':35,'tools':8},{'energy':1.5},40,'electricity'),
 BuildingDefinition('loom','Telar','Tejidos para ropa y comercio.',{'wood':30,'tools':4},{'textiles':0.3},20),
 BuildingDefinition('granary','Granero','Aumenta la reserva alimentaria útil.',{'wood':35,'stone':15},{},20),
 BuildingDefinition('recycler','Reciclador','Recupera materiales antiguos.',{'metal':25,'tools':10},{'metal':0.4,'fuel':0.15},40,'recycling'),
 BuildingDefinition('observatory','Observatorio','Analiza señales y cristales.',{'metal':45,'crystal':10},{'crystal':0.1,'knowledge':0.7},50,'radio'),
 BuildingDefinition('habitat','Hábitat adaptativo','Vivienda resiliente para 50 habitantes.',{'metal':60,'energy':40},{},60,'adaptation'),
];
class Technology {
 final String id,name; final List<String> requires; final double cost; final String effect;
 const Technology(this.id,this.name,this.requires,this.cost,this.effect);
}
const technologies=<Technology>[
 Technology('agriculture','Agricultura',[],30,'Aumenta cosechas'), Technology('sanitation','Saneamiento',[],35,'Mejora salud'), Technology('masonry','Albañilería',[],30,'Vivienda robusta'),
 Technology('mining','Minería',['masonry'],45,'Desbloquea minas'), Technology('metallurgy','Metalurgia',['mining'],60,'Herramientas eficientes'), Technology('trade','Intercambio',['agriculture'],40,'Rutas comerciales'),
 Technology('writing','Escritura',[],30,'Instituciones duraderas'), Technology('education','Enseñanza',['writing'],55,'Más conocimiento'), Technology('science','Método científico',['education'],80,'Laboratorios'),
 Technology('medicine','Medicina',['sanitation','science'],100,'Reduce mortalidad'), Technology('engineering','Ingeniería',['metallurgy'],80,'Acelera construcción'), Technology('electricity','Electricidad',['engineering'],100,'Generadores'),
 Technology('radio','Radio',['electricity'],90,'Contacto a distancia'), Technology('recycling','Reciclaje',['metallurgy'],65,'Recicladores'), Technology('chemistry','Química',['science'],80,'Combustibles y salud'),
 Technology('irrigation','Riego',['agriculture','masonry'],65,'Cosechas resistentes'), Technology('ecology','Ecología',['science'],90,'Reduce daño ambiental'), Technology('diplomacy','Diplomacia',['writing','trade'],65,'Reduce guerras'),
 Technology('logistics','Logística',['trade','engineering'],85,'Transporte rápido'), Technology('industry','Industria',['electricity','chemistry'],130,'Producción intensiva'), Technology('automation','Automatización',['industry','radio'],160,'Menos trabajo manual'),
 Technology('computing','Computación',['electricity','science'],130,'Control de sistemas'), Technology('robotics','Robótica',['automation','computing'],180,'Producción autónoma'), Technology('biotech','Biotecnología',['medicine','chemistry'],150,'Transformación dirigida'),
 Technology('adaptation','Adaptación',['ecology','biotech'],180,'Hábitats resistentes'), Technology('cybernetics','Cibernética',['biotech','computing'],200,'Interfaces humanas'), Technology('fusion','Fusión',['industry','science'],220,'Energía avanzada'),
 Technology('xenology','Xenología',['radio','biotech'],200,'Comprende contacto'), Technology('orbital','Acceso orbital',['fusion','computing'],250,'Observación planetaria'), Technology('synthesis','Síntesis cultural',['diplomacy','adaptation'],240,'Cooperación transformada')
];
const traitNames=['prudent','bold','generous','guarded','inventive','traditional','patient','restless','conciliatory','severe','green','pragmatic'];
class Person {
 String id,name,role,trait; int bornDay; int? diedDay; double skill;
 Person(this.id,this.name,this.role,this.bornDay,this.trait,{this.diedDay,this.skill=1});
 bool get alive=>diedDay==null;
 Map<String,dynamic> toJson()=>{'id':id,'name':name,'role':role,'bornDay':bornDay,'trait':trait,'diedDay':diedDay,'skill':skill};
 factory Person.fromJson(Map<String,dynamic> j)=>Person(j['id'],j['name'],j['role'],j['bornDay'],j['trait'],diedDay:j['diedDay'],skill:(j['skill'] as num).toDouble());
}
class Policy {
 double reserve=120,risk=0.35; bool expansion=true,trade=true; String research='agriculture', diplomacy='cooperate';
 Map<String,dynamic> toJson()=>{'reserve':reserve,'risk':risk,'expansion':expansion,'trade':trade,'research':research,'diplomacy':diplomacy};
 factory Policy.fromJson(Map<String,dynamic> j)=>Policy()..reserve=(j['reserve'] as num).toDouble()..risk=(j['risk'] as num).toDouble()..expansion=j['expansion']..trade=j['trade']..research=j['research']..diplomacy=j['diplomacy'];
 Policy();
}
class Project {
 String building; int finish; Project(this.building,this.finish);
 Map<String,dynamic> toJson()=>{'building':building,'finish':finish};
 factory Project.fromJson(Map<String,dynamic> j)=>Project(j['building'],j['finish']);
}
class BuildingSite { final String id,building; final int x,y; BuildingSite(this.id,this.building,this.x,this.y); Map<String,dynamic> toJson()=>{'id':id,'building':building,'x':x,'y':y}; factory BuildingSite.fromJson(Map<String,dynamic> j)=>BuildingSite(j['id'],j['building'],j['x'],j['y']);}
class Society {
 String id,name,profile,culture,leaderId; int x,y,founded; int children,adults,elders; double health=90,morale=70,environment=0;
 Map<String,double> resources={for(final r in resourceIds) r:0}; Map<String,int> built={}; List<Project> projects=[]; Set<String> tech={}; Map<String,int> relations={};
 List<BuildingSite> sites=[]; List<Person> people=[]; Policy policy=Policy(); bool facilityFound=false; String? facilityChoice; bool extinct=false; int housingModifier=0,defenseModifier=0; int discoveries=0; int expeditionWorkers=0; Set<String> flags={}; Map<String,double> demographicCarry={};
 Society(this.id,this.name,this.profile,this.x,this.y,{this.children=12,this.adults=38,this.elders=6,this.founded=0,this.culture='Cero',this.leaderId=''}) {resources.addAll({'food':260,'wood':100,'stone':75,'metal':25,'water':250,'medicine':12,'tools':20,'energy':5,'knowledge':35,'textiles':20,'crystal':5,'fuel':30});built={'farm':2,'well':1,'house':4};}
 void addSite(String building){final i=sites.length;sites.add(BuildingSite('$id:b$i',building,2+(i%14)*2,2+(i~/14)*2));}
 void ensureSites(){if(sites.isEmpty){for(final e in built.entries){for(int i=0;i<e.value;i++) {
   addSite(e.key);
 }}}}
 String get leaderTrait=>people.where((p)=>p.id==leaderId&&p.alive).map((p)=>p.trait).firstOrNull??'prudent';
 double get risk=>(policy.risk+(leaderTrait=='bold'?0.3:leaderTrait=='prudent'?-0.25:0)).clamp(0,1).toDouble();
 int get population=>children+adults+elders;
 int get housing=>math.max(0,(built['house']??0)*(tech.contains('masonry')?22:18)+(built['habitat']??0)*50+housingModifier);
 int get workers=>math.max(0,adults-projects.length*4-expeditionWorkers);
 bool get alive=>!extinct&&population>0;
 Map<String,dynamic> toJson()=>{'id':id,'name':name,'profile':profile,'culture':culture,'leaderId':leaderId,'x':x,'y':y,'founded':founded,'population':population,'children':children,'adults':adults,'elders':elders,'health':health,'morale':morale,'environment':environment,'resources':resources,'built':built,'projects':projects.map((e)=>e.toJson()).toList(),'tech':tech.toList()..sort(),'relations':relations,'sites':sites.map((e)=>e.toJson()).toList(),'people':people.map((e)=>e.toJson()).toList(),'policy':policy.toJson(),'facilityFound':facilityFound,'facilityChoice':facilityChoice,'extinct':extinct,'discoveries':discoveries,'expeditionWorkers':expeditionWorkers,'housingModifier':housingModifier,'defenseModifier':defenseModifier,'flags':flags.toList()..sort(),'demographicCarry':demographicCarry};
 factory Society.fromJson(Map<String,dynamic> j){final s=Society(j['id'],j['name'],j['profile'],j['x'],j['y'],children:j['children'],adults:j['adults'],elders:j['elders'],founded:j['founded'],culture:j['culture'],leaderId:j['leaderId']);s.health=(j['health'] as num).toDouble();s.morale=(j['morale'] as num).toDouble();s.environment=(j['environment'] as num).toDouble();s.resources=(j['resources'] as Map).map((k,v)=>MapEntry(k as String,(v as num).toDouble()));s.built=Map<String,int>.from(j['built']);s.projects=(j['projects'] as List).map((e)=>Project.fromJson(Map<String,dynamic>.from(e))).toList();s.tech=Set<String>.from(j['tech']);s.relations=Map<String,int>.from(j['relations']);s.sites=(j['sites'] as List? ?? []).map((e)=>BuildingSite.fromJson(Map<String,dynamic>.from(e))).toList();s.ensureSites();s.people=(j['people'] as List).map((e)=>Person.fromJson(Map<String,dynamic>.from(e))).toList();s.policy=Policy.fromJson(Map<String,dynamic>.from(j['policy']));s.facilityFound=j['facilityFound'];s.facilityChoice=j['facilityChoice'];s.extinct=j['extinct'];s.discoveries=j['discoveries'];s.expeditionWorkers=j['expeditionWorkers']??0;s.housingModifier=j['housingModifier']??0;s.defenseModifier=j['defenseModifier']??0;s.flags=Set<String>.from(j['flags']??[]);s.demographicCarry=(j['demographicCarry'] as Map? ?? {}).map((k,v)=>MapEntry(k as String,(v as num).toDouble()));return s;}
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
 String id,from,to; List<int> path; double cargo; int progress; bool blocked;
 TradeRoute(this.id,this.from,this.to,this.path,{this.cargo=12,this.progress=0,this.blocked=false});
 Map<String,dynamic> toJson()=>{'id':id,'from':from,'to':to,'path':path,'cargo':cargo,'progress':progress,'blocked':blocked};
 factory TradeRoute.fromJson(Map<String,dynamic> j)=>TradeRoute(j['id'],j['from'],j['to'],List<int>.from(j['path']),cargo:(j['cargo'] as num).toDouble(),progress:j['progress'],blocked:j['blocked']);
}
class WorldState {
 int seed,size,day=0,serial=0; String intensity; bool extraordinary; RandomState random; String? controlledId='s0';
 List<Tile> tiles=[]; List<Society> societies=[]; List<HistoryEntry> chronicle=[]; List<ScheduledEvent> pending=[]; List<TradeRoute> routes=[];
 Map<String,Map<String,dynamic>> commandReceipts={};
 Map<String,int> contentHistory={}; Map<String,Map<String,num>> annualSnapshots={}; Map<String,String> contentVersions={'core':'1.0.0'}; bool get extinct=>societies.every((s)=>!s.alive);
 WorldState._(this.seed,this.size,this.intensity,this.extraordinary):random=RandomState(seed);
 factory WorldState.generate({int seed=42,int size=96,String intensity='normal',bool extraordinary=true}) {
 final w=WorldState._(seed,size,intensity,extraordinary);final r=w.random;
 for(int y=0;y<size;y++){for(int x=0;x<size;x++) {final n=((math.sin(x/9)+math.cos(y/11)+math.sin((x+y+seed%17)/6))*1.2+3).floor().clamp(0,5).toInt();w.tiles.add(Tile(x,y,n,r.nextInt(5)+1,ruin:r.nextInt(80)==0));}}
 const names=['Barrio Cero','Liga del Junco','Forja Gris','Archivo del Alba','Vigías del Sur','Nómadas de Sal'];const profiles=['cooperativa','ecologista','industrial','científica','defensiva','mercantil'];
 for(int i=0;i<6;i++){int x=(size*(0.2+(i%3)*0.28)).round(),y=(size*(0.25+(i~/3)*0.45)).round();while(!w.tiles[y*size+x].passable){x=(x+1)%size;}final s=Society('s$i',names[i],profiles[i],x,y,culture:names[i]);s.policy.research=['agriculture','sanitation','mining','writing','masonry','trade'][i];s.policy.risk=i==2?0.7:0.35;s.policy.diplomacy=i==4?'defend':'cooperate';s.people=[Person('p${i}a',i==0?'Ana':'Iria $i','técnica',-28*360,'inventive'),Person('p${i}b',i==0?'Leo':'Nilo $i','explorador',-24*360,'bold'),Person('p${i}c',i==0?'Tito':'Sol $i','suministros',-42*360,'prudent')];s.leaderId=s.people.last.id;for(int j=0;j<6;j++){if(i!=j)s.relations['s$j']=r.nextInt(41)-10;}s.ensureSites();w.societies.add(s);}
 w.chronicle.add(HistoryEntry('h0',0,'Un mundo vuelve a respirar','Ana, Leo y Tito reúnen a 56 habitantes junto a las ruinas. Cada decisión tendrá memoria.','inicio','s0',w.societies.first.x,w.societies.first.y));w.serial=1;return w;
 }
 Society? society(String? id){for(final s in societies){if(s.id==id)return s;}return null;}
 Society get controlled=>society(controlledId)??societies.first;
 String get date=>'Año ${day~/360+1} · mes ${(day%360)~/30+1} · día ${day%30+1}';
 Map<String,dynamic> toJson()=>{'schema':1,'seed':seed,'size':size,'day':day,'serial':serial,'intensity':intensity,'extraordinary':extraordinary,'rng':random.state,'controlledId':controlledId,'tiles':tiles.map((t)=>t.toJson()).toList(),'societies':societies.map((s)=>s.toJson()).toList(),'chronicle':chronicle.map((h)=>h.toJson()).toList(),'pending':pending.map((e)=>e.toJson()).toList(),'routes':routes.map((r)=>r.toJson()).toList(),'annualSnapshots':annualSnapshots,'contentVersions':contentVersions,'contentHistory':contentHistory,'commandReceipts':commandReceipts};
 factory WorldState.fromJson(Map<String,dynamic> j){if(j['schema']!=1)throw FormatException('Esquema incompatible');final w=WorldState._(j['seed'],j['size'],j['intensity'],j['extraordinary']);w.day=j['day'];w.serial=j['serial'];w.random.state=j['rng'];w.controlledId=j['controlledId'];w.tiles=(j['tiles'] as List).map((e)=>Tile.fromJson(Map<String,dynamic>.from(e))).toList();w.societies=(j['societies'] as List).map((e)=>Society.fromJson(Map<String,dynamic>.from(e))).toList();w.chronicle=(j['chronicle'] as List).map((e)=>HistoryEntry.fromJson(Map<String,dynamic>.from(e))).toList();w.pending=(j['pending'] as List).map((e)=>ScheduledEvent.fromJson(Map<String,dynamic>.from(e))).toList();w.routes=(j['routes'] as List).map((e)=>TradeRoute.fromJson(Map<String,dynamic>.from(e))).toList();w.annualSnapshots=(j['annualSnapshots'] as Map).map((k,v)=>MapEntry(k as String,Map<String,num>.from(v)));w.contentVersions=Map<String,String>.from(j['contentVersions']);w.contentHistory=Map<String,int>.from(j['contentHistory']??{});w.commandReceipts=(j['commandReceipts'] as Map? ?? {}).map((k,v)=>MapEntry(k as String,Map<String,dynamic>.from(v as Map)));w.validate();return w;}
 void validate(){
 if(size!=64&&size!=96)throw const FormatException('Tamaño de mundo inválido');
 if(day<0||serial<0||tiles.length!=size*size)throw const FormatException('Calendario o terreno inválido');
 if(societies.isEmpty||societies.length>100)throw const FormatException('Número de sociedades inválido');
 final ids=societies.map((s)=>s.id).toSet();if(ids.length!=societies.length)throw const FormatException('Sociedades duplicadas');
 if(controlledId!=null&&!ids.contains(controlledId))throw const FormatException('Control sin sociedad');
 final personIds=<String>{};
 for(int i=0;i<tiles.length;i++){final t=tiles[i];if(t.x!=i%size||t.y!=i~/size||t.biome<0||t.biome>=6||!t.damage.isFinite||t.damage<0||t.damage>1)throw const FormatException('Celda inválida');}
 for(final s in societies){
 if(s.x<0||s.x>=size||s.y<0||s.y>=size||s.children<0||s.adults<0||s.elders<0||s.population>10000000)throw StateError('Población o posición imposible: ${s.id}');
 if(!resourceIds.every(s.resources.containsKey)||s.resources.keys.any((id)=>!resourceIds.contains(id))||s.resources.values.any((v)=>!v.isFinite||v<0||v>100000000))throw StateError('Recursos imposibles: ${s.id}');
 if(s.expeditionWorkers!=0&&s.expeditionWorkers!=4)throw const FormatException('Reserva de expedición inválida');
 if(s.built.entries.any((e)=>e.value<0||!buildings.any((b)=>b.id==e.key)))throw const FormatException('Edificio inválido');
 final siteIds=<String>{};final sitePositions=<String>{};final siteCounts=<String,int>{};for(final site in s.sites){if(!siteIds.add(site.id)||!sitePositions.add('${site.x}:${site.y}')||site.x<0||site.x>=32||site.y<0||site.y>=32||!buildings.any((b)=>b.id==site.building))throw const FormatException('Plano local inválido');siteCounts[site.building]=(siteCounts[site.building]??0)+1;}if(s.built.entries.any((e)=>(siteCounts[e.key]??0)!=e.value))throw const FormatException('Plano y edificios no coinciden');
 if(s.projects.any((p)=>p.finish<0||!buildings.any((b)=>b.id==p.building)))throw const FormatException('Proyecto inválido');
 if(s.tech.any((id)=>!technologies.any((t)=>t.id==id)))throw const FormatException('Tecnología inválida');
 if(s.relations.entries.any((e)=>!ids.contains(e.key)||e.value< -100||e.value>100))throw const FormatException('Relación inválida');
 if([s.health,s.morale,s.environment].any((v)=>!v.isFinite||v<0||v>100))throw const FormatException('Indicador inválido');
 if(!s.policy.reserve.isFinite||s.policy.reserve<0||!s.policy.risk.isFinite||s.policy.risk<0||s.policy.risk>1)throw const FormatException('Política inválida');
 for(final p in s.people){if(!personIds.add(p.id)||p.bornDay>day||(p.diedDay!=null&&(p.diedDay!>day||p.diedDay!<p.bornDay)))throw const FormatException('Persona inválida');}
 if(s.alive&&!s.people.any((p)=>p.id==s.leaderId))throw const FormatException('Dirigente inexistente');
 }
 for(final receipt in commandReceipts.entries){if(receipt.key.isEmpty||receipt.key.length>128||receipt.value['fingerprint'] is! String||receipt.value['message'] is! String||receipt.value['day'] is! int||(receipt.value['day'] as int)>day||(receipt.value['day'] as int)<0)throw const FormatException('Recibo de orden inválido');}
 final eventIds=<String>{};for(final e in pending){if(!eventIds.add(e.id)||!ids.contains(e.societyId)||e.day<0)throw const FormatException('Consecuencia inválida');}
 for(final r in routes){if(!ids.contains(r.from)||!ids.contains(r.to)||r.from==r.to||r.path.isEmpty||r.path.any((p)=>p<0||p>=tiles.length)||!r.cargo.isFinite||r.cargo<0||r.progress<0||r.progress>=r.path.length)throw const FormatException('Ruta inválida');for(int i=1;i<r.path.length;i++){final a=tiles[r.path[i-1]],b=tiles[r.path[i]];if((a.x-b.x).abs()+(a.y-b.y).abs()!=1)throw const FormatException('Ruta desconectada');}}
 }

 /// Commits an already validated candidate without changing the WorldState identity.
 /// References to nested entities must be reacquired after a successful submit.
 void _adopt(WorldState value) {
  seed=value.seed;size=value.size;day=value.day;serial=value.serial;
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
 society.tech.contains('engineering')?(building.days*0.75).ceil():building.days;

class Simulation {
 final WorldState world; Map<String,dynamic>? content;
 final void Function(HistoryEntry)? onHistory;
 Simulation(this.world,{this.onHistory});
 void registerContent(Map<String,dynamic> package){content=package;} 
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
  final emitted=<HistoryEntry>[];
  try {
   final candidate=WorldState.fromJson(world.toJson());
   final trial=Simulation(candidate,onHistory:emitted.add);
   if(content!=null)trial.registerContent(content!);
   final result=request.action=='resolve_event'
    ? trial.resolveContentEvent(request.target??'',request.choice??'',societyId:request.actorId)
    : trial.command(request.action,societyId:request.actorId,
      target:request.target,choice:request.choice);
   if(!result.ok)return _CommandEvaluation(CommandResult(false,result.message,code:'rejected'));
   candidate.commandReceipts[request.id]={'fingerprint':request.fingerprint,
    'message':result.message,'day':candidate.day};
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
    costs=_explorationCost;workers=4;duration=8;
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
   case 'trade':
    costs={'food':12,'textiles':5};
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

 String _id(String prefix)=>'$prefix${world.serial++}';
 HistoryEntry record(Society s,String title,String text,String category,{String? cause}){final h=HistoryEntry(_id('h'),world.day,title,text,category,s.id,s.x,s.y,cause:cause);world.chronicle.add(h);if(world.chronicle.length>2400){final referenced={...world.chronicle.map((e)=>e.cause),...world.pending.map((e)=>e.cause)};int removed=0;world.chronicle.removeWhere((entry){if(removed<400&&!referenced.contains(entry.id)&&entry.id!=h.id){removed++;return true;}return false;});}onHistory?.call(h);return h;}
 bool _pay(Society s,Map<String,double> cost){if(cost.entries.any((e)=>(s.resources[e.key]??0)<e.value))return false;for(final e in cost.entries) {
   s.resources[e.key]=s.resources[e.key]!-e.value;
 }return true;}
 /// Trusted rule interface for autonomous actions; player callers use submit.
 CommandResult command(String action,{String? societyId,String? target,String? choice}) {
 final s=world.society(societyId??world.controlledId);if(action=='delegate'){world.controlledId=null;return const CommandResult(true,'Todas las comunidades quedan delegadas.');}if(action=='control'){final t=world.society(target);if(t==null||!t.alive)return const CommandResult(false,'Comunidad no disponible.');world.controlledId=t.id;return CommandResult(true,'Ahora guías ${t.name}.');}if(s==null||!s.alive)return const CommandResult(false,'No hay una comunidad viva seleccionada.');
 if(action=='policy'){switch(target){case 'balanced':s.policy=Policy();break;case 'food':s.policy.reserve=240;s.policy.expansion=false;s.policy.research='agriculture';s.policy.risk=0.2;break;case 'science':s.policy.research='science';s.policy.risk=0.65;break;case 'trade':s.policy.trade=true;s.policy.diplomacy='cooperate';s.policy.risk=0.25;break;case 'defense':s.policy.diplomacy='defend';s.policy.risk=0.3;s.policy.expansion=false;break;case 'expansion':s.policy.expansion=true;s.policy.risk=0.6;break;case 'isolation':s.policy.trade=false;s.policy.diplomacy='isolate';s.policy.expansion=false;s.policy.risk=0.2;break;default:return const CommandResult(false,'Política desconocida.');}record(s,'Prioridades de gobierno', 'El consejo adopta $target; se conservan al cambiar de comunidad.','política');return const CommandResult(true,'Prioridades actualizadas.');}
 if(action=='repair'){if(world.tiles[s.y*world.size+s.x].damage<=0&&s.housingModifier>=0&&s.defenseModifier>=0)return const CommandResult(false,'No hay daños que reparar.');if(!_pay(s,_repairCost))return const CommandResult(false,'Reparar requiere 10 madera, 8 piedra y 2 herramientas.');final tile=world.tiles[s.y*world.size+s.x];tile.damage=math.max(0.0,tile.damage-0.5);if(s.housingModifier<0)s.housingModifier=math.min(0,s.housingModifier+18);if(s.defenseModifier<0)s.defenseModifier=math.min(0,s.defenseModifier+5);record(s,'Manos que reparan','Se recuperan viviendas dañadas y se limpia parte del territorio.','reparación');return const CommandResult(true,'Reparación completada.');}
 if(action=='build'){if(s.sites.length+s.projects.length>=196)return const CommandResult(false,'La cuadrícula local está ocupada. Funda otro asentamiento.');final matches=buildings.where((b)=>b.id==target);if(matches.isEmpty)return const CommandResult(false,'Edificio desconocido.');final b=matches.first;if(b.technology!=null&&!s.tech.contains(b.technology))return const CommandResult(false,'Falta la tecnología requerida.');if(s.workers<4||s.projects.length>=math.max(1,s.adults~/12))return const CommandResult(false,'No quedan cuatro trabajadores y capacidad de coordinación disponibles.');if(!_pay(s,b.cost))return const CommandResult(false,'Faltan materiales; no se reservó nada.');s.projects.add(Project(b.id,world.day+_constructionDays(b,s)));record(s,'Obra: ${b.name}','Materiales y cuatro trabajadores reservados.','construcción');return CommandResult(true,'${b.name}: ${_constructionDays(b,s)} días.');}
 if(action=='research'){final t=technologies.where((t)=>t.id==target);if(t.isEmpty)return const CommandResult(false,'Tecnología desconocida.');final tech=t.first;if(s.tech.contains(tech.id))return const CommandResult(false,'Conocimiento ya adquirido.');if(!tech.requires.every(s.tech.contains))return const CommandResult(false,'Faltan conocimientos previos.');if(!_pay(s,{'knowledge':tech.cost}))return const CommandResult(false,'Conocimiento insuficiente.');s.tech.add(tech.id);record(s,'Avance: ${tech.name}',tech.effect,'tecnología');return CommandResult(true,'${tech.name} incorporada.');}
 if(action=='explore'){
  if(s.expeditionWorkers>0||world.pending.any((e)=>e.type=='discovery'&&e.societyId==s.id))return const CommandResult(false,'La expedición anterior todavía no ha regresado.');
  if(s.workers<4)return const CommandResult(false,'La expedición necesita cuatro adultos disponibles.');
  final explorer=s.people.where((p)=>p.alive&&p.role=='explorador').firstOrNull;
  if(!_pay(s,_explorationCost))return const CommandResult(false,'Se necesitan 12 alimentos y 2 herramientas.');
  s.expeditionWorkers=4;
  final h=record(s,explorer==null?'Parte un equipo de exploración':'${explorer.name} parte de expedición','Cuatro adultos buscarán rutas y vestigios durante ocho días.','exploración');
  world.pending.add(ScheduledEvent(_id('e'),'discovery',s.id,world.day+8,cause:h.id,data:{'workers':4,'explorerId':explorer?.id}));
  return const CommandResult(true,'Expedición en camino; cuatro trabajadores reservados.');
 }
 if(action=='facility'){if(!s.facilityFound||s.facilityChoice!=null)return const CommandResult(false,'No hay una instalación pendiente.');final options=_facilityCosts;if(!options.containsKey(choice))return const CommandResult(false,'Respuesta desconocida.');if(!_pay(s,options[choice]!))return const CommandResult(false,'Faltan recursos para esa respuesta.');s.facilityChoice=choice;s.flags.add('facility_committed');final h=record(s,'El destino de la instalación',{'seal':'La entrada queda sellada. Se preserva el entorno.','salvage':'Se recuperan piezas, pero se pierde el archivo.','study':'El equipo técnico estudia el núcleo. El resultado depende de salud y conocimientos.','share':'Se invita a vecinos a compartir el hallazgo.'}[choice]!,'decisión');world.pending.add(ScheduledEvent(_id('e'),'facility_$choice',s.id,world.day+(choice=='study'?25:10),cause:h.id));return const CommandResult(true,'Decisión comprometida; sus consecuencias llegarán.');}
 if(action=='trade'||action=='diplomacy'){final other=world.society(target);if(other==null||other.id==s.id||!other.alive)return const CommandResult(false,'Destino inválido.');if(action=='diplomacy'){if(!_pay(s,{'food':10}))return const CommandResult(false,'Faltan víveres para la delegación.');s.relations[other.id]=math.min(100,(s.relations[other.id]??0)+(s.leaderTrait=='conciliatory'?30:s.leaderTrait=='guarded'?10:20));other.relations[s.id]=math.min(100,(other.relations[s.id]??0)+15);record(s,'Una mesa compartida','El pacto con ${other.name} mejora la confianza.','diplomacia');return const CommandResult(true,'Relaciones mejoradas.');}return _openRoute(s,other);}
 return const CommandResult(false,'Orden desconocida.');
 }
 List<int> findPath(Society a,Society b){final size=world.size,start=a.y*size+a.x,end=b.y*size+b.x;final queue=<int>[start];final prev=<int,int>{start:-1};int head=0;while(head<queue.length){final p=queue[head++];if(p==end)break;final x=p%size,y=p~/size;for(final q in [if(x>0)p-1,if(x<size-1)p+1,if(y>0)p-size,if(y<size-1)p+size]){if(!prev.containsKey(q)&&world.tiles[q].passable&&world.tiles[q].damage<0.9){prev[q]=p;queue.add(q);}}}if(!prev.containsKey(end))return [];final path=<int>[];for(int p=end;p!=-1;p=prev[p]!) {
   path.add(p);
 }return path.reversed.toList();}
 CommandResult _openRoute(Society s,Society other){if(world.routes.any((r)=>(r.from==s.id&&r.to==other.id)||(r.from==other.id&&r.to==s.id)))return const CommandResult(false,'La ruta ya existe.');if((s.relations[other.id]??0)<-20)return const CommandResult(false,'La hostilidad impide comerciar.');final path=findPath(s,other);if(path.isEmpty)return const CommandResult(false,'No existe un paso terrestre seguro.');if(!_pay(s,{'food':12,'textiles':5}))return const CommandResult(false,'Falta carga para la caravana.');world.routes.add(TradeRoute(_id('r'),s.id,other.id,path));record(s,'Caravana hacia ${other.name}','Transporta 12 alimentos por ${path.length} celdas transitables.','comercio');return const CommandResult(true,'Ruta terrestre establecida.');}
 bool delegateDecisions=false;
 int advanceDays(int count,{bool stopOnCrisis=false,bool delegateDecisions=false}){this.delegateDecisions=delegateDecisions;int advanced=0;for(int i=0;i<count;i++){if(world.extinct)break;_tick();advanced++;if(stopOnCrisis&&(world.pending.any((e)=>e.type=='content_choice')||world.societies.any((s)=>s.alive&&(s.health<35||(s.resources['food']??0)<s.population*0.5||(s.facilityFound&&s.facilityChoice==null)))))break;}return advanced;}
 void _tick(){world.day++;for(final s in List<Society>.from(world.societies)){if(!s.alive)continue;_economy(s);_projects(s);if(world.day%30==0){_monthly(s);_directContent(s);}if(world.day%360==0)_yearly(s);}final due=world.pending.where((e)=>e.day<=world.day).toList()..sort((a,b){final c=a.day.compareTo(b.day);return c==0?a.id.compareTo(b.id):c;});for(final e in due){world.pending.remove(e);final s=world.society(e.societyId);if(s!=null&&e.type=='discovery')s.expeditionWorkers=0;if(s==null||!s.alive)continue;_resolve(s,e);}for(final r in world.routes) {
   _routeTick(r);
 }if(world.day%360==0){world.annualSnapshots['${world.day}']={'population':world.societies.fold<int>(0,(int p,s)=>p+s.population),'settlements':world.societies.where((s)=>s.alive).length,'technologies':world.societies.fold<int>(0,(int p,s)=>p+s.tech.length),'damage':world.societies.fold<double>(0.0,(double p,s)=>p+s.environment)};if(world.annualSnapshots.length>1000)world.annualSnapshots.remove(world.annualSnapshots.keys.first);}}
 void _economy(Society s){final workers=s.workers;double multiplier=math.min(1,workers/math.max(1,s.built.values.fold<int>(0,(int a,b)=>a+b)*2));multiplier*=s.health/100;multiplier*=s.leaderTrait=='pragmatic'?1.25:1;multiplier*=s.tech.contains('cybernetics')?1.2:1;multiplier*=1+s.tech.length*0.01;multiplier*=s.tech.contains('automation')?1.5:1;if(s.tech.contains('metallurgy'))multiplier*=1.15;if(s.tech.contains('industry'))multiplier*=1.25;if(s.tech.contains('robotics'))multiplier*=1.2;for(final b in buildings){final n=s.built[b.id]??0;if(n==0)continue;if(b.id=='generator'&&(s.resources['fuel']??0)<0.08*n)continue;if(b.id=='generator')s.resources['fuel']=math.max(0.0,s.resources['fuel']!-0.08*n);if(b.id=='workshop'&&(s.resources['metal']??0)<0.04*n)continue;if(b.id=='workshop')s.resources['metal']=math.max(0.0,s.resources['metal']!-0.04*n);for(final e in b.yield.entries){double output=e.value*n*multiplier;if(e.key=='knowledge'){output*=s.leaderTrait=='inventive'?1.3:s.leaderTrait=='traditional'?0.85:1;output*=s.tech.contains('writing')?1.15:1;output*=s.tech.contains('computing')?1.3:1;}if(e.key=='medicine'&&s.tech.contains('chemistry'))output*=1.5;if(e.key=='energy'&&s.tech.contains('fusion'))output*=3;if(e.key=='food'){output*=[1.15,1.0,0.65,0.6,1.1,0.8][world.tiles[s.y*world.size+s.x].biome];output*=s.tech.contains('agriculture')?1.4:1;output*=s.tech.contains('irrigation')?1.3:1;output*=1-s.environment*0.004;}s.resources[e.key]=math.min(100000.0,(s.resources[e.key]??0)+math.max(0.0,output));}}
 s.resources['wood']=math.min(100000.0,s.resources['wood']!+workers*0.015);s.resources['knowledge']=math.min(100000.0,s.resources['knowledge']!+workers*(s.tech.contains('education')?0.012:0.006));final foodNeed=s.population*0.045,waterNeed=s.population*0.035;bool hunger=s.resources['food']!<foodNeed,thirst=s.resources['water']!<waterNeed;s.resources['food']=math.max(0.0,s.resources['food']!-foodNeed);s.resources['water']=math.max(0.0,s.resources['water']!-waterNeed);s.health=(s.health+(hunger?-0.65:0.04)+(thirst?-0.9:0.02)+(s.tech.contains('sanitation')?0.02:0)).clamp(0,100).toDouble();s.morale=(s.morale+(s.tech.contains('synthesis')?0.02:0)+(hunger?-0.25:0.015)+(s.population>s.housing?-0.03:0.01)).clamp(0,100).toDouble();if(hunger||thirst){if(world.day%30==0)record(s,'Reservas agotadas','La escasez reduce salud y obliga a cambiar prioridades.','necesidad');}s.environment=(s.environment+(s.built['generator']??0)*0.001+(s.built['mine']??0)*0.001-(s.tech.contains('ecology')||s.leaderTrait=='green'?0.008:0.001)).clamp(0,100).toDouble();
 }
 void _projects(Society s){for(final p in s.projects.where((p)=>p.finish<=world.day).toList()){s.projects.remove(p);s.built[p.building]=(s.built[p.building]??0)+1;s.addSite(p.building);final b=buildings.firstWhere((b)=>b.id==p.building);record(s,'${b.name} terminado','El edificio ya produce y ocupa su lugar en ${s.name}.','construcción');}}
 void _monthly(Society s){if(s.health<30&&s.population>0){final losses=math.max(1,(s.population*0.03).floor());_removePeople(s,losses);record(s,'Pérdidas por privación','$losses habitantes murieron; la comunidad recuerda la pérdida.','necesidad');}if(!s.alive)return;if(s.population==0){s.extinct=true;return;}if(s.id!=world.controlledId||delegateDecisions)_autonomy(s);if(world.random.nextInt(18)==0)_ambient(s);if(s.facilityFound&&s.facilityChoice==null&&(s.id!=world.controlledId||delegateDecisions)){final c=s.risk>0.6?'study':s.policy.diplomacy=='cooperate'?'share':'seal';command('facility',societyId:s.id,choice:c);record(s,'Resolución delegada','El consejo eligió $c según su política.','política');}}
 void _autonomy(Society s){final autonomous=s.id!=world.controlledId;final food=s.resources['food']!;if(s.projects.length<math.max(1,s.adults~/12)){String? target;if(food<s.policy.reserve*(s.leaderTrait=='patient'?1.3:1)||(s.built['farm']??0)<(s.population/35).ceil()) {
   target='farm';
 } else if(s.resources['water']!<100){target='well';}else if(s.housing<s.population+12){target='house';}else if(autonomous&&world.random.nextInt(3)==0){target=['sawmill','school','quarry','loom'][world.random.nextInt(4)];}if(target!=null)command('build',societyId:s.id,target:target);}
 if(autonomous){final preferred=technologies.where((t)=>t.id==s.policy.research&&!s.tech.contains(t.id)&&t.requires.every(s.tech.contains));final available=technologies.where((t)=>!s.tech.contains(t.id)&&t.requires.every(s.tech.contains));if(preferred.isNotEmpty) {
   command('research',societyId:s.id,target:preferred.first.id);
 } else if(available.isNotEmpty){command('research',societyId:s.id,target:available.first.id);}if(s.policy.trade&&world.day%180==0){final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isNotEmpty)command('trade',societyId:s.id,target:others[world.random.nextInt(others.length)].id);}if(!s.facilityFound&&world.day%(s.tech.contains('orbital')?360:720)==0)command('explore',societyId:s.id);}
 if(s.health<45&&s.population>15){final candidates=world.societies.where((o)=>o.alive&&o.id!=s.id&&o.health>65&&o.housing>o.population+4).toList();if(candidates.isNotEmpty){final to=candidates.first;final n=math.min(4,s.adults);s.adults-=n;to.adults+=n;record(s,'Familias emigran','$n adultos se trasladan a ${to.name} buscando seguridad.','migración');record(to,'Llegan refugiados','$n adultos de ${s.name} se incorporan sin duplicar población.','migración');}}
 }
 void _yearly(Society s){final r=world.random;int cohort(String id,double rate){final total=(s.demographicCarry[id]??0)+rate;final count=total.floor();s.demographicCarry[id]=total-count;return count;} final grown=math.min(s.children,cohort('grown',s.children/16));s.children-=grown;s.adults+=grown;final aged=math.min(s.adults,cohort('aged',s.adults/45));s.adults-=aged;s.elders+=aged;final oldDeaths=math.min(s.elders,cohort('oldDeaths',s.elders*(s.tech.contains('medicine')?0.05:0.09)));s.elders-=oldDeaths;final births=(s.health>55&&s.housing>s.population&&s.resources['food']!>s.population)?cohort('births',s.adults*(s.tech.contains('biotech')?0.055:0.045)):0;s.children+=math.min(births,math.max(0,s.housing-s.population));for(final p in s.people.where((p)=>p.alive)){final age=(world.day-p.bornDay)~/360;if(age>72&&(r.nextInt(100)<(age-70)*5||age>100)){p.diedDay=world.day;record(s,'Muere ${p.name}','Su trabajo y sus decisiones quedan en la memoria de ${s.culture}.','generación');}}
 if(!s.people.any((p)=>p.alive&&p.id==s.leaderId)&&s.adults>0){final id=_id('p');final p=Person(id,['Alma','Dara','Bruno','Nerea','Elio','Maia'][r.nextInt(6)],'dirigente',world.day-(22+r.nextInt(24))*360,traitNames[r.nextInt(traitNames.length)]);s.people.add(p);s.leaderId=id;record(s,'Una nueva generación dirige','${p.name}, de carácter ${p.trait}, asume los compromisos existentes.','generación');}if(s.people.where((p)=>p.alive&&p.role=='técnica').isEmpty&&s.adults>10){s.people.add(Person(_id('p'),'Aprendiz ${world.day~/360}','técnica',world.day-24*360,'inventive'));}
 if(s.policy.expansion&&s.population>(s.leaderTrait=='restless'?80:95)&&s.resources['food']!>300&&world.societies.length<40){_colonize(s);}if(s.population==0&&!s.extinct){s.extinct=true;record(s,'Silencio en ${s.name}','La comunidad desaparece; sus ruinas y su historia permanecen.','legado');}}
 void _colonize(Society s){if(s.children<5||s.adults<20)return;final x=(s.x+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt(),y=(s.y+world.random.nextInt(15)-7).clamp(1,world.size-2).toInt();if(!world.tiles[y*world.size+x].passable||world.societies.any((o)=>((o.x-x).abs()+(o.y-y).abs())<5))return;const cost={'food':150.0,'wood':80.0,'stone':40.0,'tools':10.0};if(!_pay(s,cost))return;final c=Society(_id('s'),'${s.culture} · ${world.societies.length+1}',s.profile,x,y,children:5,adults:20,elders:0,founded:world.day,culture:s.culture);c.resources={for(final r in resourceIds)r:0};c.resources.addAll(cost);c.built={'farm':1,'well':1,'house':2};c.tech=Set.from(s.tech);c.people=[Person(_id('p'),'Vera','dirigente',world.day-30*360,'patient')];c.leaderId=c.people.first.id;s.children-=5;s.adults-=20;c.relations[s.id]=50;s.relations[c.id]=50;c.ensureSites();world.societies.add(c);record(s,'Nace ${c.name}','25 habitantes y recursos reales fundan una colonia vinculada a su cultura.','expansión');}
 void _removePeople(Society s,int n){int v=math.min(n,s.elders);s.elders-=v;n-=v;v=math.min(n,s.adults);s.adults-=v;n-=v;s.children=math.max(0,s.children-n);if(s.population==0){s.extinct=true;for(final p in s.people.where((p)=>p.alive)) {
   p.diedDay=world.day;
 }record(s,'La comunidad cae','No queda población capaz de actuar. Las ruinas conservan su legado.','legado');}}
 void _routeTick(TradeRoute r){final a=world.society(r.from),b=world.society(r.to);if(a==null||b==null||!a.alive||!b.alive){r.blocked=true;return;}r.blocked=(a.relations[b.id]??0)<-35||r.path.any((p)=>world.tiles[p].damage>=0.9);if(r.blocked)return;r.progress+=a.tech.contains('logistics')?2:1;if(r.progress>=r.path.length){r.progress=0;if(r.cargo>0){b.resources['food']=b.resources['food']!+r.cargo;final metal=math.min(3.0,b.resources['metal']!);b.resources['metal']=b.resources['metal']!-metal;a.resources['metal']=a.resources['metal']!+metal;}r.cargo=math.min(a.tech.contains('trade')||a.leaderTrait=='generous'?16.0:12.0,a.resources['food']!);a.resources['food']=a.resources['food']!-r.cargo;}}
 void _ambient(Society s){final r=world.random;final roll=r.nextInt(8),severity=(world.intensity=='extrema'||world.intensity=='extreme')?3:(world.intensity=='caótica'||world.intensity=='chaotic')?2:1;if(roll==0){final loss=math.min(s.resources['food']!,20.0*severity);s.resources['food']=s.resources['food']!-loss;record(s,'Sequía sobre los cultivos','Una variación climática destruye ${loss.round()} alimentos. No es consecuencia de una orden.','entorno');}else if(roll==1){s.resources['wood']=s.resources['wood']!+15;record(s,'Madera recuperada','Los habitantes rescatan 15 maderas de una estructura caída.','economía');}else if(roll==2){s.health=(s.health-8*severity).clamp(0,100).toDouble();record(s,'Fiebre del polvo','Una epidemia ficticia exige cuidados y reduce salud.','salud');}else if(roll==3){s.resources['knowledge']=s.resources['knowledge']!+12;record(s,'Lecciones compartidas','La escuela y los mayores conservan 12 conocimientos.','tecnología');}else if(roll==4&&s.risk>0.6){final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isNotEmpty){final o=others[r.nextInt(others.length)];s.relations[o.id]=((s.relations[o.id]??0)-(s.tech.contains('diplomacy')?8:15)).clamp(-100,100).toInt();if(s.relations[o.id]!<-40){final supply=math.min(20.0,s.resources['food']!);s.resources['food']=s.resources['food']!-supply;final strength=s.adults*(1+s.defenseModifier*0.02)*(s.built['wall']!=null?1.3:1)*(1+s.tech.length*0.03);final defense=o.adults*(o.leaderTrait=='severe'?1.3:1)*(1+o.defenseModifier*0.02)*(o.built['wall']!=null?1.5:1);_removePeople(strength>defense?o:s,2*severity);record(s,'Conflicto con ${o.name}','La rivalidad y el riesgo político producen bajas y consumo de suministros.','conflicto');}}}else if(roll==5&&world.extraordinary&&r.nextInt(10)<severity){world.pending.add(ScheduledEvent(_id('e'),'anomaly',s.id,world.day+15));record(s,'Luces bajo la tierra','La señal anticipa una anomalía de origen desconocido.','extraordinario');}}
 void _resolve(Society s,ScheduledEvent e){if(e.type=='content'){_resolveScheduledContent(s,e);return;}switch(e.type){case 'discovery':final explorerId=e.data['explorerId'];if(explorerId!=null&&!s.people.any((p)=>p.id==explorerId&&p.alive)){record(s,'Expedición interrumpida','La pérdida de su responsable obliga al equipo a regresar sin completar la búsqueda.','exploración',cause:e.cause);break;}s.discoveries++;if(!s.facilityFound){s.facilityFound=true;record(s,'La instalación antigua','La expedición encuentra un núcleo sellado. Puedes sellarlo, desmontarlo, estudiarlo o compartirlo.','exploración',cause:e.cause);}else{s.resources['metal']=s.resources['metal']!+12;record(s,'Regreso de la expedición','La exploración recupera 12 metales de un vestigio.','exploración',cause:e.cause);}break;
 case 'facility_seal':s.environment=math.max(0.0,s.environment-10);s.morale=(s.morale+8).clamp(0,100).toDouble();record(s,'El jardín del umbral','El sellado evita riesgos y deja una zona protegida.','consecuencia',cause:e.cause);break;
 case 'facility_salvage':s.resources['metal']=s.resources['metal']!+65;s.resources['tools']=s.resources['tools']!+15;s.environment=(s.environment+8).clamp(0,100).toDouble();record(s,'Metal a cambio de memoria','Se recuperan materiales; el archivo antiguo queda destruido.','consecuencia',cause:e.cause);break;
 case 'facility_share':final others=world.societies.where((o)=>o.alive&&o.id!=s.id).toList();if(others.isEmpty){record(s,'Una invitación sin respuesta','No queda otra comunidad capaz de aceptar; el núcleo se conserva.','consecuencia',cause:e.cause);break;}final o=others.first;s.relations[o.id]=math.min(100,(s.relations[o.id]??0)+35);o.relations[s.id]=math.min(100,(o.relations[s.id]??0)+35);s.resources['knowledge']=s.resources['knowledge']!+45;o.resources['knowledge']=o.resources['knowledge']!+25;record(s,'El pacto del umbral','${o.name} comparte estudios y conserva una deuda de cooperación.','consecuencia',cause:e.cause);_openRoute(s,o);break;
 case 'facility_study':if(!s.people.any((p)=>p.alive&&p.role=='técnica')){record(s,'Estudio suspendido','No queda especialista; el proyecto espera una generación formada.','consecuencia',cause:e.cause);world.pending.add(ScheduledEvent(_id('e'),'facility_study',s.id,world.day+360,cause:e.cause));break;}final safe=s.tech.contains('science')||world.random.nextInt(100)<s.health*0.7;if(safe){s.resources['energy']=s.resources['energy']!+90;s.tech.add('electricity');final discovery=record(s,'El núcleo despierta','La investigación produce energía y una tecnología recuperada.','consecuencia',cause:e.cause);world.pending.add(ScheduledEvent(_id('e'),'energy_growth',s.id,world.day+120,cause:discovery.id));if(world.extraordinary)world.pending.add(ScheduledEvent(_id('e'),'signal',s.id,world.day+720,cause:discovery.id));}else{s.health=(s.health-20).clamp(0,100).toDouble();_removePeople(s,3);record(s,'Accidente del núcleo','La investigación sin garantías libera una descarga y causa tres bajas.','consecuencia',cause:e.cause);}break;
 case 'energy_growth':final room=math.max(0,s.housing-s.population);if(room>=4){final source=world.societies.where((o)=>o.alive&&o.id!=s.id&&o.adults>=4).toList();if(source.isNotEmpty){source.first.adults-=4;s.adults+=4;record(s,'La luz atrae familias','Cuatro adultos llegan desde ${source.first.name}; aumentan la demanda de alimentos.','migración',cause:e.cause);}}else{record(s,'Una ciudad demasiado estrecha','La energía atrajo interés, pero la falta de vivienda impide recibir familias.','consecuencia',cause:e.cause);}break;
 case 'signal':final allied=s.relations.values.where((v)=>v>35).length;final peaceful=s.policy.diplomacy=='cooperate'&&(allied>0||s.tech.contains('xenology'));if(peaceful){s.resources['knowledge']=s.resources['knowledge']!+120;s.tech.add('radio');record(s,'Voces entre estrellas','La señal recibe respuesta: intercambio bajo un pacto de convivencia.','extraordinario',cause:e.cause);}else if(s.risk>0.6){_removePeople(s,math.min(s.adults,12));s.resources['energy']=0;record(s,'La visita hostil','La señal y una respuesta agresiva desembocan en incursión y resistencia.','extraordinario',cause:e.cause);}else{s.morale=(s.morale-12).clamp(0,100).toDouble();s.resources['knowledge']=s.resources['knowledge']!+50;record(s,'Los tutores del silencio','El contacto entrega conocimiento a cambio de influencia política.','extraordinario',cause:e.cause);}break;
 case 'anomaly':final response=s.tech.contains('ecology')||s.risk<0.3;if(response){s.resources['crystal']=s.resources['crystal']!+10;record(s,'Anomalía contenida','La preparación permite recuperar cristales sin pérdidas.','extraordinario',cause:e.cause);}else{s.environment=(s.environment+20).clamp(0,100).toDouble();s.health=(s.health-15).clamp(0,100).toDouble();world.tiles[s.y*world.size+s.x].damage=1;record(s,'La tierra cambia de voz','Una instalación autónoma daña el territorio e interrumpe sus rutas.','extraordinario',cause:e.cause);}break;
 }}
}

/// Declarative content interpreter. No executable code is accepted from packages.
extension ContentSimulation on Simulation {
 List<Map<String,dynamic>> get contentEvents {
 final result=((content?['events']??[]) as List).map((e)=>Map<String,dynamic>.from(e)).toList();
 for(final raw in (content?['templates']??[]) as List){final t=Map<String,dynamic>.from(raw);final p=t['parameter'] as Map;final low=p['minimum'] as int,high=p['maximum'] as int;final parameter=low+((world.seed+(t['id'] as String).codeUnits.fold<int>(0,(int a,b)=>a+b)+world.day~/180)%(high-low+1));
 final options=<Map<String,dynamic>>[];for(final option in t['options'] as List){final o=Map<String,dynamic>.from(option);final costs=<String,num>{};for(final cost in ((o['costs']??{}) as Map).entries){final value=cost.value;costs[cost.key]=value is Map?(value['base'] as num)+(value['perUnit'] as num)*parameter:value as num;}
 final effects=<Map<String,dynamic>>[];for(final effect in (o['effects']??[]) as List){final e=Map<String,dynamic>.from(effect);if(e.containsKey('base'))e['value']=(e['base'] as num)+(e['perUnit'] as num)*parameter;effects.add(e);}options.add({...o,'costs':costs,'effects':effects});}
 result.add({'id':'template_${t['id']}','category':t['category'],'title':t['title'],'body':'${t['title']}: ${p['name']} $parameter. El alcance cambia costes y rendimientos.','conditions':t['conditions'],'trigger':'director','baseProbability':0.08,'repeatable':true,'cooldownDays':t['cooldownDays'],'options':options});}
 return result;
 }
 String _resource(String id)=>id=='fiber'?'textiles':id=='relics'?'crystal':id;
 bool _conditions(Society s,Map<String,dynamic> c){
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
 List<Map<String,dynamic>> eligibleEvents([String? societyId]){final s=world.society(societyId??world.controlledId);if(s==null||!s.alive)return [];return contentEvents.where((e){if(e['trigger']=='scheduled'&&!world.pending.any((p)=>p.type=='content_choice'&&p.societyId==s.id&&p.data['eventId']==e['id']))return false;if(e['family']!=null&&!world.extraordinary)return false;final key='${s.id}:${e['id']}';final last=world.contentHistory[key];if(last!=null&&(e['repeatable']!=true||world.day-last<(e['cooldownDays']??360)))return false;return _conditions(s,Map<String,dynamic>.from(e['conditions']??{}));}).toList();}
 Map<String,dynamic> _delegatedOption(Society s,List options){
 final affordable=options.where((raw){final o=raw as Map;return ((o['costs']??{}) as Map).entries.every((e)=>(s.resources[_resource(e.key.toString())]??0)>=(e.value as num));}).toList();if(affordable.isEmpty)return Map<String,dynamic>.from(options.last);
 if(s.risk>0.5)return Map<String,dynamic>.from(affordable.first);
 // A cautious council prefers affordable protective investments while keeping reserves.
 final first=Map<String,dynamic>.from(affordable.first);final costs=(first['costs']??{}) as Map;final food=(costs['food']??0) as num;if((s.resources['food']??0)-food>=math.min(s.policy.reserve,s.population*2))return first;return Map<String,dynamic>.from(affordable.last);
 }
 void _directContent(Society s){if(content==null||(s.id==world.controlledId&&!delegateDecisions)||!s.alive)return;final eligible=eligibleEvents(s.id);if(eligible.isEmpty)return;final candidates=eligible.where((event){double chance=((event['baseProbability']??0.1) as num).toDouble();for(final conditional in (event['conditionalProbability']??[]) as List){if(_conditions(s,Map<String,dynamic>.from(conditional['conditions']??{})))chance*=(conditional['multiplier'] as num).toDouble();}return world.random.nextDouble()<chance.clamp(0,1);}).toList();if(candidates.isEmpty)return;final e=candidates[world.random.nextInt(candidates.length)];final options=e['options'] as List;if(options.isEmpty)return;final option=_delegatedOption(s,options);resolveContentEvent(e['id'],option['id'],societyId:s.id,delegated:true);}
 CommandResult resolveContentEvent(String eventId,String optionId,{String? societyId,bool delegated=false,bool scheduled=false,String? cause}) {
 final s=world.society(societyId??world.controlledId);if(s==null||!s.alive)return const CommandResult(false,'No queda una comunidad capaz de decidir.');final es=contentEvents.where((e)=>e['id']==eventId);if(es.isEmpty)return const CommandResult(false,'Acontecimiento no encontrado.');final e=es.first;
 final queued=world.pending.where((p)=>p.type=='content_choice'&&p.societyId==s.id&&p.data['eventId']==eventId).toList();
 if(!scheduled&&queued.isEmpty&&!eligibleEvents(s.id).any((x)=>x['id']==eventId))return const CommandResult(false,'Las condiciones ya no se cumplen.');if(!_conditions(s,Map<String,dynamic>.from(e['conditions']??{})))return const CommandResult(false,'Consecuencia cancelada: el contexto cambió.');
 final options=(e['options'] as List).where((o)=>o['id']==optionId);if(options.isEmpty)return const CommandResult(false,'Opción desconocida.');final o=Map<String,dynamic>.from(options.first);final costs=(o['costs']??o['cost']??{}) as Map;final paid=<String,double>{};for(final entry in costs.entries){paid[_resource(entry.key.toString())]=(entry.value as num).toDouble();}if(!_pay(s,paid))return const CommandResult(false,'Recursos insuficientes para esta decisión.');
 if(eventId=='facility_found'){s.facilityChoice=optionId;s.flags.add('facility_committed');}world.pending.removeWhere((p)=>queued.contains(p));world.contentHistory['${s.id}:$eventId']=world.day;final h=record(s,e['title'], '${e['body']} ${delegated?'El consejo resolvió:':'Decisión:'} ${o['label']}',e['category'],cause:cause);
 for(final raw in (o['effects']??[]) as List){final effect=Map<String,dynamic>.from(raw);_applyContentEffect(s,effect,h.id);}
 for(final raw in (o['followUps']??[]) as List){final f=Map<String,dynamic>.from(raw);final probability=(f['probability']??1) as num;if(world.random.nextDouble()<probability){world.pending.add(ScheduledEvent(_id('e'),'content',s.id,world.day+math.max(1,(f['delayDays'] as num).toInt()),cause:h.id,data:{'eventId':f['eventId']}));}}
 world.validate();return CommandResult(true,'${e['title']}: ${o['label']}');
 }
 void _applyContentEffect(Society s,Map<String,dynamic> e,String cause){final rawValue=e['value']??e['amount']??0;final n=rawValue is num?rawValue.toDouble():0.0;switch(e['type']){
 case 'resource':final id=_resource(e['resource']);if(resourceIds.contains(id))s.resources[id]=(s.resources[id]!+n).clamp(0,100000).toDouble();break;
 case 'population':if(n<0){_removePeople(s,-n.toInt());}else{s.adults+=math.min(n.toInt(),math.max(0,s.housing-s.population));}break;
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
 void _resolveScheduledContent(Society s,ScheduledEvent event){final es=contentEvents.where((e)=>e['id']==event.data['eventId']);if(es.isEmpty){record(s,'Consecuencia cancelada','Su definición de contenido no está disponible.','contenido',cause:event.cause);return;}final e=es.first;if(e['family']!=null&&!world.extraordinary){record(s,'Escenario extraordinario omitido','Esta familia está desactivada en las reglas del mundo.','consecuencia',cause:event.cause);return;}if(!_conditions(s,Map<String,dynamic>.from(e['conditions']??{}))){record(s,'La historia cambia de curso','${e['title']}: ya no se cumplen sus condiciones.','consecuencia',cause:event.cause);return;}if(s.id==world.controlledId&&!delegateDecisions){world.pending.add(ScheduledEvent(_id('e'),'content_choice',s.id,world.day+3600000,cause:event.cause,data:event.data));record(s,e['title'],'Una decisión espera tu respuesta.','decisión',cause:event.cause);return;}final options=e['options'] as List;if(options.isEmpty)return;final option=_delegatedOption(s,options);final result=resolveContentEvent(e['id'],option['id'],societyId:s.id,scheduled:true,delegated:true,cause:event.cause);if(!result.ok)record(s,'Consecuencia aplazada sin efecto',result.message,'consecuencia',cause:event.cause);}
}
