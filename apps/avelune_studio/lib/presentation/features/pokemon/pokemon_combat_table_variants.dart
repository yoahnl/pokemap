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
        onPressed: () => combat.editTable((current) {
          final used = current.variants.map((value) => value.id).toSet();
          var suffix = 1;
          while (used.contains('variant_$suffix')) {
            suffix++;
          }
          return current.copyWith(
            variants: [
              ...current.variants,
              ProjectEncounterVariant(
                id: 'variant_$suffix',
                name: 'Variante $suffix',
              ),
            ],
          );
        }),
      ),
    ),
  ],
);

void _changeCombatVariant(
  PokemonCombatController combat,
  String id,
  ProjectEncounterVariant Function(ProjectEncounterVariant) change,
) => combat.editTable(
  (table) => table.copyWith(
    variants: [
      for (final variant in table.variants)
        if (variant.id == id) change(variant) else variant,
    ],
  ),
);

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
      _buildCombatVariantTimeWindows(combat, variant, prefix),
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
                    _changeCombatTableEntries(
                      combat,
                      variant.id,
                      (entries) => [
                        ...entries,
                        ProjectEncounterEntry(
                          speciesId: chosen,
                          minLevel: 5,
                          maxLevel: 5,
                        ),
                      ],
                    );
                  },
          ),
          StudioButton(
            key: ValueKey('$prefix:remove'),
            label: 'Retirer la variante',
            secondary: true,
            icon: Icons.delete_outline,
            onPressed: () {
              for (final values in [combat.numericInputs, combat.fieldErrors]) {
                values.removeWhere(
                  (key, _) => key.startsWith('variant:${variant.id}:'),
                );
              }
              combat.editTable(
                (current) => current.copyWith(
                  variants: [
                    for (final value in current.variants)
                      if (value.id != variant.id) value,
                  ],
                ),
              );
            },
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
) {
  final pattern = RegExp('^${RegExp.escape(prefix)}([0-9]+):');
  for (final values in [combat.numericInputs, combat.fieldErrors]) {
    final remapped = <String, String>{};
    for (final entry in values.entries) {
      final match = pattern.firstMatch(entry.key);
      final owner = match == null ? null : int.parse(match.group(1)!);
      if (owner == removedIndex) continue;
      final key = owner != null && owner > removedIndex
          ? '$prefix${owner - 1}:${entry.key.substring(match!.end)}'
          : entry.key;
      remapped[key] = entry.value;
    }
    values
      ..clear()
      ..addAll(remapped);
  }
}
