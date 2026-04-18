import 'battle_state.dart';
import 'battle_topology.dart';

/// Événements observables strictement dédiés au slice H2 Spikes.
///
/// Frontière volontairement dure :
/// - ce fichier n'ouvre pas un framework de hazards ;
/// - il ne sert qu'à rendre `Spikes` visible, testable et honnête ;
/// - il refuse d'anticiper Toxic Spikes, Sticky Web, retrait de hazards,
///   abilities, items ou groundedness générale.
enum BattleSpikesEventKind {
  setLayer,
  alreadyAtMaxLayers,
  damagedOnEntry,
}

/// Trace observable strictement bornée à Spikes.
///
/// Les payloads restent petits et vivants :
/// - `side` pour savoir sur quel côté l'effet existe ;
/// - `layers` pour raconter la pose ou le déclenchement réel ;
/// - `targetSlot` + `damage` seulement quand l'entrée inflige des dégâts.
///
/// H2 retire volontairement `sourceMoveId` de ce contrat :
/// - la pose ne dépend pas d'un runtime/UI qui doit afficher l'ID du move ;
/// - garder ce champ sans consommateur réel violerait la règle de non-champ
///   mort du lot ;
/// - si un futur lot en a réellement besoin, il devra le rouvrir
///   explicitement.
final class BattleSpikesEvent {
  const BattleSpikesEvent.setLayer({
    required this.side,
    required this.layers,
  })  : kind = BattleSpikesEventKind.setLayer,
        targetSlot = null,
        damage = null;

  const BattleSpikesEvent.alreadyAtMaxLayers({
    required this.side,
    required this.layers,
  })  : kind = BattleSpikesEventKind.alreadyAtMaxLayers,
        targetSlot = null,
        damage = null;

  const BattleSpikesEvent.damagedOnEntry({
    required this.side,
    required this.targetSlot,
    required this.damage,
    required this.layers,
  }) : kind = BattleSpikesEventKind.damagedOnEntry;

  final BattleSideId side;
  final BattleSpikesEventKind kind;
  final BattleSlotRef? targetSlot;
  final int? damage;
  final int layers;
}

/// Définition locale et strictement bornée de "grounded" pour H2.
///
/// Règle volontairement petite :
/// - si le Pokémon a le type Flying, il n'est pas grounded ;
/// - sinon il l'est ;
/// - si le typing est absent, on le traite comme grounded.
///
/// Ce helper refuse explicitement d'ouvrir :
/// - Levitate ;
/// - Air Balloon ;
/// - Magnet Rise ;
/// - Gravity ;
/// - items/abilities ;
/// - toute généralisation réutilisable "pour plus tard".
bool isGroundedForSpikesEntry(BattleCombatant combatant) {
  final typing = combatant.typing;
  if (typing == null) {
    return true;
  }
  return !typing.hasType('flying');
}

/// Calcule les dégâts d'entrée de Spikes pour un combattant donné.
///
/// Vérité H2 explicitement bornée :
/// - 1 couche => `floor(maxHp / 8)` ;
/// - 2 couches => `floor(maxHp / 6)` ;
/// - 3 couches => `floor(maxHp / 4)` ;
/// - minimum 1 si l'effet s'applique ;
/// - 0 si le combattant n'est pas grounded.
int resolveSpikesEntryDamage({
  required BattleCombatant combatant,
  required int layers,
}) {
  if (layers <= 0) {
    return 0;
  }
  if (!isGroundedForSpikesEntry(combatant)) {
    return 0;
  }

  final denominator = switch (layers) {
    1 => 8,
    2 => 6,
    _ => 4,
  };
  final scaledDamage = (combatant.maxHp / denominator).floor();
  return scaledDamage < 1 ? 1 : scaledDamage;
}
