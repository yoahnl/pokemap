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
    final isConnectedLine = template == BorderBlueprintTemplate.connectedLine;
    final isStoneChain = template == BorderBlueprintTemplate.stoneChainLine;
    final supportsAutoRotation = isConnectedLine ||
        isStoneChain ||
        template == BorderBlueprintTemplate.masonryLine;
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
                      onPressed: () =>
                          onRulesChanged(_strictFrom(rules, template)),
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _isStrict(rules, template!),
                      leading: const Icon(CupertinoIcons.rectangle_grid_1x2),
                      child: Text(_strictProfileLabel(template)),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'border-studio-profile-wild',
                      ),
                      onPressed: () =>
                          onRulesChanged(_wildFrom(rules, template)),
                      variant: PokeMapButtonVariant.secondary,
                      isSelected: _isWild(rules, template),
                      leading: const Icon(CupertinoIcons.wind),
                      child: Text(_wildProfileLabel(template)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BorderStudioNotice(
                  title: _isStrict(rules, template)
                      ? _strictAppliedLabel(template)
                      : _isWild(rules, template)
                          ? _wildAppliedLabel(template)
                          : 'Réglage personnalisé',
                  description:
                      'Les valeurs restent entières et déterministes pour chaque seed.',
                  tone: PokeMapTone.info,
                  icon: CupertinoIcons.checkmark_seal,
                ),
                const SizedBox(height: 12),
                if (supportsAutoRotation) ...[
                  PokeMapToggleTile(
                    key: const ValueKey<String>(
                      'border-studio-auto-rotation-toggle',
                    ),
                    label: 'Rotation automatique',
                    description: rules.allowAutoRotation
                        ? 'Oriente chaque morceau pour suivre la ligne.'
                        : isStoneChain
                            ? 'Conserve l\'éclairage et l\'orientation d\'origine des pierres.'
                            : 'Conserve l\'asset sans rotation.',
                    value: rules.allowAutoRotation,
                    onChanged: (value) => onRulesChanged(
                      _copyRules(rules, allowAutoRotation: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (isStoneChain) ...[
                  PokeMapToggleTile(
                    key: const ValueKey<String>(
                      'border-studio-two-tier-toggle',
                    ),
                    label: 'Deux étages continus',
                    description: rules.depthRows == 2
                        ? 'Assemble un Sommet plat et une Face de falaise distincts.'
                        : 'Dessine uniquement le Sommet plat.',
                    value: rules.depthRows == 2,
                    onChanged: (value) => onRulesChanged(
                      _copyRules(rules, depthRows: value ? 2 : 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PokeMapCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isStoneChain) ...[
                        PokeMapGuidedSlider(
                          key: const ValueKey<String>(
                            'border-studio-stone-interlock-control',
                          ),
                          label: 'Imbrication des pierres',
                          description:
                              'Rapproche les pierres des deux rangées pour former une falaise continue.',
                          value: (rules.maxOverlapPx * 100 / 12).round(),
                          onChanged: (value) => onRulesChanged(
                            _copyRules(
                              rules,
                              maxOverlapPx: (value * 12 / 100).round(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PokeMapGuidedSlider(
                          key: const ValueKey<String>(
                            'border-studio-stone-spacing-control',
                          ),
                          label: 'Espacement des pierres',
                          description:
                              'Ajuste le petit vide toléré entre deux pierres principales.',
                          value: (rules.gapTolerancePx * 100 / 8).round(),
                          onChanged: (value) => onRulesChanged(
                            _copyRules(
                              rules,
                              gapTolerancePx: (value * 8 / 100).round(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PokeMapGuidedSlider(
                          key: const ValueKey<String>(
                            'border-studio-stone-irregularity-control',
                          ),
                          label: 'Irrégularité des pierres',
                          description:
                              'Décale légèrement la chaîne sans créer de gros blocs.',
                          value: rules.irregularityPermille ~/ 10,
                          onChanged: (value) => onRulesChanged(
                            _copyRules(
                              rules,
                              irregularityPermille: value * 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PokeMapGuidedSlider(
                          key: const ValueKey<String>(
                            'border-studio-stone-secondary-density-control',
                          ),
                          label: 'Pierres secondaires',
                          description:
                              'Dose les petites pierres et rochers facultatifs.',
                          value: rules.detailDensityPermille ~/ 10,
                          onChanged: (value) => onRulesChanged(
                            _copyRules(
                              rules,
                              detailDensityPermille: value * 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (!isConnectedLine) ...[
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
                      ],
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
                if (isStoneChain &&
                    rules.depthRows == 2 &&
                    rules.gapTolerancePx > 0) ...[
                  const SizedBox(height: 12),
                  const BorderStudioNotice(
                    title: 'Espacement visible entre les pierres',
                    description:
                        'Avec deux étages, un espacement supérieur à 0 px peut ouvrir la falaise. Ramenez-le à 0 px pour une bordure continue.',
                    tone: PokeMapTone.warning,
                    icon: CupertinoIcons.exclamationmark_triangle,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isStoneChain) ...[
                      PokeMapStatusTile(
                        label: 'Espacement',
                        value: '${rules.gapTolerancePx} px',
                      ),
                      PokeMapStatusTile(
                        label: 'Irrégularité',
                        value: '${rules.irregularityPermille ~/ 10} %',
                      ),
                      PokeMapStatusTile(
                        label: 'Pierres secondaires',
                        value: '${rules.detailDensityPermille ~/ 10} %',
                      ),
                    ] else if (!isConnectedLine) ...[
                      PokeMapStatusTile(
                        label: 'Régularité',
                        value: '${100 - rules.irregularityPermille ~/ 10} %',
                      ),
                      PokeMapStatusTile(
                        label: 'Quantité de détails',
                        value: '${rules.detailDensityPermille ~/ 10} %',
                      ),
                    ],
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
                    description: template ==
                                BorderBlueprintTemplate.organicEdge ||
                            isStoneChain
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

  BorderGenerationParams _strictFrom(
    BorderGenerationParams current,
    BorderBlueprintTemplate template,
  ) =>
      template == BorderBlueprintTemplate.stoneChainLine
          ? _copyRules(
              current,
              irregularityPermille: 180,
              detailDensityPermille: 0,
              variationPermille: 1000,
              maxOverlapPx: 8,
              gapTolerancePx: 0,
              depthRows: 2,
              allowAutoRotation: false,
            )
          : _copyRules(
              current,
              irregularityPermille: 100,
              detailDensityPermille: 250,
              variationPermille: 100,
              maxOverlapPx:
                  template == BorderBlueprintTemplate.connectedLine ? 4 : null,
              gapTolerancePx:
                  template == BorderBlueprintTemplate.connectedLine ? 1 : null,
            );

  BorderGenerationParams _wildFrom(
    BorderGenerationParams current,
    BorderBlueprintTemplate template,
  ) =>
      template == BorderBlueprintTemplate.stoneChainLine
          ? _copyRules(
              current,
              irregularityPermille: 420,
              detailDensityPermille: 330,
              variationPermille: 1000,
              maxOverlapPx: 2,
              gapTolerancePx: 3,
              depthRows: 2,
              allowAutoRotation: false,
            )
          : _copyRules(
              current,
              irregularityPermille: 750,
              detailDensityPermille: 700,
              variationPermille: 700,
              maxOverlapPx:
                  template == BorderBlueprintTemplate.connectedLine ? 32 : null,
              gapTolerancePx:
                  template == BorderBlueprintTemplate.connectedLine ? 6 : null,
            );

  bool _isStrict(
    BorderGenerationParams rules,
    BorderBlueprintTemplate template,
  ) =>
      template == BorderBlueprintTemplate.stoneChainLine
          ? rules.irregularityPermille == 180 &&
              rules.detailDensityPermille == 0 &&
              rules.variationPermille == 1000 &&
              rules.maxOverlapPx == 8 &&
              rules.gapTolerancePx == 0 &&
              rules.depthRows == 2 &&
              !rules.allowAutoRotation
          : rules.irregularityPermille == 100 &&
              rules.detailDensityPermille == 250 &&
              rules.variationPermille == 100 &&
              (template != BorderBlueprintTemplate.connectedLine ||
                  (rules.maxOverlapPx == 4 && rules.gapTolerancePx == 1));

  bool _isWild(
    BorderGenerationParams rules,
    BorderBlueprintTemplate template,
  ) =>
      template == BorderBlueprintTemplate.stoneChainLine
          ? rules.irregularityPermille == 420 &&
              rules.detailDensityPermille == 330 &&
              rules.variationPermille == 1000 &&
              rules.maxOverlapPx == 2 &&
              rules.gapTolerancePx == 3 &&
              rules.depthRows == 2 &&
              !rules.allowAutoRotation
          : rules.irregularityPermille == 750 &&
              rules.detailDensityPermille == 700 &&
              rules.variationPermille == 700 &&
              (template != BorderBlueprintTemplate.connectedLine ||
                  (rules.maxOverlapPx == 32 && rules.gapTolerancePx == 6));

  BorderGenerationParams _copyRules(
    BorderGenerationParams source, {
    int? irregularityPermille,
    int? detailDensityPermille,
    int? variationPermille,
    int? maxOverlapPx,
    int? gapTolerancePx,
    int? depthRows,
    bool? allowAutoRotation,
  }) =>
      BorderGenerationParams(
        irregularityPermille:
            irregularityPermille ?? source.irregularityPermille,
        detailDensityPermille:
            detailDensityPermille ?? source.detailDensityPermille,
        variationPermille: variationPermille ?? source.variationPermille,
        maxOverlapPx: maxOverlapPx ?? source.maxOverlapPx,
        gapTolerancePx: gapTolerancePx ?? source.gapTolerancePx,
        depthRows: depthRows ?? source.depthRows,
        allowAutoRotation: allowAutoRotation ?? source.allowAutoRotation,
      );

  String _strictProfileLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Strict et régulier',
        BorderBlueprintTemplate.masonryLine => 'Aligné',
        BorderBlueprintTemplate.postAndRailLine => 'Régulier',
        BorderBlueprintTemplate.connectedLine => 'Net et régulier',
        BorderBlueprintTemplate.stoneChainLine => 'Fin et côtier',
      };

  String _wildProfileLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Organique et sauvage',
        BorderBlueprintTemplate.masonryLine => 'Vieilli',
        BorderBlueprintTemplate.postAndRailLine => 'Rustique',
        BorderBlueprintTemplate.connectedLine => 'Varié et naturel',
        BorderBlueprintTemplate.stoneChainLine => 'Naturel et irrégulier',
      };

  String _strictAppliedLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Profil strict appliqué',
        BorderBlueprintTemplate.masonryLine => 'Profil aligné appliqué',
        BorderBlueprintTemplate.postAndRailLine => 'Profil régulier appliqué',
        BorderBlueprintTemplate.connectedLine => 'Profil régulier appliqué',
        BorderBlueprintTemplate.stoneChainLine =>
          'Profil fin et côtier appliqué',
      };

  String _wildAppliedLabel(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge => 'Profil sauvage appliqué',
        BorderBlueprintTemplate.masonryLine => 'Profil vieilli appliqué',
        BorderBlueprintTemplate.postAndRailLine => 'Profil rustique appliqué',
        BorderBlueprintTemplate.connectedLine => 'Profil varié appliqué',
        BorderBlueprintTemplate.stoneChainLine => 'Profil naturel appliqué',
      };
}
