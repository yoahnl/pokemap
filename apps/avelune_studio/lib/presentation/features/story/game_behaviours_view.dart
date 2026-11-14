import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_row.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehavioursView extends StatefulWidget {
  const GameBehavioursView({
    super.key,
    required this.behaviours,
    required this.navigate,
    required this.openMap,
    this.trame,
    this.simulate,
    this.openScene,
  });

  final GameBehavioursController behaviours;
  final Future<bool> Function(String eventId) navigate;
  final VoidCallback openMap;
  final StorylineTrameController? trame;
  final Future<bool> Function(String eventId)? simulate;
  final SceneOpener? openScene;

  @override
  State<GameBehavioursView> createState() => _GameBehavioursViewState();
}

class _GameBehavioursViewState extends State<GameBehavioursView> {
  late final _search = TextEditingController(text: widget.behaviours.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final behaviours = widget.behaviours;
    if (TickerMode.valuesOf(context).enabled) {
      scheduleMicrotask(behaviours.sync);
    }
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        key: const ValueKey('behaviours-view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.l),
            child: Row(
              children: [
                Expanded(
                  child: StudioSearchField(
                    key: const ValueKey('behaviours-search'),
                    controller: _search,
                    label: l10n.behavioursSearch,
                    onChanged: behaviours.search,
                  ),
                ),
                const SizedBox(width: StudioSpacing.l),
                SegmentedButton<GameBehaviourGrouping>(
                  key: const ValueKey('behaviours-grouping'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: GameBehaviourGrouping.map,
                      label: Text(l10n.behavioursByMap),
                    ),
                    ButtonSegment(
                      value: GameBehaviourGrouping.fact,
                      label: Text(l10n.behavioursByFact),
                    ),
                    ButtonSegment(
                      value: GameBehaviourGrouping.character,
                      label: Text(l10n.behavioursByCharacter),
                    ),
                  ],
                  selected: {behaviours.grouping},
                  onSelectionChanged: (value) => behaviours.group(value.single),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
            child: Wrap(
              spacing: StudioSpacing.s,
              runSpacing: StudioSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final filter in GameBehaviourFilter.values)
                  StudioFilterChip(
                    key: ValueKey('behaviours-filter-${filter.name}'),
                    label: switch (filter) {
                      GameBehaviourFilter.withoutMap =>
                        l10n.behavioursFilterWithoutMap,
                      GameBehaviourFilter.toRepair =>
                        l10n.behavioursFilterToRepair,
                      GameBehaviourFilter.disabled =>
                        l10n.behavioursFilterDisabled,
                      GameBehaviourFilter.outsideTrame =>
                        l10n.behavioursFilterOutsideTrame,
                    },
                    selected: behaviours.filters.contains(filter),
                    onSelected:
                        filter == GameBehaviourFilter.outsideTrame &&
                            widget.trame == null
                        ? null
                        : (_) {
                            if (filter == GameBehaviourFilter.outsideTrame) {
                              unawaited(widget.trame!.open());
                            }
                            behaviours.toggle(filter);
                          },
                  ),
                Text(
                  switch (behaviours.grouping) {
                    GameBehaviourGrouping.fact => l10n.behavioursByFactHint,
                    GameBehaviourGrouping.character =>
                      l10n.behavioursByCharacterHint,
                    GameBehaviourGrouping.map => l10n.behavioursCoverage,
                  },
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (behaviours.refused.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StudioSpacing.l,
                StudioSpacing.m,
                StudioSpacing.l,
                0,
              ),
              child: StudioNotice(
                key: const ValueKey('behaviours-refused'),
                l10n.behavioursRefused,
                isError: true,
              ),
            ),
          const SizedBox(height: StudioSpacing.m),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final behaviours = widget.behaviours;
    final state =
        gameMemoryResourceState(
          context,
          behaviours.saved,
          loading: l10n.behavioursLoading,
          onRetry: behaviours.retry,
        ) ??
        switch (behaviours.grouping) {
          GameBehaviourGrouping.fact => gameMemoryResourceState(
            context,
            behaviours.usages,
            loading: l10n.behavioursFactsLoading,
            onRetry: behaviours.retryFacts,
          ),
          GameBehaviourGrouping.character =>
            gameMemoryResourceState(
                  context,
                  behaviours.directory,
                  loading: l10n.behavioursCharactersLoading,
                  onRetry: behaviours.retryDirectory,
                ) ??
                gameMemoryResourceState(
                  context,
                  behaviours.characters,
                  loading: l10n.behavioursCharactersLoading,
                  onRetry: behaviours.retryDirectory,
                ),
          GameBehaviourGrouping.map => null,
        };
    if (state != null) return state;
    if (behaviours.rows.isEmpty) {
      return StudioEmptyState(
        key: const ValueKey('behaviours-empty'),
        icon: Icons.bolt_outlined,
        title: l10n.behavioursEmpty,
        description: l10n.behavioursEmptyHint,
        action: StudioButton(
          label: l10n.behavioursOpenMap,
          icon: Icons.map_outlined,
          onPressed: widget.openMap,
        ),
      );
    }
    final trameView = widget.trame?.view;
    final groups = behaviours.groups(
      elementLabel: l10n.behaviourElement,
      outside: trameView == null
          ? null
          : (row) => row.record != null && trameView.outside(row.record!),
    );
    if (groups.isEmpty) {
      return StudioEmptyState(
        key: const ValueKey('behaviours-no-match'),
        title: l10n.behavioursNoMatch,
        description: l10n.memoryFactsNoMatchHint,
        action: StudioButton(
          label: l10n.memoryShowAll,
          variant: StudioButtonVariant.secondary,
          onPressed: () {
            _search.clear();
            behaviours.search('');
            for (final filter in [...behaviours.filters]) {
              behaviours.toggle(filter);
            }
          },
        ),
      );
    }
    final entries = <Object>[
      for (final group in groups) ...[group, ...group.rows],
    ];
    return ListView.builder(
      key: const ValueKey('behaviours-list'),
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        final GameBehaviourGroup group => _Header(group),
        final GameBehaviourRow row => GameBehaviourRowTile(
          row: row,
          summary: behaviours.summary(row),
          factName: behaviours.factName,
          onTap: () => unawaited(behaviours.reach(row.id, widget.navigate)),
          onSimulate: widget.simulate == null || row.record == null
              ? null
              : () => unawaited(behaviours.reach(row.id, widget.simulate!)),
          onOpenScene: switch ((widget.openScene, row.record?.sceneId)) {
            (final open?, final sceneId?) => () => open(sceneId, row.id),
            _ => null,
          },
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.group);

  final GameBehaviourGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: StudioSpacing.l,
        bottom: StudioSpacing.xs,
      ),
      child: Text(
        context.l10n.behavioursGroupHeader(
          context.l10n.behaviourGroup(group),
          group.rows.length,
        ),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
