import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('project item catalog codec', () {
    test('round-trips a complete canonical v1 catalog in stable order', () {
      final decodedJson = _fixture('items_catalog_v1_complete.json');

      final catalog = decodeProjectItemCatalog(decodedJson);
      final encoded = encodeProjectItemCatalog(catalog);
      final decodedAgain = decodeProjectItemCatalog(encoded);

      expect(decodedAgain, catalog);
      expect(decodedAgain.entries.map((entry) => entry.id), [
        'potion',
        'poke-ball',
        'escape-rope',
        'cut-hm',
      ]);
      expect(
        encoded['entries'],
        isA<List<Object?>>().having(
          (entries) => entries
              .cast<Map<String, Object?>>()
              .map((entry) => entry['id'])
              .toList(),
          'entry order',
          ['potion', 'poke-ball', 'escape-rope', 'cut-hm'],
        ),
      );
    });

    test('requires schemaVersion 1', () {
      expect(
        () => decodeProjectItemCatalog({'entries': <Object?>[]}),
        throwsA(
          isA<UnsupportedItemCatalogSchema>()
              .having((error) => error.schemaVersion, 'schemaVersion', isNull)
              .having((error) => error.path, 'path', r'$.schemaVersion'),
        ),
      );
      expect(
        () => decodeProjectItemCatalog({
          'schemaVersion': 2,
          'entries': <Object?>[],
        }),
        throwsA(
          isA<UnsupportedItemCatalogSchema>().having(
            (error) => error.schemaVersion,
            'schemaVersion',
            2,
          ),
        ),
      );
    });

    test('rejects legacy category and effect text fields with location', () {
      final legacy = _fixture('items_catalog_legacy_rejected.json');

      expect(
        () => decodeProjectItemCatalog(legacy),
        throwsA(
          isA<ProjectItemCatalogCodecException>()
              .having(
                (error) => error.code,
                'code',
                ProjectItemCatalogCodecErrorCode.legacyField,
              )
              .having((error) => error.entryIndex, 'entryIndex', 1)
              .having((error) => error.itemId, 'itemId', 'potion')
              .having(
                (error) => error.path,
                'path',
                r'$.entries[1].categoryId',
              ),
        ),
      );

      final freeTextEffect = {
        'schemaVersion': 1,
        'entries': [
          {
            'id': 'potion',
            'displayName': 'Potion',
            'pocketId': 'medicine',
            'uses': [
              {
                'contexts': ['overworld'],
                'target': 'party_member',
                'consumption': 'on_applied',
                'effect': 'Restores 20 HP',
              },
            ],
          },
        ],
      };

      expect(
        () => decodeProjectItemCatalog(freeTextEffect),
        throwsA(
          isA<ProjectItemCatalogCodecException>()
              .having(
                (error) => error.code,
                'code',
                ProjectItemCatalogCodecErrorCode.legacyField,
              )
              .having((error) => error.entryIndex, 'entryIndex', 0)
              .having((error) => error.itemId, 'itemId', 'potion')
              .having(
                (error) => error.path,
                'path',
                r'$.entries[0].uses[0].effect',
              ),
        ),
      );
    });

    test('rejects unknown kinds and unexpected fields with typed errors', () {
      final unknownKind = _minimalCatalog();
      final entry =
          (unknownKind['entries']! as List<Object?>).single
              as Map<String, Object?>;
      entry['uses'] = [
        {
          'contexts': ['overworld'],
          'target': 'world',
          'consumption': 'on_applied',
          'effect': {'kind': 'teleport'},
        },
      ];

      expect(
        () => decodeProjectItemCatalog(unknownKind),
        throwsA(
          isA<ProjectItemCatalogCodecException>()
              .having(
                (error) => error.code,
                'code',
                ProjectItemCatalogCodecErrorCode.unsupportedKind,
              )
              .having((error) => error.entryIndex, 'entryIndex', 0)
              .having((error) => error.itemId, 'itemId', 'custom-item'),
        ),
      );

      expect(
        () => decodeProjectItemCatalog({
          ..._minimalCatalog(),
          'catalog': 'items',
        }),
        throwsA(
          isA<ProjectItemCatalogCodecException>().having(
            (error) => error.code,
            'code',
            ProjectItemCatalogCodecErrorCode.unexpectedField,
          ),
        ),
      );
    });

    test('does not infer effects or inject fallback entries', () {
      final empty = decodeProjectItemCatalog({
        'schemaVersion': 1,
        'entries': <Object?>[],
      });
      final namedLikeKnownItem = decodeProjectItemCatalog(_minimalCatalog());

      expect(empty.entries, isEmpty);
      expect(namedLikeKnownItem.entries.single.uses, isEmpty);
      expect(namedLikeKnownItem.entries.single.capture, isNull);
    });
  });
}

Object? _fixture(String name) {
  return jsonDecode(File('test/fixtures/$name').readAsStringSync());
}

Map<String, Object?> _minimalCatalog() {
  return {
    'schemaVersion': 1,
    'entries': <Object?>[
      <String, Object?>{
        'id': 'custom-item',
        'displayName': 'Custom Item',
        'pocketId': 'items',
      },
    ],
  };
}
