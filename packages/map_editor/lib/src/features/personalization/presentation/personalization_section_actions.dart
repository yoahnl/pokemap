import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/project_presentation_presets.dart';

class PersonalizationSectionActions extends StatelessWidget {
  const PersonalizationSectionActions({
    super.key,
    required this.profile,
    required this.category,
    required this.baselineProfile,
    required this.onProfileChanged,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationCategory category;
  final ProjectPresentationProfile? baselineProfile;
  final ValueChanged<ProjectPresentationProfile>? onProfileChanged;

  @override
  Widget build(BuildContext context) {
    final comparison = baselineProfile == null
        ? null
        : compareProjectPresentation(baselineProfile!, profile);
    final presets = projectPresentationPresets
        .where((preset) => preset.supports(category))
        .toList(growable: false);
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final preset in presets)
                PokeMapButton(
                  key: ValueKey<String>('personalization-preset-${preset.id}'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  onPressed: onProfileChanged == null
                      ? null
                      : () =>
                            onProfileChanged!(preset.apply(profile, category)),
                  child: Text(preset.label),
                ),
              PokeMapButton(
                key: ValueKey<String>('personalization-reset-${category.name}'),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(Icons.restart_alt),
                onPressed: onProfileChanged == null
                    ? null
                    : () => onProfileChanged!(
                        resetProjectPresentationCategory(profile, category),
                      ),
                child: const Text('Réinitialiser cette section'),
              ),
              if (comparison != null)
                PokeMapBadge(
                  label: comparison.isIdentical
                      ? 'Aucun changement'
                      : '${comparison.changedPaths.length} changements',
                  variant: comparison.isIdentical
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.info,
                ),
            ],
          ),
          if (comparison != null && !comparison.isIdentical) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              comparison.changedPaths.join('  •  '),
              key: const ValueKey<String>('personalization-comparison-paths'),
            ),
          ],
        ],
      ),
    );
  }
}
