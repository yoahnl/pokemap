import 'package:map_distribution/map_distribution.dart';

import 'battle_sfx_player.dart';

extension VerifiedBattleRecipeSoundLoader on FlameAudioBattleSfxPlayer {
  Future<BattlePreparedRecipeSound> prepareVerifiedRecipeSound(
    InspectedBattleRecipeBundle bundle,
    String resourceId,
  ) async => beginVerifiedRecipeSound(bundle, resourceId).ready;

  BattleRecipeSoundPreparation beginVerifiedRecipeSound(
    InspectedBattleRecipeBundle bundle,
    String resourceId,
  ) {
    final resource = bundle.recipe.resources
        .where((entry) => entry.id == resourceId && entry.role == 'sound')
        .firstOrNull;
    final bytes = bundle.media[resourceId];
    if (resource == null || bytes == null) {
      throw const FormatException('Unknown verified recipe sound');
    }
    return beginRecipeSound(bytes, resource.mediaType);
  }
}
