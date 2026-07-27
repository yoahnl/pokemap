import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../library/game_library.dart';
import '../../player/hub_player_preferences_gateway.dart';
import '../../player/hub_player_save_gateway.dart';
import '../../player/hub_runtime_external_exit.dart';
import '../../player/hub_runtime_game_source.dart';
import '../../saves/hub_save_store.dart';
import '../../saves/hub_save_profile_manager.dart';
import '../../session/hub_in_process_session_factory.dart';
import '../../session/installed_game_launch_resolver.dart';
import '../preferences/hub_preferences_store.dart';
import 'hub_intro_video_player.dart';
import 'hub_save_profiles_screen.dart';
import 'hub_title_presentation_loader.dart';

typedef HubPlayerReturnRequest = Future<void> Function();

/// Production in-process composition for one verified installed game.
///
/// The Hub resolves installation, save, preference, and exit ports. From that
/// point on, [RuntimePlayerCoordinator] owns title/session/pause/result state,
/// while [PokeMapPlayerSessionView] owns every Flutter player surface.
class HubInstalledGamePlayer extends StatefulWidget {
  const HubInstalledGamePlayer({
    super.key,
    required this.supportRoot,
    required this.launchResolver,
    required this.game,
    required this.onHubRequested,
    this.diagnosticLogFile,
    player_ui.PlayerPreferences? preferences,
  });

  final Directory supportRoot;
  final InstalledGameLaunchResolver launchResolver;
  final InstalledGame game;
  final HubPlayerReturnRequest onHubRequested;
  final File? diagnosticLogFile;

  @override
  State<HubInstalledGamePlayer> createState() => _HubInstalledGamePlayerState();
}

class _HubInstalledGamePlayerState extends State<HubInstalledGamePlayer>
    with WidgetsBindingObserver {
  RuntimePlayerCoordinator? _coordinator;
  player_ui.RuntimePlayerCoordinatorViewController? _viewController;
  GameSessionController? _sessions;
  PlayableMapGame? _mountedGame;
  InstalledGameLaunchContext? _launch;
  _PlayerLaunchFailure? _failure;
  HubSaveProfileManager? _profileManager;
  HubSaveSelection? _saveSelection;
  HubLoadedTitlePresentation? _titlePresentation;
  player_ui.PokeMapPlayerTypography _playerTypography =
      const player_ui.PokeMapPlayerTypography();
  RuntimeTitleMusicController? _titleMusicController;
  RuntimeAudioMixer? _audioMixer;
  StreamSubscription<RuntimePlayerSnapshot>? _titleMusicSubscription;
  bool _introComplete = true;
  bool _reducedMotion = false;
  bool _managingSaves = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    RuntimePlayerCoordinator? coordinator;
    RuntimeTitleMusicController? titleMusicController;
    StreamSubscription<RuntimePlayerSnapshot>? titleMusicSubscription;
    try {
      final launch = await widget.launchResolver.resolve(widget.game);
      final store = HubSaveStore(
        supportRoot: widget.supportRoot,
        identity: launch.identity,
      );
      final preferencesStore =
          HubPreferencesStore(supportRoot: widget.supportRoot);
      final preferences = (await preferencesStore.load()).preferences;
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
      final isFrench =
          launch.manifest.locales.defaultLocale.toLowerCase().startsWith('fr');
      final saveSelection = await profileManager.ensureDefaultSelection(
        defaultProfileDisplayName: isFrench ? 'Joueur' : 'Player',
        defaultSlotDisplayName: 'Slot 1',
      );
      final newGameIdentityPresentation =
          await _loadNewGameIdentityPresentation(launch);
      final titlePresentation = await HubTitlePresentationLoader(
        manifest: launch.manifest,
        resolveFile: launch.assets.resolveFile,
      ).load(newGameIdentity: newGameIdentityPresentation);
      final loadedTypography = await _loadTypography(titlePresentation);
      final intro = titlePresentation.intro;
      _reducedMotion = preferences.reducedMotion;
      _introComplete = intro == null ||
          (_reducedMotion &&
              (intro.reducedMotionBehavior == 'skip' || intro.poster == null));
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
      await coordinator.initialize();
      titleMusicController = RuntimeTitleMusicController(mixer: audioMixer);
      titleMusicSubscription = coordinator.snapshots.listen(
        (snapshot) => unawaited(
          titleMusicController!.update(
            path: titlePresentation.titleMusicPath,
            titleVisible:
                _introComplete && snapshot.phase == RuntimePlayerPhase.title,
            volume: 1,
          ),
        ),
      );
      await titleMusicController.update(
        path: titlePresentation.titleMusicPath,
        titleVisible: _introComplete &&
            coordinator.snapshot.phase == RuntimePlayerPhase.title,
        volume: 1,
      );
      if (!mounted) {
        await titleMusicSubscription.cancel();
        await titleMusicController.dispose();
        await coordinator.dispose();
        return;
      }
      setState(() {
        _launch = launch;
        _sessions = sessions;
        _coordinator = coordinator;
        _profileManager = profileManager;
        _saveSelection = saveSelection;
        _titlePresentation = titlePresentation;
        _playerTypography = loadedTypography;
        _titleMusicController = titleMusicController;
        _audioMixer = audioMixer;
        _titleMusicSubscription = titleMusicSubscription;
        _viewController =
            player_ui.RuntimePlayerCoordinatorViewController(coordinator!);
      });
    } on Object catch (error, stackTrace) {
      await titleMusicSubscription?.cancel();
      await titleMusicController?.dispose();
      await coordinator?.dispose();
      final failure = await _recordFailure(
        error,
        stackTrace,
        event: 'playerLaunchFailed',
      );
      if (!mounted) return;
      setState(() => _failure = failure);
    }
  }

  Future<player_ui.PokeMapPlayerTypography> _loadTypography(
    HubLoadedTitlePresentation presentation,
  ) async {
    final typography = presentation.typography;
    if (typography == null) {
      return const player_ui.PokeMapPlayerTypography();
    }
    final loaded = await const RuntimeProjectTypographyLoader().load(
      <ProjectTypographyRole, RuntimeProjectFontRequest>{
        for (final entry in typography.roles.entries)
          entry.key: RuntimeProjectFontRequest(
            file: entry.value.file,
            family: entry.value.family,
            fallbackFamilies: entry.value.fallbackFamilies,
          ),
      },
    );
    RuntimeLoadedFontRole role(
      ProjectTypographyRole role,
      List<String> fallback,
    ) =>
        loaded.roles[role] ??
        RuntimeLoadedFontRole(
          registeredFamily: null,
          fallbackFamilies: fallback,
        );

    final display =
        role(ProjectTypographyRole.display, const <String>['sans-serif']);
    final body = role(ProjectTypographyRole.body, const <String>['sans-serif']);
    final dialogue =
        role(ProjectTypographyRole.dialogue, const <String>['sans-serif']);
    final numbers =
        role(ProjectTypographyRole.numbers, const <String>['monospace']);
    return player_ui.PokeMapPlayerTypography(
      displayFamily: display.registeredFamily,
      displayFallback: display.fallbackFamilies,
      bodyFamily: body.registeredFamily,
      bodyFallback: body.fallbackFamilies,
      dialogueFamily: dialogue.registeredFamily,
      dialogueFallback: dialogue.fallbackFamilies,
      numbersFamily: numbers.registeredFamily,
      numbersFallback: numbers.fallbackFamilies,
    );
  }

  Future<player_ui.PlayerNewGameIdentityPresentation>
      _loadNewGameIdentityPresentation(
    InstalledGameLaunchContext launch,
  ) async {
    final projectFile = await launch.assets.resolveReference(launch.project);
    final decoded = jsonDecode(await projectFile.readAsString());
    if (decoded is! Map) {
      throw const FormatException(
        'The installed project manifest must be a JSON object.',
      );
    }
    final project = ProjectManifest.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final config = project.newGame;
    final charactersById = <String, ProjectCharacterEntry>{
      for (final character in project.characters) character.id: character,
    };
    final authoredIds = config.playerAvatarCharacterIds;
    final fallbackId = project.settings.defaultPlayerCharacterId?.trim();
    final avatarIds = authoredIds.isNotEmpty
        ? authoredIds
        : fallbackId == null || fallbackId.isEmpty
            ? const <String>[]
            : <String>[fallbackId];
    return player_ui.PlayerNewGameIdentityPresentation(
      defaultName: config.playerName,
      defaultPronounSet: config.playerPronounSet,
      defaultAvatarCharacterId: fallbackId,
      avatarOptions: <player_ui.PlayerNewGameAvatarOption>[
        for (final id in avatarIds)
          if (charactersById[id] case final character?)
            player_ui.PlayerNewGameAvatarOption(
              characterId: character.id,
              label: character.name,
            ),
      ],
    );
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
    final coordinator = _coordinator;
    if (coordinator == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_titleMusicController?.resumeFromLifecycle());
      unawaited(coordinator.resumeFromLifecycle());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_titleMusicController?.pauseForLifecycle());
      unawaited(coordinator.pauseForLifecycle());
    }
  }

  Future<_PlayerLaunchFailure> _recordFailure(
    Object error,
    StackTrace stackTrace, {
    required String event,
  }) async {
    final cause = switch (error) {
      InstalledGameLaunchException(:final cause) => cause,
      _ => null,
    };
    final details = <String>[
      error.toString(),
      if (cause != null) 'Cause: $cause',
      stackTrace.toString(),
    ].join('\n');
    final logFile = widget.diagnosticLogFile ??
        File(
          p.join(
            widget.supportRoot.path,
            'logs',
            'hub-player.log',
          ),
        );
    String? logPath;
    try {
      await logFile.parent.create(recursive: true);
      await logFile.writeAsString(
        '${jsonEncode(<String, Object?>{
              'timestamp': DateTime.now().toUtc().toIso8601String(),
              'event': event,
              'gameId': widget.game.gameId,
              'gameVersion': widget.game.current.gameVersion.toString(),
              'errorType': error.runtimeType.toString(),
              'error': error.toString(),
              if (cause != null) 'cause': cause.toString(),
              'stackTrace': stackTrace.toString(),
            })}\n',
        mode: FileMode.append,
        flush: true,
      );
      logPath = logFile.path;
    } on Object {
      // The player-safe error remains available if log persistence fails.
    }
    return _PlayerLaunchFailure(
      code: switch (error) {
        InstalledGameLaunchException(:final code) => code.name,
        _ => 'unexpected',
      },
      details: details,
      logPath: logPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Scaffold(
        body: player_ui.PlayerErrorSurface(
          title: 'Impossible d’ouvrir ce jeu',
          message: 'La session joueur n’a pas pu être validée.',
          recommendation:
              'Le jeu installé et ses sauvegardes n’ont pas été modifiés.',
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
    if (coordinator == null ||
        viewController == null ||
        launch == null ||
        titlePresentation == null) {
      return const Scaffold(
        body: player_ui.PlayerLoadingSurface(
          stage: 'Vérification du jeu installé…',
        ),
      );
    }
    final profileManager = _profileManager;
    final saveSelection = _saveSelection;
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
    if (!_introComplete && intro != null) {
      return Theme(
        data: personalizedTheme,
        child: Scaffold(
          body: HubIntroVideoPlayer(
            intro: intro,
            reducedMotion: _reducedMotion,
            volume: _audioMixer?.mix.volumeFor(
                  RuntimeAudioRoute.cinematicMusic,
                ) ??
                1,
            onFinished: _finishIntro,
          ),
        ),
      );
    }
    if (_managingSaves && profileManager != null && saveSelection != null) {
      return Theme(
        data: personalizedTheme,
        child: HubSaveProfilesScreen(
          manager: profileManager,
          initialSelection: saveSelection,
          onSelected: (selection) {
            setState(() {
              _saveSelection = selection;
              _managingSaves = false;
            });
          },
          onClose: () => setState(() => _managingSaves = false),
        ),
      );
    }
    return Theme(
      data: personalizedTheme,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_handleSystemBack());
        },
        child: StreamBuilder<RuntimePlayerSnapshot>(
          stream: coordinator.snapshots,
          initialData: coordinator.snapshot,
          builder: (context, asyncSnapshot) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              player_ui.PokeMapPlayerSessionView(
                key: const ValueKey<String>('pokemap-runtime-player-view'),
                controller: viewController,
                titlePresentation: titlePresentation.title,
                payloadForAction: _payloadForAction,
                gameplayInputRoute: _sessions?.handleInput,
                gameplayInputAuthority: _mountedGame?.inputAuthorityListenable,
                dialoguePresentation:
                    _mountedGame?.dialoguePresentationListenable,
                onDialogueCommand:
                    _mountedGame?.dispatchDialoguePresentationCommand,
                gameSceneBuilder: (_) {
                  final game = _mountedGame;
                  return game == null
                      ? const SizedBox.expand(
                          key: ValueKey<String>(
                            'runtime-game-awaiting-mount',
                          ),
                        )
                      : GameWidget(
                          key: ObjectKey(game),
                          game: game,
                          autofocus: false,
                        );
                },
              ),
              if ((asyncSnapshot.data ?? coordinator.snapshot).phase ==
                      RuntimePlayerPhase.title &&
                  (asyncSnapshot.data ?? coordinator.snapshot).pauseSection ==
                      null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FilledButton.icon(
                    key: const ValueKey<String>('open-save-profiles'),
                    onPressed: () => setState(() => _managingSaves = true),
                    icon: const Icon(Icons.manage_accounts),
                    label: Text(HubSaveProfilesStrings.of(context).open),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishIntro() {
    if (_introComplete || !mounted) return;
    setState(() => _introComplete = true);
    final coordinator = _coordinator;
    final presentation = _titlePresentation;
    if (coordinator == null || presentation == null) return;
    unawaited(
      _titleMusicController?.update(
        path: presentation.titleMusicPath,
        titleVisible: coordinator.snapshot.phase == RuntimePlayerPhase.title,
        volume: 1,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final coordinator = _coordinator;
    _coordinator = null;
    _viewController = null;
    _sessions = null;
    _audioMixer = null;
    final titleMusicSubscription = _titleMusicSubscription;
    _titleMusicSubscription = null;
    final titleMusicController = _titleMusicController;
    _titleMusicController = null;
    if (titleMusicSubscription != null) {
      unawaited(titleMusicSubscription.cancel());
    }
    if (titleMusicController != null) {
      unawaited(titleMusicController.dispose());
    }
    if (coordinator != null) unawaited(coordinator.dispose());
    super.dispose();
  }
}

final class _PlayerLaunchFailure {
  const _PlayerLaunchFailure({
    required this.code,
    required this.details,
    required this.logPath,
  });

  final String code;
  final String details;
  final String? logPath;
}
