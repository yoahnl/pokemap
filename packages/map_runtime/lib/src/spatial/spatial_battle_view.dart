import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../presentation/flame/runtime_input_event.dart';
import 'spatial_battle_runtime.dart';

class SpatialBattleView extends StatefulWidget {
  const SpatialBattleView(
      {super.key, required this.runtime, this.keyboardInputEnabled = true});

  final SpatialBattleRuntime runtime;
  final bool keyboardInputEnabled;

  @override
  State<SpatialBattleView> createState() => _SpatialBattleViewState();
}

class _SpatialBattleViewState extends State<SpatialBattleView>
    with WidgetsBindingObserver {
  late final SpatialBattlePresentation game;
  bool pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    game = SpatialBattlePresentation(widget.runtime);
    widget.runtime.addListener(changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (pausedByLifecycle) widget.runtime.resume(owner: this);
      pausedByLifecycle = false;
    } else if (!pausedByLifecycle) {
      pausedByLifecycle = true;
      widget.runtime.pause(owner: this);
    }
  }

  KeyEventResult handleKey(FocusNode _, KeyEvent event) {
    if (!widget.keyboardInputEnabled) return KeyEventResult.ignored;
    final control = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp ||
      LogicalKeyboardKey.keyW =>
        RuntimeInputControl.up,
      LogicalKeyboardKey.arrowDown ||
      LogicalKeyboardKey.keyS =>
        RuntimeInputControl.down,
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.keyA =>
        RuntimeInputControl.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD =>
        RuntimeInputControl.right,
      LogicalKeyboardKey.enter ||
      LogicalKeyboardKey.space =>
        RuntimeInputControl.primary,
      LogicalKeyboardKey.escape => RuntimeInputControl.secondary,
      _ => null,
    };
    if (control == null) return KeyEventResult.ignored;
    final input = event is KeyUpEvent
        ? RuntimeInputEvent.release(control)
        : RuntimeInputEvent.press(control, isRepeat: event is KeyRepeatEvent);
    return widget.runtime.handleInput(input)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
      absorbing: widget.runtime.isPaused,
      child: Focus(
          autofocus: widget.keyboardInputEnabled,
          onKeyEvent: handleKey,
          child: GameWidget(game: game, autofocus: false)));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.runtime.removeListener(changed);
    widget.runtime.resume(owner: this);
    widget.runtime.cancel();
    game.dispose();
    super.dispose();
  }
}

final class SpatialBattlePresentation extends FlameGame {
  SpatialBattlePresentation(this.runtime) {
    images = Images();
    assets = AssetsCache();
  }

  final SpatialBattleRuntime runtime;
  final Set<Component> mountedOverlays = {};
  bool stopped = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (stopped) return;
    runtime.addListener(sync);
    sync();
  }

  void sync() {
    if (stopped) return;
    mountedOverlays.removeWhere((overlay) =>
        overlay != runtime.battleOverlay &&
        overlay != runtime.postBattleOverlay);
    if (!runtime.isActive) processLifecycleEvents();
    if (runtime.isPaused || !runtime.isActive) {
      pauseEngine();
    } else {
      resumeEngine();
    }
    for (final overlay in [runtime.battleOverlay, runtime.postBattleOverlay]) {
      if (overlay == null || !mountedOverlays.add(overlay)) continue;
      overlay.onGameResize(camera.viewport.size);
      unawaited(Future<void>.sync(() async {
        await camera.viewport.add(overlay);
      }).then((_) {
        if (stopped ||
            (overlay != runtime.battleOverlay &&
                overlay != runtime.postBattleOverlay)) {
          overlay.removeFromParent();
        }
      }).catchError((Object failure) {
        if (!stopped &&
            (overlay == runtime.battleOverlay ||
                overlay == runtime.postBattleOverlay)) {
          runtime.reportPresentationFailure(failure);
        }
      }));
    }
  }

  @override
  void dispose() {
    if (stopped) return;
    stopped = true;
    runtime.removeListener(sync);
    pauseEngine();
    super.dispose();
  }
}
