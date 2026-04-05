// Cutscene Studio — projection et dérivation du flow d'authoring.
// Voir cutscene_studio_models.dart pour les types ([CutsceneFlowEntry], document).

import 'cutscene_studio_models.dart';

/// Résolution des blocs **précédant** [targetBlockId] sur un chemin d’exécution unique.
///
/// Sert à dériver une **carte contextuelle** (où se trouve le joueur) pour les
/// dropdowns PNJ / warps / spawns dans l’inspecteur, après des warps ou
/// [CutsceneStudioBlockKind.transitionMap].
sealed class CutsceneStudioMapContextResolution {
  const CutsceneStudioMapContextResolution();
}

/// Chemin déterministe vers le bloc : prédécesseurs connus (tronc + une branche).
final class CutsceneStudioMapContextLinear
    extends CutsceneStudioMapContextResolution {
  const CutsceneStudioMapContextLinear(this.predecessorBlocks);
  final List<CutsceneStudioBlock> predecessorBlocks;
}

/// Après un choix avec branches non vides, un bloc sur le tronc **après** la
/// fusion dépend du chemin joueur — on ne simule pas deux cartes à la fois.
final class CutsceneStudioMapContextAmbiguous
    extends CutsceneStudioMapContextResolution {
  const CutsceneStudioMapContextAmbiguous();
}

/// Bloc absent du flow (ne devrait pas arriver si la sélection vient du canvas).
final class CutsceneStudioMapContextMissingTarget
    extends CutsceneStudioMapContextResolution {
  const CutsceneStudioMapContextMissingTarget();
}

String? _csMapCtxTrim(String? s) {
  final t = s?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

/// Lit l’arborescence [segment] pour savoir si un bloc avec cet [id] apparaît.
bool cutsceneStudioFlowSegmentContainsBlockId(
  List<CutsceneFlowEntry> segment,
  String id,
) {
  for (final e in segment) {
    switch (e) {
      case CutsceneFlowBlockEntry(:final block):
        if (block.id == id) return true;
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        if (question.id == id) return true;
        if (cutsceneStudioFlowSegmentContainsBlockId(onYes, id)) return true;
        if (cutsceneStudioFlowSegmentContainsBlockId(onNo, id)) return true;
    }
  }
  return false;
}

CutsceneStudioMapContextResolution? _walkFlowSegmentForPredecessors(
  List<CutsceneFlowEntry> segment,
  String targetId,
  List<CutsceneStudioBlock> prefix,
) {
  for (var i = 0; i < segment.length; i++) {
    final entry = segment[i];
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        if (block.id == targetId) {
          return CutsceneStudioMapContextLinear(List<CutsceneStudioBlock>.from(prefix));
        }
        prefix = <CutsceneStudioBlock>[...prefix, block];
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        if (question.id == targetId) {
          return CutsceneStudioMapContextLinear(List<CutsceneStudioBlock>.from(prefix));
        }
        final afterQuestion = <CutsceneStudioBlock>[...prefix, question];
        final inYes = _walkFlowSegmentForPredecessors(onYes, targetId, afterQuestion);
        if (inYes != null) return inYes;
        final inNo = _walkFlowSegmentForPredecessors(onNo, targetId, afterQuestion);
        if (inNo != null) return inNo;
        final hasBranchBodies = onYes.isNotEmpty || onNo.isNotEmpty;
        if (hasBranchBodies) {
          final tail = segment.sublist(i + 1);
          if (cutsceneStudioFlowSegmentContainsBlockId(tail, targetId)) {
            return const CutsceneStudioMapContextAmbiguous();
          }
        }
        prefix = <CutsceneStudioBlock>[...prefix, question];
    }
  }
  return null;
}

/// Prédécesseurs du bloc [targetBlockId] pour simulation carte joueur.
CutsceneStudioMapContextResolution cutsceneStudioResolveMapContextPredecessors(
  List<CutsceneFlowEntry> flow,
  String targetBlockId,
) {
  final r = _walkFlowSegmentForPredecessors(flow, targetBlockId, const []);
  return r ?? const CutsceneStudioMapContextMissingTarget();
}

/// Carte où se trouve le **joueur** après exécution séquentielle de [predecessorBlocks].
///
/// [warpTargetMapId] doit retourner la `targetMapId` du warp sur [mapId], ou `null`.
String? cutsceneStudioSimulatedPlayerMapId({
  required String? startMapId,
  required List<CutsceneStudioBlock> predecessorBlocks,
  required String? Function(String mapId, String warpId) warpTargetMapId,
}) {
  var map = _csMapCtxTrim(startMapId);
  if (map == null) return null;
  for (final b in predecessorBlocks) {
    switch (b.kind) {
      case CutsceneStudioBlockKind.transitionMap:
        final next = _csMapCtxTrim(b.transitionMapId);
        if (next != null) {
          map = next;
        }
        break;
      case CutsceneStudioBlockKind.moveCharacter:
      case CutsceneStudioBlockKind.pathfindMove:
        final actor = _csMapCtxTrim(b.actorId);
        final kind = _csMapCtxTrim(b.destinationTargetKind) ?? '';
        final tid = _csMapCtxTrim(b.destinationTargetId);
        if (actor == kCutsceneStudioActorPlayerId &&
            kind == kCutsceneStudioMoveTargetWarp &&
            tid != null) {
          final dest = warpTargetMapId(map!, tid);
          if (dest != null) {
            map = dest;
          }
        }
        break;
      default:
        break;
    }
  }
  return map;
}

/// Toutes les cartes visitées pendant la simulation (pour précharger warps / PNJ).
Set<String> cutsceneStudioCollectMapIdsAlongPlayerSimulation({
  required String? startMapId,
  required List<CutsceneStudioBlock> predecessorBlocks,
  required String? Function(String mapId, String warpId) warpTargetMapId,
}) {
  final out = <String>{};
  var map = _csMapCtxTrim(startMapId);
  if (map == null) return out;
  out.add(map);
  for (final b in predecessorBlocks) {
    switch (b.kind) {
      case CutsceneStudioBlockKind.transitionMap:
        final next = _csMapCtxTrim(b.transitionMapId);
        if (next != null) {
          map = next;
          out.add(map);
        }
        break;
      case CutsceneStudioBlockKind.moveCharacter:
      case CutsceneStudioBlockKind.pathfindMove:
        final actor = _csMapCtxTrim(b.actorId);
        final kind = _csMapCtxTrim(b.destinationTargetKind) ?? '';
        final tid = _csMapCtxTrim(b.destinationTargetId);
        if (actor == kCutsceneStudioActorPlayerId &&
            kind == kCutsceneStudioMoveTargetWarp &&
            tid != null) {
          final dest = warpTargetMapId(map!, tid);
          if (dest != null) {
            map = dest;
            out.add(map);
          }
        }
        break;
      default:
        break;
    }
  }
  return out;
}

List<CutsceneStudioBlock> flattenMainTrunkFlowToBlocks(
  List<CutsceneFlowEntry> flow,
) {
  final out = <CutsceneStudioBlock>[];
  for (final entry in flow) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        out.add(block);
      case CutsceneFlowChoiceEntry(:final question):
        out.add(question);
    }
  }
  return out;
}

/// Représentation linéaire pour l’authoring quand il n’y a pas encore d’arbre.
List<CutsceneFlowEntry> cutsceneLinearFlowFromBlocks(
  List<CutsceneStudioBlock> blocks,
) {
  return blocks.map(CutsceneFlowBlockEntry.new).toList(growable: false);
}

List<CutsceneFlowEntry> effectiveCutsceneFlowForDocument(
  CutsceneStudioDocument document,
) {
  if (document.cutsceneFlow != null && document.cutsceneFlow!.isNotEmpty) {
    return document.cutsceneFlow!;
  }
  return cutsceneLinearFlowFromBlocks(document.blocks);
}
