part of 'spatial_map_editing_viewport.dart';

extension _SpatialExteriorAuthoring on _SpatialMapEditingViewportState {
  void _bindExterior() {
    final next = exterior;
    if (identical(next, _exteriorNotifier)) return;
    _exteriorNotifier?.removeListener(_exteriorChanged);
    _exteriorNotifier = next;
    _exteriorNotifier?.addListener(_exteriorChanged);
  }

  SpatialSceneAuthoringTarget? get authoringTarget {
    final controller = exterior;
    final child = controller?.editingDocument;
    if (!editingExterior || child == null) return null;
    return SpatialSceneAuthoringTarget(
      map: child.current,
      offset: Offset(
        controller!.originX.toDouble(),
        controller.originZ.toDouble(),
      ),
      decorationKey:
          'exterior:${widget.document.current.id}:${controller.selectedSectorId}',
    );
  }

  void _bindExteriorEnvironment({required bool create}) {
    if (!editingExterior || widget.view.tool != StudioMapTool.environment) {
      return;
    }
    final commands = EnvironmentEditingCommands(
      editingDocument,
      widget.project,
    );
    final session = widget.view.environment;
    final armedPresetId = widget.view.exteriorEnvironmentPresetId;
    final current = session == null ? null : commands.area(session);
    if (current == null &&
        armedPresetId != null &&
        _exteriorEnvironmentTemplate?.presetId != armedPresetId) {
      _exteriorEnvironmentTemplate = null;
      if (!create) return;
      final preset = widget.project.environmentPresets
          .where((preset) => preset.id == armedPresetId)
          .firstOrNull;
      if (preset == null) return;
      final created = commands.create(preset);
      widget.view.environment = created;
      _exteriorEnvironmentTemplate = commands.area(created);
      return;
    }
    if (current != null) {
      _exteriorEnvironmentTemplate = current;
      return;
    }
    final area = _exteriorEnvironmentTemplate;
    if (area == null) return;
    final existing = commands.areas
        .where(
          (entry) =>
              entry.area.presetId == area.presetId &&
              entry.area.seed == area.seed &&
              entry.area.paramsOverride == area.paramsOverride,
        )
        .firstOrNull;
    if (existing == null && !create) return;
    final next = existing == null
        ? commands.create(
            widget.project.environmentPresets.firstWhere(
              (preset) => preset.id == area.presetId,
            ),
          )
        : MapEnvironmentSession(
            layerId: existing.layer.id,
            areaId: existing.area.id,
          );
    if (existing == null) {
      editingDocument.commit(
        const EnvironmentEditing().updateArea(
          editingDocument.current,
          manifest: widget.project,
          layerId: next.layerId,
          areaId: next.areaId,
          seed: area.seed,
          paramsOverride: area.paramsOverride,
        ),
      );
    }
    next.tool = session?.tool ?? EnvironmentPaintTool.brush;
    widget.view.environment = next;
  }

  Iterable<ExteriorDecorationRect> get _neighborBounds => [
    for (final neighbor in widget.neighbors)
      ExteriorDecorationRect(
        x: neighbor.offset.dx.round(),
        z: neighbor.offset.dy.round(),
        width: neighbor.map.size.width,
        depth: neighbor.map.size.height,
      ),
  ];

  bool get _continuousExteriorStroke =>
      terrainStroke != null ||
      reliefStroke != null ||
      environmentGesture != null &&
          environmentGesture!.tool != EnvironmentPaintTool.rectangle;

  void _continueExteriorStroke(int x, int z) {
    final controller = exterior!;
    final definition = controller.current!;
    final last = _exteriorLastCell;
    if (last == null || last.x == x && last.y == z) return;
    final bounds = definition.outerBounds;
    final path = MapEncounterCellStroke(
      GridSize(width: bounds.width, height: bounds.depth),
      false,
      GridPos(x: last.x - bounds.x, y: last.y - bounds.z),
    )..paint(GridPos(x: x - bounds.x, y: z - bounds.z));
    for (final point in path.cells.skip(1)) {
      final logical = GridPos(x: point.x + bounds.x, y: point.y + bounds.z);
      final current = authoringTarget;
      if (current == null) return;
      var localX = logical.x - controller.originX,
          localZ = logical.y - controller.originZ;
      if (localX < 0 ||
          localZ < 0 ||
          localX >= current.map.size.width ||
          localZ >= current.map.size.height) {
        if (definition.isExcluded(
          logical.x,
          logical.y,
          neighborBounds: _neighborBounds,
        )) {
          return;
        }
        final session = widget.view.environment;
        final area = session == null
            ? null
            : EnvironmentEditingCommands(
                editingDocument,
                widget.project,
              ).area(session);
        finishSegment();
        if (!_exteriorGestureActive ||
            !controller.selectAt(
              logical.x,
              logical.y,
              neighborBounds: _neighborBounds,
            )) {
          return;
        }
        if (area != null) _exteriorEnvironmentTemplate = area;
        _bindExteriorEnvironment(create: true);
        localX = logical.x - controller.originX;
        localZ = logical.y - controller.originZ;
        if (!_startSegment(localX, localZ)) return;
      } else {
        updateDrag((localX, localZ));
      }
      _exteriorLastCell = logical;
    }
  }

  SpatialSceneAuthoringTarget? resolveAuthoringTarget(int x, int z) {
    final controller = exterior;
    if (!editingExterior ||
        controller == null ||
        !widget.exteriorContextReady) {
      return null;
    }
    final activeGesture =
        terrainStroke != null ||
        reliefStroke != null ||
        environmentGesture != null ||
        (borderEraseDraft != null || exteriorBorderEraseActive) ||
        gesture != null ||
        modelGesture != null ||
        widget.view.borderDraft != null;
    final target = authoringTarget;
    final environment = widget.view.environment;
    if (environment != null) {
      final area = EnvironmentEditingCommands(
        editingDocument,
        widget.project,
      ).area(environment);
      if (area != null) _exteriorEnvironmentTemplate = area;
    }
    if (_exteriorGestureActive && _continuousExteriorStroke) {
      _continueExteriorStroke(x, z);
      final selected = authoringTarget;
      return selected != null &&
              selected.map.spatialScene != null &&
              x >= controller.originX &&
              z >= controller.originZ &&
              x < controller.originX + selected.map.size.width &&
              z < controller.originZ + selected.map.size.height
          ? selected
          : null;
    }
    if (activeGesture &&
        target != null &&
        !(widget.view.tool == StudioMapTool.border)) {
      final localX = x - controller.originX, localZ = z - controller.originZ;
      return localX >= 0 &&
              localZ >= 0 &&
              localX < target.map.size.width &&
              localZ < target.map.size.height
          ? target
          : null;
    }
    if (!controller.selectAt(x, z, neighborBounds: _neighborBounds)) {
      return null;
    }
    _bindExteriorEnvironment(create: false);
    return authoringTarget;
  }

  List<SpatialSceneDecoration> decorationVisuals(
    SpatialWorkspaceVisuals visuals,
    MapData? preview,
  ) {
    final controller = exterior;
    var decoration = controller?.current;
    if (decoration == null) return widget.neighborDecorations;
    if (editingExterior &&
        preview != null &&
        controller?.selectedSectorId != null) {
      decoration = MapExteriorDecoration(
        mapId: decoration.mapId,
        playableWidth: decoration.playableWidth,
        playableDepth: decoration.playableDepth,
        west: decoration.west,
        east: decoration.east,
        north: decoration.north,
        south: decoration.south,
        borders: decoration.borders,
        sectors: [
          for (final sector in decoration.sectors)
            if (sector.id == controller!.selectedSectorId)
              ExteriorDecorationSector(
                id: sector.id,
                originX: sector.originX,
                originZ: sector.originZ,
                scene: preview.spatialScene!,
                layers: preview.layers,
              )
            else
              sector,
        ],
      );
    }
    decoration = withExteriorBorderPreview(decoration);
    return [
      ...widget.neighborDecorations,
      SpatialSceneDecoration(
        ownerMapId: widget.document.current.id,
        decoration: decoration,
        offset: Offset.zero,
        project: widget.project,
        loadGroundImage: visuals.readGroundImage,
        loadModel: visuals.readModel,
      ),
    ];
  }
}
