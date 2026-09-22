import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';
import '../widgets/drawing_canvas.dart';
import 'gif_encoder.dart';
import 'video_encoder.dart';

class FrameExporter {
  const FrameExporter({
    this.videoEncoder = const FfmpegVideoEncoder(),
    this.documentsDirectory,
    this.temporaryDirectory,
  });

  final VideoEncoder videoEncoder;
  final Directory? documentsDirectory;
  final Directory? temporaryDirectory;

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
    await controller.loadMediaImages();
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

  Future<Uint8List> renderFrameRgba(
    EditorController controller,
    int frame,
  ) async {
    final project = controller.project;
    if (frame < 0 || frame >= project.frameCount) {
      throw RangeError.range(frame, 0, project.frameCount - 1, 'frame');
    }
    await controller.loadMediaImages();
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
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    if (data == null) throw StateError('No se pudo leer el fotograma.');
    return data.buffer.asUint8List();
  }

  Future<File> exportCurrentFrame(EditorController controller) async {
    final bytes = await renderPng(controller);
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/Velyntora/Exportaciones');
    await directory.create(recursive: true);
    final safeName = sanitizeFileName(controller.project.name);
    final frame = (controller.activeFrame + 1).toString().padLeft(4, '0');
    return File(
      '${directory.path}/${safeName}_fotograma_$frame.png',
    ).writeAsBytes(bytes, flush: true);
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

  Future<File> exportAnimatedGif(EditorController controller) async {
    final project = controller.project;
    final frames = <Uint8List>[];
    for (var frame = 0; frame < project.frameCount; frame++) {
      frames.add(await renderFrameRgba(controller, frame));
    }
    final bytes = const GifEncoder().encode(
      width: project.width,
      height: project.height,
      rgbaFrames: frames,
      fps: project.fps,
    );
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/Velyntora/Exportaciones');
    await directory.create(recursive: true);
    final safeName = sanitizeFileName(project.name);
    return File(
      '${directory.path}/$safeName.gif',
    ).writeAsBytes(bytes, flush: true);
  }

  Future<File> exportMp4(EditorController controller) async {
    final project = controller.project;
    final temporary = temporaryDirectory ?? await getTemporaryDirectory();
    final sequenceDirectory = Directory(
      '${temporary.path}/Velyntora/mp4_${DateTime.now().microsecondsSinceEpoch}',
    );
    await sequenceDirectory.create(recursive: true);
    try {
      for (var frame = 0; frame < project.frameCount; frame++) {
        final bytes = await renderFramePng(controller, frame);
        final number = (frame + 1).toString().padLeft(6, '0');
        await File(
          '${sequenceDirectory.path}/frame_$number.png',
        ).writeAsBytes(bytes, flush: true);
      }

      final documents =
          documentsDirectory ?? await getApplicationDocumentsDirectory();
      final exportDirectory = Directory(
        '${documents.path}/Velyntora/Exportaciones',
      );
      await exportDirectory.create(recursive: true);
      final output = File(
        '${exportDirectory.path}/${sanitizeFileName(project.name)}.mp4',
      );
      if (await output.exists()) await output.delete();
      await videoEncoder.encode(
        inputPattern: '${sequenceDirectory.path}/frame_%06d.png',
        outputPath: output.path,
        fps: project.fps,
        width: project.width,
        height: project.height,
        audioAssets: project.mediaAssets
            .where((asset) => asset.type == MediaType.audio)
            .toList(),
      );
      if (!await output.exists() || await output.length() == 0) {
        throw StateError('El codificador no produjo un archivo MP4 válido.');
      }
      return output;
    } finally {
      if (await sequenceDirectory.exists()) {
        await sequenceDirectory.delete(recursive: true);
      }
    }
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
