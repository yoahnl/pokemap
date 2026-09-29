import 'map_data.dart';
import 'map_layer.dart';

const pokemapPlacementOriginProperty = 'pokemapPlacementOrigin';
const pokemapPlacementOriginAuthored = 'authored';
const pokemapPlacementOriginTileIndex = 'tile_index';
const pokemapPlacementOriginEnvironment = 'environment';

bool isAuthoredMapPlacedElement(MapPlacedElement instance) =>
    instance.properties[pokemapPlacementOriginProperty]?.trim() ==
    pokemapPlacementOriginAuthored;

Set<String> environmentOwnedMapPlacedElementIds(MapData map) => {
      for (final layer in map.layers.whereType<EnvironmentLayer>())
        for (final area in layer.content.areas) ...area.generatedPlacementIds,
    };
