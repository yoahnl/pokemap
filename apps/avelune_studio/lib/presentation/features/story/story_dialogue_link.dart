import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryDialogueNavigation extends InheritedWidget {
  const StoryDialogueNavigation({
    super.key,
    required this.open,
    required super.child,
  });

  final Future<void> Function(String id) open;

  static StoryDialogueNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoryDialogueNavigation>();

  @override
  bool updateShouldNotify(StoryDialogueNavigation oldWidget) =>
      open != oldWidget.open;
}

class StoryDialogueLink extends StatelessWidget {
  const StoryDialogueLink({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final navigation = StoryDialogueNavigation.of(context);
    if (navigation == null) return const SizedBox.shrink();
    return StudioButton(
      key: ValueKey('story-open-dialogue-$id'),
      label: context.l10n.dialogueCatalogOpen,
      icon: Icons.open_in_new,
      variant: StudioButtonVariant.quiet,
      onPressed: () => navigation.open(id),
    );
  }
}
