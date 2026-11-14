import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/app.dart';

void main() {
  testWidgets(
    'Atlas navigation keeps the map dominant and every view observational',
    (t) async {
      final documents = (await t.runAsync(
        () => Directory.systemTemp.createTemp('barrio-atlas-ui-'),
      ))!;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => documents.path);
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      const boundaryKey = ValueKey('atlas-preview');
      late dynamic screen;
      await t.runAsync(() async {
        await t.pumpWidget(
          const RepaintBoundary(key: boundaryKey, child: BarrioApp()),
        );
        screen = t.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.createWorld(
          seed: 73,
          size: 96,
          origin: 'prehistory',
          extraordinary: false,
        );
      });
      await t.pump();
      // Asset callbacks started in the widget zone also need test frames.
      for (
        var attempt = 0;
        attempt < 60 && screen.game.terrainCache.landscape == null;
        attempt++
      ) {
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await t.pump();
      }
      expect(screen.game.terrainCache.landscape, isNotNull);
      final before = screen.world.canonical();
      Future<void> capture(String name) async {
        await t.pump(const Duration(milliseconds: 100));
        final folder = Platform.environment['BARRIO_CAPTURE_DIR'];
        if (folder == null) return;
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await t.pump();
        Directory(folder).createSync(recursive: true);
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(Uri.file('$folder/$name.png')),
        );
      }

      expect(find.text('PLANETA'), findsOneWidget);
      expect(
        t.getRect(find.byWidgetPredicate((w) => w is GameWidget)).height,
        greaterThan(780 * .42),
      );
      await capture('01-host-planet');
      await t.tap(find.text('Ver región'));
      await t.pump();
      expect(find.text('REGIÓN'), findsOneWidget);
      await capture('02-host-region');
      await t.runAsync(() async {
        await t.tap(find.text('Seguir'));
        await screen.viewStore.read('view_0');
      });
      await t.pump();
      expect(
        find.text(
          'Siguiendo a ${screen.world.societies.first.people.first.name}',
        ),
        findsOneWidget,
      );
      expect(find.text('ASENTAMIENTO'), findsOneWidget);
      await capture('03-host-follow');
      await t.runAsync(() async {
        await t.tap(find.byTooltip('Ver todo el asentamiento'));
        await screen.viewStore.read('view_0');
      });
      await t.pump();
      await capture('04-host-settlement');
      expect(screen.world.canonical(), before);
      expect(screen.world.controlledId, isNull);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(() async {
        await screen.viewStore.read('view_0');
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await t.runAsync(() => documents.delete(recursive: true));
    },
  );
}
