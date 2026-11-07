import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

String terrainUsageLabel(SmartTileUsage usage) => switch (usage) {
  SmartTileUsage.path => 'Chemin automatique',
  SmartTileUsage.terrain => 'Sol automatique',
  SmartTileUsage.forestSurface => 'Surface de forêt',
};

String terrainUsageExplanation(SmartTileUsage usage) => switch (usage) {
  SmartTileUsage.path =>
    'Se peint par-dessus le sol : une carte peut superposer plusieurs chemins '
        '(route, eau, berge).',
  SmartTileUsage.terrain =>
    'Fournit le sol d’une carte : une carte 2D n’accepte qu’un seul sol '
        'automatique.',
  SmartTileUsage.forestSurface =>
    'Couvre le sol d’une carte 2D ; les cartes 3D ne l’acceptent pas.',
};

class TerrainUsageSummary extends StatelessWidget {
  const TerrainUsageSummary({super.key, required this.usage});
  final SmartTileUsage usage;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('terrain-usage-summary'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.layers_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              terrainUsageLabel(usage),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              terrainUsageExplanation(usage),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}
