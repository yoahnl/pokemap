import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Bag stack identity', () {
    test('merges stacks by itemId and preserves the total quantity', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', quantity: 2),
          BagEntry(itemId: 'poke-ball', quantity: 5),
          BagEntry(itemId: 'potion', quantity: 3),
        ],
      );

      expect(bag.normalized().entries, const [
        BagEntry(itemId: 'poke-ball', quantity: 5),
        BagEntry(itemId: 'potion', quantity: 5),
      ]);
    });

    test('produces a stable itemId order for equivalent bags', () {
      const first = Bag(
        entries: [
          BagEntry(itemId: 'zinc', quantity: 1),
          BagEntry(itemId: 'antidote', quantity: 1),
        ],
      );
      const second = Bag(
        entries: [
          BagEntry(itemId: 'antidote', quantity: 1),
          BagEntry(itemId: 'zinc', quantity: 1),
        ],
      );

      expect(first.normalized(), second.normalized());
    });

    test('rejects a merged quantity that overflows signed int64', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', quantity: 0x7fffffffffffffff),
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      expect(
        bag.normalized,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('exceeds'),
          ),
        ),
      );
    });

    test('writes the canonical item system save schema', () {
      final json = const SaveData(
        saveId: 'slot-1',
        bag: Bag(entries: [BagEntry(itemId: 'potion', quantity: 2)]),
      ).toJson();

      expect(json['itemSystemSchemaVersion'], 1);
      expect(json['bag'], {
        'entries': [
          {'itemId': 'potion', 'quantity': 2},
        ],
      });
    });

    test('loads the golden Item System V1 save', () {
      final json = jsonDecode(
        File('test/fixtures/item_system_v1_save.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final save = SaveData.fromJson(json).normalized();

      expect(save.itemSystemSchemaVersion, currentItemSystemSaveSchemaVersion);
      expect(save.bag.entries, const [
        BagEntry(itemId: 'antidote', quantity: 1),
        BagEntry(itemId: 'poke-ball', quantity: 5),
        BagEntry(itemId: 'potion', quantity: 2),
      ]);
      expect(save.toJson()['bag'], {
        'entries': [
          {'itemId': 'antidote', 'quantity': 1},
          {'itemId': 'poke-ball', 'quantity': 5},
          {'itemId': 'potion', 'quantity': 2},
        ],
      });
    });

    test('refuses a legacy save containing categoryId', () {
      final legacyJson = <String, dynamic>{
        'saveId': 'slot-1',
        'itemSystemSchemaVersion': 1,
        'bag': {
          'entries': [
            {'itemId': 'potion', 'categoryId': 'medicine', 'quantity': 2},
          ],
        },
      };

      expect(
        () => SaveData.fromJson(legacyJson),
        throwsA(
          isA<UnsupportedSaveSchema>()
              .having((error) => error.schemaVersion, 'schemaVersion', 1)
              .having(
                (error) => error.expectedSchemaVersion,
                'expectedSchemaVersion',
                1,
              )
              .having(
                (error) => error.path,
                'path',
                r'$.bag.entries[0].categoryId',
              ),
        ),
      );
    });

    test('refuses every unknown BagEntry field', () {
      final json = <String, dynamic>{
        'saveId': 'slot-1',
        'itemSystemSchemaVersion': 1,
        'bag': {
          'entries': [
            {'itemId': 'potion', 'quantity': 2, 'unexpected': true},
          ],
        },
      };

      expect(
        () => SaveData.fromJson(json),
        throwsA(
          isA<UnsupportedSaveSchema>().having(
            (error) => error.path,
            'path',
            r'$.bag.entries[0].unexpected',
          ),
        ),
      );
    });

    test('refuses a save without the mandatory item system schema', () {
      expect(
        () => SaveData.fromJson({'saveId': 'slot-1'}),
        throwsA(
          isA<UnsupportedSaveSchema>()
              .having((error) => error.schemaVersion, 'schemaVersion', isNull)
              .having(
                (error) => error.path,
                'path',
                r'$.itemSystemSchemaVersion',
              ),
        ),
      );
    });
  });
}
