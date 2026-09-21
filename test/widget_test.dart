import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/main.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/screens/editor_screen.dart';
import 'package:velyntora/widgets/drawing_canvas.dart';

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

  testWidgets('la linea de tiempo muestra miniaturas reales', (tester) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = AnimationProject(name: 'Miniaturas');
    await tester.pumpWidget(MaterialApp(home: EditorScreen(project: project)));
    await tester.pump();

    expect(find.byType(FrameThumbnail), findsNWidgets(project.frameCount));
    for (var frame = 0; frame < project.frameCount; frame++) {
      expect(
        find.byKey(ValueKey<String>('frame-thumbnail-$frame')),
        findsOneWidget,
      );
    }
  });

  testWidgets('cada miniatura renderiza su propio fotograma', (tester) async {
    final project = AnimationProject(name: 'Fotogramas');
    await tester.pumpWidget(MaterialApp(home: EditorScreen(project: project)));
    await tester.pump();

    final thumbnail = find.byKey(
      const ValueKey<String>('frame-thumbnail-2'),
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(of: thumbnail, matching: find.byType(CustomPaint)),
    );
    final painter = paint.painter! as AnimationCanvasPainter;

    expect(painter.frameOverride, 2);
    expect(painter.showGuides, isFalse);
  });
}
