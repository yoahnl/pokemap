import 'dart:collection';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('native Smart Tile coverage', () {
    test('Simple requires exactly one resolvable canonical case', () {
      final report = _analyze(_simplePreset());

      expect(report.cases, hasLength(1));
      expect(report.exactCount, 1);
      expect(report.missingCount, 0);
      expect(report.ambiguousCount, 0);
      expect(report.isExact, isTrue);
    });

    test('coverage exposes fallback instead of counting it as exact', () {
      final report = _analyze(
        _simplePreset(
          rules: <SmartTileRule>[
            _visualRule(
              id: 'fallback',
              centerMatch: const SmartTileSlotMatch.any(),
            ),
          ],
          fallbackRuleId: 'fallback',
          allowFallback: true,
        ),
      );

      expect(report.fallbackCount, 1);
      expect(report.exactCount, 0);
      expect(report.isExact, isFalse);
      expect(
        report.diagnostics.map((item) => item.code),
        isNot(contains('smart_tiles.coverage.fallback_only')),
      );
    });

    for (final entry in const <(SmartTileTemplateHint, SmartTileTopology, int)>[
      (SmartTileTemplateHint.edge16, SmartTileTopology.wangEdge4, 16),
      (SmartTileTemplateHint.corner16, SmartTileTopology.wangCorner4, 16),
      (SmartTileTemplateHint.corner12, SmartTileTopology.wangCorner4, 12),
      (SmartTileTemplateHint.blob47, SmartTileTopology.blob8, 47),
      (SmartTileTemplateHint.mixed256, SmartTileTopology.wang8, 256),
    ]) {
      test('${entry.$1.name} resolves every canonical Wang case exactly', () {
        final report = _analyze(
          _templatePreset(template: entry.$1, topology: entry.$2),
        );

        expect(report.cases, hasLength(entry.$3));
        expect(report.exactCount, entry.$3);
        expect(report.isExact, isTrue);
      });
    }

    test('Simple expands once for each allowed non-empty material', () {
      final report = _analyze(
        _simplePreset(
          allowedMaterialIds: const <String>['grass', 'dirt', 'void'],
          rules: <SmartTileRule>[
            _visualRule(
              id: 'grass',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
            _visualRule(
              id: 'dirt',
              centerMatch: const SmartTileSlotMatch.material('dirt'),
            ),
          ],
        ),
        materials: _allMaterials,
      );

      expect(report.cases, hasLength(2));
      expect(
        report.cases.map((item) => item.context.centerMaterialId).toSet(),
        <String?>{'grass', 'dirt'},
      );
      expect(report.exactCount, 2);
    });

    test('Simple covers an empty material when a rule requests it explicitly',
        () {
      final report = _analyze(
        _simplePreset(
          allowedMaterialIds: const <String>['grass', 'void'],
          rules: <SmartTileRule>[
            _visualRule(
              id: 'grass',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
            _visualRule(
              id: 'void',
              centerMatch: const SmartTileSlotMatch.material('void'),
            ),
          ],
        ),
        materials: _allMaterials,
      );

      expect(report.cases, hasLength(2));
      expect(
        report.cases.map((item) => item.context.centerMaterialId).toSet(),
        <String?>{'grass', 'void'},
      );
      expect(report.exactCount, 2);
      expect(report.isExact, isTrue);
    });

    test('equal rule specificity is reported as ambiguous', () {
      final report = _analyze(
        _simplePreset(
          rules: <SmartTileRule>[
            _visualRule(
              id: 'first',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
            _visualRule(
              id: 'second',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
          ],
        ),
      );

      expect(report.ambiguousCount, 1);
      expect(report.cases.single.ruleIds, <String>['first', 'second']);
    });

    test('a selected candidate without a visual part has no candidate', () {
      final report = _analyze(
        _simplePreset(
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'empty',
              centerMatch: SmartTileSlotMatch.material('grass'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'empty'),
              ],
            ),
          ],
        ),
      );

      expect(report.noCandidateCount, 1);
    });

    test('a missing atlas is a missing visual source', () {
      final report = _analyze(
        _simplePreset(
          rules: <SmartTileRule>[
            _visualRule(
              id: 'missing-atlas',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              source: const SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'missing',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      );

      expect(report.missingVisualSourceCount, 1);
    });

    test('missing and empty animations are missing visual sources', () {
      SmartTileCoverageReport analyzeAnimation(
        String animationId, {
        List<ProjectSmartTileAnimation> animations =
            const <ProjectSmartTileAnimation>[],
      }) {
        return _analyze(
          _simplePreset(
            rules: <SmartTileRule>[
              _visualRule(
                id: animationId,
                centerMatch: const SmartTileSlotMatch.material('grass'),
                source: SmartTileVisualSource.animation(
                  animationId: animationId,
                ),
              ),
            ],
          ),
          animations: animations,
        );
      }

      expect(
        analyzeAnimation('missing').missingVisualSourceCount,
        1,
      );
      expect(
        analyzeAnimation(
          'empty',
          animations: const <ProjectSmartTileAnimation>[
            ProjectSmartTileAnimation(
              id: 'empty',
              name: 'Empty',
              frames: <ProjectSmartTileAnimationFrame>[],
            ),
          ],
        ).missingVisualSourceCount,
        1,
      );
    });

    test('direct and animated frames outside the atlas grid are reported', () {
      final direct = _analyze(
        _simplePreset(
          rules: <SmartTileRule>[
            _visualRule(
              id: 'outside',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              source: const SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 16,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      );
      final animated = _analyze(
        _simplePreset(
          rules: <SmartTileRule>[
            _visualRule(
              id: 'animation',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              source: const SmartTileVisualSource.animation(
                animationId: 'outside-animation',
              ),
            ),
          ],
        ),
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'outside-animation',
            name: 'Outside animation',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 16,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ],
      );

      expect(direct.outOfAtlasGridCount, 1);
      expect(animated.outOfAtlasGridCount, 1);
    });

    test('explicit mode survives JSON round-trip and ignores templates', () {
      final original = _simplePreset(
        allowedMaterialIds: const <String>['grass', 'dirt'],
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'only-dirt',
              centerMaterialId: 'dirt',
            ),
          ],
        ),
        rules: <SmartTileRule>[
          _visualRule(
            id: 'grass',
            centerMatch: const SmartTileSlotMatch.material('grass'),
          ),
          _visualRule(
            id: 'dirt',
            centerMatch: const SmartTileSlotMatch.material('dirt'),
          ),
        ],
      );
      final decoded = ProjectSmartTilePreset.fromJson(original.toJson());

      final report = _analyze(decoded, materials: _allMaterials);

      expect(report.cases, hasLength(1));
      expect(report.cases.single.id, 'only-dirt');
      expect(report.cases.single.context.centerMaterialId, 'dirt');
      expect(report.exactCount, 1);
    });

    test('templateAndExplicit deduplicates identical scenario ids', () {
      final report = _analyze(
        _simplePreset(
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.templateAndExplicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(
                id: 'template:grass:mask_00',
                centerMaterialId: 'grass',
              ),
            ],
          ),
        ),
      );

      expect(report.cases, hasLength(1));
      expect(
        report.diagnostics.map((item) => item.code),
        isNot(contains('smart_tiles.coverage.scenario_id_collision')),
      );
    });

    test('templateAndExplicit diagnoses an id collision with other content',
        () {
      final report = _analyze(
        _simplePreset(
          allowedMaterialIds: const <String>['grass', 'dirt'],
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.templateAndExplicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(
                id: 'template:grass:mask_00',
                centerMaterialId: 'dirt',
              ),
            ],
          ),
          rules: <SmartTileRule>[
            _visualRule(
              id: 'grass',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
            _visualRule(
              id: 'dirt',
              centerMatch: const SmartTileSlotMatch.material('dirt'),
            ),
          ],
        ),
        materials: _allMaterials,
      );

      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.scenario_id_collision'),
      );
    });

    test('Free requires at least one explicit scenario', () {
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.free,
          topology: SmartTileTopology.wang8,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(id: 'ignored-by-template-mode'),
            ],
          ),
        ),
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.explicit_scenarios_required'),
      );
    });

    test('multi-material exact Wang rules require a crossed scenario', () {
      final grassDirtRule = _visualRule(
        id: 'grass-dirt',
        centerMatch: const SmartTileSlotMatch.material('grass'),
        signature: const SmartTileSignature(
          northEdge: SmartTileSlotMatch.material('grass'),
          eastEdge: SmartTileSlotMatch.material('dirt'),
        ),
      );
      final waterRockRule = _visualRule(
        id: 'water-rock',
        centerMatch: const SmartTileSlotMatch.material('water'),
        signature: const SmartTileSignature(
          northEdge: SmartTileSlotMatch.material('water'),
          eastEdge: SmartTileSlotMatch.material('rock'),
        ),
      );
      final templateOnly = _templatePreset(
        template: SmartTileTemplateHint.mixed256,
        topology: SmartTileTopology.wang8,
        allowedMaterialIds: const <String>[
          'grass',
          'dirt',
          'water',
          'rock',
        ],
        rules: <SmartTileRule>[grassDirtRule, waterRockRule],
      );
      final withWrongCrossedScenario = templateOnly.copyWith(
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.templateAndExplicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'water-rock',
              centerMaterialId: 'water',
              signature: SmartTileExactSignature(
                northEdge: 'water',
                eastEdge: 'rock',
              ),
            ),
          ],
        ),
      );
      final withEveryRequiredCross = withWrongCrossedScenario.copyWith(
        coverageProfile: withWrongCrossedScenario.coverageProfile.copyWith(
          requiredScenarios: const <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'water-rock',
              centerMaterialId: 'water',
              signature: SmartTileExactSignature(
                northEdge: 'water',
                eastEdge: 'rock',
              ),
            ),
            SmartTileCoverageScenario(
              id: 'grass-dirt',
              centerMaterialId: 'grass',
              signature: SmartTileExactSignature(
                northEdge: 'grass',
                eastEdge: 'dirt',
              ),
            ),
          ],
        ),
      );

      expect(
        _analyze(templateOnly, materials: _extendedMaterials)
            .diagnostics
            .map((item) => item.code),
        contains('smart_tiles.coverage.explicit_scenarios_required'),
      );
      expect(
        _analyze(withWrongCrossedScenario, materials: _extendedMaterials)
            .diagnostics
            .map((item) => item.code),
        contains('smart_tiles.coverage.explicit_scenarios_required'),
      );
      expect(
        _analyze(withEveryRequiredCross, materials: _extendedMaterials)
            .diagnostics
            .map((item) => item.code),
        isNot(contains('smart_tiles.coverage.explicit_scenarios_required')),
      );
    });

    test('exact Wang material sets reject explicit supersets', () {
      final preset = _templatePreset(
        template: SmartTileTemplateHint.mixed256,
        topology: SmartTileTopology.wang8,
        allowedMaterialIds: const <String>['grass', 'dirt', 'water'],
        rules: <SmartTileRule>[
          _visualRule(
            id: 'grass-dirt',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            signature: const SmartTileSignature(
              northEdge: SmartTileSlotMatch.material('grass'),
              eastEdge: SmartTileSlotMatch.material('dirt'),
            ),
          ),
        ],
      );
      final withSuperset = preset.copyWith(
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.templateAndExplicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'grass-dirt-water',
              centerMaterialId: 'grass',
              signature: SmartTileExactSignature(
                northEdge: 'grass',
                eastEdge: 'dirt',
                southEdge: 'water',
              ),
            ),
          ],
        ),
      );
      final withExactSet = preset.copyWith(
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.templateAndExplicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'grass-dirt',
              centerMaterialId: 'grass',
              signature: SmartTileExactSignature(
                northEdge: 'grass',
                eastEdge: 'dirt',
              ),
            ),
          ],
        ),
      );

      expect(
        _analyze(withSuperset, materials: _extendedMaterials)
            .diagnostics
            .map((item) => item.code),
        contains('smart_tiles.coverage.explicit_scenarios_required'),
      );
      expect(
        _analyze(withExactSet, materials: _extendedMaterials)
            .diagnostics
            .map((item) => item.code),
        isNot(contains('smart_tiles.coverage.explicit_scenarios_required')),
      );
    });

    test('null explicit slots mean exact absence even at a connected boundary',
        () {
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.free,
          topology: SmartTileTopology.wangEdge4,
          boundaryPolicy: SmartTileBoundaryPolicy.connected,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(
                id: 'north-empty',
                centerMaterialId: 'grass',
              ),
            ],
          ),
          rules: <SmartTileRule>[
            _visualRule(
              id: 'north-empty',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.empty(),
              ),
            ),
          ],
        ),
      );

      expect(report.exactCount, 1);
    });

    test('duplicate explicit scenario ids are rejected', () {
      final report = _analyze(
        _simplePreset(
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(id: 'duplicate'),
              SmartTileCoverageScenario(id: 'duplicate'),
            ],
          ),
        ),
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.duplicate_scenario_id'),
      );
    });

    test('4097 explicit scenarios are rejected before resolution', () {
      final report = _analyze(
        _simplePreset(
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              for (var index = 0; index < 4097; index++)
                SmartTileCoverageScenario(id: 'scenario-$index'),
            ],
          ),
        ),
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.too_many_scenarios'),
      );
    });

    test('template expansion beyond 4096 is rejected before resolution', () {
      final materials = <ProjectSmartTileMaterial>[
        for (var index = 0; index < 17; index++)
          ProjectSmartTileMaterial(
            id: 'material-$index',
            name: 'Material $index',
            connectionGroupId: 'group-$index',
          ),
      ];
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.mixed256,
          topology: SmartTileTopology.wang8,
          defaultMaterialId: 'material-0',
          allowedMaterialIds: <String>[
            for (var index = 0; index < 17; index++) 'material-$index',
          ],
          rules: const <SmartTileRule>[],
        ),
        materials: materials,
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.too_many_scenarios'),
      );
    });

    test('template preflight stops before materializing unbounded expansion',
        () {
      final materials = <ProjectSmartTileMaterial>[
        for (var index = 0; index < 4097; index++)
          ProjectSmartTileMaterial(
            id: 'material-$index',
            name: 'Material $index',
            connectionGroupId: 'group-$index',
          ),
      ];
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.simple,
          topology: SmartTileTopology.uniform,
          defaultMaterialId: 'material-0',
          allowedMaterialIds: _GuardedMaterialIds(),
          rules: const <SmartTileRule>[],
        ),
        materials: materials,
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.too_many_scenarios'),
      );
    });

    test('explicit preflight stops after the first excess scenario', () {
      final report = _analyze(
        _simplePreset(
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: _GuardedScenarios(),
          ),
        ),
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.too_many_scenarios'),
      );
    });

    test('templateAndExplicit union is bounded after deduplication', () {
      final materials = <ProjectSmartTileMaterial>[
        for (var index = 0; index < 16; index++)
          ProjectSmartTileMaterial(
            id: 'material-$index',
            name: 'Material $index',
            connectionGroupId: 'group-$index',
          ),
      ];
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.mixed256,
          topology: SmartTileTopology.wang8,
          defaultMaterialId: 'material-0',
          allowedMaterialIds: <String>[
            for (var index = 0; index < 16; index++) 'material-$index',
          ],
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.templateAndExplicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(id: 'one-more'),
            ],
          ),
          rules: const <SmartTileRule>[],
        ),
        materials: materials,
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.too_many_scenarios'),
      );
    });

    test('legacy20 is rejected by native v2 coverage', () {
      final report = _analyze(
        _templatePreset(
          template: SmartTileTemplateHint.legacy20,
          topology: SmartTileTopology.cardinal4,
        ),
      );

      expect(report.cases, isEmpty);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.legacy20_unsupported'),
      );
    });

    test('fallback diagnostics follow allowFallback', () {
      ProjectSmartTilePreset preset(bool allowFallback) => _simplePreset(
            rules: <SmartTileRule>[
              _visualRule(
                id: 'fallback',
                centerMatch: const SmartTileSlotMatch.any(),
              ),
            ],
            fallbackRuleId: 'fallback',
            allowFallback: allowFallback,
          );

      final forbidden = _analyze(preset(false));
      final allowed = _analyze(preset(true));

      expect(forbidden.fallbackCount, 1);
      expect(allowed.fallbackCount, 1);
      expect(
        forbidden.diagnostics.map((item) => item.code),
        contains('smart_tiles.coverage.fallback_only'),
      );
      expect(
        allowed.diagnostics.map((item) => item.code),
        isNot(contains('smart_tiles.coverage.fallback_only')),
      );
    });
  });
}

SmartTileCoverageReport _analyze(
  ProjectSmartTilePreset preset, {
  Iterable<ProjectSmartTileMaterial> materials = _materials,
  Iterable<ProjectSmartTileAtlas> atlases = _atlases,
  Iterable<ProjectSmartTileAnimation> animations =
      const <ProjectSmartTileAnimation>[],
}) {
  return analyzeSmartTileCoverage(
    preset: preset,
    materials: materials,
    atlases: atlases,
    animations: animations,
  );
}

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'ground',
  ),
];

const _allMaterials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
  ProjectSmartTileMaterial(
    id: 'dirt',
    name: 'Dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(
    id: 'void',
    name: 'Void',
    connectionGroupId: 'void',
    isEmpty: true,
  ),
];

const _extendedMaterials = <ProjectSmartTileMaterial>[
  ..._allMaterials,
  ProjectSmartTileMaterial(
    id: 'water',
    name: 'Water',
    connectionGroupId: 'water',
  ),
  ProjectSmartTileMaterial(
    id: 'rock',
    name: 'Rock',
    connectionGroupId: 'rock',
  ),
];

const _atlases = <ProjectSmartTileAtlas>[
  ProjectSmartTileAtlas(
    id: 'atlas',
    name: 'Atlas',
    tilesetId: 'tileset',
    columns: 16,
    rows: 16,
  ),
];

ProjectSmartTilePreset _simplePreset({
  List<SmartTileRule>? rules,
  String? fallbackRuleId,
  bool allowFallback = false,
  List<String> allowedMaterialIds = const <String>['grass'],
  SmartTileCoverageProfile? coverageProfile,
}) {
  return ProjectSmartTilePreset(
    id: 'simple',
    name: 'Simple',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: coverageProfile ??
        SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
          allowFallback: allowFallback,
        ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: allowedMaterialIds,
    rules: rules ??
        <SmartTileRule>[
          _visualRule(
            id: 'grass',
            centerMatch: const SmartTileSlotMatch.material('grass'),
          ),
        ],
    fallbackRuleId: fallbackRuleId,
  );
}

ProjectSmartTilePreset _templatePreset({
  required SmartTileTemplateHint template,
  required SmartTileTopology topology,
  List<SmartTileRule>? rules,
  SmartTileCoverageProfile coverageProfile = const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  SmartTileBoundaryPolicy boundaryPolicy = SmartTileBoundaryPolicy.empty,
  String defaultMaterialId = 'grass',
  List<String> allowedMaterialIds = const <String>['grass'],
}) {
  return ProjectSmartTilePreset(
    id: template.name,
    name: template.name,
    usage: SmartTileUsage.terrain,
    topology: topology,
    templateHint: template,
    boundaryPolicy: boundaryPolicy,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: coverageProfile,
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: defaultMaterialId,
    allowedMaterialIds: allowedMaterialIds,
    rules: rules ??
        <SmartTileRule>[
          for (final mask in smartTileCanonicalMasks(template))
            _visualRule(
              id: smartTileCanonicalRuleId(mask),
              centerMatch: const SmartTileSlotMatch.any(),
              signature: smartTileSignatureForMask(mask, topology: topology),
            ),
        ],
  );
}

SmartTileRule _visualRule({
  required String id,
  required SmartTileSlotMatch centerMatch,
  SmartTileSignature signature = const SmartTileSignature(),
  SmartTileVisualSource source = const SmartTileVisualSource.frame(
    frame: SmartTileFrameRef(
      atlasId: 'atlas',
      column: 0,
      row: 0,
    ),
  ),
}) {
  return SmartTileRule(
    id: id,
    centerMatch: centerMatch,
    signature: signature,
    candidates: <SmartTileCandidate>[
      SmartTileCandidate(
        id: 'visual',
        parts: <SmartTileVisualPart>[
          SmartTileVisualPart(source: source),
        ],
      ),
    ],
  );
}

final class _GuardedMaterialIds extends ListBase<String> {
  @override
  int get length => 100000;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  String operator [](int index) {
    if (index > 4096) {
      throw StateError('template expansion read past its bounded preflight');
    }
    return 'material-$index';
  }

  @override
  void operator []=(int index, String value) =>
      throw UnsupportedError('immutable');
}

final class _GuardedScenarios extends ListBase<SmartTileCoverageScenario> {
  @override
  int get length => 100000;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  SmartTileCoverageScenario operator [](int index) {
    if (index > 4096) {
      throw StateError('explicit coverage read past its bounded preflight');
    }
    return SmartTileCoverageScenario(id: 'scenario-$index');
  }

  @override
  void operator []=(int index, SmartTileCoverageScenario value) =>
      throw UnsupportedError('immutable');
}
