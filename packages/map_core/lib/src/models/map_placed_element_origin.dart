import 'map_data.dart';

const pokemapPlacementOriginProperty = 'pokemapPlacementOrigin';
const pokemapPlacementOriginAuthored = 'authored';
const pokemapPlacementOriginTileIndex = 'tile_index';
const pokemapPlacementOriginEnvironment = 'environment';

bool isAuthoredMapPlacedElement(MapPlacedElement instance) =>
    instance.properties[pokemapPlacementOriginProperty]?.trim() ==
    pokemapPlacementOriginAuthored;
