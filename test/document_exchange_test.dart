import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/platform/document_exchange.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.barriocero.eras/documents');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() { debugDefaultTargetPlatformOverride = TargetPlatform.android; });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('export sends exact UTF-8 text and returns document URI', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'exportDocument');
      expect(call.arguments, {'text': '{"nombre":"Barrio Cero · año 2"}', 'suggestedName': 'mundo.json'});
      return 'content://documents/mundo.json';
    });
    final exchange = DocumentExchange();
    expect(await exchange.exportDocument(text: '{"nombre":"Barrio Cero · año 2"}', suggestedName: 'mundo.json'), 'content://documents/mundo.json');
  });

  test('import returns raw text for caller validation and cancellation returns null', () async {
    var cancelled = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'importDocument');
      return cancelled ? null : '{"schema":2}';
    });
    final exchange = DocumentExchange();
    expect(await exchange.importDocument(), '{"schema":2}');
    cancelled = true;
    expect(await exchange.importDocument(), isNull);
  });

  test('native failure propagates and releases operation guard', () async {
    var failed = true;
    messenger.setMockMethodCallHandler(channel, (_) async {
      if (failed) throw PlatformException(code: 'document_io');
      return null;
    });
    final exchange = DocumentExchange();
    await expectLater(exchange.importDocument(), throwsA(isA<PlatformException>()));
    failed = false;
    expect(await exchange.importDocument(), isNull);
  });

  test('concurrent picker is rejected without starting another native operation', () async {
    final response = Completer<String?>();
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) { calls++; return response.future; });
    final exchange = DocumentExchange();
    final first = exchange.importDocument();
    await expectLater(exchange.importDocument(), throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'document_busy')));
    response.complete(null);
    await first;
    expect(calls, 1);
  });

  test('unsupported platform never invokes Android channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    messenger.setMockMethodCallHandler(channel, (_) async => fail('Unexpected platform invocation'));
    final exchange = DocumentExchange();
    expect(exchange.supported, isFalse);
    await expectLater(exchange.importDocument(), throwsUnsupportedError);
  });

  test('export enforces byte limit before native invocation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => fail('Oversized document reached native code'));
    final chunk = List.filled(1000, 'é').join();
    final buffer = StringBuffer();
    for (var i = 0; i <= DocumentExchange.maxBytes ~/ 2000; i++) {
      buffer.write(chunk);
    }
    final text = buffer.toString();
    await expectLater(DocumentExchange().exportDocument(text: text), throwsFormatException);
  });
}
