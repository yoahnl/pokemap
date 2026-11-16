import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryDialogueLinks extends StatelessWidget {
  const StoryDialogueLinks({super.key, required this.onSelected});

  final ValueChanged<StorySection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.l),
      children: [
        StudioNotice(l10n.storyDialoguesEditingHint),
        const SizedBox(height: StudioSpacing.l),
        StudioChoice(
          key: const ValueKey('story-dialogue-behaviours'),
          label: l10n.storyBehaviourLines,
          subtitle: l10n.storyBehaviourLinesHint,
          onTap: () => onSelected(StorySection.behaviours),
        ),
        StudioChoice(
          key: const ValueKey('story-dialogue-scenes'),
          label: l10n.storySceneDialogues,
          subtitle: l10n.storySceneDialoguesHint,
          onTap: () => onSelected(StorySection.scenes),
        ),
      ],
    );
  }
}
