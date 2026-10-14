import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _entry = ProjectMapEntry(
  id: 'map',
  name: 'Map',
  relativePath: 'maps/map.json',
);
const _owner = MapEntity(
  id: 'owner',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 1, y: 1),
  blocksMovement: false,
);
MapData _map({List<MapEntity> entities = const [_owner]}) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  entities: entities,
);
ProjectManifest _project({
  List<ProjectMapEntry> maps = const [_entry],
  ProjectDimension dimension = ProjectDimension.twoD,
}) => ProjectManifest(
  name: 'Logical autorun owner',
  tilesets: const [],
  maps: maps,
  settings: ProjectSettings(dimension: dimension),
);

void main() {
  test(
    'autorun accepts the same logical owner identity as instance booleans without graphics or collision',
    () {
      for (final kind in MapEntityKind.values) {
        final owner = _owner.copyWith(kind: kind);
        final map = _map(entities: [owner]);
        final catalog = buildNarrativeEventProjectCatalog(
          project: _project(),
          maps: [map],
        );
        expect(
          catalog.resolveMapEventInstanceOwner('map', 'owner').valueOrNull,
          owner,
        );
        expect(
          isNarrativeEntityAutorunSourceAvailable(
            project: _project(),
            map: map,
            entityId: 'owner',
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'catalog distinguishes native autorun from input and map entry sources',
    () {
      final catalog = buildNarrativeEventProjectCatalog(
        project: _project(),
        maps: [_map()],
      );
      final source = NarrativeEventSourceRef.entityAutorun('map', 'owner');
      expect(
        catalog.resolveSource(source).status,
        NarrativeEventProjectResolutionStatus.found,
      );
      final option = catalog.spatialSources.optionsForSource(source).single;
      expect(option.selectable, isTrue);
      expect(option.sourceTypeLabel, 'Automatique');
      expect(option.ownerId, 'owner');
      expect(option.ownerKind, NarrativeSpatialEventSourceOwnerKind.entity);
      expect(option.legacyProvenances, isEmpty);
      expect(option.origin, NarrativeSpatialEventSourceOrigin.canonical);
      expect(option.source, isNot(NarrativeEventSourceRef.mapEnter('map')));
      expect(
        option.source,
        isNot(NarrativeEventSourceRef.entityInteract('map', 'owner')),
      );
      expect(
        option.source,
        isNot(NarrativeEventSourceRef.entityBump('map', 'owner')),
      );
    },
  );

  test('autorun refuses missing duplicate and noncanonical references', () {
    for (final (project, map, id) in <(ProjectManifest, MapData, String)>[
      (_project(maps: []), _map(), 'owner'),
      (_project(maps: [_entry, _entry]), _map(), 'owner'),
      (_project(), _map(entities: []), 'owner'),
      (_project(), _map(entities: [_owner, _owner]), 'owner'),
      (_project(), _map(), 'missing'),
      (_project(), _map(), ' owner'),
      (_project(), _map(), ''),
    ]) {
      expect(
        isNarrativeEntityAutorunSourceAvailable(
          project: project,
          map: map,
          entityId: id,
        ),
        isFalse,
      );
    }
  });

  test('autorun is explicitly unavailable for project or map 3D', () {
    for (final (project, map) in <(ProjectManifest, MapData)>[
      (_project(dimension: ProjectDimension.threeD), _map()),
      (
        _project(),
        _map().copyWith(spatialScene: MapSpatialScene(width: 4, depth: 4)),
      ),
      (_project(), _map().copyWith(version: ProjectVersion.v9)),
    ]) {
      expect(
        isNarrativeEntityAutorunSourceAvailable(
          project: project,
          map: map,
          entityId: 'owner',
        ),
        isFalse,
      );
    }
  });

  test('source variants discover the exact logical owner contract', () {
    final contract = NarrativeEventSourceRef.contracts.singleWhere(
      (c) => c['kind'] == 'entityAutorun',
    );
    expect(contract['requiredFields'], ['kind', 'mapId', 'entityId']);
    expect(contract['dimension'], 'twoD');
    expect(contract['entityReference'], 'knownUniqueLogicalMapEntity');
  });
}
