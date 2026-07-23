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
      find.byKey(const Key('shop-stock-field')),
      '4',
    );
    await tester.tap(find.byKey(const Key('shop-add-entry-button')));
    await tester.pump();

    expect(controller.shops.single.id, 'boutique-du-port');
    expect(controller.shops.single.entries.single.itemId, 'potion');
    expect(find.textContaining('300'), findsWidgets);
    expect(find.textContaining('Stock : 4'), findsOneWidget);
    expect(changed, 2);
  });
}
