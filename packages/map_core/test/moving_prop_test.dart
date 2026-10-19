import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('prop definitions round trip with strict pixel geometry', () {
    final definition = _prop();
    expect(MovingPropDefinition.fromJson(definition.toJson()), definition);
    expect(MapData.fromJson(_map().toJson()).movingProps, [definition]);
    for (final invalid in [
      {...definition.toJson(), 'legacy': true},
      {
        ...definition.toJson(),
        'closedPositionPx': {'x': 32.0, 'y': 32},
      },
      {...definition.toJson(), 'initialState': 'moving'},
      {
        ...definition.toJson(),
        'openPositionPx': {'x': 64, 'y': 64},
      },
      {
        ...definition.toJson(),
        'openPositionPx': {'x': 32, 'y': 32},
      },
      {
        ...definition.toJson(),
        'collisionRect': {
          'leftPx': 0,
          'topPx': 0,
          'widthPx': 0,
          'heightPx': 16,
        },
      },
    ]) {
      expect(
        () => MovingPropDefinition.fromJson(invalid),
        throwsFormatException,
      );
    }
  });

  test('settled prop state is immutable and survives both save paths', () {
    final source = <String, Map<String, MovingPropState>>{
      'room': {'gate': MovingPropState.open},
    };
    final state = MovingPropWorldState(propsByMap: source);
    source['room']!['gate'] = MovingPropState.closed;
    expect(state.prop('room', 'gate'), MovingPropState.open);
    expect(
      () => state.propsByMap['room']!['gate'] = MovingPropState.closed,
      throwsUnsupportedError,
    );
    expect(MovingPropWorldState.fromJson(state.toJson()), state);
    final game = GameState(saveId: 'save', movingPropWorldState: state);
    expect(
      gameStateFromStrictSaveJson(
        strictGameStateSaveJson(game),
      ).movingPropWorldState,
      state,
    );
    expect(
      gameStateFromSaveData(saveDataFromGameState(game)).movingPropWorldState,
      state,
    );
    expect(
      SaveData.fromJson(
        saveDataFromGameState(game).toJson(),
      ).movingPropWorldState,
      state,
    );
    for (final invalid in [
      {...state.toJson(), 'schemaVersion': 2},
      {...state.toJson(), 'schemaVersion': 1.0},
      {...state.toJson(), 'unexpected': true},
      {
        'schemaVersion': 1,
        'propsByMap': {
          'room': {'gate': 'moving'},
        },
      },
    ]) {
      expect(
        () => MovingPropWorldState.fromJson(invalid),
        throwsFormatException,
      );
    }
    final missing = strictGameStateSaveJson(game)
      ..remove('movingPropWorldState');
    expect(() => gameStateFromStrictSaveJson(missing), throwsFormatException);
  });

  test('initialization preserves settled poses and rejects missing props', () {
    final existing = const MovingPropWorldState.empty().withProp(
      mapId: 'room',
      propId: 'gate',
      state: MovingPropState.open,
    );
    expect(
      initializeMovingPropWorldState(map: _map(), worldState: existing),
      existing,
    );
    expect(
      initializeMovingPropWorldState(
        map: _map(),
        worldState: const MovingPropWorldState.empty(),
      ).prop('room', 'gate'),
      MovingPropState.closed,
    );
    expect(
      () => initializeMovingPropWorldState(
        map: _map(),
        worldState: existing.withProp(
          mapId: 'room',
          propId: 'unknown',
          state: MovingPropState.open,
        ),
      ),
      throwsFormatException,
    );
  });

  test('projection moves only its visual and projects a dynamic footprint', () {
    final map = _map();
    final state = const MovingPropWorldState.empty().withProp(
      mapId: 'room',
      propId: 'gate',
      state: MovingPropState.open,
    );
    final projected = applyMovingPropWorldStateToMap(
      map: map,
      worldState: state,
      tileSize: _tile,
    );
    final visual = projected.placedElements.first;
    expect(visual.pos, const GridPos(x: 2, y: 1));
    expect(visual.pixelOffset, const PixelOffset(x: 0, y: 0));
    expect(visual.applyCollision, isFalse);
    expect(visual.opacity, .75);
    expect(visual.properties, map.placedElements.first.properties);
    expect(projected.placedElements.last, map.placedElements.last);
    final rect = movingPropCollisionRects(map: map, worldState: state).single;
    expect(
      [rect.leftPx, rect.topPx, rect.widthPx, rect.heightPx],
      [68, 40, 16, 16],
    );
    final intermediate = applyMovingPropWorldStateToMap(
      map: map,
      worldState: state,
      tileSize: _tile,
      positions: {'gate': const PixelOffset(x: 45, y: 32)},
    );
    expect(
      intermediate.placedElements.first.pixelOffset,
      const PixelOffset(x: 13, y: 0),
    );
    expect(
      movingPropCollisionRects(
        map: map,
        worldState: state,
        positions: {'gate': const PixelOffset(x: 45, y: 32)},
      ).single.leftPx,
      49,
    );
    expect(
      () => movingPropCollisionRects(
        map: map,
        worldState: state,
        positions: {'unknown': const PixelOffset(x: 45, y: 32)},
      ).toList(),
      throwsFormatException,
    );
    expect(
      () => applyMovingPropWorldStateToMap(
        map: map,
        worldState: state,
        tileSize: _tile,
        positions: {'gate': const PixelOffset(x: 45, y: 33)},
      ),
      throwsFormatException,
    );
  });

  test(
    'map validation rejects duplicate ownership and out of bounds poses',
    () {
      validateMovingPropDefinitions(
        map: _map(),
        project: _project(),
        tileSize: _tile,
      );
      final invalidMaps = [
        _map().copyWith(movingProps: [_prop(), _prop()]),
        _map().copyWith(
          movingProps: [
            _prop(),
            _prop(id: 'second'),
          ],
        ),
        _map().copyWith(
          movingProps: [_prop(open: const PixelOffset(x: 320, y: 32))],
        ),
        _map().copyWith(placedElements: []),
        _map().copyWith(
          placedElements: [
            _map().placedElements.first.copyWith(properties: {}),
          ],
        ),
      ];
      for (final invalid in invalidMaps) {
        expect(
          () => validateMovingPropDefinitions(
            map: invalid,
            project: _project(),
            tileSize: _tile,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => validateMovingPropDefinitions(
          map: _map(),
          project: _project().copyWith(elements: []),
          tileSize: _tile,
        ),
        throwsFormatException,
      );
      expect(
        () => validateMovingPropDefinitions(
          map: _map(),
          project: _project().copyWith(
            elements: [_project().elements.first.copyWith(frames: [])],
          ),
          tileSize: _tile,
        ),
        throwsFormatException,
      );
      expect(
        () => validateMovingPropWorldState(
          project: _project(),
          maps: [_map()],
          worldState: const MovingPropWorldState.empty().withProp(
            mapId: 'missing',
            propId: 'gate',
            state: MovingPropState.open,
          ),
        ),
        throwsFormatException,
      );
    },
  );

  for (final (name, patch) in <(String, Map<String, dynamic>)>[
    ('empty identity', {'id': ''}),
    ('padded identity', {'id': ' gate'}),
    (
      'negative position',
      {
        'closedPositionPx': {'x': -1, 'y': 32},
      },
    ),
    (
      'position unknown field',
      {
        'closedPositionPx': {'x': 32, 'y': 32, 'z': 0},
      },
    ),
    (
      'fractional position',
      {
        'closedPositionPx': {'x': 32.5, 'y': 32},
      },
    ),
    (
      'unrepresentable position',
      {
        'closedPositionPx': {'x': 9007199254740992, 'y': 32},
      },
    ),
    (
      'motion over budget',
      {
        'openPositionPx': {'x': 1057, 'y': 32},
      },
    ),
    (
      'negative footprint offset',
      {
        'collisionRect': {
          'leftPx': -1,
          'topPx': 0,
          'widthPx': 16,
          'heightPx': 16,
        },
      },
    ),
    (
      'footprint over budget',
      {
        'collisionRect': {
          'leftPx': 0,
          'topPx': 0,
          'widthPx': 1025,
          'heightPx': 16,
        },
      },
    ),
    (
      'footprint unknown field',
      {
        'collisionRect': {
          'leftPx': 0,
          'topPx': 0,
          'widthPx': 16,
          'heightPx': 16,
          'legacy': true,
        },
      },
    ),
  ]) {
    test('definition refuses $name', () {
      expect(
        () => MovingPropDefinition.fromJson({..._prop().toJson(), ...patch}),
        throwsFormatException,
      );
    });
  }

  test('definition accepts reversed rails and maximum motion', () {
    final definition = MovingPropDefinition.fromJson({
      ..._prop().toJson(),
      'closedPositionPx': {'x': 1024, 'y': 32},
      'openPositionPx': {'x': 0, 'y': 32},
    });
    expect(definition.openPositionPx.x, 0);
    final state = initializeMovingPropWorldState(
      map: _map().copyWith(
        movingProps: [
          MovingPropDefinition.fromJson({
            ..._prop().toJson(),
            'initialState': 'open',
          }),
        ],
      ),
      worldState: const MovingPropWorldState.empty(),
    );
    expect(state.prop('room', 'gate'), MovingPropState.open);
  });

  test('validation refuses 3D, undersized visuals and duplicate maps', () {
    expect(
      () => validateMovingPropDefinitions(
        map: _map().copyWith(version: ProjectVersion.v9),
        project: _project(),
        tileSize: _tile,
      ),
      throwsFormatException,
    );
    expect(
      () => validateMovingPropDefinitions(
        map: _map(),
        project: _project(),
        tileSize: const PixelSize(width: 0, height: 32),
      ),
      throwsFormatException,
    );
    final tiny = _map().copyWith(
      placedElements: [
        _map().placedElements.first.copyWith(
          pixelSize: const PixelSize(width: 8, height: 8),
        ),
      ],
    );
    expect(
      () => validateMovingPropDefinitions(
        map: tiny,
        project: _project(),
        tileSize: _tile,
      ),
      throwsFormatException,
    );
    expect(
      () => validateMovingPropWorldState(
        project: _project(),
        maps: [_map(), _map()],
        worldState: const MovingPropWorldState.empty(),
      ),
      throwsFormatException,
    );
  });

  test('a moving platform cannot own the same placed visual', () {
    final platform = MovingPlatformDefinition.fromJson({
      'id': 'platform',
      'placedElementId': 'visual',
      'initialPose': {'leftPx': 32, 'topPx': 32, 'quarterTurns': 0},
      'lattice': {
        'originLeftPx': 32,
        'originTopPx': 32,
        'widthPx': 32,
        'heightPx': 32,
        'cellOffsetLeftPx': 0,
        'cellOffsetTopPx': 0,
      },
      'translationDistanceCells': 1,
      'variants': [
        for (var index = 0; index < 4; index++)
          {
            'elementId': 'gate-visual',
            'anchorOffsetPx': {'x': 0, 'y': 0},
            'supportCells': [
              {'x': 0, 'y': 0},
            ],
            'clearanceCells': [
              {'x': 0, 'y': 0},
            ],
            'rotationClearanceCells': [
              {'x': 0, 'y': 0},
            ],
            'forwardClearanceCells': [
              {'x': 0, 'y': 0},
            ],
            'backwardClearanceCells': [
              {'x': 0, 'y': 0},
            ],
          },
      ],
      'terrainLayerIds': ['terrain'],
      'travelCells': [
        {'x': 0, 'y': 0},
        {'x': 1, 'y': 0},
      ],
    });
    expect(
      () => validateMovingPropDefinitions(
        map: _map().copyWith(movingPlatforms: [platform]),
        project: _project(),
        tileSize: _tile,
      ),
      throwsFormatException,
    );
  });

  test('maps bound the number of moving prop definitions', () {
    final crowded = _map().copyWith(
      movingProps: [
        for (var index = 0; index < 257; index++)
          MovingPropDefinition.fromJson({
            ..._prop().toJson(),
            'id': 'prop-$index',
            'placedElementId': 'visual-$index',
          }),
      ],
    );
    expect(
      () => initializeMovingPropWorldState(
        map: crowded,
        worldState: const MovingPropWorldState.empty(),
      ),
      throwsFormatException,
    );
  });

  test('direct definition construction refuses overflowing rectangles', () {
    expect(
      () => MovingPropDefinition(
        id: 'gate',
        placedElementId: 'visual',
        closedPositionPx: const PixelOffset(x: 32, y: 32),
        openPositionPx: const PixelOffset(x: 64, y: 32),
        collisionRect: const PixelRect(
          leftPx: 4,
          topPx: 8,
          widthPx: 9223372036854775807,
          heightPx: 16,
        ),
      ),
      throwsFormatException,
    );
  });
}

const _tile = PixelSize(width: 32, height: 32);

MovingPropDefinition _prop({
  String id = 'gate',
  PixelOffset open = const PixelOffset(x: 64, y: 32),
}) => MovingPropDefinition(
  id: id,
  placedElementId: 'visual',
  closedPositionPx: const PixelOffset(x: 32, y: 32),
  openPositionPx: open,
  collisionRect: const PixelRect(
    leftPx: 4,
    topPx: 8,
    widthPx: 16,
    heightPx: 16,
  ),
);

MapData _map() => MapData(
  id: 'room',
  name: 'Room',
  size: const GridSize(width: 10, height: 10),
  movingProps: [_prop()],
  placedElements: const [
    MapPlacedElement(
      id: 'visual',
      layerId: 'decor',
      elementId: 'gate-visual',
      pos: GridPos(x: 1, y: 1),
      opacity: .75,
      properties: {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    ),
    MapPlacedElement(
      id: 'other',
      layerId: 'decor',
      elementId: 'gate-visual',
      pos: GridPos(x: 0, y: 0),
    ),
  ],
);

ProjectManifest _project() => const ProjectManifest(
  name: 'Props',
  maps: [],
  tilesets: [],
  elements: [
    ProjectElementEntry(
      id: 'gate-visual',
      name: 'Gate',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
);
