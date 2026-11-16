import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_navigation.dart';

class StoryBreadcrumb extends StatelessWidget {
  const StoryBreadcrumb({super.key, required this.section});

  final StorySection section;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      StudioSpacing.l,
      StudioSpacing.m,
      StudioSpacing.l,
      0,
    ),
    child: Text(
      '${context.l10n.storyWorkspaceTitle} › ${storySectionLabel(context, section)}',
      key: const ValueKey('story-breadcrumb'),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
