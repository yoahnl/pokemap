part of 'spatial_map_editor.dart';

extension _SpatialMapEditorGuidance on _SpatialMapEditorState {
  String get cameraHelp =>
      'Maj : placement précis · Maj + flèches : tourner la vue · Échap : annuler';

  String? get guidance {
    if (!showsHover) return null;
    final scene = widget.document.current.spatialScene!;
    final hit = hover;
    final cell = hit == null
        ? ''
        : 'case ${hit.cell.$1 + 1}, ${hit.cell.$2 + 1}';
    final pose = placementPreview;
    if (widget.view.tool == StudioMapTool.place) {
      final model = widget.view.model3d;
      if (model == null) return 'Choisissez un décor à placer. $cameraHelp';
      if (pose == null) {
        return '${model.name} · Pointez la carte pour voir le placement. $cameraHelp';
      }
      final position = pose.position;
      return '${model.name} · $cell · X ${position.x.toStringAsFixed(2)}, Z ${position.z.toStringAsFixed(2)} · hauteur ${(position.y / scene.levelHeight).toStringAsFixed(2)} bloc(s) · ${precision ? "Précis" : "Grille"}\nCliquez pour poser. $cameraHelp';
    }
    final erase = widget.view.tool == StudioMapTool.erase;
    if (widget.view.tool == StudioMapTool.collisionPaint ||
        widget.view.tool == StudioMapTool.collisionErase) {
      return 'Collisions ${hit == null ? "· Pointez puis glissez" : "· $cell"} · Maj + flèches : tourner la vue · Échap : annuler';
    }
    final stroke = reliefStroke;
    if (widget.view.spatialTerrainMode == SpatialTerrainMode.relief) {
      final level = erase ? 0 : widget.view.spatialTerrainLevel;
      final from = hit == null
          ? null
          : scene.heightAt(hit.cell.$1, hit.cell.$2);
      final height = from == null ? '$level blocs' : '$from → $level blocs';
      final count = stroke == null ? '' : ' · ${stroke.cells.length} case(s)';
      return '${stroke?.error ?? "Relief · $cell · $height$count"}\nGlissez pour peindre ; relâchez pour valider. Maj + flèches : tourner la vue · Échap : annuler';
    }
    if (widget.view.spatialTerrainMode == SpatialTerrainMode.ramp) {
      if (erase) {
        return 'Pente · $cell · Glissez pour retirer les pentes visées. Maj + flèches : tourner la vue · Échap : annuler';
      }
      if (stroke == null || stroke.end == stroke.origin) {
        return 'Pente · ${hit == null ? "Pointez le départ" : "$cell : départ"} · Glissez du sol bas vers le sol haut.\nLa zone et la hauteur s’affichent pendant le tracé. Maj + flèches : tourner la vue · Échap : annuler';
      }
      final width = (stroke.origin.x - stroke.end.x).abs() + 1;
      final depth = (stroke.origin.y - stroke.end.y).abs() + 1;
      final oldIds = stroke.source.spatialScene!.navigation.ramps
          .map((ramp) => ramp.id)
          .toSet();
      final ramp = stroke.preview.spatialScene!.navigation.ramps
          .where((ramp) => !oldIds.contains(ramp.id))
          .firstOrNull;
      final direction = ramp == null
          ? ''
          : switch (ramp.direction) {
              SpatialRampDirection.north => ' · vers le nord',
              SpatialRampDirection.south => ' · vers le sud',
              SpatialRampDirection.east => ' · vers l’est',
              SpatialRampDirection.west => ' · vers l’ouest',
            };
      final height = ramp == null
          ? ''
          : ' · ${ramp.lowLevel} → ${ramp.highLevel} blocs';
      return '${stroke.error ?? "Pente$direction$height"} · Zone $width × $depth cases\nRelâchez pour valider. Maj + flèches : tourner la vue · Échap : annuler';
    }
    return 'Sol · ${widget.view.terrain?.name ?? "Choisissez un terrain dans la palette"}${hit == null ? "" : " · $cell"}\nGlissez pour ${erase ? "effacer" : "peindre"}. Maj + flèches : tourner la vue · Échap : annuler';
  }

  List<SpatialCellOverlay> previewOverlays(ColorScheme colors) {
    if (!showsHover) return const [];
    final scene = widget.document.current.spatialScene!;
    final stroke = reliefStroke;
    final targets = <(int, int)>{};
    if (stroke != null &&
        stroke.mode == SpatialTerrainMode.ramp &&
        !stroke.erase) {
      for (
        var z = math.min(stroke.origin.y, stroke.end.y);
        z <= math.max(stroke.origin.y, stroke.end.y);
        z++
      ) {
        for (
          var x = math.min(stroke.origin.x, stroke.end.x);
          x <= math.max(stroke.origin.x, stroke.end.x);
          x++
        ) {
          targets.add((x, z));
        }
      }
    } else if (stroke != null) {
      targets.addAll(stroke.cells.map((cell) => (cell.x, cell.y)));
    } else if (hover != null) {
      targets.add(hover!.cell);
    }
    final relief =
        widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
        (widget.view.tool == StudioMapTool.terrain ||
            widget.view.tool == StudioMapTool.erase);
    final targetHeight =
        (widget.view.tool == StudioMapTool.erase
            ? 0
            : widget.view.spatialTerrainLevel) *
        scene.levelHeight;
    return [
      for (final cell in targets)
        if (!relief ||
            hover == null ||
            cell != hover!.cell ||
            hover!.position.y != targetHeight)
          SpatialCellOverlay(
            id: 'brush:${cell.$1}:${cell.$2}',
            cell: cell,
            kind: SpatialCellOverlayKind.preview,
            color: stroke?.error != null
                ? colors.error
                : relief
                ? colors.outline
                : colors.primary,
            targetHeight: relief ? targetHeight : null,
          ),
      if (relief && hover != null)
        SpatialCellOverlay(
          id: 'brush-cursor',
          cell: hover!.cell,
          kind: SpatialCellOverlayKind.preview,
          color: stroke?.error != null ? colors.error : colors.primary,
          targetHeight: hover!.position.y,
        ),
    ];
  }
}
