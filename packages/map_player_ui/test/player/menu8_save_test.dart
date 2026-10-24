import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

const _address = RuntimePlayerSaveAddress(
  gameId: 'com.example.aube',
  profileId: 'yoahn',
  slotId: 'slot-2',
);
const _accepted = RuntimePlayerCommandResult(
  status: RuntimePlayerCommandStatus.accepted,
);

void main() {
  testWidgets('Save starts directly and rejects duplicate activation', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    final shell = tester.widget<RuntimePlayerPauseShell>(
      find.byType(RuntimePlayerPauseShell),
    );
    shell.onSelected(PlayerPauseAction.save);
    shell.onSelected(PlayerPauseAction.save);
    await tester.pump();
    expect(harness.actions, [RuntimePlayerAction.save]);
    expect(find.byType(Dialog), findsNothing);
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-receipt')), findsOneWidget);
    expect(find.textContaining('Partie sauvegardée'), findsOneWidget);
    expect(harness.snapshot.value.pauseSection, RuntimePlayerPauseSection.root);
  });

  testWidgets('failed direct save stays on the menu and retries on request', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    harness.fail('Espace disque insuffisant.');
    await tester.pumpAndSettle();
    expect(find.text('Espace disque insuffisant.'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(harness.actions, [RuntimePlayerAction.save]);
    harness.pending = Completer<RuntimePlayerCommandResult>();
    await _openSave(tester);
    expect(harness.actions, [
      RuntimePlayerAction.save,
      RuntimePlayerAction.save,
    ]);
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.textContaining('Partie sauvegardée'), findsOneWidget);
  });

  for (final kind in ['missing', 'unrelated', 'other-slot']) {
    testWidgets('$kind receipt cannot certify direct saving', (tester) async {
      final harness = _Harness();
      await _pump(tester, harness);
      await _openSave(tester);
      final receipt = RuntimePlayerSaveReceipt(
        address: kind == 'other-slot'
            ? const RuntimePlayerSaveAddress(
                gameId: 'com.example.aube',
                profileId: 'yoahn',
                slotId: 'other-slot',
              )
            : _address,
        trigger: GameSessionCheckpointTrigger.manual,
      );
      harness.snapshot.value = harness.snapshot.value.next(
        phase: RuntimePlayerPhase.paused,
        saveReceipt: kind == 'missing' ? null : receipt,
      );
      harness.pending.complete(
        RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted,
          saveReceipt: kind == 'unrelated'
              ? null
              : kind == 'missing'
              ? null
              : receipt,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Partie sauvegardée'), findsNothing);
      expect(
        find.byKey(const ValueKey('runtime-save-receipt')),
        findsOneWidget,
      );
    });
  }

  testWidgets('changing session ignores a pending direct-save result', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    harness.snapshot.value = RuntimePlayerSnapshot(
      revision: 9,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Autre aventure',
    );
    await tester.pumpAndSettle();
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-receipt')), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Return to title initially focuses Stay and makes no request', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openExit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Rester'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
    expect(harness.actions, isEmpty);
  });

  testWidgets(
    'save and quit emits one typed request and waits for completion',
    (tester) async {
      final harness = _Harness();
      final exits = <bool>[];
      await _pump(
        tester,
        harness,
        onReturnToTitle: (save) {
          exits.add(save);
          harness.snapshot.value = harness.snapshot.value.next(
            phase: RuntimePlayerPhase.saving,
            actions: const [],
          );
          return harness.pending.future;
        },
      );
      await _openExit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Sauvegarder et quitter'), findsOneWidget);
      final confirm = find.byKey(const ValueKey('runtime-save-confirm'));
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump();
      expect(exits, [true]);
      expect(harness.actions, isEmpty);
      expect(confirm, findsOneWidget);
      expect(tester.widget<PlayerActionButton>(confirm).onPressed, isNull);
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsOneWidget);
      harness.snapshot.value = RuntimePlayerSnapshot(
        revision: 8,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
      );
      harness.pending.complete(_accepted);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
      expect(exits, [true]);
    },
  );

  testWidgets('a failed save and quit keeps the session and offers retry', (
    tester,
  ) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(
      tester,
      harness,
      onReturnToTitle: (save) {
        exits.add(save);
        return harness.pending.future;
      },
    );
    await _openExit(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.fail('Le disque est plein.');
    await tester.pumpAndSettle();
    expect(find.text('Le disque est plein.'), findsOneWidget);
    expect(harness.snapshot.value.phase, RuntimePlayerPhase.paused);
    expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsOneWidget);
    harness.pending = Completer<RuntimePlayerCommandResult>();
    await tester.tap(find.byKey(const ValueKey('runtime-save-retry')));
    await tester.pump();
    expect(exits, [true, true]);
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
  });

  testWidgets('discard emits only the explicit false exit request', (
    tester,
  ) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(
      tester,
      harness,
      onReturnToTitle: (save) async {
        exits.add(save);
        return _accepted;
      },
    );
    await _openExit(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('runtime-exit-discard')));
    await tester.pumpAndSettle();
    expect(exits, [false]);
    expect(harness.actions, isEmpty);
    expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
  });

  testWidgets('a reader without explicit exit cannot imply a discard', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openExit(tester);
    await tester.pumpAndSettle();
    final discard = tester.widget<PlayerActionButton>(
      find.byKey(const ValueKey('runtime-exit-discard')),
    );
    expect(discard.onPressed, isNull);
    expect(
      tester
          .widget<PlayerActionButton>(
            find.byKey(const ValueKey('runtime-save-confirm')),
          )
          .onPressed,
      isNull,
    );
    expect(
      discard.disabledReason,
      'Ce lecteur ne permet pas de quitter sans sauvegarder.',
    );
    expect(harness.actions, isEmpty);
  });

  testWidgets('discard follows live exit availability before confirmation', (
    tester,
  ) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(
      tester,
      harness,
      onReturnToTitle: (save) async {
        exits.add(save);
        return _accepted;
      },
    );
    await _openExit(tester);
    await tester.pumpAndSettle();
    harness.snapshot.value = harness.snapshot.value.next(
      phase: RuntimePlayerPhase.lifecyclePaused,
      actions: const [],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<PlayerActionButton>(
            find.byKey(const ValueKey('runtime-exit-discard')),
          )
          .onPressed,
      isNull,
    );
    expect(exits, isEmpty);
  });

  testWidgets('unknown metadata and another slot timestamp are omitted', (
    tester,
  ) async {
    final harness = _Harness();
    harness.snapshot.value = harness.snapshot.value.next(
      clearPauseDetails: true,
      continueSave: _summary('other-slot'),
    );
    await _pump(tester, harness);
    await _openExit(tester);
    expect(find.textContaining('Durée de jeu'), findsNothing);
    expect(find.textContaining('Dernière sauvegarde'), findsNothing);
    expect(find.textContaining('other-slot'), findsNothing);
    expect(find.text('Profil « yoahn », slot « slot-2 ».'), findsOneWidget);
  });

  testWidgets('a known timestamp is shown only for the active address', (
    tester,
  ) async {
    final harness = _Harness();
    harness.snapshot.value = harness.snapshot.value.next(
      continueSave: _summary('slot-2'),
    );
    await _pump(tester, harness);
    await _openExit(tester);
    expect(find.textContaining('Dernière sauvegarde'), findsOneWidget);
  });
}

PlayerSaveSummary _summary(String slot) => PlayerSaveSummary(
  address: SaveSlotAddress(
    gameId: _address.gameId,
    profileId: _address.profileId,
    slotId: slot,
  ),
  updatedAt: DateTime(2026, 9, 6, 17, 42),
  playTimeSeconds: 200,
  status: SaveStatus.active,
  canContinue: true,
);

final class _Harness {
  final snapshot = ValueNotifier(
    RuntimePlayerSnapshot(
      revision: 1,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      activeSaveAddress: _address,
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToTitle,
        ),
      ],
      pauseDetails: {
        RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.profile,
          title: 'Profil',
          profile: RuntimePlayerProfileSnapshot(
            playerName: 'Yoahn',
            currentMapId: 'hanazuki',
            locationName: 'Hanazuki',
            money: 1200,
            playtimeSeconds: 3661,
          ),
        ),
      },
    ),
  );
  final actions = <RuntimePlayerAction>[];
  var pending = Completer<RuntimePlayerCommandResult>();

  Future<RuntimePlayerCommandResult> onAction(RuntimePlayerAction action) {
    actions.add(action);
    if (action != RuntimePlayerAction.save) return Future.value(_accepted);
    snapshot.value = snapshot.value.next(
      phase: RuntimePlayerPhase.saving,
      clearSaveReceipt: true,
    );
    return pending.future;
  }

  void succeed() {
    snapshot.value = snapshot.value.next(
      phase: RuntimePlayerPhase.paused,
      saveReceipt: RuntimePlayerSaveReceipt(
        address: _address,
        trigger: GameSessionCheckpointTrigger.manual,
      ),
    );
    pending.complete(
      RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
        saveReceipt: snapshot.value.saveReceipt,
      ),
    );
  }

  void fail(String message) {
    snapshot.value = snapshot.value.next(phase: RuntimePlayerPhase.paused);
    pending.complete(
      RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed,
        safeMessage: message,
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Harness harness, {
  bool resize = true,
  Locale? sessionLocale,
  double? sessionTextScale,
  PlayerControlProfile? controlProfile,
  Future<RuntimePlayerCommandResult> Function(bool)? onReturnToTitle,
}) async {
  if (resize) {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  addTearDown(harness.snapshot.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: sessionLocale == null ? const Locale('fr') : const Locale('en'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Material(
        child: Builder(
          builder: (context) {
            final router = MediaQuery(
              data: sessionTextScale == null
                  ? MediaQuery.of(context)
                  : MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(sessionTextScale)),
              child: ValueListenableBuilder<RuntimePlayerSnapshot>(
                valueListenable: harness.snapshot,
                builder: (context, snapshot, _) => RuntimePlayerSurfaceRouter(
                  snapshot: snapshot,
                  titlePresentation: const RuntimePlayerTitlePresentation(
                    author: 'Studio Test',
                  ),
                  gameSceneBuilder: (_) => const SizedBox.expand(),
                  onAction: harness.onAction,
                  controlProfile: controlProfile,
                  onReturnToTitle: onReturnToTitle,
                ),
              ),
            );
            return sessionLocale == null
                ? router
                : Localizations.override(
                    context: context,
                    locale: sessionLocale,
                    child: router,
                  );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSave(WidgetTester tester) async {
  await _pageTo(tester, find.text('Sauvegarder'));
  await tester.tap(find.text('Sauvegarder'));
  await tester.pump();
}

Future<void> _openExit(WidgetTester tester) async {
  await _pageTo(tester, find.text('Retour au titre'));
  await tester.tap(find.text('Retour au titre'));
  await tester.pumpAndSettle();
}

Future<void> _pageTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; finder.hitTestable().evaluate().isEmpty && i < 20; i++) {
    final next = find.byKey(const ValueKey('player-page-next')).hitTestable();
    final enabled = next
        .evaluate()
        .where((e) => (e.widget as IconButton).onPressed != null)
        .toList();
    if (enabled.isEmpty) break;
    await tester.tap(find.byWidget(enabled.first.widget));
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget);
}
