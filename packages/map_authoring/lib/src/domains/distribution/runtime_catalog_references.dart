import 'package:map_core/map_core.dart';

import '../assets/asset_store.dart';
import 'runtime_smart_tile_rule_projection.dart';

final class RuntimeCatalogReferences {
  RuntimeCatalogReferences(ProjectManifest project, AssetCatalog assets)
      : _candidates = {
          for (final border in project.borderCatalog.records) border.id,
          if (project.settings.dimension == ProjectDimension.twoD)
            for (final preset in project.smartTileCatalog.presets)
              if (preset.rules.length >= minimumRuntimeSmartTileRuleCount)
                for (final rule in preset.rules) rule.id,
          if (project.settings.dimension == ProjectDimension.threeD &&
              project.models3d.isNotEmpty) ...{
            for (final preset in project.smartTileCatalog.presets) preset.id,
            for (final pattern in project.smartTileCatalog.patterns) pattern.id,
            for (final model in project.models3d) ...{
              model.id,
              if (assets.find(model.sourceAssetId) case final source?)
                ...modelAssetReferences(source),
            },
          },
        };

  final Set<String> _candidates;
  final Set<String> matches = {};

  void addDocument(Object? document) {
    if (_candidates.isNotEmpty) {
      matches.addAll(referencedRuntimeStrings(document, _candidates));
    }
  }
}

Set<String> modelAssetReferences(AssetRecord record) => {
      record.id,
      record.logicalPath,
      record.artifact.handle,
      record.artifact.digest,
      record.artifact.hexDigest,
      assetBlobStorageKey(record.artifact),
    };

Set<String> referencedRuntimeStrings(Object? value, Set<String> candidates) {
  final references = <String>{};
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final item = pending.removeLast();
    if (item is String && candidates.contains(item)) {
      references.add(item);
    } else if (item is Map) {
      pending.addAll(item.values);
    } else if (item is List) {
      pending.addAll(item);
    }
  }
  return references;
}
