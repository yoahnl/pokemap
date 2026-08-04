import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/application/map_placed_element_rotation_planner.dart';

void main() {
  group('planMapPlacedElementRotation', () {
    test('rejects when the active map is unavailable', () {
      final plan = planMapPlacedElementRotation(
        map: null,
        project: null,
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      expect(
        plan.rejection,
        MapPlacedElementRotationRejection.mapUnavailable,
      );
      expect(plan.sourceMap, isNull);
      expect(plan.candidateMap, isNull);
      expect(plan.canCommit, isFalse);
    });

    test('rejects when the project context is unavailable', () {
      final map = _map();
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: null,
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.projectUnavailable,
      );
    });

    test('rejects when the placed instance is missing', () {
      final map = _map();
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'missing',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.instanceMissing,
      );
      expect(plan.instance, isNull);
    });

    test('rejects when the project element definition is missing', () {
      final map = _map();
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(includeElement: false),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.elementMissing,
      );
      expect(plan.instance, same(map.placedElements.single));
    });

    test('rejects when the referenced layer is missing', () {
      final map = _map(layers: const <MapLayer>[]);
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.layerMissing,
      );
    });

    test('rejects a placement hosted by a non-tile layer', () {
      final map = _map(
        layers: const <MapLayer>[
          MapLayer.object(id: 'decor', name: 'Objects'),
        ],
      );
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.unsupportedLayer,
      );
    });

    test('rejects Environment ownership recorded by generated placement id',
        () {
      final map = _map(
        environmentGeneratedIds: const <String>['placed'],
        placement: _placement(
          properties: const <String, String>{
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
      );
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.environmentGenerated,
      );
    });

    test('rejects Environment ownership recorded by the shared origin marker',
        () {
      final map = _map(
        placement: _placement(
          properties: const <String, String>{
            pokemapPlacementOriginProperty: pokemapPlacementOriginEnvironment,
          },
        ),
      );
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.environmentGenerated,
      );
    });

    test('never infers Environment ownership from display labels', () {
      final map = _map(
        tileLayerName: 'Environment',
        placement: _placement(
          properties: const <String, String>{
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
      );

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(elementName: 'Environment'),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      expect(plan.canCommit, isTrue);
      expect(plan.rejection, isNull);
    });

    test('rejects tile-index ownership without replacing its stored rotation',
        () {
      final placement = _placement(
        quarterTurns: 2,
        properties: const <String, String>{
          pokemapPlacementOriginProperty: pokemapPlacementOriginTileIndex,
          'custom': 'preserved',
        },
      );
      final map = _map(placement: placement);
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: placement.id,
        targetQuarterTurns: 3,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.tileIndexed,
      );
      expect(map.placedElements.single, same(placement));
      expect(map.placedElements.single.quarterTurns, 2);
    });

    test('rejects absolute targets outside zero through three', () {
      for (final targetQuarterTurns in <int>[-1, 4]) {
        final map = _map();
        final snapshot = map.toJson();

        final plan = planMapPlacedElementRotation(
          map: map,
          project: _project(),
          instanceId: 'placed',
          targetQuarterTurns: targetQuarterTurns,
        );

        _expectRejectedUnchanged(
          plan,
          map: map,
          snapshot: snapshot,
          rejection:
              MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange,
        );
      }
    });

    test('retains q1 and q3 preview footprints when rotation exceeds bounds',
        () {
      for (final targetQuarterTurns in <int>[1, 3]) {
        final map = _map(
          placement: _placement(pos: const GridPos(x: 0, y: 2)),
        );
        final snapshot = map.toJson();

        final plan = planMapPlacedElementRotation(
          map: map,
          project: _project(),
          instanceId: 'placed',
          targetQuarterTurns: targetQuarterTurns,
        );

        _expectRejectedUnchanged(
          plan,
          map: map,
          snapshot: snapshot,
          rejection: MapPlacedElementRotationRejection.destinationOutOfBounds,
        );
        expect(
          plan.sourceFootprint?.destinationSize,
          const GridSize(width: 3, height: 2),
        );
        expect(
          plan.previewFootprint?.destinationSize,
          const GridSize(width: 2, height: 3),
        );
      }
    });

    test('retains both footprints when whole-map validation rejects candidate',
        () {
      final map = _map(layerTilesetId: 'incompatible-tiles');
      final snapshot = map.toJson();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      _expectRejectedUnchanged(
        plan,
        map: map,
        snapshot: snapshot,
        rejection: MapPlacedElementRotationRejection.candidateInvalid,
      );
      expect(
        plan.sourceFootprint?.destinationSize,
        const GridSize(width: 3, height: 2),
      );
      expect(
        plan.previewFootprint?.destinationSize,
        const GridSize(width: 2, height: 3),
      );
    });

    test('returns an immutable no-op without creating a candidate mutation',
        () {
      final map = _map(placement: _placement(quarterTurns: 2));
      final instance = map.placedElements.single;

      final plan = planMapPlacedElementRotation(
        map: map,
        project: _project(),
        instanceId: instance.id,
        targetQuarterTurns: 2,
      );

      expect(plan.sourceMap, same(map));
      expect(plan.instance, same(instance));
      expect(plan.sourceFootprint, same(plan.previewFootprint));
      expect(plan.candidateMap, same(map));
      expect(plan.rejection, isNull);
      expect(plan.isNoOp, isTrue);
      expect(plan.canCommit, isFalse);
    });

    test('builds a validator-clean candidate without mutating its source', () {
      final map = _map();
      final snapshot = map.toJson();
      final instance = map.placedElements.single;
      final project = _project();

      final plan = planMapPlacedElementRotation(
        map: map,
        project: project,
        instanceId: instance.id,
        targetQuarterTurns: 1,
      );

      expect(plan.canCommit, isTrue);
      expect(plan.rejection, isNull);
      expect(plan.isNoOp, isFalse);
      expect(plan.sourceMap, same(map));
      expect(plan.instance, same(instance));
      expect(
        plan.sourceFootprint?.destinationSize,
        const GridSize(width: 3, height: 2),
      );
      expect(
        plan.previewFootprint?.destinationSize,
        const GridSize(width: 2, height: 3),
      );
      expect(plan.candidateMap, isNot(same(map)));
      expect(plan.candidateMap!.placedElements.single.quarterTurns, 1);
      expect(map.placedElements.single, same(instance));
      expect(map.toJson(), snapshot);
      expect(
        () => MapValidator.validate(
          plan.candidateMap!,
          projectDialogueContext: project,
        ),
        returnsNormally,
      );
    });
  });
}

void _expectRejectedUnchanged(
  MapPlacedElementRotationPlan plan, {
  required MapData map,
  required Map<String, dynamic> snapshot,
  required MapPlacedElementRotationRejection rejection,
}) {
  expect(plan.sourceMap, same(map));
  expect(plan.rejection, rejection);
  expect(plan.candidateMap, isNull);
  expect(plan.isNoOp, isFalse);
  expect(plan.canCommit, isFalse);
  expect(map.toJson(), snapshot);
}

ProjectManifest _project({
  bool includeElement = true,
  String elementName = 'Element 3x2',
}) {
  return ProjectManifest(
    name: 'Rotation planner',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'assets/tiles.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      if (includeElement)
        ProjectElementEntry(
          id: 'element-3x2',
          name: elementName,
          tilesetId: 'tiles',
          categoryId: 'decor',
          frames: const <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: 3,
                height: 2,
              ),
            ),
          ],
        ),
    ],
  );
}

MapData _map({
  MapPlacedElement? placement,
  List<MapLayer>? layers,
  List<String> environmentGeneratedIds = const <String>[],
  String tileLayerName = 'Decor',
  String layerTilesetId = 'tiles',
}) {
  const size = GridSize(width: 4, height: 4);
  return MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: size,
    layers: layers ??
        <MapLayer>[
          if (environmentGeneratedIds.isNotEmpty)
            MapLayer.environment(
              id: 'environment',
              name: 'Generated ownership',
              content: EnvironmentLayerContent(
                targetTileLayerId: 'decor',
                areas: <EnvironmentArea>[
                  EnvironmentArea(
                    id: 'area',
                    name: 'Area',
                    presetId: 'forest',
                    mask: EnvironmentAreaMask(
                      width: size.width,
                      height: size.height,
                      cells: List<bool>.filled(
                        size.width * size.height,
                        true,
                        growable: false,
                      ),
                    ),
                    seed: 1,
                    generatedPlacementIds: environmentGeneratedIds,
                  ),
                ],
              ),
            ),
          MapLayer.tile(
            id: 'decor',
            name: tileLayerName,
            palette: layerTilesetId == 'tiles'
                ? const <TileLayerPaletteEntry>[]
                : <TileLayerPaletteEntry>[
                    TileLayerPaletteEntry(
                      tilesetId: layerTilesetId,
                      localTileId: 0,
                    ),
                  ],
            cells: List<int>.filled(
              size.width * size.height,
              0,
              growable: false,
            ),
          ),
        ],
    placedElements: <MapPlacedElement>[
      placement ?? _placement(),
    ],
  );
}

MapPlacedElement _placement({
  GridPos pos = const GridPos(x: 0, y: 0),
  int quarterTurns = 0,
  Map<String, String> properties = const <String, String>{},
}) {
  return MapPlacedElement(
    id: 'placed',
    layerId: 'decor',
    elementId: 'element-3x2',
    pos: pos,
    quarterTurns: quarterTurns,
    properties: properties,
  );
}
