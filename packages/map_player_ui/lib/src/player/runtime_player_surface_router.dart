import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../localization/player_localizations.dart';
import 'player_pause_menu.dart';
import 'player_session_surfaces.dart';
import 'player_title_screen.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_detail_router.dart';
import 'runtime_player_pause_shell.dart';

typedef RuntimePlayerActionCallback = Future<RuntimePlayerCommandResult>
    Function(RuntimePlayerAction action);

/// Pure presentation router for the runtime-owned player state machine.
class RuntimePlayerSurfaceRouter extends StatelessWidget {
  const RuntimePlayerSurfaceRouter({
    super.key,
    required this.snapshot,
    required this.titlePresentation,
    required this.gameSceneBuilder,
    required this.onAction,
    this.onShowDiagnostics,
    this.gameplayTouchMenuEnabled = true,
    this.touchControlsOpacity = 0.82,
    this.onPreferencesChanged,
    this.onPauseCommand,
  });

  final RuntimePlayerSnapshot snapshot;
  final RuntimePlayerTitlePresentation titlePresentation;
  final WidgetBuilder gameSceneBuilder;
  final RuntimePlayerActionCallback onAction;
  final VoidCallback? onShowDiagnostics;
  final bool gameplayTouchMenuEnabled;
  final double touchControlsOpacity;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;
  final ValueChanged<RuntimePlayerPauseCommand>? onPauseCommand;

  @override
  Widget build(BuildContext context) {
    final overlay = _overlay(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (_usesGameScene(snapshot.phase))
          KeyedSubtree(
            key: const ValueKey<String>('runtime-player-game-scene'),
            child: gameSceneBuilder(context),
          ),
        Positioned.fill(
          key: ValueKey<String>(
            'runtime-player-surface-${snapshot.phase.name}',
          ),
          child: overlay ?? const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget? _overlay(BuildContext context) {
    final l10n = context.playerL10n;
    return switch (snapshot.phase) {
      RuntimePlayerPhase.boot => PlayerLoadingSurface(
          stage: l10n.preparing,
        ),
      RuntimePlayerPhase.title => PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: snapshot.gameTitle,
            author: titlePresentation.author,
            description: titlePresentation.description,
            background: titlePresentation.background,
            logo: titlePresentation.logo,
            accentColor: titlePresentation.accentColor,
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: _titleAvailability(context, action),
            },
          ),
          onSelected: (action) => _dispatch(_titleAction(action)),
        ),
      RuntimePlayerPhase.preparingSession => PlayerLoadingSurface(
          stage: l10n.preparingSession,
          onCancel: _callbackFor(RuntimePlayerAction.cancel),
        ),
      RuntimePlayerPhase.loadingSession => PlayerLoadingSurface(
          stage: snapshot.loadingProgress?.stage ?? l10n.loadingGame,
          progress: _progress,
          onCancel: _callbackFor(RuntimePlayerAction.cancel),
        ),
      RuntimePlayerPhase.playing => RuntimePlayerTouchMenuButton(
          onPressed: gameplayTouchMenuEnabled
              ? _callbackFor(RuntimePlayerAction.openMenu)
              : null,
          activeInputSource: snapshot.activeInputSource,
          opacity: touchControlsOpacity,
        ),
      RuntimePlayerPhase.paused => RuntimePlayerPauseShell(
          gameTitle: snapshot.gameTitle,
          pauseSection: snapshot.pauseSection ?? RuntimePlayerPauseSection.root,
          actions: <PlayerPauseAction, PlayerActionAvailability>{
            for (final action in PlayerPauseAction.values)
              action: _pauseAvailability(context, action),
          },
          onSelected: (action) => _dispatch(_pauseAction(action)),
          onBackToRoot: () => _dispatch(
            snapshot.pauseSection == null ||
                    snapshot.pauseSection == RuntimePlayerPauseSection.root
                ? RuntimePlayerAction.resume
                : RuntimePlayerAction.returnToPauseRoot,
          ),
          onTouchMenu: _callbackFor(RuntimePlayerAction.resume),
          activeInputSource: snapshot.activeInputSource,
          logicalSelectionId: snapshot.logicalSelectionId,
          detail: RuntimePlayerDetailRouter(
            snapshot: snapshot,
            onPreferencesChanged: onPreferencesChanged,
            onPauseCommand: onPauseCommand,
          ),
        ),
      RuntimePlayerPhase.saving => PlayerLoadingSurface(
          stage: l10n.save,
        ),
      RuntimePlayerPhase.lifecyclePaused => PlayerLoadingSurface(
          stage: l10n.sessionSuspended,
        ),
      RuntimePlayerPhase.completing when snapshot.failure != null =>
        _error(context),
      RuntimePlayerPhase.completing => PlayerLoadingSurface(
          stage: l10n.validatingCompletion,
        ),
      RuntimePlayerPhase.result => PlayerResultSurface(
          title: snapshot.result?.title ?? l10n.completedFallback,
          summary: snapshot.result?.summary ?? l10n.completedSummaryFallback,
          details: snapshot.result?.details ?? const <String>[],
          onShowCredits: _callbackFor(RuntimePlayerAction.showCredits),
        ),
      RuntimePlayerPhase.credits => PlayerCreditsSurface(
          title: snapshot.credits?.title ?? snapshot.gameTitle,
          author: snapshot.credits?.author ?? titlePresentation.author,
          endingLabel: snapshot.credits?.endingLabel,
          onReturnToTitle: _callbackFor(RuntimePlayerAction.returnToTitle),
          onReturnToHub: _callbackFor(RuntimePlayerAction.returnToHost),
        ),
      RuntimePlayerPhase.disposingSession => PlayerLoadingSurface(
          stage: l10n.closingSession,
        ),
      RuntimePlayerPhase.externalExit => PlayerLoadingSurface(
          stage: l10n.returningHub,
        ),
      RuntimePlayerPhase.error => _error(context),
    };
  }

  PlayerErrorSurface _error(BuildContext context) {
    final l10n = context.playerL10n;
    final failure = snapshot.failure;
    return PlayerErrorSurface(
      title: l10n.sessionErrorTitle,
      message: failure?.safeMessage ?? l10n.sessionCannotContinue,
      recommendation: _recommendation(context, failure),
      code: failure?.code.name,
      stage: snapshot.loadingProgress?.stage,
      onRetry: _callbackFor(RuntimePlayerAction.retry),
      onCancel: _callbackFor(RuntimePlayerAction.cancel),
      onShowDiagnostics: onShowDiagnostics,
    );
  }

  String _recommendation(
    BuildContext context,
    GameSessionFailure? failure,
  ) {
    final l10n = context.playerL10n;
    return switch (failure?.recoverability) {
      GameSessionFailureRecoverability.retry => l10n.retryKeepsSaves,
      GameSessionFailureRecoverability.repair => l10n.repairFromHub,
      GameSessionFailureRecoverability.titleOrHub => l10n.returnTitleOrHub,
      GameSessionFailureRecoverability.hubOnly => l10n.consultDiagnostics,
      null => l10n.consultDiagnostics,
    };
  }

  double? get _progress {
    final progress = snapshot.loadingProgress;
    final total = progress?.total;
    if (progress == null || total == null || total == 0) return null;
    return (progress.current / total).clamp(0, 1);
  }

  VoidCallback? _callbackFor(RuntimePlayerAction action) {
    if (!snapshot.isActionEnabled(action)) return null;
    return () => _dispatch(action);
  }

  void _dispatch(RuntimePlayerAction action) {
    unawaited(onAction(action));
  }

  PlayerActionAvailability _titleAvailability(
    BuildContext context,
    PlayerTitleMenuAction action,
  ) =>
      _availability(
        context,
        _titleAction(action),
      );

  PlayerActionAvailability _pauseAvailability(
    BuildContext context,
    PlayerPauseAction action,
  ) =>
      _availability(
        context,
        _pauseAction(action),
      );

  PlayerActionAvailability _availability(
    BuildContext context,
    RuntimePlayerAction action,
  ) {
    for (final availability in snapshot.actions) {
      if (availability.action != action) continue;
      return availability.isEnabled
          ? PlayerActionAvailability.enabled
          : PlayerActionAvailability.disabled(
              availability.unavailableReason ??
                  context.playerL10n.actionUnavailable,
            );
    }
    return PlayerActionAvailability.disabled(
      context.playerL10n.actionUnavailable,
    );
  }

  RuntimePlayerAction _titleAction(PlayerTitleMenuAction action) =>
      switch (action) {
        PlayerTitleMenuAction.continueGame => RuntimePlayerAction.continueGame,
        PlayerTitleMenuAction.newGame => RuntimePlayerAction.newGame,
        PlayerTitleMenuAction.load => RuntimePlayerAction.load,
        PlayerTitleMenuAction.options => RuntimePlayerAction.openOptions,
        PlayerTitleMenuAction.creditsAbout => RuntimePlayerAction.showCredits,
        PlayerTitleMenuAction.returnToHub => RuntimePlayerAction.returnToHost,
      };

  RuntimePlayerAction _pauseAction(PlayerPauseAction action) =>
      switch (action) {
        PlayerPauseAction.resume => RuntimePlayerAction.resume,
        PlayerPauseAction.party => RuntimePlayerAction.openParty,
        PlayerPauseAction.bag => RuntimePlayerAction.openBag,
        PlayerPauseAction.pokedex => RuntimePlayerAction.openPokedex,
        PlayerPauseAction.map => RuntimePlayerAction.openMap,
        PlayerPauseAction.save => RuntimePlayerAction.save,
        PlayerPauseAction.options => RuntimePlayerAction.openOptions,
        PlayerPauseAction.returnToTitle => RuntimePlayerAction.returnToTitle,
      };

  bool _usesGameScene(RuntimePlayerPhase phase) => switch (phase) {
        RuntimePlayerPhase.loadingSession ||
        RuntimePlayerPhase.playing ||
        RuntimePlayerPhase.paused ||
        RuntimePlayerPhase.saving ||
        RuntimePlayerPhase.lifecyclePaused ||
        RuntimePlayerPhase.completing ||
        RuntimePlayerPhase.disposingSession =>
          true,
        RuntimePlayerPhase.boot ||
        RuntimePlayerPhase.title ||
        RuntimePlayerPhase.preparingSession ||
        RuntimePlayerPhase.result ||
        RuntimePlayerPhase.credits ||
        RuntimePlayerPhase.externalExit ||
        RuntimePlayerPhase.error =>
          false,
      };
}
