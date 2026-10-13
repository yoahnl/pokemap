import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

final class NativeTerrainBrush {
  factory NativeTerrainBrush.compile({
    required List<int> sourcePngBytes,
    required String tilesetId,
    required String atlasId,
    required String materialId,
    required String presetId,
    required String name,
  }) {
    for (final value in [tilesetId, atlasId, materialId, presetId, name]) {
      if (value.isEmpty || value != value.trim()) {
        throw const FormatException('terrain_brush.identity.invalid');
      }
    }
    if (sourcePngBytes.length > maximumSourcePngBytes ||
        sourcePngBytes.any((value) => value < 0 || value > 255)) {
      throw const FormatException('terrain_brush.source.bytes');
    }
    final bytes = Uint8List.fromList(sourcePngBytes);
    final source = _decodeSource(bytes);
    final raster = image.Image(width: 128, height: 128, numChannels: 4);
    for (var mask = 0; mask < 16; mask++) {
      for (var quadrantY = 0; quadrantY < 2; quadrantY++) {
        final verticalBit =
            quadrantY == 0 ? smartTileNorthBit : smartTileSouthBit;
        final row = mask & verticalBit != 0 ? 1 : quadrantY * 2;
        for (var quadrantX = 0; quadrantX < 2; quadrantX++) {
          final horizontalBit =
              quadrantX == 0 ? smartTileWestBit : smartTileEastBit;
          final column = mask & horizontalBit != 0 ? 1 : quadrantX * 2;
          for (var y = 0; y < 16; y++) {
            for (var x = 0; x < 16; x++) {
              final pixel = source.getPixel(
                column * 32 + quadrantX * 16 + x,
                row * 32 + quadrantY * 16 + y,
              );
              raster.setPixelRgba(
                (mask % 4) * 32 + quadrantX * 16 + x,
                (mask ~/ 4) * 32 + quadrantY * 16 + y,
                pixel.r,
                pixel.g,
                pixel.b,
                pixel.a,
              );
            }
          }
        }
      }
    }
    final atlas = ProjectSmartTileAtlas(
      id: atlasId,
      name: name,
      tilesetId: tilesetId,
      columns: 4,
      rows: 4,
    );
    final material = ProjectSmartTileMaterial(
      id: materialId,
      name: name,
      connectionGroupId: materialId,
      pathSurfaceKind: PathSurfaceKind.path,
    );
    final preset = ProjectSmartTilePreset(
      id: presetId,
      name: name,
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.cardinal4,
      templateHint: SmartTileTemplateHint.edge16,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: materialId,
      allowedMaterialIds: [materialId],
      rules: [
        for (var mask = 0; mask < 16; mask++)
          SmartTileRule(
            id: '$presetId-mask-$mask',
            centerMatch: SmartTileSlotMatch.material(materialId),
            signature: smartTileSignatureForMask(
              mask,
              topology: SmartTileTopology.cardinal4,
            ),
            candidates: [
              SmartTileCandidate(
                id: '$presetId-form-$mask',
                label: '$name $mask',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: atlasId,
                        column: mask % 4,
                        row: mask ~/ 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
    return NativeTerrainBrush._(
      image.encodePng(raster, level: 9),
      atlas,
      material,
      preset,
    );
  }

  NativeTerrainBrush._(
    Uint8List bytes,
    this.atlas,
    this.material,
    this.preset,
  ) : imageBytes = bytes.asUnmodifiableView();

  static const maximumSourcePngBytes = 1024 * 1024;

  final Uint8List imageBytes;
  final ProjectSmartTileAtlas atlas;
  final ProjectSmartTileMaterial material;
  final ProjectSmartTilePreset preset;
}

image.Image _decodeSource(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 ||
      signature.indexed.any((entry) => bytes[entry.$1] != entry.$2)) {
    throw const FormatException('terrain_brush.source.png');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(8) != 13 ||
      ascii.decode(bytes.sublist(12, 16)) != 'IHDR' ||
      data.getUint32(16) != 96 ||
      data.getUint32(20) != 96 ||
      bytes[24] != 8 ||
      (bytes[25] != 2 && bytes[25] != 6) ||
      bytes[26] != 0 ||
      bytes[27] != 0 ||
      bytes[28] != 0) {
    throw const FormatException('terrain_brush.source.geometry');
  }
  final channels = bytes[25] == 6 ? 4 : 3;
  final counter = _RasterByteCounter(96 * (96 * channels + 1));
  final decompressor = ZLibCodec().decoder.startChunkedConversion(counter);
  var offset = 33;
  var foundData = false;
  var ended = false;
  try {
    while (offset < bytes.length) {
      if (bytes.length - offset < 12) {
        throw const FormatException('terrain_brush.source.png');
      }
      final length = data.getUint32(offset);
      if (length > bytes.length - offset - 12) {
        throw const FormatException('terrain_brush.source.png');
      }
      final kind = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      if (kind == 'IDAT') {
        foundData = true;
        decompressor
            .add(Uint8List.sublistView(bytes, offset + 8, offset + 8 + length));
      } else if (kind == 'IEND' &&
          length == 0 &&
          foundData &&
          offset + 12 == bytes.length) {
        ended = true;
      } else {
        throw const FormatException('terrain_brush.source.png');
      }
      offset += length + 12;
    }
    decompressor.close();
    if (!ended || counter.count != counter.expected) {
      throw const FormatException('terrain_brush.source.raster');
    }
    final source = image.decodePng(bytes);
    if (source == null || source.numFrames != 1 || source.bitsPerChannel != 8) {
      throw const FormatException('terrain_brush.source.png');
    }
    return source;
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('terrain_brush.source.png');
  }
}

final class _RasterByteCounter extends ByteConversionSinkBase {
  _RasterByteCounter(this.expected);

  final int expected;
  int count = 0;

  @override
  void add(List<int> chunk) {
    count += chunk.length;
    if (count > expected) {
      throw const FormatException('terrain_brush.source.raster');
    }
  }

  @override
  void close() {}
}
