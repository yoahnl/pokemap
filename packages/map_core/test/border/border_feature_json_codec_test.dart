import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderFeature JSON codec', () {
    test('encodes the complete region feature exactly and round-trips', () {
      final override = _lockedOverride();
      final feature = _feature(
        overrides: <BorderSlotOverride>[override],
        keepOutRegions: <BorderKeepOutRegion>[_keepOut('keep-a')],
        materialization: _materialization(),
      );

      final encoded = encodeBorderFeatureJson(feature);

      expect(encoded, <String, Object?>{
        'id': 'feature-a',
        'name': 'Côte nord',
        'blueprintId': 'blueprint-a',
        'seed': '-7',
        'geometry': <String, Object?>{
          'kind': 'region',
          'width': 2,
          'height': 1,
          'cellsRle': 'border-rle-v1:2:1:1,1',
        },
        'paramsOverride': <String, Object?>{
          'irregularityPermille': 100,
          'detailDensityPermille': 200,
          'variationPermille': 300,
          'maxOverlapPx': 4,
          'gapTolerancePx': 2,
          'depthRows': 1,
        },
        'overrides': <Object?>[
          <String, Object?>{
            'slotKey': 'slot-a',
            'variationSalt': '8',
            'suppressed': false,
            'locked': true,
            'lockedPlacement': encodeBorderResolvedPlacementJson(
              override.lockedPlacement!,
              path: r'$.overrides[0].lockedPlacement',
            ),
            'replacementPrimitiveId': 'primitive-b',
            'offsetDeltaPx': <String, Object?>{'x': -3, 'y': 5},
            'transformOverride': <String, Object?>{
              'quarterTurns': 3,
              'flipX': true,
            },
          },
        ],
        'keepOutRegions': <Object?>[
          <String, Object?>{
            'id': 'keep-a',
            'region': <String, Object?>{
              'kind': 'region',
              'width': 2,
              'height': 1,
              'cellsRle': 'border-rle-v1:2:0:1,1',
            },
          },
        ],
        'materialization': encodeBorderMaterializationJson(
          feature.materialization!,
          path: r'$.materialization',
        ),
      });
      expect(
        encoded.keys,
        <String>[
          'id',
          'name',
          'blueprintId',
          'seed',
          'geometry',
          'paramsOverride',
          'overrides',
          'keepOutRegions',
          'materialization',
        ],
      );
      expect(decodeBorderFeatureJson(encoded), feature);
      expect(encoded.toString(), isNot(contains('collision')));
      expect(encoded.toString(), isNot(contains('freshness')));
    });

    test('round-trips stroke geometry without canonicalizing authored order',
        () {
      final geometry = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'east-to-south',
            points: const <GridPos>[
              GridPos(x: 4, y: 3),
              GridPos(x: 3, y: 3),
              GridPos(x: 3, y: 4),
            ],
            closed: false,
          ),
        ],
      );
      final feature = _feature(
        geometry: geometry,
        includeParams: false,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );

      final encoded = encodeBorderFeatureJson(feature);
      final decoded = decodeBorderFeatureJson(encoded);

      expect(encoded.containsKey('paramsOverride'), isFalse);
      expect(encoded.containsKey('materialization'), isFalse);
      expect(
        ((encoded['geometry']! as Map<String, Object?>)['strokes']!
                as List<Object?>)
            .single,
        <String, Object?>{
          'id': 'east-to-south',
          'points': <Object?>[
            <String, Object?>{'x': 4, 'y': 3},
            <String, Object?>{'x': 3, 'y': 3},
            <String, Object?>{'x': 3, 'y': 4},
          ],
          'closed': false,
        },
      );
      expect(decoded, feature);
    });

    test('V2 round-trips inverted line side while V1 remains key-exact', () {
      final feature = _feature(
        lineSide: BorderLineSide.inverted,
        geometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[
            BorderStroke(
              id: 'cliff',
              points: const <GridPos>[
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
              ],
              closed: false,
            ),
          ],
        ),
      );

      expect(
        () => encodeBorderFeatureJson(feature),
        _formatAt(r'$.lineSide'),
      );

      final encoded = encodeBorderFeatureJson(feature, formatVersion: 2);
      expect(encoded['lineSide'], 'inverted');
      expect(
        decodeBorderFeatureJson(encoded, formatVersion: 2),
        feature,
      );
      expect(
        () => decodeBorderFeatureJson(encoded),
        _formatAt(r'$.lineSide'),
      );

      final historical = _minimalFeatureJson();
      final decodedHistorical = decodeBorderFeatureJson(historical);
      expect(decodedHistorical.lineSide, BorderLineSide.primary);
      expect(encodeBorderFeatureJson(decodedHistorical), historical);
    });

    test('V2 round-trips disabled rotation while V1 rejects data loss', () {
      final feature = _feature(
        paramsOverride: _params(allowAutoRotation: false),
      );

      expect(
        () => encodeBorderFeatureJson(feature),
        _formatAt(r'$.paramsOverride.allowAutoRotation'),
      );

      final encoded = encodeBorderFeatureJson(feature, formatVersion: 2);
      final encodedParams = encoded['paramsOverride']! as Map<String, Object?>;
      expect(encodedParams['allowAutoRotation'], isFalse);
      expect(
        decodeBorderFeatureJson(encoded, formatVersion: 2),
        feature,
      );
    });

    test('accepts absent or null optional fields and emits canonical absence',
        () {
      final absent = _minimalFeatureJson();
      final withNulls = _minimalFeatureJson()
        ..['paramsOverride'] = null
        ..['materialization'] = null;

      final absentDecoded = decodeBorderFeatureJson(absent);
      final nullDecoded = decodeBorderFeatureJson(withNulls);

      expect(absentDecoded.paramsOverride, isNull);
      expect(absentDecoded.materialization, isNull);
      expect(nullDecoded, absentDecoded);
      expect(encodeBorderFeatureJson(nullDecoded), absent);
    });

    test('accepts absent or null override optionals and omits nulls', () {
      final absent = _minimalFeatureJson();
      final override = (absent['overrides']! as List<Object?>).single!
          as Map<String, Object?>;
      final withNulls = _deepCopy(absent)! as Map<String, Object?>;
      final nullableOverride = (withNulls['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      for (final key in <String>[
        'lockedPlacement',
        'replacementPrimitiveId',
        'offsetDeltaPx',
        'transformOverride',
      ]) {
        nullableOverride[key] = null;
      }

      final absentDecoded = decodeBorderFeatureJson(absent);
      final nullDecoded = decodeBorderFeatureJson(withNulls);

      expect(nullDecoded, absentDecoded);
      final reencoded = encodeBorderFeatureJson(nullDecoded);
      final reencodedOverride = (reencoded['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      expect(reencodedOverride, override);
      expect(reencodedOverride.keys, <String>[
        'slotKey',
        'variationSalt',
        'suppressed',
        'locked',
      ]);
    });

    test('uses canonical signed-int64 strings for seed and variation salts',
        () {
      final minimum = _minimalFeatureJson()..['seed'] = '-9223372036854775808';
      ((minimum['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['variationSalt'] = '-9223372036854775808';
      final maximum = _minimalFeatureJson()..['seed'] = '9223372036854775807';
      ((maximum['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['variationSalt'] = '9223372036854775807';

      expect(
        decodeBorderFeatureJson(minimum).seed,
        BorderSignedInt64.minimum,
      );
      expect(
        decodeBorderFeatureJson(maximum).seed,
        BorderSignedInt64.maximum,
      );
      expect(
          encodeBorderFeatureJson(decodeBorderFeatureJson(minimum)), minimum);
      expect(
          encodeBorderFeatureJson(decodeBorderFeatureJson(maximum)), maximum);

      for (final invalid in <Object?>[
        1,
        1.0,
        '+1',
        '01',
        '-0',
        ' 1',
        '1 ',
        '9223372036854775808',
        '-9223372036854775809',
      ]) {
        final badSeed = _minimalFeatureJson()..['seed'] = invalid;
        expect(
          () => decodeBorderFeatureJson(badSeed),
          _formatAt(r'$.seed'),
          reason: 'seed: $invalid',
        );

        final badSalt = _minimalFeatureJson();
        ((badSalt['overrides']! as List<Object?>).single!
            as Map<String, Object?>)['variationSalt'] = invalid;
        expect(
          () => decodeBorderFeatureJson(badSalt),
          _formatAt(r'$.overrides[0].variationSalt'),
          reason: 'variationSalt: $invalid',
        );
      }
    });

    test('preserves authored override and keep-out list order', () {
      final feature = _feature(
        overrides: <BorderSlotOverride>[
          _simpleOverride('slot-z', variationSalt: 2),
          _simpleOverride('slot-a', variationSalt: 1),
        ],
        keepOutRegions: <BorderKeepOutRegion>[
          _keepOut('keep-z'),
          _keepOut('keep-a'),
        ],
      );

      final encoded = encodeBorderFeatureJson(feature);
      final overrides = encoded['overrides']! as List<Object?>;
      final keepOuts = encoded['keepOutRegions']! as List<Object?>;

      expect(
        overrides.map((value) => (value! as Map<String, Object?>)['slotKey']),
        <String>['slot-z', 'slot-a'],
      );
      expect(
        keepOuts.map((value) => (value! as Map<String, Object?>)['id']),
        <String>['keep-z', 'keep-a'],
      );
      expect(decodeBorderFeatureJson(encoded), feature);
    });

    test('reports duplicate override slots and keep-out ids at second fields',
        () {
      final duplicateOverride = _minimalFeatureJson();
      final overrides = duplicateOverride['overrides']! as List<Object?>;
      overrides.add(_deepCopy(overrides.single)!);
      expect(
        () => decodeBorderFeatureJson(duplicateOverride),
        _formatAt(r'$.overrides[1].slotKey'),
      );

      final duplicateKeepOut = _minimalFeatureJson();
      final keepOuts = duplicateKeepOut['keepOutRegions']! as List<Object?>;
      keepOuts
        ..add(_keepOutJson('same'))
        ..add(_keepOutJson('same'));
      expect(
        () => decodeBorderFeatureJson(duplicateKeepOut),
        _formatAt(r'$.keepOutRegions[1].id'),
      );
    });

    test('enforces locked invariants at the authored override fields', () {
      final lockedWithoutPlacement = _minimalFeatureJson();
      ((lockedWithoutPlacement['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['locked'] = true;
      expect(
        () => decodeBorderFeatureJson(lockedWithoutPlacement),
        _formatAt(r'$.overrides[0].lockedPlacement'),
      );

      final placementWithoutLocked = _minimalFeatureJson();
      final unlockedOverride =
          (placementWithoutLocked['overrides']! as List<Object?>).single!
              as Map<String, Object?>;
      unlockedOverride['lockedPlacement'] =
          encodeBorderResolvedPlacementJson(_placement('slot-a'));
      expect(
        () => decodeBorderFeatureJson(placementWithoutLocked),
        _formatAt(r'$.overrides[0].locked'),
      );

      final wrongSlot = _minimalFeatureJson();
      final wrongSlotOverride = (wrongSlot['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      wrongSlotOverride['locked'] = true;
      wrongSlotOverride['lockedPlacement'] =
          encodeBorderResolvedPlacementJson(_placement('slot-b'));
      expect(
        () => decodeBorderFeatureJson(wrongSlot),
        _formatAt(r'$.overrides[0].lockedPlacement.slotKey'),
      );
    });

    test('suppression rejects every incompatible authored correction', () {
      final cases = <(String, Object?)>[
        ('replacementPrimitiveId', 'primitive-b'),
        ('offsetDeltaPx', <String, Object?>{'x': 1, 'y': 0}),
        (
          'transformOverride',
          <String, Object?>{'quarterTurns': 1, 'flipX': false},
        ),
      ];
      for (final (field, value) in cases) {
        final invalid = _minimalFeatureJson();
        final override = (invalid['overrides']! as List<Object?>).single!
            as Map<String, Object?>;
        override['suppressed'] = true;
        override[field] = value;
        expect(
          () => decodeBorderFeatureJson(invalid),
          _formatAt('\$.overrides[0].$field'),
          reason: field,
        );
      }

      final suppressedLocked = _minimalFeatureJson();
      final lockedOverride = (suppressedLocked['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      lockedOverride
        ..['suppressed'] = true
        ..['locked'] = true
        ..['lockedPlacement'] =
            encodeBorderResolvedPlacementJson(_placement('slot-a'));
      expect(
        () => decodeBorderFeatureJson(suppressedLocked),
        _formatAt(r'$.overrides[0].locked'),
      );

      final valid = _minimalFeatureJson();
      ((valid['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['suppressed'] = true;
      expect(
          decodeBorderFeatureJson(valid).overrides.single.suppressed, isTrue);
    });

    test('requires exact keys, strict types, and stable text fields', () {
      final unknownRoot = _minimalFeatureJson()..['collision'] = true;
      expect(
        () => decodeBorderFeatureJson(unknownRoot),
        _formatAt(r'$.collision'),
      );

      final unknownOverride = _minimalFeatureJson();
      ((unknownOverride['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['weight'] = 1;
      expect(
        () => decodeBorderFeatureJson(unknownOverride),
        _formatAt(r'$.overrides[0].weight'),
      );

      final wrongBoolean = _minimalFeatureJson();
      ((wrongBoolean['overrides']! as List<Object?>).single!
          as Map<String, Object?>)['suppressed'] = 0;
      expect(
        () => decodeBorderFeatureJson(wrongBoolean),
        _formatAt(r'$.overrides[0].suppressed'),
      );

      final wrongList = _minimalFeatureJson()..['overrides'] = <String, int>{};
      expect(
        () => decodeBorderFeatureJson(wrongList),
        _formatAt(r'$.overrides'),
      );

      for (final field in <String>['id', 'name', 'blueprintId']) {
        final invalid = _minimalFeatureJson()..[field] = ' value ';
        expect(
          () => decodeBorderFeatureJson(invalid),
          _formatAt('\$.$field'),
          reason: field,
        );
      }
    });

    test('uses strict signed integer offsets and exact offset keys', () {
      final minimum = _minimalFeatureJson();
      final minimumOverride = (minimum['overrides']! as List<Object?>).single!
          as Map<String, Object?>;
      minimumOverride['offsetDeltaPx'] = <String, Object?>{
        'x': -9223372036854775808,
        'y': 9223372036854775807,
      };
      final decoded = decodeBorderFeatureJson(minimum);
      expect(
        decoded.overrides.single.offsetDeltaPx,
        const BorderPixelOffset(
          x: -9223372036854775808,
          y: 9223372036854775807,
        ),
      );
      expect(encodeBorderFeatureJson(decoded), minimum);

      final wrongType = _minimalFeatureJson();
      final wrongTypeOverride = (wrongType['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      wrongTypeOverride['offsetDeltaPx'] = <String, Object?>{
        'x': 1.0,
        'y': 0,
      };
      expect(
        () => decodeBorderFeatureJson(wrongType),
        _formatAt(r'$.overrides[0].offsetDeltaPx.x'),
      );

      final unknown = _minimalFeatureJson();
      final unknownOverride = (unknown['overrides']! as List<Object?>).single!
          as Map<String, Object?>;
      unknownOverride['offsetDeltaPx'] = <String, Object?>{
        'x': 1,
        'y': 0,
        'z': 0,
      };
      expect(
        () => decodeBorderFeatureJson(unknown),
        _formatAt(r'$.overrides[0].offsetDeltaPx.z'),
      );
    });

    test('propagates precise child-codec paths', () {
      final geometry = _minimalFeatureJson();
      (geometry['geometry']! as Map<String, Object?>)['cellsRle'] =
          'border-rle-v1:1:0:1';
      expect(
        () => decodeBorderFeatureJson(geometry),
        _formatAt(r'$.geometry.cellsRle'),
      );

      final params = _minimalFeatureJson()..['paramsOverride'] = _paramsJson();
      (params['paramsOverride']! as Map<String, Object?>)['depthRows'] = 0;
      expect(
        () => decodeBorderFeatureJson(params),
        _formatAt(r'$.paramsOverride.depthRows'),
      );

      final transform = _minimalFeatureJson();
      final transformOverride = (transform['overrides']! as List<Object?>)
          .single! as Map<String, Object?>;
      transformOverride['transformOverride'] = <String, Object?>{
        'quarterTurns': 4,
        'flipX': false,
      };
      expect(
        () => decodeBorderFeatureJson(transform),
        _formatAt(r'$.overrides[0].transformOverride.quarterTurns'),
      );

      final keepOut = _minimalFeatureJson();
      (keepOut['keepOutRegions']! as List<Object?>).add(<String, Object?>{
        'id': 'keep-a',
        'region': <String, Object?>{
          'kind': 'stroke',
          'strokes': const <Object?>[],
        },
      });
      expect(
        () => decodeBorderFeatureJson(keepOut),
        _formatAt(r'$.keepOutRegions[0].region.kind'),
      );

      final materialization = _minimalFeatureJson()
        ..['materialization'] = encodeBorderMaterializationJson(
          _materialization(),
        );
      final receipt = (materialization['materialization']!
          as Map<String, Object?>)['receipt']! as Map<String, Object?>;
      receipt['resolverVersion'] = 0;
      expect(
        () => decodeBorderFeatureJson(materialization),
        _formatAt(r'$.materialization.receipt.resolverVersion'),
      );
    });

    test('keeps valid dangling references loadable without resolution', () {
      final json = _minimalFeatureJson()
        ..['blueprintId'] = 'missing-blueprint-record';
      final override =
          (json['overrides']! as List<Object?>).single! as Map<String, Object?>;
      override['replacementPrimitiveId'] = 'missing-primitive';

      final decoded = decodeBorderFeatureJson(json);

      expect(decoded.blueprintId, 'missing-blueprint-record');
      expect(
        decoded.overrides.single.replacementPrimitiveId,
        'missing-primitive',
      );
    });

    test('honors custom paths and never mutates decoder input', () {
      final input = _minimalFeatureJson();
      final before = _deepCopy(input);

      final decoded = decodeBorderFeatureJson(
        input,
        path: r'$.layers[2].content.features[4]',
      );

      expect(decoded.id, 'feature-a');
      expect(input, before);

      final invalid = _minimalFeatureJson()..['seed'] = '01';
      expect(
        () => decodeBorderFeatureJson(
          invalid,
          path: r'$.layers[2].content.features[4]',
        ),
        _formatAt(r'$.layers[2].content.features[4].seed'),
      );
    });
  });
}

BorderFeature _feature({
  BorderFeatureGeometry? geometry,
  BorderLineSide lineSide = BorderLineSide.primary,
  bool includeParams = true,
  BorderGenerationParams? paramsOverride,
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
  BorderMaterialization? materialization,
}) =>
    BorderFeature(
      id: 'feature-a',
      name: 'Côte nord',
      blueprintId: 'blueprint-a',
      seed: BorderSignedInt64.fromInt(-7),
      geometry: geometry ?? _region(),
      lineSide: lineSide,
      paramsOverride: includeParams ? paramsOverride ?? _params() : null,
      overrides: overrides ?? <BorderSlotOverride>[_simpleOverride('slot-a')],
      keepOutRegions: keepOutRegions ?? const <BorderKeepOutRegion>[],
      materialization: materialization,
    );

BorderRegionGeometry _region() => BorderRegionGeometry(
      width: 2,
      height: 1,
      cells: const <bool>[true, false],
    );

BorderKeepOutRegion _keepOut(String id) => BorderKeepOutRegion(
      id: id,
      region: BorderRegionGeometry(
        width: 2,
        height: 1,
        cells: const <bool>[false, true],
      ),
    );

BorderGenerationParams _params({bool allowAutoRotation = true}) =>
    BorderGenerationParams(
      irregularityPermille: 100,
      detailDensityPermille: 200,
      variationPermille: 300,
      maxOverlapPx: 4,
      gapTolerancePx: 2,
      depthRows: 1,
      allowAutoRotation: allowAutoRotation,
    );

BorderSlotOverride _simpleOverride(
  String slotKey, {
  int variationSalt = 1,
}) =>
    BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: BorderSignedInt64.fromInt(variationSalt),
      suppressed: false,
      locked: false,
    );

BorderSlotOverride _lockedOverride() => BorderSlotOverride(
      slotKey: 'slot-a',
      variationSalt: BorderSignedInt64.fromInt(8),
      suppressed: false,
      locked: true,
      lockedPlacement: _placement('slot-a'),
      replacementPrimitiveId: 'primitive-b',
      offsetDeltaPx: const BorderPixelOffset(x: -3, y: 5),
      transformOverride: BorderSpriteTransform(quarterTurns: 3, flipX: true),
    );

BorderResolvedPlacement _placement(String slotKey) => BorderResolvedPlacement(
      id: 'placement-$slotKey',
      slotKey: slotKey,
      primitiveId: 'primitive-a',
      visualSnapshotId: _snapshotA,
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
        drawBandIndex: 1,
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
          blueprint: _shaA,
          geometryAndSeed: _shaB,
          parameters: _shaC,
          overrides: _shaD,
          keepOutRegions: _shaE,
          mapContext: _shaF,
          visualSnapshots: _sha0,
        ),
        inputFingerprint: _sha1,
        outputFingerprint: _sha2,
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId: _snapshotA,
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: const <BorderResolvedPlacement>[],
    );

Map<String, Object?> _minimalFeatureJson() => <String, Object?>{
      'id': 'feature-a',
      'name': 'Côte nord',
      'blueprintId': 'blueprint-a',
      'seed': '-7',
      'geometry': <String, Object?>{
        'kind': 'region',
        'width': 2,
        'height': 1,
        'cellsRle': 'border-rle-v1:2:1:1,1',
      },
      'overrides': <Object?>[
        <String, Object?>{
          'slotKey': 'slot-a',
          'variationSalt': '1',
          'suppressed': false,
          'locked': false,
        },
      ],
      'keepOutRegions': <Object?>[],
    };

Map<String, Object?> _keepOutJson(String id) => <String, Object?>{
      'id': id,
      'region': <String, Object?>{
        'kind': 'region',
        'width': 2,
        'height': 1,
        'cellsRle': 'border-rle-v1:2:0:2',
      },
    };

Map<String, Object?> _paramsJson() => <String, Object?>{
      'irregularityPermille': 100,
      'detailDensityPermille': 200,
      'variationPermille': 300,
      'maxOverlapPx': 4,
      'gapTolerancePx': 2,
      'depthRows': 1,
    };

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

Object? _deepCopy(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: _deepCopy(entry.value),
    };
  }
  if (value is List) {
    return <Object?>[for (final item in value) _deepCopy(item)];
  }
  return value;
}

const String _hexA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _hexB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const String _hexC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const String _hexD =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const String _hexE =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const String _hexF =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
const String _hex0 =
    '0000000000000000000000000000000000000000000000000000000000000000';
const String _hex1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const String _hex2 =
    '2222222222222222222222222222222222222222222222222222222222222222';

const String _snapshotA = 'border-snapshot-sha256:$_hexA';
const String _shaA = 'sha256:$_hexA';
const String _shaB = 'sha256:$_hexB';
const String _shaC = 'sha256:$_hexC';
const String _shaD = 'sha256:$_hexD';
const String _shaE = 'sha256:$_hexE';
const String _shaF = 'sha256:$_hexF';
const String _sha0 = 'sha256:$_hex0';
const String _sha1 = 'sha256:$_hex1';
const String _sha2 = 'sha256:$_hex2';
