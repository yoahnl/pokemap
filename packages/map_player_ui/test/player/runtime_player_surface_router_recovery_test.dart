import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('the title offers recovery without hiding New Game',
      (tester) async {
    final dispatched = <RuntimePlayerAction>[];
    await tester.pumpWidget(_app(_titleSnapshot(withRecovery: true), dispatched));
    await tester.pumpAndSettle();

    expect(find.byKey(PlayerSaveRecoverySurface.surfaceKey), findsOneWidget);
    expect(
      find.byKey(
        PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.deleteSave),
      ),
      findsOneWidget,
    );
    expect(
      find.byType(PlayerTitleScreen),
      findsOneWidget,
      reason: 'a broken save must never block starting a new game',
    );
  });

  testWidgets('deleting from the title dispatches the runtime action',
      (tester) async {
    final dispatched = <RuntimePlayerAction>[];
    await tester.pumpWidget(_app(_titleSnapshot(withRecovery: true), dispatched));
    await tester.pumpAndSettle();

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

    expect(dispatched, <RuntimePlayerAction>[
      RuntimePlayerAction.deleteUnusableSave,
    ]);
  });

  testWidgets('a healthy title shows no recovery surface', (tester) async {
    final dispatched = <RuntimePlayerAction>[];
    await tester.pumpWidget(
      _app(_titleSnapshot(withRecovery: false), dispatched),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PlayerSaveRecoverySurface.surfaceKey), findsNothing);
    expect(dispatched, isEmpty);
  });
}

RuntimePlayerSnapshot _titleSnapshot({required bool withRecovery}) =>
    RuntimePlayerSnapshot(
      revision: 1,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Recovery Test',
      saveRecovery: withRecovery
          ? const SaveLoadDiagnostic(
              code: SaveLoadFailureCode.unsupportedSchema,
              detectedSchemaVersion: 2,
              expectedSchemaVersion: 1,
              recommendedActions: <SaveRecoveryAction>[
                SaveRecoveryAction.deleteSave,
                SaveRecoveryAction.returnToTitle,
              ],
            )
          : null,
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.newGame),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.deleteUnusableSave,
        ),
      ],
    );

Widget _app(
  RuntimePlayerSnapshot snapshot,
  List<RuntimePlayerAction> dispatched,
) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: RuntimePlayerSurfaceRouter(
        titlePresentation: const RuntimePlayerTitlePresentation(
          author: 'Certification',
        ),
        snapshot: snapshot,
        gameSceneBuilder: (_) => const SizedBox.shrink(),
        onAction: (action) async {
          dispatched.add(action);
          return const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted,
          );
        },
      ),
    );
