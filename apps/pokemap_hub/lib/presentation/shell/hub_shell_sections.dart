import 'dart:io';
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/settings/pages/avelune_appearance_settings_page.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_details.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_controller.dart';
import 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';

/// Per-section content of the Hub shell, plus its header.
///
/// Split out of hub_shell.dart. These widgets were private; Dart privacy is
/// library-scoped, so crossing a file requires them to be public.

class AveluneHomeContent extends StatelessWidget {
  const AveluneHomeContent({
    required this.productName,
    this.referenceTime,
    required this.snapshot,
    required this.actions,
    required this.homeController,
    required this.appearanceController,
  });

  final String productName;
  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final AveluneHomeController? homeController;
  final AveluneAppearanceController? appearanceController;
  final DateTime? referenceTime;

  @override
  Widget build(BuildContext context) {
    final controller = homeController;
    final appearance = appearanceController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        if (appearance != null) {
          return ListenableBuilder(
            listenable: appearance,
            builder: (context, _) {
              final state = appearance.state;
              return AveluneHomeScreen(
                key: const ValueKey<String>('avelune-home-screen'),
                viewData: viewData,
                productName: productName,
                referenceTime: referenceTime,
                appearance: state.preferences,
                customBackground: state.customBackgroundPath != null
                    ? FileImage(File(state.customBackgroundPath!))
                    : null,
                onGameSelected: (game) => controller.selectGame(game.id),
                onShowDetails: (game) => _showDetails(context, game.id),
                onAddGame: viewData.canImport
                    ? () => controller.requestImport()
                    : null,
                onContinue: (game) {
                  final source = _findSource(game.id);
                  if (source != null) actions.onContinue?.call(source);
                },
                onNewGame: (game) {
                  final source = _findSource(game.id);
                  if (source != null) actions.onNewGame?.call(source);
                },
              );
            },
          );
        }
        return AveluneHomeScreen(
          key: const ValueKey<String>('avelune-home-screen'),
          viewData: viewData,
          productName: productName,
          referenceTime: referenceTime,
          appearance: const AveluneAppearancePreferences(),
          onGameSelected: (game) => controller.selectGame(game.id),
          onShowDetails: (game) => _showDetails(context, game.id),
          onAddGame:
              viewData.canImport ? () => controller.requestImport() : null,
          onContinue: (game) {
            final source = _findSource(game.id);
            if (source != null) actions.onContinue?.call(source);
          },
          onNewGame: (game) {
            final source = _findSource(game.id);
            if (source != null) actions.onNewGame?.call(source);
          },
        );
      },
    );
  }

  /// Opens the real game details screen for [gameId].
  ///
  /// The prototype exposes this through a visible control on the hero details
  /// panel as well as the hero long press. Before AVELUNE-500 finished the
  /// cutover, neither gesture was wired on the production path at all.
  void _showDetails(BuildContext context, String gameId) {
    final source = _findSource(gameId);
    if (source == null) return;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: 'avelune-game-details'),
        transitionDuration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
        reverseTransitionDuration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => AveluneGameDetailsScreen(
          game: source,
          referenceTime: referenceTime ?? DateTime.now(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          if (reducedMotion) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  HubGameView? _findSource(String gameId) {
    for (final game in snapshot.games) {
      if (game.game.gameId == gameId) return game;
    }
    return null;
  }
}

class AvelunePreferencesContent extends StatelessWidget {
  const AvelunePreferencesContent({
    required this.appearanceController,
  });

  final AveluneAppearanceController? appearanceController;

  @override
  Widget build(BuildContext context) {
    final controller = appearanceController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AveluneAppearanceSettings(
        state: controller.state,
        onBackgroundSelected: (id) => controller.selectBackground(id),
        onFurnitureSelected: (id) => controller.selectFurniture(id),
        onImportCustomBackground: () => controller.importCustomBackground(),
        onRemoveCustomBackground: () => controller.removeCustomBackground(),
      ),
    );
  }
}

class HubHeader extends StatelessWidget {
  const HubHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: PlayerSpacing.xxs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        ],
      );
}
