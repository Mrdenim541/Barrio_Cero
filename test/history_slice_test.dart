import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:barrio_cero_eras/content/content_pack.dart';
import 'package:barrio_cero_eras/session/history_slice.dart';
import 'package:barrio_cero_eras/simulation/engine.dart';

void main() {
  final content = ContentPack.parse(
    File('assets/content/core.json').readAsStringSync(),
  ).data;
  Simulation scenario() => Simulation(
    WorldState.generate(seed: 17, size: 64, origin: 'prehistory')
      ..controlledId = null,
  )..registerContent(content);

  test(
    'A year can use one checkpoint without changing any daily result',
    () async {
      final monthly = scenario();
      final grouped = scenario();
      for (var i = 0; i < 12; i++) {
        monthly.advance(
          const AdvanceRequest(days: 30, delegateDecisions: true),
        );
      }
      final result = await advanceHistorySlice(
        grouped,
        targetDay: 360,
        stopOnCrisis: false,
        budget: const Duration(minutes: 1),
      );
      expect(result.done, isTrue);
      expect(result.cancelled, isFalse);
      expect(result.advancedDays, 360);
      expect(grouped.world.canonical(), monthly.world.canonical());
    },
  );

  test(
    'Different time budgets and checkpoint copies keep the same world',
    () async {
      final reference = scenario()
        ..advance(const AdvanceRequest(days: 720, delegateDecisions: true));
      var grouped = scenario();
      var slices = 0;
      while (grouped.world.day < 720) {
        final result = await advanceHistorySlice(
          grouped,
          targetDay: 720,
          stopOnCrisis: false,
          maxDays: 240,
          budget: slices.isEven ? Duration.zero : const Duration(minutes: 1),
        );
        expect(result.advancedDays, inInclusiveRange(1, 240));
        grouped = Simulation(WorldState.fromJson(grouped.world.toJson()))
          ..registerContent(content);
        slices++;
      }
      expect(grouped.world.canonical(), reference.world.canonical());
      expect(slices, lessThan(24));
    },
  );

  test(
    'Cancel is received between quanta and keeps a complete daily state',
    () async {
      final simulation = scenario();
      final reference = scenario()
        ..advance(const AdvanceRequest(days: 30, delegateDecisions: true));
      var cancel = false;
      final timer = Timer(Duration.zero, () => cancel = true);
      addTearDown(timer.cancel);
      final result = await advanceHistorySlice(
        simulation,
        targetDay: 36000,
        stopOnCrisis: false,
        budget: const Duration(minutes: 1),
        isCancelled: () => cancel,
      );
      expect(result.cancelled, isTrue);
      expect(result.done, isFalse);
      expect(result.advancedDays, 30);
      expect(simulation.world.canonical(), reference.world.canonical());
    },
  );

  test(
    'Crisis and invalid budgets stop without silently skipping history',
    () async {
      final simulation = scenario();
      for (final society in simulation.world.societies) {
        society.resources['food'] = 0;
        society.resources['water'] = 0;
      }
      final reference = Simulation(
        WorldState.fromJson(simulation.world.toJson()),
      )..registerContent(content);
      final advanced = reference.advanceDays(30, stopOnCrisis: true);
      final result = await advanceHistorySlice(
        simulation,
        targetDay: 36000,
        stopOnCrisis: true,
      );
      expect(result.done, isTrue);
      expect(result.advancedDays, advanced);
      expect(simulation.world.canonical(), reference.world.canonical());
      final before = simulation.world.canonical();
      await expectLater(
        advanceHistorySlice(
          simulation,
          targetDay: 36000,
          stopOnCrisis: false,
          maxDays: 0,
        ),
        throwsArgumentError,
      );
      expect(simulation.world.canonical(), before);
    },
  );
}
