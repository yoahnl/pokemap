import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_action_availability.dart';
import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_pause_surface.dart';
import 'runtime_player_detail_router.dart';
import 'runtime_player_focus_controller.dart';
import 'runtime_player_pause_shell.dart';
import 'runtime_player_pokedex.dart';

@immutable
final class PlayerPausePreviewEntryData {
  const PlayerPausePreviewEntryData({
    required this.id,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.progress,
    this.pokedexEntry,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final double? progress;
  final RuntimePlayerPokedexEntrySnapshot? pokedexEntry;
}

@immutable
final class PlayerPausePreviewDetailData {
  const PlayerPausePreviewDetailData({
    required this.action,
    required this.title,
    required this.message,
    this.profile,
    this.entries = const <PlayerPausePreviewEntryData>[],
  });

  factory PlayerPausePreviewDetailData.demonstrationProfile() =>
      PlayerPausePreviewDetailData(
        action: PlayerPauseAction.profile,
        title: 'Profil',
        message: 'Profil de démonstration, aperçu uniquement.',
        profile: RuntimePlayerProfileSnapshot(
          playerName: 'Camille',
          currentMapId: 'preview-village',
          money: 3000,
          playtimeSeconds: 1800,
          locationName: 'Village de démonstration',
        ),
        entries: const <PlayerPausePreviewEntryData>[
          PlayerPausePreviewEntryData(
            id: 'profile.player',
            title: 'Camille',
            subtitle: 'Village de démonstration',
          ),
        ],
      );

  final PlayerPauseAction action;
  final String title;
  final String message;
  final RuntimePlayerProfileSnapshot? profile;
  final List<PlayerPausePreviewEntryData> entries;
}

class PlayerPausePreviewShell extends StatefulWidget {
  const PlayerPausePreviewShell({
    super.key,
    required this.gameTitle,
    required this.actions,
    required this.presentation,
    required this.details,
    required this.onSelected,
  });

  final String gameTitle;
  final Map<PlayerPauseAction, PlayerActionAvailability> actions;
  final PlayerPausePresentation presentation;
  final Map<PlayerPauseAction, PlayerPausePreviewDetailData> details;
  final ValueChanged<PlayerPauseAction> onSelected;

  @override
  State<PlayerPausePreviewShell> createState() =>
      _PlayerPausePreviewShellState();
}

class _PlayerPausePreviewShellState extends State<PlayerPausePreviewShell> {
  late final RuntimePlayerFocusController _focusController;
  final _pokedexNavigation = RuntimePlayerPokedexNavigation();
  PlayerPauseAction? _selectedAction;
  var _detailOpen = false;
  var _touchControlsOpacity = .82;

  @override
  void initState() {
    super.initState();
    _focusController = RuntimePlayerFocusController();
  }

  @override
  void didUpdateWidget(covariant PlayerPausePreviewShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedAction;
    if (selected != null &&
        (!widget.presentation.visibleActions.contains(selected) ||
            widget.actions[selected]?.isEnabled != true ||
            !widget.details.containsKey(selected))) {
      _selectedAction = null;
      _detailOpen = false;
    }
  }

  @override
  void dispose() {
    _pokedexNavigation.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAction;
    final detailData = selected == null ? null : widget.details[selected];
    final detailOpen = _detailOpen && selected != null && detailData != null;
    return RuntimePlayerPauseShell(
      gameTitle: widget.gameTitle,
      pauseSection:
          detailOpen ? _sectionFor(selected) : RuntimePlayerPauseSection.root,
      actions: widget.actions,
      playerProfile: widget.details[PlayerPauseAction.profile]?.profile,
      presentation: widget.presentation,
      focusController: _focusController,
      logicalSelectionId: selected == null ? null : 'pause.${selected.name}',
      onSelected: _openDetail,
      onBackToRoot: _backToRoot,
      onTouchMenu: _backToRoot,
      detailTitle: detailOpen
          ? widget.presentation.label(selected, context.playerL10n)
          : null,
      detailSurfaceRole: detailOpen ? _surfaceRoleFor(selected) : null,
      detailOwnsScroll: detailOpen && _detailOwnsScroll(selected),
      detailActions: detailOpen &&
              _detailOwnsScroll(selected) &&
              widget.presentation.style !=
                  ProjectPauseMenuStyle.nightIllustrated
          ? PlayerActionButton(
              key: const ValueKey('runtime-pause-back-to-root'),
              label: context.playerL10n.back,
              icon: Icons.arrow_back_rounded,
              onPressed: _backToRoot,
            )
          : null,
      detail: detailOpen
          ? _PlayerPausePreviewDetail(
              key: ValueKey<String>(
                'player-pause-preview-detail-${selected.name}',
              ),
              gameTitle: widget.gameTitle,
              data: detailData,
              pokedexNavigation: _pokedexNavigation,
              touchControlsOpacity: _touchControlsOpacity,
              onTouchControlsOpacityChanged: (value) {
                setState(() => _touchControlsOpacity = value);
              },
            )
          : const SizedBox.shrink(),
    );
  }

  void _openDetail(PlayerPauseAction action) {
    if (widget.actions[action]?.isEnabled != true ||
        !widget.details.containsKey(action)) {
      return;
    }
    widget.onSelected(action);
    setState(() {
      _selectedAction = action;
      _detailOpen = true;
    });
  }

  void _backToRoot() {
    if (!_detailOpen) return;
    if (_selectedAction == PlayerPauseAction.pokedex &&
        _pokedexNavigation.back()) {
      return;
    }
    setState(() => _detailOpen = false);
  }
}

class _PlayerPausePreviewDetail extends StatelessWidget {
  const _PlayerPausePreviewDetail({
    super.key,
    required this.gameTitle,
    required this.data,
    required this.pokedexNavigation,
    required this.touchControlsOpacity,
    required this.onTouchControlsOpacityChanged,
  });

  final String gameTitle;
  final PlayerPausePreviewDetailData data;
  final RuntimePlayerPokedexNavigation pokedexNavigation;
  final double touchControlsOpacity;
  final ValueChanged<double> onTouchControlsOpacityChanged;

  @override
  Widget build(BuildContext context) {
    final router = RuntimePlayerDetailRouter(
      snapshot: _snapshot(
        gameTitle,
        data,
        touchControlsOpacity,
        Localizations.localeOf(context).toLanguageTag(),
      ),
      pokedexNavigation: pokedexNavigation,
      onPreferencesChanged: (preferences) => onTouchControlsOpacityChanged(
        preferences.touchControlsOpacity,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: PlayerBadge(
            label: 'Aperçu uniquement',
            icon: Icons.visibility_rounded,
            tone: PlayerBadgeTone.warning,
          ),
        ),
        const SizedBox(height: PlayerSpacing.sm),
        if (_isRuntimeSection(data.action))
          _detailOwnsScroll(data.action) ? Expanded(child: router) : router
        else
          PlayerEmptyState(
            icon: _icon(data.action),
            title: data.title,
            message: data.message,
          ),
      ],
    );
  }
}

RuntimePlayerSnapshot _snapshot(
  String gameTitle,
  PlayerPausePreviewDetailData data,
  double touchControlsOpacity,
  String locale,
) {
  final section = _sectionFor(data.action);
  return RuntimePlayerSnapshot(
    revision: 1,
    phase: RuntimePlayerPhase.paused,
    gameTitle: gameTitle,
    pauseSection: section,
    preferences: section == RuntimePlayerPauseSection.options
        ? PlayerPreferencesSnapshot(
            locale: locale,
            accessibility: const GameSessionAccessibilityOptions(),
            touchControlsOpacity: touchControlsOpacity,
          )
        : null,
    actions: <RuntimePlayerActionAvailability>[
      if (section == RuntimePlayerPauseSection.quests)
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openQuests,
          reason: 'Le journal de quêtes n’est pas encore disponible.',
        )
      else
        RuntimePlayerActionAvailability.enabled(_runtimeActionFor(section)),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.updatePreferences,
      ),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.returnToPauseRoot,
      ),
    ],
    pauseDetails: <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      if (section != RuntimePlayerPauseSection.options)
        section: RuntimePlayerPauseDetailSnapshot(
          section: section,
          title: data.title,
          profile: data.profile,
          message:
              section == RuntimePlayerPauseSection.map ? data.message : null,
          entries: <RuntimePlayerDetailEntrySnapshot>[
            for (final entry in data.entries)
              RuntimePlayerDetailEntrySnapshot(
                id: entry.id,
                title: entry.title,
                subtitle: entry.subtitle,
                trailingLabel: entry.trailingLabel,
                progress: entry.progress,
                pokedexEntry: entry.pokedexEntry,
              ),
          ],
        ),
    },
  );
}

bool _detailOwnsScroll(PlayerPauseAction action) =>
    action == PlayerPauseAction.pokedex || action == PlayerPauseAction.profile;

bool _isRuntimeSection(PlayerPauseAction action) => switch (action) {
      PlayerPauseAction.party ||
      PlayerPauseAction.bag ||
      PlayerPauseAction.pokedex ||
      PlayerPauseAction.map ||
      PlayerPauseAction.quests ||
      PlayerPauseAction.profile ||
      PlayerPauseAction.options =>
        true,
      PlayerPauseAction.resume ||
      PlayerPauseAction.save ||
      PlayerPauseAction.returnToTitle =>
        false,
    };

RuntimePlayerPauseSection _sectionFor(PlayerPauseAction action) =>
    switch (action) {
      PlayerPauseAction.party => RuntimePlayerPauseSection.party,
      PlayerPauseAction.bag => RuntimePlayerPauseSection.bag,
      PlayerPauseAction.pokedex => RuntimePlayerPauseSection.pokedex,
      PlayerPauseAction.map => RuntimePlayerPauseSection.map,
      PlayerPauseAction.quests => RuntimePlayerPauseSection.quests,
      PlayerPauseAction.profile => RuntimePlayerPauseSection.profile,
      PlayerPauseAction.options => RuntimePlayerPauseSection.options,
      PlayerPauseAction.resume ||
      PlayerPauseAction.save ||
      PlayerPauseAction.returnToTitle =>
        RuntimePlayerPauseSection.options,
    };

RuntimePlayerAction _runtimeActionFor(RuntimePlayerPauseSection section) =>
    switch (section) {
      RuntimePlayerPauseSection.party => RuntimePlayerAction.openParty,
      RuntimePlayerPauseSection.bag => RuntimePlayerAction.openBag,
      RuntimePlayerPauseSection.pokedex => RuntimePlayerAction.openPokedex,
      RuntimePlayerPauseSection.map => RuntimePlayerAction.openMap,
      RuntimePlayerPauseSection.quests => RuntimePlayerAction.openQuests,
      RuntimePlayerPauseSection.profile => RuntimePlayerAction.openProfile,
      RuntimePlayerPauseSection.options => RuntimePlayerAction.openOptions,
      RuntimePlayerPauseSection.root => throw StateError(
          'The root has no runtime detail action.',
        ),
    };

ProjectPresentationSurfaceRole _surfaceRoleFor(PlayerPauseAction action) =>
    switch (action) {
      PlayerPauseAction.party => ProjectPresentationSurfaceRole.party,
      PlayerPauseAction.bag => ProjectPresentationSurfaceRole.bag,
      PlayerPauseAction.pokedex => ProjectPresentationSurfaceRole.pokedex,
      PlayerPauseAction.map => ProjectPresentationSurfaceRole.map,
      PlayerPauseAction.quests => ProjectPresentationSurfaceRole.pauseMenu,
      PlayerPauseAction.profile => ProjectPresentationSurfaceRole.pauseMenu,
      PlayerPauseAction.options => ProjectPresentationSurfaceRole.options,
      PlayerPauseAction.resume ||
      PlayerPauseAction.save ||
      PlayerPauseAction.returnToTitle =>
        ProjectPresentationSurfaceRole.pauseMenu,
    };

IconData _icon(PlayerPauseAction action) => switch (action) {
      PlayerPauseAction.resume => Icons.play_arrow_rounded,
      PlayerPauseAction.save => Icons.save_rounded,
      PlayerPauseAction.returnToTitle => Icons.logout_rounded,
      _ => Icons.visibility_rounded,
    };
