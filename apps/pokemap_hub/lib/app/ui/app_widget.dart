import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_controller.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';
import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/presentation/shell/hub_shell.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/features/session/domain/entities/hub_player_launch_intent.dart';

typedef HubPlayerBuilder = Widget Function(
  BuildContext context,
  HubGameView game,
  HubPlayerLaunchIntent intent,
  Future<void> Function() onHubRequested,
);

/// Player application root. Platform composition injects package picking,
/// install/maintenance, and session launch actions.
class PokeMapHubApp extends StatefulWidget {
  const PokeMapHubApp({
    super.key,
    required this.controller,
    this.productName = 'PokeMap Hub',
    this.actions = const HubUiActions(),
    this.playerBuilder,
    this.appearanceController,
    this.initializeController = true,
  });

  final HubDashboardController controller;
  final String productName;
  final HubUiActions actions;
  final HubPlayerBuilder? playerBuilder;
  final AveluneAppearanceController? appearanceController;
  final bool initializeController;

  @override
  State<PokeMapHubApp> createState() => _PokeMapHubAppState();
}

class _PokeMapHubAppState extends State<PokeMapHubApp> {
  HubGameView? _activeGame;
  HubPlayerLaunchIntent _activeLaunchIntent = HubPlayerLaunchIntent.title;
  bool _startupLaunchEvaluated = false;
  AveluneHomeController? _homeController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    if (widget.initializeController) {
      unawaited(widget.controller.initialize());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLaunchMostRecentGame();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHomeController();
  }

  @override
  void didUpdateWidget(covariant PokeMapHubApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      _syncHomeController();
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _activeGame = null;
    _activeLaunchIntent = HubPlayerLaunchIntent.title;
    _startupLaunchEvaluated = false;
    _syncHomeController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLaunchMostRecentGame();
    });
  }

  void _syncHomeController() {
    final snapshot = widget.controller.snapshot;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveActions = _effectiveActions;
    final existing = _homeController;
    if (existing != null) {
      existing.actions = effectiveActions;
      existing.updateSnapshot(snapshot, reducedMotion: reducedMotion);
    } else {
      _homeController = AveluneHomeController(
        snapshot: snapshot,
        actions: effectiveActions,
        reducedMotion: reducedMotion,
      );
    }
  }

  void _handleControllerChanged() {
    _syncHomeController();
    _maybeLaunchMostRecentGame();
  }

  void _maybeLaunchMostRecentGame() {
    if (!mounted || _startupLaunchEvaluated) return;
    final snapshot = widget.controller.snapshot;
    if (snapshot.status != HubDashboardStatus.ready &&
        snapshot.status != HubDashboardStatus.error) {
      return;
    }
    _startupLaunchEvaluated = true;
    if (snapshot.status != HubDashboardStatus.ready ||
        !snapshot.preferences.launchMostRecentGameOnStartup ||
        widget.playerBuilder == null) {
      return;
    }
    HubGameView? target;
    for (final game in snapshot.games) {
      if (game.activity.installationHealthy) {
        target = game;
        break;
      }
    }
    if (target != null) {
      setState(() {
        _activeGame = target;
        _activeLaunchIntent = HubPlayerLaunchIntent.title;
      });
    }
  }

  HubUiActions get _effectiveActions {
    final actions = widget.actions;
    final playerBuilder = widget.playerBuilder;
    if (playerBuilder == null) return actions;
    return HubUiActions(
      onImportRequested: actions.onImportRequested,
      onContinue: (game) => _openPlayer(
        game,
        intent: HubPlayerLaunchIntent.continueGame,
      ),
      onNewGame: (game) => _openPlayer(
        game,
        intent: HubPlayerLaunchIntent.title,
      ),
      onUpdate: actions.onUpdate,
      onRepair: actions.onRepair,
      onManageSaves: actions.onManageSaves,
      onUninstall: actions.onUninstall,
    );
  }

  void _openPlayer(
    HubGameView game, {
    required HubPlayerLaunchIntent intent,
  }) {
    if (_activeGame?.game.gameId == game.game.gameId &&
        _activeLaunchIntent == intent) {
      return;
    }
    setState(() {
      _activeGame = game;
      _activeLaunchIntent = intent;
    });
  }

  Future<void> _returnToHub() async {
    if (_activeGame == null) return;
    setState(() {
      _activeGame = null;
      _activeLaunchIntent = HubPlayerLaunchIntent.title;
    });
    await widget.controller.refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _homeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final snapshot = widget.controller.snapshot;
          final preferences = snapshot.preferences;
          return MaterialApp(
            title: widget.productName,
            debugShowCheckedModeBanner: false,
            themeMode: preferences.themeMode,
            theme: applyAveluneTheme(
              PokeMapPlayerTheme.light(
                highContrast: preferences.highContrast,
                reducedMotion: preferences.reducedMotion,
              ),
              highContrast: preferences.highContrast,
            ),
            darkTheme: applyAveluneTheme(
              PokeMapPlayerTheme.dark(
                highContrast: preferences.highContrast,
                reducedMotion: preferences.reducedMotion,
              ),
              highContrast: preferences.highContrast,
            ),
            locale: preferences.locale,
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: PlayerTextScaler(
                    systemScaler: media.textScaler,
                    preferenceScale: preferences.textScale,
                  ),
                  disableAnimations:
                      media.disableAnimations || preferences.reducedMotion,
                  highContrast: media.highContrast || preferences.highContrast,
                ),
                child: child!,
              );
            },
            home: switch ((_activeGame, widget.playerBuilder)) {
              (final game?, final playerBuilder?) => playerBuilder(
                  context,
                  game,
                  _activeLaunchIntent,
                  _returnToHub,
                ),
              _ => HubShell(
                  productName: widget.productName,
                  snapshot: snapshot,
                  actions: _effectiveActions,
                  homeController: _homeController,
                  appearanceController: widget.appearanceController,
                  onSectionSelected: widget.controller.selectSection,
                  onCancelInstall: widget.controller.cancelImport,
                ),
            },
          );
        },
      );
}
