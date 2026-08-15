import '../models/project_manifest.dart';
import '../models/cinematic_asset.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/project_new_game_config.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/scene_execution_capabilities.dart';
import '../read_models/narrative_dependency_index.dart';

const sceneLibraryArchivedMetadataKey = 'pokemap.scene.archived';
const sceneLibraryFolderMetadataKey = 'pokemap.scene.libraryFolder';

enum SceneLibraryMutationDisposition { applied, noChange, rejected }

final class SceneLibraryLocation {
  const SceneLibraryLocation({
    this.folder,
    this.storylineId,
    this.chapterId,
  });

  final String? folder;
  final String? storylineId;
  final String? chapterId;
}

final class SceneLibraryMutationResult {
  SceneLibraryMutationResult({
    required this.before,
    required this.after,
    required this.disposition,
    this.scene,
    this.previousScene,
    this.code,
    this.message,
    List<String> referencePaths = const <String>[],
  }) : referencePaths = List<String>.unmodifiable(referencePaths);

  final ProjectManifest before;
  final ProjectManifest after;
  final SceneLibraryMutationDisposition disposition;
  final SceneAsset? scene;
  final SceneAsset? previousScene;
  final String? code;
  final String? message;
  final List<String> referencePaths;

  bool get isApplied => disposition == SceneLibraryMutationDisposition.applied;
}

bool isSceneArchived(SceneAsset scene) =>
    scene.metadata[sceneLibraryArchivedMetadataKey]?.toLowerCase() == 'true';

String? sceneLibraryFolder(SceneAsset scene) =>
    _trimOptional(scene.metadata[sceneLibraryFolderMetadataKey]);

SceneLibraryMutationResult renameSceneInProject(
  ProjectManifest project, {
  required String sceneId,
  required String name,
}) {
  final source = _findScene(project, sceneId);
  if (source == null) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneNotFound',
      message: 'The SceneAsset to rename does not exist.',
    );
  }
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return _sceneLibraryRejected(
      project,
      code: 'blankSceneName',
      message: 'A SceneAsset requires a readable name.',
      previousScene: source,
    );
  }
  return _replaceScene(
    project,
    source,
    _copySceneAsset(source, name: trimmedName),
  );
}

SceneLibraryMutationResult updateSceneLibraryClassification(
  ProjectManifest project, {
  required String sceneId,
  required SceneLibraryLocation location,
  required List<String> tags,
  required List<SceneOutcome> declaredOutcomes,
}) {
  final source = _findScene(project, sceneId);
  if (source == null) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneNotFound',
      message: 'The SceneAsset to classify does not exist.',
    );
  }
  final storylineId = _trimOptional(location.storylineId);
  final chapterId = _trimOptional(location.chapterId);
  if (chapterId != null && storylineId == null) {
    return _sceneLibraryRejected(
      project,
      code: 'chapterWithoutStoryline',
      message: 'A Scene chapter requires a Storyline owner.',
      previousScene: source,
    );
  }
  final folder = _trimOptional(location.folder);
  final metadata = Map<String, String>.from(source.metadata);
  if (folder == null) {
    metadata.remove(sceneLibraryFolderMetadataKey);
  } else {
    metadata[sceneLibraryFolderMetadataKey] = folder;
  }
  try {
    return _replaceScene(
      project,
      source,
      _copySceneAsset(
        source,
        storylineId: storylineId,
        chapterId: chapterId,
        tags: tags,
        declaredOutcomes: declaredOutcomes,
        metadata: metadata,
      ),
    );
  } on Object catch (error) {
    return _sceneLibraryRejected(
      project,
      code: 'invalidSceneClassification',
      message: 'The Scene library classification is invalid: $error',
      previousScene: source,
    );
  }
}

SceneLibraryMutationResult duplicateSceneInProject(
  ProjectManifest project, {
  required String sceneId,
  String? name,
}) {
  final source = _findScene(project, sceneId);
  if (source == null) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneNotFound',
      message: 'The SceneAsset to duplicate does not exist.',
    );
  }
  final duplicateName = _trimOptional(name) ?? '${source.name} (copie)';
  final duplicateId = _uniqueSceneId(
    duplicateName,
    project.scenes.map((scene) => scene.id),
  );
  try {
    final duplicate = _duplicateSceneAsset(
      source,
      duplicateId: duplicateId,
      name: duplicateName,
    );
    return _sceneLibraryApplied(
      project,
      project.copyWith(scenes: [...project.scenes, duplicate]),
      scene: duplicate,
    );
  } on Object catch (error) {
    return _sceneLibraryRejected(
      project,
      code: 'invalidSceneDuplicate',
      message: 'The SceneAsset duplicate is invalid: $error',
      previousScene: source,
    );
  }
}

SceneLibraryMutationResult archiveSceneInProject(
  ProjectManifest project, {
  required String sceneId,
}) =>
    _setSceneArchived(project, sceneId: sceneId, archived: true);

SceneLibraryMutationResult restoreSceneInProject(
  ProjectManifest project, {
  required String sceneId,
}) =>
    _setSceneArchived(project, sceneId: sceneId, archived: false);

SceneLibraryMutationResult deleteSceneFromProject(
  ProjectManifest project, {
  required String sceneId,
  String? replacementSceneId,
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final source = _findScene(project, sceneId);
  if (source == null) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneNotFound',
      message: 'The SceneAsset to delete does not exist.',
    );
  }
  final target = NarrativeDependencyKey.scene(source.id);
  final index =
      dependencyIndex ?? buildNarrativeDependencyIndex(project: project);
  final usages = index
      .usagesFor(target)
      .where((usage) => usage.owner != target)
      .toList(growable: false);
  final replacementId = _trimOptional(replacementSceneId);
  if (replacementId == null && usages.isNotEmpty) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneReferenced',
      message: 'The SceneAsset is still used by narrative consumers.',
      previousScene: source,
      referencePaths: [for (final usage in usages) usage.path],
    );
  }

  SceneAsset? replacement;
  if (replacementId != null) {
    replacement = _findScene(project, replacementId);
    if (replacement == null || replacement.id == source.id) {
      return _sceneLibraryRejected(
        project,
        code: 'invalidSceneReplacement',
        message: 'The replacement SceneAsset must exist and be different.',
        previousScene: source,
        referencePaths: [for (final usage in usages) usage.path],
      );
    }
    final unsupported = usages
        .where((usage) => !_isManifestSceneConsumerPath(usage.path))
        .toList(growable: false);
    if (unsupported.isNotEmpty) {
      return _sceneLibraryRejected(
        project,
        code: 'sceneReplacementUnsupportedConsumers',
        message: 'Some Scene consumers live outside ProjectManifest.',
        previousScene: source,
        referencePaths: [for (final usage in unsupported) usage.path],
      );
    }
    final replacementOutcomeIds = {
      for (final outcome in replacement.declaredOutcomes) outcome.id,
    };
    final missingOutcomes = source.declaredOutcomes
        .where((outcome) => !replacementOutcomeIds.contains(outcome.id))
        .map((outcome) => outcome.id)
        .toList(growable: false);
    if (missingOutcomes.isNotEmpty) {
      return _sceneLibraryRejected(
        project,
        code: 'sceneReplacementMissingOutcomes',
        message: 'The replacement SceneAsset does not declare every outcome.',
        previousScene: source,
        referencePaths: missingOutcomes,
      );
    }
  }

  var updatedProject = project;
  if (replacement != null) {
    updatedProject = _replaceSceneConsumers(
      updatedProject,
      sourceSceneId: source.id,
      replacementSceneId: replacement.id,
    );
  }
  updatedProject = updatedProject.copyWith(
    scenes: [
      for (final scene in updatedProject.scenes)
        if (scene.id != source.id) scene,
    ],
  );
  return _sceneLibraryApplied(
    project,
    updatedProject,
    previousScene: source,
    referencePaths: [for (final usage in usages) usage.path],
  );
}

final class SceneDraftCreationResult {
  const SceneDraftCreationResult({
    required this.updatedProject,
    required this.createdScene,
  });

  final ProjectManifest updatedProject;
  final SceneAsset createdScene;
}

final class SceneNodeDraftCreationResult {
  const SceneNodeDraftCreationResult({
    required this.updatedScene,
    required this.createdNode,
  });

  final SceneAsset updatedScene;
  final SceneNode createdNode;
}

final class SceneEdgeDraftCreationResult {
  const SceneEdgeDraftCreationResult({
    required this.updatedScene,
    required this.createdEdge,
  });

  final SceneAsset updatedScene;
  final SceneEdge createdEdge;
}

final class SceneEdgeDraftRemovalResult {
  const SceneEdgeDraftRemovalResult({
    required this.updatedScene,
    required this.removedEdge,
  });

  final SceneAsset updatedScene;
  final SceneEdge removedEdge;
}

final class SceneNodeDraftRemovalResult {
  const SceneNodeDraftRemovalResult({
    required this.updatedScene,
    required this.removedNode,
    required this.removedEdges,
  });

  final SceneAsset updatedScene;
  final SceneNode removedNode;
  final List<SceneEdge> removedEdges;
}

final class SceneNodeLayoutUpdateResult {
  const SceneNodeLayoutUpdateResult({
    required this.updatedScene,
    required this.updatedLayout,
  });

  final SceneAsset updatedScene;
  final SceneNodeLayout updatedLayout;
}

final class SceneConditionSourceUpdateResult {
  const SceneConditionSourceUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneConditionPayload updatedPayload;
}

final class SceneYarnDialoguePayloadUpdateResult {
  const SceneYarnDialoguePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneYarnDialoguePayload updatedPayload;
}

final class SceneEndPayloadUpdateResult {
  const SceneEndPayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneEndPayload updatedPayload;
}

final class SceneBattlePayloadUpdateResult {
  const SceneBattlePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneBattlePayload updatedPayload;
}

final class SceneCinematicPayloadUpdateResult {
  const SceneCinematicPayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneCinematicPayload updatedPayload;
}

final class SceneActionNodeDraftCreationResult {
  const SceneActionNodeDraftCreationResult({
    required this.updatedScene,
    required this.createdNode,
    required this.createdPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode createdNode;
  final SceneActionPayload createdPayload;
}

final class SceneActionConsequencePayloadUpdateResult {
  const SceneActionConsequencePayloadUpdateResult({
    required this.updatedScene,
    required this.updatedNode,
    required this.updatedPayload,
  });

  final SceneAsset updatedScene;
  final SceneNode updatedNode;
  final SceneActionPayload updatedPayload;
}

final class SceneAuthorableOutputPort {
  const SceneAuthorableOutputPort({
    required this.id,
    required this.label,
    required this.edgeKind,
  });

  final String id;
  final String label;
  final SceneEdgeKind edgeKind;
}

SceneDraftCreationResult createSceneDraftInProject(
  ProjectManifest project, {
  required String name,
  String? description,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Scene name is required.');
  }

  final scene = _createSceneDraft(
    id: _uniqueSceneId(trimmedName, project.scenes.map((scene) => scene.id)),
    name: trimmedName,
    description: _trimOptional(description),
  );
  return SceneDraftCreationResult(
    updatedProject: project.copyWith(
      scenes: [...project.scenes, scene],
    ),
    createdScene: scene,
  );
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForNode(
  SceneNode node,
) {
  final payload = node.payload;
  if (payload is SceneYarnDialoguePayload) {
    return [
      const SceneAuthorableOutputPort(
        id: 'completed',
        label: 'completed',
        edgeKind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcomeId in payload.expectedOutcomes)
        if (outcomeId != 'completed')
          SceneAuthorableOutputPort(
            id: outcomeId,
            label: outcomeId,
            edgeKind: SceneEdgeKind.dialogueOutcome,
          ),
    ];
  }
  if (payload is SceneBattlePayload && payload.declaredOutcomes.isNotEmpty) {
    return [
      for (final outcomeId in payload.declaredOutcomes)
        SceneAuthorableOutputPort(
          id: outcomeId,
          label: outcomeId,
          edgeKind: switch (outcomeId) {
            'victory' => SceneEdgeKind.battleVictory,
            'defeat' => SceneEdgeKind.battleDefeat,
            _ => SceneEdgeKind.branchOutcome,
          },
        ),
    ];
  }
  return authorableSceneOutputPortsForKind(node.kind);
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForNodeInGraph(
  SceneNode node,
  SceneGraph graph,
) {
  final payload = node.payload;
  if (payload is! SceneBranchByOutcomePayload) {
    return authorableSceneOutputPortsForNode(node);
  }
  final sourceNodeId = payload.sourceNodeId;
  SceneNode? sourceNode;
  for (final candidate in graph.nodes) {
    if (candidate.id == sourceNodeId) {
      sourceNode = candidate;
      break;
    }
  }
  if (sourceNode == null ||
      (sourceNode.kind != SceneNodeKind.yarnDialogue &&
          sourceNode.kind != SceneNodeKind.battle &&
          sourceNode.kind != SceneNodeKind.condition)) {
    return const <SceneAuthorableOutputPort>[];
  }
  final sourcePorts = authorableSceneOutputPortsForNode(sourceNode);
  return <SceneAuthorableOutputPort>[
    for (final port in sourcePorts)
      SceneAuthorableOutputPort(
        id: port.id,
        label: port.label,
        edgeKind: SceneEdgeKind.branchOutcome,
      ),
    if (payload.fallbackPolicy ==
            SceneBranchOutcomeFallbackPolicy.defaultRoute &&
        !sourcePorts.any((port) => port.id == 'default'))
      const SceneAuthorableOutputPort(
        id: 'default',
        label: 'default',
        edgeKind: SceneEdgeKind.branchOutcome,
      ),
    if (payload.fallbackPolicy == SceneBranchOutcomeFallbackPolicy.errorRoute &&
        !sourcePorts.any((port) => port.id == 'error'))
      const SceneAuthorableOutputPort(
        id: 'error',
        label: 'error',
        edgeKind: SceneEdgeKind.error,
      ),
  ];
}

bool isSceneNodeDraftRemovable(SceneNode node) {
  return isSceneNodeDraftKindRemovable(node.kind);
}

bool isSceneNodeDraftKindRemovable(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => false,
    SceneNodeKind.end ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      true,
  };
}

String? sceneNodeDraftRemovalBlocker(SceneGraph graph, SceneNode node) {
  if (node.kind == SceneNodeKind.start || graph.startNodeId == node.id) {
    return 'Le nœud de départ ne peut pas être supprimé.';
  }
  if (node.kind == SceneNodeKind.end) {
    final endCount =
        graph.nodes.where((candidate) => candidate.kind == SceneNodeKind.end);
    if (endCount.length <= 1) {
      return 'Une scène doit garder au moins une fin.';
    }
  }
  return null;
}

bool canRemoveSceneNodeDraft(SceneGraph graph, SceneNode node) {
  return sceneNodeDraftRemovalBlocker(graph, node) == null;
}

List<SceneAuthorableOutputPort> authorableSceneOutputPortsForKind(
  SceneNodeKind kind,
) {
  return switch (kind) {
    SceneNodeKind.start => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.condition => const [
        SceneAuthorableOutputPort(
          id: 'true',
          label: 'true',
          edgeKind: SceneEdgeKind.conditionTrue,
        ),
        SceneAuthorableOutputPort(
          id: 'false',
          label: 'false',
          edgeKind: SceneEdgeKind.conditionFalse,
        ),
      ],
    SceneNodeKind.merge => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.yarnDialogue => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.battle => const [
        SceneAuthorableOutputPort(
          id: 'victory',
          label: 'victory',
          edgeKind: SceneEdgeKind.battleVictory,
        ),
        SceneAuthorableOutputPort(
          id: 'defeat',
          label: 'defeat',
          edgeKind: SceneEdgeKind.battleDefeat,
        ),
      ],
    SceneNodeKind.action => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.defaultFlow,
        ),
      ],
    SceneNodeKind.cinematic => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    SceneNodeKind.presentationCinematic => const [
        SceneAuthorableOutputPort(
          id: 'completed',
          label: 'completed',
          edgeKind: SceneEdgeKind.presentationCompleted,
        ),
      ],
    SceneNodeKind.end ||
    SceneNodeKind.branchByOutcome =>
      const <SceneAuthorableOutputPort>[],
  };
}

SceneConditionSourceUpdateResult updateSceneConditionSource(
  SceneAsset scene, {
  required String nodeId,
  required SceneConditionSource source,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.condition) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Condition Authoring V0 can only update condition nodes.',
    );
  }
  _validateConditionSourceForV0(source);

  final updatedPayload = SceneConditionPayload(
    conditionLabel: _trimOptional(source.label),
    conditionRef: source.sourceId,
    conditionSource: source,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedNodes = [
    for (final candidate in scene.graph.nodes)
      if (candidate.id == nodeId) updatedNode else candidate,
  ];
  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: updatedNodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneConditionSourceUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneYarnDialoguePayloadUpdateResult updateSceneYarnDialoguePayload(
  SceneAsset scene, {
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
  required List<String> expectedOutcomes,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.yarnDialogue ||
      node.payload is! SceneYarnDialoguePayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene payload editing V0 can only update Yarn dialogue nodes.',
    );
  }
  final normalizedDialogueId = _trimRequired(
    dialogueId,
    'dialogueId',
    'Dialogue id is required by Scene payload editing V0.',
  );
  final currentPayload = node.payload as SceneYarnDialoguePayload;
  final updatedPayload = SceneYarnDialoguePayload(
    dialogueId: normalizedDialogueId,
    yarnNodeName: _trimOptional(yarnNodeName),
    expectedOutcomes: expectedOutcomes,
    speakerHints: currentPayload.speakerHints,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final supportedOutcomeIds = updatedPayload.expectedOutcomes.toSet();
  final staleEdgeIds = <String>{};
  final updatedEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    final isStaleDialogueOutcome = edge.fromNodeId == nodeId &&
        edge.kind == SceneEdgeKind.dialogueOutcome &&
        !supportedOutcomeIds.contains(edge.fromPortId);
    if (isStaleDialogueOutcome) {
      staleEdgeIds.add(edge.id);
    } else {
      updatedEdges.add(edge);
    }
  }
  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final candidate in scene.graph.nodes)
          if (candidate.id == updatedNode.id) updatedNode else candidate,
      ],
      edges: updatedEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: scene.layout.nodeLayouts,
      edgeLayouts: [
        for (final layout in scene.layout.edgeLayouts)
          if (!staleEdgeIds.contains(layout.edgeId)) layout,
      ],
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneYarnDialoguePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

/// Updates only the authored terminal intent of an End node.
///
/// Keeping this mutation in map_core prevents the Scene workspace from
/// becoming a second owner of terminality and preserves the original graph,
/// layout, notes and metadata verbatim.
SceneEndPayloadUpdateResult updateSceneEndPayload(
  SceneAsset scene, {
  required String nodeId,
  String? sceneOutcomeId,
  required SceneOutcomePolicy? outcomePolicy,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.end || node.payload is! SceneEndPayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene outcome policy can only update End nodes.',
    );
  }
  final currentPayload = node.payload as SceneEndPayload;
  final updatedPayload = SceneEndPayload(
    sceneOutcomeId: _trimOptional(sceneOutcomeId),
    outcomePolicy: outcomePolicy,
    notes: currentPayload.notes,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneEndPayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneBattlePayloadUpdateResult updateSceneBattlePayload(
  SceneAsset scene, {
  required String nodeId,
  required String trainerId,
  String battleKind = 'trainer',
  String? battleTemplateId,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.battle ||
      node.payload is! SceneBattlePayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene payload editing V0 can only update battle nodes.',
    );
  }
  final normalizedTrainerId = _trimRequired(
    trainerId,
    'trainerId',
    'Trainer id is required by Scene payload editing V0.',
  );
  final normalizedBattleKind = battleKind.trim();
  if (normalizedBattleKind != 'trainer' && normalizedBattleKind != 'static') {
    throw ArgumentError.value(
      battleKind,
      'battleKind',
      'Battle kind must be trainer or static.',
    );
  }
  final normalizedBattleTemplateId = battleTemplateId?.trim();
  if (normalizedBattleKind == 'static' &&
      (normalizedBattleTemplateId == null ||
          normalizedBattleTemplateId.isEmpty)) {
    throw ArgumentError.value(
      battleTemplateId,
      'battleTemplateId',
      'Static battles require a stable battle template reference.',
    );
  }
  final currentPayload = node.payload as SceneBattlePayload;
  final updatedPayload = SceneBattlePayload(
    battleKind: normalizedBattleKind,
    trainerId: normalizedTrainerId,
    battleTemplateId:
        normalizedBattleKind == 'static' ? normalizedBattleTemplateId : null,
    npcEntityId: currentPayload.npcEntityId,
    declaredOutcomes: const ['victory', 'defeat'],
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneBattlePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneNodeDraftCreationResult addSceneCinematicNodeDraft(
  SceneAsset scene, {
  required ProjectManifest project,
  required String cinematicId,
  String? title,
  String? afterNodeId,
}) {
  final cinematic = _canonicalCinematicOrThrow(
    project,
    cinematicId,
    'cinematicId',
  );
  return addSceneLinkedAssetNodeDraft(
    scene,
    payload: SceneCinematicPayload(cinematicId: cinematic.id),
    title: _trimOptional(title) ?? cinematic.title,
    afterNodeId: afterNodeId,
  );
}

SceneCinematicPayloadUpdateResult updateSceneCinematicPayload(
  SceneAsset scene, {
  required String nodeId,
  required String cinematicId,
  ProjectManifest? project,
}) {
  final node = _findNodeOrThrow(scene, nodeId, 'nodeId');
  if (node.kind != SceneNodeKind.cinematic ||
      node.payload is! SceneCinematicPayload) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene payload editing V0 can only update cinematic nodes.',
    );
  }
  final normalizedCinematicId = _trimRequired(
    cinematicId,
    'cinematicId',
    'Cinematic id is required by Scene payload editing V0.',
  );
  if (project != null) {
    _canonicalCinematicOrThrow(project, normalizedCinematicId, 'cinematicId');
  }
  final updatedPayload = SceneCinematicPayload(
    cinematicId: normalizedCinematicId,
  );
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneCinematicPayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneActionNodeDraftCreationResult addSceneConsequenceActionNodeDraft(
  SceneAsset scene, {
  required SceneConsequence consequence,
  String? title,
  String? afterNodeId,
}) {
  _validateSceneConsequenceForAuthoring(consequence);

  return _addSceneActionPayloadNodeDraft(
    scene,
    payload: SceneActionPayload.consequence(consequence),
    title: _trimOptional(title) ?? _defaultConsequenceActionTitle(consequence),
    afterNodeId: afterNodeId,
  );
}

/// Adds an awaitable command action without degrading it to a legacy string.
///
/// Persistent effects deliberately use [addSceneConsequenceActionNodeDraft];
/// keeping these entry points separate prevents a second wire for state writes.
SceneActionNodeDraftCreationResult addSceneCommandActionNodeDraft(
  SceneAsset scene, {
  required SceneActionPayload payload,
  String? title,
  String? afterNodeId,
}) {
  if (payload.interactiveCommand == null || payload.consequence != null) {
    throw ArgumentError.value(
      payload,
      'payload',
      'Command Action authoring requires one interactive Scene command.',
    );
  }
  return _addSceneActionPayloadNodeDraft(
    scene,
    payload: payload,
    title: _trimOptional(title) ?? 'Commande interactive',
    afterNodeId: afterNodeId,
  );
}

SceneActionNodeDraftCreationResult _addSceneActionPayloadNodeDraft(
  SceneAsset scene, {
  required SceneActionPayload payload,
  required String title,
  String? afterNodeId,
}) {
  final nodeId = _uniqueNodeId(
    'node_action',
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: nodeId,
    kind: SceneNodeKind.action,
    title: title,
    payload: payload,
  );
  _validateNodeCapabilityForAuthoring(scene, createdNode);
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
  );

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneActionNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
    createdPayload: payload,
  );
}

SceneActionConsequencePayloadUpdateResult updateSceneActionConsequencePayload(
  SceneAsset scene, {
  required String nodeId,
  required SceneConsequence consequence,
}) {
  final trimmedNodeId = _trimRequired(
    nodeId,
    'nodeId',
    'Scene consequence editing requires an action node id.',
  );
  final node = _findNodeOrThrow(scene, trimmedNodeId, 'nodeId');
  if (node.kind != SceneNodeKind.action) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene consequence editing V0 can only update action nodes.',
    );
  }
  _validateSceneConsequenceForAuthoring(consequence);

  final currentPayload = node.payload;
  final updatedPayload = currentPayload is SceneActionPayload
      ? SceneActionPayload.consequence(
          consequence,
          actionKind: currentPayload.actionKind,
          parameters: currentPayload.parameters,
        )
      : SceneActionPayload.consequence(consequence);
  final updatedNode = SceneNode(
    id: node.id,
    kind: node.kind,
    title: node.title,
    description: node.description,
    payload: updatedPayload,
  );
  final updatedScene = _sceneWithUpdatedNode(scene, updatedNode);

  return SceneActionConsequencePayloadUpdateResult(
    updatedScene: updatedScene,
    updatedNode: updatedNode,
    updatedPayload: updatedPayload,
  );
}

SceneNodeLayoutUpdateResult updateSceneNodeLayout(
  SceneAsset scene, {
  required String nodeId,
  required double x,
  required double y,
}) {
  _findNodeOrThrow(scene, nodeId, 'nodeId');

  final updatedLayout = SceneNodeLayout(nodeId: nodeId, x: x, y: y);
  var replaced = false;
  final nodeLayouts = <SceneNodeLayout>[];
  for (final layout in scene.layout.nodeLayouts) {
    if (layout.nodeId == nodeId) {
      nodeLayouts.add(updatedLayout);
      replaced = true;
    } else {
      nodeLayouts.add(layout);
    }
  }
  if (!replaced) {
    nodeLayouts.add(updatedLayout);
  }

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: scene.graph,
    layout: SceneGraphLayout(
      nodeLayouts: nodeLayouts,
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeLayoutUpdateResult(
    updatedScene: updatedScene,
    updatedLayout: updatedLayout,
  );
}

SceneNodeDraftCreationResult addSceneNodeDraft(
  SceneAsset scene, {
  required SceneNodeKind kind,
  String? title,
  String? afterNodeId,
}) {
  if (!_isSupportedDraftNodeKind(kind)) {
    throw ArgumentError.value(
      kind,
      'kind',
      'Scene node kind ${kind.name} is not supported by Node Authoring V0.',
    );
  }

  final nodeId = _uniqueNodeId(
    _nodeIdBaseForKind(kind),
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: nodeId,
    kind: kind,
    title: _trimOptional(title) ?? _defaultTitleForKind(kind),
    payload: SceneNodePayload.emptyForKind(kind),
  );
  _validateNodeCapabilityForAuthoring(scene, createdNode);
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
  );

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
  );
}

SceneNodeDraftCreationResult duplicateSceneNodeDraft(
  SceneAsset scene,
  String nodeId,
) {
  final source = _findNodeOrThrow(
    scene,
    _trimRequired(
      nodeId,
      'nodeId',
      'Scene node duplication requires a node id.',
    ),
    'nodeId',
  );
  if (source.kind == SceneNodeKind.start) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      'Scene node kind ${source.kind.name} cannot be duplicated yet.',
    );
  }
  final nodeIdBase = switch (source.kind) {
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome =>
      _linkedAssetNodeIdBaseForKind(source.kind),
    SceneNodeKind.action => 'node_action',
    SceneNodeKind.condition ||
    SceneNodeKind.merge ||
    SceneNodeKind.end =>
      _nodeIdBaseForKind(source.kind),
    SceneNodeKind.start => throw StateError('Unsupported duplicate node kind.'),
  };
  final duplicatedNodeId = _uniqueNodeId(
    nodeIdBase,
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: duplicatedNodeId,
    kind: source.kind,
    title: source.title,
    description: source.description,
    payload: source.payload,
  );
  SceneNodeLayout? sourceLayout;
  for (final layout in scene.layout.nodeLayouts) {
    if (layout.nodeId == source.id) {
      sourceLayout = layout;
      break;
    }
  }
  final createdLayout = sourceLayout == null
      ? _layoutForNewNode(scene,
          nodeId: duplicatedNodeId, afterNodeId: source.id)
      : SceneNodeLayout(
          nodeId: duplicatedNodeId,
          x: sourceLayout.x + 32,
          y: sourceLayout.y + 32,
        );
  return SceneNodeDraftCreationResult(
    updatedScene: SceneAsset(
      id: scene.id,
      name: scene.name,
      executionProfile: scene.executionProfile,
      description: scene.description,
      storylineId: scene.storylineId,
      chapterId: scene.chapterId,
      tags: scene.tags,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: [...scene.graph.nodes, createdNode],
        edges: scene.graph.edges,
      ),
      layout: SceneGraphLayout(
        nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
        edgeLayouts: scene.layout.edgeLayouts,
      ),
      declaredOutcomes: scene.declaredOutcomes,
      metadata: scene.metadata,
    ),
    createdNode: createdNode,
  );
}

SceneNodeDraftCreationResult addSceneLinkedAssetNodeDraft(
  SceneAsset scene, {
  required SceneNodePayload payload,
  String? title,
  String? afterNodeId,
}) {
  if (!_isSupportedLinkedAssetPayloadKind(payload.kind)) {
    throw ArgumentError.value(
      payload.kind,
      'payload.kind',
      'Scene node kind ${payload.kind.name} is not supported by Payload '
          'Pickers V0.',
    );
  }

  final nodeId = _uniqueNodeId(
    _linkedAssetNodeIdBaseForKind(payload.kind),
    scene.graph.nodes.map((node) => node.id),
  );
  final createdNode = SceneNode(
    id: nodeId,
    kind: payload.kind,
    title:
        _trimOptional(title) ?? _defaultLinkedAssetTitleForKind(payload.kind),
    payload: payload,
  );
  _validateNodeCapabilityForAuthoring(scene, createdNode);
  final createdLayout = _layoutForNewNode(
    scene,
    nodeId: nodeId,
    afterNodeId: afterNodeId,
  );

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [...scene.graph.nodes, createdNode],
      edges: scene.graph.edges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [...scene.layout.nodeLayouts, createdLayout],
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftCreationResult(
    updatedScene: updatedScene,
    createdNode: createdNode,
  );
}

SceneEdgeDraftCreationResult addSceneEdgeDraft(
  SceneAsset scene, {
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
  String? label,
}) {
  final fromNode = _findNodeOrThrow(scene, fromNodeId, 'fromNodeId');
  _findNodeOrThrow(scene, toNodeId, 'toNodeId');

  if (fromNodeId == toNodeId) {
    throw ArgumentError.value(
      toNodeId,
      'toNodeId',
      'Self-loop edges are not supported by Edge Authoring V0.',
    );
  }

  final port = _authorableOutputPortOrThrow(
    fromNode,
    fromPortId,
    graph: scene.graph,
  );
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId) {
      throw ArgumentError.value(
        fromPortId,
        'fromPortId',
        'Edge Authoring V0 allows only one outgoing edge per source port.',
      );
    }
  }

  final createdEdge = SceneEdge(
    id: _uniqueEdgeId(
      _edgeIdBase(
        fromNodeId: fromNodeId,
        fromPortId: fromPortId,
        toNodeId: toNodeId,
      ),
      scene.graph.edges.map((edge) => edge.id),
    ),
    fromNodeId: fromNodeId,
    fromPortId: fromPortId,
    toNodeId: toNodeId,
    kind: port.edgeKind,
    label: _trimOptional(label) ?? port.label,
  );

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: scene.graph.nodes,
      edges: [...scene.graph.edges, createdEdge],
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneEdgeDraftCreationResult(
    updatedScene: updatedScene,
    createdEdge: createdEdge,
  );
}

SceneEdgeDraftRemovalResult removeSceneEdgeDraft(
  SceneAsset scene,
  String edgeId,
) {
  SceneEdge? removedEdge;
  final remainingEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    if (edge.id == edgeId) {
      removedEdge = edge;
    } else {
      remainingEdges.add(edge);
    }
  }
  final edge = removedEdge;
  if (edge == null) {
    throw ArgumentError.value(
      edgeId,
      'edgeId',
      'Scene edge draft references an unknown edge.',
    );
  }

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: scene.graph.nodes,
      edges: remainingEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: scene.layout.nodeLayouts,
      edgeLayouts: [
        for (final layout in scene.layout.edgeLayouts)
          if (layout.edgeId != edgeId) layout,
      ],
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneEdgeDraftRemovalResult(
    updatedScene: updatedScene,
    removedEdge: edge,
  );
}

SceneNodeDraftRemovalResult removeSceneNodeDraft(
  SceneAsset scene,
  String nodeId,
) {
  final trimmedNodeId = _trimRequired(
    nodeId,
    'nodeId',
    'Scene node deletion requires a node id.',
  );
  final removedNode = _findNodeOrThrow(scene, trimmedNodeId, 'nodeId');
  final removalBlocker = sceneNodeDraftRemovalBlocker(
    scene.graph,
    removedNode,
  );
  if (removalBlocker != null || !isSceneNodeDraftRemovable(removedNode)) {
    throw ArgumentError.value(
      nodeId,
      'nodeId',
      removalBlocker ??
          'Scene node kind ${removedNode.kind.name} cannot be removed by Node Authoring V0.',
    );
  }

  final removedEdges = <SceneEdge>[];
  final remainingEdges = <SceneEdge>[];
  for (final edge in scene.graph.edges) {
    if (edge.fromNodeId == trimmedNodeId || edge.toNodeId == trimmedNodeId) {
      removedEdges.add(edge);
    } else {
      remainingEdges.add(edge);
    }
  }
  final removedEdgeIds = removedEdges.map((edge) => edge.id).toSet();

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          if (node.id != trimmedNodeId) node,
      ],
      edges: remainingEdges,
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (final layout in scene.layout.nodeLayouts)
          if (layout.nodeId != trimmedNodeId) layout,
      ],
      edgeLayouts: [
        for (final layout in scene.layout.edgeLayouts)
          if (!removedEdgeIds.contains(layout.edgeId)) layout,
      ],
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeDraftRemovalResult(
    updatedScene: updatedScene,
    removedNode: removedNode,
    removedEdges: List<SceneEdge>.unmodifiable(removedEdges),
  );
}

void _validateConditionSourceForV0(SceneConditionSource source) {
  switch (source.sourceKind) {
    case SceneConditionSourceKind.fact:
      if (source.expectedFactValue != null) {
        if (!source.expectedFactValue!.kind.compatibleOperators
            .contains(source.factOperator)) {
          throw ArgumentError.value(
            source.factOperator,
            'source.factOperator',
            'is incompatible with the authored Fact value.',
          );
        }
        return;
      }
      if (source.operator != SceneConditionOperator.isTrue &&
          source.operator != SceneConditionOperator.isFalse) {
        throw ArgumentError.value(
          source.operator,
          'source.operator',
          'Fact supports isTrue/isFalse or a typed comparison.',
        );
      }
      if (_trimOptional(source.value) != null) {
        throw ArgumentError.value(
          source.value,
          'source.value',
          'A boolean Fact must not carry a legacy comparison value.',
        );
      }
      return;
    case SceneConditionSourceKind.factLikeStoryFlag:
    case SceneConditionSourceKind.consumedEvent:
      if (source.operator != SceneConditionOperator.isTrue &&
          source.operator != SceneConditionOperator.isFalse) {
        throw ArgumentError.value(
          source.operator,
          'source.operator',
          '${source.sourceKind.name} supports only isTrue/isFalse in '
              'Condition Authoring V0.',
        );
      }
      if (_trimOptional(source.value) != null) {
        throw ArgumentError.value(
          source.value,
          'source.value',
          '${source.sourceKind.name} must not carry a comparison value in '
              'Condition Authoring V0.',
        );
      }
      return;
    case SceneConditionSourceKind.storyStepCompletion:
      if (source.operator != SceneConditionOperator.equals) {
        throw ArgumentError.value(
          source.operator,
          'source.operator',
          'storyStepCompletion supports only equals in Condition Authoring V0.',
        );
      }
      final value = source.value;
      if (value != SceneConditionValues.completed &&
          value != SceneConditionValues.notCompleted) {
        throw ArgumentError.value(
          source.value,
          'source.value',
          'storyStepCompletion value must be completed or notCompleted.',
        );
      }
      return;
    case SceneConditionSourceKind.storyStepActive:
    case SceneConditionSourceKind.inventoryItem:
    case SceneConditionSourceKind.partyState:
    case SceneConditionSourceKind.trainerDefeated:
    case SceneConditionSourceKind.dialogueOutcome:
    case SceneConditionSourceKind.battleOutcome:
    case SceneConditionSourceKind.scriptVariable:
    case SceneConditionSourceKind.worldState:
      throw ArgumentError.value(
        source.sourceKind,
        'source.sourceKind',
        'Condition source kind ${source.sourceKind.name} is not supported by '
            'Condition Authoring V0.',
      );
  }
}

void _validateSceneConsequenceForAuthoring(SceneConsequence consequence) {
  switch (consequence) {
    case SceneSetFactConsequence():
      _trimRequired(
        consequence.factId,
        'consequence.factId',
        'setFact consequence requires a fact id.',
      );
    case SceneMarkEventConsumedConsequence():
      _trimRequired(
        consequence.mapId,
        'consequence.mapId',
        'markEventConsumed consequence requires a map id.',
      );
      _trimRequired(
        consequence.eventId,
        'consequence.eventId',
        'markEventConsumed consequence requires an event id.',
      );
    case SceneCompleteStoryStepConsequence():
      _trimRequired(
        consequence.stepId,
        'consequence.stepId',
        'completeStoryStep consequence requires a Story Step id.',
      );
    case SceneGiveItemConsequence():
      _validateItemConsequenceForAuthoring(
        itemId: consequence.itemId,
        quantity: consequence.quantity,
        kind: 'giveItem',
      );
    case SceneTakeItemConsequence():
      _validateItemConsequenceForAuthoring(
        itemId: consequence.itemId,
        quantity: consequence.quantity,
        kind: 'takeItem',
      );
    case SceneGiveMoneyConsequence():
      if (consequence.amount <= 0) {
        throw ArgumentError.value(
          consequence.amount,
          'consequence.amount',
          'giveMoney consequence requires a positive amount.',
        );
      }
    case SceneGivePokemonConsequence():
      _trimRequired(
        consequence.speciesId,
        'consequence.speciesId',
        'givePokemon consequence requires a species id.',
      );
      _trimRequired(
        consequence.natureId,
        'consequence.natureId',
        'givePokemon consequence requires a nature id.',
      );
      _trimRequired(
        consequence.abilityId,
        'consequence.abilityId',
        'givePokemon consequence requires an ability id.',
      );
      if (consequence.level < 1 || consequence.level > 100) {
        throw ArgumentError.value(
          consequence.level,
          'consequence.level',
          'givePokemon consequence level must be between 1 and 100.',
        );
      }
      if (consequence.currentHp <= 0) {
        throw ArgumentError.value(
          consequence.currentHp,
          'consequence.currentHp',
          'givePokemon consequence currentHp must be positive.',
        );
      }
    case SceneGiveConfiguredStarterConsequence():
      _trimRequired(
        consequence.starterOptionId,
        'consequence.starterOptionId',
        'giveConfiguredStarter consequence requires a New Game starter option.',
      );
    case SceneSetNpcPresenceConsequence():
      _trimRequired(
        consequence.mapId,
        'consequence.mapId',
        'setNpcPresence consequence requires a map id.',
      );
      _trimRequired(
        consequence.entityId,
        'consequence.entityId',
        'setNpcPresence consequence requires an NPC id.',
      );
    case SceneHealPartyConsequence():
    case SceneAwardBadgeConsequence():
    case SceneUnlockFieldAbilityConsequence():
    case SceneFinishGameConsequence():
      break;
  }
}

void _validateItemConsequenceForAuthoring({
  required String itemId,
  required int quantity,
  required String kind,
}) {
  _trimRequired(
    itemId,
    'consequence.itemId',
    '$kind consequence requires an item id.',
  );
  if (quantity <= 0) {
    throw ArgumentError.value(
      quantity,
      'consequence.quantity',
      '$kind consequence requires a positive quantity.',
    );
  }
}

const Object _sceneLibraryUnset = Object();

SceneLibraryMutationResult _setSceneArchived(
  ProjectManifest project, {
  required String sceneId,
  required bool archived,
}) {
  final source = _findScene(project, sceneId);
  if (source == null) {
    return _sceneLibraryRejected(
      project,
      code: 'sceneNotFound',
      message: 'The SceneAsset to update does not exist.',
    );
  }
  final metadata = Map<String, String>.from(source.metadata);
  if (archived) {
    metadata[sceneLibraryArchivedMetadataKey] = 'true';
  } else {
    metadata.remove(sceneLibraryArchivedMetadataKey);
  }
  return _replaceScene(
    project,
    source,
    _copySceneAsset(source, metadata: metadata),
  );
}

SceneLibraryMutationResult _replaceScene(
  ProjectManifest project,
  SceneAsset source,
  SceneAsset replacement,
) {
  if (source == replacement) {
    return SceneLibraryMutationResult(
      before: project,
      after: project,
      disposition: SceneLibraryMutationDisposition.noChange,
      scene: source,
      previousScene: source,
    );
  }
  return _sceneLibraryApplied(
    project,
    project.copyWith(
      scenes: [
        for (final scene in project.scenes)
          if (scene.id == source.id) replacement else scene,
      ],
    ),
    scene: replacement,
    previousScene: source,
  );
}

SceneLibraryMutationResult _sceneLibraryApplied(
  ProjectManifest before,
  ProjectManifest after, {
  SceneAsset? scene,
  SceneAsset? previousScene,
  List<String> referencePaths = const <String>[],
}) {
  return SceneLibraryMutationResult(
    before: before,
    after: after,
    disposition: SceneLibraryMutationDisposition.applied,
    scene: scene,
    previousScene: previousScene,
    referencePaths: referencePaths,
  );
}

SceneLibraryMutationResult _sceneLibraryRejected(
  ProjectManifest project, {
  required String code,
  required String message,
  SceneAsset? previousScene,
  List<String> referencePaths = const <String>[],
}) {
  return SceneLibraryMutationResult(
    before: project,
    after: project,
    disposition: SceneLibraryMutationDisposition.rejected,
    previousScene: previousScene,
    code: code,
    message: message,
    referencePaths: referencePaths,
  );
}

SceneAsset? _findScene(ProjectManifest project, String sceneId) {
  final normalizedId = sceneId.trim();
  for (final scene in project.scenes) {
    if (scene.id == normalizedId) return scene;
  }
  return null;
}

SceneAsset _copySceneAsset(
  SceneAsset source, {
  String? id,
  String? name,
  Object? description = _sceneLibraryUnset,
  Object? storylineId = _sceneLibraryUnset,
  Object? chapterId = _sceneLibraryUnset,
  List<String>? tags,
  SceneGraph? graph,
  SceneGraphLayout? layout,
  List<SceneOutcome>? declaredOutcomes,
  Map<String, String>? metadata,
}) {
  return SceneAsset(
    id: id ?? source.id,
    name: name ?? source.name,
    executionProfile: source.executionProfile,
    description: identical(description, _sceneLibraryUnset)
        ? source.description
        : description as String?,
    storylineId: identical(storylineId, _sceneLibraryUnset)
        ? source.storylineId
        : storylineId as String?,
    chapterId: identical(chapterId, _sceneLibraryUnset)
        ? source.chapterId
        : chapterId as String?,
    tags: tags ?? source.tags,
    graph: graph ?? source.graph,
    layout: layout ?? source.layout,
    declaredOutcomes: declaredOutcomes ?? source.declaredOutcomes,
    metadata: metadata ?? source.metadata,
  );
}

SceneAsset _duplicateSceneAsset(
  SceneAsset source, {
  required String duplicateId,
  required String name,
}) {
  final sourceNodeIds = source.graph.nodes.map((node) => node.id).toSet();
  final generatedNodeIds = <String>{};
  final nodeIds = <String, String>{};
  for (final node in source.graph.nodes) {
    final id = _uniqueNodeId(
      '${node.id}_copy',
      {...sourceNodeIds, ...generatedNodeIds},
    );
    nodeIds[node.id] = id;
    generatedNodeIds.add(id);
  }

  final sourceEdgeIds = source.graph.edges.map((edge) => edge.id).toSet();
  final generatedEdgeIds = <String>{};
  final edgeIds = <String, String>{};
  for (final edge in source.graph.edges) {
    final id = _uniqueEdgeId(
      '${edge.id}_copy',
      {...sourceEdgeIds, ...generatedEdgeIds},
    );
    edgeIds[edge.id] = id;
    generatedEdgeIds.add(id);
  }

  final graph = SceneGraph(
    startNodeId: nodeIds[source.graph.startNodeId]!,
    nodes: [
      for (final node in source.graph.nodes)
        SceneNode(
          id: nodeIds[node.id]!,
          kind: node.kind,
          title: node.title,
          description: node.description,
          payload: node.payload,
        ),
    ],
    edges: [
      for (final edge in source.graph.edges)
        SceneEdge(
          id: edgeIds[edge.id]!,
          fromNodeId: nodeIds[edge.fromNodeId]!,
          fromPortId: edge.fromPortId,
          toNodeId: nodeIds[edge.toNodeId]!,
          kind: edge.kind,
          label: edge.label,
        ),
    ],
  );
  final layout = SceneGraphLayout(
    nodeLayouts: [
      for (final item in source.layout.nodeLayouts)
        SceneNodeLayout(
          nodeId: nodeIds[item.nodeId]!,
          x: item.x,
          y: item.y,
        ),
    ],
    edgeLayouts: [
      for (final item in source.layout.edgeLayouts)
        SceneEdgeLayout(
          edgeId: edgeIds[item.edgeId]!,
          controlPoints: item.controlPoints,
        ),
    ],
  );
  final metadata = Map<String, String>.from(source.metadata)
    ..remove(sceneLibraryArchivedMetadataKey);
  return _copySceneAsset(
    source,
    id: duplicateId,
    name: name,
    graph: graph,
    layout: layout,
    metadata: metadata,
  );
}

bool _isManifestSceneConsumerPath(String path) {
  if (path == 'newGame.preSessionSceneId') return true;
  if (path.startsWith('eventRegistry.records[') && path.endsWith('.sceneId')) {
    return true;
  }
  if (!path.startsWith('storylines[')) return false;
  return path.contains('.directSceneLinkIds[') ||
      path.contains('.sceneLinkIds[');
}

ProjectManifest _replaceSceneConsumers(
  ProjectManifest project, {
  required String sourceSceneId,
  required String replacementSceneId,
}) {
  final registry = project.eventRegistry;
  final updatedRegistry = registry == null
      ? null
      : NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: [
            for (final record in registry.records)
              _replaceSceneInEventRecord(
                record,
                sourceSceneId: sourceSceneId,
                replacementSceneId: replacementSceneId,
              ),
          ],
          legacyClaims: registry.legacyClaims,
        );
  final updatedStorylines = [
    for (final storyline in project.storylines)
      storyline.copyWith(
        chapters: [
          for (final chapter in storyline.chapters)
            chapter.copyWith(
              directSceneLinkIds: _replaceUniqueSceneIds(
                chapter.directSceneLinkIds,
                sourceSceneId: sourceSceneId,
                replacementSceneId: replacementSceneId,
              ),
              steps: [
                for (final step in chapter.steps)
                  step.copyWith(
                    sceneLinkIds: _replaceUniqueSceneIds(
                      step.sceneLinkIds,
                      sourceSceneId: sourceSceneId,
                      replacementSceneId: replacementSceneId,
                    ),
                  ),
              ],
            ),
        ],
      ),
  ];
  final newGame = project.newGame;
  final updatedNewGame = ProjectNewGameConfig(
    enabled: newGame.enabled,
    startMapId: newGame.startMapId,
    startSpawnId: newGame.startSpawnId,
    playerName: newGame.playerName,
    playerAvatarCharacterIds: newGame.playerAvatarCharacterIds,
    playerPronounSet: newGame.playerPronounSet,
    startingMoney: newGame.startingMoney,
    initialBag: newGame.initialBag,
    initialParty: newGame.initialParty,
    initialFacts: newGame.initialFacts,
    initialFactValues: newGame.initialFactValues,
    existingPartyFactId: newGame.existingPartyFactId,
    preSessionSceneId: newGame.preSessionSceneId == sourceSceneId
        ? replacementSceneId
        : newGame.preSessionSceneId,
    starterOptions: newGame.starterOptions,
  );
  return project.copyWith(
    eventRegistry: updatedRegistry,
    storylines: updatedStorylines,
    newGame: updatedNewGame,
  );
}

NarrativeEventRecord _replaceSceneInEventRecord(
  NarrativeEventRecord record, {
  required String sourceSceneId,
  required String replacementSceneId,
}) {
  return record.when(
    draft: (draft) => NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: draft.id,
        name: draft.name,
        source: draft.source,
        conditions: draft.conditions,
        conditionExpression: draft.conditionExpression,
        sceneId:
            draft.sceneId == sourceSceneId ? replacementSceneId : draft.sceneId,
        reusePolicy: draft.reusePolicy,
        priority: draft.priority,
        order: draft.order,
        resetPolicy: draft.resetPolicy,
      ),
    ),
    configured: (definition, enabled) =>
        NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: definition.id,
        name: definition.name,
        source: definition.source,
        conditions: definition.conditions,
        conditionExpression: definition.conditionExpression,
        sceneId: definition.sceneId == sourceSceneId
            ? replacementSceneId
            : definition.sceneId,
        reusePolicy: definition.reusePolicy,
        priority: definition.priority,
        order: definition.order,
        resetPolicy: definition.resetPolicy,
      ),
      enabled: enabled,
    ),
  );
}

List<String> _replaceUniqueSceneIds(
  List<String> sceneIds, {
  required String sourceSceneId,
  required String replacementSceneId,
}) {
  final seen = <String>{};
  return [
    for (final sceneId in sceneIds)
      if (seen.add(
        sceneId == sourceSceneId ? replacementSceneId : sceneId,
      ))
        sceneId == sourceSceneId ? replacementSceneId : sceneId,
  ];
}

SceneAsset _createSceneDraft({
  required String id,
  required String name,
  String? description,
}) {
  return SceneAsset(
    id: id,
    name: name,
    description: description,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(
          id: 'node_start',
          kind: SceneNodeKind.start,
          title: 'Début',
        ),
        SceneNode(
          id: 'node_end',
          kind: SceneNodeKind.end,
          title: 'Fin',
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
        SceneNodeLayout(nodeId: 'node_end', x: 320, y: 80),
      ],
    ),
  );
}

SceneNode _findNodeOrThrow(
  SceneAsset scene,
  String nodeId,
  String argumentName,
) {
  for (final node in scene.graph.nodes) {
    if (node.id == nodeId) {
      return node;
    }
  }
  throw ArgumentError.value(
    nodeId,
    argumentName,
    'Scene edge draft references an unknown node.',
  );
}

CinematicAsset _canonicalCinematicOrThrow(
  ProjectManifest project,
  String cinematicId,
  String argumentName,
) {
  final normalizedCinematicId = _trimRequired(
    cinematicId,
    argumentName,
    'Canonical CinematicAsset id is required by Scene cinematic authoring V0.',
  );
  for (final cinematic in project.cinematics) {
    if (cinematic.id == normalizedCinematicId) {
      return cinematic;
    }
  }
  throw ArgumentError.value(
    cinematicId,
    argumentName,
    'Scene cinematic authoring V0 requires an existing canonical '
    'CinematicAsset. Scenario bridges are read-only legacy references.',
  );
}

SceneAuthorableOutputPort _authorableOutputPortOrThrow(
  SceneNode node,
  String fromPortId, {
  SceneGraph? graph,
}) {
  final ports = graph == null
      ? authorableSceneOutputPortsForNode(node)
      : authorableSceneOutputPortsForNodeInGraph(node, graph);
  for (final port in ports) {
    if (port.id == fromPortId) {
      return port;
    }
  }
  throw ArgumentError.value(
    fromPortId,
    'fromPortId',
    'Port $fromPortId is not supported for ${node.kind.name} '
        'by Edge Authoring V0.',
  );
}

String _uniqueSceneId(String name, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final base = 'scene_${_slugify(name)}';
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _uniqueNodeId(String base, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _uniqueEdgeId(String base, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

SceneAsset _sceneWithUpdatedNode(SceneAsset scene, SceneNode updatedNode) {
  final updatedNodes = [
    for (final candidate in scene.graph.nodes)
      if (candidate.id == updatedNode.id) updatedNode else candidate,
  ];
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: updatedNodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

String _edgeIdBase({
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
}) {
  return 'edge_${_sanitizeEdgeIdPart(fromNodeId)}_'
      '${_sanitizeEdgeIdPart(fromPortId)}_'
      '${_sanitizeEdgeIdPart(toNodeId)}';
}

String _sanitizeEdgeIdPart(String value) {
  final slug = _slugify(value);
  return slug.isEmpty ? 'id' : slug;
}

void _validateNodeCapabilityForAuthoring(
  SceneAsset scene,
  SceneNode node,
) {
  final capabilityId = sceneExecutionCapabilityForNode(
    scene.executionProfile,
    node,
  );
  final decision = sceneExecutionCapabilityMatrix.evaluate(
    profile: scene.executionProfile,
    capabilityId: capabilityId,
  );
  if (!decision.isAllowed) {
    throw ArgumentError.value(
      node.kind,
      'kind',
      '${decision.issueCode!.wireName}: profile '
          '${scene.executionProfile.name} refuses $capabilityId.',
    );
  }
}

bool _isSupportedDraftNodeKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition || SceneNodeKind.merge || SceneNodeKind.end => true,
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome =>
      false,
  };
}

bool _isSupportedLinkedAssetPayloadKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome =>
      true,
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.merge =>
      false,
  };
}

String _nodeIdBaseForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition => 'node_condition',
    SceneNodeKind.merge => 'node_merge',
    SceneNodeKind.end => 'node_end',
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome =>
      throw ArgumentError.value(kind, 'kind', 'Unsupported draft node kind.'),
  };
}

String _linkedAssetNodeIdBaseForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue => 'node_yarn_dialogue',
    SceneNodeKind.battle => 'node_battle',
    SceneNodeKind.cinematic => 'node_cinematic',
    SceneNodeKind.presentationCinematic => 'node_presentation_cinematic',
    SceneNodeKind.branchByOutcome => 'node_branch',
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.merge =>
      throw ArgumentError.value(
        kind,
        'kind',
        'Unsupported linked asset node kind.',
      ),
  };
}

String _defaultTitleForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.merge => 'Merge',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.start ||
    SceneNodeKind.yarnDialogue ||
    SceneNodeKind.action ||
    SceneNodeKind.battle ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.presentationCinematic ||
    SceneNodeKind.branchByOutcome =>
      throw ArgumentError.value(kind, 'kind', 'Unsupported draft node kind.'),
  };
}

String _defaultLinkedAssetTitleForKind(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.yarnDialogue => 'Dialogue',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.presentationCinematic => 'Cinématique de présentation',
    SceneNodeKind.branchByOutcome => 'Branche par résultat',
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.condition ||
    SceneNodeKind.action ||
    SceneNodeKind.merge =>
      throw ArgumentError.value(
        kind,
        'kind',
        'Unsupported linked asset node kind.',
      ),
  };
}

String _defaultConsequenceActionTitle(SceneConsequence consequence) {
  return switch (consequence) {
    SceneSetFactConsequence() => 'Définir un Fact',
    SceneMarkEventConsumedConsequence() => 'Marquer event consommé',
    SceneCompleteStoryStepConsequence() => 'Terminer une étape narrative',
    SceneGiveItemConsequence() => 'Donner un objet',
    SceneTakeItemConsequence() => 'Retirer un objet',
    SceneGiveMoneyConsequence() => 'Donner de l’argent',
    SceneGivePokemonConsequence() => 'Donner un Pokémon',
    SceneGiveConfiguredStarterConsequence() => 'Donner un starter configuré',
    SceneSetNpcPresenceConsequence() => 'Modifier la présence d’un PNJ',
    _ => 'Conséquence',
  };
}

SceneNodeLayout _layoutForNewNode(
  SceneAsset scene, {
  required String nodeId,
  String? afterNodeId,
}) {
  final layouts = scene.layout.nodeLayouts;
  SceneNodeLayout? source;
  if (afterNodeId != null) {
    for (final layout in layouts) {
      if (layout.nodeId == afterNodeId) {
        source = layout;
        break;
      }
    }
  }

  source ??= _rightMostLayout(layouts);
  if (source != null) {
    return SceneNodeLayout(
      nodeId: nodeId,
      x: source.x + 300,
      y: source.y,
    );
  }

  return SceneNodeLayout(
    nodeId: nodeId,
    x: 24 + scene.graph.nodes.length * 300,
    y: 80,
  );
}

SceneNodeLayout? _rightMostLayout(List<SceneNodeLayout> layouts) {
  if (layouts.isEmpty) {
    return null;
  }
  var rightMost = layouts.first;
  for (final layout in layouts.skip(1)) {
    if (layout.x > rightMost.x) {
      rightMost = layout;
    }
  }
  return rightMost;
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final codeUnit in lower.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

String _trimRequired(
  String value,
  String argumentName,
  String message,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, argumentName, message);
  }
  return trimmed;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
