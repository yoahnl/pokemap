import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_commerce_owner_fixture.dart';

void main() {
  Future<(PokemonAuthoringFixture, PokemonDestinationRoute)> open(
    PokemonWorkspaceView view,
  ) async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: seedPokemonGoldenItemsAndShop,
    );
    addTearDown(host.dispose);
    final route = PokemonDestinationRoute(host);
    addTearDown(route.dispose);
    await route.go(WorkspaceSpace.pokemon);
    expect(await host.view(view), isTrue);
    return (host, route);
  }

  test('return from Carte refreshes saved item pickup references', () async {
    final (host, route) = await open(PokemonWorkspaceView.items);
    final commerce = host.commerce;
    expect(commerce.selectItem(_potion(commerce)), isTrue);
    final before = await _analyzedPotionReferences(commerce);
    await route.go(WorkspaceSpace.map);
    final document = host.maps.active!;
    document.commit(
      document.current.copyWith(
        entities: [
          ...document.current.entities,
          const MapEntity(
            id: 'pickup-potion',
            kind: MapEntityKind.item,
            pos: GridPos(x: 4, y: 4),
            item: MapEntityItemData(gameItemId: 'potion'),
          ),
        ],
      ),
    );
    expect(await host.maps.save(document), isTrue, reason: document.error);
    await route.go(WorkspaceSpace.pokemon);
    expect(commerce.item?.id, 'potion');
    expect(commerce.snapshot!.referencesComplete, isFalse);
    expect(await _analyzedPotionReferences(commerce), before + 1);
    await route.go(WorkspaceSpace.map);
    document.commit(
      document.current.copyWith(
        entities: document.current.entities
            .where((entity) => entity.id != 'pickup-potion')
            .toList(),
      ),
    );
    expect(await host.maps.save(document), isTrue, reason: document.error);
    await route.go(WorkspaceSpace.pokemon);
    expect(await _analyzedPotionReferences(commerce), before);
  });

  test('return from Histoire refreshes narrative item references', () async {
    final (host, route) = await open(PokemonWorkspaceView.items);
    final commerce = host.commerce;
    expect(commerce.selectItem(_potion(commerce)), isTrue);
    final before = await _analyzedPotionReferences(commerce);
    await route.go(WorkspaceSpace.map);
    await LocalSceneAdapter(
      session: host.source.session,
      mapAdapter: host.source.maps,
    ).publishScene(base: null, current: _giftScene());
    await route.go(WorkspaceSpace.pokemon);
    expect(commerce.snapshot!.referencesComplete, isFalse);
    expect(await _analyzedPotionReferences(commerce), before + 1);
    expect(
      commerce.snapshot!.references.referencesFor('potion').last.kind,
      ProjectItemReferenceKind.sceneGive,
    );
  });

  test('staying in Pokémon does not refresh the commerce snapshot', () async {
    final (host, route) = await open(PokemonWorkspaceView.items);
    final commerce = host.commerce;
    await commerce.analyzeReferences();
    expect(commerce.snapshot!.referencesComplete, isTrue);
    await route.go(WorkspaceSpace.pokemon);
    expect(commerce.snapshot!.referencesComplete, isTrue);
  });

  test('refresh keeps a shop by identity and clears a removed shop', () async {
    final (host, route) = await open(PokemonWorkspaceView.shops);
    final commerce = host.commerce;
    expect(
      commerce.selectShop(
        commerce.snapshot!.shops.singleWhere((shop) => shop.id == 'gare'),
      ),
      isTrue,
    );
    await route.go(WorkspaceSpace.map);
    await rewritePokemonManifest(
      host.source.directory,
      (manifest) => manifest.copyWith(
        shops: [
          const ShopDefinition(
            id: 'gare',
            label: 'Gare actualisée',
            entries: [ShopEntryDefinition(itemId: 'introuvable', price: 5)],
          ),
        ],
      ),
    );
    await route.go(WorkspaceSpace.pokemon);
    expect(commerce.shop?.id, 'gare');
    expect(commerce.shop?.label, 'Gare actualisée');
    expect(
      commerce.snapshot!.shopDiagnostics.any(
        (diagnostic) => diagnostic.code == 'SHOP_STATE_UNKNOWN_ITEM',
      ),
      isTrue,
    );
    await route.go(WorkspaceSpace.map);
    await rewritePokemonManifest(
      host.source.directory,
      (manifest) => manifest.copyWith(shops: const []),
    );
    await route.go(WorkspaceSpace.pokemon);
    expect(commerce.shop, isNull);
  });

  test(
    'refresh clears a removed item instead of retaining its draft',
    () async {
      final (host, route) = await open(PokemonWorkspaceView.items);
      final commerce = host.commerce;
      expect(commerce.selectItem(_potion(commerce)), isTrue);
      await route.go(WorkspaceSpace.map);
      final catalogFile = File(
        '${host.source.directory.path}/data/pokemon/catalogs/items.json',
      );
      final catalog =
          jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
      (catalog['entries'] as List).removeWhere(
        (value) => value is Map && value['id'] == 'potion',
      );
      await catalogFile.writeAsString(jsonEncode(catalog));
      await route.go(WorkspaceSpace.pokemon);
      expect(commerce.item, isNull);
    },
  );
}

ProjectItemDefinition _potion(PokemonCommerceController commerce) => commerce
    .snapshot!
    .catalog!
    .entries
    .singleWhere((item) => item.id == 'potion');

Future<int> _analyzedPotionReferences(
  PokemonCommerceController commerce,
) async {
  await commerce.analyzeReferences();
  expect(commerce.snapshot!.referencesComplete, isTrue);
  return commerce.snapshot!.references.referencesFor('potion').length;
}

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
