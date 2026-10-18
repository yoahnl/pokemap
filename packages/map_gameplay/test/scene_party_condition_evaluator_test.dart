import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final context = ScenePartyConditionContext(
    availableMoveIds: ['fixture-move', 'surf'],
    supportedFieldAbilities: [FieldAbility.surf],
  );
  for (final expected in [true, false]) {
    test('known move ignores HP and PP but excludes storage $expected', () {
      final source = SceneConditionSource.partyKnowsMove(
          moveId: 'fixture-move', expected: expected);
      final member = _pokemon('member', hp: 0, pp: 0);
      final state = _state(party: [member]);
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: state, context: context),
          expected);
      final stored = _state(stored: [member]);
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: stored, context: context),
          !expected);
    });

    test(
        'usable move requires the same healthy member and positive current PP $expected',
        () {
      final source = SceneConditionSource.partyHasUsableMove(
          moveId: 'fixture-move', expected: expected);
      for (final members in <List<PlayerPokemon>>[
        [],
        [_pokemon('member', hp: 0)],
        [_pokemon('member', pp: 0)],
        [_pokemon('fainted', hp: 0), _pokemon('exhausted', pp: 0)],
      ]) {
        expect(
            evaluateScenePartyCondition(
                source: source,
                gameState: _state(party: members),
                context: context),
            !expected);
      }
      final state = _state(party: [_pokemon('ready')]);
      final before = state.toJson();
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: state, context: context),
          expected);
      expect(state.toJson(), before);
      expect(
          evaluateScenePartyCondition(
              source: source,
              gameState: GameState.fromJson(before),
              context: context),
          expected);
    });

    test('missing PP cannot become a false business result $expected', () {
      final source = SceneConditionSource.partyHasUsableMove(
          moveId: 'fixture-move', expected: expected);
      for (final pp in <Map<String, int>?>[null, {}]) {
        final state = _state(
            party: [_pokemon('unknown').copyWith(currentPpByMoveId: pp)]);
        expect(
            () => evaluateScenePartyCondition(
                source: source, gameState: state, context: context),
            throwsStateError);
      }
    });

    test(
        'field gate uses support and unlock while PP remain irrelevant $expected',
        () {
      final source = SceneConditionSource.partyCanUseFieldAbility(
          ability: FieldAbility.surf, expected: expected);
      var state = _state(party: [_pokemon('surfer', move: 'surf', pp: 0)]);
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: state, context: context),
          !expected);
      state = state.copyWith(
          progression: const PlayerProgression(
              unlockedFieldAbilities: [FieldAbility.surf]));
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: state, context: context),
          expected);
      expect(
          evaluateScenePartyCondition(
              source: source,
              gameState: state,
              context: ScenePartyConditionContext()),
          !expected);
      state = state.copyWith(
          party:
              PlayerParty(members: [_pokemon('surfer', move: 'surf', hp: 0)]));
      expect(
          evaluateScenePartyCondition(
              source: source, gameState: state, context: context),
          !expected);
    });
  }

  test('move catalog is mandatory and unknown references never select a branch',
      () {
    final state = _state(party: [_pokemon('ready')]);
    for (final source in [
      SceneConditionSource.partyKnowsMove(
          moveId: 'fixture-move', expected: false),
      SceneConditionSource.partyHasUsableMove(
          moveId: 'fixture-move', expected: false),
    ]) {
      expect(
          () => evaluateScenePartyCondition(source: source, gameState: state),
          throwsStateError);
      expect(
          () => evaluateScenePartyCondition(
              source: source,
              gameState: state,
              context: ScenePartyConditionContext(availableMoveIds: ['other'])),
          throwsStateError);
    }
  });

  test('reception decision matches acquisition without generating a candidate',
      () {
    final source = SceneConditionSource.partyCanReceivePokemon();
    final fullParty = [
      for (var i = 0; i < maxPlayerPartySize; i++) _pokemon('member-$i')
    ];
    final fullBox = PokemonBox(
        id: 'box', label: 'Box', capacity: 1, pokemon: [_pokemon('stored')]);
    final states = [
      _state(),
      _state(party: fullParty),
      _state(party: fullParty)
          .copyWith(pokemonStorage: PokemonStorage(boxes: [fullBox])),
    ];
    for (final state in states) {
      final before = state.toJson();
      final plan =
          const GameStateMutations().planPokemonAcquisitionDestination(state);
      final available =
          evaluateScenePartyCondition(source: source, gameState: state);
      expect(state.toJson(), before);
      expect(available, plan.destination != CaptureDestinationKind.none);
      final actual = const GameStateMutations()
          .acquirePokemon(state, pokemon: _pokemon('gift'));
      expect(actual.destination, plan.destination);
      if (plan.storageSlot != null) {
        expect(actual.boxId, plan.storageSlot!.boxId);
        expect(actual.boxIndex, plan.storageSlot!.boxIndex);
      }
    }
  });

  test('context captures immutable sets', () {
    final ids = ['fixture-move'];
    final abilities = [FieldAbility.surf];
    final captured = ScenePartyConditionContext(
        availableMoveIds: ids, supportedFieldAbilities: abilities);
    ids.clear();
    abilities.clear();
    expect(captured.availableMoveIds, {'fixture-move'});
    expect(captured.supportedFieldAbilities, {FieldAbility.surf});
  });
  test('a ready member cannot hide unknown PP on another eligible member', () {
    final ready = _pokemon('ready');
    final unknown = _pokemon('unknown').copyWith(currentPpByMoveId: null);
    final source = SceneConditionSource.partyHasUsableMove(moveId: 'fixture-move');
    for (final members in [[ready, unknown], [unknown, ready]]) {
      expect(() => evaluateScenePartyCondition(source: source,
          gameState: _state(party: members), context: context), throwsStateError);
    }
  });
}

GameState _state(
        {List<PlayerPokemon> party = const [],
        List<PlayerPokemon> stored = const []}) =>
    GameState(
      saveId: 'party-condition',
      party: PlayerParty(members: party),
      pokemonStorage: PokemonStorage(storedPokemon: stored),
    );

PlayerPokemon _pokemon(String id,
        {int hp = 1, int pp = 1, String move = 'fixture-move'}) =>
    PlayerPokemon(
      individualId: id,
      speciesId: 'fixture-species',
      natureId: 'fixture-nature',
      abilityId: 'fixture-ability',
      currentHp: hp,
      knownMoveIds: [move],
      currentPpByMoveId: {move: pp},
    );
