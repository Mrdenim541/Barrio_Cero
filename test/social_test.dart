import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  WorldState world() =>
      WorldState.generate(size: 64, seed: 31, origin: 'prehistory');
  HomeRequest request(WorldState w) {
    final s = w.controlled, a = s.people[0], b = s.people[1];
    final bond =
        w.socialState!.meet(a.id, b.id, w.day, wantsA: false, wantsB: false)
          ..friendship = 20
          ..trust = 20;
    return w.socialState!.requestHome(
      bond.a,
      bond.b,
      s.id,
      w.day,
      w.socialResidents,
    )!;
  }

  Command command(
    WorldState w,
    String id,
    String action,
    String target, {
    String? choice,
  }) => Command(
    id: id,
    action: action,
    actorId: w.controlledId,
    issuedDay: w.day,
    target: target,
    choice: choice,
  );
  test(
    'A household decision consumes provisions without adding people or romantic consent',
    () {
      final w = world();
      final actual = request(w);
      final sim = Simulation(w),
          population = w.populationState!.total,
          before = w.canonical();
      final cmd = command(w, 'home', 'home', actual.id, choice: 'support');
      expect(sim.preview(cmd).allowed, isTrue);
      expect(w.canonical(), before);
      final result = sim.submit(cmd);
      expect(result.ok, isTrue, reason: result.message);
      expect(w.controlled.resources['wood'], 26);
      expect(w.controlled.resources['food'], 54);
      expect(w.populationState!.total, population);
      expect(w.socialState!.households.singleValue.members.length, 2);
      expect(w.socialState!.bond(actual.a, actual.b)!.status, 'acquaintance');
      expect(w.socialState!.bond(actual.a, actual.b)!.wantsA, isFalse);
      final saved = w.canonical();
      expect(sim.submit(cmd).replayed, isTrue);
      expect(w.canonical(), saved);
      w.validate();
    },
  );
  test(
    'Tutela destaca un menor existente, conserva su edad y no inventa ascendencia',
    () {
      final w = world();
      final actual = request(w);
      final sim = Simulation(w);
      expect(
        sim.submit(command(w, 'home', 'home', actual.id, choice: 'support')).ok,
        isTrue,
      );
      final population = w.populationState!.total;
      final adult = actual.a;
      final cmd = command(w, 'care', 'foster', adult);
      final result = sim.submit(cmd);
      expect(result.ok, isTrue, reason: result.message);
      expect(w.populationState!.total, population);
      final guardian = w.socialState!.guardians.single;
      expect(guardian['kind'], 'guardian');
      final child = w.controlled.people.firstWhere(
        (p) => p.id == guardian['child'],
      );
      expect(w.day - child.bornDay, lessThan(18 * 360));
      expect(w.populationState!.cohortOf(child.id), isNotNull);
      expect(w.socialState!.related(adult, child.id), isTrue);
      final roundtrip = WorldState.fromJson(jsonDecode(jsonEncode(w.toJson())));
      expect(roundtrip.canonical(), w.canonical());
    },
  );
  test(
    'A request expires and dead or absent participants cannot accept it',
    () {
      final w = world();
      final actual = request(w);
      final social = w.socialState!;
      social.reconcile(90, w.socialResidents);
      expect(social.requests[actual.id]!.status, 'expired');
      expect(social.canResolve(actual.id, 90, w.socialResidents), isNotNull);
    },
  );
  test(
    'Death retains membership history and records one loss instead of deleting the household',
    () {
      final w = world();
      final r = request(w);
      final social = w.socialState!;
      final home = social.resolve(r.id, 0, w.socialResidents);
      final people = Map<String, SocialResident>.from(w.socialResidents);
      final old = people[r.a]!;
      people[r.a] = SocialResident(old.id, old.settlement, old.bornDay, 1);
      social.reconcile(1, people);
      social.reconcile(1, people);
      expect(home.joined.containsKey(r.a), isTrue);
      expect(home.members.contains(r.a), isFalse);
      expect(social.memories.where((m) => m['kind'] == 'loss').length, 1);
      social.validate(1, people, w.societies.map((s) => s.id).toSet());
    },
  );
  test(
    'Current residents actually meet over months; saving does not change the sequence',
    () {
      var a = world(), b = world();
      for (final w in [a, b]) {
        for (final s in w.societies) {
          s.resources['food'] = 10000;
          s.resources['water'] = 10000;
          s.policy.expansion = false;
        }
      }
      Simulation(a).advanceDays(720);
      for (var i = 0; i < 24; i++) {
        Simulation(b).advanceDays(30);
        b = WorldState.fromJson(jsonDecode(jsonEncode(b.toJson())));
      }
      expect(a.canonical(), b.canonical());
      expect(a.socialState!.bonds, isNotEmpty);
      expect(a.socialState!.requests, isNotEmpty);
      a.validate();
    },
  );
  test('The engine records household losses once, even on its founding day',(){
    final w=world();final r=request(w);final sim=Simulation(w);
    expect(sim.submit(command(w,'home','home',r.id,choice:'support')).ok,isTrue);
    sim.registerContent({'events':[{'id':'loss','title':'Una pérdida real','body':'Una crisis afecta a residentes existentes.','trigger':'director','conditions':<String,dynamic>{},'repeatable':false,'category':'health','options':[{'id':'apply','label':'Continuar','costs':<String,num>{},'effects':[{'type':'population','value':-24}],'followUps':[]}]}]});
    final cmd=command(w,'loss','resolve_event','loss',choice:'apply');final result=sim.submit(cmd);expect(result.ok,isTrue,reason:result.message);
    expect(w.socialState!.households.values.single.members,isEmpty);expect(w.socialState!.households.values.single.joined.length,2);
    expect(w.socialState!.memories.where((m)=>m['kind']=='loss').length,2);w.validate();
    final before=w.canonical();expect(sim.submit(cmd).replayed,isTrue);expect(w.canonical(),before);
  });
  test('An invalid romance or duplicate home cannot be imported', () {
    final w = world();
    final r = request(w);
    w.socialState!.resolve(r.id, 0, w.socialResidents);
    final raw = jsonDecode(jsonEncode(w.toJson())) as Map<String, dynamic>;
    raw['socialState']['bonds'][0]['status'] = 'romance';
    expect(() => WorldState.fromJson(raw), throwsFormatException);
  });
}

extension SingleMapValue<K, V> on Map<K, V> {
  V get singleValue => values.single;
}
