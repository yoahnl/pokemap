import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/stories/application/story_step_outcomes.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class StoryStepOutcomes extends StatelessWidget {
  const StoryStepOutcomes({
    super.key,
    required this.controller,
    required this.story,
    required this.chapterId,
    required this.step,
  });

  final StoryWorkspaceController controller;
  final StorylineAsset story;
  final String chapterId;
  final StorylineStep step;

  @override
  Widget build(BuildContext context) {
    final choices = storyStepOutcomeChoices(
      controller.project,
      story,
      chapterId,
      step,
    );
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      key: const ValueKey('story-step-outcomes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Résultats attendus',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Résultats déclarés par les scènes et scénarios associés à cette '
          'étape. Les cocher ne déclenche rien en jeu : ils documentent ce que '
          'l’étape doit produire.',
          style: small,
        ),
        if (choices.isEmpty) ...[
          const SizedBox(height: 6),
          const StudioNotice(
            'Associez une scène ou un scénario qui déclare des résultats pour '
            'en attendre un.',
          ),
        ],
        for (final choice in choices)
          CheckboxListTile(
            key: ValueKey('story-step-outcome-${choice.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(choice.label),
            subtitle: Text(
              choice.source ??
                  'Introuvable dans les scènes et scénarios de l’étape ; '
                      'la référence est conservée.',
              style: small,
            ),
            value: choice.expected,
            onChanged: (checked) => _toggle(choice.id, checked == true),
          ),
      ],
    );
  }

  void _toggle(String id, bool expected) {
    final latest = controller.stories
        .where((candidate) => candidate.id == story.id)
        .firstOrNull
        ?.chapters
        .where((chapter) => chapter.id == chapterId)
        .firstOrNull
        ?.steps
        .where((candidate) => candidate.id == step.id)
        .firstOrNull;
    if (latest == null) return;
    final next = expected
        ? {...latest.expectedOutcomeIds, id}.toList()
        : latest.expectedOutcomeIds.where((value) => value != id).toList();
    if (next.length == latest.expectedOutcomeIds.length &&
        next.every(latest.expectedOutcomeIds.contains)) {
      return;
    }
    controller.apply(
      updateStorylineStep(
        controller.project,
        storylineId: story.id,
        chapterId: chapterId,
        stepId: step.id,
        step: latest.copyWith(expectedOutcomeIds: next),
      ),
    );
  }
}
