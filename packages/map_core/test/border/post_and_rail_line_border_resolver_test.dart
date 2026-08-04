import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('resolvePostAndRailLineBorder', () {
    test('places native spans behind one native post at every stroke node', () {
      final request = PostAndRailLineFixture().request;

      final result = resolvePostAndRailLineBorder(request);

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final placements = result.materialization!.placements;
      final posts = placements
          .where((placement) => placement.primitiveId == 'post-a')
          .toList(growable: false);
      final spans = placements
          .where((placement) => placement.primitiveId == 'span-a')
          .toList(growable: false);
      expect(posts, hasLength(5));
      expect(spans, hasLength(4));
      expect(
        posts,
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'native post width', 8)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'native post height', 12)
              .having((placement) => placement.drawBand, 'post band',
                  BorderDrawBand.structure),
        ),
      );
      expect(
        spans,
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'native span width', 16)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'native span height', 6)
              .having((placement) => placement.drawBand, 'span band',
                  BorderDrawBand.outerAccent),
        ),
      );
      expect(
        placements.take(spans.length).map((placement) => placement.primitiveId),
        everyElement('span-a'),
      );
      expect(
        placements.map((placement) => placement.slotKey).toSet(),
        hasLength(placements.length),
      );
      for (var index = 1; index < placements.length; index += 1) {
        expect(
          placements[index - 1]
              .stableOrderKey
              .compareTo(placements[index].stableOrderKey),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('requires both post and span roles atomically', () {
      final onlyPost = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post-only',
              fingerprintCharacter: '1',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
          ],
        ).request,
      );
      final onlySpan = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'span-only',
              fingerprintCharacter: '2',
              role: BorderPrimitiveRole.span,
              width: 16,
              height: 6,
            ),
          ],
        ).request,
      );

      for (final result in <BorderResolutionResult>[onlyPost, onlySpan]) {
        expect(result.canApply, isFalse);
        expect(result.materialization, isNull);
      }
      expect(
        onlyPost.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.span_role_missing'),
      );
      expect(
        onlySpan.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.post_role_missing'),
      );
    });

    test('places one post at a corner and rotates both incident spans', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'corner',
              points: const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 2, y: 2),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final posts = result.materialization!.placements
          .where((placement) => placement.primitiveId == 'post-a')
          .toList(growable: false);
      final spans = result.materialization!.placements
          .where((placement) => placement.primitiveId == 'span-a')
          .toList(growable: false);
      expect(posts, hasLength(3));
      expect(
        posts.where(
          (placement) => placement.anchorCell == const GridPos(x: 2, y: 1),
        ),
        hasLength(1),
      );
      expect(
        spans.map((placement) => placement.transform.quarterTurns).toSet(),
        <int>{0, 1},
      );
    });

    test('retains deterministic edge evidence and exact fingerprints', () {
      final request = PostAndRailLineFixture().request;

      final first = resolvePostAndRailLineBorderWithEvidence(request);
      final second = resolvePostAndRailLineBorderWithEvidence(request);

      expect(first, second);
      expect(first.result.canApply, isTrue, reason: _diagnostics(first.result));
      expect(first.edges, hasLength(4));
      expect(
        first.edges,
        everyElement(
          isA<PostAndRailLineEdgeResolutionEvidence>()
              .having((edge) => edge.spanCount, 'span count', 1)
              .having((edge) => edge.uncoveredLengthPx, 'uncovered', 0)
              .having((edge) => edge.maximumPairwiseOverlapPx, 'overlap', 0),
        ),
      );
      final materialization = first.result.materialization!;
      expect(
        materialization.receipt.inputFingerprint,
        computeBorderAggregateInputFingerprint(
          resolverVersion: request.resolverVersion,
          blueprintRevision: request.blueprintRevision!.revision,
          components: materialization.receipt.components,
        ),
      );
      expect(
        materialization.receipt.outputFingerprint,
        computeBorderOutputFingerprint(
          ground: materialization.ground,
          placements: materialization.placements,
        ),
      );
    });

    test('is independent from primitive and snapshot input order', () {
      final normal = resolvePostAndRailLineBorder(
        PostAndRailLineFixture().request,
      );
      final reversed = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(reverseInputs: true).request,
      );

      expect(normal, reversed);
    });

    test('is active through the closed V1 resolver dispatch', () {
      final request = PostAndRailLineFixture().request;

      final direct = resolvePostAndRailLineBorder(request);
      final dispatched = resolveBorderFeature(request);

      expect(dispatched, direct);
      expect(dispatched.canApply, isTrue, reason: _diagnostics(dispatched));
    });

    test('places posts at endpoints, straight nodes, and corners', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'corner',
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

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final posts = _placementsForRole(result, 'post-a');
      expect(posts, hasLength(5));
      expect(
        posts.map((placement) => placement.anchorCell),
        containsAll(const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 2),
          GridPos(x: 3, y: 3),
        ]),
      );
    });

    test('rejects unavailable span orientation instead of rotating pixels', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
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
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '3',
              role: BorderPrimitiveRole.post,
            ),
            fencePrimitive(
              id: 'horizontal-span',
              fingerprintCharacter: '4',
              role: BorderPrimitiveRole.span,
              allowedQuarterTurns: const <int>[0, 2],
            ),
          ],
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        _codes(result),
        contains('border.resolution.orientation_unavailable'),
      );
    });

    test('keeps rotated vertical sprites at transformed native size', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'vertical',
              points: const <GridPos>[
                GridPos(x: 2, y: 1),
                GridPos(x: 2, y: 2),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final span = _placementsForRole(result, 'span-a').single;
      expect(
          span.transform, BorderSpriteTransform(quarterTurns: 1, flipX: false));
      expect(span.opaqueWorldBoundsPx.width, 6);
      expect(span.opaqueWorldBoundsPx.height, 16);
      expect(
        _placementsForRole(result, 'post-a'),
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'rotated native width', 12)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'rotated native height', 8),
        ),
      );
    });

    test('repeats narrow native spans without scale or crop', () {
      final evidence = resolvePostAndRailLineBorderWithEvidence(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '5',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'short-span',
              fingerprintCharacter: '6',
              role: BorderPrimitiveRole.span,
              width: 6,
              height: 4,
            ),
          ],
          parameters: fenceParameters(maxOverlapPx: 2),
        ).request,
      );
      final result = evidence.result;

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      final spans = _placementsForRole(result, 'short-span');
      expect(spans, hasLength(12));
      expect(
        evidence.edges,
        everyElement(
          isA<PostAndRailLineEdgeResolutionEvidence>()
              .having((edge) => edge.spanCount, 'span count', 3)
              .having((edge) => edge.uncoveredLengthPx, 'uncovered', 0)
              .having((edge) => edge.maximumPairwiseOverlapPx, 'overlap', 1),
        ),
      );
      expect(
        spans,
        everyElement(
          isA<BorderResolvedPlacement>()
              .having((placement) => placement.opaqueWorldBoundsPx.width,
                  'native width', 6)
              .having((placement) => placement.opaqueWorldBoundsPx.height,
                  'native height', 4),
        ),
      );
    });

    test('blocks an edge too short for any native span', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '7',
              role: BorderPrimitiveRole.post,
            ),
            fencePrimitive(
              id: 'too-wide',
              fingerprintCharacter: '8',
              role: BorderPrimitiveRole.span,
              width: 32,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(_codes(result), contains('border.resolution.span_too_short'));
    });

    test('falls back deterministically when the first eligible span cannot fit',
        () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '4',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'a-too-wide',
              fingerprintCharacter: '5',
              role: BorderPrimitiveRole.span,
              width: 32,
            ),
            fencePrimitive(
              id: 'b-fitting',
              fingerprintCharacter: '6',
              role: BorderPrimitiveRole.span,
              width: 16,
              height: 6,
            ),
          ],
          parameters: fenceParameters(variationPermille: 0),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(_placementsForRole(result, 'a-too-wide'), isEmpty);
      expect(_placementsForRole(result, 'b-fitting'), hasLength(4));
    });

    test('measures a real occupancy-mask gap instead of opaque bounds', () {
      final occupancy = <bool>[
        for (var index = 0; index < 16 * 6; index += 1) index % 16 != 8,
      ];
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '6',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'gapped-span',
              fingerprintCharacter: '7',
              role: BorderPrimitiveRole.span,
              width: 16,
              height: 6,
              occupancy: occupancy,
            ),
          ],
          parameters: fenceParameters(gapTolerancePx: 0),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(_codes(result), contains('border.resolution.coverage_gap'));
      expect(
          _codes(result), isNot(contains('border.resolution.span_too_short')));
    });

    test('accepts only the measured contiguous occupancy gap tolerance', () {
      final occupancy = <bool>[
        for (var index = 0; index < 16 * 6; index += 1) index % 16 != 8,
      ];
      final evidence = resolvePostAndRailLineBorderWithEvidence(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '8',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'gapped-span',
              fingerprintCharacter: '9',
              role: BorderPrimitiveRole.span,
              width: 16,
              height: 6,
              occupancy: occupancy,
            ),
          ],
          parameters: fenceParameters(gapTolerancePx: 1),
        ).request,
      );

      expect(evidence.result.canApply, isTrue,
          reason: _diagnostics(evidence.result));
      expect(
        evidence.edges,
        everyElement(
          isA<PostAndRailLineEdgeResolutionEvidence>()
              .having((edge) => edge.uncoveredLengthPx, 'uncovered', 1)
              .having(
                (edge) => edge.maximumPairwiseOverlapPx,
                'overlap',
                0,
              ),
        ),
      );
    });

    test('merges adjacent edge-boundary gaps on the whole stroke abscissa', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'joined-gaps',
              points: const <GridPos>[
                GridPos(x: 1, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 3, y: 3),
              ],
              closed: false,
            ),
          ],
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: 'a',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'short-span',
              fingerprintCharacter: 'b',
              role: BorderPrimitiveRole.span,
              width: 14,
              height: 6,
            ),
          ],
          parameters: fenceParameters(gapTolerancePx: 1),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      final gap = result.diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'border.resolution.coverage_gap',
      );
      expect(gap.scope, BorderDiagnosticScope.stroke);
      expect(gap.parameters['longestGapPx'], 2);
    });

    test('fuses the terminal and initial gaps across a closed-loop wrap', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'wrap-gap',
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
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: 'c',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'short-east-north',
              fingerprintCharacter: 'd',
              role: BorderPrimitiveRole.span,
              width: 14,
              height: 6,
              allowedQuarterTurns: const <int>[0, 3],
            ),
            fencePrimitive(
              id: 'full-south-west',
              fingerprintCharacter: 'e',
              role: BorderPrimitiveRole.span,
              width: 16,
              height: 6,
              allowedQuarterTurns: const <int>[1, 2],
            ),
          ],
          parameters: fenceParameters(gapTolerancePx: 1),
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      final gap = result.diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'border.resolution.coverage_gap',
      );
      expect(gap.scope, BorderDiagnosticScope.stroke);
      expect(gap.parameters['longestGapPx'], 2);
    });

    test('covers a canonical closed loop without duplicate corner posts', () {
      final evidence = resolvePostAndRailLineBorderWithEvidence(
        PostAndRailLineFixture(
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
        ).request,
      );

      expect(evidence.result.canApply, isTrue,
          reason: _diagnostics(evidence.result));
      expect(evidence.edges, hasLength(4));
      expect(_placementsForRole(evidence.result, 'span-a'), hasLength(4));
      expect(_placementsForRole(evidence.result, 'post-a'), hasLength(4));
      expect(
        _placementsForRole(evidence.result, 'post-a')
            .map((placement) => placement.anchorCell)
            .toSet(),
        hasLength(4),
      );
    });

    test('keeps placements on untouched local edges byte-for-byte stable', () {
      final before = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'stable',
              points: const <GridPos>[
                GridPos(x: 1, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 3, y: 3),
                GridPos(x: 4, y: 3),
                GridPos(x: 5, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );
      final after = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'stable',
              points: const <GridPos>[
                GridPos(x: 1, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 3, y: 3),
                GridPos(x: 4, y: 3),
                GridPos(x: 5, y: 3),
                GridPos(x: 6, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(before.canApply, isTrue, reason: _diagnostics(before));
      expect(after.canApply, isTrue, reason: _diagnostics(after));
      final afterBySlot = <String, BorderResolvedPlacement>{
        for (final placement in after.materialization!.placements)
          placement.slotKey: placement,
      };
      final untouched = before.materialization!.placements.where(
        (placement) => placement.anchorCell.x <= 4,
      );
      expect(untouched, isNotEmpty);
      for (final placement in untouched) {
        expect(afterBySlot[placement.slotKey], placement);
      }
    });

    test('preserves a real opening between independent strokes', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'left',
              points: const <GridPos>[
                GridPos(x: 1, y: 3),
                GridPos(x: 2, y: 3),
              ],
              closed: false,
            ),
            BorderStroke(
              id: 'right',
              points: const <GridPos>[
                GridPos(x: 5, y: 3),
                GridPos(x: 6, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(_placementsForRole(result, 'span-a'), hasLength(2));
      expect(_placementsForRole(result, 'post-a'), hasLength(4));
      expect(
        result.materialization!.placements
            .map((placement) => placement.anchorCell.x),
        isNot(contains(anyOf(3, 4))),
      );
    });

    test('consumes optional accents and surface patches deterministically', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '9',
              role: BorderPrimitiveRole.post,
              width: 8,
              height: 12,
            ),
            fencePrimitive(
              id: 'span',
              fingerprintCharacter: 'a',
              role: BorderPrimitiveRole.span,
            ),
            fencePrimitive(
              id: 'accent',
              fingerprintCharacter: 'b',
              role: BorderPrimitiveRole.accent,
              width: 4,
              height: 4,
            ),
            fencePrimitive(
              id: 'patch',
              fingerprintCharacter: 'c',
              role: BorderPrimitiveRole.surfacePatch,
              width: 8,
              height: 4,
            ),
          ],
          parameters: fenceParameters(detailDensityPermille: 1000),
        ).request,
      );

      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(_placementsForRole(result, 'accent'), isNotEmpty);
      expect(
        _placementsForRole(result, 'accent'),
        everyElement(
          isA<BorderResolvedPlacement>().having(
            (placement) => placement.drawBand,
            'accent band',
            BorderDrawBand.accent,
          ),
        ),
      );
      expect(_placementsForRole(result, 'patch'), isNotEmpty);
      expect(
        _placementsForRole(result, 'patch'),
        everyElement(
          isA<BorderResolvedPlacement>().having(
            (placement) => placement.drawBand,
            'inner finish band',
            BorderDrawBand.innerFinish,
          ),
        ),
      );
    });

    test('rejects incompatible roles without returning partial output', () {
      final result = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: 'd',
              role: BorderPrimitiveRole.post,
            ),
            fencePrimitive(
              id: 'span',
              fingerprintCharacter: 'e',
              role: BorderPrimitiveRole.span,
            ),
            fencePrimitive(
              id: 'stone',
              fingerprintCharacter: 'f',
              role: BorderPrimitiveRole.structureLarge,
            ),
          ],
        ).request,
      );

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        _codes(result),
        contains('border.resolution.role_not_supported_by_template'),
      );
    });

    test('applies stable-slot suppression and keep-outs before diagnostics',
        () {
      final baseline = resolvePostAndRailLineBorder(
        PostAndRailLineFixture().request,
      );
      final target = baseline.materialization!.placements.first;
      final overrideResult = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          overrides: <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: target.slotKey,
              variationSalt: BorderSignedInt64.fromInt(0),
              suppressed: true,
              locked: false,
            ),
          ],
        ).request,
      );
      final keepOutResult = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(
              id: 'future-keep-out',
              region: BorderRegionGeometry(
                width: 10,
                height: 10,
                cells: <bool>[
                  for (var index = 0; index < 100; index += 1)
                    index == target.anchorCell.y * 10 + target.anchorCell.x,
                ],
              ),
            ),
          ],
        ).request,
      );

      for (final result in <BorderResolutionResult>[
        overrideResult,
        keepOutResult,
      ]) {
        expect(result.canApply, isTrue, reason: _diagnostics(result));
        expect(
            _codes(result), isNot(contains('border.resolution.coverage_gap')));
      }
      expect(
        overrideResult.materialization!.placements,
        baseline.materialization!.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
      expect(
        keepOutResult.materialization!.placements.length,
        lessThan(baseline.materialization!.placements.length),
      );
    });

    test('continues to reject Surface ground for a linear blueprint', () {
      final groundResult = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(ground: _unusedGround()).request,
      );

      expect(groundResult.canApply, isFalse);
      expect(groundResult.materialization, isNull);
      expect(
        _codes(groundResult),
        contains('border.resolution.linear_ground_not_supported'),
      );
    });

    test('validates anchors, occupancy RLE, and immutable snapshots', () {
      final invalidAnchor = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '0',
              role: BorderPrimitiveRole.post,
              anchorPx: const BorderPixelPos(x: 99, y: 99),
            ),
            fencePrimitive(
              id: 'span',
              fingerprintCharacter: '1',
              role: BorderPrimitiveRole.span,
            ),
          ],
        ).request,
      );
      final invalidRle = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '2',
              role: BorderPrimitiveRole.post,
            ),
            fencePrimitive(
              id: 'span',
              fingerprintCharacter: '3',
              role: BorderPrimitiveRole.span,
              occupancyMaskRle: 'not-rle',
            ),
          ],
        ).request,
      );
      final emptyOccupancy = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: <BorderPublishedPrimitive>[
            fencePrimitive(
              id: 'post',
              fingerprintCharacter: '6',
              role: BorderPrimitiveRole.post,
            ),
            fencePrimitive(
              id: 'span',
              fingerprintCharacter: '7',
              role: BorderPrimitiveRole.span,
              occupancy: List<bool>.filled(16 * 8, false),
            ),
          ],
        ).request,
      );
      final sourcePrimitives = <BorderPublishedPrimitive>[
        fencePrimitive(
          id: 'post',
          fingerprintCharacter: '4',
          role: BorderPrimitiveRole.post,
        ),
        fencePrimitive(
          id: 'span',
          fingerprintCharacter: '5',
          role: BorderPrimitiveRole.span,
        ),
      ];
      final missingSnapshot = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          primitives: sourcePrimitives,
          visualSnapshots: <BorderVisualSnapshot>[
            fenceSnapshotFor(sourcePrimitives.first),
          ],
        ).request,
      );

      expect(_codes(invalidAnchor),
          contains('border.resolution.anchor_outside_asset'));
      expect(invalidAnchor.materialization, isNull);
      expect(
          _codes(invalidRle), contains('border.resolution.occupancy_invalid'));
      expect(invalidRle.materialization, isNull);
      expect(
        _codes(emptyOccupancy),
        contains('border.resolution.occupancy_empty'),
      );
      expect(emptyOccupancy.materialization, isNull);
      expect(
        _codes(missingSnapshot),
        contains('border.resolution.visual_snapshot_invalid'),
      );
      expect(missingSnapshot.materialization, isNull);
    });

    test('validates published template, geometry, bounds, and canonical order',
        () {
      final unpublished = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(published: false).request,
      );
      final templateMismatch = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          template: BorderBlueprintTemplate.masonryLine,
        ).request,
      );
      final region = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          geometry: BorderRegionGeometry(
            width: 10,
            height: 10,
            cells: List<bool>.filled(100, false),
          ),
        ).request,
      );
      final outOfBounds = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'outside',
              points: const <GridPos>[
                GridPos(x: 9, y: 3),
                GridPos(x: 10, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );
      final nonCanonical = resolvePostAndRailLineBorder(
        PostAndRailLineFixture(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'reverse',
              points: const <GridPos>[
                GridPos(x: 3, y: 3),
                GridPos(x: 2, y: 3),
                GridPos(x: 1, y: 3),
              ],
              closed: false,
            ),
          ],
        ).request,
      );

      expect(_codes(unpublished),
          contains('border.resolution.blueprint_unavailable'));
      expect(_codes(templateMismatch),
          contains('border.resolution.template_mismatch'));
      expect(_codes(region),
          contains('border.resolution.stroke_geometry_required'));
      expect(_codes(outOfBounds),
          contains('border.resolution.stroke_out_of_bounds'));
      expect(_codes(nonCanonical),
          contains('border.resolution.stroke_not_canonical'));
      for (final result in <BorderResolutionResult>[
        unpublished,
        templateMismatch,
        region,
        outOfBounds,
        nonCanonical,
      ]) {
        expect(result.materialization, isNull);
      }
    });
  });
}

List<BorderResolvedPlacement> _placementsForRole(
  BorderResolutionResult result,
  String primitiveId,
) =>
    result.materialization!.placements
        .where((placement) => placement.primitiveId == primitiveId)
        .toList(growable: false);

Iterable<String> _codes(BorderResolutionResult result) =>
    result.diagnostics.map((diagnostic) => diagnostic.code);

String _diagnostics(BorderResolutionResult result) => result.diagnostics
    .map((diagnostic) => '${diagnostic.severity.name}:${diagnostic.code}')
    .join(', ');

BorderPublishedGround _unusedGround() => BorderPublishedGround(
      sourceSmartTilePresetId: 'unused-ground',
      edgeBandCells: 1,
      visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
        for (final role in standardBorderGroundVariantRoleOrder) role: 'unused',
      },
    );
