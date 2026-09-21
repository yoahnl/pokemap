part of 'world_workspace_controller.dart';

/// The hypotheses of a local test.
///
/// None of this touches the project or a save: the values live in an
/// in-memory game state built for the run and thrown away with it.
extension WorldWorkspaceSimulation on WorldWorkspaceController {
  bool isHypothetical(String factId) => simulationValues.containsKey(factId);

  NarrativeValue simulationValue(String factId) =>
      simulationValues[factId] ??
      fact(factId)?.initialValue ??
      const NarrativeValue.boolean(false);

  void setSimulationValue(String factId, NarrativeValue value) {
    simulationValues[factId] = value;
    report = null;
    changed();
  }

  void clearSimulationValue(String factId) {
    simulationValues.remove(factId);
    report = null;
    changed();
  }

  /// Removes the hypotheses only, never a definition.
  void resetSimulation() {
    simulationValues.clear();
    completedSteps.clear();
    consumedEvents.clear();
    report = null;
    changed();
  }

  void toggleCompletedStep(String stepId, bool completed) {
    completed ? completedSteps.add(stepId) : completedSteps.remove(stepId);
    report = null;
    changed();
  }

  void toggleConsumedEvent(String eventId, bool consumed) {
    consumed ? consumedEvents.add(eventId) : consumedEvents.remove(eventId);
    report = null;
    changed();
  }

  /// Drops the hypotheses a type change made meaningless, and keeps the rest.
  List<String> reconcileSimulation() {
    final dropped = <String>[];
    simulationValues.removeWhere((id, value) {
      final kind = fact(id)?.valueKind;
      if (kind == value.kind) return false;
      dropped.add(id);
      return true;
    });
    if (dropped.isNotEmpty) report = null;
    return dropped;
  }

  GameState simulationGameState() => GameState(
    saveId: 'ui12-simulation',
    narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
      valuesByFactId: Map.of(simulationValues),
    ),
    consumedEventIds: Set.of(consumedEvents),
    progression: PlayerProgression(
      completedStepIds: completedSteps.toList(growable: false),
    ),
  );

  void simulate() {
    reconcileSimulation();
    report = simulateNarrativeWorldState(
      project: project.copyWith(facts: facts, worldRules: rules),
      maps: maps,
      input: NarrativeWorldStateSimulationInput(
        gameState: simulationGameState(),
      ),
    );
    changed();
  }

  /// What the projection retained for a rule in the last run.
  NarrativeWorldRuleSimulationTrace? traceFor(String ruleId) =>
      report?.rules.where((trace) => trace.ruleId == ruleId).firstOrNull;

  /// The other rules competing for the same target key.
  List<NarrativeWorldRuleSimulationTrace> competitorsFor(String ruleId) {
    final trace = traceFor(ruleId);
    if (trace == null) return const [];
    return report!.rules
        .where(
          (other) =>
              other.ruleId != ruleId && other.targetKey == trace.targetKey,
        )
        .toList();
  }
}
