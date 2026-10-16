import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ledgeLine has its own explicit template and wire identity', () {
    final template = BorderBlueprintTemplate.values.byName('ledgeLine');
    expect(borderBlueprintTemplateV1WireName(template), 'ledgeLine');
    expect(
      borderTemplateStrokeAlignment(template),
      BorderStrokeAlignment.gridEdges,
    );
    expect(borderTemplateSupportsLineSide(template), isTrue);
    expect(minimumBorderCatalogFormatVersionForTemplate(template), 7);
  });

  test('catalog V7 is supported without changing the layer format', () {
    expect(ProjectBorderCatalog.latestSupportedFormatVersion, 10);
    expect(ProjectBorderCatalog(formatVersion: 7).formatVersion, 7);
    expect(BorderLayerContent.latestSupportedFormatVersion, 4);
  });
  for (final (end, normal, carrier)
      in <(GridPos, BorderCardinalDirection, GridPos)>[
        (
          const GridPos(x: 4, y: 3),
          BorderCardinalDirection.south,
          const GridPos(x: 3, y: 3),
        ),
        (
          const GridPos(x: 3, y: 4),
          BorderCardinalDirection.west,
          const GridPos(x: 2, y: 3),
        ),
        (
          const GridPos(x: 2, y: 3),
          BorderCardinalDirection.north,
          const GridPos(x: 2, y: 2),
        ),
        (
          const GridPos(x: 3, y: 2),
          BorderCardinalDirection.east,
          const GridPos(x: 3, y: 2),
        ),
      ]) {
    test(
      'one unit edge selects native $normal without transforming pixels',
      () {
        final fixture = _Fixture(points: [const GridPos(x: 3, y: 3), end]);
        final resolved = resolveLedgeLineBorderWithEvidence(fixture.request);
        expect(
          resolved.result.canApply,
          isTrue,
          reason: resolved.result.diagnostics.toString(),
        );
        final evidence = resolved.edges.single;
        expect(evidence.physicalNormal, normal);
        expect(evidence.expectedCarrierCell, carrier);
        final placement = evidence.finalPlacement;
        expect(placement, resolved.result.materialization!.placements.single);
        expect(placement.primitiveId, normal.name);
        expect(placement.anchorCell, carrier);
        expect(
          placement.topLeftWorldPx,
          BorderPixelPos(x: carrier.x * 32, y: carrier.y * 32),
        );
        expect(
          placement.transform,
          BorderSpriteTransform(quarterTurns: 0, flipX: false),
        );
        expect(placement.drawBand, BorderDrawBand.structure);
        expect(resolveBorderFeature(fixture.request), resolved.result);
      },
    );
  }

  test(
    'inverted lineSide moves carrier and selects the opposite native asset',
    () {
      final fixture = _Fixture(lineSide: BorderLineSide.inverted);
      final resolved = resolveLedgeLineBorderWithEvidence(fixture.request);
      expect(resolved.result.canApply, isTrue);
      expect(
        resolved.edges.single.physicalNormal,
        BorderCardinalDirection.north,
      );
      expect(
        resolved.edges.single.expectedCarrierCell,
        const GridPos(x: 3, y: 2),
      );
      expect(resolved.edges.single.finalPlacement.primitiveId, 'north');
    },
  );

  test(
    'a missing native normal is refused instead of rotating an available face',
    () {
      final fixture = _Fixture(
        primitives: [_primitive('north', BorderPrimitiveOrientation.north)],
      );
      final resolved = resolveLedgeLineBorderWithEvidence(fixture.request);
      expect(resolved.result.canApply, isFalse);
      expect(resolved.edges, isEmpty);
      expect(
        resolved.result.diagnostics.map((d) => d.code),
        contains('border.resolution.ledge_orientation_missing'),
      );
    },
  );

  test('jump permission toggles leave all visual placements identical', () {
    final off = _Fixture();
    final primary = _Fixture(jumpBehavior: BorderJumpBehavior());
    final inverted = _Fixture(
      jumpBehavior: BorderJumpBehavior(side: BorderLineSide.inverted),
    );
    final base = resolveLedgeLineBorder(off.request).materialization!;
    for (final fixture in [primary, inverted]) {
      final current = resolveLedgeLineBorder(fixture.request).materialization!;
      expect(current.placements, base.placements);
      expect(
        current.receipt.components.blueprint,
        isNot(base.receipt.components.blueprint),
      );
    }
    expect(
      deriveBorderJumpFaceCandidates(primary.request).single.topologicalNormal,
      BorderCardinalDirection.south,
    );
    expect(
      deriveBorderJumpFaceCandidates(inverted.request).single.topologicalNormal,
      BorderCardinalDirection.north,
    );
  });

  test(
    'replacement keeps whole-cell origin with a different primitive anchor',
    () {
      final primitives = [
        _primitive('south-a', BorderPrimitiveOrientation.south),
        _primitive(
          'south-b',
          BorderPrimitiveOrientation.south,
          anchor: const BorderPixelPos(x: 1, y: 2),
        ),
      ];
      final base = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
      );
      final slot = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single.slotKey;
      final changed = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
        overrides: [_override(slot, replacement: 'south-b')],
      );
      final evidence = resolveLedgeLineBorderWithEvidence(changed.request);
      expect(evidence.result.canApply, isTrue);
      expect(evidence.edges.single.finalPlacement.primitiveId, 'south-b');
      expect(
        evidence.edges.single.finalPlacement.topLeftWorldPx,
        const BorderPixelPos(x: 96, y: 96),
      );
    },
  );

  test(
    'variation is restricted to native variants of the same physical normal',
    () {
      final base = _Fixture();
      final slot = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single.slotKey;
      for (var salt = 1; salt <= 32; salt++) {
        final changed = _Fixture(overrides: [_override(slot, salt: salt)]);
        final resolved = resolveLedgeLineBorderWithEvidence(changed.request);
        expect(resolved.result.canApply, isTrue, reason: '$salt');
        expect(resolved.edges.single.finalPlacement.primitiveId, 'south');
      }
    },
  );

  test(
    'wrong normal, displacement, rotation and flip refuse all final evidence',
    () {
      final base = _Fixture();
      final placement = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single;
      for (final override in [
        _override(placement.slotKey, replacement: 'north'),
        _override(
          placement.slotKey,
          offset: const BorderPixelOffset(x: 1, y: 0),
        ),
        _override(
          placement.slotKey,
          transform: BorderSpriteTransform(quarterTurns: 1, flipX: false),
        ),
        _override(
          placement.slotKey,
          transform: BorderSpriteTransform(quarterTurns: 0, flipX: true),
        ),
      ]) {
        final resolved = resolveLedgeLineBorderWithEvidence(
          _Fixture(overrides: [override]).request,
        );
        expect(resolved.result.canApply, isFalse);
        expect(resolved.result.materialization, isNull);
        expect(resolved.edges, isEmpty);
      }
    },
  );

  test(
    'suppression and keep-out remove the complete module and its evidence',
    () {
      final points = const [
        GridPos(x: 3, y: 3),
        GridPos(x: 4, y: 3),
        GridPos(x: 5, y: 3),
      ];
      final base = _Fixture(points: points);
      final slot = resolveLedgeLineBorder(base.request)
          .materialization!
          .placements
          .firstWhere((p) => p.anchorCell.x == 3)
          .slotKey;
      final cells = List<bool>.filled(144, false)..[3 * 12 + 3] = true;
      for (final fixture in [
        _Fixture(
          points: points,
          overrides: [_override(slot, suppressed: true)],
        ),
        _Fixture(
          points: points,
          keepOut: [
            BorderKeepOutRegion(
              id: 'gap',
              region: BorderRegionGeometry(width: 12, height: 12, cells: cells),
            ),
          ],
        ),
      ]) {
        final resolved = resolveLedgeLineBorderWithEvidence(fixture.request);
        expect(resolved.result.canApply, isTrue);
        expect(resolved.result.materialization!.placements, hasLength(1));
        expect(resolved.edges, hasLength(1));
        expect(
          resolved.edges.single.expectedCarrierCell,
          const GridPos(x: 4, y: 3),
        );
      }
    },
  );

  test(
    'invalid canvas size, legacy orientation and transform policy refuse resolution',
    () {
      for (final primitive in [
        _primitive(
          'small',
          BorderPrimitiveOrientation.south,
          size: const GridSize(width: 31, height: 32),
        ),
        _primitive('legacy', BorderPrimitiveOrientation.legacyAxis),
        _primitive('flip', BorderPrimitiveOrientation.south, flip: true),
        _primitive(
          'rotate',
          BorderPrimitiveOrientation.south,
          turns: const [0, 1],
        ),
      ]) {
        expect(
          resolveLedgeLineBorder(
            _Fixture(primitives: [primitive]).request,
          ).canApply,
          isFalse,
        );
      }
      for (final parameters in [
        _parameters(depthRows: 2),
        _parameters(irregularity: 1),
        _parameters(autoRotation: true),
      ]) {
        expect(
          resolveLedgeLineBorder(
            _Fixture(parameters: parameters).request,
          ).canApply,
          isFalse,
        );
      }
    },
  );

  test(
    'boundary vertices are inclusive but the expected carrier must fit the map',
    () {
      expect(
        resolveLedgeLineBorder(
          _Fixture(
            points: const [GridPos(x: 11, y: 12), GridPos(x: 12, y: 12)],
            lineSide: BorderLineSide.inverted,
          ).request,
        ).canApply,
        isTrue,
      );
      expect(
        resolveLedgeLineBorder(
          _Fixture(
            points: const [GridPos(x: 11, y: 12), GridPos(x: 12, y: 12)],
          ).request,
        ).canApply,
        isFalse,
      );
      expect(
        resolveLedgeLineBorder(
          _Fixture(
            points: const [GridPos(x: 12, y: 12), GridPos(x: 13, y: 12)],
          ).request,
        ).canApply,
        isFalse,
      );
    },
  );

  test(
    'duplicate edges across strokes are refused without duplicate slots',
    () {
      final points = const [GridPos(x: 3, y: 3), GridPos(x: 4, y: 3)];
      expect(
        () => _Fixture(
          strokes: [
            _stroke(points, id: 'one'),
            _stroke(points, id: 'two'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('catalog promotion takes the maximum capability even with jump V6', () {
    final record = _record(
      _Fixture(jumpBehavior: BorderJumpBehavior()).definition,
    );
    expect(minimumBorderCatalogFormatVersionForRecord(record), 7);
    final catalog = ProjectBorderCatalog(formatVersion: 7, records: [record]);
    expect(
      decodeProjectBorderCatalogJson(
        jsonDecode(jsonEncode(encodeProjectBorderCatalogJson(catalog))),
      ),
      catalog,
    );
    for (var version = 1; version < 7; version++) {
      expect(
        () => encodeBorderBlueprintRecordJson(record, formatVersion: version),
        throwsFormatException,
      );
      final raw = encodeBorderBlueprintRecordJson(record, formatVersion: 7);
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: version),
        throwsFormatException,
      );
    }
    final invalid = encodeBorderBlueprintRecordJson(record, formatVersion: 7);
    ((invalid['draft'] as Map)['definition'] as Map)['unknown'] = 'unsupported';
    expect(
      () => decodeBorderBlueprintRecordJson(invalid, formatVersion: 7),
      throwsFormatException,
    );
  });

  test(
    'gallery certifies declared native normals only, including a single south asset',
    () {
      for (final fixture in [
        _Fixture(),
        _Fixture(
          primitives: [_primitive('south', BorderPrimitiveOrientation.south)],
        ),
      ]) {
        final gallery = resolveBorderCanonicalGallery(
          blueprintId: 'ledge',
          blueprintRevision: fixture.request.blueprintRevision!,
          visualSnapshots: fixture.request.visualSnapshots,
          tileSizePx: fixture.request.tileSizePx,
        );
        expect(
          gallery.allCasesResolved,
          isTrue,
          reason: gallery.resolutionDiagnostics.diagnostics.toString(),
        );
        expect(gallery.cases.map((c) => c.galleryCase), [
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.endpoint,
        ]);
        final declared = fixture.definition.primitives
            .map((p) => p.authoredOrientation.name)
            .toSet();
        for (final c in gallery.cases) {
          expect(c.invertedResolverResult, isNull);
          final placements = c.resolverResult.materialization!.placements;
          expect(placements.map((p) => p.primitiveId).toSet(), declared);
          expect(
            placements.length,
            declared.length *
                (c.galleryCase == BorderCanonicalGalleryCase.endpoint ? 1 : 4),
          );
          expect(
            c.publicationSample.coverageChecks.single.longestContiguousGapPx,
            0,
          );
        }
        final ready = assessBorderPublicationReadiness(
          blueprintId: 'ledge',
          definition: fixture.definition,
          resolverVersion: borderResolverVersion,
          project: _project(fixture),
          visualSnapshots: fixture.request.visualSnapshots,
          snapshotIntegrity: _integrity(fixture),
          canonicalGalleryReport: gallery.report,
        );
        expect(
          ready.canPublish,
          isTrue,
          reason: ready.diagnosticReport.diagnostics.toString(),
        );
      }
    },
  );

  test(
    'gallery measures missing source occupancy instead of assuming a full cell',
    () {
      final fixture = _Fixture(
        primitives: [
          _gappedPrimitive('south-gap', BorderPrimitiveOrientation.south),
        ],
      );
      final gallery = resolveBorderCanonicalGallery(
        blueprintId: 'ledge',
        blueprintRevision: fixture.request.blueprintRevision!,
        visualSnapshots: fixture.request.visualSnapshots,
        tileSizePx: fixture.request.tileSizePx,
      );
      expect(gallery.allCasesResolved, isTrue);
      for (final sample in gallery.cases) {
        expect(
          sample.publicationSample.coverageChecks.single.longestContiguousGapPx,
          8,
        );
      }
      expect(
        assessBorderPublicationReadiness(
          blueprintId: 'ledge',
          definition: fixture.definition,
          resolverVersion: borderResolverVersion,
          project: _project(fixture),
          visualSnapshots: fixture.request.visualSnapshots,
          snapshotIntegrity: _integrity(fixture),
          canonicalGalleryReport: gallery.report,
        ).canPublish,
        isFalse,
      );
    },
  );

  test(
    'publication checks tangent occupancy of every admissible variant independent of RNG',
    () {
      for (final orientation in BorderPrimitiveOrientation.values.where(
        (o) => o != BorderPrimitiveOrientation.legacyAxis,
      )) {
        for (final variation in [0, 1000]) {
          final fixture = _Fixture(
            primitives: [
              _primitive('a', orientation, weight: 1000),
              _gappedPrimitive('b', orientation),
            ],
            parameters: _parameters(variation: variation),
          );
          final gallery = resolveBorderCanonicalGallery(
            blueprintId: 'ledge',
            blueprintRevision: fixture.request.blueprintRevision!,
            visualSnapshots: fixture.request.visualSnapshots,
            tileSizePx: fixture.request.tileSizePx,
          );
          expect(gallery.allCasesResolved, isTrue);
          if (variation == 0) {
            for (final sample in gallery.cases) {
              expect(
                sample.resolverResult.materialization!.placements.every(
                  (p) => p.primitiveId == 'a',
                ),
                isTrue,
              );
              expect(
                sample
                    .publicationSample
                    .coverageChecks
                    .single
                    .longestContiguousGapPx,
                0,
              );
            }
          }
          final readiness = assessBorderPublicationReadiness(
            blueprintId: 'ledge',
            definition: fixture.definition,
            resolverVersion: borderResolverVersion,
            project: _project(fixture),
            visualSnapshots: fixture.request.visualSnapshots,
            snapshotIntegrity: _integrity(fixture),
            canonicalGalleryReport: gallery.report,
          );
          expect(
            readiness.canPublish,
            isFalse,
            reason: '$orientation variation=$variation',
          );
          expect(
            readiness.diagnosticReport.diagnostics
                .where(
                  (d) =>
                      d.code ==
                      'border.publication.ledge_variant_coverage_incomplete',
                )
                .map((d) => d.parameters['primitiveId']),
            ['b'],
          );
        }
      }
      final primitives = [
        _primitive('a', BorderPrimitiveOrientation.south),
        _gappedPrimitive('b', BorderPrimitiveOrientation.south),
      ];
      final base = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
      );
      final slot = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single.slotKey;
      final replaced = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
        overrides: [_override(slot, replacement: 'b')],
      );
      final result = resolveLedgeLineBorder(replaced.request);
      expect(result.canApply, isTrue);
      expect(result.materialization!.placements.single.primitiveId, 'b');
    },
  );

  test(
    'current fingerprints and form do not attest canonical placement completeness',
    () {
      final fixture = _Fixture(
        points: const [
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
        ],
      );
      final base = resolveLedgeLineBorder(fixture.request).materialization!;
      final forged = _reseal(base, [base.placements.first]);
      expect(
        ledgeLineNativePlacementGeometryMatches(fixture.request, forged),
        isTrue,
      );
      expect(
        assessBorderMaterializationFreshness(
          fixture.request,
          materialization: forged,
          snapshotIntegrity: _integrity(fixture),
        ).state,
        BorderMaterializationState.fresh,
      );
      expect(
        validateBorderResolutionResultForRequest(
          request: fixture.request,
          proposedResult: BorderResolutionResult(
            materialization: forged,
            diagnosticReport: const BorderDiagnosticsReport.empty(),
          ),
        ).hasErrors,
        isTrue,
      );
    },
  );

  test(
    'current fingerprints and form do not attest an explicit canonical replacement',
    () {
      final primitives = [
        _primitive('a', BorderPrimitiveOrientation.south),
        _primitive('b', BorderPrimitiveOrientation.south),
      ];
      final base = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
      );
      final selectedA = resolveLedgeLineBorder(base.request).materialization!;
      final fixture = _Fixture(
        primitives: primitives,
        parameters: _parameters(variation: 0),
        overrides: [
          _override(selectedA.placements.single.slotKey, replacement: 'b'),
        ],
      );
      final selectedB = resolveLedgeLineBorder(
        fixture.request,
      ).materialization!;
      expect(selectedB.placements.single.primitiveId, 'b');
      final forged = _reseal(selectedB, selectedA.placements);
      expect(
        ledgeLineNativePlacementGeometryMatches(fixture.request, forged),
        isTrue,
      );
      expect(
        assessBorderMaterializationFreshness(
          fixture.request,
          materialization: forged,
          snapshotIntegrity: _integrity(fixture),
        ).state,
        BorderMaterializationState.fresh,
      );
      expect(
        validateBorderResolutionResultForRequest(
          request: fixture.request,
          proposedResult: BorderResolutionResult(
            materialization: forged,
            diagnosticReport: const BorderDiagnosticsReport.empty(),
          ),
        ).hasErrors,
        isTrue,
      );
    },
  );

  test(
    'publication refuses invalid ledge policy even with a reused gallery',
    () {
      final fixture = _Fixture();
      final gallery = resolveBorderCanonicalGallery(
        blueprintId: 'ledge',
        blueprintRevision: fixture.request.blueprintRevision!,
        visualSnapshots: fixture.request.visualSnapshots,
        tileSizePx: fixture.request.tileSizePx,
      );
      final changed = _Fixture(parameters: _parameters(autoRotation: true));
      final ready = assessBorderPublicationReadiness(
        blueprintId: 'ledge',
        definition: changed.definition,
        resolverVersion: borderResolverVersion,
        project: _project(changed),
        visualSnapshots: changed.request.visualSnapshots,
        snapshotIntegrity: _integrity(changed),
        canonicalGalleryReport: gallery.report,
      );
      expect(ready.canPublish, isFalse);
      expect(
        ready.diagnosticReport.diagnostics.map((d) => d.code),
        contains('border.publication.ledge_parameters_invalid'),
      );
    },
  );

  test(
    'freshness is bound to lineSide, snapshot integrity and final placements',
    () {
      final fixture = _Fixture();
      final base = resolveLedgeLineBorder(fixture.request).materialization!;
      expect(
        assessBorderMaterializationFreshness(
          fixture.request,
          materialization: base,
          snapshotIntegrity: _integrity(fixture),
        ).state,
        BorderMaterializationState.fresh,
      );
      expect(
        assessBorderMaterializationFreshness(
          _Fixture(lineSide: BorderLineSide.inverted).request,
          materialization: base,
          snapshotIntegrity: _integrity(fixture),
        ).state,
        BorderMaterializationState.stale,
      );
      expect(
        assessBorderMaterializationFreshness(
          fixture.request,
          materialization: base,
          snapshotIntegrity: const {},
        ).state,
        isNot(BorderMaterializationState.fresh),
      );
    },
  );

  test(
    'a local override reuses distant modules and matches full resolution',
    () {
      final points = [for (var x = 1; x <= 60; x++) GridPos(x: x, y: 3)];
      final base = _Fixture(
        points: points,
        mapSize: const GridSize(width: 64, height: 12),
      );
      final state = resolveBorderFeatureLocalBaseline(base.request);
      final target = state.materialization.placements.firstWhere(
        (p) => p.anchorCell.x == 30,
      );
      final changed = _Fixture(
        points: points,
        mapSize: const GridSize(width: 64, height: 12),
        overrides: [_override(target.slotKey, suppressed: true)],
      );
      final local = resolveBorderFeatureLocally(
        request: changed.request,
        previousState: state,
        edits: [
          BorderLocalEdit.forCells(
            cells: [target.anchorCell],
            tileSizePx: changed.request.tileSizePx,
          ),
        ],
      );
      expect(local.result, resolveBorderFeature(changed.request));
      expect(local.reusedDistantPlacementSlotKeys.length, greaterThan(45));
      expect(local.recomputedSourceCells.length, lessThan(10));
      expect(
        identical(
          local.result.materialization!.placements.first,
          state.materialization.placements.first,
        ),
        isTrue,
      );
    },
  );

  test(
    'lower-half alpha and bottom anchor retain the whole source canvas origin',
    () {
      final fixture = _Fixture(
        primitives: [
          _primitive(
            'south',
            BorderPrimitiveOrientation.south,
            anchor: const BorderPixelPos(x: 16, y: 31),
          ),
        ],
      );
      final placement = resolveLedgeLineBorderWithEvidence(
        fixture.request,
      ).edges.single.finalPlacement;
      expect(placement.topLeftWorldPx, const BorderPixelPos(x: 96, y: 96));
      expect(
        placement.opaqueWorldBoundsPx,
        BorderPixelRect(x: 96, y: 112, width: 32, height: 16),
      );
    },
  );

  test(
    'three explicit source replacements retain their exact image and never rerandomize',
    () {
      final primitives = [
        for (final id in ['source1194', 'source1212', 'source1198'])
          _primitive(
            id,
            BorderPrimitiveOrientation.south,
            anchor: const BorderPixelPos(x: 16, y: 31),
          ),
      ];
      final base = _Fixture(primitives: primitives);
      final slot = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single.slotKey;
      for (final primitive in primitives) {
        final resolved = resolveLedgeLineBorderWithEvidence(
          _Fixture(
            primitives: primitives,
            overrides: [_override(slot, replacement: primitive.id, salt: 987)],
          ).request,
        );
        expect(resolved.result.canApply, isTrue);
        final placement = resolved.edges.single.finalPlacement;
        expect(placement.primitiveId, primitive.id);
        expect(placement.visualSnapshotId, primitive.visualSnapshotId);
        expect(placement.topLeftWorldPx, const BorderPixelPos(x: 96, y: 96));
        expect(
          placement.opaqueWorldBoundsPx,
          BorderPixelRect(x: 96, y: 112, width: 32, height: 16),
        );
      }
    },
  );

  test(
    'suppression of every module refuses an empty materialization and emits no evidence',
    () {
      final base = _Fixture();
      final slot = resolveLedgeLineBorder(
        base.request,
      ).materialization!.placements.single.slotKey;
      final resolved = resolveLedgeLineBorderWithEvidence(
        _Fixture(overrides: [_override(slot, suppressed: true)]).request,
      );
      expect(resolved.result.canApply, isFalse);
      expect(resolved.edges, isEmpty);
      expect(
        resolved.result.diagnostics.map((d) => d.code),
        contains('border.resolution.materialization_empty'),
      );
    },
  );

  test('feature upsert promotes layer to V3 independently from catalog V7', () {
    final fixture = _Fixture();
    final map = _map(fixture.request.feature);
    final written = upsertBorderFeature(
      map,
      layerId: 'border',
      feature: fixture.request.feature,
      template: BorderBlueprintTemplate.ledgeLine,
    );
    expect((written.layers.single as BorderLayer).content.formatVersion, 3);
    expect(() => jsonEncode(written.toJson()), returnsNormally);
  });

  test(
    'canonical preview application preserves transactions and rejects stale input',
    () {
      final fixture = _Fixture();
      final map = _map(fixture.request.feature);
      final result = resolveLedgeLineBorder(fixture.request);
      final applied = applyBorderFeaturePreview(
        map,
        expectedMapId: map.id,
        layerId: 'border',
        featureId: 'feature',
        expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
          fixture.request.feature,
        ),
        proposedRequest: fixture.request,
        proposedResult: result,
      );
      expect(
        (applied.layers.single as BorderLayer)
            .content
            .features
            .single
            .materialization,
        result.materialization,
      );
      final changed = updateBorderFeatureSeed(
        map,
        layerId: 'border',
        featureId: 'feature',
        seed: BorderSignedInt64.fromInt(78),
      );
      expect(
        applyBorderFeaturePreview(
          changed,
          expectedMapId: map.id,
          layerId: 'border',
          featureId: 'feature',
          expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
            fixture.request.feature,
          ),
          proposedRequest: fixture.request,
          proposedResult: result,
        ),
        same(changed),
      );
    },
  );

  test(
    'ledge relink uses the grid-edge family and preserves exact native geometry',
    () {
      final fixture = _Fixture();
      expect(
        borderTemplateGeometryFamily(BorderBlueprintTemplate.ledgeLine),
        BorderGeometryFamily.gridEdgeLinear,
      );
      final map = _map(fixture.request.feature);
      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: 'feature',
        targetBlueprintId: 'target',
        targetBlueprintRevision: fixture.request.blueprintRevision!,
        visualSnapshots: fixture.request.visualSnapshots,
        tileSizePx: fixture.request.tileSizePx,
        resolverVersion: borderResolverVersion,
      );
      expect(preview.kind, BorderRelinkKind.sameFamily);
      expect(preview.canApplyResolvedRelink, isTrue);
      final applied = applyBorderFeatureRelinkPreview(map, preview: preview);
      expect(
        (applied.layers.single as BorderLayer)
            .content
            .features
            .single
            .blueprintId,
        'target',
      );
      expect((applied.layers.single as BorderLayer).content.formatVersion, 3);
    },
  );

  test(
    'freshness rejects a resealed final placement outside its authored carrier',
    () {
      final fixture = _Fixture();
      final base = resolveLedgeLineBorder(fixture.request).materialization!;
      final source = base.placements.single;
      final altered = BorderResolvedPlacement(
        id: source.id,
        slotKey: source.slotKey,
        primitiveId: source.primitiveId,
        visualSnapshotId: source.visualSnapshotId,
        anchorCell: source.anchorCell,
        topLeftWorldPx: BorderPixelPos(
          x: source.topLeftWorldPx.x + 1,
          y: source.topLeftWorldPx.y,
        ),
        opaqueWorldBoundsPx: BorderPixelRect(
          x: source.opaqueWorldBoundsPx.x + 1,
          y: source.opaqueWorldBoundsPx.y,
          width: source.opaqueWorldBoundsPx.width,
          height: source.opaqueWorldBoundsPx.height,
        ),
        transform: source.transform,
        drawBand: source.drawBand,
        stableOrderKey: source.stableOrderKey,
      );
      final forged = BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: base.receipt.resolverVersion,
          blueprintRevision: base.receipt.blueprintRevision,
          components: base.receipt.components,
          inputFingerprint: base.receipt.inputFingerprint,
          outputFingerprint: computeBorderOutputFingerprint(
            ground: const [],
            placements: [altered],
          ),
        ),
        ground: const [],
        placements: [altered],
      );
      expect(
        assessBorderMaterializationFreshness(
          fixture.request,
          materialization: forged,
          snapshotIntegrity: _integrity(fixture),
        ).state,
        BorderMaterializationState.invalid,
      );
      expect(
        validateBorderResolutionResultForRequest(
          request: fixture.request,
          proposedResult: BorderResolutionResult(
            materialization: forged,
            diagnosticReport: const BorderDiagnosticsReport.empty(),
          ),
        ).hasErrors,
        isTrue,
      );
    },
  );

  test(
    'publication refuses missing source references and incomplete snapshot witnesses',
    () {
      final fixture = _Fixture(
        primitives: [_primitive('south', BorderPrimitiveOrientation.south)],
      );
      final gallery = resolveBorderCanonicalGallery(
        blueprintId: 'ledge',
        blueprintRevision: fixture.request.blueprintRevision!,
        visualSnapshots: fixture.request.visualSnapshots,
        tileSizePx: fixture.request.tileSizePx,
      );
      for (final (project, integrity) in [
        (_project(fixture).copyWith(elements: const []), _integrity(fixture)),
        (_project(fixture), <String, BorderVisualSnapshotIntegrity>{}),
      ]) {
        expect(
          assessBorderPublicationReadiness(
            blueprintId: 'ledge',
            definition: fixture.definition,
            resolverVersion: borderResolverVersion,
            project: project,
            visualSnapshots: fixture.request.visualSnapshots,
            snapshotIntegrity: integrity,
            canonicalGalleryReport: gallery.report,
          ).canPublish,
          isFalse,
        );
      }
    },
  );

  test(
    'immutable snapshot identities are derived from asymmetric RGBA frames',
    () {
      final size = const GridSize(width: 32, height: 32);
      final primitive = _primitive(
        'source1194',
        BorderPrimitiveOrientation.south,
        anchor: const BorderPixelPos(x: 16, y: 31),
      );
      final pixels = _pixels(primitive.id, primitive.authoredOrientation, size);
      expect(pixels[3], 0);
      expect(pixels[32 * 16 * 4 + 3], 255);
      expect(
        primitive.publishedMetrics.occupancyMaskRle,
        encodeBorderRleMask([
          for (var i = 3; i < pixels.length; i += 4) pixels[i] > 0,
        ]),
      );
      expect(
        primitive.visualSnapshotId,
        'border-snapshot-sha256:${computeBorderSnapshotContentFingerprint(
          frames: [BorderSnapshotContentFrame(sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32), durationMs: 100, rgbaBytes: pixels)],
        )}',
      );
      expect(
        _snapshot(primitive).contentFingerprint,
        _pixelFingerprint(primitive.id, primitive.authoredOrientation, size),
      );
      final changed = Uint8List.fromList(pixels)..[0] ^= 1;
      expect(
        computeBorderSnapshotContentFingerprint(
          frames: [
            BorderSnapshotContentFrame(
              sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
              durationMs: 100,
              rgbaBytes: changed,
            ),
          ],
        ),
        isNot(_snapshot(primitive).contentFingerprint),
      );
    },
  );

  test('two physical faces cannot occupy the same whole-cell carrier', () {
    final fixture = _Fixture(
      points: const [
        GridPos(x: 2, y: 3),
        GridPos(x: 3, y: 3),
        GridPos(x: 3, y: 4),
      ],
    );
    final resolved = resolveLedgeLineBorderWithEvidence(fixture.request);
    expect(resolved.result.canApply, isFalse);
    expect(resolved.edges, isEmpty);
    expect(
      resolved.result.diagnostics.map((d) => d.code),
      contains('border.resolution.ledge_carrier_ambiguous'),
    );
  });

  test('locked displacement cannot keep an old jump face alive', () {
    final base = _Fixture();
    final placement = resolveLedgeLineBorder(
      base.request,
    ).materialization!.placements.single;
    final moved = BorderResolvedPlacement(
      id: placement.id,
      slotKey: placement.slotKey,
      primitiveId: placement.primitiveId,
      visualSnapshotId: placement.visualSnapshotId,
      anchorCell: placement.anchorCell,
      topLeftWorldPx: BorderPixelPos(
        x: placement.topLeftWorldPx.x + 1,
        y: placement.topLeftWorldPx.y,
      ),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: placement.opaqueWorldBoundsPx.x + 1,
        y: placement.opaqueWorldBoundsPx.y,
        width: placement.opaqueWorldBoundsPx.width,
        height: placement.opaqueWorldBoundsPx.height,
      ),
      transform: placement.transform,
      drawBand: placement.drawBand,
      stableOrderKey: placement.stableOrderKey,
    );
    final locked = BorderSlotOverride(
      slotKey: placement.slotKey,
      variationSalt: BorderSignedInt64.zero,
      suppressed: false,
      locked: true,
      lockedPlacement: moved,
    );
    final resolved = resolveLedgeLineBorderWithEvidence(
      _Fixture(overrides: [locked]).request,
    );
    expect(resolved.result.canApply, isFalse);
    expect(resolved.edges, isEmpty);
  });
}

final class _Fixture {
  _Fixture({
    List<GridPos> points = const [GridPos(x: 3, y: 3), GridPos(x: 4, y: 3)],
    BorderLineSide lineSide = BorderLineSide.primary,
    List<BorderPublishedPrimitive>? primitives,
    List<BorderSlotOverride> overrides = const [],
    BorderGenerationParams? parameters,
    List<BorderKeepOutRegion> keepOut = const [],
    BorderJumpBehavior? jumpBehavior,
    List<BorderStroke>? strokes,
    GridSize mapSize = const GridSize(width: 12, height: 12),
  }) {
    final selected =
        primitives ??
        [
          for (final orientation in BorderPrimitiveOrientation.values.where(
            (o) => o != BorderPrimitiveOrientation.legacyAxis,
          ))
            _primitive(orientation.name, orientation),
        ];
    definition = BorderBlueprintPublishedDefinition(
      name: 'Rebord natif',
      previewSeed: BorderSignedInt64.fromInt(1),
      template: BorderBlueprintTemplate.ledgeLine,
      primitives: selected,
      defaults: parameters ?? _parameters(),
      sortOrder: 0,
      jumpBehavior: jumpBehavior,
    );
    request = BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: 'ledge',
      blueprintRevision: BorderBlueprintRevision(
        revision: 1,
        definition: definition,
      ),
      feature: BorderFeature(
        id: 'feature',
        name: 'Rebord',
        blueprintId: 'ledge',
        seed: BorderSignedInt64.fromInt(7),
        geometry: BorderStrokeGeometry(
          alignment: BorderStrokeAlignment.gridEdges,
          strokes: strokes ?? [_stroke(points)],
        ),
        lineSide: lineSide,
        overrides: overrides,
        keepOutRegions: keepOut,
      ),
      visualSnapshots: [for (final p in selected) _snapshot(p)],
      resolverVersion: borderResolverVersion,
    );
  }
  late final BorderResolutionRequest request;
  late final BorderBlueprintPublishedDefinition definition;
}

BorderStroke _stroke(List<GridPos> points, {String id = 'main'}) =>
    BorderStroke(
      id: buildBorderPreservedStrokeIdV1(
        authoredStrokeId: id,
        sourceEdgeOffset: 0,
        wrapLength: null,
        orderedPoints: points,
      ),
      points: points,
      closed: false,
    );
BorderGenerationParams _parameters({
  int depthRows = 1,
  int irregularity = 0,
  bool autoRotation = false,
  int variation = 1000,
}) => BorderGenerationParams(
  irregularityPermille: irregularity,
  detailDensityPermille: 0,
  variationPermille: variation,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: depthRows,
  allowAutoRotation: autoRotation,
);
BorderPublishedPrimitive _primitive(
  String id,
  BorderPrimitiveOrientation orientation, {
  GridSize size = const GridSize(width: 32, height: 32),
  BorderPixelPos anchor = const BorderPixelPos(x: 11, y: 23),
  bool flip = false,
  List<int> turns = const [0],
  int weight = 1,
}) => BorderPublishedPrimitive(
  id: id,
  sourceElementId: 'element-$id',
  visualSnapshotId:
      'border-snapshot-sha256:${_pixelFingerprint(id, orientation, size)}',
  role: BorderPrimitiveRole.structureLarge,
  authoredOrientation: orientation,
  weight: weight,
  anchorPx: anchor,
  transforms: BorderTransformPolicy(
    allowFlipX: flip,
    allowedQuarterTurns: turns,
  ),
  publishedMetrics: BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-$id',
    pixelSize: size,
    opaqueBounds: _opaque(orientation, size),
    defaultAnchorPx: anchor,
    occupancyMaskRle: encodeBorderRleMask([
      for (var y = 0; y < size.height; y++)
        for (var x = 0; x < size.width; x++)
          orientation == BorderPrimitiveOrientation.east
              ? x >= 16
              : orientation == BorderPrimitiveOrientation.west
              ? x < 16
              : orientation == BorderPrimitiveOrientation.north
              ? y < 16
              : y >= 16,
    ]),
  ),
);
BorderVisualSnapshot _snapshot(BorderPublishedPrimitive p) {
  final hash = p.visualSnapshotId.substring('border-snapshot-sha256:'.length);
  return BorderVisualSnapshot(
    id: p.visualSnapshotId,
    contentFingerprint: hash,
    frames: [
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$hash.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: p.publishedMetrics.pixelSize.width,
          height: p.publishedMetrics.pixelSize.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

BorderSlotOverride _override(
  String slot, {
  String? replacement,
  int salt = 0,
  bool suppressed = false,
  BorderPixelOffset? offset,
  BorderSpriteTransform? transform,
}) => BorderSlotOverride(
  slotKey: slot,
  variationSalt: BorderSignedInt64.fromInt(salt),
  suppressed: suppressed,
  locked: false,
  replacementPrimitiveId: replacement,
  offsetDeltaPx: offset,
  transformOverride: transform,
);
BorderBlueprintRecord _record(BorderBlueprintPublishedDefinition definition) =>
    BorderBlueprintRecord(
      id: 'ledge',
      draft: BorderBlueprintDraft(
        baseRevision: 1,
        definition: BorderBlueprintDraftDefinition(
          name: definition.name,
          previewSeed: definition.previewSeed,
          template: definition.template,
          defaults: definition.defaults,
          sortOrder: 0,
          jumpBehavior: definition.jumpBehavior,
          primitives: [
            for (final p in definition.primitives)
              BorderPrimitiveDraft(
                id: p.id,
                sourceElementId: p.sourceElementId,
                role: p.role,
                authoredOrientation: p.authoredOrientation,
                weight: p.weight,
                anchorPx: p.anchorPx,
                transforms: p.transforms,
                currentMetrics: p.publishedMetrics,
              ),
          ],
        ),
      ),
      latestPublished: BorderBlueprintRevision(
        revision: 1,
        definition: definition,
      ),
    );
ProjectManifest _project(_Fixture fixture) => ProjectManifest(
  name: 'Ledge reference',
  version: ProjectVersion.v8,
  maps: const [],
  tilesets: const [],
  elements: [
    for (final p in fixture.definition.primitives)
      ProjectElementEntry(
        id: p.sourceElementId!,
        name: p.id,
        tilesetId: 'sheet',
        categoryId: 'ledge',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
  ],
);
Map<String, BorderVisualSnapshotIntegrity> _integrity(_Fixture fixture) => {
  for (final s in fixture.request.visualSnapshots)
    s.id: BorderVisualSnapshotIntegrity(
      snapshotId: s.id,
      metadataValid: true,
      filesPresent: true,
      contentFingerprintMatches: true,
    ),
};

BorderPixelRect _opaque(
  BorderPrimitiveOrientation orientation,
  GridSize size,
) => switch (orientation) {
  BorderPrimitiveOrientation.east => BorderPixelRect(
    x: 16,
    y: 0,
    width: size.width - 16,
    height: size.height,
  ),
  BorderPrimitiveOrientation.west => BorderPixelRect(
    x: 0,
    y: 0,
    width: 16,
    height: size.height,
  ),
  BorderPrimitiveOrientation.north => BorderPixelRect(
    x: 0,
    y: 0,
    width: size.width,
    height: 16,
  ),
  _ => BorderPixelRect(
    x: 0,
    y: 16,
    width: size.width,
    height: size.height - 16,
  ),
};

MapData _map(BorderFeature feature) => MapData(
  id: 'map',
  name: 'Ledge map',
  version: ProjectVersion.v8,
  size: const GridSize(width: 12, height: 12),
  layers: [
    MapLayer.border(
      id: 'border',
      name: 'Rebords',
      content: BorderLayerContent(features: [feature], formatVersion: 3),
    ),
  ],
);

Uint8List _pixels(
  String id,
  BorderPrimitiveOrientation orientation,
  GridSize size,
) {
  final marker = sha256.convert(utf8.encode(id)).bytes.first;
  return Uint8List.fromList([
    for (var y = 0; y < size.height; y++)
      for (var x = 0; x < size.width; x++) ...[
        marker,
        x,
        y,
        (orientation == BorderPrimitiveOrientation.east
                ? x >= 16
                : orientation == BorderPrimitiveOrientation.west
                ? x < 16
                : orientation == BorderPrimitiveOrientation.north
                ? y < 16
                : y >= 16)
            ? 255
            : 0,
      ],
  ]);
}

String _pixelFingerprint(
  String id,
  BorderPrimitiveOrientation orientation,
  GridSize size,
) => computeBorderSnapshotContentFingerprint(
  frames: [
    BorderSnapshotContentFrame(
      sourceRectPx: BorderPixelRect(
        x: 0,
        y: 0,
        width: size.width,
        height: size.height,
      ),
      durationMs: 100,
      rgbaBytes: _pixels(id, orientation, size),
    ),
  ],
);

BorderPublishedPrimitive _gappedPrimitive(
  String id,
  BorderPrimitiveOrientation orientation,
) {
  final original = _primitive(id, orientation);
  final rgba = _pixels(id, orientation, const GridSize(width: 32, height: 32));
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      final tangent =
          orientation == BorderPrimitiveOrientation.north ||
              orientation == BorderPrimitiveOrientation.south
          ? x
          : y;
      if (tangent >= 12 && tangent < 20) {
        rgba[(y * 32 + x) * 4 + 3] = 0;
      }
    }
  }
  final hash = computeBorderSnapshotContentFingerprint(
    frames: [
      BorderSnapshotContentFrame(
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
        durationMs: 100,
        rgbaBytes: rgba,
      ),
    ],
  );
  return BorderPublishedPrimitive(
    id: original.id,
    sourceElementId: original.sourceElementId,
    visualSnapshotId: 'border-snapshot-sha256:$hash',
    role: original.role,
    authoredOrientation: original.authoredOrientation,
    weight: original.weight,
    anchorPx: original.anchorPx,
    transforms: original.transforms,
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: original.publishedMetrics.assetFingerprint,
      pixelSize: original.publishedMetrics.pixelSize,
      opaqueBounds: original.publishedMetrics.opaqueBounds,
      defaultAnchorPx: original.publishedMetrics.defaultAnchorPx,
      occupancyMaskRle: encodeBorderRleMask([
        for (var pixel = 0; pixel < 1024; pixel++) rgba[pixel * 4 + 3] != 0,
      ]),
    ),
  );
}

BorderMaterialization _reseal(
  BorderMaterialization source,
  List<BorderResolvedPlacement> placements,
) => BorderMaterialization(
  receipt: BorderResolutionReceipt(
    resolverVersion: source.receipt.resolverVersion,
    blueprintRevision: source.receipt.blueprintRevision,
    components: source.receipt.components,
    inputFingerprint: source.receipt.inputFingerprint,
    outputFingerprint: computeBorderOutputFingerprint(
      ground: const [],
      placements: placements,
    ),
  ),
  ground: const [],
  placements: placements,
);
