part of 'spatial_map_editing_viewport.dart';

extension _SpatialGestureStart on _SpatialMapEditingViewportState {
  bool start(
    int x,
    int z, {
    SpatialSceneContentHit? hit,
    bool dragging = false,
  }) {
    if (editingExterior && !isExteriorDecorationTool(widget.view.tool)) {
      widget.document.error =
          'Le décor extérieur accepte uniquement les outils visuels.';
      widget.onChanged();
      return false;
    }
    if (editingExterior && !_exteriorGestureActive) {
      exterior!.beginGesture();
      _exteriorGestureActive = true;
      _exteriorLastCell = GridPos(
        x: x + exterior!.originX,
        y: z + exterior!.originZ,
      );
    }
    final started = _startSegment(x, z, hit: hit, dragging: dragging);
    if (!started && _exteriorGestureActive) {
      exterior!.endGesture();
      _exteriorGestureActive = false;
      _exteriorLastCell = null;
    }
    return started;
  }

  bool _startSegment(
    int x,
    int z, {
    SpatialSceneContentHit? hit,
    bool dragging = false,
  }) {
    if (_exteriorGestureActive) _bindExteriorEnvironment(create: true);
    widget.view.reconcileLocks(editingDocument);
    if (hit != null && !canSelectContent(hit.kind, hit.id)) {
      discardGesture();
      widget.onChanged();
      return false;
    }
    if (locked ||
        (widget.view.spatialFreeView &&
            widget.view.tool == StudioMapTool.select &&
            hit == null) ||
        widget.view.tool == StudioMapTool.pan) {
      return false;
    }
    widget.view.rampPreview = null;
    widget.view.terrainSurfacePreview = null;
    if (selectingTerrainSurface) {
      selectTerrainSurfaceAt(x + .5, z + .5);
      return false;
    }
    if (widget.view.tool == StudioMapTool.border) {
      if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) {
        return startBorderErase(GridPos(x: x, y: z));
      }
      addBorderAngle(GridPos(x: x, y: z));
      return false;
    }
    final armedMove = widget.view.pendingMove;
    if ((hit?.kind == SpatialSceneContentKind.model &&
                hit!.id.startsWith('smt_') ||
            armedMove?.id.startsWith('smt_') == true) &&
        {
          StudioMapTool.select,
          StudioMapTool.eraseDecor,
        }.contains(widget.view.tool)) {
      discardGesture();
      editingDocument.error = SpatialModelEditingCommands.paintedTerrainMessage;
      widget.onChanged();
      return false;
    }
    discardGesture();
    widget.view.pendingMove = armedMove;
    focus.requestFocus();
    gestureFreeView = widget.view.spatialFreeView;
    final document = editingDocument;
    final cell = GridPos(x: x, y: z);
    final commands = SpatialModelEditingCommands(document, widget.project);
    try {
      if (widget.view.tool == StudioMapTool.environment) {
        return startEnvironment(cell);
      }
      if (widget.view.tool == StudioMapTool.terrain ||
          widget.view.tool == StudioMapTool.erase ||
          widget.view.tool == StudioMapTool.collisionPaint ||
          widget.view.tool == StudioMapTool.collisionErase) {
        final collision =
            widget.view.tool == StudioMapTool.collisionPaint ||
            widget.view.tool == StudioMapTool.collisionErase;
        if (!collision &&
            widget.view.spatialTerrainMode != SpatialTerrainMode.ground) {
          reliefStroke = SpatialTerrainStroke(
            source: document.current,
            models: widget.project.models3d,
            mode: widget.view.spatialTerrainMode,
            level: widget.view.spatialTerrainLevel,
            erase: widget.view.tool == StudioMapTool.erase,
            origin: cell,
            reanchorInstances: widget.view.spatialSurfaceReanchorInstances,
            surfaceBrush:
                widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
                    widget.view.spatialContinuousTerrain
                ? widget.view.tool == StudioMapTool.erase
                      ? const SpatialTerrainSurfaceBrush(
                          lowLevel: 0,
                          highLevel: 0,
                          direction: SpatialRampDirection.north,
                        )
                      : SpatialTerrainSurfaceBrush.parse(
                          lowLevel: widget.view.spatialSurfaceLowLevel,
                          highLevel: widget.view.spatialSurfaceHighLevel,
                          direction: widget.view.spatialSurfaceDirection,
                        )
                : null,
          );
          terrainSurfaceOptions = widget.view.terrainSurfaceOptions;
          terrainSource = document.current;
          terrainProject = widget.project;
          terrainTool = widget.view.tool;
          document.error = reliefStroke!.error;
          widget.onChanged();
          return true;
        }
        terrainStroke = MapCanvasStroke.start(
          map: document.current,
          project: widget.project,
          view: widget.view,
          commands: MapEditingCommands(document, widget.project),
          origin: cell,
        );
        terrainSource = terrainStroke == null ? null : document.current;
        terrainProject = terrainStroke == null ? null : widget.project;
        terrainTool = terrainStroke == null ? null : widget.view.tool;
        widget.onChanged();
        return terrainStroke != null;
      }
      if (widget.view.tool == StudioMapTool.place &&
          widget.view.model3d != null) {
        final item = commands.place(widget.view.model3d!, cell);
        widget.view.select(document, MapSelectionFamily.decor, item.id);
        widget.onChanged();
        return true;
      }
      final armed = widget.view.pendingMove;
      final instance = armed != null
          ? (armed.family == MapSelectionFamily.decor
                ? commands.selected(armed.id)
                : null)
          : hit?.kind == SpatialSceneContentKind.model
          ? commands.selected(hit!.id)
          : hit != null
          ? null
          : document.current.spatialScene!.instances
                .where(
                  (item) =>
                      item.position.x.floor() == x &&
                      item.position.z.floor() == z &&
                      !document.isElementUnavailable('model', item.id),
                )
                .lastOrNull;
      if (instance != null &&
          !document.isElementUnavailable('model', instance.id) &&
          {
            StudioMapTool.select,
            StudioMapTool.erase,
            StudioMapTool.eraseDecor,
          }.contains(widget.view.tool)) {
        final borderOwner = commands.borderOwner(instance.id);
        if (borderOwner != null) {
          widget.view.borderFeature = borderOwner;
          document.error = SpatialModelEditingCommands.generatedBorderMessage;
          widget.onChanged();
          return false;
        }
        final keys = HardwareKeyboard.instance;
        if (widget.view.tool == StudioMapTool.select &&
            armed == null &&
            !dragging &&
            (keys.isShiftPressed || keys.isMetaPressed)) {
          widget.view.toggleDecorInSelection(document, instance.id);
        } else if (widget.view.tool != StudioMapTool.select) {
          commands.delete(instance.id);
        } else {
          widget.view.select(document, MapSelectionFamily.decor, instance.id);
          document.stackPosition = cell;
          modelGesture = instance.id;
          modelEnd = null;
          modelOrigin = cell;
          modelPosition = instance.position;
          contentSource = document.current;
          contentProject = widget.project;
        }
        widget.onChanged();
        return true;
      }
      if (!{
        StudioMapTool.select,
        StudioMapTool.character,
        StudioMapTool.sign,
        StudioMapTool.zone,
        StudioMapTool.spawn,
        StudioMapTool.warp,
        StudioMapTool.gameplayZone,
        StudioMapTool.eraseDecor,
      }.contains(widget.view.tool)) {
        document.error = 'Cet outil ne s’applique pas aux décors et personnages de cette carte 3D.';
        widget.onChanged();
        return false;
      }
    } on Object catch (failure) {
      document.error = failure.toString();
      widget.onChanged();
      return false;
    }
    if (widget.view.pendingMove == null &&
        hit?.kind == SpatialSceneContentKind.actor &&
        hit!.id.startsWith('npc:') &&
        widget.view.tool == StudioMapTool.select) {
      final entity = document.current.entities
          .where((entity) => entity.id == hit.id.substring(4))
          .firstOrNull;
      if (entity == null || entity.pos.x != x || entity.pos.y != z) {
        return false;
      }
      widget.view.select(document, MapSelectionFamily.character, entity.id);
    }
    if (widget.view.pendingMove == null &&
        hit != null &&
        widget.view.tool == StudioMapTool.select &&
        (hit.kind == SpatialSceneContentKind.marker ||
            hit.kind == SpatialSceneContentKind.warp)) {
      final family = hit.kind == SpatialSceneContentKind.marker
          ? MapSelectionFamily.marker
          : MapSelectionFamily.warp;
      widget.view.select(document, family, hit.id);
      widget.view.pendingMove = MapSelectionTarget(
        mapId: document.current.id,
        family: family,
        id: hit.id,
      );
    }
    gesture = MapCharacterGesture.start(
      document: editingDocument,
      project: widget.project,
      view: widget.view,
      origin: GridPos(x: x, y: z),
    );
    if ((gesture?.entity != null || gesture?.warp != null) &&
        widget.view.tool == StudioMapTool.select) {
      contentSource = document.current;
      contentProject = widget.project;
    }
    widget.onChanged();
    return gesture != null;
  }
}
