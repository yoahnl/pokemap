import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'avelune/appearance/avelune_appearance_controller.dart';
import 'avelune/appearance/avelune_appearance_preferences.dart';
import 'avelune/appearance/avelune_appearance_catalog.dart';
import 'avelune/appearance/avelune_appearance_settings.dart';
import 'avelune/settings/avelune_motion_panel.dart';
import 'avelune/settings/avelune_settings_menu.dart';
import 'avelune/settings/avelune_storage_panel.dart';
import 'avelune/avelune_game_details.dart';
import 'avelune/avelune_theme.dart';
import 'avelune/home/avelune_home_controller.dart';
import 'avelune/home/avelune_home_screen.dart';
import 'hub_dashboard_controller.dart';
import 'hub_game_views.dart';
import 'hub_install_progress.dart';

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
  final AveluneAppearanceController? appearanceController;

  /// Pinned clock for relative wording, so visual gates do not drift with the
  /// calendar. Production leaves it null and reads the wall clock.
  final DateTime? referenceTime;
  final VoidCallback? onCancelInstall;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
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
              return _HubViewportTooSmall(
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
                if (letterboxed)
                  Center(
                    child: SizedBox(
                      width: sceneWidth,
                      height: viewport.height,
                      child: scene,
                    ),
                  )
                else
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
              child: _HubStatusBanner(diagnostic: diagnostic),
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
              icon: Icons.brightness_6_rounded,
              title: french ? 'Apparence' : 'Appearance',
              subtitle: _appearanceSummary(appearance),
              onSelected: () => _openAppearance(sheetContext, appearance),
            ),
          AveluneSettingsEntry(
            id: 'storage',
            icon: Icons.inventory_2_rounded,
            title: french ? 'Stockage' : 'Storage',
            subtitle: french
                ? '$games ${games == 1 ? 'jeu' : 'jeux'} · '
                    '${_formatBytes(sheetContext, storage.usedBytes)} utilisé'
                : '$games ${games == 1 ? 'game' : 'games'} · '
                    '${_formatBytes(sheetContext, storage.usedBytes)} used',
            onSelected: () => AveluneSheet.show<void>(
              context: sheetContext,
              title: french ? 'Stockage' : 'Storage',
              builder: (context) => AveluneStoragePanel(
                gameCount: games,
                usedLabel: _formatBytes(context, storage.usedBytes),
                availableLabel:
                    available == null ? null : _formatBytes(context, available),
              ),
            ),
          ),
          AveluneSettingsEntry(
            id: 'motion',
            icon: Icons.animation_rounded,
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
            icon: Icons.monitor_heart_rounded,
            title: french ? 'Diagnostics' : 'Diagnostics',
            subtitle: errors == 0
                ? (french ? 'Aucun incident signalé' : 'No incident reported')
                : (french
                    ? '$errors ${errors == 1 ? 'alerte' : 'alertes'}'
                    : '$errors ${errors == 1 ? 'alert' : 'alerts'}'),
            onSelected: () => AveluneSheet.show<void>(
              context: sheetContext,
              title: french ? 'Diagnostics' : 'Diagnostics',
              builder: (context) => _HubDiagnostics(snapshot: snapshot),
            ),
          ),
        ],
      ),
    );
  }

  String _appearanceSummary(AveluneAppearanceController controller) {
    final preferences = controller.state.preferences;
    final background =
        AveluneAppearanceCatalog.background(preferences.backgroundId).label;
    final furniture =
        AveluneAppearanceCatalog.furnitureFinish(preferences.furnitureId).label;
    return '$background · $furniture';
  }

  void _openAppearance(
    BuildContext context,
    AveluneAppearanceController controller,
  ) {
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    AveluneSheet.show<void>(
      context: context,
      title: french ? 'Apparence' : 'Appearance',
      builder: (sheetContext) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => AveluneAppearanceSettings(
          state: controller.state,
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
            : _diagnosticMessage(context, diagnostic),
        recommendation: diagnostic == null
            ? context.playerL10n.installedDataPreserved
            : _diagnosticRecommendation(context, diagnostic),
        code: diagnostic?.code ?? 'hub.library.unavailable',
      );
    }
    final content = switch (snapshot.section) {
      HubSection.home || HubSection.library => _AveluneHomeContent(
          productName: productName,
          snapshot: snapshot,
          actions: actions,
          homeController: homeController,
          appearanceController: appearanceController,
          referenceTime: referenceTime,
        ),
      HubSection.preferences => _AvelunePreferencesContent(
          appearanceController: appearanceController,
        ),
      HubSection.diagnostics => _HubDiagnostics(snapshot: snapshot),
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

/// Shown when the window is smaller than the console geometry supports.
class _HubViewportTooSmall extends StatelessWidget {
  const _HubViewportTooSmall({
    required this.minimumWidth,
    required this.minimumHeight,
  });

  final double minimumWidth;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    return ColoredBox(
      key: const ValueKey<String>('avelune-viewport-too-small'),
      color: colors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AveluneSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.aspect_ratio_rounded,
                color: colors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AveluneSpacing.md),
              Text(
                french ? 'Fenêtre trop petite' : 'Window too small',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AveluneSpacing.xs),
              Text(
                french
                    ? 'Agrandissez la fenêtre à au moins '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.'
                    : 'Resize the window to at least '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AveluneHomeContent extends StatelessWidget {
  const _AveluneHomeContent({
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

class _AvelunePreferencesContent extends StatelessWidget {
  const _AvelunePreferencesContent({
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

class _HubStatusBanner extends StatelessWidget {
  const _HubStatusBanner({required this.diagnostic});

  final HubDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PlayerSpacing.md,
            PlayerSpacing.md,
            PlayerSpacing.md,
            0,
          ),
          child: PlayerPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  color: context.playerColors.danger,
                ),
                const SizedBox(width: PlayerSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _diagnosticMessage(context, diagnostic),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: PlayerSpacing.xxs),
                      Text(
                        _diagnosticRecommendation(context, diagnostic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _HubDiagnostics extends StatelessWidget {
  const _HubDiagnostics({required this.snapshot});

  final HubDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) => PlayerSurface(
        maxWidth: 980,
        child: ListView(
          children: <Widget>[
            _HubHeader(
              title: context.playerL10n.diagnostics,
              subtitle: context.playerL10n.diagnosticsSubtitle,
            ),
            const SizedBox(height: PlayerSpacing.xl),
            PlayerPanel(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.storage_rounded,
                        color: context.playerColors.primary,
                      ),
                      const SizedBox(width: PlayerSpacing.md),
                      Expanded(child: Text(context.playerL10n.usedStorage)),
                      Text(_formatBytes(context, snapshot.storage.usedBytes)),
                    ],
                  ),
                  if (snapshot.storage.availableBytes
                      case final available?) ...<Widget>[
                    const SizedBox(height: PlayerSpacing.sm),
                    Row(
                      children: <Widget>[
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(context.playerL10n.availableStorage),
                        ),
                        Text(_formatBytes(context, available)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PlayerSpacing.md),
            if (snapshot.diagnostics.isEmpty)
              PlayerEmptyState(
                icon: Icons.verified_user_rounded,
                title: context.playerL10n.noDiagnostics,
                message: context.playerL10n.diagnosticsReady,
              )
            else
              for (final diagnostic in snapshot.diagnostics)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlayerSpacing.md),
                  child: _DiagnosticCard(diagnostic: diagnostic),
                ),
          ],
        ),
      );
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.diagnostic});

  final HubDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              switch (diagnostic.severity) {
                HubDiagnosticSeverity.information => Icons.info_outline_rounded,
                HubDiagnosticSeverity.warning => Icons.warning_amber_rounded,
                HubDiagnosticSeverity.error => Icons.error_outline_rounded,
              },
              color: switch (diagnostic.severity) {
                HubDiagnosticSeverity.information =>
                  context.playerColors.primary,
                HubDiagnosticSeverity.warning => context.playerColors.warning,
                HubDiagnosticSeverity.error => context.playerColors.danger,
              },
            ),
            const SizedBox(width: PlayerSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _diagnosticMessage(context, diagnostic),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: PlayerSpacing.xs),
                  Text(_diagnosticRecommendation(context, diagnostic)),
                  const SizedBox(height: PlayerSpacing.xs),
                  Text(
                    diagnostic.code,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (diagnostic.technicalDetails != null) ...[
                    const SizedBox(height: PlayerSpacing.sm),
                    SelectableText(
                      diagnostic.technicalDetails!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                    if (diagnostic.logPath != null) ...[
                      const SizedBox(height: PlayerSpacing.xs),
                      SelectableText(
                        'Journal : ${diagnostic.logPath}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: PlayerSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(
                            text: <String>[
                              diagnostic.technicalDetails!,
                              if (diagnostic.logPath != null)
                                'Journal : ${diagnostic.logPath}',
                            ].join('\n'),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier le diagnostic'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

String _diagnosticMessage(
  BuildContext context,
  HubDiagnostic diagnostic,
) {
  if (context.playerL10n.locale.languageCode == 'fr') {
    return diagnostic.message;
  }
  if (diagnostic.code.startsWith('install.')) {
    return switch (diagnostic.code) {
      'install.cancelled' =>
        'Installation was cancelled without changing the current game.',
      'install.incompatible' =>
        'This game is not compatible with this Hub version.',
      'install.insufficientDisk' =>
        'There is not enough storage to install this game.',
      'install.integrityFailed' ||
      'install.sourceChanged' =>
        'The package is incomplete or was modified.',
      _ => 'Installation could not be completed.',
    };
  }
  return switch (diagnostic.code) {
    'preferences.currentCorrupt' => 'The main preferences file was unreadable.',
    'preferences.backupCorrupt' => 'The preference backup was unreadable.',
    'preferences.writeFailed' => 'Preferences could not be saved.',
    'game.activityUnavailable' => 'Some game information is unavailable.',
    'storage.measurementUnavailable' => 'Storage usage cannot be measured.',
    'library.currentCorrupt' ||
    'library.backupCorrupt' =>
      'The library had to be recovered.',
    _ when diagnostic.code.startsWith('launch.') =>
      'This game cannot be launched.',
    _ => diagnostic.message,
  };
}

String _diagnosticRecommendation(
  BuildContext context,
  HubDiagnostic diagnostic,
) {
  if (context.playerL10n.locale.languageCode == 'fr') {
    return diagnostic.recommendation;
  }
  if (diagnostic.code.startsWith('install.')) {
    return diagnostic.code.contains('repair')
        ? 'Use Repair from the game details.'
        : 'The previously installed game remains available.';
  }
  return switch (diagnostic.code) {
    'preferences.currentCorrupt' => 'The latest valid settings were restored.',
    'preferences.backupCorrupt' => 'Review settings before playing.',
    'preferences.writeFailed' => 'Check storage and try again.',
    'game.activityUnavailable' => 'Verify or repair the installation.',
    'storage.measurementUnavailable' =>
      'Check permissions for the application data folder.',
    'library.currentCorrupt' ||
    'library.backupCorrupt' =>
      'Verify installed games.',
    _ when diagnostic.code.startsWith('launch.') =>
      'Repair the installation before playing.',
    _ => diagnostic.recommendation,
  };
}

String _formatBytes(BuildContext context, int bytes) {
  final french = context.playerL10n.locale.languageCode == 'fr';
  if (bytes < 1024) return '$bytes ${french ? 'o' : 'B'}';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} ${french ? 'Ko' : 'kB'}';
  final mib = kib / 1024;
  if (mib < 1024) return '${mib.toStringAsFixed(1)} ${french ? 'Mo' : 'MB'}';
  return '${(mib / 1024).toStringAsFixed(1)} ${french ? 'Go' : 'GB'}';
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
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
