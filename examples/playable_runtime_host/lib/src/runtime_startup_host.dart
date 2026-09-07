import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart' show PlayerPreferences;
import 'package:map_player_ui/presentation_renderer.dart'
    show
        PresentationMediaAliasStore,
        RuntimePresentationSessionRuntime,
        resolveProjectDirectoryAssetFile;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'runtime_launch_save.dart';
import 'runtime_atomic_json.dart';

const standaloneRuntimeProfileId = 'default';
const standaloneRuntimeSlotId = 'main';

const standaloneRuntimeSplashBranding = RuntimeHostSplashBranding(
  displayName: 'POKÉMAP',
  signature: 'CRÉEZ · JOUEZ · PARTAGEZ',
  primaryColorHex: '#E8C79C',
  secondaryColorHex: '#6F8F7A',
);

/// Narrow host boundary around the developer runtime already embedded by the
/// standalone example. The startup stack owns when a session starts; this port
/// keeps the host's debug overlays and project picker outside `map_runtime`.
abstract interface class StandaloneRuntimeSessionPort
    implements RuntimePlayerPauseCommandPort {
  Future<void> launch(
    GameSessionDescriptor descriptor,
    GameSessionProgressReporter reportProgress,
    RuntimeInitialMapPreloadResult? preloadedInitialMap,
  );

  Future<void> pause();
  Future<void> resume();
  Future<GameSessionCheckpoint?> captureCheckpoint();
  Future<void> stop(GameSessionExitReason reason);
  Future<void> dispose();
  bool handleInput(RuntimeInputEvent event);
}

/// Callback implementation used by the Flutter developer host and focused
/// launch tests. It deliberately contains no startup or title-screen state.
final class CallbackStandaloneRuntimeSessionPort
    implements StandaloneRuntimeSessionPort, RuntimePlayerPreferencesPort {
  CallbackStandaloneRuntimeSessionPort({
    required this.onLaunch,
    this.onPreferencesChanged,
    Future<void> Function()? onPause,
    Future<void> Function()? onResume,
    Future<GameSessionCheckpoint?> Function()? onCaptureCheckpoint,
    Future<RuntimePlayerPauseCommandResult> Function(
      RuntimePlayerPauseCommand command,
    )?
    onPauseCommand,
    Future<void> Function(GameSessionExitReason reason)? onStop,
    Future<void> Function()? onDispose,
    bool Function(RuntimeInputEvent event)? onInput,
  }) : _onPause = onPause ?? _noOp,
       _onResume = onResume ?? _noOp,
       _onCaptureCheckpoint = onCaptureCheckpoint ?? _noCheckpoint,
       _onPauseCommand = onPauseCommand,
       _onStop = onStop ?? _noOpStop,
       _onDispose = onDispose ?? _noOp,
       _onInput = onInput ?? _ignoreInput;

  final Future<void> Function(
    GameSessionDescriptor descriptor,
    GameSessionProgressReporter reportProgress,
    RuntimeInitialMapPreloadResult? preloadedInitialMap,
  )
  onLaunch;
  final void Function(PlayerPreferencesSnapshot)? onPreferencesChanged;

  @override
  void applyPlayerPreferences(PlayerPreferencesSnapshot preferences) {
    onPreferencesChanged?.call(preferences);
  }
  final Future<void> Function() _onPause;
  final Future<void> Function() _onResume;
  final Future<GameSessionCheckpoint?> Function() _onCaptureCheckpoint;
  final Future<RuntimePlayerPauseCommandResult> Function(
    RuntimePlayerPauseCommand command,
  )?
  _onPauseCommand;
  final Future<void> Function(GameSessionExitReason reason) _onStop;
  final Future<void> Function() _onDispose;
  final bool Function(RuntimeInputEvent event) _onInput;

  @override
  Future<void> launch(
    GameSessionDescriptor descriptor,
    GameSessionProgressReporter reportProgress,
    RuntimeInitialMapPreloadResult? preloadedInitialMap,
  ) => onLaunch(descriptor, reportProgress, preloadedInitialMap);

  @override
  Future<void> pause() => _onPause();

  @override
  Future<void> resume() => _onResume();

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() => _onCaptureCheckpoint();

  @override
  Future<RuntimePlayerPauseCommandResult> dispatchPauseCommand(
    RuntimePlayerPauseCommand command,
  ) async =>
      await _onPauseCommand?.call(command) ??
      const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'Les actions de l’équipe sont indisponibles.',
      );

  @override
  Future<void> stop(GameSessionExitReason reason) => _onStop(reason);

  @override
  Future<void> dispose() => _onDispose();

  @override
  bool handleInput(RuntimeInputEvent event) => _onInput(event);
}

/// Standalone composition of the host-neutral FG-017 startup contracts.
///
/// The project supplies presentation data, while PokeMap owns the splash
/// brand. Save addressing remains the runtime's canonical single slot.
final class StandaloneRuntimeStartupHost {
  StandaloneRuntimeStartupHost({
    required String projectFilePath,
    required ProjectManifest manifest,
    required StandaloneRuntimeSessionPort sessionPort,
    PlayerPreferencesGateway? preferencesGateway,
    Future<File> Function()? preferencesFile,
    RuntimeAudioMixer? sharedAudioMixer,
    PlayerInventoryPreferencesGateway? inventoryPreferencesGateway,
    Future<void> Function()? onExternalExit,
    Future<void> Function()? stopIntroPlayback,
    RuntimeSplashJingleController? splashJingleController,
    RuntimeTitleMusicController? titleMusicController,
    RuntimeStartupClock clock = const SystemRuntimeStartupClock(),
    Duration? minimumSplashDuration,
    bool reducedMotion = false,
    this.presentationSession,
  }) : presentation = StandaloneRuntimeStartupAdapter(
         projectFilePath: projectFilePath,
         manifest: manifest,
       ),
       audioMixer = sharedAudioMixer ?? RuntimeAudioMixer() {
    identity = buildStandaloneRuntimeGameIdentity(
      projectFilePath: projectFilePath,
      projectFormat: manifest.version.name,
    );
    final saves = StandalonePlayerSaveGateway(
      projectFilePath: projectFilePath,
      identity: identity,
    );
    final preferences =
        preferencesGateway ??
        StandalonePlayerPreferencesGateway(
          audioMixer: audioMixer,
          preferencesFile: preferencesFile,
        );
    initialMapPreloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFilePath,
      loadSave: (_) => saves.readEnvelope(),
      manifestLoader: (_) async => manifest,
    );
    // BETA-CIN-082: given the shared player composition, the standalone host
    // runs the same interactive Presentation as the Hub — the New Game flow
    // drives cues, branches and the world hand-off identically.
    final session = presentationSession;
    final newGameFlow = newGameFlowPort = RuntimeProjectNewGameFlowPort(
      projectFilePath: () async => projectFilePath,
      initialMapPreloader: initialMapPreloader,
      preSessionRunnerFactory: session?.buildPreSessionRunner,
      cancelActivePreSession: session?.cancelActive,
    );
    final source = _StandaloneRuntimeGameSource(
      identity: identity,
      displayTitle: manifest.name,
      projectFilePath: projectFilePath,
      preferences: preferences,
      defaultVisiblePauseActions: <ProjectPauseActionId>{
        ProjectPauseActionId.resume,
        for (final action
            in manifest
                    .effectivePresentation
                    .effectivePause
                    ?.effectiveActions ??
                defaultProjectPauseActions)
          if (action.visible) action.id,
      },
    );
    final sessions = GameSessionController(
      startTimeout: const Duration(minutes: 5),
      adapterFactory: (_) => InProcessGameSessionAdapter(
        runtimeFactory: (descriptor) => _StandaloneInProcessSessionRuntime(
          descriptor: descriptor,
          manifest: manifest,
          sessionPort: sessionPort,
          projectFilePath: projectFilePath,
          initialSave: saves.readEnvelope,
          preloadedInitialMap: initialMapPreloader.resolveForSession,
        ),
      ),
      commitCheckpoint: saves.commit,
    );
    sessionController = sessions;
    playerCoordinator = RuntimePlayerCoordinator(
      gameSource: source,
      saveGateway: saves,
      preferencesGateway: preferences,
      inventoryPreferencesGateway: inventoryPreferencesGateway ??
          FilePlayerInventoryPreferencesGateway.lazy(
            directoryProvider: () async => Directory(p.join(
              (await getApplicationSupportDirectory()).path,
              'inventory_preferences',
            )),
          ),
      newGameFlow: newGameFlow,
      sessionController: sessions,
      externalExit: _CallbackRuntimeExternalExit(onExternalExit ?? _noOp),
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: standaloneRuntimeProfileId,
        slotId: standaloneRuntimeSlotId,
      ),
    );
    final titleMusic =
        titleMusicController ?? RuntimeTitleMusicController(mixer: audioMixer);
    final splashJingle =
        splashJingleController ??
        RuntimeSplashJingleController(mixer: audioMixer);
    coordinator = RuntimeStartupCoordinator(
      playerCoordinator: playerCoordinator,
      preparationPort: presentation,
      initialMapPreloadPort: initialMapPreloader,
      assetResolver: presentation,
      introController: RuntimeIntroSequenceController(),
      splashJingleController: splashJingle,
      titleMusicController: titleMusic,
      clock: clock,
      hostBranding: standaloneRuntimeSplashBranding,
      minimumSplashDuration: minimumSplashDuration,
      reducedMotion: reducedMotion,
      stopIntroPlayback: stopIntroPlayback,
    );
  }

  late final GameIdentity identity;
  final StandaloneRuntimeStartupAdapter presentation;
  final RuntimeAudioMixer audioMixer;

  /// The New Game flow this host drives — exposed so a host can assert that
  /// its Presentation stack is really wired (BETA-CIN-082).
  late final RuntimeProjectNewGameFlowPort newGameFlowPort;

  /// The shared interactive Presentation stack, when the project carries
  /// media for it. Null keeps a media-less project perfectly playable.
  final RuntimePresentationSessionRuntime? presentationSession;
  late final RuntimeInitialMapPreloader initialMapPreloader;
  late final GameSessionController sessionController;
  late final RuntimePlayerCoordinator playerCoordinator;
  late final RuntimeStartupCoordinator coordinator;

  RuntimeStartupSnapshot get snapshot => coordinator.snapshot;
  Stream<RuntimeStartupSnapshot> get snapshots => coordinator.snapshots;

  void start() => coordinator.start();

  Future<void> dispose() async {
    await presentationSession?.close();
    await coordinator.dispose();
  }
}

/// Resolves only project-relative presentation files below the selected
/// project root. Neither the startup snapshot nor title actions receive paths.
final class StandaloneRuntimeStartupAdapter
    implements RuntimeStartupPreparationPort, RuntimePresentationAssetResolver {
  StandaloneRuntimeStartupAdapter({
    required String projectFilePath,
    required this.manifest,
  }) : projectFilePath = p.normalize(p.absolute(projectFilePath)),
       _projectRoot = p.normalize(
         p.absolute(File(projectFilePath).parent.path),
       );

  final String projectFilePath;
  final ProjectManifest manifest;
  final String _projectRoot;
  final Map<String, RuntimeResolvedAsset> _resolved =
      <String, RuntimeResolvedAsset>{};
  late final PresentationMediaAliasStore _mediaAliases =
      PresentationMediaAliasStore(
        root: Directory(p.join(
          Directory.systemTemp.path,
          'pokemap-startup-media',
          sha256.convert(utf8.encode(_projectRoot)).toString(),
        )),
      );

  @override
  Future<void> prepareManifestAndIdentity() async {
    if (!await File(projectFilePath).exists()) {
      throw StateError('The selected project manifest is unavailable.');
    }
  }

  @override
  Future<ProjectPresentationProfile?> loadPresentationProfile() async =>
      manifest.presentation;

  @override
  Future<RuntimeResolvedAsset?> resolveImage(String projectRelativePath) =>
      _resolve(projectRelativePath, fallbackMediaType: 'image/*');

  @override
  Future<RuntimeResolvedAsset?> resolveMedia(String projectRelativePath) =>
      _resolve(
        projectRelativePath,
        fallbackMediaType: 'application/octet-stream',
      );

  @override
  Future<bool> exists(String projectRelativePath) async =>
      await _resolve(projectRelativePath) != null;

  RuntimeResolvedAsset? resolvedAsset(String assetId) => _resolved[assetId];

  Future<String> loadText(String assetId) async {
    final asset = await _resolve(assetId, fallbackMediaType: 'text/plain');
    if (asset == null || asset.resolvedUri.scheme != 'file') {
      throw StateError('The requested presentation text is unavailable.');
    }
    return File.fromUri(asset.resolvedUri).readAsString();
  }

  Future<RuntimeResolvedAsset?> _resolve(
    String assetId, {
    String fallbackMediaType = 'application/octet-stream',
  }) async {
    final cached = _resolved[assetId];
    if (cached != null) return cached;
    final trimmed = assetId.trim();
    if (trimmed.isEmpty ||
        p.isAbsolute(trimmed) ||
        trimmed.contains('\u0000')) {
      return null;
    }
    final candidate = p.normalize(p.join(_projectRoot, trimmed));
    if (!p.isWithin(_projectRoot, candidate)) return null;
    final file = resolveProjectDirectoryAssetFile(
      projectRootDirectory: _projectRoot,
      relativePath: trimmed,
    );
    if (file == null) return null;
    try {
      final realRoot = p.normalize(
        await Directory(_projectRoot).resolveSymbolicLinks(),
      );
      final realFile = p.normalize(await file.resolveSymbolicLinks());
      if (!p.isWithin(realRoot, realFile)) return null;
      final mediaType = _mediaTypeFor(assetId) ?? fallbackMediaType;
      final source = File(realFile).uri;
      final resolved = RuntimeResolvedAsset(
        assetId: assetId,
        resolvedUri: mediaType.startsWith('video/') ||
                mediaType.startsWith('audio/')
            ? await _mediaAliases.resolveContainer(
                p.extension(assetId).substring(1),
                source,
              )
            : source,
        mediaType: mediaType,
      );
      _resolved[assetId] = resolved;
      return resolved;
    } on FileSystemException {
      return null;
    }
  }
}

/// Single-save gateway for a selected developer project. The public player
/// sees only `default/main`; the adjacent legacy JSON remains a host detail.
final class StandalonePlayerSaveGateway implements PlayerSaveGateway {
  StandalonePlayerSaveGateway({
    required this.projectFilePath,
    required this.identity,
  });

  final String projectFilePath;

  @override
  final GameIdentity identity;

  File get _saveFile => File.fromUri(
    File(projectFilePath).parent.uri.resolve(kRuntimeHostLaunchSaveFileName),
  );

  SaveSlotAddress get _address => SaveSlotAddress(
    gameId: identity.gameId,
    profileId: standaloneRuntimeProfileId,
    slotId: standaloneRuntimeSlotId,
  );

  @override
  Future<PlayerSaveSummary?> readLatestSummary() => readSummary(_address);

  @override
  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address) async {
    if (address != _address) return null;
    final envelope = await readEnvelope();
    if (envelope == null) return null;
    return PlayerSaveSummary(
      address: address,
      updatedAt: envelope.updatedAt,
      playTimeSeconds: envelope.playTimeSeconds,
      status: envelope.status,
      canContinue: true,
    );
  }

  @override
  Future<void> deleteSave(SaveSlotAddress address) async {}

  @override
  Future<String?> openReadHandle(SaveSlotAddress address) async {
    if (address != _address || await readEnvelope() == null) return null;
    return 'standalone-save-v1';
  }

  Future<SaveEnvelope?> readEnvelope() async {
    final saveData = await loadRuntimeHostLaunchSaveData(
      projectFilePath: projectFilePath,
    );
    if (saveData == null) return null;
    final stat = await _saveFile.stat();
    final timestamp = stat.modified.toUtc();
    final saveId = _standaloneSaveUuid(saveData.saveId);
    return const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: standaloneRuntimeProfileId,
      slotId: standaloneRuntimeSlotId,
      saveId: saveId,
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: saveData.trainerProfile.playtimeSeconds,
      gameState: gameStateFromSaveData(saveData).copyWith(saveId: saveId),
    );
  }

  @override
  Future<void> commit(GameSessionCheckpointCommit request) async {
    if (request.descriptor.identity != identity ||
        request.descriptor.profileId != standaloneRuntimeProfileId ||
        request.descriptor.slotId != standaloneRuntimeSlotId) {
      throw StateError('The checkpoint belongs to another standalone game.');
    }
    final state = gameStateFromStrictSaveJson(
      Map<String, dynamic>.from(request.checkpoint.state),
    ).copyWith(saveId: request.checkpoint.saveId);
    final saveData = saveDataFromGameState(
      state.copyWith(
        trainerProfile: state.trainerProfile.copyWith(
          playtimeSeconds: request.checkpoint.playTimeSeconds,
        ),
      ),
    );
    await writeRuntimeJsonAtomically(
      destination: _saveFile,
      json: saveData.toJson(),
      validate: SaveData.fromJson,
    );
  }
}

final class StandalonePlayerPreferencesGateway
    implements PlayerPreferencesGateway {
  StandalonePlayerPreferencesGateway({
    required RuntimeAudioMixer audioMixer,
    Future<File> Function()? preferencesFile,
    PlayerPreferencesSnapshot initial = const PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    ),
  }) : _audioMixer = audioMixer,
       _preferencesFile = preferencesFile,
       defaultPreferences = initial,
       _snapshot = initial;

  final RuntimeAudioMixer _audioMixer;
  final Future<File> Function()? _preferencesFile;
  @override
  final PlayerPreferencesSnapshot defaultPreferences;
  PlayerPreferencesSnapshot _snapshot;

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    final file = await _preferencesFile?.call();
    if (file != null && await file.exists()) {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _snapshot = PlayerPreferences.fromJson(json).toRuntimeSnapshot(
        fallbackLocale: _snapshot.locale,
      );
    }
    await _audioMixer.transitionTo(_snapshot.audioMix);
    return _snapshot;
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final confirmed = _snapshot;
    final file = await _preferencesFile?.call();
    try {
      await _audioMixer.transitionTo(preferences.audioMix);
      if (file != null) {
        await file.parent.create(recursive: true);
        await writeRuntimeJsonAtomically(
          destination: file,
          json: const PlayerPreferences().copyWithRuntimeSnapshot(preferences).toJson(),
          validate: PlayerPreferences.fromJson,
        );
      }
      _snapshot = preferences;
    } on Object {
      await _audioMixer.transitionTo(confirmed.audioMix);
      rethrow;
    }
  }
}

GameIdentity buildStandaloneRuntimeGameIdentity({
  required String projectFilePath,
  required String projectFormat,
}) {
  final canonicalPath = p.normalize(p.absolute(projectFilePath));
  final digest = sha256.convert(utf8.encode(canonicalPath)).toString();
  return GameIdentity(
    gameId: 'local.pokemap.g${digest.substring(0, 24)}',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.parse(projectFormat),
    saveFormat: 1,
    compatibilityId: 'standalone-$projectFormat',
  );
}

final class _StandaloneRuntimeGameSource implements RuntimeGameSource {
  _StandaloneRuntimeGameSource({
    required this.identity,
    required this.displayTitle,
    required this.projectFilePath,
    required this.preferences,
    required Set<ProjectPauseActionId> defaultVisiblePauseActions,
  }) : _projectDigest = sha256
           .convert(utf8.encode(p.normalize(p.absolute(projectFilePath))))
           .toString(),
       defaultVisiblePauseActions = Set<ProjectPauseActionId>.unmodifiable(
         defaultVisiblePauseActions,
       );

  @override
  final GameIdentity identity;

  @override
  final String displayTitle;

  final String projectFilePath;
  final PlayerPreferencesGateway preferences;
  @override
  final Set<ProjectPauseActionId> defaultVisiblePauseActions;
  final String _projectDigest;
  int _sessionSerial = 0;

  @override
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
    GameState? initialGameState,
  }) async {
    final playerPreferences = await preferences.load();
    final serial = ++_sessionSerial;
    return GameSessionDescriptor(
      sessionId: 'standalone-session-$serial',
      sessionToken: 'standalone-session-token-$serial',
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle:
          'standalone-project-${_projectDigest.substring(0, 24)}',
      saveReadHandle: saveReadHandle,
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{
        'battle.v1',
        'party.v1',
        'bag.v1',
        'pokedex.v1',
        'map.v1',
      },
      locale: playerPreferences.locale,
      accessibility: playerPreferences.accessibility,
      initialGameState: initialGameState,
    );
  }
}

final class _StandaloneInProcessSessionRuntime
    implements
        InProcessGameSessionRuntime,
        RuntimePlayerPreferencesPort,
        RuntimePlayerPauseDataPort,
        RuntimePlayerPauseCommandPort {
  _StandaloneInProcessSessionRuntime({
    required this.descriptor,
    required this.manifest,
    required this.sessionPort,
    required this.projectFilePath,
    required this.initialSave,
    required this.preloadedInitialMap,
  });

  @override
  void applyPlayerPreferences(PlayerPreferencesSnapshot preferences) {
    if (!_disposed) {
      _playerPreferences = preferences;
      if (sessionPort case final RuntimePlayerPreferencesPort port) {
        port.applyPlayerPreferences(preferences);
      }
    }
  }

  final GameSessionDescriptor descriptor;
  PlayerPreferencesSnapshot? _playerPreferences;
  final ProjectManifest manifest;
  late final _portraitResolver = DialoguePortraitResolver(
    manifest: manifest,
    projectRootDirectory: File(projectFilePath).parent.path,
  );
  final StandaloneRuntimeSessionPort sessionPort;
  final String projectFilePath;
  final Future<SaveEnvelope?> Function() initialSave;
  final SessionPreloadedInitialMapLoader preloadedInitialMap;
  final StreamController<GameSessionAdapterEvent> _events =
      StreamController<GameSessionAdapterEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async {
    final save = descriptor.launchMode == GameSessionLaunchMode.newGame
        ? null
        : await initialSave();
    final bundle = await preloadedInitialMap(
      projectFilePath: projectFilePath,
      descriptor: descriptor,
      initialSave: save,
    );
    await sessionPort.launch(descriptor, reportProgress, bundle);
  }

  @override
  Future<void> pause() => sessionPort.pause();

  @override
  Future<void> resume() => sessionPort.resume();

  @override
  Future<RuntimePlayerPauseCommandResult> dispatchPauseCommand(
    RuntimePlayerPauseCommand command,
  ) async {
    if (_disposed) {
      return const RuntimePlayerPauseCommandResult(
        status: RuntimePlayerPauseCommandStatus.unavailable,
        safeMessage: 'La session de jeu est terminée.',
      );
    }
    return sessionPort.dispatchPauseCommand(command);
  }

  @override
  Future<PlayerPauseMenuState> loadPauseMenuState() async {
    final checkpoint = await sessionPort.captureCheckpoint();
    if (_disposed || checkpoint == null) {
      return const PlayerPauseMenuState.empty();
    }
    return gameStateFromStrictSaveJson(
      Map<String, dynamic>.from(checkpoint.state),
    ).pauseMenuState;
  }

  @override
  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
  loadPauseDetails() async {
    final checkpoint = await captureCheckpoint();
    if (_disposed || checkpoint == null) return const {};
    await _portraitResolver.ensureCatalogLoaded();
    final state = gameStateFromStrictSaveJson(
      Map<String, dynamic>.from(checkpoint.state),
    );
    return const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: File(projectFilePath).parent.path,
      pokemonConfig: manifest.pokemon,
      locale: descriptor.locale,
      uiLocale: _playerPreferences?.locale,
      mapEnabled: true,
      projectMaps: manifest.maps,
      regionalMap: manifest.regionalMap,
      projectBadges: manifest.badges,
      projectCharacters: manifest.characters,
      portraitLookup: _portraitResolver.resolve,
      playtimeSeconds: checkpoint.playTimeSeconds,
    );
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    final checkpoint = await sessionPort.captureCheckpoint();
    if (checkpoint == null || _disposed) return null;
    final state = gameStateFromStrictSaveJson(
      Map<String, dynamic>.from(checkpoint.state),
    );
    return GameSessionCheckpoint(
      saveId: checkpoint.saveId,
      createdAt: checkpoint.createdAt,
      updatedAt: checkpoint.updatedAt,
      playTimeSeconds:
          state.trainerProfile.playtimeSeconds + checkpoint.playTimeSeconds,
      state: checkpoint.state,
    );
  }

  @override
  Future<void> lockGameplayForCompletion() => sessionPort.pause();

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {}

  @override
  Future<void> stop(GameSessionExitReason reason) => sessionPort.stop(reason);

  @override
  bool handleInput(RuntimeInputEvent event) => sessionPort.handleInput(event);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await sessionPort.dispose();
    await _events.close();
  }
}

final class _CallbackRuntimeExternalExit implements RuntimeExternalExit {
  const _CallbackRuntimeExternalExit(this._callback);

  final Future<void> Function() _callback;

  @override
  Future<void> returnToHost() => _callback();
}

Future<void> _noOp() async {}

Future<void> _noOpStop(GameSessionExitReason reason) async {}

Future<GameSessionCheckpoint?> _noCheckpoint() async => null;

bool _ignoreInput(RuntimeInputEvent event) => false;

String _standaloneSaveUuid(String legacySaveId) {
  final source = legacySaveId.trim().isEmpty
      ? 'standalone-save'
      : legacySaveId.trim();
  final hex = sha256.convert(utf8.encode(source)).toString();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '5${hex.substring(13, 16)}-'
      'a${hex.substring(17, 20)}-'
      '${hex.substring(20, 32)}';
}

String? _mediaTypeFor(String path) => switch (p.extension(path).toLowerCase()) {
  '.png' => 'image/png',
  '.jpg' || '.jpeg' => 'image/jpeg',
  '.webp' => 'image/webp',
  '.mp4' => 'video/mp4',
  '.m4a' => 'audio/mp4',
  '.mp3' => 'audio/mpeg',
  '.ogg' => 'audio/ogg',
  '.wav' => 'audio/wav',
  '.flac' => 'audio/flac',
  '.aac' => 'audio/aac',
  '.vtt' => 'text/vtt',
  _ => null,
};
