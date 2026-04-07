// Décision runtime unique : PNJ présent sur une carte si et seulement si
// les prédicats auteur (map_core) **et** les `worldChanges` Step Studio
// sont satisfaits pour la progression courante.

import 'package:map_core/map_core.dart';

import 'global_story_chapter_runtime.dart';
import 'map_entity_runtime_predicate_evaluator.dart';
import 'step_studio_world_presence_runtime.dart';

/// Retourne `true` si le PNJ [entity] doit exister sur [mapId] pour ce
/// [gameState] et ce [manifest] (visibilité PNJ + Step Studio).
///
/// [stepStudioWorldRules] est typiquement [buildStepStudioWorldPresenceRuleList]
/// sur [manifest.scenarios] ; le cache par manifeste reste une responsabilité
/// de l’appelant (ex. [PlayableMapGame]).
bool isNpcRuntimePresentOnMap({
  required GameState gameState,
  required ProjectManifest manifest,
  required List<StepStudioWorldPresenceRule> stepStudioWorldRules,
  required String mapId,
  required MapEntity entity,
}) {
  if (entity.kind != MapEntityKind.npc) {
    return true;
  }
  final base = MapEntityRuntimePredicateEvaluator(
    gameState: gameState,
    chapterIndex: buildGlobalStoryChapterStepIndex(manifest.scenarios),
  ).isNpcPresentOnMap(entity);
  if (!base) {
    return false;
  }
  return entityPassesStepStudioWorldPresence(
    mapId: mapId,
    entity: entity,
    completedStepIds: gameState.progression.completedStepIds,
    rules: stepStudioWorldRules,
  );
}
