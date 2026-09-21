import 'dart:io';

import 'package:flutter/material.dart';

import '../models/animation_models.dart';
import '../services/project_storage.dart';
import '../theme/velyntora_theme.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.storage});

  final ProjectStorage? storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProjectStorage storage;
  late Future<List<_StoredProject>> projects;

  @override
  void initState() {
    super.initState();
    storage = widget.storage ?? ProjectStorage();
    projects = _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Container(
              width: 248,
              color: VelyntoraColors.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/branding/velyntora_icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Velyntora',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const _NavItem(icon: Icons.grid_view_rounded, label: 'Proyectos', active: true),
                  const _NavItem(icon: Icons.brush_rounded, label: 'Pinceles'),
                  const _NavItem(icon: Icons.folder_copy_rounded, label: 'Recursos'),
                  const Spacer(),
                  const _NavItem(icon: Icons.settings_rounded, label: 'Ajustes'),
                  const SizedBox(height: 12),
                  Text('Velyntora 0.1', style: TextStyle(color: Colors.white.withValues(alpha: 0.35))),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(42, 34, 42, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Tus proyectos', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text('Crea animaciones sin límites ni bloqueos.', style: TextStyle(color: VelyntoraColors.muted)),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _createProject(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nuevo proyecto'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Expanded(child: _buildProjectGallery(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGallery(BuildContext context) => FutureBuilder<List<_StoredProject>>(
        future: projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('No se pudieron cargar los proyectos: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const <_StoredProject>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.movie_creation_outlined, size: 72, color: VelyntoraColors.violet),
                  const SizedBox(height: 14),
                  const Text('Todavía no hay proyectos guardados.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _createProject(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear el primero'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              childAspectRatio: 1.15,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _ProjectCard(
              entry: items[index],
              onOpen: () => _openEditor(context, items[index].project),
              onDelete: () => _deleteProject(context, items[index]),
            ),
          );
        },
      );

  Future<List<_StoredProject>> _loadProjects() async {
    final files = await storage.listProjects();
    final projects = <_StoredProject>[];
    for (final file in files) {
      try {
        projects.add(_StoredProject(file, await storage.load(file)));
      } on FormatException {
        continue;
      }
    }
    return projects;
  }

  void _refreshProjects() {
    if (!mounted) return;
    setState(() => projects = _loadProjects());
  }

  Future<void> _deleteProject(BuildContext context, _StoredProject entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Eliminar “${entry.project.name}”? Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.delete(entry.file);
    _refreshProjects();
  }

  Future<void> _createProject(BuildContext context) async {
    final nameController = TextEditingController(text: 'Animación sin título');
    var fps = 12;
    var resolution = '1920x1080';
    final project = await showDialog<AnimationProject>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo proyecto'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setDialogState) => DropdownButtonFormField<String>(
                        value: resolution,
                        decoration: const InputDecoration(labelText: 'Resolución'),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: '1280x720', child: Text('HD · 1280 × 720')),
                          DropdownMenuItem(value: '1920x1080', child: Text('Full HD · 1920 × 1080')),
                          DropdownMenuItem(value: '1080x1080', child: Text('Cuadrado · 1080 × 1080')),
                          DropdownMenuItem(value: '1080x1920', child: Text('Vertical · 1080 × 1920')),
                        ],
                        onChanged: (value) {
                          if (value != null) setDialogState(() => resolution = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setDialogState) => DropdownButtonFormField<int>(
                        value: fps,
                        decoration: const InputDecoration(labelText: 'Velocidad'),
                        items: const <int>[6, 12, 15, 24, 30, 60]
                            .map((value) => DropdownMenuItem<int>(value: value, child: Text('$value FPS')))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => fps = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final dimensions = resolution.split('x').map(int.parse).toList();
                Navigator.pop(
                  context,
                  AnimationProject(
                    name: name,
                    width: dimensions[0],
                    height: dimensions[1],
                    fps: fps,
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (project != null && context.mounted) _openEditor(context, project);
  }

  Future<void> _openEditor(BuildContext context, AnimationProject project) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(project: project)));
    _refreshProjects();
  }
}

class _StoredProject {
  const _StoredProject(this.file, this.project);
  final File file;
  final AnimationProject project;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.entry, required this.onOpen, required this.onDelete});
  final _StoredProject entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: <Color>[Color(0xFF252949), Color(0xFF14172A)]),
                  ),
                  child: Center(child: Icon(Icons.movie_creation_outlined, size: 58, color: VelyntoraColors.violet)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(entry.project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${entry.project.width} × ${entry.project.height} • ${entry.project.fps} FPS', style: const TextStyle(color: VelyntoraColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Eliminar proyecto'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? VelyntoraColors.violet.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? VelyntoraColors.cyan : VelyntoraColors.muted),
        title: Text(label),
        dense: true,
      ),
    );
  }
}
