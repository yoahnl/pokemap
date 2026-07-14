import 'package:map_core/map_core.dart';

import 'border_preview_transaction.dart';

/// Applies one already-resolved preview through the canonical optimistic core
/// operation. This is the sole persisted mutation used by World Maps Apply.
MapData applyBorderMaterialization({
  required MapData map,
  required BorderPreviewTransaction transaction,
}) {
  final request = transaction.request;
  final result = transaction.result;
  if (request == null || result == null || !result.canApply) {
    return map;
  }
  return applyBorderFeaturePreview(
    map,
    expectedMapId: transaction.mapId,
    layerId: transaction.layerId,
    featureId: transaction.featureId,
    expectedBaseFeatureFingerprint: transaction.baseFeatureFingerprint,
    proposedRequest: request,
    proposedResult: result,
  );
}
