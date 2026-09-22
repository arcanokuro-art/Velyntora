import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/media_importer.dart';

void main() {
  late Directory root;
  late MediaImporter importer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('velyntora_media_');
    importer = MediaImporter(rootDirectory: root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('copia una imagen al almacenamiento administrado', () async {
    final source = File('${root.path}${Platform.pathSeparator}referencia.png');
    await source.writeAsBytes(<int>[1, 2, 3]);

    final asset = await importer.importFile(
      source,
      type: MediaType.image,
      projectName: 'Mi animación',
      startFrame: 2,
    );

    expect(await File(asset.path).exists(), isTrue);
    expect(asset.type, MediaType.image);
    expect(asset.startFrame, 2);
    expect(asset.path, contains('Velyntora'));
  });

  test('acepta formatos de audio y video compatibles', () async {
    final audio = File('${root.path}${Platform.pathSeparator}voz.mp3');
    final video = File('${root.path}${Platform.pathSeparator}escena.mp4');
    await audio.writeAsBytes(<int>[1]);
    await video.writeAsBytes(<int>[2]);

    final audioAsset = await importer.importFile(
      audio,
      type: MediaType.audio,
      projectName: 'Proyecto',
      startFrame: 0,
    );
    final videoAsset = await importer.importFile(
      video,
      type: MediaType.video,
      projectName: 'Proyecto',
      startFrame: 3,
    );

    expect(audioAsset.type, MediaType.audio);
    expect(videoAsset.type, MediaType.video);
    expect(videoAsset.startFrame, 3);
  });

  test('rechaza extensiones incompatibles', () async {
    final source = File('${root.path}${Platform.pathSeparator}archivo.txt');
    await source.writeAsString('no compatible');

    await expectLater(
      importer.importFile(
        source,
        type: MediaType.video,
        projectName: 'Proyecto',
        startFrame: 0,
      ),
      throwsFormatException,
    );
  });

  test('serializa recursos multimedia conservando su tiempo', () {
    final project = AnimationProject(name: 'Multimedia');
    project.mediaAssets.add(
      MediaAsset(
        id: 'audio-1',
        name: 'voz.wav',
        path: '/media/voz.wav',
        type: MediaType.audio,
        startFrame: 4,
        durationFrames: 12,
      ),
    );

    final restored = AnimationProject.fromJson(project.toJson());

    expect(restored.mediaAssets, hasLength(1));
    expect(restored.mediaAssets.single.startFrame, 4);
    expect(restored.mediaAssets.single.durationFrames, 12);
    expect(restored.toJson()['version'], 4);
  });

  test('determina en que fotogramas está activo un recurso', () {
    final asset = MediaAsset(
      id: 'video-1',
      name: 'clip.mp4',
      path: '/media/clip.mp4',
      type: MediaType.video,
      startFrame: 3,
      durationFrames: 4,
    );

    expect(asset.isVisibleAt(2), isFalse);
    expect(asset.isVisibleAt(3), isTrue);
    expect(asset.isVisibleAt(6), isTrue);
    expect(asset.isVisibleAt(7), isFalse);
  });
}
