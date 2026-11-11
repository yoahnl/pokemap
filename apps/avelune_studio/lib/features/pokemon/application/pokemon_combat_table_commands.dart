part of 'pokemon_combat_controller.dart';

List<ProjectEncounterEntry> encounterTableEntries(
  ProjectEncounterTable table,
  String? variantId,
) => variantId == null
    ? table.entries
    : table.variants.singleWhere((variant) => variant.id == variantId).entries;

Map<String, String> trainerBallChoices(ProjectItemCatalog? catalog) {
  final counts = <String, int>{};
  for (final item in catalog?.entries ?? const <ProjectItemDefinition>[]) {
    counts[item.id] = (counts[item.id] ?? 0) + 1;
  }
  return {
    '': 'Aucune Ball',
    for (final item in catalog?.entries ?? const <ProjectItemDefinition>[])
      if (item.capture != null && counts[item.id] == 1)
        item.id: item.displayName,
  };
}

extension PokemonCombatTableCommands on PokemonCombatController {
  void addVariantTimeWindow(String id) => editEncounterVariant(
    id,
    (variant) => variant.copyWith(
      timeWindows: [
        ...variant.timeWindows,
        const LocalTimeWindow(startMinute: 480, endMinute: 1200),
      ],
    ),
  );

  void replaceVariantTimeWindow(String id, int index, LocalTimeWindow window) =>
      editEncounterVariant(
        id,
        (variant) => variant.copyWith(
          timeWindows: [
            for (var i = 0; i < variant.timeWindows.length; i++)
              if (i == index) window else variant.timeWindows[i],
          ],
        ),
      );

  void removeVariantTimeWindow(String id, int index) => editEncounterVariant(
    id,
    (variant) => variant.copyWith(
      timeWindows: [
        for (var i = 0; i < variant.timeWindows.length; i++)
          if (i != index) variant.timeWindows[i],
      ],
    ),
  );

  void addVariantCondition(String id, NarrativeFactDefinition fact) =>
      editEncounterVariant(
        id,
        (variant) => variant.copyWith(
          conditions: [
            ...variant.conditions,
            ScriptConditionFactory.factEquals(fact.id, fact.initialValue),
          ],
        ),
      );

  void selectVariantFact(
    String id,
    int position,
    NarrativeFactDefinition fact,
  ) {
    if (_disposed || saving) return;
    final key = 'variant:$id:condition:$position:value';
    numericInputs.remove(key);
    fieldErrors.remove(key);
    editEncounterVariant(
      id,
      (variant) => variant.copyWith(
        conditions: [
          for (var i = 0; i < variant.conditions.length; i++)
            if (i == position)
              ScriptConditionFactory.factEquals(fact.id, fact.initialValue)
            else
              variant.conditions[i],
        ],
      ),
    );
  }

  void addEncounterVariant() => editTable((current) {
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
  });

  void editEncounterVariant(
    String id,
    ProjectEncounterVariant Function(ProjectEncounterVariant) change,
  ) => editTable(
    (table) => table.copyWith(
      variants: [
        for (final variant in table.variants)
          if (variant.id == id) change(variant) else variant,
      ],
    ),
  );

  void removeEncounterVariant(String id) {
    if (_disposed || saving || table == null) return;
    for (final values in [numericInputs, fieldErrors]) {
      values.removeWhere((key, _) => key.startsWith('variant:$id:'));
    }
    editTable(
      (current) => current.copyWith(
        variants: [
          for (final variant in current.variants)
            if (variant.id != id) variant,
        ],
      ),
    );
  }

  void editEncounterEntries(
    String? variantId,
    List<ProjectEncounterEntry> Function(List<ProjectEncounterEntry>) change,
  ) => editTable(
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

  void addEncounterSpecies(String id, {String? variantId}) =>
      editEncounterEntries(
        variantId,
        (entries) => [
          ...entries,
          ProjectEncounterEntry(speciesId: id, minLevel: 5, maxLevel: 5),
        ],
      );

  void addTrainerSpecies(String id) => editTrainer(
    (current) => current.copyWith(
      team: [
        ...current.team,
        ProjectTrainerPokemonEntry(speciesId: id, level: 5),
      ],
    ),
  );

  void replaceTrainerMember(int index, ProjectTrainerPokemonEntry value) {
    final team = trainer?.current.team;
    if (team != null &&
        index >= 0 &&
        index < team.length &&
        pokemonTrainerMoveCountRefused(
          team[index].moves.length,
          value.moves.length,
        )) {
      if (_disposed || saving) return;
      error = pokemonTrainerMoveLimitRefusal;
      changed();
      return;
    }
    if (error == pokemonTrainerMoveLimitRefusal) error = null;
    editTrainer(
      (current) => current.copyWith(
        team: [
          for (var i = 0; i < current.team.length; i++)
            if (i == index) value else current.team[i],
        ],
      ),
    );
  }

  void remapVariantInputs(String prefix, int removedIndex) {
    if (_disposed || saving) return;
    final pattern = RegExp('^${RegExp.escape(prefix)}([0-9]+):');
    for (final values in [numericInputs, fieldErrors]) {
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
}
