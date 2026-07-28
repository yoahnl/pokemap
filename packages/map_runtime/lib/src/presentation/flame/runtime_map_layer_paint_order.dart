import 'package:map_core/map_core.dart';

/// Resolves the runtime paint order from the canonical `map_core` contract.
///
/// Runtime deliberately owns no ordering fallback. In particular, an unknown
/// future visual-stack version must fail explicitly instead of being rendered
/// with legacy semantics.
MapVisualCompositionPlan buildRuntimeMapLayerPaintOrder(MapData map) {
  final result = buildMapVisualCompositionPlan(map);
  final plan = result.plan;
  if (plan != null) {
    return plan;
  }
  final details =
      result.diagnostics.map((diagnostic) => diagnostic.message).join(' ');
  throw MapLoadException(
    'Map ${map.id} cannot be composed by this runtime. $details',
  );
}
