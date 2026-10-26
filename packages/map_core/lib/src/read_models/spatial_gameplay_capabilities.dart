import '../models/map_spatial_scene.dart' show ProjectDimension;
import '../models/scene_asset.dart';
import '../models/scene_interactive_command.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import '../operations/spatial_smart_tile_models.dart';
import '../models/cinematic_asset.dart';
import '../models/enums.dart';
import '../dialogue/runtime_dialogue_document.dart';
import '../models/scene_execution_capabilities.dart';
import 'narrative_command_catalog.dart';

abstract final class SpatialGameplayCapabilities {
  static const capabilityId = 'map3d.gameplay@1';
  static const storyCapabilityId = 'map3d.story@1';
  static const companionCapabilityId = 'map3d.party-companion@1';
  static const audioCapabilityId = 'map3d.scene-audio@1';
  static const sceneMusicCapabilityId = 'map3d.scene-music@1';
  static const cinematicFadeCapabilityId = 'map3d.cinematic-fade@1';
  static const cinematicConnectedCapabilityId = 'map3d.cinematic-connected@1';

  static const trainerSpottingCapabilityId = 'map3d.trainer-spotting@1';

  static bool requiresTrainerSpotting(
    ProjectManifest project, {
    required Iterable<MapData> maps,
  }) =>
      project.settings.dimension == ProjectDimension.threeD &&
      maps.any(
        (map) => map.entities.any(
          (entity) =>
              entity.npc?.trainerId != null &&
              (entity.npc?.lineOfSightRange ?? 0) > 0,
        ),
      );

  static bool requiresConnectedCinematics(ProjectManifest project,
      {required Iterable<MapData> maps}) {
    final mapsById = {for (final map in maps) map.id: map};
    for (final asset in project.cinematics) {
      final map = mapsById[asset.mapId];
      if (map == null) continue;
      for (final point in asset.stageContext?.stagePoints ??
          const <CinematicStagePoint>[]) {
        if (point.relativeToActorId == null) {
          if (point.x < 0 || point.y < 0 ||
              point.x >= map.size.width || point.y >= map.size.height) {
            return true;
          }
        } else if ((point.x != 0 || point.y != 0) &&
            (map.connections.isNotEmpty || mapsById.values.any((source) =>
                source.connections.any((connection) => connection.targetMapId == map.id)))) {
          return true;
        }
      }
    }
    return false;
  }

  static bool requiresCinematicFade(ProjectManifest project) =>
      project.cinematics.any((asset) => asset.timeline.steps.any(
          (step) => step.kind == CinematicTimelineStepKind.fade));

  static bool supportsSceneMusic(SceneMusicInteractiveCommand command) =>
      command.channel == SceneMusicChannel.music && command.scope == SceneMusicScope.scene;

  static bool requiresSceneMusic(ProjectManifest project) => project.scenes.any((scene) => scene.graph.nodes.any((node) => node.payload is SceneActionPayload && (node.payload as SceneActionPayload).interactiveCommand is SceneMusicInteractiveCommand));

  static bool requiresAudio(ProjectManifest project) => project.scenes.any((scene) => scene.graph.nodes.any((node) => node.payload is SceneActionPayload && switch ((node.payload as SceneActionPayload).interactiveCommand) {
    ScenePlaySoundEffectInteractiveCommand() || ScenePlayMusicEffectInteractiveCommand() || SceneStopSoundEffectsInteractiveCommand() => true,
    _ => false,
  }));

  static const productionExportEnabled = false;
  static const commandIds = <String>{
    NarrativeCommandIds.setFact,
    NarrativeCommandIds.adjustIntegerFact,
    NarrativeCommandIds.calculateIntegerFacts,
    NarrativeCommandIds.adjustMoney,
    NarrativeCommandIds.tryPayMoney,
    NarrativeCommandIds.inputIntegerToFact,
    NarrativeCommandIds.inputTextToFact,
    NarrativeCommandIds.markEventConsumed,
    NarrativeCommandIds.completeStoryStep,
    NarrativeCommandIds.giveItem,
    NarrativeCommandIds.giveItemGift,
    NarrativeCommandIds.takeItem,
    NarrativeCommandIds.giveMoney,
    NarrativeCommandIds.givePokemon,
    NarrativeCommandIds.givePokemonFromCatalog,
    NarrativeCommandIds.receivePokemonFromCatalog,
    NarrativeCommandIds.giveConfiguredStarter,
    NarrativeCommandIds.healParty,
    NarrativeCommandIds.setNpcPresence,
    NarrativeCommandIds.setPlayerAvatar,
    NarrativeCommandIds.setPauseMenuEntryVisibility,
    NarrativeCommandIds.warp,
    NarrativeCommandIds.openShop,
    NarrativeCommandIds.openHeal,
    NarrativeCommandIds.openPc,
    NarrativeCommandIds.dialogue,
    NarrativeCommandIds.trainerBattle,
    NarrativeCommandIds.staticEncounter,
    NarrativeCommandIds.playModelAnimation,
    NarrativeCommandIds.playSoundEffect,
    NarrativeCommandIds.playMusicEffect,
    NarrativeCommandIds.stopSoundEffects,
    NarrativeCommandIds.sceneMusic,
  };
  static const cinematicStepKinds = <CinematicTimelineStepKind>{
    CinematicTimelineStepKind.fade,
    CinematicTimelineStepKind.atmosphere,
    CinematicTimelineStepKind.wait,
    CinematicTimelineStepKind.camera,
    CinematicTimelineStepKind.actorMove,
    CinematicTimelineStepKind.actorJump,
    CinematicTimelineStepKind.actorFace,
    CinematicTimelineStepKind.actorEmote,
    CinematicTimelineStepKind.marker,
  };
  static const conditionSources = <SceneConditionSourceKind>{
    SceneConditionSourceKind.playerFacing,
    SceneConditionSourceKind.partyState,
    SceneConditionSourceKind.trainerDefeated,
    SceneConditionSourceKind.badge,
    SceneConditionSourceKind.inventoryItem,
    SceneConditionSourceKind.fact,
    SceneConditionSourceKind.integerComparison,
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
  }) {
    if (maps.any((map) => map.warps.any((warp) => warp.door != null))) {
      return true;
    }
    if (project.scenes.any(
      (scene) => scene.graph.nodes.any(
        (node) =>
            node.payload is SceneActionPayload &&
            (node.payload as SceneActionPayload).interactiveCommand
                is ScenePlayModelAnimationInteractiveCommand,
      ),
    )) {
      return true;
    }
    bool animated(SmartTileVisualPart part) =>
        part.source is SmartTileModel3dSource &&
        (part.source as SmartTileModel3dSource).animationIndex != null;
    final presets = {
      for (final preset in project.smartTileCatalog.presets)
        if (preset.rules.any(
          (rule) =>
              rule.candidates.any((candidate) => candidate.parts.any(animated)),
        ))
          preset.id,
    };
    final patterns = {
      for (final pattern in project.smartTileCatalog.patterns)
        if (pattern.cells.any((cell) => cell.parts.any(animated))) pattern.id,
    };
    return maps.any(
      (map) =>
          (map.spatialScene?.instances.any(
                (instance) => instance.animationIndex != null,
              ) ??
              false) ||
          map.spatialScene != null &&
              map.layers.whereType<SmartTileLayer>().any(
                (layer) =>
                    layer.isVisible &&
                    layer.opacity > 0 &&
                    (presets.contains(layer.presetId) ||
                        layer.patternStrokes.any(
                          (stroke) => patterns.contains(stroke.patternId),
                        )),
              ) &&
              resolveSpatialSmartTileInstances(
                map: map,
                catalog: project.smartTileCatalog,
                sourceCellWidth: project.settings.tileWidth,
                sourceCellHeight: project.settings.tileHeight,
              ).any((instance) => instance.animationIndex != null),
    );
  }

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
                  entity.kind == MapEntityKind.item ||
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
    if (payload is SceneActionPayload && payload.interactiveCommand is SceneMusicInteractiveCommand && !supportsSceneMusic(payload.interactiveCommand as SceneMusicInteractiveCommand)) return false;
    return switch (payload) {
      SceneCinematicPayload() => true,
      ScenePresentationCinematicPayload() =>
        profile == SceneExecutionProfile.preSession,
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
            ? payload.interactiveCommand is SceneWorldPresentationInteractiveCommand
              ? const {SceneWorldPresentationOperation.atmosphere, SceneWorldPresentationOperation.restoreAtmosphere}.contains((payload.interactiveCommand as SceneWorldPresentationInteractiveCommand).operation)
              : commandIds.contains(
                NarrativeCommandIds.forInteractiveCommand(
                  payload.interactiveCommand!,
                ),
              )
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
