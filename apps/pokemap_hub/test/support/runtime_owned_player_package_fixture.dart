import 'dart:convert';

/// Compiled projection of the data-only runtime player fixture.
///
/// macOS integration-test applications are sandboxed and cannot read the
/// repository after launch. A parity test keeps these payloads byte-for-byte
/// aligned with `test/fixtures/runtime_owned_player_game`.
Map<String, List<int>> runtimeOwnedPlayerFixturePayload() => {
      'project/project.json': utf8.encode(_projectJson),
      'project/maps/runtime_harbor.json': utf8.encode(_mapJson),
    };

const _projectJson = '''{
  "name": "Les Îles Claires",
  "version": "v1",
  "maps": [
    {
      "id": "runtime_harbor",
      "name": "Port des Îles Claires",
      "relativePath": "maps/runtime_harbor.json",
      "role": "exterior",
      "sortOrder": 0
    }
  ],
  "tilesets": [],
  "shops": [
    {
      "id": "harbor_shop",
      "label": "Boutique du Rivage",
      "entries": [
        {
          "itemId": "potion",
          "price": 60,
          "stock": 3
        }
      ]
    }
  ],
  "scenes": [
    {
      "id": "scene_harbor_shop",
      "name": "Boutique du Rivage",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {
            "id": "start",
            "kind": "start",
            "payload": {
              "kind": "start"
            }
          },
          {
            "id": "service",
            "kind": "action",
            "payload": {
              "kind": "action",
              "parameters": {},
              "interactiveCommand": {
                "kind": "openShop",
                "shopId": "harbor_shop"
              }
            }
          },
          {
            "id": "end",
            "kind": "end",
            "payload": {
              "kind": "end"
            }
          }
        ],
        "edges": [
          {
            "id": "start-service",
            "fromNodeId": "start",
            "fromPortId": "completed",
            "toNodeId": "service",
            "kind": "default"
          },
          {
            "id": "service-completed",
            "fromNodeId": "service",
            "fromPortId": "completed",
            "toNodeId": "end",
            "kind": "actionCompleted"
          },
          {
            "id": "service-cancelled",
            "fromNodeId": "service",
            "fromPortId": "cancelled",
            "toNodeId": "end",
            "kind": "actionCompleted"
          }
        ]
      }
    },
    {
      "id": "scene_harbor_heal",
      "name": "Centre Pokémon",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {
            "id": "start",
            "kind": "start",
            "payload": {
              "kind": "start"
            }
          },
          {
            "id": "service",
            "kind": "action",
            "payload": {
              "kind": "action",
              "parameters": {},
              "interactiveCommand": {
                "kind": "openHeal",
                "requiresConfirmation": true
              }
            }
          },
          {
            "id": "end",
            "kind": "end",
            "payload": {
              "kind": "end"
            }
          }
        ],
        "edges": [
          {
            "id": "start-service",
            "fromNodeId": "start",
            "fromPortId": "completed",
            "toNodeId": "service",
            "kind": "default"
          },
          {
            "id": "service-completed",
            "fromNodeId": "service",
            "fromPortId": "completed",
            "toNodeId": "end",
            "kind": "actionCompleted"
          },
          {
            "id": "service-cancelled",
            "fromNodeId": "service",
            "fromPortId": "cancelled",
            "toNodeId": "end",
            "kind": "actionCompleted"
          }
        ]
      }
    }
  ],
  "newGame": {
    "enabled": true,
    "startMapId": "runtime_harbor",
    "startSpawnId": "runtime_spawn",
    "playerName": "Joueur",
    "startingMoney": 500,
    "initialBag": [],
    "initialParty": [],
    "initialFacts": {},
    "starterOptions": []
  },
  "settings": {
    "tileWidth": 16,
    "tileHeight": 16,
    "displayScale": 2,
    "defaultMapWidth": 5,
    "defaultMapHeight": 4
  }
}
''';

const _mapJson = '''{
  "id": "runtime_harbor",
  "name": "Port des Îles Claires",
  "size": {
    "width": 5,
    "height": 4
  },
  "version": "v1",
  "layers": [
    {
      "runtimeType": "object",
      "id": "events",
      "name": "Interactions"
    }
  ],
  "entities": [
    {
      "id": "runtime_spawn",
      "name": "Départ",
      "kind": "spawn",
      "pos": {
        "x": 1,
        "y": 2
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "north"
      }
    },
    {
      "id": "shop_counter",
      "name": "Comptoir de la boutique",
      "kind": "custom",
      "pos": {
        "x": 1,
        "y": 1
      },
      "blocksMovement": true
    },
    {
      "id": "healing_counter",
      "name": "Comptoir de soin",
      "kind": "custom",
      "pos": {
        "x": 3,
        "y": 2
      },
      "blocksMovement": true
    }
  ],
  "events": [
    {
      "id": "event_harbor_shop",
      "title": "Marchande du rivage",
      "type": "actor",
      "position": {
        "layerId": "events",
        "x": 1,
        "y": 1
      },
      "pages": [
        {
          "pageNumber": 0,
          "sceneTarget": {
            "sceneId": "scene_harbor_shop"
          }
        }
      ]
    },
    {
      "id": "event_harbor_heal",
      "title": "Infirmière du rivage",
      "type": "actor",
      "position": {
        "layerId": "events",
        "x": 3,
        "y": 2
      },
      "pages": [
        {
          "pageNumber": 0,
          "sceneTarget": {
            "sceneId": "scene_harbor_heal"
          }
        }
      ]
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "runtime_spawn"
  }
}
''';
