import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/animation_models.dart';
import '../services/project_storage.dart';

class EditorController extends ChangeNotifier {
  EditorController(this.project, {ProjectStorage? storage})
    : storage = storage ?? ProjectStorage();

  final AnimationProject project;
  final ProjectStorage storage;
  DrawingTool tool = DrawingTool.brush;
  Color color = const Color(0xFF17192B);
  double brushSize = 10;
  double brushOpacity = 1;
  double stabilization = 0.25;
  BrushPreset brushPreset = BrushPreset.ink;
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
  DrawingStroke? selectedStroke;
  DrawingText? selectedText;
  List<Offset>? _selectionStartPoints;
  Offset? _selectionStartTextPosition;

  AnimationLayer get layer => project.layers[activeLayer];
  List<DrawingStroke> get strokes => layer.strokesAt(activeFrame);
  List<DrawingText> get texts => layer.textsAt(activeFrame);
  List<DrawingRegionFill> get regionFills =>
      layer.regionFills.putIfAbsent(activeFrame, () => <DrawingRegionFill>[]);
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;
  Duration get playbackInterval =>
      Duration(milliseconds: (1000 / project.fps).round());

  void selectTool(DrawingTool next) {
    tool = next;
    if (next != DrawingTool.select) clearSelection(notify: false);
    notifyListeners();
  }

  bool selectAt(Offset point) {
    if (layer.locked || !layer.visible) return false;
    selectedStroke = null;
    selectedText = null;

    var closestDistance = double.infinity;
    for (final item in texts.reversed) {
      final distance = (item.position - point).distanceSquared;
      if (distance < closestDistance && distance <= 0.02) {
        closestDistance = distance;
        selectedText = item;
      }
    }
    if (selectedText == null) {
      for (final stroke in strokes.reversed) {
        for (final strokePoint in stroke.points) {
          final distance = (strokePoint - point).distanceSquared;
          if (distance < closestDistance && distance <= 0.0064) {
            closestDistance = distance;
            selectedStroke = stroke;
          }
        }
      }
    }
    notifyListeners();
    return selectedStroke != null || selectedText != null;
  }

  void beginSelectionTransform() {
    _selectionStartPoints = selectedStroke == null
        ? null
        : List<Offset>.from(selectedStroke!.points);
    _selectionStartTextPosition = selectedText?.position;
  }

  void moveSelection(Offset delta) {
    if (selectedStroke != null) {
      for (var index = 0; index < selectedStroke!.points.length; index++) {
        selectedStroke!.points[index] = _clampPoint(
          selectedStroke!.points[index] + delta,
        );
      }
    } else if (selectedText != null) {
      selectedText!.position = _clampPoint(selectedText!.position + delta);
    } else {
      return;
    }
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void finishSelectionTransform() {
    if (selectedStroke != null && _selectionStartPoints != null) {
      final next = List<Offset>.from(selectedStroke!.points);
      if (!_samePoints(_selectionStartPoints!, next)) {
        _recordAction(
          _MoveStrokeAction(selectedStroke!, _selectionStartPoints!, next),
        );
      }
    } else if (selectedText != null && _selectionStartTextPosition != null) {
      final next = selectedText!.position;
      if (next != _selectionStartTextPosition) {
        _recordAction(
          _MoveTextAction(selectedText!, _selectionStartTextPosition!, next),
        );
      }
    }
    _selectionStartPoints = null;
    _selectionStartTextPosition = null;
  }

  bool deleteSelection() {
    if (selectedStroke != null) {
      final index = strokes.indexOf(selectedStroke!);
      if (index < 0) return false;
      final item = strokes.removeAt(index);
      _recordAction(_RemoveStrokeAction(strokes, item, index));
    } else if (selectedText != null) {
      final index = texts.indexOf(selectedText!);
      if (index < 0) return false;
      final item = texts.removeAt(index);
      _recordAction(_RemoveTextAction(texts, item, index));
    } else {
      return false;
    }
    clearSelection(notify: false);
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool scaleSelection(double factor) {
    if (factor <= 0) return false;
    if (selectedStroke != null && selectedStroke!.points.isNotEmpty) {
      final previous = List<Offset>.from(selectedStroke!.points);
      final center =
          previous.reduce((a, b) => a + b) / previous.length.toDouble();
      final next = previous
          .map((point) => _clampPoint(center + (point - center) * factor))
          .toList();
      selectedStroke!.points
        ..clear()
        ..addAll(next);
      _recordAction(_MoveStrokeAction(selectedStroke!, previous, next));
    } else if (selectedText != null) {
      final previous = selectedText!.fontSize;
      final next = (previous * factor).clamp(8, 240).toDouble();
      if (previous == next) return false;
      selectedText!.fontSize = next;
      _recordAction(_ScaleTextAction(selectedText!, previous, next));
    } else {
      return false;
    }
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool rotateSelection(double radians) {
    if (radians == 0) return false;
    if (selectedStroke != null && selectedStroke!.points.isNotEmpty) {
      final previous = List<Offset>.from(selectedStroke!.points);
      final center =
          previous.reduce((a, b) => a + b) / previous.length.toDouble();
      final cosine = math.cos(radians);
      final sine = math.sin(radians);
      final next = previous.map((point) {
        final relative = point - center;
        return _clampPoint(
          center +
              Offset(
                relative.dx * cosine - relative.dy * sine,
                relative.dx * sine + relative.dy * cosine,
              ),
        );
      }).toList();
      selectedStroke!.points
        ..clear()
        ..addAll(next);
      _recordAction(_MoveStrokeAction(selectedStroke!, previous, next));
    } else if (selectedText != null) {
      final previous = selectedText!.rotation;
      final next = previous + radians;
      selectedText!.rotation = next;
      _recordAction(_RotateTextAction(selectedText!, previous, next));
    } else {
      return false;
    }
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool editSelectedText(String value) {
    final item = selectedText;
    final next = value.trim();
    if (item == null || next.isEmpty || next == item.text) return false;
    final previous = item.text;
    item.text = next;
    _recordAction(_EditTextAction(item, previous, next));
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  void clearSelection({bool notify = true}) {
    selectedStroke = null;
    selectedText = null;
    _selectionStartPoints = null;
    _selectionStartTextPosition = null;
    if (notify) notifyListeners();
  }

  Offset _clampPoint(Offset point) =>
      Offset(point.dx.clamp(0, 1).toDouble(), point.dy.clamp(0, 1).toDouble());

  bool _samePoints(List<Offset> first, List<Offset> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
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

  void setBrushOpacity(double next) {
    brushOpacity = next.clamp(0.05, 1).toDouble();
    notifyListeners();
  }

  void setStabilization(double next) {
    stabilization = next.clamp(0, 0.9).toDouble();
    notifyListeners();
  }

  void selectBrushPreset(BrushPreset preset) {
    brushPreset = preset;
    switch (preset) {
      case BrushPreset.pencil:
        brushSize = 3;
        brushOpacity = 0.9;
        stabilization = 0.15;
        break;
      case BrushPreset.ink:
        brushSize = 8;
        brushOpacity = 1;
        stabilization = 0.35;
        break;
      case BrushPreset.marker:
        brushSize = 24;
        brushOpacity = 0.45;
        stabilization = 0.1;
        break;
    }
    tool = DrawingTool.brush;
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
      fillRegion(point);
      return;
    }
    if (tool != DrawingTool.brush && tool != DrawingTool.eraser) return;
    final stroke = DrawingStroke(
      points: <Offset>[point],
      color: color.withValues(alpha: brushOpacity),
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
    final points = strokes.last.points;
    if (points.isEmpty) return;
    final smoothed = Offset.lerp(point, points.last, stabilization)!;
    points.add(smoothed);
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
    final previousRegionFills = List<DrawingRegionFill>.from(regionFills);
    if (strokes.isEmpty &&
        texts.isEmpty &&
        previousFill == null &&
        previousRegionFills.isEmpty) {
      return;
    }
    final previous = List<DrawingStroke>.from(strokes);
    final previousTexts = List<DrawingText>.from(texts);
    strokes.clear();
    texts.clear();
    regionFills.clear();
    layer.fills.remove(activeFrame);
    _recordAction(
      _ClearFrameAction(
        strokes,
        layer,
        activeFrame,
        previous,
        previousTexts,
        previousRegionFills,
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

  bool fillRegion(Offset point) {
    DrawingStroke? boundary;
    var smallestArea = double.infinity;
    for (final stroke in strokes) {
      if (stroke.erase || !_isClosed(stroke.points)) continue;
      if (!_containsPoint(stroke.points, point)) continue;
      final area = _polygonArea(stroke.points).abs();
      if (area < smallestArea) {
        smallestArea = area;
        boundary = stroke;
      }
    }
    if (boundary == null) {
      fillFrame();
      return false;
    }
    final item = DrawingRegionFill(
      boundary: List<Offset>.from(boundary.points),
      color: color,
    );
    regionFills.add(item);
    _recordAction(_RegionFillAction(regionFills, item));
    hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool _isClosed(List<Offset> points) =>
      points.length >= 3 && (points.first - points.last).distance <= 0.04;

  bool _containsPoint(List<Offset> polygon, Offset point) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      final crosses = (a.dy > point.dy) != (b.dy > point.dy);
      if (crosses &&
          point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  double _polygonArea(List<Offset> polygon) {
    var area = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final next = polygon[(i + 1) % polygon.length];
      area += polygon[i].dx * next.dy - next.dx * polygon[i].dy;
    }
    return area / 2;
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
    clearSelection(notify: false);
  }

  void selectFrame(int index) {
    activeFrame = index.clamp(0, project.frameCount - 1);
    clearSelection(notify: false);
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
        final existingRegionFills = item.regionFills.remove(index);
        if (existingRegionFills != null) {
          item.regionFills[index + 1] = existingRegionFills;
        }
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
        final fills = item.regionFills[activeFrame];
        if (fills != null) {
          item.regionFills[insertAt] = fills
              .map((fill) => fill.copy())
              .toList();
        }
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
      item.regionFills.remove(removedFrame);
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
      final shiftedRegionFills = <int, List<DrawingRegionFill>>{};
      for (final entry in item.regionFills.entries) {
        shiftedRegionFills[entry.key > removedFrame
                ? entry.key - 1
                : entry.key] =
            entry.value;
      }
      item.regionFills
        ..clear()
        ..addAll(shiftedRegionFills);
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
    project.layers.insert(
      0,
      AnimationLayer(name: 'Capa ${project.layers.length + 1}'),
    );
    activeLayer = 0;
    _clearHistory();
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void selectLayer(int index) {
    activeLayer = index;
    clearSelection(notify: false);
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
      _startPlaybackTimer();
    }
    notifyListeners();
  }

  void setFps(int value) {
    final next = value.clamp(1, 60).toInt();
    if (project.fps == next) return;
    project.fps = next;
    hasUnsavedChanges = true;
    if (isPlaying) _startPlaybackTimer();
    notifyListeners();
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(playbackInterval, (_) {
      activeFrame = (activeFrame + 1) % project.frameCount;
      notifyListeners();
    });
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

class _RegionFillAction implements _EditAction {
  _RegionFillAction(this.target, this.item);

  final List<DrawingRegionFill> target;
  final DrawingRegionFill item;

  @override
  void undo() => target.remove(item);

  @override
  void redo() => target.add(item);
}

class _RemoveStrokeAction implements _EditAction {
  _RemoveStrokeAction(this.target, this.item, this.index);

  final List<DrawingStroke> target;
  final DrawingStroke item;
  final int index;

  @override
  void undo() => target.insert(index.clamp(0, target.length), item);

  @override
  void redo() => target.remove(item);
}

class _RemoveTextAction implements _EditAction {
  _RemoveTextAction(this.target, this.item, this.index);

  final List<DrawingText> target;
  final DrawingText item;
  final int index;

  @override
  void undo() => target.insert(index.clamp(0, target.length), item);

  @override
  void redo() => target.remove(item);
}

class _MoveStrokeAction implements _EditAction {
  _MoveStrokeAction(this.stroke, this.previous, this.next);

  final DrawingStroke stroke;
  final List<Offset> previous;
  final List<Offset> next;

  void _apply(List<Offset> points) {
    stroke.points
      ..clear()
      ..addAll(points);
  }

  @override
  void undo() => _apply(previous);

  @override
  void redo() => _apply(next);
}

class _MoveTextAction implements _EditAction {
  _MoveTextAction(this.item, this.previous, this.next);

  final DrawingText item;
  final Offset previous;
  final Offset next;

  @override
  void undo() => item.position = previous;

  @override
  void redo() => item.position = next;
}

class _ScaleTextAction implements _EditAction {
  _ScaleTextAction(this.item, this.previous, this.next);

  final DrawingText item;
  final double previous;
  final double next;

  @override
  void undo() => item.fontSize = previous;

  @override
  void redo() => item.fontSize = next;
}

class _RotateTextAction implements _EditAction {
  _RotateTextAction(this.item, this.previous, this.next);

  final DrawingText item;
  final double previous;
  final double next;

  @override
  void undo() => item.rotation = previous;

  @override
  void redo() => item.rotation = next;
}

class _EditTextAction implements _EditAction {
  _EditTextAction(this.item, this.previous, this.next);

  final DrawingText item;
  final String previous;
  final String next;

  @override
  void undo() => item.text = previous;

  @override
  void redo() => item.text = next;
}

class _ClearFrameAction implements _EditAction {
  _ClearFrameAction(
    this.target,
    this.layer,
    this.frame,
    this.previous,
    this.previousTexts,
    this.previousRegionFills,
    this.previousFill,
  );

  final List<DrawingStroke> target;
  final AnimationLayer layer;
  final int frame;
  final List<DrawingStroke> previous;
  final List<DrawingText> previousTexts;
  final List<DrawingRegionFill> previousRegionFills;
  final Color? previousFill;

  @override
  void undo() {
    target.addAll(previous);
    layer.textsAt(frame).addAll(previousTexts);
    layer.regionFills
        .putIfAbsent(frame, () => <DrawingRegionFill>[])
        .addAll(previousRegionFills);
    if (previousFill != null) layer.fills[frame] = previousFill!;
  }

  @override
  void redo() {
    target.clear();
    layer.textsAt(frame).clear();
    layer.regionFills.remove(frame);
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
