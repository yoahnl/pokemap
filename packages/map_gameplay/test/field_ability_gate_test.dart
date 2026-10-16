import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

PlayerPokemon _pokemon({
  List<String> moves = const [],
  int hp = 20,
  Map<String, int>? pp,
}) =>
    PlayerPokemon(
      speciesId: 'scyther',
      natureId: 'hardy',
      abilityId: 'swarm',
      knownMoveIds: moves,
      currentHp: hp,
      currentPpByMoveId: pp,
    );

void main() {
  test('a progression unlock does not make an unsupported ability supported',
      () {
    final result = evaluateFieldAbilityGate(
      ability: FieldAbility.cut,
      supportedAbilities: betaSignedFieldAbilities,
      unlockedFieldAbilities: const {FieldAbility.cut},
      party: PlayerParty(members: [
        _pokemon(moves: ['cut'])
      ]),
    );

    expect(result.status, FieldAbilityGateStatus.unsupported);
    expect(result.partyIndex, isNull);
    expect(betaSignedFieldAbilities, {FieldAbility.surf});
  });

  test('support does not grant a progression unlock', () {
    final result = evaluateFieldAbilityGate(
      ability: FieldAbility.cut,
      supportedAbilities: const {FieldAbility.cut},
      unlockedFieldAbilities: const {},
      party: PlayerParty(members: [
        _pokemon(moves: ['cut'])
      ]),
    );

    expect(result.status, FieldAbilityGateStatus.locked);
    expect(result.partyIndex, isNull);
  });

  test('a missing usable move keeps priority over a missing unlock', () {
    final result = evaluateFieldAbilityGate(
      ability: FieldAbility.surf,
      supportedAbilities: betaSignedFieldAbilities,
      unlockedFieldAbilities: const {},
      party: const PlayerParty(),
    );

    expect(result.status, FieldAbilityGateStatus.missingMove);
    expect(result.partyIndex, isNull);
  });

  for (final ability in FieldAbility.values) {
    test('${ability.name} requires a conscious member with its own move', () {
      final result = evaluateFieldAbilityGate(
        ability: ability,
        supportedAbilities: {ability},
        unlockedFieldAbilities: {ability},
        party: PlayerParty(members: [
          _pokemon(moves: [ability.moveId], hp: 0),
          _pokemon(moves: ['tackle']),
        ]),
      );

      expect(result.status, FieldAbilityGateStatus.missingMove);
      expect(result.partyIndex, isNull);
    });

    test('${ability.name} selects the first usable member without requiring PP',
        () {
      final party = PlayerParty(members: [
        _pokemon(moves: [ability.moveId], hp: 0),
        _pokemon(moves: ['tackle']),
        _pokemon(moves: [ability.moveId], pp: {ability.moveId: 0}),
        _pokemon(moves: [ability.moveId]),
      ]);
      final before = party.toJson();

      final result = evaluateFieldAbilityGate(
        ability: ability,
        supportedAbilities: {ability},
        unlockedFieldAbilities: {ability},
        party: party,
      );

      expect(result.status, FieldAbilityGateStatus.usable);
      expect(result.partyIndex, 2);
      expect(party.toJson(), before);
    });
  }
}
