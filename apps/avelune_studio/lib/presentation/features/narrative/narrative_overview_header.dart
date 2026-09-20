import 'package:flutter/material.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'narrative_name_dialog.dart';

class NarrativeOverviewHeader extends StatelessWidget {
  const NarrativeOverviewHeader({
    super.key,
    required this.controller,
    required this.summary,
    required this.onCreated,
    this.compactDetail = false,
    this.onScenes,
  });
  final NarrativeWorkspaceController controller;
  final String summary;
  final VoidCallback onCreated;
  final bool compactDetail;
  final VoidCallback? onScenes;

  @override
  Widget build(BuildContext context) => compactDetail
      ? Row(
          children: [
            Expanded(
              child: StudioPageHeader(
                title: 'Histoire',
                description: controller.project.name,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Actions Histoire',
              enabled: !controller.busy,
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) {
                switch (action) {
                  case 'scenes':
                    onScenes?.call();
                  case 'story':
                    _createStory(context);
                  case 'fact':
                    _createFact(context);
                  case 'save':
                    controller.saveAll();
                }
              },
              itemBuilder: (_) => [
                if (onScenes != null)
                  const PopupMenuItem(value: 'scenes', child: Text('Scènes')),
                PopupMenuItem(
                  value: 'story',
                  child: Text('Créer une histoire'),
                ),
                PopupMenuItem(value: 'fact', child: Text('Créer un état')),
                PopupMenuItem(
                  value: 'save',
                  child: Text(
                    'Enregistrer les modifications\nHistoires, interactions et cartes ouvertes modifiées',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioPageHeader(
              title: 'Histoire',
              description: compactDetail
                  ? controller.project.name
                  : 'Retrouvez vos histoires, leurs étapes et les interactions du monde.',
              alignActionsToEnd: true,
              actions: compactDetail
                  ? const []
                  : [
                      if (onScenes != null)
                        StudioButton(
                          label: 'Scènes',
                          icon: Icons.account_tree_outlined,
                          secondary: true,
                          onPressed: onScenes,
                        ),
                      StudioButton(
                        label: 'Créer une histoire',
                        icon: Icons.add,
                        onPressed: controller.busy
                            ? null
                            : () => _createStory(context),
                      ),
                      StudioButton(
                        label: 'Créer un état',
                        secondary: true,
                        onPressed: controller.busy
                            ? null
                            : () => _createFact(context),
                      ),
                      StudioButton(
                        label: 'Enregistrer les modifications',
                        secondary: true,
                        icon: Icons.save_outlined,
                        onPressed: controller.busy ? null : controller.saveAll,
                      ),
                    ],
            ),
            if (!compactDetail)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enregistre les histoires, interactions et cartes ouvertes modifiées.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        );

  Future<void> _createStory(BuildContext context) async {
    final title = await askNarrativeName(context, 'Nom de l’histoire');
    if (title == null || !context.mounted) return;
    final steps = await askNarrativeName(
      context,
      'Étapes, une par ligne',
      multiline: true,
    );
    if (steps == null) return;
    controller.addStory(title, steps.split('\n'));
    onCreated();
  }

  Future<void> _createFact(BuildContext context) async {
    final label = await askNarrativeName(context, 'Nom de l’état');
    if (label == null) return;
    controller.addFact(label);
    onCreated();
  }
}
