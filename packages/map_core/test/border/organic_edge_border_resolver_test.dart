import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveOrganicEdgeBorder', () {
    test('exposes exact deterministic coverage evidence from the resolver', () {
      final request = _request(singlePrimitive: true);

      final evidence = resolveOrganicEdgeBorderWithEvidence(request);

      expect(evidence.result, resolveOrganicEdgeBorder(request));
      expect(evidence.contours, hasLength(1));
      expect(evidence.contours.single.contourIndex, 0);
      expect(
        evidence.contours.single.kind,
        BorderRegionContourKind.landBoundary,
      );
      expect(evidence.contours.single.coverage.hasExcessiveGap, isFalse);
      expect(evidence.contours.single.coverage.longestContiguousGapPx, 0);
      expect(evidence.structuralRuns, isNotEmpty);
      expect(
        evidence.structuralRuns.expand((run) => run.primitiveIds).toSet(),
        <String>{'rock-a'},
      );
      expect(
        resolveOrganicEdgeBorderWithEvidence(request),
        evidence,
      );
    });

    test('materializes a canonical region deterministically', () {
      final request = _request();

      final first = resolveOrganicEdgeBorder(request);
      final second = resolveOrganicEdgeBorder(request);

      expect(first.status, isNot(BorderResolutionStatus.error));
      expect(first.canApply, isTrue);
      expect(first, second);
      final materialization = first.materialization!;
      expect(materialization.placements, isNotEmpty);
      expect(
        materialization.placements,
        orderedEquals(
          materialization.placements.toList()
            ..sort(
              (left, right) => left.stableOrderKey.compareTo(
                right.stableOrderKey,
              ),
            ),
        ),
      );
      expect(
        materialization.receipt.outputFingerprint,
        computeBorderOutputFingerprint(
          ground: materialization.ground,
          placements: materialization.placements,
        ),
      );
      expect(
        materialization.receipt.inputFingerprint,
        computeBorderAggregateInputFingerprint(
          resolverVersion: request.resolverVersion,
          blueprintRevision: request.blueprintRevision!.revision,
          components: materialization.receipt.components,
        ),
      );
    });

    test('is independent from primitive and snapshot input order', () {
      final first = resolveOrganicEdgeBorder(_request());
      final second = resolveOrganicEdgeBorder(
        _request(
          reversePrimitives: true,
          reverseSnapshots: true,
        ),
      );

      expect(first, second);
    });

    test('resolves canonical long, curved, concave, hole, and island cases',
        () {
      final cases = <String, BorderRegionGeometry>{
        'long-edge': _regionFromCoordinates(<(int, int)>[
          (1, 2),
          (2, 2),
          (3, 2),
        ]),
        'gentle-curve': _regionFromCoordinates(<(int, int)>[
          (1, 1),
          (2, 1),
          (2, 2),
          (3, 2),
        ]),
        'concave-corner': _regionFromCoordinates(<(int, int)>[
          (1, 1),
          (2, 1),
          (3, 1),
          (1, 2),
          (1, 3),
        ]),
        'hole': _regionFromCoordinates(<(int, int)>[
          (1, 1),
          (2, 1),
          (3, 1),
          (1, 2),
          (3, 2),
          (1, 3),
          (2, 3),
          (3, 3),
        ]),
        'small-island': _regionFromCoordinates(<(int, int)>[(2, 2)]),
      };

      for (final entry in cases.entries) {
        final first = resolveOrganicEdgeBorder(
          _request(region: entry.value, singlePrimitive: true),
        );
        final second = resolveOrganicEdgeBorder(
          _request(region: entry.value, singlePrimitive: true),
        );
        expect(first.canApply, isTrue, reason: entry.key);
        expect(first, second, reason: entry.key);
      }
    });

    test('materializes only the interior shoreline of a map-edge region', () {
      final result = resolveOrganicEdgeBorder(
        _request(
          region: _lowerHalfRegion(),
          singlePrimitive: true,
        ),
      );

      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      expect(result.materialization!.placements, isNotEmpty);
      expect(
        result.materialization!.placements
            .every((placement) => placement.anchorCell.y == 2),
        isTrue,
      );
    });

    test('keeps distant existing slots byte-for-byte stable', () {
      final before = resolveOrganicEdgeBorder(
        _request(region: _centerRegion(), singlePrimitive: true),
      ).materialization!;
      final after = resolveOrganicEdgeBorder(
        _request(
          region: _centerWithDistantIsland(),
          singlePrimitive: true,
        ),
      ).materialization!;
      final afterBySlot = <String, BorderResolvedPlacement>{
        for (final placement in after.placements) placement.slotKey: placement,
      };

      for (final placement in before.placements) {
        expect(afterBySlot[placement.slotKey], placement);
      }
      expect(after.placements.length, greaterThan(before.placements.length));
    });

    test('uses local seed variation without changing repeatability', () {
      final outputs = <String>{};
      for (var seed = 0; seed < 32; seed += 1) {
        final result = resolveOrganicEdgeBorder(
          _request(
            seed: seed,
            params: _params(variationPermille: 1000),
          ),
        );
        expect(result.canApply, isTrue);
        outputs.add(
          result.materialization!.placements
              .where(
                (placement) => placement.drawBand == BorderDrawBand.structure,
              )
              .map((placement) => placement.primitiveId)
              .join(','),
        );
      }

      expect(outputs.length, greaterThan(1));
      expect(
        resolveOrganicEdgeBorder(_request(seed: 7)),
        resolveOrganicEdgeBorder(_request(seed: 7)),
      );
    });

    test('bounds wild jitter and keeps logical anchors in the map', () {
      final strict = resolveOrganicEdgeBorder(
        _request(params: _params(irregularityPermille: 0)),
      ).materialization!;
      final wild = resolveOrganicEdgeBorder(
        _request(params: _params(irregularityPermille: 1000)),
      ).materialization!;
      final strictBySlot = <String, BorderResolvedPlacement>{
        for (final placement in strict.placements) placement.slotKey: placement,
      };

      for (final placement in wild.placements) {
        final baseline = strictBySlot[placement.slotKey]!;
        expect(
          (placement.topLeftWorldPx.x - baseline.topLeftWorldPx.x).abs(),
          lessThanOrEqualTo(4),
        );
        expect(
          (placement.topLeftWorldPx.y - baseline.topLeftWorldPx.y).abs(),
          lessThanOrEqualTo(4),
        );
        expect(placement.anchorCell.x, inInclusiveRange(0, 4));
        expect(placement.anchorCell.y, inInclusiveRange(0, 4));
      }
      expect(
        computeOrganicEdgeBorderDirtyHaloRadiusPx(
          _request(params: _params(irregularityPermille: 1000)),
        ),
        36,
      );
    });

    test('lets structure cross the region boundary and canvas edge', () {
      final result = resolveOrganicEdgeBorder(
        _request(region: _cornerRegion()),
      );

      expect(result.canApply, isTrue);
      expect(
        result.materialization!.placements,
        contains(
          isA<BorderResolvedPlacement>().having(
            (placement) =>
                placement.opaqueWorldBoundsPx.x < 0 ||
                placement.opaqueWorldBoundsPx.y < 0,
            'partially leaves the canvas',
            isTrue,
          ),
        ),
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.orientation_unavailable')),
      );
    });

    test('removes keep-out cells from ground, props, and coverage target', () {
      final result = resolveOrganicEdgeBorder(
        _request(
          withGround: true,
          customPrimitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'opening-rock',
              fingerprintChar: 'a',
            ),
            _primitive(
              id: 'opening-filler',
              fingerprintChar: 'b',
              role: BorderPrimitiveRole.filler,
              width: 1,
            ),
          ],
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(
              id: 'opening',
              region: _singleCellRegion(1, 1),
            ),
          ],
        ),
      );

      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      expect(
        result.materialization!.ground,
        isNot(contains(predicate<BorderResolvedGroundCell>(
          (cell) => cell.x == 1 && cell.y == 1,
        ))),
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.coverage_gap')),
      );
      final overlaps = result.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code == 'border.resolution.coverage_overlap',
          )
          .toList(growable: false);
      expect(overlaps, isNotEmpty);
      expect(
        overlaps.map((diagnostic) => diagnostic.severity),
        everyElement(BorderDiagnosticSeverity.warning),
      );
    });

    test('adds accents only when detail density permits them', () {
      final empty = resolveOrganicEdgeBorder(
        _request(
          includeAccent: true,
          params: _params(detailDensityPermille: 0),
        ),
      ).materialization!;
      final dense = resolveOrganicEdgeBorder(
        _request(
          includeAccent: true,
          params: _params(detailDensityPermille: 1000),
        ),
      ).materialization!;

      expect(
        empty.placements.where(
          (placement) => placement.drawBand == BorderDrawBand.accent,
        ),
        isEmpty,
      );
      expect(
        dense.placements.where(
          (placement) => placement.drawBand == BorderDrawBand.accent,
        ),
        isNotEmpty,
      );
    });

    test('blocks empty structural occupancy and excessive coverage gaps', () {
      final empty = resolveOrganicEdgeBorder(
        _request(emptyOccupancy: true),
      );
      final sparse = resolveOrganicEdgeBorder(
        _request(sparseOccupancy: true),
      );

      expect(empty.canApply, isFalse);
      expect(
        empty.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.structural_occupancy_empty'),
      );
      expect(sparse.canApply, isFalse);
      expect(
        sparse.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.coverage_gap'),
      );
    });

    test('uses medium and filler passes only to close structural gaps', () {
      final fullLarge = resolveOrganicEdgeBorder(
        _request(singlePrimitive: true),
      ).materialization!;
      final filled = resolveOrganicEdgeBorder(
        _request(
          singlePrimitive: true,
          sparseOccupancy: true,
          includeFiller: true,
        ),
      );

      expect(
        fullLarge.placements.map((placement) => placement.primitiveId),
        everyElement('rock-a'),
      );
      expect(filled.canApply, isTrue);
      expect(
        filled.materialization!.placements
            .map((placement) => placement.primitiveId),
        contains('filler'),
      );
    });

    test('spaces assets larger than one tile on a world-space lattice', () {
      final result = resolveOrganicEdgeBorder(
        _request(
          region: _regionFromCoordinates(<(int, int)>[
            (1, 2),
            (2, 2),
            (3, 2),
          ]),
          customPrimitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'wide-rock',
              fingerprintChar: 'f',
              width: 32,
              height: 16,
            ),
          ],
          params: _params(variationPermille: 0),
        ),
      );

      expect(result.canApply, isTrue);
      final north = result.materialization!.placements
          .where(
            (placement) =>
                placement.drawBand == BorderDrawBand.structure &&
                placement.anchorCell.y == 2 &&
                placement.opaqueWorldBoundsPx.width == 32 &&
                placement.opaqueWorldBoundsPx.y < 2 * 16,
          )
          .toList()
        ..sort(
          (left, right) => left.opaqueWorldBoundsPx.x.compareTo(
            right.opaqueWorldBoundsPx.x,
          ),
        );
      expect(north.length, greaterThanOrEqualTo(2));
      for (var index = 1; index < north.length; index += 1) {
        expect(
          north[index].opaqueWorldBoundsPx.x -
              north[index - 1].opaqueWorldBoundsPx.x,
          greaterThanOrEqualTo(32),
        );
      }
    });

    test('uses real local ordinals for sub-tile lattice candidates', () {
      final result = resolveOrganicEdgeBorder(
        _request(
          customPrimitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'small-rock',
              fingerprintChar: 'f',
              width: 5,
              height: 17,
            ),
          ],
          params: _params(variationPermille: 0),
        ),
      );

      expect(result.canApply, isTrue);
      expect(
        result.materialization!.placements
            .map((placement) => placement.stableOrderKey.ordinalLocal),
        contains(greaterThan(0)),
      );
    });

    test('materializes every requested depth rank', () {
      final result = resolveOrganicEdgeBorder(
        _request(
          singlePrimitive: true,
          params: _params(depthRows: 3, variationPermille: 0),
        ),
      );

      expect(result.canApply, isTrue);
      expect(
        result.materialization!.placements
            .where(
              (placement) => placement.drawBand == BorderDrawBand.structure,
            )
            .map((placement) => placement.stableOrderKey.rank)
            .toSet(),
        <int>{0, 1, 2},
      );
    });

    test('derives lattice phase from the feature seed', () {
      final outputs = <String>{};
      for (var seed = 0; seed < 16; seed += 1) {
        final result = resolveOrganicEdgeBorder(
          _request(
            seed: seed,
            customPrimitives: <BorderPublishedPrimitive>[
              _primitive(
                id: 'odd-wide-rock',
                fingerprintChar: 'f',
                width: 23,
                height: 17,
              ),
            ],
            params: _params(variationPermille: 0),
          ),
        );
        expect(result.canApply, isTrue);
        outputs.add(
          result.materialization!.placements
              .where(
                (placement) => placement.drawBand == BorderDrawBand.structure,
              )
              .map(
                (placement) =>
                    '${placement.topLeftWorldPx.x}:${placement.topLeftWorldPx.y}',
              )
              .join(','),
        );
      }

      expect(outputs.length, greaterThan(1));
    });

    test('rejects any opaque transformed pixel entering a distant keep-out',
        () {
      final result = resolveOrganicEdgeBorder(
        _request(
          customPrimitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'deep-rock',
              fingerprintChar: 'f',
              width: 32,
              height: 32,
            ),
          ],
          params: _params(depthRows: 2, variationPermille: 0),
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(
              id: 'interior-opening',
              region: _singleCellRegion(2, 2),
            ),
          ],
        ),
      );

      expect(result.canApply, isTrue);
      final keepOut = BorderPixelRect(x: 32, y: 32, width: 16, height: 16);
      expect(
        result.materialization!.placements,
        everyElement(
          predicate<BorderResolvedPlacement>(
            (placement) => !_rectanglesIntersect(
              placement.opaqueWorldBoundsPx,
              keepOut,
            ),
          ),
        ),
      );
    });

    test('falls back to a primitive that is locally valid around a keep-out',
        () {
      final lowerBand = <(int, int)>[
        for (var y = 2; y < 5; y += 1)
          for (var x = 0; x < 5; x += 1) (x, y),
      ];
      final keepOutBand = _regionFromCoordinates(<(int, int)>[
        for (var x = 0; x < 5; x += 1) (x, 3),
      ]);
      final invalidNearKeepOut = _primitive(
        id: 'a-deep-invalid',
        fingerprintChar: '6',
        height: 32,
        anchorPx: const BorderPixelPos(x: 8, y: 0),
        allowedQuarterTurns: const <int>[0],
      );
      final locallyValid = _primitive(
        id: 'b-shallow-valid',
        fingerprintChar: '7',
        height: 1,
        allowedQuarterTurns: const <int>[0],
      );
      final result = resolveOrganicEdgeBorder(
        _request(
          region: _regionFromCoordinates(lowerBand),
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(id: 'middle-band', region: keepOutBand),
          ],
          customPrimitives: <BorderPublishedPrimitive>[
            invalidNearKeepOut,
            locallyValid,
            _primitive(
              id: 'edge-filler',
              fingerprintChar: '8',
              role: BorderPrimitiveRole.filler,
              width: 1,
              height: 1,
            ),
          ],
          params: _params(
            variationPermille: 0,
            gapTolerancePx: 16,
          ),
        ),
      );

      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      expect(
        result.materialization!.placements
            .map((placement) => placement.primitiveId),
        contains('b-shallow-valid'),
      );
      expect(
        result.diagnostics.where(
          (diagnostic) =>
              diagnostic.code ==
                  'border.resolution.repetition_four_identical' &&
              diagnostic.parameters['primitiveId'] == 'b-shallow-valid',
        ),
        isEmpty,
      );
    });

    test('repetition windows never cross depth ranks or tangent breaks', () {
      final variants = <BorderPublishedPrimitive>[
        _primitive(id: 'variant-a', fingerprintChar: '6'),
        _primitive(id: 'variant-b', fingerprintChar: '7'),
      ];
      final cases = <BorderResolutionRequest>[
        _request(
          region: _singleCellRegion(2, 2),
          customPrimitives: variants,
          params: _params(depthRows: 2, variationPermille: 0),
        ),
        _request(
          region: _regionFromCoordinates(<(int, int)>[
            (1, 1),
            (2, 1),
            (1, 2),
          ]),
          customPrimitives: variants,
          params: _params(variationPermille: 0),
        ),
      ];

      for (final request in cases) {
        final result = resolveOrganicEdgeBorder(request);
        expect(result.canApply, isTrue);
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.code),
          isNot(contains('border.resolution.repetition_four_identical')),
        );
      }
    });

    test(
        'two short runs separated by a locally rejected site do not repeat as one',
        () {
      final occupancy = List<bool>.filled(8 * 32, false)
        ..setRange(0, 8, List<bool>.filled(8, true))
        ..[16 * 8 + 7] = true;
      final result = resolveOrganicEdgeBorder(
        _request(
          region: _regionFromCoordinates(<(int, int)>[
            for (var y = 2; y < 5; y += 1)
              for (var x = 2; x < 4; x += 1) (x, y),
          ]),
          keepOutRegions: <BorderKeepOutRegion>[
            BorderKeepOutRegion(
              id: 'middle-local-gap',
              region: _singleCellRegion(3, 3),
            ),
          ],
          customPrimitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a-repeated-deep-rock',
              fingerprintChar: '6',
              width: 8,
              height: 32,
              anchorPx: const BorderPixelPos(x: 4, y: 0),
              occupancy: occupancy,
              allowedQuarterTurns: const <int>[0],
            ),
            _primitive(
              id: 'b-deep-rock-variant',
              fingerprintChar: '7',
              width: 8,
              height: 32,
              anchorPx: const BorderPixelPos(x: 4, y: 0),
              occupancy: occupancy,
              allowedQuarterTurns: const <int>[0],
            ),
            _primitive(
              id: 'other-orientations',
              fingerprintChar: '8',
              allowedQuarterTurns: const <int>[1, 2, 3],
            ),
          ],
          params: _params(
            variationPermille: 0,
            maxOverlapPx: 3,
            gapTolerancePx: 24,
          ),
        ),
      );

      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      final eastPlacements = result.materialization!.placements
          .where(
            (placement) =>
                placement.primitiveId == 'a-repeated-deep-rock' &&
                placement.transform.quarterTurns == 0,
          )
          .toList(growable: false);
      final eastRuns = _contiguousSiteRuns(
        eastPlacements.map((placement) => placement.topLeftWorldPx.x),
        spacingPx: 5,
      );
      expect(eastRuns, hasLength(2));
      expect(
        eastRuns,
        everyElement(
          predicate<List<int>>(
            (run) => run.length < 4,
            'contains fewer than four consecutive sites',
          ),
        ),
      );
      expect(eastPlacements.length, greaterThanOrEqualTo(4));
      expect(
        result.diagnostics.where(
          (diagnostic) =>
              diagnostic.code ==
                  'border.resolution.repetition_four_identical' &&
              diagnostic.parameters['primitiveId'] == 'a-repeated-deep-rock',
        ),
        isEmpty,
      );
    });

    test('applies a stable-slot suppression before final diagnostics', () {
      final primitive = _primitive(
        id: 'small-rock',
        fingerprintChar: '8',
        width: 8,
        height: 8,
      );
      final baselineEvidence = resolveOrganicEdgeBorderWithEvidence(
        _request(
          customPrimitives: <BorderPublishedPrimitive>[primitive],
          params: _params(variationPermille: 0),
        ),
      );
      final baseline = baselineEvidence.result;
      final target = baseline.materialization!.placements.first;
      final resolvedEvidence = resolveOrganicEdgeBorderWithEvidence(
        _request(
          customPrimitives: <BorderPublishedPrimitive>[primitive],
          params: _params(variationPermille: 0),
          overrides: <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: target.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
          ],
        ),
      );
      final result = resolvedEvidence.result;

      expect(
        result.canApply,
        isTrue,
        reason:
            result.diagnostics.map((diagnostic) => diagnostic.code).join(', '),
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('border.resolution.coverage_gap')),
      );
      expect(
        result.materialization!.placements,
        baseline.materialization!.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
      final baselineTargetLength = baselineEvidence
          .contours.single.coverage.targetIntervals
          .fold<int>(0, (total, interval) => total + interval.lengthPx);
      final resolvedTargetLength = resolvedEvidence
          .contours.single.coverage.targetIntervals
          .fold<int>(0, (total, interval) => total + interval.lengthPx);
      expect(
        baselineTargetLength - resolvedTargetLength,
        primitive.publishedMetrics.pixelSize.width,
      );
    });
  });

  group('resolveBorderFeature', () {
    test('dispatches every V1 solver without geometry-family fallback', () {
      expect(resolveBorderFeature(_request()).canApply, isTrue);

      final masonry = resolveBorderFeature(
        _request(template: BorderBlueprintTemplate.masonryLine),
      );
      expect(masonry.canApply, isFalse);
      expect(
        masonry.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.stroke_geometry_required'),
      );

      final fence = resolveBorderFeature(
        _request(template: BorderBlueprintTemplate.postAndRailLine),
      );
      expect(fence.canApply, isFalse);
      expect(
        fence.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.stroke_geometry_required'),
      );
    });

    test('rejects a coherently rehashed but noncanonical proposal', () {
      final request = _request(singlePrimitive: true);
      final canonical = resolveBorderFeature(request);
      final source = canonical.materialization!;
      final first = source.placements.first;
      final alteredPlacement = BorderResolvedPlacement(
        id: first.id,
        slotKey: first.slotKey,
        primitiveId: first.primitiveId,
        visualSnapshotId: first.visualSnapshotId,
        anchorCell: first.anchorCell,
        topLeftWorldPx: BorderPixelPos(
          x: first.topLeftWorldPx.x + 1,
          y: first.topLeftWorldPx.y,
        ),
        opaqueWorldBoundsPx: BorderPixelRect(
          x: first.opaqueWorldBoundsPx.x + 1,
          y: first.opaqueWorldBoundsPx.y,
          width: first.opaqueWorldBoundsPx.width,
          height: first.opaqueWorldBoundsPx.height,
        ),
        transform: first.transform,
        drawBand: first.drawBand,
        stableOrderKey: first.stableOrderKey,
      );
      final placements = <BorderResolvedPlacement>[
        alteredPlacement,
        ...source.placements.skip(1),
      ];
      final altered = BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: source.receipt.resolverVersion,
          blueprintRevision: source.receipt.blueprintRevision,
          components: source.receipt.components,
          inputFingerprint: source.receipt.inputFingerprint,
          outputFingerprint: computeBorderOutputFingerprint(
            ground: source.ground,
            placements: placements,
          ),
        ),
        ground: source.ground,
        placements: placements,
      );
      final report = validateBorderResolutionResultForRequest(
        request: request,
        proposedResult: BorderResolutionResult(
          materialization: altered,
          diagnosticReport: const BorderDiagnosticsReport.empty(),
        ),
      );

      expect(report.hasErrors, isTrue);
      expect(
        report.diagnostics.single.code,
        'border.resolution.proposal_not_canonical',
      );
      expect(
        validateBorderResolutionResultForRequest(
          request: request,
          proposedResult: canonical,
        ).hasDiagnostics,
        isFalse,
      );
    });
  });
}

List<List<int>> _contiguousSiteRuns(
  Iterable<int> sites, {
  required int spacingPx,
}) {
  final sorted = sites.toList()..sort();
  final runs = <List<int>>[];
  for (final site in sorted) {
    if (runs.isEmpty || site != runs.last.last + spacingPx) {
      runs.add(<int>[site]);
    } else {
      runs.last.add(site);
    }
  }
  return runs;
}

BorderResolutionRequest _request({
  int seed = 0,
  BorderRegionGeometry? region,
  BorderGenerationParams? params,
  List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
  List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
  bool reversePrimitives = false,
  bool reverseSnapshots = false,
  bool withGround = false,
  bool includeAccent = false,
  bool emptyOccupancy = false,
  bool sparseOccupancy = false,
  bool singlePrimitive = false,
  bool includeFiller = false,
  List<BorderPublishedPrimitive>? customPrimitives,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
}) {
  final primitiveA = _primitive(
    id: 'rock-a',
    fingerprintChar: 'a',
    emptyOccupancy: emptyOccupancy,
    sparseOccupancy: sparseOccupancy,
  );
  final primitiveB = _primitive(
    id: 'rock-b',
    fingerprintChar: 'b',
    emptyOccupancy: emptyOccupancy,
    sparseOccupancy: sparseOccupancy,
  );
  final primitives = customPrimitives ??
      <BorderPublishedPrimitive>[
        primitiveA,
        if (!singlePrimitive) primitiveB,
        if (includeFiller)
          _primitive(
            id: 'filler',
            fingerprintChar: 'e',
            role: BorderPrimitiveRole.filler,
          ),
        if (includeAccent)
          _primitive(
            id: 'foam',
            fingerprintChar: 'c',
            role: BorderPrimitiveRole.accent,
          ),
      ];
  final orderedPrimitives = reversePrimitives
      ? primitives.reversed.toList(growable: false)
      : primitives;
  final groundSnapshotId = _snapshotId('d');
  final definition = BorderBlueprintDefinition<BorderPublishedPrimitive,
      BorderPublishedGround>(
    name: 'Côte test',
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: orderedPrimitives,
    defaults: params ?? _params(),
    ground: withGround
        ? BorderPublishedGround(
            sourceSmartTilePresetId: 'surface-grass',
            edgeBandCells: 1,
            visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
              for (final role in standardSurfaceVariantRoleOrder)
                role: groundSnapshotId,
            },
          )
        : null,
    sortOrder: 0,
  );
  final snapshots = <BorderVisualSnapshot>[
    for (final primitive in primitives) _snapshotForPrimitive(primitive),
    if (withGround) _snapshot(groundSnapshotId),
  ];
  final orderedSnapshots =
      reverseSnapshots ? snapshots.reversed.toList(growable: false) : snapshots;
  return BorderResolutionRequest(
    mapSize: const GridSize(width: 5, height: 5),
    tileSizePx: const GridSize(width: 16, height: 16),
    blueprintId: 'coast',
    blueprintRevision: BorderBlueprintRevision(
      revision: 1,
      definition: definition,
    ),
    feature: BorderFeature(
      id: 'feature-coast',
      name: 'Côte',
      blueprintId: 'coast',
      seed: BorderSignedInt64.fromInt(seed),
      geometry: region ?? _centerRegion(),
      paramsOverride: params,
      overrides: overrides,
      keepOutRegions: keepOutRegions,
    ),
    visualSnapshots: orderedSnapshots,
    resolverVersion: 1,
  );
}

BorderGenerationParams _params({
  int irregularityPermille = 0,
  int detailDensityPermille = 0,
  int variationPermille = 1000,
  int maxOverlapPx = 0,
  int gapTolerancePx = 0,
  int depthRows = 1,
}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: variationPermille,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
    );

BorderPublishedPrimitive _primitive({
  required String id,
  required String fingerprintChar,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  bool emptyOccupancy = false,
  bool sparseOccupancy = false,
  int width = 16,
  int height = 16,
  BorderPixelPos? anchorPx,
  BorderPixelRect? opaqueBounds,
  List<bool>? occupancy,
  List<int> allowedQuarterTurns = const <int>[0, 1, 2, 3],
}) {
  final cells = occupancy == null
      ? List<bool>.filled(width * height, !emptyOccupancy)
      : List<bool>.from(occupancy);
  if (sparseOccupancy) {
    cells
      ..fillRange(0, cells.length, false)
      ..[(height ~/ 2) * width + width ~/ 2] = true;
  }
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: _snapshotId(fingerprintChar),
    role: role,
    weight: 1,
    anchorPx: anchorPx ?? BorderPixelPos(x: width ~/ 2, y: height ~/ 2),
    transforms: BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: allowedQuarterTurns,
    ),
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-$id',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: opaqueBounds ??
          BorderPixelRect(x: 0, y: 0, width: width, height: height),
      defaultAnchorPx:
          anchorPx ?? BorderPixelPos(x: width ~/ 2, y: height ~/ 2),
      occupancyMaskRle: encodeBorderRleMask(cells),
    ),
  );
}

BorderVisualSnapshot _snapshotForPrimitive(BorderPublishedPrimitive primitive) {
  final size = primitive.publishedMetrics.pixelSize;
  return BorderVisualSnapshot(
    id: primitive.visualSnapshotId,
    contentFingerprint:
        primitive.visualSnapshotId.substring('border-snapshot-sha256:'.length),
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath:
            'assets/borders/snapshots/${primitive.visualSnapshotId.substring(primitive.visualSnapshotId.length - 8)}.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: size.width,
          height: size.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

BorderVisualSnapshot _snapshot(String id) => BorderVisualSnapshot(
      id: id,
      contentFingerprint: id.substring('border-snapshot-sha256:'.length),
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/${id.substring(id.length - 8)}.png',
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: 16,
            height: 16,
          ),
          durationMs: 100,
        ),
      ],
    );

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

BorderRegionGeometry _centerRegion() => BorderRegionGeometry(
      width: 5,
      height: 5,
      cells: <bool>[
        false,
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    );

BorderRegionGeometry _cornerRegion() => BorderRegionGeometry(
      width: 5,
      height: 5,
      cells: <bool>[
        true,
        true,
        false,
        false,
        false,
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    );

BorderRegionGeometry _lowerHalfRegion() => BorderRegionGeometry(
      width: 5,
      height: 5,
      cells: <bool>[
        for (var y = 0; y < 5; y += 1)
          for (var x = 0; x < 5; x += 1) y >= 2,
      ],
    );

BorderRegionGeometry _singleCellRegion(int x, int y) => BorderRegionGeometry(
      width: 5,
      height: 5,
      cells: <bool>[
        for (var row = 0; row < 5; row += 1)
          for (var column = 0; column < 5; column += 1) column == x && row == y,
      ],
    );

BorderRegionGeometry _centerWithDistantIsland() => _regionFromCoordinates(
      <(int, int)>[
        (0, 0),
        (1, 1),
        (2, 1),
        (3, 1),
        (1, 2),
        (2, 2),
        (3, 2),
        (1, 3),
        (2, 3),
        (3, 3),
      ],
    );

BorderRegionGeometry _regionFromCoordinates(List<(int, int)> coordinates) {
  final filled = coordinates.toSet();
  return BorderRegionGeometry(
    width: 5,
    height: 5,
    cells: <bool>[
      for (var y = 0; y < 5; y += 1)
        for (var x = 0; x < 5; x += 1) filled.contains((x, y)),
    ],
  );
}

bool _rectanglesIntersect(BorderPixelRect left, BorderPixelRect right) =>
    left.x < right.right &&
    left.right > right.x &&
    left.y < right.bottom &&
    left.bottom > right.y;
