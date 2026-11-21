import 'package:map_core/map_core.dart';

CharacterAnimation authoredFishingClip(
  EntityFacing direction,
  String assetId,
) => CharacterAnimation.fromJson({
  'state': 'fishing',
  'direction': direction.name,
  'sourceAssetId': assetId,
  'loop': false,
  'frames': [
    for (final x in [8, 16])
      {
        'source': {'x': x, 'y': 0, 'width': 16, 'height': 32},
        'durationMs': 150,
      },
  ],
});
