import '../../../features/resources/application/resource_creation_sources.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/layout/studio_panel.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_source_list.dart';

class BorderSourcePanel extends StatelessWidget {
  const BorderSourcePanel({
    super.key,
    required this.project,
    required this.visuals,
    required this.active,
    required this.onActive,
    this.activeMapId,
  });

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final ResourceItem? active;
  final ValueChanged<ResourceItem> onActive;
  final String? activeMapId;

  @override
  Widget build(BuildContext context) {
    final spatial = project.settings.dimension == ProjectDimension.threeD;
    final panel = StudioPanel(
      title: spatial ? 'Modèles disponibles' : 'Décors disponibles',
      compact: true,
      children: [
        Text(
          spatial
              ? 'Choisissez une pièce unitaire, puis cliquez sur sa place dans le patron.'
              : 'Choisissez un décor, puis cliquez sur une place du patron. Vous pouvez aussi le glisser.',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ResourceSourceList(
            project: project,
            visuals: visuals,
            items: borderCreationSources(project, activeMapId: activeMapId),
            activeMapId: activeMapId,
            selectedIdentity: active?.identity,
            onPick: onActive,
            keyPrefix: 'border-library',
            draggableElements: !spatial,
          ),
        ),
      ],
    );
    final minimumHeight = 450 * MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, bounds) => bounds.maxHeight < minimumHeight
          ? SingleChildScrollView(
              child: SizedBox(height: minimumHeight, child: panel),
            )
          : panel,
    );
  }
}
