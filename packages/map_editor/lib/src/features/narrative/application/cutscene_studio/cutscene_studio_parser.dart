// Cutscene Studio — parse `ScenarioAsset` → [CutsceneStudioDocument].
//
// Priorité au JSON [kCutsceneStudioFlowMetadataKey] quand présent (fidélité branches).
// Sinon walk linéaire start → source → … → end avec garde-fous (cycles, multi-sorties).
// Les nœuds [kCutsceneStudioActionFlowMerge] sont ignorés dans ce walk (structurels).

import 'package:map_core/map_core.dart';

import 'cutscene_studio_flow_codec.dart';
import 'cutscene_studio_flow.dart';
import 'cutscene_studio_models.dart';

CutsceneStudioParseResult parseScenarioToCutsceneStudioDocument(
  ScenarioAsset scenario,
) {
  final warnings = <String>[];
  final nodesById = <String, ScenarioNode>{
    for (final node in scenario.nodes) node.id: node,
  };
  final edgesByFrom = <String, List<ScenarioEdge>>{};
  for (final edge in scenario.edges) {
    edgesByFrom.putIfAbsent(edge.fromNodeId, () => <ScenarioEdge>[]).add(edge);
  }
  for (final list in edgesByFrom.values) {
    list.sort((a, b) => a.order.compareTo(b.order));
  }

  if (scenario.scope != ScenarioScope.localEventFlow) {
    warnings.add(
      'Le studio cutscene v1 supporte uniquement les scénarios localEventFlow.',
    );
  }

  final startNode = nodesById[scenario.entryNodeId];
  if (startNode == null || startNode.type != ScenarioNodeType.start) {
    warnings.add(
      'entryNodeId doit pointer vers un node Start pour le mode guidé v1.',
    );
  }

  final sourceNode = startNode == null
      ? null
      : _resolveSingleNextNode(
          fromNode: startNode,
          nodesById: nodesById,
          edgesByFrom: edgesByFrom,
          warnings: warnings,
          contextLabel: 'Start',
        );

  final parsedSource = sourceNode == null
      ? null
      : _parseSourceNode(
          sourceNode,
          warnings: warnings,
        );

  // Priorité au JSON d’authoring: il décrit fidèlement branches + ordre palette.
  final flowRaw =
      scenario.metadata[kCutsceneStudioFlowMetadataKey]?.trim() ?? '';
  if (flowRaw.isNotEmpty) {
    try {
      final flow = decodeCutsceneFlowMetadata(flowRaw);
      final source = parsedSource ??
          const CutsceneStudioSourceConfig(
            kind: CutsceneStudioSourceKind.entityInteract,
          );
      return CutsceneStudioParseResult(
        document: CutsceneStudioDocument(
          id: scenario.id,
          name: scenario.name,
          description: scenario.description,
          source: source,
          blocks: flattenMainTrunkFlowToBlocks(flow),
          cutsceneFlow: flow,
        ),
        editable: warnings.isEmpty,
        warnings: warnings,
      );
    } catch (e) {
      warnings.add('Arbre de scène sauvegardé illisible ($e).');
    }
  }

  final blocks = <CutsceneStudioBlock>[];
  if (sourceNode != null && parsedSource != null) {
    var cursor = _resolveSingleNextNode(
      fromNode: sourceNode,
      nodesById: nodesById,
      edgesByFrom: edgesByFrom,
      warnings: warnings,
      contextLabel: 'Source',
    );
    final visited = <String>{startNode!.id, sourceNode.id};

    while (cursor != null) {
      // Protection anti-boucle: le studio v1 est linéaire.
      if (!visited.add(cursor.id)) {
        warnings.add('Cycle détecté autour du node "${cursor.id}".');
        break;
      }
      if (cursor.type == ScenarioNodeType.end) {
        final outgoing = edgesByFrom[cursor.id] ?? const <ScenarioEdge>[];
        if (outgoing.isNotEmpty) {
          warnings.add(
            'Un node End ne doit pas avoir de sortie dans le mode v1.',
          );
        }
        break;
      }
      // Fusions de branches : purement structurelles, absentes du modèle linéaire.
      if (cursor.type == ScenarioNodeType.action &&
          cursor.payload.actionKind?.trim() ==
              kCutsceneStudioActionFlowMerge) {
        cursor = _resolveSingleNextNode(
          fromNode: cursor,
          nodesById: nodesById,
          edgesByFrom: edgesByFrom,
          warnings: warnings,
          contextLabel: 'Fusion "${cursor.id}"',
        );
        continue;
      }
      final parsed = _parseBlockNode(cursor, warnings: warnings);
      if (parsed == null) {
        break;
      }
      blocks.add(parsed);
      cursor = _resolveSingleNextNode(
        fromNode: cursor,
        nodesById: nodesById,
        edgesByFrom: edgesByFrom,
        warnings: warnings,
        contextLabel: 'Bloc ${cursor.id}',
      );
    }
  }

  final source = parsedSource ??
      const CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
      );
  final document = CutsceneStudioDocument(
    id: scenario.id,
    name: scenario.name,
    description: scenario.description,
    source: source,
    blocks: blocks,
  );
  return CutsceneStudioParseResult(
    document: document,
    editable: warnings.isEmpty,
    warnings: warnings,
  );
}

ScenarioNode? _resolveSingleNextNode({
  required ScenarioNode fromNode,
  required Map<String, ScenarioNode> nodesById,
  required Map<String, List<ScenarioEdge>> edgesByFrom,
  required List<String> warnings,
  required String contextLabel,
}) {
  final outgoing = edgesByFrom[fromNode.id] ?? const <ScenarioEdge>[];
  if (outgoing.isEmpty) {
    warnings.add('$contextLabel n\'a aucune sortie.');
    return null;
  }
  if (outgoing.length > 1) {
    warnings.add(
      '$contextLabel a plusieurs sorties: le mode guidé v1 ne gère pas les branches.',
    );
    return null;
  }
  final edge = outgoing.first;
  if (edge.kind != ScenarioEdgeKind.next) {
    warnings.add(
      '$contextLabel utilise "${edge.kind.name}" mais le mode v1 attend "next".',
    );
    return null;
  }
  final next = nodesById[edge.toNodeId];
  if (next == null) {
    warnings.add('$contextLabel référence un node cible introuvable.');
    return null;
  }
  return next;
}

CutsceneStudioSourceConfig? _parseSourceNode(
  ScenarioNode node, {
  required List<String> warnings,
}) {
  if (node.type != ScenarioNodeType.reference) {
    warnings.add(
      'Le node source doit être de type Reference dans le mode guidé v1.',
    );
    return null;
  }
  final actionKind = node.payload.actionKind?.trim() ?? '';
  switch (actionKind) {
    case kCutsceneStudioSourceMapEnter:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.mapEnter,
        mapId: cutsceneStudioTrimOrNull(node.binding.mapId),
      );
    case kCutsceneStudioSourceTriggerEnter:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.triggerEnter,
        mapId: cutsceneStudioTrimOrNull(node.binding.mapId),
        triggerId: cutsceneStudioTrimOrNull(node.binding.triggerId),
      );
    case kCutsceneStudioSourceEntityInteract:
      return CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
        mapId: cutsceneStudioTrimOrNull(node.binding.mapId),
        entityId: cutsceneStudioTrimOrNull(node.binding.entityId),
      );
    default:
      warnings.add(
        'Source "$actionKind" non supportée par le studio guidé v1.',
      );
      return null;
  }
}

CutsceneStudioBlock? _parseBlockNode(
  ScenarioNode node, {
  required List<String> warnings,
}) {
  if (node.type == ScenarioNodeType.dialogue) {
    return CutsceneStudioBlock(
      id: node.id,
      kind: CutsceneStudioBlockKind.dialogue,
      actorId: cutsceneStudioTrimOrNull(node.binding.entityId),
      dialogueId: cutsceneStudioTrimOrNull(node.binding.dialogueId),
    );
  }

  if (node.type != ScenarioNodeType.action) {
    warnings.add(
      'Node "${node.id}" de type "${node.type.name}" hors périmètre du mode guidé v1.',
    );
    return null;
  }

  final actionKind = node.payload.actionKind?.trim() ?? '';
  switch (actionKind) {
    case kCutsceneStudioActionRunScript:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.runScript,
        scriptId: cutsceneStudioTrimOrNull(node.binding.scriptId),
      );
    case kCutsceneStudioActionShowMessage:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.narration,
        messageText: cutsceneStudioTrimOrNull(node.payload.message),
      );
    case kCutsceneStudioActionOpenDialogue:
      // Compatibilité: certains flux historiques utilisent `action/openDialogue`
      // au lieu d'un node `dialogue`.
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.dialogue,
        actorId: cutsceneStudioTrimOrNull(node.binding.entityId),
        dialogueId: cutsceneStudioTrimOrNull(node.binding.dialogueId),
      );
    case kCutsceneStudioActionMoveCharacter:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: cutsceneStudioTrimOrNull(node.binding.entityId),
        destinationTargetKind: cutsceneStudioTrimOrNull(node.payload.params['targetKind']),
        destinationTargetId: cutsceneStudioTrimOrNull(node.payload.params['targetId']),
        waitForCompletion:
            (node.payload.params['waitForCompletion'] ?? 'true') == 'true',
      );
    case kCutsceneStudioActionFollowCharacter:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.followCharacter,
        actorId: cutsceneStudioTrimOrNull(node.payload.params['leaderId']),
      );
    case kCutsceneStudioActionFaceCharacter:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.faceCharacter,
        actorId: cutsceneStudioTrimOrNull(node.binding.entityId),
        facingDirection: cutsceneStudioTrimOrNull(node.payload.params['direction']),
      );
    case kCutsceneStudioActionTransitionMap:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.transitionMap,
        transitionMapId: cutsceneStudioTrimOrNull(node.binding.mapId),
        transitionWarpId: cutsceneStudioTrimOrNull(node.binding.warpId),
      );
    case kCutsceneStudioActionStarterChoice:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.starterChoice,
        choiceOptions: node.payload.choiceLabels.isEmpty
            ? const <String>['Feu', 'Eau', 'Plante']
            : node.payload.choiceLabels,
      );
    case kCutsceneStudioActionWaitMs:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.wait,
        durationMs: int.tryParse(node.payload.params['durationMs'] ?? ''),
      );
    case kCutsceneStudioActionSetFlag:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.setFlag,
        flagName: cutsceneStudioTrimOrNull(node.binding.flagName),
      );
    case kCutsceneStudioActionClearFlag:
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.clearFlag,
        flagName: cutsceneStudioTrimOrNull(node.binding.flagName),
      );
    case kCutsceneStudioActionEmitOutcome:
      final outcomeId = cutsceneStudioTrimOrNull(node.binding.outcomeId);
      return CutsceneStudioBlock(
        id: node.id,
        kind: CutsceneStudioBlockKind.sceneResult,
        outcomeId: outcomeId,
        resultLabel: cutsceneStudioTrimOrNull(node.metadata['result.label']) ??
            cutsceneStudioLabelFromOutcomeId(outcomeId),
        resultScope: cutsceneStudioTrimOrNull(node.metadata['result.scope']) ??
            cutsceneStudioScopeFromOutcomeId(outcomeId),
      );
    case kCutsceneStudioActionAuthoringPlaceholder:
      final kindName = cutsceneStudioTrimOrNull(
        node.metadata[kCutsceneStudioPlaceholderKindMetadataKey],
      );
      CutsceneStudioBlockKind kind;
      if (kindName != null) {
        try {
          kind = CutsceneStudioBlockKind.values.byName(kindName);
        } catch (_) {
          warnings.add(
            'Placeholder "${node.id}": kind "$kindName" inconnu.',
          );
          return null;
        }
      } else {
        warnings.add(
          'Placeholder "${node.id}" sans métadonnée $kCutsceneStudioPlaceholderKindMetadataKey.',
        );
        return null;
      }
      return CutsceneStudioBlock(
        id: node.id,
        kind: kind,
        actorId: cutsceneStudioTrimOrNull(node.binding.entityId),
        scriptId: cutsceneStudioTrimOrNull(node.binding.scriptId),
        messageText: cutsceneStudioTrimOrNull(node.payload.message),
      );
    default:
      warnings.add(
        'Action "$actionKind" non supportée par le studio guidé v1.',
      );
      return null;
  }
}
