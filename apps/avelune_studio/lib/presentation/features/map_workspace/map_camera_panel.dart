import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_spatial_settings_commands.dart';

import 'package:map_core/map_core_domain.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/layout/studio_section.dart';

class MapCameraPanel extends StatelessWidget {
  const MapCameraPanel({
    super.key,
    required this.document,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final camera = document.current.spatialScene?.camera;
    if (camera == null) return const SizedBox();
    final commands = MapSpatialSettingsCommands(document);
    bool commit(SpatialCameraProfile Function() update) {
      final committed = commands.camera(update);
      onChanged();
      return committed;
    }

    Widget field(
      String label,
      double value,
      SpatialCameraProfile Function(double) update,
    ) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: StudioCommitField(
        label: label,
        value: value.toStringAsFixed(2),
        tryCommit: (text) {
          final committed = commands.cameraNumber(text, update);
          onChanged();
          return committed;
        },
      ),
    );

    final overrides = mapCameraOverrides(document);
    return StudioSection(
      title: 'Caméra du jeu',
      collapsible: true,
      initiallyExpanded: false,
      children: [
        if (overrides != null) ...[
          StudioNotice(overrides, key: const ValueKey('map-camera-overrides')),
          const SizedBox(height: 8),
        ],
        for (final projection in SpatialCameraProjection.values)
          StudioChoice(
            label: projection == SpatialCameraProjection.perspective
                ? 'Perspective'
                : 'Orthographique',
            selected: camera.projection == projection,
            onTap: () => commit(() => camera.copyWith(projection: projection)),
          ),
        const SizedBox(height: 6),
        Text(
          camera.projection == SpatialCameraProjection.orthographic
              ? 'Les éléments gardent la même taille quelle que soit leur distance. La hauteur visible règle le cadrage.'
              : 'Les éléments lointains apparaissent plus petits. Le champ de vision et la distance règlent le cadrage.',
        ),
        field(
          'Inclinaison en degrés',
          camera.pitchDegrees,
          (value) => camera.copyWith(pitchDegrees: value),
        ),
        field(
          'Orientation en degrés',
          camera.yawDegrees,
          (value) => camera.copyWith(yawDegrees: value),
        ),
        if (camera.projection == SpatialCameraProjection.orthographic)
          field(
            'Hauteur visible en cases',
            camera.orthographicHeight,
            (value) => camera.copyWith(orthographicHeight: value),
          )
        else
          field(
            'Champ de vision en degrés',
            camera.fieldOfViewDegrees,
            (value) => camera.copyWith(fieldOfViewDegrees: value),
          ),
        field(
          'Distance en cases',
          camera.distance,
          (value) => camera.copyWith(distance: value),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
