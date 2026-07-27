import 'dart:async';
import 'dart:ui' as ui show KeyEventDeviceType;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_text_scaler.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_title_screen.dart';
import 'player_dialogue_overlay.dart';
import 'player_heal_confirmation.dart';
import 'player_new_game_identity.dart';
import 'player_pc_overlay.dart';
import 'player_shop_overlay.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_gamepad_bridge.dart';
import 'runtime_player_surface_router.dart';
import 'runtime_player_touch_controls.dart';

/// Small presentation-facing subset of the runtime player coordinator.
///
/// Tests and standalone hosts can provide this contract without importing the
/// Hub or exposing package installation details to the player UI.
abstract interface class RuntimePlayerViewController {
  RuntimePlayerSnapshot get snapshot;

  Stream<RuntimePlayerSnapshot> get snapshots;

  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command);

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  );
}

/// Adapter for the canonical in-process runtime coordinator.
final class RuntimePlayerCoordinatorViewController
    implements RuntimePlayerViewController {
  const RuntimePlayerCoordinatorViewController(this.coordinator);

  final RuntimePlayerCoordinator coordinator;

  @override
  RuntimePlayerSnapshot get snapshot => coordinator.snapshot;

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => coordinator.snapshots;

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) =>
      coordinator.dispatch(command);

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) =>
      coordinator.dispatchWorldService(command);
}

typedef RuntimePlayerActionPayloadBuilder = Object? Function(
  RuntimePlayerAction action,
);

/// Canonical Flutter host for one runtime-owned player session.
///
/// The widget only renders [RuntimePlayerSnapshot] values and sends versioned
/// commands back. It never derives a phase from Hub state.
class PokeMapPlayerSessionView extends StatefulWidget {
  const PokeMapPlayerSessionView({
    super.key,
    required this.controller,
    required this.titlePresentation,
    required this.gameSceneBuilder,
    this.payloadForAction,
    this.onShowDiagnostics,
    this.gameplayInputRoute,
    this.touchControlsAvailable,
    this.controllerInputEnabled = true,
    this.controllerInputEvents,
    this.gameplayInputAuthority,
    this.dialoguePresentation,
    this.onDialogueCommand,
    this.hapticFeedback,
  });

  final RuntimePlayerViewController controller;
  final RuntimePlayerTitlePresentation titlePresentation;

  /// Builds the runtime scene below the player surfaces.
  ///
  /// A hosted [GameWidget] must use `autofocus: false`: this session view owns
  /// the single hardware keyboard/controller focus ingress.
  final WidgetBuilder gameSceneBuilder;
  final RuntimePlayerActionPayloadBuilder? payloadForAction;
  final VoidCallback? onShowDiagnostics;
  final PlayerGameplayInputRoute? gameplayInputRoute;

  /// Overrides platform detection in embedders and widget tests.
  ///
  /// Production players normally leave this null: touch controls are then
  /// enabled on iOS and Android only.
  final bool? touchControlsAvailable;

  /// Keeps controller plugin access injectable and optional for standalone
  /// embedders while remaining enabled in the official player by default.
  final bool controllerInputEnabled;
  final Stream<RuntimeInputEvent>? controllerInputEvents;

  /// Runtime-owned authority deciding whether overworld touch chrome is legal.
  final ValueListenable<RuntimeInputAuthoritySnapshot>? gameplayInputAuthority;

  /// Optional Flutter dialogue projection published by the mounted runtime.
  final ValueListenable<DialoguePresentationSnapshot?>? dialoguePresentation;
  final ValueChanged<DialoguePresentationCommand>? onDialogueCommand;
  final Future<void> Function()? hapticFeedback;

  @override
  State<PokeMapPlayerSessionView> createState() =>
      _PokeMapPlayerSessionViewState();
}

class _PokeMapPlayerSessionViewState extends State<PokeMapPlayerSessionView> {
  StreamSubscription<RuntimeInputEvent>? _controllerSubscription;
  late RuntimePlayerSnapshot _latestSnapshot;
  bool _menuTransitionPending = false;

  bool get _touchControlsAvailable =>
      widget.touchControlsAvailable ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android));

  @override
  void initState() {
    super.initState();
    _latestSnapshot = widget.controller.snapshot;
    _bindControllerInputs();
  }

  @override
  void didUpdateWidget(covariant PokeMapPlayerSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _latestSnapshot = widget.controller.snapshot;
    }
    if (oldWidget.controllerInputEnabled != widget.controllerInputEnabled ||
        oldWidget.controllerInputEvents != widget.controllerInputEvents) {
      _bindControllerInputs();
    }
  }

  void _bindControllerInputs() {
    unawaited(_controllerSubscription?.cancel());
    _controllerSubscription = null;
    if (!widget.controllerInputEnabled) return;
    final events =
        widget.controllerInputEvents ?? _normalizedControllerInputEvents();
    _controllerSubscription = events.listen(
      (event) => unawaited(
        _routeRuntimeInput(event, source: PlayerInputSource.controller),
      ),
      onError: (_, __) {
        // A missing or disconnected platform controller must never block
        // keyboard, pointer, or touch play.
      },
    );
  }

  Stream<RuntimeInputEvent> _normalizedControllerInputEvents() async* {
    final bridge = RuntimePlayerGamepadBridge();
    await for (final event in Gamepads.normalizedEvents) {
      for (final runtimeEvent in bridge.handle(event)) {
        yield runtimeEvent;
      }
    }
  }

  PlayerInputSurface _inputSurface() {
    // Menu opening/closing is asynchronous because the runtime first acquires
    // its typed pause lock. Treat that hand-off as blocked immediately so a
    // second key/controller event cannot leak into the world meanwhile.
    if (_menuTransitionPending) return PlayerInputSurface.blocked;
    final snapshot = _latestSnapshot;
    if (snapshot.worldService != null) return PlayerInputSurface.title;
    return switch (snapshot.phase) {
      RuntimePlayerPhase.playing => PlayerInputSurface.gameplay,
      RuntimePlayerPhase.title => PlayerInputSurface.title,
      RuntimePlayerPhase.paused => PlayerInputSurface.pause,
      RuntimePlayerPhase.result => PlayerInputSurface.result,
      RuntimePlayerPhase.credits => PlayerInputSurface.credits,
      RuntimePlayerPhase.boot ||
      RuntimePlayerPhase.preparingSession ||
      RuntimePlayerPhase.loadingSession ||
      RuntimePlayerPhase.saving ||
      RuntimePlayerPhase.lifecyclePaused ||
      RuntimePlayerPhase.completing ||
      RuntimePlayerPhase.disposingSession ||
      RuntimePlayerPhase.externalExit ||
      RuntimePlayerPhase.error =>
        PlayerInputSurface.blocked,
    };
  }

  Future<void> _routeRuntimeInput(
    RuntimeInputEvent event, {
    required PlayerInputSource source,
  }) async {
    final router = PlayerInputRouter(
      surface: _inputSurface,
      routeGameplay: widget.gameplayInputRoute ?? (_) => false,
      routeSurface: _routeSurfaceInput,
      toggleMenu: _toggleMenu,
      releaseGameplayDirections: _releaseGameplayDirections,
    );
    final command = playerInputCommandFromRuntimeEvent(event, source: source);
    final surface = _inputSurface();
    final handled = await router.route(command);
    final directional = command.action == PlayerInputAction.up ||
        command.action == PlayerInputAction.down ||
        command.action == PlayerInputAction.left ||
        command.action == PlayerInputAction.right;
    if (handled &&
        command.isPress &&
        !command.isRepeat &&
        command.action != PlayerInputAction.menu &&
        (surface == PlayerInputSurface.gameplay || directional)) {
      await _performHaptic();
    }
  }

  KeyEventResult _routeHardwareKeyEvent(FocusNode node, KeyEvent event) {
    final runtimeEvent = runtimeInputEventFromKeyEvent(event);
    if (runtimeEvent == null) return KeyEventResult.ignored;
    final isHardwareGamepad = event.deviceType == ui.KeyEventDeviceType.gamepad;
    if (isHardwareGamepad && widget.controllerInputEnabled) {
      // The normalized gamepad stream is authoritative while enabled. Some
      // platforms also expose controller buttons as hardware keys; consuming
      // that duplicate path prevents one press from being routed twice.
      return KeyEventResult.handled;
    }
    unawaited(
      _routeRuntimeInput(
        runtimeEvent,
        source: isHardwareGamepad
            ? PlayerInputSource.controller
            : PlayerInputSource.keyboard,
      ),
    );
    return KeyEventResult.handled;
  }

  void _releaseGameplayDirections() {
    final route = widget.gameplayInputRoute;
    if (route == null) return;
    for (final control in const <RuntimeInputControl>[
      RuntimeInputControl.up,
      RuntimeInputControl.down,
      RuntimeInputControl.left,
      RuntimeInputControl.right,
    ]) {
      route(RuntimeInputEvent.release(control));
    }
  }

  Future<void> _toggleMenu() async {
    final snapshot = _latestSnapshot;
    final action = switch (snapshot.phase) {
      RuntimePlayerPhase.playing => RuntimePlayerAction.openMenu,
      RuntimePlayerPhase.paused => RuntimePlayerAction.resume,
      _ => null,
    };
    if (action == null) return;
    await _dispatchAction(action);
  }

  Future<void> _routeSurfaceInput(PlayerInputCommand command) async {
    if (!command.isPress) return;
    final snapshot = _latestSnapshot;
    if (snapshot.phase == RuntimePlayerPhase.paused) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext != null) {
        Actions.invoke(
          focusContext,
          RuntimePlayerLogicalIntent(
            command.action,
            source: command.source,
          ),
        );
        return;
      }
    }
    switch (command.action) {
      case PlayerInputAction.up:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.up);
      case PlayerInputAction.down:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.down);
      case PlayerInputAction.left:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.left);
      case PlayerInputAction.right:
        FocusManager.instance.primaryFocus
            ?.focusInDirection(TraversalDirection.right);
      case PlayerInputAction.confirm:
        final focusContext = FocusManager.instance.primaryFocus?.context;
        if (focusContext != null) {
          Actions.invoke(focusContext, const ActivateIntent());
        }
      case PlayerInputAction.back:
        await _dispatchBack();
      case PlayerInputAction.menu:
        // Menu/Start is intercepted by PlayerInputRouter.
        break;
    }
  }

  Future<void> _dispatchBack() async {
    final snapshot = _latestSnapshot;
    if (snapshot.worldService case final service?) {
      final action = service.isActionEnabled(RuntimeWorldServiceAction.close)
          ? RuntimeWorldServiceAction.close
          : service.isActionEnabled(RuntimeWorldServiceAction.cancel)
              ? RuntimeWorldServiceAction.cancel
              : null;
      if (action != null) {
        await widget.controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: action,
            snapshotRevision: service.revision,
          ),
        );
      }
      return;
    }
    final action = switch (snapshot.phase) {
      RuntimePlayerPhase.title
          when snapshot.pauseSection == RuntimePlayerPauseSection.options =>
        RuntimePlayerAction.returnToTitle,
      RuntimePlayerPhase.title => RuntimePlayerAction.returnToHost,
      RuntimePlayerPhase.paused
          when snapshot.pauseSection != null &&
              snapshot.pauseSection != RuntimePlayerPauseSection.root =>
        RuntimePlayerAction.returnToPauseRoot,
      RuntimePlayerPhase.paused => RuntimePlayerAction.resume,
      RuntimePlayerPhase.credits => snapshot.isActionEnabled(
          RuntimePlayerAction.finishCredits,
        )
            ? RuntimePlayerAction.finishCredits
            : RuntimePlayerAction.returnToTitle,
      _ => null,
    };
    if (action != null) await _dispatchAction(action);
  }

  Future<void> _dispatchAction(RuntimePlayerAction action) async {
    final snapshot = _latestSnapshot;
    if (!snapshot.isActionEnabled(action)) return;
    await _dispatchCommand(action, snapshot);
  }

  Future<RuntimePlayerCommandResult> _dispatchSurfaceAction(
    RuntimePlayerAction action,
    RuntimePlayerSnapshot snapshot,
  ) async {
    final identityPresentation = widget.titlePresentation.newGameIdentity;
    if (action != RuntimePlayerAction.newGame || identityPresentation == null) {
      return _dispatchCommand(action, snapshot);
    }
    final slot = widget.payloadForAction?.call(action);
    if (slot is! RuntimePlayerLoadSlot) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'A profile and slot are required for a new game.',
      );
    }
    final identity = await showDialog<GameSessionPlayerIdentity>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PlayerNewGameIdentityDialog(
        presentation: identityPresentation,
      ),
    );
    if (identity == null) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
    return _dispatchCommand(
      action,
      snapshot,
      payload: RuntimePlayerNewGameSetup(slot: slot, identity: identity),
    );
  }

  Future<RuntimePlayerCommandResult> _dispatchCommand(
    RuntimePlayerAction action,
    RuntimePlayerSnapshot snapshot, {
    Object? payload,
  }) async {
    final isMenuTransition = action == RuntimePlayerAction.openMenu ||
        action == RuntimePlayerAction.resume;
    if (isMenuTransition && _menuTransitionPending) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'The player menu is already changing state.',
      );
    }
    if (isMenuTransition) _menuTransitionPending = true;
    try {
      final result = await widget.controller.dispatch(
        RuntimePlayerCommand(
          action: action,
          snapshotRevision: snapshot.revision,
          payload: payload ?? widget.payloadForAction?.call(action),
        ),
      );
      if (result.status == RuntimePlayerCommandStatus.accepted) {
        await _performHaptic();
      }
      return result;
    } finally {
      if (isMenuTransition) _menuTransitionPending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: const ValueKey<String>('runtime-player-keyboard-input-authority'),
      autofocus: true,
      onKeyEvent: _routeHardwareKeyEvent,
      child: StreamBuilder<RuntimePlayerSnapshot>(
        stream: widget.controller.snapshots,
        initialData: widget.controller.snapshot,
        builder: (context, asyncSnapshot) {
          final snapshot = asyncSnapshot.data ?? widget.controller.snapshot;
          _latestSnapshot = snapshot;
          final authority = widget.gameplayInputAuthority;
          if (authority == null) {
            return _buildSessionStack(
              snapshot,
              const RuntimeInputAuthoritySnapshot(
                context: RuntimeInputContext.overworld,
              ),
            );
          }
          return ValueListenableBuilder<RuntimeInputAuthoritySnapshot>(
            valueListenable: authority,
            builder: (context, inputAuthority, _) => _buildSessionStack(
              snapshot,
              inputAuthority,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionStack(
    RuntimePlayerSnapshot snapshot,
    RuntimeInputAuthoritySnapshot inputAuthority,
  ) {
    final acceptsOverworldTouch = inputAuthority.acceptsOverworldInput;
    final showTouchControls = _touchControlsAvailable &&
        widget.gameplayInputRoute != null &&
        snapshot.phase == RuntimePlayerPhase.playing &&
        snapshot.worldService == null &&
        acceptsOverworldTouch;
    final touchControlsOpacity =
        snapshot.preferences?.touchControlsOpacity ?? 0.82;
    final stack = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RuntimePlayerSurfaceRouter(
          snapshot: snapshot,
          titlePresentation: widget.titlePresentation,
          gameSceneBuilder: widget.gameSceneBuilder,
          onShowDiagnostics: widget.onShowDiagnostics,
          gameplayTouchMenuEnabled: acceptsOverworldTouch,
          touchControlsOpacity: touchControlsOpacity,
          onPreferencesChanged: (preferences) => widget.controller.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.updatePreferences,
              snapshotRevision: snapshot.revision,
              payload: preferences,
            ),
          ),
          onPauseCommand: (command) => unawaited(
            _dispatchCommand(
              RuntimePlayerAction.useBagItem,
              snapshot,
              payload: command,
            ),
          ),
          onAction: (action) => _dispatchSurfaceAction(action, snapshot),
        ),
        if (showTouchControls)
          Positioned.fill(
            child: RuntimePlayerTouchControls(
              opacity: touchControlsOpacity,
              dispatch: (event) => unawaited(
                _routeRuntimeInput(
                  event,
                  source: PlayerInputSource.touch,
                ),
              ),
            ),
          ),
        if (widget.dialoguePresentation case final dialogue?)
          ValueListenableBuilder<DialoguePresentationSnapshot?>(
            valueListenable: dialogue,
            builder: (context, presentation, _) {
              final onCommand = widget.onDialogueCommand;
              if (presentation == null || onCommand == null) {
                return const SizedBox.shrink();
              }
              return PlayerDialogueOverlay(
                snapshot: presentation,
                onCommand: onCommand,
              );
            },
          ),
        if (snapshot.worldService case final service?)
          _RuntimeWorldServiceOverlay(
            snapshot: service,
            onCommand: widget.controller.dispatchWorldService,
          ),
        if (!showTouchControls &&
            (snapshot.preferences?.showInputHints ?? false) &&
            snapshot.activeInputSource != PlayerInputSource.touch)
          const Positioned(
            left: PlayerSpacing.sm,
            right: PlayerSpacing.sm,
            bottom: PlayerSpacing.sm,
            child: _RuntimePlayerInputHints(),
          ),
      ],
    );
    final preferences = snapshot.preferences;
    if (preferences == null) return stack;
    final media = MediaQuery.of(context);
    return Theme(
      data: PokeMapPlayerTheme.withAccessibility(
        Theme.of(context),
        highContrast: preferences.highContrast,
        reducedMotion: preferences.accessibility.reducedMotion,
      ),
      child: MediaQuery(
        key: const ValueKey<String>('runtime-player-session-accessibility'),
        data: media.copyWith(
          textScaler: PlayerTextScaler(
            systemScaler: media.textScaler,
            preferenceScale: preferences.accessibility.textScale,
          ),
          disableAnimations: media.disableAnimations ||
              preferences.accessibility.reducedMotion,
        ),
        child: stack,
      ),
    );
  }

  Future<void> _performHaptic() async {
    if (!(_latestSnapshot.preferences?.accessibility.hapticsEnabled ?? true)) {
      return;
    }
    try {
      await (widget.hapticFeedback ?? HapticFeedback.selectionClick)();
    } catch (_) {
      // Missing platform haptics must never interrupt player input.
    }
  }

  @override
  void dispose() {
    unawaited(_controllerSubscription?.cancel());
    _releaseGameplayDirections();
    super.dispose();
  }
}

class _RuntimePlayerInputHints extends StatelessWidget {
  const _RuntimePlayerInputHints();

  @override
  Widget build(BuildContext context) {
    final label =
        '${context.playerL10n.confirmShortcut}. ${context.playerL10n.pause}';
    return Semantics(
      key: const ValueKey<String>('runtime-player-input-hints'),
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: PlayerBadge(
            label: label,
            icon: Icons.gamepad_rounded,
          ),
        ),
      ),
    );
  }
}

class _RuntimeWorldServiceOverlay extends StatelessWidget {
  const _RuntimeWorldServiceOverlay({
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final Future<RuntimeWorldServiceCommandResult> Function(
    RuntimeWorldServiceCommand command,
  ) onCommand;

  @override
  Widget build(BuildContext context) {
    return switch (snapshot.request.kind) {
      RuntimeWorldServiceKind.shop => PlayerShopOverlay(
          snapshot: snapshot,
          onCommand: (command) => onCommand(command),
        ),
      RuntimeWorldServiceKind.heal => PlayerHealConfirmation(
          snapshot: snapshot,
          onCommand: (command) => onCommand(command),
        ),
      RuntimeWorldServiceKind.pc => PlayerPcOverlay(
          snapshot: snapshot,
          onCommand: (command) => onCommand(command),
        ),
    };
  }
}
