import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_pokemon_reference_route.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

const _sceneId = 'retired-scene-reference';
const _pickupId = 'potion-reference';

void main() {
  test(
    'a real scene reference refuses before the dirty Pokemon exit guard while map references retain that guard',
    () async {
      final host = await PokemonAuthoringFixture.create(prepareSource: _seed);
      addTearDown(host.dispose);
      expect(await host.view(PokemonWorkspaceView.items), isTrue);
      final commerce = host.commerce;
      expect(
        commerce.selectItem(
          commerce.snapshot!.catalog!.entries.singleWhere(
            (item) => item.id == 'potion',
          ),
        ),
        isTrue,
      );
      await commerce.analyzeReferences();
      final references = commerce.snapshot!.references.referencesFor('potion');
      final sceneReference = references.singleWhere(
        (reference) => reference.sourceKind == 'scene',
      );
      expect(sceneReference.sourceId, _sceneId);
      final mapReference = references.singleWhere(
        (reference) => reference.kind == ProjectItemReferenceKind.mapPickup,
      );
      commerce.editItem(
        (item) => item.copyWith(displayName: 'Potion à conserver'),
      );
      expect(commerce.dirty, isTrue);
      final draft = commerce.item;
      final snapshot = commerce.snapshot;
      final mapBefore = host.maps.active;
      final diskBefore = await _disk(host);
      final steps = <String>[];
      final route = WorkspacePokemonReferenceRoute(
        controller: host.maps,
        isActive: () => true,
        leavePokemon: () {
          steps.add('guard');
          return host.workflow.requestLeave();
        },
        sceneUnavailable: () => steps.add('scene refused'),
        showMap: () => steps.add('map shown'),
        selectEntity: (document, entityId) =>
            steps.add('selected ${document.current.id}/$entityId'),
        opened: () => steps.add('opened'),
      );

      host.decision = PokemonDraftDecision.discard;
      await route.open(sceneReference.sourceKind, sceneReference.sourceId);
      expect(steps, ['scene refused']);
      expect(host.draftConfirmations, 0);
      expect(commerce.item, same(draft));
      expect(commerce.item!.displayName, 'Potion à conserver');
      expect(commerce.snapshot, same(snapshot));
      expect(commerce.dirty, isTrue);
      expect(host.maps.active, same(mapBefore));
      expect(route.takeUnchanged(), isFalse);
      expect(await _disk(host), diskBefore);

      steps.clear();
      host.decision = PokemonDraftDecision.stay;
      await route.open(mapReference.sourceKind, mapReference.sourceId);
      expect(steps, ['guard']);
      expect(host.draftConfirmations, 1);
      expect(commerce.item, same(draft));
      expect(commerce.dirty, isTrue);
      expect(host.maps.active, same(mapBefore));
      expect(await _disk(host), diskBefore);

      steps.clear();
      host.decision = PokemonDraftDecision.discard;
      await route.open(mapReference.sourceKind, mapReference.sourceId, _pickupId);
      expect(steps, [
        'guard',
        'map shown',
        'selected ${mapReference.sourceId}/$_pickupId',
        'opened',
      ]);
      expect(host.draftConfirmations, 2);
      expect(commerce.dirty, isFalse);
      expect(host.maps.active!.current.id, mapReference.sourceId);
      expect(await _disk(host), diskBefore);
      expect(route.takeUnchanged(), isTrue);
      expect(route.takeUnchanged(), isFalse);

      steps.clear();
      await route.open(mapReference.sourceKind, mapReference.sourceId);
      expect(steps, ['guard', 'map shown', 'opened']);
      expect(host.draftConfirmations, 2);
      final document = host.maps.active!;
      document.commit(document.current.copyWith(name: 'Carte retouchée'));
      expect(route.takeUnchanged(), isFalse);

      steps.clear();
      await route.open('map', 'missing-map');
      expect(steps, ['guard']);
      expect(host.maps.active, same(document));
    },
  );
}

Future<Map<String, List<int>>> _disk(PokemonAuthoringFixture host) async => {
  for (final file
      in host.source.directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.contains('/.pokemap/'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
    file.path: await file.readAsBytes(),
};

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
                id: _pickupId,
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
