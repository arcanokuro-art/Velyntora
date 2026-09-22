import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/controllers/editor_controller.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/frame_exporter.dart';
import 'package:velyntora/services/video_encoder.dart';

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

  testWidgets('exporta todos los fotogramas a MP4 y limpia los temporales', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('velyntora_mp4_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final encoder = _FakeVideoEncoder();
    final mp4Exporter = FrameExporter(
      videoEncoder: encoder,
      documentsDirectory: Directory('${root.path}/documents'),
      temporaryDirectory: Directory('${root.path}/temporary'),
    );
    final project = AnimationProject(
      name: 'Mi película',
      width: 64,
      height: 64,
      fps: 24,
    )..frameCount = 2;

    final file = await tester.runAsync(
      () => mp4Exporter.exportMp4(EditorController(project)),
    );

    expect(file, isNotNull);
    expect(file!.path, endsWith('Mi_película.mp4'));
    expect(file.lengthSync(), greaterThan(0));
    expect(encoder.frameCount, 2);
    expect(encoder.fps, 24);
    expect(encoder.width, 64);
    expect(encoder.height, 64);
    expect(Directory(encoder.sequenceDirectory!).existsSync(), isFalse);
  });

  testWidgets('limpia los temporales cuando falla el codificador MP4', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('velyntora_mp4_error_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final encoder = _FakeVideoEncoder(fail: true);
    final mp4Exporter = FrameExporter(
      videoEncoder: encoder,
      documentsDirectory: Directory('${root.path}/documents'),
      temporaryDirectory: Directory('${root.path}/temporary'),
    );
    final project = AnimationProject(name: 'Error', width: 64, height: 64)
      ..frameCount = 1;

    await tester.runAsync(
      () => expectLater(
        mp4Exporter.exportMp4(EditorController(project)),
        throwsStateError,
      ),
    );

    expect(Directory(encoder.sequenceDirectory!).existsSync(), isFalse);
  });
}

class _FakeVideoEncoder extends VideoEncoder {
  _FakeVideoEncoder({this.fail = false});

  final bool fail;
  int frameCount = 0;
  int? fps;
  int? width;
  int? height;
  String? sequenceDirectory;

  @override
  Future<void> encode({
    required String inputPattern,
    required String outputPath,
    required int fps,
    required int width,
    required int height,
    required List<MediaAsset> audioAssets,
  }) async {
    sequenceDirectory = File(inputPattern).parent.path;
    frameCount = Directory(sequenceDirectory!)
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.png'))
        .length;
    this.fps = fps;
    this.width = width;
    this.height = height;
    if (fail) throw StateError('fallo simulado');
    await File(outputPath).writeAsBytes(<int>[0, 0, 0, 24, 102, 116, 121, 112]);
  }
}
