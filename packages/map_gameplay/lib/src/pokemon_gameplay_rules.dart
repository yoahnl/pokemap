import 'package:map_core/map_core.dart';

final class PokemonGameplayFeatureDisabledError extends StateError {
  PokemonGameplayFeatureDisabledError({
    required this.reference,
    required this.feature,
  }) : super(
          'Pokemon feature ${feature.name} is disabled by ruleset '
          '${reference.profileId}@${reference.schemaVersion}.',
        );

  final PokemonRulesetReference reference;
  final PokemonDisabledFeature feature;
}

final class PokemonGameplayRules {
  PokemonGameplayRules._(this.profile, this.mechanics);

  factory PokemonGameplayRules.fromProfile(PokemonRulesetProfile profile) {
    return PokemonGameplayRules._(profile, profile.mechanics);
  }

  final PokemonRulesetProfile profile;
  final PokemonRulesetMechanics mechanics;

  PokemonRulesetReference get reference => mechanics.reference;
  int get maxLevel => mechanics.maxLevel;

  int experienceForDefeatedPokemon({
    required int level,
    required int baseExperience,
    required bool trainerBattle,
  }) {
    if (mechanics.experience != PokemonExperiencePolicy.pokeMapSimpleV1) {
      throw StateError(
        'Unsupported Pokemon experience policy ${mechanics.experience.name}.',
      );
    }
    RangeError.checkValueInInterval(level, 1, maxLevel, 'level');
    RangeError.checkValueInInterval(
      baseExperience,
      1,
      10000,
      'baseExperience',
    );
    return trainerBattle
        ? (level * baseExperience * 3) ~/ 14
        : (level * baseExperience) ~/ 7;
  }

  int validatedFriendship(int friendship) {
    if (mechanics.friendship != PokemonFriendshipPolicy.mainline0255V1) {
      throw StateError(
        'Unsupported Pokemon friendship policy ${mechanics.friendship.name}.',
      );
    }
    RangeError.checkValueInInterval(friendship, 0, 255, 'friendship');
    return friendship;
  }

  void requireMoveMachineSupported() {
    if (mechanics.moveMachine !=
        PokemonMoveMachinePolicy.authoredConsumabilityV1) {
      throw StateError(
        'Unsupported Pokemon move machine policy ${mechanics.moveMachine.name}.',
      );
    }
  }

  void requireEvolutionSupported() {
    if (mechanics.evolution != PokemonEvolutionPolicy.pokeMapBetaV1) {
      throw StateError(
        'Unsupported Pokemon evolution policy ${mechanics.evolution.name}.',
      );
    }
  }

  void requireFeatureEnabled(PokemonDisabledFeature feature) {
    if (mechanics.disabledFeatures.contains(feature)) {
      throw PokemonGameplayFeatureDisabledError(
        reference: reference,
        feature: feature,
      );
    }
  }
}
