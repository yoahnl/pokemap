import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';

class TilesetEditorCanvas extends ConsumerStatefulWidget {
  const TilesetEditorCanvas({super.key});

  @override
  ConsumerState<TilesetEditorCanvas> createState() =>
      _TilesetEditorCanvasState();
}

class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
  GridPos? _selectionStart;
  GridPos? _selectionEnd;
  String? _lastTilesetId;

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

  GridPos _gridFromLocal(
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    final settings = project?.settings ?? const ProjectSettings();

    if (project == null) {
      return const Center(
        child: Text('No project loaded'),
      );
    }

    final tileset = notifier.getSelectedTilesetEntry();
    final tilesetPath = notifier.getSelectedTilesetAbsolutePath();
    if (tileset == null || tilesetPath == null) {
      return const Center(
        child: Text('No tileset selected'),
      );
    }
    if (_lastTilesetId != tileset.id) {
      _lastTilesetId = tileset.id;
      _selectionStart = null;
      _selectionEnd = null;
    }

    return FutureBuilder<ui.Image?>(
      future: _TilesetEditorImageCache.load(tilesetPath),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return Center(
            child: Text('Unable to load tileset: ${tileset.name}'),
          );
        }

        final columns =
            settings.tileWidth > 0 ? image.width ~/ settings.tileWidth : 0;
        final rows =
            settings.tileHeight > 0 ? image.height ~/ settings.tileHeight : 0;
        if (columns <= 0 || rows <= 0) {
          return const Center(
            child: Text('Invalid tile settings for selected tileset'),
          );
        }

        final selectionRect = _selectionRect;
        final cellWidth = math.max(
            2.0, settings.tileWidth * settings.displayScale * state.zoom);
        final cellHeight = math.max(
            2.0, settings.tileHeight * settings.displayScale * state.zoom);
        final canvasWidth = columns * cellWidth;
        final canvasHeight = rows * cellHeight;
        final tileLayers = state.activeMap?.layers
                .whereType<TileLayer>()
                .toList(growable: false) ??
            const <TileLayer>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tileset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${columns * rows} tiles | ${columns}x$rows',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          selectionRect == null
                              ? 'No selection'
                              : 'Selection ${selectionRect.width}x${selectionRect.height} at (${selectionRect.x}, ${selectionRect.y})',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: selectionRect == null
                        ? null
                        : () => _showCreateElementDialog(
                              context,
                              notifier: notifier,
                              project: project,
                              tilesetId: tileset.id,
                              tilesetGroups: tileset.elementGroups,
                              source: selectionRect,
                              activeLayerId: state.activeLayerId,
                              tileLayers: tileLayers,
                            ),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Create Element'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: canvasWidth,
                          height: canvasHeight,
                          child: GestureDetector(
                            onPanStart: (details) {
                              final pos = _gridFromLocal(
                                details.localPosition,
                                cellWidth,
                                cellHeight,
                                columns,
                                rows,
                              );
                              setState(() {
                                _selectionStart = pos;
                                _selectionEnd = pos;
                              });
                            },
                            onPanUpdate: (details) {
                              if (_selectionStart == null) return;
                              final pos = _gridFromLocal(
                                details.localPosition,
                                cellWidth,
                                cellHeight,
                                columns,
                                rows,
                              );
                              setState(() {
                                _selectionEnd = pos;
                              });
                            },
                            onTapUp: (details) {
                              final pos = _gridFromLocal(
                                details.localPosition,
                                cellWidth,
                                cellHeight,
                                columns,
                                rows,
                              );
                              setState(() {
                                _selectionStart = pos;
                                _selectionEnd = pos;
                              });
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                              ),
                              child: CustomPaint(
                                painter: _TilesetCanvasPainter(
                                  image: image,
                                  columns: columns,
                                  rows: rows,
                                  selection: selectionRect,
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
              ),
            ),
          ],
        );
      },
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
      return;
    }

    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final groups = List<ProjectMapGroup>.from(project.groups)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final worldGroupById = <String, ProjectMapGroup>{
      for (final group in groups) group.id: group,
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

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: 'element_${source.x}_${source.y}',
    );
    final tagsController = TextEditingController();
    String selectedCategoryId = categories.first.id;
    String? selectedTilesetGroupId =
        ref.read(editorNotifierProvider).selectedTilesetElementGroupId;
    if (selectedTilesetGroupId != null &&
        !tilesetGroupById.containsKey(selectedTilesetGroupId)) {
      selectedTilesetGroupId = null;
    }
    String? selectedWorldGroupId = _activeMapGroupId(project);
    String? selectedLayerId = activeLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }

    var shouldSave = false;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create Element'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Source: ${source.width}x${source.height} at (${source.x}, ${source.y})',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
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
                    value: selectedTilesetGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Tileset Group',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...sortedTilesetGroups.map(
                        (group) => DropdownMenuItem<String?>(
                          value: group.id,
                          child: Text(
                            _buildTilesetGroupPathLabel(
                                tilesetGroupById, group.id),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedTilesetGroupId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedWorldGroupId,
                    decoration: const InputDecoration(
                      labelText: 'World Group Scope',
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
                          child: Text(
                            _buildWorldGroupPathLabel(worldGroupById, group.id),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedWorldGroupId = value;
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
    await notifier.createProjectElement(
      name: nameController.text.trim(),
      tilesetId: tilesetId,
      categoryId: selectedCategoryId,
      tilesetGroupId: selectedTilesetGroupId,
      source: source,
      groupId: selectedWorldGroupId,
      recommendedLayerId: selectedLayerId,
      tags: _parseTags(tagsController.text),
    );
  }

  String? _activeMapGroupId(ProjectManifest project) {
    final map = ref.read(editorNotifierProvider).activeMap;
    if (map == null) return null;
    for (final entry in project.maps) {
      if (entry.id == map.id) {
        return entry.groupId;
      }
    }
    return null;
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

  String _buildWorldGroupPathLabel(
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

  List<String> _parseTags(String value) {
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

class _TilesetCanvasPainter extends CustomPainter {
  final ui.Image image;
  final int columns;
  final int rows;
  final TilesetSourceRect? selection;

  _TilesetCanvasPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.selection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
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
  bool shouldRepaint(covariant _TilesetCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.selection != selection;
  }
}

class _TilesetEditorImageCache {
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
