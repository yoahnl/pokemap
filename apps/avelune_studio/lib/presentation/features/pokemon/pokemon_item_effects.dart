import '../../../features/pokemon/application/pokemon_item_effects_controller.dart';
import '../../../features/pokemon/application/pokemon_item_effect_editing.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'pokemon_commerce_integer_field.dart';
import 'pokemon_capture_sprite_picker.dart';
import 'pokemon_ui_parts.dart';

class PokemonItemEffects extends StatelessWidget {
  const PokemonItemEffects({super.key, required this.commerce, this.pickPng});

  final PokemonCommerceController commerce;
  final Future<String?> Function()? pickPng;

  PokemonItemEffectsController get _effects =>
      PokemonItemEffectsController(commerce);
  ProjectItemUseDefinition? _use(ProjectItemUseContext context) =>
      _effects.useFor(context);
  void _set(
    ProjectItemUseContext context,
    ProjectItemUseDefinition? replacement,
  ) => _effects.setUse(context, replacement);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PokemonSectionHeading(
        title: 'Effets structurés',
        description: 'Les actions ci-dessous utilisent les capacités reconnues par le runtime.',
      ),
      _card(ProjectItemUseContext.overworld, 'Hors combat'),
      const SizedBox(height: 12),
      _card(ProjectItemUseContext.battle, 'En combat'),
      const SizedBox(height: 12),
      if (commerce.item!.capture != null) ...[
        PokemonCaptureSpritePicker(commerce: commerce, pickPng: pickPng),
        const SizedBox(height: 12),
      ],
      PokemonSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PokemonSectionHeading(title: 'Autres capacités existantes'),
            PokemonDataRow(
              label: 'Effet porté',
              value: commerce.item!.heldEffectId ?? 'Aucun',
            ),
            PokemonDataRow(
              label: 'Capture',
              value: commerce.item!.capture == null ? 'Aucune' : 'Configurée',
            ),
            PokemonDataRow(
              label: 'CT / CS',
              value: commerce.item!.machine?.moveId ?? 'Aucune',
            ),
            const SizedBox(height: 8),
            const Text(
              'Les autres capacités importées sont conservées. Leur édition spécialisée n’est pas disponible dans cette fiche.',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _card(ProjectItemUseContext context, String title) {
    final use = _use(context);
    final kind = use == null ? null : PokemonItemEffectEditing.kind(use.effect);
    final supported =
        kind != 'imported' &&
        (context != ProjectItemUseContext.battle ||
            (kind != 'pp' &&
                kind != 'repel' &&
                kind != 'escape_rope' &&
                kind != 'bicycle' &&
                kind != 'fishing'));
    return PokemonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokemonSectionHeading(
            title: title,
            description: use == null
                ? 'Aucun effet configuré.'
                : 'Cible : ${use.target.name} · ${use.consumption == ProjectItemConsumptionPolicy.onApplied ? 'consommé si appliqué' : 'non consommé'}',
            trailing: use == null
                ? StudioButton(
                    label: 'Ajouter un effet',
                    icon: Icons.add,
                    onPressed: () => _set(
                      context,
                      PokemonItemEffectEditing.defaultUse(context),
                    ),
                  )
                : StudioButton(
                    label: 'Retirer',
                    secondary: true,
                    icon: Icons.remove_circle_outline,
                    onPressed: () => _set(context, null),
                  ),
          ),
          if (use != null) ...[
            if (!supported)
              const Text(
                'Effet importé conservé tel quel. Ce type n’est pas éditable ici.',
              )
            else ...[
              StudioSelect(
                label: 'Type d’effet',
                value: kind,
                options: {
                  'heal': 'Soigner les PV',
                  'full_restore': 'Soin Total',
                  'cure': 'Guérir les statuts',
                  'revive': 'Réanimer',
                  if (context == ProjectItemUseContext.overworld)
                    'vitamin': 'Vitamine (EV et bonheur)',
                  if (context == ProjectItemUseContext.battle) ...{
                    'battle_boost': 'Augmenter une statistique',
                    'focus_energy': 'Muscle + (critiques)',
                    'mist': 'Défense Spéciale (Brume)',
                  },
                  if (context == ProjectItemUseContext.overworld)
                    'pp': 'Restaurer les PP',
                  if (context == ProjectItemUseContext.overworld)
                    'repel': 'Repousse',
                  if (context == ProjectItemUseContext.overworld)
                    'escape_rope': 'Corde Sortie',
                  if (context == ProjectItemUseContext.overworld)
                    'bicycle': 'Vélo',
                  if (context == ProjectItemUseContext.overworld)
                    'fishing': 'Pêche',
                },
                onChanged: (value) => _set(
                  context,
                  PokemonItemEffectEditing.changeKind(use, value),
                ),
              ),
              const SizedBox(height: 10),
              if (use.target == ProjectItemTargetKind.partyMember ||
                  use.target == ProjectItemTargetKind.partyMove) ...[
                StudioToggleRow(
                  label: 'Réduire l’amitié après utilisation',
                  value: use.friendshipLoss != null,
                  onChanged: (enabled) => _set(
                    context,
                    PokemonItemEffectEditing.toggleFriendshipLoss(use, enabled),
                  ),
                ),
                if (use.friendshipLoss
                    case final ProjectItemFriendshipLoss loss)
                  for (final tier in ['low', 'medium', 'high'])
                    PokemonCommerceIntegerField(
                      key: ValueKey(
                        'item-friendship-${commerce.item!.id}-${context.name}-$tier',
                      ),
                      commerce: commerce,
                      fieldId:
                          'item-friendship-${commerce.item!.id}-${context.name}-$tier',
                      label:
                          'Amitié retirée (${tier == 'low'
                              ? '0–99'
                              : tier == 'medium'
                              ? '100–199'
                              : '200–255'})',
                      value: loss.toJson()[tier] as int,
                      minimum: 0,
                      maximum: 255,
                      optional: false,
                      onChanged: (value) => _set(
                        context,
                        PokemonItemEffectEditing.editFriendshipLoss(
                          use,
                          tier,
                          value,
                        ),
                      ),
                    ),
              ],
              if (use.effect
                  case final ProjectItemCureStatusEffectDefinition cure)
                StudioToggleRow(
                  label: 'Soigner aussi la confusion en combat',
                  value: cure.curesConfusion,
                  onChanged: (enabled) => _set(
                    context,
                    use.copyWith(
                      effect: cure.copyWith(curesConfusion: enabled),
                    ),
                  ),
                ),
              if (use.effect
                  case final ProjectItemVitaminEffectDefinition vitamin) ...[
                StudioSelect(
                  label: 'Statistique entraînée',
                  value: vitamin.stat.name,
                  options: {
                    for (final stat in ProjectItemVitaminStat.values)
                      stat.name: _statLabel(stat.name),
                  },
                  onChanged: (value) => _set(
                    context,
                    use.copyWith(
                      effect: vitamin.copyWith(
                        stat: ProjectItemVitaminStat.values.byName(value),
                      ),
                    ),
                  ),
                ),
                for (final field in [
                  'amount',
                  'maximumPerStat',
                  'maximumTotal',
                  'friendshipGainLow',
                  'friendshipGainMedium',
                  'friendshipGainHigh',
                ])
                  _integerEffectField(context, use, field, switch (field) {
                    'amount' => 'EV ajoutés',
                    'maximumPerStat' => 'Plafond d’EV par statistique',
                    'maximumTotal' => 'Plafond total d’EV',
                    'friendshipGainLow' => 'Bonheur ajouté (0–99)',
                    'friendshipGainMedium' => 'Bonheur ajouté (100–199)',
                    _ => 'Bonheur ajouté (200–255)',
                  }, (vitamin.toJson()[field] as int)),
              ],
              if (use.effect
                  case final ProjectItemBattleBoostEffectDefinition boost) ...[
                StudioSelect(
                  label: 'Statistique augmentée',
                  value: boost.stat.name,
                  options: {
                    for (final stat in ProjectItemBattleStat.values)
                      stat.name: _statLabel(stat.name),
                  },
                  onChanged: (value) => _set(
                    context,
                    use.copyWith(
                      effect: boost.copyWith(
                        stat: ProjectItemBattleStat.values.byName(value),
                      ),
                    ),
                  ),
                ),
                _integerEffectField(
                  context,
                  use,
                  'stages',
                  'Crans ajoutés (1–6)',
                  boost.stages,
                ),
              ],
              if (use.effect case ProjectItemBattlePreparationEffectDefinition(
                effect: ProjectItemBattlePreparationKind.mist,
                :final turns,
              ))
                _integerEffectField(
                  context,
                  use,
                  'turns',
                  'Durée en tours',
                  turns!,
                ),
              if (use.effect
                  case ProjectItemHealHpEffectDefinition(
                        :final mode,
                        :final amount,
                      ) ||
                      ProjectItemRestorePpEffectDefinition(
                        :final mode,
                        :final amount,
                      )) ...[
                StudioToggleRow(
                  label: 'Restaurer complètement',
                  value: mode == ProjectItemAmountMode.full,
                  onChanged: (value) => _set(
                    context,
                    PokemonItemEffectEditing.restoreMode(
                      use,
                      pp: kind == 'pp',
                      full: value,
                    ),
                  ),
                ),
                if (mode == ProjectItemAmountMode.flat)
                  PokemonCommerceIntegerField(
                    key: ValueKey(
                      'item-effect-${commerce.item!.id}-${context.name}-${commerce.formVersion}',
                    ),
                    commerce: commerce,
                    fieldId: 'item-effect-${commerce.item!.id}-${context.name}',
                    label: kind == 'pp' ? 'PP restaurés' : 'PV restaurés',
                    value: amount,
                    minimum: 1,
                    optional: false,
                    onChanged: (value) {
                      _set(
                        context,
                        PokemonItemEffectEditing.setAmount(
                          use,
                          pp: kind == 'pp',
                          amount: value!,
                        ),
                      );
                    },
                  ),
              ],
              if (use.effect case ProjectItemFishingEffectDefinition(
                :final rodKind,
              )) ...[
                StudioSelect(
                  label: 'Canne de pêche',
                  value: rodKind.name,
                  options: const {
                    'oldRod': 'Canne',
                    'goodRod': 'Super Canne',
                    'superRod': 'Méga Canne',
                  },
                  onChanged: (value) => _set(
                    context,
                    use.copyWith(
                      effect: ProjectItemEffectDefinition.fishing(
                        rodKind: ProjectFishingRodKind.values.singleWhere(
                          (kind) => kind.name == value,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La canne reste dans le sac. Peignez sa table sur une zone d’eau : la pêche vise la case devant le joueur.',
                ),
              ],
              if (use.effect case ProjectItemRepelEffectDefinition(
                :final steps,
              ))
                PokemonCommerceIntegerField(
                  key: ValueKey(
                    'item-repel-steps-${commerce.item!.id}-${commerce.formVersion}',
                  ),
                  commerce: commerce,
                  fieldId: 'item-effect-${commerce.item!.id}-${context.name}',
                  label: 'Nombre de pas',
                  value: steps,
                  minimum: 1,
                  optional: false,
                  onChanged: (value) => _set(
                    context,
                    use.copyWith(
                      effect: ProjectItemEffectDefinition.repel(steps: value!),
                    ),
                  ),
                ),
              StudioToggleRow(
                label: 'Consommer après application',
                value:
                    use.consumption == ProjectItemConsumptionPolicy.onApplied,
                onChanged:
                    use.friendshipLoss != null ||
                        kind == 'escape_rope' ||
                        kind == 'bicycle' ||
                        kind == 'fishing'
                    ? null
                    : (value) => _set(
                        context,
                        use.copyWith(
                          consumption: value
                              ? ProjectItemConsumptionPolicy.onApplied
                              : ProjectItemConsumptionPolicy.never,
                        ),
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _integerEffectField(
    ProjectItemUseContext context,
    ProjectItemUseDefinition use,
    String field,
    String label,
    int value,
  ) => PokemonCommerceIntegerField(
    key: ValueKey(
      'item-effect-${commerce.item!.id}-${context.name}-$field-${commerce.formVersion}',
    ),
    commerce: commerce,
    fieldId: 'item-effect-${commerce.item!.id}-${context.name}-$field',
    label: label,
    value: value,
    minimum: field.startsWith('friendship') ? 0 : 1,
    maximum: field == 'stages'
        ? 6
        : field == 'maximumTotal'
        ? 1530
        : field == 'maximumPerStat'
        ? 252
        : 255,
    optional: false,
    onChanged: (next) =>
        _set(context, PokemonItemEffectEditing.setInteger(use, field, next)),
  );

  String _statLabel(String stat) => switch (stat) {
    'hp' => 'PV',
    'attack' => 'Attaque',
    'defense' => 'Défense',
    'specialAttack' => 'Attaque Spéciale',
    'specialDefense' => 'Défense Spéciale',
    'speed' => 'Vitesse',
    'accuracy' => 'Précision',
    _ => stat,
  };
}
