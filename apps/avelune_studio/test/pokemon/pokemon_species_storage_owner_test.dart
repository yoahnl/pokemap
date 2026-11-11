import 'dart:convert';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';
import '../support/pokemon_moves_source_fixture.dart';
import '../support/pokemon_species_owner_fixture.dart';

void main() {
  test('ambiguous legacy companion leaves the species readable', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        final template = await readPokemonPackDocument(
          'species',
          '0001-bulbasaur.json',
        );
        for (final id in ['bulbasaur', 'second']) {
          final species =
              jsonDecode(jsonEncode(template)) as Map<String, dynamic>
                ..['id'] = id
                ..['slug'] = id;
          (species['refs'] as Map)['learnset'] = 'shared-learn';
          await writePokemonDocument(source, 'species/$id.json', species);
        }
        final learnset = await readPokemonPackDocument(
          'learnsets',
          'bulbasaur.json',
        );
        learnset['speciesId'] = 'shared-learn';
        await writePokemonDocument(
          source,
          'learnsets/shared-learn.json',
          learnset,
        );
      },
    );
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final draft = host.pokemon.selectedDraft!;
    expect(draft.document(PokemonDocumentFamily.species)!['id'], 'bulbasaur');
    expect(draft.base.learnset!.document, isNull);
    expect(draft.base.learnset!.problem, contains('sans propriétaire unique'));
    expect(draft.document(PokemonDocumentFamily.learnset), isNull);
    host.pokemon.beginMoveSelection('startingMoves');
    expect(host.pokemon.moveInsertGroup, isNull);
    expect(host.pokemon.view, PokemonWorkspaceView.pokedex);
  });

  test('save follows manifest and companion refs, not species id', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async {
        final species = await readPokemonPackDocument(
          'species',
          '0001-bulbasaur.json',
        );
        final refs = species['refs'] as Map;
        for (final (folder, ref) in [
          ('learnsets', 'custom-learn'),
          ('evolutions', 'custom-evolution'),
          ('media', 'custom-media'),
        ]) {
          final companion = await readPokemonPackDocument(
            folder,
            'bulbasaur.json',
          );
          companion['speciesId'] = ref;
          refs[switch (folder) {
                'learnsets' => 'learnset',
                'evolutions' => 'evolution',
                _ => 'media',
              }] =
              ref;
          await writePokemonDocument(source, '$folder/$ref.json', companion);
        }
        await writePokemonDocument(
          source,
          'species/custom-filename.json',
          species,
        );
        await seedPokemonMovesCatalog(source);
      },
    );
    addTearDown(host.dispose);
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    final draft = host.pokemon.selectedDraft!;
    expect(
      draft.document(PokemonDocumentFamily.learnset)?['speciesId'],
      'custom-learn',
    );
    expect(
      draft.document(PokemonDocumentFamily.evolution)?['speciesId'],
      'custom-evolution',
    );
    expect(
      draft.document(PokemonDocumentFamily.media)?['speciesId'],
      'custom-media',
    );
    writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
      'names',
      'fr',
    ], 'Nom personnalisé');
    host.pokemon.beginMoveSelection('startingMoves');
    host.pokemon.chooseMove('leech-seed');
    expect(await host.pokemon.saveActiveOwner(), isTrue);
    final species = await readPokemonProjectDocument(
      host,
      'species/custom-filename.json',
    );
    final learnset = await readPokemonProjectDocument(
      host,
      'learnsets/custom-learn.json',
    );
    expect((species['names'] as Map)['fr'], 'Nom personnalisé');
    expect(learnset['startingMoves'] as List, contains('leech-seed'));
    expect(
      await pokemonProjectFile(host, 'learnsets/bulbasaur.json').exists(),
      isFalse,
    );
    expect(
      (await readPokemonProjectDocument(
        host,
        'evolutions/custom-evolution.json',
      ))['speciesId'],
      'custom-evolution',
    );
    expect(
      (await readPokemonProjectDocument(
        host,
        'media/custom-media.json',
      ))['speciesId'],
      'custom-media',
    );
  });

  test('disk revision conflict keeps the focused species draft', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: (source) async => writePokemonDocument(
        source,
        'species/0001-bulbasaur.json',
        await readPokemonPackDocument('species', '0001-bulbasaur.json'),
      ),
    );
    addTearDown(host.dispose);
    final file = pokemonProjectFile(host, 'species/0001-bulbasaur.json');
    expect(await host.workflow.requestSpecies('bulbasaur'), isTrue);
    writePokemonDraftField(host.pokemon, PokemonDocumentFamily.species, [
      'names',
      'fr',
    ], 'Brouillon conservé');
    final external = jsonDecode(await file.readAsString()) as Map;
    (external['names'] as Map)['fr'] = 'Modification externe';
    await file.writeAsString(jsonEncode(external));
    final changed = await file.readAsBytes();
    expect(await host.pokemon.saveActiveOwner(), isFalse);
    expect(host.pokemon.error, contains('Enregistrement refusé'));
    final draft = host.pokemon.selectedDraft!;
    expect(draft.dirty, isTrue);
    expect(
      (draft.document(PokemonDocumentFamily.species)!['names'] as Map)['fr'],
      'Brouillon conservé',
    );
    expect(await file.readAsBytes(), changed);
  });

  test('moves preview is read only and apply writes merged catalog', () async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: seedPokemonSpeciesDocuments,
      movesSource: const PokemonMovesSourceFixture(),
    );
    addTearDown(host.dispose);
    final catalog = pokemonProjectFile(host, 'catalogs/moves.json');
    final before = await catalog.readAsBytes();
    expect(await host.view(PokemonWorkspaceView.moves), isTrue);
    expect(await host.pokemon.previewMovesSync(), isTrue);
    expect(host.pokemon.movesPreview!.createdIds, contains('thunderbolt'));
    expect(await catalog.readAsBytes(), before);
    expect(await host.pokemon.applyMovesSync(), isTrue);
    expect(host.pokemon.movesPreview, isNull);
    final ids = {
      for (final entry
          in (jsonDecode(await catalog.readAsString()) as Map)['entries']
              as List)
        (entry as Map)['id'],
    };
    expect(ids, contains('thunderbolt'));
    expect(ids, contains('leech-seed'));
    expect(
      host.pokemon.index!.moves.entries.map((move) => move.id),
      contains('thunderbolt'),
    );
  });

  test('read-only search can leave A and cannot update project B', () async {
    final source = HeldPokemonExternalSourceFixture();
    Future<void> seed(M3StoryFixture fixture, String name) async {
      final species = await readPokemonPackDocument(
        'species',
        '0001-bulbasaur.json',
      );
      (species['names'] as Map)['fr'] = name;
      await writePokemonDocument(
        fixture,
        'species/0001-bulbasaur.json',
        species,
      );
    }

    final first = await PokemonAuthoringFixture.create(
      externalSource: source,
      prepareSource: (fixture) => seed(fixture, 'Espèce du projet A'),
    );
    addTearDown(first.dispose);
    final controller = first.pokemon;
    final searching = controller.searchExternal('bulbasaur');
    expect(controller.externalBusy, isTrue);
    expect(await first.workflow.requestLeave(), isTrue);
    expect(first.draftConfirmations, 0);
    await first.closeOwners();
    source.gate.complete();
    expect(await searching, isFalse);
    expect(controller.externalSearch, isNull);
    final second = await PokemonAuthoringFixture.create(
      prepareSource: (fixture) => seed(fixture, 'Espèce du projet B'),
    );
    addTearDown(second.dispose);
    final next = second.pokemon;
    expect(next, isNot(same(controller)));
    expect(next.externalSearch, isNull);
    expect(next.externalPreview, isNull);
    expect(next.index!.entries.single.name, 'Espèce du projet B');
  });
}
