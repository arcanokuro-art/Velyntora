import 'package:flutter/material.dart';

import '../controllers/editor_controller.dart';
import '../models/animation_models.dart';
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
            _TopBar(controller: controller),
            Expanded(
              child: Row(
                children: <Widget>[
                  _ToolBar(controller: controller),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ColoredBox(
                            color: const Color(0xFF222538),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: DrawingCanvas(controller: controller),
                            ),
                          ),
                        ),
                        _Timeline(controller: controller),
                      ],
                    ),
                  ),
                  _PropertiesPanel(controller: controller),
                ],
              ),
            ),
            _StatusBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(color: VelyntoraColors.surface, border: Border(bottom: BorderSide(color: VelyntoraColors.border))),
        child: Row(children: <Widget>[
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Volver a proyectos'),
          const SizedBox(width: 6),
          Image.asset('assets/branding/velyntora_icon.png', width: 34, height: 34),
          const SizedBox(width: 10),
          Text(controller.project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 18),
          _SavedBadge(controller: controller),
          const Spacer(),
          IconButton(onPressed: controller.undo, icon: const Icon(Icons.undo_rounded), tooltip: 'Deshacer'),
          const IconButton(onPressed: null, icon: Icon(Icons.redo_rounded), tooltip: 'Rehacer'),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: controller.isSaving ? null : () => _save(context),
            icon: controller.isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(controller.isSaving ? 'Guardando' : 'Guardar'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: () => _comingSoon(context, 'La exportación mediante FFmpeg se integrará después del núcleo del editor.'), icon: const Icon(Icons.ios_share_rounded), label: const Text('Exportar')),
        ]),
      );

  void _comingSoon(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
      width: 72,
      color: VelyntoraColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: <Widget>[
        for (final item in tools)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: IconButton.filledTonal(
              onPressed: () => controller.selectTool(item.$1),
              icon: Icon(item.$2),
              tooltip: item.$3,
              style: IconButton.styleFrom(
                backgroundColor: controller.tool == item.$1 ? VelyntoraColors.violet.withValues(alpha: 0.28) : Colors.transparent,
                foregroundColor: controller.tool == item.$1 ? VelyntoraColors.cyan : VelyntoraColors.muted,
              ),
            ),
          ),
        const Spacer(),
        IconButton(onPressed: controller.clearFrame, icon: const Icon(Icons.delete_sweep_outlined), tooltip: 'Limpiar fotograma'),
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
        child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('Pincel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: <Widget>[
                Container(width: 42, height: 42, decoration: BoxDecoration(color: controller.color, shape: BoxShape.circle, border: Border.all(color: Colors.white24))),
                const SizedBox(width: 12),
                Expanded(child: Text('Tamaño ${controller.brushSize.round()} px')),
              ]),
              Slider(value: controller.brushSize, min: 1, max: 80, onChanged: controller.setBrushSize),
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
              IconButton(onPressed: controller.addLayer, icon: const Icon(Icons.add_rounded), tooltip: 'Añadir capa'),
            ]),
          ),
          Expanded(
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
                    title: Text(layer.name),
                    trailing: IconButton(onPressed: () => controller.toggleLayerLock(index), icon: Icon(layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(title: const Text('Papel cebolla'), value: controller.onionSkin, onChanged: controller.setOnionSkin),
          SwitchListTile(title: const Text('Cuadrícula'), value: controller.gridEnabled, onChanged: controller.setGridEnabled),
        ]),
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) => Container(
        height: 172,
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
              TextButton.icon(onPressed: () => controller.addFrame(duplicate: true), icon: const Icon(Icons.copy_rounded), label: const Text('Duplicar')),
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
                    width: 116,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? VelyntoraColors.cyan : VelyntoraColors.border, width: selected ? 3 : 1)),
                    child: Stack(children: <Widget>[
                      Center(child: Icon(Icons.draw_outlined, color: Colors.blueGrey.withValues(alpha: 0.3))),
                      Positioned(left: 6, top: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), child: Text('${index + 1}', style: const TextStyle(fontSize: 11)))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
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
          const Text('Zoom 100%', style: TextStyle(fontSize: 11, color: VelyntoraColors.muted)),
        ]),
      );
}
