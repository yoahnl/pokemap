part of 'pokemon_combat_table_detail.dart';

Widget _buildCombatTableEntry(
  PokemonCombatController combat,
  BuildContext context,
  ProjectEncounterTable table,
  int indexInTable,
  Map<String, String> species,
  bool unique, {
  String? variantId,
}) {
  final entries = _combatTableEntries(table, variantId);
  final entry = entries[indexInTable];
  final prefix = variantId == null
      ? table.id
      : '${table.id}:variant:$variantId';
  final numericPrefix = variantId == null ? '' : 'variant:$variantId:';
  void change(ProjectEncounterEntry value) => _changeCombatTableEntries(
    combat,
    variantId,
    (current) => [
      for (var i = 0; i < current.length; i++)
        if (i == indexInTable) value else current[i],
    ],
  );
  return StudioPanel(
    compact: true,
    children: [
      StudioSelect(
        label: 'Espèce',
        value: entry.speciesId,
        options: species,
        onChanged: (id) => change(entry.copyWith(speciesId: id)),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 145,
            child: StudioDraftField(
              key: ValueKey('$prefix:$indexInTable:min'),
              label: unique ? 'Niveau' : 'Niveau min.',
              value: combat.numericValue(
                '${numericPrefix}entry$indexInTable:min',
                entry.minLevel,
              ),
              onChanged: (raw) => combat.editNumber(
                '${numericPrefix}entry$indexInTable:min',
                raw,
                (value) => change(
                  entry.copyWith(
                    minLevel: value,
                    maxLevel: unique ? value : entry.maxLevel,
                  ),
                ),
              ),
            ),
          ),
          if (!unique)
            SizedBox(
              width: 145,
              child: StudioDraftField(
                key: ValueKey('$prefix:$indexInTable:max'),
                label: 'Niveau max.',
                value: combat.numericValue(
                  '${numericPrefix}entry$indexInTable:max',
                  entry.maxLevel,
                ),
                onChanged: (raw) => combat.editNumber(
                  '${numericPrefix}entry$indexInTable:max',
                  raw,
                  (value) => change(entry.copyWith(maxLevel: value)),
                ),
              ),
            ),
          if (!unique)
            SizedBox(
              width: 145,
              child: StudioDraftField(
                key: ValueKey('$prefix:$indexInTable:weight'),
                label: 'Poids relatif',
                value: combat.numericValue(
                  '${numericPrefix}entry$indexInTable:weight',
                  entry.weight,
                ),
                onChanged: (raw) => combat.editNumber(
                  '${numericPrefix}entry$indexInTable:weight',
                  raw,
                  (value) => change(entry.copyWith(weight: value)),
                ),
              ),
            ),
          StudioButton(
            label: 'Retirer cette espèce',
            secondary: true,
            onPressed: () {
              if (variantId != null) {
                _remapCombatVariantInputs(
                  combat,
                  'variant:$variantId:entry',
                  indexInTable,
                );
              }
              _changeCombatTableEntries(
                combat,
                variantId,
                (current) => [
                  for (var i = 0; i < current.length; i++)
                    if (i != indexInTable) current[i],
                ],
              );
            },
            icon: Icons.delete_outline,
          ),
        ],
      ),
    ],
  );
}

List<ProjectEncounterEntry> _combatTableEntries(
  ProjectEncounterTable table,
  String? variantId,
) => variantId == null
    ? table.entries
    : table.variants.singleWhere((variant) => variant.id == variantId).entries;

void _changeCombatTableEntries(
  PokemonCombatController combat,
  String? variantId,
  List<ProjectEncounterEntry> Function(List<ProjectEncounterEntry>) change,
) => combat.editTable(
  (table) => variantId == null
      ? table.copyWith(entries: change(table.entries))
      : table.copyWith(
          variants: [
            for (final variant in table.variants)
              if (variant.id == variantId)
                variant.copyWith(entries: change(variant.entries))
              else
                variant,
          ],
        ),
);
