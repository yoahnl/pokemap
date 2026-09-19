import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('incompatible split decoration is not crossed by a local step', () {
    final manifest = _manifest.copyWith(
      elements: [
        ..._manifest.elements,
        _manifest.elements.last.copyWith(
          id: 'split',
          collisionProfile: const ElementCollisionProfile(
            cells: [GridPos(x: 0, y: 0)],
          ),
        ),
      ],
    );
    final map = _map().copyWith(
      placedElements: [
        _instance('a'),
        _instance('split').copyWith(elementId: 'split'),
        _instance('b'),
      ],
    );
    expect(
      moveMapPlacedElementVisualOrder(
        map,
        manifest: manifest,
        instanceId: 'a',
        forward: true,
      ),
      same(map),
    );
  });

  test('visual rank round trips independently of list and properties', () {
    final source = _instance('a').copyWith(visualOrder: -4);
    expect(MapPlacedElement.fromJson(source.toJson()), source);
    final json = source.toJson()..remove('visualOrder');
    expect(MapPlacedElement.fromJson(json).visualOrder, 0);
    for (final invalid in [1.5, '1', true]) {
      expect(
        () => MapPlacedElement.fromJson({...json, 'visualOrder': invalid}),
        throwsFormatException,
      );
    }
  });

  test('equal ranks are deterministic and sorting never mutates input', () {
    final map = _map();
    expect(_ids(sortMapPlacedElementsForPainting(map.placedElements)), [
      'a',
      'b',
      'c',
      'far',
      'other',
    ]);
    expect(_ids(map.placedElements), ['a', 'b', 'c', 'far', 'other']);
  });

  test(
    'one forward step preserves serialized gameplay priority and all data',
    () {
      final before = _map();
      final after = moveMapPlacedElementVisualOrder(
        before,
        manifest: _manifest,
        instanceId: 'a',
        forward: true,
      );
      expect(_ids(after.placedElements), _ids(before.placedElements));
      expect(
        _ids(
          mapPlacedElementsAt(
            after,
            _manifest,
            const GridPos(x: 1, y: 1),
            layerId: 'decor',
          ),
        ),
        ['b', 'a', 'c'],
      );
      for (var i = 0; i < before.placedElements.length; i++) {
        final original = before.placedElements[i].toJson()
          ..remove('visualOrder');
        final updated = after.placedElements[i].toJson()..remove('visualOrder');
        expect(updated, original);
      }
      expect(after.layers, before.layers);
      expect(after.placedElements.last, before.placedElements.last);
    },
  );

  test('backward, extremes and removal keep a usable stable local stack', () {
    final before = _map();
    expect(
      moveMapPlacedElementVisualOrder(
        before,
        manifest: _manifest,
        instanceId: 'a',
        forward: false,
      ),
      same(before),
    );
    expect(
      moveMapPlacedElementVisualOrder(
        before,
        manifest: _manifest,
        instanceId: 'c',
        forward: true,
      ),
      same(before),
    );
    final moved = moveMapPlacedElementVisualOrder(
      before,
      manifest: _manifest,
      instanceId: 'c',
      forward: false,
    );
    final removed = removeMapPlacedElement(moved, instanceId: 'b');
    final after = moveMapPlacedElementVisualOrder(
      removed,
      manifest: _manifest,
      instanceId: 'c',
      forward: false,
    );
    expect(
      _ids(
        mapPlacedElementsAt(
          after,
          _manifest,
          const GridPos(x: 1, y: 1),
          layerId: 'decor',
        ),
      ),
      ['c', 'a'],
    );
  });

  test(
    'cursor outside selection and missing instances do not change the map',
    () {
      final map = _map();
      expect(
        moveMapPlacedElementVisualOrder(
          map,
          manifest: _manifest,
          instanceId: 'a',
          forward: true,
          at: const GridPos(x: 8, y: 8),
        ),
        same(map),
      );
      expect(
        () => moveMapPlacedElementVisualOrder(
          map,
          manifest: _manifest,
          instanceId: 'absent',
          forward: true,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'hit testing uses rotated visual footprint and half-open cell edges',
    () {
      final map = _map().copyWith(
        placedElements: [
          _instance('rotated').copyWith(elementId: 'wide', quarterTurns: 1),
        ],
      );
      expect(
        _ids(
          mapPlacedElementsAt(
            map,
            _manifest,
            const GridPos(x: 1, y: 2),
            layerId: 'decor',
          ),
        ),
        ['rotated'],
      );
      expect(
        mapPlacedElementsAt(
          map,
          _manifest,
          const GridPos(x: 2, y: 1),
          layerId: 'decor',
        ),
        isEmpty,
      );
    },
  );

  test(
    'unfiltered stack follows visible composition layers before local ranks',
    () {
      final map = _map().copyWith(
        layers: [
          MapLayer.tile(id: 'upper', name: 'Upper', cells: List.filled(100, 0)),
          MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(100, 0)),
          MapLayer.tile(
            id: 'hidden',
            name: 'Hidden',
            isVisible: false,
            cells: List.filled(100, 0),
          ),
        ],
        placedElements: [
          _instance('upper').copyWith(layerId: 'upper', visualOrder: -100),
          _instance('lower').copyWith(visualOrder: 100),
          _instance('hidden').copyWith(layerId: 'hidden', visualOrder: 1000),
        ],
      );
      expect(
        _ids(mapPlacedElementsAt(map, _manifest, const GridPos(x: 1, y: 1))),
        ['lower', 'upper'],
      );
    },
  );

  test(
    'foreground is picked above later background layers independently of rank',
    () {
      final map = _map().copyWith(
        layers: [
          MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(100, 0)),
          MapLayer.tile(id: 'roof', name: 'Roof', cells: List.filled(100, 0)),
        ],
        placedElements: [
          _instance('roof').copyWith(layerId: 'roof', visualOrder: -100),
          _instance('background').copyWith(visualOrder: 100),
        ],
      );
      expect(
        _ids(mapPlacedElementsAt(map, _manifest, const GridPos(x: 1, y: 1))),
        ['background', 'roof'],
      );
    },
  );
}

List<String> _ids(Iterable<MapPlacedElement> values) =>
    values.map((e) => e.id).toList();

MapPlacedElement _instance(String id) => MapPlacedElement(
  id: id,
  layerId: 'decor',
  elementId: 'small',
  pos: const GridPos(x: 1, y: 1),
  opacity: 0.7,
  properties: const {'kept': 'exact'},
  behaviors: const [
    MapPlacedElementBehavior(
      id: 'interaction',
      effect: MapPlacedElementEffect(
        type: MapPlacedElementEffectType.showMessage,
        message: 'priority',
      ),
    ),
  ],
);

MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 10, height: 10),
  layers: const [],
  placedElements: [
    _instance('a'),
    _instance('b'),
    _instance('c'),
    _instance('far').copyWith(pos: const GridPos(x: 8, y: 8)),
    _instance('other').copyWith(layerId: 'other'),
  ],
);

final _manifest = ProjectManifest(
  name: 'Order fixture',
  maps: const [],
  tilesets: const [],
  elements: const [
    ProjectElementEntry(
      id: 'small',
      name: 'Small',
      tilesetId: 'ts',
      categoryId: 'cat',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'wide',
      name: 'Wide',
      tilesetId: 'ts',
      categoryId: 'cat',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
        ),
      ],
    ),
  ],
);
