part of 'world_workspace_controller.dart';

/// A rule while the author composes it.
///
/// The canonical definition requires its three parts at once, and the author
/// fills them one at a time. A draft therefore keeps them optional and only
/// becomes a [WorldRuleDefinition] when the relation is whole; an unfinished
/// draft stays navigable and is never published.
class WorldRuleDraft {
  WorldRuleDraft({
    required this.id,
    required this.label,
    this.description = '',
    this.enabled = true,
    this.priority = 0,
    this.source,
    this.target,
    this.effect,
    this.tags = const <String>[],
    this.debugTechnicalLabel,
  });

  factory WorldRuleDraft.of(WorldRuleDefinition rule) => WorldRuleDraft(
    id: rule.id,
    label: rule.label,
    description: rule.description,
    enabled: rule.enabled,
    priority: rule.priority,
    source: rule.source,
    target: rule.target,
    effect: rule.effect,
    tags: rule.tags,
    debugTechnicalLabel: rule.debugTechnicalLabel,
  );

  final String id;
  String label, description;
  bool enabled;
  int priority;
  WorldRuleSource? source;
  WorldRuleTarget? target;
  WorldRuleEffect? effect;
  List<String> tags;
  String? debugTechnicalLabel;

  List<String> get missing => [
    if (label.trim().isEmpty) 'un nom',
    if (source == null) 'la condition',
    if (target == null) 'la cible',
    if (effect == null) 'l’effet',
  ];

  WorldRuleDefinition? get complete => missing.isNotEmpty
      ? null
      : WorldRuleDefinition(
          id: id,
          label: label,
          description: description,
          enabled: enabled,
          source: source!,
          target: target!,
          effect: effect!,
          priority: priority,
          tags: tags,
          debugTechnicalLabel: debugTechnicalLabel,
        );

  WorldRuleDraft copy() => WorldRuleDraft(
    id: id,
    label: label,
    description: description,
    enabled: enabled,
    priority: priority,
    source: source,
    target: target,
    effect: effect,
    tags: tags,
    debugTechnicalLabel: debugTechnicalLabel,
  );

  String get signature => [
    id,
    label,
    description,
    enabled,
    priority,
    source?.toJson(),
    target?.toJson(),
    effect?.toJson(),
  ].join('|');
}

extension WorldWorkspaceRules on WorldWorkspaceController {
  WorldRuleDefinition? ruleBase(String id) =>
      _ruleBases[id] ?? project.worldRules.where((r) => r.id == id).firstOrNull;

  bool canUndoRule(String id) => _ruleHistory[id]?.isNotEmpty ?? false;

  String createRule({String? factId}) {
    final id = narrative.identity('world_rule');
    _ruleBases[id] = null;
    final source = factId == null
        ? null
        : WorldRuleSource.factValue(
            factId: factId,
            operator: NarrativeFactOperator.equals,
            expectedValue: _defaultExpected(factId),
          );
    pendingRules[id] = WorldRuleDraft(
      id: id,
      label: 'Nouvelle règle',
      source: source,
    );
    selectedRuleId = id;
    error = null;
    invalidate();
    changed();
    return id;
  }

  NarrativeValue _defaultExpected(String factId) =>
      switch (fact(factId)?.valueKind) {
        NarrativeValueKind.integer => NarrativeValue.integer(0),
        NarrativeValueKind.string => const NarrativeValue.string(''),
        _ => const NarrativeValue.boolean(true),
      };

  void editRule(String id, void Function(WorldRuleDraft) change) {
    final current = ruleDraft(id);
    if (current == null) return;
    final next = current.copy();
    change(next);
    if (next.signature == current.signature) return;
    (_ruleHistory[id] ??= []).add(current);
    pendingRules[id] = next;
    error = null;
    invalidate();
    changed();
  }

  void undoRule(String id) {
    final history = _ruleHistory[id];
    if (history == null || history.isEmpty) return;
    final previous = history.removeLast();
    if (previous == null) {
      pendingRules.remove(id);
    } else {
      pendingRules[id] = previous;
    }
    invalidate();
    changed();
  }

  /// Effects the model accepts for the target already chosen.
  List<WorldRuleEffectPickerOption> effectsFor(String id) {
    final kind = ruleDraft(id)?.target?.kind;
    if (kind == null) return const [];
    return model.effectOptions
        .where(
          (option) =>
              option.compatibleTargetKind == kind &&
              isWorldRuleEffectCompatibleWithTarget(kind, option.effectKind),
        )
        .toList();
  }

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
    // Creation names the rule canonically and refuses any other identity, so
    // a new rule only receives its final id at publication.
    final published = base == null
        ? addWorldRule(
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
          ).createdRule
        : current;
    final ticket = ++_generation;
    loading = true;
    error = null;
    changed();
    try {
      final receipt = await port.publishRule(base: base, current: published);
      if (_closed || ticket != _generation) return false;
      if (published.id != id) {
        pendingRules.remove(id);
        _ruleBases.remove(id);
        _ruleHistory.remove(id);
        if (selectedRuleId == id) selectedRuleId = published.id;
      }
      _ruleBases[published.id] = published;
      pendingRules.remove(published.id);
      _ruleHistory.remove(published.id);
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      invalidate();
      return true;
    } on Object catch (failure) {
      return ticket == _generation ? _fail(failure) : false;
    } finally {
      if (!_closed && ticket == _generation) {
        loading = false;
        changed();
      }
    }
  }

  Future<bool> deleteRule(String id) async {
    final base = project.worldRules.where((r) => r.id == id).firstOrNull;
    if (_closed) return false;
    if (base == null) {
      pendingRules.remove(id);
      _ruleBases.remove(id);
      _ruleHistory.remove(id);
      if (selectedRuleId == id) selectedRuleId = null;
      invalidate();
      changed();
      return true;
    }
    final ticket = ++_generation;
    loading = true;
    changed();
    try {
      final receipt = await port.deleteRule(base);
      if (_closed || ticket != _generation) return false;
      pendingRules.remove(id);
      _ruleBases.remove(id);
      _ruleHistory.remove(id);
      if (selectedRuleId == id) selectedRuleId = null;
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      invalidate();
      return true;
    } on Object catch (failure) {
      return ticket == _generation ? _fail(failure) : false;
    } finally {
      if (!_closed && ticket == _generation) {
        loading = false;
        changed();
      }
    }
  }
}
