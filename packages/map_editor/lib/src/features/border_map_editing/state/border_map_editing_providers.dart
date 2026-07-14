import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../application/active_border_feature_controller.dart';

/// Small overridable seam used to keep the Border selection project-UI state
/// separate from serialized [MapData].
final activeBorderFeatureSourceProvider =
    Provider<({MapData? map, String? activeLayerId})>((ref) {
  return ref.watch(
    editorNotifierProvider.select(
      (state) => (
        map: state.activeMap,
        activeLayerId: state.activeLayerId,
      ),
    ),
  );
});

final activeBorderFeatureControllerProvider = StateNotifierProvider<
    ActiveBorderFeatureController, ActiveBorderFeatureState>((ref) {
  final controller = ActiveBorderFeatureController();
  ref.listen(
    activeBorderFeatureSourceProvider,
    (_, source) => controller.reconcile(
      map: source.map,
      activeLayerId: source.activeLayerId,
    ),
    fireImmediately: true,
  );
  return controller;
});
