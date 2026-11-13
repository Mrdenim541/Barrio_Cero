import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/app.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  setUp(() async {
    documents = await Directory.systemTemp.createTemp('barrio-ui-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documents.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
    await documents.delete(recursive: true);
  });
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('Start screen and world configuration remain usable at $width', (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(const BarrioApp());
        final dynamic session = tester.state(find.byType(ErasScreen));
        await session.initialization;
      });
      await tester.pumpAndSettle();
      expect(find.text('CREAR UN MUNDO'), findsOneWidget);
      await tester.runAsync(() => tester.tap(find.text('CREAR UN MUNDO')));
      await tester.pumpAndSettle();
      expect(find.text('Semilla reproducible'), findsOneWidget);
      expect(find.text('Fundar Barrio Cero'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Continuar historia'), findsOneWidget);
    });
  }
  testWidgets('Create, order, advance and reload a committed world at 320x640', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late dynamic session;
    await tester.runAsync(() async {
      await tester.pumpWidget(const BarrioApp());
      session = tester.state(find.byType(ErasScreen));
      await session.initialization;
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('CREAR UN MUNDO')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '42');
    Future<void> commitTap(String label, bool Function() committed) async {
      await tester.runAsync(() async {
        await tester.tap(find.text(label));
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!committed()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('No confirmed transition after tapping $label; ${session.note}');
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      // Flame continuously schedules frames; await the modal animation, not idle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await commitTap('Fundar Barrio Cero', () => session.world != null && !session.advancing);
    expect(find.text('Año 1 · mes 1 · día 1'), findsOneWidget);
    expect(find.text('Construir'), findsOneWidget);
    // Essential time controls must remain readable on the smallest phone.
    expect(tester.getSize(find.text('Años')).height, lessThan(24));
    expect(tester.getSize(find.text('Crónica')).height, lessThan(24));
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Construir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await commitTap('Huerto', () => session.world.commandReceipts.isNotEmpty && !session.advancing);
    expect(session.world.society(session.world.controlledId).projects.length, 1);
    await commitTap('+ Día', () => session.world.day == 1 && !session.advancing);
    expect(find.text('Año 1 · mes 1 · día 2'), findsOneWidget);
    late String saved;
    await tester.runAsync(() async {
      saved = await File('${documents.path}/barrio_cero/world_0.json').readAsString();
    });
    final checkpoint = Checkpoint.decode(saved);
    expect(checkpoint.world.day, 1);
    expect(checkpoint.world.commandReceipts.length, 1);
    expect(checkpoint.world.society(checkpoint.world.controlledId)!.projects.length, 1);

    // Destroy the session and reconstruct it from disk, as after process restart.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await tester.pumpWidget(const BarrioApp());
      session = tester.state(find.byType(ErasScreen));
      await session.initialization;
    });
    await tester.pumpAndSettle();
    await commitTap('Continuar historia', () => session.world != null && !session.advancing);
    expect(session.world.toJson(), checkpoint.world.toJson());
    expect(find.text('Año 1 · mes 1 · día 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

}
