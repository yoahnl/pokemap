import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapData manualEnvironmentEntityMap({bool manual = true, bool spatial = true}) =>
    MapData(
      id: 'field',
      name: 'Field',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'tree',
            modelId: 'tree-model',
            position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
            entityId: 'object',
          ),
        ],
      ),
      entities: [
        MapEntity(
          id: 'object',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 2, y: 2),
        ),
      ],
      layers: [
        MapLayer.environment(
          id: 'forest',
          name: 'Forest',
          content: EnvironmentLayerContent(
            targetsSpatialTerrain: spatial,
            areas: [
              EnvironmentArea(
                id: 'trees',
                name: 'Trees',
                presetId: 'forest',
                seed: 1,
                mask: EnvironmentAreaMask(
                  width: 8,
                  height: 8,
                  cells: List.filled(64, false),
                ),
                generatedPlacementIds: ['tree'],
                manualPlacementIds: manual ? ['tree'] : [],
              ),
            ],
          ),
        ),
      ],
    );

void main() {
  test(
    'one stable spatial manual owner retains a bound model and roundtrips',
    () {
      final map = manualEnvironmentEntityMap();
      validateSpatialEntityModelBindings(map);
      expect(MapData.fromJson(map.toJson()), map);
    },
  );

  for (final mode in [
    'automatic',
    'multiple',
    'non-spatial',
    'npc',
    'duplicate-entity',
    'duplicate-binding',
    'anchor',
    'smart-tile',
  ]) {
    test('manual binding refuses $mode independently and in the codec', () {
      var map = manualEnvironmentEntityMap(
        manual: mode != 'automatic',
        spatial: mode != 'non-spatial',
      );
      final instance = map.spatialScene!.instances.single;
      if (mode == 'multiple') {
        final layer = map.layers.single as EnvironmentLayer;
        map = map.copyWith(
          layers: [
            layer,
            MapLayer.environment(
              id: 'other',
              name: 'Other',
              content: layer.content,
            ),
          ],
        );
      } else if (mode == 'npc') {
        map = map.copyWith(
          entities: [map.entities.single.copyWith(kind: MapEntityKind.npc)],
        );
      } else if (mode == 'duplicate-entity') {
        map = map.copyWith(
          entities: [map.entities.single, map.entities.single],
        );
      } else if (mode == 'duplicate-binding') {
        map = map.copyWith(
          spatialScene: map.spatialScene!.copyWith(
            instances: [
              instance,
              SpatialModelInstance.fromJson({
                ...instance.toJson(),
                'id': 'other-tree',
              }),
            ],
          ),
        );
      } else if (mode == 'anchor') {
        map = map.copyWith(
          entities: [
            map.entities.single.copyWith(pos: const GridPos(x: 1, y: 1)),
          ],
        );
      } else if (mode == 'smart-tile') {
        map = map.copyWith(
          layers: [],
          spatialScene: map.spatialScene!.copyWith(
            instances: [
              SpatialModelInstance.fromJson({
                ...instance.toJson(),
                'id': 'smt_forged',
              }),
            ],
          ),
        );
      }
      expect(
        () => validateSpatialEntityModelBindings(map),
        throwsFormatException,
      );
      expect(() => MapData.fromJson(map.toJson()), throwsA(anything));
    });
  }

  test('one manual item binding keeps once-only pickup restrictions', () {
    final map = manualEnvironmentEntityMap();
    final valid = map.copyWith(
      entities: [
        map.entities.single.copyWith(
          kind: MapEntityKind.item,
          item: const MapEntityItemData(gameItemId: 'fruit'),
        ),
      ],
    );
    expect(MapData.fromJson(valid.toJson()), valid);
    final repeating = valid.copyWith(
      entities: [
        valid.entities.single.copyWith(
          item: const MapEntityItemData(
            gameItemId: 'fruit',
            pickupMode: ItemPickupMode.always,
          ),
        ),
      ],
    );
    expect(
      () => validateSpatialEntityModelBindings(repeating),
      throwsFormatException,
    );
    final unbound = map.copyWith(
      spatialScene: map.spatialScene!.copyWith(
        instances: [
          map.spatialScene!.instances.single.copyWith(clearEntityBinding: true),
        ],
      ),
    );
    expect(SpatialEntityModelOwnership.requiresCapability([map]), isTrue);
    expect(SpatialEntityModelOwnership.requiresCapability([unbound]), isFalse);
    expect(
      SpatialEntityModelOwnership.requiresCapability([
        map.copyWith(layers: []),
      ]),
      isFalse,
    );
  });

  test('a manual owner cannot cancel another automatic owner', () {
    final map = manualEnvironmentEntityMap();
    final automatic =
        manualEnvironmentEntityMap(manual: false).layers.single
            as EnvironmentLayer;
    final mixed = map.copyWith(
      layers: [
        map.layers.single,
        MapLayer.environment(
          id: 'automatic',
          name: 'Automatic',
          content: automatic.content,
        ),
      ],
    );
    expect(SpatialEntityModelOwnership(mixed).canBind('tree'), isFalse);
    expect(
      () => validateSpatialEntityModelBindings(mixed),
      throwsFormatException,
    );
    expect(() => MapData.fromJson(mixed.toJson()), throwsFormatException);
  });

  test('manual marker outside generated ownership remains invalid', () {
    expect(
      () => EnvironmentArea(
        id: 'trees',
        name: 'Trees',
        presetId: 'forest',
        seed: 1,
        mask: EnvironmentAreaMask(width: 1, height: 1, cells: [false]),
        generatedPlacementIds: [],
        manualPlacementIds: ['tree'],
      ),
      throwsArgumentError,
    );
  });

  test('a manual owner cannot cancel a spatial Border owner', () {
    final map = manualEnvironmentEntityMap();
    final sha = 'sha256:${'0' * 64}';
    final feature = BorderFeature(
      id: 'edge',
      name: 'Edge',
      blueprintId: 'edge',
      seed: BorderSignedInt64.fromInt(1),
      geometry: BorderRegionGeometry(width: 1, height: 1, cells: [true]),
      overrides: [],
      keepOutRegions: [],
      materialization: BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: 1,
          blueprintRevision: 1,
          components: BorderInputFingerprints(
            blueprint: sha,
            geometryAndSeed: sha,
            parameters: sha,
            overrides: sha,
            keepOutRegions: sha,
            mapContext: sha,
            visualSnapshots: sha,
          ),
          inputFingerprint: sha,
          outputFingerprint: sha,
        ),
        ground: [],
        placements: [],
        targetsSpatialScene: true,
        spatialPlacements: [
          BorderSpatialPlacement(
            slotKey: 'slot',
            primitiveId: 'tree',
            instanceId: 'tree',
          ),
        ],
      ),
    );
    final mixed = map.copyWith(
      layers: [
        ...map.layers,
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(features: [feature]),
        ),
      ],
    );
    expect(SpatialEntityModelOwnership(mixed).canBind('tree'), isFalse);
    expect(
      () => validateSpatialEntityModelBindings(mixed),
      throwsFormatException,
    );
    expect(() => MapData.fromJson(mixed.toJson()), throwsFormatException);
  });
}
