part of 'spatial_scene_view.dart';

typedef _ScenePlacement = ({
  MapSpatialScene scene,
  MapData? map,
  Offset offset,
  Future<Uint8List> Function(String)? loader,
  Future<Uint8List> Function(String) modelLoader,
  ProjectManifest? project,
  Map<String, ProjectModel3dEntry> definitions,
  bool active,
});

typedef _MaterializedSceneChunk = ({
  _SceneChunk chunk,
  List<SpatialAuthoredShadowCaster> casters,
  Set<String> sourceAssetIds,
  List<({Model3dPointLight definition, _SceneModelComponent component})> lights,
});

extension _SpatialSceneMaterialization on SpatialSceneGame {
  Future<_MaterializedSceneChunk?> materializePlacement({
    required _ScenePlacement placement,
    required SpatialSceneView snapshot,
    required MapData? map,
    required MapSpatialScene scene,
    required _SceneChunkSignature signature,
    required Map<String, ({String layerId, GridPos cell})> cellOrigins,
    required bool receiveShadows,
    required int ticket,
    SpatialDecorationProjection? decoration,
    SpatialPreparedScenePlans? preparedPlans,
    _MaterializedSceneChunk? reuseModels,
    double? Function(double, double)? adjacentHeightAt,
    bool Function()? stillCurrent,
  }) async {
    bool current() =>
        ticket == generation && !closed && (stillCurrent?.call() ?? true);
    final project = placement.project;
    final sourceInstances = scene.instances;
    final placementDefinitions = placement.definitions;
    final loader = placement.loader;
    final plans = decoration == null ? preparedPlans : null;
    final mapId = map?.id ?? '__scene__';
    final casters = <SpatialAuthoredShadowCaster>[];
    final lights =
        <({Model3dPointLight definition, _SceneModelComponent component})>[];
    if (decoration != null) {
      scene = scene.copyWith(
        instances: scene.instances.where((instance) {
          final definition = placementDefinitions[instance.modelId];
          if (definition == null)
            throw StateError('Modèle absent : ${instance.modelId}');
          return decoration.allowsModel(instance, definition);
        }),
      );
      map = map?.copyWith(spatialScene: scene);
    }
    final components = <Object3D>[];
    final placedModels = <String, _ScenePlacedModel>{};
    final terrainComponents = <Object3D>[];
    _SceneGround? sceneGround;
    SpatialGroundPlan? groundPlan;
    final textures = <String, Texture>{};
    if (map != null &&
        (map.layers.isNotEmpty ||
            map.spatialScene?.cliffFrame != null ||
            decoration?.borderGround.isEmpty == false)) {
      if (project == null || loader == null) {
        throw StateError('Les ressources du sol 3D sont indisponibles.');
      }
      final plan =
          plans?.ground ??
          SpatialGroundPlan(
            map,
            project,
            excludedCells: decoration?.excludedCells ?? const {},
            cellContextResolvers: decoration?.cellContextResolvers ?? const {},
            additionalBorders:
                decoration?.borderGround ?? const SpatialGroundBorderInputs(),
          );
      groundPlan = plan;
      final elapsed = (groundElapsed * 1000).round();
      final ground = _SceneGround(
        plan,
        _groundTextures,
        placement.offset,
        mapId: mapId,
        project: project,
        loader: loader,
        animationElapsedMsForCell: decoration == null
            ? snapshot.rasterAnimationElapsedMsForCell
            : null,
        occlusionStateForCell: decoration == null
            ? snapshot.actorOcclusionStateForCell
            : null,
        presentationElapsedSeconds: snapshot.presentationElapsedSeconds,
        ground: snapshot.ground,
        edge: snapshot.edge,
        selectedCell: placement.active ? snapshot.selectedCell : null,
        receiveShadows: receiveShadows,
        renderTerrainBase: decoration?.renderTerrainBase != false,
        occlusionPlan:
            plans?.occlusion ??
            SpatialActorOcclusionPlan(
              map,
              project,
              cellContextResolvers: decoration?.cellContextResolvers ?? const {},
              includeVisual: decoration?.allowsRasterVisual,
            ),
      );
      ground.sampleTextureWindow(elapsed);
      final requiredImages = ground.currentImageIds;
      final nextImages = ground.nextImageIds;
      _wantedGroundImages.addAll({...requiredImages, ...nextImages});
      for (final id in requiredImages) {
        textures[id] = await _loadGroundTexture(
          id,
          loader,
          project,
          ticket: ticket,
        );
        if (!current()) return null;
      }
      for (final id in nextImages.difference(requiredImages)) {
        final pending = _loadGroundTexture(
          id,
          loader,
          project,
          ticket: ticket,
          prefetch: true,
        );
        unawaited(
          pending.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
        );
      }
      sceneGround = ground;
      ground.resolve(
        (groundElapsed * 1000).round(),
        animationElapsedMsForCell: decoration == null
            ? snapshot.rasterAnimationElapsedMsForCell
            : null,
      );
      components.addAll(ground.components);
    }
    for (final mesh in terrainMeshes(
      scene,
      snapshot.ground,
      snapshot.edge,
      selectedCell: placement.active ? snapshot.selectedCell : null,
      includeGround:
          groundPlan == null && decoration?.renderTerrainBase != false,
      includeCliffs: decoration?.renderTerrainBase != false,
      receiveShadows: receiveShadows,
      replacedGroundCells: groundPlan?.groundReplacementCells ?? const {},
      borderGroundReplacements:
          groundPlan?.borderGroundReplacements ?? const {},
      bridgeCells: groundPlan?.bridgeCells ?? const {},
      excludedCells: decoration?.excludedCells ?? const {},
      adjacentHeightAt: adjacentHeightAt,
      cliffTexture: groundPlan?.cliff == null
          ? null
          : (
              texture: textures[groundPlan!.cliff!.tilesetId]!,
              sourceRect: groundPlan.cliff!.sourceRect,
            ),
    )) {
      final component = MeshComponent(
        mesh: mesh,
        position: Vector3(placement.offset.dx, 0, placement.offset.dy),
      );
      terrainComponents.add(component);
      components.add(component);
    }
    if (reuseModels != null) {
      components.addAll(
        reuseModels.chunk.models.values.map((model) => model.component),
      );
      return (
        chunk: _SceneChunk(
          signature: signature,
          components: components,
          ground: sceneGround,
          models: reuseModels.chunk.models,
          terrain: terrainComponents,
          cellOrigins: cellOrigins,
        ),
        casters: reuseModels.casters,
        sourceAssetIds: reuseModels.sourceAssetIds,
        lights: reuseModels.lights,
      );
    }
    final modelSources = <String, Future<Uint8List> Function()>{};
    for (final instance in scene.instances) {
      final definition = placementDefinitions[instance.modelId];
      if (definition == null) {
        throw StateError('Modèle absent : ${instance.modelId}');
      }
      modelSources.putIfAbsent(
        definition.sourceAssetId,
        () =>
            () => placement.modelLoader(definition.id),
      );
    }
    final modelsReady = await ModelByteLoader.preloadCached(
      cache,
      modelSources,
      isCurrent: current,
      budget: resourceBudget,
      onResident: retainModelReservation,
    );
    if (!modelsReady || !current()) return null;
    for (final instance in sourceInstances) {
      final definition = placementDefinitions[instance.modelId]!;
      final allowed = decoration?.allowsModel(instance, definition) ?? true;
      final sourceModel = !allowed ? Model(nodes: const {}, animations: const []) : await ModelByteLoader.loadCached(
        cache,
        definition.sourceAssetId,
        () => placement.modelLoader(definition.id),
        budget: resourceBudget,
        isCurrent: current,
        onResident: retainModelReservation,
      );
      if (!current()) return null;
      if (allowed) loadedModelSources[definition.sourceAssetId] = sourceModel;
      final sourceClip = spatialModelSourceClip(instance, definition);
      final clipped = sourceClip == null || !allowed
          ? null
          : clippedModelCache.resolve(sourceModel, sourceClip);
      final sourceVisible = allowed && (sourceClip == null || clipped != null);
      final model = clipped?.model ?? sourceModel;
      final visibleBounds = clipped?.bounds ?? definition.inspection.bounds;
      final scale = definition.scale * instance.scale;
      final rotation = Quaternion.axisAngle(
        Vector3(0, 1, 0),
        instance.rotationDegrees * math.pi / 180,
      );
      final pivot =
          Vector3(definition.pivot.x, definition.pivot.y, definition.pivot.z) *
          scale;
      rotation.asRotationMatrix().transform(pivot);
      final animationKey = (placement.map?.id ?? '__scene__', instance.id);
      final previous =
          animationModels[animationKey] ??
          decorationAnimationModels[animationKey];
      final component = _SceneModelComponent(
        instanceId: instance.id,
        initialAnchorY: instance.position.y,
        shadowId: spatialShadowInstanceId(mapId, instance.id),
        model: model,
        visibleBounds: visibleBounds,
        definition: definition,
        playback: identical(previous?.model, model)
            ? ModelPlaybackState.from(previous!.playback)
            : null,
        runtimePoseBefore: identical(previous?.model, model)
            ? previous?.runtimePoseBefore
            : null,
        position:
            Vector3(
              instance.position.x + placement.offset.dx,
              instance.position.y,
              instance.position.z + placement.offset.dy,
            ) -
            pivot,
        rotation: rotation,
        scale: Vector3.all(scale),
      );
      component.sourceGeometryVisible = sourceVisible;
      final caster = !sourceVisible ? null : spatialAuthoredShadowCaster(
        mapId: mapId,
        instance: instance,
        definition: definition,
        bounds: visibleBounds,
        worldTransform: component.worldTransformMatrix,
      );
      if (caster != null) casters.add(caster);
      if (sourceVisible && definition.light != null) {
        final light = definition.light!;
        lights.add((definition: light, component: component));
      }
      component.bindAnimation(
        allowed ? instance.animationIndex : null,
        loop: instance.animationLoop,
        speed: instance.animationSpeed,
      );
      components.add(component);
      placedModels[instance.id] = (
        component: component,
        position: component.position.clone(),
        anchor: instance.position,
      );
    }
    return (
      chunk: _SceneChunk(
        signature: signature,
        components: components,
        ground: sceneGround,
        models: placedModels,
        terrain: terrainComponents,
        cellOrigins: cellOrigins,
      ),
      casters: casters,
      sourceAssetIds: Set.unmodifiable(sourceInstances.map((instance) => placementDefinitions[instance.modelId]!.sourceAssetId)),
      lights: lights,
    );
  }
}
