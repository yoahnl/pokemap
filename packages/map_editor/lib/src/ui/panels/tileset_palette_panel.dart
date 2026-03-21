import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';

enum _ElementVisibilityMode {
  context,
  globalOnly,
  all,
}

class TilesetPalettePanel extends ConsumerStatefulWidget {
  const TilesetPalettePanel({super.key});

  @override
  ConsumerState<TilesetPalettePanel> createState() =>
      _TilesetPalettePanelState();
}

class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  bool _creationMode = false;
  GridPos? _selectionStart;
  GridPos? _selectionEnd;
  String? _selectedCategoryId;
  _ElementVisibilityMode _visibilityMode = _ElementVisibilityMode.context;
  bool _showAllTilesets = false;
  final Set<String> _expandedCategories = <String>{};

  TilesetSourceRect? get _selectionRect {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return null;
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

    if (map == null || project == null) {
      return const Center(
        child: Text('No map loaded', style: TextStyle(color: Colors.white38)),
      );
    }

    final activeTileset = notifier.getActiveTilesetEntry();
    final activeTilesetPath = notifier.getActiveTilesetAbsolutePath();
    if (activeTileset == null || activeTilesetPath == null) {
      return const Center(
        child:
            Text('No active tileset', style: TextStyle(color: Colors.white38)),
      );
    }

    final tileLayers =
        map.layers.whereType<TileLayer>().toList(growable: false);
    final categories = notifier.getElementCategories();
    if (_selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    return FutureBuilder<ui.Image?>(
      future: _PaletteImageCache.load(activeTilesetPath),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeTileset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tileset image unavailable',
                  style: TextStyle(color: Colors.white54),
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
          return const Center(
            child: Text(
              'Invalid tile size for active tileset',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ELEMENT LIBRARY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeTileset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${columns * rows} tiles',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: tileLayers.any((l) => l.id == state.activeLayerId)
                      ? state.activeLayerId
                      : (tileLayers.isNotEmpty ? tileLayers.first.id : null),
                  decoration: const InputDecoration(
                    labelText: 'Target Layer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: tileLayers
                      .map(
                        (layer) => DropdownMenuItem<String>(
                          value: layer.id,
                          child: Text(layer.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      notifier.setActiveLayer(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              const TabBar(
                tabs: [
                  Tab(text: 'Tiles'),
                  Tab(text: 'Elements'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTilesTab(
                      state: state,
                      notifier: notifier,
                      image: image,
                      project: project,
                      tileLayers: tileLayers,
                      columns: columns,
                      rows: rows,
                      settings: settings,
                      activeTileset: activeTileset,
                    ),
                    _buildElementsTab(
                      state: state,
                      notifier: notifier,
                      image: image,
                      project: project,
                      categories: categories,
                      columns: columns,
                      tileWidth: settings.tileWidth,
                      tileHeight: settings.tileHeight,
                      activeTilesetId: activeTileset.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

    final selectedTileId = state.selectedTileId;
    final selectedEntry =
        selectedTileId == null ? null : unitEntryByTileId[selectedTileId];
    final selectedCategory =
        selectedEntry?.category ?? PaletteCategory.uncategorized;
    final previewSize = settings.tileWidth * settings.displayScale * 2.0;
    final selectionRect = _selectionRect;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: DropdownButtonFormField<PaletteCategory?>(
            value: filter,
            decoration: const InputDecoration(
              labelText: 'Tile Category Filter',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<PaletteCategory?>(
                value: null,
                child: Text('All'),
              ),
              ...PaletteCategory.values.map(
                (category) => DropdownMenuItem<PaletteCategory?>(
                  value: category,
                  child: Text(_legacyCategoryLabel(category)),
                ),
              ),
            ],
            onChanged: notifier.setPaletteCategoryFilter,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setCreationMode(!_creationMode),
                  icon: Icon(_creationMode ? Icons.close : Icons.crop_square),
                  label: Text(
                    _creationMode ? 'Exit Element Creation' : 'Create Element',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: !_creationMode || selectionRect == null
                    ? null
                    : () => _showCreateElementDialog(
                          context,
                          notifier: notifier,
                          project: project,
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
                  selectionRect: selectionRect,
                )
              : Padding(
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemBuilder: (context, index) {
                          final tileId = filteredTileIds[index];
                          final entry = unitEntryByTileId[tileId];
                          return _PaletteTileCell(
                            image: image,
                            tileId: tileId,
                            tileWidth: settings.tileWidth,
                            tileHeight: settings.tileHeight,
                            columns: columns,
                            selected: tileId == selectedTileId,
                            onTap: () {
                              notifier.selectPaletteTile(
                                tileId,
                                paletteEntryId: entry?.id,
                              );
                              notifier.selectTool(EditorToolType.tilePaint);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Tile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (_creationMode && selectionRect != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Selection: ${selectionRect.width}x${selectionRect.height} at (${selectionRect.x}, ${selectionRect.y})',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: selectedTileId == null
                        ? const Center(
                            child: Text(
                              '-',
                              style: TextStyle(color: Colors.white38),
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
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<PaletteCategory>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Tile Category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: PaletteCategory.values
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(_legacyCategoryLabel(category)),
                                ),
                              )
                              .toList(),
                          onChanged: selectedTileId == null
                              ? null
                              : (value) {
                                  if (value != null) {
                                    notifier.upsertPaletteEntryForTile(
                                      tileId: selectedTileId,
                                      columns: columns,
                                      category: value,
                                      recommendedLayerId: state.activeLayerId,
                                    );
                                  }
                                },
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
    required String activeTilesetId,
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

    final visibleElements = notifier.getVisibleProjectElementsForActiveMap(
      includeAll: _visibilityMode == _ElementVisibilityMode.all,
      globalOnly: _visibilityMode == _ElementVisibilityMode.globalOnly,
      acrossAllTilesets: _showAllTilesets,
    );

    final selectedCategoryId = _selectedCategoryId;
    Set<String>? categoryScope;
    if (selectedCategoryId != null) {
      categoryScope =
          _collectCategoryScope(categoriesByParent, selectedCategoryId);
    }

    final filteredElements = visibleElements.where((element) {
      if (categoryScope != null &&
          !categoryScope.contains(element.categoryId)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final tilesetById = <String, ProjectTilesetEntry>{
      for (final tileset in project.tilesets) tileset.id: tileset,
    };
    final groupById = <String, ProjectMapGroup>{
      for (final group in project.groups) group.id: group,
    };

    final treeRows = <Widget>[
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
      const Divider(height: 1),
      ..._buildCategoryRows(
        categoriesByParent: categoriesByParent,
        parentCategoryId: null,
        depth: 0,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<_ElementVisibilityMode>(
                  value: _visibilityMode,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _ElementVisibilityMode.context,
                      child: Text('Context'),
                    ),
                    DropdownMenuItem(
                      value: _ElementVisibilityMode.globalOnly,
                      child: Text('Global'),
                    ),
                    DropdownMenuItem(
                      value: _ElementVisibilityMode.all,
                      child: Text('All'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _visibilityMode = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showCreateCategoryDialog(
                  context,
                  notifier: notifier,
                  parentCategoryId: null,
                ),
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'New Category',
              ),
              IconButton(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () => _showCreateCategoryDialog(
                          context,
                          notifier: notifier,
                          parentCategoryId: _selectedCategoryId,
                        ),
                icon: const Icon(Icons.create_new_folder),
                tooltip: 'New Subcategory',
              ),
              IconButton(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () => _showRenameCategoryDialog(
                          context,
                          notifier: notifier,
                          categoryId: _selectedCategoryId!,
                          currentName:
                              categoriesById[_selectedCategoryId]?.name ?? '',
                        ),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Rename Category',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: CheckboxListTile(
            value: _showAllTilesets,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('All tilesets'),
            onChanged: (value) {
              setState(() {
                _showAllTilesets = value ?? false;
              });
            },
          ),
        ),
        Container(
          height: 170,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            children: treeRows,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filteredElements.length} elements',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filteredElements.isEmpty
              ? const Center(
                  child: Text(
                    'No element for current filters',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filteredElements.length,
                  itemBuilder: (context, index) {
                    final element = filteredElements[index];
                    final categoryPath = _buildCategoryPathLabel(
                      categoriesById: categoriesById,
                      categoryId: element.categoryId,
                    );
                    final tilesetName = tilesetById[element.tilesetId]?.name ??
                        element.tilesetId;
                    final groupLabel = element.groupId == null
                        ? 'Global'
                        : 'Group: ${_buildGroupPathLabel(groupById, element.groupId!)}';
                    final selectColumns =
                        element.tilesetId == activeTilesetId ? columns : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProjectElementCard(
                        image: image,
                        element: element,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        selected: state.selectedProjectElementId == element.id,
                        categoryPath: categoryPath,
                        tilesetName: tilesetName,
                        groupLabel: groupLabel,
                        onTap: () {
                          notifier.selectProjectElement(
                            element.id,
                            tilesetColumns: selectColumns,
                          );
                          if (element.recommendedLayerId != null &&
                              (state.activeMap?.layers.any(
                                    (layer) =>
                                        layer is TileLayer &&
                                        layer.id == element.recommendedLayerId,
                                  ) ??
                                  false)) {
                            notifier
                                .setActiveLayer(element.recommendedLayerId!);
                          }
                          notifier.selectTool(EditorToolType.tilePaint);
                        },
                        onEdit: () => _showEditElementDialog(
                          context,
                          notifier: notifier,
                          project: project,
                          element: element,
                          categories: categories,
                          tileLayers: state.activeMap?.layers
                                  .whereType<TileLayer>()
                                  .toList(growable: false) ??
                              const [],
                        ),
                      ),
                    );
                  },
                ),
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

  Widget _buildSelectionCanvas({
    required ui.Image image,
    required int columns,
    required int rows,
    required int tileWidth,
    required int tileHeight,
    required TilesetSourceRect? selectionRect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = math.max(80.0, constraints.maxWidth - 16.0);
        final cellSize = canvasWidth / columns;
        final canvasHeight = cellSize * rows;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        );
      },
    );
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String? parentCategoryId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(parentCategoryId == null ? 'New Category' : 'New Subcategory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              shouldSave = true;
              Navigator.pop(context);
            },
            child: const Text('Create'),
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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              shouldSave = true;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.renameElementCategory(categoryId, controller.text.trim());
  }

  Future<void> _showCreateElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required TilesetSourceRect source,
    required String? activeLayerId,
    required List<TileLayer> tileLayers,
  }) async {
    final categories = notifier.getElementCategories();
    if (categories.isEmpty) {
      return;
    }
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: 'element_${source.x}_${source.y}',
    );
    final tagsController = TextEditingController();
    var selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null ||
        !categories.any((category) => category.id == selectedCategoryId)) {
      selectedCategoryId = categories.first.id;
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
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create Element'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Source: ${source.width}x${source.height} at (${source.x}, ${source.y})',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(
                            _buildCategoryPathLabel(
                              categoriesById: categoriesById,
                              categoryId: category.id,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedCategoryId = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Scope Group',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Global'),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem<String?>(
                        value: group.id,
                        child: Text(_buildGroupPathLabel(groupById, group.id)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedGroupId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedLayerId,
                  decoration: const InputDecoration(
                    labelText: 'Recommended Layer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...tileLayers.map(
                      (layer) => DropdownMenuItem<String?>(
                        value: layer.id,
                        child: Text(layer.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedLayerId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'tree,outdoor,oak',
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
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                shouldSave = true;
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (!shouldSave || selectedCategoryId == null) return;
    await notifier.createProjectElement(
      name: nameController.text.trim(),
      categoryId: selectedCategoryId!,
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
  }) async {
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
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

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: element.name);
    final tagsController = TextEditingController(text: element.tags.join(','));
    String selectedCategoryId = element.categoryId;
    String? selectedGroupId = element.groupId;
    String? selectedLayerId = element.recommendedLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }
    var shouldSave = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit Element'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(
                            _buildCategoryPathLabel(
                              categoriesById: categoriesById,
                              categoryId: category.id,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedCategoryId = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Scope Group',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Global'),
                    ),
                    ...groups.map(
                      (group) => DropdownMenuItem<String?>(
                        value: group.id,
                        child: Text(_buildGroupPathLabel(groupById, group.id)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedGroupId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedLayerId,
                  decoration: const InputDecoration(
                    labelText: 'Recommended Layer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...tileLayers.map(
                      (layer) => DropdownMenuItem<String?>(
                        value: layer.id,
                        child: Text(layer.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedLayerId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'tree,outdoor,oak',
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
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                shouldSave = true;
                Navigator.pop(context);
              },
              child: const Text('Save'),
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
      groupId: selectedGroupId,
      clearGroupId: selectedGroupId == null,
      recommendedLayerId: selectedLayerId,
      clearRecommendedLayerId: selectedLayerId == null,
      tags: _parseTags(tagsController.text),
    );
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
    final background =
        selected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 12.0 * depth),
            SizedBox(
              width: 24,
              child: hasChildren
                  ? IconButton(
                      onPressed: onToggleExpanded,
                      icon: Icon(
                        expanded
                            ? Icons.expand_more_outlined
                            : Icons.chevron_right_outlined,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
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
                  color: selected ? Colors.blue.shade200 : Colors.white,
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
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ProjectElementCard({
    required this.image,
    required this.element,
    required this.tileWidth,
    required this.tileHeight,
    required this.selected,
    required this.categoryPath,
    required this.tilesetName,
    required this.groupLabel,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        selected ? Colors.blue.withValues(alpha: 0.18) : Colors.transparent;
    return Material(
      color: baseColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? Colors.blue : Colors.white24),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      tilesetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      groupLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    if (element.recommendedLayerId != null &&
                        element.recommendedLayerId!.isNotEmpty)
                      Text(
                        'Layer: ${element.recommendedLayerId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                constraints:
                    const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: selected ? Colors.blue : Colors.white24),
          ),
          child: _PaletteTilePreview(
            image: image,
            tileId: tileId,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            columns: columns,
          ),
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
      ..color = Colors.white24
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
        Paint()..color = Colors.orange.withValues(alpha: 0.22),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.orange
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
