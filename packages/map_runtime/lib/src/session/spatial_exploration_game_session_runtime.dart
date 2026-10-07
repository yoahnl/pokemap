import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../application/load_runtime_map_bundle.dart';
import '../player/runtime_player_pause_data.dart';
import '../player/runtime_player_host.dart';
import '../application/runtime_overworld_interaction.dart';
import 'runtime_overworld_interaction_port.dart';
import 'package:map_gameplay/map_gameplay.dart';
import '../presentation/flame/runtime_input_authority.dart';
import '../presentation/flame/runtime_input_event.dart';
import '../spatial/spatial_exploration_session.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
import 'game_session_contract.dart';
import 'in_process_game_session_adapter.dart';
import 'playable_map_game_session_runtime.dart';

typedef SpatialExplorationSessionMount = Future<void> Function(
  SpatialExplorationGameSessionRuntime runtime,
);

final class SpatialExplorationGameSessionRuntime
    implements
        InProcessGameSessionRuntime,
        GameSessionInputLockPort,
        RuntimePlayerPauseDataPort,
        RuntimePlayerCompanionMenuPort,
        RuntimePlayerPreferencesPort,
        RuntimeOverworldInteractionPort {
  SpatialExplorationGameSessionRuntime({
    required this.descriptor,
    required SessionProjectFilePathLoader projectFilePath,
    required SpatialExplorationSessionMount mountSession,
    required SpatialExplorationSessionMount unmountSession,
    SessionPreloadedInitialMapLoader? preloadedInitialMap,
  })  : _projectFilePath = projectFilePath,
        _mountSession = mountSession,
        _unmountSession = unmountSession,
        _preloadedInitialMap = preloadedInitialMap;

  final GameSessionDescriptor descriptor;
  final SessionProjectFilePathLoader _projectFilePath;
  final SpatialExplorationSessionMount _mountSession, _unmountSession;
  final SessionPreloadedInitialMapLoader? _preloadedInitialMap;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _locks = <RuntimeExternalInputLock>{};
  final _pressed = <RuntimeInputControl>{};
  final inputAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
    context: RuntimeInputContext.blocked,
  ));
  SpatialExplorationSession? _session;
  PlayerPreferencesSnapshot? _preferences;
  late final overworldInteractions = ValueNotifier(
      RuntimeOverworldInteractionSnapshot(
          sessionId: descriptor.sessionId,
          mapActivationId: _mapActivationId,
          mapId: 'loading'));
  final _interactionEvents =
      StreamController<RuntimeOverworldInteractionSnapshot?>.broadcast();
  @override
  RuntimeOverworldInteractionSnapshot? get overworldInteractionSnapshot =>
      _session == null ? null : overworldInteractions.value;
  @override
  Stream<RuntimeOverworldInteractionSnapshot?>
      get overworldInteractionSnapshots => _interactionEvents.stream;
  @override
  void applyPlayerPreferences(PlayerPreferencesSnapshot preferences) {
    _preferences = preferences;
    _session?.setTextSpeed(preferences.dialogueTextSpeed);
  }

  String get _mapActivationId =>
      '${descriptor.sessionId}:spatial:${(_session?.mapRevision.value ?? 0) + 1}';
  void _publishInteractions() {
    if (_disposed) return;
    final session = _session;
    if (session == null) return;
    final npc = !inputAuthority.value.acceptsOverworldInput
        ? null
        : findSpatialNpcInteraction(
            scene: session.bundle.map.spatialScene!,
            entities: session.bundle.map.entities,
            x: session.movement.x,
            z: session.movement.z,
            facing: session.movement.facing);
    final snapshot = RuntimeOverworldInteractionSnapshot(
        sessionId: descriptor.sessionId,
        mapActivationId: _mapActivationId,
        mapId: session.bundle.map.id,
        primaryAction: npc?.npc?.dialogue == null
            ? null
            : RuntimeOverworldInteractionAction(
                request: RuntimeOverworldInteractionRequest(
                    sessionId: descriptor.sessionId,
                    mapActivationId: _mapActivationId,
                    mapId: session.bundle.map.id,
                    targetKind: RuntimeOverworldInteractionTargetKind.entity,
                    targetId: npc!.id,
                    actionId: 'talk'),
                verb: RuntimeOverworldInteractionVerb.talk,
                targetCell: npc.pos,
                targetBounds: PixelRect(
                    leftPx: npc.pos.x * SpatialMovementController.pixelsPerCell,
                    topPx: npc.pos.y * SpatialMovementController.pixelsPerCell,
                    widthPx: SpatialMovementController.pixelsPerCell,
                    heightPx: SpatialMovementController.pixelsPerCell)));
    if (snapshot != overworldInteractions.value) {
      overworldInteractions.value = snapshot;
      _interactionEvents.add(snapshot);
    }
  }

  @override
  bool dispatchOverworldInteraction(
      RuntimeOverworldInteractionRequest request) {
    if (_disposed || !inputAuthority.value.acceptsOverworldInput) return false;
    _publishInteractions();
    if (request != overworldInteractions.value.primaryAction?.request) {
      return false;
    }
    unawaited(_session!.interact());
    return true;
  }

  bool _mounted = false, _paused = false, _stopped = false, _disposed = false;

  SpatialExplorationSession? get session => _session;
  ValueListenable<DialoguePresentationSnapshot?>
      get dialoguePresentationListenable => _session!.dialoguePresentation;
  void dispatchDialoguePresentationCommand(
      DialoguePresentationCommand command) {
    if (inputAuthority.value.context == RuntimeInputContext.dialogue &&
        inputAuthority.value.acceptsRuntimeInput) {
      _session?.dispatchDialogueCommand(command);
    }
  }

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async {
    _ensureOpen();
    if (_session != null || _stopped) {
      throw StateError('Exploration is single-use.');
    }
    if (descriptor.launchMode != GameSessionLaunchMode.newGame ||
        descriptor.saveReadHandle != null ||
        descriptor.initialGameState != null) {
      throw StateError('Spatial exploration does not restore gameplay saves.');
    }
    if (!descriptor.grantedCapabilities.contains('map3d@1')) {
      throw StateError('Spatial exploration requires map3d@1.');
    }
    reportProgress(const GameSessionLoadingProgress(
        stage: 'project', current: 0, total: 3));
    final path = await _projectFilePath();
    final preload = await _preloadedInitialMap?.call(
        projectFilePath: path, descriptor: descriptor, initialSave: null);
    try {
      final manifest =
          preload?.bundle.manifest ?? await loadProjectManifestFromFile(path);
      if (manifest.settings.dimension != ProjectDimension.threeD ||
          manifest.maps.isEmpty) {
        throw StateError('A spatial project with an initial map is required.');
      }
      final bundle = preload?.bundle ??
          await loadRuntimeMapBundle(
              projectFilePath: path,
              mapId: manifest.maps.first.id,
              preloadedManifest: manifest);
      if (bundle.map.id != manifest.maps.first.id) {
        throw StateError('The exploration map does not match the initial map.');
      }
      reportProgress(const GameSessionLoadingProgress(
          stage: 'resources', current: 1, total: 3));
      final loaded = await SpatialExplorationSession.load(bundle);
      if (_disposed) {
        loaded.dispose();
        throw StateError('Exploration closed while loading.');
      }
      _session = loaded;
      loaded.interactionActive.addListener(_syncMovement);
      loaded.transitioning.addListener(_syncMovement);
      loaded.onFrame = _publishInteractions;
      if (_preferences case final preferences?) {
        loaded.setTextSpeed(preferences.dialogueTextSpeed);
      }
      _syncMovement();
      _mounted = true;
      await _mountSession(this);
      _ensureOpen();
      reportProgress(const GameSessionLoadingProgress(
          stage: 'ready', current: 3, total: 3));
    } finally {
      preload?.dispose();
    }
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    if (_disposed || _session == null) return false;
    if (!inputAuthority.value.acceptsRuntimeInput) return true;
    if (inputAuthority.value.context == RuntimeInputContext.dialogue) {
      if (event.isPress && !event.isRepeat) {
        if (event.control == RuntimeInputControl.secondary) {
          _session!.closeDialogue();
        }
        if (event.control == RuntimeInputControl.primary) {
          final snapshot = _session!.dialoguePresentation.value;
          if (snapshot != null) {
            dispatchDialoguePresentationCommand(
                DialogueAdvanceCommand(snapshotRevision: snapshot.revision));
          }
        }
      }
      return true;
    }
    if (!inputAuthority.value.acceptsOverworldInput) return true;
    if (event.control == RuntimeInputControl.primary) {
      if (event.isPress && !event.isRepeat) {
        _publishInteractions();
        final request = overworldInteractions.value.primaryAction?.request;
        if (request != null) dispatchOverworldInteraction(request);
      }
      return true;
    }
    if (!{
      RuntimeInputControl.up,
      RuntimeInputControl.down,
      RuntimeInputControl.left,
      RuntimeInputControl.right,
      RuntimeInputControl.sprint
    }.contains(event.control)) {
      return false;
    }
    if (event.isRelease) {
      _pressed.remove(event.control);
    } else if (!event.isRepeat || _pressed.contains(event.control)) {
      _pressed.add(event.control);
    }
    _session!.movement.setInput(
      x: (_pressed.contains(RuntimeInputControl.right) ? 1 : 0) -
          (_pressed.contains(RuntimeInputControl.left) ? 1 : 0),
      z: (_pressed.contains(RuntimeInputControl.down) ? 1 : 0) -
          (_pressed.contains(RuntimeInputControl.up) ? 1 : 0),
      run: _pressed.contains(RuntimeInputControl.sprint),
    );
    return true;
  }

  @override
  Future<void> setInputLock(RuntimeExternalInputLock owner,
      {required bool locked}) async {
    _ensureOpen();
    if (locked) {
      _locks.add(owner);
      if (_session?.transitioning.value ?? false) {
        _session!.cancelPendingTransition();
      }
    } else {
      _locks.remove(owner);
    }
    _syncMovement();
  }

  void _syncMovement() {
    _pressed.clear();
    final paused = _paused ||
        _stopped ||
        _locks.isNotEmpty ||
        _session == null ||
        (_session?.transitioning.value ?? false);
    final talking = _session?.interactionActive.value ?? false;
    _session?.dialoguePaused = paused;
    _session?.movement.setPaused(paused || talking);
    inputAuthority.value = RuntimeInputAuthoritySnapshot(
        context: paused
            ? RuntimeInputContext.blocked
            : talking
                ? RuntimeInputContext.dialogue
                : RuntimeInputContext.overworld,
        externalLocks: Set.unmodifiable(_locks),
        sprintAllowed: !paused && !talking);
    _publishInteractions();
  }

  @override
  Future<void> pause() async {
    _ensureOpen();
    _paused = true;
    if (_session?.transitioning.value ?? false) {
      _session!.cancelPendingTransition();
    }
    _syncMovement();
  }

  @override
  Future<void> resume() async {
    _ensureOpen();
    _paused = false;
    _syncMovement();
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async => null;

  @override
  Future<void> lockGameplayForCompletion() =>
      setInputLock(RuntimeExternalInputLock.gameCompletion, locked: true);

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {}

  @override
  Future<void> stop(GameSessionExitReason reason) async {
    if (_disposed) return;
    _stopped = true;
    _session?.cancelPendingTransition();
    _session?.closeDialogue();
    _syncMovement();
  }

  @override
  Future<PlayerPauseMenuState> loadPauseMenuState() async =>
      PlayerPauseMenuState(
        visibilityOverrides: {
          for (final action in ProjectPauseActionId.values)
            if (action != ProjectPauseActionId.resume)
              action: action == ProjectPauseActionId.options ||
                  action == ProjectPauseActionId.returnToTitle,
        },
      );

  @override
  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      loadPauseDetails() async => const {};

  @override
  Future<RuntimePlayerCompanionMenuData> readCompanionMenuData() async =>
      RuntimePlayerCompanionMenuData(
          pauseMenuState: await loadPauseMenuState(), pauseDetails: const {});

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopped = true;
    _session?.closeDialogue();
    _syncMovement();
    try {
      if (_mounted) await _unmountSession(this);
    } finally {
      _mounted = false;
      _session?.interactionActive.removeListener(_syncMovement);
      _session?.transitioning.removeListener(_syncMovement);
      _session?.dispose();
      _session = null;
      overworldInteractions.dispose();
      await _interactionEvents.close();
      inputAuthority.dispose();
      await _events.close();
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Spatial exploration is disposed.');
  }
}
