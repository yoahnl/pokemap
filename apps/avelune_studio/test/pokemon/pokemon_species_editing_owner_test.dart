import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_species_owner_fixture.dart';

void main() {
  test(
    'focused species and learnset edits survive independent reopen',
    () async {
      final host = await PokemonAuthoringFixture.create(
        prepareSource: seedPokemonSpeciesDocuments,
      );
      addTearDown(host.dispose);
      expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
      writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
        'names',
        'fr',
      ], 'Bulbizarre du Train');
      host.pokemon.beginMoveSelection('startingMoves');
      expect(host.pokemon.view, PokemonWorkspaceView.moves);
      host.pokemon.chooseMove('leech-seed');
      expect(host.pokemon.view, PokemonWorkspaceView.pokedex);
      expect(host.pokemon.section, PokemonDetailSection.learnset);
      expect(await host.pokemon.saveActiveOwner(), isTrue);
      final species = await readPokemonProjectDocument(
        host,
        'species/0001-bulbasaur.json',
      );
      final learnset = await readPokemonProjectDocument(
        host,
        'learnsets/bulbasaur.json',
      );
      expect((species['names'] as Map)['fr'], 'Bulbizarre du Train');
      expect(learnset['startingMoves'] as List, hasLength(3));
      final reopened = await reopenPokemonSpecies(host, 'bulbasaur');
      expect(reopened.species.document!['id'], 'bulbasaur');
      expect(
        (reopened.species.document!['names'] as Map)['fr'],
        'Bulbizarre du Train',
      );
      expect(
        reopened.learnset!.document!['startingMoves'] as List,
        contains('leech-seed'),
      );
    },
  );

  test('language selection does not write fallbacks and focused edit keeps its key', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        final species = await readPokemonPackDocument(
          'species',
          '0001-bulbasaur.json',
        );
        species['names'] = {'fr': 'Bulbizarre', 'en': 'Bulbasaur'};
        await writePokemonDocument(source, 'species/bulbasaur.json', species);
      },
    );
    addTearDown(host.dispose);
    final file = pokemonProjectFile(host, 'species/bulbasaur.json');
    final before = await file.readAsBytes();
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    host.pokemon.setEditingLanguage('ja');
    expect(host.pokemon.editingLanguage, 'ja');
    expect(host.pokemon.selectedDraft!.dirty, isFalse);
    expect(
      PokemonDocumentEditing.read(
        host.pokemon.selectedDraft!.document(PokemonDocumentFamily.species)!,
        ['names', 'ja'],
      ),
      isNull,
    );
    expect(await file.readAsBytes(), before);
    writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
      'names',
      'ja',
    ], 'フシギダネ');
    host.pokemon.setEditingLanguage('en');
    expect(await host.pokemon.saveActiveOwner(), isTrue);
    final names =
        (await reopenPokemonSpecies(
              host,
              'bulbasaur',
            )).species.document!['names']
            as Map;
    expect(names['fr'], 'Bulbizarre');
    expect(names['en'], 'Bulbasaur');
    expect(names['ja'], 'フシギダネ');
  });

  test('forms and evolution save together without losing old fields', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        for (final (folder, file) in [
          ('species', '0001-bulbasaur.json'),
          ('evolutions', 'bulbasaur.json'),
        ]) {
          await writePokemonDocument(
            source,
            '$folder/$file',
            await readPokemonPackDocument(folder, file),
          );
        }
      },
    );
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
      'forms',
      'formName',
    ], 'Forme du Train');
    host.pokemon.edit(
      PokemonDocumentFamily.evolution,
      (json) => PokemonDocumentEditing.editEvolution(
        json,
        0,
        'minLevel',
        pokemonDocumentNumberInput('18'),
      ),
    );
    expect(host.pokemon.selectedDraft!.changedFamilies, [
      PokemonDocumentFamily.species,
      PokemonDocumentFamily.evolution,
    ]);
    expect(await host.pokemon.saveActiveOwner(), isTrue);
    final bundle = await reopenPokemonSpecies(host, 'bulbasaur');
    final species = bundle.species.document!;
    final target =
        (bundle.evolution!.document!['evolutions'] as List).single as Map;
    expect((species['forms'] as Map)['formName'], 'Forme du Train');
    expect((species['baseStats'] as Map)['hp'], 45);
    expect(target['minLevel'], 18);
    expect(target['method'], 'level_up');
    expect((target['conditionText'] as Map)['fr'], 'Evolue au niveau 16');
  });

  test('evolution number inputs keep blanks absent and raw text visible', () {
    expect(pokemonDocumentNumberInput(''), isNull);
    expect(pokemonDocumentNumberInput('18'), 18);
    expect(pokemonDocumentNumberInput('1.5'), '1.5');
    expect(pokemonOptionalChoice(''), isNull);
    expect(pokemonOptionalChoice('moon-stone'), 'moon-stone');
  });

  test(
    'homonyms keep distinct identities through filtering and save',
    () async {
      final host = await PokemonAuthoringFixture.create(
        prepareSource: (source) async {
          final original = await readPokemonPackDocument(
            'species',
            '0001-bulbasaur.json',
          );
          final second = Map<String, dynamic>.from(original)
            ..['id'] = 'ivysaur'
            ..['slug'] = 'ivysaur'
            ..['nationalDex'] = 2
            ..['refs'] = {
              ...(original['refs'] as Map),
              'learnset': 'ivysaur',
              'evolution': 'ivysaur',
              'media': 'ivysaur',
            };
          await writePokemonDocument(
            source,
            'species/0001-bulbasaur.json',
            original,
          );
          await writePokemonDocument(
            source,
            'species/0002-ivysaur.json',
            second,
          );
        },
      );
      addTearDown(host.dispose);
      final first = pokemonProjectFile(host, 'species/0001-bulbasaur.json');
      final beforeFirst = await first.readAsBytes();
      expect(host.pokemon.visibleSpecies.map((entry) => entry.id), [
        'bulbasaur',
        'ivysaur',
      ]);
      expect(await host.workflow.requestSpecies('ivysaur'), isTrue);
      host.pokemon.setSearch('bulbasaur');
      expect(host.pokemon.visibleSpecies.map((entry) => entry.id), [
        'bulbasaur',
      ]);
      expect(host.pokemon.selectedId, 'ivysaur');
      expect(host.pokemon.selectedDraft!.id, 'ivysaur');
      host.pokemon.setSearch('');
      writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
        'names',
        'fr',
      ], 'Bulbizarre II');
      expect(await host.pokemon.saveActiveOwner(), isTrue);
      expect(await first.readAsBytes(), beforeFirst);
      final second = await readPokemonProjectDocument(
        host,
        'species/0002-ivysaur.json',
      );
      expect(second['id'], 'ivysaur');
      expect((second['names'] as Map)['fr'], 'Bulbizarre II');
    },
  );
}
