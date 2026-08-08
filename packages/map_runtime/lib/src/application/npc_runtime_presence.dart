// Décision runtime unique : PNJ présent sur une carte si et seulement si
// les prédicats auteur (map_core) **et** les `worldChanges` Step Studio
// sont satisfaits pour la progression courante.

import 'package:map_core/map_core.dart';

import 'global_story_chapter_runtime.dart';
import 'map_entity_runtime_predicate_evaluator.dart';
import 'step_studio_world_presence_runtime.dart';
import 'scene_runtime/scene_npc_state_metadata.dart';

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
  GlobalStoryChapterStepIndex? chapterIndex,
}) {
  if (entity.kind != MapEntityKind.npc) {
    return true;
  }
  final override = sceneNpcPresenceOverride(
    gameState,
    mapId: mapId,
    entityId: entity.id,
  );
  if (override != null) return override;
  final base = MapEntityRuntimePredicateEvaluator(
    gameState: gameState,
    // Construire l'index ici re-parse le JSON authoring de chaque scénario
    // globalStory : les appelants qui évaluent plusieurs entités doivent le
    // mettre en cache par manifeste (comme les règles Step Studio).
    chapterIndex:
        chapterIndex ?? buildGlobalStoryChapterStepIndex(manifest.scenarios),
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
