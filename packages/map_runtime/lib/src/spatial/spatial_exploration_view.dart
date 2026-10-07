import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'spatial_exploration_session.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';

class SpatialExplorationView extends StatefulWidget {
  const SpatialExplorationView(
      {super.key,
      required this.session,
      this.keyboardInputEnabled = true,
      this.onReady,
      this.onError});
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
    widget.session.setLifecyclePaused(state != AppLifecycleState.resumed);
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
    if (key == LogicalKeyboardKey.keyE ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        if (key == LogicalKeyboardKey.escape) {
          widget.session.closeDialogue();
        } else if (widget.session.dialoguePresentation.value
            case final snapshot?) {
          widget.session.dispatchDialogueCommand(
              DialogueAdvanceCommand(snapshotRevision: snapshot.revision));
        } else {
          widget.session.interact();
        }
      }
      return KeyEventResult.handled;
    }
    if (widget.session.interactionActive.value) return KeyEventResult.handled;
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
            onPointerDown: (_) {
              if (widget.keyboardInputEnabled) focus.requestFocus();
            },
            child: Stack(children: [
              Positioned.fill(
                  child: SpatialSceneView(
                      scene: widget.session.bundle.map.spatialScene!,
                      groundMap: widget.session.bundle.map,
                      groundProject: widget.session.bundle.manifest,
                      loadGroundImage: widget.session.groundImageBytes,
                      models: widget.session.bundle.manifest.models3d,
                      loadModel: (id) async => Uint8List.fromList(
                          await widget.session.modelBytes(id)),
                      controller: camera,
                      onCell: (_, __) {
                        if (widget.keyboardInputEnabled) focus.requestFocus();
                      },
                      onReady: widget.onReady,
                      actorFrames: widget.session.frames,
                      background: colors.surfaceContainerLowest,
                      ground: colors.primaryContainer,
                      edge: colors.outlineVariant,
                      errorBuilder: (_, error) {
                        widget.onError?.call(error);
                        return Center(
                            child: Text('Erreur d’exploration 3D : $error'));
                      })),
              Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ValueListenableBuilder<Object?>(
                    valueListenable: widget.session.interactionError,
                    builder: (context, error, _) => error == null
                        ? const SizedBox.shrink()
                        : ColoredBox(
                            color: colors.errorContainer,
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                    'Ce dialogue ne peut pas être ouvert.',
                                    style: TextStyle(
                                        color: colors.onErrorContainer)))),
                  )),
            ])));
  }
}
