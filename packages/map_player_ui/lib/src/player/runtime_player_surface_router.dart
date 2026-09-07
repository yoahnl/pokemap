import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import 'player_pause_menu.dart';
import 'player_control_profile.dart';
import 'player_save_dialog.dart';
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
import 'runtime_player_options.dart';
import 'runtime_player_pokedex.dart';
import 'runtime_player_region_map.dart';

typedef RuntimePlayerActionCallback = Future<RuntimePlayerCommandResult>
    Function(RuntimePlayerAction action);

/// Pure presentation router for the runtime-owned player state machine.
class RuntimePlayerSurfaceRouter extends StatefulWidget {
  const RuntimePlayerSurfaceRouter({
    super.key,
    required this.snapshot,
    required this.titlePresentation,
    required this.gameSceneBuilder,
    required this.onAction,
    this.onReturnToTitle,
    this.onShowDiagnostics,
    this.gameplayTouchMenuEnabled = true,
    this.touchControlsOpacity = 0.82,
    this.onPreferencesChanged,
    this.onPauseCommand,
    this.partyNavigation,
    this.bagNavigation,
    this.pokedexNavigation,
    this.onFavoriteChanged,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.activeInputSource,
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
  final Future<RuntimePlayerCommandResult> Function(bool saveBeforeExit)?
      onReturnToTitle;
  final VoidCallback? onShowDiagnostics;
  final bool gameplayTouchMenuEnabled;
  final double touchControlsOpacity;
  final FutureOr<void> Function(PlayerPreferencesSnapshot)?
      onPreferencesChanged;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;
  final RuntimePlayerPartyNavigation? partyNavigation;
  final RuntimePlayerBagNavigation? bagNavigation;
  final RuntimePlayerPokedexNavigation? pokedexNavigation;
  final Future<void> Function(String, bool)? onFavoriteChanged;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final PlayerInputSource? activeInputSource;
  final FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged;
  final PlayerPauseMenuLabels pauseMenuLabels;
  final PlayerPausePresentation? pausePresentation;
  final RuntimePlayerFocusController? pauseFocusController;
  final ValueChanged<SceneInteractionResult>? onPreSessionResult;
  final bool showPreSessionInteraction;

  @override
  State<RuntimePlayerSurfaceRouter> createState() =>
      _RuntimePlayerSurfaceRouterState();
}

class _RuntimePlayerSurfaceRouterState
    extends State<RuntimePlayerSurfaceRouter> {
  final _ownedPokedexNavigation = RuntimePlayerPokedexNavigation();
  final _regionMapNavigation = RuntimePlayerRegionMapNavigation();
  final _optionsNavigation = RuntimePlayerOptionsNavigation();
  ValueNotifier<RuntimePlayerSnapshot>? _dialogSnapshot;
  DialogRoute<void>? _saveDialogRoute;
  RuntimePlayerSaveReceipt? _shownSaveReceipt;

  RuntimePlayerPokedexNavigation get _pokedexNavigation =>
      widget.pokedexNavigation ?? _ownedPokedexNavigation;

  @override
  void didUpdateWidget(RuntimePlayerSurfaceRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionChanged = widget.snapshot.activeSaveAddress !=
            oldWidget.snapshot.activeSaveAddress ||
        widget.snapshot.phase == RuntimePlayerPhase.title ||
        widget.snapshot.phase == RuntimePlayerPhase.preSession ||
        widget.snapshot.phase == RuntimePlayerPhase.preparingSession ||
        widget.snapshot.phase == RuntimePlayerPhase.externalExit;
    if (sessionChanged) _shownSaveReceipt = null;
    if (sessionChanged) _regionMapNavigation.clearForNewSession();
    final relay = _dialogSnapshot;
    final route = _saveDialogRoute;
    if (relay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_dialogSnapshot, relay)) return;
        relay.value = widget.snapshot;
        if (sessionChanged && route?.isActive == true) {
          route!.navigator?.removeRoute(route);
        }
      });
    }
    if (widget.pokedexNavigation == null &&
        (oldWidget.pokedexNavigation != null ||
            oldWidget.snapshot.phase != widget.snapshot.phase &&
                (widget.snapshot.phase == RuntimePlayerPhase.title ||
                    widget.snapshot.phase ==
                        RuntimePlayerPhase.preparingSession))) {
      _ownedPokedexNavigation.clearForNewSession();
    }
  }

  @override
  void dispose() {
    final route = _saveDialogRoute;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    _ownedPokedexNavigation.dispose();
    _regionMapNavigation.dispose();
    _optionsNavigation.dispose();
    super.dispose();
  }

  Widget? _bagMoney(BuildContext context) {
    final detail =
        widget.snapshot.pauseDetailFor(RuntimePlayerPauseSection.bag);
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

  void _backFromPause() {
    if (widget.snapshot.pauseSection == RuntimePlayerPauseSection.options &&
        _optionsNavigation.back()) {
      return;
    }
    if (widget.snapshot.pauseSection == RuntimePlayerPauseSection.map &&
        _regionMapNavigation.back()) {
      return;
    }
    if (widget.snapshot.pauseSection == RuntimePlayerPauseSection.pokedex &&
        _pokedexNavigation.back()) {
      return;
    }
    if (widget.snapshot.pauseSection == RuntimePlayerPauseSection.bag &&
        (widget.bagNavigation?.back() ?? false)) {
      return;
    }
    if (widget.snapshot.pauseSection == RuntimePlayerPauseSection.party &&
        (widget.partyNavigation?.back() ?? false)) {
      return;
    }
    _dispatch(widget.snapshot.pauseSection == null ||
            widget.snapshot.pauseSection == RuntimePlayerPauseSection.root
        ? RuntimePlayerAction.resume
        : RuntimePlayerAction.returnToPauseRoot);
  }

  Widget? _pokedexProgress(BuildContext context) {
    final entries = widget.snapshot
        .pauseDetailFor(RuntimePlayerPauseSection.pokedex)
        ?.entries;
    if (entries == null || entries.isEmpty) return null;
    final seen = entries
        .where((entry) =>
            entry.pokedexEntry?.knowledge ==
                RuntimePlayerPokedexKnowledge.seen ||
            entry.pokedexEntry?.knowledge ==
                RuntimePlayerPokedexKnowledge.caught)
        .length;
    final caught = entries
        .where((entry) =>
            entry.pokedexEntry?.knowledge ==
            RuntimePlayerPokedexKnowledge.caught)
        .length;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final format = MaterialLocalizations.of(context).formatDecimal;
    return PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.pokedex,
      child: Builder(
          builder: (context) => Text(
                '${french ? 'Vus' : 'Seen'} ${format(seen)} · ${french ? 'Capturés' : 'Caught'} ${format(caught)} / ${format(entries.length)}',
                key: const ValueKey('pokedex-progress'),
                style: context.playerMenuTheme.meta,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _overlay(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (_usesGameScene(widget.snapshot.phase))
          KeyedSubtree(
            key: const ValueKey<String>('runtime-player-game-scene'),
            child: widget.gameSceneBuilder(context),
          ),
        Positioned.fill(
          key: ValueKey<String>(
            'runtime-player-surface-${widget.snapshot.phase.name}',
          ),
          child: overlay ?? const SizedBox.shrink(),
        ),
        if (widget.snapshot.saveRecovery case final recovery?
            when widget.snapshot.phase == RuntimePlayerPhase.title)
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
    return switch (widget.snapshot.phase) {
      RuntimePlayerPhase.boot => PlayerLoadingSurface(
          stage: l10n.preparing,
        ),
      RuntimePlayerPhase.title
          when widget.snapshot.pauseSection ==
              RuntimePlayerPauseSection.options =>
        PlayerTitleOptionsSurface(
          snapshot: widget.snapshot,
          onReturnToTitle: _callbackFor(RuntimePlayerAction.returnToTitle),
          onPreferencesChanged: widget.onPreferencesChanged,
          controlProfile: widget.controlProfile,
          hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
          activeInputSource:
              widget.activeInputSource ?? widget.snapshot.activeInputSource,
          onControlProfileChanged: widget.onControlProfileChanged,
        ),
      RuntimePlayerPhase.title => PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: widget.titlePresentation
                .resolveTitle(widget.snapshot.gameTitle),
            author: widget.titlePresentation.author,
            description: widget.titlePresentation.description,
            background: widget.titlePresentation.background,
            logo: widget.titlePresentation.logo,
            accentColor: widget.titlePresentation.accentColor,
            layoutVariant: widget.titlePresentation.layoutVariant,
            continueSave: widget.snapshot.continueSave,
            actions: widget.titlePresentation.projectActions(
              <PlayerTitleMenuAction, PlayerActionAvailability>{
                for (final action in PlayerTitleMenuAction.values)
                  action: _titleAvailability(context, action),
              },
            ),
            actionLabels: widget.titlePresentation.actionLabels,
            actionIcons: widget.titlePresentation.actionIcons,
          ),
          onSelected: (action) => _dispatch(_titleAction(action)),
        ),
      RuntimePlayerPhase.preSession
          when widget.snapshot.preSessionRequest != null &&
              widget.showPreSessionInteraction =>
        PlayerSceneInteractionSurface(
          request: widget.snapshot.preSessionRequest!,
          interactionEnabled: widget.snapshot.isActionEnabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
          onResult: widget.onPreSessionResult ?? (_) {},
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
          stage: widget.snapshot.loadingProgress?.stage ?? l10n.loadingGame,
          progress: _progress,
          onCancel: _callbackFor(RuntimePlayerAction.cancel),
        ),
      RuntimePlayerPhase.playing => RuntimePlayerTouchMenuButton(
          onPressed: widget.gameplayTouchMenuEnabled
              ? _callbackFor(RuntimePlayerAction.openMenu)
              : null,
          activeInputSource:
              widget.activeInputSource ?? widget.snapshot.activeInputSource,
          opacity: widget.touchControlsOpacity,
        ),
      RuntimePlayerPhase.paused => RuntimePlayerPauseShell(
          focusController: widget.pauseFocusController,
          playerProfile: widget.snapshot.playerProfile,
          portraitImage: widget.snapshot.playerProfile?.portraitFilePath == null
              ? null
              : FileImage(
                  File(widget.snapshot.playerProfile!.portraitFilePath!)),
          gameTitle: widget.snapshot.gameTitle,
          pauseSection:
              widget.snapshot.pauseSection ?? RuntimePlayerPauseSection.root,
          actions: <PlayerPauseAction, PlayerActionAvailability>{
            for (final action in PlayerPauseAction.values)
              action: _pauseAvailability(context, action),
          },
          onSelected: (action) => _dispatchPauseAction(context, action),
          onBackToRoot: _backFromPause,
          onTouchMenu: widget.snapshot.pauseSection == null ||
                  widget.snapshot.pauseSection == RuntimePlayerPauseSection.root
              ? _callbackFor(RuntimePlayerAction.resume)
              : _callbackFor(RuntimePlayerAction.returnToPauseRoot),
          activeInputSource:
              widget.activeInputSource ?? widget.snapshot.activeInputSource,
          logicalSelectionId: widget.snapshot.logicalSelectionId,
          labels: widget.pauseMenuLabels,
          presentation:
              (widget.pausePresentation ?? const PlayerPausePresentation())
                  .resolveVisibility(widget.snapshot.pauseMenuState),
          saveMessage: _saveDialogRoute != null ||
                  widget.snapshot.saveReceipt == null ||
                  identical(widget.snapshot.saveReceipt, _shownSaveReceipt)
              ? null
              : PlayerSaveStrings.of(context)
                  .saved(widget.snapshot.saveReceipt!),
          detail: RuntimePlayerDetailRouter(
            optionsNavigation: widget.pausePresentation?.style ==
                    ProjectPauseMenuStyle.nightIllustrated
                ? _optionsNavigation
                : null,
            pokedexNavigation: _pokedexNavigation,
            regionMapNavigation: _regionMapNavigation,
            bagNavigation: widget.bagNavigation,
            onFavoriteChanged: widget.onFavoriteChanged,
            partyNavigation: widget.partyNavigation,
            snapshot: widget.snapshot,
            controlProfile: widget.controlProfile,
            hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
            activeInputSource:
                widget.activeInputSource ?? widget.snapshot.activeInputSource,
            onControlProfileChanged: widget.onControlProfileChanged,
            onPreferencesChanged: widget.onPreferencesChanged,
            onPauseCommand: widget.onPauseCommand,
            onReturnToTitle: widget.snapshot
                    .isActionEnabled(RuntimePlayerAction.returnToTitle)
                ? () => unawaited(_showSaveDialog(returnToTitle: true))
                : null,
          ),
          detailOwnsScroll: widget.snapshot.pauseSection ==
                  RuntimePlayerPauseSection.party ||
              widget.snapshot.pauseSection == RuntimePlayerPauseSection.bag ||
              widget.snapshot.pauseSection ==
                  RuntimePlayerPauseSection.pokedex ||
              widget.snapshot.pauseSection ==
                  RuntimePlayerPauseSection.profile ||
              widget.snapshot.pauseSection ==
                  RuntimePlayerPauseSection.options ||
              widget.snapshot.pauseSection == RuntimePlayerPauseSection.map,
          detailHeaderSecondary:
              widget.snapshot.pauseSection == RuntimePlayerPauseSection.bag
                  ? _bagMoney(context)
                  : widget.snapshot.pauseSection ==
                          RuntimePlayerPauseSection.pokedex
                      ? _pokedexProgress(context)
                      : null,
          detailActions: widget.snapshot.pauseSection == RuntimePlayerPauseSection.party &&
                  widget.snapshot
                      .isActionEnabled(RuntimePlayerAction.openParty) &&
                  widget.snapshot.pauseDetailFor(RuntimePlayerPauseSection.party) !=
                      null &&
                  widget.partyNavigation != null
              ? ListenableBuilder(
                  listenable: widget.partyNavigation!,
                  builder: (context, _) =>
                      widget.partyNavigation!.buildActions(context))
              : widget.snapshot.pauseSection == RuntimePlayerPauseSection.bag &&
                      widget.snapshot
                          .isActionEnabled(RuntimePlayerAction.openBag) &&
                      widget.snapshot.pauseDetailFor(RuntimePlayerPauseSection.bag) !=
                          null &&
                      widget.bagNavigation != null
                  ? ListenableBuilder(
                      listenable: widget.bagNavigation!,
                      builder: (context, _) =>
                          widget.bagNavigation!.buildActions(context))
                  : widget.snapshot.pauseSection == RuntimePlayerPauseSection.options &&
                          widget.snapshot.isActionEnabled(
                              RuntimePlayerAction.openOptions) &&
                          widget.snapshot.preferences != null &&
                          widget.pausePresentation?.style ==
                              ProjectPauseMenuStyle.nightIllustrated
                      ? ListenableBuilder(
                          listenable: _optionsNavigation,
                          builder: (context, _) =>
                              _optionsNavigation.buildActions(context))
                      : (widget.snapshot.pauseSection == RuntimePlayerPauseSection.pokedex ||
                                  widget.snapshot.pauseSection == RuntimePlayerPauseSection.profile ||
                                  widget.snapshot.pauseSection == RuntimePlayerPauseSection.options) &&
                              widget.pausePresentation?.style != ProjectPauseMenuStyle.nightIllustrated
                          ? PlayerActionButton(
                              key:
                                  const ValueKey('runtime-pause-detail-return'),
                              label: context.playerL10n.back,
                              icon: Icons.arrow_back_rounded,
                              onPressed: _backFromPause,
                            )
                          : null,
          detailFooterBuilder: switch (widget.snapshot.pauseSection) {
            RuntimePlayerPauseSection.party
                when widget.snapshot
                        .isActionEnabled(RuntimePlayerAction.openParty) &&
                    widget.snapshot
                            .pauseDetailFor(RuntimePlayerPauseSection.party) !=
                        null &&
                    widget.partyNavigation != null =>
              (context, returnAction) => ListenableBuilder(
                    listenable: widget.partyNavigation!,
                    builder: (context, _) => widget.partyNavigation!
                        .buildActions(context, returnAction: returnAction),
                  ),
            RuntimePlayerPauseSection.bag
                when widget.snapshot
                        .isActionEnabled(RuntimePlayerAction.openBag) &&
                    widget.snapshot
                            .pauseDetailFor(RuntimePlayerPauseSection.bag) !=
                        null &&
                    widget.bagNavigation != null =>
              (context, returnAction) => ListenableBuilder(
                    listenable: widget.bagNavigation!,
                    builder: (context, _) => widget.bagNavigation!
                        .buildActions(context, returnAction: returnAction),
                  ),
            RuntimePlayerPauseSection.options
                when widget.snapshot
                        .isActionEnabled(RuntimePlayerAction.openOptions) &&
                    widget.snapshot.preferences != null =>
              (context, returnAction) => ListenableBuilder(
                    listenable: _optionsNavigation,
                    builder: (context, _) => _optionsNavigation
                        .buildActions(context, returnAction: returnAction),
                  ),
            _ => null,
          },
        ),
      RuntimePlayerPhase.saving => PlayerLoadingSurface(
          stage: l10n.save,
        ),
      RuntimePlayerPhase.lifecyclePaused => PlayerLoadingSurface(
          stage: l10n.sessionSuspended,
        ),
      RuntimePlayerPhase.completing when widget.snapshot.failure != null =>
        _error(context),
      RuntimePlayerPhase.completing => PlayerLoadingSurface(
          stage: l10n.validatingCompletion,
        ),
      RuntimePlayerPhase.result => PlayerResultSurface(
          title: widget.snapshot.result?.title ?? l10n.completedFallback,
          summary:
              widget.snapshot.result?.summary ?? l10n.completedSummaryFallback,
          details: widget.snapshot.result?.details ?? const <String>[],
          onShowCredits: _callbackFor(RuntimePlayerAction.showCredits),
        ),
      RuntimePlayerPhase.credits => PlayerCreditsSurface(
          title: widget.snapshot.credits?.title ?? widget.snapshot.gameTitle,
          author: widget.snapshot.credits?.author ??
              widget.titlePresentation.author,
          endingLabel: widget.snapshot.credits?.endingLabel ??
              widget.titlePresentation.description,
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
    final failure = widget.snapshot.failure;
    return PlayerErrorSurface(
      title: l10n.sessionErrorTitle,
      message: failure?.safeMessage ?? l10n.sessionCannotContinue,
      recommendation: _recommendation(context, failure),
      code: failure?.code.name,
      stage: widget.snapshot.loadingProgress?.stage,
      onRetry: _callbackFor(RuntimePlayerAction.retry),
      onCancel: _callbackFor(RuntimePlayerAction.cancel),
      onShowDiagnostics: widget.onShowDiagnostics,
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
    final progress = widget.snapshot.loadingProgress;
    final total = progress?.total;
    if (progress == null || total == null || total == 0) return null;
    return (progress.current / total).clamp(0, 1);
  }

  VoidCallback? _callbackFor(RuntimePlayerAction action) {
    if (!widget.snapshot.isActionEnabled(action)) return null;
    return () => _dispatch(action);
  }

  void _dispatch(RuntimePlayerAction action) {
    unawaited(widget.onAction(action));
  }

  void _dispatchPauseAction(
    BuildContext context,
    PlayerPauseAction action,
  ) {
    if (!widget.snapshot.isActionEnabled(_pauseAction(action))) return;
    switch (action) {
      case PlayerPauseAction.save:
        if (widget.snapshot.activeSaveAddress == null) return;
        unawaited(_showSaveDialog());
      case PlayerPauseAction.returnToTitle:
        unawaited(_showSaveDialog(returnToTitle: true));
      default:
        _dispatch(_pauseAction(action));
    }
  }

  Future<void> _showSaveDialog({bool returnToTitle = false}) async {
    if (_saveDialogRoute != null) return;
    final relay = ValueNotifier(widget.snapshot);
    final navigator = Navigator.of(context, rootNavigator: true);
    final locale = Localizations.localeOf(context);
    final mediaQuery = MediaQuery.of(context);
    final route = DialogRoute<void>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierDismissible: false,
      barrierColor:
          PokeMapPlayerMenuTheme.resolve(context).shadow.withValues(alpha: .32),
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      builder: (context) => Localizations.override(
        context: context,
        locale: locale,
        delegates: PokeMapPlayerLocalizations.localizationsDelegates,
        child: MediaQuery(
          data: mediaQuery,
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.confirmation,
            child: PlayerSaveDialog(
              snapshot: relay,
              controlProfile: widget.controlProfile,
              hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
              returnToTitle: returnToTitle,
              onSave: returnToTitle && widget.onReturnToTitle == null
                  ? null
                  : () => returnToTitle
                      ? widget.onReturnToTitle!(true)
                      : widget.onAction(RuntimePlayerAction.save),
              onDiscard: widget.onReturnToTitle == null
                  ? null
                  : () => widget.onReturnToTitle!(false),
              onReceiptShown: (receipt) => _shownSaveReceipt = receipt,
            ),
          ),
        ),
      ),
    );
    setState(() {
      _dialogSnapshot = relay;
      _saveDialogRoute = route;
    });
    await navigator.push(route);
    if (mounted && identical(_saveDialogRoute, route)) {
      setState(() {
        _dialogSnapshot = null;
        _saveDialogRoute = null;
      });
    }
    await route.completed;
    relay.dispose();
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
    for (final availability in widget.snapshot.actions) {
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
