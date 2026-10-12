import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;

import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'literal_tile_fixture.dart';

final class OriginalAssetFixture {
  OriginalAssetFixture._(this.literalFixture, this.pngBytes, this.rgba);

  final LiteralTileFixture literalFixture;
  final Uint8List pngBytes;
  final Uint8List rgba;
  static const width = 256;
  static const height = 256;
  static const imagePath = 'Graphics/Tilesets/OriginalAssets.png';

  static Future<OriginalAssetFixture> create({
    String namespace = 'original-assets-fixture',
    bool reverseManifest = false,
    String? sourceRootPath,
    bool includeUnplacedAlphaIsland = false,
  }) async {
    final pixels = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final color =
            includeUnplacedAlphaIsland && x < 64 && y >= 192 && y < 224
                ? [101, 71, 31, x % 7 == 0 ? 127 : 255]
                : _sourceColor(x, y);
        final offset = (y * width + x) * 4;
        pixels.setRange(offset, offset + 4, color);
      }
    }
    final raster = image.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixels.buffer,
        numChannels: 4,
        order: image.ChannelOrder.rgba);
    final png = Uint8List.fromList(image.encodePng(raster));
    final fixture = await LiteralTileFixture.create(
      namespace: namespace,
      reverseManifest: reverseManifest,
      sourceRootPath: sourceRootPath,
      tilesets: [
        LiteralFixtureTileset(
          id: 1,
          imageName: 'OriginalAssets',
          png: png,
          priorities: {388: 2, 389: 2},
        ),
      ],
      maps: [
        LiteralFixtureMap(id: 1, width: 2, height: 3, layers: [
          [384, 385, 392, 393, 400, 401],
          List.filled(6, 0),
          List.filled(6, 0),
        ]),
        LiteralFixtureMap(id: 8, width: 2, height: 3, layers: [
          [0, 0, 436, 0, 444, 445],
          List.filled(6, 0),
          [388, 389, 0, 0, 0, 0],
        ]),
        LiteralFixtureMap(id: 12, width: 4, height: 3, layers: [
          [384, 385, 384, 385, 392, 393, 392, 393, 400, 401, 400, 401],
          List.filled(12, 0),
          List.filled(12, 0),
        ]),
        LiteralFixtureMap(id: 20, width: 2, height: 1, layers: [
          [384, 446],
          [0, 0],
          [0, 0],
        ]),
        LiteralFixtureMap(id: 21, width: 2, height: 1, layers: [
          [385, 446],
          [0, 0],
          [0, 0],
        ]),
      ],
    );
    return OriginalAssetFixture._(
        fixture, png.asUnmodifiableView(), pixels.asUnmodifiableView());
  }

  Future<LiteralTileComposition> compose({
    String parentPath = '/private/tmp/original-asset-output',
  }) =>
      const LiteralTileComposer().compose(
        source: literalFixture.source,
        files: literalFixture.files,
        selectedSourceMapIds: const [1, 8, 12, 20, 21],
        projectName: 'Controlled original asset fixture',
        parentPath: parentPath,
        folderName: 'original-asset-project',
        sourceRootPath: literalFixture.sourceRootPath,
      );

  AssetCandidate treeCandidate({
    AssetOutputMode outputMode = AssetOutputMode.standaloneObjects,
  }) =>
      _candidate(
          'tree',
          1,
          64,
          96,
          [
            _part('tree-a', 0, 0, 64, 96, 0, 0, 0, 0, 384, 1),
          ],
          outputMode: outputMode);

  AssetCandidate houseCandidate({
    AssetOutputMode outputMode = AssetOutputMode.standaloneObjects,
  }) =>
      _candidate(
          'house',
          8,
          64,
          96,
          [
            _part('roof', 128, 0, 64, 32, 0, 0, 2, 2, 388, 8),
            _part('facade-a', 128, 192, 32, 32, 0, 32, 0, 0, 436, 8),
            _part('facade-b', 128, 224, 64, 32, 0, 64, 0, 0, 444, 8),
          ],
          outputMode: outputMode);

  AssetCandidate ambiguousCandidate({
    AssetOutputMode outputMode = AssetOutputMode.sharedAtlas,
  }) =>
      _candidate(
          'ambiguous',
          12,
          128,
          96,
          [
            _part('left', 0, 0, 64, 96, 0, 0, 0, 0, 384, 12),
            _part('right', 0, 0, 64, 96, 64, 0, 0, 0, 384, 12),
          ],
          outputMode: outputMode,
          uncertainties: const [
            'Two adjacent occurrences may be two objects rather than one object.'
          ]);

  List<AssetCandidate> sharedCandidates({
    AssetOutputMode outputMode = AssetOutputMode.standaloneObjects,
  }) =>
      [
        _candidate(
            'shared-left',
            20,
            64,
            32,
            [
              _part('left', 0, 0, 32, 32, 0, 0, 0, 0, 384, 20),
              _part('shared', 192, 224, 32, 32, 32, 0, 0, 0, 446, 20),
            ],
            outputMode: outputMode),
        _candidate(
            'shared-right',
            21,
            64,
            32,
            [
              _part('right', 32, 0, 32, 32, 0, 0, 0, 0, 385, 21),
              _part('shared', 192, 224, 32, 32, 32, 0, 0, 0, 446, 21),
            ],
            outputMode: outputMode),
      ];

  AssetCandidate _candidate(String id, int mapId, int canvasWidth,
      int canvasHeight, List<Map<String, Object?>> parts,
      {required AssetOutputMode outputMode,
      List<String> uncertainties = const []}) {
    final snapshot = literalFixture.snapshot;
    final entry =
        snapshot.entries.singleWhere((e) => e.relativePath == imagePath);
    return AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': 'original-asset:$id',
      'revision': 1,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sources': [
        {
          'fileId': entry.fileId.value,
          'contentHash': entry.sha256!.value,
          'pixelWidth': width,
          'pixelHeight': height
        },
      ],
      'name': 'Controlled original $id',
      'category': 'unclassified',
      'state': 'needsReview',
      'parts': parts,
      'canvasSize': {'width': canvasWidth, 'height': canvasHeight},
      'anchor': {
        'unit': 'pixel',
        'x': canvasWidth ~/ 2,
        'y': canvasHeight,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': outputMode.name,
      'evidence': [
        {
          'type': 'test',
          'summary': 'Controlled original geometry; no production approval.',
          'reference': 'original-asset-fixture:map:$mapId'
        },
      ],
      'uncertainties': uncertainties,
      'approvedRevision': null,
    });
  }

  Map<String, Object?> _part(String id, int x, int y, int w, int h, int dx,
          int dy, int z, int priority, int tileId, int mapId) =>
      {
        'partId': id,
        'sourceFileId': literalFixture.snapshot.entries
            .singleWhere((e) => e.relativePath == imagePath)
            .fileId
            .value,
        'sourceRect': {'x': x, 'y': y, 'width': w, 'height': h},
        'destinationOffset': {'x': dx, 'y': dy},
        'sourceLayer': z,
        'sourcePriority': priority,
        'quarterTurns': 0,
        'reflected': false,
        'locator': {
          'file': 'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata',
          'mapId': mapId,
          'eventId': null,
          'pageIndex': null,
          'commandIndex': null,
          'tileId': tileId,
          'line': null
        },
      };

  Uint8List get expectedTreeRgba {
    final result = Uint8List(64 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 64; x++) {
        result.setRange(
            (y * 64 + x) * 4, (y * 64 + x) * 4 + 4, _sourceColor(x, y));
      }
    }
    return result.asUnmodifiableView();
  }

  Uint8List get expectedHouseRgba {
    final result = Uint8List(64 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 64; x++) {
        if (y >= 32 && y < 64 && x >= 32) continue;
        final sy = y < 32 ? y : y + 160;
        result.setRange(
            (y * 64 + x) * 4, (y * 64 + x) * 4 + 4, _sourceColor(x + 128, sy));
      }
    }
    return result.asUnmodifiableView();
  }

  static List<int> _sourceColor(int x, int y) {
    if (x < 64 && y < 96) {
      final alpha = x % 11 == 0
          ? 0
          : x % 11 == 1
              ? 127
              : 255;
      if (x == 2 && y == 2) return [255, 0, 255, 255];
      return [(17 + x * 3) % 256, (61 + y * 5) % 256, 91, alpha];
    }
    if (x >= 128 && x < 192 && y < 32) {
      return [151, (19 + x + y) % 256, 37, x % 9 == 0 ? 127 : 255];
    }
    if (x >= 128 && x < 192 && y >= 32 && y < 192) {
      return [255, 0, 255, 255];
    }
    if (x >= 128 && x < 192 && y >= 192) {
      return [43, (71 + y) % 256, (113 + x) % 256, 255];
    }
    if (x >= 192 && x < 224 && y >= 224) return [29, 41, 53, 127];
    return [7, 13, 23, 0];
  }
}
