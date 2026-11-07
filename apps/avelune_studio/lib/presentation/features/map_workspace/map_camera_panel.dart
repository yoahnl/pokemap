import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/layout/studio_section.dart';

String _frenchNumber(double value, int digits) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

class MapCameraPanel extends StatelessWidget {
  const MapCameraPanel({
    super.key,
    required this.document,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final VoidCallback onChanged;

  String? _overrides() {
    final effective = document.visualProfile;
    final local = document.weatherVisuals?.preview.value;
    final entries = <(SpatialVisualParameter, String)>[
      for (final (parameter, label, digits, unit) in const [
        (SpatialVisualParameter.pitchDegrees, 'Inclinaison', 1, '°'),
        (SpatialVisualParameter.yawDegrees, 'Orientation', 0, '°'),
        (SpatialVisualParameter.fieldOfViewDegrees, 'Champ de vision', 1, '°'),
        (SpatialVisualParameter.cameraDistance, 'Distance', 2, ' cases'),
      ])
        if (effective.number(parameter) case final value?)
          (parameter, '$label ${_frenchNumber(value, digits)}$unit'),
    ];
    if (entries.isEmpty) return null;
    final fromMap = entries
        .where((entry) => local?.value(entry.$1) != null)
        .map((entry) => entry.$2);
    final fromProject = entries
        .where((entry) => local?.value(entry.$1) == null)
        .map((entry) => entry.$2);
    return [
      'En jeu, ces valeurs remplacent celles de cette caméra :',
      if (fromProject.isNotEmpty)
        '${fromProject.join(', ')} (réglages du projet › Image et caméra)',
      if (fromMap.isNotEmpty)
        '${fromMap.join(', ')} (dérogation propre à cette carte)',
      'Les autres champs de cette caméra s’appliquent tels quels.',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final camera = document.current.spatialScene?.camera;
    if (camera == null) return const SizedBox();
    bool commit(SpatialCameraProfile Function() update) {
      try {
        document.commit(
          const SpatialMapOperations().configureCamera(
            document.current,
            update(),
          ),
        );
        onChanged();
        return true;
      } on FormatException {
        document.error = 'La caméra exige une inclinaison entre 0 et 90°, une taille et une distance positives.';
        onChanged();
        return false;
      }
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
          final number = double.tryParse(text.trim().replaceAll(',', '.'));
          if (number == null || !number.isFinite) {
            document.error = 'Saisissez un nombre valide.';
            onChanged();
            return false;
          }
          return commit(() => update(number));
        },
      ),
    );

    final overrides = _overrides();
    return StudioSection(
      title: 'Caméra du jeu',
      collapsible: true,
      initiallyExpanded: false,
      children: [
        if (overrides != null) ...[
          StudioNotice(
            overrides,
            key: const ValueKey('map-camera-overrides'),
          ),
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
