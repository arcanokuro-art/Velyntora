import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/services/file_sharer.dart';

void main() {
  const sharer = FileSharer();

  test('identifica archivos PNG para compartir', () {
    expect(sharer.mimeTypeForPath('fotograma.PNG'), 'image/png');
  });

  test('identifica animaciones GIF y videos MP4', () {
    expect(sharer.mimeTypeForPath('animacion.gif'), 'image/gif');
    expect(sharer.mimeTypeForPath('animacion.mp4'), 'video/mp4');
  });

  test('rechaza una lista vacia antes de abrir el menu del sistema', () async {
    await expectLater(sharer.share(const <File>[], title: 'Vacío'), throwsArgumentError);
  });
}
