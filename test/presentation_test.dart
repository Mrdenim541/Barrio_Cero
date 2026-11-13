import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/app.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('Start screen and world configuration remain usable at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const BarrioApp());
      await tester.pumpAndSettle();
      expect(find.text('CREAR UN MUNDO'), findsOneWidget);
      await tester.tap(find.text('CREAR UN MUNDO'));
      await tester.pumpAndSettle();
      expect(find.text('Semilla reproducible'), findsOneWidget);
      expect(find.text('Fundar Barrio Cero'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Continuar historia'), findsOneWidget);
    });
  }
}
