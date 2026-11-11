import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';

const _sceneId = 'retired-scene-reference';

void main() {
  testWidgets(
    'a real scene reference refuses before the dirty Pokemon exit guard while map references retain that guard',
    (tester) async {
      final host = await MapHostFixture.open(tester, prepareSource: _seed);
      await host.go('Pokémon');
      await tester.tap(find.text('Objets').first);
      await pumpIo(tester);
      await tester.tap(find.byKey(const ValueKey('item-potion')));
      await pumpIo(tester);
      final workspace = tester
          .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
          .controller!;
      final commerce = workspace.commerce!;
      await tester.tap(find.text('Usages et références').last);
      await pumpIo(tester);
      await tester.tap(find.text('Analyser les usages du projet'));
      await pumpIo(tester);
      expect(commerce.snapshot!.referencesComplete, isTrue);
      final references = commerce.snapshot!.references.referencesFor('potion');
      expect(
        references.any(
          (reference) =>
              reference.sourceKind == 'scene' && reference.sourceId == _sceneId,
        ),
        isTrue,
      );
      final mapReference = references.singleWhere(
        (reference) => reference.kind == ProjectItemReferenceKind.mapPickup,
      );
      await tester.tap(find.text('Vue d’ensemble').last);
      await pumpIo(tester);
      await tester.enterText(
        find.byKey(const ValueKey('item-name-potion')),
        'Potion à conserver',
      );
      await pumpIo(tester);
      expect(commerce.dirty, isTrue);
      expect(workspace.hasPendingChanges, isTrue);
      await tester.tap(find.text('Usages et références').last);
      await pumpIo(tester);
      final draft = commerce.item!;
      final snapshot = commerce.snapshot;
      final formVersion = commerce.formVersion;
      final document = host.document;
      final diskBefore = await host.disk();
      final sceneReference = find.widgetWithText(ListTile, 'Scène · $_sceneId');
      final openScene = find.descendant(
        of: sceneReference,
        matching: find.widgetWithText(StudioButton, 'Ouvrir'),
      );
      await tester.ensureVisible(openScene);
      await tester.tap(openScene);
      await pumpIo(tester);
      expect(
        find.text('L’éditeur de scènes est indisponible.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Conserver le brouillon Pokémon ?'), findsNothing);
      expect(find.byType(PokemonWorkspacePage), findsOneWidget);
      expect(
        tester
            .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
            .controller,
        same(workspace),
      );
      expect(workspace.view, PokemonWorkspaceView.items);
      expect(commerce.section, PokemonCommerceSection.references);
      expect(commerce.item, same(draft));
      expect(commerce.item!.displayName, 'Potion à conserver');
      expect(commerce.snapshot, same(snapshot));
      expect(commerce.formVersion, formVersion);
      expect(commerce.dirty, isTrue);
      expect(commerce.saving, isFalse);
      expect(commerce.error, isNull);
      expect(host.document, same(document));
      expect(await host.disk(), diskBefore);

      final pickupReference = find.widgetWithText(
        ListTile,
        'Objet de carte · ${mapReference.sourceId}',
      );
      final openMap = find.descendant(
        of: pickupReference,
        matching: find.widgetWithText(StudioButton, 'Ouvrir'),
      );
      await tester.ensureVisible(openMap);
      await tester.tap(openMap);
      await pumpIo(tester);
      expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
      await tester.tap(find.text('Rester'));
      await pumpIo(tester);
      expect(find.byType(PokemonWorkspacePage), findsOneWidget);
      expect(commerce.item, same(draft));
      expect(commerce.dirty, isTrue);
      expect(await host.disk(), diskBefore);

      await tester.tap(openMap);
      await pumpIo(tester);
      expect(find.text('Conserver le brouillon Pokémon ?'), findsOneWidget);
      final discardChanges = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Annuler les modifications'),
      );
      expect(discardChanges, findsOneWidget);
      await tester.tap(discardChanges);
      await pumpIo(tester);
      expect(find.byType(PokemonWorkspacePage), findsNothing);
      expect(find.byType(MapEditingViewport2D), findsOneWidget);
      expect(host.document.current.id, mapReference.sourceId);
      expect(commerce.dirty, isFalse);
      expect(await host.disk(), diskBefore);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _seed(M3StoryFixture fixture) async {
  final target = File(
    '${fixture.directory.path}/data/pokemon/catalogs/items.json',
  );
  await target.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
  ).copy(target.path);
  final projectFile = File('${fixture.directory.path}/project.json');
  final project = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  final scene = SceneAsset(
    id: _sceneId,
    name: 'Cadeau de scène',
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
          id: 'begin',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'give',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'finish',
          fromNodeId: 'give',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
  await projectFile.writeAsString(
    jsonEncode(project.copyWith(scenes: [...project.scenes, scene]).toJson()),
  );
  final mapFile = File(
    '${fixture.directory.path}/${project.maps.first.relativePath}',
  );
  final map = MapData.fromJson(
    jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
  );
  await mapFile.writeAsString(
    jsonEncode(
      map
          .copyWith(
            entities: [
              ...map.entities,
              const MapEntity(
                id: 'potion-reference',
                kind: MapEntityKind.item,
                pos: GridPos(x: 4, y: 4),
                item: MapEntityItemData(gameItemId: 'potion'),
              ),
            ],
          )
          .toJson(),
    ),
  );
}
