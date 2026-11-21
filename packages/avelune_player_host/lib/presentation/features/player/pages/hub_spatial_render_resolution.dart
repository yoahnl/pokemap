import 'package:flutter/foundation.dart';

double hubSpatialRenderResolutionScale({
  required TargetPlatform platform,
  required double devicePixelRatio,
}) {
  final handheld =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  return handheld && devicePixelRatio >= 2 ? .5 : 1;
}
