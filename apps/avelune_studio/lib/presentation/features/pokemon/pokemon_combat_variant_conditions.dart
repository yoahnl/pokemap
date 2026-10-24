part of 'pokemon_combat_table_detail.dart';

Widget _buildCombatVariantConditions(
  PokemonCombatController combat,
  ProjectEncounterVariant variant,
  String prefix,
) {
  final facts = combat.snapshot!.project.facts;
  void change(List<ScriptCondition> Function(List<ScriptCondition>) edit) =>
      _changeCombatVariant(
        combat,
        variant.id,
        (current) => current.copyWith(conditions: edit(current.conditions)),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Conditions sur les états du monde'),
      const SizedBox(height: 6),
      if (variant.conditions.isEmpty)
        const Text('Aucune condition : tous les états du monde conviennent.'),
      for (var i = 0; i < variant.conditions.length; i++) ...[
        _buildCombatVariantCondition(
          combat,
          variant,
          prefix,
          i,
          facts,
          (value) => change(
            (current) => [
              for (var j = 0; j < current.length; j++)
                if (j == i) value else current[j],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: ValueKey('$prefix:condition:$i:remove'),
            label: 'Retirer la condition',
            secondary: true,
            onPressed: () {
              _remapCombatVariantInputs(
                combat,
                'variant:${variant.id}:condition:',
                i,
              );
              change(
                (current) => [
                  for (var j = 0; j < current.length; j++)
                    if (j != i) current[j],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (facts.isEmpty)
        const Text(
          'Créez un état du monde dans Histoire pour définir une condition.',
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: StudioButton(
          key: ValueKey('$prefix:add-condition'),
          label: 'Ajouter une condition',
          secondary: true,
          icon: Icons.add,
          onPressed: facts.isEmpty
              ? null
              : () => change(
                  (current) => [
                    ...current,
                    ScriptConditionFactory.factEquals(
                      facts.first.id,
                      facts.first.initialValue,
                    ),
                  ],
                ),
        ),
      ),
    ],
  );
}

Widget _buildCombatVariantCondition(
  PokemonCombatController combat,
  ProjectEncounterVariant variant,
  String prefix,
  int position,
  List<NarrativeFactDefinition> facts,
  ValueChanged<ScriptCondition> change,
) {
  final condition = variant.conditions[position];
  if (condition.type != ScriptConditionType.factEquals) {
    return const Text(
      'Condition existante conservée. Vous pouvez la retirer pour choisir un état du monde.',
    );
  }
  final id = condition.params[ScriptConditionParams.factId];
  final fact = facts.where((value) => value.id == id).firstOrNull;
  final value = condition.params[ScriptConditionParams.value];
  final key = '$prefix:condition:$position';
  final numericKey = 'variant:${variant.id}:condition:$position:value';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        key: ValueKey('$key:fact'),
        label: 'État du monde',
        value: id,
        options: {for (final fact in facts) fact.id: fact.label},
        onChanged: (id) {
          combat.numericInputs.remove(numericKey);
          combat.fieldErrors.remove(numericKey);
          final selected = facts.singleWhere((fact) => fact.id == id);
          change(ScriptConditionFactory.factEquals(id, selected.initialValue));
        },
      ),
      const SizedBox(height: 10),
      if (fact?.valueKind == NarrativeValueKind.boolean)
        StudioSelect(
          key: ValueKey('$key:value'),
          label: 'Valeur attendue',
          value: '$value',
          options: const {'true': 'Activé', 'false': 'Désactivé'},
          onChanged: (raw) => change(
            ScriptConditionFactory.factEquals(
              id!,
              NarrativeValue.boolean(raw == 'true'),
            ),
          ),
        )
      else if (fact != null)
        StudioDraftField(
          key: ValueKey('$key:value'),
          label: 'Valeur attendue',
          value: fact.valueKind == NarrativeValueKind.integer
              ? combat.numericInputs[numericKey] ?? '$value'
              : '$value',
          errorText: combat.fieldErrors[numericKey],
          onChanged: (raw) {
            if (fact.valueKind == NarrativeValueKind.integer) {
              combat.editNumber(
                numericKey,
                raw,
                (value) => change(
                  ScriptConditionFactory.factEquals(
                    id!,
                    NarrativeValue.integer(value),
                  ),
                ),
              );
            } else {
              change(
                ScriptConditionFactory.factEquals(
                  id!,
                  NarrativeValue.string(raw),
                ),
              );
            }
          },
        )
      else
        const Text(
          'Cet état du monde est introuvable. Choisissez une référence disponible.',
        ),
    ],
  );
}
