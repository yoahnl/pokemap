// Cutscene Studio — modèle métier d'authoring (blocs, source, document, entrées de flow).
//
// Source de vérité : voir [CutsceneStudioDocument] (flow canonique vs projection `blocks`).
//
// Les fonctions [cutsceneFlowEntriesEqual] et helpers outcome/trim sont ici pour éviter
// un cycle d'import avec cutscene_studio_flow.dart.

import 'package:flutter/foundation.dart';

/// Sentinelle partagée pour les `copyWith` (distinguer « non fourni » de `null`).
const Object cutsceneStudioCopyUnset = Object();

/// Schéma d'authoring porté par le Cutscene Studio v1.
///
/// Ce marqueur est stocké dans `ScenarioAsset.metadata` pour que:
/// - l'éditeur sache qu'un scénario est compatible avec cette UX guidée;
/// - les migrations futures puissent être ciblées proprement;
/// - on reste honnête sur le niveau de support outillé.
/// v2: flow séquentiel + branches (métadonnées JSON + compilation choice/merge).
const String kCutsceneStudioSchemaVersion = 'cutscene_studio_v2';

/// Clé metadata où l'on stocke la version du schéma d'authoring cutscene.
const String kCutsceneStudioSchemaMetadataKey = 'authoring.cutsceneSchema';

/// Arbre d'authoring (palette + canvas) sérialisé pour recharger la même structure.
const String kCutsceneStudioFlowMetadataKey = 'authoring.cutsceneFlow';

/// Action kinds runtime (bridge scénario MVP) supportées par le studio v1.
///
/// NOTE PRODUIT:
/// Ces constantes restent côté authoring pour éviter les chaînes magiques
/// dans l'UI; elles reflètent le contrat runtime existant.
const String kCutsceneStudioActionRunScript = 'runScript';
const String kCutsceneStudioActionOpenDialogue = 'openDialogue';
const String kCutsceneStudioActionShowMessage = 'showMessage';
const String kCutsceneStudioActionSetFlag = 'setFlag';
const String kCutsceneStudioActionClearFlag = 'clearFlag';
const String kCutsceneStudioActionEmitOutcome = 'emitOutcome';
const String kCutsceneStudioActionMoveCharacter = 'moveCharacter';
const String kCutsceneStudioActionFollowCharacter = 'followCharacter';
const String kCutsceneStudioActionFaceCharacter = 'faceCharacter';
const String kCutsceneStudioActionTransitionMap = 'transitionMap';
const String kCutsceneStudioActionStarterChoice = 'starterChoice';
const String kCutsceneStudioActionWaitMs = 'waitMs';

/// Jonction graphe après embranchement — **pas** une attente.
///
/// Doit rester aligné sur [kScenarioActionFlowMerge] (`map_runtime`).
const String kCutsceneStudioActionFlowMerge = 'flowMerge';

/// Bloc authoring sans implémentation runtime MVP.
///
/// L’exécuteur avance sans effet gameplay mais avec un message explicite
/// (évite tout `waitMs` à 0 ms qui ferait croire à une vraie pause).
///
/// Doit rester aligné sur [kScenarioActionAuthoringPlaceholder] (`map_runtime`).
const String kCutsceneStudioActionAuthoringPlaceholder =
    'authoringPlaceholder';

/// Métadonnée nœud : kind d’origine pour un placeholder rechargé depuis graphe.
const String kCutsceneStudioPlaceholderKindMetadataKey =
    'studio.placeholderKind';

/// Métadonnée nœud : marqueur structurel studio (fusion, etc.).
const String kCutsceneStudioStructuralMetadataKey = 'studio.structural';

/// Portée "produit" d'un résultat de scène.
///
/// IMPORTANT:
/// Ces valeurs servent uniquement à l'authoring no-code.
/// Le runtime continue de consommer l'outcomeId final généré.
const String kCutsceneStudioResultScopeLocal = 'local';
const String kCutsceneStudioResultScopeProgression = 'progression';
const String kCutsceneStudioResultScopeGlobal = 'global';
const List<String> kCutsceneStudioResultScopes = <String>[
  kCutsceneStudioResultScopeLocal,
  kCutsceneStudioResultScopeProgression,
  kCutsceneStudioResultScopeGlobal,
];

/// Cibles de destination pour un bloc de déplacement.
///
/// Le but est d'offrir un vocabulaire métier (sortie, personnage, spawn...)
/// plutôt que de forcer la saisie manuelle de coordonnées.
const String kCutsceneStudioMoveTargetWarp = 'warp';
const String kCutsceneStudioMoveTargetSpawn = 'spawn';
const String kCutsceneStudioMoveTargetEntity = 'entity';

/// ID acteur « joueur » (studio + runtime) pour la simulation de carte contextuelle.
const String kCutsceneStudioActorPlayerId = 'player';

/// Source hooks monde supportés par le studio v1.
const String kCutsceneStudioSourceMapEnter = 'sourceMapEnter';
const String kCutsceneStudioSourceTriggerEnter = 'sourceTriggerEnter';
const String kCutsceneStudioSourceEntityInteract = 'sourceEntityInteract';

/// Type de déclenchement "humain" présenté dans le studio.
enum CutsceneStudioSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
}

String cutsceneStudioSourceKindLabel(CutsceneStudioSourceKind kind) {
  return switch (kind) {
    CutsceneStudioSourceKind.mapEnter => 'Entrée sur une map',
    CutsceneStudioSourceKind.triggerEnter => 'Entrée dans un trigger',
    CutsceneStudioSourceKind.entityInteract => 'Interaction avec un PNJ',
  };
}

/// Source du flow cutscene (hook monde).
///
/// Pourquoi c'est séparé des blocs:
/// - le hook monde répond au "quand démarre la scène ?";
/// - les blocs répondent au "que fait la scène ensuite ?".
@immutable
class CutsceneStudioSourceConfig {
  const CutsceneStudioSourceConfig({
    required this.kind,
    this.mapId,
    this.triggerId,
    this.entityId,
  });

  final CutsceneStudioSourceKind kind;
  final String? mapId;
  final String? triggerId;
  final String? entityId;

  CutsceneStudioSourceConfig copyWith({
    CutsceneStudioSourceKind? kind,
    Object? mapId = cutsceneStudioCopyUnset,
    Object? triggerId = cutsceneStudioCopyUnset,
    Object? entityId = cutsceneStudioCopyUnset,
  }) {
    return CutsceneStudioSourceConfig(
      kind: kind ?? this.kind,
      mapId: identical(mapId, cutsceneStudioCopyUnset) ? this.mapId : mapId as String?,
      triggerId:
          identical(triggerId, cutsceneStudioCopyUnset) ? this.triggerId : triggerId as String?,
      entityId:
          identical(entityId, cutsceneStudioCopyUnset) ? this.entityId : entityId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CutsceneStudioSourceConfig &&
        other.kind == kind &&
        other.mapId == mapId &&
        other.triggerId == triggerId &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(kind, mapId, triggerId, entityId);
}

/// Bloc d'exécution affiché dans le Cutscene Studio.
///
/// Le v1 reste volontairement petit:
/// - `dialogue`
/// - `runScript`
/// - `setFlag` / `clearFlag`
/// - `emitOutcome`
///
/// Cette contrainte permet de livrer une UX guidée stable sans mentir sur
/// le support runtime actuellement branché.
enum CutsceneStudioBlockKind {
  // Blocs métier no-code (prioritaires dans l’UX principale).
  dialogue,
  narration,
  moveCharacter,
  followCharacter,
  faceCharacter,
  transitionMap,
  starterChoice,
  wait,
  sceneResult,
  // Bloc "script" conservé pour compatibilité/transition (moins no-code).
  runScript,

  // Compatibilité legacy (non exposés dans la palette principale).
  setFlag,
  clearFlag,
  emitOutcome,

  /// Question joueur → compile vers un node `choice` (Oui / Non ou libellés custom).
  playerQuestion,

  /// Variante déplacement « pathfinding » (même action moveCharacter + paramètre).
  pathfindMove,

  /// Stubs produit (compilent en [kCutsceneStudioActionAuthoringPlaceholder]).
  characterAppear,
  characterDisappear,
  cameraCenter,
  cameraTransition,
  callCutscene,
}

String cutsceneStudioBlockKindLabel(CutsceneStudioBlockKind kind) {
  return switch (kind) {
    CutsceneStudioBlockKind.dialogue => 'Faire parler un personnage',
    CutsceneStudioBlockKind.narration => 'Afficher une ligne de narration',
    CutsceneStudioBlockKind.moveCharacter => 'Déplacer un personnage',
    CutsceneStudioBlockKind.followCharacter => 'Le joueur suit un personnage',
    CutsceneStudioBlockKind.faceCharacter => 'Tourner un personnage',
    CutsceneStudioBlockKind.transitionMap => 'Entrer dans un bâtiment / map',
    CutsceneStudioBlockKind.starterChoice => 'Choix du starter',
    CutsceneStudioBlockKind.wait => 'Attendre',
    CutsceneStudioBlockKind.sceneResult => 'Ajouter un résultat de scène',
    CutsceneStudioBlockKind.runScript => 'Lancer une séquence scriptée',
    CutsceneStudioBlockKind.setFlag => 'Activer un flag',
    CutsceneStudioBlockKind.clearFlag => 'Désactiver un flag',
    CutsceneStudioBlockKind.emitOutcome => 'Émettre un outcome (legacy)',
    CutsceneStudioBlockKind.playerQuestion => 'Poser une question',
    CutsceneStudioBlockKind.pathfindMove => 'Déplacer avec pathfinding',
    CutsceneStudioBlockKind.characterAppear => 'Faire apparaître un personnage',
    CutsceneStudioBlockKind.characterDisappear =>
      'Faire disparaître un personnage',
    CutsceneStudioBlockKind.cameraCenter => 'Centrer la caméra sur une cible',
    CutsceneStudioBlockKind.cameraTransition => 'Transition caméra',
    CutsceneStudioBlockKind.callCutscene => 'Appeler une autre cutscene',
  };
}

enum CutsceneStudioBlockCategory {
  dialogue,
  movement,
  transition,
  gameplay,
  logic,
  technical,
}

CutsceneStudioBlockCategory cutsceneStudioBlockCategory(
  CutsceneStudioBlockKind kind,
) {
  return switch (kind) {
    CutsceneStudioBlockKind.dialogue ||
    CutsceneStudioBlockKind.narration =>
      CutsceneStudioBlockCategory.dialogue,
    CutsceneStudioBlockKind.moveCharacter ||
    CutsceneStudioBlockKind.followCharacter ||
    CutsceneStudioBlockKind.faceCharacter =>
      CutsceneStudioBlockCategory.movement,
    CutsceneStudioBlockKind.transitionMap =>
      CutsceneStudioBlockCategory.transition,
    CutsceneStudioBlockKind.starterChoice ||
    CutsceneStudioBlockKind.sceneResult =>
      CutsceneStudioBlockCategory.gameplay,
    CutsceneStudioBlockKind.wait => CutsceneStudioBlockCategory.logic,
    CutsceneStudioBlockKind.runScript ||
    CutsceneStudioBlockKind.setFlag ||
    CutsceneStudioBlockKind.clearFlag ||
    CutsceneStudioBlockKind.emitOutcome ||
    CutsceneStudioBlockKind.callCutscene =>
      CutsceneStudioBlockCategory.technical,
    CutsceneStudioBlockKind.playerQuestion => CutsceneStudioBlockCategory.logic,
    CutsceneStudioBlockKind.pathfindMove =>
      CutsceneStudioBlockCategory.movement,
    CutsceneStudioBlockKind.characterAppear ||
    CutsceneStudioBlockKind.characterDisappear =>
      CutsceneStudioBlockCategory.movement,
    CutsceneStudioBlockKind.cameraCenter ||
    CutsceneStudioBlockKind.cameraTransition =>
      CutsceneStudioBlockCategory.transition,
  };
}

String cutsceneStudioBlockCategoryLabel(CutsceneStudioBlockCategory category) {
  return switch (category) {
    CutsceneStudioBlockCategory.dialogue => 'Dialogue',
    CutsceneStudioBlockCategory.movement => 'Déplacement',
    CutsceneStudioBlockCategory.transition => 'Transition',
    CutsceneStudioBlockCategory.gameplay => 'Gameplay',
    CutsceneStudioBlockCategory.logic => 'Logique',
    CutsceneStudioBlockCategory.technical => 'Technique',
  };
}

/// « Support runtime » = l’exécuteur MVP [ScenarioRuntimeExecutor] sait exécuter
/// le nœud produit par ce bloc **sans** placeholder ni blocage systématique.
///
/// Distinct de la **compilation** : un bloc peut compiler (graphe valide) tout en
/// restant partiellement supporté (ex. choix → node `choice` bloqué en MVP).
bool cutsceneStudioBlockRuntimeSupported(CutsceneStudioBlock block) {
  return switch (block.kind) {
    CutsceneStudioBlockKind.dialogue ||
    CutsceneStudioBlockKind.narration ||
    CutsceneStudioBlockKind.sceneResult ||
    CutsceneStudioBlockKind.runScript ||
    CutsceneStudioBlockKind.setFlag ||
    CutsceneStudioBlockKind.clearFlag ||
    CutsceneStudioBlockKind.emitOutcome ||
    CutsceneStudioBlockKind.moveCharacter ||
    CutsceneStudioBlockKind.followCharacter ||
    CutsceneStudioBlockKind.faceCharacter ||
    CutsceneStudioBlockKind.transitionMap ||
    CutsceneStudioBlockKind.pathfindMove =>
      true,
    CutsceneStudioBlockKind.starterChoice ||
    CutsceneStudioBlockKind.wait ||
    CutsceneStudioBlockKind.playerQuestion ||
    CutsceneStudioBlockKind.characterAppear ||
    CutsceneStudioBlockKind.characterDisappear ||
    CutsceneStudioBlockKind.cameraCenter ||
    CutsceneStudioBlockKind.cameraTransition ||
    CutsceneStudioBlockKind.callCutscene =>
      false,
  };
}

@immutable
class CutsceneStudioBlock {
  const CutsceneStudioBlock({
    required this.id,
    required this.kind,
    this.actorId,
    this.dialogueId,
    this.messageText,
    this.scriptId,
    this.flagName,
    this.outcomeId,
    this.resultLabel,
    this.resultScope,
    this.destinationTargetKind,
    this.destinationTargetId,
    this.transitionMapId,
    this.transitionWarpId,
    this.facingDirection,
    this.durationMs,
    this.waitForCompletion,
    this.choiceOptions = const <String>[],
  });

  final String id;
  final CutsceneStudioBlockKind kind;
  final String? actorId;
  final String? dialogueId;
  final String? messageText;
  final String? scriptId;
  final String? flagName;
  final String? outcomeId;
  final String? resultLabel;
  final String? resultScope;
  final String? destinationTargetKind;
  final String? destinationTargetId;
  final String? transitionMapId;
  final String? transitionWarpId;
  final String? facingDirection;
  final int? durationMs;
  final bool? waitForCompletion;
  final List<String> choiceOptions;

  CutsceneStudioBlock copyWith({
    String? id,
    CutsceneStudioBlockKind? kind,
    Object? actorId = cutsceneStudioCopyUnset,
    Object? dialogueId = cutsceneStudioCopyUnset,
    Object? messageText = cutsceneStudioCopyUnset,
    Object? scriptId = cutsceneStudioCopyUnset,
    Object? flagName = cutsceneStudioCopyUnset,
    Object? outcomeId = cutsceneStudioCopyUnset,
    Object? resultLabel = cutsceneStudioCopyUnset,
    Object? resultScope = cutsceneStudioCopyUnset,
    Object? destinationTargetKind = cutsceneStudioCopyUnset,
    Object? destinationTargetId = cutsceneStudioCopyUnset,
    Object? transitionMapId = cutsceneStudioCopyUnset,
    Object? transitionWarpId = cutsceneStudioCopyUnset,
    Object? facingDirection = cutsceneStudioCopyUnset,
    Object? durationMs = cutsceneStudioCopyUnset,
    Object? waitForCompletion = cutsceneStudioCopyUnset,
    List<String>? choiceOptions,
  }) {
    return CutsceneStudioBlock(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      actorId: identical(actorId, cutsceneStudioCopyUnset) ? this.actorId : actorId as String?,
      dialogueId: identical(dialogueId, cutsceneStudioCopyUnset)
          ? this.dialogueId
          : dialogueId as String?,
      messageText: identical(messageText, cutsceneStudioCopyUnset)
          ? this.messageText
          : messageText as String?,
      scriptId:
          identical(scriptId, cutsceneStudioCopyUnset) ? this.scriptId : scriptId as String?,
      flagName:
          identical(flagName, cutsceneStudioCopyUnset) ? this.flagName : flagName as String?,
      outcomeId:
          identical(outcomeId, cutsceneStudioCopyUnset) ? this.outcomeId : outcomeId as String?,
      resultLabel: identical(resultLabel, cutsceneStudioCopyUnset)
          ? this.resultLabel
          : resultLabel as String?,
      resultScope: identical(resultScope, cutsceneStudioCopyUnset)
          ? this.resultScope
          : resultScope as String?,
      destinationTargetKind: identical(destinationTargetKind, cutsceneStudioCopyUnset)
          ? this.destinationTargetKind
          : destinationTargetKind as String?,
      destinationTargetId: identical(destinationTargetId, cutsceneStudioCopyUnset)
          ? this.destinationTargetId
          : destinationTargetId as String?,
      transitionMapId: identical(transitionMapId, cutsceneStudioCopyUnset)
          ? this.transitionMapId
          : transitionMapId as String?,
      transitionWarpId: identical(transitionWarpId, cutsceneStudioCopyUnset)
          ? this.transitionWarpId
          : transitionWarpId as String?,
      facingDirection: identical(facingDirection, cutsceneStudioCopyUnset)
          ? this.facingDirection
          : facingDirection as String?,
      durationMs:
          identical(durationMs, cutsceneStudioCopyUnset) ? this.durationMs : durationMs as int?,
      waitForCompletion: identical(waitForCompletion, cutsceneStudioCopyUnset)
          ? this.waitForCompletion
          : waitForCompletion as bool?,
      choiceOptions: choiceOptions ?? this.choiceOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CutsceneStudioBlock) {
      return false;
    }
    if (other.id != id ||
        other.kind != kind ||
        other.actorId != actorId ||
        other.dialogueId != dialogueId ||
        other.messageText != messageText ||
        other.scriptId != scriptId ||
        other.flagName != flagName ||
        other.outcomeId != outcomeId ||
        other.resultLabel != resultLabel ||
        other.resultScope != resultScope ||
        other.destinationTargetKind != destinationTargetKind ||
        other.destinationTargetId != destinationTargetId ||
        other.transitionMapId != transitionMapId ||
        other.transitionWarpId != transitionWarpId ||
        other.facingDirection != facingDirection ||
        other.durationMs != durationMs ||
        other.waitForCompletion != waitForCompletion ||
        other.choiceOptions.length != choiceOptions.length) {
      return false;
    }
    for (var i = 0; i < choiceOptions.length; i++) {
      if (other.choiceOptions[i] != choiceOptions[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        actorId,
        dialogueId,
        messageText,
        scriptId,
        flagName,
        outcomeId,
        resultLabel,
        resultScope,
        destinationTargetKind,
        destinationTargetId,
        transitionMapId,
        transitionWarpId,
        facingDirection,
        durationMs,
        waitForCompletion,
        Object.hashAll(choiceOptions),
      );
}

// ---------------------------------------------------------------------------
// Flow Cutscene Studio — arbre séquentiel + branches « Oui / Non »
// ---------------------------------------------------------------------------
//
// Le studio visuel manipule une liste d’entrées:
// - bloc simple (action métier);
// - embranchement: une question + deux sous-listes (onYes / onNo).
//
// Ce modèle est volontairement **guidé** (pas un graphe libre) pour garder une
// lecture haut → bas lisible pour un public no-code.
//
// Persistance: sérialisé en JSON dans `ScenarioAsset.metadata` sous
// [kCutsceneStudioFlowMetadataKey], en complément du graphe runtime compilé.

/// Entrée du canevas central (bloc ou embranchement).
sealed class CutsceneFlowEntry {
  const CutsceneFlowEntry();
}

/// Bloc d’action sur une branche ou sur le fil principal.
final class CutsceneFlowBlockEntry extends CutsceneFlowEntry {
  const CutsceneFlowBlockEntry(this.block);

  final CutsceneStudioBlock block;

  @override
  bool operator ==(Object other) {
    return other is CutsceneFlowBlockEntry && other.block == block;
  }

  @override
  int get hashCode => block.hashCode;
}

/// Question à choix binaires (runtime: node `choice` + deux arêtes).
final class CutsceneFlowChoiceEntry extends CutsceneFlowEntry {
  const CutsceneFlowChoiceEntry({
    required this.question,
    this.onYes = const <CutsceneFlowEntry>[],
    this.onNo = const <CutsceneFlowEntry>[],
  });

  final CutsceneStudioBlock question;
  final List<CutsceneFlowEntry> onYes;
  final List<CutsceneFlowEntry> onNo;

  @override
  bool operator ==(Object other) {
    if (other is! CutsceneFlowChoiceEntry) return false;
    if (other.question != question ||
        other.onYes.length != onYes.length ||
        other.onNo.length != onNo.length) {
      return false;
    }
    for (var i = 0; i < onYes.length; i++) {
      if (other.onYes[i] != onYes[i]) return false;
    }
    for (var i = 0; i < onNo.length; i++) {
      if (other.onNo[i] != onNo[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        question,
        Object.hashAll(onYes),
        Object.hashAll(onNo),
      );
}

bool cutsceneFlowEntriesEqual(
  List<CutsceneFlowEntry>? a,
  List<CutsceneFlowEntry>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Document d'authoring manipulé par le studio (surface centrale).
///
/// Ce modèle n'est pas le runtime: c'est une représentation UX-friendly
/// convertie ensuite vers `ScenarioAsset`.
///
/// ---------------------------------------------------------------------------
/// Source de vérité (stabilisation produit)
/// ---------------------------------------------------------------------------
/// - **Canonique** : [cutsceneFlow] lorsqu’elle est non null (arbre + branches).
/// - **Dérivé** : [blocks] = tronc principal uniquement, toujours égal à
///   [flattenMainTrunkFlowToBlocks] appliqué au flow effectif (voir
///   [effectiveCutsceneFlowForDocument]).
/// - **Legacy** : documents sans `cutsceneFlow` → le studio matérialise un flow
///   linéaire via [cutsceneLinearFlowFromBlocks] à la volée ; toute mutation UI
///   doit alors peupler `cutsceneFlow` + synchroniser `blocks` (comme
///   [CutsceneStudioWorkspace] le fait déjà).
@immutable
class CutsceneStudioDocument {
  const CutsceneStudioDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.blocks,
    this.cutsceneFlow,
  });

  final String id;
  final String name;
  final String description;
  final CutsceneStudioSourceConfig source;

  /// Tronc principal — **projection** du flow pour compat sérialisation / tests.
  ///
  /// Ne pas éditer seul quand [cutsceneFlow] est défini : la colonne centrale
  /// et la persistance JSON utilisent le flow comme autorité.
  final List<CutsceneStudioBlock> blocks;

  /// Arbre d’authoring (tronc + branches). `null` = mode legacy 100 % linéaire.
  final List<CutsceneFlowEntry>? cutsceneFlow;

  CutsceneStudioDocument copyWith({
    String? id,
    String? name,
    String? description,
    CutsceneStudioSourceConfig? source,
    List<CutsceneStudioBlock>? blocks,
    Object? cutsceneFlow = cutsceneStudioCopyUnset,
  }) {
    return CutsceneStudioDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      source: source ?? this.source,
      blocks: blocks ?? this.blocks,
      cutsceneFlow: identical(cutsceneFlow, cutsceneStudioCopyUnset)
          ? this.cutsceneFlow
          : cutsceneFlow as List<CutsceneFlowEntry>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CutsceneStudioDocument) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.source != source ||
        other.blocks.length != blocks.length) {
      return false;
    }
    for (var i = 0; i < blocks.length; i++) {
      if (other.blocks[i] != blocks[i]) {
        return false;
      }
    }
    if (!cutsceneFlowEntriesEqual(other.cutsceneFlow, cutsceneFlow)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        source,
        Object.hashAll(blocks),
        cutsceneFlow == null
            ? 0
            : Object.hashAll(cutsceneFlow!.map((e) => e.hashCode)),
      );
}

/// Résultat de parsing d'un scénario existant vers le format studio v1.
///
/// `editable == false` signifie:
/// - le scénario existe et reste valide;
/// - MAIS sa structure sort du périmètre guidé du studio v1 (ex: branches).
@immutable
class CutsceneStudioParseResult {
  const CutsceneStudioParseResult({
    required this.document,
    required this.editable,
    required this.warnings,
  });

  final CutsceneStudioDocument document;
  final bool editable;
  final List<String> warnings;
}

/// Trim centralisé pour parser / compile (évite les chaînes vides).
String? cutsceneStudioTrimOrNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

/// Slug stable pour ids de nœuds / outcomes dérivés d’un libellé.
String cutsceneStudioNormalizeNodeId(String raw, {required String fallback}) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? fallback : normalized;
}

/// Résout l'`outcomeId` technique final pour un bloc "résultat de scène".
///
/// Frontière de responsabilité:
/// - l'UI manipule `resultLabel` + `resultScope` (langage humain);
/// - ce helper produit un identifiant technique stable utilisé au compile.
///
/// Cette fonction est publique pour que le workspace puisse afficher un aperçu
/// explicite ("id généré"), tout en évitant la saisie d'id brut.
String? resolveCutsceneStudioOutcomeId(CutsceneStudioBlock block) {
  return cutsceneStudioResolveOutcomeIdForResultBlock(block);
}

String? cutsceneStudioResolveOutcomeIdForResultBlock(CutsceneStudioBlock block) {
  final explicit = cutsceneStudioTrimOrNull(block.outcomeId);
  if (explicit != null) {
    return explicit;
  }
  final label = cutsceneStudioTrimOrNull(block.resultLabel);
  if (label == null) {
    return null;
  }
  final slug = cutsceneStudioNormalizeNodeId(label, fallback: 'scene_result');
  final scope =
      (cutsceneStudioTrimOrNull(block.resultScope) ?? kCutsceneStudioResultScopeLocal)
          .toLowerCase();
  switch (scope) {
    case kCutsceneStudioResultScopeGlobal:
      return 'global.$slug';
    case kCutsceneStudioResultScopeProgression:
      return 'progression.$slug';
    default:
      return 'local.$slug';
  }
}

String cutsceneStudioLabelFromOutcomeId(String? outcomeId) {
  final normalized = cutsceneStudioTrimOrNull(outcomeId);
  if (normalized == null) {
    return 'Résultat de scène';
  }
  final tail = normalized.split('.').last;
  final words =
      tail.split('_').where((part) => part.trim().isNotEmpty).toList();
  if (words.isEmpty) {
    return normalized;
  }
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String cutsceneStudioScopeFromOutcomeId(String? outcomeId) {
  final normalized = cutsceneStudioTrimOrNull(outcomeId);
  if (normalized == null) {
    return kCutsceneStudioResultScopeLocal;
  }
  if (normalized.startsWith('global.')) {
    return kCutsceneStudioResultScopeGlobal;
  }
  if (normalized.startsWith('progression.') ||
      normalized.startsWith('chapter_') ||
      normalized.startsWith('badge_')) {
    return kCutsceneStudioResultScopeProgression;
  }
  return kCutsceneStudioResultScopeLocal;
}
