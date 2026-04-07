import 'package:map_core/map_core.dart';

import '../collision_generation/alpha_collision_params.dart';
import '../collision_generation/placed_element_auto_collision_generator.dart';

/// Point d’entrée stable pour l’éditeur : génère un profil à partir de
/// l’**alpha** uniquement (voir [AlphaCollisionGenerationParams]).
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
    AlphaCollisionGenerationParams params = AlphaCollisionGenerationParams.defaults,
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
