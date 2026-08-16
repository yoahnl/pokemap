import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('renders every recommended action and nothing else',
      (tester) async {
    final activated = <SaveRecoveryAction>[];
    await tester.pumpWidget(
      _app(
        diagnostic: const SaveLoadDiagnostic(
          code: SaveLoadFailureCode.unreadable,
          expectedSchemaVersion: 1,
          recommendedActions: <SaveRecoveryAction>[
            SaveRecoveryAction.retry,
            SaveRecoveryAction.returnToTitle,
          ],
        ),
        activated: activated,
      ),
    );

    expect(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.retry),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.returnToTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.deleteSave),
      ),
      findsNothing,
      reason: 'an action the case does not allow must never be offered',
    );
    expect(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.restoreBackup),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.retry),
      ),
    );
    expect(activated, <SaveRecoveryAction>[SaveRecoveryAction.retry]);
  });

  testWidgets('shows the detected and expected versions', (tester) async {
    await tester.pumpWidget(
      _app(
        diagnostic: const SaveLoadDiagnostic(
          code: SaveLoadFailureCode.unsupportedSchema,
          detectedSchemaVersion: 2,
          expectedSchemaVersion: 1,
          recommendedActions: <SaveRecoveryAction>[
            SaveRecoveryAction.returnToTitle,
          ],
        ),
        activated: <SaveRecoveryAction>[],
      ),
    );

    expect(find.textContaining('version 2'), findsOneWidget);
    expect(find.textContaining('version 1'), findsOneWidget);
  });

  testWidgets('deleting requires an explicit second confirmation',
      (tester) async {
    final activated = <SaveRecoveryAction>[];
    await tester.pumpWidget(
      _app(
        diagnostic: const SaveLoadDiagnostic(
          code: SaveLoadFailureCode.unreadable,
          expectedSchemaVersion: 1,
          recommendedActions: <SaveRecoveryAction>[
            SaveRecoveryAction.deleteSave,
            SaveRecoveryAction.returnToTitle,
          ],
        ),
        activated: activated,
      ),
    );

    await tester.tap(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.deleteSave),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('player-save-recovery-delete-confirm')),
      findsOneWidget,
    );
    expect(
      activated,
      isEmpty,
      reason: 'the first tap must never erase anything',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('player-save-recovery-delete-cancel')),
    );
    await tester.pumpAndSettle();
    expect(activated, isEmpty);

    await tester.tap(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.deleteSave),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('player-save-recovery-delete-accept')),
    );
    await tester.pumpAndSettle();
    expect(activated, <SaveRecoveryAction>[SaveRecoveryAction.deleteSave]);
  });

  testWidgets('never exposes a file path or a technical message',
      (tester) async {
    for (final code in SaveLoadFailureCode.values) {
      await tester.pumpWidget(
        _app(
          diagnostic: SaveLoadDiagnostic(
            code: code,
            expectedSchemaVersion: 1,
            recommendedActions: const <SaveRecoveryAction>[
              SaveRecoveryAction.returnToTitle,
            ],
          ),
          activated: <SaveRecoveryAction>[],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('/'), findsNothing);
      expect(find.textContaining('.json'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining(code.name), findsNothing);
    }
  });
}

Widget _app({
  required SaveLoadDiagnostic diagnostic,
  required List<SaveRecoveryAction> activated,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(
        body: PlayerSaveRecoverySurface(
          diagnostic: diagnostic,
          onAction: activated.add,
        ),
      ),
    );
