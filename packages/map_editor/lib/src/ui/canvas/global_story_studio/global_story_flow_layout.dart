// ignore_for_file: public_member_api_docs
//
// ---------------------------------------------------------------------------
// Global Story — mise en page du « story flow » central
// ---------------------------------------------------------------------------
//
// Ce fichier est volontairement **sans Widget Flutter** : il calcule une liste
// de blocs de présentation à partir du document macro ([GlobalStoryStudioDocument])
// et des steps ([StepStudioStep]).
//
// Intentions UX (produit no-code) :
// - Lecture **principalement verticale**, de haut en bas (comme un studio narratif).
// - Les embranchements apparaissent comme une **rangée latérale maîtrisée**, pas
//   comme un graphe libre façon blueprint.
// - On évite les termes « node / edge » : ici ce sont des **étapes** et des
//   **chemins possibles**.
//
// Limites assumées (évolutives) :
// - La détection du **point de convergence** après une branche utilise l’ensemble
//   des steps **atteignables** depuis chaque bras (BFS borné) puis l’intersection :
//   on choisit la step commune la plus « tôt » dans l’ordre métier des steps.
// - Si aucune convergence n’est trouvée, le flux s’arrête après la branche : l’auteur
//   complète la structure dans l’onglet Step / inspecteur (message possible en UI).
// - Les sous-branches sur un bras (branche dans une branche) **coupent** le chemin
//   linéaire affiché sur ce bras pour garder une lecture stable.
//
import 'package:flutter/foundation.dart';

import '../../../features/narrative/application/global_story_studio_authoring.dart';
import '../../../features/narrative/application/step_studio_authoring.dart';

/// Une étape + les libellés « humains » des liens sortants (pour le flux central).
@immutable
class GlobalStoryFlowStepRef {
  const GlobalStoryFlowStepRef({
    required this.stepId,
    this.outgoingLabels = const <String>[],
  });

  final String stepId;

  /// Libellés courts pour résumer les sorties (ex. condition, nom de la step cible).
  final List<String> outgoingLabels;
}

/// Bras d’embranchement : suite linéaire d’étapes jusqu’au point de fusion (exclu).
@immutable
class GlobalStoryFlowBranchArm {
  const GlobalStoryFlowBranchArm({
    required this.linkLabel,
    required this.stepIds,
  });

  /// Texte affiché au-dessus du bras (condition, ou nom court de la destination).
  final String linkLabel;

  /// Étapes sur ce bras avant la convergence.
  final List<String> stepIds;
}

/// Bloc : suite verticale d’une ou plusieurs étapes (tronçon linéaire).
@immutable
class GlobalStoryFlowLinearBlock {
  const GlobalStoryFlowLinearBlock({required this.steps});

  final List<GlobalStoryFlowStepRef> steps;
}

/// Bloc : embranchement puis fusion optionnelle vers une étape commune.
@immutable
class GlobalStoryFlowBranchBlock {
  const GlobalStoryFlowBranchBlock({
    required this.branchPointStepId,
    required this.arms,
    this.mergeStepId,
  });

  /// L’étape **à partir de laquelle** plusieurs chemins sont possibles.
  final String branchPointStepId;
  final List<GlobalStoryFlowBranchArm> arms;

  /// Si non null, tous les bras « rejoignent » cette étape ensuite.
  final String? mergeStepId;
}

/// Alerte de cycle ou de structure ambiguë (on affiche un bandeau discret, pas une erreur).
@immutable
class GlobalStoryFlowNoticeBlock {
  const GlobalStoryFlowNoticeBlock({required this.message});

  final String message;
}

/// Union des blocs rendus dans la colonne centrale.
typedef GlobalStoryFlowBlock = Object;

/// Construit la séquence de blocs pour le panneau « Story flow ».
///
/// [orderedSteps] doit être trié par [StepStudioStep.order] (comme ailleurs dans l’éditeur).
List<GlobalStoryFlowBlock> buildGlobalStoryFlowBlocks({
  required GlobalStoryStudioDocument document,
  required List<StepStudioStep> orderedSteps,
}) {
  final nodeById = <String, GlobalStoryStepNode>{
    for (final n in document.nodes) n.stepId: n,
  };
  final orderIndex = <String, int>{
    for (var i = 0; i < orderedSteps.length; i++) orderedSteps[i].id: i,
  };

  final entry = document.entryStepId.trim();
  if (entry.isEmpty || orderedSteps.isEmpty) {
    return const <GlobalStoryFlowBlock>[
      GlobalStoryFlowNoticeBlock(
        message:
            'Ajoutez au moins une étape et définissez un point de départ pour voir le fil narratif.',
      ),
    ];
  }

  final blocks = <GlobalStoryFlowBlock>[];
  final visited = <String>{};
  final linearBuffer = <GlobalStoryFlowStepRef>[];

  void flushLinear() {
    if (linearBuffer.isEmpty) {
      return;
    }
    blocks.add(GlobalStoryFlowLinearBlock(steps: List<GlobalStoryFlowStepRef>.from(linearBuffer)));
    linearBuffer.clear();
  }

  GlobalStoryFlowStepRef refForStep(String id, GlobalStoryStepNode? node) {
    final labels = <String>[];
    if (node != null) {
      for (final link in node.links) {
        final targetName = _stepDisplayName(link.toStepId, orderedSteps);
        if (link.conditionLabel != null && link.conditionLabel!.trim().isNotEmpty) {
          labels.add(link.conditionLabel!.trim());
        } else if (targetName.isNotEmpty) {
          labels.add('Mène à · $targetName');
        }
      }
    }
    return GlobalStoryFlowStepRef(stepId: id, outgoingLabels: labels);
  }

  bool isBranchNode(GlobalStoryStepNode node) {
    if (node.links.length > 1) {
      return true;
    }
    return node.exitMode == GlobalStoryStepExitMode.branchExclusive ||
        node.exitMode == GlobalStoryStepExitMode.branchConditional;
  }

  String? findMergeStepId(List<String> branchTargets) {
    if (branchTargets.length < 2) {
      return null;
    }
    final reachSets = <Set<String>>[];
    for (final t in branchTargets) {
      reachSets.add(_reachableStepIds(t, nodeById, maxDepth: 28));
    }
    var common = reachSets.first.toSet();
    for (var i = 1; i < reachSets.length; i++) {
      common = common.intersection(reachSets[i]);
    }
    for (final t in branchTargets) {
      common.remove(t);
    }
    if (common.isEmpty) {
      return null;
    }
    String? best;
    var bestOrder = 1 << 30;
    for (final id in common) {
      final o = orderIndex[id] ?? (1 << 29);
      if (o < bestOrder) {
        bestOrder = o;
        best = id;
      }
    }
    return best;
  }

  String? currentId = entry;
  while (currentId != null && currentId.isNotEmpty) {
    if (visited.contains(currentId)) {
      flushLinear();
      blocks.add(
        GlobalStoryFlowNoticeBlock(
          message:
              'Le récit repasse par une étape déjà vue (« ${_stepDisplayName(currentId, orderedSteps)} »). '
              'Vérifiez les liens macro pour éviter une boucle confuse.',
        ),
      );
      break;
    }
    visited.add(currentId);

    final node = nodeById[currentId];
    if (node == null) {
      flushLinear();
      blocks.add(
        GlobalStoryFlowNoticeBlock(
          message:
              'L’étape « ${_stepDisplayName(currentId, orderedSteps)} » n’a pas encore de nœud macro. '
              'Enregistrez ou normalisez le document.',
        ),
      );
      break;
    }

    final branch = isBranchNode(node) && node.links.isNotEmpty;

    if (branch) {
      // L’étape d’embranchement est montrée seule sur sa ligne, puis le paysage latéral.
      flushLinear();
      linearBuffer.add(refForStep(currentId, node));
      flushLinear();

      final targets = node.links.map((l) => l.toStepId).toList(growable: false);
      final mergeId = findMergeStepId(targets);

      final arms = <GlobalStoryFlowBranchArm>[];
      for (final link in node.links) {
        final label = (link.conditionLabel != null && link.conditionLabel!.trim().isNotEmpty)
            ? link.conditionLabel!.trim()
            : _stepDisplayName(link.toStepId, orderedSteps);
        final path = _collectSingleLinkPath(
          start: link.toStepId,
          stopExclusive: mergeId,
          nodeById: nodeById,
        );
        arms.add(GlobalStoryFlowBranchArm(linkLabel: label, stepIds: path));
      }

      blocks.add(
        GlobalStoryFlowBranchBlock(
          branchPointStepId: currentId,
          arms: arms,
          mergeStepId: mergeId,
        ),
      );

      if (mergeId == null) {
        break;
      }
      currentId = mergeId;
      continue;
    }

    // Tronçon linéaire : on accumule jusqu’à la prochaine bifurcation / fin.
    linearBuffer.add(refForStep(currentId, node));
    if (node.links.isEmpty) {
      flushLinear();
      break;
    }
    currentId = node.links.first.toStepId;
  }

  flushLinear();

  if (blocks.isEmpty) {
    return const <GlobalStoryFlowBlock>[
      GlobalStoryFlowNoticeBlock(message: 'Aucun fil narratif à afficher pour ce scénario.'),
    ];
  }
  return blocks;
}

String _stepDisplayName(String stepId, List<StepStudioStep> orderedSteps) {
  for (final s in orderedSteps) {
    if (s.id == stepId) {
      final n = s.name.trim();
      return n.isEmpty ? stepId : n;
    }
  }
  return stepId;
}

Set<String> _reachableStepIds(
  String from,
  Map<String, GlobalStoryStepNode> nodeById, {
  required int maxDepth,
}) {
  final seen = <String>{};
  final queue = <({String id, int depth})>[(id: from, depth: 0)];
  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    if (cur.depth > maxDepth || seen.contains(cur.id)) {
      continue;
    }
    seen.add(cur.id);
    final node = nodeById[cur.id];
    if (node == null) {
      continue;
    }
    for (final l in node.links) {
      queue.add((id: l.toStepId, depth: cur.depth + 1));
    }
  }
  return seen;
}

/// Avance le long des liens **tant qu’il n’y a qu’une seule sortie**, jusqu’à
/// rencontrer [stopExclusive] (non incluse), une fin de chaîne, ou une bifurcation.
List<String> _collectSingleLinkPath({
  required String start,
  required String? stopExclusive,
  required Map<String, GlobalStoryStepNode> nodeById,
}) {
  final out = <String>[];
  var cur = start;
  final localSeen = <String>{};
  while (cur.isNotEmpty && cur != stopExclusive) {
    if (localSeen.contains(cur)) {
      break;
    }
    localSeen.add(cur);
    out.add(cur);
    final n = nodeById[cur];
    if (n == null || n.links.isEmpty) {
      break;
    }
    if (n.links.length > 1) {
      break;
    }
    final next = n.links.first.toStepId;
    if (next == stopExclusive) {
      break;
    }
    cur = next;
  }
  return out;
}
