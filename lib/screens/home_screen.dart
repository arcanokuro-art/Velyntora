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
  _HomeDestination destination = _HomeDestination.projects;
  BrushPreset defaultBrush = BrushPreset.ink;
  int defaultFps = 12;
  String defaultResolution = '1920x1080';

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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Proyectos',
                    active: destination == _HomeDestination.projects,
                    onTap: () => _selectDestination(_HomeDestination.projects),
                  ),
                  _NavItem(
                    icon: Icons.brush_rounded,
                    label: 'Pinceles',
                    active: destination == _HomeDestination.brushes,
                    onTap: () => _selectDestination(_HomeDestination.brushes),
                  ),
                  _NavItem(
                    icon: Icons.folder_copy_rounded,
                    label: 'Recursos',
                    active: destination == _HomeDestination.resources,
                    onTap: () => _selectDestination(_HomeDestination.resources),
                  ),
                  const Spacer(),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Ajustes',
                    active: destination == _HomeDestination.settings,
                    onTap: () => _selectDestination(_HomeDestination.settings),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Velyntora 0.1',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildDestination(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(_HomeDestination next) {
    if (destination == next) return;
    setState(() => destination = next);
  }

  Widget _buildDestination(BuildContext context) => switch (destination) {
    _HomeDestination.projects => _ProjectsHome(
      key: const ValueKey('projects'),
      gallery: _buildProjectGallery(context),
      onCreate: () => _createProject(context),
    ),
    _HomeDestination.brushes => _BrushLibrary(
      key: const ValueKey('brushes'),
      selected: defaultBrush,
      onSelected: (preset) => setState(() => defaultBrush = preset),
    ),
    _HomeDestination.resources => _ResourceLibrary(
      key: const ValueKey('resources'),
      projects: projects,
      onOpenProject: (project) => _openEditor(context, project),
    ),
    _HomeDestination.settings => _SettingsHome(
      key: const ValueKey('settings'),
      fps: defaultFps,
      resolution: defaultResolution,
      onFpsChanged: (value) => setState(() => defaultFps = value),
      onResolutionChanged: (value) => setState(() => defaultResolution = value),
    ),
  };

  Widget _buildProjectGallery(BuildContext context) =>
      FutureBuilder<List<_StoredProject>>(
        future: projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los proyectos: ${snapshot.error}',
              ),
            );
          }
          final items = snapshot.data ?? const <_StoredProject>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.movie_creation_outlined,
                    size: 72,
                    color: VelyntoraColors.violet,
                  ),
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
    setState(() {
      projects = _loadProjects();
    });
  }

  Future<void> _deleteProject(
    BuildContext context,
    _StoredProject entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Eliminar “${entry.project.name}”? Esta acción no se puede deshacer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.delete(entry.file);
    _refreshProjects();
  }

  Future<void> _createProject(BuildContext context) async {
    final nameController = TextEditingController(text: 'Animación sin título');
    var fps = defaultFps;
    var resolution = defaultResolution;
    final project = await showDialog<AnimationProject>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo proyecto'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setDialogState) =>
                          DropdownButtonFormField<String>(
                            initialValue: resolution,
                            decoration: const InputDecoration(
                              labelText: 'Resolución',
                            ),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                value: '1280x720',
                                child: Text('HD · 1280 × 720'),
                              ),
                              DropdownMenuItem(
                                value: '1920x1080',
                                child: Text('Full HD · 1920 × 1080'),
                              ),
                              DropdownMenuItem(
                                value: '1080x1080',
                                child: Text('Cuadrado · 1080 × 1080'),
                              ),
                              DropdownMenuItem(
                                value: '1080x1920',
                                child: Text('Vertical · 1080 × 1920'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => resolution = value);
                              }
                            },
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setDialogState) =>
                          DropdownButtonFormField<int>(
                            initialValue: fps,
                            decoration: const InputDecoration(
                              labelText: 'Velocidad',
                            ),
                            items: const <int>[6, 12, 15, 24, 30, 60]
                                .map(
                                  (value) => DropdownMenuItem<int>(
                                    value: value,
                                    child: Text('$value FPS'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => fps = value);
                              }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final dimensions = resolution
                    .split('x')
                    .map(int.parse)
                    .toList();
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

  Future<void> _openEditor(
    BuildContext context,
    AnimationProject project,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(
          project: project,
          storage: storage,
          initialBrushPreset: defaultBrush,
        ),
      ),
    );
    _refreshProjects();
  }
}

enum _HomeDestination { projects, brushes, resources, settings }

class _ProjectsHome extends StatelessWidget {
  const _ProjectsHome({
    super.key,
    required this.gallery,
    required this.onCreate,
  });
  final Widget gallery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(42, 34, 42, 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _SectionHeading(
                title: 'Tus proyectos',
                subtitle: 'Crea animaciones sin límites ni bloqueos.',
              ),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo proyecto'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Expanded(child: gallery),
      ],
    ),
  );
}

class _BrushLibrary extends StatelessWidget {
  const _BrushLibrary({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final BrushPreset selected;
  final ValueChanged<BrushPreset> onSelected;

  @override
  Widget build(BuildContext context) => _SectionPage(
    heading: const _SectionHeading(
      title: 'Pinceles',
      subtitle: 'Elige el pincel inicial de los proyectos que abras.',
    ),
    child: GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 1050 ? 3 : 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.35,
      children: <Widget>[
        _BrushCard(
          title: 'Lápiz',
          description: 'Trazo fino, ligeramente transparente y directo.',
          icon: Icons.edit_rounded,
          selected: selected == BrushPreset.pencil,
          onTap: () => onSelected(BrushPreset.pencil),
        ),
        _BrushCard(
          title: 'Tinta',
          description: 'Línea firme y estabilizada para entintado limpio.',
          icon: Icons.brush_rounded,
          selected: selected == BrushPreset.ink,
          onTap: () => onSelected(BrushPreset.ink),
        ),
        _BrushCard(
          title: 'Marcador',
          description: 'Pincel ancho y translúcido para color y bocetos.',
          icon: Icons.border_color_rounded,
          selected: selected == BrushPreset.marker,
          onTap: () => onSelected(BrushPreset.marker),
        ),
      ],
    ),
  );
}

class _ResourceLibrary extends StatelessWidget {
  const _ResourceLibrary({
    super.key,
    required this.projects,
    required this.onOpenProject,
  });
  final Future<List<_StoredProject>> projects;
  final ValueChanged<AnimationProject> onOpenProject;

  @override
  Widget build(BuildContext context) => _SectionPage(
    heading: const _SectionHeading(
      title: 'Recursos',
      subtitle: 'Imágenes, audio y video vinculados a tus proyectos.',
    ),
    child: FutureBuilder<List<_StoredProject>>(
      future: projects,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? const <_StoredProject>[];
        final withMedia = entries
            .where((entry) => entry.project.mediaAssets.isNotEmpty)
            .toList();
        if (withMedia.isEmpty) {
          return const _EmptySection(
            icon: Icons.perm_media_outlined,
            title: 'Aún no hay recursos importados',
            message: 'Importa imágenes, audio o video desde el editor y aparecerán aquí.',
          );
        }
        return ListView.separated(
          itemCount: withMedia.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = withMedia[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.folder_copy_rounded, size: 36),
                title: Text(entry.project.name),
                subtitle: Text(
                  '${entry.project.mediaAssets.length} recurso(s) vinculado(s)',
                ),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => onOpenProject(entry.project),
              ),
            );
          },
        );
      },
    ),
  );
}

class _SettingsHome extends StatelessWidget {
  const _SettingsHome({
    super.key,
    required this.fps,
    required this.resolution,
    required this.onFpsChanged,
    required this.onResolutionChanged,
  });
  final int fps;
  final String resolution;
  final ValueChanged<int> onFpsChanged;
  final ValueChanged<String> onResolutionChanged;

  @override
  Widget build(BuildContext context) => _SectionPage(
    heading: const _SectionHeading(
      title: 'Ajustes',
      subtitle: 'Valores iniciales para tus próximos proyectos.',
    ),
    child: ListView(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Nuevo proyecto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: resolution,
                  decoration: const InputDecoration(
                    labelText: 'Resolución predeterminada',
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: '1280x720',
                      child: Text('HD · 1280 × 720'),
                    ),
                    DropdownMenuItem(
                      value: '1920x1080',
                      child: Text('Full HD · 1920 × 1080'),
                    ),
                    DropdownMenuItem(
                      value: '1080x1080',
                      child: Text('Cuadrado · 1080 × 1080'),
                    ),
                    DropdownMenuItem(
                      value: '1080x1920',
                      child: Text('Vertical · 1080 × 1920'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onResolutionChanged(value);
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<int>(
                  initialValue: fps,
                  decoration: const InputDecoration(
                    labelText: 'Velocidad predeterminada',
                  ),
                  items: const <int>[6, 12, 15, 24, 30, 60]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value FPS'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onFpsChanged(value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(18),
            leading: Icon(Icons.devices_rounded),
            title: Text('Interfaz adaptable'),
            subtitle: Text(
              'Los controles se ajustan automáticamente a teléfono, tableta y escritorio.',
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.heading, required this.child});
  final Widget heading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(42, 34, 42, 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        heading,
        const SizedBox(height: 30),
        Expanded(child: child),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: VelyntoraColors.muted)),
    ],
  );
}

class _BrushCard extends StatelessWidget {
  const _BrushCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? VelyntoraColors.cyan : VelyntoraColors.border,
        width: selected ? 2 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 34, color: VelyntoraColors.cyan),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: VelyntoraColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 72, color: VelyntoraColors.violet),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: VelyntoraColors.muted),
        ),
      ],
    ),
  );
}

class _StoredProject {
  const _StoredProject(this.file, this.project);
  final File file;
  final AnimationProject project;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });
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
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF252949), Color(0xFF14172A)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.movie_creation_outlined,
                  size: 58,
                  color: VelyntoraColors.violet,
                ),
              ),
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
                      Text(
                        entry.project.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.project.width} × ${entry.project.height} • ${entry.project.fps} FPS',
                        style: const TextStyle(
                          color: VelyntoraColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Eliminar proyecto',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active
            ? VelyntoraColors.violet.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: active ? VelyntoraColors.cyan : VelyntoraColors.muted,
          ),
          title: Text(label),
          dense: true,
        ),
      ),
    );
  }
}
