import 'package:flutter/material.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final TransformationController _transformation = TransformationController();

  EditorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _transformation.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _transformation
      ..removeListener(_reportZoom)
      ..dispose();
    super.dispose();
  }

  void _reportZoom() =>
      controller.setZoom(_transformation.value.getMaxScaleOnAxis());

  void _resetView() {
    _transformation.value = Matrix4.identity();
    controller.resetZoom();
  }

  Future<void> _addText(BuildContext context, Offset position) async {
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Añadir texto'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 3,
          maxLength: 160,
          decoration: const InputDecoration(hintText: 'Escribe el texto'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (value != null) controller.addText(value, position);
  }

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
        final movingCanvas = controller.tool == DrawingTool.hand;
        return GestureDetector(
          onDoubleTap: movingCanvas ? _resetView : null,
          child: InteractiveViewer(
            transformationController: _transformation,
            minScale: 0.25,
            maxScale: 8,
            panEnabled: movingCanvas,
            scaleEnabled: movingCanvas,
            boundaryMargin: const EdgeInsets.all(600),
            child: Center(
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
                  onTapDown: controller.tool == DrawingTool.text
                      ? (details) => _addText(
                            context,
                            _normalize(
                              details.localPosition,
                              Size(width, height),
                            ),
                          )
                      : controller.tool == DrawingTool.select
                          ? (details) => controller.selectAt(
                                _normalize(
                                  details.localPosition,
                                  Size(width, height),
                                ),
                              )
                          : null,
                  onPanStart: movingCanvas
                      ? null
                      : controller.tool == DrawingTool.select
                          ? (_) => controller.beginSelectionTransform()
                          : (details) => controller.beginStroke(
                                _normalize(
                                  details.localPosition,
                                  Size(width, height),
                                ),
                              ),
                  onPanUpdate: movingCanvas
                      ? null
                      : controller.tool == DrawingTool.select
                          ? (details) => controller.moveSelection(
                                Offset(
                                  details.delta.dx / width,
                                  details.delta.dy / height,
                                ),
                              )
                          : (details) => controller.extendStroke(
                                _normalize(
                                  details.localPosition,
                                  Size(width, height),
                                ),
                              ),
                  onPanEnd: controller.tool == DrawingTool.select
                      ? (_) => controller.finishSelectionTransform()
                      : null,
                  child: CustomPaint(
                    painter: AnimationCanvasPainter(controller),
                    size: Size(width, height),
                  ),
                ),
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
  AnimationCanvasPainter(
    this.controller, {
    this.showGuides = true,
    this.frameOverride,
  })
      : super(repaint: controller);

  final EditorController controller;
  final bool showGuides;
  final int? frameOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameOverride ?? controller.activeFrame;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawColor(Colors.white, BlendMode.src);

    if (showGuides && controller.onionSkin && frame > 0) {
      _paintFrame(canvas, size, frame - 1, opacity: 0.18);
    }
    _paintFrame(canvas, size, frame);

    if (showGuides && controller.tool == DrawingTool.select) {
      _paintSelection(canvas, size);
    }

    if (showGuides && controller.gridEnabled) _paintGrid(canvas, size);
    canvas.restore();
  }

  void _paintFrame(Canvas canvas, Size size, int frame, {double opacity = 1}) {
    for (final layer in controller.project.layers.reversed) {
      if (!layer.visible) continue;
      final fill = layer.fills[frame];
      if (fill != null) {
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = fill.withValues(
              alpha: fill.a * layer.opacity * opacity,
            ),
        );
      }
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
      final texts = layer.texts[frame] ?? const <DrawingText>[];
      for (final item in texts) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.text,
            style: TextStyle(
              color: item.color.withValues(
                alpha: item.color.a * layer.opacity * opacity,
              ),
              fontSize: item.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width * (1 - item.position.dx));
        final origin = _scale(item.position, size);
        canvas
          ..save()
          ..translate(origin.dx, origin.dy)
          ..rotate(item.rotation);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
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

  void _paintSelection(Canvas canvas, Size size) {
    Rect? bounds;
    final stroke = controller.selectedStroke;
    if (stroke != null && stroke.points.isNotEmpty) {
      final scaled = stroke.points.map((point) => _scale(point, size)).toList();
      final xs = scaled.map((point) => point.dx);
      final ys = scaled.map((point) => point.dy);
      bounds = Rect.fromLTRB(
        xs.reduce((a, b) => a < b ? a : b),
        ys.reduce((a, b) => a < b ? a : b),
        xs.reduce((a, b) => a > b ? a : b),
        ys.reduce((a, b) => a > b ? a : b),
      ).inflate(8);
    }
    final text = controller.selectedText;
    if (text != null) {
      final origin = _scale(text.position, size);
      bounds = Rect.fromLTWH(
        origin.dx,
        origin.dy,
        text.fontSize * text.text.length * 0.58,
        text.fontSize * 1.35,
      ).inflate(6);
    }
    if (bounds == null) return;
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFF21D4F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Offset _scale(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant AnimationCanvasPainter oldDelegate) => true;
}
