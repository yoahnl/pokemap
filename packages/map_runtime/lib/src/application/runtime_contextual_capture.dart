import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_pokemon_species_loader.dart';

final class RuntimeCaptureProvenance {
  RuntimeCaptureProvenance({
    required Map<String, RuntimePokemonSpecies> speciesById,
    required Map<int, String?> playerSexesByLineupIndex,
    required this.targetSex,
    required this.encounterKind,
    Map<String, Set<String>>? targetEvolutionItemIdsBySpecies,
  }) : speciesById = Map.unmodifiable(speciesById),
       playerSexesByLineupIndex = Map.unmodifiable(playerSexesByLineupIndex),
       targetEvolutionItemIdsBySpecies = targetEvolutionItemIdsBySpecies == null
           ? null
           : Map.unmodifiable(
               targetEvolutionItemIdsBySpecies.map(
                 (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
               ),
             );

  final Map<String, RuntimePokemonSpecies> speciesById;
  final Map<int, String?> playerSexesByLineupIndex;
  final String? targetSex;
  final EncounterKind encounterKind;
  final Map<String, Set<String>>? targetEvolutionItemIdsBySpecies;
}

final class RuntimePreparedBattleCapture {
  const RuntimePreparedBattleCapture._(this.choice);

  final PlayerBattleChoiceCapture choice;
}

RuntimePreparedBattleCapture prepareRuntimeBattleCapture({
  required PlayerBattleChoiceCapture choice,
  required BattleState battleState,
  required PokemonRulesetProfile ruleset,
  RuntimeCaptureProvenance? provenance,
  ProjectCaptureItemDefinition? canonicalCapture,
  bool allowDemonstrationRateOverride = false,
}) {
  if (canonicalCapture != null &&
      ((choice.contextualPolicy != null && choice.contextualPolicy != canonicalCapture.contextualPolicy) ||
       choice.captureContext != null)) {
    throw StateError('Capture selection does not match the canonical item definition.');
  }
  if (canonicalCapture != null && !allowDemonstrationRateOverride &&
      (choice.rateNumerator != canonicalCapture.rateNumerator ||
       choice.rateDenominator != canonicalCapture.rateDenominator)) {
    throw StateError('Capture rate does not match the canonical item definition.');
  }
  final policy = canonicalCapture?.contextualPolicy ?? choice.contextualPolicy;
  final target = battleState.enemy;
  var prepared = choice;
  if (policy != null) {
    if (ruleset.profileId != PokemonRulesetProfile.contextualProfileId) {
      throw StateError('Contextual capture requires the explicit contextual ruleset.');
    }
    final species = provenance?.speciesById[target.speciesId];
    if (provenance == null || species == null || !species.isBaseForm) {
      throw StateError(
        'Current species capture metadata is unavailable or ambiguous.',
      );
    }
    int? weightDecikilograms;
    try {
      weightDecikilograms = runtimeCaptureWeightDecikilograms(species.weightKg);
    } on StateError {
      weightDecikilograms = null;
    }
    final attacker = battleState.player;
    prepared = PlayerBattleChoiceCapture(
      itemId: choice.itemId,
      rateNumerator: choice.rateNumerator,
      rateDenominator: choice.rateDenominator,
      contextualPolicy: policy,
      captureContext: BattleCaptureContext(
        attackerLevel: attacker.level,
        targetLevel: target.level,
        targetBaseSpeed: species.baseSpeed,
        targetBaseCatchRate: species.catchRate,
        targetWeightDecikilograms: weightDecikilograms,
        attackerSpecies: attacker.speciesId,
        targetSpecies: target.speciesId,
        attackerSex: _sex(
          provenance.playerSexesByLineupIndex[attacker.lineupIndex],
        ),
        targetSex: _sex(provenance.targetSex),
        targetTypes: target.typing == null
            ? null
            : {
                target.typing!.primaryType,
                ?target.typing!.secondaryType,
              },
        targetEvolutionItemIds:
            provenance.targetEvolutionItemIdsBySpecies?[target.speciesId],
        encounterOrigin: switch (provenance.encounterKind) {
          EncounterKind.oldRod ||
          EncounterKind.goodRod ||
          EncounterKind.superRod => ProjectCaptureEncounterOrigin.fishing,
          EncounterKind.walk => ProjectCaptureEncounterOrigin.walking,
          EncounterKind.surf => ProjectCaptureEncounterOrigin.surfing,
          EncounterKind.headbutt => ProjectCaptureEncounterOrigin.headbutt,
          EncounterKind.gift => ProjectCaptureEncounterOrigin.gift,
          EncounterKind.special => ProjectCaptureEncounterOrigin.scripted,
        },
      ),
    );
  }
  PokemonBattleRules.fromProfile(ruleset).validateCaptureSelection(
    targetCurrentHp: target.currentHp,
    targetMaxHp: target.maxHp,
    catchRate: target.catchRate ?? 0,
    ballId: prepared.itemId,
    ballRateNumerator: prepared.rateNumerator,
    ballRateDenominator: prepared.rateDenominator,
    contextualPolicy: prepared.contextualPolicy,
    captureContext: prepared.captureContext,
  );
  return RuntimePreparedBattleCapture._(prepared);
}

int? runtimeCaptureWeightDecikilograms(double? weightKg) {
  if (weightKg == null) return null;
  if (!weightKg.isFinite || weightKg < 0) {
    throw StateError('Capture weight must be finite and nonnegative.');
  }
  final match = RegExp(r'^(\d+)(?:\.(\d+))?(?:e([+-]?\d+))?$')
      .firstMatch(weightKg.toString());
  if (match == null) throw StateError('Invalid capture weight.');
  final fraction = match[2] ?? '';
  final digits = BigInt.parse('${match[1]}$fraction');
  final scale = fraction.length - int.parse(match[3] ?? '0') - 1;
  final denominator = BigInt.from(10).pow(scale > 0 ? scale : 0);
  final numerator = digits * BigInt.from(10).pow(scale < 0 ? -scale : 0);
  final result = numerator ~/ denominator;
  if (numerator.remainder(denominator) != BigInt.zero ||
      result > BigInt.from(0x7fffffff)) {
    throw StateError('Capture weight must have exact decikilogram precision.');
  }
  return result.toInt();
}

BattleCaptureSex? _sex(String? value) => switch (value) {
  'male' => BattleCaptureSex.male,
  'female' => BattleCaptureSex.female,
  'genderless' => BattleCaptureSex.genderless,
  _ => null,
};
