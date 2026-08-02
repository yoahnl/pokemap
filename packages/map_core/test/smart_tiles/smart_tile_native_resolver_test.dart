import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('native Smart Tile resolver', () {
    test('uniform resolves variants without reading neighbors', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(
              id: 'uniform',
              centerMatch: const SmartTileSlotMatch.material('grass'),
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(
          centerMaterialId: 'grass',
          observed: SmartTileObservedSignature(
            northEdge: SmartTileObservedSlot.inside(materialId: 'dirt'),
          ),
        ),
        x: 2,
        y: 3,
      );

      expect(result.status, SmartTileResolutionStatus.resolved);
      expect(result.ruleId, 'uniform');
      expect(result.candidate, isNotNull);
    });

    test('uniform rules distinguish the center material', () {
      final preset = _preset(
        topology: SmartTileTopology.uniform,
        rules: <SmartTileRule>[
          _rule(
            id: 'uniform_grass',
            centerMatch: const SmartTileSlotMatch.material('grass'),
          ),
          _rule(
            id: 'uniform_dirt',
            centerMatch: const SmartTileSlotMatch.material('dirt'),
          ),
        ],
      );

      final grass = resolveSmartTile(
        preset: preset,
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        x: 0,
        y: 0,
      );
      final dirt = resolveSmartTile(
        preset: preset,
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'dirt'),
        x: 0,
        y: 0,
      );

      expect(grass.ruleId, 'uniform_grass');
      expect(dirt.ruleId, 'uniform_dirt');
    });

    test('exact material distinguishes ids sharing one connection group', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          rules: <SmartTileRule>[
            _rule(
              id: 'north_grass_alt',
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('grass_alt'),
              ),
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(
          centerMaterialId: 'grass',
          observed: SmartTileObservedSignature(
            northEdge: SmartTileObservedSlot.inside(
              materialId: 'grass_alt',
            ),
          ),
        ),
        x: 0,
        y: 0,
      );

      expect(result.ruleId, 'north_grass_alt');
    });

    test('equal maximum specificity is ambiguous regardless of rule order', () {
      ProjectSmartTilePreset ambiguous(List<String> order) => _preset(
            topology: SmartTileTopology.cardinal4,
            rules: <SmartTileRule>[
              for (final id in order)
                _rule(
                  id: id,
                  signature: const SmartTileSignature(
                    northEdge: SmartTileSlotMatch.same(),
                  ),
                ),
            ],
          );

      final first = resolveSmartTile(
        preset: ambiguous(const <String>['b', 'a']),
        materials: _materials,
        context: _northConnected,
        x: 0,
        y: 0,
      );
      final second = resolveSmartTile(
        preset: ambiguous(const <String>['a', 'b']),
        materials: _materials,
        context: _northConnected,
        x: 0,
        y: 0,
      );

      expect(first.status, SmartTileResolutionStatus.ambiguousRule);
      expect(second.status, SmartTileResolutionStatus.ambiguousRule);
      expect(first.matchingRuleIds, <String>['a', 'b']);
      expect(second.matchingRuleIds, <String>['a', 'b']);
      expect(
        () => first.matchingRuleIds.add('c'),
        throwsUnsupportedError,
      );
    });

    test('center any, empty, and material matches are exact', () {
      final materialPreset = _preset(
        topology: SmartTileTopology.uniform,
        rules: <SmartTileRule>[
          _rule(
            id: 'material',
            centerMatch: const SmartTileSlotMatch.material('grass'),
          ),
          _rule(id: 'any'),
        ],
      );
      expect(
        resolveSmartTile(
          preset: materialPreset,
          materials: _materials,
          context: const SmartTileCellContext(centerMaterialId: 'grass'),
          x: 0,
          y: 0,
        ).ruleId,
        'material',
      );
      expect(
        resolveSmartTile(
          preset: materialPreset,
          materials: _materials,
          context: const SmartTileCellContext(centerMaterialId: 'dirt'),
          x: 0,
          y: 0,
        ).ruleId,
        'any',
      );

      final emptyCenterPreset = _preset(
        topology: SmartTileTopology.wangEdge4,
        rules: <SmartTileRule>[
          _rule(
            id: 'empty',
            centerMatch: const SmartTileSlotMatch.empty(),
            signature: const SmartTileSignature(
              northEdge: SmartTileSlotMatch.material('grass'),
            ),
          ),
        ],
      );
      expect(
        resolveSmartTile(
          preset: emptyCenterPreset,
          materials: _materials,
          context: const SmartTileCellContext(
            observed: SmartTileObservedSignature(
              northEdge: SmartTileObservedSlot.inside(materialId: 'grass'),
            ),
          ),
          x: 0,
          y: 0,
        ).ruleId,
        'empty',
      );
    });

    test('Wang exact rules can resolve without a center material', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangCorner4,
          rules: <SmartTileRule>[
            _rule(
              id: 'corners',
              centerMatch: const SmartTileSlotMatch.empty(),
              signature: const SmartTileSignature(
                northEastCorner: SmartTileSlotMatch.material('grass'),
                southEastCorner: SmartTileSlotMatch.material('dirt'),
                southWestCorner: SmartTileSlotMatch.material('grass_alt'),
                northWestCorner: SmartTileSlotMatch.material('dirt'),
              ),
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(
          observed: SmartTileObservedSignature(
            northEastCorner: SmartTileObservedSlot.inside(
              materialId: 'grass',
            ),
            southEastCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
            southWestCorner: SmartTileObservedSlot.inside(
              materialId: 'grass_alt',
            ),
            northWestCorner: SmartTileObservedSlot.inside(materialId: 'dirt'),
          ),
        ),
        x: 0,
        y: 0,
      );

      expect(result.status, SmartTileResolutionStatus.resolved);
      expect(result.ruleId, 'corners');
    });

    test('relative rules never match without a center material', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          rules: <SmartTileRule>[
            _rule(
              id: 'same',
              centerMatch: const SmartTileSlotMatch.empty(),
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.same(),
              ),
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(
          observed: SmartTileObservedSignature(
            northEdge: SmartTileObservedSlot.inside(materialId: 'grass'),
          ),
        ),
        x: 0,
        y: 0,
      );

      expect(result.status, SmartTileResolutionStatus.noMatchingRule);
    });

    test('empty distinguishes null, blank, explicit empty, and material', () {
      final preset = _preset(
        topology: SmartTileTopology.wangEdge4,
        rules: <SmartTileRule>[
          _rule(
            id: 'empty',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            signature: const SmartTileSignature(
              northEdge: SmartTileSlotMatch.empty(),
            ),
          ),
        ],
      );

      SmartTileResolution sample(String? materialId) => resolveSmartTile(
            preset: preset,
            materials: _materials,
            context: SmartTileCellContext(
              centerMaterialId: 'grass',
              observed: SmartTileObservedSignature(
                northEdge: SmartTileObservedSlot.inside(
                  materialId: materialId,
                ),
              ),
            ),
            x: 0,
            y: 0,
          );

      expect(sample(null).status, SmartTileResolutionStatus.resolved);
      expect(sample('').status, SmartTileResolutionStatus.resolved);
      expect(sample('void').status, SmartTileResolutionStatus.resolved);
      expect(sample('dirt').status, SmartTileResolutionStatus.noMatchingRule);
    });

    test('boundary policy only changes slots outside the map', () {
      final preset = _preset(
        topology: SmartTileTopology.wangEdge4,
        boundaryPolicy: SmartTileBoundaryPolicy.connected,
        rules: <SmartTileRule>[
          _rule(
            id: 'empty',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            signature: const SmartTileSignature(
              northEdge: SmartTileSlotMatch.empty(),
            ),
          ),
        ],
      );

      SmartTileResolution resolve(SmartTileObservedSlot north) =>
          resolveSmartTile(
            preset: preset,
            materials: _materials,
            context: SmartTileCellContext(
              centerMaterialId: 'grass',
              observed: SmartTileObservedSignature(northEdge: north),
            ),
            x: 0,
            y: 0,
          );

      expect(
        resolve(const SmartTileObservedSlot.outside()).status,
        SmartTileResolutionStatus.noMatchingRule,
      );
      expect(
        resolve(const SmartTileObservedSlot.inside()).status,
        SmartTileResolutionStatus.resolved,
      );
    });

    test('fallback is excluded from primary matching and ignores signature',
        () {
      final fallback = _rule(
        id: 'fallback',
        centerMatch: const SmartTileSlotMatch.material('dirt'),
        signature: const SmartTileSignature(
          northEdge: SmartTileSlotMatch.material('dirt'),
        ),
      );
      final primaryResult = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          fallbackRuleId: fallback.id,
          rules: <SmartTileRule>[_rule(id: 'primary'), fallback],
        ),
        materials: _materials,
        context: _northConnected,
        x: 0,
        y: 0,
      );
      final fallbackResult = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.wangEdge4,
          fallbackRuleId: fallback.id,
          rules: <SmartTileRule>[
            _rule(
              id: 'primary',
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('dirt'),
              ),
            ),
            fallback,
          ],
        ),
        materials: _materials,
        context: _northConnected,
        x: 0,
        y: 0,
      );

      expect(primaryResult.ruleId, 'primary');
      expect(primaryResult.usedFallback, isFalse);
      expect(fallbackResult.ruleId, 'fallback');
      expect(fallbackResult.usedFallback, isTrue);
    });

    test('missing fallback and fallback without positive weight are explicit',
        () {
      final missing = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          fallbackRuleId: 'missing',
          rules: const <SmartTileRule>[],
        ),
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        x: 0,
        y: 0,
      );
      final noCandidate = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          fallbackRuleId: 'fallback',
          rules: <SmartTileRule>[
            _rule(
              id: 'fallback',
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(id: 'dormant', weight: 0),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        x: 0,
        y: 0,
      );

      expect(missing.status, SmartTileResolutionStatus.noMatchingRule);
      expect(noCandidate.status, SmartTileResolutionStatus.noCandidate);
      expect(noCandidate.ruleId, 'fallback');
      expect(noCandidate.usedFallback, isTrue);
    });

    test('zero weight is dormant and candidate order does not affect output',
        () {
      final candidates = const <SmartTileCandidate>[
        SmartTileCandidate(id: 'z_dormant', weight: 0),
        SmartTileCandidate(id: 'b', weight: 2),
        SmartTileCandidate(id: 'a', weight: 1),
      ];
      final first = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(id: 'uniform', candidates: candidates),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        mapId: 'map',
        layerId: 'terrain',
        projectSeed: 42,
        x: 4,
        y: 8,
      );
      final reordered = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(id: 'uniform', candidates: candidates.reversed.toList()),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        mapId: 'map',
        layerId: 'terrain',
        projectSeed: 42,
        x: 4,
        y: 8,
      );

      expect(first.candidate?.id, isNot('z_dormant'));
      expect(reordered.candidate?.id, first.candidate?.id);
      expect(reordered.deterministicHash, first.deterministicHash);
    });

    test('invalid center-relative rules are rejected defensively', () {
      for (final centerMatch in const <SmartTileSlotMatch>[
        SmartTileSlotMatch.same(),
        SmartTileSlotMatch.different(),
      ]) {
        final result = resolveSmartTile(
          preset: _preset(
            topology: SmartTileTopology.uniform,
            rules: <SmartTileRule>[
              _rule(id: 'invalid', centerMatch: centerMatch),
            ],
          ),
          materials: _materials,
          context: const SmartTileCellContext(centerMaterialId: 'grass'),
          x: 0,
          y: 0,
        );

        expect(result.status, SmartTileResolutionStatus.invalidRule);
      }
    });

    test('negative candidate weight is rejected defensively', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(
              id: 'invalid',
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(id: 'invalid', weight: -1),
              ],
            ),
          ],
        ),
        materials: _materials,
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        x: 0,
        y: 0,
      );

      expect(result.status, SmartTileResolutionStatus.invalidRule);
    });

    test('empty contexts have no intent', () {
      final result = resolveSmartTile(
        preset: _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[_rule(id: 'any')],
        ),
        materials: _materials,
        context: const SmartTileCellContext(),
        x: 0,
        y: 0,
      );

      expect(result.status, SmartTileResolutionStatus.noIntent);
    });
  });

  group('native resolver catalog validation', () {
    test('rejects center-relative and inactive-slot constraints', () {
      final diagnostics = _validate(
        _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(
              id: 'invalid',
              centerMatch: const SmartTileSlotMatch.same(),
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('grass'),
              ),
            ),
          ],
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'smart_tiles.rules.center_match_invalid',
          'smart_tiles.rules.inactive_slot',
        ]),
      );
    });

    test('rejects unknown material references', () {
      final diagnostics = _validate(
        _preset(
          topology: SmartTileTopology.wangEdge4,
          rules: <SmartTileRule>[
            _rule(
              id: 'unknown',
              centerMatch: const SmartTileSlotMatch.material('missing'),
              signature: const SmartTileSignature(
                northEdge: SmartTileSlotMatch.material('also_missing'),
              ),
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code == 'smart_tiles.reference.material_missing',
            )
            .length,
        2,
      );
    });

    test('zero weight is dormant but negative weight is invalid', () {
      final diagnostics = _validate(
        _preset(
          topology: SmartTileTopology.uniform,
          rules: <SmartTileRule>[
            _rule(
              id: 'weights',
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(id: 'zero', weight: 0),
                SmartTileCandidate(id: 'negative', weight: -1),
                SmartTileCandidate(id: 'positive'),
              ],
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code == 'smart_tiles.candidate.negative_weight',
            )
            .length,
        1,
      );
    });

    test('published and fallback rules require a positive candidate', () {
      final published = _validate(
        _preset(
          topology: SmartTileTopology.uniform,
          status: SmartTilePresetStatus.published,
          rules: <SmartTileRule>[
            _rule(
              id: 'published',
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(id: 'zero', weight: 0),
              ],
            ),
          ],
        ),
      );
      final fallback = _validate(
        _preset(
          topology: SmartTileTopology.uniform,
          fallbackRuleId: 'fallback',
          rules: <SmartTileRule>[
            _rule(
              id: 'fallback',
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(id: 'zero', weight: 0),
              ],
            ),
          ],
        ),
      );

      bool hasPositiveCandidateError(List<SmartTileDiagnostic> diagnostics) =>
          diagnostics.any(
            (diagnostic) =>
                diagnostic.code == 'smart_tiles.rule.no_positive_candidate' &&
                diagnostic.isError,
          );
      expect(hasPositiveCandidateError(published), isTrue);
      expect(hasPositiveCandidateError(fallback), isTrue);
    });
  });
}

const List<ProjectSmartTileMaterial> _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'vegetation',
  ),
  ProjectSmartTileMaterial(
    id: 'grass_alt',
    name: 'Grass alternate',
    connectionGroupId: 'vegetation',
  ),
  ProjectSmartTileMaterial(
    id: 'dirt',
    name: 'Dirt',
    connectionGroupId: 'earth',
  ),
  ProjectSmartTileMaterial(
    id: 'void',
    name: 'Void',
    connectionGroupId: 'void',
    isEmpty: true,
  ),
];

const SmartTileCellContext _northConnected = SmartTileCellContext(
  centerMaterialId: 'grass',
  observed: SmartTileObservedSignature(
    northEdge: SmartTileObservedSlot.inside(materialId: 'grass_alt'),
  ),
);

ProjectSmartTilePreset _preset({
  required SmartTileTopology topology,
  required List<SmartTileRule> rules,
  SmartTileBoundaryPolicy boundaryPolicy = SmartTileBoundaryPolicy.empty,
  SmartTilePresetStatus status = SmartTilePresetStatus.draft,
  String? fallbackRuleId,
}) {
  return ProjectSmartTilePreset(
    id: 'test',
    name: 'Test',
    usage: SmartTileUsage.terrain,
    topology: topology,
    boundaryPolicy: boundaryPolicy,
    status: status,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>[
      'grass',
      'grass_alt',
      'dirt',
      'void',
    ],
    rules: rules,
    fallbackRuleId: fallbackRuleId,
  );
}

SmartTileRule _rule({
  required String id,
  SmartTileSlotMatch centerMatch = const SmartTileSlotMatch.any(),
  SmartTileSignature signature = const SmartTileSignature(),
  List<SmartTileCandidate>? candidates,
}) {
  return SmartTileRule(
    id: id,
    centerMatch: centerMatch,
    signature: signature,
    candidates: candidates ?? <SmartTileCandidate>[SmartTileCandidate(id: id)],
  );
}

List<SmartTileDiagnostic> _validate(ProjectSmartTilePreset preset) {
  return validateProjectSmartTileCatalog(
    catalog: ProjectSmartTileCatalog(
      materials: _materials,
      presets: <ProjectSmartTilePreset>[preset],
    ),
    projectTilesetIds: const <String>[],
  );
}
