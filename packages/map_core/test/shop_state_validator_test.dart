import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShopStateValidator', () {
    test('reports structural and project-reference diagnostics with context',
        () {
      final sharedCondition =
          ScriptConditionFactory.flagIsSet('shared-shop-condition');
      final project = _project(
        shops: <ShopDefinition>[
          ShopDefinition(
            id: 'port',
            label: 'Boutique du Port',
            states: <ShopStateDefinition>[
              _state(id: 'duplicate', activation: sharedCondition),
              _state(id: 'duplicate', activation: sharedCondition),
              _state(
                id: 'unknown-item',
                entries: const <ShopEntryDefinition>[
                  ShopEntryDefinition(itemId: 'missing', price: 100),
                ],
              ),
              _state(
                id: 'invalid-price',
                entries: const <ShopEntryDefinition>[
                  ShopEntryDefinition(itemId: 'potion', price: 0),
                ],
              ),
              _state(
                id: 'invalid-stock',
                entries: const <ShopEntryDefinition>[
                  ShopEntryDefinition(
                    itemId: 'potion',
                    price: 100,
                    stock: -1,
                  ),
                ],
              ),
              _state(
                id: 'unknown-references',
                activation: ScriptConditionFactory.allOf(
                  <ScriptCondition>[
                    ScriptConditionFactory.factEquals(
                      'missing-fact',
                      NarrativeValue.boolean(true),
                    ),
                    ScriptConditionFactory.stepCompleted('missing-step'),
                    ScriptConditionFactory.badgeOwned('missing-badge'),
                    ScriptConditionFactory.itemQuantityAtLeast(
                      'missing-condition-item',
                      1,
                    ),
                  ],
                ),
              ),
              _state(
                id: 'same-expression-a',
                priority: 20,
                activation: sharedCondition,
              ),
              _state(
                id: 'same-expression-b',
                priority: 20,
                activation: sharedCondition,
              ),
              _state(
                id: 'closed-without-message',
                isOpen: false,
              ),
              _state(
                id: 'open-empty',
                entries: const <ShopEntryDefinition>[],
              ),
            ],
          ),
        ],
      );

      final diagnostics = ShopStateValidator(
        project: project,
        knownItemIds: const <String>{'potion'},
      ).validate();
      final codes = diagnostics.map((diagnostic) => diagnostic.code).toSet();

      expect(
        codes,
        containsAll(<String>{
          'SHOP_STATE_DUPLICATE_ID',
          'SHOP_STATE_UNKNOWN_ITEM',
          'SHOP_STATE_INVALID_PRICE',
          'SHOP_STATE_INVALID_STOCK',
          'SHOP_STATE_UNKNOWN_CONDITION_REFERENCE',
          'SHOP_STATE_EQUAL_PRIORITY_IDENTICAL_CONDITION',
          'SHOP_STATE_CLOSED_WITHOUT_MESSAGE',
          'SHOP_STATE_OPEN_EMPTY_CATALOGUE',
        }),
      );
      for (final diagnostic in diagnostics) {
        expect(diagnostic.shopId, 'port');
        expect(diagnostic.path, isNotEmpty);
        expect(diagnostic.severity, isA<ShopStateDiagnosticSeverity>());
      }
      expect(
        diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code == 'SHOP_STATE_UNKNOWN_CONDITION_REFERENCE',
            )
            .map((diagnostic) => diagnostic.path),
        containsAll(<String>[
          'shops.port.states.unknown-references.activation.children.0.factId',
          'shops.port.states.unknown-references.activation.children.1.stepId',
          'shops.port.states.unknown-references.activation.children.2.badgeId',
          'shops.port.states.unknown-references.activation.children.3.itemId',
        ]),
      );
    });

    test('accepts known project references and a valid catalogue', () {
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'lysa-defeated',
            label: 'Lysa vaincue',
          ),
        ],
        badges: const <BadgeDefinition>[
          BadgeDefinition(id: 'brume', label: 'Badge Brume'),
        ],
        storylines: <StorylineAsset>[
          StorylineAsset(
            id: 'main',
            type: StorylineType.main,
            title: 'Histoire principale',
            chapters: <StorylineChapter>[
              StorylineChapter(
                id: 'port',
                title: 'Le port',
                order: 0,
                steps: <StorylineStep>[
                  StorylineStep(
                    id: 'beat-lysa',
                    title: 'Battre Lysa',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        shops: <ShopDefinition>[
          ShopDefinition(
            id: 'port',
            label: 'Boutique du Port',
            entries: const <ShopEntryDefinition>[
              ShopEntryDefinition(itemId: 'potion', price: 300),
            ],
            states: <ShopStateDefinition>[
              _state(
                id: 'after-lysa',
                activation: ScriptConditionFactory.allOf(
                  <ScriptCondition>[
                    ScriptConditionFactory.factEquals(
                      'lysa-defeated',
                      NarrativeValue.boolean(true),
                    ),
                    ScriptConditionFactory.stepCompleted('beat-lysa'),
                    ScriptConditionFactory.badgeOwned('brume'),
                    ScriptConditionFactory.itemQuantityAtLeast('potion', 1),
                  ],
                ),
                entries: const <ShopEntryDefinition>[
                  ShopEntryDefinition(itemId: 'potion', price: 250),
                ],
              ),
            ],
          ),
        ],
      );

      final diagnostics = ShopStateValidator(
        project: project,
        knownItemIds: const <String>{'potion'},
      ).validate();

      expect(
        diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'SHOP_STATE_UNKNOWN_CONDITION_REFERENCE',
        ),
        isEmpty,
      );
      expect(
        diagnostics.where(
          (diagnostic) =>
              diagnostic.severity == ShopStateDiagnosticSeverity.error,
        ),
        isEmpty,
      );
    });
  });
}

ProjectManifest _project({
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
  List<BadgeDefinition> badges = const <BadgeDefinition>[],
  List<ShopDefinition> shops = const <ShopDefinition>[],
}) =>
    ProjectManifest(
      name: 'Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      facts: facts,
      storylines: storylines,
      badges: badges,
      shops: shops,
    );

ShopStateDefinition _state({
  required String id,
  int priority = 0,
  ScriptCondition? activation,
  bool isOpen = true,
  List<ShopEntryDefinition> entries = const <ShopEntryDefinition>[
    ShopEntryDefinition(itemId: 'potion', price: 300),
  ],
}) =>
    ShopStateDefinition(
      id: id,
      label: id,
      priority: priority,
      activation:
          activation ?? ScriptConditionFactory.flagIsSet('condition-$id'),
      isOpen: isOpen,
      entries: entries,
    );
