import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  for (final stat in ['attack', 'defense', 'special_attack', 'special_defense', 'speed', 'accuracy']) {
    test('$stat boost caps at six and refuses another item without a turn', () {
      final engine=BattleEngine(setup:setup());
      for(var i=0;i<6;i++) {
        engine.submit(BattleDecision.item(itemId:'x-stat',target:psdkPlayerSlot,effect:PsdkBattleStatBoostItemEffect(stat:stat,stages:1),highPriority:true));
      }
      expect(engine.snapshot().battlerAt(psdkPlayerSlot).statStages.valueOf(stat),6);
      final before=engine.snapshot().turnNumber;
      expect(()=>engine.submit(BattleDecision.item(itemId:'x-stat',target:psdkPlayerSlot,effect:PsdkBattleStatBoostItemEffect(stat:stat,stages:1),highPriority:true)),throwsA(isA<BattleDecisionRejectedError>()));
      expect(engine.snapshot().turnNumber,before);
    });
  }
  test('battle preparation respects ability hooks and switching scopes', () {
    final contrary=BattleEngine(setup:BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player:combatant('player',abilityId:'contrary'),opponent:combatant('enemy'),rngSeeds:const PsdkBattleRngSeeds(moveDamage:1,moveCritical:99999,moveAccuracy:3,generic:4)));
    contrary.submit(const BattleDecision.item(itemId:'x-attack',target:psdkPlayerSlot,effect:PsdkBattleStatBoostItemEffect(stat:'attack',stages:1),highPriority:true));
    expect(contrary.snapshot().battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),-1);
    final engine=BattleEngine(setup:BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player:combatant('player'),opponent:combatant('enemy'),playerReserves:[combatant('reserve')],rngSeeds:const PsdkBattleRngSeeds(moveDamage:1,moveCritical:99999,moveAccuracy:3,generic:4)));
    engine.submit(const BattleDecision.item(itemId:'dire-hit',target:psdkPlayerSlot,effect:PsdkBattlePreparationItemEffect.focusEnergy(),highPriority:true));
    engine.submit(const BattleDecision.item(itemId:'guard-spec',target:psdkPlayerSlot,effect:PsdkBattlePreparationItemEffect.mist(turns:5),highPriority:true));
    engine.submit(const BattleDecision.switchPokemon(partyIndex:1));
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).effects.contains('focus_energy'),isFalse);
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).effects.contains('mist'),isTrue);
    engine.submit(const BattleDecision.switchPokemon(partyIndex:0));
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).effects.contains('focus_energy'),isFalse);
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),0);
  });
  test('X Attack applies a bounded stage and consumes once in a real turn', () {
    final engine = BattleEngine(setup: setup());
    final turn = engine.submit(const BattleDecision.item(
        itemId: 'x-attack',
        target: psdkPlayerSlot,
        effect: PsdkBattleStatBoostItemEffect(stat: 'attack', stages: 1),
        highPriority: true));
    expect(
        turn.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'), 1);
    expect(turn.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1));
    expect(
        turn.timeline.events.whereType<BattleItemTimelineEvent>().single.kind,
        'item_consumed');
  });
  test('Dire Hit cannot be stacked and Guard Spec expires after five turns',
      () {
    final engine = BattleEngine(setup: setup());
    final focus = engine.submit(const BattleDecision.item(
        itemId: 'dire-hit',
        target: psdkPlayerSlot,
        effect: PsdkBattlePreparationItemEffect.focusEnergy(),
        highPriority: true));
    expect(
        focus.state.battlerAt(psdkPlayerSlot).effects.contains('focus_energy'),
        isTrue);
    final beforeDuplicate = engine.snapshot();
    expect(
        () => engine.submit(const BattleDecision.item(
            itemId: 'dire-hit',
            target: psdkPlayerSlot,
            effect: PsdkBattlePreparationItemEffect.focusEnergy(),
            highPriority: true)),
        throwsA(isA<BattleDecisionRejectedError>()));
    expect(engine.snapshot().battlerAt(psdkPlayerSlot),
        same(beforeDuplicate.battlerAt(psdkPlayerSlot)));
    final mist = engine.submit(const BattleDecision.item(
        itemId: 'guard-spec',
        target: psdkPlayerSlot,
        effect: PsdkBattlePreparationItemEffect.mist(turns: 5),
        highPriority: true));
    expect(
        mist.state.battlerAt(psdkPlayerSlot).effects.contains('mist'), isTrue);
    for (var i = 0; i < 4; i++) {
      engine.submit(const BattleDecision.fight(moveSlot: 0));
    }
    expect(engine.snapshot().battlerAt(psdkPlayerSlot).effects.contains('mist'),
        isFalse);
  });
}

BattleEngineSetup setup() => BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: combatant('player'),
    opponent: combatant('enemy'),
    rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1, moveCritical: 99999, moveAccuracy: 3, generic: 4));
PsdkBattleCombatantSetup combatant(String id, {String abilityId='none'}) => PsdkBattleCombatantSetup(
        id: id,
        abilityId: abilityId,
        speciesId: 'eevee',
        displayName: 'Évoli',
        level: 20,
        maxHp: 100,
        currentHp: 100,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
            attack: 20,
            defense: 20,
            specialAttack: 20,
            specialDefense: 20,
            speed: 20),
        moves: [
          PsdkBattleMoveData(
              id: 'wait',
              dbSymbol: 'wait',
              name: 'Attente',
              type: 'normal',
              category: PsdkBattleMoveCategory.physical,
              power: 0,
              accuracy: 100,
              pp: 35,
              priority: 0,
              battleEngineMethod: 's_basic',
              target: PsdkBattleMoveTarget.adjacentFoe)
        ]);
