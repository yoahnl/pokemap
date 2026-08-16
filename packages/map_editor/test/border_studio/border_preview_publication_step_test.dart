import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_canonical_gallery_canvas.dart';
import 'package:map_editor/src/features/border_studio/presentation/border_preview_publication_step.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('renders the six real prepared cases and enables exact publish', (
    tester,
  ) async {
    var publishCount = 0;
    await _pumpStep(
      tester,
      state: _state(),
      preview: _preview(),
      onPublish: () => publishCount += 1,
    );

    for (final galleryCase in _organicCases) {
      expect(
        find.byKey(
          ValueKey<String>('border-studio-gallery-case-${galleryCase.name}'),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Cas réels'), findsOneWidget);
    expect(find.text('6/6'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(6));

    final publish = find.byKey(const ValueKey<String>('border-studio-publish'));
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNotNull);
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    expect(publishCount, 1);
  });

  testWidgets('requires an explicit visual acknowledgement for warnings', (
    tester,
  ) async {
    const warningCode = 'border.publication.repetition_run';
    String? acknowledged;
    await _pumpStep(
      tester,
      state: _state(
        diagnostics: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            BorderDiagnostic(
              code: warningCode,
              severity: BorderDiagnosticSeverity.warning,
              phase: BorderDiagnosticPhase.publication,
              scope: BorderDiagnosticScope.blueprint,
              blueprintId: 'coast',
              suggestedAction: 'border.action.review',
            ),
          ],
        ),
      ),
      preview: _preview(),
      onAcknowledgeWarning: (code) => acknowledged = code,
    );

    final publish = find.byKey(const ValueKey<String>('border-studio-publish'));
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNull);
    expect(
      find.textContaining('séquences visuelles se répètent'),
      findsOneWidget,
    );

    final acknowledge = find.byKey(
      const ValueKey<String>(
        'border-studio-acknowledge-warning-border.publication.repetition_run',
      ),
    );
    await tester.ensureVisible(acknowledge);
    await tester.tap(acknowledge);
    expect(acknowledged, warningCode);
  });

  testWidgets(
    'shows an actionable French remediation for a missing connected-line transform',
    (tester) async {
      const diagnosticCode =
          'border.publication.connected_line_transform_unavailable';
      final diagnostic = BorderDiagnostic(
        code: diagnosticCode,
        severity: BorderDiagnosticSeverity.error,
        phase: BorderDiagnosticPhase.publication,
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: 'coast',
        parameters: const <String, Object?>{
          'role': 'lineCorner',
          'quarterTurns': 1,
          'flipX': true,
        },
        suggestedAction:
            'border.action.allow_required_connected_line_transform',
      );
      await _pumpStep(
        tester,
        state: _state(
          template: BorderBlueprintTemplate.connectedLine,
          diagnostics: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[diagnostic],
          ),
        ),
        preview: _preview(template: BorderBlueprintTemplate.connectedLine),
      );

      expect(find.text('Transformation requise pour Angle'), findsOneWidget);
      expect(
        find.text(
          'Supprimez puis réimportez l’asset de ce rôle pour autoriser les '
          'rotations et le miroir requis, puis régénérez l’aperçu.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(diagnosticCode), findsNothing);
    },
  );

  testWidgets(
    'details measured publication gaps without exposing diagnostic codes',
    (tester) async {
      const diagnosticCode = 'border.publication.coverage_gap_exceeded';
      final diagnostic = BorderDiagnostic(
        code: diagnosticCode,
        severity: BorderDiagnosticSeverity.error,
        phase: BorderDiagnosticPhase.publication,
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: 'coast',
        parameters: const <String, Object?>{
          'sampleId': 'sharpCorner',
          'coverageComponent': 'primary',
          'gapTolerancePx': 6,
          'longestContiguousGapPx': 16,
        },
        suggestedAction: 'border.action.reduce_coverage_gap',
      );
      await _pumpStep(
        tester,
        state: _state(
          template: BorderBlueprintTemplate.connectedLine,
          diagnostics: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[diagnostic],
          ),
        ),
        preview: _preview(template: BorderBlueprintTemplate.connectedLine),
      );

      expect(
        find.byKey(const ValueKey<String>('border-studio-publication-errors')),
        findsOneWidget,
      );
      expect(find.text('Corrections avant publication'), findsOneWidget);
      expect(
        find.text(
          'Le cas « Angle prononcé » contient un vide de 16 px, au-dessus des '
          '6 px tolérés. Augmentez le vide toléré ou ajustez les assets.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(diagnosticCode), findsNothing);
    },
  );

  testWidgets(
    'details actionable stone-chain errors without exposing diagnostic codes',
    (tester) async {
      const requiredNodeCode =
          'border.resolution.stone_chain_required_node_unresolved';
      const transformCode =
          'border.publication.stone_chain_transform_unavailable';
      await _pumpStep(
        tester,
        state: _state(
          template: BorderBlueprintTemplate.stoneChainLine,
          diagnostics: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[
              BorderDiagnostic(
                code: requiredNodeCode,
                severity: BorderDiagnosticSeverity.error,
                phase: BorderDiagnosticPhase.resolution,
                scope: BorderDiagnosticScope.segment,
                blueprintId: 'coast',
                suggestedAction: 'border.action.reduce_stone_node_overlap',
              ),
              BorderDiagnostic(
                code: transformCode,
                severity: BorderDiagnosticSeverity.error,
                phase: BorderDiagnosticPhase.publication,
                scope: BorderDiagnosticScope.blueprint,
                blueprintId: 'coast',
                suggestedAction: 'border.action.allow_required_transform',
              ),
            ],
          ),
        ),
        preview: _preview(template: BorderBlueprintTemplate.stoneChainLine),
      );

      expect(
        find.byKey(const ValueKey<String>('border-studio-stone-chain-errors')),
        findsOneWidget,
      );
      expect(find.text('Corrections de la chaîne de pierres'), findsOneWidget);
      expect(
        find.text(
          'Ajustez le tracé ou réduisez le chevauchement afin de placer chaque '
          'angle et extrémité.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Autorisez les orientations requises pour les pierres, puis régénérez '
          'la galerie.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(requiredNodeCode), findsNothing);
      expect(find.textContaining(transformCode), findsNothing);
    },
  );

  testWidgets(
    'explains missing two-tier roles and orientations in plain French',
    (tester) async {
      const faceCode = 'border.publication.stone_chain_face_role_missing';
      const orientationCode =
          'border.publication.stone_chain_directional_coverage_missing';
      await _pumpStep(
        tester,
        state: _state(
          template: BorderBlueprintTemplate.stoneChainLine,
          diagnostics: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[
              BorderDiagnostic(
                code: faceCode,
                severity: BorderDiagnosticSeverity.error,
                phase: BorderDiagnosticPhase.publication,
                scope: BorderDiagnosticScope.blueprint,
                blueprintId: 'coast',
                suggestedAction: 'border.action.assign_stone_chain_face',
              ),
              BorderDiagnostic(
                code: orientationCode,
                severity: BorderDiagnosticSeverity.error,
                phase: BorderDiagnosticPhase.publication,
                scope: BorderDiagnosticScope.blueprint,
                blueprintId: 'coast',
                suggestedAction: 'border.action.complete_directional_coverage',
              ),
            ],
          ),
        ),
        preview: _preview(template: BorderBlueprintTemplate.stoneChainLine),
      );

      expect(
        find.text('Assignez au moins un asset au rôle Face de falaise.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Renseignez l’orientation dessinée des assets pour couvrir Nord, Est, Sud et Ouest.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(faceCode), findsNothing);
      expect(find.textContaining(orientationCode), findsNothing);
    },
  );

  testWidgets('previews every frame that the candidate will publish', (
    tester,
  ) async {
    final preview = _preview(animated: true);
    await _pumpStep(tester, state: _state(), preview: preview, settle: false);

    expect(find.byType(Image), findsNWidgets(6));
    for (final widget in tester.widgetList<Image>(find.byType(Image))) {
      expect((widget.image as MemoryImage).bytes, orderedEquals(_png()));
    }

    await tester.pump(const Duration(milliseconds: 40));
    for (final widget in tester.widgetList<Image>(find.byType(Image))) {
      expect((widget.image as MemoryImage).bytes, orderedEquals(_secondPng()));
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('uses the selected template canonical case count', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      state: _state(template: BorderBlueprintTemplate.masonryLine),
      preview: _preview(template: BorderBlueprintTemplate.masonryLine),
    );

    expect(find.text('3/3'), findsOneWidget);
    expect(find.textContaining('Générez les 3 cas canoniques'), findsOneWidget);
    expect(find.textContaining('six cas'), findsNothing);
  });

  testWidgets('connected line previews both sides of all topological cases', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      state: _state(template: BorderBlueprintTemplate.connectedLine),
      preview: _preview(template: BorderBlueprintTemplate.connectedLine),
    );

    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('Côté principal'), findsNWidgets(4));
    expect(find.text('Côté inversé'), findsNWidgets(4));
    for (final galleryCase in <BorderCanonicalGalleryCase>[
      BorderCanonicalGalleryCase.longEdge,
      BorderCanonicalGalleryCase.sharpCorner,
      BorderCanonicalGalleryCase.endpoint,
      BorderCanonicalGalleryCase.opening,
    ]) {
      expect(
        find.byKey(
          ValueKey<String>('border-studio-gallery-case-${galleryCase.name}'),
        ),
        findsOneWidget,
      );
      final primaryFinder = find.byKey(
        ValueKey<String>('border-studio-gallery-${galleryCase.name}-primary'),
      );
      final invertedFinder = find.byKey(
        ValueKey<String>('border-studio-gallery-${galleryCase.name}-inverted'),
      );
      expect(primaryFinder, findsOneWidget);
      expect(invertedFinder, findsOneWidget);
      expect(
        tester
            .widget<BorderCanonicalGalleryCanvas>(primaryFinder)
            .materialization!
            .placements
            .map((placement) => placement.transform.flipX),
        everyElement(isFalse),
      );
      expect(
        tester
            .widget<BorderCanonicalGalleryCanvas>(invertedFinder)
            .materialization!
            .placements
            .map((placement) => placement.transform.flipX),
        everyElement(isTrue),
      );
    }

    final sharpCorner = tester.widget<BorderCanonicalGalleryCanvas>(
      find.byKey(
        const ValueKey<String>('border-studio-gallery-sharpCorner-primary'),
      ),
    );
    expect(
      (sharpCorner.geometry as BorderStrokeGeometry).strokes.map(
        (stroke) => stroke.id,
      ),
      orderedEquals(<String>['leftTurn', 'rightTurn']),
    );
    expect(find.byType(Image), findsNWidgets(8));
  });

  testWidgets(
    'stone chain previews five grid-edge cases on both sides without mirroring pixels',
    (tester) async {
      await _pumpStep(
        tester,
        state: _state(template: BorderBlueprintTemplate.stoneChainLine),
        preview: _preview(template: BorderBlueprintTemplate.stoneChainLine),
      );

      final galleryCases = borderCanonicalGalleryCasesForTemplate(
        BorderBlueprintTemplate.stoneChainLine,
      );
      expect(galleryCases, hasLength(5));
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('Côté principal'), findsNWidgets(5));
      expect(find.text('Côté inversé'), findsNWidgets(5));
      expect(find.byType(Image), findsNWidgets(10));

      for (final galleryCase in galleryCases) {
        final primary = tester.widget<BorderCanonicalGalleryCanvas>(
          find.byKey(
            ValueKey<String>(
              'border-studio-gallery-${galleryCase.name}-primary',
            ),
          ),
        );
        final inverted = tester.widget<BorderCanonicalGalleryCanvas>(
          find.byKey(
            ValueKey<String>(
              'border-studio-gallery-${galleryCase.name}-inverted',
            ),
          ),
        );
        expect(
          (primary.geometry as BorderStrokeGeometry).alignment,
          BorderStrokeAlignment.gridEdges,
        );
        expect(
          primary.materialization!.placements.map(
            (placement) => placement.transform.flipX,
          ),
          everyElement(isFalse),
        );
        expect(
          inverted.materialization!.placements.map(
            (placement) => placement.transform.flipX,
          ),
          everyElement(isFalse),
        );
      }
    },
  );

  testWidgets('connected line cannot publish with a missing inverted preview', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      state: _state(template: BorderBlueprintTemplate.connectedLine),
      preview: _preview(
        template: BorderBlueprintTemplate.connectedLine,
        includeInvertedConnectedSide: false,
      ),
    );

    final publish = find.byKey(const ValueKey<String>('border-studio-publish'));
    expect(tester.widget<PokeMapButton>(publish).onPressed, isNull);
    expect(
      find.textContaining(
        'Les 4 cas canoniques doivent être résolus sans erreur',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpStep(
  WidgetTester tester, {
  required BorderStudioDraftState state,
  required BorderStudioPublicationPreview preview,
  VoidCallback? onPublish,
  ValueChanged<String>? onAcknowledgeWarning,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BorderPreviewPublicationStep(
            state: state,
            preview: preview,
            isPreparing: false,
            isPublishing: false,
            onPreparePreview: () {},
            onNewVariation: () {},
            onAcknowledgeWarning: onAcknowledgeWarning ?? (_) {},
            onSaveDraft: () {},
            onPublish: onPublish ?? () {},
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

BorderStudioDraftState _state({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  BorderDiagnosticsReport diagnostics = const BorderDiagnosticsReport.empty(),
}) {
  final record = _record(template: template);
  return BorderStudioDraftState(
    catalogRecords: <BorderBlueprintRecord>[record],
    selectedBlueprintId: record.id,
    workingDraft: BorderStudioDraft(id: record.id, blueprint: record.draft),
    diagnostics: diagnostics,
    diagnosticsAreCurrent: true,
  );
}

BorderStudioPublicationPreview _preview({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  bool animated = false,
  bool includeInvertedConnectedSide = true,
}) {
  final record = _record(template: template);
  final galleryCases = borderCanonicalGalleryCasesForTemplate(template);
  final snapshot = _snapshot(animated: animated);
  final manifest = ProjectManifest(
    name: 'Gallery',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: minimumBorderCatalogFormatVersionForTemplate(template),
      records: <BorderBlueprintRecord>[record],
      visualSnapshots: <BorderVisualSnapshot>[snapshot],
    ),
  );
  final candidate = BorderPublicationCandidate(
    nextManifest: manifest,
    revision: 1,
    files: <BorderSnapshotFilePayload>[
      BorderSnapshotFilePayload(
        relativePath: snapshot.frames.first.relativeAssetPath,
        bytes: _png(),
      ),
      if (animated)
        BorderSnapshotFilePayload(
          relativePath: snapshot.frames[1].relativeAssetPath,
          bytes: _secondPng(),
        ),
    ],
    snapshotIntegrity: <String, BorderVisualSnapshotIntegrity>{
      _snapshotId: BorderVisualSnapshotIntegrity(
        snapshotId: _snapshotId,
        metadataValid: true,
        filesPresent: true,
        contentFingerprintMatches: true,
      ),
    },
    primitiveSnapshotIdsByPrimitiveId: const <String, String>{
      'rock': _snapshotId,
    },
    groundSnapshotIdsByRole: const <BorderGroundVariantRole, String>{},
  );
  final samples = <BorderPublicationGallerySample>[
    for (final galleryCase in galleryCases)
      BorderPublicationGallerySample(
        galleryCase: galleryCase,
        coverageChecks: <BorderPublicationCoverageCheck>[
          BorderPublicationCoverageCheck(
            component: BorderCanonicalCoverageComponent.primary,
            longestContiguousGapPx: 0,
            maximumPairwiseOverlapPx: 0,
            gapTolerancePx: 2,
            maxOverlapPx: 4,
          ),
        ],
        structuralRuns: const <BorderPublicationStructuralRun>[],
      ),
  ];
  final report = BorderPublicationGalleryReport(
    resolverVersion: 1,
    canonicalGalleryVersion: borderCanonicalGalleryVersion,
    candidateFingerprint: _fingerprint,
    samples: samples,
  );
  return BorderStudioPublicationPreview(
    previousManifest: manifest,
    draftRecord: record,
    candidate: candidate,
    resolverVersion: 1,
    canonicalGalleryReport: report,
    canonicalGalleryCases: <BorderStudioCanonicalGalleryCasePreview>[
      for (var index = 0; index < galleryCases.length; index += 1)
        BorderStudioCanonicalGalleryCasePreview(
          galleryCase: galleryCases[index],
          mapSize: template == BorderBlueprintTemplate.organicEdge
              ? const GridSize(width: 1, height: 1)
              : const GridSize(width: 4, height: 3),
          geometry: _galleryGeometry(
            template: template,
            galleryCase: galleryCases[index],
          ),
          resolution: _resolution(index),
          invertedResolution:
              borderTemplateRequiresInvertedCanonicalGallery(template) &&
                  includeInvertedConnectedSide
              ? _resolution(
                  index,
                  flipX: template == BorderBlueprintTemplate.connectedLine,
                )
              : null,
          publicationSample: samples[index],
        ),
    ],
    resolutionDiagnostics: const BorderDiagnosticsReport.empty(),
    diagnostics: const BorderDiagnosticsReport.empty(),
  );
}

BorderBlueprintRecord _record({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
}) => BorderBlueprintRecord(
  id: 'coast',
  draft: BorderBlueprintDraft(
    baseRevision: 0,
    definition: BorderBlueprintDraftDefinition(
      name: 'Côte',
      previewSeed: BorderSignedInt64.fromInt(7),
      template: template,
      primitives: <BorderPrimitiveDraft>[
        _draftPrimitive(
          id: 'rock',
          role: template == BorderBlueprintTemplate.connectedLine
              ? BorderPrimitiveRole.lineCap
              : BorderPrimitiveRole.structureLarge,
          allowFlipX: template == BorderBlueprintTemplate.connectedLine,
        ),
        if (template == BorderBlueprintTemplate.connectedLine) ...[
          _draftPrimitive(
            id: 'straight',
            role: BorderPrimitiveRole.lineStraight,
            allowFlipX: true,
          ),
          _draftPrimitive(
            id: 'corner',
            role: BorderPrimitiveRole.lineCorner,
            allowFlipX: true,
          ),
        ],
      ],
      defaults: BorderGenerationParams(
        irregularityPermille: 250,
        detailDensityPermille: 500,
        variationPermille: 300,
        maxOverlapPx: 4,
        gapTolerancePx: 2,
        depthRows: template == BorderBlueprintTemplate.stoneChainLine ? 2 : 1,
      ),
      sortOrder: 0,
    ),
  ),
);

BorderPrimitiveDraft _draftPrimitive({
  required String id,
  required BorderPrimitiveRole role,
  required bool allowFlipX,
}) => BorderPrimitiveDraft(
  id: id,
  sourceElementId: '$id-element',
  role: role,
  weight: 100,
  anchorPx: const BorderPixelPos(x: 1, y: 1),
  transforms: BorderTransformPolicy(
    allowFlipX: allowFlipX,
    allowedQuarterTurns: const <int>[0],
  ),
  currentMetrics: BorderPrimitiveAssetMetrics(
    assetFingerprint: 'source-$id',
    pixelSize: const GridSize(width: 2, height: 2),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
    defaultAnchorPx: const BorderPixelPos(x: 1, y: 1),
    occupancyMaskRle: '1:4',
  ),
);

BorderFeatureGeometry _galleryGeometry({
  required BorderBlueprintTemplate template,
  required BorderCanonicalGalleryCase galleryCase,
}) {
  if (template == BorderBlueprintTemplate.organicEdge) {
    return BorderRegionGeometry(width: 1, height: 1, cells: const <bool>[true]);
  }
  if (template == BorderBlueprintTemplate.connectedLine &&
      galleryCase == BorderCanonicalGalleryCase.sharpCorner) {
    return BorderStrokeGeometry(
      strokes: <BorderStroke>[
        BorderStroke(
          id: 'leftTurn',
          points: const <GridPos>[
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
            GridPos(x: 1, y: 2),
          ],
          closed: false,
        ),
        BorderStroke(
          id: 'rightTurn',
          points: const <GridPos>[
            GridPos(x: 2, y: 1),
            GridPos(x: 3, y: 1),
            GridPos(x: 3, y: 0),
          ],
          closed: false,
        ),
      ],
    );
  }
  return BorderStrokeGeometry(
    alignment: borderTemplateStrokeAlignment(template),
    strokes: <BorderStroke>[
      BorderStroke(
        id: 'line',
        points: const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        closed: false,
      ),
    ],
  );
}

BorderResolutionResult _resolution(int index, {bool flipX = false}) =>
    BorderResolutionResult(
      materialization: BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: 1,
          blueprintRevision: 1,
          components: BorderInputFingerprints(
            blueprint: _fingerprint,
            geometryAndSeed: _fingerprint,
            parameters: _fingerprint,
            overrides: _fingerprint,
            keepOutRegions: _fingerprint,
            mapContext: _fingerprint,
            visualSnapshots: _fingerprint,
          ),
          inputFingerprint: _fingerprint,
          outputFingerprint: _fingerprint,
        ),
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[
          BorderResolvedPlacement(
            id: 'placement-$index',
            slotKey: 'slot-$index',
            primitiveId: 'rock',
            visualSnapshotId: _snapshotId,
            anchorCell: const GridPos(x: 0, y: 0),
            topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
            opaqueWorldBoundsPx: BorderPixelRect(
              x: 0,
              y: 0,
              width: 2,
              height: 2,
            ),
            transform: BorderSpriteTransform(quarterTurns: 0, flipX: flipX),
            drawBand: BorderDrawBand.structure,
            stableOrderKey: BorderStableOrderKey(
              drawBandIndex: 1,
              anchorRowMajor: 0,
              passIndex: 0,
              rank: 0,
              ordinalLocal: 0,
              slotKey: 'slot-$index',
            ),
          ),
        ],
      ),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

BorderVisualSnapshot _snapshot({bool animated = false}) => BorderVisualSnapshot(
  id: _snapshotId,
  contentFingerprint: 'a' * 64,
  frames: <BorderVisualFrameSnapshot>[
    BorderVisualFrameSnapshot(
      relativeAssetPath: 'assets/borders/snapshots/${'a' * 64}/frame_0000.png',
      sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
      durationMs: animated ? 40 : 100,
    ),
    if (animated)
      BorderVisualFrameSnapshot(
        relativeAssetPath:
            'assets/borders/snapshots/${'a' * 64}/frame_0001.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
        durationMs: 60,
      ),
  ],
);

Uint8List _png() {
  final bitmap = image.Image(width: 2, height: 2);
  for (var y = 0; y < 2; y += 1) {
    for (var x = 0; x < 2; x += 1) {
      bitmap.setPixelRgba(x, y, 120, 130, 140, 255);
    }
  }
  return Uint8List.fromList(image.encodePng(bitmap));
}

Uint8List _secondPng() {
  final bitmap = image.Image(width: 2, height: 2);
  for (var y = 0; y < 2; y += 1) {
    for (var x = 0; x < 2; x += 1) {
      bitmap.setPixelRgba(x, y, 40, 50, 60, 255);
    }
  }
  return Uint8List.fromList(image.encodePng(bitmap));
}

const _organicCases = <BorderCanonicalGalleryCase>[
  BorderCanonicalGalleryCase.longEdge,
  BorderCanonicalGalleryCase.gentleCurve,
  BorderCanonicalGalleryCase.sharpConvexCorner,
  BorderCanonicalGalleryCase.sharpConcaveCorner,
  BorderCanonicalGalleryCase.hole,
  BorderCanonicalGalleryCase.smallIsland,
];
const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprint =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
