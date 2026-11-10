import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

PokemonSpeciesSummary _entry(String id, String form, {String? base}) =>
    PokemonSpeciesSummary(
      id: id,
      name: 'Forme $form',
      nationalDex: 26,
      generation: 1,
      types: const [],
      formIds: [form],
      formId: form,
      baseFormId: base ?? id,
      isBaseForm: base == null,
      mediaRelativePath: '',
      enabled: true,
      relativePath: '$id.json',
    );

void main() {
  test(
    'nested document edits preserve sibling keys and create missing containers',
    () {
      final json = <String, dynamic>{
        'name': {'fr': 'Raichu'},
        'typing': false,
      };
      PokemonDocumentEditing.write(json, ['name', 'en'], 'Raichu EN');
      PokemonDocumentEditing.write(json, ['typing', 'types'], ['electric']);
      expect(PokemonDocumentEditing.read(json, ['name', 'fr']), 'Raichu');
      expect(PokemonDocumentEditing.read(json, ['name', 'en']), 'Raichu EN');
      expect(PokemonDocumentEditing.read(json, ['typing', 'types']), [
        'electric',
      ]);
      expect(PokemonDocumentEditing.read(json, ['missing', 'value']), isNull);
    },
  );

  test('species typing removes empty values and duplicates while preserving metadata', () {
    final json = <String, dynamic>{
      'typing': {
        'types': ['electric', 'psychic'],
        'ability': 'static',
      },
    };
    PokemonDocumentEditing.setType(json, 0, 'psychic');
    expect((json['typing'] as Map)['types'], ['psychic']);
    PokemonDocumentEditing.setType(json, 1, 'electric');
    expect((json['typing'] as Map)['types'], ['psychic', 'electric']);
    PokemonDocumentEditing.setType(json, 1, '');
    expect((json['typing'] as Map)['types'], ['psychic']);
    expect((json['typing'] as Map)['ability'], 'static');
  });

  test('form candidates remain in the owning base group and exclude the selected form', () {
    final entries = [
      _entry('raichu', 'base'),
      _entry('raichu-alola', 'alola', base: 'raichu'),
      _entry('raichu-mega', 'mega', base: 'raichu'),
      _entry('pikachu', 'base'),
    ];
    final siblings = PokemonDocumentEditing.siblings(
      entries: entries,
      ownerId: 'raichu-alola',
      forms: {'formId': 'alola', 'isBaseForm': false, 'baseFormId': 'raichu'},
    );
    expect(siblings.map((entry) => entry.id), ['raichu', 'raichu-mega']);
    expect(PokemonDocumentEditing.matchesForm(siblings.last, 'mega'), isTrue);
    expect(
      PokemonDocumentEditing.matchesForm(siblings.last, 'pikachu'),
      isFalse,
    );
    expect(
      PokemonDocumentEditing.siblings(
        entries: entries,
        forms: {},
        ownerId: null,
      ),
      isEmpty,
    );
  });

  test('adding and removing links preserve unresolved forms and other form metadata', () {
    final forms = <String, dynamic>{
      'otherForms': ['alola', 'unresolved'],
      'formId': 'base',
    };
    expect(PokemonDocumentEditing.addForm(forms, 'alola'), [
      'alola',
      'unresolved',
    ]);
    expect(PokemonDocumentEditing.addForm(forms, 'mega'), [
      'alola',
      'unresolved',
      'mega',
    ]);
    final json = <String, dynamic>{'forms': forms};
    PokemonDocumentEditing.setForms(
      json,
      PokemonDocumentEditing.removeForm(forms, 0),
    );
    expect((json['forms'] as Map)['otherForms'], ['unresolved']);
    expect((json['forms'] as Map)['formId'], 'base');
    expect(forms['otherForms'], ['alola', 'unresolved']);
  });

  test('evolution defaults and edits preserve every unedited entry and localized condition', () {
    final json = <String, dynamic>{
      'evolutions': [
        {
          'targetSpeciesId': 'raichu',
          'method': 'item',
          'conditionText': {'fr': 'Pierre Foudre', 'en': 'Thunder Stone'},
          'custom': true,
        },
      ],
    };
    PokemonDocumentEditing.addEvolution(json, 'raichu-alola');
    final entries = json['evolutions'] as List;
    expect(entries.last, {
      'targetSpeciesId': 'raichu-alola',
      'method': 'level',
      'conditionText': {},
    });
    PokemonDocumentEditing.editEvolutionCondition(json, 0, 'fr', 'À Alola');
    PokemonDocumentEditing.editEvolution(json, 1, 'level', 30);
    expect((json['evolutions'] as List).first, {
      'targetSpeciesId': 'raichu',
      'method': 'item',
      'conditionText': {'fr': 'À Alola', 'en': 'Thunder Stone'},
      'custom': true,
    });
    expect(((json['evolutions'] as List).last as Map)['level'], 30);
    PokemonDocumentEditing.removeEvolution(json, 1);
    expect(json['evolutions'] as List, hasLength(1));
  });
}
