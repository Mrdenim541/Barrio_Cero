import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/app.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart' show WorldState;

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
        .setMockMethodCallHandler(const MethodChannel('com.barriocero.eras/documents'), null);
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

    // Opening Android's picker can enqueue multiple lifecycle saves before an
    // import commits. They must never overwrite the imported world afterward.
    await commitTap('+ Día', () => session.world.day == 2 && !session.advancing);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.barriocero.eras/documents'), (call) async {
      expect(call.method, 'importDocument');
      session.didChangeAppLifecycleState(AppLifecycleState.inactive);
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      return saved;
    });
    await tester.tap(find.text('MENÚ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Archivo de mundos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await commitTap('Importar partida (JSON)', () => session.note == 'Historia importada.' && !session.advancing);
    expect(session.world.day, 1);
    await tester.runAsync(() async {
      await session.saveQueue;
      final persisted = Checkpoint.decode(await session.store.read('world_0') as String);
      expect(persisted.world.toJson(), checkpoint.world.toJson(),
          reason: 'Earlier lifecycle saves must not overwrite the imported checkpoint');
    });

    // Browsing another slot must not retarget autosave before a successful load.
    final otherWorld = Checkpoint.create(
      world: WorldState.generate(seed: 99, size: 64),
      coreSource: checkpoint.coreSource,
    ).encode();
    await tester.runAsync(() => session.store.write('world_1', otherWorld) as Future<void>);
    await tester.tap(find.text('MENÚ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Archivo de mundos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.slot, 0, reason: 'Choosing a slot must not replace the active save destination');
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await session.saveQueue;
      expect(await session.store.read('world_1'), otherWorld);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await commitTap('Cargar este espacio', () => session.slot == 1 && !session.advancing);
    expect(session.world.seed, 99);
    expect(session.world.toJson(), Checkpoint.decode(otherWorld).world.toJson());

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
