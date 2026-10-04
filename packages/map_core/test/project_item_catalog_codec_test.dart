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

    test('round-trips an optional project capture animation PNG path', () {
      final json = _minimalCatalog();
      final entry =
          (json['entries']! as List<Object?>).single as Map<String, Object?>;
      entry['capture'] = {
        'rateNumerator': 1,
        'rateDenominator': 1,
        'allowedEncounterKinds': ['walk'],
        'animationSpritePath': ' assets/capture/custom-ball.png ',
      };

      final decoded = decodeProjectItemCatalog(json);
      final encoded = encodeProjectItemCatalog(decoded);
      final encodedEntry = (encoded['entries']! as List).single as Map;

      expect(
        encodedEntry['capture']['animationSpritePath'],
        'assets/capture/custom-ball.png',
      );
      expect(decodeProjectItemCatalog(encoded), decoded);
      expect(encoded['schemaVersion'], 1);
    });

    test('omits capture animation paths when the object has no visual', () {
      final json = _minimalCatalog();
      final entry =
          (json['entries']! as List<Object?>).single as Map<String, Object?>;
      entry['capture'] = {
        'rateNumerator': 1,
        'rateDenominator': 1,
        'allowedEncounterKinds': ['walk'],
      };

      final encoded = encodeProjectItemCatalog(decodeProjectItemCatalog(json));
      final encodedEntry = (encoded['entries']! as List).single as Map;

      expect(
        (encodedEntry['capture'] as Map).containsKey('animationSpritePath'),
        isFalse,
      );
    });

    test('rejects unsafe or non-PNG capture paths at the exact field', () {
      for (final path in <Object>[
        'art/custom.png',
        'custom.png',
        'Assets/custom.png',
        'database/custom.png',
        '/tmp/ball.png',
        '../ball.png',
        'assets/../ball.png',
        'C:/ball.png',
        r'assets\ball.png',
        'assets/\u0000ball.png',
        'https://example.invalid/ball.png',
        'assets/ball.jpg',
        'assets//ball.png',
        'assets/./ball.png',
        '',
        ' ',
        42,
      ]) {
        final json = _minimalCatalog();
        final entry =
            (json['entries']! as List<Object?>).single as Map<String, Object?>;
        entry['capture'] = {
          'rateNumerator': 1,
          'rateDenominator': 1,
          'allowedEncounterKinds': ['walk'],
          'animationSpritePath': path,
        };

        expect(
          () => decodeProjectItemCatalog(json),
          throwsA(
            isA<ProjectItemCatalogCodecException>()
                .having(
                  (error) => error.code,
                  'code',
                  ProjectItemCatalogCodecErrorCode.invalidValue,
                )
                .having(
                  (error) => error.path,
                  'path',
                  r'$.entries[0].capture.animationSpritePath',
                ),
          ),
          reason: 'path: $path',
        );
      }
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
