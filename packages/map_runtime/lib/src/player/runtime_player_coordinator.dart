import 'dart:async';

import 'package:map_core/map_core.dart';

import '../session/game_session_contract.dart';
import '../session/game_session_controller.dart';
import 'runtime_player_host.dart';
import 'runtime_player_models.dart';

/// Runtime-owned state machine for title, session and player surfaces.
///
/// The embedding host provides data and persistence ports but never owns the
/// player navigation state.
final class RuntimePlayerCoordinator {
  RuntimePlayerCoordinator({
    required RuntimeGameSource gameSource,
    required PlayerSaveGateway saveGateway,
    required PlayerPreferencesGateway preferencesGateway,
    required GameSessionController sessionController,
  })  : _gameSource = gameSource,
        _saveGateway = saveGateway,
        _preferencesGateway = preferencesGateway,
        _sessions = sessionController,
        _snapshot = RuntimePlayerSnapshot(
          revision: 0,
          phase: RuntimePlayerPhase.boot,
          gameTitle: gameSource.displayTitle,
        ) {
    if (gameSource.identity != saveGateway.identity) {
      throw ArgumentError(
        'The player save gateway must match the selected game identity.',
      );
    }
    _sessionSubscription = _sessions.snapshots.listen(_onSessionSnapshot);
  }

  final RuntimeGameSource _gameSource;
  final PlayerSaveGateway _saveGateway;
  final PlayerPreferencesGateway _preferencesGateway;
  final GameSessionController _sessions;
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  late final StreamSubscription<GameSessionSnapshot> _sessionSubscription;
  Future<void> _tail = Future<void>.value();

  RuntimePlayerSnapshot _snapshot;
  PlayerPreferencesSnapshot? _preferences;
  PlayerSaveSummary? _latestSave;
  _RuntimeLaunchRequest? _retryLaunch;
  int _launchGeneration = 0;
  bool _disposed = false;

  RuntimePlayerSnapshot get snapshot => _snapshot;
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;
  PlayerPreferencesSnapshot? get preferences => _preferences;

  Future<void> initialize() {
    return _serialize(() async {
      _ensureOpen();
      if (_hasLiveSession) {
        throw StateError('Cannot initialize the title during a live session.');
      }
      await _loadTitleData();
    });
  }

  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) {
    _ensureOpen();
    if (command.action == RuntimePlayerAction.cancel) {
      return _cancel(command);
    }
    return _serialize(() => _dispatchSerialized(command));
  }

  Future<RuntimePlayerCommandResult> _dispatchSerialized(
    RuntimePlayerCommand command,
  ) async {
    if (command.snapshotRevision != _snapshot.revision) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.stale,
        safeMessage: 'The player surface changed before this action arrived.',
      );
    }
    if (!_snapshot.isActionEnabled(command.action)) {
      return RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: _snapshot.unavailableReasonFor(command.action) ??
            'This player action is unavailable.',
      );
    }

    switch (command.action) {
      case RuntimePlayerAction.newGame:
        final slot = command.payload;
        if (slot is! RuntimePlayerLoadSlot) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'A profile and slot are required for a new game.',
          );
        }
        return _launch(
          _RuntimeLaunchRequest(
            launchMode: GameSessionLaunchMode.newGame,
            profileId: slot.profileId,
            slotId: slot.slotId,
          ),
        );
      case RuntimePlayerAction.continueGame:
        final save = _latestSave;
        if (save == null || !save.canContinue) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'No compatible save is available to continue.',
          );
        }
        return _launchSave(save, GameSessionLaunchMode.continueGame);
      case RuntimePlayerAction.load:
        final slot = command.payload;
        if (slot is! RuntimePlayerLoadSlot) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'A profile and slot are required to load a save.',
          );
        }
        final address = _address(slot);
        final save = await _saveGateway.readSummary(address);
        if (save == null || !save.canContinue) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'The selected save is unavailable or incompatible.',
          );
        }
        return _launchSave(save, GameSessionLaunchMode.load);
      case RuntimePlayerAction.retry:
        final retry = _retryLaunch;
        if (retry == null) {
          final loaded = await _loadTitleData();
          return RuntimePlayerCommandResult(
            status: loaded
                ? RuntimePlayerCommandStatus.accepted
                : RuntimePlayerCommandStatus.failed,
          );
        }
        return _launch(retry);
      case RuntimePlayerAction.openMenu:
        await _sessions.pause();
        if (_snapshot.phase != RuntimePlayerPhase.paused) {
          _publishPause(RuntimePlayerPauseSection.root);
        }
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.resume:
        await _sessions.resume();
        if (_snapshot.phase != RuntimePlayerPhase.playing) {
          _publishPlaying();
        }
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.openParty:
        _publishPause(
          RuntimePlayerPauseSection.party,
          logicalSelectionId: 'pause.party',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.openBag:
        _publishPause(
          RuntimePlayerPauseSection.bag,
          logicalSelectionId: 'pause.bag',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.openPokedex:
        _publishPause(
          RuntimePlayerPauseSection.pokedex,
          logicalSelectionId: 'pause.pokedex',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.openMap:
        _publishPause(
          RuntimePlayerPauseSection.map,
          logicalSelectionId: 'pause.map',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.openOptions:
        _publishPause(
          RuntimePlayerPauseSection.options,
          logicalSelectionId: 'pause.options',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.returnToPauseRoot:
        _publishPause(
          RuntimePlayerPauseSection.root,
          logicalSelectionId: _snapshot.logicalSelectionId,
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.cancel:
      case RuntimePlayerAction.save:
      case RuntimePlayerAction.returnToTitle:
      case RuntimePlayerAction.showCredits:
      case RuntimePlayerAction.finishCredits:
      case RuntimePlayerAction.returnToHost:
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.unavailable,
          safeMessage: 'This action is not available on the current surface.',
        );
    }
  }

  Future<RuntimePlayerCommandResult> _launchSave(
    PlayerSaveSummary save,
    GameSessionLaunchMode launchMode,
  ) async {
    _validateSaveScope(save);
    final handle = await _saveGateway.openReadHandle(save.address);
    if (handle == null || handle.trim().isEmpty) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'The selected save could not be opened safely.',
      );
    }
    return _launch(
      _RuntimeLaunchRequest(
        launchMode: launchMode,
        profileId: save.address.profileId,
        slotId: save.address.slotId,
        saveReadHandle: handle,
      ),
    );
  }

  Future<RuntimePlayerCommandResult> _launch(
    _RuntimeLaunchRequest request,
  ) async {
    final generation = ++_launchGeneration;
    _retryLaunch = request;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.preparingSession,
        clearLoadingProgress: true,
        clearFailure: true,
        actions: _cancelActions,
      ),
    );
    try {
      final descriptor = await _gameSource.createSessionDescriptor(
        launchMode: request.launchMode,
        profileId: request.profileId,
        slotId: request.slotId,
        saveReadHandle: request.saveReadHandle,
      );
      if (generation != _launchGeneration) {
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.cancelled,
        );
      }
      await _sessions.prepare(descriptor);
      if (generation != _launchGeneration) {
        await _sessions.terminate();
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.cancelled,
        );
      }
      await _sessions.start();
      if (generation != _launchGeneration) {
        await _cancelLiveSession();
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.cancelled,
        );
      }
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      );
    } catch (_) {
      if (generation != _launchGeneration) {
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.cancelled,
        );
      }
      _publishFailure(
        const GameSessionFailure(
          code: GameSessionFailureCode.runtime,
          recoverability: GameSessionFailureRecoverability.retry,
          safeMessage: 'The game session could not be launched.',
        ),
        allowRetry: true,
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'The game session could not be launched.',
      );
    }
  }

  Future<RuntimePlayerCommandResult> _cancel(
    RuntimePlayerCommand command,
  ) async {
    if (command.snapshotRevision != _snapshot.revision) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.stale,
      );
    }
    if (!_snapshot.isActionEnabled(RuntimePlayerAction.cancel)) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
      );
    }
    _launchGeneration++;
    await _cancelLiveSession();
    _publishTitle();
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  Future<void> _cancelLiveSession() async {
    switch (_sessions.snapshot.state) {
      case GameSessionState.starting:
      case GameSessionState.loading:
        await _sessions.cancelLoading();
      case GameSessionState.prepared:
      case GameSessionState.running:
      case GameSessionState.paused:
      case GameSessionState.lifecyclePaused:
      case GameSessionState.completing:
      case GameSessionState.completed:
      case GameSessionState.failed:
        await _sessions.terminate();
      case GameSessionState.idle:
      case GameSessionState.preparing:
      case GameSessionState.stopping:
      case GameSessionState.disposed:
        return;
    }
  }

  Future<bool> _loadTitleData() async {
    try {
      _preferences = await _preferencesGateway.load();
      _latestSave = await _saveGateway.readLatestSummary();
      _validateSaveScope(_latestSave);
      _retryLaunch = null;
      _publishTitle();
      return true;
    } catch (_) {
      _publishFailure(
        const GameSessionFailure(
          code: GameSessionFailureCode.storage,
          recoverability: GameSessionFailureRecoverability.retry,
          safeMessage: 'Player data could not be loaded.',
        ),
        allowRetry: true,
      );
      return false;
    }
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await _sessions.settle();
    await _tail;
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _launchGeneration++;
    await _cancelLiveSession();
    await _sessionSubscription.cancel();
    await _sessions.dispose();
    _disposed = true;
    await _snapshots.close();
  }

  void _onSessionSnapshot(GameSessionSnapshot session) {
    if (_disposed) return;
    switch (session.state) {
      case GameSessionState.idle:
        return;
      case GameSessionState.preparing:
      case GameSessionState.prepared:
      case GameSessionState.starting:
        if (_snapshot.phase != RuntimePlayerPhase.preparingSession) {
          _publish(
            _snapshot.next(
              phase: RuntimePlayerPhase.preparingSession,
              actions: _cancelActions,
            ),
          );
        }
      case GameSessionState.loading:
        _publish(
          _snapshot.next(
            phase: RuntimePlayerPhase.loadingSession,
            loadingProgress: session.loadingProgress,
            actions: _cancelActions,
          ),
        );
      case GameSessionState.running:
        if (_snapshot.phase != RuntimePlayerPhase.playing) {
          _publishPlaying();
        }
      case GameSessionState.paused:
        if (_snapshot.phase != RuntimePlayerPhase.paused) {
          _publishPause(RuntimePlayerPauseSection.root);
        }
      case GameSessionState.lifecyclePaused:
      case GameSessionState.completing:
      case GameSessionState.completed:
      case GameSessionState.stopping:
        return;
      case GameSessionState.failed:
        _publishFailure(
          session.failure ??
              const GameSessionFailure(
                code: GameSessionFailureCode.runtime,
                recoverability: GameSessionFailureRecoverability.titleOrHub,
                safeMessage: 'The player session failed.',
              ),
          allowRetry: true,
        );
      case GameSessionState.disposed:
        if (session.exitReason == GameSessionExitReason.cancelled) {
          _publishTitle();
        }
    }
  }

  void _publishTitle() {
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.title,
        clearPauseSection: true,
        clearLoadingProgress: true,
        clearFailure: true,
        clearResult: true,
        clearCredits: true,
        clearLogicalSelection: true,
        actions: _titleActions,
      ),
    );
  }

  void _publishPlaying() {
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.playing,
        clearPauseSection: true,
        clearLoadingProgress: true,
        clearFailure: true,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
  }

  void _publishPause(
    RuntimePlayerPauseSection section, {
    String? logicalSelectionId,
  }) {
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.paused,
        pauseSection: section,
        logicalSelectionId: logicalSelectionId,
        actions: _pauseActions(
          includeReturnToRoot: section != RuntimePlayerPauseSection.root,
        ),
      ),
    );
  }

  void _publishFailure(
    GameSessionFailure failure, {
    required bool allowRetry,
  }) {
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.error,
        failure: failure,
        clearLoadingProgress: true,
        actions: <RuntimePlayerActionAvailability>[
          if (allowRetry)
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.retry,
            ),
          const RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.cancel,
          ),
        ],
      ),
    );
  }

  List<RuntimePlayerActionAvailability> get _titleActions {
    final save = _latestSave;
    final continueEnabled = save != null && save.canContinue;
    final unavailableReason = save?.safeUnavailableReason ??
        'No compatible save is available for this game.';
    return <RuntimePlayerActionAvailability>[
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.newGame,
      ),
      if (continueEnabled)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        )
      else
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.continueGame,
          reason: unavailableReason,
        ),
      if (continueEnabled)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.load,
        )
      else
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.load,
          reason: unavailableReason,
        ),
    ];
  }

  List<RuntimePlayerActionAvailability> _pauseActions({
    required bool includeReturnToRoot,
  }) {
    return <RuntimePlayerActionAvailability>[
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.resume,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openParty,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openBag,
      ),
      if (_hasCapability('pokedex.v1'))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openPokedex,
        )
      else
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openPokedex,
          reason: 'This game does not provide a Pokédex.',
        ),
      if (_hasCapability('map.v1'))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openMap,
        )
      else
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openMap,
          reason: 'This game does not provide a player map.',
        ),
      RuntimePlayerActionAvailability.disabled(
        RuntimePlayerAction.save,
        reason: 'Saving is not available from this player surface yet.',
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openOptions,
      ),
      RuntimePlayerActionAvailability.disabled(
        RuntimePlayerAction.returnToTitle,
        reason: 'Return to title is not available during this transition.',
      ),
      if (includeReturnToRoot)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToPauseRoot,
        ),
    ];
  }

  bool _hasCapability(String capability) {
    return _sessions.snapshot.descriptor?.grantedCapabilities
            .contains(capability) ??
        false;
  }

  static const _cancelActions = <RuntimePlayerActionAvailability>[
    RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
  ];

  bool get _hasLiveSession =>
      _sessions.snapshot.state != GameSessionState.idle &&
      _sessions.snapshot.state != GameSessionState.disposed;

  void _validateSaveScope(PlayerSaveSummary? save) {
    if (save != null && save.address.gameId != _gameSource.identity.gameId) {
      throw StateError('The selected save belongs to another game.');
    }
  }

  // Kept in one place so a later profile selector cannot accidentally omit
  // the stable game identity.
  SaveSlotAddress _address(RuntimePlayerLoadSlot slot) {
    return SaveSlotAddress(
      gameId: _gameSource.identity.gameId,
      profileId: slot.profileId,
      slotId: slot.slotId,
    );
  }

  void _publish(RuntimePlayerSnapshot next) {
    _snapshot = next;
    if (!_snapshots.isClosed) {
      _snapshots.add(next);
    }
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError('The runtime player coordinator is disposed.');
    }
  }

  Future<T> _serialize<T>(FutureOr<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

final class _RuntimeLaunchRequest {
  const _RuntimeLaunchRequest({
    required this.launchMode,
    required this.profileId,
    required this.slotId,
    this.saveReadHandle,
  });

  final GameSessionLaunchMode launchMode;
  final String profileId;
  final String slotId;
  final String? saveReadHandle;
}
