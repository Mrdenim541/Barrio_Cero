import '../tool/fixtures.dart';
import 'dart:io';
import 'package:flame/game.dart';
import 'package:barrio_cero_eras/presentation/settlement_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/presentation/app.dart';
import 'package:barrio_cero_eras/persistence/checkpoint.dart';
import 'package:barrio_cero_eras/simulation/engine.dart' show WorldState, ScheduledEvent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  setUp(() async {
    documents = await Directory.systemTemp.createTemp('barrio-ui-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documents.path,
        );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.barriocero.eras/documents'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documents.delete(recursive: true);
  });
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets(
      'Start screen and world configuration remain usable at $width',
      (tester) async {
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
      },
    );
  }
  testWidgets(
    'Default opening creates and saves a real prehistoric community',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late dynamic screen;
      await tester.runAsync(() async {
        await tester.pumpWidget(const BarrioApp());
        screen = tester.state(find.byType(ErasScreen));
        await screen.initialization;
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('CREAR UN MUNDO')));
      await tester.pumpAndSettle();
      expect(find.text('Prehistoria'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '17');
      Future<void> commit(String text, bool Function() done) async {
        await tester.runAsync(() async {
          await tester.tap(find.text(text));
          final end = DateTime.now().add(const Duration(seconds: 15));
          while (!done()) {
            if (DateTime.now().isAfter(end)) {
              fail('No confirmed $text: ${screen.note}');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      await commit(
        'Fundar Barrio Cero',
        () => screen.world != null && !screen.advancing,
      );
      expect(screen.world.origin, 'prehistory');
      expect(screen.world.controlled.population, 24);
      expect(screen.world.controlled.resources['metal'], 0);
      expect(find.textContaining('Lidera Tara'), findsOneWidget);
      await tester.tap(find.text('Construir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Huerto'), findsNothing);
      expect(find.text('Refugio de pieles'), findsOneWidget);
      await tester.tap(find.text('Refugio de pieles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await commit(
        'Confirmar orden',
        () => screen.world.controlled.projects.length == 1 && !screen.advancing,
      );
      expect(screen.world.controlled.resources['wood'], 22);
      await commit('+ Día', () => screen.world.day == 1 && !screen.advancing);
      final checkpoint = Checkpoint.decode(
        File('${documents.path}/barrio_cero/world_0.json').readAsStringSync(),
      );
      expect(checkpoint.world.origin, 'prehistory');
      expect(checkpoint.world.controlled.projects.single.work!.remaining, 36);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets('Learning previews, commits and reopens at 320 with enlarged text', (tester) async {
    tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
    tester.platformDispatcher.textScaleFactorTestValue=1.3;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late dynamic screen;
    await tester.runAsync(() async {
      await tester.pumpWidget(const BarrioApp());screen=tester.state(find.byType(ErasScreen));
      await screen.initialization;await screen.session.createWorld(seed:42,size:64,origin:'reconstruction');
    });
    await tester.pump();await tester.pump(const Duration(milliseconds:500));
    final before=screen.world.canonical();
    await tester.ensureVisible(find.text('Más acciones'));await tester.tap(find.text('Más acciones'));await tester.pump();await tester.pump(const Duration(milliseconds:500));
    await tester.scrollUntilVisible(find.text('Formar aprendices'),100,scrollable:find.byType(Scrollable).last);await tester.pump();await tester.ensureVisible(find.text('Formar aprendices'));await tester.pump();await tester.tap(find.text('Formar aprendices'));
    await tester.pump();await tester.pump(const Duration(milliseconds:500));
    await tester.scrollUntilVisible(find.text('Oficios técnicos'),140,scrollable:find.byType(Scrollable).last);await tester.pump();await tester.pump(const Duration(milliseconds:500));await tester.ensureVisible(find.text('Oficios técnicos'));await tester.pump();await tester.tap(find.text('Oficios técnicos'));
    await tester.pump();await tester.pump(const Duration(milliseconds:500));
    await tester.scrollUntilVisible(find.text('Duración: 90 días'),100,scrollable:find.byType(Scrollable).last);await tester.pump();
    expect(find.text('Duración: 90 días'),findsOneWidget);expect(screen.world.canonical(),before);
    await tester.scrollUntilVisible(find.text('Confirmar orden'),100,scrollable:find.byType(Scrollable).last);await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Confirmar orden'));
      final deadline=DateTime.now().add(const Duration(seconds:15));
      while(screen.world.controlled.lessons.isEmpty||screen.advancing){
        if(DateTime.now().isAfter(deadline))fail('Training not committed: ${screen.note}');
        await Future<void>.delayed(const Duration(milliseconds:10));
      }
    });
    await tester.pump();await tester.pump(const Duration(milliseconds:500));
    final checkpoint=Checkpoint.decode(File('${documents.path}/barrio_cero/world_0.json').readAsStringSync());
    expect(checkpoint.world.controlled.lessons.single.work.remaining,180);
    expect(checkpoint.world.controlled.population,56);
    await tester.runAsync(() async {await screen.session.loadSlot(0);});await tester.pump();
    expect(screen.world.canonical(),checkpoint.world.canonical());expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pump(const Duration(milliseconds:50));
  });

  testWidgets('A real pending invitation appears before generic opportunities and previews its actual source', (tester) async {
    tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final world=WorldState.generate(seed:42,size:64);world.society('s1')!.health=30;fixturePath(world,'s1','s0');
    world.pending.add(ScheduledEvent('fixture-choice','content_choice','s0',3600000,data:{'eventId':'refugee_letter'}));
    final source=Checkpoint.create(world:world,coreSource:File('assets/content/core.json').readAsStringSync()).encode();
    late dynamic screen;
    await tester.runAsync(() async {await tester.pumpWidget(const BarrioApp());screen=tester.state(find.byType(ErasScreen));await screen.initialization;await screen.session.importCheckpoint(source);});
    await tester.pump();await tester.pump(const Duration(milliseconds:500));final before=screen.world.canonical();
    await tester.ensureVisible(find.text('Más acciones'));await tester.pump();await tester.tap(find.text('Más acciones'));await tester.pump();await tester.pump(const Duration(milliseconds:500));
    await tester.scrollUntilVisible(find.text('Decisiones'),120,scrollable:find.byType(Scrollable).last);await tester.pump();await tester.ensureVisible(find.text('Decisiones'));await tester.pump();await tester.tap(find.text('Decisiones'));await tester.pump();await tester.pump(const Duration(milliseconds:500));
    expect(find.text('Carta de refugio'),findsOneWidget);expect(tester.getTopLeft(find.text('Carta de refugio')).dy,lessThan(400));
    await tester.tap(find.widgetWithText(OutlinedButton,'Organizar la respuesta').first);await tester.pump();await tester.pump(const Duration(milliseconds:500));
    expect(find.textContaining('Grupo previsto: 5 adultos de Liga del Junco'),findsOneWidget);expect(screen.world.canonical(),before);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pump(const Duration(milliseconds:50));
  });

  testWidgets('Create, order, advance and reload a committed world at 320x640', (
    tester,
  ) async {
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
    await tester.tap(find.text('Prehistoria').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconstrucción').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '42');
    Future<void> commitTap(String label, bool Function() committed) async {
      await tester.runAsync(() async {
        await tester.tap(find.text(label));
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!committed()) {
          if (DateTime.now().isAfter(deadline)) {
            fail(
              'No confirmed transition after tapping $label; ${session.note}',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      // Flame continuously schedules frames; await the modal animation, not idle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    await commitTap(
      'Fundar Barrio Cero',
      () => session.world != null && !session.advancing,
    );
    expect(find.text('Año 1 · mes 1 · día 1'), findsOneWidget);
    expect(find.text('Construir'), findsOneWidget);
    // Essential time controls must remain readable on the smallest phone.
    expect(tester.getSize(find.text('Avanzar')).height, lessThan(24));
    expect(find.text('Barrio'), findsOneWidget);
    expect(find.text('Mundo'), findsOneWidget);
    expect(find.text('Historia'), findsOneWidget);
    expect(session.game.mode, 'Asentamiento');
    final beforeNavigation = session.world.toJson();
    await tester.tap(find.text('Mundo'));
    await tester.pump();
    expect(session.game.mode, 'Mundo');
    await tester.tap(find.text('Historia'));
    await tester.pump();
    expect(find.text('La memoria del mundo'), findsOneWidget);
    await tester.tap(find.text('Barrio'));
    await tester.pump();
    expect(
      session.world.toJson(),
      beforeNavigation,
      reason: 'Navigation must not advance or mutate the world',
    );
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Construir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Huerto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.world.commandReceipts, isEmpty);
    expect(find.text('Duración: 12 días'), findsOneWidget);
    await commitTap(
      'Confirmar orden',
      () => session.world.commandReceipts.isNotEmpty && !session.advancing,
    );
    expect(
      session.world.society(session.world.controlledId).projects.length,
      1,
    );
    await commitTap(
      '+ Día',
      () => session.world.day == 1 && !session.advancing,
    );
    expect(find.text('Año 1 · mes 1 · día 2'), findsOneWidget);
    late String saved;
    await tester.runAsync(() async {
      saved = await File(
        '${documents.path}/barrio_cero/world_0.json',
      ).readAsString();
    });
    final checkpoint = Checkpoint.decode(saved);
    expect(checkpoint.world.day, 1);
    expect(checkpoint.world.commandReceipts.length, 1);
    expect(
      checkpoint.world.society(checkpoint.world.controlledId)!.projects.length,
      1,
    );

    // Opening Android's picker can enqueue multiple lifecycle saves before an
    // import commits. They must never overwrite the imported world afterward.
    await commitTap(
      '+ Día',
      () => session.world.day == 2 && !session.advancing,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.barriocero.eras/documents'),
          (call) async {
            expect(call.method, 'importDocument');
            session.didChangeAppLifecycleState(AppLifecycleState.inactive);
            session.didChangeAppLifecycleState(AppLifecycleState.paused);
            session.didChangeAppLifecycleState(AppLifecycleState.resumed);
            return saved;
          },
        );
    await tester.tap(find.text('MENÚ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Archivo de mundos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await commitTap(
      'Importar partida (JSON)',
      () => session.note == 'Historia importada.' && !session.advancing,
    );
    expect(session.world.day, 1);
    await tester.runAsync(() async {
      await session.saveQueue;
      final persisted = Checkpoint.decode(
        await session.store.read('world_0') as String,
      );
      expect(
        persisted.world.toJson(),
        checkpoint.world.toJson(),
        reason:
            'Earlier lifecycle saves must not overwrite the imported checkpoint',
      );
    });

    // Browsing another slot must not retarget autosave before a successful load.
    final otherWorld = Checkpoint.create(
      world: WorldState.generate(seed: 99, size: 64),
      coreSource: checkpoint.coreSource,
    ).encode();
    await tester.runAsync(
      () => session.store.write('world_1', otherWorld) as Future<void>,
    );
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
    expect(
      session.slot,
      0,
      reason: 'Choosing a slot must not replace the active save destination',
    );
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await session.saveQueue;
      expect(await session.store.read('world_1'), otherWorld);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await commitTap(
      'Cargar este espacio',
      () => session.slot == 1 && !session.advancing,
    );
    expect(session.world.seed, 99);
    expect(
      session.world.toJson(),
      Checkpoint.decode(otherWorld).world.toJson(),
    );

    // Destroy the session and reconstruct it from disk, as after process restart.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await tester.pumpWidget(const BarrioApp());
      session = tester.state(find.byType(ErasScreen));
      await session.initialization;
    });
    await tester.pumpAndSettle();
    await commitTap(
      'Continuar historia',
      () => session.world != null && !session.advancing,
    );
    expect(session.world.toJson(), checkpoint.world.toJson());
    expect(find.text('Año 1 · mes 1 · día 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('Active navigation and sheets at $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late dynamic screen;
      await tester.runAsync(() async {
        await tester.pumpWidget(const BarrioApp());
        screen = tester.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.createWorld(seed: 42, size: 64);
      });
      await tester.pump();
      await tester.tap(find.text('Barrio'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Mundo'));
      await tester.pump();
      await tester.tap(find.text('Historia'));
      await tester.pump();
      expect(find.text('La memoria del mundo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Barrio'));
      await tester.pump();
      await tester.ensureVisible(find.text('Comunidad'));
      await tester.tap(find.text('Comunidad'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Habitantes destacados'), findsOneWidget);
      expect(find.textContaining('bornDay'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Tap real local building and person without changing simulation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late dynamic screen;
      await tester.runAsync(() async {
        await tester.pumpWidget(const BarrioApp());
        screen = tester.state(find.byType(ErasScreen));
        await screen.initialization;
        await screen.session.createWorld(seed: 42, size: 64);
      });
      await tester.pump();
      await tester.tap(find.text('Barrio'));
      await tester.pump(const Duration(milliseconds: 500));
      final before = screen.world.toJson();
      final map = tester.getRect(
        find.byWidgetPredicate((widget) => widget is GameWidget),
      );
      final scene = SettlementScene(screen.world.societies.first.toJson());
      for (final kind in ['site', 'person']) {
        final entity = scene.entities.firstWhere((e) => e.kind == kind);
        final point = scene.toScreen(
          entity.bounds.center,
          map.size,
          screen.game.pan,
          screen.game.zoom,
        );
        await tester.tapAt(map.topLeft + point);
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.text(kind == 'site' ? 'Construir otro' : 'Ver comunidad'),
          findsOneWidget,
        );
        expect(screen.world.toJson(), before);
        await tester.tapAt(const Offset(10, 80));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Legacy game upgrade is reachable, optional and preserves a rules backup',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late dynamic screen;
      late String original;
      await tester.runAsync(() async {
        await tester.pumpWidget(const BarrioApp());
        screen = tester.state(find.byType(ErasScreen));
        await screen.initialization;
        original = Checkpoint.create(
          world: WorldState.generate(size: 64, fixedMaterials: false),
          coreSource: File('assets/content/core.json').readAsStringSync(),
        ).encode();
        await screen.store.write('world_0', original);
        await screen.session.loadSlot(0);
      });
      await tester.pump();
      await tester.tap(find.text('Barrio'));
      await tester.pump(const Duration(milliseconds: 500));
      Future<void> openUpgrade() async {
        await tester.tap(find.text('MENÚ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.ensureVisible(
          find.text('Actualizar reglas de la partida'),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Actualizar reglas de la partida'));
          final deadline = DateTime.now().add(const Duration(seconds: 5));
          while (find.text('Copiar y actualizar').evaluate().isEmpty) {
            if (DateTime.now().isAfter(deadline)) break;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump();
          }
        });
        await tester.pump(const Duration(milliseconds: 500));
      }

      await openUpgrade();
      expect(
        find.text('Copiar y actualizar'),
        findsOneWidget,
        reason: screen.note,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Conservar reglas actuales'));
        await screen.session.idle;
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(screen.world.controlled.materialRules, 1);
      await tester.runAsync(() async {
        expect(await screen.store.read('world_0'), original);
      });
      await openUpgrade();
      await tester.runAsync(() async {
        await tester.tap(find.text('Copiar y actualizar'));
        await screen.session.idle;
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(screen.world.controlled.materialRules, 2);
      expect(screen.world.entities, isNotNull);
      expect(screen.world.ruleChanges.length, 1);
      await tester.runAsync(() async {
        final hash = screen.world.ruleChanges.last['sourceSha256'];
        expect(await screen.store.read('rules_0_$hash'), original);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
