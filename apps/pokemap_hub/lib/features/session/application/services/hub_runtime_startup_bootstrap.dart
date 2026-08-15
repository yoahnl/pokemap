import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/saves/application/services/hub_save_profile_manager.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/application/services/hub_in_process_session_factory.dart';
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
  });

  final GameSessionController sessions;
  final RuntimePlayerCoordinator coordinator;
  final HubRuntimeStartupAdapter startupAdapter;
  final String playerLocale;
  final RuntimeAudioMixer audioMixer;
  final ControlProfileRepositoryInterface controlProfileStore;
  final player_ui.PlayerControlProfile controlProfile;
  final bool reducedMotion;
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

  @override
  Future<RuntimeStartupBootstrapResult<HubRuntimeStartupPreparedData>> prepare({
    required RuntimeStartupBootstrapStageSink onStageCompleted,
  }) async {
    try {
      final launch = await launchResolver.resolve(game);
      onStageCompleted(RuntimeStartupBootstrapStage.projectResolution);

      final preferencesRead = await preferencesRepository.load();
      final preferences = preferencesRead.preferences;
      onStageCompleted(RuntimeStartupBootstrapStage.playerPreferences);

      final controlProfile = await controlProfileRepository.load();
      onStageCompleted(RuntimeStartupBootstrapStage.controlProfile);

      final store = saveRepositoryFactory(supportRoot, launch.identity);
      final audioMixer = RuntimeAudioMixer(
        mix: RuntimeAudioMix(
          masterVolume: preferences.masterVolume,
          musicVolume: preferences.musicVolume,
          effectsVolume: preferences.effectsVolume,
        ),
      );
      final preferencesGateway = HubPlayerPreferencesGateway(
        store: preferencesRepository,
        fallbackLocale: launch.manifest.locales.defaultLocale,
        audioMixer: audioMixer,
      );
      final saveGateway = HubPlayerSaveGateway(store: store);
      final playerLocale = ProjectLocaleResolver.resolve(
        preferredLocale:
            preferences.locale?.toLanguageTag() ??
            launch.manifest.locales.defaultLocale,
        supportedLocales: launch.manifest.locales.supported,
        fallbackLocale: launch.manifest.locales.defaultLocale,
      );
      final saveSelection = await HubSaveProfileManager(
        store: store,
      ).ensureDefaultSelection(
        defaultProfileDisplayName: defaultProfileDisplayNameForLocale(
          playerLocale,
        ),
        defaultSlotDisplayName: 'Slot 1',
      );
      onStageCompleted(RuntimeStartupBootstrapStage.hostStorage);

      final startupAdapter = HubRuntimeStartupAdapter(
        manifest: launch.manifest,
        assets: launch.assets,
      );
      onStageCompleted(RuntimeStartupBootstrapStage.presentationBinding);

      final gameSource = HubRuntimeGameSource(
        launch: launch,
        preferencesGateway: preferencesGateway,
      );
      final initialMapPreloader = RuntimeInitialMapPreloader(
        projectFilePath: () async {
          final project = await launch.assets.resolveReference(launch.project);
          return project.path;
        },
        loadSave: saveGateway.readLaunchableEnvelope,
      );
      final newGameFlow = RuntimeProjectNewGameFlowPort(
        projectFilePath: () async {
          final project = await launch.assets.resolveReference(launch.project);
          return project.path;
        },
        initialMapPreloader: initialMapPreloader,
      );
      final sessionFactory = HubInProcessSessionFactory(
        launch: launch,
        saves: store,
        mountGame: mountGame,
        unmountGame: unmountGame,
        preloadedInitialMap: initialMapPreloader.resolveForSession,
        audioMixer: audioMixer,
      );
      final sessions = GameSessionController(
        adapterFactory: sessionFactory.call,
        commitCheckpoint: saveGateway.commit,
      );
      final coordinator = RuntimePlayerCoordinator(
        gameSource: gameSource,
        saveGateway: saveGateway,
        preferencesGateway: preferencesGateway,
        newGameFlow: newGameFlow,
        sessionController: sessions,
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
        splashJingleController: RuntimeSplashJingleController(
          mixer: audioMixer,
        ),
        titleMusicController: RuntimeTitleMusicController(mixer: audioMixer),
        presentationMetadata: RuntimeStartupPresentationMetadata(
          author: launch.manifest.author.name,
          description: launch.manifest.description,
        ),
        reducedMotion: preferences.reducedMotion,
        stopIntroPlayback: stopIntroPlayback,
      );
      onStageCompleted(RuntimeStartupBootstrapStage.runtimeGraph);
      return RuntimeStartupBootstrapResult<HubRuntimeStartupPreparedData>(
        graph: graph,
        value: HubRuntimeStartupPreparedData(
          sessions: sessions,
          coordinator: coordinator,
          startupAdapter: startupAdapter,
          playerLocale: playerLocale,
          audioMixer: audioMixer,
          controlProfileStore: controlProfileRepository,
          controlProfile: controlProfile,
          reducedMotion: preferences.reducedMotion,
        ),
      );
    } on Object catch (error, stackTrace) {
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
