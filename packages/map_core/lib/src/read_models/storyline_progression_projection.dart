import '../models/project_manifest.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';

/// Kind of canonical narrative entity exposed by the Storyline graph.
enum StorylineProgressionNodeKind {
  storyline,
  chapter,
  step,
  sceneOutcome,
  fact,
  condition,
}

/// Semantic meaning of a projected edge.
enum StorylineProgressionEdgeKind {
  contains,
  authorOrder,
  outcomeActivatesStep,
  outcomeCompletesStep,
  requires,
  blocks,
  convergesTo,
  sideQuestAvailability,
  entryCondition,
  completionCondition,
}

/// Canonical storage location from which an edge was derived.
enum StorylineProgressionSourceKind {
  ownership,
  chapterOrder,
  stepOrder,
  outcomeEffect,
  relationship,
  stepCondition,
}

enum StorylineProgressionEdgeEditability { readOnly, reversible }

enum StorylineProgressionDiagnosticCode {
  storylineNotFound,
  missingDestination,
  duplicateOutcomeEffect,
  cycleDetected,
  ambiguousCondition,
}

final class StorylineProgressionNode {
  const StorylineProgressionNode({
    required this.id,
    required this.kind,
    required this.canonicalId,
    required this.label,
    this.storylineId,
    this.chapterId,
    this.stepId,
    this.isMissing = false,
  });

  final String id;
  final StorylineProgressionNodeKind kind;
  final String canonicalId;
  final String label;
  final String? storylineId;
  final String? chapterId;
  final String? stepId;
  final bool isMissing;
}

final class StorylineProgressionSource {
  const StorylineProgressionSource({
    required this.kind,
    this.storylineId,
    this.chapterId,
    this.stepId,
    this.sceneLinkId,
    this.outcomeLinkId,
    this.relationshipId,
    this.conditionSlot,
  });

  final StorylineProgressionSourceKind kind;
  final String? storylineId;
  final String? chapterId;
  final String? stepId;
  final String? sceneLinkId;
  final String? outcomeLinkId;
  final String? relationshipId;
  final String? conditionSlot;
}

final class StorylineProgressionEdge {
  const StorylineProgressionEdge({
    required this.id,
    required this.kind,
    required this.fromNodeId,
    required this.toNodeId,
    required this.source,
    required this.editability,
    this.readOnlyReason,
  });

  final String id;
  final StorylineProgressionEdgeKind kind;
  final String fromNodeId;
  final String toNodeId;
  final StorylineProgressionSource source;
  final StorylineProgressionEdgeEditability editability;
  final String? readOnlyReason;
}

final class StorylineProgressionDiagnostic {
  const StorylineProgressionDiagnostic({
    required this.code,
    required this.message,
    this.edgeId,
    this.nodeId,
  });

  final StorylineProgressionDiagnosticCode code;
  final String message;
  final String? edgeId;
  final String? nodeId;
}

/// Immutable, non-serialized view of one Storyline's progression semantics.
final class StorylineProgressionProjection {
  StorylineProgressionProjection({
    required this.storylineId,
    required List<StorylineProgressionNode> nodes,
    required List<StorylineProgressionEdge> edges,
    required List<StorylineProgressionDiagnostic> diagnostics,
  })  : nodes = List<StorylineProgressionNode>.unmodifiable(nodes),
        edges = List<StorylineProgressionEdge>.unmodifiable(edges),
        diagnostics =
            List<StorylineProgressionDiagnostic>.unmodifiable(diagnostics);

  final String storylineId;
  final List<StorylineProgressionNode> nodes;
  final List<StorylineProgressionEdge> edges;
  final List<StorylineProgressionDiagnostic> diagnostics;

  List<StorylineProgressionEdge> edgesOfKind(
    StorylineProgressionEdgeKind kind,
  ) =>
      List<StorylineProgressionEdge>.unmodifiable(
        edges.where((edge) => edge.kind == kind),
      );
}

/// Builds a graph from canonical authoring fields without persisting layout.
StorylineProgressionProjection buildStorylineProgressionProjection({
  required ProjectManifest project,
  required String storylineId,
}) {
  final nodes = <String, StorylineProgressionNode>{};
  final edges = <StorylineProgressionEdge>[];
  final diagnostics = <StorylineProgressionDiagnostic>[];
  final storyline = _storylineById(project, storylineId);
  if (storyline == null) {
    return StorylineProgressionProjection(
      storylineId: storylineId,
      nodes: const <StorylineProgressionNode>[],
      edges: const <StorylineProgressionEdge>[],
      diagnostics: <StorylineProgressionDiagnostic>[
        StorylineProgressionDiagnostic(
          code: StorylineProgressionDiagnosticCode.storylineNotFound,
          message: 'La Storyline demandée est introuvable: $storylineId.',
          nodeId: 'storyline:$storylineId',
        ),
      ],
    );
  }

  void addNode(StorylineProgressionNode node) {
    final current = nodes[node.id];
    if (current == null || current.isMissing && !node.isMissing) {
      nodes[node.id] = node;
    }
  }

  StorylineProgressionNode ensureStorylineNode(String id) {
    final asset = _storylineById(project, id);
    final node = StorylineProgressionNode(
      id: 'storyline:$id',
      kind: StorylineProgressionNodeKind.storyline,
      canonicalId: id,
      label: asset?.title ?? id,
      storylineId: id,
      isMissing: asset == null,
    );
    addNode(node);
    return node;
  }

  StorylineProgressionNode ensureStepNode(String id) {
    final location = _stepLocation(project, storyline.id, id);
    final node = StorylineProgressionNode(
      id: 'step:$id',
      kind: StorylineProgressionNodeKind.step,
      canonicalId: id,
      label: location?.step.title ?? id,
      storylineId: storyline.id,
      chapterId: location?.chapter.id,
      stepId: id,
      isMissing: location == null,
    );
    addNode(node);
    return node;
  }

  ensureStorylineNode(storyline.id);
  final chapters = [...storyline.chapters]
    ..sort((a, b) => _compareOrdered(a.order, a.id, b.order, b.id));
  for (var chapterIndex = 0;
      chapterIndex < chapters.length;
      chapterIndex += 1) {
    final chapter = chapters[chapterIndex];
    final chapterNodeId = 'chapter:${chapter.id}';
    addNode(
      StorylineProgressionNode(
        id: chapterNodeId,
        kind: StorylineProgressionNodeKind.chapter,
        canonicalId: chapter.id,
        label: chapter.title,
        storylineId: storyline.id,
        chapterId: chapter.id,
      ),
    );
    edges.add(
      StorylineProgressionEdge(
        id: 'contains:storyline:${storyline.id}:chapter:${chapter.id}',
        kind: StorylineProgressionEdgeKind.contains,
        fromNodeId: 'storyline:${storyline.id}',
        toNodeId: chapterNodeId,
        source: StorylineProgressionSource(
          kind: StorylineProgressionSourceKind.ownership,
          storylineId: storyline.id,
          chapterId: chapter.id,
        ),
        editability: StorylineProgressionEdgeEditability.readOnly,
        readOnlyReason:
            'La propriété du chapitre se modifie avec les opérations de structure.',
      ),
    );
    if (chapterIndex > 0) {
      edges.add(
        StorylineProgressionEdge(
          id: 'order:chapter:${chapters[chapterIndex - 1].id}:${chapter.id}',
          kind: StorylineProgressionEdgeKind.authorOrder,
          fromNodeId: 'chapter:${chapters[chapterIndex - 1].id}',
          toNodeId: chapterNodeId,
          source: StorylineProgressionSource(
            kind: StorylineProgressionSourceKind.chapterOrder,
            storylineId: storyline.id,
            chapterId: chapter.id,
          ),
          editability: StorylineProgressionEdgeEditability.readOnly,
          readOnlyReason:
              'L’ordre auteur se modifie avec les commandes de réorganisation.',
        ),
      );
    }

    final steps = [...chapter.steps]
      ..sort((a, b) => _compareOrdered(a.order, a.id, b.order, b.id));
    for (var stepIndex = 0; stepIndex < steps.length; stepIndex += 1) {
      final step = steps[stepIndex];
      final stepNodeId = 'step:${step.id}';
      addNode(
        StorylineProgressionNode(
          id: stepNodeId,
          kind: StorylineProgressionNodeKind.step,
          canonicalId: step.id,
          label: step.title,
          storylineId: storyline.id,
          chapterId: chapter.id,
          stepId: step.id,
        ),
      );
      edges.add(
        StorylineProgressionEdge(
          id: 'contains:chapter:${chapter.id}:step:${step.id}',
          kind: StorylineProgressionEdgeKind.contains,
          fromNodeId: chapterNodeId,
          toNodeId: stepNodeId,
          source: StorylineProgressionSource(
            kind: StorylineProgressionSourceKind.ownership,
            storylineId: storyline.id,
            chapterId: chapter.id,
            stepId: step.id,
          ),
          editability: StorylineProgressionEdgeEditability.readOnly,
          readOnlyReason:
              'La propriété de l’étape se modifie avec les opérations de structure.',
        ),
      );
      if (stepIndex > 0) {
        edges.add(
          StorylineProgressionEdge(
            id: 'order:step:${steps[stepIndex - 1].id}:${step.id}',
            kind: StorylineProgressionEdgeKind.authorOrder,
            fromNodeId: 'step:${steps[stepIndex - 1].id}',
            toNodeId: stepNodeId,
            source: StorylineProgressionSource(
              kind: StorylineProgressionSourceKind.stepOrder,
              storylineId: storyline.id,
              chapterId: chapter.id,
              stepId: step.id,
            ),
            editability: StorylineProgressionEdgeEditability.readOnly,
            readOnlyReason:
                'L’ordre auteur se modifie avec les commandes de réorganisation.',
          ),
        );
      }
      _projectCondition(
        storyline: storyline,
        chapter: chapter,
        step: step,
        condition: step.entryCondition,
        slot: 'entry',
        edgeKind: StorylineProgressionEdgeKind.entryCondition,
        project: project,
        addNode: addNode,
        edges: edges,
        diagnostics: diagnostics,
      );
      _projectCondition(
        storyline: storyline,
        chapter: chapter,
        step: step,
        condition: step.completionCondition,
        slot: 'completion',
        edgeKind: StorylineProgressionEdgeKind.completionCondition,
        project: project,
        addNode: addNode,
        edges: edges,
        diagnostics: diagnostics,
      );
    }
  }

  for (final sceneLink in storyline.sceneLinks) {
    for (final outcomeLink in sceneLink.outcomeLinks) {
      final outcomeNodeId =
          'outcome:${storyline.id}:${sceneLink.id}:${outcomeLink.id}';
      addNode(
        StorylineProgressionNode(
          id: outcomeNodeId,
          kind: StorylineProgressionNodeKind.sceneOutcome,
          canonicalId: outcomeLink.id,
          label: outcomeLink.label ?? outcomeLink.outcomeId,
          storylineId: storyline.id,
          chapterId: sceneLink.chapterId,
          stepId: sceneLink.stepId,
        ),
      );
      final effectKeys = <String>{};
      for (final effect in outcomeLink.effects) {
        final edgeKind = _edgeKindForEffect(effect.type);
        if (edgeKind == null) continue;
        final target = ensureStepNode(effect.targetId);
        final effectKey = '${effect.type.name}:${effect.targetId}';
        final edgeId =
            'effect:${storyline.id}:${sceneLink.id}:${outcomeLink.id}:$effectKey';
        if (!effectKeys.add(effectKey)) {
          diagnostics.add(
            StorylineProgressionDiagnostic(
              code: StorylineProgressionDiagnosticCode.duplicateOutcomeEffect,
              message:
                  'Le résultat contient plusieurs fois le même effet $effectKey.',
              edgeId: edgeId,
              nodeId: target.id,
            ),
          );
        }
        edges.add(
          StorylineProgressionEdge(
            id: edgeId,
            kind: edgeKind,
            fromNodeId: outcomeNodeId,
            toNodeId: target.id,
            source: StorylineProgressionSource(
              kind: StorylineProgressionSourceKind.outcomeEffect,
              storylineId: storyline.id,
              chapterId: sceneLink.chapterId,
              stepId: sceneLink.stepId,
              sceneLinkId: sceneLink.id,
              outcomeLinkId: outcomeLink.id,
            ),
            editability: StorylineProgressionEdgeEditability.reversible,
          ),
        );
        if (target.isMissing) {
          diagnostics.add(
            StorylineProgressionDiagnostic(
              code: StorylineProgressionDiagnosticCode.missingDestination,
              message:
                  'L’effet du résultat cible une étape introuvable: ${effect.targetId}.',
              edgeId: edgeId,
              nodeId: target.id,
            ),
          );
        }
      }
    }
  }

  for (final owner in project.storylines) {
    for (final relationship in owner.relationships) {
      if (relationship.sourceStorylineId != storyline.id &&
          relationship.targetStorylineId != storyline.id) {
        continue;
      }
      final source = ensureStorylineNode(relationship.sourceStorylineId);
      final target = ensureStorylineNode(relationship.targetStorylineId);
      final kind = _edgeKindForRelationship(relationship.kind);
      final reversible = _isReversibleRelationship(relationship.kind);
      final edgeId = 'relationship:${owner.id}:${relationship.id}';
      edges.add(
        StorylineProgressionEdge(
          id: edgeId,
          kind: kind,
          fromNodeId: source.id,
          toNodeId: target.id,
          source: StorylineProgressionSource(
            kind: StorylineProgressionSourceKind.relationship,
            storylineId: owner.id,
            relationshipId: relationship.id,
          ),
          editability: reversible
              ? StorylineProgressionEdgeEditability.reversible
              : StorylineProgressionEdgeEditability.readOnly,
          readOnlyReason: reversible
              ? null
              : 'Cette relation descriptive possède une sémantique enrichie et ne se modifie pas comme une arête simple.',
        ),
      );
      if (source.isMissing || target.isMissing) {
        diagnostics.add(
          StorylineProgressionDiagnostic(
            code: StorylineProgressionDiagnosticCode.missingDestination,
            message:
                'La relation ${relationship.id} référence une Storyline introuvable.',
            edgeId: edgeId,
            nodeId: target.isMissing ? target.id : source.id,
          ),
        );
      }
    }
  }

  if (_hasRelationshipCycle(project)) {
    diagnostics.add(
      const StorylineProgressionDiagnostic(
        code: StorylineProgressionDiagnosticCode.cycleDetected,
        message:
            'Les relations de progression contiennent un cycle requires/blocks/convergesTo.',
      ),
    );
  }
  if (_hasOutcomeStepCycle(project, storyline.id)) {
    diagnostics.add(
      const StorylineProgressionDiagnostic(
        code: StorylineProgressionDiagnosticCode.cycleDetected,
        message: 'Les effets de résultats forment un cycle entre étapes.',
      ),
    );
  }

  return StorylineProgressionProjection(
    storylineId: storyline.id,
    nodes: nodes.values.toList(growable: false),
    edges: edges,
    diagnostics: diagnostics,
  );
}

void _projectCondition({
  required StorylineAsset storyline,
  required StorylineChapter chapter,
  required StorylineStep step,
  required ScriptCondition? condition,
  required String slot,
  required StorylineProgressionEdgeKind edgeKind,
  required ProjectManifest project,
  required void Function(StorylineProgressionNode) addNode,
  required List<StorylineProgressionEdge> edges,
  required List<StorylineProgressionDiagnostic> diagnostics,
}) {
  if (condition == null) return;
  final flagId = _simpleFactId(condition);
  final source = StorylineProgressionSource(
    kind: StorylineProgressionSourceKind.stepCondition,
    storylineId: storyline.id,
    chapterId: chapter.id,
    stepId: step.id,
    conditionSlot: slot,
  );
  if (flagId != null) {
    final fact = project.facts.where((candidate) => candidate.id == flagId);
    final exists = fact.isNotEmpty;
    final nodeId = 'fact:$flagId';
    addNode(
      StorylineProgressionNode(
        id: nodeId,
        kind: StorylineProgressionNodeKind.fact,
        canonicalId: flagId,
        label: exists ? fact.first.label : flagId,
        storylineId: storyline.id,
        chapterId: chapter.id,
        stepId: step.id,
        isMissing: !exists,
      ),
    );
    final edgeId = 'condition:${storyline.id}:${chapter.id}:${step.id}:$slot';
    edges.add(
      StorylineProgressionEdge(
        id: edgeId,
        kind: edgeKind,
        fromNodeId: nodeId,
        toNodeId: 'step:${step.id}',
        source: source,
        editability: StorylineProgressionEdgeEditability.reversible,
      ),
    );
    if (!exists) {
      diagnostics.add(
        StorylineProgressionDiagnostic(
          code: StorylineProgressionDiagnosticCode.missingDestination,
          message: 'La condition cible un Fact introuvable: $flagId.',
          edgeId: edgeId,
          nodeId: nodeId,
        ),
      );
    }
    return;
  }

  final nodeId = 'condition:${storyline.id}:${chapter.id}:${step.id}:$slot';
  addNode(
    StorylineProgressionNode(
      id: nodeId,
      kind: StorylineProgressionNodeKind.condition,
      canonicalId: '$slot:${step.id}',
      label: slot == 'entry' ? 'Condition d’entrée' : 'Condition de complétion',
      storylineId: storyline.id,
      chapterId: chapter.id,
      stepId: step.id,
    ),
  );
  final edgeId = 'condition:${storyline.id}:${chapter.id}:${step.id}:$slot';
  edges.add(
    StorylineProgressionEdge(
      id: edgeId,
      kind: edgeKind,
      fromNodeId: nodeId,
      toNodeId: 'step:${step.id}',
      source: source,
      editability: StorylineProgressionEdgeEditability.readOnly,
      readOnlyReason:
          'La condition composée ne possède pas de transformation inverse non ambiguë.',
    ),
  );
  diagnostics.add(
    StorylineProgressionDiagnostic(
      code: StorylineProgressionDiagnosticCode.ambiguousCondition,
      message:
          'La condition composée est visible mais reste éditable dans son formulaire dédié.',
      edgeId: edgeId,
      nodeId: nodeId,
    ),
  );
}

String? _simpleFactId(ScriptCondition condition) {
  if (condition.children.isNotEmpty) return null;
  if (condition.type != ScriptConditionType.flagIsSet &&
      condition.type != ScriptConditionType.flagIsUnset) {
    return null;
  }
  final id = condition.params[ScriptConditionParams.flagName]?.trim();
  return id == null || id.isEmpty ? null : id;
}

StorylineProgressionEdgeKind? _edgeKindForEffect(StorylineEffectType type) {
  return switch (type) {
    StorylineEffectType.activateStep =>
      StorylineProgressionEdgeKind.outcomeActivatesStep,
    StorylineEffectType.completeStep =>
      StorylineProgressionEdgeKind.outcomeCompletesStep,
    _ => null,
  };
}

StorylineProgressionEdgeKind _edgeKindForRelationship(
  StorylineRelationshipKind kind,
) {
  return switch (kind) {
    StorylineRelationshipKind.requires => StorylineProgressionEdgeKind.requires,
    StorylineRelationshipKind.blocks => StorylineProgressionEdgeKind.blocks,
    StorylineRelationshipKind.convergesTo =>
      StorylineProgressionEdgeKind.convergesTo,
    _ => StorylineProgressionEdgeKind.sideQuestAvailability,
  };
}

bool _isReversibleRelationship(StorylineRelationshipKind kind) {
  return kind == StorylineRelationshipKind.requires ||
      kind == StorylineRelationshipKind.blocks ||
      kind == StorylineRelationshipKind.convergesTo;
}

bool _hasRelationshipCycle(ProjectManifest project) {
  final adjacency = <String, Set<String>>{};
  for (final storyline in project.storylines) {
    for (final relationship in storyline.relationships) {
      if (!_isReversibleRelationship(relationship.kind)) continue;
      adjacency
          .putIfAbsent(relationship.sourceStorylineId, () => <String>{})
          .add(relationship.targetStorylineId);
    }
  }
  return _hasCycle(adjacency);
}

bool _hasOutcomeStepCycle(ProjectManifest project, String storylineId) {
  final storyline = _storylineById(project, storylineId);
  if (storyline == null) return false;
  final adjacency = <String, Set<String>>{};
  for (final link in storyline.sceneLinks) {
    final source = link.stepId;
    if (source == null) continue;
    for (final outcome in link.outcomeLinks) {
      for (final effect in outcome.effects) {
        if (_edgeKindForEffect(effect.type) == null) continue;
        adjacency.putIfAbsent(source, () => <String>{}).add(effect.targetId);
      }
    }
  }
  return _hasCycle(adjacency);
}

bool _hasCycle(Map<String, Set<String>> adjacency) {
  final visiting = <String>{};
  final visited = <String>{};
  bool visit(String node) {
    if (visiting.contains(node)) return true;
    if (!visited.add(node)) return false;
    visiting.add(node);
    for (final target in adjacency[node] ?? const <String>{}) {
      if (visit(target)) return true;
    }
    visiting.remove(node);
    return false;
  }

  for (final node in adjacency.keys) {
    if (visit(node)) return true;
  }
  return false;
}

StorylineAsset? _storylineById(ProjectManifest project, String id) {
  for (final storyline in project.storylines) {
    if (storyline.id == id) return storyline;
  }
  return null;
}

_StepLocation? _stepLocation(
  ProjectManifest project,
  String storylineId,
  String stepId,
) {
  final storyline = _storylineById(project, storylineId);
  if (storyline == null) return null;
  for (final chapter in storyline.chapters) {
    for (final step in chapter.steps) {
      if (step.id == stepId) return _StepLocation(chapter, step);
    }
  }
  return null;
}

int _compareOrdered(
    int leftOrder, String leftId, int rightOrder, String rightId) {
  final order = leftOrder.compareTo(rightOrder);
  return order == 0 ? leftId.compareTo(rightId) : order;
}

final class _StepLocation {
  const _StepLocation(this.chapter, this.step);

  final StorylineChapter chapter;
  final StorylineStep step;
}
