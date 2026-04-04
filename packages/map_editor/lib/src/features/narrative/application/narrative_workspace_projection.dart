import 'package:map_core/map_core.dart';

import 'step_studio_authoring.dart';

/// Type d'outcome exposé dans le workspace narratif.
///
/// Cette classification est volontairement "produit" (pas purement technique):
/// - local: outcome principalement émis/consommé dans des flows locaux.
/// - global: outcome principalement lié à la progression globale.
/// - mixed: usage mixte local + global (cas de convergence ou migration).
/// - unknown: pas assez d'information pour classifier proprement.
enum NarrativeOutcomeScope {
  local,
  global,
  mixed,
  unknown,
}

/// Résumé "macro" d'un scénario tel qu'affiché dans les workspaces narratifs.
class NarrativeScenarioSummary {
  const NarrativeScenarioSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.scope,
    required this.entryNodeId,
    required this.nodeCount,
    required this.edgeCount,
    required this.declaredOutcomes,
    required this.emittedOutcomes,
    required this.consumedOutcomes,
  });

  final String id;
  final String name;
  final String description;
  final ScenarioScope scope;
  final String entryNodeId;
  final int nodeCount;
  final int edgeCount;
  final List<String> declaredOutcomes;
  final List<String> emittedOutcomes;
  final List<String> consumedOutcomes;
}

/// Vue "Step" dérivée des données existantes.
///
/// Le modèle canonique `Step` n'est pas encore implémenté dans la donnée
/// projet. Cette structure fournit un socle UI stable et explicite:
/// - 1 step logique par scénario global (fallback),
/// - enrichissement optionnel via metadata (`step.*`) quand présent.
class NarrativeStepSummary {
  const NarrativeStepSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.globalScenarioId,
    required this.linkedCutsceneIds,
    required this.expectedOutcomeIds,
    required this.emittedOutcomeIds,
    required this.activationSummary,
    required this.completionSummary,
    required this.worldChangeCount,
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final String globalScenarioId;
  final List<String> linkedCutsceneIds;
  final List<String> expectedOutcomeIds;
  final List<String> emittedOutcomeIds;
  final String activationSummary;
  final String completionSummary;
  final int worldChangeCount;
}

/// Graphe relationnel outcome -> émetteurs / consommateurs.
class NarrativeOutcomeSummary {
  const NarrativeOutcomeSummary({
    required this.id,
    required this.scope,
    required this.declaredByScenarioIds,
    required this.emittedByScenarioIds,
    required this.consumedByScenarioIds,
  });

  final String id;
  final NarrativeOutcomeScope scope;
  final List<String> declaredByScenarioIds;
  final List<String> emittedByScenarioIds;
  final List<String> consumedByScenarioIds;
}

/// Projection consolidée de la donnée narrative pour l'UI.
///
/// Frontière de responsabilité:
/// - cette projection est STRICTEMENT orientée lecture/présentation.
/// - elle ne modifie jamais le `ProjectManifest`.
/// - elle ne remplace pas un futur vrai domaine `GlobalStory/Step/Cutscene`.
class NarrativeWorkspaceProjection {
  const NarrativeWorkspaceProjection({
    required this.globalStories,
    required this.localEventFlows,
    required this.steps,
    required this.outcomes,
    required this.scenarioById,
  });

  final List<NarrativeScenarioSummary> globalStories;
  final List<NarrativeScenarioSummary> localEventFlows;
  final List<NarrativeStepSummary> steps;
  final List<NarrativeOutcomeSummary> outcomes;
  final Map<String, NarrativeScenarioSummary> scenarioById;
}

NarrativeWorkspaceProjection buildNarrativeWorkspaceProjection(
  ProjectManifest project,
) {
  final globalStories = <NarrativeScenarioSummary>[];
  final localEventFlows = <NarrativeScenarioSummary>[];
  final scenarioById = <String, NarrativeScenarioSummary>{};

  final stepById = <String, _MutableStep>{};
  final outcomeById = <String, _MutableOutcome>{};

  for (final scenario in project.scenarios) {
    final emitted = _collectOutcomesForActionKinds(
      scenario,
      const <String>{'emitoutcome', 'emit_outcome'},
    );
    final consumed = _collectOutcomesForActionKinds(
      scenario,
      const <String>{
        'sourceoutcome',
        'source_outcome',
        'waituntiloutcome',
        'wait_until_outcome',
      },
    );
    final declared = _dedupeAndSort(
      scenario.declaredOutcomes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    );

    final summary = NarrativeScenarioSummary(
      id: scenario.id,
      name: scenario.name.trim().isEmpty ? scenario.id : scenario.name,
      description: scenario.description,
      scope: scenario.scope,
      entryNodeId: scenario.entryNodeId,
      nodeCount: scenario.nodes.length,
      edgeCount: scenario.edges.length,
      declaredOutcomes: declared,
      emittedOutcomes: emitted,
      consumedOutcomes: consumed,
    );

    scenarioById[summary.id] = summary;
    if (summary.scope == ScenarioScope.globalStory) {
      globalStories.add(summary);
    } else {
      localEventFlows.add(summary);
    }

    _registerScenarioOutcomes(summary, outcomeById);
    _registerStepProjection(summary, scenario, stepById);
  }

  final steps = stepById.values
      .map((e) => NarrativeStepSummary(
            id: e.id,
            name: e.name,
            description: e.description,
            order: e.order,
            globalScenarioId: e.globalScenarioId,
            linkedCutsceneIds: _dedupeAndSort(e.linkedCutsceneIds),
            expectedOutcomeIds: _dedupeAndSort(e.expectedOutcomeIds),
            emittedOutcomeIds: _dedupeAndSort(e.emittedOutcomeIds),
            activationSummary: e.activationSummary,
            completionSummary: e.completionSummary,
            worldChangeCount: e.worldChangeCount,
          ))
      .toList(growable: false)
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  final outcomes = outcomeById.values
      .map((e) => NarrativeOutcomeSummary(
            id: e.id,
            scope: _classifyOutcomeScope(e),
            declaredByScenarioIds: _dedupeAndSort(e.declaredByScenarioIds),
            emittedByScenarioIds: _dedupeAndSort(e.emittedByScenarioIds),
            consumedByScenarioIds: _dedupeAndSort(e.consumedByScenarioIds),
          ))
      .toList(growable: false)
    ..sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));

  globalStories
      .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  localEventFlows
      .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return NarrativeWorkspaceProjection(
    globalStories: globalStories,
    localEventFlows: localEventFlows,
    steps: steps,
    outcomes: outcomes,
    scenarioById: scenarioById,
  );
}

void _registerScenarioOutcomes(
  NarrativeScenarioSummary summary,
  Map<String, _MutableOutcome> outcomeById,
) {
  for (final id in summary.declaredOutcomes) {
    final item = outcomeById.putIfAbsent(id, () => _MutableOutcome(id: id));
    item.declaredByScenarioIds.add(summary.id);
    item.scopes.add(summary.scope);
  }
  for (final id in summary.emittedOutcomes) {
    final item = outcomeById.putIfAbsent(id, () => _MutableOutcome(id: id));
    item.emittedByScenarioIds.add(summary.id);
    item.scopes.add(summary.scope);
  }
  for (final id in summary.consumedOutcomes) {
    final item = outcomeById.putIfAbsent(id, () => _MutableOutcome(id: id));
    item.consumedByScenarioIds.add(summary.id);
    item.scopes.add(summary.scope);
  }
}

void _registerStepProjection(
  NarrativeScenarioSummary summary,
  ScenarioAsset rawScenario,
  Map<String, _MutableStep> stepById,
) {
  if (summary.scope != ScenarioScope.globalStory) {
    return;
  }

  final parsed = parseStepStudioDocumentFromGlobalScenario(rawScenario);
  final normalizedSteps = parsed.document.steps;
  if (normalizedSteps.isEmpty) {
    return;
  }

  for (final step in normalizedSteps) {
    final stepId = step.id;
    final stepName = step.name.trim().isEmpty ? summary.name : step.name;
    final stepDescription = step.description.trim().isEmpty
        ? (summary.description.trim().isEmpty
            ? 'No description yet.'
            : summary.description)
        : step.description;
    final linkedCutsceneIds = step.cutscenes
        .map((entry) => entry.cutsceneId.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    final item = stepById.putIfAbsent(
      stepId,
      () => _MutableStep(
        id: stepId,
        name: stepName,
        description: stepDescription,
        order: step.order,
        globalScenarioId: summary.id,
        activationSummary: summarizeStepActivation(step),
        completionSummary: summarizeStepCompletion(step),
        worldChangeCount: step.worldChanges.length,
      ),
    );
    item.linkedCutsceneIds.addAll(linkedCutsceneIds);
    item.expectedOutcomeIds.addAll(
      <String>[
        ...summary.consumedOutcomes,
        ..._collectExpectedOutcomeIds(step),
      ],
    );
    item.emittedOutcomeIds.addAll(
      <String>[
        ...summary.declaredOutcomes,
        ...summary.emittedOutcomes,
        ...step.outcomes
            .map((outcome) => outcome.outcomeId.trim())
            .where((entry) => entry.isNotEmpty),
      ],
    );
  }
}

Iterable<String> _collectExpectedOutcomeIds(StepStudioStep step) sync* {
  if (step.activation.mode == StepStudioActivationMode.afterOutcome) {
    final value = (step.activation.outcomeId ?? '').trim();
    if (value.isNotEmpty) {
      yield value;
    }
  }
  if (step.completion.mode == StepStudioCompletionMode.whenOutcomeEmitted) {
    final value = (step.completion.outcomeId ?? '').trim();
    if (value.isNotEmpty) {
      yield value;
    }
  }
}

List<String> _collectOutcomesForActionKinds(
  ScenarioAsset scenario,
  Set<String> actionKinds,
) {
  final values = <String>[];
  for (final node in scenario.nodes) {
    final actionKind = (node.payload.actionKind ?? '').trim().toLowerCase();
    if (!actionKinds.contains(actionKind)) {
      continue;
    }

    final fromBinding = (node.binding.outcomeId ?? '').trim();
    if (fromBinding.isNotEmpty) {
      values.add(fromBinding);
    }

    // Fallback défensif: certains anciens graphes utilisaient `params`.
    final fromParams = (node.payload.params['outcomeId'] ?? '').trim();
    if (fromParams.isNotEmpty) {
      values.add(fromParams);
    }
  }
  return _dedupeAndSort(values);
}

NarrativeOutcomeScope _classifyOutcomeScope(_MutableOutcome item) {
  final hasGlobal = item.scopes.contains(ScenarioScope.globalStory);
  final hasLocal = item.scopes.contains(ScenarioScope.localEventFlow);
  if (hasGlobal && hasLocal) {
    return NarrativeOutcomeScope.mixed;
  }
  if (hasGlobal) {
    return NarrativeOutcomeScope.global;
  }
  if (hasLocal) {
    return NarrativeOutcomeScope.local;
  }
  return NarrativeOutcomeScope.unknown;
}

List<String> _dedupeAndSort(List<String> source) {
  final set = <String>{...source};
  final out = set.toList(growable: false)
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

class _MutableStep {
  _MutableStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.globalScenarioId,
    required this.activationSummary,
    required this.completionSummary,
    required this.worldChangeCount,
  });

  final String id;
  final String name;
  final String description;
  final int order;
  final String globalScenarioId;
  final String activationSummary;
  final String completionSummary;
  final int worldChangeCount;
  final List<String> linkedCutsceneIds = <String>[];
  final List<String> expectedOutcomeIds = <String>[];
  final List<String> emittedOutcomeIds = <String>[];
}

class _MutableOutcome {
  _MutableOutcome({
    required this.id,
  });

  final String id;
  final Set<ScenarioScope> scopes = <ScenarioScope>{};
  final List<String> declaredByScenarioIds = <String>[];
  final List<String> emittedByScenarioIds = <String>[];
  final List<String> consumedByScenarioIds = <String>[];
}
