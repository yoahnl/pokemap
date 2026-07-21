import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

enum SelbrumeNarrativeAuthoringDomain {
  fact,
  storyline,
  dialogue,
  cinematic,
  scene,
  worldRule,
  event,
  validation,
  reload,
}

final class SelbrumeNarrativeAuthoringStepEvidence {
  const SelbrumeNarrativeAuthoringStepEvidence({
    required this.domain,
    required this.errorCount,
    required this.warningCount,
    required this.diagnosticKeys,
  });

  final SelbrumeNarrativeAuthoringDomain domain;
  final int errorCount;
  final int warningCount;
  final List<String> diagnosticKeys;

  bool get diagnosticsCaptured => errorCount >= 0 && warningCount >= 0;
}

final class SelbrumeNarrativeReconstructionResult {
  const SelbrumeNarrativeReconstructionResult({
    required this.initialProject,
    required this.authoredProject,
    required this.reloadedProject,
    required this.map,
    required this.factId,
    required this.storylineId,
    required this.chapterId,
    required this.stepId,
    required this.dialogueId,
    required this.cinematicId,
    required this.sceneId,
    required this.eventId,
    required this.worldRuleId,
    required this.dialogueFilePath,
    required this.steps,
  });

  final ProjectManifest initialProject;
  final ProjectManifest authoredProject;
  final ProjectManifest reloadedProject;
  final MapData map;
  final String factId;
  final String storylineId;
  final String chapterId;
  final String stepId;
  final String dialogueId;
  final String cinematicId;
  final String sceneId;
  final String eventId;
  final String worldRuleId;
  final String dialogueFilePath;
  final List<SelbrumeNarrativeAuthoringStepEvidence> steps;

  String get mapId => map.id;
  String get npcEntityId => SelbrumeNarrativeAuthoringHarness.npcEntityId;
  String get authoredFingerprint =>
      canonicalizeNarrativeEventJson(authoredProject.toJson());
  String get reloadedFingerprint =>
      canonicalizeNarrativeEventJson(reloadedProject.toJson());
}

/// Reconstructs a narrative slice through the same typed application and core
/// operations used by Narrative Studio. File encoding remains owned by the
/// workspace, repositories and Event V2 journaled persistence gateway.
final class SelbrumeNarrativeAuthoringHarness {
  SelbrumeNarrativeAuthoringHarness._({
    required this.root,
    required ProjectFileSystem workspace,
    required FileProjectRepository projectRepository,
    required FileMapRepository mapRepository,
  })  : _workspace = workspace,
        _projectRepository = projectRepository,
        _mapRepository = mapRepository;

  static const mapId = 'map_selbrume_harbor';
  static const npcEntityId = 'npc_harbor_guide';
  static const _storylineId = 'story_selbrume_harbor';
  static const _chapterId = 'chapter_arrival';
  static const _stepId = 'step_meet_harbor_guide';

  final Directory root;
  final ProjectFileSystem _workspace;
  final FileProjectRepository _projectRepository;
  final FileMapRepository _mapRepository;

  String get projectPath => _workspace.projectManifestPath;

  static Future<SelbrumeNarrativeAuthoringHarness>
      createPhysicalFixture() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_nsc80_narrative_authoring_',
    );
    final workspace = ProjectFileSystem(root.path);
    final projectRepository = FileProjectRepository();
    final mapRepository = FileMapRepository();
    final project = ProjectManifest(
      name: 'Selbrume — reconstruction no-code',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: mapId,
          name: 'Port de Selbrume',
          relativePath: 'maps/$mapId.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const <NarrativeEventRecord>[],
        legacyClaims: const <LegacySourceClaim>[],
      ),
    );
    const map = MapData(
      id: mapId,
      name: 'Port de Selbrume',
      size: GridSize(width: 12, height: 10),
      entities: <MapEntity>[
        MapEntity(
          id: npcEntityId,
          name: 'Guide du port',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 4, y: 3),
          npc: MapEntityNpcData(displayName: 'Guide du port'),
        ),
        MapEntity(
          id: 'spawn_harbor',
          name: 'Arrivée',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 7),
          spawn: MapEntitySpawnData(spawnKey: 'arrival'),
          blocksMovement: false,
        ),
      ],
    );
    await projectRepository.saveProject(project, workspace.projectManifestPath);
    await mapRepository.saveMap(
      map,
      workspace.resolveMapPath(project.maps.single.relativePath),
      projectDialogueContext: project,
    );
    return SelbrumeNarrativeAuthoringHarness._(
      root: root,
      workspace: workspace,
      projectRepository: projectRepository,
      mapRepository: mapRepository,
    );
  }

  Future<SelbrumeNarrativeReconstructionResult> authorVerticalSlice() async {
    final initialProject = await _projectRepository.loadProject(projectPath);
    final map = await _mapRepository.loadMap(
      _workspace.resolveMapPath(initialProject.maps.single.relativePath),
    );
    final evidence = <SelbrumeNarrativeAuthoringStepEvidence>[];
    var project = initialProject;

    final fact = addNarrativeFact(
      project,
      label: 'Guide du port rencontré',
      description: 'Le joueur a parlé au guide en arrivant à Selbrume.',
      category: 'Selbrume',
      tags: const <String>['selbrume', 'arrival'],
    );
    project = fact.updatedProject;
    await _saveAndRecord(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.fact,
      evidence,
    );

    final storyline = createStoryline(
      project,
      storyline: StorylineAsset(
        id: _storylineId,
        type: StorylineType.main,
        status: StorylineStatus.active,
        title: 'La brume de Selbrume',
        description: 'Première rencontre au port.',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: _chapterId,
            title: 'Arrivée au port',
            order: 0,
            status: StorylineStatus.active,
            steps: <StorylineStep>[
              StorylineStep(
                id: _stepId,
                title: 'Rencontrer le guide du port',
                order: 0,
                status: StorylineStatus.active,
              ),
            ],
          ),
        ],
      ),
    );
    if (!storyline.isApplied) {
      throw StateError('Storyline creation failed: ${storyline.code}.');
    }
    project = storyline.after;
    await _saveAndRecord(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.storyline,
      evidence,
    );

    project = await CreateProjectDialogueUseCase(_projectRepository).execute(
      _workspace,
      project,
      name: 'Guide du port',
      description: 'Accueil du joueur à Selbrume.',
      defaultStartNode: 'Start',
    );
    final dialogueId = project.dialogues.single.id;
    project = await UpdateProjectDialogueUseCase(_projectRepository).execute(
      _workspace,
      project,
      dialogueId: dialogueId,
      declaredOutcomes: const <DialogueDeclaredOutcome>[
        DialogueDeclaredOutcome(id: 'accepted', label: 'Conseil accepté'),
      ],
    );
    await SaveDialogueYarnBodyUseCase().execute(
      _workspace,
      project,
      dialogueId: dialogueId,
      yarnBody: '''title: Start
---
Guide: Bienvenue à Selbrume. La brume cache parfois le chemin.
-> Écouter le conseil
    <<outcome accepted>>
===
''',
    );
    evidence.add(_capture(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.dialogue,
    ));

    final cinematicMutation = NarrativeAssetMutation.createCinematic(
      project,
      title: 'La brume se lève sur le port',
      description: 'Un court temps visuel conclut la rencontre.',
      timeline: CinematicTimeline(
        steps: <CinematicTimelineStep>[
          CinematicTimelineStep(
            id: 'wait_harbor_reveal',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 250,
          ),
        ],
      ),
    );
    if (cinematicMutation is! NarrativeAssetCreated) {
      throw StateError('Cinematic creation was rejected.');
    }
    project = cinematicMutation.after;
    final cinematicId = cinematicMutation.asset.id;
    await _saveAndRecord(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.cinematic,
      evidence,
    );

    final sceneDraft = createSceneDraftInProject(
      project,
      name: 'Rencontre avec le guide du port',
      description: 'Dialogue puis révélation du port.',
    );
    project = sceneDraft.updatedProject;
    var scene = removeSceneEdgeDraft(
      sceneDraft.createdScene,
      'edge_start_end',
    ).updatedScene;
    final dialogueNode = addSceneLinkedAssetNodeDraft(
      scene,
      payload: SceneYarnDialoguePayload(
        dialogueId: dialogueId,
        yarnNodeName: 'Start',
        expectedOutcomes: const <String>['accepted'],
        speakerHints: const <String>['Guide du port'],
      ),
      title: 'Accueil du guide',
      afterNodeId: 'node_start',
    );
    scene = dialogueNode.updatedScene;
    final cinematicNode = addSceneCinematicNodeDraft(
      scene,
      project: project,
      cinematicId: cinematicId,
      afterNodeId: dialogueNode.createdNode.id,
    );
    scene = cinematicNode.updatedScene;
    final factNode = addSceneConsequenceActionNodeDraft(
      scene,
      consequence: SceneConsequence.setFact(
        factId: fact.createdFact.id,
        value: true,
      ),
      title: 'Mémoriser la rencontre',
      afterNodeId: cinematicNode.createdNode.id,
    );
    scene = factNode.updatedScene;
    final completionNode = addSceneConsequenceActionNodeDraft(
      scene,
      consequence: SceneConsequence.completeStoryStep(stepId: _stepId),
      title: 'Terminer l’arrivée au port',
      afterNodeId: factNode.createdNode.id,
    );
    scene = completionNode.updatedScene;
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: dialogueNode.createdNode.id,
    ).updatedScene;
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: dialogueNode.createdNode.id,
      fromPortId: 'accepted',
      toNodeId: cinematicNode.createdNode.id,
    ).updatedScene;
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: cinematicNode.createdNode.id,
      fromPortId: 'completed',
      toNodeId: factNode.createdNode.id,
    ).updatedScene;
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: factNode.createdNode.id,
      fromPortId: 'completed',
      toNodeId: completionNode.createdNode.id,
    ).updatedScene;
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: completionNode.createdNode.id,
      fromPortId: 'completed',
      toNodeId: 'node_end',
    ).updatedScene;
    scene = updateSceneEndPayload(
      scene,
      nodeId: 'node_end',
      outcomePolicy: SceneOutcomePolicy.progression,
    ).updatedScene;
    project = project.copyWith(
      scenes: <SceneAsset>[
        for (final candidate in project.scenes)
          if (candidate.id == scene.id) scene else candidate,
      ],
    );
    final linkedStoryline = linkSceneToStorylineStep(
      project,
      storylineId: _storylineId,
      chapterId: _chapterId,
      stepId: _stepId,
      sceneId: scene.id,
    );
    project = linkedStoryline.updatedProject;
    await _saveAndRecord(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.scene,
      evidence,
    );

    final worldRule = addWorldRule(
      project,
      label: 'Masquer le guide après la rencontre',
      description: 'Le monde reflète la progression du joueur.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: fact.createdFact.id,
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: mapId,
        entityId: npcEntityId,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
      tags: const <String>['selbrume'],
      maps: <MapData>[map],
    );
    project = worldRule.updatedProject;
    await _saveAndRecord(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.worldRule,
      evidence,
    );

    var eventWriteIndex = 0;
    final builder = NarrativeEventBuilderV2UseCase(
      persistenceGateway: _projectRepository,
      idGeneratorFactory: () => NarrativeEventIdGenerator(
        rawUuidFactory: () => '019abcde-4000-7000-8000-000000000080',
      ),
      operationIdFactory: () =>
          'nsc80_reconstruct_harbor_event_${eventWriteIndex++}',
    );
    final creation = await builder.create(
      projectPath: projectPath,
      request: NarrativeEventBuilderV2CreationRequest(
        name: 'Rencontre avec le guide du port',
        source: NarrativeEventSourceRef.entityInteract(mapId, npcEntityId),
        sceneId: scene.id,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        publish: true,
      ),
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!creation.succeeded || creation.eventId == null) {
      throw StateError(
        'Event creation failed at ${creation.failedStep}: ${creation.code}.',
      );
    }
    final activation = await builder.setEnabled(
      projectPath: projectPath,
      eventId: creation.eventId!,
      enabled: true,
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!activation.succeeded) {
      throw StateError('Event activation failed: ${activation.code}.');
    }
    project = await _projectRepository.loadProject(projectPath);
    evidence.add(_capture(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.event,
    ));
    evidence.add(_capture(
      project,
      map,
      SelbrumeNarrativeAuthoringDomain.validation,
    ));

    final reloaded = await _projectRepository.loadProject(projectPath);
    evidence.add(_capture(
      reloaded,
      map,
      SelbrumeNarrativeAuthoringDomain.reload,
    ));
    final dialogue = reloaded.dialogues.singleWhere(
      (entry) => entry.id == dialogueId,
    );
    return SelbrumeNarrativeReconstructionResult(
      initialProject: initialProject,
      authoredProject: project,
      reloadedProject: reloaded,
      map: map,
      factId: fact.createdFact.id,
      storylineId: _storylineId,
      chapterId: _chapterId,
      stepId: _stepId,
      dialogueId: dialogueId,
      cinematicId: cinematicId,
      sceneId: scene.id,
      eventId: creation.eventId!,
      worldRuleId: worldRule.createdRule.id,
      dialogueFilePath:
          _workspace.resolveProjectRelativePath(dialogue.relativePath),
      steps: List<SelbrumeNarrativeAuthoringStepEvidence>.unmodifiable(
        evidence,
      ),
    );
  }

  Future<NarrativeEventMapCreationResult> attemptDuplicateSourceEvent() {
    return CreateNarrativeEventFromMapSourceUseCase(
      persistenceGateway: _projectRepository,
    ).call(
      projectPath: projectPath,
      intent: NarrativeEventMapCreationIntent(
        source: NarrativeEventSourceRef.entityInteract(mapId, npcEntityId),
        humanName: 'Deuxième rencontre accidentelle',
      ),
      mapDirty: false,
      projectDirty: false,
      saving: false,
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<void> _saveAndRecord(
    ProjectManifest project,
    MapData map,
    SelbrumeNarrativeAuthoringDomain domain,
    List<SelbrumeNarrativeAuthoringStepEvidence> evidence,
  ) async {
    await _projectRepository.saveProject(project, projectPath);
    evidence.add(_capture(project, map, domain));
  }

  SelbrumeNarrativeAuthoringStepEvidence _capture(
    ProjectManifest project,
    MapData map,
    SelbrumeNarrativeAuthoringDomain domain,
  ) {
    final report = validateNarrativeProject(
      project,
      maps: <MapData>[map],
    );
    return SelbrumeNarrativeAuthoringStepEvidence(
      domain: domain,
      errorCount: report.errorCount,
      warningCount: report.warningCount,
      diagnosticKeys: <String>[
        for (final diagnostic in report.diagnostics) diagnostic.stableKey,
      ],
    );
  }
}
