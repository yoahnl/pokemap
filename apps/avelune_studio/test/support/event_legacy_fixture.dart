import 'package:map_core/map_core_domain.dart';

const historicalProject = ProjectManifest(
  name: 'Historique intact',
  maps: [
    ProjectMapEntry(
      id: 'old_station',
      name: 'Ancienne gare',
      relativePath: 'maps/station.json',
    ),
  ],
  tilesets: [],
  scenarios: [
    ScenarioAsset(
      id: 'old_arrival',
      name: 'Arrivée ancienne',
      entryNodeId: 'entry',
      nodes: [
        ScenarioNode(
          id: 'entry',
          type: ScenarioNodeType.reference,
          title: 'Entrée en gare',
          binding: ScenarioNodeBinding(mapId: 'old_station'),
          payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
        ),
      ],
    ),
  ],
);

const historicalMap = MapData(
  id: 'old_station',
  name: 'Ancienne gare',
  size: GridSize(width: 10, height: 10),
  layers: [MapLayer.object(id: 'events', name: 'Événements')],
  entities: [
    MapEntity(
      id: 'chief',
      name: 'Chef',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 3),
    ),
  ],
  events: [
    MapEventDefinition(
      id: 'old_greeting',
      title: 'Ancien accueil',
      position: EventPosition(layerId: 'events', x: 2, y: 3),
      metadata: {LegacyMapEventCompatibilityMetadataKeys.entityId: 'chief'},
      pages: [
        MapEventPage(
          pageNumber: 0,
          message: 'Bienvenue dans la gare historique.',
        ),
        MapEventPage(pageNumber: 1, message: 'Le train est arrivé.'),
      ],
    ),
  ],
);
