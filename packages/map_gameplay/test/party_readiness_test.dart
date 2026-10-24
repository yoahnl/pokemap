import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

PlayerPokemon mon(String id, int hp) => PlayerPokemon(
    individualId: id,
    speciesId: 'rattata',
    natureId: 'hardy',
    abilityId: 'run_away',
    currentHp: hp);
void main() {
  test('readiness counts positive HP and ignores fainted members', () {
    for (final (hp, expected) in [
      (<int>[], false),
      ([1], false),
      ([1, 0], false),
      ([0, 0], false),
      ([1, 1], true),
      ([1, 0, 1], true)
    ]) {
      final party = PlayerParty(
          members: [for (var i = 0; i < hp.length; i++) mon('$i', hp[i])]);
      expect(partyHasAtLeastUsableMembers(party, 2), expected);
      final state = GameState(saveId: 'readiness', party: party);
      final loaded = gameStateFromSaveData(saveDataFromGameState(state));
      expect(partyHasAtLeastUsableMembers(loaded.party, 2), expected);
    }
  });
  test('invalid thresholds fail closed while one and six remain supported', () {
    final party =
        PlayerParty(members: [for (var i = 0; i < 6; i++) mon('$i', 1)]);
    for (final count in [-1, 0, 7]) {
      expect(partyHasAtLeastUsableMembers(party, count), isFalse);
    }
    expect(partyHasAtLeastUsableMembers(party, 1), isTrue);
    expect(partyHasAtLeastUsableMembers(party, 6), isTrue);
  });
}
