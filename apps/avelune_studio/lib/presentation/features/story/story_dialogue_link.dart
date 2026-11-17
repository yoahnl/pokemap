import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryDialogueNavigation extends InheritedWidget {
  const StoryDialogueNavigation({
    super.key,
    required this.open,
    this.openWithLanguage,
    this.loadLanguages,
    this.currentSource,
    required super.child,
  });

  final Future<void> Function(String id) open;
  final Future<void> Function(String id, String language)? openWithLanguage;
  final Future<DialogueCatalogLanguages> Function()? loadLanguages;
  final StoryDialogueSource? Function(String, StoryDialogueSource?)?
  currentSource;

  static StoryDialogueNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoryDialogueNavigation>();

  @override
  bool updateShouldNotify(StoryDialogueNavigation oldWidget) =>
      open != oldWidget.open ||
      openWithLanguage != oldWidget.openWithLanguage ||
      loadLanguages != oldWidget.loadLanguages ||
      currentSource != oldWidget.currentSource;
}

class StoryDialogueLink extends StatelessWidget {
  const StoryDialogueLink({
    super.key,
    required this.id,
    this.label,
    this.language,
  });

  final String id;
  final String? label;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final navigation = StoryDialogueNavigation.of(context);
    if (navigation == null) return const SizedBox.shrink();
    return StudioButton(
      key: ValueKey('story-open-dialogue-$id'),
      label: label ?? context.l10n.dialogueCatalogOpen,
      icon: Icons.open_in_new,
      variant: StudioButtonVariant.quiet,
      onPressed: () => switch ((language, navigation.openWithLanguage)) {
        (final language?, final open?) => open(id, language),
        _ => navigation.open(id),
      },
    );
  }
}
