import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/showdown_move_catalog_converter.dart';

void main() {
  const converter = ShowdownMoveCatalogConverter();

  Map<String, dynamic> entryFor(String id) {
    final catalog = converter.convert(<String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'target': 'normal',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
      },
      'fangamestrike': <String, dynamic>{
        'name': 'Fangame Strike',
        'type': 'Bug',
        'category': 'Status',
        'target': 'self',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
      },
    });
    return catalog.entries.firstWhere((entry) => entry['id'] == id);
  }

  test('a converted move carries its french name', () {
    final names =
        (entryFor('thunderbolt')['names'] as Map).cast<String, dynamic>();
    expect(names['en'], 'Thunderbolt');
    expect(names['fr'], 'Tonnerre');
  });

  test('the canonical name stays english', () {
    expect(entryFor('thunderbolt')['name'], 'Thunderbolt');
  });

  test('a move absent from the table keeps only its english name', () {
    final names =
        (entryFor('fangame_strike')['names'] as Map).cast<String, dynamic>();
    expect(names['en'], 'Fangame Strike');
    expect(names.containsKey('fr'), isFalse);
  });
}
