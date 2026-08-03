import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/stages/smart_tile_publish_stage.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

void main() {
  testWidgets('requires an explicit destination without a deferred Wang gate',
      (tester) async {
    final layerId = TextEditingController(text: 'path_layer');
    final layerName = TextEditingController(text: 'Chemin');
    addTearDown(layerId.dispose);
    addTearDown(layerName.dispose);
    SmartTilePublicationTargetKind? selectedTarget;

    await _pumpStage(
      tester,
      layerId: layerId,
      layerName: layerName,
      onTargetChanged: (target) => selectedTarget = target,
    );

    expect(find.text('Bibliothèque seulement'), findsOneWidget);
    expect(find.text('Map map'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('smart-tiles-publish-target-map')),
    );
    expect(selectedTarget, SmartTilePublicationTargetKind.map);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const Key('smart-tiles-publish-plan')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('shows the exact atomic plan before enabling apply',
      (tester) async {
    final layerId = TextEditingController(text: 'ground_layer');
    final layerName = TextEditingController(text: 'Prairie');
    addTearDown(layerId.dispose);
    addTearDown(layerName.dispose);
    var applied = false;
    final plan = _plan();

    await _pumpStage(
      tester,
      layerId: layerId,
      layerName: layerName,
      targetKind: SmartTilePublicationTargetKind.map,
      plan: plan,
      onApply: () => applied = true,
    );

    expect(
      find.byKey(const Key('smart-tiles-publish-plan-summary')),
      findsOneWidget,
    );
    expect(find.text('Tout ou rien'), findsOneWidget);
    expect(find.text('ground'), findsOneWidget);
    expect(find.text('ground_layer'), findsWidgets);
    expect(find.text('Manifeste · project'), findsOneWidget);
    expect(find.text('Map · map'), findsOneWidget);
    expect(find.text('1 avertissement(s) conservé(s)'), findsOneWidget);

    final apply = find.byKey(const Key('smart-tiles-publish-apply'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    expect(applied, isTrue);
  });
}

Future<void> _pumpStage(
  WidgetTester tester, {
  required TextEditingController layerId,
  required TextEditingController layerName,
  SmartTilePublicationTargetKind targetKind =
      SmartTilePublicationTargetKind.library,
  SmartTilePublicationPlan? plan,
  ValueChanged<SmartTilePublicationTargetKind>? onTargetChanged,
  VoidCallback? onApply,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 900,
          child: SingleChildScrollView(
            child: SmartTilePublishStage(
              name: 'Prairie',
              usage: SmartTileUsage.terrain,
              atlasSummary: 'atlas.png',
              gridSummary: '16 × 16 px',
              guideSummary: 'Sans raccords',
              mappingSummary: '1 association',
              targetKind: targetKind,
              mapId: 'map',
              mapAvailable: true,
              layerIdController: layerId,
              layerNameController: layerName,
              blockingDiagnostics: const <SmartTileDiagnostic>[],
              warningDiagnostics: const <SmartTileDiagnostic>[],
              busy: false,
              plan: plan,
              errorCode: null,
              errorMessage: null,
              published: false,
              onTargetChanged: onTargetChanged ?? (_) {},
              onLayerIdentityChanged: () {},
              onPlan: () {},
              onApply: onApply ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

SmartTilePublicationPlan _plan() {
  final receipt = AuthoringReceipt(
    receiptId: 'receipt',
    requestId: 'request',
    actionId: 'smart_tile.preset.publish',
    actionVersion: 1,
    status: AuthoringReceiptStatus.planned,
    createdAtUtc: '2026-08-03T00:00:00.000Z',
    diff: AuthoringDiff(<AuthoringDiffEntry>[
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: AuthoringResourceRef(kind: 'project', id: 'project'),
        path: '/smartTileCatalog',
        after: const <String, Object?>{},
      ),
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: AuthoringResourceRef(kind: 'map', id: 'map'),
        path: '/layers/ground_layer',
        after: const <String, Object?>{'id': 'ground_layer'},
      ),
    ]),
  );
  return SmartTilePublicationPlan(
    canonical: SmartTilePublicationCanonicalPlan(
      token: Object(),
      planId: 'plan-publish',
      snapshotRevision: 'revision',
      receipt: receipt,
    ),
    target: const SmartTilePublicationTarget.map(
      mapId: 'map',
      layerId: 'ground_layer',
      layerName: 'Prairie',
    ),
    draftId: 'draft-ground',
    presetId: 'ground',
    warnings: const <SmartTileDiagnostic>[
      SmartTileDiagnostic(
        code: 'smart_tile.test.warning',
        severity: SmartTileDiagnosticSeverity.warning,
        path: r'$.rules',
        message: 'Vérifiez la variation.',
      ),
    ],
  );
}
