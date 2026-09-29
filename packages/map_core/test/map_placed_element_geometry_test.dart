import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('hidden Environment ownership overrides an authored marker', () {
    final original = _map([_instance]);
    final before = original.copyWith(
      layers: [
        ...original.layers,
        MapLayer.environment(
          id: 'environment',
          name: 'Environment',
          isVisible: false,
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: [
              EnvironmentArea(
                id: 'area',
                name: 'Area',
                presetId: 'preset',
                seed: 1,
                mask: EnvironmentAreaMask(
                  width: 8,
                  height: 8,
                  cells: List.filled(64, false),
                ),
                generatedPlacementIds: ['placed'],
              ),
            ],
          ),
        ),
      ],
    );
    expect(
      () => setMapPlacedElementGeometry(
        before,
        manifest: _project,
        instanceId: 'placed',
        pixelX: 17,
        pixelY: 32,
        pixelSize: null,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => detachMapPlacedElementFromTileProjection(
        before,
        instanceId: 'placed',
      ),
      throwsA(isA<ValidationException>()),
    );
    final changed = _instance.copyWith(
      pixelOffset: const PixelOffset(x: 1, y: 0),
    );
    final after = before.copyWith(placedElements: [changed]);
    expect(() => MapValidator.validate(before), returnsNormally);
    expect(
      () => MapValidator.validate(after),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => MapValidator.validatePlacedElement(
        after,
        changed,
        projectDialogueContext: _project,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => MapDeltaValidator.validate(
        DeltaValidationContext(
          before: before,
          after: after,
          project: _project,
          delta: MapMutationDelta.placedElement(
            instance: changed,
            instanceIndex: 0,
          ),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('placed element preserves pixel offset and custom size in JSON', () {
    final json = _instance.toJson()
      ..['pixelOffset'] = {'x': 3, 'y': 7}
      ..['pixelSize'] = {'width': 17, 'height': 49};

    final decoded = MapPlacedElement.fromJson(json);

    expect(decoded.toJson()['pixelOffset'], {'x': 3, 'y': 7});
    expect(decoded.toJson()['pixelSize'], {'width': 17, 'height': 49});
    expect(decoded, isNot(_instance));
  });

  test(
    'detaching preserves fields and refuses a padded Environment marker',
    () {
      final projected = _instance.copyWith(properties: {'label': 'kept'});
      final map = _map([projected]);
      final detached = detachMapPlacedElementFromTileProjection(
        map,
        instanceId: projected.id,
      );
      expect(
        detached.placedElements.single,
        projected.copyWith(
          properties: {
            'label': 'kept',
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
      );
      expect(map.placedElements.single, projected);
      expect(
        () => detachMapPlacedElementFromTileProjection(
          _map([
            projected.copyWith(
              properties: {pokemapPlacementOriginProperty: ' environment '},
            ),
          ]),
          instanceId: projected.id,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('pixel dimensions reject fractional JSON values', () {
    final json = _instance.toJson()
      ..['pixelSize'] = {'width': 1.5, 'height': 4};

    expect(() => MapPlacedElement.fromJson(json), throwsFormatException);
  });

  test('normalizes offsets in both directions using floor division', () {
    for (final sample in [
      (
        const PixelOffset(x: 33, y: 65),
        const GridPos(x: 3, y: 3),
        const PixelOffset(x: 1, y: 1),
      ),
      (
        const PixelOffset(x: -1, y: -33),
        const GridPos(x: 0, y: -1),
        const PixelOffset(x: 15, y: 31),
      ),
    ]) {
      final normalized = normalizeMapPlacedElementGeometry(
        _instance.copyWith(pixelOffset: sample.$1),
        tileSize: _tileSize,
      );
      expect(normalized.pos, sample.$2);
      expect(normalized.pixelOffset, sample.$3);
    }
  });

  test('natural geometry preserves quarter turns with non-square tiles', () {
    for (var turn = 0; turn < 4; turn++) {
      final geometry = resolveMapPlacedElementGeometry(
        instance: _instance.copyWith(quarterTurns: turn),
        element: _element,
        tileSize: _tileSize,
      );
      final expected = turn.isEven
          ? const PixelSize(width: 32, height: 32)
          : const PixelSize(width: 16, height: 64);
      expect(geometry.pixelSize, expected);
      expect(geometry.naturalPixelSize, expected);
      expect(_rect(geometry.logicalRect), [
        16,
        32,
        expected.width,
        expected.height,
      ]);
    }
  });

  test('custom odd dimensions and half-open cell coverage are exact', () {
    final geometry = resolveMapPlacedElementGeometry(
      instance: _instance.copyWith(
        pixelOffset: const PixelOffset(x: 15, y: 31),
        pixelSize: const PixelSize(width: 17, height: 1),
      ),
      element: _element,
      tileSize: _tileSize,
    );
    expect(_rect(geometry.logicalRect), [31, 63, 17, 1]);
    expect(
      geometry.cellBounds,
      const MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 1),
      ),
    );
  });

  test('atomic geometry operation preserves order and unrelated fields', () {
    final original = _map([
      _instance,
      _instance.copyWith(id: 'other', visualOrder: 7),
    ]);
    final result = setMapPlacedElementGeometry(
      original,
      manifest: _project,
      instanceId: 'placed',
      pixelX: 33,
      pixelY: 65,
      pixelSize: const PixelSize(width: 7, height: 9),
    );
    expect(result.placedElements.map((e) => e.id), ['placed', 'other']);
    expect(result.placedElements.first.pos, const GridPos(x: 2, y: 2));
    expect(
      result.placedElements.first.pixelOffset,
      const PixelOffset(x: 1, y: 1),
    );
    expect(result.placedElements.last, same(original.placedElements.last));
    expect(original.placedElements.first, _instance);
    final reset = setMapPlacedElementGeometry(
      result,
      manifest: _project,
      instanceId: 'placed',
      pixelX: 33,
      pixelY: 65,
      pixelSize: null,
    );
    expect(reset.placedElements.first.pixelSize, isNull);
  });

  test('four quarter turns restore custom size and exact pixel anchor', () {
    final instance = _instance.copyWith(
      pixelOffset: const PixelOffset(x: 3, y: 7),
      pixelSize: const PixelSize(width: 17, height: 49),
    );
    var map = _map([instance]);
    for (var i = 0; i < 4; i++) {
      map = rotateMapPlacedElement(
        map,
        instanceId: 'placed',
        deltaQuarterTurns: 1,
      );
      expect(
        map.placedElements.single.pixelSize,
        i.isEven
            ? const PixelSize(width: 49, height: 17)
            : const PixelSize(width: 17, height: 49),
      );
      expect(map.placedElements.single.pos, instance.pos);
      expect(map.placedElements.single.pixelOffset, instance.pixelOffset);
    }
    expect(map.placedElements.single, instance);
  });

  test('pixel hit testing keeps half-open edges and tiny offset elements', () {
    final map = _map([
      _instance.copyWith(
        pixelOffset: const PixelOffset(x: 15, y: 31),
        pixelSize: const PixelSize(width: 1, height: 1),
      ),
    ]);
    for (final sample in [
      (31, 63, true),
      (30, 63, false),
      (32, 63, false),
      (31, 64, false),
    ]) {
      final hits = mapPlacedElementsAtPixel(
        map,
        _project,
        PixelPosition(leftPx: sample.$1, topPx: sample.$2),
        layerId: 'decor',
      );
      expect(hits.isNotEmpty, sample.$3);
    }
  });

  test(
    'cell queries and ordering include tiny elements away from cell center',
    () {
      final tiny = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 15, y: 31),
        pixelSize: const PixelSize(width: 1, height: 1),
      );
      final map = _map([tiny, tiny.copyWith(id: 'neighbor')]);
      expect(
        mapPlacedElementsAt(
          map,
          _project,
          const GridPos(x: 1, y: 1),
          layerId: 'decor',
        ).map((e) => e.id),
        ['placed', 'neighbor'],
      );
      final moved = moveMapPlacedElementVisualOrder(
        map,
        manifest: _project,
        instanceId: 'placed',
        forward: true,
        at: const GridPos(x: 1, y: 1),
      );
      expect(
        sortMapPlacedElementsForPainting(moved.placedElements).map((e) => e.id),
        ['neighbor', 'placed'],
      );
    },
  );

  test('pixel overlap changes visual ranks without reordering gameplay', () {
    final map = _map([
      _instance.copyWith(pixelSize: const PixelSize(width: 17, height: 1)),
      _instance.copyWith(
        id: 'neighbor',
        pos: const GridPos(x: 2, y: 1),
        pixelSize: const PixelSize(width: 1, height: 1),
      ),
    ]);
    final moved = moveMapPlacedElementVisualOrder(
      map,
      manifest: _project,
      instanceId: 'placed',
      forward: true,
    );
    expect(moved.placedElements.map((e) => e.id), ['placed', 'neighbor']);
    expect(
      sortMapPlacedElementsForPainting(moved.placedElements).map((e) => e.id),
      ['neighbor', 'placed'],
    );
    final touching = map.copyWith(
      placedElements: [
        map.placedElements.first.copyWith(
          pixelSize: const PixelSize(width: 16, height: 1),
        ),
        map.placedElements.last,
      ],
    );
    expect(
      moveMapPlacedElementVisualOrder(
        touching,
        manifest: _project,
        instanceId: 'placed',
        forward: true,
      ),
      touching,
    );
  });

  test('validation and resize detect pixel overflow with anchor inside', () {
    final instance = _instance.copyWith(
      pos: const GridPos(x: 3, y: 1),
      pixelOffset: const PixelOffset(x: 15, y: 0),
      pixelSize: const PixelSize(width: 2, height: 1),
    );
    final map = _map([instance]);
    final plan = planMapResize(map, width: 4, height: 4, project: _project);
    expect(
      plan.impacts.any(
        (i) =>
            i.kind == MapResizeImpactKind.placedElement &&
            i.reason == MapResizeImpactReason.footprintOutside,
      ),
      isTrue,
    );
    expect(
      () => MapValidator.validatePlacedElement(
        map.copyWith(size: const GridSize(width: 4, height: 4)),
        instance,
        projectDialogueContext: _project,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('negative origin is rejected after normalization without mutation', () {
    final map = _map([_instance]);
    expect(
      () => setMapPlacedElementGeometry(
        map,
        manifest: _project,
        instanceId: 'placed',
        pixelX: -1,
        pixelY: 0,
        pixelSize: const PixelSize(width: 1, height: 1),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(map.placedElements.single, _instance);
  });

  test('invalid sizes and generated transformations are rejected', () {
    for (final instance in [
      _instance.copyWith(pixelSize: const PixelSize(width: 0, height: 1)),
      _instance.copyWith(pixelSize: const PixelSize(width: 1, height: -1)),
      _instance.copyWith(pixelOffset: const PixelOffset(x: 16, y: 0)),
      _instance.copyWith(
        pixelSize: const PixelSize(width: 1, height: 1),
        properties: const {'pokemapPlacementOrigin': 'environment'},
      ),
    ]) {
      expect(
        () => MapValidator.validatePlacedElement(
          _map([instance]),
          instance,
          projectDialogueContext: _project,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('custom pixel area is bounded independently from map dimensions', () {
    final instance = _instance.copyWith(
      pos: const GridPos(x: 0, y: 0),
      pixelSize: const PixelSize(width: 1024, height: 1025),
    );
    expect(
      () => MapValidator.validatePlacedElement(
        _map([
          instance,
        ]).copyWith(size: const GridSize(width: 128, height: 128)),
        instance,
        projectDialogueContext: _project,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('atlas offsets stay visual and pixel selection covers all frames', () {
    final element = _element.copyWith(
      frames: [
        _element.frames.first,
        _element.frames.first.copyWith(tilesetId: 'other'),
      ],
    );
    final project = _project.copyWith(
      elements: [element],
      tilesets: [_atlas('ts', 5, -7), _atlas('other', -9, 4)],
    );
    final instance = _instance.copyWith(
      quarterTurns: 1,
      pixelSize: const PixelSize(width: 3, height: 5),
    );
    final map = _map([instance]);
    for (final sample in [(21, 25, true), (7, 36, true), (16, 32, false)]) {
      expect(
        mapPlacedElementsAtPixel(
          map,
          project,
          PixelPosition(leftPx: sample.$1, topPx: sample.$2),
          layerId: 'decor',
        ).isNotEmpty,
        sample.$3,
      );
    }
    expect(
      _rect(
        resolveMapPlacedElementGeometry(
          instance: instance,
          element: element,
          tileSize: _tileSize,
        ).logicalRect,
      ),
      [16, 32, 3, 5],
    );
    expect(
      _rect(
        resolveMapPlacedElementVisualBounds(
          instance: instance,
          element: element,
          manifest: project,
        ),
      ),
      [7, 25, 17, 16],
    );
  });

  test('delta validation agrees with full placed element validation', () {
    for (final width in [17, 129]) {
      final before = _map([_instance]);
      final instance = _instance.copyWith(
        pixelSize: PixelSize(width: width, height: 1),
      );
      final after = before.copyWith(placedElements: [instance]);
      final context = DeltaValidationContext(
        before: before,
        after: after,
        project: _project,
        delta: MapMutationDelta.placedElement(
          instance: instance,
          instanceIndex: 0,
        ),
      );
      if (width == 17) {
        expect(
          MapDeltaValidator.validate(context).inspectedPlacedElementCount,
          1,
        );
        expect(
          () => MapValidator.validatePlacedElement(
            after,
            instance,
            projectDialogueContext: _project,
          ),
          returnsNormally,
        );
      } else {
        expect(
          () => MapDeltaValidator.validate(context),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapValidator.validatePlacedElement(
            after,
            instance,
            projectDialogueContext: _project,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    }
  });

  test('pixel budget accepts its edge and does not cap natural assets', () {
    expect(
      () => resolveMapPlacedElementGeometry(
        instance: _instance.copyWith(
          pixelSize: const PixelSize(width: 1024, height: 1024),
        ),
        element: _element,
        tileSize: _tileSize,
      ),
      returnsNormally,
    );
    final large = _element.copyWith(
      frames: const [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 128, height: 128),
        ),
      ],
    );
    expect(
      resolveMapPlacedElementGeometry(
        instance: _instance.copyWith(
          pixelOffset: const PixelOffset(x: 1, y: 1),
        ),
        element: large,
        tileSize: _tileSize,
      ).pixelSize,
      const PixelSize(width: 2048, height: 4096),
    );
  });

  test('geometry rejects coordinates beyond exact integer representation', () {
    expect(
      () => resolveMapPlacedElementGeometry(
        instance: _instance.copyWith(
          pos: const GridPos(x: 9007199254740991, y: 0),
        ),
        element: _element,
        tileSize: _tileSize,
      ),
      throwsA(isA<ValidationException>()),
    );
    for (final value in [1.5, true, '3', 9007199254740992, null]) {
      expect(
        () => PixelOffset.fromJson({'x': value, 'y': 0}),
        throwsFormatException,
      );
      expect(
        () => PixelSize.fromJson({'width': 1, 'height': value}),
        throwsFormatException,
      );
    }
  });
}

ProjectTilesetEntry _atlas(String id, int dx, int dy) => ProjectTilesetEntry(
  id: id,
  name: id,
  relativePath: '$id.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: '$id.png',
    pixelWidth: 64,
    pixelHeight: 64,
    tileWidth: 16,
    tileHeight: 32,
    pixelOffsetX: dx,
    pixelOffsetY: dy,
  ),
);

List<int> _rect(PixelRect rect) => [
  rect.leftPx,
  rect.topPx,
  rect.widthPx,
  rect.heightPx,
];

const _tileSize = PixelSize(width: 16, height: 32);

const _element = ProjectElementEntry(
  id: 'wide',
  name: 'Wide',
  tilesetId: 'ts',
  categoryId: 'cat',
  frames: [
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
    ),
  ],
);

final _project = ProjectManifest(
  name: 'Geometry',
  maps: const [],
  tilesets: const [],
  elements: const [_element],
  settings: const ProjectSettings(tileWidth: 16, tileHeight: 32),
);

MapData _map(List<MapPlacedElement> instances) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 8, height: 8),
  layers: [
    MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(64, 0)),
  ],
  placedElements: instances,
);

const _instance = MapPlacedElement(
  id: 'placed',
  layerId: 'decor',
  elementId: 'wide',
  pos: GridPos(x: 1, y: 1),
  properties: {'pokemapPlacementOrigin': 'authored'},
);
