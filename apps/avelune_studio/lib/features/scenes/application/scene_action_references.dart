import 'package:map_core/map_core_domain.dart';
import 'package:map_core/map_core.dart'
    show ProjectModel3dEntry, Model3dAnimation;

class SceneActionReferences {
  SceneActionReferences({required this.project, required this.changed});

  ProjectManifest project;
  final void Function() changed;
  MapData? map;
  String? mapId;
  String? error;
  bool loading = false;
  int _request = 0;
  bool _disposed = false;

  Future<void> load({
    required ProjectManifest project,
    required String? commandId,
    required Map<String, String> parameters,
    required Future<MapData> Function(String)? loadMap,
  }) async {
    if (_disposed) return;
    this.project = project;
    final request = ++_request;
    map = null;
    error = null;
    loading = false;
    mapId = switch (commandId) {
      NarrativeCommandIds.setPropState ||
      NarrativeCommandIds.setMapEventInstanceBoolean ||
      NarrativeCommandIds.playModelAnimation => parameters['mapId'],
      NarrativeCommandIds.warp => parameters['destinationMapId'],
      _ => null,
    };
    final id = mapId;
    if (id == null || !project.maps.any((entry) => entry.id == id)) return;
    if (loadMap == null) {
      error = 'La carte n’est pas disponible dans cet éditeur.';
      return;
    }
    loading = true;
    final isWarp = commandId == NarrativeCommandIds.warp;
    final isProp = commandId == NarrativeCommandIds.setPropState;
    final isLocal = commandId == NarrativeCommandIds.setMapEventInstanceBoolean;
    try {
      final loaded = await Future<MapData>.sync(() => loadMap(id));
      if (_disposed || request != _request) return;
      loading = false;
      if (loaded.id != id && (isWarp || isProp || isLocal)) {
        error = 'La carte chargée ne correspond pas à la destination.';
      } else if ((isProp || isLocal) &&
          (loaded.spatialScene != null ||
              loaded.version == ProjectVersion.v9)) {
        error = 'Les décors mobiles nécessitent une carte 2D.';
      } else if (!isWarp &&
          !isProp &&
          !isLocal &&
          (loaded.id != id || loaded.spatialScene == null)) {
        error = 'La carte choisie ne contient pas de scène 3D.';
      } else {
        map = loaded;
      }
    } catch (failure) {
      if (_disposed || request != _request) return;
      loading = false;
      error = isWarp
          ? 'Impossible de charger les points d’arrivée : $failure'
          : 'Impossible de charger les décors : $failure';
    }
    changed();
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  Map<String, String> get warpPoints => {
    for (final (index, warp) in (map?.warps ?? <MapWarp>[]).indexed)
      warp.id: 'Point d’arrivée ${index + 1} · (${warp.pos.x}, ${warp.pos.y})',
  };

  Map<String, String> get movingProps => {
    for (final prop in map?.movingProps ?? <MovingPropDefinition>[])
      if (map!.movingProps.where((value) => value.id == prop.id).length == 1)
        prop.id:
            '${project.elements.where((element) => element.id == map!.placedElements.where((placement) => placement.id == prop.placedElementId).firstOrNull?.elementId).firstOrNull?.name ?? 'Décor'} · (${prop.closedPositionPx.x}, ${prop.closedPositionPx.y})',
  };

  ProjectModel3dEntry? _instanceModel(SpatialModelInstance instance) => project
      .models3d
      .where((model) => model.id == instance.modelId)
      .firstOrNull;

  Map<String, String> get modelInstances => {
    for (final instance
        in map?.spatialScene?.instances ?? <SpatialModelInstance>[])
      if (_instanceModel(instance) case final model?)
        if (model.inspection.animations.isNotEmpty)
          instance.id:
              '${model.name} · (${instance.position.x.toStringAsFixed(1)}, ${instance.position.z.toStringAsFixed(1)})',
  };

  Map<String, String> modelAnimations(String? instanceId) {
    final instance = map?.spatialScene?.instances
        .where((instance) => instance.id == instanceId)
        .firstOrNull;
    final model = instance == null ? null : _instanceModel(instance);
    return {
      for (final clip in model?.inspection.animations ?? <Model3dAnimation>[])
        '${clip.index}':
            '${clip.name} · ${clip.durationSeconds.toStringAsFixed(2)} s',
    };
  }
}
