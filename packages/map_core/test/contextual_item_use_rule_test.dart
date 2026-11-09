import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'native map selection includes resources only referenced by a contextual Scene',
    () async {
      final scene = SceneAsset(
        id: 'secret',
        name: 'Secret',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'avatar',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setPlayerAvatar(characterId: 'costume'),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'a',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'avatar',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'b',
              fromNodeId: 'avatar',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Context',
        maps: [],
        tilesets: [],
        scenes: [scene],
        characters: const [
          ProjectCharacterEntry(id: 'costume', name: 'Costume', tilesetId: ''),
        ],
      );
      final publication = PortableCatalogPublication.encodeProject(project);
      final catalog = await PortableProjectCatalog.open(
        publication.descriptor,
        readObject: (reference) async =>
            publication.storage.objects[reference.sha256]!,
      );
      final selected = await ProjectCatalogSelection(catalog).forMap(
        const MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 8, height: 8),
          mapMetadata: MapMetadata(
            contextualItemUses: [
              ContextualItemUseRule(
                id: 'use',
                itemId: 'rope',
                sceneId: 'secret',
              ),
            ],
          ),
        ),
      );
      expect(selected.characters.map((character) => character.id), ['costume']);
    },
  );
  final rule = <String, dynamic>{
    'id': 'alpha-rope',
    'itemId': 'rope',
    'sceneId': 'secret',
    'priority': 10,
    'position': {'x': 6, 'y': 3},
    'facing': 'north',
  };
  test(
    'contextual item rules survive map metadata and narrative projections',
    () {
      final metadata = MapMetadata.fromJson({
        'contextualItemUses': [rule],
      });
      expect(metadata.toJson()['contextualItemUses'], [rule]);
      final map = MapData(
        id: 'alpha',
        name: 'Alpha',
        size: const GridSize(width: 12, height: 12),
        mapMetadata: metadata,
      );
      final projection = NarrativeMapProjection.fromMapData(map);
      expect(projection.toJson()['contextualItemUses'], [rule]);
      expect(
        NarrativeMapProjection.fromJson(
          projection.toJson(),
        ).toJson()['contextualItemUses'],
        [rule],
      );
      final index = buildNarrativeDependencyIndex(
        project: const ProjectManifest(name: 'Refs', maps: [], tilesets: []),
        maps: [map],
      );
      expect(
        index
            .usagesFor(
              const NarrativeDependencyKey(
                NarrativeDependencyTargetKind.scene,
                'secret',
              ),
            )
            .map((usage) => usage.path),
        contains('maps[alpha].mapMetadata.contextualItemUses[0].sceneId'),
      );
    },
  );

  test('legacy metadata and projections have no implicit item reaction', () {
    final metadata = MapMetadata.fromJson({});
    expect(metadata.contextualItemUses, isEmpty);
    expect(metadata.toJson().containsKey('contextualItemUses'), isFalse);
    final map = const MapData(
      id: 'old',
      name: 'Old',
      size: GridSize(width: 8, height: 8),
    );
    final encoded = NarrativeMapProjection.fromMapData(map).toJson()
      ..remove('contextualItemUses');
    expect(
      NarrativeMapProjection.fromJson(encoded).contextualItemUses,
      isEmpty,
    );
    expect(
      NarrativeMapProjection.fromJson(
        encoded,
      ).toJson().containsKey('contextualItemUses'),
      isFalse,
    );
  });

  test(
    'invalid contextual coordinates and facing are rejected at the codec',
    () {
      for (final invalid in [
        {
          ...rule,
          'position': {'x': -1, 'y': 3},
        },
        {...rule, 'facing': 'diagonal'},
        {...rule, 'priority': 1.5},
        {...rule, 'sceneId': ''},
      ]) {
        expect(
          () => MapMetadata.fromJson({
            'contextualItemUses': [invalid],
          }),
          throwsFormatException,
        );
      }
    },
  );
}
