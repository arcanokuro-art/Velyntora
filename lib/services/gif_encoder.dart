import 'dart:typed_data';

class GifEncoder {
  const GifEncoder();

  Uint8List encode({
    required int width,
    required int height,
    required List<Uint8List> rgbaFrames,
    required int fps,
  }) {
    if (width <= 0 || height <= 0 || width > 65535 || height > 65535) {
      throw RangeError('Las dimensiones GIF deben estar entre 1 y 65535.');
    }
    if (rgbaFrames.isEmpty) {
      throw ArgumentError.value(rgbaFrames, 'rgbaFrames', 'Se requiere al menos un fotograma.');
    }
    final pixelBytes = width * height * 4;
    if (rgbaFrames.any((frame) => frame.length != pixelBytes)) {
      throw ArgumentError('Cada fotograma debe contener width × height × 4 bytes RGBA.');
    }

    final output = BytesBuilder(copy: false)
      ..add('GIF89a'.codeUnits)
      ..add(_word(width))
      ..add(_word(height))
      ..add(<int>[0xF7, 0, 0])
      ..add(_palette())
      ..add(<int>[0x21, 0xFF, 0x0B])
      ..add('NETSCAPE2.0'.codeUnits)
      ..add(<int>[0x03, 0x01, 0x00, 0x00, 0x00]);

    final delay = (100 / fps.clamp(1, 60)).round().clamp(2, 100).toInt();
    for (final rgba in rgbaFrames) {
      final indexed = Uint8List(width * height);
      for (var pixel = 0; pixel < indexed.length; pixel++) {
        final offset = pixel * 4;
        indexed[pixel] = (rgba[offset] & 0xE0) |
            ((rgba[offset + 1] & 0xE0) >> 3) |
            (rgba[offset + 2] >> 6);
      }
      final compressed = _lzw(indexed);
      output
        ..add(<int>[0x21, 0xF9, 0x04, 0x08])
        ..add(_word(delay))
        ..add(<int>[0x00, 0x00])
        ..add(<int>[0x2C, 0, 0, 0, 0])
        ..add(_word(width))
        ..add(_word(height))
        ..add(<int>[0x00, 0x08]);
      for (var offset = 0; offset < compressed.length; offset += 255) {
        final count = (compressed.length - offset).clamp(0, 255).toInt();
        output
          ..addByte(count)
          ..add(compressed.sublist(offset, offset + count));
      }
      output.addByte(0);
    }
    output.addByte(0x3B);
    return output.takeBytes();
  }

  Uint8List _palette() {
    final palette = Uint8List(256 * 3);
    for (var index = 0; index < 256; index++) {
      palette[index * 3] = ((index >> 5) & 7) * 255 ~/ 7;
      palette[index * 3 + 1] = ((index >> 2) & 7) * 255 ~/ 7;
      palette[index * 3 + 2] = (index & 3) * 255 ~/ 3;
    }
    return palette;
  }

  Uint8List _lzw(Uint8List pixels) {
    const clearCode = 256;
    const endCode = 257;
    final bytes = BytesBuilder(copy: false);
    var currentByte = 0;
    var bitCount = 0;

    void writeCode(int code, int size) {
      currentByte |= code << bitCount;
      bitCount += size;
      while (bitCount >= 8) {
        bytes.addByte(currentByte & 0xFF);
        currentByte >>= 8;
        bitCount -= 8;
      }
    }

    final dictionary = <int, int>{};
    var codeSize = 9;
    var nextCode = 258;
    writeCode(clearCode, codeSize);
    var prefix = pixels.first;
    for (final symbol in pixels.skip(1)) {
      final key = (prefix << 8) | symbol;
      final existing = dictionary[key];
      if (existing != null) {
        prefix = existing;
        continue;
      }
      writeCode(prefix, codeSize);
      if (nextCode < 4096) {
        dictionary[key] = nextCode++;
        if (nextCode == (1 << codeSize) && codeSize < 12) codeSize++;
      } else {
        writeCode(clearCode, codeSize);
        dictionary.clear();
        codeSize = 9;
        nextCode = 258;
      }
      prefix = symbol;
    }
    writeCode(prefix, codeSize);
    writeCode(endCode, codeSize);
    if (bitCount > 0) bytes.addByte(currentByte & 0xFF);
    return bytes.takeBytes();
  }

  List<int> _word(int value) => <int>[value & 0xFF, (value >> 8) & 0xFF];
}
