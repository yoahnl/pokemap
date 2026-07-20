import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'border_runtime_asset_collection.dart';

/// Filesystem-backed proof required before a map can enter the runtime.
@immutable
final class BorderRuntimePreparation {
  BorderRuntimePreparation({
    required this.assetCollection,
    required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
    required List<BorderMaterializationFreshness> featureFreshness,
  })  : snapshotIntegrity =
            Map<String, BorderVisualSnapshotIntegrity>.unmodifiable(
          snapshotIntegrity,
        ),
        featureFreshness = List<BorderMaterializationFreshness>.unmodifiable(
          featureFreshness,
        );

  final BorderRuntimeAssetCollection assetCollection;
  final Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity;
  final List<BorderMaterializationFreshness> featureFreshness;
}
