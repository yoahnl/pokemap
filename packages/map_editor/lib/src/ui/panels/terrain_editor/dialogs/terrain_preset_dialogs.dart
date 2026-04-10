part of 'package:map_editor/src/ui/panels/terrain_editor_panel.dart';

// Dialog and preset-library helpers stay in a dedicated part file so the
// panel shell can remain focused on composition. They still belong to the
// same library because they reuse many private helpers and models.

Future<void> _showCreateCategoryDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  String? parentCategoryId,
}) async {
  final controller = TextEditingController();
  var shouldSave = false;

  await showMacosEditorModalSheet<void>(
    context: context,
    maxWidth: 400,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parentCategoryId == null ? 'New Folder' : 'New Subfolder',
          style: editorMacosSheetTitleStyle(ctx),
        ),
        const SizedBox(height: 12),
        MacosTextField(
          controller: controller,
          autofocus: true,
          placeholder: 'Folder name',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            PushButton(
              controlSize: ControlSize.large,
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                shouldSave = true;
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
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
  final ok = await showMacosEditorPromptSheet(
    context,
    title: 'Rename Folder',
    controller: controller,
    placeholder: 'Folder name',
    confirmLabel: 'Rename',
  );

  if (!ok) {
    return;
  }
  await notifier.renamePresetCategory(
    categoryId: category.id,
    kind: kind,
    name: controller.text.trim(),
  );
}

Future<void> _showDeleteCategoryDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required ProjectPresetCategory category,
}) async {
  final shouldDelete = await showMacosEditorTwoChoiceAlert(
    context,
    title: 'Delete Folder',
    message:
        'Delete "${category.name}" and its subfolders. Presets inside will stay in the library but move back to the root.',
    primaryLabel: 'Delete',
    primaryIsDestructive: true,
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
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
  String? categoryId,
}) async {
  if (kind == PresetLibraryKind.terrain) {
    await _showTerrainPresetDialog(
      context,
      notifier: notifier,
      settings: settings,
      tilesets: tilesets,
      initialCategoryId: categoryId,
    );
    return;
  }
  await _showPathPresetDialog(
    context,
    notifier: notifier,
    settings: settings,
    tilesets: tilesets,
    initialCategoryId: categoryId,
  );
}

Future<void> _showEditPresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required PresetLibraryKind kind,
  required ProjectSettings settings,
  required dynamic preset,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  if (kind == PresetLibraryKind.terrain) {
    final terrainPreset = preset as ProjectTerrainPreset;
    await _showTerrainPresetDialog(
      context,
      notifier: notifier,
      settings: settings,
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
    settings: settings,
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
  final shouldDelete = await showMacosEditorTwoChoiceAlert(
    context,
    title: 'Delete Preset',
    message: 'Delete "${preset.name}" from the library?',
    primaryLabel: 'Delete',
    primaryIsDestructive: true,
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
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
  String? initialCategoryId,
  ProjectTerrainPreset? preset,
}) async {
  final controller = TextEditingController(text: preset?.name ?? '');
  var terrainType = preset?.terrainType ?? TerrainType.grass;
  var categoryId = preset?.categoryId ?? initialCategoryId;
  var tilesetId = preset?.tilesetId ?? '';
  final variants =
      List<TerrainPresetVariant>.from(preset?.variants ?? const []);
  final categories = _flattenCategories(
    notifier,
    PresetLibraryKind.terrain,
  );
  final availableTilesets = List<ProjectTilesetEntry>.from(
    _terrainTilesetCandidates(
      tilesets: tilesets,
      pathPresets: notifier.getPathPresets(),
      currentTilesetId: preset?.tilesetId,
    ),
  );
  final paintableTerrainTypes = TerrainType.values
      .where((type) => type.isBackgroundPaintable)
      .toList(growable: false);
  String folderRowPickLabel(String id) {
    if (id.isEmpty) return 'Root';
    return categories.firstWhere((e) => e.id == id).label;
  }

  String tilesetRowLabel(String id) {
    if (id.isEmpty) return 'None';
    return availableTilesets.firstWhere((e) => e.id == id).name;
  }

  await showMacosEditorTallSheet<void>(
    context: context,
    maxWidth: 420,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  preset == null ? 'New Terrain Preset' : 'Edit Terrain Preset',
                  style: editorMacosSheetTitleStyle(ctx),
                ),
                const SizedBox(height: 12),
                MacosTextField(
                  controller: controller,
                  autofocus: true,
                  placeholder: 'Preset name',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    secondary: true,
                    onPressed: () async {
                      final picked = await showCupertinoListPicker<TerrainType>(
                        context: ctx,
                        title: 'Base type',
                        items: paintableTerrainTypes,
                        labelOf: _terrainLabel,
                      );
                      if (picked != null) {
                        setState(() => terrainType = picked);
                      }
                    },
                    child: Text(
                      'Base type: ${_terrainLabel(terrainType)}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    secondary: true,
                    onPressed: () async {
                      final items = <String>[
                        '',
                        ...categories.map((c) => c.id),
                      ];
                      final picked = await showCupertinoListPicker<String>(
                        context: ctx,
                        title: 'Folder',
                        items: items,
                        labelOf: folderRowPickLabel,
                      );
                      if (picked != null) {
                        setState(
                          () => categoryId = picked.isEmpty ? null : picked,
                        );
                      }
                    },
                    child: Text(
                      'Folder: ${folderRowPickLabel(categoryId ?? '')}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    secondary: true,
                    onPressed: () async {
                      final items = <String>[
                        '',
                        ...availableTilesets.map((t) => t.id),
                      ];
                      final picked = await showCupertinoListPicker<String>(
                        context: ctx,
                        title: 'Tileset',
                        items: items,
                        labelOf: tilesetRowLabel,
                      );
                      if (picked != null) {
                        setState(() => tilesetId = picked);
                      }
                    },
                    child: Text('Tileset: ${tilesetRowLabel(tilesetId)}'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terrain tilesets cannot be shared with path presets.',
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Visual Variants',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.label.resolveFrom(ctx),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add, size: 16),
                          SizedBox(width: 4),
                          Text('Add'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (variants.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No visual variant. Renderer will fallback to color overlay.',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                      ),
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
                          onDelete: () => setState(
                            () => variants.removeAt(index),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) {
                          await showCupertinoEditorAlert(
                            ctx,
                            message: 'Preset name is required.',
                          );
                          return;
                        }
                        if (preset == null) {
                          await notifier.createTerrainPreset(
                            name: controller.text.trim(),
                            terrainType: terrainType,
                            categoryId: categoryId,
                            tilesetId: tilesetId,
                            variants: variants,
                          );
                        } else {
                          await notifier.updateTerrainPreset(
                            presetId: preset.id,
                            name: controller.text.trim(),
                            terrainType: terrainType,
                            categoryId: categoryId,
                            clearCategoryId: categoryId == null,
                            tilesetId: tilesetId,
                            clearTilesetId: tilesetId.isEmpty,
                            variants: variants,
                          );
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(preset == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showPathPresetDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
  String? initialCategoryId,
  ProjectPathPreset? preset,
}) async {
  final controller = TextEditingController(text: preset?.name ?? '');
  var traversalType = _pathTraversalTypeFromSurfaceKind(
    preset?.surfaceKind ?? PathSurfaceKind.path,
  );
  var categoryId = preset?.categoryId ?? initialCategoryId;
  var tilesetId = preset?.tilesetId ?? '';
  final variants = <TerrainPathVariant, List<TilesetVisualFrame>>{
    for (final mapping
        in preset?.variants ?? const <PathPresetVariantMapping>[])
      if (mapping.frames.isNotEmpty)
        mapping.variant: List<TilesetVisualFrame>.from(
          mapping.frames,
          growable: false,
        ),
  };
  final categories = _flattenCategories(
    notifier,
    PresetLibraryKind.path,
  );
  final availableTilesets = List<ProjectTilesetEntry>.from(
    _pathTilesetCandidates(
      tilesets: tilesets,
      terrainPresets: notifier.getTerrainPresets(),
      currentTilesetId: preset?.tilesetId,
    ),
  );
  String pathFolderRowPickLabel(String id) {
    if (id.isEmpty) return 'Root';
    return categories.firstWhere((e) => e.id == id).label;
  }

  String pathTilesetRowLabel(String id) {
    if (id.isEmpty) return 'None';
    return availableTilesets.firstWhere((e) => e.id == id).name;
  }

  await showMacosEditorTallSheet<void>(
    context: context,
    maxWidth: 420,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  preset == null ? 'New Path Preset' : 'Edit Path Preset',
                  style: editorMacosSheetTitleStyle(ctx),
                ),
                const SizedBox(height: 12),
                MacosTextField(
                  controller: controller,
                  autofocus: true,
                  placeholder: 'Preset name',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Surface type',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.label.resolveFrom(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoSlidingSegmentedControl<_PathTraversalType>(
                      groupValue: traversalType,
                      onValueChanged: (value) {
                        if (value != null) {
                          setState(() => traversalType = value);
                        }
                      },
                      children: {
                        for (final t in _PathTraversalType.values)
                          t: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(_pathTraversalLabel(t)),
                          ),
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    secondary: true,
                    onPressed: () async {
                      final items = <String>[
                        '',
                        ...categories.map((c) => c.id),
                      ];
                      final picked = await showCupertinoListPicker<String>(
                        context: ctx,
                        title: 'Folder',
                        items: items,
                        labelOf: pathFolderRowPickLabel,
                      );
                      if (picked != null) {
                        setState(
                          () => categoryId = picked.isEmpty ? null : picked,
                        );
                      }
                    },
                    child: Text(
                      'Folder: ${pathFolderRowPickLabel(categoryId ?? '')}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    secondary: true,
                    onPressed: () async {
                      final items = <String>[
                        '',
                        ...availableTilesets.map((t) => t.id),
                      ];
                      final picked = await showCupertinoListPicker<String>(
                        context: ctx,
                        title: 'Tileset',
                        items: items,
                        labelOf: pathTilesetRowLabel,
                      );
                      if (picked != null) {
                        setState(() => tilesetId = picked);
                      }
                    },
                    child: Text(
                      'Tileset: ${pathTilesetRowLabel(tilesetId)}',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Path tilesets cannot be shared with terrain presets.',
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Variant Mapping',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label.resolveFrom(ctx),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${variants.length}/${TerrainPathVariant.values.length} mapped',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: tilesetId.trim().isEmpty
                      ? null
                      : () async {
                          final mapped = await _showPathMappingWorkspaceDialog(
                            context,
                            notifier: notifier,
                            settings: settings,
                            tilesetId: tilesetId,
                            initialMappings: variants,
                          );
                          if (mapped == null) {
                            return;
                          }
                          setState(() {
                            variants
                              ..clear()
                              ..addAll(mapped);
                          });
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.square_grid_2x2, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Open Visual Mapping Editor',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tilesetId.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Select a path tileset first to map variants.',
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) {
                          await showCupertinoEditorAlert(
                            ctx,
                            message: 'Preset name is required.',
                          );
                          return;
                        }
                        final mappings = variants.entries
                            .where((entry) => entry.value.isNotEmpty)
                            .map(
                              (entry) => PathPresetVariantMapping(
                                variant: entry.key,
                                frames: List<TilesetVisualFrame>.from(
                                  entry.value,
                                  growable: false,
                                ),
                              ),
                            )
                            .toList(growable: false)
                          ..sort(
                            (a, b) =>
                                a.variant.index.compareTo(b.variant.index),
                          );
                        final resolvedSurfaceKind =
                            _surfaceKindForPathTraversalType(
                          traversalType: traversalType,
                          previousSurfaceKind:
                              preset?.surfaceKind ?? PathSurfaceKind.path,
                        );
                        if (preset == null) {
                          await notifier.createPathPreset(
                            name: controller.text.trim(),
                            surfaceKind: resolvedSurfaceKind,
                            categoryId: categoryId,
                            tilesetId: tilesetId,
                            variants: mappings,
                          );
                        } else {
                          await notifier.updatePathPreset(
                            presetId: preset.id,
                            name: controller.text.trim(),
                            surfaceKind: resolvedSurfaceKind,
                            categoryId: categoryId,
                            clearCategoryId: categoryId == null,
                            tilesetId: tilesetId,
                            clearTilesetId: tilesetId.isEmpty,
                            variants: mappings,
                          );
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(preset == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
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

const List<TerrainPathVariant> _pathSchemaEditableVariants =
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

Future<TerrainPresetVariant?> _showTerrainVariantDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required ProjectSettings settings,
  required String tilesetId,
  TerrainPresetVariant? initial,
}) async {
  final xController = TextEditingController(
      text: (initial?.frames.primarySource.x ?? 0).toString());
  final yController = TextEditingController(
      text: (initial?.frames.primarySource.y ?? 0).toString());
  final widthController = TextEditingController(
      text: (initial?.frames.primarySource.width ?? 1).toString());
  final heightController = TextEditingController(
      text: (initial?.frames.primarySource.height ?? 1).toString());
  final weightController =
      TextEditingController(text: (initial?.weight ?? 1).toString());

  TerrainPresetVariant? result;

  await showMacosEditorModalSheet<void>(
    context: context,
    maxWidth: 400,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          initial == null ? 'Add Variant' : 'Edit Variant',
          style: editorMacosSheetTitleStyle(ctx),
        ),
        const SizedBox(height: 12),
        if (tilesetId.trim().isNotEmpty) ...[
          PushButton(
            controlSize: ControlSize.large,
            secondary: true,
            onPressed: () async {
              final currentSource = TilesetSourceRect(
                x: int.tryParse(xController.text.trim()) ?? 0,
                y: int.tryParse(yController.text.trim()) ?? 0,
                width: int.tryParse(widthController.text.trim()) ?? 1,
                height: int.tryParse(heightController.text.trim()) ?? 1,
              );
              final picked = await _showTilesetRectPickerDialog(
                context,
                notifier: notifier,
                settings: settings,
                tilesetId: tilesetId,
                initial: currentSource,
              );
              if (picked == null) {
                return;
              }
              xController.text = picked.x.toString();
              yController.text = picked.y.toString();
              widthController.text = picked.width.toString();
              heightController.text = picked.height.toString();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.square_grid_2x2, size: 16),
                SizedBox(width: 8),
                Text('Pick From Tileset'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: MacosTextField(
                controller: xController,
                keyboardType: TextInputType.number,
                placeholder: 'X',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MacosTextField(
                controller: yController,
                keyboardType: TextInputType.number,
                placeholder: 'Y',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MacosTextField(
                controller: widthController,
                keyboardType: TextInputType.number,
                placeholder: 'Width',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MacosTextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                placeholder: 'Height',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MacosTextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          placeholder: 'Weight',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            PushButton(
              controlSize: ControlSize.large,
              onPressed: () async {
                final errs = [
                  _positiveOrZeroValidator(xController.text),
                  _positiveOrZeroValidator(yController.text),
                  _positiveValidator(widthController.text),
                  _positiveValidator(heightController.text),
                  _positiveValidator(weightController.text),
                ].whereType<String>();
                if (errs.isNotEmpty) {
                  await showCupertinoEditorAlert(
                    ctx,
                    message: errs.first,
                  );
                  return;
                }
                result = TerrainPresetVariant(
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(
                        x: int.parse(xController.text.trim()),
                        y: int.parse(yController.text.trim()),
                        width: int.parse(widthController.text.trim()),
                        height: int.parse(heightController.text.trim()),
                      ),
                    ),
                  ],
                  weight: int.parse(weightController.text.trim()),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
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
  if (path == null) {
    return null;
  }
  final image = await _TerrainTilesetImageCache.load(path);
  if (image == null) {
    return null;
  }
  if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
    return null;
  }
  final columns = image.width ~/ settings.tileWidth;
  final rows = image.height ~/ settings.tileHeight;
  if (columns <= 0 || rows <= 0) {
    return null;
  }

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

  final cellWidth = math.max(16.0, settings.tileWidth * settings.displayScale);
  final cellHeight =
      math.max(16.0, settings.tileHeight * settings.displayScale);
  final canvasWidth = columns * cellWidth;
  final canvasHeight = rows * cellHeight;

  if (!context.mounted) {
    return null;
  }
  return showMacosSheet<TilesetSourceRect>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SizedBox(
            width: 760,
            height: 560,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle ??
                        'Selection ${result.width}x${result.height} at (${result.x}, ${result.y})',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      child: SingleChildScrollView(
                        primary: false,
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () => Navigator.pop(ctx, result),
                        child: const Text('Use Selection'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
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

Future<Map<TerrainPathVariant, List<TilesetVisualFrame>>?>
    _showPathMappingWorkspaceDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required ProjectSettings settings,
  required String tilesetId,
  required Map<TerrainPathVariant, List<TilesetVisualFrame>> initialMappings,
  TerrainPathVariant? initialVariant,
}) async {
  final normalizedTilesetId = tilesetId.trim();
  if (normalizedTilesetId.isEmpty) {
    return null;
  }
  final path = notifier.getTilesetAbsolutePathById(normalizedTilesetId);
  if (path == null || path.isEmpty) {
    return null;
  }
  final image = await _TerrainTilesetImageCache.load(path);
  if (image == null) {
    return null;
  }

  final sourceTileWidth = settings.tileWidth;
  final sourceTileHeight = settings.tileHeight;
  if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
    return null;
  }
  final columns = image.width ~/ sourceTileWidth;
  final rows = image.height ~/ sourceTileHeight;
  if (columns <= 0 || rows <= 0) {
    return null;
  }

  final mappings = <TerrainPathVariant, List<TilesetVisualFrame>>{
    for (final entry in initialMappings.entries)
      if (entry.value.isNotEmpty)
        entry.key: List<TilesetVisualFrame>.from(
          entry.value,
          growable: false,
        ),
  };
  TerrainPathVariant selectedVariant = initialVariant != null &&
          _pathSchemaEditableVariants.contains(initialVariant)
      ? initialVariant
      : _pathSchemaEditableVariants.firstWhere(
          (variant) => !mappings.containsKey(variant),
          orElse: () => _pathSchemaEditableVariants.first,
        );
  Map<TerrainPathVariant, List<TilesetVisualFrame>>? result;

  if (!context.mounted) {
    return null;
  }
  await showMacosSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 980,
              height: 660,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Path Mapping Editor',
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 430,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Step 1: Complete the schema',
                                style: TextStyle(
                                  color: CupertinoColors.label
                                      .resolveFrom(ctx)
                                      .withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${mappings.length}/${TerrainPathVariant.values.length} mapped',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(ctx),
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
                                  color: CupertinoColors.systemFill
                                      .resolveFrom(ctx),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.separator
                                        .resolveFrom(ctx),
                                  ),
                                ),
                                child: Text(
                                  'Select a slot in the schema, then click a cell in the tileset on the right to assign it.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(ctx),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemFill
                                        .resolveFrom(ctx),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: CupertinoColors.separator
                                          .resolveFrom(ctx),
                                    ),
                                  ),
                                  child: _PathSchemaCanvas(
                                    mappings: mappings,
                                    selectedVariant: selectedVariant,
                                    image: image,
                                    sourceTileWidth: sourceTileWidth,
                                    sourceTileHeight: sourceTileHeight,
                                    onSelect: (variant) => setState(
                                        () => selectedVariant = variant),
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
                              color:
                                  CupertinoColors.systemFill.resolveFrom(ctx),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    CupertinoColors.separator.resolveFrom(ctx),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Step 2: Click the tileset to map "${_pathVariantDisplayName(selectedVariant)}"',
                                  style: TextStyle(
                                    color: CupertinoColors.label
                                        .resolveFrom(ctx)
                                        .withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tileset: ${notifier.getTilesetById(normalizedTilesetId)?.name ?? normalizedTilesetId}',
                                  style: TextStyle(
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(ctx),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: EditorPaintColors.blueGrey
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CupertinoColors.separator
                                          .resolveFrom(ctx),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active variant: ${_pathVariantDisplayName(selectedVariant)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: CupertinoColors.label
                                              .resolveFrom(ctx),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Connections: ${_pathVariantDirectionsLabel(selectedVariant)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(ctx),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _pathVariantUsageDescription(
                                          selectedVariant,
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(ctx),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _PathVariantFramesEditor(
                                  image: image,
                                  sourceTileWidth: sourceTileWidth,
                                  sourceTileHeight: sourceTileHeight,
                                  frames: mappings[selectedVariant] ??
                                      const <TilesetVisualFrame>[],
                                  onChanged: (next) {
                                    setState(() {
                                      if (next.isEmpty) {
                                        mappings.remove(selectedVariant);
                                      } else {
                                        mappings[selectedVariant] = next;
                                      }
                                    });
                                  },
                                  onPickFrame: (initial) async {
                                    final picked =
                                        await _showTilesetRectPickerDialog(
                                      context,
                                      notifier: notifier,
                                      settings: settings,
                                      tilesetId: normalizedTilesetId,
                                      initial: initial,
                                      title: 'Pick path frame source',
                                    );
                                    if (picked == null) {
                                      return null;
                                    }
                                    return TilesetSourceRect(
                                      x: picked.x,
                                      y: picked.y,
                                      width: 1,
                                      height: 1,
                                    );
                                  },
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
                                        final renderHeight =
                                            image.height * scale;
                                        final cellWidth = renderWidth / columns;
                                        final cellHeight = renderHeight / rows;

                                        void mapCurrentVariant(
                                          Offset localPosition,
                                        ) {
                                          final pos = _gridFromPickerLocal(
                                            localPosition,
                                            cellWidth,
                                            cellHeight,
                                            columns,
                                            rows,
                                          );
                                          setState(() {
                                            mappings[selectedVariant] =
                                                _withUpdatedPrimaryPathFrame(
                                              mappings[selectedVariant],
                                              TilesetSourceRect(
                                                x: pos.x,
                                                y: pos.y,
                                                width: 1,
                                                height: 1,
                                              ),
                                            );
                                          });
                                        }

                                        return SizedBox(
                                          width: renderWidth,
                                          height: renderHeight,
                                          child: GestureDetector(
                                            onTapDown: (details) =>
                                                mapCurrentVariant(
                                              details.localPosition,
                                            ),
                                            onPanUpdate: (details) =>
                                                mapCurrentVariant(
                                              details.localPosition,
                                            ),
                                            child: CustomPaint(
                                              painter:
                                                  _PathTilesetMappingPainter(
                                                image: image,
                                                columns: columns,
                                                rows: rows,
                                                mappings: mappings,
                                                selectedVariant:
                                                    selectedVariant,
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: mappings.containsKey(selectedVariant)
                            ? () => setState(
                                  () => mappings.remove(selectedVariant),
                                )
                            : null,
                        child: const Text('Clear Variant'),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          result = _completePathMappings(
                            <TerrainPathVariant, List<TilesetVisualFrame>>{
                              for (final entry in mappings.entries)
                                if (entry.value.isNotEmpty)
                                  entry.key: List<TilesetVisualFrame>.from(
                                    entry.value,
                                    growable: false,
                                  ),
                            },
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  return result;
}

Map<TerrainPathVariant, List<TilesetVisualFrame>> _completePathMappings(
  Map<TerrainPathVariant, List<TilesetVisualFrame>> mappings,
) {
  final completed = <TerrainPathVariant, List<TilesetVisualFrame>>{
    for (final entry in mappings.entries)
      entry.key: List<TilesetVisualFrame>.from(entry.value, growable: false),
  };

  List<TilesetVisualFrame>? pick(List<TerrainPathVariant> order) {
    for (final variant in order) {
      final frames = completed[variant];
      if (frames != null && frames.isNotEmpty) {
        return frames;
      }
    }
    return null;
  }

  void ensure(
    TerrainPathVariant target,
    List<TerrainPathVariant> fallbackOrder,
  ) {
    if (completed.containsKey(target)) {
      return;
    }
    final frames = pick(fallbackOrder);
    if (frames == null || frames.isEmpty) {
      return;
    }
    completed[target] = List<TilesetVisualFrame>.from(
      frames,
      growable: false,
    );
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

Future<void> _runTerrainMemberAssistant(
  BuildContext context, {
  required EditorNotifier notifier,
  required ProjectSettings settings,
  required ProjectTerrainPreset preset,
}) async {
  final tilesetId = preset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return;
  }
  var variants = List<TerrainPresetVariant>.from(preset.variants);
  while (true) {
    if (!context.mounted) {
      return;
    }
    final picked = await _showTilesetRectPickerDialog(
      context,
      notifier: notifier,
      settings: settings,
      tilesetId: tilesetId,
      initial: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
      title: 'Add Terrain Member',
    );
    if (picked == null) {
      break;
    }
    variants.add(
      TerrainPresetVariant(
        frames: [TilesetVisualFrame(source: picked)],
        weight: 1,
      ),
    );
    await notifier.updateTerrainPreset(
      presetId: preset.id,
      variants: variants,
    );
    if (!context.mounted) {
      return;
    }
    final addMore = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Add Another Member?',
      message: 'Continue selecting cells for this terrain preset?',
      secondaryLabel: 'No',
      primaryLabel: 'Yes',
      icon: CupertinoIcons.question_circle_fill,
    );
    if (!addMore) {
      break;
    }
  }
}

Future<void> _runPathMappingAssistant(
  BuildContext context, {
  required EditorNotifier notifier,
  required ProjectSettings settings,
  required ProjectPathPreset preset,
}) async {
  final tilesetId = preset.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return;
  }
  final mapped = await _showPathMappingWorkspaceDialog(
    context,
    notifier: notifier,
    settings: settings,
    tilesetId: tilesetId,
    initialMappings: {
      for (final mapping in preset.variants)
        if (mapping.frames.isNotEmpty)
          mapping.variant: List<TilesetVisualFrame>.from(
            mapping.frames,
            growable: false,
          ),
    },
  );
  if (mapped == null) {
    return;
  }
  final next = mapped.entries
      .where((entry) => entry.value.isNotEmpty)
      .map(
        (entry) => PathPresetVariantMapping(
          variant: entry.key,
          frames: List<TilesetVisualFrame>.from(entry.value, growable: false),
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
            color: EditorPaintColors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EditorPaintColors.white12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Tileset preview unavailable',
            style: TextStyle(fontSize: 11, color: EditorPaintColors.white60),
          ),
        );
      }
      return Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EditorPaintColors.white12),
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

Widget _buildPresetDetailsContent({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic preset,
  required PresetLibraryKind kind,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
}) {
  final color = kind == PresetLibraryKind.terrain ? EditorChrome.accentJade : EditorChrome.accentWarm;
  return _PresetDetailsCard(
    kind: kind,
    preset: preset,
    color: color,
    settings: settings,
    tilesets: tilesets,
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
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return '> 0';
  }
  return null;
}

String? _positiveOrZeroValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return '>= 0';
  }
  return null;
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

enum _PathTraversalType { ground, water }

_PathTraversalType _pathTraversalTypeFromSurfaceKind(PathSurfaceKind kind) {
  if (kind == PathSurfaceKind.water) {
    return _PathTraversalType.water;
  }
  return _PathTraversalType.ground;
}

PathSurfaceKind _surfaceKindForPathTraversalType({
  required _PathTraversalType traversalType,
  required PathSurfaceKind previousSurfaceKind,
}) {
  if (traversalType == _PathTraversalType.water) {
    return PathSurfaceKind.water;
  }
  if (previousSurfaceKind == PathSurfaceKind.water) {
    return PathSurfaceKind.path;
  }
  return previousSurfaceKind;
}

String _pathTraversalLabel(_PathTraversalType type) {
  return switch (type) {
    _PathTraversalType.ground => 'Ground',
    _PathTraversalType.water => 'Water',
  };
}

// ---------------------------------------------------------------------------
// Path animation helpers (moved to terrain_map_panel.dart)
// ---------------------------------------------------------------------------
// The following helper functions are kept for backward compatibility
// but are no longer used in this file. They were used by the old
// _PathAnimationTriggerRuleCard widget which has been removed.

TilesetSourceRect? _pathMappingPrimarySource(List<TilesetVisualFrame>? frames) {
  if (frames == null || frames.isEmpty) {
    return null;
  }
  return frames.first.source;
}

List<TilesetVisualFrame> _withUpdatedPrimaryPathFrame(
  List<TilesetVisualFrame>? current,
  TilesetSourceRect source,
) {
  final normalizedSource = TilesetSourceRect(
    x: source.x,
    y: source.y,
    width: 1,
    height: 1,
  );
  if (current == null || current.isEmpty) {
    return <TilesetVisualFrame>[
      TilesetVisualFrame(source: normalizedSource),
    ];
  }
  final next = List<TilesetVisualFrame>.from(current, growable: false);
  final first = next.first;
  next[0] = first.copyWith(source: normalizedSource);
  return next;
}

bool _sameFrameList(
  List<TilesetVisualFrame>? left,
  List<TilesetVisualFrame>? right,
) {
  if (left == null || right == null) {
    return left == null && right == null;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

String _terrainVariantLabel(TerrainPresetVariant variant) {
  final s = variant.frames.primarySource;
  return '(${s.x}, ${s.y}) ${s.width}x${s.height} • w${variant.weight}';
}

String _pathVariantDisplayName(TerrainPathVariant variant) {
  return switch (variant) {
    TerrainPathVariant.isolated => 'Isolated',
    TerrainPathVariant.endNorth => 'North End',
    TerrainPathVariant.endEast => 'East End',
    TerrainPathVariant.endSouth => 'South End',
    TerrainPathVariant.endWest => 'West End',
    TerrainPathVariant.horizontal => 'Horizontal',
    TerrainPathVariant.vertical => 'Vertical',
    TerrainPathVariant.cornerNE => 'North-East Corner',
    TerrainPathVariant.cornerSE => 'South-East Corner',
    TerrainPathVariant.cornerSW => 'South-West Corner',
    TerrainPathVariant.cornerNW => 'North-West Corner',
    TerrainPathVariant.innerCornerNE => 'Inner North-East Corner',
    TerrainPathVariant.innerCornerSE => 'Inner South-East Corner',
    TerrainPathVariant.innerCornerSW => 'Inner South-West Corner',
    TerrainPathVariant.innerCornerNW => 'Inner North-West Corner',
    TerrainPathVariant.teeNorth => 'North T-Junction',
    TerrainPathVariant.teeEast => 'East T-Junction',
    TerrainPathVariant.teeSouth => 'South T-Junction',
    TerrainPathVariant.teeWest => 'West T-Junction',
    TerrainPathVariant.cross => 'Cross',
  };
}

String _pathVariantDirectionsLabel(TerrainPathVariant variant) {
  final c = _pathVariantConnections(variant);
  final directions = <String>[];
  if (c.north) directions.add('North');
  if (c.east) directions.add('East');
  if (c.south) directions.add('South');
  if (c.west) directions.add('West');
  if (directions.isEmpty) {
    return 'No connection';
  }
  return directions.join(' + ');
}

String _pathVariantUsageDescription(TerrainPathVariant variant) {
  if (_isInnerCornerVariant(variant)) {
    final corner = switch (variant) {
      TerrainPathVariant.innerCornerNE => 'north-east',
      TerrainPathVariant.innerCornerSE => 'south-east',
      TerrainPathVariant.innerCornerSW => 'south-west',
      TerrainPathVariant.innerCornerNW => 'north-west',
      _ => '',
    };
    return 'Used when all four directions connect, with a diagonal gap on the $corner side.';
  }
  final c = _pathVariantConnections(variant);
  if (!c.north && !c.east && !c.south && !c.west) {
    return 'Used when the path cell has no path neighbors.';
  }
  final directions = <String>[];
  if (c.north) directions.add('North');
  if (c.east) directions.add('East');
  if (c.south) directions.add('South');
  if (c.west) directions.add('West');
  return 'Used when the path cell connects to: ${directions.join(', ')}.';
}

bool _isInnerCornerVariant(TerrainPathVariant variant) {
  return variant == TerrainPathVariant.innerCornerNE ||
      variant == TerrainPathVariant.innerCornerSE ||
      variant == TerrainPathVariant.innerCornerSW ||
      variant == TerrainPathVariant.innerCornerNW;
}

String _presetId(dynamic preset) => preset.id as String;

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
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          EditorToolbarIconButton(
            icon: CupertinoIcons.pencil,
            iconSize: 15,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          EditorToolbarIconButton(
            icon: CupertinoIcons.xmark,
            iconSize: 15,
            onPressed: onDelete,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
