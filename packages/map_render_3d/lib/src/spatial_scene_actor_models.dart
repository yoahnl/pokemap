part of 'spatial_scene_view.dart';

final class _SpatialSceneActorModels {
  _SpatialSceneActorModels(this.game);

  final SpatialSceneGame game;
  final _cache = <String, Future<Model>>{};
  final _sources = <String, _ActorModelSource>{};
  final _actors = <String, _ActorModelComponent>{};
  Set<String> _wanted = {}, _required = {};
  late SpatialSceneView _configuration;
  RuntimeResourceBudget? _budget;
  String? _identity;

  void beginFrame(SpatialSceneView configuration) {
    final budget = configuration.resourceBudget ?? game._ownedResourceBudget;
    if (!identical(_budget, budget) || _identity != configuration.resourceIdentity) {
      clear();
      _budget = budget;
      _identity = configuration.resourceIdentity;
    }
    _configuration = configuration;
    _wanted.clear();
  }

  bool sync(
    String id,
    SpatialActorModelVisual? visual, {
    required double x,
    required double y,
    required double z,
  }) {
    if (visual == null) {
      removeActor(id);
      return false;
    }
    final definition = visual.definition;
    final sourceId = definition.sourceAssetId;
    final revision = _revision(sourceId);
    var source = _sources[sourceId];
    if (source != null &&
        (source.revision != revision ||
            source.failed && source.loadModel != visual.loadModel)) {
      _removeSource(sourceId);
      source = null;
    }
    if (source == null) {
      source = _sources[sourceId] = _ActorModelSource(revision, visual.loadModel);
      unawaited(_load(source, definition));
    } else if (!_required.contains(sourceId) && !_wanted.contains(sourceId)) {
      source.lease?.retainRequired();
    }
    _wanted.add(sourceId);
    final model = source.model;
    if (model == null) {
      removeActor(id);
      return false;
    }
    var actor = _actors[id];
    if (actor == null || !identical(actor.model, model)) {
      actor?.removeFromParent();
      actor = _ActorModelComponent(model: model);
      _actors[id] = actor;
      game.world.add(actor);
    }
    final clip = visual.pose.animationIndex;
    if (clip == null || clip >= actor.animationCount) {
      actor.presentationVisible = false;
      return false;
    }
    actor.presentationVisible = true;
    actor.position.setValues(x, y, z);
    actor.scale.setValues(definition.scale, definition.scale, definition.scale);
    if (actor.facing != visual.facing || actor.definition != definition) {
      actor.facing = visual.facing;
      actor.definition = definition;
      final yaw = switch (visual.facing) {
        EntityFacing.south => 0.0,
        EntityFacing.east => math.pi / 2,
        EntityFacing.north => math.pi,
        EntityFacing.west => -math.pi / 2,
      };
      actor.rotation.setFrom(Quaternion.axisAngle(Vector3(0, 1, 0), yaw));
      final pivot = definition.pivot;
      actor.pivot.setValues(pivot.x, pivot.y, pivot.z);
      actor.pivot.scale(definition.scale);
      actor.rotation.asRotationMatrix().transform(actor.pivot);
    }
    actor.position.sub(actor.pivot);
    actor.bindRuntimeState(visual.pose);
    return actor.isMounted;
  }

  Future<void> _load(
    _ActorModelSource source,
    ProjectModel3dEntry definition,
  ) async {
    final id = definition.sourceAssetId;
    final budget = _budget!;
    bool current() =>
        !game.closed &&
        identical(_sources[id], source) &&
        _revision(id) == source.revision;
    try {
      final model = await ModelByteLoader.loadCached(
        _cache,
        id,
        () => source.loadModel(definition.id),
        budget: budget,
        isCurrent: current,
        onResident: (_, lease) {
          if (current()) {
            source.lease = lease;
          } else {
            lease.release();
          }
        },
      );
      if (current()) source.model = model;
    } on Object {
      if (!current()) return;
      source.lease?.release();
      source.lease = null;
      source.failed = true;
    }
  }

  String? _revision(String id) =>
      _configuration.modelSourceUpdates?.revision(id) ??
      _configuration.modelSourceRevisions[id];

  void setVisible(String id, bool visible) {
    if (!visible) _actors[id]?.presentationVisible = false;
  }

  void removeActor(String id) => _actors.remove(id)?.removeFromParent();

  void endFrame() {
    for (final id in _required) {
      if (_wanted.contains(id)) continue;
      final source = _sources[id];
      final lease = source?.lease;
      if (source?.model == null || lease == null) {
        _removeSource(id);
      } else if (!(_budget?.isDisposed ?? true)) {
        lease.retainOptionally(() => _removeSource(id));
      }
    }
    final previous = _required;
    _required = _wanted;
    _wanted = previous;
  }

  void _removeSource(String id) {
    _cache.remove(id);
    _sources.remove(id)?.lease?.release();
  }

  void clear() {
    for (final actor in _actors.values) {
      actor.removeFromParent();
    }
    _actors.clear();
    for (final source in _sources.values) {
      source.lease?.release();
    }
    _sources.clear();
    _cache.clear();
    _required.clear();
    _wanted.clear();
  }
}

final class _ActorModelSource {
  _ActorModelSource(this.revision, this.loadModel);

  final String? revision;
  final Future<Uint8List> Function(String id) loadModel;
  Model? model;
  RuntimeResourceReservation? lease;
  bool failed = false;
}

final class _ActorModelComponent extends AnimatedModelComponent {
  _ActorModelComponent({required super.model});

  final pivot = Vector3.zero();
  EntityFacing? facing;
  ProjectModel3dEntry? definition;
  bool presentationVisible = true;

  @override
  void draw(RenderContext3D context) {
    if (presentationVisible) super.draw(context);
  }

  @override
  bool isVisible(CameraComponent3D camera) =>
      presentationVisible && super.isVisible(camera);
}
