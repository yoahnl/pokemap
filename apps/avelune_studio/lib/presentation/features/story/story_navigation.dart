import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String storySectionLabel(BuildContext context, StorySection section) {
  final l10n = context.l10n;
  return switch (section) {
    StorySection.trame => l10n.storyTabTrame,
    StorySection.behaviours => l10n.storySectionBehaviours,
    StorySection.scenes => l10n.storySectionScenes,
    StorySection.dialogues => l10n.storySectionDialogues,
    StorySection.facts => l10n.storySectionFacts,
    StorySection.rules => l10n.memorySectionRules,
    StorySection.verification => l10n.storySectionVerification,
  };
}

String storySectionHint(BuildContext context, StorySection section) {
  final l10n = context.l10n;
  return switch (section) {
    StorySection.trame => l10n.storyTrameHint,
    StorySection.behaviours => l10n.storyBehavioursHint,
    StorySection.scenes => l10n.storyScenesHint,
    StorySection.dialogues => l10n.storyDialoguesHint,
    StorySection.facts => l10n.storyFactsHint,
    StorySection.rules => l10n.storyRulesHint,
    StorySection.verification => l10n.storyVerificationHint,
  };
}

class StoryNavigation extends StatelessWidget {
  const StoryNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    this.verificationMarker,
  });

  final StorySection selected;
  final ValueChanged<StorySection> onSelected;
  final StudioBadge? verificationMarker;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: WidgetOrderTraversalPolicy(),
    child: StudioSidebar(
      width: selected == StorySection.behaviours ? 190 : 240,
      child: ListView(
        key: const ValueKey('story-navigation'),
        children: [
          StudioPageHeader(
            title: context.l10n.storyWorkspaceTitle,
            description: context.l10n.storyWorkspaceHint,
          ),
          for (final section in StorySection.values)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
              child: StudioNavigationEntry(
                key: ValueKey('story-section-${section.name}'),
                label: storySectionLabel(context, section),
                detail: storySectionHint(context, section),
                icon: switch (section) {
                  StorySection.trame => Icons.auto_stories_outlined,
                  StorySection.behaviours => Icons.bolt_outlined,
                  StorySection.scenes => Icons.account_tree_outlined,
                  StorySection.dialogues => Icons.chat_bubble_outline,
                  StorySection.facts => Icons.flag_outlined,
                  StorySection.rules => Icons.rule_outlined,
                  StorySection.verification => Icons.fact_check_outlined,
                },
                selected: section == selected,
                marker: switch ((section, verificationMarker)) {
                  (StorySection.verification, final marker?) => ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 72),
                    child: marker,
                  ),
                  _ => null,
                },
                markerLabel: section == StorySection.verification
                    ? verificationMarker?.label
                    : null,
                onTap: () => onSelected(section),
              ),
            ),
        ],
      ),
    ),
  );
}
