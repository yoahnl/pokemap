import 'enums.dart';
import 'geometry.dart';
import 'narrative_event_definition.dart';
import 'narrative_event_wire.dart';

final class ContextualItemUseRule {
  const ContextualItemUseRule({
    required this.id,
    required this.itemId,
    required this.sceneId,
    this.priority = 0,
    this.position,
    this.facing,
    this.conditionExpression,
  });

  final String id;
  final String itemId;
  final String sceneId;
  final int priority;
  final GridPos? position;
  final EntityFacing? facing;
  final NarrativeEventConditionExpression? conditionExpression;

  factory ContextualItemUseRule.fromJson(Map<String, dynamic> json) {
    final object = NarrativeEventWire.object(json, path: 'contextualItemUse');
    NarrativeEventWire.expectExactFields(object, const {
      'id',
      'itemId',
      'sceneId',
      'priority',
      'position',
      'facing',
      'conditionExpression',
    }, path: 'contextualItemUse');
    final priority = json['priority'] ?? 0;
    if (priority is! int || priority < -1000000 || priority > 1000000) {
      throw const FormatException('Invalid contextual item priority.');
    }
    GridPos? position;
    if (json['position'] != null) {
      final raw = json['position'];
      if (raw is! Map<String, dynamic> ||
          raw.keys.any((key) => key != 'x' && key != 'y') ||
          raw['x'] is! int ||
          raw['y'] is! int ||
          (raw['x'] as int) < 0 ||
          (raw['y'] as int) < 0) {
        throw const FormatException('Invalid contextual item position.');
      }
      position = GridPos.fromJson(raw);
    }
    final facing = json['facing'];
    if (facing != null &&
        !EntityFacing.values.any((value) => value.name == facing)) {
      throw const FormatException('Invalid contextual item facing.');
    }
    return ContextualItemUseRule(
      id: NarrativeEventWire.requiredIdentity(
        object,
        'id',
        path: 'contextualItemUse',
      ),
      itemId: NarrativeEventWire.requiredIdentity(
        object,
        'itemId',
        path: 'contextualItemUse',
      ),
      sceneId: NarrativeEventWire.requiredIdentity(
        object,
        'sceneId',
        path: 'contextualItemUse',
      ),
      priority: priority,
      position: position,
      facing: facing == null
          ? null
          : EntityFacing.values.byName(facing as String),
      conditionExpression: json['conditionExpression'] == null
          ? null
          : NarrativeEventConditionExpression.fromJson(
              json['conditionExpression'],
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'sceneId': sceneId,
    'priority': priority,
    if (position != null) 'position': position!.toJson(),
    if (facing != null) 'facing': facing!.name,
    if (conditionExpression != null)
      'conditionExpression': conditionExpression!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is ContextualItemUseRule &&
      id == other.id &&
      itemId == other.itemId &&
      sceneId == other.sceneId &&
      priority == other.priority &&
      position == other.position &&
      facing == other.facing &&
      conditionExpression == other.conditionExpression;

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    sceneId,
    priority,
    position,
    facing,
    conditionExpression,
  );
}
