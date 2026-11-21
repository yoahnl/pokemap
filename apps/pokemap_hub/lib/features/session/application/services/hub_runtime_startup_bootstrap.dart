import 'package:pokemap_hub/features/session/data/repositories/hub_prepared_narrative_index.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/saves/application/services/hub_save_profile_manager.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/application/services/hub_game_options_availability.dart';
import 'package:pokemap_hub/features/session/application/services/hub_in_process_session_factory.dart';
import 'package:pokemap_hub/features/session/application/services/hub_installed_presentation_runtime.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_game_source.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/features/session/application/services/player_launch_failure.dart';
import 'package:pokemap_hub/features/session/domain/entities/hub_runtime_external_exit.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';

final class HubRuntimeStartupPreparedData {
  const HubRuntimeStartupPreparedData({
    required this.sessions,
    required this.coordinator,
    required this.startupAdapter,
    required this.playerLocale,
    required this.audioMixer,
    required this.controlProfileStore,
    required this.controlProfile,
    required this.reducedMotion,
    this.presentationRuntime,
  });

  final GameSessionController sessions;
  final RuntimePlayerCoordinator coordinator;
  final HubRuntimeStartupAdapter startupAdapter;
  final String playerLocale;
  final RuntimeAudioMixer audioMixer;
  final ControlProfileRepositoryInterface controlProfileStore;
  final player_ui.PlayerControlProfile controlProfile;
  final bool reducedMotion;
  final HubInstalledPresentationRuntime? presentationRuntime;
}

final class HubRuntimeStartupLifetime {
  bool _closed = false;
  final _closedSignal = Completer<void>();
  final _pending = <Future<void>>{};
  final _cleanup = <Future<void> Function()>[];

  void ensureActive() {
    if (_closed) throw const _HubRuntimeStartupCancelled();
  }

  void own(Future<void> Function() cleanup) => _cleanup.add(cleanup);

  Future<void> waitForGate(Future<void> gate) async {
    await Future.any([gate, _closedSignal.future]);
    ensureActive();
  }

  Future<T> run<T>(Future<T> Function() work) async {
    ensureActive();
    final complete = Completer<void>();
    _pending.add(complete.future);
    try {
      return await work();
    } finally {
      complete.complete();
      _pending.remove(complete.future);
    }
  }

  Future<void> close() async {
    _closed = true;
    if (!_closedSignal.isCompleted) _closedSignal.complete();
    await Future.wait(_pending.toList());
    for (final cleanup in _cleanup) {
      await cleanup();
    }
    _cleanup.clear();
  }
}

final class _HubRuntimeStartupCancelled implements Exception {
  const _HubRuntimeStartupCancelled();
}

final class HubRuntimeStartupBootstrap
    implements RuntimeStartupBootstrapPort<HubRuntimeStartupPreparedData> {
  const HubRuntimeStartupBootstrap({
    required this.supportRoot,
    required this.saveRepositoryFactory,
    required this.preferencesRepository,
    required this.controlProfileRepository,
    required this.launchResolver,
    required this.game,
    required this.onHubRequested,
    required this.mountGame,
    required this.unmountGame,
    required this.stopIntroPlayback,
    required this.defaultProfileDisplayNameForLocale,
    this.diagnosticLogFile,
    this.presentationFrameDeltas,
    this.presentationBeforeTerminal,
    this.preferencesRead,
    this.startupWorkGate,
    this.audioMixer,
    this.splashJingle,
    this.lifetime,
    this.mountSpatialSession,
    this.unmountSpatialSession,
  });

  final Directory supportRoot;
  final SaveRepositoryFactory saveRepositoryFactory;
  final PlayerPreferencesRepositoryInterface preferencesRepository;
  final ControlProfileRepositoryInterface controlProfileRepository;
  final SessionLaunchRepositoryInterface launchResolver;
  final InstalledGame game;
  final Future<void> Function() onHubRequested;
  final Future<void> Function(PlayableMapGame game) mountGame;
  final Future<void> Function(PlayableMapGame game) unmountGame;
  final Future<void> Function() stopIntroPlayback;
  final String Function(String locale) defaultProfileDisplayNameForLocale;
  final File? diagnosticLogFile;
  final RuntimePresentationFrameDeltas? presentationFrameDeltas;
  final RuntimePresentationBeforeTerminal? presentationBeforeTerminal;
  final Future<HubPreferencesRead>? preferencesRead;
  final Future<void>? startupWorkGate;
  final RuntimeAudioMixer? audioMixer;
  final RuntimeSplashJingleController? splashJingle;
  final HubRuntimeStartupLifetime? lifetime;
  final SpatialExplorationSessionMount? mountSpatialSession,
      unmountSpatialSession;

  @override
  Future<RuntimeStartupBootstrapResult<HubRuntimeStartupPreparedData>> prepare({
    required RuntimeStartupBootstrapStageSink onStageCompleted,
  }) =>
      lifetime?.run(() => _prepare(onStageCompleted)) ??
      _prepare(onStageCompleted);

  Future<RuntimeStartupBootstrapResult<HubRuntimeStartupPreparedData>> _prepare(
    RuntimeStartupBootstrapStageSink onStageCompleted,
  ) async {
    HubInstalledPresentationRuntime? presentationRuntime;
    RuntimeProjectCatalog? preparedCatalog;
    RuntimeInitialMapPreloader? ownedPreloader;
    try {
      final launching = Future.sync(() => launchResolver.resolve(game))
        ..ignore();
      final workGate = startupWorkGate;
      if (workGate != null) {
        await (lifetime?.waitForGate(workGate) ?? workGate);
      }
      lifetime?.ensureActive();
      final launch = await launching;
      lifetime?.ensureActive();
      onStageCompleted(RuntimeStartupBootstrapStage.projectResolution);

      final loadedPreferences =
          await (preferencesRead ?? preferencesRepository.load());
      lifetime?.ensureActive();
      final preferences = loadedPreferences.preferences;
      onStageCompleted(RuntimeStartupBootstrapStage.playerPreferences);

      final controlProfile = await controlProfileRepository.load();
      lifetime?.ensureActive();
      onStageCompleted(RuntimeStartupBootstrapStage.controlProfile);

      final store = saveRepositoryFactory(supportRoot, launch.identity);
      final configuredAudioMixer =
          audioMixer ??
          RuntimeAudioMixer(
            mix: RuntimeAudioMix(
              masterVolume: preferences.masterVolume,
              musicVolume: preferences.musicVolume,
              effectsVolume: preferences.effectsVolume,
            ),
          );
      final preferencesGateway = HubPlayerPreferencesGateway(
        store: preferencesRepository,
        fallbackLocale: launch.manifest.locales.defaultLocale,
        audioMixer: configuredAudioMixer,
        systemLocales: () => PlatformDispatcher.instance.locales.map(
          (locale) => locale.toLanguageTag(),
        ),
      );
      final saveGateway = HubPlayerSaveGateway(store: store);
      final playerLocale = preferencesGateway.project(preferences).locale;
      final saveSelection = await HubSaveProfileManager(store: store)
          .ensureDefaultSelection(
            defaultProfileDisplayName: defaultProfileDisplayNameForLocale(
              playerLocale,
            ),
            defaultSlotDisplayName: 'Slot 1',
          );
      lifetime?.ensureActive();
      onStageCompleted(RuntimeStartupBootstrapStage.hostStorage);

      final startupAdapter = HubRuntimeStartupAdapter(
        manifest: launch.manifest,
        assets: launch.assets,
      );
      onStageCompleted(RuntimeStartupBootstrapStage.presentationBinding);

      final projectFile = await launch.assets.resolveReference(launch.project);
      lifetime?.ensureActive();
      final metadataCatalog = await RuntimeProjectCatalog.open(
        projectFile.path,
        expectedSourceSha256: launch.manifest.content.files
            .firstWhere((entry) => entry.path == launch.project.packagePath)
            .sha256,
      );
      preparedCatalog = metadataCatalog;
      final installedProject = metadataCatalog.projectMetadata;
      lifetime?.ensureActive();
      final spatial =
          installedProject.settings.dimension == ProjectDimension.threeD;
      if (spatial != launch.grantedCapabilities.contains('map3d@1')) {
        throw StateError(
          'The installed dimension does not match its runtime capability.',
        );
      }
      final locales = ProjectLocalePolicy(
        supportedLocales: launch.manifest.locales.supported,
        fallbackLocale: launch.manifest.locales.defaultLocale,
      );
      Future<String> readPreferredLocale() async =>
          (await preferencesGateway.read()).contentLocale(locales);

      if (installedProject.presentationCinematics.isNotEmpty) {
        final media = _referencesPresentationMedia(installedProject)
            ? await const HubInstalledPresentationMediaLoader().load(
                launch.assets,
              )
            : HubInstalledPresentationMedia(
                catalog: ProjectMediaCatalog(),
                mediaUris: const <String, Uri>{},
              );
        lifetime?.ensureActive();
        presentationRuntime = HubInstalledPresentationRuntime(
          runtimeSourceId: launch.identity.gameId,
          media: media,
          targetPlatform: currentPresentationMediaTargetPlatform(),
          audioMixer: configuredAudioMixer,
          reducedMotion: preferences.reducedMotion,
          frameDeltas: presentationFrameDeltas,
          beforeTerminal: presentationBeforeTerminal,
          readPreferredLocale: readPreferredLocale,
        );
        lifetime?.own(presentationRuntime.close);
      }

      final gameSource = HubRuntimeGameSource(
        launch: launch,
        preferencesGateway: preferencesGateway,
      );
      final resourceProfile = hubRuntimeResourceProfile(spatial: spatial);
      final preparedNarrativeIndex = HubPreparedNarrativeIndex(
        supportRoot: supportRoot,
      );
      final initialMapPreloader = RuntimeInitialMapPreloader(
        preparedProjectCatalog: metadataCatalog,
        preparedNarrativeCorpusLoader: (catalog) =>
            preparedNarrativeIndex.loadForStartup(
              catalog: catalog,
              versionRoot: projectFile.parent.parent,
              manifest: launch.manifest,
            ),
        cacheNarrativeCorpus: (corpus) => preparedNarrativeIndex.store(
          launch.manifest,
          corpus,
        ),
        expectedIdentity: launch.identity,
        projectFilePath: () async => projectFile.path,
        loadSave: saveGateway.readLaunchableEnvelope,
        resourceProfile: resourceProfile,
      );
      ownedPreloader = initialMapPreloader;
      preparedCatalog = null;
      lifetime?.own(() async => initialMapPreloader.clear());
      final RuntimeNewGameFlowPort newGameFlow = RuntimeProjectNewGameFlowPort(
        locales: locales,
        projectFilePath: () async => projectFile.path,
        initialMapPreloader: initialMapPreloader,
        preSessionRunnerFactory: presentationRuntime?.buildPreSessionRunner,
        cancelActivePreSession: presentationRuntime?.cancelActive,
        readPreferredLocale: readPreferredLocale,
      );
      final sessionFactory = HubInProcessSessionFactory(
        launch: launch,
        saves: store,
        mountGame: mountGame,
        unmountGame: unmountGame,
        dimension: installedProject.settings.dimension,
        mountSpatialSession: mountSpatialSession,
        unmountSpatialSession: unmountSpatialSession,
        preloadedInitialMap: initialMapPreloader.resolveForSession,
        resourceProfile: resourceProfile,
        commitCheckpoint: saveGateway.commit,
        audioMixer: configuredAudioMixer,
        presentationCinematicPlayer: presentationRuntime?.controller,
        feedbackLocalizer: player_ui.localizeRuntimePlayerFeedback,
        battleMessageFormatter: player_ui.localizeRuntimeBattleMessage,
      );
      final sessions = GameSessionController(
        adapterFactory: sessionFactory.call,
        commitCheckpoint: saveGateway.commit,
        playerLocale: playerLocale,
        feedbackLocalizer: player_ui.localizeRuntimePlayerFeedback,
      );
      final coordinator = RuntimePlayerCoordinator(
        gameSource: gameSource,
        feedbackLocalizer: player_ui.localizeRuntimePlayerFeedback,
        saveGateway: saveGateway,
        preferencesGateway: preferencesGateway,
        readPreferences: preferencesGateway.read,
        newGameFlow: newGameFlow,
        inventoryPreferencesGateway: FilePlayerInventoryPreferencesGateway(
          directory: Directory.fromUri(
            supportRoot.uri.resolve('inventory_preferences/'),
          ),
        ),
        sessionController: sessions,
        optionsAvailability: RuntimePlayerOptionsAvailability(
          graphics3d: spatial,
          weather: spatial,
        ),
        externalExit: HubRuntimeExternalExit(onHubRequested),
        defaultSaveSlot: RuntimePlayerLoadSlot(
          profileId: saveSelection.profileId,
          slotId: saveSelection.slotId,
        ),
      );
      final graph = RuntimeStartupPreparedGraph(
        playerCoordinator: coordinator,
        preparationPort: startupAdapter,
        initialMapPreloadPort: initialMapPreloader,
        assetResolver: startupAdapter,
        introController: RuntimeIntroSequenceController(),
        splashJingleController:
            splashJingle ??
            RuntimeSplashJingleController(mixer: configuredAudioMixer),
        titleMusicController: RuntimeTitleMusicController(
          mixer: configuredAudioMixer,
        ),
        presentationMetadata: RuntimeStartupPresentationMetadata(
          author: launch.manifest.author.name,
          description: launch.manifest.description,
        ),
        reducedMotion: preferences.reducedMotion,
        stopIntroPlayback: stopIntroPlayback,
      );
      unawaited(
        resolveHubGameOptionsAvailability(
          projectFilePath: projectFile.path,
          capabilities: launch.grantedCapabilities,
        ).then(coordinator.updateOptionsAvailability, onError: (Object _) {}),
      );
      onStageCompleted(RuntimeStartupBootstrapStage.runtimeGraph);
      return RuntimeStartupBootstrapResult<HubRuntimeStartupPreparedData>(
        graph: graph,
        value: HubRuntimeStartupPreparedData(
          sessions: sessions,
          coordinator: coordinator,
          startupAdapter: startupAdapter,
          playerLocale: playerLocale,
          audioMixer: configuredAudioMixer,
          controlProfileStore: controlProfileRepository,
          controlProfile: controlProfile,
          reducedMotion: preferences.reducedMotion,
          presentationRuntime: presentationRuntime,
        ),
      );
    } on Object catch (error, stackTrace) {
      preparedCatalog?.dispose();
      ownedPreloader?.clear();
      await presentationRuntime?.close();
      if (error is _HubRuntimeStartupCancelled) rethrow;
      final recorded = await recordPlayerLaunchFailure(
        game: game,
        supportRoot: supportRoot,
        diagnosticLogFile: diagnosticLogFile,
        error,
        stackTrace,
        event: 'playerLaunchFailed',
      );
      throw RuntimeStartupBootstrapException(
        RuntimeStartupFailure(
          code: 'hub.${recorded.code}',
          safeMessage: 'The installed game could not be prepared.',
        ),
      );
    }
  }
}

RuntimeResourceProfile hubRuntimeResourceProfile({required bool spatial}) =>
    spatial
    ? const RuntimeResourceProfile(maximumResidentBytes: 256 * 1024 * 1024)
    : const RuntimeResourceProfile(
        maximumResidentBytes: 256 * 1024 * 1024,
        maximumTransientBytes: 256 * 1024 * 1024,
        maximumConcurrentDecodes: 1,
      );

bool _referencesPresentationMedia(ProjectManifest project) {
  for (final cinematic in project.presentationCinematics) {
    for (final track in cinematic.tracks) {
      if (track.clips.any(
        (clip) =>
            clip is PresentationVisualClip ||
            clip is PresentationAudioClip ||
            clip is PresentationCaptionClip,
      )) {
        return true;
      }
    }
  }
  return false;
}
