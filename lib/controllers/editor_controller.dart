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
  double zoom = 1;
  int activeFrame = 0;
  int activeLayer = 0;
  bool onionSkin = true;
  bool gridEnabled = false;
  bool isPlaying = false;
  bool isSaving = false;
  bool hasUnsavedChanges = false;
  String? lastSavedPath;
  Timer? _playbackTimer;
  final Map<String, List<DrawingStroke>> _redoStrokes =
      <String, List<DrawingStroke>>{};

  AnimationLayer get layer => project.layers[activeLayer];
  List<DrawingStroke> get strokes => layer.strokesAt(activeFrame);
  String get _historyKey => '$activeLayer:$activeFrame';
  bool get canUndo => strokes.isNotEmpty;
  bool get canRedo => _redoStrokes[_historyKey]?.isNotEmpty ?? false;

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

  void setZoom(double next) {
    final safeZoom = next.clamp(0.25, 8.0);
    if (zoom == safeZoom) return;
    zoom = safeZoom;
    notifyListeners();
  }

  void resetZoom() => setZoom(1);

  void beginStroke(Offset point) {
    if (layer.locked || !layer.visible) return;
    if (tool != DrawingTool.brush && tool != DrawingTool.eraser) return;
    strokes.add(DrawingStroke(
      points: <Offset>[point],
      color: color,
      width: brushSize,
      erase: tool == DrawingTool.eraser,
    ));
    _redoStrokes.remove(_historyKey);
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
      (_redoStrokes[_historyKey] ??= <DrawingStroke>[])
          .add(strokes.removeLast());
      hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void redo() {
    final history = _redoStrokes[_historyKey];
    if (history == null || history.isEmpty) return;
    strokes.add(history.removeLast());
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearFrame() {
    strokes.clear();
    _redoStrokes.remove(_historyKey);
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

  bool deleteFrame() {
    if (project.frameCount <= 1) return false;
    final removedFrame = activeFrame;
    for (final item in project.layers) {
      item.frames.remove(removedFrame);
      final shiftedFrames = <int, List<DrawingStroke>>{};
      for (final entry in item.frames.entries) {
        shiftedFrames[entry.key > removedFrame ? entry.key - 1 : entry.key] =
            entry.value;
      }
      item.frames
        ..clear()
        ..addAll(shiftedFrames);
    }
    project.frameCount--;
    activeFrame = activeFrame.clamp(0, project.frameCount - 1);
    _redoStrokes.clear();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
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

  void renameActiveLayer(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName == layer.name) return;
    layer.name = trimmedName;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void setActiveLayerOpacity(double value) {
    layer.opacity = value.clamp(0, 1);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  bool moveActiveLayerUp() {
    if (activeLayer <= 0) return false;
    final selectedLayer = project.layers.removeAt(activeLayer);
    activeLayer--;
    project.layers.insert(activeLayer, selectedLayer);
    _redoStrokes.clear();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool moveActiveLayerDown() {
    if (activeLayer >= project.layers.length - 1) return false;
    final selectedLayer = project.layers.removeAt(activeLayer);
    activeLayer++;
    project.layers.insert(activeLayer, selectedLayer);
    _redoStrokes.clear();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool deleteActiveLayer() {
    if (project.layers.length <= 1) return false;
    project.layers.removeAt(activeLayer);
    activeLayer = activeLayer.clamp(0, project.layers.length - 1);
    _redoStrokes.clear();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
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
