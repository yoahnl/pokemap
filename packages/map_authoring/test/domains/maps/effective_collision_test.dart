import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        AuthoringPerformanceCounterName,
        AuthoringPerformanceObserver,
        AuthoringPerformanceSpan;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EffectiveCollisionInspector', () {
    test('projects every moved collision pixel and deduplicates provenance',
        () {
      final fixture = _collisionFixture();
      final element = fixture.manifest.elements.single.copyWith(
          collisionProfile: ElementCollisionProfile(
              collisionMask: ElementCollisionPixelMask(
                  widthPx: 16,
                  heightPx: 16,
                  dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                      widthPx: 16,
                      heightPx: 16,
                      solidPixels: List<bool>.generate(
                          256, (i) => i == 0 || i == 32)))));
      final manifest = fixture.manifest.copyWith(
          elements: [element],
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16));
      final map =
          fixture.map.copyWith(layers: [], entities: [], placedElements: [
        fixture.map.placedElements.single.copyWith(
            properties: {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
            },
            pixelOffset: const PixelOffset(x: 15, y: 15),
            pixelSize: const PixelSize(width: 1, height: 1))
      ]);
      const inspector = EffectiveCollisionInspector();
      expect(
          inspector
              .queryAt(
                  manifest: manifest, map: map, pos: const GridPos(x: 1, y: 0))
              .contributions
              .length,
          1);
      expect(
          inspector
              .queryAt(
                  manifest: manifest, map: map, pos: const GridPos(x: 2, y: 0))
              .isBlocked,
          isFalse);
    });

    test('moved cell profiles free old cells and occupy resized cells', () {
      final fixture = _collisionFixture();
      final manifest = fixture.manifest.copyWith(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16));
      final map =
          fixture.map.copyWith(layers: [], entities: [], placedElements: [
        fixture.map.placedElements.single.copyWith(
            pos: const GridPos(x: 2, y: 1),
            properties: {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
            },
            pixelOffset: const PixelOffset(x: 1, y: 1),
            pixelSize: const PixelSize(width: 17, height: 1))
      ]);
      const inspector = EffectiveCollisionInspector();
      expect(
          inspector
              .queryAt(
                  manifest: manifest, map: map, pos: const GridPos(x: 1, y: 0))
              .isBlocked,
          isFalse);
      expect(
          inspector
              .queryAt(
                  manifest: manifest, map: map, pos: const GridPos(x: 3, y: 1))
              .contributions
              .length,
          1);
      expect(
          inspector
              .queryAt(
                  manifest: manifest, map: map, pos: const GridPos(x: 2, y: 2))
              .isBlocked,
          isFalse);
    });

    test(
        'invalid collision masks report an error without falling back to cells',
        () {
      final fixture = _collisionFixture();
      final manifest = fixture.manifest.copyWith(elements: [
        fixture.manifest.elements.single.copyWith(
            collisionProfile: const ElementCollisionProfile(
                cells: [GridPos(x: 0, y: 0)],
                collisionMask: ElementCollisionPixelMask(
                    widthPx: 16, heightPx: 16, dataBase64: 'AA==')))
      ]);
      expect(
          () => const EffectiveCollisionInspector().queryAt(
              manifest: manifest,
              map: fixture.map,
              pos: const GridPos(x: 1, y: 0)),
          throwsFormatException);
    });

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

    test('observes pixel mask base64 decoding on the canonical inspector', () {
      final observer = _RecordingPerformanceObserver();
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: <bool>[
            true,
            ...List<bool>.filled(255, false),
          ],
        ),
      );
      final manifest = _manifest(
        elements: [
          ProjectElementEntry(
            id: 'masked-rock',
            name: 'Masked rock',
            tilesetId: 'nature',
            categoryId: 'decor',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
            ),
          ),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 1, height: 1),
        placedElements: const [
          MapPlacedElement(
            id: 'masked-rock-instance',
            layerId: 'decor',
            elementId: 'masked-rock',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final result = EffectiveCollisionInspector(
        performanceObserver: observer,
      ).queryAt(
        manifest: manifest,
        map: map,
        pos: const GridPos(x: 0, y: 0),
      );

      expect(result, isA<EffectiveCollisionCell>());
      expect(
        observer.counter(AuthoringPerformanceCounterName.base64Decode),
        1,
      );
    });
  });
}

final class _RecordingPerformanceObserver
    implements AuthoringPerformanceObserver {
  final Map<String, int> _counters = <String, int>{};

  int counter(String name) => _counters[name] ?? 0;

  @override
  void incrementCounter(String name, {int by = 1}) {
    _counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
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
    );
