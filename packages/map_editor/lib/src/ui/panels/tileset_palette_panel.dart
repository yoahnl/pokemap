import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show
        BorderSide,
        BoxShadow,
        Colors,
        Material,
        PopupMenuButton,
        PopupMenuItem,
        RoundedRectangleBorder;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../../application/services/element_collision_authoring_service.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/models/editor_ui_modes.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'element_collision_editor_sheet.dart';

part 'tileset_palette/dialogs/element_frame_picker_dialog.dart';
part 'tileset_palette/widgets/animation/placed_element_animation_widgets.dart';
part 'tileset_palette/widgets/collision/element_collision_editor.dart';
part 'tileset_palette/widgets/collision/element_collision_profile_painter.dart';
part 'tileset_palette/widgets/library/tileset_palette_library_widgets.dart';
part 'tileset_palette/widgets/palette/tileset_palette_preview.dart';
part 'tileset_palette/widgets/placed_instances/placed_instances_section.dart';

const ElementCollisionAuthoringService _elementCollisionAuthoringService =
    ElementCollisionAuthoringService();

class _InspectorPulldownAction {
  const _InspectorPulldownAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
}

class TilesetPalettePanel extends ConsumerStatefulWidget {
  const TilesetPalettePanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TilesetPalettePanel> createState() =>
      _TilesetPalettePanelState();
}

class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  bool _creationMode = false;
  GridPos? _selectionStart;
  GridPos? _selectionEnd;
  String? _selectedCategoryId;
  final Set<String> _expandedCategories = <String>{};
  final Set<String> _expandedTilesetGroups = <String>{};
  final ScrollController _selectionHorizontalScrollController =
      ScrollController();
  final ScrollController _selectionVerticalScrollController =
      ScrollController();
  String? _lastPlacedInstancesSignature;

  @override
  void dispose() {
    _selectionHorizontalScrollController.dispose();
    _selectionVerticalScrollController.dispose();
    super.dispose();
  }

  /// Sélecteur type « menu déroulant » (ancré sous le contrôle), même look que les pilules inspecteur.
  Widget _inspectorPickerDropdown({
    required BuildContext context,
    required Color accent,
    required String fieldLabel,
    required String valueLabel,
    required List<String> orderedIds,
    required String selectedId,
    required String Function(String id) idToLabel,
    required ValueChanged<String> onSelected,
    String? tooltip,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = EditorChrome.primaryLabel(context);
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: tooltip ?? fieldLabel,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        color: EditorChrome.islandFillElevated(context),
        elevation: 3,
        initialValue: selectedId,
        onSelected: onSelected,
        itemBuilder: (menuCtx) => [
          for (final id in orderedIds)
            PopupMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: id == selectedId
                        ? Icon(
                            CupertinoIcons.checkmark,
                            size: 14,
                            color: accent,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      idToLabel(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: id == selectedId
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: accent.withValues(alpha: 0.09),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fieldLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_down, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inspectorAccentPopupMenu({
    required BuildContext context,
    required Color accent,
    required String buttonLabel,
    required List<_InspectorPulldownAction> actions,
  }) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<int>(
        tooltip: buttonLabel,
        padding: EdgeInsets.zero,
        splashRadius: 16,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        color: EditorChrome.islandFillElevated(context),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: accent.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 5),
              Icon(CupertinoIcons.chevron_down, size: 11, color: accent),
            ],
          ),
        ),
        itemBuilder: (ctx) => [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem<int>(
              value: i,
              enabled: actions[i].enabled,
              child: Text(
                actions[i].label,
                style: TextStyle(
                  color: actions[i].enabled
                      ? labelColor
                      : CupertinoColors.placeholderText.resolveFrom(ctx),
                ),
              ),
            ),
        ],
        onSelected: (i) {
          final a = actions[i];
          if (a.enabled) a.onTap();
        },
      ),
    );
  }

  TilesetSourceRect? get _selectionRect {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return null;
    return _rectFromPoints(start, end);
  }

  TilesetSourceRect _rectFromPoints(GridPos start, GridPos end) {
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

  void _setCreationMode(bool enabled) {
    setState(() {
      _creationMode = enabled;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  GridPos _gridFromLocal(
    Offset localPosition,
    double cellSize,
    int columns,
    int rows,
  ) {
    final maxX = math.max(0.0, columns * cellSize - 0.000001);
    final maxY = math.max(0.0, rows * cellSize - 0.000001);
    final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
    final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
    final x = (dx / cellSize).floor().clamp(0, columns - 1);
    final y = (dy / cellSize).floor().clamp(0, rows - 1);
    return GridPos(x: x, y: y);
  }

  @override
  Widget build(BuildContext context) {
    final paletteSnapshot = ref.watch(editorTilesetPaletteSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = paletteSnapshot.activeMap;
    final project = paletteSnapshot.project;
    final settings = paletteSnapshot.settings;

    if (project == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    final selectedTileset = paletteSnapshot.selectedTilesetEntry;
    final selectedTilesetPath = notifier.getSelectedTilesetAbsolutePath();
    if (selectedTileset == null || selectedTilesetPath == null) {
      return Center(
        child: Text(
          'No tileset selected',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }
    final sortedTilesets = List<ProjectTilesetEntry>.from(project.tilesets)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final tileLayers =
        map?.layers.whereType<TileLayer>().toList(growable: false) ?? const [];
    final categories = notifier.getElementCategories();
    if (_selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    return FutureBuilder<ui.Image?>(
      future: _PaletteImageCache.load(selectedTilesetPath),
      builder: (context, imageSnapshot) {
        final image = imageSnapshot.data;
        if (image == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedTileset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tileset image unavailable',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 12),
                PushButton(
                  key: const ValueKey('element-auto-shadow-backfill-button'),
                  controlSize: ControlSize.small,
                  secondary: true,
                  onPressed: () => _showApplyElementAutoShadowsDialog(
                    context,
                    notifier: notifier,
                  ),
                  child: const Text('Ombres auto'),
                ),
              ],
            ),
          );
        }

        final columns =
            settings.tileWidth > 0 ? image.width ~/ settings.tileWidth : 0;
        final rows =
            settings.tileHeight > 0 ? image.height ~/ settings.tileHeight : 0;
        if (columns <= 0 || rows <= 0) {
          return Center(
            child: Text(
              'Invalid tile size for active tileset',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          );
        }

        final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
        final pickerAccent = widget.embedded
            ? EditorChrome.inspectorJoyLilac
            : CupertinoTheme.of(context).primaryColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, widget.embedded ? 8 : 12, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.embedded)
                    Text(
                      'ELEMENTS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: secondary,
                      ),
                    ),
                  if (!widget.embedded) const SizedBox(height: 6),
                  _inspectorPickerDropdown(
                    context: context,
                    accent: pickerAccent,
                    fieldLabel: 'Tileset',
                    valueLabel: selectedTileset.name,
                    tooltip: 'Choisir un tileset',
                    orderedIds:
                        sortedTilesets.map((tileset) => tileset.id).toList(),
                    selectedId: selectedTileset.id,
                    idToLabel: (id) =>
                        sortedTilesets.firstWhere((t) => t.id == id).name,
                    onSelected: notifier.selectTilesetEditorContext,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${columns * rows} tuiles',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                  if (map == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No active map: edition mode only',
                        style: TextStyle(color: secondary, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _buildElementsTab(
                snapshot: paletteSnapshot,
                notifier: notifier,
                image: image,
                project: project,
                categories: categories,
                columns: columns,
                tileWidth: settings.tileWidth,
                tileHeight: settings.tileHeight,
                activeTileset: selectedTileset,
                tileLayers: tileLayers,
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildTilesTab({
    required EditorTilesetPaletteSnapshot snapshot,
    required EditorNotifier notifier,
    required ui.Image image,
    required ProjectManifest project,
    required List<TileLayer> tileLayers,
    required int columns,
    required int rows,
    required ProjectSettings settings,
    required ProjectTilesetEntry activeTileset,
  }) {
    final unitEntryByTileId = <int, TilesetPaletteEntry>{};
    for (final entry in activeTileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width != 1 || ps.height != 1) continue;
      final tileId = ps.y * columns + ps.x + 1;
      if (tileId > 0 && tileId <= columns * rows) {
        unitEntryByTileId[tileId] = entry;
      }
    }

    final filter = snapshot.paletteCategoryFilter;
    final filteredTileIds = <int>[];
    for (var tileId = 1; tileId <= columns * rows; tileId++) {
      if (filter == null) {
        filteredTileIds.add(tileId);
        continue;
      }
      final entry = unitEntryByTileId[tileId];
      if (entry == null) {
        if (filter == PaletteCategory.uncategorized) {
          filteredTileIds.add(tileId);
        }
      } else if (entry.category == filter) {
        filteredTileIds.add(tileId);
      }
    }

    final selectedTileId = snapshot.activeBrush.maybeMap(
      tile: (brush) =>
          brush.tilesetId == activeTileset.id ? brush.tileId : null,
      orElse: () => null,
    );
    final selectedEntry =
        selectedTileId == null ? null : unitEntryByTileId[selectedTileId];
    final selectedCategory =
        selectedEntry?.category ?? PaletteCategory.uncategorized;
    final previewSize = settings.tileWidth * settings.displayScale * 2.0;
    final selectionRect = _selectionRect;

    final tileTabSecondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final tileTabLabel = CupertinoColors.label.resolveFrom(context);
    final filterItems = <int>[
      -1,
      ...List.generate(PaletteCategory.values.length, (i) => i),
    ];
    String filterLabel(int i) =>
        i < 0 ? 'All' : _legacyCategoryLabel(PaletteCategory.values[i]);
    final currentFilterIndex =
        filter == null ? -1 : PaletteCategory.values.indexOf(filter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<int>(
                context: context,
                title: 'Tile Category Filter',
                items: filterItems,
                labelOf: filterLabel,
              );
              if (picked != null) {
                notifier.setPaletteCategoryFilter(
                  picked < 0 ? null : PaletteCategory.values[picked],
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tile Category Filter',
                  style: TextStyle(fontSize: 12, color: tileTabSecondary),
                ),
                Text(
                  filterLabel(currentFilterIndex),
                  style: TextStyle(color: tileTabLabel),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  onPressed: () => _setCreationMode(!_creationMode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _creationMode
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.square,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _creationMode
                              ? 'Exit Element Creation'
                              : 'Create Element',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton.filled(
                onPressed: !_creationMode || selectionRect == null
                    ? null
                    : () => _showCreateElementDialog(
                          context,
                          notifier: notifier,
                          project: project,
                          image: image,
                          tilesetId: activeTileset.id,
                          tilesetGroups: activeTileset.elementGroups,
                          source: selectionRect,
                          tileWidth: settings.tileWidth,
                          tileHeight: settings.tileHeight,
                          activeLayerId: snapshot.activeLayerId,
                          tileLayers: tileLayers,
                        ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _creationMode
              ? _buildSelectionCanvas(
                  image: image,
                  columns: columns,
                  rows: rows,
                  tileWidth: settings.tileWidth,
                  tileHeight: settings.tileHeight,
                  displayScale: settings.displayScale,
                  selectionRect: selectionRect,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    SizedBox(
                      height: 220,
                      child: _buildSelectionCanvas(
                        image: image,
                        columns: columns,
                        rows: rows,
                        tileWidth: settings.tileWidth,
                        tileHeight: settings.tileHeight,
                        displayScale: settings.displayScale,
                        selectionRect: selectionRect,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final paletteTileSize =
                              settings.tileWidth * settings.displayScale;
                          final crossAxisCount =
                              (constraints.maxWidth / (paletteTileSize + 8))
                                  .floor()
                                  .clamp(1, 20);
                          return GridView.builder(
                            itemCount: filteredTileIds.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              final tileId = filteredTileIds[index];
                              return _PaletteTileCell(
                                image: image,
                                tileId: tileId,
                                tileWidth: settings.tileWidth,
                                tileHeight: settings.tileHeight,
                                columns: columns,
                                selected: tileId == selectedTileId,
                                onTap: () {
                                  notifier.selectPaletteTile(tileId);
                                  notifier.selectTool(EditorToolType.tilePaint);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Tile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: tileTabLabel,
                ),
              ),
              if (_creationMode && selectionRect != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Selection: ${selectionRect.width}x${selectionRect.height} at (${selectionRect.x}, ${selectionRect.y})',
                  style: TextStyle(
                    color: tileTabSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: selectedTileId == null
                        ? Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                            ),
                          )
                        : _PaletteTilePreview(
                            image: image,
                            tileId: selectedTileId,
                            tileWidth: settings.tileWidth,
                            tileHeight: settings.tileHeight,
                            columns: columns,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTileId == null
                              ? 'No tile selected'
                              : 'Tile #$selectedTileId',
                          style: TextStyle(fontSize: 12, color: tileTabLabel),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: selectedTileId == null
                              ? null
                              : () async {
                                  final picked = await showCupertinoListPicker<
                                      PaletteCategory>(
                                    context: context,
                                    title: 'Tile Category',
                                    items: PaletteCategory.values.toList(),
                                    labelOf: _legacyCategoryLabel,
                                  );
                                  if (picked != null) {
                                    notifier.upsertPaletteEntryForTile(
                                      tileId: selectedTileId,
                                      columns: columns,
                                      category: picked,
                                      recommendedLayerId:
                                          snapshot.activeLayerId,
                                    );
                                  }
                                },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tile Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tileTabSecondary,
                                ),
                              ),
                              Text(
                                _legacyCategoryLabel(selectedCategory),
                                style: TextStyle(color: tileTabLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElementsTab({
    required EditorTilesetPaletteSnapshot snapshot,
    required EditorNotifier notifier,
    required ui.Image image,
    required ProjectManifest project,
    required List<ProjectElementCategory> categories,
    required int columns,
    required int tileWidth,
    required int tileHeight,
    required ProjectTilesetEntry activeTileset,
    required List<TileLayer> tileLayers,
  }) {
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final categoriesByParent = <String?, List<ProjectElementCategory>>{};
    for (final category in categories) {
      final key = category.parentCategoryId;
      categoriesByParent.putIfAbsent(key, () => []).add(category);
    }
    for (final list in categoriesByParent.values) {
      list.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    final tilesetGroups = notifier.getSelectedTilesetElementGroups();
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in tilesetGroups) group.id: group,
    };
    final tilesetGroupsByParent = <String?, List<TilesetElementGroup>>{};
    for (final group in tilesetGroups) {
      tilesetGroupsByParent
          .putIfAbsent(group.parentGroupId, () => [])
          .add(group);
    }
    for (final list in tilesetGroupsByParent.values) {
      list.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    final selectedTilesetGroupId = snapshot.selectedTilesetElementGroupId;
    final validSelectedTilesetGroupId = selectedTilesetGroupId != null &&
            tilesetGroupById.containsKey(selectedTilesetGroupId)
        ? selectedTilesetGroupId
        : null;

    final tilesetElements = notifier.getSelectedTilesetElements(
      tilesetGroupId: validSelectedTilesetGroupId,
      includeDescendants: true,
    );

    final selectedCategoryId = _selectedCategoryId;
    Set<String>? categoryScope;
    if (selectedCategoryId != null) {
      categoryScope =
          _collectCategoryScope(categoriesByParent, selectedCategoryId);
    }

    final filteredElements = tilesetElements.where((element) {
      if (categoryScope != null &&
          !categoryScope.contains(element.categoryId)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final groupById = <String, ProjectMapGroup>{
      for (final group in project.groups) group.id: group,
    };

    const tilesAccent = EditorChrome.inspectorJoyLilac;
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final rim = EditorChrome.editorIslandRim(context);
    final listSurface = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: tilesAccent.withValues(alpha: 0.07),
    );
    const categoryStripe = EditorChrome.inspectorJoyCyan;

    final tilesetGroupActions = <_InspectorPulldownAction>[
      _InspectorPulldownAction(
        label: 'Nouveau groupe racine',
        onTap: () => _showCreateTilesetGroupDialog(
          context,
          notifier: notifier,
          tilesetId: activeTileset.id,
        ),
      ),
      _InspectorPulldownAction(
        label: 'Nouveau sous-groupe',
        enabled: validSelectedTilesetGroupId != null,
        onTap: () {
          final id = validSelectedTilesetGroupId;
          if (id == null) return;
          _showCreateTilesetSubgroupDialog(
            context,
            notifier: notifier,
            tilesetId: activeTileset.id,
            parentGroupId: id,
          );
        },
      ),
      _InspectorPulldownAction(
        label: 'Renommer la sélection',
        enabled: validSelectedTilesetGroupId != null,
        onTap: () {
          final id = validSelectedTilesetGroupId;
          if (id == null) return;
          _showRenameTilesetGroupDialog(
            context,
            notifier: notifier,
            tilesetId: activeTileset.id,
            groupId: id,
            currentName: tilesetGroupById[id]?.name ?? '',
          );
        },
      ),
    ];

    final categoryActions = <_InspectorPulldownAction>[
      _InspectorPulldownAction(
        label: 'Nouvelle catégorie racine',
        onTap: () => _showCreateCategoryDialog(
          context,
          notifier: notifier,
          parentCategoryId: null,
        ),
      ),
      _InspectorPulldownAction(
        label: 'Nouvelle sous-catégorie',
        enabled: selectedCategoryId != null,
        onTap: () {
          final id = selectedCategoryId;
          if (id == null) return;
          _showCreateCategoryDialog(
            context,
            notifier: notifier,
            parentCategoryId: id,
          );
        },
      ),
      _InspectorPulldownAction(
        label: 'Renommer la catégorie',
        enabled: selectedCategoryId != null,
        onTap: () {
          final id = selectedCategoryId;
          if (id == null) return;
          _showRenameCategoryDialog(
            context,
            notifier: notifier,
            categoryId: id,
            currentName: categoriesById[id]?.name ?? '',
          );
        },
      ),
    ];

    final tilesetGroupRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: validSelectedTilesetGroupId == null,
        label: 'Tous les groupes',
        hasChildren: false,
        expanded: false,
        accentOverride: tilesAccent,
        onTap: () => notifier.selectTilesetElementGroupFilter(null),
      ),
      const EditorHorizontalDivider(),
      ..._buildTilesetGroupRows(
        groupsByParent: tilesetGroupsByParent,
        parentGroupId: null,
        selectedGroupId: validSelectedTilesetGroupId,
        rowAccent: tilesAccent,
        onSelect: (groupId) =>
            notifier.selectTilesetElementGroupFilter(groupId),
      ),
    ];

    final categoryRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: selectedCategoryId == null,
        label: 'Toutes les catégories',
        hasChildren: false,
        expanded: false,
        accentOverride: categoryStripe,
        onTap: () {
          setState(() {
            _selectedCategoryId = null;
          });
        },
      ),
      const EditorHorizontalDivider(),
      ..._buildCategoryRows(
        categoriesByParent: categoriesByParent,
        parentCategoryId: null,
        depth: 0,
        rowAccent: categoryStripe,
      ),
    ];

    final panelMode = snapshot.tilesElementsPanelMode;
    final placedInstancesScope = _resolvePlacedElementInstances(
      snapshot: snapshot,
      activeTileset: activeTileset,
      project: project,
      tilesetColumns: columns,
    );
    final selectedPlacedInstance = _findPlacedElementInstanceById(
      instances: placedInstancesScope.instances,
      instanceId: snapshot.selectedPlacedElementInstanceId,
    );

    if (panelMode == TilesElementsPanelMode.placedInstances) {
      _logPlacedInstancesSnapshot(placedInstancesScope);
      if (snapshot.selectedPlacedElementInstanceId != null &&
          selectedPlacedInstance == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref.read(editorNotifierProvider.notifier).selectPlacedElementInstance(
                instanceId: null,
              );
        });
      }
    }

    final paletteSections = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.square_stack_3d_up_fill,
                  size: 14,
                  color: tilesAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Groupes internes (tileset)',
                    style: TextStyle(
                      color: secondaryLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _inspectorAccentPopupMenu(
                  context: context,
                  accent: tilesAccent,
                  buttonLabel: 'Actions',
                  actions: tilesetGroupActions,
                ),
              ],
            ),
            Text(
              'Filtre les éléments selon le groupe dans ce tileset.',
              style: TextStyle(
                color: secondaryLabel,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: listSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: rim),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ColoredBox(
              color: tilesAccent,
              child: SizedBox(width: 3),
            ),
            Expanded(
              child: ListView(
                children: tilesetGroupRows,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.tag_fill,
                  size: 14,
                  color: categoryStripe,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Catégories d'éléments",
                    style: TextStyle(
                      color: secondaryLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _inspectorAccentPopupMenu(
                  context: context,
                  accent: categoryStripe,
                  buttonLabel: 'Actions',
                  actions: categoryActions,
                ),
              ],
            ),
            Text(
              'Filtre la liste par catégorie projet (pas le tileset).',
              style: TextStyle(
                color: secondaryLabel,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: listSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: rim),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ColoredBox(
              color: categoryStripe,
              child: SizedBox(width: 3),
            ),
            Expanded(
              child: ListView(
                children: categoryRows,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: tilesAccent.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tilesAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: tilesAccent.withValues(alpha: 0.1),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.cube_box_fill,
                  size: 15,
                  color: tilesAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Éléments à placer',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${filteredElements.length}',
                  style: TextStyle(
                    color: secondaryLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                PushButton(
                  key: const ValueKey('element-auto-shadow-backfill-button'),
                  controlSize: ControlSize.small,
                  secondary: true,
                  onPressed: () => _showApplyElementAutoShadowsDialog(
                    context,
                    notifier: notifier,
                  ),
                  child: const Text('Ombres auto'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (filteredElements.isEmpty)
              Text(
                'Aucun élément pour ces filtres',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredElements.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final element = filteredElements[index];
                  final categoryPath = _buildCategoryPathLabel(
                    categoriesById: categoriesById,
                    categoryId: element.categoryId,
                  );
                  final tilesetName = activeTileset.name;
                  final groupLabel = element.groupId == null
                      ? 'Global'
                      : 'Groupe : ${_buildGroupPathLabel(groupById, element.groupId!)}';
                  final tilesetGroupLabel = element.tilesetGroupId == null
                      ? 'Interne : aucun'
                      : 'Interne : ${_buildTilesetGroupPathLabel(tilesetGroupById, element.tilesetGroupId!)}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ProjectElementCard(
                      image: image,
                      element: element,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      selectionAccent: tilesAccent,
                      selected: snapshot.activeBrush.maybeMap(
                        projectElement: (brush) =>
                            brush.elementId == element.id,
                        orElse: () => false,
                      ),
                      categoryPath: categoryPath,
                      tilesetName: tilesetName,
                      groupLabel: groupLabel,
                      tilesetGroupLabel: tilesetGroupLabel,
                      onTap: () {
                        notifier.selectProjectElement(element.id);
                        if (element.recommendedLayerId != null &&
                            (snapshot.activeMap?.layers.any(
                                  (layer) =>
                                      layer is TileLayer &&
                                      layer.id == element.recommendedLayerId,
                                ) ??
                                false)) {
                          notifier.setActiveLayer(
                            element.recommendedLayerId!,
                          );
                        }
                        notifier.selectTool(EditorToolType.tilePaint);
                      },
                      onEdit: () => _showEditElementDialog(
                        context,
                        notifier: notifier,
                        project: project,
                        image: image,
                        element: element,
                        categories: categories,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        tileLayers: tileLayers,
                        tilesetGroups: tilesetGroups,
                      ),
                      onDelete: () => _showDeleteElementDialog(
                        context,
                        notifier: notifier,
                        element: element,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
          child: _buildTilesElementsModeSelector(
            mode: panelMode,
            onChanged: notifier.setTilesElementsPanelMode,
            placedCount: placedInstancesScope.instances.length,
          ),
        ),
        const SizedBox(height: 4),
        if (panelMode == TilesElementsPanelMode.palette) ...paletteSections,
        if (panelMode == TilesElementsPanelMode.placedInstances)
          _PlacedInstancesSection(
            manifest: project,
            image: image,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            scope: placedInstancesScope,
            selectedInstanceId: snapshot.selectedPlacedElementInstanceId,
            selectedInstance: selectedPlacedInstance,
            dialogues: project.dialogues,
            projectRootPath: snapshot.projectRootPath,
            onSelectInstance: (instance) {
              notifier.selectPlacedElementInstance(
                instanceId: instance?.instanceId,
                elementId:
                    instance?.element?.id ?? instance?.instance.elementId,
                layerId: instance?.layerId,
              );
            },
            onCollisionAppliedChanged: (instance, applyCollision) {
              notifier.setPlacedElementInstanceCollisionApplied(
                instanceId: instance.instanceId,
                applyCollision: applyCollision,
              );
            },
            onOpacityChanged: (instance, opacity) {
              notifier.setPlacedElementInstanceOpacity(
                instanceId: instance.instanceId,
                opacity: opacity,
              );
            },
            onShadowOverrideChanged: (instance, shadowOverride) {
              notifier.setPlacedElementInstanceShadowOverride(
                instanceId: instance.instanceId,
                shadowOverride: shadowOverride,
              );
            },
            onEnsureDefaultShadowProfiles: () {
              notifier.ensureDefaultShadowProfiles();
            },
            onAnimationConfigChanged: (instance, animation) {
              notifier.setPlacedElementInstanceAnimationConfig(
                instanceId: instance.instanceId,
                animation: animation,
              );
            },
            onBehaviorsChanged: (instance, behaviors) {
              notifier.setPlacedElementInstanceBehaviors(
                instanceId: instance.instanceId,
                behaviors: behaviors,
              );
            },
            onDeleteInstance: (instance) async {
              await _showDeletePlacedInstanceDialog(
                context,
                notifier: notifier,
                instance: instance,
              );
            },
          ),
      ],
    );
  }

  Widget _buildTilesElementsModeSelector({
    required TilesElementsPanelMode mode,
    required ValueChanged<TilesElementsPanelMode> onChanged,
    required int placedCount,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<TilesElementsPanelMode>(
            groupValue: mode,
            children: const {
              TilesElementsPanelMode.palette: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('Palette'),
              ),
              TilesElementsPanelMode.placedInstances: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('Instances posées'),
              ),
            },
            onValueChanged: (value) {
              if (value == null) {
                return;
              }
              onChanged(value);
            },
          ),
          if (mode == TilesElementsPanelMode.placedInstances) ...[
            const SizedBox(height: 6),
            Text(
              '$placedCount instance${placedCount > 1 ? 's' : ''} détectée${placedCount > 1 ? 's' : ''} sur le calque actif',
              style: TextStyle(
                color: secondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _PlacedElementInstancesScope _resolvePlacedElementInstances({
    required EditorTilesetPaletteSnapshot snapshot,
    required ProjectManifest project,
    required ProjectTilesetEntry activeTileset,
    required int tilesetColumns,
  }) {
    final map = snapshot.activeMap;
    if (map == null) {
      return const _PlacedElementInstancesScope(
        layerId: null,
        layerName: null,
        instances: [],
        emptyTitle: 'Aucune map active',
        emptyMessage: 'Charge une map pour parcourir les éléments posés.',
      );
    }
    final layerId = snapshot.activeLayerId;
    if (layerId == null || layerId.isEmpty) {
      return const _PlacedElementInstancesScope(
        layerId: null,
        layerName: null,
        instances: [],
        emptyTitle: 'Aucun calque actif',
        emptyMessage: 'Sélectionne un calque pour afficher les instances.',
      );
    }
    MapLayer? layer;
    for (final entry in map.layers) {
      if (entry.id == layerId) {
        layer = entry;
        break;
      }
    }
    if (layer == null) {
      return _PlacedElementInstancesScope(
        layerId: layerId,
        layerName: null,
        instances: const [],
        emptyTitle: 'Calque introuvable',
        emptyMessage: 'Le calque actif "$layerId" est introuvable.',
      );
    }
    if (layer is! TileLayer) {
      return _PlacedElementInstancesScope(
        layerId: layer.id,
        layerName: layer.name,
        instances: const [],
        emptyTitle: 'Calque non compatible',
        emptyMessage:
            'Les instances posées sont disponibles sur les calques de tuiles.',
      );
    }
    final tileLayer = layer;
    final layerTilesetId = (tileLayer.tilesetId ?? map.tilesetId).trim();
    if (layerTilesetId.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Tileset manquant',
        emptyMessage:
            'Le calque actif n’a pas de tileset associé pour détecter les éléments.',
      );
    }
    final elementById = <String, ProjectElementEntry>{
      for (final entry in project.elements) entry.id: entry,
    };
    final rawLayerInstances = map.placedElements
        .where((instance) => instance.layerId == tileLayer.id)
        .toList(growable: true)
      ..sort((a, b) {
        final yCompare = a.pos.y.compareTo(b.pos.y);
        if (yCompare != 0) return yCompare;
        final xCompare = a.pos.x.compareTo(b.pos.x);
        if (xCompare != 0) return xCompare;
        return a.id.compareTo(b.id);
      });

    if (rawLayerInstances.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Aucun élément placé sur ce layer',
        emptyMessage: 'Place un élément depuis la palette pour le voir ici.',
      );
    }

    final occurrencesByElementId = <String, int>{};
    final instances = <_PlacedElementInstanceVm>[];
    for (final instance in rawLayerInstances) {
      final element = elementById[instance.elementId];
      final previewAvailable = element != null &&
          _resolveElementPrimaryTilesetId(element) == activeTileset.id &&
          tilesetColumns > 0;
      final key = element?.id ?? instance.elementId;
      final occurrence = (occurrencesByElementId[key] ?? 0) + 1;
      occurrencesByElementId[key] = occurrence;
      instances.add(
        _PlacedElementInstanceVm(
          instance: instance,
          element: element,
          layerName: tileLayer.name,
          occurrence: occurrence,
          previewAvailable: previewAvailable,
        ),
      );
    }

    if (instances.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: layer.id,
        layerName: layer.name,
        instances: const [],
        emptyTitle: 'Aucun élément placé sur ce layer',
        emptyMessage: 'Place un élément depuis la palette pour le voir ici.',
      );
    }

    return _PlacedElementInstancesScope(
      layerId: layer.id,
      layerName: layer.name,
      instances: instances,
      emptyTitle: '',
      emptyMessage: '',
    );
  }

  _PlacedElementInstanceVm? _findPlacedElementInstanceById({
    required List<_PlacedElementInstanceVm> instances,
    required String? instanceId,
  }) {
    if (instanceId == null || instanceId.isEmpty) {
      return null;
    }
    for (final instance in instances) {
      if (instance.instanceId == instanceId) {
        return instance;
      }
    }
    return null;
  }

  void _logPlacedInstancesSnapshot(_PlacedElementInstancesScope scope) {
    if (!kDebugMode) {
      return;
    }
    final layerId = scope.layerId ?? '';
    final signature =
        '$layerId|${scope.instances.length}|${scope.emptyTitle}|${scope.emptyMessage}';
    if (signature == _lastPlacedInstancesSignature) {
      return;
    }
    _lastPlacedInstancesSignature = signature;
    if (scope.instances.isEmpty) {
      debugPrint('[editor][elements] no placed instances for layer=$layerId');
      return;
    }
    debugPrint(
      '[editor][elements] loaded placed instances count=${scope.instances.length} layer=$layerId',
    );
  }

  List<Widget> _buildCategoryRows({
    required Map<String?, List<ProjectElementCategory>> categoriesByParent,
    required String? parentCategoryId,
    required int depth,
    Color? rowAccent,
  }) {
    final rows = <Widget>[];
    final children = categoriesByParent[parentCategoryId] ?? const [];
    for (final category in children) {
      final grandChildren = categoriesByParent[category.id] ?? const [];
      final hasChildren = grandChildren.isNotEmpty;
      final expanded = _expandedCategories.contains(category.id);

      rows.add(
        _CategoryTreeRow(
          depth: depth,
          selected: _selectedCategoryId == category.id,
          label: category.name,
          hasChildren: hasChildren,
          expanded: expanded,
          accentOverride: rowAccent,
          onTap: () {
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
          onToggleExpanded: hasChildren
              ? () {
                  setState(() {
                    if (expanded) {
                      _expandedCategories.remove(category.id);
                    } else {
                      _expandedCategories.add(category.id);
                    }
                  });
                }
              : null,
        ),
      );
      if (hasChildren && expanded) {
        rows.addAll(
          _buildCategoryRows(
            categoriesByParent: categoriesByParent,
            parentCategoryId: category.id,
            depth: depth + 1,
            rowAccent: rowAccent,
          ),
        );
      }
    }
    return rows;
  }

  List<Widget> _buildTilesetGroupRows({
    required Map<String?, List<TilesetElementGroup>> groupsByParent,
    required String? parentGroupId,
    required String? selectedGroupId,
    required ValueChanged<String> onSelect,
    int depth = 0,
    Color? rowAccent,
  }) {
    final rows = <Widget>[];
    final children = groupsByParent[parentGroupId] ?? const [];
    for (final group in children) {
      final grandChildren = groupsByParent[group.id] ?? const [];
      final hasChildren = grandChildren.isNotEmpty;
      final expanded = _expandedTilesetGroups.contains(group.id);

      rows.add(
        _CategoryTreeRow(
          depth: depth,
          selected: selectedGroupId == group.id,
          label: group.name,
          hasChildren: hasChildren,
          expanded: expanded,
          accentOverride: rowAccent,
          onTap: () => onSelect(group.id),
          onToggleExpanded: hasChildren
              ? () {
                  setState(() {
                    if (expanded) {
                      _expandedTilesetGroups.remove(group.id);
                    } else {
                      _expandedTilesetGroups.add(group.id);
                    }
                  });
                }
              : null,
        ),
      );
      if (hasChildren && expanded) {
        rows.addAll(
          _buildTilesetGroupRows(
            groupsByParent: groupsByParent,
            parentGroupId: group.id,
            selectedGroupId: selectedGroupId,
            onSelect: onSelect,
            depth: depth + 1,
            rowAccent: rowAccent,
          ),
        );
      }
    }
    return rows;
  }

  Set<String> _collectCategoryScope(
    Map<String?, List<ProjectElementCategory>> byParent,
    String rootId,
  ) {
    final scope = <String>{rootId};
    final queue = <String>[rootId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final children = byParent[current] ?? const [];
      for (final child in children) {
        if (scope.add(child.id)) {
          queue.add(child.id);
        }
      }
    }
    return scope;
  }

  String _buildCategoryPathLabel({
    required Map<String, ProjectElementCategory> categoriesById,
    required String categoryId,
  }) {
    final labels = <String>[];
    String? cursor = categoryId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final category = categoriesById[cursor];
      if (category == null) break;
      labels.add(category.name);
      cursor = category.parentCategoryId;
    }
    return labels.reversed.join(' / ');
  }

  String _buildGroupPathLabel(
    Map<String, ProjectMapGroup> groupById,
    String groupId,
  ) {
    final labels = <String>[];
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final group = groupById[cursor];
      if (group == null) break;
      labels.add(group.name);
      cursor = group.parentGroupId;
    }
    return labels.reversed.join(' / ');
  }

  String _buildTilesetGroupPathLabel(
    Map<String, TilesetElementGroup> groupById,
    String groupId,
  ) {
    final labels = <String>[];
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final group = groupById[cursor];
      if (group == null) break;
      labels.add(group.name);
      cursor = group.parentGroupId;
    }
    return labels.reversed.join(' / ');
  }

  Widget _buildSelectionCanvas({
    required ui.Image image,
    required int columns,
    required int rows,
    required int tileWidth,
    required int tileHeight,
    required double displayScale,
    required TilesetSourceRect? selectionRect,
  }) {
    final cellSize = math.max(8.0, tileWidth * displayScale);
    final canvasWidth = columns * cellSize;
    final canvasHeight = rows * cellSize;

    return SingleChildScrollView(
      controller: _selectionHorizontalScrollController,
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _selectionVerticalScrollController,
        primary: false,
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: GestureDetector(
            onPanStart: (details) {
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionStart = pos;
                _selectionEnd = pos;
              });
            },
            onPanUpdate: (details) {
              if (_selectionStart == null) return;
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionEnd = pos;
              });
            },
            onTapUp: (details) {
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionStart = pos;
                _selectionEnd = pos;
              });
            },
            child: CustomPaint(
              painter: _TilesetSelectionPainter(
                image: image,
                columns: columns,
                rows: rows,
                tileWidth: tileWidth,
                tileHeight: tileHeight,
                selection: selectionRect,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String? parentCategoryId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            parentCategoryId == null ? 'New Category' : 'New Subcategory',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
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
    if (!shouldSave) return;
    if (parentCategoryId == null) {
      await notifier.createElementCategory(controller.text.trim());
    } else {
      await notifier.createElementSubcategory(
        parentCategoryId,
        controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _expandedCategories.add(parentCategoryId);
      });
    }
  }

  Future<void> _showRenameCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String categoryId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rename Category',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
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
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.renameElementCategory(categoryId, controller.text.trim());
  }

  Future<void> _showCreateTilesetGroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Tileset Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
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
    if (!shouldSave) return;
    await notifier.createTilesetElementGroup(
      tilesetId,
      controller.text.trim(),
    );
  }

  Future<void> _showCreateTilesetSubgroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
    required String parentGroupId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Tileset Subgroup',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
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
    if (!shouldSave) return;
    await notifier.createTilesetElementSubgroup(
      tilesetId,
      parentGroupId,
      controller.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _expandedTilesetGroups.add(parentGroupId);
    });
  }

  Future<void> _showRenameTilesetGroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
    required String groupId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rename Tileset Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
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
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.renameTilesetElementGroup(
      tilesetId,
      groupId,
      controller.text.trim(),
    );
  }

  Future<void> _showCreateElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ui.Image image,
    required String tilesetId,
    required List<TilesetElementGroup> tilesetGroups,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required String? activeLayerId,
    required List<TileLayer> tileLayers,
  }) async {
    final categories = notifier.getElementCategories();
    if (categories.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Missing Element Category',
        message:
            'Create at least one element category before creating an element.',
      );
      return;
    }
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final nameController = TextEditingController(
      text: 'element_${source.x}_${source.y}',
    );
    final tagsController = TextEditingController();
    var selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null ||
        !categories.any((category) => category.id == selectedCategoryId)) {
      selectedCategoryId = categories.first.id;
    }
    final sortedTilesetGroups = List<TilesetElementGroup>.from(tilesetGroups)
      ..sort((a, b) {
        if (a.parentGroupId == b.parentGroupId) {
          final sortCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortCompare != 0) return sortCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        final parentA = a.parentGroupId ?? '';
        final parentB = b.parentGroupId ?? '';
        final parentCompare = parentA.compareTo(parentB);
        if (parentCompare != 0) return parentCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in sortedTilesetGroups) group.id: group,
    };
    String? selectedTilesetGroupId =
        ref.read(editorNotifierProvider).selectedTilesetElementGroupId;
    if (selectedTilesetGroupId != null &&
        !tilesetGroupById.containsKey(selectedTilesetGroupId)) {
      selectedTilesetGroupId = null;
    }
    String? selectedGroupId = _activeMapGroupId();
    String? selectedLayerId = activeLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }
    var selectedPresetKind = ElementPresetKind.generic;
    ElementCollisionProfile? collisionProfile;
    var collisionPadding = const WarpTriggerPadding();

    final groups = List<ProjectMapGroup>.from(project.groups)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final groupById = <String, ProjectMapGroup>{
      for (final group in groups) group.id: group,
    };

    var shouldSave = false;
    String tilesetGroupRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return _buildTilesetGroupPathLabel(tilesetGroupById, id);
    }

    String scopeRowLabel(String id) {
      if (id.isEmpty) return 'Global';
      return _buildGroupPathLabel(groupById, id);
    }

    String layerRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return tileLayers.firstWhere((l) => l.id == id).name;
    }

    await showMacosEditorTallSheet<void>(
      context: context,
      maxWidth: 440,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => ListView(
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
                    'Create Element',
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Source: ${source.width}x${source.height} at (${source.x}, ${source.y})',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: nameController,
                    autofocus: true,
                    placeholder: 'Name',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Category',
                          items: categories.map((c) => c.id).toList(),
                          labelOf: (id) => _buildCategoryPathLabel(
                            categoriesById: categoriesById,
                            categoryId: id,
                          ),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedCategoryId = picked);
                        }
                      },
                      child: Text(
                        'Category: ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId!)}',
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
                          ...sortedTilesetGroups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Tileset Group',
                          items: items,
                          labelOf: tilesetGroupRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedTilesetGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Tileset Group: ${tilesetGroupRowLabel(selectedTilesetGroupId ?? '')}',
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
                          ...groups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Scope Group',
                          items: items,
                          labelOf: scopeRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Scope Group: ${scopeRowLabel(selectedGroupId ?? '')}',
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
                          ...tileLayers.map((l) => l.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Recommended Layer',
                          items: items,
                          labelOf: layerRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedLayerId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Recommended Layer: ${layerRowLabel(selectedLayerId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: tagsController,
                    placeholder: 'Tags (tree,outdoor,oak)',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked =
                            await showCupertinoListPicker<ElementPresetKind>(
                          context: ctx,
                          title: 'Type prédéfini',
                          items: ElementPresetKind.values,
                          labelOf: _elementPresetLabel,
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedPresetKind = picked);
                        }
                      },
                      child: Text(
                        'Type: ${_elementPresetLabel(selectedPresetKind)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileSummaryCard(
                    source: source,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onOpenEditor: () async {
                      final edited = await showElementCollisionEditorSheet(
                        context: ctx,
                        elementName: nameController.text.trim().isEmpty
                            ? 'Nouvel élément'
                            : nameController.text.trim(),
                        image: image,
                        source: source,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        initialProfile: collisionProfile,
                        fallbackPadding: collisionPadding,
                      );
                      if (edited == null) {
                        return;
                      }
                      setStateDialog(() {
                        collisionProfile = edited;
                        collisionPadding = edited.padding;
                      });
                    },
                    onClearProfile: () {
                      setStateDialog(() {
                        collisionProfile = null;
                        collisionPadding = const WarpTriggerPadding();
                      });
                    },
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
                          if (nameController.text.trim().isEmpty) {
                            await showCupertinoEditorAlert(
                              ctx,
                              message: 'Name is required.',
                            );
                            return;
                          }
                          shouldSave = true;
                          Navigator.pop(ctx);
                        },
                        child: const Text('Create'),
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

    if (!shouldSave || selectedCategoryId == null) return;
    await notifier.createProjectElement(
      name: nameController.text.trim(),
      tilesetId: tilesetId,
      categoryId: selectedCategoryId!,
      tilesetGroupId: selectedTilesetGroupId,
      source: source,
      presetKind: selectedPresetKind,
      collisionProfile: collisionProfile,
      groupId: selectedGroupId,
      recommendedLayerId: selectedLayerId,
      tags: _parseTags(tagsController.text),
    );
    notifier.selectTool(EditorToolType.tilePaint);
    if (!mounted) return;
    setState(() {
      _creationMode = false;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  Future<void> _showEditElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ui.Image image,
    required ProjectElementEntry element,
    required List<ProjectElementCategory> categories,
    required int tileWidth,
    required int tileHeight,
    required List<TileLayer> tileLayers,
    required List<TilesetElementGroup> tilesetGroups,
  }) async {
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final sortedTilesetGroups = List<TilesetElementGroup>.from(tilesetGroups)
      ..sort((a, b) {
        if (a.parentGroupId == b.parentGroupId) {
          final sortCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortCompare != 0) return sortCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        final parentA = a.parentGroupId ?? '';
        final parentB = b.parentGroupId ?? '';
        final parentCompare = parentA.compareTo(parentB);
        if (parentCompare != 0) return parentCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in sortedTilesetGroups) group.id: group,
    };
    final groups = List<ProjectMapGroup>.from(project.groups)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final groupById = <String, ProjectMapGroup>{
      for (final group in groups) group.id: group,
    };

    final nameController = TextEditingController(text: element.name);
    final tagsController = TextEditingController(text: element.tags.join(','));
    String selectedCategoryId = element.categoryId;
    String? selectedTilesetGroupId = element.tilesetGroupId;
    if (selectedTilesetGroupId != null &&
        !tilesetGroupById.containsKey(selectedTilesetGroupId)) {
      selectedTilesetGroupId = null;
    }
    String? selectedGroupId = element.groupId;
    String? selectedLayerId = element.recommendedLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }
    var selectedPresetKind = element.presetKind;
    ElementCollisionProfile? collisionProfile = element.collisionProfile;
    ProjectElementShadowConfig? shadowConfig = element.shadow;
    var shadowManifest = project;
    var collisionPadding =
        collisionProfile?.padding ?? const WarpTriggerPadding();
    var frames = List<TilesetVisualFrame>.from(element.frames);
    var shouldSave = false;

    String editTilesetGroupRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return _buildTilesetGroupPathLabel(tilesetGroupById, id);
    }

    String editScopeRowLabel(String id) {
      if (id.isEmpty) return 'Global';
      return _buildGroupPathLabel(groupById, id);
    }

    String editLayerRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return tileLayers.firstWhere((l) => l.id == id).name;
    }

    await showMacosEditorTallSheet<void>(
      context: context,
      maxWidth: 440,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => ListView(
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
                    'Edit Element',
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 12),
                  _ElementFramesEditor(
                    image: image,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    ownerTilesetId: element.tilesetId,
                    frames: frames,
                    onChanged: (next) {
                      setStateDialog(() {
                        frames = next;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: nameController,
                    placeholder: 'Name',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Category',
                          items: categories.map((c) => c.id).toList(),
                          labelOf: (id) => _buildCategoryPathLabel(
                            categoriesById: categoriesById,
                            categoryId: id,
                          ),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedCategoryId = picked);
                        }
                      },
                      child: Text(
                        'Category: ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId)}',
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
                          ...sortedTilesetGroups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Tileset Group',
                          items: items,
                          labelOf: editTilesetGroupRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedTilesetGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Tileset Group: ${editTilesetGroupRowLabel(selectedTilesetGroupId ?? '')}',
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
                          ...groups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Scope Group',
                          items: items,
                          labelOf: editScopeRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Scope Group: ${editScopeRowLabel(selectedGroupId ?? '')}',
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
                          ...tileLayers.map((l) => l.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Recommended Layer',
                          items: items,
                          labelOf: editLayerRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedLayerId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Recommended Layer: ${editLayerRowLabel(selectedLayerId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: tagsController,
                    placeholder: 'Tags (tree,outdoor,oak)',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked =
                            await showCupertinoListPicker<ElementPresetKind>(
                          context: ctx,
                          title: 'Type prédéfini',
                          items: ElementPresetKind.values,
                          labelOf: _elementPresetLabel,
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedPresetKind = picked);
                        }
                      },
                      child: Text(
                        'Type: ${_elementPresetLabel(selectedPresetKind)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElementShadowSection(
                    manifest: shadowManifest,
                    element: element,
                    shadow: shadowConfig,
                    onChanged: (next) {
                      setStateDialog(() {
                        shadowConfig = next;
                      });
                    },
                    onEnsureDefaultShadowProfiles: () {
                      final updated = notifier.ensureDefaultShadowProfiles();
                      if (updated == null) return;
                      setStateDialog(() {
                        shadowManifest = updated;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileSummaryCard(
                    source: frames.primarySource,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onOpenEditor: () async {
                      final edited = await showElementCollisionEditorSheet(
                        context: ctx,
                        elementName: nameController.text.trim().isEmpty
                            ? element.name
                            : nameController.text.trim(),
                        image: image,
                        source: frames.primarySource,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        initialProfile: collisionProfile,
                        fallbackPadding: collisionPadding,
                      );
                      if (edited == null) {
                        return;
                      }
                      setStateDialog(() {
                        collisionProfile = edited;
                        collisionPadding = edited.padding;
                      });
                    },
                    onClearProfile: () {
                      setStateDialog(() {
                        collisionProfile = null;
                        collisionPadding = const WarpTriggerPadding();
                      });
                    },
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
                          if (nameController.text.trim().isEmpty) {
                            await showCupertinoEditorAlert(
                              ctx,
                              message: 'Name is required.',
                            );
                            return;
                          }
                          shouldSave = true;
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
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

    if (!shouldSave) return;
    await notifier.updateProjectElement(
      elementId: element.id,
      name: nameController.text.trim(),
      presetKind: selectedPresetKind,
      collisionProfile: collisionProfile,
      clearCollisionProfile: collisionProfile == null,
      categoryId: selectedCategoryId,
      tilesetGroupId: selectedTilesetGroupId,
      clearTilesetGroupId: selectedTilesetGroupId == null,
      groupId: selectedGroupId,
      clearGroupId: selectedGroupId == null,
      recommendedLayerId: selectedLayerId,
      clearRecommendedLayerId: selectedLayerId == null,
      shadow: shadowConfig,
      clearShadow: shadowConfig == null,
      frames: frames,
      tags: _parseTags(tagsController.text),
    );
  }

  Future<void> _showDeleteElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectElementEntry element,
  }) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete Element',
      message: 'Delete "${element.name}"?',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    await notifier.deleteProjectElement(element.id);
  }

  Future<void> _showApplyElementAutoShadowsDialog(
    BuildContext context, {
    required EditorNotifier notifier,
  }) async {
    final shouldApply = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Appliquer les ombres automatiques aux éléments ?',
      message:
          'Les éléments sans ombre ou avec une ancienne ombre générique recevront une empreinte automatique. Les ombres manuelles et désactivées seront conservées.',
      primaryLabel: 'Appliquer',
    );
    if (!shouldApply) return;
    await notifier.applyElementAutoShadowSuggestions();
  }

  Future<void> _showDeletePlacedInstanceDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required _PlacedElementInstanceVm instance,
  }) async {
    final elementName = instance.element?.name ?? instance.instance.elementId;
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer l’instance',
      message:
          'Supprimer "$elementName" en (${instance.pos.x}, ${instance.pos.y}) sur "${instance.layerName}" ?',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }
    notifier.deletePlacedElementInstance(instanceId: instance.instanceId);
  }

  List<String> _parseTags(String value) {
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _activeMapGroupId() {
    final project = ref.read(editorNotifierProvider).project;
    final map = ref.read(editorNotifierProvider).activeMap;
    if (project == null || map == null) return null;
    for (final entry in project.maps) {
      if (entry.id == map.id) {
        return entry.groupId;
      }
    }
    return null;
  }

  String _legacyCategoryLabel(PaletteCategory category) {
    switch (category) {
      case PaletteCategory.floors:
        return 'Sols';
      case PaletteCategory.paths:
        return 'Chemins';
      case PaletteCategory.water:
        return 'Eau';
      case PaletteCategory.buildings:
        return 'Batiments';
      case PaletteCategory.roofs:
        return 'Toits';
      case PaletteCategory.plants:
        return 'Plantes';
      case PaletteCategory.trees:
        return 'Arbres';
      case PaletteCategory.cliffs:
        return 'Falaises';
      case PaletteCategory.decorations:
        return 'Decorations';
      case PaletteCategory.interiors:
        return 'Interieurs';
      case PaletteCategory.objects:
        return 'Objets';
      case PaletteCategory.uncategorized:
        return 'Non classes';
    }
  }
}

class _PlacedElementBehaviorsSection extends StatefulWidget {
  const _PlacedElementBehaviorsSection({
    required this.value,
    required this.dialogues,
    required this.projectRootPath,
    required this.onChanged,
  });

  final List<MapPlacedElementBehavior> value;
  final List<ProjectDialogueEntry> dialogues;
  final String? projectRootPath;
  final ValueChanged<List<MapPlacedElementBehavior>> onChanged;

  @override
  State<_PlacedElementBehaviorsSection> createState() =>
      _PlacedElementBehaviorsSectionState();
}

class _PlacedElementBehaviorsSectionState
    extends State<_PlacedElementBehaviorsSection> {
  static const String _dialogueNoneMenuId = '__placed_behavior_dialogue_none__';
  static const String _nodeNoneMenuId = '__placed_behavior_node_none__';
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  int _selectedIndex = 0;
  String _messageDraft = '';
  Timer? _messageCommitDebounce;
  List<String> _dialogueNodes = const <String>[];
  bool _dialogueNodesLoading = false;
  int _dialogueNodesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _syncFromWidget(force: true);
    Future.microtask(_reloadDialogueNodesForSelected);
  }

  @override
  void didUpdateWidget(covariant _PlacedElementBehaviorsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromWidget();
    final dialoguesChanged = !listEquals(oldWidget.dialogues, widget.dialogues);
    final rootChanged = oldWidget.projectRootPath != widget.projectRootPath;
    final valueChanged = !listEquals(oldWidget.value, widget.value);
    if (dialoguesChanged || rootChanged || valueChanged) {
      Future.microtask(_reloadDialogueNodesForSelected);
    }
  }

  @override
  void dispose() {
    _messageCommitDebounce?.cancel();
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      return;
    }
    _commitMessageDraft();
  }

  void _syncFromWidget({bool force = false}) {
    if (widget.value.isEmpty) {
      _selectedIndex = 0;
      _setMessageDraft('', force: force);
      return;
    }
    if (_selectedIndex >= widget.value.length) {
      _selectedIndex = widget.value.length - 1;
    }
    _applyDraftsFromBehavior(widget.value[_selectedIndex], force: force);
  }

  void _applyDraftsFromBehavior(
    MapPlacedElementBehavior behavior, {
    bool force = false,
  }) {
    _setMessageDraft(behavior.effect.message ?? '', force: force);
  }

  void _setMessageDraft(String value, {bool force = false}) {
    final canApply = force || !_messageFocusNode.hasFocus;
    if (!canApply) {
      return;
    }
    if (_messageDraft == value && _messageController.text == value) {
      return;
    }
    _messageDraft = value;
    _messageController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _scheduleMessageCommit() {
    _messageCommitDebounce?.cancel();
    _messageCommitDebounce = Timer(const Duration(milliseconds: 220), () {
      _commitMessageDraft();
    });
  }

  void _commitDrafts() {
    _commitMessageDraft();
  }

  void _commitMessageDraft() {
    _messageCommitDebounce?.cancel();
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.showMessage) {
      return;
    }
    final normalized = _messageDraft.trim().isEmpty ? null : _messageDraft;
    if (selected.effect.message == normalized) {
      return;
    }
    _replaceSelectedBehavior(
      selected.copyWith(
        effect: selected.effect.copyWith(message: normalized),
      ),
    );
  }

  MapPlacedElementBehavior _defaultBehavior() {
    return const MapPlacedElementBehavior(
      enabled: true,
      trigger: MapPlacedElementTriggerType.onAction,
      effect: MapPlacedElementEffect(
        type: MapPlacedElementEffectType.showMessage,
        message: '...',
      ),
    );
  }

  void _emit(List<MapPlacedElementBehavior> next) {
    widget.onChanged(next);
  }

  void _addBehavior() {
    _commitDrafts();
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    )..add(_defaultBehavior());
    _selectedIndex = next.length - 1;
    _emit(next);
  }

  void _removeSelectedBehavior() {
    if (widget.value.isEmpty) {
      return;
    }
    _commitDrafts();
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    );
    next.removeAt(_selectedIndex);
    if (_selectedIndex >= next.length) {
      _selectedIndex = next.isEmpty ? 0 : next.length - 1;
    }
    _emit(next);
  }

  void _replaceSelectedBehavior(MapPlacedElementBehavior behavior) {
    if (widget.value.isEmpty) {
      return;
    }
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    );
    next[_selectedIndex] = behavior;
    _emit(next);
  }

  void _updateSelected(MapPlacedElementBehavior behavior) {
    _replaceSelectedBehavior(behavior);
  }

  int _defaultExplicitCooldownMs(MapPlacedElementEffectType effectType) {
    switch (effectType) {
      case MapPlacedElementEffectType.showMessage:
        return 650;
      case MapPlacedElementEffectType.openDialogue:
        return 900;
      case MapPlacedElementEffectType.setAnimationEnabled:
        return 0;
      case MapPlacedElementEffectType.playAnimationOnce:
        return 180;
    }
  }

  List<MapPlacedElementTriggerScope> _allowedScopesForTrigger(
    MapPlacedElementTriggerType trigger,
  ) {
    switch (trigger) {
      case MapPlacedElementTriggerType.onAction:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.facingOnly,
        ];
      case MapPlacedElementTriggerType.onEnter:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.oncePerEnter,
          MapPlacedElementTriggerScope.whileInsideSingleShot,
        ];
      case MapPlacedElementTriggerType.onNear:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.whileInsideSingleShot,
          MapPlacedElementTriggerScope.facingOnly,
          MapPlacedElementTriggerScope.nearCardinalOnly,
        ];
      case MapPlacedElementTriggerType.onBump:
      case MapPlacedElementTriggerType.onExit:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
        ];
    }
  }

  String _scopeLabel(MapPlacedElementTriggerScope scope) {
    switch (scope) {
      case MapPlacedElementTriggerScope.defaultScope:
        return 'Par défaut';
      case MapPlacedElementTriggerScope.oncePerEnter:
        return 'Une fois/entrée';
      case MapPlacedElementTriggerScope.whileInsideSingleShot:
        return 'Zone unique';
      case MapPlacedElementTriggerScope.facingOnly:
        return 'Regard uniquement';
      case MapPlacedElementTriggerScope.nearCardinalOnly:
        return 'Proche N/S/E/O';
    }
  }

  MapPlacedElementBehavior? get _selectedBehavior {
    if (widget.value.isEmpty) {
      return null;
    }
    if (_selectedIndex < 0 || _selectedIndex >= widget.value.length) {
      return null;
    }
    return widget.value[_selectedIndex];
  }

  List<ProjectDialogueEntry> _sortedDialogues() {
    final sorted = List<ProjectDialogueEntry>.of(widget.dialogues);
    sorted.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  String _normalizeDialogueRelativePath(String raw) {
    return raw.trim().replaceAll(r'\', '/');
  }

  String? _resolveDialogueFilePath(String dialogueId) {
    final root = widget.projectRootPath;
    if (root == null || root.trim().isEmpty) {
      return null;
    }
    final normalizedId = dialogueId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }
    final matches = widget.dialogues.where((e) => e.id == normalizedId);
    if (matches.isEmpty) {
      return null;
    }
    final rel = _normalizeDialogueRelativePath(matches.first.relativePath);
    if (rel.isEmpty) {
      return null;
    }
    return '$root/$rel';
  }

  Future<List<String>> _extractYarnNodeTitles(String absolutePath) async {
    try {
      final file = File(absolutePath);
      if (!await file.exists()) {
        return const <String>[];
      }
      final lines = await file.readAsLines();
      return [
        for (final line in lines)
          if (line.trim().startsWith('title:'))
            line.trim().substring('title:'.length).trim(),
      ].where((title) => title.isNotEmpty).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _reloadDialogueNodesForSelected() async {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      if (mounted) {
        setState(() {
          _dialogueNodesLoading = false;
          _dialogueNodes = const <String>[];
        });
      }
      return;
    }
    final dialogueId = selected.effect.dialogue?.dialogueId.trim() ?? '';
    final path = _resolveDialogueFilePath(dialogueId);
    if (path == null) {
      if (mounted) {
        setState(() {
          _dialogueNodesLoading = false;
          _dialogueNodes = const <String>[];
        });
      }
      return;
    }
    final requestId = ++_dialogueNodesRequestId;
    if (mounted) {
      setState(() {
        _dialogueNodesLoading = true;
      });
    }
    final nodes = await _extractYarnNodeTitles(path);
    if (!mounted || requestId != _dialogueNodesRequestId) {
      return;
    }
    setState(() {
      _dialogueNodesLoading = false;
      _dialogueNodes = nodes;
    });
  }

  Future<String?> _showDialoguePicker({
    required BuildContext context,
    required List<ProjectDialogueEntry> sorted,
    required String selectedDialogueId,
  }) async {
    final searchController = TextEditingController();
    var query = '';
    try {
      return await showMacosSheet<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final q = query.trim().toLowerCase();
              final filtered = sorted.where((entry) {
                if (q.isEmpty) {
                  return true;
                }
                final haystack =
                    '${entry.name} ${entry.id} ${entry.relativePath}'
                        .toLowerCase();
                return haystack.contains(q);
              }).toList(growable: false);
              final selectedMissing = selectedDialogueId.isNotEmpty &&
                  !sorted.any((entry) => entry.id == selectedDialogueId);
              return Center(
                child: MacosSheet(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 72,
                    vertical: 44,
                  ),
                  child: SizedBox(
                    width: 520,
                    height: MediaQuery.sizeOf(ctx).height * 0.62,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Choisir un script Yarn',
                            textAlign: TextAlign.center,
                            style: editorMacosSheetTitleStyle(ctx),
                          ),
                          const SizedBox(height: 10),
                          CupertinoTextField(
                            controller: searchController,
                            placeholder: 'Rechercher (nom, id, chemin)…',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                query = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: 1 +
                                  (selectedMissing ? 1 : 0) +
                                  filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (c, i) {
                                if (i == 0) {
                                  return PushButton(
                                    controlSize: ControlSize.large,
                                    secondary: true,
                                    onPressed: () => Navigator.of(c).pop(
                                      _dialogueNoneMenuId,
                                    ),
                                    child: const Text('Aucun dialogue'),
                                  );
                                }
                                final offset = i - 1;
                                if (selectedMissing && offset == 0) {
                                  return PushButton(
                                    controlSize: ControlSize.large,
                                    secondary: true,
                                    onPressed: () => Navigator.of(c).pop(
                                      selectedDialogueId,
                                    ),
                                    child: Text(
                                      '$selectedDialogueId (absent du projet)',
                                    ),
                                  );
                                }
                                final index =
                                    offset - (selectedMissing ? 1 : 0);
                                final entry = filtered[index];
                                return PushButton(
                                  controlSize: ControlSize.large,
                                  secondary: true,
                                  onPressed: () =>
                                      Navigator.of(c).pop(entry.id),
                                  child: Text(
                                    '${entry.name} · ${entry.relativePath}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          PushButton(
                            controlSize: ControlSize.large,
                            secondary: true,
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      searchController.dispose();
    }
  }

  void _updateSelectedDialogue(String dialogueId) {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      return;
    }
    final normalizedId = dialogueId.trim();
    final currentDialogue = selected.effect.dialogue;
    if (currentDialogue?.dialogueId == normalizedId) {
      return;
    }
    final nextDialogue = DialogueRef(
      dialogueId: normalizedId,
      scriptPathRelative: currentDialogue?.scriptPathRelative ?? '',
      startNode: null,
    );
    _updateSelected(
      selected.copyWith(
        effect: selected.effect.copyWith(dialogue: nextDialogue),
      ),
    );
  }

  void _updateSelectedDialogueNode(String? nodeId) {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      return;
    }
    final currentDialogue = selected.effect.dialogue;
    if (currentDialogue == null) {
      return;
    }
    final normalizedNode =
        (nodeId == null || nodeId.trim().isEmpty) ? null : nodeId.trim();
    if (currentDialogue.startNode == normalizedNode) {
      return;
    }
    _updateSelected(
      selected.copyWith(
        effect: selected.effect.copyWith(
          dialogue: currentDialogue.copyWith(startNode: normalizedNode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final selected = _selectedBehavior;
    const maxBehaviorCooldownMs = 600000;
    final allowedScopes = selected == null
        ? const <MapPlacedElementTriggerScope>[]
        : _allowedScopesForTrigger(selected.trigger);
    final selectedScope = selected == null
        ? MapPlacedElementTriggerScope.defaultScope
        : allowedScopes.contains(selected.triggerScope)
            ? selected.triggerScope
            : MapPlacedElementTriggerScope.defaultScope;

    String triggerHelp(MapPlacedElementTriggerType trigger) {
      switch (trigger) {
        case MapPlacedElementTriggerType.onAction:
          return 'Action: déclenché avec la touche d’action face à l’élément.';
        case MapPlacedElementTriggerType.onEnter:
          return 'Entrée: déclenché quand le joueur marche sur l’élément.';
        case MapPlacedElementTriggerType.onBump:
          return 'Contact: déclenché quand le joueur se cogne contre l’élément.';
        case MapPlacedElementTriggerType.onExit:
          return 'Sortie: déclenché quand le joueur quitte la zone couverte.';
        case MapPlacedElementTriggerType.onNear:
          return 'Proximité: déclenché quand le joueur devient adjacent (4 directions).';
      }
    }

    String scopeHelp(MapPlacedElementTriggerScope scope) {
      switch (scope) {
        case MapPlacedElementTriggerScope.defaultScope:
          return 'Default: comportement actuel sans filtre supplémentaire.';
        case MapPlacedElementTriggerScope.oncePerEnter:
          return 'Once per enter: déclenche une fois à l’entrée, puis réarme après sortie.';
        case MapPlacedElementTriggerScope.whileInsideSingleShot:
          return 'Single-shot: un déclenchement tant que le joueur reste dans la zone, puis réarmement après sortie.';
        case MapPlacedElementTriggerScope.facingOnly:
          return 'Facing only: déclenche seulement si le joueur regarde l’élément.';
        case MapPlacedElementTriggerScope.nearCardinalOnly:
          return 'Near cardinal: proximité limitée à N/S/E/W (pas de diagonales).';
      }
    }

    String effectHelp(MapPlacedElementEffectType effectType) {
      switch (effectType) {
        case MapPlacedElementEffectType.showMessage:
          return 'Message: affiche un texte court dans le HUD runtime.';
        case MapPlacedElementEffectType.openDialogue:
          return 'Dialogue: choisis un script Yarn, puis un nœud de départ.';
        case MapPlacedElementEffectType.setAnimationEnabled:
          return 'Animation on/off: active ou coupe l’animation locale de cette instance.';
        case MapPlacedElementEffectType.playAnimationOnce:
          return 'Animation 1x: joue une séquence une fois puis revient à l’état normal.';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comportements',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                onPressed: _addBehavior,
                child: const Text(
                  'Ajouter',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                onPressed:
                    widget.value.isEmpty ? null : _removeSelectedBehavior,
                child: const Text(
                  'Supprimer',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Décor enrichi local: utilise cette section pour des réactions simples. Pour un vrai acteur gameplay (PNJ, panneau, item), utilise une MapEntity.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          if (widget.value.isEmpty) ...[
            Text(
              'Aucun comportement configuré.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoute un comportement pour définir déclencheur + effet.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.value.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final behavior = widget.value[index];
                  final selectedChip = index == _selectedIndex;
                  return CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    color: selectedChip
                        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.3)
                        : EditorPaintColors.white12,
                    onPressed: () {
                      _commitDrafts();
                      setState(() {
                        _selectedIndex = index;
                        _applyDraftsFromBehavior(behavior, force: true);
                      });
                      Future.microtask(_reloadDialogueNodesForSelected);
                    },
                    child: Text(
                      '${index + 1}. ${behavior.trigger.name} → ${behavior.effect.type.name}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: 8),
              _CompactSwitchRow(
                title: 'Activé',
                value: selected.enabled,
                onChanged: (next) =>
                    _updateSelected(selected.copyWith(enabled: next)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Déclencheur',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<
                        MapPlacedElementTriggerType>(
                      groupValue: selected.trigger,
                      children: const {
                        MapPlacedElementTriggerType.onAction: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Action', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onEnter: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Entrée', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onBump: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Contact', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onExit: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Sortie', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onNear: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Proche', style: TextStyle(fontSize: 10)),
                        ),
                      },
                      onValueChanged: (next) {
                        if (next == null) {
                          return;
                        }
                        _commitDrafts();
                        final allowedScopesForNext =
                            _allowedScopesForTrigger(next);
                        final nextScope =
                            allowedScopesForNext.contains(selected.triggerScope)
                                ? selected.triggerScope
                                : MapPlacedElementTriggerScope.defaultScope;
                        _updateSelected(
                          selected.copyWith(
                            trigger: next,
                            triggerScope: nextScope,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                triggerHelp(selected.trigger),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Scope',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<MapPlacedElementTriggerScope>(
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        offset: const Offset(0, 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: EditorChrome.inspectorJoyBlue
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        color: EditorChrome.islandFillElevated(context),
                        elevation: 3,
                        initialValue: selectedScope,
                        onSelected: (nextScope) {
                          _commitDrafts();
                          _updateSelected(
                            selected.copyWith(triggerScope: nextScope),
                          );
                        },
                        itemBuilder: (menuCtx) => [
                          for (final scope in allowedScopes)
                            PopupMenuItem<MapPlacedElementTriggerScope>(
                              value: scope,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: scope == selectedScope
                                        ? const Icon(
                                            CupertinoIcons.checkmark,
                                            size: 14,
                                            color:
                                                EditorChrome.inspectorJoyBlue,
                                          )
                                        : null,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _scopeLabel(scope),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: scope == selectedScope
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: label,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _scopeLabel(selectedScope),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: label,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                size: 12,
                                color: secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                scopeHelp(selectedScope),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Effet',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<
                        MapPlacedElementEffectType>(
                      groupValue: selected.effect.type,
                      children: const {
                        MapPlacedElementEffectType.showMessage: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Message', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.openDialogue: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Dialogue', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.setAnimationEnabled: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Anim ON/OFF',
                              style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.playAnimationOnce: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Anim 1x', style: TextStyle(fontSize: 10)),
                        ),
                      },
                      onValueChanged: (next) {
                        if (next == null) {
                          return;
                        }
                        _commitDrafts();
                        final effect = switch (next) {
                          MapPlacedElementEffectType.showMessage =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType.showMessage,
                              message: '...',
                            ),
                          MapPlacedElementEffectType.openDialogue =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType.openDialogue,
                              dialogue: DialogueRef(dialogueId: ''),
                            ),
                          MapPlacedElementEffectType.setAnimationEnabled =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType
                                  .setAnimationEnabled,
                              animationEnabled: true,
                            ),
                          MapPlacedElementEffectType.playAnimationOnce =>
                            const MapPlacedElementEffect(
                              type:
                                  MapPlacedElementEffectType.playAnimationOnce,
                            ),
                        };
                        _updateSelected(selected.copyWith(effect: effect));
                        Future.microtask(_reloadDialogueNodesForSelected);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                effectHelp(selected.effect.type),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              _CompactSwitchRow(
                title: 'Cooldown explicite',
                value: selected.cooldownMs != null,
                onChanged: (next) {
                  if (!next) {
                    _updateSelected(selected.copyWith(cooldownMs: null));
                    return;
                  }
                  _updateSelected(
                    selected.copyWith(
                      cooldownMs:
                          _defaultExplicitCooldownMs(selected.effect.type),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                selected.cooldownMs == null
                    ? 'Utilise la valeur par défaut du runtime pour cet effet.'
                    : 'Valeur forcée pour ce behavior. Le runtime ignore sa valeur par défaut.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              if (selected.cooldownMs != null) ...[
                const SizedBox(height: 6),
                _CompactStepperRow(
                  label: 'Cooldown',
                  value: '${selected.cooldownMs} ms',
                  onMinus: () {
                    final current = selected.cooldownMs ?? 0;
                    final next = math.max(0, current - 50);
                    _updateSelected(selected.copyWith(cooldownMs: next));
                  },
                  onPlus: () {
                    final current = selected.cooldownMs ?? 0;
                    final next = math.min(maxBehaviorCooldownMs, current + 50);
                    _updateSelected(selected.copyWith(cooldownMs: next));
                  },
                  onReset: () =>
                      _updateSelected(selected.copyWith(cooldownMs: null)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in const [250, 500, 1000])
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        color: selected.cooldownMs == preset
                            ? EditorChrome.inspectorJoyBlue
                                .withValues(alpha: 0.25)
                            : EditorPaintColors.white12,
                        onPressed: () => _updateSelected(
                            selected.copyWith(cooldownMs: preset)),
                        child: Text(
                          '${preset}ms',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
              if (selected.effect.type ==
                  MapPlacedElementEffectType.showMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: CupertinoTextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    placeholder: 'Message…',
                    style: TextStyle(color: label, fontSize: 11),
                    placeholderStyle: TextStyle(color: secondary, fontSize: 11),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    onChanged: (text) {
                      _messageDraft = text;
                      _scheduleMessageCommit();
                    },
                    onSubmitted: (_) => _commitMessageDraft(),
                    onEditingComplete: _commitMessageDraft,
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.openDialogue)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Builder(
                    builder: (context) {
                      final sortedDialogues = _sortedDialogues();
                      final selectedDialogueId =
                          selected.effect.dialogue?.dialogueId.trim() ?? '';
                      ProjectDialogueEntry? selectedDialogue;
                      for (final entry in sortedDialogues) {
                        if (entry.id == selectedDialogueId) {
                          selectedDialogue = entry;
                          break;
                        }
                      }
                      final selectedDialogueLabel = selectedDialogueId.isEmpty
                          ? 'Aucun dialogue'
                          : selectedDialogue != null
                              ? '${selectedDialogue.name} · ${selectedDialogue.relativePath}'
                              : '$selectedDialogueId (absent du projet)';
                      final currentNode =
                          selected.effect.dialogue?.startNode?.trim() ?? '';
                      final nodeMenuIds = <String>[
                        _nodeNoneMenuId,
                        ..._dialogueNodes,
                      ];
                      if (currentNode.isNotEmpty &&
                          !nodeMenuIds.contains(currentNode)) {
                        nodeMenuIds.add(currentNode);
                      }
                      final selectedNodeMenu =
                          currentNode.isEmpty ? _nodeNoneMenuId : currentNode;
                      String nodeLabel(String id) {
                        if (id == _nodeNoneMenuId) {
                          return 'Nœud par défaut';
                        }
                        return id;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final picked = await _showDialoguePicker(
                                context: context,
                                sorted: sortedDialogues,
                                selectedDialogueId: selectedDialogueId,
                              );
                              if (picked == null) {
                                return;
                              }
                              if (picked == _dialogueNoneMenuId) {
                                _updateSelectedDialogue('');
                              } else {
                                _updateSelectedDialogue(picked);
                              }
                              await _reloadDialogueNodesForSelected();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: EditorChrome.largeIslandSurfaceColor(
                                  context,
                                  tint: EditorChrome.inspectorJoyLilac
                                      .withValues(alpha: 0.08),
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: EditorChrome.inspectorJoyLilac
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Script Yarn',
                                          style: TextStyle(
                                            color: secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedDialogueLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 12,
                                    color: secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Material(
                            color: Colors.transparent,
                            child: PopupMenuButton<String>(
                              enabled: selectedDialogueId.isNotEmpty,
                              tooltip: 'Choisir un nœud Yarn',
                              padding: EdgeInsets.zero,
                              splashRadius: 20,
                              offset: const Offset(0, 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: EditorChrome.inspectorJoyBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              color: EditorChrome.islandFillElevated(context),
                              elevation: 3,
                              initialValue: selectedNodeMenu,
                              onSelected: (picked) {
                                if (picked == _nodeNoneMenuId) {
                                  _updateSelectedDialogueNode(null);
                                } else {
                                  _updateSelectedDialogueNode(picked);
                                }
                              },
                              itemBuilder: (menuCtx) => [
                                for (final id in nodeMenuIds)
                                  PopupMenuItem<String>(
                                    value: id,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          child: id == selectedNodeMenu
                                              ? const Icon(
                                                  CupertinoIcons.checkmark,
                                                  size: 14,
                                                  color: EditorChrome
                                                      .inspectorJoyBlue,
                                                )
                                              : null,
                                        ),
                                        Expanded(
                                          child: Text(
                                            nodeLabel(id),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: id == selectedNodeMenu
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: label,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: EditorChrome.largeIslandSurfaceColor(
                                    context,
                                    tint: EditorChrome.inspectorJoyBlue
                                        .withValues(alpha: 0.08),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: EditorChrome.inspectorJoyBlue
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nœud Yarn',
                                            style: TextStyle(
                                              color: secondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            nodeLabel(selectedNodeMenu),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selectedDialogueId.isEmpty
                                                  ? secondary
                                                  : label,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 12,
                                      color: secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (selectedDialogueId.isEmpty)
                            Text(
                              'Choisis un script pour activer la sélection du nœud.',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            )
                          else if (_dialogueNodesLoading)
                            Text(
                              'Chargement des nœuds Yarn…',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            )
                          else if (_dialogueNodes.isEmpty)
                            Text(
                              'Aucun nœud détecté dans ce script (ou fichier introuvable).',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.setAnimationEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _CompactSwitchRow(
                    title: 'Animation activée',
                    value: selected.effect.animationEnabled ?? true,
                    onChanged: (next) {
                      _updateSelected(
                        selected.copyWith(
                          effect:
                              selected.effect.copyWith(animationEnabled: next),
                        ),
                      );
                    },
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.playAnimationOnce)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Animation 1x: déclenche une lecture unique puis restaure l’animation locale normale.',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
  final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) {
    return frameTilesetId;
  }
  return entry.tilesetId.trim();
}
