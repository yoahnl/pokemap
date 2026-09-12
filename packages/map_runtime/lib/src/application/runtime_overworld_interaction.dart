import 'package:map_core/map_core.dart';

enum RuntimeOverworldInteractionVerb { interact, talk, read, collect, enter }

enum RuntimeOverworldInteractionTargetKind { entity, placedElement, mapEvent }

final class RuntimeOverworldInteractionRequest {
  const RuntimeOverworldInteractionRequest({
    required this.sessionId,
    required this.mapActivationId,
    required this.mapId,
    required this.targetKind,
    required this.targetId,
    required this.actionId,
  });

  final String sessionId;
  final String mapActivationId;
  final String mapId;
  final RuntimeOverworldInteractionTargetKind targetKind;
  final String targetId;
  final String actionId;

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'mapActivationId': mapActivationId,
        'mapId': mapId,
        'targetKind': targetKind.name,
        'targetId': targetId,
        'actionId': actionId,
      };

  @override
  bool operator ==(Object other) =>
      other is RuntimeOverworldInteractionRequest &&
      sessionId == other.sessionId &&
      mapActivationId == other.mapActivationId &&
      mapId == other.mapId &&
      targetKind == other.targetKind &&
      targetId == other.targetId &&
      actionId == other.actionId;

  @override
  int get hashCode => Object.hash(
      sessionId, mapActivationId, mapId, targetKind, targetId, actionId);
}

final class RuntimeOverworldInteractionAction {
  const RuntimeOverworldInteractionAction({
    required this.request,
    required this.verb,
    required this.targetCell,
    required this.targetBounds,
  });

  final RuntimeOverworldInteractionRequest request;
  final RuntimeOverworldInteractionVerb verb;
  final GridPos targetCell;
  final PixelRect targetBounds;

  Map<String, Object?> toJson() => {
        'request': request.toJson(),
        'verb': verb.name,
        'targetCell': targetCell.toJson(),
        'targetBounds': {
          'leftPx': targetBounds.leftPx,
          'topPx': targetBounds.topPx,
          'widthPx': targetBounds.widthPx,
          'heightPx': targetBounds.heightPx,
        },
      };

  @override
  bool operator ==(Object other) =>
      other is RuntimeOverworldInteractionAction &&
      request == other.request &&
      verb == other.verb &&
      targetCell == other.targetCell &&
      targetBounds.leftPx == other.targetBounds.leftPx &&
      targetBounds.topPx == other.targetBounds.topPx &&
      targetBounds.widthPx == other.targetBounds.widthPx &&
      targetBounds.heightPx == other.targetBounds.heightPx;

  @override
  int get hashCode => Object.hash(
      request,
      verb,
      targetCell,
      targetBounds.leftPx,
      targetBounds.topPx,
      targetBounds.widthPx,
      targetBounds.heightPx);
}

final class RuntimeOverworldInteractionSnapshot {
  const RuntimeOverworldInteractionSnapshot({
    required this.sessionId,
    required this.mapActivationId,
    required this.mapId,
    this.primaryAction,
    RuntimeOverworldInteractionAction? tapAction,
  }) : tapAction = tapAction ?? primaryAction;

  final String sessionId;
  final String mapActivationId;
  final String mapId;
  final RuntimeOverworldInteractionAction? primaryAction;
  final RuntimeOverworldInteractionAction? tapAction;

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'mapActivationId': mapActivationId,
        'mapId': mapId,
        'primaryAction': primaryAction?.toJson(),
        'tapAction': tapAction?.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is RuntimeOverworldInteractionSnapshot &&
      sessionId == other.sessionId &&
      mapActivationId == other.mapActivationId &&
      mapId == other.mapId &&
      primaryAction == other.primaryAction &&
      tapAction == other.tapAction;

  @override
  int get hashCode =>
      Object.hash(sessionId, mapActivationId, mapId, primaryAction, tapAction);
}
