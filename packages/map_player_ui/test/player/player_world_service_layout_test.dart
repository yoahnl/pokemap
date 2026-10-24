import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final formats = [
    ('portrait-touch', const Size(390, 844), PlayerInputSource.touch),
    ('portrait-controller', const Size(390, 844), PlayerInputSource.controller),
    ('landscape-touch', const Size(844, 390), PlayerInputSource.touch),
    (
      'landscape-controller',
      const Size(844, 390),
      PlayerInputSource.controller,
    ),
    ('companion-viewport', const Size(640, 480), PlayerInputSource.controller),
  ];
  for (final (name, size, input) in formats) {
    for (final kind in ['shop', 'heal', 'trade']) {
      testWidgets('$kind keeps actions anchored without scrolling at $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final commands = <RuntimeWorldServiceCommand>[];
        final snapshot = _snapshot(kind);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: PokeMapPlayerTheme.dark(),
            home: PlayerInputScope(
              activeInputSource: input,
              child: switch (kind) {
                'shop' => PlayerShopOverlay(
                  snapshot: snapshot,
                  onCommand: commands.add,
                ),
                'heal' => PlayerHealConfirmation(
                  snapshot: snapshot,
                  onCommand: commands.add,
                ),
                _ => PlayerPartyTradeOverlay(
                  snapshot: snapshot,
                  onCommand: commands.add,
                  hardwareGamepadEnabled: false,
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$kind $name');
        expect(find.byType(Scrollable), findsNothing);
        final action = find.byKey(
          ValueKey(switch (kind) {
            'shop' => 'shop-buy',
            'heal' => 'heal-confirm',
            _ => 'party-trade-cancel',
          }),
        );
        expect(action, findsOneWidget);
        expect(tester.getRect(action).overlaps(Offset.zero & size), isTrue);
        final content = tester.getRect(find.byType(PlayerPagedList).last);
        expect(
          tester.getRect(action).top - content.bottom,
          greaterThanOrEqualTo(12),
          reason: '$kind content/action spacing',
        );
        expect(commands, isEmpty);
        await tester.tap(action);
        expect(commands.single.snapshotRevision, 11);
        expect(
          commands.single.action,
          kind == 'trade'
              ? RuntimeWorldServiceAction.cancel
              : RuntimeWorldServiceAction.confirm,
        );
      });
    }
  }
}

RuntimeWorldServiceSnapshot _snapshot(String kind) =>
    RuntimeWorldServiceSnapshot(
      revision: 11,
      request: switch (kind) {
        'shop' => const OpenShopService(interactionId: 'shop', shopId: 'shop'),
        'heal' => const OpenHealService(interactionId: 'heal'),
        _ => const OpenPartyTradeService(interactionId: 'trade'),
      },
      stage: RuntimeWorldServiceStage.active,
      content: switch (kind) {
        'shop' => RuntimeShopServiceContent(
          title: 'Boutique',
          message: '',
          money: 500,
          entries: [
            for (var i = 0; i < 16; i++)
              RuntimeShopEntrySnapshot(
                itemId: 'item-$i',
                label: 'Objet $i',
                unitPrice: 60,
                remainingStock: 5,
              ),
          ],
          selectedItemId: 'item-0',
          quantity: 2,
          totalPrice: 120,
        ),
        'heal' => RuntimeHealServiceContent(
          title: 'Centre de soins',
          message: 'Soigner l’équipe ?',
          members: [
            for (var i = 0; i < 6; i++)
              RuntimeHealPartyMemberSnapshot(
                partyIndex: i,
                label: 'Compagnon $i',
                currentHp: 3,
                maxHp: 24,
                hasStatus: true,
                depletedMoveCount: 1,
              ),
          ],
        ),
        _ => RuntimePartyTradeServiceContent(
          phase: RuntimePartyTradePhase.selectFirst,
          members: [
            for (var i = 0; i < 6; i++)
              RuntimePartyTradePokemonSnapshot(
                individualId: 'member-$i',
                speciesId: 'species-$i',
                label: 'Compagnon $i',
                level: 12,
              ),
          ],
        ),
      },
      actions: const [
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.increaseQuantity,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.decreaseQuantity,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.showPurchases,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.showSales,
        ),
      ],
    );
