import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviours_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourList extends StatelessWidget {
  const GameBehaviourList({
    super.key,
    required this.behaviours,
    required this.search,
    required this.child,
    this.trame,
    this.create,
  });

  final GameBehavioursController behaviours;
  final TextEditingController search;
  final StorylineTrameController? trame;
  final Widget child;
  final VoidCallback? create;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioSidebar(
      width: double.infinity,
      child: Column(
        key: const ValueKey('behaviours-view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioPageHeader(
            title: l10n.storySectionBehaviours,
            titleMaxLines: 1,
            description: l10n.storyBehavioursHint,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioSearchField(
                  key: const ValueKey('behaviours-search'),
                  controller: search,
                  label: l10n.triggersSearch,
                  onChanged: behaviours.search,
                ),
                const SizedBox(height: StudioSpacing.m),
                StudioSelect(
                  key: const ValueKey('behaviours-map-filter'),
                  label: l10n.behavioursByMap,
                  compact: true,
                  value: behaviours.mapId ?? '',
                  options: {
                    '': l10n.triggersAllMaps,
                    for (final map in behaviours.source().maps)
                      map.id: map.name,
                    if (behaviours.mapId case final String id
                        when !behaviours.source().maps.any(
                          (map) => map.id == id,
                        ))
                      id: l10n.behavioursMissingMap,
                  },
                  onChanged: (id) =>
                      behaviours.filterMap(id.isEmpty ? null : id),
                ),
                const SizedBox(height: StudioSpacing.m),
                Wrap(
                  spacing: StudioSpacing.xs,
                  runSpacing: StudioSpacing.xs,
                  children: [
                    StudioFilterChip(
                      key: const ValueKey('behaviours-filter-toRepair'),
                      label: l10n.triggersIncomplete,
                      selected: behaviours.filters.contains(
                        GameBehaviourFilter.toRepair,
                      ),
                      onSelected: (_) =>
                          behaviours.toggle(GameBehaviourFilter.toRepair),
                    ),
                    StudioContextMenuButton(
                      key: const ValueKey('behaviours-grouping'),
                      tooltip: l10n.triggersGrouping,
                      icon: Icons.tune,
                      items: () => [
                        for (final group in GameBehaviourGrouping.values)
                          StudioContextMenuEntry(
                            label: switch (group) {
                              GameBehaviourGrouping.map => l10n.behavioursByMap,
                              GameBehaviourGrouping.fact =>
                                l10n.behavioursByFact,
                              GameBehaviourGrouping.character =>
                                l10n.behavioursByCharacter,
                            },
                            icon: group == behaviours.grouping
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            onSelected: () => behaviours.group(group),
                          ),
                        const StudioContextMenuSeparator(),
                        for (final filter in GameBehaviourFilter.values.where(
                          (value) => value != GameBehaviourFilter.toRepair,
                        ))
                          StudioContextMenuEntry(
                            key: ValueKey('behaviours-filter-${filter.name}'),
                            label: switch (filter) {
                              GameBehaviourFilter.withoutMap =>
                                l10n.behavioursFilterWithoutMap,
                              GameBehaviourFilter.disabled =>
                                l10n.behavioursFilterDisabled,
                              _ => l10n.behavioursFilterOutsideTrame,
                            },
                            icon: behaviours.filters.contains(filter)
                                ? Icons.check_box_outlined
                                : Icons.check_box_outline_blank,
                            onSelected:
                                filter == GameBehaviourFilter.outsideTrame &&
                                    trame == null
                                ? null
                                : () {
                                    if (filter ==
                                        GameBehaviourFilter.outsideTrame) {
                                      unawaited(trame!.open());
                                    }
                                    behaviours.toggle(filter);
                                  },
                          ),
                      ],
                    ),
                  ],
                ),
                if (behaviours.refused.isNotEmpty)
                  StudioNotice(
                    key: const ValueKey('behaviours-refused'),
                    l10n.behavioursRefused,
                    isError: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: StudioSpacing.m),
          Expanded(child: child),
          if (create != null)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.m),
              child: StudioButton(
                key: const ValueKey('story-trigger-create'),
                label: l10n.storyAddBehaviour,
                icon: Icons.add,
                onPressed: create,
              ),
            ),
        ],
      ),
    );
  }
}
