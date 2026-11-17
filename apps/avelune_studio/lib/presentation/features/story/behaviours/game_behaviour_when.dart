import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourWhen extends StatelessWidget {
  const GameBehaviourWhen({
    super.key,
    required this.binding,
    required this.record,
    required this.element,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final MapStoryElement element;
  final bool editable;

  void _move(MapStoryElement target) {
    if (!binding.reassign(record, target)) return;
    final current = binding.elements!.byKey(target.key)!;
    binding.select(current);
    binding.openBehaviour(
      current.behaviours.indexWhere((item) => item.id == record.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kinds = binding.triggerKinds(element);
    final carriers = [
      for (final candidate
          in binding.elements?.elements ?? const <MapStoryElement>[])
        if (candidate.key == element.key ||
            binding.triggerKinds(candidate).isNotEmpty)
          candidate,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('story-trigger-source'),
          label: l10n.triggersSource,
          value: element.key,
          options: {
            for (final carrier in carriers)
              carrier.key: mapBuilderStoryName(carrier, l10n),
          },
          onChanged: editable
              ? (value) =>
                    _move(carriers.singleWhere((item) => item.key == value))
              : null,
        ),
        const SizedBox(height: StudioSpacing.s),
        StudioSelect(
          key: const ValueKey('map-story-when'),
          label: l10n.triggersEvent,
          value: record.source?.kind.name ?? '',
          options: {
            if (record.source == null) '': l10n.storyTrigger('none'),
            for (final kind in {...kinds, ?record.source?.kind})
              kind.name: l10n.storyTrigger(kind.name),
          },
          onChanged: editable
              ? (value) => binding.setTrigger(
                  element,
                  record,
                  NarrativeEventSourceKind.values.byName(value),
                )
              : null,
        ),
      ],
    );
  }
}
