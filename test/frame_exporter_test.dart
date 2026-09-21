import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/controllers/editor_controller.dart';
import 'package:velyntora/models/animation_models.dart';
import 'package:velyntora/services/frame_exporter.dart';

void main() {
  const exporter = FrameExporter();

  test('limpia caracteres no validos del nombre exportado', () {
    expect(exporter.sanitizeFileName(' Mi animación: 01 / prueba '),
        'Mi_animación_01_prueba');
  });

  test('usa un nombre seguro cuando el proyecto no tiene nombre util', () {
    expect(exporter.sanitizeFileName('***'), 'Velyntora');
  });

  testWidgets('renderiza el fotograma como PNG valido', (tester) async {
    final project = AnimationProject(name: 'Exportar', width: 64, height: 36);
    final controller = EditorController(project)..setStabilization(0);
    controller.beginStroke(const Offset(0.1, 0.1));
    controller.extendStroke(const Offset(0.9, 0.9));

    final bytes = await exporter.renderPng(controller);
    expect(bytes.length, greaterThan(100));
    expect(bytes.take(8).toList(), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
