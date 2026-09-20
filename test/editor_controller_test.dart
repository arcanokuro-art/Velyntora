import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/controllers/editor_controller.dart';
import 'package:velyntora/models/animation_models.dart';

void main() {
  test('agrega y duplica fotogramas', () {
    final controller = EditorController(AnimationProject(name: 'Prueba'));
    expect(controller.project.frameCount, 6);
    controller.addFrame(duplicate: true);
    expect(controller.project.frameCount, 7);
    expect(controller.activeFrame, 1);
  });

  test('agrega capas y selecciona la nueva', () {
    final controller = EditorController(AnimationProject(name: 'Prueba'));
    controller.addLayer();
    expect(controller.project.layers.length, 2);
    expect(controller.activeLayer, 0);
  });

  test('serializa y recupera un proyecto', () {
    final project = AnimationProject(name: 'Prueba de formato');
    project.frameCount = 18;
    final restored = AnimationProject.fromJson(project.toJson());
    expect(restored.name, project.name);
    expect(restored.frameCount, 18);
    expect(restored.layers.length, 1);
  });

  test('deshace y rehace un trazo', () {
    final controller = EditorController(AnimationProject(name: 'Historial'));
    controller.beginStroke(const Offset(0.1, 0.2));
    controller.extendStroke(const Offset(0.3, 0.4));

    expect(controller.strokes, hasLength(1));
    controller.undo();
    expect(controller.strokes, isEmpty);
    expect(controller.canRedo, isTrue);

    controller.redo();
    expect(controller.strokes, hasLength(1));
    expect(controller.strokes.single.points, hasLength(2));
  });

  test('un trazo nuevo descarta el historial de rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Historial'));
    controller.beginStroke(const Offset(0.1, 0.2));
    controller.undo();
    controller.beginStroke(const Offset(0.5, 0.5));

    expect(controller.canRedo, isFalse);
  });

  test('elimina un fotograma y recorre los siguientes', () {
    final controller = EditorController(AnimationProject(name: 'Eliminar'));
    controller.selectFrame(1);
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.selectFrame(2);
    controller.beginStroke(const Offset(0.8, 0.8));
    controller.selectFrame(1);

    expect(controller.deleteFrame(), isTrue);
    expect(controller.project.frameCount, 5);
    expect(controller.layer.frames[1]?.single.points.single,
        const Offset(0.8, 0.8));
  });

  test('impide eliminar el ultimo fotograma', () {
    final project = AnimationProject(name: 'Minimo')..frameCount = 1;
    final controller = EditorController(project);

    expect(controller.deleteFrame(), isFalse);
    expect(controller.project.frameCount, 1);
  });

  test('renombra la capa activa y descarta nombres vacios', () {
    final controller = EditorController(AnimationProject(name: 'Capas'));
    controller.renameActiveLayer('  Boceto  ');
    expect(controller.layer.name, 'Boceto');

    controller.renameActiveLayer('   ');
    expect(controller.layer.name, 'Boceto');
  });

  test('limita la opacidad de la capa entre cero y uno', () {
    final controller = EditorController(AnimationProject(name: 'Capas'));
    controller.setActiveLayerOpacity(1.5);
    expect(controller.layer.opacity, 1);

    controller.setActiveLayerOpacity(-0.5);
    expect(controller.layer.opacity, 0);
  });

  test('reordena capas conservando la seleccion', () {
    final controller = EditorController(AnimationProject(name: 'Capas'));
    controller.addLayer();
    final selectedLayer = controller.layer;

    expect(controller.moveActiveLayerDown(), isTrue);
    expect(controller.activeLayer, 1);
    expect(controller.layer, same(selectedLayer));
    expect(controller.moveActiveLayerUp(), isTrue);
    expect(controller.activeLayer, 0);
    expect(controller.layer, same(selectedLayer));
  });

  test('elimina capas sin permitir borrar la ultima', () {
    final controller = EditorController(AnimationProject(name: 'Capas'));
    expect(controller.deleteActiveLayer(), isFalse);

    controller.addLayer();
    expect(controller.deleteActiveLayer(), isTrue);
    expect(controller.project.layers, hasLength(1));
    expect(controller.deleteActiveLayer(), isFalse);
  });

  test('limita el zoom al intervalo permitido', () {
    final controller = EditorController(AnimationProject(name: 'Zoom'));
    controller.setZoom(20);
    expect(controller.zoom, 8);

    controller.setZoom(0.01);
    expect(controller.zoom, 0.25);
  });

  test('restablece el zoom al cien por ciento', () {
    final controller = EditorController(AnimationProject(name: 'Zoom'));
    controller.setZoom(3.5);
    controller.resetZoom();
    expect(controller.zoom, 1);
  });

  test('rellena el fotograma activo y permite deshacer y rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Relleno'));
    controller.selectTool(DrawingTool.fill);
    controller.setColor(const Color(0xFF7357FF));
    controller.selectTool(DrawingTool.fill);
    controller.beginStroke(const Offset(0.5, 0.5));

    expect(controller.layer.fills[0], const Color(0xFF7357FF));
    controller.undo();
    expect(controller.layer.fills[0], isNull);
    controller.redo();
    expect(controller.layer.fills[0], const Color(0xFF7357FF));
  });

  test('duplica y serializa el relleno del fotograma', () {
    final controller = EditorController(AnimationProject(name: 'Relleno'));
    controller.selectTool(DrawingTool.fill);
    controller.fillFrame();
    controller.addFrame(duplicate: true);

    expect(controller.layer.fills[1], controller.color);
    final restored = AnimationProject.fromJson(controller.project.toJson());
    expect(restored.layers.single.fills[1], controller.color);
    expect(restored.toJson()['version'], 2);
  });

  test('mantiene compatibilidad con proyectos sin rellenos', () {
    final project = AnimationProject(name: 'Anterior');
    final json = project.toJson();
    final layers = json['layers'] as List<Map<String, Object>>;
    layers.single.remove('fills');

    final restored = AnimationProject.fromJson(json);
    expect(restored.layers.single.fills, isEmpty);
  });

  test('limpiar fotograma elimina trazos y relleno con deshacer', () {
    final controller = EditorController(AnimationProject(name: 'Limpiar'));
    controller.beginStroke(const Offset(0.1, 0.1));
    controller.selectTool(DrawingTool.fill);
    controller.fillFrame();
    controller.clearFrame();

    expect(controller.strokes, isEmpty);
    expect(controller.layer.fills[0], isNull);
    controller.undo();
    expect(controller.strokes, hasLength(1));
    expect(controller.layer.fills[0], controller.color);
  });

  test('agrega texto y permite deshacer y rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.addText('Hola Velyntora', const Offset(0.25, 0.4));

    expect(controller.texts.single.text, 'Hola Velyntora');
    expect(controller.texts.single.position, const Offset(0.25, 0.4));
    controller.undo();
    expect(controller.texts, isEmpty);
    controller.redo();
    expect(controller.texts.single.text, 'Hola Velyntora');
  });

  test('duplica y serializa textos del fotograma', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.addText('Titulo', const Offset(0.1, 0.2));
    controller.addFrame(duplicate: true);

    expect(controller.texts.single.text, 'Titulo');
    final restored = AnimationProject.fromJson(controller.project.toJson());
    expect(restored.layers.single.texts[1]?.single.text, 'Titulo');
  });

  test('elimina un fotograma y recorre sus textos', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.selectFrame(1);
    controller.addText('Eliminar', const Offset(0.1, 0.1));
    controller.selectFrame(2);
    controller.addText('Conservar', const Offset(0.2, 0.2));
    controller.selectFrame(1);

    controller.deleteFrame();
    expect(controller.layer.texts[1]?.single.text, 'Conservar');
  });

  test('limpiar fotograma elimina y recupera textos', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.addText('Recuperar', const Offset(0.3, 0.3));
    controller.clearFrame();
    expect(controller.texts, isEmpty);

    controller.undo();
    expect(controller.texts.single.text, 'Recuperar');
  });
}
