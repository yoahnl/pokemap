import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'geometry.dart';

enum MovingPlatformMotion { forward, backward, rotateClockwise }

final class MovingPlatformPose {
  MovingPlatformPose({
    required num leftPx,
    required num topPx,
    required this.quarterTurns,
  }) : leftPx = leftPx.toDouble(),
       topPx = topPx.toDouble() {
    if (!this.leftPx.isFinite ||
        !this.topPx.isFinite ||
        this.leftPx < 0 ||
        this.topPx < 0 ||
        this.leftPx > 9007199254740991 ||
        topPx > 9007199254740991 ||
        quarterTurns < 0 ||
        quarterTurns > 3) {
      throw const FormatException('Invalid moving platform pose.');
    }
  }

  final double leftPx, topPx;
  final int quarterTurns;

  factory MovingPlatformPose.fromJson(Map<String, dynamic> json) {
    _keys(json, {'leftPx', 'topPx', 'quarterTurns'});
    return MovingPlatformPose(
      leftPx: _number(json, 'leftPx'),
      topPx: _number(json, 'topPx'),
      quarterTurns: _integer(json, 'quarterTurns'),
    );
  }

  Map<String, dynamic> toJson() => {
    'leftPx': leftPx,
    'topPx': topPx,
    'quarterTurns': quarterTurns,
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPlatformPose &&
      other.leftPx == leftPx &&
      other.topPx == topPx &&
      other.quarterTurns == quarterTurns;
  @override
  int get hashCode => Object.hash(leftPx, topPx, quarterTurns);
}

final class MovingPlatformLattice {
  MovingPlatformLattice({
    required num widthPx,
    required num heightPx,
    required num originLeftPx,
    required num originTopPx,
    required num cellOffsetLeftPx,
    required num cellOffsetTopPx,
  }) : widthPx = widthPx.toDouble(),
       heightPx = heightPx.toDouble(),
       originLeftPx = originLeftPx.toDouble(),
       originTopPx = originTopPx.toDouble(),
       cellOffsetLeftPx = cellOffsetLeftPx.toDouble(),
       cellOffsetTopPx = cellOffsetTopPx.toDouble() {
    if (![
          this.widthPx,
          this.heightPx,
          this.originLeftPx,
          this.originTopPx,
          this.cellOffsetLeftPx,
          this.cellOffsetTopPx,
        ].every((value) => value.isFinite && value.abs() < 1000000000) ||
        this.widthPx < 1 ||
        this.heightPx < 1 ||
        this.widthPx > 4096 ||
        this.heightPx > 4096) {
      throw const FormatException('Invalid moving platform lattice.');
    }
  }

  final double widthPx,
      heightPx,
      originLeftPx,
      originTopPx,
      cellOffsetLeftPx,
      cellOffsetTopPx;

  factory MovingPlatformLattice.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'widthPx',
      'heightPx',
      'originLeftPx',
      'originTopPx',
      'cellOffsetLeftPx',
      'cellOffsetTopPx',
    });
    return MovingPlatformLattice(
      widthPx: _number(json, 'widthPx'),
      heightPx: _number(json, 'heightPx'),
      originLeftPx: _number(json, 'originLeftPx'),
      originTopPx: _number(json, 'originTopPx'),
      cellOffsetLeftPx: _number(json, 'cellOffsetLeftPx'),
      cellOffsetTopPx: _number(json, 'cellOffsetTopPx'),
    );
  }

  Map<String, dynamic> toJson() => {
    'widthPx': widthPx,
    'heightPx': heightPx,
    'originLeftPx': originLeftPx,
    'originTopPx': originTopPx,
    'cellOffsetLeftPx': cellOffsetLeftPx,
    'cellOffsetTopPx': cellOffsetTopPx,
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPlatformLattice &&
      other.widthPx == widthPx &&
      other.heightPx == heightPx &&
      other.originLeftPx == originLeftPx &&
      other.originTopPx == originTopPx &&
      other.cellOffsetLeftPx == cellOffsetLeftPx &&
      other.cellOffsetTopPx == cellOffsetTopPx;
  @override
  int get hashCode => Object.hash(
    widthPx,
    heightPx,
    originLeftPx,
    originTopPx,
    cellOffsetLeftPx,
    cellOffsetTopPx,
  );
}

final class MovingPlatformVariant {
  MovingPlatformVariant({
    required this.elementId,
    required this.anchorOffsetPx,
    required List<GridPos> supportCells,
    required List<GridPos> clearanceCells,
    required List<GridPos> rotationClearanceCells,
    required List<GridPos> forwardClearanceCells,
    required List<GridPos> backwardClearanceCells,
  }) : supportCells = List.unmodifiable(supportCells),
       clearanceCells = List.unmodifiable(clearanceCells),
       rotationClearanceCells = List.unmodifiable(rotationClearanceCells),
       forwardClearanceCells = List.unmodifiable(forwardClearanceCells),
       backwardClearanceCells = List.unmodifiable(backwardClearanceCells) {
    _identity(elementId);
    _cells(this.supportCells, 4096, requireNonempty: true);
    _cells(this.clearanceCells, 4096, requireNonempty: true);
    _cells(this.rotationClearanceCells, 4096, requireNonempty: true);
    _cells(this.forwardClearanceCells, 4096, requireNonempty: true);
    _cells(this.backwardClearanceCells, 4096, requireNonempty: true);
    if (anchorOffsetPx.x < 0 || anchorOffsetPx.y < 0) {
      throw const FormatException(
        'Platform visual anchor must be nonnegative.',
      );
    }
  }

  final String elementId;
  final GridPos anchorOffsetPx;
  final List<GridPos> supportCells,
      clearanceCells,
      rotationClearanceCells,
      forwardClearanceCells,
      backwardClearanceCells;

  factory MovingPlatformVariant.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'elementId',
      'anchorOffsetPx',
      'supportCells',
      'clearanceCells',
      'rotationClearanceCells',
      'forwardClearanceCells',
      'backwardClearanceCells',
    });
    return MovingPlatformVariant(
      elementId: _identity(json['elementId']),
      anchorOffsetPx: _point(json['anchorOffsetPx']),
      supportCells: _points(json['supportCells']),
      clearanceCells: _points(json['clearanceCells']),
      rotationClearanceCells: _points(json['rotationClearanceCells']),
      forwardClearanceCells: _points(json['forwardClearanceCells']),
      backwardClearanceCells: _points(json['backwardClearanceCells']),
    );
  }

  Map<String, dynamic> toJson() => {
    'elementId': elementId,
    'anchorOffsetPx': anchorOffsetPx.toJson(),
    'supportCells': supportCells.map((value) => value.toJson()).toList(),
    'clearanceCells': clearanceCells.map((value) => value.toJson()).toList(),
    'rotationClearanceCells': rotationClearanceCells
        .map((value) => value.toJson())
        .toList(),
    'forwardClearanceCells': forwardClearanceCells
        .map((value) => value.toJson())
        .toList(),
    'backwardClearanceCells': backwardClearanceCells
        .map((value) => value.toJson())
        .toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPlatformVariant &&
      other.elementId == elementId &&
      other.anchorOffsetPx == anchorOffsetPx &&
      const DeepCollectionEquality().equals(other.supportCells, supportCells) &&
      const DeepCollectionEquality().equals(
        other.clearanceCells,
        clearanceCells,
      ) &&
      const DeepCollectionEquality().equals(
        other.rotationClearanceCells,
        rotationClearanceCells,
      ) &&
      const DeepCollectionEquality().equals(
        other.forwardClearanceCells,
        forwardClearanceCells,
      ) &&
      const DeepCollectionEquality().equals(
        other.backwardClearanceCells,
        backwardClearanceCells,
      );
  @override
  int get hashCode => Object.hash(
    elementId,
    anchorOffsetPx,
    const DeepCollectionEquality().hash(supportCells),
    const DeepCollectionEquality().hash(clearanceCells),
    const DeepCollectionEquality().hash(rotationClearanceCells),
    const DeepCollectionEquality().hash(forwardClearanceCells),
    const DeepCollectionEquality().hash(backwardClearanceCells),
  );
}

final class MovingPlatformDefinition {
  MovingPlatformDefinition({
    required this.id,
    required this.placedElementId,
    required this.initialPose,
    required this.translationDistanceCells,
    required this.lattice,
    required List<MovingPlatformVariant> variants,
    required Set<String> terrainLayerIds,
    required List<GridPos> travelCells,
  }) : variants = List.unmodifiable(variants),
       terrainLayerIds = Set.unmodifiable(terrainLayerIds),
       travelCells = List.unmodifiable(travelCells) {
    _identity(id);
    _identity(placedElementId);
    if (translationDistanceCells <= 0 ||
        translationDistanceCells > 256 ||
        this.variants.length != 4 ||
        this.terrainLayerIds.isEmpty) {
      throw const FormatException('Invalid moving platform definition.');
    }
    for (final value in this.terrainLayerIds) {
      _identity(value);
    }
    _cells(this.travelCells, 65536, requireNonempty: true);
  }

  final String id, placedElementId;
  final MovingPlatformPose initialPose;
  final MovingPlatformLattice lattice;
  final int translationDistanceCells;
  final List<MovingPlatformVariant> variants;
  final Set<String> terrainLayerIds;
  final List<GridPos> travelCells;

  factory MovingPlatformDefinition.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'id',
      'placedElementId',
      'initialPose',
      'lattice',
      'translationDistanceCells',
      'variants',
      'terrainLayerIds',
      'travelCells',
    });
    final variants = json['variants'];
    final layers = json['terrainLayerIds'];
    if (variants is! List ||
        layers is! List ||
        layers.toSet().length != layers.length) {
      throw const FormatException(
        'Invalid platform variants or terrain layers.',
      );
    }
    return MovingPlatformDefinition(
      id: _identity(json['id']),
      placedElementId: _identity(json['placedElementId']),
      initialPose: MovingPlatformPose.fromJson(_object(json['initialPose'])),
      lattice: MovingPlatformLattice.fromJson(_object(json['lattice'])),
      translationDistanceCells: _integer(json, 'translationDistanceCells'),
      variants: variants
          .map((value) => MovingPlatformVariant.fromJson(_object(value)))
          .toList(),
      terrainLayerIds: layers.map(_identity).toSet(),
      travelCells: _points(json['travelCells']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placedElementId': placedElementId,
    'initialPose': initialPose.toJson(),
    'lattice': lattice.toJson(),
    'translationDistanceCells': translationDistanceCells,
    'variants': variants.map((value) => value.toJson()).toList(),
    'terrainLayerIds': terrainLayerIds.toList()..sort(),
    'travelCells': travelCells.map((value) => value.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPlatformDefinition &&
      other.id == id &&
      other.placedElementId == placedElementId &&
      other.initialPose == initialPose &&
      other.lattice == lattice &&
      other.translationDistanceCells == translationDistanceCells &&
      const DeepCollectionEquality().equals(other.variants, variants) &&
      const DeepCollectionEquality().equals(
        other.terrainLayerIds,
        terrainLayerIds,
      ) &&
      const DeepCollectionEquality().equals(other.travelCells, travelCells);
  @override
  int get hashCode => Object.hash(
    id,
    placedElementId,
    initialPose,
    lattice,
    translationDistanceCells,
    const DeepCollectionEquality().hash(variants),
    const DeepCollectionEquality().hash(terrainLayerIds),
    const DeepCollectionEquality().hash(travelCells),
  );
}

final class MovingPlatformWorldState {
  const MovingPlatformWorldState.empty() : platformsByMap = const {};

  MovingPlatformWorldState({
    required Map<String, Map<String, MovingPlatformPose>> platformsByMap,
  }) : platformsByMap = Map.unmodifiable({
         for (final entry in platformsByMap.entries)
           _identity(entry.key): Map<String, MovingPlatformPose>.unmodifiable({
             for (final platform in entry.value.entries)
               _identity(platform.key): platform.value,
           }),
       });

  final Map<String, Map<String, MovingPlatformPose>> platformsByMap;

  MovingPlatformPose? platform(String mapId, String platformId) =>
      platformsByMap[mapId]?[platformId];

  MovingPlatformWorldState withPlatform({
    required String mapId,
    required String platformId,
    required MovingPlatformPose pose,
  }) => MovingPlatformWorldState(
    platformsByMap: {
      ...platformsByMap,
      mapId: {...?platformsByMap[mapId], platformId: pose},
    },
  );

  factory MovingPlatformWorldState.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'platformsByMap'});
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported moving platform state schema.');
    }
    return MovingPlatformWorldState(
      platformsByMap: _object(json['platformsByMap']).map(
        (key, value) => MapEntry(
          key,
          _object(value).map(
            (id, pose) =>
                MapEntry(id, MovingPlatformPose.fromJson(_object(pose))),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'platformsByMap': platformsByMap.map(
      (key, value) =>
          MapEntry(key, value.map((id, pose) => MapEntry(id, pose.toJson()))),
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is MovingPlatformWorldState &&
      const DeepCollectionEquality().equals(
        platformsByMap,
        other.platformsByMap,
      );
  @override
  int get hashCode => const DeepCollectionEquality().hash(platformsByMap);
}

void _keys(Map<String, dynamic> json, Set<String> keys) {
  if (json.keys.toSet().difference(keys).isNotEmpty ||
      keys.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Invalid moving platform fields.');
  }
}

String _identity(Object? value) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw const FormatException('Invalid moving platform identity.');
  }
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Invalid moving platform $key.');
  return value;
}

num _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid moving platform $key.');
  }
  return value;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected moving platform object.');
  }
  return value;
}

GridPos _point(Object? value) {
  final json = _object(value);
  _keys(json, {'x', 'y'});
  return GridPos(x: _integer(json, 'x'), y: _integer(json, 'y'));
}

List<GridPos> _points(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected moving platform cells.');
  }
  return value.map(_point).toList();
}

void _cells(List<GridPos> cells, int maximum, {required bool requireNonempty}) {
  if ((requireNonempty && cells.isEmpty) ||
      cells.length > maximum ||
      cells.map((cell) => (cell.x, cell.y)).toSet().length != cells.length ||
      cells.any((cell) => cell.x.abs() > 100000 || cell.y.abs() > 100000)) {
    throw const FormatException('Invalid moving platform cells.');
  }
}
