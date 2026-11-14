part of 'spatial_map_editing_viewport.dart';

extension _SpatialSceneComposition on _SpatialMapEditingViewportState {
  bool get showsHover =>
      !locked &&
      {
        StudioMapTool.place,
        StudioMapTool.terrain,
        StudioMapTool.erase,
        StudioMapTool.collisionPaint,
        StudioMapTool.collisionErase,
        StudioMapTool.environment,
        StudioMapTool.gameplayZone,
        StudioMapTool.border,
      }.contains(widget.view.tool);

  Model3dVector3 positionFor(SpatialSurfaceHit hit) {
    final scene = editingDocument.current.spatialScene!;
    final x = precision
        ? hit.position.x.clamp(0.0, scene.width - .000001)
        : hit.cell.$1 + .5;
    final z = precision
        ? hit.position.z.clamp(0.0, scene.depth - .000001)
        : hit.cell.$2 + .5;
    return Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z);
  }

  SpatialModelPlacementPreview? get placementPreview {
    final model = widget.view.model3d;
    if (!showsHover ||
        hover == null ||
        widget.view.tool != StudioMapTool.place ||
        model == null ||
        !widget.project.models3d.any((item) => item.id == model.id)) {
      return null;
    }
    return SpatialModelPlacementPreview(
      modelId: model.id,
      position: positionFor(hover!),
    );
  }

  void surfaceTap(SpatialSurfaceHit hit) {
    if (locked) return;
    if (selectingTerrainSurface) {
      selectTerrainSurfaceAt(hit.position.x, hit.position.z);
      return;
    }
    if (widget.view.tool != StudioMapTool.place ||
        widget.view.model3d == null) {
      tap(hit.cell.$1, hit.cell.$2);
      return;
    }
    focus.requestFocus();
    try {
      final item = SpatialModelEditingCommands(
        editingDocument,
        widget.project,
      ).placeAt(widget.view.model3d!, positionFor(hit));
      widget.view.select(editingDocument, MapSelectionFamily.decor, item.id);
    } on Object catch (failure) {
      editingDocument.error = failure.toString();
    }
    hover = null;
    widget.onChanged();
  }

  bool canSelectContent(SpatialSceneContentKind kind, String id) {
    return !editingDocument.isElementUnavailable(
      switch (kind) {
        SpatialSceneContentKind.model => 'model',
        SpatialSceneContentKind.actor ||
        SpatialSceneContentKind.marker => 'entity',
        SpatialSceneContentKind.warp => 'warp',
      },
      kind == SpatialSceneContentKind.actor && id.startsWith('npc:')
          ? id.substring(4)
          : id,
    );
  }

  SpatialSceneVisibility get sceneVisibility => _visibilityFor(editingDocument);

  SpatialSceneVisibility _visibilityFor(EditableMapDocument document) {
    final state = document.editorState;
    final content = <(SpatialSceneContentKind, String)>{};
    final layers = <String>{};
    final kinds = <SpatialSceneContentKind>{};
    for (final family in state.hiddenFamilies) {
      switch (family) {
        case 'model':
          kinds.add(SpatialSceneContentKind.model);
        case 'entity':
          kinds.addAll([
            SpatialSceneContentKind.actor,
            SpatialSceneContentKind.marker,
          ]);
        case 'warp':
          kinds.add(SpatialSceneContentKind.warp);
      }
    }
    for (final key in state.hiddenElements) {
      final separator = key.indexOf(':');
      final kind = key.substring(0, separator);
      final id = key.substring(separator + 1);
      switch (kind) {
        case 'model':
          content.add((SpatialSceneContentKind.model, id));
        case 'entity':
          content.add((SpatialSceneContentKind.actor, 'npc:$id'));
          content.add((SpatialSceneContentKind.marker, id));
        case 'warp':
          content.add((SpatialSceneContentKind.warp, id));
        case 'layer':
          layers.add(id);
      }
    }
    final allLayers = state.hiddenFamilies.contains('layer');
    for (final layerId
        in allLayers
            ? document.current.layers.map((layer) => layer.id)
            : layers) {
      for (final id in document.elementIdsInLayer('model', layerId)) {
        content.add((SpatialSceneContentKind.model, id));
      }
    }
    return SpatialSceneVisibility(
      hiddenContent: content,
      hiddenKinds: kinds,
      hiddenLayers: layers,
      allLayersHidden: allLayers,
    );
  }

  Widget sceneView(MapWorkspaceVisuals visuals) {
    final freeView = widget.view.spatialFreeView;
    final borderMap = spatialBorderPreview;
    final rampMap =
        widget.view.tool == StudioMapTool.terrain &&
            widget.view.spatialTerrainMode == SpatialTerrainMode.ramp &&
            widget.view.rampPreview?.validFor(editingDocument.current) == true
        ? widget.view.rampPreview!.result
        : null;
    final terrainSurfaceMap =
        widget.view.tool == StudioMapTool.terrain &&
            widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
            widget.view.spatialContinuousTerrain &&
            widget.view.terrainSurfacePreview?.validFor(
                  editingDocument.current,
                ) ==
                true
        ? widget.view.terrainSurfacePreview!.result
        : null;
    final colors = Theme.of(context).colorScheme;
    final selectedModel = editingDocument.current.spatialScene!.instances
        .where(
          (instance) =>
              instance.id ==
              widget.view.selectedFor(
                editingDocument.current.id,
                MapSelectionFamily.decor,
              ),
        )
        .firstOrNull;
    final selectedActor = editingDocument.current.entities
        .where(
          (entity) =>
              entity.id ==
              widget.view.selectedFor(
                editingDocument.current.id,
                MapSelectionFamily.character,
              ),
        )
        .firstOrNull;
    return SpatialSceneView(
      modelSourceUpdates: visuals is SpatialModelSourceWorkspaceVisuals
          ? (visuals as SpatialModelSourceWorkspaceVisuals).modelSourceUpdates
          : null,
      neighbors: widget.neighbors,
      visibility: editingExterior
          ? _visibilityFor(widget.document)
          : sceneVisibility,
      decorations: decorationVisuals(
        visuals as SpatialWorkspaceVisuals,
        borderMap ??
            rampMap ??
            terrainSurfaceMap ??
            environmentPreview ??
            reliefStroke?.preview ??
            terrainStroke?.preview,
      ),
      authoringTarget: authoringTarget,
      resolveAuthoringTarget: editingExterior ? resolveAuthoringTarget : null,
      canSelectContent: canSelectContent,
      canSelectLayer: (id) =>
          !editingDocument.isElementUnavailable('layer', id),
      animationPreview: widget.view.spatialAnimations,
      onHover: showsHover ? updateHover : null,
      onSurfaceTap: surfaceTap,
      placementPreview: placementPreview,
      cellOverlays: cellOverlays(colors),
      contentPreview: contentPreview,
      selectedContent: selectedModel != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.model,
              id: selectedModel.id,
              cell: (
                selectedModel.position.x.floor(),
                selectedModel.position.z.floor(),
              ),
            )
          : selectedActor != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.actor,
              id: 'npc:${selectedActor.id}',
              cell: (selectedActor.pos.x, selectedActor.pos.y),
            )
          : null,
      selectionColor: colors.primary,
      onZoom: (delta) {
        final factor =
            (widget.view.scale * math.exp(-delta * .001)).clamp(.15, 8) /
            widget.view.scale;
        widget.view.transform.value = widget.view.transform.value.clone()
          ..scaleByDouble(factor, factor, 1, 1);
      },
      selectContent:
          widget.view.tool == StudioMapTool.select ||
          (!freeView && widget.view.tool == StudioMapTool.eraseDecor),
      scene: editingExterior
          ? widget.document.current.spatialScene!
          : borderMap?.spatialScene ??
                rampMap?.spatialScene ??
                terrainSurfaceMap?.spatialScene ??
                environmentPreview?.spatialScene ??
                reliefStroke?.preview.spatialScene ??
                editingDocument.spatialPreviewMap.spatialScene!,
      groundMap: editingExterior
          ? widget.document.current
          : borderMap ??
                rampMap ??
                terrainSurfaceMap ??
                environmentPreview ??
                reliefStroke?.preview ??
                terrainStroke?.preview ??
                editingDocument.spatialPreviewMap,
      groundProject: widget.project,
      loadGroundImage: (visuals as SpatialWorkspaceVisuals).readGroundImage,
      models: widget.project.models3d,
      loadModel: (visuals as SpatialWorkspaceVisuals).readModel,
      controller: camera,
      onCell: tap,
      onContextMenu: freeView || editingExterior ? null : widget.onContextMenu,
      onDragStart: (x, z, hit) =>
          widget.view.tool == StudioMapTool.place ||
              (widget.view.tool == StudioMapTool.border &&
                  widget.view.borderEditingMode == BorderStrokeEditingMode.draw)
          ? false
          : start(x, z, hit: hit, dragging: true),
      onDragUpdate: updateDrag,
      onDragEnd: finish,
      onDragCancel: cancel,
      onContent: (hit) {
        start(hit.cell.$1, hit.cell.$2, hit: hit);
        finish();
      },
      actorFrames: (_) => preview?.frames ?? const {},
      background: colors.surfaceContainerLowest,
      ground: colors.primaryContainer,
      edge: colors.outlineVariant,
      onReady: _readiness?.ready,
      errorBuilder: (_, failure) {
        _readiness?.fail(failure);
        return Center(child: Text('${error ?? failure}'));
      },
    );
  }
}
