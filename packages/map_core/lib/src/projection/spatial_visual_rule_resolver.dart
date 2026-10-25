import '../diagnostics/world_rule_diagnostics.dart';
import '../models/project_manifest.dart';
import '../models/game_state.dart';
import '../models/world_rule.dart';
import '../models/spatial_visual_profile.dart';
import '../operations/narrative_fact_runtime.dart';
import 'world_rule_projection.dart';

final class SpatialVisualRuleResolver {
  SpatialVisualRuleResolver(ProjectManifest project)
    : _facts = NarrativeFactRuntimeResolver.fromFacts(project.facts) {
    final candidates = project.worldRules.where((rule) => rule.enabled && rule.target.kind == WorldRuleTargetKind.atmosphere).toList();
    final invalid = {for (final item in diagnoseWorldRules(project.copyWith(worldRules: candidates)).diagnostics)
      if (item.severity == WorldRuleDiagnosticSeverity.error) item.ruleId};
    _rules = candidates.where((rule) => !invalid.contains(rule.id)).toList()
      ..sort((a, b) {final priority = a.priority.compareTo(b.priority); return priority == 0 ? a.id.compareTo(b.id) : priority;});
  }
  final NarrativeFactRuntimeResolver _facts;
  late final List<WorldRuleDefinition> _rules;
  GameState? _lastState;
  String? _lastMap;
  SpatialVisualPatch _last = SpatialVisualPatch();
  SpatialVisualPatch resolve(GameState state, String mapId) {
    if (identical(state, _lastState) && mapId == _lastMap) return _last;
    var result = SpatialVisualPatch();
    for (final rule in _rules) {
      if (rule.target.mapId == mapId && worldRuleSourceMatches(rule.source, state, _facts)) {
        result = result.overriddenBy(rule.effect.visualSettings!);
      }
    }
    _lastState = state;
    _lastMap = mapId;
    return _last = result;
  }
}
