part of 'spatial_scene_decoration.dart';

final class _LogicalBorderSource {
  _LogicalBorderSource(this.border, this.project, this.ground, this.context);
  final ExteriorDecorationBorder border;
  final ProjectManifest project;
  final SpatialGroundBorderInputs ground;
  final SpatialBorderResolutionContext context;
  final Map<double, List<ExteriorDecorationSector>> _renderSectors = {};
  List<ExteriorDecorationSector> renderSectorsFor(
    double levelHeight,
  ) => _renderSectors.putIfAbsent(levelHeight, () {
    final sectors = <ExteriorDecorationSector>[];
    final groups = <(int, int), List<SpatialModelInstance>>{};
    for (final instance in border.instances) {
      final support = instance.supportPosition;
      groups
          .putIfAbsent((
            support.x.floor() ~/ 32,
            support.z.floor() ~/ 32,
          ), () => [])
          .add(instance);
    }
    for (final surface in ground.surfaces) {
      for (final footprint in surface.footprints) {
        final left = footprint.points
            .map((point) => point.x)
            .reduce(math.min)
            .floor()
            .clamp(0, border.width - 1);
        final right =
            (footprint.points.map((point) => point.x).reduce(math.max).ceil() -
                    1)
                .clamp(0, border.width - 1);
        final top = footprint.points
            .map((point) => point.z)
            .reduce(math.min)
            .floor()
            .clamp(0, border.depth - 1);
        final bottom =
            (footprint.points.map((point) => point.z).reduce(math.max).ceil() -
                    1)
                .clamp(0, border.depth - 1);
        for (var z = top ~/ 32; z <= bottom ~/ 32; z++) {
          for (var x = left ~/ 32; x <= right ~/ 32; x++) {
            groups.putIfAbsent((x, z), () => []);
          }
        }
      }
    }
    for (final group in groups.entries) {
      final left = group.key.$1 * 32, top = group.key.$2 * 32;
      final width = math.min(32, border.width - left),
          depth = math.min(32, border.depth - top);
      final id =
          'logical_border_${narrativeEventCanonicalSha256([border.layerId, border.id, left, top]).substring(0, 32)}';
      final sector = ExteriorDecorationSector(
        id: id,
        originX: border.originX + left,
        originZ: border.originZ + top,
        scene: MapSpatialScene(
          width: width,
          depth: depth,
          generateCliffs: false,
          levelHeight: levelHeight,
          instances: [
            for (final instance in group.value)
              instance.copyWith(
                position: Model3dVector3(
                  x: instance.position.x - left,
                  y: instance.position.y,
                  z: instance.position.z - top,
                ),
              ),
          ],
        ),
      );
      sectors.add(sector);
    }
    return List.unmodifiable(sectors);
  });
  Offset? _acceptedOffset;
  List<Rect>? _acceptedBlocked;
  Set<String> _accepted = const {};
  Set<String>? _filteredFor;
  SpatialGroundBorderInputs? _filteredGround;

  Set<String> acceptedAt(Offset offset, List<Rect> blocked) {
    if (_acceptedOffset == offset && listEquals(_acceptedBlocked, blocked))
      return _accepted;
    final models = {for (final model in project.models3d) model.id: model};
    _acceptedOffset = offset;
    _acceptedBlocked = blocked;
    return _accepted = Set.unmodifiable(
      border.instances
          .where((instance) {
            final model = models[instance.modelId];
            if (model == null)
              throw StateError('Modèle absent : ${instance.modelId}');
            final footprint = spatialDecorationModelFootprint(
              instance,
              model,
              offset,
            );
            return !blocked.any((bounds) => bounds.overlaps(footprint));
          })
          .map((instance) => instance.id),
    );
  }

  SpatialGroundBorderInputs groundAt(Offset offset, List<Rect> blocked) {
    final accepted = acceptedAt(offset, blocked);
    if (accepted.length == border.instances.length) return ground;
    if (identical(accepted, _filteredFor)) return _filteredGround!;
    _filteredFor = accepted;
    return _filteredGround = SpatialGroundBorderInputs(
      masks: resolveSpatialBorderGroundMaskCellsByLayerInContext(
        manifest: project,
        context: context,
        includeInstance: accepted.contains,
      ),
      replacements: resolveSpatialBorderGroundReplacementsByLayerInContext(
        manifest: project,
        context: context,
        includeInstance: accepted.contains,
      ),
      surfaces: resolveSpatialBorderGroundSurfacesInContext(
        manifest: project,
        context: context,
        includeInstance: accepted.contains,
      ),
    );
  }

  Offset? _claimedOffset;
  List<Rect>? _claimedBlocked;
  List<Rect> _claimed = const [];
  List<Rect> claimsAt(Offset offset, List<Rect> blocked) {
    if (_claimedOffset == offset && listEquals(_claimedBlocked, blocked))
      return _claimed;
    final models = {for (final model in project.models3d) model.id: model};
    final claimed = <Rect>[];
    for (final instance in border.instances) {
      final model = models[instance.modelId];
      if (model == null)
        throw StateError('Modèle absent : ${instance.modelId}');
      final footprint = spatialDecorationModelFootprint(
        instance,
        model,
        offset,
      );
      if (!blocked.any((bounds) => bounds.overlaps(footprint)))
        claimed.add(footprint);
    }
    for (final surface in groundAt(offset, blocked).surfaces) {
      for (final footprint in surface.footprints) {
        claimed.add(
          Rect.fromLTRB(
            footprint.points.map((point) => point.x).reduce(math.min) +
                offset.dx,
            footprint.points.map((point) => point.z).reduce(math.min) +
                offset.dy,
            footprint.points.map((point) => point.x).reduce(math.max) +
                offset.dx,
            footprint.points.map((point) => point.z).reduce(math.max) +
                offset.dy,
          ),
        );
      }
    }
    _claimedOffset = offset;
    _claimedBlocked = blocked;
    return _claimed = List.unmodifiable(claimed);
  }
}

void _projectLogicalDecorationBorders(
  SpatialSceneDecoration source,
  Offset ownerOffset,
  List<Rect> blocked,
  List<SpatialDecorationProjection> results,
  Map<String, SpatialDecorationProjection> previous,
  List<({MapData map, Offset offset})> nativeMaps,
  List<Rect> claimed,
) {
  if (source.decoration.borders.isEmpty) return;
  final ownerMap = nativeMaps
      .where((entry) => entry.map.id == source.ownerMapId)
      .firstOrNull
      ?.map;
  if (ownerMap == null)
    throw StateError(
      'La carte propriétaire de la bordure extérieure est indisponible.',
    );
  final cached = <String, _LogicalBorderSource>{
    for (final projection in previous.values)
      if (projection.source.ownerMapId == source.ownerMapId)
        for (final border in projection._logicalBorders)
          '${border.border.layerId}:${border.border.id}': border,
  };
  final logical = <_LogicalBorderSource>[];
  for (final border in source.decoration.borders) {
    final retained = cached['${border.layerId}:${border.id}'];
    if (retained != null &&
        retained.border == border &&
        identical(retained.project, source.project)) {
      logical.add(retained);
      continue;
    }
    final context = createExteriorDecorationBorderContext(
      decoration: source.decoration,
      border: border,
      playableMap: ownerMap,
    );
    logical.add(
      _LogicalBorderSource(
        border,
        source.project,
        SpatialGroundBorderInputs(
          masks: resolveSpatialBorderGroundMaskCellsByLayerInContext(
            manifest: source.project,
            context: context,
          ),
          replacements: resolveSpatialBorderGroundReplacementsByLayerInContext(
            manifest: source.project,
            context: context,
          ),
          surfaces: resolveSpatialBorderGroundSurfacesInContext(
            manifest: source.project,
            context: context,
          ),
        ),
        context,
      ),
    );
  }
  final regular = results
      .where((projection) => projection.source.ownerMapId == source.ownerMapId)
      .toList();
  final regularBounds = [
    for (final projection in regular)
      Rect.fromLTWH(
        projection.offset.dx,
        projection.offset.dy,
        projection.sector.scene.width.toDouble(),
        projection.sector.scene.depth.toDouble(),
      ),
  ];
  final synthetic = <String, SpatialDecorationProjection>{};
  for (final item in logical) {
    for (final sector in item.renderSectorsFor(
      ownerMap.spatialScene!.levelHeight,
    )) {
      final id = sector.id;
      final width = sector.scene.width, depth = sector.scene.depth;
      final offset =
          ownerOffset +
          Offset(sector.originX.toDouble(), sector.originZ.toDouble());
      final key = 'exterior:${source.ownerMapId}:$id';
      final prior = previous[key];
      final groundOcclusions = [...blocked, ...regularBounds];
      final reusable =
          prior != null &&
          prior.offset == offset &&
          listEquals(prior._groundOcclusions, groundOcclusions);
      final excluded = <(int, int)>{};
      for (var z = 0; !reusable && z < depth; z++) {
        for (var x = 0; x < width; x++) {
          final cell = Rect.fromLTWH(offset.dx + x, offset.dy + z, 1, 1);
          if (groundOcclusions.any((bounds) => bounds.overlaps(cell)))
            excluded.add((x, z));
        }
      }
      final projection =
          SpatialDecorationProjection(
              source: source,
              sector: sector,
              offset: offset,
              excludedCells: reusable
                  ? prior.excludedCells
                  : Set.unmodifiable(excluded),
              blockedBounds: blocked,
              cachedMap: prior?.sector == sector ? prior?.map : null,
            )
            ..renderTerrainBase = false
            .._groundOcclusions = groundOcclusions;
      synthetic[key] = projection;
    }
  }
  final all = [...regular, ...synthetic.values];
  for (final projection in all) {
    final scope = Rect.fromLTWH(
      projection.sector.originX.toDouble(),
      projection.sector.originZ.toDouble(),
      projection.sector.scene.width.toDouble(),
      projection.sector.scene.depth.toDouble(),
    );
    final relevant = logical
        .where(
          (item) => scope.overlaps(
            Rect.fromLTWH(
              item.border.originX.toDouble(),
              item.border.originZ.toDouble(),
              item.border.width.toDouble(),
              item.border.depth.toDouble(),
            ),
          ),
        )
        .toList();
    projection._logicalBorders = relevant;
    final groundInputs = [
      for (final item in relevant)
        item.groundAt(
          ownerOffset +
              Offset(
                item.border.originX.toDouble(),
                item.border.originZ.toDouble(),
              ),
          blocked,
        ),
    ];
    projection._logicalBorderInputs = groundInputs;
    final prior = previous[projection.key];
    if (prior != null &&
        listEquals(prior._logicalBorders, relevant) &&
        listEquals(prior._logicalBorderInputs, groundInputs)) {
      projection.borderGround = prior.borderGround;
      continue;
    }
    final masks = <String, Set<(int, int)>>{};
    final replacements = <String, List<SpatialBorderGroundReplacement>>{};
    final surfaces = <SpatialBorderGroundSurface>[];
    for (final (index, item) in relevant.indexed) {
      final ground = groundInputs[index];
      final dx = item.border.originX - projection.sector.originX,
          dz = item.border.originZ - projection.sector.originZ;
      for (final entry in ground.masks.entries) {
        masks
            .putIfAbsent(entry.key, () => {})
            .addAll(entry.value.map((cell) => (cell.$1 + dx, cell.$2 + dz)));
      }
      BorderGroundFootprint shift(BorderGroundFootprint footprint) =>
          BorderGroundFootprint(
            points: [
              for (final point in footprint.points)
                BorderGroundPoint(x: point.x + dx, z: point.z + dz),
            ],
          );
      for (final entry in ground.replacements.entries) {
        replacements
            .putIfAbsent(entry.key, () => [])
            .addAll(
              entry.value.map(
                (replacement) => SpatialBorderGroundReplacement(
                  left: replacement.left + dx,
                  top: replacement.top + dz,
                  right: replacement.right + dx,
                  bottom: replacement.bottom + dz,
                  lowerHeight: replacement.lowerHeight,
                  upperHeight: replacement.upperHeight,
                  footprints: replacement.footprints.map(shift).toList(),
                ),
              ),
            );
      }
      surfaces.addAll(
        ground.surfaces.map(
          (surface) => SpatialBorderGroundSurface(
            layerId: surface.layerId,
            sourceSmartTilePresetId: surface.sourceSmartTilePresetId,
            materialId: surface.materialId,
            height:
                surface.height -
                surface.gradientX * dx -
                surface.gradientZ * dz,
            gradientX: surface.gradientX,
            gradientZ: surface.gradientZ,
            opacity: surface.opacity,
            footprints: surface.footprints.map(shift).toList(),
          ),
        ),
      );
    }
    projection.borderGround = SpatialGroundBorderInputs(
      masks: masks,
      replacements: replacements,
      surfaces: surfaces,
    );
  }
  for (final item in logical) {
    final offset =
        ownerOffset +
        Offset(item.border.originX.toDouble(), item.border.originZ.toDouble());
    claimed.addAll(item.claimsAt(offset, blocked));
  }
  results.addAll(synthetic.values);
}
