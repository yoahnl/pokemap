import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/original_autotile_fixture.dart';
import 'support/native_writer_fixture.dart';

Future<LiteralTileComposition> _compose(LiteralTileFixture fixture,
        {List<int> selected = const [1],
        List<LiteralDependencyDecision> decisions = const [],
        NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation,
        String parentPath = '/private/tmp/original-literal-output'}) =>
    const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: selected,
      projectName: 'Original literal fixture',
      parentPath: parentPath,
      folderName: 'original-literal-project',
      sourceRootPath: fixture.sourceRootPath,
      dependencyDecisions: decisions,
      limits: limits,
      cancellation: cancellation,
    );

Matcher get _boundedFailure => anyOf(isA<NativeWriteException>(),
    isA<BinaryDecodeError>(), isA<ContractError>());

LiteralCompositionDiagnostic _blocking(
        LiteralTileComposition result, String code) =>
    result.diagnostics
        .firstWhere((item) => item.blocksPlanning && item.code == code);

LiteralDependencyDecision _decision(
        LiteralTileFixture fixture, LiteralDependencyDisposition disposition,
        {Sha256Hash? snapshotHash,
        Sha256Hash? selectionHash,
        SourceLocator? locator,
        int target = 8}) =>
    LiteralDependencyDecision(
      sourceSnapshotHash: snapshotHash ?? fixture.snapshot.canonicalHash,
      selectionHash: selectionHash ?? literalSelectionHash(fixture.source, [1]),
      locator: locator ??
          fixture.source.maps
              .singleWhere((map) => map.map.sourceMapId == 1)
              .map
              .events
              .single
              .pages
              .single
              .commands
              .first
              .sourceLocator,
      targetSourceMapId: target,
      decision: disposition,
    );

Future<LiteralTileFixture> _warpFixture(
        {bool dynamic = false,
        bool normalizeTarget = true,
        String? sourceRootPath}) =>
    LiteralTileFixture.create(
      sourceRootPath: sourceRootPath,
      maps: [
        LiteralFixtureMap(id: 1, warpParameters: [
          [dynamic ? 1 : 0, 8, 1, 0, 2, 0]
        ]),
        LiteralFixtureMap(id: 8, warpParameters: [
          [0, 1, 1, 0, 2, 0]
        ]),
      ],
      selectedMapIds: normalizeTarget ? null : {1},
    );

TileLayer _layerFor(
    LiteralTileComposition composition, int mapId, int sourceZ) {
  final id = composition.layerProvenance
      .singleWhere((provenance) =>
          provenance.sourceMapId == mapId && provenance.sourceZ == sourceZ)
      .nativeLayerId;
  return composition.nativeMaps[mapId]!.layers
      .singleWhere((layer) => layer.id == id) as TileLayer;
}

List<int> _paintOriginalAtlasPixel(MapData map, image.Image atlas, int cell,
    {int pixelX = 16, int pixelY = 16}) {
  final order =
      buildMapVisualCompositionPlan(map).plan!.visibleTileLayersInPaintOrder;
  const origins = {0: (0, 0), 7: (224, 0), 8: (0, 32)};
  var result = <int>[0, 0, 0, 0];
  for (final layer in order) {
    final paletteCell = layer.cells[cell];
    if (paletteCell == 0) continue;
    final localId = layer.palette[paletteCell - 1].localTileId;
    final origin = origins[localId]!;
    final pixel = atlas.getPixel(origin.$1 + pixelX, origin.$2 + pixelY);
    final foreground = [
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
      pixel.a.toInt()
    ];
    final alpha = foreground[3] / 255;
    final oldAlpha = result[3] / 255;
    final combinedAlpha = alpha + oldAlpha * (1 - alpha);
    if (combinedAlpha == 0) continue;
    result = [
      for (var channel = 0; channel < 3; channel++)
        ((foreground[channel] * alpha +
                    result[channel] * oldAlpha * (1 - alpha)) /
                combinedAlpha)
            .round(),
      (combinedAlpha * 255).round(),
    ];
  }
  return result;
}

void main() {
  test('reuse refuses stricter resolved draft aggregate node budget', () async {
    final fixture = await LiteralTileFixture.create();
    const generous = NativeWriteLimits(maxDraftEvidenceJsonNodes: 2000000);
    final composition = await _compose(fixture, limits: generous);
    expect(
      await composition.verifyForReuse(
        source: fixture.source,
        files: fixture.files,
        limits: generous,
      ),
      same(composition),
    );
    expect(
      await composition.verifyForReuse(
        source: fixture.source,
        files: fixture.files,
      ),
      isNull,
    );
  });

  test(
      'local palettes contain only each layer source tiles with exact shared references',
      () async {
    final maps = [
      LiteralFixtureMap(id: 1, layers: [
        [391, 0, 391],
        [48, 384, 0],
        [0, 0, 0]
      ]),
      LiteralFixtureMap(id: 8, layers: [
        [392, 392, 0],
        [0, 49, 0],
        [0, 0, 393]
      ])
    ];
    final scriptsPath = Platform.environment['AVELUNE_AUTOTILE_SCRIPTS_PATH'];
    final scriptsBytes =
        scriptsPath == null ? null : await File(scriptsPath).readAsBytes();
    final water =
        OriginalAutotileFixture.simple(frameCount: scriptsPath == null ? 1 : 3);
    Future<LiteralTileFixture> fixture({bool reverse = false}) =>
        LiteralTileFixture.create(
          maps: maps,
          interpretationProfile: scriptsBytes == null ? null : fixtureSourceInterpretationProfile,
      scriptsBytes: scriptsBytes,
          tilesets: [
            LiteralFixtureTileset(
                id: 1,
                autotileNames: ['OriginalWater'],
                passages: {391: 7},
                priorities: {392: 2},
                terrainTags: {391: 1})
          ],
          reverseManifest: reverse,
          autotilePngs: {'OriginalWater': water.pngBytes},
        );
    final original = await fixture();
    final result = await _compose(original, selected: [8, 1]);
    final repeated =
        await _compose(await fixture(reverse: true), selected: [1, 8]);
    expect(result.canWrite, isTrue,
        reason: result.diagnostics.map((d) => d.toJson()).toString());
    expect(result.compositionHash, repeated.compositionHash);
    for (final sourceMap in maps) {
      for (var z = 0; z < 3; z++) {
        final sourceCells = sourceMap.layers[z];
        final ids = sourceCells.where((tile) => tile != 0).toSet().toList()
          ..sort();
        final native = _layerFor(result, sourceMap.id, z);
        expect(native.palette, hasLength(ids.length));
        expect(native.cells.toSet().difference({0}),
            {for (var i = 1; i <= ids.length; i++) i});
        for (var index = 0; index < sourceCells.length; index++) {
          final tile = sourceCells[index];
          if (tile == 0) {
            expect(native.cells[index], 0);
            continue;
          }
          expect(native.cells[index], ids.indexOf(tile) + 1);
          final crop = result.crops.singleWhere((c) => c.sourceTileId == tile);
          expect(
              native.palette[native.cells[index] - 1],
              TileLayerPaletteEntry(
                  tilesetId: crop.nativeTilesetId,
                  localTileId: crop.nativeLocalTileId));
          expect(crop.nativeLocalTileId, tile < 384 ? tile % 48 : tile - 384);
        }
      }
    }
    final imports = result.draft!.mutations
        .where((m) => m.actionId == 'tileset.import_image');
    expect(imports, hasLength(2));
    expect(imports.map((m) => m.parameters['tilesetId']).toSet(),
        {result.tilesetIds[1], result.autotiles.single.nativeTilesetId});
    final regular = result.draft!.artifacts.singleWhere((a) =>
        a.rawSha256 ==
        literalFixtureHash(
            original.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!));
    expect(regular.bytes,
        original.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']);
    expect(
        result.autotiles.single.tileAnimations.isNotEmpty, scriptsPath != null);
    final ledge = result.crops.singleWhere((c) => c.sourceTileId == 391);
    expect((ledge.passage, ledge.priority, ledge.terrainTag), (7, 0, 1));
    expect(result.crops.singleWhere((c) => c.sourceTileId == 392).priority, 2);
    expect(result.crops.every((c) => !c.toJson().containsKey('paletteCell')),
        isTrue);
    expect(result.draft!.compositionEvidence['version'], 2);
  });

  test(
      'local palette map save envelopes stay below one MiB after global palette amplification',
      () async {
    const count = 2000;
    final atlas = image.Image(width: 256, height: 16000, numChannels: 4);
    final fixture = await LiteralTileFixture.create(
      maps: [
        for (var id = 1; id <= 2; id++)
          LiteralFixtureMap(id: id, width: 50, height: 40, layers: [
            List.generate(count, (i) => 384 + (id - 1) * count + i),
            List.filled(count, 0),
            List.filled(count, 0)
          ])
      ],
      tilesets: [
        LiteralFixtureTileset(
            id: 1, metadataTileCount: 4384, png: image.encodePng(atlas))
      ],
    );
    final result = await _compose(fixture, selected: [1, 2]);
    expect(result.canWrite, isTrue);
    int envelopeBytes(
            Map<String, Object?> parameters, NativeMutation mutation) =>
        utf8
            .encode(canonicalAuthoringJson(AuthoringRequest(
              requestId: '${List.filled(256, 'r').join()}:native:32767',
              actionId: mutation.actionId,
              actionVersion: mutation.actionVersion,
              workspaceHandle: List.filled(256, 'w').join(),
              expectedRevision: List.filled(256, 'e').join(),
              idempotencyKey: mutation.operationId.value,
              parameters: parameters,
            ).toJson()))
            .length;
    final globalPalette = [
      for (final crop in result.crops)
        TileLayerPaletteEntry(
            tilesetId: crop.nativeTilesetId,
            localTileId: crop.nativeLocalTileId)
    ];
    for (final mutation
        in result.draft!.mutations.where((m) => m.actionId == 'map.save')) {
      final map = MapData.fromJson(
          Map<String, dynamic>.from(mutation.parameters['map'] as Map));
      final oldShape = map.copyWith(layers: [
        for (final layer in map.layers.cast<TileLayer>())
          layer.copyWith(palette: globalPalette, cells: [
            for (final cell in layer.cells)
              cell == 0 ? 0 : globalPalette.indexOf(layer.palette[cell - 1]) + 1
          ])
      ]);
      final before = envelopeBytes({'map': oldShape.toJson()}, mutation);
      final after = envelopeBytes(mutation.parameters, mutation);
      expect(before, greaterThan(1048576));
      expect(after, lessThan(1048576));
      expect(after, lessThan(before ~/ 4));
    }
  });

  test('split image budget admits two logical atlases below the separate total',
      () async {
    final fixture = await LiteralTileFixture.create(
      maps: [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8, tilesetId: 2)],
      tilesets: [
        LiteralFixtureTileset(id: 1),
        LiteralFixtureTileset(id: 2, png: literalFixtureAtlas(alternate: true))
      ],
    );
    final result = await _compose(fixture,
        selected: [1, 8],
        limits: const NativeWriteLimits(
            maxImagePixels: 16384, maxTotalImagePixels: 32768));
    expect(result.canWrite, isTrue);
    expect(result.nativeMaps, hasLength(2));
  });

  test('split image budget forwards separate remaining autotile and image caps',
      () async {
    final fixture = await LiteralTileFixture.create(
      maps: [
        LiteralFixtureMap(id: 1, layers: [
          [48, 384, 391],
          [0, 0, 0],
          [0, 0, 0]
        ])
      ],
      tilesets: [
        LiteralFixtureTileset(id: 1, autotileNames: ['OriginalWater'])
      ],
      autotilePngs: {
        'OriginalWater': OriginalAutotileFixture.simple().pngBytes
      },
    );
    final result = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: [1],
      projectName: 'Bounded autotile',
      parentPath: '/private/tmp',
      folderName: 'bounded-autotile',
      allowFirstFrameAutotiles: true,
      limits: const NativeWriteLimits(
          maxImagePixels: 147456, maxTotalImagePixels: 166912),
    );
    expect(result.canWrite, isTrue,
        reason: result.diagnostics.map((entry) => entry.code).join(','));
    expect(
        result.draft!.artifacts
            .where((artifact) => artifact.reference.mediaType == 'image/png'),
        hasLength(2));
  });

  test(
      'real macOS scanner raster inventory composes through snapshot-bound source reads',
      () async {
    final root = await Directory.systemTemp.createTemp('ac06-real-scanner-');
    MacOsSourceTree? tree;
    try {
      final fixture = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/original-source');
      final before = await _sourceDiskBytes(fixture.sourceRootPath!);
      tree = await MacOsSourceTree.open(fixture.sourceRootPath!);
      final policy = SourceScanPolicy();
      final snapshot = await SourceScanner().scan(
          source: tree,
          logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
          policy: policy);
      expect(snapshot.state, SourceScanState.complete);
      final png = snapshot.entries.singleWhere((entry) =>
          entry.relativePath == 'Graphics/Tilesets/OriginalAtlas1.png');
      expect(png.format, 'raster');
      expect(png.family, 'graphics');
      expect(png.sha256,
          literalFixtureHash(fixture.sourceBytes[png.relativePath]!));
      final files = await SnapshotSourceFiles.bind(
          source: tree, snapshot: snapshot, policy: policy);
      final source = await const RmxpSourceNormalizer()
          .normalize(snapshot: snapshot, files: files);
      expect(source.canPlan, isTrue);
      await files.verifyUnchanged();
      final result = await const LiteralTileComposer().compose(
          source: source,
          files: files,
          selectedSourceMapIds: [1],
          projectName: 'Real scanner original fixture',
          parentPath: root.path,
          folderName: 'native-output',
          sourceRootPath: fixture.sourceRootPath);
      expect(result.canWrite, isTrue,
          reason: result.diagnostics
              .map((diagnostic) => diagnostic.toJson())
              .toList()
              .toString());
      expect(result.draft!.artifacts.single.bytes,
          fixture.sourceBytes[png.relativePath]);
      await files.verifyUnchanged();
      expect(await _sourceDiskBytes(fixture.sourceRootPath!), before);
    } finally {
      await tree?.close();
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);

  test('native paint order preserves source Z opaque overlap oracle', () async {
    final fixture = await LiteralTileFixture.create(maps: [
      LiteralFixtureMap(id: 1, layers: const [
        [384, 384, 384],
        [391, 0, 0],
        [0, 392, 0],
      ]),
    ]);
    final composition = await _compose(fixture);
    expect(composition.canWrite, isTrue);
    final map = composition.nativeMaps[1]!;
    final z0 = _layerFor(composition, 1, 0).id;
    final z1 = _layerFor(composition, 1, 1).id;
    final z2 = _layerFor(composition, 1, 2).id;
    final native = buildMapVisualCompositionPlan(map);
    expect(native.canCompose, isTrue);
    expect(native.plan!.visibleTileLayersInPaintOrder.map((layer) => layer.id),
        [z0, z1, z2]);
    expect(map.layers.map((layer) => layer.id), [z2, z1, z0]);
    final atlas = image.decodePng(Uint8List.fromList(
        fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!))!;
    expect(_paintOriginalAtlasPixel(map, atlas, 0), [19, 207, 55, 255]);
    expect(_paintOriginalAtlasPixel(map, atlas, 1), [23, 61, 223, 255]);
    expect(_paintOriginalAtlasPixel(map, atlas, 2), [201, 17, 39, 255]);
    expect(composition.layerProvenance.map((provenance) => provenance.sourceZ),
        [0, 1, 2]);
  });

  test(
      'native paint order preserves transparent and partial alpha over opaque base',
      () async {
    final fixture = await LiteralTileFixture.create(maps: [
      LiteralFixtureMap(id: 1, layers: const [
        [391, 391, 391],
        [384, 384, 384],
        [0, 0, 0],
      ]),
    ]);
    final composition = await _compose(fixture);
    final map = composition.nativeMaps[1]!;
    final atlas = image.decodePng(Uint8List.fromList(
        fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!))!;
    expect(_paintOriginalAtlasPixel(map, atlas, 0, pixelX: 0, pixelY: 0),
        [19, 207, 55, 255]);
    expect(_paintOriginalAtlasPixel(map, atlas, 0, pixelX: 1, pixelY: 0),
        [18, 118, 49, 255]);
    expect(_paintOriginalAtlasPixel(map, atlas, 0, pixelX: 3, pixelY: 0),
        [255, 0, 255, 255]);
  });

  test('TIL-01 hand-authored boundary crops and three native layers', () async {
    final fixture = await LiteralTileFixture.create();
    expect(fixture.source.canPlan, isTrue);
    final result = await _compose(fixture);
    expect(result.canWrite, isTrue);
    expect(result.playableCertified, isFalse);
    expect(result.diagnostics.where((item) => item.blocksPlanning), isEmpty);
    final crops = {
      for (final crop in result.crops) crop.sourceTileId: crop,
    };
    expect(crops.keys, unorderedEquals([384, 391, 392]));
    expect(
        (crops[384]!.x, crops[384]!.y, crops[384]!.width, crops[384]!.height),
        (0, 0, 32, 32));
    expect(
        (crops[391]!.x, crops[391]!.y, crops[391]!.width, crops[391]!.height),
        (224, 0, 32, 32));
    expect(
        (crops[392]!.x, crops[392]!.y, crops[392]!.width, crops[392]!.height),
        (0, 32, 32, 32));
    expect(crops[384]!.nativeLocalTileId, 0);
    expect(crops[391]!.nativeLocalTileId, 7);
    expect(crops[392]!.nativeLocalTileId, 8);
    final map = result.nativeMaps[1]!;
    expect(map.layers, hasLength(3));
    expect(_layerFor(result, 1, 0).cells, [1, 2, 3]);
    expect(_layerFor(result, 1, 1).cells, [0, 1, 0]);
    expect(_layerFor(result, 1, 2).cells, [0, 0, 0]);
    expect(_layerFor(result, 1, 0).palette.map((entry) => entry.localTileId),
        [0, 7, 8]);
    expect(result.layerProvenance.map((item) => item.sourceZ), [0, 1, 2]);
    expect(result.layerProvenance.every((item) => item.cellCount == 3), isTrue);
  });

  test('TIL-01 zero is empty on every source layer without a fake palette tile',
      () async {
    final fixture = await LiteralTileFixture.create(maps: [
      LiteralFixtureMap(id: 1, layers: const [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0]
      ]),
    ]);
    final result = await _compose(fixture);
    expect(result.canWrite, isTrue);
    expect(result.crops, isEmpty);
    final layers = result.nativeMaps[1]!.layers.cast<TileLayer>();
    expect(layers, hasLength(3));
    for (final layer in layers) {
      expect(layer.cells, [0, 0, 0]);
      expect(layer.palette, isEmpty);
    }
  });

  for (final entry in const {
    1: 'literal.tile.reserved',
    47: 'literal.tile.reserved',
    48: 'autotile.geometry',
    383: 'autotile.geometry',
    400: 'literal.tile.out_of_bounds',
  }.entries) {
    test('TIL-01 tile ${entry.key} has an explicit localized blocker',
        () async {
      final fixture = await LiteralTileFixture.create(
        maps: [
          LiteralFixtureMap(id: 1, layers: [
            [0, entry.key, 0],
            [0, 0, 0],
            [0, 0, 0]
          ])
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1,
              autotileNames:
                  List.generate(7, (slot) => 'OriginalAutotile$slot'))
        ],
      );
      expect(fixture.source.canPlan, isTrue);
      final result = await _compose(fixture);
      expect(result.canWrite, isFalse);
      expect(result.draft, isNull);
      final diagnostic = _blocking(result, entry.value);
      if (entry.key >= 48 && entry.key < 384) {
        expect(diagnostic.locator['file'], 'Data/Tilesets.rxdata');
        expect(diagnostic.locator['sourceTilesetId'], 1);
        expect(diagnostic.locator['autotileSlot'], entry.key ~/ 48 - 1);
        return;
      }
      expect(diagnostic.locator['file'], 'Data/Map001.rxdata');
      expect(diagnostic.locator['mapId'], 1);
      expect(diagnostic.locator['tileId'], entry.key);
      expect(diagnostic.locator['sourceZ'], 0);
      expect(diagnostic.locator['x'], 1);
      expect(diagnostic.locator['y'], 0);
    });
  }

  test('TIL-02 preserves hidden RGB alpha 0 and 127 and opaque magenta',
      () async {
    final fixture = await LiteralTileFixture.create();
    final original =
        fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!;
    final hash = literalFixtureHash(original);
    final result = await _compose(fixture);
    final output = result.draft!.artifacts.single.bytes;
    expect(output, original);
    expect(literalFixtureHash(output), hash);
    expect(result.crops.every((crop) => crop.imageSha256 == hash), isTrue);
    final raster = image.decodePng(Uint8List.fromList(output))!;
    List<int> rgba(int x, int y) {
      final pixel = raster.getPixel(x, y);
      return [
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        pixel.a.toInt()
      ];
    }

    expect(rgba(0, 0), [9, 11, 13, 0]);
    expect(rgba(1, 0), [17, 29, 43, 127]);
    expect(rgba(2, 0), [53, 71, 89, 255]);
    expect(rgba(3, 0), [255, 0, 255, 255]);
    expect(rgba(16, 16), [201, 17, 39, 255]);
    expect(rgba(240, 16), [19, 207, 55, 255]);
    expect(rgba(16, 48), [23, 61, 223, 255]);
    expect(
        fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png'], original);
    expect(literalFixtureHash(original), hash);
    expect(() => output[0] = 0, throwsUnsupportedError);
  });

  for (final identicalBytes in [false, true]) {
    test(
        'TIL-04 distinct tileset identities survive ${identicalBytes ? 'identical' : 'different'} PNG bytes and properties',
        () async {
      final fixture = await LiteralTileFixture.create(
        maps: [
          LiteralFixtureMap(id: 1),
          LiteralFixtureMap(id: 8, tilesetId: 2)
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1,
              priorities: {384: 0},
              passages: {384: 1},
              terrainTags: {384: 5}),
          LiteralFixtureTileset(
              id: 2,
              png: literalFixtureAtlas(alternate: !identicalBytes),
              priorities: {384: 3},
              passages: {384: 2},
              terrainTags: {384: 6}),
        ],
      );
      final result = await _compose(fixture, selected: [8, 1]);
      expect(result.canWrite, isTrue);
      expect(result.tilesetIds[1], isNot(result.tilesetIds[2]));
      expect(result.mapIds[1], isNot(result.mapIds[8]));
      final first = result.crops.singleWhere(
          (crop) => crop.sourceTilesetId == 1 && crop.sourceTileId == 384);
      final second = result.crops.singleWhere(
          (crop) => crop.sourceTilesetId == 2 && crop.sourceTileId == 384);
      expect(first.nativeTilesetId, result.tilesetIds[1]);
      expect(second.nativeTilesetId, result.tilesetIds[2]);
      expect((first.passage, first.priority, first.terrainTag), (1, 0, 5));
      expect((second.passage, second.priority, second.terrainTag), (2, 3, 6));
      expect(first.imageFileId, isNot(second.imageFileId));
      expect(first.imageSha256 == second.imageSha256, identicalBytes);
      final firstLayer = _layerFor(result, 1, 0);
      final secondLayer = _layerFor(result, 8, 0);
      expect(firstLayer.palette.first.tilesetId, result.tilesetIds[1]);
      expect(secondLayer.palette.first.tilesetId, result.tilesetIds[2]);
      expect(result.playableCertified, isFalse);
      final imports = result.draft!.mutations
          .where((mutation) => mutation.actionId == 'tileset.import_image')
          .toList();
      expect(imports, hasLength(2));
      expect(imports[0].parameters['tilesetId'],
          isNot(imports[1].parameters['tilesetId']));
    });
  }

  test(
      'IR-04 composition is independent of selection order and manifest enumeration',
      () async {
    final maps = [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)];
    final first = await LiteralTileFixture.create(maps: maps);
    final reordered =
        await LiteralTileFixture.create(maps: maps, reverseManifest: true);
    final a = await _compose(first, selected: [8, 1]);
    final b = await _compose(reordered, selected: [1, 8]);
    expect(a.selectionHash, b.selectionHash);
    expect(a.compositionHash, b.compositionHash);
    expect(a.draft!.canonicalHash, b.draft!.canonicalHash);
    expect(a.mapIds, b.mapIds);
    expect(a.tilesetIds, b.tilesetIds);
    expect(a.crops.map((crop) => crop.toJson()).toList(),
        b.crops.map((crop) => crop.toJson()).toList());
    expect(a.nativeMaps.map((id, map) => MapEntry(id, map.toJson())),
        b.nativeMaps.map((id, map) => MapEntry(id, map.toJson())));
  });

  test(
      'native identities are namespace scoped and stable when resource bytes change',
      () async {
    final original = await LiteralTileFixture.create();
    final changed = await LiteralTileFixture.create(tilesets: [
      LiteralFixtureTileset(id: 1, png: literalFixtureAtlas(alternate: true))
    ]);
    final otherNamespace = await LiteralTileFixture.create(
        namespace: 'other-original-literal-fixture');
    final a = await _compose(original);
    final b = await _compose(changed);
    final c = await _compose(otherNamespace);
    expect(a.mapIds, b.mapIds);
    expect(a.tilesetIds, b.tilesetIds);
    expect(a.compositionHash, isNot(b.compositionHash));
    expect(a.mapIds[1], isNot(c.mapIds[1]));
    expect(a.tilesetIds[1], isNot(c.tilesetIds[1]));
  });

  test('MAP-05 static transfer outside selection blocks without a decision',
      () async {
    final fixture = await _warpFixture();
    final result = await _compose(fixture);
    expect(result.canWrite, isFalse);
    final dependency = result.dependencies.single;
    expect(dependency.kind, LiteralDependencyKind.staticTransfer);
    expect((dependency.sourceMapId, dependency.targetSourceMapId), (1, 8));
    expect(dependency.decision, isNull);
    expect((
      dependency.locator.file,
      dependency.locator.mapId,
      dependency.locator.eventId,
      dependency.locator.pageIndex,
      dependency.locator.commandIndex
    ), (
      'Data/Map001.rxdata',
      1,
      6,
      0,
      0
    ));
    _blocking(result, 'literal.dependency.unresolved');
  });

  test(
      'MAP-05 explicit include adds a dependency without inventing an active native warp',
      () async {
    final fixture = await _warpFixture();
    final result = await _compose(fixture,
        decisions: [_decision(fixture, LiteralDependencyDisposition.include)]);
    expect(result.canWrite, isTrue);
    expect(result.selectedSourceMapIds, [1]);
    expect(result.includedSourceMapIds, [8]);
    expect(result.nativeMaps.keys, unorderedEquals([1, 8]));
    expect(result.dependencies.first.decision,
        LiteralDependencyDisposition.include);
    for (final map in result.nativeMaps.values) {
      expect(map.warps, isEmpty);
    }
    expect(result.playableCertified, isFalse);
  });

  test(
      'MAP-05 explicit study exclusion records disposition without a broken native warp',
      () async {
    final fixture = await _warpFixture();
    final result = await _compose(fixture, decisions: [
      _decision(fixture, LiteralDependencyDisposition.excludeStudy)
    ]);
    expect(result.canWrite, isTrue);
    expect(result.nativeMaps.keys, [1]);
    expect(result.includedSourceMapIds, isEmpty);
    expect(result.dependencies.single.decision,
        LiteralDependencyDisposition.excludeStudy);
    expect(result.nativeMaps[1]!.warps, isEmpty);
    expect(
        result.diagnostics.any((diagnostic) =>
            !diagnostic.blocksPlanning && diagnostic.code.contains('exclude')),
        isTrue);
    expect(result.playableCertified, isFalse);
  });

  test('MAP-05 explicit block prevents draft creation', () async {
    final fixture = await _warpFixture();
    final result = await _compose(fixture,
        decisions: [_decision(fixture, LiteralDependencyDisposition.block)]);
    expect(result.canWrite, isFalse);
    expect(result.draft, isNull);
    expect(result.dependencies.single.decision,
        LiteralDependencyDisposition.block);
    expect(result.diagnostics.any((diagnostic) => diagnostic.blocksPlanning),
        isTrue);
  });

  test('MAP-05 include requires target IR rather than inventing or reading it',
      () async {
    final fixture = await _warpFixture(normalizeTarget: false);
    expect(fixture.source.canPlan, isTrue);
    expect(fixture.source.maps.map((map) => map.map.sourceMapId), [1]);
    final result = await _compose(fixture,
        decisions: [_decision(fixture, LiteralDependencyDisposition.include)]);
    expect(result.canWrite, isFalse);
    _blocking(result, 'literal.dependency.renormalize');
    expect(fixture.files.reads, isEmpty);
  });

  test('MAP-05 dynamic transfer never interprets a variable id as a map id',
      () async {
    final fixture = await _warpFixture(dynamic: true);
    final result = await _compose(fixture);
    expect(result.canWrite, isFalse);
    expect(
        result.dependencies.single.kind, LiteralDependencyKind.dynamicTransfer);
    expect(result.dependencies.single.targetSourceMapId, isNull);
    expect(result.includedSourceMapIds, isEmpty);
    _blocking(result, 'literal.dependency.dynamic');
  });

  test(
      'explicit inactive dynamic transfer retains its map without a destination',
      () async {
    final fixture = await _warpFixture(dynamic: true);
    final initial = await _compose(fixture);
    final dependency = initial.dependencies.single;
    final decision = LiteralDependencyDecision(
        sourceSnapshotHash: fixture.snapshot.canonicalHash,
        selectionHash: initial.selectionHash,
        locator: dependency.locator,
        targetSourceMapId: null,
        decision: LiteralDependencyDisposition.excludeStudy);
    final result = await _compose(fixture, decisions: [decision]);
    expect(result.canWrite, isTrue);
    expect(result.selectedSourceMapIds, [1]);
    expect(result.includedSourceMapIds, isEmpty);
    expect(result.nativeMaps.keys, [1]);
    expect(
        result.dependencies.single.kind, LiteralDependencyKind.dynamicTransfer);
    expect(result.dependencies.single.targetSourceMapId, isNull);
    expect(result.dependencies.single.decision,
        LiteralDependencyDisposition.excludeStudy);
    expect(result.nativeMaps[1]!.warps, isEmpty);
    expect(
        result.diagnostics
            .singleWhere(
                (entry) => entry.code == 'literal.dependency.dynamic_inactive')
            .blocksPlanning,
        isFalse);
    final preserved = result.draft!.source.maps
        .singleWhere((map) => map.map.sourceMapId == 1)
        .map
        .events
        .single
        .pages
        .single
        .commands
        .first;
    expect(preserved.parameters, [1, 8, 1, 0, 2, 0]);
    expect(
        (result.draft!.compositionEvidence['composition'] as Map)['decisions'],
        [decision.toJson()]);
    final stored = LocalReviewDependencyDecision.fromDecision(decision);
    expect(LocalReviewDependencyDecision.fromJson(stored.toJson()).toJson(),
        stored.toJson());
    expect(stored.targetSourceMapId, isNull);
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source,
                scriptsArchiveHash:
                    Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
interpretationProfile: fixtureSourceInterpretationProfile,
))
        .analyze();
    expect(
        analysis.events
            .singleWhere((event) => event.sourceMapId == 1)
            .isQuarantined,
        isTrue);
  });

  test('dynamic dependency cannot include a null destination', () async {
    final fixture = await _warpFixture(dynamic: true);
    final initial = await _compose(fixture);
    final result = await _compose(fixture, decisions: [
      LiteralDependencyDecision(
          sourceSnapshotHash: fixture.snapshot.canonicalHash,
          selectionHash: initial.selectionHash,
          locator: initial.dependencies.single.locator,
          targetSourceMapId: null,
          decision: LiteralDependencyDisposition.include)
    ]);
    expect(result.canWrite, isFalse);
    expect(result.nativeMaps, isEmpty);
    _blocking(result, 'literal.dependency.decision');
  });

  test('inactive dynamic transfer writes and reopens without an active warp',
      () async {
    final root = await Directory.systemTemp.createTemp('literal-dynamic-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await _warpFixture(
          dynamic: true, sourceRootPath: '${root.path}/source');
      final before = await _sourceDiskBytes(fixture.sourceRootPath!);
      final initial = await _compose(fixture);
      final composition =
          await _compose(fixture, parentPath: output.path, decisions: [
        LiteralDependencyDecision(
            sourceSnapshotHash: fixture.snapshot.canonicalHash,
            selectionHash: initial.selectionHash,
            locator: initial.dependencies.single.locator,
            targetSourceMapId: null,
            decision: LiteralDependencyDisposition.excludeStudy)
      ]);
      final approval = approveNativeFixtureDraft(composition.draft!,
          selectedSourceMapIds: composition.selectedSourceMapIds,
          dependencySourceMapIds: composition.includedSourceMapIds);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, composition.draft!);
      final native = await _LiteralNativeSession.open(receipt.projectPath);
      try {
        final snapshot = await native.snapshots
            .load(native.project, policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.maps.single.id, composition.nativeMaps[1]!.id);
        expect(snapshot.maps.single.warps, isEmpty);
        expect(snapshot.maps.single.entities, isEmpty);
        expect(snapshot.manifest.maps, hasLength(1));
      } finally {
        await native.close();
      }
      expect(await _sourceDiskBytes(fixture.sourceRootPath!), before);
    } finally {
      await root.delete(recursive: true);
    }
  });

  for (final mutation in [
    'snapshot',
    'selection',
    'locator',
    'target',
    'duplicate'
  ]) {
    test('MAP-05 $mutation dependency decision is rejected before media reads',
        () async {
      final fixture = await _warpFixture();
      final otherLocator = fixture.source.maps
          .singleWhere((map) => map.map.sourceMapId == 8)
          .map
          .events
          .single
          .pages
          .single
          .commands
          .single
          .sourceLocator;
      final decision = _decision(fixture, LiteralDependencyDisposition.include,
          snapshotHash: mutation == 'snapshot' ? Sha256Hash('0' * 64) : null,
          selectionHash: mutation == 'selection'
              ? canonicalHashOf({'foreign': true})
              : null,
          locator: mutation == 'locator' ? otherLocator : null,
          target: mutation == 'target' ? 120 : 8);
      final result = await _compose(fixture,
          decisions: [decision, if (mutation == 'duplicate') decision]);
      expect(result.canWrite, isFalse);
      _blocking(result, 'literal.dependency.decision');
      expect(fixture.files.reads, isEmpty);
    });
  }

  test('MAP-05 dependency disposition changes canonical composition evidence',
      () async {
    final fixture = await _warpFixture();
    final include = _decision(fixture, LiteralDependencyDisposition.include);
    final exclude =
        _decision(fixture, LiteralDependencyDisposition.excludeStudy);
    expect(include.canonicalHash, isNot(exclude.canonicalHash));
    final a = await _compose(fixture, decisions: [include]);
    final b = await _compose(fixture, decisions: [exclude]);
    expect(a.compositionHash, isNot(b.compositionHash));
    expect(a.draft!.canonicalHash, isNot(b.draft!.canonicalHash));
    final projection = include.toJson();
    projection['decision'] = 'block';
    expect(include.decision, LiteralDependencyDisposition.include);
  });

  for (final change in ['hash', 'shorter', 'longer']) {
    test('source $change drift is refused without changing original bytes',
        () async {
      final fixture = await LiteralTileFixture.create();
      const path = 'Graphics/Tilesets/OriginalAtlas1.png';
      final original = fixture.sourceBytes[path]!;
      final changed = original.toList();
      if (change == 'hash') changed[changed.length - 1] ^= 1;
      if (change == 'shorter') changed.removeLast();
      if (change == 'longer') changed.add(0);
      fixture.files.overrides[path] = changed;
      await expectLater(_compose(fixture), throwsA(_boundedFailure));
      expect(fixture.sourceBytes[path], original);
      expect(
          literalFixtureHash(original),
          fixture.snapshot.entries
              .singleWhere((entry) => entry.relativePath == path)
              .sha256);
    });
  }

  test('malformed admitted PNG bytes fail before producing a native draft',
      () async {
    final fixture = await LiteralTileFixture.create(tilesets: [
      LiteralFixtureTileset(id: 1, png: [137, 80, 78, 71, 13, 10, 26, 10]),
    ]);
    expect(fixture.source.canPlan, isTrue);
    await expectLater(_compose(fixture), throwsA(_boundedFailure));
  });

  test('missing source media cannot bypass normalized source blockers',
      () async {
    final fixture = await LiteralTileFixture.create(
        tilesets: [LiteralFixtureTileset(id: 1, imagePresent: false)]);
    expect(fixture.source.canPlan, isFalse);
    final result = await _compose(fixture);
    expect(result.canWrite, isFalse);
    expect(result.draft, isNull);
    _blocking(result, 'literal.source.incomplete');
    expect(fixture.files.reads, isEmpty);
  });

  for (final limits in const [
    NativeWriteLimits(maxArtifactBytes: 8),
    NativeWriteLimits(maxTotalArtifactBytes: 8),
    NativeWriteLimits(maxMapCells: 8),
    NativeWriteLimits(maxMutations: 2),
  ]) {
    test(
        'known source quota refuses before its first media read ${[
          limits.maxArtifactBytes,
          limits.maxTotalArtifactBytes,
          limits.maxMapCells,
          limits.maxMutations
        ]}', () async {
      final fixture = await LiteralTileFixture.create();
      await expectLater(
          _compose(fixture, limits: limits), throwsA(_boundedFailure));
      expect(fixture.files.reads, isEmpty);
    });
  }

  test('image pixel quota is bounded at its actual original geometry',
      () async {
    final fixture = await LiteralTileFixture.create();
    await expectLater(
        _compose(fixture,
            limits: const NativeWriteLimits(maxImagePixels: 16383)),
        throwsA(_boundedFailure));
  });

  test('cancellation before and during a source read never returns a draft',
      () async {
    final fixture = await LiteralTileFixture.create();
    final early = ScanCancellation()..cancel();
    await expectLater(
        _compose(fixture, cancellation: early), throwsA(_boundedFailure));
    expect(fixture.files.reads, isEmpty);
    final active = ScanCancellation();
    fixture.files.onRead = (_) => active.cancel();
    await expectLater(
        _compose(fixture, cancellation: active), throwsA(_boundedFailure));
  });

  test(
      'selection hashes reject duplicates zero and unknown source maps before reads',
      () async {
    final fixture = await LiteralTileFixture.create();
    for (final selected in [
      <int>[],
      [0],
      [1, 1],
    ]) {
      await expectLater(
          _compose(fixture, selected: selected), throwsA(_boundedFailure));
      expect(fixture.files.reads, isEmpty);
    }
    final unknown = await _compose(fixture, selected: [120]);
    expect(unknown.canWrite, isFalse);
    _blocking(unknown, 'literal.dependency.renormalize');
    expect(fixture.files.reads, isEmpty);
    expect(() => literalSelectionHash(fixture.source, [1, 1]),
        throwsA(_boundedFailure));
    expect(() => literalSelectionHash(fixture.source, [0]),
        throwsA(_boundedFailure));
  });

  test('composition does not manufacture a confirmed source profile', () async {
    for (final contradiction in [false, true]) {
      final fixture =
          await LiteralTileFixture.create(contradictoryProfile: contradiction);
      final state = fixture.snapshot.profile.state;
      expect(
          state,
          contradiction
              ? SourceProfileState.requiresConfirmation
              : SourceProfileState.observed);
      final result = await _compose(fixture);
      expect(result.playableCertified, isFalse);
      expect(fixture.snapshot.profile.state, state);
      expect(
          result.diagnostics.any((diagnostic) =>
              diagnostic.code.contains('profile') &&
              !diagnostic.blocksPlanning),
          isTrue);
    }
  });

  test('composition collections and deep diagnostic locators are immutable',
      () async {
    final fixture = await LiteralTileFixture.create();
    final result = await _compose(fixture);
    expect(() => result.mapIds.clear(), throwsUnsupportedError);
    expect(() => result.tilesetIds.clear(), throwsUnsupportedError);
    expect(() => result.nativeMaps.clear(), throwsUnsupportedError);
    expect(() => result.selectedSourceMapIds.add(8), throwsUnsupportedError);
    expect(() => result.includedSourceMapIds.add(8), throwsUnsupportedError);
    expect(() => result.crops.clear(), throwsUnsupportedError);
    expect(() => result.layerProvenance.clear(), throwsUnsupportedError);
    expect(() => result.dependencies.clear(), throwsUnsupportedError);
    expect(() => result.diagnostics.clear(), throwsUnsupportedError);
    final nested = <String, Object?>{
      'values': <Object?>[1]
    };
    final diagnostic = LiteralCompositionDiagnostic(
        code: 'controlled',
        blocksPlanning: false,
        locator: {'nested': nested},
        message: 'Original diagnostic fixture');
    (nested['values']! as List)[0] = 99;
    final frozen = diagnostic.locator['nested']! as Map;
    expect(frozen['values'], [1]);
    expect(() => (frozen['values'] as List).add(2), throwsUnsupportedError);
  });

  test(
      'TIL-03 controlled original composition writes edits saves and freshly reopens',
      () async {
    final root = await Directory.systemTemp.createTemp('ac06-literal-native-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/original-source',
        maps: [
          LiteralFixtureMap(id: 1, width: 3, height: 3, layers: const [
            [384, 391, 392, 391, 384, 392, 392, 391, 384],
            [0, 384, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ])
        ],
      );
      final sourceBefore = await _sourceDiskBytes(fixture.sourceRootPath!);
      final composition = await _compose(fixture, parentPath: output.path);
      final approval = approveNativeFixtureDraft(composition.draft!,
          selectedSourceMapIds: composition.selectedSourceMapIds,
          dependencySourceMapIds: composition.includedSourceMapIds);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, composition.draft!);
      expect(receipt.verified, isTrue);
      expect(receipt.published, isFalse);
      final native = await _LiteralNativeSession.open(receipt.projectPath);
      late MapData edited;
      late List<int> savedBytes;
      late String relativePath;
      try {
        final snapshot = await native.snapshots
            .load(native.project, policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.loadDiagnostics, isEmpty);
        expect(snapshot.maps.single, composition.nativeMaps[1]);
        final map = snapshot.maps.single;
        expect(map.layers, hasLength(3));
        final base = _layerFor(composition, 1, 0);
        edited = map.copyWith(name: 'Controlled native painted cell', layers: [
          for (final layer in map.layers)
            if (layer.id == base.id)
              base.copyWith(cells: [2, ...base.cells.skip(1)])
            else
              layer,
        ]);
        await native.save(edited, snapshot.revision);
        relativePath = snapshot.manifest.maps.single.relativePath;
        savedBytes =
            await File('${receipt.projectPath}/$relativePath').readAsBytes();
        expect(
            MapData.fromJson(
                jsonDecode(utf8.decode(savedBytes)) as Map<String, dynamic>),
            edited);
        final sourcePng =
            fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!;
        final tilesetId = composition.tilesetIds[1]!;
        expect(
            await snapshot.readResourceBytes('assetLogical:image_$tilesetId'),
            sourcePng);
        expect(receipt.assetHashes['image_$tilesetId'],
            literalFixtureHash(sourcePng));
      } finally {
        await native.close();
      }
      final fresh = await _LiteralNativeSession.open(receipt.projectPath);
      try {
        final snapshot = await fresh.snapshots
            .load(fresh.project, policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.maps.single, edited);
        final z0 = _layerFor(composition, 1, 0).id;
        expect(
            (snapshot.maps.single.layers.singleWhere((layer) => layer.id == z0)
                    as TileLayer)
                .cells
                .first,
            2);
        expect(await File('${receipt.projectPath}/$relativePath').readAsBytes(),
            savedBytes);
      } finally {
        await fresh.close();
      }
      expect(await _sourceDiskBytes(fixture.sourceRootPath!), sourceBefore);
      expect(
          await Directory('${output.path}/original-literal-project').exists(),
          isFalse);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('TIL-04 identical PNGs remain two native tileset and asset identities',
      () async {
    final root =
        await Directory.systemTemp.createTemp('ac06-identical-native-');
    try {
      final output = await Directory('${root.path}/output').create();
      final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/original-source',
        maps: [
          LiteralFixtureMap(id: 1),
          LiteralFixtureMap(id: 8, tilesetId: 2)
        ],
        tilesets: [
          LiteralFixtureTileset(id: 1),
          LiteralFixtureTileset(id: 2, priorities: {384: 3})
        ],
      );
      final before = await _sourceDiskBytes(fixture.sourceRootPath!);
      final composition =
          await _compose(fixture, selected: [1, 8], parentPath: output.path);
      final approval = approveNativeFixtureDraft(composition.draft!,
          selectedSourceMapIds: composition.selectedSourceMapIds,
          dependencySourceMapIds: composition.includedSourceMapIds);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, composition.draft!);
      final native = await _LiteralNativeSession.open(receipt.projectPath);
      try {
        final snapshot = await native.snapshots
            .load(native.project, policy: ProjectSnapshotLoadPolicy.strict);
        expect(snapshot.manifest.tilesets, hasLength(2));
        final sources = snapshot.manifest.tilesets
            .map((tileset) =>
                tileset.source! as ProjectRegularAtlasTilesetSource)
            .toList();
        expect(sources[0].assetId, isNot(sources[1].assetId));
        for (final source in sources) {
          expect(
              await snapshot
                  .readResourceBytes('assetLogical:${source.assetId}'),
              fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']);
        }
        for (final entry in composition.nativeMaps.entries) {
          expect(snapshot.mapById(entry.value.id), entry.value);
        }
        expect(receipt.assetHashes, hasLength(2));
        expect(receipt.assetHashes.values.toSet(), hasLength(1));
      } finally {
        await native.close();
      }
      expect(await _sourceDiskBytes(fixture.sourceRootPath!), before);
    } finally {
      await root.delete(recursive: true);
    }
  });

  for (final reclassification in ['all-selected', 'missing-dependency']) {
    test(
        'MAP-05 native writer refuses $reclassification despite a newly approved plan',
        () async {
      final root =
          await Directory.systemTemp.createTemp('ac06-dependency-gate-');
      try {
        final fixture = await _warpFixture();
        final composition = await _compose(fixture,
            parentPath: root.path,
            decisions: [
              _decision(fixture, LiteralDependencyDisposition.include)
            ]);
        final approval = approveNativeFixtureDraft(composition.draft!,
            selectedSourceMapIds:
                reclassification == 'all-selected' ? [1, 8] : [1],
            dependencySourceMapIds: []);
        final stages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(approval.plan, approval.context, composition.draft!),
            throwsA(isA<NativeWriteException>()));
        expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
        expect(await root.list().toList(), isEmpty);
      } finally {
        await root.delete(recursive: true);
      }
    });
  }

  test(
      'changed composition evidence under the old approval refuses before filesystem effects',
      () async {
    final root =
        await Directory.systemTemp.createTemp('ac06-composition-binding-');
    try {
      final fixture = await LiteralTileFixture.create();
      final composition = await _compose(fixture, parentPath: root.path);
      final approval = approveNativeFixtureDraft(composition.draft!,
          selectedSourceMapIds: [1]);
      final evidence =
          jsonDecode(jsonEncode(composition.draft!.compositionEvidence))
              as Map<String, dynamic>;
      evidence['compositionHash'] = '0' * 64;
      final changed = copyNativeFixtureDraft(composition.draft!,
          compositionEvidence: evidence);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(approval.plan, approval.context, changed),
          throwsA(isA<NativeWriteException>()));
      expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
      expect(await root.list().toList(), isEmpty);
      expect(
          () => (composition.draft!.compositionEvidence['composition']!
              as Map)['selectedSourceMapIds'] = [8],
          throwsUnsupportedError);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test(
      'study composition refuses a core-admitted playable slice before filesystem effects',
      () async {
    final root = await Directory.systemTemp.createTemp('ac06-study-only-');
    try {
      final fixture = await LiteralTileFixture.create();
      final composition = await _compose(fixture, parentPath: root.path);
      final approval = approveNativeFixtureDraft(composition.draft!,
          selectedSourceMapIds: [1], requestedMode: 'playableSlice');
      expect(
          admitPlan(approval.plan, approval.context).plan, same(approval.plan));
      expect(
          (composition.draft!.compositionEvidence['composition']!
              as Map)['playableCertified'],
          isFalse);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(approval.plan, approval.context, composition.draft!),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.composition.mode')));
      expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
      expect(await root.list().toList(), isEmpty);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('study composition refuses a recomputed claim of playable certification',
      () async {
    final root =
        await Directory.systemTemp.createTemp('ac06-false-certification-');
    try {
      final fixture = await LiteralTileFixture.create();
      final composition = await _compose(fixture, parentPath: root.path);
      final evidence =
          jsonDecode(jsonEncode(composition.draft!.compositionEvidence))
              as Map<String, dynamic>;
      final record = evidence['composition'] as Map<String, dynamic>;
      record['playableCertified'] = true;
      evidence['compositionHash'] = canonicalHashOf(record).value;
      final changed = copyNativeFixtureDraft(composition.draft!,
          compositionEvidence: evidence);
      final approval =
          approveNativeFixtureDraft(changed, selectedSourceMapIds: [1]);
      expect(
          admitPlan(approval.plan, approval.context).plan, same(approval.plan));
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(approval.plan, approval.context, changed),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.composition.mode')));
      expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
      expect(await root.list().toList(), isEmpty);
    } finally {
      await root.delete(recursive: true);
    }
  });

  for (final contradiction in [
    'version',
    'mapIds',
    'tilesetIds',
    'sourceArchiveHash'
  ]) {
    test(
        'recomputed contradictory $contradiction provenance refuses a freshly admitted plan',
        () async {
      final root =
          await Directory.systemTemp.createTemp('ac06-provenance-gate-');
      try {
        final fixture = await LiteralTileFixture.create();
        final composition = await _compose(fixture, parentPath: root.path);
        final evidence =
            jsonDecode(jsonEncode(composition.draft!.compositionEvidence))
                as Map<String, dynamic>;
        final record = evidence['composition'] as Map<String, dynamic>;
        switch (contradiction) {
          case 'version':
            evidence['version'] = 1;
            record['version'] = 1;
          case 'mapIds':
            (record['mapIds'] as Map)['1'] = 'false_mapping';
          case 'tilesetIds':
            (record['tilesetIds'] as Map)['1'] = 'false_tileset';
          case 'sourceArchiveHash':
            record['sourceArchiveHash'] = '0' * 64;
        }
        evidence['compositionHash'] = canonicalHashOf(record).value;
        final changed = copyNativeFixtureDraft(composition.draft!,
            compositionEvidence: evidence);
        final approval =
            approveNativeFixtureDraft(changed, selectedSourceMapIds: [1]);
        expect(admitPlan(approval.plan, approval.context).plan,
            same(approval.plan));
        final stages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
                .write(approval.plan, approval.context, changed),
            throwsA(isA<NativeWriteException>().having(
                (error) => error.code,
                'code',
                const {'version', 'sourceArchiveHash'}.contains(contradiction)
                    ? 'native.composition.evidence'
                    : 'native.composition.contents')));
        expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
        expect(await root.list().toList(), isEmpty);
      } finally {
        await root.delete(recursive: true);
      }
    });
  }

  for (final empty in [false, true]) {
    test(
        'native source labels ${empty ? 'fallback' : 'trim'} without changing original provenance',
        () async {
      final root = await Directory.systemTemp.createTemp('ac06-source-labels-');
      try {
        final sourceMapName = empty ? '   ' : ' Original map name ';
        final sourceTilesetName = empty ? '   ' : ' Original atlas name ';
        final fixture = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/source',
          maps: [LiteralFixtureMap(id: 1, name: sourceMapName)],
          tilesets: [LiteralFixtureTileset(id: 1, name: sourceTilesetName)],
        );
        final sourceHash = fixture.source.canonicalHash;
        final before = await _sourceDiskBytes(fixture.sourceRootPath!);
        final output = await Directory('${root.path}/output').create();
        final composition = await _compose(fixture, parentPath: output.path);
        expect(composition.canWrite, isTrue);
        final import = composition.draft!.mutations.singleWhere(
            (mutation) => mutation.actionId == 'tileset.import_image');
        final approval = approveNativeFixtureDraft(composition.draft!,
            selectedSourceMapIds: [1]);
        expect(admitPlan(approval.plan, approval.context).plan,
            same(approval.plan));
        final receipt = await const NativeProjectWriter()
            .write(approval.plan, approval.context, composition.draft!);
        expect(receipt.verified, isTrue);
        expect(composition.nativeMaps[1]!.name,
            empty ? 'Map 1' : 'Original map name');
        expect(import.parameters['name'],
            empty ? 'Tileset 1' : 'Original atlas name');
        expect(fixture.source.maps.single.map.name, sourceMapName);
        expect(fixture.source.mapHierarchy.single.name, sourceMapName);
        expect(fixture.source.tilesets.single.name, sourceTilesetName);
        expect(fixture.source.canonicalHash, sourceHash);
        expect(await _sourceDiskBytes(fixture.sourceRootPath!), before);
      } finally {
        await root.delete(recursive: true);
      }
    });
  }
}

Future<Map<String, List<int>>> _sourceDiskBytes(String root) async {
  final result = <String, List<int>>{};
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result[entry.path.substring(root.length + 1)] = await entry.readAsBytes();
    }
  }
  return result;
}

final class _LiteralNativeSession {
  _LiteralNativeSession(
      this.opener, this.snapshots, this.project, this.workspace, this.api);
  final ProjectOpenService opener;
  final ProjectSnapshotLoader snapshots;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi api;

  static Future<_LiteralNativeSession> open(String root) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opened = await opener.openProject(root);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await api.attachProject(
        projectRootPath: root,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _LiteralNativeSession(
        opener, snapshots, opened.projectHandle, opened.workspaceHandle, api);
  }

  Future<void> save(MapData map, String revision) async {
    final plan = await api.planMutation(
        project,
        AuthoringRequest(
          requestId: 'original-literal-native-edit',
          actionId: 'map.save',
          actionVersion: 1,
          workspaceHandle: workspace.value,
          expectedRevision: revision,
          idempotencyKey: 'original-literal-native-edit',
          parameters: {'map': map.toJson()},
        ));
    expect(plan.applicable, isTrue);
    final receipt = await api.applyMutation(project,
        planId: plan.planId, operationId: 'original-literal-native-edit');
    expect(receipt.receipt.status, AuthoringReceiptStatus.applied);
  }

  Future<void> close() async {
    await api.detachWorkspace(workspace);
    opener.closeWorkspace(workspace);
  }
}
