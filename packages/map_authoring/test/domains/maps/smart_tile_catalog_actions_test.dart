import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileCatalogActions', () {
    test('advertises the six canonical catalog mutations', () {
      expect(
        SmartTileCatalogActions.descriptors.map((item) => item.id),
        <String>[
          'smart_tile.animation.delete',
          'smart_tile.animation.upsert',
          'smart_tile.atlas.upsert',
          'smart_tile.material.upsert',
          'smart_tile.preset.delete',
          'smart_tile.preset.publish',
        ],
      );
      for (final descriptor in SmartTileCatalogActions.descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
    });

    test('rejects atlas geometry outside the decoded source image', () {
      final fixture = _fixture();

      expect(
        () => const SmartTileCatalogActions().build(
          _context(
            fixture,
            actionId: 'smart_tile.atlas.upsert',
            parameters: {
              'atlas': _atlas(columns: 2).toJson(),
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile.atlas.out_of_image',
              )
              .having(
                (error) => error.details['imageWidth'],
                'imageWidth',
                1,
              ),
        ),
      );
    });

    test('publishes a complete preset and creates its layer atomically', () {
      final fixture = _fixture();
      final preset = _preset();

      final draft = const SmartTileCatalogActions().build(
        _context(
          fixture,
          actionId: 'smart_tile.preset.publish',
          parameters: {
            'preset': preset.toJson(),
            'layer': const {
              'mapId': 'map',
              'layerId': 'terrain',
              'name': 'Terrain',
            },
          },
        ),
      );

      expect(
        draft.changeSet.changes.map((change) => change.resource.kind),
        <String>['map', 'project'],
      );
      final projectedManifest = ProjectManifest.fromJson(
        jsonDecode(
          utf8.decode(
            draft.changeSet.changes
                .singleWhere((change) => change.resource.kind == 'project')
                .afterBytes!,
          ),
        ) as Map<String, dynamic>,
      );
      final projectedMap = MapData.fromJson(
        jsonDecode(
          utf8.decode(
            draft.changeSet.changes
                .singleWhere((change) => change.resource.kind == 'map')
                .afterBytes!,
          ),
        ) as Map<String, dynamic>,
      );
      expect(
        projectedManifest.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.published,
      );
      expect(projectedMap.layers.single, isA<SmartTileLayer>());
      expect((projectedMap.layers.single as SmartTileLayer).presetId, 'grass');
    });

    test('creates a layer without rewriting an already published preset', () {
      final preset = _preset().copyWith(
        status: SmartTilePresetStatus.published,
      );
      final fixture = _fixture(preset: preset);

      final draft = const SmartTileCatalogActions().build(
        _context(
          fixture,
          actionId: 'smart_tile.preset.publish',
          parameters: {
            'preset': preset.toJson(),
            'layer': const {
              'mapId': 'map',
              'layerId': 'terrain',
              'name': 'Terrain',
            },
          },
        ),
      );

      expect(
        draft.changeSet.changes.map((change) => change.resource.kind),
        <String>['map'],
      );
      expect(draft.preview['manifestChanged'], isFalse);
    });

    test('upserts a material through one validated manifest change', () {
      final fixture = _fixture(
        map: const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
        ),
      );
      const material = ProjectSmartTileMaterial(
        id: 'dirt',
        name: 'Dirt',
        connectionGroupId: 'ground',
        terrainType: TerrainType.dirt,
      );

      final draft = const SmartTileCatalogActions().build(
        _context(
          fixture,
          actionId: 'smart_tile.material.upsert',
          parameters: <String, Object?>{'material': material.toJson()},
        ),
      );

      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.changes.single.resource.kind, 'project');
      expect(
        draft.changeSet.diff.entries.single.path,
        '/smartTileCatalog/materials/dirt',
      );
    });

    test('refuses to delete an animation referenced by a preset', () {
      final preset = _preset().copyWith(
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'animated',
            centerMatch: SmartTileSlotMatch.material('grass'),
            signature: SmartTileSignature(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'animated',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'wind',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final fixture = _fixture(
        preset: preset,
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'wind',
            name: 'Wind',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
          ),
        ],
      );

      expect(
        () => const SmartTileCatalogActions().build(
          _context(
            fixture,
            actionId: 'smart_tile.animation.delete',
            parameters: const <String, Object?>{'animationId': 'wind'},
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.animation.references_blocking',
          ),
        ),
      );
    });

    test('refuses to delete a preset referenced by an active layer', () {
      final preset = _preset().copyWith(
        status: SmartTilePresetStatus.published,
      );
      final fixture = _fixture(
        preset: preset,
        map: const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            MapLayer.smartTile(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              materialPalette: <String>['', 'grass'],
              field: SmartTileField.cell(semanticCells: <int>[1]),
            ),
          ],
        ),
      );

      expect(
        () => const SmartTileCatalogActions().build(
          _context(
            fixture,
            actionId: 'smart_tile.preset.delete',
            parameters: const <String, Object?>{'presetId': 'grass'},
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.preset.references_blocking',
          ),
        ),
      );
    });

    test('all catalog mutations fail closed while any project map is legacy',
        () {
      final fixture = _fixture(
        map: const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v4,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            MapLayer.terrain(
              id: 'legacy',
              name: 'Legacy',
              terrains: <TerrainType>[TerrainType.grass],
            ),
          ],
        ),
        preset: _preset(),
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'wind',
            name: 'Wind',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
          ),
        ],
      );
      final requests = <({String actionId, Map<String, Object?> parameters})>[
        (
          actionId: 'smart_tile.atlas.upsert',
          parameters: <String, Object?>{'atlas': _atlas().toJson()},
        ),
        (
          actionId: 'smart_tile.material.upsert',
          parameters: <String, Object?>{'material': _material().toJson()},
        ),
        (
          actionId: 'smart_tile.animation.upsert',
          parameters: <String, Object?>{
            'animation': const ProjectSmartTileAnimation(
              id: 'wind',
              name: 'Wind',
              frames: <ProjectSmartTileAnimationFrame>[
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 120,
                ),
              ],
            ).toJson(),
          },
        ),
        (
          actionId: 'smart_tile.animation.delete',
          parameters: const <String, Object?>{'animationId': 'wind'},
        ),
        (
          actionId: 'smart_tile.preset.publish',
          parameters: <String, Object?>{'preset': _preset().toJson()},
        ),
        (
          actionId: 'smart_tile.preset.delete',
          parameters: const <String, Object?>{'presetId': 'grass'},
        ),
      ];

      for (final request in requests) {
        expect(
          () => const SmartTileCatalogActions().build(
            _context(
              fixture,
              actionId: request.actionId,
              parameters: request.parameters,
            ),
          ),
          throwsA(
            isA<MapAuthoringException>().having(
              (error) => error.code,
              'code',
              'smart_tile_legacy_project_unsupported',
            ),
          ),
          reason: request.actionId,
        );
      }
    });
  });
}

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) _fixture({
  MapData map = const MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v4,
    size: GridSize(width: 1, height: 1),
  ),
  ProjectSmartTilePreset? preset,
  List<ProjectSmartTileAnimation> animations = const [],
}) {
  final artifact = ContentArtifactRef.fromBytes(
    _pngBytes,
    mediaType: 'image/png',
  );
  final assetCatalog = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'tileset-image',
        logicalPath: 'assets/tileset.png',
        artifact: artifact,
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Smart Tile authoring fixture',
    version: ProjectVersion.v5,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[_atlas()],
      materials: <ProjectSmartTileMaterial>[_material()],
      animations: animations,
      presets: <ProjectSmartTilePreset>[
        if (preset != null) preset,
      ],
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final catalogBytes = _encode(assetCatalog.toJson());
  final resources = <String, List<int>>{
    'project': projectBytes,
    'map:map': mapBytes,
    assetCatalogResourceIdentity: catalogBytes,
    assetBlobResourceIdentity(artifact.digest): _pngBytes,
  };
  final storageKeys = <String, String>{
    'project': 'project.json',
    'map:map': 'maps/map.json',
    assetCatalogResourceIdentity: assetCatalogStorageKey,
    assetBlobResourceIdentity(artifact.digest): assetBlobStorageKey(artifact),
  };
  final fingerprints = <String, String>{
    for (final entry in resources.entries)
      entry.key: computeAuthoringBytesFingerprint(
        entry.value,
        logicalName: storageKeys[entry.key]!,
      ),
  };
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project_smart_tiles'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('smart-tile-snapshot'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: <MapData>[map],
      resourceFingerprints: fingerprints,
      resourceBytes: resources,
      resourceStorageKeys: storageKeys,
    ),
  );
}

AuthoringPlanningContext _context(
  ({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) fixture, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: fixture.snapshot,
      request: AuthoringRequest(
        requestId: 'request',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace:smart-tiles',
        parameters: parameters,
        expectedRevision: fixture.snapshot.revision,
        idempotencyKey: 'idempotency-$actionId',
      ),
      planId: 'plan-smart-tiles',
      seed: 7,
    );

ProjectSmartTileAtlas _atlas({int columns = 1}) => ProjectSmartTileAtlas(
      id: 'atlas',
      name: 'Atlas',
      tilesetId: 'tileset',
      cellWidth: 1,
      cellHeight: 1,
      columns: columns,
      rows: 1,
    );

ProjectSmartTileMaterial _material() => const ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Grass',
      connectionGroupId: 'ground',
      terrainType: TerrainType.grass,
    );

ProjectSmartTilePreset _preset() => ProjectSmartTilePreset(
      id: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: const <String>['grass'],
      rules: const <SmartTileRule>[
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('grass'),
          signature: SmartTileSignature(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'base',
              parts: <SmartTileVisualPart>[
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

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
