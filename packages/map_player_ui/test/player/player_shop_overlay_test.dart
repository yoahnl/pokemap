import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('shop renders runtime prices and emits versioned commands',
      (tester) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 7,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeShopServiceContent(
        title: 'Boutique du Port',
        message: 'Bienvenue !',
        money: 500,
        entries: const <RuntimeShopEntrySnapshot>[
          RuntimeShopEntrySnapshot(
            itemId: 'potion',
            label: 'Potion',
            unitPrice: 60,
            remainingStock: 3,
          ),
        ],
        selectedItemId: 'potion',
        quantity: 1,
        totalPrice: 60,
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.increaseQuantity,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        PlayerShopOverlay(
          snapshot: snapshot,
          onCommand: commands.add,
        ),
      ),
    );

    expect(find.text('Boutique du Port'), findsOneWidget);
    expect(find.text('500 ₽'), findsOneWidget);
    expect(find.text('60 ₽'), findsWidgets);
    expect(find.text('Stock : 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('shop-quantity-plus')));
    await tester.tap(find.byKey(const ValueKey<String>('shop-buy')));
    await tester.tap(find.byKey(const ValueKey<String>('shop-close')));

    expect(
      commands.map((command) => command.action),
      <RuntimeWorldServiceAction>[
        RuntimeWorldServiceAction.increaseQuantity,
        RuntimeWorldServiceAction.confirm,
        RuntimeWorldServiceAction.close,
      ],
    );
    expect(commands.every((command) => command.snapshotRevision == 7), isTrue);
    expect(commands[1].targetId, 'potion');
    expect(commands[1].quantity, 1);
  });

  testWidgets('empty and unavailable shop states stay player-safe',
      (tester) async {
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 2,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'empty',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeShopServiceContent(
        title: 'Échoppe',
        message: 'Revenez plus tard.',
        money: 10,
        entries: <RuntimeShopEntrySnapshot>[],
      ),
      actions: <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.disabled(
          RuntimeWorldServiceAction.confirm,
          reason: 'Cette boutique est vide.',
        ),
        const RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        PlayerShopOverlay(
          snapshot: snapshot,
          onCommand: (_) {},
        ),
      ),
    );

    expect(find.text('Cette boutique est vide.'), findsOneWidget);
    expect(find.text('Revenez plus tard.'), findsOneWidget);
    final buy = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Acheter'),
    );
    expect(buy.onPressed, isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
