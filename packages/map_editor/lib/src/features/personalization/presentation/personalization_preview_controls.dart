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
      key: const ValueKey<String>('personalization-preview-primary-settings'),
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _PreviewOnlySetting(
          label: 'Format',
          child: PokeMapSegmentedTabs(
            minimumHeight: 48,
            tabs: <PokeMapSegmentedTab>[
              for (final viewport in viewports)
                PokeMapSegmentedTab(
                  key: ValueKey<String>(
                    'personalization-preview-viewport-${viewport.name}',
                  ),
                  label: _viewportLabel(viewport),
                  semanticLabel:
                      '${_viewportLabel(viewport)}, aperçu uniquement',
                  icon: _viewportIcon(viewport),
                  selected: scenario.viewport == viewport,
                  onTap: () => onChanged(scenario.copyWith(viewport: viewport)),
                ),
            ],
          ),
        ),
        _PreviewOnlySetting(
          label: 'Taille du texte',
          child: PokeMapSegmentedTabs(
            minimumHeight: 48,
            tabs: <PokeMapSegmentedTab>[
              for (final entry in textScales)
                PokeMapSegmentedTab(
                  key: ValueKey<String>(
                    'personalization-preview-text-scale-${entry.$1}',
                  ),
                  label: '${entry.$1} %',
                  semanticLabel: '${entry.$1} %, aperçu uniquement',
                  selected: scenario.textScale == entry.$2,
                  onTap: () =>
                      onChanged(scenario.copyWith(textScale: entry.$2)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PersonalizationPreviewSecondaryControls extends StatelessWidget {
  const PersonalizationPreviewSecondaryControls({
    super.key,
    required this.scenario,
    required this.onChanged,
  });

  final PersonalizationPreviewScenario scenario;
  final ValueChanged<PersonalizationPreviewScenario> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      if (scenario.supportsReducedMotion)
        PokeMapButton(
          key: const ValueKey<String>('personalization-preview-reduced-motion'),
          size: PokeMapButtonSize.medium,
          variant: PokeMapButtonVariant.secondary,
          semanticLabel: 'Mouvement réduit, aperçu uniquement',
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
          size: PokeMapButtonSize.medium,
          variant: PokeMapButtonVariant.secondary,
          semanticLabel: 'Comparer avant/après, aperçu uniquement',
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

class _PreviewOnlySetting extends StatelessWidget {
  const _PreviewOnlySetting({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      child,
    ],
  );
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
