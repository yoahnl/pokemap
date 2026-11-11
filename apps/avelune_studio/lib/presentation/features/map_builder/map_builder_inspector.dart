import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';

const mapBuilderInspectorWidth = 280.0;

class MapBuilderInspector extends StatelessWidget {
  const MapBuilderInspector({
    super.key,
    required this.entry,
    required this.projectName,
    required this.onCollapse,
  });

  final ProjectMapEntry? entry;
  final String projectName;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = this.entry;
    return Ink(
      key: const ValueKey('map-inspector'),
      width: mapBuilderInspectorWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: StudioSpacing.xl),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Text(
                  'Propriétés',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Replier l’inspecteur',
                  onPressed: onCollapse,
                  icon: const Icon(Icons.last_page, size: 18),
                ),
              ],
            ),
          ),
          if (entry != null)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARTE ACTIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.m),
                  Text(
                    entry.name,
                    key: const ValueKey('map-inspector-name'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    '${mapRoleLabel(entry.role)} · $projectName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
