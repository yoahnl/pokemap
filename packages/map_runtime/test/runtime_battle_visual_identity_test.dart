import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

void main() {
  test('reports unknown visual identity without a source', () {
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());
    final combatant = session.presentation.activeCombatants.first;

    expect(combatant.initialVisualIdentity, isNull);
    expect(combatant.currentVisualIdentity, isNull);
    expect(
      combatant.visualIdentityUnavailableReason,
      RuntimeBattleVisualIdentityUnavailableReason.unknownSource,
    );
  });

  test('keeps two same-species identities distinct after switching', () {
    final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant('p-a', speciesId: 'pikachu'),
      playerReserves: [_combatant('p-b', speciesId: 'pikachu')],
      opponent: _combatant('e-a', speciesId: 'eevee'),
      rngSeeds: _seeds,
    );
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(
      setup,
      visualIdentitiesByBank: {
        0: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'pikachu',
            formId: 'alpha',
            genderId: 'female',
            isShiny: true,
          ),
          const RuntimeBattleVisualIdentity(
            speciesId: 'pikachu',
            formId: 'beta',
            genderId: 'male',
            isShiny: false,
          ),
        ],
        1: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'eevee',
            formId: null,
            genderId: null,
            isShiny: false,
          ),
        ],
      },
    );

    var active = session.presentation.combatantAt(
      const BattleSlotRef.active(BattleSideId.player),
    )!;
    expect(active.combatantId, 'p-a');
    expect(active.initialVisualIdentity!.formId, 'alpha');
    expect(active.currentVisualIdentity!.genderId, 'female');
    expect(active.currentVisualIdentity!.isShiny, isTrue);
    expect(active.visualIdentityUnavailableReason, isNull);

    session.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
    active = session.presentation.combatantAt(
      const BattleSlotRef.active(BattleSideId.player),
    )!;
    expect(active.combatantId, 'p-b');
    expect(active.initialVisualIdentity!.formId, 'beta');
    expect(active.currentVisualIdentity!.genderId, 'male');
    expect(active.currentVisualIdentity!.isShiny, isFalse);
  });

  test('rejects an unproven lineup association', () {
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(
      _setup(),
      visualIdentitiesByBank: {
        0: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'wrong-species',
            formId: null,
            genderId: null,
            isShiny: false,
          ),
        ],
      },
    );
    final active = session.presentation.activeCombatants.first;
    expect(active.initialVisualIdentity, isNull);
    expect(active.currentVisualIdentity, isNull);
    expect(
      active.visualIdentityUnavailableReason,
      RuntimeBattleVisualIdentityUnavailableReason.unknownSource,
    );
  });

  test('rejects a lineup with a different number of sources', () {
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(
      _setup(),
      visualIdentitiesByBank: {
        0: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'player',
            formId: null,
            genderId: null,
            isShiny: false,
          ),
          const RuntimeBattleVisualIdentity(
            speciesId: 'player',
            formId: null,
            genderId: null,
            isShiny: false,
          ),
        ],
      },
    );
    final active = session.presentation.activeCombatants.first;
    expect(active.initialVisualIdentity, isNull);
    expect(active.currentVisualIdentity, isNull);
    expect(
      active.visualIdentityUnavailableReason,
      RuntimeBattleVisualIdentityUnavailableReason.unknownSource,
    );
  });

  test('keeps the initial identity after a real Transform but hides its current identity', () {
    final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant('ditto', moves: [_transformMove()]),
      opponent: _combatant('pikachu'),
      rngSeeds: _seeds,
    );
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(
      setup,
      visualIdentitiesByBank: {
        0: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'ditto',
            formId: null,
            genderId: null,
            isShiny: true,
          ),
        ],
        1: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'pikachu',
            formId: 'female',
            genderId: 'female',
            isShiny: false,
          ),
        ],
      },
    );

    session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
    final active = session.presentation.combatantAt(
      const BattleSlotRef.active(BattleSideId.player),
    )!;
    expect(
      session.state.psdkState
          .battlerAt(psdkPlayerSlot)
          .transformState
          .isTransformed,
      isTrue,
    );
    expect(active.initialVisualIdentity!.speciesId, 'ditto');
    expect(active.currentVisualIdentity, isNull);
    expect(
      active.visualIdentityUnavailableReason,
      RuntimeBattleVisualIdentityUnavailableReason.transformed,
    );
  });

  test('does not reuse the original identity while an illusion is active', () {
    final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(
        'zoroark',
        transformState: const PsdkBattleTransformState(
          illusionSpeciesId: 'pikachu',
        ),
      ),
      opponent: _combatant('opponent'),
      rngSeeds: _seeds,
    );
    final session = RuntimePsdkBattleSessionAdapter.fromSetup(
      setup,
      visualIdentitiesByBank: {
        0: [
          const RuntimeBattleVisualIdentity(
            speciesId: 'zoroark',
            formId: null,
            genderId: null,
            isShiny: false,
          ),
        ],
      },
    );
    final active = session.presentation.activeCombatants.first;
    expect(active.initialVisualIdentity!.speciesId, 'zoroark');
    expect(active.currentVisualIdentity, isNull);
    expect(
      active.visualIdentityUnavailableReason,
      RuntimeBattleVisualIdentityUnavailableReason.illusion,
    );
  });

  test(
    'does not reuse the original identity after a switch changes numeric form',
    () {
      final setup = PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
        player: _combatant('player'),
        playerReserves: [_combatant('groudon', heldItemId: 'red_orb')],
        opponent: _combatant('opponent'),
        rngSeeds: _seeds,
      );
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        setup,
        visualIdentitiesByBank: {
          0: [
            const RuntimeBattleVisualIdentity(
              speciesId: 'player',
              formId: null,
              genderId: null,
              isShiny: false,
            ),
            const RuntimeBattleVisualIdentity(
              speciesId: 'groudon',
              formId: null,
              genderId: null,
              isShiny: true,
            ),
          ],
        },
      );
      session.submitPlayerChoice(const PlayerBattleChoiceSwitch(0));
      final active = session.presentation.activeCombatants.first;
      expect(session.state.psdkState.battlerAt(psdkPlayerSlot).form, 1);
      expect(active.initialVisualIdentity!.speciesId, 'groudon');
      expect(active.currentVisualIdentity, isNull);
      expect(
        active.visualIdentityUnavailableReason,
        RuntimeBattleVisualIdentityUnavailableReason.appearanceChanged,
      );
    },
  );
}

const _seeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 1,
  generic: 1,
);

PsdkBattleSetup _setup() => PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
  player: _combatant('player'),
  opponent: _combatant('opponent'),
  rngSeeds: const PsdkBattleRngSeeds(
    moveDamage: 1,
    moveCritical: 2,
    moveAccuracy: 3,
    generic: 4,
  ),
);

PsdkBattleCombatantSetup _combatant(
  String id, {
  String? speciesId,
  List<PsdkBattleMoveData>? moves,
  String? heldItemId,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
}) => PsdkBattleCombatantSetup(
  id: id,
  speciesId: speciesId ?? id,
  displayName: id,
  level: 10,
  maxHp: 100,
  currentHp: 100,
  heldItemId: heldItemId,
  transformState: transformState,
  types: const PsdkBattleTypes(primary: 'normal'),
  stats: const PsdkBattleStats(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  ),
  moves:
      moves ??
      [
        PsdkBattleMoveData(
          id: 'wait',
          dbSymbol: 'wait',
          name: 'wait',
          type: 'normal',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 100,
          pp: 10,
          currentPp: 10,
          priority: 0,
          battleEngineMethod: 's_status',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      ],
);

PsdkBattleMoveData _transformMove() => PsdkBattleMoveData(
  id: 'transform',
  dbSymbol: 'transform',
  name: 'transform',
  type: 'normal',
  category: PsdkBattleMoveCategory.status,
  power: 0,
  accuracy: 100,
  pp: 10,
  currentPp: 10,
  priority: 0,
  battleEngineMethod: 's_transform',
  target: PsdkBattleMoveTarget.adjacentFoe,
);
