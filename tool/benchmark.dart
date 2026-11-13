import 'dart:convert';
import 'dart:io';
import '../lib/simulation/engine.dart';
void main(){
 final pack=Map<String,dynamic>.from(jsonDecode(File('assets/content/core.json').readAsStringSync()));
 for(final size in [64,96]){
  final w=WorldState.generate(seed:73,size:size);w.controlledId=null;
  for(int i=w.societies.length;i<32;i++){
   int index=(i*127)%(size*size);while(!w.tiles[index].passable||w.societies.any((s)=>s.x==index%size&&s.y==index~/size)){index=(index+1)%(size*size);}
   final s=Society('bench$i','Puesto $i','cooperativa',index%size,index~/size);final leader=Person('benchLeader$i','Vera $i','dirigente',-30*360,traitNames[i%12]);s.people=[leader];s.leaderId=leader.id;s.ensureSites();w.societies.add(s);
  }
  w.validate();final e=Simulation(w)..registerContent(pack);final watch=Stopwatch()..start();final days=e.advanceDays(36000,delegateDecisions:true);watch.stop();w.validate();
  print(jsonEncode({'platform':Platform.operatingSystem,'dart':Platform.version,'map':size,'initialSettlements':32,'simulatedDays':days,'milliseconds':watch.elapsedMilliseconds,'rssBytes':ProcessInfo.currentRss,'livingSettlements':w.societies.where((s)=>s.alive).length,'historyEntries':w.chronicle.length,'pending':w.pending.length}));
 }
}
