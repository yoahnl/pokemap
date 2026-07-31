import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('project JSON migrations', () {
    test('rejects a shop entry with a negative authored price', () {
      final raw = <String, dynamic>{
        'name': 'Project',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'shops': <Object?>[
          <String, Object?>{
            'id': 'selbrume-mart',
            'label': 'Boutique de Selbrume',
            'entries': <Object?>[
              <String, Object?>{'itemId': 'potion', 'price': -1},
            ],
          },
        ],
      };

      expect(
        () => migrateProjectManifestJson(raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate shop and badge ids after normalization', () {
      for (final entry in <MapEntry<String, List<Object?>>>[
        MapEntry<String, List<Object?>>('shops', <Object?>[
          <String, Object?>{'id': 'mart', 'label': 'A'},
          <String, Object?>{'id': ' mart ', 'label': 'B'},
        ]),
        MapEntry<String, List<Object?>>('badges', <Object?>[
          <String, Object?>{'id': 'brume', 'label': 'A'},
          <String, Object?>{'id': ' brume ', 'label': 'B'},
        ]),
      ]) {
        expect(
          () => migrateProjectManifestJson(<String, dynamic>{
            'name': 'Project',
            entry.key: entry.value,
          }),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('project manifest migration is exported and currently preserves input',
        () {
      final raw = <String, dynamic>{
        'id': 'project',
        'name': 'Project',
      };

      final migrated = migrateProjectManifestJson(raw);

      expect(identical(migrated, raw), isTrue);
    });

    test('map data migration is exported and currently preserves input', () {
      final raw = <String, dynamic>{
        'id': 'map',
        'name': 'Map',
      };

      final migrated = migrateMapDataJson(raw);

      expect(identical(migrated, raw), isTrue);
    });

    for (final entry
        in <String, Map<String, dynamic> Function(Map<String, dynamic>)>{
      'project manifest': migrateProjectManifestJson,
      'map data': migrateMapDataJson,
    }.entries) {
      test('${entry.key} accepts absent, null, V1, V2, V3, and V4 by identity',
          () {
        for (final version in <Object?>[
          _absentVersion,
          null,
          'v1',
          'v2',
          'v3',
          'v4',
        ]) {
          final raw = <String, dynamic>{'name': 'identity'};
          if (!identical(version, _absentVersion)) {
            raw['version'] = version;
          }

          expect(identical(entry.value(raw), raw), isTrue, reason: '$version');
        }
      });

      test('${entry.key} rejects unknown or wrongly typed versions at path',
          () {
        for (final invalid in <Object?>[
          'v0',
          'v5',
          true,
          1,
          <String, Object?>{},
        ]) {
          final raw = <String, dynamic>{
            'name': 'invalid',
            'version': invalid,
          };

          expect(
            () => entry.value(raw),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                startsWith(r'$.version:'),
              ),
            ),
            reason: '$invalid',
          );
        }
      });
    }

    test('manifest migration rejects records or snapshots under effective V1',
        () {
      for (final catalog in <ProjectBorderCatalog>[
        ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[_record('coast')],
        ),
        ProjectBorderCatalog(
          visualSnapshots: <BorderVisualSnapshot>[_snapshot('a')],
        ),
      ]) {
        for (final version in <Object?>[_absentVersion, null, 'v1']) {
          final raw = <String, dynamic>{
            'borderCatalog': encodeProjectBorderCatalogJson(catalog),
          };
          if (!identical(version, _absentVersion)) {
            raw['version'] = version;
          }
          expect(
            () => migrateProjectManifestJson(raw),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                startsWith(r'$.borderCatalog:'),
              ),
            ),
          );
          raw['version'] = 'v2';
          expect(identical(migrateProjectManifestJson(raw), raw), isTrue);
        }
      }
    });

    test('map migration rejects Border layers under V1', () {
      for (final version in <Object?>[_absentVersion, null, 'v1']) {
        final raw = <String, dynamic>{
          'layers': <Object?>[
            <String, Object?>{
              'runtimeType': 'border',
              'id': 'borders',
            },
          ],
        };
        if (!identical(version, _absentVersion)) {
          raw['version'] = version;
        }
        expect(
          () => migrateMapDataJson(raw),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              startsWith(r'$.layers[0].runtimeType:'),
            ),
          ),
        );
        raw['version'] = 'v2';
        expect(identical(migrateMapDataJson(raw), raw), isTrue);
      }
    });
  });
}

const Object _absentVersion = Object();

BorderBlueprintRecord _record(String id) => BorderBlueprintRecord(
      id: id,
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition:
            BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
          name: 'Border $id',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: const <BorderPrimitiveDraft>[],
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          sortOrder: 0,
        ),
      ),
    );

BorderVisualSnapshot _snapshot(String digit) {
  final fingerprint = digit * 64;
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$fingerprint',
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$digit.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 8, height: 8),
        durationMs: 100,
      ),
    ],
  );
}
