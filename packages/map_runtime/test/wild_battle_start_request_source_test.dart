import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_music_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

void main() {
  test('interactive source snapshot survives deleted source and native hydration', () {
    final payload = const EncounterZonePayload(encounterTableId: 'rock-table', encounterKind: EncounterKind.special, battleMusicPath: 'audio/rock.ogg', battleBackgroundRelativePath: 'assets/rock.png', battleTransitionIds: ['rby_wild']);
    final request = WildBattleStartRequest(requestId: 'object', createdAtEpochMs: 1, returnContext: const OverworldReturnContext(mapId: 'route', playerPos: GridPos(x: 1, y: 1), playerFacing: Direction.east), mapId: 'route', encounterSourceId: 'entity:rock', encounterSourceKind: EncounterSourceKind.interactiveObject, tableId: 'rock-table', encounterKind: EncounterKind.special, speciesId: 'test', level: 2, minLevel: 2, maxLevel: 2, weight: 1, playerPos: const GridPos(x: 1, y: 1), encounterSourceSnapshot: payload);
    final hydrated = request.withGeneratedPokemon(pokemon: const PlayerPokemon(speciesId: 'test', natureId: 'hardy', abilityId: 'test'), profileId: 'native', schemaVersion: 1);
    expect(hydrated.encounterSourceSnapshot, payload);
    expect(hydrated.toJson()['encounterSourceSnapshot'], payload.toJson());
    final bundle = RuntimeMapBundle(manifest: const ProjectManifest(name: 'Deleted rock', maps: [], tilesets: []), map: MapData(id: 'route', name: 'Route', size: const GridSize(width: 4, height: 4)), projectRootDirectory: '/tmp/deleted-rock', tilesetAbsolutePathsById: {});
    expect(const BattleMusicResolver().resolve(request: hydrated, bundle: bundle).battleMusicAbsolutePath, '/tmp/deleted-rock/audio/rock.ogg');
    expect(const BattleBackgroundResolver().resolve(request: hydrated, bundle: bundle).explicitImageAbsolutePath, '/tmp/deleted-rock/assets/rock.png');
    expect(resolveBattleTransitionSpec(request: hydrated, manifest: bundle.manifest, map: bundle.map).id, 'rby_wild');

  });
  test('wild battle request preserves a Smart Tile encounter source', () {
    const encounter = GameplayEncounter(
      mapId: 'route',
      sourceId: 'smart_tile_layer:grass_north',
      sourceKind: EncounterSourceKind.smartTileLayer,
      tableId: 'grass_north',
      encounterKind: EncounterKind.walk,
      speciesId: 'sproutle',
      level: 5,
      minLevel: 4,
      maxLevel: 6,
      weight: 10,
      playerPos: GridPos(x: 2, y: 1),
    );
    final world = GameplayWorldState.initial(
      map: MapData(
        id: 'route',
        name: 'Route',
        size: const GridSize(width: 4, height: 4),
      ),
      playerPos: const GridPos(x: 2, y: 1),
      playerFacing: Direction.south,
    );

    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: world,
      createdAtEpochMs: 42,
    );

    expect(request.encounterSourceId, 'smart_tile_layer:grass_north');
    expect(request.encounterSourceKind, EncounterSourceKind.smartTileLayer);
    expect(request.source, RuntimeBattleSourceKind.wildEncounter);
    expect(request.toJson(), containsPair('encounterSourceKind', 'smartTileLayer'));
    expect(request.toJson(), isNot(contains('zoneId')));
  });
}
