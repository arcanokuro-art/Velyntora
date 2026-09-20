import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/main.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/screens/editor_screen.dart';

void main() {
  testWidgets('muestra la galería de Velyntora', (tester) async {
    await tester.pumpWidget(const VelyntoraApp());
    expect(find.text('Velyntora'), findsOneWidget);
    expect(find.text('Tus proyectos'), findsOneWidget);
    expect(find.text('Nuevo proyecto'), findsOneWidget);
  });

  testWidgets('editor cabe en una pantalla Android horizontal', (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: EditorScreen(project: AnimationProject(name: 'Android'))),
    );
    await tester.pump();
    expect(find.text('Android'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
