import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_connection_profile.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_form_projection.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide_placement.dart';

void main() {
  group('no-code variant authoring', () {
    test('persists the real transform policy and projects core D4 operations',
        () {
      final controller = _controller();
      const policy = SmartTileTransformPolicy(
        allowHFlip: true,
        allowQuarterTurns: true,
        preferUntransformed: false,
      );

      controller.setTransformPolicy(policy);

      expect(controller.state.transformPolicy, policy);
      expect(controller.compilePreset().transformPolicy, policy);
      expect(
        controller
            .compileAuthoringDraft(lastStage: SmartTileAuthoringStage.variants)
            .transformPolicy,
        policy,
      );
      expect(controller.allowedTransforms, smartTileD4Transforms);
    });

    test('adds, reorders, reweights, and removes variants with bounded weights',
        () {
      final controller = _controller()
        ..addAtlasVariant(
          mask: 0,
          column: 0,
          row: 0,
          candidateId: 'first',
          weight: 7,
        )
        ..addAtlasVariant(
          mask: 0,
          column: 1,
          row: 0,
          candidateId: 'second',
          weight: 2,
        )
        ..addAtlasVariant(
          mask: 0,
          column: 2,
          row: 0,
          candidateId: 'third',
        );

      controller
        ..reorderCandidate(mask: 0, candidateId: 'third', newIndex: 0)
        ..updateCandidateWeight(mask: 0, candidateId: 'second', weight: 3)
        ..removeCandidate(mask: 0, candidateId: 'first');

      expect(
        controller.state.mappings[0]!.map((candidate) => candidate.id),
        <String>['third', 'second'],
      );
      expect(
        controller.state.mappings[0]!.map((candidate) => candidate.weight),
        <int>[1, 3],
      );
      expect(
        () => controller.updateCandidateWeight(
          mask: 0,
          candidateId: 'second',
          weight: 0,
        ),
        throwsRangeError,
      );
      expect(
        () => controller.addAtlasVariant(
          mask: 0,
          column: 3,
          row: 0,
          candidateId: 'invalid',
          weight: 1001,
        ),
        throwsRangeError,
      );
    });

    test('prefills an ERW guide without deleting existing variants', () {
      final controller = _largeController()
        ..selectTemplate(SmartTileTemplateHint.corner12)
        ..addAtlasVariant(
          mask: smartTileNorthWestBit,
          column: 30,
          row: 30,
          candidateId: 'hand-authored',
        );
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

      expect(
        controller.state.mappings[smartTileNorthWestBit]!
            .map((candidate) => candidate.id),
        containsAll(<String>['hand-authored', 'guide_cell_1', 'guide_cell_3']),
      );
      expect(controller.state.mappings, hasLength(12));
    });

    test('creates a named animation while keeping its id internal', () {
      final controller = _controller();

      final animation = controller.createAnimation(
        name: 'Herbe au vent',
        frames: const <SmartTileFrameRef>[
          SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
          SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
        ],
        durationMs: 180,
      );

      expect(animation.id, 'smart-tile-animation-herbe-au-vent');
      expect(animation.name, 'Herbe au vent');
      expect(animation.frames, hasLength(2));
      expect(controller.state.animations.single, animation);
    });
  });

  group('human form projection', () {
    test('projects every core coverage status into the five visible states',
        () {
      expect(
        smartTileVisibleFormStatus(SmartTileCoverageStatus.exact),
        SmartTileVisibleFormStatus.covered,
      );
      expect(
        smartTileVisibleFormStatus(SmartTileCoverageStatus.transformed),
        SmartTileVisibleFormStatus.generated,
      );
      expect(
        smartTileVisibleFormStatus(SmartTileCoverageStatus.fallback),
        SmartTileVisibleFormStatus.fallback,
      );
      expect(
        smartTileVisibleFormStatus(SmartTileCoverageStatus.ambiguous),
        SmartTileVisibleFormStatus.ambiguous,
      );
      for (final status in <SmartTileCoverageStatus>[
        SmartTileCoverageStatus.missing,
        SmartTileCoverageStatus.noCandidate,
        SmartTileCoverageStatus.missingVisualSource,
        SmartTileCoverageStatus.outOfAtlasGrid,
      ]) {
        expect(
          smartTileVisibleFormStatus(status),
          SmartTileVisibleFormStatus.missing,
        );
      }
    });

    test('labels canonical forms without leaking masks or hexadecimal codes',
        () {
      final controller = _controller()
        ..configureConnections(
          const SmartTileConnectionConfiguration(
            topology: SmartTileTopology.wangEdge4,
            templateHint: SmartTileTemplateHint.edge16,
          ),
          clearMappings: false,
        )
        ..addAtlasVariant(
          mask: 0,
          column: 0,
          row: 0,
          candidateId: 'island',
        );
      final catalog = controller.compileCatalog();
      final forms = projectSmartTileForms(
        preset: catalog.presets.single,
        materials: catalog.materials,
        atlases: catalog.atlases,
        animations: catalog.animations,
      );

      expect(forms, hasLength(16));
      expect(forms.first.status, SmartTileVisibleFormStatus.covered);
      expect(forms.where((form) => form.status.isBlocking), hasLength(15));
      for (final form in forms) {
        expect(form.label, isNot(contains('0x')));
        expect(form.label, isNot(contains('mask_')));
        expect(form.description, isNot(contains('0x')));
      }
    });

    test('finds every form already assigned to an atlas cell', () {
      final controller = _controller()
        ..addAtlasVariant(
          mask: smartTileNorthBit,
          column: 2,
          row: 3,
          candidateId: 'north',
        )
        ..addAtlasVariant(
          mask: smartTileSouthBit,
          column: 2,
          row: 3,
          candidateId: 'south',
        );
      final catalog = controller.compileCatalog();
      final forms = projectSmartTileForms(
        preset: catalog.presets.single,
        materials: catalog.materials,
        atlases: catalog.atlases,
        animations: catalog.animations,
      );

      expect(
        smartTileFormsForAtlasFrame(
          forms: forms,
          atlasId: 'atlas',
          column: 2,
          row: 3,
        ).map((form) => form.mask),
        <int>[smartTileNorthBit, smartTileSouthBit],
      );
    });
  });
}

SmartTileAuthoringController _controller() {
  return SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: 'smart-tile',
      name: 'Smart Tile',
      materialId: 'grass',
      materialName: 'Herbe',
    )
    ..selectUsage(SmartTileUsage.terrain)
    ..configureAtlas(
      atlasId: 'atlas',
      atlasName: 'Atlas',
      tilesetId: 'tileset',
      geometry: const SmartTileGridGeometry(
        imageWidth: 320,
        imageHeight: 320,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
}

SmartTileAuthoringController _largeController() {
  return SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: 'smart-tile',
      name: 'Smart Tile',
      materialId: 'grass',
      materialName: 'Herbe',
    )
    ..selectUsage(SmartTileUsage.path)
    ..configureAtlas(
      atlasId: 'atlas',
      atlasName: 'Atlas',
      tilesetId: 'tileset',
      geometry: const SmartTileGridGeometry(
        imageWidth: 1760,
        imageHeight: 2304,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
}
