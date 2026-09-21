import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/services/gif_encoder.dart';

void main() {
  const encoder = GifEncoder();

  testWidgets('genera un GIF animado decodificable', (tester) async {
    final red = Uint8List.fromList(<int>[255, 0, 0, 255, 255, 0, 0, 255]);
    final blue = Uint8List.fromList(<int>[0, 0, 255, 255, 0, 0, 255, 255]);

    final bytes = encoder.encode(
      width: 2,
      height: 1,
      rgbaFrames: <Uint8List>[red, blue],
      fps: 12,
    );
    final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes));

    expect(String.fromCharCodes(bytes.take(6)), 'GIF89a');
    expect(bytes.last, 0x3B);
    expect(codec, isNotNull);
    expect(codec!.frameCount, 2);
    final frame = await tester.runAsync(codec.getNextFrame);
    expect(frame, isNotNull);
    expect(frame!.image.width, 2);
    expect(frame.image.height, 1);
    frame.image.dispose();
    codec.dispose();
  });

  test('rechaza listas vacias de fotogramas', () {
    expect(
      () => encoder.encode(width: 2, height: 2, rgbaFrames: const <Uint8List>[], fps: 12),
      throwsArgumentError,
    );
  });

  test('rechaza fotogramas con cantidad incorrecta de pixeles', () {
    expect(
      () => encoder.encode(
        width: 2,
        height: 2,
        rgbaFrames: <Uint8List>[Uint8List(4)],
        fps: 12,
      ),
      throwsArgumentError,
    );
  });
}
