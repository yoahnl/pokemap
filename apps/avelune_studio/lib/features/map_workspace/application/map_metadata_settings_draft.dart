import 'package:map_core/map_core_domain.dart';

class MapMetadataSettingsDraft {
  MapMetadataSettingsDraft(MapData map)
    : mapId = map.id,
      dungeon = map.mapMetadata.escapeRopeDungeonId ?? '',
      allowed = map.mapMetadata.allowEscapeRope,
      bicycle = map.mapMetadata.allowBicycle,
      rules = [...map.contextualItemUses];

  final String mapId;
  String dungeon;
  bool allowed, bicycle;
  List<ContextualItemUseRule> rules;
  bool rulesEdited = false;

  bool valid(ProjectManifest project) =>
      dungeon.isEmpty || project.groups.any((group) => group.id == dungeon);

  Map<String, Object?> get parameters => {
    'mapId': mapId,
    'escapeRopeDungeonId': dungeon.isEmpty ? null : dungeon,
    'allowEscapeRope': allowed,
    'allowBicycle': bicycle,
    if (rulesEdited)
      'contextualItemUses': rules.map((rule) => rule.toJson()).toList(),
  };
}

final class MapContextualItemUseDraft {
  MapContextualItemUseDraft(this.id);
  factory MapContextualItemUseDraft.fromRule(ContextualItemUseRule rule) =>
      MapContextualItemUseDraft(rule.id)
        ..itemId = rule.itemId
        ..sceneId = rule.sceneId
        ..priority = rule.priority.toString()
        ..precise = rule.position != null
        ..x = (rule.position?.x ?? 0).toString()
        ..y = (rule.position?.y ?? 0).toString()
        ..facing = rule.facing?.name ?? ''
        ..condition = rule.conditionExpression;
  final String id;
  String itemId = '',
      sceneId = '',
      priority = '0',
      x = '0',
      y = '0',
      facing = '';
  bool precise = false;
  NarrativeEventConditionExpression? condition;

  bool isValid(
    MapData map,
    Map<String, String> items,
    Map<String, String> scenes,
  ) {
    final p = int.tryParse(priority),
        px = int.tryParse(x),
        py = int.tryParse(y);
    return items.containsKey(itemId) &&
        scenes.containsKey(sceneId) &&
        p != null &&
        p >= -1000000 &&
        p <= 1000000 &&
        (!precise ||
            px != null &&
                py != null &&
                px >= 0 &&
                py >= 0 &&
                px < map.size.width &&
                py < map.size.height);
  }

  ContextualItemUseRule toRule() => ContextualItemUseRule(
    id: id,
    itemId: itemId,
    sceneId: sceneId,
    priority: int.parse(priority),
    position: precise ? GridPos(x: int.parse(x), y: int.parse(y)) : null,
    facing: facing.isEmpty ? null : EntityFacing.values.byName(facing),
    conditionExpression: condition,
  );
}
