import '../../battle_move.dart';
import '../../battle_setup.dart';
import '../../psdk/domain/psdk_battle_move.dart';

const canonicalStruggleMoveId = 'struggle';
const canonicalStruggleMoveName = 'Struggle';

/// Reserved action slot used only while executing the synthetic fallback.
///
/// Real moves always keep their authored `0..n-1` slots. This value must never
/// be written back to a party member or exposed as an authored move index.
const canonicalStruggleMoveSlot = -1;

/// Legacy presentation projection used by the runtime command menu.
///
/// The one synthetic PP makes the existing read-only legacy menu consider the
/// row selectable. The canonical PSDK runner never spends or persists it.
const canonicalLegacyStruggleMoveData = BattleMoveData(
  id: canonicalStruggleMoveId,
  name: canonicalStruggleMoveName,
  power: 50,
  type: 'unknown',
  category: BattleMoveCategory.physical,
  target: BattleMoveTarget.opponent,
  accuracy: BattleMoveAccuracy.alwaysHits(),
  pp: 1,
  currentPp: 1,
);

const canonicalLegacyStruggleMove = BattleMove(
  id: canonicalStruggleMoveId,
  name: canonicalStruggleMoveName,
  power: 50,
  type: 'unknown',
  category: BattleMoveCategory.physical,
  target: BattleMoveTarget.opponent,
  accuracy: BattleMoveAccuracy.alwaysHits(),
  pp: 1,
  currentPp: 1,
);

/// Gen-4+-style PokeMap V0 fallback: typeless power 50, always hit, 1/4 max-HP
/// recoil through the existing `s_struggle` behavior.
PsdkBattleMoveData createCanonicalPsdkStruggleMove() {
  return PsdkBattleMoveData(
    id: canonicalStruggleMoveId,
    dbSymbol: canonicalStruggleMoveId,
    name: canonicalStruggleMoveName,
    type: 'unknown',
    category: PsdkBattleMoveCategory.physical,
    power: 50,
    accuracy: 0,
    pp: 1,
    currentPp: 1,
    priority: 0,
    battleEngineMethod: 's_struggle',
    target: PsdkBattleMoveTarget.adjacentFoe,
    contact: true,
  );
}
