import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';

class PersonalizationPreviewControls extends StatelessWidget {
  const PersonalizationPreviewControls({
    super.key,
    required this.scenario,
    required this.onChanged,
  });

  final PersonalizationPreviewScenario scenario;
  final ValueChanged<PersonalizationPreviewScenario> onChanged;

  @override
  Widget build(BuildContext context) {
    const textScales = <(String, double)>[
      ('100', 1),
      ('125', 1.25),
      ('150', 1.5),
      ('200', 2),
    ];
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Simulation locale',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final viewport in PersonalizationPreviewViewport.values)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preview-viewport-${viewport.name}',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: scenario.viewport == viewport,
                  onPressed: () =>
                      onChanged(scenario.copyWith(viewport: viewport)),
                  leading: Icon(_viewportIcon(viewport)),
                  child: Text(_viewportLabel(viewport)),
                ),
              for (final entry in textScales)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preview-text-scale-${entry.$1}',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: scenario.textScale == entry.$2,
                  onPressed: () =>
                      onChanged(scenario.copyWith(textScale: entry.$2)),
                  child: Text('${entry.$1} %'),
                ),
              PokeMapButton(
                key: const ValueKey<String>(
                  'personalization-preview-reduced-motion',
                ),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                isSelected: scenario.reducedMotion,
                onPressed: () => onChanged(
                  scenario.copyWith(reducedMotion: !scenario.reducedMotion),
                ),
                leading: const Icon(Icons.motion_photos_off_outlined),
                child: const Text('Mouvement réduit'),
              ),
              if (scenario.canCompare)
                PokeMapButton(
                  key: const ValueKey<String>(
                    'personalization-preview-compare',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: scenario.showComparison,
                  onPressed: () => onChanged(
                    scenario.copyWith(
                      comparisonEnabled: !scenario.comparisonEnabled,
                    ),
                  ),
                  leading: const Icon(Icons.compare_outlined),
                  child: Text(
                    scenario.showComparison
                        ? 'Fermer la comparaison'
                        : 'Comparer avant/après',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _viewportLabel(PersonalizationPreviewViewport viewport) =>
    switch (viewport) {
      PersonalizationPreviewViewport.landscape => 'Paysage',
      PersonalizationPreviewViewport.portrait => 'Portrait',
      PersonalizationPreviewViewport.square => 'Carré',
      PersonalizationPreviewViewport.phoneLandscape => 'Téléphone paysage',
    };

IconData _viewportIcon(PersonalizationPreviewViewport viewport) =>
    switch (viewport) {
      PersonalizationPreviewViewport.landscape => Icons.stay_current_landscape,
      PersonalizationPreviewViewport.portrait => Icons.stay_current_portrait,
      PersonalizationPreviewViewport.square => Icons.crop_square,
      PersonalizationPreviewViewport.phoneLandscape =>
        Icons.stay_current_landscape,
    };
