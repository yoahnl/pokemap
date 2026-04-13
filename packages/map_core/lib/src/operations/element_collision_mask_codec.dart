import 'dart:convert';
import 'dart:math' as math;

import '../models/element_collision_profile.dart';
import '../models/geometry.dart';

/// Décode/encode les masques collision pixel-level vers un format compact.
///
/// Convention `packed_bits_v1`:
/// - ordre row-major (ligne par ligne);
/// - bit à 1 => pixel solide gameplay;
/// - bit index 0 = pixel (0,0), index 1 = (1,0), etc.
class ElementCollisionMaskCodec {
  const ElementCollisionMaskCodec._();

  /// Encode un buffer booléen pixel (`width * height`) en base64.
  static String encodePackedBits({
    required int widthPx,
    required int heightPx,
    required List<bool> solidPixels,
  }) {
    final total = widthPx * heightPx;
    if (total <= 0 || solidPixels.length != total) {
      throw ArgumentError(
        'Invalid solidPixels length: expected $total, got ${solidPixels.length}',
      );
    }
    final bytes = List<int>.filled((total + 7) >> 3, 0);
    for (var i = 0; i < total; i++) {
      if (!solidPixels[i]) {
        continue;
      }
      final byteIndex = i >> 3;
      final bitIndex = i & 7;
      bytes[byteIndex] |= 1 << bitIndex;
    }
    return base64Encode(bytes);
  }

  /// Décode le base64 en buffer booléen pixel (`width * height`).
  static List<bool> decodePackedBits({
    required int widthPx,
    required int heightPx,
    required String dataBase64,
  }) {
    final total = widthPx * heightPx;
    if (total <= 0) {
      return const <bool>[];
    }
    final raw = dataBase64.trim();
    if (raw.isEmpty) {
      return List<bool>.filled(total, false);
    }
    final bytes = base64Decode(raw);
    final minBytes = (total + 7) >> 3;
    if (bytes.length < minBytes) {
      throw FormatException(
        'Packed mask payload too short: expected >= $minBytes bytes, got ${bytes.length}',
      );
    }
    final out = List<bool>.filled(total, false);
    for (var i = 0; i < total; i++) {
      final byteIndex = i >> 3;
      final bitIndex = i & 7;
      out[i] = (bytes[byteIndex] & (1 << bitIndex)) != 0;
    }
    return out;
  }

  /// Dérive des cellules legacy à partir d'un masque pixel.
  ///
  /// Une cellule est marquée solide si le ratio pixels solides / pixels de la
  /// cellule est >= [minimumSolidRatioPerCell].
  static List<GridPos> cellsFromPixelMask({
    required ElementCollisionPixelMask mask,
    required int tileWidth,
    required int tileHeight,
    required int sourceWidthInTiles,
    required int sourceHeightInTiles,
    double minimumSolidRatioPerCell = 0.01,
  }) {
    final total = mask.widthPx * mask.heightPx;
    if (total <= 0 ||
        tileWidth <= 0 ||
        tileHeight <= 0 ||
        sourceWidthInTiles <= 0 ||
        sourceHeightInTiles <= 0) {
      return const <GridPos>[];
    }
    final bits = decodePackedBits(
      widthPx: mask.widthPx,
      heightPx: mask.heightPx,
      dataBase64: mask.dataBase64,
    );
    final out = <GridPos>[];
    final minRatio = minimumSolidRatioPerCell.clamp(0.0, 1.0);

    for (var cy = 0; cy < sourceHeightInTiles; cy++) {
      for (var cx = 0; cx < sourceWidthInTiles; cx++) {
        final startX = cx * tileWidth;
        final startY = cy * tileHeight;
        var solid = 0;
        var sampled = 0;
        for (var py = 0; py < tileHeight; py++) {
          final y = startY + py;
          if (y < 0 || y >= mask.heightPx) {
            continue;
          }
          for (var px = 0; px < tileWidth; px++) {
            final x = startX + px;
            if (x < 0 || x >= mask.widthPx) {
              continue;
            }
            sampled++;
            final idx = y * mask.widthPx + x;
            if (idx >= 0 && idx < bits.length && bits[idx]) {
              solid++;
            }
          }
        }
        if (sampled <= 0) {
          continue;
        }
        final ratio = solid / sampled;
        if (ratio >= minRatio && solid > 0) {
          out.add(GridPos(x: cx, y: cy));
        }
      }
    }

    out.sort((a, b) {
      final c = a.y.compareTo(b.y);
      if (c != 0) {
        return c;
      }
      return a.x.compareTo(b.x);
    });
    return out;
  }

  /// Crée un masque vide de dimensions données.
  static ElementCollisionPixelMask emptyMask({
    required int widthPx,
    required int heightPx,
  }) {
    final total = math.max(0, widthPx * heightPx);
    return ElementCollisionPixelMask(
      widthPx: math.max(0, widthPx),
      heightPx: math.max(0, heightPx),
      dataBase64: encodePackedBits(
        widthPx: math.max(0, widthPx),
        heightPx: math.max(0, heightPx),
        solidPixels: List<bool>.filled(total, false),
      ),
    );
  }
}
