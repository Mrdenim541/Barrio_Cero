import 'dart:io';

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
    final sizes = {'characters': [128, 2304], 'buildings': [384, 192], 'terrain': [192, 32]};
    for (final entry in sizes.entries) {
      final image = await loadArtImage(_OffsetAssetBundle(), 'assets/art/${entry.key}.png');
      expect([image.width, image.height], entry.value);
      final raw = await loadArtPixels(_OffsetAssetBundle(), 'assets/art/${entry.key}.rgba', entry.value[0], entry.value[1]);
      final expected = (await image.toByteData())!.buffer.asUint8List();
      final actual = (await raw.toByteData())!.buffer.asUint8List();
      expect(actual.length, expected.length);
      var maximumDifference = 0;
      for (var i = 0; i < actual.length; i++) {
        final difference = (actual[i] - expected[i]).abs();
        if (difference > maximumDifference) maximumDifference = difference;
      }
      expect(maximumDifference, lessThanOrEqualTo(1), reason: 'PNG and premultiplied atlas pixels must agree');
      raw.dispose();
      image.dispose();
    }
  });
}
