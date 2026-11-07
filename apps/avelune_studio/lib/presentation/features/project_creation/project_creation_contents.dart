import 'package:flutter/material.dart';

import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../../features/project_creation/application/project_template_contents.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ProjectTemplateContentsPanel extends StatelessWidget {
  const ProjectTemplateContentsPanel({super.key, required this.controller});
  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    final contents = projectTemplateContents(
      dimension: controller.dimension,
      template: controller.template,
      width: controller.width,
      height: controller.height,
      catalogueLabel: controller.selectedTemplate?.label,
    );
    final theme = Theme.of(context).textTheme;
    return StudioPanel(
      key: const ValueKey('creation-template-contents'),
      title: 'Ce que contient ce modèle',
      children: [
        for (final row in contents.rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: Text(row.key, style: theme.labelLarge),
                ),
                Expanded(child: Text(row.value)),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text('Avant un premier test', style: theme.labelLarge),
        const SizedBox(height: 4),
        Text(contents.beforeTest),
      ],
    );
  }
}

class ProjectCreationPathPreview extends StatelessWidget {
  const ProjectCreationPathPreview({super.key, required this.controller});
  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    final folder = controller.folderName.isEmpty ? '…' : controller.folderName;
    final parent = controller.parentPath;
    final theme = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('creation-path-preview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chemin final', style: theme.labelLarge),
        const SizedBox(height: 4),
        SelectionArea(
          child: Text(
            parent.isEmpty
                ? '…/$folder · Emplacement choisi à la dernière étape'
                : '${parent.endsWith('/') ? parent.substring(0, parent.length - 1) : parent}/$folder',
          ),
        ),
      ],
    );
  }
}
