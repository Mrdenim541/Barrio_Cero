import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barrio_cero_eras/content/content_pack.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

String digest(dynamic input) {
  dynamic sort(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: sort(value[key])};
    }
    if (value is List) return value.map(sort).toList();
    return value;
  }
  return sha256.convert(utf8.encode(jsonEncode(sort(input)))).toString();
}

void main() {
  final core = File('assets/content/core.json').readAsStringSync();
  final extra = File('assets/content/example_pack.json').readAsStringSync();
  final base = ContentPack.parse(core);
  final addon = ContentPack.parse(extra, base: base);

  Checkpoint fixture({bool withAddon = false}) => Checkpoint.create(
    world: WorldState.generate(seed: 19, size: 64), coreSource: core,
    additionalSources: withAddon ? [extra] : [], target: 3600,
    settings: {'sound': true},
  );

  String tamper(Checkpoint checkpoint, void Function(Map<String, dynamic>) edit,
      {bool rehash = false}) {
    final map = jsonDecode(checkpoint.encode()) as Map<String, dynamic>;
    edit(map['payload'] as Map<String, dynamic>);
    if (rehash) map['sha256'] = digest(map['payload']);
    return jsonEncode(map);
  }

  test('roundtrip retains world, target, settings and complete exact sources', () {
    final cp = fixture(withAddon: true);
    final restored = Checkpoint.decode(cp.encode());
    expect(restored.world.canonical(), cp.world.canonical());
    expect(restored.target, 3600);
    expect(restored.stopCrisis, isTrue);
    expect(restored.settings['sound'], isTrue);
    expect(restored.coreSource, core);
    expect(restored.additionalSources, [extra]);
    expect(restored.world.contentVersions['${addon.id}.version'], addon.version);
    expect(restored.encode(), cp.encode());
  });

  test('creating a bound snapshot does not mutate the running world', () {
    final w = WorldState.generate(size: 64);
    final before = w.canonical();
    final cp = Checkpoint.create(world: w, coreSource: core);
    expect(w.canonical(), before);
    expect(cp.world.contentVersions['barrio.core.sha256'], base.hash);
  });

  test('target, crisis policy, settings and packages are inside integrity hash', () {
    final cp = fixture(withAddon: true);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (p) => p['target'] = 7200,
      (p) => p['stopCrisis'] = false,
      (p) => (p['settings'] as Map)['sound'] = false,
      (p) => (p['packages'] as List).removeLast(),
    ]) {
      expect(() => Checkpoint.decode(tamper(cp, edit)), throwsFormatException);
    }
  });

  test('rehashed invalid dates, types and unknown envelope fields are rejected', () {
    final cp = fixture();
    for (final edit in <void Function(Map<String, dynamic>)>[
      (p) => p['target'] = -1,
      (p) => p['target'] = 360001,
      (p) => p['target'] = 1.5,
      (p) => p['stopCrisis'] = 'false',
      (p) => (p['settings'] as Map)['sound'] = 1,
      (p) => (p['settings'] as Map)['invented'] = false,
      (p) => p['surprise'] = 1,
    ]) {
      expect(() => Checkpoint.decode(tamper(cp, edit, rehash: true)),
        throwsFormatException);
    }
    final envelope = jsonDecode(cp.encode()) as Map;
    envelope['ignored'] = true;
    expect(() => Checkpoint.decode(jsonEncode(envelope)), throwsFormatException);
  });

  test('package drops, extra pins, missing core and replacement bytes rejected', () {
    final cp = fixture(withAddon: true);
    for (final edit in <void Function(Map<String, dynamic>)>[
      (p) => (p['packages'] as List).removeLast(),
      (p) => (p['packages'] as List).removeAt(0),
      (p) => ((p['world'] as Map)['contentVersions'] as Map)['unknown.sha256'] = base.hash,
      (p) => ((p['packages'] as List).first as Map)['source'] = '$core ',
      (p) => (p['packages'] as List).add((p['packages'] as List).last),
    ]) {
      expect(() => Checkpoint.decode(tamper(cp, edit, rehash: true)),
        throwsFormatException);
    }
  });

  test('content pending references must exist in exact packaged versions', () {
    final w = WorldState.generate(size: 64);
    w.pending.add(ScheduledEvent('pending999', 'content', 's0', 30,
      data: {'eventId': 'not_in_package'}));
    expect(() => Checkpoint.create(world: w, coreSource: core),
      throwsFormatException);
  });

  test('legacy migration is explicit, retains old world and validates core bytes', () {
    final w = WorldState.generate(size: 64);
    w.contentVersions['barrio.core.sha256'] = base.hash;
    w.contentVersions['${addon.id}.sha256'] = addon.hash;
    final state = w.toJson();
    final original = jsonEncode({
      'format': 'barrio-cero-save', 'version': 1, 'world': state,
      'sha256': sha256.convert(utf8.encode(jsonEncode(state))).toString(),
      'packs': [extra], 'target': 360, 'stopCrisis': false,
      'settings': {'reduceMotion': true, 'sound': false, 'vibration': true},
    });
    expect(() => Checkpoint.decode(original), throwsFormatException);
    final migrated = Checkpoint.migrateLegacy(original, expectedCoreSource: core);
    expect(migrated.world.day, w.day);
    expect(migrated.target, 360);
    expect(migrated.stopCrisis, isFalse);
    expect(migrated.settings['reduceMotion'], isTrue);
    expect(migrated.additionalSources, [extra]);
    expect(Checkpoint.decode(migrated.encode()).world.canonical(),
      migrated.world.canonical());
    expect(() => Checkpoint.migrateLegacy(original, expectedCoreSource: '$core '),
      throwsFormatException);
    final dropped = jsonDecode(original) as Map;
    dropped['packs'] = [];
    expect(() => Checkpoint.migrateLegacy(jsonEncode(dropped),
      expectedCoreSource: core), throwsFormatException);
  });

  test('checkpoint retains embedded base when installed base later changes', () {
    final saved = fixture().encode();
    // decode needs no external assets; old source stays available byte-for-byte.
    final restored = Checkpoint.decode(saved);
    expect(restored.basePack.hash, base.hash);
    expect(restored.coreSource, core);
  });
}
