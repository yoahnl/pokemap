import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';

BorderPixelPos recommendedBorderPrimitiveAnchor({
  required BorderBlueprintTemplate template,
  required BorderPrimitiveAssetMetrics metrics,
}) {
  if (template != BorderBlueprintTemplate.connectedLine) {
    return metrics.defaultAnchorPx;
  }

  return BorderPixelPos(
    x: metrics.pixelSize.width ~/ 2,
    y: metrics.pixelSize.height ~/ 2,
  );
}
