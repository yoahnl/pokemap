import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_tiled_wang_import_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  final licensedErwTsx = Platform.environment['POKEMAP_STN07_ERW_TSX'];
  final licensedErwRoot = Platform.environment['POKEMAP_ERW_ROOT'];

  test(
    'imports and reopens all four locally licensed ERW image collections',
    () async {
      final tilesetRoot = _erwTilesetRoot(licensedErwRoot!);
      final sources = <SmartTileTiledWangSource>[];
      for (final fileName in _erwCollectionFiles) {
        sources.add(
          await loadSmartTileTiledWangSource(
              p.join(tilesetRoot.path, fileName)),
        );
      }
      expect(sources, everyElement(isA<SmartTileTiledWangSource>()));
      expect(sources.every((source) => source.isImageCollection), isTrue);
      expect(
        sources.fold<int>(
          0,
          (total, source) =>
              total + source.tilesetDocument.dependencyClosure.images.length,
        ),
        1318,
      );

      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_erw_collections_',
      );
      final projectRoot = await Directory(
        p.join(sandbox.path, 'project'),
      ).create();
      const manifest = ProjectManifest(
        name: 'ERW collection proof',
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
      final service = SmartTileTiledWangImportService(
        gateway: CanonicalSmartTileSourceAssetGateway(
          mutations: mutations,
          queries: queries,
        ),
      );

      for (final source in sources) {
        final result = await service.import(
          projectRootPath: projectRoot.path,
          source: source,
          selections: const <TiledWangSetSelection>[],
        );
        expect(result.presetIds, isEmpty);
      }
      await mutations.closeAll();
      await queries.closeAll();

      final projectText =
          await File(p.join(projectRoot.path, 'project.json')).readAsString();
      expect(projectText, isNot(contains(licensedErwRoot)));
      final reopened = ProjectManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(projectText) as Map),
      );
      ProjectValidator.validate(reopened);
      expect(reopened.tilesets, hasLength(4));
      expect(
        reopened.tilesets.fold<int>(0, (total, tileset) {
          final collection =
              tileset.source as ProjectImageCollectionTilesetSource;
          return total + collection.tileDefinitions.length;
        }),
        1318,
      );
      final catalog = AssetCatalog.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            await File(p.join(projectRoot.path, assetCatalogStorageKey))
                .readAsString(),
          ) as Map,
        ),
      );
      expect(catalog.records, isNotEmpty);
      for (final asset in catalog.records) {
        expect(
          await File(
            p.join(projectRoot.path, assetBlobStorageKey(asset.artifact)),
          ).exists(),
          isTrue,
        );
      }
    },
    skip: licensedErwRoot == null
        ? 'Set POKEMAP_ERW_ROOT to the locally licensed ERW pack root.'
        : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );

  test(
    'accepts a user-owned ERW Wang atlas without copying licensed assets',
    () async {
      final source = await loadSmartTileTiledWangSource(licensedErwTsx!);
      final document = source.document!;
      final selections = <TiledWangSetSelection>[
        for (var index = 0; index < document.wangSets.length; index++)
          TiledWangSetSelection(
            wangSetIndex: index,
            usage: SmartTileUsage.forestSurface,
          ),
      ];
      final bundle = compileTiledWangImport(
        document: document,
        importId: source.importId,
        tilesetId: 'licensed-erw-atlas',
        selections: selections,
      );
      final diagnostics = validateProjectSmartTileCatalog(
        catalog: ProjectSmartTileCatalog(
          atlases: <ProjectSmartTileAtlas>[bundle.atlas],
          materials: bundle.materials,
          animations: bundle.animations,
          presets: bundle.presets,
        ),
        projectTilesetIds: const <String>['licensed-erw-atlas'],
      );

      expect(source.imagePath, isNot(equals(licensedErwTsx)));
      expect(document.wangSets, isNotEmpty);
      expect(bundle.presets, hasLength(document.wangSets.length));
      expect(
        bundle.presets.map((preset) => preset.usage),
        everyElement(SmartTileUsage.forestSurface),
      );
      expect(
        diagnostics.where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
    },
    skip: licensedErwTsx == null
        ? 'Set POKEMAP_STN07_ERW_TSX to a locally licensed ERW TSX.'
        : false,
  );

  test('loads a TSX preview and resolves its relative atlas image', () async {
    final root = await Directory.systemTemp.createTemp('pokemap_tsx_preview_');
    addTearDown(() async => root.delete(recursive: true));
    final image = File(p.join(root.path, 'images', 'road.png'));
    await image.parent.create(recursive: true);
    await image.writeAsBytes(img.encodePng(img.Image(width: 1, height: 1)));
    final tsx = File(p.join(root.path, 'tsx', 'road.tsx'));
    await tsx.parent.create(recursive: true);
    await tsx.writeAsString(
      _tsx.replaceFirst('road.png', '../images/road.png'),
    );

    final source = await loadSmartTileTiledWangSource(tsx.path);

    expect(source.displayName, 'road.tsx');
    expect(source.document!.wangSets.single.name, 'Road');
    expect(source.imagePath, p.normalize(image.path));
    expect(source.importId, startsWith('road-'));
    expect(source.importId, hasLength('road-'.length + 12));
  });

  test('rejects mismatched image dimensions before any import mutation',
      () async {
    final root = await Directory.systemTemp.createTemp('pokemap_tsx_size_');
    addTearDown(() async => root.delete(recursive: true));
    final image = File(p.join(root.path, 'road.png'));
    await image.writeAsBytes(img.encodePng(img.Image(width: 2, height: 1)));
    final tsx = File(p.join(root.path, 'road.tsx'));
    await tsx.writeAsString(_tsx);

    await expectLater(
      loadSmartTileTiledWangSource(tsx.path),
      throwsA(
        isA<SmartTileTiledWangImportServiceException>().having(
          (error) => error.code,
          'code',
          'smart_tile.tiled_wang.image_dimensions_mismatch',
        ),
      ),
    );
  });

  test('stages the image then applies one composite Tiled action', () async {
    final source = SmartTileTiledWangSource(
      tsxPath: '/outside/road.tsx',
      imagePath: '/outside/road.png',
      imagePaths: const <String, String>{
        'road.png': '/outside/road.png',
      },
      displayName: 'road.tsx',
      tsx: _tsx,
      importId: 'road-123456789abc',
      tilesetDocument: parseTiledTileset(_tsx),
      document: parseTiledWangTileset(_tsx),
    );
    final gateway = _Gateway();
    final service = SmartTileTiledWangImportService(
      gateway: gateway,
    );

    final result = await service.import(
      projectRootPath: '/project',
      source: source,
      selections: const <TiledWangSetSelection>[
        TiledWangSetSelection(
          wangSetIndex: 0,
          usage: SmartTileUsage.path,
        ),
      ],
    );

    expect(gateway.stagedPaths, <String>[source.imagePath]);
    expect(gateway.actionId, 'tileset.tiled.import');
    expect(gateway.parameters?['tsx'], _tsx);
    expect(gateway.parameters?['importId'], source.importId);
    expect(
      gateway.parameters?['tilesetId'],
      'smart-tile-tileset-${_pngReference.hexDigest.substring(0, 16)}',
    );
    expect(gateway.parameters?['artifactHandle'], _pngReference.handle);
    expect(gateway.parameters?['selections'], <Object?>[
      <String, Object?>{'wangSetIndex': 0, 'usage': 'path'},
    ]);
    expect(gateway.expectedRevision, 'revision-1');
    expect(result.presetIds, <String>['road-123456789abc-w0-preset']);
    expect(result.receiptId, 'receipt-composite-tiled');
    expect(result.manifest.smartTileCatalog.presets.single.usage,
        SmartTileUsage.path);
  });

  test('executes one composite receipt through the real editor adapters',
      () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_tiled_tileset_editor_',
    );
    final projectRoot = await Directory(
      p.join(sandbox.path, 'project'),
    ).create();
    final externalRoot = await Directory(
      p.join(sandbox.path, 'external'),
    ).create();
    final image = File(p.join(externalRoot.path, 'road.png'));
    await image.writeAsBytes(img.encodePng(img.Image(width: 1, height: 1)));
    final tsx = File(p.join(externalRoot.path, 'road.tsx'));
    await tsx.writeAsString(_tsx);
    const manifest = ProjectManifest(
      name: 'Tiled editor integration',
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
    final service = SmartTileTiledWangImportService(
      gateway: CanonicalSmartTileSourceAssetGateway(
        mutations: mutations,
        queries: queries,
      ),
    );

    final result = await service.import(
      projectRootPath: projectRoot.path,
      source: await loadSmartTileTiledWangSource(tsx.path),
      selections: const <TiledWangSetSelection>[
        TiledWangSetSelection(
          wangSetIndex: 0,
          usage: SmartTileUsage.path,
        ),
      ],
    );

    final receipt = mutations.lastAppliedReceipt!;
    expect(receipt.actionId, 'tileset.tiled.import');
    expect(result.receiptId, receipt.receiptId);
    expect(receipt.diff.entries, hasLength(3));
    expect(result.manifest.tilesets, hasLength(1));
    expect(result.manifest.tilesets.single.source,
        isA<ProjectRegularAtlasTilesetSource>());
    expect(result.manifest.smartTileCatalog.presets.single.usage,
        SmartTileUsage.path);
    expect(
      await File(p.join(projectRoot.path, assetCatalogStorageKey)).exists(),
      isTrue,
    );
    expect(
      await File(
        p.join(
          projectRoot.path,
          result.manifest.tilesets.single.relativePath,
        ),
      ).exists(),
      isTrue,
    );
  });

  test('imports and reopens a collection through the real editor adapters',
      () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_tiled_collection_editor_',
    );
    final projectRoot = await Directory(
      p.join(sandbox.path, 'project'),
    ).create();
    final externalRoot = await Directory(
      p.join(sandbox.path, 'external'),
    ).create();
    final sprites = await Directory(
      p.join(externalRoot.path, 'sprites'),
    ).create();
    for (final name in const <String>['flower.png', 'water.png']) {
      await File(p.join(sprites.path, name)).writeAsBytes(
        img.encodePng(img.Image(width: 1, height: 1)),
      );
    }
    final tsx = File(p.join(externalRoot.path, 'props.tsx'));
    await tsx.writeAsString(_collectionTsx);
    const manifest = ProjectManifest(
      name: 'Tiled collection integration',
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
    final service = SmartTileTiledWangImportService(
      gateway: CanonicalSmartTileSourceAssetGateway(
        mutations: mutations,
        queries: queries,
      ),
    );

    final source = await loadSmartTileTiledWangSource(tsx.path);
    expect(source.isImageCollection, isTrue);
    expect(source.document, isNull);
    final result = await service.import(
      projectRootPath: projectRoot.path,
      source: source,
      selections: const <TiledWangSetSelection>[],
    );

    expect(result.presetIds, isEmpty);
    expect(mutations.lastAppliedReceipt?.actionId, 'tileset.tiled.import');
    final serialized = ProjectManifest.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          await File(p.join(projectRoot.path, 'project.json')).readAsString(),
        ) as Map,
      ),
    );
    final collection = serialized.tilesets.single.source
        as ProjectImageCollectionTilesetSource;
    expect(collection.tileDefinitions.map((tile) => tile.tileId), <int>[5, 9]);
    expect(collection.pages, hasLength(1));
    final catalog = AssetCatalog.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          await File(p.join(projectRoot.path, assetCatalogStorageKey))
              .readAsString(),
        ) as Map,
      ),
    );
    expect(catalog.records, hasLength(1));
    expect(
      await File(
        p.join(
          projectRoot.path,
          assetBlobStorageKey(catalog.records.single.artifact),
        ),
      ).exists(),
      isTrue,
    );
  });

  test('rejects a stale snapshot after canonical Wang apply', () async {
    final source = SmartTileTiledWangSource(
      tsxPath: '/outside/road.tsx',
      imagePath: '/outside/road.png',
      imagePaths: const <String, String>{
        'road.png': '/outside/road.png',
      },
      displayName: 'road.tsx',
      tsx: _tsx,
      importId: 'road-123456789abc',
      tilesetDocument: parseTiledTileset(_tsx),
      document: parseTiledWangTileset(_tsx),
    );
    final gateway = _Gateway(staleAfterApply: true);
    final service = SmartTileTiledWangImportService(
      gateway: gateway,
    );

    expect(
      () => service.import(
        projectRootPath: '/project',
        source: source,
        selections: const <TiledWangSetSelection>[
          TiledWangSetSelection(
            wangSetIndex: 0,
            usage: SmartTileUsage.path,
          ),
        ],
      ),
      throwsA(
        isA<SmartTileTiledWangImportServiceException>().having(
          (error) => error.code,
          'code',
          'smart_tile.tiled_wang.snapshot_stale',
        ),
      ),
    );
  });
}

Directory _erwTilesetRoot(String rootPath) {
  final candidates = <Directory>[
    Directory(p.join(rootPath, 'TiledMap Editor', 'Tilesets')),
    Directory(p.join(rootPath, 'Tilesets')),
    Directory(rootPath),
  ];
  return candidates.firstWhere(
    (candidate) => File(
      p.join(candidate.path, _erwCollectionFiles.first),
    ).existsSync(),
    orElse: () => throw StateError('Unable to locate the ERW Tilesets folder.'),
  );
}

const _erwCollectionFiles = <String>[
  'Atlas-Props-sheet1-sprites.tsx',
  'Atlas-Props-sheet2-sprites.tsx',
  'Atlas-props-sheet3-sprites.tsx',
  'Atlas-Props-sheet4-sprites.tsx',
];

final class _Gateway implements SmartTileSourceAssetGateway {
  _Gateway({this.staleAfterApply = false});

  final bool staleAfterApply;
  var applied = false;
  String? actionId;
  Map<String, Object?>? parameters;
  String? expectedRevision;
  final List<String> stagedPaths = <String>[];
  final ProjectManifest manifest = const ProjectManifest(
    name: 'Project',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  @override
  Future<SmartTileSourceApplyResult> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    this.actionId = actionId;
    this.parameters = parameters;
    this.expectedRevision = expectedRevision;
    applied = true;
    return const SmartTileSourceApplyResult(
      revision: 'revision-2',
      receiptId: 'receipt-composite-tiled',
    );
  }

  @override
  Future<SmartTileSourceCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    if (!applied || staleAfterApply) {
      return SmartTileSourceCanonicalSnapshot(
        revision: 'revision-1',
        manifest: manifest,
      );
    }
    final selections = (parameters!['selections']! as List)
        .cast<Map<String, Object?>>()
        .map(
          (selection) => TiledWangSetSelection(
            wangSetIndex: selection['wangSetIndex']! as int,
            usage: SmartTileUsage.values.byName(selection['usage']! as String),
          ),
        );
    final bundle = compileTiledWangImport(
      document: parseTiledWangTileset(parameters!['tsx']! as String),
      importId: parameters!['importId']! as String,
      tilesetId: parameters!['tilesetId']! as String,
      selections: selections,
    );
    final tileset = ProjectTilesetEntry(
      id: parameters!['tilesetId']! as String,
      name: parameters!['displayName']! as String,
      relativePath: parameters!['logicalPath']! as String,
      source: ProjectRegularAtlasTilesetSource(
        assetId: parameters!['assetId']! as String,
        pixelWidth: 1,
        pixelHeight: 1,
        tileWidth: 1,
        tileHeight: 1,
      ),
    );
    return SmartTileSourceCanonicalSnapshot(
      revision: 'revision-2',
      manifest: manifest.copyWith(
        tilesets: <ProjectTilesetEntry>[tileset],
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: <ProjectSmartTileAtlas>[bundle.atlas],
          materials: bundle.materials,
          animations: bundle.animations,
          presets: bundle.presets,
        ),
      ),
    );
  }

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    stagedPaths.add(sourcePath);
    return _pngReference;
  }
}

final _pngReference = ContentArtifactRef(
  digest: 'sha256:${List<String>.filled(64, 'a').join()}',
  mediaType: 'image/png',
  byteLength: 128,
);

const _tsx = '''
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" width="1" height="1"/>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';

const _collectionTsx = '''
<tileset name="Props" tilewidth="1" tileheight="1" tilecount="2" columns="0">
  <tileoffset x="2" y="-3"/>
  <tile id="5">
    <properties><property name="name" value="Flower"/></properties>
    <image source="sprites/flower.png" width="1" height="1"/>
  </tile>
  <tile id="9">
    <image source="sprites/water.png" width="1" height="1"/>
    <animation><frame tileid="5" duration="120"/></animation>
  </tile>
</tileset>
''';
