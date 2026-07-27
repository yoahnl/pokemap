import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../display/hub_display_preferences.dart';
import '../display/hub_display_preferences_controller.dart';
import 'hub_dashboard_controller.dart';
import 'hub_game_views.dart';
import 'hub_install_progress.dart';

class HubShell extends StatelessWidget {
  const HubShell({
    super.key,
    required this.snapshot,
    required this.actions,
    required this.onSectionSelected,
    required this.onQueryChanged,
    required this.onGameSelected,
    required this.onGameDetailsClosed,
    required this.onPreferencesChanged,
    this.displayPreferencesController,
    this.onCancelInstall,
  });

  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final ValueChanged<HubSection> onSectionSelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onGameSelected;
  final VoidCallback onGameDetailsClosed;
  final ValueChanged<PlayerPreferences> onPreferencesChanged;
  final HubDisplayPreferencesController? displayPreferencesController;
  final VoidCallback? onCancelInstall;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final content = _content(context);
            final shell = wide
                ? Row(
                    children: <Widget>[
                      _navigationRail(context),
                      VerticalDivider(
                        width: 1,
                        color: context.playerColors.outline,
                      ),
                      Expanded(child: content),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Expanded(child: content),
                      _navigationBar(context),
                    ],
                  );
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                shell,
                if (snapshot.status == HubDashboardStatus.installing)
                  HubInstallProgressScreen(
                    progress: snapshot.installProgress,
                    onCancel: onCancelInstall,
                  ),
              ],
            );
          },
        ),
      );

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
    final selectedGame = snapshot.selectedGame;
    final content = selectedGame != null
        ? HubGameDetailView(
            game: selectedGame,
            actions: actions,
            onBack: onGameDetailsClosed,
          )
        : switch (snapshot.section) {
            HubSection.home => _HubHome(
                snapshot: snapshot,
                actions: actions,
                onGameSelected: onGameSelected,
              ),
            HubSection.library => _HubLibrary(
                snapshot: snapshot,
                actions: actions,
                onQueryChanged: onQueryChanged,
                onGameSelected: onGameSelected,
              ),
            HubSection.preferences => switch (displayPreferencesController) {
                final controller? => ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _HubPreferences(
                      preferences: snapshot.preferences,
                      onChanged: onPreferencesChanged,
                      displaySnapshot: controller.snapshot,
                      onDisplayChanged: (preferences) =>
                          controller.update(preferences),
                    ),
                  ),
                null => _HubPreferences(
                    preferences: snapshot.preferences,
                    onChanged: onPreferencesChanged,
                  ),
              },
            HubSection.diagnostics => _HubDiagnostics(snapshot: snapshot),
          };
    final error = snapshot.status == HubDashboardStatus.error
        ? snapshot.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.severity == HubDiagnosticSeverity.error,
            )
            .firstOrNull
        : null;
    if (error == null) return content;
    return Column(
      children: <Widget>[
        _HubStatusBanner(diagnostic: error),
        Expanded(child: content),
      ],
    );
  }

  Widget _navigationRail(BuildContext context) => NavigationRail(
        selectedIndex: snapshot.section.index,
        onDestinationSelected: (index) =>
            onSectionSelected(HubSection.values[index]),
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: PlayerSpacing.md),
          child: Semantics(
            header: true,
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.catching_pokemon_rounded,
                  color: context.playerColors.primary,
                  size: 34,
                ),
                const SizedBox(height: PlayerSpacing.xs),
                const Text(
                  'PokeMap',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        destinations: _destinations(context)
            .map(
              (destination) => NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: Text(destination.label),
              ),
            )
            .toList(growable: false),
      );

  Widget _navigationBar(BuildContext context) => NavigationBar(
        selectedIndex: snapshot.section.index,
        onDestinationSelected: (index) =>
            onSectionSelected(HubSection.values[index]),
        destinations: _destinations(context)
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
            )
            .toList(growable: false),
      );

  List<_HubDestination> _destinations(BuildContext context) {
    final l10n = context.playerL10n;
    return <_HubDestination>[
      _HubDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.home,
      ),
      _HubDestination(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
        label: l10n.library,
      ),
      _HubDestination(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
        label: l10n.preferences,
      ),
      _HubDestination(
        icon: Icons.health_and_safety_outlined,
        selectedIcon: Icons.health_and_safety_rounded,
        label: l10n.diagnostics,
      ),
    ];
  }
}

final class _HubDestination {
  const _HubDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
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

class _HubHome extends StatelessWidget {
  const _HubHome({
    required this.snapshot,
    required this.actions,
    required this.onGameSelected,
  });

  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final ValueChanged<String> onGameSelected;

  @override
  Widget build(BuildContext context) {
    final games = snapshot.games;
    final resumable =
        games.where((game) => game.activity.canContinue).firstOrNull;
    return PlayerSurface(
      maxWidth: 1320,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _HubHeader(
              title: 'PokeMap Hub',
              subtitle: context.playerL10n.hubSubtitle,
              action: PlayerActionButton(
                label: context.playerL10n.importGame,
                icon: Icons.add_box_outlined,
                onPressed: actions.onImportRequested,
                disabledReason: actions.onImportRequested == null
                    ? context.playerL10n.importUnavailable
                    : null,
              ),
            ),
          ),
          if (snapshot.diagnostics.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: PlayerSpacing.lg),
                child: _DiagnosticSummary(
                  count: snapshot.diagnostics.length,
                ),
              ),
            ),
          if (resumable != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: PlayerSpacing.xl),
                child: _ResumeCard(
                  game: resumable,
                  onPressed: actions.onContinue == null
                      ? null
                      : () => actions.onContinue!(resumable),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: PlayerSpacing.xl,
                bottom: PlayerSpacing.md,
              ),
              child: Text(
                context.playerL10n.installedGames,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          if (games.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: PlayerEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: context.playerL10n.emptyLibraryTitle,
                  message: context.playerL10n.emptyLibraryMessage,
                  action: PlayerActionButton(
                    label: context.playerL10n.importGame,
                    icon: Icons.file_open_rounded,
                    onPressed: actions.onImportRequested,
                    disabledReason: actions.onImportRequested == null
                        ? context.playerL10n.importUnavailable
                        : null,
                  ),
                ),
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 1100
                    ? 4
                    : constraints.crossAxisExtent >= 760
                        ? 3
                        : constraints.crossAxisExtent >= 500
                            ? 2
                            : 1;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      return _HomeGameCard(
                        game: game,
                        onPressed: () => onGameSelected(game.game.gameId),
                      );
                    },
                    childCount: games.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 230,
                    crossAxisSpacing: PlayerSpacing.md,
                    mainAxisSpacing: PlayerSpacing.md,
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: PlayerSpacing.xxl),
          ),
        ],
      ),
    );
  }
}

class _HomeGameCard extends StatelessWidget {
  const _HomeGameCard({required this.game, required this.onPressed});

  final HubGameView game;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey<String>('hub-game-card-${game.game.gameId}'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(PlayerRadii.md),
          child: PlayerPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(PlayerRadii.md - 1),
                    ),
                    child: HubArtwork(
                      path: game.activity.coverPath ?? game.activity.heroPath,
                      icon: Icons.landscape_rounded,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(PlayerSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        game.game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        game.game.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _HubLibrary extends StatelessWidget {
  const _HubLibrary({
    required this.snapshot,
    required this.actions,
    required this.onQueryChanged,
    required this.onGameSelected,
  });

  final HubDashboardSnapshot snapshot;
  final HubUiActions actions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onGameSelected;

  @override
  Widget build(BuildContext context) => PlayerSurface(
        maxWidth: 1320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HubHeader(
              title: context.playerL10n.library,
              subtitle:
                  context.playerL10n.installedGameCount(snapshot.games.length),
              action: PlayerActionButton(
                label: context.playerL10n.importGame,
                icon: Icons.add_box_outlined,
                onPressed: actions.onImportRequested,
                disabledReason: actions.onImportRequested == null
                    ? context.playerL10n.importUnavailable
                    : null,
              ),
            ),
            const SizedBox(height: PlayerSpacing.lg),
            TextField(
              key: const ValueKey<String>('hub-library-search'),
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: context.playerL10n.searchGames,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: context.playerColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PlayerRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: PlayerSpacing.lg),
            Expanded(
              child: HubGameGrid(
                gridKey: const ValueKey<String>('hub-library-grid'),
                games: snapshot.visibleGames,
                onSelected: onGameSelected,
                emptyState: PlayerEmptyState(
                  icon: snapshot.games.isEmpty
                      ? Icons.inventory_2_outlined
                      : Icons.search_off_rounded,
                  title: snapshot.games.isEmpty
                      ? context.playerL10n.emptyLibraryTitle
                      : context.playerL10n.noSearchResult,
                  message: snapshot.games.isEmpty
                      ? context.playerL10n.emptyLibraryMessage
                      : context.playerL10n.tryAnotherSearch,
                ),
              ),
            ),
          ],
        ),
      );
}

class _HubPreferences extends StatelessWidget {
  const _HubPreferences({
    required this.preferences,
    required this.onChanged,
    this.displaySnapshot,
    this.onDisplayChanged,
  });

  final PlayerPreferences preferences;
  final ValueChanged<PlayerPreferences> onChanged;
  final HubDisplayPreferencesSnapshot? displaySnapshot;
  final ValueChanged<HubDisplayPreferences>? onDisplayChanged;

  @override
  Widget build(BuildContext context) => PlayerSurface(
        maxWidth: 900,
        child: ListView(
          children: <Widget>[
            _HubHeader(
              title: context.playerL10n.preferences,
              subtitle: context.playerL10n.globalSettingsSubtitle,
            ),
            const SizedBox(height: PlayerSpacing.xl),
            PlayerPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.playerL10n.appearance,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  DropdownButtonFormField<PlayerLanguage>(
                    isExpanded: true,
                    initialValue: preferences.language,
                    decoration: InputDecoration(
                      labelText: context.playerL10n.language,
                    ),
                    items: <DropdownMenuItem<PlayerLanguage>>[
                      DropdownMenuItem(
                        value: PlayerLanguage.system,
                        child: Text(context.playerL10n.systemLanguage),
                      ),
                      DropdownMenuItem(
                        value: PlayerLanguage.fr,
                        child: Text('Français'),
                      ),
                      DropdownMenuItem(
                        value: PlayerLanguage.en,
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(preferences.copyWith(language: value));
                      }
                    },
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  DropdownButtonFormField<PlayerThemePreference>(
                    isExpanded: true,
                    initialValue: preferences.theme,
                    decoration: InputDecoration(
                      labelText: context.playerL10n.theme,
                    ),
                    items: <DropdownMenuItem<PlayerThemePreference>>[
                      DropdownMenuItem(
                        value: PlayerThemePreference.system,
                        child: Text(context.playerL10n.systemTheme),
                      ),
                      DropdownMenuItem(
                        value: PlayerThemePreference.light,
                        child: Text(context.playerL10n.lightTheme),
                      ),
                      DropdownMenuItem(
                        value: PlayerThemePreference.dark,
                        child: Text(context.playerL10n.darkTheme),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(preferences.copyWith(theme: value));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: PlayerSpacing.md),
            PlayerPanel(
              child: SwitchListTile.adaptive(
                key: const ValueKey<String>(
                  'hub-launch-most-recent-on-startup-toggle',
                ),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.playerL10n.launchMostRecentGameOnStartup,
                ),
                subtitle: Text(
                  context.playerL10n.launchMostRecentGameOnStartupDescription,
                ),
                value: preferences.launchMostRecentGameOnStartup,
                onChanged: (value) => onChanged(
                  preferences.copyWith(
                    launchMostRecentGameOnStartup: value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: PlayerSpacing.md),
            PlayerPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.playerL10n.accessibility,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  Text(
                    '${context.playerL10n.textSize} '
                    '${(preferences.textScale * 100).round()} %',
                  ),
                  Slider(
                    value: preferences.textScale,
                    min: 0.8,
                    max: 1.6,
                    divisions: 8,
                    label: '${(preferences.textScale * 100).round()} %',
                    onChanged: (value) =>
                        onChanged(preferences.copyWith(textScale: value)),
                  ),
                  Text(
                    '${context.playerL10n.touchControlsOpacity} '
                    '${(preferences.touchControlsOpacity * 100).round()} %',
                  ),
                  Slider(
                    key: const ValueKey<String>(
                      'hub-touch-controls-opacity-slider',
                    ),
                    value: preferences.touchControlsOpacity,
                    min: 0.3,
                    max: 1,
                    divisions: 14,
                    label:
                        '${(preferences.touchControlsOpacity * 100).round()} %',
                    onChanged: (value) => onChanged(
                      preferences.copyWith(touchControlsOpacity: value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.playerL10n.reducedMotion),
                    value: preferences.reducedMotion,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(reducedMotion: value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.playerL10n.highContrast),
                    value: preferences.highContrast,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(highContrast: value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.playerL10n.haptics),
                    value: preferences.hapticsEnabled,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(hapticsEnabled: value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.playerL10n.inputHints),
                    value: preferences.showInputHints,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(showInputHints: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PlayerSpacing.md),
            PlayerPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.playerL10n.audio,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: PlayerSpacing.md),
                  _VolumeSlider(
                    label: context.playerL10n.masterVolume,
                    value: preferences.masterVolume,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(masterVolume: value),
                    ),
                  ),
                  _VolumeSlider(
                    label: context.playerL10n.music,
                    value: preferences.musicVolume,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(musicVolume: value),
                    ),
                  ),
                  _VolumeSlider(
                    label: context.playerL10n.effects,
                    value: preferences.effectsVolume,
                    onChanged: (value) => onChanged(
                      preferences.copyWith(effectsVolume: value),
                    ),
                  ),
                ],
              ),
            ),
            if (displaySnapshot case final display?) ...<Widget>[
              const SizedBox(height: PlayerSpacing.md),
              _HubDisplayPreferencesPanel(
                snapshot: display,
                onChanged: onDisplayChanged,
              ),
            ],
            const SizedBox(height: PlayerSpacing.xl),
          ],
        ),
      );
}

class _HubDisplayPreferencesPanel extends StatelessWidget {
  const _HubDisplayPreferencesPanel({
    required this.snapshot,
    required this.onChanged,
  });

  final HubDisplayPreferencesSnapshot snapshot;
  final ValueChanged<HubDisplayPreferences>? onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerDisplayStrings.of(context);
    final supported =
        snapshot.status != HubDisplayPreferencesStatus.unsupported;
    final canUpdate = snapshot.canUpdate && onChanged != null;
    return PlayerPanel(
      key: const ValueKey<String>('hub-display-preferences'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: PlayerSpacing.md),
          if (!supported)
            PlayerEmptyState(
              icon: Icons.desktop_windows_outlined,
              title: strings.title,
              message: strings.unsupported,
            )
          else ...<Widget>[
            DropdownButtonFormField<HubDisplayMode>(
              key: const ValueKey<String>('hub-display-mode'),
              isExpanded: true,
              initialValue: snapshot.preferences.mode,
              decoration: InputDecoration(labelText: strings.mode),
              items: <DropdownMenuItem<HubDisplayMode>>[
                DropdownMenuItem(
                  value: HubDisplayMode.windowed,
                  child: Text(strings.windowed),
                ),
                DropdownMenuItem(
                  value: HubDisplayMode.fullscreen,
                  child: Text(strings.fullscreen),
                ),
              ],
              onChanged: canUpdate
                  ? (value) {
                      if (value != null) {
                        onChanged!(snapshot.preferences.copyWith(mode: value));
                      }
                    }
                  : null,
            ),
            const SizedBox(height: PlayerSpacing.md),
            DropdownButtonFormField<HubWindowSizePreset>(
              key: const ValueKey<String>('hub-window-size'),
              isExpanded: true,
              initialValue: snapshot.preferences.windowSize,
              decoration: InputDecoration(labelText: strings.windowSize),
              items: <DropdownMenuItem<HubWindowSizePreset>>[
                for (final preset in HubWindowSizePreset.values)
                  DropdownMenuItem(
                    value: preset,
                    child: Text(_presetLabel(strings, preset)),
                  ),
              ],
              onChanged: canUpdate
                  ? (value) {
                      if (value != null) {
                        onChanged!(
                          snapshot.preferences.copyWith(windowSize: value),
                        );
                      }
                    }
                  : null,
            ),
            if (snapshot.status == HubDisplayPreferencesStatus.error) ...[
              const SizedBox(height: PlayerSpacing.sm),
              Text(
                strings.applyFailed,
                key: const ValueKey<String>('hub-display-error'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.playerColors.danger,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _presetLabel(
    PlayerDisplayStrings strings,
    HubWindowSizePreset preset,
  ) {
    final label = switch (preset) {
      HubWindowSizePreset.compact => strings.compact,
      HubWindowSizePreset.balanced => strings.balanced,
      HubWindowSizePreset.spacious => strings.spacious,
    };
    final size = preset.logicalSize;
    return '$label — ${size.width.round()} × ${size.height.round()}';
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        value: '${(value * 100).round()} %',
        child: Row(
          children: <Widget>[
            SizedBox(width: 120, child: Text(label)),
            Expanded(
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${(value * 100).round()} %',
                textAlign: TextAlign.end,
              ),
            ),
          ],
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

class _DiagnosticSummary extends StatelessWidget {
  const _DiagnosticSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        child: Row(
          children: <Widget>[
            Icon(
              Icons.health_and_safety_outlined,
              color: context.playerColors.warning,
            ),
            const SizedBox(width: PlayerSpacing.md),
            Expanded(
              child: Text(
                context.playerL10n.diagnosticsToReview(count),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.game,
    required this.onPressed,
  });

  final HubGameView game;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        elevated: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.playerL10n.resumeLastGame,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.playerColors.primary,
                      ),
                ),
                const SizedBox(height: PlayerSpacing.xs),
                Text(
                  game.game.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(game.game.authorName),
              ],
            );
            final action = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: PlayerActionButton(
                label: context.playerL10n.continueGame,
                icon: Icons.play_circle_fill_rounded,
                autofocus: onPressed != null,
                onPressed: onPressed,
                disabledReason: onPressed == null
                    ? context.playerL10n.launchUnavailable
                    : null,
              ),
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      information,
                      const SizedBox(height: PlayerSpacing.lg),
                      action,
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(child: information),
                      const SizedBox(width: PlayerSpacing.lg),
                      action,
                    ],
                  );
          },
        ),
      );
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final information = Column(
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
          if (action == null) return information;
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    information,
                    const SizedBox(height: PlayerSpacing.md),
                    action!,
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: information),
                    const SizedBox(width: PlayerSpacing.lg),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: action!,
                    ),
                  ],
                );
        },
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
      'Check permissions for the PokeMap folder.',
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
