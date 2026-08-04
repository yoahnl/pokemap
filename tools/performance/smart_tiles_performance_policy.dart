/// Portable Smart Tiles performance policy.
///
/// Wall-clock timings remain host-specific. These work-count ceilings are the
/// deterministic CI gate: a fixed viewport must stay far below even the
/// smallest supported rich-map extent (128²), whatever machine runs the test.
const Map<String, int> smartTilesEditorNavigationWorkBudget = <String, int>{
  'visibleCell': 2048,
  'tile': 4096,
  'collision': 2048,
  'smartOwner': 15000,
  'smartPattern': 256,
  'objectCandidate': 128,
  'objectVisualCache': 64,
  'gridLine': 256,
};

const Map<String, int> smartTilesRuntimeNavigationWorkBudget = <String, int>{
  'visibleCell': 2048,
  'tile': 4096,
  'collision': 2048,
  'smartOwner': 15000,
  'smartPattern': 256,
  'objectCandidate': 128,
  'placedCandidate': 128,
  'entityCandidate': 128,
  'regularVisualCache': 64,
  'objectVisualCache': 64,
};

List<String> smartTilesWorkBudgetViolations({
  required Map<String, int> actual,
  required Map<String, int> budget,
}) {
  final violations = <String>[];
  for (final entry in budget.entries) {
    final actualValue = actual[entry.key];
    if (actualValue == null) {
      violations.add('${entry.key} is missing');
    } else if (actualValue > entry.value) {
      violations.add('${entry.key}=$actualValue exceeds ${entry.value}');
    }
  }
  return List<String>.unmodifiable(violations);
}
