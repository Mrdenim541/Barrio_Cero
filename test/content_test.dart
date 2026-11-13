import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/content/content_pack.dart';

void main() {
  final source = File('assets/content/core.json').readAsStringSync();
  final example = File('assets/content/example_pack.json').readAsStringSync();
  final manifest = jsonDecode(File('assets/content/manifest.json').readAsStringSync());
  test('pinned core and importable example validate', () {
    final core = ContentPack.parse(source, expectedHash: manifest['packages'][0]['sha256']);
    final extra = ContentPack.parse(example, base: core);
    final registry = ContentRegistry()..importPack(core)..importPack(extra);
    final combined = registry.compose([core.pin, extra.pin]);
    expect(combined['events'].length, 159);
    expect(core.data['arcs'].length, 12);
    expect(core.data['templates'].length, 16);
    expect(registry.prepareMigration(pins: [core.pin], pendingEventIds: ['facility_energy'])['events'].length, 158);
    expect(() => registry.prepareMigration(pins: [core.pin], pendingEventIds: ['absent']), throwsFormatException);
  });
  test('rejects changed bytes and same-version replacement', () {
    final core = ContentPack.parse(source);
    expect(() => ContentPack.parse('$source ', expectedHash: core.hash), throwsFormatException);
    final registry = ContentRegistry()..importPack(core);
    expect(() => registry.importPack(ContentPack.parse('$source ')), throwsFormatException);
    expect(() => registry.compose([core.pin, core.pin]), throwsFormatException);
  });
  test('rejects forbidden operations, unknown conditions and malformed effects', () {
    void rejects(void Function(Map<String, dynamic>) edit) {
      final pack = jsonDecode(source) as Map<String, dynamic>;
      edit(pack);
      expect(() => ContentPack.parse(jsonEncode(pack)), throwsFormatException);
    }
    rejects((p) => p['events'][0]['options'][0]['effects'][0]['type'] = 'execute');
    rejects((p) => p['events'][0]['conditions']['execute'] = 'rm');
    rejects((p) => p['events'][0]['conditions']['technologies'] = ['unknown']);
    rejects((p) => p['events'][0]['options'][0]['costs'] = {'food': -1});
    rejects((p) => p['events'][0]['options'][0]['effects'] = [{'type': 'flag', 'value': 9}]);
    rejects((p) => p['events'][0]['options'][0]['effects'] = [{'type': 'resource', 'resource': 'unknown', 'value': 3}]);
    rejects((p) => p['events'][0]['options'][0]['effects'] = [{'type': 'schedule', 'eventId': 'unknown', 'delayDays': 1}]);
    rejects((p) => p['events'][0]['options'][0]['effects'] = [{'type': 'schedule', 'eventId': 'facility_energy', 'delayDays': 0}]);
    rejects((p) => p['technologies'][0]['requires'] = [p['technologies'][0]['id']]);
    rejects((p) => p['templates'][0]['parameter']['maximum'] = 9999999);
  });
  test('extra package collision and incompatible dependency are rejected', () {
    final core = ContentPack.parse(source);
    final pack = jsonDecode(example) as Map<String, dynamic>;
    pack['events'][0]['id'] = 'granary_mold';
    expect(() => ContentPack.parse(jsonEncode(pack), base: core), throwsFormatException);
    pack['events'][0]['id'] = 'senderos_waystone';
    pack['requires']['barrio.core'] = '99.0.0';
    expect(() => ContentPack.parse(jsonEncode(pack), base: core), throwsFormatException);
  });
}
