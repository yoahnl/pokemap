import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final field in ['shadowCatalog', 'projectedBuildingShadowCatalog']) {
    for (final value in _retiredValues) {
      test('manifest abandons removed $field with $value', () {
        final original = _manifest();
        final decoded = ProjectManifest.fromJson(
          original.toJson()..[field] = value,
        );
        expect(decoded, original);
        expect(decoded.toJson(), original.toJson());
        expect(decoded.toJson().keys, isNot(contains(field)));
      });
    }
  }

  for (final field in ['shadow', 'projectedBuildingShadow']) {
    for (final value in _retiredValues) {
      test('element abandons removed $field with $value', () {
        final decoded = ProjectElementEntry.fromJson(
          _element.toJson()..[field] = value,
        );
        expect(decoded, _element);
        expect(decoded.toJson(), _element.toJson());
        expect(decoded.toJson().keys, isNot(contains(field)));
        final manifestJson = _manifest().toJson()
          ..['elements'] = [_element.toJson()..[field] = value];
        expect(ProjectManifest.fromJson(manifestJson), _manifest());
      });
    }
  }

  for (final value in _retiredValues) {
    test('placed element abandons removed shadowOverride with $value', () {
      final decoded = MapPlacedElement.fromJson(
        _placed.toJson()..['shadowOverride'] = value,
      );
      expect(decoded, _placed);
      expect(decoded.toJson(), _placed.toJson());
      expect(decoded.toJson().keys, isNot(contains('shadowOverride')));
      final mapJson = _map.toJson()
        ..['placedElements'] = [_placed.toJson()..['shadowOverride'] = value];
      expect(MapData.fromJson(mapJson), _map);
    });
  }

  test('Smart Tile rejects the removed render channel', () {
    final part = SmartTileVisualPart(
      source: SmartTileVisualSource.frame(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
      ),
    );
    expect(
      () => SmartTileVisualPart.fromJson(part.toJson()..['channel'] = 'shadow'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          allOf(contains('shadow'), contains('ground')),
        ),
      ),
    );
    expect(SmartTileRenderChannel.values.map((channel) => channel.name), [
      'ground',
      'understory',
      'canopy',
      'foreground',
      'actorOcclusion',
    ]);
  });

  test('current data round-trips without removed fields', () {
    final manifest = _manifest();
    final manifestJson = manifest.toJson();
    expect(manifestJson.keys, isNot(contains('shadowCatalog')));
    expect(
      manifestJson.keys,
      isNot(contains('projectedBuildingShadowCatalog')),
    );
    expect(_element.toJson().keys, isNot(contains('shadow')));
    expect(_element.toJson().keys, isNot(contains('projectedBuildingShadow')));
    expect(_placed.toJson().keys, isNot(contains('shadowOverride')));
    expect(ProjectManifest.fromJson(manifestJson), manifest);
    expect(MapData.fromJson(_map.toJson()), _map);
    expect(ProjectElementEntry.fromJson(_element.toJson()), _element);
    expect(MapPlacedElement.fromJson(_placed.toJson()), _placed);
  });

  for (final config in [null, MapVisualStackConfig.canonicalV1]) {
    test('composition retains the remaining paint order with $config', () {
      final plan = buildMapVisualCompositionPlan(
        _map.copyWith(visualStack: config),
      ).plan!;
      expect(plan.steps.map((step) => step.stableKey), [
        'tileBackgroundLayer:decor',
        'placedElements:decor',
        'backgroundEntities',
        'collisionOverlay',
        'foregroundTilesAndPlacedElements',
        'foregroundEntities',
      ]);
      expect(
        plan.strategy,
        config == null
            ? MapVisualCompositionStrategy.legacyPhased
            : MapVisualCompositionStrategy.authoredStack,
      );
      expect(plan.visibleTileLayersInPaintOrder, _map.layers);
      expect(
        MapVisualCompositionStepKind.values.map((kind) => kind.name),
        isNot(contains('shadows')),
      );
    });
  }
}

const _retiredValues = [
  null,
  <String, dynamic>{},
  {'enabled': true, 'profileId': 'old'},
];

ProjectManifest _manifest() => ProjectManifest(
  name: 'Current project',
  maps: const [],
  tilesets: const [],
  elements: [_element],
  pokemon: const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ),
);

const _element = ProjectElementEntry(
  id: 'tree',
  name: 'Tree',
  tilesetId: 'atlas',
  categoryId: 'decor',
  frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
  tags: ['tree', 'outdoor'],
  sortOrder: 3,
);

const _placed = MapPlacedElement(
  id: 'tree-1',
  layerId: 'decor',
  elementId: 'tree',
  pos: GridPos(x: 1, y: 1),
  quarterTurns: 1,
  opacity: 0.75,
  properties: {'ordinary': 'preserved'},
);

const _map = MapData(
  id: 'map',
  name: 'Current map',
  size: GridSize(width: 4, height: 4),
  layers: [
    MapLayer.tile(
      id: 'decor',
      name: 'Decor',
      cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
  ],
  placedElements: [_placed],
  properties: {'ordinary': 'preserved'},
);
