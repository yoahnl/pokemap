import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../theme/theme.dart';
import 'terrain_editor/path_mapping_editor_helpers.dart';

part 'terrain_editor/dialogs/terrain_preset_dialogs.dart';
part 'terrain_editor/widgets/terrain_mapping_workspace.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({
    super.key,

    /// Masque le bandeau « Surface Library » quand l’en-tête est géré par le parent (explorateur).
    this.omitOuterHeader = false,
  });

  final bool omitOuterHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;
    final settings = snapshot.settings;
    final tilesets = snapshot.tilesets;

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);
    return Column(
      children: [
        if (!omitOuterHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        EditorChrome.accentWarm.withValues(alpha: 0.22),
                        EditorChrome.accentJade.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const MacosIcon(
                    CupertinoIcons.square_stack_3d_down_right_fill,
                    size: 18,
                    color: EditorChrome.accentWarm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surface Library',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: EditorChrome.primaryLabel(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ground presets and path overlays for your world',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EditorChrome.chipFill(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${(snapshot.selectedTerrainPresetId != null ? 1 : 0) + (snapshot.selectedPathPresetId != null ? 1 : 0)} active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
        Expanded(
          child: project == null
              ? Center(
                  child: Text(
                    'Open a project to manage terrain and surface presets',
                    style: TextStyle(color: subtle),
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
                        color: EditorChrome.accentJade,
                        icon: CupertinoIcons.map,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: snapshot.selectedTerrainPresetId,
                      ),
                      const SizedBox(height: 12),
                      _LibraryRoot(
                        title: 'Paths',
                        subtitle:
                            'Surface overlays: roads, water, tall grass, ice, lava, rails...',
                        kind: PresetLibraryKind.path,
                        color: EditorChrome.accentWarm,
                        icon: CupertinoIcons.arrow_branch,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: snapshot.selectedPathPresetId,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LibraryRoot extends ConsumerStatefulWidget {
  const _LibraryRoot({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.color,
    required this.icon,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final String title;
  final String subtitle;
  final PresetLibraryKind kind;
  final Color color;
  final IconData icon;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_LibraryRoot> createState() => _LibraryRootState();
}

class _LibraryRootState extends ConsumerState<_LibraryRoot> {
  bool _expanded = true;
  bool _detailsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final subtitle = widget.subtitle;
    final kind = widget.kind;
    final color = widget.color;
    final icon = widget.icon;
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories = notifier.getPresetCategories(kind: kind);
    final uncategorizedPresets = _rootPresets(notifier, kind);
    final selectedPreset = kind == PresetLibraryKind.terrain
        ? notifier.getTerrainPresetById(selectedPresetId)
        : notifier.getPathPresetById(selectedPresetId);
    final presetCount = kind == PresetLibraryKind.terrain
        ? notifier.getTerrainPresets().length
        : notifier.getPathPresets().length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              color.withValues(alpha: 0.04),
              EditorChrome.islandFillElevated(context),
            ),
            Color.alphaBlend(
              color.withValues(alpha: 0.015),
              EditorChrome.islandFill(context),
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
          if (_expanded) const EditorHorizontalDivider(),
          if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                kind == PresetLibraryKind.terrain
                    ? 'No terrain preset or folder yet'
                    : 'No path preset or folder yet',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            )
          else if (_expanded)
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
                      settings: settings,
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
                      settings: settings,
                      tilesets: tilesets,
                      selected: _presetId(preset) == selectedPresetId,
                    ),
                  ),
                ],
              ),
            ),
          if (_expanded && selectedPreset != null) ...[
            const EditorHorizontalDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _detailsExpanded = !_detailsExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Preset',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          _detailsExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ],
                    ),
                  ),
                  if (_detailsExpanded) ...[
                    const SizedBox(height: 8),
                    _PresetDetailsCard(
                      kind: kind,
                      preset: selectedPreset,
                      color: color,
                      settings: settings,
                      tilesets: tilesets,
                    ),
                  ],
                ],
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

Future<void> _openTerrainCategoryFolderMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset anchorGlobal,
  required ProjectPresetCategory category,
  required PresetLibraryKind kind,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  final notifier = ref.read(editorNotifierProvider.notifier);
  final action = await showMacosEditorContextMenu<String>(
    context: context,
    globalPosition: anchorGlobal,
    actions: const [
      MacosEditorSheetAction(
        label: 'New Subfolder',
        value: 'new_folder',
      ),
      MacosEditorSheetAction(
        label: 'New Preset',
        value: 'new_preset',
      ),
      MacosEditorSheetAction(
        label: 'Rename Folder',
        value: 'rename',
      ),
      MacosEditorSheetAction(
        label: 'Delete Folder',
        value: 'delete',
        isDestructive: true,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case 'new_folder':
      await _showCreateCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        parentCategoryId: category.id,
      );
    case 'new_preset':
      await _showCreatePresetDialog(
        context,
        notifier: notifier,
        kind: kind,
        settings: settings,
        tilesets: tilesets,
        categoryId: category.id,
      );
    case 'rename':
      await _showRenameCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        category: category,
      );
    case 'delete':
      await _showDeleteCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        category: category,
      );
  }
}

Future<void> _openTerrainPresetRowMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset anchorGlobal,
  required PresetLibraryKind kind,
  required dynamic preset,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  final notifier = ref.read(editorNotifierProvider.notifier);
  final action = await showMacosEditorContextMenu<String>(
    context: context,
    globalPosition: anchorGlobal,
    actions: const [
      MacosEditorSheetAction(
        label: 'Edit Preset',
        value: 'edit',
      ),
      MacosEditorSheetAction(
        label: 'Delete Preset',
        value: 'delete',
        isDestructive: true,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  if (action == 'edit') {
    await _showEditPresetDialog(
      context,
      notifier: notifier,
      kind: kind,
      settings: settings,
      preset: preset,
      tilesets: tilesets,
    );
  } else if (action == 'delete') {
    await _showDeletePresetDialog(
      context,
      notifier: notifier,
      kind: kind,
      preset: preset,
    );
  }
}

class _CategoryNode extends ConsumerStatefulWidget {
  const _CategoryNode({
    required this.category,
    required this.kind,
    required this.depth,
    required this.color,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectPresetCategory category;
  final PresetLibraryKind kind;
  final int depth;
  final Color color;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_CategoryNode> createState() => _CategoryNodeState();
}

class _CategoryNodeState extends ConsumerState<_CategoryNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final children = notifier.getPresetCategories(
        kind: widget.kind, parentCategoryId: widget.category.id);
    final presets = widget.kind == PresetLibraryKind.terrain
        ? notifier
            .getTerrainPresets()
            .where((preset) => preset.categoryId == widget.category.id)
            .toList(growable: false)
        : notifier
            .getPathPresets()
            .where((preset) => preset.categoryId == widget.category.id)
            .toList(growable: false);

    final childWidgets = [
      if (_expanded) ...[
        ...children.map(
          (child) => _CategoryNode(
            category: child,
            kind: widget.kind,
            depth: widget.depth + 1,
            color: widget.color,
            settings: widget.settings,
            tilesets: widget.tilesets,
            selectedPresetId: widget.selectedPresetId,
          ),
        ),
        ...presets.map(
          (preset) => _PresetNode(
            kind: widget.kind,
            preset: preset,
            depth: widget.depth + 1,
            color: widget.color,
            settings: widget.settings,
            tilesets: widget.tilesets,
            selected: _presetId(preset) == widget.selectedPresetId,
          ),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: EdgeInsets.only(left: 12.0 + widget.depth * 16.0, right: 4),
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _expanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.folder, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      '${children.length} folders • ${presets.length} presets',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              EditorToolbarIconButton(
                icon: CupertinoIcons.ellipsis_vertical,
                tooltip: 'Folder actions',
                onPressed: () => _openTerrainCategoryFolderMenu(
                  context: context,
                  ref: ref,
                  anchorGlobal: editorMenuAnchorBelowWidget(context),
                  category: widget.category,
                  kind: widget.kind,
                  settings: widget.settings,
                  tilesets: widget.tilesets,
                ),
              ),
            ],
          ),
        ),
        ...childWidgets,
      ],
    );
  }
}

class _PresetNode extends ConsumerWidget {
  const _PresetNode({
    required this.kind,
    required this.preset,
    required this.depth,
    required this.color,
    required this.settings,
    required this.tilesets,
    required this.selected,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final int depth;
  final Color color;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);

    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return GestureDetector(
      onSecondaryTapDown: (d) => _openTerrainPresetRowMenu(
        context: context,
        ref: ref,
        anchorGlobal: d.globalPosition,
        kind: kind,
        preset: preset,
        settings: settings,
        tilesets: tilesets,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : null,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.only(
              left: 44.0 + depth * 16.0, right: 4, top: 6, bottom: 6),
          minimumSize: Size.zero,
          onPressed: () {
            if (kind == PresetLibraryKind.terrain) {
              notifier.selectTerrainPreset(preset.id);
            } else {
              notifier.selectPathPreset(preset.id);
            }
          },
          child: Row(
            children: [
              Icon(
                kind == PresetLibraryKind.terrain
                    ? CupertinoIcons.square_grid_2x2
                    : CupertinoIcons.arrow_branch,
                size: 16,
                color: selected ? color : secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? label : secondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      kind == PresetLibraryKind.terrain
                          ? _terrainLabel(
                              (preset as ProjectTerrainPreset).terrainType,
                            )
                          : _pathTraversalLabel(
                              _pathTraversalTypeFromSurfaceKind(
                                (preset as ProjectPathPreset).surfaceKind,
                              ),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.placeholderText
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (btnContext) => EditorToolbarIconButton(
                  icon: CupertinoIcons.ellipsis_vertical,
                  tooltip: 'Preset actions',
                  onPressed: () => _openTerrainPresetRowMenu(
                    context: context,
                    ref: ref,
                    anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
                    kind: kind,
                    preset: preset,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetDetailsCard extends ConsumerWidget {
  const _PresetDetailsCard({
    required this.kind,
    required this.preset,
    required this.color,
    required this.settings,
    required this.tilesets,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final Color color;
  final ProjectSettings settings;
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
    final tilesetId = (preset.tilesetId as String).trim();
    final terrainPreset = kind == PresetLibraryKind.terrain
        ? preset as ProjectTerrainPreset
        : null;
    final pathPreset =
        kind == PresetLibraryKind.path ? preset as ProjectPathPreset : null;

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name as String,
            style: TextStyle(
              fontSize: 12,
              color: label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Base type: ${_terrainLabel(terrainPreset!.terrainType)}'
                : 'Surface type: ${_pathTraversalLabel(_pathTraversalTypeFromSurfaceKind(pathPreset!.surfaceKind))}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Folder: ${categoryPath ?? 'Root'}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Tileset: ${tilesetName.isEmpty ? 'None' : tilesetName}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Variants: ${terrainPreset!.variants.length}'
                : 'Autotile mappings: ${pathPreset!.variants.length}/${TerrainPathVariant.values.length}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          if (tilesetId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildTilesetPreview(
              notifier: notifier,
              tilesetId: tilesetId,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: () => _showEditPresetDialog(
                  context,
                  notifier: notifier,
                  kind: kind,
                  settings: settings,
                  preset: preset,
                  tilesets: tilesets,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.pencil, size: 16),
                    const SizedBox(width: 6),
                    Text('Edit Preset', style: TextStyle(color: label)),
                  ],
                ),
              ),
              if (kind == PresetLibraryKind.terrain)
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: tilesetId.isEmpty
                      ? null
                      : () => _runTerrainMemberAssistant(
                            context,
                            notifier: notifier,
                            settings: settings,
                            preset: terrainPreset!,
                          ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.square_grid_2x2, size: 16),
                      const SizedBox(width: 6),
                      Text('Edit Sprites', style: TextStyle(color: label)),
                    ],
                  ),
                ),
              if (kind == PresetLibraryKind.path)
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: tilesetId.isEmpty
                      ? null
                      : () => _runPathMappingAssistant(
                            context,
                            notifier: notifier,
                            settings: settings,
                            preset: pathPreset!,
                          ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.arrow_branch, size: 16),
                      const SizedBox(width: 6),
                      Text('Edit Mapping', style: TextStyle(color: label)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetCategorySection extends ConsumerWidget {
  const _PresetCategorySection({
    required this.category,
    required this.kind,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
    required this.notifier,
    required this.onChanged,
  });

  final ProjectPresetCategory? category;
  final PresetLibraryKind kind;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;
  final EditorNotifier notifier;
  final VoidCallback onChanged;

  Color get _color => kind == PresetLibraryKind.terrain
      ? EditorChrome.accentJade
      : EditorChrome.accentWarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uncategorizedPresets = category == null
        ? _rootPresets(notifier, kind)
        : kind == PresetLibraryKind.terrain
            ? notifier
                .getTerrainPresets()
                .where((preset) => preset.categoryId == category?.id)
                .toList(growable: false)
            : notifier
                .getPathPresets()
                .where((preset) => preset.categoryId == category?.id)
                .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (category != null)
          _CategoryNode(
            category: category!,
            kind: kind,
            depth: 0,
            color: _color,
            settings: settings,
            tilesets: tilesets,
            selectedPresetId: selectedPresetId,
          ),
        ...uncategorizedPresets.map(
          (preset) => _PresetNode(
            kind: kind,
            preset: preset,
            depth: category == null ? 0 : 1,
            color: _color,
            settings: settings,
            tilesets: tilesets,
            selected: _presetId(preset) == selectedPresetId,
          ),
        ),
      ],
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

  String _presetId(dynamic preset) {
    return preset.id;
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class TerrainLibraryPanel extends ConsumerWidget {
  const TerrainLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;

    return project == null
        ? Center(
            child: Text(
              'Open a project to manage terrain presets',
              style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          )
        : _TerrainLibraryContent(
            settings: snapshot.settings,
            tilesets: snapshot.tilesets,
            selectedPresetId: snapshot.selectedTerrainPresetId,
          );
  }
}

class _TerrainLibraryContent extends ConsumerStatefulWidget {
  const _TerrainLibraryContent({
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_TerrainLibraryContent> createState() =>
      _TerrainLibraryContentState();
}

class _TerrainLibraryContentState
    extends ConsumerState<_TerrainLibraryContent> {
  bool _expanded = true;

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

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories =
        notifier.getPresetCategories(kind: PresetLibraryKind.terrain);
    final uncategorizedPresets =
        _rootPresets(notifier, PresetLibraryKind.terrain);
    final selectedPreset = notifier.getTerrainPresetById(selectedPresetId);
    final presetCount = notifier.getTerrainPresets().length;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final treeColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.map,
                          size: 16,
                          color: EditorChrome.accentJade,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terrains',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Base ground presets only',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.terrain,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.terrain,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        if (_expanded) const EditorHorizontalDivider(),
        if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No terrain preset or folder yet',
              style: TextStyle(
                fontSize: 11,
                color: secondary,
              ),
            ),
          )
        else if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (categories.isNotEmpty) ...[
                  for (final category in categories)
                    _PresetCategorySection(
                      category: category,
                      kind: PresetLibraryKind.terrain,
                      settings: settings,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                      notifier: notifier,
                      onChanged: () => setState(() {}),
                    ),
                  const SizedBox(height: 8),
                ],
                if (uncategorizedPresets.isNotEmpty) ...[
                  _PresetCategorySection(
                    category: null,
                    kind: PresetLibraryKind.terrain,
                    settings: settings,
                    tilesets: tilesets,
                    selectedPresetId: selectedPresetId,
                    notifier: notifier,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
      ],
    );

    final detailsSection = selectedPreset != null
        ? Column(
            children: [
              const EditorHorizontalDivider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildPresetDetailsContent(
                  context: context,
                  ref: ref,
                  preset: selectedPreset,
                  kind: PresetLibraryKind.terrain,
                  settings: settings,
                  tilesets: tilesets,
                ),
              ),
            ],
          )
        : null;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          treeColumn,
          if (detailsSection != null) detailsSection,
        ],
      ),
    );
  }
}

class PathLibraryPanel extends ConsumerWidget {
  const PathLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;

    return project == null
        ? Center(
            child: Text(
              'Open a project to manage path presets',
              style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          )
        : _PathLibraryContent(
            settings: snapshot.settings,
            tilesets: snapshot.tilesets,
            selectedPresetId: snapshot.selectedPathPresetId,
          );
  }
}

class _PathLibraryContent extends ConsumerStatefulWidget {
  const _PathLibraryContent({
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_PathLibraryContent> createState() =>
      _PathLibraryContentState();
}

class _PathLibraryContentState extends ConsumerState<_PathLibraryContent> {
  bool _expanded = true;

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

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories =
        notifier.getPresetCategories(kind: PresetLibraryKind.path);
    final uncategorizedPresets = _rootPresets(notifier, PresetLibraryKind.path);
    final selectedPreset = notifier.getPathPresetById(selectedPresetId);
    final presetCount = notifier.getPathPresets().length;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final treeColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_branch,
                          size: 16,
                          color: EditorChrome.accentWarm,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paths',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Surface overlays: roads, water, tall grass, ice, lava, rails...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.path,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.path,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        if (_expanded) const EditorHorizontalDivider(),
        if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No path preset or folder yet',
              style: TextStyle(
                fontSize: 11,
                color: secondary,
              ),
            ),
          )
        else if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (categories.isNotEmpty) ...[
                  for (final category in categories)
                    _PresetCategorySection(
                      category: category,
                      kind: PresetLibraryKind.path,
                      settings: settings,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                      notifier: notifier,
                      onChanged: () => setState(() {}),
                    ),
                  const SizedBox(height: 8),
                ],
                if (uncategorizedPresets.isNotEmpty) ...[
                  _PresetCategorySection(
                    category: null,
                    kind: PresetLibraryKind.path,
                    settings: settings,
                    tilesets: tilesets,
                    selectedPresetId: selectedPresetId,
                    notifier: notifier,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
      ],
    );

    final detailsSection = selectedPreset != null
        ? Column(
            children: [
              const EditorHorizontalDivider(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildPresetDetailsContent(
                  context: context,
                  ref: ref,
                  preset: selectedPreset,
                  kind: PresetLibraryKind.path,
                  settings: settings,
                  tilesets: tilesets,
                ),
              ),
            ],
          )
        : null;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          treeColumn,
          if (detailsSection != null) detailsSection,
        ],
      ),
    );
  }
}
