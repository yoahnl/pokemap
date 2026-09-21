import 'package:map_core/map_core_domain.dart';

import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/world_port.dart';

export '../domain/world_port.dart';

part 'world_workspace_facts.dart';
part 'world_workspace_rule_publication.dart';
part 'world_workspace_rules.dart';
part 'world_workspace_simulation.dart';

/// States and world rules of one project.
///
/// States are not owned here: stories already keep their working version in
/// [NarrativeWorkspaceController.pendingFacts], and this controller edits that
/// same draft so a state opened from a story and from this page stay one
/// document. Rules had no draft store yet, so this controller keeps theirs.
class WorldWorkspaceController {
  WorldWorkspaceController(this.narrative, this.port, {required this.changed});

  final NarrativeWorkspaceController narrative;
  final WorldPort port;
  final void Function() changed;

  final _factBases = <String, NarrativeFactDefinition?>{};
  final pendingRules = <String, WorldRuleDraft>{};
  final _ruleBases = <String, WorldRuleDefinition?>{};
  final _factHistory = <String, List<NarrativeFactDefinition?>>{};
  final _ruleHistory = <String, List<WorldRuleDraft?>>{};
  final simulationValues = <String, NarrativeValue>{};
  final completedSteps = <String>{};
  final consumedEvents = <String>{};

  List<MapData> _maps = const [];
  FactsWorldRulesManagerReadModel? _model;
  String? _modelKey;
  NarrativeWorldStateSimulationReport? report;
  String? selectedFactId, selectedRuleId, error;
  bool loading = false, initialized = false, _closed = false;
  bool saving = false;
  int _generation = 0;

  ProjectManifest get project => narrative.project;
  List<MapData> get maps => _maps;

  List<NarrativeFactDefinition> get facts => narrative.facts;

  /// Only whole relations reach the projections: an unfinished draft stays in
  /// the library and in its editor, never in what the game would read.
  List<WorldRuleDefinition> get rules {
    final merged = <String, WorldRuleDefinition>{
      for (final rule in project.worldRules) rule.id: rule,
    };
    for (final draft in pendingRules.values) {
      if (draft.complete case final complete?) merged[draft.id] = complete;
    }
    return merged.values.toList();
  }

  WorldRuleDraft? ruleDraft(String id) {
    final pending = pendingRules[id];
    if (pending != null) return pending;
    final published = project.worldRules.where((r) => r.id == id).firstOrNull;
    return published == null ? null : WorldRuleDraft.of(published);
  }

  bool get dirty =>
      narrative.pendingFacts.isNotEmpty || pendingRules.isNotEmpty;

  bool isFactDirty(String id) => narrative.pendingFacts.containsKey(id);
  bool isRuleDirty(String id) => pendingRules.containsKey(id);

  NarrativeFactDefinition? fact(String id) =>
      facts.where((item) => item.id == id).firstOrNull;
  WorldRuleDefinition? rule(String id) =>
      rules.where((item) => item.id == id).firstOrNull;
  bool get hasRuleDraft => pendingRules.isNotEmpty;

  NarrativeFactDefinition? get activeFact =>
      selectedFactId == null ? null : fact(selectedFactId!);
  WorldRuleDraft? get activeRule =>
      selectedRuleId == null ? null : ruleDraft(selectedRuleId!);

  /// The library, usages and picker catalogues, rebuilt only when the
  /// documents they read actually change.
  FactsWorldRulesManagerReadModel get model {
    final key = _projectionKey();
    if (_modelKey != key || _model == null) {
      final drafted = project.copyWith(facts: facts, worldRules: rules);
      _model = buildFactsWorldRulesManagerReadModel(
        drafted,
        maps: _maps,
        dependencyIndex: buildNarrativeDependencyIndex(
          project: drafted,
          maps: _maps,
        ),
      );
      _modelKey = key;
    }
    return _model!;
  }

  String _projectionKey() => [
    project.facts.length,
    project.worldRules.length,
    _maps.length,
    for (final fact in narrative.pendingFacts.values) fact.toJson().toString(),
    for (final draft in pendingRules.values) draft.signature,
    for (final fact in project.facts) fact.id,
    for (final rule in project.worldRules) rule.id,
  ].join('|');

  void invalidate() {
    _modelKey = null;
    report = null;
  }

  Future<void> initialize() async {
    if (_closed) return;
    final ticket = ++_generation;
    loading = true;
    changed();
    try {
      final loaded = await port.loadMaps();
      if (_closed || ticket != _generation) return;
      _maps = loaded;
      initialized = true;
      invalidate();
      error = null;
    } on Object catch (failure) {
      if (!_closed && ticket == _generation) error = failure.toString();
    } finally {
      if (!_closed && ticket == _generation) {
        loading = false;
        changed();
      }
    }
  }

  void selectFact(String? id) {
    selectedFactId = id;
    error = null;
    changed();
  }

  void selectRule(String? id) {
    selectedRuleId = id;
    error = null;
    changed();
  }

  bool _fail(Object failure) {
    if (!_closed) {
      error = failure.toString();
      changed();
    }
    return false;
  }

  void dispose() {
    _closed = true;
    _generation++;
  }
}
