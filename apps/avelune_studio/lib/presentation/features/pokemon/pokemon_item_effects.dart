import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'pokemon_commerce_integer_field.dart';
import 'pokemon_ui_parts.dart';

class PokemonItemEffects extends StatelessWidget {
  const PokemonItemEffects({super.key, required this.commerce});

  final PokemonCommerceController commerce;

  ProjectItemUseDefinition? _use(ProjectItemUseContext context) {
    for (final value in commerce.item!.uses) {
      if (value.contexts.contains(context)) return value;
    }
    return null;
  }

  void _set(
    ProjectItemUseContext context,
    ProjectItemUseDefinition? replacement,
  ) {
    commerce.setFieldError(
      'item-effect-${commerce.item!.id}-${context.name}',
      null,
    );
    commerce.editItem(
      (item) => item.copyWith(
        uses: [
          for (final value in item.uses)
            if (!value.contexts.contains(context))
              value
            else if (value.contexts.length > 1)
              value.copyWith(contexts: {...value.contexts}..remove(context)),
          if (replacement != null) replacement.copyWith(contexts: {context}),
        ],
      ),
    );
  }

  ProjectItemUseDefinition _defaultUse(ProjectItemUseContext context) =>
      ProjectItemUseDefinition(
        contexts: {context},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );

  ProjectItemEffectDefinition _effect(String kind) => switch (kind) {
    'cure' => const ProjectItemEffectDefinition.cureStatus(
      mode: ProjectItemStatusCureMode.all,
    ),
    'revive' => const ProjectItemEffectDefinition.revive(
      rateNumerator: 1,
      rateDenominator: 2,
    ),
    'pp' => const ProjectItemEffectDefinition.restorePp(
      mode: ProjectItemAmountMode.flat,
      amount: 10,
    ),
    _ => const ProjectItemEffectDefinition.healHp(
      mode: ProjectItemAmountMode.flat,
      amount: 20,
    ),
  };

  String _kind(ProjectItemEffectDefinition effect) => switch (effect) {
    ProjectItemHealHpEffectDefinition() => 'heal',
    ProjectItemCureStatusEffectDefinition() => 'cure',
    ProjectItemReviveEffectDefinition() => 'revive',
    ProjectItemRestorePpEffectDefinition() => 'pp',
    _ => 'imported',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PokemonSectionHeading(
        title: 'Effets structurés',
        description:
            'Les actions ci-dessous utilisent les capacités reconnues par le runtime.',
      ),
      _card(ProjectItemUseContext.overworld, 'Hors combat'),
      const SizedBox(height: 12),
      _card(ProjectItemUseContext.battle, 'En combat'),
      const SizedBox(height: 12),
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
              'Les capacités importées sont conservées. Leur édition spécialisée n’est pas disponible dans cette fiche.',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _card(ProjectItemUseContext context, String title) {
    final use = _use(context);
    final kind = use == null ? null : _kind(use.effect);
    final supported =
        kind != 'imported' &&
        (context != ProjectItemUseContext.battle || kind != 'pp');
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
                    onPressed: () => _set(context, _defaultUse(context)),
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
                  'cure': 'Guérir les statuts',
                  'revive': 'Réanimer',
                  if (context == ProjectItemUseContext.overworld)
                    'pp': 'Restaurer les PP',
                },
                onChanged: (value) => _set(
                  context,
                  use.copyWith(
                    effect: _effect(value),
                    target: value == 'pp'
                        ? ProjectItemTargetKind.partyMove
                        : ProjectItemTargetKind.partyMember,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                    use.copyWith(
                      effect: kind == 'pp'
                          ? ProjectItemEffectDefinition.restorePp(
                              mode: value
                                  ? ProjectItemAmountMode.full
                                  : ProjectItemAmountMode.flat,
                              amount: value ? null : 10,
                            )
                          : ProjectItemEffectDefinition.healHp(
                              mode: value
                                  ? ProjectItemAmountMode.full
                                  : ProjectItemAmountMode.flat,
                              amount: value ? null : 20,
                            ),
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
                        use.copyWith(
                          effect: kind == 'pp'
                              ? ProjectItemEffectDefinition.restorePp(
                                  mode: ProjectItemAmountMode.flat,
                                  amount: value!,
                                )
                              : ProjectItemEffectDefinition.healHp(
                                  mode: ProjectItemAmountMode.flat,
                                  amount: value!,
                                ),
                        ),
                      );
                    },
                  ),
              ],
              StudioToggleRow(
                label: 'Consommer après application',
                value:
                    use.consumption == ProjectItemConsumptionPolicy.onApplied,
                onChanged: (value) => _set(
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
}
