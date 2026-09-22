import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/video_encoder.dart';

void main() {
  const encoder = FfmpegVideoEncoder();

  test('construye un MP4 H.264 compatible y conserva los FPS', () {
    final command = encoder.buildCommand(
      inputPattern: '/tmp/frames/frame_%06d.png',
      outputPath: '/tmp/salida.mp4',
      fps: 24,
      audioAssets: <MediaAsset>[],
    );

    expect(command, contains('-framerate 24'));
    expect(command, contains('-c:v libx264'));
    expect(command, contains('-pix_fmt yuv420p'));
    expect(command, contains('scale=trunc(iw/2)*2:trunc(ih/2)*2'));
    expect(command, contains('-movflags +faststart'));
  });

  test('añade audio con el desplazamiento de su fotograma inicial', () {
    final directory = Directory.systemTemp.createTempSync('velyntora_audio_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final audio = File('${directory.path}/voz prueba.wav')
      ..writeAsBytesSync(<int>[1]);
    final command = encoder.buildCommand(
      inputPattern: '/tmp/frame_%06d.png',
      outputPath: '/tmp/video.mp4',
      fps: 12,
      audioAssets: <MediaAsset>[
        MediaAsset(
          id: 'audio',
          name: 'Voz',
          path: audio.path,
          type: MediaType.audio,
          startFrame: 6,
        ),
      ],
    );

    expect(command, contains('-itsoffset 0.500000'));
    expect(command, contains("'${audio.path}'"));
    expect(command, contains('-map 1:a:0? -c:a aac -shortest'));
  });
}
