import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

import '../../../map_core/test/support/spatial_border_ground_surface_fixture.dart';
import '../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('global Border-only ground atlas is admitted and loadable by runtime session', () async {
    final owned = Directory(
      '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/runtime-border-ground',
    );
    await owned.create(recursive: true);
    final root = await owned.createTemp('bundle_');
    addTearDown(() async {
      await root.delete(recursive: true);
      if (await owned.list().isEmpty) await owned.delete();
    });
    final files = spatialPayload();
    final base = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)),
    );
    final groundFixture = surfaceFixture();
    final grassBytes = image.encodePng(image.Image(width: 16, height: 16));
    final grassRecord = AssetRecord(
      id: 'grass-source',
      logicalPath: 'assets/tilesets/grass.png',
      artifact: ContentArtifactRef.fromBytes(
        grassBytes,
        mediaType: 'image/png',
      ),
      usages: const ['tileset'],
    );
    final assets = AssetCatalog.fromJson(
      jsonDecode(utf8.decode(files['project/assets/.pokemap-assets.json']!)),
    );
    files['project/assets/.pokemap-assets.json'] = utf8.encode(
      jsonEncode(
        AssetCatalog(records: [...assets.records, grassRecord]).toJson(),
      ),
    );
    files['project/${grassRecord.logicalPath}'] = grassBytes;
    files['project/${assetBlobStorageKey(grassRecord.artifact)}'] = grassBytes;
    final projectJson = base.toJson();
    projectJson['borderCatalog'] = jsonDecode(
      jsonEncode(groundFixture.project.toJson()['borderCatalog'])
          .replaceAll('"unit"', '"model"'),
    );
    final project = ProjectManifest.fromJson(projectJson).copyWith(
      smartTileCatalog: groundFixture.project.smartTileCatalog,
      tilesets: [
        ...base.tilesets,
        const ProjectTilesetEntry(
          id: 'grass',
          name: 'Border-only grass',
          relativePath: 'assets/tilesets/grass.png',
          source: ProjectTilesetSource.regularAtlas(
            assetId: 'grass-source',
            pixelWidth: 16,
            pixelHeight: 16,
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      ],
    );
    for (final entry in files.entries.where(
      (entry) => entry.key != 'project/project.json',
    )) {
      final file = File(
        '${root.path}/${entry.key.substring('project/'.length)}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'exterior-ground',
      project: project,
    );
    final playable = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!)),
    );
    final border = ExteriorDecorationBorder(
      id: 'fence',
      layerId: 'border',
      originX: -4,
      originZ: 0,
      width: 4,
      depth: 8,
      feature: (groundFixture.map.layers.single as BorderLayer)
          .content
          .features
          .single,
    );
    final definition = MapExteriorDecoration(
      mapId: 'map',
      playableWidth: 8,
      playableDepth: 8,
      west: 4,
    );
    final applied = applyExteriorDecorationBorderResolution(
      border,
      resolveExteriorDecorationBorder(
        manifest: project,
        decoration: definition,
        border: border,
        playableMap: playable,
      ),
    );
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: const LocalProjectFileReader(),
    );
    final authoring = LocalMapExteriorDecorationAuthoring(policy: policy);
    final initial = await authoring.inspect(
      projectRoot: root.path,
      mapId: 'map',
    );
    final configured = await authoring.configure(
      projectRoot: root.path,
      mapId: 'map',
      expectedRevision: initial.revision,
      decoration: definition,
      operationId: 'configure-ground',
    );
    await authoring.setBorder(
      projectRoot: root.path,
      mapId: 'map',
      expectedRevision: configured.afterRevision,
      border: applied,
      operationId: 'store-ground-border',
    );
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: 'map',
    );
    addTearDown(() => bundle.projectCatalog?.dispose());
    expect(bundle.map.layers, isEmpty);
    expect(bundle.exteriorDecoration!.sectors, isEmpty);
    expect(bundle.exteriorDecoration!.borders, hasLength(1));
    expect(
      bundle.manifest.smartTileCatalog.presets.map((preset) => preset.id),
      contains('grass-terrain'),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      isNot(contains('grass')),
    );
    final session = await SpatialExplorationSession.load(bundle);
    addTearDown(session.dispose);
    final loaded = await session.groundImageBytesForBundle(bundle, 'grass');
    expect(loaded, grassBytes);
    expect(image.decodePng(loaded)!.width, 16);
    expect(bundle.runtimeImageAbsolutePathsById['grass'], endsWith('.blob'));
  });
}
