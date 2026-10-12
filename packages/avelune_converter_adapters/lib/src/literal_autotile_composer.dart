import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

enum LiteralAutotileFormat { simple, standard, extended }

final class LiteralAutotilePart {
  const LiteralAutotilePart(
      {required this.x,
      required this.y,
      required this.width,
      required this.height,
      required this.destinationX,
      required this.destinationY});
  final int x;
  final int y;
  final int width;
  final int height;
  final int destinationX;
  final int destinationY;
}

final class LiteralAutotileDiagnostic {
  const LiteralAutotileDiagnostic(this.code, this.message, {this.locator});

  final String code;
  final String message;
  final SourceLocator? locator;
}

final class LiteralAutotileFailure implements Exception {
  const LiteralAutotileFailure(this.code, this.message, {this.locator});

  final String code;
  final String message;
  final SourceLocator? locator;

  @override
  String toString() => 'LiteralAutotileFailure($code): $message';
}

final class LiteralAutotileProfile {
  LiteralAutotileProfile._({
    required this.sourceSnapshotHash,
    required this.clockAttested,
    required this.extendedAttested,
    required this.baseFrameDurationMs,
    required this.provenance,
  });

  factory LiteralAutotileProfile.unverified({
    required Sha256Hash sourceSnapshotHash,
  }) =>
      LiteralAutotileProfile._(
        sourceSnapshotHash: sourceSnapshotHash,
        clockAttested: false,
        extendedAttested: false,
        baseFrameDurationMs: null,
        provenance: Map.unmodifiable({
          'state': 'unverified',
          'sourceSnapshotHash': sourceSnapshotHash.value
        }),
      );

  final Sha256Hash sourceSnapshotHash;
  final bool clockAttested;
  final bool extendedAttested;
  final int? baseFrameDurationMs;
  final Map<String, Object?> provenance;
}

final class LiteralAutotileComposition {
  LiteralAutotileComposition._({
    required this.artifact,
    required this.sourceArtifact,
    required this.sourceTilesetId,
    required this.autotileSlot,
    required this.nativeTilesetId,
    required this.sourceFrameCount,
    required this.sourcePixelWidth,
    required this.sourcePixelHeight,
    required this.format,
    required this.firstFrameOnly,
    required this.degraded,
    required this.frameDurationMs,
    required this.sourceSnapshotHash,
    required this.sourceFileHash,
    required this.sourceFileId,
    required this.tileAnimations,
    required this.diagnostics,
    required this.provenance,
    required this.compositionHash,
  });

  final NativeArtifact artifact;
  final NativeArtifact sourceArtifact;
  final int sourceTilesetId;
  final int autotileSlot;
  final String nativeTilesetId;
  final int sourceFrameCount;
  final int sourcePixelWidth;
  final int sourcePixelHeight;
  final LiteralAutotileFormat format;
  final bool firstFrameOnly;
  final bool degraded;
  final int? frameDurationMs;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash sourceFileHash;
  final ConverterId sourceFileId;
  final List<ProjectRegularAtlasTileAnimation> tileAnimations;
  final List<LiteralAutotileDiagnostic> diagnostics;
  final Map<String, Object?> provenance;
  final Sha256Hash compositionHash;

  int get pixelWidth => 256;
  int get pixelHeight => 192 * sourceFrameCount;
  bool get animationVerified => tileAnimations.isNotEmpty && !degraded;

  int localTileId({int frame = 0, required int variant}) {
    if (frame < 0 ||
        frame >= sourceFrameCount ||
        variant < 0 ||
        variant >= 48) {
      throw RangeError('Autotile frame or stored variant is out of bounds');
    }
    return frame * 48 + variant;
  }

  List<LiteralAutotilePart> sourceParts(
      {required int frame, required int variant}) {
    localTileId(frame: frame, variant: variant);
    final rectangles = _sourceRects(format, variant);
    final frameWidth = format == LiteralAutotileFormat.simple ? 32 : 96;
    return List.unmodifiable([
      for (var quarter = 0; quarter < 4; quarter++)
        LiteralAutotilePart(
            x: frame * frameWidth + rectangles[quarter].$1,
            y: rectangles[quarter].$2,
            width: 16,
            height: 16,
            destinationX: quarter % 2 * 16,
            destinationY: quarter ~/ 2 * 16)
    ]);
  }
}

final class LiteralAutotileComposer {
  const LiteralAutotileComposer();

  static String get attestedArchiveSha256 => _scriptsHash;

  static int? attestedFrameDurationMs(String sourceName) {
    final suffix =
        RegExp(r'\[[ \t\n\r\f\v]*([0-9]+)[ \t\n\r\f\v]*\][ \t\n\r\f\v]*$')
            .firstMatch(sourceName);
    if (suffix == null) return 250;
    final units = int.tryParse(suffix.group(1)!);
    if (units == null || units <= 0 || units > 2147483647 ~/ 50) return null;
    return units * 50;
  }

  Future<LiteralAutotileProfile> inspectProfile({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    if (snapshot.state != SourceScanState.complete) {
      throw const LiteralAutotileFailure('autotile.snapshot.incomplete',
          'Autotile inspection requires a complete source snapshot');
    }
    final entries = snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) == 'data/scripts.rxdata');
    if (entries.length != 1) {
      return LiteralAutotileProfile.unverified(
          sourceSnapshotHash: snapshot.canonicalHash);
    }
    final entry = entries.single;
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256?.value != _scriptsHash) {
      return LiteralAutotileProfile.unverified(
          sourceSnapshotHash: snapshot.canonicalHash);
    }
    final bytes = await _readVerified(entry, files, limits, cancellation);
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: entry.relativePath,
        limits: MarshalDecodeLimits(
          maxInputBytes: limits.maxArtifactBytes,
          maxDepth: math.min(128, limits.jsonLimits.maxDepth),
          maxNodes: math.min(100000, limits.jsonLimits.maxNodes),
          maxObjects: math.min(100000, limits.jsonLimits.maxNodes),
          maxSymbols: math.min(4096, limits.jsonLimits.maxNodes),
          maxContainerEntries: math.min(4096, limits.jsonLimits.maxNodes),
          maxTotalEntries: math.min(100000, limits.jsonLimits.maxNodes),
          maxStringBytes: limits.maxArtifactBytes,
          maxTotalStringBytes: limits.maxTotalArtifactBytes,
          maxTotalLocationCodeUnits: limits.jsonLimits.maxTextCodeUnits,
        ));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array) {
      throw const LiteralAutotileFailure(
          'autotile.profile.shape', 'Attested script archive is not an array');
    }
    final facts = <String, Object?>{};
    var totalExpanded = 0;
    for (final specification in _scriptPins) {
      cancellation?.check();
      if (specification.$1 >= root.elements.length) {
        throw const LiteralAutotileFailure(
            'autotile.profile.shape', 'Attested script section is missing');
      }
      final tuple = document.node(root.elements[specification.$1]);
      if (tuple.kind != MarshalKind.array || tuple.elements.length != 3) {
        throw const LiteralAutotileFailure(
            'autotile.profile.shape', 'Attested script row is malformed');
      }
      final name = document.node(tuple.elements[1]);
      final compressed = document.node(tuple.elements[2]);
      if (name.kind != MarshalKind.string ||
          name.text().text != specification.$2 ||
          compressed.kind != MarshalKind.string ||
          compressed.bytes == null) {
        throw const LiteralAutotileFailure(
            'autotile.profile.shape', 'Attested script identity is malformed');
      }
      final remaining = limits.maxTotalArtifactBytes - totalExpanded;
      if (remaining <= 0) {
        throw const LiteralAutotileFailure('autotile.quota.scripts',
            'Expanded script inspection exceeds the aggregate byte budget');
      }
      final raw = const BoundedZlibDecoder().decode(compressed.bytes!,
          sourcePath: entry.relativePath,
          baseOffset: compressed.dataOffset ?? compressed.location.byteOffset,
          limits: ZlibDecodeLimits(
              maxInputBytes: limits.maxArtifactBytes,
              maxOutputBytes:
                  math.min(remaining, limits.jsonLimits.maxStringCodeUnits)));
      totalExpanded += raw.length;
      if (sha256.convert(raw).toString() != specification.$3) {
        throw const LiteralAutotileFailure(
            'autotile.profile.hash', 'Attested script section hash differs');
      }
      facts[specification.$2] = {
        'sectionIndex': specification.$1,
        'sha256': specification.$3,
        'byteLength': raw.length,
      };
      await Future<void>.delayed(Duration.zero);
    }
    cancellation?.check();
    final provenance = _freeze({
      'state': 'attested',
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourceFileId': entry.fileId.value,
      'sourceFilePath': entry.relativePath,
      'sourceFileHash': entry.sha256!.value,
      'sections': facts,
      'baseFrameDurationMs': 250,
      'nameSuffixUnitMs': 50,
      'clockScale': 1,
      'clockReferences': [
        'TilemapRenderer:24-26',
        'TilemapRenderer:148-152',
        'TilemapRenderer:191-196'
      ],
      'runtimeSpeedTogglesPreserved': false,
    }, limits);
    return LiteralAutotileProfile._(
        sourceSnapshotHash: snapshot.canonicalHash,
        clockAttested: true,
        extendedAttested: true,
        baseFrameDurationMs: 250,
        provenance: provenance);
  }

  Future<LiteralAutotileComposition> compose({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required int sourceTilesetId,
    required int autotileSlot,
    required LiteralAutotileProfile profile,
    bool nativeAnimationAvailable = true,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    final snapshot = source.snapshot;
    if (!source.canPlan || snapshot.state != SourceScanState.complete) {
      throw const LiteralAutotileFailure('autotile.source.blocked',
          'Autotile composition requires a complete normalized source');
    }
    if (profile.sourceSnapshotHash != snapshot.canonicalHash) {
      throw const LiteralAutotileFailure('autotile.profile.snapshot',
          'Autotile profile belongs to a different source snapshot');
    }
    if (sourceTilesetId <= 0 || autotileSlot < 0 || autotileSlot > 6) {
      throw const LiteralAutotileFailure('autotile.source.identity',
          'Invalid source tileset or autotile slot');
    }
    final tilesets = source.tilesets
        .where((tileset) => tileset.sourceTilesetId == sourceTilesetId);
    if (tilesets.length != 1) {
      throw const LiteralAutotileFailure(
          'autotile.source.tileset', 'Source tileset is missing or ambiguous');
    }
    final tileset = tilesets.single;
    final references = tileset.images.where((reference) =>
        reference.role == 'autotile' && reference.slot == autotileSlot);
    if (references.length != 1 ||
        references.single.state != 'resolved' ||
        references.single.sourceFile == null) {
      throw LiteralAutotileFailure(
          'autotile.source.image', 'Autotile image is missing or unresolved',
          locator: tileset.locator);
    }
    final reference = references.single;
    final entry = reference.sourceFile!;
    final members =
        snapshot.entries.where((value) => value.fileId == entry.fileId);
    if (members.length != 1 ||
        canonicalHashOf(members.single.toJson()) !=
            canonicalHashOf(entry.toJson()) ||
        entry.kind != SourceNodeKind.file ||
        entry.format != 'raster' ||
        !entry.relativePath.toLowerCase().endsWith('.png')) {
      throw LiteralAutotileFailure('autotile.source.image',
          'Autotile image is not an admitted PNG in this snapshot',
          locator: reference.locator);
    }
    final bytes = await _readVerified(entry, files, limits, cancellation);
    final (width, height) =
        const NativePngValidator().headerDimensions(bytes, limits: limits);
    final format = switch (height) {
      32 => LiteralAutotileFormat.simple,
      128 => LiteralAutotileFormat.standard,
      192 => LiteralAutotileFormat.extended,
      _ => null,
    };
    if (format == null) {
      throw LiteralAutotileFailure('autotile.geometry',
          'Autotile height must be 32, 128, or attested 192 pixels',
          locator: reference.locator);
    }
    if (format == LiteralAutotileFormat.extended && !profile.extendedAttested) {
      throw LiteralAutotileFailure('autotile.extended.unverified',
          'Extended autotile geometry requires the attested source expander',
          locator: reference.locator);
    }
    final frameWidth = format == LiteralAutotileFormat.simple ? 32 : 96;
    if (width % frameWidth != 0) {
      throw LiteralAutotileFailure('autotile.geometry',
          'Autotile width must contain complete source frames',
          locator: reference.locator);
    }
    final frameCount = width ~/ frameWidth;
    final outputPixels = frameCount * 256 * 192;
    if (outputPixels > limits.maxImagePixels - width * height) {
      throw LiteralAutotileFailure('autotile.quota.pixels',
          'Source and generated autotile pixels exceed the aggregate budget',
          locator: reference.locator);
    }
    final channelBytes = bytes[24] == 16 ? 2 : 1;
    final rowBytes = 1 + 256 * 4 * channelBytes;
    final rawLength = rowBytes * 192 * frameCount;
    final outputBound = rawLength + 5 * ((rawLength + 65534) ~/ 65535) + 6 + 57;
    if (outputBound > limits.maxArtifactBytes ||
        outputBound > limits.maxTotalArtifactBytes - bytes.length) {
      throw LiteralAutotileFailure('autotile.quota.output',
          'Generated autotile PNG exceeds its conservative byte budget',
          locator: reference.locator);
    }
    final requiredNodes = 1500 + frameCount * 48 * 6;
    if (requiredNodes > limits.jsonLimits.maxNodes) {
      throw LiteralAutotileFailure('autotile.quota.metadata',
          'Autotile animation and provenance exceed the metadata budget',
          locator: reference.locator);
    }
    const NativePngValidator().validate(bytes, limits: limits);
    cancellation?.check();
    final decoded = image.decodePng(Uint8List.fromList(bytes));
    if (decoded == null || decoded.width != width || decoded.height != height) {
      throw LiteralAutotileFailure('autotile.image.decode',
          'Autotile PNG could not be decoded at its admitted dimensions',
          locator: reference.locator);
    }
    final scanlines = Uint8List(rawLength);
    for (var frame = 0; frame < frameCount; frame++) {
      cancellation?.check();
      for (var variant = 0; variant < 48; variant++) {
        final rects = _sourceRects(format, variant);
        for (var quarter = 0; quarter < 4; quarter++) {
          final sourceX = frame * frameWidth + rects[quarter].$1;
          final sourceY = rects[quarter].$2;
          final targetX = variant % 8 * 32 + quarter % 2 * 16;
          final targetY = frame * 192 + variant ~/ 8 * 32 + quarter ~/ 2 * 16;
          for (var y = 0; y < 16; y++) {
            var target =
                (targetY + y) * rowBytes + 1 + targetX * 4 * channelBytes;
            for (var x = 0; x < 16; x++) {
              final pixel = decoded.getPixel(sourceX + x, sourceY + y);
              for (final value in [pixel.r, pixel.g, pixel.b, pixel.a]) {
                if (channelBytes == 2) scanlines[target++] = value.toInt() >> 8;
                scanlines[target++] = value.toInt() & 255;
              }
            }
          }
        }
        if (variant % 8 == 7) {
          await Future<void>.delayed(Duration.zero);
          cancellation?.check();
        }
      }
    }
    final output =
        _encodePng(scanlines, 256, frameCount * 192, channelBytes * 8);
    if (output.length > outputBound) {
      throw const LiteralAutotileFailure('autotile.quota.output',
          'PNG encoder exceeded its reserved output bound');
    }
    final artifact = NativeArtifact(bytes: output, limits: limits);
    final diagnostics = <LiteralAutotileDiagnostic>[];
    int? duration;
    if (profile.clockAttested) {
      duration = attestedFrameDurationMs(reference.sourceName);
      if (duration == null || duration <= 0 || duration > 2147483647) {
        duration = null;
        diagnostics.add(LiteralAutotileDiagnostic('autotile.clock.invalid',
            'Source suffix does not specify a positive bounded frame duration',
            locator: reference.locator));
      }
    }
    final animated =
        frameCount > 1 && nativeAnimationAvailable && duration != null;
    if (frameCount > 1 && !profile.clockAttested) {
      diagnostics.add(LiteralAutotileDiagnostic('autotile.clock.unverified',
          'Source clock is unverified; all frames are retained and only the first frame is active',
          locator: reference.locator));
    }
    if (frameCount > 1 && !nativeAnimationAvailable) {
      diagnostics.add(LiteralAutotileDiagnostic(
          'autotile.animation.unavailable',
          'Native animation is unavailable; all frames are retained and only the first frame is active',
          locator: reference.locator));
    }
    final animations = <ProjectRegularAtlasTileAnimation>[];
    if (animated) {
      for (var variant = 0; variant < 48; variant++) {
        animations.add(ProjectRegularAtlasTileAnimation(
            tileId: variant,
            frames: List.unmodifiable([
              for (var frame = 0; frame < frameCount; frame++)
                ProjectImageCollectionAnimationFrame(
                    tileId: frame * 48 + variant, durationMs: duration)
            ])));
      }
      diagnostics.add(LiteralAutotileDiagnostic('autotile.clock.base_scale',
          'Animation preserves the attested base clock at 1x; source runtime speed toggles are not represented',
          locator: reference.locator));
    }
    final nativeTilesetId = 'auto_${canonicalHashOf({
          'namespace': snapshot.logicalProjectNamespace.value,
          'tileset': sourceTilesetId,
          'slot': autotileSlot
        }).value.substring(0, 24)}';
    final provenance = _freeze({
      'version': 1,
      'kind': 'literalAutotile',
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourceFileId': entry.fileId.value,
      'sourceFilePath': entry.relativePath,
      'sourceFileHash': entry.sha256!.value,
      'sourceTilesetId': sourceTilesetId,
      'autotileSlot': autotileSlot,
      'sourceName': reference.sourceName,
      'sourceLocator': reference.locator.toJson(),
      'nativeTilesetId': nativeTilesetId,
      'generatedImageHash': artifact.rawSha256.value,
      'sourcePixelWidth': width,
      'sourcePixelHeight': height,
      'pixelWidth': 256,
      'pixelHeight': frameCount * 192,
      'sourceFrameCount': frameCount,
      'format': format.name,
      'variantCount': 48,
      'localTileIdRule': 'frame*48+storedVariant',
      'neighborhoodRecomputed': false,
      'patternSha256': _scriptPins[2].$3,
      'patternReference': 'TileDrawingHelper:5-18',
      'geometryReference': 'AutotileExpander:9-65',
      'sourceProfile': profile.provenance,
      'firstFrameOnly': !animated,
      'degraded': frameCount > 1 && !animated,
      'frameDurationMs': duration,
      'nativeAnimationAvailable': nativeAnimationAvailable,
      'tileAnimations':
          animations.map((animation) => animation.toJson()).toList(),
      'diagnostics': diagnostics.map((diagnostic) => diagnostic.code).toList(),
    }, limits);
    cancellation?.check();
    return LiteralAutotileComposition._(
        artifact: artifact,
        sourceArtifact: NativeArtifact(
            bytes: bytes, expectedSha256: entry.sha256, limits: limits),
        sourceTilesetId: sourceTilesetId,
        autotileSlot: autotileSlot,
        nativeTilesetId: nativeTilesetId,
        sourceFrameCount: frameCount,
        sourcePixelWidth: width,
        sourcePixelHeight: height,
        format: format,
        firstFrameOnly: !animated,
        degraded: frameCount > 1 && !animated,
        frameDurationMs: duration,
        sourceSnapshotHash: snapshot.canonicalHash,
        sourceFileHash: entry.sha256!,
        sourceFileId: entry.fileId,
        tileAnimations: List.unmodifiable(animations),
        diagnostics: List.unmodifiable(diagnostics),
        provenance: provenance,
        compositionHash:
            canonicalHashOf(provenance, limits: limits.jsonLimits));
  }
}

Future<List<int>> _readVerified(SourceFileEntry entry, SourceFilePort files,
    NativeWriteLimits limits, ScanCancellation? cancellation) async {
  cancellation?.check();
  if (entry.kind != SourceNodeKind.file || entry.sha256 == null) {
    throw const LiteralAutotileFailure('autotile.source.hash',
        'Source file must be regular and have an admitted byte hash');
  }
  if (entry.byteLength > limits.maxArtifactBytes ||
      entry.byteLength > limits.maxTotalArtifactBytes) {
    throw const LiteralAutotileFailure(
        'autotile.quota.input', 'Source file exceeds the admitted byte budget');
  }
  final bytes = await files.read(entry.fileId);
  cancellation?.check();
  if (bytes.length != entry.byteLength ||
      sha256.convert(bytes).toString() != entry.sha256!.value) {
    throw const LiteralAutotileFailure('autotile.source.hash',
        'Source bytes differ from the admitted snapshot');
  }
  return bytes;
}

Map<String, Object?> _freeze(
    Map<String, Object?> value, NativeWriteLimits limits) {
  Object? freeze(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.unmodifiable(
          value.map((key, item) => MapEntry(key, freeze(item))));
    }
    if (value is List) return List<Object?>.unmodifiable(value.map(freeze));
    return value;
  }

  return freeze(jsonDecode(canonicalJsonOf(value, limits: limits.jsonLimits)))
      as Map<String, Object?>;
}

List<(int, int)> _sourceRects(LiteralAutotileFormat format, int variant) {
  if (format == LiteralAutotileFormat.simple) {
    return const [(0, 0), (16, 0), (0, 16), (16, 16)];
  }
  if (format == LiteralAutotileFormat.extended &&
      _extended.containsKey(variant)) {
    final (x, y) = _extended[variant]!;
    return [(x, y), (x + 16, y), (x, y + 16), (x + 16, y + 16)];
  }
  return [
    for (final quarter in _quarters[variant])
      ((quarter - 1) % 6 * 16, (quarter - 1) ~/ 6 * 16)
  ];
}

Uint8List _encodePng(Uint8List scanlines, int width, int height, int bits) {
  final compressed = ZLibCodec(level: 0).encode(scanlines);
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, bits)
    ..setUint8(9, 6);
  final output = BytesBuilder(copy: false)
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', compressed))
    ..add(_chunk('IEND', const []));
  return output.takeBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final output = Uint8List(data.length + 12);
  ByteData.sublistView(output).setUint32(0, data.length);
  final name = ascii.encode(type);
  output.setRange(4, 8, name);
  output.setRange(8, 8 + data.length, data);
  var crc = 0xffffffff;
  for (var index = 4; index < output.length - 4; index++) {
    crc ^= output[index];
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  ByteData.sublistView(output).setUint32(output.length - 4, crc ^ 0xffffffff);
  return output;
}

const _scriptsHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
const _scriptPins = [
  (
    72,
    'TilemapRenderer',
    '321f334b2eeee0f1fa45d16f52117feb7ea765e17643b88c09a69285ada4bdef'
  ),
  (
    74,
    'AutotileExpander',
    'c40587686d2176794b79aa926e0adc5fdb67db102dd6f14a7e54a1618635e597'
  ),
  (
    75,
    'TileDrawingHelper',
    '2a94034ce77b68faeb8c7620e4a9cf2ceea81580992db7c86424cc3b63393bc7'
  ),
];
const _extended = {1: (0, 128), 2: (32, 128), 4: (32, 160), 8: (0, 160)};
const _quarters = [
  [27, 28, 33, 34],
  [5, 28, 33, 34],
  [27, 6, 33, 34],
  [5, 6, 33, 34],
  [27, 28, 33, 12],
  [5, 28, 33, 12],
  [27, 6, 33, 12],
  [5, 6, 33, 12],
  [27, 28, 11, 34],
  [5, 28, 11, 34],
  [27, 6, 11, 34],
  [5, 6, 11, 34],
  [27, 28, 11, 12],
  [5, 28, 11, 12],
  [27, 6, 11, 12],
  [5, 6, 11, 12],
  [25, 26, 31, 32],
  [25, 6, 31, 32],
  [25, 26, 31, 12],
  [25, 6, 31, 12],
  [15, 16, 21, 22],
  [15, 16, 21, 12],
  [15, 16, 11, 22],
  [15, 16, 11, 12],
  [29, 30, 35, 36],
  [29, 30, 11, 36],
  [5, 30, 35, 36],
  [5, 30, 11, 36],
  [39, 40, 45, 46],
  [5, 40, 45, 46],
  [39, 6, 45, 46],
  [5, 6, 45, 46],
  [25, 30, 31, 36],
  [15, 16, 45, 46],
  [13, 14, 19, 20],
  [13, 14, 19, 12],
  [17, 18, 23, 24],
  [17, 18, 11, 24],
  [41, 42, 47, 48],
  [5, 42, 47, 48],
  [37, 38, 43, 44],
  [37, 6, 43, 44],
  [13, 18, 19, 24],
  [13, 14, 43, 44],
  [37, 42, 43, 48],
  [17, 18, 47, 48],
  [13, 18, 43, 48],
  [1, 2, 7, 8],
];
