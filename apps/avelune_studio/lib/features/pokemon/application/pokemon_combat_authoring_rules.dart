import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_combat_port.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_combat_controller.dart';
import 'pokemon_combat_references.dart';

export 'pokemon_document_editing.dart' show pokemonOptionalChoice;
export 'pokemon_trainer_move_limit.dart';

bool pokemonEncounterIsUnique(ProjectEncounterTable table) =>
    table.tags.contains('studio:unique');

bool pokemonEncounterOffersSpeciesAddition(ProjectEncounterTable table) =>
    !pokemonEncounterIsUnique(table) || table.entries.isEmpty;

Map<String, String> pokemonEnabledSpeciesNames(PokemonWorkspaceIndex index) => {
  for (final entry in index.entries)
    if (entry.enabled) entry.id: entry.name,
};

PokemonRulesetProfile pokemonRulesetProfile(String profileId) =>
    profileId == PokemonRulesetProfile.standardProfileId
    ? PokemonRulesetProfile.standardV1
    : PokemonRulesetProfile.pokeMapBetaV1;

int pokemonEncounterChancePercent(ProjectEncounterTable table) =>
    (table.chancePerStep * 100).round();

ProjectEncounterEntry pokemonEncounterEntryWithMinLevel(
  ProjectEncounterEntry entry,
  int level, {
  required bool unique,
}) =>
    entry.copyWith(minLevel: level, maxLevel: unique ? level : entry.maxLevel);

extension PokemonCombatAuthoringCommands on PokemonCombatController {
  bool get canAnalyzeReferences =>
      !operationActive && !dirty && port is PokemonCombatReferencePort;

  bool get canChangeRuleset => !operationActive && !dirty;

  bool get canRequestDeletion =>
      !dirty &&
      snapshot?.referencesComplete == true &&
      (table != null || trainer != null);

  List<String> get selectedReferences {
    final current = snapshot;
    if (current == null) return const [];
    final selectedTable = table;
    if (selectedTable != null) {
      return combatTableReferences(current, selectedTable.current);
    }
    final selectedTrainer = trainer;
    return selectedTrainer == null
        ? const []
        : combatTrainerReferences(current, selectedTrainer.current);
  }

  bool createForView(String name) => view == PokemonCombatView.trainers
      ? createTrainer(name)
      : createTable(name, unique: view == PokemonCombatView.unique);

  void editEncounterChancePercent(String raw) => editNumber(
    'chance',
    raw,
    (value) =>
        editTable((current) => current.copyWith(chancePerStep: value / 100)),
  );

  void editVariantConditionValue(
    String variantId,
    int position,
    NarrativeFactDefinition fact,
    String raw,
  ) {
    void apply(NarrativeValue value) => editEncounterVariant(
      variantId,
      (variant) => variant.copyWith(
        conditions: [
          for (var i = 0; i < variant.conditions.length; i++)
            if (i == position)
              ScriptConditionFactory.factEquals(fact.id, value)
            else
              variant.conditions[i],
        ],
      ),
    );
    switch (fact.valueKind) {
      case NarrativeValueKind.boolean:
        apply(NarrativeValue.boolean(raw == 'true'));
      case NarrativeValueKind.integer:
        editNumber(
          'variant:$variantId:condition:$position:value',
          raw,
          (value) => apply(NarrativeValue.integer(value)),
        );
      case NarrativeValueKind.string:
        apply(NarrativeValue.string(raw));
    }
  }
}
