import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_trainer_species_reader.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/combat_project_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
  test('trainer stats read the persisted species without changing its selected draft', () async {
    final reader = _RecordingReader();
    final fixture = await PokemonAuthoringFixture.create(
      prepareSource: seedCombatProject,
      reader: reader,
    );
    addTearDown(fixture.dispose);
    final controller = fixture.pokemon;
    final index = controller.index!;
    final summary = index.entries.singleWhere(
      (entry) => entry.id == 'bulbasaur',
    );
    final speciesFile = File(
      '${fixture.source.directory.path}/${summary.relativePath}',
    );
    final projectFile = File('${fixture.source.directory.path}/project.json');
    final speciesBefore = await speciesFile.readAsBytes();
    final projectBefore = await projectFile.readAsBytes();
    expect(await controller.selectSpecies('bulbasaur'), isTrue);
    final draft = controller.selectedDraft!;
    draft.edit(PokemonDocumentFamily.species, (document) {
      (document['baseStats'] as Map)['hp'] = 99;
    });
    reader.clear();

    final species = await loadPokemonTrainerSpecies(
      port: fixture.port,
      index: index,
      id: 'bulbasaur',
    );

    expect(species!.id, 'bulbasaur');
    expect(species.names['fr'], 'Bulbizarre');
    expect(species.baseStats.hp, 45);
    expect(species.baseStats.atk, 49);
    expect(species.typing.types, ['grass', 'poison']);
    expect(controller.selectedDraft, same(draft));
    expect(controller.selectedId, 'bulbasaur');
    expect(draft.dirty, isTrue);
    expect(draft.canUndo, isTrue);
    expect(
      (draft.document(PokemonDocumentFamily.species)!['baseStats']
          as Map)['hp'],
      99,
    );
    expect(
      reader.paths.where((path) => path == summary.relativePath),
      hasLength(1),
    );
    expect(reader.directories, isEmpty);
    expect(reader.paths, isNot(contains('project.json')));
    expect(await speciesFile.readAsBytes(), speciesBefore);
    expect(await projectFile.readAsBytes(), projectBefore);
  });

  test(
    'an ID absent from the supplied index does not read project files',
    () async {
      final reader = _RecordingReader();
      final fixture = await PokemonAuthoringFixture.create(
        prepareSource: seedCombatProject,
        reader: reader,
      );
      addTearDown(fixture.dispose);
      reader.clear();

      expect(
        await loadPokemonTrainerSpecies(
          port: fixture.port,
          index: fixture.pokemon.index!,
          id: 'missing',
        ),
        isNull,
      );
      expect(reader.paths, isEmpty);
      expect(reader.directories, isEmpty);
      expect(fixture.pokemon.selectedDraft, isNull);
    },
  );

  for (final malformed in [false, true]) {
    test('species read errors remain visible malformed=$malformed', () async {
      final fixture = await PokemonAuthoringFixture.create(
        prepareSource: seedCombatProject,
      );
      addTearDown(fixture.dispose);
      final index = fixture.pokemon.index!;
      final summary = index.entries.singleWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      final file = File(
        '${fixture.source.directory.path}/${summary.relativePath}',
      );
      if (malformed) {
        await file.writeAsString('{');
      } else {
        final document =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        document['id'] = 'another-species';
        await file.writeAsString(jsonEncode(document));
      }
      final before = await file.readAsBytes();

      await expectLater(
        loadPokemonTrainerSpecies(
          port: fixture.port,
          index: index,
          id: 'bulbasaur',
        ),
        throwsA(
          malformed ? isA<FormatException>() : isA<PokemonWorkspaceFailure>(),
        ),
      );
      expect(await file.readAsBytes(), before);
      expect(fixture.pokemon.selectedDraft, isNull);
      expect(fixture.pokemon.error, isNull);
    });
  }

  for (final problem in [null, 'Unavailable species']) {
    test(
      'a source without a usable species returns no stats problem=$problem',
      () async {
        final port = _UnavailableSpeciesPort(problem);
        final index = PokemonWorkspaceIndex(
          enabled: true,
          entries: [port.summary],
          moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
          types: [],
          items: {},
        );

        expect(
          await loadPokemonTrainerSpecies(port: port, index: index, id: 'bird'),
          isNull,
        );
        expect(port.loaded, same(port.summary));
      },
    );
  }
}

final class _RecordingReader
    implements ProjectFileReader, ProjectDirectoryReader {
  final local = const LocalProjectFileReader();
  final paths = <String>[];
  final directories = <String>[];

  void clear() {
    paths.clear();
    directories.clear();
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      local.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) {
    directories.add(relativeDirectory);
    return local.listFiles(
      projectRoot: projectRoot,
      relativeDirectory: relativeDirectory,
    );
  }
}

final class _UnavailableSpeciesPort implements PokemonWorkspacePort {
  _UnavailableSpeciesPort(this.problem);

  final String? problem;
  PokemonSpeciesSummary? loaded;
  final summary = const PokemonSpeciesSummary(
    id: 'bird',
    name: 'Oiseau',
    nationalDex: 1,
    generation: 1,
    types: ['normal'],
    formIds: ['base'],
    mediaRelativePath: '',
    enabled: true,
    relativePath: 'species/bird.json',
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async {
    loaded = entry;
    return PokemonSpeciesBundle(
      species: PokemonDocumentSource(
        family: PokemonDocumentFamily.species,
        relativePath: entry.relativePath,
        bytes: null,
        document: problem == null ? null : {'id': 'bird'},
        problem: problem,
      ),
      learnset: null,
      evolution: null,
      media: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
