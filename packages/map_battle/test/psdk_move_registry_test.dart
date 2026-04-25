import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean move registry', () {
    test('resolves behaviors by battleEngineMethod, not by move id', () {
      final registry = createStaticBasicMoveRegistry();
      final scratch = _definition(id: 'scratch', dbSymbol: 'scratch');
      final tackle = _definition(id: 'tackle', dbSymbol: 'tackle');

      expect(scratch.id, isNot(tackle.id));
      expect(scratch.battleEngineMethod, tackle.battleEngineMethod);
      expect(
        registry.resolve(scratch.battleEngineMethod),
        same(registry.resolve(tackle.battleEngineMethod)),
      );
    });

    test('fails loudly for an unsupported battleEngineMethod', () {
      final registry = createStaticBasicMoveRegistry();

      expect(
        () => registry.resolve('s_missing'),
        throwsA(isA<UnsupportedBattleMoveBehavior>()),
      );
      expect(
        () => PsdkBattleMoveBehaviorRegistry.fromClean(registry).resolve(
          method: 's_missing',
          context: _psdkContext(move: _definition().psdkMove),
        ),
        throwsA(isA<UnsupportedPsdkBattleMoveBehavior>()),
      );
    });

    test('snapshots behavior collections at construction', () {
      final behaviors = <BattleMoveBehavior>[
        _NoopMoveBehavior('s_custom'),
      ];
      final registry = BattleMoveRegistry(behaviors);
      behaviors.clear();

      expect(registry.resolve('s_custom').battleEngineMethod, 's_custom');
    });

    test('keeps PSDK accuracy zero as a bypass sentinel', () {
      final psdk = _definition(accuracy: 0).psdkMove;
      final definition = BattleMoveDefinition.fromPsdk(psdk);

      expect(psdk.accuracy, 0);
      expect(definition.accuracy, 0);
      expect(definition.psdkMove.accuracy, 0);
    });

    test('separates immutable move definition from mutable move instance', () {
      final definition = _definition(pp: 5);
      final instance = BattleMoveInstance.fromDefinition(definition);

      expect(instance.data, same(definition));
      expect(instance.pp, 5);

      expect(instance.spendPp(), isTrue);
      instance.markUsed(
        damageDealt: 12,
        originalTargets: const <BattlePositionRef>[
          BattlePositionRef(bank: 1, position: 0),
        ],
      );

      expect(definition.pp, 5);
      expect(instance.pp, 3);
      expect(instance.used, isTrue);
      expect(instance.consecutiveUseCount, 1);
      expect(instance.damageDealt, 12);
      expect(
        () => instance.originalTargets.clear(),
        throwsUnsupportedError,
      );
    });

    test('does not shadow legacy BattleMoveData at the root API', () {
      const legacyMoveData = BattleMoveData(
        id: 'legacy-tackle',
        name: 'Tackle',
        power: 40,
      );
      final cleanDefinition = _definition();

      expect(legacyMoveData, isA<BattleMoveData>());
      expect(cleanDefinition, isA<BattleMoveDefinition>());
    });
  });
}

final class _NoopMoveBehavior implements BattleMoveBehavior {
  const _NoopMoveBehavior(this.battleEngineMethod);

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: const <PsdkBattleEvent>[],
    );
  }
}

PsdkBattleMoveContext _psdkContext({
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleMoveContext(
    state: PsdkBattleState.fromSetup(_setup(move: move)),
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 2,
      moveAccuracySeed: 3,
      genericSeed: 4,
    ),
    turn: 1,
    user: psdkPlayerSlot,
    target: psdkOpponentSlot,
    move: move,
  );
}

PsdkBattleSetup _setup({
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      moves: <PsdkBattleMoveData>[move],
    ),
    opponent: _combatant(
      id: 'opponent',
      moves: <PsdkBattleMoveData>[_definition(id: 'foe-move').psdkMove],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves,
  );
}

BattleMoveDefinition _definition({
  String id = 'scratch',
  String dbSymbol = 'scratch',
  int accuracy = 100,
  int pp = 35,
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: dbSymbol,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: accuracy,
    pp: pp,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
