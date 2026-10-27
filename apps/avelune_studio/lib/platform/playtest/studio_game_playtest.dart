import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../features/rendering/application/studio_rendering_preferences.dart';

const studioGameBranding = RuntimeHostSplashBranding(
  displayName: 'AVELUNE',
  signature: 'CRÉEZ · JOUEZ · PARTAGEZ',
);

final class StudioGamePlaytest {
  StudioGamePlaytest._(
    this.project,
    this.assets,
    this.presentation,
    this.audioMixer,
    this.saves,
    this.newGameFlow,
    this.sessions,
    this.player,
    this.startup,
  ) : _preferencesSubscription = player.snapshots.listen((snapshot) {
        presentation.controller.setReducedMotion(
          snapshot.preferences?.accessibility.reducedMotion ?? false,
        );
      });

  final StreamSubscription<RuntimePlayerSnapshot> _preferencesSubscription;
  final ProjectManifest project;
  final StudioGameAssets assets;
  final RuntimePresentationSessionRuntime presentation;
  final RuntimeAudioMixer audioMixer;
  final StudioGameSaves saves;
  final RuntimeProjectNewGameFlowPort newGameFlow;
  final GameSessionController sessions;
  final RuntimePlayerCoordinator player;
  final RuntimeStartupCoordinator startup;

  static Future<StudioGamePlaytest> prepare({
    required String projectFilePath,
    required Future<void> Function() onExit,
    required PlayableMapGameMount mountGame,
    required PlayableMapGameUnmount unmountGame,
    required SpatialExplorationSessionMount mountSpatial,
    required SpatialExplorationSessionMount unmountSpatial,
    Future<void> Function()? stopIntroPlayback,
    RuntimePresentationFrameDeltas? presentationFrameDeltas,
    StudioRenderingPreferences? renderingPreferences,
  }) async {
    await renderingPreferences?.load();
    final project = await loadProjectManifestFromFile(projectFilePath);
    final assets = StudioGameAssets(projectFilePath, project);
    final media = await loadProjectDirectoryPresentationMedia(
      projectRootDirectory: File(projectFilePath).parent.path,
    );
    final audio = RuntimeAudioMixer();
    final presentation = RuntimePresentationSessionRuntime(
      runtimeSourceId: 'studio-game',
      catalog: media?.catalog ?? ProjectMediaCatalog(),
      mediaUris: media?.mediaUris ?? const {},
      targetPlatform: currentPresentationMediaTargetPlatform(),
      audioMixer: audio,
      reducedMotion: false,
      frameDeltas: presentationFrameDeltas,
    );
    final preferences = _StudioGamePreferences(audio, renderingPreferences);
    final source = _StudioGameSource(project, preferences);
    final saves = StudioGameSaves(source.identity);
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFilePath,
      loadSave: (_) async => saves.envelope,
    );
    final flow = RuntimeProjectNewGameFlowPort(
      projectFilePath: () async => projectFilePath,
      initialMapPreloader: preloader,
      preSessionRunnerFactory: presentation.buildPreSessionRunner,
      cancelActivePreSession: presentation.cancelActive,
    );
    final sessions = GameSessionController(
      adapterFactory: (_) => InProcessGameSessionAdapter(
        runtimeFactory: (descriptor) {
          Future<SaveEnvelope?> initialSave() async =>
              descriptor.launchMode == GameSessionLaunchMode.newGame
              ? null
              : saves.envelope;
          if (project.settings.dimension == ProjectDimension.threeD) {
            return SpatialExplorationGameSessionRuntime(
              descriptor: descriptor,
              projectFilePath: () async => projectFilePath,
              initialSave: initialSave,
              preloadedInitialMap: preloader.resolveForSession,
              commitCheckpoint: saves.commit,
              mountSession: mountSpatial,
              audioMixer: audio,
              unmountSession: unmountSpatial,
            );
          }
          return PlayableMapGameSessionRuntime(
            descriptor: descriptor,
            projectFilePath: () async => projectFilePath,
            initialSave: initialSave,
            preloadedInitialMap: preloader.resolveForSession,
            commitCheckpoint: saves.commit,
            mountGame: mountGame,
            unmountGame: unmountGame,
            audioMixer: audio,
            presentationCinematicPlayer: presentation.controller,
          );
        },
      ),
      commitCheckpoint: saves.commit,
    );
    final player = RuntimePlayerCoordinator(
      gameSource: source,
      saveGateway: saves,
      preferencesGateway: preferences,
      newGameFlow: flow,
      sessionController: sessions,
      externalExit: _StudioGameExit(onExit),
      defaultSaveSlot: const RuntimePlayerLoadSlot(
        profileId: 'studio',
        slotId: 'test',
      ),
    );
    final startup = RuntimeStartupCoordinator(
      playerCoordinator: player,
      preparationPort: assets,
      initialMapPreloadPort: preloader,
      assetResolver: assets,
      introController: RuntimeIntroSequenceController(),
      splashJingleController: RuntimeSplashJingleController(mixer: audio),
      titleMusicController: RuntimeTitleMusicController(mixer: audio),
      hostBranding: studioGameBranding,
      stopIntroPlayback: stopIntroPlayback,
    );
    return StudioGamePlaytest._(
      project,
      assets,
      presentation,
      audio,
      saves,
      flow,
      sessions,
      player,
      startup,
    );
  }

  Future<void> dispose() async {
    await _preferencesSubscription.cancel();
    await startup.dispose();
    await presentation.close();
  }
}

final class StudioGameAssets
    implements RuntimeStartupPreparationPort, RuntimePresentationAssetResolver {
  StudioGameAssets(this.projectFilePath, this.project);
  final String projectFilePath;
  final ProjectManifest project;
  final _resolved = <String, RuntimeResolvedAsset>{};
  final _aliases = PresentationMediaAliasStore(
    root: Directory(
      p.join(Directory.systemTemp.path, 'avelune-studio-game-media'),
    ),
  );
  RuntimeResolvedAsset? resolvedAsset(String id) => _resolved[id];
  @override
  Future<void> prepareManifestAndIdentity() async {
    if (!await File(projectFilePath).exists()) {
      throw StateError('Le projet est indisponible.');
    }
  }

  @override
  Future<ProjectPresentationProfile?> loadPresentationProfile() async =>
      project.presentation;
  @override
  Future<bool> exists(String path) async => await resolveMedia(path) != null;
  @override
  Future<RuntimeResolvedAsset?> resolveImage(String path) => resolveMedia(path);
  @override
  Future<RuntimeResolvedAsset?> resolveMedia(String path) async {
    if (_resolved[path] case final cached?) return cached;
    final file = resolveProjectDirectoryAssetFile(
      projectRootDirectory: File(projectFilePath).parent.path,
      relativePath: path,
    );
    if (file == null) return null;
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    final type = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'mp4' || 'm4v' => 'video/mp4',
      'mov' => 'video/quicktime',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      'm4a' => 'audio/mp4',
      _ => 'application/octet-stream',
    };
    return _resolved[path] = RuntimeResolvedAsset(
      assetId: path,
      resolvedUri: type.startsWith('video/') || type.startsWith('audio/')
          ? await _aliases.resolveContainer(extension, file.uri)
          : file.uri,
      mediaType: type,
    );
  }

  Future<String> loadText(String path) async {
    final asset = await resolveMedia(path);
    if (asset == null) throw StateError('Le texte est indisponible.');
    return File.fromUri(asset.resolvedUri).readAsString();
  }
}

final class StudioGameSaves implements PlayerSaveGateway {
  StudioGameSaves(this.identity);
  @override
  final GameIdentity identity;
  SaveEnvelope? envelope;
  int _revision = 0;
  SaveSlotAddress get address => SaveSlotAddress(
    gameId: identity.gameId,
    profileId: 'studio',
    slotId: 'test',
  );
  @override
  Future<PlayerSaveSummary?> readLatestSummary() => readSummary(address);
  @override
  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address) async {
    final saved = envelope;
    if (address != this.address || saved == null) return null;
    return PlayerSaveSummary(
      address: address,
      updatedAt: saved.updatedAt,
      playTimeSeconds: saved.playTimeSeconds,
      status: saved.status,
      canContinue: saved.status == SaveStatus.active,
    );
  }

  @override
  Future<String?> openReadHandle(SaveSlotAddress address) async =>
      address == this.address && envelope != null
      ? 'studio-save-$_revision'
      : null;
  @override
  Future<void> deleteSave(SaveSlotAddress address) async {
    if (address == this.address) {
      envelope = null;
      _revision++;
    }
  }

  @override
  Future<void> commit(GameSessionCheckpointCommit request) async {
    final descriptor = request.descriptor;
    if (descriptor.identity != identity ||
        descriptor.profileId != 'studio' ||
        descriptor.slotId != 'test') {
      throw StateError('Sauvegarde de test étrangère.');
    }
    final checkpoint = request.checkpoint;
    envelope = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'studio',
      slotId: 'test',
      saveId: checkpoint.saveId,
      createdAt: checkpoint.createdAt,
      updatedAt: checkpoint.updatedAt,
      status: request.status,
      completedAt: request.completedAt,
      playTimeSeconds: checkpoint.playTimeSeconds,
      gameState: gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state),
      ),
    );
    _revision++;
  }
}

final class _StudioGamePreferences implements PlayerPreferencesGateway {
  _StudioGamePreferences(this.audio, this.renderingPreferences);
  final RuntimeAudioMixer audio;
  final StudioRenderingPreferences? renderingPreferences;
  @override
  final defaultPreferences = const PlayerPreferencesSnapshot(
    locale: 'fr',
    accessibility: GameSessionAccessibilityOptions(),
  );
  PlayerPreferencesSnapshot? _value;
  @override
  Future<PlayerPreferencesSnapshot> load() async {
    await renderingPreferences?.load();
    return (_value ?? defaultPreferences).copyWith(
      targetFramesPerSecond: AveluneFrameRate.limit,
    );
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final previous = _value ?? defaultPreferences;
    final changesAudio =
        preferences.audioMix.masterVolume != previous.audioMix.masterVolume ||
        preferences.audioMix.musicVolume != previous.audioMix.musicVolume ||
        preferences.audioMix.effectsVolume != previous.audioMix.effectsVolume;
    final changesFrameRate =
        preferences.targetFramesPerSecond != AveluneFrameRate.limit;
    var newerFrameRateChoice = false;
    void observeFrameRate() => newerFrameRateChoice = true;
    AveluneFrameRate.changes.addListener(observeFrameRate);
    try {
      if (changesAudio) await audio.transitionTo(preferences.audioMix);
      if (changesFrameRate && !newerFrameRateChoice) {
        final rendering = renderingPreferences;
        if (rendering == null) {
          AveluneFrameRate.setLimit(preferences.targetFramesPerSecond);
        } else {
          await rendering.setLimit(preferences.targetFramesPerSecond);
        }
      }
      _value = preferences.copyWith(
        targetFramesPerSecond: AveluneFrameRate.limit,
      );
    } catch (_) {
      if (changesAudio) await audio.transitionTo(previous.audioMix);
      rethrow;
    } finally {
      AveluneFrameRate.changes.removeListener(observeFrameRate);
    }
  }
}

final class _StudioGameExit implements RuntimeExternalExit {
  _StudioGameExit(this.callback);
  final Future<void> Function() callback;
  @override
  Future<void> returnToHost() => callback();
}

final class _StudioGameSource implements RuntimeGameSource {
  _StudioGameSource(this.project, this.preferences);
  final PlayerPreferencesGateway preferences;
  final ProjectManifest project;
  int _serial = 0;
  @override
  late final identity = GameIdentity(
    gameId: 'games.avelune.studio-project-test',
    gameVersion: '0.0.0',
    projectFormat: ProjectFormat.parse(project.version.name),
    saveFormat: SaveEnvelopeCodec.currentSaveFormat,
    compatibilityId: 'studio-project',
  );
  @override
  String get displayTitle => project.name;
  @override
  Set<ProjectPauseActionId> get defaultVisiblePauseActions => {
    for (final action
        in project.effectivePresentation.effectivePause?.effectiveActions ??
            defaultProjectPauseActions)
      if (action.visible) action.id,
  };
  @override
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
    GameState? initialGameState,
  }) async {
    final serial = ++_serial;
    final preference = await preferences.load();
    return GameSessionDescriptor(
      sessionId: 'studio-game-$serial',
      sessionToken: 'studio-game-token-$serial',
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle: 'studio-project',
      saveReadHandle: saveReadHandle,
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: {
        GameCompletionPartyCapabilities.capabilityId,
        'battle.v1',
        'party.v1',
        'bag.v1',
        'pokedex.v1',
        'map.v1',
        if (project.settings.dimension == ProjectDimension.threeD) ...{
          'map3d@1',
          SpatialGameplayCapabilities.capabilityId,
          SpatialGameplayCapabilities.storyCapabilityId,
          SpatialGameplayCapabilities.trainerSpottingCapabilityId,
          SpatialGameplayCapabilities.companionCapabilityId,
          SpatialCameraProfile.orthographicCapabilityId,
          SpatialVisualDocument.capabilityId,
          ProjectContactDeviceConfig.capabilityId,
          SpatialGameplayCapabilities.audioCapabilityId,
          SpatialGameplayCapabilities.sceneMusicCapabilityId,
          SpatialGameplayCapabilities.npcTradeCapabilityId,
          SpatialGameplayCapabilities.cinematicFadeCapabilityId,
          SpatialGameplayCapabilities.cinematicConnectedCapabilityId,
          'map3d.animation@1',
          SpatialModelShadowCapabilities.capabilityId,
          SpatialActorContactShadowCapabilities.capabilityId,
          SpatialActorOcclusionCapabilities.capabilityId,
          SpatialSceneLightingCapabilities.dayNightCapabilityId,
          SpatialSceneLightingCapabilities.pointLightCapabilityId,
          SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId,
          SpatialModelClipCapabilities.capabilityId,
          'map3d.terrain-appearance@1',
          SpatialTerrainSurfaceSet.capabilityId,
          SpatialRamp.fractionalLevelsCapabilityId,
        },
      },
      locale: preference.locale,
      accessibility: preference.accessibility,
      initialGameState: initialGameState,
    );
  }
}
