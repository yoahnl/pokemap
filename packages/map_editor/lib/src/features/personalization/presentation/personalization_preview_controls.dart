import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';

class PersonalizationPreviewControls extends StatelessWidget {
  static const capabilityIds = <String>{
    'preview.viewport',
    'preview.textScale',
    'preview.reducedMotion',
    'preview.compare',
  };

  const PersonalizationPreviewControls({
    super.key,
    required this.scenario,
    required this.onChanged,
  });

  final PersonalizationPreviewScenario scenario;
  final ValueChanged<PersonalizationPreviewScenario> onChanged;

  @override
  Widget build(BuildContext context) {
    const textScales = <(String, double)>[('100', 1), ('150', 1.5), ('200', 2)];
    const viewports = <PersonalizationPreviewViewport>[
      PersonalizationPreviewViewport.landscape,
      PersonalizationPreviewViewport.portrait,
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        PokeMapSegmentedTabs(
          minimumHeight: 48,
          tabs: <PokeMapSegmentedTab>[
            for (final viewport in viewports)
              PokeMapSegmentedTab(
                key: ValueKey<String>(
                  'personalization-preview-viewport-${viewport.name}',
                ),
                label: _viewportLabel(viewport),
                icon: _viewportIcon(viewport),
                selected: scenario.viewport == viewport,
                onTap: () => onChanged(scenario.copyWith(viewport: viewport)),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text('Taille du texte'),
            PokeMapSegmentedTabs(
              minimumHeight: 48,
              tabs: <PokeMapSegmentedTab>[
                for (final entry in textScales)
                  PokeMapSegmentedTab(
                    key: ValueKey<String>(
                      'personalization-preview-text-scale-${entry.$1}',
                    ),
                    label: '${entry.$1} %',
                    selected: scenario.textScale == entry.$2,
                    onTap: () =>
                        onChanged(scenario.copyWith(textScale: entry.$2)),
                  ),
              ],
            ),
          ],
        ),
        if (scenario.supportsReducedMotion)
          PokeMapButton(
            key: const ValueKey<String>(
              'personalization-preview-reduced-motion',
            ),
            size: PokeMapButtonSize.large,
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
            key: const ValueKey<String>('personalization-preview-compare'),
            size: PokeMapButtonSize.large,
            variant: PokeMapButtonVariant.secondary,
            isSelected: scenario.showComparison,
            onPressed: () => onChanged(
              scenario.copyWith(comparisonEnabled: !scenario.comparisonEnabled),
            ),
            leading: const Icon(Icons.compare_outlined),
            child: Text(
              scenario.showComparison
                  ? 'Fermer la comparaison'
                  : 'Comparer avant/après',
            ),
          ),
      ],
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
