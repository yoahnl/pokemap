import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/map_data.dart';
import '../models/cinematic_asset.dart';
import '../models/enums.dart';
import '../dialogue/runtime_dialogue_document.dart';
import '../models/scene_execution_capabilities.dart';
import 'narrative_command_catalog.dart';

abstract final class SpatialGameplayCapabilities {
  static const capabilityId = 'map3d.gameplay@1';
  static const storyCapabilityId = 'map3d.story@1';
  static const productionExportEnabled = false;
  static const commandIds = <String>{
    NarrativeCommandIds.setFact,
    NarrativeCommandIds.markEventConsumed,
    NarrativeCommandIds.completeStoryStep,
    NarrativeCommandIds.giveItem,
    NarrativeCommandIds.takeItem,
    NarrativeCommandIds.giveMoney,
    NarrativeCommandIds.givePokemon,
    NarrativeCommandIds.giveConfiguredStarter,
    NarrativeCommandIds.healParty,
    NarrativeCommandIds.setNpcPresence,
    NarrativeCommandIds.setPauseMenuEntryVisibility,
    NarrativeCommandIds.warp,
    NarrativeCommandIds.openShop,
    NarrativeCommandIds.openHeal,
    NarrativeCommandIds.openPc,
    NarrativeCommandIds.dialogue,
    NarrativeCommandIds.trainerBattle,
    NarrativeCommandIds.staticEncounter,
    NarrativeCommandIds.playModelAnimation,
  };
  static const cinematicStepKinds = <CinematicTimelineStepKind>{
    CinematicTimelineStepKind.wait,
    CinematicTimelineStepKind.camera,
    CinematicTimelineStepKind.actorMove,
    CinematicTimelineStepKind.actorFace,
    CinematicTimelineStepKind.marker,
  };
  static const conditionSources = <SceneConditionSourceKind>{
    SceneConditionSourceKind.inventoryItem,
    SceneConditionSourceKind.fact,
    SceneConditionSourceKind.factLikeStoryFlag,
    SceneConditionSourceKind.storyStepCompletion,
    SceneConditionSourceKind.consumedEvent,
  };

  static bool requiresStory(ProjectManifest project) =>
      project.scenes.any(
        (scene) => scene.graph.nodes.any(
          (node) =>
              node.payload is SceneCinematicPayload ||
              node.payload is SceneActionPayload &&
                  (node.payload as SceneActionPayload).interactiveCommand
                      is ScenePlayModelAnimationInteractiveCommand,
        ),
      ) ||
      (project.eventRegistry?.records.any(
            (record) =>
                record.definitionOrNull?.source.kind ==
                    NarrativeEventSourceKind.modelInteract ||
                record.draftOrNull?.source?.kind ==
                    NarrativeEventSourceKind.modelInteract,
          ) ??
          false);

  static bool requiresModelAnimation(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) =>
      project.scenes.any(
        (scene) => scene.graph.nodes.any(
          (node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).interactiveCommand
                  is ScenePlayModelAnimationInteractiveCommand,
        ),
      ) ||
      maps.any(
        (map) =>
            map.spatialScene?.instances.any(
              (instance) => instance.animationIndex != null,
            ) ??
            false,
      );

  static bool requiresGameplay(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
    Iterable<RuntimeDialogueDocument> dialogues = const [],
  }) =>
      project.pokemon.enabled ||
      project.newGame.enabled ||
      project.scenes.isNotEmpty ||
      project.cinematics.isNotEmpty ||
      project.presentationCinematics.isNotEmpty ||
      project.facts.isNotEmpty ||
      project.worldRules.isNotEmpty ||
      project.storylines.isNotEmpty ||
      project.scenarios.isNotEmpty ||
      project.shops.isNotEmpty ||
      project.badges.isNotEmpty ||
      project.trainers.isNotEmpty ||
      project.encounterTables.isNotEmpty ||
      project.dialogues.any((entry) => entry.declaredOutcomes.isNotEmpty) ||
      dialogues.any(
        (document) => document.nodes.any(
          (node) => node.steps.any(
            (step) =>
                step is! RuntimeDialogueLine ||
                step.characterId != null ||
                step.portraitStateId != null,
          ),
        ),
      ) ||
      (project.eventRegistry?.records.isNotEmpty ?? false) ||
      maps.any(
        (map) =>
            map.events.isNotEmpty ||
            map.triggers.isNotEmpty ||
            map.gameplayZones.isNotEmpty ||
            map.entities.any(
              (entity) =>
                  entity.kind == MapEntityKind.custom ||
                  entity.editorVisual != null ||
                  entity.npc?.trainerId != null ||
                  entity.npc?.visibilityRule != null ||
                  (entity.npc?.conditionalDialogues.isNotEmpty ?? false),
            ),
      );

  static bool supportsSceneNode(SceneExecutionProfile profile, SceneNode node) {
    final capability = sceneExecutionCapabilityForNode(profile, node);
    if (!sceneExecutionCapabilityMatrix
        .evaluate(profile: profile, capabilityId: capability)
        .isAllowed) {
      return false;
    }
    final payload = node.payload;
    return switch (payload) {
      SceneCinematicPayload() => true,
      ScenePresentationCinematicPayload() => false,
      SceneConditionPayload() =>
        payload.conditionSource != null &&
            (conditionSources.contains(payload.conditionSource!.sourceKind) ||
                profile == SceneExecutionProfile.preSession &&
                    payload.conditionSource!.sourceKind ==
                        SceneConditionSourceKind.newGameDraft),
      SceneActionPayload() =>
        payload.consequence != null
            ? commandIds.contains(payload.consequence!.kind.name)
            : payload.interactiveCommand != null
            ? commandIds.contains(payload.interactiveCommand!.kind.name)
            : profile == SceneExecutionProfile.preSession &&
                  payload.preSessionInteraction != null,
      SceneBattlePayload() => const {
        'trainer',
        'static',
        'wild',
      }.contains(payload.battleKind),
      _ => const {
        SceneNodeKind.start,
        SceneNodeKind.end,
        SceneNodeKind.yarnDialogue,
        SceneNodeKind.branchByOutcome,
        SceneNodeKind.merge,
      }.contains(node.kind),
    };
  }
}
