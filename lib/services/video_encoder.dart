import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';

import '../models/animation_models.dart';

abstract class VideoEncoder {
  const VideoEncoder();

  Future<void> encode({
    required String inputPattern,
    required String outputPath,
    required int fps,
    required int width,
    required int height,
    required List<MediaAsset> audioAssets,
  });
}

class FfmpegVideoEncoder extends VideoEncoder {
  const FfmpegVideoEncoder();

  String buildCommand({
    required String inputPattern,
    required String outputPath,
    required int fps,
    required List<MediaAsset> audioAssets,
  }) {
    final inputs = <String>[
      '-y',
      '-framerate',
      '$fps',
      '-i',
      _quote(inputPattern),
    ];
    for (final asset in audioAssets.where(
      (asset) => File(asset.path).existsSync(),
    )) {
      inputs
        ..add('-itsoffset')
        ..add((asset.startFrame / fps).toStringAsFixed(6))
        ..add('-i')
        ..add(_quote(asset.path));
    }

    final existingAudio = audioAssets
        .where((asset) => File(asset.path).existsSync())
        .toList();
    final output = <String>['-map', '0:v:0'];
    if (existingAudio.length == 1) {
      output.addAll(<String>['-map', '1:a:0?', '-c:a', 'aac', '-shortest']);
    } else if (existingAudio.length > 1) {
      final labels = List<String>.generate(
        existingAudio.length,
        (index) => '[${index + 1}:a]',
      ).join();
      output.addAll(<String>[
        '-filter_complex',
        _quote(
          '${labels}amix=inputs=${existingAudio.length}:duration=longest[a]',
        ),
        '-map',
        '[a]',
        '-c:a',
        'aac',
        '-shortest',
      ]);
    }
    output.addAll(<String>[
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-vf',
      _quote('scale=trunc(iw/2)*2:trunc(ih/2)*2'),
      '-movflags',
      '+faststart',
      _quote(outputPath),
    ]);
    return <String>[...inputs, ...output].join(' ');
  }

  @override
  Future<void> encode({
    required String inputPattern,
    required String outputPath,
    required int fps,
    required int width,
    required int height,
    required List<MediaAsset> audioAssets,
  }) async {
    final command = buildCommand(
      inputPattern: inputPattern,
      outputPath: outputPath,
      fps: fps,
      audioAssets: audioAssets,
    );
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      throw StateError(
        'FFmpeg no pudo crear el MP4: ${output ?? 'error desconocido'}',
      );
    }
  }

  String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
