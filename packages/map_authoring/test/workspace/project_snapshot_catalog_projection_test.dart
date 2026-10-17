import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_metadata_fixture.dart';

void main() {
  for (final field in ['scenes', 'worldRules', 'eventRegistry']) {
    test('$field post-image adopts the complete snapshot with cold parity',
        () async {
      final f = await MapMetadataFixture.create();
      addTearDown(f.dispose);
      final seeded = (await f.manifest()).copyWith(
        facts: [NarrativeFactDefinition(id: 'fact_known', label: 'Known')],
        scenes: [_projectionScene('Before')],
      );
      final map = (await f.map()).copyWith(entities: [
        const MapEntity(
            id: 'owner',
            kind: MapEntityKind.custom,
            name: 'Owner',
            pos: GridPos(x: 1, y: 1)),
      ]);
      await File('${f.root.path}/documents/unusual.json')
          .writeAsBytes(encodeMapAuthoringDocument(map));
      await File('${f.root.path}/project.json')
          .writeAsString(jsonEncode(seeded.toJson()));
      final assetBytes = List<int>.generate(1024, (index) => index % 256);
      final artifact = ContentArtifactRef.fromBytes(assetBytes,
          mediaType: 'application/octet-stream');
      await Directory('${f.root.path}/assets/.pokemap-store')
          .create(recursive: true);
      await File('${f.root.path}/assets/source.bin').writeAsBytes(assetBytes);
      await File('${f.root.path}/${assetBlobStorageKey(artifact)}')
          .writeAsBytes(assetBytes);
      await File('${f.root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: 'source', logicalPath: 'assets/source.bin', artifact: artifact),
      ]).toJson()));
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [f.root.path], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(f.root.path);
      addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
      final cache = ProjectSnapshotCache();
      final profiles = <ProjectSnapshotLoadProfile>[];
      final snapshots = ProjectSnapshotLoader(
          handles: handles, snapshotCache: cache, profileSink: profiles.add);
      final before = await snapshots.load(opened.projectHandle);
      final manifest = switch (field) {
        'scenes' =>
          before.manifest.copyWith(scenes: [_projectionScene('After')]),
        'worldRules' => before.manifest.copyWith(worldRules: [
            WorldRuleDefinition(
              id: 'rule',
              label: 'Hide owner',
              source: const WorldRuleSource(
                  kind: WorldRuleSourceKind.fact,
                  sourceId: 'fact_known',
                  predicate: WorldRuleSourcePredicate.isTrue),
              target: const WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: 'town',
                  entityId: 'owner'),
              effect:
                  const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
            )
          ]),
        _ => before.manifest.copyWith(
              eventRegistry: NarrativeEventRegistry(
                  schemaVersion: 1,
                  mode: EventSystemMode.v2Only,
                  records: [
                NarrativeEventRecord.fromJson({
                  'state': 'configured',
                  'enabled': false,
                  'definition': {
                    'id': 'evt_019abcde-0000-7000-8000-000000000001',
                    'name': 'Entry',
                    'source': {'kind': 'mapEnter', 'mapId': 'town'},
                    'conditions': <Object?>[],
                    'sceneId': 'scene',
                    'reusePolicy': 'reusable',
                    'priority': 0,
                    'order': 0
                  },
                })
              ],
                  legacyClaims: const [])),
      };
      ProjectValidator.validate(manifest, maps: before.maps);
      final edit = change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest));
      await File('${f.root.path}/project.json').writeAsBytes(edit.afterBytes!);
      final adopted = await snapshots.adoptAppliedChanges(opened.projectHandle,
          baseRevision: before.revision, changes: [edit]);
      expect(adopted, isNotNull);
      expect(cache.adoptions, 1);
      expect(identical(adopted!.maps.single, before.maps.single), isTrue);
      expect(
          identical(adopted.storedResources['assetBlob:${artifact.digest}'],
              before.storedResources['assetBlob:${artifact.digest}']),
          isTrue);
      final cached = await snapshots.load(opened.projectHandle);
      expect(profiles.last.cacheHit, isTrue);
      expect(profiles.last.assetBlobVerifications, 0);
      final cold = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(adopted.manifest, cold.manifest);
      expect(adopted.revision, cold.revision);
      expect(cached.revision, cold.revision);
      expect(adopted.resourceFingerprints, cold.resourceFingerprints);
      expect(adopted.resourceStorageKeys, cold.resourceStorageKeys);
      expect(adopted.maps, cold.maps);
      for (final identity in cold.resourceStorageKeys.keys) {
        expect(await adopted.readResourceBytes(identity),
            await cold.readResourceBytes(identity));
      }
    });
  }

  test('new narrative item references retain strict missing-catalog rejection',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    expect(before.itemCatalog, isNull);
    final manifest = before.manifest.copyWith(scenes: [_itemProjectionScene()]);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, manifest));
    await File('${f.root.path}/project.json').writeAsBytes(edit.afterBytes!);
    await expectLater(
        f.snapshots.load(f.opened.projectHandle),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.item_catalog_missing')));
    expect(const ProjectSnapshotMapProjector().project(before, [edit]), isNull);
  });

  test('scene removal retains strict spatial map-reference rejection',
      () async {
    final f =
        await MapMetadataFixture.create(dimension: ProjectDimension.threeD);
    addTearDown(f.dispose);
    final manifest =
        (await f.manifest()).copyWith(scenes: [_projectionScene('Before')]);
    final map = (await f.map()).copyWith(
      layers: [
        MapLayer.collision(
            id: 'base', name: 'Base', collisions: List<bool>.filled(20, false))
      ],
      events: [
        MapEventDefinition(
            id: 'event',
            title: 'Entry',
            position: const EventPosition(layerId: 'base', x: 1, y: 1),
            pages: const [
              MapEventPage(
                  pageNumber: 0,
                  sceneTarget: MapEventSceneTarget(sceneId: 'scene'))
            ])
      ],
    );
    await File('${f.root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    await File('${f.root.path}/documents/unusual.json')
        .writeAsBytes(encodeMapAuthoringDocument(map));
    final before = await f.snapshots.load(f.opened.projectHandle);
    final edited = manifest.copyWith(scenes: []);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, edited));
    await File('${f.root.path}/project.json').writeAsBytes(edit.afterBytes!);
    await expectLater(
        f.snapshots.load(f.opened.projectHandle),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.spatial_map_invalid')));
    expect(const ProjectSnapshotMapProjector().project(before, [edit]), isNull);
  });

  test('narrative edits cannot hide resource discovery changes', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final narrative =
        before.manifest.copyWith(scenes: [_projectionScene('After')]);
    for (final manifest in [
      narrative.copyWith(dialogues: const [
        ProjectDialogueEntry(
            id: 'new', name: 'New', relativePath: 'dialogues/new.yarn')
      ]),
      narrative.copyWith(
          pokemon:
              narrative.pokemon.copyWith(speciesDir: 'data/other-species')),
      narrative.copyWith(
          pokemon: narrative.pokemon.copyWith(catalogFiles: {
        ...narrative.pokemon.catalogFiles,
        'items': 'data/other-items.json'
      })),
      narrative.copyWith(maps: [
        narrative.maps.single.copyWith(relativePath: 'documents/other.json')
      ]),
    ]) {
      expect(
          const ProjectSnapshotMapProjector().project(before, [
            change(before, 'project',
                encodeProjectAuthoringDocument(before, manifest)),
          ]),
          isNull);
    }
  });

  test('folder and title post-images retain the complete cached snapshot',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ], maps: [
      before.manifest.maps.single
          .copyWith(groupId: 'folder', name: 'Village été')
    ]);
    final map = before.maps.single.copyWith(name: 'Village été');
    final changes = [
      change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest)),
      change(before, 'map:town', encodeMapAuthoringDocument(map)),
    ];
    final projected =
        const ProjectSnapshotMapProjector().project(before, changes);
    expect(projected, isNotNull);
    expect(projected!.manifest, manifest);
    expect(projected.mapById('town'), map);
    expect(projected.resourceStorageKeys, before.resourceStorageKeys);
    expect(projected.pokemonInventoryComplete, before.pokemonInventoryComplete);
    for (final edit in changes) {
      await File('${f.root.path}/${edit.storageKey}')
          .writeAsBytes(edit.afterBytes!);
    }
    final reread = await f.snapshots.load(f.opened.projectHandle);
    expect(projected.revision, reread.revision);
    expect(projected.resourceFingerprints, reread.resourceFingerprints);
    expect(projected.manifest, reread.manifest);
  });

  test('folder-only post-image reuses unchanged map objects and bytes',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ]);
    final projected = const ProjectSnapshotMapProjector().project(before, [
      change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest)),
    ]);
    expect(projected, isNotNull);
    expect(identical(projected!.maps.single, before.maps.single), isTrue);
    expect(
        projected.resourceBytes('map:town'), before.resourceBytes('map:town'));
    expect(projected.manifest, manifest);
  });

  test(
      'unrelated manifests, new identities and paths require the strict loader',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    for (final manifest in [
      before.manifest.copyWith(name: 'Other project'),
      before.manifest
          .copyWith(settings: before.manifest.settings.copyWith(tileWidth: 32)),
      before.manifest.copyWith(maps: []),
      before.manifest
          .copyWith(maps: [before.manifest.maps.single.copyWith(id: 'other')]),
      before.manifest.copyWith(maps: [
        before.manifest.maps.single.copyWith(relativePath: 'maps/other.json')
      ]),
      before.manifest.copyWith(
          maps: [before.manifest.maps.single.copyWith(role: MapRole.interior)]),
    ]) {
      expect(
          const ProjectSnapshotMapProjector().project(before, [
            change(before, 'project',
                encodeProjectAuthoringDocument(before, manifest)),
          ]),
          isNull);
    }
    final rawSettings = jsonDecode(utf8.decode(before.resourceBytes('project')))
        as Map<String, dynamic>;
    (rawSettings['settings'] as Map)['unmodeled'] = {
      'dependencies': ['new']
    };
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project', utf8.encode(jsonEncode(rawSettings))),
        ]),
        isNull);
    final raw = jsonDecode(utf8.decode(before.resourceBytes('project')))
        as Map<String, dynamic>;
    raw['unsupported'] = {
      'references': ['external']
    };
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project', utf8.encode(jsonEncode(raw))),
        ]),
        isNull);
  });

  test('invalid folder relationships and projection bindings are refused',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder',
          name: 'Village',
          parentGroupId: 'folder',
          type: MapGroupType.village),
    ]);
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project',
              encodeProjectAuthoringDocument(before, manifest)),
        ]),
        isNull);
    expect(
        () => before.projectMapResources(
              revision: before.revision,
              manifest: before.manifest.copyWith(maps: [
                before.manifest.maps.single
                    .copyWith(relativePath: 'other.json'),
              ]),
              maps: before.maps,
              resourceFingerprints: before.resourceFingerprints,
              replacementBytes: const {},
            ),
        throwsArgumentError);
  });

  test('stale pre-images and duplicate manifest changes are not adopted',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(groups: const [
      ProjectMapGroup(
          id: 'folder', name: 'Village', type: MapGroupType.village),
    ]);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, manifest));
    expect(const ProjectSnapshotMapProjector().project(before, [edit, edit]),
        isNull);
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          AuthoringResourceChange(
              resource: AuthoringResourceRef(kind: 'project', id: 'project'),
              storageKey: edit.storageKey,
              beforeBytes: [0],
              afterBytes: edit.afterBytes),
        ]),
        isNull);
  });
}

AuthoringResourceChange change(
        ProjectSnapshot snapshot, String identity, List<int> bytes) =>
    AuthoringResourceChange(
        resource: AuthoringResourceRef(
            kind: identity == 'project' ? 'project' : 'map',
            id: identity == 'project' ? 'project' : identity.substring(4),
            revision: snapshot.resourceFingerprints[identity]),
        storageKey: snapshot.resourceStorageKeys[identity]!,
        beforeBytes: snapshot.resourceBytes(identity),
        afterBytes: bytes);

SceneAsset _projectionScene(String name) => SceneAsset(
    id: 'scene',
    name: name,
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'done',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow)
    ]));

SceneAsset _itemProjectionScene() => SceneAsset(
    id: 'gift',
    name: 'Gift',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'give',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
              consequence:
                  SceneConsequence.giveItem(itemId: 'potion', quantity: 1))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start_give',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'give',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'give_end',
          fromNodeId: 'give',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted),
    ]));
