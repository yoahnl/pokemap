import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'scene_interactive_pokemon_gift_test.dart' show giftCatalog;
import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  const project = ProjectManifest(name: 'Seen', maps: [], tilesets: []);
  const before = GameState(saveId: 'seen', currentMapId: 'lab');
  final seen = SceneConsequence.markPokemonSeen(speciesId: 'clockbird');

  test(
    'a scene containing only seen preloads its exact native species catalog',
    () async {
      final root = await Directory.systemTemp.createTemp('scene-seen-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final config = await writeSceneCatalogPokemonGiftFixture(root);
      final scene = SceneAsset(
        id: 'seen',
        name: 'Seen',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'seen',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(seen),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'a',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'seen',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'b',
              fromNodeId: 'seen',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );
      final catalog = await loadRuntimeScenePokemonCatalog(
        scene: scene,
        projectRootDirectory: root.path,
        pokemonConfig: config,
      );
      expect(catalog!.entries.keys, ['clockbird']);
      final result = SceneConsequenceRuntimeWriter(
        project: project,
        pokemonCatalog: catalog,
      ).applyOne(before, seen);
      expect(result.gameState.progression.seenSpeciesIds, ['clockbird']);
      expect(result.gameState.party, before.party);
    },
  );
  test(
    'seen consequence commits only native Pokedex seen and survives reopen',
    () {
      final writer = SceneConsequenceRuntimeWriter(
        project: project,
        pokemonCatalog: giftCatalog(),
      );
      final result = writer.applyOne(before, seen);
      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.progression.seenSpeciesIds, ['clockbird']);
      expect(result.gameState.progression.caughtSpeciesIds, isEmpty);
      expect(result.gameState.party, before.party);
      expect(result.gameState.pokemonStorage, before.pokemonStorage);
      final reopened = GameState.fromJson(result.gameState.toJson());
      expect(
        writer.applyOne(reopened, seen).gameState.toJson(),
        reopened.toJson(),
      );
    },
  );
  test(
    'seen consequence rejects unavailable catalog or species without a write',
    () {
      for (final catalog in [null, RuntimeScenePokemonCatalog(entries: {})]) {
        final writer = SceneConsequenceRuntimeWriter(
          project: project,
          pokemonCatalog: catalog,
        );
        final result = writer.applyOne(before, seen);
        expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
        expect(identical(result.gameState, before), isTrue);
      }
    },
  );
  test('invalid seen in a batch rolls back earlier native seen updates', () {
    final writer = SceneConsequenceRuntimeWriter(
      project: project,
      pokemonCatalog: giftCatalog(),
    );
    final result = writer.applyAll(before, [
      seen,
      SceneConsequence.markPokemonSeen(speciesId: 'missing'),
    ]);
    expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
    expect(identical(result.gameState, before), isTrue);
  });
}
