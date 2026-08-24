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

/// Bandes noires entrelacées qui envahissent l'écran — BETA-BAT-019.
///
/// L'adaptation sans shader de `RSWild`/`DPPWild` : la référence découpe la
/// capture d'écran en lignes alternées qui glissent hors champ (0,7 s) en
/// révélant le noir. Notre overlay vit PAR-DESSUS la carte encore rendue :
/// l'effet inverse est visuellement équivalent — les bandes paires entrent
/// par la gauche, les impaires par la droite, jusqu'au noir complet.
final class TransitionInterleavedBandsPhase extends BattleTransitionPhase {
  const TransitionInterleavedBandsPhase({
    required this.durationSeconds,
    this.bandHeight = 3,
  });

  @override
  final double durationSeconds;

  /// Hauteur d'une bande en pixels logiques. La référence masque des lignes
  /// de texture d'un pixel ; à nos résolutions, 3 px gardent le peigne fin
  /// sans scintiller.
  final double bandHeight;
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

/// Les phases communes aux sauvages à planche — recontrôlées à l'oracle le
/// 2026-08-24 : `create_pre_transition_animation` de `100 RBYWild.rb` porte
/// le flash (1,5 s facteur 6) et le noir tenu (0,25 s) pour TOUS ses
/// héritiers ; seuls la planche et son tempo changent
/// (`pre_transition_cells_duration`).
BattleTransitionSpec _wildSheetTransition({
  required String id,
  required String sheetName,
  required double cellsDurationSeconds,
}) {
  return BattleTransitionSpec(
    id: id,
    phases: <BattleTransitionPhase>[
      const TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
      TransitionSheetCellsPhase(
        sheetName: sheetName,
        columns: 10,
        rows: 3,
        durationSeconds: cellsDurationSeconds,
      ),
      const TransitionHoldBlackPhase(durationSeconds: 0.25),
    ],
  );
}

/// La transition sauvage Or — `110 GSCWild.rb` : planche `gold_wild` en 1 s.
final battleTransitionGoldWild = _wildSheetTransition(
  id: 'gold_wild',
  sheetName: 'gold_wild',
  cellsDurationSeconds: 1,
);

/// La transition sauvage Cristal — `110 GSCWild.rb` : planche
/// `crystal_wild` au tempo hérité de RBY (0,5 s).
final battleTransitionCrystalWild = _wildSheetTransition(
  id: 'crystal_wild',
  sheetName: 'crystal_wild',
  cellsDurationSeconds: 0.5,
);

/// La transition sauvage HeartGold/SoulSilver — `150 HGSSWild.rb` : planche
/// `heartgold_soulsilver_wild` en 1,5 s.
final battleTransitionHgssWild = _wildSheetTransition(
  id: 'hgss_wild',
  sheetName: 'heartgold_soulsilver_wild',
  cellsDurationSeconds: 1.5,
);

/// La transition grotte HeartGold/SoulSilver — `151 HGSSCave.rb` : planche
/// `heartgold_soulsilver_cave_wild` en 1,5 s.
final battleTransitionHgssCave = _wildSheetTransition(
  id: 'hgss_cave',
  sheetName: 'heartgold_soulsilver_cave_wild',
  cellsDurationSeconds: 1.5,
);

/// La transition sauvage Rubis/Saphir — `120 RSWild.rb` : flash hérité de
/// RBY puis les lignes de l'écran glissent hors champ en 0,7 s (adaptées en
/// bandes entrelacées, voir [TransitionInterleavedBandsPhase]), noir tenu.
const battleTransitionRsWild = BattleTransitionSpec(
  id: 'rs_wild',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionInterleavedBandsPhase(durationSeconds: 0.7),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition sauvage Diamant/Perle — `140 DPPWild.rb` : la même
/// mécanique que Rubis/Saphir (seul le shader de découpe diffère dans la
/// référence, invisible dans notre adaptation) sous son propre id
/// d'authoring.
const battleTransitionDppWild = BattleTransitionSpec(
  id: 'dpp_wild',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionInterleavedBandsPhase(durationSeconds: 0.7),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition dresseur HeartGold/SoulSilver — `154 HGSSTrainer.rb` :
/// toute la séquence Diamant/Perle/Platine avec les deux planches HGSS.
const battleTransitionHgssTrainer = BattleTransitionSpec(
  id: 'hgss_trainer',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 0.7, factor: 2),
    TransitionSpriteZoomPhase(durationSeconds: 0.4, zoomFrom: 0.2),
    TransitionSpriteAnglePhase(
      durationSeconds: 0.4,
      angleFromDegrees: 90,
      angleToDegrees: -360,
    ),
    TransitionSheetCellsPhase(
      sheetName: 'heartgold_soulsilver_trainer_01',
      columns: 3,
      rows: 4,
      durationSeconds: 0.2,
    ),
    TransitionSheetCellsPhase(
      sheetName: 'heartgold_soulsilver_trainer_02',
      columns: 3,
      rows: 4,
      durationSeconds: 0.2,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// Le registre moteur des transitions connues — BETA-BAT-019.
///
/// Le panel portable sans shader de la référence. Les transitions à
/// FragmentShader (RBY/RS dresseur, grottes RS/DPP, mers, Noir/Blanc, XY,
/// champions d'arène, Red, Team Rocket, Zone de Combat) restent à porter
/// dans un lot « shaders » dédié.
final Map<String, BattleTransitionSpec> battleTransitionRegistry =
    <String, BattleTransitionSpec>{
  'rby_wild': battleTransitionRbyWild,
  'gold_wild': battleTransitionGoldWild,
  'crystal_wild': battleTransitionCrystalWild,
  'hgss_wild': battleTransitionHgssWild,
  'hgss_cave': battleTransitionHgssCave,
  'rs_wild': battleTransitionRsWild,
  'dpp_wild': battleTransitionDppWild,
  'dpp_trainer': battleTransitionDppTrainer,
  'hgss_trainer': battleTransitionHgssTrainer,
};

/// Les transitions proposables pour une rencontre SAUVAGE, dans l'ordre du
/// panel d'authoring.
const List<String> battleWildTransitionIds = <String>[
  'rby_wild',
  'gold_wild',
  'crystal_wild',
  'hgss_wild',
  'hgss_cave',
  'rs_wild',
  'dpp_wild',
];

/// Les transitions proposables pour un combat DRESSEUR, dans l'ordre du
/// panel d'authoring.
const List<String> battleTrainerTransitionIds = <String>[
  'dpp_trainer',
  'hgss_trainer',
];

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
