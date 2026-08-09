import 'dart:async';

import 'package:map_core/map_core.dart';

import '../session/game_session_contract.dart';
import '../session/game_session_controller.dart';
import 'runtime_player_host.dart';
import 'runtime_player_models.dart';
import 'runtime_player_pause_data.dart';
import 'runtime_world_service_models.dart';

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
    required RuntimeExternalExit externalExit,
    RuntimePlayerLoadSlot? defaultSaveSlot,
  })  : _gameSource = gameSource,
        _saveGateway = saveGateway,
        _preferencesGateway = preferencesGateway,
        _sessions = sessionController,
        _externalExit = externalExit,
        _defaultSaveSlot = defaultSaveSlot,
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
    _worldServiceSubscription =
        _sessions.worldServiceSnapshots.listen(_onWorldServiceSnapshot);
  }

  final RuntimeGameSource _gameSource;
  final PlayerSaveGateway _saveGateway;
  final PlayerPreferencesGateway _preferencesGateway;
  final GameSessionController _sessions;
  final RuntimeExternalExit _externalExit;
  final RuntimePlayerLoadSlot? _defaultSaveSlot;
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  late final StreamSubscription<GameSessionSnapshot> _sessionSubscription;
  late final StreamSubscription<RuntimeWorldServiceSnapshot?>
      _worldServiceSubscription;
  Future<void> _tail = Future<void>.value();

  RuntimePlayerSnapshot _snapshot;
  PlayerPreferencesSnapshot? _preferences;
  PlayerSaveSummary? _latestSave;
  _RuntimeLaunchRequest? _retryLaunch;
  RuntimePlayerSnapshot? _lifecycleResumeSnapshot;
  Future<bool>? _activeSaveBoundary;
  int _launchGeneration = 0;
  bool _lifecycleActive = true;
  bool _creditsOpenedFromTitle = false;
  bool _disposed = false;

  RuntimePlayerSnapshot get snapshot => _snapshot;
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;
  PlayerPreferencesSnapshot? get preferences => _preferences;
  PlayerSaveSummary? get latestSave => _latestSave;
  bool get isDisposed => _disposed;

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
    if (command.snapshotRevision == _snapshot.revision &&
        _snapshot.phase == RuntimePlayerPhase.saving) {
      switch (command.action) {
        case RuntimePlayerAction.save:
          return Future<RuntimePlayerCommandResult>.value(
            const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.unavailable,
              safeMessage: 'A checkpoint is already in progress.',
            ),
          );
        case RuntimePlayerAction.returnToTitle:
          final boundary = _activeSaveBoundary;
          if (boundary != null) {
            return _serialize(() => _returnToTitleAfterSave(boundary));
          }
        case RuntimePlayerAction.newGame:
        case RuntimePlayerAction.continueGame:
        case RuntimePlayerAction.load:
        case RuntimePlayerAction.retry:
        case RuntimePlayerAction.openMenu:
        case RuntimePlayerAction.resume:
        case RuntimePlayerAction.openParty:
        case RuntimePlayerAction.openBag:
        case RuntimePlayerAction.useBagItem:
        case RuntimePlayerAction.openPokedex:
        case RuntimePlayerAction.openMap:
        case RuntimePlayerAction.openOptions:
        case RuntimePlayerAction.updatePreferences:
        case RuntimePlayerAction.returnToPauseRoot:
        case RuntimePlayerAction.showCredits:
        case RuntimePlayerAction.finishCredits:
        case RuntimePlayerAction.cancel:
        case RuntimePlayerAction.returnToHost:
          break;
      }
    }
    return _serialize(() => _dispatchSerialized(command));
  }

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) {
    _ensureOpen();
    return _sessions.dispatchWorldService(command);
  }

  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) {
    _ensureOpen();
    if (snapshotRevision == _snapshot.revision &&
        (_snapshot.phase == RuntimePlayerPhase.preparingSession ||
            _snapshot.phase == RuntimePlayerPhase.loadingSession)) {
      return _cancel(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.cancel,
          snapshotRevision: snapshotRevision,
        ),
      );
    }
    return _serialize(() => _requestBackSerialized(snapshotRevision));
  }

  Future<void> pauseForLifecycle() {
    _ensureOpen();
    if (!_lifecycleActive) return Future<void>.value();
    // Invalidate a descriptor/session launch synchronously. The serialized
    // lifecycle operation may sit behind that launch, but allocation checks
    // observe this generation change as soon as their current await returns.
    _lifecycleActive = false;
    _launchGeneration++;
    return _serialize(() async {
      _ensureOpen();
      if (_snapshot.phase == RuntimePlayerPhase.lifecyclePaused) return;
      if (_sessions.snapshot.state != GameSessionState.running &&
          _sessions.snapshot.state != GameSessionState.paused) {
        return;
      }
      final resumeSnapshot = _snapshot;
      await _sessions.pauseForLifecycle();
      _lifecycleResumeSnapshot = resumeSnapshot;
      _publish(
        _snapshot.next(
          phase: RuntimePlayerPhase.lifecyclePaused,
          actions: const <RuntimePlayerActionAvailability>[],
        ),
      );
    });
  }

  Future<void> resumeFromLifecycle() {
    _ensureOpen();
    if (_lifecycleActive) return Future<void>.value();
    _lifecycleActive = true;
    return _serialize(() async {
      _ensureOpen();
      if (_snapshot.phase != RuntimePlayerPhase.lifecyclePaused) return;
      final resumeSnapshot = _lifecycleResumeSnapshot;
      if (resumeSnapshot == null) {
        throw StateError('The player lifecycle resume state is missing.');
      }
      await _sessions.resumeFromLifecycle();
      _lifecycleResumeSnapshot = null;
      switch (resumeSnapshot.phase) {
        case RuntimePlayerPhase.paused:
          _publishPause(
            resumeSnapshot.pauseSection ?? RuntimePlayerPauseSection.root,
            logicalSelectionId: resumeSnapshot.logicalSelectionId,
            failure: resumeSnapshot.failure,
            clearFailure: resumeSnapshot.failure == null,
          );
        case RuntimePlayerPhase.playing:
          _publishPlaying();
        case RuntimePlayerPhase.boot:
        case RuntimePlayerPhase.title:
        case RuntimePlayerPhase.preparingSession:
        case RuntimePlayerPhase.loadingSession:
        case RuntimePlayerPhase.saving:
        case RuntimePlayerPhase.lifecyclePaused:
        case RuntimePlayerPhase.completing:
        case RuntimePlayerPhase.result:
        case RuntimePlayerPhase.credits:
        case RuntimePlayerPhase.disposingSession:
        case RuntimePlayerPhase.externalExit:
        case RuntimePlayerPhase.error:
          throw StateError(
            'Unsupported player lifecycle resume phase: '
            '${resumeSnapshot.phase.name}.',
          );
      }
    });
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
        final payload = command.payload;
        final slot = switch (payload) {
          RuntimePlayerNewGameSetup() => payload.slot,
          RuntimePlayerLoadSlot() => payload,
          _ => _defaultSaveSlot,
        };
        if (slot == null) {
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
            initialPlayerIdentity: switch (payload) {
              RuntimePlayerNewGameSetup() => payload.identity,
              _ => null,
            },
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
        final slot = switch (command.payload) {
          RuntimePlayerLoadSlot value => value,
          _ => _defaultSaveSlot,
        };
        if (slot == null) {
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
        if (_snapshot.phase == RuntimePlayerPhase.completing &&
            _sessions.snapshot.state == GameSessionState.completing) {
          await _sessions.retryCompletion();
          if (_sessions.snapshot.state == GameSessionState.completed) {
            _publishCompletionResult();
            return const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted,
            );
          }
          return RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.failed,
            safeMessage: _sessions.snapshot.failure?.safeMessage ??
                'The final checkpoint could not be saved.',
          );
        }
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
        final pauseDetails = Map<RuntimePlayerPauseSection,
            RuntimePlayerPauseDetailSnapshot>.from(
          await _sessions.loadPauseDetails(),
        );
        _publishPause(
          RuntimePlayerPauseSection.root,
          pauseDetails: pauseDetails,
        );
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
      case RuntimePlayerAction.useBagItem:
        final pauseCommand = command.payload;
        if (pauseCommand is! RuntimePlayerPauseCommand ||
            _snapshot.pauseSection != RuntimePlayerPauseSection.bag) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'A valid bag item and target are required.',
          );
        }
        final result = await _sessions.dispatchPauseCommand(pauseCommand);
        final pauseDetails = Map<RuntimePlayerPauseSection,
            RuntimePlayerPauseDetailSnapshot>.from(
          await _sessions.loadPauseDetails(),
        );
        final bag = pauseDetails[RuntimePlayerPauseSection.bag];
        if (bag != null) {
          pauseDetails[RuntimePlayerPauseSection.bag] =
              bag.withMessage(result.safeMessage);
        }
        _publishPause(
          RuntimePlayerPauseSection.bag,
          logicalSelectionId: _snapshot.logicalSelectionId,
          pauseDetails: pauseDetails,
        );
        return RuntimePlayerCommandResult(
          status: switch (result.status) {
            RuntimePlayerPauseCommandStatus.accepted =>
              RuntimePlayerCommandStatus.accepted,
            RuntimePlayerPauseCommandStatus.unavailable =>
              RuntimePlayerCommandStatus.unavailable,
            RuntimePlayerPauseCommandStatus.failed =>
              RuntimePlayerCommandStatus.failed,
          },
          safeMessage: result.safeMessage,
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
        if (_snapshot.phase == RuntimePlayerPhase.title) {
          _publish(
            _snapshot.next(
              pauseSection: RuntimePlayerPauseSection.options,
              logicalSelectionId: 'title.options',
              clearFailure: true,
              actions: _titleOptionsActions,
            ),
          );
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted,
          );
        }
        _publishPause(
          RuntimePlayerPauseSection.options,
          logicalSelectionId: 'pause.options',
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.updatePreferences:
        final preferences = command.payload;
        if (preferences is! PlayerPreferencesSnapshot) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'Valid player preferences are required.',
          );
        }
        try {
          await _preferencesGateway.save(preferences);
        } on Object {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.failed,
            safeMessage: 'Player preferences could not be saved.',
          );
        }
        _preferences = preferences;
        _publish(_snapshot.next(preferences: preferences));
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
      case RuntimePlayerAction.save:
        final section =
            _snapshot.pauseSection ?? RuntimePlayerPauseSection.root;
        final logicalSelectionId = _snapshot.logicalSelectionId;
        final boundary = Completer<bool>();
        final boundaryFuture = boundary.future;
        _activeSaveBoundary = boundaryFuture;
        _publish(
          _snapshot.next(
            phase: RuntimePlayerPhase.saving,
            actions: const <RuntimePlayerActionAvailability>[],
            clearFailure: true,
          ),
        );
        try {
          final saved = await _sessions.requestCheckpoint();
          _publishPause(
            section,
            logicalSelectionId: logicalSelectionId,
            failure: saved ? null : _sessions.snapshot.failure,
            clearFailure: saved,
            saveReceipt: saved
                ? RuntimePlayerSaveReceipt(
                    address: _activeSaveAddress!,
                    trigger: GameSessionCheckpointTrigger.manual,
                  )
                : null,
          );
          boundary.complete(saved);
          return RuntimePlayerCommandResult(
            status: saved
                ? RuntimePlayerCommandStatus.accepted
                : RuntimePlayerCommandStatus.failed,
            safeMessage: saved
                ? null
                : _sessions.snapshot.failure?.safeMessage ??
                    'The checkpoint could not be saved.',
          );
        } catch (error, stackTrace) {
          boundary.complete(false);
          Error.throwWithStackTrace(error, stackTrace);
        } finally {
          if (identical(_activeSaveBoundary, boundaryFuture)) {
            _activeSaveBoundary = null;
          }
        }
      case RuntimePlayerAction.showCredits:
        final completion = _sessions.committedCompletion;
        final openedFromTitle = _snapshot.phase == RuntimePlayerPhase.title;
        if (completion == null && !openedFromTitle) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'No completed game credits are available.',
          );
        }
        _creditsOpenedFromTitle = openedFromTitle;
        _publish(
          _snapshot.next(
            phase: RuntimePlayerPhase.credits,
            result: completion?.result,
            credits: completion?.credits,
            clearResult: completion == null,
            clearCredits: completion == null,
            clearFailure: true,
            actions: openedFromTitle
                ? _titleCreditsActions
                : _creditsActions(completion!),
          ),
        );
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        );
      case RuntimePlayerAction.finishCredits:
        if (_creditsOpenedFromTitle) {
          _publishTitle();
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted,
          );
        }
        if (_sessions.committedCompletion?.destination ==
            GameCompletionDestination.hub) {
          return _returnToHost();
        }
        return _returnToTitle(checkpoint: false);
      case RuntimePlayerAction.returnToTitle:
        if (_snapshot.phase == RuntimePlayerPhase.title ||
            (!_hasLiveSession &&
                _snapshot.phase == RuntimePlayerPhase.credits)) {
          _publishTitle();
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted,
          );
        }
        return _returnToTitle(
          checkpoint: _snapshot.phase == RuntimePlayerPhase.paused,
        );
      case RuntimePlayerAction.cancel:
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.unavailable,
          safeMessage: 'This action is not available on the current surface.',
        );
      case RuntimePlayerAction.returnToHost:
        return _returnToHost();
    }
  }

  Future<RuntimePlayerCommandResult> _requestBackSerialized(
    int snapshotRevision,
  ) async {
    if (snapshotRevision != _snapshot.revision) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.stale,
        safeMessage: 'The player surface changed before Back arrived.',
      );
    }
    final worldService = _snapshot.worldService;
    if (worldService != null) {
      final action = worldService.isActionEnabled(
        RuntimeWorldServiceAction.close,
      )
          ? RuntimeWorldServiceAction.close
          : worldService.isActionEnabled(RuntimeWorldServiceAction.cancel)
              ? RuntimeWorldServiceAction.cancel
              : null;
      if (action == null) {
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.unavailable,
        );
      }
      final result = await _sessions.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: action,
          snapshotRevision: worldService.revision,
        ),
      );
      return RuntimePlayerCommandResult(
        status: switch (result.status) {
          RuntimeWorldServiceCommandStatus.accepted =>
            RuntimePlayerCommandStatus.accepted,
          RuntimeWorldServiceCommandStatus.stale =>
            RuntimePlayerCommandStatus.stale,
          RuntimeWorldServiceCommandStatus.unavailable =>
            RuntimePlayerCommandStatus.unavailable,
          RuntimeWorldServiceCommandStatus.cancelled =>
            RuntimePlayerCommandStatus.cancelled,
          RuntimeWorldServiceCommandStatus.failed =>
            RuntimePlayerCommandStatus.failed,
        },
        safeMessage: result.safeMessage,
      );
    }
    final action = switch (_snapshot.phase) {
      RuntimePlayerPhase.title
          when _snapshot.pauseSection == RuntimePlayerPauseSection.options =>
        RuntimePlayerAction.returnToTitle,
      RuntimePlayerPhase.title => RuntimePlayerAction.returnToHost,
      RuntimePlayerPhase.preparingSession ||
      RuntimePlayerPhase.loadingSession ||
      RuntimePlayerPhase.error =>
        RuntimePlayerAction.cancel,
      RuntimePlayerPhase.playing => RuntimePlayerAction.openMenu,
      RuntimePlayerPhase.paused
          when _snapshot.pauseSection != null &&
              _snapshot.pauseSection != RuntimePlayerPauseSection.root =>
        RuntimePlayerAction.returnToPauseRoot,
      RuntimePlayerPhase.paused => RuntimePlayerAction.resume,
      RuntimePlayerPhase.result => _snapshot.isActionEnabled(
          RuntimePlayerAction.returnToHost,
        )
            ? RuntimePlayerAction.returnToHost
            : RuntimePlayerAction.returnToTitle,
      RuntimePlayerPhase.credits => RuntimePlayerAction.finishCredits,
      RuntimePlayerPhase.boot ||
      RuntimePlayerPhase.saving ||
      RuntimePlayerPhase.lifecyclePaused ||
      RuntimePlayerPhase.completing ||
      RuntimePlayerPhase.disposingSession ||
      RuntimePlayerPhase.externalExit =>
        null,
    };
    if (action == null) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
      );
    }
    final command = RuntimePlayerCommand(
      action: action,
      snapshotRevision: snapshotRevision,
    );
    if (action == RuntimePlayerAction.cancel) return _cancel(command);
    return _dispatchSerialized(command);
  }

  Future<RuntimePlayerCommandResult> _returnToHost() async {
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.externalExit,
        actions: const <RuntimePlayerActionAvailability>[],
      ),
    );
    try {
      await _disposeOwnedResources();
      await _externalExit.returnToHost();
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      );
    } catch (_) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'The player could not return to its host.',
      );
    }
  }

  Future<RuntimePlayerCommandResult> _returnToTitle({
    required bool checkpoint,
  }) async {
    final pauseSection =
        _snapshot.pauseSection ?? RuntimePlayerPauseSection.root;
    final logicalSelectionId = _snapshot.logicalSelectionId;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.disposingSession,
        actions: const <RuntimePlayerActionAvailability>[],
        clearFailure: true,
      ),
    );
    try {
      await _sessions.returnToTitle(checkpoint: checkpoint);
      if (_sessions.snapshot.state == GameSessionState.disposed) {
        final loaded = await _loadTitleData(
          failure: _sessions.snapshot.failure,
        );
        if (!loaded) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.failed,
            safeMessage: 'Player data could not be refreshed.',
          );
        }
      }
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      );
    } on GameSessionException catch (error) {
      if (error.code == GameSessionErrorCode.checkpointRejected &&
          _sessions.snapshot.state == GameSessionState.paused) {
        final failure = _sessions.snapshot.failure ??
            const GameSessionFailure(
              code: GameSessionFailureCode.storage,
              recoverability: GameSessionFailureRecoverability.retry,
              safeMessage: 'The checkpoint could not be saved.',
            );
        _publishPause(
          pauseSection,
          logicalSelectionId: logicalSelectionId,
          failure: failure,
        );
        return RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.failed,
          safeMessage: failure.safeMessage,
        );
      }
      _publishFailure(
        const GameSessionFailure(
          code: GameSessionFailureCode.runtime,
          recoverability: GameSessionFailureRecoverability.titleOrHub,
          safeMessage: 'The game session could not be closed safely.',
        ),
        allowRetry: false,
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'The game session could not be closed safely.',
      );
    }
  }

  Future<RuntimePlayerCommandResult> _returnToTitleAfterSave(
    Future<bool> boundary,
  ) async {
    final saved = await boundary;
    if (!saved) {
      return RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: _sessions.snapshot.failure?.safeMessage ??
            'The checkpoint could not be saved.',
      );
    }
    return _returnToTitle(checkpoint: false);
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
    if (!_lifecycleActive) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
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
        initialPlayerIdentity: request.initialPlayerIdentity,
      );
      if (generation != _launchGeneration) {
        return _finishCancelledLaunch();
      }
      await _sessions.prepare(descriptor);
      if (generation != _launchGeneration) {
        await _sessions.terminate();
        return _finishCancelledLaunch();
      }
      await _sessions.start();
      if (generation != _launchGeneration) {
        await _cancelLiveSession();
        return _finishCancelledLaunch();
      }
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      );
    } catch (_) {
      if (generation != _launchGeneration) {
        return _finishCancelledLaunch();
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

  RuntimePlayerCommandResult _finishCancelledLaunch() {
    if (!_disposed && _snapshot.phase != RuntimePlayerPhase.title) {
      _publishTitle();
    }
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.cancelled,
    );
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

  Future<bool> _loadTitleData({GameSessionFailure? failure}) async {
    try {
      final titleData = await Future.wait<Object?>(
        <Future<Object?>>[
          _preferencesGateway.load(),
          _saveGateway.readLatestSummary(),
        ],
        eagerError: false,
      );
      _preferences = titleData[0]! as PlayerPreferencesSnapshot;
      _latestSave = titleData[1] as PlayerSaveSummary?;
      _validateSaveScope(_latestSave);
      _retryLaunch = null;
      _publishTitle(failure: failure);
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
    await _disposeOwnedResources();
  }

  Future<void> _disposeOwnedResources() async {
    if (_disposed) return;
    _disposed = true;
    _launchGeneration++;
    await _cancelLiveSession();
    await _worldServiceSubscription.cancel();
    await _sessionSubscription.cancel();
    await _sessions.dispose();
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
        if (_snapshot.phase != RuntimePlayerPhase.paused &&
            _snapshot.phase != RuntimePlayerPhase.saving) {
          _publishPause(RuntimePlayerPauseSection.root);
        }
      case GameSessionState.lifecyclePaused:
        return;
      case GameSessionState.completing:
        _publish(
          _snapshot.next(
            phase: RuntimePlayerPhase.completing,
            failure: session.failure,
            clearFailure: session.failure == null,
            actions: session.completionCommitFailed
                ? const <RuntimePlayerActionAvailability>[
                    RuntimePlayerActionAvailability.enabled(
                      RuntimePlayerAction.retry,
                    ),
                  ]
                : const <RuntimePlayerActionAvailability>[],
          ),
        );
      case GameSessionState.completed:
        _publishCompletionResult();
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
        if (session.exitReason == GameSessionExitReason.cancelled ||
            session.exitReason == GameSessionExitReason.title) {
          _publishTitle(failure: session.failure);
        }
    }
  }

  void _onWorldServiceSnapshot(RuntimeWorldServiceSnapshot? service) {
    if (_disposed || identical(_snapshot.worldService, service)) return;
    _publish(
      _snapshot.next(
        worldService: service,
        clearWorldService: service == null,
      ),
    );
  }

  void _publishTitle({GameSessionFailure? failure}) {
    _creditsOpenedFromTitle = false;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.title,
        clearPauseSection: true,
        clearLoadingProgress: true,
        failure: failure,
        clearFailure: failure == null,
        clearResult: true,
        clearCredits: true,
        clearLogicalSelection: true,
        clearWorldService: true,
        clearActiveSaveAddress: true,
        clearSaveReceipt: true,
        preferences: _preferences,
        hasDiscoveredSave: _latestSave != null,
        continueSave: _latestSave,
        clearContinueSave: _latestSave == null,
        actions: _titleActions,
      ),
    );
  }

  void _publishPlaying() {
    final activeSaveAddress = _activeSaveAddress;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.playing,
        clearPauseSection: true,
        clearPauseDetails: true,
        clearLoadingProgress: true,
        clearFailure: true,
        clearWorldService: true,
        activeSaveAddress: activeSaveAddress,
        clearSaveReceipt: true,
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
    GameSessionFailure? failure,
    bool clearFailure = false,
    Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>?
        pauseDetails,
    RuntimePlayerSaveReceipt? saveReceipt,
  }) {
    final effectivePauseDetails = pauseDetails ?? _snapshot.pauseDetails;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.paused,
        pauseSection: section,
        logicalSelectionId: logicalSelectionId,
        failure: failure,
        clearFailure: clearFailure,
        pauseDetails: effectivePauseDetails,
        saveReceipt: saveReceipt,
        actions: _pauseActions(
          includeReturnToRoot: section != RuntimePlayerPauseSection.root,
          pauseDetails: effectivePauseDetails,
        ),
      ),
    );
  }

  RuntimePlayerSaveAddress? get _activeSaveAddress {
    final descriptor = _sessions.snapshot.descriptor;
    if (descriptor == null) return null;
    return RuntimePlayerSaveAddress(
      gameId: descriptor.identity.gameId,
      profileId: descriptor.profileId,
      slotId: descriptor.slotId,
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

  void _publishCompletionResult() {
    final completion = _sessions.committedCompletion;
    if (completion == null || _snapshot.phase == RuntimePlayerPhase.result) {
      return;
    }
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.result,
        clearPauseSection: true,
        clearLoadingProgress: true,
        clearFailure: true,
        clearWorldService: true,
        result: completion.result,
        credits: completion.credits,
        actions: _resultActions(completion),
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
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openOptions,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.showCredits,
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
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.returnToHost,
      ),
    ];
  }

  static const _titleOptionsActions = <RuntimePlayerActionAvailability>[
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.openOptions,
    ),
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.updatePreferences,
    ),
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.returnToTitle,
    ),
  ];

  static const _titleCreditsActions = <RuntimePlayerActionAvailability>[
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.finishCredits,
    ),
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.returnToTitle,
    ),
  ];

  List<RuntimePlayerActionAvailability> _pauseActions({
    required bool includeReturnToRoot,
    required Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>
        pauseDetails,
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
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.useBagItem,
      ),
      if (pauseDetails.containsKey(RuntimePlayerPauseSection.pokedex))
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
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.save,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.openOptions,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.updatePreferences,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.returnToTitle,
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

  List<RuntimePlayerActionAvailability> _resultActions(
    GameCompletionEvent completion,
  ) =>
      <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.showCredits,
        ),
        RuntimePlayerActionAvailability.enabled(
          completion.destination == GameCompletionDestination.hub
              ? RuntimePlayerAction.returnToHost
              : RuntimePlayerAction.returnToTitle,
        ),
      ];

  List<RuntimePlayerActionAvailability> _creditsActions(
    GameCompletionEvent completion,
  ) =>
      <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.finishCredits,
        ),
        RuntimePlayerActionAvailability.enabled(
          completion.destination == GameCompletionDestination.hub
              ? RuntimePlayerAction.returnToHost
              : RuntimePlayerAction.returnToTitle,
        ),
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
    this.initialPlayerIdentity,
  });

  final GameSessionLaunchMode launchMode;
  final String profileId;
  final String slotId;
  final String? saveReadHandle;
  final GameSessionPlayerIdentity? initialPlayerIdentity;
}
