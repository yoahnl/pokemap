part of 'cinematic_workspace_page.dart';

extension _CinematicPageMap on _CinematicWorkspacePageState {
  void prepareMap(CinematicAsset asset) {
    if (loadingMapId != asset.mapId) {
      loadingMapId = asset.mapId;
      loadedMap = null;
      model = null;
      mapError = null;
      final generation = ++loadGeneration, id = asset.mapId;
      if (id != null) {
        unawaited(
          widget.loader
              .load(id)
              .then((map) {
                if (!mounted ||
                    generation != loadGeneration ||
                    loadingMapId != id) {
                  return;
                }
                loadedMap = map;
                refresh();
              })
              .catchError((Object failure) {
                if (!mounted || generation != loadGeneration) return;
                mapError = failure.toString();
                refresh();
              }),
        );
      }
    }
    final open = widget.loader.workspace.documents[asset.mapId]?.current;
    if (open != null) loadedMap = open;
    final map = loadedMap;
    if (map != null &&
        (model?.asset != asset ||
            model?.project != controller.project ||
            model?.map != map)) {
      model = CinematicMapModel(asset, controller.project, map);
      preparePlan();
    }
    if (map == null) preparePlan();
  }

  void preparePlan() {
    final current = model;
    final source = widget.visuals;
    final identity = (controller.activeId, controller.project);
    if (mediaIdentity != identity && source is CinematicMediaWorkspaceVisuals) {
      mediaIdentity = identity;
      controller.transport.configureMedia(
        (source as CinematicMediaWorkspaceVisuals).createCinematicMedia(
          controller.project,
        ),
      );
    }
    controller.preparePreview(
      actorDisplay: current?.actors,
      resolvedTargets: current?.targets ?? const {},
      stageBounds: current?.bounds,
    );
  }

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
                      loadingMapId = null;
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
    if (destination.dx < 0 ||
        destination.dy < 0 ||
        destination.dx >= model!.map.size.width ||
        destination.dy >= model!.map.size.height) {
      view!.spatialError = 'Le repère doit rester dans la carte.';
      refresh();
      return;
    }
    view!.spatialError = null;
    final owner = controller.active!;
    final uses = cinematicPointUses(owner.asset, point.id);
    if (uses.length > 1 &&
        !await confirm(
          'Déplacer ce repère partagé ?',
          'Ce déplacement affecte ${uses.join(', ')}.',
        )) {
      return;
    }
    if (!mounted ||
        controller.activeId != owner.asset.id ||
        controller.active?.revision != owner.revision) {
      return;
    }
    controller.setStagePoint(
      CinematicStagePoint(
        id: point.id,
        label: point.label,
        x: destination.dx,
        y: destination.dy,
        description: point.description,
      ),
    );
  }

  void point(Offset point) {
    if (!flush()) return;
    final state = view!, current = model!;
    if (state.mode == CinematicMapMode.select ||
        state.mode == CinematicMapMode.pan) {
      return;
    }
    if (point.dx < 0 ||
        point.dy < 0 ||
        point.dx >= current.map.size.width ||
        point.dy >= current.map.size.height) {
      state.spatialError = 'Choisissez une case dans la carte.';
      refresh();
      return;
    }
    state.spatialError = null;
    if (state.mode == CinematicMapMode.destination && state.stepId != null) {
      if (controller.setDestination(
        state.stepId!,
        point.dx,
        point.dy,
        width: current.map.size.width,
        height: current.map.size.height,
      )) {
        state.mode = CinematicMapMode.select;
      }
    } else if (state.mode == CinematicMapMode.placement &&
        state.actorId != null) {
      if (controller.placeActorAt(
        state.actorId!,
        point.dx,
        point.dy,
        width: current.map.size.width,
        height: current.map.size.height,
      )) {
        state.mode = CinematicMapMode.select;
      }
    } else if (state.mode == CinematicMapMode.path && state.stepId != null) {
      controller.appendWaypoint(
        state.stepId!,
        point.dx,
        point.dy,
        width: current.map.size.width,
        height: current.map.size.height,
      );
    }

    refresh();
  }
}
