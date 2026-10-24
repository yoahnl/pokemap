import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test(
      'battle boosts validate active targets without persisting temporary stats',
      () {
    for (final effect in [
      const ProjectItemEffectDefinition.battleBoost(
          stat: ProjectItemBattleStat.attack, stages: 1),
      const ProjectItemEffectDefinition.battlePreparation(
          effect: ProjectItemBattlePreparationKind.focusEnergy),
      const ProjectItemEffectDefinition.battlePreparation(
          effect: ProjectItemBattlePreparationKind.mist, turns: 5),
    ]) {
      final initial = state(const PokemonStatSpread());
      final service = PlayerItemUseService(
          snapshot: ItemCatalogSnapshot.fromCatalog(
              ProjectItemCatalog(schemaVersion: 1, entries: [
        ProjectItemDefinition(
            id: 'protein',
            displayName: 'Objet',
            pocketId: 'battle',
            uses: [
              ProjectItemUseDefinition(
                  contexts: {ProjectItemUseContext.battle},
                  target: ProjectItemTargetKind.partyMember,
                  consumption: ProjectItemConsumptionPolicy.onApplied,
                  effect: effect)
            ])
      ])));
      PlayerItemUseResult invoke(
              {bool active = true, bool duplicate = false}) =>
          service.use(PlayerItemUseRequest(
              state: initial,
              itemId: 'protein',
              context: ProjectItemUseContext.battle,
              partyIndex: 0,
              maxHp: 100,
              targetIsActiveBattler: active,
              targetBattleStages: {
                ProjectItemBattleStat.attack: duplicate ? 6 : 0
              },
              targetHasFocusEnergy: duplicate,
              targetBankHasMist: duplicate));
      final applied = invoke();
      expect(applied.isSuccess, isTrue);
      expect(applied.state.party, initial.party);
      expect(applied.consumptionReceipt?.quantity, 1);
      for (final rejected in [invoke(active: false), invoke(duplicate: true)]) {
        expect(rejected.isSuccess, isFalse);
        expect(rejected.state, initial);
        expect(rejected.consumptionReceipt, isNull);
      }
    }
  });
  test('HP Up recalculates maximum HP and preserves fainting and damage', () {
    const base = PokemonBaseStats(
        hp: 50,
        attack: 50,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 50);
    final initial = state(const PokemonStatSpread(hp: 92));
    final member = initial.party.members.single;
    final oldMax = const PokemonStatCalculator()
        .calculate(
            baseStats: base,
            ivs: member.ivs,
            evs: member.evs,
            level: member.level,
            naturePolicy: PokemonNatureStatPolicy.canonical,
            natureId: member.natureId)
        .maxHp;
    final service = PlayerItemUseService(
        snapshot: ItemCatalogSnapshot.fromCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'protein',
          displayName: 'PV Plus',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.vitamin(
                    stat: ProjectItemVitaminStat.hp,
                    amount: 10,
                    maximumPerStat: 100))
          ])
    ])));
    for (final hp in [0, 50]) {
      final source = initial.copyWith(
          party: PlayerParty(members: [member.copyWith(currentHp: hp)]));
      final result = service.use(PlayerItemUseRequest(
          state: source,
          itemId: 'protein',
          context: ProjectItemUseContext.overworld,
          partyIndex: 0,
          maxHp: oldMax,
          baseStats: base));
      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.evs.hp, 100);
      expect(result.state.party.members.single.currentHp, hp == 0 ? 0 : 51);
    }
    expect(
        service
            .use(PlayerItemUseRequest(
                state: initial,
                itemId: 'protein',
                context: ProjectItemUseContext.overworld,
                partyIndex: 0,
                maxHp: oldMax))
            .failure,
        PlayerItemUseFailure.invalidRequest);
  });
  test('HGSS vitamin applies partial EV room, friendship and one consumption',
      () {
    final initial = state(const PokemonStatSpread(attack: 95));
    final result = use(initial);
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.evs.attack, 100);
    expect(result.state.party.members.single.friendship, 75);
    expect(result.state.bag.entries.single.quantity, 1);
    expect(result.consumptionReceipt?.quantity, 1);
    expect(initial.party.members.single.evs.attack, 95);
    expect(GameState.fromJson(result.state.toJson()), result.state);
  });

  test('HGSS vitamin respects total EV room independently of stat room', () {
    final result = use(state(const PokemonStatSpread(hp: 252, defense: 252)));
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.evs.attack, 6);
  });

  test('vitamin no-effect and battle refusals preserve state and stock', () {
    for (final spread in [
      const PokemonStatSpread(attack: 100),
      const PokemonStatSpread(hp: 252, defense: 252, speed: 6)
    ]) {
      final initial = state(spread), result = use(initial);
      expect(result.failure, PlayerItemUseFailure.noEffect);
      expect(result.state, initial);
      expect(result.consumptionReceipt, isNull);
    }
    final initial = state(const PokemonStatSpread());
    expect(use(initial, context: ProjectItemUseContext.battle).failure,
        PlayerItemUseFailure.unavailableInContext);
  });

  test('vitamin friendship tiers are configured and capped', () {
    for (final pair in [(99, 104), (199, 202), (254, 255)]) {
      final initial = state(const PokemonStatSpread());
      final result = use(initial.copyWith(
          party: PlayerParty(members: [
        initial.party.members.single.copyWith(friendship: pair.$1)
      ])));
      expect(result.state.party.members.single.friendship, pair.$2);
    }
  });
}

PlayerItemUseResult use(GameState initial,
    {ProjectItemUseContext context = ProjectItemUseContext.overworld}) {
  final effect = ProjectItemEffectDefinition.fromJson({
    'kind': 'vitamin',
    'stat': 'attack',
    'amount': 10,
    'maximumPerStat': 100,
    'maximumTotal': 510,
    'friendshipGainLow': 5,
    'friendshipGainMedium': 3,
    'friendshipGainHigh': 2
  });
  final service = PlayerItemUseService(
      snapshot: ItemCatalogSnapshot.fromCatalog(
          ProjectItemCatalog(schemaVersion: 1, entries: [
    ProjectItemDefinition(
        id: 'protein',
        displayName: 'Protéine',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: effect)
        ])
  ])));
  return service.use(PlayerItemUseRequest(
      state: initial,
      itemId: 'protein',
      context: context,
      partyIndex: 0,
      maxHp: 100));
}

GameState state(PokemonStatSpread evs) => GameState(
    saveId: 'vitamin',
    party: PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'totodile',
          natureId: 'hardy',
          abilityId: 'torrent',
          level: 50,
          currentHp: 50,
          friendship: 70,
          evs: evs)
    ]),
    bag: const Bag(entries: [BagEntry(itemId: 'protein', quantity: 2)]));
