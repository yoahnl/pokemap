part of 'spatial_map_editing_viewport.dart';

extension _SpatialCellOverlays on _SpatialMapEditingViewportState {
  List<SpatialCellOverlay> cellOverlays(ColorScheme colors) {
    final map =
        environmentPreview ??
        reliefStroke?.preview ??
        terrainStroke?.preview ??
        editingDocument.current;
    final destination = contentGestureValid ? gesture?.destination : null;
    final cells = <SpatialCellOverlay>[];
    cells.addAll(previewOverlays(colors));
    cells.addAll(environmentOverlays(colors));
    cells.addAll(borderOverlays(colors));
    cells.addAll(terrainSurfaceSelectionOverlays(colors));
    final drawing = gesture;
    if (drawing?.zone == true &&
        widget.view.tool == StudioMapTool.gameplayZone &&
        identical(drawing!.source, map)) {
      final area = drawing.rectangle;
      for (var z = area.pos.y; z < area.pos.y + area.size.height; z++) {
        for (var x = area.pos.x; x < area.pos.x + area.size.width; x++) {
          cells.add(
            SpatialCellOverlay(
              id: 'field-zone-draft:$x:$z',
              cell: (x, z),
              kind: SpatialCellOverlayKind.preview,
              color: colors.secondary,
            ),
          );
        }
      }
    }
    final selectedZone = widget.view.selectedFor(
      map.id,
      MapSelectionFamily.zone,
    );
    for (final zone in map.gameplayZones) {
      if (zone.kind == GameplayZoneKind.fieldAction ||
          editingDocument.isElementHidden('zone', zone.id) ||
          zone.id != selectedZone &&
              !widget.view.revealedZones.contains(zone.kind)) {
        continue;
      }
      final origin = zone.area.pos;
      final covered = switch (zone.cellMask) {
        final mask? => [
          for (final cell in mask) (origin.x + cell.x, origin.y + cell.y),
        ],
        null => [
          for (var z = origin.y; z < origin.y + zone.area.size.height; z++)
            for (var x = origin.x; x < origin.x + zone.area.size.width; x++)
              (x, z),
        ],
      };
      for (final (x, z) in covered) {
        cells.add(
          SpatialCellOverlay(
            id: 'zone:${zone.id}:$x:$z',
            cell: (x, z),
            kind: SpatialCellOverlayKind.preview,
            color: zone.id == selectedZone ? colors.primary : colors.secondary,
          ),
        );
      }
    }
    for (final zone in map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.fieldAction ||
          editingDocument.isElementHidden('zone', zone.id)) {
        continue;
      }
      final waterfall = zone.fieldAction?.waterfall,
          whirlpool = zone.fieldAction?.whirlpool;
      if (waterfall == null && whirlpool == null) continue;
      final route = [
        waterfall?.entry ?? whirlpool!.entry,
        ...?waterfall?.path,
        ...?whirlpool?.path,
        waterfall?.exit ?? whirlpool!.exit,
      ];
      final origin = drawing?.armed?.id == zone.id
          ? drawing?.armedArea?.pos ?? zone.area.pos
          : zone.area.pos;
      for (var index = 0; index < route.length; index++) {
        cells.add(
          SpatialCellOverlay(
            id: 'field-route:${zone.id}:$index',
            cell: (origin.x + route[index].x, origin.y + route[index].y),
            kind: SpatialCellOverlayKind.preview,
            color: index == 0
                ? colors.secondary
                : index == route.length - 1
                ? colors.tertiary
                : colors.primary,
          ),
        );
      }
    }

    for (final layer in map.layers.whereType<CollisionLayer>()) {
      for (var index = 0; index < layer.collisions.length; index++) {
        if (layer.collisions[index]) {
          cells.add(
            SpatialCellOverlay(
              id: '${layer.id}:$index',
              cell: (index % map.size.width, index ~/ map.size.width),
              kind: SpatialCellOverlayKind.collision,
              color: colors.error,
            ),
          );
        }
      }
    }
    for (final entity in map.entities.where(
      (entity) => entity.kind == MapEntityKind.spawn,
    )) {
      final position = gesture?.entity?.id == entity.id
          ? destination ?? entity.pos
          : entity.pos;
      cells.add(
        SpatialCellOverlay(
          id: entity.id,
          cell: (position.x, position.y),
          kind: SpatialCellOverlayKind.spawn,
          color:
              widget.view.selectedFor(map.id, MapSelectionFamily.marker) ==
                  entity.id
              ? colors.primary
              : colors.secondary,
        ),
      );
    }
    for (final warp in map.warps) {
      final origin = gesture?.warp?.id == warp.id
          ? destination ?? warp.pos
          : warp.pos;
      cells.add(
        SpatialCellOverlay(
          id: warp.id,
          cell: (origin.x, origin.y),
          kind: SpatialCellOverlayKind.warp,
          color:
              widget.view.selectedFor(map.id, MapSelectionFamily.warp) ==
                  warp.id
              ? colors.primary
              : colors.tertiary,
        ),
      );
    }
    return cells;
  }
}
