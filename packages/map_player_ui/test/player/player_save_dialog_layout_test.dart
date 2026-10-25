import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_save_dialog.dart';
import 'package:map_runtime/map_runtime.dart';

const _address = RuntimePlayerSaveAddress(
  gameId: 'save-layout',
  profileId: 'profile',
  slotId: 'slot',
);

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashMarcellus',
    )..addFont(rootBundle.load('assets/fonts/Marcellus-Regular.ttf'))).load();
  });

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 432),
    const Size(496, 432),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final safe in [
        EdgeInsets.zero,
        const EdgeInsets.fromLTRB(12, 24, 18, 20),
      ]) {
        testWidgets(
          'exit dialog fits its real route $size text=$scale safe=$safe',
          (tester) async {
            final snapshot = ValueNotifier(_snapshot());
            addTearDown(snapshot.dispose);
            var saves = 0;
            var discards = 0;
            await _openDialog(
              tester,
              snapshot,
              size: size,
              scale: scale,
              safe: safe,
              onSave: () async {
                saves++;
                return const RuntimePlayerCommandResult(
                  status: RuntimePlayerCommandStatus.accepted,
                );
              },
              onDiscard: () async {
                discards++;
                return const RuntimePlayerCommandResult(
                  status: RuntimePlayerCommandStatus.accepted,
                );
              },
            );
            expect(
              ModalRoute.of(tester.element(find.byType(PlayerSaveDialog))),
              isA<DialogRoute<void>>(),
            );
            final panel = tester.getRect(
              find.byKey(const ValueKey('runtime-save-panel')),
            );
            final allowed = safe.deflateRect(Offset.zero & size).deflate(16);
            expect(panel.left, greaterThanOrEqualTo(allowed.left - .5));
            expect(panel.top, greaterThanOrEqualTo(allowed.top - .5));
            expect(panel.right, lessThanOrEqualTo(allowed.right + .5));
            expect(panel.bottom, lessThanOrEqualTo(allowed.bottom + .5));
            expect(panel.height, lessThanOrEqualTo(600));
            expect(find.byType(Scrollable), findsNothing);
            final keys = [
              const ValueKey('runtime-exit-stay'),
              const ValueKey('runtime-exit-discard'),
              const ValueKey('runtime-save-confirm'),
            ];
            final buttons = find.descendant(
              of: find.byType(PlayerSaveDialog),
              matching: find.byType(PlayerActionButton),
            );
            expect(
              tester
                  .widgetList<PlayerActionButton>(buttons)
                  .map((button) => button.key),
              keys,
            );
            for (final key in keys) {
              final action = find.byKey(key);
              expect(action.hitTestable(), findsOneWidget);
              final rect = tester.getRect(action);
              expect(rect.height, greaterThanOrEqualTo(48));
              expect(rect.top, greaterThanOrEqualTo(panel.top));
              expect(rect.bottom, lessThanOrEqualTo(panel.bottom));
            }
            if (size.width > size.height) {
              final first = tester.getRect(find.byKey(keys.first));
              for (final key in keys.skip(1)) {
                final bounds = tester.getRect(find.byKey(key));
                expect(bounds.top, closeTo(first.top, .5));
                expect(bounds.bottom, closeTo(first.bottom, .5));
              }
            }
            if (scale == 1) {
              expect(panel.height, lessThan(380));
              expect(
                find.byKey(const ValueKey('player-page-next')),
                findsNothing,
              );
              final content = tester.getRect(find.byType(PlayerPagedList));
              final firstAction = tester.getRect(find.byKey(keys.first));
              expect(firstAction.top - content.bottom, closeTo(12, .5));
            } else {
              final next = find.byKey(const ValueKey('player-page-next'));
              if (next.evaluate().isNotEmpty) {
                expect(next.hitTestable(), findsOneWidget);
                await tester.tap(next);
                await tester.pumpAndSettle();
              }
            }
            expect(saves, 0);
            expect(discards, 0);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(keys.first));
            await tester.pumpAndSettle();
            expect(find.byType(PlayerSaveDialog), findsNothing);
            expect(saves, 0);
            expect(discards, 0);
          },
        );
      }
    }
  }

  testWidgets('save failure remeasures the dialog to its shorter result', (
    tester,
  ) async {
    final snapshot = ValueNotifier(_snapshot());
    addTearDown(snapshot.dispose);
    var saves = 0;
    var receipts = 0;
    await _openDialog(
      tester,
      snapshot,
      size: const Size(390, 844),
      scale: 1,
      safe: EdgeInsets.zero,
      returnToTitle: false,
      onSave: () async {
        saves++;
        return const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.failed,
          safeMessage: 'Espace disque insuffisant.',
        );
      },
      onReceipt: (_) => receipts++,
    );
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Espace disque insuffisant.'), findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-save-result')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('runtime-save-panel'))).height,
      lessThan(260),
    );
    expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
    expect(saves, 1);
    expect(receipts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a measured exit dialog keeps its canonical pending guard and result',
    (tester) async {
      final snapshot = ValueNotifier(_snapshot());
      addTearDown(snapshot.dispose);
      final pending = Completer<RuntimePlayerCommandResult>();
      var saves = 0;
      var receipts = 0;
      await _openDialog(
        tester,
        snapshot,
        size: const Size(390, 844),
        scale: 2,
        safe: const EdgeInsets.fromLTRB(12, 24, 18, 20),
        onSave: () {
          saves++;
          snapshot.value = snapshot.value.next(
            phase: RuntimePlayerPhase.saving,
            actions: const [],
          );
          return pending.future;
        },
        onReceipt: (_) => receipts++,
      );
      final confirm = find.byKey(const ValueKey('runtime-save-confirm'));
      await tester.tap(confirm);
      await tester.pump();
      await tester.tap(confirm);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(saves, 1);
      expect(tester.widget<PlayerActionButton>(confirm).onPressed, isNull);
      expect(find.byType(PlayerSaveDialog), findsOneWidget);
      snapshot.value = snapshot.value.next(phase: RuntimePlayerPhase.title);
      pending.complete(
        const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlayerSaveDialog), findsNothing);
      expect(saves, 1);
      expect(receipts, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

RuntimePlayerSnapshot _snapshot() => RuntimePlayerSnapshot(
  revision: 1,
  phase: RuntimePlayerPhase.paused,
  gameTitle: 'Game',
  activeSaveAddress: _address,
  actions: const [
    RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
    RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.returnToTitle),
  ],
);

Future<void> _openDialog(
  WidgetTester tester,
  ValueNotifier<RuntimePlayerSnapshot> snapshot, {
  required Size size,
  required double scale,
  required EdgeInsets safe,
  required Future<RuntimePlayerCommandResult> Function() onSave,
  bool returnToTitle = true,
  Future<RuntimePlayerCommandResult> Function()? onDiscard,
  ValueChanged<RuntimePlayerSaveReceipt>? onReceipt,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: scale > 1 ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: safe,
          viewPadding: safe,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => PlayerMenuThemeScope(
                  child: PlayerSaveDialog(
                    snapshot: snapshot,
                    returnToTitle: returnToTitle,
                    hardwareGamepadEnabled: false,
                    onSave: onSave,
                    onDiscard:
                        onDiscard ??
                        () async => const RuntimePlayerCommandResult(
                          status: RuntimePlayerCommandStatus.accepted,
                        ),
                    onReceiptShown: onReceipt ?? (_) {},
                  ),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
