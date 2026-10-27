import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'enums.dart';
import 'exterior_decoration_border.dart';
import 'border_geometry.dart';
import 'border_value_objects.dart';
import 'geometry.dart';
import 'map_data.dart';
import 'map_layer.dart';
import 'map_spatial_scene.dart';
import 'smart_tile.dart';
import 'smart_tile_field.dart';
import 'spatial_navigation.dart';

final class ExteriorDecorationRect {
  ExteriorDecorationRect({
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
  }) {
    if (width <= 0 || depth <= 0) {
      throw const FormatException(
        'Exterior decoration bounds must be nonempty.',
      );
    }
  }

  final int x, z, width, depth;
  int get right => x + width;
  int get bottom => z + depth;

  bool contains(num px, num pz) =>
      px >= x && px < right && pz >= z && pz < bottom;

  bool containsRect(ExteriorDecorationRect other) =>
      other.x >= x &&
      other.z >= z &&
      other.right <= right &&
      other.bottom <= bottom;

  bool overlaps(ExteriorDecorationRect other) =>
      x < other.right &&
      right > other.x &&
      z < other.bottom &&
      bottom > other.z;

  @override
  bool operator ==(Object other) =>
      other is ExteriorDecorationRect &&
      x == other.x &&
      z == other.z &&
      width == other.width &&
      depth == other.depth;

  @override
  int get hashCode => Object.hash(x, z, width, depth);
}

final class MapExteriorDecoration {
  static const currentSchemaVersion = 1;
  static const capabilityId = 'map3d.exterior-decoration@1';
  static const maxMargin = 64;
  static const maxSectors = 256;
  static const maxBorders = 64;
  static const maxSectorSize = 32;
  static const maxInstances = 10000;
  static const maxResourceReferences = 1024;

  MapExteriorDecoration({
    this.schemaVersion = currentSchemaVersion,
    required this.mapId,
    required this.playableWidth,
    required this.playableDepth,
    this.west = 0,
    this.east = 0,
    this.north = 0,
    this.south = 0,
    Iterable<ExteriorDecorationSector> sectors = const [],
    Iterable<ExteriorDecorationBorder> borders = const [],
  }) : sectors = List.unmodifiable(sectors),
       borders = List.unmodifiable(borders) {
    _requireId(mapId, 'mapId');
    if (schemaVersion != currentSchemaVersion ||
        playableWidth < 1 ||
        playableWidth > 256 ||
        playableDepth < 1 ||
        playableDepth > 256 ||
        [
          west,
          east,
          north,
          south,
        ].any((value) => value < 0 || value > maxMargin) ||
        this.sectors.length > maxSectors ||
        this.borders.length > maxBorders) {
      throw const FormatException(
        'Invalid exterior decoration version, dimensions or quotas.',
      );
    }
    final ids = <String>{};
    final resources = <String>{};
    var instances = 0;
    for (var index = 0; index < this.sectors.length; index++) {
      final sector = this.sectors[index];
      instances += sector.scene.instances.length;
      resources.addAll(sector.resourceReferenceIds);
      if (!ids.add(sector.id) ||
          !outerBounds.containsRect(sector.bounds) ||
          instances > maxInstances ||
          resources.length > maxResourceReferences) {
        throw const FormatException(
          'Exterior decoration sector identity, bounds or instance quota is invalid.',
        );
      }
      for (var previous = 0; previous < index; previous++) {
        if (sector.bounds.overlaps(this.sectors[previous].bounds)) {
          throw const FormatException(
            'Exterior decoration sectors must not overlap.',
          );
        }
      }
    }
    final borderIds = <String>{};
    for (final border in this.borders) {
      resources.addAll(border.resourceReferenceIds);
      instances += border.instances.length;
      if (!borderIds.add(border.id) ||
          instances > maxInstances ||
          resources.length > maxResourceReferences ||
          !outerBounds.containsRect(
            ExteriorDecorationRect(
              x: border.originX,
              z: border.originZ,
              width: border.width,
              depth: border.depth,
            ),
          )) {
        throw const FormatException(
          'Logical exterior Border bounds, identity or shared quota is invalid.',
        );
      }
    }
  }

  final int schemaVersion;
  final String mapId;
  final int playableWidth, playableDepth;
  final int west, east, north, south;
  final List<ExteriorDecorationSector> sectors;
  final List<ExteriorDecorationBorder> borders;

  ExteriorDecorationRect get playableBounds => ExteriorDecorationRect(
    x: 0,
    z: 0,
    width: playableWidth,
    depth: playableDepth,
  );

  ExteriorDecorationRect get outerBounds => ExteriorDecorationRect(
    x: -west,
    z: -north,
    width: west + playableWidth + east,
    depth: north + playableDepth + south,
  );

  bool isExcluded(
    num x,
    num z, {
    Iterable<ExteriorDecorationRect> neighborBounds = const [],
  }) =>
      playableBounds.contains(x, z) ||
      neighborBounds.any((rect) => rect.contains(x, z));

  void validateForMap(MapData map) {
    if (map.id != mapId ||
        map.version != ProjectVersion.v9 ||
        map.size.width != playableWidth ||
        map.size.height != playableDepth ||
        map.spatialScene?.width != playableWidth ||
        map.spatialScene?.depth != playableDepth) {
      throw const FormatException(
        'Exterior decoration must reference its unchanged v9 playable map.',
      );
    }
  }

  static int compareVisualPriority(
    MapExteriorDecoration a,
    MapExteriorDecoration b,
  ) => a.mapId.compareTo(b.mapId);

  factory MapExteriorDecoration.fromJson(
    Map<String, dynamic> json,
  ) => _decode(() {
    const requiredKeys = {
      'schemaVersion',
      'mapId',
      'playableWidth',
      'playableDepth',
      'west',
      'east',
      'north',
      'south',
      'sectors',
    };
    _requireKnownKeys(json, {...requiredKeys, 'borders'});
    if (requiredKeys.any((key) => !json.containsKey(key))) {
      throw const FormatException(
        'Exterior decoration is missing required fields.',
      );
    }
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != currentSchemaVersion) {
      throw const FormatException('Unsupported exterior decoration version.');
    }
    final rawSectors = json['sectors'] as List;
    final rawBorders = json.containsKey('borders')
        ? json['borders'] as List
        : const [];
    if (rawSectors.length > maxSectors || rawBorders.length > maxBorders) {
      throw const FormatException('Exterior decoration sector quota exceeded.');
    }
    return MapExteriorDecoration(
      schemaVersion: json['schemaVersion'] as int,
      mapId: json['mapId'] as String,
      playableWidth: json['playableWidth'] as int,
      playableDepth: json['playableDepth'] as int,
      west: json['west'] as int,
      east: json['east'] as int,
      north: json['north'] as int,
      south: json['south'] as int,
      sectors: rawSectors.map(
        (value) => ExteriorDecorationSector.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
      borders: rawBorders.map(
        (value) => ExteriorDecorationBorder.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'mapId': mapId,
    'playableWidth': playableWidth,
    'playableDepth': playableDepth,
    'west': west,
    'east': east,
    'north': north,
    'south': south,
    'sectors': sectors.map((sector) => sector.toJson()).toList(),
    if (borders.isNotEmpty)
      'borders': borders.map((border) => border.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is MapExteriorDecoration &&
      schemaVersion == other.schemaVersion &&
      mapId == other.mapId &&
      playableWidth == other.playableWidth &&
      playableDepth == other.playableDepth &&
      west == other.west &&
      east == other.east &&
      north == other.north &&
      south == other.south &&
      const DeepCollectionEquality().equals(sectors, other.sectors) &&
      const DeepCollectionEquality().equals(borders, other.borders);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    mapId,
    playableWidth,
    playableDepth,
    west,
    east,
    north,
    south,
    const DeepCollectionEquality().hash(sectors),
    const DeepCollectionEquality().hash(borders),
  );
}

final class ExteriorDecorationSector {
  static const maxLayers = 64;

  ExteriorDecorationSector({
    required this.id,
    required this.originX,
    required this.originZ,
    required this.scene,
    Iterable<MapLayer> layers = const [],
  }) : layers = List.unmodifiable(layers) {
    _requireId(id, 'sector.id');
    if (scene.width > MapExteriorDecoration.maxSectorSize ||
        scene.depth > MapExteriorDecoration.maxSectorSize ||
        this.layers.length > maxLayers ||
        scene.navigation != SpatialNavigationProfile() ||
        scene.instances.any((instance) => instance.entityId != null)) {
      throw const FormatException(
        'Exterior sectors require bounded visual scenes without authored navigation or actors.',
      );
    }
    final ids = <String>{};
    for (final layer in this.layers) {
      _requireId(layer.id, 'layer.id');
      if (!ids.add(layer.id) ||
          !layer.opacity.isFinite ||
          layer.opacity < 0 ||
          layer.opacity > 1) {
        throw const FormatException(
          'Invalid exterior decoration layer identity or opacity.',
        );
      }
      switch (layer) {
        case SmartTileLayer():
          _validateSmartTile(layer, scene.width, scene.depth);
        case EnvironmentLayer():
          for (final area in layer.content.areas) {
            if (area.mask.width != scene.width ||
                area.mask.height != scene.depth) {
              throw const FormatException(
                'Exterior Environment masks must match their sector.',
              );
            }
          }
        case BorderLayer():
          for (final feature in layer.content.features) {
            switch (feature.geometry) {
              case BorderRegionGeometry geometry:
                if (geometry.width != scene.width ||
                    geometry.height != scene.depth) {
                  throw const FormatException(
                    'Exterior Border masks must match their sector.',
                  );
                }
              case BorderStrokeGeometry geometry:
                final edge =
                    geometry.alignment == BorderStrokeAlignment.gridEdges
                    ? 0
                    : 1;
                if (geometry.strokes.any(
                  (stroke) => stroke.points.any(
                    (point) =>
                        point.x < 0 ||
                        point.y < 0 ||
                        point.x > scene.width - edge ||
                        point.y > scene.depth - edge,
                  ),
                )) {
                  throw const FormatException(
                    'Exterior Border strokes must remain inside their sector.',
                  );
                }
            }
          }
          break;
        default:
          throw const FormatException(
            'Exterior decoration accepts only native Terrain, Path, Border and Environment layers.',
          );
      }
    }
    validateSpatialMapStructure(asVisualMap());
  }

  final String id;
  final int originX, originZ;
  final MapSpatialScene scene;
  final List<MapLayer> layers;

  late final Set<String> resourceReferenceIds = Set.unmodifiable({
    for (final instance in scene.instances) instance.modelId,
    if (scene.cliffFrame != null) scene.cliffFrame!.atlasId,
    for (final layer in layers)
      ...switch (layer) {
        SmartTileLayer() => {
          layer.presetId,
          ...layer.materialPalette.skip(1),
          for (final stroke in layer.patternStrokes) stroke.patternId,
        },
        EnvironmentLayer() => {
          for (final area in layer.content.areas) area.presetId,
        },
        BorderLayer() => {
          for (final feature in layer.content.features) feature.blueprintId,
        },
        _ => <String>{},
      },
  });

  ExteriorDecorationRect get bounds => ExteriorDecorationRect(
    x: originX,
    z: originZ,
    width: scene.width,
    depth: scene.depth,
  );

  MapData asVisualMap() => MapData(
    id: id,
    name: id,
    size: GridSize(width: scene.width, height: scene.depth),
    version: ProjectVersion.v9,
    spatialScene: scene,
    layers: layers,
  );

  factory ExteriorDecorationSector.fromJson(
    Map<String, dynamic> json,
  ) => _decode(() {
    _requireKeys(json, const {'id', 'originX', 'originZ', 'scene', 'layers'});
    final rawScene = Map<String, dynamic>.from(json['scene'] as Map);
    _requireKnownKeys(rawScene, const {
      'schemaVersion',
      'width',
      'depth',
      'heightLevels',
      'levelHeight',
      'cliffFrame',
      'generateCliffs',
      'instances',
      'camera',
      'dayNightCycle',
      'navigation',
      'terrainSurfaces',
    });
    if (rawScene['width'] is! int ||
        rawScene['depth'] is! int ||
        (rawScene['width'] as int) > MapExteriorDecoration.maxSectorSize ||
        (rawScene['depth'] as int) > MapExteriorDecoration.maxSectorSize ||
        (rawScene['instances'] as List).length >
            MapExteriorDecoration.maxInstances) {
      throw const FormatException(
        'Exterior decoration sector scene quota exceeded.',
      );
    }
    final rawNavigation = rawScene['navigation'];
    if (rawNavigation is Map) {
      _requireKnownKeys(Map<String, dynamic>.from(rawNavigation), const {
        'spawn',
        'allowDiagonalMovement',
        'ramps',
        'ledges',
        'blockedAreas',
      });
    }
    for (final raw in rawScene['instances'] as List) {
      _requireKnownKeys(Map<String, dynamic>.from(raw as Map), const {
        'id',
        'modelId',
        'position',
        'rotationDegrees',
        'scale',
        'animationIndex',
        'animationLoop',
        'animationSpeed',
        'blocksMovement',
        'castsShadows',
        'entityId',
        'clip',
      });
    }
    final rawLayers = json['layers'] as List;
    if (rawLayers.length > maxLayers) {
      throw const FormatException('Exterior decoration layer quota exceeded.');
    }
    final sector = ExteriorDecorationSector(
      id: json['id'] as String,
      originX: json['originX'] as int,
      originZ: json['originZ'] as int,
      scene: MapSpatialScene.fromJson(rawScene),
      layers: rawLayers.map((value) {
        final layer = Map<String, dynamic>.from(value as Map);
        final extraKeys = switch (layer['runtimeType']) {
          'smart_tile' => const {
            'presetId',
            'usage',
            'materialPalette',
            'field',
            'patternStrokes',
            'layerSeed',
            'candidateWeights',
            'animationActivation',
            'encounterBehavior',
          },
          'border' => const {'content', 'renderInForeground'},
          'environment' => const {'content'},
          _ => throw const FormatException(
            'Unsupported exterior decoration layer.',
          ),
        };
        _requireKnownKeys(layer, {
          'runtimeType',
          'id',
          'name',
          'isVisible',
          'opacity',
          'properties',
          ...extraKeys,
        });
        return MapLayer.fromJson(layer);
      }),
    );
    _requireRetainedKeys(json, sector.toJson());
    return sector;
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originX': originX,
    'originZ': originZ,
    'scene': scene.toJson(),
    'layers': layers.map((layer) => layer.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is ExteriorDecorationSector &&
      id == other.id &&
      originX == other.originX &&
      originZ == other.originZ &&
      scene == other.scene &&
      const DeepCollectionEquality().equals(layers, other.layers);

  @override
  int get hashCode => Object.hash(
    id,
    originX,
    originZ,
    scene,
    const DeepCollectionEquality().hash(layers),
  );
}

void _validateSmartTile(SmartTileLayer layer, int width, int depth) {
  if ((layer.usage != SmartTileUsage.terrain &&
          layer.usage != SmartTileUsage.path) ||
      layer.encounterBehavior != null ||
      layer.animationActivation != SmartTileAnimationActivation.always ||
      layer.presetId.trim().isEmpty ||
      layer.materialPalette.isEmpty ||
      layer.materialPalette.first != '' ||
      layer.materialPalette.toSet().length != layer.materialPalette.length ||
      layer.materialPalette
          .skip(1)
          .any((value) => value.trim().isEmpty || value != value.trim())) {
    throw const FormatException(
      'Exterior Smart Tile layers require visual terrain/path semantics and a valid palette.',
    );
  }
  final field = layer.field;
  final lattices = <(List<int>, int)>[
    (field.semanticCells, width * depth),
    if (field is SmartTileEdgeField) ...[
      (field.horizontalEdges, width * (depth + 1)),
      (field.verticalEdges, (width + 1) * depth),
    ],
    if (field is SmartTileCornerField)
      (field.corners, (width + 1) * (depth + 1)),
    if (field is SmartTileMixedField) ...[
      (field.horizontalEdges, width * (depth + 1)),
      (field.verticalEdges, (width + 1) * depth),
      (field.corners, (width + 1) * (depth + 1)),
    ],
  ];
  for (final (values, count) in lattices) {
    if (values.length != count ||
        values.any(
          (value) => value < 0 || value >= layer.materialPalette.length,
        )) {
      throw const FormatException(
        'Exterior Smart Tile lattice dimensions or material indices are invalid.',
      );
    }
  }
}

void _requireId(String value, String field) {
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value)) {
    throw FormatException('Invalid exterior decoration $field.');
  }
}

void _requireKnownKeys(Map<String, dynamic> json, Set<String> keys) {
  if (json.keys.any((key) => !keys.contains(key))) {
    throw const FormatException(
      'Unknown exterior decoration fields are not supported.',
    );
  }
}

void _requireKeys(Map<String, dynamic> json, Set<String> keys) {
  _requireKnownKeys(json, keys);
  if (keys.any((key) => !json.containsKey(key))) {
    throw const FormatException(
      'Exterior decoration is missing required fields.',
    );
  }
}

T _decode<T>(T Function() decode) {
  try {
    return decode();
  } on FormatException {
    rethrow;
  } on Object catch (error) {
    throw FormatException('Invalid exterior decoration document: $error');
  }
}

void _requireRetainedKeys(Object? raw, Object? canonical) {
  if (raw is Map && canonical is Map) {
    for (final entry in raw.entries) {
      if (!canonical.containsKey(entry.key)) {
        final value = entry.value;
        final supportedDefault =
            (const {
                  'cliffFrame',
                  'dayNightCycle',
                  'entityId',
                  'castsShadows',
                  'clip',
                  'animationIndex',
                  'encounterBehavior',
                }.contains(entry.key) &&
                value == null) ||
            (entry.key == 'generateCliffs' && value == true) ||
            (entry.key == 'renderInForeground' && value == false) ||
            (entry.key == 'ledges' && value is List && value.isEmpty) ||
            (entry.key == 'candidateWeights' && value is Map && value.isEmpty);
        if (!supportedDefault) {
          throw FormatException(
            'Unsupported exterior decoration field: ${entry.key}.',
          );
        }
      } else {
        _requireRetainedKeys(entry.value, canonical[entry.key]);
      }
    }
  } else if (raw is List && canonical is List) {
    if (raw.length != canonical.length) {
      throw const FormatException(
        'Exterior decoration arrays must be preserved.',
      );
    }
    for (var index = 0; index < raw.length; index++) {
      _requireRetainedKeys(raw[index], canonical[index]);
    }
  }
}
