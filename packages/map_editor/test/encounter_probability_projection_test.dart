import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' as core;
import 'package:map_editor/src/ui/panels/encounter_probability_projection.dart'
    as editor;

void main() {
  test('preview delegates encounter probability truth to map_core', () {
    expect(
      identical(
        editor.projectEncounterProbabilities,
        core.projectEncounterProbabilities,
      ),
      isTrue,
    );
  });

  test(
    'projects relative and resolved probabilities without conflating them',
    () {
      final projection = editor.projectEncounterProbabilities(
        chancePerStep: 0.12,
        weights: const <int>[50, 30, 20],
      );

      expect(projection.isValid, isTrue);
      expect(projection.totalWeight, 100);
      expect(
        projection.entries.map((entry) => entry.relativeShare),
        orderedEquals(<double>[0.5, 0.3, 0.2]),
      );
      expect(
        projection.entries.map((entry) => entry.resolvedChancePerStep),
        orderedEquals(<double>[0.06, 0.036, 0.024]),
      );
    },
  );

  test('rejects zero totals instead of displaying invented percentages', () {
    final projection = editor.projectEncounterProbabilities(
      chancePerStep: 0.12,
      weights: const <int>[0, 0],
    );

    expect(projection.isValid, isFalse);
    expect(
      projection.issues,
      contains(editor.EncounterProbabilityIssue.zeroTotalWeight),
    );
    expect(
      projection.issues,
      contains(editor.EncounterProbabilityIssue.nonPositiveWeight),
    );
    expect(
      projection.entries.every(
        (entry) =>
            entry.relativeShare == null && entry.resolvedChancePerStep == null,
      ),
      isTrue,
    );
  });

  test(
    'rejects a negative weight even when the arithmetic sum is positive',
    () {
      final projection = editor.projectEncounterProbabilities(
        chancePerStep: 0.2,
        weights: const <int>[-1, 3],
      );

      expect(projection.isValid, isFalse);
      expect(
        projection.issues,
        contains(editor.EncounterProbabilityIssue.nonPositiveWeight),
      );
      expect(
        projection.entries.every((entry) => entry.relativeShare == null),
        isTrue,
      );
    },
  );
}
