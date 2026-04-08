import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/services/element_collision_authoring_service.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';

const ElementCollisionAuthoringService _authoringService =
    ElementCollisionAuthoringService();

Future<ElementCollisionProfile?> showElementCollisionEditorSheet({
  required BuildContext context,
  required String elementName,
  required ui.Image image,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  ElementCollisionProfile? initialProfile,
  WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
}) {
  return showMacosEditorTallSheet<ElementCollisionProfile>(
    context: context,
    heightFraction: 0.92,
    maxWidth: 1180,
    builder: (ctx) => _ElementCollisionEditorSheet(
      elementName: elementName,
      image: image,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      initialProfile: initialProfile,
      fallbackPadding: fallbackPadding,
    ),
  );
}

class _ElementCollisionEditorSheet extends StatefulWidget {
  const _ElementCollisionEditorSheet({
    required this.elementName,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.initialProfile,
    required this.fallbackPadding,
  });

  final String elementName;
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? initialProfile;
  final WarpTriggerPadding fallbackPadding;

  @override
  State<_ElementCollisionEditorSheet> createState() =>
      _ElementCollisionEditorSheetState();
}

class _ElementCollisionEditorSheetState
    extends State<_ElementCollisionEditorSheet> {
  _ElementCollisionEditorTool _tool = _ElementCollisionEditorTool.preview;
  ElementCollisionProfile? _draftProfile;
  late WarpTriggerPadding _draftPadding;
  bool _showGrid = true;
  bool _showBase = true;
  bool _showFinal = true;
  bool _showOverrides = true;
  final List<Offset> _pendingPolygon = <Offset>[];
  Offset? _lastBrushPoint;
  Offset? _hoverGridPoint;

  @override
  void initState() {
    super.initState();
    _draftProfile = widget.initialProfile;
    _draftPadding = widget.initialProfile?.padding ?? widget.fallbackPadding;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _describe();
    final pendingPolygonPreviewCells = _buildPendingPolygonPreviewCells();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return LayoutBuilder(
      builder: (context, constraints) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              _pendingPolygon.length >= 3) {
            _closeAndApplyPendingPolygon();
            return KeyEventResult.handled;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _pendingPolygon.isNotEmpty) {
            setState(() {
              _pendingPolygon.clear();
              _hoverGridPoint = null;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditorHeader(
                  elementName: widget.elementName,
                  source: widget.source,
                  finalCellCount: snapshot.finalCells.length,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: () => Navigator.of(context).pop(_buildSavedProfile()),
                ),
                const SizedBox(height: 14),
                _EditorToolbar(
                  tool: _tool,
                  pendingPolygonCount: _pendingPolygon.length,
                  onToolChanged: (tool) {
                    setState(() {
                      _tool = tool;
                      _lastBrushPoint = null;
                      _hoverGridPoint = null;
                      if (!_isPolygonTool(tool)) {
                        _pendingPolygon.clear();
                      }
                    });
                  },
                  onClosePolygon: _pendingPolygon.length >= 3
                      ? _closeAndApplyPendingPolygon
                      : null,
                  onClearPolygon: _pendingPolygon.isNotEmpty
                      ? () => setState(() {
                            _pendingPolygon.clear();
                            _hoverGridPoint = null;
                          })
                      : null,
                  onResetOverrides: () {
                    setState(() {
                      _draftProfile = _authoringService.resetOverrides(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        current: _draftProfile,
                        fallbackPadding: _draftPadding,
                      );
                      _draftPadding = _draftProfile?.padding ?? _draftPadding;
                    });
                  },
                  onRestoreBase: () {
                    setState(() {
                      _draftProfile = _authoringService.recalculateFromPadding(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        padding: _draftPadding,
                        current: _draftProfile,
                        preserveOverrides: false,
                      );
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _draftProfile = _authoringService.clearAllCollision(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        current: _draftProfile,
                        fallbackPadding: _draftPadding,
                      );
                    });
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: Colors.white.withValues(alpha: 0.02),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CupertinoColors.separator
                                  .resolveFrom(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Forme de collision',
                                    style: TextStyle(
                                      color: label,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _tool.helpLabel,
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, canvasConstraints) {
                                    final canvasSize = Size(
                                      canvasConstraints.maxWidth,
                                      canvasConstraints.maxHeight,
                                    );
                                    return MouseRegion(
                                      cursor: _tool ==
                                              _ElementCollisionEditorTool
                                                  .preview
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.precise,
                                      onHover: (event) {
                                        final next = _localToGridPoint(
                                          event.localPosition,
                                          canvasSize,
                                        );
                                        if (next == _hoverGridPoint) {
                                          return;
                                        }
                                        setState(() => _hoverGridPoint = next);
                                      },
                                      onExit: (_) {
                                        if (_hoverGridPoint != null) {
                                          setState(
                                              () => _hoverGridPoint = null);
                                        }
                                      },
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapUp: (details) => _handleCanvasTap(
                                            details.localPosition, canvasSize),
                                        onDoubleTapDown: (details) =>
                                            _handleCanvasDoubleTap(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanStart: (details) =>
                                            _handleCanvasPanStart(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanUpdate: (details) =>
                                            _handleCanvasPanUpdate(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanEnd: (_) => _lastBrushPoint = null,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            color: Colors.black
                                                .withValues(alpha: 0.14),
                                            border: Border.all(
                                              color: CupertinoColors.separator
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter:
                                                _ElementCollisionCanvasPainter(
                                              image: widget.image,
                                              source: widget.source,
                                              tileWidth: widget.tileWidth,
                                              tileHeight: widget.tileHeight,
                                              snapshot: snapshot,
                                              showGrid: _showGrid,
                                              showBase: _showBase,
                                              showFinal: _showFinal,
                                              showOverrides: _showOverrides,
                                              pendingPolygon: _pendingPolygon,
                                              pendingPolygonPreviewCells:
                                                  pendingPolygonPreviewCells,
                                              hoverGridPoint: _hoverGridPoint,
                                              highlightPolygonClosure:
                                                  _shouldHighlightPolygonClosure,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 320,
                        child: _EditorSidebar(
                          source: widget.source,
                          snapshot: snapshot,
                          showGrid: _showGrid,
                          showBase: _showBase,
                          showFinal: _showFinal,
                          showOverrides: _showOverrides,
                          pendingPolygonPreviewCount:
                              pendingPolygonPreviewCells.length,
                          onShowGridChanged: (value) =>
                              setState(() => _showGrid = value),
                          onShowBaseChanged: (value) =>
                              setState(() => _showBase = value),
                          onShowFinalChanged: (value) =>
                              setState(() => _showFinal = value),
                          onShowOverridesChanged: (value) =>
                              setState(() => _showOverrides = value),
                          paddingEditor: ElementCollisionPaddingEditor(
                            padding: _draftPadding,
                            maxHorizontal: math.max(
                                0, widget.source.width * widget.tileWidth - 1),
                            maxVertical: math.max(0,
                                widget.source.height * widget.tileHeight - 1),
                            onChanged: (next) {
                              setState(() {
                                _draftPadding = next;
                                _draftProfile =
                                    _authoringService.recalculateFromPadding(
                                  source: widget.source,
                                  tileWidth: widget.tileWidth,
                                  tileHeight: widget.tileHeight,
                                  padding: next,
                                  current: _draftProfile,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ElementCollisionAuthoringSnapshot _describe() {
    return _authoringService.describe(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      profile: _draftProfile,
      fallbackPadding: _draftPadding,
    );
  }

  List<GridPos> _buildPendingPolygonPreviewCells() {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return const <GridPos>[];
    }
    // The polygon itself is the authoring truth while editing. These preview
    // cells are the backend projection that will actually reach runtime after
    // closing/saving, so the author can judge the conversion before commit.
    return _authoringService.shapeRasterizerService.rasterizePolygon(
      vertices: _pendingPolygon,
      gridWidth: widget.source.width,
      gridHeight: widget.source.height,
    );
  }

  ElementCollisionProfile _buildSavedProfile() {
    final snapshot = _describe();
    return _authoringService.rebuild(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      padding: snapshot.padding,
      manualAddedCells: snapshot.manualAddedCells,
      manualRemovedCells: snapshot.manualRemovedCells,
    );
  }

  void _closeAndApplyPendingPolygon() {
    if (_pendingPolygon.length < 3) {
      return;
    }
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyPolygon(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        vertices: List<Offset>.from(_pendingPolygon),
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _pendingPolygon.clear();
      _hoverGridPoint = null;
    });
  }

  void _handleCanvasTap(Offset localPosition, Size canvasSize) {
    if (_tool == _ElementCollisionEditorTool.preview) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    if (_isPolygonTool(_tool)) {
      if (_pendingPolygon.length >= 3 &&
          _isNearPolygonStart(gridPoint, _pendingPolygon.first)) {
        _closeAndApplyPendingPolygon();
        return;
      }
      setState(() {
        _pendingPolygon.add(gridPoint);
      });
      return;
    }

    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
    });
  }

  void _handleCanvasDoubleTap(Offset localPosition, Size canvasSize) {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    setState(() => _hoverGridPoint = gridPoint);
    _closeAndApplyPendingPolygon();
  }

  void _handleCanvasPanStart(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    _lastBrushPoint = gridPoint;
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
    });
  }

  void _handleCanvasPanUpdate(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    final previous = _lastBrushPoint;
    final operation = _tool.operation;
    if (previous == null || operation == null) {
      _lastBrushPoint = gridPoint;
      return;
    }
    if ((previous - gridPoint).distance < 0.001) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[previous, gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _lastBrushPoint = gridPoint;
    });
  }

  Offset? _localToGridPoint(Offset localPosition, Size canvasSize) {
    final targetRect = _fitCollisionPreviewRect(
      size: canvasSize,
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      padding: 24,
    );
    if (!targetRect.contains(localPosition)) {
      return null;
    }
    final localX = localPosition.dx - targetRect.left;
    final localY = localPosition.dy - targetRect.top;
    final gridX = (localX / targetRect.width) * widget.source.width;
    final gridY = (localY / targetRect.height) * widget.source.height;
    return Offset(gridX, gridY);
  }

  bool _isBrushTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.brushAdd ||
        tool == _ElementCollisionEditorTool.brushRemove;
  }

  bool _isPolygonTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.polygonAdd ||
        tool == _ElementCollisionEditorTool.polygonRemove;
  }

  bool get _shouldHighlightPolygonClosure {
    if (!_isPolygonTool(_tool) ||
        _pendingPolygon.length < 3 ||
        _hoverGridPoint == null) {
      return false;
    }
    return _isNearPolygonStart(_hoverGridPoint!, _pendingPolygon.first);
  }

  bool _isNearPolygonStart(Offset point, Offset start) {
    return (point - start).distance <= 0.45;
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.elementName,
    required this.source,
    required this.finalCellCount,
    required this.onCancel,
    required this.onSave,
  });

  final String elementName;
  final TilesetSourceRect source;
  final int finalCellCount;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collision Editor',
                style: editorMacosSheetTitleStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                '$elementName • source ${source.width}x${source.height} • $finalCellCount cellule${finalCellCount > 1 ? 's' : ''} finales',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: onCancel,
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 10),
        PushButton(
          controlSize: ControlSize.large,
          onPressed: onSave,
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.tool,
    required this.pendingPolygonCount,
    required this.onToolChanged,
    required this.onClosePolygon,
    required this.onClearPolygon,
    required this.onResetOverrides,
    required this.onRestoreBase,
    required this.onClearAll,
  });

  final _ElementCollisionEditorTool tool;
  final int pendingPolygonCount;
  final ValueChanged<_ElementCollisionEditorTool> onToolChanged;
  final VoidCallback? onClosePolygon;
  final VoidCallback? onClearPolygon;
  final VoidCallback onResetOverrides;
  final VoidCallback onRestoreBase;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final value in _ElementCollisionEditorTool.values)
          _ToolButton(
            label: value.label,
            selected: tool == value,
            onPressed: () => onToolChanged(value),
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Fermer le polygone ($pendingPolygonCount)',
            onPressed: onClosePolygon,
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Effacer le polygone',
            onPressed: onClearPolygon,
          ),
        _ToolbarAction(
          label: 'Réinitialiser retouches',
          onPressed: onResetOverrides,
        ),
        _ToolbarAction(
          label: 'Restaurer base padding',
          onPressed: onRestoreBase,
        ),
        _ToolbarAction(
          label: 'Vider toute collision',
          onPressed: onClearAll,
        ),
      ],
    );
  }
}

class _EditorSidebar extends StatelessWidget {
  const _EditorSidebar({
    required this.source,
    required this.snapshot,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.onShowGridChanged,
    required this.onShowBaseChanged,
    required this.onShowFinalChanged,
    required this.onShowOverridesChanged,
    this.pendingPolygonPreviewCount = 0,
    required this.paddingEditor,
  });

  final TilesetSourceRect source;
  final ElementCollisionAuthoringSnapshot snapshot;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final ValueChanged<bool> onShowGridChanged;
  final ValueChanged<bool> onShowBaseChanged;
  final ValueChanged<bool> onShowFinalChanged;
  final ValueChanged<bool> onShowOverridesChanged;
  final int pendingPolygonPreviewCount;
  final Widget paddingEditor;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarSection(
          title: 'Résumé',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LegendChip(
                    label: 'Base ${snapshot.baseCells.length}',
                    color: Colors.cyanAccent,
                  ),
                  _LegendChip(
                    label: '+ ${snapshot.manualAddedCells.length}',
                    color: Colors.greenAccent,
                  ),
                  _LegendChip(
                    label: '- ${snapshot.manualRemovedCells.length}',
                    color: Colors.redAccent,
                  ),
                  _LegendChip(
                    label: 'Final ${snapshot.finalCells.length}',
                    color: EditorChrome.inspectorJoyCoral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Le runtime lira uniquement ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} dans `collisionProfile.cells`.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Source: ${source.width} colonnes × ${source.height} lignes',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              if (pendingPolygonPreviewCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Preview backend polygone: $pendingPolygonPreviewCount cellule${pendingPolygonPreviewCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Padding auto',
          child: paddingEditor,
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Affichage',
          child: Column(
            children: [
              _DisplayToggle(
                label: 'Grille',
                value: showGrid,
                onChanged: onShowGridChanged,
              ),
              _DisplayToggle(
                label: 'Base auto',
                value: showBase,
                onChanged: onShowBaseChanged,
              ),
              _DisplayToggle(
                label: 'Retouches manuelles',
                value: showOverrides,
                onChanged: onShowOverridesChanged,
              ),
              _DisplayToggle(
                label: 'Forme finale',
                value: showFinal,
                onChanged: onShowFinalChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Aide',
          child: Text(
            'Pinceau: cliquez-glissez pour peindre des cellules. Polygone: placez des points, puis fermez la forme en cliquant sur le premier point, avec Entrée, double-clic ou le bouton dédié. Base = padding, final = base + ajouts - retraits.',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class ElementCollisionPaddingEditor extends StatelessWidget {
  const ElementCollisionPaddingEditor({
    super.key,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Le padding génère la base automatique, puis les retouches manuelles sont réappliquées par-dessus.',
          style: TextStyle(
            color: secondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PaddingStepper(
              label: 'Top',
              value: padding.top,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(top: v)),
            ),
            _PaddingStepper(
              label: 'Right',
              value: padding.right,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(right: v)),
            ),
            _PaddingStepper(
              label: 'Bottom',
              value: padding.bottom,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
            ),
            _PaddingStepper(
              label: 'Left',
              value: padding.left,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(left: v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Valeurs actuelles: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
          style: TextStyle(
            color: label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaddingStepper extends StatelessWidget {
  const _PaddingStepper({
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
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
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
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 18,
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

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.018),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DisplayToggle extends StatelessWidget {
  const _DisplayToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          MacosSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCoral;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size.zero,
      borderRadius: BorderRadius.circular(10),
      color: selected ? accent.withValues(alpha: 0.16) : Colors.black26,
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ElementCollisionCanvasPainter extends CustomPainter {
  _ElementCollisionCanvasPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.snapshot,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.pendingPolygon,
    required this.pendingPolygonPreviewCells,
    required this.hoverGridPoint,
    required this.highlightPolygonClosure,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionAuthoringSnapshot snapshot;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final List<Offset> pendingPolygon;
  final List<GridPos> pendingPolygonPreviewCells;
  final Offset? hoverGridPoint;
  final bool highlightPolygonClosure;

  @override
  void paint(Canvas canvas, Size size) {
    final targetRect = _fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: 24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          targetRect.inflate(10), const Radius.circular(18)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      canvas.drawImageRect(
        image,
        sourceRect,
        targetRect,
        Paint()
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.none,
      );
    }

    final cellWidth = targetRect.width / source.width;
    final cellHeight = targetRect.height / source.height;

    if (showBase) {
      for (final cell in snapshot.baseCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.cyanAccent.withValues(alpha: 0.16),
        );
      }
    }

    if (showFinal) {
      for (final cell in snapshot.finalCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18),
          strokeColor: EditorChrome.inspectorJoyCoral,
        );
      }
    }

    if (pendingPolygonPreviewCells.isNotEmpty) {
      for (final cell in pendingPolygonPreviewCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.yellowAccent.withValues(alpha: 0.14),
          strokeColor: Colors.yellowAccent.withValues(alpha: 0.85),
        );
      }
    }

    if (showOverrides) {
      for (final cell in snapshot.manualAddedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect.deflate(2),
          Paint()
            ..color = Colors.greenAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      for (final cell in snapshot.manualRemovedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = Colors.redAccent.withValues(alpha: 0.16)
            ..style = PaintingStyle.fill,
        );
        final strikePaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawLine(cellRect.topLeft, cellRect.bottomRight, strikePaint);
        canvas.drawLine(cellRect.topRight, cellRect.bottomLeft, strikePaint);
      }
    }

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1;
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

    if (pendingPolygon.isNotEmpty) {
      final path = Path();
      final points = pendingPolygon
          .map((point) => Offset(
                targetRect.left + (point.dx / source.width) * targetRect.width,
                targetRect.top + (point.dy / source.height) * targetRect.height,
              ))
          .toList(growable: false);
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellowAccent.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in points) {
        canvas.drawCircle(
          point,
          4,
          Paint()..color = Colors.yellowAccent,
        );
      }
      canvas.drawCircle(
        points.first,
        highlightPolygonClosure ? 9 : 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlightPolygonClosure ? 3 : 1.5
          ..color = highlightPolygonClosure
              ? Colors.greenAccent
              : Colors.yellowAccent.withValues(alpha: 0.8),
      );
      if (hoverGridPoint != null && highlightPolygonClosure) {
        final hoverPoint = Offset(
          targetRect.left +
              (hoverGridPoint!.dx / source.width) * targetRect.width,
          targetRect.top +
              (hoverGridPoint!.dy / source.height) * targetRect.height,
        );
        canvas.drawLine(
          hoverPoint,
          points.first,
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      if (points.length >= 3) {
        final preview = Path.from(path)..close();
        canvas.drawPath(
          preview,
          Paint()
            ..color = Colors.yellowAccent.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _fillCell(
    Canvas canvas, {
    required GridPos cell,
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
    required Color color,
    Color? strokeColor,
  }) {
    final rect = _cellRect(
      cell,
      targetRect: targetRect,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (strokeColor != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Rect _cellRect(
    GridPos cell, {
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
  }) {
    return Rect.fromLTWH(
      targetRect.left + cell.x * cellWidth,
      targetRect.top + cell.y * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementCollisionCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.snapshot != snapshot ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showBase != showBase ||
        oldDelegate.showFinal != showFinal ||
        oldDelegate.showOverrides != showOverrides ||
        !_sameCells(oldDelegate.pendingPolygonPreviewCells,
            pendingPolygonPreviewCells) ||
        oldDelegate.hoverGridPoint != hoverGridPoint ||
        oldDelegate.highlightPolygonClosure != highlightPolygonClosure ||
        !_sameOffsets(oldDelegate.pendingPolygon, pendingPolygon);
  }

  bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _sameCells(List<GridPos> a, List<GridPos> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

Rect _fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  double padding = 0,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  final safeRect = Rect.fromLTWH(
    padding,
    padding,
    math.max(0, size.width - padding * 2),
    math.max(0, size.height - padding * 2),
  );
  if (sourcePixelWidth <= 0 ||
      sourcePixelHeight <= 0 ||
      safeRect.width <= 0 ||
      safeRect.height <= 0) {
    return safeRect;
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = safeRect.width / safeRect.height;
  if (sourceAspect > targetAspect) {
    final height = safeRect.width / sourceAspect;
    final top = safeRect.top + (safeRect.height - height) / 2;
    return Rect.fromLTWH(safeRect.left, top, safeRect.width, height);
  }
  final width = safeRect.height * sourceAspect;
  final left = safeRect.left + (safeRect.width - width) / 2;
  return Rect.fromLTWH(left, safeRect.top, width, safeRect.height);
}

enum _ElementCollisionEditorTool {
  preview(
    label: 'Aperçu',
    helpLabel: 'Visualiser la forme finale et les retouches.',
  ),
  brushAdd(
    label: 'Pinceau +',
    helpLabel: 'Cliquez-glissez pour ajouter des cellules.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  brushRemove(
    label: 'Pinceau -',
    helpLabel: 'Cliquez-glissez pour retirer des cellules.',
    operation: ElementCollisionAuthoringOperation.remove,
  ),
  polygonAdd(
    label: 'Polygone +',
    helpLabel: 'Placez des points, puis appliquez le polygone.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  polygonRemove(
    label: 'Polygone -',
    helpLabel: 'Placez des points, puis retirez cette zone.',
    operation: ElementCollisionAuthoringOperation.remove,
  );

  const _ElementCollisionEditorTool({
    required this.label,
    required this.helpLabel,
    this.operation,
  });

  final String label;
  final String helpLabel;
  final ElementCollisionAuthoringOperation? operation;
}
