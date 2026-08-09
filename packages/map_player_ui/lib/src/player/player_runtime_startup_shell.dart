import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_intro_video_player.dart';
import 'player_intro_video_surface.dart';
import 'player_new_game_identity.dart';
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
    this.sessionBuilder,
  }) : assert(
          splashAnimationProgress == null ||
              (splashAnimationProgress >= 0 && splashAnimationProgress <= 1),
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
  final Widget Function(
    BuildContext context,
    RuntimePlayerSnapshot? playerSnapshot,
  )? sessionBuilder;

  @override
  State<PlayerRuntimeStartupShell> createState() =>
      _PlayerRuntimeStartupShellState();
}

class _PlayerRuntimeStartupShellState extends State<PlayerRuntimeStartupShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splashAnimation;
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
    if (widget.reducedMotion) {
      _splashAnimation.value = 1;
    } else {
      _splashAnimation.forward();
    }
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
    if (!oldWidget.reducedMotion && widget.reducedMotion) {
      _splashAnimation.value = 1;
    }
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
    return RuntimePlayerActions(
      onBack: _handleBack,
      onMenu: () => _handleInput(
        const PlayerInputCommand.press(
          PlayerInputAction.menu,
          source: PlayerInputSource.keyboard,
        ),
      ),
      onInputSourceChanged: _focusController.noteInputSource,
      child: IgnorePointer(ignoring: !_active, child: child),
    );
  }

  Widget _buildSplash() => AnimatedBuilder(
        animation: _splashAnimation,
        builder: (context, _) => PlayerRuntimeSplashSurface(
          branding: widget.branding,
          progress: widget.snapshot.progress,
          animationProgress:
              widget.splashAnimationProgress ?? _splashAnimation.value,
          logo: widget.splashLogo,
          reducedMotion: widget.reducedMotion,
        ),
      );

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
      onStart: () => _dispatchStartup(RuntimeStartupAction.pressStart),
      onReplayIntro: widget.snapshot.canReplayIntro
          ? () => _dispatchStartup(RuntimeStartupAction.replayIntro)
          : null,
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
    return PlayerTitleScreen(
      data: PlayerTitleViewData(
        gameTitle: player.gameTitle,
        author: widget.titlePresentation.author,
        description: widget.titlePresentation.description,
        background: widget.titlePresentation.background,
        backgroundContent: _titleMotion(
          source: widget.titleMenuSource,
          poster: widget.titleMenuPoster,
        ),
        logo: widget.titlePresentation.logo,
        accentColor: widget.titlePresentation.accentColor,
        layoutVariant: PlayerTitleLayoutVariant.runtimeStartup,
        actions: actions,
        initialSelection: initial,
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
    Object? payload = widget.payloadForAction?.call(
      RuntimePlayerAction.newGame,
    );
    final identityPresentation = widget.titlePresentation.newGameIdentity;
    if (identityPresentation != null && payload is RuntimePlayerLoadSlot) {
      final identity = await showDialog<GameSessionPlayerIdentity>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PlayerNewGameIdentityDialog(
          presentation: identityPresentation,
        ),
      );
      if (identity == null || !mounted) return;
      payload = RuntimePlayerNewGameSetup(slot: payload, identity: identity);
    }
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
        if (widget.snapshot.canSkipSplash) {
          _dispatchStartup(RuntimeStartupAction.skipSplash);
        }
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
    final enabled = projection.actions
        .where((availability) => availability.isEnabled)
        .toList(growable: false);
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
    final player = widget.snapshot.playerSnapshot;
    if (player != null && _isTitleOptions(player)) {
      _focusController.select('title.openOptions');
      _dispatchPlayer(RuntimePlayerAction.returnToTitle, player);
    }
  }

  PlayerTitleMenuAction _titleAction(RuntimePlayerAction action) =>
      switch (action) {
        RuntimePlayerAction.continueGame => PlayerTitleMenuAction.continueGame,
        RuntimePlayerAction.newGame => PlayerTitleMenuAction.newGame,
        RuntimePlayerAction.openOptions => PlayerTitleMenuAction.options,
        _ => throw ArgumentError.value(action, 'action'),
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
    _focusController.dispose();
    super.dispose();
  }
}
