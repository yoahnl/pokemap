import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    final tilesets = project?.tilesets ?? const <ProjectTilesetEntry>[];
    final selectedTerrainPreset = notifier.getSelectedTerrainPreset();
    final selectedPathPreset = notifier.getSelectedPathPreset();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'SURFACE LIBRARY',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: project == null
                ? const Center(
                    child: Text(
                      'Open a project to manage terrain and surface presets',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LibraryRoot(
                          title: 'Terrains',
                          subtitle: 'Base ground presets only',
                          kind: PresetLibraryKind.terrain,
                          color: const Color(0xFF2B6F53),
                          icon: Icons.landscape_outlined,
                          tilesets: tilesets,
                          selectedPresetId: selectedTerrainPreset?.id,
                        ),
                        const SizedBox(height: 12),
                        _LibraryRoot(
                          title: 'Paths',
                          subtitle:
                              'Surface overlays: roads, water, tall grass, ice, lava, rails...',
                          kind: PresetLibraryKind.path,
                          color: const Color(0xFF7A4A1E),
                          icon: Icons.route_outlined,
                          tilesets: tilesets,
                          selectedPresetId: selectedPathPreset?.id,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LibraryRoot extends ConsumerWidget {
  const _LibraryRoot({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.color,
    required this.icon,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final String title;
  final String subtitle;
  final PresetLibraryKind kind;
  final Color color;
  final IconData icon;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories = notifier.getPresetCategories(kind: kind);
    final uncategorizedPresets = _rootPresets(notifier, kind);
    final selectedPreset = kind == PresetLibraryKind.terrain
        ? notifier.getTerrainPresetById(selectedPresetId)
        : notifier.getPathPresetById(selectedPresetId);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                  ),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                ),
                IconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                    tilesets: tilesets,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (categories.isEmpty && uncategorizedPresets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                kind == PresetLibraryKind.terrain
                    ? 'No terrain preset or folder yet'
                    : 'No path preset or folder yet',
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...categories.map(
                    (category) => _CategoryNode(
                      category: category,
                      kind: kind,
                      depth: 0,
                      color: color,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                    ),
                  ),
                  ...uncategorizedPresets.map(
                    (preset) => _PresetNode(
                      kind: kind,
                      preset: preset,
                      depth: 0,
                      color: color,
                      tilesets: tilesets,
                      selected: _presetId(preset) == selectedPresetId,
                    ),
                  ),
                ],
              ),
            ),
          if (selectedPreset != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _PresetDetailsCard(
                kind: kind,
                preset: selectedPreset,
                color: color,
                tilesets: tilesets,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<dynamic> _rootPresets(EditorNotifier notifier, PresetLibraryKind kind) {
    if (kind == PresetLibraryKind.terrain) {
      return notifier
          .getTerrainPresets()
          .where((preset) => preset.categoryId == null)
          .toList(growable: false);
    }
    return notifier
        .getPathPresets()
        .where((preset) => preset.categoryId == null)
        .toList(growable: false);
  }
}

class _CategoryNode extends ConsumerWidget {
  const _CategoryNode({
    required this.category,
    required this.kind,
    required this.depth,
    required this.color,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectPresetCategory category;
  final PresetLibraryKind kind;
  final int depth;
  final Color color;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final children =
        notifier.getPresetCategories(kind: kind, parentCategoryId: category.id);
    final presets = kind == PresetLibraryKind.terrain
        ? notifier
            .getTerrainPresets()
            .where((preset) => preset.categoryId == category.id)
            .toList(growable: false)
        : notifier
            .getPathPresets()
            .where((preset) => preset.categoryId == category.id)
            .toList(growable: false);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: 12.0 + depth * 16.0, right: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(Icons.folder_outlined, size: 16, color: color),
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
        subtitle: Text(
          '${children.length} folders • ${presets.length} presets',
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (value) async {
            if (value == 'new_folder') {
              await _showCreateCategoryDialog(
                context,
                notifier: notifier,
                kind: kind,
                parentCategoryId: category.id,
              );
              return;
            }
            if (value == 'new_preset') {
              await _showCreatePresetDialog(
                context,
                notifier: notifier,
                kind: kind,
                tilesets: tilesets,
                categoryId: category.id,
              );
              return;
            }
            if (value == 'rename') {
              await _showRenameCategoryDialog(
                context,
                notifier: notifier,
                kind: kind,
                category: category,
              );
              return;
            }
            await _showDeleteCategoryDialog(
              context,
              notifier: notifier,
              kind: kind,
              category: category,
            );
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'new_folder',
              child: Text('New Subfolder'),
            ),
            PopupMenuItem(
              value: 'new_preset',
              child: Text('New Preset'),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Text('Rename Folder'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete Folder'),
            ),
          ],
        ),
        children: [
          ...children.map(
            (child) => _CategoryNode(
              category: child,
              kind: kind,
              depth: depth + 1,
              color: color,
              tilesets: tilesets,
              selectedPresetId: selectedPresetId,
            ),
          ),
          ...presets.map(
            (preset) => _PresetNode(
              kind: kind,
              preset: preset,
              depth: depth + 1,
              color: color,
              tilesets: tilesets,
              selected: _presetId(preset) == selectedPresetId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetNode extends ConsumerWidget {
  const _PresetNode({
    required this.kind,
    required this.preset,
    required this.depth,
    required this.color,
    required this.tilesets,
    required this.selected,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final int depth;
  final Color color;
  final List<ProjectTilesetEntry> tilesets;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);

    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: color.withValues(alpha: 0.16),
      contentPadding: EdgeInsets.only(left: 44.0 + depth * 16.0, right: 4),
      leading: Icon(
        kind == PresetLibraryKind.terrain
            ? Icons.texture_outlined
            : Icons.route_outlined,
        size: 16,
        color: selected ? color : Colors.white60,
      ),
      title: Text(
        preset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        kind == PresetLibraryKind.terrain
            ? _terrainLabel((preset as ProjectTerrainPreset).terrainType)
            : _pathSurfaceLabel((preset as ProjectPathPreset).surfaceKind),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Colors.white54),
      ),
      onTap: () {
        if (kind == PresetLibraryKind.terrain) {
          notifier.selectTerrainPreset(preset.id);
        } else {
          notifier.selectPathPreset(preset.id);
        }
      },
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 16),
        onSelected: (value) async {
          if (value == 'edit') {
            await _showEditPresetDialog(
              context,
              notifier: notifier,
              kind: kind,
              preset: preset,
              tilesets: tilesets,
            );
            return;
          }
          await _showDeletePresetDialog(
            context,
            notifier: notifier,
            kind: kind,
            preset: preset,
          );
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Text('Edit Preset'),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete Preset'),
          ),
        ],
      ),
    );
  }
}

class _PresetDetailsCard extends ConsumerWidget {
  const _PresetDetailsCard({
    required this.kind,
    required this.preset,
    required this.color,
    required this.tilesets,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final Color color;
  final List<ProjectTilesetEntry> tilesets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categoryPath = notifier.resolvePresetCategoryPath(
      kind: kind,
      categoryId: preset.categoryId as String?,
    );
    final tilesetName =
        _resolveTilesetName(tilesets, preset.tilesetId as String);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name as String,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Base type: ${_terrainLabel((preset as ProjectTerrainPreset).terrainType)}'
                : 'Surface family: ${_pathSurfaceLabel((preset as ProjectPathPreset).surfaceKind)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Folder: ${categoryPath ?? 'Root'}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Tileset: ${tilesetName.isEmpty ? 'None' : tilesetName}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Variants: ${(preset as ProjectTerrainPreset).variants.length}'
                : 'Autotile mappings: ${(preset as ProjectPathPreset).variants.length}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCreateCategoryDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  String? parentCategoryId,
}) async {
  final controller = TextEditingController();
  var shouldSave = false;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(parentCategoryId == null ? 'New Folder' : 'New Subfolder'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Folder name',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            shouldSave = true;
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );

  if (!shouldSave) {
    return;
  }
  await notifier.createPresetCategory(
    name: controller.text,
    kind: kind,
    parentCategoryId: parentCategoryId,
  );
}

Future<void> _showRenameCategoryDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required ProjectPresetCategory category,
}) async {
  final controller = TextEditingController(text: category.name);
  var shouldSave = false;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Folder'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Folder name',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            shouldSave = true;
            Navigator.pop(context);
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );

  if (!shouldSave) {
    return;
  }
  await notifier.renamePresetCategory(
    categoryId: category.id,
    kind: kind,
    name: controller.text,
  );
}

Future<void> _showDeleteCategoryDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required ProjectPresetCategory category,
}) async {
  var shouldDelete = false;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Folder'),
      content: Text(
        'Delete "${category.name}" and its subfolders. Presets inside will stay in the library but move back to the root.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            shouldDelete = true;
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (!shouldDelete) {
    return;
  }
  await notifier.deletePresetCategory(categoryId: category.id, kind: kind);
}

Future<void> _showCreatePresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required List<ProjectTilesetEntry> tilesets,
  String? categoryId,
}) async {
  if (kind == PresetLibraryKind.terrain) {
    await _showTerrainPresetDialog(
      context,
      notifier: notifier,
      tilesets: tilesets,
      initialCategoryId: categoryId,
    );
    return;
  }
  await _showPathPresetDialog(
    context,
    notifier: notifier,
    tilesets: tilesets,
    initialCategoryId: categoryId,
  );
}

Future<void> _showEditPresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required dynamic preset,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  if (kind == PresetLibraryKind.terrain) {
    final terrainPreset = preset as ProjectTerrainPreset;
    await _showTerrainPresetDialog(
      context,
      notifier: notifier,
      tilesets: tilesets,
      preset: terrainPreset,
      initialCategoryId: terrainPreset.categoryId,
    );
    return;
  }
  final pathPreset = preset as ProjectPathPreset;
  await _showPathPresetDialog(
    context,
    notifier: notifier,
    tilesets: tilesets,
    preset: pathPreset,
    initialCategoryId: pathPreset.categoryId,
  );
}

Future<void> _showDeletePresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required dynamic preset,
}) async {
  var shouldDelete = false;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Preset'),
      content: Text('Delete "${preset.name}" from the library?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            shouldDelete = true;
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (!shouldDelete) {
    return;
  }
  if (kind == PresetLibraryKind.terrain) {
    await notifier.deleteTerrainPreset(preset.id as String);
  } else {
    await notifier.deletePathPreset(preset.id as String);
  }
}

Future<void> _showTerrainPresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required List<ProjectTilesetEntry> tilesets,
  String? initialCategoryId,
  ProjectTerrainPreset? preset,
}) async {
  final controller = TextEditingController(text: preset?.name ?? '');
  var terrainType = preset?.terrainType ?? TerrainType.grass;
  var categoryId = preset?.categoryId ?? initialCategoryId;
  var tilesetId = preset?.tilesetId ?? '';
  var shouldSave = false;
  final categories = _flattenCategories(
    notifier,
    PresetLibraryKind.terrain,
  );

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title:
            Text(preset == null ? 'New Terrain Preset' : 'Edit Terrain Preset'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Preset name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TerrainType>(
                initialValue: terrainType,
                decoration: const InputDecoration(
                  labelText: 'Base type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: TerrainType.values
                    .where((type) => type.isBackgroundPaintable)
                    .map(
                      (type) => DropdownMenuItem<TerrainType>(
                        value: type,
                        child: Text(_terrainLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      terrainType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Root'),
                  ),
                  ...categories.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.id,
                      child: Text(entry.label),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    categoryId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tilesetId.isEmpty ? '' : tilesetId,
                decoration: const InputDecoration(
                  labelText: 'Tileset',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('None'),
                  ),
                  ...tilesets.map(
                    (tileset) => DropdownMenuItem<String>(
                      value: tileset.id,
                      child: Text(tileset.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    tilesetId = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              shouldSave = true;
              Navigator.pop(context);
            },
            child: Text(preset == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  if (!shouldSave) {
    return;
  }
  if (preset == null) {
    await notifier.createTerrainPreset(
      name: controller.text,
      terrainType: terrainType,
      categoryId: categoryId,
      tilesetId: tilesetId,
    );
    return;
  }
  await notifier.updateTerrainPreset(
    presetId: preset.id,
    name: controller.text,
    terrainType: terrainType,
    categoryId: categoryId,
    clearCategoryId: categoryId == null,
    tilesetId: tilesetId,
    clearTilesetId: tilesetId.isEmpty,
  );
}

Future<void> _showPathPresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required List<ProjectTilesetEntry> tilesets,
  String? initialCategoryId,
  ProjectPathPreset? preset,
}) async {
  final controller = TextEditingController(text: preset?.name ?? '');
  var surfaceKind = preset?.surfaceKind ?? PathSurfaceKind.path;
  var categoryId = preset?.categoryId ?? initialCategoryId;
  var tilesetId = preset?.tilesetId ?? '';
  var shouldSave = false;
  final categories = _flattenCategories(
    notifier,
    PresetLibraryKind.path,
  );

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(preset == null ? 'New Path Preset' : 'Edit Path Preset'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Preset name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PathSurfaceKind>(
                initialValue: surfaceKind,
                decoration: const InputDecoration(
                  labelText: 'Surface family',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: PathSurfaceKind.values
                    .map(
                      (type) => DropdownMenuItem<PathSurfaceKind>(
                        value: type,
                        child: Text(_pathSurfaceLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      surfaceKind = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Root'),
                  ),
                  ...categories.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.id,
                      child: Text(entry.label),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    categoryId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tilesetId.isEmpty ? '' : tilesetId,
                decoration: const InputDecoration(
                  labelText: 'Tileset',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('None'),
                  ),
                  ...tilesets.map(
                    (tileset) => DropdownMenuItem<String>(
                      value: tileset.id,
                      child: Text(tileset.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    tilesetId = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              shouldSave = true;
              Navigator.pop(context);
            },
            child: Text(preset == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  if (!shouldSave) {
    return;
  }
  if (preset == null) {
    await notifier.createPathPreset(
      name: controller.text,
      surfaceKind: surfaceKind,
      categoryId: categoryId,
      tilesetId: tilesetId,
    );
    return;
  }
  await notifier.updatePathPreset(
    presetId: preset.id,
    name: controller.text,
    surfaceKind: surfaceKind,
    categoryId: categoryId,
    clearCategoryId: categoryId == null,
    tilesetId: tilesetId,
    clearTilesetId: tilesetId.isEmpty,
  );
}

List<_CategoryOption> _flattenCategories(
  EditorNotifier notifier,
  PresetLibraryKind kind, {
  String? parentCategoryId,
  int depth = 0,
}) {
  final categories = notifier.getPresetCategories(
    kind: kind,
    parentCategoryId: parentCategoryId,
  );
  final result = <_CategoryOption>[];
  for (final category in categories) {
    result.add(
      _CategoryOption(
        id: category.id,
        label: '${'  ' * depth}${depth == 0 ? '' : '└ '}${category.name}',
      ),
    );
    result.addAll(
      _flattenCategories(
        notifier,
        kind,
        parentCategoryId: category.id,
        depth: depth + 1,
      ),
    );
  }
  return result;
}

String _resolveTilesetName(
    List<ProjectTilesetEntry> tilesets, String tilesetId) {
  final normalized = tilesetId.trim();
  if (normalized.isEmpty) {
    return '';
  }
  for (final tileset in tilesets) {
    if (tileset.id == normalized) {
      return tileset.name;
    }
  }
  return normalized;
}

String _terrainLabel(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.none => 'None',
    TerrainType.grass => 'Grass Base',
    TerrainType.dirt => 'Dirt Base',
    TerrainType.sand => 'Sand Base',
    TerrainType.rock => 'Rock Base',
    TerrainType.stone => 'Stone Base',
    TerrainType.indoor => 'Indoor Base',
  };
}

String _pathSurfaceLabel(PathSurfaceKind kind) {
  return switch (kind) {
    PathSurfaceKind.path => 'Path',
    PathSurfaceKind.road => 'Road',
    PathSurfaceKind.water => 'Water',
    PathSurfaceKind.tallGrass => 'Tall Grass',
    PathSurfaceKind.ice => 'Ice',
    PathSurfaceKind.lava => 'Lava',
    PathSurfaceKind.swamp => 'Swamp',
    PathSurfaceKind.rails => 'Rails',
    PathSurfaceKind.bridge => 'Bridge',
    PathSurfaceKind.special => 'Special',
    PathSurfaceKind.custom => 'Custom',
  };
}

String _presetId(dynamic preset) => preset.id as String;

class _CategoryOption {
  const _CategoryOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
