import 'package:map_core/map_core.dart';

final class PresentationStudioPropertyCommand {
  PresentationStudioPropertyCommand({
    required this.actionId,
    required Map<String, Object?> parameters,
  }) : parameters = Map<String, Object?>.unmodifiable(parameters);

  factory PresentationStudioPropertyCommand.updateCinematic({
    required PresentationCinematicAsset cinematic,
  }) => PresentationStudioPropertyCommand(
    actionId: 'presentationCinematic.update',
    parameters: <String, Object?>{
      'cinematicId': cinematic.id,
      'title': cinematic.title,
      'description': cinematic.description,
      'durationUs': cinematic.durationUs,
    },
  );

  factory PresentationStudioPropertyCommand.updateLayer({
    required String cinematicId,
    required PresentationLayer layer,
  }) => PresentationStudioPropertyCommand(
    actionId: 'presentationLayer.update',
    parameters: <String, Object?>{
      'cinematicId': cinematicId,
      'layer': encodePresentationLayer(layer),
    },
  );

  /// Authors the branches of one interaction cue — BETA-CIN-079.
  ///
  /// The routes live on the Scene binding, so this command carries the Scene
  /// coordinates the read model resolved, never the Presentation clip.
  factory PresentationStudioPropertyCommand.setCueRoutes({
    required String sceneId,
    required String presentationNodeId,
    required String markerId,
    required List<ScenePresentationCueOutcomeRoute> routes,
  }) => PresentationStudioPropertyCommand(
    actionId: 'scene.presentation.cue.routes.set',
    parameters: <String, Object?>{
      'sceneId': sceneId,
      'presentationNodeId': presentationNodeId,
      'markerId': markerId,
      'routes': routes.map((route) => route.toJson()).toList(growable: false),
    },
  );

  factory PresentationStudioPropertyCommand.updateClip({
    required String cinematicId,
    required String trackId,
    required PresentationClip clip,
  }) => PresentationStudioPropertyCommand(
    actionId: 'presentationClip.update',
    parameters: <String, Object?>{
      'cinematicId': cinematicId,
      'trackId': trackId,
      'clip': encodePresentationClip(clip),
    },
  );

  final String actionId;
  final Map<String, Object?> parameters;
}
