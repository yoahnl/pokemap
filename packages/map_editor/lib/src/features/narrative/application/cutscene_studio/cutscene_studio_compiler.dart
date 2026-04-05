// Cutscene Studio — compile [CutsceneStudioDocument] → [ScenarioAsset].
//
// Utilise [effectiveCutsceneFlowForDocument] ; écrit le flow dans les metadata via
// [encodeCutsceneFlowMetadata]. Fusions = [kCutsceneStudioActionFlowMerge] ;
// stubs = [kCutsceneStudioActionAuthoringPlaceholder] (pas de wait factice).

import 'package:map_core/map_core.dart';

import 'cutscene_studio_flow_codec.dart';
import 'cutscene_studio_flow.dart';
import 'cutscene_studio_models.dart';

/// Compile la représentation studio vers le format canonique `ScenarioAsset`.
///
/// Contrat du compilateur:
/// - si [CutsceneStudioDocument.cutsceneFlow] est non null → graphe avec
///   `choice` + nœuds de fusion [kCutsceneStudioActionFlowMerge] (sans `waitMs`);
/// - sinon → graphe linéaire historique à partir de [CutsceneStudioDocument.blocks];
/// - sérialise toujours l’arbre d’authoring dans les métadonnées pour reprise UI;
/// - les blocs sans runtime MVP réel → [kCutsceneStudioActionAuthoringPlaceholder]
///   (jamais de `waitMs` factice).
ScenarioAsset buildScenarioFromCutsceneStudioDocument(
  CutsceneStudioDocument document, {
  ScenarioAsset? previousScenario,
}) {
  const startNodeId = 'start';
  const sourceNodeId = 'source';
  const endNodeId = 'end';

  final flow = effectiveCutsceneFlowForDocument(document);
  final declaredOutcomes = <String>{};
  _collectDeclaredOutcomesFromFlow(flow, declaredOutcomes);

  final nodes = <ScenarioNode>[
    const ScenarioNode(
      id: startNodeId,
      type: ScenarioNodeType.start,
      title: 'Start',
    ),
    ScenarioNode(
      id: sourceNodeId,
      type: ScenarioNodeType.reference,
      title: 'Source',
      payload: ScenarioNodePayload(
        actionKind: _sourceActionKind(document.source.kind),
      ),
      binding: ScenarioNodeBinding(
        mapId: cutsceneStudioTrimOrNull(document.source.mapId),
        triggerId: cutsceneStudioTrimOrNull(document.source.triggerId),
        entityId: cutsceneStudioTrimOrNull(document.source.entityId),
      ),
    ),
    const ScenarioNode(
      id: endNodeId,
      type: ScenarioNodeType.end,
      title: 'End',
    ),
  ];
  final edges = <ScenarioEdge>[
    const ScenarioEdge(
      id: 'edge_start_source',
      fromNodeId: startNodeId,
      toNodeId: sourceNodeId,
      kind: ScenarioEdgeKind.next,
      order: 0,
    ),
  ];

  final compiler = _CutsceneFlowGraphCompiler(
    nodes: nodes,
    edges: edges,
  );
  compiler.compileMainSequence(
    sourceNodeId: sourceNodeId,
    endNodeId: endNodeId,
    flow: flow,
  );

  final previousMetadata =
      previousScenario?.metadata ?? const <String, String>{};
  final metadata = <String, String>{
    ...previousMetadata,
    kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
    kCutsceneStudioFlowMetadataKey: encodeCutsceneFlowMetadata(flow),
  };

  return ScenarioAsset(
    id: document.id.trim(),
    name: document.name.trim(),
    description: document.description.trim(),
    scope: ScenarioScope.localEventFlow,
    entryNodeId: startNodeId,
    declaredOutcomes: declaredOutcomes.toList(growable: false),
    activationCondition: previousScenario?.activationCondition,
    nodes: nodes,
    edges: edges,
    metadata: metadata,
  );
}

void _collectDeclaredOutcomesFromFlow(
  List<CutsceneFlowEntry> flow,
  Set<String> declaredOutcomes,
) {
  for (final entry in flow) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        if (block.kind == CutsceneStudioBlockKind.emitOutcome ||
            block.kind == CutsceneStudioBlockKind.sceneResult) {
          final outcome = cutsceneStudioResolveOutcomeIdForResultBlock(block);
          if (outcome != null && outcome.isNotEmpty) {
            declaredOutcomes.add(outcome);
          }
        }
      case CutsceneFlowChoiceEntry(:final onYes, :final onNo):
        _collectDeclaredOutcomesFromFlow(onYes, declaredOutcomes);
        _collectDeclaredOutcomesFromFlow(onNo, declaredOutcomes);
    }
  }
}

class _CutsceneFlowGraphCompiler {
  _CutsceneFlowGraphCompiler({
    required this.nodes,
    required this.edges,
  });

  final List<ScenarioNode> nodes;
  final List<ScenarioEdge> edges;

  var _edgeSeq = 1;
  var _mergeSeq = 0;

  String _nextEdgeId() => 'edge_${_edgeSeq++}';

  void compileMainSequence({
    required String sourceNodeId,
    required String endNodeId,
    required List<CutsceneFlowEntry> flow,
  }) {
    var previousId = sourceNodeId;
    for (final entry in flow) {
      previousId = _compileMainEntry(previousId, entry);
    }
    edges.add(
      ScenarioEdge(
        id: _nextEdgeId(),
        fromNodeId: previousId,
        toNodeId: endNodeId,
        kind: ScenarioEdgeKind.next,
        order: 0,
      ),
    );
  }

  String _compileMainEntry(String previousId, CutsceneFlowEntry entry) {
    switch (entry) {
      case CutsceneFlowBlockEntry(:final block):
        if (block.kind == CutsceneStudioBlockKind.playerQuestion) {
          return _compileInlinePlayerQuestion(previousId, block);
        }
        final nodeId = cutsceneStudioNormalizeNodeId(block.id, fallback: 'block_${_edgeSeq}');
        nodes.insert(
          nodes.length - 1,
          _buildNodeForBlock(block, nodeId: nodeId),
        );
        edges.add(
          ScenarioEdge(
            id: _nextEdgeId(),
            fromNodeId: previousId,
            toNodeId: nodeId,
            kind: ScenarioEdgeKind.next,
            order: 0,
          ),
        );
        return nodeId;
      case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
        final choiceId = cutsceneStudioNormalizeNodeId(
          question.id,
          fallback: 'choice_${_edgeSeq}',
        );
        nodes.insert(
          nodes.length - 1,
          _buildChoiceScenarioNode(question, choiceId),
        );
        edges.add(
          ScenarioEdge(
            id: _nextEdgeId(),
            fromNodeId: previousId,
            toNodeId: choiceId,
            kind: ScenarioEdgeKind.next,
            order: 0,
          ),
        );
        final mergeId = _addMergeNode();
        _compileChoiceBranch(choiceId, 0, _choiceOptionLabel(question, 0),
            onYes, mergeId);
        _compileChoiceBranch(choiceId, 1, _choiceOptionLabel(question, 1),
            onNo, mergeId);
        return mergeId;
    }
  }

  String _compileInlinePlayerQuestion(
    String previousId,
    CutsceneStudioBlock block,
  ) {
    final choiceId =
        cutsceneStudioNormalizeNodeId(block.id, fallback: 'choice_${_edgeSeq}');
    nodes.insert(
      nodes.length - 1,
      _buildChoiceScenarioNode(block, choiceId),
    );
    edges.add(
      ScenarioEdge(
        id: _nextEdgeId(),
        fromNodeId: previousId,
        toNodeId: choiceId,
        kind: ScenarioEdgeKind.next,
        order: 0,
      ),
    );
    final mergeId = _addMergeNode();
    _compileChoiceBranch(choiceId, 0, _choiceOptionLabel(block, 0),
        const <CutsceneFlowEntry>[], mergeId);
    _compileChoiceBranch(choiceId, 1, _choiceOptionLabel(block, 1),
        const <CutsceneFlowEntry>[], mergeId);
    return mergeId;
  }

  String _addMergeNode() {
    final id = 'merge_${_mergeSeq++}';
    nodes.insert(
      nodes.length - 1,
      ScenarioNode(
        id: id,
        type: ScenarioNodeType.action,
        title: 'Fusion branches',
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionFlowMerge,
        ),
        metadata: const <String, String>{
          kCutsceneStudioStructuralMetadataKey: 'flowMerge',
        },
      ),
    );
    return id;
  }

  void _compileChoiceBranch(
    String choiceNodeId,
    int order,
    String label,
    List<CutsceneFlowEntry> branch,
    String mergeNodeId,
  ) {
    if (branch.isEmpty) {
      edges.add(
        ScenarioEdge(
          id: _nextEdgeId(),
          fromNodeId: choiceNodeId,
          toNodeId: mergeNodeId,
          kind: ScenarioEdgeKind.choice,
          order: order,
          label: label,
        ),
      );
      return;
    }
    String? branchPrev;
    var first = true;
    for (final sub in branch) {
      switch (sub) {
        case CutsceneFlowBlockEntry(:final block):
          if (block.kind == CutsceneStudioBlockKind.playerQuestion) {
            branchPrev = _compileNestedPlayerQuestionInBranch(
              choiceNodeId,
              order,
              label,
              branchPrev,
              first,
              block,
            );
            first = false;
            continue;
          }
          final nid = cutsceneStudioNormalizeNodeId(block.id, fallback: 'block_${_edgeSeq}');
          nodes.insert(
            nodes.length - 1,
            _buildNodeForBlock(block, nodeId: nid),
          );
          if (first) {
            edges.add(
              ScenarioEdge(
                id: _nextEdgeId(),
                fromNodeId: choiceNodeId,
                toNodeId: nid,
                kind: ScenarioEdgeKind.choice,
                order: order,
                label: label,
              ),
            );
          } else {
            edges.add(
              ScenarioEdge(
                id: _nextEdgeId(),
                fromNodeId: branchPrev!,
                toNodeId: nid,
                kind: ScenarioEdgeKind.next,
                order: 0,
              ),
            );
          }
          branchPrev = nid;
          first = false;
        case CutsceneFlowChoiceEntry(:final question, :final onYes, :final onNo):
          final cid = cutsceneStudioNormalizeNodeId(
            question.id,
            fallback: 'choice_${_edgeSeq}',
          );
          nodes.insert(
            nodes.length - 1,
            _buildChoiceScenarioNode(question, cid),
          );
          if (first) {
            edges.add(
              ScenarioEdge(
                id: _nextEdgeId(),
                fromNodeId: choiceNodeId,
                toNodeId: cid,
                kind: ScenarioEdgeKind.choice,
                order: order,
                label: label,
              ),
            );
          } else {
            edges.add(
              ScenarioEdge(
                id: _nextEdgeId(),
                fromNodeId: branchPrev!,
                toNodeId: cid,
                kind: ScenarioEdgeKind.next,
                order: 0,
              ),
            );
          }
          final innerMerge = _addMergeNode();
          _compileChoiceBranch(
              cid, 0, _choiceOptionLabel(question, 0), onYes, innerMerge);
          _compileChoiceBranch(
              cid, 1, _choiceOptionLabel(question, 1), onNo, innerMerge);
          branchPrev = innerMerge;
          first = false;
      }
    }
    edges.add(
      ScenarioEdge(
        id: _nextEdgeId(),
        fromNodeId: branchPrev!,
        toNodeId: mergeNodeId,
        kind: ScenarioEdgeKind.next,
        order: 0,
      ),
    );
  }

  /// Gère un bloc « question » mal placé dans une branche (peu probable en UI).
  String _compileNestedPlayerQuestionInBranch(
    String choiceNodeId,
    int order,
    String label,
    String? branchPrev,
    bool first,
    CutsceneStudioBlock block,
  ) {
    final cid = cutsceneStudioNormalizeNodeId(block.id, fallback: 'choice_${_edgeSeq}');
    nodes.insert(
      nodes.length - 1,
      _buildChoiceScenarioNode(block, cid),
    );
    if (first) {
      edges.add(
        ScenarioEdge(
          id: _nextEdgeId(),
          fromNodeId: choiceNodeId,
          toNodeId: cid,
          kind: ScenarioEdgeKind.choice,
          order: order,
          label: label,
        ),
      );
    } else {
      edges.add(
        ScenarioEdge(
          id: _nextEdgeId(),
          fromNodeId: branchPrev!,
          toNodeId: cid,
          kind: ScenarioEdgeKind.next,
          order: 0,
        ),
      );
    }
    final innerMerge = _addMergeNode();
    _compileChoiceBranch(
        cid, 0, _choiceOptionLabel(block, 0), const <CutsceneFlowEntry>[],
        innerMerge);
    _compileChoiceBranch(
        cid, 1, _choiceOptionLabel(block, 1), const <CutsceneFlowEntry>[],
        innerMerge);
    return innerMerge;
  }
}

String _choiceOptionLabel(CutsceneStudioBlock question, int index) {
  final opts = question.choiceOptions;
  if (opts.length > index && opts[index].trim().isNotEmpty) {
    return opts[index].trim();
  }
  return index == 0 ? 'Oui' : 'Non';
}

ScenarioNode _buildChoiceScenarioNode(
  CutsceneStudioBlock block,
  String nodeId,
) {
  final labels = block.choiceOptions.length >= 2
      ? block.choiceOptions
      : const <String>['Oui', 'Non'];
  return ScenarioNode(
    id: nodeId,
    type: ScenarioNodeType.choice,
    title: cutsceneStudioTrimOrNull(block.messageText)?.isNotEmpty == true
        ? cutsceneStudioTrimOrNull(block.messageText)!
        : cutsceneStudioBlockKindLabel(CutsceneStudioBlockKind.playerQuestion),
    payload: ScenarioNodePayload(
      message: cutsceneStudioTrimOrNull(block.messageText),
      choiceLabels: labels,
    ),
  );
}

/// Nœud explicite « pas encore branché runtime » — honnêteté produit.
///
/// L’exécuteur MVP consomme [kCutsceneStudioActionAuthoringPlaceholder] et avance
/// sans effet (voir `map_runtime`), au lieu d’un `waitMs` à 0 ms trompeur.
ScenarioNode _buildAuthoringPlaceholderScenarioNode(
  CutsceneStudioBlock block, {
  required String nodeId,
}) {
  final detail = StringBuffer('Placeholder studio — ')
    ..write(block.kind.name)
    ..write(' (')
    ..write(cutsceneStudioBlockKindLabel(block.kind))
    ..write(')');
  final extra = cutsceneStudioTrimOrNull(block.messageText);
  if (extra != null) {
    detail.write(' · ');
    detail.write(extra);
  }
  return ScenarioNode(
    id: nodeId,
    type: ScenarioNodeType.action,
    title: '⚠ ${cutsceneStudioBlockKindLabel(block.kind)}',
    payload: ScenarioNodePayload(
      actionKind: kCutsceneStudioActionAuthoringPlaceholder,
      message: detail.toString(),
    ),
    metadata: <String, String>{
      kCutsceneStudioPlaceholderKindMetadataKey: block.kind.name,
    },
    binding: ScenarioNodeBinding(
      entityId: cutsceneStudioTrimOrNull(block.actorId),
      scriptId: cutsceneStudioTrimOrNull(block.scriptId),
    ),
  );
}

ScenarioNode _buildNodeForBlock(
  CutsceneStudioBlock block, {
  required String nodeId,
}) {
  switch (block.kind) {
    case CutsceneStudioBlockKind.dialogue:
      // Bloc métier "faire parler":
      // - chemin principal: dialogue asset sélectionné;
      // - fallback authoring: ligne inline convertie en showMessage.
      final dialogueId = cutsceneStudioTrimOrNull(block.dialogueId);
      if (dialogueId == null) {
        final text = cutsceneStudioTrimOrNull(block.messageText) ?? '';
        return ScenarioNode(
          id: nodeId,
          type: ScenarioNodeType.action,
          title: cutsceneStudioBlockKindLabel(block.kind),
          payload: ScenarioNodePayload(
            actionKind: kCutsceneStudioActionShowMessage,
            message: text,
          ),
          binding: ScenarioNodeBinding(
            entityId: cutsceneStudioTrimOrNull(block.actorId),
          ),
        );
      }
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.dialogue,
        title: cutsceneStudioBlockKindLabel(block.kind),
        binding: ScenarioNodeBinding(
          entityId: cutsceneStudioTrimOrNull(block.actorId),
          dialogueId: dialogueId,
        ),
      );
    case CutsceneStudioBlockKind.narration:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionShowMessage,
          message: cutsceneStudioTrimOrNull(block.messageText) ?? '',
        ),
      );
    case CutsceneStudioBlockKind.moveCharacter:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionMoveCharacter,
          params: <String, String>{
            'targetKind': cutsceneStudioTrimOrNull(block.destinationTargetKind) ?? '',
            'targetId': cutsceneStudioTrimOrNull(block.destinationTargetId) ?? '',
            'waitForCompletion':
                (block.waitForCompletion ?? true) ? 'true' : 'false',
          },
        ),
        binding: ScenarioNodeBinding(
          entityId: cutsceneStudioTrimOrNull(block.actorId),
        ),
      );
    case CutsceneStudioBlockKind.followCharacter:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionFollowCharacter,
          params: <String, String>{
            'leaderId': cutsceneStudioTrimOrNull(block.actorId) ?? '',
          },
        ),
      );
    case CutsceneStudioBlockKind.faceCharacter:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionFaceCharacter,
          params: <String, String>{
            'direction': cutsceneStudioTrimOrNull(block.facingDirection) ?? 'south',
          },
        ),
        binding: ScenarioNodeBinding(
          entityId: cutsceneStudioTrimOrNull(block.actorId),
        ),
      );
    case CutsceneStudioBlockKind.transitionMap:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionTransitionMap,
        ),
        binding: ScenarioNodeBinding(
          mapId: cutsceneStudioTrimOrNull(block.transitionMapId),
          warpId: cutsceneStudioTrimOrNull(block.transitionWarpId),
        ),
      );
    case CutsceneStudioBlockKind.starterChoice:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionStarterChoice,
          choiceLabels: block.choiceOptions.isEmpty
              ? const <String>['Feu', 'Eau', 'Plante']
              : block.choiceOptions,
        ),
      );
    case CutsceneStudioBlockKind.wait:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionWaitMs,
          params: <String, String>{
            'durationMs': (block.durationMs ?? 700).toString(),
          },
        ),
      );
    case CutsceneStudioBlockKind.sceneResult:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionEmitOutcome,
        ),
        binding: ScenarioNodeBinding(
          outcomeId: cutsceneStudioResolveOutcomeIdForResultBlock(block),
        ),
        metadata: <String, String>{
          'result.label': cutsceneStudioTrimOrNull(block.resultLabel) ?? '',
          'result.scope':
              cutsceneStudioTrimOrNull(block.resultScope) ?? kCutsceneStudioResultScopeLocal,
        },
      );
    case CutsceneStudioBlockKind.runScript:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionRunScript,
        ),
        binding: ScenarioNodeBinding(
          scriptId: cutsceneStudioTrimOrNull(block.scriptId),
        ),
      );
    case CutsceneStudioBlockKind.setFlag:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionSetFlag,
        ),
        binding: ScenarioNodeBinding(
          flagName: cutsceneStudioTrimOrNull(block.flagName),
        ),
      );
    case CutsceneStudioBlockKind.clearFlag:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionClearFlag,
        ),
        binding: ScenarioNodeBinding(
          flagName: cutsceneStudioTrimOrNull(block.flagName),
        ),
      );
    case CutsceneStudioBlockKind.emitOutcome:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: const ScenarioNodePayload(
          actionKind: kCutsceneStudioActionEmitOutcome,
        ),
        binding: ScenarioNodeBinding(
          outcomeId: cutsceneStudioResolveOutcomeIdForResultBlock(block),
        ),
      );
    case CutsceneStudioBlockKind.playerQuestion:
      return _buildChoiceScenarioNode(block, nodeId);
    case CutsceneStudioBlockKind.pathfindMove:
      return ScenarioNode(
        id: nodeId,
        type: ScenarioNodeType.action,
        title: cutsceneStudioBlockKindLabel(block.kind),
        payload: ScenarioNodePayload(
          actionKind: kCutsceneStudioActionMoveCharacter,
          params: <String, String>{
            'targetKind': cutsceneStudioTrimOrNull(block.destinationTargetKind) ?? '',
            'targetId': cutsceneStudioTrimOrNull(block.destinationTargetId) ?? '',
            'waitForCompletion':
                (block.waitForCompletion ?? true) ? 'true' : 'false',
            'pathfinding': 'true',
          },
        ),
        binding: ScenarioNodeBinding(
          entityId: cutsceneStudioTrimOrNull(block.actorId),
        ),
      );
    case CutsceneStudioBlockKind.characterAppear:
    case CutsceneStudioBlockKind.characterDisappear:
    case CutsceneStudioBlockKind.cameraCenter:
    case CutsceneStudioBlockKind.cameraTransition:
    case CutsceneStudioBlockKind.callCutscene:
      return _buildAuthoringPlaceholderScenarioNode(block, nodeId: nodeId);
  }
}

String _sourceActionKind(CutsceneStudioSourceKind kind) {
  return switch (kind) {
    CutsceneStudioSourceKind.mapEnter => kCutsceneStudioSourceMapEnter,
    CutsceneStudioSourceKind.triggerEnter => kCutsceneStudioSourceTriggerEnter,
    CutsceneStudioSourceKind.entityInteract =>
      kCutsceneStudioSourceEntityInteract,
  };
}
