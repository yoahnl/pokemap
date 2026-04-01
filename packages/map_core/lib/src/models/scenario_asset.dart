import 'package:freezed_annotation/freezed_annotation.dart';

import 'script_conditions.dart';

part 'scenario_asset.freezed.dart';
part 'scenario_asset.g.dart';

@freezed
class ScenarioAsset with _$ScenarioAsset {
  @JsonSerializable(explicitToJson: true)
  const factory ScenarioAsset({
    required String id,
    required String name,
    @Default('') String description,
    required String entryNodeId,
    @Default(<ScenarioNode>[]) List<ScenarioNode> nodes,
    @Default(<ScenarioEdge>[]) List<ScenarioEdge> edges,
    @Default({}) Map<String, String> metadata,
  }) = _ScenarioAsset;

  factory ScenarioAsset.fromJson(Map<String, dynamic> json) =>
      _$ScenarioAssetFromJson(json);
}

@freezed
class ScenarioNode with _$ScenarioNode {
  @JsonSerializable(explicitToJson: true)
  const factory ScenarioNode({
    required String id,
    @Default(ScenarioNodeType.action) ScenarioNodeType type,
    @Default('') String title,
    @Default('') String description,
    @Default(ScenarioNodePosition(x: 0, y: 0)) ScenarioNodePosition position,
    @Default(ScenarioNodeBinding()) ScenarioNodeBinding binding,
    @Default(ScenarioNodePayload()) ScenarioNodePayload payload,
    @Default({}) Map<String, String> metadata,
  }) = _ScenarioNode;

  factory ScenarioNode.fromJson(Map<String, dynamic> json) =>
      _$ScenarioNodeFromJson(json);
}

@freezed
class ScenarioNodePosition with _$ScenarioNodePosition {
  const factory ScenarioNodePosition({
    required double x,
    required double y,
  }) = _ScenarioNodePosition;

  factory ScenarioNodePosition.fromJson(Map<String, dynamic> json) =>
      _$ScenarioNodePositionFromJson(json);
}

@freezed
class ScenarioNodeBinding with _$ScenarioNodeBinding {
  const factory ScenarioNodeBinding({
    String? mapId,
    String? eventId,
    String? entityId,
    String? warpId,
    String? triggerId,
    String? trainerId,
    String? dialogueId,
    String? scriptId,
    String? flagName,
    String? variableName,
  }) = _ScenarioNodeBinding;

  factory ScenarioNodeBinding.fromJson(Map<String, dynamic> json) =>
      _$ScenarioNodeBindingFromJson(json);
}

@freezed
class ScenarioNodePayload with _$ScenarioNodePayload {
  @JsonSerializable(explicitToJson: true)
  const factory ScenarioNodePayload({
    String? actionKind,
    String? message,
    ScriptCondition? condition,
    @Default(<String>[]) List<String> choiceLabels,
    @Default({}) Map<String, String> params,
  }) = _ScenarioNodePayload;

  factory ScenarioNodePayload.fromJson(Map<String, dynamic> json) =>
      _$ScenarioNodePayloadFromJson(json);
}

@freezed
class ScenarioEdge with _$ScenarioEdge {
  const factory ScenarioEdge({
    required String id,
    required String fromNodeId,
    required String toNodeId,
    @Default('') String label,
    @Default(ScenarioEdgeKind.next) ScenarioEdgeKind kind,
    @Default(0) int order,
    @Default({}) Map<String, String> metadata,
  }) = _ScenarioEdge;

  factory ScenarioEdge.fromJson(Map<String, dynamic> json) =>
      _$ScenarioEdgeFromJson(json);
}

enum ScenarioNodeType {
  @JsonValue('start')
  start,
  @JsonValue('dialogue')
  dialogue,
  @JsonValue('action')
  action,
  @JsonValue('condition')
  condition,
  @JsonValue('choice')
  choice,
  @JsonValue('reference')
  reference,
  @JsonValue('end')
  end,
}

enum ScenarioEdgeKind {
  @JsonValue('next')
  next,
  @JsonValue('trueBranch')
  trueBranch,
  @JsonValue('falseBranch')
  falseBranch,
  @JsonValue('choice')
  choice,
  @JsonValue('reference')
  reference,
}
