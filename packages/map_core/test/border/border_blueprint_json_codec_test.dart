import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderGenerationParams JSON codec', () {
    test('encodes exact keys and round-trips', () {
      final params = _params();

      final encoded = encodeBorderGenerationParamsJson(params);

      expect(encoded, <String, Object?>{
        'irregularityPermille': 101,
        'detailDensityPermille': 202,
        'variationPermille': 303,
        'maxOverlapPx': 4,
        'gapTolerancePx': 5,
        'depthRows': 2,
      });
      expect(decodeBorderGenerationParamsJson(encoded), params);
    });

    test('requires exact keys, strict integers, and model bounds', () {
      final unknown = _paramsJson()..['extra'] = 1;
      expect(
        () => decodeBorderGenerationParamsJson(unknown),
        _formatAt(r'$.extra'),
      );

      final missing = _paramsJson()..remove('depthRows');
      expect(
        () => decodeBorderGenerationParamsJson(missing),
        _formatAt(r'$.depthRows'),
      );

      for (final bad in <Object?>[null, 1.0, '1', true]) {
        final wrong = _paramsJson()..['maxOverlapPx'] = bad;
        expect(
          () => decodeBorderGenerationParamsJson(wrong),
          _formatAt(r'$.maxOverlapPx'),
          reason: '$bad',
        );
      }

      for (final entry in <MapEntry<String, int>>[
        const MapEntry<String, int>('irregularityPermille', -1),
        const MapEntry<String, int>('detailDensityPermille', 1001),
        const MapEntry<String, int>('variationPermille', 1001),
        const MapEntry<String, int>('maxOverlapPx', -1),
        const MapEntry<String, int>('gapTolerancePx', -1),
        const MapEntry<String, int>('depthRows', 0),
      ]) {
        final invalid = _paramsJson()..[entry.key] = entry.value;
        expect(
          () => decodeBorderGenerationParamsJson(invalid),
          _formatAt('\$.${entry.key}'),
          reason: '${entry.key}: ${entry.value}',
        );
      }
    });

    test('honors a custom path and does not mutate input', () {
      final input = _paramsJson();
      final before = _copy(input);

      expect(
        decodeBorderGenerationParamsJson(
          input,
          path: r'$.catalog.records[3].draft.definition.defaults',
        ),
        _params(),
      );
      expect(input, before);
    });

    test('persists the rotation toggle in V2 and rejects destructive V1 writes',
        () {
      final disabled = _params(allowAutoRotation: false);

      final encodedV2 = encodeBorderGenerationParamsJson(
        disabled,
        formatVersion: 2,
      );
      expect(encodedV2['allowAutoRotation'], isFalse);
      expect(
        decodeBorderGenerationParamsJson(encodedV2, formatVersion: 2),
        disabled,
      );

      expect(
        () => encodeBorderGenerationParamsJson(disabled),
        _formatAt(r'$.allowAutoRotation'),
      );

      final encodedV1 = encodeBorderGenerationParamsJson(_params());
      expect(encodedV1, isNot(contains('allowAutoRotation')));
      expect(
        decodeBorderGenerationParamsJson(encodedV1).allowAutoRotation,
        isTrue,
      );
    });
  });

  group('BorderBlueprintRecord JSON codec', () {
    test('encodes the exact canonical draft and published wire shape', () {
      final record = _record(
        draftRoles: const <BorderPrimitiveRole>[
          BorderPrimitiveRole.structureLarge,
        ],
        publishedRoles: const <BorderPrimitiveRole>[
          BorderPrimitiveRole.structureLarge,
        ],
        withGround: false,
      );

      final encoded = encodeBorderBlueprintRecordJson(record);

      expect(encoded, <String, Object?>{
        'id': 'coast',
        'draft': <String, Object?>{
          'baseRevision': 1,
          'definition': <String, Object?>{
            'name': 'Coast',
            'previewSeed': '-7',
            'template': 'organicEdge',
            'primitives': <Object?>[
              <String, Object?>{
                'id': 'draft-0',
                'sourceElementId': 'element-0',
                'role': 'structureLarge',
                'weight': 0,
                'anchorPx': <String, Object?>{'x': -2, 'y': 5},
                'transforms': <String, Object?>{
                  'allowFlipX': true,
                  'allowedQuarterTurns': <int>[0, 2, 3],
                },
                'currentMetrics': _metricsJson(),
              },
            ],
            'defaults': _paramsJson(),
            'categoryId': 'nature',
            'sortOrder': -4,
          },
        },
        'latestPublished': <String, Object?>{
          'revision': 1,
          'definition': <String, Object?>{
            'name': 'Coast published',
            'previewSeed': '8',
            'template': 'organicEdge',
            'primitives': <Object?>[
              <String, Object?>{
                'id': 'published-0',
                'sourceElementId': 'element-0',
                'visualSnapshotId': 'snapshot-0',
                'role': 'structureLarge',
                'weight': 1,
                'anchorPx': <String, Object?>{'x': -2, 'y': 5},
                'transforms': <String, Object?>{
                  'allowFlipX': true,
                  'allowedQuarterTurns': <int>[0, 2, 3],
                },
                'publishedMetrics': _metricsJson(),
              },
            ],
            'defaults': _paramsJson(),
            'categoryId': 'nature',
            'sortOrder': -3,
          },
        },
      });
      expect(decodeBorderBlueprintRecordJson(encoded), record);
    });

    test('V4 round-trips every draft and published orientation spelling', () {
      const cases = <BorderPrimitiveOrientation, String>{
        BorderPrimitiveOrientation.legacyAxis: 'legacyAxis',
        BorderPrimitiveOrientation.east: 'east',
        BorderPrimitiveOrientation.south: 'south',
        BorderPrimitiveOrientation.west: 'west',
        BorderPrimitiveOrientation.north: 'north',
      };

      for (final entry in cases.entries) {
        final record = _record(
          draftOrientation: entry.key,
          publishedOrientation: entry.key,
          withGround: false,
        );
        final encoded = encodeBorderBlueprintRecordJson(
          record,
          formatVersion: ProjectBorderCatalog.formatVersionV4,
        );
        final draftPrimitive =
            _primitiveJsonList(encoded, published: false).single;
        final publishedPrimitive =
            _primitiveJsonList(encoded, published: true).single;

        if (entry.key == BorderPrimitiveOrientation.legacyAxis) {
          expect(draftPrimitive, isNot(contains('authoredOrientation')));
          expect(publishedPrimitive, isNot(contains('authoredOrientation')));

          final explicitLegacy = _copy(encoded);
          _primitiveJsonList(explicitLegacy, published: false)
              .single['authoredOrientation'] = entry.value;
          _primitiveJsonList(explicitLegacy, published: true)
              .single['authoredOrientation'] = entry.value;
          expect(
            decodeBorderBlueprintRecordJson(
              explicitLegacy,
              formatVersion: ProjectBorderCatalog.formatVersionV4,
            ),
            record,
          );
        } else {
          expect(draftPrimitive['authoredOrientation'], entry.value);
          expect(publishedPrimitive['authoredOrientation'], entry.value);
        }
        expect(
          decodeBorderBlueprintRecordJson(
            encoded,
            formatVersion: ProjectBorderCatalog.formatVersionV4,
          ),
          record,
        );
      }
    });

    test('V1 through V3 decode absent orientation as legacyAxis', () {
      for (final formatVersion in <int>[1, 2, 3]) {
        final encoded = encodeBorderBlueprintRecordJson(
          _record(withGround: false),
          formatVersion: formatVersion,
        );
        expect(
          _primitiveJsonList(encoded, published: false).single,
          isNot(contains('authoredOrientation')),
        );
        expect(
          _primitiveJsonList(encoded, published: true).single,
          isNot(contains('authoredOrientation')),
        );

        final decoded = decodeBorderBlueprintRecordJson(
          encoded,
          formatVersion: formatVersion,
        );
        expect(
          decoded.draft.definition.primitives.single.authoredOrientation,
          BorderPrimitiveOrientation.legacyAxis,
        );
        expect(
          decoded.latestPublished!.definition.primitives.single
              .authoredOrientation,
          BorderPrimitiveOrientation.legacyAxis,
        );
      }
    });

    test('V1 through V3 reject cardinal orientation at its exact path', () {
      for (final formatVersion in <int>[1, 2, 3]) {
        expect(
          () => encodeBorderBlueprintRecordJson(
            _record(
              draftOrientation: BorderPrimitiveOrientation.west,
              withGround: false,
            ),
            formatVersion: formatVersion,
          ),
          _formatAt(
            r'$.draft.definition.primitives[0].authoredOrientation',
          ),
          reason: 'draft V$formatVersion',
        );
        expect(
          () => encodeBorderBlueprintRecordJson(
            _record(
              publishedOrientation: BorderPrimitiveOrientation.north,
              withGround: false,
            ),
            formatVersion: formatVersion,
          ),
          _formatAt(
            r'$.latestPublished.definition.primitives[0]'
            r'.authoredOrientation',
          ),
          reason: 'published V$formatVersion',
        );
      }
    });

    test('orientation key strictness follows the selected format version', () {
      for (final formatVersion in <int>[1, 2, 3]) {
        final encoded = encodeBorderBlueprintRecordJson(
          _record(withGround: false),
          formatVersion: formatVersion,
        );
        _primitiveJsonList(encoded, published: false)
            .single['authoredOrientation'] = 'west';

        expect(
          () => decodeBorderBlueprintRecordJson(
            encoded,
            formatVersion: formatVersion,
          ),
          _formatAt(
            r'$.draft.definition.primitives[0].authoredOrientation',
          ),
          reason: 'future key in V$formatVersion',
        );

        final published = encodeBorderBlueprintRecordJson(
          _record(withGround: false),
          formatVersion: formatVersion,
        );
        _primitiveJsonList(published, published: true)
            .single['authoredOrientation'] = 'north';
        expect(
          () => decodeBorderBlueprintRecordJson(
            published,
            formatVersion: formatVersion,
          ),
          _formatAt(
            r'$.latestPublished.definition.primitives[0]'
            r'.authoredOrientation',
          ),
          reason: 'future published key in V$formatVersion',
        );
      }

      final v4 = encodeBorderBlueprintRecordJson(
        _record(withGround: false),
        formatVersion: ProjectBorderCatalog.formatVersionV4,
      );
      _primitiveJsonList(v4, published: true).single['futureOrientation'] =
          'west';
      expect(
        () => decodeBorderBlueprintRecordJson(
          v4,
          formatVersion: ProjectBorderCatalog.formatVersionV4,
        ),
        _formatAt(
          r'$.latestPublished.definition.primitives[0].futureOrientation',
        ),
      );
    });

    test('V4 rejects unknown orientation spellings at the primitive path', () {
      final draft = encodeBorderBlueprintRecordJson(
        _record(withGround: false),
        formatVersion: ProjectBorderCatalog.formatVersionV4,
      );
      _primitiveJsonList(draft, published: false)
          .single['authoredOrientation'] = 'northWest';
      expect(
        () => decodeBorderBlueprintRecordJson(
          draft,
          formatVersion: ProjectBorderCatalog.formatVersionV4,
        ),
        _formatAt(r'$.draft.definition.primitives[0].authoredOrientation'),
      );

      final published = encodeBorderBlueprintRecordJson(
        _record(withGround: false),
        formatVersion: ProjectBorderCatalog.formatVersionV4,
      );
      _primitiveJsonList(published, published: true)
          .single['authoredOrientation'] = 'northWest';
      expect(
        () => decodeBorderBlueprintRecordJson(
          published,
          formatVersion: ProjectBorderCatalog.formatVersionV4,
        ),
        _formatAt(
          r'$.latestPublished.definition.primitives[0]'
          r'.authoredOrientation',
        ),
      );
    });

    test('rejects nonblank but non-trimmed record IDs at the id path', () {
      for (final id in <String>[' ', ' coast', 'coast ']) {
        final encoded = encodeBorderBlueprintRecordJson(
          _record(includePublished: false),
        )..['id'] = id;

        expect(
          () => decodeBorderBlueprintRecordJson(encoded),
          _formatAt(r'$.id'),
          reason: '"$id"',
        );
      }
    });

    test('defaults deprecation to false and encodes only true canonically', () {
      final active = _record(includePublished: false);
      final activeJson = encodeBorderBlueprintRecordJson(active);

      expect(active.isDeprecated, isFalse);
      expect(activeJson.containsKey('isDeprecated'), isFalse);
      expect(decodeBorderBlueprintRecordJson(activeJson).isDeprecated, isFalse);

      final explicitFalse = _copy(activeJson)..['isDeprecated'] = false;
      final decodedFalse = decodeBorderBlueprintRecordJson(explicitFalse);
      expect(decodedFalse.isDeprecated, isFalse);
      expect(
        encodeBorderBlueprintRecordJson(decodedFalse).containsKey(
          'isDeprecated',
        ),
        isFalse,
      );

      final deprecated = _record(
        includePublished: false,
        isDeprecated: true,
      );
      final deprecatedJson = encodeBorderBlueprintRecordJson(deprecated);
      expect(deprecatedJson['isDeprecated'], isTrue);
      expect(
        decodeBorderBlueprintRecordJson(deprecatedJson),
        deprecated,
      );
    });

    test('rejects null and non-boolean deprecation at its exact path', () {
      for (final invalid in <Object?>[null, 0, 'true']) {
        final json = encodeBorderBlueprintRecordJson(
          _record(includePublished: false),
        )..['isDeprecated'] = invalid;

        expect(
          () => decodeBorderBlueprintRecordJson(json),
          _formatAt(r'$.isDeprecated'),
          reason: '$invalid',
        );
      }
    });

    test('round-trips all three V1 templates through explicit wire names', () {
      const cases = <BorderBlueprintTemplate, String>{
        BorderBlueprintTemplate.organicEdge: 'organicEdge',
        BorderBlueprintTemplate.masonryLine: 'masonryLine',
        BorderBlueprintTemplate.postAndRailLine: 'postAndRailLine',
      };

      for (final entry in cases.entries) {
        final record = _record(template: entry.key, includePublished: false);
        final encoded = encodeBorderBlueprintRecordJson(record);
        final definition = (encoded['draft']!
            as Map<String, Object?>)['definition']! as Map<String, Object?>;
        expect(definition['template'], entry.value);
        expect(decodeBorderBlueprintRecordJson(encoded), record);
      }
    });

    test('round-trips connectedLine roles only through Border catalog V2', () {
      const roles = <BorderPrimitiveRole>[
        BorderPrimitiveRole.lineCap,
        BorderPrimitiveRole.lineStraight,
        BorderPrimitiveRole.lineCorner,
      ];
      final record = _record(
        template: BorderBlueprintTemplate.connectedLine,
        draftRoles: roles,
        publishedRoles: roles,
        withGround: false,
      );

      expect(
        () => encodeBorderBlueprintRecordJson(record),
        _formatAt(r'$.draft.definition.template'),
      );

      final encoded = encodeBorderBlueprintRecordJson(
        record,
        formatVersion: 2,
      );
      expect(_draftDefinitionJson(encoded)['template'], 'connectedLine');
      expect(
        _primitiveJsonList(encoded, published: false)
            .map((value) => value['role']),
        <String>['lineCap', 'lineStraight', 'lineCorner'],
      );
      expect(
        decodeBorderBlueprintRecordJson(encoded, formatVersion: 2),
        record,
      );
      expect(
        () => decodeBorderBlueprintRecordJson(encoded),
        _formatAt(r'$.draft.definition.template'),
      );
    });

    test('round-trips all eight primitive roles without reordering', () {
      const roles = <BorderPrimitiveRole>[
        BorderPrimitiveRole.structureLarge,
        BorderPrimitiveRole.structureMedium,
        BorderPrimitiveRole.filler,
        BorderPrimitiveRole.accent,
        BorderPrimitiveRole.post,
        BorderPrimitiveRole.span,
        BorderPrimitiveRole.surfacePatch,
        BorderPrimitiveRole.outerAccent,
      ];
      const names = <String>[
        'structureLarge',
        'structureMedium',
        'filler',
        'accent',
        'post',
        'span',
        'surfacePatch',
        'outerAccent',
      ];
      final record = _record(
        draftRoles: roles,
        publishedRoles: roles,
        withGround: false,
      );

      final encoded = encodeBorderBlueprintRecordJson(record);
      final draftRoles = _primitiveJsonList(encoded, published: false)
          .map((value) => value['role'])
          .toList();
      final publishedRoles = _primitiveJsonList(encoded, published: true)
          .map((value) => value['role'])
          .toList();

      expect(draftRoles, names);
      expect(publishedRoles, names);
      expect(decodeBorderBlueprintRecordJson(encoded), record);
    });

    test('encodes all 20 Surface roles in explicit stable order', () {
      const names = <String>[
        'isolated',
        'endNorth',
        'endEast',
        'endSouth',
        'endWest',
        'horizontal',
        'vertical',
        'cornerNE',
        'cornerSE',
        'cornerSW',
        'cornerNW',
        'innerCornerNE',
        'innerCornerSE',
        'innerCornerSW',
        'innerCornerNW',
        'teeNorth',
        'teeEast',
        'teeSouth',
        'teeWest',
        'cross',
      ];
      final record = _record();

      final encoded = encodeBorderBlueprintRecordJson(record);
      final publishedDefinition = (((encoded['latestPublished']!
          as Map<String, Object?>)['definition']!) as Map<String, Object?>);
      final ground = publishedDefinition['ground']! as Map<String, Object?>;
      final snapshots =
          ground['visualSnapshotIdsByRole']! as Map<String, Object?>;

      expect(snapshots.keys, names);
      expect(snapshots.length, 20);
      expect(decodeBorderBlueprintRecordJson(encoded), record);
    });

    test('supports draft-only records and canonical nullable optionals', () {
      final record = _record(
        includePublished: false,
        withGround: false,
        categoryId: null,
      );
      final encoded = encodeBorderBlueprintRecordJson(record);
      final definition = ((encoded['draft']!
          as Map<String, Object?>)['definition']!) as Map<String, Object?>;

      expect(encoded.containsKey('latestPublished'), isFalse);
      expect(definition.containsKey('ground'), isFalse);
      expect(definition.containsKey('categoryId'), isFalse);

      final withNulls = _copy(encoded);
      withNulls['latestPublished'] = null;
      final nullableDefinition = (((withNulls['draft']!
          as Map<String, Object?>)['definition']!) as Map<String, Object?>)
        ..['ground'] = null
        ..['categoryId'] = null;
      expect(nullableDefinition['ground'], isNull);

      final decoded = decodeBorderBlueprintRecordJson(withNulls);
      expect(decoded, record);
      expect(
        encodeBorderBlueprintRecordJson(decoded).containsKey(
          'latestPublished',
        ),
        isFalse,
      );
    });

    test('accepts draft weight zero but rejects published weight zero', () {
      final json = encodeBorderBlueprintRecordJson(_record());
      expect(
        _primitiveJsonList(json, published: false).first['weight'],
        0,
      );

      _primitiveJsonList(json, published: true).first['weight'] = 0;
      expect(
        () => decodeBorderBlueprintRecordJson(json),
        _formatAt(
          r'$.latestPublished.definition.primitives[0].weight',
        ),
      );
    });

    test('uses canonical signed-int64 strings for preview seeds', () {
      for (final seed in <BorderSignedInt64>[
        BorderSignedInt64.minimum,
        BorderSignedInt64.fromInt(-1),
        BorderSignedInt64.zero,
        BorderSignedInt64.fromInt(1),
        BorderSignedInt64.maximum,
      ]) {
        final record = _record(
          includePublished: false,
          previewSeed: seed,
        );
        final encoded = encodeBorderBlueprintRecordJson(record);
        final definition = ((encoded['draft']!
            as Map<String, Object?>)['definition']!) as Map<String, Object?>;
        expect(definition['previewSeed'], seed.toString());
        expect(decodeBorderBlueprintRecordJson(encoded), record);
      }

      for (final encodedSeed in <Object?>[
        1,
        1.0,
        '+1',
        '01',
        '-0',
        ' 1',
        '9223372036854775808',
        '-9223372036854775809',
      ]) {
        final json = encodeBorderBlueprintRecordJson(
          _record(includePublished: false),
        );
        _draftDefinitionJson(json)['previewSeed'] = encodedSeed;
        expect(
          () => decodeBorderBlueprintRecordJson(json),
          _formatAt(r'$.draft.definition.previewSeed'),
          reason: '$encodedSeed',
        );
      }
    });

    test('accepts normalized transforms and rejects non-normalized input', () {
      final json = encodeBorderBlueprintRecordJson(
        _record(includePublished: false),
      );
      final transforms = _primitiveJsonList(json, published: false)
          .first['transforms']! as Map<String, Object?>;
      expect(transforms, <String, Object?>{
        'allowFlipX': true,
        'allowedQuarterTurns': <int>[0, 2, 3],
      });

      for (final turns in <List<Object?>>[
        <Object?>[2, 0],
        <Object?>[0, 0],
        <Object?>[-1],
        <Object?>[4],
        <Object?>[0, 1.0],
      ]) {
        final invalid = encodeBorderBlueprintRecordJson(
          _record(includePublished: false),
        );
        (_primitiveJsonList(invalid, published: false).first['transforms']!
            as Map<String, Object?>)['allowedQuarterTurns'] = turns;
        expect(
          () => decodeBorderBlueprintRecordJson(invalid),
          _formatUnder(
            r'$.draft.definition.primitives[0].transforms.allowedQuarterTurns',
          ),
          reason: '$turns',
        );
      }
    });

    test('rejects unknown templates, roles, and deep fields at their paths',
        () {
      final template = encodeBorderBlueprintRecordJson(_record());
      _draftDefinitionJson(template)['template'] = 'organicLine';
      expect(
        () => decodeBorderBlueprintRecordJson(template),
        _formatAt(r'$.draft.definition.template'),
      );

      final role = encodeBorderBlueprintRecordJson(_record());
      _primitiveJsonList(role, published: false).first['role'] = 'cornerNE';
      expect(
        () => decodeBorderBlueprintRecordJson(role),
        _formatAt(r'$.draft.definition.primitives[0].role'),
      );

      final deepUnknown = encodeBorderBlueprintRecordJson(_record());
      final metrics = _primitiveJsonList(deepUnknown, published: true)
          .first['publishedMetrics']! as Map<String, Object?>;
      (metrics['pixelSize']! as Map<String, Object?>)['columns'] = 3;
      expect(
        () => decodeBorderBlueprintRecordJson(deepUnknown),
        _formatAt(
          r'$.latestPublished.definition.primitives[0].publishedMetrics.pixelSize.columns',
        ),
      );

      final missing = encodeBorderBlueprintRecordJson(_record());
      _draftDefinitionJson(missing).remove('defaults');
      expect(
        () => decodeBorderBlueprintRecordJson(missing),
        _formatAt(r'$.draft.definition.defaults'),
      );
    });

    test('keeps draft and published primitive shapes strictly separate', () {
      final wrongDraft = encodeBorderBlueprintRecordJson(_record());
      final draftPrimitive =
          _primitiveJsonList(wrongDraft, published: false).first;
      draftPrimitive['publishedMetrics'] = draftPrimitive.remove(
        'currentMetrics',
      );
      expect(
        () => decodeBorderBlueprintRecordJson(wrongDraft),
        _formatAt(
          r'$.draft.definition.primitives[0].publishedMetrics',
        ),
      );

      final wrongPublished = encodeBorderBlueprintRecordJson(_record());
      final publishedPrimitive =
          _primitiveJsonList(wrongPublished, published: true).first;
      publishedPrimitive['currentMetrics'] = publishedPrimitive.remove(
        'publishedMetrics',
      );
      expect(
        () => decodeBorderBlueprintRecordJson(wrongPublished),
        _formatAt(
          r'$.latestPublished.definition.primitives[0].currentMetrics',
        ),
      );
    });

    test('requires the published ground role map to be exact and nonempty', () {
      final missing = encodeBorderBlueprintRecordJson(_record());
      _publishedGroundSnapshots(missing).remove('cross');
      expect(
        () => decodeBorderBlueprintRecordJson(missing),
        _formatAt(
          r'$.latestPublished.definition.ground.visualSnapshotIdsByRole.cross',
        ),
      );

      final extra = encodeBorderBlueprintRecordJson(_record());
      _publishedGroundSnapshots(extra)['north'] = 'snapshot-extra';
      expect(
        () => decodeBorderBlueprintRecordJson(extra),
        _formatAt(
          r'$.latestPublished.definition.ground.visualSnapshotIdsByRole.north',
        ),
      );

      final empty = encodeBorderBlueprintRecordJson(_record());
      _publishedGroundSnapshots(empty)['isolated'] = '';
      expect(
        () => decodeBorderBlueprintRecordJson(empty),
        _formatAt(
          r'$.latestPublished.definition.ground.visualSnapshotIdsByRole.isolated',
        ),
      );
    });

    test('delegates strict RLE validation on decode and encode', () {
      final malformed = encodeBorderBlueprintRecordJson(_record());
      final metrics = _primitiveJsonList(malformed, published: false)
          .first['currentMetrics']! as Map<String, Object?>;
      metrics['occupancyMaskRle'] = 'border-rle-v1:5:1:5';
      expect(
        () => decodeBorderBlueprintRecordJson(malformed),
        _formatAt(
          r'$.draft.definition.primitives[0].currentMetrics.occupancyMaskRle',
        ),
      );

      final invalidMetrics = _metrics(rle: 'border-rle-v1:5:1:5');
      final invalidRecord = _record(
        includePublished: false,
        draftMetrics: invalidMetrics,
      );
      expect(
        () => encodeBorderBlueprintRecordJson(invalidRecord),
        _formatAt(
          r'$.draft.definition.primitives[0].currentMetrics.occupancyMaskRle',
        ),
      );
    });

    test('uses custom paths, preserves order, and never mutates input', () {
      final record = _record(
        draftRoles: const <BorderPrimitiveRole>[
          BorderPrimitiveRole.outerAccent,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.structureLarge,
        ],
        includePublished: false,
      );
      final input = encodeBorderBlueprintRecordJson(record);
      final before = _copy(input);

      expect(
        decodeBorderBlueprintRecordJson(
          input,
          path: r'$.borderCatalog.records[4]',
        ),
        record,
      );
      expect(input, before);
      expect(
        _primitiveJsonList(input, published: false).map((value) => value['id']),
        <String>['draft-0', 'draft-1', 'draft-2'],
      );

      _draftDefinitionJson(input)['template'] = 'bad';
      expect(
        () => decodeBorderBlueprintRecordJson(
          input,
          path: r'$.borderCatalog.records[4]',
        ),
        _formatAt(r'$.borderCatalog.records[4].draft.definition.template'),
      );
    });

    test('contains no collision wire fields', () {
      final jsonText = jsonEncode(encodeBorderBlueprintRecordJson(_record()));

      expect(jsonText, isNot(contains('collision')));
      expect(jsonText, isNot(contains('footprint')));
    });
  });
}

BorderBlueprintRecord _record({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  BorderPrimitiveOrientation draftOrientation =
      BorderPrimitiveOrientation.legacyAxis,
  BorderPrimitiveOrientation publishedOrientation =
      BorderPrimitiveOrientation.legacyAxis,
  List<BorderPrimitiveRole> draftRoles = const <BorderPrimitiveRole>[
    BorderPrimitiveRole.structureLarge,
  ],
  List<BorderPrimitiveRole> publishedRoles = const <BorderPrimitiveRole>[
    BorderPrimitiveRole.structureLarge,
  ],
  bool includePublished = true,
  bool withGround = true,
  String? categoryId = 'nature',
  Object previewSeed = -7,
  BorderPrimitiveAssetMetrics? draftMetrics,
  bool isDeprecated = false,
}) {
  final metrics = draftMetrics ?? _metrics();
  return BorderBlueprintRecord(
    id: 'coast',
    isDeprecated: isDeprecated,
    draft: BorderBlueprintDraft(
      baseRevision: 1,
      definition: BorderBlueprintDraftDefinition(
        name: 'Coast',
        previewSeed: _signedInt64(previewSeed),
        template: template,
        primitives: <BorderPrimitiveDraft>[
          for (var index = 0; index < draftRoles.length; index += 1)
            BorderPrimitiveDraft(
              id: 'draft-$index',
              sourceElementId: 'element-$index',
              role: draftRoles[index],
              authoredOrientation: draftOrientation,
              weight: index,
              anchorPx: const BorderPixelPos(x: -2, y: 5),
              transforms: _transforms(),
              currentMetrics: metrics,
            ),
        ],
        defaults: _params(),
        ground: withGround
            ? BorderGroundDraft(
                sourceSurfacePresetId: 'water',
                edgeBandCells: 2,
              )
            : null,
        categoryId: categoryId,
        sortOrder: -4,
      ),
    ),
    latestPublished: includePublished
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Coast published',
              previewSeed: BorderSignedInt64.fromInt(8),
              template: template,
              primitives: <BorderPublishedPrimitive>[
                for (var index = 0; index < publishedRoles.length; index += 1)
                  BorderPublishedPrimitive(
                    id: 'published-$index',
                    sourceElementId: 'element-$index',
                    visualSnapshotId: 'snapshot-$index',
                    role: publishedRoles[index],
                    authoredOrientation: publishedOrientation,
                    weight: index + 1,
                    anchorPx: const BorderPixelPos(x: -2, y: 5),
                    transforms: _transforms(),
                    publishedMetrics: _metrics(),
                  ),
              ],
              defaults: _params(),
              ground: withGround
                  ? BorderPublishedGround(
                      sourceSurfacePresetId: 'water',
                      edgeBandCells: 2,
                      visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
                        for (final role in standardSurfaceVariantRoleOrder)
                          role: 'snapshot-${role.index}',
                      },
                    )
                  : null,
              categoryId: categoryId,
              sortOrder: -3,
            ),
          )
        : null,
  );
}

BorderSignedInt64 _signedInt64(Object value) => switch (value) {
      BorderSignedInt64() => value,
      int() => BorderSignedInt64.fromInt(value),
      _ => throw ArgumentError.value(value, 'value'),
    };

BorderTransformPolicy _transforms() => BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: <int>[0, 2, 3],
    );

BorderGenerationParams _params({bool allowAutoRotation = true}) =>
    BorderGenerationParams(
      irregularityPermille: 101,
      detailDensityPermille: 202,
      variationPermille: 303,
      maxOverlapPx: 4,
      gapTolerancePx: 5,
      depthRows: 2,
      allowAutoRotation: allowAutoRotation,
    );

Map<String, Object?> _paramsJson() => <String, Object?>{
      'irregularityPermille': 101,
      'detailDensityPermille': 202,
      'variationPermille': 303,
      'maxOverlapPx': 4,
      'gapTolerancePx': 5,
      'depthRows': 2,
    };

BorderPrimitiveAssetMetrics _metrics({
  String rle = 'border-rle-v1:6:1:2,2,2',
}) =>
    BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-fingerprint',
      pixelSize: const GridSize(width: 3, height: 2),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 3, height: 2),
      defaultAnchorPx: const BorderPixelPos(x: -2, y: 5),
      occupancyMaskRle: rle,
    );

Map<String, Object?> _metricsJson() => <String, Object?>{
      'assetFingerprint': 'asset-fingerprint',
      'pixelSize': <String, Object?>{'width': 3, 'height': 2},
      'opaqueBounds': <String, Object?>{
        'x': 0,
        'y': 0,
        'width': 3,
        'height': 2,
      },
      'defaultAnchorPx': <String, Object?>{'x': -2, 'y': 5},
      'occupancyMaskRle': 'border-rle-v1:6:1:2,2,2',
    };

Map<String, Object?> _draftDefinitionJson(Map<String, Object?> record) =>
    ((record['draft']! as Map<String, Object?>)['definition']!)
        as Map<String, Object?>;

List<Map<String, Object?>> _primitiveJsonList(
  Map<String, Object?> record, {
  required bool published,
}) {
  final owner = published
      ? record['latestPublished']! as Map<String, Object?>
      : record['draft']! as Map<String, Object?>;
  final definition = owner['definition']! as Map<String, Object?>;
  return (definition['primitives']! as List<Object?>)
      .cast<Map<String, Object?>>();
}

Map<String, Object?> _publishedGroundSnapshots(Map<String, Object?> record) {
  final published = record['latestPublished']! as Map<String, Object?>;
  final definition = published['definition']! as Map<String, Object?>;
  final ground = definition['ground']! as Map<String, Object?>;
  return ground['visualSnapshotIdsByRole']! as Map<String, Object?>;
}

Map<String, Object?> _copy(Map<String, Object?> input) =>
    (jsonDecode(jsonEncode(input))! as Map<String, Object?>);

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

Matcher _formatUnder(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith(path),
      ),
    );
