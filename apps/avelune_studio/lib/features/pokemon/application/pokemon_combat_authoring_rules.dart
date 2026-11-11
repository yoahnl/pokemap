import 'package:map_core/map_core_domain.dart';

import 'pokemon_combat_controller.dart';

export 'pokemon_document_editing.dart' show pokemonOptionalChoice;

const pokemonTrainerMoveLimit = 4;

bool pokemonTrainerCanAddMove(ProjectTrainerPokemonEntry member) =>
    member.moves.length < pokemonTrainerMoveLimit;

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
