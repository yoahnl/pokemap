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
  testWidgets('save dialogs honor remapped confirmation and back',
      (tester) async {
    final harness = _Harness();
    final profile = PlayerControlProfile.standard
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'keyQ')
        .profile
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.secondary,
            inputId: 'keyW')
        .profile;
    await _pump(tester, harness, controlProfile: profile);
    await _openSave(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-dialog')), findsNothing);
    expect(harness.actions, isEmpty);
    await _openSave(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pump();
    expect(harness.actions, [RuntimePlayerAction.save]);
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsOneWidget);
  });

  testWidgets('save dialogs keep the player text scale below the Navigator',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness, sessionTextScale: 1.6);
    await _openSave(tester);
    final dialog =
        tester.element(find.byKey(const ValueKey('runtime-save-dialog')));
    expect(MediaQuery.textScalerOf(dialog).scale(10), 16);
  });

  testWidgets('confirmation is read only and initially focuses Cancel',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    expect(harness.actions, isEmpty);
    expect(find.text('Profil « yoahn », slot « slot-2 ».'), findsOneWidget);
    expect(find.text('Lieu : Hanazuki'), findsOneWidget);
    expect(find.text('Durée de jeu : 1 h 01 min'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-dialog')), findsNothing);
    expect(harness.actions, isEmpty);
  });

  testWidgets('pending save survives Back lifecycle and duplicate activation',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    final confirm = find.byKey(const ValueKey('runtime-save-confirm'));
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();
    expect(harness.actions, [RuntimePlayerAction.save]);
    expect(find.text('Sauvegarde en cours…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('runtime-save-dialog')), findsOneWidget);
    harness.snapshot.value = harness.snapshot.value.next(
      phase: RuntimePlayerPhase.lifecyclePaused,
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Sauvegarde en cours…'), findsOneWidget);
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsOneWidget);
    expect(harness.actions, [RuntimePlayerAction.save]);
  });

  testWidgets('success uses one live result and the real receipt',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsOneWidget);
    expect(find.text('Profil « yoahn », slot « slot-2 ».'), findsOneWidget);
    final result = tester
        .widget<Semantics>(find.byKey(const ValueKey('runtime-save-result')));
    expect(result.properties.liveRegion, isTrue);
    expect(find.byKey(const ValueKey('runtime-save-receipt')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('runtime-save-return')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-dialog')), findsNothing);
    expect(find.byKey(const ValueKey('runtime-save-receipt')), findsNothing);
  });

  testWidgets('a failed write remains visible and retries only on request',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.fail('Espace disque insuffisant.');
    await tester.pumpAndSettle();
    expect(find.text('Espace disque insuffisant.'), findsOneWidget);
    expect(find.text('Partie sauvegardée'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(harness.actions, [RuntimePlayerAction.save]);
    harness.pending = Completer<RuntimePlayerCommandResult>();
    await tester.tap(find.byKey(const ValueKey('runtime-save-retry')));
    await tester.pump();
    expect(
        harness.actions, [RuntimePlayerAction.save, RuntimePlayerAction.save]);
    harness.succeed();
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsOneWidget);
  });

  testWidgets('accepted command without a new receipt never claims success',
      (tester) async {
    final harness = _Harness();
    harness.snapshot.value = harness.snapshot.value.next(
      saveReceipt: const RuntimePlayerSaveReceipt(
          address: _address, trigger: GameSessionCheckpointTrigger.manual),
    );
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.snapshot.value =
        harness.snapshot.value.next(phase: RuntimePlayerPhase.paused);
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-save-retry')), findsOneWidget);
  });

  testWidgets('changing session removes an old pending result', (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.snapshot.value = RuntimePlayerSnapshot(
      revision: 8,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Autre aventure',
    );
    await tester.pumpAndSettle();
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-save-dialog')), findsNothing);
    expect(find.text('Partie sauvegardée'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 wide at text scale 2 stacks actions within 342 pixels',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final harness = _Harness();
    await _pump(tester, harness, resize: false);
    await _openSave(tester);
    final panel =
        tester.getRect(find.byKey(const ValueKey('runtime-save-panel')));
    final cancel =
        tester.getRect(find.byKey(const ValueKey('runtime-save-cancel')));
    final confirm =
        tester.getRect(find.byKey(const ValueKey('runtime-save-confirm')));
    expect(panel.width, 342);
    expect(confirm.top - cancel.bottom, 12);
    expect(cancel.height, greaterThanOrEqualTo(48));
    expect(confirm.height, greaterThanOrEqualTo(48));
    expect(confirm.left, cancel.left);
    expect(find.byKey(const ValueKey('runtime-save-confirm')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Return to title initially focuses Stay and makes no request',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await tester.tap(find.text('Retour au titre'));
    await tester.pumpAndSettle();
    expect(find.text('Rester'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
    expect(harness.actions, isEmpty);
  });

  testWidgets('save and quit emits one typed request and waits for completion',
      (tester) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(tester, harness, onReturnToTitle: (save) {
      exits.add(save);
      harness.snapshot.value = harness.snapshot.value.next(
        phase: RuntimePlayerPhase.saving,
        actions: const [],
      );
      return harness.pending.future;
    });
    await tester.tap(find.text('Retour au titre'));
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
  });

  testWidgets('a failed save and quit keeps the session and offers retry',
      (tester) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(tester, harness, onReturnToTitle: (save) {
      exits.add(save);
      return harness.pending.future;
    });
    await tester.tap(find.text('Retour au titre'));
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

  testWidgets('discard emits only the explicit false exit request',
      (tester) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(tester, harness, onReturnToTitle: (save) async {
      exits.add(save);
      return _accepted;
    });
    await tester.tap(find.text('Retour au titre'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('runtime-exit-discard')));
    await tester.pumpAndSettle();
    expect(exits, [false]);
    expect(harness.actions, isEmpty);
    expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
  });

  testWidgets('a reader without explicit exit cannot imply a discard',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await tester.tap(find.text('Retour au titre'));
    await tester.pumpAndSettle();
    final discard = tester.widget<PlayerActionButton>(
        find.byKey(const ValueKey('runtime-exit-discard')));
    expect(discard.onPressed, isNull);
    expect(
        tester
            .widget<PlayerActionButton>(
              find.byKey(const ValueKey('runtime-save-confirm')),
            )
            .onPressed,
        isNull);
    expect(discard.disabledReason,
        'Ce lecteur ne permet pas de quitter sans sauvegarder.');
    expect(harness.actions, isEmpty);
  });

  testWidgets('discard follows live exit availability before confirmation',
      (tester) async {
    final harness = _Harness();
    final exits = <bool>[];
    await _pump(tester, harness, onReturnToTitle: (save) async {
      exits.add(save);
      return _accepted;
    });
    await tester.tap(find.text('Retour au titre'));
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
        isNull);
    expect(exits, isEmpty);
  });

  testWidgets('a new receipt from another operation is not a save success',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.snapshot.value = harness.snapshot.value.next(
      phase: RuntimePlayerPhase.paused,
      saveReceipt: const RuntimePlayerSaveReceipt(
        address: _address,
        trigger: GameSessionCheckpointTrigger.manual,
      ),
    );
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-save-retry')), findsOneWidget);
  });

  testWidgets('unknown metadata and another slot timestamp are omitted',
      (tester) async {
    final harness = _Harness();
    harness.snapshot.value = harness.snapshot.value.next(
      clearPauseDetails: true,
      continueSave: _summary('other-slot'),
    );
    await _pump(tester, harness);
    await _openSave(tester);
    expect(find.textContaining('Durée de jeu'), findsNothing);
    expect(find.textContaining('Dernière sauvegarde'), findsNothing);
    expect(find.textContaining('other-slot'), findsNothing);
    expect(find.text('Profil « yoahn », slot « slot-2 ».'), findsOneWidget);
  });

  testWidgets('a known timestamp is shown only for the active address',
      (tester) async {
    final harness = _Harness();
    harness.snapshot.value = harness.snapshot.value.next(
      continueSave: _summary('slot-2'),
    );
    await _pump(tester, harness);
    await _openSave(tester);
    expect(find.textContaining('Dernière sauvegarde'), findsOneWidget);
  });

  testWidgets('a receipt from a different slot never reports success',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await _openSave(tester);
    await tester.tap(find.byKey(const ValueKey('runtime-save-confirm')));
    await tester.pump();
    harness.snapshot.value = harness.snapshot.value.next(
      phase: RuntimePlayerPhase.paused,
      saveReceipt: const RuntimePlayerSaveReceipt(
        address: RuntimePlayerSaveAddress(
          gameId: 'com.example.aube',
          profileId: 'yoahn',
          slotId: 'other-slot',
        ),
        trigger: GameSessionCheckpointTrigger.manual,
      ),
    );
    harness.pending.complete(_accepted);
    await tester.pumpAndSettle();
    expect(find.text('Partie sauvegardée'), findsNothing);
    expect(find.textContaining('other-slot'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-save-retry')), findsOneWidget);
  });

  testWidgets('the dialog keeps the session locale on the root Navigator',
      (tester) async {
    final harness = _Harness();
    await _pump(tester, harness, sessionLocale: const Locale('fr'));
    await _openSave(tester);
    expect(find.text('Sauvegarder la partie ?'), findsOneWidget);
    expect(find.text('Save game?'), findsNothing);
  });
}

PlayerSaveSummary _summary(String slot) => PlayerSaveSummary(
      address: SaveSlotAddress(
          gameId: _address.gameId, profileId: _address.profileId, slotId: slot),
      updatedAt: DateTime(2026, 9, 6, 17, 42),
      playTimeSeconds: 200,
      status: SaveStatus.active,
      canContinue: true,
    );

final class _Harness {
  final snapshot = ValueNotifier(RuntimePlayerSnapshot(
    revision: 1,
    phase: RuntimePlayerPhase.paused,
    gameTitle: 'Aube',
    pauseSection: RuntimePlayerPauseSection.root,
    activeSaveAddress: _address,
    actions: const [
      RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
      RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
      RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToTitle),
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
  ));
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
          address: _address, trigger: GameSessionCheckpointTrigger.manual),
    );
    pending.complete(RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
      saveReceipt: snapshot.value.saveReceipt,
    ));
  }

  void fail(String message) {
    snapshot.value = snapshot.value.next(phase: RuntimePlayerPhase.paused);
    pending.complete(RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.failed, safeMessage: message));
  }
}

Future<void> _pump(WidgetTester tester, _Harness harness,
    {bool resize = true,
    Locale? sessionLocale,
    double? sessionTextScale,
    PlayerControlProfile? controlProfile,
    Future<RuntimePlayerCommandResult> Function(bool)? onReturnToTitle}) async {
  if (resize) {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  addTearDown(harness.snapshot.dispose);
  await tester.pumpWidget(MaterialApp(
    locale: sessionLocale == null ? const Locale('fr') : const Locale('en'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    home: Material(child: Builder(builder: (context) {
      final router = MediaQuery(
        data: sessionTextScale == null
            ? MediaQuery.of(context)
            : MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sessionTextScale)),
        child: ValueListenableBuilder<RuntimePlayerSnapshot>(
          valueListenable: harness.snapshot,
          builder: (context, snapshot, _) => RuntimePlayerSurfaceRouter(
            snapshot: snapshot,
            titlePresentation:
                const RuntimePlayerTitlePresentation(author: 'Studio Test'),
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
    })),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openSave(WidgetTester tester) async {
  final save = find.text('Sauvegarder');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}
