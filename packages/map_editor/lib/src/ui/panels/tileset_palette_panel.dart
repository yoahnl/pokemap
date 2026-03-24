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
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';

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

  @override
  void dispose() {
    _selectionHorizontalScrollController.dispose();
    _selectionVerticalScrollController.dispose();
    super.dispose();
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
        final labelColor = CupertinoColors.label.resolveFrom(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(12, widget.embedded ? 10 : 12, 12, 8),
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
                  SizedBox(height: widget.embedded ? 0 : 6),
                  Text(
                    selectedTileset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () async {
                      final picked = await showCupertinoListPicker<String>(
                        context: context,
                        title: 'Tileset',
                        items:
                            sortedTilesets.map((tileset) => tileset.id).toList(),
                        labelOf: (id) => sortedTilesets
                            .firstWhere((t) => t.id == id)
                            .name,
                      );
                      if (picked != null) {
                        notifier.selectTilesetEditorContext(picked);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tileset',
                          style: TextStyle(fontSize: 12, color: secondary),
                        ),
                        Text(
                          selectedTileset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: labelColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${columns * rows} tiles',
                    style: TextStyle(color: secondary, fontSize: 12),
                  ),
                  if (map == null)
                    Text(
                      'No active map: edition mode only',
                      style: TextStyle(color: secondary, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (tileLayers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Builder(
                  builder: (ctx) {
                    final effectiveLayerId =
                        tileLayers.any((l) => l.id == state.activeLayerId)
                            ? state.activeLayerId!
                            : tileLayers.first.id;
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      onPressed: () async {
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Target Layer',
                          items: tileLayers.map((l) => l.id).toList(),
                          labelOf: (id) =>
                              tileLayers.firstWhere((l) => l.id == id).name,
                        );
                        if (picked != null) {
                          notifier.setActiveLayer(picked);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Layer',
                            style: TextStyle(fontSize: 12, color: secondary),
                          ),
                          Text(
                            tileLayers
                                .firstWhere((l) => l.id == effectiveLayerId)
                                .name,
                            style: TextStyle(color: labelColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
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
      if (entry.source.width != 1 || entry.source.height != 1) continue;
      final tileId = entry.source.y * columns + entry.source.x + 1;
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
    String filterLabel(int i) => i < 0
        ? 'All'
        : _legacyCategoryLabel(PaletteCategory.values[i]);
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
                          tilesetId: activeTileset.id,
                          tilesetGroups: activeTileset.elementGroups,
                          source: selectionRect,
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
              top: BorderSide(color: CupertinoColors.separator.resolveFrom(context)),
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
                                  final picked =
                                      await showCupertinoListPicker<
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

    final tilesetGroupRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: validSelectedTilesetGroupId == null,
        label: 'All Internal Groups',
        hasChildren: false,
        expanded: false,
        onTap: () => notifier.selectTilesetElementGroupFilter(null),
      ),
      const EditorHorizontalDivider(),
      ..._buildTilesetGroupRows(
        groupsByParent: tilesetGroupsByParent,
        parentGroupId: null,
        selectedGroupId: validSelectedTilesetGroupId,
        onSelect: (groupId) =>
            notifier.selectTilesetElementGroupFilter(groupId),
      ),
    ];

    final categoryRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: selectedCategoryId == null,
        label: 'All Categories',
        hasChildren: false,
        expanded: false,
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
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tileset Internal Groups',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ),
              EditorToolbarIconButton(
                onPressed: () => _showCreateTilesetGroupDialog(
                  context,
                  notifier: notifier,
                  tilesetId: activeTileset.id,
                ),
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New Group',
              ),
              EditorToolbarIconButton(
                onPressed: validSelectedTilesetGroupId == null
                    ? null
                    : () => _showCreateTilesetSubgroupDialog(
                          context,
                          notifier: notifier,
                          tilesetId: activeTileset.id,
                          parentGroupId: validSelectedTilesetGroupId,
                        ),
                icon: CupertinoIcons.folder_fill,
                tooltip: 'New Subgroup',
              ),
              EditorToolbarIconButton(
                onPressed: validSelectedTilesetGroupId == null
                    ? null
                    : () => _showRenameTilesetGroupDialog(
                          context,
                          notifier: notifier,
                          tilesetId: activeTileset.id,
                          groupId: validSelectedTilesetGroupId,
                          currentName:
                              tilesetGroupById[validSelectedTilesetGroupId]
                                      ?.name ??
                                  '',
                        ),
                icon: CupertinoIcons.pencil,
                tooltip: 'Rename Group',
              ),
            ],
          ),
        ),
        Container(
          height: 130,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            children: tilesetGroupRows,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Element Categories',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 12,
                  ),
                ),
              ),
              EditorToolbarIconButton(
                onPressed: () => _showCreateCategoryDialog(
                  context,
                  notifier: notifier,
                  parentCategoryId: null,
                ),
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New Category',
              ),
              EditorToolbarIconButton(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () => _showCreateCategoryDialog(
                          context,
                          notifier: notifier,
                          parentCategoryId: _selectedCategoryId,
                        ),
                icon: CupertinoIcons.folder_fill,
                tooltip: 'New Subcategory',
              ),
              EditorToolbarIconButton(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () => _showRenameCategoryDialog(
                          context,
                          notifier: notifier,
                          categoryId: _selectedCategoryId!,
                          currentName:
                              categoriesById[_selectedCategoryId]?.name ?? '',
                        ),
                icon: CupertinoIcons.pencil,
                tooltip: 'Rename Category',
              ),
            ],
          ),
        ),
        Container(
          height: 130,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            children: categoryRows,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filteredElements.length} elements',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (filteredElements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              'No element for current filters',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
                  : 'Group: ${_buildGroupPathLabel(groupById, element.groupId!)}';
              final tilesetGroupLabel = element.tilesetGroupId == null
                  ? 'Internal: none'
                  : 'Internal: ${_buildTilesetGroupPathLabel(tilesetGroupById, element.tilesetGroupId!)}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProjectElementCard(
                  image: image,
                  element: element,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                  selected: state.activeBrush.maybeMap(
                    projectElement: (brush) => brush.elementId == element.id,
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
                      notifier.setActiveLayer(element.recommendedLayerId!);
                    }
                    notifier.selectTool(EditorToolType.tilePaint);
                  },
                  onEdit: () => _showEditElementDialog(
                    context,
                    notifier: notifier,
                    project: project,
                    element: element,
                    categories: categories,
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
    );
  }

  List<Widget> _buildCategoryRows({
    required Map<String?, List<ProjectElementCategory>> categoriesByParent,
    required String? parentCategoryId,
    required int depth,
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
              final pos =
                  _gridFromLocal(details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionEnd = pos;
              });
            },
            onTapUp: (details) {
              final pos =
                  _gridFromLocal(details.localPosition, cellSize, columns, rows);
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
    required String tilesetId,
    required List<TilesetElementGroup> tilesetGroups,
    required TilesetSourceRect source,
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
    required ProjectElementEntry element,
    required List<ProjectElementCategory> categories,
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

class _CategoryTreeRow extends StatelessWidget {
  final int depth;
  final bool selected;
  final String label;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpanded;

  const _CategoryTreeRow({
    required this.depth,
    required this.selected,
    required this.label,
    required this.hasChildren,
    required this.expanded,
    required this.onTap,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 12.0 * depth),
            SizedBox(
              width: 24,
              child: hasChildren
                  ? EditorToolbarIconButton(
                      onPressed: onToggleExpanded,
                      icon: expanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      iconSize: 16,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
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
    final accent = CupertinoTheme.of(context).primaryColor;
    final sep = CupertinoColors.separator.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final baseColor =
        selected ? accent.withValues(alpha: 0.12) : EditorPaintColors.transparent;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? accent : sep,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: sep),
                ),
                child: _PaletteRectPreview(
                  image: image,
                  source: element.source,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    categoryPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                  Text(
                    tilesetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                  Text(
                    groupLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    tilesetGroupLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 11,
                    ),
                  ),
                  if (element.recommendedLayerId != null &&
                      element.recommendedLayerId!.isNotEmpty)
                    Text(
                      'Layer: ${element.recommendedLayerId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CupertinoColors.placeholderText.resolveFrom(context),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            EditorToolbarIconButton(
              onPressed: onEdit,
              icon: CupertinoIcons.pencil,
              iconSize: 18,
              tooltip: 'Edit',
            ),
            EditorToolbarIconButton(
              onPressed: onDelete,
              icon: CupertinoIcons.trash,
              iconSize: 18,
              tooltip: 'Delete',
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
