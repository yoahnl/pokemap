import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderSpriteTransform', () {
    test('accepts only normalized quarter turns with value semantics', () {
      for (var quarterTurns = 0; quarterTurns <= 3; quarterTurns += 1) {
        final transform = BorderSpriteTransform(
          quarterTurns: quarterTurns,
          flipX: true,
        );

        expect(transform.quarterTurns, quarterTurns);
        expect(transform.flipX, isTrue);
        expect(
          transform,
          BorderSpriteTransform(quarterTurns: quarterTurns, flipX: true),
        );
        expect(
          transform.hashCode,
          BorderSpriteTransform(
            quarterTurns: quarterTurns,
            flipX: true,
          ).hashCode,
        );
        expect(
          transform,
          isNot(
            BorderSpriteTransform(
              quarterTurns: quarterTurns,
              flipX: false,
            ),
          ),
        );
      }

      for (final quarterTurns in <int>[-1, 4]) {
        expect(
          () => BorderSpriteTransform(
            quarterTurns: quarterTurns,
            flipX: false,
          ),
          throwsA(isA<ValidationException>()),
        );
      }

      final base = BorderSpriteTransform(quarterTurns: 0, flipX: false);
      expect(
        <BorderSpriteTransform>[
          BorderSpriteTransform(quarterTurns: 1, flipX: false),
          BorderSpriteTransform(quarterTurns: 0, flipX: true),
        ],
        everyElement(isNot(base)),
      );
    });
  });

  group('BorderDrawBand', () {
    test('exposes the fixed explicit V1 order and stable index mapping', () {
      expect(
        BorderDrawBand.values,
        const <BorderDrawBand>[
          BorderDrawBand.outerAccent,
          BorderDrawBand.structure,
          BorderDrawBand.innerFinish,
          BorderDrawBand.accent,
        ],
      );
      expect(
        borderDrawBandV1Order,
        const <BorderDrawBand>[
          BorderDrawBand.outerAccent,
          BorderDrawBand.structure,
          BorderDrawBand.innerFinish,
          BorderDrawBand.accent,
        ],
      );
      expect(
        [for (final band in borderDrawBandV1Order) band.stableV1Index],
        const <int>[0, 1, 2, 3],
      );
      expect(
        [for (final band in borderDrawBandV1Order) borderDrawBandV1Index(band)],
        const <int>[0, 1, 2, 3],
      );
    });
  });

  group('BorderStableOrderKey', () {
    test('requires nonnegative numeric fields and a stable slot key', () {
      for (final createInvalid in <BorderStableOrderKey Function()>[
        () => _orderKey(drawBandIndex: -1),
        () => _orderKey(anchorRowMajor: -1),
        () => _orderKey(passIndex: -1),
        () => _orderKey(rank: -1),
        () => _orderKey(ordinalLocal: -1),
        () => _orderKey(slotKey: ''),
        () => _orderKey(slotKey: '   '),
        () => _orderKey(slotKey: ' slot-a'),
        () => _orderKey(slotKey: 'slot-a '),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('compares the six fields directly in the approved order', () {
      const maximum = 9223372036854775807;
      final orderedPairs = <(BorderStableOrderKey, BorderStableOrderKey)>[
        (
          _orderKey(
            drawBandIndex: 0,
            anchorRowMajor: maximum,
            passIndex: maximum,
            rank: maximum,
            ordinalLocal: maximum,
            slotKey: 'z',
          ),
          _orderKey(drawBandIndex: 1, slotKey: 'a'),
        ),
        (
          _orderKey(
            anchorRowMajor: 0,
            passIndex: maximum,
            rank: maximum,
            ordinalLocal: maximum,
            slotKey: 'z',
          ),
          _orderKey(anchorRowMajor: 1, slotKey: 'a'),
        ),
        (
          _orderKey(
            passIndex: 0,
            rank: maximum,
            ordinalLocal: maximum,
            slotKey: 'z',
          ),
          _orderKey(passIndex: 1, slotKey: 'a'),
        ),
        (
          _orderKey(
            rank: 0,
            ordinalLocal: maximum,
            slotKey: 'z',
          ),
          _orderKey(rank: 1, slotKey: 'a'),
        ),
        (
          _orderKey(ordinalLocal: 0, slotKey: 'z'),
          _orderKey(ordinalLocal: 1, slotKey: 'a'),
        ),
        (
          _orderKey(slotKey: 'slot-a'),
          _orderKey(slotKey: 'slot-b'),
        ),
      ];

      for (final (first, second) in orderedPairs) {
        expect(first.compareTo(second), isNegative);
        expect(second.compareTo(first), isPositive);
      }
      expect(_orderKey().compareTo(_orderKey()), 0);
    });

    test('handles the signed integer maximum without subtractive overflow', () {
      const maximum = 9223372036854775807;
      final smallest = _orderKey(drawBandIndex: 0);
      final largest = _orderKey(drawBandIndex: maximum);

      expect(smallest.compareTo(largest), isNegative);
      expect(largest.compareTo(smallest), isPositive);
    });

    test('has equality and hash semantics across every persisted field', () {
      final key = _orderKey(
        drawBandIndex: 3,
        anchorRowMajor: 20,
        passIndex: 2,
        rank: 4,
        ordinalLocal: 6,
        slotKey: 'slot-z',
      );
      final equal = _orderKey(
        drawBandIndex: 3,
        anchorRowMajor: 20,
        passIndex: 2,
        rank: 4,
        ordinalLocal: 6,
        slotKey: 'slot-z',
      );

      expect(key, equal);
      expect(key.hashCode, equal.hashCode);
      expect(
        <BorderStableOrderKey>[
          _orderKey(
            drawBandIndex: 2,
            anchorRowMajor: 20,
            passIndex: 2,
            rank: 4,
            ordinalLocal: 6,
            slotKey: 'slot-z',
          ),
          _orderKey(
            drawBandIndex: 3,
            anchorRowMajor: 21,
            passIndex: 2,
            rank: 4,
            ordinalLocal: 6,
            slotKey: 'slot-z',
          ),
          _orderKey(
            drawBandIndex: 3,
            anchorRowMajor: 20,
            passIndex: 3,
            rank: 4,
            ordinalLocal: 6,
            slotKey: 'slot-z',
          ),
          _orderKey(
            drawBandIndex: 3,
            anchorRowMajor: 20,
            passIndex: 2,
            rank: 5,
            ordinalLocal: 6,
            slotKey: 'slot-z',
          ),
          _orderKey(
            drawBandIndex: 3,
            anchorRowMajor: 20,
            passIndex: 2,
            rank: 4,
            ordinalLocal: 7,
            slotKey: 'slot-z',
          ),
          _orderKey(
            drawBandIndex: 3,
            anchorRowMajor: 20,
            passIndex: 2,
            rank: 4,
            ordinalLocal: 6,
            slotKey: 'slot-y',
          ),
        ],
        everyElement(isNot(key)),
      );
    });
  });

  group('BorderResolvedPlacement', () {
    test('owns a generic mutable GridPos and permits out-of-map anchors', () {
      final sourceAnchor = _MutableGridPos(
        x: -9223372036854775808,
        y: 9223372036854775807,
      );
      final placement = _placement(anchorCell: sourceAnchor);

      sourceAnchor
        ..x = 100
        ..y = 200;

      expect(
        placement.anchorCell,
        const GridPos(
          x: -9223372036854775808,
          y: 9223372036854775807,
        ),
      );
      expect(placement.anchorCell, isNot(same(sourceAnchor)));
      expect(placement, _placement(anchorCell: placement.anchorCell));
      expect(
        placement.hashCode,
        _placement(anchorCell: placement.anchorCell).hashCode,
      );
    });

    test('requires nonblank already-trimmed persisted identities', () {
      for (final invalid in <String>['', '   ', ' value', 'value ']) {
        expect(
          () => _placement(id: invalid),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => _placement(slotKey: invalid),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => _placement(primitiveId: invalid),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('requires exact immutable visual snapshot identity syntax', () {
      for (final snapshotId in _malformedSnapshotIds) {
        expect(
          () => _placement(visualSnapshotId: snapshotId),
          throwsA(isA<ValidationException>()),
          reason: snapshotId,
        );
      }
    });

    test('requires slot and draw-band consistency with its stable key', () {
      expect(
        () => _placement(
          slotKey: 'slot-a',
          stableOrderKey: _orderKey(slotKey: 'slot-b'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _placement(
          drawBand: BorderDrawBand.structure,
          stableOrderKey: _orderKey(
            drawBandIndex: BorderDrawBand.accent.stableV1Index,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('stores the complete approved persisted placement contract', () {
      final placement = _placement();

      expect(placement.id, 'placement-a');
      expect(placement.slotKey, 'slot-a');
      expect(placement.primitiveId, 'primitive-a');
      expect(placement.visualSnapshotId, _snapshotId);
      expect(placement.anchorCell, const GridPos(x: -2, y: 3));
      expect(placement.topLeftWorldPx, const BorderPixelPos(x: -16, y: 48));
      expect(
        placement.opaqueWorldBoundsPx,
        BorderPixelRect(x: -15, y: 49, width: 8, height: 12),
      );
      expect(
        placement.transform,
        BorderSpriteTransform(quarterTurns: 1, flipX: true),
      );
      expect(placement.drawBand, BorderDrawBand.structure);
      expect(placement.stableOrderKey, _orderKey());
    });

    test('equality includes every persisted placement field', () {
      final placement = _placement();
      expect(
        <BorderResolvedPlacement>[
          _placement(id: 'placement-b'),
          _placement(slotKey: 'slot-b'),
          _placement(primitiveId: 'primitive-b'),
          _placement(visualSnapshotId: _snapshotIdB),
          _placement(anchorCell: const GridPos(x: -1, y: 3)),
          _placement(topLeftWorldPx: const BorderPixelPos(x: -15, y: 48)),
          _placement(
            opaqueWorldBoundsPx:
                BorderPixelRect(x: -14, y: 49, width: 8, height: 12),
          ),
          _placement(
            transform: BorderSpriteTransform(quarterTurns: 2, flipX: true),
          ),
          _placement(drawBand: BorderDrawBand.innerFinish),
          _placement(
            stableOrderKey: _orderKey(anchorRowMajor: 11),
          ),
        ],
        everyElement(isNot(placement)),
      );
    });
  });

  group('BorderResolvedGroundCell', () {
    test('permits out-of-map coordinates with value semantics', () {
      final ground = _ground(
        x: -9223372036854775808,
        y: 9223372036854775807,
      );
      final equal = _ground(
        x: -9223372036854775808,
        y: 9223372036854775807,
      );

      expect(ground.x, -9223372036854775808);
      expect(ground.y, 9223372036854775807);
      expect(ground.visualSnapshotId, _snapshotId);
      expect(ground.resolvedRole, SurfaceVariantRole.innerCornerNE);
      expect(ground, equal);
      expect(ground.hashCode, equal.hashCode);
      expect(
        <BorderResolvedGroundCell>[
          _ground(x: -9223372036854775807, y: 9223372036854775807),
          _ground(x: -9223372036854775808, y: 9223372036854775806),
          _ground(
            x: -9223372036854775808,
            y: 9223372036854775807,
            visualSnapshotId: _snapshotIdB,
          ),
          _ground(
            x: -9223372036854775808,
            y: 9223372036854775807,
            resolvedRole: SurfaceVariantRole.cross,
          ),
        ],
        everyElement(isNot(ground)),
      );
    });

    test('requires exact immutable visual snapshot identity syntax', () {
      for (final snapshotId in _malformedSnapshotIds) {
        expect(
          () => _ground(visualSnapshotId: snapshotId),
          throwsA(isA<ValidationException>()),
          reason: snapshotId,
        );
      }
    });
  });

  group('BorderInputFingerprints', () {
    test('stores all component hashes with value semantics', () {
      final fingerprints = _fingerprints();
      final equal = _fingerprints();

      expect(fingerprints.blueprint, _shaA);
      expect(fingerprints.geometryAndSeed, _shaB);
      expect(fingerprints.parameters, _shaC);
      expect(fingerprints.overrides, _shaD);
      expect(fingerprints.keepOutRegions, _shaE);
      expect(fingerprints.mapContext, _shaF);
      expect(fingerprints.visualSnapshots, _shaG);
      expect(fingerprints, equal);
      expect(fingerprints.hashCode, equal.hashCode);
      expect(
        <BorderInputFingerprints>[
          _fingerprints(blueprint: _shaB),
          _fingerprints(geometryAndSeed: _shaC),
          _fingerprints(parameters: _shaD),
          _fingerprints(overrides: _shaE),
          _fingerprints(keepOutRegions: _shaF),
          _fingerprints(mapContext: _shaG),
          _fingerprints(visualSnapshots: _shaH),
        ],
        everyElement(isNot(fingerprints)),
      );
    });

    test('requires repository SHA-256 syntax for every component', () {
      for (final createInvalid in <BorderInputFingerprints Function()>[
        () => _fingerprints(blueprint: '$_shaA\n'),
        () => _fingerprints(geometryAndSeed: _uppercaseSha),
        () => _fingerprints(parameters: 'sha256:abc'),
        () => _fingerprints(overrides: _snapshotId),
        () => _fingerprints(keepOutRegions: _hexA),
        () => _fingerprints(mapContext: ' sha256:$_hexA'),
        () => _fingerprints(visualSnapshots: ''),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });
  });

  group('BorderResolutionReceipt', () {
    test('stores versions, component hashes, and aggregate hashes', () {
      final receipt = _receipt();
      final equal = _receipt();

      expect(receipt.resolverVersion, 1);
      expect(receipt.blueprintRevision, 2);
      expect(receipt.components, _fingerprints());
      expect(receipt.inputFingerprint, _shaH);
      expect(receipt.outputFingerprint, _shaI);
      expect(receipt, equal);
      expect(receipt.hashCode, equal.hashCode);
      expect(_receipt(blueprintRevision: 1).blueprintRevision, 1);
      expect(
        <BorderResolutionReceipt>[
          _receipt(resolverVersion: 2),
          _receipt(blueprintRevision: 3),
          _receipt(
            components: _fingerprints(blueprint: _shaB),
          ),
          _receipt(inputFingerprint: _shaA),
          _receipt(outputFingerprint: _shaB),
        ],
        everyElement(isNot(receipt)),
      );
    });

    test('requires positive versions and repository SHA-256 syntax', () {
      for (final createInvalid in <BorderResolutionReceipt Function()>[
        () => _receipt(resolverVersion: 0),
        () => _receipt(resolverVersion: -1),
        () => _receipt(blueprintRevision: 0),
        () => _receipt(blueprintRevision: -1),
        () => _receipt(inputFingerprint: _uppercaseSha),
        () => _receipt(outputFingerprint: 'sha256:short'),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });
  });

  group('BorderMaterialization', () {
    test('owns immutable ordered ground and placement lists', () {
      final ground = <BorderResolvedGroundCell>[
        _ground(x: -1, y: 0),
        _ground(x: 2, y: 0),
        _ground(x: -5, y: 1),
      ];
      final placements = <BorderResolvedPlacement>[
        _placement(id: 'first', slotKey: 'slot-a'),
        _placement(
          id: 'second',
          slotKey: 'slot-b',
          stableOrderKey: _orderKey(slotKey: 'slot-b'),
        ),
      ];
      final materialization = BorderMaterialization(
        receipt: _receipt(),
        ground: ground,
        placements: placements,
      );

      ground.clear();
      placements.clear();

      expect(
        materialization.ground,
        <BorderResolvedGroundCell>[
          _ground(x: -1, y: 0),
          _ground(x: 2, y: 0),
          _ground(x: -5, y: 1),
        ],
      );
      expect(
        materialization.placements.map((placement) => placement.id),
        <String>['first', 'second'],
      );
      expect(
        () => materialization.ground.add(_ground()),
        throwsUnsupportedError,
      );
      expect(
        () => materialization.placements.add(_placement()),
        throwsUnsupportedError,
      );

      final equal = BorderMaterialization(
        receipt: _receipt(),
        ground: materialization.ground,
        placements: materialization.placements,
      );
      expect(materialization, equal);
      expect(materialization.hashCode, equal.hashCode);
      expect(
        <BorderMaterialization>[
          BorderMaterialization(
            receipt: _receipt(resolverVersion: 2),
            ground: materialization.ground,
            placements: materialization.placements,
          ),
          BorderMaterialization(
            receipt: _receipt(),
            ground: <BorderResolvedGroundCell>[
              _ground(x: -2, y: 0),
              _ground(x: 2, y: 0),
              _ground(x: -5, y: 1),
            ],
            placements: materialization.placements,
          ),
          BorderMaterialization(
            receipt: _receipt(),
            ground: materialization.ground,
            placements: <BorderResolvedPlacement>[
              _placement(id: 'changed', slotKey: 'slot-a'),
              _placement(
                id: 'second',
                slotKey: 'slot-b',
                stableOrderKey: _orderKey(slotKey: 'slot-b'),
              ),
            ],
          ),
        ],
        everyElement(isNot(materialization)),
      );
    });

    test('requires at least one resolved output', () {
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: const <BorderResolvedGroundCell>[],
          placements: const <BorderResolvedPlacement>[],
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(
        BorderMaterialization(
          receipt: _receipt(),
          ground: <BorderResolvedGroundCell>[_ground()],
          placements: const <BorderResolvedPlacement>[],
        ).ground,
        hasLength(1),
      );
      expect(
        BorderMaterialization(
          receipt: _receipt(),
          ground: const <BorderResolvedGroundCell>[],
          placements: <BorderResolvedPlacement>[_placement()],
        ).placements,
        hasLength(1),
      );
    });

    test('rejects duplicate ground coordinates', () {
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: <BorderResolvedGroundCell>[
            _ground(x: 2, y: 3),
            _ground(x: 2, y: 3, resolvedRole: SurfaceVariantRole.cross),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate placement ids and slot keys', () {
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: const <BorderResolvedGroundCell>[],
          placements: <BorderResolvedPlacement>[
            _placement(id: 'same', slotKey: 'slot-a'),
            _placement(
              id: 'same',
              slotKey: 'slot-b',
              stableOrderKey: _orderKey(slotKey: 'slot-b'),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: const <BorderResolvedGroundCell>[],
          placements: <BorderResolvedPlacement>[
            _placement(id: 'first', slotKey: 'same'),
            _placement(id: 'second', slotKey: 'same'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires direct row-major ground order without coordinate math', () {
      const minimum = -9223372036854775808;
      const maximum = 9223372036854775807;
      final ordered = <BorderResolvedGroundCell>[
        _ground(x: minimum, y: minimum),
        _ground(x: maximum, y: minimum),
        _ground(x: minimum, y: maximum),
        _ground(x: maximum, y: maximum),
      ];

      expect(
        BorderMaterialization(
          receipt: _receipt(),
          ground: ordered,
          placements: const <BorderResolvedPlacement>[],
        ).ground,
        ordered,
      );
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: <BorderResolvedGroundCell>[
            _ground(x: maximum, y: minimum),
            _ground(x: minimum, y: minimum),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: <BorderResolvedGroundCell>[
            _ground(x: minimum, y: maximum),
            _ground(x: maximum, y: minimum),
          ],
          placements: const <BorderResolvedPlacement>[],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires nondecreasing stable placement order and never sorts', () {
      const maximum = 9223372036854775807;
      final first = _placement(
        id: 'first',
        slotKey: 'slot-z',
        drawBand: BorderDrawBand.outerAccent,
        stableOrderKey: _orderKey(
          drawBandIndex: BorderDrawBand.outerAccent.stableV1Index,
          anchorRowMajor: maximum,
          passIndex: maximum,
          rank: maximum,
          ordinalLocal: maximum,
          slotKey: 'slot-z',
        ),
      );
      final second = _placement(
        id: 'second',
        slotKey: 'slot-a',
        drawBand: BorderDrawBand.structure,
        stableOrderKey: _orderKey(
          drawBandIndex: BorderDrawBand.structure.stableV1Index,
          slotKey: 'slot-a',
        ),
      );
      final materialization = BorderMaterialization(
        receipt: _receipt(),
        ground: const <BorderResolvedGroundCell>[],
        placements: <BorderResolvedPlacement>[first, second],
      );

      expect(
          materialization.placements, <BorderResolvedPlacement>[first, second]);
      expect(
        () => BorderMaterialization(
          receipt: _receipt(),
          ground: const <BorderResolvedGroundCell>[],
          placements: <BorderResolvedPlacement>[second, first],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BorderVisualSnapshotIntegrity', () {
    test('is valid only when all supplied integrity checks pass', () {
      final valid = BorderVisualSnapshotIntegrity(
        snapshotId: _snapshotId,
        metadataValid: true,
        filesPresent: true,
        contentFingerprintMatches: true,
      );

      expect(valid.isValid, isTrue);
      expect(
        valid,
        BorderVisualSnapshotIntegrity(
          snapshotId: _snapshotId,
          metadataValid: true,
          filesPresent: true,
          contentFingerprintMatches: true,
        ),
      );
      expect(
        valid.hashCode,
        BorderVisualSnapshotIntegrity(
          snapshotId: _snapshotId,
          metadataValid: true,
          filesPresent: true,
          contentFingerprintMatches: true,
        ).hashCode,
      );
      expect(
        <BorderVisualSnapshotIntegrity>[
          BorderVisualSnapshotIntegrity(
            snapshotId: _snapshotIdB,
            metadataValid: true,
            filesPresent: true,
            contentFingerprintMatches: true,
          ),
          BorderVisualSnapshotIntegrity(
            snapshotId: _snapshotId,
            metadataValid: false,
            filesPresent: true,
            contentFingerprintMatches: true,
          ),
          BorderVisualSnapshotIntegrity(
            snapshotId: _snapshotId,
            metadataValid: true,
            filesPresent: false,
            contentFingerprintMatches: true,
          ),
          BorderVisualSnapshotIntegrity(
            snapshotId: _snapshotId,
            metadataValid: true,
            filesPresent: true,
            contentFingerprintMatches: false,
          ),
        ],
        everyElement(isNot(valid)),
      );

      for (final flags in <(bool, bool, bool)>[
        (false, true, true),
        (true, false, true),
        (true, true, false),
        (false, false, false),
      ]) {
        expect(
          BorderVisualSnapshotIntegrity(
            snapshotId: _snapshotId,
            metadataValid: flags.$1,
            filesPresent: flags.$2,
            contentFingerprintMatches: flags.$3,
          ).isValid,
          isFalse,
        );
      }
    });

    test('requires exact immutable visual snapshot identity syntax', () {
      for (final snapshotId in _malformedSnapshotIds) {
        expect(
          () => BorderVisualSnapshotIntegrity(
            snapshotId: snapshotId,
            metadataValid: true,
            filesPresent: true,
            contentFingerprintMatches: true,
          ),
          throwsA(isA<ValidationException>()),
          reason: snapshotId,
        );
      }
    });
  });

  group('BorderMaterializationFreshness', () {
    test('exposes the exact approved state and reason enums', () {
      expect(
        BorderMaterializationState.values,
        const <BorderMaterializationState>[
          BorderMaterializationState.fresh,
          BorderMaterializationState.stale,
          BorderMaterializationState.unmaterialized,
          BorderMaterializationState.invalid,
        ],
      );
      expect(
        BorderStalenessReason.values,
        const <BorderStalenessReason>[
          BorderStalenessReason.blueprintNewer,
          BorderStalenessReason.blueprintMissing,
          BorderStalenessReason.geometryOrSeedChanged,
          BorderStalenessReason.parametersChanged,
          BorderStalenessReason.overridesChanged,
          BorderStalenessReason.keepOutRegionsChanged,
          BorderStalenessReason.mapContextChanged,
          BorderStalenessReason.resolverNewer,
          BorderStalenessReason.visualSnapshotMissingOrCorrupt,
          BorderStalenessReason.outputAltered,
        ],
      );
    });

    test('owns immutable reasons with unordered value semantics', () {
      final source = <BorderStalenessReason>{
        BorderStalenessReason.parametersChanged,
        BorderStalenessReason.resolverNewer,
      };
      final freshness = BorderMaterializationFreshness(
        state: BorderMaterializationState.stale,
        reasons: source,
        isRenderable: true,
        canRegenerate: true,
      );

      source.clear();

      expect(
        freshness.reasons,
        <BorderStalenessReason>{
          BorderStalenessReason.parametersChanged,
          BorderStalenessReason.resolverNewer,
        },
      );
      expect(
        () => freshness.reasons.add(BorderStalenessReason.blueprintNewer),
        throwsUnsupportedError,
      );

      final equal = BorderMaterializationFreshness(
        state: BorderMaterializationState.stale,
        reasons: <BorderStalenessReason>{
          BorderStalenessReason.resolverNewer,
          BorderStalenessReason.parametersChanged,
        },
        isRenderable: true,
        canRegenerate: true,
      );
      expect(freshness, equal);
      expect(freshness.hashCode, equal.hashCode);
      expect(
        _freshness(
          state: BorderMaterializationState.stale,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.parametersChanged,
          },
          isRenderable: true,
          canRegenerate: true,
        ),
        isNot(freshness),
      );
      expect(
        _freshness(
          state: BorderMaterializationState.stale,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.parametersChanged,
            BorderStalenessReason.resolverNewer,
          },
          isRenderable: true,
          canRegenerate: false,
        ),
        isNot(freshness),
      );
      expect(
        _freshness(
          state: BorderMaterializationState.invalid,
          reasons: const <BorderStalenessReason>{},
          isRenderable: false,
          canRegenerate: true,
        ),
        isNot(
          _freshness(
            state: BorderMaterializationState.unmaterialized,
            reasons: const <BorderStalenessReason>{},
            isRenderable: false,
            canRegenerate: true,
          ),
        ),
      );
    });

    test('accepts each basic state-consistent shape', () {
      expect(
        _freshness(
          state: BorderMaterializationState.fresh,
          reasons: const <BorderStalenessReason>{},
          isRenderable: true,
          canRegenerate: true,
        ).state,
        BorderMaterializationState.fresh,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.fresh,
          reasons: const <BorderStalenessReason>{},
          isRenderable: true,
          canRegenerate: false,
        ).canRegenerate,
        isFalse,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.stale,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.blueprintMissing,
          },
          isRenderable: true,
          canRegenerate: false,
        ).state,
        BorderMaterializationState.stale,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.stale,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.visualSnapshotMissingOrCorrupt,
          },
          isRenderable: true,
          canRegenerate: false,
        ).state,
        BorderMaterializationState.stale,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.unmaterialized,
          reasons: const <BorderStalenessReason>{},
          isRenderable: false,
          canRegenerate: true,
        ).state,
        BorderMaterializationState.unmaterialized,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.invalid,
          reasons: const <BorderStalenessReason>{},
          isRenderable: false,
          canRegenerate: true,
        ).state,
        BorderMaterializationState.invalid,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.invalid,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.visualSnapshotMissingOrCorrupt,
          },
          isRenderable: false,
          canRegenerate: true,
        ).state,
        BorderMaterializationState.invalid,
      );
      expect(
        _freshness(
          state: BorderMaterializationState.invalid,
          reasons: const <BorderStalenessReason>{
            BorderStalenessReason.outputAltered,
          },
          isRenderable: false,
          canRegenerate: false,
        ).state,
        BorderMaterializationState.invalid,
      );
    });

    test('rejects contradictory state, reasons, and flags', () {
      for (final createInvalid in <BorderMaterializationFreshness Function()>[
        () => _freshness(
              state: BorderMaterializationState.fresh,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.blueprintNewer,
              },
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.fresh,
              reasons: const <BorderStalenessReason>{},
              isRenderable: false,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.stale,
              reasons: const <BorderStalenessReason>{},
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.stale,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.outputAltered,
              },
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.stale,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.visualSnapshotMissingOrCorrupt,
              },
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.stale,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.parametersChanged,
              },
              isRenderable: false,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.unmaterialized,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.parametersChanged,
              },
              isRenderable: false,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.unmaterialized,
              reasons: const <BorderStalenessReason>{},
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.invalid,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.outputAltered,
              },
              isRenderable: true,
              canRegenerate: true,
            ),
        () => _freshness(
              state: BorderMaterializationState.invalid,
              reasons: const <BorderStalenessReason>{
                BorderStalenessReason.blueprintMissing,
              },
              isRenderable: false,
              canRegenerate: true,
            ),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });
  });
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
const String _hexG =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const String _hexH =
    '123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0';
const String _hexI =
    '23456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01';
const String _shaA = 'sha256:$_hexA';
const String _shaB = 'sha256:$_hexB';
const String _shaC = 'sha256:$_hexC';
const String _shaD = 'sha256:$_hexD';
const String _shaE = 'sha256:$_hexE';
const String _shaF = 'sha256:$_hexF';
const String _shaG = 'sha256:$_hexG';
const String _shaH = 'sha256:$_hexH';
const String _shaI = 'sha256:$_hexI';
const String _snapshotId = 'border-snapshot-sha256:$_hexA';
const String _snapshotIdB = 'border-snapshot-sha256:$_hexB';
const String _uppercaseSha =
    'sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

const List<String> _malformedSnapshotIds = <String>[
  '',
  'border-snapshot-sha256:abc',
  'border-snapshot-sha256:'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  _shaA,
  'border-snapshot-sha256:$_hexA\n',
  ' border-snapshot-sha256:$_hexA',
];

BorderStableOrderKey _orderKey({
  int drawBandIndex = 1,
  int anchorRowMajor = 10,
  int passIndex = 0,
  int rank = 0,
  int ordinalLocal = 0,
  String slotKey = 'slot-a',
}) {
  return BorderStableOrderKey(
    drawBandIndex: drawBandIndex,
    anchorRowMajor: anchorRowMajor,
    passIndex: passIndex,
    rank: rank,
    ordinalLocal: ordinalLocal,
    slotKey: slotKey,
  );
}

BorderResolvedPlacement _placement({
  String id = 'placement-a',
  String slotKey = 'slot-a',
  String primitiveId = 'primitive-a',
  String visualSnapshotId = _snapshotId,
  GridPos anchorCell = const GridPos(x: -2, y: 3),
  BorderPixelPos topLeftWorldPx = const BorderPixelPos(x: -16, y: 48),
  BorderPixelRect? opaqueWorldBoundsPx,
  BorderSpriteTransform? transform,
  BorderDrawBand drawBand = BorderDrawBand.structure,
  BorderStableOrderKey? stableOrderKey,
}) {
  return BorderResolvedPlacement(
    id: id,
    slotKey: slotKey,
    primitiveId: primitiveId,
    visualSnapshotId: visualSnapshotId,
    anchorCell: anchorCell,
    topLeftWorldPx: topLeftWorldPx,
    opaqueWorldBoundsPx: opaqueWorldBoundsPx ??
        BorderPixelRect(x: -15, y: 49, width: 8, height: 12),
    transform: transform ?? BorderSpriteTransform(quarterTurns: 1, flipX: true),
    drawBand: drawBand,
    stableOrderKey: stableOrderKey ??
        _orderKey(
          drawBandIndex: drawBand.stableV1Index,
          slotKey: slotKey,
        ),
  );
}

BorderResolvedGroundCell _ground({
  int x = 0,
  int y = 0,
  String visualSnapshotId = _snapshotId,
  SurfaceVariantRole resolvedRole = SurfaceVariantRole.innerCornerNE,
}) {
  return BorderResolvedGroundCell(
    x: x,
    y: y,
    visualSnapshotId: visualSnapshotId,
    resolvedRole: resolvedRole,
  );
}

BorderInputFingerprints _fingerprints({
  String blueprint = _shaA,
  String geometryAndSeed = _shaB,
  String parameters = _shaC,
  String overrides = _shaD,
  String keepOutRegions = _shaE,
  String mapContext = _shaF,
  String visualSnapshots = _shaG,
}) {
  return BorderInputFingerprints(
    blueprint: blueprint,
    geometryAndSeed: geometryAndSeed,
    parameters: parameters,
    overrides: overrides,
    keepOutRegions: keepOutRegions,
    mapContext: mapContext,
    visualSnapshots: visualSnapshots,
  );
}

BorderResolutionReceipt _receipt({
  int resolverVersion = 1,
  int blueprintRevision = 2,
  BorderInputFingerprints? components,
  String inputFingerprint = _shaH,
  String outputFingerprint = _shaI,
}) {
  return BorderResolutionReceipt(
    resolverVersion: resolverVersion,
    blueprintRevision: blueprintRevision,
    components: components ?? _fingerprints(),
    inputFingerprint: inputFingerprint,
    outputFingerprint: outputFingerprint,
  );
}

BorderMaterializationFreshness _freshness({
  required BorderMaterializationState state,
  required Set<BorderStalenessReason> reasons,
  required bool isRenderable,
  required bool canRegenerate,
}) {
  return BorderMaterializationFreshness(
    state: state,
    reasons: reasons,
    isRenderable: isRenderable,
    canRegenerate: canRegenerate,
  );
}

final class _MutableGridPos implements GridPos {
  _MutableGridPos({required this.x, required this.y});

  @override
  int x;

  @override
  int y;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
