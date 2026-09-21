import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/animation_models.dart';

class ProjectStorage {
  ProjectStorage({this.rootDirectory});

  final Directory? rootDirectory;

  Future<Directory> get projectsDirectory async {
    final documents = rootDirectory ?? await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}Velyntora${Platform.pathSeparator}Projects',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> save(AnimationProject project) async {
    final directory = await projectsDirectory;
    final safeName = project.name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${safeName.isEmpty ? 'Proyecto' : safeName}.vely',
    );
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(project.toJson()), flush: true);
    return file;
  }

  Future<AnimationProject> load(File file) async {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return AnimationProject.fromJson(json);
  }

  Future<List<File>> listProjects() async {
    final directory = await projectsDirectory;
    final projects = await directory
        .list()
        .where(
          (entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.vely'),
        )
        .cast<File>()
        .toList();
    projects.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return projects;
  }

  Future<void> delete(File file) async {
    if (!await file.exists()) return;
    final directory = await projectsDirectory;
    final root =
        '${await directory.resolveSymbolicLinks()}${Platform.pathSeparator}';
    final target = await file.resolveSymbolicLinks();
    if (!target.startsWith(root)) {
      throw ArgumentError('El archivo no pertenece a Velyntora.');
    }
    await file.delete();
  }
}
