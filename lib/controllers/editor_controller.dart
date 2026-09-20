import 'dart:async';

import 'package:flutter/material.dart';

import '../models/animation_models.dart';
import '../services/project_storage.dart';

class EditorController extends ChangeNotifier {
  EditorController(this.project, {ProjectStorage? storage})
      : storage = storage ?? const ProjectStorage();

  final AnimationProject project;
  final ProjectStorage storage;
  DrawingTool tool = DrawingTool.brush;
  Color color = const Color(0xFF17192B);
  double brushSize = 10;
  int activeFrame = 0;
  int activeLayer = 0;
  bool onionSkin = true;
  bool gridEnabled = false;
  bool isPlaying = false;
  bool isSaving = false;
  bool hasUnsavedChanges = false;
  String? lastSavedPath;
  Timer? _playbackTimer;

  AnimationLayer get layer => project.layers[activeLayer];
  List<DrawingStroke> get strokes => layer.strokesAt(activeFrame);

  void selectTool(DrawingTool next) {
    tool = next;
    notifyListeners();
  }

  void setColor(Color next) {
    color = next;
    tool = DrawingTool.brush;
    notifyListeners();
  }

  void setBrushSize(double next) {
    brushSize = next;
    notifyListeners();
  }

  void beginStroke(Offset point) {
    if (layer.locked || !layer.visible) return;
    if (tool != DrawingTool.brush && tool != DrawingTool.eraser) return;
    strokes.add(DrawingStroke(
      points: <Offset>[point],
      color: color,
      width: brushSize,
      erase: tool == DrawingTool.eraser,
    ));
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (strokes.isEmpty) return;
    strokes.last.points.add(point);
    notifyListeners();
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void clearFrame() {
    strokes.clear();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void selectFrame(int index) {
    activeFrame = index.clamp(0, project.frameCount - 1);
    notifyListeners();
  }

  void setOnionSkin(bool value) {
    onionSkin = value;
    notifyListeners();
  }

  void setGridEnabled(bool value) {
    gridEnabled = value;
    notifyListeners();
  }

  void addFrame({bool duplicate = false}) {
    final insertAt = activeFrame + 1;
    for (final item in project.layers) {
      for (var index = project.frameCount - 1; index >= insertAt; index--) {
        final existing = item.frames.remove(index);
        if (existing != null) item.frames[index + 1] = existing;
      }
      if (duplicate) {
        item.frames[insertAt] = item
            .strokesAt(activeFrame)
            .map((stroke) => stroke.copy())
            .toList();
      }
    }
    project.frameCount++;
    activeFrame = insertAt;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void addLayer() {
    project.layers.insert(0, AnimationLayer(name: 'Capa ${project.layers.length + 1}'));
    activeLayer = 0;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void selectLayer(int index) {
    activeLayer = index;
    notifyListeners();
  }

  void toggleLayerVisibility(int index) {
    project.layers[index].visible = !project.layers[index].visible;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void toggleLayerLock(int index) {
    project.layers[index].locked = !project.layers[index].locked;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void togglePlayback() {
    if (isPlaying) {
      _playbackTimer?.cancel();
      isPlaying = false;
    } else {
      isPlaying = true;
      _playbackTimer = Timer.periodic(
        Duration(milliseconds: (1000 / project.fps).round()),
        (_) {
          activeFrame = (activeFrame + 1) % project.frameCount;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  Future<String> saveProject() async {
    if (isSaving) return lastSavedPath ?? '';
    isSaving = true;
    notifyListeners();
    try {
      final file = await storage.save(project);
      lastSavedPath = file.path;
      hasUnsavedChanges = false;
      return file.path;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
