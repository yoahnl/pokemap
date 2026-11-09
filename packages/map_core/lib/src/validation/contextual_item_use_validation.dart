import '../exceptions/map_exceptions.dart';
import '../models/contextual_item_use_rule.dart';
import '../models/items/project_item_catalog.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/project_manifest.dart';
import '../operations/periodic_reward_condition_evaluator.dart';

void validateContextualItemUseRules(
  MapData map, {
  ProjectManifest? project,
  ProjectItemCatalog? itemCatalog,
  List<MapData> maps = const [],
  PeriodicRewardSceneLookup? lookupRewardScenes,
}) {
  final rules = map.contextualItemUses;
  if (rules.length > 128)
    throw const ValidationException(
      'A map supports at most 128 contextual item uses.',
    );
  final ids = <String>{};
  for (final rule in rules) {
    ContextualItemUseRule.fromJson(rule.toJson());
    if (!ids.add(rule.id))
      throw ValidationException('Duplicate contextual item use: ${rule.id}.');
    final position = rule.position;
    if (position != null &&
        (position.x >= map.size.width || position.y >= map.size.height)) {
      throw ValidationException(
        'Contextual item use ${rule.id} is outside the map.',
      );
    }
    if (itemCatalog != null &&
        itemCatalog.entries.where((item) => item.id == rule.itemId).length !=
            1) {
      throw ValidationException(
        'Contextual item use ${rule.id} requires one existing item.',
      );
    }
    if (project == null) continue;
    if (project.scenes.where((scene) => scene.id == rule.sceneId).length != 1) {
      throw ValidationException(
        'Contextual item use ${rule.id} requires one existing Scene.',
      );
    }
    for (final condition
        in rule.conditionExpression?.leaves ??
            const <NarrativeEventCondition>[]) {
      condition.whenTyped<void>(
        civilWeekday: (_, _) {},
        periodicRewardAvailable: (reference, _) {
          if (!resolvePeriodicRewardReference(
            reference: reference,
            lookupScenes:
                lookupRewardScenes ??
                (id) => project.scenes.where((scene) => scene.id == id),
          ).isResolved) {
            throw ValidationException(
              'Contextual item use ${rule.id} refers to an unavailable reward.',
            );
          }
        },
        fact: (id, _, expected) {
          if (project.facts
                  .where(
                    (fact) => fact.id == id && fact.valueKind == expected.kind,
                  )
                  .length !=
              1) {
            throw ValidationException(
              'Contextual item use ${rule.id} refers to an unavailable or mistyped Fact.',
            );
          }
        },
        narrativeEventConsumed: (id, _) {
          if (project.eventRegistry?.records
                  .where(
                    (event) => event.id == id && event.definitionOrNull != null,
                  )
                  .length !=
              1) {
            throw ValidationException(
              'Contextual item use ${rule.id} refers to an unavailable Event.',
            );
          }
        },
        mapEventInstanceBoolean: (mapId, entityId, _, _) {
          final owners = mapId == map.id
              ? [map]
              : maps.where((candidate) => candidate.id == mapId).toList();
          if (project.settings.mapInstanceRetentionPolicy == null ||
              owners.length != 1 ||
              owners.single.entities
                      .where((entity) => entity.id == entityId)
                      .length !=
                  1) {
            throw ValidationException(
              'Contextual item use ${rule.id} requires an existing instance owner and retention policy.',
            );
          }
        },
      );
    }
  }
}
