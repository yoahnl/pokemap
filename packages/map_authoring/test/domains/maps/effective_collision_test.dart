import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EffectiveCollisionInspector', () {
    test('explains layer, placed-element profile and entity provenance', () {
      final fixture = _collisionFixture();
      const inspector = EffectiveCollisionInspector();

      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 0, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.collisionLayer,
      );
      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 1, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.placedElementProfile,
      );
      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 2, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.blockingEntity,
      );
    });

    test('reachability reports an exit isolated by effective collision', () {
      final collisions = <bool>[
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
      ];
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: [
          MapLayer.collision(
            id: 'walls',
            name: 'Walls',
            collisions: collisions,
          ),
        ],
      );

      final report = const EffectiveCollisionInspector().validateReachability(
        manifest: _manifest(),
        map: map,
        start: const GridPos(x: 0, y: 0),
        exits: const [GridPos(x: 2, y: 2)],
      );

      expect(report.isValid, isFalse);
      expect(report.unreachableExits, const [GridPos(x: 2, y: 2)]);
      expect(report.reachableCellCount, 3);

      final walkability =
          const EffectiveCollisionInspector().validateWalkability(
        manifest: _manifest(),
        map: map,
      );
      expect(walkability.isFullyConnected, isFalse);
      expect(walkability.componentCount, 2);
      expect(walkability.componentSizes, const [3, 3]);
    });
  });
}

({ProjectManifest manifest, MapData map}) _collisionFixture() {
  final manifest = _manifest(
    elements: const [
      ProjectElementEntry(
        id: 'rock',
        name: 'Rock',
        tilesetId: 'nature',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
        collisionProfile: ElementCollisionProfile(
          cells: [GridPos(x: 0, y: 0)],
        ),
      ),
    ],
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 3),
    layers: [
      MapLayer.collision(
        id: 'manual',
        name: 'Manual',
        collisions: const [
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'rock-instance',
        layerId: 'decor',
        elementId: 'rock',
        pos: GridPos(x: 1, y: 0),
      ),
    ],
    entities: const [
      MapEntity(
        id: 'blocker',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 0),
      ),
    ],
  );
  return (manifest: manifest, map: map);
}

ProjectManifest _manifest({
  List<ProjectElementEntry> elements = const [],
}) =>
    ProjectManifest(
      name: 'Collision test',
      maps: const [],
      tilesets: const [],
      elements: elements,
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );
