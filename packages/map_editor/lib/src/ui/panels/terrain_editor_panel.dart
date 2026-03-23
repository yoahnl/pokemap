import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({super.key});

  static const List<TerrainType> _paintableTerrainTypes = <TerrainType>[
    TerrainType.normal,
    TerrainType.water,
    TerrainType.tallGrass,
    TerrainType.sand,
    TerrainType.ice,
  ];

  static const List<TerrainPathVariant> _pathSchemaEditableVariants =
      <TerrainPathVariant>[
    TerrainPathVariant.cornerSE,
    TerrainPathVariant.endSouth,
    TerrainPathVariant.cornerSW,
    TerrainPathVariant.endEast,
    TerrainPathVariant.cross,
    TerrainPathVariant.endWest,
    TerrainPathVariant.cornerNE,
    TerrainPathVariant.endNorth,
    TerrainPathVariant.cornerNW,
    TerrainPathVariant.innerCornerSE,
    TerrainPathVariant.innerCornerSW,
    TerrainPathVariant.innerCornerNE,
    TerrainPathVariant.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    final settings = project?.settings ?? const ProjectSettings();
    final allTilesets = project?.tilesets ?? const <ProjectTilesetEntry>[];

    final terrainPresets = notifier.getTerrainPresets();
    final pathPresets = notifier.getPathPresets();
    final terrainCategories = notifier.getTerrainPresetCategories(
      kind: TerrainPresetCategoryKind.terrain,
    );
    final pathCategories = notifier.getTerrainPresetCategories(
      kind: TerrainPresetCategoryKind.path,
    );
    final selectedTerrainPreset = notifier.getSelectedTerrainPreset();
    final selectedPathPreset = notifier.getSelectedPathPreset();
    final isPathSelection = state.selectedTerrainType == TerrainType.path;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TERRAINS & PATHS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Icon(
                  isPathSelection
                      ? Icons.route_outlined
                      : Icons.terrain_outlined,
                  size: 16,
                  color: isPathSelection
                      ? Colors.brown[300]
                      : Colors.lightBlue[200],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBackgroundSection(
                    context,
                    ref: ref,
                    notifier: notifier,
                    presets: terrainPresets,
                    categories: terrainCategories,
                    selectedPreset: selectedTerrainPreset,
                    settings: settings,
                    tilesets: allTilesets,
                  ),
                  const SizedBox(height: 14),
                  _buildPathSection(
                    context,
                    ref: ref,
                    notifier: notifier,
                    presets: pathPresets,
                    categories: pathCategories,
                    selectedPreset: selectedPathPreset,
                    settings: settings,
                    tilesets: allTilesets,
                  ),
                  if (terrainPresets.isEmpty && pathPresets.isEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Create terrain and path presets to build a reusable biome library.',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required List<ProjectTerrainPreset> presets,
    required List<ProjectTerrainPresetCategory> categories,
    required ProjectTerrainPreset? selectedPreset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Terrains',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Create Terrain Category',
                onPressed: () => _showCreatePresetCategoryDialog(
                  context,
                  notifier: notifier,
                  kind: TerrainPresetCategoryKind.terrain,
                ),
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Create Terrain Preset',
                onPressed: () => _showCreateTerrainPresetDialog(
                  context,
                  ref: ref,
                  notifier: notifier,
                  settings: settings,
                  tilesets: tilesets,
                  categories: categories,
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (presets.isEmpty)
            const Text(
              'No terrain preset yet',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final selected = selectedPreset?.id == preset.id;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor:
                        Colors.blueAccent.withValues(alpha: 0.15),
                    leading: Icon(
                      Icons.texture_outlined,
                      size: 16,
                      color: selected ? Colors.blue[200] : Colors.white60,
                    ),
                    title: Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_terrainLabel(preset.terrainType)} • ${preset.variants.length} members${_categorySuffix(notifier, preset.categoryId)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => notifier.selectTerrainPreset(preset.id),
                  );
                },
              ),
            ),
          if (selectedPreset != null) ...[
            const SizedBox(height: 10),
            _buildTerrainPresetDetails(
              context,
              ref: ref,
              notifier: notifier,
              preset: selectedPreset,
              settings: settings,
              tilesets: tilesets,
              categories: categories,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathSection(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required List<ProjectPathPreset> presets,
    required List<ProjectTerrainPresetCategory> categories,
    required ProjectPathPreset? selectedPreset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.brown.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Path Presets',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Create Path Category',
                onPressed: () => _showCreatePresetCategoryDialog(
                  context,
                  notifier: notifier,
                  kind: TerrainPresetCategoryKind.path,
                ),
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Create Path Preset',
                onPressed: () => _showCreatePathPresetDialog(
                  context,
                  ref: ref,
                  notifier: notifier,
                  settings: settings,
                  tilesets: tilesets,
                  categories: categories,
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (presets.isEmpty)
            const Text(
              'No path preset yet',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final selected = selectedPreset?.id == preset.id;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: Colors.brown.withValues(alpha: 0.18),
                    leading: Icon(
                      Icons.route_outlined,
                      size: 16,
                      color: selected ? Colors.brown[300] : Colors.white60,
                    ),
                    title: Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_terrainLabel(preset.groundTerrainType)} • ${preset.variants.length}/${TerrainPathVariant.values.length} mapped${_categorySuffix(notifier, preset.categoryId)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => notifier.selectPathPreset(preset.id),
                  );
                },
              ),
            ),
          if (selectedPreset != null) ...[
            const SizedBox(height: 10),
            _buildPathPresetDetails(
              context,
              ref: ref,
              notifier: notifier,
              preset: selectedPreset,
              settings: settings,
              tilesets: tilesets,
              categories: categories,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerrainPresetDetails(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectTerrainPreset preset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) {
    final tilesetName = _resolveTilesetName(tilesets, preset.tilesetId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${_terrainLabel(preset.terrainType)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Tileset: ${tilesetName ?? 'None'}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Variants: ${preset.variants.length}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Category: ${_categoryLabel(notifier, preset.categoryId) ?? 'None'}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          if (preset.tilesetId.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTilesetPreview(
              notifier: notifier,
              tilesetId: preset.tilesetId,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditTerrainPresetDialog(
                  context,
                  ref: ref,
                  notifier: notifier,
                  preset: preset,
                  settings: settings,
                  tilesets: tilesets,
                  categories: categories,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: preset.tilesetId.trim().isEmpty
                    ? null
                    : () async {
                        await _runTerrainMemberAssistant(
                          context,
                          notifier: notifier,
                          settings: settings,
                          preset: preset,
                        );
                      },
                icon: const Icon(Icons.add_box_outlined, size: 16),
                label: const Text('Add Members'),
              ),
              OutlinedButton.icon(
                onPressed: () => notifier.deleteTerrainPreset(preset.id),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPathPresetDetails(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectPathPreset preset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) {
    final tilesetName = _resolveTilesetName(tilesets, preset.tilesetId);
    final missingVariants =
        TerrainPathVariant.values.length - preset.variants.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tileset: ${tilesetName ?? 'None'}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Mapped variants: ${preset.variants.length}/${TerrainPathVariant.values.length}${missingVariants > 0 ? ' ($missingVariants missing)' : ''}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Type: ${_terrainLabel(preset.groundTerrainType)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            'Category: ${_categoryLabel(notifier, preset.categoryId) ?? 'None'}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          if (preset.tilesetId.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTilesetPreview(
              notifier: notifier,
              tilesetId: preset.tilesetId,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditPathPresetDialog(
                  context,
                  ref: ref,
                  notifier: notifier,
                  preset: preset,
                  settings: settings,
                  tilesets: tilesets,
                  categories: categories,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Mapping'),
              ),
              OutlinedButton.icon(
                onPressed: preset.tilesetId.trim().isEmpty
                    ? null
                    : () async {
                        await _runPathMappingAssistant(
                          context,
                          notifier: notifier,
                          settings: settings,
                          preset: preset,
                        );
                      },
                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                label: const Text('Map All Variants'),
              ),
              OutlinedButton.icon(
                onPressed: () => notifier.deletePathPreset(preset.id),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePresetCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required TerrainPresetCategoryKind kind,
  }) async {
    final categories = notifier.getTerrainPresetCategories(kind: kind);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    var parentCategoryId = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            kind == TerrainPresetCategoryKind.terrain
                ? 'Create Terrain Category'
                : 'Create Path Category',
          ),
          content: SizedBox(
            width: 340,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categories.any((c) => c.id == parentCategoryId)
                        ? parentCategoryId
                        : '',
                    decoration: const InputDecoration(
                      labelText: 'Parent Category (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      ...categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(
                            _categoryPathForDropdown(categories, category.id),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => parentCategoryId = value ?? ''),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                await notifier.createTerrainPresetCategory(
                  name: nameController.text.trim(),
                  kind: kind,
                  parentCategoryId: parentCategoryId,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTerrainPresetDialog(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    var terrainType = TerrainType.normal;
    var categoryId = '';
    var tilesetId = '';
    final variants = <TerrainPresetVariant>[];
    final availableTilesets = List<ProjectTilesetEntry>.from(
      _terrainTilesetCandidates(
        tilesets: tilesets,
        pathPresets: notifier.getPathPresets(),
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Terrain Preset'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TerrainType>(
                      value: terrainType,
                      decoration:
                          const InputDecoration(labelText: 'Terrain Type'),
                      items: _paintableTerrainTypes
                          .map(
                            (type) => DropdownMenuItem<TerrainType>(
                              value: type,
                              child: Text(_terrainLabel(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) setState(() => terrainType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == categoryId)
                          ? categoryId
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              _categoryPathForDropdown(categories, category.id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        categoryId = value ?? '';
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: availableTilesets.any((t) => t.id == tilesetId)
                          ? tilesetId
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Tileset (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...availableTilesets.map(
                          (tileset) => DropdownMenuItem<String>(
                            value: tileset.id,
                            child: Text(tileset.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        tilesetId = value ?? '';
                        variants.clear();
                      }),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Terrain tilesets cannot be shared with path presets.',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final imported =
                              await _importTilesetFromTerrainEditor(
                            ref: ref,
                            notifier: notifier,
                          );
                          if (imported == null) return;
                          setState(() {
                            final exists = availableTilesets.any(
                              (tileset) => tileset.id == imported.id,
                            );
                            if (!exists) {
                              availableTilesets.add(imported);
                            }
                            tilesetId = imported.id;
                          });
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Import Terrain Tileset'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Visual Variants',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final created = await _showTerrainVariantDialog(
                              context,
                              notifier: notifier,
                              settings: settings,
                              tilesetId: tilesetId,
                            );
                            if (created != null) {
                              setState(() => variants.add(created));
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (variants.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No visual variant. Renderer will fallback to color overlay.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var index = 0; index < variants.length; index++)
                            _VariantTile(
                              label: _terrainVariantLabel(variants[index]),
                              onEdit: () async {
                                final edited = await _showTerrainVariantDialog(
                                  context,
                                  notifier: notifier,
                                  settings: settings,
                                  tilesetId: tilesetId,
                                  initial: variants[index],
                                );
                                if (edited != null) {
                                  setState(() => variants[index] = edited);
                                }
                              },
                              onDelete: () =>
                                  setState(() => variants.removeAt(index)),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                await notifier.createTerrainPreset(
                  name: nameController.text.trim(),
                  terrainType: terrainType,
                  categoryId: categoryId,
                  tilesetId: tilesetId,
                  variants: variants,
                );
                Navigator.pop(context);
                if (tilesetId.trim().isEmpty) return;
                final createdId =
                    ref.read(editorNotifierProvider).selectedTerrainPresetId;
                if (createdId == null) return;
                final created = notifier.getTerrainPresetById(createdId);
                if (created == null) return;
                await _runTerrainMemberAssistant(
                  context,
                  notifier: notifier,
                  settings: settings,
                  preset: created,
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTerrainPresetDialog(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectTerrainPreset preset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: preset.name);
    var terrainType = preset.terrainType;
    var categoryId = preset.categoryId ?? '';
    var tilesetId = preset.tilesetId;
    final variants = List<TerrainPresetVariant>.from(preset.variants);
    final availableTilesets = List<ProjectTilesetEntry>.from(
      _terrainTilesetCandidates(
        tilesets: tilesets,
        pathPresets: notifier.getPathPresets(),
        currentTilesetId: preset.tilesetId,
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Terrain Preset'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TerrainType>(
                      value: terrainType,
                      decoration:
                          const InputDecoration(labelText: 'Terrain Type'),
                      items: _paintableTerrainTypes
                          .map(
                            (type) => DropdownMenuItem<TerrainType>(
                              value: type,
                              child: Text(_terrainLabel(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) setState(() => terrainType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == categoryId)
                          ? categoryId
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              _categoryPathForDropdown(categories, category.id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => categoryId = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: availableTilesets.any((t) => t.id == tilesetId)
                          ? tilesetId
                          : '',
                      decoration: const InputDecoration(
                          labelText: 'Tileset (optional)'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...availableTilesets.map(
                          (tileset) => DropdownMenuItem<String>(
                            value: tileset.id,
                            child: Text(tileset.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => tilesetId = value ?? ''),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Terrain tilesets cannot be shared with path presets.',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final imported =
                              await _importTilesetFromTerrainEditor(
                            ref: ref,
                            notifier: notifier,
                          );
                          if (imported == null) return;
                          setState(() {
                            final exists = availableTilesets.any(
                              (tileset) => tileset.id == imported.id,
                            );
                            if (!exists) {
                              availableTilesets.add(imported);
                            }
                            tilesetId = imported.id;
                          });
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Import Terrain Tileset'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Visual Variants',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final created = await _showTerrainVariantDialog(
                              context,
                              notifier: notifier,
                              settings: settings,
                              tilesetId: tilesetId,
                            );
                            if (created != null) {
                              setState(() => variants.add(created));
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (variants.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No visual variant. Renderer will fallback to color overlay.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var index = 0; index < variants.length; index++)
                            _VariantTile(
                              label: _terrainVariantLabel(variants[index]),
                              onEdit: () async {
                                final edited = await _showTerrainVariantDialog(
                                  context,
                                  notifier: notifier,
                                  settings: settings,
                                  tilesetId: tilesetId,
                                  initial: variants[index],
                                );
                                if (edited != null) {
                                  setState(() => variants[index] = edited);
                                }
                              },
                              onDelete: () =>
                                  setState(() => variants.removeAt(index)),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                notifier.updateTerrainPreset(
                  presetId: preset.id,
                  name: nameController.text.trim(),
                  terrainType: terrainType,
                  categoryId: categoryId,
                  clearCategoryId: categoryId.trim().isEmpty,
                  tilesetId: tilesetId,
                  clearTilesetId: tilesetId.isEmpty,
                  variants: variants,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<TerrainPresetVariant?> _showTerrainVariantDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required String tilesetId,
    TerrainPresetVariant? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final xController =
        TextEditingController(text: (initial?.source.x ?? 0).toString());
    final yController =
        TextEditingController(text: (initial?.source.y ?? 0).toString());
    final widthController =
        TextEditingController(text: (initial?.source.width ?? 1).toString());
    final heightController =
        TextEditingController(text: (initial?.source.height ?? 1).toString());
    final weightController =
        TextEditingController(text: (initial?.weight ?? 1).toString());

    TerrainPresetVariant? result;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Add Variant' : 'Edit Variant'),
        content: SizedBox(
          width: 320,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tilesetId.trim().isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final currentSource = TilesetSourceRect(
                          x: int.tryParse(xController.text.trim()) ?? 0,
                          y: int.tryParse(yController.text.trim()) ?? 0,
                          width: int.tryParse(widthController.text.trim()) ?? 1,
                          height:
                              int.tryParse(heightController.text.trim()) ?? 1,
                        );
                        final picked = await _showTilesetRectPickerDialog(
                          context,
                          notifier: notifier,
                          settings: settings,
                          tilesetId: tilesetId,
                          initial: currentSource,
                        );
                        if (picked == null) return;
                        xController.text = picked.x.toString();
                        yController.text = picked.y.toString();
                        widthController.text = picked.width.toString();
                        heightController.text = picked.height.toString();
                      },
                      icon: const Icon(Icons.grid_view_outlined, size: 16),
                      label: const Text('Pick From Tileset'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: xController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'X'),
                        validator: _positiveOrZeroValidator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: yController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Y'),
                        validator: _positiveOrZeroValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Width'),
                        validator: _positiveValidator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height'),
                        validator: _positiveValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight'),
                  validator: _positiveValidator,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              result = TerrainPresetVariant(
                source: TilesetSourceRect(
                  x: int.parse(xController.text),
                  y: int.parse(yController.text),
                  width: int.parse(widthController.text),
                  height: int.parse(heightController.text),
                ),
                weight: int.parse(weightController.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<TilesetSourceRect?> _showTilesetRectPickerDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required String tilesetId,
    required TilesetSourceRect initial,
    String title = 'Select Variant Area',
    String? subtitle,
  }) async {
    final path = notifier.getTilesetAbsolutePathById(tilesetId);
    if (path == null) return null;
    final image = await _TerrainTilesetImageCache.load(path);
    if (image == null) return null;
    if (settings.tileWidth <= 0 || settings.tileHeight <= 0) return null;
    final columns = image.width ~/ settings.tileWidth;
    final rows = image.height ~/ settings.tileHeight;
    if (columns <= 0 || rows <= 0) return null;

    final clampedStart = GridPos(
      x: initial.x.clamp(0, columns - 1),
      y: initial.y.clamp(0, rows - 1),
    );
    final clampedEnd = GridPos(
      x: (initial.x + initial.width - 1).clamp(0, columns - 1),
      y: (initial.y + initial.height - 1).clamp(0, rows - 1),
    );

    GridPos start = clampedStart;
    GridPos end = clampedEnd;
    TilesetSourceRect result = _rectFromGridPoints(start, end);

    final cellWidth =
        math.max(16.0, settings.tileWidth * settings.displayScale);
    final cellHeight =
        math.max(16.0, settings.tileHeight * settings.displayScale);
    final canvasWidth = columns * cellWidth;
    final canvasHeight = rows * cellHeight;

    final picked = await showDialog<TilesetSourceRect>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 760,
              height: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle ??
                        'Selection ${result.width}x${result.height} at (${result.x}, ${result.y})',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: canvasWidth,
                              height: canvasHeight,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  final pos = _gridFromPickerLocal(
                                    details.localPosition,
                                    cellWidth,
                                    cellHeight,
                                    columns,
                                    rows,
                                  );
                                  setState(() {
                                    start = pos;
                                    end = pos;
                                    result = _rectFromGridPoints(start, end);
                                  });
                                },
                                onPanUpdate: (details) {
                                  final pos = _gridFromPickerLocal(
                                    details.localPosition,
                                    cellWidth,
                                    cellHeight,
                                    columns,
                                    rows,
                                  );
                                  setState(() {
                                    end = pos;
                                    result = _rectFromGridPoints(start, end);
                                  });
                                },
                                onTapUp: (details) {
                                  final pos = _gridFromPickerLocal(
                                    details.localPosition,
                                    cellWidth,
                                    cellHeight,
                                    columns,
                                    rows,
                                  );
                                  setState(() {
                                    start = pos;
                                    end = pos;
                                    result = _rectFromGridPoints(start, end);
                                  });
                                },
                                child: CustomPaint(
                                  painter: _TilesetRectSelectionPainter(
                                    image: image,
                                    columns: columns,
                                    rows: rows,
                                    selection: result,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                onPressed: () => Navigator.pop(context, result),
                child: const Text('Use Selection'),
              ),
            ],
          );
        },
      ),
    );

    return picked;
  }

  GridPos _gridFromPickerLocal(
    Offset localPosition,
    double cellWidth,
    double cellHeight,
    int columns,
    int rows,
  ) {
    final maxX = math.max(0.0, columns * cellWidth - 0.000001);
    final maxY = math.max(0.0, rows * cellHeight - 0.000001);
    final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
    final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
    final x = (dx / cellWidth).floor().clamp(0, columns - 1);
    final y = (dy / cellHeight).floor().clamp(0, rows - 1);
    return GridPos(x: x, y: y);
  }

  TilesetSourceRect _rectFromGridPoints(GridPos start, GridPos end) {
    final left = math.min(start.x, end.x);
    final top = math.min(start.y, end.y);
    final right = math.max(start.x, end.x);
    final bottom = math.max(start.y, end.y);
    return TilesetSourceRect(
      x: left,
      y: top,
      width: right - left + 1,
      height: bottom - top + 1,
    );
  }

  Future<void> _showCreatePathPresetDialog(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    var groundTerrainType = TerrainType.normal;
    var categoryId = '';
    var tilesetId = '';
    final availableTilesets = List<ProjectTilesetEntry>.from(
      _pathTilesetCandidates(
        tilesets: tilesets,
        terrainPresets: notifier.getTerrainPresets(),
      ),
    );
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Path Preset'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TerrainType>(
                  value: groundTerrainType,
                  decoration: const InputDecoration(labelText: 'Path Type'),
                  items: _paintableTerrainTypes
                      .map(
                        (type) => DropdownMenuItem<TerrainType>(
                          value: type,
                          child: Text(_terrainLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => groundTerrainType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categories.any((category) => category.id == categoryId)
                      ? categoryId
                      : '',
                  decoration:
                      const InputDecoration(labelText: 'Category (optional)'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('None'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(
                          _categoryPathForDropdown(categories, category.id),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => categoryId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: availableTilesets.any((t) => t.id == tilesetId)
                      ? tilesetId
                      : '',
                  decoration:
                      const InputDecoration(labelText: 'Tileset (optional)'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('None'),
                    ),
                    ...availableTilesets.map(
                      (tileset) => DropdownMenuItem<String>(
                        value: tileset.id,
                        child: Text(tileset.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => tilesetId = value ?? ''),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Path tilesets cannot be shared with terrain presets.',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final imported = await _importTilesetFromTerrainEditor(
                        ref: ref,
                        notifier: notifier,
                      );
                      if (imported == null) return;
                      setState(() {
                        final exists = availableTilesets.any(
                          (tileset) => tileset.id == imported.id,
                        );
                        if (!exists) {
                          availableTilesets.add(imported);
                        }
                        tilesetId = imported.id;
                      });
                    },
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('Import Path Tileset'),
                  ),
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
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                await notifier.createPathPreset(
                  name: nameController.text.trim(),
                  groundTerrainType: groundTerrainType,
                  categoryId: categoryId,
                  tilesetId: tilesetId,
                );
                Navigator.pop(context);
                if (tilesetId.trim().isEmpty) return;
                final createdId =
                    ref.read(editorNotifierProvider).selectedPathPresetId;
                if (createdId == null) return;
                final created = notifier.getPathPresetById(createdId);
                if (created == null) return;
                final mapped = await _showPathMappingWorkspaceDialog(
                  context,
                  notifier: notifier,
                  settings: settings,
                  tilesetId: created.tilesetId,
                  initialMappings: {
                    for (final mapping in created.variants)
                      mapping.variant: mapping.source,
                  },
                );
                if (mapped == null) return;
                final mappings = mapped.entries
                    .map(
                      (entry) => PathPresetVariantMapping(
                        variant: entry.key,
                        source: entry.value,
                      ),
                    )
                    .toList(growable: false)
                  ..sort((a, b) => a.variant.index.compareTo(b.variant.index));
                await notifier.updatePathPreset(
                  presetId: created.id,
                  variants: mappings,
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPathPresetDialog(
    BuildContext context, {
    required WidgetRef ref,
    required EditorNotifier notifier,
    required ProjectPathPreset preset,
    required ProjectSettings settings,
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPresetCategory> categories,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: preset.name);
    var groundTerrainType = preset.groundTerrainType;
    var categoryId = preset.categoryId ?? '';
    var tilesetId = preset.tilesetId;
    final variants = <TerrainPathVariant, TilesetSourceRect>{
      for (final mapping in preset.variants) mapping.variant: mapping.source,
    };
    final availableTilesets = List<ProjectTilesetEntry>.from(
      _pathTilesetCandidates(
        tilesets: tilesets,
        terrainPresets: notifier.getTerrainPresets(),
        currentTilesetId: preset.tilesetId,
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Path Preset'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TerrainType>(
                      value: groundTerrainType,
                      decoration: const InputDecoration(labelText: 'Path Type'),
                      items: _paintableTerrainTypes
                          .map(
                            (type) => DropdownMenuItem<TerrainType>(
                              value: type,
                              child: Text(_terrainLabel(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => groundTerrainType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categories
                              .any((category) => category.id == categoryId)
                          ? categoryId
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              _categoryPathForDropdown(categories, category.id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => categoryId = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: availableTilesets.any((t) => t.id == tilesetId)
                          ? tilesetId
                          : '',
                      decoration: const InputDecoration(
                          labelText: 'Tileset (optional)'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('None'),
                        ),
                        ...availableTilesets.map(
                          (tileset) => DropdownMenuItem<String>(
                            value: tileset.id,
                            child: Text(tileset.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => tilesetId = value ?? ''),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Path tilesets cannot be shared with terrain presets.',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final imported =
                              await _importTilesetFromTerrainEditor(
                            ref: ref,
                            notifier: notifier,
                          );
                          if (imported == null) return;
                          setState(() {
                            final exists = availableTilesets.any(
                              (tileset) => tileset.id == imported.id,
                            );
                            if (!exists) {
                              availableTilesets.add(imported);
                            }
                            tilesetId = imported.id;
                          });
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Import Path Tileset'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Variant Mapping',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${variants.length}/${TerrainPathVariant.values.length} mapped',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: tilesetId.trim().isEmpty
                            ? null
                            : () async {
                                final mapped =
                                    await _showPathMappingWorkspaceDialog(
                                  context,
                                  notifier: notifier,
                                  settings: settings,
                                  tilesetId: tilesetId,
                                  initialMappings: variants,
                                );
                                if (mapped == null) return;
                                setState(() {
                                  variants
                                    ..clear()
                                    ..addAll(mapped);
                                });
                              },
                        icon: const Icon(Icons.grid_view_outlined, size: 16),
                        label: const Text('Open Visual Mapping Editor'),
                      ),
                    ),
                    if (tilesetId.trim().isEmpty) ...[
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select a path tileset first to map variants.',
                          style: TextStyle(fontSize: 10, color: Colors.white54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                final mappings = variants.entries
                    .map(
                      (entry) => PathPresetVariantMapping(
                        variant: entry.key,
                        source: entry.value,
                      ),
                    )
                    .toList(growable: false)
                  ..sort((a, b) => a.variant.index.compareTo(b.variant.index));
                notifier.updatePathPreset(
                  presetId: preset.id,
                  name: nameController.text.trim(),
                  groundTerrainType: groundTerrainType,
                  categoryId: categoryId,
                  clearCategoryId: categoryId.trim().isEmpty,
                  tilesetId: tilesetId,
                  clearTilesetId: tilesetId.isEmpty,
                  variants: mappings,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<TerrainPathVariant, TilesetSourceRect>?>
      _showPathMappingWorkspaceDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required String tilesetId,
    required Map<TerrainPathVariant, TilesetSourceRect> initialMappings,
    TerrainPathVariant? initialVariant,
  }) async {
    final normalizedTilesetId = tilesetId.trim();
    if (normalizedTilesetId.isEmpty) return null;
    final path = notifier.getTilesetAbsolutePathById(normalizedTilesetId);
    if (path == null || path.isEmpty) return null;
    final image = await _TerrainTilesetImageCache.load(path);
    if (image == null) return null;

    final sourceTileWidth = settings.tileWidth;
    final sourceTileHeight = settings.tileHeight;
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) return null;
    final columns = image.width ~/ sourceTileWidth;
    final rows = image.height ~/ sourceTileHeight;
    if (columns <= 0 || rows <= 0) return null;

    final mappings = <TerrainPathVariant, TilesetSourceRect>{
      for (final entry in initialMappings.entries)
        entry.key: TilesetSourceRect(
          x: entry.value.x,
          y: entry.value.y,
          width: 1,
          height: 1,
        ),
    };
    TerrainPathVariant selectedVariant = initialVariant != null &&
            _pathSchemaEditableVariants.contains(initialVariant)
        ? initialVariant
        : _pathSchemaEditableVariants.firstWhere(
            (variant) => !mappings.containsKey(variant),
            orElse: () => _pathSchemaEditableVariants.first,
          );
    Map<TerrainPathVariant, TilesetSourceRect>? result;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Path Mapping Editor'),
          content: SizedBox(
            width: 980,
            height: 620,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 430,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Etape 1: Completer le schema',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mappings.length}/${TerrainPathVariant.values.length} mapped',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.64),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          'Cliquer un emplacement dans le schema, puis cliquer une case du tileset a droite pour l affecter.',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: _PathSchemaCanvas(
                            mappings: mappings,
                            selectedVariant: selectedVariant,
                            image: image,
                            sourceTileWidth: sourceTileWidth,
                            sourceTileHeight: sourceTileHeight,
                            onSelect: (variant) =>
                                setState(() => selectedVariant = variant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Etape 2: Cliquer dans le tileset pour mapper "${_pathVariantDisplayName(selectedVariant)}"',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.64),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Variante active: ${_pathVariantDisplayName(selectedVariant)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Connexions: ${_pathVariantDirectionsLabel(selectedVariant)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _pathVariantUsageDescription(selectedVariant),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final scale = math.min(
                                  constraints.maxWidth / image.width,
                                  constraints.maxHeight / image.height,
                                );
                                final renderWidth = image.width * scale;
                                final renderHeight = image.height * scale;
                                final cellWidth = renderWidth / columns;
                                final cellHeight = renderHeight / rows;

                                void mapCurrentVariant(Offset localPosition) {
                                  final pos = _gridFromPickerLocal(
                                    localPosition,
                                    cellWidth,
                                    cellHeight,
                                    columns,
                                    rows,
                                  );
                                  setState(() {
                                    mappings[selectedVariant] =
                                        TilesetSourceRect(
                                      x: pos.x,
                                      y: pos.y,
                                      width: 1,
                                      height: 1,
                                    );
                                  });
                                }

                                return SizedBox(
                                  width: renderWidth,
                                  height: renderHeight,
                                  child: GestureDetector(
                                    onTapDown: (details) => mapCurrentVariant(
                                        details.localPosition),
                                    onPanUpdate: (details) => mapCurrentVariant(
                                        details.localPosition),
                                    child: CustomPaint(
                                      painter: _PathTilesetMappingPainter(
                                        image: image,
                                        columns: columns,
                                        rows: rows,
                                        mappings: mappings,
                                        selectedVariant: selectedVariant,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: mappings.containsKey(selectedVariant)
                  ? () => setState(() => mappings.remove(selectedVariant))
                  : null,
              child: const Text('Effacer la variante'),
            ),
            ElevatedButton(
              onPressed: () {
                result = _completePathMappings(
                  <TerrainPathVariant, TilesetSourceRect>{
                    for (final entry in mappings.entries)
                      entry.key: TilesetSourceRect(
                        x: entry.value.x,
                        y: entry.value.y,
                        width: 1,
                        height: 1,
                      ),
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  Map<TerrainPathVariant, TilesetSourceRect> _completePathMappings(
    Map<TerrainPathVariant, TilesetSourceRect> mappings,
  ) {
    final completed = <TerrainPathVariant, TilesetSourceRect>{
      ...mappings,
    };

    TilesetSourceRect? pick(List<TerrainPathVariant> order) {
      for (final variant in order) {
        final source = completed[variant];
        if (source != null) return source;
      }
      return null;
    }

    void ensure(
      TerrainPathVariant target,
      List<TerrainPathVariant> fallbackOrder,
    ) {
      if (completed.containsKey(target)) return;
      final source = pick(fallbackOrder);
      if (source == null) return;
      completed[target] = source;
    }

    ensure(
      TerrainPathVariant.horizontal,
      const [
        TerrainPathVariant.cross,
        TerrainPathVariant.horizontal,
        TerrainPathVariant.endWest,
        TerrainPathVariant.endEast,
      ],
    );
    ensure(
      TerrainPathVariant.vertical,
      const [
        TerrainPathVariant.cross,
        TerrainPathVariant.vertical,
        TerrainPathVariant.endNorth,
        TerrainPathVariant.endSouth,
      ],
    );
    ensure(
      TerrainPathVariant.teeNorth,
      const [
        TerrainPathVariant.teeNorth,
        TerrainPathVariant.endNorth,
        TerrainPathVariant.endWest,
        TerrainPathVariant.endEast,
        TerrainPathVariant.cross,
      ],
    );
    ensure(
      TerrainPathVariant.teeEast,
      const [
        TerrainPathVariant.teeEast,
        TerrainPathVariant.endEast,
        TerrainPathVariant.endNorth,
        TerrainPathVariant.endSouth,
        TerrainPathVariant.cross,
      ],
    );
    ensure(
      TerrainPathVariant.teeSouth,
      const [
        TerrainPathVariant.teeSouth,
        TerrainPathVariant.endSouth,
        TerrainPathVariant.endWest,
        TerrainPathVariant.endEast,
        TerrainPathVariant.cross,
      ],
    );
    ensure(
      TerrainPathVariant.teeWest,
      const [
        TerrainPathVariant.teeWest,
        TerrainPathVariant.endWest,
        TerrainPathVariant.endNorth,
        TerrainPathVariant.endSouth,
        TerrainPathVariant.cross,
      ],
    );
    ensure(
      TerrainPathVariant.isolated,
      const [
        TerrainPathVariant.cross,
        TerrainPathVariant.isolated,
        TerrainPathVariant.endNorth,
        TerrainPathVariant.endEast,
        TerrainPathVariant.endSouth,
        TerrainPathVariant.endWest,
      ],
    );

    return completed;
  }

  Future<ProjectTilesetEntry?> _importTilesetFromTerrainEditor({
    required WidgetRef ref,
    required EditorNotifier notifier,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp'],
      withData: false,
    );
    final sourcePath = picked != null && picked.files.isNotEmpty
        ? picked.files.first.path
        : null;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }
    final name = _defaultImportedTilesetName(sourcePath);
    await notifier.importProjectTileset(
      sourcePath: sourcePath,
      name: name,
      scope: TilesetScope.global,
    );
    final updated = ref.read(editorNotifierProvider).project;
    if (updated == null || updated.tilesets.isEmpty) return null;
    final importedId = ref.read(editorNotifierProvider).selectedTilesetEditorId;
    if (importedId != null) {
      for (final tileset in updated.tilesets) {
        if (tileset.id == importedId) {
          return tileset;
        }
      }
    }
    return updated.tilesets.last;
  }

  String _defaultImportedTilesetName(String sourcePath) {
    final fileName = sourcePath.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    final rawName = dot > 0 ? fileName.substring(0, dot) : fileName;
    final normalized = rawName.trim();
    if (normalized.isEmpty) {
      return 'imported_tileset';
    }
    return normalized;
  }

  Future<void> _runTerrainMemberAssistant(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required ProjectTerrainPreset preset,
  }) async {
    final tilesetId = preset.tilesetId.trim();
    if (tilesetId.isEmpty) return;
    var variants = List<TerrainPresetVariant>.from(preset.variants);
    while (true) {
      final picked = await _showTilesetRectPickerDialog(
        context,
        notifier: notifier,
        settings: settings,
        tilesetId: tilesetId,
        initial: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        title: 'Add Terrain Member',
      );
      if (picked == null) break;
      variants.add(TerrainPresetVariant(source: picked, weight: 1));
      await notifier.updateTerrainPreset(
        presetId: preset.id,
        variants: variants,
      );
      final addMore = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Another Member?'),
              content: const Text(
                'Continue selecting cells for this terrain preset?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ??
          false;
      if (!addMore) break;
    }
  }

  Future<void> _runPathMappingAssistant(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectSettings settings,
    required ProjectPathPreset preset,
  }) async {
    final tilesetId = preset.tilesetId.trim();
    if (tilesetId.isEmpty) return;
    final mapped = await _showPathMappingWorkspaceDialog(
      context,
      notifier: notifier,
      settings: settings,
      tilesetId: tilesetId,
      initialMappings: {
        for (final mapping in preset.variants) mapping.variant: mapping.source,
      },
    );
    if (mapped == null) return;
    final next = mapped.entries
        .map(
          (entry) => PathPresetVariantMapping(
            variant: entry.key,
            source: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.variant.index.compareTo(b.variant.index));
    await notifier.updatePathPreset(
      presetId: preset.id,
      variants: next,
    );
  }

  Widget _buildTilesetPreview({
    required EditorNotifier notifier,
    required String tilesetId,
  }) {
    final path = notifier.getTilesetAbsolutePathById(tilesetId);
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<ui.Image?>(
      future: _TerrainTilesetImageCache.load(path),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Tileset preview unavailable',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          );
        }
        return Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RawImage(
              image: image,
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
            ),
          ),
        );
      },
    );
  }

  List<ProjectTilesetEntry> _terrainTilesetCandidates({
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectPathPreset> pathPresets,
    String? currentTilesetId,
  }) {
    final normalizedCurrent = currentTilesetId?.trim() ?? '';
    final blockedTilesetIds = pathPresets
        .map((preset) => preset.tilesetId.trim())
        .where((id) => id.isNotEmpty && id != normalizedCurrent)
        .toSet();
    return tilesets
        .where((tileset) => !blockedTilesetIds.contains(tileset.id))
        .toList(growable: false);
  }

  List<ProjectTilesetEntry> _pathTilesetCandidates({
    required List<ProjectTilesetEntry> tilesets,
    required List<ProjectTerrainPreset> terrainPresets,
    String? currentTilesetId,
  }) {
    final normalizedCurrent = currentTilesetId?.trim() ?? '';
    final blockedTilesetIds = terrainPresets
        .map((preset) => preset.tilesetId.trim())
        .where((id) => id.isNotEmpty && id != normalizedCurrent)
        .toSet();
    return tilesets
        .where((tileset) => !blockedTilesetIds.contains(tileset.id))
        .toList(growable: false);
  }

  String? _positiveValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return '> 0';
    return null;
  }

  String? _positiveOrZeroValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return '>= 0';
    return null;
  }

  String _terrainLabel(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => 'None',
      TerrainType.normal => 'Normal Ground',
      TerrainType.path => 'Path',
      TerrainType.water => 'Water',
      TerrainType.tallGrass => 'Tall Grass',
      TerrainType.sand => 'Sand',
      TerrainType.ice => 'Ice',
    };
  }

  String _terrainVariantLabel(TerrainPresetVariant variant) {
    return '(${variant.source.x}, ${variant.source.y}) ${variant.source.width}x${variant.source.height} • w${variant.weight}';
  }

  String _pathVariantDisplayName(TerrainPathVariant variant) {
    return switch (variant) {
      TerrainPathVariant.isolated => 'Isole',
      TerrainPathVariant.endNorth => 'Extremite Nord',
      TerrainPathVariant.endEast => 'Extremite Est',
      TerrainPathVariant.endSouth => 'Extremite Sud',
      TerrainPathVariant.endWest => 'Extremite Ouest',
      TerrainPathVariant.horizontal => 'Ligne Horizontale',
      TerrainPathVariant.vertical => 'Ligne Verticale',
      TerrainPathVariant.cornerNE => 'Coin Nord-Est',
      TerrainPathVariant.cornerSE => 'Coin Sud-Est',
      TerrainPathVariant.cornerSW => 'Coin Sud-Ouest',
      TerrainPathVariant.cornerNW => 'Coin Nord-Ouest',
      TerrainPathVariant.innerCornerNE => 'Coin Interne Nord-Est',
      TerrainPathVariant.innerCornerSE => 'Coin Interne Sud-Est',
      TerrainPathVariant.innerCornerSW => 'Coin Interne Sud-Ouest',
      TerrainPathVariant.innerCornerNW => 'Coin Interne Nord-Ouest',
      TerrainPathVariant.teeNorth => 'Jonction T Nord',
      TerrainPathVariant.teeEast => 'Jonction T Est',
      TerrainPathVariant.teeSouth => 'Jonction T Sud',
      TerrainPathVariant.teeWest => 'Jonction T Ouest',
      TerrainPathVariant.cross => 'Croisement',
    };
  }

  String _pathVariantDirectionsLabel(TerrainPathVariant variant) {
    final c = _pathVariantConnections(variant);
    final directions = <String>[];
    if (c.north) directions.add('Nord');
    if (c.east) directions.add('Est');
    if (c.south) directions.add('Sud');
    if (c.west) directions.add('Ouest');
    if (directions.isEmpty) return 'Aucune connexion';
    return directions.join(' + ');
  }

  String _pathVariantUsageDescription(TerrainPathVariant variant) {
    if (_isInnerCornerVariant(variant)) {
      final corner = switch (variant) {
        TerrainPathVariant.innerCornerNE => 'Nord-Est',
        TerrainPathVariant.innerCornerSE => 'Sud-Est',
        TerrainPathVariant.innerCornerSW => 'Sud-Ouest',
        TerrainPathVariant.innerCornerNW => 'Nord-Ouest',
        _ => '',
      };
      return 'Coin interne: utilise quand les 4 directions sont connectees, avec un vide diagonal cote $corner.';
    }
    final c = _pathVariantConnections(variant);
    if (!c.north && !c.east && !c.south && !c.west) {
      return 'Utilise quand la case chemin n a aucun voisin chemin.';
    }
    final directions = <String>[];
    if (c.north) directions.add('Nord');
    if (c.east) directions.add('Est');
    if (c.south) directions.add('Sud');
    if (c.west) directions.add('Ouest');
    return 'Utilise quand la case chemin est connectee a: ${directions.join(', ')}.';
  }

  bool _isInnerCornerVariant(TerrainPathVariant variant) {
    return variant == TerrainPathVariant.innerCornerNE ||
        variant == TerrainPathVariant.innerCornerSE ||
        variant == TerrainPathVariant.innerCornerSW ||
        variant == TerrainPathVariant.innerCornerNW;
  }

  String _categorySuffix(EditorNotifier notifier, String? categoryId) {
    final label = _categoryLabel(notifier, categoryId);
    if (label == null || label.isEmpty) return '';
    return ' - $label';
  }

  String? _categoryLabel(EditorNotifier notifier, String? categoryId) {
    final path = notifier.resolveTerrainPresetCategoryPath(categoryId);
    if (path == null || path.isEmpty) return null;
    return path;
  }

  String _categoryPathForDropdown(
    List<ProjectTerrainPresetCategory> categories,
    String categoryId,
  ) {
    final byId = <String, ProjectTerrainPresetCategory>{
      for (final category in categories) category.id: category,
    };
    final current = byId[categoryId];
    if (current == null) return categoryId;
    final segments = <String>[current.name];
    var cursor = current.parentCategoryId;
    final visited = <String>{current.id};
    while (cursor != null && visited.add(cursor)) {
      final parent = byId[cursor];
      if (parent == null) break;
      segments.insert(0, parent.name);
      cursor = parent.parentCategoryId;
    }
    return segments.join(' / ');
  }

  String? _resolveTilesetName(
    List<ProjectTilesetEntry> tilesets,
    String tilesetId,
  ) {
    final normalized = tilesetId.trim();
    if (normalized.isEmpty) return null;
    for (final tileset in tilesets) {
      if (tileset.id == normalized) return tileset.name;
    }
    return normalized;
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.label,
    required this.onEdit,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 15),
            onPressed: onEdit,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 15),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PathSchemaCanvas extends StatelessWidget {
  const _PathSchemaCanvas({
    required this.mappings,
    required this.selectedVariant,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onSelect,
  });

  final Map<TerrainPathVariant, TilesetSourceRect> mappings;
  final TerrainPathVariant selectedVariant;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final ValueChanged<TerrainPathVariant> onSelect;

  static const List<TerrainPathVariant> _mainSquareVariants =
      <TerrainPathVariant>[
    TerrainPathVariant.cornerSE,
    TerrainPathVariant.endSouth,
    TerrainPathVariant.cornerSW,
    TerrainPathVariant.endEast,
    TerrainPathVariant.cross,
    TerrainPathVariant.endWest,
    TerrainPathVariant.cornerNE,
    TerrainPathVariant.endNorth,
    TerrainPathVariant.cornerNW,
  ];

  static const List<TerrainPathVariant> _innerCornerVariants =
      <TerrainPathVariant>[
    TerrainPathVariant.innerCornerSE,
    TerrainPathVariant.innerCornerSW,
    TerrainPathVariant.innerCornerNE,
    TerrainPathVariant.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final cellByWidth = (maxWidth - gap) / 5;
        final cellByHeight = maxHeight / 3;
        final cell = math.max(30.0, math.min(cellByWidth, cellByHeight));
        final bigSize = cell * 3;
        final smallSize = cell * 2;
        final totalWidth = bigSize + gap + smallSize;
        final offsetX = math.max(0.0, (maxWidth - totalWidth) / 2);
        final offsetY = math.max(0.0, (maxHeight - bigSize) / 2);

        return Stack(
          children: [
            Positioned(
              left: offsetX,
              top: offsetY,
              width: bigSize,
              height: bigSize,
              child: _PathSchemaGridSection(
                columns: 3,
                variants: _mainSquareVariants,
                mappings: mappings,
                selectedVariant: selectedVariant,
                image: image,
                sourceTileWidth: sourceTileWidth,
                sourceTileHeight: sourceTileHeight,
                onSelect: onSelect,
              ),
            ),
            Positioned(
              left: offsetX + bigSize + gap,
              top: offsetY + (bigSize - smallSize) / 2,
              width: smallSize,
              height: smallSize,
              child: _PathSchemaGridSection(
                columns: 2,
                variants: _innerCornerVariants,
                mappings: mappings,
                selectedVariant: selectedVariant,
                image: image,
                sourceTileWidth: sourceTileWidth,
                sourceTileHeight: sourceTileHeight,
                onSelect: onSelect,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PathSchemaGridSection extends StatelessWidget {
  const _PathSchemaGridSection({
    required this.columns,
    required this.variants,
    required this.mappings,
    required this.selectedVariant,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onSelect,
  });

  final int columns;
  final List<TerrainPathVariant> variants;
  final Map<TerrainPathVariant, TilesetSourceRect> mappings;
  final TerrainPathVariant selectedVariant;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final ValueChanged<TerrainPathVariant> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        final isSelected = variant == selectedVariant;
        final mappedSource = mappings[variant];
        return _PathSchemaGridSlot(
          variant: variant,
          selected: isSelected,
          mappedSource: mappedSource,
          image: image,
          sourceTileWidth: sourceTileWidth,
          sourceTileHeight: sourceTileHeight,
          onTap: () => onSelect(variant),
        );
      },
    );
  }
}

class _PathSchemaGridSlot extends StatelessWidget {
  const _PathSchemaGridSlot({
    required this.variant,
    required this.selected,
    required this.mappedSource,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onTap,
  });

  final TerrainPathVariant variant;
  final bool selected;
  final TilesetSourceRect? mappedSource;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMapping = mappedSource != null;
    return InkWell(
      borderRadius: BorderRadius.circular(0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? Colors.lightBlueAccent.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.14),
          border: Border.all(
            color: selected ? Colors.lightBlueAccent : Colors.white12,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PathSlotPreviewPainter(
                  image: image,
                  sourceTileWidth: sourceTileWidth,
                  sourceTileHeight: sourceTileHeight,
                  source: mappedSource,
                  selected: selected,
                ),
              ),
            ),
            if (!hasMapping)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CustomPaint(
                    painter: _PathVariantGlyphPainter(
                      variant: variant,
                      selected: selected,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PathSlotPreviewPainter extends CustomPainter {
  const _PathSlotPreviewPainter({
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.source,
    required this.selected,
  });

  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final TilesetSourceRect? source;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderColor = selected ? Colors.lightBlueAccent : Colors.white24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1.2,
    );
    if (source == null) {
      final linePaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(rect.left + 8, rect.top + 8),
        Offset(rect.right - 8, rect.bottom - 8),
        linePaint,
      );
      canvas.drawLine(
        Offset(rect.right - 8, rect.top + 8),
        Offset(rect.left + 8, rect.bottom - 8),
        linePaint,
      );
      return;
    }

    final srcRect = Rect.fromLTWH(
      source!.x * sourceTileWidth.toDouble(),
      source!.y * sourceTileHeight.toDouble(),
      source!.width * sourceTileWidth.toDouble(),
      source!.height * sourceTileHeight.toDouble(),
    );
    final dstRect = rect.deflate(3);
    canvas.clipRRect(
      RRect.fromRectAndRadius(dstRect, const Radius.circular(6)),
    );
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PathSlotPreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        oldDelegate.source != source ||
        oldDelegate.selected != selected;
  }
}

class _PathVariantGlyphPainter extends CustomPainter {
  const _PathVariantGlyphPainter({
    required this.variant,
    required this.selected,
  });

  final TerrainPathVariant variant;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final iconRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(iconRect, const Radius.circular(8)),
      Paint()
        ..color = selected
            ? Colors.lightBlueAccent.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) * 0.33;
    final activeColor = selected ? Colors.lightBlueAccent : Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.22);
    final activeLinePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    final inactiveDotPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final connections = _pathVariantConnections(variant);
    final north = Offset(center.dx, center.dy - half);
    final east = Offset(center.dx + half, center.dy);
    final south = Offset(center.dx, center.dy + half);
    final west = Offset(center.dx - half, center.dy);

    canvas.drawLine(center, north, axisPaint);
    canvas.drawLine(center, east, axisPaint);
    canvas.drawLine(center, south, axisPaint);
    canvas.drawLine(center, west, axisPaint);

    if (connections.north) {
      canvas.drawLine(center, north, activeLinePaint);
    }
    if (connections.east) {
      canvas.drawLine(center, east, activeLinePaint);
    }
    if (connections.south) {
      canvas.drawLine(center, south, activeLinePaint);
    }
    if (connections.west) {
      canvas.drawLine(center, west, activeLinePaint);
    }

    canvas.drawCircle(
        north, 2.0, connections.north ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        east, 2.0, connections.east ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        south, 2.0, connections.south ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        west, 2.0, connections.west ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(center, 2.8, dotPaint);

    final notchAlignment = _innerCornerAlignment(variant);
    if (notchAlignment != null) {
      final notchCenter = Offset(
        center.dx + notchAlignment.dx * half * 0.72,
        center.dy + notchAlignment.dy * half * 0.72,
      );
      canvas.drawCircle(
        notchCenter,
        4.1,
        Paint()
          ..color = Colors.black.withValues(alpha: selected ? 0.72 : 0.58)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        notchCenter,
        3.2,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    _paintCompassLabel(
      canvas,
      'N',
      Offset(center.dx, 4),
      connections.north ? activeColor : Colors.white54,
    );
    _paintCompassLabel(
      canvas,
      'E',
      Offset(size.width - 5, center.dy),
      connections.east ? activeColor : Colors.white54,
    );
    _paintCompassLabel(
      canvas,
      'S',
      Offset(center.dx, size.height - 4),
      connections.south ? activeColor : Colors.white54,
    );
    _paintCompassLabel(
      canvas,
      'O',
      Offset(5, center.dy),
      connections.west ? activeColor : Colors.white54,
    );
  }

  @override
  bool shouldRepaint(covariant _PathVariantGlyphPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.selected != selected;
  }
}

Offset? _innerCornerAlignment(TerrainPathVariant variant) {
  return switch (variant) {
    TerrainPathVariant.innerCornerNE => const Offset(1, -1),
    TerrainPathVariant.innerCornerSE => const Offset(1, 1),
    TerrainPathVariant.innerCornerSW => const Offset(-1, 1),
    TerrainPathVariant.innerCornerNW => const Offset(-1, -1),
    _ => null,
  };
}

void _paintCompassLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}

class _PathTilesetMappingPainter extends CustomPainter {
  const _PathTilesetMappingPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.mappings,
    required this.selectedVariant,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final Map<TerrainPathVariant, TilesetSourceRect> mappings;
  final TerrainPathVariant selectedVariant;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint());
    if (columns <= 0 || rows <= 0) return;

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (final entry in mappings.entries) {
      final source = entry.value;
      final rect = Rect.fromLTWH(
        source.x * cellWidth,
        source.y * cellHeight,
        source.width * cellWidth,
        source.height * cellHeight,
      );
      final selected = entry.key == selectedVariant;
      canvas.drawRect(
        rect,
        Paint()
          ..color = (selected ? Colors.amberAccent : Colors.lightBlueAccent)
              .withValues(alpha: selected ? 0.34 : 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = selected ? Colors.amberAccent : Colors.lightBlueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.2 : 1.4,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var x = 0; x <= columns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathTilesetMappingPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        !_samePathMappings(oldDelegate.mappings, mappings) ||
        oldDelegate.selectedVariant != selectedVariant;
  }
}

({bool north, bool east, bool south, bool west}) _pathVariantConnections(
  TerrainPathVariant variant,
) {
  return switch (variant) {
    TerrainPathVariant.isolated => (
        north: false,
        east: false,
        south: false,
        west: false
      ),
    TerrainPathVariant.endNorth => (
        north: true,
        east: false,
        south: false,
        west: false
      ),
    TerrainPathVariant.endEast => (
        north: false,
        east: true,
        south: false,
        west: false
      ),
    TerrainPathVariant.endSouth => (
        north: false,
        east: false,
        south: true,
        west: false
      ),
    TerrainPathVariant.endWest => (
        north: false,
        east: false,
        south: false,
        west: true
      ),
    TerrainPathVariant.horizontal => (
        north: false,
        east: true,
        south: false,
        west: true
      ),
    TerrainPathVariant.vertical => (
        north: true,
        east: false,
        south: true,
        west: false
      ),
    TerrainPathVariant.cornerNE => (
        north: true,
        east: true,
        south: false,
        west: false
      ),
    TerrainPathVariant.cornerSE => (
        north: false,
        east: true,
        south: true,
        west: false
      ),
    TerrainPathVariant.cornerSW => (
        north: false,
        east: false,
        south: true,
        west: true
      ),
    TerrainPathVariant.cornerNW => (
        north: true,
        east: false,
        south: false,
        west: true
      ),
    TerrainPathVariant.innerCornerNE => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerSE => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerSW => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerNW => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.teeNorth => (
        north: true,
        east: true,
        south: false,
        west: true
      ),
    TerrainPathVariant.teeEast => (
        north: true,
        east: true,
        south: true,
        west: false
      ),
    TerrainPathVariant.teeSouth => (
        north: false,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.teeWest => (
        north: true,
        east: false,
        south: true,
        west: true
      ),
    TerrainPathVariant.cross => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
  };
}

bool _samePathMappings(
  Map<TerrainPathVariant, TilesetSourceRect> left,
  Map<TerrainPathVariant, TilesetSourceRect> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    final source = right[entry.key];
    if (source == null || source != entry.value) {
      return false;
    }
  }
  return true;
}

class _TilesetRectSelectionPainter extends CustomPainter {
  const _TilesetRectSelectionPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.selection,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final TilesetSourceRect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint());

    if (columns <= 0 || rows <= 0) return;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var x = 0; x <= columns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final left = selection.x * cellWidth;
    final top = selection.y * cellHeight;
    final width = selection.width * cellWidth;
    final height = selection.height * cellHeight;
    final rect = Rect.fromLTWH(left, top, width, height);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.24),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TilesetRectSelectionPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.selection != selection;
  }
}

class _TerrainTilesetImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String? path) {
    if (path == null || path.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(path, () async {
      try {
        final file = File(path);
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return null;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }
}
