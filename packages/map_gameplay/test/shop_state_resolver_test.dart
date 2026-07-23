import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const resolver = ShopStateResolver();

  GameState state({Set<String> flags = const <String>{}}) => GameState(
        saveId: 'shop-state-resolver',
        storyFlags: StoryFlags(activeFlags: flags),
      );

  ShopDefinition shop({
    List<ShopStateDefinition> states = const <ShopStateDefinition>[],
  }) =>
      ShopDefinition(
        id: 'shop_port_supplies',
        label: 'Comptoir des Brisants',
        entries: const <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: 'potion', price: 300),
        ],
        states: states,
      );

  group('ShopStateResolver', () {
    test('uses the legacy default catalogue when no state matches', () {
      final result = resolver.resolve(
        shop: shop(
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'after-lysa',
              label: 'Après Lysa',
              priority: 10,
              activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 250),
              ],
            ),
          ],
        ),
        gameState: state(),
      );

      expect(result.isDefault, isTrue);
      expect(result.stateId, ShopStateResolver.defaultStateId);
      expect(result.authoringLabel, 'État par défaut');
      expect(result.storefrontLabel, 'Comptoir des Brisants');
      expect(result.entries.single.price, 300);
      expect(result.matchedStateIds, isEmpty);
    });

    test('selects the highest-priority matching state', () {
      final result = resolver.resolve(
        shop: shop(
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'after-lysa',
              label: 'Après Lysa',
              priority: 10,
              activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 250),
              ],
            ),
            ShopStateDefinition(
              id: 'story-finished',
              label: 'Histoire terminée',
              priority: 30,
              activation: ScriptConditionFactory.flagIsSet('story_finished'),
              storefrontLabel: 'Grand Comptoir des Brisants',
              welcomeMessage: 'Les arrivages du large sont disponibles.',
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 200),
              ],
            ),
          ],
        ),
        gameState: state(
          flags: const <String>{'lysa_defeated', 'story_finished'},
        ),
      );

      expect(result.stateId, 'story-finished');
      expect(result.priority, 30);
      expect(result.isDefault, isFalse);
      expect(result.storefrontLabel, 'Grand Comptoir des Brisants');
      expect(result.message, 'Les arrivages du large sont disponibles.');
      expect(result.entries.single.price, 200);
      expect(result.matchedStateIds, <String>[
        'story-finished',
        'after-lysa',
      ]);
    });

    test('keeps declaration order for an equal-priority runtime tie', () {
      final result = resolver.resolve(
        shop: shop(
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'first-declared',
              label: 'Premier état',
              priority: 20,
              activation: ScriptConditionFactory.flagIsSet('shared_flag'),
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 220),
              ],
            ),
            ShopStateDefinition(
              id: 'second-declared',
              label: 'Second état',
              priority: 20,
              activation: ScriptConditionFactory.flagIsSet('shared_flag'),
              entries: const <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 210),
              ],
            ),
          ],
        ),
        gameState: state(flags: const <String>{'shared_flag'}),
      );

      expect(result.stateId, 'first-declared');
      expect(result.entries.single.price, 220);
      expect(result.matchedStateIds, <String>[
        'first-declared',
        'second-declared',
      ]);
    });

    test('returns the authored closed message', () {
      final result = resolver.resolve(
        shop: shop(
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'lighthouse-alert',
              label: 'Alerte au phare',
              priority: 40,
              activation: ScriptConditionFactory.flagIsSet('lighthouse_danger'),
              isOpen: false,
              closedMessage: 'Le comptoir est fermé pendant l’alerte.',
            ),
          ],
        ),
        gameState: state(flags: const <String>{'lighthouse_danger'}),
      );

      expect(result.stateId, 'lighthouse-alert');
      expect(result.isOpen, isFalse);
      expect(result.message, 'Le comptoir est fermé pendant l’alerte.');
      expect(result.entries, isEmpty);
    });
  });
}
