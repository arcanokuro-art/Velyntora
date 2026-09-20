import 'dart:ui';

enum DrawingTool { brush, eraser, fill, select, text, hand }

class DrawingStroke {
  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.erase,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool erase;

  DrawingStroke copy() => DrawingStroke(
        points: List<Offset>.from(points),
        color: color,
        width: width,
        erase: erase,
      );
}

class AnimationLayer {
  AnimationLayer({required this.name});

  String name;
  bool visible = true;
  bool locked = false;
  double opacity = 1;
  final Map<int, List<DrawingStroke>> frames = <int, List<DrawingStroke>>{};

  List<DrawingStroke> strokesAt(int frame) =>
      frames.putIfAbsent(frame, () => <DrawingStroke>[]);
}

class AnimationProject {
  AnimationProject({
    required this.name,
    this.width = 1920,
    this.height = 1080,
    this.fps = 12,
  }) : layers = <AnimationLayer>[AnimationLayer(name: 'Capa 1')];

  final String name;
  final int width;
  final int height;
  int fps;
  int frameCount = 6;
  final List<AnimationLayer> layers;
}
