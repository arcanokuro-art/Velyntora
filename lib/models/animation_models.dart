import 'dart:ui';

enum DrawingTool { brush, eraser, fill, select, text, hand }

enum BrushPreset { pencil, ink, marker }

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

  Map<String, Object> toJson() => <String, Object>{
        'points': points
            .map((point) => <String, double>{'x': point.dx, 'y': point.dy})
            .toList(),
        'color': color.toARGB32(),
        'width': width,
        'erase': erase,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        points: (json['points'] as List<dynamic>)
            .map((point) => Offset(
                  (point as Map<String, dynamic>)['x'] as double,
                  point['y'] as double,
                ))
            .toList(),
        color: Color(json['color'] as int),
        width: (json['width'] as num).toDouble(),
        erase: json['erase'] as bool,
      );
}

class DrawingText {
  DrawingText({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    this.rotation = 0,
  });

  String text;
  Offset position;
  final Color color;
  double fontSize;
  double rotation;

  DrawingText copy() => DrawingText(
        text: text,
        position: position,
        color: color,
        fontSize: fontSize,
        rotation: rotation,
      );

  Map<String, Object> toJson() => <String, Object>{
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'color': color.toARGB32(),
        'fontSize': fontSize,
        'rotation': rotation,
      };

  factory DrawingText.fromJson(Map<String, dynamic> json) => DrawingText(
        text: json['text'] as String,
        position: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        color: Color(json['color'] as int),
        fontSize: (json['fontSize'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      );
}

class AnimationLayer {
  AnimationLayer({required this.name});

  String name;
  bool visible = true;
  bool locked = false;
  double opacity = 1;
  final Map<int, List<DrawingStroke>> frames = <int, List<DrawingStroke>>{};
  final Map<int, Color> fills = <int, Color>{};
  final Map<int, List<DrawingText>> texts = <int, List<DrawingText>>{};

  List<DrawingStroke> strokesAt(int frame) =>
      frames.putIfAbsent(frame, () => <DrawingStroke>[]);

  List<DrawingText> textsAt(int frame) =>
      texts.putIfAbsent(frame, () => <DrawingText>[]);

  Map<String, Object> toJson() => <String, Object>{
        'name': name,
        'visible': visible,
        'locked': locked,
        'opacity': opacity,
        'fills': fills.map(
          (frame, color) => MapEntry(frame.toString(), color.toARGB32()),
        ),
        'texts': texts.map(
          (frame, items) => MapEntry(
            frame.toString(),
            items.map((item) => item.toJson()).toList(),
          ),
        ),
        'frames': frames.map(
          (frame, strokes) => MapEntry(
            frame.toString(),
            strokes.map((stroke) => stroke.toJson()).toList(),
          ),
        ),
      };

  factory AnimationLayer.fromJson(Map<String, dynamic> json) {
    final layer = AnimationLayer(name: json['name'] as String)
      ..visible = json['visible'] as bool
      ..locked = json['locked'] as bool
      ..opacity = (json['opacity'] as num).toDouble();
    final savedFrames = json['frames'] as Map<String, dynamic>;
    for (final entry in savedFrames.entries) {
      layer.frames[int.parse(entry.key)] = (entry.value as List<dynamic>)
          .map((stroke) => DrawingStroke.fromJson(stroke as Map<String, dynamic>))
          .toList();
    }
    final savedFills = json['fills'] as Map<String, dynamic>?;
    if (savedFills != null) {
      for (final entry in savedFills.entries) {
        layer.fills[int.parse(entry.key)] = Color(entry.value as int);
      }
    }
    final savedTexts = json['texts'] as Map<String, dynamic>?;
    if (savedTexts != null) {
      for (final entry in savedTexts.entries) {
        layer.texts[int.parse(entry.key)] = (entry.value as List<dynamic>)
            .map((item) => DrawingText.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    return layer;
  }
}

class AnimationProject {
  AnimationProject({
    required this.name,
    int width = 1920,
    int height = 1080,
    this.fps = 12,
  })  : width = width.clamp(64, 4096).toInt(),
        height = height.clamp(64, 4096).toInt(),
        layers = <AnimationLayer>[AnimationLayer(name: 'Capa 1')];

  final String name;
  final int width;
  final int height;
  int fps;
  int frameCount = 6;
  final List<AnimationLayer> layers;

  Map<String, Object> toJson() => <String, Object>{
        'format': 'velyntora-project',
        'version': 2,
        'name': name,
        'width': width,
        'height': height,
        'fps': fps,
        'frameCount': frameCount,
        'layers': layers.map((layer) => layer.toJson()).toList(),
      };

  factory AnimationProject.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'velyntora-project') {
      throw const FormatException('El archivo no es un proyecto de Velyntora.');
    }
    final project = AnimationProject(
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      fps: ((json['fps'] as num?)?.toInt() ?? 12).clamp(1, 60).toInt(),
    )..frameCount = json['frameCount'] as int;
    project.layers
      ..clear()
      ..addAll(
        (json['layers'] as List<dynamic>).map(
          (layer) => AnimationLayer.fromJson(layer as Map<String, dynamic>),
        ),
      );
    if (project.layers.isEmpty) {
      project.layers.add(AnimationLayer(name: 'Capa 1'));
    }
    return project;
  }
}
