import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main(){
  test('Housing does not silently take labor from food and water production',(){
    final a=WorldState.generate(size:64),b=WorldState.generate(size:64);
    for(final world in [a,b]){final s=world.controlled;s.built={'farm':2,'well':1};s.sites=[];s.health=100;s.resources['food']=100;s.resources['water']=100;}
    b.controlled.built['house']=100;
    for(final world in [a,b]){world.controlled.ensureSites();world.validate();Simulation(world).advanceDays(1);}
    expect(a.controlled.resources['food'],b.controlled.resources['food']);
    expect(a.controlled.resources['water'],b.controlled.resources['water']);
  });
  test('A reserved construction crew cannot also produce on its completion day',(){
    final w=WorldState.generate(size:64,origin:'prehistory');final sim=Simulation(w);
    expect(sim.command('build',target:'shelter').ok,isTrue);
    sim.advanceDays(10);expect(w.controlled.projects,isEmpty);
    final last=w.controlled.lastProduction!,flow=DailyProduction.fromJson(Map<String,dynamic>.from(last['flows']));
    expect(flow.availableLabor,12000);expect(flow.laborUsed,lessThanOrEqualTo(12000));
    sim.advanceDays(1);final next=DailyProduction.fromJson(Map<String,dynamic>.from(w.controlled.lastProduction!['flows']));expect(next.availableLabor,16000);w.validate();
  });
  test('Existing rules7 worlds retain their previous labor semantics',(){
    WorldState legacy(bool houses){final raw=WorldState.generate(size:64).toJson();raw['rulesVersion']=7;raw.remove('migrations');final w=WorldState.fromJson(raw),s=w.controlled;s.built={'farm':2,'well':1,if(houses)'house':100};s.sites=[];s.ensureSites();s.health=100;s.resources['food']=100;s.resources['water']=100;return w;}
    final a=legacy(false),b=legacy(true);Simulation(a).advanceDays(1);Simulation(b).advanceDays(1);
    expect(a.controlled.resources['food'],isNot(b.controlled.resources['food']));expect(a.controlled.lastProduction,isNull);expect(b.controlled.lastProduction,isNull);
  });

  test('Autonomy repairs missing water capacity before chasing a nearly full food reserve',(){
    final w=WorldState.generate(size:64,origin:'prehistory',extraordinary:false);w.controlledId=null;
    final town=w.societies.first;town.built.remove('water_collect');town.sites.removeWhere((site)=>site.building=='water_collect');town.resources['food']=50;town.resources['water']=5;
    w.validate();Simulation(w).advanceDays(30,delegateDecisions:true);
    expect((town.built['water_collect']??0)>0||town.projects.any((p)=>p.building=='water_collect'),isTrue);
    expect(town.built['foraging_camp'],2);
  });

  test('An autonomous water emergency reserves an ordinary paid project on the first day',(){
    final world=WorldState.generate(size:64,origin:'prehistory',extraordinary:false);world.controlledId=null;final town=world.societies.first;
    town.built.remove('water_collect');town.sites.removeWhere((s)=>s.building=='water_collect');town.resources['water']=5;
    final wood=town.resources['wood']!,stone=town.resources['stone']!;final definition=world.buildingDefinitions.firstWhere((b)=>b.id=='water_collect');
    Simulation(world).advanceDays(1);final order=town.projects.singleWhere((p)=>p.building=='water_collect').work!;
    expect(order.createdDay,1);expect(order.remaining,order.totalWork-4);
    expect(town.resources['stone'],stone-(definition.cost['stone']??0));
    expect(town.resources['wood']!,greaterThanOrEqualTo(wood-(definition.cost['wood']??0)));
    expect(town.resources['wood']!,lessThan(wood));world.validate();
  });

}
