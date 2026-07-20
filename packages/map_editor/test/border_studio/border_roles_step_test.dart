import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_roles_step.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('two-tier stone chains require one top and one cliff face',
      (tester) async {
    final state = _state(
      depthRows: 2,
      primitives: <BorderPrimitiveDraft>[
        _primitive(
          id: 'top',
          role: BorderPrimitiveRole.structureLarge,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: BorderRolesStep(
            state: state,
            onRoleChanged: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Sommet plat'), findsWidgets);
    expect(find.text('Face de falaise'), findsWidgets);
    expect(find.text('Pierre libre facultative'), findsWidgets);
    expect(find.text('Pierre de sommet à un angle'), findsWidgets);
    expect(find.text('Pierre de sommet à une extrémité'), findsWidgets);
    expect(find.text('Requis'), findsNWidgets(2));
    expect(find.text('Face de falaise', skipOffstage: false), findsWidgets);
    expect(find.text('Rôles non résolus'), findsOneWidget);
  });

  testWidgets('one-tier stone chains keep the face optional', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: BorderRolesStep(
            state: _state(
              depthRows: 1,
              primitives: <BorderPrimitiveDraft>[
                _primitive(
                  id: 'top',
                  role: BorderPrimitiveRole.structureLarge,
                ),
              ],
            ),
            onRoleChanged: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Requis'), findsOneWidget);
    expect(find.text('Rôles non résolus'), findsNothing);
  });
}

BorderStudioDraftState _state({
  required int depthRows,
  required List<BorderPrimitiveDraft> primitives,
}) =>
    BorderStudioDraftState(
      workingDraft: BorderStudioDraft(
        id: 'cliff',
        blueprint: BorderBlueprintDraft(
          baseRevision: 0,
          definition: BorderBlueprintDraftDefinition(
            name: 'Falaise',
            previewSeed: BorderSignedInt64.fromInt(1),
            template: BorderBlueprintTemplate.stoneChainLine,
            primitives: primitives,
            defaults: BorderGenerationParams(
              irregularityPermille: 180,
              detailDensityPermille: 0,
              variationPermille: 1000,
              maxOverlapPx: 8,
              gapTolerancePx: 0,
              depthRows: depthRows,
              allowAutoRotation: false,
            ),
            sortOrder: 0,
          ),
        ),
      ),
    );

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
}) =>
    BorderPrimitiveDraft(
      id: id,
      sourceElementId: 'source-$id',
      role: role,
      weight: 1000,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: false,
        allowedQuarterTurns: const <int>[0],
      ),
      currentMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'fingerprint-$id',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: '1:256',
      ),
    );
