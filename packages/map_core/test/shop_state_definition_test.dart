import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShopStateDefinition', () {
    test('normalizes and round-trips one complete conditional state', () {
      final state = ShopStateDefinition(
        id: ' after-lysa ',
        label: ' Après la victoire contre Lysa ',
        priority: 10,
        activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
        storefrontLabel: ' Comptoir victorieux ',
        welcomeMessage: ' Félicitations ! ',
        closedMessage: ' Fermé. ',
        entries: const <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: ' potion ', price: 250, stock: 20),
        ],
      ).normalized(knownItemIds: const <String>{'potion'});

      final restored = ShopStateDefinition.fromJson(state.toJson());

      expect(restored.id, 'after-lysa');
      expect(restored.label, 'Après la victoire contre Lysa');
      expect(restored.storefrontLabel, 'Comptoir victorieux');
      expect(restored.welcomeMessage, 'Félicitations !');
      expect(restored.closedMessage, 'Fermé.');
      expect(restored.entries.single.itemId, 'potion');
      expect(restored.entries.single.price, 250);
      expect(restored.entries.single.stock, 20);
      expect(restored, state);
    });

    test('normalizes an empty storefront label to null', () {
      final state = ShopStateDefinition(
        id: 'default-like',
        label: 'Default-like',
        activation: ScriptConditionFactory.flagIsSet('story.ready'),
        storefrontLabel: '   ',
      ).normalized();

      expect(state.storefrontLabel, isNull);
    });

    test('rejects empty identity, duplicate items and unknown items', () {
      expect(
        () => ShopStateDefinition(
          id: ' ',
          label: 'State',
          activation: ScriptConditionFactory.flagIsSet('story.ready'),
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => ShopStateDefinition(
          id: 'state',
          label: ' ',
          activation: ScriptConditionFactory.flagIsSet('story.ready'),
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => ShopStateDefinition(
          id: 'state',
          label: 'State',
          activation: ScriptConditionFactory.flagIsSet('story.ready'),
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 100),
            ShopEntryDefinition(itemId: ' potion ', price: 200),
          ],
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => ShopStateDefinition(
          id: 'state',
          label: 'State',
          activation: ScriptConditionFactory.flagIsSet('story.ready'),
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'missing', price: 100),
          ],
        ).normalized(knownItemIds: const <String>{'potion'}),
        throwsStateError,
      );
    });
  });
}
