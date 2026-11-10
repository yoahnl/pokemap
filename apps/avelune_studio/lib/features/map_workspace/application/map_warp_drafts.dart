import 'package:map_core/map_core.dart';

class MapWarpLadderDraft {
  MapWarpLadderDraft(this.warp) {
    reset(warp);
  }
  MapWarp warp;
  late String mode, facing, height, duration;
  bool durationTouched = false;

  void reset(MapWarp value) {
    warp = value;
    final ladder = warp.ladder ?? MapWarpLadder();
    mode = warp.ladder?.direction.name ?? 'none';
    facing = ladder.facing.name;
    height = ladder.heightCells.toString();
    duration = (ladder.durationSeconds * 1000).round().toString();
    durationTouched = false;
  }

  MapWarpLadder? get value {
    if (mode == 'none') return null;
    final heightValue = double.tryParse(height),
        durationValue = double.tryParse(duration);
    if (heightValue == null || durationValue == null) return null;
    try {
      return MapWarpLadder(
        direction: MapWarpLadderDirection.values.byName(mode),
        facing: EntityFacing.values.byName(facing),
        heightCells: heightValue,
        durationSeconds: durationTouched
            ? durationValue / 1000
            : (warp.ladder?.durationSeconds ?? 16 / 30),
      );
    } on FormatException {
      return null;
    }
  }

  bool get invalid => mode != 'none' && value == null;
}

class MapWarpTransitionDraft {
  MapWarpTransitionDraft(this.original) {
    reset(original);
  }
  MapWarpTransition original;
  late MapWarpTransitionType type;
  late String durationMs;
  bool durationTouched = false;

  void reset(MapWarpTransition transition) {
    original = transition;
    type = transition.type;
    durationMs = (transition.durationSeconds * 1000).round().toString();
    durationTouched = false;
  }

  void defaults() {
    reset(const MapWarpTransition());
    durationTouched = true;
  }

  MapWarpTransition? get value {
    final duration = durationTouched ? int.tryParse(durationMs.trim()) : null;
    if (durationTouched &&
        (duration == null || duration < 1 || duration > 5000)) {
      return null;
    }
    return MapWarpTransition(
      type: type,
      durationSeconds: duration == null
          ? original.durationSeconds
          : duration / 1000,
    );
  }
}

class MapWarpDoorDraft {
  MapWarpDoorDraft(this.map, this.project, this.warp) {
    reset(warp);
  }
  MapData map;
  ProjectManifest project;
  MapWarp warp;
  MapWarpDoor? value;
  bool enabled = false;

  void reset(MapWarp next) {
    warp = next;
    value = warp.door;
    enabled = value != null;
  }

  ProjectModel3dEntry? model(SpatialModelInstance instance) {
    final models = project.models3d.where(
      (model) => model.id == instance.modelId,
    );
    return models.length == 1 ? models.single : null;
  }

  List<Model3dAnimation> clips(ProjectModel3dEntry? model) {
    final clips = model?.inspection.animations ?? <Model3dAnimation>[];
    return clips
        .where(
          (clip) =>
              clip.durationSeconds.isFinite &&
              clip.durationSeconds > 0 &&
              clips.where((other) => other.index == clip.index).length == 1,
        )
        .toList();
  }

  Map<GridPos, String> exits() {
    final position = warp.pos;
    final candidates = {
      GridPos(x: position.x, y: position.y + 1): 'Sud',
      GridPos(x: position.x, y: position.y - 1): 'Nord',
      GridPos(x: position.x + 1, y: position.y): 'Est',
      GridPos(x: position.x - 1, y: position.y): 'Ouest',
    };
    return Map.fromEntries(
      candidates.entries.where((entry) {
        final position = entry.key;
        return position.x >= 0 &&
            position.y >= 0 &&
            position.x < map.size.width &&
            position.y < map.size.height &&
            !(map.spatialScene?.navigation.blockedAreas.any(
                  (area) => area.contains(position.x + .5, position.y + .5),
                ) ??
                false);
      }),
    );
  }

  String exitId(GridPos position) => '${position.x},${position.y}';

  MapWarpDoor binding(SpatialModelInstance instance, GridPos exit) {
    final availableClips = clips(model(instance));
    return MapWarpDoor(
      instanceId: instance.id,
      openAnimationIndex: availableClips.first.index,
      closeAnimationIndex: availableClips.length > 1
          ? availableClips[1].index
          : availableClips.first.index,
      exitPos: exit,
    );
  }

  List<SpatialModelInstance> get candidates {
    final instances = map.spatialScene?.instances ?? <SpatialModelInstance>[];
    return instances
        .where(
          (instance) =>
              instance.clip == null &&
              instance.animationIndex == null &&
              instances.where((other) => other.id == instance.id).length == 1 &&
              clips(model(instance)).isNotEmpty,
        )
        .toList();
  }

  bool get changed =>
      enabled != (warp.door != null) || (enabled && value != warp.door);

  String? get problem {
    if (!enabled) return null;
    final draft = value;
    if (draft == null) {
      return 'Choisissez un modèle animé et une case de dégagement.';
    }
    try {
      validateMapWarpDoor(
        map,
        warp.copyWith(door: draft),
        models: project.models3d,
      );
    } on ValidationException catch (error) {
      return error.message;
    }
    return null;
  }

  void enable(bool next) {
    enabled = next;
    final choices = candidates, exits = this.exits();
    if (next && value == null && choices.isNotEmpty && exits.isNotEmpty) {
      value = binding(choices.first, exits.keys.first);
    }
  }
}
