import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile deterministic resolver', () {
    test('uses the standard unsigned FNV-1a 64-bit contract', () {
      expect(smartTileFnv1a64('hello'.codeUnits), 0xa430d84680aabd0b);
    });

    test('resolves all 16 cardinal masks', () {
      final preset = ProjectSmartTilePreset(
        id: 'cardinal-path',
        name: 'Cardinal path',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.cardinal4,
        defaultMaterialId: 'dirt',
        allowedMaterialIds: const <String>['dirt'],
        rules: <SmartTileRule>[
          for (var mask = 0; mask < 16; mask += 1)
            SmartTileRule(
              id: 'mask-$mask',
              signature: _cardinalSignature(mask),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'candidate-$mask',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: mask,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      );

      for (var mask = 0; mask < 16; mask += 1) {
        final result = resolveSmartTile(
          preset: preset,
          materials: _materials,
          neighborhood: _cardinalNeighborhood(mask),
          mapId: 'map',
          layerId: 'path',
          x: 4,
          y: 7,
        );

        expect(result.status, SmartTileResolutionStatus.resolved);
        expect(result.ruleId, 'mask-$mask', reason: 'mask $mask');
        expect(result.candidate?.id, 'candidate-$mask', reason: 'mask $mask');
      }
    });

    test('Blob topology gates diagonal connectivity through cardinal sides',
        () {
      const neighborhood = SmartTileNeighborhood(
        centerMaterialId: 'dirt',
        north: SmartTileCellSample.inside(materialId: null),
        east: SmartTileCellSample.inside(materialId: null),
        south: SmartTileCellSample.inside(materialId: null),
        west: SmartTileCellSample.inside(materialId: null),
        northWest: SmartTileCellSample.inside(materialId: 'dirt'),
        northEast: SmartTileCellSample.inside(materialId: 'dirt'),
        southEast: SmartTileCellSample.inside(materialId: 'dirt'),
        southWest: SmartTileCellSample.inside(materialId: 'dirt'),
      );

      expect(
        smartTileConnectivityMask(
          topology: SmartTileTopology.blob8,
          boundaryPolicy: SmartTileBoundaryPolicy.empty,
          materials: _materials,
          neighborhood: neighborhood,
        ),
        0,
      );
      expect(
        smartTileConnectivityMask(
          topology: SmartTileTopology.wang8,
          boundaryPolicy: SmartTileBoundaryPolicy.empty,
          materials: _materials,
          neighborhood: neighborhood,
        ),
        0xf0,
      );
    });

    test('matches explicit Wang materials independently of connection group',
        () {
      final preset = _preset(
        topology: SmartTileTopology.wangEdge4,
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'water-north',
            signature: SmartTileSignature(
              northEdge: SmartTileSlotMatch.material('water'),
            ),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'transition',
                parts: <SmartTileVisualPart>[],
              ),
            ],
          ),
        ],
      );
      const neighborhood = SmartTileNeighborhood(
        centerMaterialId: 'dirt',
        north: SmartTileCellSample.inside(materialId: 'water'),
      );

      expect(
        resolveSmartTile(
          preset: preset,
          materials: _materials,
          neighborhood: neighborhood,
          x: 0,
          y: 0,
        ).ruleId,
        'water-north',
      );
    });

    test('applies each map-boundary policy without changing in-map emptiness',
        () {
      const outside = SmartTileNeighborhood(
        centerMaterialId: 'dirt',
        north: SmartTileCellSample.outside(),
      );
      const emptyInside = SmartTileNeighborhood(
        centerMaterialId: 'dirt',
        north: SmartTileCellSample.inside(),
      );

      expect(
        _northConnected(
          outside,
          SmartTileBoundaryPolicy.empty,
        ),
        isFalse,
      );
      expect(
        _northConnected(outside, SmartTileBoundaryPolicy.connected),
        isTrue,
      );
      expect(
        _northConnected(emptyInside, SmartTileBoundaryPolicy.connected),
        isFalse,
      );
    });

    test('weighted candidates are deterministic and preserve visual parts', () {
      final preset = _preset(
        topology: SmartTileTopology.cardinal4,
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'any',
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'common',
                weight: 3,
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
                    source: SmartTileVisualSource.animation(
                      animationId: 'leaves',
                    ),
                    channel: SmartTileRenderChannel.canopy,
                    offsetY: -32,
                  ),
                ],
              ),
              SmartTileCandidate(
                id: 'rare',
                weight: 1,
                parts: <SmartTileVisualPart>[],
              ),
            ],
          ),
        ],
      );
      const neighborhood = SmartTileNeighborhood(centerMaterialId: 'dirt');

      final first = resolveSmartTile(
        preset: preset,
        materials: _materials,
        neighborhood: neighborhood,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      final repeated = resolveSmartTile(
        preset: preset,
        materials: _materials,
        neighborhood: neighborhood,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      final reorderedPreset = preset.copyWith(
        rules: <SmartTileRule>[
          preset.rules.single.copyWith(
            candidates: preset.rules.single.candidates.reversed.toList(),
          ),
        ],
      );
      final reordered = resolveSmartTile(
        preset: reorderedPreset,
        materials: _materials,
        neighborhood: neighborhood,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      final anotherLayerSeed = resolveSmartTile(
        preset: preset,
        materials: _materials,
        neighborhood: neighborhood,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
        layerSeed: 1,
      );
      final observed = <String?>{
        for (var x = 0; x < 200; x += 1)
          resolveSmartTile(
            preset: preset,
            materials: _materials,
            neighborhood: neighborhood,
            mapId: 'hanazuki',
            layerId: 'path',
            x: x,
            y: 9,
            projectSeed: 1742,
          ).candidate?.id,
      };

      expect(repeated.candidate?.id, first.candidate?.id);
      expect(repeated.deterministicHash, first.deterministicHash);
      expect(reordered.candidate?.id, first.candidate?.id);
      expect(reordered.deterministicHash, first.deterministicHash);
      expect(first.deterministicHash, 0x1574bbaada138ecf);
      expect(
          anotherLayerSeed.deterministicHash, isNot(first.deterministicHash));
      expect(observed, containsAll(<String>['common', 'rare']));
      if (first.candidate?.id == 'common') {
        expect(first.parts, hasLength(2));
        expect(first.parts.last.channel, SmartTileRenderChannel.canopy);
      }
    });
  });
}

const List<ProjectSmartTileMaterial> _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'dirt',
    name: 'Dirt',
    connectionGroupId: 'ground',
  ),
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'ground',
  ),
  ProjectSmartTileMaterial(
    id: 'water',
    name: 'Water',
    connectionGroupId: 'water',
  ),
];

ProjectSmartTilePreset _preset({
  required SmartTileTopology topology,
  required List<SmartTileRule> rules,
  SmartTileBoundaryPolicy boundaryPolicy = SmartTileBoundaryPolicy.empty,
}) {
  return ProjectSmartTilePreset(
    id: 'test',
    name: 'Test',
    usage: SmartTileUsage.path,
    topology: topology,
    boundaryPolicy: boundaryPolicy,
    defaultMaterialId: 'dirt',
    allowedMaterialIds: const <String>['dirt', 'grass', 'water'],
    rules: rules,
  );
}

SmartTileSignature _cardinalSignature(int mask) {
  return SmartTileSignature(
    northEdge: _sameOrDifferent(mask & 0x1 != 0),
    eastEdge: _sameOrDifferent(mask & 0x2 != 0),
    southEdge: _sameOrDifferent(mask & 0x4 != 0),
    westEdge: _sameOrDifferent(mask & 0x8 != 0),
  );
}

SmartTileSlotMatch _sameOrDifferent(bool same) => same
    ? const SmartTileSlotMatch.same()
    : const SmartTileSlotMatch.different();

SmartTileNeighborhood _cardinalNeighborhood(int mask) {
  SmartTileCellSample sample(int bit) => SmartTileCellSample.inside(
        materialId: mask & bit == 0 ? null : 'dirt',
      );

  return SmartTileNeighborhood(
    centerMaterialId: 'dirt',
    north: sample(0x1),
    east: sample(0x2),
    south: sample(0x4),
    west: sample(0x8),
  );
}

bool _northConnected(
  SmartTileNeighborhood neighborhood,
  SmartTileBoundaryPolicy policy,
) {
  return smartTileConnectivityMask(
            topology: SmartTileTopology.cardinal4,
            boundaryPolicy: policy,
            materials: _materials,
            neighborhood: neighborhood,
          ) &
          0x1 !=
      0;
}
