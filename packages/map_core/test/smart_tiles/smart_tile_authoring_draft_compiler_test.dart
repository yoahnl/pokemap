import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('compileSmartTileAuthoringDraft', () {
    test('compiles a complete uniform terrain without mutating its inputs', () {
      final draft = _uniformDraft();
      const catalog = ProjectSmartTileCatalog.empty();

      final result = compileSmartTileAuthoringDraft(
        draft: draft,
        catalog: catalog,
        manifest: _manifest(),
      );

      expect(result, isA<SmartTileDraftCompilationSuccess>());
      final success = result as SmartTileDraftCompilationSuccess;
      expect(success.preset.status, SmartTilePresetStatus.published);
      expect(success.preset.id, draft.targetPresetId);
      expect(success.coverage.isExact, isTrue);
      expect(success.diagnostics.where((item) => item.isError), isEmpty);
      expect(success.atlases, draft.atlases);
      expect(success.materials, draft.materials);
      expect(catalog.isEmpty, isTrue);
      expect(draft.lastStage, SmartTileAuthoringStage.publish);
    });

    test('compiles an isolated edit of an existing published preset', () {
      final published = _publishedPreset();
      final catalog = ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        materials: const <ProjectSmartTileMaterial>[_material],
        presets: <ProjectSmartTilePreset>[published],
      );

      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft().copyWith(
          sourcePresetId: published.id,
          name: 'Edited grass',
        ),
        catalog: catalog,
        manifest: _manifest(),
      );

      expect(result, isA<SmartTileDraftCompilationSuccess>());
      final success = result as SmartTileDraftCompilationSuccess;
      expect(success.preset.name, 'Edited grass');
      expect(catalog.presets.single.name, 'Grass');
    });

    test('compiles all sixteen ERW corner cases', () {
      final result = compileSmartTileAuthoringDraft(
        draft: _corner16Draft(),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(result, isA<SmartTileDraftCompilationSuccess>());
      final success = result as SmartTileDraftCompilationSuccess;
      expect(success.preset.rules, hasLength(16));
      expect(success.coverage.isExact, isTrue);
    });

    test('compiles a forest candidate with ground and canopy parts', () {
      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft(
          usage: SmartTileUsage.forestSurface,
          rules: <SmartTileRule>[
            _uniformRule(
              parts: const <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.canopy,
                  drawOrder: 1,
                ),
              ],
            ),
          ],
        ),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(result, isA<SmartTileDraftCompilationSuccess>());
      final success = result as SmartTileDraftCompilationSuccess;
      expect(success.preset.usage, SmartTileUsage.forestSurface);
      expect(success.preset.rules.single.candidates.single.parts, hasLength(2));
      expect(success.coverage.isExact, isTrue);
    });

    test('fails explicitly when the primary atlas is absent', () {
      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft().copyWith(
          atlases: const <ProjectSmartTileAtlas>[],
        ),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(
          _failureCodes(result), contains('smart_tiles.draft.atlas_missing'));
    });

    test('fails explicitly when the default material is absent', () {
      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft().copyWith(
          materials: const <ProjectSmartTileMaterial>[],
        ),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(
        _failureCodes(result),
        contains('smart_tiles.draft.default_material_missing'),
      );
    });

    test('fails on a visual frame outside the configured grid', () {
      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft(
          rules: <SmartTileRule>[
            _uniformRule(
              parts: const <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 1,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(
        _failureCodes(result),
        contains('smart_tiles.visual.out_of_atlas_grid'),
      );
    });

    test('fails when two rules resolve the same canonical case', () {
      final rule = _uniformRule();
      final result = compileSmartTileAuthoringDraft(
        draft: _uniformDraft(
          rules: <SmartTileRule>[
            rule,
            rule.copyWith(id: 'uniform-copy'),
          ],
        ),
        catalog: const ProjectSmartTileCatalog.empty(),
        manifest: _manifest(),
      );

      expect(_failureCodes(result), contains('smart_tiles.rules.ambiguous'));
    });
  });
}

const _atlas = ProjectSmartTileAtlas(
  id: 'atlas',
  name: 'Atlas',
  tilesetId: 'tileset',
  columns: 1,
  rows: 1,
);

const _material = ProjectSmartTileMaterial(
  id: 'grass',
  name: 'Grass',
  connectionGroupId: 'ground',
);

ProjectManifest _manifest() => const ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v5,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tileset',
          name: 'Tileset',
          relativePath: 'tileset.png',
        ),
      ],
    );

ProjectSmartTileAuthoringDraft _uniformDraft({
  SmartTileUsage usage = SmartTileUsage.terrain,
  List<SmartTileRule>? rules,
}) {
  return ProjectSmartTileAuthoringDraft(
    id: 'draft-grass',
    targetPresetId: 'grass',
    name: 'Grass',
    usage: usage,
    lastStage: SmartTileAuthoringStage.publish,
    sourceTilesetIds: const <String>['tileset'],
    atlases: const <ProjectSmartTileAtlas>[_atlas],
    primaryAtlasId: 'atlas',
    materials: const <ProjectSmartTileMaterial>[_material],
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
    rules: rules ?? <SmartTileRule>[_uniformRule()],
  );
}

ProjectSmartTileAuthoringDraft _corner16Draft() {
  return ProjectSmartTileAuthoringDraft(
    id: 'draft-erw',
    targetPresetId: 'erw',
    name: 'ERW corner 16',
    usage: SmartTileUsage.path,
    lastStage: SmartTileAuthoringStage.publish,
    sourceTilesetIds: const <String>['tileset'],
    atlases: const <ProjectSmartTileAtlas>[_atlas],
    primaryAtlasId: 'atlas',
    materials: const <ProjectSmartTileMaterial>[_material],
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    topology: SmartTileTopology.wangCorner4,
    templateHint: SmartTileTemplateHint.corner16,
    rules: <SmartTileRule>[
      for (final mask
          in smartTileCanonicalMasks(SmartTileTemplateHint.corner16))
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
          centerMatch: const SmartTileSlotMatch.any(),
          signature: smartTileSignatureForMask(
            mask,
            topology: SmartTileTopology.wangCorner4,
          ),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'candidate-$mask',
              parts: const <SmartTileVisualPart>[
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
}

ProjectSmartTilePreset _publishedPreset() => ProjectSmartTilePreset(
      id: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: const <String>['grass'],
      rules: <SmartTileRule>[_uniformRule()],
    );

SmartTileRule _uniformRule({List<SmartTileVisualPart>? parts}) {
  return SmartTileRule(
    id: 'uniform',
    centerMatch: const SmartTileSlotMatch.material('grass'),
    candidates: <SmartTileCandidate>[
      SmartTileCandidate(
        id: 'uniform-candidate',
        parts: parts ??
            const <SmartTileVisualPart>[
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
  );
}

Set<String> _failureCodes(SmartTileDraftCompilationResult result) {
  expect(result, isA<SmartTileDraftCompilationFailure>());
  return (result as SmartTileDraftCompilationFailure)
      .diagnostics
      .map((item) => item.code)
      .toSet();
}
