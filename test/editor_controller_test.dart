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
}
