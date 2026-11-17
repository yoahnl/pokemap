import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryDialogueNavigation extends InheritedWidget {
  const StoryDialogueNavigation({
    super.key,
    required this.open,
    this.loadLanguages,
    required super.child,
  });

  final Future<void> Function(String id) open;
  final Future<DialogueCatalogLanguages> Function()? loadLanguages;

  static StoryDialogueNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoryDialogueNavigation>();

  @override
  bool updateShouldNotify(StoryDialogueNavigation oldWidget) =>
      open != oldWidget.open || loadLanguages != oldWidget.loadLanguages;
}

class StoryDialogueLink extends StatelessWidget {
  const StoryDialogueLink({super.key, required this.id, this.label});

  final String id;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final navigation = StoryDialogueNavigation.of(context);
    if (navigation == null) return const SizedBox.shrink();
    return StudioButton(
      key: ValueKey('story-open-dialogue-$id'),
      label: label ?? context.l10n.dialogueCatalogOpen,
      icon: Icons.open_in_new,
      variant: StudioButtonVariant.quiet,
      onPressed: () => navigation.open(id),
    );
  }
}
