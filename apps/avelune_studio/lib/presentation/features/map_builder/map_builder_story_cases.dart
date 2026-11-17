import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderStoryCaseList extends StatelessWidget {
  const MapBuilderStoryCaseList({
    super.key,
    required this.binding,
    required this.element,
    required this.current,
    required this.editable,
    required this.state,
    this.itemBuilder,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final NarrativeEventRecord? current;
  final bool editable;
  final String Function(NarrativeEventRecord record, AppLocalizations l10n)
  state;
  final Widget Function(
    NarrativeEventRecord record,
    int number,
    Widget? handle,
  )?
  itemBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cases = binding.casesOf(element);
    final indexes = {
      for (final (index, record) in element.behaviours.indexed)
        record.id: index,
    };
    final names = {
      for (final record in element.behaviours) record.id: record.name,
    };
    var number = 0;
    Widget tile(NarrativeEventRecord record, Widget? handle) {
      final shadow = cases.shadowedBy[record.id];
      final index = indexes[record.id]!;
      number++;
      return Column(
        key: ValueKey('map-story-case-${record.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemBuilder?.call(record, number, handle) ??
              Row(
                children: [
                  ?handle,
                  Expanded(
                    child: StudioChoice(
                      key: ValueKey('map-story-behaviour-$index'),
                      dense: true,
                      label: '$number · ${record.name}',
                      subtitle: state(record, l10n),
                      selected: identical(record, current),
                      onTap: () => binding.openBehaviour(index),
                    ),
                  ),
                ],
              ),
          if (shadow != null)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
              child: StudioNotice(
                l10n.storyCaseShadowed(names[shadow] ?? shadow),
                key: ValueKey('map-story-case-shadow-${record.id}'),
              ),
            ),
        ],
      );
    }

    Widget eyebrow(String text) => Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.xs),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    final titled = cases.groups.length + (cases.unsorted.isEmpty ? 0 : 1) > 1;
    return Column(
      key: const ValueKey('map-story-cases'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in cases.groups) ...[
          if (titled) eyebrow(l10n.storyTrigger(group.kind.name)),
          _Group(
            key: ValueKey('map-story-cases-${group.kind.name}'),
            movable: editable && group.cases.length > 1,
            onMove: (from, to) => binding.moveCase(group, from, to),
            tiles: [
              for (final (index, item) in group.cases.indexed)
                tile(
                  item.record,
                  editable && group.cases.length > 1
                      ? ReorderableDragStartListener(
                          key: ValueKey(
                            'map-story-case-drag-${item.record.id}',
                          ),
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(right: StudioSpacing.xs),
                            child: Icon(Icons.drag_indicator, size: 18),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ],
        if (cases.unsorted.isNotEmpty) ...[
          if (titled) eyebrow(l10n.storyCaseNoTrigger),
          for (final record in cases.unsorted) tile(record, null),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    super.key,
    required this.movable,
    required this.onMove,
    required this.tiles,
  });

  final bool movable;
  final void Function(int from, int to) onMove;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => movable
      ? ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: onMove,
          children: tiles,
        )
      : Column(children: tiles);
}
