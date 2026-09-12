import 'dart:async';
import 'dart:ui' as ui show KeyEventDeviceType, PointerDeviceKind, ViewFocusEvent, ViewFocusState;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_overworld_components.dart';
import '../foundation/player_text_scaler.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_options.dart';
import 'player_battle_overlay.dart';
import 'player_title_screen.dart';
import 'player_dialogue_overlay.dart';
import 'player_control_profile.dart';
import 'player_heal_confirmation.dart';
import 'player_pause_menu.dart';
import 'player_pc_overlay.dart';
import 'player_scene_interaction_surface.dart';
import 'player_shop_overlay.dart';
import 'presentation_frame_renderer.dart';
import 'runtime_presentation_frame_surface.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_focus_controller.dart';
import 'runtime_player_gamepad_bridge.dart';
import 'runtime_player_surface_router.dart';
import 'runtime_player_party.dart';
import 'runtime_player_bag.dart';
import 'runtime_player_pokedex.dart';
import 'runtime_player_touch_controls.dart';

/// Small presentation-facing subset of the runtime player coordinator.
///
/// Tests and standalone hosts can provide this contract without importing the
/// Hub or exposing package installation details to the player UI.
abstract interface class RuntimePlayerViewController {
  RuntimePlayerSnapshot get snapshot;

  Stream<RuntimePlayerSnapshot> get snapshots;

  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command);

  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  });

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  );
}

/// Adapter for the canonical in-process runtime coordinator.
abstract interface class RuntimePlayerBagFavoritesController {
  Future<RuntimePlayerCommandResult> setBagItemFavorite(
      {required String itemId,
      required bool favorite,
      required int snapshotRevision});
}

final class RuntimePlayerCoordinatorViewController
    implements
        RuntimePlayerViewController,
        RuntimePlayerBagFavoritesController {
  const RuntimePlayerCoordinatorViewController(this.coordinator);

  final RuntimePlayerCoordinator coordinator;

  @override
  Future<RuntimePlayerCommandResult> setBagItemFavorite(
          {required String itemId,
          required bool favorite,
          required int snapshotRevision}) =>
      coordinator.setBagItemFavorite(
          itemId: itemId,
          favorite: favorite,
          snapshotRevision: snapshotRevision);

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
  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) =>
      coordinator.requestBack(snapshotRevision: snapshotRevision);

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
    this.gameplayViewportKey,
    this.touchControlsAvailable,
    this.controllerInputEnabled = true,
    this.controllerInputEvents,
    this.normalizedControllerInputEvents,
    this.connectedControllerIds,
    this.gameplayInputAuthority,
    this.overworldInteractions,
    this.hitTestOverworldInteraction,
    this.onOverworldInteraction,
    this.dialoguePresentation,
    this.onDialogueCommand,
    this.battlePresentation,
    this.onBattleCommand,
    this.hapticFeedback,
    this.controlProfile,
    this.onControlProfileChanged,
    this.pauseMenuLabels = const PlayerPauseMenuLabels(),
    this.pausePresentation,
    this.presentationFrame,
    this.presentationContentPort,
    this.onPresentationSkip,
  }) : assert(
          presentationFrame == null || presentationContentPort != null,
        );

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
  final GlobalKey? gameplayViewportKey;

  /// Overrides platform detection in embedders and widget tests.
  ///
  /// Production players normally leave this null: touch controls are then
  /// enabled on iOS and Android only.
  final bool? touchControlsAvailable;

  /// Keeps controller plugin access injectable and optional for standalone
  /// embedders while remaining enabled in the official player by default.
  final bool controllerInputEnabled;
  final Stream<RuntimeInputEvent>? controllerInputEvents;
  final Stream<NormalizedGamepadEvent>? normalizedControllerInputEvents;
  final ValueListenable<Set<String>>? connectedControllerIds;

  /// Runtime-owned authority deciding whether overworld touch chrome is legal.
  final ValueListenable<RuntimeInputAuthoritySnapshot>? gameplayInputAuthority;
  final ValueListenable<RuntimeOverworldInteractionSnapshot>? overworldInteractions;
  final RuntimeOverworldInteractionRequest? Function(Offset)? hitTestOverworldInteraction;
  final bool Function(RuntimeOverworldInteractionRequest)? onOverworldInteraction;

  /// Optional Flutter dialogue projection published by the mounted runtime.
  final ValueListenable<DialoguePresentationSnapshot?>? dialoguePresentation;
  final ValueChanged<DialoguePresentationCommand>? onDialogueCommand;
  final ValueListenable<BattleCommandOverlaySnapshot?>? battlePresentation;
  final ValueChanged<BattlePresentationCommand>? onBattleCommand;
  final Future<void> Function()? hapticFeedback;
  final PlayerControlProfile? controlProfile;
  final FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged;
  final PlayerPauseMenuLabels pauseMenuLabels;
  final PlayerPausePresentation? pausePresentation;
  final ValueListenable<RuntimePresentationFrameSnapshot?>? presentationFrame;
  final PresentationFrameContentPort? presentationContentPort;
  final Future<void> Function()? onPresentationSkip;

  @override
  State<PokeMapPlayerSessionView> createState() =>
      _PokeMapPlayerSessionViewState();
}

class _PokeMapPlayerSessionViewState extends State<PokeMapPlayerSessionView>
    with WidgetsBindingObserver {
  final _sessionSurfaceKey = GlobalKey();
  final _touchMenuKey = GlobalKey();
  final _overworldActionKey = GlobalKey();
  int _overworldActionEpoch = 0;
  RuntimeOverworldInteractionRequest? _lastOverworldRequest;
  final _touchCancellation = ValueNotifier<int>(0);
  var _pauseFocusController = RuntimePlayerFocusController();
  final _partyNavigation = RuntimePlayerPartyNavigation();
  final _bagNavigation = RuntimePlayerBagNavigation();
  final _pokedexNavigation = RuntimePlayerPokedexNavigation();
  StreamSubscription<dynamic>? _controllerSubscription;
  StreamSubscription<RuntimePlayerSnapshot>? _snapshotSubscription;
  bool _lifecycleActive = true;
  bool _viewFocused = true;
  RuntimeInputContext? _lastGameplayContext;
  bool _lastAcceptsOverworldInput = true;
  late (bool, bool, bool) _lastPresentationOwners;
  Timer? _controllerInventoryTimer;
  RuntimePlayerGamepadBridge? _gamepadBridge;
  final Map<String, PlayerControllerFamily> _controllerFamilies = {};
  int _controllerBindingGeneration = 0;
  bool _readingControllerInventory = false;
  late PlayerInputSourcePolicy _inputPolicy;
  ui.PointerDeviceKind? _pendingPointerKind;
  late RuntimePlayerSnapshot _latestSnapshot;
  PlayerInputSource get _activeInputSource => _inputPolicy.activeSource;
  PlayerControllerFamily get _controllerFamily =>
      _controllerFamilies[_inputPolicy.activeControllerId] ?? PlayerControllerFamily.unknown;
  bool _menuTransitionPending = false;

  bool get _touchControlsAvailable =>
      widget.touchControlsAvailable ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android));

  PlayerControlProfile get _controlProfile =>
      widget.controlProfile ?? PlayerControlProfile.standard;

  @override
  void initState() {
    super.initState();
    _latestSnapshot = widget.controller.snapshot;
    _inputPolicy = PlayerInputSourcePolicy(touchAvailable: _touchControlsAvailable);
    WidgetsBinding.instance.addObserver(this);
    _lifecycleActive = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _lastGameplayContext = widget.gameplayInputAuthority?.value.context;
    _lastAcceptsOverworldInput = widget.gameplayInputAuthority?.value.acceptsOverworldInput ?? true;
    _lastPresentationOwners = _presentationOwners;
    _snapshotSubscription = widget.controller.snapshots.listen(_handleSnapshot);
    HardwareKeyboard.instance.addHandler(_observeHardwareInput);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_observePointerInput);
    widget.presentationFrame?.addListener(_handlePresentationFrameChanged);
    widget.dialoguePresentation?.addListener(_handlePresentationFrameChanged);
    widget.battlePresentation?.addListener(_handlePresentationFrameChanged);
    widget.gameplayInputAuthority?.addListener(_handleGameplayAuthorityChanged);
    _lastOverworldRequest = widget.overworldInteractions?.value.primaryAction?.request;
    widget.overworldInteractions?.addListener(_handleOverworldInteractionsChanged);
    _bindControllerInputs();
  }

  @override
  void didUpdateWidget(covariant PokeMapPlayerSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overworldInteractions != widget.overworldInteractions) {
      oldWidget.overworldInteractions?.removeListener(_handleOverworldInteractionsChanged);
      widget.overworldInteractions?.addListener(_handleOverworldInteractionsChanged);
      _overworldActionEpoch++;
      _lastOverworldRequest = widget.overworldInteractions?.value.primaryAction?.request;
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.gameplayInputAuthority != widget.gameplayInputAuthority) {
      for (final event in _inputPolicy.releaseAll()) {
        oldWidget.gameplayInputRoute?.call(event);
      }
    }
    if (oldWidget.gameplayInputAuthority != widget.gameplayInputAuthority) {
      oldWidget.gameplayInputAuthority?.removeListener(_handleGameplayAuthorityChanged);
      widget.gameplayInputAuthority?.addListener(_handleGameplayAuthorityChanged);
      _touchCancellation.value++;
      _handleGameplayAuthorityChanged();
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.gameplayViewportKey != widget.gameplayViewportKey) {
      _touchCancellation.value++;
    }
    if (oldWidget.controller != widget.controller) {
      unawaited(_snapshotSubscription?.cancel());
      _snapshotSubscription = widget.controller.snapshots.listen(_handleSnapshot);
      _pokedexNavigation.clearForNewSession();
      _pauseFocusController.dispose();
      _pauseFocusController = RuntimePlayerFocusController();
      _latestSnapshot = widget.controller.snapshot;
    }
    if (oldWidget.presentationFrame != widget.presentationFrame) {
      oldWidget.presentationFrame?.removeListener(
        _handlePresentationFrameChanged,
      );
      widget.presentationFrame?.addListener(_handlePresentationFrameChanged);
    }
    if (oldWidget.dialoguePresentation != widget.dialoguePresentation) {
      oldWidget.dialoguePresentation?.removeListener(_handlePresentationFrameChanged);
      widget.dialoguePresentation?.addListener(_handlePresentationFrameChanged);
    }
    if (oldWidget.battlePresentation != widget.battlePresentation) {
      oldWidget.battlePresentation?.removeListener(_handlePresentationFrameChanged);
      widget.battlePresentation?.addListener(_handlePresentationFrameChanged);
    }
    if (oldWidget.presentationFrame != widget.presentationFrame ||
        oldWidget.dialoguePresentation != widget.dialoguePresentation ||
        oldWidget.battlePresentation != widget.battlePresentation) {
      _handlePresentationFrameChanged();
    }
    if (oldWidget.controllerInputEnabled != widget.controllerInputEnabled ||
        oldWidget.controllerInputEvents != widget.controllerInputEvents ||
        oldWidget.normalizedControllerInputEvents != widget.normalizedControllerInputEvents ||
        oldWidget.connectedControllerIds != widget.connectedControllerIds ||
        oldWidget.controlProfile != widget.controlProfile) {
      oldWidget.connectedControllerIds?.removeListener(_handleControllerInventoryChanged);
      for (final event in _inputPolicy.releaseAll()) {
        widget.gameplayInputRoute?.call(event);
      }
      _bindControllerInputs();
    }
  }

  void _handleGameplayAuthorityChanged() {
    final authority = widget.gameplayInputAuthority?.value;
    if (!(authority?.acceptsOverworldInput ?? true) ||
        _lastGameplayContext != authority?.context ||
        _lastAcceptsOverworldInput != (authority?.acceptsOverworldInput ?? true)) {
      _releaseGameplayDirections();
      _touchCancellation.value++;
    }
    _lastGameplayContext = authority?.context;
    _lastAcceptsOverworldInput = authority?.acceptsOverworldInput ?? true;
  }

  void _handleSnapshot(RuntimePlayerSnapshot snapshot) {
    if (!mounted) return;
    final previous = _latestSnapshot;
    _latestSnapshot = snapshot;
    if (snapshot.phase != previous.phase ||
        snapshot.worldService?.request != previous.worldService?.request) {
      _releaseGameplayDirections();
      _touchCancellation.value++;
    }
    if (snapshot.phase != previous.phase &&
        (snapshot.phase == RuntimePlayerPhase.title ||
            snapshot.phase == RuntimePlayerPhase.preparingSession)) {
      _pokedexNavigation.clearForNewSession();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleActive = state == AppLifecycleState.resumed;
    _releaseGameplayDirections();
    _touchCancellation.value++;
    if (mounted) setState(() {});
  }

  @override
  void didChangeViewFocus(ui.ViewFocusEvent event) {
    if (event.viewId != View.of(context).viewId) return;
    _viewFocused = event.state == ui.ViewFocusState.focused;
    _releaseGameplayDirections();
    _touchCancellation.value++;
    if (mounted) setState(() {});
  }

  void _handleOverworldInteractionsChanged() {
    final request = widget.overworldInteractions?.value.primaryAction?.request;
    if (request != _lastOverworldRequest) {
      _overworldActionEpoch++;
      _lastOverworldRequest = request;
    }
    if (mounted) setState(() {});
  }

  bool get _acceptsOverworldInteraction =>
      _lifecycleActive && _viewFocused &&
      !_menuTransitionPending &&
      _latestSnapshot.phase == RuntimePlayerPhase.playing &&
      _latestSnapshot.worldService == null &&
      widget.presentationFrame?.value == null &&
      widget.dialoguePresentation?.value == null &&
      widget.battlePresentation?.value == null &&
      (widget.gameplayInputAuthority?.value.acceptsOverworldInput ?? true);

  RuntimeOverworldInteractionRequest? _hitTestOverworldInteraction(Offset position) {
    if (!_acceptsOverworldInteraction) return null;
    final viewport = widget.gameplayViewportKey?.currentContext?.findRenderObject();
    final session = _sessionSurfaceKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize ||
        session is! RenderBox || !session.attached || !session.hasSize) {
      return null;
    }
    final point = viewport.globalToLocal(session.localToGlobal(position));
    return widget.hitTestOverworldInteraction?.call(point);
  }

  void _dispatchOverworldInteraction(RuntimeOverworldInteractionRequest request, {
    required bool fromTouch,
    bool fromWorldTap = false,
    int? epoch,
    int? cancellation,
  }) {
    final interactions = widget.overworldInteractions?.value;
    final action = fromWorldTap ? interactions?.tapAction : interactions?.primaryAction;
    if (!mounted || !_acceptsOverworldInteraction ||
        (epoch != null && epoch != _overworldActionEpoch) ||
        (cancellation != null && cancellation != _touchCancellation.value) ||
        action?.request != request) {
      return;
    }
    if (fromTouch) {
      _pendingPointerKind = null;
      _setActiveInputSource(PlayerInputSource.touch);
    }
    if (widget.onOverworldInteraction?.call(request) ?? false) {
      unawaited(_performHaptic());
    }
  }

  Widget? _overworldAction() {
    final action = widget.overworldInteractions?.value.primaryAction;
    if (!_acceptsOverworldInteraction || action == null || widget.onOverworldInteraction == null) return null;
    final device = switch (_activeInputSource) {
      PlayerInputSource.touch => PlayerControlDevice.touch,
      PlayerInputSource.keyboard || PlayerInputSource.mouse => PlayerControlDevice.keyboard,
      PlayerInputSource.controller => PlayerControlDevice.gamepad,
    };
    final glyph = (_latestSnapshot.preferences?.showInputHints ?? true)
        ? _controlProfile.promptFor(device, RuntimeInputControl.primary, family: _controllerFamily)
        : '';
    final epoch = _overworldActionEpoch;
    final cancellation = _touchCancellation.value;
    return SizedBox(key: _overworldActionKey, child: Builder(builder: (context) {
      final l10n = context.playerL10n;
      final (label, icon) = switch (action.verb) {
        RuntimeOverworldInteractionVerb.talk => (l10n.talk, Icons.chat_bubble_outline_rounded),
        RuntimeOverworldInteractionVerb.read => (l10n.read, Icons.search_rounded),
        RuntimeOverworldInteractionVerb.collect => (l10n.collect, Icons.back_hand_outlined),
        RuntimeOverworldInteractionVerb.enter => (l10n.enter, Icons.login_rounded),
        RuntimeOverworldInteractionVerb.interact => (l10n.interact, Icons.touch_app_outlined),
      };
      return PlayerOverworldActionCapsule(
      key: ValueKey((action.request, epoch, cancellation)),
      label: label,
      icon: icon,
      glyph: glyph.isEmpty ? null : glyph,
      onPressed: () => _dispatchOverworldInteraction(action.request,
        fromTouch: _pendingPointerKind == ui.PointerDeviceKind.touch,
        epoch: epoch, cancellation: cancellation),
      );
    }));
  }

  (bool, bool, bool) get _presentationOwners => (
    widget.presentationFrame?.value != null,
    widget.dialoguePresentation?.value != null,
    widget.battlePresentation?.value != null,
  );

  void _handlePresentationFrameChanged() {
    final owners = _presentationOwners;
    if (owners != _lastPresentationOwners) {
      _releaseGameplayDirections();
      _touchCancellation.value++;
    }
    _lastPresentationOwners = owners;
    if (mounted) setState(() {});
  }

  void _setActiveInputSource(PlayerInputSource source) {
    if (source != PlayerInputSource.touch) {
      _touchCancellation.value++;
    }
    final previous = _activeInputSource;
    _inputPolicy.recognizeSource(PlayerInputOwner(source));
    if (mounted && previous != _activeInputSource) {
      setState(() {});
    }
  }

  bool _observeHardwareInput(KeyEvent event) {
    if (event is KeyDownEvent && !_editableTextHasFocus() &&
        _controlProfile.runtimeEventFromKeyEvent(event) != null &&
        !(event.deviceType == ui.KeyEventDeviceType.gamepad && widget.controllerInputEnabled)) {
      _pendingPointerKind = null;
      _setActiveInputSource(event.deviceType == ui.KeyEventDeviceType.gamepad
          ? PlayerInputSource.controller
          : PlayerInputSource.keyboard);
    }
    return false;
  }

  void _observePointerInput(PointerEvent event) {
    if (event is PointerDownEvent) _pendingPointerKind = event.kind;
  }

  void _bindControllerInputs() {
    final generation = ++_controllerBindingGeneration;
    unawaited(_controllerSubscription?.cancel());
    _controllerSubscription = null;
    _controllerInventoryTimer?.cancel();
    _controllerInventoryTimer = null;
    widget.connectedControllerIds?.addListener(_handleControllerInventoryChanged);
    if (!widget.controllerInputEnabled) {
      _applyControllerInventory({});
      return;
    }
    final bridge = _gamepadBridge?.rebind(_controlProfile) ??
        RuntimePlayerGamepadBridge(controlProfile: _controlProfile);
    _gamepadBridge = bridge;
    if (widget.connectedControllerIds != null) {
      _handleControllerInventoryChanged();
    } else if (widget.controllerInputEvents == null && widget.normalizedControllerInputEvents == null) {
      unawaited(_refreshControllerInventory(generation));
      _controllerInventoryTimer = Timer.periodic(const Duration(seconds: 2),
        (_) => unawaited(_refreshControllerInventory(generation)));
    }
    final injected = widget.controllerInputEvents;
    if (injected != null) {
      _controllerSubscription = injected.listen((event) {
        if (generation != _controllerBindingGeneration) return;
        final id = widget.connectedControllerIds?.value.firstOrNull ?? 'injected';
        unawaited(_routeRuntimeInput(event, source: PlayerInputSource.controller, deviceId: id));
      }, onError: (_, __) {
        if (mounted && generation == _controllerBindingGeneration) {
          _applyControllerInventory({});
        }
      });
      return;
    }
    _controllerSubscription = (widget.normalizedControllerInputEvents ?? Gamepads.normalizedEvents).listen((event) {
      if (generation != _controllerBindingGeneration) return;
      final previousFamily = _controllerFamily;
      final family = RuntimePlayerGamepadBridge.familyFor(event);
      if (family != PlayerControllerFamily.unknown) {
        _controllerFamilies[event.gamepadId] = family;
      }
      if (mounted && previousFamily != _controllerFamily) setState(() {});
      for (final input in bridge.handle(event)) {
        unawaited(_routeRuntimeInput(input, source: PlayerInputSource.controller,
          deviceId: event.gamepadId));
      }
    }, onError: (_, __) {
      if (mounted && generation == _controllerBindingGeneration) {
        _applyControllerInventory({});
      }
    });
  }

  Future<void> _refreshControllerInventory(int generation) async {
    if (_readingControllerInventory) return;
    _readingControllerInventory = true;
    try {
      final devices = await Gamepads.list();
      final ids = devices.map((device) => device.id).toSet();
      await Future.wait(devices.map((device) => device.dispose()));
      if (mounted && generation == _controllerBindingGeneration) {
        _applyControllerInventory(ids);
      }
    } catch (_) {
      return;
    } finally {
      _readingControllerInventory = false;
    }
  }

  void _handleControllerInventoryChanged() =>
      _applyControllerInventory(widget.connectedControllerIds?.value ?? {});

  void _applyControllerInventory(Set<String> ids) {
    final previous = _activeInputSource;
    for (final id in _inputPolicy.connectedControllers.difference(ids)) {
      _gamepadBridge?.disconnect(id);
      _controllerFamilies.remove(id);
      Gamepads.normalizer?.removeDevice(id);
    }
    for (final event in _inputPolicy.updateControllers(ids)) {
      widget.gameplayInputRoute?.call(event);
    }
    if (mounted && previous != _activeInputSource) setState(() {});
  }

  PlayerInputSurface _inputSurface() {
    if (!_lifecycleActive || !_viewFocused) return PlayerInputSurface.blocked;
    // Menu opening/closing is asynchronous because the runtime first acquires
    // its typed pause lock. Treat that hand-off as blocked immediately so a
    // second key/controller event cannot leak into the world meanwhile.
    if (_menuTransitionPending) return PlayerInputSurface.blocked;
    if (widget.presentationFrame?.value != null) {
      return PlayerInputSurface.blocked;
    }
    final snapshot = _latestSnapshot;
    if (snapshot.worldService != null) return PlayerInputSurface.title;
    return switch (snapshot.phase) {
      RuntimePlayerPhase.playing => PlayerInputSurface.gameplay,
      RuntimePlayerPhase.title => PlayerInputSurface.title,
      RuntimePlayerPhase.paused => PlayerInputSurface.pause,
      RuntimePlayerPhase.result => PlayerInputSurface.result,
      RuntimePlayerPhase.credits => PlayerInputSurface.credits,
      RuntimePlayerPhase.boot ||
      RuntimePlayerPhase.preSession ||
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
    String deviceId = '',
    String inputId = '',
  }) async {
    if (source != PlayerInputSource.touch) {
      _pendingPointerKind = null;
      if (event.isPress && !event.isRepeat) {
        _touchCancellation.value++;
      }
    }
    final previous = _activeInputSource;
    final previousControllerId = _inputPolicy.activeControllerId;
    final events = _inputPolicy.route(event,
      owner: PlayerInputOwner(source, deviceId: deviceId), inputId: inputId);
    if (mounted && (previous != _activeInputSource ||
        previousControllerId != _inputPolicy.activeControllerId)) {
      setState(() {});
    }
    await Future.wait(events.map((input) =>
      _routeAcceptedRuntimeInput(input, source: source)));
  }

  Future<void> _routeAcceptedRuntimeInput(
    RuntimeInputEvent event, {
    required PlayerInputSource source,
  }) async {
    if ((!_lifecycleActive || !_viewFocused) && event.isPress) return;
    if (source == PlayerInputSource.touch && !event.isPress &&
        const {RuntimeInputControl.up, RuntimeInputControl.down,
          RuntimeInputControl.left, RuntimeInputControl.right,
          RuntimeInputControl.sprint}.contains(event.control)) {
      widget.gameplayInputRoute?.call(event);
      return;
    }
    final command = playerInputCommandFromRuntimeEvent(event, source: source);
    if (widget.presentationFrame?.value != null && command.isPress) {
      if (command.action == PlayerInputAction.confirm &&
          _latestSnapshot.phase != RuntimePlayerPhase.preSession) {
        await widget.onPresentationSkip?.call();
      } else if (command.action == PlayerInputAction.back ||
          command.action == PlayerInputAction.menu) {
        await _dispatchAction(RuntimePlayerAction.cancel);
      }
      return;
    }
    final router = PlayerInputRouter(
      surface: _inputSurface,
      routeGameplay: widget.gameplayInputRoute ?? (_) => false,
      routeSurface: _routeSurfaceInput,
      toggleMenu: _toggleMenu,
      releaseGameplayDirections: _releaseGameplayDirections,
    );
    final surface = _inputSurface();
    final handled = await router.route(command);
    final directional = command.action == PlayerInputAction.up ||
        command.action == PlayerInputAction.down ||
        command.action == PlayerInputAction.left ||
        command.action == PlayerInputAction.right;
    if (handled &&
        !(source == PlayerInputSource.touch &&
            command.action == PlayerInputAction.sprint) &&
        command.isPress &&
        !command.isRepeat &&
        command.action != PlayerInputAction.menu &&
        (surface == PlayerInputSurface.gameplay || directional)) {
      await _performHaptic();
    }
  }

  KeyEventResult _routeHardwareKeyEvent(FocusNode node, KeyEvent event) {
    final runtimeEvent = _controlProfile.runtimeEventFromKeyEvent(event);
    if (runtimeEvent == null) return KeyEventResult.ignored;
    final isHardwareGamepad = event.deviceType == ui.KeyEventDeviceType.gamepad;
    if (!isHardwareGamepad && runtimeEvent.isPress && _editableTextHasFocus()) {
      return KeyEventResult.ignored;
    }
    if (isHardwareGamepad && widget.controllerInputEnabled) {
      // The normalized gamepad stream is authoritative while enabled. Some
      // platforms also expose controller buttons as hardware keys; consuming
      // that duplicate path prevents one press from being routed twice.
      return KeyEventResult.handled;
    }
    unawaited(
      _routeRuntimeInput(
        runtimeEvent,
        inputId: event.physicalKey.usbHidUsage.toString(),
        source: isHardwareGamepad
            ? PlayerInputSource.controller
            : PlayerInputSource.keyboard,
      ),
    );
    return KeyEventResult.handled;
  }

  bool _editableTextHasFocus() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _releaseGameplayDirections() {
    final route = widget.gameplayInputRoute;
    for (final event in _inputPolicy.releaseHeld()) {
      if (event.control != RuntimeInputControl.menu) route?.call(event);
    }
  }

  Future<void> _toggleMenu() async {
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final snapshot = _latestSnapshot;
    final action = switch (snapshot.phase) {
      RuntimePlayerPhase.playing => RuntimePlayerAction.openMenu,
      RuntimePlayerPhase.paused => snapshot.pauseSection == null ||
              snapshot.pauseSection == RuntimePlayerPauseSection.root
          ? RuntimePlayerAction.resume
          : RuntimePlayerAction.returnToPauseRoot,
      _ => null,
    };
    if (action == null) return;
    await _dispatchAction(action);
  }

  Future<void> _routeSurfaceInput(PlayerInputCommand command) async {
    if (!command.isPress) return;
    final snapshot = _latestSnapshot;
    if (snapshot.phase == RuntimePlayerPhase.paused ||
        snapshot.phase == RuntimePlayerPhase.title &&
            snapshot.pauseSection == RuntimePlayerPauseSection.options) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext != null &&
          Actions.maybeFind<RuntimePlayerLogicalIntent>(focusContext) != null) {
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
        if (ModalRoute.of(context)?.isCurrent == false) {
          await Navigator.of(context).maybePop();
        } else {
          await _dispatchBack();
        }
      case PlayerInputAction.sprint:
      case PlayerInputAction.menu:
        // Menu/Start is intercepted by PlayerInputRouter.
        break;
    }
  }

  Future<void> _dispatchBack() async {
    final snapshot = _latestSnapshot;
    await widget.controller.requestBack(
      snapshotRevision: snapshot.revision,
    );
  }

  Future<void> _dispatchAction(RuntimePlayerAction action) async {
    final snapshot = _latestSnapshot;
    if (!snapshot.isActionEnabled(action)) return;
    await _dispatchCommand(action, snapshot);
  }

  Future<RuntimePlayerCommandResult> _dispatchSurfaceAction(
    RuntimePlayerAction action,
    RuntimePlayerSnapshot snapshot,
  ) =>
      _dispatchCommand(action, snapshot);

  Future<RuntimePlayerCommandResult> _dispatchCommand(
    RuntimePlayerAction action,
    RuntimePlayerSnapshot snapshot, {
    Object? payload,
  }) async {
    if (_pendingPointerKind == ui.PointerDeviceKind.touch) {
      _pendingPointerKind = null;
      _setActiveInputSource(PlayerInputSource.touch);
    }
    if (action == RuntimePlayerAction.openMenu &&
        (widget.gameplayInputAuthority?.value.context ==
                RuntimeInputContext.battle ||
            widget.gameplayInputAuthority?.value.context ==
                RuntimeInputContext.transition ||
            widget.battlePresentation?.value != null)) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'Le menu est temporairement indisponible.',
      );
    }
    final isMenuTransition = action == RuntimePlayerAction.openMenu ||
        action == RuntimePlayerAction.resume;
    if (isMenuTransition && _menuTransitionPending) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'The player menu is already changing state.',
      );
    }
    if (isMenuTransition) {
      _menuTransitionPending = true;
      if (mounted) setState(() {});
    }
    if (action == RuntimePlayerAction.openMenu) {
      _releaseGameplayDirections();
      _touchCancellation.value++;
    }
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
      if (isMenuTransition) {
        _menuTransitionPending = false;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<RuntimePlayerLocalActionNotification>(
      onNotification: (_) {
        if (_pendingPointerKind == ui.PointerDeviceKind.touch) {
          _pendingPointerKind = null;
          _setActiveInputSource(PlayerInputSource.touch);
        }
        return true;
      },
      child: Focus(
        key: const ValueKey<String>('runtime-player-keyboard-input-authority'),
        autofocus: true,
        onKeyEvent: _routeHardwareKeyEvent,
        child: Builder(
          builder: (context) {
            final snapshot = _latestSnapshot;
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
      ),
    );
  }

  Rect? _rectInSession(GlobalKey? key) {
    final target = key?.currentContext?.findRenderObject();
    final session = _sessionSurfaceKey.currentContext?.findRenderObject();
    if (target is! RenderBox || !target.attached || !target.hasSize ||
        session is! RenderBox || !session.attached || !session.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      target.getTransformTo(session), Offset.zero & target.size,
    );
  }

  Widget _buildSessionStack(
    RuntimePlayerSnapshot snapshot,
    RuntimeInputAuthoritySnapshot inputAuthority,
  ) {
    final acceptsOverworldTouch = inputAuthority.acceptsOverworldInput && _acceptsOverworldInteraction;
    final acceptsTouchControls = _touchControlsAvailable &&
        widget.gameplayInputRoute != null &&
        snapshot.phase == RuntimePlayerPhase.playing &&
        snapshot.worldService == null &&
        widget.presentationFrame?.value == null &&
        acceptsOverworldTouch;
    final showTouchControls = acceptsTouchControls && _activeInputSource == PlayerInputSource.touch;
    final touchControlsOpacity =
        snapshot.preferences?.touchControlsOpacity ?? 0.82;
    final showInputHints = !showTouchControls &&
        snapshot.phase != RuntimePlayerPhase.playing &&
        snapshot.phase != RuntimePlayerPhase.paused &&
        snapshot.phase != RuntimePlayerPhase.preSession &&
        widget.presentationFrame?.value == null &&
        (snapshot.preferences?.showInputHints ?? false) &&
        _activeInputSource != PlayerInputSource.touch;
    Widget inputHints() => Positioned(
          left: PlayerSpacing.sm,
          right: PlayerSpacing.sm,
          bottom: PlayerSpacing.sm,
          child: _RuntimePlayerInputHints(profile: _controlProfile, source: _activeInputSource,
            controllerFamily: _controllerFamily),
        );
    final stack = Stack(
      key: _sessionSurfaceKey,
      fit: StackFit.expand,
      children: <Widget>[
        RuntimePlayerSurfaceRouter(
          pauseFocusController: _pauseFocusController,
          snapshot: snapshot,
          titlePresentation: widget.titlePresentation,
          activeInputSource: _activeInputSource,
          hardwareGamepadEnabled: !widget.controllerInputEnabled,
          pauseMenuLabels: widget.pauseMenuLabels,
          pausePresentation: widget.pausePresentation,
          gameSceneBuilder: widget.gameSceneBuilder,
          onShowDiagnostics: widget.onShowDiagnostics,
          gameplayTouchMenuEnabled: acceptsOverworldTouch,
          gameplayTouchMenuKey: _touchMenuKey,
          gameplayAction: _overworldAction(),
          touchControlsOpacity: touchControlsOpacity,
          onPreferencesChanged: (preferences) async {
            final unavailableMessage = context.playerL10n.actionUnavailable;
            final result =
                await widget.controller.dispatch(RuntimePlayerCommand(
              action: RuntimePlayerAction.updatePreferences,
              snapshotRevision: _latestSnapshot.revision,
              payload: preferences,
            ));
            if (result.status != RuntimePlayerCommandStatus.accepted) {
              throw RuntimePlayerOptionsFailure(
                  result.safeMessage ?? unavailableMessage);
            }
          },
          onPauseCommand: (command) async {
            final unavailableMessage = context.playerL10n.actionUnavailable;
            final result = await _dispatchCommand(
              command.kind ==
                          RuntimePlayerPauseCommandKind.reorderPartyMember ||
                      command.kind == RuntimePlayerPauseCommandKind.setPartyLead
                  ? RuntimePlayerAction.reorderParty
                  : RuntimePlayerAction.useBagItem,
              snapshot,
              payload: command,
            );
            if ((snapshot.pauseSection == RuntimePlayerPauseSection.party ||
                    snapshot.pauseSection == RuntimePlayerPauseSection.bag) &&
                (result.status == RuntimePlayerCommandStatus.unavailable ||
                    result.status == RuntimePlayerCommandStatus.stale ||
                    result.status == RuntimePlayerCommandStatus.failed)) {
              throw RuntimePlayerPartyCommandFailure(
                  result.safeMessage ?? unavailableMessage);
            }
          },
          partyNavigation: _partyNavigation,
          bagNavigation: _bagNavigation,
          pokedexNavigation: _pokedexNavigation,
          onFavoriteChanged: widget.controller
                  is! RuntimePlayerBagFavoritesController
              ? null
              : (itemId, favorite) async {
                  final unavailableMessage =
                      context.playerL10n.actionUnavailable;
                  final result = await (widget.controller
                          as RuntimePlayerBagFavoritesController)
                      .setBagItemFavorite(
                          itemId: itemId,
                          favorite: favorite,
                          snapshotRevision: snapshot.revision);
                  if (result.status != RuntimePlayerCommandStatus.accepted) {
                    throw RuntimePlayerPartyCommandFailure(
                        result.safeMessage ?? unavailableMessage);
                  }
                },
          controlProfile: _controlProfile,
          onControlProfileChanged: widget.onControlProfileChanged,
          controllerFamily: _controllerFamily,
          onPreSessionResult: (result) => unawaited(
            _dispatchCommand(
              RuntimePlayerAction.resolvePreSessionInteraction,
              snapshot,
              payload: result,
            ),
          ),
          showPreSessionInteraction: widget.presentationFrame?.value == null,
          onAction: (action) => _dispatchSurfaceAction(action, snapshot),
          onReturnToTitle: (saveBeforeExit) => _dispatchCommand(
            RuntimePlayerAction.returnToTitle,
            _latestSnapshot,
            payload: RuntimePlayerExitRequest(saveBeforeExit: saveBeforeExit),
          ),
        ),
        if (widget.presentationFrame case final presentation?)
          ValueListenableBuilder<RuntimePresentationFrameSnapshot?>(
            valueListenable: presentation,
            builder: (context, frame, _) {
              if (frame == null) return const SizedBox.shrink();
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  RuntimePresentationFrameSurface(
                    snapshot: frame,
                    contentPort: widget.presentationContentPort!,
                    onSkip: snapshot.phase == RuntimePlayerPhase.preSession
                        ? null
                        : widget.onPresentationSkip,
                  ),
                  if (snapshot.preSessionRequest case final request?)
                    PlayerSceneInteractionSurface(
                      request: request,
                      interactionEnabled: snapshot.isActionEnabled(
                        RuntimePlayerAction.resolvePreSessionInteraction,
                      ),
                      onResult: (result) => unawaited(
                        _dispatchCommand(
                          RuntimePlayerAction.resolvePreSessionInteraction,
                          snapshot,
                          payload: result,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (acceptsTouchControls)
          Positioned.fill(
            child: RuntimePlayerTouchControls(
              showControls: showTouchControls,
              sprintAllowed: inputAuthority.sprintAllowed,
              sprintAccepted: inputAuthority.sprintAccepted,
              runMode: snapshot.preferences?.touchRunMode ?? RuntimePlayerTouchRunMode.gesture,
              onSprintAccepted: () => unawaited(_performHaptic()),
              cancellationSignal: _touchCancellation,
              readGameplayViewport: () => _rectInSession(widget.gameplayViewportKey),
              readExcludedRects: () => [
                if (_rectInSession(_touchMenuKey) case final rect?) rect,
                if (_rectInSession(_overworldActionKey) case final rect?) rect,
              ],
              interactionChanges: widget.overworldInteractions,
              resolveTapTarget: _hitTestOverworldInteraction,
              onTap: (request) => _dispatchOverworldInteraction(request, fromTouch: true, fromWorldTap: true),
              leftHanded: snapshot.preferences?.leftHandedTouchControls ?? false,
              onMovementGesture: () => _setActiveInputSource(PlayerInputSource.touch),
              opacity: touchControlsOpacity,
              controlProfile: _controlProfile,
              dispatch: (event) => unawaited(
                _routeRuntimeInput(
                  event,
                  source: PlayerInputSource.touch,
                ),
              ),
            ),
          ),
        if (widget.dialoguePresentation case final dialogue?
            when snapshot.phase == RuntimePlayerPhase.playing)
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
        if (widget.battlePresentation case final battle?)
          ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
            valueListenable: battle,
            builder: (context, presentation, _) {
              final onCommand = widget.onBattleCommand;
              if (presentation == null || onCommand == null) {
                return const SizedBox.shrink();
              }
              return PlayerBattleOverlay(
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
        if (showInputHints)
          if (widget.battlePresentation case final battle?)
            ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
              valueListenable: battle,
              builder: (context, presentation, _) =>
                  presentation == null ? inputHints() : const SizedBox.shrink(),
            )
          else
            inputHints(),
      ],
    );
    return RuntimePlayerPreferencesScope(
      preferences: snapshot.preferences,
      child: stack,
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_snapshotSubscription?.cancel());
    ++_controllerBindingGeneration;
    _controllerInventoryTimer?.cancel();
    widget.connectedControllerIds?.removeListener(_handleControllerInventoryChanged);
    HardwareKeyboard.instance.removeHandler(_observeHardwareInput);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_observePointerInput);
    _pauseFocusController.dispose();
    unawaited(_controllerSubscription?.cancel());
    _partyNavigation.dispose();
    _bagNavigation.dispose();
    _pokedexNavigation.dispose();
    widget.presentationFrame?.removeListener(_handlePresentationFrameChanged);
    widget.dialoguePresentation?.removeListener(_handlePresentationFrameChanged);
    widget.battlePresentation?.removeListener(_handlePresentationFrameChanged);
    widget.gameplayInputAuthority?.removeListener(_handleGameplayAuthorityChanged);
    widget.overworldInteractions?.removeListener(_handleOverworldInteractionsChanged);
    _releaseGameplayDirections();
    _touchCancellation.dispose();
    super.dispose();
  }
}

class RuntimePlayerPreferencesScope extends StatelessWidget {
  const RuntimePlayerPreferencesScope({
    super.key,
    required this.preferences,
    required this.child,
  });

  final PlayerPreferencesSnapshot? preferences;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preferences = this.preferences;
    if (preferences == null) return child;
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
        child: Localizations.override(
          context: context,
          locale: Locale(preferences.locale.split(RegExp('[-_]')).first),
          delegates: PokeMapPlayerLocalizations.localizationsDelegates,
          child: PlayerMenuEffectsScope(
            effects: preferences.menuEffects,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RuntimePlayerInputHints extends StatelessWidget {
  const _RuntimePlayerInputHints({required this.profile, required this.source,
    required this.controllerFamily});

  final PlayerControlProfile profile;
  final PlayerInputSource source;
  final PlayerControllerFamily controllerFamily;

  @override
  Widget build(BuildContext context) {
    final device = source == PlayerInputSource.controller
        ? PlayerControlDevice.gamepad : PlayerControlDevice.keyboard;
    final label = '${profile.promptFor(device, RuntimeInputControl.primary, family: controllerFamily)} · '
        '${profile.promptFor(device, RuntimeInputControl.menu, family: controllerFamily)} ${context.playerL10n.pause}';
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
