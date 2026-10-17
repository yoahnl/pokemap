import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/distribution/runtime_unused_model_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';
import '../../support/glb_fixture.dart';

void main() {
  test('a projected game retains baked stair navigation without the authoring profile', () async {
    final fixture = await _fixture();
    final projectFile = File('${fixture.root.path}/project.json');
    final project = ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
    final model = project.models3d.first.copyWith(rampProfile: Model3dRampProfile(
      x: -.5, z: -1, width: 1, depth: 1, lowHeight: 0, highHeight: 1, direction: SpatialRampDirection.north));
    final updatedProject = project.copyWith(models3d: [model, ...project.models3d.skip(1)]);
    final mapFile = File('${fixture.root.path}/maps/map.json');
    final source = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    final terrain = source.copyWith(spatialScene: source.spatialScene!.copyWith(instances: const [],
      heightLevels: List.generate(64, (index) => index ~/ 8 < 2 ? 1 : 0)));
    final map = const SpatialMapOperations().upsertInstance(terrain, SpatialModelInstance(
      id: 'placed-stair', modelId: model.id, position: Model3dVector3(x: 3.5, y: 0, z: 3)), model: model);
    await projectFile.writeAsString(jsonEncode(updatedProject.toJson()));
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final beforeProject = await projectFile.readAsBytes();
    final beforeMap = await mapFile.readAsBytes();
    final projection = await const RuntimeProjectProjectionBuilder().build(projectRoot: fixture.root, profile: _profile());
    expect(projection.project.models3d.single.rampProfile, isNull);
    final exported = MapData.fromJson(jsonDecode(utf8.decode(projection.payloadFiles['project/maps/map.json']!)));
    expect(exported.spatialScene!.navigation.ramps.single, map.spatialScene!.navigation.ramps.single);
    final built = const GamePackageBuilder().build(manifest: spatialManifest(), payloadFiles: projection.payloadFiles);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.gameId, 'games.example.exploration');
    expect(await projectFile.readAsBytes(), beforeProject);
    expect(await mapFile.readAsBytes(), beforeMap);
  });
  test(
      'runtime removes authoring-only ramp profiles without mutating source models',
      () async {
    final source = await _source();
    final profile = Model3dRampProfile(
        x: 0,
        z: 0,
        width: 1,
        depth: 1,
        lowHeight: 0,
        highHeight: 1,
        direction: SpatialRampDirection.north);
    final project = source.project.copyWith(
        models3d: source.project.models3d
            .map((model) => model.copyWith(rampProfile: profile))
            .toList());
    final result = projectRuntimeModelResources(
        project: project, maps: [source.map], assets: source.assets);
    expect(result.project.models3d, isNotEmpty);
    expect(
        result.project.models3d
            .every((model) => !model.toJson().containsKey('rampProfile')),
        isTrue);
    expect(project.models3d.every((model) => model.rampProfile == profile),
        isTrue);
  });
  test('export omits unused models and assets while preserving authoring data',
      () async {
    final fixture = await _fixture();
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: fixture.root, profile: _profile());

    expect(projection.project.models3d.map((model) => model.id), ['model']);
    expect(projection.project.resourceLibraryCatalog.entries, isEmpty);
    expect(projection.payloadFiles,
        isNot(contains('project/assets/models3d/unused.glb')));
    expect(projection.payloadFiles,
        isNot(contains('project/${fixture.unusedBlob}')));
    final catalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
            projection.payloadFiles['project/$assetCatalogStorageKey']!))
        as Map<String, dynamic>);
    expect(catalog.records.map((record) => record.id),
        isNot(contains('unused-source')));
    await _expectSourceUnchanged(fixture.root, fixture.files);
  });

  test('unused assets do not consume the projection entry budget', () async {
    final fixture = await _fixture();
    final projection = await const RuntimeProjectProjectionBuilder(
      maxPayloadEntries: 7,
    ).build(projectRoot: fixture.root, profile: _profile());

    expect(projection.payloadFiles, hasLength(7));
    expect(projection.project.maps, hasLength(1));
    expect(projection.project.models3d, hasLength(1));
    await _expectSourceUnchanged(fixture.root, fixture.files);
  });

  test('a model used only by another map remains in the package', () async {
    final fixture = await _fixture(secondMapUsesModel: true);
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: fixture.root, profile: _profile());

    expect(projection.project.models3d.map((model) => model.id),
        ['model', 'unused']);
    expect(projection.payloadFiles,
        contains('project/assets/models3d/unused.glb'));
    expect(projection.payloadFiles, contains('project/${fixture.unusedBlob}'));
    expect(projection.project.maps, hasLength(2));
    await _expectSourceUnchanged(fixture.root, fixture.files);
  });

  test('a shared artifact stays available after its unused alias is omitted',
      () async {
    final fixture = await _fixture(sharedArtifact: true);
    final projection = await const RuntimeProjectProjectionBuilder(
      maxPayloadEntries: 7,
    ).build(projectRoot: fixture.root, profile: _profile());

    expect(projection.project.models3d.map((model) => model.id), ['model']);
    expect(projection.payloadFiles, contains('project/${fixture.unusedBlob}'));
    expect(projection.payloadFiles,
        isNot(contains('project/assets/models3d/unused.glb')));
    await _expectSourceUnchanged(fixture.root, fixture.files);
  });

  test('compiled dialogue references keep their model available', () async {
    final fixture = await _fixture(dialogueMentionsModel: true);
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: fixture.root, profile: _profile());

    expect(projection.project.models3d.map((model) => model.id),
        ['model', 'unused']);
    expect(projection.payloadFiles, contains('project/${fixture.unusedBlob}'));
    await _expectSourceUnchanged(fixture.root, fixture.files);
  });

  test('unused patterns do not keep obsolete models alive', () async {
    final source = await _source();
    final project = source.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(patterns: [_pattern()]));
    final result = projectRuntimeModelResources(
        project: project, maps: [source.map], assets: source.assets);

    expect(result.project.smartTileCatalog.patterns, isEmpty);
    expect(result.project.models3d.map((model) => model.id), ['model']);
    expect(result.excludedLogicalPaths, {'assets/models3d/unused.glb'});
    expect(project.smartTileCatalog.patterns, hasLength(1));
    expect(project.models3d, hasLength(2));
  });

  test('a stamped pattern retains its model and playback parameters', () async {
    final source = await _source();
    final pattern = _pattern();
    final project = source.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
            presets: [_preset('model')], patterns: [pattern]));
    final map = source.map.copyWith(layers: [
      ...source.map.layers,
      _layer(source.map).copyWith(patternStrokes: [
        const SmartTilePatternStroke(
            id: 'stamp', patternId: 'pattern', cells: [GridPos(x: 1, y: 1)])
      ])
    ]);
    final result = projectRuntimeModelResources(
        project: project, maps: [map], assets: source.assets);

    expect(result.project.models3d, project.models3d);
    expect(result.project.smartTileCatalog.patterns, [pattern]);
    expect(result.excludedLogicalPaths, isEmpty);
    expect(map.layers.whereType<SmartTileLayer>().single.patternStrokes,
        hasLength(1));
  });

  test('all candidates of a used preset remain even on an empty field',
      () async {
    final source = await _source();
    final preset = _preset('unused');
    final project = source.project
        .copyWith(smartTileCatalog: ProjectSmartTileCatalog(presets: [preset]));
    final map =
        source.map.copyWith(layers: [...source.map.layers, _layer(source.map)]);
    final result = projectRuntimeModelResources(
        project: project, maps: [map], assets: source.assets);

    expect(result.project.models3d, project.models3d);
    expect(result.project.smartTileCatalog.presets, [preset]);
    expect(result.excludedLogicalPaths, isEmpty);
  });

  for (final reference in [
    'unused',
    'unused-source',
    'assets/models3d/unused.glb'
  ]) {
    test('project metadata reference $reference protects the asset', () async {
      final source = await _source();
      final project = source.project
          .copyWith(globalProperties: {'runtimeResource': reference});
      final result = projectRuntimeModelResources(
          project: project, maps: [source.map], assets: source.assets);

      expect(result.assets.records.map((record) => record.id),
          contains('unused-source'));
      expect(result.excludedLogicalPaths, isEmpty);
      if (reference == 'unused') {
        expect(result.project.models3d, project.models3d);
      }
    });
  }

  test('incomplete map inventory cannot prune resources', () async {
    final source = await _source();
    expect(
        () => projectRuntimeModelResources(
            project: source.project, maps: [], assets: source.assets),
        throwsArgumentError);
  });

  test('2D exports retain their existing projection', () async {
    final source = await _source();
    final project = source.project.copyWith(settings: ProjectSettings());
    final result = projectRuntimeModelResources(
        project: project, maps: [source.map], assets: source.assets);

    expect(identical(result.project, project), isTrue);
    expect(identical(result.assets, source.assets), isTrue);
    expect(result.excludedLogicalPaths, isEmpty);
  });
}

Future<({Directory root, Map<String, List<int>> files, String unusedBlob})>
    _fixture(
        {bool secondMapUsesModel = false,
        bool sharedArtifact = false,
        bool dialogueMentionsModel = false}) async {
  final root = await Directory.systemTemp.createTemp('unused-model-export-');
  addTearDown(() => root.delete(recursive: true));
  final files = spatialPayload();
  var project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>);
  final bytes = sharedArtifact
      ? files['project/assets/models3d/model.glb']!
      : triangleGlb(edit: (json) {
          json['nodes'][0].remove('translation');
          json['nodes'][0].remove('scale');
          json['extras'] = {'fixture': 'unused-model'};
        });
  final artifact =
      ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
  final unusedBlob = assetBlobStorageKey(artifact);
  final catalog = AssetCatalog.fromJson(
      jsonDecode(utf8.decode(files['project/$assetCatalogStorageKey']!))
          as Map<String, dynamic>);
  final unusedRecord = AssetRecord(
      id: 'unused-source',
      logicalPath: 'assets/models3d/unused.glb',
      artifact: artifact);
  files['project/${unusedRecord.logicalPath}'] = bytes;
  files['project/$unusedBlob'] = bytes;
  files['project/$assetCatalogStorageKey'] = utf8.encode(jsonEncode(
      AssetCatalog(records: [...catalog.records, unusedRecord]).toJson()));
  project = project.copyWith(
      models3d: [
        ...project.models3d,
        ProjectModel3dEntry(
            id: 'unused',
            name: 'Unused model',
            sourceAssetId: unusedRecord.id,
            relativePath: unusedRecord.logicalPath,
            inspection: const GlbModel3dInspector().inspect(bytes))
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
        ResourceLibraryEntry(resourceKind: 'model3d', resourceId: 'unused')
      ]));
  if (secondMapUsesModel) {
    final first = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!))
            as Map<String, dynamic>);
    final second = first.copyWith(
        id: 'second',
        spatialScene: first.spatialScene!.copyWith(instances: [
          SpatialModelInstance(
              id: first.spatialScene!.instances.first.id,
              modelId: 'unused',
              position: first.spatialScene!.instances.first.position)
        ]));
    project = project.copyWith(maps: [
      ...project.maps,
      const ProjectMapEntry(
          id: 'second', name: 'Second', relativePath: 'maps/second.json')
    ]);
    files['project/maps/second.json'] =
        utf8.encode(jsonEncode(second.toJson()));
  }
  if (dialogueMentionsModel) {
    project = project.copyWith(dialogues: [
      const ProjectDialogueEntry(
          id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
    ]);
    files['project/dialogues/talk.yarn'] =
        utf8.encode('title: Start\n---\nunused\n===\n');
  }
  files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key.substring(8)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  return (root: root, files: files, unusedBlob: unusedBlob);
}

Future<({ProjectManifest project, MapData map, AssetCatalog assets})>
    _source() async {
  final fixture = await _fixture();
  return (
    project: ProjectManifest.fromJson(
        jsonDecode(utf8.decode(fixture.files['project/project.json']!))
            as Map<String, dynamic>),
    map: MapData.fromJson(
        jsonDecode(utf8.decode(fixture.files['project/maps/map.json']!))
            as Map<String, dynamic>),
    assets: AssetCatalog.fromJson(jsonDecode(
            utf8.decode(fixture.files['project/$assetCatalogStorageKey']!))
        as Map<String, dynamic>)
  );
}

ProjectSmartTilePattern _pattern() => const ProjectSmartTilePattern(
        id: 'pattern',
        name: 'Pattern',
        usage: SmartTileUsage.path,
        width: 1,
        height: 1,
        cells: [
          SmartTilePatternCell(x: 0, y: 0, parts: [
            SmartTileVisualPart(
                source: SmartTileVisualSource.model3d(
                    modelId: 'unused', animationIndex: 0, followTerrain: false))
          ])
        ]);

ProjectSmartTilePreset _preset(String modelId) => ProjectSmartTilePreset(
        id: 'path',
        name: 'Path',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: [
          'grass'
        ],
        rules: [
          SmartTileRule(
              id: 'rule',
              centerMatch: const SmartTileSlotMatch.any(),
              candidates: [
                SmartTileCandidate(id: 'candidate', parts: [
                  SmartTileVisualPart(
                      source: SmartTileVisualSource.model3d(modelId: modelId))
                ])
              ])
        ]);

SmartTileLayer _layer(MapData map) => MapLayer.smartTile(
        id: 'path',
        name: 'Path',
        presetId: 'path',
        usage: SmartTileUsage.path,
        field: SmartTileField.cell(
            semanticCells: List.filled(map.size.width * map.size.height, 0)))
    as SmartTileLayer;

Future<void> _expectSourceUnchanged(
    Directory root, Map<String, List<int>> expected) async {
  for (final entry in expected.entries) {
    expect(await File('${root.path}/${entry.key.substring(8)}').readAsBytes(),
        entry.value,
        reason: entry.key);
  }
}

GamePackageExportProfile _profile() => GamePackageExportProfile(
    gameId: 'games.example.unused-models',
    gameVersion: '0.1.0',
    title: 'Unused resources',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);
