import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximum decoded or allocated atlas canvas size accepted by this service.
const tilesetAtlasPixelBudget = 64 * 1024 * 1024;

final class TilesetAtlasItem {
  const TilesetAtlasItem({
    required this.id,
    required this.bytes,
    required this.xCells,
    required this.yCells,
    required this.widthCells,
    required this.heightCells,
  });

  final String id;
  final Uint8List bytes;
  final int xCells;
  final int yCells;
  final int widthCells;
  final int heightCells;
}

Uint8List buildTilesetAtlas({
  required int widthCells,
  required int heightCells,
  required int tileWidth,
  required int tileHeight,
  required List<TilesetAtlasItem> items,
}) {
  if (widthCells <= 0 ||
      heightCells <= 0 ||
      tileWidth <= 0 ||
      tileHeight <= 0) {
    throw ArgumentError('Atlas and tile dimensions must be positive.');
  }
  final atlasWidth = _checkedProduct(
    widthCells,
    tileWidth,
    label: 'Atlas pixel width',
  );
  final atlasHeight = _checkedProduct(
    heightCells,
    tileHeight,
    label: 'Atlas pixel height',
  );
  _ensurePixelBudget(atlasWidth, atlasHeight, label: 'Atlas canvas');

  final ids = <String>{};
  final validatedItems = <TilesetAtlasItem>[];
  for (final item in items) {
    if (item.id.isEmpty) {
      throw ArgumentError('Atlas item IDs must not be empty.');
    }
    if (!ids.add(item.id)) {
      throw ArgumentError('Duplicate atlas item ID: ${item.id}.');
    }
    if (item.xCells < 0 || item.yCells < 0) {
      throw ArgumentError('Atlas item ${item.id} has negative coordinates.');
    }
    if (item.widthCells <= 0 || item.heightCells <= 0) {
      throw ArgumentError(
          'Atlas item ${item.id} has a non-positive footprint.');
    }
    if (item.xCells + item.widthCells > widthCells ||
        item.yCells + item.heightCells > heightCells) {
      throw ArgumentError('Atlas item ${item.id} is out of bounds.');
    }
    for (final other in validatedItems) {
      if (_overlaps(item, other)) {
        throw ArgumentError(
          'Atlas items ${other.id} and ${item.id} overlap.',
        );
      }
    }
    validatedItems.add(item);
  }

  final orderedItems = validatedItems.toList()
    ..sort((left, right) {
      final byY = left.yCells.compareTo(right.yCells);
      if (byY != 0) {
        return byY;
      }
      final byX = left.xCells.compareTo(right.xCells);
      if (byX != 0) {
        return byX;
      }
      return left.id.compareTo(right.id);
    });

  final preparedItems = <_PreparedAtlasItem>[
    for (final item in orderedItems)
      _preflightItem(
        item,
        expectedWidth: _checkedProduct(
          item.widthCells,
          tileWidth,
          label: 'Atlas item ${item.id} pixel width',
        ),
        expectedHeight: _checkedProduct(
          item.heightCells,
          tileHeight,
          label: 'Atlas item ${item.id} pixel height',
        ),
      ),
  ];

  final atlas = img.Image(
    width: atlasWidth,
    height: atlasHeight,
    numChannels: 4,
  );
  for (final prepared in preparedItems) {
    final item = prepared.item;
    final decoded = _decodePreparedItem(prepared);
    final source = decoded.convert(
      format: img.Format.uint8,
      numChannels: 4,
      alpha: decoded.hasAlpha ? null : 255,
    );
    final offsetX = item.xCells * tileWidth;
    final offsetY = item.yCells * tileHeight;
    for (var y = 0; y < source.height; y += 1) {
      for (var x = 0; x < source.width; x += 1) {
        final pixel = source.getPixel(x, y);
        atlas.setPixelRgba(
          offsetX + x,
          offsetY + y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          pixel.a.toInt(),
        );
      }
    }
  }

  return Uint8List.fromList(img.encodePng(atlas));
}

_PreparedAtlasItem _preflightItem(
  TilesetAtlasItem item, {
  required int expectedWidth,
  required int expectedHeight,
}) {
  final img.Decoder? decoder;
  final img.DecodeInfo? info;
  try {
    decoder = img.findDecoderForData(item.bytes);
    info = decoder?.startDecode(item.bytes);
  } on RangeError {
    throw FormatException('Atlas item ${item.id} has invalid image bytes.');
  } on Exception {
    throw FormatException('Atlas item ${item.id} has invalid image bytes.');
  }
  if (decoder == null || info == null) {
    throw FormatException('Atlas item ${item.id} has invalid image bytes.');
  }
  if (info.width != expectedWidth || info.height != expectedHeight) {
    throw ArgumentError(
      'Atlas item ${item.id} is ${info.width}x${info.height}; '
      'its footprint requires ${expectedWidth}x$expectedHeight pixels.',
    );
  }
  _ensurePixelBudget(
    info.width,
    info.height,
    label: 'Atlas item ${item.id}',
  );
  return _PreparedAtlasItem(
    item: item,
    decoder: decoder,
    expectedWidth: expectedWidth,
    expectedHeight: expectedHeight,
  );
}

img.Image _decodePreparedItem(_PreparedAtlasItem prepared) {
  final img.Image? decoded;
  try {
    decoded = prepared.decoder.decode(prepared.item.bytes, frame: 0);
  } on RangeError {
    throw FormatException(
      'Atlas item ${prepared.item.id} has invalid image bytes.',
    );
  } on Exception {
    throw FormatException(
      'Atlas item ${prepared.item.id} has invalid image bytes.',
    );
  }
  if (decoded == null) {
    throw FormatException(
      'Atlas item ${prepared.item.id} has invalid image bytes.',
    );
  }
  if (decoded.width != prepared.expectedWidth ||
      decoded.height != prepared.expectedHeight) {
    throw ArgumentError(
      'Atlas item ${prepared.item.id} decoded to '
      '${decoded.width}x${decoded.height}; its footprint requires '
      '${prepared.expectedWidth}x${prepared.expectedHeight} pixels.',
    );
  }
  return decoded;
}

int _checkedProduct(int left, int right, {required String label}) {
  if (left <= 0 || right <= 0 || left > tilesetAtlasPixelBudget ~/ right) {
    throw ArgumentError(
      '$label exceeds the $tilesetAtlasPixelBudget pixel budget.',
    );
  }
  return left * right;
}

void _ensurePixelBudget(int width, int height, {required String label}) {
  if (width <= 0 || height <= 0 || width > tilesetAtlasPixelBudget ~/ height) {
    throw ArgumentError(
      '$label exceeds the $tilesetAtlasPixelBudget pixel budget.',
    );
  }
}

bool _overlaps(TilesetAtlasItem left, TilesetAtlasItem right) =>
    left.xCells < right.xCells + right.widthCells &&
    right.xCells < left.xCells + left.widthCells &&
    left.yCells < right.yCells + right.heightCells &&
    right.yCells < left.yCells + left.heightCells;

final class _PreparedAtlasItem {
  const _PreparedAtlasItem({
    required this.item,
    required this.decoder,
    required this.expectedWidth,
    required this.expectedHeight,
  });

  final TilesetAtlasItem item;
  final img.Decoder decoder;
  final int expectedWidth;
  final int expectedHeight;
}
