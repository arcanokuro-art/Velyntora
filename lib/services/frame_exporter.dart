import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../controllers/editor_controller.dart';
import '../widgets/drawing_canvas.dart';

class FrameExporter {
  const FrameExporter();

  Future<Uint8List> renderPng(EditorController controller) async {
    return renderFramePng(controller, controller.activeFrame);
  }

  Future<Uint8List> renderFramePng(
    EditorController controller,
    int frame,
  ) async {
    final project = controller.project;
    if (frame < 0 || frame >= project.frameCount) {
      throw RangeError.range(frame, 0, project.frameCount - 1, 'frame');
    }
    final size = ui.Size(project.width.toDouble(), project.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    AnimationCanvasPainter(
      controller,
      showGuides: false,
      frameOverride: frame,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(project.width, project.height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (data == null) throw StateError('No se pudo codificar la imagen PNG.');
    return data.buffer.asUint8List();
  }

  Future<File> exportCurrentFrame(EditorController controller) async {
    final bytes = await renderPng(controller);
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/Velyntora/Exportaciones');
    await directory.create(recursive: true);
    final safeName = sanitizeFileName(controller.project.name);
    final frame = (controller.activeFrame + 1).toString().padLeft(4, '0');
    return File('${directory.path}/${safeName}_fotograma_$frame.png')
        .writeAsBytes(bytes, flush: true);
  }

  Future<List<File>> exportPngSequence(EditorController controller) async {
    final documents = await getApplicationDocumentsDirectory();
    final safeName = sanitizeFileName(controller.project.name);
    final directory = Directory(
      '${documents.path}/Velyntora/Exportaciones/${safeName}_secuencia',
    );
    await directory.create(recursive: true);

    final files = <File>[];
    for (var frame = 0; frame < controller.project.frameCount; frame++) {
      final bytes = await renderFramePng(controller, frame);
      final number = (frame + 1).toString().padLeft(4, '0');
      final file = File('${directory.path}/${safeName}_$number.png');
      files.add(await file.writeAsBytes(bytes, flush: true));
    }
    return files;
  }

  String sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'Velyntora' : sanitized;
  }
}
