part of 'spatial_scene_view.dart';

final class SpatialModelSourceUpdates extends ChangeNotifier {
  final _revisions = <String, String>{};
  final _definitions = <String, ProjectModel3dEntry>{};
  Map<String, String> _batch = const {};
  Map<String, ProjectModel3dEntry> _definitionBatch = const {};

  String? revision(String sourceAssetId) => _revisions[sourceAssetId];
  ProjectModel3dEntry? definition(String modelId) => _definitions[modelId];

  void publish({
    required Map<String, String> revisions,
    Map<String, ProjectModel3dEntry> definitions = const {},
  }) {
    _batch = Map.unmodifiable(revisions);
    _definitionBatch = Map.unmodifiable(definitions);
    _revisions.addAll(revisions);
    _definitions.addAll(definitions);
    notifyListeners();
  }
}

final class _ModelSourceDependent {
  _ModelSourceDependent({
    required this.chunk,
    required this.mapId,
    required this.instance,
    required this.decoration,
    required this.sourceIndex,
  });
  final _SceneChunk chunk;
  final String mapId;
  SpatialModelInstance instance;
  final bool decoration;
  final int sourceIndex;
}

bool _sameProjectOutsideModels(
  ProjectManifest? before,
  ProjectManifest? after,
) =>
    identical(before, after) ||
    before != null &&
        after != null &&
        before.copyWith(models3d: const []) ==
            after.copyWith(models3d: const []);

extension _SpatialSceneModelSources on SpatialSceneGame {
  bool _syncLightDefinitions(SpatialSceneView before) {
    final after = configuration;
    if (!sceneReady ||
        refreshing ||
        before.resourceIdentity != after.resourceIdentity ||
        !identical(before.resourceBudget, after.resourceBudget) ||
        !identical(before.controller, after.controller) ||
        !identical(before.scene, after.scene) ||
        !identical(before.groundMap, after.groundMap) ||
        before.sceneOffset != after.sceneOffset ||
        before.ground != after.ground ||
        before.edge != after.edge ||
        before.selectedCell != after.selectedCell ||
        before.visibility != after.visibility ||
        before.selectedContent != after.selectedContent ||
        before.authoringTarget != after.authoringTarget ||
        before.selectionColor != after.selectionColor ||
        !listEquals(before.cellOverlays, after.cellOverlays) ||
        before.neighbors.length != after.neighbors.length ||
        before.decorations.length != after.decorations.length ||
        !mapEquals(before.modelSourceRevisions, after.modelSourceRevisions) ||
        !identical(before.modelSourceUpdates, after.modelSourceUpdates) ||
        _modelSourceRevisionPending ||
        !identical(before.contentPreview, after.contentPreview) ||
        !identical(before.placementPreview, after.placementPreview) ||
        !_sameProjectOutsideModels(before.groundProject, after.groundProject))
      return false;
    final previous = before.models, next = after.models;
    if (previous is! ProjectModel3dEntries || next is! ProjectModel3dEntries)
      return false;
    final changes = next.changesSince(previous);
    if (changes == null || changes.isEmpty) return false;
    bool projectMatches(ProjectManifest? old, ProjectManifest? updated) =>
        identical(old, updated) ||
        identical(old, before.groundProject) &&
            identical(updated, after.groundProject);
    for (final (index, neighbor) in before.neighbors.indexed) {
      final updated = after.neighbors[index];
      if (!identical(neighbor.map, updated.map) ||
          neighbor.offset != updated.offset ||
          !projectMatches(neighbor.project, updated.project))
        return false;
    }
    for (final (index, decoration) in before.decorations.indexed) {
      final updated = after.decorations[index];
      if (decoration.decoration != updated.decoration ||
          decoration.ownerMapId != updated.ownerMapId ||
          decoration.offset != updated.offset ||
          !projectMatches(decoration.project, updated.project))
        return false;
    }
    for (final model in changes) {
      final old = previous.lookup(model.id)!;
      if (old.copyWith(light: model.light, clearLight: model.light == null) !=
          model)
        return false;
    }
    final affected = <_SceneModelComponent, bool>{};
    final decorationMaps = <String>{};
    for (final model in changes) {
      for (final dependent
          in _modelSourceDependents[model.sourceAssetId] ??
              const <_ModelSourceDependent>[]) {
        if (dependent.instance.modelId != model.id) continue;
        final component =
            dependent.chunk.models[dependent.instance.id]!.component;
        component.definition = model;
        affected[component] = dependent.decoration;
        if (dependent.decoration) decorationMaps.add(dependent.mapId);
      }
    }
    List<({Model3dPointLight definition, _SceneModelComponent component})>
    update(
      List<({Model3dPointLight definition, _SceneModelComponent component})>
      lights,
      bool decoration,
    ) => [
      for (final light in lights)
        if (!affected.containsKey(light.component)) light,
      for (final entry in affected.entries)
        if (entry.value == decoration && entry.key.sourceGeometryVisible)
          if (entry.key.definition.light case final light?)
            (definition: light, component: entry.key),
    ];
    pointLightBindings = update(pointLightBindings, false);
    decorationPointLights = update(decorationPointLights, true);
    for (final id in decorationMaps) {
      final old = _decorationMaterializations[id];
      if (old == null) continue;
      _decorationMaterializations[id] = (
        chunk: old.chunk,
        sourceAssetIds: old.sourceAssetIds,
        casters: old.casters,
        lights: [
          for (final light in decorationPointLights)
            if (old.chunk.models.values.any(
              (model) => identical(model.component, light.component),
            ))
              light,
        ],
      );
    }
    renderedConfiguration = after;
    syncLighting();
    return true;
  }

  void _bindModelSourceUpdates() {
    final updates = configuration.modelSourceUpdates;
    if (identical(updates, _modelSourceUpdates)) return;
    _modelSourceUpdates?.removeListener(_modelSourceUpdateListener);
    _modelSourceUpdates = updates;
    updates?.addListener(_modelSourceUpdateListener);
    if (updates == null) return;
    for (final entry in _modelSourceDependents.entries) {
      final revision = updates.revision(entry.key);
      if (revision != _residentModelSourceRevisions[entry.key]) {
        _pendingModelSourceRevisions[entry.key] = revision;
        _modelSourceRevisionPending = true;
      }
      for (final dependent in entry.value) {
        final id = dependent.instance.modelId;
        if (updates.definition(id) case final definition?) {
          _pendingModelSourceDefinitions[id] = definition;
        }
      }
    }
  }

  void _receiveModelSourceUpdates() {
    final updates = _modelSourceUpdates!;
    _pendingModelSourceRevisions.addAll(updates._batch);
    _pendingModelSourceDefinitions.addAll(updates._definitionBatch);
    _modelSourceRevisionPending = true;
    if (refreshing) generation++;
  }

  void _observeModelSourceRevisions() {
    _bindModelSourceUpdates();
    final snapshot = configuration;
    if (identical(_lastModelSourceRevisions, snapshot.modelSourceRevisions))
      return;
    _lastModelSourceRevisions = snapshot.modelSourceRevisions;
    if (snapshot.modelSourceUpdates != null) return;
    for (final source
        in snapshot.changedModelSourceIds ?? loadedModelSources.keys) {
      modelSourceCandidatesVisited++;
      final revision = snapshot.modelSourceRevisions[source];
      final previous = _pendingModelSourceRevisions.containsKey(source)
          ? _pendingModelSourceRevisions[source]
          : _residentModelSourceRevisions[source];
      if (revision == previous) continue;
      _pendingModelSourceRevisions[source] = revision;
      _modelSourceRevisionPending = true;
    }
    _pendingModelSourceDefinitions.addAll(snapshot.modelSourceDefinitions);
  }

  void _commitModelSourceRevisions(SpatialSceneView snapshot) {
    for (final source in loadedModelSources.keys) {
      _residentModelSourceRevisions[source] =
          snapshot.modelSourceUpdates?.revision(source) ??
          _pendingModelSourceRevisions[source] ??
          snapshot.modelSourceRevisions[source];
    }
    _pendingModelSourceRevisions.clear();
    _pendingModelSourceDefinitions.clear();
    _modelSourceRevisionPending = false;
    _lastModelSourceRevisions = snapshot.modelSourceRevisions;
  }

  void _invalidateChangedModelSourceRevisions() {
    _observeModelSourceRevisions();
    for (final entry in _pendingModelSourceRevisions.entries) {
      final source = entry.key;
      if (entry.value == _residentModelSourceRevisions[source]) continue;
      cache.remove(source);
      if (modelReservations.remove(source) case final lease?)
        retiredReservations.add(lease);
      final model = loadedModelSources.remove(source);
      if (model != null) clippedModelCache.releaseSource(model);
      for (final dependent
          in _modelSourceDependents[source] ??
              const <_ModelSourceDependent>[]) {
        _invalidatedModelChunks.add(dependent.chunk);
      }
    }
  }

  bool get canSyncModelSourceRevisions {
    _observeModelSourceRevisions();
    final before = renderedConfiguration, after = configuration;
    if (before == null ||
        !_modelSourceRevisionPending ||
        before.resourceIdentity != after.resourceIdentity ||
        !identical(before.resourceBudget, after.resourceBudget) ||
        !identical(before.controller, after.controller) ||
        !identical(before.scene, after.scene) ||
        !identical(before.groundMap, after.groundMap) ||
        before.sceneOffset != after.sceneOffset ||
        before.ground != after.ground ||
        before.edge != after.edge ||
        before.selectedCell != after.selectedCell ||
        !_sameProjectOutsideModels(before.groundProject, after.groundProject) ||
        before.neighbors.length != after.neighbors.length ||
        before.decorations.length != after.decorations.length)
      return false;
    if (!identical(before.neighbors, after.neighbors)) {
      for (final (index, neighbor) in before.neighbors.indexed) {
        final next = after.neighbors[index];
        if (!identical(neighbor.map, next.map) ||
            neighbor.offset != next.offset ||
            !_sameProjectOutsideModels(neighbor.project, next.project))
          return false;
      }
    }
    if (!identical(before.decorations, after.decorations)) {
      for (final (index, decoration) in before.decorations.indexed) {
        final next = after.decorations[index];
        if (decoration.decoration != next.decoration ||
            decoration.ownerMapId != next.ownerMapId ||
            decoration.offset != next.offset ||
            !_sameProjectOutsideModels(decoration.project, next.project))
          return false;
      }
    }
    return true;
  }

  void _indexModelSourceDependents() {
    _modelSourceDependents.clear();
    _modelSourceInstanceDependents.clear();
    final snapshot = renderedConfiguration ?? configuration;
    final neighbors = {
      for (final entry in snapshot.neighbors.indexed) entry.$2.map.id: entry.$1,
    };
    final decorations = {
      for (final entry in snapshot.decorations.indexed)
        (entry.$2.ownerMapId, entry.$2.decoration.mapId): entry.$1,
    };
    for (final (chunks, decoration) in [
      (sceneChunks, false),
      (decorationChunks, true),
    ]) {
      for (final entry in chunks.entries) {
        final chunk = entry.value;
        final instances = {
          for (final instance in chunk.signature.$2.instances)
            instance.id: instance,
        };
        final projection = _decorationProjections[entry.key];
        final sourceIndex = decoration
            ? decorations[(
                    projection?.source.ownerMapId,
                    projection?.source.decoration.mapId,
                  )] ??
                  -1
            : neighbors[entry.key] ?? -1;
        for (final model in chunk.models.entries) {
          final source = model.value.component.definition.sourceAssetId;
          final dependent = _ModelSourceDependent(
            chunk: chunk,
            mapId: entry.key,
            instance: instances[model.key]!,
            decoration: decoration,
            sourceIndex: sourceIndex,
          );
          (_modelSourceDependents[source] ??= []).add(dependent);
          _modelSourceInstanceDependents[(entry.key, model.key)] = dependent;
        }
      }
    }
  }

  Future<bool> _syncModelSourceRevisions() async {
    final before = renderedConfiguration!;
    final snapshot = configuration;
    final selectedComponent = _editingModels(
      snapshot,
    )[snapshot.selectedContent?.id]?.component;
    final revisions = Map<String, String?>.of(_pendingModelSourceRevisions);
    final definitions = Map<String, ProjectModel3dEntry>.of(
      _pendingModelSourceDefinitions,
    );
    final changed = {
      for (final entry in revisions.entries)
        if (entry.value != _residentModelSourceRevisions[entry.key]) entry.key,
    };
    final ticket = ++generation;
    bool current() => !closed && ticket == generation;
    refreshing = true;
    _destinationPreparation?.discard();
    _destinationPreparation = null;
    final staged = <String, Future<Model>>{};
    final stagedModels = <String, Model>{};
    final leases = <String, RuntimeResourceReservation>{};
    final replacements =
        <(_ModelSourceDependent, _ScenePlacedModel, _SceneModelComponent)>[];
    final changedCasters = <String, SpatialAuthoredShadowCaster?>{};
    final affectedLights = <_SceneModelComponent>{};
    var committed = false;
    try {
      for (final source in changed) {
        modelSourceCandidatesVisited++;
        for (final dependent
            in _modelSourceDependents[source] ??
                const <_ModelSourceDependent>[]) {
          final instance = dependent.instance;
          final previous = dependent.chunk.models[instance.id]!;
          final definition =
              definitions[instance.modelId] ?? previous.component.definition;
          final neighbor = !dependent.decoration && dependent.sourceIndex >= 0
              ? snapshot.neighbors[dependent.sourceIndex]
              : null;
          final decoration = dependent.decoration && dependent.sourceIndex >= 0
              ? snapshot.decorations[dependent.sourceIndex]
              : null;
          final loader =
              decoration?.loadModel ??
              neighbor?.loadModel ??
              snapshot.loadModel;
          final model = await ModelByteLoader.loadCached(
            staged,
            source,
            () => loader(definition.id),
            budget: resourceBudget,
            isCurrent: current,
            onResident: (key, lease) => leases[key] = lease,
          );
          if (!current()) return false;
          stagedModels[source] = model;
          final clip = spatialModelSourceClip(instance, definition);
          final clipped = clip == null
              ? null
              : clippedModelCache.resolve(model, clip);
          final sourceVisible =
              (clip == null || clipped != null) &&
              (!dependent.decoration ||
                  (_decorationProjections[dependent.mapId]?.allowsModel(
                        instance,
                        definition,
                      ) ??
                      false));
          final scale = definition.scale * instance.scale;
          final rotation = Quaternion.axisAngle(
            Vector3(0, 1, 0),
            instance.rotationDegrees * math.pi / 180,
          );
          final pivot =
              Vector3(
                definition.pivot.x,
                definition.pivot.y,
                definition.pivot.z,
              ) *
              scale;
          rotation.asRotationMatrix().transform(pivot);
          final offset = dependent.chunk.signature.$4;
          final component = _SceneModelComponent(
            instanceId: instance.id,
            initialAnchorY: instance.position.y,
            shadowId: previous.component.shadowId,
            model: clipped?.model ?? model,
            visibleBounds: clipped?.bounds ?? definition.inspection.bounds,
            definition: definition,
            position:
                Vector3(
                  instance.position.x + offset.dx,
                  instance.position.y,
                  instance.position.z + offset.dy,
                ) -
                pivot,
            rotation: rotation,
            scale: Vector3.all(scale),
          )..sourceGeometryVisible = sourceVisible;
          component.bindAnimation(
            instance.animationIndex,
            loop: instance.animationLoop,
            speed: instance.animationSpeed,
          );
          replacements.add((dependent, previous, component));
          if (instance.effectiveCastsShadows(previous.component.definition) ||
              instance.effectiveCastsShadows(definition)) {
            changedCasters[component.shadowId] = sourceVisible
                ? spatialAuthoredShadowCaster(
                    mapId: dependent.mapId,
                    instance: instance,
                    definition: definition,
                    bounds: component.visibleBounds,
                    worldTransform: component.worldTransformMatrix,
                  )
                : null;
          }
          if (previous.component.definition.light != null ||
              definition.light != null)
            affectedLights.add(previous.component);
        }
      }
      if (!current()) return false;
      for (final (dependent, previous, next) in replacements) {
        final component = previous.component;
        component.replaceModelFrom(next);
        component.definition = next.definition;
        component.visibleBounds = next.visibleBounds;
        component.sourceGeometryVisible = next.sourceGeometryVisible;
        component.position.setFrom(next.position);
        component.initialPositionY = next.position.y;
        final preview = snapshot.contentPreview;
        if (preview?.kind == SpatialSceneContentKind.model &&
            preview?.id == dependent.instance.id) {
          component.position.add(
            Vector3(
              preview!.position.x - dependent.instance.position.x,
              preview.position.y - dependent.instance.position.y,
              preview.position.z - dependent.instance.position.z,
            ),
          );
        }
        component.rotation.setFrom(next.rotation);
        component.scale.setFrom(next.scale);
        final updated = (
          component: component,
          position: next.position.clone(),
          anchor: dependent.instance.position,
        );
        dependent.chunk.models[dependent.instance.id] = updated;
        if (identical(
          modelComponents[dependent.instance.id]?.component,
          component,
        ))
          modelComponents[dependent.instance.id] = updated;
        if (identical(selectedComponent, component)) {
          if (modelSelections.remove(dependent.instance.id)
              case final selection?)
            component.removeAll(selection);
        }
      }
      List<SpatialAuthoredShadowCaster> updateCasters(
        List<SpatialAuthoredShadowCaster> previous,
        bool decoration,
      ) => [
        for (final caster in previous)
          if (!changedCasters.containsKey(caster.id)) caster,
        for (final (dependent, previous, _) in replacements)
          if (dependent.decoration == decoration)
            if (changedCasters[previous.component.shadowId] case final caster?)
              caster,
      ];
      if (changedCasters.isNotEmpty) {
        authoredShadowCasters = updateCasters(authoredShadowCasters, false);
        decorationShadowCasters = updateCasters(decorationShadowCasters, true);
        _casterShadowIds = allAuthoredShadowCasters
            .map((caster) => caster.id)
            .toSet();
        final context = this.context as SpatialRenderContext;
        context.shadowCasters = [
          for (final component in context.shadowCasters)
            if (!changedCasters.containsKey(
              (component as _SceneModelComponent).shadowId,
            ))
              component,
          for (final (_, previous, _) in replacements)
            if (changedCasters[previous.component.shadowId] != null)
              previous.component,
        ];
        _refreshVisibilityLighting();
      }
      List<({Model3dPointLight definition, _SceneModelComponent component})>
      updateLights(
        List<({Model3dPointLight definition, _SceneModelComponent component})>
        previous,
        bool decoration,
      ) => [
        for (final light in previous)
          if (!affectedLights.contains(light.component)) light,
        for (final (dependent, previous, _) in replacements)
          if (dependent.decoration == decoration &&
              affectedLights.contains(previous.component) &&
              previous.component.sourceGeometryVisible)
            if (previous.component.definition.light case final light?)
              (definition: light, component: previous.component),
      ];
      if (affectedLights.isNotEmpty) {
        pointLightBindings = updateLights(pointLightBindings, false);
        decorationPointLights = updateLights(decorationPointLights, true);
      }
      if (changedCasters.isNotEmpty || affectedLights.isNotEmpty) {
        for (final mapId in {
          for (final (dependent, _, _) in replacements)
            if (dependent.decoration) dependent.mapId,
        }) {
          final old = _decorationMaterializations[mapId]!;
          _decorationMaterializations[mapId] = (
            chunk: old.chunk,
            sourceAssetIds: old.sourceAssetIds,
            casters: [
              for (final caster in old.casters)
                if (!changedCasters.containsKey(caster.id)) caster,
              for (final (dependent, previous, _) in replacements)
                if (dependent.decoration && dependent.mapId == mapId)
                  if (changedCasters[previous.component.shadowId]
                      case final caster?)
                    caster,
            ],
            lights: [
              for (final light in old.lights)
                if (!affectedLights.contains(light.component)) light,
              for (final (dependent, previous, _) in replacements)
                if (dependent.decoration &&
                    dependent.mapId == mapId &&
                    affectedLights.contains(previous.component) &&
                    previous.component.sourceGeometryVisible)
                  if (previous.component.definition.light case final light?)
                    (definition: light, component: previous.component),
            ],
          );
        }
      }
      for (final source in changed) {
        final previous = loadedModelSources.remove(source);
        if (previous != null) clippedModelCache.releaseSource(previous);
        cache.remove(source);
        modelReservations.remove(source)?.release();
        if (staged[source] case final future?) cache[source] = future;
        if (stagedModels[source] case final model?)
          loadedModelSources[source] = model;
        if (leases.remove(source) case final lease?)
          modelReservations[source] = lease;
      }
      for (final entry in revisions.entries)
        _residentModelSourceRevisions[entry.key] = entry.value;
      _pendingModelSourceRevisions.clear();
      _pendingModelSourceDefinitions.clear();
      _modelSourceRevisionPending = false;
      renderedConfiguration = snapshot;
      refreshing = false;
      committed = true;
      modelSourceComponentBuilds += replacements.length;
      modelSourceUpdates++;
      if (changedCasters.isNotEmpty || affectedLights.isNotEmpty)
        syncLighting();
      final selectedChanged = replacements.any(
        (entry) => identical(entry.$2.component, selectedComponent),
      );
      syncContentSelection(selectedChanged ? null : before, snapshot);
      if (!identical(before.visibility, snapshot.visibility)) syncVisibility();
      if (!identical(before.contentPreview, snapshot.contentPreview)) {
        for (final id in {
          before.contentPreview?.id,
          snapshot.contentPreview?.id,
        }) {
          final placed = _editingModels(snapshot)[id];
          if (placed == null) continue;
          final preview = snapshot.contentPreview;
          final position =
              preview?.kind == SpatialSceneContentKind.model &&
                  preview?.id == id
              ? preview!.position
              : placed.anchor;
          placed.component.position.setValues(
            placed.position.x + position.x - placed.anchor.x,
            placed.position.y + position.y - placed.anchor.y,
            placed.position.z + position.z - placed.anchor.z,
          );
        }
      }
      if (snapshot.placementPreview case final preview?) {
        final definition =
            definitions[preview.modelId] ??
            snapshot.modelSourceUpdates?.definition(preview.modelId) ??
            placementRenderer.definition;
        if (definition != null && changed.contains(definition.sourceAssetId)) {
          placementRenderer.clear();
          await placementRenderer.sync(
            preview: placementPreviewHidden ? null : preview,
            models: [definition],
            color: snapshot.selectionColor ?? snapshot.edge,
            offset:
                snapshot.sceneOffset +
                (snapshot.authoringTarget?.offset ?? Offset.zero),
          );
        }
      }
      if (snapshot.onHover != null) onSurfaceChanged();
      return true;
    } on Object {
      if (!current()) return false;
      rethrow;
    } finally {
      for (final lease in leases.values) lease.release();
      if (!committed)
        for (final model in stagedModels.values)
          clippedModelCache.releaseSource(model);
      if (current()) refreshing = false;
    }
  }
}
