import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import '../simulation/engine.dart';
import '../content/content_pack.dart';
import 'storage.dart';
import '../platform/document_exchange.dart';
import '../persistence/checkpoint.dart';
import 'world_game.dart';

class BarrioApp extends StatelessWidget {
  const BarrioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title:'Barrio Cero: Eras',debugShowCheckedModeBanner:false,
    theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,colorScheme:const ColorScheme.dark(primary:gold,secondary:moss,surface:ink),scaffoldBackgroundColor:ink,fontFamily:'sans-serif',
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size(44,46),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size(44,46),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)))),
      inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder(),isDense:true)),
    home:const ErasScreen());
}

// Worker commits complete daily transitions; the UI persists every batch before
// displaying it. A cancel preserves the last confirmed batch and never rewinds.
void historyWorker(Map<String,dynamic> args) async {
  final send=args['port'] as SendPort;
  final controls=ReceivePort();
  var cancel=false;
  Completer<void>? confirmation;
  controls.listen((m){if(m=='cancel'){cancel=true;}if((m=='ack'||m=='cancel') && confirmation!=null && !confirmation.isCompleted)confirmation.complete();});
  send.send({'control':controls.sendPort});
  try {
  final world=WorldState.fromJson(Map<String,dynamic>.from(args['world'] as Map));
  final sim=Simulation(world);
  if(args['content'] is Map)sim.registerContent(Map<String,dynamic>.from(args['content'] as Map));
  final target=args['target'] as int;
  final stop=args['stop'] as bool;
    while((world.toJson()['day'] as num).toInt()<target && !cancel) {
      final before=(world.toJson()['day'] as num).toInt();
      final days=(target-before).clamp(0,180).toInt();
      sim.advanceDays(days,stopOnCrisis:stop,delegateDecisions:!stop);
      final state=world.toJson();
      confirmation=Completer<void>();
      send.send({'world':state,'done':(state['day'] as num).toInt()>=target,'target':target});
      if((state['day'] as num).toInt()>=target){controls.close();return;}
      await confirmation.future;
      if((state['day'] as num).toInt()<before+days) break;
      await Future<void>.delayed(Duration.zero);
    }
    send.send({'world':world.toJson(),'done':true,'cancelled':cancel,'target':target});
  } catch(e) {send.send({'error':e.toString()});}
  controls.close();
}

class ErasScreen extends StatefulWidget {
  const ErasScreen({super.key});
  @override State<ErasScreen> createState()=>_ErasScreenState();
}
class _ErasScreenState extends State<ErasScreen> with WidgetsBindingObserver {
  WorldState? world;
  late WorldGame game;
  final store=SaveStore();
  final documents=DocumentExchange();
  Map<String,dynamic> state={};
  String? selected;
  int slot=0;
  Timer? timer;
  bool reduceMotion=false,sound=false,vibration=false,busy=false,stopCrisis=true,advancing=false;
  int speed=1;
  int? jumpTarget;
  int jumpStart=0;
  Map<String,dynamic>? jumpBefore;
  SendPort? jumpControl;
  Isolate? worker;
  bool webCancel=false;
  void _cancelJump(){webCancel=true;jumpControl?.send('cancel');}
  ReceivePort? results;
  Future<void> commitQueue=Future.value();
  Future<void> saveQueue=Future.value();
  late final Future<void> initialization;
  String note='';
  Map<String,dynamic>? core;
  String? coreHash;
  String? activeCoreSource;
  ContentPack? basePack;
  List<String> availablePackSources=[];
  List<String> activePackSources=[];
  Simulation _sim(){final value=Simulation(world!);if(core!=null)value.registerContent(core!);return value;}
  Future<void> _content()async{try{final text=await rootBundle.loadString('assets/content/core.json');final pack=ContentPack.parse(text);basePack=pack;activeCoreSource=text;core=Map<String,dynamic>.from(pack.data);coreHash=pack.hash;}catch(e){_message('No se pudo cargar el catálogo narrativo: $e');}}
  Offset gesturePan=Offset.zero;
  double gestureZoom=1;
  int get day=>number(state['day']);
  int number(dynamic v,[int fallback=0])=>v is num?v.toInt():fallback;
  List<Map<String,dynamic>> get societies=>(state['societies'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  Map<String,dynamic>? get society=>societies.where((s)=>s['id']==selected).firstOrNull;
  String get controlled=>'${state['controlledId'] ?? state['controlledSocietyId'] ?? ''}';
  String date(int d)=>'Año ${d~/360+1} · mes ${(d%360)~/30+1} · día ${d%30+1}';
  @override void initState(){
    super.initState();WidgetsBinding.instance.addObserver(this);
    game=WorldGame((id){setState(()=>selected=id);});
    initialization=_loadRegistry();
  }
  Future<void> _loadRegistry()async{
    await _content();
    try{final raw=await store.read('packages');if(raw!=null){final sources=(jsonDecode(raw) as List).cast<String>();if(sources.length>8)throw const FormatException('Demasiados paquetes');for(final text in sources){ContentPack.parse(text,base:basePack);}availablePackSources=sources;}}
    catch(_){availablePackSources=[];}
  }

  @override void dispose(){WidgetsBinding.instance.removeObserver(this);timer?.cancel();jumpControl?.send('cancel');results?.close();worker?.kill();super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState value){if(value!=AppLifecycleState.resumed){timer?.cancel();timer=null;if(busy){_cancelJump();}else if(!advancing){_save().catchError((Object error){_message('No se pudo guardar al pausar: $error');});}}}
  void refresh(){state=Map<String,dynamic>.from(world!.toJson());game.data=state;game.selected=selected;game.reduceMotion=reduceMotion;}
  Future<void> _save() async {
    if(world==null)return;
    final payload=_encode(world!.toJson(), target:jumpTarget);
    final destination='world_$slot';
    // SaveStore owns the single write queue. Delaying enqueue in a second
    // lifecycle-only queue lets an older autosave run after a newer import.
    saveQueue=store.write(destination,payload);
    await saveQueue;
  }
  String _encode(Map<String,dynamic> value,{int? target}) {
    final source=activeCoreSource;
    if(source==null)throw const FormatException('No hay contenido base confirmado.');
    return Checkpoint.create(world:WorldState.fromJson(value),coreSource:source,
      additionalSources:activePackSources,target:target,stopCrisis:stopCrisis,
      settings:{'reduceMotion':reduceMotion,'sound':sound,'vibration':vibration}).encode();
  }
  Future<void> _load({bool backup=false,int? fromSlot}) async {
    final sourceSlot=fromSlot??slot;
    await initialization;
    if(busy||advancing)return;
    timer?.cancel();timer=null;
    try{
      final raw=await store.read('world_$sourceSlot',backup:backup);
      if(raw==null){_message('No hay una partida en este espacio.');return;}
      await _import(raw,persist:false,destinationSlot:sourceSlot);
    }catch(e){if(!backup){final recovery=await store.read('world_$sourceSlot',backup:true);if(recovery!=null){try{await _import(recovery,persist:false,destinationSlot:sourceSlot);_message('Copia anterior recuperada; el archivo principal no era válido.');return;}catch(_){}}}_message('No se pudo cargar. Prueba Recuperar copia: $e');}
  }
  Future<void> _import(String raw,{bool persist=true,int? destinationSlot}) async {
    final targetSlot=destinationSlot??slot;
    if(targetSlot<0||targetSlot>2)throw const FormatException('Espacio de guardado inválido');
    await initialization;
    if(busy||advancing)throw StateError('Espera a que termine el avance actual.');
    timer?.cancel();timer=null;advancing=true;
    try{
    if(utf8.encode(raw).length>Checkpoint.maxBytes)throw const FormatException('Archivo demasiado grande');
    final envelope=jsonDecode(raw);
    final legacy=envelope is Map && envelope['version']==1;
    late final Checkpoint checkpoint;
    if(legacy){
      final installed=await rootBundle.loadString('assets/content/core.json');
      checkpoint=Checkpoint.migrateLegacy(raw,expectedCoreSource:installed);
      if(!mounted)return;
      final accept=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
        title:const Text('Actualizar guardado del prototipo'),
        content:const Text('Se conservará una copia del archivo original. El nuevo formato protege también el objetivo temporal, los ajustes y todo el contenido. Las reglas del mundo todavía conservan su versión actual.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Conservar copia y actualizar'))]));
      if(accept!=true)return;
      await store.write('legacy_$targetSlot',raw);
    }else{checkpoint=Checkpoint.decode(raw);}
    if(persist||legacy)await store.write('world_$targetSlot',checkpoint.encode());
    timer?.cancel();timer=null;
    if(!mounted)return;
    setState((){
      slot=targetSlot;world=checkpoint.world;core=checkpoint.content;basePack=checkpoint.basePack;
      coreHash=checkpoint.basePack.hash;activeCoreSource=checkpoint.coreSource;
      activePackSources=checkpoint.additionalSources.toList();
      reduceMotion=checkpoint.settings['reduceMotion']??false;
      sound=checkpoint.settings['sound']??false;vibration=checkpoint.settings['vibration']??false;
      selected=world!.controlledId??world!.societies.first.id;
      jumpTarget=checkpoint.target;stopCrisis=checkpoint.stopCrisis;refresh();
    });
    if(jumpTarget!=null && jumpTarget!>day)_message('Salto recuperado desde la fecha confirmada. Puedes continuarlo desde Años.');
    }finally{advancing=false;}
  }
  void _message(String text){if(!mounted)return;setState(()=>note=text);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text),behavior:SnackBarBehavior.floating,margin:const EdgeInsets.fromLTRB(12,0,12,80),duration:const Duration(seconds:4)));}
  Future<void> _newWorld() async {
    await initialization;
    if(busy||advancing||!mounted)return;
    timer?.cancel();timer=null;
    var seed='${DateTime.now().millisecondsSinceEpoch%100000}';
    String intensity='normal';int size=96;bool extraordinary=true;
    final create=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,change)=>AlertDialog(title:const Text('Un mundo por escribir'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Cada decisión deja memoria. El tiempo se detiene cuando cierras el juego.',style:TextStyle(color:earth)),const SizedBox(height:20),
      TextFormField(initialValue:seed,onChanged:(value)=>seed=value,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Semilla reproducible')),
      const SizedBox(height:12),DropdownButtonFormField<String>(isExpanded:true,initialValue:intensity,decoration:const InputDecoration(labelText:'Intensidad'),items:const [DropdownMenuItem(value:'normal',child:Text('Normal')),DropdownMenuItem(value:'caótica',child:Text('Caótica')),DropdownMenuItem(value:'extrema',child:Text('Extrema'))],onChanged:(v)=>change(()=>intensity=v!)),
      const SizedBox(height:12),DropdownButtonFormField<int>(isExpanded:true,initialValue:size,decoration:const InputDecoration(labelText:'Mapa'),items:const [DropdownMenuItem(value:64,child:Text('Pequeño · 64 × 64')),DropdownMenuItem(value:96,child:Text('Normal · 96 × 96'))],onChanged:(v)=>change(()=>size=v!)),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Familias extraordinarias'),subtitle:const Text('Contacto, máquinas y transformaciones'),value:extraordinary,onChanged:(v)=>change(()=>extraordinary=v)),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Volver')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Fundar Barrio Cero'))])));
    if(create!=true)return;
    advancing=true;
    try{
      final source=await rootBundle.loadString('assets/content/core.json');
      final candidate=WorldState.generate(seed:int.tryParse(seed)??42,size:size,intensity:intensity,extraordinary:extraordinary);
      final checkpoint=Checkpoint.create(world:candidate,coreSource:source,
        additionalSources:availablePackSources,settings:{'reduceMotion':reduceMotion,'sound':sound,'vibration':vibration});
      await store.write('world_$slot',checkpoint.encode());
      if(!mounted)return;
      setState((){world=checkpoint.world;core=checkpoint.content;basePack=checkpoint.basePack;
        activeCoreSource=checkpoint.coreSource;coreHash=checkpoint.basePack.hash;
        activePackSources=checkpoint.additionalSources.toList();selected=world!.controlledId;
        game.pan=Offset.zero;game.zoom=1;game.mode='Mundo';jumpTarget=null;
        note='Toca Barrio Cero, ordena una construcción y avanza un mes.';refresh();});
    }catch(e){_message('No se pudo crear el mundo: $e');}finally{advancing=false;}
  }
  Future<void> _command(String action,{String? target,String? choice}) async {
    if(busy||world==null||advancing)return;
    if(!['control','delegate'].contains(action) && selected!=controlled){_message('Asume la dirección de esta comunidad desde su ficha para darle órdenes.');return;}
    advancing=true;
    try{
      final candidate=WorldState.fromJson(world!.toJson());final sim=Simulation(candidate);if(core!=null)sim.registerContent(core!);
      final result=sim.submit(Command(id:'ui-${candidate.day}-${candidate.commandReceipts.length}',action:action,actorId:candidate.controlledId,issuedDay:candidate.day,target:target,choice:choice));
      if(!result.ok){_message(result.message);return;}
      await store.write('world_$slot',_encode(candidate.toJson(),target:jumpTarget));world=candidate;
      setState((){refresh();if(action=='control'){selected=controlled;game.selected=selected;}});
      if(vibration)HapticFeedback.lightImpact();
      if(sound && result.ok==true)SystemSound.play(SystemSoundType.click);
      _message(result.message);
    }catch(e){_message('La orden no pudo aplicarse: $e');}finally{advancing=false;}
  }
  Future<void> _advance(int days) async {
    if(busy||world==null||advancing)return;
    advancing=true;
    try{final candidate=WorldState.fromJson(world!.toJson());final sim=Simulation(candidate);if(core!=null)sim.registerContent(core!);sim.advanceDays(days,stopOnCrisis:stopCrisis);final nextTarget=jumpTarget!=null&&candidate.day>=jumpTarget!?null:jumpTarget;await store.write('world_$slot',_encode(candidate.toJson(),target:nextTarget));world=candidate;jumpTarget=nextTarget;setState(refresh);}catch(e){timer?.cancel();timer=null;_message('Simulación detenida: $e');}finally{advancing=false;}
  }
  void _play(){if(timer!=null){timer!.cancel();setState(()=>timer=null);}else{timer=Timer.periodic(Duration(milliseconds:1200~/speed),(t){_advance(1);});setState((){});}}
  Future<void> _jump(int years,{bool resume=false}) async {
    if(advancing||busy){_message('Espera a que se confirme el avance actual.');return;}
    setState(()=>busy=true);webCancel=false;
    timer?.cancel();timer=null;
    jumpBefore=Map<String,dynamic>.from(state);
    jumpStart=day;
    final requestedTarget=resume?jumpTarget:day+years*360;
    if(requestedTarget==null||requestedTarget<=day){setState(()=>busy=false);return;}
    try{
      if(!resume)await store.write('branch_$slot',_encode(world!.toJson()));
      await store.write('world_$slot',_encode(world!.toJson(),target:requestedTarget));
      jumpTarget=requestedTarget;
    }catch(error){
      if(mounted)setState(()=>busy=false);
      _message('No se pudo preparar el salto: $error. La historia no ha avanzado.');
      return;
    }
    if(!mounted)return;
    if(webCancel){setState(()=>busy=false);return;}
    if(kIsWeb){await _jumpWeb();return;}
    results=ReceivePort();
    results!.listen((dynamic message){
      commitQueue=commitQueue.then((_)async{
        final m=Map<String,dynamic>.from(message as Map);
        if(m['control']!=null){jumpControl=m['control'] as SendPort;if(webCancel)jumpControl?.send('cancel');return;}
        if(m['error']!=null){results?.close();results=null;jumpControl=null;worker?.kill();setState(()=>busy=false);_message('Salto detenido: ${m['error']}');return;}
        if(m['world']!=null){
          final candidate=WorldState.fromJson(Map<String,dynamic>.from(m['world'] as Map));
          final done=m['done']==true;
          final target=done && number((m['world'] as Map)['day'])>=(jumpTarget??day)?null:jumpTarget;
          await store.write('world_$slot',_encode(candidate.toJson(),target:target));
          world=candidate;jumpTarget=target;
          if(mounted)setState((){refresh();busy=!done;});
          if(!done)jumpControl?.send('ack');
          if(done){results?.close();results=null;jumpControl=null;_jumpReport(m['cancelled']==true);}
        }
      }).catchError((Object error){jumpControl?.send('cancel');results?.close();results=null;worker?.kill();if(mounted)setState(()=>busy=false);_message('No se confirmó el último lote: $error. Se conserva la fecha guardada.');});
    });
    try{worker=await Isolate.spawn(historyWorker,{'port':results!.sendPort,'world':world!.toJson(),'target':jumpTarget!,'stop':stopCrisis,'content':core});}catch(e){results?.close();results=null;setState(()=>busy=false);_message('No se pudo iniciar el trabajador: $e');}
  }
  Future<void> _jumpWeb()async{
    // Browser preview lacks Dart isolates. Yield between exact daily batches;
    // Android always uses the isolate worker above.
    try{
      while(jumpTarget!=null && day<jumpTarget! && !webCancel){
        final candidate=WorldState.fromJson(world!.toJson());final sim=Simulation(candidate);if(core!=null)sim.registerContent(core!);
        final days=(jumpTarget!-day).clamp(0,180).toInt();
        final advanced=sim.advanceDays(days,stopOnCrisis:stopCrisis,delegateDecisions:!stopCrisis);
        final target=candidate.day>=jumpTarget!?null:jumpTarget;
        await store.write('world_$slot',_encode(candidate.toJson(),target:target));
        world=candidate;jumpTarget=target;setState(refresh);
        if(advanced<days)break;
        await Future<void>.delayed(const Duration(milliseconds:1));
      }
      setState(()=>busy=false);_jumpReport(webCancel);
    }catch(e){setState(()=>busy=false);_message('No se confirmó el avance: $e');}
  }
  void _jumpReport(bool cancelled){
    final before=jumpBefore??{};
    int pop(Map<String,dynamic> d)=>(d['societies'] as List? ?? []).fold<int>(0,(n,s)=>n+number(s['population']));
    showDialog<void>(context:context,builder:(context)=>AlertDialog(title:Text(cancelled?'Historia pausada':'Una nueva era'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${date(jumpStart)} → ${date(day)}'),const SizedBox(height:16),Text('Población mundial: ${pop(before)} → ${pop(state)}'),Text('Sociedades: ${(before['societies'] as List? ?? []).length} → ${societies.length}'),Text('Tecnologías: ${_totalTech(before)} → ${_totalTech(state)}'),Text('Daño ambiental medio: ${_environment(before).toStringAsFixed(1)} → ${_environment(state).toStringAsFixed(1)}'),Text('Pactos y tensiones: ${_relations(before)} → ${_relations(state)}'),const SizedBox(height:12),...((state['chronicle'] as List? ?? []).where((e)=>number(e['day'])>jumpStart).toList().reversed.take(3).map((e)=>Text('• ${e['title']}',style:const TextStyle(fontSize:11,color:earth)))),const SizedBox(height:16),const Text('La crónica conserva las causas de los cambios. Cancelar conserva todo el periodo confirmado.')])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Volver al mundo')),FilledButton(onPressed:(){Navigator.pop(context);_chronicle();},child:const Text('Leer crónica'))]));
  }
  int _totalTech(Map<String,dynamic> data)=>(data['societies'] as List? ?? []).fold<int>(0,(n,s)=>n+(s['tech'] as List? ?? []).length);
  double _environment(Map<String,dynamic> data){final list=data['societies'] as List? ?? [];return list.isEmpty?0:list.fold<double>(0,(n,s)=>n+(s['environment'] as num? ?? 0).toDouble())/list.length;}
  String _relations(Map<String,dynamic> data){var good=0,bad=0;for(final s in data['societies'] as List? ?? []){for(final value in (s['relations'] as Map? ?? {}).values){if(number(value)>30)good++;if(number(value)<-30)bad++;}}return '${good~/2} amistades / ${bad~/2} rivalidades';}
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:world==null?_welcome():_world()));
  Widget _welcome()=>Center(child:SingleChildScrollView(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('CRÓNICAS DE UN PLANETA',textAlign:TextAlign.center,style:TextStyle(color:earth,fontSize:11,letterSpacing:3)),const SizedBox(height:12),
    const Text('BARRIO\nCERO',textAlign:TextAlign.center,style:TextStyle(color:gold,fontWeight:FontWeight.w900,fontSize:64,height:.95,letterSpacing:2)),
    const Text('E R A S',textAlign:TextAlign.center,style:TextStyle(color:moss,fontWeight:FontWeight.w600,fontSize:22,height:2)),const SizedBox(height:28),
    const Text('De un pequeño barrio al legado de siglos.\nConstruye. Decide. Observa lo que permanece.',textAlign:TextAlign.center,style:TextStyle(color:earth,height:1.6)),const SizedBox(height:32),
    FilledButton(onPressed:_newWorld,child:const Text('CREAR UN MUNDO')),const SizedBox(height:10),OutlinedButton(onPressed:_load,child:const Text('Continuar historia')),
    const SizedBox(height:12),Wrap(alignment:WrapAlignment.center,crossAxisAlignment:WrapCrossAlignment.center,children:[const Text('Espacio de guardado  '),DropdownButton<int>(value:slot,items:List.generate(3,(i)=>DropdownMenuItem(value:i,child:Text('${i+1}'))),onChanged:(v)=>setState(()=>slot=v!))]),
    TextButton(onPressed:_archive,child:const Text('Importar / recuperar partida')),
    if(kIsWeb)const Text('Vista web: guardado temporal. Exporta tu partida antes de cerrar.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:earth)),
    const SizedBox(height:22),const Text('Sin conexión · Sin cuentas · Tu historia',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:moss)),
  ]))))) ;
  Widget _world()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(14,10,8,6),child:Row(children:[const Text('BARRIO CERO',style:TextStyle(color:gold,fontWeight:FontWeight.w900,letterSpacing:1.4,fontSize:16)),const Spacer(),TextButton(onPressed:busy||advancing?null:_menu,child:const Text('MENÚ'))])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:Row(children:[Text(date(day),style:const TextStyle(fontSize:11,color:earth)),const Spacer(),Flexible(child:Text(controlled.isEmpty?'Observando el mundo':'Guías: ${societies.where((s)=>s['id']==controlled).firstOrNull?['name']??controlled}',overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:moss)))])),
    const SizedBox(height:8),
    Expanded(child:Stack(children:[
      Positioned.fill(child:GestureDetector(onScaleStart:(d){gesturePan=game.pan;gestureZoom=game.zoom;},onScaleUpdate:(d){game.pan=gesturePan+d.focalPointDelta;gesturePan=game.pan;game.zoom=(gestureZoom*d.scale).clamp(.6,9).toDouble();},onTapUp:(d)=>game.touch(d.localPosition),child:GameWidget(game:game))),
      Positioned(left:10,bottom:10,child:Container(decoration:BoxDecoration(color:ink.withValues(alpha:.95),borderRadius:BorderRadius.circular(6)),child:Row(mainAxisSize:MainAxisSize.min,children:['Mundo','Región','Asentamiento'].map((m)=>TextButton(style:TextButton.styleFrom(foregroundColor:game.mode==m?gold:earth,padding:const EdgeInsets.symmetric(horizontal:10)),onPressed:(){setState((){game.mode=m;game.zoom=m=='Región'?3:1;if(selected!=null)game.locate(selected!);});},child:Text(m,style:const TextStyle(fontSize:11)))).toList()))),
      Positioned(right:10,top:94,child:Column(children:[_mapButton('+',()=>game.zoom=(game.zoom*1.4).clamp(.6,9).toDouble()),_mapButton('−',()=>game.zoom=(game.zoom/1.4).clamp(.6,9).toDouble()),_mapButton('◎',(){if(selected!=null)game.locate(selected!);}),_mapButton('▣',()=>game.mini=!game.mini)])),
      Positioned(left:10,top:35,child:DropdownButton<String>(value:game.filter,dropdownColor:ink,style:const TextStyle(fontSize:10,color:gold),underline:const SizedBox(),items:['Territorios','Población','Recursos','Conflictos','Entorno'].map((f)=>DropdownMenuItem(value:f,child:Text(f))).toList(),onChanged:(v)=>setState(()=>game.filter=v!))),
    ])),
    if(busy)Padding(padding:const EdgeInsets.all(10),child:Column(children:[LinearProgressIndicator(value:jumpTarget==null?null:((day-jumpStart)/(jumpTarget!-jumpStart)).clamp(0.0,1.0).toDouble()),Row(children:[Expanded(child:Text('Procesando historia · ${date(day)}',style:const TextStyle(fontSize:11))),TextButton(onPressed:_cancelJump,child:const Text('Pausar salto'))])])),
    _selection(),
    if(world!.extinct)Padding(padding:const EdgeInsets.all(10),child:Text('No queda población capaz de actuar. Inspecciona el legado o crea otro mundo desde el menú.',style:const TextStyle(color:gold,fontSize:12))),
    if(note.isNotEmpty)Padding(padding:const EdgeInsets.fromLTRB(14,0,14,4),child:Text(note,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:earth))),
    Container(color:const Color(0xff253235),padding:const EdgeInsets.fromLTRB(8,5,8,8),child:Row(children:[
      Expanded(child:TextButton(style:TextButton.styleFrom(padding:EdgeInsets.zero,minimumSize:const Size(44,48)),onPressed:busy?null:_play,child:Icon(timer==null?Icons.play_arrow:Icons.pause))),
      Expanded(child:TextButton(style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:4),minimumSize:const Size(44,48)),onPressed:busy?null:()=>_advance(1),child:const Text('+ Día',style:TextStyle(fontSize:12)))),
      Expanded(child:TextButton(style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:4),minimumSize:const Size(44,48)),onPressed:busy?null:()=>_advance(30),child:const Text('+ Mes',style:TextStyle(fontSize:12)))),
      Expanded(child:FilledButton(style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:4),minimumSize:const Size(44,48)),onPressed:busy?null:_years,child:const Text('Años',maxLines:1,style:TextStyle(fontSize:12)))),
      Expanded(child:TextButton(style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:4),minimumSize:const Size(44,48)),onPressed:_chronicle,child:const Text('Crónica',maxLines:1,style:TextStyle(fontSize:12)))),
    ])),
  ]);
  Widget _mapButton(String label,VoidCallback tap)=>SizedBox(width:40,height:40,child:TextButton(style:TextButton.styleFrom(backgroundColor:ink.withValues(alpha:.85),padding:EdgeInsets.zero),onPressed:tap,child:Text(label)));
  Widget _selection(){
    final s=society;if(s==null)return Padding(padding:const EdgeInsets.all(14),child:Text('Toca una comunidad para descubrir su historia.',style:TextStyle(color:earth)));
    final resources=s['resources'] as Map? ?? {};
    return Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(14,10,14,8),decoration:const BoxDecoration(border:Border(top:BorderSide(color:Color(0xff47514b)))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('${s['name']}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17))),Text('${number(s['population'])} hab.',style:const TextStyle(color:moss,fontSize:12)),const SizedBox(width:12),TextButton(onPressed:()=>_details(s),child:const Text('Ficha'))]),
      Text('Alimento ${number(resources['food'])} · Madera ${number(resources['wood'])} · Salud ${number(s['health'],100)}%',style:const TextStyle(fontSize:11,color:earth)),
      const SizedBox(height:6),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_action('Construir',_build),_action('Investigar',_research),_action('Explorar',()=>_command('explore')),_action('Instalación',_facility),_action('Decisiones',_stories),_action('Diplomacia',_diplomacy),_action('Políticas',_policies),_action('Reparar',()=>_command('repair'))])),
    ]));
  }
  Widget _action(String text,VoidCallback callback)=>Padding(padding:const EdgeInsets.only(right:6),child:OutlinedButton(style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:12),minimumSize:const Size(44,42)),onPressed:busy?null:callback,child:Text(text,style:const TextStyle(fontSize:11))));
  Future<void> _sheet(String title,List<Widget> children)=>showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(context)=>SafeArea(child:ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(context).height*.82),child:ListView(shrinkWrap:true,padding:const EdgeInsets.fromLTRB(20,0,20,24),children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:gold)),const SizedBox(height:18),...children]))));
  void _details(Map<String,dynamic> s){
    _sheet('${s['name']}',[
      Text('Localización (${s['x']}, ${s['y']}) · Identidad ${s['id']}'),const SizedBox(height:14),
      ...s.entries.where((e)=>!['id','name','x','y'].contains(e.key)).map((e)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Text('${_label(e.key)}: ${_readable(e.value)}',style:const TextStyle(fontSize:12,color:earth)))),
      FilledButton(onPressed:(){Navigator.pop(context);_command('control',target:s['id'].toString());},child:const Text('Asumir dirección de esta comunidad')),
    ]);
  }
  String _label(String key)=>{'resources':'Reservas','population':'Población','health':'Salud','buildings':'Edificios','technologies':'Conocimientos','characters':'Personajes','relations':'Relaciones','policies':'Políticas','profile':'Perfil','tasks':'Proyectos','food':'Alimento','wood':'Madera','stone':'Piedra','metal':'Metal','medicine':'Medicina','energy':'Energía','knowledge':'Conocimiento'}[key]??key;
  String _readable(dynamic v){if(v is Map)return v.entries.map((e)=>'${_label(e.key.toString())}: ${_readable(e.value)}').join(' · ');if(v is List)return v.map(_readable).join(', ');return '$v';}
  void _build()=>_sheet('Construir con propósito',[
    const Text('Los recursos y el trabajo se reservan al ordenar. Los edificios aparecen al completarse.',style:TextStyle(color:earth)),const SizedBox(height:12),
    ...buildings.map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.name),subtitle:Text('${e.description}\n${e.cost.entries.map((c)=>"${_label(c.key)} ${c.value.toInt()}").join(" · ")} · ${e.days} días${e.technology==null?"":" · Requiere ${e.technology}"}',style:const TextStyle(fontSize:11)),trailing:const Text('Ordenar',style:TextStyle(color:gold)),onTap:(){Navigator.pop(context);_command('build',target:e.id);})),
  ]);
  void _research()=>_sheet('Conocimiento heredado',[
    const Text('Las tecnologías necesitan recursos, tiempo y conocimientos anteriores.',style:TextStyle(color:earth)),const SizedBox(height:12),
    ...technologies.map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.name),subtitle:Text('${e.effect} · ${e.cost.toInt()} conocimiento\nRequisitos: ${e.requires.isEmpty?"ninguno":e.requires.join(", ")}',style:const TextStyle(color:earth,fontSize:10)),onTap:(){Navigator.pop(context);_command('research',target:e.id);})),
  ]);
  Future<void> _resolveStory(String event,String option)async{
    if(advancing||busy||selected!=controlled)return;
    advancing=true;
    try{final candidate=WorldState.fromJson(world!.toJson());final sim=Simulation(candidate);if(core!=null)sim.registerContent(core!);final result=sim.submit(Command(id:'ui-${candidate.day}-${candidate.commandReceipts.length}',action:'resolve_event',actorId:candidate.controlledId,issuedDay:candidate.day,target:event,choice:option));if(result.ok){await store.write('world_$slot',_encode(candidate.toJson(),target:jumpTarget));world=candidate;setState(refresh);}_message(result.message);}catch(e){_message('No se pudo confirmar la decisión: $e');}finally{advancing=false;}
  }
  void _stories(){
    if(selected!=controlled){_message('Asume la dirección desde la ficha antes de resolver sus decisiones.');return;}
    final events=_sim().eligibleEvents(selected).take(8).toList();
    _sheet('Decisiones de la comunidad',[
      if(events.isEmpty)const Text('No hay decisiones compatibles ahora. Explora, construye y deja pasar el tiempo.',style:TextStyle(color:earth)),
      ...events.map((e)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${e['title']??e['id']}',style:const TextStyle(fontSize:17,color:gold,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('${e['body']??e['text']??e['description']??''}',style:const TextStyle(color:earth)),const SizedBox(height:12),
        ...(e['options'] as List? ?? []).map((dynamic o)=>Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(onPressed:()async{Navigator.pop(context);await _resolveStory(e['id'],o['id']);},child:Text('${o['label']??o['text']??o['id']}')))),
      ])))),
    ]);
  }
  void _facility()=>_sheet('La instalación antigua',[
    const Text('Leo ha señalado una estructura bajo las ruinas. Su destino puede transformar la comunidad. Explora primero si aún no la has descubierto.',style:TextStyle(color:earth,height:1.5)),const SizedBox(height:16),
    ...{'seal':('Sellar','Aislar el riesgo y conservar el secreto.'),'salvage':('Desmontar','Recuperar materiales; perder el conocimiento interior.'),'study':('Estudiar','Invertir en ciencia. Energía, accidente o señal.'),'share':('Ofrecer acceso','Compartir el hallazgo con otra sociedad.')}.entries.map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.value.$1),subtitle:Text(e.value.$2),onTap:(){Navigator.pop(context);_command('facility',choice:e.key);})),
  ]);
  void _diplomacy()=>_sheet('Más allá del barrio',[
    ...societies.where((s)=>s['id']!=selected).map((s)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${s['name']}',style:const TextStyle(fontWeight:FontWeight.bold)),Text('${number(s['population'])} habitantes · ${s['profile']??'Comunidad autónoma'}',style:const TextStyle(color:earth,fontSize:11)),Row(children:[TextButton(onPressed:(){Navigator.pop(context);_command('trade',target:s['id'].toString());},child:const Text('Abrir comercio')),TextButton(onPressed:(){Navigator.pop(context);_command('diplomacy',target:s['id'].toString());},child:const Text('Negociar'))])])))),
  ]);
  void _policies(){
    _sheet('Gobernar a largo plazo',[
      const Text('Las prioridades guían las decisiones autónomas. Cambiar de sociedad conserva sus recursos y sus compromisos.',style:TextStyle(color:earth)),const SizedBox(height:14),
      ...{'balanced':'Equilibrio','food':'Reservas y alimentación','science':'Investigación','expansion':'Expansión','trade':'Cooperación comercial','defense':'Protección','isolation':'Aislamiento'}.entries.map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(e.value),onTap:(){Navigator.pop(context);_command('policy',target:e.key);})),
      OutlinedButton(onPressed:(){Navigator.pop(context);_command('delegate');},child:const Text('Delegar todas y observar')),
    ]);
  }
  void _years()=>_sheet('Observar una era',[
    StatefulBuilder(builder:(context,change)=>SwitchListTile(contentPadding:EdgeInsets.zero,value:stopCrisis,onChanged:(v){change(()=>stopCrisis=v);setState((){});},title:const Text('Detener ante crisis'),subtitle:Text(stopCrisis?'Las decisiones importantes interrumpen el salto.':'Los dirigentes aplican sus políticas y registran sus decisiones.'))),
    const SizedBox(height:12),const Text('Se guardará un punto anterior. El avance usa las mismas reglas diarias. Pausar conserva los días ya confirmados.',style:TextStyle(color:earth,height:1.5)),const SizedBox(height:18),
    ...[1,10,100].map((years)=>Padding(padding:const EdgeInsets.only(bottom:8),child:FilledButton(onPressed:(){Navigator.pop(context);_jump(years);},child:Text('Avanzar $years ${years==1?'año':'años'}')))),
    if(jumpTarget!=null && jumpTarget!>day)OutlinedButton(onPressed:(){Navigator.pop(context);_jump(0,resume:true);},child:Text('Continuar hasta ${date(jumpTarget!)}')),
  ]);
  void _chronicle(){
    final entries=(state['chronicle'] as List? ?? []).reversed.take(180).toList();
    _sheet('La memoria del mundo',[
      Text('${entries.length} noticias recientes · Toca una noticia para localizar su comunidad.',style:const TextStyle(color:earth,fontSize:11)),const SizedBox(height:12),
      ...entries.map((dynamic e){final m=e is Map?e:{};final id=(m['societyId']??m['location']??m['society'])?.toString();return ListTile(contentPadding:EdgeInsets.zero,title:Text('${m['title']??m['text']??m['message']??e}',style:const TextStyle(fontSize:13)),subtitle:Text('${date(number(m['day']))}\n${m['text']??m['description']??m['detail']??''}${m['cause']==null?'':' · Causa: ${m['cause']}'}',style:const TextStyle(fontSize:10,color:earth)),onTap:(){if(id!=null){setState(()=>selected=id);game.locate(id);}Navigator.pop(context);});}),
      if(entries.isEmpty)const Text('La historia empieza con tus primeras decisiones.'),
    ]);
  }
  void _menu(){if(busy||advancing){_message('Pausa el salto antes de cambiar de partida o configuración.');return;}_sheet('Tu mundo, tus reglas',[
    ListTile(title:const Text('Guardar ahora'),onTap:()async{Navigator.pop(context);if(advancing||busy)return;advancing=true;try{await _save();_message('Partida guardada.');}catch(error){_message('No se pudo guardar: $error');}finally{advancing=false;}}),
    ListTile(title:const Text('Paquetes de contenido'),onTap:(){Navigator.pop(context);_packages();}),
    ListTile(title:const Text('Archivo de mundos'),onTap:(){Navigator.pop(context);_archive();}),
    ListTile(title:const Text('Restaurar punto anterior al salto'),subtitle:const Text('Reemplaza este mundo por su rama anterior.'),onTap:()async{Navigator.pop(context);final raw=await store.read('branch_$slot');if(raw!=null) {
      await _import(raw);
    } else {
      _message('No hay un punto anterior.');
    }}),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Reducir movimiento'),value:reduceMotion,onChanged:(v){setState(()=>reduceMotion=v);game.reduceMotion=v;Navigator.pop(context);}),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Sonido de decisiones'),value:sound,onChanged:(v){setState(()=>sound=v);Navigator.pop(context);}),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Respuesta táctil'),value:vibration,onChanged:(v){setState(()=>vibration=v);Navigator.pop(context);}),
    ListTile(title:const Text('Velocidad automática'),subtitle:Text('$speed×'),onTap:(){setState(()=>speed=speed==1?2:speed==2?4:1);if(timer!=null){timer!.cancel();timer=null;_play();}Navigator.pop(context);}),
    ListTile(title:const Text('Cómo empezar'),onTap:(){Navigator.pop(context);_sheet('Tus primeras decisiones',[const Text('1. Toca Barrio Cero y abre su ficha.\n2. Construye un huerto o una vivienda.\n3. Avanza un mes para ver el trabajo completado.\n4. Explora y decide qué hacer con la instalación.\n5. Negocia con otra comunidad.\n6. Revisa políticas y avanza un año.\n\nAna mantiene los conocimientos, Leo explora y Tito cuida las reservas. El calendario tiene 12 meses de 30 días. La cámara no cambia la historia.',style:TextStyle(height:1.8,color:earth))]);}),
    ListTile(title:const Text('Crear otro mundo'),onTap:(){Navigator.pop(context);_newWorld();}),
    ListTile(title:const Text('Volver al inicio'),onTap:()async{Navigator.pop(context);await _save();timer?.cancel();timer=null;setState(()=>world=null);}),
  ]);}
  void _packages()=>_sheet('Contenido versionado',[
    Text('Base: barrio.core 1.0.0\nSHA-256: ${coreHash??"cargando"}',style:const TextStyle(fontSize:10,color:earth)),const SizedBox(height:12),
    const Text('Importar agrega contenido para los próximos mundos. La historia actual conserva su conjunto exacto; no se migra automáticamente.',style:TextStyle(color:earth,height:1.5)),
    ...availablePackSources.map((source){final p=ContentPack.parse(source,base:basePack);return ListTile(contentPadding:EdgeInsets.zero,title:Text('${p.id} ${p.version}'),subtitle:Text(p.hash,style:const TextStyle(fontSize:9)));}),
    const SizedBox(height:16),FilledButton(onPressed:()async{
      Navigator.pop(context);final input=TextEditingController();
      final accept=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Importar paquete'),content:TextField(controller:input,minLines:5,maxLines:10,decoration:const InputDecoration(labelText:'JSON declarativo del paquete')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Validar'))]));
      if(accept==true){try{final pack=ContentPack.parse(input.text,base:basePack);if(availablePackSources.length>=8)throw const FormatException('Límite de 8 paquetes');if(availablePackSources.any((text)=>ContentPack.parse(text,base:basePack).id==pack.id))throw const FormatException('Identidad ya importada');availablePackSources.add(input.text);await store.write('packages',jsonEncode(availablePackSources));_message('Paquete validado. Se aplicará al crear un nuevo mundo.');}catch(e){_message('Paquete rechazado: $e');}}
    },child:const Text('Importar paquete JSON')),
  ]);
  void _archive({int? chosenSlot}){
    final selectedSlot=chosenSlot??slot;
    final duplicateSlot=selectedSlot==slot?(slot+1)%3:selectedSlot;
    _sheet('Archivo de mundos',[
    Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[const Text('Espacio elegido: '),DropdownButton<int>(value:selectedSlot,items:List.generate(3,(i)=>DropdownMenuItem(value:i,child:Text('${i+1}'))),onChanged:(v){Navigator.pop(context);_archive(chosenSlot:v);})]),
    FilledButton(onPressed:(){Navigator.pop(context);_load(fromSlot:selectedSlot);},child:const Text('Cargar este espacio')),const SizedBox(height:8),
    OutlinedButton(onPressed:(){Navigator.pop(context);_load(backup:true,fromSlot:selectedSlot);},child:const Text('Recuperar copia anterior')),const SizedBox(height:8),
    if(world!=null)...[
      OutlinedButton(onPressed:()async{final destination=duplicateSlot;await store.write('world_$destination',_encode(world!.toJson()));if(mounted){Navigator.pop(context);_message('Mundo duplicado en espacio ${destination+1}.');}},child:Text('Duplicar en espacio ${duplicateSlot+1}')),
      const SizedBox(height:8),OutlinedButton(onPressed:(){Navigator.pop(context);_export();},child:const Text('Exportar partida (JSON)')),
    ],
    const SizedBox(height:8),OutlinedButton(onPressed:(){Navigator.pop(context);_importDialog(destinationSlot:selectedSlot);},child:const Text('Importar partida (JSON)')),
    if(kIsWeb)const Padding(padding:EdgeInsets.only(top:10),child:Text('En esta previsualización el almacenamiento es temporal. Android conserva archivos locales al cerrar.',style:TextStyle(color:earth,fontSize:11))),
  ]);}
  Future<void> _export() async {
    if(advancing||busy){_message('Espera a que se confirme el avance actual.');return;}
    final data=_encode(world!.toJson(),target:jumpTarget);
    if(documents.supported){try{final uri=await documents.exportDocument(text:data,suggestedName:'barrio-cero-$slot-dia-$day.json');if(uri!=null)_message('Partida exportada al documento elegido.');}catch(e){_message('No se pudo exportar: $e');}return;}
    _sheet('Exportar historia',[
      const Text('Copia el JSON y guárdalo en un archivo .json. Permite trasladar el mundo sin cuentas ni conexión.',style:TextStyle(color:earth)),const SizedBox(height:12),
      FilledButton(onPressed:(){Clipboard.setData(ClipboardData(text:data));_message('Partida copiada al portapapeles.');},child:const Text('Copiar partida completa')),
      const SizedBox(height:12),SelectableText('${data.substring(0,data.length.clamp(0,800).toInt())}…',style:const TextStyle(fontSize:10)),
    ]);
  }
  Future<void> _importDialog({int? destinationSlot})async{
    if(advancing||busy){_message('Pausa el avance antes de importar.');return;}
    timer?.cancel();timer=null;
    if(documents.supported){try{final raw=await documents.importDocument();if(raw!=null){await _import(raw,destinationSlot:destinationSlot);_message('Historia importada.');}}catch(e){_message('Importación rechazada; la partida actual se conserva. $e');}return;}
    final input=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Importar historia'),content:TextField(controller:input,minLines:5,maxLines:10,decoration:const InputDecoration(labelText:'Pega el contenido del archivo JSON')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Validar e importar'))]));
    if(ok==true){try{await _import(input.text,destinationSlot:destinationSlot);_message('Historia importada.');}catch(e){_message('Importación rechazada; la partida actual se conserva. $e');}}
  }
}
