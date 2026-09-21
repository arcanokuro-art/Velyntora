import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/main.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/screens/editor_screen.dart';
import 'package:velyntora/screens/home_screen.dart';
import 'package:velyntora/services/project_storage.dart';
import 'package:velyntora/widgets/drawing_canvas.dart';

void main() {
  testWidgets('muestra la galería de Velyntora', (tester) async {
    final directory = await Directory.systemTemp.createTemp('velyntora_widget_');
    addTearDown(() => directory.delete(recursive: true));
    await tester.pumpWidget(
      VelyntoraApp(storage: ProjectStorage(rootDirectory: directory)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Velyntora'), findsOneWidget);
    expect(find.text('Tus proyectos'), findsOneWidget);
    expect(find.text('Nuevo proyecto'), findsOneWidget);
    expect(find.text('Todavía no hay proyectos guardados.'), findsOneWidget);
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

  testWidgets('la galeria muestra proyectos guardados', (tester) async {
    final directory = await Directory.systemTemp.createTemp('velyntora_gallery_');
    addTearDown(() => directory.delete(recursive: true));
    final storage = ProjectStorage(rootDirectory: directory);
    await storage.save(AnimationProject(name: 'Proyecto recuperado', fps: 24));

    await tester.pumpWidget(MaterialApp(home: HomeScreen(storage: storage)));
    await tester.pumpAndSettle();

    expect(find.text('Proyecto recuperado'), findsOneWidget);
    expect(find.textContaining('24 FPS'), findsOneWidget);
  });

  testWidgets('elimina un proyecto confirmado desde la galeria', (tester) async {
    final directory = await Directory.systemTemp.createTemp('velyntora_delete_');
    addTearDown(() => directory.delete(recursive: true));
    final storage = ProjectStorage(rootDirectory: directory);
    final file = await storage.save(AnimationProject(name: 'Descartar'));

    await tester.pumpWidget(MaterialApp(home: HomeScreen(storage: storage)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eliminar proyecto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(await file.exists(), isFalse);
    expect(find.text('Todavía no hay proyectos guardados.'), findsOneWidget);
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

  testWidgets('guarda automaticamente los cambios del editor', (tester) async {
    final directory = await Directory.systemTemp.createTemp('velyntora_autosave_');
    addTearDown(() => directory.delete(recursive: true));
    final storage = ProjectStorage(rootDirectory: directory);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(
          project: AnimationProject(name: 'Automático'),
          storage: storage,
          autoSaveDelay: const Duration(milliseconds: 10),
        ),
      ),
    );
    await tester.tap(find.text('12 FPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24 FPS'));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(await storage.listProjects(), hasLength(1));
  });

  testWidgets('advierte antes de salir con cambios pendientes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EditorScreen(project: AnimationProject(name: 'Aviso'))),
    );
    await tester.tap(find.text('12 FPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24 FPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver a proyectos'));
    await tester.pumpAndSettle();

    expect(find.text('Cambios sin guardar'), findsOneWidget);
    expect(find.text('Guardar y salir'), findsOneWidget);
  });
}
import 'dart:io';
