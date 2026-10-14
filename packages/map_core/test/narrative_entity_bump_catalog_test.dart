import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _npc = MapEntity(
  id: 'door',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(characterId: 'actor'),
);
const _mapEntry = ProjectMapEntry(
  id: 'map',
  name: 'Map',
  relativePath: 'maps/map.json',
);
const _character = ProjectCharacterEntry(
  id: 'actor',
  name: 'Actor',
  tilesetId: 'qa',
  frameHeight: 1,
);
MapData _map({List<MapEntity> entities = const [_npc]}) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 6, height: 6),
  entities: entities,
);
ProjectManifest _project({
  List<ProjectMapEntry> maps = const [_mapEntry],
  List<ProjectCharacterEntry> characters = const [_character],
  List<ProjectTrainerEntry> trainers = const [],
  ProjectDimension dimension = ProjectDimension.twoD,
}) => ProjectManifest(
  name: 'Native contact',
  tilesets: const [],
  maps: maps,
  characters: characters,
  trainers: trainers,
  settings: ProjectSettings(dimension: dimension),
);

void main() {
  test(
    'native blocking NPC contact reference is available without an egress anchor restriction',
    () {
      for (final entity in [
        _npc,
        _npc.copyWith(size: const GridSize(width: 2, height: 2)),
      ]) {
        expect(
          isNarrativeEntityBumpSourceAvailable(
            project: _project(),
            map: _map(entities: [entity]),
            entityId: 'door',
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'canonical catalog discovers a bump source separately from interaction',
    () {
      final catalog = buildNarrativeEventProjectCatalog(
        project: _project(),
        maps: [_map()],
      );
      final bump = NarrativeEventSourceRef.entityBump('map', 'door');
      final interact = NarrativeEventSourceRef.entityInteract('map', 'door');
      expect(
        catalog.resolveSource(bump).status,
        NarrativeEventProjectResolutionStatus.found,
      );
      expect(
        catalog.resolveSource(interact).status,
        NarrativeEventProjectResolutionStatus.found,
      );
      final option = catalog.spatialSources.optionsForSource(bump).single;
      expect(option.sourceTypeLabel, 'Contact du joueur');
      expect(option.legacyProvenances, isEmpty);
      expect(option.origin, NarrativeSpatialEventSourceOrigin.canonical);
    },
  );

  test(
    'native contact refuses spatial maps and invalid canonical contact bounds',
    () {
      for (final map in [
        _map().copyWith(spatialScene: MapSpatialScene(width: 6, depth: 6)),
        _map().copyWith(version: ProjectVersion.v9),
        _map(entities: [_npc.copyWith(pos: const GridPos(x: 6, y: 1))]),
        _map(
          entities: [_npc.copyWith(size: const GridSize(width: 0, height: 1))],
        ),
      ]) {
        expect(
          isNarrativeEntityBumpSourceAvailable(
            project: _project(),
            map: map,
            entityId: 'door',
          ),
          isFalse,
        );
      }
    },
  );

  test(
    'contact resolves a unique trainer character without replacing an invalid direct reference',
    () {
      const trainer = ProjectTrainerEntry(
        id: 'trainer',
        name: 'Trainer',
        trainerClass: 'QA',
        characterId: 'actor',
      );
      final indirect = _npc.copyWith(
        npc: const MapEntityNpcData(trainerId: 'trainer'),
      );
      expect(
        isNarrativeEntityBumpSourceAvailable(
          project: _project(trainers: [trainer]),
          map: _map(entities: [indirect]),
          entityId: 'door',
        ),
        isTrue,
      );
      for (final project in [
        _project(trainers: []),
        _project(trainers: [trainer, trainer]),
        _project(trainers: [trainer], characters: [_character, _character]),
      ]) {
        expect(
          isNarrativeEntityBumpSourceAvailable(
            project: project,
            map: _map(entities: [indirect]),
            entityId: 'door',
          ),
          isFalse,
        );
      }
      final invalidDirect = _npc.copyWith(
        npc: const MapEntityNpcData(
          characterId: 'missing',
          trainerId: 'trainer',
        ),
      );
      expect(
        isNarrativeEntityBumpSourceAvailable(
          project: _project(trainers: [trainer]),
          map: _map(entities: [invalidDirect]),
          entityId: 'door',
        ),
        isFalse,
      );
    },
  );

  test(
    'contact availability refuses invalid exact references and nonblocking owners',
    () {
      final invalidEntities = [
        _npc.copyWith(blocksMovement: false),
        _npc.copyWith(kind: MapEntityKind.sign),
        _npc.copyWith(kind: MapEntityKind.custom),
        _npc.copyWith(npc: null),
        _npc.copyWith(npc: const MapEntityNpcData(characterId: 'missing')),
      ];
      for (final entity in invalidEntities) {
        expect(
          isNarrativeEntityBumpSourceAvailable(
            project: _project(),
            map: _map(entities: [entity]),
            entityId: 'door',
          ),
          isFalse,
        );
      }
      for (final project in [
        _project(maps: []),
        _project(maps: [_mapEntry, _mapEntry]),
        _project(characters: []),
        _project(characters: [_character, _character]),
        _project(dimension: ProjectDimension.threeD),
      ]) {
        expect(
          isNarrativeEntityBumpSourceAvailable(
            project: project,
            map: _map(),
            entityId: 'door',
          ),
          isFalse,
        );
      }
      expect(
        isNarrativeEntityBumpSourceAvailable(
          project: _project(),
          map: _map(entities: []),
          entityId: 'door',
        ),
        isFalse,
      );
      expect(
        isNarrativeEntityBumpSourceAvailable(
          project: _project(),
          map: _map(entities: [_npc, _npc]),
          entityId: 'door',
        ),
        isFalse,
      );
      expect(
        isNarrativeEntityBumpSourceAvailable(
          project: _project(),
          map: _map(),
          entityId: 'missing',
        ),
        isFalse,
      );
    },
  );
}
