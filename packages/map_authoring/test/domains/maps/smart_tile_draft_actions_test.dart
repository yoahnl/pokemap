import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile draft actions', () {
    test(
        'lifecycle descriptors expose exact selectors and strict input schemas',
        () {
      for (final id in [
        'smart_tile.preset.rename',
        'smart_tile.preset.duplicate'
      ]) {
        final descriptor = SmartTileCatalogActions.descriptors
            .firstWhere((item) => item.id == id);
        final schema = descriptor.extensions['inputSchema'] as Map;
        expect(schema['additionalProperties'], isFalse);
        expect(schema['oneOf'], [
          {
            'required': ['presetId']
          },
          {
            'required': ['draftId']
          }
        ]);
        expect((schema['properties'] as Map).keys,
            containsAll(['name', 'presetId', 'draftId']));
      }
    });
    test('normalized identical rename is a genuine empty change set', () {
      final fixture =
          _fixture(presets: [_publishedPreset()], publishedResources: true);
      final mutation = _build(fixture,
          actionId: 'smart_tile.preset.rename',
          parameters: {'presetId': 'grass', 'name': '  Published grass  '});
      expect(mutation.changeSet.changes, isEmpty);
    });

    test(
        'rename only a saved draft preserves its publication and other draft fields',
        () {
      final original = _completeDraft().copyWith(sourcePresetId: 'grass');
      final fixture = _fixture(
          presets: [_publishedPreset()],
          drafts: [original],
          publishedResources: true);
      final mutation = _build(fixture,
          actionId: 'smart_tile.preset.rename',
          parameters: {'draftId': original.id, 'name': 'Raccords en cours'});
      final catalog = _projectedManifest(mutation).smartTileCatalog;
      expect(catalog.presets, fixture.manifest.smartTileCatalog.presets);
      expect(
          catalog.drafts.single, original.copyWith(name: 'Raccords en cours'));
    });

    test('duplicate published preset preserves all rules and is not published',
        () {
      final preset = _publishedPreset().copyWith(
          tags: ['été'],
          seedSalt: 83,
          transformPolicy: const SmartTileTransformPolicy(allowHFlip: true));
      final fixture = _fixture(presets: [preset], publishedResources: true);
      final mutation =
          _build(fixture, actionId: 'smart_tile.preset.duplicate', parameters: {
        'presetId': preset.id,
        'newDraftId': 'draft-copy',
        'targetPresetId': 'copy',
        'name': 'Copie publiée'
      });
      final catalog = _projectedManifest(mutation).smartTileCatalog;
      final copy = catalog.drafts.single;
      expect(catalog.presets.single, preset);
      expect(copy.tags, preset.tags);
      expect(copy.transformPolicy, preset.transformPolicy);
      expect(copy.seedSalt, preset.seedSalt);
      expect(copy.atlases.single.tilesetId, _publishedAtlas.tilesetId);
      expect(copy.sourcePresetId, isNull);
      expect(mutation.preview['sourceVersion'], 'published');
    });

    test(
        'duplicate refuses a destination already published or targeted by another draft',
        () {
      final source = _completeDraft(targetPresetId: 'unpublished');
      for (final fixture in [
        _fixture(
            presets: [_publishedPreset()],
            drafts: [source],
            publishedResources: true),
        _fixture(drafts: [
          source,
          _completeDraft(id: 'other', targetPresetId: 'grass')
        ]),
      ]) {
        expect(
            () => _build(fixture,
                    actionId: 'smart_tile.preset.duplicate',
                    parameters: {
                      'draftId': source.id,
                      'newDraftId': 'new-copy',
                      'targetPresetId': 'grass',
                      'name': 'Copie'
                    }),
            throwsA(_domainCode('smart_tile.duplicate.identity_conflict')));
      }
    });

    test('lifecycle actions reject ambiguous or unexpected fields', () {
      final fixture = _fixture(drafts: [_completeDraft()]);
      for (final parameters in [
        {'draftId': 'draft-grass', 'presetId': 'grass', 'name': 'Nom'},
        {'draftId': 'draft-grass', 'name': 'Nom', 'rules': []},
        {'name': 'Nom'},
      ]) {
        expect(
            () => _build(fixture,
                actionId: 'smart_tile.preset.rename', parameters: parameters),
            throwsA(isA<MapAuthoringException>()));
      }
    });
    test('rename changes published and linked draft names without publication',
        () {
      final original = _completeDraft().copyWith(
        sourcePresetId: 'grass',
        name: 'Préparation modifiée',
        tags: ['conserver'],
      );
      final fixture = _fixture(
        presets: [_publishedPreset()],
        drafts: [original],
        publishedResources: true,
      );
      final mutation = _build(fixture,
          actionId: 'smart_tile.preset.rename',
          parameters: {'presetId': 'grass', 'name': '  Chemin fleuri  '});
      final projected = _projectedManifest(mutation).smartTileCatalog;
      expect(
          projected.presets.single,
          fixture.manifest.smartTileCatalog.presets.single
              .copyWith(name: 'Chemin fleuri'));
      expect(projected.drafts.single, original.copyWith(name: 'Chemin fleuri'));
      expect(projected.atlases, fixture.manifest.smartTileCatalog.atlases);
      expect(mutation.changeSet.changes.map((change) => change.resource.kind),
          ['project']);
    });

    test(
        'duplicate creates an independent draft and isolates editable resources',
        () {
      final original = _completeDraft().copyWith(tags: ['copie complète']);
      final fixture = _fixture(drafts: [original]);
      final mutation =
          _build(fixture, actionId: 'smart_tile.preset.duplicate', parameters: {
        'draftId': original.id,
        'newDraftId': 'draft-copy',
        'targetPresetId': 'copy',
        'name': 'Copie',
      });
      final catalog = _projectedManifest(mutation).smartTileCatalog;
      final copy =
          catalog.drafts.firstWhere((draft) => draft.id == 'draft-copy');
      expect(catalog.drafts.firstWhere((draft) => draft.id == original.id),
          original);
      expect(copy.targetPresetId, 'copy');
      expect(copy.sourcePresetId, isNull);
      expect(copy.sourceTilesetIds, original.sourceTilesetIds);
      expect(copy.tags, original.tags);
      expect(copy.rules.single.candidates.single.weight,
          original.rules.single.candidates.single.weight);
      expect(copy.atlases.single.id, isNot(original.atlases.single.id));
      expect(copy.atlases.single.tilesetId, original.atlases.single.tilesetId);
      expect(copy.materials.single.id, isNot(original.materials.single.id));
      expect(copy.primaryAtlasId, copy.atlases.single.id);
      expect(copy.defaultMaterialId, copy.materials.single.id);
      final source = copy.rules.single.candidates.single.parts.single.source
          as SmartTileFrameSource;
      expect(source.frame.atlasId, copy.atlases.single.id);
      expect(catalog.presets, isEmpty);
    });

    test('duplicate refuses an existing draft identity instead of upserting it',
        () {
      final original = _completeDraft();
      final fixture = _fixture(drafts: [original]);
      expect(
          () => _build(fixture,
                  actionId: 'smart_tile.preset.duplicate',
                  parameters: {
                    'draftId': original.id,
                    'newDraftId': original.id,
                    'targetPresetId': 'copy',
                    'name': 'Copie'
                  }),
          throwsA(_domainCode('smart_tile.duplicate.identity_conflict')));
    });

    test('duplicate isolates dependencies inherited by a saved draft', () {
      final original = ProjectSmartTileAuthoringDraft.fromJson({
        ..._publishedPreset().toJson()..remove('status'),
        'id': 'inherited',
        'targetPresetId': 'original-draft',
        'lastStage': 'connections',
        'sourceTilesetIds': ['tileset'],
        'primaryAtlasId': 'published-atlas',
      });
      final fixture = _fixture(
          drafts: [original],
          presets: [_publishedPreset()],
          publishedResources: true);
      final mutation =
          _build(fixture, actionId: 'smart_tile.preset.duplicate', parameters: {
        'draftId': original.id,
        'newDraftId': 'copy-draft',
        'targetPresetId': 'copy',
        'name': 'Copie'
      });
      final projected = _projectedManifest(mutation);
      final copy = projected.smartTileCatalog.drafts.last;
      expect(copy.atlases.single.id, isNot('published-atlas'));
      expect(copy.materials.single.id, isNot('published-grass'));
      expect(copy.primaryAtlasId, copy.atlases.single.id);
      expect(copy.defaultMaterialId, copy.materials.single.id);
      expect(projected.smartTileCatalog.drafts.first, original);
      expect(
          compileSmartTileAuthoringDraft(
              draft: copy,
              catalog: projected.smartTileCatalog,
              manifest: projected),
          isA<SmartTileDraftCompilationSuccess>());
    });

    test('published and saved animated copies preserve exact animation data',
        () {
      const animation =
          ProjectSmartTileAnimation(id: 'wind', name: 'Vent', frames: [
        ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
                atlasId: 'published-atlas', column: 0, row: 0),
            durationMs: 173)
      ]);
      final original = _publishedPreset();
      final candidate = original.rules.single.candidates.single
          .copyWith(label: 'Vent d’été', weight: 7, parts: [
        const SmartTileVisualPart(
            source: SmartTileVisualSource.animation(animationId: 'wind'))
      ]);
      final preset = original.copyWith(rules: [
        original.rules.single.copyWith(candidates: [candidate]),
        original.rules.single.copyWith(id: 'fallback', candidates: [candidate])
      ], fallbackRuleId: 'fallback', seedSalt: 12);
      final saved = ProjectSmartTileAuthoringDraft.fromJson({
        ...preset.toJson()..remove('status'),
        'id': 'saved',
        'lastStage': 'connections',
        'targetPresetId': 'saved-target',
        'primaryAtlasId': 'published-atlas',
        'sourceTilesetIds': ['tileset']
      });
      final fixture = _fixture(
          presets: [preset],
          drafts: [saved],
          animations: [animation],
          publishedResources: true);
      for (final selector in [
        {'presetId': preset.id},
        {'draftId': saved.id}
      ]) {
        final mutation = _build(fixture,
            actionId: 'smart_tile.preset.duplicate',
            parameters: {
              ...selector,
              'newDraftId': 'copy-draft',
              'targetPresetId': 'copy',
              'name': 'Copie'
            });
        final catalog = _projectedManifest(mutation).smartTileCatalog;
        final copy = catalog.drafts.last;
        final copiedAnimation = copy.animations.single;
        expect(copiedAnimation.id, isNot(animation.id));
        expect(
            copiedAnimation,
            animation.copyWith(id: copiedAnimation.id, frames: [
              animation.frames.single.copyWith(
                  frame: animation.frames.single.frame
                      .copyWith(atlasId: copy.atlases.single.id))
            ]));
        final copiedCandidate = copy.rules.first.candidates.single;
        expect(copiedCandidate.label, candidate.label);
        expect(copiedCandidate.weight, candidate.weight);
        expect(
            (copiedCandidate.parts.single.source as SmartTileAnimationSource)
                .animationId,
            copiedAnimation.id);
        expect(copy.fallbackRuleId, preset.fallbackRuleId);
        expect(copy.seedSalt, preset.seedSalt);
        expect(catalog.animations.single, animation);
        expect(catalog.presets.single, preset);
      }
    });

    test('preset deletion refuses a retained authoring draft dependency', () {
      final original = _completeDraft().copyWith(sourcePresetId: 'grass');
      final fixture = _fixture(
          presets: [_publishedPreset()],
          drafts: [original],
          publishedResources: true);
      expect(
          () => _build(fixture,
              actionId: 'smart_tile.preset.delete',
              parameters: {'presetId': 'grass'}),
          throwsA(_domainCode('smart_tile.preset.references_blocking')));
    });
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
      final persistedDraft =
          _projectedManifest(upsert).smartTileCatalog.drafts.single;
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
  List<ProjectSmartTileAnimation> animations = const [],
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
    version: ProjectVersion.v8,
    size: GridSize(width: 1, height: 1),
  );
  final manifest = ProjectManifest(
    name: 'Smart Tile drafts',
    version: ProjectVersion.v8,
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
      animations: animations,
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
