import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_view_data.dart';

class ResourceLibraryScopePanel extends StatelessWidget {
  const ResourceLibraryScopePanel({
    super.key,
    required this.maps,
    required this.mapId,
    required this.onMap,
    required this.scope,
    required this.counts,
    required this.onScope,
  });

  final Map<String, String> maps;
  final String? mapId;
  final ValueChanged<String> onMap;
  final ResourceLibraryScope scope;
  final Map<ResourceLibraryScope, int> counts;
  final ValueChanged<ResourceLibraryScope> onScope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapName = maps[mapId] ?? 'cette carte';
    final explanation = switch (scope) {
      ResourceLibraryScope.project => 'Toutes les ressources du projet.',
      ResourceLibraryScope.used => 'Ressources utilisées sur $mapName.',
      ResourceLibraryScope.exclusive =>
        'Ressources utilisées uniquement sur $mapName, réutilisables ailleurs.',
    };
    return StudioPanel(
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: StudioSpacing.l,
            spacing: StudioSpacing.l,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PÉRIMÈTRE DES RESSOURCES',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .75,
                    ),
                  ),
                  const SizedBox(height: StudioSpacing.s),
                  Text(
                    'Quelles ressources afficher ?',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              if (maps.isNotEmpty)
                SizedBox(
                  width: 190,
                  child: StudioSelect(
                    label: 'Carte de référence',
                    value: mapId,
                    options: maps,
                    onChanged: onMap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        Wrap(
          spacing: StudioSpacing.m,
          runSpacing: StudioSpacing.xs,
          children: [
            for (final option in ResourceLibraryScope.values)
              StudioFilterChip(
                key: ValueKey('library-scope-${option.name}'),
                label: '${option.label} · ${counts[option] ?? 0}',
                selected: option == scope,
                onSelected:
                    mapId == null && option != ResourceLibraryScope.project
                    ? null
                    : (_) => onScope(option),
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.s),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: StudioSpacing.m),
            Expanded(
              child: Text(explanation, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}
