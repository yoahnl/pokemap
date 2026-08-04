import 'package:test/test.dart';

import '../../../../tools/performance/smart_tiles_performance_policy.dart';

void main() {
  test('portable work budgets report missing and over-budget counters', () {
    final violations = smartTilesWorkBudgetViolations(
      actual: const <String, int>{
        'visibleCell': 40,
        'tile': 201,
      },
      budget: const <String, int>{
        'visibleCell': 64,
        'tile': 200,
        'objectCandidate': 8,
      },
    );

    expect(
      violations,
      <String>[
        'tile=201 exceeds 200',
        'objectCandidate is missing',
      ],
    );
  });

  test('checked-in editor and runtime policies are finite viewport budgets',
      () {
    expect(smartTilesEditorNavigationWorkBudget, isNotEmpty);
    expect(smartTilesRuntimeNavigationWorkBudget, isNotEmpty);
    expect(
      smartTilesEditorNavigationWorkBudget.values,
      everyElement(allOf(greaterThan(0), lessThan(128 * 128))),
    );
    expect(
      smartTilesRuntimeNavigationWorkBudget.values,
      everyElement(allOf(greaterThan(0), lessThan(128 * 128))),
    );
  });
}
