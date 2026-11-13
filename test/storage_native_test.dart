import 'dart:io';

import 'package:barrio_cero_eras/presentation/storage_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documents;
  late SaveStore store;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('barrio-storage-');
    store = SaveStore();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => documents.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await documents.delete(recursive: true);
  });

  test('queued writes retain the last confirmed value and its predecessor', () async {
    final writes = [
      store.write('world_0', 'first'),
      store.write('world_0', 'second'),
      store.write('world_0', 'third'),
    ];
    // Reads wait for queued commits, even without awaiting each write first.
    expect(await store.read('world_0'), 'third');
    await Future.wait(writes);
    expect(await store.read('world_0', backup: true), 'second');
    expect(await store.read('world_1'), isNull);
  });

  test('uncommitted temporary files never replace a confirmed save', () async {
    await store.write('world_0', 'previous');
    await store.write('world_0', 'confirmed');
    final root = '${documents.path}/barrio_cero';
    await File('$root/world_0.pending').writeAsString('incomplete');
    await File('$root/world_0.backup.pending').writeAsString('incomplete backup');
    final restarted = SaveStore();
    expect(await restarted.read('world_0'), 'confirmed');
    expect(await restarted.read('world_0', backup: true), 'previous');
    await restarted.write('world_0', 'next');
    expect(await restarted.read('world_0'), 'next');
    expect(await restarted.read('world_0', backup: true), 'confirmed');
  });

  test('failed temporary write preserves both saves and does not poison queue', () async {
    await store.write('world_0', 'previous');
    await store.write('world_0', 'confirmed');
    final obstacle = Directory('${documents.path}/barrio_cero/world_0.pending');
    await obstacle.create();
    await expectLater(store.write('world_0', 'rejected'), throwsA(isA<FileSystemException>()));
    expect(await store.read('world_0'), 'confirmed');
    expect(await store.read('world_0', backup: true), 'previous');
    await obstacle.delete();
    await store.write('world_0', 'recovered');
    expect(await store.read('world_0'), 'recovered');
    expect(await store.read('world_0', backup: true), 'confirmed');
  });

  test('slot validation rejects paths outside the defined archive', () async {
    for (final slot in ['../world_0', 'world_3', 'world_-1', '/tmp/save']) {
      expect(() => store.write(slot, 'invalid'), throwsFormatException);
      await expectLater(store.read(slot), throwsFormatException);
    }
    expect(await documents.list().isEmpty, isTrue);
  });
}
