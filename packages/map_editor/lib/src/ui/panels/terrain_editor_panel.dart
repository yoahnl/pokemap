import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../features/editor/state/editor_notifier.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    final settings = project?.settings ?? const ProjectSettings();
    final tilesets = project?.tilesets ?? const <ProjectTilesetEntry>[];
    final selectedTerrainPreset = notifier.getSelectedTerrainPreset();
    final selectedPathPreset = notifier.getSelectedPathPreset();

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);
    return Column(
      children: [
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
                  '${(selectedTerrainPreset != null ? 1 : 0) + (selectedPathPreset != null ? 1 : 0)} active',
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
                        selectedPresetId: selectedTerrainPreset?.id,
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
                        selectedPresetId: selectedPathPreset?.id,
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
              EditorChrome.elevatedPanelBackground(context),
            ),
            Color.alphaBlend(
              color.withValues(alpha: 0.015),
              EditorChrome.panelBackground(context),
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
                            color: CupertinoColors.systemFill
                                .resolveFrom(context),
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

class _CategoryNode extends ConsumerWidget {
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

    return CupertinoDisclosureTile(
      tilePadding: EdgeInsets.only(left: 12.0 + depth * 16.0, right: 4),
      childrenPadding: EdgeInsets.zero,
      leading: Icon(CupertinoIcons.folder, size: 16, color: color),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          Text(
            '${children.length} folders • ${presets.length} presets',
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
      trailing: Builder(
        builder: (btnContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Folder actions',
          onPressed: () => _openTerrainCategoryFolderMenu(
            context: context,
            ref: ref,
            anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
            category: category,
            kind: kind,
            settings: settings,
            tilesets: tilesets,
          ),
        ),
      ),
      onSecondaryTapDown: (d) => _openTerrainCategoryFolderMenu(
        context: context,
        ref: ref,
        anchorGlobal: d.globalPosition,
        category: category,
        kind: kind,
        settings: settings,
        tilesets: tilesets,
      ),
      children: [
        ...children.map(
          (child) => _CategoryNode(
            category: child,
            kind: kind,
            depth: depth + 1,
            color: color,
            settings: settings,
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
            settings: settings,
            tilesets: tilesets,
            selected: _presetId(preset) == selectedPresetId,
          ),
        ),
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
          padding: EdgeInsets.only(left: 44.0 + depth * 16.0, right: 4, top: 6, bottom: 6),
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
                          : _pathSurfaceLabel(
                              (preset as ProjectPathPreset).surfaceKind,
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
                : 'Surface family: ${_pathSurfaceLabel(pathPreset!.surfaceKind)}',
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
                  preset == null
                      ? 'New Terrain Preset'
                      : 'Edit Terrain Preset',
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
                          final picked =
                              await showCupertinoListPicker<TerrainType>(
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
                          final picked =
                              await showCupertinoListPicker<String>(
                            context: ctx,
                            title: 'Folder',
                            items: items,
                            labelOf: folderRowPickLabel,
                          );
                          if (picked != null) {
                            setState(
                              () => categoryId =
                                  picked.isEmpty ? null : picked,
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
                          final picked =
                              await showCupertinoListPicker<String>(
                            context: ctx,
                            title: 'Tileset',
                            items: items,
                            labelOf: tilesetRowLabel,
                          );
                          if (picked != null) {
                            setState(() => tilesetId = picked);
                          }
                        },
                        child:
                            Text('Tileset: ${tilesetRowLabel(tilesetId)}'),
                      ),
                    ),
                          const SizedBox(height: 4),
                          Text(
                            'Terrain tilesets cannot be shared with path presets.',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(ctx),
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
                                  final created =
                                      await _showTerrainVariantDialog(
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
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(ctx),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (var index = 0;
                                    index < variants.length;
                                    index++)
                                  _VariantTile(
                                    label: _terrainVariantLabel(variants[index]),
                                    onEdit: () async {
                                      final edited =
                                          await _showTerrainVariantDialog(
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
  var surfaceKind = preset?.surfaceKind ?? PathSurfaceKind.path;
  var categoryId = preset?.categoryId ?? initialCategoryId;
  var tilesetId = preset?.tilesetId ?? '';
  final variants = <TerrainPathVariant, TilesetSourceRect>{
    for (final mapping
        in preset?.variants ?? const <PathPresetVariantMapping>[])
      mapping.variant: mapping.source,
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () async {
                          final picked =
                              await showCupertinoListPicker<PathSurfaceKind>(
                            context: ctx,
                            title: 'Surface family',
                            items: PathSurfaceKind.values.toList(),
                            labelOf: _pathSurfaceLabel,
                          );
                          if (picked != null) {
                            setState(() => surfaceKind = picked);
                          }
                        },
                        child: Text(
                          'Surface: ${_pathSurfaceLabel(surfaceKind)}',
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
                          final picked =
                              await showCupertinoListPicker<String>(
                            context: ctx,
                            title: 'Folder',
                            items: items,
                            labelOf: pathFolderRowPickLabel,
                          );
                          if (picked != null) {
                            setState(
                              () => categoryId =
                                  picked.isEmpty ? null : picked,
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
                          final picked =
                              await showCupertinoListPicker<String>(
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
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(ctx),
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
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(ctx),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(ctx),
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
                          .map(
                            (entry) => PathPresetVariantMapping(
                              variant: entry.key,
                              source: entry.value,
                            ),
                          )
                          .toList(growable: false)
                        ..sort(
                          (a, b) =>
                              a.variant.index.compareTo(b.variant.index),
                        );
                      if (preset == null) {
                        await notifier.createPathPreset(
                          name: controller.text.trim(),
                          surfaceKind: surfaceKind,
                          categoryId: categoryId,
                          tilesetId: tilesetId,
                          variants: mappings,
                        );
                      } else {
                        await notifier.updatePathPreset(
                          presetId: preset.id,
                          name: controller.text.trim(),
                          surfaceKind: surfaceKind,
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
                        source: TilesetSourceRect(
                          x: int.parse(xController.text.trim()),
                          y: int.parse(yController.text.trim()),
                          width: int.parse(widthController.text.trim()),
                          height: int.parse(heightController.text.trim()),
                        ),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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

  if (!context.mounted) {
    return null;
  }
  await showMacosSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Center(
        child: MacosSheet(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: CupertinoColors.systemFill
                                  .resolveFrom(ctx),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: CupertinoColors.separator
                                    .resolveFrom(ctx),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            onTapDown: (details) =>
                                                mapCurrentVariant(
                                              details.localPosition,
                                            ),
                                            onPanUpdate: (details) =>
                                                mapCurrentVariant(
                                              details.localPosition,
                                            ),
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

Map<TerrainPathVariant, TilesetSourceRect> _completePathMappings(
  Map<TerrainPathVariant, TilesetSourceRect> mappings,
) {
  final completed = <TerrainPathVariant, TilesetSourceRect>{...mappings};

  TilesetSourceRect? pick(List<TerrainPathVariant> order) {
    for (final variant in order) {
      final source = completed[variant];
      if (source != null) {
        return source;
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
    final source = pick(fallbackOrder);
    if (source == null) {
      return;
    }
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
    variants.add(TerrainPresetVariant(source: picked, weight: 1));
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
      for (final mapping in preset.variants) mapping.variant: mapping.source,
    },
  );
  if (mapped == null) {
    return;
  }
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

String _terrainVariantLabel(TerrainPresetVariant variant) {
  return '(${variant.source.x}, ${variant.source.y}) ${variant.source.width}x${variant.source.height} • w${variant.weight}';
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? EditorPaintColors.lightBlueAccent.withValues(alpha: 0.18)
              : EditorPaintColors.black.withValues(alpha: 0.14),
          border: Border.all(
            color: selected
                ? EditorPaintColors.lightBlueAccent
                : EditorPaintColors.white12,
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
    final borderColor = selected ? EditorPaintColors.lightBlueAccent : EditorPaintColors.white24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = EditorPaintColors.black.withValues(alpha: 0.35)
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
        ..color = EditorPaintColors.white24
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
            ? EditorPaintColors.lightBlueAccent.withValues(alpha: 0.16)
            : EditorPaintColors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) * 0.33;
    final activeColor = selected ? EditorPaintColors.lightBlueAccent : EditorPaintColors.white;
    final inactiveColor = EditorPaintColors.white.withValues(alpha: 0.22);
    final activeLinePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final axisPaint = Paint()
      ..color = EditorPaintColors.white.withValues(alpha: 0.14)
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
          ..color = EditorPaintColors.black.withValues(alpha: selected ? 0.72 : 0.58)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        notchCenter,
        3.2,
        Paint()
          ..color = EditorPaintColors.orangeAccent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    _paintCompassLabel(
      canvas,
      'N',
      Offset(center.dx, 4),
      connections.north ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'E',
      Offset(size.width - 5, center.dy),
      connections.east ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'S',
      Offset(center.dx, size.height - 4),
      connections.south ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'W',
      Offset(5, center.dy),
      connections.west ? activeColor : EditorPaintColors.white54,
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
    if (columns <= 0 || rows <= 0) {
      return;
    }

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
          ..color = (selected ? EditorPaintColors.amberAccent : EditorPaintColors.lightBlueAccent)
              .withValues(alpha: selected ? 0.34 : 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = selected ? EditorPaintColors.amberAccent : EditorPaintColors.lightBlueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.2 : 1.4,
      );
    }

    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
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
  if (left.length != right.length) {
    return false;
  }
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

    if (columns <= 0 || rows <= 0) {
      return;
    }
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
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
      Paint()..color = EditorPaintColors.lightBlueAccent.withValues(alpha: 0.24),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = EditorPaintColors.lightBlueAccent
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
    if (path == null || path.isEmpty) {
      return Future.value(null);
    }
    return _cache.putIfAbsent(path, () async {
      try {
        final file = File(path);
        if (!await file.exists()) {
          return null;
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          return null;
        }
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
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
