import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';
import '../fixtures/border/organic_edge_reference_coast_fixture.dart';
import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('resolveBorderCanonicalGallery', () {
    test('resolves the exact masonry cases from real line-solver evidence', () {
      final fixture = MasonryLineFixture();
      final request = fixture.request;

      final gallery = resolveBorderCanonicalGallery(
        blueprintId: request.blueprintId,
        blueprintRevision: request.blueprintRevision!,
        visualSnapshots: request.visualSnapshots,
        tileSizePx: request.tileSizePx,
      );

      expect(gallery.template, BorderBlueprintTemplate.masonryLine);
      expect(gallery.allCasesResolved, isTrue);
      expect(
        gallery.cases.map((item) => item.galleryCase),
        orderedEquals(const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
        ]),
      );
      expect(gallery.report.samples, hasLength(3));
      for (var index = 0; index < gallery.cases.length; index += 1) {
        final caseResult = gallery.cases[index];
        expect(caseResult.mapSize.width, greaterThan(0));
        expect(caseResult.mapSize.height, greaterThan(0));
        expect(caseResult.geometry, isA<BorderStrokeGeometry>());
        expect(caseResult.resolverResult.canApply, isTrue);
        expect(
          caseResult.publicationSample,
          gallery.report.samples[index],
        );

        final directEvidence = resolveMasonryLineBorderWithEvidence(
          _requestForCase(request, caseResult),
        );
        final check = caseResult.publicationSample.coverageChecks.single;
        expect(
          check.longestContiguousGapPx,
          directEvidence.edges.map((edge) => edge.longestGapPx).fold<int>(
              0, (maximum, value) => value > maximum ? value : maximum),
        );
        expect(
          check.maximumPairwiseOverlapPx,
          directEvidence.edges
              .map((edge) => edge.maximumPairwiseOverlapPx)
              .fold<int>(
                  0, (maximum, value) => value > maximum ? value : maximum),
        );
      }
    });

    test('keeps a fence opening as two independent canonical strokes', () {
      final fixture = PostAndRailLineFixture();
      final request = fixture.request;

      final gallery = resolveBorderCanonicalGallery(
        blueprintId: request.blueprintId,
        blueprintRevision: request.blueprintRevision!,
        visualSnapshots: request.visualSnapshots,
        tileSizePx: request.tileSizePx,
      );

      expect(gallery.template, BorderBlueprintTemplate.postAndRailLine);
      expect(gallery.allCasesResolved, isTrue);
      expect(
        gallery.cases.map((item) => item.galleryCase),
        orderedEquals(const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
          BorderCanonicalGalleryCase.opening,
        ]),
      );
      final opening = gallery.cases.last;
      final geometry = opening.geometry as BorderStrokeGeometry;
      expect(geometry.strokes, hasLength(2));
      expect(geometry.strokes.map((stroke) => stroke.id),
          orderedEquals(const <String>['leading', 'trailing']));
      expect(
        opening.publicationSample.coverageChecks
            .map((check) => check.component),
        orderedEquals(const <BorderCanonicalCoverageComponent>[
          BorderCanonicalCoverageComponent.leadingStroke,
          BorderCanonicalCoverageComponent.trailingStroke,
        ]),
      );

      for (final caseResult in gallery.cases) {
        final directEvidence = resolvePostAndRailLineBorderWithEvidence(
          _requestForCase(request, caseResult),
        );
        expect(caseResult.resolverResult, directEvidence.result);
        final edgesByStroke =
            <String, List<PostAndRailLineEdgeResolutionEvidence>>{};
        for (final edge in directEvidence.edges) {
          edgesByStroke.putIfAbsent(edge.strokeId, () => []).add(edge);
        }
        for (final check in caseResult.publicationSample.coverageChecks) {
          final strokeId = switch (check.component) {
            BorderCanonicalCoverageComponent.leadingStroke => 'leading',
            BorderCanonicalCoverageComponent.trailingStroke => 'trailing',
            _ => 'primary',
          };
          expect(
            check.longestContiguousGapPx,
            edgesByStroke[strokeId]!.map((edge) => edge.longestGapPx).fold<int>(
                0, (maximum, value) => value > maximum ? value : maximum),
          );
          expect(
            check.maximumPairwiseOverlapPx,
            edgesByStroke[strokeId]!
                .map((edge) => edge.maximumPairwiseOverlapPx)
                .fold<int>(
                    0, (maximum, value) => value > maximum ? value : maximum),
          );
        }
      }
    });

    test('keeps structural runs separated across a fence opening', () {
      final fixture = PostAndRailLineFixture(
        primitives: <BorderPublishedPrimitive>[
          fencePrimitive(
            id: 'post',
            fingerprintCharacter: 'a',
            role: BorderPrimitiveRole.post,
            width: 8,
            height: 12,
          ),
          fencePrimitive(
            id: 'span-primary',
            fingerprintCharacter: 'b',
            role: BorderPrimitiveRole.span,
            width: 16,
            height: 6,
          ),
          fencePrimitive(
            id: 'span-alternate',
            fingerprintCharacter: 'c',
            role: BorderPrimitiveRole.span,
            width: 16,
            height: 6,
          ),
        ],
        parameters: fenceParameters(variationPermille: 0),
      );

      final gallery = _galleryFor(fixture.request);
      final opening = gallery.report.samples.singleWhere(
        (sample) => sample.galleryCase == BorderCanonicalGalleryCase.opening,
      );
      final spanRuns = opening.structuralRuns
          .where((run) => run.role == BorderPrimitiveRole.span)
          .toList(growable: false);

      expect(spanRuns, hasLength(2));
      expect(
        spanRuns.map((run) => run.primitiveIds.length),
        orderedEquals(const <int>[3, 3]),
      );
      expect(
        spanRuns,
        everyElement(
          predicate<BorderPublicationStructuralRun>(
            (run) => _longestIdenticalPrimitiveRun(run.primitiveIds) < 4,
            'contains no four-placement repetition across the opening',
          ),
        ),
      );
    });

    test('resolves connected-line topology cases on both visual sides', () {
      final fixture = PostAndRailLineFixture(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          fencePrimitive(
            id: 'cap',
            fingerprintCharacter: 'a',
            role: BorderPrimitiveRole.lineCap,
            width: 16,
            height: 16,
            allowFlipX: true,
          ),
          fencePrimitive(
            id: 'straight',
            fingerprintCharacter: 'b',
            role: BorderPrimitiveRole.lineStraight,
            width: 16,
            height: 16,
            allowFlipX: true,
          ),
          fencePrimitive(
            id: 'corner',
            fingerprintCharacter: 'c',
            role: BorderPrimitiveRole.lineCorner,
            width: 16,
            height: 16,
            allowFlipX: true,
          ),
        ],
      );

      final gallery = _galleryFor(fixture.request);

      expect(gallery.template, BorderBlueprintTemplate.connectedLine);
      expect(gallery.allCasesResolved, isTrue);
      expect(
        gallery.cases.map((item) => item.galleryCase),
        orderedEquals(const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
          BorderCanonicalGalleryCase.opening,
        ]),
      );
      final sharpCorner = gallery.cases.singleWhere(
        (item) => item.galleryCase == BorderCanonicalGalleryCase.sharpCorner,
      );
      expect(
        (sharpCorner.geometry as BorderStrokeGeometry)
            .strokes
            .map((stroke) => stroke.id),
        orderedEquals(const <String>['leftTurn', 'rightTurn']),
      );
      expect(
        sharpCorner.resolverResult.materialization!.placements
            .where((placement) => placement.primitiveId == 'corner'),
        hasLength(2),
      );
      expect(
        sharpCorner.invertedResolverResult!.materialization!.placements
            .where((placement) => placement.primitiveId == 'corner'),
        hasLength(2),
      );
      for (final caseResult in gallery.cases) {
        expect(caseResult.resolverResult.canApply, isTrue);
        expect(caseResult.invertedResolverResult, isNotNull);
        expect(caseResult.invertedResolverResult!.canApply, isTrue);
        expect(
          caseResult.resolverResult.materialization!.placements
              .map((placement) => placement.transform.flipX),
          everyElement(isFalse),
        );
        expect(
          caseResult.invertedResolverResult!.materialization!.placements
              .map((placement) => placement.transform.flipX),
          everyElement(isTrue),
        );
        final sample = caseResult.publicationSample;
        expect(
          sample.structuralRuns.map((run) => run.id),
          anyElement(startsWith('primary:')),
        );
        expect(
          sample.structuralRuns.map((run) => run.id),
          anyElement(startsWith('inverted:')),
        );
      }
    });

    test('measures connected-line gaps and overlaps from real placements', () {
      PostAndRailLineFixture connectedFixture(int size, String suffix) =>
          PostAndRailLineFixture(
            template: BorderBlueprintTemplate.connectedLine,
            primitives: <BorderPublishedPrimitive>[
              fencePrimitive(
                id: 'cap-$suffix',
                fingerprintCharacter: 'a',
                role: BorderPrimitiveRole.lineCap,
                width: size,
                height: size,
                allowFlipX: true,
              ),
              fencePrimitive(
                id: 'straight-$suffix',
                fingerprintCharacter: 'b',
                role: BorderPrimitiveRole.lineStraight,
                width: size,
                height: size,
                allowFlipX: true,
              ),
              fencePrimitive(
                id: 'corner-$suffix',
                fingerprintCharacter: 'c',
                role: BorderPrimitiveRole.lineCorner,
                width: size,
                height: size,
                allowFlipX: true,
              ),
            ],
          );

      BorderPublicationCoverageCheck longEdgeCheck(
        PostAndRailLineFixture fixture,
      ) =>
          _galleryFor(fixture.request)
              .report
              .samples
              .singleWhere(
                (sample) =>
                    sample.galleryCase == BorderCanonicalGalleryCase.longEdge,
              )
              .coverageChecks
              .single;

      final narrow = longEdgeCheck(connectedFixture(4, 'narrow'));
      final wide = longEdgeCheck(connectedFixture(24, 'wide'));

      expect(narrow.longestContiguousGapPx, 13);
      expect(narrow.maximumPairwiseOverlapPx, 0);
      expect(wide.longestContiguousGapPx, 0);
      expect(wide.maximumPairwiseOverlapPx, 8);
    });

    test('adapts the existing organic gallery without changing its API', () {
      final fixture = OrganicEdgeReferenceCoastFixture();

      final legacy = resolveOrganicEdgeCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );
      final generic = resolveBorderCanonicalGallery(
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: fixture.revision,
        visualSnapshots: fixture.snapshots,
        tileSizePx: organicEdgeReferenceTileSizePx,
      );

      expect(generic.template, BorderBlueprintTemplate.organicEdge);
      expect(generic.report, legacy.report);
      expect(generic.resolutionDiagnostics, legacy.resolutionDiagnostics);
      expect(generic.allCasesResolved, legacy.allCasesResolved);
      expect(generic.cases, hasLength(legacy.cases.length));
      for (var index = 0; index < generic.cases.length; index += 1) {
        final adapted = generic.cases[index];
        final source = legacy.cases[index];
        expect(adapted.galleryCase, source.galleryCase);
        expect(
            adapted.mapSize,
            GridSize(
                width: source.geometry.width, height: source.geometry.height));
        expect(adapted.geometry, source.geometry);
        expect(adapted.resolverResult, source.resolverEvidence.result);
        expect(adapted.publicationSample, source.publicationSample);
      }
    });

    test('is deterministic and independent from line input ordering', () {
      for (final pair in <(BorderResolutionRequest, BorderResolutionRequest)>[
        (
          MasonryLineFixture().request,
          MasonryLineFixture(reverseInputs: true).request
        ),
        (
          PostAndRailLineFixture().request,
          PostAndRailLineFixture(reverseInputs: true).request,
        ),
      ]) {
        final (source, reordered) = pair;
        final first = _galleryFor(source);
        final repeated = _galleryFor(source);
        final reorderedGallery = _galleryFor(reordered);

        expect(repeated, first);
        expect(reorderedGallery, first);
        expect(reorderedGallery.hashCode, first.hashCode);
        expect(
          () => first.cases.add(first.cases.first),
          throwsUnsupportedError,
        );
      }
    });

    test('retains deterministic blocking diagnostics from the real solver', () {
      final fixture = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[
          masonryPrimitive(
            id: 'east-only',
            fingerprintCharacter: 'f',
            allowedQuarterTurns: const <int>[0],
          ),
        ],
      );

      final gallery = _galleryFor(fixture.request);

      expect(gallery.allCasesResolved, isFalse);
      expect(gallery.report.samples, hasLength(3));
      expect(
        gallery.cases
            .singleWhere(
              (item) =>
                  item.galleryCase == BorderCanonicalGalleryCase.sharpCorner,
            )
            .resolverResult
            .canApply,
        isFalse,
      );
      expect(
        gallery.resolutionDiagnostics.diagnostics.map((item) => item.code),
        contains('border.resolution.orientation_unavailable'),
      );
      expect(_galleryFor(fixture.request), gallery);
    });
  });
}

BorderCanonicalGalleryResult _galleryFor(BorderResolutionRequest request) =>
    resolveBorderCanonicalGallery(
      blueprintId: request.blueprintId,
      blueprintRevision: request.blueprintRevision!,
      visualSnapshots: request.visualSnapshots,
      tileSizePx: request.tileSizePx,
      resolverVersion: request.resolverVersion,
    );

BorderResolutionRequest _requestForCase(
  BorderResolutionRequest source,
  BorderCanonicalGalleryCaseResult caseResult,
) =>
    BorderResolutionRequest(
      mapSize: caseResult.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: 'border-gallery-v1:${borderCanonicalGalleryCaseV1WireName(caseResult.galleryCase)}',
        name: borderCanonicalGalleryCaseV1WireName(caseResult.galleryCase),
        blueprintId: source.blueprintId,
        seed: source.blueprintRevision!.definition.previewSeed,
        geometry: caseResult.geometry,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: borderResolverVersion,
    );

int _longestIdenticalPrimitiveRun(List<String> primitiveIds) {
  var longest = 0;
  var current = 0;
  String? previous;
  for (final primitiveId in primitiveIds) {
    if (primitiveId == previous) {
      current += 1;
    } else {
      previous = primitiveId;
      current = 1;
    }
    if (current > longest) longest = current;
  }
  return longest;
}
