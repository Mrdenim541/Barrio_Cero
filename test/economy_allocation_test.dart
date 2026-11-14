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
    WorldState legacy(bool houses){final raw=WorldState.generate(size:64).toJson();raw['rulesVersion']=7;final w=WorldState.fromJson(raw),s=w.controlled;s.built={'farm':2,'well':1,if(houses)'house':100};s.sites=[];s.ensureSites();s.health=100;s.resources['food']=100;s.resources['water']=100;return w;}
    final a=legacy(false),b=legacy(true);Simulation(a).advanceDays(1);Simulation(b).advanceDays(1);
    expect(a.controlled.resources['food'],isNot(b.controlled.resources['food']));expect(a.controlled.lastProduction,isNull);expect(b.controlled.lastProduction,isNull);
  });

}
