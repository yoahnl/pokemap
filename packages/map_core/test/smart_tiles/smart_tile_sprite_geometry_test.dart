import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileSpriteTransform', () {
    test('round-trips on visual parts and rejects non-integer turns', () {
      const part = SmartTileVisualPart(
        source: SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        ),
        transform: SmartTileSpriteTransform(quarterTurns: 3, flipX: true),
      );

      final json = part.toJson();
      final decoded = SmartTileVisualPart.fromJson(json);

      expect(decoded.transform, part.transform);
      expect(json['transform'], <String, Object>{
        'quarterTurns': 3,
        'flipX': true,
      });
      expect(
        () => SmartTileSpriteTransform.fromJson(<String, Object>{
          'quarterTurns': 1.5,
        }),
        throwsFormatException,
      );
    });

    test('canonical table transforms an asymmetric vector for all D4 values',
        () {
      const expected = <(double, double)>[
        (2, 1),
        (-1, 2),
        (-2, -1),
        (1, -2),
        (-2, 1),
        (-1, -2),
        (2, -1),
        (1, 2),
      ];

      expect(smartTileD4Transforms, hasLength(8));
      for (var index = 0; index < smartTileD4Transforms.length; index += 1) {
        final transformed = transformSmartTileVector(
          const SmartTileGeometryPoint(x: 2, y: 1),
          smartTileD4Transforms[index],
        );
        expect(
          (transformed.x, transformed.y),
          expected[index],
          reason: 'D4 index $index',
        );
      }
    });

    test('policy permissions use the generated closure', () {
      const verticalOnly = SmartTileTransformPolicy(allowVFlip: true);
      const horizontalAndVertical = SmartTileTransformPolicy(
        allowHFlip: true,
        allowVFlip: true,
      );
      const fullD4 = SmartTileTransformPolicy(
        allowHFlip: true,
        allowQuarterTurns: true,
      );

      expect(
        smartTileAllowedTransforms(verticalOnly),
        const <SmartTileSpriteTransform>[
          SmartTileSpriteTransform(),
          SmartTileSpriteTransform(quarterTurns: 2, flipX: true),
        ],
      );
      expect(
        smartTileTransformPolicyAllows(
          horizontalAndVertical,
          const SmartTileSpriteTransform(quarterTurns: 2),
        ),
        isTrue,
      );
      expect(smartTileAllowedTransforms(fullD4), smartTileD4Transforms);
    });

    test('composition transforms signature and visual in canonical order', () {
      const horizontalFlip = SmartTileSpriteTransform(flipX: true);
      const clockwise = SmartTileSpriteTransform(quarterTurns: 1);
      final composed = composeSmartTileSpriteTransforms(
        first: horizontalFlip,
        second: clockwise,
      );
      final signature = transformSmartTileSignature(
        const SmartTileSignature(
          northEdge: SmartTileSlotMatch.material('grass'),
        ),
        clockwise,
      );

      expect(
        composed,
        const SmartTileSpriteTransform(quarterTurns: 1, flipX: true),
      );
      expect(
        signature.eastEdge,
        const SmartTileSlotMatch.material('grass'),
      );
      expect(signature.northEdge, const SmartTileSlotMatch.any());
    });
  });

  group('SmartTileSpriteGeometry', () {
    test('keeps offset, anchor, footprint, and rotated bounds coherent', () {
      final geometry = resolveSmartTileSpriteGeometry(
        cellX: 2,
        cellY: 3,
        destinationCellWidth: 32,
        destinationCellHeight: 16,
        sourceCellWidth: 16,
        sourceCellHeight: 8,
        offsetUnit: SmartTileOffsetUnit.pixel,
        offsetX: 3,
        offsetY: 4,
        atlasPixelOffsetX: 1,
        atlasPixelOffsetY: 2,
        footprintWidth: 2,
        footprintHeight: 3,
        anchorX: 4,
        anchorY: 2,
        transform: const SmartTileSpriteTransform(quarterTurns: 1),
      );

      expect(geometry.destinationRect.left, 64);
      expect(geometry.destinationRect.top, 56);
      expect(geometry.destinationRect.width, 64);
      expect(geometry.destinationRect.height, 48);
      expect(geometry.visualBounds.left, 64);
      expect(geometry.visualBounds.top, 56);
      expect(geometry.visualBounds.width, 48);
      expect(geometry.visualBounds.height, 64);
      expect(geometry.anchorOffset, const SmartTileGeometryPoint(x: 8, y: 4));
      expect(
        geometry.transformedAnchorOffset,
        const SmartTileGeometryPoint(x: 44, y: 8),
      );
    });
  });

  group('transformed resolution', () {
    test('rotates a rule signature and reports the synthesized transform', () {
      final resolution = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          transformPolicy: const SmartTileTransformPolicy(
            allowQuarterTurns: true,
          ),
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'north',
              centerMatch: SmartTileSlotMatch.material('dirt'),
              signature: SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('grass'),
              ),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'north', parts: <SmartTileVisualPart>[]),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: _eastGrassContext,
        x: 4,
        y: 2,
      );

      expect(resolution.status, SmartTileResolutionStatus.resolved);
      expect(resolution.ruleId, 'north');
      expect(
        resolution.transform,
        const SmartTileSpriteTransform(quarterTurns: 1),
      );
    });

    test('detects transformed Wang intent even when the center is empty', () {
      final resolution = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          transformPolicy: const SmartTileTransformPolicy(
            allowQuarterTurns: true,
          ),
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'north',
              centerMatch: SmartTileSlotMatch.any(),
              signature: SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('grass'),
              ),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'north'),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(
          observed: SmartTileObservedSignature(
            northEdge: SmartTileObservedSlot.inside(),
            eastEdge: SmartTileObservedSlot.inside(materialId: 'grass'),
            southEdge: SmartTileObservedSlot.inside(),
            westEdge: SmartTileObservedSlot.inside(),
          ),
        ),
        x: 0,
        y: 0,
      );

      expect(resolution.status, SmartTileResolutionStatus.resolved);
      expect(
        resolution.transform,
        const SmartTileSpriteTransform(quarterTurns: 1),
      );
    });

    test('preferUntransformed only resolves equivalent transforms', () {
      final preferred = _preset(
        transformPolicy: const SmartTileTransformPolicy(
          allowHFlip: true,
          allowQuarterTurns: true,
        ),
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'any',
            centerMatch: SmartTileSlotMatch.material('dirt'),
            candidates: <SmartTileCandidate>[SmartTileCandidate(id: 'any')],
          ),
        ],
      );
      final neutral = preferred.copyWith(
        transformPolicy: preferred.transformPolicy.copyWith(
          preferUntransformed: false,
        ),
      );

      final preferredTransforms = <SmartTileSpriteTransform>{
        for (var x = 0; x < 16; x += 1)
          resolveSmartTile(
            preset: preferred,
            materials: _materials,
            context: _eastGrassContext,
            x: x,
            y: 0,
          ).transform,
      };
      final neutralTransforms = <SmartTileSpriteTransform>{
        for (var x = 0; x < 16; x += 1)
          resolveSmartTile(
            preset: neutral,
            materials: _materials,
            context: _eastGrassContext,
            x: x,
            y: 0,
          ).transform,
      };

      expect(
        preferredTransforms,
        <SmartTileSpriteTransform>{const SmartTileSpriteTransform()},
      );
      expect(
        neutralTransforms
            .any((transform) => !isIdentitySmartTileTransform(transform)),
        isTrue,
      );
    });

    test('untransformed preference never hides ambiguity between rules', () {
      final resolution = resolveSmartTile(
        preset: _preset(
          transformPolicy: const SmartTileTransformPolicy(
            allowQuarterTurns: true,
          ),
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'east-exact',
              centerMatch: SmartTileSlotMatch.material('dirt'),
              signature: SmartTileSignature(
                eastEdge: SmartTileSlotMatch.material('grass'),
              ),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'east-exact'),
              ],
            ),
            SmartTileRule(
              id: 'north-rotated',
              centerMatch: SmartTileSlotMatch.material('dirt'),
              signature: SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('grass'),
              ),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'north-rotated'),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: _eastGrassContext,
        x: 0,
        y: 0,
      );

      expect(resolution.status, SmartTileResolutionStatus.ambiguousRule);
      expect(
          resolution.matchingRuleIds, <String>['east-exact', 'north-rotated']);
    });

    test('coverage counts transformed separately from exact and fallback', () {
      final preset = _preset(
        transformPolicy: const SmartTileTransformPolicy(
          allowQuarterTurns: true,
        ),
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'east-grass',
              centerMaterialId: 'dirt',
              signature: SmartTileExactSignature(eastEdge: 'grass'),
            ),
          ],
        ),
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'north',
            centerMatch: SmartTileSlotMatch.material('dirt'),
            signature: SmartTileSignature(
              northEdge: SmartTileSlotMatch.material('grass'),
            ),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'north',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
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

      final report = analyzeSmartTileCoverage(
        preset: preset,
        materials: _materials,
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            columns: 1,
            rows: 1,
          ),
        ],
        animations: const <ProjectSmartTileAnimation>[],
      );

      expect(report.transformedCount, 1);
      expect(report.exactCount, 0);
      expect(report.fallbackCount, 0);
      expect(report.cases.single.status, SmartTileCoverageStatus.transformed);
      expect(report.diagnostics, isEmpty);
    });
  });
}

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'dirt',
    name: 'Dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
];

const _eastGrassContext = SmartTileCellContext(
  centerMaterialId: 'dirt',
  observed: SmartTileObservedSignature(
    northEdge: SmartTileObservedSlot.inside(),
    eastEdge: SmartTileObservedSlot.inside(materialId: 'grass'),
    southEdge: SmartTileObservedSlot.inside(),
    westEdge: SmartTileObservedSlot.inside(),
  ),
);

ProjectSmartTilePreset _preset({
  required SmartTileTransformPolicy transformPolicy,
  required List<SmartTileRule> rules,
  SmartTileTopology topology = SmartTileTopology.cardinal4,
  SmartTileCoverageProfile coverageProfile = const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
}) {
  return ProjectSmartTilePreset(
    id: 'test',
    name: 'Test',
    usage: SmartTileUsage.path,
    topology: topology,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: coverageProfile,
    transformPolicy: transformPolicy,
    defaultMaterialId: 'dirt',
    allowedMaterialIds: const <String>['dirt', 'grass'],
    rules: rules,
  );
}
