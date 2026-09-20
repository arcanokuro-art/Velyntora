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
}
