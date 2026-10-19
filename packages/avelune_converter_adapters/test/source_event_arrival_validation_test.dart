import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_arrival_validation.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _position = GridPos(x: 1, y: 1);
const _size = GridSize(width: 4, height: 4);

MapWarp _arrival(String id, GridPos pos, {String mapId = 'map'}) => MapWarp(
    id: id,
    pos: pos,
    targetMapId: mapId,
    targetPos: pos,
    triggerMode: MapWarpTriggerMode.sceneOnly);

MapData _map(
        {List<MapEntity> entities = const [],
        List<MapLayer> layers = const [],
        List<MapWarp>? warps,
        List<MapPlacedElement> placedElements = const []}) =>
    MapData(
        id: 'map',
        name: 'Destination',
        size: _size,
        layers: layers,
        entities: entities,
        placedElements: placedElements,
        warps: warps ?? [_arrival('arrival', _position)]);

ProjectManifest _manifest(MapData map,
        {List<ProjectElementEntry> elements = const [],
        List<WorldRuleDefinition> worldRules = const [],
        List<NarrativeFactDefinition> facts = const []}) =>
    ProjectManifest(
        name: 'Arrival guard',
        maps: [
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'tiles', name: 'Tiles', relativePath: 'assets/tiles.png')
        ],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        elementCategories: const [
          ProjectElementCategory(id: 'obstacles', name: 'Obstacles')
        ],
        elements: elements,
        worldRules: worldRules,
        facts: facts);

({MapData map, ProjectManifest manifest}) _maskFixture({required int localX}) {
  final pixels = List<bool>.filled(32 * 32, false);
  pixels[24 * 32 + localX] = true;
  final mask = ElementCollisionPixelMask(
      widthPx: 32,
      heightPx: 32,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 32, heightPx: 32, solidPixels: pixels));
  final element = ProjectElementEntry(
      id: 'wall',
      name: 'Wall',
      tilesetId: 'tiles',
      categoryId: 'obstacles',
      frames: const [
        TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
      ],
      collisionProfile: ElementCollisionProfile(collisionMask: mask));
  final map = _map(layers: const [
    TileLayer(id: 'base', name: 'Base', cells: [])
  ], placedElements: const [
    MapPlacedElement(
        id: 'placed',
        elementId: 'wall',
        layerId: 'base',
        pos: _position,
        applyCollision: true)
  ]);
  return (map: map, manifest: _manifest(map, elements: [element]));
}

Matcher _arrivalFailure(String code) => throwsA(
    isA<NativeWriteException>().having((error) => error.code, 'code', code));

void main() {
  test('arrival owner remains available without a runtime presentation state',
      () {
    final owner = MapEntity(
        id: 'door',
        kind: MapEntityKind.npc,
        pos: _position,
        npc: const MapEntityNpcData(characterId: 'doorCharacter'),
        properties: const {
          mapEntityCollisionWidthProperty: '1',
          mapEntityCollisionHeightProperty: '1',
          mapEntityCollisionOffsetYProperty: '0',
        },
        presentation: MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'closed',
              condition: NarrativeEventConditionExpression.all(const []),
              characterId: 'doorCharacter',
              blocksMovement: true),
        ]));
    final map = _map(entities: [owner]);
    final manifest = _manifest(map).copyWith(characters: const [
      ProjectCharacterEntry(
          id: 'doorCharacter',
          name: 'Door',
          tilesetId: 'tiles',
          frameHeight: 1),
    ]);
    final before = map.toJson();
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: manifest,
            maps: [map],
            arrivalAnchorIds: ['arrival'],
            arrivalCollisionOwners: {'arrival': 'door'}),
        returnsNormally);
    expect(map.toJson(), before);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: manifest.copyWith(characters: const []),
            maps: [map],
            arrivalAnchorIds: ['arrival'],
            arrivalCollisionOwners: {'arrival': 'door'}),
        _arrivalFailure('events.arrival.binding'));
  });

  for (final baseBlocks in [false, true]) {
    test('arrival rejects a presented blocker with baseBlocks=$baseBlocks', () {
      final entity = MapEntity(
          id: 'other',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 1),
          blocksMovement: baseBlocks,
          presentation: MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'blocking',
                condition: NarrativeEventConditionExpression.all(const []),
                blocksMovement: true,
                size: const GridSize(width: 2, height: 1)),
          ]));
      final map = _map(entities: [entity]);
      final before = map.toJson();
      expect(
          () => const SourceEventArrivalValidator().validate(
              manifest: _manifest(map),
              maps: [map],
              arrivalAnchorIds: ['arrival']),
          _arrivalFailure('events.arrival.blocked'));
      expect(map.toJson(), before);
    });
  }

  test('arrival preserves authored collision offsets across variant sizes', () {
    final entity = MapEntity(
        id: 'offset',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 3, height: 2),
        blocksMovement: true,
        properties: const {
          mapEntityCollisionWidthProperty: '1',
          mapEntityCollisionHeightProperty: '1',
          mapEntityCollisionOffsetXProperty: '2',
          mapEntityCollisionOffsetYProperty: '1',
        },
        presentation: MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'small',
              condition: NarrativeEventConditionExpression.all(const []),
              blocksMovement: true),
          MapEntityPresentationVariant(
              id: 'wide',
              condition: NarrativeEventConditionExpression.all(const []),
              blocksMovement: true,
              size: const GridSize(width: 2, height: 1)),
        ]));
    for (final position in [
      const GridPos(x: 2, y: 1),
      const GridPos(x: 3, y: 2),
    ]) {
      final map =
          _map(entities: [entity], warps: [_arrival('arrival', position)]);
      expect(
          () => const SourceEventArrivalValidator().validate(
              manifest: _manifest(map),
              maps: [map],
              arrivalAnchorIds: ['arrival']),
          position.x == 2
              ? _arrivalFailure('events.arrival.blocked')
              : returnsNormally);
    }
  });

  test('arrival keeps a through presentation passable', () {
    final map = _map(entities: [
      MapEntity(
          id: 'through',
          kind: MapEntityKind.custom,
          pos: _position,
          blocksMovement: false,
          presentation: MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'through',
                condition: NarrativeEventConditionExpression.all(const []),
                blocksMovement: false),
          ])),
    ]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['arrival']),
        returnsNormally);
  });

  test('arrival binding error identifies its map warp owner and exact cause',
      () {
    final owner = MapEntity(
        id: 'door',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 1),
        npc: const MapEntityNpcData(characterId: 'doorCharacter'));
    final map = _map(entities: [owner]);
    final manifest = _manifest(map).copyWith(characters: const [
      ProjectCharacterEntry(
          id: 'doorCharacter',
          name: 'Door',
          tilesetId: 'tiles',
          frameHeight: 1),
    ]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: manifest,
            maps: [map],
            arrivalAnchorIds: ['arrival'],
            arrivalCollisionOwners: {'arrival': 'door'}),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'events.arrival.binding')
            .having((error) => error.message, 'map', contains('map=map'))
            .having((error) => error.message, 'warp', contains('warp=arrival'))
            .having((error) => error.message, 'owner', contains('owner=door'))
            .having((error) => error.message, 'position', contains('(1,1)'))
            .having(
                (error) => error.message, 'cause', contains('exact anchor'))));
  });

  test('rejects an active or nonlocal destination marker', () {
    for (final warp in [
      _arrival('arrival', _position)
          .copyWith(triggerMode: MapWarpTriggerMode.onBump),
      _arrival('arrival', _position).copyWith(
          triggerMode: MapWarpTriggerMode.sceneOnly, targetMapId: 'other'),
    ]) {
      final map = _map(warps: [warp]);
      expect(
          () => const SourceEventArrivalValidator().validate(
              manifest: _manifest(map),
              maps: [map],
              arrivalAnchorIds: ['arrival']),
          _arrivalFailure('events.arrival.binding'));
    }
  });

  test('explicit owner admits only its collision and keeps a second blocker',
      () {
    final owner = MapEntity(
        id: 'door',
        kind: MapEntityKind.npc,
        pos: _position,
        npc: const MapEntityNpcData(characterId: 'doorCharacter'),
        properties: const {
          mapEntityCollisionWidthProperty: '1',
          mapEntityCollisionHeightProperty: '1',
          mapEntityCollisionOffsetYProperty: '0'
        });
    for (final other in [false, true]) {
      final map =
          _map(entities: [owner, if (other) owner.copyWith(id: 'other')]);
      final manifest = _manifest(map).copyWith(characters: const [
        ProjectCharacterEntry(
            id: 'doorCharacter',
            name: 'Door',
            tilesetId: 'tiles',
            frameHeight: 1),
      ]);
      void operation() => const SourceEventArrivalValidator().validate(
          manifest: manifest,
          maps: [map],
          arrivalAnchorIds: ['arrival'],
          arrivalCollisionOwners: {'arrival': 'door'});
      expect(operation,
          other ? _arrivalFailure('events.arrival.blocked') : returnsNormally);
      expect(map.entities.first, owner);
    }
  });

  test('accepts a free canonical destination without altering project data',
      () {
    final map = _map();
    final manifest = _manifest(map);
    final before = map.toJson();
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: manifest, maps: [map], arrivalAnchorIds: ['arrival']),
        returnsNormally);
    expect(map.toJson(), before);
  });

  test('rejects a full collision cell at the arrival', () {
    final collisions = List<bool>.filled(16, false)..[5] = true;
    final map = _map(layers: [
      CollisionLayer(id: 'collision', name: 'Collision', collisions: collisions)
    ]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['arrival']),
        _arrivalFailure('events.arrival.blocked'));
  });

  test(
      'rejects a pixel mask overlapping the hitbox while the cell centre is free',
      () {
    final fixture = _maskFixture(localX: 16);
    final world = GameplayWorldState.initial(
        map: fixture.map,
        project: fixture.manifest,
        playerPos: _position,
        tileWidth: 32,
        tileHeight: 32);
    expect(world.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1), isFalse);
    expect(world.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: fixture.manifest,
            maps: [fixture.map],
            arrivalAnchorIds: ['arrival']),
        _arrivalFailure('events.arrival.blocked'));
  });

  test('accepts a pixel mask outside the hitbox in the same authored cell', () {
    final fixture = _maskFixture(localX: 0);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: fixture.manifest,
            maps: [fixture.map],
            arrivalAnchorIds: ['arrival']),
        returnsNormally);
  });

  test('rejects future projected blocking entities despite their hiding rule',
      () {
    final entity = MapEntity(
        id: 'future',
        name: 'Future object',
        kind: MapEntityKind.custom,
        pos: _position,
        blocksMovement: true,
        properties: {
          mapEntityCollisionWidthProperty: '1',
          mapEntityCollisionHeightProperty: '1'
        });
    final map = _map(entities: [entity]);
    final fact = addNarrativeFact(_manifest(map), label: 'Hide future object')
        .createdFact;
    final manifest = _manifest(map, facts: [fact]);
    final rule = addWorldRule(manifest,
        label: 'Initially hidden',
        source: WorldRuleSource.factValue(
            factId: fact.id,
            operator: NarrativeFactOperator.equals,
            expectedValue: const NarrativeValue.boolean(false)),
        target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map',
            entityId: 'future'),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
        maps: [map]).createdRule;
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: manifest.copyWith(worldRules: [rule]),
            maps: [map],
            arrivalAnchorIds: ['arrival']),
        _arrivalFailure('events.arrival.blocked'));
  });

  test('allows through entities at the destination', () {
    final map = _map(entities: const [
      MapEntity(
          id: 'through',
          name: 'Through',
          kind: MapEntityKind.custom,
          pos: _position,
          blocksMovement: false)
    ]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['arrival']),
        returnsNormally);
  });

  test('checks each anchor after a free anchor on the same map', () {
    final map = _map(warps: [
      _arrival('first', const GridPos(x: 0, y: 0)),
      _arrival('second', _position)
    ], entities: const [
      MapEntity(
          id: 'solid',
          name: 'Solid',
          kind: MapEntityKind.custom,
          pos: _position,
          blocksMovement: true,
          properties: {
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1'
          })
    ]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['first', 'second']),
        _arrivalFailure('events.arrival.blocked'));
  });

  test('requires every requested anchor to resolve exactly once', () {
    final map = _map();
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['missing']),
        _arrivalFailure('events.arrival.binding'));
    final duplicate = map.copyWith(warps: [map.warps.single, map.warps.single]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(duplicate),
            maps: [duplicate],
            arrivalAnchorIds: ['arrival']),
        _arrivalFailure('events.arrival.binding'));
  });

  test(
      'rejects an out of bounds anchor before a clamped player spawn can hide it',
      () {
    final map = _map(warps: [_arrival('arrival', const GridPos(x: 4, y: 1))]);
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['arrival']),
        _arrivalFailure('events.arrival.bounds'));
  });

  test('honours cancellation before querying collisions', () {
    final map = _map();
    final cancellation = ScanCancellation()..cancel();
    expect(
        () => const SourceEventArrivalValidator().validate(
            manifest: _manifest(map),
            maps: [map],
            arrivalAnchorIds: ['arrival'],
            cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
  });
}
