import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'story_graph_connection.dart';
import 'story_graph_controls.dart';
import 'story_graph_geometry.dart';
import 'story_graph_layer.dart';
import 'story_graph_painter.dart';
import 'story_view_state.dart';
export 'story_view_state.dart';
part 'story_graph_surface.dart';

class StoryGraphCanvas extends StatefulWidget {
  const StoryGraphCanvas({
    super.key,
    required this.project,
    required this.storyId,
    required this.viewState,
    required this.onSelect,
    required this.onConnect,
    required this.onDisconnect,
    required this.onAddStep,
    this.selection,
    this.onOpenScene,
  });
  final ProjectManifest project;
  final String storyId;
  final StoryViewState viewState;
  final StoryGraphSelection? selection;
  final ValueChanged<StoryGraphSelection?> onSelect;
  final ValueChanged<StorylineProgressionConnectRequest> onConnect;
  final ValueChanged<StorylineProgressionEdge> onDisconnect;
  final ValueChanged<String> onAddStep;
  final ValueChanged<String>? onOpenScene;
  @override
  State<StoryGraphCanvas> createState() => _StoryGraphCanvasState();
}

class _StoryGraphCanvasState extends State<StoryGraphCanvas> {
  final _key = GlobalKey();
  final _focus = FocusNode();
  late StoryGraphGeometry _graph;
  int _sourcesRevision = -1;
  double _textScale = 1;
  String? _dragId, _targetId;
  Offset? _dragPosition, _wireEnd;
  StorylineProgressionNode? _source;
  int _generation = 0;
  StoryViewState get _state => widget.viewState;
  Map<String, Offset> get _positions => {
    ..._state.positions,
    if (_dragId != null && _dragPosition != null) _dragId!: _dragPosition!,
  };
  @override
  void initState() {
    super.initState();
    _refresh();
    _state.addListener(_changed);
  }

  void _rebuild(VoidCallback operation) => setState(operation);

  void _refresh() {
    _graph = StoryGraphGeometry(
      widget.project,
      widget.storyId,
      _state,
      textScale: _textScale,
    );
    _sourcesRevision = _state.sourcesRevision;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (_textScale != scale) {
      _textScale = scale;
      _refresh();
    }
  }

  @override
  void didUpdateWidget(covariant StoryGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewState != _state) {
      oldWidget.viewState.removeListener(_changed);
      _state.addListener(_changed);
    }
    if (!identical(oldWidget.project, widget.project) ||
        oldWidget.storyId != widget.storyId ||
        oldWidget.viewState != _state) {
      _generation++;
      _source = null;
      _targetId = null;
      _dragId = null;
      _refresh();
    }
  }

  void _changed() {
    if (_sourcesRevision != _state.sourcesRevision) _refresh();
    final reveal = _state.revealId;
    if (reveal != null) {
      _state.revealId = null;
      if (_graph.nodes.containsKey(reveal)) {
        _state.viewport.centerOn(_graph.rect(reveal, _positions).center);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  Offset _local(Offset global) =>
      (_key.currentContext!.findRenderObject() as RenderBox).globalToLocal(
        global,
      );
  void _cancel() => setState(() {
    _source = null;
    _targetId = null;
    _wireEnd = null;
    _dragId = null;
    _dragPosition = null;
    _generation++;
  });
  void _wireMove(Offset global) {
    if (_source == null) return;
    final local = _local(global);
    String? target;
    for (final node in _graph.nodes.values) {
      if (_graph.canTarget(_source!, node) &&
          (_state.viewport.worldToLocal(_graph.input(node.id, _positions)) -
                      local)
                  .distance <=
              24) {
        target = node.id;
        break;
      }
    }
    setState(() {
      _wireEnd = local;
      _targetId = target;
    });
  }

  Future<void> _wireFinish() async {
    final source = _source, target = _graph.nodes[_targetId];
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final global = box.localToGlobal(_wireEnd ?? Offset.zero);
    _cancel();
    if (source == null || target == null) return;
    final generation = _generation;
    final request = await chooseStoryGraphConnection(
      context,
      _graph,
      source,
      target,
      global,
    );
    if (mounted && generation == _generation && request != null) {
      widget.onConnect(request);
    }
  }

  KeyEventResult _keyboard(FocusNode node, KeyEvent event) {
    if (!_focus.hasPrimaryFocus || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    if ((keyboard.isMetaPressed || keyboard.isControlPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      keyboard.isShiftPressed ? _state.redo() : _state.undo();
      return KeyEventResult.handled;
    }
    final edge = widget.selection?.edge;
    if ((event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) &&
        edge != null) {
      final matches = _graph.edges.where((e) => e.id == edge.id);
      if (matches.isNotEmpty &&
          matches.first.editability ==
              StorylineProgressionEdgeEditability.reversible) {
        widget.onDisconnect(matches.first);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => _surface(context);
}
