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

  test('selecciona el trazo mas cercano', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.extendStroke(const Offset(0.3, 0.3));
    final expected = controller.strokes.single;
    controller.selectTool(DrawingTool.select);

    expect(controller.selectAt(const Offset(0.21, 0.21)), isTrue);
    expect(controller.selectedStroke, same(expected));
    expect(controller.selectedText, isNull);
  });

  test('mueve un trazo seleccionado con deshacer y rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.2, 0.2));
    controller.beginSelectionTransform();
    controller.moveSelection(const Offset(0.1, 0.15));
    controller.finishSelectionTransform();

    expect(controller.strokes.single.points.single.dx, closeTo(0.3, 0.000001));
    expect(controller.strokes.single.points.single.dy, closeTo(0.35, 0.000001));
    controller.undo();
    expect(controller.strokes.single.points.single, const Offset(0.2, 0.2));
    controller.redo();
    expect(controller.strokes.single.points.single.dx, closeTo(0.3, 0.000001));
    expect(controller.strokes.single.points.single.dy, closeTo(0.35, 0.000001));
  });

  test('selecciona y mueve texto dentro del lienzo', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.addText('Mover', const Offset(0.9, 0.9));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.9, 0.9));
    controller.beginSelectionTransform();
    controller.moveSelection(const Offset(0.4, 0.4));
    controller.finishSelectionTransform();

    expect(controller.texts.single.position, const Offset(1, 1));
    controller.undo();
    expect(controller.texts.single.position, const Offset(0.9, 0.9));
  });

  test('no selecciona contenido de una capa bloqueada', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.toggleLayerLock(0);
    controller.selectTool(DrawingTool.select);

    expect(controller.selectAt(const Offset(0.2, 0.2)), isFalse);
    expect(controller.selectedStroke, isNull);
  });

  test('elimina un trazo seleccionado con deshacer y rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.2, 0.2));

    expect(controller.deleteSelection(), isTrue);
    expect(controller.strokes, isEmpty);
    controller.undo();
    expect(controller.strokes, hasLength(1));
    controller.redo();
    expect(controller.strokes, isEmpty);
  });

  test('elimina un texto seleccionado y puede recuperarlo', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.addText('Eliminar', const Offset(0.4, 0.4));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.4, 0.4));

    expect(controller.deleteSelection(), isTrue);
    expect(controller.texts, isEmpty);
    controller.undo();
    expect(controller.texts.single.text, 'Eliminar');
  });

  test('escala un trazo alrededor de su centro', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.beginStroke(const Offset(0.2, 0.2));
    controller.extendStroke(const Offset(0.4, 0.4));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.2, 0.2));

    expect(controller.scaleSelection(2), isTrue);
    expect(controller.strokes.single.points.first.dx, closeTo(0.1, 0.000001));
    expect(controller.strokes.single.points.last.dx, closeTo(0.5, 0.000001));
    controller.undo();
    expect(controller.strokes.single.points.first, const Offset(0.2, 0.2));
  });

  test('escala texto respetando los limites de tamano', () {
    final controller = EditorController(AnimationProject(name: 'Seleccion'));
    controller.addText('Escalar', const Offset(0.4, 0.4));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.4, 0.4));

    expect(controller.scaleSelection(100), isTrue);
    expect(controller.texts.single.fontSize, 240);
    controller.undo();
    expect(controller.texts.single.fontSize, lessThan(240));
  });

  test('rota un trazo alrededor de su centro con deshacer', () {
    final controller = EditorController(AnimationProject(name: 'Rotacion'));
    controller.beginStroke(const Offset(0.2, 0.5));
    controller.extendStroke(const Offset(0.8, 0.5));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.2, 0.5));

    expect(controller.rotateSelection(1.57079632679), isTrue);
    expect(controller.strokes.single.points.first.dx, closeTo(0.5, 0.000001));
    expect(controller.strokes.single.points.first.dy, closeTo(0.2, 0.000001));
    controller.undo();
    expect(controller.strokes.single.points.first, const Offset(0.2, 0.5));
  });

  test('rota y serializa un texto seleccionado', () {
    final controller = EditorController(AnimationProject(name: 'Rotacion'));
    controller.addText('Girar', const Offset(0.3, 0.3));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.3, 0.3));
    controller.rotateSelection(0.5);

    expect(controller.texts.single.rotation, 0.5);
    final restored = AnimationProject.fromJson(controller.project.toJson());
    expect(restored.layers.single.texts[0]?.single.rotation, 0.5);
  });

  test('edita texto seleccionado con deshacer y rehacer', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.addText('Antes', const Offset(0.3, 0.3));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.3, 0.3));

    expect(controller.editSelectedText('Despues'), isTrue);
    expect(controller.texts.single.text, 'Despues');
    controller.undo();
    expect(controller.texts.single.text, 'Antes');
    controller.redo();
    expect(controller.texts.single.text, 'Despues');
  });

  test('rechaza texto editado vacio', () {
    final controller = EditorController(AnimationProject(name: 'Texto'));
    controller.addText('Conservar', const Offset(0.3, 0.3));
    controller.selectTool(DrawingTool.select);
    controller.selectAt(const Offset(0.3, 0.3));

    expect(controller.editSelectedText('   '), isFalse);
    expect(controller.texts.single.text, 'Conservar');
  });

  test('limita la opacidad del pincel', () {
    final controller = EditorController(AnimationProject(name: 'Pincel'));
    controller.setBrushOpacity(4);
    expect(controller.brushOpacity, 1);
    controller.setBrushOpacity(0);
    expect(controller.brushOpacity, 0.05);
  });

  test('limita la estabilizacion del pincel', () {
    final controller = EditorController(AnimationProject(name: 'Pincel'));
    controller.setStabilization(4);
    expect(controller.stabilization, 0.9);
    controller.setStabilization(-2);
    expect(controller.stabilization, 0);
  });

  test('configura el ajuste de lapiz', () {
    final controller = EditorController(AnimationProject(name: 'Pincel'));
    controller.selectBrushPreset(BrushPreset.pencil);
    expect(controller.brushSize, 3);
    expect(controller.brushOpacity, 0.9);
    expect(controller.stabilization, 0.15);
  });

  test('configura el ajuste de marcador', () {
    final controller = EditorController(AnimationProject(name: 'Pincel'));
    controller.selectBrushPreset(BrushPreset.marker);
    expect(controller.brushSize, 24);
    expect(controller.brushOpacity, 0.45);
    expect(controller.tool, DrawingTool.brush);
  });

  test('aplica opacidad y estabilizacion al trazo', () {
    final controller = EditorController(AnimationProject(name: 'Pincel'));
    controller.setBrushOpacity(0.5);
    controller.setStabilization(0.5);
    controller.beginStroke(Offset.zero);
    controller.extendStroke(const Offset(1, 1));

    expect(controller.strokes.single.color.a, closeTo(0.5, 0.01));
    expect(controller.strokes.single.points.last, const Offset(0.5, 0.5));
  });
}
