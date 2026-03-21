import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';

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

  void _setCreationMode(bool value) {
    if (_creationMode == value) return;
    setState(() {
      _creationMode = value;
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

    final tileset = notifier.getActiveTilesetEntry();
    final tilesetPath = notifier.getActiveTilesetAbsolutePath();
    if (tileset == null || tilesetPath == null) {
      return const Center(
        child:
            Text('No active tileset', style: TextStyle(color: Colors.white38)),
      );
    }

    final tileLayers =
        map.layers.whereType<TileLayer>().toList(growable: false);

    return FutureBuilder<ui.Image?>(
      future: _PaletteImageCache.load(tilesetPath),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tileset.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
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
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tileset.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Invalid tile size for this tileset image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        final allEntries =
            List<TilesetPaletteEntry>.from(tileset.paletteEntries)
              ..sort(_paletteEntrySort);

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
                    Text(
                      tileset.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${columns * rows} tiles  •  ${allEntries.length} elements',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<PaletteCategory?>(
                  value: state.paletteCategoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Category Filter',
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
                        child: Text(_categoryLabel(category)),
                      ),
                    ),
                  ],
                  onChanged: notifier.setPaletteCategoryFilter,
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
                      context,
                      state: state,
                      notifier: notifier,
                      image: image,
                      columns: columns,
                      rows: rows,
                      settings: settings,
                      tileset: tileset,
                    ),
                    _buildElementsTab(
                      notifier: notifier,
                      state: state,
                      image: image,
                      columns: columns,
                      tileWidth: settings.tileWidth,
                      tileHeight: settings.tileHeight,
                      entries: allEntries,
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

  Widget _buildTilesTab(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ui.Image image,
    required int columns,
    required int rows,
    required ProjectSettings settings,
    required ProjectTilesetEntry tileset,
  }) {
    final unitEntryByTileId = <int, TilesetPaletteEntry>{};
    for (final entry in tileset.paletteEntries) {
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setCreationMode(!_creationMode),
                  icon: Icon(_creationMode ? Icons.close : Icons.crop_square),
                  label: Text(
                    _creationMode ? 'Exit Element Mode' : 'Create Element',
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
                          source: selectionRect,
                          activeLayerId: state.activeLayerId,
                          tileLayers: state.activeMap?.layers
                                  .whereType<TileLayer>()
                                  .toList(growable: false) ??
                              const [],
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
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: PaletteCategory.values
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(_categoryLabel(category)),
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
    required EditorNotifier notifier,
    required EditorState state,
    required ui.Image image,
    required int columns,
    required int tileWidth,
    required int tileHeight,
    required List<TilesetPaletteEntry> entries,
  }) {
    final filter = state.paletteCategoryFilter;
    final filteredEntries = entries.where((entry) {
      if (filter == null) return true;
      return entry.category == filter;
    }).toList(growable: false);

    if (filteredEntries.isEmpty) {
      return const Center(
        child: Text(
          'No elements for this filter',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final grouped = <PaletteCategory, List<TilesetPaletteEntry>>{};
    for (final entry in filteredEntries) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final nameA = a.name.trim().isEmpty ? a.id : a.name.trim();
        final nameB = b.name.trim().isEmpty ? b.id : b.name.trim();
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      children: [
        for (final category in PaletteCategory.values)
          if ((grouped[category]?.isNotEmpty ?? false)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _categoryLabel(category).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...grouped[category]!.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaletteElementCard(
                  image: image,
                  entry: entry,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                  selected: state.selectedPaletteEntryId == entry.id,
                  onTap: () {
                    notifier.selectPaletteEntry(
                      entry.id,
                      tilesetColumns: columns,
                    );
                    notifier.selectTool(EditorToolType.tilePaint);
                  },
                ),
              ),
            ),
          ],
      ],
    );
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

  Future<void> _showCreateElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required TilesetSourceRect source,
    required String? activeLayerId,
    required List<TileLayer> tileLayers,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: 'element_${source.x}_${source.y}',
    );
    PaletteCategory category = PaletteCategory.uncategorized;
    String? recommendedLayer = activeLayerId;
    if (recommendedLayer != null &&
        !tileLayers.any((layer) => layer.id == recommendedLayer)) {
      recommendedLayer = null;
    }

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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaletteCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PaletteCategory.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_categoryLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        category = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: recommendedLayer,
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
                      recommendedLayer = value;
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

    if (!shouldSave) return;
    await notifier.createPaletteEntry(
      name: nameController.text.trim(),
      category: category,
      source: source,
      recommendedLayerId: recommendedLayer,
    );
    notifier.selectTool(EditorToolType.tilePaint);
    if (!mounted) return;
    setState(() {
      _creationMode = false;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }
}

class _PaletteElementCard extends StatelessWidget {
  final ui.Image image;
  final TilesetPaletteEntry entry;
  final int tileWidth;
  final int tileHeight;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteElementCard({
    required this.image,
    required this.entry,
    required this.tileWidth,
    required this.tileHeight,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = entry.name.trim().isEmpty ? entry.id : entry.name.trim();
    final recommended = entry.recommendedLayerId;
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
                    source: entry.source,
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
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.source.width}x${entry.source.height} • ${_categoryLabel(entry.category)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    if (recommended != null && recommended.trim().isNotEmpty)
                      Text(
                        'Layer: $recommended',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                  ],
                ),
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

int _paletteEntrySort(TilesetPaletteEntry a, TilesetPaletteEntry b) {
  final categoryCompare = a.category.index.compareTo(b.category.index);
  if (categoryCompare != 0) return categoryCompare;
  final nameA = a.name.trim().isEmpty ? a.id : a.name.trim();
  final nameB = b.name.trim().isEmpty ? b.id : b.name.trim();
  final nameCompare = nameA.toLowerCase().compareTo(nameB.toLowerCase());
  if (nameCompare != 0) return nameCompare;
  return a.id.compareTo(b.id);
}

String _categoryLabel(PaletteCategory category) {
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
