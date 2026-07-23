import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/application/shop_state_simulation_controller.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  test('agrees with ShopStateResolver for three isolated draft contexts', () {
    final project = _project();
    final shop = project.shops.single;
    const initial = GameState(saveId: 'shop-preview');
    final controller = ShopStateSimulationController(
      project: project,
      initialGameState: initial,
    );
    const resolver = ShopStateResolver();
    final context = ScriptEvaluationContext(
      narrativeFactResolver:
          NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    final projectBefore = project.toJson();
    final states = <GameState>[
      initial,
      initial.copyWith(
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const <String, bool>{'lysa': true},
        ),
      ),
      initial.copyWith(
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const <String, bool>{
            'lysa': true,
            'ending': true,
          },
        ),
      ),
    ];

    for (final gameState in states) {
      controller.replaceDraft(gameState);
      final preview = controller.simulate(shop);
      final runtime = resolver.resolve(
        shop: shop,
        gameState: gameState,
        conditionContext: context,
      );

      expect(preview.resolvedState.stateId, runtime.stateId);
      expect(preview.resolvedState.priority, runtime.priority);
      expect(
        preview.matchedStates.map((state) => state.id),
        runtime.matchedStateIds,
      );
    }

    expect(controller.draftGameState, states.last);
    expect(project.toJson(), projectBefore);
  });

  test('aggregates structural and active-context diagnostics', () {
    final project = _project(withTie: true);
    final controller = ShopStateSimulationController(
      project: project,
      initialGameState: const GameState(
        saveId: 'tie',
        narrativeFactRuntimeState: NarrativeFactRuntimeState.empty(),
      ).copyWith(
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const <String, bool>{
            'lysa': true,
            'ending': true,
          },
        ),
      ),
    );

    final diagnostics = controller.validate(
      project.shops.single,
      knownItemIds: const <String>{'potion'},
    );

    expect(
      diagnostics.map((diagnostic) => diagnostic.code),
      contains('SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH'),
    );
  });
}

ProjectManifest _project({bool withTie = false}) {
  final states = <ShopStateDefinition>[
    ShopStateDefinition(
      id: 'after-lysa',
      label: 'Après la victoire contre Lysa',
      priority: 10,
      activation: ScriptConditionFactory.factEquals(
        'lysa',
        const NarrativeValue.boolean(true),
      ),
      entries: const <ShopEntryDefinition>[
        ShopEntryDefinition(itemId: 'potion', price: 250),
      ],
    ),
    ShopStateDefinition(
      id: 'ending',
      label: 'Histoire terminée',
      priority: withTie ? 10 : 20,
      activation: ScriptConditionFactory.factEquals(
        'ending',
        const NarrativeValue.boolean(true),
      ),
      entries: const <ShopEntryDefinition>[
        ShopEntryDefinition(itemId: 'potion', price: 200),
      ],
    ),
  ];
  return ProjectManifest(
    name: 'Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: 'lysa', label: 'Lysa vaincue'),
      NarrativeFactDefinition(id: 'ending', label: 'Histoire terminée'),
    ],
    shops: <ShopDefinition>[
      ShopDefinition(
        id: 'port',
        label: 'Boutique du Port',
        entries: const <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: 'potion', price: 300),
        ],
        states: states,
      ),
    ],
  );
}
