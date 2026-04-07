import 'dart:math' as math;

import 'element_visual_occupancy_analyzer.dart';
import 'placed_element_collision_params.dart';

/// Résultat d'analyse gameplay pixel-level.
///
/// `solidPixels` a la même taille que l'occupation visuelle source
/// (`widthPx * heightPx`) et représente le masque collision gameplay.
class ElementGroundBlockingMask {
  const ElementGroundBlockingMask({
    required this.widthPx,
    required this.heightPx,
    required this.solidPixels,
  });

  final int widthPx;
  final int heightPx;
  final List<bool> solidPixels;
}

/// Convertit une occupation visuelle pixel-level en masque collision gameplay.
///
/// Principe:
/// - la collision doit rester ancrée sur la base "solide" du sprite;
/// - la matière haute (toit, feuillage) ne suffit pas à bloquer;
/// - on applique un filtre vertical explicite:
///   1) bande basse du sprite (`spriteGameplayBandBottomFraction`);
///   2) bas de chaque cellule (`cellGroundFootprintFraction`).
class ElementGroundBlockingMaskAnalyzer {
  const ElementGroundBlockingMaskAnalyzer();

  ElementGroundBlockingMask analyze({
    required ElementVisualOccupancyMask occupancy,
    required int tileWidth,
    required int tileHeight,
    required int cellCountX,
    required int cellCountY,
    required PlacedElementCollisionGenerationParams params,
  }) {
    final widthPx = occupancy.widthPx;
    final heightPx = occupancy.heightPx;
    final solid = List<bool>.filled(widthPx * heightPx, false);
    if (widthPx <= 0 || heightPx <= 0 || tileWidth <= 0 || tileHeight <= 0) {
      return ElementGroundBlockingMask(
        widthPx: widthPx,
        heightPx: heightPx,
        solidPixels: solid,
      );
    }

    final bandFrac = params.spriteGameplayBandBottomFraction.clamp(1e-6, 1.0);
    final footFrac = params.cellGroundFootprintFraction.clamp(1e-6, 1.0);
    final minRatio = params.minimumOpaqueRatioInGroundSample.clamp(0.0, 1.0);
    final bandStartY = ((1.0 - bandFrac) * heightPx).ceil().clamp(0, heightPx);
    final footprintStartInCell =
        ((1.0 - footFrac) * tileHeight).ceil().clamp(0, tileHeight);

    // Étape 1: décider quelles cellules sont bloquantes selon la densité dans
    // l'échantillon "sol" (bande basse sprite + bas de cellule).
    final blockedCellKeys = <String>{};
    for (var cellY = 0; cellY < cellCountY; cellY++) {
      for (var cellX = 0; cellX < cellCountX; cellX++) {
        final startX = cellX * tileWidth;
        final startY = cellY * tileHeight;
        var sampled = 0;
        var visibleInSample = 0;

        for (var py = 0; py < tileHeight; py++) {
          if (py < footprintStartInCell) {
            continue;
          }
          final y = startY + py;
          if (y < 0 || y >= heightPx || y < bandStartY) {
            continue;
          }
          for (var px = 0; px < tileWidth; px++) {
            final x = startX + px;
            if (x < 0 || x >= widthPx) {
              continue;
            }
            sampled++;
            if (occupancy.visiblePixels[y * widthPx + x]) {
              visibleInSample++;
            }
          }
        }

        if (sampled <= 0) {
          continue;
        }
        final ratio = visibleInSample / sampled;
        final blocks = minRatio <= 0 ? visibleInSample > 0 : ratio >= minRatio;
        if (!blocks) {
          continue;
        }
        blockedCellKeys.add('$cellX:$cellY');
      }
    }

    // Étape 2: construire le masque pixel gameplay réel.
    //
    // IMPORTANT: contrairement à une projection "cellule pleine", on ne marque
    // solide qu'aux pixels visuellement occupés ET dans l'échantillon sol.
    for (var y = 0; y < heightPx; y++) {
      if (y < bandStartY) {
        continue;
      }
      final cellY = (y ~/ tileHeight).clamp(0, math.max(0, cellCountY - 1));
      final pyInCell = y % tileHeight;
      if (pyInCell < footprintStartInCell) {
        continue;
      }
      for (var x = 0; x < widthPx; x++) {
        final cellX = (x ~/ tileWidth).clamp(0, math.max(0, cellCountX - 1));
        if (!blockedCellKeys.contains('$cellX:$cellY')) {
          continue;
        }
        final idx = y * widthPx + x;
        if (idx < 0 || idx >= occupancy.visiblePixels.length) {
          continue;
        }
        if (!occupancy.visiblePixels[idx]) {
          continue;
        }
        solid[idx] = true;
      }
    }

    return ElementGroundBlockingMask(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: solid,
    );
  }
}
