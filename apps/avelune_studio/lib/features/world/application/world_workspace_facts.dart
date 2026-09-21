part of 'world_workspace_controller.dart';

extension WorldWorkspaceFacts on WorldWorkspaceController {
  NarrativeFactDefinition? factBase(String id) =>
      _factBases[id] ?? project.facts.where((f) => f.id == id).firstOrNull;

  bool canUndoFact(String id) => _factHistory[id]?.isNotEmpty ?? false;

  List<String> get _newFactDraftIds => [
    for (final id in narrative.pendingFacts.keys)
      if (_factBases.containsKey(id) && _factBases[id] == null) id,
  ];

  Future<bool> saveNewFacts() async {
    if (_closed || saving) return false;
    for (final id in _newFactDraftIds) {
      if (!await saveFact(id)) return false;
    }
    if (_newFactDraftIds.isNotEmpty) {
      return _fail(
        const WorldFailure(
          'De nouveaux états ont été créés pendant l’enregistrement. '
          'Leurs brouillons sont conservés.',
        ),
      );
    }
    return true;
  }

  String createFact() {
    final id = narrative.identity('fact');
    _factBases[id] = null;
    _write(
      NarrativeFactDefinition(
        id: id,
        label: 'Nouvel état',
        initialValue: const NarrativeValue.boolean(false),
      ),
    );
    selectedFactId = id;
    error = null;
    changed();
    return id;
  }

  void editFact(NarrativeFactDefinition next) {
    final current = fact(next.id);
    if (current == next) return;
    (_factHistory[next.id] ??= []).add(current);
    _write(next);
    error = null;
    changed();
  }

  void undoFact(String id) {
    final history = _factHistory[id];
    if (history == null || history.isEmpty) return;
    final previous = history.removeLast();
    if (previous == null) {
      narrative.pendingFacts.remove(id);
    } else {
      _write(previous);
    }
    invalidate();
    changed();
  }

  void _write(NarrativeFactDefinition value) {
    narrative.pendingFacts[value.id] = value;
    invalidate();
  }

  /// Renames never change the identity, and the historical boolean binding is
  /// kept: the model only accepts it on a bool, so a type change has to drop
  /// it through an explicit decision rather than in the background.
  NarrativeFactTypeChangePreview? previewFactType(
    String id,
    NarrativeValueKind kind,
  ) {
    final current = fact(id);
    if (current == null || current.valueKind == kind) return null;
    return previewNarrativeFactTypeChange(
      project.copyWith(facts: facts, worldRules: rules),
      maps: maps,
      factId: id,
      nextKind: kind,
    );
  }

  /// The canonical creation derives the identity from the label and refuses
  /// any other one, so a new state only receives its final id here. The draft
  /// and the rules that already point at it follow that rename.
  NarrativeFactDefinition _canonical(NarrativeFactDefinition draft) =>
      addNarrativeFact(
        project,
        label: draft.label,
        description: draft.description,
        category: draft.category,
        initialValue: draft.initialValue,
        tags: draft.tags,
        legacyFlagName: draft.legacyFlagName,
      ).createdFact;

  void _rename(String from, String to) {
    if (from == to) return;
    narrative.pendingFacts.remove(from);
    _factBases.remove(from);
    _factHistory.remove(from);
    if (selectedFactId == from) selectedFactId = to;
    if (simulationValues.remove(from) case final value?) {
      simulationValues[to] = value;
    }
    for (final entry in pendingRules.entries.toList()) {
      final source = entry.value.source;
      if (source?.kind != WorldRuleSourceKind.fact ||
          source?.sourceId != from) {
        continue;
      }
      entry.value.source = WorldRuleSource.factValue(
        factId: to,
        operator: source!.factOperator ?? NarrativeFactOperator.equals,
        expectedValue:
            source.expectedFactValue ?? const NarrativeValue.boolean(true),
        label: source.label,
      );
    }
  }

  Future<bool> saveFact(String id) async {
    final drafted = fact(id);
    if (_closed || drafted == null) return false;
    final base = factBase(id);
    final NarrativeFactDefinition current;
    try {
      current = base == null ? _canonical(drafted) : drafted;
    } on Object catch (failure) {
      return _fail(failure);
    }
    final ticket = ++_generation;
    loading = saving = true;
    error = null;
    changed();
    try {
      final receipt = await port.publishFact(base: base, current: current);
      if (_closed || ticket != _generation) return false;
      _rename(id, current.id);
      _factBases[current.id] = current;
      if (narrative.pendingFacts[current.id] == current) {
        narrative.pendingFacts.remove(current.id);
      }
      _factHistory.remove(current.id);
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      invalidate();
      return true;
    } on Object catch (failure) {
      return ticket == _generation ? _fail(failure) : false;
    } finally {
      if (!_closed && ticket == _generation) {
        loading = saving = false;
        changed();
      }
    }
  }

  /// Refuses while anything still reads or writes the state, including the
  /// rule drafts that are not published yet.
  List<String> factBlockers(String id) => [
    for (final usage
        in model.facts
            .where((entry) => entry.fact.id == id)
            .expand((entry) => entry.usages))
      usage.ownerLabel,
    for (final rule in pendingRules.values)
      if (rule.source?.kind == WorldRuleSourceKind.fact &&
          rule.source?.sourceId == id)
        '${rule.label} (brouillon)',
  ];

  Future<bool> deleteFact(String id) async {
    final base = project.facts.where((f) => f.id == id).firstOrNull;
    if (_closed) return false;
    if (factBlockers(id).isNotEmpty) {
      return _fail(
        const WorldFailure('Cet état est utilisé : il ne peut être supprimé.'),
      );
    }
    if (base == null) {
      narrative.pendingFacts.remove(id);
      _factBases.remove(id);
      _factHistory.remove(id);
      if (selectedFactId == id) selectedFactId = null;
      invalidate();
      changed();
      return true;
    }
    final ticket = ++_generation;
    loading = saving = true;
    changed();
    try {
      final receipt = await port.deleteFact(base);
      if (_closed || ticket != _generation) return false;
      narrative.pendingFacts.remove(id);
      _factBases.remove(id);
      _factHistory.remove(id);
      if (selectedFactId == id) selectedFactId = null;
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      invalidate();
      return true;
    } on Object catch (failure) {
      return ticket == _generation ? _fail(failure) : false;
    } finally {
      if (!_closed && ticket == _generation) {
        loading = saving = false;
        changed();
      }
    }
  }
}
