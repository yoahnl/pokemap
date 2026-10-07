import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';

class MapConnectionPanel extends StatefulWidget {
  const MapConnectionPanel({
    super.key,
    required this.map,
    required this.project,
    required this.onLink,
    required this.onUnlink,
  });

  final MapData map;
  final ProjectManifest project;
  final Future<void> Function(MapConnectionDirection, String, int) onLink;
  final Future<void> Function(MapConnectionDirection) onUnlink;

  @override
  State<MapConnectionPanel> createState() => _MapConnectionPanelState();
}

class _MapConnectionPanelState extends State<MapConnectionPanel> {
  MapConnectionDirection direction = MapConnectionDirection.east;
  String? targetMapId;
  String offset = '0';

  @override
  Widget build(BuildContext context) {
    final destinations = widget.project.maps
        .where((entry) => entry.id != widget.map.id)
        .toList();
    final target = destinations.any((entry) => entry.id == targetMapId)
        ? targetMapId
        : destinations.firstOrNull?.id;
    final connection = widget.map.connections
        .where((entry) => entry.direction == direction)
        .firstOrNull;
    final destination = destinations
        .where((entry) => entry.id == connection?.targetMapId)
        .firstOrNull;
    final shift = int.tryParse(offset.trim());
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Liaisons entre cartes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Reliez deux bords pour passer d’une carte à l’autre en marchant. Le retour est créé automatiquement. Libérez les cases du passage sur les deux cartes dans Collisions.',
          ),
          const SizedBox(height: 14),
          for (final value in MapConnectionDirection.values)
            StudioChoice(
              key: ValueKey('connection-direction-${value.name}'),
              label: _directionLabel(value),
              subtitle: widget.map.connections
                  .where((entry) => entry.direction == value)
                  .map(
                    (entry) =>
                        widget.project.maps
                            .where((map) => map.id == entry.targetMapId)
                            .firstOrNull
                            ?.name ??
                        'Carte introuvable',
                  )
                  .firstOrNull,
              selected: direction == value,
              onTap: () => setState(() => direction = value),
            ),
          const SizedBox(height: 14),
          if (connection != null) ...[
            Text(
              'Vers ${destination?.name ?? 'carte introuvable'} · décalage ${connection.offset} case(s)',
            ),
            const SizedBox(height: 10),
            StudioButton(
              key: const ValueKey('connection-remove'),
              label: 'Retirer cette liaison',
              secondary: true,
              onPressed: () => widget.onUnlink(direction),
            ),
          ] else if (destinations.isEmpty)
            const Text('Ajoutez une autre carte pour créer une liaison.')
          else ...[
            StudioSelect(
              key: const ValueKey('connection-target'),
              value: target,
              label: 'Carte voisine',
              options: {for (final entry in destinations) entry.id: entry.name},
              onChanged: (value) => setState(() => targetMapId = value),
            ),
            const SizedBox(height: 10),
            StudioDraftField(
              key: const ValueKey('connection-offset'),
              value: offset,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              label: 'Décalage en cases',
              helperText: '0 aligne les deux bords au même niveau.',
              errorText: shift == null ? 'Saisissez un nombre entier.' : null,
              onChanged: (value) => setState(() => offset = value),
            ),
            const SizedBox(height: 12),
            StudioButton(
              key: const ValueKey('connection-create'),
              label: 'Relier les deux cartes',
              onPressed: shift == null || target == null
                  ? null
                  : () => widget.onLink(direction, target, shift),
            ),
          ],
        ],
      ),
    );
  }
}

String _directionLabel(MapConnectionDirection direction) => switch (direction) {
  MapConnectionDirection.north => 'Bord nord',
  MapConnectionDirection.east => 'Bord est',
  MapConnectionDirection.south => 'Bord sud',
  MapConnectionDirection.west => 'Bord ouest',
};
