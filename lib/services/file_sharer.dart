import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

class FileSharer {
  const FileSharer();

  Future<void> share(List<File> files, {required String title}) async {
    if (files.isEmpty) {
      throw ArgumentError.value(files, 'files', 'No hay archivos para compartir.');
    }
    for (final file in files) {
      if (!await file.exists()) {
        throw ArgumentError.value(file.path, 'files', 'El archivo no existe.');
      }
    }
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        text: 'Creado con Velyntora',
        files: files
            .map(
              (file) => XFile(
                file.path,
                mimeType: mimeTypeForPath(file.path),
              ),
            )
            .toList(),
      ),
    );
  }

  String? mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    return null;
  }
}
