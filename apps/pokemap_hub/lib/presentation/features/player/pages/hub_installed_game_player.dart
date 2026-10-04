import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/application/services/hub_installed_presentation_runtime.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_player_strings.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion.dart';
import 'package:flutter/services.dart';

typedef HubPlayerReturnRequest = Future<void> Function();

class HubInstalledGamePlayerController {
  Future<void> Function()? _stop;

  Future<void> stop() async => await _stop?.call();
}

class _HubGameplayCompanionPort implements AveluneGameplayCompanionOwnerPort {
  _HubGameplayCompanionPort(this.owner, this.coordinator);

  final _HubInstalledGamePlayerState owner;
  final RuntimePlayerCoordinator coordinator;
  RuntimeStartupResolvedPresentation? _presentationSource;
  Map<String, Object?>? _presentationCache;
  bool? _presentationDark;
  bool? _presentationReducedMotion;
  String? _presentationLocale;

  bool get _current => owner.mounted && !owner._closing && identical(owner._viewController?.coordinator, coordinator);

  @override
  bool get isPaused => _current && coordinator.snapshot.phase == RuntimePlayerPhase.paused && coordinator.snapshot.worldService == null && owner._mountedGame?.battleExitTransitionVisible.value != true;

  @override
  Future<AveluneGameplayCompanionData> read() async {
    if (!_current) return const AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.waiting);
    final snapshot = coordinator.snapshot;
    final game = owner._mountedGame;
    final presentation = _presentation();
    if (snapshot.worldService != null) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.blocked, presentation: presentation);
    }
    if (game?.battleExitTransitionVisible.value == true) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.blocked, presentation: presentation);
    }
    if (snapshot.phase == RuntimePlayerPhase.paused || snapshot.phase == RuntimePlayerPhase.saving) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.menu, player: snapshot, presentation: presentation);
    }
    if (snapshot.phase != RuntimePlayerPhase.playing || game == null) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.waiting, presentation: presentation);
    }
    final authority = game.inputAuthorityListenable.value;
    final battle = game.battleCommandOverlayListenable.value;
    if (battle != null || authority.context == RuntimeInputContext.battle) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.battle, battle: battle, presentation: presentation);
    }
    if (authority.context == RuntimeInputContext.transition || authority.context == RuntimeInputContext.cinematic || authority.context == RuntimeInputContext.blocked) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.blocked, presentation: presentation);
    }
    final menu = await coordinator.readCompanionMenu();
    if (!_current || !identical(snapshot, coordinator.snapshot) || !identical(game, owner._mountedGame) || menu == null ||
        game.battleCommandOverlayListenable.value != null || game.inputAuthorityListenable.value.context != authority.context) {
      return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.blocked, presentation: presentation);
    }
    return AveluneGameplayCompanionData(mode: AveluneGameplayCompanionMode.menu, player: menu, presentation: presentation);
  }

  Map<String, Object?> _presentation() {
    final resolved = owner._startupSnapshot?.presentation;
    if (resolved == null) return const {};
    final dark = Theme.of(owner.context).brightness == Brightness.dark;
    final locale = coordinator.snapshot.preferences?.locale ?? coordinator.snapshot.defaultPreferences.locale;
    if (identical(resolved, _presentationSource) && dark == _presentationDark && owner._reducedMotion == _presentationReducedMotion && locale == _presentationLocale && _presentationCache != null) {
      return _presentationCache!;
    }
    _presentationSource = resolved;
    _presentationDark = dark;
    _presentationReducedMotion = owner._reducedMotion;
    _presentationLocale = locale;
    final adapter = owner._startupAdapter;
    final profile = resolved.profile;
    final typography = profile?.typography;
    final fontProfiles = typography == null ? <ProjectTypographyRole, ProjectTypographyRoleProfile>{} : {
      ProjectTypographyRole.display: typography.display,
      ProjectTypographyRole.body: typography.body,
      ProjectTypographyRole.dialogue: typography.dialogue,
      if (typography.combat != null) ProjectTypographyRole.combat: typography.combat!,
      ProjectTypographyRole.numbers: typography.numbers,
    };
    final images = <String, String>{};
    for (final asset in [resolved.titleHero, resolved.titleLogo, resolved.menuBackground]) {
      if (asset == null) continue;
      final uri = adapter?.resolvedAsset(asset.assetId)?.resolvedUri;
      if (uri?.scheme == 'file') images[asset.assetId] = uri!.toString();
    }
    return _presentationCache = {
      'profile': profile == null ? null : jsonDecode(jsonEncode(profile.toJson())),
      'author': resolved.metadata.author,
      'description': resolved.metadata.description,
      'orientation': resolved.orientation.name,
      'images': images,
      'titleHero': resolved.titleHero?.assetId,
      'titleLogo': resolved.titleLogo?.assetId,
      'menuBackground': resolved.menuBackground?.assetId,
      'reducedMotion': owner._reducedMotion,
      'dark': dark,
      'locale': locale,
      'fonts': {
        for (final entry in resolved.typography?.roles.entries ?? <MapEntry<ProjectTypographyRole, RuntimeLoadedFontRole>>[])
          entry.key.name: {
            'family': entry.value.registeredFamily,
            'fallback': entry.value.fallbackFamilies,
            'uri': fontProfiles[entry.key]?.fontPath == null ? null : adapter?.resolvedAsset(fontProfiles[entry.key]!.fontPath!)?.resolvedUri.toString(),
          },
      },
    };
  }

  @override
  Future<void> execute(String kind, Map<String, Object?> payload, AveluneGameplayCompanionSnapshot expected) async {
    if (!_current) throw PlatformException(code: 'staleSession');
    if (kind == 'battle') {
      _executeBattle(payload, expected);
      return;
    }
    final projected = expected.player;
    if (expected.mode != AveluneGameplayCompanionMode.menu || projected == null || projected.revision != coordinator.snapshot.revision || coordinator.snapshot.worldService != null || owner._mountedGame?.battleExitTransitionVisible.value == true) {
      throw PlatformException(code: 'staleRevision');
    }
    switch (kind) {
      case 'pause':
        await _ensurePause();
      case 'back':
        if (payload['snapshotRevision'] != projected.revision) throw PlatformException(code: 'staleRevision');
        if (coordinator.snapshot.phase == RuntimePlayerPhase.playing) return;
        _requireAccepted(await coordinator.requestBack(snapshotRevision: projected.revision));
      case 'player':
        final command = RuntimeCompanionPresentationCodec.decodePlayerCommand(Map<String, dynamic>.from(payload));
        if (command.snapshotRevision != projected.revision || !projected.isActionEnabled(command.action)) {
          throw PlatformException(code: 'unavailable', message: projected.unavailableReasonFor(command.action));
        }
        if (coordinator.snapshot.phase == RuntimePlayerPhase.playing && command.action == RuntimePlayerAction.resume) return;
        await _ensurePause();
        _checkPaused();
        _requireAccepted(await owner._companionCommandController.dispatch(RuntimePlayerCommand(
          action: command.action, snapshotRevision: coordinator.snapshot.revision, payload: command.payload,
        )));
      case 'favorite':
        if (payload['snapshotRevision'] != projected.revision || payload['itemId'] is! String || payload['favorite'] is! bool) {
          throw PlatformException(code: 'invalidIntent');
        }
        await _ensurePause();
        _checkPaused();
        _requireAccepted(await coordinator.setBagItemFavorite(
          itemId: payload['itemId'] as String, favorite: payload['favorite'] as bool, snapshotRevision: coordinator.snapshot.revision,
        ));
      case 'worldService':
        throw PlatformException(code: 'unavailable', message: 'Ce service se contrôle sur l’écran principal.');
      case 'controlProfile':
        await _ensurePause();
        _checkPaused();
        await owner._updateControlProfile(player_ui.PlayerControlProfile.fromJson(payload));
      default:
        throw PlatformException(code: 'invalidIntent');
    }
  }

  Future<void> _ensurePause() async {
    if (!_current) throw PlatformException(code: 'staleSession');
    if (owner._mountedGame?.battleExitTransitionVisible.value == true) throw PlatformException(code: 'unavailable');
    if (coordinator.snapshot.phase == RuntimePlayerPhase.paused) return;
    if (coordinator.snapshot.phase != RuntimePlayerPhase.playing) throw PlatformException(code: 'unavailable');
    _requireAccepted(await owner._companionCommandController.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu, snapshotRevision: coordinator.snapshot.revision,
    )));
    _checkPaused();
  }

  void _checkPaused() {
    if (!_current) throw PlatformException(code: 'staleSession');
    if (coordinator.snapshot.phase != RuntimePlayerPhase.paused) throw PlatformException(code: 'unavailable');
    final game = owner._mountedGame;
    if (game == null || game.battleExitTransitionVisible.value || game.battleCommandOverlayListenable.value != null || game.inputAuthorityListenable.value.context == RuntimeInputContext.battle ||
        game.inputAuthorityListenable.value.context == RuntimeInputContext.transition) {
      throw PlatformException(code: 'unavailable');
    }
  }

  void _executeBattle(Map<String, Object?> payload, AveluneGameplayCompanionSnapshot expected) {
    final game = owner._mountedGame;
    final snapshot = game?.battleCommandOverlayListenable.value;
    if (expected.mode != AveluneGameplayCompanionMode.battle || snapshot == null || expected.battle == null ||
        snapshot.revision != expected.battle!.revision || payload['snapshotRevision'] != snapshot.revision || payload['expectedMode'] != snapshot.mode.name) {
      throw PlatformException(code: 'staleMode');
    }
    final command = switch (payload['action']) {
      'back' => BattleBackCommand(snapshotRevision: snapshot.revision, expectedMode: snapshot.mode),
      'select' => BattleSelectEntryCommand(snapshotRevision: snapshot.revision, expectedMode: snapshot.mode, entryIndex: payload['entryIndex'] as int),
      _ => throw PlatformException(code: 'invalidIntent'),
    };
    if (!validateBattlePresentationCommand(snapshot, command).accepted || !game!.dispatchBattlePresentationCommand(command)) {
      throw PlatformException(code: 'unavailable');
    }
  }

  void _requireAccepted(RuntimePlayerCommandResult result) {
    if (result.status != RuntimePlayerCommandStatus.accepted) throw PlatformException(code: result.status.name, message: result.safeMessage);
  }
}

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
    this.splashWordmark,
    this.splashAudioDriver,
    this.diagnosticLogFile,
    this.controller,
    this.companionOwner,
    this.onCompanionInput,
    this.beforePlayerStops,
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
  final ImageProvider? splashWordmark;
  final FlameCinematicAudioDriver? splashAudioDriver;
  final File? diagnosticLogFile;
  final HubInstalledGamePlayerController? controller;
  final AveluneGameplayCompanionOwner? companionOwner;
  final bool Function(RuntimeInputEvent)? onCompanionInput;
  final Future<void> Function()? beforePlayerStops;

  @override
  State<HubInstalledGamePlayer> createState() => _HubInstalledGamePlayerState();
}

class _HubInstalledGamePlayerState extends State<HubInstalledGamePlayer>
    with WidgetsBindingObserver {
  static const _splashMovieRevealDuration = Duration(milliseconds: 2600);

  final _gameplayViewportKey = GlobalKey();
  RuntimeStartupBootstrapCoordinator<HubRuntimeStartupPreparedData>?
  _startupCoordinator;
  HubRuntimeStartupAdapter? _startupAdapter;
  RuntimeStartupSnapshot? _startupSnapshot;
  final player_ui.PlayerRuntimeStartupShellController _startupShellController =
      player_ui.PlayerRuntimeStartupShellController();
  player_ui.RuntimePlayerCoordinatorViewController? _viewController;
  GameSessionController? _sessions;
  PlayableMapGame? _mountedGame;
  final Completer<void> _mountWait = Completer<void>();
  Locale? _playerLocale;
  RuntimeAudioMixer? _audioMixer;
  late final RuntimeSplashJingleController _splashJingle;
  late final Future<HubPreferencesRead> _preferencesRead;
  late final Future<void> _splashSequenceStarted;
  VideoPlayerController? _splashMovie;
  final Completer<void> _splashImagesReady = Completer<void>();
  Completer<void>? _splashResume;
  bool _splashImagesRequested = false;
  bool _splashAnimationReady = false;
  ControlProfileRepositoryInterface? _controlProfileStore;
  player_ui.PlayerControlProfile _controlProfile =
      player_ui.PlayerControlProfile.standard;
  StreamSubscription<RuntimeStartupSnapshot>? _startupSubscription;
  bool _lifecycleActive = true;
  bool _reducedMotion = false;
  HubInstalledPresentationRuntime? _presentationRuntime;
  Future<void>? _shutdown;
  bool _closing = false;
  final _bootstrapLifetime = HubRuntimeStartupLifetime();
  final _companionCommandController = player_ui.RuntimePlayerSessionCommandController();
  _HubGameplayCompanionPort? _companionPort;
  StreamSubscription<RuntimePlayerSnapshot>? _companionSubscription;

  bool get _useSplashMovie =>
      Platform.isIOS &&
      widget.hostBranding.displayName == 'AVELUNE' &&
      widget.splashAudioDriver == null;

  @override
  void initState() {
    super.initState();
    widget.controller?._stop = _stop;
    widget.companionOwner?.addListener(_handleCompanionChanged);
    WidgetsBinding.instance.addObserver(this);
    final mixer = RuntimeAudioMixer();
    _audioMixer = mixer;
    _splashJingle = RuntimeSplashJingleController(
      mixer: mixer,
      driver: widget.splashAudioDriver,
      enabled: !_useSplashMovie,
    );
    _preferencesRead = Future<HubPreferencesRead>.sync(
      widget.preferencesRepository.load,
    );
    _splashSequenceStarted = _startSplashSequence(mixer);
    _startRuntimeBootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_useSplashMovie) return;
    _precacheSplashImages();
  }

  void _precacheSplashImages() {
    if (_splashImagesRequested) return;
    _splashImagesRequested = true;
    final images = <ImageProvider>[
      if (widget.splashLogo != null) widget.splashLogo!,
      if (widget.splashWordmark != null) widget.splashWordmark!,
      if (widget.hostBranding.displayName == 'AVELUNE') ...<ImageProvider>[
        const AssetImage(
          'assets/splash/eclipse_orbit_soft.png',
          package: 'map_player_ui',
        ),
        const AssetImage(
          'assets/splash/eclipse_orbit_sharp.png',
          package: 'map_player_ui',
        ),
        const AssetImage(
          'assets/splash/eclipse_disc.png',
          package: 'map_player_ui',
        ),
      ],
    ];
    unawaited(
      Future.wait<void>([
        for (final image in images)
          precacheImage(image, context, onError: (_, _) {}),
      ]).then(
        (_) => _splashImagesReady.complete(),
        onError: (Object _, StackTrace _) => _splashImagesReady.complete(),
      ),
    );
  }

  Future<void> _startSplashSequence(RuntimeAudioMixer mixer) async {
    try {
      final preferences = (await _preferencesRead).preferences;
      if (_closing) return;
      await mixer.transitionTo(
        RuntimeAudioMix(
          masterVolume: preferences.masterVolume,
          musicVolume: preferences.musicVolume,
          effectsVolume: preferences.effectsVolume,
        ),
      );
      if (!_lifecycleActive) {
        await (_splashResume ??= Completer<void>()).future;
      }
      if (!mounted || _closing) return;
      if (_useSplashMovie) {
        final movie = VideoPlayerController.asset(
          'assets/avelune/splash/avelune_eclipse.mp4',
          package: 'pokemap_hub',
        );
        try {
          await movie.initialize();
          await movie.setVolume(
            mixer.mix.volumeFor(RuntimeAudioRoute.splash, sourceVolume: .6),
          );
          await movie.setLooping(false);
          if (!mounted || _closing) {
            await movie.dispose();
            return;
          }
          _splashMovie = movie;
          setState(() {});
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || _closing) return;
          await movie.play();
          if (mounted && !_closing) {
            setState(() => _splashAnimationReady = true);
          }
          return;
        } on Object {
          if (identical(_splashMovie, movie)) {
            _splashMovie = null;
            if (mounted) setState(() {});
          }
          if (!mounted || _closing) return;
          await movie.dispose();
          _precacheSplashImages();
        }
      }
      await _splashImagesReady.future;
      if (!mounted) return;
      _splashJingle.enabled = true;
      await _splashJingle.playOnce();
    } on Object {
      if (!mounted) return;
    }
    if (mounted) setState(() => _splashAnimationReady = true);
  }

  void _startRuntimeBootstrap() {
    final startup =
        RuntimeStartupBootstrapCoordinator<HubRuntimeStartupPreparedData>(
          bootstrapPort: HubRuntimeStartupBootstrap(
            lifetime: _bootstrapLifetime,
            supportRoot: widget.supportRoot,
            saveRepositoryFactory: widget.saveRepositoryFactory,
            preferencesRepository: widget.preferencesRepository,
            preferencesRead: _preferencesRead,
            startupWorkGate:
                _useSplashMovie
                    ? _splashSequenceStarted.then(
                      (_) => Future<void>.delayed(_splashMovieRevealDuration),
                    )
                    : null,
            audioMixer: _audioMixer,
            splashJingle: _splashJingle,
            controlProfileRepository: widget.controlProfileRepository,
            launchResolver: widget.launchResolver,
            game: widget.game,
            onHubRequested: widget.onHubRequested,
            mountGame: _mountGame,
            unmountGame: _unmountGame,
            stopIntroPlayback: _startupShellController.stopIntroPlayback,
            defaultProfileDisplayNameForLocale:
                (locale) =>
                    HubInstalledPlayerStrings.forLocale(locale).defaultProfile,
            diagnosticLogFile: widget.diagnosticLogFile,
          ),
          hostBranding: widget.hostBranding,
          splashSequenceStarted: _splashSequenceStarted,
          onPrepared: _acceptRuntimeBootstrap,
        );
    _startupCoordinator = startup;
    _startupSnapshot = startup.snapshot;
    _startupSubscription = startup.snapshots.listen(_handleStartupSnapshot);
    startup.start();
  }

  void _acceptRuntimeBootstrap(HubRuntimeStartupPreparedData prepared) {
    if (!mounted || _closing) return;
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
      _presentationRuntime = prepared.presentationRuntime;
      _viewController = player_ui.RuntimePlayerCoordinatorViewController(
        prepared.coordinator,
      );
    });
    final companion = widget.companionOwner;
    if (companion != null) {
      final port = _HubGameplayCompanionPort(this, prepared.coordinator);
      _companionPort = port;
      companion.bind(port);
      _companionSubscription = prepared.coordinator.snapshots.listen((_) => companion.invalidate());
    }
  }

  void _handleStartupSnapshot(RuntimeStartupSnapshot snapshot) {
    if (!mounted || _closing) return;
    if (snapshot.phase != RuntimeStartupPhase.splash &&
        snapshot.phase != RuntimeStartupPhase.preparing) {
      final movie = _splashMovie;
      if (movie != null) unawaited(movie.pause());
    }
    setState(() => _startupSnapshot = snapshot);
    widget.companionOwner?.invalidate();
  }

  Future<void> _mountGame(PlayableMapGame game) async {
    if (!mounted || _closing) {
      throw StateError('The player surface closed before the game mounted.');
    }
    game.setDialogueFlutterOverlayPreferred(true);
    game.setBattleFlutterCommandOverlayPreferred(true);
    game.inputAuthorityListenable.addListener(_invalidateCompanion);
    game.battleCommandOverlayListenable.addListener(_invalidateCompanion);
    game.battleExitTransitionVisible.addListener(_invalidateCompanion);
    setState(() => _mountedGame = game);
    _invalidateCompanion();
    await Future.any(<Future<void>>[game.loaded, _mountWait.future]);
  }

  void _releaseMountWait() {
    if (!_mountWait.isCompleted) {
      _mountWait.complete();
    }
  }

  Future<void> _unmountGame(PlayableMapGame game) async {
    if (!mounted || !identical(_mountedGame, game)) return;
    game.inputAuthorityListenable.removeListener(_invalidateCompanion);
    game.battleCommandOverlayListenable.removeListener(_invalidateCompanion);
    game.battleExitTransitionVisible.removeListener(_invalidateCompanion);
    setState(() => _mountedGame = null);
    _invalidateCompanion();
  }

  void _invalidateCompanion() => widget.companionOwner?.invalidate();

  void _handleCompanionChanged() {
    if (mounted && !_closing) setState(() {});
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
    if (_closing) return;
    final startup = _startupCoordinator;
    if (state == AppLifecycleState.resumed) {
      final splashResume = _splashResume;
      _splashResume = null;
      if (splashResume != null && !splashResume.isCompleted) {
        splashResume.complete();
      }
      if (!_lifecycleActive && mounted) {
        setState(() => _lifecycleActive = true);
      }
      if (startup != null) {
        unawaited(startup.resumeFromLifecycle());
      }
      unawaited(_splashJingle.resumeFromLifecycle());
      if (_splashMovie != null &&
          (_startupSnapshot?.phase == RuntimeStartupPhase.splash ||
              _startupSnapshot?.phase == RuntimeStartupPhase.preparing)) {
        unawaited(_splashMovie!.play());
      }
      unawaited(_presentationRuntime?.controller.resumeAfterLifecycle());
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
      unawaited(_splashJingle.pauseForLifecycle());
      final movie = _splashMovie;
      if (movie != null) unawaited(movie.pause());
      unawaited(_presentationRuntime?.controller.pauseForLifecycle());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_closing) return const SizedBox.expand();
    final viewController = _viewController;
    final startup = _startupCoordinator!;
    final effectiveSnapshot = _startupSnapshot ?? startup.snapshot;
    final visiblePhase =
        effectiveSnapshot.phase == RuntimeStartupPhase.lifecyclePaused
            ? effectiveSnapshot.suspendedPhase ?? RuntimeStartupPhase.splash
            : effectiveSnapshot.phase;
    final resolvedPresentation = effectiveSnapshot.presentation;
    final playerPresentation =
        resolvedPresentation == null
            ? const player_ui.RuntimePlayerPresentation(
              title: player_ui.RuntimePlayerTitlePresentation(author: ''),
            )
            : player_ui.RuntimePlayerPresentation.fromRuntime(
              resolvedPresentation,
              imageForAsset: _startupImage,
            );
    // La personnalisation part d'un thème joueur VIERGE, jamais de
    // `Theme.of(context)` : à ce niveau, c'est le thème Avelune, et
    // `applyAveluneTheme` y écrase `colorScheme.primary` avec l'accent du
    // lanceur. Comme `applyTo` n'empile que typographie, palettes et profils
    // sans jamais toucher au `colorScheme`, un jeu qui n'authore aucune
    // couleur héritait de la marque du lanceur au lieu de la sienne — visible
    // sur tout widget qui laisse `style: null`. La luminosité résolue par
    // l'app est conservée, elle vient bien d'une préférence du joueur.
    final playerBaseTheme =
        Theme.of(context).brightness == Brightness.dark
            ? player_ui.PokeMapPlayerTheme.dark(reducedMotion: _reducedMotion)
            : player_ui.PokeMapPlayerTheme.light(reducedMotion: _reducedMotion);
    final personalizedTheme = playerPresentation.applyTo(playerBaseTheme);
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
      volume: 1,
    );
    final player = Theme(
      data: startupTheme,
      child: player_ui.PlayerRuntimeStartupShell(
        key: const ValueKey<String>('pokemap-runtime-startup-shell'),
        controller: _startupShellController,
        branding: widget.hostBranding,
        snapshot: effectiveSnapshot,
        titlePresentation: playerPresentation.title,
        introSource: introSource,
        introPoster: _startupImage(resolvedPresentation?.introPoster),
        audioMixer: _audioMixer,
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
        splashWordmark: widget.splashWordmark,
        splashCinematic:
            _splashMovie == null
                ? null
                : FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _splashMovie!.value.size.width,
                    height: _splashMovie!.value.size.height,
                    child: VideoPlayer(_splashMovie!),
                  ),
                ),
        reducedMotion: _reducedMotion,
        splashAnimationReady: _splashAnimationReady,
        onPresentationOrientationChanged: (nextOrientation) {
          unawaited(startup.updatePresentationOrientation(nextOrientation));
        },
        onStartupCommand: (command) {
          unawaited(startup.dispatch(command));
        },
        onPlayerCommand:
            (command) => startup.dispatchPlayerCommand(
              startupSnapshotRevision: effectiveSnapshot.revision,
              command: command,
            ),
        onIntroPlaybackCompleted: (revision) {
          unawaited(startup.introPlaybackCompleted(snapshotRevision: revision));
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
    final locale = effectiveSnapshot.playerSnapshot?.preferences?.locale;
    final playerLocale =
        locale == null
            ? _playerLocale ??
                Locale(
                  widget.game.defaultLocale
                      .split(RegExp('[-_]'))
                      .first
                      .toLowerCase(),
                )
            : Locale(locale.split(RegExp('[-_]')).first);
    return Localizations.override(
      context: context,
      locale: playerLocale,
      child: player,
    );
  }

  Widget _buildSessionView(
    player_ui.RuntimePlayerCoordinatorViewController viewController,
    player_ui.RuntimePlayerPresentation presentation,
  ) {
    final companion = widget.companionOwner?.value;
    final snapshot = viewController.snapshot;
    final battle = _mountedGame?.battleCommandOverlayListenable.value;
    final delegatesCompanion = companion != null && companion.companionAttached && snapshot.worldService == null && _mountedGame?.battleExitTransitionVisible.value != true && (
      companion.mode == AveluneGameplayCompanionMode.menu && companion.player != null && companion.player!.revision == snapshot.revision ||
      companion.mode == AveluneGameplayCompanionMode.battle && companion.battle != null && battle != null && companion.battle!.revision == battle.revision
    );
    final presentationRuntime = _presentationRuntime;
    if (presentationRuntime != null) {
      final size = MediaQuery.sizeOf(context);
      final orientation =
          size.height > size.width
              ? player_ui.PresentationFrameOrientation.portrait
              : player_ui.PresentationFrameOrientation.landscape;
      if (presentationRuntime.controller.orientation != orientation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            presentationRuntime.controller.setOrientation(orientation);
          }
        });
      }
    }
    return player_ui.PokeMapPlayerSessionView(
      key: const ValueKey<String>('pokemap-runtime-player-view'),
      controller: viewController,
      commandController: _companionCommandController,
      companionMenusAttached: delegatesCompanion,
      onCompanionInput: widget.onCompanionInput,
      loadingLogo: widget.splashLogo,
      loadingWordmark: widget.splashWordmark,
      titlePresentation: presentation.title,
      pauseMenuLabels: presentation.pauseMenuLabels,
      pausePresentation: presentation.pausePresentation,
      gameplayInputRoute: _sessions?.handleInput,
      gameplayViewportKey: _gameplayViewportKey,
      gameplayInputAuthority: _mountedGame?.inputAuthorityListenable,
      menuInteractionBlocked: _mountedGame?.battleExitTransitionVisible,
      overworldInteractions: _mountedGame?.overworldInteractions,
      hitTestOverworldInteraction: _mountedGame?.hitTestOverworldInteraction,
      onOverworldInteraction: _sessions?.dispatchOverworldInteraction,
      dialoguePresentation: _mountedGame?.dialoguePresentationListenable,
      onDialogueCommand: _mountedGame?.dispatchDialoguePresentationCommand,
      battlePresentation: _mountedGame?.battleCommandOverlayListenable,
      onBattleCommand: _mountedGame?.dispatchBattlePresentationCommand,
      controlProfile: _controlProfile,
      onControlProfileChanged: _updateControlProfile,
      presentationFrame: presentationRuntime?.controller,
      presentationContentPort: presentationRuntime?.controller,
      onPresentationSkip:
          presentationRuntime == null
              ? null
              : () async {
                await presentationRuntime.controller.skipActive();
              },
      gameSceneBuilder: (context) {
        final game = _mountedGame;
        if (game == null) {
          return const SizedBox.expand(
            key: ValueKey<String>('runtime-game-awaiting-mount'),
          );
        }
        // Recette du 2026-08-24 : la scène de combat gère la safe area dans
        // sa géométrie (le HUD passait sous la notch), mais Flame ne voit pas
        // MediaQuery. Chaque build — donc chaque rotation — pousse les
        // insets réels au jeu.
        game.setViewSafeAreaPadding(MediaQuery.viewPaddingOf(context));
        return SizedBox.expand(
          key: _gameplayViewportKey,
          child: GameWidget(
            key: ObjectKey(game),
            game: game,
            autofocus: false,
            errorBuilder: (context, error) {
              _releaseMountWait();
              throw error;
            },
          ),
        );
      },
    );
  }

  Future<void> _updateControlProfile(
    player_ui.PlayerControlProfile profile,
  ) async {
    if (profile == _controlProfile) return;
    final store = _controlProfileStore;
    if (store == null) {
      throw StateError('Control profile storage is unavailable.');
    }
    await store.save(profile);
    if (mounted) setState(() => _controlProfile = profile);
  }

  Future<void> _stop() => _shutdown ??= _stopOwnedResources();

  Future<void> _stopOwnedResources() async {
    _closing = true;
    final preparationClosed = _bootstrapLifetime.close();
    await widget.beforePlayerStops?.call();
    widget.companionOwner?.removeListener(_handleCompanionChanged);
    final port = _companionPort;
    if (port != null) widget.companionOwner?.unbind(port);
    _companionPort = null;
    final companionSubscription = _companionSubscription;
    _companionSubscription = null;
    _mountedGame?.inputAuthorityListenable.removeListener(_invalidateCompanion);
    _mountedGame?.battleCommandOverlayListenable.removeListener(_invalidateCompanion);
    _mountedGame?.battleExitTransitionVisible.removeListener(_invalidateCompanion);
    final splashResume = _splashResume;
    if (splashResume != null && !splashResume.isCompleted) {
      splashResume.complete();
    }
    _releaseMountWait();
    WidgetsBinding.instance.removeObserver(this);
    final startupCoordinator = _startupCoordinator;
    _startupCoordinator = null;
    _startupSnapshot = null;
    _viewController = null;
    _sessions = null;
    _audioMixer = null;
    final presentationRuntime = _presentationRuntime;
    _presentationRuntime = null;
    final startupSubscription = _startupSubscription;
    _startupSubscription = null;
    final movie = _splashMovie;
    _splashMovie = null;
    await Future.wait<void>([
      preparationClosed,
      if (companionSubscription != null) companionSubscription.cancel(),
      if (presentationRuntime != null) presentationRuntime.close(),
      if (startupSubscription != null) startupSubscription.cancel(),
      if (startupCoordinator != null) startupCoordinator.dispose(),
      _splashJingle.dispose(),
      if (movie != null) movie.dispose(),
    ]);
  }

  @override
  void didUpdateWidget(HubInstalledGamePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._stop == _stop) {
        oldWidget.controller?._stop = null;
      }
      widget.controller?._stop = _stop;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._stop == _stop) {
      widget.controller?._stop = null;
    }
    unawaited(_stop());
    super.dispose();
  }
}
