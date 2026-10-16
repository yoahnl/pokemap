import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'resource_pack_publication_test.dart'
    show modelFixture, presetFixture, borderFixture;

void main() {
  test('portable tilesets never activate project world designation', () {
    final base = fixture();
    final tileset = base.tilesets.single.copyWith(isWorldTileset: true);
    expect(
      () => ResourcePackCatalog(
        tilesets: [tileset],
        files: base.files,
        provenance: base.provenance,
      ),
      throwsFormatException,
    );
    final json = base.toJson();
    ((json['tilesets'] as List).first as Map)['isWorldTileset'] = true;
    expect(() => ResourcePackCatalog.fromJson(json), throwsFormatException);
  });

  test(
    'portable catalog rejects project data and unknown nested null keys',
    () {
      for (final key in [
        'maps',
        'groups',
        'presentation',
        'dialogues',
        'events',
        'settings',
        'unknown',
      ]) {
        expect(
          () => ResourcePackCatalog.fromJson({
            ...ResourcePackCatalog().toJson(),
            key: null,
          }),
          throwsFormatException,
        );
      }
      final json = fixture().toJson();
      ((json['elements']! as List).first as Map)['secret'] = null;
      expect(() => ResourcePackCatalog.fromJson(json), throwsFormatException);
      final nested = fixture().toJson();
      ((((nested['elements']! as List).first as Map)['frames'] as List).first
              as Map)['secret'] =
          0;
      expect(() => ResourcePackCatalog.fromJson(nested), throwsFormatException);
      expect(ResourcePackCatalog.fromJson(fixture().toJson()), fixture());
    },
  );
  test('closure is stable and shares dependencies and parents', () {
    final graph = ResourcePackDependencyGraph.fromCatalog(fixture());
    final roots = [
      for (final id in ['chair', 'table'])
        ResourcePackRef(kind: ResourcePackKind.element, id: id),
    ];
    final closure = graph.closure(roots: roots);
    expect(closure.nodes, graph.closure(roots: roots.reversed).nodes);
    expect(closure.files, ['image']);
    expect(
      closure.supports
          .where((s) => s.kind == ResourcePackSupportKind.resourceFamily)
          .map((s) => s.id),
      ['custom-child', 'custom-parent'],
    );
    expect(closure.resources.map((r) => r.identity), [
      'element:chair',
      'element:table',
      'tileset:sheet',
    ]);
    expect(
      closure.supports
          .where((s) => s.kind == ResourcePackSupportKind.elementCategory)
          .map((s) => s.id),
      ['furniture', 'objects'],
    );
  });
  test('missing reference diagnostics preserve every resource kind', () {
    final graph = ResourcePackDependencyGraph.fromCatalog(fixture());
    for (final kind in ResourcePackKind.values) {
      expect(
        () => graph.closure(
          roots: [ResourcePackRef(kind: kind, id: 'absent')],
        ),
        throwsA(
          isA<ResourcePackDependencyException>()
              .having((e) => e.code, 'code', 'pack.reference_missing')
              .having((e) => e.reference.resource?.kind, 'kind', kind),
        ),
      );
    }
  });
  test('cycles fail and a long chain does not recurse', () {
    ResourcePackNodeRef ref(String id) => ResourcePackNodeRef.resource(
      ResourcePackRef(kind: ResourcePackKind.element, id: id),
    );
    final graph = ResourcePackDependencyGraph(
      nodes: [
        ResourcePackDependencyNode(
          reference: ref('a'),
          dependencies: [ref('b')],
        ),
        ResourcePackDependencyNode(
          reference: ref('b'),
          dependencies: [ref('a')],
        ),
      ],
    );
    expect(
      () => graph.closure(roots: [ref('a').resource!]),
      throwsA(
        isA<ResourcePackDependencyException>().having(
          (e) => e.code,
          'code',
          'pack.dependency_cycle',
        ),
      ),
    );
    final long = ResourcePackDependencyGraph(
      nodes: [
        for (var i = 0; i < 12000; i++)
          ResourcePackDependencyNode(
            reference: ref('n$i'),
            dependencies: [if (i < 11999) ref('n${i + 1}')],
          ),
      ],
    );
    expect(
      long.closure(roots: [ref('n0').resource!]).resources,
      hasLength(12000),
    );
  });
  test('tileset frames cross owners and groups stay owner scoped', () {
    final base = fixture();
    final first = base.tilesets.single.copyWith(
      folderId: 'folder',
      elementGroups: [const TilesetElementGroup(id: 'same', name: 'First')],
      paletteEntries: [
        const TilesetPaletteEntry(
          id: 'tile',
          frames: [
            TilesetVisualFrame(
              tilesetId: 'other',
              source: TilesetSourceRect(x: 0, y: 0),
            ),
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    );
    final other = first.copyWith(
      id: 'other',
      name: 'Other',
      paletteEntries: [],
      elementGroups: [const TilesetElementGroup(id: 'same', name: 'Second')],
    );
    final graph = ResourcePackDependencyGraph.fromCatalog(
      ResourcePackCatalog(
        tilesets: [first, other],
        tilesetFolders: [
          const ProjectTilesetFolder(
            id: 'folder',
            name: 'Folder',
            parentFolderId: 'parent',
          ),
          const ProjectTilesetFolder(id: 'parent', name: 'Parent'),
        ],
        files: base.files,
        provenance: base.provenance,
      ),
    );
    final closure = graph.closure(
      roots: [ResourcePackRef(kind: ResourcePackKind.tileset, id: 'sheet')],
    );
    expect(closure.resources.map((r) => r.id), ['other', 'sheet']);
    final groups = closure.supports
        .where((s) => s.kind == ResourcePackSupportKind.tilesetElementGroup)
        .toList();
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.owner!.id).toSet(), {'sheet', 'other'});
    expect(closure.files, ['image']);
  });
  test(
    'Smart Tile supports include every typed source and only explicit extras',
    () {
      final base = fixture();
      final preset = presetFixture().copyWith(
        allowedMaterialIds: ['grass', 'stone'],
        rules: [
          const SmartTileRule(
            id: 'r',
            centerMatch: SmartTileSlotMatch.material('grass'),
            signature: SmartTileSignature(
              northEdge: SmartTileSlotMatch.material('stone'),
            ),
            candidates: [
              SmartTileCandidate(
                id: 'c',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'anim',
                    ),
                  ),
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.model3d(modelId: 'model'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final smart = ProjectSmartTileCatalog(
        categories: [
          const ProjectSmartTileCategory(id: 'ground', name: 'Ground'),
        ],
        materials: [
          for (final id in ['grass', 'stone'])
            ProjectSmartTileMaterial(
              id: id,
              name: id,
              connectionGroupId: 'group',
              categoryId: 'ground',
            ),
        ],
        atlases: [
          const ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'sheet',
            columns: 1,
            rows: 1,
          ),
        ],
        animations: [
          const ProjectSmartTileAnimation(
            id: 'anim',
            name: 'Animation',
            frames: [
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
                durationMs: 100,
              ),
            ],
          ),
        ],
        presets: [preset],
        patterns: [
          const ProjectSmartTilePattern(
            id: 'pattern',
            name: 'Pattern',
            usage: SmartTileUsage.terrain,
            width: 1,
            height: 1,
            cells: [
              SmartTilePatternCell(
                x: 0,
                y: 0,
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final catalog = ResourcePackCatalog(
        tilesets: base.tilesets,
        models3d: [modelFixture()],
        smartTileCatalog: smart,
        smartTilePatternIds: ['pattern'],
        files: [
          ...base.files,
          fileBinding('glb', 'assets/models3d/model.glb', glb: true),
        ],
        provenance: base.provenance,
      );
      final graph = ResourcePackDependencyGraph.fromCatalog(
        ResourcePackCatalog.fromJson(catalog.toJson()),
      );
      final closure = graph.closure(
        roots: [
          ResourcePackRef(
            kind: ResourcePackKind.smartTilePreset,
            id: 'terrain',
          ),
        ],
      );
      expect(closure.files, ['glb', 'image']);
      expect(
        closure.supports.map((s) => s.kind).toSet(),
        containsAll([
          ResourcePackSupportKind.smartTileMaterial,
          ResourcePackSupportKind.smartTileConnectionGroup,
          ResourcePackSupportKind.smartTileAnimation,
          ResourcePackSupportKind.smartTileAtlas,
          ResourcePackSupportKind.smartTileCategory,
        ]),
      );
      expect(
        closure.supports.any(
          (s) => s.kind == ResourcePackSupportKind.smartTilePattern,
        ),
        isFalse,
      );
      final extra = graph.closure(roots: [], smartTilePatternIds: ['pattern']);
      expect(extra.files, ['image']);
      expect(extra.supports.map((s) => s.id), contains('pattern'));
      expect(
        () => graph.closure(roots: [], smartTilePatternIds: ['missing']),
        throwsA(isA<ResourcePackDependencyException>()),
      );
      final draft = reconstructResourcePackSmartTileDraft(
        preset: preset,
        catalog: smart,
      );
      expect(draft.animations.single.id, 'anim');
      expect(draft.atlases.single.id, 'atlas');
      expect(draft.materials, hasLength(2));
    },
  );
  test(
    'connection groups from different packs are isolated by typed remapping',
    () {
      final source = ProjectSmartTileCatalog(
        materials: [
          const ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'shared',
          ),
        ],
      );
      final first = remapResourcePackConnectionGroups(source, {
        'shared': 'rp_first_group',
      });
      final second = remapResourcePackConnectionGroups(source, {
        'shared': 'rp_second_group',
      });
      expect(
        first.materials.single.connectionGroupId,
        isNot(second.materials.single.connectionGroupId),
      );
      expect(source.materials.single.connectionGroupId, 'shared');
      expect(
        () => remapResourcePackConnectionGroups(source, {}),
        throwsFormatException,
      );
    },
  );
  test(
    'character portraits and custom animation files and definitions are visited',
    () {
      final base = fixture();
      final character = ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'sheet',
        portraits: [
          const CharacterPortraitVariant(
            portraitStateId: 'happy',
            assetId: 'portrait',
          ),
        ],
        animations: [
          const CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.south,
            sourceAssetId: 'walk',
          ),
        ],
        customAnimations: [
          const CharacterCustomAnimationClip(
            definitionId: 'wave',
            sourceAssetId: 'wave',
          ),
        ],
      );
      final catalog = ResourcePackCatalog(
        tilesets: base.tilesets,
        characters: [character],
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(id: 'happy', displayName: 'Happy'),
          ],
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Wave',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
        files: [
          ...base.files,
          for (final id in ['portrait', 'walk', 'wave'])
            fileBinding(id, 'assets/$id.png'),
        ],
        provenance: base.provenance,
      );
      final closure =
          ResourcePackDependencyGraph.fromCatalog(
            ResourcePackCatalog.fromJson(catalog.toJson()),
          ).closure(
            roots: [
              ResourcePackRef(kind: ResourcePackKind.character, id: 'hero'),
            ],
          );
      expect(closure.files, ['image', 'portrait', 'walk', 'wave']);
      expect(closure.supports.map((s) => s.kind).toSet(), {
        ResourcePackSupportKind.characterPortraitState,
        ResourcePackSupportKind.characterAnimationDefinition,
      });
    },
  );
  test(
    'all three tileset property locations reject opaque structured references',
    () {
      final base = fixture();
      for (final location in ['source', 'tile', 'collision']) {
        const property = ProjectTilesetProperty(
          name: 'opaque',
          type: ProjectTilesetPropertyType.structured,
          value: null,
        );
        final source = ProjectTilesetSource.imageCollection(
          pages: [
            const ProjectImageCollectionPage(
              id: 'page',
              assetId: 'image',
              pixelWidth: 16,
              pixelHeight: 16,
            ),
          ],
          properties: location == 'source' ? [property] : [],
          tileDefinitions: [
            ProjectImageCollectionTileDefinition(
              tileId: 0,
              pageId: 'page',
              sourceRect: const ProjectTilesetPixelRect(
                x: 0,
                y: 0,
                width: 16,
                height: 16,
              ),
              properties: location == 'tile' ? [property] : [],
              collisionObjects: [
                ProjectTilesetCollisionObject(
                  id: 1,
                  x: 0,
                  y: 0,
                  properties: location == 'collision' ? [property] : [],
                ),
              ],
            ),
          ],
        );
        expect(
          () => ResourcePackCatalog(
            tilesets: [base.tilesets.single.copyWith(source: source)],
            files: base.files,
            provenance: base.provenance,
          ),
          throwsFormatException,
          reason: location,
        );
      }
    },
  );

  test(
    'tileset property asset references are visited and local object references stay local',
    () {
      final base = fixture();
      final source = ProjectTilesetSource.imageCollection(
        pages: [
          const ProjectImageCollectionPage(
            id: 'page',
            assetId: 'image',
            pixelWidth: 16,
            pixelHeight: 16,
          ),
        ],
        properties: [
          const ProjectTilesetProperty(
            name: 'sourceFile',
            type: ProjectTilesetPropertyType.assetReference,
            value: 'extra',
          ),
        ],
        tileDefinitions: [
          const ProjectImageCollectionTileDefinition(
            tileId: 0,
            pageId: 'page',
            sourceRect: ProjectTilesetPixelRect(
              x: 0,
              y: 0,
              width: 16,
              height: 16,
            ),
            properties: [
              ProjectTilesetProperty(
                name: 'tileFile',
                type: ProjectTilesetPropertyType.assetReference,
                value: 'extra',
              ),
            ],
            collisionObjects: [
              ProjectTilesetCollisionObject(
                id: 1,
                x: 0,
                y: 0,
                properties: [
                  ProjectTilesetProperty(
                    name: 'objectFile',
                    type: ProjectTilesetPropertyType.assetReference,
                    value: 'extra',
                  ),
                  ProjectTilesetProperty(
                    name: 'local',
                    type: ProjectTilesetPropertyType.objectReference,
                    value: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final catalog = ResourcePackCatalog(
        tilesets: [base.tilesets.single.copyWith(source: source)],
        files: [...base.files, fileBinding('extra', 'assets/extra.png')],
        provenance: base.provenance,
      );
      final graph = ResourcePackDependencyGraph.fromCatalog(
        ResourcePackCatalog.fromJson(catalog.toJson()),
      );
      expect(
        graph
            .closure(
              roots: [
                ResourcePackRef(kind: ResourcePackKind.tileset, id: 'sheet'),
              ],
            )
            .files,
        ['extra', 'image'],
      );
      final raw = catalog.toJson();
      final sourceJson =
          ((raw['tilesets'] as List).single as Map)['source'] as Map;
      (sourceJson['properties'] as List).add({
        'name': 'outside',
        'type': 'object_reference',
        'value': 999,
      });
      expect(
        () => ResourcePackDependencyGraph.fromCatalog(
          ResourcePackCatalog.fromJson(raw),
        ),
        throwsFormatException,
      );
      for (final location in ['source', 'tile', 'collision']) {
        final raw = catalog.toJson();
        final sourceJson =
            ((raw['tilesets'] as List).single as Map)['source'] as Map;
        final tile = (sourceJson['tileDefinitions'] as List).single as Map;
        final collision = (tile['collisionObjects'] as List).single as Map;
        final owner = switch (location) {
          'source' => sourceJson,
          'tile' => tile,
          _ => collision,
        };
        ((owner['properties'] as List).first as Map)['unknown'] = null;
        expect(
          () => ResourcePackCatalog.fromJson(raw),
          throwsFormatException,
          reason: location,
        );
      }
    },
  );
  test(
    'spatial Border ground surfaces include Smart Tile and material references',
    () {
      final base = fixture();
      final original = borderFixture();
      final published = original.latestPublished!.definition;
      final primitive = published.primitives.single;
      final surface = BorderGroundSurface(
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
      );
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
            groundSurfaces: [surface],
          ),
        ],
        defaults: published.defaults,
        sortOrder: 0,
      );
      final record = BorderBlueprintRecord(
        id: original.id,
        draft: original.draft,
        latestPublished: BorderBlueprintRevision(
          revision: 3,
          definition: definition,
        ),
      );
      final smart = ProjectSmartTileCatalog(
        materials: [
          const ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        presets: [presetFixture()],
      );
      final catalog = ResourcePackCatalog(
        models3d: [modelFixture()],
        smartTileCatalog: smart,
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 10,
          records: [record],
        ),
        files: [fileBinding('glb', 'assets/models3d/model.glb', glb: true)],
        provenance: base.provenance,
      );
      final closure =
          ResourcePackDependencyGraph.fromCatalog(
            ResourcePackCatalog.fromJson(catalog.toJson()),
          ).closure(
            roots: [
              ResourcePackRef(
                kind: ResourcePackKind.borderBlueprint,
                id: 'border',
              ),
            ],
          );
      expect(closure.resources.map((r) => r.identity), [
        'borderBlueprint:border',
        'model3d:model',
        'smartTilePreset:terrain',
      ]);
      expect(
        closure.supports.any(
          (s) =>
              s.kind == ResourcePackSupportKind.smartTileMaterial &&
              s.id == 'grass',
        ),
        isTrue,
      );
      expect(closure.files, ['glb']);
    },
  );

  test(
    'published Border ground visits preset snapshots and files once with portable aliases',
    () {
      final base = fixture();
      final fingerprint = 'c' * 64;
      final snapshot = BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$fingerprint',
        contentFingerprint: fingerprint,
        frames: [
          BorderVisualFrameSnapshot(
            relativeAssetPath: 'assets/borders/snapshots/source.png',
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
            durationMs: 100,
          ),
        ],
      );
      final metrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'pixels',
        pixelSize: const GridSize(width: 1, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: 'border-rle-v1:1:1:1',
      );
      final original = borderFixture();
      final published = original.latestPublished!.definition;
      final ground = BorderPublishedGround(
        sourceSmartTilePresetId: 'terrain',
        edgeBandCells: 1,
        visualSnapshotIdsByRole: {
          for (final role in standardBorderGroundVariantRoleOrder)
            role: snapshot.id,
        },
      );
      final definition = BorderBlueprintPublishedDefinition(
        name: 'Raster Border',
        previewSeed: published.previewSeed,
        template: published.template,
        primitives: [
          BorderPublishedPrimitive(
            id: 'p',
            sourceElementId: 'chair',
            visualSnapshotId: snapshot.id,
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: BorderPixelPos(x: 0, y: 0),
            transforms: BorderTransformPolicy(
              allowFlipX: false,
              allowedQuarterTurns: [0],
            ),
            publishedMetrics: metrics,
          ),
        ],
        defaults: published.defaults,
        ground: ground,
        sortOrder: 0,
      );
      final record = BorderBlueprintRecord(
        id: 'border',
        draft: original.draft,
        latestPublished: BorderBlueprintRevision(
          revision: 3,
          definition: definition,
        ),
      );
      final preset = presetFixture().copyWith(
        rules: [
          const SmartTileRule(
            id: 'r',
            centerMatch: SmartTileSlotMatch.material('grass'),
            signature: SmartTileSignature(),
            candidates: [
              SmartTileCandidate(
                id: 'c',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final smart = ProjectSmartTileCatalog(
        materials: [
          const ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        atlases: [
          const ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'sheet',
            columns: 1,
            rows: 1,
          ),
        ],
        presets: [preset],
      );
      final catalog = ResourcePackCatalog(
        tilesets: base.tilesets,
        elements: base.elements,
        elementCategories: base.elementCategories,
        smartTileCatalog: smart,
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 10,
          records: [record],
          visualSnapshots: [snapshot],
        ),
        files: [
          ...base.files,
          fileBinding('snapshot', snapshot.frames.single.relativeAssetPath),
        ],
        provenance: base.provenance,
      );
      final restored = ResourcePackCatalog.fromJson(catalog.toJson());
      final closure = ResourcePackDependencyGraph.fromCatalog(restored).closure(
        roots: [
          ResourcePackRef(kind: ResourcePackKind.borderBlueprint, id: 'border'),
        ],
      );
      expect(closure.files, ['image', 'snapshot']);
      final alias = closure.supports.singleWhere(
        (s) => s.kind == ResourcePackSupportKind.borderSnapshot,
      );
      expect(alias.id, resourcePackBorderSnapshotAlias(fingerprint));
      expect(restored.borderCatalog.visualSnapshots.single.id, snapshot.id);
      final mapping = ResourcePackSupportMapping(
        kind: ResourcePackSupportKind.borderSnapshot,
        sourceId: alias.id,
        targetId: snapshot.id,
      );
      expect(mapping.targetId, contains(':'));
      expect(
        restored
            .borderCatalog
            .records
            .single
            .draft
            .definition
            .ground!
            .sourceSmartTilePresetId,
        'terrain',
      );
    },
  );
  test('missing support and file references fail the selected closure', () {
    final base = fixture();
    final graph = ResourcePackDependencyGraph.fromCatalog(base);
    final root = ResourcePackRef(kind: ResourcePackKind.element, id: 'chair');
    final selected = graph.closure(roots: [root]);
    for (final target in selected.nodes.where(
      (n) => n.support != null || n.fileId != null,
    )) {
      final missing = ResourcePackDependencyGraph(
        nodes: graph.nodes.where((n) => n.reference != target),
      );
      expect(
        () => missing.closure(roots: [root]),
        throwsA(
          isA<ResourcePackDependencyException>()
              .having((e) => e.code, 'code', 'pack.reference_missing')
              .having((e) => e.reference, 'reference', target),
        ),
      );
    }
  });

  test(
    'catalog rejects missing mandatory lists and invalid portable support identities',
    () {
      for (final key in ['tilesets', 'files', 'provenance']) {
        final json = ResourcePackCatalog().toJson()..remove(key);
        expect(
          () => ResourcePackCatalog.fromJson(json),
          throwsFormatException,
          reason: key,
        );
      }
      expect(
        () => ResourcePackCatalog(
          elementCategories: [
            const ProjectElementCategory(id: 'with space', name: 'Invalid'),
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => ResourcePackCatalog(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'element',
                resourceId: 'absent',
                placementContext: ResourcePlacementContext.interior,
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
      final base = fixture();
      expect(
        () => ResourcePackCatalog(
          tilesets: [base.tilesets.single.copyWith(scope: TilesetScope.group)],
          files: base.files,
          provenance: base.provenance,
        ),
        throwsFormatException,
      );
    },
  );

  test('tileset source binding owns its declared relative path', () {
    final base = fixture();
    final wrong = base.tilesets.single.copyWith(
      relativePath: 'assets/other.png',
    );
    expect(
      () => ResourcePackCatalog(
        tilesets: [wrong],
        files: [...base.files, fileBinding('other', 'assets/other.png')],
        provenance: base.provenance,
      ),
      throwsFormatException,
    );
    final collection = wrong.copyWith(
      source: const ProjectTilesetSource.imageCollection(
        pages: [
          ProjectImageCollectionPage(
            id: 'page',
            assetId: 'image',
            pixelWidth: 16,
            pixelHeight: 16,
          ),
        ],
        tileDefinitions: [
          ProjectImageCollectionTileDefinition(
            tileId: 0,
            pageId: 'page',
            sourceRect: ProjectTilesetPixelRect(
              x: 0,
              y: 0,
              width: 16,
              height: 16,
            ),
          ),
        ],
        properties: [],
      ),
    );
    expect(
      () => ResourcePackCatalog(
        tilesets: [collection],
        files: [...base.files, fileBinding('other', 'assets/other.png')],
        provenance: base.provenance,
      ),
      throwsFormatException,
    );
  });
  test(
    'environment presets visit both palette dimensions category family parents and source files',
    () {
      final base = fixture();
      final preset = EnvironmentPreset(
        id: 'garden',
        name: 'Garden',
        templateId: 'scatter',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'chair',
            weight: 2,
            collisionMode: EnvironmentCollisionMode.forceEnabled,
          ),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        categoryId: 'furniture',
        sortOrder: 4,
      );
      final spatialPreset = EnvironmentPreset(
        id: 'sculptures',
        name: 'Sculptures',
        templateId: 'scatter',
        palette: [
          EnvironmentPaletteItem(
            modelId: 'model',
            weight: 1,
            cellOffsetWorld: Model3dVector3(x: 1, y: 2, z: 3),
            collisionMode: EnvironmentCollisionMode.forceDisabled,
          ),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        categoryId: 'furniture',
        sortOrder: 5,
      );
      final catalog = ResourcePackCatalog(
        tilesets: base.tilesets,
        elements: base.elements,
        elementCategories: base.elementCategories,
        models3d: [modelFixture()],
        environmentPresets: [preset, spatialPreset],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: base.resourceLibraryCatalog.families,
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'environmentPreset',
              resourceId: 'garden',
              familyId: 'custom-child',
            ),
          ],
        ),
        files: [
          ...base.files,
          fileBinding('glb', 'assets/models3d/model.glb', glb: true),
        ],
        provenance: base.provenance,
      );
      final restored = ResourcePackCatalog.fromJson(catalog.toJson());
      expect(restored.environmentPresets.first, preset);
      final graph = ResourcePackDependencyGraph.fromCatalog(restored);
      final root = ResourcePackRef(
        kind: ResourcePackKind.environmentPreset,
        id: 'garden',
      );
      final closure = graph.closure(
        roots: [
          root,
          ResourcePackRef(
            kind: ResourcePackKind.environmentPreset,
            id: 'sculptures',
          ),
        ],
      );
      expect(closure.resources.map((r) => r.identity), [
        'element:chair',
        'environmentPreset:garden',
        'environmentPreset:sculptures',
        'model3d:model',
        'tileset:sheet',
      ]);
      expect(closure.files, ['glb', 'image']);
      expect(
        closure.supports.map((s) => s.id),
        containsAll(['furniture', 'objects', 'custom-child', 'custom-parent']),
      );
      for (final ref in closure.nodes.where(
        (n) =>
            n.resource?.kind == ResourcePackKind.model3d ||
            n.resource?.kind == ResourcePackKind.element,
      )) {
        final broken = ResourcePackDependencyGraph(
          nodes: graph.nodes.where((n) => n.reference != ref),
        );
        expect(
          () => broken.closure(
            roots: [
              root,
              ResourcePackRef(
                kind: ResourcePackKind.environmentPreset,
                id: 'sculptures',
              ),
            ],
          ),
          throwsA(
            isA<ResourcePackDependencyException>().having(
              (e) => e.reference,
              'reference',
              ref,
            ),
          ),
        );
      }
      final raw = catalog.toJson();
      (((raw['environmentPresets'] as List).first as Map)['palette'] as List)
              .first['unexpected'] =
          null;
      expect(() => ResourcePackCatalog.fromJson(raw), throwsFormatException);
    },
  );

  test(
    'portable native integer fields reject fractional values before coercion',
    () {
      for (final key in ['x', 'y', 'width', 'height']) {
        final json = fixture().toJson();
        final frame =
            (((json['elements'] as List).first as Map)['frames'] as List).single
                as Map;
        (frame['source'] as Map)[key] = 0.5;
        expect(
          () => ResourcePackCatalog.fromJson(json),
          throwsFormatException,
          reason: key,
        );
      }
      for (final invalid in ['1', true, <String, Object?>{}, 1.5]) {
        final raw = fixture().toJson();
        final frame =
            (((raw['elements'] as List).first as Map)['frames'] as List).single
                as Map;
        frame['durationMs'] = invalid;
        expect(() => ResourcePackCatalog.fromJson(raw), throwsFormatException);
      }
      final source = const SmartTileVisualSource.model3d(
        modelId: 'model',
        scale: 1.25,
        offsetX: 0.5,
      );
      final preset = presetFixture().copyWith(
        rules: [
          SmartTileRule(
            id: 'r',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            signature: const SmartTileSignature(),
            candidates: [
              SmartTileCandidate(
                id: 'c',
                parts: [SmartTileVisualPart(source: source)],
              ),
            ],
          ),
        ],
      );
      final catalog = ResourcePackCatalog(
        models3d: [modelFixture()],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            const ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ),
          ],
          presets: [preset],
        ),
        files: [fileBinding('glb', 'assets/models3d/model.glb', glb: true)],
        provenance: fixture().provenance,
      );
      final restored = ResourcePackCatalog.fromJson(catalog.toJson());
      final restoredSource =
          restored
                  .smartTileCatalog
                  .presets
                  .single
                  .rules
                  .single
                  .candidates
                  .single
                  .parts
                  .single
                  .source
              as SmartTileModel3dSource;
      expect(restoredSource.scale, 1.25);
      expect(restoredSource.offsetX, 0.5);
      final json = fixture().toJson();
      final frame =
          (((json['elements'] as List).first as Map)['frames'] as List).single
              as Map;
      frame['durationMs'] = 100.5;
      expect(() => ResourcePackCatalog.fromJson(json), throwsFormatException);
    },
  );

  test(
    'whole catalog validation rejects orphan missing references and cycles without widening selection',
    () {
      final base = fixture();
      for (final cycle in [false, true]) {
        final catalog = ResourcePackCatalog(
          tilesets: base.tilesets,
          elements: base.elements,
          elementCategories: [
            ...base.elementCategories,
            ProjectElementCategory(
              id: 'orphan',
              name: 'Orphan',
              parentCategoryId: cycle ? 'orphan' : 'missing',
            ),
          ],
          tilesetFolders: [
            ProjectTilesetFolder(
              id: 'folder-orphan',
              name: 'Orphan',
              parentFolderId: cycle ? 'folder-orphan' : 'missing',
            ),
          ],
          files: base.files,
          provenance: base.provenance,
        );
        final graph = ResourcePackDependencyGraph.fromCatalog(catalog);
        expect(
          graph
              .closure(
                roots: [
                  ResourcePackRef(kind: ResourcePackKind.element, id: 'chair'),
                ],
              )
              .files,
          ['image'],
        );
        expect(
          () => graph.validateAll(),
          throwsA(
            isA<ResourcePackDependencyException>().having(
              (e) => e.code,
              'code',
              cycle ? 'pack.dependency_cycle' : 'pack.reference_missing',
            ),
          ),
        );
      }
      final valid = ResourcePackDependencyGraph.fromCatalog(base);
      expect(valid.validateAll().nodes, hasLength(valid.nodes.length));
    },
  );

  test('collision object identities remain scoped to each native tile', () {
    final base = fixture();
    ResourcePackCatalog withProperties({
      bool sourceReference = false,
      bool tileReference = false,
    }) {
      final source = ProjectTilesetSource.imageCollection(
        pages: [
          const ProjectImageCollectionPage(
            id: 'page',
            assetId: 'image',
            pixelWidth: 16,
            pixelHeight: 16,
          ),
        ],
        properties: [
          if (sourceReference)
            const ProjectTilesetProperty(
              name: 'ambiguous',
              type: ProjectTilesetPropertyType.objectReference,
              value: 1,
            ),
        ],
        tileDefinitions: [
          for (var id = 0; id < 2; id++)
            ProjectImageCollectionTileDefinition(
              tileId: id,
              pageId: 'page',
              sourceRect: const ProjectTilesetPixelRect(
                x: 0,
                y: 0,
                width: 16,
                height: 16,
              ),
              properties: [
                if (tileReference)
                  const ProjectTilesetProperty(
                    name: 'own',
                    type: ProjectTilesetPropertyType.objectReference,
                    value: 1,
                  ),
              ],
              collisionObjects: [
                ProjectTilesetCollisionObject(
                  id: 1,
                  x: 0,
                  y: 0,
                  width: 1,
                  height: 1,
                  properties: [
                    if (tileReference)
                      const ProjectTilesetProperty(
                        name: 'own',
                        type: ProjectTilesetPropertyType.objectReference,
                        value: 1,
                      ),
                  ],
                ),
              ],
            ),
        ],
      );
      return ResourcePackCatalog(
        tilesets: [base.tilesets.single.copyWith(source: source)],
        files: base.files,
        provenance: base.provenance,
      );
    }

    for (final tileReference in [false, true]) {
      final graph = ResourcePackDependencyGraph.fromCatalog(
        ResourcePackCatalog.fromJson(
          withProperties(tileReference: tileReference).toJson(),
        ),
      );
      expect(graph.validateAll().files, ['image']);
    }
    expect(
      () => ResourcePackDependencyGraph.fromCatalog(
        withProperties(sourceReference: true),
      ),
      throwsFormatException,
    );
  });
  test('catalog refuses unbound source paths and duplicate file paths', () {
    final base = fixture();
    expect(
      () => ResourcePackCatalog(
        tilesets: [
          base.tilesets.single.copyWith(relativePath: '/Users/private.png'),
        ],
        files: base.files,
        provenance: base.provenance,
      ),
      throwsFormatException,
    );
    expect(
      () => ResourcePackCatalog(
        files: [
          ...base.files,
          fileBinding('alias', base.files.single.logicalPath),
        ],
        provenance: base.provenance,
      ),
      throwsFormatException,
    );
  });
}

ResourcePackCatalog fixture() => ResourcePackCatalog(
  tilesets: [
    const ProjectTilesetEntry(
      id: 'sheet',
      name: 'Sheet',
      relativePath: 'assets/sheet.png',
      source: ProjectTilesetSource.regularAtlas(
        assetId: 'image',
        pixelWidth: 16,
        pixelHeight: 16,
        tileWidth: 16,
        tileHeight: 16,
      ),
    ),
  ],
  elements: [
    for (final id in ['chair', 'table'])
      ProjectElementEntry(
        id: id,
        name: id,
        tilesetId: 'sheet',
        categoryId: 'furniture',
        frames: [
          const TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
  ],
  resourceLibraryCatalog: ResourceLibraryCatalog(
    families: [
      ResourceFamily(id: 'custom-parent', name: 'Parent'),
      ResourceFamily(
        id: 'custom-child',
        name: 'Child',
        parentId: 'custom-parent',
      ),
    ],
    entries: [
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'chair',
        familyId: 'custom-child',
      ),
    ],
  ),
  elementCategories: [
    const ProjectElementCategory(
      id: 'furniture',
      name: 'Furniture',
      parentCategoryId: 'objects',
    ),
    const ProjectElementCategory(id: 'objects', name: 'Objects'),
  ],
  files: [
    ResourcePackFileBinding(
      id: 'image',
      logicalPath: 'assets/sheet.png',
      archivePath: 'blobs/${'a' * 64}.png',
      rawSha256: 'a' * 64,
      byteLength: 12,
      mediaType: 'image/png',
      provenanceId: 'author',
      licenseIds: [],
    ),
  ],
  provenance: [
    ResourcePackProvenance(
      id: 'author',
      author: 'Original',
      licenseIds: [],
      resources: [],
    ),
  ],
);

ResourcePackFileBinding fileBinding(
  String id,
  String path, {
  bool glb = false,
}) => ResourcePackFileBinding(
  id: id,
  logicalPath: path,
  archivePath: 'blobs/${'b' * 64}.${glb ? 'glb' : 'png'}',
  rawSha256: 'b' * 64,
  byteLength: 20,
  mediaType: glb ? 'model/gltf-binary' : 'image/png',
  provenanceId: 'author',
  licenseIds: [],
);
