import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';

/// Une phase de la pré-transition — BETA-BAT-016.
///
/// La séquence est une liste ordonnée de phases, exécutée par l'overlay de
/// pré-transition. C'est la projection Dart de l'arbre `Yuki::Animation` de
/// la référence : chaque phase a une durée et un effet unique, et la somme
/// des phases reproduit `create_pre_transition_animation` de la transition
/// choisie.
sealed class BattleTransitionPhase {
  const BattleTransitionPhase();

  double get durationSeconds;
}

/// Flash sinusoïdal de l'écran (parité `create_flash_animation`) :
/// blanc quand sin(x) > 0, alpha = sin²(x) × 180, x parcourt 0 → factor·π.
final class TransitionFlashPhase extends BattleTransitionPhase {
  const TransitionFlashPhase({
    required this.durationSeconds,
    required this.factor,
  });

  @override
  final double durationSeconds;
  final double factor;
}

/// Zoom du sprite de planche (la pokéball DPP qui grossit).
final class TransitionSpriteZoomPhase extends BattleTransitionPhase {
  const TransitionSpriteZoomPhase({
    required this.durationSeconds,
    required this.zoomFrom,
  });

  @override
  final double durationSeconds;

  /// Zoom de départ, relatif au zoom « plein cadre » (1 = pleine taille).
  final double zoomFrom;
}

/// Rotation du sprite de planche (la pokéball DPP qui tourne).
final class TransitionSpriteAnglePhase extends BattleTransitionPhase {
  const TransitionSpriteAnglePhase({
    required this.durationSeconds,
    required this.angleFromDegrees,
    required this.angleToDegrees,
  });

  @override
  final double durationSeconds;
  final double angleFromDegrees;
  final double angleToDegrees;
}

/// Défilement des cellules d'une planche, dans l'ordre ligne par ligne.
final class TransitionSheetCellsPhase extends BattleTransitionPhase {
  const TransitionSheetCellsPhase({
    required this.sheetName,
    required this.columns,
    required this.rows,
    required this.durationSeconds,
  });

  final String sheetName;
  final int columns;
  final int rows;
  @override
  final double durationSeconds;
}

/// Écran noir opaque tenu (la fin canonique de toute pré-transition).
final class TransitionHoldBlackPhase extends BattleTransitionPhase {
  const TransitionHoldBlackPhase({required this.durationSeconds});

  @override
  final double durationSeconds;
}

/// Fondu progressif transparent → noir — BETA-BAT-017.
///
/// La sortie de combat de la référence : l'écran fond au noir depuis la
/// scène encore affichée, puis le noir est tenu pendant que l'overworld se
/// remonte dessous. Alpha linéaire 0 → 255 sur la durée.
final class TransitionFadeToBlackPhase extends BattleTransitionPhase {
  const TransitionFadeToBlackPhase({required this.durationSeconds});

  @override
  final double durationSeconds;
}

/// Une transition de début de combat complète. Les planches sont toujours
/// ajustées à la largeur du viewport et centrées — c'est le cadrage commun de
/// RBYWild (étirée plein écran) et de DPPTrainer (pokéball centrée).
final class BattleTransitionSpec {
  const BattleTransitionSpec({
    required this.id,
    required this.phases,
  });

  final String id;
  final List<BattleTransitionPhase> phases;

  double get totalSeconds =>
      phases.fold(0, (sum, phase) => sum + phase.durationSeconds);
}

/// La transition sauvage RBY — recontrôlée sur `100 RBYWild.rb` le
/// 2026-08-23 : flash 1,5 s facteur 6 (trois flashs blancs), planche 10×3
/// étirée plein écran sur 0,5 s, noir tenu 0,25 s.
const battleTransitionRbyWild = BattleTransitionSpec(
  id: 'rby_wild',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionSheetCellsPhase(
      sheetName: 'rby_wild',
      columns: 10,
      rows: 3,
      durationSeconds: 0.5,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition dresseur Diamant/Perle/Platine — recontrôlée sur
/// `144 DPPTrainer.rb` le 2026-08-23 : flash 0,7 s facteur 2, pokéball 3×4
/// centrée qui zoome (0,2 → plein cadre, 0,4 s) puis tourne (90° → -360°,
/// 0,4 s), puis les deux planches défilent (0,2 s chacune), noir tenu 0,25 s.
const battleTransitionDppTrainer = BattleTransitionSpec(
  id: 'dpp_trainer',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 0.7, factor: 2),
    TransitionSpriteZoomPhase(durationSeconds: 0.4, zoomFrom: 0.2),
    TransitionSpriteAnglePhase(
      durationSeconds: 0.4,
      angleFromDegrees: 90,
      angleToDegrees: -360,
    ),
    TransitionSheetCellsPhase(
      sheetName: 'diamant_perle_trainer_01',
      columns: 3,
      rows: 4,
      durationSeconds: 0.2,
    ),
    TransitionSheetCellsPhase(
      sheetName: 'diamant_perle_trainer_02',
      columns: 3,
      rows: 4,
      durationSeconds: 0.2,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La sortie de combat — BETA-BAT-017. Jouée par le même overlay que les
/// pré-transitions : fondu au noir par-dessus la scène de combat, noir tenu,
/// puis le jeu commit l'état, démonte le combat et demande le reveal sur
/// l'overworld. Hors registre : ce n'est pas un choix d'authoring.
const battleExitFade = BattleTransitionSpec(
  id: 'battle_exit_fade',
  phases: <BattleTransitionPhase>[
    TransitionFadeToBlackPhase(durationSeconds: 0.45),
    TransitionHoldBlackPhase(durationSeconds: 0.05),
  ],
);

/// Le registre moteur des transitions connues.
const Map<String, BattleTransitionSpec> battleTransitionRegistry =
    <String, BattleTransitionSpec>{
  'rby_wild': battleTransitionRbyWild,
  'dpp_trainer': battleTransitionDppTrainer,
};

/// Résout la transition d'une requête de combat — BETA-BAT-016.
///
/// Choisie par la donnée (`ProjectBattleTransitionConfig`), avec un défaut
/// distinct par type et un repli sûr : un id inconnu ou vide retombe sur le
/// défaut du type, comme les registres `.default` de la référence.
BattleTransitionSpec resolveBattleTransitionSpec({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  final isTrainerBattle = request is TrainerBattleStartRequest ||
      request is StaticBattleStartRequest;
  final config = manifest.battleTransitions;
  final requestedId =
      (isTrainerBattle ? config?.trainerTransitionId : config?.wildTransitionId)
          ?.trim();
  final fallback =
      isTrainerBattle ? battleTransitionDppTrainer : battleTransitionRbyWild;
  if (requestedId == null || requestedId.isEmpty) {
    return fallback;
  }
  return battleTransitionRegistry[requestedId] ?? fallback;
}
