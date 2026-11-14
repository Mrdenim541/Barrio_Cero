import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/session/session_controller.dart';

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  String oldSave() {
    final w = WorldState.generate(seed: 42, size: 64, fixedMaterials: false);
    w.controlled.resources['food'] = 123.123456789;
    return '  ${Checkpoint.create(world: w, coreSource: core).encode()}\n';
  }

  test(
    'Conversion preserves identities, PRNG, population, pins and records rounding',
    () {
      final source = oldSave();
      final old = Checkpoint.decode(source);
      final upgraded = Checkpoint.upgradeRules(source);
      expect(upgraded.world.random.state, old.world.random.state);
      expect(upgraded.world.day, old.world.day);
      expect(
        upgraded.world.societies.map((s) => s.population),
        old.world.societies.map((s) => s.population),
      );
      expect(
        upgraded.world.societies.map(
          (s) => s.people.map((p) => p.toJson()).toList(),
        ),
        old.world.societies.map(
          (s) => s.people.map((p) => p.toJson()).toList(),
        ),
      );
      expect(upgraded.world.controlled.resources['food'], 123.123);
      expect(
        upgraded.world.ruleChanges.single['amountAdjustments'],
        isNotEmpty,
      );
      expect(upgraded.coreSource, old.coreSource);
      expect(
        upgraded.world.entities!.societies.keys.toSet(),
        old.world.societies.map((s) => s.id).toSet(),
      );
      expect(
        Checkpoint.decode(upgraded.encode()).world.canonical(),
        upgraded.world.canonical(),
      );
    },
  );
  test('Rules 6 conversion preserves exact cohorts and skills without inventing families',(){
    final raw=WorldState.generate(size:64,origin:'prehistory').toJson();
    raw.remove('socialState');raw['rulesVersion']=6;
    final previous=Checkpoint.create(world:WorldState.fromJson(raw),coreSource:core);
    final source=previous.encode(),before=Checkpoint.decode(previous.encode());
    final upgraded=Checkpoint.upgradeRules(source);
    expect(upgraded.world.populationState!.toJson(),before.world.populationState!.toJson());
    expect(upgraded.world.societies.map((s)=>s.people.map((p)=>p.toJson()).toList()),before.world.societies.map((s)=>s.people.map((p)=>p.toJson()).toList()));
    expect(upgraded.world.socialState!.bonds,isEmpty);expect(upgraded.world.socialState!.households,isEmpty);expect(upgraded.world.socialState!.guardians,isEmpty);
    expect(upgraded.world.random.state,before.world.random.state);expect(upgraded.coreSource,before.coreSource);
    expect(upgraded.world.ruleChanges.last['ageEstimation'],'unchanged; existing cohort dates retained');
    expect(Checkpoint.decode(source).world.rulesVersion,6);
  });
  test(
    'Cancel has no writes; upgrade keeps exact bytes; restore reactivates old rules',
    () async {
      final original = oldSave();
      final files = {'world_0': original};
      final session = SessionController(
        read: (key, {backup = false}) async => files[key],
        write: (key, value) async {
          files[key] = value;
        },
        loadCore: () async => core,
      );
      await session.loadSlot(0);
      final before = Map.from(files);
      final cancelled = await session.upgradeRules(confirm: () async => false);
      expect(cancelled.accepted, isFalse);
      expect(files, before);
      await session.upgradeRules(confirm: () async => true);
      final backup = files.keys.singleWhere((k) => k.startsWith('rules_'));
      expect(files[backup], original);
      expect(session.worldCopy()!.entities, isNotNull);
      expect(session.worldCopy()!.controlled.materialRules, 2);
      await session.restoreRulesBackup();
      expect(session.worldCopy()!.controlled.materialRules, 1);
      expect(session.worldCopy()!.controlled.resources['food'], 123.123456789);
      expect(files[backup], original);
    },
  );
  test(
    'Failure after backup leaves committed world and session untouched',
    () async {
      final original = oldSave();
      final files = {'world_0': original};
      var fail = false;
      final session = SessionController(
        read: (key, {backup = false}) async => files[key],
        write: (key, value) async {
          if (fail && key == 'world_0') throw FileSystemException('disk full');
          files[key] = value;
        },
        loadCore: () async => core,
      );
      await session.loadSlot(0);
      final before = session.worldCopy()!.canonical();
      fail = true;
      await expectLater(
        session.upgradeRules(confirm: () async => true),
        throwsA(isA<FileSystemException>()),
      );
      expect(session.worldCopy()!.canonical(), before);
      expect(files['world_0'], original);
      expect(files.keys.where((k) => k.startsWith('rules_')).length, 1);
    },
  );
  test('Impossible reconciliation rejects and retains original rules', () {
    final w = WorldState.generate(size: 64, fixedMaterials: false);
    w.controlled.adults = 1;
    final raw = Checkpoint.create(world: w, coreSource: core).encode();
    expect(() => Checkpoint.upgradeRules(raw), throwsFormatException);
    expect(Checkpoint.decode(raw).world.controlled.materialRules, 1);
  });
}
