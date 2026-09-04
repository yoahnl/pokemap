import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile deterministic resolver', () {
    test('uses the standard unsigned FNV-1a 64-bit contract', () {
      expect(smartTileFnv1a64('hello'.codeUnits), 0xa430d84680aabd0b);
    });

    test('resolves all 16 cardinal masks', () {
      final preset = _cardinalPreset();

      for (var mask = 0; mask < 16; mask += 1) {
        final result = resolveSmartTile(
          preset: preset,
          materials: _materials,
          context: _cardinalContext(mask),
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

    test('prepared resolver preserves every observable resolution field', () {
      final preset = _cardinalPreset();
      final prepared = PreparedSmartTileResolver(
        preset: preset,
        materials: _materials,
        mapId: 'large-map',
        layerId: 'path',
        projectSeed: 1742,
        layerSeed: 7,
      );

      for (var mask = 0; mask < 16; mask += 1) {
        final expected = resolveSmartTile(
          preset: preset,
          materials: _materials,
          context: _cardinalContext(mask),
          mapId: 'large-map',
          layerId: 'path',
          x: mask * 3,
          y: 31 - mask,
          projectSeed: 1742,
          layerSeed: 7,
        );
        final actual = prepared.resolve(
          context: _cardinalContext(mask),
          x: mask * 3,
          y: 31 - mask,
        );

        _expectEquivalentResolution(actual, expected, reason: 'mask $mask');
      }
    });

    test('Blob topology gates diagonal connectivity through cardinal sides',
        () {
      const context = SmartTileCellContext(
        centerMaterialId: 'dirt',
        observed: SmartTileObservedSignature(
          northEdge: SmartTileObservedSlot.inside(materialId: null),
          eastEdge: SmartTileObservedSlot.inside(materialId: null),
          southEdge: SmartTileObservedSlot.inside(materialId: null),
          westEdge: SmartTileObservedSlot.inside(materialId: null),
          northWestCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
          northEastCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
          southEastCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
          southWestCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
        ),
      );

      expect(
        smartTileConnectivityMask(
          topology: SmartTileTopology.blob8,
          boundaryPolicy: SmartTileBoundaryPolicy.empty,
          materials: _materials,
          context: context,
        ),
        0,
      );
      expect(
        smartTileConnectivityMask(
          topology: SmartTileTopology.wang8,
          boundaryPolicy: SmartTileBoundaryPolicy.empty,
          materials: _materials,
          context: context,
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
            centerMatch: SmartTileSlotMatch.any(),
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
      const context = SmartTileCellContext(
        centerMaterialId: 'dirt',
        observed: SmartTileObservedSignature(
          northEdge: SmartTileObservedSlot.inside(materialId: 'water'),
        ),
      );

      expect(
        resolveSmartTile(
          preset: preset,
          materials: _materials,
          context: context,
          x: 0,
          y: 0,
        ).ruleId,
        'water-north',
      );
    });

    test('applies each map-boundary policy without changing in-map emptiness',
        () {
      const outside = SmartTileCellContext(
        centerMaterialId: 'dirt',
        observed: SmartTileObservedSignature(
          northEdge: SmartTileObservedSlot.outside(),
        ),
      );
      const emptyInside = SmartTileCellContext(
        centerMaterialId: 'dirt',
        observed: SmartTileObservedSignature(
          northEdge: SmartTileObservedSlot.inside(),
        ),
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
            centerMatch: SmartTileSlotMatch.any(),
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
      const context = SmartTileCellContext(centerMaterialId: 'dirt');

      final first = resolveSmartTile(
        preset: preset,
        materials: _materials,
        context: context,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      final repeated = resolveSmartTile(
        preset: preset,
        materials: _materials,
        context: context,
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
        context: context,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      final anotherLayerSeed = resolveSmartTile(
        preset: preset,
        materials: _materials,
        context: context,
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
            context: context,
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
      final named = resolveSmartTile(
        preset: preset.copyWith(
          rules: [
            preset.rules.single.copyWith(
              candidates: [
                for (final candidate in preset.rules.single.candidates)
                  candidate.copyWith(label: 'Brins ${candidate.id}'),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: context,
        mapId: 'hanazuki',
        layerId: 'path',
        x: 12,
        y: 9,
        projectSeed: 1742,
      );
      expect(named.candidate?.id, first.candidate?.id);
      expect(named.deterministicHash, first.deterministicHash);
      expect(named.parts, first.parts);
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

ProjectSmartTilePreset _cardinalPreset() {
  return ProjectSmartTilePreset(
    id: 'cardinal-path',
    name: 'Cardinal path',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.cardinal4,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'dirt',
    allowedMaterialIds: const <String>['dirt'],
    rules: <SmartTileRule>[
      for (var mask = 0; mask < 16; mask += 1)
        SmartTileRule(
          id: 'mask-$mask',
          centerMatch: const SmartTileSlotMatch.any(),
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
}

void _expectEquivalentResolution(
  SmartTileResolution actual,
  SmartTileResolution expected, {
  required String reason,
}) {
  expect(actual.status, expected.status, reason: reason);
  expect(actual.ruleId, expected.ruleId, reason: reason);
  expect(actual.candidate, expected.candidate, reason: reason);
  expect(actual.deterministicHash, expected.deterministicHash, reason: reason);
  expect(actual.matchingRuleIds, expected.matchingRuleIds, reason: reason);
  expect(actual.usedFallback, expected.usedFallback, reason: reason);
  expect(actual.transform, expected.transform, reason: reason);
  expect(actual.message, expected.message, reason: reason);
}

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
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
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

SmartTileCellContext _cardinalContext(int mask) {
  SmartTileObservedSlot sample(int bit) => SmartTileObservedSlot.inside(
        materialId: mask & bit == 0 ? null : 'dirt',
      );

  return SmartTileCellContext(
    centerMaterialId: 'dirt',
    observed: SmartTileObservedSignature(
      northEdge: sample(0x1),
      eastEdge: sample(0x2),
      southEdge: sample(0x4),
      westEdge: sample(0x8),
    ),
  );
}

bool _northConnected(
  SmartTileCellContext context,
  SmartTileBoundaryPolicy policy,
) {
  return smartTileConnectivityMask(
            topology: SmartTileTopology.cardinal4,
            boundaryPolicy: policy,
            materials: _materials,
            context: context,
          ) &
          0x1 !=
      0;
}
