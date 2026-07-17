import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';

void main() {
  group('resolveMasonryLineBorder', () {
    test('uses resolver contract V2 for masonry output changes', () {
      expect(borderResolverVersion, 2);
    });

    test('resolves a long line deterministically at native size', () {
      final request = MasonryLineFixture().request;

      final first = resolveMasonryLineBorder(request);
      final second = resolveMasonryLineBorder(request);

      expect(first.canApply, isTrue, reason: _diagnostics(first));
      expect(first, second);
      expect(
        resolveMasonryLineBorderWithEvidence(request),
        resolveMasonryLineBorderWithEvidence(request),
      );
      expect(first.materialization!.ground, isEmpty);
      expect(first.materialization!.placements, isNotEmpty);
      expect(
        first.materialization!.placements,
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'native opaque width', 12)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'native opaque height', 10),
        ),
      );
      expect(
        first.materialization!.receipt.outputFingerprint,
        computeBorderOutputFingerprint(
          ground: first.materialization!.ground,
          placements: first.materialization!.placements,
        ),
      );
      expect(
        first.materialization!.receipt.inputFingerprint,
        computeBorderAggregateInputFingerprint(
          resolverVersion: request.resolverVersion,
          blueprintRevision: request.blueprintRevision!.revision,
          components: first.materialization!.receipt.components,
        ),
      );
      expect(
        first.materialization!.placements.map(
          (placement) => placement.transform.flipX,
        ),
        everyElement(isFalse),
      );
    });

    test('keeps the depth 1 legacy output fingerprint', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          parameters: masonryParameters(depthRows: 1),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(result.materialization!.placements, hasLength(8));
      expect(
        result.materialization!.receipt.outputFingerprint,
        'sha256:9c495903fcd6c88b35e80b055e10ae802ebc2e1d62307a67a0cf0b053aa80acd',
      );
    });

    test('keeps masonry sprites unrotated when automatic rotation is disabled',
        () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'vertical',
              points: const <GridPos>[
                GridPos(x: 3, y: 1),
                GridPos(x: 3, y: 2),
                GridPos(x: 3, y: 3),
                GridPos(x: 3, y: 4),
                GridPos(x: 3, y: 5),
                GridPos(x: 3, y: 6),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'upright-stone',
              fingerprintCharacter: 'e',
              allowedQuarterTurns: const <int>[0],
            ),
          ],
          parameters: masonryParameters(
            allowAutoRotation: false,
            maxOverlapPx: 0,
          ),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .where(
              (placement) => placement.drawBand == BorderDrawBand.structure,
            )
            .map((placement) => placement.transform.quarterTurns),
        everyElement(0),
      );
    });

    test('moves an asymmetric masonry body across the line when inverted', () {
      BorderResolutionResult resolveAt(BorderLineSide lineSide) =>
          resolveMasonryLineBorder(
            MasonryLineFixture(
              strokes: <BorderStroke>[
                BorderStroke(
                  id: 'short',
                  points: const <GridPos>[
                    GridPos(x: 1, y: 3),
                    GridPos(x: 2, y: 3),
                  ],
                  closed: false,
                ),
              ],
              primitives: <BorderPublishedPrimitive>[
                masonryPrimitive(
                  id: 'asymmetric-stone',
                  fingerprintCharacter: 'f',
                  width: 16,
                  height: 16,
                  anchorPx: const BorderPixelPos(x: 8, y: 12),
                  allowFlipX: true,
                ),
              ],
              parameters: masonryParameters(
                variationPermille: 0,
                maxOverlapPx: 0,
              ),
              lineSide: lineSide,
            ).request,
          );

      final primary = resolveAt(BorderLineSide.primary);
      final inverted = resolveAt(BorderLineSide.inverted);

      expect(primary.canApply, isTrue, reason: _diagnostics(primary));
      expect(inverted.canApply, isTrue, reason: _diagnostics(inverted));
      final primaryStone = primary.materialization!.placements.single;
      final invertedStone = inverted.materialization!.placements.single;
      expect(
        primaryStone.transform,
        BorderSpriteTransform(quarterTurns: 0, flipX: false),
      );
      expect(
        invertedStone.transform,
        BorderSpriteTransform(quarterTurns: 2, flipX: true),
      );
      expect(
        invertedStone.opaqueWorldBoundsPx.y,
        greaterThan(primaryStone.opaqueWorldBoundsPx.y),
      );
    });

    test(
        'adds a staggered medium rear row before the large front row at depth 2',
        () {
      MasonryLineBorderResolutionEvidence resolveAt(
        BorderLineSide lineSide,
      ) =>
          resolveMasonryLineBorderWithEvidence(
            MasonryLineFixture(
              primitives: <BorderPublishedPrimitive>[
                masonryPrimitive(
                  id: 'large-front',
                  fingerprintCharacter: '7',
                  width: 12,
                  height: 10,
                  allowFlipX: true,
                ),
                masonryPrimitive(
                  id: 'medium-rear',
                  fingerprintCharacter: '8',
                  role: BorderPrimitiveRole.structureMedium,
                  width: 10,
                  height: 8,
                  allowFlipX: true,
                ),
              ],
              parameters: masonryParameters(
                depthRows: 2,
                variationPermille: 0,
                maxOverlapPx: 2,
              ),
              lineSide: lineSide,
            ).request,
          );

      for (final lineSide in BorderLineSide.values) {
        final evidence = resolveAt(lineSide);
        final result = evidence.result;

        expect(result.canApply, isTrue, reason: _diagnostics(result));
        expect(
          evidence.edges,
          everyElement(
            isA<MasonryLineEdgeResolutionEvidence>()
                .having((edge) => edge.longestGapPx, 'longest gap', 0)
                .having(
                  (edge) => edge.maximumPairwiseOverlapPx,
                  'maximum overlap',
                  lessThanOrEqualTo(2),
                ),
          ),
        );
        final placements = result.materialization!.placements;
        final rear = placements
            .where(
              (placement) => placement.drawBand == BorderDrawBand.outerAccent,
            )
            .toList(growable: false);
        final front = placements
            .where(
              (placement) => placement.drawBand == BorderDrawBand.structure,
            )
            .toList(growable: false);
        expect(rear, isNotEmpty);
        expect(front, isNotEmpty);
        expect(rear.map((placement) => placement.primitiveId),
            everyElement('medium-rear'));
        expect(front.map((placement) => placement.primitiveId),
            everyElement('large-front'));
        expect(
          rear.map((placement) => placement.stableOrderKey.rank),
          everyElement(1),
        );
        expect(
          rear.map((placement) => placement.stableOrderKey.passIndex),
          everyElement(1),
        );
        expect(
          front.map((placement) => placement.stableOrderKey.rank),
          everyElement(0),
        );
        expect(
          placements.indexOf(rear.last),
          lessThan(placements.indexOf(front.first)),
        );

        final rearXs = rear
            .map((placement) => placement.opaqueWorldBoundsPx.x)
            .toList(growable: false)
          ..sort();
        final frontXs = front
            .map((placement) => placement.opaqueWorldBoundsPx.x)
            .toList(growable: false)
          ..sort();
        expect(
          rearXs.map(
            (x) => ((x - frontXs.first) % 10 + 10) % 10,
          ),
          everyElement(5),
        );
        expect(rearXs.toSet().intersection(frontXs.toSet()), isEmpty);

        final rearBounds = rear.first.opaqueWorldBoundsPx;
        final frontBounds = front.first.opaqueWorldBoundsPx;
        final rearCenterY = rearBounds.y + rearBounds.height ~/ 2;
        final frontCenterY = frontBounds.y + frontBounds.height ~/ 2;
        expect(
          rearCenterY - frontCenterY,
          lineSide == BorderLineSide.primary ? -6 : 6,
        );
        expect(
          rear.map((placement) => placement.transform),
          everyElement(
            lineSide == BorderLineSide.primary
                ? BorderSpriteTransform(quarterTurns: 0, flipX: false)
                : BorderSpriteTransform(quarterTurns: 2, flipX: true),
          ),
        );
      }
    });

    test('falls back to large stones for the rear row at depth 2', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'large-only',
              fingerprintCharacter: '9',
              width: 8,
              height: 8,
            ),
          ],
          parameters: masonryParameters(
            depthRows: 2,
            variationPermille: 0,
            maxOverlapPx: 0,
          ),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final rear = result.materialization!.placements.where(
        (placement) => placement.drawBand == BorderDrawBand.outerAccent,
      );
      expect(rear, isNotEmpty);
      expect(
        rear.map((placement) => placement.primitiveId),
        everyElement('large-only'),
      );
    });

    test('scales to a long stroke with deterministic bounded work', () {
      final points = <GridPos>[
        for (var x = 1; x <= 385; x += 1) GridPos(x: x, y: 3),
      ];
      final base = MasonryLineFixture(
        strokes: <BorderStroke>[
          BorderStroke(id: 'long', points: points, closed: false),
        ],
        primitives: <BorderPublishedPrimitive>[
          masonryPrimitive(
            id: 'long-stone',
            fingerprintCharacter: '0',
            width: 16,
          ),
        ],
        parameters: masonryParameters(maxOverlapPx: 0),
      ).request;
      final request = _copyRequest(
        base,
        mapSize: const GridSize(width: 387, height: 8),
      );

      final stopwatch = Stopwatch()..start();
      final first = resolveMasonryLineBorder(request);
      stopwatch.stop();
      final second = resolveMasonryLineBorder(request);

      expect(first.canApply, isTrue, reason: _diagnostics(first));
      expect(first, second);
      expect(
        first.materialization!.placements.where(
            (placement) => placement.drawBand == BorderDrawBand.structure),
        hasLength(384),
      );
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 8)),
        reason: 'A 384-edge stroke must not trigger per-candidate full '
            'coverage recomputation: ${stopwatch.elapsed}.',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('gates weighted variation proportionally at 0, 1, and 1000 permille',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'a-default',
          fingerprintCharacter: '1',
          width: 16,
          weight: 1,
        ),
        masonryPrimitive(
          id: 'z-variant',
          fingerprintCharacter: '2',
          width: 16,
          weight: 1000,
        ),
      ];
      BorderResolutionResult resolveAt(int variationPermille) =>
          resolveMasonryLineBorder(
            MasonryLineFixture(
              primitives: primitives,
              parameters: masonryParameters(
                variationPermille: variationPermille,
                maxOverlapPx: 0,
              ),
            ).request,
          );
      List<String> structuralIds(BorderResolutionResult result) => result
          .materialization!.placements
          .where((placement) => placement.drawBand == BorderDrawBand.structure)
          .map((placement) => placement.primitiveId)
          .toList(growable: false);

      final zero = resolveAt(0);
      final one = resolveAt(1);
      final full = resolveAt(1000);

      expect(zero.canApply, isTrue, reason: _diagnostics(zero));
      expect(one.canApply, isTrue, reason: _diagnostics(one));
      expect(full.canApply, isTrue, reason: _diagnostics(full));
      expect(structuralIds(zero), everyElement('a-default'));
      expect(structuralIds(one), structuralIds(zero));
      expect(structuralIds(full), contains('z-variant'));
      expect(resolveAt(0), zero);
      expect(resolveAt(1), one);
      expect(resolveAt(1000), full);
    });

    test('uses only explicitly allowed cardinal orientations at corners', () {
      final request = MasonryLineFixture(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'corner',
            points: const <GridPos>[
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 2, y: 2),
              GridPos(x: 2, y: 3),
            ],
            closed: false,
          ),
        ],
      ).request;

      final result = resolveMasonryLineBorder(request);

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.transform.quarterTurns)
            .toSet(),
        containsAll(<int>{0, 1}),
      );
    });

    test('rejects a missing orientation instead of inventing a rotation', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'vertical',
              points: const <GridPos>[
                GridPos(x: 2, y: 1),
                GridPos(x: 2, y: 2),
                GridPos(x: 2, y: 3),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'horizontal-only',
              fingerprintCharacter: 'c',
              allowedQuarterTurns: const <int>[0, 2],
            ),
          ],
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.orientation_unavailable'),
      );
    });

    test('is independent from primitive and snapshot input order', () {
      final normal = resolveMasonryLineBorder(MasonryLineFixture().request);
      final reversed = resolveMasonryLineBorder(
        MasonryLineFixture(reverseInputs: true).request,
      );

      expect(normal, reversed);
    });

    test('dispatches both line solvers without cross-template fallback', () {
      expect(
        resolveBorderFeature(MasonryLineFixture().request).canApply,
        isTrue,
      );
      final fence = resolveBorderFeature(
        MasonryLineFixture(
          template: BorderBlueprintTemplate.postAndRailLine,
        ).request,
      );
      expect(fence.canApply, isFalse);
      expect(
        fence.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.role_not_supported_by_template'),
      );
    });

    test('bounds irregular normal jitter without scaling native sprites', () {
      final strict = resolveMasonryLineBorder(
        MasonryLineFixture(
          parameters: masonryParameters(irregularityPermille: 0),
        ).request,
      ).materialization!;
      final irregular = resolveMasonryLineBorder(
        MasonryLineFixture(
          parameters: masonryParameters(irregularityPermille: 1000),
        ).request,
      ).materialization!;
      final strictBySlot = <String, BorderResolvedPlacement>{
        for (final placement in strict.placements) placement.slotKey: placement,
      };

      expect(irregular.placements.map((placement) => placement.slotKey),
          unorderedEquals(strictBySlot.keys));
      for (final placement in irregular.placements) {
        final baseline = strictBySlot[placement.slotKey]!;
        expect(placement.opaqueWorldBoundsPx.width,
            baseline.opaqueWorldBoundsPx.width);
        expect(placement.opaqueWorldBoundsPx.height,
            baseline.opaqueWorldBoundsPx.height);
        expect(
          (placement.topLeftWorldPx.y - baseline.topLeftWorldPx.y).abs(),
          lessThanOrEqualTo(4),
        );
      }
    });

    test('warns for unadorned ends and uses an adapted optional post', () {
      final unadorned = resolveMasonryLineBorder(
        MasonryLineFixture().request,
      );
      final adorned = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'stone',
              fingerprintCharacter: 'c',
            ),
            masonryPrimitive(
              id: 'post',
              fingerprintCharacter: 'd',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 14,
            ),
          ],
        ).request,
      );

      expect(unadorned.status, BorderResolutionStatus.warning);
      expect(
        unadorned.diagnostics
            .where((diagnostic) =>
                diagnostic.code ==
                'border.resolution.masonry_end_finish_missing')
            .length,
        2,
      );
      expect(adorned.canApply, isTrue, reason: _diagnostics(adorned));
      expect(
        adorned.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.masonry_end_finish_missing')),
      );
      expect(
        adorned.materialization!.placements
            .where((placement) => placement.primitiveId == 'post'),
        hasLength(2),
      );
    });

    test('orients directional end finishes outwards at opposite caps', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'stone',
              fingerprintCharacter: 'c',
            ),
            masonryPrimitive(
              id: 'directional-post',
              fingerprintCharacter: 'd',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 14,
              allowedQuarterTurns: const <int>[0, 2],
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .where((placement) => placement.primitiveId == 'directional-post')
            .map((placement) => placement.transform.quarterTurns),
        unorderedEquals(<int>[2, 0]),
      );
    });

    test('uses complementary large, medium, and filler structural passes', () {
      List<bool> stripe(int startX, int endX) => <bool>[
            for (var y = 0; y < 10; y += 1)
              for (var x = 0; x < 12; x += 1) x >= startX && x < endX,
          ];
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'large',
              fingerprintCharacter: 'c',
              occupancy: stripe(0, 4),
            ),
            masonryPrimitive(
              id: 'medium',
              fingerprintCharacter: 'd',
              role: BorderPrimitiveRole.structureMedium,
              occupancy: stripe(4, 8),
            ),
            masonryPrimitive(
              id: 'filler',
              fingerprintCharacter: 'e',
              role: BorderPrimitiveRole.filler,
              occupancy: stripe(8, 12),
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.primitiveId)
            .toSet(),
        containsAll(<String>{'large', 'medium', 'filler'}),
      );
    });

    test('allows one native block to overhang a short segment', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'short',
              points: const <GridPos>[
                GridPos(x: 2, y: 2),
                GridPos(x: 3, y: 2),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'wide-stone',
              fingerprintCharacter: 'e',
              width: 24,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(result.materialization!.placements, hasLength(1));
      expect(
        result.materialization!.placements.single.opaqueWorldBoundsPx.width,
        24,
      );
    });

    test('blocks a real occupancy gap without returning partial output', () {
      final occupancy = <bool>[
        for (var y = 0; y < 10; y += 1)
          for (var x = 0; x < 12; x += 1) x < 4 || x >= 8,
      ];
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'gapped-stone',
              fingerprintCharacter: 'f',
              occupancy: occupancy,
            ),
          ],
          parameters: masonryParameters(gapTolerancePx: 0),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.coverage_gap'),
      );
    });

    test('keeps pairwise structural overlap within the configured maximum', () {
      final request = MasonryLineFixture(
        parameters: masonryParameters(maxOverlapPx: 3),
      ).request;

      final evidence = resolveMasonryLineBorderWithEvidence(request);

      expect(evidence.result.canApply, isTrue,
          reason: _diagnostics(evidence.result));
      expect(evidence.edges, isNotEmpty);
      expect(
        evidence.edges.map((edge) => edge.maximumPairwiseOverlapPx),
        everyElement(lessThanOrEqualTo(3)),
      );
      expect(
        evidence.edges.map((edge) => edge.longestGapPx),
        everyElement(0),
      );
    });

    test('limits the full overlap across adjacent unit-edge junctions', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'two-edges',
              points: const <GridPos>[
                GridPos(x: 1, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 3, y: 3),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'wide-stone',
              fingerprintCharacter: 'f',
              width: 20,
            ),
          ],
          parameters: masonryParameters(maxOverlapPx: 2),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final structural = result.materialization!.placements
          .where((placement) => placement.primitiveId == 'wide-stone')
          .toList()
        ..sort((left, right) =>
            left.opaqueWorldBoundsPx.x.compareTo(right.opaqueWorldBoundsPx.x));
      expect(structural.length, greaterThanOrEqualTo(2));
      for (var index = 1; index < structural.length; index += 1) {
        final overlap = structural[index - 1].opaqueWorldBoundsPx.right -
            structural[index].opaqueWorldBoundsPx.x;
        expect(overlap, lessThanOrEqualTo(2));
      }
    });

    test('checks every same-pass pair with mixed sizes around corners', () {
      final stroke = BorderStroke(
        id: 'mixed-corners',
        points: <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 2),
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
        ],
        closed: false,
      );
      final lattice = buildBorderLinearLatticeV1(
        stroke: stroke,
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      var checkedMaterializations = 0;
      for (var seed = 0; seed < 64; seed += 1) {
        final result = resolveMasonryLineBorder(
          MasonryLineFixture(
            strokes: <BorderStroke>[stroke],
            primitives: <BorderPublishedPrimitive>[
              masonryPrimitive(
                id: 'a-wide',
                fingerprintCharacter: '1',
                width: 24,
              ),
              masonryPrimitive(
                id: 'b-tiny',
                fingerprintCharacter: '2',
                width: 4,
              ),
              masonryPrimitive(
                id: 'c-medium',
                fingerprintCharacter: '3',
                width: 14,
              ),
            ],
            parameters: masonryParameters(
              variationPermille: 1000,
              maxOverlapPx: 2,
              gapTolerancePx: 128,
            ),
            featureSeed: seed,
          ).request,
        );
        expect(result.canApply, isTrue, reason: _diagnostics(result));
        checkedMaterializations += 1;
        final intervals = <(int, int, String)>[
          for (final placement in result.materialization!.placements)
            if (placement.drawBand == BorderDrawBand.structure)
              _strokeIntervalForFullMask(
                placement: placement,
                lattice: lattice,
                tileSizePx: const GridSize(width: 16, height: 16),
              ),
        ];
        for (var first = 0; first < intervals.length; first += 1) {
          for (var second = first + 1; second < intervals.length; second += 1) {
            final overlap = _intervalOverlap(
              intervals[first].$1,
              intervals[first].$2,
              intervals[second].$1,
              intervals[second].$2,
            );
            expect(
              overlap,
              lessThanOrEqualTo(2),
              reason: 'seed=$seed pair=${intervals[first].$3}/'
                  '${intervals[second].$3}',
            );
          }
        }
      }
      expect(checkedMaterializations, 64);
    });

    test('merges the end and start gaps on a closed stroke domain', () {
      final insetOccupancy = <bool>[
        for (var y = 0; y < 16; y += 1)
          for (var x = 0; x < 16; x += 1) x > 0 && x < 15 && y > 0 && y < 15,
      ];
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'loop',
              points: const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 2, y: 2),
                GridPos(x: 1, y: 2),
              ],
              closed: true,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'inset-stone',
              fingerprintCharacter: '7',
              width: 16,
              height: 16,
              occupancy: insetOccupancy,
            ),
          ],
          parameters: masonryParameters(
            maxOverlapPx: 0,
            gapTolerancePx: 1,
          ),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics
            .where((diagnostic) =>
                diagnostic.code == 'border.resolution.coverage_gap')
            .map((diagnostic) => diagnostic.parameters['longestGapPx']),
        contains(greaterThan(1)),
      );
    });

    test('resolves a fully occupied closed loop across the wrap junction', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'solid-loop',
              points: const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 2, y: 2),
                GridPos(x: 1, y: 2),
              ],
              closed: true,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'solid-stone',
              fingerprintCharacter: '6',
              width: 16,
              height: 16,
            ),
          ],
          parameters: masonryParameters(
            maxOverlapPx: 0,
            gapTolerancePx: 0,
          ),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(result.materialization!.placements, isNotEmpty);
    });

    test('materializes surface patches only through the detail pass', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'stone',
              fingerprintCharacter: '8',
            ),
            masonryPrimitive(
              id: 'surface-patch',
              fingerprintCharacter: '9',
              role: BorderPrimitiveRole.surfacePatch,
              width: 5,
              height: 7,
            ),
          ],
          parameters: masonryParameters(detailDensityPermille: 1000),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final patches = result.materialization!.placements
          .where((placement) => placement.primitiveId == 'surface-patch');
      expect(patches, isNotEmpty);
      expect(
        patches,
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'native width', 5)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'native height', 7)
              .having((placement) => placement.drawBand, 'draw band',
                  BorderDrawBand.innerFinish),
        ),
      );
    });

    test('applies stable-slot suppression and keep-outs before final output',
        () {
      final baseline = resolveMasonryLineBorder(MasonryLineFixture().request);
      final target = baseline.materialization!.placements.first;
      final keepOut = BorderKeepOutRegion(
        id: 'opening',
        region: BorderRegionGeometry(
          width: 8,
          height: 8,
          cells: <bool>[
            for (var index = 0; index < 64; index += 1)
              index == target.anchorCell.y * 8 + target.anchorCell.x,
          ],
        ),
      );
      final overrideResult = resolveMasonryLineBorder(
        MasonryLineFixture(
          overrides: <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: target.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
          ],
        ).request,
      );
      final keepOutResult = resolveMasonryLineBorder(
        MasonryLineFixture(keepOutRegions: <BorderKeepOutRegion>[keepOut])
            .request,
      );

      expect(overrideResult.canApply, isTrue,
          reason: _diagnostics(overrideResult));
      expect(
        overrideResult.materialization!.placements,
        baseline.materialization!.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
      expect(
        overrideResult.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.coverage_gap')),
      );
      expect(keepOutResult.canApply, isTrue,
          reason: _diagnostics(keepOutResult));
      expect(
        keepOutResult.materialization!.placements.length,
        lessThan(baseline.materialization!.placements.length),
      );
      expect(
        keepOutResult.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.coverage_gap')),
      );
    });

    test('continues to reject Surface ground for a linear blueprint', () {
      final groundSnapshotId = masonrySnapshotId('9');
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          ground: BorderPublishedGround(
            sourceSurfacePresetId: 'ground',
            edgeBandCells: 1,
            visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
              for (final role in standardSurfaceVariantRoleOrder)
                role: groundSnapshotId,
            },
          ),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.linear_ground_not_supported'),
      );
    });

    test('uses a medium structure when large assets lack the orientation', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'large-vertical-only',
              fingerprintCharacter: '1',
              allowedQuarterTurns: const <int>[1, 3],
            ),
            masonryPrimitive(
              id: 'medium-horizontal',
              fingerprintCharacter: '2',
              role: BorderPrimitiveRole.structureMedium,
              allowedQuarterTurns: const <int>[0, 2],
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .where(
                (placement) => placement.drawBand == BorderDrawBand.structure)
            .map((placement) => placement.primitiveId)
            .toSet(),
        <String>{'medium-horizontal'},
      );
    });

    test('uses filler placements only when they close residual mask gaps', () {
      final gappedOccupancy = <bool>[
        for (var y = 0; y < 10; y += 1)
          for (var x = 0; x < 12; x += 1) x < 5 || x >= 9,
      ];
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'gapped-large',
              fingerprintCharacter: '3',
              occupancy: gappedOccupancy,
            ),
            masonryPrimitive(
              id: 'gap-filler',
              fingerprintCharacter: '4',
              role: BorderPrimitiveRole.filler,
              width: 4,
            ),
          ],
          parameters: masonryParameters(maxOverlapPx: 3),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.primitiveId),
        contains('gap-filler'),
      );
    });

    test('rejects a first parasite block with no target-domain contribution',
        () {
      final parasiteOccupancy = <bool>[
        for (var y = 0; y < 10; y += 1)
          for (var x = 0; x < 64; x += 1) x < 8,
      ];
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'short-with-parasite',
              points: const <GridPos>[
                GridPos(x: 2, y: 3),
                GridPos(x: 3, y: 3),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'a-parasite-large',
              fingerprintCharacter: 'a',
              width: 64,
              occupancy: parasiteOccupancy,
            ),
            masonryPrimitive(
              id: 'z-filler',
              fingerprintCharacter: 'b',
              role: BorderPrimitiveRole.filler,
              width: 16,
            ),
          ],
          parameters: masonryParameters(
            variationPermille: 0,
            maxOverlapPx: 0,
          ),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .map((placement) => placement.primitiveId),
        isNot(contains('a-parasite-large')),
      );
      expect(
        result.materialization!.placements
            .map((placement) => placement.primitiveId),
        contains('z-filler'),
      );
    });

    test('materializes surface patches only when detail density selects them',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'stone',
          fingerprintCharacter: '5',
        ),
        masonryPrimitive(
          id: 'moss',
          fingerprintCharacter: '6',
          role: BorderPrimitiveRole.surfacePatch,
          width: 6,
          height: 4,
        ),
      ];
      final empty = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: primitives,
          parameters: masonryParameters(detailDensityPermille: 0),
        ).request,
      );
      final dense = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: primitives,
          parameters: masonryParameters(detailDensityPermille: 1000),
        ).request,
      );

      expect(empty.canApply, isTrue, reason: _diagnostics(empty));
      expect(dense.canApply, isTrue, reason: _diagnostics(dense));
      expect(
        empty.materialization!.placements
            .where((placement) => placement.primitiveId == 'moss'),
        isEmpty,
      );
      expect(
        dense.materialization!.placements
            .where((placement) => placement.primitiveId == 'moss'),
        isNotEmpty,
      );
      expect(
        dense.materialization!.placements
            .where((placement) => placement.primitiveId == 'moss')
            .map((placement) => placement.drawBand),
        everyElement(BorderDrawBand.innerFinish),
      );
    });

    test('does not materialize an end finish wholly outside the canvas', () {
      final result = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'stone',
              fingerprintCharacter: '7',
            ),
            masonryPrimitive(
              id: 'bad-post',
              fingerprintCharacter: '8',
              role: BorderPrimitiveRole.post,
              width: 128,
              anchorPx: const BorderPixelPos(x: 127, y: 5),
              opaqueBounds: BorderPixelRect(
                x: 0,
                y: 0,
                width: 4,
                height: 10,
              ),
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.materialization!.placements
            .where((placement) => placement.primitiveId == 'bad-post'),
        isEmpty,
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.masonry_end_finish_outside_canvas'),
      );
    });

    test('packs adjacent straight edges once and validates both corner sides',
        () {
      final straight = resolveMasonryLineBorderWithEvidence(
        MasonryLineFixture().request,
      );
      final corner = resolveMasonryLineBorderWithEvidence(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'corner-joint',
              points: const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 3, y: 1),
                GridPos(x: 3, y: 2),
                GridPos(x: 3, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(straight.result.canApply, isTrue,
          reason: _diagnostics(straight.result));
      final structural = straight.result.materialization!.placements.where(
        (placement) => placement.drawBand == BorderDrawBand.structure,
      );
      expect(
        structural
            .map((placement) => '${placement.transform.quarterTurns}:'
                '${placement.topLeftWorldPx.x}:'
                '${placement.topLeftWorldPx.y}')
            .toSet()
            .length,
        structural.length,
      );
      expect(corner.result.canApply, isTrue,
          reason: _diagnostics(corner.result));
      expect(corner.edges, hasLength(4));
      expect(
        corner.edges.map((edge) => edge.longestGapPx),
        everyElement(0),
      );
      expect(
        corner.edges.map((edge) => edge.maximumPairwiseOverlapPx),
        everyElement(lessThanOrEqualTo(2)),
      );
    });

    test('rejects noncanonical strokes and incompatible masonry roles', () {
      final reversed = resolveMasonryLineBorder(
        MasonryLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'reversed',
              points: const <GridPos>[
                GridPos(x: 5, y: 3),
                GridPos(x: 4, y: 3),
                GridPos(x: 3, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );
      final incompatible = resolveMasonryLineBorder(
        MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[
            masonryPrimitive(
              id: 'stone',
              fingerprintCharacter: 'a',
            ),
            masonryPrimitive(
              id: 'rail',
              fingerprintCharacter: 'b',
              role: BorderPrimitiveRole.span,
            ),
          ],
        ).request,
      );

      expect(reversed.canApply, isFalse);
      expect(reversed.materialization, isNull);
      expect(
        reversed.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.stroke_not_canonical'),
      );
      expect(incompatible.canApply, isFalse);
      expect(incompatible.materialization, isNull);
      expect(
        incompatible.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.role_not_supported_by_template'),
      );
    });

    test('persists exact line slot keys and structured order keys', () {
      final request = MasonryLineFixture().request;
      final materialization =
          resolveMasonryLineBorder(request).materialization!;

      for (final placement in materialization.placements.where(
        (placement) => placement.drawBand == BorderDrawBand.structure,
      )) {
        final expectedSlot = buildBorderLineSlotKey(
          featureId: request.feature.id,
          strokeId: 'main',
          edgeStart: placement.anchorCell,
          edgeEnd: GridPos(
            x: placement.anchorCell.x + 1,
            y: placement.anchorCell.y,
          ),
          passIndex: placement.stableOrderKey.passIndex,
          role: BorderPrimitiveRole.structureLarge,
          rank: placement.stableOrderKey.rank,
          ordinalLocal: placement.stableOrderKey.ordinalLocal,
        );
        expect(placement.slotKey, expectedSlot);
        expect(
          placement.stableOrderKey,
          buildBorderStableOrderKey(
            drawBand: placement.drawBand,
            mapWidth: request.mapSize.width,
            anchorCell: placement.anchorCell,
            passIndex: placement.stableOrderKey.passIndex,
            rank: placement.stableOrderKey.rank,
            ordinalLocal: placement.stableOrderKey.ordinalLocal,
            slotKey: expectedSlot,
          ),
        );
      }
    });

    test('validates revision, geometry, bounds, anchors, RLE, and snapshots',
        () {
      final base = MasonryLineFixture().request;
      final invalidAnchorPrimitive = masonryPrimitive(
        id: 'invalid-anchor',
        fingerprintCharacter: 'c',
        anchorPx: const BorderPixelPos(x: 99, y: 5),
      );
      final validMetrics = masonryPrimitive(
        id: 'invalid-rle-source',
        fingerprintCharacter: 'd',
      ).publishedMetrics;
      final invalidRlePrimitive = BorderPublishedPrimitive(
        id: 'invalid-rle',
        sourceElementId: 'element-invalid-rle',
        visualSnapshotId: masonrySnapshotId('d'),
        role: BorderPrimitiveRole.structureLarge,
        weight: 1,
        anchorPx: validMetrics.defaultAnchorPx,
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: const <int>[0, 1, 2, 3],
        ),
        publishedMetrics: BorderPrimitiveAssetMetrics(
          assetFingerprint: validMetrics.assetFingerprint,
          pixelSize: validMetrics.pixelSize,
          opaqueBounds: validMetrics.opaqueBounds,
          defaultAnchorPx: validMetrics.defaultAnchorPx,
          occupancyMaskRle: 'not-rle',
        ),
      );
      final cases = <(BorderResolutionRequest, String)>[
        (
          _copyRequest(base, omitBlueprintRevision: true),
          'border.resolution.blueprint_unavailable',
        ),
        (
          _copyRequest(
            base,
            feature: _copyFeature(
              base.feature,
              geometry: BorderRegionGeometry(
                width: 8,
                height: 8,
                cells: List<bool>.filled(64, true),
              ),
            ),
          ),
          'border.resolution.stroke_geometry_required',
        ),
        (
          _copyRequest(
            base,
            feature: _copyFeature(
              base.feature,
              geometry: BorderStrokeGeometry(strokes: const <BorderStroke>[]),
            ),
          ),
          'border.resolution.stroke_geometry_empty',
        ),
        (
          _copyRequest(
            base,
            feature: _copyFeature(
              base.feature,
              geometry: BorderStrokeGeometry(
                strokes: <BorderStroke>[
                  BorderStroke(
                    id: 'outside',
                    points: const <GridPos>[
                      GridPos(x: 7, y: 2),
                      GridPos(x: 8, y: 2),
                    ],
                    closed: false,
                  ),
                ],
              ),
            ),
          ),
          'border.resolution.stroke_out_of_bounds',
        ),
        (
          MasonryLineFixture(
            primitives: <BorderPublishedPrimitive>[invalidAnchorPrimitive],
          ).request,
          'border.resolution.anchor_outside_asset',
        ),
        (
          MasonryLineFixture(
            primitives: <BorderPublishedPrimitive>[invalidRlePrimitive],
          ).request,
          'border.resolution.structural_occupancy_invalid',
        ),
        (
          _copyRequest(base, visualSnapshots: const <BorderVisualSnapshot>[]),
          'border.resolution.visual_snapshot_invalid',
        ),
      ];

      for (final entry in cases) {
        final result = resolveMasonryLineBorder(entry.$1);
        expect(result.canApply, isFalse, reason: entry.$2);
        expect(result.materialization, isNull, reason: entry.$2);
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.code),
          contains(entry.$2),
          reason: _diagnostics(result),
        );
      }
    });
  });
}

String _diagnostics(BorderResolutionResult result) => result.diagnostics
    .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
    .join('\n');

(int, int, String) _strokeIntervalForFullMask({
  required BorderResolvedPlacement placement,
  required BorderLinearStrokeLattice lattice,
  required GridSize tileSizePx,
}) {
  final edge = lattice.edges.firstWhere(
    (candidate) => candidate.startCell == placement.anchorCell,
  );
  final horizontal = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.west;
  final edgeStartWorldPx = horizontal
      ? edge.startCell.x * tileSizePx.width + tileSizePx.width ~/ 2
      : edge.startCell.y * tileSizePx.height + tileSizePx.height ~/ 2;
  final worldStart = horizontal
      ? placement.opaqueWorldBoundsPx.x
      : placement.opaqueWorldBoundsPx.y;
  final worldEnd = horizontal
      ? placement.opaqueWorldBoundsPx.right
      : placement.opaqueWorldBoundsPx.bottom;
  final forward = edge.direction == BorderCardinalDirection.east ||
      edge.direction == BorderCardinalDirection.south;
  final localStart =
      forward ? worldStart - edgeStartWorldPx : edgeStartWorldPx - worldEnd;
  final localEnd =
      forward ? worldEnd - edgeStartWorldPx : edgeStartWorldPx - worldStart;
  return (
    edge.startAbscissaPx + localStart,
    edge.startAbscissaPx + localEnd,
    placement.id,
  );
}

int _intervalOverlap(
    int firstStart, int firstEnd, int secondStart, int secondEnd) {
  final start = firstStart > secondStart ? firstStart : secondStart;
  final end = firstEnd < secondEnd ? firstEnd : secondEnd;
  return end > start ? end - start : 0;
}

BorderResolutionRequest _copyRequest(
  BorderResolutionRequest source, {
  GridSize? mapSize,
  BorderBlueprintRevision? blueprintRevision,
  bool omitBlueprintRevision = false,
  BorderFeature? feature,
  List<BorderVisualSnapshot>? visualSnapshots,
}) =>
    BorderResolutionRequest(
      mapSize: mapSize ?? source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: omitBlueprintRevision
          ? null
          : blueprintRevision ?? source.blueprintRevision,
      feature: feature ?? source.feature,
      visualSnapshots: visualSnapshots ?? source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderFeature _copyFeature(
  BorderFeature source, {
  required BorderFeatureGeometry geometry,
}) =>
    BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: geometry,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
    );
