
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/presentation/features/settings/pages/avelune_appearance_settings_page.dart';
import 'package:pokemap_hub/presentation/features/settings/widgets/avelune_motion_panel.dart';
import 'package:pokemap_hub/presentation/features/settings/pages/avelune_settings_menu.dart';
import 'package:pokemap_hub/presentation/features/settings/widgets/avelune_storage_panel.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_controller.dart';
import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/presentation/features/installation/widgets/hub_install_progress.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
import 'package:pokemap_hub/presentation/shell/hub_shell_diagnostics.dart';
import 'package:pokemap_hub/presentation/shell/hub_shell_layout.dart';
import 'package:pokemap_hub/presentation/shell/hub_shell_sections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single shell for every platform.
///
/// Desktop used to get its own interface — navigation rail, library grid, game
/// detail view and a preferences form — while phones got the Avelune room. That
/// second interface is gone: there is one console experience, and desktop
/// renders exactly what mobile renders.
class HubShell extends StatelessWidget {
  const HubShell({
    super.key,
    this.productName = 'PokeMap Hub',
    required this.snapshot,
    required this.actions,
    required this.onSectionSelected,
    this.homeController,
    this.appearanceController,
    this.referenceTime,
    this.onCancelInstall,
  });

  final String productName;
  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final ValueChanged<HubSection> onSectionSelected;
  final AveluneHomeController? homeController;
  final AveluneAppearanceNotifier? appearanceController;

  /// Pinned clock for relative wording, so visual gates do not drift with the
  /// calendar. Production leaves it null and reads the wall clock.
  final DateTime? referenceTime;
  final VoidCallback? onCancelInstall;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    // No Scaffold: the console owns the whole window, and a Scaffold only adds
    // Material's background, its safe-area handling and its snackbar host —
    // none of which this shell uses.
    return ColoredBox(
      color: colors.canvas,
      // Scaffold's Material was also supplying the inherited text style. Text
      // with no explicit style fell back to the platform default the moment it
      // went away, so the shell states it itself.
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium ??
            TextStyle(color: colors.textPrimary),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: colors.background,
          systemNavigationBarColor: colors.background,
          systemNavigationBarDividerColor: colors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final viewport = Size(
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : mediaQuery.size.width,
              constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : mediaQuery.size.height,
            );
            final letterboxWidth = viewport.height * kAvelunePortraitAspectRatio;
            final letterboxed = viewport.width > letterboxWidth + 0.5;
            final sceneWidth = letterboxed ? letterboxWidth : viewport.width;
            // A letterboxed scene no longer touches the left and right screen
            // edges, so the horizontal display cutouts do not apply to it.
            final padding = letterboxed
                ? mediaQuery.padding.copyWith(left: 0, right: 0)
                : mediaQuery.padding;

            if (!_fitsConsole(Size(sceneWidth, viewport.height), padding)) {
              return HubViewportTooSmall(
                minimumWidth: AveluneBreakpoints.minimumContentWidth,
                minimumHeight: AveluneBreakpoints.minimumContentHeight,
              );
            }

            final scene = MediaQuery(
              data: mediaQuery.copyWith(padding: padding, viewPadding: padding),
              child: _consoleShell(context),
            );

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (letterboxed) ...<Widget>[
                  AveluneLetterboxBackdrop(
                    appearanceController: appearanceController,
                  ),
                  Center(
                    child: SizedBox(
                      width: sceneWidth,
                      height: viewport.height,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: colors.canvas.withValues(alpha: 0.72),
                              blurRadius: 48,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: scene,
                      ),
                    ),
                  ),
                ] else
                  scene,
                if (snapshot.status == HubDashboardStatus.installing)
                  HubInstallProgressScreen(
                    progress: snapshot.installProgress,
                    onCancel: onCancelInstall,
                  ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  /// The room geometry rejects viewports below its minimum content box. Desktop
  /// windows resize freely, so the shell has to check before handing it one.
  bool _fitsConsole(Size scene, EdgeInsets padding) =>
      scene.width - padding.horizontal >=
          AveluneBreakpoints.minimumContentWidth &&
      scene.height - padding.vertical >=
          AveluneBreakpoints.minimumContentHeight;

  Widget _consoleShell(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _content(context),
          // Floated, not stacked in a Column: the room geometry rejects a
          // viewport it cannot fit the console into, so anything that shaved
          // height off the scene would make the whole home throw.
          if (_bannerDiagnostic case final diagnostic?)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: HubStatusBanner(diagnostic: diagnostic),
            ),
          // The room scene owns the whole viewport and the navigation floats
          // above it. Laying them out in a Column instead would remove the
          // navigation height from the scene while AveluneHomeGeometry still
          // subtracts the safe-area insets and reserves `navigationRect`,
          // double-counting the same band and dropping a 393x852 iPhone to the
          // compact class.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Builder(
              // The approved sheet floats over the room, so opening settings is
              // not a navigation change: the Home tab stays selected and the
              // scene stays mounted behind the barrier.
              builder: (navContext) => AveluneBottomNavigation(
                selectedItem: AveluneNavigationItem.home,
                onItemSelected: (item) {
                  if (item == AveluneNavigationItem.settings) {
                    _openSettings(navContext);
                  }
                },
              ),
            ),
          ),
        ],
      );

  /// Opens the approved settings sheet over the room.
  void _openSettings(BuildContext context) {
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final storage = snapshot.storage;
    final available = storage.availableBytes;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final appearance = appearanceController;
    final games = snapshot.games.length;
    final errors = snapshot.diagnostics
        .where((diagnostic) => diagnostic.severity != HubDiagnosticSeverity.information)
        .length;

    AveluneSheet.show<void>(
      context: context,
      title: french ? 'Paramètres Avelune' : 'Avelune settings',
      builder: (sheetContext) => AveluneSettingsMenu(
        caption: french
            ? 'Réglages locaux de votre console.'
            : 'Local settings for your console.',
        entries: <AveluneSettingsEntry>[
          // Omitted outright when no controller is wired: a row that could only
          // open an unresolvable spinner is worse than no row.
          if (appearance != null)
            AveluneSettingsEntry(
              id: 'appearance',
              icon: AveluneIcons.appearance,
              title: french ? 'Apparence' : 'Appearance',
              subtitle: _appearanceSummary(
                ProviderScope.containerOf(context)
                    .read(aveluneAppearanceNotifierProvider),
              ),
              onSelected: () => _openAppearance(sheetContext, appearance),
            ),
          AveluneSettingsEntry(
            id: 'storage',
            icon: AveluneIcons.storage,
            title: french ? 'Stockage' : 'Storage',
            subtitle: french
                ? '$games ${games == 1 ? 'jeu' : 'jeux'} · '
                    '${formatStorageBytes(sheetContext, storage.usedBytes)} utilisé'
                : '$games ${games == 1 ? 'game' : 'games'} · '
                    '${formatStorageBytes(sheetContext, storage.usedBytes)} used',
            onSelected: () => AveluneSheet.show<void>(
              context: sheetContext,
              title: french ? 'Stockage' : 'Storage',
              builder: (context) => AveluneStoragePanel(
                gameCount: games,
                usedLabel: formatStorageBytes(context, storage.usedBytes),
                availableLabel:
                    available == null ? null : formatStorageBytes(context, available),
              ),
            ),
          ),
          AveluneSettingsEntry(
            id: 'motion',
            icon: AveluneIcons.motion,
            title: french ? 'Mouvement' : 'Motion',
            subtitle: aveluneMotionSummary(reducedMotion, french: french),
            onSelected: () => AveluneSheet.show<void>(
              context: sheetContext,
              title: french ? 'Mouvement' : 'Motion',
              builder: (context) =>
                  AveluneMotionPanel(reducedMotion: reducedMotion),
            ),
          ),
          AveluneSettingsEntry(
            id: 'diagnostics',
            icon: AveluneIcons.diagnostics,
            title: french ? 'Diagnostics' : 'Diagnostics',
            subtitle: errors == 0
                ? (french ? 'Aucun incident signalé' : 'No incident reported')
                : (french
                    ? '$errors ${errors == 1 ? 'alerte' : 'alertes'}'
                    : '$errors ${errors == 1 ? 'alert' : 'alerts'}'),
            onSelected: () => AveluneSheet.show<void>(
              context: sheetContext,
              title: french ? 'Diagnostics' : 'Diagnostics',
              builder: (context) => HubDiagnostics(snapshot: snapshot),
            ),
          ),
        ],
      ),
    );
  }

  String _appearanceSummary(AveluneAppearanceState state) {
    final preferences = state.preferences;
    final background =
        AveluneAppearanceCatalog.background(preferences.backgroundId).label;
    final furniture =
        AveluneAppearanceCatalog.furnitureFinish(preferences.furnitureId).label;
    return '$background · $furniture';
  }

  void _openAppearance(
    BuildContext context,
    AveluneAppearanceNotifier controller,
  ) {
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    AveluneSheet.show<void>(
      context: context,
      title: french ? 'Apparence' : 'Appearance',
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) => AveluneAppearanceSettings(
          state: ref.watch(aveluneAppearanceNotifierProvider),
          onBackgroundSelected: controller.selectBackground,
          onFurnitureSelected: controller.selectFurniture,
          onImportCustomBackground: controller.importCustomBackground,
          onRemoveCustomBackground: controller.removeCustomBackground,
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (snapshot.status == HubDashboardStatus.loading ||
        snapshot.status == HubDashboardStatus.idle) {
      return PlayerSurface(
        child: Center(
          child: PlayerProgressCard(
            title: context.playerL10n.loading,
            stage: context.playerL10n.openingLibrary,
          ),
        ),
      );
    }
    final emptyLibraryError = snapshot.diagnostics
        .where(
          (diagnostic) => diagnostic.severity == HubDiagnosticSeverity.error,
        )
        .firstOrNull;
    if (snapshot.status == HubDashboardStatus.error &&
        snapshot.games.isEmpty &&
        emptyLibraryError?.code.startsWith('importPicker.') != true) {
      final diagnostic = emptyLibraryError;
      return PlayerErrorSurface(
        title: context.playerL10n.hubAttentionTitle,
        message: diagnostic == null
            ? context.playerL10n.libraryUnavailable
            : diagnosticMessage(context, diagnostic),
        recommendation: diagnostic == null
            ? context.playerL10n.installedDataPreserved
            : diagnosticRecommendation(context, diagnostic),
        code: diagnostic?.code ?? 'hub.library.unavailable',
      );
    }
    final content = switch (snapshot.section) {
      HubSection.home || HubSection.library => AveluneHomeContent(
          productName: productName,
          snapshot: snapshot,
          actions: actions,
          homeController: homeController,
          appearanceController: appearanceController,
          referenceTime: referenceTime,
        ),
      HubSection.preferences => AvelunePreferencesContent(
          appearanceController: appearanceController,
        ),
      HubSection.diagnostics => HubDiagnostics(snapshot: snapshot),
    };
    return content;
  }

  /// Error worth surfacing over the scene, if any.
  HubDiagnostic? get _bannerDiagnostic =>
      snapshot.status == HubDashboardStatus.error
          ? snapshot.diagnostics
              .where(
                (diagnostic) =>
                    diagnostic.severity == HubDiagnosticSeverity.error,
              )
              .firstOrNull
          : null;

}

/// Fills the space beside a letterboxed scene with the room itself, blurred.
///
/// A landscape window cannot hold the portrait console, so the sides were flat
/// black bars. Extending the player's own chosen background reads as the rest of
/// the room falling out of focus instead of as dead space.
