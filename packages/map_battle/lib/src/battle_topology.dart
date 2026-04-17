/// Identité locale des deux côtés d'un combat singles.
///
/// Phase D n'ouvre toujours pas une topologie Showdown complète :
/// - il n'existe que deux côtés ;
/// - chacun ne porte qu'un seul slot actif ;
/// - mais on arrête de faire comme si tout le moteur n'était qu'un couple
///   `player/enemy` plat sans vraie identité de side.
enum BattleSideId {
  player,
  enemy,
}

/// Petit helper de compatibilité pour les surfaces encore stringly-typed.
///
/// On le garde parce que :
/// - plusieurs traces moteur/runtime utilisent encore `"player"` / `"enemy"` ;
/// - Phase D ne doit pas élargir artificiellement le périmètre aux autres
///   contrats d'événements qui n'ont pas besoin de migrer aujourd'hui ;
/// - les nouveaux contrats topologiques peuvent néanmoins s'appuyer sur
///   [BattleSideId] sans casser toute la surface en une fois.
extension BattleSideIdActorId on BattleSideId {
  String get actorId => switch (this) {
        BattleSideId.player => 'player',
        BattleSideId.enemy => 'enemy',
      };
}

/// Référence explicite à un slot battle local.
///
/// Phase D garde ce contrat volontairement minimal :
/// - en singles, le seul slot réellement résolu aujourd'hui est le slot actif
///   `0` de chaque side ;
/// - cette référence existe pourtant déjà car les requests et les événements
///   de switch doivent maintenant se rattacher à une topologie honnête ;
/// - on n'ouvre pas pour autant une grille de slots multi-actifs.
final class BattleSlotRef {
  const BattleSlotRef({
    required this.side,
    required this.slotIndex,
  });

  const BattleSlotRef.active(this.side) : slotIndex = 0;

  final BattleSideId side;
  final int slotIndex;

  @override
  bool operator ==(Object other) {
    return other is BattleSlotRef &&
        other.side == side &&
        other.slotIndex == slotIndex;
  }

  @override
  int get hashCode => Object.hash(side, slotIndex);

  @override
  String toString() {
    return 'BattleSlotRef(side: ${side.name}, slotIndex: $slotIndex)';
  }
}
