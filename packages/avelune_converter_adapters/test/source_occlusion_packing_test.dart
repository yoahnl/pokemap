import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_adapters/src/source_semantics_projection.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test('one padded frame pays only for its occupied column', () async {
    final (fixture, base) = await _case(count: 1, priority: 2);
    final result = await _project(fixture, base,
        limits: const NativeWriteLimits(
            maxImagePixels: 16384, maxTotalImagePixels: 19456));
    final rasters = _rasters(result);
    expect(rasters.values.map((raster) => (raster.width, raster.height)),
        [(32, 96)]);
    _expectExactFrames(fixture, base, result);
  });

  test('packs definitions into shared rows and bounded per-image pages',
      () async {
    final (fixture, base) = await _case(count: 16);
    const limits =
        NativeWriteLimits(maxImagePixels: 16384, maxTotalImagePixels: 49152);
    final result = await _project(fixture, base, limits: limits);
    expect(
        _rasters(result).values.map((raster) => (raster.width, raster.height)),
        [(256, 64), (256, 64)]);
    final packing = result.semanticEvidence['occlusionPacking'] as Map;
    expect(packing['decodedInputPixels'], 16384);
    expect(packing['plannedOutputPixels'], 32768);
    expect(packing['allocatedOutputPixels'], 32768);
    expect(packing['pageCount'], 2);
    expect(packing['groups'], [
      {
        'pixelOffsetY': -31,
        'frameHeightPx': 64,
        'definitionCount': 16,
        'frameCount': 16,
        'pageCount': 2,
        'outputPixels': 32768,
        'channelBitDepth': 8,
      }
    ]);
    _expectExactFrames(fixture, base, result);
    final again = await _project(fixture, base, limits: limits);
    expect(result.semanticEvidence, again.semanticEvidence);
    expect(result.mutations.map((mutation) => mutation.toJson(0)),
        again.mutations.map((mutation) => mutation.toJson(0)));
    expect(result.artifacts.map((artifact) => artifact.rawSha256),
        again.artifacts.map((artifact) => artifact.rawSha256));
  });

  test('preflights aggregate page pixels before allocating any output page',
      () async {
    final (fixture, base) = await _case(count: 16);
    await expectLater(
        _project(fixture, base,
            limits: const NativeWriteLimits(
                maxImagePixels: 16384, maxTotalImagePixels: 49151)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'semantics.quota.pixels')
            .having((error) => error.message, 'message',
                contains('plannedOutputPixels=32768'))
            .having((error) => error.message, 'message',
                contains('allocatedOutputPixels=0'))));
  });

  test('constrains columns so a tall frame fits the per-image pixel budget',
      () async {
    final (fixture, base) = await _case(
        count: 1,
        priority: 5,
        png: image
            .encodePng(image.Image(width: 256, height: 32, numChannels: 4)));
    final result = await _project(fixture, base,
        limits: const NativeWriteLimits(
            maxImagePixels: 8192, maxTotalImagePixels: 14336));
    expect(
        _rasters(result).values.map((raster) => (raster.width, raster.height)),
        [(32, 192)]);
    _expectExactFrames(fixture, base, result);
  });

  test('page imports retain aggregate artifact and mutation limits', () async {
    final (fixture, base) = await _case(count: 16);
    for (final limits in [
      NativeWriteLimits(
          maxImagePixels: 16384,
          maxArtifacts: base.draft!.artifacts.length + 1),
      NativeWriteLimits(
          maxImagePixels: 16384,
          maxMutations: base.draft!.mutations.length + 1),
    ]) {
      await expectLater(
          _project(fixture, base, limits: limits),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'semantics.quota.draft')));
    }
  });

  test('mixed RGBA8 and RGBA16 definitions preserve every channel', () async {
    final sixteen = image.Image(
        width: 256, height: 64, numChannels: 4, format: image.Format.uint16);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        sixteen.setPixelRgba(x, y, 517 + x * 1501, 1027 + y * 137, 63217,
            x % 2 == 0 ? 0 : 33791);
      }
    }
    final fixture = await LiteralTileFixture.create(maps: [
      for (final id in [1, 2]) _map(id: id, tilesetId: id, tiles: [384]),
    ], tilesets: [
      LiteralFixtureTileset(id: 1, priorities: {384: 1}),
      LiteralFixtureTileset(
          id: 2, priorities: {384: 1}, png: image.encodePng(sixteen)),
    ]);
    final base = await _base(fixture);
    final result = await _project(fixture, base);
    final rasters = _rasters(result);
    expect(rasters, hasLength(1));
    expect(rasters.values.single.format, image.Format.uint16);
    expect(rasters.values.single.width, 64);
    _expectExactFrames(fixture, base, result);
  });

  test('shared offsets keep distinct padded frame heights and exact masks',
      () async {
    final fixture = await LiteralTileFixture.create(maps: [
      _map(tiles: [384, 385])
    ], tilesets: [
      LiteralFixtureTileset(id: 1, priorities: {384: 1, 385: 2})
    ]);
    final base = await _base(fixture);
    final result = await _project(fixture, base,
        limits: const NativeWriteLimits(
            maxImagePixels: 16384, maxTotalImagePixels: 21504));
    expect(
        _rasters(result).values.map((raster) => (raster.width, raster.height)),
        [(32, 64), (32, 96)]);
    _expectExactFrames(fixture, base, result);
  });

  test('native atlas dimensions stay bounded for large offset groups',
      () async {
    final (fixture, base) = await _case(
        count: 513,
        png: image
            .encodePng(image.Image(width: 256, height: 2080, numChannels: 4)));
    final result = await _project(fixture, base,
        limits: const NativeWriteLimits(maxMutations: 1024));
    final rasters = _rasters(result);
    expect(rasters, hasLength(2));
    expect(rasters.values.every((raster) => raster.height <= 4096), isTrue);
    expect(_elements(result), hasLength(513));
  });

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  test('animation frames span pages without changing order or duration',
      () async {
    final raster = image.Image(width: 224, height: 32, numChannels: 4);
    for (var y = 0; y < raster.height; y++) {
      for (var x = 0; x < raster.width; x++) {
        raster.setPixelRgba(
            x, y, x, y * 7, x ~/ 32 * 37, (x + y) % 3 == 0 ? 0 : 127);
      }
    }
    final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        extraFiles: {
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = PackingPlayer\n'),
          'Graphics/Characters/PackingPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        },
        maps: [
          _map(tiles: [for (var id = 48; id < 96; id++) id])
        ],
        tilesets: [
          LiteralFixtureTileset(
              id: 1,
              autotileNames: ['Packing [3]'],
              priorities: {for (var id = 48; id < 96; id++) id: 1})
        ],
        autotilePngs: {
          'Packing [3]': image.encodePng(raster)
        });
    final output = await Directory.systemTemp.createTemp('occlusion-pages-');
    addTearDown(() async {
      if (await output.exists()) await output.delete(recursive: true);
    });
    final base = await _base(fixture, parentPath: output.path);
    expect(base.autotiles.single.sourceFrameCount, 7);
    expect(base.autotiles.single.animationVerified, isTrue);
    const limits =
        NativeWriteLimits(maxImagePixels: 400000, maxTotalImagePixels: 2000000);
    final result = await _project(fixture, base, limits: limits);
    final elements = _elements(result);
    expect(elements, hasLength(48));
    expect(elements.every((element) => element.frames.length == 7), isTrue);
    expect(
        elements.any((element) =>
            element.frames.map((frame) => frame.tilesetId).toSet().length > 1),
        isTrue);
    expect(_rasters(result), hasLength(2));
    _expectExactFrames(fixture, base, result);
    try {
      final draft = (await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: base,
          files: fixture.files,
          limits: limits))!;
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, isTrue);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.loadDiagnostics, isEmpty);
        for (final element in elements) {
          final reloaded = native.manifest.elements
              .singleWhere((entry) => entry.id == element.id);
          expect(reloaded.toJson(), element.toJson());
          for (final frame in reloaded.frames) {
            final atlas = native.manifest.tilesets
                .singleWhere((entry) => entry.id == frame.tilesetId);
            final source = atlas.source as ProjectRegularAtlasTilesetSource;
            final resolved = const ProjectTilesetVisualResolver().resolve(
                source: source,
                selection: ProjectTilesetVisualSelection.regularAtlas(
                    source: frame.source),
                cellWidth: 32,
                cellHeight: 32);
            final slices = resolved.frames.single.slices;
            expect(slices, hasLength(frame.source.height));
            for (var row = 0; row < frame.source.height; row++) {
              expect(slices[row].assetId, source.assetId);
              expect(
                  slices[row].sourceRect,
                  ProjectTilesetPixelRect(
                      x: frame.source.x * 32,
                      y: (frame.source.y + row) * 32,
                      width: 32,
                      height: 32));
              expect(
                  slices[row].destinationRect,
                  ProjectTilesetPixelRect(
                      x: 0,
                      y: source.pixelOffsetY + row * 32,
                      width: 32,
                      height: 32));
            }
            final imported = result.mutations.singleWhere((mutation) =>
                mutation.actionId == 'tileset.import_image' &&
                mutation.parameters['tilesetId'] == frame.tilesetId);
            final artifact = result.artifacts.singleWhere((artifact) =>
                artifact.handle == imported.parameters['artifactHandle']);
            expect(
                literalFixtureHash(
                    await File('${receipt.projectPath}/${atlas.relativePath}')
                        .readAsBytes()),
                artifact.rawSha256);
          }
        }
        expect(native.maps.single.toJson(), result.nativeMaps[1]!.toJson());
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    } finally {
      await output.delete(recursive: true);
    }
  }, skip: scriptsPath == null);

  test('scheduled cancellation after map projection is observed before packing',
      () async {
    final (fixture, base) = await _case(count: 16);
    final cancellation = ScanCancellation();
    final future = _project(fixture, base, cancellation: cancellation);
    scheduleMicrotask(cancellation.cancel);
    await expectLater(
        future,
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
  });

  test('scheduled cancellation during page packing never returns a projection',
      () async {
    final (fixture, base) = await _case(count: 16);
    final cancellation = ScanCancellation();
    final future = _project(fixture, base, cancellation: cancellation);
    final cancelled = Completer<void>();
    Timer.run(() => Timer.run(() {
          cancellation.cancel();
          cancelled.complete();
        }));
    await expectLater(
        future,
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    await cancelled.future;
  });
}

Future<(LiteralTileFixture, LiteralTileComposition)> _case(
    {required int count, int priority = 1, List<int>? png}) async {
  final tiles = [for (var index = 0; index < count; index++) 384 + index];
  final fixture = await LiteralTileFixture.create(maps: [
    _map(tiles: tiles)
  ], tilesets: [
    LiteralFixtureTileset(
        id: 1,
        metadataTileCount: 384 + count,
        png: png,
        priorities: {for (final tile in tiles) tile: priority})
  ]);
  return (fixture, await _base(fixture));
}

LiteralFixtureMap _map(
        {int id = 1, int tilesetId = 1, required List<int> tiles}) =>
    LiteralFixtureMap(
        id: id,
        tilesetId: tilesetId,
        width: 16,
        height: (tiles.length + 15) ~/ 16 + 8,
        layers: [
          List.filled(((tiles.length + 15) ~/ 16 + 8) * 16, 0),
          [
            for (var index = 0;
                index < ((tiles.length + 15) ~/ 16 + 8) * 16;
                index++)
              index >= 16 && index - 16 < tiles.length ? tiles[index - 16] : 0
          ],
          List.filled(((tiles.length + 15) ~/ 16 + 8) * 16, 0),
        ]);

Future<LiteralTileComposition> _base(LiteralTileFixture fixture,
        {String parentPath = '/private/tmp'}) =>
    const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds:
            fixture.source.maps.map((entry) => entry.map.sourceMapId).toList(),
        projectName: 'Occlusion packing',
        parentPath: parentPath,
        folderName: 'occlusion-packing');

Future<SourceSemanticsProjection> _project(
        LiteralTileFixture fixture, LiteralTileComposition base,
        {NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation}) =>
    const SourceSemanticsProjector().project(
        source: fixture.source,
        base: base,
        player: SourcePlayerCharacterImport(
            sourceSnapshotHash: fixture.snapshot.canonicalHash,
            metadataFile: fixture.snapshot.entries.first,
            imageFile: fixture.snapshot.entries.first,
            imageBytes: literalFixtureAtlas(),
            outputBytes: literalFixtureAtlas(),
            selectedHeaderId: 1,
            charsetName: 'Fixed tall preview',
            sheetWidth: 128,
            sheetHeight: 192,
            frameWidthPx: 32,
            frameHeightPx: 48,
            assetId: 'preview-player',
            tilesetId: 'preview-player',
            character: const ProjectCharacterEntry(
                id: 'preview-player',
                name: 'Preview',
                tilesetId: 'preview-player')),
        files: fixture.files,
        limits: limits,
        cancellation: cancellation);

List<ProjectElementEntry> _elements(SourceSemanticsProjection result) => [
      for (final mutation in result.mutations)
        if (mutation.actionId == 'element.upsert' &&
            (mutation.parameters['element'] as Map)['id']
                .toString()
                .startsWith('ac12-occ-'))
          ProjectElementEntry.fromJson(
              Map<String, dynamic>.from(mutation.parameters['element'] as Map))
    ];

Map<String, image.Image> _rasters(SourceSemanticsProjection result) => {
      for (final mutation in result.mutations)
        if (mutation.actionId == 'tileset.import_image' &&
            (mutation.parameters['tilesetId'] as String)
                .startsWith('ac12-occlusion-'))
          mutation.parameters['tilesetId'] as String: image.decodePng(
              Uint8List.fromList(result.artifacts
                  .singleWhere((artifact) =>
                      artifact.handle == mutation.parameters['artifactHandle'])
                  .bytes))!
    };

void _expectExactFrames(LiteralTileFixture fixture, LiteralTileComposition base,
    SourceSemanticsProjection result) {
  final rasters = _rasters(result);
  final elements = {
    for (final element in _elements(result)) element.id: element
  };
  final sources = <String, (image.Image, ProjectRegularAtlasTilesetSource)>{};
  for (final crop in base.crops.where((crop) => crop.priority > 0)) {
    sources.putIfAbsent(crop.nativeTilesetId, () {
      final imported = base.draft!.mutations.singleWhere((mutation) =>
          mutation.actionId == 'tileset.import_image' &&
          mutation.parameters['tilesetId'] == crop.nativeTilesetId);
      final raster = image.decodePng(Uint8List.fromList(base.draft!.artifacts
          .singleWhere((artifact) =>
              artifact.handle == imported.parameters['artifactHandle'])
          .bytes))!;
      final upsert = base.draft!.mutations
          .where((mutation) =>
              mutation.actionId == 'tileset.upsert' &&
              (mutation.parameters['tileset'] as Map)['id'] ==
                  crop.nativeTilesetId)
          .firstOrNull;
      final source = upsert == null
          ? ProjectRegularAtlasTilesetSource(
              assetId: crop.nativeTilesetId,
              pixelWidth: raster.width,
              pixelHeight: raster.height,
              tileWidth: 32,
              tileHeight: 32)
          : ProjectTilesetEntry.fromJson(Map<String, dynamic>.from(
                  upsert.parameters['tileset'] as Map))
              .source as ProjectRegularAtlasTilesetSource;
      return (raster, source);
    });
  }
  for (final original in fixture.source.maps) {
    final sourceMap = original.map;
    final native = result.nativeMaps[sourceMap.sourceMapId]!;
    final placements = native.placedElements
        .where((entry) => entry.id.startsWith('ac12-occ-'))
        .toList();
    var expectedPlacements = 0;
    for (final layer in sourceMap.layers) {
      for (var index = 0; index < layer.cells.length; index++) {
        final tileId = layer.cells[index];
        if (tileId == 0) continue;
        final crop = base.crops.singleWhere((crop) =>
            crop.sourceTilesetId == sourceMap.sourceTilesetId &&
            crop.sourceTileId == tileId);
        if (crop.priority == 0) continue;
        expectedPlacements++;
        final layout = SourceOcclusionLayout.resolve(
            priority: crop.priority,
            sourcePlayerDepthOffsetPx: 32,
            x: index % sourceMap.width,
            y: index ~/ sourceMap.width,
            mapSize: native.size);
        final id = 'ac12-occ-${canonicalHashOf({
              'crop': crop.toJson(),
              'atlasOffsetY': layout.atlasOffsetY,
              'sourcePlayerDepthOffsetPx': 32
            }).value.substring(0, 24)}';
        final placed = placements.singleWhere((entry) =>
            entry.id ==
            'ac12-occ-${sourceMap.sourceMapId}-${layer.sourceZ}-$index');
        expect(placed.elementId, id);
        expect(placed.pos, layout.logicalPos);
        expect(placed.applyCollision, isFalse);
        expect(placed.visualOrder, layer.sourceZ * layer.cells.length + index);
        final element = elements[id]!;
        expect(element.tilesetId, element.frames.first.tilesetId);
        final mask = element.collisionProfile!.occlusionMask!;
        expect(mask.widthPx, 32);
        expect(mask.heightPx, layout.frameHeightTiles * 32);
        expect(element.collisionProfile!.collisionMask, isNull);
        final maskPixels = ElementCollisionMaskCodec.decodePackedBits(
            widthPx: mask.widthPx,
            heightPx: mask.heightPx,
            dataBase64: mask.dataBase64);
        for (var y = 0; y < mask.heightPx; y++) {
          for (var x = 0; x < 32; x++) {
            expect(maskPixels[y * 32 + x],
                y >= layout.topPaddingPx && y < layout.topPaddingPx + 32);
          }
        }
        final (sourceRaster, atlas) = sources[crop.nativeTilesetId]!;
        final animation = atlas.tileAnimations
            .where((entry) => entry.tileId == crop.nativeLocalTileId)
            .firstOrNull;
        final sourceFrames = animation?.frames ??
            [
              ProjectImageCollectionAnimationFrame(
                  tileId: crop.nativeLocalTileId, durationMs: 0)
            ];
        expect(element.frames, hasLength(sourceFrames.length));
        for (var frameIndex = 0;
            frameIndex < sourceFrames.length;
            frameIndex++) {
          final frame = element.frames[frameIndex];
          final sourceFrame = sourceFrames[frameIndex];
          final raster = rasters[frame.tilesetId]!;
          expect(frame.durationMs,
              sourceFrame.durationMs == 0 ? null : sourceFrame.durationMs);
          expect(frame.source.width, 1);
          expect(frame.source.height, layout.frameHeightTiles);
          expect(frame.source.x * 32 + 32, lessThanOrEqualTo(raster.width));
          expect((frame.source.y + frame.source.height) * 32,
              lessThanOrEqualTo(raster.height));
          final tileset = result.mutations.singleWhere((mutation) =>
              mutation.actionId == 'tileset.upsert' &&
              (mutation.parameters['tileset'] as Map)['id'] == frame.tilesetId);
          final targetAtlas = ProjectTilesetEntry.fromJson(
                  Map<String, dynamic>.from(
                      tileset.parameters['tileset'] as Map))
              .source as ProjectRegularAtlasTilesetSource;
          expect(targetAtlas.pixelOffsetY, layout.atlasOffsetY);
          expect(
              placed.pos.y * 32 +
                  targetAtlas.pixelOffsetY +
                  frame.source.height * 32,
              layout.depthSortYPx);
          final scale = raster.format == image.Format.uint16 &&
                  sourceRaster.format != image.Format.uint16
              ? 257
              : 1;
          for (var y = 0; y < mask.heightPx; y++) {
            for (var x = 0; x < 32; x++) {
              final pixel = raster.getPixel(
                  frame.source.x * 32 + x, frame.source.y * 32 + y);
              final expected =
                  y >= layout.topPaddingPx && y < layout.topPaddingPx + 32
                      ? sourceRaster.getPixel(
                          sourceFrame.tileId % atlas.columns * 32 + x,
                          sourceFrame.tileId ~/ atlas.columns * 32 +
                              y -
                              layout.topPaddingPx)
                      : null;
              expect(
                  [pixel.r, pixel.g, pixel.b, pixel.a],
                  expected == null
                      ? [0, 0, 0, 0]
                      : [
                          expected.r * scale,
                          expected.g * scale,
                          expected.b * scale,
                          expected.a * scale
                        ]);
            }
          }
        }
      }
    }
    expect(placements, hasLength(expectedPlacements));
    expect(() => MapValidator.validate(native), returnsNormally);
  }
}
