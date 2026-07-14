import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderSpriteTransform JSON codec', () {
    test('encodes the exact shape and round-trips', () {
      final transform = BorderSpriteTransform(quarterTurns: 3, flipX: true);

      final encoded = encodeBorderSpriteTransformJson(transform);

      expect(encoded, <String, Object?>{
        'quarterTurns': 3,
        'flipX': true,
      });
      expect(decodeBorderSpriteTransformJson(encoded), transform);
    });

    test('requires exact keys, strict scalar types, and normalized turns', () {
      expect(
        () => decodeBorderSpriteTransformJson(<String, Object?>{
          'quarterTurns': 0,
          'flipX': false,
          'rotation': 0,
        }),
        _formatAt(r'$.rotation'),
      );
      expect(
        () => decodeBorderSpriteTransformJson(<String, Object?>{
          'quarterTurns': 1.0,
          'flipX': false,
        }),
        _formatAt(r'$.quarterTurns'),
      );
      expect(
        () => decodeBorderSpriteTransformJson(<String, Object?>{
          'quarterTurns': 0,
          'flipX': 0,
        }),
        _formatAt(r'$.flipX'),
      );
      for (final turns in <int>[-1, 4]) {
        expect(
          () => decodeBorderSpriteTransformJson(<String, Object?>{
            'quarterTurns': turns,
            'flipX': false,
          }),
          _formatAt(r'$.quarterTurns'),
        );
      }
    });
  });

  group('BorderResolvedPlacement JSON codec', () {
    test('encodes every persisted field exactly and round-trips', () {
      final placement = _placement();

      final encoded = encodeBorderResolvedPlacementJson(placement);

      expect(encoded, _placementJson());
      expect(
        encoded.keys,
        <String>[
          'id',
          'slotKey',
          'primitiveId',
          'visualSnapshotId',
          'anchorCell',
          'topLeftWorldPx',
          'opaqueWorldBoundsPx',
          'transform',
          'drawBand',
          'stableOrderKey',
        ],
      );
      expect(decodeBorderResolvedPlacementJson(encoded), placement);
    });

    test('maps all four draw bands and stable indices explicitly', () {
      const cases = <(BorderDrawBand, String, int)>[
        (BorderDrawBand.outerAccent, 'outerAccent', 0),
        (BorderDrawBand.structure, 'structure', 1),
        (BorderDrawBand.innerFinish, 'innerFinish', 2),
        (BorderDrawBand.accent, 'accent', 3),
      ];

      for (final (band, wireName, stableIndex) in cases) {
        final placement = _placement(
          drawBand: band,
          stableOrderKey: _orderKey(drawBandIndex: stableIndex),
        );
        final encoded = encodeBorderResolvedPlacementJson(placement);
        final order = encoded['stableOrderKey']! as Map<String, Object?>;

        expect(encoded['drawBand'], wireName);
        expect(order['drawBandIndex'], stableIndex);
        expect(decodeBorderResolvedPlacementJson(encoded), placement);
      }
    });

    test('rejects unknown bands and strict nested fields at exact paths', () {
      final unknownBand = _placementJson()..['drawBand'] = 'foreground';
      expect(
        () => decodeBorderResolvedPlacementJson(unknownBand),
        _formatAt(r'$.drawBand'),
      );

      final unknownField = _placementJson()..['collision'] = true;
      expect(
        () => decodeBorderResolvedPlacementJson(unknownField),
        _formatAt(r'$.collision'),
      );

      final unknownAnchor = _placementJson();
      (unknownAnchor['anchorCell']! as Map<String, Object?>)['column'] = 0;
      expect(
        () => decodeBorderResolvedPlacementJson(unknownAnchor),
        _formatAt(r'$.anchorCell.column'),
      );

      final missingOrderSlot = _placementJson();
      (missingOrderSlot['stableOrderKey']! as Map<String, Object?>)
          .remove('slotKey');
      expect(
        () => decodeBorderResolvedPlacementJson(missingOrderSlot),
        _formatAt(r'$.stableOrderKey.slotKey'),
      );
    });

    test('rejects slot and draw-band/index mismatches at their fields', () {
      final wrongSlot = _placementJson();
      (wrongSlot['stableOrderKey']! as Map<String, Object?>)['slotKey'] =
          'slot-b';
      expect(
        () => decodeBorderResolvedPlacementJson(wrongSlot),
        _formatAt(r'$.stableOrderKey.slotKey'),
      );

      final wrongIndex = _placementJson();
      (wrongIndex['stableOrderKey']! as Map<String, Object?>)['drawBandIndex'] =
          2;
      expect(
        () => decodeBorderResolvedPlacementJson(wrongIndex),
        _formatAt(r'$.stableOrderKey.drawBandIndex'),
      );
    });

    test('requires strict integer fields throughout the placement', () {
      final cases = <(Map<String, Object?>, String)>[
        (
          _placementJson()
            ..['anchorCell'] = <String, Object?>{'x': '-2', 'y': 3},
          r'$.anchorCell.x',
        ),
        (
          _placementJson()
            ..['topLeftWorldPx'] = <String, Object?>{'x': -16.0, 'y': 48},
          r'$.topLeftWorldPx.x',
        ),
        (
          _placementJson()
            ..['opaqueWorldBoundsPx'] = <String, Object?>{
              'x': -15,
              'y': 49,
              'width': '8',
              'height': 12,
            },
          r'$.opaqueWorldBoundsPx.width',
        ),
        (
          _placementJson()
            ..['stableOrderKey'] = <String, Object?>{
              'drawBandIndex': 1,
              'anchorRowMajor': 3,
              'passIndex': 0,
              'rank': true,
              'ordinalLocal': 2,
              'slotKey': 'slot-a',
            },
          r'$.stableOrderKey.rank',
        ),
      ];

      for (final (json, path) in cases) {
        expect(
          () => decodeBorderResolvedPlacementJson(json),
          _formatAt(path),
          reason: path,
        );
      }
    });

    test('rejects malformed IDs, snapshot IDs, and pixel rectangles', () {
      final blankId = _placementJson()..['id'] = ' placement ';
      expect(
        () => decodeBorderResolvedPlacementJson(blankId),
        _formatAt(r'$.id'),
      );

      final snapshot = _placementJson()
        ..['visualSnapshotId'] = 'border-snapshot-sha256:short';
      expect(
        () => decodeBorderResolvedPlacementJson(snapshot),
        _formatAt(r'$.visualSnapshotId'),
      );

      final snapshotWithNewline = _placementJson()
        ..['visualSnapshotId'] = '$_snapshotA\n';
      expect(
        () => decodeBorderResolvedPlacementJson(snapshotWithNewline),
        _formatAt(r'$.visualSnapshotId'),
      );

      final invalidRect = _placementJson();
      (invalidRect['opaqueWorldBoundsPx']! as Map<String, Object?>)['width'] =
          0;
      expect(
        () => decodeBorderResolvedPlacementJson(invalidRect),
        _formatAt(r'$.opaqueWorldBoundsPx.width'),
      );
    });

    test('accepts signed-64 coordinate boundaries as JSON integers', () {
      final json = _placementJson()
        ..['anchorCell'] = <String, Object?>{
          'x': -9223372036854775808,
          'y': 9223372036854775807,
        }
        ..['topLeftWorldPx'] = <String, Object?>{
          'x': -9223372036854775808,
          'y': 9223372036854775807,
        }
        ..['opaqueWorldBoundsPx'] = <String, Object?>{
          'x': -9223372036854775808,
          'y': 9223372036854775806,
          'width': 1,
          'height': 1,
        }
        ..['stableOrderKey'] = <String, Object?>{
          'drawBandIndex': 1,
          'anchorRowMajor': 9223372036854775807,
          'passIndex': 9223372036854775807,
          'rank': 9223372036854775807,
          'ordinalLocal': 9223372036854775807,
          'slotKey': 'slot-a',
        };

      final decoded = decodeBorderResolvedPlacementJson(json);
      final encoded = encodeBorderResolvedPlacementJson(decoded);

      expect(encoded['anchorCell'], json['anchorCell']);
      expect(encoded['topLeftWorldPx'], json['topLeftWorldPx']);
      expect(encoded['opaqueWorldBoundsPx'], json['opaqueWorldBoundsPx']);
      expect(encoded['stableOrderKey'], json['stableOrderKey']);
    });

    test('honors custom paths and does not mutate decoder input', () {
      final input = _placementJson();
      final before = _deepCopy(input);

      expect(
        decodeBorderResolvedPlacementJson(
          input,
          path:
              r'$.layers[4].content.features[0].materialization.placements[2]',
        ),
        _placement(),
      );
      expect(input, before);

      final invalid = _placementJson()..['drawBand'] = 'invalid';
      expect(
        () => decodeBorderResolvedPlacementJson(
          invalid,
          path:
              r'$.layers[4].content.features[0].materialization.placements[2]',
        ),
        _formatAt(
          r'$.layers[4].content.features[0].materialization.placements[2].drawBand',
        ),
      );
    });
  });

  group('BorderMaterialization JSON codec', () {
    test('encodes the exact receipt, ground, and placements wire', () {
      final materialization = _materialization();

      final encoded = encodeBorderMaterializationJson(materialization);

      expect(encoded, _materializationJson());
      expect(
        encoded.keys,
        <String>['receipt', 'ground', 'placements'],
      );
      expect(encoded.toString(), isNot(contains('freshness')));
      expect(encoded.toString(), isNot(contains('integrity')));
      expect(encoded.toString(), isNot(contains('collision')));
      expect(decodeBorderMaterializationJson(encoded), materialization);
    });

    test('maps all 20 Surface roles through stable explicit wire names', () {
      const cases = <(SurfaceVariantRole, String)>[
        (SurfaceVariantRole.isolated, 'isolated'),
        (SurfaceVariantRole.endNorth, 'endNorth'),
        (SurfaceVariantRole.endEast, 'endEast'),
        (SurfaceVariantRole.endSouth, 'endSouth'),
        (SurfaceVariantRole.endWest, 'endWest'),
        (SurfaceVariantRole.horizontal, 'horizontal'),
        (SurfaceVariantRole.vertical, 'vertical'),
        (SurfaceVariantRole.cornerNE, 'cornerNE'),
        (SurfaceVariantRole.cornerSE, 'cornerSE'),
        (SurfaceVariantRole.cornerSW, 'cornerSW'),
        (SurfaceVariantRole.cornerNW, 'cornerNW'),
        (SurfaceVariantRole.innerCornerNE, 'innerCornerNE'),
        (SurfaceVariantRole.innerCornerSE, 'innerCornerSE'),
        (SurfaceVariantRole.innerCornerSW, 'innerCornerSW'),
        (SurfaceVariantRole.innerCornerNW, 'innerCornerNW'),
        (SurfaceVariantRole.teeNorth, 'teeNorth'),
        (SurfaceVariantRole.teeEast, 'teeEast'),
        (SurfaceVariantRole.teeSouth, 'teeSouth'),
        (SurfaceVariantRole.teeWest, 'teeWest'),
        (SurfaceVariantRole.cross, 'cross'),
      ];

      for (final (role, wireName) in cases) {
        final materialization = _materialization(
          ground: <BorderResolvedGroundCell>[
            _ground(resolvedRole: role),
          ],
          placements: const <BorderResolvedPlacement>[],
        );
        final encoded = encodeBorderMaterializationJson(materialization);
        final ground = encoded['ground']! as List<Object?>;
        final cell = ground.single! as Map<String, Object?>;

        expect(cell['resolvedRole'], wireName);
        expect(decodeBorderMaterializationJson(encoded), materialization);
      }
    });

    test('preserves authored runtime list order and never sorts', () {
      final materialization = _materialization(
        ground: <BorderResolvedGroundCell>[
          _ground(x: -2, y: 0, resolvedRole: SurfaceVariantRole.endWest),
          _ground(x: 5, y: 0, resolvedRole: SurfaceVariantRole.endEast),
          _ground(x: -4, y: 2, resolvedRole: SurfaceVariantRole.endSouth),
        ],
        placements: <BorderResolvedPlacement>[
          _placement(
            id: 'outer',
            slotKey: 'slot-outer',
            drawBand: BorderDrawBand.outerAccent,
            stableOrderKey: _orderKey(
              drawBandIndex: 0,
              anchorRowMajor: 99,
              slotKey: 'slot-outer',
            ),
          ),
          _placement(
            id: 'structure',
            slotKey: 'slot-structure',
            drawBand: BorderDrawBand.structure,
            stableOrderKey: _orderKey(
              drawBandIndex: 1,
              anchorRowMajor: 0,
              slotKey: 'slot-structure',
            ),
          ),
        ],
      );

      final encoded = encodeBorderMaterializationJson(materialization);
      final ground = encoded['ground']! as List<Object?>;
      final placements = encoded['placements']! as List<Object?>;

      expect(
        ground.map((value) => (value! as Map<String, Object?>)['x']),
        <int>[-2, 5, -4],
      );
      expect(
        placements.map((value) => (value! as Map<String, Object?>)['id']),
        <String>['outer', 'structure'],
      );
      expect(decodeBorderMaterializationJson(encoded), materialization);
    });

    test('requires exact root, receipt, component, and entry keys', () {
      final unknownRoot = _materializationJson()..['freshness'] = 'fresh';
      expect(
        () => decodeBorderMaterializationJson(unknownRoot),
        _formatAt(r'$.freshness'),
      );

      final unknownReceipt = _materializationJson();
      (unknownReceipt['receipt']! as Map<String, Object?>)['integrity'] = true;
      expect(
        () => decodeBorderMaterializationJson(unknownReceipt),
        _formatAt(r'$.receipt.integrity'),
      );

      final unknownComponent = _materializationJson();
      final receipt = unknownComponent['receipt']! as Map<String, Object?>;
      (receipt['components']! as Map<String, Object?>)['sourceAsset'] = _shaA;
      expect(
        () => decodeBorderMaterializationJson(unknownComponent),
        _formatAt(r'$.receipt.components.sourceAsset'),
      );

      final unknownGround = _materializationJson();
      ((unknownGround['ground']! as List<Object?>).single!
          as Map<String, Object?>)['opacity'] = 1;
      expect(
        () => decodeBorderMaterializationJson(unknownGround),
        _formatAt(r'$.ground[0].opacity'),
      );
    });

    test('requires integer versions and valid repository fingerprints', () {
      final wrongVersion = _materializationJson();
      (wrongVersion['receipt']! as Map<String, Object?>)['resolverVersion'] =
          '1';
      expect(
        () => decodeBorderMaterializationJson(wrongVersion),
        _formatAt(r'$.receipt.resolverVersion'),
      );

      final zeroRevision = _materializationJson();
      (zeroRevision['receipt']! as Map<String, Object?>)['blueprintRevision'] =
          0;
      expect(
        () => decodeBorderMaterializationJson(zeroRevision),
        _formatAt(r'$.receipt.blueprintRevision'),
      );

      final malformedComponent = _materializationJson();
      final malformedReceipt =
          malformedComponent['receipt']! as Map<String, Object?>;
      (malformedReceipt['components']!
          as Map<String, Object?>)['geometryAndSeed'] = 'sha256:short';
      expect(
        () => decodeBorderMaterializationJson(malformedComponent),
        _formatAt(r'$.receipt.components.geometryAndSeed'),
      );

      final componentWithNewline = _materializationJson();
      final newlineReceipt =
          componentWithNewline['receipt']! as Map<String, Object?>;
      (newlineReceipt['components']!
          as Map<String, Object?>)['geometryAndSeed'] = '$_shaB\n';
      expect(
        () => decodeBorderMaterializationJson(componentWithNewline),
        _formatAt(r'$.receipt.components.geometryAndSeed'),
      );

      final malformedAggregate = _materializationJson();
      (malformedAggregate['receipt']!
          as Map<String, Object?>)['outputFingerprint'] = _snapshotA;
      expect(
        () => decodeBorderMaterializationJson(malformedAggregate),
        _formatAt(r'$.receipt.outputFingerprint'),
      );
    });

    test('rejects unknown Surface roles and malformed snapshot IDs', () {
      final unknownRole = _materializationJson();
      ((unknownRole['ground']! as List<Object?>).single!
          as Map<String, Object?>)['resolvedRole'] = 'shore';
      expect(
        () => decodeBorderMaterializationJson(unknownRole),
        _formatAt(r'$.ground[0].resolvedRole'),
      );

      final malformedSnapshot = _materializationJson();
      ((malformedSnapshot['ground']! as List<Object?>).single!
              as Map<String, Object?>)['visualSnapshotId'] =
          'border-snapshot-sha256:short';
      expect(
        () => decodeBorderMaterializationJson(malformedSnapshot),
        _formatAt(r'$.ground[0].visualSnapshotId'),
      );
    });

    test('reports duplicate ground coordinates at the second entry', () {
      final duplicate = _materializationJson();
      final ground = duplicate['ground']! as List<Object?>;
      ground.add(_deepCopy(ground.single)!);

      expect(
        () => decodeBorderMaterializationJson(duplicate),
        _formatAt(r'$.ground[1]'),
      );
    });

    test('reports duplicate placement ids and slots at second fields', () {
      final duplicateId = _materializationJson();
      final placements = duplicateId['placements']! as List<Object?>;
      final secondId = _placementJson(
        id: 'placement-a',
        slotKey: 'slot-b',
        anchorRowMajor: 4,
      );
      placements.add(secondId);
      expect(
        () => decodeBorderMaterializationJson(duplicateId),
        _formatAt(r'$.placements[1].id'),
      );

      final duplicateSlot = _materializationJson();
      final slotPlacements = duplicateSlot['placements']! as List<Object?>;
      final secondSlot = _placementJson(
        id: 'placement-b',
        slotKey: 'slot-a',
        anchorRowMajor: 4,
      );
      slotPlacements.add(secondSlot);
      expect(
        () => decodeBorderMaterializationJson(duplicateSlot),
        _formatAt(r'$.placements[1].slotKey'),
      );
    });

    test('rejects noncanonical ground and placement order without sorting', () {
      final groundOrder = _materializationJson();
      final ground = groundOrder['ground']! as List<Object?>;
      ground.insert(0, <String, Object?>{
        'x': 0,
        'y': 1,
        'visualSnapshotId': _snapshotB,
        'resolvedRole': 'isolated',
      });
      expect(
        () => decodeBorderMaterializationJson(groundOrder),
        _formatAt(r'$.ground[1]'),
      );

      final placementOrder = _materializationJson();
      final placements = placementOrder['placements']! as List<Object?>;
      placements.insert(
        0,
        _placementJson(
          id: 'placement-late',
          slotKey: 'slot-late',
          drawBand: 'accent',
          drawBandIndex: 3,
        ),
      );
      expect(
        () => decodeBorderMaterializationJson(placementOrder),
        _formatAt(r'$.placements[1].stableOrderKey'),
      );
    });

    test('rejects empty materialization and strict ground coordinate types',
        () {
      final empty = _materializationJson()
        ..['ground'] = <Object?>[]
        ..['placements'] = <Object?>[];
      expect(
        () => decodeBorderMaterializationJson(empty),
        _formatAt(r'$'),
      );

      final wrongCoordinate = _materializationJson();
      ((wrongCoordinate['ground']! as List<Object?>).single!
          as Map<String, Object?>)['x'] = 0.0;
      expect(
        () => decodeBorderMaterializationJson(wrongCoordinate),
        _formatAt(r'$.ground[0].x'),
      );
    });

    test('preserves signed-64 versions and ground coordinate boundaries', () {
      final json = _materializationJson();
      final receipt = json['receipt']! as Map<String, Object?>;
      receipt['resolverVersion'] = 9223372036854775807;
      receipt['blueprintRevision'] = 9223372036854775807;
      final ground =
          (json['ground']! as List<Object?>).single! as Map<String, Object?>;
      ground['x'] = -9223372036854775808;
      ground['y'] = 9223372036854775807;

      final decoded = decodeBorderMaterializationJson(json);
      final encoded = encodeBorderMaterializationJson(decoded);
      final encodedReceipt = encoded['receipt']! as Map<String, Object?>;
      final encodedGround =
          (encoded['ground']! as List<Object?>).single! as Map<String, Object?>;

      expect(encodedReceipt['resolverVersion'], 9223372036854775807);
      expect(encodedReceipt['blueprintRevision'], 9223372036854775807);
      expect(encodedGround['x'], -9223372036854775808);
      expect(encodedGround['y'], 9223372036854775807);
    });

    test('honors a custom path and never mutates decoder input', () {
      final input = _materializationJson();
      final before = _deepCopy(input);

      expect(
        decodeBorderMaterializationJson(
          input,
          path: r'$.features[3].materialization',
        ),
        _materialization(),
      );
      expect(input, before);

      final invalid = _materializationJson();
      (invalid['receipt']! as Map<String, Object?>)['resolverVersion'] = 0;
      expect(
        () => decodeBorderMaterializationJson(
          invalid,
          path: r'$.features[3].materialization',
        ),
        _formatAt(
          r'$.features[3].materialization.receipt.resolverVersion',
        ),
      );
    });
  });
}

BorderMaterialization _materialization({
  List<BorderResolvedGroundCell>? ground,
  List<BorderResolvedPlacement>? placements,
}) =>
    BorderMaterialization(
      receipt: _receipt(),
      ground: ground ?? <BorderResolvedGroundCell>[_ground()],
      placements: placements ?? <BorderResolvedPlacement>[_placement()],
    );

BorderResolvedGroundCell _ground({
  int x = 0,
  int y = 0,
  String visualSnapshotId = _snapshotA,
  SurfaceVariantRole resolvedRole = SurfaceVariantRole.innerCornerNE,
}) =>
    BorderResolvedGroundCell(
      x: x,
      y: y,
      visualSnapshotId: visualSnapshotId,
      resolvedRole: resolvedRole,
    );

BorderResolvedPlacement _placement({
  String id = 'placement-a',
  String slotKey = 'slot-a',
  String primitiveId = 'primitive-a',
  String visualSnapshotId = _snapshotB,
  GridPos anchorCell = const GridPos(x: -2, y: 3),
  BorderPixelPos topLeftWorldPx = const BorderPixelPos(x: -16, y: 48),
  BorderPixelRect? opaqueWorldBoundsPx,
  BorderSpriteTransform? transform,
  BorderDrawBand drawBand = BorderDrawBand.structure,
  BorderStableOrderKey? stableOrderKey,
}) =>
    BorderResolvedPlacement(
      id: id,
      slotKey: slotKey,
      primitiveId: primitiveId,
      visualSnapshotId: visualSnapshotId,
      anchorCell: anchorCell,
      topLeftWorldPx: topLeftWorldPx,
      opaqueWorldBoundsPx: opaqueWorldBoundsPx ??
          BorderPixelRect(x: -15, y: 49, width: 8, height: 12),
      transform:
          transform ?? BorderSpriteTransform(quarterTurns: 1, flipX: true),
      drawBand: drawBand,
      stableOrderKey: stableOrderKey ?? _orderKey(slotKey: slotKey),
    );

BorderStableOrderKey _orderKey({
  int drawBandIndex = 1,
  int anchorRowMajor = 3,
  int passIndex = 0,
  int rank = 1,
  int ordinalLocal = 2,
  String slotKey = 'slot-a',
}) =>
    BorderStableOrderKey(
      drawBandIndex: drawBandIndex,
      anchorRowMajor: anchorRowMajor,
      passIndex: passIndex,
      rank: rank,
      ordinalLocal: ordinalLocal,
      slotKey: slotKey,
    );

BorderResolutionReceipt _receipt() => BorderResolutionReceipt(
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
    );

Map<String, Object?> _materializationJson() => <String, Object?>{
      'receipt': <String, Object?>{
        'resolverVersion': 1,
        'blueprintRevision': 2,
        'components': <String, Object?>{
          'blueprint': _shaA,
          'geometryAndSeed': _shaB,
          'parameters': _shaC,
          'overrides': _shaD,
          'keepOutRegions': _shaE,
          'mapContext': _shaF,
          'visualSnapshots': _sha0,
        },
        'inputFingerprint': _sha1,
        'outputFingerprint': _sha2,
      },
      'ground': <Object?>[
        <String, Object?>{
          'x': 0,
          'y': 0,
          'visualSnapshotId': _snapshotA,
          'resolvedRole': 'innerCornerNE',
        },
      ],
      'placements': <Object?>[_placementJson()],
    };

Map<String, Object?> _placementJson({
  String id = 'placement-a',
  String slotKey = 'slot-a',
  String primitiveId = 'primitive-a',
  String visualSnapshotId = _snapshotB,
  String drawBand = 'structure',
  int drawBandIndex = 1,
  int anchorRowMajor = 3,
}) =>
    <String, Object?>{
      'id': id,
      'slotKey': slotKey,
      'primitiveId': primitiveId,
      'visualSnapshotId': visualSnapshotId,
      'anchorCell': <String, Object?>{'x': -2, 'y': 3},
      'topLeftWorldPx': <String, Object?>{'x': -16, 'y': 48},
      'opaqueWorldBoundsPx': <String, Object?>{
        'x': -15,
        'y': 49,
        'width': 8,
        'height': 12,
      },
      'transform': <String, Object?>{
        'quarterTurns': 1,
        'flipX': true,
      },
      'drawBand': drawBand,
      'stableOrderKey': <String, Object?>{
        'drawBandIndex': drawBandIndex,
        'anchorRowMajor': anchorRowMajor,
        'passIndex': 0,
        'rank': 1,
        'ordinalLocal': 2,
        'slotKey': slotKey,
      },
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
const String _snapshotB = 'border-snapshot-sha256:$_hexB';
const String _shaA = 'sha256:$_hexA';
const String _shaB = 'sha256:$_hexB';
const String _shaC = 'sha256:$_hexC';
const String _shaD = 'sha256:$_hexD';
const String _shaE = 'sha256:$_hexE';
const String _shaF = 'sha256:$_hexF';
const String _sha0 = 'sha256:$_hex0';
const String _sha1 = 'sha256:$_hex1';
const String _sha2 = 'sha256:$_hex2';
