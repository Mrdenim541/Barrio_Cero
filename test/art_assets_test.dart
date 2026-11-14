import 'dart:io';
import 'dart:convert';

import 'package:barrio_cero_eras/presentation/art_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _OffsetAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    final message = Uint8List(bytes.length + 32)..fillRange(0, 32, 255);
    message.setRange(17, 17 + bytes.length, bytes);
    return ByteData.view(message.buffer, 17, bytes.length);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('original atlases decode from bounded platform buffer views', () async {
    final manifest = jsonDecode(
      File('assets/art/atlas.json').readAsStringSync(),
    );
    final sizes = {
      for (final key in ['characters', 'buildings', 'terrain'])
        key: [
          manifest[key]['pixelWidth'] as int,
          manifest[key]['pixelHeight'] as int,
        ],
    };
    for (final entry in sizes.entries) {
      final image = await loadArtImage(
        _OffsetAssetBundle(),
        'assets/art/${entry.key}.png',
      );
      expect([image.width, image.height], entry.value);
      final raw = await loadArtPixels(
        _OffsetAssetBundle(),
        'assets/art/${entry.key}.rgba',
        entry.value[0],
        entry.value[1],
      );
      final expected = (await image.toByteData())!.buffer.asUint8List();
      final actual = (await raw.toByteData())!.buffer.asUint8List();
      expect(actual.length, expected.length);
      var maximumDifference = 0;
      for (var i = 0; i < actual.length; i++) {
        final difference = (actual[i] - expected[i]).abs();
        if (difference > maximumDifference) maximumDifference = difference;
      }
      expect(
        maximumDifference,
        lessThanOrEqualTo(1),
        reason: 'PNG and premultiplied atlas pixels must agree',
      );
      raw.dispose();
      image.dispose();
    }
  });
  test('Every shipped building and primitive role has an atlas frame', () {
    final manifest = jsonDecode(
      File('assets/art/atlas.json').readAsStringSync(),
    );
    final buildings = AtlasLayout.fromJson(
      Map<String, dynamic>.from(manifest['buildings']),
    );
    final core = jsonDecode(
      File('assets/content/core.json').readAsStringSync(),
    );
    final pixels = File('assets/art/buildings.rgba').readAsBytesSync();
    for (final definition in core['buildings']) {
      final frame = buildings.frame(definition['id']);
      expect(frame, isNotNull);
      var visible = false;
      for (var y = frame!.top.toInt(); y < frame.bottom; y++) {
        for (var x = frame.left.toInt(); x < frame.right; x++) {
          if (pixels[(y * buildings.pixelWidth + x) * 4 + 3] > 0) {
            visible = true;
          }
        }
      }
      expect(visible, isTrue, reason: '${definition['id']} has actual pixels');
    }
    final people = AtlasLayout.fromJson(
      Map<String, dynamic>.from(manifest['characters']),
    );
    for (final role in [
      'ancestral_artisan',
      'ancestral_scout',
      'ancestral_elder',
    ]) {
      final index = people.roles.indexOf(role);
      expect(index, greaterThanOrEqualTo(0));
      expect(
        () => people.cell(
          index * people.actions.length + people.actions.indexOf('work'),
          3,
        ),
        returnsNormally,
      );
    }
  });
}
