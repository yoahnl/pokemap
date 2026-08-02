import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('validateProjectSmartTileCatalog', () {
    test('reports duplicate ids', () {
      final catalog = _catalog(
        categories: const <ProjectSmartTileCategory>[
          ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
          ProjectSmartTileCategory(id: 'nature', name: 'Nature duplicate'),
        ],
      );

      expect(_codes(catalog), contains('smart_tiles.id.duplicate'));
    });

    test('reports missing references', () {
      final catalog = _catalog(
        tilesetId: 'missing-tileset',
        preset: _pathPreset(
          defaultMaterialId: 'missing-material',
          allowedMaterialIds: const <String>['missing-material'],
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'references',
              centerMatch: SmartTileSlotMatch.any(),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'references',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'missing-atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                        animationId: 'missing-animation',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.reference.tileset_missing',
          'smart_tiles.reference.atlas_missing',
          'smart_tiles.reference.material_missing',
          'smart_tiles.reference.animation_missing',
        ]),
      );
    });

    test('reports out-of-bounds frames, weights, and animations', () {
      final catalog = _catalog(
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'invalid-animation',
            name: 'Invalid animation',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 0,
              ),
            ],
          ),
        ],
        preset: _pathPreset(
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'invalid-candidate',
              centerMatch: SmartTileSlotMatch.any(),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'bad-weight',
                  weight: -1,
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 2,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.atlas.frame_out_of_bounds',
          'smart_tiles.candidate.negative_weight',
          'smart_tiles.animation.invalid',
        ]),
      );
    });

    test('accepts a multi-material Wang Terrain preset', () {
      final catalog = _catalog(
        preset: const ProjectSmartTilePreset(
          id: 'bad-terrain',
          name: 'Bad terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass', 'dirt'],
        ),
      );

      expect(
        validateProjectSmartTileCatalog(
          catalog: catalog,
          projectTilesetIds: const <String>['tileset'],
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
    });

    test('rejects relative center matches and unknown center materials', () {
      final catalog = _catalog(
        preset: _pathPreset(
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'relative-center',
              centerMatch: SmartTileSlotMatch.same(),
            ),
            SmartTileRule(
              id: 'missing-center',
              centerMatch: SmartTileSlotMatch.material('missing'),
            ),
          ],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.rules.center_match_invalid',
          'smart_tiles.reference.material_missing',
        ]),
      );
    });

    test('rejects reachable references outside the preset material set', () {
      final catalog = _catalog(
        preset: const ProjectSmartTilePreset(
          id: 'grass-only',
          name: 'Grass only',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(
                id: 'unreachable-dirt',
                centerMaterialId: 'dirt',
                signature: SmartTileExactSignature(northEdge: 'dirt'),
              ),
            ],
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'unreachable-dirt',
              centerMatch: SmartTileSlotMatch.material('dirt'),
              signature: SmartTileSignature(
                eastEdge: SmartTileSlotMatch.material('dirt'),
              ),
            ),
          ],
        ),
      );

      final disallowed = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: const <String>['tileset'],
      )
          .where(
            (diagnostic) =>
                diagnostic.code == 'smart_tiles.reference.material_not_allowed',
          )
          .toList(growable: false);

      expect(disallowed, hasLength(4));
      final paths = disallowed.map((diagnostic) => diagnostic.path).toList();
      for (final suffix in const <String>[
        'coverageProfile.requiredScenarios[0].centerMaterialId',
        'coverageProfile.requiredScenarios[0].signature.northEdge',
        'rules[0].centerMatch.materialId',
        'rules[0].signature.eastEdge.materialId',
      ]) {
        expect(paths.any((path) => path.contains(suffix)), isTrue);
      }
    });

    test('rejects every native template paired with a wrong topology', () {
      const expectedTopologies =
          <SmartTileTemplateHint, Set<SmartTileTopology>>{
        SmartTileTemplateHint.simple: <SmartTileTopology>{
          SmartTileTopology.uniform,
        },
        SmartTileTemplateHint.edge16: <SmartTileTopology>{
          SmartTileTopology.cardinal4,
          SmartTileTopology.wangEdge4,
        },
        SmartTileTemplateHint.corner16: <SmartTileTopology>{
          SmartTileTopology.wangCorner4,
        },
        SmartTileTemplateHint.corner12: <SmartTileTopology>{
          SmartTileTopology.wangCorner4,
        },
        SmartTileTemplateHint.blob47: <SmartTileTopology>{
          SmartTileTopology.blob8,
        },
        SmartTileTemplateHint.mixed256: <SmartTileTopology>{
          SmartTileTopology.wang8,
        },
      };

      for (final entry in expectedTopologies.entries) {
        for (final topology in SmartTileTopology.values) {
          if (entry.value.contains(topology)) continue;
          final catalog = _catalog(
            preset: ProjectSmartTilePreset(
              id: 'invalid-${entry.key.name}-${topology.name}',
              name: 'Invalid template topology pair',
              usage: SmartTileUsage.path,
              topology: topology,
              templateHint: entry.key,
              coveragePolicy: SmartTileCoveragePolicy.sparse,
              coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: const SmartTileTransformPolicy(),
              defaultMaterialId: 'dirt',
              allowedMaterialIds: const <String>['dirt'],
            ),
          );

          expect(
            _codes(catalog),
            contains('smart_tiles.topology.template_mismatch'),
            reason: '${entry.key.name} only accepts '
                '${entry.value.map((value) => value.name).join(', ')}, '
                'not ${topology.name}',
          );
        }
      }
    });

    test('reports non-canonical catalog identities and material categories',
        () {
      final catalog = ProjectSmartTileCatalog(
        categories: const <ProjectSmartTileCategory>[
          ProjectSmartTileCategory(id: ' ', name: ' '),
        ],
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: ' ',
            tilesetId: 'tileset',
            columns: 1,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'material',
            name: ' ',
            connectionGroupId: ' ',
            categoryId: 'missing-category',
          ),
        ],
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(id: ' ', name: ' ', frames: []),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: ' ',
            name: ' ',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'material',
            allowedMaterialIds: <String>['material'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: ' ',
                centerMatch: SmartTileSlotMatch.any(),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(id: ' '),
                ],
              ),
            ],
          ),
        ],
      );

      final diagnostics = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: const <String>['tileset'],
      );
      final invalidIdentityPaths = diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code == 'smart_tiles.id.invalid' ||
                diagnostic.code == 'smart_tiles.name.invalid',
          )
          .map((diagnostic) => diagnostic.path)
          .toSet();

      for (final suffix in const <String>[
        'categories[0].id',
        'categories[0].name',
        'atlases[0].name',
        'materials[0].name',
        'materials[0].connectionGroupId',
        'animations[0].id',
        'animations[0].name',
        'presets[0].id',
        'presets[0].name',
        'presets[0].rules[0].id',
        'presets[0].rules[0].candidates[0].id',
      ]) {
        expect(
          invalidIdentityPaths.any((path) => path.endsWith(suffix)),
          isTrue,
          reason: suffix,
        );
      }
      expect(
        diagnostics.where(
          (diagnostic) =>
              diagnostic.code == 'smart_tiles.reference.category_missing' &&
              diagnostic.path.endsWith('materials[0].categoryId'),
        ),
        isNotEmpty,
      );
    });

    test('blocks non-default transforms from publication until STN-02', () {
      final draft = _pathPreset().copyWith(
        transformPolicy: const SmartTileTransformPolicy(allowHFlip: true),
      );
      final published = draft.copyWith(
        status: SmartTilePresetStatus.published,
      );

      final draftDiagnostic = validateProjectSmartTileCatalog(
        catalog: _catalog(preset: draft),
        projectTilesetIds: const <String>['tileset'],
      ).singleWhere(
        (diagnostic) =>
            diagnostic.code == 'smart_tiles.transforms.requires_stn02',
      );
      final publishedDiagnostic = validateProjectSmartTileCatalog(
        catalog: _catalog(preset: published),
        projectTilesetIds: const <String>['tileset'],
      ).singleWhere(
        (diagnostic) =>
            diagnostic.code == 'smart_tiles.transforms.requires_stn02',
      );

      expect(draftDiagnostic.severity, SmartTileDiagnosticSeverity.warning);
      expect(
        publishedDiagnostic.severity,
        SmartTileDiagnosticSeverity.error,
      );
    });

    test('accepts a valid Terrain preset and Wang Path preset', () {
      final terrain = _catalog(
        preset: const ProjectSmartTilePreset(
          id: 'grass-terrain',
          name: 'Grass terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.wangEdge4,
          templateHint: SmartTileTemplateHint.edge16,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass'],
        ),
      );
      final path = _catalog(
        preset: _pathPreset(),
      );

      expect(
        validateProjectSmartTileCatalog(
          catalog: terrain,
          projectTilesetIds: const <String>['tileset'],
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
      expect(
        validateProjectSmartTileCatalog(
          catalog: path,
          projectTilesetIds: const <String>['tileset'],
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
    });
  });
}

Set<String> _codes(ProjectSmartTileCatalog catalog) {
  return validateProjectSmartTileCatalog(
    catalog: catalog,
    projectTilesetIds: const <String>['tileset'],
  ).map((diagnostic) => diagnostic.code).toSet();
}

ProjectSmartTileCatalog _catalog({
  String tilesetId = 'tileset',
  List<ProjectSmartTileCategory> categories =
      const <ProjectSmartTileCategory>[],
  List<ProjectSmartTileAnimation> animations =
      const <ProjectSmartTileAnimation>[],
  ProjectSmartTilePreset? preset,
}) {
  return ProjectSmartTileCatalog(
    categories: categories,
    atlases: <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: tilesetId,
        columns: 2,
        rows: 2,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      ),
      ProjectSmartTileMaterial(
        id: 'dirt',
        name: 'Dirt',
        connectionGroupId: 'ground',
      ),
    ],
    animations: animations,
    presets: <ProjectSmartTilePreset>[
      preset ?? _pathPreset(),
    ],
  );
}

ProjectSmartTilePreset _pathPreset({
  String defaultMaterialId = 'dirt',
  List<String> allowedMaterialIds = const <String>['grass', 'dirt'],
  List<SmartTileRule> rules = const <SmartTileRule>[],
}) {
  return ProjectSmartTilePreset(
    id: 'path',
    name: 'Path',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.wang8,
    templateHint: SmartTileTemplateHint.mixed256,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: defaultMaterialId,
    allowedMaterialIds: allowedMaterialIds,
    rules: rules,
  );
}
