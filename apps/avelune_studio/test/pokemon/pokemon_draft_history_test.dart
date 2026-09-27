import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the latest 100 edits undoable after a long typing session', () {
    final draft = PokemonSpeciesDraft(_bundle());

    for (var edit = 1; edit <= 500; edit++) {
      draft.edit(PokemonDocumentFamily.species, (json) {
        (json['names'] as Map)['fr'] = 'Nom $edit';
      });
    }

    var undoCount = 0;
    while (draft.canUndo) {
      draft.undo();
      undoCount++;
    }
    expect(undoCount, 100);
    expect(_name(draft), 'Nom 400');

    var redoCount = 0;
    while (draft.canRedo) {
      draft.redo();
      redoCount++;
    }
    expect(redoCount, 100);
    expect(_name(draft), 'Nom 500');
  });

  test('limits retained history for large documents', () {
    final draft = PokemonSpeciesDraft(_bundle(payload: 'x' * (1024 * 1024)));

    for (var edit = 1; edit <= 20; edit++) {
      draft.edit(PokemonDocumentFamily.species, (json) {
        (json['names'] as Map)['fr'] = 'Nom $edit';
      });
    }

    var undoCount = 0;
    while (draft.canUndo) {
      draft.undo();
      undoCount++;
    }
    expect(undoCount, inInclusiveRange(5, 8));
  });

  test('undo and redo restore only the edited document family', () {
    final draft = PokemonSpeciesDraft(_bundle());
    draft.edit(PokemonDocumentFamily.species, (json) {
      (json['names'] as Map)['fr'] = 'Premier';
    });
    draft.edit(PokemonDocumentFamily.learnset, (json) {
      (json['moves'] as List).add('growl');
    });

    draft.undo();
    expect(_name(draft), 'Premier');
    expect(draft.document(PokemonDocumentFamily.learnset)!['moves'], [
      'tackle',
    ]);

    draft.undo();
    expect(_name(draft), 'Bulbizarre');
    draft.redo();
    expect(_name(draft), 'Premier');
    draft.edit(PokemonDocumentFamily.species, (json) {
      (json['names'] as Map)['fr'] = 'Autre';
    });
    expect(draft.canRedo, isFalse);
  });
}

PokemonSpeciesBundle _bundle({String payload = ''}) => PokemonSpeciesBundle(
  species: PokemonDocumentSource(
    family: PokemonDocumentFamily.species,
    relativePath: 'species.json',
    bytes: null,
    document: {
      'id': 'bulbasaur',
      'names': {'fr': 'Bulbizarre'},
      'payload': payload,
    },
  ),
  learnset: const PokemonDocumentSource(
    family: PokemonDocumentFamily.learnset,
    relativePath: 'learnset.json',
    bytes: null,
    document: {
      'moves': ['tackle'],
    },
  ),
  evolution: null,
  media: null,
);

String _name(PokemonSpeciesDraft draft) =>
    (draft.document(PokemonDocumentFamily.species)!['names'] as Map)['fr']
        as String;
