import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'model3d_ramp_profile.dart';

final class Model3dVector3 {
  Model3dVector3({required num x, required num y, required num z})
    : x = _finite(x, 'x'),
      y = _finite(y, 'y'),
      z = _finite(z, 'z');

  static final zero = Model3dVector3(x: 0, y: 0, z: 0);
  final double x;
  final double y;
  final double z;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model3dVector3 && other.x == x && other.y == y && other.z == z;
  @override
  int get hashCode => Object.hash(x, y, z);

  factory Model3dVector3.fromJson(Map<String, dynamic> json) {
    _keys(json, {'x', 'y', 'z'});
    return Model3dVector3(
      x: _number(json['x']),
      y: _number(json['y']),
      z: _number(json['z']),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

final class Model3dBounds {
  Model3dBounds({required this.min, required this.max}) {
    if (min.x > max.x || min.y > max.y || min.z > max.z) {
      throw const FormatException('Model bounds must be ordered.');
    }
  }

  final Model3dVector3 min;
  final Model3dVector3 max;
  Model3dVector3 get size =>
      Model3dVector3(x: max.x - min.x, y: max.y - min.y, z: max.z - min.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model3dBounds && other.min == min && other.max == max;
  @override
  int get hashCode => Object.hash(min, max);

  factory Model3dBounds.fromJson(Map<String, dynamic> json) {
    _keys(json, {'min', 'max'});
    return Model3dBounds(
      min: Model3dVector3.fromJson(_object(json['min'])),
      max: Model3dVector3.fromJson(_object(json['max'])),
    );
  }

  Map<String, dynamic> toJson() => {'min': min.toJson(), 'max': max.toJson()};
}

enum Model3dAlphaMode { opaque, mask, blend }

final class Model3dMaterial {
  Model3dMaterial({
    required this.index,
    required String name,
    this.alphaMode = Model3dAlphaMode.opaque,
    this.alphaCutoff,
    this.doubleSided = false,
  }) : name = _name(name) {
    if (index < 0) {
      throw const FormatException('Material index must be nonnegative.');
    }
    if (alphaMode == Model3dAlphaMode.mask
        ? alphaCutoff != .5
        : alphaCutoff != null) {
      throw const FormatException(
        'MASK requires an explicit alpha cutoff of 0.5.',
      );
    }
  }
  final int index;
  final String name;
  final Model3dAlphaMode alphaMode;
  final double? alphaCutoff;
  final bool doubleSided;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model3dMaterial &&
          other.index == index &&
          other.name == name &&
          other.alphaMode == alphaMode &&
          other.alphaCutoff == alphaCutoff &&
          other.doubleSided == doubleSided;
  @override
  int get hashCode =>
      Object.hash(index, name, alphaMode, alphaCutoff, doubleSided);

  factory Model3dMaterial.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'index',
      'name',
      if (json.containsKey('alphaMode')) 'alphaMode',
      if (json.containsKey('alphaCutoff')) 'alphaCutoff',
      if (json.containsKey('doubleSided')) 'doubleSided',
    });
    if (json.containsKey('doubleSided') && json['doubleSided'] is! bool) {
      throw const FormatException('Material doubleSided must be a boolean.');
    }
    return Model3dMaterial(
      index: _integer(json['index']),
      name: json['name'] as String,
      alphaMode: switch (json['alphaMode']) {
        null || 'opaque' => Model3dAlphaMode.opaque,
        'mask' => Model3dAlphaMode.mask,
        'blend' => Model3dAlphaMode.blend,
        _ => throw const FormatException('Unsupported model alpha mode.'),
      },
      alphaCutoff: json['alphaCutoff'] == null
          ? null
          : _finite(_number(json['alphaCutoff']), 'alphaCutoff'),
      doubleSided: json['doubleSided'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    if (alphaMode != Model3dAlphaMode.opaque) 'alphaMode': alphaMode.name,
    if (alphaCutoff != null) 'alphaCutoff': alphaCutoff,
    if (doubleSided) 'doubleSided': true,
  };
}

final class Model3dAnimation {
  Model3dAnimation({
    required this.index,
    required String name,
    required num durationSeconds,
  }) : name = _name(name),
       durationSeconds = _finite(durationSeconds, 'durationSeconds') {
    if (index < 0 || this.durationSeconds <= 0) {
      throw const FormatException('Animation index and duration are invalid.');
    }
  }
  final int index;
  final String name;
  final double durationSeconds;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model3dAnimation &&
          other.index == index &&
          other.name == name &&
          other.durationSeconds == durationSeconds;
  @override
  int get hashCode => Object.hash(index, name, durationSeconds);

  factory Model3dAnimation.fromJson(Map<String, dynamic> json) {
    _keys(json, {'index', 'name', 'durationSeconds'});
    return Model3dAnimation(
      index: _integer(json['index']),
      name: json['name'] as String,
      durationSeconds: _number(json['durationSeconds']),
    );
  }
  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'durationSeconds': durationSeconds,
  };
}

final class Model3dInspection {
  Model3dInspection({
    required this.bounds,
    required this.meshCount,
    required this.triangleCount,
    Iterable<Model3dMaterial> materials = const [],
    Iterable<Model3dAnimation> animations = const [],
    Iterable<String> diagnostics = const [],
  }) : materials = List.unmodifiable(materials),
       animations = List.unmodifiable(animations),
       diagnostics = List.unmodifiable(diagnostics) {
    if (meshCount <= 0 || triangleCount <= 0) {
      throw const FormatException('A model must contain triangle geometry.');
    }
    if (this.materials.map((v) => v.index).toSet().length !=
            this.materials.length ||
        this.animations.map((v) => v.index).toSet().length !=
            this.animations.length) {
      throw const FormatException('Inspected identities must be unique.');
    }
  }
  final Model3dBounds bounds;
  final int meshCount;
  final int triangleCount;
  final List<Model3dMaterial> materials;
  final List<Model3dAnimation> animations;
  final List<String> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model3dInspection &&
          other.bounds == bounds &&
          other.meshCount == meshCount &&
          other.triangleCount == triangleCount &&
          const DeepCollectionEquality().equals(other.materials, materials) &&
          const DeepCollectionEquality().equals(other.animations, animations) &&
          const DeepCollectionEquality().equals(other.diagnostics, diagnostics);
  @override
  int get hashCode => Object.hash(
    bounds,
    meshCount,
    triangleCount,
    const DeepCollectionEquality().hash(materials),
    const DeepCollectionEquality().hash(animations),
    const DeepCollectionEquality().hash(diagnostics),
  );

  factory Model3dInspection.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'schemaVersion',
      'bounds',
      'meshCount',
      'triangleCount',
      'materials',
      'animations',
      'diagnostics',
    });
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported model inspection version.');
    }
    return Model3dInspection(
      bounds: Model3dBounds.fromJson(_object(json['bounds'])),
      meshCount: _integer(json['meshCount']),
      triangleCount: _integer(json['triangleCount']),
      materials: (json['materials'] as List).map(
        (v) => Model3dMaterial.fromJson(_object(v)),
      ),
      animations: (json['animations'] as List).map(
        (v) => Model3dAnimation.fromJson(_object(v)),
      ),
      diagnostics: (json['diagnostics'] as List).cast<String>(),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'bounds': bounds.toJson(),
    'meshCount': meshCount,
    'triangleCount': triangleCount,
    'materials': materials.map((v) => v.toJson()).toList(),
    'animations': animations.map((v) => v.toJson()).toList(),
    'diagnostics': diagnostics,
  };
}

final class Model3dPointLight {
  Model3dPointLight({
    required this.localPosition,
    this.radius = 4,
    this.intensity = 1,
    this.colorRgb = 0xffd59a,
    this.nightOnly = true,
  }) {
    if (!radius.isFinite ||
        radius < .25 ||
        radius > 64 ||
        !intensity.isFinite ||
        intensity < 0 ||
        intensity > 4 ||
        colorRgb < 0 ||
        colorRgb > 0xffffff) {
      throw const FormatException('Invalid model point light.');
    }
  }

  final Model3dVector3 localPosition;
  final double radius, intensity;
  final int colorRgb;
  final bool nightOnly;

  Model3dPointLight copyWith({
    Model3dVector3? localPosition,
    double? radius,
    double? intensity,
    int? colorRgb,
    bool? nightOnly,
  }) => Model3dPointLight(
    localPosition: localPosition ?? this.localPosition,
    radius: radius ?? this.radius,
    intensity: intensity ?? this.intensity,
    colorRgb: colorRgb ?? this.colorRgb,
    nightOnly: nightOnly ?? this.nightOnly,
  );

  factory Model3dPointLight.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'localPosition',
      for (final field in ['radius', 'intensity', 'colorRgb', 'nightOnly'])
        if (json.containsKey(field)) field,
    });
    if (json.containsKey('nightOnly') && json['nightOnly'] is! bool) {
      throw const FormatException('Point light nightOnly must be boolean.');
    }
    return Model3dPointLight(
      localPosition: Model3dVector3.fromJson(_object(json['localPosition'])),
      radius: json.containsKey('radius')
          ? _number(json['radius']).toDouble()
          : 4,
      intensity: json.containsKey('intensity')
          ? _number(json['intensity']).toDouble()
          : 1,
      colorRgb: json.containsKey('colorRgb')
          ? _integer(json['colorRgb'])
          : 0xffd59a,
      nightOnly: json['nightOnly'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'localPosition': localPosition.toJson(),
    'radius': radius,
    'intensity': intensity,
    'colorRgb': colorRgb,
    'nightOnly': nightOnly,
  };
  @override
  bool operator ==(Object other) =>
      other is Model3dPointLight &&
      localPosition == other.localPosition &&
      radius == other.radius &&
      intensity == other.intensity &&
      colorRgb == other.colorRgb &&
      nightOnly == other.nightOnly;
  @override
  int get hashCode =>
      Object.hash(localPosition, radius, intensity, colorRgb, nightOnly);
}

final class ProjectModel3dEntry {
  ProjectModel3dEntry({
    required String id,
    required String name,
    required String sourceAssetId,
    required this.relativePath,
    required this.inspection,
    num scale = 1,
    Model3dVector3? pivot,
    this.collisionBounds,
    this.rampProfile,
    this.blocksMovementByDefault = true,
    this.castsShadowsByDefault = false,
    this.light,
  }) : id = _id(id),
       name = _name(name),
       sourceAssetId = _id(sourceAssetId, maximumLength: 160),
       scale = _finite(scale, 'scale'),
       pivot = pivot ?? Model3dVector3.zero {
    if (this.scale <= 0 || this.scale > 1000000) {
      throw const FormatException(
        'Model scale must be positive and at most 1000000.',
      );
    }
    if (relativePath != 'assets/models3d/${this.id}.glb') {
      throw const FormatException(
        'Model source must use its canonical project path.',
      );
    }
    final collisionSize = collisionBounds?.size;
    if (collisionSize != null &&
        (collisionSize.x <= 0 ||
            collisionSize.y <= 0 ||
            collisionSize.z <= 0)) {
      throw const FormatException('Model collision bounds must have volume.');
    }
  }
  final String id;
  final String name;
  final String sourceAssetId;
  final String relativePath;
  final Model3dInspection inspection;
  final double scale;
  final Model3dVector3 pivot;
  final Model3dBounds? collisionBounds;
  final Model3dRampProfile? rampProfile;
  final bool blocksMovementByDefault;
  final bool castsShadowsByDefault;
  final Model3dPointLight? light;

  ProjectModel3dEntry copyWith({
    String? name,
    num? scale,
    Model3dVector3? pivot,
    Model3dBounds? collisionBounds,
    bool clearCollisionBounds = false,
    Model3dRampProfile? rampProfile,
    bool clearRampProfile = false,
    bool? blocksMovementByDefault,
    bool? castsShadowsByDefault,
    Model3dPointLight? light,
    bool clearLight = false,
  }) => ProjectModel3dEntry(
    id: id,
    name: name ?? this.name,
    sourceAssetId: sourceAssetId,
    relativePath: relativePath,
    inspection: inspection,
    scale: scale ?? this.scale,
    pivot: pivot ?? this.pivot,
    collisionBounds: clearCollisionBounds
        ? null
        : collisionBounds ?? this.collisionBounds,
    rampProfile: clearRampProfile ? null : rampProfile ?? this.rampProfile,
    blocksMovementByDefault:
        blocksMovementByDefault ?? this.blocksMovementByDefault,
    castsShadowsByDefault: castsShadowsByDefault ?? this.castsShadowsByDefault,
    light: clearLight ? null : light ?? this.light,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel3dEntry &&
          other.id == id &&
          other.name == name &&
          other.sourceAssetId == sourceAssetId &&
          other.relativePath == relativePath &&
          other.inspection == inspection &&
          other.scale == scale &&
          other.pivot == pivot &&
          other.collisionBounds == collisionBounds &&
          other.rampProfile == rampProfile &&
          other.blocksMovementByDefault == blocksMovementByDefault &&
          other.castsShadowsByDefault == castsShadowsByDefault &&
          other.light == light;
  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceAssetId,
    relativePath,
    inspection,
    scale,
    pivot,
    collisionBounds,
    rampProfile,
    blocksMovementByDefault,
    castsShadowsByDefault,
    light,
  );

  factory ProjectModel3dEntry.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'id',
      'name',
      'sourceAssetId',
      'relativePath',
      'inspection',
      'scale',
      'pivot',
      if (json.containsKey('collisionBounds')) 'collisionBounds',
      if (json.containsKey('rampProfile')) 'rampProfile',
      if (json.containsKey('blocksMovementByDefault'))
        'blocksMovementByDefault',
      if (json.containsKey('castsShadowsByDefault')) 'castsShadowsByDefault',
      if (json.containsKey('light')) 'light',
    });
    if (json.containsKey('blocksMovementByDefault') &&
        json['blocksMovementByDefault'] is! bool) {
      throw const FormatException('Default movement blocking must be boolean.');
    }
    if (json.containsKey('castsShadowsByDefault') &&
        json['castsShadowsByDefault'] is! bool) {
      throw const FormatException('Default shadow casting must be boolean.');
    }
    return ProjectModel3dEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceAssetId: json['sourceAssetId'] as String,
      relativePath: json['relativePath'] as String,
      inspection: Model3dInspection.fromJson(_object(json['inspection'])),
      scale: _number(json['scale']),
      pivot: Model3dVector3.fromJson(_object(json['pivot'])),
      collisionBounds: json['collisionBounds'] == null
          ? null
          : Model3dBounds.fromJson(_object(json['collisionBounds'])),
      rampProfile: json['rampProfile'] == null
          ? null
          : Model3dRampProfile.fromJson(_object(json['rampProfile'])),
      blocksMovementByDefault: json['blocksMovementByDefault'] as bool? ?? true,
      castsShadowsByDefault: json['castsShadowsByDefault'] as bool? ?? false,
      light: json['light'] == null
          ? null
          : Model3dPointLight.fromJson(_object(json['light'])),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceAssetId': sourceAssetId,
    'relativePath': relativePath,
    'inspection': inspection.toJson(),
    'scale': scale,
    'pivot': pivot.toJson(),
    if (collisionBounds != null) 'collisionBounds': collisionBounds!.toJson(),
    if (rampProfile != null) 'rampProfile': rampProfile!.toJson(),
    if (!blocksMovementByDefault) 'blocksMovementByDefault': false,
    if (castsShadowsByDefault) 'castsShadowsByDefault': true,
    if (light != null) 'light': light!.toJson(),
  };
}

String _id(String value, {int maximumLength = 128}) {
  if (value.length > maximumLength ||
      !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
    throw const FormatException('Invalid model identity.');
  }
  return value;
}

String _name(String value) {
  final result = value.trim();
  if (result.isEmpty || result.length > 256) {
    throw const FormatException(
      'Model label must contain 1 to 256 characters.',
    );
  }
  return result;
}

double _finite(num value, String field) {
  if (!value.isFinite) throw FormatException('$field must be finite.');
  return value.toDouble();
}

num _number(Object? value) {
  if (value is! num) throw const FormatException('Expected a number.');
  return value;
}

int _integer(Object? value) {
  if (value is! int) throw const FormatException('Expected an integer.');
  return value;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object.');
  return Map<String, dynamic>.from(value);
}

void _keys(Map<String, dynamic> json, Set<String> keys) {
  if (json.keys.any((key) => !keys.contains(key)) ||
      keys.any((key) => !json.containsKey(key))) {
    throw const FormatException('Invalid model document fields.');
  }
}
