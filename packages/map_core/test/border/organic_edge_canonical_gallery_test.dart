import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/organic_edge_reference_coast_fixture.dart';

void main() {
  group('resolveOrganicEdgeCanonicalGallery', () {
    test('resolves the exact six organic cases from real solver evidence', () {
      final fixture = OrganicEdgeReferenceCoastFixture();

      final gallery = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );

      expect(gallery.allCasesResolved, isTrue);
      expect(
        gallery.cases.map((item) => item.galleryCase),
        orderedEquals(const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.gentleCurve,
          BorderCanonicalGalleryCase.sharpConvexCorner,
          BorderCanonicalGalleryCase.sharpConcaveCorner,
          BorderCanonicalGalleryCase.hole,
          BorderCanonicalGalleryCase.smallIsland,
        ]),
      );
      expect(gallery.report.samples, hasLength(6));
      expect(
        gallery.cases.every((item) => item.resolverEvidence.result.canApply),
        isTrue,
      );

      for (var index = 0; index < gallery.cases.length; index += 1) {
        final caseResult = gallery.cases[index];
        final sample = gallery.report.samples[index];
        expect(sample, caseResult.publicationSample);
        expect(sample.galleryCase, caseResult.galleryCase);
        for (var contourIndex = 0;
            contourIndex < caseResult.resolverEvidence.contours.length;
            contourIndex += 1) {
          final contour = caseResult.resolverEvidence.contours[contourIndex];
          final expectedComponent =
              caseResult.galleryCase == BorderCanonicalGalleryCase.hole
                  ? contour.kind == BorderRegionContourKind.landBoundary
                      ? BorderCanonicalCoverageComponent.outerLoop
                      : BorderCanonicalCoverageComponent.innerLoop
                  : BorderCanonicalCoverageComponent.primary;
          final check = sample.coverageChecks.singleWhere(
            (item) => item.component == expectedComponent,
          );
          expect(check.longestContiguousGapPx,
              contour.coverage.longestContiguousGapPx);
          expect(check.maximumPairwiseOverlapPx,
              contour.coverage.maximumPairwiseOverlapPx);
          expect(check.gapTolerancePx, contour.coverage.gapTolerancePx);
          expect(check.maxOverlapPx, contour.coverage.maxOverlapPx);
        }
      }

      final hole = gallery.cases.singleWhere(
        (item) => item.galleryCase == BorderCanonicalGalleryCase.hole,
      );
      expect(
        hole.publicationSample.coverageChecks.map((item) => item.component),
        orderedEquals(const <BorderCanonicalCoverageComponent>[
          BorderCanonicalCoverageComponent.outerLoop,
          BorderCanonicalCoverageComponent.innerLoop,
        ]),
      );
    });

    test('is deterministic and independent from primitive and snapshot order',
        () {
      final fixture = OrganicEdgeReferenceCoastFixture();
      final reversed = OrganicEdgeReferenceCoastFixture(reverseInputs: true);

      final first = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );
      final second = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );
      final reordered = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: reversed.revision,
        visualSnapshots: reversed.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );

      expect(second, first);
      expect(reordered, first);
      expect(
        first.cases
            .expand((item) => item.publicationSample.structuralRuns)
            .expand((run) => run.primitiveIds)
            .every(
              fixture.primitives
                  .map((primitive) => primitive.id)
                  .toSet()
                  .contains,
            ),
        isTrue,
      );
    });

    test('retains real blocking gap evidence for insufficient assets', () {
      final fixture = OrganicEdgeReferenceCoastFixture(sparseStructure: true);

      final gallery = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );

      expect(gallery.allCasesResolved, isFalse);
      expect(
        gallery.report.samples
            .expand((sample) => sample.coverageChecks)
            .any((check) => check.hasExcessiveGap),
        isTrue,
      );
      expect(
        gallery.resolutionDiagnostics.diagnostics.map((item) => item.code),
        contains('border.resolution.coverage_gap'),
      );
    });
  });
}
