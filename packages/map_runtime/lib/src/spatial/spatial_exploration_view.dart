import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'spatial_exploration_session.dart';

class SpatialExplorationView extends StatefulWidget {
  const SpatialExplorationView({super.key, required this.session,
    this.keyboardInputEnabled = true, this.onReady, this.onError});
  final SpatialExplorationSession session;
  final bool keyboardInputEnabled;
  final VoidCallback? onReady;
  final void Function(Object)? onError;
  @override
  State<SpatialExplorationView> createState() => _SpatialExplorationViewState();
}

class _SpatialExplorationViewState extends State<SpatialExplorationView>
    with WidgetsBindingObserver {
  final focus = FocusNode();
  final camera = SpatialSceneController()..setView(SpatialEditorView.game);
  final keys = <LogicalKeyboardKey>{};
  int inputEpoch = -1;
  void release() {
    keys.clear();
    if (widget.keyboardInputEnabled) widget.session.movement.releaseInput();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) release();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (!widget.keyboardInputEnabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (inputEpoch != widget.session.movement.inputEpoch) {
      keys.clear();
      inputEpoch = widget.session.movement.inputEpoch;
    }
    if (event is KeyRepeatEvent && !keys.contains(key)) {
      return KeyEventResult.handled;
    }
    final supported = {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight
    };
    if (!supported.contains(key)) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    bool pressed(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        keys.contains(a) || keys.contains(b);
    widget.session.movement.setInput(
        x: (pressed(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)
                ? 1
                : 0) -
            (pressed(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyQ)
                ? 1
                : 0),
        z: (pressed(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)
                ? 1
                : 0) -
            (pressed(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyZ)
                ? 1
                : 0),
        run: keys.contains(LogicalKeyboardKey.shiftLeft) ||
            keys.contains(LogicalKeyboardKey.shiftRight));
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    release();
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
        autofocus: widget.keyboardInputEnabled,
        focusNode: focus,
        onFocusChange: (value) {
          if (!value) release();
        },
        onKeyEvent: onKey,
        child: Listener(
            onPointerDown: (_) { if (widget.keyboardInputEnabled) focus.requestFocus(); },
            child: SpatialSceneView(
                scene: widget.session.bundle.map.spatialScene!,
                models: widget.session.bundle.manifest.models3d,
                loadModel: (id) async =>
                    Uint8List.fromList(await widget.session.modelBytes(id)),
                controller: camera,
                onCell: (_, __) { if (widget.keyboardInputEnabled) focus.requestFocus(); },
                onReady: widget.onReady,
                actorFrame: widget.session.frame,
                background: colors.surfaceContainerLowest,
                ground: colors.primaryContainer,
                edge: colors.outlineVariant,
                errorBuilder: (_, error) {
                  widget.onError?.call(error);
                  return Center(child: Text('Erreur d’exploration 3D : $error'));
                })));
  }
}
