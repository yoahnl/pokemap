import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../session/game_session_contract.dart';
import '../session/game_session_controller.dart';
import 'runtime_player_host.dart';
import 'runtime_player_models.dart';
import 'runtime_new_game_flow.dart';
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
    required RuntimeNewGameFlowPort newGameFlow,
    required GameSessionController sessionController,
    required RuntimeExternalExit externalExit,
    RuntimePlayerLoadSlot? defaultSaveSlot,
  })  : _gameSource = gameSource,
        _saveGateway = saveGateway,
        _preferencesGateway = preferencesGateway,
        _newGameFlow = newGameFlow,
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
  final RuntimeNewGameFlowPort _newGameFlow;
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
  SaveSlotAddress? _unusableSaveAddress;
  Future<bool>? _activeSaveBoundary;
  HeadlessSceneInteractionPort? _preSessionInteractions;
  StreamSubscription<SceneInteractionRequest>? _preSessionSubscription;
  NewGameSeedCommitJournal _newGameCommitJournal =
      NewGameSeedCommitJournal.empty();
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
    if (command.action == RuntimePlayerAction.resolvePreSessionInteraction) {
      return Future<RuntimePlayerCommandResult>.value(
        _resolvePreSessionInteraction(command),
      );
    }
    if (command.snapshotRevision == _snapshot.revision &&
        _snapshot.phase == RuntimePlayerPhase.saving) {
      switch (command.action) {
        case RuntimePlayerAction.save:
          return Future<RuntimePlayerCommandResult>.value(
            const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.unavailable,
              safeMessage: 'Une sauvegarde est déjà en cours.',
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
        case RuntimePlayerAction.reorderParty:
        case RuntimePlayerAction.openPokedex:
        case RuntimePlayerAction.openMap:
        case RuntimePlayerAction.openOptions:
        case RuntimePlayerAction.updatePreferences:
        case RuntimePlayerAction.returnToPauseRoot:
        case RuntimePlayerAction.showCredits:
        case RuntimePlayerAction.finishCredits:
        case RuntimePlayerAction.cancel:
        case RuntimePlayerAction.resolvePreSessionInteraction:
        case RuntimePlayerAction.deleteUnusableSave:
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
        (_snapshot.phase == RuntimePlayerPhase.preSession ||
            _snapshot.phase == RuntimePlayerPhase.preparingSession ||
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
    _cancelPreSessionInteraction(
      SceneInteractionCancellationReason.superseded,
    );
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
        case RuntimePlayerPhase.preSession:
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
        safeMessage: 'La surface joueur a changé avant l’arrivée de cette action.',
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
            safeMessage: 'Un profil et un emplacement sont requis pour une nouvelle partie.',
          );
        }
        return _launchNewGame(
          _RuntimeLaunchRequest(
            launchMode: GameSessionLaunchMode.newGame,
            profileId: slot.profileId,
            slotId: slot.slotId,
            requestedIdentity: switch (payload) {
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
            safeMessage: 'Aucune sauvegarde compatible n’est disponible pour continuer.',
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
            safeMessage: 'Un profil et un emplacement sont requis pour charger une sauvegarde.',
          );
        }
        final address = _address(slot);
        final save = await _saveGateway.readSummary(address);
        if (save == null || !save.canContinue) {
          if (save != null) {
            _unusableSaveAddress = address;
            _publish(
              _snapshot.next(saveRecovery: _unusableSaveRecovery),
            );
          }
          return RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: save?.unavailableReason == null
                ? 'La sauvegarde choisie est indisponible ou incompatible.'
                : playerSaveUnavailableReasonText(save!.unavailableReason!),
          );
        }
        return _launchSave(save, GameSessionLaunchMode.load);
      case RuntimePlayerAction.deleteUnusableSave:
        return _deleteUnusableSave();
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
                'La sauvegarde finale n’a pas pu être enregistrée.',
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
        return retry.launchMode == GameSessionLaunchMode.newGame
            ? _launchNewGame(retry)
            : _launch(retry);
      case RuntimePlayerAction.openMenu:
        await _sessions.pause();
        final pauseMenuState = await _sessions.loadPauseMenuState();
        final pauseDetails = Map<RuntimePlayerPauseSection,
            RuntimePlayerPauseDetailSnapshot>.from(
          await _sessions.loadPauseDetails(),
        );
        _publishPause(
          RuntimePlayerPauseSection.root,
          pauseMenuState: pauseMenuState,
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
      case RuntimePlayerAction.reorderParty:
        final reorderCommand = command.payload;
        final isReorderKind = reorderCommand is RuntimePlayerPauseCommand &&
            (reorderCommand.kind ==
                    RuntimePlayerPauseCommandKind.reorderPartyMember ||
                reorderCommand.kind ==
                    RuntimePlayerPauseCommandKind.setPartyLead);
        if (!isReorderKind ||
            _snapshot.pauseSection != RuntimePlayerPauseSection.party) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'Deux membres de l’équipe valides sont requis.',
          );
        }
        final reorderResult =
            await _sessions.dispatchPauseCommand(reorderCommand);
        final reorderDetails = Map<RuntimePlayerPauseSection,
            RuntimePlayerPauseDetailSnapshot>.from(
          await _sessions.loadPauseDetails(),
        );
        final party = reorderDetails[RuntimePlayerPauseSection.party];
        if (party != null) {
          reorderDetails[RuntimePlayerPauseSection.party] =
              party.withMessage(reorderResult.safeMessage);
        }
        _publishPause(
          RuntimePlayerPauseSection.party,
          logicalSelectionId: _snapshot.logicalSelectionId,
          pauseDetails: reorderDetails,
        );
        return RuntimePlayerCommandResult(
          status: switch (reorderResult.status) {
            RuntimePlayerPauseCommandStatus.accepted =>
              RuntimePlayerCommandStatus.accepted,
            RuntimePlayerPauseCommandStatus.unavailable =>
              RuntimePlayerCommandStatus.unavailable,
            RuntimePlayerPauseCommandStatus.failed =>
              RuntimePlayerCommandStatus.failed,
          },
          safeMessage: reorderResult.safeMessage,
        );
      case RuntimePlayerAction.useBagItem:
        final pauseCommand = command.payload;
        if (pauseCommand is! RuntimePlayerPauseCommand ||
            _snapshot.pauseSection != RuntimePlayerPauseSection.bag) {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.unavailable,
            safeMessage: 'Un objet du sac et une cible valides sont requis.',
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
            safeMessage: 'Des préférences joueur valides sont requises.',
          );
        }
        try {
          await _preferencesGateway.save(preferences);
        } on Object {
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.failed,
            safeMessage: 'Les préférences du joueur n’ont pas pu être sauvegardées.',
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
                    'La sauvegarde n’a pas pu être enregistrée.',
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
            safeMessage: 'Aucun générique de fin n’est disponible.',
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
      case RuntimePlayerAction.resolvePreSessionInteraction:
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
        safeMessage: 'La surface joueur a changé avant l’arrivée du retour.',
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
      RuntimePlayerPhase.preSession ||
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
        safeMessage: 'Le joueur n’a pas pu revenir à son hôte.',
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
            safeMessage: 'Les données du joueur n’ont pas pu être actualisées.',
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
              safeMessage: 'La sauvegarde n’a pas pu être enregistrée.',
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
          safeMessage: 'La session de jeu n’a pas pu être fermée proprement.',
        ),
        allowRetry: false,
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'La session de jeu n’a pas pu être fermée proprement.',
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
            'La sauvegarde n’a pas pu être enregistrée.',
      );
    }
    return _returnToTitle(checkpoint: false);
  }

  Future<RuntimePlayerCommandResult> _launchNewGame(
    _RuntimeLaunchRequest request,
  ) async {
    if (!_lifecycleActive) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
    final generation = ++_launchGeneration;
    final runId = 'new-game-$generation';
    _retryLaunch = request;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.preSession,
        clearLoadingProgress: true,
        clearFailure: true,
        clearPreSessionRequest: true,
        actions: _cancelActions,
      ),
    );
    final interactions = HeadlessSceneInteractionPort();
    _preSessionInteractions = interactions;
    _preSessionSubscription = interactions.requests.listen((interaction) {
      if (generation != _launchGeneration || _disposed) return;
      _publish(
        _snapshot.next(
          phase: RuntimePlayerPhase.preSession,
          preSessionRequest: interaction,
          actions: _preSessionInteractionActions,
        ),
      );
    });
    var keepPreload = false;
    try {
      final existing = await _saveGateway.readSummary(
        SaveSlotAddress(
          gameId: _gameSource.identity.gameId,
          profileId: request.profileId,
          slotId: request.slotId,
        ),
      );
      if (generation != _launchGeneration) return _finishCancelledLaunch();
      if (existing != null) {
        final overwrite = await interactions.request(
          SceneInteractionRequest.confirmation(
            requestId: '$runId:overwrite',
            revision: 0,
            prompt: _overwritePrompt(existing),
          ),
        );
        if (generation != _launchGeneration) return _finishCancelledLaunch();
        if (overwrite is SceneCancelledInteractionResult ||
            overwrite is! SceneConfirmedInteractionResult ||
            !overwrite.value) {
          _publishTitle();
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.cancelled,
          );
        }
        _publish(
          _snapshot.next(
            phase: RuntimePlayerPhase.preSession,
            clearPreSessionRequest: true,
            actions: _cancelActions,
          ),
        );
      }
      final preparation = await _newGameFlow.prepare();
      if (generation != _launchGeneration) return _finishCancelledLaunch();
      var draft = NewGameDraft.start(
        draftId: '$runId:draft',
        projectRevision: preparation.projectRevision,
        slotId: request.slotId,
        config: preparation.project.newGame,
      );
      draft = _applyRequestedIdentity(draft, request.requestedIdentity);
      draft = _applyUnambiguousFallbacks(draft);
      final runner = preparation.preSessionRunner;
      if (runner != null) {
        draft = await runner.run(
          runId: runId,
          draft: draft,
          interactions: interactions,
        );
      }
      if (generation != _launchGeneration) return _finishCancelledLaunch();
      final currentProjectRevision =
          await _newGameFlow.readCurrentProjectRevision();
      if (generation != _launchGeneration) return _finishCancelledLaunch();
      final commit = commitNewGameDraft(
        journal: _newGameCommitJournal,
        operationId: '$runId:commit',
        currentProjectRevision: currentProjectRevision,
        expectedDraftRevision: draft.revision,
        draft: draft,
      );
      if (commit.status != NewGameSeedCommitStatus.committed &&
          commit.status != NewGameSeedCommitStatus.replayed) {
        throw StateError('The New Game draft could not be committed.');
      }
      _newGameCommitJournal = commit.journal;
      final initialGameState = createNewGameStateFromSeed(
        project: preparation.project,
        startMap: preparation.startMap,
        seed: commit.seed!,
        currentProjectRevision: currentProjectRevision,
        locale: _preferences?.locale ?? 'en',
        tileWidthPx: preparation.project.settings.tileWidth,
        tileHeightPx: preparation.project.settings.tileHeight,
      );
      if (generation != _launchGeneration) return _finishCancelledLaunch();
      final launch = await _launch(
        request.withInitialGameState(initialGameState),
        launchGeneration: generation,
      );
      keepPreload = launch.status == RuntimePlayerCommandStatus.accepted;
      return launch;
    } catch (_) {
      if (generation != _launchGeneration) {
        return _finishCancelledLaunch();
      }
      _publishFailure(
        const GameSessionFailure(
          code: GameSessionFailureCode.runtime,
          recoverability: GameSessionFailureRecoverability.retry,
          safeMessage: 'La nouvelle partie n’a pas pu être préparée.',
        ),
        allowRetry: true,
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'La nouvelle partie n’a pas pu être préparée.',
      );
    } finally {
      await _closePreSessionInteractions(interactions);
      if (!keepPreload) _newGameFlow.clear();
    }
  }

  NewGameDraft _applyRequestedIdentity(
    NewGameDraft draft,
    GameSessionPlayerIdentity? identity,
  ) {
    if (identity == null) return draft;
    var next = _applyDraftCommand(
      draft,
      NewGameDraftCommand.setPlayerName(
        expectedRevision: draft.revision,
        playerName: identity.name,
      ),
    );
    next = _applyDraftCommand(
      next,
      NewGameDraftCommand.setPronouns(
        expectedRevision: next.revision,
        pronounSet: identity.pronounSet,
      ),
    );
    if (identity.avatarCharacterId != null) {
      next = _applyDraftCommand(
        next,
        NewGameDraftCommand.selectAvatar(
          expectedRevision: next.revision,
          avatarCharacterId: identity.avatarCharacterId,
        ),
      );
    }
    return next;
  }

  NewGameDraft _applyUnambiguousFallbacks(NewGameDraft draft) {
    var next = draft;
    if (next.avatarCharacterId == null &&
        next.allowedAvatarCharacterIds.length == 1) {
      next = _applyDraftCommand(
        next,
        NewGameDraftCommand.selectAvatar(
          expectedRevision: next.revision,
          avatarCharacterId: next.allowedAvatarCharacterIds.single,
        ),
      );
    }
    if (next.starterOptionId == null &&
        next.allowedStarterOptionIds.length == 1) {
      next = _applyDraftCommand(
        next,
        NewGameDraftCommand.selectStarter(
          expectedRevision: next.revision,
          starterOptionId: next.allowedStarterOptionIds.single,
        ),
      );
    }
    return next;
  }

  NewGameDraft _applyDraftCommand(
    NewGameDraft draft,
    NewGameDraftCommand command,
  ) {
    final result = draft.apply(command);
    if (result.status != NewGameDraftCommandStatus.applied) {
      throw StateError('The guided New Game selection is invalid.');
    }
    return result.draft;
  }

  RuntimePlayerCommandResult _resolvePreSessionInteraction(
    RuntimePlayerCommand command,
  ) {
    if (command.snapshotRevision != _snapshot.revision) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.stale,
      );
    }
    if (!_snapshot.isActionEnabled(
      RuntimePlayerAction.resolvePreSessionInteraction,
    )) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
      );
    }
    final result = command.payload;
    final interactions = _preSessionInteractions;
    if (result is! SceneInteractionResult || interactions == null) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
      );
    }
    final resolution = interactions.resolve(result);
    if (resolution.status == SceneInteractionResolutionStatus.accepted) {
      _publish(
        _snapshot.next(
          actions: _cancelActions,
        ),
      );
    }
    return RuntimePlayerCommandResult(
      status: switch (resolution.status) {
        SceneInteractionResolutionStatus.accepted =>
          RuntimePlayerCommandStatus.accepted,
        SceneInteractionResolutionStatus.staleRevision ||
        SceneInteractionResolutionStatus.alreadyTerminal =>
          RuntimePlayerCommandStatus.stale,
        SceneInteractionResolutionStatus.unknownRequest ||
        SceneInteractionResolutionStatus.kindMismatch ||
        SceneInteractionResolutionStatus.invalidResult =>
          RuntimePlayerCommandStatus.unavailable,
      },
    );
  }

  void _cancelPreSessionInteraction(
    SceneInteractionCancellationReason reason,
  ) {
    final interactions = _preSessionInteractions;
    final request = interactions?.pendingRequests.firstOrNull;
    if (interactions == null || request == null) return;
    interactions.cancel(
      requestId: request.requestId,
      revision: request.revision,
      reason: reason,
    );
  }

  Future<void> _closePreSessionInteractions(
    HeadlessSceneInteractionPort interactions,
  ) async {
    if (!identical(_preSessionInteractions, interactions)) {
      interactions.close();
      return;
    }
    _preSessionInteractions = null;
    final subscription = _preSessionSubscription;
    _preSessionSubscription = null;
    await subscription?.cancel();
    interactions.close();
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
        safeMessage: 'La sauvegarde sélectionnée n’a pas pu être ouverte en sécurité.',
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
    _RuntimeLaunchRequest request, {
    int? launchGeneration,
  }) async {
    if (!_lifecycleActive) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
    final generation = launchGeneration ?? ++_launchGeneration;
    _retryLaunch = request;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.preparingSession,
        clearPreSessionRequest: true,
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
        initialGameState: request.initialGameState,
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
          safeMessage: 'La session de jeu n’a pas pu être lancée.',
        ),
        allowRetry: true,
      );
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: 'La session de jeu n’a pas pu être lancée.',
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
    _cancelPreSessionInteraction(SceneInteractionCancellationReason.user);
    _newGameFlow.clear();
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
          safeMessage: 'Les données du joueur n’ont pas pu être chargées.',
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
    _cancelPreSessionInteraction(SceneInteractionCancellationReason.disposed);
    _newGameFlow.clear();
    final preSessionSubscription = _preSessionSubscription;
    _preSessionSubscription = null;
    _preSessionInteractions?.close();
    _preSessionInteractions = null;
    await preSessionSubscription?.cancel();
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
                safeMessage: 'La session joueur a échoué.',
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
        clearPreSessionRequest: true,
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
        clearPauseMenuState: true,
        preferences: _preferences,
        hasDiscoveredSave: _latestSave != null,
        continueSave: _latestSave,
        clearContinueSave: _latestSave == null,
        saveRecovery: _titleSaveRecovery,
        clearSaveRecovery: _titleSaveRecovery == null,
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
    PlayerPauseMenuState? pauseMenuState,
    RuntimePlayerSaveReceipt? saveReceipt,
  }) {
    final effectivePauseDetails = pauseDetails ?? _snapshot.pauseDetails;
    final effectivePauseMenuState = pauseMenuState ?? _snapshot.pauseMenuState;
    _publish(
      _snapshot.next(
        phase: RuntimePlayerPhase.paused,
        pauseSection: section,
        logicalSelectionId: logicalSelectionId,
        failure: failure,
        clearFailure: clearFailure,
        pauseDetails: effectivePauseDetails,
        pauseMenuState: effectivePauseMenuState,
        saveReceipt: saveReceipt,
        actions: _pauseActions(
          includeReturnToRoot: section != RuntimePlayerPauseSection.root,
          pauseDetails: effectivePauseDetails,
          pauseMenuState: effectivePauseMenuState,
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
        clearPreSessionRequest: true,
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
    final unavailableReason = save?.unavailableReason == null
        ? 'Aucune sauvegarde compatible n\u2019est disponible pour ce jeu.'
        : playerSaveUnavailableReasonText(save!.unavailableReason!);
    return <RuntimePlayerActionAvailability>[
      if (save != null && !save.canContinue)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.deleteUnusableSave,
        ),
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
    required PlayerPauseMenuState pauseMenuState,
  }) {
    return <RuntimePlayerActionAvailability>[
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.resume,
      ),
      if (_isPauseActionVisible(ProjectPauseActionId.party, pauseMenuState)) ...[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openParty,
        ),
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.reorderParty,
        ),
      ],
      if (_isPauseActionVisible(ProjectPauseActionId.bag, pauseMenuState)) ...[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openBag,
        ),
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.useBagItem,
        ),
      ],
      if (_isPauseActionVisible(ProjectPauseActionId.pokedex, pauseMenuState))
        if (pauseDetails.containsKey(RuntimePlayerPauseSection.pokedex))
          const RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openPokedex,
          )
        else
          RuntimePlayerActionAvailability.disabled(
            RuntimePlayerAction.openPokedex,
            reason: 'This game does not provide a Pokédex.',
          ),
      if (_isPauseActionVisible(ProjectPauseActionId.map, pauseMenuState))
        if (_hasCapability('map.v1'))
          const RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMap,
          )
        else
          RuntimePlayerActionAvailability.disabled(
            RuntimePlayerAction.openMap,
            reason: 'This game does not provide a player map.',
          ),
      if (_isPauseActionVisible(ProjectPauseActionId.save, pauseMenuState))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.save,
        ),
      if (_isPauseActionVisible(ProjectPauseActionId.options, pauseMenuState))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openOptions,
        ),
      if (_isPauseActionVisible(ProjectPauseActionId.options, pauseMenuState))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.updatePreferences,
        ),
      if (_isPauseActionVisible(
        ProjectPauseActionId.returnToTitle,
        pauseMenuState,
      ))
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToTitle,
        ),
      if (includeReturnToRoot)
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToPauseRoot,
        ),
    ];
  }

  bool _isPauseActionVisible(
    ProjectPauseActionId actionId,
    PlayerPauseMenuState pauseMenuState,
  ) {
    return pauseMenuState.isActionVisible(
      actionId,
      projectDefaultVisibility:
          _gameSource.defaultVisiblePauseActions.contains(actionId),
    );
  }

  bool _hasCapability(String capability) {
    return _sessions.snapshot.descriptor?.grantedCapabilities
            .contains(capability) ??
        false;
  }

  static const _cancelActions = <RuntimePlayerActionAvailability>[
    RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
  ];

  static const _preSessionInteractionActions =
      <RuntimePlayerActionAvailability>[
    RuntimePlayerActionAvailability.enabled(
      RuntimePlayerAction.resolvePreSessionInteraction,
    ),
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
  SaveLoadDiagnostic? get _titleSaveRecovery {
    final save = _latestSave;
    if (save == null || save.canContinue) return null;
    _unusableSaveAddress = save.address;
    return _unusableSaveRecovery;
  }

  static const SaveLoadDiagnostic _unusableSaveRecovery = SaveLoadDiagnostic(
    code: SaveLoadFailureCode.unsupportedSchema,
    recommendedActions: <SaveRecoveryAction>[
      SaveRecoveryAction.retry,
      SaveRecoveryAction.deleteSave,
      SaveRecoveryAction.returnToTitle,
    ],
  );

  Future<RuntimePlayerCommandResult> _deleteUnusableSave() async {
    final address = _unusableSaveAddress;
    if (address == null) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.unavailable,
        safeMessage: 'Aucune sauvegarde à réparer n’est sélectionnée.',
      );
    }
    await _saveGateway.deleteSave(address);
    _unusableSaveAddress = null;
    await _loadTitleData();
    _publish(_snapshot.next(clearSaveRecovery: true));
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  SaveSlotAddress _address(RuntimePlayerLoadSlot slot) {
    return SaveSlotAddress(
      gameId: _gameSource.identity.gameId,
      profileId: slot.profileId,
      slotId: slot.slotId,
    );
  }

  SceneInteractionPrompt _overwritePrompt(PlayerSaveSummary existing) {
    final reason = existing.canContinue ? null : existing.unavailableReason;
    if (reason == null) {
      return SceneInteractionPrompt(
        localizationKey: 'player.new_game.confirm_overwrite',
        fallbackText:
            'Cette sauvegarde existe déjà. Voulez-vous la remplacer ?',
      );
    }
    // `reasonCode` voyage à côté de la formulation : un résolveur de
    // localisation choisira sa propre phrase par langue au lieu de réutiliser
    // celle-ci, sans avoir à la reconnaître.
    return SceneInteractionPrompt(
      localizationKey: 'player.new_game.confirm_overwrite_unusable',
      fallbackText:
          'Cette sauvegarde ne peut pas être poursuivie : {reason} '
          'La remplacer effacera définitivement sa progression.',
      arguments: <String, String>{
        'reason': playerSaveUnavailableReasonText(reason),
        'reasonCode': reason.name,
      },
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
    this.requestedIdentity,
    this.initialGameState,
  });

  final GameSessionLaunchMode launchMode;
  final String profileId;
  final String slotId;
  final String? saveReadHandle;
  final GameSessionPlayerIdentity? requestedIdentity;
  final GameState? initialGameState;

  _RuntimeLaunchRequest withInitialGameState(GameState value) {
    return _RuntimeLaunchRequest(
      launchMode: launchMode,
      profileId: profileId,
      slotId: slotId,
      saveReadHandle: saveReadHandle,
      requestedIdentity: requestedIdentity,
      initialGameState: value,
    );
  }
}
