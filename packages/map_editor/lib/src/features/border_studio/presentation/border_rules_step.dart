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
    final definition = state.workingDraft?.blueprint.definition;
    final rules = definition?.defaults;
    final template = definition?.template;
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
                      child: Text(_strictProfileLabel(template!)),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'border-studio-profile-wild',
                      ),
                      onPressed: () => onRulesChanged(_wildFrom(rules)),
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _isWild(rules),
                      leading: const Icon(CupertinoIcons.wind),
                      child: Text(_wildProfileLabel(template)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BorderStudioNotice(
                  title: _isStrict(rules)
                      ? _strictAppliedLabel(template)
                      : _isWild(rules)
                          ? _wildAppliedLabel(template)
                          : 'Réglage personnalisé',
                  description:
                      'Les valeurs restent entières et déterministes pour chaque seed.',
                  tone: PokeMapTone.info,
                  icon: CupertinoIcons.checkmark_seal,
                ),
                const SizedBox(height: 12),
                PokeMapCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PokeMapGuidedSlider(
                        key: const ValueKey<String>(
                          'border-studio-regularity-control',
                        ),
                        label: 'Régularité',
                        description:
                            'Élevée pour un tracé calme, basse pour plus d’aspérités.',
                        value: 100 - rules.irregularityPermille ~/ 10,
                        onChanged: (value) => onRulesChanged(
                          _copyRules(
                            rules,
                            irregularityPermille: (100 - value) * 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PokeMapGuidedSlider(
                        key: const ValueKey<String>(
                          'border-studio-details-control',
                        ),
                        label: 'Quantité de détails',
                        description:
                            'Dose les petits éléments ajoutés autour de la structure.',
                        value: rules.detailDensityPermille ~/ 10,
                        onChanged: (value) => onRulesChanged(
                          _copyRules(
                            rules,
                            detailDensityPermille: value * 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PokeMapGuidedSlider(
                        key: const ValueKey<String>(
                          'border-studio-variety-control',
                        ),
                        label: 'Variété',
                        description:
                            'Augmente la fréquence des alternatives compatibles.',
                        value: rules.variationPermille ~/ 10,
                        onChanged: (value) => onRulesChanged(
                          _copyRules(
                            rules,
                            variationPermille: value * 10,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    description: template == BorderBlueprintTemplate.organicEdge
                        ? 'Chevauchement ${rules.maxOverlapPx} px · vide toléré ${rules.gapTolerancePx} px · profondeur ${rules.depthRows} rangée(s)'
                        : 'Chevauchement ${rules.maxOverlapPx} px · vide toléré ${rules.gapTolerancePx} px',
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
      _copyRules(
        current,
        irregularityPermille: 100,
        detailDensityPermille: 250,
        variationPermille: 100,
      );

  BorderGenerationParams _wildFrom(BorderGenerationParams current) =>
      _copyRules(
        current,
        irregularityPermille: 750,
        detailDensityPermille: 700,
        variationPermille: 700,
      );

  bool _isStrict(BorderGenerationParams rules) =>
      rules.irregularityPermille == 100 &&
      rules.detailDensityPermille == 250 &&
      rules.variationPermille == 100;

  bool _isWild(BorderGenerationParams rules) =>
      rules.irregularityPermille == 750 &&
      rules.detailDensityPermille == 700 &&
      rules.variationPermille == 700;

  BorderGenerationParams _copyRules(
    BorderGenerationParams source, {
    int? irregularityPermille,
    int? detailDensityPermille,
    int? variationPermille,
  }) =>
      BorderGenerationParams(
        irregularityPermille:
            irregularityPermille ?? source.irregularityPermille,
        detailDensityPermille:
            detailDensityPermille ?? source.detailDensityPermille,
        variationPermille: variationPermille ?? source.variationPermille,
        maxOverlapPx: source.maxOverlapPx,
        gapTolerancePx: source.gapTolerancePx,
        depthRows: source.depthRows,
      );

  String _strictProfileLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Strict et régulier',
        BorderBlueprintTemplate.masonryLine => 'Aligné',
        BorderBlueprintTemplate.postAndRailLine => 'Régulier',
      };

  String _wildProfileLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Organique et sauvage',
        BorderBlueprintTemplate.masonryLine => 'Vieilli',
        BorderBlueprintTemplate.postAndRailLine => 'Rustique',
      };

  String _strictAppliedLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Profil strict appliqué',
        BorderBlueprintTemplate.masonryLine => 'Profil aligné appliqué',
        BorderBlueprintTemplate.postAndRailLine => 'Profil régulier appliqué',
      };

  String _wildAppliedLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Profil sauvage appliqué',
        BorderBlueprintTemplate.masonryLine => 'Profil vieilli appliqué',
        BorderBlueprintTemplate.postAndRailLine => 'Profil rustique appliqué',
      };
}
