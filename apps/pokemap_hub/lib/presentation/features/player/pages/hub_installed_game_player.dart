import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/presentation/features/player/state/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';

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
    required this.saveRepositoryFactory,
    required this.preferencesRepository,
    required this.controlProfileRepository,
    required this.launchResolver,
    required this.game,
    required this.onHubRequested,
    required this.hostBranding,
    required this.splashLogo,
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
  final RuntimeHostSplashBranding hostBranding;
  final ImageProvider? splashLogo;
  final File? diagnosticLogFile;

  @override
  State<HubInstalledGamePlayer> createState() => _HubInstalledGamePlayerState();
}

class _HubInstalledGamePlayerState extends State<HubInstalledGamePlayer>
    with WidgetsBindingObserver {
  RuntimeStartupBootstrapCoordinator<HubRuntimeStartupPreparedData>?
  _startupCoordinator;
  HubRuntimeStartupAdapter? _startupAdapter;
  RuntimeStartupSnapshot? _startupSnapshot;
  final player_ui.PlayerRuntimeStartupShellController _startupShellController =
      player_ui.PlayerRuntimeStartupShellController();
  player_ui.RuntimePlayerCoordinatorViewController? _viewController;
  GameSessionController? _sessions;
  PlayableMapGame? _mountedGame;
  Locale? _playerLocale;
  RuntimeAudioMixer? _audioMixer;
  ControlProfileRepositoryInterface? _controlProfileStore;
  player_ui.PlayerControlProfile _controlProfile =
      player_ui.PlayerControlProfile.standard;
  StreamSubscription<RuntimeStartupSnapshot>? _startupSubscription;
  bool _lifecycleActive = true;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRuntimeBootstrap();
  }

  void _startRuntimeBootstrap() {
    final startup =
        RuntimeStartupBootstrapCoordinator<HubRuntimeStartupPreparedData>(
          bootstrapPort: HubRuntimeStartupBootstrap(
            supportRoot: widget.supportRoot,
            saveRepositoryFactory: widget.saveRepositoryFactory,
            preferencesRepository: widget.preferencesRepository,
            controlProfileRepository: widget.controlProfileRepository,
            launchResolver: widget.launchResolver,
            game: widget.game,
            onHubRequested: widget.onHubRequested,
            mountGame: _mountGame,
            unmountGame: _unmountGame,
            stopIntroPlayback: _startupShellController.stopIntroPlayback,
            diagnosticLogFile: widget.diagnosticLogFile,
          ),
          hostBranding: widget.hostBranding,
          onPrepared: _acceptRuntimeBootstrap,
        );
    _startupCoordinator = startup;
    _startupSnapshot = startup.snapshot;
    _startupSubscription = startup.snapshots.listen(_handleStartupSnapshot);
    startup.start();
  }

  void _acceptRuntimeBootstrap(HubRuntimeStartupPreparedData prepared) {
    if (!mounted) return;
    setState(() {
      _sessions = prepared.sessions;
      _startupAdapter = prepared.startupAdapter;
      _playerLocale = Locale(
        prepared.playerLocale.split(RegExp('[-_]')).first.toLowerCase(),
      );
      _audioMixer = prepared.audioMixer;
      _controlProfileStore = prepared.controlProfileStore;
      _controlProfile = prepared.controlProfile;
      _reducedMotion = prepared.reducedMotion;
      _viewController = player_ui.RuntimePlayerCoordinatorViewController(
        prepared.coordinator,
      );
    });
  }

  void _handleStartupSnapshot(RuntimeStartupSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _startupSnapshot = snapshot);
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

  ImageProvider? _startupImage(RuntimeStartupPresentationAsset? asset) {
    final adapter = _startupAdapter;
    if (adapter == null || asset == null) return null;
    final resolved = adapter.resolvedAsset(asset.assetId);
    if (resolved == null || resolved.resolvedUri.scheme != 'file') return null;
    return FileImage(File.fromUri(resolved.resolvedUri));
  }

  player_ui.PlayerIntroVideoSource? _startupVideo(
    RuntimeStartupPresentationAsset? asset,
    ProjectVideoVariantProfile? variant, {
    required bool looping,
    required double volume,
  }) {
    final adapter = _startupAdapter;
    if (adapter == null || asset == null || variant == null) return null;
    final resolved = adapter.resolvedAsset(asset.assetId);
    if (resolved == null) return null;
    return player_ui.PlayerIntroVideoSource(
      videoUri: resolved.resolvedUri,
      captionsLoader:
          variant.captionsPath == null
              ? null
              : () => adapter.loadText(variant.captionsPath!),
      volume: volume,
      looping: looping,
      aspectRatio: variant.width / variant.height,
      focalX: variant.focalX,
      focalY: variant.focalY,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final startup = _startupCoordinator;
    if (state == AppLifecycleState.resumed) {
      if (!_lifecycleActive && mounted) {
        setState(() => _lifecycleActive = true);
      }
      if (startup != null) {
        unawaited(startup.resumeFromLifecycle());
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_lifecycleActive && mounted) {
        setState(() => _lifecycleActive = false);
      }
      if (startup != null) {
        unawaited(startup.pauseForLifecycle());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewController = _viewController;
    final startup = _startupCoordinator!;
    final effectiveSnapshot = _startupSnapshot ?? startup.snapshot;
    final visiblePhase =
        effectiveSnapshot.phase == RuntimeStartupPhase.lifecyclePaused
            ? effectiveSnapshot.suspendedPhase ?? RuntimeStartupPhase.splash
            : effectiveSnapshot.phase;
    final resolvedPresentation = effectiveSnapshot.presentation;
    final playerPresentation = resolvedPresentation == null
        ? const player_ui.RuntimePlayerPresentation(
            title: player_ui.RuntimePlayerTitlePresentation(author: ''),
          )
        : player_ui.RuntimePlayerPresentation.fromRuntime(
            resolvedPresentation,
            imageForAsset: _startupImage,
          );
    final personalizedTheme = playerPresentation.applyTo(Theme.of(context));
    final startupTheme =
        visiblePhase == RuntimeStartupPhase.preparing ||
                visiblePhase == RuntimeStartupPhase.splash
            ? player_ui.PokeMapPlayerTheme.dark(reducedMotion: _reducedMotion)
            : personalizedTheme;
    final presentationProfile = resolvedPresentation?.profile;
    final orientation =
        resolvedPresentation?.orientation ??
        RuntimePresentationOrientation.landscape;
    final introProfile = presentationProfile?.intro;
    final promptMedia = presentationProfile?.titleMotion?.promptLoop;
    final menuMedia = presentationProfile?.titleMotion?.menuLoop;
    final introVariant =
        introProfile == null
            ? null
            : selectRuntimePresentationVideo(
              introProfile.media,
              orientation,
            ).variant;
    final promptVariant =
        promptMedia == null
            ? null
            : selectRuntimePresentationVideo(promptMedia, orientation).variant;
    final menuVariant =
        menuMedia == null
            ? null
            : selectRuntimePresentationVideo(menuMedia, orientation).variant;
    final introSource = _startupVideo(
      resolvedPresentation?.introVideo,
      introVariant,
      looping: false,
      volume: _audioMixer?.mix.volumeFor(RuntimeAudioRoute.cinematicMusic) ?? 1,
    );
    final player = Theme(
      data: startupTheme,
      child: player_ui.PlayerRuntimeStartupShell(
          key: const ValueKey<String>('pokemap-runtime-startup-shell'),
          controller: _startupShellController,
          branding: widget.hostBranding,
          snapshot: effectiveSnapshot,
          titlePresentation:
              playerPresentation.title,
          introSource: introSource,
          introPoster: _startupImage(resolvedPresentation?.introPoster),
          titlePromptSource: _startupVideo(
            resolvedPresentation?.titlePromptVideo,
            promptVariant,
            looping: true,
            volume: 0,
          ),
          titlePromptPoster: _startupImage(
            resolvedPresentation?.titlePromptPoster,
          ),
          titleMenuSource: _startupVideo(
            resolvedPresentation?.titleMenuVideo,
            menuVariant,
            looping: true,
            volume: 0,
          ),
          titleMenuPoster: _startupImage(resolvedPresentation?.titleMenuPoster),
          splashLogo: widget.splashLogo,
          reducedMotion: _reducedMotion,
          onPresentationOrientationChanged: (nextOrientation) {
            unawaited(startup.updatePresentationOrientation(nextOrientation));
          },
          onStartupCommand: (command) {
            unawaited(startup.dispatch(command));
          },
          onPlayerCommand: (command) {
            unawaited(
              startup.dispatchPlayerCommand(
                startupSnapshotRevision: effectiveSnapshot.revision,
                command: command,
              ),
            );
          },
          onIntroPlaybackCompleted: (revision) {
            unawaited(
              startup.introPlaybackCompleted(snapshotRevision: revision),
            );
          },
          onIntroPlaybackFailed: (revision, reason) {
            unawaited(
              startup.introPlaybackFailed(
                snapshotRevision: revision,
                reason: reason,
              ),
            );
          },
          sessionBuilder:
              viewController == null
                  ? (_, _) => const SizedBox.expand()
                  : (_, _) =>
                      _buildSessionView(viewController, playerPresentation),
      ),
    );
    final playerLocale = _playerLocale;
    if (playerLocale == null) return player;
    return Localizations.override(
      context: context,
      locale: playerLocale,
      child: player,
    );
  }

  Widget _buildSessionView(
    player_ui.RuntimePlayerCoordinatorViewController viewController,
    player_ui.RuntimePlayerPresentation presentation,
  ) => player_ui.PokeMapPlayerSessionView(
    key: const ValueKey<String>('pokemap-runtime-player-view'),
    controller: viewController,
    titlePresentation: presentation.title,
    pauseMenuLabels: presentation.pauseMenuLabels,
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
          : GameWidget(key: ObjectKey(game), game: game, autofocus: false);
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
    final startupCoordinator = _startupCoordinator;
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
    }
    super.dispose();
  }
}
