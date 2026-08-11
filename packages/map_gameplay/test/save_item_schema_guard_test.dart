import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/items/save_item_schema_guard.dart';
import 'package:test/test.dart';

void main() {
  const guard = SaveItemSchemaGuard();
  final originalState = GameState(
    saveId: 'current-session',
    bag: const Bag(entries: [BagEntry(itemId: 'antidote', quantity: 4)]),
  );

  test('accepts and stably reloads the canonical item save schema', () {
    const save = SaveData(
      saveId: 'slot-1',
      bag: Bag(
        entries: [
          BagEntry(itemId: 'potion', quantity: 2),
          BagEntry(itemId: 'poke-ball', quantity: 5),
        ],
      ),
    );

    final result = guard.decode(
      save.toJson(),
      originalState: originalState,
    );

    expect(result.isAccepted, isTrue);
    expect(result.diagnostic, isNull);
    expect(result.saveData, save.normalized());
    expect(result.saveData?.toJson(), save.normalized().toJson());
    expect(result.state.bag, save.bag.normalized());
  });

  test('rejects unsupported item save wire with no mutation', () {
    final fixtures = <({
      Map<String, dynamic> json,
      Object? detectedVersion,
      String path,
    })>[
      (
        json: {'saveId': 'missing-version'},
        detectedVersion: null,
        path: r'$.itemSystemSchemaVersion',
      ),
      (
        json: {'saveId': 'wrong-version', 'itemSystemSchemaVersion': 0},
        detectedVersion: 0,
        path: r'$.itemSystemSchemaVersion',
      ),
      (
        json: {
          'saveId': 'legacy-entry',
          'itemSystemSchemaVersion': 1,
          'bag': {
            'entries': [
              {
                'itemId': 'potion',
                'categoryId': 'medicine',
                'quantity': 1,
              },
            ],
          },
        },
        detectedVersion: 1,
        path: r'$.bag.entries[0].categoryId',
      ),
      (
        json: {
          'saveId': 'unknown-entry-field',
          'itemSystemSchemaVersion': 1,
          'bag': {
            'entries': [
              {'itemId': 'potion', 'quantity': 1, 'unexpected': true},
            ],
          },
        },
        detectedVersion: 1,
        path: r'$.bag.entries[0].unexpected',
      ),
    ];

    for (final fixture in fixtures) {
      final result = guard.decode(
        fixture.json,
        originalState: originalState,
      );

      expect(result.isAccepted, isFalse);
      expect(result.state, same(originalState));
      expect(result.saveData, isNull);
      expect(result.diagnostic?.code, 'UnsupportedSaveSchema');
      expect(result.diagnostic?.schemaVersion, fixture.detectedVersion);
      expect(result.diagnostic?.expectedSchemaVersion, 1);
      expect(result.diagnostic?.path, fixture.path);
    }
  });
}
