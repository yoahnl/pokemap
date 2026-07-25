import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'hub_dashboard_controller.dart';
import 'hub_game_views.dart';
import 'hub_shell.dart';

typedef HubPlayerBuilder = Widget Function(
  BuildContext context,
  HubGameView game,
  Future<void> Function() onHubRequested,
);

/// Player application root. Platform composition injects package picking,
/// install/maintenance, and session launch actions.
class PokeMapHubApp extends StatefulWidget {
  const PokeMapHubApp({
    super.key,
    required this.controller,
    this.actions = const HubUiActions(),
    this.playerBuilder,
    this.initializeController = true,
  });

  final HubDashboardController controller;
  final HubUiActions actions;
  final HubPlayerBuilder? playerBuilder;
  final bool initializeController;

  @override
  State<PokeMapHubApp> createState() => _PokeMapHubAppState();
}

class _PokeMapHubAppState extends State<PokeMapHubApp> {
  HubGameView? _activeGame;

  @override
  void initState() {
    super.initState();
    if (widget.initializeController) {
      unawaited(widget.controller.initialize());
    }
  }

  HubUiActions get _effectiveActions {
    final actions = widget.actions;
    final playerBuilder = widget.playerBuilder;
    if (playerBuilder == null) return actions;
    return HubUiActions(
      onImportRequested: actions.onImportRequested,
      onContinue: _openPlayer,
      onNewGame: _openPlayer,
      onUpdate: actions.onUpdate,
      onRepair: actions.onRepair,
      onManageSaves: actions.onManageSaves,
      onUninstall: actions.onUninstall,
    );
  }

  void _openPlayer(HubGameView game) {
    if (_activeGame?.game.gameId == game.game.gameId) return;
    setState(() => _activeGame = game);
  }

  Future<void> _returnToHub() async {
    if (_activeGame == null) return;
    setState(() => _activeGame = null);
    await widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final snapshot = widget.controller.snapshot;
          final preferences = snapshot.preferences;
          return MaterialApp(
            title: 'PokeMap Hub',
            debugShowCheckedModeBanner: false,
            themeMode: preferences.themeMode,
            theme: PokeMapPlayerTheme.light(
              highContrast: preferences.highContrast,
              reducedMotion: preferences.reducedMotion,
            ),
            darkTheme: PokeMapPlayerTheme.dark(
              highContrast: preferences.highContrast,
              reducedMotion: preferences.reducedMotion,
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
              (final game?, final playerBuilder?) =>
                playerBuilder(context, game, _returnToHub),
              _ => HubShell(
                  snapshot: snapshot,
                  actions: _effectiveActions,
                  onSectionSelected: widget.controller.selectSection,
                  onQueryChanged: widget.controller.setQuery,
                  onGameSelected: widget.controller.selectGame,
                  onGameDetailsClosed: widget.controller.closeGameDetails,
                  onPreferencesChanged: (preferences) => unawaited(
                    widget.controller.updatePreferences(preferences),
                  ),
                  onCancelInstall: widget.controller.cancelImport,
                ),
            },
          );
        },
      );
}
