import '../models/element_collision_profile.dart';
import '../models/geometry.dart';
import '../operations/element_collision_mask_codec.dart';

/// Outils **hors runtime gameplay** : migration one-shot `cells` → [ElementCollisionPixelMask].
///
/// Le moteur de collision actif **ne lit pas** [ElementCollisionProfile.cells].
/// Les projets qui n’ont que des cellules doivent appeler ces helpers (éditeur,
/// script de migration) pour produire un [pixelMask] valide avant chargement strict.
class ElementCollisionLegacyMigration {
  ElementCollisionLegacyMigration._();

  /// Remplit chaque cellule listée comme **tuile pleine** en pixels (legacy).
  ///
  /// [cells] : coordonnées **locales** dans le repère source (tuiles élément).
  static ElementCollisionPixelMask pixelMaskFromLegacyCellsFullTileRectangles({
    required List<GridPos> cells,
    required int sourceWidthInTiles,
    required int sourceHeightInTiles,
    required int tileWidthPx,
    required int tileHeightPx,
  }) {
    final widthPx = sourceWidthInTiles * tileWidthPx;
    final heightPx = sourceHeightInTiles * tileHeightPx;
    final solid = List<bool>.filled(widthPx * heightPx, false);
    for (final c in cells) {
      if (c.x < 0 ||
          c.y < 0 ||
          c.x >= sourceWidthInTiles ||
          c.y >= sourceHeightInTiles) {
        continue;
      }
      final baseX = c.x * tileWidthPx;
      final baseY = c.y * tileHeightPx;
      for (var py = 0; py < tileHeightPx; py++) {
        for (var px = 0; px < tileWidthPx; px++) {
          final x = baseX + px;
          final y = baseY + py;
          solid[y * widthPx + x] = true;
        }
      }
    }
    return ElementCollisionPixelMask(
      widthPx: widthPx,
      heightPx: heightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: widthPx,
        heightPx: heightPx,
        solidPixels: solid,
      ),
    );
  }
}
