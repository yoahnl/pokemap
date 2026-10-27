import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const source = PlayerPokemon(
      individualId: 'selected',
      speciesId: 'bellsprout',
      natureId: 'hardy',
      abilityId: 'chlorophyll',
      level: 12,
      heldItemId: 'berry');
  const received = PlayerPokemon(
      speciesId: 'onix',
      natureId: 'hasty',
      abilityId: 'rock_head',
      level: 12,
      currentHp: 30);
  final offer = NpcPokemonTradeOffer(
      id: 'village',
      requestedSpeciesId: 'bellsprout',
      offeredPokemon: received);
  final before = GameState(
      saveId: 'trade-save',
      party: const PlayerParty(members: [
        PlayerPokemon(
            individualId: 'leader',
            speciesId: 'pidgey',
            natureId: 'hardy',
            abilityId: 'keen_eye'),
        source,
        PlayerPokemon(
            individualId: 'last',
            speciesId: 'rattata',
            natureId: 'hardy',
            abilityId: 'run_away'),
      ]));
  test('fixed NPC exchange replaces only the selected slot and is durable once',
      () {
    final after = const NpcPokemonTradeOperations().trade(before,
        offer: offer,
        selectedIndividualId: 'selected',
        receivedPokemon: received);
    expect(after.party.members.map((x) => x.speciesId),
        ['pidgey', 'onix', 'rattata']);
    expect(after.party.members.first, before.party.members.first);
    expect(after.party.members.last, before.party.members.last);
    expect(after.party.members[1].individualId, isNot('selected'));
    expect(
        after.party.members[1].provenance!.kind, PlayerPokemonOriginKind.trade);
    expect(after.appliedPokemonGrantOperationIds, contains(offer.operationId));
    expect(after.bag, before.bag);
    expect(after.pokemonStorage, before.pokemonStorage);
    expect(after.progression.caughtSpeciesIds, contains('onix'));
    expect(
        const NpcPokemonTradeOperations().trade(after,
            offer: offer,
            selectedIndividualId: 'leader',
            receivedPokemon: received),
        same(after));
  });
  test('wrong species or level cannot consume the selected Pokemon', () {
    for (final choice in ['leader', 'missing']) {
      expect(
          () => const NpcPokemonTradeOperations().trade(before,
              offer: offer,
              selectedIndividualId: choice,
              receivedPokemon: received),
          throwsStateError);
    }
    expect(
        () => const NpcPokemonTradeOperations().trade(before,
            offer: offer,
            selectedIndividualId: 'selected',
            receivedPokemon: received.copyWith(level: 13)),
        throwsStateError);
    expect(before.party.members[1], source);
  });
}
