part of 'playable_map_game.dart';

final class _SceneWarpPresentationOwner {
  _SceneWarpPresentationOwner(this.overlay);

  final WarpPresentationOverlayComponent overlay;
  MapActivation? activation;
}

extension _PlayableMapWarpPresentation on PlayableMapGame {
  bool _ownsSceneWarpTransfer(_SceneWarpPresentationOwner owner) =>
      !_isRemoved &&
      _flowPhase == _RuntimeFlowPhase.mapTransition &&
      identical(_warpTransitionOverlay, owner.overlay) &&
      owner.overlay.controller.phase ==
          RuntimeWarpPresentationPhase.transferring;

  Future<RuntimeWarpPresentationRenderer> _prepareSceneWarpPresentation(
    SceneWarpInteractiveCommand command,
  ) async {
    final source = _bundle;
    final session = _activeNarrativeSceneWorkingSession;
    if (_isRemoved ||
        _flowPhase != _RuntimeFlowPhase.overworld ||
        _warpTransitionOverlay != null ||
        source.map.spatialScene != null) {
      throw StateError('Warp presentation requires the current 2D overworld.');
    }
    final images = await _loadTilesetImagesCached(
      source.runtimeImageAbsolutePathsById,
      manifest: source.manifest,
      resourceBundle: source,
    );
    if (!identical(source, _bundle) ||
        !_scenePresentationScopeIsCurrent(session) ||
        _flowPhase != _RuntimeFlowPhase.overworld ||
        _warpTransitionOverlay != null) {
      throw StateError('Warp presentation preparation is no longer current.');
    }
    return RuntimeWarpPresentationRenderer(
      presentation: command.presentation!,
      project: source.manifest,
      images: images,
    );
  }

  Future<bool> _executePresentedSceneWarp(
    SceneWarpInteractiveCommand command,
    TriggeredWarp warp,
    RuntimeWarpPresentationRenderer renderer,
    Future<TriggeredWarp> Function() resolveTarget,
  ) async {
    late final _SceneWarpPresentationOwner owner;
    final controller = RuntimeWarpPresentationController(
      presentation: command.presentation!,
      transfer: () => _handleWarp(
        warp,
        resolveTarget: resolveTarget,
        allowMapActivationWork: true,
        skipVisualTransition: true,
        arrivalFacing: command.arrivalFacing,
        arrivalCollisionOwnerEntityId: command.arrivalCollisionOwnerEntityId,
        presentationOwner: owner,
      ),
    );
    final overlay = WarpPresentationOverlayComponent(
      viewportSize: camera.viewport.size.clone(),
      controller: controller,
      renderer: renderer,
    );
    owner = _SceneWarpPresentationOwner(overlay);
    _setFlowPhase(_RuntimeFlowPhase.mapTransition);
    _clearPressedMovementControls();
    _warpTransitionOverlay = overlay;
    try {
      camera.viewport.add(overlay);
      final outcome = await controller.outcome;
      if (outcome != RuntimeWarpPresentationOutcome.completed ||
          _isRemoved ||
          !identical(_warpTransitionOverlay, overlay)) {
        return false;
      }
      _setFlowPhase(_RuntimeFlowPhase.overworld);
      final activation = owner.activation;
      if (activation == null) return false;
      final session = _activeNarrativeSceneWorkingSession;
      if (session != null && session.defersMapActivation) {
        session.deferredMapActivation = activation;
      } else {
        _installMapActivation(activation);
        _resetTriggerEnterOccupancy();
        await _dispatchCompletedMapActivation(activation);
      }
      return true;
    } finally {
      final ownsOverlay = identical(_warpTransitionOverlay, overlay);
      overlay.close();
      if (ownsOverlay) {
        _warpTransitionOverlay = null;
        if (!_isRemoved &&
            controller.phase == RuntimeWarpPresentationPhase.completed) {
          _setFlowPhase(_RuntimeFlowPhase.overworld);
        }
      }
    }
  }
}
