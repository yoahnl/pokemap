import 'dart:async';
import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/load_runtime_map_bundle.dart';
import '../application/map_activation.dart';
import '../application/player_service_runtime_controller.dart';
import '../player/runtime_world_service_models.dart';
import '../presentation/flame/playable_map_game.dart';
import '../presentation/flame/runtime_input_authority.dart';
import '../presentation/flame/runtime_input_event.dart';
import '../../domain/repositories/game_save_repository.dart';
import 'game_session_contract.dart';
import 'in_process_game_session_adapter.dart';

typedef PlayableMapGameMount = Future<void> Function(PlayableMapGame game);
typedef PlayableMapGameUnmount = Future<void> Function(PlayableMapGame game);
typedef SessionProjectFilePathLoader = Future<String> Function();
typedef SessionInitialSaveLoader = Future<SaveEnvelope?> Function();
typedef SessionSaveIdFactory = String Function();

/// Disposable in-process graph backed by the production `PlayableMapGame`.
///
/// The Flutter shell owns mounting because `GameWidget` must call Flame's
/// lifecycle hooks. This class owns everything after construction and invokes
/// [unmountGame] before clearing Flame components and caches.
final class PlayableMapGameSessionRuntime
    implements
        InProcessGameSessionRuntime,
        GameSessionInputLockPort,
        RuntimeWorldServicePort {
  PlayableMapGameSessionRuntime({
    required this.descriptor,
    required SessionProjectFilePathLoader projectFilePath,
    required SessionInitialSaveLoader initialSave,
    required PlayableMapGameMount mountGame,
    required PlayableMapGameUnmount unmountGame,
    SessionSaveIdFactory? saveIdFactory,
    DateTime Function()? now,
  })  : _projectFilePath = projectFilePath,
        _initialSave = initialSave,
        _mountGame = mountGame,
        _unmountGame = unmountGame,
        _saveIdFactory = saveIdFactory ?? _uuidV4,
        _now = now ?? DateTime.now;

  final GameSessionDescriptor descriptor;
  final SessionProjectFilePathLoader _projectFilePath;
  final SessionInitialSaveLoader _initialSave;
  final PlayableMapGameMount _mountGame;
  final PlayableMapGameUnmount _unmountGame;
  final SessionSaveIdFactory _saveIdFactory;
  final DateTime Function() _now;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  final Stopwatch _playWatch = Stopwatch();

  PlayableMapGame? _game;
  PlayerServiceRuntimeController? _playerServices;
  StreamSubscription<RuntimeWorldServiceSnapshot?>? _playerServiceSnapshots;
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  DateTime? _createdAt;
  String? _saveId;
  int _basePlayTimeSeconds = 0;
  bool _mounted = false;
  bool _completionInFlight = false;
  bool _completionEmitted = false;
  bool _disposed = false;

  PlayableMapGame? get game => _game;

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) {
    final services = _playerServices;
    if (services == null || _disposed) {
      return Future<RuntimeWorldServiceCommandResult>.value(
        const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: 'No contextual world service is active.',
        ),
      );
    }
    return services.dispatchWorldService(command);
  }

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async {
    _ensureNotDisposed();
    if (_game != null) throw StateError('The runtime graph is single-use.');
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'project',
        current: 0,
        total: 4,
      ),
    );
    final projectFilePath = await _projectFilePath();
    final manifest = await loadProjectManifestFromFile(projectFilePath);
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'save',
        current: 1,
        total: 4,
      ),
    );
    final save = await _initialSave();
    _validateInitialSave(save);

    late final String mapId;
    SaveData? saveData;
    GameState? initialState;
    if (descriptor.launchMode == GameSessionLaunchMode.newGame) {
      if (!manifest.newGame.enabled ||
          manifest.newGame.startMapId.trim().isEmpty) {
        throw StateError(
          'The installed project does not define a launchable new game.',
        );
      }
      mapId = manifest.newGame.startMapId;
      _createdAt = _now().toUtc();
      _saveId = _saveIdFactory();
    } else {
      final envelope = save!;
      initialState = const GameStateSaveEnvelopeMapper().restore(envelope);
      mapId = initialState.currentMapId;
      saveData = saveDataFromGameState(initialState);
      _createdAt = envelope.createdAt;
      _saveId = envelope.saveId;
      _basePlayTimeSeconds = envelope.playTimeSeconds;
    }

    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'world',
        current: 2,
        total: 4,
      ),
    );
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: mapId,
    );
    final memorySaves = _SessionMemoryGameSaveRepository(initialState);
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectFilePath,
      saveData: saveData,
      saveRepository: memorySaves,
      initialMapActivationReason:
          descriptor.launchMode == GameSessionLaunchMode.newGame
              ? MapActivationReason.initialBoot
              : MapActivationReason.saveRestore,
    );
    _game = game;
    final playerServices = PlayerServiceRuntimeController.contextual(
      currentGameState: () => game.playerServiceGameStateSnapshot,
      commitAndSave: game.commitAndSavePlayerServiceState,
      setInputLocked: (locked) => game.setExternalInputLock(
        RuntimeExternalInputLock.playerService,
        locked: locked,
      ),
      loadRecoveryCaps: (state) => loadRuntimePlayerServiceRecoveryCaps(
        gameState: state,
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon,
      ),
      conditionContext: ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
          bundle.manifest.facts,
        ),
      ),
      grantedCapabilities: descriptor.grantedCapabilities,
    );
    _playerServices = playerServices;
    _worldServiceSnapshot = playerServices.worldServiceSnapshot;
    _playerServiceSnapshots = playerServices.worldServiceSnapshots.listen(
      _publishWorldService,
    );
    game.setPlayerServiceRuntimeController(playerServices);
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'mount',
        current: 3,
        total: 4,
      ),
    );
    await _mountGame(game);
    _mounted = true;
    _playWatch.start();
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'ready',
        current: 4,
        total: 4,
      ),
    );
  }

  @override
  Future<void> pause() async {
    final game = _requireGame();
    _playWatch.stop();
    game.pauseEngine();
  }

  @override
  Future<void> resume() async {
    final game = _requireGame();
    if (_completionEmitted) {
      throw StateError('A completed game cannot resume gameplay.');
    }
    game.resumeEngine();
    _playWatch.start();
  }

  @override
  Future<void> setInputLock(
    RuntimeExternalInputLock owner, {
    required bool locked,
  }) async {
    _requireGame().setExternalInputLock(owner, locked: locked);
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    final game = _requireGame();
    final saveId = _saveId!;
    final state = game.gameStateSnapshot.copyWith(saveId: saveId);
    final updatedAt = _now().toUtc();
    return GameSessionCheckpoint(
      saveId: saveId,
      createdAt: _createdAt!,
      updatedAt: updatedAt,
      playTimeSeconds: _basePlayTimeSeconds + _playWatch.elapsed.inSeconds,
      state: state.toJson(),
    );
  }

  /// Entry point for the future narrative command adapter.
  ///
  /// It locks input and the game clock before publishing the terminal event.
  Future<void> emitCompletion(GameCompletionRequest request) async {
    if (_completionEmitted || _completionInFlight) return;
    _completionInFlight = true;
    try {
      await lockGameplayForCompletion();
      final checkpoint = (await captureCheckpoint())!;
      final completion = GameCompletionEvent(
        sessionId: descriptor.sessionId,
        gameId: descriptor.identity.gameId,
        endingId: request.endingId,
        outcome: request.outcome,
        completedAt: checkpoint.updatedAt,
        playTimeSeconds: checkpoint.playTimeSeconds,
        result: request.result,
        credits: request.credits,
        destination: request.destination,
        allowPostGameContinue: request.allowPostGameContinue,
        finalCheckpoint: checkpoint,
      );
      _completionEmitted = true;
      if (!_events.isClosed) {
        _events.add(GameSessionCompleted(completion));
      }
    } finally {
      _completionInFlight = false;
    }
  }

  @override
  Future<void> lockGameplayForCompletion() async {
    final game = _requireGame();
    _playWatch.stop();
    game.setExternalInputLock(
      RuntimeExternalInputLock.gameCompletion,
      locked: true,
    );
    game.pauseEngine();
  }

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {
    // Both acceptance and retry keep gameplay locked. The shell decides the
    // next surface; no final-save failure may reveal a live world underneath.
  }

  @override
  Future<void> stop(GameSessionExitReason reason) async {
    final game = _game;
    if (game == null) return;
    _playWatch.stop();
    game.pauseEngine();
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    if (_completionEmitted) return true;
    return _requireGame().handleRuntimeInputEvent(event);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _playWatch.stop();
    await _playerServiceSnapshots?.cancel();
    _playerServiceSnapshots = null;
    final playerServices = _playerServices;
    _playerServices = null;
    await playerServices?.dispose();
    _publishWorldService(null);
    final game = _game;
    _game = null;
    if (game != null && _mounted) {
      await _unmountGame(game);
      _mounted = false;
    }
    // Flame's public dispose clears components plus per-game asset caches.
    game?.dispose();
    await _events.close();
    await _worldServiceSnapshots.close();
  }

  void _validateInitialSave(SaveEnvelope? save) {
    if (descriptor.launchMode == GameSessionLaunchMode.newGame) {
      if (save != null) {
        throw StateError('New Game cannot consume an existing save payload.');
      }
      return;
    }
    if (save == null ||
        save.gameId != descriptor.identity.gameId ||
        save.profileId != descriptor.profileId ||
        save.slotId != descriptor.slotId ||
        save.gameVersion != descriptor.identity.gameVersion ||
        save.saveFormat != descriptor.identity.saveFormat ||
        save.compatibilityId != descriptor.identity.compatibilityId) {
      throw StateError('The selected save does not match the session.');
    }
  }

  PlayableMapGame _requireGame() {
    _ensureNotDisposed();
    final game = _game;
    if (game == null) throw StateError('The playable runtime is not loaded.');
    return game;
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('The playable runtime is disposed.');
  }

  void _publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
    _worldServiceSnapshot = snapshot;
    if (!_worldServiceSnapshots.isClosed) {
      _worldServiceSnapshots.add(snapshot);
    }
  }
}

final class _SessionMemoryGameSaveRepository implements GameSaveRepository {
  _SessionMemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final source = bytes.map(hex).join();
  return '${source.substring(0, 8)}-'
      '${source.substring(8, 12)}-'
      '${source.substring(12, 16)}-'
      '${source.substring(16, 20)}-'
      '${source.substring(20)}';
}
