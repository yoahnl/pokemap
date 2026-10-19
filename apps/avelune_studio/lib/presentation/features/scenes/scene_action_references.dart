part of 'scene_action_form.dart';

extension _SceneActionReferences on _SceneActionFormState {
  void _loadReferenceMap() {
    final request = ++_referenceRequest;
    _referenceMap = null;
    _referenceError = null;
    _referenceLoading = false;
    _referenceMapId = switch (_commandId) {
      NarrativeCommandIds.setPropState => _values['mapId'],
      NarrativeCommandIds.playModelAnimation => _values['mapId'],
      NarrativeCommandIds.warp => _values['destinationMapId'],
      _ => null,
    };
    final id = _referenceMapId;
    if (id == null ||
        !_options(NarrativeCommandParameterKind.map).containsKey(id)) {
      return;
    }
    final load = widget.loadMap;
    if (load == null) {
      _referenceError = 'La carte n’est pas disponible dans cet éditeur.';
      return;
    }
    _referenceLoading = true;
    final isWarp = _commandId == NarrativeCommandIds.warp;
    final isProp = _commandId == NarrativeCommandIds.setPropState;
    Future<MapData>.sync(() => load(id)).then(
      (map) {
        if (!mounted || request != _referenceRequest) return;
        _refreshReferences(() {
          _referenceLoading = false;
          if (map.id != id && (isWarp || isProp)) {
            _referenceError =
                'La carte chargée ne correspond pas à la destination.';
          } else if (isProp && map.spatialScene != null) {
            _referenceError = 'Les décors mobiles nécessitent une carte 2D.';
          } else if (!isWarp && !isProp && (map.id != id || map.spatialScene == null)) {
            _referenceError = 'La carte choisie ne contient pas de scène 3D.';
          } else {
            _referenceMap = map;
          }
        });
      },
      onError: (Object error) {
        if (!mounted || request != _referenceRequest) return;
        _refreshReferences(() {
          _referenceLoading = false;
          _referenceError = isWarp
              ? 'Impossible de charger les points d’arrivée : $error'
              : 'Impossible de charger les décors : $error';
        });
      },
    );
  }

  Map<String, String> get _warpPoints => {
    for (final (index, warp) in (_referenceMap?.warps ?? <MapWarp>[]).indexed)
      warp.id: 'Point d’arrivée ${index + 1} · (${warp.pos.x}, ${warp.pos.y})',
  };

  Map<String, String> get _movingProps => {
    for (final prop in _referenceMap?.movingProps ?? <MovingPropDefinition>[])
      if (_referenceMap!.movingProps.where((value) => value.id == prop.id).length == 1)
        prop.id: '${widget.project.elements.where((element) => element.id == _referenceMap!.placedElements.where((placement) => placement.id == prop.placedElementId).firstOrNull?.elementId).firstOrNull?.name ?? 'Décor'} · (${prop.closedPositionPx.x}, ${prop.closedPositionPx.y})',
  };

  ProjectModel3dEntry? _instanceModel(SpatialModelInstance instance) => widget
      .project
      .models3d
      .where((model) => model.id == instance.modelId)
      .firstOrNull;

  Map<String, String> get _modelInstances => {
    for (final instance
        in _referenceMap?.spatialScene?.instances ?? <SpatialModelInstance>[])
      if (_instanceModel(instance) case final model?)
        if (model.inspection.animations.isNotEmpty)
          instance.id:
              '${model.name} · (${instance.position.x.toStringAsFixed(1)}, ${instance.position.z.toStringAsFixed(1)})',
  };

  Map<String, String> get _modelAnimations {
    final instance = _referenceMap?.spatialScene?.instances
        .where((instance) => instance.id == _values['instanceId'])
        .firstOrNull;
    final model = instance == null ? null : _instanceModel(instance);
    return {
      for (final clip in model?.inspection.animations ?? <Model3dAnimation>[])
        '${clip.index}':
            '${clip.name} · ${clip.durationSeconds.toStringAsFixed(2)} s',
    };
  }
}
