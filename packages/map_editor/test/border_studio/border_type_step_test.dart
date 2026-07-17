import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_type_step.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'disables only templates incompatible with current primitive roles',
    (tester) async {
      final selectedTemplates = <BorderBlueprintTemplate>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: BorderTypeStep(
              state: _stateWithStructurePrimitive(),
              onTemplateSelected: selectedTemplates.add,
            ),
          ),
        ),
      );

      final masonryButton = tester.widget<PokeMapButton>(
        find.byKey(
          const ValueKey<String>('border-studio-template-masonry'),
        ),
      );
      final fenceButton = tester.widget<PokeMapButton>(
        find.byKey(
          const ValueKey<String>('border-studio-template-fence'),
        ),
      );
      final connectedButton = tester.widget<PokeMapButton>(
        find.byKey(
          const ValueKey<String>('border-studio-template-connected-line'),
        ),
      );

      expect(masonryButton.onPressed, isNotNull);
      expect(fenceButton.onPressed, isNull);
      expect(connectedButton.onPressed, isNull);
      expect(find.text('Ligne connectée'), findsOneWidget);
      expect(find.text('Publication disponible'), findsNWidgets(4));
      expect(find.text('Publication après BORD-03'), findsNothing);
      expect(
        find.text(
          'Indisponible : le rôle « Structure principale » n’est pas pris en '
          'charge. Réattribuez ou retirez l’asset concerné avant de choisir ce '
          'type.',
        ),
        findsNWidgets(2),
      );

      masonryButton.onPressed!();
      expect(
        selectedTemplates,
        <BorderBlueprintTemplate>[BorderBlueprintTemplate.masonryLine],
      );
    },
  );
}

BorderStudioDraftState _stateWithStructurePrimitive() {
  return BorderStudioDraftState(
    selectedBlueprintId: 'coast',
    workingDraft: BorderStudioDraft(
      id: 'coast',
      blueprint: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: 'Côte rocheuse',
          previewSeed: BorderSignedInt64.fromInt(1),
          template: BorderBlueprintTemplate.organicEdge,
          primitives: <BorderPrimitiveDraft>[
            BorderPrimitiveDraft(
              id: 'coast-structure',
              sourceElementId: 'coast-rock',
              role: BorderPrimitiveRole.structureLarge,
              weight: 1000,
              anchorPx: const BorderPixelPos(x: 8, y: 15),
              transforms: BorderTransformPolicy(
                allowFlipX: false,
                allowedQuarterTurns: const <int>[0],
              ),
              currentMetrics: BorderPrimitiveAssetMetrics(
                assetFingerprint: 'coast-structure-fingerprint',
                pixelSize: const GridSize(width: 16, height: 16),
                opaqueBounds:
                    BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
                defaultAnchorPx: const BorderPixelPos(x: 8, y: 15),
                occupancyMaskRle: '1:256',
              ),
            ),
          ],
          defaults: BorderGenerationParams(
            irregularityPermille: 250,
            detailDensityPermille: 500,
            variationPermille: 300,
            maxOverlapPx: 4,
            gapTolerancePx: 1,
            depthRows: 1,
          ),
          sortOrder: 0,
        ),
      ),
    ),
  );
}
