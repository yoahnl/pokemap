import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering show ScrollCacheExtent;
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';

class MapWarpPalette extends StatelessWidget {
  const MapWarpPalette({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.onPick,
    this.arrivalSelected = false,
    this.onPickArrival,
  });
  final List<ProjectMapEntry> destinations;
  final String? selectedId;
  final ValueChanged<ProjectMapEntry> onPick;
  final bool arrivalSelected;
  final VoidCallback? onPickArrival;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onPickArrival != null) ...[
          SizedBox(
            height: 104,
            child: StudioPaletteCard(
              key: const ValueKey('warp-arrival-point'),
              name: 'Point d’arrivée',
              selected: arrivalSelected,
              preview: const Icon(Icons.location_on_outlined, size: 48),
              onTap: onPickArrival!,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Utilisé par une scène',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          '${destinations.length} destination(s)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: destinations.isEmpty
              ? const StudioEmptyState(
                  icon: Icons.meeting_room_outlined,
                  title: 'Aucun passage vers une autre carte',
                  description:
                      'Le point d’arrivée peut être posé sur cette carte.',
                )
              : GridView.builder(
                  key: const PageStorageKey('warp-destinations'),
                  scrollCacheExtent: const rendering.ScrollCacheExtent.pixels(
                    0,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent:
                        104 +
                        16 * (MediaQuery.textScalerOf(context).scale(1) - 1),
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
                      preview: const Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                      ),
                      onTap: () => onPick(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
