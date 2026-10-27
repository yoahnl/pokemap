part of 'spatial_scene_view.dart';

bool _sameDecorations(
  List<SpatialSceneDecoration> a,
  List<SpatialSceneDecoration> b,
) =>
    identical(a, b) ||
    a.length == b.length &&
        a.indexed.every((entry) {
          final before = entry.$2, after = b[entry.$1];
          return before.ownerMapId == after.ownerMapId &&
              before.decoration == after.decoration &&
              before.offset == after.offset &&
              identical(before.project, after.project) &&
              before.loadModel == after.loadModel &&
              before.loadGroundImage == after.loadGroundImage;
        });

extension _SpatialDecorationRendering on SpatialSceneGame {
  List<SpatialAuthoredShadowCaster> get allAuthoredShadowCasters =>
      decorationShadowCasters.isEmpty
      ? authoredShadowCasters
      : [...authoredShadowCasters, ...decorationShadowCasters];

  void _enableDecorationShadowReceivers() {
    if (_decorationReceiversEnabled) return;
    for (final chunk in sceneChunks.values) {
      chunk.ground?.receiveShadows = true;
      for (final component in [...chunk.terrain, ...?chunk.ground?.underlays]) {
        if (component is! MeshComponent) continue;
        for (final surface in component.mesh.surfaces) {
          final before = surface.material;
          if (before is SpatialPixelMaterial &&
              before.lightingRole == SpatialPixelLightingRole.ground)
            continue;
          if (before is! UnlitMaterial) continue;
          final next = SpatialPixelMaterial(
            before.albedoTexture,
            lightingRole: SpatialPixelLightingRole.ground,
            preserveUnlitColor:
                before is! SpatialPixelMaterial || before.preserveUnlitColor,
          );
          next.albedoColor = before.albedoColor;
          if (before is SpatialPixelMaterial) {
            next.uvRect.setFrom(before.uvRect);
            next.uvTransformU.setFrom(before.uvTransformU);
            next.uvTransformV.setFrom(before.uvTransformV);
          }
          surface.material = next;
        }
      }
    }
    _decorationReceiversEnabled = true;
  }

  void _pruneDecorationModels(
    Iterable<_MaterializedSceneChunk> materializations,
    SpatialSceneView snapshot,
  ) {
    final retainedAssets = <String>{
      ..._sceneModelAssetIds,
      for (final materialized in materializations)
        ...materialized.sourceAssetIds,
      if (snapshot.placementPreview case final preview?)
        ...snapshot.models
            .where((model) => model.id == preview.modelId)
            .map((model) => model.sourceAssetId),
    };
    cache.removeWhere((id, _) {
      if (retainedAssets.contains(id)) return false;
      modelReservations.remove(id)?.release();
      final model = loadedModelSources.remove(id);
      if (model != null) clippedModelCache.releaseSource(model);
      return true;
    });
  }

  Future<bool> _syncDecorations() async {
    if (!sceneReady || closed || refreshing) return false;
    final wasLoading = _decorationLoading;
    final snapshot = configuration;
    final ticket = ++_decorationGeneration;
    if (configuration.decorations.isEmpty && decorationChunks.isEmpty) {
      _decorationLoading = false;
      _decorationCommittedRevision = ticket;
      if (wasLoading) {
        _pruneDecorationModels(const [], snapshot);
        _pruneGroundTextures();
      }
      return true;
    }
    _decorationLoading = true;
    final sceneTicket = generation;
    bool current() =>
        !closed && ticket == _decorationGeneration && generation == sceneTicket;
    final initialModelKeys = cache.keys.toSet();
    final initialGroundKeys = groundTextureCache.keys.toSet();
    try {
      final projections = projectSpatialDecorations(
        decorations: snapshot.decorations,
        sceneOffset: snapshot.sceneOffset,
        playableBounds: [
          Rect.fromLTWH(
            0,
            0,
            snapshot.scene.width.toDouble(),
            snapshot.scene.depth.toDouble(),
          ),
          for (final neighbor in snapshot.neighbors)
            Rect.fromLTWH(
              neighbor.offset.dx,
              neighbor.offset.dy,
              neighbor.map.size.width.toDouble(),
              neighbor.map.size.height.toDouble(),
            ),
        ],
        previous: _decorationProjections,
        nativeMaps: [
          if (snapshot.groundMap case final map?)
            (map: map, offset: Offset.zero),
          for (final neighbor in snapshot.neighbors)
            (map: neighbor.map, offset: neighbor.offset),
        ],
      );
      final next = <String, _SceneChunk>{};
      final materializations = <String, _MaterializedSceneChunk>{};
      final nextProjections = <String, SpatialDecorationProjection>{};
      final contourDependencies = <String, List<Object?>>{};
      final casters = <SpatialAuthoredShadowCaster>[];
      final lights =
          <({Model3dPointLight definition, _SceneModelComponent component})>[];
      double? heightAt(double worldX, double worldZ) {
        final playable = [
          (snapshot.groundMap, snapshot.sceneOffset),
          for (final neighbor in snapshot.neighbors)
            (neighbor.map, snapshot.sceneOffset + neighbor.offset),
        ];
        for (final (map, offset) in playable) {
          final scene = map?.spatialScene;
          if (scene == null) continue;
          final x = worldX - offset.dx, z = worldZ - offset.dy;
          if (x >= 0 && z >= 0 && x < scene.width && z < scene.depth)
            return scene.worldHeightAt(x, z);
        }
        for (final projection in projections) {
          final x = worldX - projection.offset.dx,
              z = worldZ - projection.offset.dy;
          final scene = projection.map.spatialScene!;
          if (x >= 0 &&
              z >= 0 &&
              x < scene.width &&
              z < scene.depth &&
              !projection.excludedCells.contains((x.floor(), z.floor()))) {
            return scene.worldHeightAt(x, z);
          }
        }
        return null;
      }

      for (final projection in projections) {
        nextProjections[projection.key] = projection;
        final source = projection.source;
        final priorProjection = _decorationProjections[projection.key];
        final priorChunk = decorationChunks[projection.key];
        final canReuseProjection =
            priorProjection != null &&
            priorChunk != null &&
            identical(priorProjection.map, projection.map) &&
            identical(
              priorProjection.cellContextResolvers,
              projection.cellContextResolvers,
            ) &&
            identical(priorProjection.source.project, source.project);
        final map = canReuseProjection
            ? priorChunk.signature.$1!
            : projectedSmartTileMap(
                projection.map,
                source.project,
                cellContextResolvers: projection.cellContextResolvers,
              );
        _smartTileProjectionCache.remove(projection.map);
        final scene = map.spatialScene!;
        final signature = (
          map,
          scene,
          source.project,
          projection.offset,
          snapshot.ground,
          snapshot.edge,
          null,
          true,
        );
        final bounds = Rect.fromLTWH(
          projection.offset.dx,
          projection.offset.dy,
          scene.width.toDouble(),
          scene.depth.toDouble(),
        ).inflate(.001);
        Object terrainSignature(MapSpatialScene target, Offset offset) => (
          offset,
          target.width,
          target.depth,
          target.levelHeight,
          target.generateCliffs,
          target.navigation,
          target.terrainSurfaces,
          Object.hashAll(target.heightLevels),
        );
        final dependencies = <Object?>[
          for (final other in projections)
            if (other.key != projection.key &&
                bounds.overlaps(
                  Rect.fromLTWH(
                    other.offset.dx,
                    other.offset.dy,
                    other.sector.scene.width.toDouble(),
                    other.sector.scene.depth.toDouble(),
                  ),
                ))
              terrainSignature(other.sector.scene, other.offset),
          if (snapshot.groundMap?.spatialScene case final target?)
            terrainSignature(target, snapshot.sceneOffset),
          for (final neighbor in snapshot.neighbors)
            if (neighbor.map.spatialScene case final target?)
              terrainSignature(target, snapshot.sceneOffset + neighbor.offset),
        ];
        contourDependencies[projection.key] = dependencies;
        final previous = decorationChunks[projection.key];
        final oldProjection = _decorationProjections[projection.key];
        final unchanged =
            previous != null &&
            previous.signature == signature &&
            identical(oldProjection?.excludedCells, projection.excludedCells) &&
            oldProjection?.source.loadModel == source.loadModel &&
            oldProjection?.source.loadGroundImage == source.loadGroundImage &&
            projection.dependenciesMatch(oldProjection) &&
            identical(projection.borderGround, oldProjection?.borderGround) &&
            identical(
              projection.cellContextResolvers,
              oldProjection?.cellContextResolvers,
            ) &&
            listEquals(
              dependencies,
              _decorationContourDependencies[projection.key],
            );
        if (unchanged) {
          next[projection.key] = previous;
          final retained = _decorationMaterializations[projection.key]!;
          materializations[projection.key] = retained;
          casters.addAll(retained.casters);
          lights.addAll(retained.lights);
          continue;
        }
        final placement = (
          scene: scene,
          map: map,
          offset: projection.offset,
          loader: source.loadGroundImage,
          modelLoader: source.loadModel,
          project: source.project,
          definitions: {
            for (final model in source.project.models3d) model.id: model,
          },
          active: false,
        );
        final previousModels = _decorationMaterializations[projection.key];
        final reuseModels =
            previous != null &&
            previousModels != null &&
            previous.signature.$2 == scene &&
            previous.signature.$4 == projection.offset &&
            oldProjection != null &&
            oldProjection.source.loadModel == source.loadModel &&
            oldProjection.source.loadGroundImage == source.loadGroundImage &&
            identical(oldProjection.excludedCells, projection.excludedCells) &&
            projection.dependenciesMatch(oldProjection) &&
            scene.instances.every((instance) {
              final definition = placement.definitions[instance.modelId];
              final before = previous.models[instance.id]?.component;
              return definition != null &&
                  before != null &&
                  before.definition == definition &&
                  oldProjection.allowsModel(instance, definition) ==
                      projection.allowsModel(instance, definition);
            });
        final built = await materializePlacement(
          placement: placement,
          snapshot: snapshot,
          map: map,
          scene: scene,
          signature: signature,
          cellOrigins: const {},
          receiveShadows: true,
          ticket: sceneTicket,
          decoration: projection,
          reuseModels: reuseModels ? previousModels : null,
          stillCurrent: current,
          adjacentHeightAt: (x, z) =>
              heightAt(x + projection.offset.dx, z + projection.offset.dy),
        );
        if (built == null || !current()) return false;
        next[projection.key] = built.chunk;
        materializations[projection.key] = built;
        casters.addAll(built.casters);
        lights.addAll(built.lights);
        decorationSectorBuilds++;
      }
      if (!current()) return false;
      return await decorationSceneComponents.replaceGroups(
        {
          for (final entry in next.entries) ...{
            entry.key: entry.value.components.where(
              (component) => component is! _SceneModelComponent,
            ),
            (entry.key, #models): entry.value.models.values.map(
              (model) => model.component,
            ),
          },
        },
        isCurrent: current,
        onCommit: () {
          final oldGrounds = {
            for (final chunk in decorationChunks.values)
              if (chunk.ground case final ground?) ground,
          };
          grounds = [
            for (final ground in grounds)
              if (!oldGrounds.contains(ground)) ground,
            for (final chunk in next.values)
              if (chunk.ground case final ground?) ground,
          ];
          decorationChunks = next;
          _decorationMaterializations = materializations;
          _decorationContourDependencies = contourDependencies;
          decorationReceiverMinY = projections.isEmpty
              ? 0
              : projections
                    .map(
                      (projection) => spatialShadowReceiverMinimumHeight(
                        projection.sector.scene,
                      ),
                    )
                    .reduce(math.min);
          decorationReceiverMaxY = projections.isEmpty
              ? 0
              : projections
                    .map(
                      (projection) =>
                          projection.sector.scene.maximumWorldHeight,
                    )
                    .reduce(math.max);
          _decorationProjections = nextProjections;
          decorationAnimationModels = {
            for (final chunk in next.entries)
              for (final model in chunk.value.models.entries)
                (chunk.key, model.key): model.value.component,
          };
          decorationShadowCasters = List.unmodifiable(casters);
          if (casters.isNotEmpty) _enableDecorationShadowReceivers();
          decorationPointLights = lights;
          _pruneDecorationModels(materializations.values, snapshot);
          for (final frames in modelSelections.values) {
            for (final frame in frames) {
              frame.removeFromParent();
            }
          }
          modelSelections.clear();
          syncContentSelection(null, snapshot);
          syncContentPreview();
          final allCasters = allAuthoredShadowCasters;
          authoredLighting = spatialAuthoredShadowLighting(
            allCasters,
            receiverMinY: allReceiverMinY,
            receiverMaxY: allReceiverMaxY,
          );
          final lighting = authoredLighting;
          (context as SpatialRenderContext).shadowCasters =
              [...animationModels.values, ...decorationAnimationModels.values]
                  .where(
                    (component) =>
                        lighting.shadow?.casterInstanceIds.contains(
                          component.shadowId,
                        ) ==
                        true,
                  )
                  .toList();
          _refreshVisibilityLighting();
          syncLighting();
          syncCamera();
          _pruneGroundTextures();
          decorationUpdates++;
          _decorationCommittedRevision = ticket;
          _decorationLoading = false;
        },
      );
    } on Object {
      if (current()) {
        cache.removeWhere((key, _) {
          if (initialModelKeys.contains(key)) return false;
          modelReservations.remove(key)?.release();
          final model = loadedModelSources.remove(key);
          if (model != null) clippedModelCache.releaseSource(model);
          return true;
        });
        groundTextureCache.removeWhere((key, _) {
          if (initialGroundKeys.contains(key)) return false;
          groundReservations.remove(key)?.release();
          _groundTextures.remove(key);
          _groundTextureTokens.remove(key);
          return true;
        });
      }
      rethrow;
    } finally {
      if (ticket == _decorationGeneration) _decorationLoading = false;
    }
  }
}
