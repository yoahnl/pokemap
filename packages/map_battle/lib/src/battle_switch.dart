import 'battle_topology.dart';

/// Petite taxonomie des événements de switch/réserve visibles dans un tour.
///
/// BE10 reste volontairement très borné :
/// - pas de pipeline générique de selfSwitch / forceSwitch ;
/// - pas de journal universel ;
/// - seulement ce qu'il faut pour ne pas muter les actifs/réserves en silence.
enum BattleSwitchEventKind {
  switched,
  replacementRequired,
}

/// Trace minimale d'un switch ou d'un remplacement forcé.
///
/// Ce contrat sépare volontairement les événements de roster des :
/// - `BattleStatusEvent` (statuts majeurs) ;
/// - `BattleVolatileEvent` (protect/recharge/charge) ;
/// - `BattleFieldEvent` (weather/pseudoWeather).
///
/// Cela garde chaque couche lisible et évite de transformer `BattleTurnResult`
/// en sac de booléens croisés.
final class BattleSwitchEvent {
  const BattleSwitchEvent.switched({
    required this.side,
    required this.fromSpeciesId,
    required this.toSpeciesId,
    required this.wasForced,
    this.slotIndex = 0,
  }) : kind = BattleSwitchEventKind.switched;

  const BattleSwitchEvent.replacementRequired({
    required this.side,
    required this.fromSpeciesId,
    this.slotIndex = 0,
  })  : kind = BattleSwitchEventKind.replacementRequired,
        toSpeciesId = null,
        wasForced = true;

  /// Side concerné par le switch ou la demande de remplacement.
  final BattleSideId side;
  final int slotIndex;

  final BattleSwitchEventKind kind;

  /// Espèce qui quitte le terrain.
  ///
  /// Sur `replacementRequired`, c'est l'espèce K.O. que le joueur doit
  /// remplacer avant de pouvoir reprendre un tour normal.
  final String fromSpeciesId;

  /// Espèce qui entre sur le terrain quand un switch a réellement eu lieu.
  final String? toSpeciesId;

  /// `true` pour un remplacement contraint par un K.O., `false` pour un
  /// switch volontaire du joueur.
  final bool wasForced;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Phase D fait migrer l'événement vers un vrai side, mais certaines traces
  /// runtime/tests lisent encore `"player"` / `"enemy"`.
  String get actor => side.actorId;

  /// Slot concerné par l'événement.
  BattleSlotRef get slot => BattleSlotRef(side: side, slotIndex: slotIndex);
}
