import 'package:map_core/map_core.dart';

final class ModelVisibilityDependencies {
  ModelVisibilityDependencies(Object? raw)
      : this.expressions([
          if (raw != null) NarrativeEventConditionExpression.fromJson(raw),
        ]);

  ModelVisibilityDependencies.expressions(
      Iterable<NarrativeEventConditionExpression> expressions) {
    for (final leaf in expressions.expand((expression) => expression.leaves)) {
      leaf.whenTyped<void>(
        civilWeekday: (_, __) {}, periodicRewardAvailable: (reference, _) =>
            rewardSceneIds.add(reference.sceneId),
        fact: (id, operator, expected) => factIds.add(id),
        narrativeEventConsumed: (id, _) => eventIds.add(id),
        mapEventInstanceBoolean: (mapId, eventId, key, expected) =>
            mapIds.add(mapId),
      );
    }
  }

  final rewardSceneIds = <String>{};
  final factIds = <String>{};
  final eventIds = <String>{};
  final mapIds = <String>{};
}
