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

    /// Couche fonctionnelle du scénario:
    /// - globalStory: progression centrale
    /// - localEventFlow: hooks monde locaux
    ///
    /// Cette séparation explicite est la base du modèle story-centric.
    @Default(ScenarioScope.localEventFlow) ScenarioScope scope,
    required String entryNodeId,

    /// Liste d'outcomes "métier" déclarés par ce scénario.
    ///
    /// Exemple:
    /// - professor_intro.completed
    /// - starter.selected.fire
    ///
    /// Objectif: rendre les transitions locales -> globales explicites.
    @Default(<String>[]) List<String> declaredOutcomes,

    /// Gating optionnel du scénario.
    ///
    /// Si défini, le runtime n'activera ce scénario que lorsque la condition
    /// est vraie. Permet au graphe global de piloter l'activation des flows
    /// locaux sans dupliquer les règles partout.
    ScriptCondition? activationCondition,
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

    /// Identifiant d'outcome explicite.
    ///
    /// Utilisé notamment par:
    /// - sourceOutcome (consommation côté global)
    /// - emitOutcome (production côté local)
    String? outcomeId,
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

/// Couche fonctionnelle d'un scénario.
///
/// Cette séparation est volontairement explicite:
/// - `globalStory`: graphe de progression narrative globale.
/// - `localEventFlow`: flow local branché sur des hooks monde.
///
/// Elle permet de passer d'un modèle purement "event-centric" vers un modèle
/// "story-centric" où les events locaux deviennent des points d'entrée/sortie
/// rattachés à une progression globale.
enum ScenarioScope {
  @JsonValue('globalStory')
  globalStory,
  @JsonValue('localEventFlow')
  localEventFlow,
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
