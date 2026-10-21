import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_metadata_fixture.dart';

void main() {
  for (final field in [
    'scenes',
    'worldRules',
    'eventRegistry',
    'facts',
    'dialogues',
    'cinematics'
  ]) {
    test('$field post-image adopts the complete snapshot with cold parity',
        () async {
      final f = await MapMetadataFixture.create();
      addTearDown(f.dispose);
      final seeded = (await f.manifest()).copyWith(
        facts: [NarrativeFactDefinition(id: 'fact_known', label: 'Known')],
        scenes: [_projectionScene('Before')],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'known', name: 'Before', relativePath: 'dialogues/known.yarn')
        ],
      );
      await Directory('${f.root.path}/dialogues').create();
      await File('${f.root.path}/dialogues/known.yarn')
          .writeAsString('title: Start\n---\nHello\n===\n');
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
        'facts' => before.manifest.copyWith(facts: [
            NarrativeFactDefinition(id: 'fact_known', label: 'After'),
            NarrativeFactDefinition(id: 'fact_added', label: 'Added')
          ]),
        'dialogues' => before.manifest.copyWith(dialogues: [
            before.manifest.dialogues.single.copyWith(
                name: 'After', tags: ['intro'], defaultStartNode: 'Start')
          ]),
        'cinematics' =>
          before.manifest.copyWith(cinematics: [_projectionCinematic()]),
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

  test('manifest-only adoption refuses partial snapshots', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final partial = ProjectSnapshot(
      projectHandle: before.projectHandle,
      revision: before.revision,
      manifest: before.manifest,
      maps: before.maps,
      resourceFingerprints: before.resourceFingerprints,
      resourceStorageKeys: before.resourceStorageKeys,
      resourceBytes: {
        for (final id in before.resourceStorageKeys.keys)
          id: before.resourceBytes(id)
      },
      loadDiagnostics: [
        ProjectSnapshotLoadDiagnostic(
            code: 'missing', resourceKind: 'dialogue', resourceId: 'missing')
      ],
    );
    final manifest = before.manifest.copyWith(
        facts: [NarrativeFactDefinition(id: 'added', label: 'Added')]);
    expect(
        const ProjectSnapshotMapProjector().project(partial, [
          change(partial, 'project',
              encodeProjectAuthoringDocument(partial, manifest))
        ]),
        isNull);
  });

  test('new dialogue sources require their exact paired manifest post-image',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    const entry = ProjectDialogueEntry(
        id: 'added', name: 'Added', relativePath: 'dialogues/added.yarn');
    final manifest = before.manifest.copyWith(dialogues: [entry]);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, manifest));
    final source = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'dialogue', id: entry.id),
        storageKey: entry.relativePath,
        beforeBytes: null,
        afterBytes: utf8.encode('title: Start\n---\nHello\n===\n'));
    const projector = ProjectSnapshotMapProjector();
    final projected = projector.project(before, [source, edit])!;
    expect(projected.resourceStorageKeys['dialogueSource:added'],
        entry.relativePath);
    expect(projected.resourceBytes('dialogueSource:added'), source.afterBytes);
    expect(before.resourceStorageKeys.containsKey('dialogueSource:added'),
        isFalse);
    expect(projected.maps.single, same(before.maps.single));
    for (final invalid in <List<AuthoringResourceChange>>[
      [source],
      [edit],
      [source, source, edit],
      [source, edit, edit],
      [
        edit,
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'dialogue', id: 'other'),
            storageKey: entry.relativePath,
            beforeBytes: null,
            afterBytes: source.afterBytes)
      ],
      [
        edit,
        AuthoringResourceChange(
            resource: source.resource,
            storageKey: 'dialogues/other.yarn',
            beforeBytes: null,
            afterBytes: source.afterBytes)
      ],
      [
        edit,
        AuthoringResourceChange(
            resource: source.resource,
            storageKey: source.storageKey,
            beforeBytes: [0],
            afterBytes: source.afterBytes)
      ],
      [
        source,
        edit,
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'asset', id: 'extra'),
            storageKey: 'assets/extra.png',
            beforeBytes: null,
            afterBytes: [1])
      ],
    ]) {
      expect(projector.project(before, invalid), isNull);
    }
  });

  test('oversized dialogue source additions fall back before reading disk',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [f.root.path], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(f.root.path);
    addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
    final cache = ProjectSnapshotCache();
    final snapshots =
        ProjectSnapshotLoader(handles: handles, snapshotCache: cache);
    final before = await snapshots.load(opened.projectHandle);
    const entry = ProjectDialogueEntry(
        id: 'added', name: 'Added', relativePath: 'dialogues/added.yarn');
    final manifest = before.manifest.copyWith(dialogues: [entry]);
    final source = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'dialogue', id: entry.id),
        storageKey: entry.relativePath,
        beforeBytes: null,
        afterBytes: List.filled(
            ProjectSnapshotCache.maxProjectedDialogueSourceBytes + 1, 65));
    expect(
        await snapshots.adoptAppliedChanges(opened.projectHandle,
            baseRevision: before.revision,
            changes: [
              source,
              change(before, 'project',
                  encodeProjectAuthoringDocument(before, manifest))
            ]),
        isNull);
    expect(cache.adoptionRejections, 1);
    expect(
        await File('${f.root.path}/${entry.relativePath}').exists(), isFalse);
    expect(
        (await snapshots.load(opened.projectHandle)).revision, before.revision);
  });

  for (final mutation in ['sameLength', 'shorter', 'longer']) {
    test('committed new dialogue $mutation mismatch cannot enter the cache',
        () async {
      final f = await MapMetadataFixture.create();
      addTearDown(f.dispose);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [f.root.path], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(f.root.path);
      addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
      final cache = ProjectSnapshotCache();
      final snapshots =
          ProjectSnapshotLoader(handles: handles, snapshotCache: cache);
      final before = await snapshots.load(opened.projectHandle);
      const entry = ProjectDialogueEntry(
          id: 'added', name: 'Added', relativePath: 'dialogues/added.yarn');
      final manifest = before.manifest.copyWith(dialogues: [entry]);
      final bytes = utf8.encode('title: Start\n---\nHello\n===\n');
      final inline =
          AuthoringPayload.inline(bytes, storageKey: entry.relativePath);
      final planned = await AuthoringPayload.verifiedSource(
          storageKey: entry.relativePath,
          byteLength: bytes.length,
          rawSha256: inline.rawSha256,
          resourceRevision: inline.resourceRevision,
          openRead: () => Stream.value(bytes));
      await planned.release();
      final changed = List<int>.of(bytes);
      switch (mutation) {
        case 'sameLength':
          changed[0] ^= 1;
        case 'shorter':
          changed.removeLast();
        case 'longer':
          changed.add(65);
      }
      final projectEdit = change(
          before, 'project', encodeProjectAuthoringDocument(before, manifest));
      await File('${f.root.path}/project.json')
          .writeAsBytes(projectEdit.afterBytes!);
      await Directory('${f.root.path}/dialogues').create();
      await File('${f.root.path}/${entry.relativePath}').writeAsBytes(changed);
      expect(
          await snapshots.adoptAppliedChanges(opened.projectHandle,
              baseRevision: before.revision,
              changes: [
                projectEdit,
                AuthoringResourceChange.withPayloads(
                    resource:
                        AuthoringResourceRef(kind: 'dialogue', id: entry.id),
                    storageKey: entry.relativePath,
                    beforePayload: null,
                    afterPayload: planned)
              ]),
          isNull);
      expect(cache.adoptionRejections, 1);
      expect(cache.projectCount, 0);
      expect(before.manifest.dialogues, isEmpty);
    });
  }

  test('dialogue metadata adoption refuses changed or missing source bindings',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final seeded = (await f.manifest()).copyWith(dialogues: const [
      ProjectDialogueEntry(
          id: 'known', name: 'Before', relativePath: 'dialogues/known.yarn')
    ]);
    await Directory('${f.root.path}/dialogues').create();
    await File('${f.root.path}/dialogues/known.yarn')
        .writeAsString('title: Start\n---\nHello\n===\n');
    await File('${f.root.path}/project.json')
        .writeAsString(jsonEncode(seeded.toJson()));
    final before = await f.snapshots.load(f.opened.projectHandle);
    for (final dialogues in [
      <ProjectDialogueEntry>[],
      [seeded.dialogues.single.copyWith(id: 'other')],
      [seeded.dialogues.single.copyWith(relativePath: 'dialogues/other.yarn')],
    ]) {
      final manifest = seeded.copyWith(dialogues: dialogues);
      expect(
          const ProjectSnapshotMapProjector().project(before, [
            change(before, 'project',
                encodeProjectAuthoringDocument(before, manifest))
          ]),
          isNull);
    }
    final missing = ProjectSnapshot(
      projectHandle: before.projectHandle,
      revision: before.revision,
      manifest: before.manifest,
      maps: before.maps,
      resourceFingerprints: {
        'project': before.resourceFingerprints['project']!,
        'map:town': before.resourceFingerprints['map:town']!
      },
      resourceStorageKeys: {
        'project': 'project.json',
        'map:town': 'documents/unusual.json'
      },
      resourceBytes: {
        'project': before.resourceBytes('project'),
        'map:town': before.resourceBytes('map:town')
      },
    );
    final metadata = seeded
        .copyWith(dialogues: [seeded.dialogues.single.copyWith(name: 'After')]);
    expect(
        const ProjectSnapshotMapProjector().project(missing, [
          change(missing, 'project',
              encodeProjectAuthoringDocument(missing, metadata))
        ]),
        isNull);
  });

  test('invalid facts and cinematics remain rejected', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    for (final manifest in [
      before.manifest.copyWith(facts: [
        NarrativeFactDefinition(id: 'duplicate', label: 'One'),
        NarrativeFactDefinition(id: 'duplicate', label: 'Two')
      ]),
      before.manifest.copyWith(
          cinematics: [_projectionCinematic().copyWith(mapId: 'unknown')]),
    ]) {
      expect(
          const ProjectSnapshotMapProjector().project(before, [
            change(before, 'project',
                encodeProjectAuthoringDocument(before, manifest))
          ]),
          isNull);
    }
  });

  test('new media and unmodeled dependencies require the strict loader',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.snapshots.load(f.opened.projectHandle);
    final manifest = before.manifest.copyWith(cinematics: [
      _projectionCinematic()
    ], cinematicMediaAssets: [
      CinematicMediaAsset(
          id: 'new',
          label: 'New',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/new.ogg')
    ]);
    expect(
        const ProjectSnapshotMapProjector().project(before, [
          change(before, 'project',
              encodeProjectAuthoringDocument(before, manifest))
        ]),
        isNull);
    for (final field in ['facts', 'cinematics']) {
      final modeled = field == 'facts'
          ? before.manifest.copyWith(
              facts: [NarrativeFactDefinition(id: 'new', label: 'New')])
          : before.manifest.copyWith(cinematics: [_projectionCinematic()]);
      final raw = jsonDecode(
              utf8.decode(encodeProjectAuthoringDocument(before, modeled)))
          as Map<String, dynamic>;
      ((raw[field] as List).single as Map)['unmodeledDependency'] =
          'audio/new.ogg';
      expect(
          const ProjectSnapshotMapProjector().project(before,
              [change(before, 'project', utf8.encode(jsonEncode(raw)))]),
          isNull);
    }
  });

  test('manifest adoption refuses an out-of-band map replacement', () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [f.root.path], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(f.root.path);
    addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
    final cache = ProjectSnapshotCache();
    final snapshots =
        ProjectSnapshotLoader(handles: handles, snapshotCache: cache);
    final before = await snapshots.load(opened.projectHandle);
    final manifest = before.manifest
        .copyWith(facts: [NarrativeFactDefinition(id: 'new', label: 'New')]);
    final edit = change(
        before, 'project', encodeProjectAuthoringDocument(before, manifest));
    await File('${f.root.path}/project.json').writeAsBytes(edit.afterBytes!);
    await File('${f.root.path}/documents/unusual.json').writeAsBytes(
        encodeMapAuthoringDocument(
            before.maps.single.copyWith(name: 'External')));
    expect(
        await snapshots.adoptAppliedChanges(opened.projectHandle,
            baseRevision: before.revision, changes: [edit]),
        isNull);
    expect(cache.adoptionRejections, 1);
    final cold = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(cold.maps.single.name, 'External');
    expect(cold.manifest, manifest);
  });

  test('canonical manifest-only actions keep coherent cached snapshots',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final seeded = (await f.manifest()).copyWith(dialogues: const [
      ProjectDialogueEntry(
          id: 'known', name: 'Before', relativePath: 'dialogues/known.yarn')
    ]);
    await Directory('${f.root.path}/dialogues').create();
    await File('${f.root.path}/dialogues/known.yarn')
        .writeAsString('title: Start\n---\nHello\n===\n');
    await File('${f.root.path}/project.json')
        .writeAsString(jsonEncode(seeded.toJson()));
    await Directory('${f.root.path}/${seeded.pokemon.speciesDir}')
        .create(recursive: true);
    await File('${f.root.path}/${seeded.pokemon.speciesDir}/bulbasaur.json')
        .writeAsString(jsonEncode({'id': 'bulbasaur'}));
    await Directory('${f.root.path}/data/pokemon/catalogs')
        .create(recursive: true);
    await File('${f.root.path}/${seeded.pokemon.catalogFiles['items']}')
        .writeAsString(jsonEncode(encodeProjectItemCatalog(
            const ProjectItemCatalog(schemaVersion: 1, entries: []))));
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
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await api.attachProject(
        projectRootPath: f.root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() => api.detachWorkspace(opened.workspaceHandle));
    final measurements = <Map<String, Object?>>[];
    for (final action in <(String, Map<String, Object?>)>[
      (
        'fact.create',
        {
          'fact':
              NarrativeFactDefinition(id: 'fact_added', label: 'Added').toJson()
        }
      ),
      ('cinematic.upsert', {'cinematic': _projectionCinematic().toJson()}),
      (
        'dialogue.update',
        {'entry': seeded.dialogues.single.copyWith(name: 'After').toJson()}
      ),
      (
        'dialogue.create',
        {
          'entry': const ProjectDialogueEntry(
                  id: 'added',
                  name: 'Added',
                  relativePath: 'dialogues/added.yarn')
              .toJson(),
          'source': 'title: Start\n---\nNew dialogue\n===\n'
        }
      ),
    ]) {
      final before = await snapshots.load(opened.projectHandle,
          deferPokemonDocuments: false);
      expect(before.pokemonInventoryComplete, isTrue);
      expect(before.itemCatalog, isNotNull);
      final pokemonBytes =
          before.resourceBytes(pokemonSpeciesResourceIdentity('bulbasaur'));
      final clock = Stopwatch()..start();
      final request = AuthoringRequest(
          requestId: action.$1,
          actionId: action.$1,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: action.$2,
          expectedRevision: before.revision,
          idempotencyKey: action.$1);
      final plan = await api.plan(opened.projectHandle, request);
      final planMicros = clock.elapsedMicroseconds;
      final applyClock = Stopwatch()..start();
      await api.apply(opened.projectHandle,
          planId: plan['planId']! as String, operationId: 'apply-${action.$1}');
      final applyMicros = applyClock.elapsedMicroseconds;
      final warm = await snapshots.load(opened.projectHandle);
      expect(profiles.last.cacheHit, isTrue);
      final cold = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(warm.itemCatalog, cold.itemCatalog);
      expect(warm.pokemonInventoryComplete, isTrue);
      expect(warm.resourceBytes(pokemonSpeciesResourceIdentity('bulbasaur')),
          pokemonBytes);
      expect(warm.manifest, cold.manifest);
      expect(warm.maps, cold.maps);
      expect(warm.revision, cold.revision);
      expect(warm.resourceFingerprints, cold.resourceFingerprints);
      expect(warm.resourceStorageKeys, cold.resourceStorageKeys);
      expect(warm.resourceFingerprints.keys.toList(),
          cold.resourceFingerprints.keys.toList());
      expect(warm.resourceStorageKeys.keys.toList(),
          cold.resourceStorageKeys.keys.toList());
      expect(warm.inlineResourceBytes.keys.toList(),
          cold.inlineResourceBytes.keys.toList());
      measurements.add({
        'action': action.$1,
        'planMicros': planMicros,
        'applyMicros': applyMicros,
        'revision': warm.revision
      });
    }
    expect(profiles.where((profile) => !profile.cacheHit).length, 1);
    expect(cache.adoptions, 4);
    expect(cache.adoptionRejections, 0);
    print(jsonEncode({'manifestActionCacheMeasurements': measurements}));
    final deferred =
        await snapshots.load(opened.projectHandle, deferPokemonDocuments: true);
    expect(deferred.itemCatalog, isNull);
    expect(deferred.storedResources, isNotEmpty);
    final deferredManifest = deferred.manifest.copyWith(
        facts: [NarrativeFactDefinition(id: 'fact_other', label: 'Other')]);
    expect(
        await snapshots.adoptAppliedChanges(opened.projectHandle,
            baseRevision: deferred.revision,
            changes: [
              change(deferred, 'project',
                  encodeProjectAuthoringDocument(deferred, deferredManifest))
            ]),
        isNull);
    final full = await snapshots.load(opened.projectHandle,
        deferPokemonDocuments: false);
    expect(profiles.last.cacheHit, isFalse);
    expect(full.itemCatalog, isNotNull);
    expect(full.pokemonInventoryComplete, isTrue);
    expect(full.resourceBytes(pokemonSpeciesResourceIdentity('bulbasaur')),
        utf8.encode(jsonEncode({'id': 'bulbasaur'})));
  });

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

CinematicAsset _projectionCinematic() => CinematicAsset(
    id: 'cine',
    title: 'Wait',
    timeline: CinematicTimeline(steps: [
      CinematicTimelineStep(
          id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 100)
    ]));
