// Index runtime des chapitres Global Story Studio (metadata scénario global).
// Aligné sur `authoring.globalStoryStudioDocument` côté map_editor — pas de dépendance
// à l’éditeur : on parse uniquement le JSON nécessaire à l’évaluation « chapitre terminé ».

import 'dart:convert';

import 'package:map_core/map_core.dart';

/// Clé metadata — doit rester alignée avec `kGlobalStoryStudioDocumentMetadataKey`
/// dans `map_editor` (global_story_studio_authoring.dart).
const String kGlobalStoryStudioDocumentMetadataKey =
    'authoring.globalStoryStudioDocument';

/// Pour chaque id de chapitre, la liste des ids de steps Step Studio qui
/// doivent être dans [PlayerProgression.completedStepIds] pour considérer
/// le chapitre comme terminé.
class GlobalStoryChapterStepIndex {
  const GlobalStoryChapterStepIndex({required this.chapterIdToStepIds});

  /// Vide si aucun document valide n’a été trouvé.
  final Map<String, List<String>> chapterIdToStepIds;

  /// `true` seulement si le chapitre existe, a au moins une step, et **toutes**
  /// ses steps sont dans [completedStepIds].
  ///
  /// Chapitre inconnu ou sans steps : `false` (évite les faux positifs).
  bool isChapterCompleted(
    String chapterId,
    Set<String> completedStepIds,
  ) {
    final id = chapterId.trim();
    if (id.isEmpty) return false;
    final steps = chapterIdToStepIds[id];
    if (steps == null || steps.isEmpty) return false;
    return steps.every(completedStepIds.contains);
  }

  /// Négation stricte de [isChapterCompleted] pour le même chapitre.
  bool isChapterNotCompleted(
    String chapterId,
    Set<String> completedStepIds,
  ) {
    final id = chapterId.trim();
    if (id.isEmpty) return true;
    final steps = chapterIdToStepIds[id];
    if (steps == null || steps.isEmpty) return true;
    return !steps.every(completedStepIds.contains);
  }
}

/// Construit l’index à partir des scénarios du manifeste.
///
/// On lit uniquement les scénarios `scope == globalStory` qui portent un JSON
/// `authoring.globalStoryStudioDocument` avec un tableau `chapters`.
GlobalStoryChapterStepIndex buildGlobalStoryChapterStepIndex(
  List<ScenarioAsset> scenarios,
) {
  final out = <String, List<String>>{};
  for (final scenario in scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final raw = scenario.metadata[kGlobalStoryStudioDocumentMetadataKey];
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final chapters = decoded['chapters'];
      if (chapters is! List<dynamic>) {
        continue;
      }
      for (final rawChapter in chapters) {
        if (rawChapter is! Map<String, dynamic>) {
          continue;
        }
        final chapterId = (rawChapter['id'] as String?)?.trim();
        if (chapterId == null || chapterId.isEmpty) {
          continue;
        }
        final stepIdsJson = rawChapter['stepIds'];
        if (stepIdsJson is! List<dynamic>) {
          out[chapterId] = const [];
          continue;
        }
        final stepIds = stepIdsJson
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        out[chapterId] = stepIds;
      }
    } catch (_) {
      // JSON invalide : ignorer ce scénario.
    }
  }
  return GlobalStoryChapterStepIndex(chapterIdToStepIds: out);
}
