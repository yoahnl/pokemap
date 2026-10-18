import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_runtime/src/application/character_animation_source_resolver.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  for (final factor in [1, 2, 4]) {
    test('unchanged map ignores unused scene library at ${factor}x', () {
      final project = _project([
        _scene('local'),
        for (var index = 0; index < factor * 8; index++)
          _scene('unused-$index'),
      ]);
      expect(collectAllRuntimeTilesetIds(_map(), project), {'local-sheet'});
    });
  }

  test('every conditional event page remains available', () {
    final map = _map().copyWith(
      events: [
        MapEventDefinition(
          id: 'event',
          position: const EventPosition(layerId: 'objects', x: 0, y: 0),
          pages: const [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'local'),
            ),
            MapEventPage(
              pageNumber: 1,
              sceneTarget: MapEventSceneTarget(sceneId: 'future'),
            ),
          ],
        ),
      ],
    );
    expect(
      collectAllRuntimeTilesetIds(
        map,
        _project([_scene('local'), _scene('future'), _scene('unused')]),
      ),
      {'local-sheet', 'future-sheet'},
    );
  });

  test('map event sources and pending outcome roots keep future media', () {
    final sources = [
      NarrativeEventSourceRef.mapEnter('map'),
      NarrativeEventSourceRef.entityInteract('other-map', 'npc'),
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer-on-another-map',
          outcomeId: 'completed',
        ),
      ),
    ];
    final names = ['local', 'unused', 'pending'];
    final project = _project([for (final name in names) _scene(name)]).copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        legacyClaims: [],
        records: [
          for (var index = 0; index < sources.length; index++)
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-0000-7000-8000-00000000000${index + 1}',
                name: names[index],
                source: sources[index],
                conditions: [],
                sceneId: names[index],
                reusePolicy: NarrativeEventReusePolicy.reusable,
                priority: 0,
                order: index,
              ),
              enabled: true,
            ),
        ],
      ),
    );
    expect(collectAllRuntimeTilesetIds(_map(), project), {
      'local-sheet',
      'pending-sheet',
    });
  });

  test(
    'cinematic appearance roots preserve future custom animation sources',
    () {
      final scene = SceneAsset(
        id: 'local',
        name: 'Local',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'intro'),
            ),
          ],
        ),
      );
      CinematicAsset cinematic(String id, String character) => CinematicAsset(
        id: id,
        title: id,
        timeline: CinematicTimeline(),
        stageContext: CinematicStageContext(
          actorAppearanceBindings: [
            CinematicActorAppearanceBinding(
              actorId: 'actor',
              characterId: character,
            ),
          ],
        ),
      );
      final project = _project([scene]).copyWith(
        characters: [_character('intro-actor'), _character('unused-actor')],
        cinematics: [
          cinematic('intro', 'intro-actor'),
          cinematic('unused', 'unused-actor'),
        ],
      );
      expect(collectRuntimeMapCharacterIds(_map(), project), {'intro-actor'});
    },
  );

  for (final factor in [1, 2, 4]) {
    test(
      'unchanged map requests only effective character sources at ${factor}x',
      () {
        final characters = [
          _character('hero'),
          _character('guide'),
          _character('declared'),
          for (var index = 0; index < factor * 8; index++)
            _character('unused-$index'),
        ];
        final project = _project([]).copyWith(
          characters: characters,
          settings: const ProjectSettings(defaultPlayerCharacterId: 'hero'),
        );
        final map = _map().copyWith(
          entities: const [
            MapEntity(
              id: 'guide-instance',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 1),
              npc: MapEntityNpcData(characterId: 'guide'),
            ),
          ],
        );
        final opened = <String>[];
        final catalog = AssetCatalog(
          records: [
            for (final character in characters)
              for (final state in ['walk', 'run'])
                AssetRecord(
                  id: '${character.id}-$state',
                  logicalPath: '${character.id}-$state.png',
                  artifact: ContentArtifactRef.fromBytes([
                    character.id.length,
                    state.length,
                  ], mediaType: 'image/png'),
                ),
          ],
        );
        final plan = buildCharacterAnimationSourcePreloadPlan(
          manifest: project,
          map: map,
          projectRootDirectory: '/project',
          assetCatalog: catalog,
          additionalCharacterIds: {'declared'},
          fileExists: (path) {
            opened.add(path);
            return true;
          },
        );
        expect(plan.absolutePathsByAssetId.keys.toSet(), {
          'hero-walk',
          'hero-run',
          'guide-walk',
          'guide-run',
          'declared-walk',
          'declared-run',
        });
        expect(opened, hasLength(6));
        expect(plan.diagnostics, isEmpty);
        expect(collectRuntimeMapCharacterIds(map, project), {'hero', 'guide'});
      },
    );
  }

  test('global and local scenario roots retain their scene media', () {
    final project =
        _project([
          _scene('local'),
          _scene('global'),
          _scene('linked'),
          _scene('other'),
          _scene('extra'),
        ]).copyWith(
          scenarios: [
            ScenarioAsset(
              id: 'global',
              name: 'Global',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'source',
              nodes: const [
                ScenarioNode(
                  id: 'source',
                  metadata: {'eventV2.sceneId': 'global'},
                ),
              ],
            ),
            ScenarioAsset(
              id: 'local',
              name: 'Local',
              entryNodeId: 'source',
              nodes: const [
                ScenarioNode(
                  id: 'source',
                  binding: ScenarioNodeBinding(mapId: 'map'),
                  metadata: {'eventV2.sceneId': 'linked'},
                ),
              ],
            ),
            ScenarioAsset(
              id: 'other',
              name: 'Other',
              entryNodeId: 'source',
              nodes: const [
                ScenarioNode(
                  id: 'source',
                  binding: ScenarioNodeBinding(mapId: 'other-map'),
                  metadata: {'eventV2.sceneId': 'other'},
                ),
              ],
            ),
          ],
        );
    expect(
      collectAllRuntimeTilesetIds(
        _map(),
        project,
        additionalSceneIds: {'extra'},
      ),
      {'local-sheet', 'global-sheet', 'linked-sheet', 'extra-sheet'},
    );
  });
}

ProjectCharacterEntry _character(String id) => ProjectCharacterEntry(
  id: id,
  name: id,
  tilesetId: '$id-legacy',
  animations: [
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.south,
      sourceAssetId: '$id-walk',
    ),
    CharacterAnimation(
      state: CharacterAnimationState.run,
      direction: EntityFacing.north,
      sourceAssetId: '$id-run',
    ),
  ],
);

MapData _map() => const MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 2, height: 2),
  events: [
    MapEventDefinition(
      id: 'event',
      position: EventPosition(layerId: 'objects', x: 0, y: 0),
      pages: [
        MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'local'),
        ),
      ],
    ),
  ],
);

ProjectManifest _project(List<SceneAsset> scenes) => ProjectManifest(
  name: 'Scoped scene media',
  maps: [],
  tilesets: [
    for (final scene in scenes)
      ProjectTilesetEntry(
        id: '${scene.id}-sheet',
        name: scene.id,
        relativePath: 'tilesets/${scene.id}.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: '${scene.id}-sheet',
          pixelWidth: 4,
          pixelHeight: 3,
          tileWidth: 4,
          tileHeight: 3,
        ),
      ),
  ],
  elements: [
    for (final scene in scenes)
      ProjectElementEntry(
        id: scene.id,
        name: scene.id,
        tilesetId: '${scene.id}-sheet',
        categoryId: 'pictures',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
  ],
  scenes: scenes,
);

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'warp',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.warp(
            destinationMapId: 'map',
            warpId: 'arrival',
            presentation: SceneWarpPresentation(
              mode: SceneWarpPresentationMode.illustrated,
              illustrationElementId: id,
            ),
          ),
        ),
      ),
    ],
  ),
);
