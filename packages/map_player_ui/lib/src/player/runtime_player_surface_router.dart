import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import 'player_pause_menu.dart';
import 'player_control_profile.dart';
import 'player_save_recovery_surface.dart';
import 'player_save_strings.dart';
import 'player_scene_interaction_surface.dart';
import 'player_session_surfaces.dart';
import 'player_title_options_surface.dart';
import 'player_title_screen.dart';
import 'runtime_player_actions.dart';
import 'runtime_player_detail_router.dart';
import 'runtime_player_pause_shell.dart';
import 'runtime_player_focus_controller.dart';
import 'runtime_player_party.dart';
import 'runtime_player_bag.dart';

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
    this.partyNavigation,
    this.bagNavigation,
    this.onFavoriteChanged,
    this.controlProfile,
    this.onControlProfileChanged,
    this.pauseMenuLabels = const PlayerPauseMenuLabels(),
    this.pausePresentation,
    this.pauseFocusController,
    this.onPreSessionResult,
    this.showPreSessionInteraction = true,
  });

  final RuntimePlayerSnapshot snapshot;
  final RuntimePlayerTitlePresentation titlePresentation;
  final WidgetBuilder gameSceneBuilder;
  final RuntimePlayerActionCallback onAction;
  final VoidCallback? onShowDiagnostics;
  final bool gameplayTouchMenuEnabled;
  final double touchControlsOpacity;
  final ValueChanged<PlayerPreferencesSnapshot>? onPreferencesChanged;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;
  final RuntimePlayerPartyNavigation? partyNavigation;
  final RuntimePlayerBagNavigation? bagNavigation;
  final Future<void> Function(String, bool)? onFavoriteChanged;
  final PlayerControlProfile? controlProfile;
  final ValueChanged<PlayerControlProfile>? onControlProfileChanged;
  final PlayerPauseMenuLabels pauseMenuLabels;
  final PlayerPausePresentation? pausePresentation;
  final RuntimePlayerFocusController? pauseFocusController;
  final ValueChanged<SceneInteractionResult>? onPreSessionResult;
  final bool showPreSessionInteraction;

  Widget? _bagMoney(BuildContext context) {
    final detail = snapshot.pauseDetailFor(RuntimePlayerPauseSection.bag);
    final money = detail?.bagMoney;
    if (money == null) return null;
    final currency = detail!.bagCurrencyLabel;
    final label = Localizations.localeOf(context).languageCode == 'fr'
        ? 'Argent'
        : 'Money';
    return PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.bag,
        child: Builder(
            builder: (context) => Text(
                '$label : ${MaterialLocalizations.of(context).formatDecimal(money)}${currency == null ? '' : ' $currency'}',
                key: const ValueKey('bag-money'),
                style: context.playerMenuTheme.label)));
  }

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
        if (snapshot.saveRecovery case final recovery?
            when snapshot.phase == RuntimePlayerPhase.title)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: PlayerSaveRecoverySurface(
                  diagnostic: recovery,
                  onAction: _dispatchRecovery,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _dispatchRecovery(SaveRecoveryAction action) {
    switch (action) {
      case SaveRecoveryAction.deleteSave:
        _dispatch(RuntimePlayerAction.deleteUnusableSave);
      case SaveRecoveryAction.retry:
        _dispatch(RuntimePlayerAction.continueGame);
      case SaveRecoveryAction.restoreBackup:
      case SaveRecoveryAction.migrate:
      case SaveRecoveryAction.returnToTitle:
        break;
    }
  }

  Widget? _overlay(BuildContext context) {
    final l10n = context.playerL10n;
    return switch (snapshot.phase) {
      RuntimePlayerPhase.boot => PlayerLoadingSurface(
          stage: l10n.preparing,
        ),
      RuntimePlayerPhase.title
          when snapshot.pauseSection == RuntimePlayerPauseSection.options =>
        PlayerTitleOptionsSurface(
          snapshot: snapshot,
          onReturnToTitle: _callbackFor(RuntimePlayerAction.returnToTitle),
          onPreferencesChanged: onPreferencesChanged,
          controlProfile: controlProfile,
          onControlProfileChanged: onControlProfileChanged,
        ),
      RuntimePlayerPhase.title => PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: titlePresentation.resolveTitle(snapshot.gameTitle),
            author: titlePresentation.author,
            description: titlePresentation.description,
            background: titlePresentation.background,
            logo: titlePresentation.logo,
            accentColor: titlePresentation.accentColor,
            layoutVariant: titlePresentation.layoutVariant,
            continueSave: snapshot.continueSave,
            actions: titlePresentation.projectActions(
              <PlayerTitleMenuAction, PlayerActionAvailability>{
                for (final action in PlayerTitleMenuAction.values)
                  action: _titleAvailability(context, action),
              },
            ),
            actionLabels: titlePresentation.actionLabels,
            actionIcons: titlePresentation.actionIcons,
          ),
          onSelected: (action) => _dispatch(_titleAction(action)),
        ),
      RuntimePlayerPhase.preSession
          when snapshot.preSessionRequest != null &&
              showPreSessionInteraction =>
        PlayerSceneInteractionSurface(
          request: snapshot.preSessionRequest!,
          interactionEnabled: snapshot.isActionEnabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
          onResult: onPreSessionResult ?? (_) {},
        ),
      RuntimePlayerPhase.preSession => PlayerLoadingSurface(
          stage: l10n.preparingSession,
          onCancel: _callbackFor(RuntimePlayerAction.cancel),
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
          focusController: pauseFocusController,
          playerProfile: snapshot.playerProfile,
          portraitImage: snapshot.playerProfile?.portraitFilePath == null
              ? null
              : FileImage(File(snapshot.playerProfile!.portraitFilePath!)),
          gameTitle: snapshot.gameTitle,
          pauseSection: snapshot.pauseSection ?? RuntimePlayerPauseSection.root,
          actions: <PlayerPauseAction, PlayerActionAvailability>{
            for (final action in PlayerPauseAction.values)
              action: _pauseAvailability(context, action),
          },
          onSelected: (action) => _dispatchPauseAction(context, action),
          onBackToRoot: () {
            if (snapshot.pauseSection == RuntimePlayerPauseSection.bag &&
                (bagNavigation?.back() ?? false)) {
              return;
            }
            if (snapshot.pauseSection == RuntimePlayerPauseSection.party &&
                (partyNavigation?.back() ?? false)) {
              return;
            }
            _dispatch(
              snapshot.pauseSection == null ||
                      snapshot.pauseSection == RuntimePlayerPauseSection.root
                  ? RuntimePlayerAction.resume
                  : RuntimePlayerAction.returnToPauseRoot,
            );
          },
          onTouchMenu: snapshot.pauseSection == null ||
                  snapshot.pauseSection == RuntimePlayerPauseSection.root
              ? _callbackFor(RuntimePlayerAction.resume)
              : _callbackFor(RuntimePlayerAction.returnToPauseRoot),
          activeInputSource: snapshot.activeInputSource,
          logicalSelectionId: snapshot.logicalSelectionId,
          labels: pauseMenuLabels,
          presentation: (pausePresentation ?? const PlayerPausePresentation())
              .resolveVisibility(snapshot.pauseMenuState),
          saveMessage: snapshot.saveReceipt == null
              ? null
              : PlayerSaveStrings.of(context).saved(snapshot.saveReceipt!),
          detail: RuntimePlayerDetailRouter(
            bagNavigation: bagNavigation,
            onFavoriteChanged: onFavoriteChanged,
            partyNavigation: partyNavigation,
            snapshot: snapshot,
            onPreferencesChanged: onPreferencesChanged,
            onPauseCommand: onPauseCommand,
          ),
          detailOwnsScroll:
              snapshot.pauseSection == RuntimePlayerPauseSection.party ||
                  snapshot.pauseSection == RuntimePlayerPauseSection.bag,
          detailHeaderSecondary:
              snapshot.pauseSection == RuntimePlayerPauseSection.bag
                  ? _bagMoney(context)
                  : null,
          detailActions: snapshot.pauseSection ==
                      RuntimePlayerPauseSection.party &&
                  snapshot.isActionEnabled(RuntimePlayerAction.openParty) &&
                  snapshot.pauseDetailFor(RuntimePlayerPauseSection.party) !=
                      null &&
                  partyNavigation != null
              ? ListenableBuilder(
                  listenable: partyNavigation!,
                  builder: (context, _) =>
                      partyNavigation!.buildActions(context))
              : snapshot.pauseSection == RuntimePlayerPauseSection.bag &&
                      snapshot.isActionEnabled(RuntimePlayerAction.openBag) &&
                      snapshot.pauseDetailFor(RuntimePlayerPauseSection.bag) !=
                          null &&
                      bagNavigation != null
                  ? ListenableBuilder(
                      listenable: bagNavigation!,
                      builder: (context, _) =>
                          bagNavigation!.buildActions(context))
                  : null,
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
          endingLabel:
              snapshot.credits?.endingLabel ?? titlePresentation.description,
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

  void _dispatchPauseAction(
    BuildContext context,
    PlayerPauseAction action,
  ) {
    if (action != PlayerPauseAction.save) {
      _dispatch(_pauseAction(action));
      return;
    }
    final address = snapshot.activeSaveAddress;
    if (address == null) return;
    final strings = PlayerSaveStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.title),
        content: Text(strings.target(address)),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('runtime-save-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const ValueKey<String>('runtime-save-confirm'),
            autofocus: true,
            onPressed: () {
              Navigator.of(context).pop();
              _dispatch(RuntimePlayerAction.save);
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
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
        PlayerPauseAction.quests => RuntimePlayerAction.openQuests,
        PlayerPauseAction.profile => RuntimePlayerAction.openProfile,
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
        RuntimePlayerPhase.preSession ||
        RuntimePlayerPhase.preparingSession ||
        RuntimePlayerPhase.result ||
        RuntimePlayerPhase.credits ||
        RuntimePlayerPhase.externalExit ||
        RuntimePlayerPhase.error =>
          false,
      };
}
