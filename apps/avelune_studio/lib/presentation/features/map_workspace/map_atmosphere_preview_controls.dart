import 'package:flutter/material.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/inputs/studio_toggle_row.dart';

class MapAtmospherePreviewControls extends StatelessWidget {
  const MapAtmospherePreviewControls({super.key, required this.controller});

  final SpatialSceneController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final available = controller.atmosphereAvailability;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ambiance · aperçu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ces effets s’appliquent immédiatement à cet aperçu, sans modifier la carte enregistrée.',
          ),
          StudioToggleRow(
            key: const ValueKey('atmosphere-preview-water'),
            label: 'Eau animée',
            value: controller.waterAnimated,
            description: available.water
                ? 'Ondulations et reflets sur les surfaces d’eau de l’essai.'
                : 'Aucune surface d’eau définie pour cet aperçu.',
            onChanged: available.water
                ? (value) => controller.waterAnimated = value
                : null,
          ),
          StudioToggleRow(
            key: const ValueKey('atmosphere-preview-windows'),
            label: 'Fenêtres éclairées',
            value: controller.windowsLit,
            description: available.windows
                ? 'Une lumière chaude apparaît dans les fenêtres le soir.'
                : 'Aucune fenêtre définie pour cet aperçu.',
            onChanged: available.windows
                ? (value) => controller.windowsLit = value
                : null,
          ),
          StudioToggleRow(
            key: const ValueKey('atmosphere-preview-fireflies'),
            label: 'Lucioles le soir',
            value: controller.fireflies,
            description: available.fireflies
                ? 'De petites lucioles apparaissent à la tombée du jour.'
                : 'Aucune zone de lucioles définie pour cet aperçu.',
            onChanged: available.fireflies
                ? (value) => controller.fireflies = value
                : null,
          ),
        ],
      );
    },
  );
}
