import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('an unsupported schema reports the detected and expected versions', () {
    final diagnostic = describeGameSaveLoadFailure(
      const UnsupportedSaveSchema(
        schemaVersion: 99,
        expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
        path: r'$.itemSystemSchemaVersion',
      ),
    );

    expect(diagnostic.code, SaveLoadFailureCode.unsupportedSchema);
    expect(diagnostic.detectedSchemaVersion, 99);
    expect(diagnostic.expectedSchemaVersion, currentItemSystemSaveSchemaVersion);
    expect(
      diagnostic.recommendedActions,
      <SaveRecoveryAction>[SaveRecoveryAction.returnToTitle],
      reason: 'a save from another schema cannot be repaired by retrying',
    );
  });

  test('a non numeric schema marker never leaks into the diagnostic', () {
    final diagnostic = describeGameSaveLoadFailure(
      const UnsupportedSaveSchema(
        schemaVersion: '<script>alert(1)</script>',
        expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
        path: r'$.itemSystemSchemaVersion',
      ),
    );

    expect(diagnostic.code, SaveLoadFailureCode.unsupportedSchema);
    expect(diagnostic.detectedSchemaVersion, isNull);
  });

  test('truncated json is unreadable and may be retried or deleted', () {
    final diagnostic = describeGameSaveLoadFailure(
      const FormatException('Unexpected end of input'),
    );

    expect(diagnostic.code, SaveLoadFailureCode.unreadable);
    expect(
      diagnostic.recommendedActions,
      <SaveRecoveryAction>[
        SaveRecoveryAction.retry,
        SaveRecoveryAction.deleteSave,
        SaveRecoveryAction.returnToTitle,
      ],
    );
  });

  test('an unexpected failure never offers deletion', () {
    final diagnostic = describeGameSaveLoadFailure(StateError('boom'));

    expect(diagnostic.code, SaveLoadFailureCode.invalidState);
    expect(
      diagnostic.recommendedActions,
      isNot(contains(SaveRecoveryAction.deleteSave)),
      reason: 'an unclassified failure must never authorise data loss',
    );
  });

  test('every diagnostic carries the expected schema and an action', () {
    final diagnostics = <SaveLoadDiagnostic>[
      describeGameSaveLoadFailure(
        const UnsupportedSaveSchema(
          schemaVersion: 2,
          expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
          path: r'$',
        ),
      ),
      describeGameSaveLoadFailure(const FormatException('broken')),
      describeGameSaveLoadFailure(ArgumentError('nope')),
    ];

    for (final diagnostic in diagnostics) {
      expect(diagnostic.expectedSchemaVersion, isNotNull);
      expect(diagnostic.recommendedActions, isNotEmpty);
    }
  });
}
