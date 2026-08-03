import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_connection_profile.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide_placement.dart';

void main() {
  group('SmartTileAuthoringController', () {
    test('chooses native defaults for each supported usage', () {
      final controller = SmartTileAuthoringController.blank();

      controller.selectUsage(SmartTileUsage.terrain);
      expect(controller.state.topology, SmartTileTopology.cardinal4);
      expect(controller.state.templateHint, SmartTileTemplateHint.edge16);

      controller.selectUsage(SmartTileUsage.path);
      expect(controller.state.topology, SmartTileTopology.blob8);
      expect(controller.state.templateHint, SmartTileTemplateHint.blob47);

      controller.selectUsage(SmartTileUsage.forestSurface);
      expect(controller.state.topology, SmartTileTopology.blob8);
      expect(controller.state.templateHint, SmartTileTemplateHint.blob47);
    });

    test('compiles complete terrain and sparse overlay coverage policies', () {
      for (final entry in const <(SmartTileUsage, SmartTileCoveragePolicy)>[
        (SmartTileUsage.terrain, SmartTileCoveragePolicy.complete),
        (SmartTileUsage.path, SmartTileCoveragePolicy.sparse),
        (SmartTileUsage.forestSurface, SmartTileCoveragePolicy.sparse),
      ]) {
        final controller = _configuredController()
          ..selectUsage(entry.$1)
          ..addAtlasVariant(
            mask: 0,
            column: 0,
            row: 0,
            candidateId: 'base',
          );

        expect(
          controller.compilePreset().coveragePolicy,
          entry.$2,
          reason: entry.$1.name,
        );
        final profile = controller.compilePreset().coverageProfile;
        if (entry.$2 == SmartTileCoveragePolicy.complete) {
          expect(profile.mode, SmartTileCoverageMode.template);
        } else {
          expect(profile.mode, SmartTileCoverageMode.explicit);
          expect(profile.requiredScenarios, hasLength(1));
          expect(profile.requiredScenarios.single.centerMaterialId, 'grass');
        }
      }
    });

    test('preserves a canonical custom coverage profile across no-op saves',
        () {
      final source = _configuredController()
        ..selectUsage(SmartTileUsage.path)
        ..addAtlasVariant(
          mask: smartTileNorthBit,
          column: 0,
          row: 0,
          candidateId: 'north',
        );
      const customProfile = SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.templateAndExplicit,
        allowFallback: true,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: 'custom-wang-contract',
            centerMaterialId: 'grass',
            signature: SmartTileExactSignature(northEdge: 'grass'),
          ),
        ],
      );
      final canonical = source
          .compileAuthoringDraft(lastStage: SmartTileAuthoringStage.forms)
          .copyWith(coverageProfile: customProfile);

      final resumed = SmartTileAuthoringController.fromCanonicalDraft(
        canonical,
      );
      final firstSave = resumed.compileAuthoringDraft(
        lastStage: SmartTileAuthoringStage.forms,
      );
      final secondSave = resumed.compileAuthoringDraft(
        lastStage: SmartTileAuthoringStage.forms,
      );

      expect(firstSave.coverageProfile, customProfile);
      expect(secondSave.coverageProfile, customProfile);
      expect(resumed.compilePreset().coverageProfile, customProfile);

      final mappingEdited = SmartTileAuthoringController.fromCanonicalDraft(
        canonical,
      )..addAtlasVariant(
          mask: smartTileEastBit,
          column: 1,
          row: 0,
          candidateId: 'east',
        );
      expect(
        mappingEdited.compilePreset().coverageProfile,
        isNot(customProfile),
      );
      expect(
        mappingEdited.compilePreset().coverageProfile.requiredScenarios,
        hasLength(2),
      );

      final materialEdited = SmartTileAuthoringController.fromCanonicalDraft(
        canonical,
      )..addMaterial(
          const ProjectSmartTileMaterial(
            id: 'mud',
            name: 'Boue',
            connectionGroupId: 'mud',
          ),
        );
      expect(
        materialEdited.compilePreset().coverageProfile,
        isNot(customProfile),
      );
      expect(
        materialEdited.compilePreset().coverageProfile.requiredScenarios,
        hasLength(2),
      );

      final policyEdited = SmartTileAuthoringController.fromCanonicalDraft(
        canonical,
      )..configureConnections(
          const SmartTileConnectionConfiguration(
            topology: SmartTileTopology.blob8,
            templateHint: SmartTileTemplateHint.blob47,
            boundaryPolicy: SmartTileBoundaryPolicy.connected,
            coveragePolicy: SmartTileCoveragePolicy.complete,
          ),
          clearMappings: false,
        );
      expect(
        policyEdited.compilePreset().coverageProfile.mode,
        SmartTileCoverageMode.template,
      );

      final multiMaterialSource = _configuredController()
        ..selectUsage(SmartTileUsage.path)
        ..addMaterial(
          const ProjectSmartTileMaterial(
            id: 'mud',
            name: 'Boue',
            connectionGroupId: 'mud',
          ),
          makeActive: false,
        )
        ..addAtlasVariant(
          mask: smartTileNorthBit,
          column: 0,
          row: 0,
          candidateId: 'north',
        );
      final multiMaterialCanonical = multiMaterialSource
          .compileAuthoringDraft(lastStage: SmartTileAuthoringStage.materials)
          .copyWith(coverageProfile: customProfile);
      final defaultEdited = SmartTileAuthoringController.fromCanonicalDraft(
        multiMaterialCanonical,
      )..setDefaultMaterial('mud');
      expect(
        defaultEdited.compilePreset().coverageProfile,
        isNot(customProfile),
      );
    });

    test('proposes gained and lost forms without mutating active transforms',
        () {
      final controller = _configuredController()
        ..selectUsage(SmartTileUsage.terrain)
        ..addAtlasVariant(
          mask: smartTileNorthBit,
          column: 0,
          row: 0,
          candidateId: 'north',
        );
      const quarterTurns = SmartTileTransformPolicy(
        allowQuarterTurns: true,
      );

      final gain = controller.proposeTransformPolicy(quarterTurns);

      expect(controller.state.transformPolicy.allowQuarterTurns, isFalse);
      expect(gain.gainedMasks, <int>[
        smartTileEastBit,
        smartTileSouthBit,
        smartTileWestBit,
      ]);
      expect(gain.lostMasks, isEmpty);
      expect(gain.gainedForms.map((impact) => impact.sourceMask).toSet(), {
        smartTileNorthBit,
      });
      expect(
        gain.gainedForms.map((impact) => impact.transform).toSet(),
        contains(const SmartTileSpriteTransform(quarterTurns: 1)),
      );

      controller.setTransformPolicy(quarterTurns);
      final loss = controller.proposeTransformPolicy(
        const SmartTileTransformPolicy(),
      );
      expect(loss.gainedMasks, isEmpty);
      expect(loss.lostMasks, <int>[
        smartTileEastBit,
        smartTileSouthBit,
        smartTileWestBit,
      ]);
    });

    test('transform proposal excludes unresolved and invalid visual forms', () {
      final source = _configuredController()
        ..selectUsage(SmartTileUsage.terrain)
        ..addAtlasVariant(
          mask: smartTileNorthBit,
          column: 0,
          row: 0,
          candidateId: 'north',
        );
      final canonical = source.compileAuthoringDraft(
        lastStage: SmartTileAuthoringStage.variants,
      );
      final brokenRule = canonical.rules.single.copyWith(
        candidates: const <SmartTileCandidate>[
          SmartTileCandidate(id: 'missing-visual'),
        ],
      );
      final resumed = SmartTileAuthoringController.fromCanonicalDraft(
        canonical.copyWith(rules: <SmartTileRule>[brokenRule]),
      );

      final proposal = resumed.proposeTransformPolicy(
        const SmartTileTransformPolicy(allowQuarterTurns: true),
      );

      expect(proposal.gainedForms, isEmpty);
      expect(proposal.lostForms, isEmpty);
    });

    test('Simple compiles an explicit center-material rule', () {
      final controller = _configuredController()
        ..selectUsage(SmartTileUsage.terrain)
        ..selectTemplate(SmartTileTemplateHint.simple)
        ..addAtlasVariant(
          mask: 0,
          column: 0,
          row: 0,
          candidateId: 'base',
        );

      final preset = controller.compilePreset();

      expect(preset.topology, SmartTileTopology.uniform);
      expect(preset.rules, hasLength(1));
      expect(preset.rules.single.centerMatch.kind, SmartTileMatchKind.material);
      expect(preset.rules.single.centerMatch.materialId, 'grass');
    });

    test('groups sixteen guide cells into twelve native rules', () {
      final controller = _largeConfiguredController()
        ..selectUsage(SmartTileUsage.path);
      final placement = placeSmartTileGuide(
        guide: erwCorner16Guide,
        geometry: controller.state.gridGeometry!,
        anchorColumn: 20,
        anchorRow: 20,
      );

      controller.applyGuidePlacement(
        guide: erwCorner16Guide,
        placement: placement,
      );

      expect(controller.state.templateHint, SmartTileTemplateHint.corner12);
      expect(controller.state.topology, SmartTileTopology.wangCorner4);
      expect(controller.state.mappings, hasLength(12));
      expect(controller.compilePreset().rules, hasLength(12));
      expect(
        controller.compilePreset().rules.map((rule) => rule.id).toSet(),
        smartTileCanonicalMasks(SmartTileTemplateHint.corner12)
            .map(smartTileCanonicalRuleId)
            .toSet(),
      );
      expect(
        controller.state.mappings.values
            .expand((candidates) => candidates)
            .length,
        16,
      );
      expect(controller.state.mappings[0x10], hasLength(2));
      expect(controller.state.mappings[0x20], hasLength(2));
      expect(controller.state.mappings[0x40], hasLength(2));
      expect(controller.state.mappings[0x80], hasLength(2));
    });

    test('manual correction preserves sibling variants for the same mask', () {
      final controller = _largeConfiguredController()
        ..selectUsage(SmartTileUsage.path);
      final placement = placeSmartTileGuide(
        guide: erwCorner16Guide,
        geometry: controller.state.gridGeometry!,
        anchorColumn: 20,
        anchorRow: 20,
      );
      controller.applyGuidePlacement(
        guide: erwCorner16Guide,
        placement: placement,
      );
      final correctedCell = erwCorner16Guide.cellByNumber(7);
      final siblingBefore = controller.state.mappings[correctedCell.mask]!
          .singleWhere((candidate) => candidate.id == 'guide_cell_5');

      controller.replaceAtlasCandidate(
        mask: correctedCell.mask,
        column: 42,
        row: 51,
        candidateId: 'guide_cell_7',
      );

      expect(controller.state.mappings, hasLength(12));
      final variants = controller.state.mappings[correctedCell.mask]!;
      expect(variants, hasLength(2));
      expect(
        variants.singleWhere((candidate) => candidate.id == 'guide_cell_5'),
        siblingBefore,
      );
      final corrected =
          variants.singleWhere((candidate) => candidate.id == 'guide_cell_7');
      expect(
        (corrected.parts.single.source as SmartTileFrameSource).frame,
        const SmartTileFrameRef(
          atlasId: 'atlas-erw',
          column: 42,
          row: 51,
        ),
      );
    });

    test('invalid guide placement leaves every existing mapping untouched', () {
      final controller = _largeConfiguredController()
        ..selectUsage(SmartTileUsage.path)
        ..addAtlasVariant(
          mask: 0,
          column: 4,
          row: 4,
          candidateId: 'keep-me',
        );
      final before = controller.state.mappings;
      final placement = placeSmartTileGuide(
        guide: erwCorner16Guide,
        geometry: controller.state.gridGeometry!,
        anchorColumn: 0,
        anchorRow: 0,
      );

      expect(
        () => controller.applyGuidePlacement(
          guide: erwCorner16Guide,
          placement: placement,
        ),
        throwsStateError,
      );
      expect(controller.state.mappings, same(before));
    });

    test('maps arbitrary atlas cells to weighted canonical variants', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.path)
        ..addAtlasVariant(
          mask: smartTileNorthBit | smartTileEastBit,
          column: 7,
          row: 3,
          candidateId: 'common',
          weight: 7,
        )
        ..addAtlasVariant(
          mask: smartTileNorthBit | smartTileEastBit,
          column: 1,
          row: 5,
          candidateId: 'rare',
          weight: 2,
        );

      final preset = controller.compilePreset();
      final rule = preset.rules.single;

      expect(rule.id, smartTileCanonicalRuleId(0x03));
      expect(rule.signature.northEdge.kind, SmartTileMatchKind.same);
      expect(rule.signature.eastEdge.kind, SmartTileMatchKind.same);
      expect(rule.candidates.map((item) => item.id), ['common', 'rare']);
      expect(rule.candidates.map((item) => item.weight), [7, 2]);
      expect(
        (rule.candidates.first.parts.single.source as SmartTileFrameSource)
            .frame,
        const SmartTileFrameRef(
          atlasId: 'atlas-hanazuki',
          column: 7,
          row: 3,
        ),
      );
    });

    test('forest visuals preserve independent multi-part render channels', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.forestSurface)
        ..addAtlasVariant(
          mask: 0xff,
          column: 2,
          row: 1,
          candidateId: 'forest-main',
          channel: SmartTileRenderChannel.understory,
        )
        ..addVisualPart(
          mask: 0xff,
          candidateId: 'forest-main',
          part: const SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas-hanazuki',
                column: 4,
                row: 0,
                columnSpan: 2,
                rowSpan: 3,
              ),
            ),
            channel: SmartTileRenderChannel.canopy,
            offsetY: -64,
            footprintWidth: 2,
            footprintHeight: 3,
            anchorX: 32,
            anchorY: 96,
            drawOrder: 10,
          ),
        );

      final parts =
          controller.compilePreset().rules.single.candidates.single.parts;

      expect(parts, hasLength(2));
      expect(parts.first.channel, SmartTileRenderChannel.understory);
      expect(parts.last.channel, SmartTileRenderChannel.canopy);
      expect(parts.last.footprintWidth, 2);
      expect(parts.last.anchorY, 96);
    });

    test('animations remain catalog records separate from variant weights', () {
      final controller = _configuredController();
      controller
        ..selectUsage(SmartTileUsage.terrain)
        ..addAnimation(
          const ProjectSmartTileAnimation(
            id: 'grass-wind',
            name: 'Herbe au vent',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas-hanazuki',
                  column: 0,
                  row: 0,
                ),
                durationMs: 180,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas-hanazuki',
                  column: 1,
                  row: 0,
                ),
                durationMs: 220,
              ),
            ],
          ),
        )
        ..addAnimationVariant(
          mask: 0x0f,
          animationId: 'grass-wind',
          candidateId: 'animated',
          weight: 3,
        );

      final compiled = controller.compileCatalog();

      expect(compiled.animations, hasLength(1));
      expect(compiled.animations.single.frames, hasLength(2));
      final candidate = compiled.presets.single.rules.single.candidates.single;
      expect(candidate.weight, 3);
      expect(
        (candidate.parts.single.source as SmartTileAnimationSource).animationId,
        'grass-wind',
      );
    });
  });
}

SmartTileAuthoringController _configuredController() {
  final controller = SmartTileAuthoringController.blank();
  controller
    ..configureIdentity(
      id: 'hanazuki',
      name: 'Hanazuki',
      materialId: 'grass',
      materialName: 'Herbe Hanazuki',
    )
    ..configureAtlas(
      atlasId: 'atlas-hanazuki',
      atlasName: 'Atlas Hanazuki',
      tilesetId: 'tileset-hanazuki',
      geometry: const SmartTileGridGeometry(
        imageWidth: 320,
        imageHeight: 192,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
  return controller;
}

SmartTileAuthoringController _largeConfiguredController() {
  final controller = SmartTileAuthoringController.blank();
  controller
    ..configureIdentity(
      id: 'hanazuki-erw',
      name: 'Chemin ERW Hanazuki',
      materialId: 'dirt',
      materialName: 'Terre Hanazuki',
    )
    ..configureAtlas(
      atlasId: 'atlas-erw',
      atlasName: 'Atlas ERW',
      tilesetId: 'tileset-erw',
      geometry: const SmartTileGridGeometry(
        imageWidth: 1760,
        imageHeight: 2304,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
  return controller;
}
