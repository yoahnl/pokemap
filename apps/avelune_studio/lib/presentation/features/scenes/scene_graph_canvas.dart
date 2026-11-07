import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_menu.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_painter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_surface.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';
export 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';
export 'package:avelune_studio/presentation/features/scenes/scene_canvas_node.dart'
    show sceneBlockColor, sceneBlockIcon;

class SceneGraphCanvas extends StatefulWidget {
  const SceneGraphCanvas({
    super.key,
    required this.scene,
    required this.viewport,
    required this.onSelectNode,
    required this.onSelectEdge,
    required this.onClearSelection,
    required this.onMoveNode,
    required this.onConnect,
    required this.onAdd,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.availableBlocks = const [],
    this.highlightedNodeIds = const {},
    this.highlightedEdgeIds = const {},
    this.nodeSummary,
    this.onDelete,
    this.onDuplicate,
    this.onUndo,
    this.onRedo,
    this.onSave,
    this.fitOnFirstLayout = true,
  });
  final SceneAsset scene;
  final SceneGraphViewport viewport;
  final String? selectedNodeId, selectedEdgeId;
  final ValueChanged<String> onSelectNode, onSelectEdge;
  final VoidCallback onClearSelection;
  final void Function(String, Offset) onMoveNode;
  final void Function(String, String, String) onConnect;
  final SceneCanvasAdd onAdd;
  final List<SceneBlockDragData> availableBlocks;
  final Set<String> highlightedNodeIds, highlightedEdgeIds;
  final String Function(SceneNode)? nodeSummary;
  final VoidCallback? onDelete, onDuplicate, onUndo, onRedo, onSave;
  final bool fitOnFirstLayout;
  @override
  State<SceneGraphCanvas> createState() => _SceneGraphCanvasState();
}

class _SceneGraphCanvasState extends State<SceneGraphCanvas> {
  final _canvasKey = GlobalKey();
  final _focus = FocusNode(debugLabel: 'Scene canvas');
  late SceneCanvasGeometry _geometry;
  final _positions = <String, Offset>{};
  String? _dragNode, _wireNode, _wirePort, _target;
  Offset? _wireEnd;
  bool _keyboardLink = false;
  bool _minimap = true;
  int _menuRevision = 0;
  @override
  void initState() {
    super.initState();
    _geometry = SceneCanvasGeometry(widget.scene);
    widget.viewport.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant SceneGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewport != widget.viewport) {
      oldWidget.viewport.removeListener(_refresh);
      widget.viewport.addListener(_refresh);
      _menuRevision++;
    }
    if (!identical(oldWidget.scene, widget.scene)) {
      _menuRevision++;
      _geometry = SceneCanvasGeometry(widget.scene);
      _positions.clear();
      _dragNode = null;
      if (oldWidget.scene.id != widget.scene.id || _wireNode != null) {
        _clearGesture();
        _menuRevision++;
      }
    }
  }

  @override
  void dispose() {
    widget.viewport.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _clearGesture() {
    _positions.clear();
    _dragNode = null;
    _wireNode = null;
    _wirePort = null;
    _target = null;
    _wireEnd = null;
    _keyboardLink = false;
  }

  void _cancel() {
    if (_keyboardLink) _announce('Liaison annulée.');
    setState(_clearGesture);
  }

  void _announce(String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  String _nodeName(String id) {
    final node = _geometry.nodes[id];
    return node?.title?.trim().isNotEmpty == true
        ? node!.title!.trim()
        : node == null
        ? id
        : sceneKindLabel(node.kind);
  }

  List<String> _freePorts(String id) => [
    for (final port
        in _geometry.ports[id] ?? const <SceneAuthorableOutputPort>[])
      if (!_geometry.occupied.contains('$id:${port.id}')) port.id,
  ];

  List<String> _targets(String source) {
    final ids = [
      for (final node in _geometry.nodes.values)
        if (node.id != source && node.kind != SceneNodeKind.start) node.id,
    ];
    ids.sort((a, b) {
      final pa = _geometry.positions[a]!, pb = _geometry.positions[b]!;
      final dx = pa.dx.compareTo(pb.dx);
      return dx != 0 ? dx : pa.dy.compareTo(pb.dy);
    });
    return ids;
  }

  void _showKeyboardTarget(String target) {
    _target = target;
    _wireEnd = widget.viewport.worldToLocal(
      _geometry.input(target, _positions),
    );
  }

  KeyEventResult _keyboardLinkKey(LogicalKeyboardKey key) {
    final source = widget.selectedNodeId;
    if (!_keyboardLink) {
      if (key != LogicalKeyboardKey.keyL || source == null) {
        return KeyEventResult.ignored;
      }
      final ports = _freePorts(source), targets = _targets(source);
      if (ports.isEmpty || targets.isEmpty) {
        _announce(
          ports.isEmpty
              ? '« ${_nodeName(source)} » n’a plus de sortie libre.'
              : 'Aucun bloc ne peut recevoir cette liaison.',
        );
        return KeyEventResult.handled;
      }
      setState(() {
        _keyboardLink = true;
        _wireNode = source;
        _wirePort = ports.first;
        _showKeyboardTarget(targets.first);
      });
      _announce(
        'Liaison depuis « ${_nodeName(source)} », sortie ${scenePortLabel(ports.first)}, '
        'vers « ${_nodeName(targets.first)} ». L : autre sortie, Tab : autre cible, '
        'Entrée : relier, Échap : annuler.',
      );
      return KeyEventResult.handled;
    }
    final from = _wireNode!;
    if (key == LogicalKeyboardKey.keyL) {
      final ports = _freePorts(from);
      final next = ports[(ports.indexOf(_wirePort!) + 1) % ports.length];
      setState(() => _wirePort = next);
      _announce('Sortie ${scenePortLabel(next)}.');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      final targets = _targets(from);
      final back =
          HardwareKeyboard.instance.isShiftPressed ||
          key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowUp;
      final index = targets.indexOf(_target!);
      final next =
          targets[(index + (back ? targets.length - 1 : 1)) % targets.length];
      setState(() => _showKeyboardTarget(next));
      _announce('Cible « ${_nodeName(next)} ».');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final port = _wirePort!, target = _target!;
      setState(_clearGesture);
      widget.onConnect(from, port, target);
      _announce(
        '« ${_nodeName(from)} », sortie ${scenePortLabel(port)}, relié à « ${_nodeName(target)} ».',
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Offset _local(Offset global) =>
      (_canvasKey.currentContext!.findRenderObject() as RenderBox)
          .globalToLocal(global);
  void _select(String id) {
    _focus.requestFocus();
    widget.onSelectNode(id);
  }

  void _startDrag(String id) {
    if (_wireNode != null) return;
    _select(id);
    setState(() {
      _dragNode = id;
      _positions[id] = _geometry.positions[id]!;
    });
  }

  void _moveDrag(Offset delta) {
    final id = _dragNode;
    if (id == null) return;
    setState(
      () => _positions[id] = _positions[id]! + delta / widget.viewport.zoom,
    );
  }

  void _endDrag() {
    final id = _dragNode;
    final point = _positions[id];
    setState(() {
      _positions.clear();
      _dragNode = null;
    });
    if (id != null && point != null && point != _geometry.positions[id]) {
      widget.onMoveNode(id, point);
    }
  }

  void _startWire(String id, String port) {
    if (_geometry.occupied.contains('$id:$port')) return;
    _select(id);
    setState(() {
      _wireNode = id;
      _wirePort = port;
      _wireEnd = widget.viewport.worldToLocal(
        _geometry.output(id, port, _positions),
      );
    });
  }

  void _moveWire(Offset global) {
    final id = _wireNode;
    if (id == null) return;
    final local = _local(global);
    setState(() {
      _target = _geometry.targetAt(local, widget.viewport, _positions, id);
      _wireEnd = _target == null
          ? local
          : widget.viewport.worldToLocal(_geometry.input(_target!, _positions));
    });
  }

  void _endWire() {
    final source = _wireNode, port = _wirePort, target = _target;
    _cancel();
    if (source != null && port != null && target != null) {
      widget.onConnect(source, port, target);
    }
  }

  Future<void> _menu(Offset local) async {
    final revision = ++_menuRevision;
    final source = _wireNode, port = _wirePort;
    _cancel();
    final block = await showSceneCanvasMenu(context, widget.availableBlocks);
    if (!mounted || revision != _menuRevision || block == null) return;
    widget.onAdd(
      block,
      widget.viewport.localToWorld(local),
      fromNodeId: source,
      fromPortId: port,
    );
    _focus.requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final control =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (!control && _keyboardLinkKey(key) == KeyEventResult.handled) {
      return KeyEventResult.handled;
    }
    if (control && key == LogicalKeyboardKey.keyZ) {
      (HardwareKeyboard.instance.isShiftPressed ? widget.onRedo : widget.onUndo)
          ?.call();
      return KeyEventResult.handled;
    }
    if (control && key == LogicalKeyboardKey.keyS) {
      widget.onSave?.call();
      return KeyEventResult.handled;
    }
    if (control && key == LogicalKeyboardKey.keyD) {
      widget.onDuplicate?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      widget.onDelete?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space ||
        (control && key == LogicalKeyboardKey.keyK)) {
      _menu(_wireEnd ?? widget.viewport.size.center(Offset.zero));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    onKeyEvent: _key,
    child: SceneCanvasSurface(
      canvasKey: _canvasKey,
      geometry: _geometry,
      viewport: widget.viewport,
      positions: _positions,
      selectedNodeId: widget.selectedNodeId,
      selectedEdgeId: widget.selectedEdgeId,
      sourceNodeId: _wireNode,
      targetNodeId: _target,
      previewStart: _wireNode == null
          ? null
          : widget.viewport.worldToLocal(
              _geometry.output(_wireNode!, _wirePort!, _positions),
            ),
      previewEnd: _wireEnd,
      highlightedNodes: widget.highlightedNodeIds,
      highlightedEdges: widget.highlightedEdgeIds,
      summary: widget.nodeSummary,
      onSelect: _select,
      onDragStart: _startDrag,
      onDragMove: _moveDrag,
      onDragEnd: _endDrag,
      onCancel: _cancel,
      onWireStart: _startWire,
      onWireMove: _moveWire,
      onWireEnd: _endWire,
      onBackgroundTap: (point) {
        _focus.requestFocus();
        final edge = sceneEdgeAt(_geometry, widget.viewport, _positions, point);
        if (edge == null) {
          widget.onClearSelection();
        } else {
          widget.onSelectEdge(edge);
        }
      },
      onContext: _menu,
      onDrop: (block, global) {
        _focus.requestFocus();
        widget.onAdd(block, widget.viewport.localToWorld(_local(global)));
      },
      onSize: (size) {
        widget.viewport.size = size;
        if (!widget.viewport.initialized && widget.fitOnFirstLayout) {
          widget.viewport.initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.viewport.fit(_geometry.bounds(_positions));
          });
        }
      },
      showMinimap: _minimap,
      onToggleMinimap: () => setState(() => _minimap = !_minimap),
    ),
  );
}
