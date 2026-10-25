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
    if (current.target.mapId.isNotEmpty &&
        !await loadTargetMap(current.target.mapId)) {
      return false;
    }
    if (_closed) return false;
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
  WorldRuleDefinition _canonicalRule(
    WorldRuleDefinition current, {
    ProjectManifest? manifest,
  }) => addWorldRule(
    manifest ?? project,
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

  Future<bool> saveAll() async {
    if (_closed || saving) return false;
    final ids = pendingRules.keys.toList();
    if (ids.isEmpty) return true;
    for (final mapId in {
      for (final id in ids)
        if (pendingRules[id]?.target?.mapId case final String mapId)
          if (mapId.isNotEmpty) mapId,
    }) {
      if (!await loadTargetMap(mapId) || _closed) return false;
    }
    final List<
      ({String id, WorldRuleDefinition? base, WorldRuleDefinition current})
    >
    prepared;
    try {
      prepared = _prepareRuleBatch(ids);
    } on Object catch (failure) {
      return _fail(failure);
    }
    final dependencies = <String, NarrativeFactDefinition>{};
    for (final publication in prepared) {
      final dependency = _draftedSource(publication.current.source);
      if (dependency != null) dependencies[dependency.id] = dependency;
    }
    final savedFacts = <String>[];
    for (final dependency in dependencies.values) {
      final publication = saveFact(dependency.id);
      final generation = _generation;
      final saved = await publication;
      if (_closed || generation != _generation) return false;
      if (!saved) {
        return _ruleBatchFailure(savedFacts, error ?? 'écriture refusée');
      }
      savedFacts.add(dependency.label);
    }
    final List<
      ({String id, WorldRuleDefinition? base, WorldRuleDefinition current})
    >
    publications;
    try {
      publications = dependencies.isEmpty ? prepared : _prepareRuleBatch(ids);
    } on Object catch (failure) {
      return _ruleBatchFailure(savedFacts, failure);
    }
    final ticket = ++_generation;
    loading = saving = true;
    error = null;
    changed();
    try {
      if (_closed || ticket != _generation) return false;
      final receipt = await port.publishRuleBatch(
        rules: [
          for (final publication in publications)
            (base: publication.base, current: publication.current),
        ],
      );
      if (_closed || ticket != _generation) return false;
      narrative.workspace.acceptResources(receipt.before, receipt.manifest);
      var removed = false;
      for (final publication in publications) {
        if (!pendingRules.containsKey(publication.id)) {
          removed = true;
          continue;
        }
        _adoptRule(publication.id, publication.current);
      }
      invalidate();
      return !removed && pendingRules.isEmpty;
    } on Object catch (failure) {
      return ticket == _generation
          ? _ruleBatchFailure(savedFacts, failure)
          : false;
    } finally {
      if (!_closed && ticket == _generation) {
        loading = saving = false;
        changed();
      }
    }
  }

  List<({String id, WorldRuleDefinition? base, WorldRuleDefinition current})>
  _prepareRuleBatch(List<String> ids) {
    if (ids.length > maxWorldRuleBatchSize) {
      throw const WorldFailure('Enregistrez au maximum 128 règles à la fois.');
    }
    final manifest = project.copyWith(facts: facts);
    var projected = manifest;
    final publications =
        <
          ({String id, WorldRuleDefinition? base, WorldRuleDefinition current})
        >[];
    for (final id in ids) {
      final draft = pendingRules[id];
      if (draft == null) {
        throw const WorldFailure(
          'Un brouillon a été retiré pendant l’enregistrement.',
        );
      }
      final current = draft.complete;
      if (current == null) {
        throw WorldFailure(
          'Il manque ${draft.missing.join(', ')} à la règle « ${draft.label} ».',
        );
      }
      final base = ruleBase(id);
      final sent = base == null
          ? _canonicalRule(current, manifest: projected)
          : current;
      publications.add((id: id, base: base, current: sent));
      if (base == null) {
        projected = projected.copyWith(
          worldRules: [...projected.worldRules, sent],
        );
      }
    }
    upsertWorldRules(
      manifest,
      rules: [for (final publication in publications) publication.current],
      maps: maps,
    );
    return publications;
  }

  bool _ruleBatchFailure(List<String> savedFacts, Object failure) {
    if (savedFacts.isEmpty) return _fail(failure);
    final states = savedFacts.map((label) => '« $label »').join(', ');
    return _fail(
      WorldFailure(
        '${savedFacts.length == 1 ? 'L’état $states a' : 'Les états $states ont'} '
        'bien été enregistré${savedFacts.length == 1 ? '' : 's'}, mais pas les '
        'règles : $failure',
      ),
    );
  }
}
