import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';
import 'package:pokemap_hub/presentation/features/settings/pages/avelune_appearance_settings_page.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_details.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_controller.dart';
import 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_feedback.dart';
import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

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
  final AveluneAppearanceNotifier? appearanceController;
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
          return Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(aveluneAppearanceNotifierProvider);
              return _AveluneFeedbackHost(
                preferences: snapshot.preferences,
                builder: (feedback) => AveluneHomeScreen(
                  key: const ValueKey<String>('avelune-home-screen'),
                  viewData: viewData,
                  productName: productName,
                  referenceTime: referenceTime,
                  appearance: state.preferences,
                  customBackground: state.customBackgroundPath != null
                      ? requireLocalArtworkImage(state.customBackgroundPath!)
                      : null,
                  feedback: feedback,
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
                ),
              );
            },
          );
        }
        return _AveluneFeedbackHost(
          preferences: snapshot.preferences,
          builder: (feedback) => AveluneHomeScreen(
            key: const ValueKey<String>('avelune-home-screen'),
            viewData: viewData,
            productName: productName,
            referenceTime: referenceTime,
            appearance: const AveluneAppearancePreferences(),
            feedback: feedback,
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
          ),
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
        reverseTransitionDuration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => AveluneGameDetailsScreen(
          game: source,
          referenceTime: referenceTime ?? DateTime.now(),
          onDelete: actions.onUninstall == null
              ? null
              : () => actions.onUninstall!(source),
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

class _AveluneFeedbackHost extends StatefulWidget {
  const _AveluneFeedbackHost({
    required this.preferences,
    required this.builder,
  });

  final PlayerPreferences preferences;
  final Widget Function(AveluneFeedback feedback) builder;

  @override
  State<_AveluneFeedbackHost> createState() => _AveluneFeedbackHostState();
}

class _AveluneFeedbackHostState extends State<_AveluneFeedbackHost> {
  late final AveluneSystemFeedback _feedback;

  @override
  void initState() {
    super.initState();
    _feedback = AveluneSystemFeedback(
      hapticsEnabled: () => widget.preferences.hapticsEnabled,
      clickSoundEnabled: () =>
          widget.preferences.masterVolume > 0 &&
          widget.preferences.effectsVolume > 0,
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(_feedback);
}

class AvelunePreferencesContent extends StatelessWidget {
  const AvelunePreferencesContent({
    required this.appearanceController,
  });

  final AveluneAppearanceNotifier? appearanceController;

  @override
  Widget build(BuildContext context) {
    final controller = appearanceController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Consumer(
      builder: (context, ref, _) => AveluneAppearanceSettings(
        state: ref.watch(aveluneAppearanceNotifierProvider),
        onBackgroundSelected: (id) => controller.selectBackground(id),
        onFurnitureSelected: (id) => controller.selectFurniture(id),
        onImportFromPhotoLibrary: () => controller.importCustomBackground(
          AveluneBackgroundSource.photoLibrary,
        ),
        onImportFromFiles: () => controller.importCustomBackground(
          AveluneBackgroundSource.files,
        ),
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
