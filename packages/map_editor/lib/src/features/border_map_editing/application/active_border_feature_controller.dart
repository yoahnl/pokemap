import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

/// Ephemeral World Maps selection for the dedicated Border layer.
///
/// It is intentionally absent from [MapData] and therefore never serialized.
@immutable
final class ActiveBorderFeatureState {
  const ActiveBorderFeatureState({
    required this.activeLayerId,
    required this.activeFeatureId,
  });

  const ActiveBorderFeatureState.empty()
      : activeLayerId = null,
        activeFeatureId = null;

  final String? activeLayerId;
  final String? activeFeatureId;

  bool get hasActiveFeature => activeLayerId != null && activeFeatureId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveBorderFeatureState &&
          activeLayerId == other.activeLayerId &&
          activeFeatureId == other.activeFeatureId;

  @override
  int get hashCode => Object.hash(activeLayerId, activeFeatureId);
}

final class ActiveBorderFeatureController
    extends StateNotifier<ActiveBorderFeatureState> {
  ActiveBorderFeatureController()
      : super(const ActiveBorderFeatureState.empty());

  /// Reconciles selection after layer/feature selection, deletion or reorder.
  /// Later authored features are visually uppermost and become the fallback.
  void reconcile({required MapData? map, required String? activeLayerId}) {
    state = resolveActiveBorderFeatureSelection(
      current: state,
      map: map,
      activeLayerId: activeLayerId,
    );
  }

  void selectFeature({
    required MapData map,
    required String layerId,
    required String featureId,
  }) {
    final layer = _findBorderLayer(map, layerId);
    if (layer == null || layer.content.featureById(featureId) == null) {
      throw ArgumentError.value(
        featureId,
        'featureId',
        'must belong to the requested active Border layer',
      );
    }
    state = ActiveBorderFeatureState(
      activeLayerId: layer.id,
      activeFeatureId: featureId,
    );
  }

  void clear() {
    state = const ActiveBorderFeatureState.empty();
  }
}

/// Purely resolves the canonical Border feature without publishing selection.
ActiveBorderFeatureState resolveActiveBorderFeatureSelection({
  required ActiveBorderFeatureState current,
  required MapData? map,
  required String? activeLayerId,
}) {
  final layer = _findBorderLayer(map, activeLayerId);
  if (layer == null) {
    return const ActiveBorderFeatureState.empty();
  }
  final currentFeatureId =
      current.activeLayerId == layer.id ? current.activeFeatureId : null;
  final currentStillExists = currentFeatureId != null &&
      layer.content.featureById(currentFeatureId) != null;
  final nextFeatureId = currentStillExists
      ? currentFeatureId
      : layer.content.features.isEmpty
          ? null
          : layer.content.features.last.id;
  return ActiveBorderFeatureState(
    activeLayerId: layer.id,
    activeFeatureId: nextFeatureId,
  );
}

BorderLayer? _findBorderLayer(MapData? map, String? layerId) {
  if (map == null || layerId == null) return null;
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer is BorderLayer ? layer : null;
    }
  }
  return null;
}
