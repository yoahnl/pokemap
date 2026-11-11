part of 'cinematic_workspace_page.dart';

extension _CinematicPageMap on _CinematicWorkspacePageState {
  CinematicMediaPlaybackPort Function(ProjectManifest)? get mediaFactory {
    final source = widget.visuals;
    return source is CinematicMediaWorkspaceVisuals
        ? (source as CinematicMediaWorkspaceVisuals).createCinematicMedia
        : null;
  }

  void prepareMap(CinematicAsset asset) => controller.prepareMapPreview(
    load: widget.loader.load,
    media: mediaFactory,
  );

  void preparePlan() => controller.prepareMapPlan(media: mediaFactory);

  Widget mapContent() {
    final current = model;
    if (current != null) {
      return CinematicMapScene(
        key: ValueKey('${current.asset.id}:${current.map.id}'),
        model: current,
        visuals: widget.visuals,
        view: view!,
        transport: controller.transport,
        changed: refresh,
        onPoint: point,
        onPointMove: movePoint,
        beforeSelect: flush,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: mapError != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StudioNotice(mapError!, isError: true),
                  StudioButton(
                    label: 'Réessayer la carte',
                    onPressed: () {
                      controller.retryMapPreview();
                      refresh();
                    },
                  ),
                ],
              )
            : loadingMapId == null
            ? const Text(
                'Choisissez une carte dans les propriétés. La timeline reste éditable.',
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  Future<void> movePoint(CinematicStagePoint point, Offset destination) async {
    if (!flush() || model == null) return;
    await controller.moveStagePointTo(
      point.id,
      destination.dx,
      destination.dy,
      model: model!,
      confirmShared: (uses) => confirm(
        'Déplacer ce repère partagé ?',
        'Ce déplacement affecte ${uses.join(', ')}.',
      ),
      isActive: () => mounted,
    );
    if (mounted) {
      view!.spatialError = controller.error;
      refresh();
    }
  }

  void point(Offset point) {
    if (!flush()) return;
    final state = view!, current = model!;
    final outcome = controller.applyMapPoint(
      mode: state.mode,
      stepId: state.stepId,
      actorId: state.actorId,
      x: point.dx,
      y: point.dy,
      width: current.map.size.width,
      height: current.map.size.height,
    );
    if (outcome == null) return;
    state.spatialError = outcome.error;
    state.mode = outcome.mode;
    refresh();
  }
}
