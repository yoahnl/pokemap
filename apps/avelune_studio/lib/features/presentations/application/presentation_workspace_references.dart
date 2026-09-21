part of 'presentation_workspace_controller.dart';

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
}
