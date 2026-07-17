import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const String _snapshotId = 'border-snapshot-sha256:'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _hashA =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _hashB =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('resizeBorderLayerContent regions', () {
    test('crops region and several keep-outs without translating or reordering',
        () {
      final firstKeepOut = BorderKeepOutRegion(
        id: 'keep-z',
        region: _region(
          4,
          3,
          const <bool>[
            false,
            true,
            true,
            false,
            true,
            false,
            false,
            true,
            false,
            true,
            false,
            false,
          ],
        ),
      );
      final secondKeepOut = BorderKeepOutRegion(
        id: 'keep-a',
        region: _region(
          4,
          3,
          const <bool>[
            true,
            false,
            false,
            true,
            false,
            true,
            true,
            false,
            true,
            false,
            false,
            false,
          ],
        ),
      );
      final feature = _feature(
        id: 'feature-z',
        blueprintId: 'organic-edge-blueprint',
        lineSide: BorderLineSide.inverted,
        geometry: _region(
          4,
          3,
          const <bool>[
            true,
            false,
            true,
            false,
            false,
            true,
            false,
            true,
            true,
            true,
            false,
            false,
          ],
        ),
        keepOutRegions: <BorderKeepOutRegion>[firstKeepOut, secondKeepOut],
      );
      final trailing = _feature(
        id: 'feature-a',
        geometry: _region(4, 3, List<bool>.filled(12, false)),
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          formatVersion: BorderLayerContent.formatVersionV2,
          features: <BorderFeature>[feature, trailing],
        ),
        oldMapSize: const GridSize(width: 4, height: 3),
        newMapSize: const GridSize(width: 2, height: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isTrue);
      expect(result.diagnosticReport.hasErrors, isFalse);
      final resized = result.content!;
      expect(resized.features.map((value) => value.id), <String>[
        'feature-z',
        'feature-a',
      ]);
      final resizedFeature = resized.features.first;
      expect(resized.formatVersion, BorderLayerContent.formatVersionV2);
      expect(resizedFeature.lineSide, BorderLineSide.inverted);
      expect(
        (resizedFeature.geometry as BorderRegionGeometry).cells,
        const <bool>[true, false, false, true],
      );
      expect(
        resizedFeature.keepOutRegions.map((value) => value.id),
        <String>['keep-z', 'keep-a'],
      );
      expect(
        resizedFeature.keepOutRegions[0].region.cells,
        const <bool>[false, true, true, false],
      );
      expect(
        resizedFeature.keepOutRegions[1].region.cells,
        const <bool>[true, false, false, true],
      );
      final cropDiagnostics = result.diagnosticReport.diagnostics
          .where((diagnostic) => diagnostic.code.contains('cell_clipped'))
          .toList(growable: false);
      expect(cropDiagnostics, isNotEmpty);
      expect(
        cropDiagnostics.every(
          (diagnostic) => diagnostic.phase == BorderDiagnosticPhase.resize,
        ),
        isTrue,
      );
      expect(
        cropDiagnostics.every(
          (diagnostic) => diagnostic.parameters['layerId'] == 'border-main',
        ),
        isTrue,
      );
      expect(cropDiagnostics.every((diagnostic) => diagnostic.cell != null),
          isTrue);
    });

    test('pads region and several keep-outs with false cells', () {
      final content = BorderLayerContent(
        features: <BorderFeature>[
          _feature(
            geometry: _region(
              2,
              2,
              const <bool>[true, false, false, true],
            ),
            keepOutRegions: <BorderKeepOutRegion>[
              BorderKeepOutRegion(
                id: 'keep-z',
                region: _region(
                  2,
                  2,
                  const <bool>[false, true, true, false],
                ),
              ),
              BorderKeepOutRegion(
                id: 'keep-a',
                region: _region(2, 2, List<bool>.filled(4, false)),
              ),
            ],
          ),
        ],
      );

      final result = resizeBorderLayerContent(
        content: content,
        oldMapSize: const GridSize(width: 2, height: 2),
        newMapSize: const GridSize(width: 4, height: 3),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isTrue);
      final feature = result.content!.features.single;
      expect(
        (feature.geometry as BorderRegionGeometry).cells,
        const <bool>[
          true,
          false,
          false,
          false,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      );
      expect(
        feature.keepOutRegions.first.region.cells,
        const <bool>[
          false,
          true,
          false,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      );
      final paddingDiagnostics = result.diagnosticReport.diagnostics
          .where((diagnostic) => diagnostic.code.contains('padding'))
          .toList(growable: false);
      expect(paddingDiagnostics, hasLength(3));
      expect(
        paddingDiagnostics.map((diagnostic) => diagnostic.cell).toSet(),
        <GridPos>{const GridPos(x: 2, y: 0)},
      );
    });

    test('rejects mismatched region and keep-out dimensions atomically', () {
      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(2, 2, List<bool>.filled(4, false)),
              keepOutRegions: <BorderKeepOutRegion>[
                BorderKeepOutRegion(
                  id: 'bad-keep-out',
                  region: _region(3, 2, List<bool>.filled(6, false)),
                ),
              ],
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 3, height: 3),
        newMapSize: const GridSize(width: 2, height: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isFalse);
      expect(result.content, isNull);
      expect(result.diagnosticReport.errorCount, 2);
      expect(
        result.diagnosticReport.diagnostics.map((value) => value.code),
        containsAll(<String>[
          'region_size_mismatch',
          'keep_out_region_size_mismatch',
        ]),
      );
    });

    test('validates positive bounded map and tile sizes before allocation', () {
      final content = BorderLayerContent(
        features: <BorderFeature>[
          _feature(geometry: _region(1, 1, const <bool>[true])),
        ],
      );

      for (final sizes in <(GridSize, GridSize, GridSize)>[
        (
          const GridSize(width: 0, height: 1),
          const GridSize(width: 1, height: 1),
          const GridSize(width: 16, height: 16),
        ),
        (
          const GridSize(width: 1, height: 1),
          const GridSize(width: 8193, height: 1),
          const GridSize(width: 16, height: 16),
        ),
        (
          const GridSize(width: 1, height: 1),
          const GridSize(width: 1, height: 1),
          const GridSize(width: 0, height: 16),
        ),
      ]) {
        final result = resizeBorderLayerContent(
          content: content,
          oldMapSize: sizes.$1,
          newMapSize: sizes.$2,
          tileSizePx: sizes.$3,
          layerId: 'border-main',
        );
        expect(result.canApply, isFalse);
        expect(result.content, isNull);
        expect(result.diagnosticReport.hasErrors, isTrue);
      }
    });
  });

  group('resizeBorderLayerContent strokes', () {
    test('preserves untouched stroke objects, ids, order, points, and closed',
        () {
      final open = BorderStroke(
        id: 'stroke-z',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
        ],
        closed: false,
      );
      final closed = BorderStroke(
        id: 'stroke-a',
        points: const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 0, y: 2),
        ],
        closed: true,
      );
      final geometry =
          BorderStrokeGeometry(strokes: <BorderStroke>[open, closed]);

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[_feature(geometry: geometry)],
        ),
        oldMapSize: const GridSize(width: 4, height: 4),
        newMapSize: const GridSize(width: 3, height: 3),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isTrue);
      final resizedGeometry =
          result.content!.features.single.geometry as BorderStrokeGeometry;
      expect(resizedGeometry, same(geometry));
      expect(
          resizedGeometry.strokes, orderedEquals(<BorderStroke>[open, closed]));
      expect(resizedGeometry.strokes[0], same(open));
      expect(resizedGeometry.strokes[1], same(closed));
    });

    for (final blueprintId in <String>[
      'masonry-line-blueprint',
      'post-and-rail-line-blueprint',
    ]) {
      test('clips and splits $blueprintId with stable collision-free ids', () {
        final untouched = BorderStroke(
          id: 'wall__fragment_2',
          points: const <GridPos>[
            GridPos(x: 0, y: 4),
            GridPos(x: 1, y: 4),
          ],
          closed: false,
        );
        final result = resizeBorderLayerContent(
          content: BorderLayerContent(
            features: <BorderFeature>[
              _feature(
                blueprintId: blueprintId,
                geometry: BorderStrokeGeometry(
                  strokes: <BorderStroke>[
                    BorderStroke(
                      id: 'wall',
                      points: const <GridPos>[
                        GridPos(x: 0, y: 0),
                        GridPos(x: 1, y: 0),
                        GridPos(x: 2, y: 0),
                        GridPos(x: 3, y: 0),
                        GridPos(x: 4, y: 0),
                        GridPos(x: 4, y: 1),
                        GridPos(x: 4, y: 2),
                        GridPos(x: 3, y: 2),
                        GridPos(x: 2, y: 2),
                        GridPos(x: 1, y: 2),
                      ],
                      closed: false,
                    ),
                    untouched,
                  ],
                ),
              ),
            ],
          ),
          oldMapSize: const GridSize(width: 5, height: 5),
          newMapSize: const GridSize(width: 4, height: 5),
          tileSizePx: const GridSize(width: 16, height: 16),
          layerId: 'border-main',
        );

        expect(result.canApply, isTrue);
        final geometry =
            result.content!.features.single.geometry as BorderStrokeGeometry;
        final identities = geometry.strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .toList(growable: false);
        expect(
          identities.map((identity) => identity.authoredStrokeId),
          <String>['wall', 'wall__fragment_3', 'wall__fragment_2'],
        );
        expect(
          identities.take(2).map((identity) => identity.sourceEdgeOffset),
          <int>[0, 7],
        );
        expect(
          geometry.strokes[0].points,
          const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 3, y: 0),
          ],
        );
        expect(
          geometry.strokes[1].points,
          const <GridPos>[
            GridPos(x: 3, y: 2),
            GridPos(x: 2, y: 2),
            GridPos(x: 1, y: 2),
          ],
        );
        expect(geometry.strokes[2], same(untouched));
        expect(
          result.diagnosticReport.diagnostics.map((value) => value.code),
          containsAll(<String>['stroke_points_clipped', 'stroke_split']),
        );
        expect(
          result.diagnosticReport.diagnostics.every(
            (diagnostic) =>
                diagnostic.phase == BorderDiagnosticPhase.resize &&
                diagnostic.scope == BorderDiagnosticScope.stroke &&
                diagnostic.featureId == 'feature' &&
                diagnostic.strokeId == 'wall' &&
                diagnostic.cell == const GridPos(x: 4, y: 0) &&
                diagnostic.parameters['layerId'] == 'border-main' &&
                diagnostic.suggestedAction.startsWith('border.resize.'),
          ),
          isTrue,
        );
      });
    }

    test('removes too-short fragments and converts a clipped loop to open', () {
      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: BorderStrokeGeometry(
                strokes: <BorderStroke>[
                  BorderStroke(
                    id: 'short-tail',
                    points: const <GridPos>[
                      GridPos(x: 0, y: 0),
                      GridPos(x: 1, y: 0),
                      GridPos(x: 2, y: 0),
                      GridPos(x: 3, y: 0),
                      GridPos(x: 4, y: 0),
                      GridPos(x: 4, y: 1),
                      GridPos(x: 4, y: 2),
                      GridPos(x: 3, y: 2),
                      GridPos(x: 2, y: 2),
                    ],
                    closed: false,
                  ),
                  BorderStroke(
                    id: 'loop',
                    points: const <GridPos>[
                      GridPos(x: 1, y: 3),
                      GridPos(x: 2, y: 3),
                      GridPos(x: 3, y: 3),
                      GridPos(x: 3, y: 4),
                      GridPos(x: 3, y: 5),
                      GridPos(x: 2, y: 5),
                      GridPos(x: 1, y: 5),
                      GridPos(x: 1, y: 4),
                    ],
                    closed: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 5, height: 6),
        newMapSize: const GridSize(width: 3, height: 6),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isTrue);
      final strokes =
          (result.content!.features.single.geometry as BorderStrokeGeometry)
              .strokes;
      expect(
        strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .map((identity) => identity.authoredStrokeId),
        <String>['short-tail', 'loop'],
      );
      expect(
        strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .map((identity) => identity.sourceEdgeOffset),
        <int>[0, 5],
      );
      expect(
        resolveBorderStrokeLineageIdentityV1(strokes.last).wrapLength,
        8,
      );
      expect(
        strokes.first.points,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
        ],
      );
      expect(strokes.last.closed, isFalse);
      expect(
        strokes.last.points,
        const <GridPos>[
          GridPos(x: 2, y: 5),
          GridPos(x: 1, y: 5),
          GridPos(x: 1, y: 4),
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
        ],
      );
      final diagnostics = result.diagnosticReport.diagnostics;
      expect(
        diagnostics.map((value) => value.code),
        containsAll(<String>[
          'stroke_fragment_too_short',
          'stroke_closed_to_open',
        ]),
      );
      expect(
        diagnostics.every(
          (diagnostic) =>
              diagnostic.cell != null &&
              diagnostic.featureId == 'feature' &&
              diagnostic.strokeId != null &&
              diagnostic.parameters['layerId'] == 'border-main',
        ),
        isTrue,
      );
    });

    test('does not regenerate or replace an unaffected materialization', () {
      final materialization = _materialization(
        ground: <BorderResolvedGroundCell>[_ground(0, 0)],
        placements: const <BorderResolvedPlacement>[],
      );
      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: BorderStrokeGeometry(
                strokes: <BorderStroke>[
                  BorderStroke(
                    id: 'wall',
                    points: const <GridPos>[
                      GridPos(x: 0, y: 0),
                      GridPos(x: 1, y: 0),
                      GridPos(x: 2, y: 0),
                    ],
                    closed: false,
                  ),
                ],
              ),
              materialization: materialization,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 3, height: 2),
        newMapSize: const GridSize(width: 2, height: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isTrue);
      expect(
        result.content!.features.single.materialization,
        same(materialization),
      );
      expect(
        result.content!.features.single.materialization!.receipt,
        same(materialization.receipt),
      );
    });
  });

  group('resizeBorderLayerContent materialization', () {
    test('same-size is identity and does not rehash materialization output',
        () {
      final forgedMaterialization = BorderMaterialization(
        receipt: _receipt(outputFingerprint: _hashB),
        ground: <BorderResolvedGroundCell>[_ground(0, 0)],
        placements: const <BorderResolvedPlacement>[],
      );
      final content = BorderLayerContent(
        features: <BorderFeature>[
          _feature(
            geometry: _region(1, 1, const <bool>[true]),
            materialization: forgedMaterialization,
          ),
        ],
      );

      final result = resizeBorderLayerContent(
        content: content,
        oldMapSize: const GridSize(width: 1, height: 1),
        newMapSize: const GridSize(width: 1, height: 1),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isTrue);
      expect(result.content, same(content));
      expect(result.diagnosticReport.hasDiagnostics, isFalse);
      expect(
        result.content!.features.single.materialization,
        same(forgedMaterialization),
      );
    });

    test(
        'keeps inside and partial placements but culls anchor and bounds cases',
        () {
      final inside = _placement(
        id: 'inside',
        order: 0,
        anchor: const GridPos(x: 0, y: 0),
        bounds: BorderPixelRect(x: 0, y: 0, width: 10, height: 10),
      );
      final partial = _placement(
        id: 'partial',
        order: 1,
        anchor: const GridPos(x: 2, y: 2),
        bounds: BorderPixelRect(x: 40, y: 40, width: 16, height: 16),
      );
      final anchorOutside = _placement(
        id: 'anchor-outside',
        order: 2,
        anchor: const GridPos(x: 3, y: 1),
        bounds: BorderPixelRect(x: 10, y: 10, width: 10, height: 10),
      );
      final boundsOutside = _placement(
        id: 'bounds-outside',
        order: 3,
        anchor: const GridPos(x: 1, y: 1),
        bounds: BorderPixelRect(x: 48, y: 0, width: 10, height: 10),
      );
      final edgeTouch = _placement(
        id: 'edge-touch',
        order: 4,
        anchor: const GridPos(x: 1, y: 1),
        bounds: BorderPixelRect(x: -10, y: 0, width: 10, height: 10),
      );
      final materialization = _materialization(
        ground: <BorderResolvedGroundCell>[
          _ground(0, 0),
          _ground(2, 2),
          _ground(3, 2),
        ],
        placements: <BorderResolvedPlacement>[
          inside,
          partial,
          anchorOutside,
          boundsOutside,
          edgeTouch,
        ],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(4, 3, List<bool>.filled(12, false)),
              materialization: materialization,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 4, height: 3),
        newMapSize: const GridSize(width: 3, height: 3),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isTrue);
      final resized = result.content!.features.single.materialization!;
      expect(resized.ground.map((value) => (value.x, value.y)), <(int, int)>[
        (0, 0),
        (2, 2),
      ]);
      expect(
        resized.placements.map((value) => value.id),
        <String>['inside', 'partial'],
      );
      expect(resized.placements[0], same(inside));
      expect(resized.placements[1], same(partial));
      expect(
        result.diagnosticReport.diagnostics
            .where((value) => value.code == 'placement_anchor_out_of_bounds'),
        hasLength(1),
      );
      expect(
        result.diagnosticReport.diagnostics
            .where((value) => value.code == 'placement_bounds_out_of_bounds'),
        hasLength(2),
      );
    });

    test('invalid source output fingerprint blocks before culling', () {
      final ground = <BorderResolvedGroundCell>[_ground(4, 0)];
      final materialization = BorderMaterialization(
        receipt: _receipt(outputFingerprint: _hashB),
        ground: ground,
        placements: const <BorderResolvedPlacement>[],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(5, 1, List<bool>.filled(5, false)),
              materialization: materialization,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 5, height: 1),
        newMapSize: const GridSize(width: 2, height: 1),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isFalse);
      expect(result.content, isNull);
      expect(
        result.diagnosticReport.diagnostics.single.code,
        'materialization_output_fingerprint_mismatch',
      );
    });

    test('non-portable source output integers block before any resize', () {
      final materialization = BorderMaterialization(
        receipt: _receipt(outputFingerprint: _hashA),
        ground: <BorderResolvedGroundCell>[
          _ground(9007199254740992, 0),
        ],
        placements: const <BorderResolvedPlacement>[],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(2, 1, const <bool>[false, false]),
              materialization: materialization,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 2, height: 1),
        newMapSize: const GridSize(width: 1, height: 1),
        tileSizePx: const GridSize(width: 16, height: 16),
        layerId: 'border-main',
      );

      expect(result.canApply, isFalse);
      expect(result.content, isNull);
      expect(
        result.diagnosticReport.diagnostics.single.code,
        'materialization_output_fingerprint_invalid',
      );
    });

    test('partial culling changes only the output fingerprint and keeps order',
        () {
      final first = _placement(
        id: 'first',
        order: 7,
        anchor: const GridPos(x: 0, y: 0),
        bounds: BorderPixelRect(x: 0, y: 0, width: 10, height: 10),
      );
      final removed = _placement(
        id: 'removed',
        order: 99,
        anchor: const GridPos(x: 3, y: 0),
        bounds: BorderPixelRect(x: 48, y: 0, width: 10, height: 10),
      );
      final source = _materialization(
        ground: <BorderResolvedGroundCell>[_ground(0, 0)],
        placements: <BorderResolvedPlacement>[first, removed],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(4, 2, List<bool>.filled(8, false)),
              materialization: source,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 4, height: 2),
        newMapSize: const GridSize(width: 2, height: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      final resized = result.content!.features.single.materialization!;
      expect(resized.placements.single, same(first));
      expect(resized.placements.single.stableOrderKey.anchorRowMajor, 7);
      expect(resized.receipt, isNot(same(source.receipt)));
      expect(resized.receipt.resolverVersion, source.receipt.resolverVersion);
      expect(
          resized.receipt.blueprintRevision, source.receipt.blueprintRevision);
      expect(resized.receipt.components, same(source.receipt.components));
      expect(resized.receipt.inputFingerprint, source.receipt.inputFingerprint);
      expect(
        resized.receipt.outputFingerprint,
        computeBorderOutputFingerprint(
          ground: resized.ground,
          placements: resized.placements,
        ),
      );
      expect(
        resized.receipt.outputFingerprint,
        isNot(source.receipt.outputFingerprint),
      );
    });

    test('reuses an unchanged materialization and receipt by identity', () {
      final source = _materialization(
        ground: <BorderResolvedGroundCell>[_ground(0, 0)],
        placements: <BorderResolvedPlacement>[
          _placement(
            id: 'inside',
            order: 100,
            anchor: const GridPos(x: 0, y: 0),
            bounds: BorderPixelRect(x: -2, y: -2, width: 8, height: 8),
          ),
        ],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(3, 3, List<bool>.filled(9, false)),
              materialization: source,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 3, height: 3),
        newMapSize: const GridSize(width: 2, height: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      final resized = result.content!.features.single.materialization!;
      expect(resized, same(source));
      expect(resized.receipt, same(source.receipt));
    });

    test('removes materialization when ground and placements become empty', () {
      final source = _materialization(
        ground: <BorderResolvedGroundCell>[_ground(2, 0)],
        placements: <BorderResolvedPlacement>[
          _placement(
            id: 'outside',
            order: 0,
            anchor: const GridPos(x: 2, y: 0),
            bounds: BorderPixelRect(x: 32, y: 0, width: 10, height: 10),
          ),
        ],
      );

      final result = resizeBorderLayerContent(
        content: BorderLayerContent(
          features: <BorderFeature>[
            _feature(
              geometry: _region(3, 1, List<bool>.filled(3, false)),
              materialization: source,
            ),
          ],
        ),
        oldMapSize: const GridSize(width: 3, height: 1),
        newMapSize: const GridSize(width: 2, height: 1),
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isTrue);
      expect(result.content!.features.single.materialization, isNull);
    });
  });

  group('resizeMapDataWithBorderDiagnostics', () {
    test('a map without Border is exactly the legacy resize result', () {
      final source = _legacyMap();
      final legacy = resizeMapData(source, width: 2, height: 2);

      final result = resizeMapDataWithBorderDiagnostics(
        source,
        width: 2,
        height: 2,
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isTrue);
      expect(result.diagnosticReport.hasDiagnostics, isFalse);
      expect(result.map, legacy);
      expect(jsonEncode(result.map), jsonEncode(legacy));
    });

    test('same-size calls return the original map identity', () {
      final source = _mapWithBorder(
        feature: _feature(
          geometry: _region(3, 3, List<bool>.filled(9, false)),
        ),
      );

      expect(resizeMapData(source, width: 3, height: 3), same(source));
      final result = resizeMapDataWithBorderDiagnostics(
        source,
        width: 3,
        height: 3,
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      expect(result.canApply, isTrue);
      expect(result.map, same(source));
    });

    test('legacy API refuses a changed-size Border map with migration hint',
        () {
      final source = _mapWithBorder(
        feature: _feature(
          geometry: _region(3, 3, List<bool>.filled(9, false)),
        ),
      );

      expect(
        () => resizeMapData(source, width: 2, height: 2),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('resizeMapDataWithBorderDiagnostics'),
          ),
        ),
      );
    });

    test('preflights every Border layer and refuses the whole map atomically',
        () {
      final valid = _feature(
        id: 'valid',
        geometry: _region(3, 3, List<bool>.filled(9, false)),
      );
      final invalid = _feature(
        id: 'invalid',
        geometry: _region(2, 3, List<bool>.filled(6, false)),
      );
      final source = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border-valid',
            name: 'Valid',
            content: BorderLayerContent(features: <BorderFeature>[valid]),
          ),
          MapLayer.border(
            id: 'border-invalid',
            name: 'Invalid',
            content: BorderLayerContent(features: <BorderFeature>[invalid]),
          ),
        ],
      );

      final result = resizeMapDataWithBorderDiagnostics(
        source,
        width: 2,
        height: 2,
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(result.canApply, isFalse);
      expect(result.map, isNull);
      expect(
        result.diagnosticReport.diagnostics.single.parameters['layerId'],
        'border-invalid',
      );
    });

    test('resized Border map round-trips through JSON', () {
      final source = _mapWithBorder(
        feature: _feature(
          geometry: _region(3, 3, const <bool>[
            true,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
          ]),
        ),
      );

      final result = resizeMapDataWithBorderDiagnostics(
        source,
        width: 2,
        height: 2,
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      final encoded = jsonEncode(result.map);
      final decoded = MapData.fromJson(
        jsonDecode(encoded)! as Map<String, dynamic>,
      );
      expect(decoded, result.map);
    });

    for (final target in <GridSize>[
      const GridSize(width: 2, height: 2),
      const GridSize(width: 4, height: 4),
    ]) {
      test(
          'keeps Collision and unrelated layers byte-equivalent to legacy at '
          '${target.width}x${target.height}', () {
        final source = _mapWithCollisionLayersAndBorder();
        final sourceBytes = jsonEncode(source);
        final withoutBorder = source.copyWith(
          version: ProjectVersion.v1,
          layers: source.layers
              .where((layer) => layer is! BorderLayer)
              .toList(growable: false),
        );
        final legacy = resizeMapData(
          withoutBorder,
          width: target.width,
          height: target.height,
        );

        final result = resizeMapDataWithBorderDiagnostics(
          source,
          width: target.width,
          height: target.height,
          tileSizePx: const GridSize(width: 16, height: 16),
        );

        expect(result.canApply, isTrue);
        expect(jsonEncode(source), sourceBytes);
        final resized = result.map!;
        final resizedUnrelated = resized.layers
            .where((layer) => layer is! BorderLayer)
            .toList(growable: false);
        expect(jsonEncode(resizedUnrelated), jsonEncode(legacy.layers));
        final resizedCollision =
            resized.layers.whereType<CollisionLayer>().toList(growable: false);
        final legacyCollision =
            legacy.layers.whereType<CollisionLayer>().toList(growable: false);
        expect(resizedCollision, legacyCollision);
        expect(jsonEncode(resizedCollision), jsonEncode(legacyCollision));
        expect(resized.placedElements, legacy.placedElements);
        expect(
          resized.placedElements.map((value) => value.applyCollision),
          legacy.placedElements.map((value) => value.applyCollision),
        );
        expect(
          jsonEncode(resized.placedElements),
          jsonEncode(legacy.placedElements),
        );
      });
    }
  });
}

BorderRegionGeometry _region(int width, int height, List<bool> cells) =>
    BorderRegionGeometry(width: width, height: height, cells: cells);

BorderFeature _feature({
  String id = 'feature',
  String blueprintId = 'blueprint',
  BorderLineSide lineSide = BorderLineSide.primary,
  required BorderFeatureGeometry geometry,
  List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
  BorderMaterialization? materialization,
}) =>
    BorderFeature(
      id: id,
      name: 'Feature $id',
      blueprintId: blueprintId,
      seed: BorderSignedInt64.zero,
      geometry: geometry,
      lineSide: lineSide,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: keepOutRegions,
      materialization: materialization,
    );

BorderResolvedGroundCell _ground(int x, int y) => BorderResolvedGroundCell(
      x: x,
      y: y,
      visualSnapshotId: _snapshotId,
      resolvedRole: SurfaceVariantRole.isolated,
    );

BorderResolvedPlacement _placement({
  required String id,
  required int order,
  required GridPos anchor,
  required BorderPixelRect bounds,
}) =>
    BorderResolvedPlacement(
      id: id,
      slotKey: 'slot-$id',
      primitiveId: 'primitive',
      visualSnapshotId: _snapshotId,
      anchorCell: anchor,
      topLeftWorldPx: BorderPixelPos(x: bounds.x, y: bounds.y),
      opaqueWorldBoundsPx: bounds,
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: 1,
        anchorRowMajor: order,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: 'slot-$id',
      ),
    );

BorderInputFingerprints _components() => BorderInputFingerprints(
      blueprint: _hashA,
      geometryAndSeed: _hashA,
      parameters: _hashA,
      overrides: _hashA,
      keepOutRegions: _hashA,
      mapContext: _hashA,
      visualSnapshots: _hashA,
    );

BorderResolutionReceipt _receipt({required String outputFingerprint}) =>
    BorderResolutionReceipt(
      resolverVersion: 1,
      blueprintRevision: 1,
      components: _components(),
      inputFingerprint: _hashA,
      outputFingerprint: outputFingerprint,
    );

BorderMaterialization _materialization({
  required List<BorderResolvedGroundCell> ground,
  required List<BorderResolvedPlacement> placements,
}) =>
    BorderMaterialization(
      receipt: _receipt(
        outputFingerprint: computeBorderOutputFingerprint(
          ground: ground,
          placements: placements,
        ),
      ),
      ground: ground,
      placements: placements,
    );

MapData _mapWithBorder({required BorderFeature feature}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
      ],
    );

MapData _legacyMap() => MapData(
      id: 'legacy',
      name: 'Legacy',
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tiles: List<int>.generate(9, (index) => index + 1),
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.generate(9, (index) => index.isEven),
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'inside',
          layerId: 'tiles',
          elementId: 'element',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
        MapPlacedElement(
          id: 'outside',
          layerId: 'tiles',
          elementId: 'element',
          pos: GridPos(x: 2, y: 2),
          applyCollision: false,
        ),
      ],
    );

MapData _mapWithCollisionLayersAndBorder() => MapData(
      id: 'mixed',
      name: 'Mixed',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          tiles: List<int>.generate(9, (index) => index + 1),
        ),
        MapLayer.collision(
          id: 'collision-before',
          name: 'Before',
          collisions: List<bool>.generate(9, (index) => index.isEven),
        ),
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(
            features: <BorderFeature>[
              _feature(
                geometry: _region(3, 3, List<bool>.filled(9, false)),
              ),
            ],
          ),
        ),
        MapLayer.collision(
          id: 'collision-after',
          name: 'After',
          collisions: List<bool>.generate(9, (index) => index % 3 == 0),
        ),
        const MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'inside-true',
          layerId: 'collision-before',
          elementId: 'element',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
        MapPlacedElement(
          id: 'inside-false',
          layerId: 'collision-after',
          elementId: 'element',
          pos: GridPos(x: 0, y: 0),
          applyCollision: false,
        ),
        MapPlacedElement(
          id: 'crop-away',
          layerId: 'collision-after',
          elementId: 'element',
          pos: GridPos(x: 2, y: 2),
          applyCollision: true,
        ),
      ],
    );
