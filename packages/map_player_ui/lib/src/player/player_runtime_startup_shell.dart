import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_intro_video_player.dart';
import 'player_intro_video_surface.dart';
import 'player_runtime_splash_surface.dart';
import 'player_startup_media.dart';
import 'player_startup_strings.dart';
import 'player_title_options_surface.dart';
import 'player_title_motion.dart';
import 'player_title_prompt_surface.dart';
import 'player_title_screen.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_focus_controller.dart';

typedef PlayerStartupIntroFailure = void Function(
  int snapshotRevision,
  String reason,
);

/// Imperative bridge for controller/gamepad commands already normalized by the
/// runtime input router. Keyboard and touch remain regular Flutter input.
final class PlayerRuntimeStartupShellController {
  bool Function(PlayerInputCommand command)? _handler;
  Future<void> Function()? _stopIntroPlayback;

  bool handle(PlayerInputCommand command) => _handler?.call(command) ?? false;

  /// Awaits decoder silence without owning any startup navigation decision.
  Future<void> stopIntroPlayback() =>
      _stopIntroPlayback?.call() ?? Future<void>.value();

  void _attach(
    bool Function(PlayerInputCommand command) handler,
    Future<void> Function() stopIntroPlayback,
  ) {
    _handler = handler;
    _stopIntroPlayback = stopIntroPlayback;
  }

  void _detach(
    bool Function(PlayerInputCommand command) handler,
    Future<void> Function() stopIntroPlayback,
  ) {
    if (_handler == handler) _handler = null;
    if (_stopIntroPlayback == stopIntroPlayback) _stopIntroPlayback = null;
  }
}

/// Host-independent composition of the FG-017 startup states.
class PlayerRuntimeStartupShell extends StatefulWidget {
  const PlayerRuntimeStartupShell({
    super.key,
    required this.branding,
    required this.snapshot,
    required this.titlePresentation,
    required this.onStartupCommand,
    required this.onPlayerCommand,
    required this.onIntroPlaybackCompleted,
    required this.onIntroPlaybackFailed,
    this.controller,
    this.introSource,
    this.introPoster,
    this.splashLogo,
    this.introDriverFactory,
    this.titlePromptSource,
    this.titlePromptPoster,
    this.titleMenuSource,
    this.titleMenuPoster,
    this.titleMotionDriverFactory,
    this.onPresentationOrientationChanged,
    this.payloadForAction,
    this.onPreferencesChanged,
    this.reducedMotion = false,
    this.splashAnimationProgress,
    this.splashLoadingProgress,
    this.sessionBuilder,
  })  : assert(
          splashAnimationProgress == null ||
              (splashAnimationProgress >= 0 && splashAnimationProgress <= 1),
        ),
        assert(
          splashLoadingProgress == null ||
              (splashLoadingProgress >= 0 && splashLoadingProgress <= 1),
        );

  final RuntimeHostSplashBranding branding;
  final RuntimeStartupSnapshot snapshot;
  final RuntimePlayerTitlePresentation titlePresentation;
  final ValueChanged<RuntimeStartupCommand> onStartupCommand;
  final ValueChanged<RuntimePlayerCommand> onPlayerCommand;
  final ValueChanged<int> onIntroPlaybackCompleted;
  final PlayerStartupIntroFailure onIntroPlaybackFailed;
  final PlayerRuntimeStartupShellController? controller;
  final PlayerIntroVideoSource? introSource;
  final ImageProvider? introPoster;
  final ImageProvider? splashLogo;
  final PlayerIntroPlaybackFactory? introDriverFactory;
  final PlayerIntroVideoSource? titlePromptSource;
  final ImageProvider? titlePromptPoster;
  final PlayerIntroVideoSource? titleMenuSource;
  final ImageProvider? titleMenuPoster;
  final PlayerIntroPlaybackFactory? titleMotionDriverFactory;
  final ValueChanged<RuntimePresentationOrientation>?
      onPresentationOrientationChanged;
  final Object? Function(RuntimePlayerAction action)? payloadForAction;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;
  final bool reducedMotion;
  final double? splashAnimationProgress;
  final double? splashLoadingProgress;
  final Widget Function(
    BuildContext context,
    RuntimePlayerSnapshot? playerSnapshot,
  )? sessionBuilder;

  @override
  State<PlayerRuntimeStartupShell> createState() =>
      _PlayerRuntimeStartupShellState();
}

class _PlayerRuntimeStartupShellState extends State<PlayerRuntimeStartupShell>
    with TickerProviderStateMixin {
  late final AnimationController _splashAnimation;
  late final AnimationController _splashAmbientAnimation;
  late final AnimationController _splashFinishAnimation;
  late final RuntimePlayerFocusController _focusController;
  late final PlayerIntroVideoPlayerController _introPlaybackController;
  int? _consumedStartupRevision;
  RuntimePresentationOrientation? _reportedOrientation;

  RuntimeStartupPhase get _visiblePhase =>
      widget.snapshot.phase == RuntimeStartupPhase.lifecyclePaused
          ? widget.snapshot.suspendedPhase ?? RuntimeStartupPhase.splash
          : widget.snapshot.phase;

  bool get _active =>
      widget.snapshot.isLifecycleActive &&
      widget.snapshot.phase != RuntimeStartupPhase.lifecyclePaused;

  @override
  void initState() {
    super.initState();
    _splashAnimation = AnimationController(
      vsync: this,
      duration: widget.branding.minimumDisplayDuration,
    );
    _splashAmbientAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _splashFinishAnimation = AnimationController(
      vsync: this,
      duration: widget.branding.finalCurtainDuration,
    );
    _syncSplashAnimations();
    _focusController = RuntimePlayerFocusController(
      activeInputSource: widget.snapshot.playerSnapshot?.activeInputSource ??
          PlayerInputSource.keyboard,
    );
    _introPlaybackController = PlayerIntroVideoPlayerController();
    widget.controller?._attach(_handleInput, _stopIntroPlayback);
  }

  @override
  void didUpdateWidget(PlayerRuntimeStartupShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(_handleInput, _stopIntroPlayback);
      widget.controller?._attach(_handleInput, _stopIntroPlayback);
    }
    if (oldWidget.snapshot.revision != widget.snapshot.revision) {
      _consumedStartupRevision = null;
    }
    if (oldWidget.branding.minimumDisplayDuration !=
        widget.branding.minimumDisplayDuration) {
      _splashAnimation.duration = widget.branding.minimumDisplayDuration;
    }
    if (oldWidget.branding.finalCurtainDuration !=
        widget.branding.finalCurtainDuration) {
      _splashFinishAnimation.duration = widget.branding.finalCurtainDuration;
    }
    if (oldWidget.reducedMotion && !widget.reducedMotion) {
      _splashAnimation.value = 0;
      _splashAmbientAnimation.value = 0;
    }
    _syncSplashAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final orientation = size.height > size.width
        ? RuntimePresentationOrientation.portrait
        : RuntimePresentationOrientation.landscape;
    if (_reportedOrientation == orientation) return;
    _reportedOrientation = orientation;
    widget.onPresentationOrientationChanged?.call(orientation);
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_visiblePhase) {
      RuntimeStartupPhase.preparing ||
      RuntimeStartupPhase.splash =>
        _buildSplash(),
      RuntimeStartupPhase.intro => _buildIntro(),
      RuntimeStartupPhase.titlePrompt => _buildTitlePrompt(),
      RuntimeStartupPhase.titleMenu => _buildTitleState(),
      RuntimeStartupPhase.recoverableError => _buildError(context),
      RuntimeStartupPhase.launchingSession ||
      RuntimeStartupPhase.completed =>
        _buildSession(context),
      RuntimeStartupPhase.lifecyclePaused => _buildSplash(),
    };
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: RuntimePlayerActions(
        onBack: _handleBack,
        onMenu: () => _handleInput(
          const PlayerInputCommand.press(
            PlayerInputAction.menu,
            source: PlayerInputSource.keyboard,
          ),
        ),
        onInputSourceChanged: _focusController.noteInputSource,
        child: IgnorePointer(ignoring: !_active, child: child),
      ),
    );
  }

  Widget _buildSplash() => AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _splashAnimation,
          _splashAmbientAnimation,
          _splashFinishAnimation,
        ]),
        builder: (context, _) => PlayerRuntimeSplashSurface(
          branding: widget.branding,
          progress: widget.splashLoadingProgress ?? widget.snapshot.progress,
          animationProgress:
              widget.splashAnimationProgress ?? _splashAnimation.value,
          exitProgress: _splashFinishAnimation.value,
          ambientProgress: _splashAmbientAnimation.value,
          loadingLabel: _runtimeStartupLoadingLabel(widget.snapshot),
          logo: widget.splashLogo,
          reducedMotion: widget.reducedMotion,
        ),
      );

  void _syncSplashAnimations() {
    if (widget.reducedMotion) {
      _splashAnimation.stop(canceled: false);
      _splashAnimation.value = kPlayerSplashHoldProgress;
      _splashAmbientAnimation.stop(canceled: false);
      _splashAmbientAnimation.value = 0;
      _splashFinishAnimation.stop(canceled: false);
      _splashFinishAnimation.value = 0;
      return;
    }
    final splashVisible = _visiblePhase == RuntimeStartupPhase.splash ||
        _visiblePhase == RuntimeStartupPhase.preparing;
    if (!splashVisible || !_active) {
      _splashAnimation.stop(canceled: false);
      _splashAmbientAnimation.stop(canceled: false);
      _splashFinishAnimation.stop(canceled: false);
      return;
    }
    if (!_splashAmbientAnimation.isAnimating) {
      _splashAmbientAnimation.repeat();
    }
    final loadingProgress =
        widget.splashLoadingProgress ?? widget.snapshot.progress;
    final target = loadingProgress >= 1 ? 1.0 : kPlayerSplashHoldProgress;
    if (loadingProgress < 1) {
      _splashFinishAnimation.stop(canceled: false);
      _splashFinishAnimation.value = 0;
    }
    if (_splashAnimation.value < target) {
      final exitingHeldTimeline = target == 1 &&
          _splashAnimation.value >= kPlayerSplashHoldProgress - .0001;
      final remaining = exitingHeldTimeline
          ? widget.branding.exitTransitionDuration.inMicroseconds *
              ((1 - _splashAnimation.value) / (1 - kPlayerSplashHoldProgress))
          : widget.branding.minimumDisplayDuration.inMicroseconds *
              (target - _splashAnimation.value);
      unawaited(
        _splashAnimation
            .animateTo(
          target,
          duration: Duration(microseconds: remaining.round()),
          curve: Curves.linear,
        )
            .then((_) {
          if (mounted) _syncSplashAnimations();
        }),
      );
      return;
    }
    if (target == 1 &&
        widget.snapshot.isMinimumElapsed &&
        _splashFinishAnimation.value < 1 &&
        !_splashFinishAnimation.isAnimating) {
      _splashFinishAnimation.forward();
    }
  }

  Widget _buildIntro() {
    final snapshot = widget.snapshot;
    final source = widget.introSource;
    if (source == null) {
      return PlayerIntroVideoSurface(
        media: widget.introPoster == null
            ? null
            : Image(
                image: widget.introPoster!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
        isPoster: true,
        onSkip: () => _dispatchStartup(RuntimeStartupAction.skipIntro),
        onContinue: () =>
            _dispatchStartup(RuntimeStartupAction.continueFromPoster),
        onReplay: snapshot.canReplayIntro
            ? () => _dispatchStartup(RuntimeStartupAction.replayIntro)
            : null,
      );
    }
    return PlayerIntroVideoPlayer(
      source: source,
      controller: _introPlaybackController,
      poster: widget.introPoster,
      phase: snapshot.introPhase,
      allowReplay: snapshot.canReplayIntro,
      driverFactory: widget.introDriverFactory,
      onPlaybackCompleted: () {
        if (_active && _visiblePhase == RuntimeStartupPhase.intro) {
          widget.onIntroPlaybackCompleted(snapshot.revision);
        }
      },
      onPlaybackFailed: (reason) {
        if (_active && _visiblePhase == RuntimeStartupPhase.intro) {
          widget.onIntroPlaybackFailed(snapshot.revision, reason);
        }
      },
      onSkip: () => _dispatchStartup(RuntimeStartupAction.skipIntro),
      onContinue: () =>
          _dispatchStartup(RuntimeStartupAction.continueFromPoster),
      onReplay: () => _dispatchStartup(RuntimeStartupAction.replayIntro),
    );
  }

  Future<void> _stopIntroPlayback() => _introPlaybackController.stopPlayback();

  Widget _buildTitlePrompt() {
    final player = widget.snapshot.playerSnapshot;
    return PlayerTitlePromptSurface(
      gameTitle: player?.gameTitle ?? widget.branding.displayName,
      background: widget.titlePresentation.background,
      logo: widget.titlePresentation.logo,
      backgroundContent: _titleMotion(
        source: widget.titlePromptSource,
        poster: widget.titlePromptPoster,
      ),
      eyebrow: widget.branding.signature,
      footer: widget.branding.displayName,
      onStart: () => _dispatchStartup(RuntimeStartupAction.pressStart),
    );
  }

  Widget _buildTitleState() {
    final player = widget.snapshot.playerSnapshot;
    if (player == null) return _buildPreparing();
    if (_isTitleOptions(player)) {
      return PlayerTitleOptionsSurface(
        snapshot: player,
        onReturnToTitle: () {
          _focusController.select('title.openOptions');
          _dispatchPlayer(RuntimePlayerAction.returnToTitle, player);
        },
        onPreferencesChanged: (preferences) {
          widget.onPreferencesChanged?.call(preferences);
          _dispatchPlayer(
            RuntimePlayerAction.updatePreferences,
            player,
            payload: preferences,
          );
        },
      );
    }
    final projection =
        const RuntimeTitleMenuPolicy.singleSave().project(player);
    final actions = <PlayerTitleMenuAction, PlayerActionAvailability>{
      for (final availability in projection.actions)
        _titleAction(availability.action): availability.isEnabled
            ? PlayerActionAvailability.enabled
            : PlayerActionAvailability.disabled(
                availability.unavailableReason ??
                    'This action is unavailable for this game.',
              ),
    };
    final initial = projection.initialSelection == null
        ? null
        : _titleAction(projection.initialSelection!);
    final titleActions = widget.titlePresentation.projectActions(actions);
    return PlayerTitleScreen(
      data: PlayerTitleViewData(
        gameTitle: widget.titlePresentation.resolveTitle(player.gameTitle),
        author: widget.titlePresentation.author,
        description: widget.titlePresentation.description,
        background: widget.titlePresentation.background,
        backgroundContent: _titleMotion(
          source: widget.titleMenuSource,
          poster: widget.titleMenuPoster,
        ),
        logo: widget.titlePresentation.logo,
        accentColor: widget.titlePresentation.accentColor,
        layoutVariant: widget.titlePresentation.layoutVariant ==
                PlayerTitleLayoutVariant.cinematic
            ? PlayerTitleLayoutVariant.runtimeStartupCinematic
            : PlayerTitleLayoutVariant.runtimeStartup,
        actions: titleActions,
        actionLabels: widget.titlePresentation.actionLabels,
        actionIcons: widget.titlePresentation.actionIcons,
        initialSelection: titleActions.containsKey(initial) ? initial : null,
        continueSave: player.continueSave,
      ),
      focusController: _focusController,
      onSelected: (action) => _selectTitleAction(action, player),
    );
  }

  Widget? _titleMotion({
    required PlayerIntroVideoSource? source,
    required ImageProvider? poster,
  }) {
    if (source == null && poster == null) return null;
    return PlayerTitleMotion(
      source: source,
      poster: poster,
      driverFactory: widget.titleMotionDriverFactory,
      reducedMotion: widget.reducedMotion,
    );
  }

  Widget _buildPreparing() => Scaffold(
        body: Center(
          child: Semantics(
            liveRegion: true,
            child: Text(PlayerStartupStrings.of(context).preparing),
          ),
        ),
      );

  Widget _buildError(BuildContext context) {
    final strings = PlayerStartupStrings.of(context);
    return Scaffold(
      body: PlayerSurface(
        maxWidth: 560,
        child: PlayerPanel(
          elevated: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: context.playerColors.danger,
              ),
              const SizedBox(height: PlayerSpacing.md),
              Text(
                widget.snapshot.failure?.safeMessage ??
                    strings.startupUnavailable,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PlayerSpacing.lg),
              PlayerActionButton(
                label: strings.retry,
                icon: Icons.refresh_rounded,
                onPressed: widget.snapshot.canRetry
                    ? () => _dispatchStartup(
                          RuntimeStartupAction.retryPreparation,
                        )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) =>
      widget.sessionBuilder?.call(context, widget.snapshot.playerSnapshot) ??
      _buildPreparing();

  bool _isTitleOptions(RuntimePlayerSnapshot player) =>
      player.isActionEnabled(RuntimePlayerAction.returnToTitle) &&
      player.isActionEnabled(RuntimePlayerAction.updatePreferences);

  void _selectTitleAction(
    PlayerTitleMenuAction action,
    RuntimePlayerSnapshot player,
  ) {
    final runtimeAction = _runtimeAction(action);
    _focusController.select(
      'title.${runtimeAction.name}',
      source: PlayerInputSource.touch,
    );
    final projection =
        const RuntimeTitleMenuPolicy.singleSave().project(player);
    if (runtimeAction == RuntimePlayerAction.newGame &&
        projection.requiresNewGameConfirmation) {
      unawaited(_confirmNewGame(player));
      return;
    }
    _dispatchPlayer(runtimeAction, player);
  }

  Future<void> _confirmNewGame(RuntimePlayerSnapshot player) async {
    final strings = PlayerStartupStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.replaceSaveTitle),
        content: Text(strings.replaceSaveBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.begin),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final payload = widget.payloadForAction?.call(
      RuntimePlayerAction.newGame,
    );
    _dispatchPlayer(RuntimePlayerAction.newGame, player, payload: payload);
  }

  void _dispatchStartup(RuntimeStartupAction action) {
    final revision = widget.snapshot.revision;
    if (!_active || _consumedStartupRevision == revision) return;
    _consumedStartupRevision = revision;
    widget.onStartupCommand(
      RuntimeStartupCommand(action: action, snapshotRevision: revision),
    );
  }

  void _dispatchPlayer(
    RuntimePlayerAction action,
    RuntimePlayerSnapshot player, {
    Object? payload,
  }) {
    if (!_active || !player.isActionEnabled(action)) return;
    widget.onPlayerCommand(
      RuntimePlayerCommand(
        action: action,
        snapshotRevision: player.revision,
        payload: payload ?? widget.payloadForAction?.call(action),
      ),
    );
  }

  bool _handleInput(PlayerInputCommand command) {
    if (!_active || !command.isPress) return false;
    if (command.isRepeat &&
        command.action != PlayerInputAction.up &&
        command.action != PlayerInputAction.down) {
      return true;
    }
    _focusController.noteInputSource(command.source);
    final phase = _visiblePhase;
    if (phase == RuntimeStartupPhase.titleMenu) {
      return _handleTitleMenuInput(command);
    }
    if (command.action != PlayerInputAction.confirm &&
        command.action != PlayerInputAction.menu) {
      return false;
    }
    switch (phase) {
      case RuntimeStartupPhase.splash || RuntimeStartupPhase.preparing:
        return true;
      case RuntimeStartupPhase.intro:
        if (widget.snapshot.canContinueFromPoster) {
          _dispatchStartup(RuntimeStartupAction.continueFromPoster);
        } else if (widget.snapshot.canSkipIntro) {
          _dispatchStartup(RuntimeStartupAction.skipIntro);
        }
        return true;
      case RuntimeStartupPhase.titlePrompt:
        _dispatchStartup(RuntimeStartupAction.pressStart);
        return true;
      case RuntimeStartupPhase.recoverableError:
        if (widget.snapshot.canRetry) {
          _dispatchStartup(RuntimeStartupAction.retryPreparation);
        }
        return true;
      case RuntimeStartupPhase.titleMenu ||
            RuntimeStartupPhase.launchingSession ||
            RuntimeStartupPhase.completed ||
            RuntimeStartupPhase.lifecyclePaused:
        return false;
    }
  }

  bool _handleTitleMenuInput(PlayerInputCommand command) {
    final player = widget.snapshot.playerSnapshot;
    if (player == null || _isTitleOptions(player)) return false;
    final projection =
        const RuntimeTitleMenuPolicy.singleSave().project(player);
    final availabilityByAction =
        <RuntimePlayerAction, RuntimePlayerActionAvailability>{
      for (final availability in projection.actions)
        availability.action: availability,
    };
    final authored = widget.titlePresentation.actions;
    final orderedActions = authored == null
        ? projection.actions.map((availability) => availability.action)
        : authored.where((action) => action.visible).map(
            (action) => _runtimeAction(_titleActionFromProject(action.id)));
    final enabled = <RuntimePlayerActionAvailability>[
      for (final action in orderedActions)
        if (availabilityByAction[action] case final availability?)
          if (availability.isEnabled) availability,
    ];
    if (enabled.isEmpty) return false;
    final current = enabled.indexWhere(
      (availability) =>
          'title.${availability.action.name}' ==
          _focusController.logicalSelectionId,
    );
    if (command.action == PlayerInputAction.up ||
        command.action == PlayerInputAction.down) {
      final delta = command.action == PlayerInputAction.up ? -1 : 1;
      final base = current < 0 ? 0 : current;
      final next = (base + delta) % enabled.length;
      _focusController.select(
        'title.${enabled[next].action.name}',
        source: command.source,
        requestFocus: true,
      );
      return true;
    }
    if (command.action == PlayerInputAction.confirm ||
        command.action == PlayerInputAction.menu) {
      final selected = current < 0 ? enabled.first : enabled[current];
      _selectTitleAction(_titleAction(selected.action), player);
      return true;
    }
    return false;
  }

  void _handleBack() {
    if (!_active) return;
    widget.onStartupCommand(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.requestBack,
        snapshotRevision: widget.snapshot.revision,
      ),
    );
  }

  PlayerTitleMenuAction _titleAction(RuntimePlayerAction action) =>
      switch (action) {
        RuntimePlayerAction.continueGame => PlayerTitleMenuAction.continueGame,
        RuntimePlayerAction.newGame => PlayerTitleMenuAction.newGame,
        RuntimePlayerAction.load => PlayerTitleMenuAction.load,
        RuntimePlayerAction.openOptions => PlayerTitleMenuAction.options,
        RuntimePlayerAction.showCredits => PlayerTitleMenuAction.creditsAbout,
        RuntimePlayerAction.returnToHost => PlayerTitleMenuAction.returnToHub,
        _ => throw ArgumentError.value(action, 'action'),
      };

  PlayerTitleMenuAction _titleActionFromProject(ProjectTitleActionId action) =>
      switch (action) {
        ProjectTitleActionId.continueGame => PlayerTitleMenuAction.continueGame,
        ProjectTitleActionId.newGame => PlayerTitleMenuAction.newGame,
        ProjectTitleActionId.load => PlayerTitleMenuAction.load,
        ProjectTitleActionId.options => PlayerTitleMenuAction.options,
        ProjectTitleActionId.creditsAbout => PlayerTitleMenuAction.creditsAbout,
        ProjectTitleActionId.returnToHub => PlayerTitleMenuAction.returnToHub,
      };

  RuntimePlayerAction _runtimeAction(PlayerTitleMenuAction action) =>
      switch (action) {
        PlayerTitleMenuAction.continueGame => RuntimePlayerAction.continueGame,
        PlayerTitleMenuAction.newGame => RuntimePlayerAction.newGame,
        PlayerTitleMenuAction.options => RuntimePlayerAction.openOptions,
        PlayerTitleMenuAction.load => RuntimePlayerAction.load,
        PlayerTitleMenuAction.creditsAbout => RuntimePlayerAction.showCredits,
        PlayerTitleMenuAction.returnToHub => RuntimePlayerAction.returnToHost,
      };

  @override
  void dispose() {
    widget.controller?._detach(_handleInput, _stopIntroPlayback);
    _splashAnimation.dispose();
    _splashAmbientAnimation.dispose();
    _splashFinishAnimation.dispose();
    _focusController.dispose();
    super.dispose();
  }
}

String _runtimeStartupLoadingLabel(RuntimeStartupSnapshot snapshot) {
  if (snapshot.progress >= 1) return 'PRÊT';
  return switch (snapshot.currentStage) {
    RuntimeStartupPreparationStage.manifestAndIdentity =>
      'PRÉPARATION DU VOYAGE',
    RuntimeStartupPreparationStage.playerPreferences => 'PRÉFÉRENCES DU JOUEUR',
    RuntimeStartupPreparationStage.saveDiscovery =>
      'RECHERCHE DE LA SAUVEGARDE',
    RuntimeStartupPreparationStage.initialMap => 'ACCORD DU MONDE',
    RuntimeStartupPreparationStage.presentationProfile =>
      'PROFIL DE PRÉSENTATION',
    RuntimeStartupPreparationStage.splashBranding => 'PRÉPARATION DU SPLASH',
    RuntimeStartupPreparationStage.introAndPoster => 'PRÉPARATION DE LA SCÈNE',
    RuntimeStartupPreparationStage.titleMenuAndMusic => 'MENU ET MUSIQUE',
  };
}
