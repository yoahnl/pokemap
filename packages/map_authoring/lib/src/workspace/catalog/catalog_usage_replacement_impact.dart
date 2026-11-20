import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../transactions/authoring_plan.dart';

final class CatalogUsageReplacementImpact {
  CatalogUsageReplacementImpact(
      {required AuthoringPlan plan,
      required Iterable<MapData> beforeMaps,
      required Iterable<MapData> afterMaps})
      : _sourceId = plan.request.parameters['resourceId'] as String,
        _targetId = plan.request.parameters['replacementId'] as String {
    final affectedBorders =
        (plan.preview['repointedBorderIds'] as List?)?.toSet() ?? const {};
    final before = {for (final map in beforeMaps) map.id: map};
    var regenerated = 0;
    var redirected = 0;
    final maps = <Map<String, Object?>>[];
    for (final map in afterMaps) {
      final original = before[map.id]!;
      final targetPlacements = {
        for (final instance
            in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
          if (instance.modelId == _targetId) instance.id,
      };
      final ids = [
        for (final instance in original.spatialScene?.instances ??
            const <SpatialModelInstance>[])
          if (instance.modelId == _sourceId &&
              targetPlacements.contains(instance.id))
            instance.id,
      ];
      _redirected[map.id] = ids;
      final materializations = {
        for (final layer in original.layers.whereType<BorderLayer>())
          for (final feature in layer.content.features)
            if (affectedBorders.contains(feature.blueprintId))
              (layer.id, feature.id): feature,
      };
      final recalculated = {
        for (final layer in map.layers.whereType<BorderLayer>())
          for (final feature in layer.content.features)
            if (materializations[(layer.id, feature.id)] case final previous?
                when previous.materialization != feature.materialization)
              ...feature.generatedPlacementIds,
      }.length;
      regenerated += recalculated;
      redirected += ids.length;
      maps.add({
        'mapId': map.id,
        'mapName': map.name,
        'instanceIds': ids,
        'regeneratedInstanceCount': recalculated,
      });
    }
    final counts = {
      'occurrenceCount': redirected,
      'regeneratedInstanceCount': regenerated,
    };
    preview = {...plan.preview, ...counts, 'noOp': false, 'maps': maps};
    referenceImpact = {...plan.referenceImpact, ...counts};
  }

  late final Map<String, Object?> preview;
  late final Map<String, Object?> referenceImpact;
  final String _sourceId;
  final String _targetId;
  final _redirected = <String, List<String>>{};

  AuthoringDiffEntry mapDiff(AuthoringDiffEntry entry) {
    final ids = _redirected[entry.resource.id];
    if (entry.resource.kind != 'map' || ids == null) return entry;
    return AuthoringDiffEntry.fromJson({
      ...entry.toJson(),
      'before': {for (final id in ids) id: _sourceId},
      'after': {for (final id in ids) id: _targetId},
    });
  }
}
