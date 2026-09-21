import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/controllers/editor_controller.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/frame_exporter.dart';

void main() {
  const exporter = FrameExporter();

  test('limpia caracteres no validos del nombre exportado', () {
    expect(
      exporter.sanitizeFileName(' Mi animación: 01 / prueba '),
      'Mi_animación_01_prueba',
    );
  });

  test('usa un nombre seguro cuando el proyecto no tiene nombre util', () {
    expect(exporter.sanitizeFileName('***'), 'Velyntora');
  });

  testWidgets('renderiza el fotograma como PNG valido', (tester) async {
    final project = AnimationProject(name: 'Exportar', width: 64, height: 36);
    final controller = EditorController(project)..setStabilization(0);
    controller.beginStroke(const Offset(0.1, 0.1));
    controller.extendStroke(const Offset(0.9, 0.9));

    final bytes = await tester.runAsync(() => exporter.renderPng(controller));
    expect(bytes, isNotNull);
    final png = bytes!;
    expect(png.length, greaterThan(100));
    expect(png.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });

  testWidgets('renderiza otro fotograma sin cambiar la seleccion', (
    tester,
  ) async {
    final controller = EditorController(
      AnimationProject(name: 'Secuencia', width: 64, height: 36),
    )..selectFrame(2);

    final bytes = await tester.runAsync(
      () => exporter.renderFramePng(controller, 0),
    );

    expect(bytes, isNotNull);
    expect(controller.activeFrame, 2);
  });

  test('rechaza un numero de fotograma fuera del proyecto', () async {
    final controller = EditorController(AnimationProject(name: 'Rango'));
    await expectLater(
      exporter.renderFramePng(controller, controller.project.frameCount),
      throwsRangeError,
    );
  });

  testWidgets('la exportacion no incluye piel de cebolla', (tester) async {
    final painted = EditorController(
      AnimationProject(name: 'Con dibujo', width: 64, height: 36),
    )..setStabilization(0);
    painted.beginStroke(const Offset(0.1, 0.1));
    painted.extendStroke(const Offset(0.9, 0.9));
    painted
      ..selectFrame(1)
      ..setOnionSkin(true);

    final blank = EditorController(
      AnimationProject(name: 'En blanco', width: 64, height: 36),
    );
    final exported = await tester.runAsync(
      () => exporter.renderFramePng(painted, 1),
    );
    final expected = await tester.runAsync(
      () => exporter.renderFramePng(blank, 1),
    );

    expect(exported, expected);
  });

  testWidgets('exporta un proyecto vertical con sus dimensiones', (
    tester,
  ) async {
    final controller = EditorController(
      AnimationProject(name: 'Vertical', width: 72, height: 128),
    );

    final bytes = await tester.runAsync(() => exporter.renderPng(controller));
    final png = bytes!;
    int readUint32(int offset) =>
        (png[offset] << 24) |
        (png[offset + 1] << 16) |
        (png[offset + 2] << 8) |
        png[offset + 3];

    expect(readUint32(16), 72);
    expect(readUint32(20), 128);
  });

  testWidgets('renderiza RGBA completo para el codificador GIF', (
    tester,
  ) async {
    final controller = EditorController(
      AnimationProject(name: 'RGBA', width: 64, height: 64),
    );

    final bytes = await tester.runAsync(
      () => exporter.renderFrameRgba(controller, 0),
    );

    expect(bytes, isNotNull);
    expect(bytes, hasLength(64 * 64 * 4));
  });
}
