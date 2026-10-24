import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class MapDayNightPanel extends StatelessWidget {
  const MapDayNightPanel({
    super.key,
    required this.document,
    required this.onChanged,
    this.controller,
  });
  final EditableMapDocument document;
  final VoidCallback onChanged;
  final SpatialSceneController? controller;

  @override
  Widget build(BuildContext context) {
    final cycle = document.current.spatialScene?.dayNightCycle;
    bool commit(SpatialDayNightCycle? next) {
      try {
        document.commit(
          const SpatialMapOperations().configureDayNightCycle(
            document.current,
            next,
          ),
        );
        document.error = null;
        onChanged();
        return true;
      } on FormatException catch (failure) {
        document.error = '$failure';
        onChanged();
        return false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jour et nuit', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StudioToggleRow(
          key: const ValueKey('map-day-night-enabled'),
          label: 'Activer le cycle jour/nuit',
          value: cycle != null,
          onChanged: (enabled) =>
              commit(enabled ? SpatialDayNightCycle() : null),
        ),
        if (cycle != null) ...[
          const SizedBox(height: 8),
          StudioCommitField(
            key: const ValueKey('map-day-night-duration'),
            label: 'Durée d’une journée (minutes)',
            value: '${cycle.durationSeconds / 60}',
            tryCommit: (text) {
              final minutes = double.tryParse(text.trim().replaceAll(',', '.'));
              if (minutes == null ||
                  !minutes.isFinite ||
                  minutes * 60 < 10 ||
                  minutes * 60 > 86400) {
                document.error =
                    'Choisissez une durée entre 10 secondes et 24 heures.';
                onChanged();
                return false;
              }
              return commit(
                SpatialDayNightCycle(
                  durationSeconds: minutes * 60,
                  startMinuteOfDay: cycle.startMinuteOfDay,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          StudioCommitField(
            key: const ValueKey('map-day-night-start'),
            label: 'Heure au début (HH:mm)',
            value:
                '${(cycle.startMinuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(cycle.startMinuteOfDay % 60).toString().padLeft(2, '0')}',
            tryCommit: (text) {
              final parts = text.trim().split(':');
              final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
              final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
              if (hour == null ||
                  minute == null ||
                  hour < 0 ||
                  hour > 23 ||
                  minute < 0 ||
                  minute > 59) {
                document.error = 'Saisissez une heure entre 00:00 et 23:59.';
                onChanged();
                return false;
              }
              return commit(
                SpatialDayNightCycle(
                  durationSeconds: cycle.durationSeconds,
                  startMinuteOfDay: hour * 60 + minute,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Ce cycle règle l’ambiance visuelle de la carte. Les horaires des personnages et des rencontres restent indépendants.',
          ),
          if (controller case final preview?) ...[
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: preview,
              builder: (context, _) {
                final time =
                    (preview.dayNightMinuteOfDay ??
                            preview.previewMinuteOfDay ??
                            cycle.startMinuteOfDay.toDouble())
                        .floor();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu · ${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (id, label, minute) in [
                          ('dawn', 'Aube', 360),
                          ('day', 'Jour', 720),
                          ('dusk', 'Crépuscule', 1080),
                          ('night', 'Nuit', 1320),
                        ])
                          StudioButton(
                            key: ValueKey('day-night-preview-$id'),
                            label: label,
                            secondary: true,
                            onPressed: () =>
                                preview.previewMinuteOfDay = minute.toDouble(),
                          ),
                        StudioButton(
                          key: const ValueKey('day-night-preview-play'),
                          label: preview.previewDayNightRunning
                              ? 'Pause'
                              : 'Lire le cycle',
                          secondary: true,
                          onPressed: () => preview.previewDayNightRunning =
                              !preview.previewDayNightRunning,
                        ),
                        StudioButton(
                          key: const ValueKey('day-night-preview-reset'),
                          label: 'Revenir à l’heure de départ',
                          secondary: true,
                          onPressed: () => preview.previewMinuteOfDay = null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('L’aperçu ne modifie pas l’heure enregistrée.'),
                  ],
                );
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
