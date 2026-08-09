import 'package:map_core/map_core.dart';

List<SmartTileRenderChannel> smartTileRenderChannelsForUsage(
  SmartTileUsage usage,
) => switch (usage) {
  SmartTileUsage.terrain => const <SmartTileRenderChannel>[
    SmartTileRenderChannel.ground,
  ],
  SmartTileUsage.path => const <SmartTileRenderChannel>[
    SmartTileRenderChannel.ground,
    SmartTileRenderChannel.actorOcclusion,
  ],
  SmartTileUsage.forestSurface => SmartTileRenderChannel.values,
};
