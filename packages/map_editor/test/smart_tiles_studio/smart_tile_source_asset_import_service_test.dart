import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('stages an exact file then canonically imports asset and tileset',
      () async {
    final gateway = _FakeGateway(_pngReference);
    final service = SmartTileSourceAssetImportService(
      gateway: gateway,
      imageLoader: const _FakeImageLoader(width: 96, height: 64),
    );

    final result = await service.importImage(
      projectRootPath: '/project',
      sourcePath: '/outside/ERW Grass.png',
      displayName: 'ERW Grass.png',
    );

    expect(gateway.stagedPaths, ['/outside/ERW Grass.png']);
    expect(gateway.actions.map((item) => item.actionId), [
      'asset.import',
      'tileset.upsert',
    ]);
    expect(gateway.actions.first.parameters.toString(),
        isNot(contains('/outside')));
    expect(
      gateway.actions.first.parameters['logicalPath'],
      assetBlobStorageKey(_pngReference),
    );
    expect(
      (gateway.actions.last.parameters['tileset']! as Map)['source'],
      containsPair('pixelWidth', 96),
    );
    expect(
      gateway.actions.last.parameters,
      isNot(contains('atlas')),
    );
    expect(result.tileset.name, 'ERW Grass');
    expect(result.tileset.relativePath, assetBlobStorageKey(_pngReference));
    expect(result.image.width, 96);
    expect(result.manifest.tilesets, [result.tileset]);
  });

  test('rejects staged non-image bytes before planning a project mutation',
      () async {
    final gateway = _FakeGateway(
      ContentArtifactRef(
        digest: 'sha256:${List<String>.filled(64, 'b').join()}',
        mediaType: 'text/plain',
        byteLength: 12,
      ),
    );
    final service = SmartTileSourceAssetImportService(
      gateway: gateway,
      imageLoader: const _FakeImageLoader(width: 1, height: 1),
    );

    await expectLater(
      service.importImage(
        projectRootPath: '/project',
        sourcePath: '/outside/not-image.txt',
        displayName: 'not-image.txt',
      ),
      throwsA(
        isA<SmartTileSourceImportException>().having(
          (error) => error.code,
          'code',
          'smart_tile.source_not_image',
        ),
      ),
    );
    expect(gateway.actions, isEmpty);
  });

  test('executes the complete editor adapter flow from an external PNG',
      () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_smart_tile_source_',
    );
    final projectRoot = await Directory(
      p.join(sandbox.path, 'project'),
    ).create();
    final source = File(p.join(sandbox.path, 'external.png'));
    await source.writeAsBytes(_onePixelPng, flush: true);
    const manifest = ProjectManifest(
      name: 'Smart Tile source integration',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      jsonEncode(manifest.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(() async {
      await mutations.closeAll();
      await queries.closeAll();
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });
    final service = SmartTileSourceAssetImportService(
      gateway: CanonicalSmartTileSourceAssetGateway(
        mutations: mutations,
        queries: queries,
      ),
      imageLoader: const FileSmartTileAtlasImageLoader(),
    );

    final result = await service.importImage(
      projectRootPath: projectRoot.path,
      sourcePath: source.path,
      displayName: 'External grass.png',
    );

    expect(result.tileset.name, 'External grass');
    expect(result.image.width, 1);
    expect(result.image.height, 1);
    expect(result.manifest.tilesets, contains(result.tileset));
    expect(
      await File(p.join(projectRoot.path, result.tileset.relativePath))
          .exists(),
      isTrue,
    );
    expect(
      result.tileset.relativePath,
      allOf(startsWith('assets/.pokemap-store/'), endsWith('.blob')),
    );
  });
}

final _pngReference = ContentArtifactRef(
  digest: 'sha256:${List<String>.filled(64, 'a').join()}',
  mediaType: 'image/png',
  byteLength: 128,
);

final class _FakeGateway implements SmartTileSourceAssetGateway {
  _FakeGateway(this.reference);

  final ContentArtifactRef reference;
  final List<String> stagedPaths = <String>[];
  final List<_AppliedAction> actions = <_AppliedAction>[];
  String revision = 'r0';
  ProjectManifest manifest = const ProjectManifest(
    name: 'test',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    stagedPaths.add(sourcePath);
    return reference;
  }

  @override
  Future<SmartTileSourceApplyResult> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    expect(expectedRevision, revision);
    actions.add(_AppliedAction(actionId, parameters));
    revision = 'r${actions.length}';
    if (actionId == 'tileset.upsert') {
      final tileset = ProjectTilesetEntry.fromJson(
        Map<String, dynamic>.from(parameters['tileset']! as Map),
      );
      manifest = manifest.copyWith(tilesets: <ProjectTilesetEntry>[tileset]);
    }
    return SmartTileSourceApplyResult(
      revision: revision,
      receiptId: 'receipt-${actions.length}',
    );
  }

  @override
  Future<SmartTileSourceCanonicalSnapshot> load({
    required String projectRootPath,
  }) async =>
      SmartTileSourceCanonicalSnapshot(
        revision: revision,
        manifest: manifest,
      );
}

final class _AppliedAction {
  const _AppliedAction(this.actionId, this.parameters);

  final String actionId;
  final Map<String, Object?> parameters;
}

final class _FakeImageLoader implements SmartTileAtlasImageLoader {
  const _FakeImageLoader({required this.width, required this.height});

  final int width;
  final int height;

  @override
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  }) async =>
      SmartTileAtlasImageLoadResult(
        status: SmartTileAtlasImageLoadStatus.loaded,
        message: 'loaded from $projectRootPath/${tileset.relativePath}',
        image: SmartTileAtlasImage(
          absolutePath: '$projectRootPath/${tileset.relativePath}',
          bytes: Uint8List.fromList(const <int>[0]),
          width: width,
          height: height,
          columnAlphaCoverage: List<double>.filled(width, 1),
          rowAlphaCoverage: List<double>.filled(height, 1),
        ),
      );
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
