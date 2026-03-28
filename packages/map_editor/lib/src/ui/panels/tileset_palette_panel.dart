import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';

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
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final settings = project?.settings ?? const ProjectSettings();

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

    final selectedTileset = notifier.getSelectedTilesetEntry();
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
      builder: (context, snapshot) {
        final image = snapshot.data;
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
                state: state,
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
    required EditorState state,
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

    final filter = state.paletteCategoryFilter;
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

    final selectedTileId = state.activeBrush.maybeMap(
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
                          activeLayerId: state.activeLayerId,
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
                                      recommendedLayerId: state.activeLayerId,
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
    required EditorState state,
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
    final selectedTilesetGroupId = state.selectedTilesetElementGroupId;
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

    final panelMode = state.tilesElementsPanelMode;
    final placedInstancesScope = _resolvePlacedElementInstances(
      state: state,
      activeTileset: activeTileset,
      project: project,
      tilesetColumns: columns,
    );
    final selectedPlacedInstance = _findPlacedElementInstanceById(
      instances: placedInstancesScope.instances,
      instanceId: state.selectedPlacedElementInstanceId,
    );

    if (panelMode == TilesElementsPanelMode.placedInstances) {
      _logPlacedInstancesSnapshot(placedInstancesScope);
      if (state.selectedPlacedElementInstanceId != null &&
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
                Icon(
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
            ColoredBox(
              color: tilesAccent,
              child: const SizedBox(width: 3),
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
                Icon(
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
            ColoredBox(
              color: categoryStripe,
              child: const SizedBox(width: 3),
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
                Icon(
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
                      selected: state.activeBrush.maybeMap(
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
                            (state.activeMap?.layers.any(
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
            image: image,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            scope: placedInstancesScope,
            selectedInstanceId: state.selectedPlacedElementInstanceId,
            selectedInstance: selectedPlacedInstance,
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
    required EditorState state,
    required ProjectManifest project,
    required ProjectTilesetEntry activeTileset,
    required int tilesetColumns,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return const _PlacedElementInstancesScope(
        layerId: null,
        layerName: null,
        instances: [],
        emptyTitle: 'Aucune map active',
        emptyMessage: 'Charge une map pour parcourir les éléments posés.',
      );
    }
    final layerId = state.activeLayerId;
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
    if (layerTilesetId != activeTileset.id) {
      String layerTilesetName = layerTilesetId;
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          layerTilesetName = tileset.name;
          break;
        }
      }
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Tileset différent',
        emptyMessage:
            'Le calque actif utilise "$layerTilesetName". Sélectionne ce tileset dans la palette pour afficher les miniatures.',
      );
    }

    if (tilesetColumns <= 0) {
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Tileset non disponible',
        emptyMessage:
            'Impossible d’afficher les miniatures tant que le tileset n’est pas chargé.',
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
      final candidateElement = elementById[instance.elementId];
      final element = candidateElement != null &&
              _resolveElementPrimaryTilesetId(candidateElement) ==
                  layerTilesetId
          ? candidateElement
          : null;
      final key = element?.id ?? instance.elementId;
      final occurrence = (occurrencesByElementId[key] ?? 0) + 1;
      occurrencesByElementId[key] = occurrence;
      instances.add(
        _PlacedElementInstanceVm(
          instance: instance,
          element: element,
          layerName: tileLayer.name,
          occurrence: occurrence,
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
    var generatingCollision = false;

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
                  _ElementCollisionPaddingEditor(
                    padding: collisionPadding,
                    maxHorizontal: math.max(0, source.width * tileWidth - 1),
                    maxVertical: math.max(0, source.height * tileHeight - 1),
                    onChanged: (next) {
                      setStateDialog(() {
                        collisionPadding = next;
                        if (collisionProfile != null) {
                          collisionProfile =
                              collisionProfile!.copyWith(padding: next);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.regular,
                          secondary: true,
                          onPressed: generatingCollision
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    generatingCollision = true;
                                  });
                                  final generated = await notifier
                                      .generateElementCollisionProfile(
                                    tilesetId: tilesetId,
                                    source: source,
                                    presetKind: selectedPresetKind,
                                    padding: collisionPadding,
                                  );
                                  if (!mounted) return;
                                  setStateDialog(() {
                                    generatingCollision = false;
                                    if (generated != null) {
                                      collisionProfile = generated;
                                      collisionPadding = generated.padding;
                                    }
                                  });
                                },
                          child: Text(
                            generatingCollision
                                ? 'Génération...'
                                : 'Générer automatiquement la collision',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () {
                          setStateDialog(() {
                            collisionProfile = null;
                            collisionPadding = const WarpTriggerPadding();
                          });
                        },
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileEditor(
                    image: image,
                    source: source,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onProfileChanged: (profile) {
                      setStateDialog(() {
                        collisionProfile = profile;
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
    var collisionPadding =
        collisionProfile?.padding ?? const WarpTriggerPadding();
    var generatingCollision = false;
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
                  _ElementCollisionPaddingEditor(
                    padding: collisionPadding,
                    maxHorizontal: math.max(
                        0, element.frames.primarySource.width * tileWidth - 1),
                    maxVertical: math.max(0,
                        element.frames.primarySource.height * tileHeight - 1),
                    onChanged: (next) {
                      setStateDialog(() {
                        collisionPadding = next;
                        if (collisionProfile != null) {
                          collisionProfile =
                              collisionProfile!.copyWith(padding: next);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.regular,
                          secondary: true,
                          onPressed: generatingCollision
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    generatingCollision = true;
                                  });
                                  final generated = await notifier
                                      .generateElementCollisionProfile(
                                    tilesetId: element.tilesetId,
                                    source: element.frames.primarySource,
                                    presetKind: selectedPresetKind,
                                    padding: collisionPadding,
                                  );
                                  if (!mounted) return;
                                  setStateDialog(() {
                                    generatingCollision = false;
                                    if (generated != null) {
                                      collisionProfile = generated;
                                      collisionPadding = generated.padding;
                                    }
                                  });
                                },
                          child: Text(
                            generatingCollision
                                ? 'Génération...'
                                : 'Générer automatiquement la collision',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () {
                          setStateDialog(() {
                            collisionProfile = null;
                            collisionPadding = const WarpTriggerPadding();
                          });
                        },
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileEditor(
                    image: image,
                    source: element.frames.primarySource,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onProfileChanged: (profile) {
                      setStateDialog(() {
                        collisionProfile = profile;
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

class _PlacedElementInstancesScope {
  const _PlacedElementInstancesScope({
    required this.layerId,
    required this.layerName,
    required this.instances,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String? layerId;
  final String? layerName;
  final List<_PlacedElementInstanceVm> instances;
  final String emptyTitle;
  final String emptyMessage;
}

class _PlacedElementInstanceVm {
  const _PlacedElementInstanceVm({
    required this.instance,
    required this.element,
    required this.layerName,
    required this.occurrence,
  });

  final MapPlacedElement instance;
  final ProjectElementEntry? element;
  final String layerName;
  final int occurrence;

  String get displayLabel =>
      '${element?.id ?? instance.elementId} #$occurrence';
  GridPos get pos => instance.pos;
  String get layerId => instance.layerId;
  String get instanceId => instance.id;
  bool get applyCollision => instance.applyCollision;
  TilesetSourceRect get source =>
      element?.frames.primarySource ??
      const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1);
}

class _PlacedInstancesSection extends StatelessWidget {
  const _PlacedInstancesSection({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.scope,
    required this.selectedInstanceId,
    required this.selectedInstance,
    required this.onSelectInstance,
    required this.onCollisionAppliedChanged,
    required this.onDeleteInstance,
  });

  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final _PlacedElementInstancesScope scope;
  final String? selectedInstanceId;
  final _PlacedElementInstanceVm? selectedInstance;
  final ValueChanged<_PlacedElementInstanceVm?> onSelectInstance;
  final void Function(_PlacedElementInstanceVm instance, bool applyCollision)
      onCollisionAppliedChanged;
  final Future<void> Function(_PlacedElementInstanceVm instance)
      onDeleteInstance;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCyan;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);
    final selected = selectedInstance;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: accent.withValues(alpha: 0.09),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.1),
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
                  Icon(
                    CupertinoIcons.square_stack_3d_down_right_fill,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instances posées (calque actif)',
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${scope.instances.length}',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                scope.layerId == null
                    ? 'Calque actif: —'
                    : 'Calque actif: ${scope.layerName ?? scope.layerId}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              if (scope.instances.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EditorChrome.largeIslandSurfaceColor(
                      context,
                      tint: Colors.white.withValues(alpha: 0.02),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: separator),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scope.emptyTitle,
                        style: TextStyle(
                          color: label,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scope.emptyMessage,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height:
                      math.min(260, scope.instances.length * 67 + 6).toDouble(),
                  child: ListView.separated(
                    itemCount: scope.instances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final instance = scope.instances[index];
                      return _PlacedInstanceCard(
                        image: image,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        instance: instance,
                        selected: selectedInstanceId == instance.instanceId,
                        onTap: () => onSelectInstance(instance),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 15,
                    color: EditorChrome.inspectorJoyMint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Propriétés de l'instance sélectionnée",
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (selected == null)
                Text(
                  'Sélectionne une instance dans la liste pour afficher ses détails.',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11,
                  ),
                )
              else ...[
                _PropertyLine(
                  label: 'Élément source',
                  value: selected.element == null
                      ? 'Introuvable (${selected.instance.elementId})'
                      : '${selected.element!.name} (${selected.element!.id})',
                ),
                _PropertyLine(
                  label: 'Instance',
                  value: selected.displayLabel,
                ),
                _PropertyLine(
                  label: 'Position',
                  value: '(${selected.pos.x}, ${selected.pos.y})',
                ),
                _PropertyLine(
                  label: 'Taille',
                  value: '${selected.source.width} x ${selected.source.height}',
                ),
                _PropertyLine(
                  label: 'Layer',
                  value: '${selected.layerName} (${selected.layerId})',
                ),
                _PropertyLine(
                  label: 'ID interne',
                  value: selected.instanceId,
                ),
                const SizedBox(height: 8),
                _CollisionToggleRow(
                  value: selected.applyCollision,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    onCollisionAppliedChanged(selected, value);
                  },
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onPressed: () => onDeleteInstance(selected),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.trash, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Supprimer cette instance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const _FuturePropertyGroup(
                  title: 'Animation',
                  status: 'À venir',
                ),
                const SizedBox(height: 6),
                const _FuturePropertyGroup(
                  title: 'Comportement / Triggers',
                  status: 'À venir',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacedInstanceCard extends StatelessWidget {
  const _PlacedInstanceCard({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.instance,
    required this.selected,
    required this.onTap,
  });

  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final _PlacedElementInstanceVm instance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = EditorChrome.inspectorJoyCyan;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.13)
              : EditorPaintColors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? accent : border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                ),
                child: instance.element == null
                    ? Icon(
                        CupertinoIcons.question_circle,
                        size: 18,
                        color: secondary,
                      )
                    : _PaletteRectPreview(
                        image: image,
                        source: instance.source,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instance.element?.name ?? 'Élément introuvable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    instance.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Pos: (${instance.pos.x}, ${instance.pos.y}) · Layer: ${instance.layerName} · Collision: ${instance.applyCollision ? 'on' : 'off'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 16,
                color: EditorChrome.inspectorJoyCyan,
              ),
          ],
        ),
      ),
    );
  }
}

class _PropertyLine extends StatelessWidget {
  const _PropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final primary = CupertinoColors.label.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: primary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuturePropertyGroup extends StatelessWidget {
  const _FuturePropertyGroup({
    required this.title,
    required this.status,
  });

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollisionToggleRow extends StatelessWidget {
  const _CollisionToggleRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collision',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Appliquer la collision de l’élément',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: value,
              onChanged: (next) => onChanged(next),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementCollisionProfileEditor extends StatelessWidget {
  const _ElementCollisionProfileEditor({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final cells = _normalizedCells(profile?.cells ?? const []);
    final padding = profile?.padding ?? draftPadding;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
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
                  'Collision overlay',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${cells.length} cellule${cells.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Zone sombre = exclue par padding, contour cyan = zone active d’analyse.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxHeight = math
                  .min(210, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(120.0, 210.0);
              return SizedBox(
                height: boxHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final local = details.localPosition;
                    final size = Size(constraints.maxWidth, boxHeight);
                    final targetRect = _fitCollisionPreviewRect(
                      size: size,
                      source: source,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                    );
                    if (!targetRect.contains(local)) {
                      return;
                    }
                    final localX = local.dx - targetRect.left;
                    final localY = local.dy - targetRect.top;
                    final cellWidth = targetRect.width / source.width;
                    final cellHeight = targetRect.height / source.height;
                    final cellX =
                        (localX / cellWidth).floor().clamp(0, source.width - 1);
                    final cellY = (localY / cellHeight)
                        .floor()
                        .clamp(0, source.height - 1);
                    final key = '$cellX:$cellY';
                    final next = <String, GridPos>{
                      for (final cell in cells) '${cell.x}:${cell.y}': cell,
                    };
                    if (next.containsKey(key)) {
                      next.remove(key);
                    } else {
                      next[key] = GridPos(x: cellX, y: cellY);
                    }
                    onProfileChanged(
                      ElementCollisionProfile(
                        source: ElementCollisionProfileSource.manual,
                        padding: padding,
                        cells: _normalizedCells(
                            next.values.toList(growable: false)),
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ElementCollisionProfilePainter(
                        image: image,
                        source: source,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        padding: padding,
                        cells: cells,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Clique sur la grille pour activer/désactiver des cellules.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<GridPos> _normalizedCells(List<GridPos> cells) {
    final unique = <String, GridPos>{};
    for (final cell in cells) {
      if (cell.x < 0 || cell.y < 0) {
        continue;
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        continue;
      }
      unique['${cell.x}:${cell.y}'] = GridPos(x: cell.x, y: cell.y);
    }
    final out = unique.values.toList(growable: false)
      ..sort((a, b) {
        final yCompare = a.y.compareTo(b.y);
        if (yCompare != 0) {
          return yCompare;
        }
        return a.x.compareTo(b.x);
      });
    return out;
  }
}

class _ElementCollisionPaddingEditor extends StatelessWidget {
  const _ElementCollisionPaddingEditor({
    required this.padding,
    required this.maxHorizontal,
    required this.maxVertical,
    required this.onChanged,
  });

  final WarpTriggerPadding padding;
  final int maxHorizontal;
  final int maxVertical;
  final ValueChanged<WarpTriggerPadding> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.01),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Padding collision (px)',
            style: TextStyle(
              color: label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ajuste l’auto-génération puis affine manuellement si besoin.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionPaddingStepper(
                label: 'Top',
                value: padding.top,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(top: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Right',
                value: padding.right,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(right: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Bottom',
                value: padding.bottom,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Left',
                value: padding.left,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(left: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollisionPaddingStepper extends StatelessWidget {
  const _CollisionPaddingStepper({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canDecrease = value > 0;
    final canIncrease = value < maxValue;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 16,
                  color: canDecrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 16,
                  color: canIncrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementCollisionProfilePainter extends CustomPainter {
  _ElementCollisionProfilePainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.cells,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final WarpTriggerPadding padding;
  final List<GridPos> cells;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right > image.width || sourceRect.bottom > image.height) {
      return;
    }

    final targetRect = _fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final imagePaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    canvas.drawImageRect(image, sourceRect, targetRect, imagePaint);

    final sourcePixelWidth = source.width * tileWidth.toDouble();
    final sourcePixelHeight = source.height * tileHeight.toDouble();
    final scaleX =
        sourcePixelWidth <= 0 ? 1.0 : targetRect.width / sourcePixelWidth;
    final scaleY =
        sourcePixelHeight <= 0 ? 1.0 : targetRect.height / sourcePixelHeight;
    final leftPad = padding.left * scaleX;
    final rightPad = padding.right * scaleX;
    final topPad = padding.top * scaleY;
    final bottomPad = padding.bottom * scaleY;
    final activeLeft = targetRect.left + leftPad;
    final activeTop = targetRect.top + topPad;
    final activeRight = targetRect.right - rightPad;
    final activeBottom = targetRect.bottom - bottomPad;
    final activeRect = Rect.fromLTRB(
      math.min(activeLeft, activeRight),
      math.min(activeTop, activeBottom),
      math.max(activeLeft, activeRight),
      math.max(activeTop, activeBottom),
    );

    final excludedPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    if (leftPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            targetRect.left, targetRect.top, leftPad, targetRect.height),
        excludedPaint,
      );
    }
    if (rightPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.right - rightPad,
          targetRect.top,
          rightPad,
          targetRect.height,
        ),
        excludedPaint,
      );
    }
    if (topPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
            targetRect.left, targetRect.top, targetRect.width, topPad),
        excludedPaint,
      );
    }
    if (bottomPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.bottom - bottomPad,
          targetRect.width,
          bottomPad,
        ),
        excludedPaint,
      );
    }
    if (activeRect.width > 0 && activeRect.height > 0) {
      canvas.drawRect(
        activeRect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final cellWidth = targetRect.width / source.width;
    final cellHeight = targetRect.height / source.height;
    for (final cell in cells) {
      final cellRect = Rect.fromLTWH(
        targetRect.left + cell.x * cellWidth,
        targetRect.top + cell.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = EditorChrome.inspectorJoyCoral.withValues(alpha: 0.32)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        cellRect,
        Paint()
          ..color = EditorChrome.inspectorJoyCoral
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var x = 0; x <= source.width; x++) {
      final dx = targetRect.left + x * cellWidth;
      canvas.drawLine(
        Offset(dx, targetRect.top),
        Offset(dx, targetRect.bottom),
        gridPaint,
      );
    }
    for (var y = 0; y <= source.height; y++) {
      final dy = targetRect.top + y * cellHeight;
      canvas.drawLine(
        Offset(targetRect.left, dy),
        Offset(targetRect.right, dy),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElementCollisionProfilePainter oldDelegate) {
    if (oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.padding != padding ||
        oldDelegate.cells.length != cells.length) {
      return true;
    }
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != oldDelegate.cells[i]) {
        return true;
      }
    }
    return false;
  }
}

Rect _fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  if (sourcePixelWidth <= 0 || sourcePixelHeight <= 0) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = size.width <= 0 || size.height <= 0
      ? sourceAspect
      : size.width / size.height;
  if (sourceAspect > targetAspect) {
    final height = size.width / sourceAspect;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * sourceAspect;
  final left = (size.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, size.height);
}

class _CategoryTreeRow extends StatelessWidget {
  final int depth;
  final bool selected;
  final String label;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpanded;
  final Color? accentOverride;

  const _CategoryTreeRow({
    required this.depth,
    required this.selected,
    required this.label,
    required this.hasChildren,
    required this.expanded,
    required this.onTap,
    this.onToggleExpanded,
    this.accentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentOverride ?? CupertinoTheme.of(context).primaryColor;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final background = selected
        ? accent.withValues(alpha: 0.14)
        : EditorPaintColors.transparent;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(width: 10.0 * depth),
            SizedBox(
              width: 22,
              child: hasChildren
                  ? EditorToolbarIconButton(
                      onPressed: onToggleExpanded,
                      icon: expanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      iconSize: 14,
                      color: accent,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? accent : labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectElementCard extends StatelessWidget {
  final ui.Image image;
  final ProjectElementEntry element;
  final int tileWidth;
  final int tileHeight;
  final bool selected;
  final Color selectionAccent;
  final String categoryPath;
  final String tilesetName;
  final String groupLabel;
  final String tilesetGroupLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectElementCard({
    required this.image,
    required this.element,
    required this.tileWidth,
    required this.tileHeight,
    required this.selected,
    required this.selectionAccent,
    required this.categoryPath,
    required this.tilesetName,
    required this.groupLabel,
    required this.tilesetGroupLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sep = CupertinoColors.separator.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final tertiary = CupertinoColors.placeholderText.resolveFrom(context);
    final baseColor = selected
        ? selectionAccent.withValues(alpha: 0.1)
        : EditorPaintColors.transparent;
    final collisionCellCount = element.collisionProfile?.cells.length ?? 0;
    final meta2 = [
      groupLabel,
      tilesetGroupLabel,
      'Type: ${_elementPresetLabel(element.presetKind)}',
      'Collision: $collisionCellCount',
      if (element.recommendedLayerId != null &&
          element.recommendedLayerId!.isNotEmpty)
        'Calque : ${element.recommendedLayerId}',
    ].join(' · ');
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? selectionAccent : sep,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: sep),
                ),
                child: _PaletteRectPreview(
                  image: image,
                  source: element.frames.primarySource,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    element.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$categoryPath · $tilesetName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  Text(
                    meta2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: PopupMenuButton<int>(
                tooltip: 'Actions',
                padding: EdgeInsets.zero,
                splashRadius: 14,
                offset: const Offset(0, 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: BorderSide(
                    color: selectionAccent.withValues(alpha: 0.45),
                  ),
                ),
                color: EditorChrome.islandFillElevated(context),
                elevation: 3,
                itemBuilder: (ctx) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Text(
                      'Modifier',
                      style: TextStyle(color: labelColor),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text(
                      'Supprimer',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed.resolveFrom(
                          ctx,
                        ),
                      ),
                    ),
                  ),
                ],
                onSelected: (i) {
                  if (i == 0) {
                    onEdit();
                  } else if (i == 1) {
                    onDelete();
                  }
                },
                child: SizedBox(
                  width: 36,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: selectionAccent.withValues(alpha: 0.12),
                      ),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: selectionAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 16,
                      color: labelColor,
                    ),
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

class _PaletteTileCell extends StatelessWidget {
  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteTileCell({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final sep = CupertinoColors.separator.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: selected ? accent : sep),
        ),
        child: _PaletteTilePreview(
          image: image,
          tileId: tileId,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          columns: columns,
        ),
      ),
    );
  }
}

class _PaletteTilePreview extends StatelessWidget {
  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  const _PaletteTilePreview({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaletteTilePainter(
        image: image,
        tileId: tileId,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        columns: columns,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PaletteRectPreview extends StatelessWidget {
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  const _PaletteRectPreview({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaletteRectPainter(
        image: image,
        source: source,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PaletteTilePainter extends CustomPainter {
  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;

  _PaletteTilePainter({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sourceIndex = tileId - 1;
    if (sourceIndex < 0) return;
    final sourceX = (sourceIndex % columns) * tileWidth;
    final sourceY = (sourceIndex ~/ columns) * tileHeight;
    if (sourceX + tileWidth > image.width ||
        sourceY + tileHeight > image.height) {
      return;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PaletteTilePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.tileId != tileId ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.columns != columns;
  }
}

class _PaletteRectPainter extends CustomPainter {
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  _PaletteRectPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (srcRect.right > image.width || srcRect.bottom > image.height) {
      return;
    }

    final aspect = srcRect.width / srcRect.height;
    final targetAspect = size.width / size.height;
    Rect dstRect;
    if (aspect > targetAspect) {
      final height = size.width / aspect;
      final top = (size.height - height) / 2;
      dstRect = Rect.fromLTWH(0, top, size.width, height);
    } else {
      final width = size.height * aspect;
      final left = (size.width - width) / 2;
      dstRect = Rect.fromLTWH(left, 0, width, size.height);
    }
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PaletteRectPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight;
  }
}

class _TilesetSelectionPainter extends CustomPainter {
  final ui.Image image;
  final int columns;
  final int rows;
  final int tileWidth;
  final int tileHeight;
  final TilesetSourceRect? selection;

  _TilesetSelectionPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.tileWidth,
    required this.tileHeight,
    required this.selection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final srcRect = Rect.fromLTWH(
          x * tileWidth.toDouble(),
          y * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
      }
    }

    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var x = 0; x <= columns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final selected = selection;
    if (selected != null) {
      final rect = Rect.fromLTWH(
        selected.x * cellWidth,
        selected.y * cellHeight,
        selected.width * cellWidth,
        selected.height * cellHeight,
      );
      canvas.drawRect(
        rect,
        Paint()..color = EditorPaintColors.orange.withValues(alpha: 0.22),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = EditorPaintColors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TilesetSelectionPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.selection != selection;
  }
}

class _PaletteImageCache {
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

String _elementPresetLabel(ElementPresetKind kind) {
  switch (kind) {
    case ElementPresetKind.generic:
      return 'Generic';
    case ElementPresetKind.tree:
      return 'Tree';
    case ElementPresetKind.building:
      return 'Building';
    case ElementPresetKind.rock:
      return 'Rock';
    case ElementPresetKind.cliff:
      return 'Cliff';
    case ElementPresetKind.tallDecoration:
      return 'Tall deco';
  }
}

String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
  final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) {
    return frameTilesetId;
  }
  return entry.tilesetId.trim();
}
