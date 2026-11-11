import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_preview.dart';

class MapBuilderResourceCard extends StatelessWidget {
  const MapBuilderResourceCard({
    super.key,
    required this.item,
    required this.project,
    required this.mapId,
    required this.visuals,
    required this.armed,
    required this.onUse,
  });

  final ResourceItem item;
  final ProjectManifest project;
  final String? mapId;
  final MapWorkspaceVisuals visuals;
  final bool armed;
  final ValueChanged<ResourceItem>? onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onUse = this.onUse;
    final reserved = item.metadata(project)?.mapId != null;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      button: true,
      selected: armed,
      label: item.name,
      child: InkWell(
        key: ValueKey('map-resource-${item.identity}'),
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
        onTap: onUse == null ? null : () => onUse(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Ink(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    StudioMetrics.panelRadius,
                  ),
                  border: Border.all(
                    color: armed ? scheme.primary : scheme.outlineVariant,
                    width: armed ? 2 : 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: MapBuilderResourcePreview(
                      item: item,
                      project: project,
                      visuals: visuals,
                      size: constraints.biggest.shortestSide - StudioSpacing.m,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: StudioSpacing.s),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(item.typeLabel, style: muted, maxLines: 1),
            Text(
              reserved ? 'Sur cette carte' : 'Commune au projet',
              style: muted,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
