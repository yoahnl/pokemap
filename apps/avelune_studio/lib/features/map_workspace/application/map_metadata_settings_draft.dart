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

final class MapContextualItemUseCollectionDraft {
  MapContextualItemUseCollectionDraft(Iterable<ContextualItemUseRule> rules)
    : _drafts = rules.map(MapContextualItemUseDraft.fromRule).toList() {
    _usedIds.addAll(_drafts.map((draft) => draft.id));
  }

  final List<MapContextualItemUseDraft> _drafts;
  final Set<String> _usedIds = {};
  int _nextId = 1;

  List<MapContextualItemUseDraft> get drafts => List.unmodifiable(_drafts);
  bool get canAdd => _drafts.length < 128;
  bool get _validIdentities =>
      _drafts.every((draft) => draft.id.trim().isNotEmpty) &&
      _drafts.map((draft) => draft.id).toSet().length == _drafts.length;

  MapContextualItemUseDraft add() {
    if (!canAdd) {
      throw StateError(
        'Une carte accepte au maximum 128 utilisations d’objets.',
      );
    }
    var id = '';
    do {
      id = 'context-item-${_nextId++}';
    } while (!_usedIds.add(id));
    final draft = MapContextualItemUseDraft(id);
    _drafts.add(draft);
    return draft;
  }

  void removeAt(int index) => _drafts.removeAt(index);

  bool isValid(
    MapData map,
    Map<String, String> items,
    Map<String, String> scenes,
  ) =>
      _drafts.length <= 128 &&
      _validIdentities &&
      _drafts.every((draft) => draft.isValid(map, items, scenes));

  List<ContextualItemUseRule> toRules() {
    if (_drafts.length > 128 || !_validIdentities) {
      throw StateError(
        'La collection contient trop de règles ou des identifiants invalides.',
      );
    }
    return [for (final draft in _drafts) draft.toRule()];
  }
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
    return id.trim().isNotEmpty &&
        items.containsKey(itemId) &&
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
