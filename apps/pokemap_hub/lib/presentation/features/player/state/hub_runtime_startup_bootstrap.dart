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
import 'package:pokemap_hub/features/session/application/services/hub_title_presentation_loader.dart';
import 'package:pokemap_hub/features/session/application/services/player_launch_failure.dart';
import 'package:pokemap_hub/features/session/domain/entities/hub_runtime_external_exit.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_player_strings.dart';

import 'player_typography_loader.dart';

final class HubRuntimeStartupPreparedData {
  const HubRuntimeStartupPreparedData({
    required this.sessions,
    required this.coordinator,
    required this.startupAdapter,
    required this.saveSelection,
    required this.titlePresentation,
    required this.playerLocale,
    required this.playerTypography,
    required this.audioMixer,
    required this.controlProfileStore,
    required this.controlProfile,
    required this.reducedMotion,
  });

  final GameSessionController sessions;
  final RuntimePlayerCoordinator coordinator;
  final HubRuntimeStartupAdapter startupAdapter;
  final HubSaveSelection saveSelection;
  final HubLoadedTitlePresentation titlePresentation;
  final String playerLocale;
  final player_ui.PokeMapPlayerTypography playerTypography;
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
      final strings = HubInstalledPlayerStrings.forLocale(playerLocale);
      final saveSelection = await HubSaveProfileManager(
        store: store,
      ).ensureDefaultSelection(
        defaultProfileDisplayName: strings.defaultProfile,
        defaultSlotDisplayName: 'Slot 1',
      );
      onStageCompleted(RuntimeStartupBootstrapStage.hostStorage);

      final titlePresentation =
          await HubTitlePresentationLoader(
            manifest: launch.manifest,
            resolveFile: launch.assets.resolveFile,
          ).load();
      final playerTypography = await loadPlayerTypography(titlePresentation);
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
        sessionController: sessions,
        externalExit: HubRuntimeExternalExit(onHubRequested),
      );
      final startupAdapter = HubRuntimeStartupAdapter(
        manifest: launch.manifest,
        assets: launch.assets,
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
          saveSelection: saveSelection,
          titlePresentation: titlePresentation,
          playerLocale: playerLocale,
          playerTypography: playerTypography,
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
