import 'package:map_core/map_core.dart';

import 'psdk_battle_combatant.dart';
import 'psdk_battle_field.dart';
import 'psdk_battle_rng.dart';
import 'psdk_battle_slots.dart';
import '../../pokemon_battle_rules.dart';

/// Input setup for the parallel PSDK engine.
///
class PsdkBattleSetup {
  factory PsdkBattleSetup.singlesPokeMapBetaV1ForTest({
    required PsdkBattleCombatantSetup player,
    required PsdkBattleCombatantSetup opponent,
    required PsdkBattleRngSeeds rngSeeds,
    PsdkBattleFieldState field = const PsdkBattleFieldState(),
    bool canFlee = false,
    bool canCapture = false,
    bool isTrainerBattle = false,
    List<PsdkBattleCombatantSetup> playerReserves =
        const <PsdkBattleCombatantSetup>[],
    List<PsdkBattleCombatantSetup> opponentReserves =
        const <PsdkBattleCombatantSetup>[],
  }) {
    return PsdkBattleSetup.singles(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      player: player,
      opponent: opponent,
      rngSeeds: rngSeeds,
      field: field,
      canFlee: canFlee,
      canCapture: canCapture,
      isTrainerBattle: isTrainerBattle,
      playerReserves: playerReserves,
      opponentReserves: opponentReserves,
    );
  }

  PsdkBattleSetup.singles({
    required this.ruleset,
    required PsdkBattleCombatantSetup player,
    required PsdkBattleCombatantSetup opponent,
    required this.rngSeeds,
    this.field = const PsdkBattleFieldState(),
    this.canFlee = false,
    this.canCapture = false,
    this.isTrainerBattle = false,
    List<PsdkBattleCombatantSetup> playerReserves =
        const <PsdkBattleCombatantSetup>[],
    List<PsdkBattleCombatantSetup> opponentReserves =
        const <PsdkBattleCombatantSetup>[],
  })  : combatants =
            Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup>.unmodifiable(
          <PsdkBattleSlotRef, PsdkBattleCombatantSetup>{
            psdkPlayerSlot: player,
            psdkOpponentSlot: opponent,
          },
        ),
        parties = Map<int, List<PsdkBattleCombatantSetup>>.unmodifiable(
          <int, List<PsdkBattleCombatantSetup>>{
            psdkPlayerSlot.bank: List<PsdkBattleCombatantSetup>.unmodifiable(
              <PsdkBattleCombatantSetup>[player, ...playerReserves],
            ),
            psdkOpponentSlot.bank: List<PsdkBattleCombatantSetup>.unmodifiable(
              <PsdkBattleCombatantSetup>[opponent, ...opponentReserves],
            ),
          },
        ),
        isSingles = true {
    ruleset.requireSupported();
    if (isTrainerBattle && canCapture) {
      throw ArgumentError(
        'A trainer battle cannot expose a capture decision.',
      );
    }
    if (canCapture) {
      final catchRate = opponent.catchRate;
      if (catchRate == null || catchRate < 1 || catchRate > 255) {
        throw ArgumentError.value(
          catchRate,
          'opponent.catchRate',
          'Capture-enabled wild battles require a catchRate within 1..255.',
        );
      }
    }
  }

  PsdkBattleSetup.doubles({
    required this.ruleset,
    required List<PsdkBattleCombatantSetup> player,
    required List<PsdkBattleCombatantSetup> opponent,
    required this.rngSeeds,
    this.field = const PsdkBattleFieldState(),
    List<PsdkBattleCombatantSetup> playerReserves = const [],
    List<PsdkBattleCombatantSetup> opponentReserves = const [],
  })  : combatants = Map.unmodifiable({
          for (var position = 0; position < player.length; position++)
            PsdkBattleSlotRef(bank: 0, position: position): player[position],
          for (var position = 0; position < opponent.length; position++)
            PsdkBattleSlotRef(bank: 1, position: position): opponent[position],
        }),
        parties = Map.unmodifiable({
          0: List<PsdkBattleCombatantSetup>.unmodifiable(
              [...player, ...playerReserves]),
          1: List<PsdkBattleCombatantSetup>.unmodifiable(
              [...opponent, ...opponentReserves]),
        }),
        isSingles = false,
        isTrainerBattle = true,
        canCapture = false,
        canFlee = false {
    ruleset.requireSupported();
    PokemonBattleRules.fromProfile(ruleset)
        .requireFeatureEnabled(PokemonDisabledFeature.doubleBattles);
    _validateDoublesParty(player, playerReserves, 'player');
    _validateDoublesParty(opponent, opponentReserves, 'opponent');
  }

  final Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup> combatants;
  final PokemonRulesetProfile ruleset;
  final Map<int, List<PsdkBattleCombatantSetup>> parties;
  final PsdkBattleRngSeeds rngSeeds;
  final PsdkBattleFieldState field;
  final bool canFlee;
  final bool canCapture;
  final bool isTrainerBattle;
  final bool isSingles;

  PsdkBattleCombatantSetup get player => combatants[psdkPlayerSlot]!;
  PsdkBattleCombatantSetup get opponent => combatants[psdkOpponentSlot]!;

  List<PsdkBattleCombatantSetup> partyForBank(int bank) {
    return List<PsdkBattleCombatantSetup>.unmodifiable(
      parties[bank] ?? const <PsdkBattleCombatantSetup>[],
    );
  }
}

void _validateDoublesParty(
  List<PsdkBattleCombatantSetup> active,
  List<PsdkBattleCombatantSetup> reserves,
  String name,
) {
  if (active.length != 2 || active.length + reserves.length > 6) {
    throw ArgumentError.value(active.length, name,
        'Doubles require two active battlers and at most six party members.');
  }
  if (active.any((battler) => battler.currentHp <= 0)) {
    throw ArgumentError.value(
        name, 'active', 'Doubles require two conscious active battlers.');
  }
  final ids = <String>{};
  for (final battler in [...active, ...reserves]) {
    if (!ids.add(battler.id)) {
      throw ArgumentError.value(
          battler.id, name, 'Duplicate party combatant identity.');
    }
  }
}
