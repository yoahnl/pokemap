import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'landscape shop keeps four articles and the detail action visible with real font and safe insets',
    (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final font = ByteData.sublistView(
          await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
        );
        await (FontLoader('Avenir Next')..addFont(Future.value(font))).load();
      });
      final commands = <RuntimeWorldServiceCommand>[];
      await _pump(
        tester,
        _snapshot(fourEntries: true),
        commands.add,
        safePadding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
      );
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      final cards = [
        for (final id in ['potion', 'super-potion', 'antidote', 'revive'])
          tester.getRect(find.byKey(ValueKey('shop-item-$id'))),
      ];
      expect(cards[0].top, cards[1].top);
      expect(cards[2].top, cards[3].top);
      expect(cards[2].top, greaterThan(cards[0].bottom));
      for (final card in cards) {
        expect(card.height, greaterThanOrEqualTo(48));
        expect(card.top, greaterThanOrEqualTo(12));
        expect(card.bottom, lessThanOrEqualTo(370));
      }
      expect(find.byKey(const ValueKey('shop-open-quantity')), findsOneWidget);
      final label = tester.renderObject<RenderParagraph>(
        find.text('Super Potion'),
      );
      expect(
        label.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(label.size.width + .5),
      );
      final stock = tester.renderObject<RenderParagraph>(
        find.text('700 ₽ · Stock : 12'),
      );
      expect(
        stock.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(stock.size.width + .5),
      );
      await tester.tap(find.byKey(const ValueKey('shop-item-antidote')));
      expect(commands.single.action, RuntimeWorldServiceAction.select);
      expect(commands.single.targetId, 'antidote');
      expect(commands.single.snapshotRevision, 7);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'companion shop keeps four articles in two columns without pagination',
    (tester) async {
      tester.view.physicalSize = const Size(496, 432);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final font = ByteData.sublistView(
          await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
        );
        await (FontLoader('Avenir Next')..addFont(Future.value(font))).load();
      });
      await _pump(
        tester,
        _snapshot(fourEntries: true),
        (_) {},
        companion: true,
      );
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      final cards = [
        for (final id in ['potion', 'super-potion', 'antidote', 'revive'])
          tester.getRect(find.byKey(ValueKey('shop-item-$id'))),
      ];
      expect(cards[0].top, cards[1].top);
      expect(cards[2].top, cards[3].top);
      expect(cards[2].top, greaterThan(cards[0].bottom));
      expect(cards.last.bottom, lessThan(432));
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shop starts with its list and waits for runtime selection before quantity',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final initial = _snapshot();
      await _pump(tester, initial, commands.add);
      expect(find.text('Boutique du Port'), findsOneWidget);
      expect(find.text('500 ₽'), findsOneWidget);
      expect(find.textContaining('Stock : 3'), findsWidgets);
      expect(find.byKey(const ValueKey('shop-quantity-plus')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('shop-item-potion')));
      await tester.pumpAndSettle();
      expect(commands.single.action, RuntimeWorldServiceAction.select);
      expect(commands.single.snapshotRevision, 7);
      expect(commands.single.targetId, 'potion');
      expect(find.byKey(const ValueKey('shop-quantity-review')), findsNothing);
      await _pump(tester, initial.next(), commands.add);
      expect(
        find.byKey(const ValueKey('shop-quantity-review')),
        findsOneWidget,
      );
      expect(find.text('Prix unitaire : 60 ₽'), findsOneWidget);
      expect(find.text('Total : 60 ₽'), findsOneWidget);
      expect(find.text('Solde après : 440 ₽'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shop-quantity-plus')));
      await tester.tap(find.byKey(const ValueKey('shop-buy')));
      expect(commands.map((command) => command.action), [
        RuntimeWorldServiceAction.select,
        RuntimeWorldServiceAction.increaseQuantity,
        RuntimeWorldServiceAction.confirm,
      ]);
      expect(commands.last.snapshotRevision, 8);
      expect(commands.last.targetId, 'potion');
      expect(commands.last.quantity, 1);
      expect(
        find.byKey(const ValueKey('shop-quantity-review')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(PlayerShopOverlay),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quantity return is local while close emits the runtime close intent',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final initial = _snapshot();
      await _pump(tester, initial, commands.add);
      await tester.tap(find.byKey(const ValueKey('shop-item-potion')));
      await _pump(tester, initial.next(), commands.add);
      await tester.tap(find.byKey(const ValueKey('shop-quantity-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shop-quantity-review')), findsNothing);
      expect(find.byKey(const ValueKey('shop-item-potion')), findsOneWidget);
      expect(commands.map((command) => command.action), [
        RuntimeWorldServiceAction.select,
      ]);
      await tester.tap(find.byKey(const ValueKey('shop-close')));
      expect(commands.last.action, RuntimeWorldServiceAction.close);
      expect(commands.last.snapshotRevision, 8);
      expect(
        commands.any(
          (command) => command.action == RuntimeWorldServiceAction.cancel,
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stale snapshots cannot open quantity and missing items return to list',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final initial = _snapshot();
      await _pump(tester, initial, commands.add);
      await tester.tap(find.byKey(const ValueKey('shop-item-potion')));
      await _pump(tester, _snapshot(), commands.add);
      expect(find.byKey(const ValueKey('shop-quantity-review')), findsNothing);
      await _pump(tester, initial.next(), commands.add);
      expect(
        find.byKey(const ValueKey('shop-quantity-review')),
        findsOneWidget,
      );
      await _pump(tester, _snapshot(revision: 9, empty: true), commands.add);
      expect(find.byKey(const ValueKey('shop-quantity-review')), findsNothing);
      expect(find.text('Cette boutique est vide.'), findsOneWidget);
      final buy = tester.widget<PlayerActionButton>(
        find.byKey(const ValueKey('shop-buy')),
      );
      expect(buy.onPressed, isNull);
      expect(commands, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sell review uses runtime quantities and preserves versioned sale intents',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final initial = _snapshot(selling: true, quantity: 2);
      await _pump(tester, initial, commands.add, locale: const Locale('en'));
      expect(find.textContaining('Owned: 3'), findsWidgets);
      expect(find.textContaining('Cannot be sold'), findsOneWidget);
      expect(find.byKey(const ValueKey('shop-quantity-review')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('shop-item-potion')));
      await _pump(
        tester,
        initial.next(),
        commands.add,
        locale: const Locale('en'),
      );
      expect(find.text('Total: 60 ₽'), findsOneWidget);
      expect(find.text('Balance after : 560 ₽'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shop-sell')));
      expect(commands.last.action, RuntimeWorldServiceAction.confirm);
      expect(commands.last.targetId, 'potion');
      expect(commands.last.quantity, 2);
      expect(commands.last.snapshotRevision, 8);
      await tester.tap(find.byKey(const ValueKey('shop-quantity-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shop-mode-buy')));
      expect(commands.last.action, RuntimeWorldServiceAction.showPurchases);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disabled runtime transactions retain the reason and cannot confirm',
    (tester) async {
      final commands = <RuntimeWorldServiceCommand>[];
      final initial = _snapshot(confirmEnabled: false);
      await _pump(tester, initial, commands.add);
      await tester.tap(find.byKey(const ValueKey('shop-item-potion')));
      await _pump(tester, initial.next(), commands.add);
      expect(find.text('Argent insuffisant.'), findsWidgets);
      expect(
        tester
            .widget<PlayerActionButton>(find.byKey(const ValueKey('shop-buy')))
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const ValueKey('shop-buy')),
        warnIfMissed: false,
      );
      expect(commands.map((command) => command.action), [
        RuntimeWorldServiceAction.select,
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

RuntimeWorldServiceSnapshot _snapshot({
  int revision = 7,
  bool empty = false,
  bool fourEntries = false,
  bool selling = false,
  bool confirmEnabled = true,
  int quantity = 1,
}) => RuntimeWorldServiceSnapshot(
  revision: revision,
  request: const OpenShopService(interactionId: 'npc.merchant', shopId: 'mart'),
  stage: RuntimeWorldServiceStage.active,
  content: RuntimeShopServiceContent(
    title: 'Boutique du Port',
    message: 'Bienvenue !',
    money: 500,
    mode: selling ? RuntimeShopMode.sell : RuntimeShopMode.buy,
    entries: empty
        ? []
        : [
            RuntimeShopEntrySnapshot(
              itemId: 'potion',
              label: 'Potion',
              unitPrice: selling ? 30 : 60,
              remainingStock: 3,
              ownedQuantity: 3,
            ),
            if (fourEntries) ...[
              const RuntimeShopEntrySnapshot(
                itemId: 'super-potion',
                label: 'Super Potion',
                unitPrice: 700,
                remainingStock: 12,
                ownedQuantity: 0,
              ),
              const RuntimeShopEntrySnapshot(
                itemId: 'antidote',
                label: 'Antidote',
                unitPrice: 100,
                remainingStock: 12,
                ownedQuantity: 0,
              ),
              const RuntimeShopEntrySnapshot(
                itemId: 'revive',
                label: 'Rappel',
                unitPrice: 1500,
                remainingStock: 12,
                ownedQuantity: 0,
              ),
            ],
            if (selling)
              const RuntimeShopEntrySnapshot(
                itemId: 'bike-pass',
                label: 'Bike Pass',
                unitPrice: 0,
                ownedQuantity: 1,
                canTransact: false,
                unavailableReason: 'Key items cannot be sold.',
              ),
          ],
    selectedItemId: empty ? null : 'potion',
    quantity: quantity,
    totalPrice: empty ? 0 : (selling ? 30 : 60) * quantity,
  ),
  actions: [
    for (final action in [
      RuntimeWorldServiceAction.select,
      RuntimeWorldServiceAction.showPurchases,
      RuntimeWorldServiceAction.showSales,
      RuntimeWorldServiceAction.decreaseQuantity,
      RuntimeWorldServiceAction.increaseQuantity,
      RuntimeWorldServiceAction.close,
    ])
      RuntimeWorldServiceActionAvailability.enabled(action),
    if (empty || !confirmEnabled)
      RuntimeWorldServiceActionAvailability.disabled(
        RuntimeWorldServiceAction.confirm,
        reason: empty ? 'Cette boutique est vide.' : 'Argent insuffisant.',
      )
    else
      const RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.confirm,
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  RuntimeWorldServiceSnapshot snapshot,
  ValueChanged<RuntimeWorldServiceCommand> onCommand, {
  Locale locale = const Locale('fr'),
  EdgeInsets safePadding = EdgeInsets.zero,
  bool companion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(padding: safePadding, viewPadding: safePadding),
        child: child!,
      ),
      home: companion
          ? PlayerCompanionScope(
              child: PlayerShopOverlay(
                snapshot: snapshot,
                onCommand: onCommand,
              ),
            )
          : PlayerShopOverlay(snapshot: snapshot, onCommand: onCommand),
    ),
  );
  await tester.pumpAndSettle();
}
