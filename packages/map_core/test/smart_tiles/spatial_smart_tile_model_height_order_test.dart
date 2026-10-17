import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('a flat model path clears its opaque PNG soil layer', () {
    final values = _resolve([_layer('path'), _layer('soil')]);
    expect(_height(values, 'path'), closeTo(.502, 1e-12));
    expect(values.single.blocksMovement, isFalse);
  });

  test('model overlays follow front-first layer reordering', () {
    final first = _resolve([_layer('upper'), _layer('lower'), _layer('soil')]);
    final second = _resolve([_layer('lower'), _layer('upper'), _layer('soil')]);
    expect(_height(first, 'upper'), closeTo(.503, 1e-12));
    expect(_height(first, 'lower'), closeTo(.502, 1e-12));
    expect(_height(second, 'upper'), _height(first, 'lower'));
    expect(_height(second, 'lower'), _height(first, 'upper'));
    expect(first.map((v) => v.id).toSet(), second.map((v) => v.id).toSet());
    expect(first.map((v) => v.position.x), everyElement(.5));
    expect(first.map((v) => v.position.z), everyElement(.5));
  });

  test('bottom-to-top stacks preserve the same authored order', () {
    final first = _resolve([_layer('upper'), _layer('lower'), _layer('soil')]);
    final second = _resolve(
      [_layer('soil'), _layer('lower'), _layer('upper')],
      properties: const {'tileLayerOrder': 'bottom_to_top'},
    );
    expect(_height(second, 'upper'), _height(first, 'upper'));
    expect(_height(second, 'lower'), _height(first, 'lower'));
  });

  test('canonical stacks override the old bottom-to-top property', () {
    final values = _resolve(
      [_layer('upper'), _layer('lower'), _layer('soil')],
      properties: const {'tileLayerOrder': 'bottom_to_top'},
      canonical: true,
    );
    expect(_height(values, 'upper'), closeTo(.503, 1e-12));
    expect(_height(values, 'lower'), closeTo(.502, 1e-12));
  });

  test('hidden and transparent layers reserve no paint height', () {
    final values = _resolve([
      _layer('upper'),
      _layer('hidden').copyWith(isVisible: false),
      _layer('transparent').copyWith(opacity: 0),
      _layer('soil'),
    ]);
    expect(values, hasLength(1));
    expect(values.single.position.y, closeTo(.502, 1e-12));
  });

  test('same-cell model parts follow drawOrder and stable ties', () {
    final values = _resolve(
      [_layer('path'), _layer('soil')],
      parts: {
        'path': [
          _part('high', order: 8),
          _part('low', order: -3),
          _part('last', order: 8),
        ],
      },
    );
    expect(_height(values, 'low'), lessThan(_height(values, 'high')));
    expect(_height(values, 'high'), lessThan(_height(values, 'last')));
    expect(_height(values, 'last'), lessThan(.503));
  });

  test('pattern model parts preserve their source drawOrder', () {
    final pattern = ProjectSmartTilePattern(
      id: 'motif',
      name: 'Motif',
      usage: SmartTileUsage.path,
      width: 1,
      height: 1,
      drawOrder: 10,
      cells: [
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: [_part('high', order: 2), _part('low', order: -2)],
        ),
      ],
    );
    final layer = _layer('path').copyWith(
      patternStrokes: const [
        SmartTilePatternStroke(
          id: 'paint',
          patternId: 'motif',
          cells: [GridPos(x: 0, y: 0)],
        ),
      ],
    );
    final values = _resolve([layer, _layer('soil')], patterns: [pattern]);
    expect(values, hasLength(2));
    expect(_height(values, 'high'), greaterThan(_height(values, 'low')));
  });

  test('absolute and replacement model heights remain exact', () {
    final values = _resolve(
      [_layer('absolute'), _layer('replacement'), _layer('soil')],
      parts: {
        'absolute': [_part('absolute', follow: false, y: -.25)],
        'replacement': [
          _part(
            'replacement',
            replace: true,
            y: .125,
            channel: SmartTileRenderChannel.ground,
          ),
        ],
      },
    );
    expect(_height(values, 'absolute'), -.25);
    expect(_height(values, 'replacement'), .625);
  });

  test('the authored local model height remains additive', () {
    final values = _resolve(
      [_layer('path'), _layer('soil')],
      parts: {
        'path': [_part('path', y: .125)],
      },
    );
    expect(_height(values, 'path'), closeTo(.627, 1e-12));
  });

  test('canopy model heights remain independent from ground paint', () {
    final values = _resolve(
      [_layer('path'), _layer('soil')],
      parts: {
        'path': [_part('path', channel: SmartTileRenderChannel.canopy)],
      },
    );
    expect(_height(values, 'path'), .5);
  });
}

double _height(List<SpatialModelInstance> values, String id) =>
    values.singleWhere((v) => v.modelId == id).position.y;

SmartTileVisualPart _part(
  String id, {
  int order = 0,
  bool follow = true,
  bool replace = false,
  double y = 0,
  SmartTileRenderChannel channel = SmartTileRenderChannel.understory,
}) => SmartTileVisualPart(
  source: SmartTileVisualSource.model3d(
    modelId: id,
    followTerrain: follow,
    replacesGround: replace,
    offsetY: y,
  ),
  channel: channel,
  drawOrder: order,
);

SmartTileLayer _layer(String id) => SmartTileLayer(
  id: id,
  name: id,
  presetId: id,
  usage: id == 'soil' ? SmartTileUsage.terrain : SmartTileUsage.path,
  materialPalette: const ['', 'material'],
  field: const SmartTileField.cell(semanticCells: [1]),
);

List<SpatialModelInstance> _resolve(
  List<SmartTileLayer> layers, {
  Map<String, List<SmartTileVisualPart>> parts = const {},
  List<ProjectSmartTilePattern> patterns = const [],
  Map<String, String> properties = const {},
  bool canonical = false,
}) {
  final catalog = ProjectSmartTileCatalog(
    materials: const [
      ProjectSmartTileMaterial(
        id: 'material',
        name: 'Material',
        connectionGroupId: 'material',
      ),
    ],
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Opaque PNG soil',
        tilesetId: 'soil',
        columns: 1,
        rows: 1,
      ),
    ],
    presets: [
      for (final layer in layers)
        ProjectSmartTilePreset(
          id: layer.id,
          name: layer.name,
          usage: layer.usage,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          defaultMaterialId: 'material',
          allowedMaterialIds: const ['material'],
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          rules: [
            SmartTileRule(
              id: 'source',
              centerMatch: const SmartTileSlotMatch.material('material'),
              candidates: [
                SmartTileCandidate(
                  id: 'source',
                  parts: layer.id == 'soil'
                      ? const [
                          SmartTileVisualPart(
                            source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                atlasId: 'atlas',
                                column: 0,
                                row: 0,
                              ),
                            ),
                          ),
                        ]
                      : parts[layer.id] ?? [_part(layer.id)],
                ),
              ],
            ),
          ],
        ),
    ],
    patterns: patterns,
  );
  final modelIds = <String>{
    for (final preset in catalog.presets)
      for (final rule in preset.rules)
        for (final candidate in rule.candidates)
          for (final part in candidate.parts)
            if (part.source case SmartTileModel3dSource source) source.modelId,
    for (final pattern in patterns)
      for (final cell in pattern.cells)
        for (final part in cell.parts)
          if (part.source case SmartTileModel3dSource source) source.modelId,
  };
  expect(
    validateProjectSmartTileCatalog(
      catalog: catalog,
      projectModelIds: modelIds,
      projectTilesetIds: const ['soil'],
      spatial: true,
    ).where((diagnostic) => diagnostic.isError),
    isEmpty,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v9,
    size: const GridSize(width: 1, height: 1),
    layers: layers,
    properties: properties,
    visualStack: canonical ? MapVisualStackConfig.canonicalV1 : null,
    spatialScene: MapSpatialScene(
      width: 1,
      depth: 1,
      levelHeight: .5,
      heightLevels: const [1],
    ),
  );
  return resolveSpatialSmartTileInstances(map: map, catalog: catalog);
}
