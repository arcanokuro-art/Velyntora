import 'package:flutter/material.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = controller.project.width / controller.project.height;
        var width = constraints.maxWidth;
        var height = width / ratio;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * ratio;
        }
        return Center(
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Colors.black54, blurRadius: 28),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => controller.beginStroke(
                _normalize(details.localPosition, Size(width, height)),
              ),
              onPanUpdate: (details) => controller.extendStroke(
                _normalize(details.localPosition, Size(width, height)),
              ),
              child: CustomPaint(
                painter: AnimationCanvasPainter(controller),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _normalize(Offset point, Size size) =>
      Offset(point.dx / size.width, point.dy / size.height);
}

class AnimationCanvasPainter extends CustomPainter {
  AnimationCanvasPainter(this.controller) : super(repaint: controller);

  final EditorController controller;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawColor(Colors.white, BlendMode.src);

    if (controller.onionSkin && controller.activeFrame > 0) {
      _paintFrame(canvas, size, controller.activeFrame - 1, opacity: 0.18);
    }
    _paintFrame(canvas, size, controller.activeFrame);

    if (controller.gridEnabled) _paintGrid(canvas, size);
    canvas.restore();
  }

  void _paintFrame(Canvas canvas, Size size, int frame, {double opacity = 1}) {
    for (final layer in controller.project.layers.reversed) {
      if (!layer.visible) continue;
      final strokes = layer.frames[frame] ?? const <DrawingStroke>[];
      for (final stroke in strokes) {
        if (stroke.points.isEmpty) continue;
        final paint = Paint()
          ..color = stroke.color.withValues(
            alpha: stroke.color.a * layer.opacity * opacity,
          )
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..blendMode = stroke.erase ? BlendMode.clear : BlendMode.srcOver;
        final path = Path();
        final first = _scale(stroke.points.first, size);
        path.moveTo(first.dx, first.dy);
        for (final point in stroke.points.skip(1)) {
          final scaled = _scale(point, size);
          path.lineTo(scaled.dx, scaled.dy);
        }
        if (stroke.points.length == 1) {
          canvas.drawCircle(first, stroke.width / 2, paint..style = PaintingStyle.fill);
        } else {
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Offset _scale(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant AnimationCanvasPainter oldDelegate) => true;
}
