part of 'pokemon_combat_table_detail.dart';

Widget _buildCombatTableEntry(
  PokemonCombatController combat,
  BuildContext context,
  ProjectEncounterTable table,
  int indexInTable,
  Map<String, String> species,
  bool unique,
) {
  final entry = table.entries[indexInTable];
  void change(ProjectEncounterEntry value) => combat.editTable(
    (current) => current.copyWith(
      entries: [
        for (var i = 0; i < current.entries.length; i++)
          if (i == indexInTable) value else current.entries[i],
      ],
    ),
  );
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
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
                  key: ValueKey('${table.id}:$indexInTable:min'),
                  label: unique ? 'Niveau' : 'Niveau min.',
                  value: combat.numericValue(
                    'entry$indexInTable:min',
                    entry.minLevel,
                  ),
                  onChanged: (raw) => combat.editNumber(
                    'entry$indexInTable:min',
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
                    key: ValueKey('${table.id}:$indexInTable:max'),
                    label: 'Niveau max.',
                    value: combat.numericValue(
                      'entry$indexInTable:max',
                      entry.maxLevel,
                    ),
                    onChanged: (raw) => combat.editNumber(
                      'entry$indexInTable:max',
                      raw,
                      (value) => change(entry.copyWith(maxLevel: value)),
                    ),
                  ),
                ),
              if (!unique)
                SizedBox(
                  width: 145,
                  child: StudioDraftField(
                    key: ValueKey('${table.id}:$indexInTable:weight'),
                    label: 'Poids relatif',
                    value: combat.numericValue(
                      'entry$indexInTable:weight',
                      entry.weight,
                    ),
                    onChanged: (raw) => combat.editNumber(
                      'entry$indexInTable:weight',
                      raw,
                      (value) => change(entry.copyWith(weight: value)),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Retirer cette espèce',
                onPressed: () => combat.editTable(
                  (current) => current.copyWith(
                    entries: [
                      for (var i = 0; i < current.entries.length; i++)
                        if (i != indexInTable) current.entries[i],
                    ],
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
