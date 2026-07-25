import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import '../../player/player_shell_controller.dart';
import '../../player/player_shell_models.dart';

final class HubSaveSelection {
  const HubSaveSelection({
    required this.profileId,
    required this.slotId,
  });

  final String profileId;
  final String slotId;
}

typedef HubSaveSelectionRequest = Future<HubSaveSelection?> Function();

final class HubPlayerSettingsProjection {
  const HubPlayerSettingsProjection({
    required this.accessibility,
    required this.masterVolume,
    required this.musicVolume,
    required this.effectsVolume,
  });

  final GameSessionAccessibilityOptions accessibility;
  final double masterVolume;
  final double musicVolume;
  final double effectsVolume;
}

HubPlayerSettingsProjection projectHubPlayerSettings(
  player_ui.PlayerPreferences preferences,
) =>
    HubPlayerSettingsProjection(
      accessibility: GameSessionAccessibilityOptions(
        reducedMotion: preferences.reducedMotion,
        textScale: preferences.textScale,
        hapticsEnabled: preferences.hapticsEnabled,
      ),
      masterVolume: preferences.masterVolume,
      musicVolume: preferences.musicVolume,
      effectsVolume: preferences.effectsVolume,
    );

/// Pure snapshot-to-widget adapter, independently testable from Flame.
class HubPlayerShellSurface extends StatelessWidget {
  const HubPlayerShellSurface({
    super.key,
    required this.snapshot,
    required this.gameView,
    required this.onTitleAction,
    required this.onPauseAction,
    required this.onCancelLoading,
    required this.onShowCredits,
    required this.onFinishCredits,
    required this.onReturnToHub,
    this.pauseActions,
    this.titleData,
    this.onRetryError,
  });

  final PlayerShellSnapshot snapshot;
  final Widget gameView;
  final ValueChanged<PlayerTitleAction> onTitleAction;
  final ValueChanged<player_ui.PlayerPauseAction> onPauseAction;
  final VoidCallback onCancelLoading;
  final VoidCallback onShowCredits;
  final ValueChanged<GameCompletionDestination> onFinishCredits;
  final VoidCallback onReturnToHub;
  final Map<player_ui.PlayerPauseAction, player_ui.PlayerActionAvailability>?
      pauseActions;
  final player_ui.PlayerTitleViewData? titleData;
  final VoidCallback? onRetryError;

  @override
  Widget build(BuildContext context) => switch (snapshot.state) {
        PlayerShellState.title => player_ui.PlayerTitleScreen(
            data: titleData ?? _titleData(context),
            onSelected: (action) => onTitleAction(_titleAction(action)),
          ),
        PlayerShellState.preparingSession => player_ui.PlayerLoadingSurface(
            stage: context.playerL10n.preparingSession,
          ),
        PlayerShellState.loadingSession => player_ui.PlayerLoadingSurface(
            stage: snapshot.loadingProgress?.stage ??
                context.playerL10n.loadingGame,
            progress: _loadingValue(snapshot.loadingProgress),
            onCancel: onCancelLoading,
          ),
        PlayerShellState.playing => gameView,
        PlayerShellState.paused => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              gameView,
              player_ui.PlayerPauseMenu(
                gameTitle: snapshot.title.gameTitle,
                actions: pauseActions ?? _defaultPauseActions(context),
                onSelected: onPauseAction,
              ),
            ],
          ),
        PlayerShellState.lifecyclePaused => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              gameView,
              ColoredBox(
                color: context.playerColors.scrim,
                child: Center(
                  child: player_ui.PlayerProgressCard(
                    title: context.playerL10n.sessionSuspended,
                    stage: context.playerL10n.resumeOnReturn,
                  ),
                ),
              ),
            ],
          ),
        PlayerShellState.completing => snapshot.failure == null
            ? player_ui.PlayerLoadingSurface(
                stage: context.playerL10n.validatingCompletion,
              )
            : player_ui.PlayerErrorSurface(
                title: context.playerL10n.completionSaveIncomplete,
                message: snapshot.failure?.safeMessage ??
                    context.playerL10n.completionSaveMessage,
                recommendation: context.playerL10n.completionSaveRecommendation,
                code: 'completion.${snapshot.failure!.code.name}',
                onRetry: onRetryError,
                onReturnToHub: onReturnToHub,
              ),
        PlayerShellState.result => player_ui.PlayerResultSurface(
            title:
                snapshot.result?.title ?? context.playerL10n.completedFallback,
            summary: snapshot.result?.summary ??
                context.playerL10n.completedSummaryFallback,
            details: snapshot.result?.details ?? const <String>[],
            onShowCredits: onShowCredits,
          ),
        PlayerShellState.credits => _credits(),
        PlayerShellState.disposingSession => player_ui.PlayerLoadingSurface(
            stage: context.playerL10n.closingSession,
          ),
        PlayerShellState.hub => player_ui.PlayerLoadingSurface(
            stage: context.playerL10n.returningHub,
          ),
        PlayerShellState.error => player_ui.PlayerErrorSurface(
            title: context.playerL10n.sessionErrorTitle,
            message: snapshot.failure?.safeMessage ??
                context.playerL10n.sessionCannotContinue,
            recommendation: _failureRecommendation(context, snapshot.failure),
            code: snapshot.failure == null
                ? 'session.unknown'
                : 'session.${snapshot.failure!.code.name}',
            onRetry: onRetryError,
            onReturnToHub: onReturnToHub,
          ),
      };

  player_ui.PlayerTitleViewData _titleData(BuildContext context) {
    final actions =
        <player_ui.PlayerTitleMenuAction, player_ui.PlayerActionAvailability>{};
    for (final action in player_ui.PlayerTitleMenuAction.values) {
      final shellAction = _titleAction(action);
      final enabled = snapshot.title.enabledActions.contains(shellAction);
      actions[action] = enabled
          ? player_ui.PlayerActionAvailability.enabled
          : player_ui.PlayerActionAvailability.disabled(
              switch (shellAction) {
                PlayerTitleAction.continueGame =>
                  context.playerL10n.noSaveAvailable,
                PlayerTitleAction.load => context.playerL10n.noSaveToLoad,
                _ => context.playerL10n.actionUnavailable,
              },
            );
    }
    return player_ui.PlayerTitleViewData(
      gameTitle: snapshot.title.gameTitle,
      author: snapshot.title.author,
      description: snapshot.title.description,
      actions: actions,
    );
  }

  player_ui.PlayerCreditsSurface _credits() {
    final credits = snapshot.credits;
    final destination = snapshot.completionDestination ??
        GameCompletionDestination.playerChoice;
    return player_ui.PlayerCreditsSurface(
      title: credits?.title ?? snapshot.title.gameTitle,
      author: credits?.author ?? snapshot.title.author,
      endingLabel: credits?.endingLabel,
      onReturnToTitle: destination == GameCompletionDestination.hub
          ? null
          : () => onFinishCredits(GameCompletionDestination.title),
      onReturnToHub: destination == GameCompletionDestination.title
          ? null
          : () => onFinishCredits(GameCompletionDestination.hub),
    );
  }

  Map<player_ui.PlayerPauseAction, player_ui.PlayerActionAvailability>
      _defaultPauseActions(BuildContext context) =>
          <player_ui.PlayerPauseAction, player_ui.PlayerActionAvailability>{
            player_ui.PlayerPauseAction.resume:
                player_ui.PlayerActionAvailability.enabled,
            player_ui.PlayerPauseAction.party:
                player_ui.PlayerActionAvailability.disabled(
              context.playerL10n.unavailableInGame,
            ),
            player_ui.PlayerPauseAction.bag:
                player_ui.PlayerActionAvailability.disabled(
              context.playerL10n.unavailableInGame,
            ),
            player_ui.PlayerPauseAction.pokedex:
                player_ui.PlayerActionAvailability.disabled(
              context.playerL10n.unavailableInGame,
            ),
            player_ui.PlayerPauseAction.map:
                player_ui.PlayerActionAvailability.disabled(
              context.playerL10n.unavailableInGame,
            ),
            player_ui.PlayerPauseAction.save:
                player_ui.PlayerActionAvailability.enabled,
            player_ui.PlayerPauseAction.options:
                player_ui.PlayerActionAvailability.enabled,
            player_ui.PlayerPauseAction.returnToTitle:
                player_ui.PlayerActionAvailability.enabled,
          };

  PlayerTitleAction _titleAction(
    player_ui.PlayerTitleMenuAction action,
  ) =>
      switch (action) {
        player_ui.PlayerTitleMenuAction.continueGame =>
          PlayerTitleAction.continueGame,
        player_ui.PlayerTitleMenuAction.newGame => PlayerTitleAction.newGame,
        player_ui.PlayerTitleMenuAction.load => PlayerTitleAction.load,
        player_ui.PlayerTitleMenuAction.options => PlayerTitleAction.options,
        player_ui.PlayerTitleMenuAction.creditsAbout =>
          PlayerTitleAction.creditsAbout,
        player_ui.PlayerTitleMenuAction.returnToHub =>
          PlayerTitleAction.returnToHub,
      };

  double? _loadingValue(GameSessionLoadingProgress? progress) {
    if (progress?.total case final total? when total > 0) {
      return progress!.current / total;
    }
    return null;
  }

  String _failureRecommendation(
    BuildContext context,
    GameSessionFailure? failure,
  ) =>
      switch (failure?.recoverability) {
        GameSessionFailureRecoverability.retry =>
          context.playerL10n.retryKeepsSaves,
        GameSessionFailureRecoverability.repair =>
          context.playerL10n.repairFromHub,
        GameSessionFailureRecoverability.titleOrHub =>
          context.playerL10n.returnTitleOrHub,
        GameSessionFailureRecoverability.hubOnly =>
          context.playerL10n.consultDiagnostics,
        null => context.playerL10n.consultDiagnostics,
      };
}

/// Lifecycle-aware controller host for the player shell.
class HubPlayerShellView extends StatefulWidget {
  const HubPlayerShellView({
    super.key,
    required this.controller,
    required this.gameView,
    required this.onNewGameSelection,
    required this.onLoadSelection,
    required this.onHubRequested,
    this.pauseActions,
    this.onPauseSectionRequested,
    this.options,
    this.titleData,
    this.initializeController = true,
    this.disposeController = false,
  });

  final PlayerShellController controller;
  final Widget gameView;
  final HubSaveSelectionRequest onNewGameSelection;
  final HubSaveSelectionRequest onLoadSelection;
  final VoidCallback onHubRequested;
  final Map<player_ui.PlayerPauseAction, player_ui.PlayerActionAvailability>?
      pauseActions;
  final ValueChanged<player_ui.PlayerPauseAction>? onPauseSectionRequested;
  final Widget? options;
  final player_ui.PlayerTitleViewData? titleData;
  final bool initializeController;
  final bool disposeController;

  @override
  State<HubPlayerShellView> createState() => _HubPlayerShellViewState();
}

class _HubPlayerShellViewState extends State<HubPlayerShellView>
    with WidgetsBindingObserver {
  late PlayerShellSnapshot _snapshot;
  StreamSubscription<PlayerShellSnapshot>? _subscription;
  HubSaveSelection? _pendingOverwrite;
  var _hubNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _snapshot = widget.controller.snapshot;
    _subscription = widget.controller.snapshots.listen(_onSnapshot);
    if (widget.initializeController) {
      unawaited(widget.controller.initialize());
    }
  }

  @override
  void didUpdateWidget(covariant HubPlayerShellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    unawaited(_subscription?.cancel());
    if (oldWidget.disposeController) {
      unawaited(oldWidget.controller.dispose());
    }
    _snapshot = widget.controller.snapshot;
    _subscription = widget.controller.snapshots.listen(_onSnapshot);
    _hubNotified = false;
    if (widget.initializeController) {
      unawaited(widget.controller.initialize());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.resumeFromLifecycle());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(widget.controller.pauseForLifecycle());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_snapshot.state == PlayerShellState.title &&
        _snapshot.title.state == PlayerTitleState.options) {
      return _TitleSubstateSurface(
        title: context.playerL10n.options,
        onClose: widget.controller.closeTitleSubstate,
        child: widget.options ??
            Text(
              context.playerL10n.preferences,
              textAlign: TextAlign.center,
            ),
      );
    }
    if (_snapshot.state == PlayerShellState.title &&
        _snapshot.title.state == PlayerTitleState.creditsAbout) {
      return _TitleSubstateSurface(
        title: context.playerL10n.creditsAbout,
        onClose: widget.controller.closeTitleSubstate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _snapshot.title.gameTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: player_ui.PlayerSpacing.sm),
            Text(_snapshot.title.author),
            if (_snapshot.title.description
                case final description?) ...<Widget>[
              const SizedBox(height: player_ui.PlayerSpacing.md),
              Text(description, textAlign: TextAlign.center),
            ],
          ],
        ),
      );
    }
    return HubPlayerShellSurface(
      snapshot: _snapshot,
      gameView: widget.gameView,
      pauseActions: widget.pauseActions,
      titleData: widget.titleData,
      onTitleAction: _handleTitleAction,
      onPauseAction: _handlePauseAction,
      onCancelLoading: () => unawaited(widget.controller.cancelLoading()),
      onShowCredits: widget.controller.showCredits,
      onFinishCredits: (destination) =>
          unawaited(widget.controller.finishCredits(destination)),
      onRetryError: _snapshot.state == PlayerShellState.completing
          ? () => unawaited(widget.controller.retryCompletion())
          : null,
      onReturnToHub: () => unawaited(widget.controller.returnToHub()),
    );
  }

  Future<void> _handleTitleAction(PlayerTitleAction action) async {
    switch (action) {
      case PlayerTitleAction.continueGame:
        await widget.controller.continueGame();
      case PlayerTitleAction.newGame:
        final selection = await widget.onNewGameSelection();
        if (selection == null) return;
        final result = await widget.controller.startNewGame(
          profileId: selection.profileId,
          slotId: selection.slotId,
        );
        if (result == PlayerLaunchResult.overwriteConfirmationRequired &&
            mounted) {
          _pendingOverwrite = selection;
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.playerL10n.overwriteSaveTitle),
                  content: Text(context.playerL10n.overwriteSaveMessage),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.playerL10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.playerL10n.newGame),
                    ),
                  ],
                ),
              ) ??
              false;
          if (confirmed && _pendingOverwrite != null) {
            await widget.controller.startNewGame(
              profileId: _pendingOverwrite!.profileId,
              slotId: _pendingOverwrite!.slotId,
              overwriteConfirmed: true,
            );
          }
          _pendingOverwrite = null;
        }
      case PlayerTitleAction.load:
        final selection = await widget.onLoadSelection();
        if (selection != null) {
          await widget.controller.loadSlot(
            profileId: selection.profileId,
            slotId: selection.slotId,
          );
        }
      case PlayerTitleAction.options:
        widget.controller.openOptions();
      case PlayerTitleAction.creditsAbout:
        widget.controller.openAbout();
      case PlayerTitleAction.returnToHub:
        await widget.controller.returnToHub();
    }
  }

  Future<void> _handlePauseAction(player_ui.PlayerPauseAction action) async {
    switch (action) {
      case player_ui.PlayerPauseAction.resume:
        await widget.controller.togglePause();
      case player_ui.PlayerPauseAction.save:
        await widget.controller.save();
      case player_ui.PlayerPauseAction.returnToTitle:
        await widget.controller.returnToTitle();
      case player_ui.PlayerPauseAction.party:
      case player_ui.PlayerPauseAction.bag:
      case player_ui.PlayerPauseAction.pokedex:
      case player_ui.PlayerPauseAction.map:
      case player_ui.PlayerPauseAction.options:
        widget.onPauseSectionRequested?.call(action);
    }
  }

  void _onSnapshot(PlayerShellSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
    if (snapshot.state == PlayerShellState.hub && !_hubNotified) {
      _hubNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHubRequested();
      });
    } else if (snapshot.state != PlayerShellState.hub) {
      _hubNotified = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    if (widget.disposeController) {
      unawaited(widget.controller.dispose());
    }
    super.dispose();
  }
}

class _TitleSubstateSurface extends StatelessWidget {
  const _TitleSubstateSurface({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: player_ui.PlayerSurface(
          maxWidth: 720,
          child: Center(
            child: SingleChildScrollView(
              child: player_ui.PlayerPanel(
                elevated: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.playerL10n.close,
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: player_ui.PlayerSpacing.lg),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
