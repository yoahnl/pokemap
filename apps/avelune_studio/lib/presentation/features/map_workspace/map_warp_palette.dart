import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';

class MapWarpPalette extends StatelessWidget {
  const MapWarpPalette({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.onPick,
  });
  final List<ProjectMapEntry> destinations;
  final String? selectedId;
  final ValueChanged<ProjectMapEntry> onPick;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const StudioEmptyState(
        icon: Icons.meeting_room_outlined,
        title: 'Aucune destination disponible',
        description:
            'Un passage mène vers une autre carte. Créez une deuxième carte '
            'dans le projet pour pouvoir en poser un.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${destinations.length} destination(s)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            key: const PageStorageKey('warp-destinations'),
            scrollCacheExtent: const ScrollCacheExtent.pixels(0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent:
                  104 + 16 * (MediaQuery.textScalerOf(context).scale(1) - 1),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final entry = destinations[index];
              return StudioPaletteCard(
                key: ValueKey('warp-destination-${entry.id}'),
                name: entry.name,
                selected: selectedId == entry.id,
                maxNameLines: 2,
                preview: const Icon(Icons.meeting_room_outlined, size: 48),
                onTap: () => onPick(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}
