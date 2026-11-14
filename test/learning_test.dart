import 'dart:convert';
import '../tool/fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main(){
  WorldState world()=>WorldState.generate(size:64,origin:'prehistory',seed:27);
  Command order(WorldState w,String id,{String action='train',String? target='resident',String? choice='craft'})=>Command(id:id,action:action,actorId:w.controlledId,issuedDay:w.day,target:target,choice:choice);
  void provision(WorldState w){for(final s in w.societies){s.policy.expansion=false;s.resources['food']=10000;s.resources['water']=10000;s.resources['knowledge']=100;}}
  test('Preview leaves the world and RNG intact, training uses a real resident',(){
    final w=world();provision(w);final sim=Simulation(w);final cmd=order(w,'craft');final before=w.canonical();final total=w.populationState!.total;
    final preview=sim.preview(cmd);expect(preview.allowed,isTrue,reason:preview.reason);expect(preview.workers,2);expect(preview.durationDays,90);expect(w.canonical(),before);
    final result=sim.submit(cmd);expect(result.ok,isTrue,reason:result.message);expect(w.populationState!.total,total);
    final s=w.controlled,lesson=s.lessons.single,learner=s.people.firstWhere((p)=>p.id==lesson.learner);
    expect(learner.competence('craft'),0);expect(w.populationState!.members.containsKey(learner.id),isTrue);expect(s.workers,s.adults-2);
    final committed=w.canonical();expect(sim.submit(cmd).replayed,isTrue);expect(w.canonical(),committed);w.validate();
  });
  test('Training consumes actual work, persists partial skill, and completes after recovery',(){
    final w=world();provision(w);final sim=Simulation(w);expect(sim.submit(order(w,'train')).ok,isTrue);final learnerId=w.controlled.lessons.single.learner;
    sim.advanceDays(45);expect(w.controlled.people.firstWhere((p)=>p.id==learnerId).competence('craft'),500);
    final recovered=WorldState.fromJson(jsonDecode(jsonEncode(w.toJson())));final resumed=Simulation(recovered);
    sim.advanceDays(45);resumed.advanceDays(45);expect(recovered.canonical(),w.canonical());expect(w.controlled.lessons,isEmpty);
    expect(w.controlled.people.firstWhere((p)=>p.id==learnerId).competence('craft'),1000);w.validate();
  });
  test('Cancel refunds the unused fraction once and allows an existing apprentice to resume',(){
    final w=world();provision(w);final sim=Simulation(w);expect(sim.submit(order(w,'train')).ok,isTrue);sim.advanceDays(45);
    final l=w.controlled.lessons.single,learner=l.learner;final before=w.controlled.resources['knowledge']!;
    final cancel=order(w,'cancel',action:'cancel_train',target:l.id,choice:null);expect(sim.submit(cancel).ok,isTrue);
    expect(w.controlled.resources['knowledge'],before+2.5);expect(w.controlled.people.firstWhere((p)=>p.id==learner).competence('craft'),500);
    final state=w.canonical();expect(sim.submit(cancel).replayed,isTrue);expect(w.canonical(),state);
    final quote=sim.preview(order(w,'resume',target:learner));expect(quote.durationDays,45);expect(quote.costs['knowledge'],2.5);
    expect(sim.submit(order(w,'resume',target:learner)).ok,isTrue);sim.advanceDays(45);expect(w.controlled.people.firstWhere((p)=>p.id==learner).competence('craft'),1000);
  });
  test('Missing teachers do not create free specialists and insufficient resources reject atomically',(){
    final w=world();provision(w);final sim=Simulation(w);final before=w.canonical();expect(sim.submit(order(w,'technical',choice:'technical')).ok,isFalse);expect(w.canonical(),before);
    w.controlled.resources['knowledge']=0;final poor=w.canonical();expect(sim.submit(order(w,'poor')).ok,isFalse);expect(w.canonical(),poor);
  });
  test('A teacher cannot also lead an expedition and untrained teams require more work',(){
    final w=world();provision(w);w.controlled.resources['tools']=100;final sim=Simulation(w);
    expect(sim.submit(order(w,'scout',choice:'scout')).ok,isTrue);
    final preview=sim.preview(order(w,'explore',action:'explore',target:null,choice:null));expect(preview.durationDays,12);
    expect(sim.submit(order(w,'explore',action:'explore',target:null,choice:null)).ok,isTrue);
    final expedition=w.pending.firstWhere((e)=>e.type=='discovery'&&e.societyId==w.controlledId);expect(expedition.data['explorerId'],isNull);expect(expedition.data['remainingWork'],48);w.validate();
  });
  test('Malformed costs, ghost teachers and invented progress cannot be imported',(){
    final w=world();provision(w);final sim=Simulation(w);expect(sim.submit(order(w,'craft')).ok,isTrue);
    for(final corrupt in <void Function(Map<String,dynamic>)>[
      (j)=>j['societies'][0]['lessons'][0]['teacher']='missing',
      (j)=>j['societies'][0]['lessons'][0]['work']['committed']['food']=999999,
      (j)=>j['societies'][0]['lessons'][0]['work']['remaining']=1,
    ]){final j=jsonDecode(jsonEncode(w.toJson())) as Map<String,dynamic>;corrupt(j);expect(()=>WorldState.fromJson(j),throwsFormatException);}
  });
  test('Retirement interrupts a real teacher, preserves partial learning and refunds once',(){
    final w=world();provision(w);final sim=Simulation(w);expect(sim.submit(order(w,'craft')).ok,isTrue);sim.advanceDays(45);
    final l=w.controlled.lessons.single,learner=l.learner;
    w.controlled.people.firstWhere((p)=>p.id==l.teacher).bornDay=w.day-65*360+1;
    fixturePopulation(w);final before=w.controlled.resources['knowledge']!;
    sim.advanceDays(1);expect(w.controlled.lessons,isEmpty);expect(w.controlled.resources['knowledge']!,greaterThanOrEqualTo(before+2.5));
    expect(w.controlled.people.firstWhere((p)=>p.id==learner).competence('craft'),500);w.validate();
  });
  test('Trained craft saves inputs without changing the recipe output',(){
    final a=world(),b=world();
    for(final w in [a,b]){provision(w);final s=w.controlled;s.built={'knapping_shed':1};s.sites=[];s.ensureSites();s.health=100;}
    for(final p in b.controlled.people){p.skills['craft']=0;}
    Simulation(a).advanceDays(1);Simulation(b).advanceDays(1);
    expect(a.controlled.resources['tools'],b.controlled.resources['tools']);
    expect(a.controlled.resources['stone']!,greaterThan(b.controlled.resources['stone']!));
  });

}
