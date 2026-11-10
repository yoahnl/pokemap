part of 'pokemon_combat_table_detail.dart';

Widget _buildCombatTableVariants(
  BuildContext context,
  PokemonCombatController combat,
  PokemonWorkspaceIndex index,
  ProjectEncounterTable table,
  Map<String, String> species,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Text(
      'Variantes de rencontres',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    const SizedBox(height: 6),
    const Text(
      'Une variante remplace la liste par défaut quand toutes ses conditions correspondent et que son horaire est actif. La priorité la plus élevée gagne. Deux variantes actives de même priorité empêchent la rencontre.',
    ),
    const SizedBox(height: 12),
    for (final variant in table.variants) ...[
      _buildCombatTableVariant(context, combat, index, table, variant, species),
      const SizedBox(height: 16),
    ],
    Align(
      alignment: Alignment.centerLeft,
      child: StudioButton(
        key: ValueKey('${table.id}:add-variant'),
        label: 'Ajouter une variante',
        secondary: true,
        icon: Icons.add,
        onPressed: combat.addEncounterVariant,
      ),
    ),
  ],
);

void _changeCombatVariant(
  PokemonCombatController combat,
  String id,
  ProjectEncounterVariant Function(ProjectEncounterVariant) change,
) => combat.editEncounterVariant(id, change);

Widget _buildCombatTableVariant(
  BuildContext context,
  PokemonCombatController combat,
  PokemonWorkspaceIndex index,
  ProjectEncounterTable table,
  ProjectEncounterVariant variant,
  Map<String, String> species,
) {
  final prefix = '${table.id}:variant:${variant.id}';
  final priorityKey = 'variant:${variant.id}:priority';
  void change(ProjectEncounterVariant Function(ProjectEncounterVariant) edit) =>
      _changeCombatVariant(combat, variant.id, edit);
  return StudioPanel(
    key: ValueKey(prefix),
    title: variant.name,
    children: [
      StudioDraftField(
        key: ValueKey('$prefix:name'),
        label: 'Nom de la variante',
        value: variant.name,
        onChanged: (value) =>
            change((current) => current.copyWith(name: value)),
      ),
      const SizedBox(height: 12),
      StudioDraftField(
        key: ValueKey('$prefix:priority'),
        label: 'Priorité',
        helperText: 'Un nombre plus élevé passe avant les autres variantes.',
        value: combat.numericValue(priorityKey, variant.priority),
        errorText: combat.fieldErrors[priorityKey],
        onChanged: (raw) => combat.editNumber(
          priorityKey,
          raw,
          (value) => change((current) => current.copyWith(priority: value)),
        ),
      ),
      const SizedBox(height: 18),
      _buildCombatVariantConditions(combat, variant, prefix),
      const SizedBox(height: 18),
      Text(
        'Espèces et poids relatifs',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < variant.entries.length; i++) ...[
        _buildCombatTableEntry(
          combat,
          context,
          table,
          i,
          species,
          false,
          variantId: variant.id,
        ),
        const SizedBox(height: 12),
      ],
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          StudioButton(
            key: ValueKey('$prefix:add-species'),
            label: 'Ajouter une espèce',
            secondary: true,
            icon: Icons.add,
            onPressed: species.isEmpty
                ? null
                : () async {
                    final chosen = await chooseCombatSpecies(context, index);
                    if (chosen == null) return;
                    combat.addEncounterSpecies(chosen, variantId: variant.id);
                  },
          ),
          StudioButton(
            key: ValueKey('$prefix:remove'),
            label: 'Retirer la variante',
            secondary: true,
            icon: Icons.delete_outline,
            onPressed: () => combat.removeEncounterVariant(variant.id),
          ),
        ],
      ),
    ],
  );
}

void _remapCombatVariantInputs(
  PokemonCombatController combat,
  String prefix,
  int removedIndex,
) => combat.remapVariantInputs(prefix, removedIndex);
