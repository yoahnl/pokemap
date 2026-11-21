import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

class ProjectCharacterWorkspaceLayout extends StatelessWidget {
  const ProjectCharacterWorkspaceLayout({
    super.key,
    required this.sidebar,
    required this.compactSelector,
    required this.content,
  });

  final Widget sidebar;
  final Widget compactSelector;
  final Widget content;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth >= 688;
      final details = ListView(
        primary: false,
        padding: const EdgeInsets.all(StudioSpacing.xl),
        children: [
          if (!wide) ...[
            compactSelector,
            const SizedBox(height: StudioSpacing.l),
          ],
          content,
        ],
      );
      if (!wide) return details;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 224,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                StudioSpacing.xl,
                StudioSpacing.xl,
                0,
                StudioSpacing.xl,
              ),
              child: sidebar,
            ),
          ),
          Expanded(child: details),
        ],
      );
    },
  );
}

class ProjectCharacterWorkshopHeader extends StatelessWidget {
  const ProjectCharacterWorkshopHeader({
    super.key,
    required this.name,
    required this.onBack,
    required this.onRename,
    required this.showRename,
  });

  final String name;
  final VoidCallback? onBack;
  final VoidCallback? onRename;
  final bool showRename;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioButton(
          label: 'Retour à la bibliothèque',
          icon: Icons.arrow_back,
          onPressed: onBack,
          variant: StudioButtonVariant.quiet,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (showRename)
              StudioContextMenuButton(
                tooltip: 'Actions du personnage',
                items: () => [
                  StudioContextMenuEntry(
                    label: 'Renommer',
                    icon: Icons.edit_outlined,
                    onSelected: onRename,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.m),
      ],
    ),
  );
}
