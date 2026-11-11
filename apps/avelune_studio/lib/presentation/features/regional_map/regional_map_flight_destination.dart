import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/regional_map/application/regional_map_controller.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_section.dart';
import '../../../features/regional_map/application/regional_map_choices.dart';
import 'regional_map_place_summary.dart';

class RegionalMapFlightDestination extends StatelessWidget {
  const RegionalMapFlightDestination({
    super.key,
    required this.owner,
    required this.point,
    required this.onEnable,
  });

  final RegionalMapController owner;
  final ProjectRegionPointOfInterest point;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final destination = point.destination;
    final source = owner.source!;
    final nativeMaps = source.project.maps;
    final map = source.maps[destination?.mapId];
    final spawns = regionalSpawnOptions(map);
    final arrival = destination == null
        ? null
        : regionalFlightArrival(
            destination: destination,
            project: source.project,
            map: map,
            loading: owner.loadingMap,
          );
    return StudioSection(
      title: 'Destination de Vol',
      children: [
        Text(
          'Indépendant de la visibilité : un lieu peut être visible sans arrivée de Vol, ou l’inverse.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        StudioToggleRow(
          label: 'Autoriser Vol vers ce lieu',
          value: destination != null,
          onChanged: owner.busy || nativeMaps.isEmpty
              ? null
              : (enabled) {
                  if (!enabled) {
                    owner.editPoint(clearDestination: true);
                    return;
                  }
                  onEnable();
                },
        ),
        if (nativeMaps.isEmpty)
          const StudioNotice(
            'Créez une carte 2D native avec une arrivée pour y autoriser Vol.',
          ),
        if (destination != null) ...[
          StudioSelect(
            label: 'Carte d’arrivée',
            value: destination.mapId,
            options: {for (final entry in nativeMaps) entry.id: entry.name},
            onChanged: owner.busy
                ? null
                : (id) => owner.editPoint(
                    destination: ProjectRegionDestination(mapId: id),
                  ),
          ),
          StudioSelect(
            label: 'Point d’arrivée',
            value: destination.spawnId,
            options: spawns,
            onChanged: owner.busy || owner.loadingMap
                ? null
                : (id) => owner.editPoint(
                    destination: ProjectRegionDestination(
                      mapId: destination.mapId,
                      spawnId: id,
                    ),
                  ),
          ),
          if (!owner.loadingMap && map != null && spawns.isEmpty)
            const StudioNotice(
              'Ajoutez une arrivée sur cette carte dans l’éditeur de carte.',
            )
          else if (arrival != null)
            StudioNotice(
              key: const ValueKey('regional-flight-arrival'),
              arrival.text,
              isError: arrival.problem,
            ),
        ],
      ],
    );
  }
}
