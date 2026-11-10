import 'package:map_core/map_core.dart';

class SceneNpcPoseDraft {
  SceneNpcPoseDraft({
    required this.project,
    required this.current,
    required this.changed,
    this.loadMap,
  }) {
    read();
  }
  ProjectManifest project;
  SceneActionPayload? current;
  Future<MapData> Function(String)? loadMap;
  final void Function() changed;
  bool _disposed = false;
  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required ProjectManifest project,
    required SceneActionPayload? current,
    required Future<MapData> Function(String)? loadMap,
  }) {
    final reread = this.current != current;
    final reload = this.project != project || this.loadMap != loadMap;
    this.project = project;
    this.current = current;
    this.loadMap = loadMap;
    if (reread) {
      read();
    } else if (reload) {
      reloadMap();
    }
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  String? selectedMapId, selectedEntityId, facingName;
  String mode = 'position', xText = '', yText = '';
  MapData? stageMap;
  bool loading = false;
  String? error;
  int _request = 0;

  void read() {
    final pose = current?.consequence;
    selectedMapId = null;
    selectedEntityId = null;
    mode = 'position';
    facingName = null;
    xText = '';
    yText = '';
    if (pose is SceneSetNpcPoseConsequence) {
      selectedMapId = pose.mapId;
      selectedEntityId = pose.entityId;
      mode = pose.x == null ? 'facing' : 'position';
      xText = pose.x?.toString() ?? '';
      yText = pose.y?.toString() ?? '';
      facingName = pose.facing?.name;
    }
    reloadMap();
  }

  Map<String, String> get mapOptions => {
    if (project.settings.dimension == ProjectDimension.twoD)
      for (final entry in project.maps)
        if (project.maps.where((value) => value.id == entry.id).length == 1)
          entry.id: entry.name,
  };

  Map<String, String> get actorOptions => {
    if (stageMap case final map?)
      for (final entity in map.entities)
        if (map.entities.where((value) => value.id == entity.id).length == 1 &&
            entity.presentation != null &&
            entity.presentation!.variants.any(
              (variant) => variant.characterId != null,
            ) &&
            validateMapEntityPresentation(
              project: project,
              map: map,
              entity: entity,
            ).isEmpty)
          entity.id: entity.name.isEmpty ? 'PNJ (${entity.id})' : entity.name,
  };

  Future<void> reloadMap() async {
    final token = ++_request;
    stageMap = null;
    error = null;
    loading = false;
    final id = selectedMapId;
    if (id == null) return;
    loading = true;
    await Future<void>.value();
    try {
      if (!mapOptions.containsKey(id) || loadMap == null) {
        throw StateError('Unavailable');
      }
      final map = await loadMap!(id);
      if (map.id != id ||
          map.version == ProjectVersion.v9 ||
          map.spatialScene != null) {
        throw StateError('Unavailable');
      }
      if (!_disposed && token == _request) _update(() => stageMap = map);
    } on Object {
      if (!_disposed && token == _request) {
        _update(
          () => error = 'Carte indisponible. Les références enregistrées sont conservées.',
        );
      }
    } finally {
      if (!_disposed && token == _request) _update(() => loading = false);
    }
  }

  SceneSetNpcPoseConsequence? get pose {
    if (loading ||
        error != null ||
        !mapOptions.containsKey(selectedMapId) ||
        !actorOptions.containsKey(selectedEntityId)) {
      return null;
    }
    try {
      final facing = facingName == null || facingName!.isEmpty
          ? null
          : EntityFacing.values.byName(facingName!);
      if (mode == 'facing') {
        return SceneConsequence.setNpcPose(
          mapId: selectedMapId!,
          entityId: selectedEntityId!,
          facing: facing,
        ) as SceneSetNpcPoseConsequence;
      }
      final x = int.tryParse(xText), y = int.tryParse(yText);
      if (x == null || y == null) return null;
      final owner = stageMap!.entities.singleWhere(
        (entity) => entity.id == selectedEntityId,
      );
      if (x + owner.size.width > stageMap!.size.width ||
          y + owner.size.height > stageMap!.size.height ||
          owner.presentation!.variants.any(
            (variant) =>
                x + variant.size.width > stageMap!.size.width ||
                y + variant.size.height > stageMap!.size.height,
          )) {
        return null;
      }
      return SceneConsequence.setNpcPose(
        mapId: selectedMapId!,
        entityId: selectedEntityId!,
        x: x,
        y: y,
        facing: facing,
      ) as SceneSetNpcPoseConsequence;
    } on Object {
      return null;
    }
  }
}
