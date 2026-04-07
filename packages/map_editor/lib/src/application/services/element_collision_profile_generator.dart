import 'package:map_core/map_core.dart';

import '../collision_generation/placed_element_auto_collision_generator.dart';
import '../collision_generation/placed_element_collision_params.dart';

/// Façade éditeur : génère un profil via [PlacedElementAutoCollisionGenerator].
///
/// Voir [PlacedElementCollisionGenerationParams] : copie alpha → masque pixel
/// (aucune heuristique grille dans le générateur).
class ElementCollisionProfileGenerator {
  const ElementCollisionProfileGenerator();

  static const PlacedElementAutoCollisionGenerator _delegate =
      PlacedElementAutoCollisionGenerator();

  Future<ElementCollisionProfile> generate({
    required String tilesetImagePath,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
    PlacedElementCollisionGenerationParams params =
        PlacedElementCollisionGenerationParams.defaults,
  }) {
    return _delegate.generate(
      tilesetImagePath: tilesetImagePath,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
      params: params,
    );
  }
}
