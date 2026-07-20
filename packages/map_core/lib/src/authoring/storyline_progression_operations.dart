import '../models/project_manifest.dart';
import '../models/narrative_value.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import '../read_models/storyline_progression_projection.dart';
import 'storyline_authoring_operations.dart';

enum StorylineProgressionMutationDisposition { applied, noChange, rejected }

enum StorylineProgressionConditionSlot { entry, completion }

enum _StorylineProgressionConnectKind {
  outcomeEffect,
  relationship,
  factCondition,
}

/// Explicit request for one mutation whose inverse is known and testable.
final class StorylineProgressionConnectRequest {
  const StorylineProgressionConnectRequest._({
    required _StorylineProgressionConnectKind kind,
    this.storylineId,
    this.sceneLinkId,
    this.outcomeLinkId,
    this.effectType,
    this.targetStepId,
    this.relationshipId,
    this.relationshipKind,
    this.sourceStorylineId,
    this.targetStorylineId,
    this.chapterId,
    this.stepId,
    this.conditionSlot,
    this.factId,
    this.expectedValue,
  }) : _kind = kind;

  factory StorylineProgressionConnectRequest.outcomeEffect({
    required String storylineId,
    required String sceneLinkId,
    required String outcomeLinkId,
    required StorylineEffectType effectType,
    required String targetStepId,
  }) {
    return StorylineProgressionConnectRequest._(
      kind: _StorylineProgressionConnectKind.outcomeEffect,
      storylineId: storylineId,
      sceneLinkId: sceneLinkId,
      outcomeLinkId: outcomeLinkId,
      effectType: effectType,
      targetStepId: targetStepId,
    );
  }

  factory StorylineProgressionConnectRequest.relationship({
    required String relationshipId,
    required StorylineRelationshipKind kind,
    required String sourceStorylineId,
    required String targetStorylineId,
  }) {
    return StorylineProgressionConnectRequest._(
      kind: _StorylineProgressionConnectKind.relationship,
      relationshipId: relationshipId,
      relationshipKind: kind,
      sourceStorylineId: sourceStorylineId,
      targetStorylineId: targetStorylineId,
    );
  }

  factory StorylineProgressionConnectRequest.factCondition({
    required String storylineId,
    required String chapterId,
    required String stepId,
    required StorylineProgressionConditionSlot slot,
    required String factId,
    required bool expectedValue,
  }) {
    return StorylineProgressionConnectRequest._(
      kind: _StorylineProgressionConnectKind.factCondition,
      storylineId: storylineId,
      chapterId: chapterId,
      stepId: stepId,
      conditionSlot: slot,
      factId: factId,
      expectedValue: expectedValue,
    );
  }

  final _StorylineProgressionConnectKind _kind;
  final String? storylineId;
  final String? sceneLinkId;
  final String? outcomeLinkId;
  final StorylineEffectType? effectType;
  final String? targetStepId;
  final String? relationshipId;
  final StorylineRelationshipKind? relationshipKind;
  final String? sourceStorylineId;
  final String? targetStorylineId;
  final String? chapterId;
  final String? stepId;
  final StorylineProgressionConditionSlot? conditionSlot;
  final String? factId;
  final bool? expectedValue;
}

final class StorylineProgressionMutationResult {
  const StorylineProgressionMutationResult({
    required this.before,
    required this.after,
    required this.disposition,
    this.code,
    this.message,
  });

  final ProjectManifest before;
  final ProjectManifest after;
  final StorylineProgressionMutationDisposition disposition;
  final String? code;
  final String? message;
}

StorylineProgressionMutationResult connectStorylineProgressionEdge(
  ProjectManifest project,
  StorylineProgressionConnectRequest request,
) {
  return switch (request._kind) {
    _StorylineProgressionConnectKind.outcomeEffect =>
      _connectOutcomeEffect(project, request),
    _StorylineProgressionConnectKind.relationship =>
      _connectRelationship(project, request),
    _StorylineProgressionConnectKind.factCondition =>
      _connectFactCondition(project, request),
  };
}

StorylineProgressionMutationResult disconnectStorylineProgressionEdge(
  ProjectManifest project, {
  required String storylineId,
  required String edgeId,
}) {
  final projection = buildStorylineProgressionProjection(
    project: project,
    storylineId: storylineId,
  );
  final matches = projection.edges.where((edge) => edge.id == edgeId).toList();
  if (matches.isEmpty) {
    return _rejected(
      project,
      code: 'edgeNotFound',
      message: 'L’arête de progression est introuvable.',
    );
  }
  final edge = matches.single;
  if (edge.editability == StorylineProgressionEdgeEditability.readOnly) {
    return _rejected(
      project,
      code: 'edgeReadOnly',
      message: edge.readOnlyReason ?? 'Cette arête est en lecture seule.',
    );
  }
  return switch (edge.source.kind) {
    StorylineProgressionSourceKind.outcomeEffect =>
      _disconnectOutcomeEffect(project, edge),
    StorylineProgressionSourceKind.relationship =>
      _disconnectRelationship(project, edge),
    StorylineProgressionSourceKind.stepCondition =>
      _disconnectFactCondition(project, edge),
    _ => _rejected(
        project,
        code: 'edgeReadOnly',
        message: 'Cette arête dérivée ne possède pas d’opération inverse.',
      ),
  };
}

StorylineProgressionMutationResult _connectOutcomeEffect(
  ProjectManifest project,
  StorylineProgressionConnectRequest request,
) {
  final storyline = _storyline(project, request.storylineId!);
  if (storyline == null) {
    return _rejected(project,
        code: 'storylineNotFound', message: 'Storyline introuvable.');
  }
  final target = _step(storyline, request.targetStepId!);
  if (target == null) {
    return _rejected(
      project,
      code: 'destinationNotFound',
      message: 'L’étape de destination est introuvable.',
    );
  }
  if (request.effectType != StorylineEffectType.activateStep &&
      request.effectType != StorylineEffectType.completeStep) {
    return _rejected(
      project,
      code: 'unsupportedEffectType',
      message: 'Seuls activateStep et completeStep forment des arêtes.',
    );
  }
  final link = _sceneLink(storyline, request.sceneLinkId!);
  final outcome =
      link == null ? null : _outcomeLink(link, request.outcomeLinkId!);
  if (link == null || outcome == null) {
    return _rejected(
      project,
      code: 'outcomeSourceNotFound',
      message: 'Le résultat source est introuvable.',
    );
  }
  final duplicate = outcome.effects.any(
    (effect) =>
        effect.type == request.effectType &&
        effect.targetId == request.targetStepId,
  );
  if (duplicate) {
    return _rejected(
      project,
      code: 'duplicateOutcomeEffect',
      message: 'Cet effet existe déjà sur le résultat.',
    );
  }
  if (link.stepId != null &&
      _wouldCreateOutcomeCycle(
        storyline,
        fromStepId: link.stepId!,
        toStepId: request.targetStepId!,
      )) {
    return _rejected(
      project,
      code: 'cycleDetected',
      message: 'Cette connexion créerait un cycle entre étapes.',
    );
  }

  final replacement = _copySceneLink(
    link,
    outcomeLinks: [
      for (final candidate in link.outcomeLinks)
        if (candidate.id == outcome.id)
          _copyOutcomeLink(
            candidate,
            effects: [
              ...candidate.effects,
              StorylineEffect(
                type: request.effectType!,
                targetId: request.targetStepId!,
              ),
            ],
          )
        else
          candidate,
    ],
  );
  return _replaceStoryline(
    project,
    storyline.copyWith(
      sceneLinks: [
        for (final candidate in storyline.sceneLinks)
          if (candidate.id == link.id) replacement else candidate,
      ],
    ),
  );
}

StorylineProgressionMutationResult _connectRelationship(
  ProjectManifest project,
  StorylineProgressionConnectRequest request,
) {
  final source = _storyline(project, request.sourceStorylineId!);
  final target = _storyline(project, request.targetStorylineId!);
  if (source == null || target == null) {
    return _rejected(
      project,
      code: 'destinationNotFound',
      message: 'Une Storyline de la relation est introuvable.',
    );
  }
  if (!_isReversibleRelationship(request.relationshipKind!)) {
    return _rejected(
      project,
      code: 'relationshipReadOnly',
      message: 'Cette relation enrichie s’édite dans son formulaire dédié.',
    );
  }
  if (request.sourceStorylineId == request.targetStorylineId) {
    return _rejected(
      project,
      code: 'cycleDetected',
      message: 'Une Storyline ne peut pas dépendre d’elle-même.',
    );
  }
  final idAlreadyUsed = project.storylines.any(
    (storyline) => storyline.relationships.any(
      (relationship) => relationship.id == request.relationshipId,
    ),
  );
  final sameRelationship =
      project.storylines.expand((s) => s.relationships).any(
            (relationship) =>
                relationship.kind == request.relationshipKind &&
                relationship.sourceStorylineId == request.sourceStorylineId &&
                relationship.targetStorylineId == request.targetStorylineId,
          );
  if (idAlreadyUsed || sameRelationship) {
    return _rejected(
      project,
      code: 'duplicateRelationship',
      message: 'Cette relation existe déjà.',
    );
  }
  if (_wouldCreateRelationshipCycle(
    project,
    sourceId: source.id,
    targetId: target.id,
  )) {
    return _rejected(
      project,
      code: 'cycleDetected',
      message: 'Cette relation créerait un cycle de progression.',
    );
  }
  final relationship = StorylineRelationship(
    id: request.relationshipId!,
    kind: request.relationshipKind!,
    sourceStorylineId: source.id,
    targetStorylineId: target.id,
  );
  return _replaceStoryline(
    project,
    source.copyWith(relationships: [...source.relationships, relationship]),
  );
}

StorylineProgressionMutationResult _connectFactCondition(
  ProjectManifest project,
  StorylineProgressionConnectRequest request,
) {
  if (!project.facts.any(
    (fact) =>
        fact.id == request.factId &&
        fact.valueKind == NarrativeValueKind.boolean,
  )) {
    return _rejected(
      project,
      code: 'destinationNotFound',
      message: 'Le Fact booléen de destination est introuvable.',
    );
  }
  final storyline = _storyline(project, request.storylineId!);
  final chapter =
      storyline == null ? null : _chapter(storyline, request.chapterId!);
  final step =
      chapter == null ? null : _stepInChapter(chapter, request.stepId!);
  if (storyline == null || chapter == null || step == null) {
    return _rejected(
      project,
      code: 'destinationNotFound',
      message: 'L’étape de destination est introuvable.',
    );
  }
  final current =
      request.conditionSlot == StorylineProgressionConditionSlot.entry
          ? step.entryCondition
          : step.completionCondition;
  if (current != null) {
    return _rejected(
      project,
      code: 'conditionSlotOccupied',
      message: 'Ce rôle de condition est déjà renseigné.',
    );
  }
  final condition = request.expectedValue!
      ? ScriptConditionFactory.flagIsSet(request.factId!)
      : ScriptConditionFactory.flagIsUnset(request.factId!);
  final updatedStep =
      request.conditionSlot == StorylineProgressionConditionSlot.entry
          ? step.copyWith(entryCondition: condition)
          : step.copyWith(completionCondition: condition);
  final mutation = updateStorylineStep(
    project,
    storylineId: storyline.id,
    chapterId: chapter.id,
    stepId: step.id,
    step: updatedStep,
  );
  if (!mutation.isApplied) {
    return _rejected(
      project,
      code: mutation.code ?? 'stepUpdateRejected',
      message: mutation.message ?? 'La condition n’a pas pu être enregistrée.',
    );
  }
  return _applied(project, mutation.after);
}

StorylineProgressionMutationResult _disconnectOutcomeEffect(
  ProjectManifest project,
  StorylineProgressionEdge edge,
) {
  final storyline = _storyline(project, edge.source.storylineId!);
  final link = storyline == null
      ? null
      : _sceneLink(storyline, edge.source.sceneLinkId!);
  final outcome =
      link == null ? null : _outcomeLink(link, edge.source.outcomeLinkId!);
  if (storyline == null || link == null || outcome == null) {
    return _rejected(project,
        code: 'edgeSourceNotFound', message: 'La source canonique a disparu.');
  }
  final effectType = switch (edge.kind) {
    StorylineProgressionEdgeKind.outcomeActivatesStep =>
      StorylineEffectType.activateStep,
    StorylineProgressionEdgeKind.outcomeCompletesStep =>
      StorylineEffectType.completeStep,
    _ => null,
  };
  if (effectType == null) {
    return _rejected(project,
        code: 'edgeReadOnly', message: 'L’arête ne représente pas un effet.');
  }
  final targetId = edge.toNodeId.replaceFirst('step:', '');
  final effects = outcome.effects
      .where(
          (effect) => effect.type != effectType || effect.targetId != targetId)
      .toList(growable: false);
  if (effects.length == outcome.effects.length) {
    return _rejected(project,
        code: 'edgeSourceNotFound', message: 'L’effet canonique a disparu.');
  }
  final updatedOutcomes = <StorylineSceneOutcomeLink>[
    for (final candidate in link.outcomeLinks)
      if (candidate.id != outcome.id)
        candidate
      else if (effects.isNotEmpty)
        _copyOutcomeLink(candidate, effects: effects),
  ];
  final replacement = _copySceneLink(link, outcomeLinks: updatedOutcomes);
  return _replaceStoryline(
    project,
    storyline.copyWith(
      sceneLinks: [
        for (final candidate in storyline.sceneLinks)
          if (candidate.id == link.id) replacement else candidate,
      ],
    ),
  );
}

StorylineProgressionMutationResult _disconnectRelationship(
  ProjectManifest project,
  StorylineProgressionEdge edge,
) {
  final source = _storyline(project, edge.source.storylineId!);
  if (source == null) {
    return _rejected(project,
        code: 'edgeSourceNotFound', message: 'La Storyline source a disparu.');
  }
  final relationships = source.relationships
      .where((relationship) => relationship.id != edge.source.relationshipId)
      .toList(growable: false);
  if (relationships.length == source.relationships.length) {
    return _rejected(project,
        code: 'edgeSourceNotFound',
        message: 'La relation canonique a disparu.');
  }
  return _replaceStoryline(
    project,
    source.copyWith(relationships: relationships),
  );
}

StorylineProgressionMutationResult _disconnectFactCondition(
  ProjectManifest project,
  StorylineProgressionEdge edge,
) {
  final storyline = _storyline(project, edge.source.storylineId!);
  final chapter =
      storyline == null ? null : _chapter(storyline, edge.source.chapterId!);
  final step =
      chapter == null ? null : _stepInChapter(chapter, edge.source.stepId!);
  if (storyline == null || chapter == null || step == null) {
    return _rejected(project,
        code: 'edgeSourceNotFound', message: 'L’étape source a disparu.');
  }
  final updated = edge.source.conditionSlot == 'entry'
      ? step.copyWith(entryCondition: null)
      : step.copyWith(completionCondition: null);
  final mutation = updateStorylineStep(
    project,
    storylineId: storyline.id,
    chapterId: chapter.id,
    stepId: step.id,
    step: updated,
  );
  return mutation.isApplied
      ? _applied(project, mutation.after)
      : _rejected(
          project,
          code: mutation.code ?? 'stepUpdateRejected',
          message: mutation.message ?? 'La condition n’a pas pu être retirée.',
        );
}

StorylineProgressionMutationResult _replaceStoryline(
  ProjectManifest project,
  StorylineAsset replacement,
) {
  return _applied(
    project,
    project.copyWith(
      storylines: [
        for (final storyline in project.storylines)
          if (storyline.id == replacement.id) replacement else storyline,
      ],
    ),
  );
}

StorylineProgressionMutationResult _applied(
  ProjectManifest before,
  ProjectManifest after,
) {
  return StorylineProgressionMutationResult(
    before: before,
    after: after,
    disposition: StorylineProgressionMutationDisposition.applied,
  );
}

StorylineProgressionMutationResult _rejected(
  ProjectManifest project, {
  required String code,
  required String message,
}) {
  return StorylineProgressionMutationResult(
    before: project,
    after: project,
    disposition: StorylineProgressionMutationDisposition.rejected,
    code: code,
    message: message,
  );
}

StorylineSceneLink _copySceneLink(
  StorylineSceneLink source, {
  required List<StorylineSceneOutcomeLink> outcomeLinks,
}) {
  return StorylineSceneLink(
    id: source.id,
    chapterId: source.chapterId,
    stepId: source.stepId,
    label: source.label,
    state: source.state,
    role: source.role,
    sceneRef: source.sceneRef,
    order: source.order,
    expectedOutcomeIds: source.expectedOutcomeIds,
    outcomeLinks: outcomeLinks,
    authorNotes: source.authorNotes,
    metadata: source.metadata,
  );
}

StorylineSceneOutcomeLink _copyOutcomeLink(
  StorylineSceneOutcomeLink source, {
  required List<StorylineEffect> effects,
}) {
  return StorylineSceneOutcomeLink(
    id: source.id,
    outcomeId: source.outcomeId,
    label: source.label,
    effects: effects,
    notes: source.notes,
    metadata: source.metadata,
  );
}

bool _wouldCreateRelationshipCycle(
  ProjectManifest project, {
  required String sourceId,
  required String targetId,
}) {
  final adjacency = <String, Set<String>>{};
  for (final storyline in project.storylines) {
    for (final relationship in storyline.relationships) {
      if (!_isReversibleRelationship(relationship.kind)) continue;
      adjacency
          .putIfAbsent(relationship.sourceStorylineId, () => <String>{})
          .add(relationship.targetStorylineId);
    }
  }
  adjacency.putIfAbsent(sourceId, () => <String>{}).add(targetId);
  return _hasCycle(adjacency);
}

bool _wouldCreateOutcomeCycle(
  StorylineAsset storyline, {
  required String fromStepId,
  required String toStepId,
}) {
  final adjacency = <String, Set<String>>{};
  for (final link in storyline.sceneLinks) {
    if (link.stepId == null) continue;
    for (final outcome in link.outcomeLinks) {
      for (final effect in outcome.effects) {
        if (effect.type != StorylineEffectType.activateStep &&
            effect.type != StorylineEffectType.completeStep) {
          continue;
        }
        adjacency
            .putIfAbsent(link.stepId!, () => <String>{})
            .add(effect.targetId);
      }
    }
  }
  adjacency.putIfAbsent(fromStepId, () => <String>{}).add(toStepId);
  return _hasCycle(adjacency);
}

bool _hasCycle(Map<String, Set<String>> adjacency) {
  final visiting = <String>{};
  final visited = <String>{};
  bool visit(String node) {
    if (visiting.contains(node)) return true;
    if (!visited.add(node)) return false;
    visiting.add(node);
    for (final next in adjacency[node] ?? const <String>{}) {
      if (visit(next)) return true;
    }
    visiting.remove(node);
    return false;
  }

  for (final node in adjacency.keys) {
    if (visit(node)) return true;
  }
  return false;
}

bool _isReversibleRelationship(StorylineRelationshipKind kind) {
  return kind == StorylineRelationshipKind.requires ||
      kind == StorylineRelationshipKind.blocks ||
      kind == StorylineRelationshipKind.convergesTo;
}

StorylineAsset? _storyline(ProjectManifest project, String id) {
  for (final storyline in project.storylines) {
    if (storyline.id == id) return storyline;
  }
  return null;
}

StorylineChapter? _chapter(StorylineAsset storyline, String id) {
  for (final chapter in storyline.chapters) {
    if (chapter.id == id) return chapter;
  }
  return null;
}

StorylineStep? _step(StorylineAsset storyline, String id) {
  for (final chapter in storyline.chapters) {
    final step = _stepInChapter(chapter, id);
    if (step != null) return step;
  }
  return null;
}

StorylineStep? _stepInChapter(StorylineChapter chapter, String id) {
  for (final step in chapter.steps) {
    if (step.id == id) return step;
  }
  return null;
}

StorylineSceneLink? _sceneLink(StorylineAsset storyline, String id) {
  for (final link in storyline.sceneLinks) {
    if (link.id == id) return link;
  }
  return null;
}

StorylineSceneOutcomeLink? _outcomeLink(StorylineSceneLink link, String id) {
  for (final outcome in link.outcomeLinks) {
    if (outcome.id == id) return outcome;
  }
  return null;
}
