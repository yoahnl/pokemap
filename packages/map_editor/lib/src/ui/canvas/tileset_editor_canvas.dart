import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../theme/theme.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import 'tileset_grid_metrics.dart';

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

        final metrics = TilesetGridMetrics.fromImagePixels(
          imageWidth: image.width,
          imageHeight: image.height,
          tileWidth: settings.tileWidth,
          tileHeight: settings.tileHeight,
        );
        final columns = metrics.columns;
        final rows = metrics.rows;
        if (!metrics.isValid) {
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

        final colors = context.pokeMapColors;
        final subtle = colors.textMuted;

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
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${columns * rows} tuiles · $columns × $rows',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 12,
                          ),
                        ),
                        if (metrics.hasTrailingPixels)
                          Text(
                            'Grille utilisable : ${metrics.usablePixelWidth} × ${metrics.usablePixelHeight} px sur ${image.width} × ${image.height} px',
                            style: TextStyle(
                              color: subtle,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          selectionRect == null
                              ? 'Aucune sélection'
                              : 'Sélection ${selectionRect.width} × ${selectionRect.height} à (${selectionRect.x}, ${selectionRect.y})',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: colors.brandPrimary,
                    disabledColor: colors.brandPrimary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.plus_square, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Créer un élément',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const EditorHorizontalDivider(),
            Expanded(
              child: CupertinoScrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: CupertinoScrollbar(
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
                                border: Border.all(
                                    color: EditorPaintColors.white24),
                              ),
                              child: CustomPaint(
                                painter: _TilesetCanvasPainter(
                                  image: image,
                                  columns: columns,
                                  rows: rows,
                                  tileWidth: settings.tileWidth,
                                  tileHeight: settings.tileHeight,
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
      await showCupertinoEditorAlert(
        context,
        title: 'Catégorie d’élément manquante',
        message:
            'Créez au moins une catégorie d’élément avant de pouvoir créer un élément.',
      );
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
    await showMacosEditorTallSheet<void>(
      context: context,
      maxWidth: 440,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Créer un élément',
                        style: editorMacosSheetTitleStyle(ctx),
                      ),
                    ),
                    MacosIconButton(
                      icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Source : ${source.width} × ${source.height} à (${source.x}, ${source.y})',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      ctx,
                      label: 'Nom',
                      controller: nameController,
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
                            title: 'Catégorie',
                            items: categories.map((c) => c.id).toList(),
                            labelOf: (id) => _buildCategoryPathLabel(
                              categoriesById: categoriesById,
                              categoryId: id,
                            ),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedCategoryId = picked;
                            });
                          }
                        },
                        child: Text(
                          'Catégorie : ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () async {
                          final picked =
                              await showMacosEditorActionsSheet<String>(
                            context: ctx,
                            title: const Text('Groupe de tileset'),
                            actions: [
                              const MacosEditorSheetAction(
                                label: 'Aucun',
                                value: '',
                              ),
                              ...sortedTilesetGroups.map(
                                (g) => MacosEditorSheetAction<String>(
                                  label: _buildTilesetGroupPathLabel(
                                      tilesetGroupById, g.id),
                                  value: g.id,
                                ),
                              ),
                            ],
                          );
                          if (picked == null || !ctx.mounted) return;
                          setStateDialog(() {
                            selectedTilesetGroupId =
                                picked.isEmpty ? null : picked;
                          });
                        },
                        child: Text(
                          selectedTilesetGroupId == null
                              ? 'Groupe de tileset : Aucun'
                              : 'Groupe de tileset : ${_buildTilesetGroupPathLabel(tilesetGroupById, selectedTilesetGroupId!)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () async {
                          final picked =
                              await showMacosEditorActionsSheet<String>(
                            context: ctx,
                            title: const Text("Portée du groupe d'éléments"),
                            actions: [
                              const MacosEditorSheetAction(
                                label: 'Global',
                                value: '',
                              ),
                              ...groups.map(
                                (g) => MacosEditorSheetAction<String>(
                                  label: _buildWorldGroupPathLabel(
                                      worldGroupById, g.id),
                                  value: g.id,
                                ),
                              ),
                            ],
                          );
                          if (picked == null || !ctx.mounted) return;
                          setStateDialog(() {
                            selectedWorldGroupId =
                                picked.isEmpty ? null : picked;
                          });
                        },
                        child: Text(
                          selectedWorldGroupId == null
                              ? "Groupe d'éléments : Global"
                              : "Groupe d'éléments : ${_buildWorldGroupPathLabel(worldGroupById, selectedWorldGroupId!)}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PushButton(
                        controlSize: ControlSize.regular,
                        secondary: true,
                        onPressed: () async {
                          final picked =
                              await showMacosEditorActionsSheet<String>(
                            context: ctx,
                            title: const Text('Calque recommandé'),
                            actions: [
                              const MacosEditorSheetAction(
                                label: 'Aucun',
                                value: '',
                              ),
                              ...tileLayers.map(
                                (layer) => MacosEditorSheetAction<String>(
                                  label: layer.name,
                                  value: layer.id,
                                ),
                              ),
                            ],
                          );
                          if (picked == null || !ctx.mounted) return;
                          setStateDialog(() {
                            selectedLayerId = picked.isEmpty ? null : picked;
                          });
                        },
                        child: Text(
                          selectedLayerId == null
                              ? 'Calque recommandé : Aucun'
                              : 'Calque recommandé : ${tileLayers.firstWhere((l) => l.id == selectedLayerId).name}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      ctx,
                      label: 'Tags (arbre, exterieur, etc.)',
                      controller: tagsController,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          return;
                        }
                        shouldSave = true;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Créer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  static Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: editorMacosFormLabelStyle(context)),
        const SizedBox(height: 6),
        MacosTextField(controller: controller),
      ],
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
  final int tileWidth;
  final int tileHeight;
  final TilesetSourceRect? selection;

  _TilesetCanvasPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.tileWidth,
    required this.tileHeight,
    required this.selection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      (columns * tileWidth).toDouble(),
      (rows * tileHeight).toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
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
  bool shouldRepaint(covariant _TilesetCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
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
