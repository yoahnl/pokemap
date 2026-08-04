import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_fingerprint_golden.dart';

const String _hexA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _hexB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const String _hexC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const String _snapshotA = 'border-snapshot-sha256:$_hexA';
const String _snapshotB = 'border-snapshot-sha256:$_hexB';
const String _snapshotC = 'border-snapshot-sha256:$_hexC';

void main() {
  test('geometry fingerprint distinguishes grid-edge alignment', () {
    final stroke = BorderStroke(
      id: 'edge',
      points: const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      closed: false,
    );
    String fingerprint(BorderStrokeAlignment alignment) =>
        computeBorderNonVisualInputFingerprints(
          _request(
            template: BorderBlueprintTemplate.stoneChainLine,
            geometry: BorderStrokeGeometry(
              strokes: <BorderStroke>[stroke],
              alignment: alignment,
            ),
            includeGround: false,
          ),
        ).geometryAndSeed;

    expect(
      fingerprint(BorderStrokeAlignment.gridEdges),
      isNot(fingerprint(BorderStrokeAlignment.cellCenters)),
    );
  });

  test('literal JCS preimages independently reproduce all nine goldens', () {
    final vectors = <(String, String)>[
      (
        borderBlueprintCanonicalJsonGolden,
        borderBlueprintFingerprintGolden,
      ),
      (
        borderGeometryAndSeedCanonicalJsonGolden,
        borderGeometryAndSeedFingerprintGolden,
      ),
      (
        borderParametersCanonicalJsonGolden,
        borderParametersFingerprintGolden,
      ),
      (
        borderOverridesCanonicalJsonGolden,
        borderOverridesFingerprintGolden,
      ),
      (
        borderKeepOutRegionsCanonicalJsonGolden,
        borderKeepOutRegionsFingerprintGolden,
      ),
      (
        borderMapContextCanonicalJsonGolden,
        borderMapContextFingerprintGolden,
      ),
      (
        borderVisualSnapshotsCanonicalJsonGolden,
        borderVisualSnapshotsFingerprintGolden,
      ),
      (
        borderAggregateInputCanonicalJsonGolden,
        borderAggregateInputFingerprintGolden,
      ),
      (
        borderOutputCanonicalJsonGolden,
        borderOutputFingerprintGolden,
      ),
    ];

    for (final (preimage, expectedFingerprint) in vectors) {
      expect(
        'sha256:${sha256.convert(utf8.encode(preimage))}',
        expectedFingerprint,
      );
    }

    expect(
      borderBlueprintCanonicalJsonGolden,
      contains('"ground":{"edgeBandCells":2,"visualSnapshotIdsByRole":{'),
    );
    expect(
      borderGeometryAndSeedCanonicalJsonGolden,
      allOf(contains('"kind":"region"'), isNot(contains('"kind":"stroke"'))),
    );
    expect(
      borderOverridesCanonicalJsonGolden,
      contains('"lockedPlacement":null'),
    );
    expect(
      borderVisualSnapshotsCanonicalJsonGolden,
      allOf(contains('"frames":['), contains('"transparentColorArgb":')),
    );
    expect(
      borderAggregateInputCanonicalJsonGolden,
      contains('"components":{"blueprint":'),
    );
    expect(
      borderOutputCanonicalJsonGolden,
      contains('"stableOrderKey":{"anchorRowMajor":'),
    );
  });

  group('Border input fingerprints V1', () {
    test('requires a published blueprint revision', () {
      expect(
        () => computeBorderInputFingerprints(
          _request(includeBlueprintRevision: false),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('returns seven canonical sha256 fingerprints', () {
      final fingerprints = computeBorderInputFingerprints(_request());

      for (final value in <String>[
        fingerprints.blueprint,
        fingerprints.geometryAndSeed,
        fingerprints.parameters,
        fingerprints.overrides,
        fingerprints.keepOutRegions,
        fingerprints.mapContext,
        fingerprints.visualSnapshots,
      ]) {
        expect(value, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
      }

      expect(fingerprints.blueprint, borderBlueprintFingerprintGolden);
      expect(
        fingerprints.geometryAndSeed,
        borderGeometryAndSeedFingerprintGolden,
      );
      expect(fingerprints.parameters, borderParametersFingerprintGolden);
      expect(fingerprints.overrides, borderOverridesFingerprintGolden);
      expect(
        fingerprints.keepOutRegions,
        borderKeepOutRegionsFingerprintGolden,
      );
      expect(fingerprints.mapContext, borderMapContextFingerprintGolden);
      expect(
        fingerprints.visualSnapshots,
        borderVisualSnapshotsFingerprintGolden,
      );
    });

    test('blueprint fingerprint tracks only non-legacy orientation', () {
      final legacy = computeBorderInputFingerprints(_request()).blueprint;
      String oriented(BorderPrimitiveOrientation orientation) =>
          computeBorderInputFingerprints(
            _request(
              primitives: <BorderPublishedPrimitive>[
                _primitive(
                  id: 'b',
                  snapshotId: _snapshotB,
                  authoredOrientation: orientation,
                ),
                _primitive(id: 'a', snapshotId: _snapshotA),
              ],
            ),
          ).blueprint;

      expect(legacy, borderBlueprintFingerprintGolden);
      expect(
        oriented(BorderPrimitiveOrientation.west),
        isNot(oriented(BorderPrimitiveOrientation.north)),
      );
      expect(
        oriented(BorderPrimitiveOrientation.west),
        isNot(legacy),
      );
    });

    test('is independent of insertion order for set-like inputs', () {
      final first = computeBorderInputFingerprints(_request());
      final reordered = computeBorderInputFingerprints(
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(id: 'a', snapshotId: _snapshotA),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
          ground: _ground(reverseInsertion: true),
          overrides: <BorderSlotOverride>[
            _override(slotKey: 'slot-a', salt: BorderSignedInt64.minimum),
            _override(slotKey: 'slot-z', salt: BorderSignedInt64.maximum),
          ],
          keepOutRegions: <BorderKeepOutRegion>[
            _keepOut('a', const <bool>[true, false]),
            _keepOut('z', const <bool>[false, true]),
          ],
          snapshots: <BorderVisualSnapshot>[
            _snapshot(_hexC),
            _snapshot(_hexB),
            _snapshot(_hexA),
          ],
        ),
      );

      expect(reordered, first);
    });

    test('ignores display, draft-source metadata, and unused snapshots', () {
      final first = computeBorderInputFingerprints(_request());
      final changedMetadata = computeBorderInputFingerprints(
        _request(
          definitionName: 'Nom totalement différent',
          previewSeed: BorderSignedInt64.maximum,
          categoryId: 'other-category',
          sortOrder: 999,
          featureName: 'Autre nom',
          primitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a',
              snapshotId: _snapshotA,
              sourceElementId: 'current-source-x',
            ),
            _primitive(
              id: 'b',
              snapshotId: _snapshotB,
              sourceElementId: 'current-source-y',
            ),
          ],
          ground: _ground(sourceSmartTilePresetId: 'current-surface-y'),
          snapshots: <BorderVisualSnapshot>[
            _snapshot(_hexA),
            _snapshot(_hexB),
            _snapshot(
              _hexC,
              durationMs: 999,
              pathSuffix: 'unused-changed.png',
            ),
          ],
        ),
      );

      expect(changedMetadata, first);
    });

    test('uses effective parameters so an equal override is identical', () {
      final defaults = _params();
      final inherited = computeBorderInputFingerprints(
        _request(defaults: defaults, paramsOverride: null),
      );
      final explicit = computeBorderInputFingerprints(
        _request(defaults: defaults, paramsOverride: _params()),
      );
      final changed = computeBorderInputFingerprints(
        _request(
          defaults: defaults,
          paramsOverride: _params(maxOverlapPx: 9007199254740991),
        ),
      );

      expect(explicit.parameters, inherited.parameters);
      expect(changed.parameters, isNot(inherited.parameters));
    });

    test('rotation policy participates in parameter freshness', () {
      final automatic = computeBorderInputFingerprints(
        _request(defaults: _params()),
      );
      final authored = computeBorderInputFingerprints(
        _request(defaults: _params(allowAutoRotation: false)),
      );

      expect(authored.parameters, isNot(automatic.parameters));
      expect(authored.blueprint, isNot(automatic.blueprint));
    });

    test('preserves exact signed int64 seed and salt bounds', () {
      final minimum = computeBorderInputFingerprints(
        _request(
          seed: BorderSignedInt64.minimum,
          overrides: <BorderSlotOverride>[
            _override(slotKey: 'slot-a', salt: BorderSignedInt64.minimum),
          ],
        ),
      );
      final maximum = computeBorderInputFingerprints(
        _request(
          seed: BorderSignedInt64.maximum,
          overrides: <BorderSlotOverride>[
            _override(slotKey: 'slot-a', salt: BorderSignedInt64.maximum),
          ],
        ),
      );

      expect(maximum.geometryAndSeed, isNot(minimum.geometryAndSeed));
      expect(maximum.overrides, isNot(minimum.overrides));
    });

    test('changes the owning component for included input changes', () {
      final base = computeBorderInputFingerprints(_request());

      expect(
        computeBorderInputFingerprints(
          _request(template: BorderBlueprintTemplate.masonryLine),
        ).blueprint,
        isNot(base.blueprint),
      );
      expect(
        computeBorderInputFingerprints(
          _request(seed: BorderSignedInt64.fromInt(99)),
        ).geometryAndSeed,
        isNot(base.geometryAndSeed),
      );
      expect(
        computeBorderInputFingerprints(
          _request(paramsOverride: _params(depthRows: 9)),
        ).parameters,
        isNot(base.parameters),
      );
      expect(
        computeBorderInputFingerprints(
          _request(
            overrides: <BorderSlotOverride>[
              _override(
                slotKey: 'slot-a',
                salt: BorderSignedInt64.fromInt(9),
              ),
            ],
          ),
        ).overrides,
        isNot(base.overrides),
      );
      expect(
        computeBorderInputFingerprints(
          _request(
            keepOutRegions: <BorderKeepOutRegion>[
              _keepOut('a', const <bool>[false, true]),
            ],
          ),
        ).keepOutRegions,
        isNot(base.keepOutRegions),
      );
      expect(
        computeBorderInputFingerprints(
          _request(mapSize: const GridSize(width: 31, height: 20)),
        ).mapContext,
        isNot(base.mapContext),
      );
      expect(
        computeBorderInputFingerprints(
          _request(
            snapshots: <BorderVisualSnapshot>[
              _snapshot(_hexA, durationMs: 101),
              _snapshot(_hexB),
              _snapshot(_hexC),
            ],
          ),
        ).visualSnapshots,
        isNot(base.visualSnapshots),
      );
    });

    test('keeps all six unrelated component fingerprints stable per change',
        () {
      final base = computeBorderInputFingerprints(_request());
      final cases = <(BorderResolutionRequest, int)>[
        (_request(template: BorderBlueprintTemplate.masonryLine), 0),
        (_request(seed: BorderSignedInt64.fromInt(99)), 1),
        (_request(paramsOverride: _params(depthRows: 9)), 2),
        (
          _request(
            overrides: <BorderSlotOverride>[
              _override(
                slotKey: 'slot-a',
                salt: BorderSignedInt64.fromInt(9),
              ),
            ],
          ),
          3,
        ),
        (
          _request(
            keepOutRegions: <BorderKeepOutRegion>[
              _keepOut('a', const <bool>[false, true]),
            ],
          ),
          4,
        ),
        (_request(mapSize: const GridSize(width: 31, height: 20)), 5),
        (
          _request(
            snapshots: <BorderVisualSnapshot>[
              _snapshot(_hexA, durationMs: 101),
              _snapshot(_hexB),
              _snapshot(_hexC),
            ],
          ),
          6,
        ),
      ];

      for (final (request, changedIndex) in cases) {
        final changed = computeBorderInputFingerprints(request);
        final before = _fingerprintComponents(base);
        final after = _fingerprintComponents(changed);
        for (var index = 0; index < before.length; index += 1) {
          expect(after[index],
              index == changedIndex ? isNot(before[index]) : before[index]);
        }
      }
    });

    test('connected line side changes only geometryAndSeed and aggregate', () {
      final primary = computeBorderInputFingerprints(
        _request(
          template: BorderBlueprintTemplate.connectedLine,
          lineSide: BorderLineSide.primary,
        ),
      );
      final inverted = computeBorderInputFingerprints(
        _request(
          template: BorderBlueprintTemplate.connectedLine,
          lineSide: BorderLineSide.inverted,
        ),
      );

      final primaryComponents = _fingerprintComponents(primary);
      final invertedComponents = _fingerprintComponents(inverted);
      for (var index = 0; index < primaryComponents.length; index += 1) {
        expect(
          invertedComponents[index],
          index == 1
              ? isNot(primaryComponents[index])
              : primaryComponents[index],
        );
      }
      expect(
        computeBorderAggregateInputFingerprint(
          resolverVersion: 3,
          blueprintRevision: 2,
          components: inverted,
        ),
        isNot(
          computeBorderAggregateInputFingerprint(
            resolverVersion: 3,
            blueprintRevision: 2,
            components: primary,
          ),
        ),
      );
    });

    test('line side does not alter historical template projections', () {
      final primary = computeBorderInputFingerprints(
        _request(lineSide: BorderLineSide.primary),
      );
      final inverted = computeBorderInputFingerprints(
        _request(lineSide: BorderLineSide.inverted),
      );

      expect(inverted, primary);
      expect(primary.geometryAndSeed, borderGeometryAndSeedFingerprintGolden);
    });

    test('blueprint projection includes every published structural field', () {
      final base = computeBorderInputFingerprints(_request()).blueprint;
      final variants = <BorderResolutionRequest>[
        _request(revisionNumber: 3),
        _request(defaults: _params(gapTolerancePx: 6)),
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a',
              snapshotId: _snapshotA,
              role: BorderPrimitiveRole.accent,
            ),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
        ),
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a',
              snapshotId: _snapshotA,
              transforms: BorderTransformPolicy(
                allowFlipX: true,
                allowedQuarterTurns: <int>[0, 1, 2],
              ),
            ),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
        ),
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(id: 'a', snapshotId: _snapshotA, weight: 699),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
        ),
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a',
              snapshotId: _snapshotA,
              anchorPx: const BorderPixelPos(x: 7, y: 15),
            ),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
        ),
        _request(
          primitives: <BorderPublishedPrimitive>[
            _primitive(
              id: 'a',
              snapshotId: _snapshotA,
              transforms: BorderTransformPolicy(
                allowFlipX: false,
                allowedQuarterTurns: <int>[0, 2],
              ),
            ),
            _primitive(id: 'b', snapshotId: _snapshotB),
          ],
        ),
        for (final metrics in <BorderPrimitiveAssetMetrics>[
          _metrics('a', assetFingerprint: 'changed'),
          _metrics('a', pixelSize: const GridSize(width: 17, height: 20)),
          _metrics(
            'a',
            opaqueBounds: BorderPixelRect(x: 0, y: 2, width: 14, height: 18),
          ),
          _metrics(
            'a',
            defaultAnchorPx: const BorderPixelPos(x: 7, y: 19),
          ),
          _metrics('a', occupancyMaskRle: 'border-rle-v1:1:1:1'),
        ])
          _request(
            primitives: <BorderPublishedPrimitive>[
              _primitive(id: 'a', snapshotId: _snapshotA, metrics: metrics),
              _primitive(id: 'b', snapshotId: _snapshotB),
            ],
          ),
        _request(ground: _ground(edgeBandCells: 3)),
        _request(
          ground: _ground(
            snapshotOverrideRole: BorderGroundVariantRole.cross,
            snapshotOverrideId: _snapshotA,
          ),
        ),
        _request(includeGround: false),
      ];

      for (final variant in variants) {
        expect(computeBorderInputFingerprints(variant).blueprint, isNot(base));
      }
    });

    test('fails closed when published primitive ids are duplicated', () {
      expect(
        () => computeBorderInputFingerprints(
          _request(
            primitives: <BorderPublishedPrimitive>[
              _primitive(id: 'a', snapshotId: _snapshotA),
              _primitive(id: 'a', snapshotId: _snapshotB),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('override projection includes explicit nulls and locked placement',
        () {
      final base = computeBorderInputFingerprints(
        _request(
          overrides: <BorderSlotOverride>[
            _override(slotKey: 'slot-a', salt: BorderSignedInt64.zero),
          ],
        ),
      ).overrides;
      final variants = <BorderSlotOverride>[
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.fromInt(1),
          suppressed: true,
          locked: false,
        ),
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: false,
          replacementPrimitiveId: null,
          offsetDeltaPx: const BorderPixelOffset(x: -2, y: 3),
          transformOverride:
              BorderSpriteTransform(quarterTurns: 2, flipX: true),
        ),
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: false,
          replacementPrimitiveId: 'a',
          offsetDeltaPx: null,
          transformOverride:
              BorderSpriteTransform(quarterTurns: 2, flipX: true),
        ),
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: false,
          replacementPrimitiveId: 'a',
          offsetDeltaPx: const BorderPixelOffset(x: -2, y: 3),
          transformOverride: null,
        ),
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: true,
          lockedPlacement: _placement(
            slotKey: 'slot-a',
            id: 'locked-a',
            visualSnapshotId: _snapshotB,
          ),
        ),
      ];

      for (final variant in variants) {
        expect(
          computeBorderInputFingerprints(
            _request(overrides: <BorderSlotOverride>[variant]),
          ).overrides,
          isNot(base),
        );
      }
    });

    test('snapshot projection includes every ordered frame field', () {
      final base = computeBorderInputFingerprints(_request()).visualSnapshots;
      final frameVariants = <BorderVisualFrameSnapshot>[
        _frame('other.png', durationMs: 100),
        _frame(
          'frame.png',
          durationMs: 100,
          sourceRectPx: BorderPixelRect(x: 2, y: 2, width: 16, height: 16),
        ),
        _frame('frame.png', durationMs: 101),
        _frame('frame.png', durationMs: 100, transparentColorArgb: null),
      ];

      for (final frame in frameVariants) {
        final changed = computeBorderInputFingerprints(
          _request(
            snapshots: <BorderVisualSnapshot>[
              _snapshot(_hexA, frames: <BorderVisualFrameSnapshot>[frame]),
              _snapshot(_hexB),
              _snapshot(_hexC),
            ],
          ),
        ).visualSnapshots;
        expect(changed, isNot(base));
      }
    });

    test('map and geometry projections include every coordinate and dimension',
        () {
      final base = computeBorderInputFingerprints(_request());
      for (final request in <BorderResolutionRequest>[
        _request(mapSize: const GridSize(width: 30, height: 21)),
        _request(tileSizePx: const GridSize(width: 17, height: 16)),
        _request(tileSizePx: const GridSize(width: 16, height: 17)),
      ]) {
        expect(
          computeBorderInputFingerprints(request).mapContext,
          isNot(base.mapContext),
        );
      }
      for (final request in <BorderResolutionRequest>[
        _request(featureId: 'feature-b'),
        _request(
          geometry: BorderRegionGeometry(
            width: 1,
            height: 2,
            cells: const <bool>[true, true],
          ),
        ),
        _request(
          geometry: BorderRegionGeometry(
            width: 2,
            height: 2,
            cells: const <bool>[true, true, true, true],
          ),
        ),
      ]) {
        expect(
          computeBorderInputFingerprints(request).geometryAndSeed,
          isNot(base.geometryAndSeed),
        );
      }
    });

    test('preserves stroke order and frame order', () {
      final firstGeometry = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'a',
            points: const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
            closed: false,
          ),
          BorderStroke(
            id: 'b',
            points: const <GridPos>[GridPos(x: 3, y: 0), GridPos(x: 4, y: 0)],
            closed: false,
          ),
        ],
      );
      final secondGeometry = BorderStrokeGeometry(
        strokes: firstGeometry.strokes.reversed.toList(),
      );
      final frames = <BorderVisualFrameSnapshot>[
        _frame('a.png', durationMs: 80),
        _frame('b.png', durationMs: 120),
      ];

      expect(
        computeBorderInputFingerprints(
          _request(geometry: firstGeometry),
        ).geometryAndSeed,
        isNot(
          computeBorderInputFingerprints(
            _request(geometry: secondGeometry),
          ).geometryAndSeed,
        ),
      );
      expect(
        computeBorderInputFingerprints(
          _request(
            snapshots: <BorderVisualSnapshot>[
              _snapshot(_hexA, frames: frames),
              _snapshot(_hexB),
              _snapshot(_hexC),
            ],
          ),
        ).visualSnapshots,
        isNot(
          computeBorderInputFingerprints(
            _request(
              snapshots: <BorderVisualSnapshot>[
                _snapshot(_hexA, frames: frames.reversed.toList()),
                _snapshot(_hexB),
                _snapshot(_hexC),
              ],
            ),
          ).visualSnapshots,
        ),
      );
    });

    test('rejects every missing referenced visual snapshot', () {
      expect(
        () => computeBorderInputFingerprints(
          _request(snapshots: <BorderVisualSnapshot>[_snapshot(_hexA)]),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('tracks snapshots referenced only by ground or locked placements', () {
      final snapshotsWithoutC = <BorderVisualSnapshot>[
        _snapshot(_hexA),
        _snapshot(_hexB),
      ];
      final groundWithC = _ground(
        snapshotOverrideRole: BorderGroundVariantRole.cross,
        snapshotOverrideId: _snapshotC,
      );
      final lockedWithC = BorderSlotOverride(
        slotKey: 'slot-a',
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(
          slotKey: 'slot-a',
          id: 'locked-a',
          visualSnapshotId: _snapshotC,
        ),
      );

      for (final request in <BorderResolutionRequest>[
        _request(ground: groundWithC, snapshots: snapshotsWithoutC),
        _request(
          overrides: <BorderSlotOverride>[lockedWithC],
          snapshots: snapshotsWithoutC,
        ),
      ]) {
        expect(
          () => computeBorderInputFingerprints(request),
          throwsA(isA<ValidationException>()),
        );
      }

      final sharedReference = computeBorderInputFingerprints(
        _request(
          ground: groundWithC,
          overrides: <BorderSlotOverride>[lockedWithC],
        ),
      ).visualSnapshots;
      final changedC = computeBorderInputFingerprints(
        _request(
          ground: groundWithC,
          overrides: <BorderSlotOverride>[lockedWithC],
          snapshots: <BorderVisualSnapshot>[
            _snapshot(_hexA),
            _snapshot(_hexB),
            _snapshot(_hexC, durationMs: 101),
          ],
        ),
      ).visualSnapshots;
      expect(changedC, isNot(sharedReference));
    });
  });

  group('Border aggregate and output fingerprints V1', () {
    test('aggregate includes versions and all seven components', () {
      final components = computeBorderInputFingerprints(_request());
      final first = computeBorderAggregateInputFingerprint(
        resolverVersion: 1,
        blueprintRevision: 2,
        components: components,
      );
      final changed = computeBorderAggregateInputFingerprint(
        resolverVersion: 2,
        blueprintRevision: 2,
        components: components,
      );

      expect(first, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
      expect(first, borderAggregateInputFingerprintGolden);
      expect(changed, isNot(first));
      expect(
        computeBorderAggregateInputFingerprint(
          resolverVersion: 1,
          blueprintRevision: 3,
          components: components,
        ),
        isNot(first),
      );

      final values = <String>[
        components.blueprint,
        components.geometryAndSeed,
        components.parameters,
        components.overrides,
        components.keepOutRegions,
        components.mapContext,
        components.visualSnapshots,
      ];
      for (var index = 0; index < values.length; index += 1) {
        final changedValues = List<String>.from(values);
        changedValues[index] = 'sha256:$_hexC';
        final variant = BorderInputFingerprints(
          blueprint: changedValues[0],
          geometryAndSeed: changedValues[1],
          parameters: changedValues[2],
          overrides: changedValues[3],
          keepOutRegions: changedValues[4],
          mapContext: changedValues[5],
          visualSnapshots: changedValues[6],
        );
        expect(
          computeBorderAggregateInputFingerprint(
            resolverVersion: 1,
            blueprintRevision: 2,
            components: variant,
          ),
          isNot(first),
        );
      }

      final requestComponents = computeBorderInputFingerprints(_request());
      final otherResolverComponents = computeBorderInputFingerprints(
        BorderResolutionRequest(
          mapSize: const GridSize(width: 30, height: 20),
          tileSizePx: const GridSize(width: 16, height: 16),
          blueprintId: 'blueprint-a',
          blueprintRevision: _request().blueprintRevision,
          feature: _request().feature,
          visualSnapshots: _request().visualSnapshots,
          resolverVersion: 99,
        ),
      );
      expect(otherResolverComponents, requestComponents);
    });

    test('output excludes receipts, preserves both list orders, and is exact',
        () {
      final groundA = _resolvedGround(x: 0, role: BorderGroundVariantRole.endEast);
      final groundB = _resolvedGround(x: 1, role: BorderGroundVariantRole.endWest);
      final placementA = _placement(slotKey: 'slot-a', id: 'placement-a');
      final placementB = _placement(
        slotKey: 'slot-b',
        id: 'placement-b',
        anchorRowMajor: 11,
      );
      final first = computeBorderOutputFingerprint(
        ground: <BorderResolvedGroundCell>[groundA, groundB],
        placements: <BorderResolvedPlacement>[placementA, placementB],
      );

      expect(first, matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
      expect(first, borderOutputFingerprintGolden);
      expect(
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[groundB, groundA],
          placements: <BorderResolvedPlacement>[placementA, placementB],
        ),
        isNot(first),
      );
      expect(
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[groundA, groundB],
          placements: <BorderResolvedPlacement>[placementB, placementA],
        ),
        isNot(first),
      );
      expect(
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[groundA, groundB],
          placements: <BorderResolvedPlacement>[
            _placement(
              slotKey: 'slot-a',
              id: 'placement-a',
              topLeftX: 9007199254740991,
              opaqueX: 9007199254740991,
            ),
            placementB,
          ],
        ),
        isNot(first),
      );
      final outputVariants = <String>[
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[
            BorderResolvedGroundCell(
              x: 0,
              y: 3,
              visualSnapshotId: _snapshotA,
              resolvedRole: BorderGroundVariantRole.endEast,
            ),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[
            BorderResolvedGroundCell(
              x: 0,
              y: 2,
              visualSnapshotId: _snapshotB,
              resolvedRole: BorderGroundVariantRole.endEast,
            ),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
        computeBorderOutputFingerprint(
          ground: <BorderResolvedGroundCell>[
            BorderResolvedGroundCell(
              x: 0,
              y: 2,
              visualSnapshotId: _snapshotA,
              resolvedRole: BorderGroundVariantRole.cross,
            ),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
      ];
      expect(outputVariants.toSet(), hasLength(outputVariants.length));
    });

    test('output placement includes every persisted ordering and visual field',
        () {
      final base = computeBorderOutputFingerprint(
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[
          _placement(slotKey: 'slot-a', id: 'placement-a'),
        ],
      );
      final variants = <BorderResolvedPlacement>[
        _placement(slotKey: 'slot-a', id: 'placement-b'),
        _placement(slotKey: 'slot-b', id: 'placement-a'),
        _placement(slotKey: 'slot-a', id: 'placement-a', primitiveId: 'b'),
        _placement(
          slotKey: 'slot-a',
          id: 'placement-a',
          visualSnapshotId: _snapshotB,
        ),
        _placement(
          slotKey: 'slot-a',
          id: 'placement-a',
          anchorCell: const GridPos(x: 2, y: 2),
        ),
        _placement(slotKey: 'slot-a', id: 'placement-a', topLeftX: 17),
        _placement(slotKey: 'slot-a', id: 'placement-a', topLeftY: 33),
        _placement(slotKey: 'slot-a', id: 'placement-a', opaqueX: 18),
        _placement(slotKey: 'slot-a', id: 'placement-a', opaqueY: 35),
        _placement(slotKey: 'slot-a', id: 'placement-a', opaqueWidth: 13),
        _placement(slotKey: 'slot-a', id: 'placement-a', opaqueHeight: 17),
        _placement(
          slotKey: 'slot-a',
          id: 'placement-a',
          transform: BorderSpriteTransform(quarterTurns: 1, flipX: false),
        ),
        _placement(
          slotKey: 'slot-a',
          id: 'placement-a',
          drawBand: BorderDrawBand.accent,
        ),
        _placement(
          slotKey: 'slot-a',
          id: 'placement-a',
          anchorRowMajor: 11,
        ),
        _placement(slotKey: 'slot-a', id: 'placement-a', passIndex: 2),
        _placement(slotKey: 'slot-a', id: 'placement-a', rank: 3),
        _placement(slotKey: 'slot-a', id: 'placement-a', ordinalLocal: 4),
      ];

      for (final placement in variants) {
        expect(
          computeBorderOutputFingerprint(
            ground: const <BorderResolvedGroundCell>[],
            placements: <BorderResolvedPlacement>[placement],
          ),
          isNot(base),
        );
      }
    });
  });
}

BorderResolutionRequest _request({
  GridSize mapSize = const GridSize(width: 30, height: 20),
  GridSize tileSizePx = const GridSize(width: 16, height: 16),
  bool includeBlueprintRevision = true,
  int revisionNumber = 2,
  List<BorderPublishedPrimitive>? primitives,
  BorderPublishedGround? ground,
  bool includeGround = true,
  BorderGenerationParams? defaults,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  String definitionName = 'Rocky coast',
  BorderSignedInt64? previewSeed,
  String? categoryId = 'nature',
  int sortOrder = 10,
  String featureId = 'feature-a',
  String featureName = 'North coast',
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  BorderLineSide lineSide = BorderLineSide.primary,
  BorderGenerationParams? paramsOverride,
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
  List<BorderVisualSnapshot>? snapshots,
}) {
  final effectivePrimitives = primitives ??
      <BorderPublishedPrimitive>[
        _primitive(id: 'b', snapshotId: _snapshotB),
        _primitive(id: 'a', snapshotId: _snapshotA),
      ];
  final effectiveGround = ground ?? _ground();
  final effectiveDefaults = defaults ?? _params();
  final effectiveOverrides = overrides ??
      <BorderSlotOverride>[
        _override(slotKey: 'slot-z', salt: BorderSignedInt64.maximum),
        _override(slotKey: 'slot-a', salt: BorderSignedInt64.minimum),
      ];
  final effectiveKeepOuts = keepOutRegions ??
      <BorderKeepOutRegion>[
        _keepOut('z', const <bool>[false, true]),
        _keepOut('a', const <bool>[true, false]),
      ];
  final revision = BorderBlueprintRevision(
    revision: revisionNumber,
    definition: BorderBlueprintPublishedDefinition(
      name: definitionName,
      previewSeed: previewSeed ?? BorderSignedInt64.fromInt(42),
      template: template,
      primitives: effectivePrimitives,
      defaults: effectiveDefaults,
      ground: includeGround ? effectiveGround : null,
      categoryId: categoryId,
      sortOrder: sortOrder,
    ),
  );

  return BorderResolutionRequest(
    mapSize: mapSize,
    tileSizePx: tileSizePx,
    blueprintId: 'blueprint-a',
    blueprintRevision: includeBlueprintRevision ? revision : null,
    feature: BorderFeature(
      id: featureId,
      name: featureName,
      blueprintId: 'blueprint-a',
      seed: seed ?? BorderSignedInt64.fromInt(7),
      geometry: geometry ??
          BorderRegionGeometry(
            width: 2,
            height: 2,
            cells: const <bool>[true, false, true, true],
          ),
      lineSide: lineSide,
      paramsOverride: paramsOverride,
      overrides: effectiveOverrides,
      keepOutRegions: effectiveKeepOuts,
      materialization: null,
    ),
    visualSnapshots: snapshots ??
        <BorderVisualSnapshot>[
          _snapshot(_hexA),
          _snapshot(_hexB),
          _snapshot(_hexC),
        ],
    resolverVersion: 3,
  );
}

List<String> _fingerprintComponents(BorderInputFingerprints fingerprints) =>
    <String>[
      fingerprints.blueprint,
      fingerprints.geometryAndSeed,
      fingerprints.parameters,
      fingerprints.overrides,
      fingerprints.keepOutRegions,
      fingerprints.mapContext,
      fingerprints.visualSnapshots,
    ];

BorderGenerationParams _params({
  int irregularityPermille = 100,
  int detailDensityPermille = 200,
  int variationPermille = 300,
  int maxOverlapPx = 4,
  int gapTolerancePx = 5,
  int depthRows = 2,
  bool allowAutoRotation = true,
}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: variationPermille,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    );

BorderPublishedPrimitive _primitive({
  required String id,
  required String snapshotId,
  String? sourceElementId,
  BorderPrimitiveRole? role,
  int? weight,
  BorderPixelPos? anchorPx,
  BorderTransformPolicy? transforms,
  BorderPrimitiveAssetMetrics? metrics,
  BorderPrimitiveOrientation authoredOrientation =
      BorderPrimitiveOrientation.legacyAxis,
}) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: sourceElementId ?? 'source-$id',
      visualSnapshotId: snapshotId,
      role: role ??
          (id == 'a'
              ? BorderPrimitiveRole.structureLarge
              : BorderPrimitiveRole.filler),
      authoredOrientation: authoredOrientation,
      weight: weight ?? (id == 'a' ? 700 : 300),
      anchorPx: anchorPx ?? const BorderPixelPos(x: 8, y: 15),
      transforms: transforms ??
          BorderTransformPolicy(
            allowFlipX: true,
            allowedQuarterTurns: <int>[0, 2],
          ),
      publishedMetrics: metrics ?? _metrics(id),
    );

BorderPrimitiveAssetMetrics _metrics(
  String id, {
  String? assetFingerprint,
  GridSize pixelSize = const GridSize(width: 16, height: 20),
  BorderPixelRect? opaqueBounds,
  BorderPixelPos defaultAnchorPx = const BorderPixelPos(x: 8, y: 19),
  String occupancyMaskRle = 'border-rle-v1:2:1:1,1',
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: assetFingerprint ?? 'asset-$id',
      pixelSize: pixelSize,
      opaqueBounds:
          opaqueBounds ?? BorderPixelRect(x: 1, y: 2, width: 14, height: 18),
      defaultAnchorPx: defaultAnchorPx,
      occupancyMaskRle: occupancyMaskRle,
    );

BorderPublishedGround _ground({
  bool reverseInsertion = false,
  String sourceSmartTilePresetId = 'current-surface',
  int edgeBandCells = 2,
  BorderGroundVariantRole? snapshotOverrideRole,
  String? snapshotOverrideId,
}) {
  final roles = reverseInsertion
      ? standardBorderGroundVariantRoleOrder.reversed
      : standardBorderGroundVariantRoleOrder;
  return BorderPublishedGround(
    sourceSmartTilePresetId: sourceSmartTilePresetId,
    edgeBandCells: edgeBandCells,
    visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
      for (final role in roles)
        role: role == snapshotOverrideRole
            ? snapshotOverrideId!
            : standardBorderGroundVariantRoleOrder.indexOf(role).isEven
                ? _snapshotA
                : _snapshotB,
    },
  );
}

BorderSlotOverride _override({
  required String slotKey,
  required BorderSignedInt64 salt,
}) =>
    BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: salt,
      suppressed: false,
      locked: false,
      replacementPrimitiveId: 'a',
      offsetDeltaPx: const BorderPixelOffset(x: -2, y: 3),
      transformOverride: BorderSpriteTransform(quarterTurns: 2, flipX: true),
    );

BorderKeepOutRegion _keepOut(String id, List<bool> cells) =>
    BorderKeepOutRegion(
      id: id,
      region: BorderRegionGeometry(width: 2, height: 1, cells: cells),
    );

BorderVisualSnapshot _snapshot(
  String hex, {
  int durationMs = 100,
  String pathSuffix = 'frame.png',
  List<BorderVisualFrameSnapshot>? frames,
}) =>
    BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$hex',
      contentFingerprint: hex,
      frames: frames ??
          <BorderVisualFrameSnapshot>[
            _frame(pathSuffix, durationMs: durationMs)
          ],
    );

BorderVisualFrameSnapshot _frame(
  String suffix, {
  required int durationMs,
  BorderPixelRect? sourceRectPx,
  int? transparentColorArgb = 0xff00ff00,
}) =>
    BorderVisualFrameSnapshot(
      relativeAssetPath: 'assets/borders/snapshots/$suffix',
      sourceRectPx:
          sourceRectPx ?? BorderPixelRect(x: 1, y: 2, width: 16, height: 16),
      durationMs: durationMs,
      transparentColorArgb: transparentColorArgb,
    );

BorderResolvedGroundCell _resolvedGround({
  required int x,
  required BorderGroundVariantRole role,
}) =>
    BorderResolvedGroundCell(
      x: x,
      y: 2,
      visualSnapshotId: _snapshotA,
      resolvedRole: role,
    );

BorderResolvedPlacement _placement({
  required String slotKey,
  required String id,
  int anchorRowMajor = 10,
  int topLeftX = 16,
  int topLeftY = 32,
  int? opaqueX,
  int opaqueY = 34,
  int opaqueWidth = 14,
  int opaqueHeight = 18,
  String primitiveId = 'a',
  String visualSnapshotId = _snapshotA,
  GridPos anchorCell = const GridPos(x: 1, y: 2),
  BorderSpriteTransform? transform,
  BorderDrawBand drawBand = BorderDrawBand.structure,
  int? drawBandIndex,
  int passIndex = 1,
  int rank = 2,
  int ordinalLocal = 3,
}) =>
    BorderResolvedPlacement(
      id: id,
      slotKey: slotKey,
      primitiveId: primitiveId,
      visualSnapshotId: visualSnapshotId,
      anchorCell: anchorCell,
      topLeftWorldPx: BorderPixelPos(x: topLeftX, y: topLeftY),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: opaqueX ?? topLeftX + 1,
        y: opaqueY,
        width: opaqueWidth,
        height: opaqueHeight,
      ),
      transform:
          transform ?? BorderSpriteTransform(quarterTurns: 2, flipX: true),
      drawBand: drawBand,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: drawBandIndex ?? borderDrawBandV1Index(drawBand),
        anchorRowMajor: anchorRowMajor,
        passIndex: passIndex,
        rank: rank,
        ordinalLocal: ordinalLocal,
        slotKey: slotKey,
      ),
    );
