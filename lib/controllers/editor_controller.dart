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
  final List<_EditAction> _undoHistory = <_EditAction>[];
  final List<_EditAction> _redoHistory = <_EditAction>[];

  AnimationLayer get layer => project.layers[activeLayer];
  List<DrawingStroke> get strokes => layer.strokesAt(activeFrame);
  List<DrawingText> get texts => layer.textsAt(activeFrame);
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  void selectTool(DrawingTool next) {
    tool = next;
    notifyListeners();
  }

  void setColor(Color next) {
    color = next;
    if (tool != DrawingTool.fill && tool != DrawingTool.text) {
      tool = DrawingTool.brush;
    }
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
    if (tool == DrawingTool.fill) {
      fillFrame();
      return;
    }
    if (tool != DrawingTool.brush && tool != DrawingTool.eraser) return;
    final stroke = DrawingStroke(
      points: <Offset>[point],
      color: color,
      width: brushSize,
      erase: tool == DrawingTool.eraser,
    );
    strokes.add(stroke);
    _recordAction(_StrokeAction(strokes, stroke));
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (strokes.isEmpty) return;
    strokes.last.points.add(point);
    notifyListeners();
  }

  void undo() {
    if (_undoHistory.isEmpty) return;
    final action = _undoHistory.removeLast();
    action.undo();
    _redoHistory.add(action);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void redo() {
    if (_redoHistory.isEmpty) return;
    final action = _redoHistory.removeLast();
    action.redo();
    _undoHistory.add(action);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearFrame() {
    final previousFill = layer.fills[activeFrame];
    if (strokes.isEmpty && texts.isEmpty && previousFill == null) return;
    final previous = List<DrawingStroke>.from(strokes);
    final previousTexts = List<DrawingText>.from(texts);
    strokes.clear();
    texts.clear();
    layer.fills.remove(activeFrame);
    _recordAction(
      _ClearFrameAction(
        strokes,
        layer,
        activeFrame,
        previous,
        previousTexts,
        previousFill,
      ),
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void fillFrame() {
    final previous = layer.fills[activeFrame];
    if (previous == color) return;
    layer.fills[activeFrame] = color;
    _recordAction(_FillAction(layer, activeFrame, previous, color));
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void addText(String value, Offset position) {
    final trimmedText = value.trim();
    if (trimmedText.isEmpty || layer.locked || !layer.visible) return;
    final item = DrawingText(
      text: trimmedText,
      position: position,
      color: color,
      fontSize: (brushSize * 2.4).clamp(16, 96),
    );
    texts.add(item);
    _recordAction(_TextAction(texts, item));
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void _recordAction(_EditAction action) {
    _undoHistory.add(action);
    _redoHistory.clear();
  }

  void _clearHistory() {
    _undoHistory.clear();
    _redoHistory.clear();
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
        final existingFill = item.fills.remove(index);
        if (existingFill != null) item.fills[index + 1] = existingFill;
        final existingTexts = item.texts.remove(index);
        if (existingTexts != null) item.texts[index + 1] = existingTexts;
      }
      if (duplicate) {
        item.frames[insertAt] = item
            .strokesAt(activeFrame)
            .map((stroke) => stroke.copy())
            .toList();
        final fill = item.fills[activeFrame];
        if (fill != null) item.fills[insertAt] = fill;
        item.texts[insertAt] = item
            .textsAt(activeFrame)
            .map((text) => text.copy())
            .toList();
      }
    }
    project.frameCount++;
    activeFrame = insertAt;
    _clearHistory();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  bool deleteFrame() {
    if (project.frameCount <= 1) return false;
    final removedFrame = activeFrame;
    for (final item in project.layers) {
      item.frames.remove(removedFrame);
      item.fills.remove(removedFrame);
      item.texts.remove(removedFrame);
      final shiftedFrames = <int, List<DrawingStroke>>{};
      for (final entry in item.frames.entries) {
        shiftedFrames[entry.key > removedFrame ? entry.key - 1 : entry.key] =
            entry.value;
      }
      item.frames
        ..clear()
        ..addAll(shiftedFrames);
      final shiftedFills = <int, Color>{};
      for (final entry in item.fills.entries) {
        shiftedFills[entry.key > removedFrame ? entry.key - 1 : entry.key] =
            entry.value;
      }
      item.fills
        ..clear()
        ..addAll(shiftedFills);
      final shiftedTexts = <int, List<DrawingText>>{};
      for (final entry in item.texts.entries) {
        shiftedTexts[entry.key > removedFrame ? entry.key - 1 : entry.key] =
            entry.value;
      }
      item.texts
        ..clear()
        ..addAll(shiftedTexts);
    }
    project.frameCount--;
    activeFrame = activeFrame.clamp(0, project.frameCount - 1);
    _clearHistory();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  void addLayer() {
    project.layers.insert(0, AnimationLayer(name: 'Capa ${project.layers.length + 1}'));
    activeLayer = 0;
    _clearHistory();
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
    _clearHistory();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool moveActiveLayerDown() {
    if (activeLayer >= project.layers.length - 1) return false;
    final selectedLayer = project.layers.removeAt(activeLayer);
    activeLayer++;
    project.layers.insert(activeLayer, selectedLayer);
    _clearHistory();
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool deleteActiveLayer() {
    if (project.layers.length <= 1) return false;
    project.layers.removeAt(activeLayer);
    activeLayer = activeLayer.clamp(0, project.layers.length - 1);
    _clearHistory();
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

abstract class _EditAction {
  void undo();
  void redo();
}

class _StrokeAction implements _EditAction {
  _StrokeAction(this.target, this.stroke);

  final List<DrawingStroke> target;
  final DrawingStroke stroke;

  @override
  void undo() => target.remove(stroke);

  @override
  void redo() => target.add(stroke);
}

class _TextAction implements _EditAction {
  _TextAction(this.target, this.item);

  final List<DrawingText> target;
  final DrawingText item;

  @override
  void undo() => target.remove(item);

  @override
  void redo() => target.add(item);
}

class _ClearFrameAction implements _EditAction {
  _ClearFrameAction(
    this.target,
    this.layer,
    this.frame,
    this.previous,
    this.previousTexts,
    this.previousFill,
  );

  final List<DrawingStroke> target;
  final AnimationLayer layer;
  final int frame;
  final List<DrawingStroke> previous;
  final List<DrawingText> previousTexts;
  final Color? previousFill;

  @override
  void undo() {
    target.addAll(previous);
    layer.textsAt(frame).addAll(previousTexts);
    if (previousFill != null) layer.fills[frame] = previousFill!;
  }

  @override
  void redo() {
    target.clear();
    layer.textsAt(frame).clear();
    layer.fills.remove(frame);
  }
}

class _FillAction implements _EditAction {
  _FillAction(this.layer, this.frame, this.previous, this.next);

  final AnimationLayer layer;
  final int frame;
  final Color? previous;
  final Color next;

  @override
  void undo() {
    if (previous == null) {
      layer.fills.remove(frame);
    } else {
      layer.fills[frame] = previous!;
    }
  }

  @override
  void redo() => layer.fills[frame] = next;
}
