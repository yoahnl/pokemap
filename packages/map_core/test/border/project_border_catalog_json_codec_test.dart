import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _snapshotFingerprintA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _snapshotFingerprintB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('ProjectBorderCatalog JSON codec', () {
    test('encodes the exact canonical empty catalog', () {
      expect(
        encodeProjectBorderCatalogJson(const ProjectBorderCatalog.empty()),
        <String, Object?>{
          'formatVersion': 1,
          'records': <Object?>[],
          'visualSnapshots': <Object?>[],
        },
      );
    });

    test('round-trips records and animated snapshots in authored order', () {
      final firstSnapshot = _snapshot(
        fingerprint: _snapshotFingerprintA,
        frames: <BorderVisualFrameSnapshot>[
          _frame('a-first.png', durationMs: 80),
          _frame('a-second.png', durationMs: 120, transparentColorArgb: 0),
        ],
      );
      final secondSnapshot = _snapshot(
        fingerprint: _snapshotFingerprintB,
        frames: <BorderVisualFrameSnapshot>[
          _frame('b-only.png', durationMs: 90),
        ],
      );
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record(id: 'second', publishedSnapshotId: firstSnapshot.id),
          _record(id: 'first', publishedSnapshotId: secondSnapshot.id),
        ],
        visualSnapshots: <BorderVisualSnapshot>[
          secondSnapshot,
          firstSnapshot,
        ],
      );

      final encoded = encodeProjectBorderCatalogJson(catalog);

      expect(encoded.keys,
          <String>['formatVersion', 'records', 'visualSnapshots']);
      expect(
        (encoded['records']! as List<Object?>)
            .map((value) => (value! as Map<String, Object?>)['id']),
        <String>['second', 'first'],
      );
      expect(
        (encoded['visualSnapshots']! as List<Object?>)
            .map((value) => (value! as Map<String, Object?>)['id']),
        <String>[secondSnapshot.id, firstSnapshot.id],
      );
      final encodedFrames = (((encoded['visualSnapshots']! as List<Object?>)[1]!
          as Map<String, Object?>)['frames']!) as List<Object?>;
      expect(
        encodedFrames.map(
          (value) => (value! as Map<String, Object?>)['relativeAssetPath'],
        ),
        <String>[
          'assets/borders/snapshots/a-first.png',
          'assets/borders/snapshots/a-second.png',
        ],
      );
      expect(decodeProjectBorderCatalogJson(encoded), catalog);
    });

    test('rejects non-object roots and non-string object keys', () {
      for (final invalid in <Object?>[null, true, 1, 'catalog', <Object?>[]]) {
        expect(
          () => decodeProjectBorderCatalogJson(invalid),
          _formatAt(r'$'),
          reason: '$invalid',
        );
      }

      expect(
        () => decodeProjectBorderCatalogJson(<Object?, Object?>{
          'formatVersion': 1,
          'records': <Object?>[],
          'visualSnapshots': <Object?>[],
          7: 'not a JSON object key',
        }),
        _formatAt(r'$'),
      );
    });

    test('requires exactly all three root keys', () {
      final unknown = _emptyJson()..['future'] = true;
      expect(
        () => decodeProjectBorderCatalogJson(unknown),
        _formatAt(r'$.future'),
      );

      for (final key in <String>[
        'formatVersion',
        'records',
        'visualSnapshots',
      ]) {
        final missing = _emptyJson()..remove(key);
        expect(
          () => decodeProjectBorderCatalogJson(missing),
          _formatAt('\$.$key'),
          reason: key,
        );
      }
    });

    test('accepts V1/V2 and rejects unsupported strict integer versions', () {
      for (final invalidVersion in <Object?>[
        null,
        true,
        1.0,
        '1',
        0,
        3,
      ]) {
        final invalid = _emptyJson()..['formatVersion'] = invalidVersion;
        expect(
          () => decodeProjectBorderCatalogJson(invalid),
          _formatAt(r'$.formatVersion'),
          reason: '$invalidVersion',
        );
      }

      for (final field in <String>['records', 'visualSnapshots']) {
        for (final invalidList in <Object?>[null, true, <String, Object?>{}]) {
          final invalid = _emptyJson()..[field] = invalidList;
          expect(
            () => decodeProjectBorderCatalogJson(invalid),
            _formatAt('\$.$field'),
            reason: '$field: $invalidList',
          );
        }
      }
    });

    test('V2 round-trips connectedLine while V1 rejects its enum values', () {
      final record = _record(
        template: BorderBlueprintTemplate.connectedLine,
        role: BorderPrimitiveRole.lineCap,
      );
      final catalog = ProjectBorderCatalog(
        formatVersion: 2,
        records: <BorderBlueprintRecord>[record],
      );

      final encoded = encodeProjectBorderCatalogJson(catalog);
      expect(encoded['formatVersion'], 2);
      final definition = ((((encoded['records']! as List<Object?>).single!
              as Map<String, Object?>)['draft']!
          as Map<String, Object?>)['definition']! as Map<String, Object?>);
      expect(definition['template'], 'connectedLine');
      expect(decodeProjectBorderCatalogJson(encoded), catalog);

      final mislabeledV1 = _deepCopy(encoded)..['formatVersion'] = 1;
      expect(
        () => decodeProjectBorderCatalogJson(mislabeledV1),
        _formatAt(r'$.records[0].draft.definition.template'),
      );
    });

    test('reports duplicate record and snapshot ids at the second id path', () {
      final record = encodeBorderBlueprintRecordJson(_record(id: 'same'));
      final duplicateRecords = _emptyJson()
        ..['records'] = <Object?>[_deepCopy(record), _deepCopy(record)];
      expect(
        () => decodeProjectBorderCatalogJson(duplicateRecords),
        _formatAt(r'$.records[1].id'),
      );

      final snapshot = encodeBorderVisualSnapshotJson(
        _snapshot(fingerprint: _snapshotFingerprintA),
      );
      final duplicateSnapshots = _emptyJson()
        ..['visualSnapshots'] = <Object?>[
          _deepCopy(snapshot),
          _deepCopy(snapshot),
        ];
      expect(
        () => decodeProjectBorderCatalogJson(duplicateSnapshots),
        _formatAt(r'$.visualSnapshots[1].id'),
      );
    });

    test('keeps record and snapshot id namespaces independent', () {
      final snapshot = _snapshot(fingerprint: _snapshotFingerprintA);
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record(id: snapshot.id),
        ],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );

      expect(
        decodeProjectBorderCatalogJson(encodeProjectBorderCatalogJson(catalog)),
        catalog,
      );
    });

    test('propagates indexed record and snapshot child paths', () {
      final invalidRecord = encodeBorderBlueprintRecordJson(_record());
      final draft = invalidRecord['draft']! as Map<String, Object?>;
      draft['unknown'] = true;
      expect(
        () => decodeProjectBorderCatalogJson(
          _emptyJson()..['records'] = <Object?>[invalidRecord],
        ),
        _formatAt(r'$.records[0].draft.unknown'),
      );

      final invalidSnapshot = encodeBorderVisualSnapshotJson(
        _snapshot(fingerprint: _snapshotFingerprintA),
      );
      final frames = invalidSnapshot['frames']! as List<Object?>;
      (frames.single! as Map<String, Object?>)['relativeAssetPath'] =
          '../outside.png';
      expect(
        () => decodeProjectBorderCatalogJson(
          _emptyJson()..['visualSnapshots'] = <Object?>[invalidSnapshot],
        ),
        _formatAt(r'$.visualSnapshots[0].frames[0].relativeAssetPath'),
      );
    });

    test('validates nested metrics and RLE at the complete encode path', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record(occupancyMaskRle: 'not-rle'),
        ],
      );

      expect(
        () => encodeProjectBorderCatalogJson(catalog),
        _formatAt(
          r'$.records[0].draft.definition.primitives[0]'
          r'.currentMetrics.occupancyMaskRle',
        ),
      );
    });

    test('accepts dangling published snapshot references without resolving',
        () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          _record(publishedSnapshotId: 'snapshot-not-in-this-catalog'),
        ],
      );

      expect(
        decodeProjectBorderCatalogJson(encodeProjectBorderCatalogJson(catalog)),
        catalog,
      );
    });

    test('honors custom paths and never mutates deeply nested input', () {
      final input = encodeProjectBorderCatalogJson(
        ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[_record()],
          visualSnapshots: <BorderVisualSnapshot>[
            _snapshot(fingerprint: _snapshotFingerprintA),
          ],
        ),
      );
      final before = _deepCopy(input);
      const path = r'$.project.borderCatalog';

      decodeProjectBorderCatalogJson(input, path: path);

      expect(input, before);
      final duplicate = _deepCopy(input);
      final records = duplicate['records']! as List<Object?>;
      records.add(
        _deepCopy(records.single! as Map<String, Object?>),
      );
      expect(
        () => decodeProjectBorderCatalogJson(duplicate, path: path),
        _formatAt(r'$.project.borderCatalog.records[1].id'),
      );
    });

    test('canonical re-encode normalizes child optional fields', () {
      final snapshot = encodeBorderVisualSnapshotJson(
        _snapshot(fingerprint: _snapshotFingerprintA),
      );
      final frame = (snapshot['frames']! as List<Object?>).single!
          as Map<String, Object?>;
      frame.remove('durationMs');
      final record = encodeBorderBlueprintRecordJson(_record());
      record['latestPublished'] = null;
      final input = <String, Object?>{
        'formatVersion': 1,
        'records': <Object?>[record],
        'visualSnapshots': <Object?>[snapshot],
      };

      final canonical = encodeProjectBorderCatalogJson(
        decodeProjectBorderCatalogJson(input),
      );

      final canonicalRecord = (canonical['records']! as List<Object?>).single!
          as Map<String, Object?>;
      final canonicalSnapshot = (canonical['visualSnapshots']! as List<Object?>)
          .single! as Map<String, Object?>;
      final canonicalFrame = (canonicalSnapshot['frames']! as List<Object?>)
          .single! as Map<String, Object?>;
      expect(canonicalRecord.containsKey('latestPublished'), isFalse);
      expect(canonicalFrame['durationMs'], 100);
    });
  });
}

Map<String, Object?> _emptyJson() => <String, Object?>{
      'formatVersion': 1,
      'records': <Object?>[],
      'visualSnapshots': <Object?>[],
    };

BorderBlueprintRecord _record({
  String id = 'coast',
  String? publishedSnapshotId,
  String occupancyMaskRle = 'border-rle-v1:4:1:4',
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
}) {
  final metrics = BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-sha256:fixture',
    pixelSize: const GridSize(width: 2, height: 2),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
    defaultAnchorPx: const BorderPixelPos(x: 1, y: 2),
    occupancyMaskRle: occupancyMaskRle,
  );
  final params = BorderGenerationParams(
    irregularityPermille: 100,
    detailDensityPermille: 200,
    variationPermille: 300,
    maxOverlapPx: 1,
    gapTolerancePx: 2,
    depthRows: 1,
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: true,
    allowedQuarterTurns: const <int>[0, 1],
  );
  final draft = BorderBlueprintDraft(
    baseRevision: publishedSnapshotId == null ? 0 : 1,
    definition: BorderBlueprintDraftDefinition(
      name: 'Coast $id',
      previewSeed: BorderSignedInt64.fromInt(-7),
      template: template,
      primitives: <BorderPrimitiveDraft>[
        BorderPrimitiveDraft(
          id: 'draft-stone',
          sourceElementId: 'stone-element',
          role: role,
          weight: 100,
          anchorPx: const BorderPixelPos(x: 1, y: 2),
          transforms: transforms,
          currentMetrics: metrics,
        ),
      ],
      defaults: params,
      sortOrder: 4,
    ),
  );
  return BorderBlueprintRecord(
    id: id,
    draft: draft,
    latestPublished: publishedSnapshotId == null
        ? null
        : BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Published coast $id',
              previewSeed: BorderSignedInt64.fromInt(9),
              template: template,
              primitives: <BorderPublishedPrimitive>[
                BorderPublishedPrimitive(
                  id: 'published-stone',
                  sourceElementId: 'stone-element',
                  visualSnapshotId: publishedSnapshotId,
                  role: role,
                  weight: 100,
                  anchorPx: const BorderPixelPos(x: 1, y: 2),
                  transforms: transforms,
                  publishedMetrics: metrics,
                ),
              ],
              defaults: params,
              sortOrder: 4,
            ),
          ),
  );
}

BorderVisualSnapshot _snapshot({
  required String fingerprint,
  List<BorderVisualFrameSnapshot>? frames,
}) =>
    BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: frames ?? <BorderVisualFrameSnapshot>[_frame('only.png')],
    );

BorderVisualFrameSnapshot _frame(
  String name, {
  int durationMs = 100,
  int? transparentColorArgb,
}) =>
    BorderVisualFrameSnapshot(
      relativeAssetPath: 'assets/borders/snapshots/$name',
      sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 12),
      durationMs: durationMs,
      transparentColorArgb: transparentColorArgb,
    );

Map<String, Object?> _deepCopy(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value))! as Map<String, Object?>;

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message.toString(),
        'message',
        contains(path),
      ),
    );
