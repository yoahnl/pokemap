import 'battle_state.dart';
import 'battle_topology.dart';
import 'battle_type_chart.dart';

/// Événements observables strictement dédiés à Stealth Rock.
///
/// Frontière H1 volontairement dure :
/// - ce fichier n'ouvre pas un système générique de side conditions ;
/// - il ne sert qu'à rendre Stealth Rock visible et testable ;
/// - il refuse d'anticiper Spikes, Toxic Spikes, Boots, Defog, etc.
enum BattleStealthRockEventKind {
  set,
  alreadyPresent,
  damagedOnEntry,
}

/// Trace observable strictement bornée au premier slice Stealth Rock.
final class BattleStealthRockEvent {
  const BattleStealthRockEvent.set({
    required this.side,
    required this.sourceMoveId,
  })  : kind = BattleStealthRockEventKind.set,
        targetSlot = null,
        damage = null;

  const BattleStealthRockEvent.alreadyPresent({
    required this.side,
    required this.sourceMoveId,
  })  : kind = BattleStealthRockEventKind.alreadyPresent,
        targetSlot = null,
        damage = null;

  const BattleStealthRockEvent.damagedOnEntry({
    required this.side,
    required this.targetSlot,
    required this.damage,
  })  : kind = BattleStealthRockEventKind.damagedOnEntry,
        sourceMoveId = null;

  final BattleSideId side;
  final BattleStealthRockEventKind kind;
  final String? sourceMoveId;
  final BattleSlotRef? targetSlot;
  final int? damage;
}

/// Calcule les dégâts d'entrée de Stealth Rock pour un combattant.
///
/// Vérité H1 explicitement alignée sur la mécanique Showdown-like lue dans le
/// dépôt de référence :
/// - base 1/8 des PV max ;
/// - multipliée par l'efficacité du type Roche contre le typing entrant ;
/// - puis tronquée avec un minimum de 1 si l'effet est non nul.
int resolveStealthRockEntryDamage(BattleCombatant combatant) {
  final typeMultiplier = BattleTypeChart.resolveEffectivenessMultiplier(
    moveType: 'rock',
    defenderTyping: combatant.typing,
  );
  if (typeMultiplier <= 0) {
    return 0;
  }

  final scaledDamage = (combatant.maxHp * typeMultiplier / 8).floor();
  return scaledDamage < 1 ? 1 : scaledDamage;
}
