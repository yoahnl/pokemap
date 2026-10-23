import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('runtime JSON closure excludes orphan and nested project documents',
      () async {
    final root = await _fixture();
    final projectFile = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
    await projectFile.writeAsString(jsonEncode(project.copyWith(
      globalProperties: {'runtimeConfigPath': 'config/runtime.json'},
      dialogues: [
        const ProjectDialogueEntry(
            id: 'intro', name: 'Intro', relativePath: 'dialogues/intro.yarn')
      ],
    ).toJson()));
    await _write(root, 'config/runtime.json', {
      'nextPath': 'config/nested/child.json',
      'profile': 'a-literal.json',
      'conditionSource': {
        'sourceKind': 'factLikeStoryFlag',
        'sourceId': 'semantic-id.json'
      },
      'runtimeFiles': {'named': 'config/dictionary.json'},
      'dependencyPaths': ['config/array.json'],
    });
    await _write(root, 'config/array.json', {'value': 'array dependency'});
    await _write(
        root, 'config/dictionary.json', {'value': 'dictionary dependency'});
    await _write(root, 'config/nested/child.json', {
      'returnPath': 'config/runtime.json',
      'dialoguePath': 'dialogues/intro.json',
      'mediaPath': 'data/runtime/marker.png'
    });
    await _write(root, 'data/runtime/by-id.json', {
      'entries': [
        {'id': 'native-item'}
      ]
    });
    await _write(root, 'copies/other/project.json', project.toJson());
    await _write(
        root, 'copies/other/maps/unrelated.json', {'id': 'orphan-map'});
    await _write(root, 'notes/orphan.json', {'notRuntime': true});
    await _write(
        root, 'dialogues/intro.yarn', 'title: Start\n---\nBonjour !\n===\n');
    await _write(root, 'data/runtime/marker.png',
        spatialPayload()['project/assets/hero.png']!);
    final before = await projectFile.readAsBytes();
    final result = await _build(root);
    expect(
        result.payloadFiles.keys,
        containsAll([
          'project/maps/map.json',
          'project/config/runtime.json',
          'project/config/nested/child.json',
          'project/config/array.json',
          'project/config/dictionary.json',
          'project/dialogues/intro.json',
          'project/data/runtime/by-id.json',
          'project/data/runtime/marker.png',
        ]));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/project.json')));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/maps/unrelated.json')));
    expect(result.payloadFiles, isNot(contains('project/notes/orphan.json')));
    expect(await projectFile.readAsBytes(), before);
  });

  test(
      'runtime JSON references retain nested assets JSON without its orphan siblings',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'assets/runtime/options.json',
    }).toJson()));
    await _write(root, 'assets/runtime/options.json', {'value': 1});
    await _write(
        root, 'assets/runtime/provenance.json', {'source': '/author/only'});
    final result = await _build(root);
    expect(
        result.payloadFiles, contains('project/assets/runtime/options.json'));
    expect(result.payloadFiles,
        isNot(contains('project/assets/runtime/provenance.json')));
  });

  test('catalog closure excludes authoring JSON records and their blobs',
      () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'provenance',
        'assets/converter/provenance.json', {'file': 'shard:private-proof'},
        tags: ['runtime'], usages: ['runtime']);
    final before =
        await File('${root.path}/$assetCatalogStorageKey').readAsBytes();
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(catalog.find(record.id), isNull);
    expect(
        projection.payloadFiles,
        isNot(contains(
            PackagePathPolicy.normalizeNfc('project/${record.logicalPath}'))));
    expect(projection.payloadFiles,
        isNot(contains('project/${assetBlobStorageKey(record.artifact)}')));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    final inspected =
        const GamePackageInspector().inspect(artifact.packageBytes);
    expect(inspected.manifest.gameId, _profile().gameId);
    expect(inspected.manifest.content.files.map((file) => file.path),
        isNot(contains('project/${assetBlobStorageKey(record.artifact)}')));
    expect(await File('${root.path}/$assetCatalogStorageKey').readAsBytes(),
        before);
  });

  test('referenced catalog JSON survives misleading provenance labels',
      () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'native-encounter-release',
        'assets/converter/runtime-e\u0301.json', {
      'catalog': 'moves',
      'entries': [
        PokemonMove(
                id: 'tackle',
                name: 'Tackle',
                names: {'en': 'Tackle'},
                generation: 1,
                source: 'test',
                type: 'normal',
                category: PokemonMoveCategory.physical,
                target: PokemonMoveTarget.normal,
                basePower: 40,
                accuracy: const PokemonMoveAccuracy.percent(value: 100),
                pp: 35)
            .toJson()
      ]
    },
        tags: [
          'preserved-native-provenance'
        ],
        usages: [
          'converter.sourceEventBytes'
        ]);
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project
        .copyWith(
            pokemon: project.pokemon
                .copyWith(catalogFiles: {'moves': record.logicalPath}))
        .toJson()));
    final projection = await _build(root);
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(
        catalog.require(record.id).toJson(),
        record
            .copyWith(
                logicalPath: PackagePathPolicy.normalizeNfc(record.logicalPath))
            .toJson());
    expect(
        projection.payloadFiles,
        contains(
            PackagePathPolicy.normalizeNfc('project/${record.logicalPath}')));
    expect(projection.payloadFiles,
        contains('project/${assetBlobStorageKey(record.artifact)}'));
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(
        const GamePackageInspector()
            .inspect(artifact.packageBytes)
            .manifest
            .gameId,
        _profile().gameId);
    final exported = ZipDecoder().decodeBytes(artifact.packageBytes).findFile(
        PackagePathPolicy.normalizeNfc('project/${record.logicalPath}'))!;
    final decoded =
        jsonDecode(utf8.decode(exported.content)) as Map<String, dynamic>;
    final move = PokemonMove.fromJson(
        Map<String, dynamic>.from((decoded['entries'] as List).single as Map));
    expect(move.id, 'tackle');
    expect(move.pp, 35);
  });

  test('admitted catalog JSON retains its nested reference closure', () async {
    final root = await _fixture();
    final record = await _catalogJson(root, 'config', 'config/runtime.json',
        {'dependencyPath': 'config/child.json'});
    await _write(root, 'config/child.json', {'value': 1});
    final projection = await _build(root);
    expect(projection.payloadFiles, contains('project/${record.logicalPath}'));
    expect(projection.payloadFiles, contains('project/config/child.json'));
  });

  test('runtime character image survives misleading provenance tags', () async {
    final root = await _fixture();
    final file = File('${root.path}/$assetCatalogStorageKey');
    final catalog =
        AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
    await _write(
        root,
        assetCatalogStorageKey,
        AssetCatalog(records: [
          for (final record in catalog.records)
            record.copyWith(
                tags: ['preserved-native-provenance'],
                usages: ['converter.sourceEventBytes'])
        ]).toJson());
    final projection = await _build(root);
    final retained = AssetCatalog.fromJson(jsonDecode(utf8
        .decode(projection.payloadFiles['project/$assetCatalogStorageKey']!)));
    expect(retained.require('hero-source').logicalPath, 'assets/hero.png');
    expect(projection.payloadFiles, contains('project/assets/hero.png'));
    expect(
        projection.payloadFiles,
        contains(
            'project/${assetBlobStorageKey(retained.require('hero-source').artifact)}'));
  });

  for (final sceneOnly in [false, true]) {
    test(
        'Presentation media retain their referenced opaque source blobs sceneOnly=$sceneOnly',
        () async {
      final root = await _fixture();
      final bytes = spatialPayload()['project/assets/hero.png']!;
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
      const path = 'assets/presentation/opening.bin';
      final file = File('${root.path}/$assetCatalogStorageKey');
      final catalog =
          AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
      final record = AssetRecord(
          id: 'opening-source', logicalPath: path, artifact: artifact);
      await _write(root, assetCatalogStorageKey,
          AssetCatalog(records: [...catalog.records, record]).toJson());
      await _write(root, assetBlobStorageKey(artifact), bytes);
      await _write(
          root,
          projectMediaCatalogStorageKey,
          encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
            ProjectMediaAsset(
                id: 'opening',
                label: 'Opening',
                kind: ProjectMediaKind.image,
                sourceAssetId: record.id,
                provenance: ProjectMediaProvenance(source: 'Fixture'),
                license:
                    ProjectMediaLicense(identifier: 'CC0-1.0', name: 'CC0'),
                technicalMetadata: ProjectMediaTechnicalMetadata(
                    mediaType: 'image/png',
                    container: 'png',
                    codec: 'png',
                    sizeBytes: bytes.length,
                    width: 32,
                    height: 32))
          ])));
      final projectFile = File('${root.path}/project.json');
      final project = ProjectManifest.fromJson(
          jsonDecode(await projectFile.readAsString()));
      await _write(
          root,
          'maps/map.json',
          MapData(
                  id: 'map',
                  name: 'Map',
                size: const GridSize(width: 8, height: 8),
                entities: const [MapEntity(id: 'spawn', name: 'Spawn',
                  kind: MapEntityKind.spawn, pos: GridPos(x: 1, y: 1),
                  spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))])
              .toJson());
      await projectFile.writeAsString(jsonEncode(project
          .copyWith(
              version: ProjectVersion.v8,
              models3d: [],
            newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'map', startSpawnId: 'spawn', playerName: 'Player'),
              settings:
                project.settings.copyWith(dimension: ProjectDimension.twoD, spatialCamera: null),
              scenes: sceneOnly
                  ? [
                      SceneAsset(
                          id: 'picture',
                          name: 'Picture',
                          graph: SceneGraph(startNodeId: 'start', nodes: [
                            SceneNode(id: 'start', kind: SceneNodeKind.start),
                            SceneNode(
                                id: 'show',
                                kind: SceneNodeKind.action,
                                payload: SceneActionPayload.interactive(
                                    SceneInteractiveCommand.worldPresentation(
                                        operation:
                                            SceneWorldPresentationOperation
                                                .showPicture,
                                        slotId: 1,
                                        mediaAssetId: 'opening',
                                        referenceWidth: 512,
                                        referenceHeight: 384,
                                        x: 0,
                                        y: 0))),
                            SceneNode(id: 'end', kind: SceneNodeKind.end),
                          ], edges: [
                            SceneEdge(
                                id: 'start_show',
                                fromNodeId: 'start',
                                fromPortId: 'completed',
                                toNodeId: 'show',
                                kind: SceneEdgeKind.defaultFlow),
                            SceneEdge(
                                id: 'show_end',
                                fromNodeId: 'show',
                                fromPortId: 'completed',
                                toNodeId: 'end',
                                kind: SceneEdgeKind.actionCompleted),
                          ]))
                    ]
                  : const [],
              presentationCinematics: [
                if (!sceneOnly)
                  PresentationCinematicAsset(
                      id: 'opening',
                      title: 'Opening',
                      durationUs: 1000000,
                      layers: [
                        PresentationLayer(
                            id: 'background', label: 'Background', zIndex: 0)
                      ],
                      tracks: [
                        PresentationTrack(
                            id: 'visual',
                            label: 'Visual',
                            kind: PresentationTrackKind.visual,
                            clips: [
                              PresentationVisualClip(
                                  id: 'image',
                                  startUs: 0,
                                  durationUs: 1000000,
                                  layerId: 'background',
                                  resourceId: 'opening')
                            ])
                      ])
              ])
          .toJson()));
      final projection = await _build(root);
      final retained = AssetCatalog.fromJson(jsonDecode(utf8.decode(
          projection.payloadFiles['project/$assetCatalogStorageKey']!)));
      expect(retained.require(record.id).toJson(), record.toJson());
      expect(
          projection.payloadFiles['project/${assetBlobStorageKey(artifact)}'],
          bytes);
      final projectedMedia = decodeProjectMediaCatalogBytes(
          projection.payloadFiles['project/$projectMediaCatalogStorageKey']!);
      expect(projectedMedia.find('opening'), isNotNull);
      if (sceneOnly) {
        final artifact = await const CanonicalGamePackageExportService().build(
            projectRoot: root,
            profile: _profile(),
            mode: GamePackageExportMode.localTest);
        final archive =
            ZipDecoder().decodeBytes(artifact.packageBytes, verify: true);
        expect(
            archive
                .findFile('project/${assetBlobStorageKey(record.artifact)}')!
                .content,
            bytes);
        expect(
            decodeProjectMediaCatalogBytes(archive
                    .findFile('project/$projectMediaCatalogStorageKey')!
                    .content)
                .find('opening'),
            isNotNull);
        expect(artifact.inspection.payloadPaths,
            contains('project/$projectMediaCatalogStorageKey'));
      }
    });
  }

  for (final entry in <String, Map<String, Object>>{
    'referenceEscapesRoot': {'file': 'shard:outside-runtime'},
    'probableSecret': {'privateKey': '-----BEGIN PRIVATE KEY-----'},
  }.entries) {
    test('referenced catalog JSON still rejects ${entry.key}', () async {
      final root = await _fixture();
      final record = await _catalogJson(
          root, 'provenance', 'assets/converter/runtime.json', entry.value,
          tags: ['preserved-native-provenance']);
      await _runtimeReference(root, record.logicalPath);
      await expectLater(
          const CanonicalGamePackageExportService().build(
              projectRoot: root,
              profile: _profile(),
              mode: GamePackageExportMode.localTest),
          throwsA(isA<GamePackageExportException>()
              .having((error) => error.code, 'code', entry.key)));
    });
  }

  test('ID addressed data survives with optional Pokemon catalog defaults',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project
        .copyWith(
          pokemon: const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        )
        .toJson()));
    await _write(root, 'data/pokemon/catalogs/moves.json', {'entries': []});
    await _write(root, 'data/pokemon/species/native-id.json', {'id': 'native'});
    await _write(root, 'data/runtime/project.json', {'id': 'project'});
    await _write(root, 'data/runtime/sibling.json', {'id': 'sibling'});
    final result = await _build(root);
    expect(result.payloadFiles,
        contains('project/data/pokemon/catalogs/moves.json'));
    expect(result.payloadFiles,
        contains('project/data/pokemon/species/native-id.json'));
    expect(result.payloadFiles, contains('project/data/runtime/project.json'));
    expect(result.payloadFiles, contains('project/data/runtime/sibling.json'));
  });

  test('a dangling nested runtime JSON reference is rejected', () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'config/runtime.json'
    }).toJson()));
    for (final reference in [
      {'nextPath': 'config/missing.json'},
      {
        'sourceItem': {'sourcePath': 'config/missing.json'}
      },
    ]) {
      await _write(root, 'config/runtime.json', reference);
      await expectLater(
          _build(root),
          throwsA(isA<GamePackageExportException>()
              .having((error) => error.code, 'code', 'missingProjectFile')
              .having((error) => error.path, 'path', 'config/missing.json')));
    }
  });

  test('unreferenced malformed JSON is excluded without being decoded',
      () async {
    final root = await _fixture();
    await _write(root, 'old/project.json', '{broken');
    await _write(root, 'old/maps/corrupt.json', '{broken');
    final result = await _build(root);
    expect(
        result.payloadFiles.keys.any((path) => path.startsWith('project/old/')),
        isFalse);
  });
}

Future<Directory> _fixture() async {
  final root =
      await Directory.systemTemp.createTemp('runtime-reference-closure-');
  addTearDown(() => root.delete(recursive: true));
  for (final entry in spatialPayload().entries) {
    await _write(root, entry.key.substring('project/'.length), entry.value);
  }
  return root;
}

Future<void> _write(Directory root, String path, Object value) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  if (value is List<int>) {
    await file.writeAsBytes(value);
  } else {
    await file.writeAsString(value is String ? value : jsonEncode(value));
  }
}

Future<RuntimeProjectProjection> _build(Directory root) =>
    const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
          gameId: 'games.example.closure',
          gameVersion: '0.1.0',
          title: 'Closure',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr']),
    );

Future<AssetRecord> _catalogJson(
    Directory root, String id, String path, Map<String, Object> value,
    {List<String> tags = const [], List<String> usages = const []}) async {
  final bytes = utf8.encode(jsonEncode(value));
  final artifact =
      ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
  final record = AssetRecord(
      id: id,
      logicalPath: path,
      artifact: artifact,
      tags: tags,
      usages: usages);
  final file = File('${root.path}/$assetCatalogStorageKey');
  final catalog = AssetCatalog.fromJson(jsonDecode(await file.readAsString()));
  await _write(root, assetCatalogStorageKey,
      AssetCatalog(records: [...catalog.records, record]).toJson());
  await _write(root, assetBlobStorageKey(artifact), bytes);
  return record;
}

Future<void> _runtimeReference(Directory root, String path) async {
  final file = File('${root.path}/project.json');
  final project =
      ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
  await file.writeAsString(jsonEncode(project
      .copyWith(globalProperties: {'runtimeConfigPath': path}).toJson()));
}

GamePackageExportProfile _profile() => GamePackageExportProfile(
    gameId: 'games.example.closure',
    gameVersion: '0.1.0',
    title: 'Closure',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);
