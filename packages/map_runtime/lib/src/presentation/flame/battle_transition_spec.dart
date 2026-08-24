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

/// Le terrain d'où sort le Pokémon sauvage — BETA-BAT-032.
///
/// Recette du 2026-08-24 : « il y a la transition, mais aussi une belle
/// animation avec des herbes etc… enfin ça dépend du type de terrain ».
/// Observé dans la vidéo de référence (Pokémon Platine) : après le noir, des
/// brins d'herbe remplissent l'écran et se dispersent avant que la scène
/// n'apparaisse.
///
/// Aucune planche de balayage plein écran n'existe dans les assets, et PSDK
/// n'a pas cette animation (c'est une spécificité DS) : la phase est donc
/// dessinée, paramétrée par le terrain.
enum BattleTerrainSweepKind {
  /// Brins d'herbe qui montent et se dispersent — hautes herbes, forêt.
  grass,

  /// Gerbes d'eau — surf et pêche.
  water,

  /// Poussière et éclats de roche — grotte.
  dust,
}

final class TransitionTerrainSweepPhase extends BattleTransitionPhase {
  const TransitionTerrainSweepPhase({
    required this.kind,
    this.durationSeconds = 0.65,
  });

  final BattleTerrainSweepKind kind;

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

/// Le threshold dissolve des pré-transitions à shader — BETA-BAT-019.
///
/// La parité des `black_to_white.frag` / `rbytrainer.frag` de la référence :
/// une texture de seuil plein écran, et chaque pixel devient noir opaque
/// quand son seuil (canal rouge, plus vert/256 en précision fine) passe sous
/// `t` — qui parcourt [tFrom, tTo] sur la durée. Le rideau spiral du dresseur
/// RBY, les dissolves Rubis/Saphir et de la Zone de Combat en découlent.
/// Sans FragmentShader chargeable, l'overlay retombe sur un fondu noir
/// simple : l'entrée en combat ne casse jamais.
final class TransitionThresholdDissolvePhase extends BattleTransitionPhase {
  const TransitionThresholdDissolvePhase({
    required this.textureName,
    required this.durationSeconds,
    this.tFrom = 0,
    this.tTo = 1,
    this.fineThreshold = false,
  });

  final String textureName;
  @override
  final double durationSeconds;
  final double tFrom;
  final double tTo;

  /// `true` = seuil 16 bits (rouge + vert/256), la précision du rideau RBY.
  final bool fineThreshold;
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

  /// La même transition, suivie d'un balayage de terrain — BETA-BAT-032.
  ///
  /// La phase est ajoutée à la spec RÉSOLUE et jamais au registre : les 15
  /// transitions de BETA-BAT-019 gardent leur définition et leurs tests
  /// pixel au bit près.
  BattleTransitionSpec withTerrainSweep(BattleTerrainSweepKind kind) {
    return BattleTransitionSpec(
      id: '$id+${kind.name}',
      phases: List<BattleTransitionPhase>.unmodifiable(
        <BattleTransitionPhase>[
          ...phases,
          TransitionTerrainSweepPhase(kind: kind),
        ],
      ),
    );
  }
}

/// Le terrain d'une rencontre sauvage, ou null quand rien ne le justifie —
/// BETA-BAT-032.
///
/// La donnée réelle porte deux signaux : COMMENT la rencontre s'est produite
/// (`EncounterKind` : à pied, en surf, à la canne) et OÙ (`mapType`). L'eau
/// gagne sur le lieu — on pêche depuis une berge — puis la grotte, puis
/// l'herbe par défaut d'une rencontre à pied.
///
/// Un combat de dresseur n'en a pas : il ne sort de nulle part.
BattleTerrainSweepKind? resolveBattleTerrainSweepKind({
  required BattleStartRequest request,
  MapData? map,
}) {
  if (request is! WildBattleStartRequest) return null;
  switch (request.encounterKind) {
    case EncounterKind.surf:
    case EncounterKind.oldRod:
    case EncounterKind.goodRod:
    case EncounterKind.superRod:
      return BattleTerrainSweepKind.water;
    case EncounterKind.walk:
    case EncounterKind.headbutt:
      break;
    case EncounterKind.gift:
    case EncounterKind.special:
      // Une rencontre scriptée n'est pas une rencontre de terrain.
      return null;
  }
  return switch (map?.mapMetadata.mapType) {
    MapType.cave => BattleTerrainSweepKind.dust,
    _ => BattleTerrainSweepKind.grass,
  };
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

/// La transition dresseur Rouge/Bleu/Jaune — `100 RBYTrainer.rb` : le rideau
/// spiral, un dissolve fin (seuil 16 bits) de 2,75 s sans flash, noir tenu.
const battleTransitionRbyTrainer = BattleTransitionSpec(
  id: 'rby_trainer',
  phases: <BattleTransitionPhase>[
    TransitionThresholdDissolvePhase(
      textureName: 'rby_trainer',
      durationSeconds: 2.75,
      fineThreshold: true,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition dresseur Rubis/Saphir — `124 RSTrainer.rb` : flash RBY puis
/// dissolve `ruby_saphir_trainer` en 1 s, noir tenu.
const battleTransitionRsTrainer = BattleTransitionSpec(
  id: 'rs_trainer',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionThresholdDissolvePhase(
      textureName: 'ruby_saphir_trainer',
      durationSeconds: 1,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition grotte Rubis/Saphir — `121 RSCave.rb` : flash hérité de RBY
/// puis dissolve `ruby_saphir_wild` en 1 s, noir tenu.
const battleTransitionRsCave = BattleTransitionSpec(
  id: 'rs_cave',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionThresholdDissolvePhase(
      textureName: 'ruby_saphir_wild',
      durationSeconds: 1,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La transition grotte Diamant/Perle — `141 DPPCave.rb` : le même dissolve
/// avec sa texture (le zoom ×3 de la capture d'écran de la référence n'a pas
/// d'équivalent sans capture — adaptation assumée).
const battleTransitionDppCave = BattleTransitionSpec(
  id: 'dpp_cave',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionThresholdDissolvePhase(
      textureName: 'diamant_perle_wild',
      durationSeconds: 1,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La Zone de Combat, rideau vertical — `300 BattleFrontier.rb` (hérite du
/// dresseur Rubis/Saphir avec sa texture).
const battleTransitionBattleFrontierVertical = BattleTransitionSpec(
  id: 'battle_frontier_v',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionThresholdDissolvePhase(
      textureName: 'battle_frontier_vertical',
      durationSeconds: 1,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// La Zone de Combat, rideau horizontal — `300 BattleFrontier.rb`.
const battleTransitionBattleFrontierHorizontal = BattleTransitionSpec(
  id: 'battle_frontier_h',
  phases: <BattleTransitionPhase>[
    TransitionFlashPhase(durationSeconds: 1.5, factor: 6),
    TransitionThresholdDissolvePhase(
      textureName: 'battle_frontier_horizontal',
      durationSeconds: 1,
    ),
    TransitionHoldBlackPhase(durationSeconds: 0.25),
  ],
);

/// Le registre moteur des transitions connues — BETA-BAT-019.
///
/// Le panel de la référence : les neuf sans shader, plus les six dissolves
/// du lot shaders (rideau RBY dresseur, Rubis/Saphir dresseur et grotte,
/// grotte Diamant/Perle, Zone de Combat V/H). Restent hors périmètre les
/// transitions qui déforment la capture d'écran (mers, Noir/Blanc) et
/// celles à images par dresseur (XY, champions d'arène, Red, Team Rocket).
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
  'rby_trainer': battleTransitionRbyTrainer,
  'rs_trainer': battleTransitionRsTrainer,
  'rs_cave': battleTransitionRsCave,
  'dpp_cave': battleTransitionDppCave,
  'battle_frontier_v': battleTransitionBattleFrontierVertical,
  'battle_frontier_h': battleTransitionBattleFrontierHorizontal,
};

/// Résout la transition d'une requête de combat — BETA-BAT-016.
///
/// Choisie par la donnée (`ProjectBattleTransitionConfig`), avec un défaut
/// distinct par type et un repli sûr : un id inconnu ou vide retombe sur le
/// défaut du type, comme les registres `.default` de la référence.
BattleTransitionSpec resolveBattleTransitionSpec({
  required BattleStartRequest request,
  required ProjectManifest manifest,
  MapData? map,
}) {
  final isTrainerBattle = request is TrainerBattleStartRequest ||
      request is StaticBattleStartRequest;

  // BETA-BAT-019 : le dresseur d'abord — sa transition authorée gagne sur
  // tout, comme les registres TRAINER_TRANSITIONS de la référence.
  if (request is TrainerBattleStartRequest) {
    final trainerId = request.trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id != trainerId) continue;
      final authored = trainer.battleTransitionId?.trim() ?? '';
      final spec = battleTransitionRegistry[authored];
      if (spec != null) return spec;
      break;
    }
  }

  // BETA-BAT-019 : la ZONE (ou le calque Smart Tile) qui a déclenché la
  // rencontre sauvage peut porter PLUSIEURS transitions — le runtime en tire
  // une, déterministe par requête (le même requestId rejoue la même), donc
  // testable et rejouable. Les ids inconnus sont ignorés sans bruit.
  if (map != null && request is WildBattleStartRequest) {
    final source = findEncounterSource(
      map,
      kind: request.encounterSourceKind,
      id: request.encounterSourceId,
    );
    final authoredIds =
        (source?.encounter.battleTransitionIds ?? const <String>[])
            .map((id) => id.trim())
            .where(battleTransitionRegistry.containsKey)
            .toList(growable: false);
    if (authoredIds.isNotEmpty) {
      final index = _stableRequestHash(request.requestId) % authoredIds.length;
      return battleTransitionRegistry[authoredIds[index]]!;
    }
  }

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

/// La transition à jouer, balayage de terrain compris — BETA-BAT-032.
///
/// Séparé de [resolveBattleTransitionSpec], qui ne fait qu'un choix parmi le
/// registre : le contrat de ce choix est verrouillé par les tests de
/// BETA-BAT-019, et la composition du terrain est une étape distincte.
BattleTransitionSpec resolveBattleTransitionSpecWithTerrain({
  required BattleStartRequest request,
  required ProjectManifest manifest,
  MapData? map,
}) {
  final spec = resolveBattleTransitionSpec(
    request: request,
    manifest: manifest,
    map: map,
  );
  final terrain = resolveBattleTerrainSweepKind(request: request, map: map);
  return terrain == null ? spec : spec.withTerrainSweep(terrain);
}

/// FNV-1a sur le requestId : stable entre exécutions et plateformes, là où
/// `String.hashCode` ne le garantit pas — le tirage d'une transition doit se
/// rejouer à l'identique dans un test comme dans une partie chargée.
int _stableRequestHash(String requestId) {
  var hash = 0x811c9dc5;
  for (final unit in requestId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
