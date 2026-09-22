import 'package:flutter/material.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class FrameThumbnail extends StatelessWidget {
  const FrameThumbnail({
    super.key,
    required this.controller,
    required this.frame,
  });

  final EditorController controller;
  final int frame;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: Colors.white,
        child: CustomPaint(
          painter: AnimationCanvasPainter(
            controller,
            showGuides: false,
            frameOverride: frame,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final TransformationController _transformation = TransformationController();
  double _pointerPressure = 1;

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

  void _trackPressure(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      _pointerPressure = 1;
      return;
    }
    final range = event.pressureMax - event.pressureMin;
    _pointerPressure = range <= 0
        ? 1
        : ((event.pressure - event.pressureMin) / range).clamp(0, 1);
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
        if (!constraints.hasBoundedWidth ||
            !constraints.hasBoundedHeight ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
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
                child: Listener(
                  onPointerDown: _trackPressure,
                  onPointerMove: _trackPressure,
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
                            pressure: _pointerPressure,
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
                            pressure: _pointerPressure,
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
          ),
        );
      },
    );
  }

  Offset _normalize(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0.0, 1.0),
    (point.dy / size.height).clamp(0.0, 1.0),
  );
}

class AnimationCanvasPainter extends CustomPainter {
  AnimationCanvasPainter(
    this.controller, {
    this.showGuides = true,
    this.frameOverride,
  }) : super(repaint: controller);

  final EditorController controller;
  final bool showGuides;
  final int? frameOverride;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
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
            ..color = fill.withValues(alpha: fill.a * layer.opacity * opacity),
        );
      }
      final regionFills =
          layer.regionFills[frame] ?? const <DrawingRegionFill>[];
      for (final region in regionFills) {
        if (region.boundary.length < 3) continue;
        final path = Path();
        final first = _scale(region.boundary.first, size);
        path.moveTo(first.dx, first.dy);
        for (final point in region.boundary.skip(1)) {
          final scaled = _scale(point, size);
          path.lineTo(scaled.dx, scaled.dy);
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..color = region.color.withValues(
              alpha: region.color.a * layer.opacity * opacity,
            )
            ..style = PaintingStyle.fill,
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
        final first = _scale(stroke.points.first, size);
        if (stroke.points.length == 1) {
          canvas.drawCircle(
            first,
            stroke.width * stroke.pressureAt(0) / 2,
            paint..style = PaintingStyle.fill,
          );
        } else if (stroke.pressures.isEmpty) {
          final path = Path()..moveTo(first.dx, first.dy);
          for (final point in stroke.points.skip(1)) {
            final scaled = _scale(point, size);
            path.lineTo(scaled.dx, scaled.dy);
          }
          canvas.drawPath(path, paint);
        } else {
          for (var index = 1; index < stroke.points.length; index++) {
            final start = _scale(stroke.points[index - 1], size);
            final end = _scale(stroke.points[index], size);
            final pressure =
                (stroke.pressureAt(index - 1) + stroke.pressureAt(index)) / 2;
            canvas.drawLine(
              start,
              end,
              paint..strokeWidth = stroke.width * pressure,
            );
          }
        }
      }
      final texts = layer.texts[frame] ?? const <DrawingText>[];
      for (final item in texts) {
        final textPainter =
            TextPainter(
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
            )..layout(
              maxWidth: (size.width * (1 - item.position.dx)).clamp(
                0.0,
                size.width,
              ),
            );
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
