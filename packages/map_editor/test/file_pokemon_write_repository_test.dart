import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late InitializePokemonProjectStorageUseCase initializeStorage;
  late FilePokemonWriteRepository writeRepository;
  late FilePokemonReadRepository readRepository;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('pokemon_write_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    initializeStorage = const InitializePokemonProjectStorageUseCase();
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonWriteRepository', () {
    test('saves a species file in the project workspace', () async {
      final species = _bulbasaurSpecies();

      await writeRepository.saveSpecies(workspace, species);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['id'], 'bulbasaur');

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.gameplayFlags.starterEligible, isTrue);
    });

    test('saves a learnset file in the project workspace', () async {
      final learnset = _bulbasaurLearnset();

      await writeRepository.saveLearnset(workspace, learnset);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.levelUp.first.moveId, 'tackle');
      expect(readBack.levelUp.first.level, 1);
    });

    test('saves an evolution file in the project workspace', () async {
      final evolution = _bulbasaurEvolution();

      await writeRepository.saveEvolution(workspace, evolution);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(readBack.evolutions.single.minLevel, 16);
    });

    test('saves a media file in the project workspace', () async {
      final media = _bulbasaurMedia();

      await writeRepository.saveMedia(workspace, media);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack =
          await readRepository.readMediaById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(
        readBack.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
    });

    test('saves a catalog file in the project workspace', () async {
      await initializeStorage.execute(workspace);
      final movesCatalog = _movesCatalog();

      await writeRepository.saveCatalogByKey(workspace, 'moves', movesCatalog);

      final file = File(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      );
      expect(await file.exists(), isTrue);

      final readBack =
          await readRepository.readCatalogByKey(workspace, 'moves');
      expect(readBack.catalog, 'moves');
      expect(
        readBack.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl']),
      );
    });

    test('writes in the workspace project and not at the monorepo root',
        () async {
      final species = _bulbasaurSpecies();
      final decoy =
          await Directory.systemTemp.createTemp('pokemon_write_decoy_');
      final originalCurrent = Directory.current;
      try {
        Directory.current = decoy.path;

        await writeRepository.saveSpecies(workspace, species);

        expect(
          File(
            workspace.resolveProjectRelativePath(
              'data/pokemon/species/0001-bulbasaur.json',
            ),
          ).existsSync(),
          isTrue,
        );
        expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
        expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Write Repo Project', tempProjectRoot.path);
      await initializeStorage.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies());
      await writeRepository.saveLearnset(workspace, _bulbasaurLearnset());
      await writeRepository.saveEvolution(workspace, _bulbasaurEvolution());
      await writeRepository.saveMedia(workspace, _bulbasaurMedia());
      await writeRepository.saveCatalogByKey(
          workspace, 'moves', _movesCatalog());

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('overwrites the target species file predictably', () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Updated'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Updated demo entry',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: false,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 2,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);
      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names['en'], 'Bulbasaur Updated');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.sourceMeta.seedVersion, 2);
    });

    test('does not create a duplicate species file when the slug changes',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbizarre-custom',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Custom'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Updated demo entry after slug change.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 3,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);
      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      final speciesFiles = await speciesDir
          .list()
          .where(
              (entity) => entity is File && p.extension(entity.path) == '.json')
          .cast<File>()
          .toList();

      expect(speciesFiles, hasLength(1));
      expect(p.basename(speciesFiles.single.path), '0001-bulbasaur.json');

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.slug, 'bulbizarre-custom');
      expect(readBack.names['en'], 'Bulbasaur Custom');
      expect(readBack.sourceMeta.seedVersion, 3);
    });

    test(
        'reuses an existing non-canonical species path instead of creating a duplicate canonical file',
        () async {
      await initializeStorage.execute(workspace);

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      final customFile = File(
        p.join(speciesDir.path, '0001-bulbizarre-custom.json'),
      );
      await customFile.writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(_bulbasaurSpecies().toJson()),
      );

      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur-refreshed',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Refreshed'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Rewrite uses the already-present custom file path.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 4,
        ),
      );

      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);

      final speciesFiles = await speciesDir
          .list()
          .where(
            (entity) => entity is File && p.extension(entity.path) == '.json',
          )
          .cast<File>()
          .toList();
      expect(speciesFiles, hasLength(1));
      expect(
          p.basename(speciesFiles.single.path), '0001-bulbizarre-custom.json');

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.slug, 'bulbasaur-refreshed');
      expect(readBack.names['en'], 'Bulbasaur Refreshed');
      expect(readBack.sourceMeta.seedVersion, 4);
    });

    test('ignores a misleading species basename whose JSON declares another id',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies());

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _bulbasaurSpecies().toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );

      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur-rewritten',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Rewritten Cleanly'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Misleading filename should not block overwrite.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 6,
        ),
      );

      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await canonicalFile.exists(), isTrue);
      expect(await misleadingFile.exists(), isTrue);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.slug, 'bulbasaur-rewritten');
      expect(readBack.names['en'], 'Bulbasaur Rewritten Cleanly');
      expect(readBack.sourceMeta.seedVersion, 6);
    });

    test(
        'rewrites an existing species even when another unrelated species json is invalid',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Rewritten'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        refs: PokemonSpeciesRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Rewrite succeeds despite unrelated invalid JSON.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 4,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);

      final invalidSpeciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-unrelated.json',
        ),
      );
      await invalidSpeciesFile.parent.create(recursive: true);
      await invalidSpeciesFile.writeAsString('{ invalid json');

      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final rewrittenFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final decoded = jsonDecode(await rewrittenFile.readAsString())
          as Map<String, dynamic>;

      expect(decoded['id'], 'bulbasaur');
      expect((decoded['names'] as Map<String, dynamic>)['en'],
          'Bulbasaur Rewritten');
      expect(
        (decoded['sourceMeta'] as Map<String, dynamic>)['seedVersion'],
        4,
      );
    });

    test(
        'throws explicit conflict when multiple species files match the same id',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      await writeRepository.saveSpecies(workspace, originalSpecies);

      final conflictingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur-duplicate.json',
        ),
      );
      await conflictingFile.parent.create(recursive: true);
      final conflictingJson = _bulbasaurSpecies().toJson()
        ..['slug'] = 'bulbasaur-duplicate'
        ..['sourceMeta'] = const <String, dynamic>{
          'seededBy': 'test',
          'seedVersion': 7,
        };
      await conflictingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(conflictingJson),
      );

      expect(
        () => writeRepository.saveSpecies(
          workspace,
          const PokemonSpeciesFile(
            id: 'bulbasaur',
            slug: 'bulbasaur',
            nationalDex: 1,
            names: <String, String>{'en': 'Bulbasaur'},
            speciesName: <String, String>{'en': 'Seed Pokemon'},
            genIntroduced: 1,
            typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
            baseStats: PokemonSpeciesBaseStats(
              hp: 45,
              atk: 49,
              def: 49,
              spa: 65,
              spd: 65,
              spe: 45,
              bst: 318,
            ),
            abilities: PokemonSpeciesAbilities(
              primary: 'overgrow',
              hidden: 'chlorophyll',
            ),
            breeding: PokemonSpeciesBreeding(
              genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
              eggGroups: <String>['monster', 'grass'],
              hatchCycles: 20,
            ),
            progression: PokemonSpeciesProgression(
              growthRateId: 'medium_slow',
              baseExp: 64,
              catchRate: 45,
              baseFriendship: 50,
            ),
            refs: PokemonSpeciesRefs(
              learnset: 'bulbasaur',
              evolution: 'bulbasaur',
              media: 'bulbasaur',
            ),
            dexContent: PokemonSpeciesDexContent(
              heightM: 0.7,
              weightKg: 6.9,
              color: 'green',
              flavorText: 'Conflict test.',
            ),
            gameplayFlags: PokemonSpeciesGameplayFlags(
              starterEligible: true,
            ),
            sourceMeta: PokemonSpeciesSourceMeta(
              seededBy: 'test',
              seedVersion: 5,
            ),
          ),
        ),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains('Multiple Pokemon species files match the id "bulbasaur"'),
          ),
        ),
      );
    });

    test('throws explicit error when catalog key does not match payload',
        () async {
      await initializeStorage.execute(workspace);
      final before = await File(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      ).readAsString();

      const abilitiesCatalog = PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: 'abilities',
        meta: PokemonDataMeta(
          description: 'Ability catalog for mismatch test.',
          sourcePriority: <String>['internal'],
          notes: <String>[],
        ),
        entries: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'overgrow',
            'name': 'Overgrow',
          },
        ],
      );

      expect(
        () => writeRepository.saveCatalogByKey(
          workspace,
          'moves',
          abilitiesCatalog,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog key mismatch'),
          ),
        ),
      );

      final after = await File(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      ).readAsString();
      expect(after, before);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir =
        Directory(p.join(current.path, 'packages', 'map_editor'));
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}

PokemonSpeciesFile _bulbasaurSpecies() {
  return const PokemonSpeciesFile(
    id: 'bulbasaur',
    slug: 'bulbasaur',
    nationalDex: 1,
    names: <String, String>{'en': 'Bulbasaur', 'fr': 'Bulbizarre'},
    speciesName: <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: 1,
    typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    refs: PokemonSpeciesRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
    dexContent: PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'A strange seed was planted on its back at birth.',
    ),
    gameplayFlags: PokemonSpeciesGameplayFlags(
      starterEligible: true,
    ),
    sourceMeta: PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}

PokemonLearnsetFile _bulbasaurLearnset() {
  return const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle', 'growl'],
    relearnMoves: <String>['tackle', 'growl', 'vine_whip'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'tackle',
        level: 1,
        source: 'level_up',
        versionGroup: 'demo',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level_up',
        versionGroup: 'demo',
      ),
    ],
    tm: <PokemonLearnsetMoveEntry>[
      PokemonLearnsetMoveEntry(
        moveId: 'growl',
        versionGroup: 'demo',
      ),
    ],
  );
}

PokemonEvolutionFile _bulbasaurEvolution() {
  return const PokemonEvolutionFile(
    speciesId: 'bulbasaur',
    preEvolution: null,
    evolutions: <PokemonEvolutionEntry>[
      PokemonEvolutionEntry(
        targetSpeciesId: 'ivysaur',
        method: 'level_up',
        minLevel: 16,
        conditionText: <String, String>{
          'en': 'Evolves at level 16',
        },
      ),
    ],
  );
}

PokemonMediaFile _bulbasaurMedia() {
  return const PokemonMediaFile(
    speciesId: 'bulbasaur',
    defaultFormId: 'base',
    variants: <String, PokemonMediaVariant>{
      'base': PokemonMediaVariant(
        frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
        backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
        icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
        party: 'assets/pokemon/sprites/bulbasaur/party.png',
        overworld: 'assets/pokemon/sprites/bulbasaur/overworld.png',
        portrait: 'assets/pokemon/portraits/bulbasaur.png',
        cry: 'assets/pokemon/cries/bulbasaur.ogg',
        animations: <String, PokemonMediaAnimationRef>{
          'battleFront': PokemonMediaAnimationRef(
            sheet: 'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
            animationId: 'battle_front',
          ),
        },
      ),
    },
  );
}

PokemonCatalogFile _movesCatalog() {
  return const PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>['Write repository integration test data.'],
    ),
    entries: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'tackle',
        'name': 'Tackle',
        'names': <String, String>{'en': 'Tackle', 'fr': 'Charge'},
        'type': 'normal',
        'category': 'physical',
        'power': 40,
        'accuracy': 100,
        'pp': 35,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'A physical attack in which the user charges and slams.',
        'generation': 1,
      },
      <String, dynamic>{
        'id': 'growl',
        'name': 'Growl',
        'names': <String, String>{'en': 'Growl', 'fr': 'Rugissement'},
        'type': 'normal',
        'category': 'status',
        'power': null,
        'accuracy': 100,
        'pp': 40,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'Lowers the target Attack by one stage.',
        'generation': 1,
      },
    ],
  );
}
