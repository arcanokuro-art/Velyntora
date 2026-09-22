import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../models/animation_models.dart';

class MediaImporter {
  MediaImporter({this.rootDirectory});

  final Directory? rootDirectory;

  static const Map<MediaType, List<String>> extensions =
      <MediaType, List<String>>{
        MediaType.image: <String>['png', 'jpg', 'jpeg', 'webp'],
        MediaType.audio: <String>['mp3', 'wav', 'm4a', 'aac', 'ogg'],
        MediaType.video: <String>['mp4', 'mov', 'mkv', 'webm'],
      };

  Future<MediaAsset?> pickAndImport({
    required MediaType type,
    required String projectName,
    required int startFrame,
  }) async {
    final selected = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(label: type.name, extensions: extensions[type]),
      ],
    );
    if (selected == null) return null;
    return importFile(
      File(selected.path),
      type: type,
      projectName: projectName,
      startFrame: startFrame,
    );
  }

  Future<MediaAsset> importFile(
    File source, {
    required MediaType type,
    required String projectName,
    required int startFrame,
  }) async {
    if (!await source.exists()) {
      throw ArgumentError('El archivo seleccionado no existe.');
    }
    final extension = source.path.split('.').last.toLowerCase();
    if (!(extensions[type]?.contains(extension) ?? false)) {
      throw FormatException(
        'Formato .$extension no compatible con ${type.name}.',
      );
    }
    final documents = rootDirectory ?? await getApplicationDocumentsDirectory();
    final project = _safeName(projectName, fallback: 'Proyecto');
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}Velyntora'
      '${Platform.pathSeparator}Media${Platform.pathSeparator}$project',
    );
    await directory.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final originalName = source.uri.pathSegments.last;
    final name = _safeName(originalName, fallback: 'archivo.$extension');
    final destination = File(
      '${directory.path}${Platform.pathSeparator}${stamp}_$name',
    );
    await source.copy(destination.path);
    return MediaAsset(
      id: '$stamp-$name',
      name: originalName,
      path: destination.path,
      type: type,
      startFrame: startFrame,
      durationFrames: type == MediaType.image ? 1 : 1,
    );
  }

  String _safeName(String value, {required String fallback}) {
    final safe = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return safe.isEmpty ? fallback : safe;
  }
}
