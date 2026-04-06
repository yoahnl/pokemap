// Couche runtime : relie le document Step Studio (JSON dans les métadonnées
// du scénario **global**) aux identifiants de scénarios **locaux** (cutscenes)
// sans dépendre du package `map_editor` (évite une dépendance circulaire et
// garde le bundle jouable autonome).

import 'dart:convert';

import 'package:map_core/map_core.dart';

/// Clé metadata du scénario global — doit rester alignée avec
/// `kStepStudioDocumentMetadataKey` dans `map_editor` (Step Studio authoring).
const String kStepStudioDocumentMetadataKey = 'authoring.stepStudioDocument';

/// Index dérivé du document Step Studio : pour chaque scénario local dont
/// l’id est référencé dans une règle `completion.mode = whenCutsceneEnds`,
/// on retient l’id de la step à marquer complète quand ce scénario atteint
/// un nœud `end` (statut `reachedEnd` côté exécuteur).
///
/// Remarque : si deux steps déclarent la même `cutsceneId` de completion,
/// la **dernière** occurrence dans l’ordre des scénarios globaux puis des
/// steps JSON l’emporte (cas anormal ; l’authoring devrait garantir l’unicité).
class StepCompletionCutsceneIndex {
  const StepCompletionCutsceneIndex({
    required this.cutsceneScenarioIdToStepId,
  });

  /// Clé = `scenario.id` du scénario **local** (cutscene), valeur = `step.id`.
  final Map<String, String> cutsceneScenarioIdToStepId;

  /// Retourne l’id de step à compléter lorsque le scénario local [scenarioId]
  /// se termine proprement (`reachedEnd`), ou `null` si aucune règle ne cible
  /// cette cutscene.
  String? stepIdToCompleteWhenCutsceneEnds(String scenarioId) {
    final key = scenarioId.trim();
    if (key.isEmpty) {
      return null;
    }
    return cutsceneScenarioIdToStepId[key];
  }
}

/// Construit l’index à partir du manifeste courant (tous les scénarios).
///
/// On ne lit que les entrées `scope == globalStory` qui portent un JSON
/// `authoring.stepStudioDocument` ; les autres sont ignorées silencieusement.
StepCompletionCutsceneIndex buildStepCompletionCutsceneIndex(
  List<ScenarioAsset> scenarios,
) {
  final out = <String, String>{};
  for (final scenario in scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final raw = scenario.metadata[kStepStudioDocumentMetadataKey];
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final steps = decoded['steps'];
      if (steps is! List<dynamic>) {
        continue;
      }
      for (final rawStep in steps) {
        if (rawStep is! Map<String, dynamic>) {
          continue;
        }
        final stepId = (rawStep['id'] as String?)?.trim();
        if (stepId == null || stepId.isEmpty) {
          continue;
        }
        final completion = rawStep['completion'];
        if (completion is! Map<String, dynamic>) {
          continue;
        }
        final mode = (completion['mode'] as String?)?.trim();
        if (mode != 'whenCutsceneEnds') {
          continue;
        }
        final cutsceneId = (completion['cutsceneId'] as String?)?.trim();
        if (cutsceneId == null || cutsceneId.isEmpty) {
          continue;
        }
        out[cutsceneId] = stepId;
      }
    } catch (_) {
      // JSON invalide : on n’indexe rien pour ce scénario ; le jeu reste jouable.
    }
  }
  return StepCompletionCutsceneIndex(cutsceneScenarioIdToStepId: out);
}

/// Ajoute [stepId] à [completed] s’il manque ; retourne une nouvelle liste
/// immuable si changement, sinon [completed].
List<String> appendCompletedStepIdIfAbsent(
  List<String> completed,
  String stepId,
) {
  final id = stepId.trim();
  if (id.isEmpty) {
    return completed;
  }
  if (completed.contains(id)) {
    return completed;
  }
  return [...completed, id];
}
