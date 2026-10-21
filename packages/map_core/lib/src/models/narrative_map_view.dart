import 'enums.dart';
import 'geometry.dart';
import 'map_data.dart';
import 'map_event_definition.dart';
import 'map_spatial_scene.dart';
import 'moving_platform.dart';
import 'moving_prop.dart';
import 'narrative_map_projection.dart';

abstract interface class NarrativeMapView {
  String get id;
  String get name;
  ProjectVersion get version;
  GridSize get size;
  MapSpatialScene? get spatialScene;
  List<MapEntity> get entities;
  List<MapTrigger> get triggers;
  List<MapEventDefinition> get events;
  List<MapWarp> get warps;
  List<MovingPropDefinition> get movingProps;
  List<MovingPlatformDefinition> get movingPlatforms;
  List<MapPlacedElement> get placedElements;
}

List<String> narrativeMapLayerIds(NarrativeMapView map) => switch (map) {
  MapData() => List.unmodifiable(map.layers.map((layer) => layer.id)),
  NarrativeMapProjection() => map.layerIds,
  _ => throw ArgumentError('Narrative map layers are unavailable.'),
};
