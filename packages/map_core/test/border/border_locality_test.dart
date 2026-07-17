import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';
import '../fixtures/border/organic_edge_reference_coast_fixture.dart';
import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('Border dirty halo', () {
    test('computes the approved request pixel radius', () {
      final request = MasonryLineFixture(
        parameters: masonryParameters(
          irregularityPermille: 1000,
          maxOverlapPx: 3,
          gapTolerancePx: 2,
          depthRows: 2,
        ),
      ).request;

      expect(computeBorderDirtyHaloRadiusForRequestPx(request), 53);
    });

    test('covers old and new move bounds plus their connecting corridor', () {
      final request = MasonryLineFixture().request;
      final oldBounds = BorderPixelRect(x: 0, y: 20, width: 10, height: 8);
      final newBounds = BorderPixelRect(x: 200, y: 20, width: 10, height: 8);
      final edit = BorderLocalEdit.forManualMove(
        oldOpaqueBoundsPx: oldBounds,
        newOpaqueBoundsPx: newBounds,
      );

      final halo = computeBorderDirtyHalo(
        request: request,
        edits: <BorderLocalEdit>[edit],
      );

      expect(
          edit.sourceBoundsPx,
          containsAll(<BorderPixelRect>[
            oldBounds,
            newBounds,
          ]));
      expect(halo.intersects(oldBounds), isTrue);
      expect(halo.intersects(newBounds), isTrue);
      expect(
        halo.intersects(
          BorderPixelRect(x: 104, y: 22, width: 2, height: 2),
        ),
        isTrue,
        reason: 'the swept corridor must be dirty between both positions',
      );
      expect(
        halo.intersects(
          BorderPixelRect(x: 260, y: 22, width: 2, height: 2),
        ),
        isFalse,
      );
    });

    test('converts paint or erase cells to canonical pixel bounds', () {
      final edit = BorderLocalEdit.forCells(
        cells: const <GridPos>[
          GridPos(x: 4, y: 5),
          GridPos(x: 2, y: 3),
          GridPos(x: 4, y: 5),
        ],
        tileSizePx: const GridSize(width: 16, height: 12),
      );

      expect(edit.sourceBoundsPx, <BorderPixelRect>[
        BorderPixelRect(x: 32, y: 36, width: 16, height: 12),
        BorderPixelRect(x: 64, y: 60, width: 16, height: 12),
      ]);
    });

    test('derives one stable namespace across nested stroke fragments', () {
      expect(borderStrokeLineageNamespaceV1('wall'), 'wall');
      expect(borderStrokeLineageNamespaceV1('wall__fragment_2'), 'wall');
      expect(
        borderStrokeLineageNamespaceV1(
          'wall__fragment_2__fragment_3',
        ),
        'wall',
      );
      expect(
        borderStrokeLineageNamespaceV1('wall__fragment_custom'),
        'wall__fragment_custom',
      );

      final lattice = buildBorderLinearLatticeV1(
        stroke: _horizontalStroke('wall__fragment_2', 4, 6, y: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      expect(lattice.strokeId, 'wall__fragment_2');
      expect(lattice.lineageNamespace, 'wall');

      const preservedPoints = <GridPos>[
        GridPos(x: 4, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 2, y: 2),
      ];
      final preservedStroke = BorderStroke(
        id: buildBorderPreservedStrokeIdV1(
          authoredStrokeId: 'wall__fragment_2',
          sourceEdgeOffset: 17,
          wrapLength: null,
          orderedPoints: preservedPoints,
        ),
        points: preservedPoints,
        closed: false,
      );
      final preserved = buildBorderLinearLatticeV1(
        stroke: preservedStroke,
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      expect(preserved.strokeId, 'wall__fragment_2');
      expect(preserved.persistedStrokeId, preservedStroke.id);
      expect(preserved.lineageNamespace, 'wall');
      expect(preserved.preservesTraversal, isTrue);
      expect(preserved.sourceEdgeOffset, 17);
      expect(preserved.edges.first.direction, BorderCardinalDirection.west);
      expect(preserved.edges.first.generationEdgeIndex, 17);

      final invalidMarker = BorderStroke(
        id: '${preservedStroke.id.substring(0, preservedStroke.id.length - 1)}'
            '${preservedStroke.id.endsWith('0') ? '1' : '0'}',
        points: preservedPoints,
        closed: false,
      );
      expect(
        () => buildBorderLinearLatticeV1(
          stroke: invalidMarker,
          tileSizePx: const GridSize(width: 16, height: 16),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('composes source offsets across nested open and wrapped erases', () {
      final firstOpenErase = BorderStrokeEditingDraft.begin(
        baseGeometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _horizontalStroke('wall', 2, 34, y: 4),
          ],
        ),
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 18, y: 4),
      ).previewGeometry!;
      final nestedOpenErase = BorderStrokeEditingDraft.begin(
        baseGeometry: firstOpenErase,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 25, y: 4),
      ).previewGeometry!;
      final openIdentities = nestedOpenErase.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        openIdentities.map((identity) => identity.authoredStrokeId),
        <String>[
          'wall',
          'wall__fragment_2',
          'wall__fragment_2__fragment_2',
        ],
      );
      expect(
        openIdentities.map((identity) => identity.lineageNamespace),
        everyElement('wall'),
      );
      expect(
        openIdentities.map((identity) => identity.sourceEdgeOffset),
        <int>[0, 17, 24],
      );
      expect(
        nestedOpenErase.strokes.map(
          (stroke) => buildBorderLinearLatticeV1(
            stroke: stroke,
            tileSizePx: const GridSize(width: 16, height: 16),
          ).edges.first.generationEdgeIndex,
        ),
        <int>[0, 17, 24],
      );

      final openedLoop = BorderStrokeEditingDraft.begin(
        baseGeometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[_largeClosedLoopStroke('loop')],
        ),
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 20, y: 2),
      ).previewGeometry!;
      final openedPoints = openedLoop.strokes.single.points;
      final nestedWrappedErase = BorderStrokeEditingDraft.begin(
        baseGeometry: openedLoop,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: openedPoints[60],
      ).previewGeometry!;
      final wrappedIdentities = nestedWrappedErase.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        wrappedIdentities.map((identity) => identity.authoredStrokeId),
        <String>['loop', 'loop__fragment_2'],
      );
      expect(
        wrappedIdentities.map((identity) => identity.sourceEdgeOffset),
        <int>[19, 80],
      );
      expect(
        wrappedIdentities.map((identity) => identity.wrapLength),
        everyElement(108),
      );
      expect(
        nestedWrappedErase.strokes.map(
          (stroke) => buildBorderLinearLatticeV1(
            stroke: stroke,
            tileSizePx: const GridSize(width: 16, height: 16),
          ).edges.first.generationEdgeIndex,
        ),
        <int>[19, 80],
      );
    });
  });

  group('Border local regeneration', () {
    test('paint and erase reuse byte-identical distant placements', () {
      final fixture = OrganicEdgeReferenceCoastFixture();
      final baseRequest = fixture.referenceCoastRequest();
      final baseGeometry = baseRequest.feature.geometry as BorderRegionGeometry;
      final paintedCells = baseGeometry.cells.toList(growable: false);
      paintedCells[0] = true;
      final paintedRequest = _copyRequestWithGeometry(
        baseRequest,
        BorderRegionGeometry(
          width: baseGeometry.width,
          height: baseGeometry.height,
          cells: paintedCells,
        ),
      );
      final baseState = resolveBorderFeatureLocalBaseline(baseRequest);
      final paintedState = resolveBorderFeatureLocalBaseline(paintedRequest);
      final baseResult = baseState.result;
      final paintedResult = paintedState.result;
      expect(baseResult.canApply, isTrue);
      expect(paintedResult.canApply, isTrue);

      for (final scenario in <({
        String name,
        BorderResolutionRequest request,
        BorderLocalResolutionState previousState,
      })>[
        (
          name: 'paint',
          request: paintedRequest,
          previousState: baseState,
        ),
        (
          name: 'erase',
          request: baseRequest,
          previousState: paintedState,
        ),
      ]) {
        final local = resolveBorderFeatureLocally(
          request: scenario.request,
          previousState: scenario.previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 0, y: 0)],
              tileSizePx: scenario.request.tileSizePx,
            ),
          ],
        );
        final full = resolveBorderFeature(scenario.request);

        expect(local.result, full, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          isNotEmpty,
          reason: scenario.name,
        );
        expect(local.recomputedSourceCells, isNotEmpty, reason: scenario.name);
        final previousBySlot = <String, BorderResolvedPlacement>{
          for (final placement
              in scenario.previousState.materialization.placements)
            placement.slotKey: placement,
        };
        final localBySlot = <String, BorderResolvedPlacement>{
          for (final placement in local.result.materialization!.placements)
            placement.slotKey: placement,
        };
        for (final slotKey in local.reusedDistantPlacementSlotKeys) {
          final previous = previousBySlot[slotKey]!;
          final retained = localBySlot[slotKey]!;
          expect(retained, same(previous), reason: '$scenario.name:$slotKey');
          expect(retained.id, previous.id);
          expect(retained.slotKey, previous.slotKey);
          expect(retained.stableOrderKey, previous.stableOrderKey);
          expect(retained.primitiveId, previous.primitiveId);
          expect(retained.visualSnapshotId, previous.visualSnapshotId);
          expect(_placementBytes(retained), _placementBytes(previous));
          expect(
            local.recomputedSourceCells,
            isNot(contains(retained.anchorCell)),
            reason: 'distant source branch must not run: $slotKey',
          );
        }
      }
    });

    test('chains local baselines without a complete intermediate solve', () {
      final fixture = OrganicEdgeReferenceCoastFixture();
      final baseRequest = fixture.referenceCoastRequest();
      final baseGeometry = baseRequest.feature.geometry as BorderRegionGeometry;
      final paintedCells = baseGeometry.cells.toList(growable: false);
      paintedCells[0] = true;
      final paintedRequest = _copyRequestWithGeometry(
        baseRequest,
        BorderRegionGeometry(
          width: baseGeometry.width,
          height: baseGeometry.height,
          cells: paintedCells,
        ),
      );
      final edit = BorderLocalEdit.forCells(
        cells: const <GridPos>[GridPos(x: 0, y: 0)],
        tileSizePx: baseRequest.tileSizePx,
      );
      final initialState = resolveBorderFeatureLocalBaseline(baseRequest);

      final painted = resolveBorderFeatureLocally(
        request: paintedRequest,
        previousState: initialState,
        edits: <BorderLocalEdit>[edit],
      );
      expect(painted.result, resolveBorderFeature(paintedRequest));
      expect(painted.nextState, isNotNull);

      final erased = resolveBorderFeatureLocally(
        request: baseRequest,
        previousState: painted.nextState!,
        edits: <BorderLocalEdit>[edit],
      );
      expect(erased.result, resolveBorderFeature(baseRequest));
      expect(erased.nextState, isNotNull);
      expect(erased.reusedDistantPlacementSlotKeys, isNotEmpty);
    });

    test('placement-only forced anchors do not discard distant ground', () {
      final request =
          OrganicEdgeReferenceCoastFixture().referenceCoastRequest();
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final previous = previousState.materialization;
      final groundCoordinates = <(int, int)>{
        for (final cell in previous.ground) (cell.x, cell.y),
      };
      final radius = computeBorderDirtyHaloRadiusForRequestPx(request);
      late final BorderResolvedPlacement target;
      late final BorderPixelRect probe;
      for (final placement in previous.placements) {
        final anchor = BorderPixelRect(
          x: placement.anchorCell.x * request.tileSizePx.width,
          y: placement.anchorCell.y * request.tileSizePx.height,
          width: request.tileSizePx.width,
          height: request.tileSizePx.height,
        );
        if (!groundCoordinates.contains(
          (placement.anchorCell.x, placement.anchorCell.y),
        )) {
          continue;
        }
        final opaque = placement.opaqueWorldBoundsPx;
        if (opaque.x < anchor.x) {
          target = placement;
          probe = BorderPixelRect(
            x: anchor.x - radius - 1,
            y: opaque.y,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.right > anchor.right) {
          target = placement;
          probe = BorderPixelRect(
            x: anchor.right + radius,
            y: opaque.y,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.y < anchor.y) {
          target = placement;
          probe = BorderPixelRect(
            x: opaque.x,
            y: anchor.y - radius - 1,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.bottom > anchor.bottom) {
          target = placement;
          probe = BorderPixelRect(
            x: opaque.x,
            y: anchor.bottom + radius,
            width: 1,
            height: 1,
          );
          break;
        }
      }
      final edit = BorderLocalEdit.forManualMove(
        oldOpaqueBoundsPx: probe,
        newOpaqueBoundsPx: probe,
      );
      final halo = computeBorderDirtyHalo(
        request: request,
        edits: <BorderLocalEdit>[edit],
      );
      final anchorBounds = BorderPixelRect(
        x: target.anchorCell.x * request.tileSizePx.width,
        y: target.anchorCell.y * request.tileSizePx.height,
        width: request.tileSizePx.width,
        height: request.tileSizePx.height,
      );
      expect(halo.intersects(target.opaqueWorldBoundsPx), isTrue);
      expect(halo.intersects(anchorBounds), isFalse);

      final local = resolveBorderFeatureLocally(
        request: request,
        previousState: previousState,
        edits: <BorderLocalEdit>[edit],
      );
      final full = resolveBorderFeature(request);

      expect(local.result, full);
      expect(local.recomputedSourceCells, contains(target.anchorCell));
      expect(
        local.reusedDistantGroundCoordinates,
        contains((target.anchorCell.x, target.anchorCell.y)),
      );
    });

    test('manual move changes only swept-halo subproblems', () {
      final baseRequest = PostAndRailLineFixture(
        mapSize: const GridSize(width: 30, height: 8),
        strokes: <BorderStroke>[_horizontalStroke('main', 1, 25, y: 4)],
        parameters: fenceParameters(maxOverlapPx: 8, gapTolerancePx: 8),
      ).request;
      final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
      final before = beforeState.materialization;
      final target = before.placements.firstWhere(
        (placement) => placement.anchorCell.x == 13,
      );
      final movedRequest = _copyRequestWithOverrides(
        baseRequest,
        <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            offsetDeltaPx: const BorderPixelOffset(x: 8, y: -4),
          ),
        ],
      );
      final full = resolveBorderFeature(movedRequest);
      expect(
        full.canApply,
        isTrue,
        reason: full.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      final moved = full.materialization!.placements.singleWhere(
        (placement) => placement.slotKey == target.slotKey,
      );
      expect(moved.opaqueWorldBoundsPx, isNot(target.opaqueWorldBoundsPx));

      final local = resolveBorderFeatureLocally(
        request: movedRequest,
        previousState: beforeState,
        edits: <BorderLocalEdit>[
          BorderLocalEdit.forManualMove(
            oldOpaqueBoundsPx: target.opaqueWorldBoundsPx,
            newOpaqueBoundsPx: moved.opaqueWorldBoundsPx,
          ),
        ],
      );

      expect(local.result, full);
      expect(
        local.reusedDistantPlacementSlotKeys,
        isNot(contains(target.slotKey)),
      );
      expect(local.recomputedSourceCells, contains(target.anchorCell));
      expect(local.reusedDistantPlacementSlotKeys, isNotEmpty);
      final beforeBySlot = <String, BorderResolvedPlacement>{
        for (final placement in before.placements) placement.slotKey: placement,
      };
      for (final placement in local.result.materialization!.placements) {
        if (local.reusedDistantPlacementSlotKeys.contains(placement.slotKey)) {
          expect(placement, same(beforeBySlot[placement.slotKey]));
        }
      }
    });

    test('retains distant suppressed override base evidence', () {
      final longStroke = _horizontalStroke('main', 2, 34, y: 4);
      final masonrySource = MasonryLineFixture().request;
      final scenarios = <({
        String name,
        BorderResolutionRequest request,
        GridPos editCell,
      })>[
        (
          name: 'organic',
          request: OrganicEdgeReferenceCoastFixture().referenceCoastRequest(),
          editCell: const GridPos(x: 0, y: 0),
        ),
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[longStroke]),
            const GridSize(width: 40, height: 8),
          ),
          editCell: const GridPos(x: 2, y: 4),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 40, height: 8),
            strokes: <BorderStroke>[longStroke],
          ).request,
          editCell: const GridPos(x: 2, y: 4),
        ),
      ];

      for (final scenario in scenarios) {
        final unsuppressed = resolveBorderFeature(scenario.request);
        expect(unsuppressed.canApply, isTrue, reason: scenario.name);
        final edit = BorderLocalEdit.forCells(
          cells: <GridPos>[scenario.editCell],
          tileSizePx: scenario.request.tileSizePx,
        );
        final halo = computeBorderDirtyHalo(
          request: scenario.request,
          edits: <BorderLocalEdit>[edit],
        );
        final target = unsuppressed.materialization!.placements.firstWhere(
          (placement) =>
              !halo.intersects(placement.opaqueWorldBoundsPx) &&
              !halo.intersects(
                BorderPixelRect(
                  x: placement.anchorCell.x * scenario.request.tileSizePx.width,
                  y: placement.anchorCell.y *
                      scenario.request.tileSizePx.height,
                  width: scenario.request.tileSizePx.width,
                  height: scenario.request.tileSizePx.height,
                ),
              ),
        );
        final suppressedRequest = _copyRequestWithOverrides(
          scenario.request,
          <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: target.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
          ],
        );
        final previousState = resolveBorderFeatureLocalBaseline(
          suppressedRequest,
        );
        expect(
          previousState.materialization.placements
              .map((placement) => placement.slotKey),
          isNot(contains(target.slotKey)),
          reason: scenario.name,
        );
        expect(
          previousState.basePlacements.map((placement) => placement.slotKey),
          contains(target.slotKey),
          reason: scenario.name,
        );

        final local = resolveBorderFeatureLocally(
          request: suppressedRequest,
          previousState: previousState,
          edits: <BorderLocalEdit>[edit],
        );
        final full = resolveBorderFeature(suppressedRequest);

        expect(local.result, full, reason: scenario.name);
        expect(
          local.result.diagnostics.map((diagnostic) => diagnostic.code),
          isNot(contains('border.resolution.override_orphaned')),
          reason: scenario.name,
        );
        expect(
          local.recomputedSourceCells,
          isNot(contains(target.anchorCell)),
          reason: '${scenario.name}: suppressed distant branch must not run',
        );
      }
    });

    test('rejects global input changes against a local baseline', () {
      final request = MasonryLineFixture().request;
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final changedSeed = _copyRequestWithSeed(
        request,
        BorderSignedInt64.fromInt(999),
      );

      expect(
        () => resolveBorderFeatureLocally(
          request: changedSeed,
          previousState: previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 2, y: 2)],
              tileSizePx: request.tileSizePx,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('connected side inversion requires a full resolution', () {
      final request = MasonryLineFixture(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPublishedPrimitive>[
          masonryPrimitive(
            id: 'cap',
            fingerprintCharacter: 'a',
            role: BorderPrimitiveRole.lineCap,
            allowFlipX: true,
          ),
          masonryPrimitive(
            id: 'straight',
            fingerprintCharacter: 'b',
            role: BorderPrimitiveRole.lineStraight,
            allowFlipX: true,
          ),
          masonryPrimitive(
            id: 'corner',
            fingerprintCharacter: 'c',
            role: BorderPrimitiveRole.lineCorner,
            allowFlipX: true,
          ),
        ],
      ).request;
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final invertedRequest = BorderResolutionRequest(
        mapSize: request.mapSize,
        tileSizePx: request.tileSizePx,
        blueprintId: request.blueprintId,
        blueprintRevision: request.blueprintRevision,
        feature: toggleBorderFeatureLineSide(request.feature),
        visualSnapshots: request.visualSnapshots,
        resolverVersion: request.resolverVersion,
      );

      expect(resolveBorderFeature(invertedRequest).canApply, isTrue);
      expect(
        () => resolveBorderFeatureLocally(
          request: invertedRequest,
          previousState: previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 1, y: 3)],
              tileSizePx: request.tileSizePx,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects override changes outside the declared edit halo', () {
      final request = PostAndRailLineFixture(
        mapSize: const GridSize(width: 40, height: 8),
        strokes: <BorderStroke>[
          _horizontalStroke('main', 2, 34, y: 4),
        ],
      ).request;
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final target = previousState.materialization.placements.firstWhere(
        (placement) => placement.anchorCell.x >= 25,
      );
      final changed = _copyRequestWithOverrides(
        request,
        <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
          ),
        ],
      );

      expect(
        () => resolveBorderFeatureLocally(
          request: changed,
          previousState: previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 2, y: 4)],
              tileSizePx: request.tileSizePx,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('linear erase keeps distant fragments in their lineage namespace', () {
      final stroke = _horizontalStroke('wall', 2, 34, y: 4);
      final masonrySource = MasonryLineFixture().request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 40, height: 8),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 40, height: 8),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 18, y: 4),
        ).previewGeometry!;
        final identities = erasedGeometry.strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .toList(growable: false);
        expect(
          identities.map((identity) => identity.authoredStrokeId),
          <String>['wall', 'wall__fragment_2'],
          reason: scenario.name,
        );
        expect(
          identities.map((identity) => identity.sourceEdgeOffset),
          <int>[0, 17],
          reason: scenario.name,
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        late final List<String> evidenceStrokeIds;
        late final int evidenceEdgeCount;
        if (scenario.name == 'masonry') {
          final evidence = resolveMasonryLineBorderWithEvidence(erasedRequest);
          evidenceStrokeIds = evidence.edges
              .map((edge) => edge.strokeId)
              .toList(growable: false);
          evidenceEdgeCount = evidence.edges.length;
        } else {
          final evidence =
              resolvePostAndRailLineBorderWithEvidence(erasedRequest);
          evidenceStrokeIds = evidence.edges
              .map((edge) => edge.strokeId)
              .toList(growable: false);
          evidenceEdgeCount = evidence.edges.length;
        }
        expect(evidenceEdgeCount, 30, reason: scenario.name);
        expect(
          evidenceStrokeIds.toSet(),
          <String>{'wall', 'wall__fragment_2'},
          reason: scenario.name,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 18, y: 4)],
              tileSizePx: erasedRequest.tileSizePx,
            ),
          ],
        );

        expect(local.result, full, reason: scenario.name);
        final distantRight = before.placements.where(
          (placement) => placement.anchorCell.x >= 25,
        );
        expect(distantRight, isNotEmpty, reason: scenario.name);
        final localBySlot = <String, BorderResolvedPlacement>{
          for (final placement in local.result.materialization!.placements)
            placement.slotKey: placement,
        };
        for (final placement in distantRight) {
          expect(
            local.reusedDistantPlacementSlotKeys,
            contains(placement.slotKey),
            reason: scenario.name,
          );
          expect(
            localBySlot[placement.slotKey],
            same(placement),
            reason: scenario.name,
          );
          expect(
            _placementBytes(localBySlot[placement.slotKey]!),
            _placementBytes(placement),
            reason: scenario.name,
          );
          expect(
            local.recomputedSourceCells,
            isNot(contains(placement.anchorCell)),
            reason: '${scenario.name}: distant source branch must not run',
          );
        }
      }
    });

    test('curved split preserves a canonically reversed distant fragment', () {
      final stroke = _reversingSplitStroke('wall');
      final masonrySource = MasonryLineFixture(
        parameters: masonryParameters(gapTolerancePx: 5),
      ).request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 44, height: 24),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 44, height: 24),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 20, y: 12),
        ).previewGeometry!;
        final identities = erasedGeometry.strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .toList(growable: false);
        expect(
          identities.map((identity) => identity.authoredStrokeId),
          <String>['wall', 'wall__fragment_2'],
          reason: scenario.name,
        );
        expect(
          erasedGeometry.strokes.last.points.first,
          const GridPos(x: 20, y: 13),
          reason: 'the detached fragment must retain source traversal',
        );
        expect(
          canonicalizeBorderStrokeV1(
            id: 'probe',
            sampledPoints: erasedGeometry.strokes.last.points,
            closed: false,
          ).points.first,
          const GridPos(x: 38, y: 4),
          reason: 'ordinary canonicalization would reverse this fragment',
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final edit = BorderLocalEdit.forCells(
          cells: const <GridPos>[GridPos(x: 20, y: 12)],
          tileSizePx: erasedRequest.tileSizePx,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[edit],
        );

        expect(local.result, full, reason: scenario.name);
        final distantSlots = before.placements
            .where(
              (placement) =>
                  placement.anchorCell.x >= 30 &&
                  placement.anchorCell.y >= 18 &&
                  !local.dirtyHalo.intersects(
                    placement.opaqueWorldBoundsPx,
                  ),
            )
            .map((placement) => placement.slotKey)
            .toList(growable: false);
        expect(distantSlots, isNotEmpty, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          containsAll(distantSlots),
          reason: scenario.name,
        );
        final beforeBySlot = <String, BorderResolvedPlacement>{
          for (final placement in before.placements)
            placement.slotKey: placement,
        };
        expect(
          local.recomputedSourceCells,
          isNot(contains(beforeBySlot[distantSlots.first]!.anchorCell)),
          reason: '${scenario.name}: distant curve branch must not run',
        );
      }
    });

    test('opening a closed loop preserves its distant perimeter', () {
      final stroke = _largeClosedLoopStroke('wall');
      final masonrySource = MasonryLineFixture(
        parameters: masonryParameters(gapTolerancePx: 7),
      ).request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 44, height: 24),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 44, height: 24),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 20, y: 2),
        ).previewGeometry!;
        expect(erasedGeometry.strokes, hasLength(1), reason: scenario.name);
        final identity = resolveBorderStrokeLineageIdentityV1(
          erasedGeometry.strokes.single,
        );
        expect(identity.authoredStrokeId, 'wall', reason: scenario.name);
        expect(identity.sourceEdgeOffset, 19, reason: scenario.name);
        expect(identity.wrapLength, 108, reason: scenario.name);
        expect(erasedGeometry.strokes.single.closed, isFalse);
        expect(
          erasedGeometry.strokes.single.points.first,
          const GridPos(x: 21, y: 2),
          reason: 'opening must retain the closed source traversal',
        );
        expect(
          canonicalizeBorderStrokeV1(
            id: 'probe',
            sampledPoints: erasedGeometry.strokes.single.points,
            closed: false,
          ).points.first,
          const GridPos(x: 19, y: 2),
          reason: 'ordinary canonicalization would reverse the opened loop',
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final edit = BorderLocalEdit.forCells(
          cells: const <GridPos>[GridPos(x: 20, y: 2)],
          tileSizePx: erasedRequest.tileSizePx,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[edit],
        );

        expect(local.result, full, reason: scenario.name);
        final distantSlots = before.placements
            .where(
              (placement) =>
                  placement.anchorCell.y >= 18 &&
                  !local.dirtyHalo.intersects(
                    placement.opaqueWorldBoundsPx,
                  ),
            )
            .map((placement) => placement.slotKey)
            .toList(growable: false);
        expect(distantSlots, isNotEmpty, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          containsAll(distantSlots),
          reason: scenario.name,
        );
        final beforeBySlot = <String, BorderResolvedPlacement>{
          for (final placement in before.placements)
            placement.slotKey: placement,
        };
        expect(
          local.recomputedSourceCells,
          isNot(contains(beforeBySlot[distantSlots.first]!.anchorCell)),
          reason: '${scenario.name}: distant loop branch must not run',
        );
      }
    });
  });
}

BorderResolutionRequest _copyRequestWithGeometry(
  BorderResolutionRequest source,
  BorderFeatureGeometry geometry,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolutionRequest _copyRequestWithGeometryAndMapSize(
  BorderResolutionRequest source,
  BorderFeatureGeometry geometry,
  GridSize mapSize,
) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

String _placementBytes(BorderResolvedPlacement placement) =>
    jsonEncode(encodeBorderResolvedPlacementJson(placement));

BorderResolutionRequest _copyRequestWithOverrides(
  BorderResolutionRequest source,
  List<BorderSlotOverride> overrides,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolutionRequest _copyRequestWithSeed(
  BorderResolutionRequest source,
  BorderSignedInt64 seed,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderStroke _horizontalStroke(
  String id,
  int fromX,
  int toX, {
  required int y,
}) =>
    BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = fromX; x <= toX; x += 1) GridPos(x: x, y: y),
      ],
      closed: false,
    );

BorderStroke _reversingSplitStroke(String id) => BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = 2; x <= 20; x += 1) GridPos(x: x, y: 2),
        for (var y = 3; y <= 20; y += 1) GridPos(x: 20, y: y),
        for (var x = 21; x <= 38; x += 1) GridPos(x: x, y: 20),
        for (var y = 19; y >= 4; y -= 1) GridPos(x: 38, y: y),
      ],
      closed: false,
    );

BorderStroke _largeClosedLoopStroke(String id) => BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = 2; x <= 38; x += 1) GridPos(x: x, y: 2),
        for (var y = 3; y <= 20; y += 1) GridPos(x: 38, y: y),
        for (var x = 37; x >= 2; x -= 1) GridPos(x: x, y: 20),
        for (var y = 19; y >= 3; y -= 1) GridPos(x: 2, y: y),
      ],
      closed: true,
    );
