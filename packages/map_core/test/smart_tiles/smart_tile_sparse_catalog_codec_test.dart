import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'catalog omits neutral defaults without changing detailed resources',
    () {
      final catalog = _catalog();
      final json = catalog.toJson();
      final preset = _object((json['presets'] as List).single);
      final rule = _object((preset['rules'] as List).single);
      final candidate = _object((rule['candidates'] as List).single);
      final part = _object((candidate['parts'] as List).single);
      final frame = _object(_object(part['source'])['frame']);
      final scenario = _object(
        (_object(preset['coverageProfile'])['requiredScenarios'] as List)
            .single,
      );
      expect(rule, isNot(contains('signature')));
      expect(candidate, isNot(contains('weight')));
      expect(candidate, isNot(contains('label')));
      expect(part.keys, ['source']);
      expect(frame.keys, ['atlasId', 'column', 'row']);
      expect(scenario, {'id': 'grass-center', 'centerMaterialId': 'grass'});
      expect(
        _object(preset['coverageProfile']),
        isNot(contains('allowFallback')),
      );
      expect(_object((json['materials'] as List).single), {
        'id': 'grass',
        'name': 'Herbe',
        'connectionGroupId': 'grass',
      });
      expect(catalog.presets.single.toJson()['rules'], [
        catalog.presets.single.rules.single.toJson(),
      ]);
      expect(catalog.materials.single.toJson(), containsPair('isEmpty', false));
      final expanded = catalog.toJson(compact: false);
      expect(expanded['materials'],
          catalog.materials.map((value) => value.toJson()).toList());
      expect(expanded['presets'],
          catalog.presets.map((value) => value.toJson()).toList());
      expect(ProjectSmartTileCatalog.fromJson(_decoded(expanded)), catalog);
      expect(ProjectSmartTileCatalog.fromJson(_decoded(json)), catalog);
    },
  );

  test(
    'nonneutral visuals, matches, scenarios and material fields survive',
    () {
      const signature = SmartTileSignature(
        northEdge: SmartTileSlotMatch.material('water'),
        eastEdge: SmartTileSlotMatch.same(),
        southEdge: SmartTileSlotMatch.different(),
        westEdge: SmartTileSlotMatch.empty(),
      );
      const exact = SmartTileExactSignature(
        northEdge: 'water',
        eastEdge: 'grass',
        southEastCorner: 'grass',
      );
      final parts = [
        const SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 1,
              row: 2,
              columnSpan: 2,
              rowSpan: 3,
            ),
          ),
          transform: SmartTileSpriteTransform(quarterTurns: 3, flipX: true),
          channel: SmartTileRenderChannel.actorOcclusion,
          frameSampling: SmartTileFrameSampling.tessellated,
          offsetUnit: SmartTileOffsetUnit.cell,
          offsetX: -2,
          offsetY: 3,
          footprintWidth: 2,
          footprintHeight: 3,
          anchorX: 1,
          anchorY: -1,
          drawOrder: 7,
        ),
        const SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: 'ripples'),
          channel: SmartTileRenderChannel.understory,
          frameSampling: SmartTileFrameSampling.stableRandom,
        ),
      ];
      final catalog = _catalog(
        rule: SmartTileRule(
          id: 'shore',
          centerMatch: const SmartTileSlotMatch.material('grass'),
          signature: signature,
          candidates: [
            SmartTileCandidate(
              id: 'shore-a',
              label: 'Rive',
              weight: 17,
              parts: parts,
            ),
          ],
        ),
        profile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.templateAndExplicit,
          allowFallback: true,
          requiredScenarios: [
            SmartTileCoverageScenario(
              id: 'shore',
              centerMaterialId: 'grass',
              signature: exact,
            ),
          ],
        ),
        material: const ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'grass',
          categoryId: 'nature',
          terrainType: TerrainType.grass,
          pathSurfaceKind: PathSurfaceKind.path,
          isEmpty: true,
          sortOrder: -2,
          editorColorArgb: 0,
        ),
      );
      final json = catalog.toJson();
      final rule = _object(
        (_object((json['presets'] as List).single)['rules'] as List).single,
      );
      expect(_object(rule['signature']).keys, [
        'northEdge',
        'eastEdge',
        'southEdge',
        'westEdge',
      ]);
      final roundtrip = ProjectSmartTileCatalog.fromJson(_decoded(json));
      expect(roundtrip, catalog);
      expect(
        roundtrip.presets.single.rules.single.candidates.single.parts,
        parts,
      );
      expect(
        roundtrip.presets.single.coverageProfile,
        catalog.presets.single.coverageProfile,
      );
      expect(roundtrip.materials.single, catalog.materials.single);
    },
  );

  test('private drafts retain source identities and complete coverage', () {
    final catalog = _catalog();
    final preset = catalog.presets.single;
    final draft = ProjectSmartTileAuthoringDraft(
      id: 'private',
      targetPresetId: 'target',
      sourcePresetId: preset.id,
      name: 'Privé',
      usage: preset.usage,
      lastStage: SmartTileAuthoringStage.test,
      sourceTilesetIds: const ['tileset'],
      primaryAtlasId: 'atlas',
      materials: catalog.materials,
      rules: preset.rules,
      coverageProfile: preset.coverageProfile,
      defaultMaterialId: 'grass',
      allowedMaterialIds: const ['grass'],
      fallbackRuleId: preset.rules.single.id,
    );
    final withDraft = ProjectSmartTileCatalog(
      materials: catalog.materials,
      presets: catalog.presets,
      drafts: [draft],
    );
    final json = withDraft.toJson();
    final encoded = _object((json['drafts'] as List).single);
    expect(encoded['id'], 'private');
    expect(encoded['sourcePresetId'], preset.id);
    expect(encoded['fallbackRuleId'], preset.rules.single.id);
    expect(ProjectSmartTileCatalog.fromJson(_decoded(json)), withDraft);
    expect(draft.toJson()['rules'], [preset.rules.single.toJson()]);
  });

  test(
    'large explicit coverage stays bounded with identical resolver results',
    () {
      final catalog = _catalog();
      final preset = catalog.presets.single.copyWith(
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: [
            for (var i = 0; i < 1200; i++)
              SmartTileCoverageScenario(
                id: 'cell-$i',
                centerMaterialId: 'grass',
              ),
          ],
        ),
      );
      final large = ProjectSmartTileCatalog(
        materials: catalog.materials,
        presets: [preset],
      );
      final expanded = {
        ...large.toJson(),
        'presets': [preset.toJson()],
      };
      final sparse = large.toJson();
      expect(_nodes(sparse), lessThan(_nodes(expanded) ~/ 2));
      final restored = ProjectSmartTileCatalog.fromJson(_decoded(sparse));
      expect(restored, large);
      expect(
        restored.presets.single.coverageProfile.requiredScenarios,
        hasLength(1200),
      );
      for (final coordinate in [(0, 0), (12, 25), (-3, 9)]) {
        final before = resolveSmartTile(
          preset: preset,
          materials: large.materials,
          context: const SmartTileCellContext(centerMaterialId: 'grass'),
          x: coordinate.$1,
          y: coordinate.$2,
        );
        final after = resolveSmartTile(
          preset: restored.presets.single,
          materials: restored.materials,
          context: const SmartTileCellContext(centerMaterialId: 'grass'),
          x: coordinate.$1,
          y: coordinate.$2,
        );
        expect(after.status, before.status);
        expect(after.ruleId, before.ruleId);
        expect(after.candidate, before.candidate);
        expect(after.transform, before.transform);
      }
    },
  );
}

ProjectSmartTileCatalog _catalog({
  SmartTileRule? rule,
  SmartTileCoverageProfile? profile,
  ProjectSmartTileMaterial? material,
}) => ProjectSmartTileCatalog(
  materials: [
    material ??
        const ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'grass',
        ),
  ],
  presets: [
    ProjectSmartTilePreset(
      id: 'terrain',
      name: 'Terrain',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile:
          profile ??
          const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: [
              SmartTileCoverageScenario(
                id: 'grass-center',
                centerMaterialId: 'grass',
              ),
            ],
          ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: const ['grass'],
      rules: [
        rule ??
            const SmartTileRule(
              id: 'grass',
              centerMatch: SmartTileSlotMatch.material('grass'),
              candidates: [
                SmartTileCandidate(
                  id: 'grass-a',
                  parts: [
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
    ),
  ],
);

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value as Map);
Map<String, dynamic> _decoded(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
int _nodes(Object? value) =>
    1 +
    switch (value) {
      Map value => value.values.fold<int>(
        0,
        (count, item) => count + _nodes(item),
      ),
      List value => value.fold<int>(0, (count, item) => count + _nodes(item)),
      _ => 0,
    };
