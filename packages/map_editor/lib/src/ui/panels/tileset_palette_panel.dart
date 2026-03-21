import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';

class TilesetPalettePanel extends ConsumerWidget {
  const TilesetPalettePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final tileLayers = <TileLayer>[];
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        tileLayers.add(layer);
      }
    }

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
                Text(tileset.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
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
                Text(tileset.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                const Text(
                  'Invalid tile size for this tileset image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

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
            continue;
          }
          if (entry.category == filter) {
            filteredTileIds.add(tileId);
          }
        }

        final selectedTileId = state.selectedTileId;
        final selectedEntry =
            selectedTileId == null ? null : unitEntryByTileId[selectedTileId];
        final selectedCategory =
            selectedEntry?.category ?? PaletteCategory.uncategorized;
        final previewSize = settings.tileWidth * settings.displayScale * 2.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tileset.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${columns * rows} tiles',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<PaletteCategory?>(
                value: filter,
                decoration: const InputDecoration(
                  labelText: 'Category',
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
            Expanded(
              child: Padding(
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
                  const Text('Selected Tile',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                child: Text('-',
                                    style: TextStyle(color: Colors.white38)),
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
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(_categoryLabel(category)),
                                      ))
                                  .toList(),
                              onChanged: selectedTileId == null
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        notifier.upsertPaletteEntryForTile(
                                          tileId: selectedTileId,
                                          columns: columns,
                                          category: value,
                                          recommendedLayerId:
                                              state.activeLayerId,
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
      },
    );
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
