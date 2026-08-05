import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';

const int tiledImageCollectionDefaultPageSize = 2048;
const int tiledImageCollectionDefaultPadding = 1;
const int tiledImageCollectionDefaultDecodedPixelBudget = 64 * 1024 * 1024;
const int tiledImageCollectionDefaultGeneratedPixelBudget = 64 * 1024 * 1024;

final class TiledImageCollectionPackingException implements Exception {
  const TiledImageCollectionPackingException(
    this.code,
    this.message, {
    this.source,
  });

  final String code;
  final String message;
  final String? source;

  @override
  String toString() => 'TiledImageCollectionPackingException($code): $message';
}

/// Platform-neutral decoded pixels exchanged with the injected raster codec.
///
/// Bytes use row-major, non-premultiplied RGBA8888 order. This stable form
/// keeps placement and pixel copying canonical without adding an image codec
/// dependency to `map_authoring`.
final class TiledImageCollectionRgbaImage {
  TiledImageCollectionRgbaImage({
    required this.pixelWidth,
    required this.pixelHeight,
    required Iterable<int> rgbaBytes,
  }) : rgbaBytes = List<int>.unmodifiable(_validRgbaBytes(
          rgbaBytes,
          pixelWidth: pixelWidth,
          pixelHeight: pixelHeight,
        ));

  final int pixelWidth;
  final int pixelHeight;
  final List<int> rgbaBytes;
}

final class TiledImageCollectionRasterMetadata {
  const TiledImageCollectionRasterMetadata({
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final int pixelWidth;
  final int pixelHeight;
}

/// Codec boundary owned by platform adapters such as `map_editor` or MCP.
///
/// Implementations decode the first frame only and must emit deterministic PNG
/// bytes for equal RGBA input. The packer owns all geometry and never resizes,
/// filters, blends or otherwise alters decoded pixels.
abstract interface class TiledImageCollectionRasterCodec {
  /// Reads dimensions without allocating the complete decoded pixel buffer.
  TiledImageCollectionRasterMetadata inspect(List<int> encodedBytes);

  TiledImageCollectionRgbaImage decode(List<int> encodedBytes);

  List<int> encodePng(TiledImageCollectionRgbaImage image);
}

/// One staged dependency from a parsed Tiled image collection.
///
/// The normalized TSX source is only a deterministic import key. Generated
/// project pages never retain or read this external path at runtime.
final class TiledImageCollectionPackingInput {
  const TiledImageCollectionPackingInput({
    required this.source,
    required this.bytes,
    required this.declaredPixelWidth,
    required this.declaredPixelHeight,
    this.transparentColor,
  });

  final String source;
  final List<int> bytes;
  final int declaredPixelWidth;
  final int declaredPixelHeight;
  final TilesetTransparentColor? transparentColor;
}

final class TiledImageCollectionPackedPage {
  TiledImageCollectionPackedPage({
    required this.id,
    required this.pixelWidth,
    required this.pixelHeight,
    required List<int> bytes,
  })  : bytes = List<int>.unmodifiable(bytes),
        artifact = ContentArtifactRef.fromBytes(
          bytes,
          mediaType: 'image/png',
        );

  final String id;
  final int pixelWidth;
  final int pixelHeight;
  final List<int> bytes;
  final ContentArtifactRef artifact;
}

final class TiledImageCollectionPackedPlacement {
  const TiledImageCollectionPackedPlacement({
    required this.source,
    required this.pageId,
    required this.sourceRect,
  });

  final String source;
  final String pageId;
  final ProjectTilesetPixelRect sourceRect;
}

final class TiledImageCollectionPackingResult {
  factory TiledImageCollectionPackingResult({
    required Iterable<TiledImageCollectionPackedPage> pages,
    required Iterable<TiledImageCollectionPackedPlacement> placements,
  }) {
    final frozenPages = List<TiledImageCollectionPackedPage>.unmodifiable(
      pages,
    );
    final frozenPlacements =
        List<TiledImageCollectionPackedPlacement>.unmodifiable(placements);
    return TiledImageCollectionPackingResult._(
      pages: frozenPages,
      placements: frozenPlacements,
      placementsBySource:
          Map<String, TiledImageCollectionPackedPlacement>.unmodifiable(
        <String, TiledImageCollectionPackedPlacement>{
          for (final placement in frozenPlacements) placement.source: placement,
        },
      ),
    );
  }

  const TiledImageCollectionPackingResult._({
    required this.pages,
    required this.placements,
    required Map<String, TiledImageCollectionPackedPlacement>
        placementsBySource,
  }) : _placementsBySource = placementsBySource;

  final List<TiledImageCollectionPackedPage> pages;
  final List<TiledImageCollectionPackedPlacement> placements;
  final Map<String, TiledImageCollectionPackedPlacement> _placementsBySource;

  TiledImageCollectionPackedPlacement placementForSource(String source) {
    final placement = _placementsBySource[source];
    if (placement == null) {
      throw TiledImageCollectionPackingException(
        'tileset.tiled.image_dependency_unknown',
        'The packed collection does not contain the requested image.',
        source: source,
      );
    }
    return placement;
  }
}

/// Deterministically packs variable-size collection images into owned PNGs.
///
/// Packing uses stable first-fit shelves over a dimension/source-sorted input.
/// Pixels are copied as RGBA values after applying any per-image TSX chroma
/// key. Page PNGs are exposed through content-addressed artifact references
/// and can be staged transactionally.
final class TiledImageCollectionPacker {
  const TiledImageCollectionPacker({required this.codec});

  final TiledImageCollectionRasterCodec codec;

  TiledImageCollectionPackingResult pack(
    Iterable<TiledImageCollectionPackingInput> inputs, {
    int maximumPageWidth = tiledImageCollectionDefaultPageSize,
    int maximumPageHeight = tiledImageCollectionDefaultPageSize,
    int padding = tiledImageCollectionDefaultPadding,
    int maximumDecodedPixels = tiledImageCollectionDefaultDecodedPixelBudget,
    int maximumGeneratedPixels =
        tiledImageCollectionDefaultGeneratedPixelBudget,
  }) {
    if (maximumPageWidth <= 0 ||
        maximumPageHeight <= 0 ||
        padding < 0 ||
        maximumDecodedPixels <= 0 ||
        maximumGeneratedPixels <= 0) {
      throw const TiledImageCollectionPackingException(
        'tileset.tiled.image_packing_config_invalid',
        'Page dimensions and pixel budgets must be positive and padding must '
            'not be negative.',
      );
    }

    final sourceInputs = inputs.toList(growable: false);
    if (sourceInputs.isEmpty) {
      throw const TiledImageCollectionPackingException(
        'tileset.tiled.image_dependencies_required',
        'An image collection must contain at least one staged image.',
      );
    }

    final seenSources = <String>{};
    final prepared = <_PreparedImage>[];
    var decodedPixels = 0;
    for (final input in sourceInputs) {
      _validateInput(input, seenSources);
      final pixelCount = input.declaredPixelWidth * input.declaredPixelHeight;
      if (pixelCount > maximumDecodedPixels - decodedPixels) {
        throw TiledImageCollectionPackingException(
          'tileset.tiled.image_pixel_budget_exceeded',
          'The decoded image collection exceeds the configured pixel budget.',
          source: input.source,
        );
      }
      decodedPixels += pixelCount;
      prepared.add(_decode(input));
    }

    prepared.sort(_comparePreparedImages);
    final pages = <_PackingPage>[];
    for (final image in prepared) {
      final allocatedWidth = image.width + padding * 2;
      final allocatedHeight = image.height + padding * 2;
      if (allocatedWidth > maximumPageWidth ||
          allocatedHeight > maximumPageHeight) {
        throw TiledImageCollectionPackingException(
          'tileset.tiled.image_page_too_small',
          'The image and its padding do not fit inside one generated page.',
          source: image.source,
        );
      }

      _RawPlacement? placement;
      for (final page in pages) {
        placement = page.tryPlace(
          image,
          allocatedWidth: allocatedWidth,
          allocatedHeight: allocatedHeight,
          maximumWidth: maximumPageWidth,
          maximumHeight: maximumPageHeight,
          padding: padding,
        );
        if (placement != null) break;
      }
      if (placement == null) {
        final page = _PackingPage();
        pages.add(page);
        placement = page.tryPlace(
          image,
          allocatedWidth: allocatedWidth,
          allocatedHeight: allocatedHeight,
          maximumWidth: maximumPageWidth,
          maximumHeight: maximumPageHeight,
          padding: padding,
        );
      }
      if (placement == null) {
        throw TiledImageCollectionPackingException(
          'tileset.tiled.image_page_too_small',
          'The image cannot be placed inside a generated page.',
          source: image.source,
        );
      }
    }

    var generatedPixels = 0;
    for (final page in pages) {
      final pixelCount = page.usedWidth * page.usedHeight;
      if (pixelCount > maximumGeneratedPixels - generatedPixels) {
        throw const TiledImageCollectionPackingException(
          'tileset.tiled.image_page_pixel_budget_exceeded',
          'The generated collection pages exceed the configured pixel budget.',
        );
      }
      generatedPixels += pixelCount;
    }

    final packedPages = <TiledImageCollectionPackedPage>[];
    final packedPlacements = <TiledImageCollectionPackedPlacement>[];
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex += 1) {
      final id = _pageId(pageIndex);
      final rendered = pages[pageIndex].render();
      final encoded = _encodePage(rendered);
      packedPages.add(
        TiledImageCollectionPackedPage(
          id: id,
          pixelWidth: rendered.pixelWidth,
          pixelHeight: rendered.pixelHeight,
          bytes: encoded,
        ),
      );
      for (final placement in pages[pageIndex].placements) {
        packedPlacements.add(
          TiledImageCollectionPackedPlacement(
            source: placement.image.source,
            pageId: id,
            sourceRect: ProjectTilesetPixelRect(
              x: placement.x,
              y: placement.y,
              width: placement.image.width,
              height: placement.image.height,
            ),
          ),
        );
      }
    }
    packedPlacements.sort(
      (left, right) => left.source.compareTo(right.source),
    );
    return TiledImageCollectionPackingResult(
      pages: packedPages,
      placements: packedPlacements,
    );
  }

  _PreparedImage _decode(TiledImageCollectionPackingInput input) {
    final metadata = _inspect(
      input.bytes,
      source: input.source,
      encoding: false,
    );
    if (metadata.pixelWidth != input.declaredPixelWidth ||
        metadata.pixelHeight != input.declaredPixelHeight) {
      throw TiledImageCollectionPackingException(
        'tileset.tiled.image_dimensions_mismatch',
        'The inspected collection image dimensions differ from the TSX.',
        source: input.source,
      );
    }
    late final TiledImageCollectionRgbaImage decoded;
    try {
      decoded = codec.decode(input.bytes);
    } on TiledImageCollectionPackingException {
      rethrow;
    } on ArgumentError {
      throw _decodeFailure(input.source);
    } on Exception {
      throw _decodeFailure(input.source);
    }
    if (decoded.pixelWidth != input.declaredPixelWidth ||
        decoded.pixelHeight != input.declaredPixelHeight) {
      throw TiledImageCollectionPackingException(
        'tileset.tiled.image_dimensions_mismatch',
        'The decoded collection image dimensions differ from the TSX.',
        source: input.source,
      );
    }
    return _PreparedImage(
      source: input.source,
      image: _applyTransparentColor(decoded, input.transparentColor),
    );
  }

  List<int> _encodePage(TiledImageCollectionRgbaImage page) {
    late final List<int> encoded;
    try {
      encoded = codec.encodePng(page);
    } on TiledImageCollectionPackingException {
      rethrow;
    } on ArgumentError {
      throw _encodeFailure();
    } on Exception {
      throw _encodeFailure();
    }
    if (encoded.isEmpty || encoded.any((byte) => byte < 0 || byte > 255)) {
      throw _encodeFailure();
    }
    final metadata = _inspect(encoded, encoding: true);
    if (metadata.pixelWidth != page.pixelWidth ||
        metadata.pixelHeight != page.pixelHeight) {
      throw _encodeFailure();
    }
    return List<int>.unmodifiable(encoded);
  }

  TiledImageCollectionRasterMetadata _inspect(
    List<int> bytes, {
    String? source,
    required bool encoding,
  }) {
    try {
      final metadata = codec.inspect(bytes);
      if (metadata.pixelWidth <= 0 || metadata.pixelHeight <= 0) {
        throw const FormatException('invalid raster dimensions');
      }
      return metadata;
    } on TiledImageCollectionPackingException {
      rethrow;
    } on ArgumentError {
      throw encoding ? _encodeFailure() : _decodeFailure(source!);
    } on Exception {
      throw encoding ? _encodeFailure() : _decodeFailure(source!);
    }
  }
}

TiledImageCollectionRgbaImage _applyTransparentColor(
  TiledImageCollectionRgbaImage image,
  TilesetTransparentColor? transparentColor,
) {
  if (transparentColor == null) return image;
  final rgbaBytes = List<int>.of(image.rgbaBytes);
  for (var index = 0; index < rgbaBytes.length; index += 4) {
    if (transparentColor.matchesRgb(
      red: rgbaBytes[index],
      green: rgbaBytes[index + 1],
      blue: rgbaBytes[index + 2],
    )) {
      rgbaBytes[index + 3] = 0;
    }
  }
  return TiledImageCollectionRgbaImage(
    pixelWidth: image.pixelWidth,
    pixelHeight: image.pixelHeight,
    rgbaBytes: rgbaBytes,
  );
}

void _validateInput(
  TiledImageCollectionPackingInput input,
  Set<String> seenSources,
) {
  if (input.source.isEmpty ||
      input.source != input.source.trim() ||
      input.source.contains('\\')) {
    throw TiledImageCollectionPackingException(
      'tileset.tiled.image_reference_invalid',
      'Every collection image must use a normalized nonblank source.',
      source: input.source,
    );
  }
  if (!seenSources.add(input.source)) {
    throw TiledImageCollectionPackingException(
      'tileset.tiled.image_dependency_duplicate',
      'A collection image dependency is staged more than once.',
      source: input.source,
    );
  }
  if (input.declaredPixelWidth <= 0 || input.declaredPixelHeight <= 0) {
    throw TiledImageCollectionPackingException(
      'tileset.tiled.image_dimensions_invalid',
      'Every collection image must declare positive pixel dimensions.',
      source: input.source,
    );
  }
  if (input.bytes.isEmpty ||
      input.bytes.any((byte) => byte < 0 || byte > 255)) {
    throw _decodeFailure(input.source);
  }
}

TiledImageCollectionPackingException _decodeFailure(String source) =>
    TiledImageCollectionPackingException(
      'tileset.tiled.image_decode_invalid',
      'The staged collection image cannot be decoded as RGBA pixels.',
      source: source,
    );

TiledImageCollectionPackingException _encodeFailure() =>
    const TiledImageCollectionPackingException(
      'tileset.tiled.image_encode_invalid',
      'A generated collection page cannot be encoded as PNG.',
    );

List<int> _validRgbaBytes(
  Iterable<int> bytes, {
  required int pixelWidth,
  required int pixelHeight,
}) {
  if (pixelWidth <= 0 || pixelHeight <= 0) {
    throw ArgumentError('RGBA image dimensions must be positive.');
  }
  final values = bytes.toList(growable: false);
  final expectedLength = pixelWidth * pixelHeight * 4;
  if (values.length != expectedLength ||
      values.any((byte) => byte < 0 || byte > 255)) {
    throw ArgumentError('RGBA image bytes must match its pixel dimensions.');
  }
  return values;
}

int _comparePreparedImages(_PreparedImage left, _PreparedImage right) {
  final byHeight = right.height.compareTo(left.height);
  if (byHeight != 0) return byHeight;
  final byWidth = right.width.compareTo(left.width);
  if (byWidth != 0) return byWidth;
  return left.source.compareTo(right.source);
}

String _pageId(int index) => 'page-${index.toString().padLeft(4, '0')}';

final class _PreparedImage {
  const _PreparedImage({required this.source, required this.image});

  final String source;
  final TiledImageCollectionRgbaImage image;

  int get width => image.pixelWidth;
  int get height => image.pixelHeight;
}

final class _PackingPage {
  final List<_Shelf> _shelves = <_Shelf>[];
  final List<_RawPlacement> placements = <_RawPlacement>[];
  int usedWidth = 0;
  int usedHeight = 0;

  _RawPlacement? tryPlace(
    _PreparedImage image, {
    required int allocatedWidth,
    required int allocatedHeight,
    required int maximumWidth,
    required int maximumHeight,
    required int padding,
  }) {
    _Shelf? bestShelf;
    for (final shelf in _shelves) {
      if (allocatedHeight > shelf.height ||
          shelf.nextX + allocatedWidth > maximumWidth) {
        continue;
      }
      if (bestShelf == null ||
          _compareShelfFit(
                shelf,
                bestShelf,
                allocatedWidth: allocatedWidth,
                allocatedHeight: allocatedHeight,
                maximumWidth: maximumWidth,
              ) <
              0) {
        bestShelf = shelf;
      }
    }

    if (bestShelf == null) {
      if (usedHeight + allocatedHeight > maximumHeight) return null;
      bestShelf = _Shelf(y: usedHeight, height: allocatedHeight);
      _shelves.add(bestShelf);
      usedHeight += allocatedHeight;
    }

    final placement = _RawPlacement(
      image: image,
      x: bestShelf.nextX + padding,
      y: bestShelf.y + padding,
    );
    bestShelf.nextX += allocatedWidth;
    usedWidth = math.max(usedWidth, bestShelf.nextX);
    placements.add(placement);
    return placement;
  }

  TiledImageCollectionRgbaImage render() {
    final pageBytes = Uint8List(usedWidth * usedHeight * 4);
    for (final placement in placements) {
      final source = placement.image.image;
      for (var y = 0; y < source.pixelHeight; y += 1) {
        final sourceStart = y * source.pixelWidth * 4;
        final targetStart = ((placement.y + y) * usedWidth + placement.x) * 4;
        pageBytes.setRange(
          targetStart,
          targetStart + source.pixelWidth * 4,
          source.rgbaBytes,
          sourceStart,
        );
      }
    }
    return TiledImageCollectionRgbaImage(
      pixelWidth: usedWidth,
      pixelHeight: usedHeight,
      rgbaBytes: pageBytes,
    );
  }
}

int _compareShelfFit(
  _Shelf left,
  _Shelf right, {
  required int allocatedWidth,
  required int allocatedHeight,
  required int maximumWidth,
}) {
  final leftVerticalWaste = left.height - allocatedHeight;
  final rightVerticalWaste = right.height - allocatedHeight;
  final byVerticalWaste = leftVerticalWaste.compareTo(rightVerticalWaste);
  if (byVerticalWaste != 0) return byVerticalWaste;
  final leftHorizontalWaste = maximumWidth - left.nextX - allocatedWidth;
  final rightHorizontalWaste = maximumWidth - right.nextX - allocatedWidth;
  final byHorizontalWaste = leftHorizontalWaste.compareTo(rightHorizontalWaste);
  if (byHorizontalWaste != 0) return byHorizontalWaste;
  return left.y.compareTo(right.y);
}

final class _Shelf {
  _Shelf({required this.y, required this.height});

  final int y;
  final int height;
  int nextX = 0;
}

final class _RawPlacement {
  const _RawPlacement({
    required this.image,
    required this.x,
    required this.y,
  });

  final _PreparedImage image;
  final int x;
  final int y;
}
