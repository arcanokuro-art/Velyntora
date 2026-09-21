import 'package:flutter/material.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';
import '../services/frame_exporter.dart';
import '../theme/velyntora_theme.dart';
import '../widgets/drawing_canvas.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});
  final AnimationProject project;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController controller = EditorController(widget.project);
  final FrameExporter exporter = const FrameExporter();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          children: <Widget>[
            _TopBar(
              controller: controller,
              onExport: () => _showExportOptions(context),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1100;
                  return Row(
                    children: <Widget>[
                      _ToolBar(controller: controller),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ColoredBox(
                                color: const Color(0xFF222538),
                                child: Padding(
                                  padding: EdgeInsets.all(compact ? 10 : 28),
                                  child: DrawingCanvas(controller: controller),
                                ),
                              ),
                            ),
                            _Timeline(controller: controller, compact: compact),
                          ],
                        ),
                      ),
                      if (!compact) _PropertiesPanel(controller: controller),
                    ],
                  );
                },
              ),
            ),
            _StatusBar(controller: controller),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFrame(BuildContext context) async {
    try {
      final file = await exporter.exportCurrentFrame(controller);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG exportado en ${file.path}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar: $error')),
        );
      }
    }
  }

  Future<void> _exportSequence(BuildContext context) async {
    try {
      final files = await exporter.exportPngSequence(controller);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${files.length} PNG exportados en ${files.first.parent.path}',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar: $error')),
        );
      }
    }
  }

  Future<void> _showExportOptions(BuildContext context) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              title: Text('Exportar'),
              subtitle: Text('Los archivos se guardan sin guías ni piel de cebolla.'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Fotograma actual'),
              subtitle: const Text('Una imagen PNG a resolución completa'),
              onTap: () => Navigator.pop(sheetContext, 'frame'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Secuencia PNG'),
              subtitle: Text('${controller.project.frameCount} fotogramas numerados'),
              onTap: () => Navigator.pop(sheetContext, 'sequence'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (option == 'frame') await _exportFrame(context);
    if (option == 'sequence') await _exportSequence(context);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onExport});
  final EditorController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          return Container(
            height: 62,
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 14),
            decoration: const BoxDecoration(color: VelyntoraColors.surface, border: Border(bottom: BorderSide(color: VelyntoraColors.border))),
            child: Row(children: <Widget>[
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Volver a proyectos'),
              Image.asset('assets/branding/velyntora_icon.png', width: 32, height: 32),
              const SizedBox(width: 8),
              Expanded(child: Text(controller.project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (!compact) ...<Widget>[
                const SizedBox(width: 18),
                _SavedBadge(controller: controller),
              ],
              if (compact) IconButton(onPressed: () => _showMobilePanel(context), icon: const Icon(Icons.layers_rounded), tooltip: 'Pincel y capas'),
              IconButton(onPressed: controller.canUndo ? controller.undo : null, icon: const Icon(Icons.undo_rounded), tooltip: 'Deshacer'),
              IconButton(onPressed: controller.canRedo ? controller.redo : null, icon: const Icon(Icons.redo_rounded), tooltip: 'Rehacer'),
              if (compact)
                IconButton(onPressed: controller.isSaving ? null : () => _save(context), icon: const Icon(Icons.save_outlined), tooltip: 'Guardar')
              else
                OutlinedButton.icon(
                  onPressed: controller.isSaving ? null : () => _save(context),
                  icon: controller.isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(controller.isSaving ? 'Guardando' : 'Guardar'),
                ),
              const SizedBox(width: 6),
              if (compact)
                IconButton.filled(onPressed: onExport, icon: const Icon(Icons.ios_share_rounded), tooltip: 'Exportar')
              else
                FilledButton.icon(onPressed: onExport, icon: const Icon(Icons.ios_share_rounded), label: const Text('Exportar')),
            ]),
          );
        },
      );

  void _showMobilePanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VelyntoraColors.surface,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.9,
        child: _PropertiesPanel(controller: controller),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      final path = await controller.saveProject();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proyecto guardado en $path')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $error')),
        );
      }
    }
  }
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({required this.controller});
  final EditorController controller;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(children: <Widget>[
          Icon(controller.hasUnsavedChanges ? Icons.edit_rounded : Icons.check_circle_rounded, size: 15, color: controller.hasUnsavedChanges ? Colors.amberAccent : Colors.greenAccent),
          const SizedBox(width: 5),
          Text(controller.hasUnsavedChanges ? 'Cambios sin guardar' : 'Guardado', style: TextStyle(fontSize: 12, color: controller.hasUnsavedChanges ? Colors.amberAccent : Colors.greenAccent)),
        ]),
      );
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    const tools = <(DrawingTool, IconData, String)>[
      (DrawingTool.brush, Icons.brush_rounded, 'Pincel'),
      (DrawingTool.eraser, Icons.auto_fix_normal_rounded, 'Borrador'),
      (DrawingTool.fill, Icons.format_color_fill_rounded, 'Relleno'),
      (DrawingTool.select, Icons.select_all_rounded, 'Selección'),
      (DrawingTool.text, Icons.text_fields_rounded, 'Texto'),
      (DrawingTool.hand, Icons.pan_tool_alt_rounded, 'Mover'),
    ];
    return Container(
      width: 60,
      color: VelyntoraColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: <Widget>[
        for (final item in tools)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: IconButton.filledTonal(
              onPressed: () => controller.selectTool(item.$1),
              icon: Icon(item.$2),
              tooltip: item.$3,
              style: IconButton.styleFrom(
                fixedSize: const Size(40, 40),
                backgroundColor: controller.tool == item.$1 ? VelyntoraColors.violet.withValues(alpha: 0.28) : Colors.transparent,
                foregroundColor: controller.tool == item.$1 ? VelyntoraColors.cyan : VelyntoraColors.muted,
              ),
            ),
          ),
        const Spacer(),
        IconButton(onPressed: controller.clearFrame, icon: const Icon(Icons.delete_sweep_outlined), tooltip: 'Limpiar fotograma', style: IconButton.styleFrom(fixedSize: const Size(40, 40))),
      ]),
    );
  }
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) => Container(
        width: 280,
        color: VelyntoraColors.surface,
        child: ListView(children: <Widget>[
          if (controller.tool == DrawingTool.select)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Selección', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    controller.selectedStroke != null
                        ? 'Trazo seleccionado'
                        : controller.selectedText != null
                            ? 'Texto seleccionado'
                            : 'Toca un trazo o texto para seleccionarlo',
                    style: const TextStyle(color: VelyntoraColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                    IconButton.filledTonal(
                      onPressed: controller.selectedStroke != null || controller.selectedText != null
                          ? () => controller.scaleSelection(0.8)
                          : null,
                      icon: const Icon(Icons.zoom_out_map_rounded),
                      tooltip: 'Reducir selección',
                    ),
                    IconButton.filledTonal(
                      onPressed: controller.selectedStroke != null || controller.selectedText != null
                          ? () => controller.scaleSelection(1.25)
                          : null,
                      icon: const Icon(Icons.zoom_in_map_rounded),
                      tooltip: 'Ampliar selección',
                    ),
                    IconButton.filledTonal(
                      onPressed: controller.selectedStroke != null || controller.selectedText != null
                          ? () => controller.rotateSelection(-0.261799)
                          : null,
                      icon: const Icon(Icons.rotate_left_rounded),
                      tooltip: 'Girar 15° a la izquierda',
                    ),
                    IconButton.filledTonal(
                      onPressed: controller.selectedStroke != null || controller.selectedText != null
                          ? () => controller.rotateSelection(0.261799)
                          : null,
                      icon: const Icon(Icons.rotate_right_rounded),
                      tooltip: 'Girar 15° a la derecha',
                    ),
                    if (controller.selectedText != null)
                      IconButton.filledTonal(
                        onPressed: () => _editSelectedText(context),
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Editar texto',
                      ),
                    IconButton.filledTonal(
                      onPressed: controller.selectedStroke != null || controller.selectedText != null
                          ? controller.deleteSelection
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Eliminar selección',
                    ),
                  ]),
                ],
              ),
            )
          else
            Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('Pincel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<BrushPreset>(
                initialValue: controller.brushPreset,
                decoration: const InputDecoration(labelText: 'Ajuste rápido', isDense: true),
                items: const <DropdownMenuItem<BrushPreset>>[
                  DropdownMenuItem(value: BrushPreset.pencil, child: Text('Lápiz')),
                  DropdownMenuItem(value: BrushPreset.ink, child: Text('Tinta')),
                  DropdownMenuItem(value: BrushPreset.marker, child: Text('Marcador')),
                ],
                onChanged: (value) {
                  if (value != null) controller.selectBrushPreset(value);
                },
              ),
              const SizedBox(height: 16),
              Row(children: <Widget>[
                Container(width: 42, height: 42, decoration: BoxDecoration(color: controller.color, shape: BoxShape.circle, border: Border.all(color: Colors.white24))),
                const SizedBox(width: 12),
                Expanded(child: Text('Tamaño ${controller.brushSize.round()} px')),
              ]),
              Slider(value: controller.brushSize, min: 1, max: 80, onChanged: controller.setBrushSize),
              Row(children: <Widget>[
                const Expanded(child: Text('Opacidad')),
                Text('${(controller.brushOpacity * 100).round()}%'),
              ]),
              Slider(value: controller.brushOpacity, min: 0.05, max: 1, onChanged: controller.setBrushOpacity),
              Row(children: <Widget>[
                const Expanded(child: Text('Estabilización')),
                Text('${(controller.stabilization * 100).round()}%'),
              ]),
              Slider(value: controller.stabilization, min: 0, max: 0.9, onChanged: controller.setStabilization),
              const SizedBox(height: 8),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: <Color>[
                  const Color(0xFF17192B),
                  const Color(0xFF7357FF),
                  const Color(0xFFF05CE7),
                  const Color(0xFF21D4F7),
                  const Color(0xFFFFC857),
                  const Color(0xFFFF5E78),
                ]
                    .map(
                      (color) => InkWell(
                        onTap: () => controller.setColor(color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.color == color
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
            child: Row(children: <Widget>[
              const Expanded(child: Text('Capas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              IconButton(onPressed: controller.activeLayer > 0 ? controller.moveActiveLayerUp : null, icon: const Icon(Icons.arrow_upward_rounded), tooltip: 'Subir capa'),
              IconButton(onPressed: controller.activeLayer < controller.project.layers.length - 1 ? controller.moveActiveLayerDown : null, icon: const Icon(Icons.arrow_downward_rounded), tooltip: 'Bajar capa'),
              IconButton(onPressed: controller.project.layers.length > 1 ? () => _deleteLayer(context) : null, icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Eliminar capa'),
              IconButton(onPressed: controller.addLayer, icon: const Icon(Icons.add_rounded), tooltip: 'Añadir capa'),
            ]),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              itemCount: controller.project.layers.length,
              itemBuilder: (context, index) {
                final layer = controller.project.layers[index];
                final selected = index == controller.activeLayer;
                return Container(
                  color: selected ? VelyntoraColors.violet.withValues(alpha: 0.14) : null,
                  child: ListTile(
                    dense: true,
                    onTap: () => controller.selectLayer(index),
                    leading: IconButton(onPressed: () => controller.toggleLayerVisibility(index), icon: Icon(layer.visible ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 19)),
                    title: Row(children: <Widget>[
                      Expanded(child: Text(layer.name, overflow: TextOverflow.ellipsis)),
                      IconButton(
                        onPressed: selected ? () => _renameLayer(context) : null,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        tooltip: 'Renombrar capa',
                        visualDensity: VisualDensity.compact,
                      ),
                    ]),
                    trailing: IconButton(onPressed: () => controller.toggleLayerLock(index), icon: Icon(layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Row(children: <Widget>[
              Expanded(child: Text('Opacidad de ${controller.layer.name}', overflow: TextOverflow.ellipsis)),
              Text('${(controller.layer.opacity * 100).round()}%'),
            ]),
          ),
          Slider(value: controller.layer.opacity, min: 0, max: 1, onChanged: controller.setActiveLayerOpacity),
          SwitchListTile(title: const Text('Papel cebolla'), value: controller.onionSkin, onChanged: controller.setOnionSkin),
          SwitchListTile(title: const Text('Cuadrícula'), value: controller.gridEnabled, onChanged: controller.setGridEnabled),
        ]),
      );

  void _deleteLayer(BuildContext context) {
    if (!controller.deleteActiveLayer()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El proyecto debe conservar al menos una capa.')),
      );
    }
  }

  Future<void> _editSelectedText(BuildContext context) async {
    final selected = controller.selectedText;
    if (selected == null) return;
    final textController = TextEditingController(text: selected.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar texto'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 3,
          maxLength: 160,
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, textController.text), child: const Text('Guardar')),
        ],
      ),
    );
    textController.dispose();
    if (value != null) controller.editSelectedText(value);
  }

  Future<void> _renameLayer(BuildContext context) async {
    final textController = TextEditingController(text: controller.layer.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renombrar capa'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, textController.text), child: const Text('Guardar')),
        ],
      ),
    );
    textController.dispose();
    if (name != null) controller.renameActiveLayer(name);
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller, required this.compact});
  final EditorController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        height: compact ? 132 : 172,
        decoration: const BoxDecoration(color: VelyntoraColors.surface, border: Border(top: BorderSide(color: VelyntoraColors.border))),
        child: Column(children: <Widget>[
          SizedBox(
            height: 46,
            child: Row(children: <Widget>[
              const SizedBox(width: 14),
              IconButton(onPressed: () => controller.selectFrame(controller.activeFrame - 1), icon: const Icon(Icons.skip_previous_rounded)),
              IconButton.filled(onPressed: controller.togglePlayback, icon: Icon(controller.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)),
              IconButton(onPressed: () => controller.selectFrame(controller.activeFrame + 1), icon: const Icon(Icons.skip_next_rounded)),
              const SizedBox(width: 12),
              Text('${controller.activeFrame + 1} / ${controller.project.frameCount}'),
              const SizedBox(width: 14),
              Text('${controller.project.fps} FPS', style: const TextStyle(color: VelyntoraColors.muted)),
              const Spacer(),
              if (!compact) TextButton.icon(onPressed: () => controller.addFrame(duplicate: true), icon: const Icon(Icons.copy_rounded), label: const Text('Duplicar')),
              IconButton(
                onPressed: () => _deleteFrame(context),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar fotograma',
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(onPressed: controller.addFrame, icon: const Icon(Icons.add_rounded), label: const Text('Fotograma')),
              const SizedBox(width: 14),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: controller.project.frameCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == controller.activeFrame;
                return InkWell(
                  onTap: () => controller.selectFrame(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: compact ? 86 : 116,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? VelyntoraColors.cyan : VelyntoraColors.border, width: selected ? 3 : 1)),
                    child: Stack(children: <Widget>[
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: FrameThumbnail(
                            key: ValueKey<String>('frame-thumbnail-$index'),
                            controller: controller,
                            frame: index,
                          ),
                        ),
                      ),
                      Positioned(left: 6, top: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), child: Text('${index + 1}', style: const TextStyle(fontSize: 11)))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );

  void _deleteFrame(BuildContext context) {
    if (!controller.deleteFrame()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El proyecto debe conservar al menos un fotograma.')),
      );
    }
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xFF090B15),
        child: Row(children: <Widget>[
          Text('${controller.project.width} × ${controller.project.height}', style: const TextStyle(fontSize: 11, color: VelyntoraColors.muted)),
          const SizedBox(width: 18),
          Text('${controller.project.layers.length} capa(s)', style: const TextStyle(fontSize: 11, color: VelyntoraColors.muted)),
          const Spacer(),
          Text('Zoom ${(controller.zoom * 100).round()}%', style: const TextStyle(fontSize: 11, color: VelyntoraColors.muted)),
        ]),
      );
}
