import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Dimensions natives décodées depuis les octets image (package `image`, synchrone).
({int? width, int? height}) decodeRasterImageSizeFromBytes(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) {
    return (width: null, height: null);
  }
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return (width: null, height: null);
    }
    return (width: decoded.width, height: decoded.height);
  } catch (_) {
    return (width: null, height: null);
  }
}

/// Entrées brouillon strictement positives pour dessiner l’overlay.
bool surfaceStudioAtlasGridOverlayDraftValid(
  int? tileWidth,
  int? tileHeight,
  int? columns,
  int? rows,
) {
  if (tileWidth == null ||
      tileHeight == null ||
      columns == null ||
      rows == null) {
    return false;
  }
  return tileWidth > 0 &&
      tileHeight > 0 &&
      columns > 0 &&
      rows > 0;
}

int surfaceStudioAtlasGridExpectedWidthPx(int tileWidth, int columns) =>
    tileWidth * columns;

int surfaceStudioAtlasGridExpectedHeightPx(int tileHeight, int rows) =>
    tileHeight * rows;

/// Grille visuellement dense : sous-échantillonnage des traits pour rester léger.
bool surfaceStudioAtlasGridOverlayIsDense(int columns, int rows) {
  if (columns > 48 || rows > 48) {
    return true;
  }
  if (columns * rows > 2400) {
    return true;
  }
  return false;
}

/// Pas plus d’environ ~64 intervalles par axe pour les traits intérieurs.
int surfaceStudioAtlasGridOverlayLineStep(int count) {
  if (count <= 48) {
    return 1;
  }
  final s = (count / 48).ceil();
  return s < 1 ? 1 : s;
}

/// Peintre : lignes uniquement (pas de widgets par cellule) — Lot 73.
class SurfaceStudioAtlasImageGridPainter extends CustomPainter {
  const SurfaceStudioAtlasImageGridPainter({
    required this.columns,
    required this.rows,
    required this.lineColor,
    this.stepX = 1,
    this.stepY = 1,
  });

  final int columns;
  final int rows;
  final Color lineColor;
  final int stepX;
  final int stepY;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= columns; i++) {
      final boundary = i == 0 || i == columns;
      if (!boundary && stepX > 1 && (i % stepX) != 0) {
        continue;
      }
      final x = i * size.width / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 0; j <= rows; j++) {
      final boundary = j == 0 || j == rows;
      if (!boundary && stepY > 1 && (j % stepY) != 0) {
        continue;
      }
      final y = j * size.height / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasImageGridPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.stepX != stepX ||
        oldDelegate.stepY != stepY;
  }
}
