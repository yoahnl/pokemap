import 'package:flutter/material.dart';

import '../../../features/terrains/domain/terrain_connections.dart';

import 'package:map_core/map_core_domain.dart';

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
