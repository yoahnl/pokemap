import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/features/story/story_dialogue_link.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourContext extends StatelessWidget {
  const GameBehaviourContext({
    super.key,
    required this.binding,
    required this.record,
    required this.element,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final MapStoryElement element;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final project = binding.behaviours.project(binding.project!);
    final scene = record.sceneId == null
        ? null
        : binding.sceneOf(record.sceneId!);
    final dialogues = {
      for (final node in scene?.graph.nodes ?? const <SceneNode>[])
        if (node.payload case SceneYarnDialoguePayload(:final dialogueId))
          dialogueId,
    };
    final usages =
        binding.behaviours
            .registry(binding.project!)
            ?.records
            .where(
              (item) => item.sceneId != null && item.sceneId == record.sceneId,
            )
            .length ??
        0;
    return StudioSection(
      key: ValueKey('story-trigger-context-${record.id}'),
      title: l10n.triggersContext,
      children: [
        Text(
          '${binding.map?.name ?? l10n.behavioursMissingMap} · ${mapBuilderStoryName(element, l10n)}',
        ),
        Text(l10n.storyTrigger(record.source?.kind.name ?? 'none')),
        Text(l10n.triggersPriority(record.priority)),
        const SizedBox(height: StudioSpacing.s),
        Text(
          l10n.triggersUsages,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (scene != null) ...[
          Text(scene.name),
          Text(l10n.triggersSceneUsages(usages)),
          if (binding.openScene case final open?)
            StudioButton(
              variant: StudioButtonVariant.quiet,
              label: l10n.sceneGraphOpen,
              onPressed: () => open(scene.id, record.id),
            ),
        ],
        for (final id in dialogues) StoryDialogueLink(id: id),
        for (final factId
            in record.expression.leaves
                .expand(
                  (condition) => condition.whenTyped<Iterable<String>>(
                    fact: (id, _, _) => [id],
                    narrativeEventConsumed: (_, _) => const [],
                    mapEventInstanceBoolean: (_, _, _, _) => const [],
                    civilWeekday: (_, _) => const [],
                    periodicRewardAvailable: (_, _) => const [],
                  ),
                )
                .toSet())
          Text(
            project.facts
                    .where((fact) => fact.id == factId)
                    .firstOrNull
                    ?.label ??
                l10n.memoryUnknownFact,
          ),
      ],
    );
  }
}
