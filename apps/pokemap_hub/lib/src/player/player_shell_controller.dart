import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../saves/hub_save_store.dart';
import '../saves/save_storage_diagnostic.dart';
import '../session/installed_game_launch_resolver.dart';
import '../session/save_read_handle.dart';
import 'player_shell_models.dart';

typedef PlayerOpaqueIdFactory = String Function();

/// Product navigation root for title, runtime, result and credits.
///
/// Widgets remain a Phase 5 concern. This controller provides the stable
/// snapshots and commands needed by those widgets without importing editor or
/// developer-host code.
final class PlayerShellController {
  PlayerShellController({
    required this.launch,
    required this.saves,
    required this.sessions,
    PlayerOpaqueIdFactory? sessionIdFactory,
    PlayerOpaqueIdFactory? sessionTokenFactory,
    this.accessibility = const GameSessionAccessibilityOptions(),
  })  : _sessionIdFactory =
            sessionIdFactory ?? (() => _secureOpaqueId('session')),
        _sessionTokenFactory =
            sessionTokenFactory ?? (() => _secureOpaqueId('token')),
        _snapshot = PlayerShellSnapshot(
          state: PlayerShellState.title,
          title: PlayerTitleSnapshot(
            state: PlayerTitleState.titleIdle,
            gameTitle: launch.manifest.title,
            author: launch.manifest.author.name,
            description: launch.manifest.description,
            enabledActions: const <PlayerTitleAction>{},
          ),
        ) {
    if (launch.identity != saves.identity) {
      throw ArgumentError(
        'The player shell save store must match the launch identity.',
      );
    }
    _sessionSubscription = sessions.snapshots.listen(_onSessionSnapshot);
  }

  final InstalledGameLaunchContext launch;
  final HubSaveStore saves;
  final GameSessionController sessions;
  final GameSessionAccessibilityOptions accessibility;
  final PlayerOpaqueIdFactory _sessionIdFactory;
  final PlayerOpaqueIdFactory _sessionTokenFactory;
  final _snapshots = StreamController<PlayerShellSnapshot>.broadcast();
  late final StreamSubscription<GameSessionSnapshot> _sessionSubscription;

  PlayerShellSnapshot _snapshot;
  SaveSlotRead? _continueSave;
  bool _launching = false;
  bool _disposed = false;

  PlayerShellSnapshot get snapshot => _snapshot;
  Stream<PlayerShellSnapshot> get snapshots => _snapshots.stream;

  PlayerInputSurface get inputSurface => switch (_snapshot.state) {
        PlayerShellState.title => PlayerInputSurface.title,
        PlayerShellState.playing => PlayerInputSurface.gameplay,
        PlayerShellState.paused => PlayerInputSurface.pause,
        PlayerShellState.result => PlayerInputSurface.result,
        PlayerShellState.credits => PlayerInputSurface.credits,
        _ => PlayerInputSurface.blocked,
      };

  Future<void> initialize() async {
    _ensureOpen();
    if (_hasLiveSession) {
      throw StateError('Cannot refresh the title while a session is active.');
    }
    await _refreshTitle();
  }

  void openOptions() {
    _requireTitle();
    _publish(
      _snapshot.copyWith(
        title: _snapshot.title.copyWith(state: PlayerTitleState.options),
      ),
    );
  }

  void openAbout() {
    _requireTitle();
    _publish(
      _snapshot.copyWith(
        title: _snapshot.title.copyWith(state: PlayerTitleState.creditsAbout),
      ),
    );
  }

  void closeTitleSubstate() {
    _requireTitle();
    _publish(
      _snapshot.copyWith(
        title: _snapshot.title.copyWith(state: PlayerTitleState.titleIdle),
      ),
    );
  }

  Future<PlayerLaunchResult> continueGame() async {
    _requireTitle();
    final save = _continueSave ?? await saves.findContinue();
    if (save == null || !save.canContinue || save.envelope == null) {
      return PlayerLaunchResult.unavailable;
    }
    return _launchSave(save, GameSessionLaunchMode.continueGame);
  }

  Future<PlayerLaunchResult> loadSlot({
    required String profileId,
    required String slotId,
  }) async {
    _requireTitle();
    final save = await saves.read(
      SaveSlotAddress(
        gameId: launch.identity.gameId,
        profileId: profileId,
        slotId: slotId,
      ),
    );
    if (!save.canContinue || save.envelope == null) {
      return PlayerLaunchResult.incompatibleSave;
    }
    return _launchSave(save, GameSessionLaunchMode.load);
  }

  Future<PlayerLaunchResult> startNewGame({
    required String profileId,
    required String slotId,
    bool overwriteConfirmed = false,
  }) async {
    _requireTitle();
    final address = SaveSlotAddress(
      gameId: launch.identity.gameId,
      profileId: profileId,
      slotId: slotId,
    );
    final existing = await saves.read(address);
    if (existing.status != SaveSlotReadStatus.missing && !overwriteConfirmed) {
      _publish(
        _snapshot.copyWith(
          title: _snapshot.title.copyWith(
            state: PlayerTitleState.confirmingOverwrite,
          ),
        ),
      );
      return PlayerLaunchResult.overwriteConfirmationRequired;
    }
    return _launchDescriptor(
      profileId: profileId,
      slotId: slotId,
      mode: GameSessionLaunchMode.newGame,
    );
  }

  Future<void> togglePause() async {
    switch (_snapshot.state) {
      case PlayerShellState.playing:
        await sessions.pause();
      case PlayerShellState.paused:
        await sessions.resume();
      default:
        throw StateError('Pause is unavailable in ${_snapshot.state.name}.');
    }
  }

  Future<void> pauseForLifecycle() async {
    const pausable = <GameSessionState>{
      GameSessionState.starting,
      GameSessionState.loading,
      GameSessionState.running,
      GameSessionState.paused,
    };
    if (!pausable.contains(sessions.snapshot.state)) return;
    await sessions.pauseForLifecycle();
  }

  Future<void> resumeFromLifecycle() async {
    if (sessions.snapshot.state != GameSessionState.lifecyclePaused) return;
    await sessions.resumeFromLifecycle();
  }

  void showCredits() {
    if (_snapshot.state != PlayerShellState.result ||
        _snapshot.credits == null) {
      throw StateError('Credits are available only after a committed result.');
    }
    _publish(_snapshot.copyWith(state: PlayerShellState.credits));
  }

  Future<void> finishCredits(GameCompletionDestination destination) async {
    if (_snapshot.state != PlayerShellState.credits) {
      throw StateError('The credits screen is not active.');
    }
    if (destination != GameCompletionDestination.title &&
        destination != GameCompletionDestination.hub) {
      throw ArgumentError.value(
        destination,
        'destination',
        'A concrete title or Hub destination is required.',
      );
    }
    final allowed = _snapshot.completionDestination;
    if (allowed != GameCompletionDestination.playerChoice &&
        allowed != destination) {
      throw StateError('This ending does not allow the selected destination.');
    }
    _publish(_snapshot.copyWith(state: PlayerShellState.disposingSession));
    if (destination == GameCompletionDestination.title) {
      await sessions.returnToTitle(checkpoint: false);
      await _refreshTitle();
    } else if (destination == GameCompletionDestination.hub) {
      await sessions.returnToHub(checkpoint: false);
    }
  }

  Future<void> returnToTitle({
    bool abandonCheckpointFailure = false,
  }) async {
    if (!_hasLiveSession) return;
    _publish(_snapshot.copyWith(state: PlayerShellState.disposingSession));
    await sessions.returnToTitle(
      abandonCheckpointFailure: abandonCheckpointFailure,
    );
    await _refreshTitle();
  }

  Future<void> returnToHub({
    bool abandonCheckpointFailure = false,
  }) async {
    if (!_hasLiveSession) {
      _publish(_snapshot.copyWith(state: PlayerShellState.hub));
      return;
    }
    _publish(_snapshot.copyWith(state: PlayerShellState.disposingSession));
    await sessions.returnToHub(
      abandonCheckpointFailure: abandonCheckpointFailure,
    );
  }

  Future<void> settle() async {
    await sessions.settle();
    await Future<void>.delayed(Duration.zero);
    await sessions.settle();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _sessionSubscription.cancel();
    await sessions.dispose();
    await _snapshots.close();
  }

  Future<PlayerLaunchResult> _launchSave(
    SaveSlotRead save,
    GameSessionLaunchMode mode,
  ) {
    final envelope = save.envelope!;
    return _launchDescriptor(
      profileId: save.address.profileId,
      slotId: save.address.slotId,
      mode: mode,
      saveReadHandle: hubSaveReadHandle(envelope),
    );
  }

  Future<PlayerLaunchResult> _launchDescriptor({
    required String profileId,
    required String slotId,
    required GameSessionLaunchMode mode,
    String? saveReadHandle,
  }) async {
    if (_launching || _snapshot.state != PlayerShellState.title) {
      return PlayerLaunchResult.unavailable;
    }
    _launching = true;
    _publish(
      _snapshot.copyWith(
        state: PlayerShellState.preparingSession,
        clearFailure: true,
        clearResult: true,
        clearCredits: true,
        clearCompletionDestination: true,
      ),
    );
    try {
      final descriptor = GameSessionDescriptor(
        sessionId: _sessionIdFactory(),
        sessionToken: _sessionTokenFactory(),
        identity: launch.identity,
        profileId: profileId,
        slotId: slotId,
        launchMode: mode,
        installedVersionHandle: launch.installedVersionHandle,
        saveReadHandle: saveReadHandle,
        runtimeApiVersion: launch.runtimeApiVersion,
        grantedCapabilities: launch.grantedCapabilities,
        locale: launch.manifest.locales.defaultLocale,
        accessibility: accessibility,
      );
      await sessions.prepare(descriptor);
      await sessions.start();
      return PlayerLaunchResult.started;
    } catch (_) {
      _publish(
        _snapshot.copyWith(
          state: PlayerShellState.error,
          failure: const GameSessionFailure(
            code: GameSessionFailureCode.runtime,
            recoverability: GameSessionFailureRecoverability.titleOrHub,
            safeMessage: 'The game session could not be launched.',
          ),
        ),
      );
      rethrow;
    } finally {
      _launching = false;
    }
  }

  Future<void> _refreshTitle() async {
    final latest = await saves.findContinue();
    _continueSave = latest;
    final actions = <PlayerTitleAction>{
      PlayerTitleAction.newGame,
      PlayerTitleAction.options,
      PlayerTitleAction.creditsAbout,
      PlayerTitleAction.returnToHub,
      if (latest != null && latest.canContinue) PlayerTitleAction.continueGame,
      if (latest != null) PlayerTitleAction.load,
    };
    _publish(
      _snapshot.copyWith(
        state: PlayerShellState.title,
        title: _snapshot.title.copyWith(
          state: PlayerTitleState.titleIdle,
          enabledActions: actions,
          continueAddress: latest?.address,
          continueUpdatedAt: latest?.envelope?.updatedAt,
          clearContinue: latest == null,
        ),
        clearLoadingProgress: true,
        clearFailure: true,
        clearResult: true,
        clearCredits: true,
        clearCompletionDestination: true,
      ),
    );
  }

  void _onSessionSnapshot(GameSessionSnapshot session) {
    if (_disposed) return;
    switch (session.state) {
      case GameSessionState.idle:
      case GameSessionState.preparing:
      case GameSessionState.prepared:
      case GameSessionState.starting:
        _publish(
          _snapshot.copyWith(state: PlayerShellState.preparingSession),
        );
      case GameSessionState.loading:
        _publish(
          _snapshot.copyWith(
            state: PlayerShellState.loadingSession,
            loadingProgress: session.loadingProgress,
          ),
        );
      case GameSessionState.running:
        _publish(
          _snapshot.copyWith(
            state: PlayerShellState.playing,
            clearLoadingProgress: true,
          ),
        );
      case GameSessionState.paused:
        _publish(_snapshot.copyWith(state: PlayerShellState.paused));
      case GameSessionState.lifecyclePaused:
        _publish(_snapshot.copyWith(state: PlayerShellState.lifecyclePaused));
      case GameSessionState.completing:
        _publish(
          _snapshot.copyWith(
            state: PlayerShellState.completing,
            failure: session.failure,
          ),
        );
      case GameSessionState.completed:
        final completion = sessions.committedCompletion;
        if (completion != null) {
          _publish(
            _snapshot.copyWith(
              state: PlayerShellState.result,
              result: completion.result,
              credits: completion.credits,
              completionDestination: completion.destination,
              clearFailure: true,
            ),
          );
        }
      case GameSessionState.failed:
        _publish(
          _snapshot.copyWith(
            state: PlayerShellState.error,
            failure: session.failure,
          ),
        );
      case GameSessionState.stopping:
        _publish(
          _snapshot.copyWith(state: PlayerShellState.disposingSession),
        );
      case GameSessionState.disposed:
        if (session.exitReason == GameSessionExitReason.hub) {
          _publish(_snapshot.copyWith(state: PlayerShellState.hub));
        }
    }
  }

  bool get _hasLiveSession =>
      sessions.snapshot.state != GameSessionState.idle &&
      sessions.snapshot.state != GameSessionState.disposed;

  void _requireTitle() {
    _ensureOpen();
    if (_snapshot.state != PlayerShellState.title) {
      throw StateError('The player title is not active.');
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('The player shell is disposed.');
  }

  void _publish(PlayerShellSnapshot next) {
    _snapshot = next;
    if (!_snapshots.isClosed) _snapshots.add(next);
  }
}

String _secureOpaqueId(String prefix) {
  final random = Random.secure();
  final bytes = List<int>.generate(18, (_) => random.nextInt(256));
  return '$prefix-${base64UrlEncode(bytes).replaceAll('=', '')}';
}
