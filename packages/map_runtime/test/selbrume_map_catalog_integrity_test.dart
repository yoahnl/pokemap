import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectManifest manifest;

  setUpAll(() async {
    manifest = await SelbrumeMapTestFixture.loadManifest();
  });

  test('port catalog loads the active pilot and exact structural contracts',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_port_brisants',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_port_brisants.json');
    expect(entries.single.role, MapRole.exterior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    final map = bundle.map;
    expect(map.id, entries.single.id);
    expect(map.size, const GridSize(width: 45, height: 34));
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_tile_port_ref_base',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_port_ref_ground',
        'l_tile_port_ref_backdrop',
        'l_environment_port_ref_north',
        'l_tile_port_ref_overhead',
        'l_environment_port_ref_east',
        'l_tile_port_ref_structures',
        'l_collisions',
      ],
    );
    expect(map.layers[0], isA<TerrainLayer>());
    expect(map.layers[1], isA<TileLayer>());
    expect(map.layers[2], isA<PathLayer>());
    expect(map.layers[3], isA<PathLayer>());
    expect(map.layers[4], isA<TileLayer>());
    expect(map.layers[5], isA<TileLayer>());
    expect(map.layers[6], isA<EnvironmentLayer>());
    expect(map.layers[7], isA<TileLayer>());
    expect(map.layers[8], isA<EnvironmentLayer>());
    expect(map.layers[9], isA<TileLayer>());
    expect(map.layers[10], isA<CollisionLayer>());
    for (final layer in map.layers) {
      final cellCount = switch (layer) {
        TerrainLayer(:final terrains) => terrains.length,
        PathLayer(:final cells) => cells.length,
        TileLayer(:final tiles) => tiles.length,
        EnvironmentLayer(:final content) => content.areas.every(
            (area) => area.mask.cells.length == 45 * 34,
          )
              ? 45 * 34
              : -1,
        CollisionLayer(:final collisions) => collisions.length,
        _ => -1,
      };
      expect(cellCount, 45 * 34, reason: layer.id);
    }

    expect(() => MapValidator.validate(map, projectDialogueContext: manifest),
        returnsNormally);
    final zones = <String, MapGameplayZone>{
      for (final zone in map.gameplayZones) zone.id: zone,
    };
    expect(zones.keys,
        unorderedEquals(<String>['zone_port_entry', 'zone_port_center']));
    expect(
      zones['zone_port_entry']!.area,
      const MapRect(
        pos: GridPos(x: 26, y: 0),
        size: GridSize(width: 5, height: 4),
      ),
    );
    expect(
      zones['zone_port_center']!.area,
      const MapRect(
        pos: GridPos(x: 17, y: 10),
        size: GridSize(width: 14, height: 8),
      ),
    );
    for (final zone in zones.values) {
      expect(zone.kind, GameplayZoneKind.special);
      expect(zone.special?.scriptKey, isNull);
      expect(zone.special?.properties['inert'], 'true');
    }

    final triggerById = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    expect(
      triggerById.keys,
      unorderedEquals(<String>[
        'zone_port_entry',
        'zone_port_center',
        'tr_port_rival_scene',
        'tr_port_nest',
      ]),
    );
    expect(
      triggerById['zone_port_entry']?.properties['eventId'],
      'event_enter_port_alert',
    );
    expect(
      triggerById['zone_port_center']?.properties['eventId'],
      'event_ending_port',
    );

    final placedById = <String, MapPlacedElement>{
      for (final placed in map.placedElements) placed.id: placed,
    };
    expect(
        placedById.keys,
        containsAll(<String>[
          'pe_port_bateau',
          'pe_port_hangar',
        ]));
    expect(placedById['pe_port_bateau']!.pos, const GridPos(x: 0, y: 21));
    expect(placedById['pe_port_bateau']!.elementId, 'el_port_ref_boat_large');
    expect(placedById['pe_port_hangar']!.pos, const GridPos(x: 31, y: 11));
    expect(placedById['pe_port_hangar']!.elementId, 'el_port_ref_chandlery');
    expect(placedById, isNot(contains('pe_port_nid_goelise')));
    final entitiesById = <String, MapEntity>{
      for (final entity in map.entities) entity.id: entity,
    };
    expect(
      entitiesById.keys,
      unorderedEquals(<String>[
        'anchor_port_lysa',
        'anchor_port_soline',
        'anchor_port_pecheurs',
        'npc_lysa',
        'npc_soline',
        'npc_pecheur',
        'fog_port',
        'goelise_nest_proxy',
      ]),
    );
    _expectNarrativeNpc(
      map,
      id: 'npc_soline',
      pos: const GridPos(x: 39, y: 10),
      characterId: 'character_soline',
      dialogueId: 'dialogue_soline',
    );
    _expectNarrativeNpc(
      map,
      id: 'npc_pecheur',
      pos: const GridPos(x: 13, y: 17),
      characterId: 'character_pecheur',
      dialogueId: 'dialogue_goelise_port',
    );
    _expectWorldStateVisual(
      map,
      id: 'goelise_nest_proxy',
      pos: const GridPos(x: 7, y: 9),
      elementId: 'el_port_ref_nest',
    );
    _expectWorldStateVisual(
      map,
      id: 'fog_port',
      pos: const GridPos(x: 22, y: 11),
      elementId: 'el_selbrume_fx_brume_basse',
    );
    expect(map.events, isEmpty);
  });

  test('bourg catalog preserves the seed while adopting the canonical map',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_bourg_selbrume',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_bourg_selbrume.json');
    expect(entries.single.role, MapRole.exterior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 55, height: 55));
    expect(map.tilesetId, isEmpty);
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(map.mapMetadata.defaultSpawnId, 'spawn');
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_border_bordures',
        'l_tile_for_t',
        'l_environment_for_t',
        'l_path_path',
        'l_terrain',
        'l_path_ocean',
        'l_tile_maison',
      ],
    );
    expect(map.layers[0], isA<BorderLayer>());
    expect(map.layers[1], isA<TileLayer>());
    expect(map.layers[2], isA<EnvironmentLayer>());
    expect(map.layers[3], isA<PathLayer>());
    expect(map.layers[4], isA<TerrainLayer>());
    expect(map.layers[5], isA<PathLayer>());
    expect(map.layers[6], isA<TileLayer>());
    expect(
      map.layers.where((layer) => layer.id == 'l_tile_objectif'),
      isEmpty,
    );
    expect(
      map.placedElements.where(
        (placed) =>
            placed.layerId == 'l_tile_objectif' || placed.elementId == 'test',
      ),
      isEmpty,
    );
    expect(map.placedElements, hasLength(84));
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );

    final entitiesById = <String, MapEntity>{
      for (final entity in map.entities) entity.id: entity,
    };
    expect(
      entitiesById.keys,
      unorderedEquals(<String>[
        'spawn',
        'p6_03_intro_sign',
        'npc_mael',
        'npc',
        'gate_bourg_to_port',
        'gate_bourg_to_bois',
      ]),
    );
    expect(entitiesById['spawn']?.pos, const GridPos(x: 17, y: 24));
    expect(
      entitiesById['p6_03_intro_sign']?.pos,
      const GridPos(x: 22, y: 25),
    );
    expect(entitiesById['npc']?.pos, const GridPos(x: 34, y: 29));
    expect(entitiesById['npc']?.kind, MapEntityKind.custom);
    expect(entitiesById['npc']?.blocksMovement, isFalse);
    expect(entitiesById['npc']?.properties, <String, String>{
      'contractRole': 'canonical_map_generator_compatibility_anchor',
      'inert': 'true',
    });
    _expectNarrativeNpc(
      map,
      id: 'npc_mael',
      pos: const GridPos(x: 27, y: 20),
      characterId: 'mael',
      dialogueId: 'dialogue_mael_intro',
    );
    _expectRouteLock(
      map,
      id: 'gate_bourg_to_port',
      pos: const GridPos(x: 0, y: 54),
      size: const GridSize(width: 55, height: 1),
      visualElementId: 'el_selbrume_passage_barriere_fermee',
    );
    _expectRouteLock(
      map,
      id: 'gate_bourg_to_bois',
      pos: const GridPos(x: 54, y: 0),
      size: const GridSize(width: 1, height: 55),
      visualElementId: 'el_selbrume_bois_ronces',
    );

    _expectPlacement(
      map,
      id: 'pe_bourg_maison_joueur_facade',
      elementId: 'selbrum_maison_1',
      layerId: 'l_tile_maison',
      pos: const GridPos(x: 10, y: 18),
    );
    _expectPlacement(
      map,
      id: 'pe_bourg_centre_facade',
      elementId: 'selbrume_centre_pok_mon',
      layerId: 'l_tile_maison',
      pos: const GridPos(x: 29, y: 22),
    );
    _expectPlacement(
      map,
      id: 'pe_bourg_puits',
      elementId: 'le_puits',
      layerId: 'l_tile_maison',
      pos: const GridPos(x: 23, y: 27),
    );
    _expectPlacement(
      map,
      id: 'pe_bourg_kiosque',
      elementId: 'kiosque_l_gumes',
      layerId: 'l_tile_maison',
      pos: const GridPos(x: 36, y: 35),
    );
    expect(
      map.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_port_brisants',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_bois_chaise_brume',
        ),
      ]),
    );
    expect(map.warps, hasLength(1));
    final warp = map.warps.single;
    expect(warp.id, 'warp_bourg_to_maison');
    expect(warp.pos, const GridPos(x: 13, y: 23));
    expect(warp.targetMapId, 'map_maison_joueur');
    expect(warp.targetPos, const GridPos(x: 10, y: 13));
    expect(
      <String>{
        for (final connection in map.connections) connection.targetMapId,
        for (final mapWarp in map.warps) mapWarp.targetMapId,
      }.intersection(
        const <String>{'Selbrume', 'route 1', 'house 1', 'house 2', 'lab'},
      ),
      isEmpty,
    );
  });

  test('maison_joueur catalog exposes the exact player-house contract',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_maison_joueur',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_maison_joueur.json');
    expect(entries.single.role, MapRole.interior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_maison_joueur',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 20, height: 16));
    expect(map.tilesetId, isEmpty);
    expect(map.mapMetadata.isIndoor, isTrue);
    expect(map.mapMetadata.defaultSpawnId, isNull);
    _expectCanonicalInteriorLayers(
      map,
      tilesetId: 'ts_selbrume_cabin_interior',
      fxTilesetId: 'ts_selbrume_cabin_interior',
    );
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    _expectPlacement(
      map,
      id: 'pe_maison_lit',
      elementId: 'el_selbrume_maison_lit',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 2, y: 3),
    );
    _expectPlacement(
      map,
      id: 'pe_maison_bureau',
      elementId: 'el_selbrume_maison_bureau',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 14, y: 4),
    );
    final rug = _expectPlacement(
      map,
      id: 'pe_maison_tapis',
      elementId: 'el_selbrume_maison_tapis',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 8, y: 8),
    );
    expect(rug.applyCollision, isFalse);
    _expectPlacement(
      map,
      id: 'pe_maison_etagere',
      elementId: 'el_selbrume_cabane_etagere',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 16, y: 3),
    );
    final door = _expectPlacement(
      map,
      id: 'pe_maison_porte',
      elementId: 'el_selbrume_cabane_porte_principale',
      layerId: 'l_tile_walls',
      pos: const GridPos(x: 9, y: 13),
    );
    expect(door.applyCollision, isFalse);
    expect(
      map.placedElements.map((placed) => placed.layerId).toSet(),
      <String>{
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
      },
      reason: 'Player-house art must use its authored semantic layers.',
    );

    expect(map.entities, hasLength(1));
    final spawn = map.entities.single;
    expect(spawn.id, 'spawn_maison_joueur');
    expect(spawn.kind, MapEntityKind.spawn);
    expect(spawn.pos, const GridPos(x: 10, y: 11));
    expect(spawn.blocksMovement, isFalse);
    expect(map.gameplayZones, hasLength(1));
    final zone = map.gameplayZones.single;
    expect(zone.id, 'zone_player_house_exit');
    expect(zone.kind, GameplayZoneKind.special);
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 8, y: 12),
        size: GridSize(width: 5, height: 4),
      ),
    );
    expect(zone.special?.scriptKey, isNull);
    expect(zone.special?.properties['inert'], 'true');
    expect(map.triggers, hasLength(1));
    final trigger = map.triggers.single;
    expect(trigger.id, 'zone_player_house_exit');
    expect(trigger.type, TriggerType.custom);
    expect(
      trigger.area,
      const MapRect(
        pos: GridPos(x: 10, y: 13),
        size: GridSize(width: 1, height: 2),
      ),
    );
    expect(trigger.properties, <String, String>{
      'eventId': 'event_player_house_exit',
      'reservedForNarrative': 'true',
    });
    expect(map.events, isEmpty);
    expect(map.warps, hasLength(1));
    final warp = map.warps.single;
    expect(warp.id, 'warp_maison_to_bourg');
    expect(warp.pos, const GridPos(x: 10, y: 15));
    expect(warp.targetMapId, 'map_bourg_selbrume');
    expect(warp.targetPos, const GridPos(x: 13, y: 24));
  });

  test('cabane_gardien catalog exposes the exact Task15 cabin adaptation',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_cabane_gardien',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_cabane_gardien.json');
    expect(entries.single.role, MapRole.interior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_cabane_gardien',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 20, height: 16));
    expect(map.tilesetId, isEmpty);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task15');
    expect(map.mapMetadata.mapType, MapType.interior);
    expect(map.mapMetadata.isIndoor, isTrue);
    _expectCanonicalInteriorLayers(
      map,
      tilesetId: 'ts_selbrume_cabin_interior',
      fxTilesetId: 'ts_selbrume_cabin_interior',
    );
    expect(
      map.layers.whereType<CollisionLayer>().single.collisions,
      everyElement(isFalse),
    );
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(map.connections, isEmpty);
    expect(map.entities.map((entity) => entity.id), <String>[
      'gate_cabin_shortcut',
    ]);
    _expectRouteLock(
      map,
      id: 'gate_cabin_shortcut',
      pos: const GridPos(x: 19, y: 8),
      size: const GridSize(width: 1, height: 1),
    );
    expect(map.events, isEmpty);
    expect(map.gameplayZones, isEmpty);
    expect(map.placedElements, hasLength(50));
    expect(
      map.placedElements.map((placed) => placed.layerId).toSet(),
      <String>{
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
      },
    );
    expect(
      map.placedElements.map((placed) => placed.elementId),
      isNot(contains(anyOf(
        'el_selbrume_maison_lit',
        'el_selbrume_maison_bureau',
        'el_selbrume_maison_tapis',
      ))),
    );

    final placedById = <String, MapPlacedElement>{
      for (final placed in map.placedElements) placed.id: placed,
    };
    final table = placedById['pe_cabane_table']!;
    expect(table.elementId, 'el_selbrume_cabane_table_carnet_ferme');
    expect(table.pos, const GridPos(x: 6, y: 5));
    expect(table.opacity, 1);
    expect(table.applyCollision, isTrue);
    final journal = placedById['pe_cabane_journal']!;
    expect(journal.elementId, 'el_selbrume_cabane_table_carnet_ouvert');
    expect(journal.pos, table.pos);
    expect(journal.opacity, 0);
    expect(journal.applyCollision, isFalse);
    expect(journal.behaviors, isEmpty);
    expect(journal.properties, isEmpty);
    final key = placedById['pe_cabane_cle']!;
    expect(key.elementId, 'el_selbrume_cabane_cle');
    expect(key.pos, const GridPos(x: 14, y: 9));
    expect(key.applyCollision, isFalse);
    final secondaryDoor = placedById['pe_cabane_porte_secondaire']!;
    expect(
      secondaryDoor.elementId,
      'el_selbrume_cabane_porte_secondaire_fermee',
    );
    expect(secondaryDoor.pos, const GridPos(x: 18, y: 6));
    expect(secondaryDoor.applyCollision, isFalse);
    expect(
      map.placedElements.where(
        (placed) =>
            placed.elementId == 'el_selbrume_cabane_porte_secondaire_ouverte',
      ),
      isEmpty,
    );
    expect(
      map.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_cabane_to_phare_exterieur',
          pos: GridPos(x: 10, y: 15),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 8, y: 34),
        ),
        MapWarp(
          id: 'warp_cabane_to_passage',
          pos: GridPos(x: 19, y: 8),
          targetMapId: 'map_passage_dames',
          targetPos: GridPos(x: 50, y: 10),
        ),
      ],
    );
    expect(map.triggers, hasLength(1));
    final triggersById = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    expect(
      triggersById['tr_cabane_journal']?.area,
      const MapRect(
        pos: GridPos(x: 6, y: 5),
        size: GridSize(width: 2, height: 2),
      ),
    );
    expect(
      triggersById['tr_cabane_journal']?.properties,
      const <String, String>{
        'eventId': 'event_selbrume_cabane_journal',
        'reservedForNarrative': 'true',
      },
    );
    expect(triggersById, isNot(contains('tr_cabane_cle')));
    expect(
      manifest.groups
          .singleWhere((group) => group.id == 'group_selbrume_bourg')
          .properties['selbrumeGeneratorBoundary'],
      'task16',
    );
  });

  test('bois catalog exposes the exact forest map contract', () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_bois_chaise_brume',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_bois_chaise_brume.json');
    expect(entries.single.role, MapRole.exterior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 45, height: 45));
    expect(map.tilesetId, isEmpty);
    expect(map.mapMetadata.mapType, MapType.forest);
    expect(map.mapMetadata.weather, MapWeather.fog);
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task9');
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in map.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_forest_props');
    }
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(
      map.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bourg_selbrume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_marais_salants',
        ),
      ]),
    );
    expect(map.warps, isEmpty);
    expect(map.events, isEmpty);
    expect(map.triggers, isEmpty);
    expect(map.entities.map((entity) => entity.id), <String>[
      'gate_bois_to_marais',
    ]);
    _expectRouteLock(
      map,
      id: 'gate_bois_to_marais',
      pos: const GridPos(x: 44, y: 0),
      size: const GridSize(width: 1, height: 45),
      visualElementId: 'el_selbrume_bois_ronces',
    );

    const grassAreas = <String, MapRect>{
      'zone_bois_herbe_1': MapRect(
        pos: GridPos(x: 9, y: 8),
        size: GridSize(width: 8, height: 6),
      ),
      'zone_bois_herbe_2': MapRect(
        pos: GridPos(x: 26, y: 9),
        size: GridSize(width: 8, height: 7),
      ),
      'zone_bois_herbe_3': MapRect(
        pos: GridPos(x: 7, y: 29),
        size: GridSize(width: 10, height: 7),
      ),
      'zone_bois_herbe_4': MapRect(
        pos: GridPos(x: 27, y: 30),
        size: GridSize(width: 8, height: 6),
      ),
    };
    expect(
      map.gameplayZones.map((zone) => zone.id),
      unorderedEquals(grassAreas.keys),
    );
    for (final zone in map.gameplayZones) {
      expect(zone.area, grassAreas[zone.id]);
      expect(zone.kind, GameplayZoneKind.special);
      expect(zone.encounter, isNull);
      expect(zone.special?.scriptKey, isNull);
      expect(zone.special?.properties, <String, String>{
        'contractRole': 'tall_grass_surface',
        'inert': 'true',
      });
    }

    expect(
      map.placedElements.map((placed) => placed.elementId),
      unorderedEquals(<String>[
        'el_selbrume_bois_pin_grand',
        'el_selbrume_bois_pin_moyen',
        'el_selbrume_bois_pin_petit',
        'el_selbrume_bois_buisson_1',
        'el_selbrume_bois_buisson_2',
        'el_selbrume_bois_fougere',
        'el_selbrume_bois_souche',
        'el_selbrume_bois_tronc_tombe',
        'el_selbrume_bois_ronces',
        'el_selbrume_bois_aiguilles_sol',
        'el_selbrume_bois_banc',
        'el_selbrume_bois_panneau',
      ]),
    );
    _expectPlacement(
      map,
      id: 'pe_bois_pin_grand_001',
      elementId: 'el_selbrume_bois_pin_grand',
      layerId: 'l_tile_overhead',
      pos: const GridPos(x: 2, y: 2),
    );
    _expectPlacement(
      map,
      id: 'pe_bois_tronc_tombe_001',
      elementId: 'el_selbrume_bois_tronc_tombe',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 18, y: 36),
    );
    _expectPlacement(
      map,
      id: 'pe_bois_panneau_001',
      elementId: 'el_selbrume_bois_panneau',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 3, y: 21),
    );
  });

  test('marais catalog preserves encounters and exposes inert anchors',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_marais_salants',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_marais_salants.json');
    expect(entries.single.role, MapRole.exterior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 45, height: 45));
    expect(map.tilesetId, isEmpty);
    expect(map.mapMetadata.mapType, MapType.route);
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task10');
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in map.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_marsh_props');
    }
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(
      map.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bois_chaise_brume',
        ),
        const MapConnection(
          direction: MapConnectionDirection.south,
          targetMapId: 'map_passage_dames',
        ),
      ]),
    );
    expect(map.warps, isEmpty);
    expect(map.events, isEmpty);

    final entities = <String, MapEntity>{
      for (final entity in map.entities) entity.id: entity,
    };
    expect(
      entities.keys,
      unorderedEquals(<String>[
        'grant',
        'anchor_marais_mado',
        'clue_glass_object',
        'npc_mado',
        'gate_marais_to_passage',
        'clue_electric_object',
        'clue_lens_object',
        'crystal_1_object',
        'crystal_2_object',
        'crystal_3_object',
        'fog_marais',
      ]),
    );
    final grant = entities['grant']!;
    expect(grant.kind, MapEntityKind.npc);
    expect(grant.pos, const GridPos(x: 24, y: 20));
    expect(grant.size, const GridSize(width: 2, height: 2));
    expect(grant.npc?.trainerId, 'grant');
    expect(grant.npc?.dialogue, isNull);
    final mado = entities['anchor_marais_mado']!;
    expect(mado.kind, MapEntityKind.custom);
    expect(mado.pos, const GridPos(x: 10, y: 12));
    expect(mado.blocksMovement, isFalse);
    expect(mado.npc, isNull);
    expect(mado.properties, <String, String>{
      'contractRole': 'reserved_character_anchor',
      'inert': 'true',
    });
    _expectNarrativeNpc(
      map,
      id: 'npc_mado',
      pos: const GridPos(x: 10, y: 12),
      characterId: 'character_mado',
      dialogueId: 'dialogue_mado',
    );
    _expectRouteLock(
      map,
      id: 'gate_marais_to_passage',
      pos: const GridPos(x: 0, y: 44),
      size: const GridSize(width: 45, height: 1),
      visualElementId: 'el_selbrume_passage_barriere_fermee',
    );
    for (final contract in const <(String, GridPos, String)>[
      (
        'clue_glass_object',
        GridPos(x: 8, y: 32),
        'el_selbrume_indice_verre',
      ),
      (
        'clue_electric_object',
        GridPos(x: 32, y: 10),
        'el_selbrume_indice_traces_electriques',
      ),
      (
        'clue_lens_object',
        GridPos(x: 34, y: 34),
        'el_selbrume_indice_repere_lentille',
      ),
      (
        'crystal_1_object',
        GridPos(x: 14, y: 7),
        'el_selbrume_cristal_1',
      ),
      (
        'crystal_2_object',
        GridPos(x: 24, y: 28),
        'el_selbrume_cristal_2',
      ),
      (
        'crystal_3_object',
        GridPos(x: 38, y: 22),
        'el_selbrume_cristal_3',
      ),
      (
        'fog_marais',
        GridPos(x: 20, y: 20),
        'el_selbrume_fx_brume_basse',
      ),
    ]) {
      _expectWorldStateVisual(
        map,
        id: contract.$1,
        pos: contract.$2,
        elementId: contract.$3,
      );
    }

    const encounterAreas = <String, MapRect>{
      'zone': MapRect(
        pos: GridPos(x: 1, y: 27),
        size: GridSize(width: 2, height: 8),
      ),
      'zone_1': MapRect(
        pos: GridPos(x: 3, y: 27),
        size: GridSize(width: 3, height: 6),
      ),
      'zone_2': MapRect(
        pos: GridPos(x: 4, y: 28),
        size: GridSize(width: 3, height: 8),
      ),
      'zone_3': MapRect(
        pos: GridPos(x: 7, y: 31),
        size: GridSize(width: 5, height: 3),
      ),
      'zone_4': MapRect(
        pos: GridPos(x: 10, y: 32),
        size: GridSize(width: 3, height: 2),
      ),
    };
    final zones = <String, MapGameplayZone>{
      for (final zone in map.gameplayZones) zone.id: zone,
    };
    expect(
      zones.keys,
      unorderedEquals(<String>[...encounterAreas.keys, 'zone_marais_entry']),
    );
    for (final contract in encounterAreas.entries) {
      final zone = zones[contract.key]!;
      expect(zone.name, contract.key);
      expect(zone.kind, GameplayZoneKind.encounter);
      expect(zone.area, contract.value);
      expect(zone.encounter?.encounterTableId, 'grass_path_route_1');
    }
    final entryZone = zones['zone_marais_entry']!;
    expect(entryZone.kind, GameplayZoneKind.special);
    expect(
      entryZone.area,
      const MapRect(
        pos: GridPos(x: 0, y: 22),
        size: GridSize(width: 5, height: 7),
      ),
    );
    expect(entryZone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });

    const triggerEvents = <String, String>{
      'zone_marais_entry': 'event_marais_entry',
      'tr_marais_indice_verre': 'event_selbrume_indice_verre',
      'tr_marais_indice_traces_electriques':
          'event_selbrume_indice_traces_electriques',
      'tr_marais_indice_repere_lentille':
          'event_selbrume_indice_repere_lentille',
      'tr_marais_cristal_1': 'event_selbrume_cristal_1',
      'tr_marais_cristal_2': 'event_selbrume_cristal_2',
      'tr_marais_cristal_3': 'event_selbrume_cristal_3',
    };
    final triggers = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    expect(triggers.keys, unorderedEquals(triggerEvents.keys));
    for (final contract in triggerEvents.entries) {
      expect(triggers[contract.key]?.type, TriggerType.custom);
      expect(triggers[contract.key]?.properties['eventId'], contract.value);
      expect(
        triggers[contract.key]?.properties['reservedForNarrative'],
        'true',
      );
    }

    _expectPlacement(
      map,
      id: 'pe_marais_cabane_paludier',
      elementId: 'el_selbrume_marais_cabane_paludier',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 4, y: 14),
    );
    _expectPlacement(
      map,
      id: 'pe_marais_ecluse',
      elementId: 'el_selbrume_marais_ecluse_fermee',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 27, y: 18),
    );
    _expectPlacement(
      map,
      id: 'pe_marais_indice_verre',
      elementId: 'el_selbrume_indice_verre',
      layerId: 'l_tile_ground',
      pos: const GridPos(x: 8, y: 32),
    );
  });

  test('passage catalog exposes the static causeway contract', () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_passage_dames',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_passage_dames.json');
    expect(entries.single.role, MapRole.connector);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 60, height: 24));
    expect(map.tilesetId, isEmpty);
    expect(map.mapMetadata.mapType, MapType.route);
    expect(map.mapMetadata.weather, MapWeather.fog);
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task11');
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in map.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_passage_props');
    }
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(
      map.connections,
      unorderedEquals(<MapConnection>[
        const MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_marais_salants',
        ),
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_phare_exterieur',
        ),
      ]),
    );
    expect(map.warps, isEmpty);
    expect(map.events, isEmpty);
    expect(
      map.entities.map((entity) => entity.id),
      unorderedEquals(<String>['gate_passage_to_phare', 'fog_passage']),
    );
    _expectRouteLock(
      map,
      id: 'gate_passage_to_phare',
      pos: const GridPos(x: 59, y: 0),
      size: const GridSize(width: 1, height: 24),
      visualElementId: 'el_selbrume_passage_barriere_fermee',
    );
    _expectWorldStateVisual(
      map,
      id: 'fog_passage',
      pos: const GridPos(x: 28, y: 8),
      elementId: 'el_selbrume_fx_brume_basse',
    );
    expect(map.gameplayZones, hasLength(1));
    final zone = map.gameplayZones.single;
    expect(zone.id, 'zone_passage_entry');
    expect(zone.kind, GameplayZoneKind.special);
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 28, y: 0),
        size: GridSize(width: 9, height: 5),
      ),
    );
    expect(zone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });
    expect(map.triggers, hasLength(1));
    final trigger = map.triggers.single;
    expect(trigger.id, 'zone_passage_entry');
    expect(trigger.type, TriggerType.custom);
    expect(trigger.area, zone.area);
    expect(trigger.properties, <String, String>{
      'eventId': 'event_enter_passage_dames',
      'reservedForNarrative': 'true',
    });

    _expectPlacement(
      map,
      id: 'pe_passage_barriere',
      elementId: 'el_selbrume_passage_barriere_fermee',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 32, y: 3),
    );
    _expectPlacement(
      map,
      id: 'pe_passage_marches',
      elementId: 'el_selbrume_passage_marches',
      layerId: 'l_tile_ground',
      pos: const GridPos(x: 56, y: 13),
    );
    _expectPlacement(
      map,
      id: 'pe_passage_flaques',
      elementId: 'el_selbrume_passage_flaques',
      layerId: 'l_tile_ground',
      pos: const GridPos(x: 49, y: 9),
    );
    expect(
      map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_passage_chaussee_humide',
        'el_selbrume_passage_chaussee_seche',
        'el_selbrume_passage_ecume_h',
        'el_selbrume_passage_ecume_v',
        'el_selbrume_passage_algues',
        'el_selbrume_passage_balanes',
        'el_selbrume_passage_bois_flotte',
        'el_selbrume_passage_banc_brume',
      ]),
    );
  });

  test('phare_exterieur catalog exposes landmarks approaches and warps',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_phare_exterieur',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_phare_exterieur.json');
    expect(entries.single.role, MapRole.exterior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 45, height: 45));
    expect(map.tilesetId, isEmpty);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task12');
    expect(map.mapMetadata.mapType, MapType.building);
    expect(map.mapMetadata.weather, MapWeather.fog);
    expect(map.mapMetadata.isIndoor, isFalse);
    expect(
      map.layers.map((layer) => layer.id),
      <String>[
        'l_terrain',
        'l_path_primary',
        'l_path_secondary',
        'l_tile_ground',
        'l_tile_structures',
        'l_tile_overhead',
        'l_tile_fx',
        'l_collisions',
      ],
    );
    for (final layer in map.layers.whereType<TileLayer>()) {
      expect(layer.tilesetId, 'ts_selbrume_lighthouse_exterior');
    }
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(
      map.connections,
      const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_passage_dames',
        ),
      ],
    );
    expect(
      map.warps,
      unorderedEquals(const <MapWarp>[
        MapWarp(
          id: 'warp_phare_ext_to_interieur',
          pos: GridPos(x: 23, y: 18),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 42),
        ),
        MapWarp(
          id: 'warp_phare_ext_to_cabane',
          pos: GridPos(x: 8, y: 33),
          targetMapId: 'map_cabane_gardien',
          targetPos: GridPos(x: 10, y: 13),
        ),
      ]),
    );
    expect(map.events, isEmpty);
    expect(
      map.entities.map((entity) => entity.id),
      unorderedEquals(<String>[
        'npc_yvon',
        'gate_cabin_door',
        'cabin_key_object',
        'fog_phare',
      ]),
    );
    _expectNarrativeNpc(
      map,
      id: 'npc_yvon',
      pos: const GridPos(x: 10, y: 12),
      characterId: 'character_yvon',
      dialogueId: 'dialogue_yvon_cabin',
    );
    _expectRouteLock(
      map,
      id: 'gate_cabin_door',
      pos: const GridPos(x: 8, y: 33),
      size: const GridSize(width: 1, height: 1),
    );
    _expectWorldStateVisual(
      map,
      id: 'cabin_key_object',
      pos: const GridPos(x: 14, y: 28),
      elementId: 'el_selbrume_cabane_cle',
    );
    _expectWorldStateVisual(
      map,
      id: 'fog_phare',
      pos: const GridPos(x: 22, y: 22),
      elementId: 'el_selbrume_fx_brume_basse',
    );
    expect(map.gameplayZones, hasLength(1));
    final zone = map.gameplayZones.single;
    expect(zone.id, 'zone_lighthouse_entry');
    expect(zone.kind, GameplayZoneKind.special);
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 0, y: 10),
        size: GridSize(width: 8, height: 8),
      ),
    );
    expect(zone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });
    expect(map.triggers, hasLength(2));
    final triggersById = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    expect(triggersById['zone_lighthouse_entry']?.area, zone.area);
    expect(triggersById['zone_lighthouse_entry']?.properties, <String, String>{
      'eventId': 'event_lighthouse_exterior_arrival',
      'reservedForNarrative': 'true',
    });
    expect(
      triggersById['tr_cabin_key_outside']?.area,
      const MapRect(
        pos: GridPos(x: 14, y: 28),
        size: GridSize(width: 1, height: 1),
      ),
    );
    expect(
      triggersById['tr_cabin_key_outside']?.properties,
      <String, String>{
        'eventId': 'event_selbrume_cabin_key_outside',
        'reservedForNarrative': 'true',
      },
    );

    _expectPlacement(
      map,
      id: 'pe_phare_batiment',
      elementId: 'el_selbrume_phare_batiment',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 19, y: 8),
    );
    _expectPlacement(
      map,
      id: 'pe_phare_cabane_facade',
      elementId: 'el_selbrume_cabane_facade',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 6, y: 28),
    );
    _expectPlacement(
      map,
      id: 'pe_phare_porte_ouverte',
      elementId: 'el_selbrume_phare_porte_ouverte',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 22, y: 16),
    );
    _expectPlacement(
      map,
      id: 'pe_phare_cabane_porte_ouverte',
      elementId: 'el_selbrume_cabane_porte_ouverte',
      layerId: 'l_tile_structures',
      pos: const GridPos(x: 7, y: 32),
    );
  });

  test('phare_interieur catalog exposes the short dungeon contract', () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_phare_interieur',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_phare_interieur.json');
    expect(entries.single.role, MapRole.interior);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 36, height: 45));
    expect(map.tilesetId, isEmpty);
    expect(
      map.properties['selbrumeGeneratorBoundary'],
      anyOf('task13', 'task14'),
    );
    expect(map.mapMetadata.mapType, MapType.interior);
    expect(map.mapMetadata.isIndoor, isTrue);
    _expectCanonicalInteriorLayers(
      map,
      tilesetId: 'ts_selbrume_lighthouse_interior',
      fxTilesetId: 'ts_selbrume_lighthouse_fx',
    );
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(map.connections, isEmpty);
    expect(map.events, isEmpty);
    expect(map.entities.map((entity) => entity.id), <String>[
      'gate_lighthouse_top',
    ]);
    _expectRouteLock(
      map,
      id: 'gate_lighthouse_top',
      pos: const GridPos(x: 18, y: 1),
      size: const GridSize(width: 1, height: 1),
      visualElementId: 'el_selbrume_fx_lumiere_instable',
    );
    expect(
      map.warps,
      unorderedEquals(const <MapWarp>[
        MapWarp(
          id: 'warp_phare_interieur_to_exterieur',
          pos: GridPos(x: 18, y: 44),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 23, y: 19),
        ),
        MapWarp(
          id: 'warp_phare_interieur_to_sommet',
          pos: GridPos(x: 18, y: 1),
          targetMapId: 'map_sommet_phare',
          targetPos: GridPos(x: 12, y: 22),
        ),
      ]),
    );
    final zones = <String, MapGameplayZone>{
      for (final zone in map.gameplayZones) zone.id: zone,
    };
    expect(
        zones.keys,
        unorderedEquals(<String>[
          'zone_lighthouse_floor_1',
          'zone_lighthouse_top_access',
        ]));
    expect(
      zones['zone_lighthouse_floor_1']?.area,
      const MapRect(
        pos: GridPos(x: 6, y: 32),
        size: GridSize(width: 24, height: 11),
      ),
    );
    expect(
      zones['zone_lighthouse_top_access']?.area,
      const MapRect(
        pos: GridPos(x: 14, y: 0),
        size: GridSize(width: 8, height: 4),
      ),
    );
    for (final zone in zones.values) {
      expect(zone.kind, GameplayZoneKind.special);
      expect(zone.special?.properties['inert'], 'true');
    }
    expect(map.triggers, hasLength(3));
    final triggersById = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    final noteTrigger = triggersById['tr_phare_note']!;
    expect(noteTrigger.id, 'tr_phare_note');
    expect(
      noteTrigger.area,
      const MapRect(
        pos: GridPos(x: 10, y: 24),
        size: GridSize(width: 2, height: 2),
      ),
    );
    expect(
      noteTrigger.properties['eventId'],
      'event_selbrume_phare_note_ancien_gardien',
    );
    expect(
      triggersById['tr_phare_guardian_1']?.area,
      const MapRect(
        pos: GridPos(x: 7, y: 32),
        size: GridSize(width: 2, height: 2),
      ),
    );
    expect(
      triggersById['tr_phare_guardian_2']?.area,
      const MapRect(
        pos: GridPos(x: 24, y: 14),
        size: GridSize(width: 2, height: 2),
      ),
    );

    _expectPlacement(
      map,
      id: 'pe_phare_note_ancien_gardien',
      elementId: 'el_selbrume_phare_bureau_note',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 10, y: 24),
    );
    _expectPlacement(
      map,
      id: 'pe_phare_mecanisme',
      elementId: 'el_selbrume_phare_mecanisme',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 25, y: 23),
    );
    final up = _expectPlacement(
      map,
      id: 'pe_phare_escalier_haut',
      elementId: 'el_selbrume_phare_escalier_haut',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 17, y: 0),
    );
    final down = _expectPlacement(
      map,
      id: 'pe_phare_escalier_bas',
      elementId: 'el_selbrume_phare_escalier_bas',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 17, y: 42),
    );
    final trapdoor = _expectPlacement(
      map,
      id: 'pe_phare_trappe',
      elementId: 'el_selbrume_phare_trappe',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 28, y: 29),
    );
    expect(up.applyCollision, isFalse);
    expect(down.applyCollision, isFalse);
    expect(trapdoor.applyCollision, isFalse);
  });

  test('sommet catalog exposes exact hosts reservations and initial off state',
      () async {
    final entries = manifest.maps.where(
      (entry) => entry.id == 'map_sommet_phare',
    );
    expect(entries, hasLength(1));
    expect(entries.single.relativePath, 'maps/map_sommet_phare.json');
    expect(entries.single.role, MapRole.upper_floor);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_sommet_phare',
    );
    final map = bundle.map;
    expect(map.size, const GridSize(width: 24, height: 24));
    expect(map.tilesetId, isEmpty);
    expect(map.properties['selbrumeGeneratorBoundary'], 'task14');
    expect(map.mapMetadata.mapType, MapType.interior);
    expect(map.mapMetadata.isIndoor, isTrue);
    _expectCanonicalInteriorLayers(
      map,
      tilesetId: 'ts_selbrume_lighthouse_interior',
      fxTilesetId: 'ts_selbrume_lighthouse_fx',
    );
    expect(
      map.layers.whereType<CollisionLayer>().single.collisions,
      everyElement(isFalse),
    );
    expect(
      () => MapValidator.validate(map, projectDialogueContext: manifest),
      returnsNormally,
    );
    expect(map.connections, isEmpty);
    expect(map.events, isEmpty);
    expect(
      map.entities.map((entity) => entity.id),
      unorderedEquals(<String>['boss_phare_pokemon', 'fog_sommet']),
    );
    _expectWorldStateVisual(
      map,
      id: 'boss_phare_pokemon',
      pos: const GridPos(x: 12, y: 10),
      elementId: 'el_selbrume_fx_lumiere_instable',
      blocksMovement: true,
    );
    _expectWorldStateVisual(
      map,
      id: 'fog_sommet',
      pos: const GridPos(x: 12, y: 12),
      elementId: 'el_selbrume_fx_brume_basse',
    );
    expect(
      map.warps,
      const <MapWarp>[
        MapWarp(
          id: 'warp_sommet_to_phare_interieur',
          pos: GridPos(x: 12, y: 23),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 2),
        ),
      ],
    );
    expect(map.gameplayZones, hasLength(1));
    final zone = map.gameplayZones.single;
    expect(zone.id, 'zone_lighthouse_top');
    expect(zone.kind, GameplayZoneKind.special);
    expect(
      zone.area,
      const MapRect(
        pos: GridPos(x: 7, y: 5),
        size: GridSize(width: 10, height: 10),
      ),
    );
    expect(zone.special?.scriptKey, isNull);
    expect(zone.special?.properties, <String, String>{
      'contractRole': 'navigation_anchor',
      'inert': 'true',
    });
    final triggers = <String, MapTrigger>{
      for (final trigger in map.triggers) trigger.id: trigger,
    };
    expect(
      triggers.keys,
      unorderedEquals(<String>[
        'tr_sommet_confrontation',
        'tr_lighthouse_top',
      ]),
    );
    expect(
      triggers['tr_sommet_confrontation']?.area,
      const MapRect(
        pos: GridPos(x: 12, y: 10),
        size: GridSize(width: 1, height: 1),
      ),
    );
    expect(
      triggers['tr_sommet_confrontation']?.properties['eventId'],
      'event_selbrume_sommet_confrontation',
    );
    expect(triggers['tr_lighthouse_top']?.area, zone.area);
    expect(
      triggers['tr_lighthouse_top']?.properties['eventId'],
      'event_final_pokemon_scene',
    );
    for (final trigger in triggers.values) {
      expect(trigger.type, TriggerType.custom);
      expect(trigger.properties['reservedForNarrative'], 'true');
    }

    final platform = _expectPlacement(
      map,
      id: 'pe_sommet_plateforme',
      elementId: 'el_selbrume_sommet_plateforme',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 9, y: 7),
    );
    final lantern = _expectPlacement(
      map,
      id: 'pe_sommet_lanterne',
      elementId: 'el_selbrume_sommet_lanterne',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 10, y: 0),
    );
    final trapdoor = _expectPlacement(
      map,
      id: 'pe_sommet_trappe',
      elementId: 'el_selbrume_phare_trappe',
      layerId: 'l_tile_floor',
      pos: const GridPos(x: 11, y: 22),
    );
    _expectPlacement(
      map,
      id: 'pe_sommet_mecanisme',
      elementId: 'el_selbrume_phare_mecanisme',
      layerId: 'l_tile_furniture',
      pos: const GridPos(x: 17, y: 15),
    );
    final off = _expectPlacement(
      map,
      id: 'pe_sommet_lumiere_eteinte',
      elementId: 'el_selbrume_fx_lumiere_eteinte',
      layerId: 'l_tile_fx',
      pos: const GridPos(x: 10, y: 0),
    );
    expect(platform.applyCollision, isFalse);
    expect(lantern.applyCollision, isTrue);
    expect(trapdoor.applyCollision, isFalse);
    expect(off.applyCollision, isFalse);
    expect(
      map.placedElements.where(
        (placed) => placed.elementId == 'el_selbrume_sommet_parapet_h',
      ),
      hasLength(8),
    );
    expect(
      map.placedElements.where(
        (placed) => placed.elementId == 'el_selbrume_sommet_parapet_v',
      ),
      hasLength(10),
    );
    expect(
      map.placedElements
          .where((placed) => placed.elementId.startsWith('el_selbrume_fx_'))
          .map((placed) => placed.elementId),
      <String>['el_selbrume_fx_lumiere_eteinte'],
    );
  });

  test('declares every Selbrume beta map exactly once in the active catalog',
      () {
    for (final mapId in SelbrumeMapTestFixture.allBetaMapIds) {
      final entries = manifest.maps.where((entry) => entry.id == mapId);
      expect(
        entries,
        hasLength(1),
        reason: 'Missing or duplicate Selbrume map manifest entry: $mapId',
      );
    }

    expect(
      manifest.maps.map((entry) => entry.id),
      unorderedEquals(SelbrumeMapTestFixture.allBetaMapIds),
      reason: 'The active map catalog must contain only the ten beta maps.',
    );
  });

  test(
    'loads every catalog map through loadRuntimeMapBundle and MapValidator',
    () async {
      final mapsRoot = SelbrumeMapTestFixture.mapsDirectoryPath;
      final projectRoot = SelbrumeMapTestFixture.projectRoot.path;

      for (final mapId in SelbrumeMapTestFixture.allBetaMapIds) {
        final entries = manifest.maps.where((entry) => entry.id == mapId);
        expect(
          entries,
          hasLength(1),
          reason: 'Missing or duplicate Selbrume map manifest entry: $mapId',
        );
        final entry = entries.single;
        final relativePath = entry.relativePath.trim();
        final absolutePath = p.normalize(p.join(projectRoot, relativePath));

        // Containment is checked on normalized absolute paths so a seemingly
        // maps/-prefixed path cannot escape through `..` segments.
        expect(relativePath, isNotEmpty, reason: '$mapId has an empty path.');
        expect(
          p.isAbsolute(relativePath),
          isFalse,
          reason: '$mapId must use a project-relative map path.',
        );
        expect(
          p.isWithin(mapsRoot, absolutePath),
          isTrue,
          reason: '$mapId escapes the project maps/ directory: $relativePath',
        );
        expect(
          File(absolutePath).existsSync(),
          isTrue,
          reason: '$mapId points to a missing map file: $absolutePath',
        );

        final bundle = await loadRuntimeMapBundle(
          projectFilePath: SelbrumeMapTestFixture.projectFilePath,
          mapId: mapId,
        );
        expect(
          bundle.map.id,
          entry.id,
          reason: 'Manifest ID and MapData.id differ for $relativePath.',
        );
        expect(
          bundle.map.size,
          SelbrumeMapTestFixture.expectedDimensions[mapId],
          reason: '$mapId has drifted from its planned beta dimensions.',
        );
        expect(
          () => MapValidator.validate(
            bundle.map,
            projectDialogueContext: bundle.manifest,
          ),
          returnsNormally,
          reason: '$mapId must pass MapValidator with its real project.',
        );
      }
    },
  );

  test('keeps required zones, narrative placements, and landmarks stable',
      () async {
    final bundles = await SelbrumeMapTestFixture.loadAllBetaBundles();

    // These are required-ID subset contracts, not exact-total contracts. Beta
    // maps intentionally keep additional encounter zones and decorative placed
    // elements; every required ID must simply be present without duplicates.
    for (final requirement
        in SelbrumeMapTestFixture.requiredZoneIdsByMap.entries) {
      final map = bundles[requirement.key]!.map;
      for (final zoneId in requirement.value) {
        expect(
          map.gameplayZones.where((zone) => zone.id == zoneId),
          hasLength(1),
          reason: '${requirement.key} must contain zone $zoneId exactly once.',
        );
      }
    }

    for (final requirement
        in SelbrumeMapTestFixture.requiredNarrativePlacedIdsByMap.entries) {
      final map = bundles[requirement.key]!.map;
      for (final placedId in requirement.value) {
        expect(
          map.placedElements.where((placed) => placed.id == placedId),
          hasLength(1),
          reason:
              '${requirement.key} must contain narrative placement $placedId exactly once.',
        );
      }
    }

    for (final requirement
        in SelbrumeMapTestFixture.requiredNarrativeEntityIdsByMap.entries) {
      final map = bundles[requirement.key]!.map;
      for (final entityId in requirement.value) {
        expect(
          map.entities.where((entity) => entity.id == entityId),
          hasLength(1),
          reason:
              '${requirement.key} must contain narrative entity $entityId exactly once.',
        );
      }
    }

    for (final mapRequirement
        in SelbrumeMapTestFixture.allowedElementIdsByLandmarkByMap.entries) {
      final map = bundles[mapRequirement.key]!.map;
      for (final landmarkRequirement in mapRequirement.value.entries) {
        final matches = map.placedElements
            .where((placed) => placed.id == landmarkRequirement.key)
            .toList(growable: false);
        expect(
          matches,
          hasLength(1),
          reason:
              '${mapRequirement.key} must contain landmark ${landmarkRequirement.key} exactly once.',
        );
        expect(
          landmarkRequirement.value,
          contains(matches.single.elementId),
          reason: '${landmarkRequirement.key} must reference one of its '
              'approved element-family members.',
        );
      }
    }
  });

  test('allows only the frozen legacy JSON files outside the active catalog',
      () {
    expect(
      manifest.maps.where(
        (entry) => entry.id == SelbrumeMapTestFixture.startMapId,
      ),
      hasLength(1),
      reason: 'Legacy cutover checks require canonical map_bourg_selbrume.',
    );
    final projectRoot = SelbrumeMapTestFixture.projectRoot.path;
    final referencedPaths = manifest.maps
        .map(
          (entry) =>
              p.normalize(p.join(projectRoot, entry.relativePath.trim())),
        )
        .toSet();
    expect(
      () => _validateLegacyMapFiles(
        mapsDirectory: Directory(
          SelbrumeMapTestFixture.mapsDirectoryPath,
        ),
        referencedAbsolutePaths: referencedPaths,
        expectedLegacyFileNames:
            SelbrumeMapTestFixture.allowedLegacyMapFileNames,
      ),
      returnsNormally,
    );
  });

  test('rejects a missing expected legacy map file', () {
    final temp = Directory.systemTemp.createTempSync(
      'selbrume_missing_legacy_',
    );
    addTearDown(() => temp.delete(recursive: true));

    expect(
      () => _validateLegacyMapFiles(
        mapsDirectory: temp,
        referencedAbsolutePaths: const <String>{},
        expectedLegacyFileNames: const <String>{'Selbrume.json'},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('Selbrume.json'), contains('missing')),
        ),
      ),
    );
  });

  test('accepts the decomposed spelling of a frozen Unicode legacy filename',
      () {
    final temp = Directory.systemTemp.createTempSync(
      'selbrume_decomposed_legacy_',
    );
    addTearDown(() => temp.delete(recursive: true));
    File(p.join(temp.path, 'poke\u0301mon center.json'))
        .writeAsStringSync('{}');

    expect(
      () => _validateLegacyMapFiles(
        mapsDirectory: temp,
        referencedAbsolutePaths: const <String>{},
        expectedLegacyFileNames: const <String>{'pokémon center.json'},
      ),
      returnsNormally,
    );
  });

  test('rejects an unreferenced JSON outside the legacy allowlist', () {
    final temp = Directory.systemTemp.createTempSync(
      'selbrume_unexpected_legacy_',
    );
    addTearDown(() => temp.delete(recursive: true));
    File(p.join(temp.path, 'unexpected.json')).writeAsStringSync('{}');

    expect(
      () => _validateLegacyMapFiles(
        mapsDirectory: temp,
        referencedAbsolutePaths: const <String>{},
        expectedLegacyFileNames: const <String>{},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('unexpected.json'), contains('Unexpected')),
        ),
      ),
    );
  });

  test('rejects an active map path that references a legacy allowlist file',
      () {
    final temp = Directory.systemTemp.createTempSync(
      'selbrume_active_legacy_overlap_',
    );
    addTearDown(() => temp.delete(recursive: true));
    final legacy = File(p.join(temp.path, 'Selbrume.json'))
      ..writeAsStringSync('{}');

    expect(
      () => _validateLegacyMapFiles(
        mapsDirectory: temp,
        referencedAbsolutePaths: <String>{p.normalize(legacy.absolute.path)},
        expectedLegacyFileNames: const <String>{'Selbrume.json'},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('Selbrume.json'), contains('active map')),
        ),
      ),
    );
  });
}

MapPlacedElement _expectPlacement(
  MapData map, {
  required String id,
  required String elementId,
  required String layerId,
  required GridPos pos,
}) {
  final matches = map.placedElements.where((placed) => placed.id == id);
  expect(matches, hasLength(1));
  final placed = matches.single;
  expect(placed.elementId, elementId);
  expect(placed.layerId, layerId);
  expect(placed.pos, pos);
  return placed;
}

MapEntity _expectNarrativeNpc(
  MapData map, {
  required String id,
  required GridPos pos,
  required String characterId,
  required String dialogueId,
}) {
  final matches = map.entities.where((entity) => entity.id == id);
  expect(matches, hasLength(1));
  final entity = matches.single;
  expect(entity.kind, MapEntityKind.npc, reason: '${map.id}/$id');
  expect(entity.pos, pos, reason: '${map.id}/$id');
  expect(entity.size, const GridSize(width: 1, height: 1));
  expect(entity.blocksMovement, isTrue, reason: '${map.id}/$id');
  expect(entity.npc?.characterId, characterId, reason: '${map.id}/$id');
  expect(
    entity.npc?.dialogue?.dialogueId,
    dialogueId,
    reason: '${map.id}/$id',
  );
  expect(entity.properties, const <String, String>{
    'contractRole': 'selbrume_canonical_narrative_source',
  });
  return entity;
}

MapEntity _expectRouteLock(
  MapData map, {
  required String id,
  required GridPos pos,
  required GridSize size,
  String? visualElementId,
}) {
  final matches = map.entities.where((entity) => entity.id == id);
  expect(matches, hasLength(1));
  final entity = matches.single;
  expect(entity.kind, MapEntityKind.sign, reason: '${map.id}/$id');
  expect(entity.pos, pos, reason: '${map.id}/$id');
  expect(entity.size, size, reason: '${map.id}/$id');
  expect(entity.blocksMovement, isTrue, reason: '${map.id}/$id');
  expect(entity.sign?.plainText.trim(), isNotEmpty, reason: '${map.id}/$id');
  expect(entity.editorVisual?.elementId, visualElementId);
  expect(entity.properties, const <String, String>{
    'contractRole': 'selbrume_route_lock',
    'unlockProjection': 'world_rule_entity_hidden',
  });
  return entity;
}

MapEntity _expectWorldStateVisual(
  MapData map, {
  required String id,
  required GridPos pos,
  required String elementId,
  bool blocksMovement = false,
}) {
  final matches = map.entities.where((entity) => entity.id == id);
  expect(matches, hasLength(1));
  final entity = matches.single;
  expect(entity.kind, MapEntityKind.custom, reason: '${map.id}/$id');
  expect(entity.pos, pos, reason: '${map.id}/$id');
  expect(entity.size, const GridSize(width: 1, height: 1));
  expect(entity.blocksMovement, blocksMovement, reason: '${map.id}/$id');
  expect(entity.editorVisual?.elementId, elementId, reason: '${map.id}/$id');
  expect(entity.properties, const <String, String>{
    'contractRole': 'selbrume_world_state_visual',
  });
  return entity;
}

void _expectCanonicalInteriorLayers(
  MapData map, {
  required String tilesetId,
  required String fxTilesetId,
}) {
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_tile_floor',
    'l_tile_walls',
    'l_tile_furniture',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  expect(map.layers.map((layer) => layer.id), expectedLayerIds);
  expect(map.layers.first, isA<TerrainLayer>());
  for (var index = 1; index <= 5; index += 1) {
    expect(map.layers[index], isA<TileLayer>(),
        reason: '${map.id}/${expectedLayerIds[index]}');
  }
  expect(map.layers.last, isA<CollisionLayer>());
  expect(map.properties['tileLayerOrder'], 'bottom_to_top');

  final expectedCellCount = map.size.width * map.size.height;
  for (final layer in map.layers) {
    final cellCount = switch (layer) {
      TerrainLayer(:final terrains) => terrains.length,
      TileLayer(:final tiles) => tiles.length,
      CollisionLayer(:final collisions) => collisions.length,
      _ => -1,
    };
    expect(cellCount, expectedCellCount, reason: '${map.id}/${layer.id}');
    if (layer
        case TileLayer(
          :final id,
          tilesetId: final layerTilesetId,
          :final tiles,
        )) {
      expect(
        layerTilesetId,
        id == 'l_tile_fx' ? fxTilesetId : tilesetId,
        reason: '${map.id}/$id',
      );
      expect(tiles, everyElement(0), reason: '${map.id}/$id');
    }
  }
}

void _validateLegacyMapFiles({
  required Directory mapsDirectory,
  required Set<String> referencedAbsolutePaths,
  required Set<String> expectedLegacyFileNames,
}) {
  final mapJsonFiles = mapsDirectory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => p.extension(file.path).toLowerCase() == '.json')
      .toList(growable: false);
  final canonicalExpectedFileNames =
      expectedLegacyFileNames.map(_canonicalLegacyFileName).toSet();
  final expectedLegacyPaths = <String>{
    for (final fileName in canonicalExpectedFileNames)
      p.normalize(p.join(mapsDirectory.absolute.path, fileName)),
  };
  final canonicalReferencedPaths =
      referencedAbsolutePaths.map(_canonicalLegacyPath).toSet();
  final activeLegacyPaths =
      canonicalReferencedPaths.intersection(expectedLegacyPaths);
  if (activeLegacyPaths.isNotEmpty) {
    throw StateError(
      'Legacy allowlist files must not be referenced by an active map entry: '
      '$activeLegacyPaths',
    );
  }

  final existingCanonicalFileNames = mapJsonFiles
      .map((file) => _canonicalLegacyFileName(p.basename(file.path)))
      .toSet();
  for (final fileName in expectedLegacyFileNames) {
    if (!existingCanonicalFileNames.contains(
      _canonicalLegacyFileName(fileName),
    )) {
      throw StateError(
        'Expected legacy map file is missing: '
        '${p.join(mapsDirectory.absolute.path, fileName)}',
      );
    }
  }

  for (final file in mapJsonFiles) {
    final absolutePath = p.normalize(file.absolute.path);
    final canonicalAbsolutePath = _canonicalLegacyPath(absolutePath);
    if (canonicalReferencedPaths.contains(canonicalAbsolutePath)) {
      continue;
    }
    if (p.dirname(absolutePath) != p.normalize(mapsDirectory.absolute.path)) {
      throw StateError(
        'Legacy map JSON files must remain directly under maps/: $absolutePath',
      );
    }
    if (!canonicalExpectedFileNames.contains(
      _canonicalLegacyFileName(p.basename(absolutePath)),
    )) {
      throw StateError('Unexpected unreferenced map JSON: $absolutePath');
    }
  }
}

String _canonicalLegacyPath(String path) {
  final normalized = p.normalize(path);
  return p.normalize(
    p.join(
      p.dirname(normalized),
      _canonicalLegacyFileName(p.basename(normalized)),
    ),
  );
}

String _canonicalLegacyFileName(String fileName) {
  // The frozen project contains one filename whose accented `é` can be
  // surfaced as either NFC or NFD depending on the checkout filesystem. Keep
  // this compatibility local to the legacy allowlist instead of normalizing
  // arbitrary project identifiers.
  return fileName
      .replaceAll('e\u0301', '\u00e9')
      .replaceAll('E\u0301', '\u00c9');
}
