import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('return from Carte refreshes saved item pickup references', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    final commerce = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!
        .commerce!;
    final before = commerce.snapshot!.references.referencesFor('potion').length;

    await host.go('Carte');
    final saved = await tester.runAsync(() async {
      host.document.commit(
        host.document.current.copyWith(
          entities: [
            ...host.document.current.entities,
            const MapEntity(
              id: 'pickup-potion',
              kind: MapEntityKind.item,
              pos: GridPos(x: 4, y: 4),
              item: MapEntityItemData(gameItemId: 'potion'),
            ),
          ],
        ),
      );
      return host.maps.save(host.document);
    });
    expect(saved, isTrue, reason: host.document.error);
    await pumpIo(tester);
    await host.go('Pokémon');
    await pumpIo(tester);

    expect(commerce.item?.id, 'potion');
    expect(
      commerce.snapshot!.references.referencesFor('potion').length,
      before + 1,
    );
    await host.go('Carte');
    final removed = await tester.runAsync(() async {
      host.document.commit(
        host.document.current.copyWith(
          entities: host.document.current.entities
              .where((entity) => entity.id != 'pickup-potion')
              .toList(),
        ),
      );
      return host.maps.save(host.document);
    });
    expect(removed, isTrue, reason: host.document.error);
    await pumpIo(tester);
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(
      commerce.snapshot!.references.referencesFor('potion').length,
      before,
    );
  });

  testWidgets('return from Histoire refreshes narrative item references', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    final commerce = _commerce(tester);
    final before = commerce.snapshot!.references.referencesFor('potion').length;
    await host.go('Histoire');
    await tester.runAsync(() async {
      await LocalSceneAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      ).publishScene(base: null, current: _giftScene());
    });
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(
      commerce.snapshot!.references.referencesFor('potion').length,
      before + 1,
    );
    expect(
      commerce.snapshot!.references.referencesFor('potion').last.kind,
      ProjectItemReferenceKind.sceneGive,
    );
  });

  testWidgets('refresh keeps a shop by identity and clears a removed shop', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Boutiques').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('shop-gare')));
    await pumpIo(tester);
    final commerce = _commerce(tester);
    await host.go('Carte');
    final manifestFile = File('${host.source.directory.path}/project.json');
    await tester.runAsync(() async {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
      );
      await manifestFile.writeAsString(
        jsonEncode(
          manifest
              .copyWith(
                shops: [
                  const ShopDefinition(
                    id: 'gare',
                    label: 'Gare actualisée',
                    entries: [
                      ShopEntryDefinition(itemId: 'introuvable', price: 5),
                    ],
                  ),
                ],
              )
              .toJson(),
        ),
      );
    });
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(commerce.shop?.id, 'gare');
    expect(commerce.shop?.label, 'Gare actualisée');
    expect(
      commerce.snapshot!.shopDiagnostics.any(
        (diagnostic) => diagnostic.code == 'SHOP_STATE_UNKNOWN_ITEM',
      ),
      isTrue,
    );
    await host.go('Carte');
    await tester.runAsync(() async {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
      );
      await manifestFile.writeAsString(
        jsonEncode(manifest.copyWith(shops: const []).toJson()),
      );
    });
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(commerce.shop, isNull);
  });

  testWidgets('refresh clears a removed item instead of retaining its draft', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester, prepareSource: _seed);
    await host.go('Pokémon');
    await tester.tap(find.text('Objets').first);
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('item-potion')));
    await pumpIo(tester);
    final commerce = _commerce(tester);
    await host.go('Carte');
    final catalogFile = File(
      '${host.source.directory.path}/data/pokemon/catalogs/items.json',
    );
    await tester.runAsync(() async {
      final catalog =
          jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
      (catalog['entries'] as List).removeWhere(
        (value) => value is Map && value['id'] == 'potion',
      );
      await catalogFile.writeAsString(jsonEncode(catalog));
    });
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(commerce.item, isNull);
  });
}

PokemonCommerceController _commerce(WidgetTester tester) => tester
    .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
    .controller!
    .commerce!;

SceneAsset _giftScene() => SceneAsset(
  id: 'scene-gift',
  name: 'Cadeau de gare',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'give',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(itemId: 'potion', quantity: 1),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-give',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'give',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'give-end',
        fromNodeId: 'give',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

Future<void> _seed(M3StoryFixture fixture) async {
  final target = File(
    '${fixture.directory.path}/data/pokemon/catalogs/items.json',
  );
  await target.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
  ).copy(target.path);
  final manifestFile = File('${fixture.directory.path}/project.json');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
  );
  await manifestFile.writeAsString(
    jsonEncode(
      manifest
          .copyWith(
            shops: [
              const ShopDefinition(id: 'gare', label: 'Boutique de la gare'),
            ],
          )
          .toJson(),
    ),
  );
}
