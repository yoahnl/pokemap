import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_publication_readiness.dart';
import 'border_resolver.dart';
import 'border_region_contours.dart';
import 'organic_edge_border_resolver.dart';

const GridSize _organicGalleryMapSize = GridSize(width: 20, height: 16);

/// One canonical organic gallery and the real resolver trace behind it.
@immutable
final class OrganicEdgeCanonicalGalleryResult {
  OrganicEdgeCanonicalGalleryResult._({
    required this.report,
    required List<OrganicEdgeCanonicalGalleryCaseResult> cases,
    required this.resolutionDiagnostics,
  }) : _cases = List<OrganicEdgeCanonicalGalleryCaseResult>.unmodifiable(cases);

  final BorderPublicationGalleryReport report;
  final List<OrganicEdgeCanonicalGalleryCaseResult> _cases;
  final BorderDiagnosticsReport resolutionDiagnostics;

  List<OrganicEdgeCanonicalGalleryCaseResult> get cases => _cases;

  bool get allCasesResolved =>
      _cases.length ==
          borderCanonicalGalleryCasesForTemplate(
            BorderBlueprintTemplate.organicEdge,
          ).length &&
      _cases.every((item) => item.resolverEvidence.result.canApply);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganicEdgeCanonicalGalleryResult &&
          report == other.report &&
          _listEquals(_cases, other._cases) &&
          resolutionDiagnostics == other.resolutionDiagnostics;

  @override
  int get hashCode => Object.hash(
        report,
        Object.hashAll(_cases),
        resolutionDiagnostics,
      );
}

/// Geometry, solver result, and publication projection for one gallery case.
@immutable
final class OrganicEdgeCanonicalGalleryCaseResult {
  const OrganicEdgeCanonicalGalleryCaseResult._({
    required this.galleryCase,
    required this.geometry,
    required this.resolverEvidence,
    required this.publicationSample,
  });

  final BorderCanonicalGalleryCase galleryCase;
  final BorderRegionGeometry geometry;
  final OrganicEdgeBorderResolutionEvidence resolverEvidence;
  final BorderPublicationGallerySample publicationSample;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganicEdgeCanonicalGalleryCaseResult &&
          galleryCase == other.galleryCase &&
          geometry == other.geometry &&
          resolverEvidence == other.resolverEvidence &&
          publicationSample == other.publicationSample;

  @override
  int get hashCode => Object.hash(
        galleryCase,
        geometry,
        resolverEvidence,
        publicationSample,
      );
}

/// Resolves the immutable six-case organic publication gallery.
///
/// Every coverage scalar in [OrganicEdgeCanonicalGalleryResult.report] is a
/// direct projection of the assessment retained by
/// [resolveOrganicEdgeBorderWithEvidence]. Failed cases are retained with
/// their real diagnostics and never receive invented passing metrics.
OrganicEdgeCanonicalGalleryResult resolveOrganicEdgeCanonicalGallery({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  int resolverVersion = borderResolverVersion,
}) {
  if (blueprintRevision.definition.template !=
      BorderBlueprintTemplate.organicEdge) {
    throw const ValidationException(
      'Organic canonical gallery requires an organicEdge revision',
    );
  }
  final snapshots = visualSnapshots.toList(growable: false);
  final cases = <OrganicEdgeCanonicalGalleryCaseResult>[];
  final diagnostics = <BorderDiagnostic>[];
  for (final galleryCase in borderCanonicalGalleryCasesForTemplate(
    BorderBlueprintTemplate.organicEdge,
  )) {
    final geometry = _geometryFor(galleryCase);
    final caseWire = borderCanonicalGalleryCaseV1WireName(galleryCase);
    final request = BorderResolutionRequest(
      mapSize: _organicGalleryMapSize,
      tileSizePx: tileSizePx,
      blueprintId: blueprintId,
      blueprintRevision: blueprintRevision,
      feature: BorderFeature(
        id: 'border-gallery-v1:$caseWire',
        name: caseWire,
        blueprintId: blueprintId,
        seed: blueprintRevision.definition.previewSeed,
        geometry: geometry,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: snapshots,
      resolverVersion: resolverVersion,
    );
    final evidence = resolveOrganicEdgeBorderWithEvidence(request);
    diagnostics.addAll(evidence.result.diagnostics);
    final sample = BorderPublicationGallerySample(
      galleryCase: galleryCase,
      coverageChecks: _coverageChecks(galleryCase, evidence),
      structuralRuns: <BorderPublicationStructuralRun>[
        for (var runIndex = 0;
            runIndex < evidence.structuralRuns.length;
            runIndex += 1)
          _publicationRun(
            caseWire: caseWire,
            runIndex: runIndex,
            evidence: evidence.structuralRuns[runIndex],
          ),
      ],
    );
    cases.add(
      OrganicEdgeCanonicalGalleryCaseResult._(
        galleryCase: galleryCase,
        geometry: geometry,
        resolverEvidence: evidence,
        publicationSample: sample,
      ),
    );
  }

  return OrganicEdgeCanonicalGalleryResult._(
    report: BorderPublicationGalleryReport(
      resolverVersion: resolverVersion,
      canonicalGalleryVersion: borderCanonicalGalleryVersion,
      candidateFingerprint: computeBorderPublicationCandidateFingerprint(
        blueprintId: blueprintId,
        definition: blueprintRevision.definition,
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

List<BorderPublicationCoverageCheck> _coverageChecks(
  BorderCanonicalGalleryCase galleryCase,
  OrganicEdgeBorderResolutionEvidence evidence,
) {
  final checks = <BorderPublicationCoverageCheck>[
    for (final contour in evidence.contours)
      BorderPublicationCoverageCheck.fromLoopAssessment(
        component: galleryCase == BorderCanonicalGalleryCase.hole
            ? switch (contour.kind) {
                BorderRegionContourKind.landBoundary =>
                  BorderCanonicalCoverageComponent.outerLoop,
                BorderRegionContourKind.holeBoundary =>
                  BorderCanonicalCoverageComponent.innerLoop,
              }
            : BorderCanonicalCoverageComponent.primary,
        assessment: contour.coverage,
      ),
  ];
  checks.sort(
    (left, right) => _coverageComponentRank(left.component).compareTo(
      _coverageComponentRank(right.component),
    ),
  );
  return checks;
}

BorderPublicationStructuralRun _publicationRun({
  required String caseWire,
  required int runIndex,
  required OrganicEdgeStructuralRunEvidence evidence,
}) =>
    BorderPublicationStructuralRun(
      id: '$caseWire:run:$runIndex',
      role: evidence.role,
      quarterTurns: evidence.quarterTurns,
      passIndex: evidence.passIndex,
      primitiveIds: evidence.primitiveIds,
    );

BorderRegionGeometry _geometryFor(BorderCanonicalGalleryCase galleryCase) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => _region(
          (x, y) => x >= 3 && x <= 16 && y >= 6 && y <= 9,
        ),
      BorderCanonicalGalleryCase.gentleCurve => _region(
          (x, y) {
            if (y < 2 || y > 13) return false;
            const starts = <int>[8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3];
            return x >= starts[y - 2] && x <= 16;
          },
        ),
      BorderCanonicalGalleryCase.sharpConvexCorner => _region(
          (x, y) =>
              (x >= 4 && x <= 12 && y >= 3 && y <= 12) ||
              (x >= 13 && x <= 16 && y >= 8 && y <= 12),
        ),
      BorderCanonicalGalleryCase.sharpConcaveCorner => _region(
          (x, y) =>
              x >= 3 && x <= 16 && y >= 3 && y <= 12 && !(x >= 10 && y <= 7),
        ),
      BorderCanonicalGalleryCase.hole => _region(
          (x, y) =>
              x >= 3 &&
              x <= 16 &&
              y >= 2 &&
              y <= 13 &&
              !(x >= 8 && x <= 11 && y >= 6 && y <= 9),
        ),
      BorderCanonicalGalleryCase.smallIsland => _region(
          (x, y) => x >= 8 && x <= 10 && y >= 6 && y <= 8,
        ),
      BorderCanonicalGalleryCase.sharpCorner ||
      BorderCanonicalGalleryCase.endpoint ||
      BorderCanonicalGalleryCase.opening =>
        throw const ValidationException(
          'Line-only case is not valid in the organic gallery',
        ),
    };

BorderRegionGeometry _region(bool Function(int x, int y) isFilled) =>
    BorderRegionGeometry(
      width: _organicGalleryMapSize.width,
      height: _organicGalleryMapSize.height,
      cells: <bool>[
        for (var y = 0; y < _organicGalleryMapSize.height; y += 1)
          for (var x = 0; x < _organicGalleryMapSize.width; x += 1)
            isFilled(x, y),
      ],
    );

int _coverageComponentRank(BorderCanonicalCoverageComponent component) =>
    switch (component) {
      BorderCanonicalCoverageComponent.primary => 0,
      BorderCanonicalCoverageComponent.outerLoop => 1,
      BorderCanonicalCoverageComponent.innerLoop => 2,
      BorderCanonicalCoverageComponent.leadingStroke => 3,
      BorderCanonicalCoverageComponent.trailingStroke => 4,
    };

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
