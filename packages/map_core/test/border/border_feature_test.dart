import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderPixelOffset', () {
    test('has value semantics across both signed coordinates', () {
      const offset = BorderPixelOffset(x: -12, y: 34);
      const equal = BorderPixelOffset(x: -12, y: 34);

      expect(offset, equal);
      expect(offset.hashCode, equal.hashCode);
      expect(offset, isNot(const BorderPixelOffset(x: -11, y: 34)));
      expect(offset, isNot(const BorderPixelOffset(x: -12, y: 35)));
    });
  });

  group('BorderSlotOverride', () {
    test('stores a plain local variation with value semantics', () {
      final override = BorderSlotOverride(
        slotKey: 'slot-a',
        variationSalt: BorderSignedInt64.minimum,
        suppressed: false,
        locked: false,
      );
      final equal = BorderSlotOverride(
        slotKey: 'slot-a',
        variationSalt: BorderSignedInt64.minimum,
        suppressed: false,
        locked: false,
      );

      expect(override.slotKey, 'slot-a');
      expect(override.variationSalt, BorderSignedInt64.minimum);
      expect(override.suppressed, isFalse);
      expect(override.locked, isFalse);
      expect(override.lockedPlacement, isNull);
      expect(override.replacementPrimitiveId, isNull);
      expect(override.offsetDeltaPx, isNull);
      expect(override.transformOverride, isNull);
      expect(override, equal);
      expect(override.hashCode, equal.hashCode);
    });

    test('accepts an aggregated replace, move, transform, and lock', () {
      final placement = _placement(slotKey: 'slot-a');
      final override = BorderSlotOverride(
        slotKey: 'slot-a',
        variationSalt: BorderSignedInt64.maximum,
        suppressed: false,
        locked: true,
        lockedPlacement: placement,
        replacementPrimitiveId: 'primitive-b',
        offsetDeltaPx: const BorderPixelOffset(x: -3, y: 5),
        transformOverride: BorderSpriteTransform(
          quarterTurns: 3,
          flipX: true,
        ),
      );

      expect(override.lockedPlacement, placement);
      expect(override.replacementPrimitiveId, 'primitive-b');
      expect(
        override.offsetDeltaPx,
        const BorderPixelOffset(x: -3, y: 5),
      );
      expect(
        override.transformOverride,
        BorderSpriteTransform(quarterTurns: 3, flipX: true),
      );
      expect(
        override,
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.maximum,
          suppressed: false,
          locked: true,
          lockedPlacement: _placement(slotKey: 'slot-a'),
          replacementPrimitiveId: 'primitive-b',
          offsetDeltaPx: const BorderPixelOffset(x: -3, y: 5),
          transformOverride: BorderSpriteTransform(
            quarterTurns: 3,
            flipX: true,
          ),
        ),
      );
    });

    test('requires nonblank already-trimmed persisted identities', () {
      for (final invalid in <String>['', '   ', ' slot-a', 'slot-a ']) {
        expect(
          () => BorderSlotOverride(
            slotKey: invalid,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => BorderSlotOverride(
            slotKey: 'slot-a',
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            replacementPrimitiveId: invalid,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('requires locked and lockedPlacement to be present together', () {
      expect(
        () => BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: true,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: false,
          lockedPlacement: _placement(slotKey: 'slot-a'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires a locked placement for the same stable slot', () {
      expect(
        () => BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: true,
          lockedPlacement: _placement(slotKey: 'slot-b'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('suppression permits only the variation salt', () {
      final suppressed = BorderSlotOverride(
        slotKey: 'slot-a',
        variationSalt: BorderSignedInt64.fromInt(17),
        suppressed: true,
        locked: false,
      );
      expect(suppressed.variationSalt, BorderSignedInt64.fromInt(17));

      final invalidSuppressed = <BorderSlotOverride Function()>[
        () => BorderSlotOverride(
              slotKey: 'slot-a',
              variationSalt: BorderSignedInt64.fromInt(17),
              suppressed: true,
              locked: true,
              lockedPlacement: _placement(slotKey: 'slot-a'),
            ),
        () => BorderSlotOverride(
              slotKey: 'slot-a',
              variationSalt: BorderSignedInt64.fromInt(17),
              suppressed: true,
              locked: false,
              replacementPrimitiveId: 'primitive-b',
            ),
        () => BorderSlotOverride(
              slotKey: 'slot-a',
              variationSalt: BorderSignedInt64.fromInt(17),
              suppressed: true,
              locked: false,
              offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
            ),
        () => BorderSlotOverride(
              slotKey: 'slot-a',
              variationSalt: BorderSignedInt64.fromInt(17),
              suppressed: true,
              locked: false,
              transformOverride: BorderSpriteTransform(
                quarterTurns: 1,
                flipX: false,
              ),
            ),
      ];

      for (final createInvalid in invalidSuppressed) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('equality includes every persisted field', () {
      final override = _override(slotKey: 'slot-a', variationSalt: 3);

      expect(
        <BorderSlotOverride>[
          _override(slotKey: 'slot-b', variationSalt: 3),
          _override(slotKey: 'slot-a', variationSalt: 4),
          BorderSlotOverride(
            slotKey: 'slot-a',
            variationSalt: BorderSignedInt64.fromInt(3),
            suppressed: true,
            locked: false,
          ),
          BorderSlotOverride(
            slotKey: 'slot-a',
            variationSalt: BorderSignedInt64.fromInt(3),
            suppressed: false,
            locked: true,
            lockedPlacement: _placement(slotKey: 'slot-a'),
          ),
          _override(
            slotKey: 'slot-a',
            variationSalt: 3,
            replacementPrimitiveId: 'primitive-c',
          ),
          _override(
            slotKey: 'slot-a',
            variationSalt: 3,
            offsetDeltaPx: const BorderPixelOffset(x: 9, y: 2),
          ),
          _override(
            slotKey: 'slot-a',
            variationSalt: 3,
            transformOverride: BorderSpriteTransform(
              quarterTurns: 2,
              flipX: true,
            ),
          ),
        ],
        everyElement(isNot(override)),
      );
    });
  });

  group('BorderFeature', () {
    test('stores the complete draft and preserves ordered immutable lists', () {
      final overrides = <BorderSlotOverride>[
        _override(slotKey: 'slot-a'),
        _override(slotKey: 'slot-b'),
      ];
      final keepOutRegions = <BorderKeepOutRegion>[
        _keepOut('keep-a', cells: const <bool>[true, false]),
        _keepOut('keep-b', cells: const <bool>[false, true]),
      ];
      final feature = _feature(
        overrides: overrides,
        keepOutRegions: keepOutRegions,
      );

      overrides
        ..clear()
        ..add(_override(slotKey: 'slot-c'));
      keepOutRegions.clear();

      expect(feature.id, 'feature-a');
      expect(feature.name, 'Côte nord');
      expect(feature.blueprintId, 'blueprint-a');
      expect(feature.seed, BorderSignedInt64.fromInt(-7));
      expect(feature.geometry, _region());
      expect(feature.paramsOverride, _params());
      expect(
        feature.overrides.map((entry) => entry.slotKey),
        orderedEquals(const <String>['slot-a', 'slot-b']),
      );
      expect(
        feature.keepOutRegions.map((entry) => entry.id),
        orderedEquals(const <String>['keep-a', 'keep-b']),
      );
      expect(feature.materialization, isNull);
      expect(
        () => feature.overrides.add(_override(slotKey: 'slot-d')),
        throwsUnsupportedError,
      );
      expect(
        () => feature.keepOutRegions.clear(),
        throwsUnsupportedError,
      );
    });

    test(
        'allows empty region and stroke draft geometry without materialization',
        () {
      final emptyRegion = _feature(
        geometry: BorderRegionGeometry(
          width: 2,
          height: 1,
          cells: const <bool>[false, false],
        ),
        includeParamsOverride: false,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );
      final emptyStrokes = _feature(
        geometry: BorderStrokeGeometry(strokes: const <BorderStroke>[]),
        includeParamsOverride: false,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );

      expect(emptyRegion.materialization, isNull);
      expect(emptyStrokes.materialization, isNull);
    });

    test('accepts the signed-int64 seed boundaries', () {
      expect(
        _feature(seed: BorderSignedInt64.minimum).seed,
        BorderSignedInt64.minimum,
      );
      expect(
        _feature(seed: BorderSignedInt64.maximum).seed,
        BorderSignedInt64.maximum,
      );
    });

    test('requires nonblank already-trimmed identity and display fields', () {
      for (final invalid in <String>['', '   ', ' value', 'value ']) {
        expect(
          () => _feature(id: invalid),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => _feature(name: invalid),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => _feature(blueprintId: invalid),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects duplicate override slot keys and keep-out ids', () {
      expect(
        () => _feature(
          overrides: <BorderSlotOverride>[
            _override(slotKey: 'slot-a'),
            _override(slotKey: 'slot-a', variationSalt: 2),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _feature(
          keepOutRegions: <BorderKeepOutRegion>[
            _keepOut('keep-a', cells: const <bool>[true, false]),
            _keepOut('keep-a', cells: const <bool>[false, true]),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('has deep ordered value semantics across every persisted field', () {
      final feature = _feature(materialization: _materialization());
      final equal = _feature(materialization: _materialization());

      expect(feature, equal);
      expect(feature.hashCode, equal.hashCode);
      expect(
        <BorderFeature>[
          _feature(id: 'feature-b', materialization: _materialization()),
          _feature(name: 'Côte sud', materialization: _materialization()),
          _feature(
            blueprintId: 'blueprint-b',
            materialization: _materialization(),
          ),
          _feature(seed: -8, materialization: _materialization()),
          _feature(
            geometry: BorderRegionGeometry(
              width: 2,
              height: 1,
              cells: const <bool>[false, true],
            ),
            materialization: _materialization(),
          ),
          _feature(
            paramsOverride: _params(irregularityPermille: 101),
            materialization: _materialization(),
          ),
          _feature(
            overrides: <BorderSlotOverride>[
              _override(slotKey: 'slot-b'),
              _override(slotKey: 'slot-a'),
            ],
            materialization: _materialization(),
          ),
          _feature(
            keepOutRegions: <BorderKeepOutRegion>[
              _keepOut('keep-b', cells: const <bool>[false, true]),
              _keepOut('keep-a', cells: const <bool>[true, false]),
            ],
            materialization: _materialization(),
          ),
          _feature(materialization: null),
        ],
        everyElement(isNot(feature)),
      );
    });
  });
}

BorderFeature _feature({
  String id = 'feature-a',
  String name = 'Côte nord',
  String blueprintId = 'blueprint-a',
  Object seed = -7,
  BorderFeatureGeometry? geometry,
  BorderGenerationParams? paramsOverride,
  bool includeParamsOverride = true,
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
  BorderMaterialization? materialization,
}) {
  return BorderFeature(
    id: id,
    name: name,
    blueprintId: blueprintId,
    seed: _signedInt64(seed),
    geometry: geometry ?? _region(),
    paramsOverride: includeParamsOverride ? paramsOverride ?? _params() : null,
    overrides: overrides ??
        <BorderSlotOverride>[
          _override(slotKey: 'slot-a'),
          _override(slotKey: 'slot-b'),
        ],
    keepOutRegions: keepOutRegions ??
        <BorderKeepOutRegion>[
          _keepOut('keep-a', cells: const <bool>[true, false]),
          _keepOut('keep-b', cells: const <bool>[false, true]),
        ],
    materialization: materialization,
  );
}

BorderRegionGeometry _region() => BorderRegionGeometry(
      width: 2,
      height: 1,
      cells: const <bool>[true, false],
    );

BorderKeepOutRegion _keepOut(String id, {required List<bool> cells}) =>
    BorderKeepOutRegion(
      id: id,
      region: BorderRegionGeometry(width: 2, height: 1, cells: cells),
    );

BorderGenerationParams _params({int irregularityPermille = 100}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: 200,
      variationPermille: 300,
      maxOverlapPx: 4,
      gapTolerancePx: 2,
      depthRows: 1,
    );

BorderSlotOverride _override({
  required String slotKey,
  Object variationSalt = 1,
  String? replacementPrimitiveId = 'primitive-b',
  BorderPixelOffset? offsetDeltaPx = const BorderPixelOffset(x: 2, y: 2),
  BorderSpriteTransform? transformOverride,
}) {
  return BorderSlotOverride(
    slotKey: slotKey,
    variationSalt: _signedInt64(variationSalt),
    suppressed: false,
    locked: false,
    replacementPrimitiveId: replacementPrimitiveId,
    offsetDeltaPx: offsetDeltaPx,
    transformOverride: transformOverride ??
        BorderSpriteTransform(quarterTurns: 1, flipX: false),
  );
}

BorderSignedInt64 _signedInt64(Object value) => switch (value) {
      BorderSignedInt64() => value,
      int() => BorderSignedInt64.fromInt(value),
      _ => throw ArgumentError.value(value, 'value'),
    };

BorderResolvedPlacement _placement({required String slotKey}) =>
    BorderResolvedPlacement(
      id: 'placement-$slotKey',
      slotKey: slotKey,
      primitiveId: 'primitive-a',
      visualSnapshotId: _snapshotId,
      anchorCell: const GridPos(x: 2, y: 3),
      topLeftWorldPx: const BorderPixelPos(x: 32, y: 48),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: 33,
        y: 49,
        width: 12,
        height: 8,
      ),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: BorderDrawBand.structure.stableV1Index,
        anchorRowMajor: 32,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: slotKey,
      ),
    );

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 2,
        components: BorderInputFingerprints(
          blueprint: _fingerprint('1'),
          geometryAndSeed: _fingerprint('2'),
          parameters: _fingerprint('3'),
          overrides: _fingerprint('4'),
          keepOutRegions: _fingerprint('5'),
          mapContext: _fingerprint('6'),
          visualSnapshots: _fingerprint('7'),
        ),
        inputFingerprint: _fingerprint('8'),
        outputFingerprint: _fingerprint('9'),
      ),
      ground: const <BorderResolvedGroundCell>[],
      placements: <BorderResolvedPlacement>[_placement(slotKey: 'slot-a')],
    );

String _fingerprint(String digit) => 'sha256:${digit * 64}';

const String _snapshotId = 'border-snapshot-sha256:'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
