import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile draft actions', () {
    test('registers durable draft upsert and delete descriptors', () {
      expect(
        SmartTileCatalogActions.descriptors.map((item) => item.id),
        containsAll(<String>[
          'smart_tile.preset.draft.upsert',
          'smart_tile.preset.draft.delete',
        ]),
      );
    });

    test('upsert preserves every published list and other drafts', () {
      final other = _completeDraft(
        id: 'other-draft',
        targetPresetId: 'other-target',
      );
      final fixture = _fixture(drafts: <ProjectSmartTileAuthoringDraft>[other]);
      final incoming = _completeDraft();

      final mutation = _build(
        fixture,
        actionId: 'smart_tile.preset.draft.upsert',
        parameters: <String, Object?>{'draft': incoming.toJson()},
      );
      final projected = _projectedManifest(mutation);

      expect(projected.smartTileCatalog.categories,
          fixture.manifest.smartTileCatalog.categories);
      expect(projected.smartTileCatalog.atlases,
          fixture.manifest.smartTileCatalog.atlases);
      expect(projected.smartTileCatalog.materials,
          fixture.manifest.smartTileCatalog.materials);
      expect(projected.smartTileCatalog.animations,
          fixture.manifest.smartTileCatalog.animations);
      expect(projected.smartTileCatalog.presets,
          fixture.manifest.smartTileCatalog.presets);
      expect(
        projected.smartTileCatalog.drafts.map((item) => item.id),
        <String>['draft-grass', 'other-draft'],
      );
    });

    test('upsert replaces by draft id and rejects an exact no-op', () {
      final original = _completeDraft(name: 'Before');
      final fixture =
          _fixture(drafts: <ProjectSmartTileAuthoringDraft>[original]);
      final replacement = original.copyWith(name: 'After');

      final mutation = _build(
        fixture,
        actionId: 'smart_tile.preset.draft.upsert',
        parameters: <String, Object?>{'draft': replacement.toJson()},
      );

      expect(_projectedManifest(mutation).smartTileCatalog.drafts.single.name,
          'After');
      expect(
        () => _build(
          fixture,
          actionId: 'smart_tile.preset.draft.upsert',
          parameters: <String, Object?>{'draft': original.toJson()},
        ),
        throwsA(_domainCode('smart_tile.no_change')),
      );
    });

    test('delete removes only the requested draft and unknown ids fail', () {
      final first = _completeDraft();
      final second = _completeDraft(
        id: 'other-draft',
        targetPresetId: 'other-target',
      );
      final fixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[first, second],
      );

      final mutation = _build(
        fixture,
        actionId: 'smart_tile.preset.draft.delete',
        parameters: const <String, Object?>{'draftId': 'draft-grass'},
      );

      expect(
        _projectedManifest(mutation).smartTileCatalog.drafts,
        <ProjectSmartTileAuthoringDraft>[second],
      );
      expect(
        () => _build(
          fixture,
          actionId: 'smart_tile.preset.draft.delete',
          parameters: const <String, Object?>{'draftId': 'missing'},
        ),
        throwsA(_domainCode('smart_tile.draft.unknown')),
      );
    });

    test('publication promotes resources and removes the draft atomically', () {
      final fixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[_completeDraft()],
      );

      final mutation = _build(
        fixture,
        actionId: 'smart_tile.preset.publish',
        parameters: const <String, Object?>{'draftId': 'draft-grass'},
      );
      final projected = _projectedManifest(mutation);

      expect(mutation.changeSet.changes.map((item) => item.resource.kind),
          <String>['project']);
      expect(projected.smartTileCatalog.drafts, isEmpty);
      expect(projected.smartTileCatalog.presets.single.status,
          SmartTilePresetStatus.published);
      expect(projected.smartTileCatalog.atlases.single.id, 'draft-atlas');
      expect(projected.smartTileCatalog.materials.single.id, 'draft-grass');
    });

    test('actor occlusion survives canonical draft upsert and publication', () {
      final base = _completeDraft();
      final candidate = base.rules.single.candidates.single;
      final draft = base.copyWith(
        usage: SmartTileUsage.path,
        rules: <SmartTileRule>[
          base.rules.single.copyWith(
            candidates: <SmartTileCandidate>[
              candidate.copyWith(
                parts: <SmartTileVisualPart>[
                  ...candidate.parts,
                  const SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'draft-atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                    channel: SmartTileRenderChannel.actorOcclusion,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final initial = _fixture();
      final upsert = _build(
        initial,
        actionId: 'smart_tile.preset.draft.upsert',
        parameters: <String, Object?>{'draft': draft.toJson()},
      );
      final persistedDraft = _projectedManifest(upsert)
          .smartTileCatalog
          .drafts
          .single;
      final publishFixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[persistedDraft],
      );
      final publish = _build(
        publishFixture,
        actionId: 'smart_tile.preset.publish',
        parameters: const <String, Object?>{'draftId': 'draft-grass'},
      );

      expect(
        persistedDraft.rules.single.candidates.single.parts.last.channel,
        SmartTileRenderChannel.actorOcclusion,
      );
      expect(
        _projectedManifest(publish)
            .smartTileCatalog
            .presets
            .single
            .rules
            .single
            .candidates
            .single
            .parts
            .last
            .channel,
        SmartTileRenderChannel.actorOcclusion,
      );
    });

    test('publication can create a layer in the same change set', () {
      final fixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[_completeDraft()],
      );

      final mutation = _build(
        fixture,
        actionId: 'smart_tile.preset.publish',
        parameters: const <String, Object?>{
          'draftId': 'draft-grass',
          'layer': <String, Object?>{
            'mapId': 'map',
            'layerId': 'terrain',
            'name': 'Terrain',
          },
        },
      );

      expect(
        mutation.changeSet.changes.map((item) => item.resource.kind),
        <String>['map', 'project'],
      );
      expect(_projectedManifest(mutation).smartTileCatalog.drafts, isEmpty);
      expect(_projectedMap(mutation).layers.single, isA<SmartTileLayer>());
    });

    test('invalid optional layer leaves project and map preimages untouched',
        () {
      final fixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[_completeDraft()],
      );
      final projectBefore = fixture.snapshot.resourceBytes('project');
      final mapBefore = fixture.snapshot.resourceBytes('map:map');

      expect(
        () => _build(
          fixture,
          actionId: 'smart_tile.preset.publish',
          parameters: const <String, Object?>{
            'draftId': 'draft-grass',
            'layer': <String, Object?>{
              'mapId': 'missing-map',
              'layerId': 'terrain',
              'name': 'Terrain',
            },
          },
        ),
        throwsA(_domainCode('smart_tile_target_map_missing')),
      );
      expect(fixture.snapshot.resourceBytes('project'), projectBefore);
      expect(fixture.snapshot.resourceBytes('map:map'), mapBefore);
    });

    test('published target requires an explicit isolated edit source', () {
      final fixture = _fixture(
        presets: <ProjectSmartTilePreset>[_publishedPreset()],
        drafts: <ProjectSmartTileAuthoringDraft>[_completeDraft()],
      );

      expect(
        () => _build(
          fixture,
          actionId: 'smart_tile.preset.publish',
          parameters: const <String, Object?>{'draftId': 'draft-grass'},
        ),
        throwsA(_domainCode('smart_tile.draft.target_conflict')),
      );
    });

    test('changed dependencies shared by another preset fail closed', () {
      final shared = _completeDraft().copyWith(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'published-atlas',
            name: 'Changed atlas',
            tilesetId: 'tileset',
            cellWidth: 1,
            cellHeight: 1,
            columns: 1,
            rows: 1,
          ),
        ],
        primaryAtlasId: 'published-atlas',
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'published-grass',
            name: 'Changed grass',
            connectionGroupId: 'ground',
          ),
        ],
        defaultMaterialId: 'published-grass',
        allowedMaterialIds: const <String>['published-grass'],
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'base',
            centerMatch: SmartTileSlotMatch.material('published-grass'),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'base',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'published-atlas',
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
      final fixture = _fixture(
        publishedResources: true,
        presets: <ProjectSmartTilePreset>[
          _publishedPreset(id: 'other-target'),
        ],
        drafts: <ProjectSmartTileAuthoringDraft>[shared],
      );

      expect(
        () => _build(
          fixture,
          actionId: 'smart_tile.preset.publish',
          parameters: const <String, Object?>{'draftId': 'draft-grass'},
        ),
        throwsA(_domainCode('smart_tile.draft.shared_dependency_conflict')),
      );
    });

    test('publish accepts exactly one of draftId and preset', () {
      final fixture = _fixture(
        drafts: <ProjectSmartTileAuthoringDraft>[_completeDraft()],
      );

      for (final parameters in <Map<String, Object?>>[
        const <String, Object?>{},
        <String, Object?>{
          'draftId': 'draft-grass',
          'preset': _publishedPreset().toJson(),
        },
      ]) {
        expect(
          () => _build(
            fixture,
            actionId: 'smart_tile.preset.publish',
            parameters: parameters,
          ),
          throwsA(_domainCode('smart_tile.request_invalid')),
        );
      }
    });
  });
}

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) _fixture({
  List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[],
  List<ProjectSmartTileAuthoringDraft> drafts =
      const <ProjectSmartTileAuthoringDraft>[],
  bool publishedResources = false,
}) {
  final artifact = ContentArtifactRef.fromBytes(
    _pngBytes,
    mediaType: 'image/png',
  );
  final assets = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'tileset-image',
        logicalPath: 'assets/tileset.png',
        artifact: artifact,
      ),
    ],
  );
  const map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
  );
  final manifest = ProjectManifest(
    name: 'Smart Tile drafts',
    version: ProjectVersion.v6,
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
      categories: const <ProjectSmartTileCategory>[
        ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
      ],
      atlases: <ProjectSmartTileAtlas>[
        if (publishedResources) _publishedAtlas,
      ],
      materials: <ProjectSmartTileMaterial>[
        if (publishedResources) _publishedMaterial,
      ],
      presets: presets,
      drafts: drafts,
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final assetBytes = _encode(assets.toJson());
  final resources = <String, List<int>>{
    'project': projectBytes,
    'map:map': mapBytes,
    assetCatalogResourceIdentity: assetBytes,
    assetBlobResourceIdentity(artifact.digest): _pngBytes,
  };
  final storageKeys = <String, String>{
    'project': 'project.json',
    'map:map': 'maps/map.json',
    assetCatalogResourceIdentity: assetCatalogStorageKey,
    assetBlobResourceIdentity(artifact.digest): assetBlobStorageKey(artifact),
  };
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('smart_tile_drafts'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('smart-tile-draft-snapshot'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: const <MapData>[map],
      resourceFingerprints: <String, String>{
        for (final entry in resources.entries)
          entry.key: computeAuthoringBytesFingerprint(
            entry.value,
            logicalName: storageKeys[entry.key]!,
          ),
      },
      resourceBytes: resources,
      resourceStorageKeys: storageKeys,
    ),
  );
}

ProjectSmartTileAuthoringDraft _completeDraft({
  String id = 'draft-grass',
  String targetPresetId = 'grass',
  String name = 'Grass',
}) {
  return ProjectSmartTileAuthoringDraft(
    id: id,
    targetPresetId: targetPresetId,
    name: name,
    categoryId: 'nature',
    usage: SmartTileUsage.terrain,
    lastStage: SmartTileAuthoringStage.publish,
    sourceTilesetIds: const <String>['tileset'],
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'draft-atlas',
        name: 'Draft atlas',
        tilesetId: 'tileset',
        cellWidth: 1,
        cellHeight: 1,
        columns: 1,
        rows: 1,
      ),
    ],
    primaryAtlasId: 'draft-atlas',
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'draft-grass',
        name: 'Draft grass',
        connectionGroupId: 'ground',
      ),
    ],
    defaultMaterialId: 'draft-grass',
    allowedMaterialIds: const <String>['draft-grass'],
    rules: const <SmartTileRule>[
      SmartTileRule(
        id: 'base',
        centerMatch: SmartTileSlotMatch.material('draft-grass'),
        candidates: <SmartTileCandidate>[
          SmartTileCandidate(
            id: 'base',
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'draft-atlas',
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
}

const _publishedAtlas = ProjectSmartTileAtlas(
  id: 'published-atlas',
  name: 'Published atlas',
  tilesetId: 'tileset',
  cellWidth: 1,
  cellHeight: 1,
  columns: 1,
  rows: 1,
);

const _publishedMaterial = ProjectSmartTileMaterial(
  id: 'published-grass',
  name: 'Published grass',
  connectionGroupId: 'ground',
);

ProjectSmartTilePreset _publishedPreset({String id = 'grass'}) =>
    ProjectSmartTilePreset(
      id: id,
      name: 'Published grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'published-grass',
      allowedMaterialIds: const <String>['published-grass'],
      rules: const <SmartTileRule>[
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('published-grass'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'base',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'published-atlas',
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

AuthoringMutationDraft _build(
  ({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) fixture, {
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return const SmartTileCatalogActions().build(
    AuthoringPlanningContext(
      snapshot: fixture.snapshot,
      request: AuthoringRequest(
        requestId: 'request',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace:smart-tiles',
        parameters: parameters,
        expectedRevision: fixture.snapshot.revision,
        idempotencyKey: 'idempotency',
      ),
      planId: 'plan',
      seed: 7,
    ),
  );
}

ProjectManifest _projectedManifest(AuthoringMutationDraft mutation) {
  final bytes = mutation.changeSet.changes
      .singleWhere((item) => item.resource.kind == 'project')
      .afterBytes!;
  return ProjectManifest.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
}

MapData _projectedMap(AuthoringMutationDraft mutation) {
  final bytes = mutation.changeSet.changes
      .singleWhere((item) => item.resource.kind == 'map')
      .afterBytes!;
  return MapData.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
}

Matcher _domainCode(String code) => isA<MapAuthoringException>().having(
      (error) => error.code,
      'code',
      code,
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
