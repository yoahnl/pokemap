part of 'presentation_workspace_controller.dart';

typedef PresentationSceneUse = ({SceneAsset scene, SceneNode node});

const presentationScenarioUnlinkedError =
    'Liez cette présentation à une scène et enregistrez pour tester son parcours.';

bool _presents(SceneNode node, String presentationId) =>
    node.payload is ScenePresentationCinematicPayload &&
    (node.payload as ScenePresentationCinematicPayload)
            .presentationCinematicId ==
        presentationId;

SceneAsset? presentationScenarioScene(
  List<SceneAsset> scenes,
  String? preferredSceneId,
) =>
    scenes.where((scene) => scene.id == preferredSceneId).firstOrNull ??
    (scenes.length == 1 ? scenes.single : null);

extension PresentationWorkspaceReferences on PresentationWorkspaceController {
  Set<(String, PresentationReferenceKey?, PresentationReferenceKey, String)>
  _sceneReferenceProblems(
    PresentationWorkingSession session,
    PresentationCinematicAsset asset,
  ) {
    final scenes = <String, SceneAsset>{
      for (final scene in [...project.scenes, ...?sceneDrafts?.call()])
        scene.id: scene,
      if (session.link case final link?) link.scene.id: link.scene,
    };
    final graph = PresentationReferenceGraph.build(
      cinematics: [
        for (final a in entries)
          if (a.id != asset.id) a,
        asset,
      ],
      scenes: scenes.values,
      mediaCatalog: session.projection.mediaCatalog,
    );
    return {
      for (final diagnostic in graph.diagnostics)
        if (diagnostic.owner?.kind == PresentationReferenceKind.scene &&
            (diagnostic.target.parentId == asset.id ||
                diagnostic.target ==
                    PresentationReferenceKey.presentationCinematic(asset.id)))
          (
            diagnostic.code,
            diagnostic.owner,
            diagnostic.target,
            diagnostic.path,
          ),
    };
  }

  bool _referencesAllow(
    PresentationWorkingSession session,
    PresentationCinematicAsset proposed,
  ) {
    final before = _sceneReferenceProblems(session, session.asset);
    if (_sceneReferenceProblems(session, proposed).difference(before).isEmpty) {
      return true;
    }
    return _fail('Cette modification retire un repère utilisé par une scène.');
  }

  List<PresentationSceneUse> sceneUses(
    String presentationId, {
    PresentationClip? selected,
  }) {
    final scenes = <String, SceneAsset>{
      for (final scene in project.scenes) scene.id: scene,
      for (final scene in sceneDrafts?.call() ?? <SceneAsset>[])
        scene.id: scene,
    };
    return [
      for (final scene in scenes.values)
        for (final node in scene.graph.nodes)
          if (node.payload case ScenePresentationCinematicPayload payload)
            if (payload.presentationCinematicId == presentationId &&
                (selected is! PresentationMarkerClip ||
                    selected.markerKind !=
                        PresentationMarkerKind.interactionCue ||
                    payload.interactionCueBindings.any(
                      (binding) => binding.markerId == selected.id,
                    )))
              (scene: scene, node: node),
    ];
  }

  List<SceneAsset> scenarioScenes(String presentationId) => project.scenes
      .where(
        (scene) =>
            scene.graph.nodes.any((node) => _presents(node, presentationId)),
      )
      .toList();
}
