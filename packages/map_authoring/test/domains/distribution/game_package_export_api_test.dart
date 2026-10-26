import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/gameplay/project_capture_sprite_provisioning_service.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart'
    as spatial_fixture;

void main() {
  test('local export bounds story exploration without certifying completion',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    final file = File(p.join(root.path, 'project.json'));
    final project = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    final scene = project.scenes.single;
    final bounded = SceneAsset(
        id: scene.id,
        name: scene.name,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            ...scene.graph.nodes,
            for (var index = 0; index < 300; index++)
              SceneNode(id: 'merge_$index', kind: SceneNodeKind.merge),
          ],
          edges: [
            ...scene.graph.edges.where((edge) => edge.id != 'start-finish'),
            SceneEdge(
                id: 'start-merge',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'merge_0',
                kind: SceneEdgeKind.defaultFlow),
            for (var index = 0; index < 300; index++)
              SceneEdge(
                  id: 'merge-edge-$index',
                  fromNodeId: 'merge_$index',
                  fromPortId: 'completed',
                  toNodeId: index == 299 ? 'finish' : 'merge_${index + 1}',
                  kind: SceneEdgeKind.defaultFlow),
          ],
        ));
    await file.writeAsString(
        jsonEncode(project.copyWith(scenes: [bounded]).toJson()));
    final artifact = await CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection)
        .build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest);
    expect(artifact.certification.isExportable, isTrue);
    expect(artifact.certification.isCertified, isFalse);
    final report = artifact.certification.gameplayReadinessReport;
    expect(report.symbolicReachability!.verdict,
        NarrativeSymbolicVerdict.indeterminate);
    expect(report.byCode('narrativeSolvabilityIndeterminate'), isNotEmpty);
    expect(report.errorCount, 0);
    final published = await CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection)
        .build(projectRoot: root, profile: _profile());
    expect(published.certification.isCertified, isTrue);
    expect(published.certification.gameplayReadinessReport.narrativelySolvable,
        NarrativeSymbolicVerdict.pass);
  });

  test(
      'canonical Whirlpool export keeps the shared route and water and refuses 3D',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'data/pokemon/catalogs/moves.json'))
        .writeAsString(jsonEncode({
      'entries': [
        {'id': 'surf'},
        {'id': 'whirlpool'},
      ]
    }));
    final projectFile = File(p.join(root.path, 'project.json'));
    final mapFile = File(p.join(root.path, 'maps/start.json'));
    final project = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>);
    final original = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
    final zone = MapGameplayZone.fromJson(jsonDecode(
        File('../map_core/test/fixtures/whirlpool_field_zone.json')
            .readAsStringSync()) as Map<String, dynamic>);
    var map = const TriggerZoneActions().createZone(original,
        zone: const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 0, y: 0), size: GridSize(width: 8, height: 8)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf)));
    map = const TriggerZoneActions().createZone(map, zone: zone);
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final before = await mapFile.readAsBytes();
    final service = CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection);
    final artifact = await service.build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.certification.gameplayReadinessReport.isPlayable, isTrue);
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final exported = MapData.fromJson(jsonDecode(
            utf8.decode(archive.findFile('project/maps/start.json')!.content))
        as Map<String, dynamic>);
    expect(exported, map);
    expect(exported.gameplayZones.last.fieldAction!.toJson(),
        zone.fieldAction!.toJson());
    expect(await mapFile.readAsBytes(), before);
    await projectFile.writeAsString(jsonEncode(project
        .copyWith(
            version: ProjectVersion.v9,
            settings:
                project.settings.copyWith(dimension: ProjectDimension.threeD))
        .toJson()));
    await mapFile.writeAsString(jsonEncode(map
        .copyWith(
            version: ProjectVersion.v9,
            layers: const [],
            visualStack: null,
            spatialScene: MapSpatialScene(width: 8, depth: 8))
        .toJson()));
    await expectLater(
        service.build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>().having(
            (error) => error.code, 'code', 'runtime3d.gameplay_unsupported')));
  });
  test(
      'canonical export preserves a Strength block and slide zone and refuses their spatial use',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    final projectFile = File(p.join(root.path, 'project.json'));
    final mapFile = File(p.join(root.path, 'maps/start.json'));
    final original = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>);
    final project = original.copyWith(
      tilesets: const [
        ProjectTilesetEntry(
            id: 'props', name: 'Props', relativePath: 'assets/props.png')
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'props', name: 'Props')
      ],
      elements: const [
        ProjectElementEntry(
            id: 'rock-visual',
            name: 'Rocher',
            tilesetId: 'props',
            categoryId: 'props',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
            ])
      ],
    );
    final visual = File(p.join(root.path, 'assets/props.png'));
    await visual.parent.create(recursive: true);
    await visual
        .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
    final initial = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
    var map = const EntityActions().create(
        initial,
        const MapEntity(
          id: 'rock',
          name: 'Rocher',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1),
          editorVisual: MapEntityEditorVisual(elementId: 'rock-visual'),
        ));
    map = const EntityActions().setFieldObstacle(map,
        project: project,
        entityId: 'rock',
        fieldObstacle: const MapEntityFieldObstacleData(
            kind: FieldObstacleKind.strengthBoulder));
    map = const TriggerZoneActions().createZone(map,
        zone: const MapGameplayZone(
          id: 'ice',
          name: 'Glace',
          kind: GameplayZoneKind.movementEffect,
          area: MapRect(
              pos: GridPos(x: 1, y: 1), size: GridSize(width: 4, height: 2)),
          movementEffect: MovementEffectZonePayload(),
        ));
    await projectFile.writeAsString(jsonEncode(project.toJson()));
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final before = await mapFile.readAsBytes();
    final service = CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection);
    final artifact = await service.build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.certification.gameplayReadinessReport.isPlayable, isTrue);
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final exported = MapData.fromJson(jsonDecode(
            utf8.decode(archive.findFile('project/maps/start.json')!.content))
        as Map<String, dynamic>);
    expect(exported, map);
    expect(await mapFile.readAsBytes(), before);
    await projectFile.writeAsString(jsonEncode(project
        .copyWith(
          version: ProjectVersion.v9,
          settings:
              project.settings.copyWith(dimension: ProjectDimension.threeD),
        )
        .toJson()));
    await mapFile.writeAsString(jsonEncode(map
        .copyWith(
            version: ProjectVersion.v9,
            layers: const [],
            visualStack: null,
            spatialScene:
                MapSpatialScene(width: map.size.width, depth: map.size.height))
        .toJson()));
    await expectLater(
        service.build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>()
            .having(
                (error) => error.code, 'code', 'runtime3d.gameplay_unsupported')
            .having((error) => error.toString(), 'reason',
                contains('outside map3d.gameplay@1'))));
  });
  test(
      'canonical profile authoring persists the metadata used by the next export',
      () async {
    final root = await _createPlayableProject();
    final outputRoot =
        await Directory.systemTemp.createTemp('profile-export-output-');
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => outputRoot.delete(recursive: true));
    final profiles = await LocalGamePackageExportProfileApi.create(
        allowedProjectRoots: [root.path]);
    final candidate = _profile()
        .copyWith(title: 'Persisted authoring title', gameVersion: '2.3.4');
    final checked =
        await profiles.validate(projectRoot: root.path, profile: candidate);
    await profiles.save(
        projectRoot: root.path,
        profile: candidate,
        expectedProfileRevision: checked.profileRevision,
        expectedContextRevision: checked.contextRevision);
    final projectBytes =
        await File(p.join(root.path, 'project.json')).readAsBytes();
    final exports = await LocalGamePackageExportApi.create(
        allowedProjectRoots: [root.path],
        allowedExportRoots: [outputRoot.path],
        exportService: CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection));
    final output = File(p.join(outputRoot.path, 'profile.avelunegame'));
    final receipt =
        await exports.export(projectRoot: root.path, outputPath: output.path);
    expect(receipt.title, candidate.title);
    expect(receipt.gameVersion, '2.3.4');
    final archive =
        ZipDecoder().decodeBytes(await output.readAsBytes(), verify: true);
    expect(archive.files.where((entry) => entry.name.contains('.pokemap')),
        isEmpty);
    final descriptor = jsonDecode(
            utf8.decode(archive.findFile('project/project.json')!.content))
        as Map<String, dynamic>;
    expect(descriptor['format'], 'avelune.portable-catalog');
    expect(descriptor['version'], 2);
    expect(descriptor['kind'], 'project');
    final exported = PortableCatalogPublication.decodeProjectSync(descriptor,
        readObject: (ref) => archive
            .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
            .content);
    final original = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(projectBytes)) as Map<String, dynamic>);
    expect(exported.name, original.name);
    expect(
        exported.maps.map((map) => map.id), original.maps.map((map) => map.id));
    final inspected =
        GamePackageInspector().inspect(await output.readAsBytes());
    expect(inspected.manifest.compatibility.requiredCapabilities,
        contains('catalog.partitioned@2'));

    expect(await File(p.join(root.path, 'project.json')).readAsBytes(),
        projectBytes);
    expect((await profiles.read(projectRoot: root.path)).profile, candidate);
  });
  test('canonical spatial localTest exports a partitioned native project',
      () async {
    final root =
        await Directory.systemTemp.createTemp('canonical-spatial-export-');
    addTearDown(() => root.delete(recursive: true));
    final source = spatial_fixture.spatialPayload();
    for (final entry in source.entries) {
      final file =
          File(p.join(root.path, entry.key.substring('project/'.length)));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final artifact = await CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        containsAll(['catalog.partitioned@2', 'map3d@1']));
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final descriptor = jsonDecode(
            utf8.decode(archive.findFile('project/project.json')!.content))
        as Map<String, dynamic>;
    expect(descriptor['version'], 2);
    final project = PortableCatalogPublication.decodeProjectSync(descriptor,
        readObject: (ref) => archive
            .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
            .content);
    expect(project.settings.dimension, ProjectDimension.threeD);
    expect(project.models3d.single.id, 'model');
    expect(archive.findFile('project/assets/models3d/model.glb')!.content,
        source['project/assets/models3d/model.glb']);
    final reexport =
        GamePackageBuilder().build(manifest: artifact.manifest, payloadFiles: {
      for (final file in archive.files)
        if (file.name != 'game-manifest.json') file.name: file.content
    });
    expect(reexport.packageBytes, artifact.packageBytes);
  });

  test('exports provisioned capture sprites and their exact project reference',
      () async {
    final projectRoot = await _createPlayableProject();
    addTearDown(() => projectRoot.delete(recursive: true));
    final items =
        File(p.join(projectRoot.path, 'data/pokemon/catalogs/items.json'));
    await items.writeAsString(jsonEncode(
        encodeProjectItemCatalog(ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'poke_ball',
          displayName: 'Poké Ball',
          pocketId: 'balls',
          capture: ProjectCaptureItemDefinition(
              rateNumerator: 1,
              rateDenominator: 1,
              allowedEncounterKinds: {EncounterKind.walk}))
    ]))));
    final packRoot = p.normalize(p.join(Directory.current.path, '..', '..',
        'apps', 'avelune_studio', 'assets', 'pokemon', 'capture_sprites'));
    final isolatedSource =
        await Directory.systemTemp.createTemp('capture-source-');
    for (final name in ['manifest.json', 'sprites.zip']) {
      await File(p.join(packRoot, name))
          .copy(p.join(isolatedSource.path, name));
    }
    addTearDown(() async {
      if (await isolatedSource.exists()) {
        await isolatedSource.delete(recursive: true);
      }
    });
    await provisionProjectCaptureSprites(
        projectPath: projectRoot.path,
        loadPack: () async => ProjectCaptureSpritePack(
            manifestBytes:
                await File(p.join(isolatedSource.path, 'manifest.json'))
                    .readAsBytes(),
            archiveBytes: await File(p.join(isolatedSource.path, 'sprites.zip'))
                .readAsBytes()));
    const path = 'data/pokemon/assets/items/poke_ball/animation.png';
    final original = await File(p.join(projectRoot.path, path)).readAsBytes();
    final provenanceFile = (await Directory(p.join(projectRoot.path,
        'data/pokemon/assets/items')).list().toList()).whereType<File>().singleWhere(
        (file) => p.basename(file.path).startsWith('capture-source-') &&
            file.path.endsWith('.json'));
    final provenanceBytes = await provenanceFile.readAsBytes();
    await isolatedSource.delete(recursive: true);
    final artifact = await CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection)
        .build(projectRoot: projectRoot, profile: _profile());
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    expect(archive.findFile('project/$path')!.content, original);
    final catalog = decodeProjectItemCatalog(jsonDecode(utf8.decode(archive
        .findFile('project/data/pokemon/catalogs/items.json')!
        .content)));
    expect(catalog.entries.single.capture!.animationSpritePath, path);
    expect(archive.files.where((file) =>
        file.name
            .startsWith('project/data/pokemon/assets/items/capture-source-') &&
        file.name.endsWith('.json')), isEmpty);
    expect(await provenanceFile.readAsBytes(), provenanceBytes);
    final provenanceJson = jsonDecode(utf8.decode(provenanceBytes));
    expect(provenanceJson['sprites'][0]['projectItemId'], 'poke_ball');
    expect(provenanceJson['sprites'][0]['sourceItem']['sourcePath'],
        'Data/Studio/items/poke_ball.json');
    expect(archive.files.where((file) => file.name.endsWith('sprites.zip')),
        isEmpty);
  });

  test('exports project-owned item art without the runtime icon pack',
      () async {
    final projectRoot = await _createPlayableProject();
    addTearDown(() => projectRoot.delete(recursive: true));
    const logicalPath = 'data/pokemon/assets/items/potion.png';
    final pixels = image.encodePng(image.Image(width: 3, height: 2));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [projectRoot.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(projectRoot.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final staged = await store.put(pixels, declaredMediaType: 'image/png');
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: snapshots, artifactStore: store);
    await mutations.attachProject(
        projectRootPath: projectRoot.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final plan = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'project-item-art',
            actionId: 'asset.import_batch',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision:
                (await snapshots.load(opened.projectHandle)).revision,
            idempotencyKey: 'project-item-art',
            parameters: {
              'entries': [
                {
                  'assetId': 'item-art-potion',
                  'logicalPath': logicalPath,
                  'artifactHandle': staged.reference.handle,
                }
              ]
            }));
    await mutations.apply(opened.projectHandle,
        planId: plan['planId'] as String, operationId: 'project-item-art');
    final artifact = await CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection)
        .build(projectRoot: projectRoot, profile: _profile());
    await File(p.join(projectRoot.path, logicalPath)).delete();
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final packaged = archive.findFile('project/$logicalPath');
    expect(packaged, isNotNull);
    expect(packaged!.content, pixels);
    expect(artifact.inspection.payloadPaths,
        isNot(contains('packages/map_runtime/assets/menu/items/icons.zip')));
    expect(archive.files.where((file) => file.name.endsWith('icons.zip')),
        isEmpty);
  });

  test('export artifact reuses the certified immutable archive', () async {
    final projectRoot = await _createPlayableProject();
    addTearDown(() => projectRoot.delete(recursive: true));
    GamePackageBuildResult? built;
    final service = CanonicalGamePackageExportService(
      pokemonValidator: _acceptPokemonProjection,
      packageArchiveBuilder: ({required manifest, required payloadFiles}) {
        built = const GamePackageBuilder().build(
          manifest: manifest,
          payloadFiles: payloadFiles,
        );
        return built!;
      },
    );

    final artifact = await service.build(
      projectRoot: projectRoot,
      profile: _profile(),
    );

    expect(identical(artifact.packageBytes, built!.packageBytes), isTrue);
    expect(artifact.packageBytes, isA<Uint8List>());
    expect(
      () => artifact.packageBytes[0] = 0,
      throwsUnsupportedError,
    );

    final suppliedBytes = artifact.packageBytes.toList();
    final externalArtifact = GamePackageExportArtifact(
      packageBytes: suppliedBytes,
      manifest: artifact.manifest,
      inspection: artifact.inspection,
      personalizationPreflight: artifact.personalizationPreflight,
      certification: artifact.certification,
      suggestedFileName: artifact.suggestedFileName,
      compiledDialogueCount: artifact.compiledDialogueCount,
      scrubbedSecretFieldCount: artifact.scrubbedSecretFieldCount,
    );
    suppliedBytes[0] ^= 0xff;
    expect(externalArtifact.packageBytes, artifact.packageBytes);
    expect(externalArtifact.packageBytes, isA<Uint8List>());
    expect(
      () => GamePackageExportArtifact(
        packageBytes: [-1],
        manifest: artifact.manifest,
        inspection: artifact.inspection,
        personalizationPreflight: artifact.personalizationPreflight,
        certification: artifact.certification,
        suggestedFileName: artifact.suggestedFileName,
        compiledDialogueCount: artifact.compiledDialogueCount,
        scrubbedSecretFieldCount: artifact.scrubbedSecretFieldCount,
      ),
      throwsA(
        isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'invalidFileBytes'),
      ),
    );
  });

  test('selected-file fallback preserves the certified archive', () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot = await Directory.systemTemp.createTemp('direct_export_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    final service = CanonicalGamePackageExportService(
      pokemonValidator: _acceptPokemonProjection,
      atomicFileWriter: ({
        required outputFile,
        required packageBytes,
        required packageSha256,
      }) async {
        throw const FileSystemException('Sibling writes denied');
      },
    );
    final artifact = await service.build(
      projectRoot: projectRoot,
      profile: _profile(),
    );
    final output = File(p.join(exportRoot.path, 'direct.avelunegame'));

    await service.writeArtifactToFile(artifact: artifact, outputFile: output);

    expect(await output.readAsBytes(), artifact.packageBytes);
  });

  test('local test exports an unfinished story while publication rejects it',
      () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot =
        await Directory.systemTemp.createTemp('local_test_export_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    final graph = project['scenes'][0]['graph'] as Map<String, dynamic>;
    final finish =
        (graph['nodes'] as List).singleWhere((node) => node['id'] == 'finish');
    finish['payload'] =
        SceneActionPayload.consequence(SceneConsequence.healParty()).toJson();
    await projectFile.writeAsString(jsonEncode(project));
    await GamePackageExportProfileStore(projectRoot: projectRoot)
        .save(_profile());
    final api = await LocalGamePackageExportApi.create(
      allowedProjectRoots: [projectRoot.path],
      allowedExportRoots: [exportRoot.path],
      exportService: CanonicalGamePackageExportService(
          pokemonValidator: _acceptPokemonProjection),
    );
    final output = File(p.join(exportRoot.path, 'test.avelunegame'));
    final receipt = await api.export(
        projectRoot: projectRoot.path,
        outputPath: output.path,
        mode: GamePackageExportMode.localTest);
    expect(receipt.mode, GamePackageExportMode.localTest);
    expect(
        const GamePackageInspector()
            .inspect(await output.readAsBytes())
            .manifest
            .gameId,
        _profile().gameId);
    await expectLater(
        api.export(
            projectRoot: projectRoot.path,
            outputPath: p.join(exportRoot.path, 'publication.avelunegame')),
        throwsA(isA<GamePackageExportException>().having(
            (error) => error.gameplayReadinessReport
                ?.byCode('exportStoryEndUnreachable'),
            'story end diagnostics',
            isNotEmpty)));

    project['newGame']['startSpawnId'] = 'missing-spawn';
    await projectFile.writeAsString(jsonEncode(project));
    await expectLater(
        api.export(
            projectRoot: projectRoot.path,
            outputPath: p.join(exportRoot.path, 'invalid-test.avelunegame'),
            mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'gameplayReadinessFailed')));
  });

  test('local test keeps unfinished draft and fact diagnostics as warnings',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    final file = File(p.join(root.path, 'project.json'));
    final original = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    final registry = original.eventRegistry!;
    final project = original.copyWith(
      facts: [
        NarrativeFactDefinition(id: 'fact_later', label: 'Later chapter')
      ],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          legacyClaims: registry.legacyClaims,
          records: [
            ...registry.records,
            NarrativeEventRecord.draft(NarrativeEventDraft(
              id: 'evt_019abcde-6000-7000-8000-000000000002',
              name: 'Unfinished event',
              conditions: const [],
              priority: 0,
              order: 1,
            )),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-6000-7000-8000-000000000003',
                name: 'Later chapter event',
                source: NarrativeEventSourceRef.mapEnter('map.start'),
                conditions: [NarrativeEventCondition.fact('fact_later', true)],
                sceneId: 'scene.main',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 2,
              ),
              enabled: true,
            ),
          ]),
    );
    await file.writeAsString(jsonEncode(project.toJson()));
    final before = await file.readAsBytes();
    final service = CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection);
    final artifact = await service.build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    final report = artifact.certification.gameplayReadinessReport;
    expect(report.isPlayable, isTrue);
    for (final code in [
      'narrativeEventSourceMissing',
      'requiredFactNeverProduced'
    ]) {
      expect(report.byCode(code), isNotEmpty);
      expect(
          report.byCode(code).every(
              (d) => d.severity == NarrativeProjectDiagnosticSeverity.warning),
          isTrue);
    }
    expect(artifact.certification.isCertified, isFalse);
    await expectLater(
        service.build(projectRoot: root, profile: _profile()),
        throwsA(isA<GamePackageExportException>().having(
            (error) => error.gameplayReadinessReport?.errorCount,
            'publication errors',
            greaterThan(0))));
    expect(await file.readAsBytes(), before);
  });

  test('local test still rejects a configured event with a missing source',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    final file = File(p.join(root.path, 'project.json'));
    final original = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    final registry = original.eventRegistry!;
    await file.writeAsString(jsonEncode(original
        .copyWith(
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: registry.schemaVersion,
              mode: registry.mode,
              legacyClaims: registry.legacyClaims,
              records: [
                ...registry.records,
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                    id: 'evt_019abcde-6000-7000-8000-000000000004',
                    name: 'Broken configured event',
                    source: NarrativeEventSourceRef.entityInteract(
                        'map.start', 'entity.missing'),
                    conditions: const [],
                    sceneId: 'scene.main',
                    reusePolicy: NarrativeEventReusePolicy.oneShot,
                    priority: 0,
                    order: 1,
                  ),
                  enabled: true,
                ),
              ]),
        )
        .toJson()));
    final service = CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection);
    await expectLater(
        service.build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>().having(
            (error) => error.gameplayReadinessReport
                ?.byCode('narrativeEventSourceMissing')
                .any((d) =>
                    d.severity == NarrativeProjectDiagnosticSeverity.error),
            'configured source remains blocking',
            isTrue)));
  });

  test('export repacks tall atlases without changing tile identity or pixels',
      () async {
    final root = await _createPlayableProject();
    addTearDown(() => root.delete(recursive: true));
    final file = File(p.join(root.path, 'project.json'));
    final project = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    final pixels = image.Image(width: 32, height: 8224, numChannels: 4);
    for (var y = 0; y < pixels.height; y++) {
      for (var x = 0; x < pixels.width; x++) {
        pixels.setPixelRgba(x, y, x, y % 256, y ~/ 256, y % 3 == 0 ? 0 : 127);
      }
    }
    final bytes = image.encodePng(pixels);
    final ref = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    final record = AssetRecord(
        id: 'tall-image',
        logicalPath: 'assets/tall.png',
        artifact: ref,
        usages: const ['tileset']);
    final blob = File(p.join(root.path, assetBlobStorageKey(ref)));
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File(p.join(root.path, assetCatalogStorageKey))
        .writeAsString(jsonEncode(AssetCatalog(records: [record]).toJson()));
    await file.writeAsString(jsonEncode(project.copyWith(
      tilesets: [
        const ProjectTilesetEntry(
            id: 'tall',
            name: 'Tall',
            relativePath: 'assets/tall.png',
            source: ProjectRegularAtlasTilesetSource(
                assetId: 'tall-image',
                pixelWidth: 32,
                pixelHeight: 8224,
                tileWidth: 32,
                tileHeight: 32))
      ],
      elements: [
        const ProjectElementEntry(
            id: 'last',
            name: 'Last',
            tilesetId: 'tall',
            categoryId: 'props',
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 256))
            ])
      ],
      elementCategories: [
        const ProjectElementCategory(id: 'props', name: 'Props')
      ],
    ).toJson()));
    final before = await file.readAsBytes();
    final artifact = await CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection)
        .build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest);
    final archive =
        ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
    final descriptor = jsonDecode(
            utf8.decode(archive.findFile('project/project.json')!.content))
        as Map<String, dynamic>;
    final exportedProject = PortableCatalogPublication.decodeProjectSync(
        descriptor,
        readObject: (ref) => archive
            .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
            .content);
    final source = exportedProject.tilesets.single.source
        as ProjectRegularAtlasTilesetSource;
    expect([source.pixelWidth, source.pixelHeight], [64, 4128]);
    expect(exportedProject.elements.single.frames.single.source,
        const TilesetSourceRect(x: 0, y: 128));
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
            archive.findFile('project/$assetCatalogStorageKey')!.content))
        as Map<String, dynamic>);
    final exportedRecord = catalog.findByLogicalPath('assets/tall.png')!;
    final packed = image.decodePng(archive
        .findFile('project/${assetBlobStorageKey(exportedRecord.artifact)}')!
        .content)!;
    expect([packed.width, packed.height], [64, 4128]);
    for (var tile = 0; tile < 257; tile++) {
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final original = pixels.getPixel(x, tile * 32 + y);
          final actual =
              packed.getPixel((tile % 2) * 32 + x, (tile ~/ 2) * 32 + y);
          expect([actual.r, actual.g, actual.b, actual.a],
              [original.r, original.g, original.b, original.a]);
        }
      }
    }
    expect(await file.readAsBytes(), before);
    expect(await blob.readAsBytes(), bytes);
    final authored = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(before)) as Map<String, dynamic>);
    await file.writeAsString(jsonEncode(authored.copyWith(elements: [
      authored.elements.single.copyWith(frames: [
        const TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 254, height: 2)),
      ]),
    ]).toJson()));
    await expectLater(
        CanonicalGamePackageExportService(
                pokemonValidator: _acceptPokemonProjection)
            .build(
                projectRoot: root,
                profile: _profile(),
                mode: GamePackageExportMode.localTest),
        throwsA(isA<GamePackageExportException>().having((error) => error.code,
            'unsafe rectangle', 'runtimeAtlasRepackUnsupported')));
  });

  test('canonical export includes and remaps the authored menu background',
      () async {
    final projectRoot = await _createPlayableProject(illustrated: true);
    final exportRoot = await Directory.systemTemp.createTemp('menu_export_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    await GamePackageExportProfileStore(projectRoot: projectRoot)
        .save(_profile());
    final output = File(p.join(exportRoot.path, 'menu.avelunegame'));
    final api = await LocalGamePackageExportApi.create(
        allowedProjectRoots: [projectRoot.path],
        allowedExportRoots: [exportRoot.path],
        exportService: CanonicalGamePackageExportService(
            pokemonValidator: _acceptPokemonProjection));
    await api.export(projectRoot: projectRoot.path, outputPath: output.path);
    final inspection =
        const GamePackageInspector().inspect(await output.readAsBytes());
    final pause = inspection.manifest.presentation!.pause!;
    expect(pause.title, 'Voyage');
    expect(pause.style, ProjectPauseMenuStyle.nightIllustrated);
    expect(pause.background!.imagePath, 'presentation/menu-background.png');
    expect(pause.background!.focalX, .8);
    expect(
        const GamePackagePersonalizationPreflight()
            .certify(inspection)
            .assetSha256
            .keys,
        contains('presentation/menu-background.png'));
    await File(p.join(projectRoot.path, 'assets/menu/background.png'))
        .writeAsBytes([0x89, 0x50, 0x4e, 0x47]);
    await expectLater(
        api.export(
            projectRoot: projectRoot.path,
            outputPath: p.join(exportRoot.path, 'invalid.avelunegame')),
        throwsA(isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'invalidMenuBackground')));
  });

  test('exports a certified package inside the configured output root',
      () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot = await Directory.systemTemp.createTemp('avelune_export_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    final profile = _profile();
    await GamePackageExportProfileStore(projectRoot: projectRoot).save(profile);
    final output = File(p.join(exportRoot.path, 'fixture-1.0.0.avelunegame'));
    final api = await LocalGamePackageExportApi.create(
      allowedProjectRoots: <String>[projectRoot.path],
      allowedExportRoots: <String>[exportRoot.path],
      exportService: CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection,
      ),
    );

    final receipt = await api.export(
      projectRoot: projectRoot.path,
      outputPath: output.path,
    );
    final inspection = const GamePackageInspector().inspect(
      await output.readAsBytes(),
    );

    expect(receipt.outputPath, await output.resolveSymbolicLinks());
    expect(receipt.sizeBytes, await output.length());
    expect(receipt.sha256, isNotEmpty);
    expect(receipt.gameId, profile.gameId);
    expect(receipt.gameVersion, profile.gameVersion);
    expect(inspection.manifest.gameId, profile.gameId);
  });

  test('rejects a destination outside the configured output root', () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot = await Directory.systemTemp.createTemp('avelune_export_');
    final outsideRoot =
        await Directory.systemTemp.createTemp('avelune_outside_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    addTearDown(() => outsideRoot.delete(recursive: true));
    await GamePackageExportProfileStore(projectRoot: projectRoot)
        .save(_profile());
    final api = await LocalGamePackageExportApi.create(
      allowedProjectRoots: <String>[projectRoot.path],
      allowedExportRoots: <String>[exportRoot.path],
      exportService: CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection,
      ),
    );

    await expectLater(
      api.export(
        projectRoot: projectRoot.path,
        outputPath: p.join(outsideRoot.path, 'escape.avelunegame'),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'exportPathOutsideAllowedRoots',
        ),
      ),
    );
  });
}

Future<Directory> _createPlayableProject({bool illustrated = false}) async {
  final root = await Directory.systemTemp.createTemp('authoring_export_');
  final project = ProjectManifest(
    name: 'Export Fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map.start',
        name: 'Start',
        relativePath: 'maps/start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    presentation: illustrated
        ? const ProjectPresentationProfile(
            pause: ProjectPausePresentationProfile(
                style: ProjectPauseMenuStyle.nightIllustrated,
                title: 'Voyage',
                background: ProjectPauseBackgroundProfile(
                    imagePath: 'assets/menu/background.png', focalX: .8)))
        : null,
    scenes: <SceneAsset>[_completionScene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-6000-7000-8000-000000000001',
            name: 'Runtime start',
            source: NarrativeEventSourceRef.mapEnter('map.start'),
            conditions: const [],
            sceneId: 'scene.main',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'map.start',
      startSpawnId: 'spawn.player',
      playerName: 'Player',
      initialParty: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'fixture.partner',
          formId: 'partner',
          natureId: 'hardy',
          abilityId: 'steadfast',
          level: 5,
          currentHp: 20,
        ),
      ],
    ),
    pokemon: const ProjectPokemonConfig(
      enabled: true,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
  );
  if (illustrated) {
    final imageFile = File(p.join(root.path, 'assets/menu/background.png'));
    await imageFile.parent.create(recursive: true);
    await imageFile
        .writeAsBytes(image.encodePng(image.Image(width: 2, height: 2)));
  }
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(project.toJson()),
    flush: true,
  );
  await Directory(p.join(root.path, 'maps')).create(recursive: true);
  await File(p.join(root.path, 'maps', 'start.json')).writeAsString(
    jsonEncode(
      const MapData(
        id: 'map.start',
        name: 'Start',
        version: ProjectVersion.v8,
        size: GridSize(width: 8, height: 8),
        layers: <MapLayer>[MapLayer.object(id: 'events', name: 'Events')],
        mapMetadata: MapMetadata(defaultSpawnId: 'spawn.player'),
        entities: <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            name: 'Player start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
      ).toJson(),
    ),
    flush: true,
  );
  await Directory(
    p.join(root.path, 'data', 'pokemon', 'species'),
  ).create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'species', 'fixture.json'),
  ).writeAsString('{"id":"fixture.partner"}', flush: true);
  await Directory(
    p.join(root.path, 'data', 'pokemon', 'catalogs'),
  ).create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
  ).writeAsString('{"entries":[]}', flush: true);
  return root;
}

Future<PokemonCatalogCoherenceReport> _acceptPokemonProjection({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectManifest manifest,
}) async =>
    PokemonCatalogCoherenceReport(const <PokemonCatalogDiagnostic>[]);

SceneAsset _completionScene() => SceneAsset(
      id: 'scene.main',
      name: 'Main journey',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'finish',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.finishGame(
                endingId: 'ending.fixture.complete',
                outcome: SceneGameCompletionOutcome.completed,
                result: SceneFinishGameResult(
                  title: SceneLocalizedText(fallback: 'Complete'),
                  summary: SceneLocalizedText(fallback: 'Done'),
                ),
                postGamePolicy: ScenePostGamePolicy.returnToTitle,
              ),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start-finish',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'finish',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'finish-end',
            fromNodeId: 'finish',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

GamePackageExportProfile _profile() => GamePackageExportProfile(
      gameId: 'games.example.authoring-export',
      gameVersion: '1.0.0',
      title: 'Authoring Export',
      authorName: 'PokeMap',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
    );
