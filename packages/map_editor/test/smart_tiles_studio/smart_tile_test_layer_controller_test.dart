import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_test_layer_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/workbench/smart_tile_compact_lab.dart';

void main() {
  group('SmartTileTestLayerController', () {
    for (final fixture in _fixtures) {
      test('${fixture.name} resolves through the canonical layer context', () {
        final controller = SmartTileTestLayerController(
          preset: fixture.preset,
          catalog: fixture.catalog,
        );

        final inspection = controller.loadCanonicalScenario(fixture.mask);
        final directContext = smartTileCellContextForLayerCell(
          layer: controller.layer,
          map: controller.map,
          preset: fixture.preset,
          x: controller.width ~/ 2,
          y: controller.height ~/ 2,
        );
        final directResolution = resolveSmartTile(
          preset: fixture.preset,
          materials: fixture.catalog.materials,
          context: directContext,
          x: controller.width ~/ 2,
          y: controller.height ~/ 2,
          mapId: controller.map.id,
          layerId: controller.layer.id,
          layerSeed: controller.layer.layerSeed,
        );
        final directVisuals = <SmartTileLayerVisual>[
          ...resolveSmartTileLayerVisuals(
            map: controller.map,
            layer: controller.layer,
            catalog: fixture.catalog,
            pass: SmartTileVisualPass.background,
          ),
          ...resolveSmartTileLayerVisuals(
            map: controller.map,
            layer: controller.layer,
            catalog: fixture.catalog,
            pass: SmartTileVisualPass.foreground,
          ),
        ].where(
          (visual) =>
              visual.cellX == controller.width ~/ 2 &&
              visual.cellY == controller.height ~/ 2,
        );

        expect(
          smartTileConnectivityMask(
            topology: fixture.preset.topology,
            boundaryPolicy: fixture.preset.boundaryPolicy,
            materials: fixture.catalog.materials,
            context: inspection.context,
          ),
          fixture.mask,
        );
        expect(
          inspection.resolution.status,
          SmartTileResolutionStatus.resolved,
        );
        expect(inspection.resolution.ruleId, directResolution.ruleId);
        expect(
          inspection.resolution.candidate?.id,
          directResolution.candidate?.id,
        );
        expect(
          _visualProjection(inspection.visuals),
          _visualProjection(directVisuals),
        );
        expect(
          inspection.visuals.map((visual) => visual.channel),
          <SmartTileRenderChannel>[
            SmartTileRenderChannel.ground,
            SmartTileRenderChannel.canopy,
          ],
        );
      });
    }

    test('pencil and eraser mutate only the selected native lattice', () {
      final fixture = _fixtures.singleWhere((item) => item.name == 'mixed');
      final controller = SmartTileTestLayerController(
        preset: fixture.preset,
        catalog: fixture.catalog,
      );
      const cell = SmartTileLabTarget(
        kind: SmartTileLabTargetKind.cell,
        x: 2,
        y: 2,
      );
      const horizontal = SmartTileLabTarget(
        kind: SmartTileLabTargetKind.horizontalEdge,
        x: 2,
        y: 2,
      );
      const vertical = SmartTileLabTarget(
        kind: SmartTileLabTargetKind.verticalEdge,
        x: 2,
        y: 2,
      );
      const corner = SmartTileLabTarget(
        kind: SmartTileLabTargetKind.corner,
        x: 2,
        y: 2,
      );

      for (final target in <SmartTileLabTarget>[
        cell,
        horizontal,
        vertical,
        corner,
      ]) {
        controller.applyTarget(target, tool: SmartTileLabTool.pencil);
      }

      expect(
        smartTileMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        'ground',
      );
      expect(
        smartTileHorizontalEdgeMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        'ground',
      );
      expect(
        smartTileVerticalEdgeMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        'ground',
      );
      expect(
        smartTileCornerMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        'ground',
      );

      controller.applyTarget(horizontal, tool: SmartTileLabTool.eraser);
      expect(
        smartTileHorizontalEdgeMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        isNull,
      );
      expect(
        smartTileVerticalEdgeMaterialIdAt(
          controller.layer,
          mapSize: controller.size,
          x: 2,
          y: 2,
        ),
        'ground',
      );

      controller.reset();
      expect(smartTileAuthoredValueCount(controller.layer), 0);
      expect(controller.inspection, isNull);
    });

    test('runs every canonical case from an isolated fresh layer', () {
      final fixture = _fixtures.singleWhere((item) => item.name == 'edge');
      final completePreset = fixture.preset.copyWith(
        rules: <SmartTileRule>[
          for (var mask = 0; mask < 16; mask++)
            _rule(mask, SmartTileTopology.wangEdge4),
        ],
      );
      final controller = SmartTileTestLayerController(
        preset: completePreset,
        catalog: ProjectSmartTileCatalog(
          atlases: fixture.catalog.atlases,
          materials: fixture.catalog.materials,
          animations: fixture.catalog.animations,
          presets: <ProjectSmartTilePreset>[completePreset],
        ),
      );

      final results = controller.runCanonicalScenarios();

      expect(results, hasLength(16));
      expect(results.every((result) => result.isResolved), isTrue);
      expect(smartTileAuthoredValueCount(controller.layer), 0);
    });
  });

  group('smartTileLabTargetAt', () {
    const size = GridSize(width: 7, height: 7);
    const padding = SmartTileCompactLab.canvasPadding;
    const extent = 44.0;

    test('targets a cell center', () {
      final target = smartTileLabTargetAt(
        position: const Offset(
          padding + 3.5 * extent,
          padding + 3.5 * extent,
        ),
        mapSize: size,
        topology: SmartTileTopology.cardinal4,
      );

      expect(target?.kind, SmartTileLabTargetKind.cell);
      expect((target?.x, target?.y), (3, 3));
    });

    test('distinguishes horizontal, vertical and corner lattices', () {
      final horizontal = smartTileLabTargetAt(
        position: const Offset(
          padding + 3.5 * extent,
          padding + 3 * extent,
        ),
        mapSize: size,
        topology: SmartTileTopology.wang8,
      );
      final vertical = smartTileLabTargetAt(
        position: const Offset(
          padding + 3 * extent,
          padding + 3.5 * extent,
        ),
        mapSize: size,
        topology: SmartTileTopology.wang8,
      );
      final corner = smartTileLabTargetAt(
        position: const Offset(
          padding + 3 * extent,
          padding + 3 * extent,
        ),
        mapSize: size,
        topology: SmartTileTopology.wang8,
      );

      expect(horizontal?.kind, SmartTileLabTargetKind.horizontalEdge);
      expect((horizontal?.x, horizontal?.y), (3, 3));
      expect(vertical?.kind, SmartTileLabTargetKind.verticalEdge);
      expect((vertical?.x, vertical?.y), (3, 3));
      expect(corner?.kind, SmartTileLabTargetKind.corner);
      expect((corner?.x, corner?.y), (3, 3));
    });
  });
}

List<Map<String, Object?>> _visualProjection(
  Iterable<SmartTileLayerVisual> visuals,
) =>
    <Map<String, Object?>>[
      for (final visual in visuals)
        <String, Object?>{
          'cellX': visual.cellX,
          'cellY': visual.cellY,
          'candidateId': visual.candidateId,
          'channel': visual.channel.name,
          'tilesetId': visual.tilesetId,
          'sourceX': visual.sourceRect.x,
          'sourceY': visual.sourceRect.y,
          'quarterTurns': visual.transform.quarterTurns,
          'flipX': visual.transform.flipX,
          'drawOrder': visual.drawOrder,
        },
    ];

final List<_LabFixture> _fixtures = <_LabFixture>[
  _fixture(
    name: 'cell',
    topology: SmartTileTopology.cardinal4,
    template: SmartTileTemplateHint.edge16,
    mask: smartTileNorthBit | smartTileEastBit,
  ),
  _fixture(
    name: 'edge',
    topology: SmartTileTopology.wangEdge4,
    template: SmartTileTemplateHint.edge16,
    mask: smartTileNorthBit | smartTileEastBit,
  ),
  _fixture(
    name: 'corner',
    topology: SmartTileTopology.wangCorner4,
    template: SmartTileTemplateHint.corner16,
    mask: smartTileNorthWestBit | smartTileSouthEastBit,
  ),
  _fixture(
    name: 'mixed',
    topology: SmartTileTopology.wang8,
    template: SmartTileTemplateHint.mixed256,
    mask: smartTileNorthBit |
        smartTileEastBit |
        smartTileNorthWestBit |
        smartTileSouthEastBit,
  ),
];

_LabFixture _fixture({
  required String name,
  required SmartTileTopology topology,
  required SmartTileTemplateHint template,
  required int mask,
}) {
  final preset = ProjectSmartTilePreset(
    id: name,
    name: name,
    usage: SmartTileUsage.terrain,
    topology: topology,
    templateHint: template,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'ground',
    allowedMaterialIds: const <String>['ground'],
    rules: <SmartTileRule>[_rule(mask, topology)],
  );
  final catalog = ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tileset',
        columns: 2,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'ground',
        name: 'Ground',
        connectionGroupId: 'ground',
      ),
    ],
    presets: <ProjectSmartTilePreset>[preset],
  );
  return _LabFixture(name: name, mask: mask, preset: preset, catalog: catalog);
}

SmartTileRule _rule(int mask, SmartTileTopology topology) => SmartTileRule(
      id: smartTileCanonicalRuleId(mask),
      centerMatch: const SmartTileSlotMatch.any(),
      signature: smartTileSignatureForMask(mask, topology: topology),
      candidates: const <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'candidate',
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
              ),
              channel: SmartTileRenderChannel.ground,
            ),
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 1,
                  row: 0,
                ),
              ),
              channel: SmartTileRenderChannel.canopy,
              drawOrder: 10,
            ),
          ],
        ),
      ],
    );

final class _LabFixture {
  const _LabFixture({
    required this.name,
    required this.mask,
    required this.preset,
    required this.catalog,
  });

  final String name;
  final int mask;
  final ProjectSmartTilePreset preset;
  final ProjectSmartTileCatalog catalog;
}
