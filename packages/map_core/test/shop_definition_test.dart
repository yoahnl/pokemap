import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShopDefinition', () {
    test('normalizes and round-trips stable stock entries', () {
      final shop = const ShopDefinition(
        id: ' selbrume-mart ',
        label: ' Boutique de Selbrume ',
        entries: <ShopEntryDefinition>[
          ShopEntryDefinition(
            itemId: ' potion ',
            price: 300,
            sellPrice: 150,
            stock: 5,
          ),
        ],
      ).normalized(knownItemIds: const <String>{'potion'});

      final restored = ShopDefinition.fromJson(shop.toJson());

      expect(restored.id, 'selbrume-mart');
      expect(restored.label, 'Boutique de Selbrume');
      expect(restored.entries.single.itemId, 'potion');
      expect(restored.entries.single.price, 300);
      expect(restored.entries.single.sellPrice, 150);
      expect(restored.entries.single.stock, 5);
    });

    test('legacy shops without states keep their default catalogue', () {
      final shop = ShopDefinition.fromJson(<String, dynamic>{
        'id': 'mart',
        'label': 'Boutique',
        'entries': <Object?>[
          <String, Object?>{'itemId': 'potion', 'price': 300},
        ],
      });

      expect(shop.states, isEmpty);
      expect(shop.entries.single.itemId, 'potion');
      expect(shop.entries.single.price, 300);
      expect(shop.entries.single.sellPrice, isNull);
    });

    test('normalizes states and rejects duplicate conditional state ids', () {
      final shop = ShopDefinition(
        id: 'mart',
        label: 'Boutique',
        states: <ShopStateDefinition>[
          _state(' after-story '),
        ],
      ).normalized();

      expect(shop.states.single.id, 'after-story');
      expect(
        () => ShopDefinition(
          id: 'mart',
          label: 'Boutique',
          states: <ShopStateDefinition>[
            _state('after-story'),
            _state(' after-story '),
          ],
        ).normalized(),
        throwsStateError,
      );
    });

    test('rejects unknown items, duplicates, invalid price and stock', () {
      expect(
        () => const ShopDefinition(
          id: 'mart',
          label: 'Mart',
          entries: <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'missing', price: 1),
          ],
        ).normalized(knownItemIds: const <String>{'potion'}),
        throwsStateError,
      );
      expect(
        () => const ShopDefinition(
          id: 'mart',
          label: 'Mart',
          entries: <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 300),
            ShopEntryDefinition(itemId: ' potion ', price: 400),
          ],
        ).normalized(),
        throwsStateError,
      );
      for (final entry in <ShopEntryDefinition>[
        const ShopEntryDefinition(itemId: 'potion', price: 0),
        const ShopEntryDefinition(itemId: 'potion', price: 1, sellPrice: 0),
        const ShopEntryDefinition(itemId: 'potion', price: 1, stock: -1),
      ]) {
        expect(entry.normalized, throwsStateError);
      }
    });

    test('manifest preserves shops and defaults legacy projects to empty', () {
      final manifest = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'Selbrume',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'shops': <Object?>[
          const ShopDefinition(id: 'mart', label: 'Mart').toJson(),
        ],
      });
      final legacy = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'Legacy',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.shops.single.id, 'mart');
      expect(ProjectManifest.fromJson(manifest.toJson()).shops, manifest.shops);
      expect(legacy.shops, isEmpty);
    });

    test('manifest rejects duplicate normalized shop and badge ids', () {
      for (final entry in <MapEntry<String, List<Object?>>>[
        MapEntry<String, List<Object?>>('shops', <Object?>[
          <String, Object?>{'id': 'mart', 'label': 'A'},
          <String, Object?>{'id': ' mart ', 'label': 'B'},
        ]),
        MapEntry<String, List<Object?>>('badges', <Object?>[
          <String, Object?>{'id': 'brume', 'label': 'A'},
          <String, Object?>{'id': ' brume ', 'label': 'B'},
        ]),
      ]) {
        expect(
          () => ProjectManifest.fromJson(<String, dynamic>{
            'name': 'Selbrume',
            'maps': <Object?>[],
            'tilesets': <Object?>[],
            entry.key: entry.value,
          }),
          throwsFormatException,
        );
      }
    });
  });
}

ShopStateDefinition _state(String id) => ShopStateDefinition(
      id: id,
      label: 'After story',
      activation: ScriptConditionFactory.flagIsSet('story.finished'),
    );
