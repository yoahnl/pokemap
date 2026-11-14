import 'package:map_core/map_core_domain.dart';

import 'map_atmosphere_controller.dart';

String? mapAtmosphereOverrides(
  SpatialVisualPatch? effective,
  SpatialVisualPatch? local,
) {
  if (effective == null) return null;
  const groups = <(String, List<SpatialVisualParameter>)>[
    (
      'profondeur de champ',
      [
        SpatialVisualParameter.depthOfFieldEnabled,
        SpatialVisualParameter.depthOfFieldStrength,
        SpatialVisualParameter.depthOfFieldFocusRange,
      ],
    ),
    (
      'halos',
      [
        SpatialVisualParameter.halosEnabled,
        SpatialVisualParameter.haloStrength,
        SpatialVisualParameter.haloSpread,
      ],
    ),
    (
      'brume',
      [
        SpatialVisualParameter.depthFogEnabled,
        SpatialVisualParameter.fogOpacity,
        SpatialVisualParameter.fogStart,
        SpatialVisualParameter.fogEnd,
      ],
    ),
    (
      'eau animée',
      [
        SpatialVisualParameter.waterAnimated,
        SpatialVisualParameter.waterStrength,
        SpatialVisualParameter.waterSpeed,
      ],
    ),
    (
      'fenêtres',
      [
        SpatialVisualParameter.windowsLit,
        SpatialVisualParameter.windowStrength,
      ],
    ),
    (
      'lucioles',
      [SpatialVisualParameter.fireflies, SpatialVisualParameter.fireflyDensity],
    ),
  ];
  final fromProject = <String>[], fromMap = <String>[];
  for (final (label, parameters) in groups) {
    final set = parameters.where((p) => effective.value(p) != null);
    if (set.isEmpty) continue;
    if (set.any((p) => local?.value(p) != null)) {
      fromMap.add(label);
    } else {
      fromProject.add(label);
    }
  }
  if (fromProject.isEmpty && fromMap.isEmpty) return null;
  return [
    'En jeu, des réglages d’image remplacent une partie de ces effets :',
    if (fromProject.isNotEmpty)
      '${fromProject.join(', ')} (réglages du projet › Image et caméra)',
    if (fromMap.isNotEmpty)
      '${fromMap.join(', ')} (dérogation propre à cette carte)',
    'Les sources placées ici (lumières, vitrages, lucioles, eau) restent '
        'celles de cette carte.',
  ].join('\n');
}

class MapAtmosphereEditing {
  const MapAtmosphereEditing(this.controller, this.map, this.project);
  final MapAtmosphereController controller;
  final MapData map;
  final ProjectManifest? project;

  Map<String, (String, Model3dVector3)> get haloChoices {
    final choices = <String, (String, Model3dVector3)>{};
    final models = {
      for (final model in project?.models3d ?? <ProjectModel3dEntry>[])
        model.id: model,
    };
    for (final instance
        in map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = models[instance.modelId];
      if (model == null) continue;
      final bounds = model.inspection.bounds;
      choices[instance.id] = (
        model.name,
        model.light?.localPosition ??
            Model3dVector3(
              x: (bounds.min.x + bounds.max.x) / 2,
              y: (bounds.min.y + bounds.max.y) / 2,
              z: bounds.max.z + .04,
            ),
      );
    }
    return choices;
  }

  Map<String, (String, SpatialAtmosphereMaterialTarget)> materials({
    required bool ground,
  }) {
    final choices = <String, (String, SpatialAtmosphereMaterialTarget)>{};
    final project = this.project;
    if (project == null) return choices;
    if (ground) {
      final ids = {
        for (final layer in map.layers.whereType<TileLayer>())
          for (final entry in layer.palette) entry.tilesetId,
      };
      for (final tile in project.tilesets.where(
        (tile) => ids.contains(tile.id),
      )) {
        choices['ground:${tile.id}'] = (
          'Sol · ${tile.name}',
          SpatialAtmosphereMaterialTarget.groundTileset(tile.id),
        );
      }
    }
    for (final instance
        in map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = project.models3d
          .where((model) => model.id == instance.modelId)
          .firstOrNull;
      if (model == null) continue;
      for (final material in model.inspection.materials) {
        choices['${instance.id}:${material.name}'] = (
          '${model.name} · ${material.name} · ${instance.id}',
          SpatialAtmosphereMaterialTarget(
            instanceId: instance.id,
            materialName: material.name,
          ),
        );
      }
    }
    return choices;
  }

  ProjectModel3dEntry? modelOf(String instanceId) {
    final instance = map.spatialScene?.instances
        .where((item) => item.id == instanceId)
        .firstOrNull;
    if (instance == null) return null;
    return project?.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
  }

  List<SpatialAtmosphereMaterialTarget> instanceMaterials(String instanceId) =>
      [
        for (final material
            in modelOf(instanceId)?.inspection.materials ??
                const <Model3dMaterial>[])
          SpatialAtmosphereMaterialTarget(
            instanceId: instanceId,
            materialName: material.name,
          ),
      ];

  List<(String, SpatialAtmosphereMaterialTarget)> groundMaterials() {
    final ids = {
      for (final layer in map.layers.whereType<TileLayer>())
        for (final entry in layer.palette) entry.tilesetId,
    };
    return [
      for (final tile in project?.tilesets ?? const <ProjectTilesetEntry>[])
        if (ids.contains(tile.id))
          (tile.name, SpatialAtmosphereMaterialTarget.groundTileset(tile.id)),
    ];
  }

  bool number(
    String key,
    String text,
    double minimum,
    double maximum,
    SpatialAtmosphereSettings Function(double) update,
  ) {
    final number = double.tryParse(text.trim().replaceAll(',', '.'));
    if (number == null ||
        !number.isFinite ||
        number < minimum ||
        number > maximum) {
      controller.reject('Choisissez une valeur entre $minimum et $maximum.');
      return false;
    }
    try {
      controller.edit(update(number));
    } on FormatException {
      controller.reject(
        key.startsWith('fog-')
            ? 'La fin de la brume doit être plus éloignée que son début.'
            : 'Cette valeur est hors de la plage autorisée.',
      );
      return false;
    }
    return true;
  }

  bool zone(int index, String axis, String edge, String text) {
    final number = double.tryParse(text.trim().replaceAll(',', '.'));
    final limit = axis == 'x' ? map.size.width : map.size.height;
    if (number == null || !number.isFinite || number < 0 || number > limit) {
      controller.reject('La zone doit rester dans la carte (0–$limit).');
      return false;
    }
    final settings = controller.current;
    final old = settings.fireflyZones[index];
    final min = old.bounds.min, max = old.bounds.max;
    final nextMin = Model3dVector3(
      x: axis == 'x' && edge == 'min' ? number : min.x,
      y: min.y,
      z: axis == 'z' && edge == 'min' ? number : min.z,
    );
    final nextMax = Model3dVector3(
      x: axis == 'x' && edge == 'max' ? number : max.x,
      y: max.y,
      z: axis == 'z' && edge == 'max' ? number : max.z,
    );
    if (nextMin.x >= nextMax.x || nextMin.z >= nextMax.z) {
      controller.reject('La fin de la zone doit se trouver après son début.');
      return false;
    }
    final zones = [...settings.fireflyZones];
    zones[index] = SpatialAtmosphereFireflyZone(
      bounds: Model3dBounds(min: nextMin, max: nextMax),
      count: old.count,
      seed: old.seed,
    );
    controller.edit(settings.copyWith(fireflyZones: zones));
    return true;
  }

  int? addHalo(String id) {
    final settings = controller.current;
    if (settings.halos.length >= 32) {
      controller.reject('La carte peut contenir 32 halos au maximum.');
      return null;
    }
    final source = haloChoices[id];
    if (source == null) return null;
    final index = settings.halos.length;
    controller.edit(
      settings.copyWith(
        halos: [
          ...settings.halos,
          SpatialAtmosphereHalo(instanceId: id, localPosition: source.$2),
        ],
      ),
    );
    return index;
  }

  void addWater(SpatialAtmosphereMaterialTarget target) {
    final settings = controller.current;
    if (settings.waterTargets.any(
      (item) =>
          item.instanceId == target.instanceId &&
          item.materialName == target.materialName,
    )) {
      return;
    }
    controller.edit(
      settings.copyWith(waterTargets: [...settings.waterTargets, target]),
    );
  }

  void addWindow(SpatialAtmosphereMaterialTarget target) {
    final settings = controller.current;
    if (settings.windows.any(
      (item) =>
          item.target.instanceId == target.instanceId &&
          item.target.materialName == target.materialName,
    )) {
      return;
    }
    controller.edit(
      settings.copyWith(
        windows: [
          ...settings.windows,
          SpatialAtmosphereWindow(
            target: target,
            uvRects: [
              SpatialAtmosphereUvRect(left: 0, top: 0, right: 1, bottom: 1),
            ],
          ),
        ],
      ),
    );
  }

  void addFireflyZone() {
    controller.edit(
      controller.current.copyWith(
        fireflyZones: [
          SpatialAtmosphereFireflyZone(
            bounds: Model3dBounds(
              min: Model3dVector3(x: 0, y: .2, z: 0),
              max: Model3dVector3(
                x: map.size.width.toDouble(),
                y: 2.2,
                z: map.size.height.toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool removeWater(int index) {
    final settings = controller.current;
    if (index < 0 || index >= settings.waterTargets.length) return false;
    controller.edit(
      settings.copyWith(
        waterTargets: [...settings.waterTargets]..removeAt(index),
      ),
    );
    return true;
  }

  bool removeWindow(int index) {
    final settings = controller.current;
    if (index < 0 || index >= settings.windows.length) return false;
    controller.edit(
      settings.copyWith(windows: [...settings.windows]..removeAt(index)),
    );
    return true;
  }

  bool removeHalo(int index) {
    final settings = controller.current;
    if (index < 0 || index >= settings.halos.length) return false;
    controller.edit(
      settings.copyWith(halos: [...settings.halos]..removeAt(index)),
    );
    return true;
  }

  bool removeFireflyZone(int index) {
    final settings = controller.current;
    if (index < 0 || index >= settings.fireflyZones.length) return false;
    controller.edit(
      settings.copyWith(
        fireflyZones: [...settings.fireflyZones]..removeAt(index),
      ),
    );
    return true;
  }

  bool haloPosition(int index, String axis, String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value.abs() > 100000) {
      controller.reject('Choisissez une position valide.');
      return false;
    }
    final source = controller.current.halos[index];
    final p = source.localPosition;
    _replaceHalo(
      index,
      source,
      position: Model3dVector3(
        x: axis == 'x' ? value : p.x,
        y: axis == 'y' ? value : p.y,
        z: axis == 'z' ? value : p.z,
      ),
    );
    return true;
  }

  void haloWindow(int index, bool value) =>
      _replaceHalo(index, controller.current.halos[index], window: value);

  void _replaceHalo(
    int index,
    SpatialAtmosphereHalo source, {
    Model3dVector3? position,
    bool? window,
  }) {
    controller.edit(
      controller.current.copyWith(
        halos: [...controller.current.halos]
          ..[index] = SpatialAtmosphereHalo(
            instanceId: source.instanceId,
            localPosition: position ?? source.localPosition,
            radiusX: source.radiusX,
            radiusY: source.radiusY,
            opacity: source.opacity,
            colorRgb: source.colorRgb,
            window: window ?? source.window,
          ),
      ),
    );
  }
}
