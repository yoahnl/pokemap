import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_evolution_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_json_bundle_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_learnset_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_media_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_species_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late ImportPokemonJsonBundleUseCase useCase;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_bundle_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_bundle_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();

    const writeRepository = FilePokemonWriteRepository();
    useCase = const ImportPokemonJsonBundleUseCase(
      writeRepository: writeRepository,
      speciesImportUseCase: ImportPokemonSpeciesJsonUseCase(writeRepository),
      learnsetImportUseCase: ImportPokemonLearnsetJsonUseCase(writeRepository),
      evolutionImportUseCase:
          ImportPokemonEvolutionJsonUseCase(writeRepository),
      mediaImportUseCase: ImportPokemonMediaJsonUseCase(writeRepository),
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Bundle Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
    if (await tempImportRoot.exists()) {
      await tempImportRoot.delete(recursive: true);
    }
  });

  group('ImportPokemonJsonBundleUseCase', () {
    test('preview detects sibling artifacts and preserves type order',
        () async {
      final sourcePaths = await _writeValidBundle(tempImportRoot);

      final preview = await useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: sourcePaths.species.path,
      );

      expect(preview.speciesId, 'bulbasaur');
      expect(preview.nationalDex, 1);
      expect(preview.primaryName, 'Bulbasaur');
      expect(preview.types, <String>['grass', 'poison']);
      expect(preview.learnset.status, PokemonImportPreviewStatus.found);
      expect(preview.evolution.status, PokemonImportPreviewStatus.found);
      expect(preview.media.status, PokemonImportPreviewStatus.found);
      expect(preview.learnset.absoluteSourcePath, sourcePaths.learnset.path);
      expect(preview.evolution.absoluteSourcePath, sourcePaths.evolution.path);
      expect(preview.media.absoluteSourcePath, sourcePaths.media.path);
    });

    test(
        'execute imports species and detected companions without touching project.json',
        () async {
      final sourcePaths = await _writeValidBundle(tempImportRoot);
      final beforeProjectJson = await projectFile.readAsString();

      final result = await useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: sourcePaths.species.path,
      );

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.startingMoves, <String>['tackle', 'growl']);
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'execute leaves project data untouched when a detected companion is invalid',
        () async {
      final sourcePaths = await _writeValidBundle(tempImportRoot);
      await sourcePaths.learnset.writeAsString('{"speciesId": ""}');
      final beforeProjectJson = await projectFile.readAsString();

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSpeciesSourcePath: sourcePaths.species.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon learnset speciesId cannot be empty',
          ),
        ),
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });
  });
}

class _BundleSourcePaths {
  const _BundleSourcePaths({
    required this.species,
    required this.learnset,
    required this.evolution,
    required this.media,
  });

  final File species;
  final File learnset;
  final File evolution;
  final File media;
}

Future<_BundleSourcePaths> _writeValidBundle(Directory root) async {
  final speciesFile = await _writeJson(
    root,
    p.join('species', 'bulbasaur.json'),
    _bulbasaurSpecies.toJson(),
  );
  final learnsetFile = await _writeJson(
    root,
    p.join('learnsets', 'bulbasaur.json'),
    _bulbasaurLearnset.toJson(),
  );
  final evolutionFile = await _writeJson(
    root,
    p.join('evolutions', 'bulbasaur.json'),
    _bulbasaurEvolution.toJson(),
  );
  final mediaFile = await _writeJson(
    root,
    p.join('media', 'bulbasaur.json'),
    _bulbasaurMedia.toJson(),
  );
  return _BundleSourcePaths(
    species: speciesFile,
    learnset: learnsetFile,
    evolution: evolutionFile,
    media: mediaFile,
  );
}

Future<File> _writeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  return file;
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
  speciesName: <String, String>{'fr': 'Pokémon Graine', 'en': 'Seed Pokemon'},
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
  forms: PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
  ),
  classification: PokemonSpeciesClassification(
    isEnabledInProject: true,
    isObtainable: true,
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
    flavorText: 'Une étrange graine a été plantée sur son dos à la naissance.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(
    starterEligible: true,
    giftOnly: false,
    tradeOnly: false,
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'bundle-test',
    seedVersion: 1,
  ),
);

const PokemonLearnsetFile _bulbasaurLearnset = PokemonLearnsetFile(
  speciesId: 'bulbasaur',
  startingMoves: <String>['tackle', 'growl'],
  relearnMoves: <String>['vine_whip'],
  levelUp: <PokemonLearnsetLevelUpEntry>[
    PokemonLearnsetLevelUpEntry(
      moveId: 'vine_whip',
      level: 7,
      source: 'level_up',
      versionGroup: 'scarlet-violet',
    ),
  ],
);

const PokemonEvolutionFile _bulbasaurEvolution = PokemonEvolutionFile(
  speciesId: 'bulbasaur',
  evolutions: <PokemonEvolutionEntry>[
    PokemonEvolutionEntry(
      targetSpeciesId: 'ivysaur',
      method: 'level_up',
      minLevel: 16,
      conditionText: <String, String>{
        'fr': 'Évolue au niveau 16',
        'en': 'Evolves at level 16',
      },
    ),
  ],
);

const PokemonMediaFile _bulbasaurMedia = PokemonMediaFile(
  speciesId: 'bulbasaur',
  defaultFormId: 'base',
  variants: <String, PokemonMediaVariant>{
    'base': PokemonMediaVariant(
      frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
      backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
      icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
      party: 'assets/pokemon/sprites/bulbasaur/party.png',
      portrait: 'assets/pokemon/portraits/bulbasaur.png',
      cry: 'assets/pokemon/cries/bulbasaur.ogg',
    ),
  },
);
