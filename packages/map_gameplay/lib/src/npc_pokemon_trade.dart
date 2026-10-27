import 'package:map_core/map_core.dart';
import 'game_state_mutations.dart';

final class NpcPokemonTradeOperations {
  const NpcPokemonTradeOperations();

  GameState trade(GameState state,
      {required NpcPokemonTradeOffer offer,
      required String selectedIndividualId,
      required PlayerPokemon receivedPokemon}) {
    if (state.appliedPokemonGrantOperationIds.contains(offer.operationId)) {
      return state;
    }
    final members = state.party.members;
    final index =
        members.indexWhere((p) => p.individualId == selectedIndividualId);
    if (selectedIndividualId.isEmpty ||
        index < 0 ||
        members.where((p) => p.individualId == selectedIndividualId).length !=
            1 ||
        members[index].speciesId != offer.requestedSpeciesId ||
        receivedPokemon.speciesId != offer.offeredPokemon.speciesId ||
        receivedPokemon.formId != offer.offeredPokemon.formId ||
        receivedPokemon.level !=
            (offer.matchSelectedLevel
                ? members[index].level
                : offer.offeredPokemon.level)) {
      throw StateError('NPC trade selection no longer matches the offer.');
    }
    final received = receivedPokemon.copyWith(
        individualId: '',
        provenance: PlayerPokemonProvenance(
            kind: PlayerPokemonOriginKind.trade,
            mapId: state.currentMapId,
            sourceId: offer.id,
            metLevel: receivedPokemon.level));
    final reduced = state.copyWith(
        party: state.party.copyWith(members: [
      ...members.take(index),
      ...members.skip(index + 1),
    ]));
    final granted = const GameStateMutations().givePokemonOnce(reduced,
        grantOperationId: offer.operationId, pokemon: received);
    if (!granted.appliedPokemonGrantOperationIds.contains(offer.operationId) ||
        granted.party.members.length != members.length) {
      throw StateError('NPC trade acquisition was rejected.');
    }
    final replacement = granted.party.members.last;
    return granted.copyWith(
        party: state.party.copyWith(members: [
      ...members.take(index),
      replacement,
      ...members.skip(index + 1),
    ]));
  }
}
