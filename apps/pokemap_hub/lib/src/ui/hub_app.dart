import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'hub_dashboard_controller.dart';
import 'hub_game_views.dart';
import 'hub_shell.dart';

/// Player application root. Platform composition injects package picking,
/// install/maintenance, and session launch actions.
class PokeMapHubApp extends StatefulWidget {
  const PokeMapHubApp({
    super.key,
    required this.controller,
    this.actions = const HubUiActions(),
    this.initializeController = true,
  });

  final HubDashboardController controller;
  final HubUiActions actions;
  final bool initializeController;

  @override
  State<PokeMapHubApp> createState() => _PokeMapHubAppState();
}

class _PokeMapHubAppState extends State<PokeMapHubApp> {
  @override
  void initState() {
    super.initState();
    if (widget.initializeController) {
      unawaited(widget.controller.initialize());
    }
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
            home: HubShell(
              snapshot: snapshot,
              actions: widget.actions,
              onSectionSelected: widget.controller.selectSection,
              onQueryChanged: widget.controller.setQuery,
              onGameSelected: widget.controller.selectGame,
              onGameDetailsClosed: widget.controller.closeGameDetails,
              onPreferencesChanged: (preferences) =>
                  unawaited(widget.controller.updatePreferences(preferences)),
              onCancelInstall: widget.controller.cancelImport,
            ),
          );
        },
      );
}
