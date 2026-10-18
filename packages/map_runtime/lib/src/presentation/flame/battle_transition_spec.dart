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

const battleExitFade = BattleTransitionSpec(
  id: 'battle_exit_fade',
  phases: <BattleTransitionPhase>[
    TransitionFadeToBlackPhase(durationSeconds: 0.45),
    TransitionHoldBlackPhase(durationSeconds: 0.05),
  ],
);

const battleTransitionDefaultFade = BattleTransitionSpec(
  id: 'default_fade',
  phases: <BattleTransitionPhase>[
    TransitionFadeToBlackPhase(durationSeconds: 0.3),
    TransitionHoldBlackPhase(durationSeconds: 0.05),
  ],
);

BattleTransitionSpec battleTransitionSpecFromDefinition(BattleTransitionDefinition definition) =>
    BattleTransitionSpec(id: definition.id, phases: List.unmodifiable([
      for (final phase in definition.phases) _phaseFromDefinition(phase),
    ]));

BattleTransitionPhase _phaseFromDefinition(BattleTransitionPhaseDefinition phase) {
  final parameters = phase.parameters;
  double number(String key) => (parameters[key] as num).toDouble();
  return switch (phase.effect) {
    BattleTransitionEffect.flash => TransitionFlashPhase(durationSeconds: phase.durationSeconds, factor: number('factor')),
    BattleTransitionEffect.spriteZoom => TransitionSpriteZoomPhase(durationSeconds: phase.durationSeconds, zoomFrom: number('zoomFrom')),
    BattleTransitionEffect.spriteAngle => TransitionSpriteAnglePhase(durationSeconds: phase.durationSeconds, angleFromDegrees: number('angleFromDegrees'), angleToDegrees: number('angleToDegrees')),
    BattleTransitionEffect.sheetCells => TransitionSheetCellsPhase(durationSeconds: phase.durationSeconds, sheetName: parameters['sheetName'] as String, columns: parameters['columns'] as int, rows: parameters['rows'] as int),
    BattleTransitionEffect.holdBlack => TransitionHoldBlackPhase(durationSeconds: phase.durationSeconds),
    BattleTransitionEffect.terrainSweep => TransitionTerrainSweepPhase(durationSeconds: phase.durationSeconds, kind: BattleTerrainSweepKind.values.singleWhere((entry) => entry.name == parameters['terrain'])),
    BattleTransitionEffect.interleavedBands => TransitionInterleavedBandsPhase(durationSeconds: phase.durationSeconds, bandHeight: number('bandHeight')),
    BattleTransitionEffect.thresholdDissolve => TransitionThresholdDissolvePhase(durationSeconds: phase.durationSeconds, textureName: parameters['textureName'] as String, tFrom: number('tFrom'), tTo: number('tTo'), fineThreshold: parameters['fineThreshold'] as bool),
    BattleTransitionEffect.fadeToBlack => TransitionFadeToBlackPhase(durationSeconds: phase.durationSeconds),
  };
}

BattleTransitionSpec resolveBattleTransitionSpec({
  required BattleStartRequest request,
  required ProjectManifest manifest,
  MapData? map,
}) {
  final config = manifest.battleTransitions;
  config?.validate();
  final catalog = config?.definitionsById ?? const <String, BattleTransitionDefinition>{};
  final isTrainerBattle = request is TrainerBattleStartRequest || request is StaticBattleStartRequest;
  final usage = isTrainerBattle ? BattleTransitionUsage.trainer : BattleTransitionUsage.wild;

  BattleTransitionSpec resolve(String id) {
    final definition = catalog[id];
    if (definition == null || !definition.usages.contains(usage)) {
      throw FormatException('Battle transition "$id" is not defined for this project and usage.');
    }
    return battleTransitionSpecFromDefinition(definition);
  }

  if (request is TrainerBattleStartRequest) {
    final trainer = manifest.trainers.where((entry) => entry.id == request.trainerId.trim()).firstOrNull;
    final selected = trainer?.battleTransitionId?.trim() ?? '';
    if (selected.isNotEmpty) return resolve(selected);
  }
  if (request is WildBattleStartRequest && (map != null || request.encounterSourceSnapshot != null)) {
    final source = map == null ? null : findEncounterSource(map,
        kind: request.encounterSourceKind, id: request.encounterSourceId);
    final ids = ((request.encounterSourceSnapshot ?? source?.encounter)?.battleTransitionIds ?? const <String>[])
        .map((id) => id.trim()).toList(growable: false);
    if (ids.isNotEmpty) {
      for (final id in ids) { resolve(id); }
      return resolve(ids[_stableRequestHash(request.requestId) % ids.length]);
    }
  }
  final selected = (isTrainerBattle ? config?.trainerTransitionId : config?.wildTransitionId)?.trim() ?? '';
  return selected.isEmpty ? battleTransitionDefaultFade : resolve(selected);
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
