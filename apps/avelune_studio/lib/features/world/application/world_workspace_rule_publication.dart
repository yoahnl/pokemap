part of 'world_workspace_controller.dart';

extension WorldWorkspaceRulePublication on WorldWorkspaceController {
  NarrativeFactDefinition? unsavedRuleDependency(String id) {
    final source = ruleDraft(id)?.source;
    return source == null ? null : _draftedSource(source);
  }

  NarrativeFactDefinition? _draftedSource(WorldRuleSource source) =>
      source.kind != WorldRuleSourceKind.fact ||
          project.facts.any((fact) => fact.id == source.sourceId)
      ? null
      : narrative.pendingFacts[source.sourceId];

  Future<bool> saveRule(String id) async {
    final draft = ruleDraft(id);
    if (_closed || draft == null) return false;
    final current = draft.complete;
    if (current == null) {
      return _fail(
        WorldFailure('Il manque ${draft.missing.join(', ')} à cette règle.'),
      );
    }
    final base = ruleBase(id);
    final WorldRuleDefinition sent;
    try {
      sent = base == null ? _canonicalRule(current) : current;
    } on Object catch (failure) {
      return _fail(_preparationFailure(current, failure));
    }
    final ticket = ++_generation;
    loading = saving = true;
    error = null;
    changed();
    try {
      final receipt = await port.publishRule(base: base, current: sent);
      if (_closed || ticket != _generation) return false;
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      _adoptRule(id, sent);
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

  /// Creation names the rule canonically and refuses any other identity, so a
  /// new rule only receives its final id here.
  WorldRuleDefinition _canonicalRule(WorldRuleDefinition current) =>
      addWorldRule(
        project,
        label: current.label,
        description: current.description,
        enabled: current.enabled,
        source: current.source,
        target: current.target,
        effect: current.effect,
        priority: current.priority,
        tags: current.tags,
        debugTechnicalLabel: current.debugTechnicalLabel,
        maps: maps,
      ).createdRule;

  /// A rule cannot be written before the state it reads. That dependency is
  /// named to the author instead of surfacing the authoring error.
  Object _preparationFailure(WorldRuleDefinition rule, Object failure) {
    final pending = _draftedSource(rule.source);
    return pending == null
        ? failure
        : WorldFailure(
            'L’état « ${pending.label} » n’est pas encore enregistré. '
            'Enregistrez-le d’abord, puis cette règle.',
          );
  }

  /// The publication becomes the saved base. A draft edited while the write
  /// was in flight survives it, under the identity the publication settled on.
  void _adoptRule(String id, WorldRuleDefinition sent) {
    final canonical = sent.id;
    final published =
        project.worldRules.where((rule) => rule.id == canonical).firstOrNull ??
        sent;
    if (canonical != id) {
      final live = pendingRules.remove(id);
      final history = _ruleHistory.remove(id);
      _ruleBases.remove(id);
      if (selectedRuleId == id) selectedRuleId = canonical;
      if (live != null) pendingRules[canonical] = live.copy(id: canonical);
      if (history != null) {
        _ruleHistory[canonical] = [
          for (final previous in history) previous?.copy(id: canonical),
        ];
      }
    }
    _ruleBases[canonical] = published;
    final live = pendingRules[canonical];
    if (live == null ||
        live.signature == WorldRuleDraft.of(published).signature) {
      pendingRules.remove(canonical);
      _ruleHistory.remove(canonical);
    }
  }

  /// Saves the state a rule depends on, then the rule, and reports a partial
  /// result as such rather than as a success or as a single failure.
  Future<bool> saveRuleWithDependency(String id) async {
    final dependency = unsavedRuleDependency(id);
    if (dependency == null) return saveRule(id);
    if (!await saveFact(dependency.id)) return false;
    if (await saveRule(id)) return true;
    return _fail(
      WorldFailure(
        'L’état « ${dependency.label} » a bien été enregistré, mais pas la '
        'règle : ${error ?? 'écriture refusée'}',
      ),
    );
  }

  /// The rule drafts join the workspace-wide protections: closing the project
  /// with an unsaved relation goes through the same choice as any document.
  Future<bool> saveAll() async {
    for (final id in pendingRules.keys.toList()) {
      if (!await saveRuleWithDependency(id)) return false;
    }
    return pendingRules.isEmpty;
  }
}
