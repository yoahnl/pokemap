import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

class BorderRulesStep extends StatelessWidget {
  const BorderRulesStep({
    super.key,
    required this.state,
    required this.onRulesChanged,
  });

  final BorderStudioDraftState state;
  final ValueChanged<BorderGenerationParams> onRulesChanged;

  @override
  Widget build(BuildContext context) {
    final rules = state.workingDraft?.blueprint.definition.defaults;
    return BorderStudioStepScaffold(
      title: '4. Règles',
      description:
          'Réglez le caractère visuel avec des profils guidés, sans toucher aux données internes.',
      child: rules == null
          ? const PokeMapEmptyState(
              title: 'Créez un blueprint pour régler son assemblage',
              icon: Icon(CupertinoIcons.slider_horizontal_3),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'border-studio-profile-strict',
                      ),
                      onPressed: () => onRulesChanged(_strictFrom(rules)),
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _isStrict(rules),
                      leading: const Icon(CupertinoIcons.rectangle_grid_1x2),
                      child: const Text('Strict et régulier'),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'border-studio-profile-wild',
                      ),
                      onPressed: () => onRulesChanged(_wildFrom(rules)),
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _isWild(rules),
                      leading: const Icon(CupertinoIcons.wind),
                      child: const Text('Organique et sauvage'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BorderStudioNotice(
                  title: _isStrict(rules)
                      ? 'Profil strict appliqué'
                      : _isWild(rules)
                          ? 'Profil sauvage appliqué'
                          : 'Réglage personnalisé',
                  description:
                      'Les valeurs restent entières et déterministes pour chaque seed.',
                  tone: PokeMapTone.info,
                  icon: CupertinoIcons.checkmark_seal,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PokeMapStatusTile(
                      label: 'Régularité',
                      value: '${100 - rules.irregularityPermille ~/ 10} %',
                    ),
                    PokeMapStatusTile(
                      label: 'Quantité de détails',
                      value: '${rules.detailDensityPermille ~/ 10} %',
                    ),
                    PokeMapStatusTile(
                      label: 'Variété',
                      value: '${rules.variationPermille ~/ 10} %',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PokeMapCard(
                  child: PokeMapSectionHeader(
                    title: 'Réglages avancés',
                    description:
                        'Chevauchement ${rules.maxOverlapPx} px · vide toléré ${rules.gapTolerancePx} px · profondeur ${rules.depthRows} rangée(s)',
                    trailing: const PokeMapBadge(
                      label: 'Guidés',
                      variant: PokeMapBadgeVariant.neutral,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  BorderGenerationParams _strictFrom(BorderGenerationParams current) =>
      BorderGenerationParams(
        irregularityPermille: 100,
        detailDensityPermille: 250,
        variationPermille: 100,
        maxOverlapPx: current.maxOverlapPx,
        gapTolerancePx: current.gapTolerancePx,
        depthRows: current.depthRows,
      );

  BorderGenerationParams _wildFrom(BorderGenerationParams current) =>
      BorderGenerationParams(
        irregularityPermille: 750,
        detailDensityPermille: 700,
        variationPermille: 700,
        maxOverlapPx: current.maxOverlapPx,
        gapTolerancePx: current.gapTolerancePx,
        depthRows: current.depthRows,
      );

  bool _isStrict(BorderGenerationParams rules) =>
      rules.irregularityPermille == 100 &&
      rules.detailDensityPermille == 250 &&
      rules.variationPermille == 100;

  bool _isWild(BorderGenerationParams rules) =>
      rules.irregularityPermille == 750 &&
      rules.detailDensityPermille == 700 &&
      rules.variationPermille == 700;
}
