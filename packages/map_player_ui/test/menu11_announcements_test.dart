import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_save_dialog.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('short exit dialog retains three reachable large text actions',
      (tester) async {
    const size = Size(844, 390);
    const insets = EdgeInsets.fromLTRB(24, 30, 24, 20);
    final snapshot = ValueNotifier(RuntimePlayerSnapshot(
      revision: 1,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aventure',
      activeSaveAddress: const RuntimePlayerSaveAddress(
          gameId: 'test', profileId: 'player', slotId: 'slot'),
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.returnToTitle),
      ],
    ));
    addTearDown(snapshot.dispose);
    await _pump(
        tester,
        PlayerSaveDialog(
          snapshot: snapshot,
          onSave: () async => const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted),
          onDiscard: () async => const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted),
          returnToTitle: true,
          hardwareGamepadEnabled: false,
          onReceiptShown: (_) {},
        ),
        size: size,
        textScaler: const TextScaler.linear(2),
        insets: insets);
    expect(tester.takeException(), isNull);
    for (final id in [
      'runtime-exit-stay',
      'runtime-exit-discard',
      'runtime-save-confirm',
    ]) {
      final finder = find.byKey(ValueKey(id));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(finder);
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, greaterThanOrEqualTo(48));
      expect(bounds.top, greaterThanOrEqualTo(insets.top));
      expect(bounds.bottom, lessThanOrEqualTo(size.height - insets.bottom));
      expect(finder.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  for (final exiting in [false, true]) {
    testWidgets('${exiting ? 'exit' : 'save'} pending is one live announcement',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final pending = Completer<RuntimePlayerCommandResult>();
      final snapshot = ValueNotifier(RuntimePlayerSnapshot(
        revision: 1,
        phase: RuntimePlayerPhase.paused,
        gameTitle: 'Aventure',
        activeSaveAddress: const RuntimePlayerSaveAddress(
            gameId: 'test', profileId: 'player', slotId: 'slot'),
        actions: const [
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
          RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.returnToTitle),
        ],
      ));
      addTearDown(snapshot.dispose);
      await _pump(
          tester,
          PlayerSaveDialog(
            snapshot: snapshot,
            onSave: () => pending.future,
            onDiscard: () => pending.future,
            returnToTitle: exiting,
            hardwareGamepadEnabled: false,
            onReceiptShown: (_) {},
          ));
      final message = exiting ? 'Retour au titre…' : 'Sauvegarde en cours…';
      expect(find.bySemanticsLabel(message), findsNothing);
      await tester.tap(find.byKey(
          ValueKey(exiting ? 'runtime-exit-discard' : 'runtime-save-confirm')));
      await tester.pump();
      final node = _liveMessage(tester, message);
      await tester.pump(const Duration(milliseconds: 200));
      expect(_liveMessage(tester, message).id, node.id);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.failed, safeMessage: 'Annulée'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('bag snapshot messages update one live announcement',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final message = ValueNotifier<String?>(null);
    addTearDown(message.dispose);
    await _pump(
        tester,
        ValueListenableBuilder<String?>(
            valueListenable: message,
            builder: (_, value, __) =>
                RuntimePlayerBag(detail: _bag(message: value))));
    const first = 'Objet utilisé : 20 PV restaurés.';
    expect(find.bySemanticsLabel(first), findsNothing);
    message.value = first;
    await tester.pump();
    final node = _liveMessage(tester, first);
    await tester.pump();
    expect(_liveMessage(tester, first).id, node.id);
    const second = 'Cet objet est incompatible.';
    message.value = second;
    await tester.pump();
    expect(find.bySemanticsLabel(first), findsNothing);
    expect(_liveMessage(tester, second).id, node.id);
    message.value = null;
    await tester.pump();
    expect(find.bySemanticsLabel(second), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('bag command failure announces only the safe message',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
        tester,
        RuntimePlayerBag(
            detail: _bag(),
            onFavoriteChanged: (_, __) async {
              throw StateError('/private/secret');
            }));
    await tester.tap(find.byKey(const ValueKey('bag-favorite-potion')));
    await tester.pumpAndSettle();
    _liveMessage(tester, 'Cette action a échoué. Réessayez.');
    expect(find.bySemanticsLabel(RegExp('private/secret')), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

SemanticsNode _liveMessage(WidgetTester tester, String message) {
  final finder = find.bySemanticsLabel(message);
  expect(finder, findsOneWidget);
  final node = tester.getSemantics(finder);
  expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
  expect(node.getSemanticsData().label, message);
  return node;
}

RuntimePlayerPauseDetailSnapshot _bag({String? message}) =>
    RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.bag,
        title: 'Sac',
        message: message,
        bagPockets: const [
          RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins')
        ],
        entries: [
          RuntimePlayerDetailEntrySnapshot(
              id: 'potion',
              title: 'Potion',
              bagItem: RuntimePlayerBagItemSnapshot(
                  itemId: 'potion',
                  quantity: 2,
                  sortOrder: 0,
                  pocketId: 'medicine',
                  description: 'Restaure des PV.'))
        ]);

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(1440, 900),
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets insets = EdgeInsets.zero}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: textScaler, padding: insets, viewPadding: insets),
        child: child!),
    home: PlayerMenuThemeScope(child: Scaffold(body: SafeArea(child: child))),
  ));
  await tester.pumpAndSettle();
}
