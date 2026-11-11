import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

const _sceneId = 'retired-scene-reference';

void main() {
  test('a real scene reference is analysed while map references retain the dirty Pokemon exit guard', () async {
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
    expect(mapReference.sourceKind, 'map');
    commerce.editItem(
      (item) => item.copyWith(displayName: 'Potion à conserver'),
    );
    expect(commerce.dirty, isTrue);
    expect(host.pokemon.hasPendingChanges, isTrue);
    final draft = commerce.item;
    final snapshot = commerce.snapshot;
    final diskBefore = await _disk(host);

    host.decision = PokemonDraftDecision.stay;
    expect(await host.workflow.requestLeave(), isFalse);
    expect(host.draftConfirmations, 1);
    expect(host.pokemon.view, PokemonWorkspaceView.items);
    expect(commerce.item, same(draft));
    expect(commerce.item!.displayName, 'Potion à conserver');
    expect(commerce.snapshot, same(snapshot));
    expect(commerce.dirty, isTrue);
    expect(commerce.saving, isFalse);
    expect(await _disk(host), diskBefore);

    host.decision = PokemonDraftDecision.discard;
    expect(await host.workflow.requestLeave(), isTrue);
    expect(host.draftConfirmations, 2);
    expect(commerce.dirty, isFalse);
    expect(host.pokemon.hasPendingChanges, isFalse);
    expect(await _disk(host), diskBefore);
  });
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
