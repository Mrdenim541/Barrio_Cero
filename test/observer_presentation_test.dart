import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/app.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  late Directory documents;
  setUp(() async {
    documents = await Directory.systemTemp.createTemp('observer-ui-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documents.delete(recursive: true);
  });
  Future<void> animate(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  void size(WidgetTester t) {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    t.view.physicalSize = const Size(360, 720);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets(
    'A chosen protagonist persists separately; exploration pauses only the camera',
    (t) async {
      size(t);
      late dynamic screen;
      await t.runAsync(() async {
        await t.pumpWidget(const BarrioApp());
        screen = t.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.createWorld(
          seed: 17,
          size: 64,
          origin: 'prehistory',
        );
      });
      await t.pump();
      final before = screen.world.canonical();
      final person = screen.world.societies[1].people.last;
      await t.tap(find.text('MENÚ'));
      await animate(t);
      await t.tap(find.text('Elegir protagonista'));
      await animate(t);
      await t.ensureVisible(find.text(person.name));
      await t.runAsync(() async {
        await t.tap(find.text(person.name));
        await screen.viewStore.read('view_0');
      });
      await animate(t);
      expect(screen.selected, 's1');
      expect(screen.game.followedIndividualId, person.id);
      expect(find.text('Siguiendo a ${person.name}'), findsOneWidget);
      expect(screen.world.canonical(), before);

      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(() async {
        await t.pumpWidget(const BarrioApp());
        screen = t.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.loadSlot(0);
        await screen.viewRestoration;
      });
      await animate(t);
      expect(screen.game.followedIndividualId, person.id);
      expect(screen.world.canonical(), before);
      final map = t.getRect(find.byWidgetPredicate((w) => w is GameWidget));
      await t.runAsync(() async {
        await t.dragFrom(map.center, const Offset(48, 30));
        await screen.viewStore.read('view_0');
      });
      await t.pump();
      expect(screen.following, isFalse);
      expect(screen.protagonist.individualId, person.id);
      expect(screen.game.followedIndividualId, isNull);
      await t.runAsync(() async {
        await t.tap(find.text('Seguir'));
        await screen.viewStore.read('view_0');
      });
      await t.pump();
      expect(screen.game.followedIndividualId, person.id);
      expect(screen.selected, 's1');
      expect(screen.world.canonical(), before);
      expect(screen.world.controlledId, isNull);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'A pinch reaches the real selected settlement and returns to the planet without a command',
    (t) async {
      size(t);
      late dynamic screen;
      await t.runAsync(() async {
        await t.pumpWidget(const BarrioApp());
        screen = t.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.createWorld(
          seed: 17,
          size: 64,
          origin: 'prehistory',
        );
      });
      await t.pump();
      await t.tap(find.text('Mundo'));
      await animate(t);
      await t.tap(find.byTooltip('Centrar comunidad'));
      await t.pump();
      final before = screen.world.canonical();
      final center = t
          .getRect(find.byWidgetPredicate((w) => w is GameWidget))
          .center;
      final left = await t.startGesture(
        center - const Offset(25, 0),
        pointer: 1,
      );
      final right = await t.startGesture(
        center + const Offset(25, 0),
        pointer: 2,
      );
      await left.moveTo(center - const Offset(80, 0));
      await right.moveTo(center + const Offset(80, 0));
      await t.pump();
      await left.moveTo(center - const Offset(155, 0));
      await right.moveTo(center + const Offset(155, 0));
      await t.pump();
      await left.up();
      await right.up();
      expect(screen.game.mode, 'Región');
      final nearerLeft = await t.startGesture(
        center - const Offset(25, 0),
        pointer: 5,
      );
      final nearerRight = await t.startGesture(
        center + const Offset(25, 0),
        pointer: 6,
      );
      await nearerLeft.moveTo(center - const Offset(80, 0));
      await nearerRight.moveTo(center + const Offset(80, 0));
      await t.pump();
      await nearerLeft.moveTo(center - const Offset(155, 0));
      await nearerRight.moveTo(center + const Offset(155, 0));
      await t.pump();
      await nearerLeft.up();
      await nearerRight.up();
      expect(screen.game.mode, 'Asentamiento');
      expect(screen.selected, 's0');
      expect(screen.world.canonical(), before);
      final outLeft = await t.startGesture(
        center - const Offset(60, 0),
        pointer: 3,
      );
      final outRight = await t.startGesture(
        center + const Offset(60, 0),
        pointer: 4,
      );
      await outLeft.moveTo(center - const Offset(30, 0));
      await outRight.moveTo(center + const Offset(30, 0));
      await t.pump();
      await outLeft.moveTo(center - const Offset(3, 0));
      await outRight.moveTo(center + const Offset(3, 0));
      await t.pump();
      await outLeft.up();
      await outRight.up();
      expect(screen.game.mode, 'Mundo');
      expect(screen.world.canonical(), before);
      expect(screen.world.controlledId, isNull);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Old direction is changed explicitly; inspecting inhabitants preserves playback and a quote resumes it',
    (t) async {
      size(t);
      final world = WorldState.generate(
        seed: 17,
        size: 64,
        origin: 'prehistory',
      );
      final source = Checkpoint.create(
        world: world,
        coreSource: File('assets/content/core.json').readAsStringSync(),
      ).encode();
      late dynamic screen;
      await t.runAsync(() async {
        await t.pumpWidget(const BarrioApp());
        screen = t.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.importCheckpoint(source);
      });
      await t.pump();
      expect(screen.world.controlledId, 's0');
      await t.runAsync(() async {
        await t.tap(find.text('Dejar actuar al mundo'));
        await screen.session.idle;
      });
      await animate(t);
      expect(screen.world.controlledId, isNull);
      expect(screen.stopCrisis, isFalse);
      expect(screen.game.mode, 'Mundo');
      expect(find.text('Intervenir'), findsOneWidget);
      await t.tap(find.byTooltip('Cerrar mensaje'));
      await t.pump();
      await t.tap(find.text('Seguir'));
      await t.pump();
      await t.tap(find.byTooltip('Ver todo el asentamiento'));
      await t.pump();
      await t.runAsync(() async {
        await t.tap(find.byIcon(Icons.play_arrow));
        await screen.session.idle;
      });
      await t.pump();
      final before = screen.world.canonical();
      final map = t.getRect(find.byWidgetPredicate((w) => w is GameWidget));
      final scene = SettlementScene(screen.world.societies.first.toJson());
      final person = scene.entities.firstWhere((e) => e.kind == 'person');
      final point = screen.game.entityScreenPosition('s0', person);
      await t.tapAt(map.topLeft + point);
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(
        screen.timer.isActive,
        isTrue,
        reason: 'Inspecting an inhabitant must not stop their world',
      );
      expect(screen.world.canonical(), before);
      await t.tapAt(const Offset(8, 8));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(find.byIcon(Icons.pause));
      await t.pump();
      // Start playback before selecting the quote; closing it must restore that state.
      await t.tap(find.byIcon(Icons.play_arrow));
      await t.pump();
      await t.tap(find.text('Intervenir'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.text('Construir').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.ensureVisible(find.text('Refugio de pieles'));
      await t.tap(find.text('Refugio de pieles'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(screen.timer, isNull);
      expect(find.text('Confirmar orden'), findsOneWidget);
      await t.tapAt(const Offset(8, 8));
      await animate(t);
      await t.runAsync(() async {
        await screen.session.idle;
        final end = DateTime.now().add(const Duration(seconds: 5));
        while (screen.timer == null) {
          if (DateTime.now().isAfter(end)) break;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(
        screen.timer?.isActive,
        isTrue,
        reason: 'Cancelling an optional quote must restore playback',
      );
      await t.tap(find.byIcon(Icons.pause));
      await t.pump();
      expect(screen.world.controlledId, isNull);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
