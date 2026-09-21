import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/project_storage.dart';

void main() {
  late Directory root;
  late ProjectStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('velyntora_storage_');
    storage = ProjectStorage(rootDirectory: root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('guarda, enumera y carga un proyecto', () async {
    final project = AnimationProject(name: 'Proyecto local', fps: 24);
    final file = await storage.save(project);

    final files = await storage.listProjects();
    final restored = await storage.load(files.single);

    expect(file.path, endsWith('Proyecto local.vely'));
    expect(restored.name, 'Proyecto local');
    expect(restored.fps, 24);
  });

  test('elimina un proyecto almacenado', () async {
    final file = await storage.save(AnimationProject(name: 'Eliminar'));

    await storage.delete(file);

    expect(await file.exists(), isFalse);
    expect(await storage.listProjects(), isEmpty);
  });

  test('impide eliminar archivos externos', () async {
    final external = File('${root.path}${Platform.pathSeparator}externo.vely');
    await external.writeAsString('no borrar');

    await expectLater(storage.delete(external), throwsArgumentError);

    expect(await external.exists(), isTrue);
  });
}
