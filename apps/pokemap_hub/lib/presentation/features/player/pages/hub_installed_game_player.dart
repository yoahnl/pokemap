import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
import 'package:pokemap_hub/features/session/domain/entities/hub_runtime_external_exit.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_game_source.dart';
import 'package:pokemap_hub/features/saves/application/services/hub_save_profile_manager.dart';
import 'package:pokemap_hub/features/session/application/services/hub_in_process_session_factory.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_player_strings.dart';
import 'package:pokemap_hub/features/session/domain/entities/hub_player_launch_intent.dart';
import 'package:pokemap_hub/features/session/application/services/hub_title_presentation_loader.dart';
import 'package:pokemap_hub/features/session/application/services/player_launch_failure.dart';
import 'package:pokemap_hub/presentation/features/player/state/player_typography_loader.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';

typedef HubPlayerReturnRequest = Future<void> Function();

const _aveluneStartupBranding = RuntimeHostSplashBranding(
  displayName: 'AVELUNE',
  signature: 'UNE AVENTURE POKÉMAP',
  primaryColorHex: '#C88A5A',
  secondaryColorHex: '#6F8F7A',
);

/// Production in-process composition for one verified installed game.
///
/// The Hub resolves installation, save, preference, and exit ports. From that
/// point on, [RuntimePlayerCoordinator] owns title/session/pause/result state,
/// while [PokeMapPlayerSessionView] owns every Flutter player surface.
class HubInstalledGamePlayer extends StatefulWidget {
  const HubInstalledGamePlayer({
    super.key,
    required this.supportRoot,
    required this.saveRepositoryFactory,
    required this.preferencesRepository,
    required this.controlProfileRepository,
    required this.launchResolver,
    required this.game,
    required this.onHubRequested,
    this.initialLaunchIntent = HubPlayerLaunchIntent.title,
    this.runtimeStartupShellEnabled = true,
    this.diagnosticLogFile,
    player_ui.PlayerPreferences? preferences,
  });

  final Directory supportRoot;

  /// Injected rather than constructed here: building repositories is the DI
  /// layer's job, and a widget that news up a store makes presentation depend
  /// on data (rules 2 and 6).
  final SaveRepositoryFactory saveRepositoryFactory;
  final PlayerPreferencesRepositoryInterface preferencesRepository;
  final ControlProfileRepositoryInterface controlProfileRepository;
  final SessionLaunchRepositoryInterface launchResolver;
  final InstalledGame game;
  final HubPlayerReturnRequest onHubRequested;
  final HubPlayerLaunchIntent initialLaunchIntent;

  /// Host-owned rollout capability. It is deliberately not project data: a
  /// verified game cannot opt itself into a host integration path.
  final bool runtimeStartupShellEnabled;
  final File? diagnosticLogFile;

  @override
  State<HubInstalledGamePlayer> createState() => _HubInstalledGamePlayerState();
}

class _HubInstalledGamePlayerState extends State<HubInstalledGamePlayer>
    with WidgetsBindingObserver {
  RuntimePlayerCoordinator? _coordinator;
  RuntimeStartupCoordinator? _startupCoordinator;
  RuntimeStartupSnapshot? _startupSnapshot;
  final player_ui.PlayerRuntimeStartupShellController _startupShellController =
      player_ui.PlayerRuntimeStartupShellController();
  player_ui.RuntimePlayerCoordinatorViewController? _viewController;
  GameSessionController? _sessions;
  PlayableMapGame? _mountedGame;
  InstalledGameLaunchContext? _launch;
  PlayerLaunchFailure? _failure;
  HubSaveSelection? _saveSelection;
  HubLoadedTitlePresentation? _titlePresentation;
  player_ui.PokeMapPlayerTypography _playerTypography =
      const player_ui.PokeMapPlayerTypography();
  RuntimeAudioMixer? _audioMixer;
  ControlProfileRepositoryInterface? _controlProfileStore;
  player_ui.PlayerControlProfile _controlProfile =
      player_ui.PlayerControlProfile.standard;
  StreamSubscription<RuntimeStartupSnapshot>? _startupSubscription;
  bool _reducedMotion = false;
  bool _initialLaunchDispatching = false;
  bool _initialLaunchHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    RuntimePlayerCoordinator? coordinator;
    RuntimeStartupCoordinator? startupCoordinator;
    RuntimeTitleMusicController? titleMusicController;
    StreamSubscription<RuntimeStartupSnapshot>? startupSubscription;
    try {
      final launch = await widget.launchResolver.resolve(widget.game);
      final store = widget.saveRepositoryFactory(
        widget.supportRoot,
        launch.identity,
      );
      final preferencesStore = widget.preferencesRepository;
      final preferences = (await preferencesStore.load()).preferences;
      final controlProfileStore = widget.controlProfileRepository;
      final controlProfile = await controlProfileStore.load();
      final audioMixer = RuntimeAudioMixer(
        mix: RuntimeAudioMix(
          masterVolume: preferences.masterVolume,
          musicVolume: preferences.musicVolume,
          effectsVolume: preferences.effectsVolume,
        ),
      );
      final preferencesGateway = HubPlayerPreferencesGateway(
        store: preferencesStore,
        fallbackLocale: launch.manifest.locales.defaultLocale,
        audioMixer: audioMixer,
      );
      final saveGateway = HubPlayerSaveGateway(store: store);
      final profileManager = HubSaveProfileManager(store: store);
      final playerLocale = ProjectLocaleResolver.resolve(
        preferredLocale: preferences.locale?.toLanguageTag() ??
            launch.manifest.locales.defaultLocale,
        supportedLocales: launch.manifest.locales.supported,
        fallbackLocale: launch.manifest.locales.defaultLocale,
      );
      final strings = HubInstalledPlayerStrings.forLocale(playerLocale);
      final saveSelection = await profileManager.ensureDefaultSelection(
        defaultProfileDisplayName: strings.defaultProfile,
        defaultSlotDisplayName: 'Slot 1',
      );
      final newGameIdentityPresentation =
          await loadNewGameIdentityPresentation(launch);
      final titlePresentation = await HubTitlePresentationLoader(
        manifest: launch.manifest,
        resolveFile: launch.assets.resolveFile,
      ).load(newGameIdentity: newGameIdentityPresentation);
      final loadedTypography = await loadPlayerTypography(titlePresentation);
      final gameSource = HubRuntimeGameSource(
        launch: launch,
        preferencesGateway: preferencesGateway,
      );
      final sessionFactory = HubInProcessSessionFactory(
        launch: launch,
        saves: store,
        mountGame: _mountGame,
        unmountGame: _unmountGame,
        audioMixer: audioMixer,
      );
      final sessions = GameSessionController(
        adapterFactory: sessionFactory.call,
        commitCheckpoint: saveGateway.commit,
      );
      coordinator = RuntimePlayerCoordinator(
        gameSource: gameSource,
        saveGateway: saveGateway,
        preferencesGateway: preferencesGateway,
        sessionController: sessions,
        externalExit: HubRuntimeExternalExit(widget.onHubRequested),
      );
      if (widget.runtimeStartupShellEnabled) {
        final startupTitleMusic =
            RuntimeTitleMusicController(mixer: audioMixer);
        titleMusicController = startupTitleMusic;
        final startupAdapter = HubRuntimeStartupAdapter(
          manifest: launch.manifest,
          assets: launch.assets,
        );
        startupCoordinator = RuntimeStartupCoordinator(
          playerCoordinator: coordinator,
          preparationPort: startupAdapter,
          assetResolver: startupAdapter,
          introController: RuntimeIntroSequenceController(),
          titleMusicController: startupTitleMusic,
          hostBranding: _aveluneStartupBranding,
          reducedMotion: preferences.reducedMotion,
          stopIntroPlayback: _startupShellController.stopIntroPlayback,
        );
        startupSubscription = startupCoordinator.snapshots.listen(
          _handleStartupSnapshot,
        );
      } else {
        // Rollback path for controlled host rollout. It preserves the direct
        // runtime player composition without reintroducing Hub-owned intro UI.
        await coordinator.initialize();
        final initialLaunch = await dispatchHubInitialLaunchIntent(
          intent: widget.initialLaunchIntent,
          snapshot: coordinator.snapshot,
          dispatch: coordinator.dispatch,
        );
        if (initialLaunch != null &&
            initialLaunch.status != RuntimePlayerCommandStatus.accepted) {
          throw StateError(
            initialLaunch.safeMessage ??
                'The selected save could not be resumed from Avelune.',
          );
        }
      }
      if (!mounted) {
        await startupSubscription?.cancel();
        if (startupCoordinator != null) {
          await startupCoordinator.dispose();
        } else {
          await titleMusicController?.dispose();
          await coordinator.dispose();
        }
        return;
      }
      setState(() {
        _launch = launch;
        _sessions = sessions;
        _coordinator = coordinator;
        _startupCoordinator = startupCoordinator;
        _startupSnapshot = startupCoordinator?.snapshot;
        _startupSubscription = startupSubscription;
        _saveSelection = saveSelection;
        _titlePresentation = titlePresentation;
        _playerTypography = loadedTypography;
        _audioMixer = audioMixer;
        _controlProfileStore = controlProfileStore;
        _controlProfile = controlProfile;
        _reducedMotion = preferences.reducedMotion;
        _viewController =
            player_ui.RuntimePlayerCoordinatorViewController(coordinator!);
      });
      startupCoordinator?.start();
    } on Object catch (error, stackTrace) {
      await startupSubscription?.cancel();
      if (startupCoordinator != null) {
        await startupCoordinator.dispose();
      } else {
        await titleMusicController?.dispose();
        await coordinator?.dispose();
      }
      final failure = await recordPlayerLaunchFailure(
        game: widget.game,
        supportRoot: widget.supportRoot,
        diagnosticLogFile: widget.diagnosticLogFile,
        error,
        stackTrace,
        event: 'playerLaunchFailed',
      );
      if (!mounted) return;
      setState(() => _failure = failure);
    }
  }

  void _handleStartupSnapshot(RuntimeStartupSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _startupSnapshot = snapshot);
    if (widget.initialLaunchIntent.skipsIntro) {
      unawaited(_driveInitialLaunchIntent(snapshot));
    }
  }

  /// Dashboard Continue remains a shortcut, but every skipped startup phase is
  /// still committed through the same revisioned runtime commands as a human
  /// press. One in-flight guard prevents a fast stream from double-launching.
  Future<void> _driveInitialLaunchIntent(
    RuntimeStartupSnapshot snapshot,
  ) async {
    final startup = _startupCoordinator;
    if (startup == null ||
        _initialLaunchHandled ||
        _initialLaunchDispatching ||
        !mounted) {
      return;
    }
    RuntimeStartupAction? startupAction;
    switch (snapshot.phase) {
      case RuntimeStartupPhase.preparing || RuntimeStartupPhase.splash:
        if (snapshot.canSkipSplash) {
          startupAction = RuntimeStartupAction.skipSplash;
        }
        break;
      case RuntimeStartupPhase.intro:
        if (snapshot.canContinueFromPoster) {
          startupAction = RuntimeStartupAction.continueFromPoster;
        } else if (snapshot.canSkipIntro) {
          startupAction = RuntimeStartupAction.skipIntro;
        }
        break;
      case RuntimeStartupPhase.titlePrompt:
        startupAction = RuntimeStartupAction.pressStart;
        break;
      case RuntimeStartupPhase.titleMenu:
        _initialLaunchDispatching = true;
        try {
          final player = snapshot.playerSnapshot;
          if (player == null) return;
          final result = await startup.dispatchPlayerCommand(
            startupSnapshotRevision: snapshot.revision,
            command: RuntimePlayerCommand(
              action: RuntimePlayerAction.continueGame,
              snapshotRevision: player.revision,
            ),
          );
          _initialLaunchHandled =
              result.status == RuntimePlayerCommandStatus.accepted;
        } finally {
          _initialLaunchDispatching = false;
        }
        return;
      case RuntimeStartupPhase.launchingSession ||
            RuntimeStartupPhase.completed:
        _initialLaunchHandled = true;
        return;
      case RuntimeStartupPhase.recoverableError ||
            RuntimeStartupPhase.lifecyclePaused:
        return;
    }
    if (startupAction == null) return;
    _initialLaunchDispatching = true;
    try {
      await startup.dispatch(
        RuntimeStartupCommand(
          action: startupAction,
          snapshotRevision: snapshot.revision,
        ),
      );
    } finally {
      _initialLaunchDispatching = false;
    }
    final current = startup.snapshot;
    if (mounted &&
        !_initialLaunchHandled &&
        current.revision != snapshot.revision) {
      unawaited(_driveInitialLaunchIntent(current));
    }
  }

  Future<void> _mountGame(PlayableMapGame game) async {
    if (!mounted) {
      throw StateError('The player surface closed before the game mounted.');
    }
    game.setDialogueFlutterOverlayPreferred(true);
    setState(() => _mountedGame = game);
  }

  Future<void> _unmountGame(PlayableMapGame game) async {
    if (!mounted || !identical(_mountedGame, game)) return;
    setState(() => _mountedGame = null);
  }

  Object? _payloadForAction(RuntimePlayerAction action) {
    if (action == RuntimePlayerAction.newGame) {
      final selection = _saveSelection;
      if (selection == null) return null;
      return RuntimePlayerLoadSlot(
        profileId: selection.profileId,
        slotId: selection.slotId,
      );
    }
    if (action == RuntimePlayerAction.load) {
      final selection = _saveSelection;
      if (selection != null) {
        return RuntimePlayerLoadSlot(
          profileId: selection.profileId,
          slotId: selection.slotId,
        );
      }
    }
    return null;
  }

  Future<void> _handleSystemBack() async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    final snapshot = coordinator.snapshot;
    final action = switch (snapshot.phase) {
      RuntimePlayerPhase.title
          when snapshot.pauseSection == RuntimePlayerPauseSection.options =>
        RuntimePlayerAction.returnToTitle,
      RuntimePlayerPhase.title => RuntimePlayerAction.returnToHost,
      RuntimePlayerPhase.playing => RuntimePlayerAction.openMenu,
      RuntimePlayerPhase.paused => RuntimePlayerAction.returnToTitle,
      RuntimePlayerPhase.preparingSession ||
      RuntimePlayerPhase.loadingSession =>
        RuntimePlayerAction.cancel,
      _ => null,
    };
    if (action == null || !snapshot.isActionEnabled(action)) return;
    await coordinator.dispatch(
      RuntimePlayerCommand(
        action: action,
        snapshotRevision: snapshot.revision,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final startup = _startupCoordinator;
    final coordinator = _coordinator;
    if (coordinator == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(
        startup?.resumeFromLifecycle() ?? coordinator.resumeFromLifecycle(),
      );
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(
        startup?.pauseForLifecycle() ?? coordinator.pauseForLifecycle(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = HubInstalledPlayerStrings.of(context);
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        body: player_ui.PlayerErrorSurface(
          title: strings.launchFailureTitle,
          message: strings.launchFailureMessage,
          recommendation: strings.launchFailureRecommendation,
          code: 'hub.player.${failure.code}',
          onReturnToHub: () => unawaited(widget.onHubRequested()),
          onShowDiagnostics: () => Clipboard.setData(
            ClipboardData(
              text: <String>[
                failure.details,
                if (failure.logPath != null) 'Log: ${failure.logPath}',
              ].join('\n'),
            ),
          ),
        ),
      );
    }
    final coordinator = _coordinator;
    final viewController = _viewController;
    final launch = _launch;
    final titlePresentation = _titlePresentation;
    final startup = _startupCoordinator;
    final startupSnapshot = _startupSnapshot;
    if (coordinator == null ||
        viewController == null ||
        launch == null ||
        titlePresentation == null ||
        (widget.runtimeStartupShellEnabled &&
            (startup == null || startupSnapshot == null))) {
      return Scaffold(
        body: player_ui.PlayerLoadingSurface(
          stage: strings.verifyingGame,
        ),
      );
    }
    var personalizedTheme = player_ui.PokeMapPlayerTheme.withTypography(
      Theme.of(context),
      _playerTypography,
    );
    if (titlePresentation.semanticTheme case final semanticTheme?) {
      personalizedTheme = player_ui.PokeMapPlayerTheme.withSemanticTheme(
        personalizedTheme,
        semanticTheme,
      );
    }
    final intro = titlePresentation.intro;
    final introSource = intro == null
        ? null
        : player_ui.PlayerIntroVideoSource(
            videoUri: File(intro.videoPath).uri,
            captionsLoader: intro.captionsPath == null
                ? null
                : File(intro.captionsPath!).readAsString,
            volume: _audioMixer?.mix.volumeFor(
                  RuntimeAudioRoute.cinematicMusic,
                ) ??
                1,
          );
    return Theme(
      data: personalizedTheme,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_handleSystemBack());
        },
        child: widget.runtimeStartupShellEnabled
            ? player_ui.PlayerRuntimeStartupShell(
                key: const ValueKey<String>('pokemap-runtime-startup-shell'),
                controller: _startupShellController,
                branding: _aveluneStartupBranding,
                snapshot: startupSnapshot!,
                titlePresentation: titlePresentation.title,
                introSource: introSource,
                introPoster: intro?.poster,
                splashLogo: const AssetImage(
                  'assets/avelune/logo/avelune_mark.webp',
                ),
                reducedMotion: _reducedMotion,
                payloadForAction: _payloadForAction,
                onStartupCommand: (command) =>
                    unawaited(startup!.dispatch(command)),
                onPlayerCommand: (command) => unawaited(
                  startup!.dispatchPlayerCommand(
                    startupSnapshotRevision: startupSnapshot.revision,
                    command: command,
                  ),
                ),
                onIntroPlaybackCompleted: (revision) => unawaited(
                  startup!.introPlaybackCompleted(
                    snapshotRevision: revision,
                  ),
                ),
                onIntroPlaybackFailed: (revision, reason) => unawaited(
                  startup!.introPlaybackFailed(
                    snapshotRevision: revision,
                    reason: reason,
                  ),
                ),
                sessionBuilder: (_, __) => _buildSessionView(
                  viewController,
                  titlePresentation.title,
                ),
              )
            : _buildSessionView(
                viewController,
                titlePresentation.title,
              ),
      ),
    );
  }

  Widget _buildSessionView(
    player_ui.RuntimePlayerCoordinatorViewController viewController,
    player_ui.RuntimePlayerTitlePresentation titlePresentation,
  ) =>
      player_ui.PokeMapPlayerSessionView(
        key: const ValueKey<String>('pokemap-runtime-player-view'),
        controller: viewController,
        titlePresentation: titlePresentation,
        payloadForAction: _payloadForAction,
        gameplayInputRoute: _sessions?.handleInput,
        gameplayInputAuthority: _mountedGame?.inputAuthorityListenable,
        dialoguePresentation: _mountedGame?.dialoguePresentationListenable,
        onDialogueCommand: _mountedGame?.dispatchDialoguePresentationCommand,
        controlProfile: _controlProfile,
        onControlProfileChanged: _updateControlProfile,
        gameSceneBuilder: (_) {
          final game = _mountedGame;
          return game == null
              ? const SizedBox.expand(
                  key: ValueKey<String>('runtime-game-awaiting-mount'),
                )
              : GameWidget(
                  key: ObjectKey(game),
                  game: game,
                  autofocus: false,
                );
        },
      );

  void _updateControlProfile(player_ui.PlayerControlProfile profile) {
    if (profile == _controlProfile) return;
    setState(() => _controlProfile = profile);
    final store = _controlProfileStore;
    if (store != null) unawaited(store.save(profile));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final coordinator = _coordinator;
    final startupCoordinator = _startupCoordinator;
    _coordinator = null;
    _startupCoordinator = null;
    _startupSnapshot = null;
    _viewController = null;
    _sessions = null;
    _audioMixer = null;
    final startupSubscription = _startupSubscription;
    _startupSubscription = null;
    if (startupSubscription != null) {
      unawaited(startupSubscription.cancel());
    }
    if (startupCoordinator != null) {
      unawaited(startupCoordinator.dispose());
    } else if (coordinator != null) {
      unawaited(coordinator.dispose());
    }
    super.dispose();
  }
}
