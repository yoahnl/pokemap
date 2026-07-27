import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/application/shop_editor_controller.dart';
import 'package:map_editor/src/features/gameplay/presentation/shop_editor_panel.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('authors a shop with guided catalogue controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ShopEditorController(
      manifest: const ProjectManifest(
        name: 'Test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
      itemOptions: const <ShopEditorItemOption>[
        ShopEditorItemOption(id: 'potion', label: 'Potion'),
        ShopEditorItemOption(id: 'antidote', label: 'Antidote'),
      ],
    );
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: ShopEditorPanel(
            controller: controller,
            onManifestChanged: (_) => changed += 1,
          ),
        ),
      ),
    );

    expect(find.text('Aucune boutique'), findsOneWidget);
    expect(find.textContaining('Identifiant technique'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('shop-create-label-field')),
      'Boutique du Port',
    );
    await tester.tap(find.byKey(const Key('shop-create-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('shop-item-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potion').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shop-price-field')),
      '300',
    );
    await tester.enterText(
      find.byKey(const Key('shop-sell-price-field')),
      '150',
    );
    await tester.enterText(
      find.byKey(const Key('shop-stock-field')),
      '4',
    );
    await tester.tap(find.byKey(const Key('shop-add-entry-button')));
    await tester.pump();

    expect(controller.shops.single.id, 'boutique-du-port');
    expect(controller.shops.single.entries.single.itemId, 'potion');
    expect(controller.shops.single.entries.single.sellPrice, 150);
    expect(find.textContaining('300'), findsWidgets);
    expect(find.textContaining('Revente : 150'), findsOneWidget);
    expect(find.textContaining('Stock : 4'), findsOneWidget);
    expect(changed, 2);
  });

  testWidgets('edits one conditional state without mutating the default',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ShopEditorController(
      manifest: _manifestWithConditionalShop(),
      itemOptions: const <ShopEditorItemOption>[
        ShopEditorItemOption(id: 'potion', label: 'Potion'),
      ],
    );
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ShopEditorPanel(
            controller: controller,
            onManifestChanged: (_) => changed += 1,
          ),
        ),
      ),
    );

    for (final key in <String>[
      'shop-project-list',
      'shop-state-list',
      'shop-state-catalog-editor',
      'shop-state-inspector',
      'shop-state-preview-strip',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    await tester.tap(
      find.byKey(const Key('shop-state-after-lysa')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shop-state-entry-edit-potion')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('shop-price-field')),
      '450',
    );
    await tester.tap(find.byKey(const Key('shop-add-entry-button')));
    await tester.pump();

    expect(changed, 1);
    expect(controller.shopById('port').entries.single.price, 300);
    expect(
      controller.stateById('port', 'after-lysa').entries.single.price,
      450,
    );

    await tester.tap(
      find.byKey(const Key('shop-preview-edit-context')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('shop-state-simulation-context-editor')),
      findsOneWidget,
    );
    expect(find.text('Snapshot local'), findsOneWidget);
  });

  testWidgets('renders repeated diagnostics while switching shop states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ShopEditorController(
      manifest: _manifestWithConditionalShop().copyWith(
        shops: <ShopDefinition>[
          _manifestWithConditionalShop().shops.single.copyWith(
            entries: const <ShopEntryDefinition>[
              ShopEntryDefinition(itemId: 'potion', price: 300),
              ShopEntryDefinition(itemId: 'antidote', price: 100),
            ],
            states: <ShopStateDefinition>[
              _manifestWithConditionalShop()
                  .shops
                  .single
                  .states
                  .single
                  .copyWith(
                entries: const <ShopEntryDefinition>[
                  ShopEntryDefinition(itemId: 'potion', price: 250),
                  ShopEntryDefinition(itemId: 'antidote', price: 100),
                ],
              ),
            ],
          ),
        ],
      ),
      itemOptions: const <ShopEditorItemOption>[],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ShopEditorPanel(
            controller: controller,
            onManifestChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('shop-state-after-lysa')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      controller.shopById('port').states.single.id,
      'after-lysa',
    );
  });

  testWidgets('adapts its inspector and lists at supported widths',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ShopEditorController(
      manifest: _manifestWithConditionalShop(),
      itemOptions: const <ShopEditorItemOption>[
        ShopEditorItemOption(id: 'potion', label: 'Potion'),
      ],
    );

    Future<void> pumpAt(double width) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: ShopEditorPanel(
              controller: controller,
              onManifestChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }

    await pumpAt(1440);
    expect(find.byKey(const Key('shop-state-inspector')), findsOneWidget);
    expect(find.byKey(const Key('shop-project-list')), findsOneWidget);

    await pumpAt(1200);
    expect(find.byKey(const Key('shop-state-inspector')), findsNothing);
    expect(
      find.byKey(const Key('shop-inspector-side-sheet-button')),
      findsOneWidget,
    );

    await pumpAt(980);
    expect(find.byKey(const Key('shop-project-list')), findsNothing);
    expect(
      find.byKey(const Key('shop-lists-compact-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shop-state-catalog-editor')), findsOneWidget);
  });

  testWidgets(
      'a diagnostic selects its state and focuses the inspector section',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ShopEditorController(
      manifest: _manifestWithConditionalShop(),
      itemOptions: const <ShopEditorItemOption>[
        ShopEditorItemOption(id: 'potion', label: 'Potion'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ShopEditorPanel(
            controller: controller,
            onManifestChanged: (_) {},
          ),
        ),
      ),
    );

    final diagnostic = find.byKey(
      const Key(
        'shop-diagnostic-SHOP_STATE_UNKNOWN_CONDITION_REFERENCE-after-lysa-'
        'shops.port.states.after-lysa.activation.stepId',
      ),
    );
    await tester.scrollUntilVisible(
      diagnostic,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('shop-state-inspector')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.descendant(of: diagnostic, matching: find.text('Examiner')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shop-state-condition-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('shop-state-label-field')),
      findsOneWidget,
    );
  });
}

ProjectManifest _manifestWithConditionalShop() => const ProjectManifest(
      name: 'Test',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      shops: <ShopDefinition>[
        ShopDefinition(
          id: 'port',
          label: 'Boutique du Port',
          entries: <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 300),
          ],
          states: <ShopStateDefinition>[
            ShopStateDefinition(
              id: 'after-lysa',
              label: 'Après la victoire contre Lysa',
              priority: 10,
              activation: ScriptCondition(
                type: ScriptConditionType.stepCompleted,
                params: <String, String>{
                  ScriptConditionParams.stepId: 'lysa',
                },
              ),
              entries: <ShopEntryDefinition>[
                ShopEntryDefinition(itemId: 'potion', price: 350),
              ],
            ),
          ],
        ),
      ],
    );
