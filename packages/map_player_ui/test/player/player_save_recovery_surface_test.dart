import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 432),
    const Size(496, 432),
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'recovery is a compact modal with safe actions $size dark=$dark text=$scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final activated = <SaveRecoveryAction>[];
            await tester.pumpWidget(
              _app(
                diagnostic: const SaveLoadDiagnostic(
                  code: SaveLoadFailureCode.unreadable,
                  expectedSchemaVersion: 1,
                  recommendedActions: [
                    SaveRecoveryAction.retry,
                    SaveRecoveryAction.returnToTitle,
                    SaveRecoveryAction.deleteSave,
                  ],
                ),
                activated: activated,
                theme: dark
                    ? PokeMapPlayerTheme.dark()
                    : PokeMapPlayerTheme.light(),
                scale: scale,
                companion: size.width == 496,
              ),
            );
            await tester.pumpAndSettle();
            final card = find.byKey(
              const ValueKey('player-save-recovery-card'),
            );
            final bounds = tester.getRect(card);
            expect(bounds.width, lessThanOrEqualTo(500));
            expect(bounds.left, greaterThanOrEqualTo(14));
            expect(bounds.right, lessThanOrEqualTo(size.width - 14));
            expect(bounds.top, greaterThanOrEqualTo(24));
            expect(bounds.bottom, lessThanOrEqualTo(size.height - 20));
            final scrim = tester.widget<ColoredBox>(
              find.byKey(const ValueKey('player-save-recovery-scrim')),
            );
            expect(scrim.color.a, greaterThan(0));
            expect(scrim.color.a, lessThan(1));
            expect(find.byType(PlayerSessionPanel), findsNothing);
            expect(find.byType(Scrollable), findsNothing);
            if (scale == 1) {
              expect(bounds.height, lessThan(340));
              final retry = tester.getRect(
                find.byKey(
                  PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.retry),
                ),
              );
              final title = tester.getRect(
                find.byKey(
                  PlayerSaveRecoverySurface.actionKey(
                    SaveRecoveryAction.returnToTitle,
                  ),
                ),
              );
              final delete = tester.getRect(
                find.byKey(
                  PlayerSaveRecoverySurface.actionKey(
                    SaveRecoveryAction.deleteSave,
                  ),
                ),
              );
              expect(retry.top, closeTo(title.top, .5));
              expect(delete.top, greaterThanOrEqualTo(retry.bottom + 8));
              expect(
                find.byKey(const ValueKey('player-page-next')),
                findsNothing,
              );
            }
            final delete = tester.widget<PlayerActionButton>(
              find.byKey(
                PlayerSaveRecoverySurface.actionKey(
                  SaveRecoveryAction.deleteSave,
                ),
                skipOffstage: false,
              ),
            );
            final danger = PokeMapPlayerMenuTheme.resolve(tester.element(card))
                .danger;
            expect(delete.foregroundColor, danger);
            expect(delete.backgroundColor, isNotNull);
            expect(activated, isEmpty);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets('authored windows retain their recovery composition', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        diagnostic: const SaveLoadDiagnostic(
          code: SaveLoadFailureCode.unreadable,
          expectedSchemaVersion: 1,
          recommendedActions: [SaveRecoveryAction.retry],
        ),
        activated: <SaveRecoveryAction>[],
        theme: PokeMapPlayerTheme.withWindowProfile(
          PokeMapPlayerTheme.dark(),
          legacyProjectPresentationWindows,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerSessionPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('player-save-recovery-scrim')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every recommended action and nothing else', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(
      find.byKey(PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.retry)),
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
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(PlayerSaveRecoverySurface.actionKey(SaveRecoveryAction.retry)),
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
    await tester.pumpAndSettle();

    expect(find.textContaining('version 2'), findsOneWidget);
    expect(find.textContaining('version 1'), findsOneWidget);
  });

  testWidgets('deleting requires an explicit second confirmation', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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

  testWidgets('never exposes a file path or a technical message', (
    tester,
  ) async {
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
  ThemeData? theme,
  double scale = 1,
  bool companion = false,
}) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: theme ?? PokeMapPlayerTheme.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.fromLTRB(12, 24, 18, 20),
      viewPadding: const EdgeInsets.fromLTRB(12, 24, 18, 20),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: companion
        ? PlayerCompanionScope(
            child: PlayerSaveRecoverySurface(
              diagnostic: diagnostic,
              onAction: activated.add,
            ),
          )
        : PlayerSaveRecoverySurface(
            diagnostic: diagnostic,
            onAction: activated.add,
          ),
  ),
);
