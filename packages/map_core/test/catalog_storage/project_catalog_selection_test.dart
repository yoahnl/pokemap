import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../resource_pack_publication_test.dart'
    show borderFixture, modelFixture, presetFixture;

void main() {
  test('map catalogue closure includes a skin referenced only by a reachable route', () async {
    final project = ProjectManifest(name: 'Route appearance closure', maps: [],
      tilesets: const [ProjectTilesetEntry(id: 'costume', name: 'Costume', relativePath: 'costume.png')],
      characters: const [ProjectCharacterEntry(id: 'coat', name: 'Coat', tilesetId: 'costume')],
      newGame: ProjectNewGameConfig(preSessionSceneId: 'route'),
      scenes: [SceneAsset(id: 'route', name: 'Route', graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'skin', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.actorRoute(target: SceneActorTarget.player(mapId: 'room'),
            steps: [SceneActorRouteStep.appearance(characterId: 'coat')]))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [SceneEdge(id: 'start-skin', fromNodeId: 'start', fromPortId: 'completed',
        toNodeId: 'skin', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'skin-end', fromNodeId: 'skin', fromPortId: 'completed',
          toNodeId: 'end', kind: SceneEdgeKind.actionCompleted)]))]);
    final build = PortableCatalogPublication.encodeProject(project);
    final catalog = await PortableProjectCatalog.open(build.descriptor,
      readObject: (ref) async => build.storage.objects[ref.sha256]!);
    final selected = await ProjectCatalogSelection(catalog).forMap(
      const MapData(id: 'room', name: 'Room', size: GridSize(width: 1, height: 1)));
    expect(selected.characters.map((value) => value.id), ['coat']);
    expect(selected.tilesets.map((value) => value.id), ['costume']);
  });
  for (final withGround in [false, true]) {
    test('2D Border selection distinguishes draft and published snapshots '
        '(ground: $withGround)', () async {
      final base = borderFixture().latestPublished!.definition;
      final fingerprint = List.filled(64, '1').join();
      final snapshot = BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$fingerprint',
        contentFingerprint: fingerprint,
        frames: [
          BorderVisualFrameSnapshot(
            relativeAssetPath: 'assets/borders/snapshots/border.png',
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
            durationMs: 100,
          ),
        ],
      );
      final transforms = BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: [0],
      );
      final metrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'sprite',
        pixelSize: const GridSize(width: 1, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: 'border-rle-v1:1:1:1',
      );
      final project = ProjectManifest(
        name: 'Sprite Border selection',
        maps: [],
        models3d: [modelFixture()],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'sheet',
            name: 'Sheet',
            relativePath: 'sheet.png',
          ),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'objects', name: 'Objects'),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'sprite',
            name: 'Sprite',
            tilesetId: 'sheet',
            categoryId: 'objects',
            frames: [
              TilesetVisualFrame(
                tilesetId: 'sheet',
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            const ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ),
          ],
          presets: [presetFixture()],
        ),
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          visualSnapshots: [snapshot],
          records: [
            BorderBlueprintRecord(
              id: 'border',
              draft: BorderBlueprintDraft(
                baseRevision: 1,
                definition: BorderBlueprintDraftDefinition(
                  name: base.name,
                  previewSeed: base.previewSeed,
                  template: base.template,
                  defaults: base.defaults,
                  sortOrder: 0,
                  primitives: [
                    BorderPrimitiveDraft(
                      id: 'p',
                      sourceElementId: 'sprite',
                      role: BorderPrimitiveRole.lineStraight,
                      weight: 1,
                      anchorPx: BorderPixelPos(x: 0, y: 0),
                      transforms: transforms,
                      currentMetrics: metrics,
                    ),
                  ],
                  ground: withGround
                      ? BorderGroundDraft(
                          sourceSmartTilePresetId: 'terrain',
                          edgeBandCells: 1,
                        )
                      : null,
                ),
              ),
              latestPublished: BorderBlueprintRevision(
                revision: 1,
                definition: BorderBlueprintPublishedDefinition(
                  name: base.name,
                  previewSeed: base.previewSeed,
                  template: base.template,
                  defaults: base.defaults,
                  sortOrder: 0,
                  primitives: [
                    BorderPublishedPrimitive(
                      id: 'p',
                      sourceElementId: 'sprite',
                      visualSnapshotId: snapshot.id,
                      role: BorderPrimitiveRole.lineStraight,
                      weight: 1,
                      anchorPx: BorderPixelPos(x: 0, y: 0),
                      transforms: transforms,
                      publishedMetrics: metrics,
                    ),
                  ],
                  ground: withGround
                      ? BorderPublishedGround(
                          sourceSmartTilePresetId: 'terrain',
                          edgeBandCells: 1,
                          visualSnapshotIdsByRole: {
                            for (final role in BorderGroundVariantRole.values)
                              role: snapshot.id,
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final catalog = await PortableProjectCatalog.open(
        built.descriptor,
        readObject: (ref) async => built.storage.objects[ref.sha256]!,
      );
      final selected = await ProjectCatalogSelection(catalog).resolve([
        CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, 'border'),
      ]);
      expect(selected.elements.map((entry) => entry.id), ['sprite']);
      expect(selected.borderCatalog.visualSnapshots.map((entry) => entry.id), [
        snapshot.id,
      ]);
      expect(
        selected
            .borderCatalog
            .records
            .single
            .draft
            .definition
            .primitives
            .single,
        isA<BorderPrimitiveDraft>(),
      );
      expect(
        selected.smartTileCatalog.presets.map((entry) => entry.id),
        withGround ? ['terrain'] : isEmpty,
      );
    });
  }

  test(
    'a selected Border includes its published ground surfaces and terrain support',
    () async {
      final original = borderFixture();
      final published = original.latestPublished!.definition;
      final primitive = published.primitives.single;
      final definition = BorderBlueprintPublishedDefinition(
        name: published.name,
        previewSeed: published.previewSeed,
        template: published.template,
        primitives: [
          BorderPublishedPrimitive(
            id: primitive.id,
            sourceModelId: 'model',
            role: primitive.role,
            weight: 1,
            anchorWorld: primitive.anchorWorld,
            transforms: primitive.transforms,
            groundSurfaces: [
              BorderGroundSurface(
                sourceSmartTilePresetId: 'terrain',
                materialId: 'grass',
                height: 1,
                footprints: [
                  BorderGroundFootprint(
                    points: [
                      BorderGroundPoint(x: 0, z: 0),
                      BorderGroundPoint(x: 1, z: 0),
                      BorderGroundPoint(x: 0, z: 1),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        defaults: published.defaults,
        sortOrder: 0,
      );
      final project = ProjectManifest(
        name: 'Border selection',
        maps: [],
        tilesets: [],
        models3d: [modelFixture()],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            const ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ),
          ],
          presets: [presetFixture()],
        ),
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 10,
          records: [
            BorderBlueprintRecord(
              id: original.id,
              draft: original.draft,
              latestPublished: BorderBlueprintRevision(
                revision: 3,
                definition: definition,
              ),
            ),
          ],
        ),
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final catalog = await PortableProjectCatalog.open(
        built.descriptor,
        readObject: (ref) async => built.storage.objects[ref.sha256]!,
      );
      final selected = await ProjectCatalogSelection(catalog).resolve([
        CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, 'border'),
      ]);
      expect(selected.models3d.map((entry) => entry.id), ['model']);
      expect(selected.smartTileCatalog.presets.map((entry) => entry.id), [
        'terrain',
      ]);
      expect(selected.smartTileCatalog.materials.map((entry) => entry.id), [
        'grass',
      ]);
    },
  );

  test(
    'map selection excludes trainers, cinematic actors and scene visuals from other maps',
    () async {
      final project = ProjectManifest(
        name: 'Scoped visuals',
        version: ProjectVersion.v8,
        maps: [],
        tilesets: [
          for (final id in ['floor', 'foreign'])
            ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
        ],
        elementCategories: [
          const ProjectElementCategory(id: 'visuals', name: 'Visuals'),
        ],
        elements: [
          const ProjectElementEntry(
            id: 'foreign-portrait',
            name: 'Foreign portrait',
            tilesetId: 'foreign',
            categoryId: 'visuals',
            frames: [
              TilesetVisualFrame(
                tilesetId: 'foreign',
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
        ],
        characters: [
          const ProjectCharacterEntry(
            id: 'foreign-character',
            name: 'Foreign',
            tilesetId: 'foreign',
          ),
        ],
        trainers: [
          const ProjectTrainerEntry(
            id: 'foreign-trainer',
            name: 'Foreign',
            trainerClass: 'Sage',
            characterId: 'foreign-character',
            portraitElementId: 'foreign-portrait',
            team: [ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 8)],
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'foreign-cinematic',
            title: 'Foreign',
            mapId: 'other',
            timeline: CinematicTimeline(),
            stageContext: CinematicStageContext(
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'actor',
                  characterId: 'foreign-character',
                ),
              ],
            ),
          ),
        ],
        scenes: [
          SceneAsset(
            id: 'foreign-scene',
            name: 'Foreign',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'warp',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneWarpInteractiveCommand(
                      destinationMapId: 'other',
                      warpId: 'arrival',
                      presentation: SceneWarpPresentation(
                        mode: SceneWarpPresentationMode.illustrated,
                        illustrationElementId: 'foreign-portrait',
                      ),
                    ),
                  ),
                ),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'start-warp',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'warp',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                SceneEdge(
                  id: 'warp-end',
                  fromNodeId: 'warp',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow,
                ),
              ],
            ),
          ),
        ],
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final reads = <String>[];
      final catalog = await PortableProjectCatalog.open(
        build.descriptor,
        readObject: (ref) async {
          final bytes = build.storage.objects[ref.sha256]!;
          final json = jsonDecode(utf8.decode(bytes)) as Map;
          if (json['type'] == 'unit') {
            reads.add((json['key'] as Map)['id'] as String);
          }
          return bytes;
        },
      );
      reads.clear();
      final selected = await ProjectCatalogSelection(catalog).forMap(
        MapData(
          id: 'garden',
          name: 'Garden',
          size: const GridSize(width: 8, height: 8),
          tilesetId: 'floor',
        ),
      );
      expect(reads, ['floor']);
      expect(selected.characters, isEmpty);
      expect(selected.elements, isEmpty);
      expect(selected.tilesets.map((entry) => entry.id), ['floor']);
      expect(selected.trainers, project.trainers);
      ProjectValidator.validateCatalogSelection(selected);
      final reachableBuild = PortableCatalogPublication.encodeProject(
        project.copyWith(
          newGame: ProjectNewGameConfig(preSessionSceneId: 'foreign-scene'),
        ),
      );
      final reachable = await PortableProjectCatalog.open(
        reachableBuild.descriptor,
        readObject: (ref) async => reachableBuild.storage.objects[ref.sha256]!,
      );
      final sceneSelection = await ProjectCatalogSelection(reachable).forMap(
        MapData(
          id: 'garden',
          name: 'Garden',
          size: const GridSize(width: 8, height: 8),
          tilesetId: 'floor',
        ),
      );
      expect(sceneSelection.elements.map((entry) => entry.id), [
        'foreign-portrait',
      ]);
      expect(sceneSelection.tilesets.map((entry) => entry.id).toSet(), {
        'floor',
        'foreign',
      });
      expect(sceneSelection.characters, isEmpty);
      ProjectValidator.validateCatalogSelection(sceneSelection);
    },
  );
  test(
    'classification parents resolve before building the selected library',
    () async {
      final project = ProjectManifest(
        name: 'Classified',
        maps: [],
        tilesets: [
          const ProjectTilesetEntry(
            id: 'sheet',
            name: 'Sheet',
            relativePath: 'sheet.png',
          ),
        ],
        elements: [
          const ProjectElementEntry(
            id: 'chair',
            name: 'Chair',
            tilesetId: 'sheet',
            categoryId: '',
            frames: [],
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(id: 'parent', name: 'Parent'),
            ResourceFamily(id: 'child', name: 'Child', parentId: 'parent'),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'chair',
              familyId: 'child',
              placementContext: ResourcePlacementContext.interior,
            ),
          ],
        ),
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final catalog = await PortableProjectCatalog.open(
        build.descriptor,
        readObject: (r) async => build.storage.objects[r.sha256]!,
      );
      final selected = await ProjectCatalogSelection(
        catalog,
      ).resolve([CatalogDefinitionKey(CatalogDefinitionKind.element, 'chair')]);
      expect(
        selected.resourceLibraryCatalog.families.map((f) => f.id).toSet(),
        {'parent', 'child'},
      );
      expect(selected.resourceLibraryCatalog.entries.single.familyId, 'child');
      expect(
        selected.resourceLibraryCatalog.entries.single.placementContext,
        ResourcePlacementContext.interior,
      );
    },
  );
  test(
    'selection resolves typed dependencies without unrelated payloads',
    () async {
      for (final count in [128, 256, 512]) {
        final project = ProjectManifest(
          name: 'Selection',
          maps: [],
          tilesets: [
            const ProjectTilesetEntry(
              id: 'sheet',
              name: 'Sheet',
              relativePath: 'assets/sheet.png',
            ),
          ],
          elements: [
            for (var i = 0; i < count; i++)
              ProjectElementEntry(
                id: 'element-$i',
                name: 'Decor $i',
                tilesetId: 'sheet',
                categoryId: '',
                frames: [
                  const TilesetVisualFrame(
                    tilesetId: 'sheet',
                    source: TilesetSourceRect(
                      x: 0,
                      y: 0,
                      width: 16,
                      height: 16,
                    ),
                  ),
                ],
              ),
          ],
        );
        final build = PortableCatalogPublication.encodeProject(project);
        final unitsRead = <String>[];
        final catalog = await PortableProjectCatalog.open(
          build.descriptor,
          readObject: (reference) async {
            final bytes = build.storage.objects[reference.sha256]!;
            final json = jsonDecode(utf8.decode(bytes)) as Map;
            if (json['type'] == 'unit') {
              unitsRead.add((json['key'] as Map)['id'] as String);
            }
            return bytes;
          },
        );
        unitsRead.clear();
        final selection = await ProjectCatalogSelection(catalog).resolve([
          CatalogDefinitionKey(
            CatalogDefinitionKind.element,
            'element-${count - 1}',
          ),
        ]);
        expect(selection.elements.map((e) => e.id), ['element-${count - 1}']);
        expect(selection.tilesets.map((e) => e.id), ['sheet']);
        expect(unitsRead.toSet(), {'element-${count - 1}', 'sheet'});
        expect(selection.maps, project.maps);
        unitsRead.clear();
        final mapSelection = await ProjectCatalogSelection(catalog).forMap(
          MapData(
            id: 'garden',
            name: 'Garden',
            size: const GridSize(width: 8, height: 8),
            tilesetId: 'sheet',
            layers: [MapLayer.object(id: 'objects', name: 'Objects')],
            placedElements: [
              MapPlacedElement(
                id: 'placed',
                layerId: 'objects',
                elementId: 'element-${count - 1}',
                pos: const GridPos(x: 2, y: 2),
              ),
            ],
          ),
        );
        expect(mapSelection.elements, selection.elements);
        expect(mapSelection.tilesets, selection.tilesets);
        expect(unitsRead.toSet(), {'element-${count - 1}', 'sheet'});
      }
    },
  );

  test(
    'selection rejects a missing dependency instead of returning an empty preview',
    () async {
      final project = ProjectManifest(
        name: 'Missing',
        maps: [],
        tilesets: [],
        elements: [
          const ProjectElementEntry(
            id: 'chair',
            name: 'Chair',
            tilesetId: 'missing',
            categoryId: '',
            frames: [],
          ),
        ],
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final catalog = await PortableProjectCatalog.open(
        build.descriptor,
        readObject: (r) async => build.storage.objects[r.sha256]!,
      );
      await expectLater(
        ProjectCatalogSelection(catalog).resolve([
          CatalogDefinitionKey(CatalogDefinitionKind.element, 'chair'),
        ]),
        throwsFormatException,
      );
    },
  );
}
