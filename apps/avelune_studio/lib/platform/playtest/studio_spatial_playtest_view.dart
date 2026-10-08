import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

class StudioSpatialPlaytestView extends StatefulWidget {
  const StudioSpatialPlaytestView({
    super.key,
    required this.runtime,
    this.onReady,
    this.onError,
    this.sceneBuilder,
  });

  final SpatialExplorationGameSessionRuntime runtime;
  final VoidCallback? onReady;
  final void Function(Object)? onError;
  final WidgetBuilder? sceneBuilder;

  @override
  State<StudioSpatialPlaytestView> createState() =>
      _StudioSpatialPlaytestViewState();
}

class _StudioSpatialPlaytestViewState extends State<StudioSpatialPlaytestView>
    with WidgetsBindingObserver {
  final _focus = FocusNode();
  final _pressed = <RuntimeInputControl>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _releaseInput() {
    for (final control in _pressed) {
      widget.runtime.handleInput(RuntimeInputEvent.release(control));
    }
    _pressed.clear();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    final input = PlayerControlProfile.standard.runtimeEventFromKeyEvent(event);
    if (input == null) return KeyEventResult.ignored;
    if (input.isPress) {
      _pressed.add(input.control);
    } else {
      _pressed.remove(input.control);
    }
    return widget.runtime.handleInput(input)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _releaseInput();
    unawaited(
      widget.runtime.setInputLock(
        RuntimeExternalInputLock.lifecycle,
        locked: state != AppLifecycleState.resumed,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseInput();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = widget.runtime;
    final session = runtime.session!;
    return ClipRect(
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (!focused) _releaseInput();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _focus.requestFocus,
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    widget.sceneBuilder?.call(context) ??
                    SpatialExplorationView(
                      key: ObjectKey(runtime),
                      session: session,
                      keyboardInputEnabled: false,
                      onReady: widget.onReady,
                      onError: widget.onError,
                    ),
              ),
              if (runtime.battle case final battle?)
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: battle,
                    builder: (context, _) => battle.isActive
                        ? SpatialBattleView(
                            key: ObjectKey(battle),
                            runtime: battle,
                            keyboardInputEnabled: false,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: Theme(
                  data: Theme.of(context).brightness == Brightness.dark
                      ? PokeMapPlayerTheme.dark()
                      : PokeMapPlayerTheme.light(),
                  child: Stack(
                    children: [
                      ValueListenableBuilder<DialoguePresentationSnapshot?>(
                        valueListenable: runtime.dialoguePresentationListenable,
                        builder: (context, snapshot, _) => snapshot == null
                            ? const SizedBox.shrink()
                            : PlayerDialogueOverlay(
                                snapshot: snapshot,
                                onCommand:
                                    runtime.dispatchDialoguePresentationCommand,
                              ),
                      ),
                      StreamBuilder<RuntimeWorldServiceSnapshot?>(
                        stream: runtime.worldServiceSnapshots,
                        initialData: runtime.worldServiceSnapshot,
                        builder: (context, snapshot) {
                          final service = snapshot.data;
                          if (service == null) return const SizedBox.shrink();
                          void command(RuntimeWorldServiceCommand value) {
                            unawaited(runtime.dispatchWorldService(value));
                          }

                          return switch (service.request.kind) {
                            RuntimeWorldServiceKind.heal =>
                              PlayerHealConfirmation(
                                snapshot: service,
                                onCommand: command,
                              ),
                            RuntimeWorldServiceKind.shop => PlayerShopOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                            RuntimeWorldServiceKind.pc => PlayerPcOverlay(
                              snapshot: service,
                              onCommand: command,
                            ),
                          };
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<Object?>(
                valueListenable: session.interactionError,
                builder: (context, error, _) => error == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.topCenter,
                        child: Text('L’interaction a été interrompue : $error'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
