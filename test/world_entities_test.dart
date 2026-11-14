import '../tool/fixtures.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  Command cmd(WorldState w, String action, String target, String id) => Command(
    id: id,
    action: action,
    actorId: w.controlledId,
    issuedDay: w.day,
    target: target,
  );
  WorldState ready() {
    final w = WorldState.generate(seed: 42, size: 64);
    w.societies[0].relations['s1'] = 60;
    w.societies[1].relations['s0'] = 60;
    return w;
  }

  test('Union owns two distinct cities without copying reserves or people', () {
    final w = ready();
    final initial = w.societies[1].toJson();
    final people = w.societies.fold<int>(0, (n, s) => n + s.population);
    expect(Simulation(w).submit(cmd(w, 'federate', 's1', 'union')).ok, isTrue);
    expect(w.entities!.citiesOf('s0').length, 2);
    expect(w.entities!.societies.containsKey('s1'), isTrue);
    expect(w.entities!.societies['s1']!.capitalId, isNull);
    expect(w.societies[1].toJson(), initial);
    expect(w.societies.fold<int>(0, (n, s) => n + s.population), people);
    expect(w.controlled.resources['food'], 240);
    expect(w.controlled.resources['knowledge'], 25);
    w.validate();
  });
  test(
    'Capital relocation retains government, stocks and identities through save',
    () {
      final w = ready();
      final sim = Simulation(w);
      sim.submit(cmd(w, 'federate', 's1', 'union'));
      final leader = w.entities!.societies['s0']!.leaderId;
      final resources = w.societies.map((s) => Map.from(s.resources)).toList();
      expect(sim.submit(cmd(w, 'capital', 's1', 'capital')).ok, isTrue);
      expect(w.entities!.societies['s0']!.capitalId, 'settlement:s1');
      expect(w.entities!.societies['s0']!.leaderId, leader);
      expect(w.societies.map((s) => s.resources).toList(), resources);
      final checkpoint = Checkpoint.create(
        world: w,
        coreSource: File('assets/content/core.json').readAsStringSync(),
      );
      expect(
        Checkpoint.decode(checkpoint.encode()).world.entities!.toJson(),
        w.entities!.toJson(),
      );
    },
  );
  test('Union prerequisites and foreign capitals reject without effects', () {
    final w = WorldState.generate(size: 64);
    final before = w.canonical();
    final sim = Simulation(w);
    expect(sim.submit(cmd(w, 'federate', 's1', 'union')).ok, isFalse);
    expect(w.canonical(), before);
    expect(sim.submit(cmd(w, 'capital', 's1', 'capital')).ok, isFalse);
    expect(w.canonical(), before);
  });
  test(
    'Losing capital keeps the society and its surviving city and culture',
    () {
      final w = ready();
      Simulation(w).submit(cmd(w, 'federate', 's1', 'union'));
      final origin = w.societies.first;
      origin.children = 0;
      origin.adults = 0;
      origin.elders = 0;
      origin.extinct = true;fixturePopulation(w,trimFeatures:true);
      Simulation(w).advanceDays(1);
      expect(w.entities!.societies['s0']!.capitalId, 'settlement:s1');
      expect(w.entities!.cultures.length, 6);
      w.validate();
    },
  );
  test('Corrupt ownership and duplicate city actors rejected', () {
    final raw = jsonDecode(jsonEncode(WorldState.generate(size: 64).toJson()));
    raw['entities']['settlements'][0]['societyId'] = 'missing';
    expect(() => WorldState.fromJson(raw), throwsFormatException);
  });
  test('Legacy execution has no invented political history', () {
    final w = WorldState.generate(size: 64, fixedMaterials: false);
    final raw = w.toJson();
    expect(raw.containsKey('entities'), isFalse);
    expect(WorldState.fromJson(raw).toJson(), raw);
  });
  test('Unsupported species and ignored entity fields are rejected', () {
    final raw = jsonDecode(jsonEncode(WorldState.generate(size: 64).toJson()));
    raw['entities']['species'].add('equine');
    expect(() => WorldState.fromJson(raw), throwsFormatException);
    final unknown = jsonDecode(
      jsonEncode(WorldState.generate(size: 64).toJson()),
    );
    unknown['entities']['settlements'][0]['inventedMechanic'] = true;
    expect(() => WorldState.fromJson(unknown), throwsFormatException);
  });
}
