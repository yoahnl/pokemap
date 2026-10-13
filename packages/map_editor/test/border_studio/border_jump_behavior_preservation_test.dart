import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft_controller.dart';

void main() {
  test('ordinary draft edits preserve its Border jump behavior', () {
    final jump = BorderJumpBehavior(side: BorderLineSide.inverted);
    for (final edit in ['rename', 'parameters', 'primitives']) {
      final provider =
          NotifierProvider<BorderStudioDraftController, BorderStudioDraftState>(
            BorderStudioDraftController.new,
          );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(provider.notifier);
      final record = BorderBlueprintRecord(
        id: 'ledge',
        draft: BorderBlueprintDraft(
          baseRevision: 0,
          definition: BorderBlueprintDraftDefinition(
            name: 'Ledge',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: [],
            defaults: _rules(),
            sortOrder: 0,
            jumpBehavior: jump,
          ),
        ),
      );
      controller.loadFromManifest(
        ProjectManifest(
          name: 'Border preservation',
          version: ProjectVersion.v8,
          maps: [],
          tilesets: [],
          borderCatalog: ProjectBorderCatalog(records: [record]),
        ),
      );
      switch (edit) {
        case 'rename':
          controller.renameBlueprint('Renamed ledge');
        case 'parameters':
          controller.setGenerationParams(_rules(depthRows: 2));
        case 'primitives':
          controller.replacePrimitives([
            BorderPrimitiveDraft(
              id: 'body',
              sourceElementId: 'ledge-body',
              role: BorderPrimitiveRole.structureLarge,
              weight: 1,
              anchorPx: const BorderPixelPos(x: 0, y: 0),
              currentMetrics: BorderPrimitiveAssetMetrics(
                assetFingerprint: 'ledge-body',
                pixelSize: const GridSize(width: 1, height: 1),
                opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
                defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
                occupancyMaskRle: encodeBorderRleMask([true]),
              ),
              transforms: BorderTransformPolicy(
                allowFlipX: false,
                allowedQuarterTurns: [0],
              ),
            ),
          ]);
      }
      expect(
        controller.state.workingDraft!.blueprint.definition.jumpBehavior,
        jump,
        reason: edit,
      );
      expect(
        controller
            .saveDraft()
            .borderCatalog
            .records
            .single
            .draft
            .definition
            .jumpBehavior,
        jump,
        reason: '$edit saved',
      );
    }
  });
}

BorderGenerationParams _rules({int depthRows = 1}) => BorderGenerationParams(
  irregularityPermille: 0,
  detailDensityPermille: 0,
  variationPermille: 0,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: depthRows,
);
