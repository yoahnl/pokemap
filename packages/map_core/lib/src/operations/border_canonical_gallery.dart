import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_coverage.dart';
import 'border_publication_readiness.dart';
import 'border_resolver.dart';
import 'connected_line_border_resolver.dart';
import 'masonry_line_border_resolver.dart';
import 'organic_edge_canonical_gallery.dart';
import 'post_and_rail_line_border_resolver.dart';

const GridSize _lineGalleryMapSize = GridSize(width: 12, height: 10);

/// Template-neutral canonical gallery resolved from production solvers.
@immutable
final class BorderCanonicalGalleryResult {
  BorderCanonicalGalleryResult._({
    required this.template,
    required this.report,
    required List<BorderCanonicalGalleryCaseResult> cases,
    required this.resolutionDiagnostics,
  }) : _cases = List<BorderCanonicalGalleryCaseResult>.unmodifiable(cases);

  final BorderBlueprintTemplate template;
  final BorderPublicationGalleryReport report;
  final List<BorderCanonicalGalleryCaseResult> _cases;
  final BorderDiagnosticsReport resolutionDiagnostics;

  List<BorderCanonicalGalleryCaseResult> get cases => _cases;

  bool get allCasesResolved =>
      _cases.length ==
          borderCanonicalGalleryCasesForTemplate(template).length &&
      _cases.every(
        (item) =>
            item.resolverResult.canApply &&
            (template != BorderBlueprintTemplate.connectedLine ||
                item.invertedResolverResult?.canApply == true),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderCanonicalGalleryResult &&
          template == other.template &&
          report == other.report &&
          _listEquals(_cases, other._cases) &&
          resolutionDiagnostics == other.resolutionDiagnostics;

  @override
  int get hashCode => Object.hash(
        template,
        report,
        Object.hashAll(_cases),
        resolutionDiagnostics,
      );
}

/// One neutral case, including the exact geometry sent to the real solver.
@immutable
final class BorderCanonicalGalleryCaseResult {
  const BorderCanonicalGalleryCaseResult._({
    required this.galleryCase,
    required this.mapSize,
    required this.geometry,
    required this.resolverResult,
    this.invertedResolverResult,
    required this.publicationSample,
  });

  final BorderCanonicalGalleryCase galleryCase;
  final GridSize mapSize;
  final BorderFeatureGeometry geometry;

  /// Primary-side output retained under the original gallery API.
  final BorderResolutionResult resolverResult;

  /// Opposite-side output for `connectedLine`; `null` for other templates.
  final BorderResolutionResult? invertedResolverResult;
  final BorderPublicationGallerySample publicationSample;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderCanonicalGalleryCaseResult &&
          galleryCase == other.galleryCase &&
          mapSize == other.mapSize &&
          geometry == other.geometry &&
          resolverResult == other.resolverResult &&
          invertedResolverResult == other.invertedResolverResult &&
          publicationSample == other.publicationSample;

  @override
  int get hashCode => Object.hash(
        galleryCase,
        mapSize,
        geometry,
        resolverResult,
        invertedResolverResult,
        publicationSample,
      );
}

/// Resolves the immutable canonical gallery for a published V1 template.
BorderCanonicalGalleryResult resolveBorderCanonicalGallery({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  int resolverVersion = borderResolverVersion,
}) {
  final definition = blueprintRevision.definition;
  final snapshots = visualSnapshots.toList(growable: false);
  if (definition.template == BorderBlueprintTemplate.organicEdge) {
    return _adaptOrganicGallery(
      resolveOrganicEdgeCanonicalGallery(
        blueprintId: blueprintId,
        blueprintRevision: blueprintRevision,
        visualSnapshots: snapshots,
        tileSizePx: tileSizePx,
        resolverVersion: resolverVersion,
      ),
    );
  }
  final cases = <BorderCanonicalGalleryCaseResult>[];
  final diagnostics = <BorderDiagnostic>[];

  for (final galleryCase in borderCanonicalGalleryCasesForTemplate(
    definition.template,
  )) {
    final caseWire = borderCanonicalGalleryCaseV1WireName(galleryCase);
    switch (definition.template) {
      case BorderBlueprintTemplate.masonryLine:
        final geometry = _masonryGeometryFor(galleryCase);
        final evidence = resolveMasonryLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
          ),
        );
        diagnostics.addAll(evidence.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: <BorderPublicationCoverageCheck>[
            _masonryCoverageCheck(
              evidence,
              definition.defaults,
            ),
          ],
          structuralRuns: _structuralRuns(
            caseWire: caseWire,
            result: evidence.result,
            definition: definition,
            geometry: geometry,
            acceptedRoles: const <BorderPrimitiveRole>{
              BorderPrimitiveRole.structureLarge,
              BorderPrimitiveRole.structureMedium,
              BorderPrimitiveRole.filler,
            },
          ),
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: evidence.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.postAndRailLine:
        final geometry = _fenceGeometryFor(galleryCase);
        final evidence = resolvePostAndRailLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
          ),
        );
        diagnostics.addAll(evidence.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: _fenceCoverageChecks(
            galleryCase: galleryCase,
            evidence: evidence,
            params: definition.defaults,
          ),
          structuralRuns: _structuralRuns(
            caseWire: caseWire,
            result: evidence.result,
            definition: definition,
            geometry: geometry,
            acceptedRoles: const <BorderPrimitiveRole>{
              BorderPrimitiveRole.post,
              BorderPrimitiveRole.span,
            },
          ),
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: evidence.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.connectedLine:
        final geometry = _connectedLineGeometryFor(galleryCase);
        final primary = resolveConnectedLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.primary,
          ),
        );
        final inverted = resolveConnectedLineBorderWithEvidence(
          _request(
            mapSize: _lineGalleryMapSize,
            tileSizePx: tileSizePx,
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: snapshots,
            resolverVersion: resolverVersion,
            caseWire: caseWire,
            geometry: geometry,
            lineSide: BorderLineSide.inverted,
          ),
        );
        diagnostics
          ..addAll(primary.result.diagnostics)
          ..addAll(inverted.result.diagnostics);
        final sample = BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: _connectedLineCoverageChecks(
            galleryCase: galleryCase,
            params: definition.defaults,
            geometry: geometry,
            definition: definition,
            primary: primary.result,
            inverted: inverted.result,
            tileSizePx: tileSizePx,
          ),
          structuralRuns: <BorderPublicationStructuralRun>[
            ..._structuralRuns(
              caseWire: caseWire,
              idPrefix: 'primary:$caseWire',
              result: primary.result,
              definition: definition,
              geometry: geometry,
              acceptedRoles: const <BorderPrimitiveRole>{
                BorderPrimitiveRole.lineCap,
                BorderPrimitiveRole.lineStraight,
                BorderPrimitiveRole.lineCorner,
              },
            ),
            ..._structuralRuns(
              caseWire: caseWire,
              idPrefix: 'inverted:$caseWire',
              result: inverted.result,
              definition: definition,
              geometry: geometry,
              acceptedRoles: const <BorderPrimitiveRole>{
                BorderPrimitiveRole.lineCap,
                BorderPrimitiveRole.lineStraight,
                BorderPrimitiveRole.lineCorner,
              },
            ),
          ],
        );
        cases.add(
          BorderCanonicalGalleryCaseResult._(
            galleryCase: galleryCase,
            mapSize: _lineGalleryMapSize,
            geometry: geometry,
            resolverResult: primary.result,
            invertedResolverResult: inverted.result,
            publicationSample: sample,
          ),
        );
      case BorderBlueprintTemplate.organicEdge:
        throw StateError('Organic gallery is adapted before line dispatch');
    }
  }

  return BorderCanonicalGalleryResult._(
    template: definition.template,
    report: BorderPublicationGalleryReport(
      resolverVersion: resolverVersion,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: computeBorderPublicationCandidateFingerprint(
        blueprintId: blueprintId,
        definition: definition,
        resolverVersion: resolverVersion,
      ),
      samples: <BorderPublicationGallerySample>[
        for (final item in cases) item.publicationSample,
      ],
    ),
    cases: cases,
    resolutionDiagnostics: BorderDiagnosticsReport(diagnostics: diagnostics),
  );
}

BorderCanonicalGalleryResult _adaptOrganicGallery(
  OrganicEdgeCanonicalGalleryResult source,
) =>
    BorderCanonicalGalleryResult._(
      template: BorderBlueprintTemplate.organicEdge,
      report: source.report,
      cases: <BorderCanonicalGalleryCaseResult>[
        for (final item in source.cases)
          BorderCanonicalGalleryCaseResult._(
            galleryCase: item.galleryCase,
            mapSize: GridSize(
              width: item.geometry.width,
              height: item.geometry.height,
            ),
            geometry: item.geometry,
            resolverResult: item.resolverEvidence.result,
            publicationSample: item.publicationSample,
          ),
      ],
      resolutionDiagnostics: source.resolutionDiagnostics,
    );

BorderResolutionRequest _request({
  required GridSize mapSize,
  required GridSize tileSizePx,
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required int resolverVersion,
  required String caseWire,
  required BorderFeatureGeometry geometry,
  BorderLineSide lineSide = BorderLineSide.primary,
}) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: tileSizePx,
      blueprintId: blueprintId,
      blueprintRevision: blueprintRevision,
      feature: BorderFeature(
        id: 'border-gallery-v1:$caseWire',
        name: caseWire,
        blueprintId: blueprintId,
        seed: blueprintRevision.definition.previewSeed,
        geometry: geometry,
        lineSide: lineSide,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );

BorderStrokeGeometry _masonryGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: <GridPos>[
                for (var x = 2; x <= 9; x += 1) GridPos(x: x, y: 5),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.sharpCorner => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
                GridPos(x: 4, y: 2),
                GridPos(x: 5, y: 2),
                GridPos(x: 5, y: 3),
                GridPos(x: 5, y: 4),
                GridPos(x: 5, y: 5),
                GridPos(x: 5, y: 6),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.endpoint => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 6, y: 4),
                GridPos(x: 7, y: 4),
              ],
              closed: false,
            ),
          ],
        ),
      _ => throw const ValidationException(
          'Organic or fence-only case is not valid in the masonry gallery',
        ),
    };

BorderStrokeGeometry _fenceGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: <GridPos>[
                for (var x = 2; x <= 9; x += 1) GridPos(x: x, y: 5),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.sharpCorner => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
                GridPos(x: 4, y: 2),
                GridPos(x: 5, y: 2),
                GridPos(x: 5, y: 3),
                GridPos(x: 5, y: 4),
                GridPos(x: 5, y: 5),
                GridPos(x: 5, y: 6),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.endpoint => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'primary',
              points: const <GridPos>[
                GridPos(x: 4, y: 4),
                GridPos(x: 5, y: 4),
                GridPos(x: 6, y: 4),
                GridPos(x: 7, y: 4),
              ],
              closed: false,
            ),
          ],
        ),
      BorderCanonicalGalleryCase.opening => BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'leading',
              points: const <GridPos>[
                GridPos(x: 1, y: 5),
                GridPos(x: 2, y: 5),
                GridPos(x: 3, y: 5),
                GridPos(x: 4, y: 5),
              ],
              closed: false,
            ),
            BorderStroke(
              id: 'trailing',
              points: const <GridPos>[
                GridPos(x: 7, y: 5),
                GridPos(x: 8, y: 5),
                GridPos(x: 9, y: 5),
                GridPos(x: 10, y: 5),
              ],
              closed: false,
            ),
          ],
        ),
      _ => throw const ValidationException(
          'Organic-only case is not valid in the fence gallery',
        ),
    };

BorderStrokeGeometry _connectedLineGeometryFor(
  BorderCanonicalGalleryCase galleryCase,
) {
  if (galleryCase != BorderCanonicalGalleryCase.sharpCorner) {
    return _fenceGeometryFor(galleryCase);
  }
  return BorderStrokeGeometry(
    strokes: <BorderStroke>[
      BorderStroke(
        id: 'leftTurn',
        points: const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
          GridPos(x: 4, y: 5),
        ],
        closed: false,
      ),
      BorderStroke(
        id: 'rightTurn',
        points: const <GridPos>[
          GridPos(x: 10, y: 4),
          GridPos(x: 10, y: 5),
          GridPos(x: 10, y: 6),
          GridPos(x: 10, y: 7),
          GridPos(x: 9, y: 7),
          GridPos(x: 8, y: 7),
          GridPos(x: 7, y: 7),
        ],
        closed: false,
      ),
    ],
  );
}

BorderPublicationCoverageCheck _masonryCoverageCheck(
  MasonryLineBorderResolutionEvidence evidence,
  BorderGenerationParams params,
) =>
    BorderPublicationCoverageCheck(
      component: BorderCanonicalCoverageComponent.primary,
      longestContiguousGapPx: _maximum(
        evidence.edges.map((edge) => edge.longestGapPx),
      ),
      maximumPairwiseOverlapPx: _maximum(
        evidence.edges.map((edge) => edge.maximumPairwiseOverlapPx),
      ),
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );

List<BorderPublicationCoverageCheck> _fenceCoverageChecks({
  required BorderCanonicalGalleryCase galleryCase,
  required PostAndRailLineBorderResolutionEvidence evidence,
  required BorderGenerationParams params,
}) {
  final edgesByStroke = <String, List<PostAndRailLineEdgeResolutionEvidence>>{};
  for (final edge in evidence.edges) {
    edgesByStroke
        .putIfAbsent(
            edge.strokeId, () => <PostAndRailLineEdgeResolutionEvidence>[])
        .add(edge);
  }
  final components = borderCanonicalCoverageComponentsForCase(
    template: BorderBlueprintTemplate.postAndRailLine,
    galleryCase: galleryCase,
  );
  return <BorderPublicationCoverageCheck>[
    for (final component in components)
      BorderPublicationCoverageCheck(
        component: component,
        longestContiguousGapPx: _maximum(
          _fenceEdgesForComponent(edgesByStroke, component)
              .map((edge) => edge.longestGapPx),
        ),
        maximumPairwiseOverlapPx: _maximum(
          _fenceEdgesForComponent(edgesByStroke, component)
              .map((edge) => edge.maximumPairwiseOverlapPx),
        ),
        gapTolerancePx: params.gapTolerancePx,
        maxOverlapPx: params.maxOverlapPx,
      ),
  ];
}

List<BorderPublicationCoverageCheck> _connectedLineCoverageChecks({
  required BorderCanonicalGalleryCase galleryCase,
  required BorderGenerationParams params,
  required BorderStrokeGeometry geometry,
  required BorderBlueprintPublishedDefinition definition,
  required BorderResolutionResult primary,
  required BorderResolutionResult inverted,
  required GridSize tileSizePx,
}) {
  final strokesById = <String, BorderStroke>{
    for (final stroke in geometry.strokes) stroke.id: stroke,
  };
  final primitivesById = <String, BorderPublishedPrimitive>{
    for (final primitive in definition.primitives) primitive.id: primitive,
  };
  return <BorderPublicationCoverageCheck>[
    for (final component in borderCanonicalCoverageComponentsForCase(
      template: BorderBlueprintTemplate.connectedLine,
      galleryCase: galleryCase,
    ))
      _connectedLineCoverageCheck(
        component: component,
        strokes: switch (component) {
          BorderCanonicalCoverageComponent.leadingStroke => <BorderStroke>[
              strokesById['leading']!
            ],
          BorderCanonicalCoverageComponent.trailingStroke => <BorderStroke>[
              strokesById['trailing']!
            ],
          _ => geometry.strokes,
        },
        primary: primary,
        inverted: inverted,
        primitivesById: primitivesById,
        tileSizePx: tileSizePx,
        params: params,
      ),
  ];
}

BorderPublicationCoverageCheck _connectedLineCoverageCheck({
  required BorderCanonicalCoverageComponent component,
  required List<BorderStroke> strokes,
  required BorderResolutionResult primary,
  required BorderResolutionResult inverted,
  required Map<String, BorderPublishedPrimitive> primitivesById,
  required GridSize tileSizePx,
  required BorderGenerationParams params,
}) {
  final assessments = <({int gap, int overlap})>[
    for (final result in <BorderResolutionResult>[primary, inverted])
      for (final stroke in strokes)
        _connectedLineStrokeCoverage(
          stroke: stroke,
          result: result,
          primitivesById: primitivesById,
          tileSizePx: tileSizePx,
          params: params,
        ),
  ];
  return BorderPublicationCoverageCheck(
    component: component,
    longestContiguousGapPx: _maximum(
      assessments.map((assessment) => assessment.gap),
    ),
    maximumPairwiseOverlapPx: _maximum(
      assessments.map((assessment) => assessment.overlap),
    ),
    gapTolerancePx: params.gapTolerancePx,
    maxOverlapPx: params.maxOverlapPx,
  );
}

({int gap, int overlap}) _connectedLineStrokeCoverage({
  required BorderStroke stroke,
  required BorderResolutionResult result,
  required Map<String, BorderPublishedPrimitive> primitivesById,
  required GridSize tileSizePx,
  required BorderGenerationParams params,
}) {
  final strokeCells = stroke.points.toSet();
  final placements =
      (result.materialization?.placements ?? const <BorderResolvedPlacement>[])
          .where((placement) => strokeCells.contains(placement.anchorCell))
          .toList(growable: false);
  var longestGap = 0;
  var maximumOverlap = 0;
  final edgeCount =
      stroke.closed ? stroke.points.length : stroke.points.length - 1;
  for (var index = 0; index < edgeCount; index += 1) {
    final start = stroke.points[index];
    final end = stroke.points[(index + 1) % stroke.points.length];
    final horizontal = start.y == end.y;
    final startAxis = horizontal
        ? start.x * tileSizePx.width + tileSizePx.width ~/ 2
        : start.y * tileSizePx.height + tileSizePx.height ~/ 2;
    final endAxis = horizontal
        ? end.x * tileSizePx.width + tileSizePx.width ~/ 2
        : end.y * tileSizePx.height + tileSizePx.height ~/ 2;
    final targetStart = startAxis < endAxis ? startAxis : endAxis;
    final targetEnd = startAxis < endAxis ? endAxis : startAxis;
    final edgeLength = targetEnd - targetStart;
    final projections = <BorderStructuralCoverageProjection>[];
    for (final placement in placements) {
      final primitive = primitivesById[placement.primitiveId];
      if (primitive == null) continue;
      final clipped = <BorderCoverageInterval>[];
      for (final interval in projectBorderStructuralMaskOntoWorldAxis(
        metrics: primitive.publishedMetrics,
        transform: placement.transform,
        topLeftWorldPx: placement.topLeftWorldPx,
        worldXAxis: horizontal,
      )) {
        final clippedStart =
            interval.startPx > targetStart ? interval.startPx : targetStart;
        final clippedEnd =
            interval.endPx < targetEnd ? interval.endPx : targetEnd;
        if (clippedEnd > clippedStart) {
          clipped.add(
            BorderCoverageInterval(
              startPx: clippedStart - targetStart + 1,
              endPx: clippedEnd - targetStart + 1,
            ),
          );
        }
      }
      if (clipped.isNotEmpty) {
        projections.add(
          BorderStructuralCoverageProjection(
            placementId: placement.id,
            drawBand: placement.drawBand,
            passIndex: placement.stableOrderKey.passIndex,
            intervals: clipped,
          ),
        );
      }
    }
    final assessment = assessBorderLoopCoverage(
      perimeterPx: edgeLength + 2,
      targetIntervals: <BorderCoverageInterval>[
        BorderCoverageInterval(startPx: 1, endPx: edgeLength + 1),
      ],
      projections: projections,
      gapTolerancePx: params.gapTolerancePx,
      maxOverlapPx: params.maxOverlapPx,
    );
    if (assessment.longestContiguousGapPx > longestGap) {
      longestGap = assessment.longestContiguousGapPx;
    }
    if (assessment.maximumPairwiseOverlapPx > maximumOverlap) {
      maximumOverlap = assessment.maximumPairwiseOverlapPx;
    }
  }
  return (gap: longestGap, overlap: maximumOverlap);
}

List<PostAndRailLineEdgeResolutionEvidence> _fenceEdgesForComponent(
  Map<String, List<PostAndRailLineEdgeResolutionEvidence>> edgesByStroke,
  BorderCanonicalCoverageComponent component,
) =>
    edgesByStroke[switch (component) {
      BorderCanonicalCoverageComponent.leadingStroke => 'leading',
      BorderCanonicalCoverageComponent.trailingStroke => 'trailing',
      _ => 'primary',
    }] ??
    const <PostAndRailLineEdgeResolutionEvidence>[];

List<BorderPublicationStructuralRun> _structuralRuns({
  required String caseWire,
  String? idPrefix,
  required BorderResolutionResult result,
  required BorderBlueprintPublishedDefinition definition,
  required BorderStrokeGeometry geometry,
  required Set<BorderPrimitiveRole> acceptedRoles,
}) {
  final rolesByPrimitiveId = <String, BorderPrimitiveRole>{
    for (final primitive in definition.primitives) primitive.id: primitive.role,
  };
  final continuityByCell = _structuralContinuityByCell(geometry);
  final grouped =
      <(String, int, BorderPrimitiveRole, int, int), List<String>>{};
  for (final placement in result.materialization?.placements ??
      const <BorderResolvedPlacement>[]) {
    final role = rolesByPrimitiveId[placement.primitiveId];
    if (role == null || !acceptedRoles.contains(role)) continue;
    final continuity = continuityByCell[placement.anchorCell];
    if (continuity == null) {
      throw const ValidationException(
        'Canonical gallery structural placement must belong to one stroke',
      );
    }
    final nodeRole = role == BorderPrimitiveRole.post ||
        role == BorderPrimitiveRole.lineCap ||
        role == BorderPrimitiveRole.lineStraight ||
        role == BorderPrimitiveRole.lineCorner;
    final segment = nodeRole ? continuity.nodeSegment : continuity.edgeSegment;
    if (segment < 0) {
      throw const ValidationException(
        'Canonical gallery structural placement must belong to one '
        'continuous stroke segment',
      );
    }
    final key = (
      continuity.strokeId,
      segment,
      role,
      placement.transform.quarterTurns,
      placement.stableOrderKey.passIndex,
    );
    grouped.putIfAbsent(key, () => <String>[]).add(placement.primitiveId);
  }
  var index = 0;
  return <BorderPublicationStructuralRun>[
    for (final entry in grouped.entries)
      BorderPublicationStructuralRun(
        id: '${idPrefix ?? caseWire}:run:${index++}',
        role: entry.key.$3,
        quarterTurns: entry.key.$4,
        passIndex: entry.key.$5,
        primitiveIds: entry.value,
      ),
  ];
}

Map<GridPos, _StructuralContinuity> _structuralContinuityByCell(
  BorderStrokeGeometry geometry,
) {
  final result = <GridPos, _StructuralContinuity>{};
  for (final stroke in geometry.strokes) {
    final edgeQuarterTurns = <int>[
      for (var index = 0;
          index <
              (stroke.closed ? stroke.points.length : stroke.points.length - 1);
          index += 1)
        _quarterTurnsBetween(
          stroke.points[index],
          stroke.points[(index + 1) % stroke.points.length],
        ),
    ];
    final edgeSegments = _continuitySegments(
      edgeQuarterTurns,
      circular: stroke.closed,
    );
    final nodeQuarterTurns = <int>[
      for (var index = 0; index < stroke.points.length; index += 1)
        index < edgeQuarterTurns.length
            ? edgeQuarterTurns[index]
            : edgeQuarterTurns.last,
    ];
    final nodeSegments = _continuitySegments(
      nodeQuarterTurns,
      circular: stroke.closed,
    );
    for (var index = 0; index < stroke.points.length; index += 1) {
      result[stroke.points[index]] = _StructuralContinuity(
        strokeId: stroke.id,
        edgeSegment: index < edgeSegments.length ? edgeSegments[index] : -1,
        nodeSegment: nodeSegments[index],
      );
    }
  }
  return result;
}

List<int> _continuitySegments(
  List<int> quarterTurns, {
  required bool circular,
}) {
  final segments = List<int>.filled(quarterTurns.length, 0, growable: false);
  var segment = 0;
  for (var index = 1; index < quarterTurns.length; index += 1) {
    if (quarterTurns[index] != quarterTurns[index - 1]) segment += 1;
    segments[index] = segment;
  }
  if (circular &&
      segments.length > 1 &&
      quarterTurns.first == quarterTurns.last) {
    final wrappedSegment = segments.last;
    for (var index = 0; index < segments.length; index += 1) {
      if (segments[index] == wrappedSegment) segments[index] = 0;
    }
  }
  return segments;
}

int _quarterTurnsBetween(GridPos start, GridPos end) {
  final deltaX = BigInt.from(end.x) - BigInt.from(start.x);
  final deltaY = BigInt.from(end.y) - BigInt.from(start.y);
  if (deltaX == BigInt.one && deltaY == BigInt.zero) return 0;
  if (deltaX == BigInt.zero && deltaY == BigInt.one) return 1;
  if (deltaX == -BigInt.one && deltaY == BigInt.zero) return 2;
  if (deltaX == BigInt.zero && deltaY == -BigInt.one) return 3;
  throw const ValidationException(
    'Canonical gallery structural runs require unit-cardinal strokes',
  );
}

final class _StructuralContinuity {
  const _StructuralContinuity({
    required this.strokeId,
    required this.edgeSegment,
    required this.nodeSegment,
  });

  final String strokeId;
  final int edgeSegment;
  final int nodeSegment;
}

int _maximum(Iterable<int> values) {
  var maximum = 0;
  for (final value in values) {
    if (value > maximum) maximum = value;
  }
  return maximum;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
