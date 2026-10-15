import 'package:map_core/map_core.dart';
import 'pokemon_evolution_service.dart';
import 'pokemon_evolution_held_item_policy.dart';

enum PokemonPartyTradeFailure {
  invalidSelection,
  invalidCatalog,
  ambiguousEvolution
}

final class PokemonPartyTradeResult {
  const PokemonPartyTradeResult.success(this.state, {this.evolution})
      : failure = null;
  const PokemonPartyTradeResult.failed(this.state, this.failure)
      : evolution = null;
  final GameState state;
  final PokemonEvolutionResult? evolution;
  final PokemonPartyTradeFailure? failure;
  bool get isSuccess => failure == null;
}

final class PokemonPartyTradeOperations {
  const PokemonPartyTradeOperations(
      {this.evolutionService = const PokemonEvolutionService()});
  final PokemonEvolutionService evolutionService;
  PokemonPartyTradeResult trade(
    GameState state, {
    required PokemonRulesetProfile ruleset,
    required String firstIndividualId,
    required String partnerIndividualId,
    required List<PokemonEvolutionCandidate> candidates,
    required int sourceMaxHp,
    required PokemonEvolutionHeldItemPolicy heldItemPolicy,
  }) {
    PokemonPartyTradeResult failed(PokemonPartyTradeFailure failure) =>
        PokemonPartyTradeResult.failed(state, failure);
    final members = state.party.members;
    final ids = members.map((pokemon) => pokemon.individualId).toList();
    final firstIndex = ids.indexOf(firstIndividualId),
        partnerIndex = ids.indexOf(partnerIndividualId);
    if (firstIndividualId.isEmpty ||
        partnerIndividualId.isEmpty ||
        firstIndex < 0 ||
        partnerIndex < 0 ||
        ids.any((id) => id.isEmpty) ||
        ids.toSet().length != ids.length ||
        sourceMaxHp <= 0) {
      return failed(PokemonPartyTradeFailure.invalidSelection);
    }
    final first = members[firstIndex], partner = members[partnerIndex];
    if (!heldItemPolicy.recognizes(first.heldItemId)) {
      return failed(PokemonPartyTradeFailure.invalidCatalog);
    }
    final trigger =
        PokemonEvolutionTrigger.trade(partnerSpeciesId: partner.speciesId);
    final eligible = <PokemonEvolutionCandidate>[];
    try {
      trigger.validated();
      for (final candidate in candidates) {
        candidate.validated();
        if (candidate.sourceSpeciesId != first.speciesId ||
            candidate.condition.kind != PokemonEvolutionConditionKind.trade) {
          return failed(PokemonPartyTradeFailure.invalidCatalog);
        }
        if (candidate.isEligible(first, trigger: trigger)) {
          eligible.add(candidate);
        }
      }
    } on Object {
      return failed(PokemonPartyTradeFailure.invalidCatalog);
    }
    if (eligible.length > 1) {
      return failed(PokemonPartyTradeFailure.ambiguousEvolution);
    }
    PokemonEvolutionResult? evolution;
    if (eligible.isNotEmpty &&
        !heldItemPolicy.preventsEvolution(first.heldItemId)) {
      try {
        evolution = evolutionService.evolve(
            ruleset: ruleset,
            pokemon: first,
            candidate: eligible.single,
            sourceMaxHp: sourceMaxHp,
            trigger: trigger);
        if (eligible.single.condition.tradeRequirements!.requiredHeldItemId !=
            null) {
          evolution = PokemonEvolutionResult(
              pokemon: evolution.pokemon.copyWith(heldItemId: ''),
              previousMaxHp: evolution.previousMaxHp,
              calculatedStats: evolution.calculatedStats);
        }
      } on Object {
        return failed(PokemonPartyTradeFailure.invalidCatalog);
      }
    }
    final nextMembers = [...members];
    if (evolution != null) nextMembers[firstIndex] = evolution.pokemon;
    return PokemonPartyTradeResult.success(
        state.copyWith(
            party: PlayerParty(members: nextMembers),
            progression: state.progression.copyWith(caughtSpeciesIds: [
              ...state.progression.caughtSpeciesIds,
              first.speciesId,
              if (evolution != null) evolution.pokemon.speciesId,
            ]).normalized()),
        evolution: evolution);
  }
}
