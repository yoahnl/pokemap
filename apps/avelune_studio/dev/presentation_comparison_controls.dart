import 'package:flutter/material.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';

class PresentationComparisonControls extends StatelessWidget {
  const PresentationComparisonControls({super.key, required this.controller});
  final SpatialSceneController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SizedBox(
      width: 960,
      child: Column(
        children: [
          Text(
            'Essai visuel · copie HeartGold · réglages temporaires',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: StudioToggleRow(
                  key: const ValueKey('presentation-preview-halos'),
                  label: 'Halos lumineux',
                  value: controller.halosEnabled,
                  onChanged: (value) => controller.halosEnabled = value,
                ),
              ),
              Expanded(
                child: StudioToggleRow(
                  key: const ValueKey('presentation-preview-fog'),
                  label: 'Brume en profondeur',
                  value: controller.depthFogEnabled,
                  onChanged: (value) => controller.depthFogEnabled = value,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
