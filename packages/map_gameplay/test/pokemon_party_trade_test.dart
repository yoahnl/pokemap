import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

PlayerPokemon pokemon(String id, String species, {String? heldItem}) =>
    PlayerPokemon(
        individualId: id,
        speciesId: species,
        natureId: 'bold',
        abilityId: 'synchronize',
        gender: 'female',
        level: 20,
        experience: 8000,
        currentHp: 19,
        heldItemId: heldItem ?? '',
        knownMoveIds: const ['confusion'],
        currentPpByMoveId: const {'confusion': 7});

PokemonEvolutionCandidate candidate(
        {PokemonTradeEvolutionRequirements? requirements,
        String id = 'native-trade',
        String target = 'alakazam'}) =>
    PokemonEvolutionCandidate(
        opportunityId: id,
        sourceSpeciesId: 'kadabra',
        targetSpeciesId: target,
        condition: PokemonEvolutionCondition.trade(
            requirements:
                requirements ?? const PokemonTradeEvolutionRequirements()),
        targetBaseStats: const PokemonBaseStats(
            hp: 55,
            attack: 50,
            defense: 45,
            specialAttack: 135,
            specialDefense: 95,
            speed: 120),
        targetPrimaryAbilityId: 'synchronize',
        targetAbilityIds: const ['synchronize']);

void main() {
  final first = pokemon('first-id', 'kadabra');
  final partner = pokemon('partner-id', 'machoke');
  GameState state(
          {PlayerPokemon? replaceFirst, List<PlayerPokemon>? members}) =>
      GameState(
          saveId: 'native-self-trade',
          trainerProfile: const TrainerProfile(name: 'Player'),
          party:
              PlayerParty(members: members ?? [replaceFirst ?? first, partner]),
          progression: const PlayerProgression(
              caughtSpeciesIds: ['kadabra', 'machoke'],
              seenSpeciesIds: ['kadabra', 'machoke']));
  final catalog = ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(schemaVersion: 1, entries: [
    ProjectItemDefinition(
        id: 'native-stone',
        displayName: 'Stable Stone',
        pocketId: 'items',
        heldEffectId: 'prevent_evolution'),
    ProjectItemDefinition(
        id: 'native-coat', displayName: 'Metal Coat', pocketId: 'items'),
    ProjectItemDefinition(
        id: 'ordinary-item', displayName: 'Berry', pocketId: 'items')
  ]));
  final policy = PokemonEvolutionHeldItemPolicy.fromCatalog(catalog);
  PokemonPartyTradeResult trade(GameState input,
          {String firstId = 'first-id',
          String partnerId = 'partner-id',
          List<PokemonEvolutionCandidate>? choices}) =>
      const PokemonPartyTradeOperations().trade(input,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          firstIndividualId: firstId,
          partnerIndividualId: partnerId,
          candidates: choices ?? [candidate()],
          sourceMaxHp: 40,
          heldItemPolicy: policy);

  test('trade condition is isolated from level and item triggers', () {
    final rule = candidate();
    expect(
        rule.isEligible(first,
            trigger: const PokemonEvolutionTrigger.levelUp()),
        false);
    expect(
        rule.isEligible(first,
            trigger: const PokemonEvolutionTrigger.itemUse('stone')),
        false);
    expect(
        rule.isEligible(first,
            trigger: const PokemonEvolutionTrigger.trade(
                partnerSpeciesId: 'machoke')),
        true);
  });
  test(
      'native trade evolves first identity without swapping the partner or party',
      () {
    final before = state();
    final result = trade(before);
    expect(result.isSuccess, true);
    expect(result.evolution, isNotNull);
    final evolved = result.state.party.members.first;
    expect(evolved.speciesId, 'alakazam');
    expect(evolved.individualId, 'first-id');
    expect(evolved.natureId, first.natureId);
    expect(evolved.abilityId, 'synchronize');
    expect(evolved.gender, first.gender);
    expect(evolved.ivs, first.ivs);
    expect(evolved.evs, first.evs);
    expect(evolved.knownMoveIds, first.knownMoveIds);
    expect(evolved.currentPpByMoveId, first.currentPpByMoveId);
    expect(evolved.experience, first.experience);
    expect(evolved.level, first.level);
    expect(result.state.party.members[1], partner);
    expect(result.state.bag, before.bag);
    expect(result.state.progression.caughtSpeciesIds, contains('alakazam'));
    expect(result.state.progression.storyFlags, before.progression.storyFlags);
  });
  test('same individual is a valid source branch and evolves only once', () {
    final result = trade(state(), partnerId: 'first-id');
    expect(result.isSuccess, true);
    expect(result.state.party.members.length, 2);
    expect(result.state.party.members.first.speciesId, 'alakazam');
    expect(result.state.party.members[1], partner);
  });
  test('unknown or ambiguous individual ids refuse without state changes', () {
    final before = state();
    final unknown = trade(before, firstId: 'missing');
    expect(unknown.isSuccess, false);
    expect(unknown.state, before);
    final duplicate = state(members: [first, first]);
    final result = trade(duplicate);
    expect(result.isSuccess, false);
    expect(result.state, duplicate);
  });
  test('empty catalog completes a native trade without inventing an evolution',
      () {
    final before = state();
    final result = trade(before, choices: []);
    expect(result.isSuccess, true);
    expect(result.evolution, isNull);
    expect(result.state, before);
  });
  test('partner species constraint is checked against the selected individual',
      () {
    final rule = candidate(
        requirements: const PokemonTradeEvolutionRequirements(
            requiredPartnerSpeciesId: 'shelmet'));
    final before = state();
    final result = trade(before, choices: [rule]);
    expect(result.isSuccess, true);
    expect(result.evolution, isNull);
    expect(result.state, before);
  });
  test(
      'held requirement consumes the actual first held item only after evolution',
      () {
    final holding = first.copyWith(heldItemId: 'native-coat');
    final before = state(replaceFirst: holding);
    final result = trade(before, choices: [
      candidate(
          requirements: const PokemonTradeEvolutionRequirements(
              requiredHeldItemId: 'native-coat'))
    ]);
    expect(result.isSuccess, true);
    expect(result.evolution, isNotNull);
    expect(result.state.party.members.first.heldItemId, isEmpty);
    expect(result.state.bag, before.bag);
    expect(result.state.party.members[1], partner);
    final missing = trade(state(), choices: [
      candidate(
          requirements: const PokemonTradeEvolutionRequirements(
              requiredHeldItemId: 'native-coat'))
    ]);
    expect(missing.isSuccess, true);
    expect(missing.evolution, isNull);
  });
  test('catalogue-defined prevention blocks with an arbitrary native item id',
      () {
    final before =
        state(replaceFirst: first.copyWith(heldItemId: 'native-stone'));
    final result = trade(before);
    expect(result.isSuccess, true);
    expect(result.evolution, isNull);
    expect(result.state, before);
    expect(result.state.party.members.first.heldItemId, 'native-stone');
    final ordinary =
        trade(state(replaceFirst: first.copyWith(heldItemId: 'ordinary-item')));
    expect(ordinary.evolution, isNotNull);
    expect(ordinary.state.party.members.first.heldItemId, 'ordinary-item');
  });
  test('multiple eligible native candidates refuse atomically', () {
    final before = state();
    final result = trade(before,
        choices: [candidate(), candidate(id: 'other', target: 'branch')]);
    expect(result.isSuccess, false);
    expect(result.state, before);
  });
  test('a held item absent from the native policy fails closed', () {
    final before =
        state(replaceFirst: first.copyWith(heldItemId: 'unknown-held'));
    final result = trade(before);
    expect(result.isSuccess, false);
    expect(result.state, before);
  });
  test(
      'trade result survives canonical save reload with stable partner identity',
      () {
    final result = trade(state());
    final reloaded = GameState.fromJson(result.state.toJson());
    expect(reloaded.party.members.first.individualId, 'first-id');
    expect(reloaded.party.members.first.speciesId, 'alakazam');
    expect(reloaded.party.members[1].individualId, 'partner-id');
    expect(reloaded.progression.caughtSpeciesIds, contains('alakazam'));
  });
}
