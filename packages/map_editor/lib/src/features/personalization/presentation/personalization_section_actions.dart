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
    final changedSections = comparison == null
        ? const <String>[]
        : _changedSectionLabels(comparison.changedPaths);
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
                      : changedSections.length == 1
                      ? '1 section modifiée'
                      : '${changedSections.length} sections modifiées',
                  variant: comparison.isIdentical
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.info,
                ),
            ],
          ),
          if (comparison != null && !comparison.isIdentical) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              changedSections.join('  •  '),
              key: const ValueKey<String>('personalization-comparison-paths'),
            ),
          ],
        ],
      ),
    );
  }
}

List<String> _changedSectionLabels(List<String> paths) => <String>{
  for (final path in paths) _changedSectionLabel(path),
}.toList(growable: false);

String _changedSectionLabel(String path) {
  if (path.startsWith(r'$.branding')) return 'Identité visuelle';
  if (path.startsWith(r'$.titleMotion')) return 'Animations du titre';
  if (path.startsWith(r'$.title')) return 'Écran titre';
  if (path.startsWith(r'$.intro')) return 'Introduction';
  if (path.startsWith(r'$.typography')) return 'Typographie';
  if (path.startsWith(r'$.theme')) return 'Couleurs globales';
  if (path.startsWith(r'$.surfacePalettes')) {
    return 'Couleurs des interfaces';
  }
  if (path.startsWith(r'$.pause')) return 'Menu Pause';
  if (path.startsWith(r'$.menuLabels')) return 'Libellés des menus';
  if (path.startsWith(r'$.windows')) return 'Forme des fenêtres';
  if (path.startsWith(r'$.layouts')) return 'Disposition';
  return 'Autres réglages';
}
