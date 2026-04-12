import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/ports/pokemon_write_repository.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late ImportExternalPokemonSpeciesUseCase singleUseCase;
  late BatchImportExternalPokemonSpeciesUseCase batchUseCase;
  late _FakePokemonExternalSourceRepository externalSourceRepository;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_external_import_project_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    externalSourceRepository = _FakePokemonExternalSourceRepository(
      showdownSpeciesPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurShowdownPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonSpeciesPayloads: <String, Map<String, dynamic>>{
        '1':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        '2': jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurPokemonPayload) as Map<String, dynamic>,
      },
      pokeApiEvolutionChainPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
      },
      binaryAssets: <String, PokemonExternalBinaryAsset>{
        'https://assets.example.test/bulbasaur/portrait.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front.png',
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back.png',
          bytes: Uint8List.fromList(<int>[9, 10, 11, 12]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front_shiny.png',
          bytes: Uint8List.fromList(<int>[13, 14, 15, 16]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back_shiny.png',
          bytes: Uint8List.fromList(<int>[17, 18, 19, 20]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/cry.ogg':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
          bytes: Uint8List.fromList(<int>[21, 22, 23, 24]),
          contentType: 'audio/ogg',
        ),
      },
    );
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
    singleUseCase = ImportExternalPokemonSpeciesUseCase(
      externalSourceRepository: externalSourceRepository,
      writeRepository: writeRepository,
    );
    batchUseCase = BatchImportExternalPokemonSpeciesUseCase(singleUseCase);

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon External Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ImportExternalPokemonSpeciesUseCase', () {
    test('imports one species from external payloads into local storage',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(workspace, speciesId: '1');

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(result.preview.primaryName, 'Bulbasaur');
      expect(result.preview.cries.isAvailable, isTrue);
      expect(result.downloadedAssetCount, 6);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.progression.growthRateId, 'medium_slow');
      expect(species.progression.baseFriendship, 50);
      expect(species.dexContent.color, 'green');
      expect(species.dexContent.flavorText,
          'A strange seed was planted on its back at birth.');
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isTrue,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves everything but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(result.downloadedAssetCount, 0);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
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
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fail_on_conflict reports conflicts and writes nothing', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'fail_on_conflict stays atomic even when only one artefact already exists',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // On provoque ici le cas le plus intéressant du point de vue produit :
      // un conflit partiel. Si l'atomicité promise par le use case casse,
      // l'import pourrait écrire learnset/evolution/media alors que l'espèce
      // principale est en conflit, ce qui rendrait le résultat trompeur.
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.species,
            )
            .action,
        PokemonExternalImportArtifactAction.conflict,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing skips files already present and still writes missing ones',
        () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        dryRun: true,
      );
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.skip,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('overwrite_existing replaces an existing artefact', () async {
      await writeRepository.saveLearnset(
        workspace,
        const PokeApiPokemonLearnsetConverter().convert(
          speciesId: 'bulbasaur',
          payload: jsonDecode(_legacyBulbasaurPokemonPayload)
              as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.learnset,
            )
            .action,
        PokemonExternalImportArtifactAction.overwrite,
      );
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing reuses an existing non-canonical species path '
        'without creating a duplicate canonical file', () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing ignores a misleading basename with another json id',
        () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _customSlugBulbasaurSpecies.toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(await misleadingFile.exists(), isTrue);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('surfaces external source errors clearly', () async {
      externalSourceRepository.pokeApiPokemonSpeciesPayloads
          .remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon-species payload not found for species "bulbasaur"',
          ),
        ),
      );
    });

    test('continues when optional pokemon payload is unavailable', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.hasConflicts, isFalse);
      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isFalse);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);
      expect(result.preview.learnset.isAvailable, isFalse);
      expect(result.preview.media.isAvailable, isFalse);
      expect(result.preview.cries.isAvailable, isFalse);
      expect(
        result.warnings.join('\n'),
        contains('Learnset and media payload unavailable for "bulbasaur"'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test(
        'omits a missing media asset ref from media.json while keeping the rest coherent',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(baseVariant.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('Portrait download failed'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'keeps species learnset and evolution when all media downloads fail and writes no ghost refs',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets.clear();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.downloadedAssetCount, 0);
      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic, isNull);
      expect(baseVariant.backStatic, isNull);
      expect(baseVariant.frontShinyStatic, isNull);
      expect(baseVariant.backShinyStatic, isNull);
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.cry, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(result.warnings.join('\n'), contains('download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing does not download new assets when media.json is already skipped',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // Ce cas verrouille précisément le coin restant du mini-fix 2 :
      // - `media.json` existe déjà, donc l'artefact media doit être `skip` ;
      // - aucun asset local n'existe encore ;
      // - si le pipeline continue malgré tout à télécharger les binaires,
      //   ils deviennent orphelins parce que le `media.json` conservé ne sera
      //   jamais réécrit dans ce run.
      //
      // On prépare donc volontairement un `media.json` minimal qui ne référence
      // aucun asset. Si l'import écrit ensuite des portraits/sprites/cries alors
      // que le JSON média est skippé, le bug est réel et reproductible.
      await writeRepository.saveMedia(
        workspace,
        const PokemonMediaFile(
          speciesId: 'bulbasaur',
          defaultFormId: 'base',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(),
          },
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.media,
            )
            .action,
        PokemonExternalImportArtifactAction.skip,
      );
      expect(result.downloadedAssetCount, 0);
      expect(result.downloadedAssets, isEmpty);
      expect(media.variants['base']?.portrait, isNull);
      expect(media.variants['base']?.frontStatic, isNull);
      expect(media.variants['base']?.backStatic, isNull);
      expect(media.variants['base']?.cry, isNull);
      expect(
        result.warnings.join('\n'),
        contains('media.json'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing keeps a pre-existing local asset ref without re-downloading it',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[200, 201, 202]);

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final portraitResult = result.downloadedAssets.firstWhere(
        (asset) => asset.label == 'Portrait',
      );

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[200, 201, 202]);
      expect(portraitResult.wasWritten, isFalse);
      expect(portraitResult.existedBefore, isTrue);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps an existing local asset ref when redownload fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[77, 88, 99]);
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[77, 88, 99]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible image content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[9, 9, 9, 9]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps a local image when redownload content-type is incompatible',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[17, 18, 19]);
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[17, 18, 19]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible cry content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository
              .binaryAssets['https://assets.example.test/bulbasaur/cry.ogg'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
        bytes: Uint8List.fromList(<int>[4, 4, 4, 4]),
        contentType: 'audio/mpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (audio/mpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('refuses GIF assets without persisting a ghost media ref', () async {
      final beforeProjectJson = await projectFile.readAsString();
      final payload =
          jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>;
      final sprites = payload['sprites'] as Map<String, dynamic>;
      final other = sprites['other'] as Map<String, dynamic>;
      final officialArtwork = other['official-artwork'] as Map<String, dynamic>;
      officialArtwork['front_default'] =
          'https://assets.example.test/bulbasaur/portrait.gif';
      externalSourceRepository.pokeApiPokemonPayloads['bulbasaur'] = payload;

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('GIF assets are explicitly excluded'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('applies the same no-ghost rule to cries', () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/cry.ogg');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(result.warnings.join('\n'), contains('Cri download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('cleans up newly written media assets if media.json persistence fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final useCase = ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalSourceRepository,
        writeRepository: _ThrowingMediaWriteRepository(
          delegate: writeRepository,
        ),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Simulated media write failure'),
          ),
        ),
      );

      // Ce test verrouille un invariant subtil de clôture 11A :
      // si le `media.json` final ne peut pas être écrit, on ne doit pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun JSON local.
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );

      // Le mini-fix ne touche pas à `project.json`. On le reverrouille ici
      // même sur un échec tardif du pipeline.
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects a headerless incompatible image payload without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        // Signature JPEG volontairement incompatible.
        bytes: Uint8List.fromList(
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46],
        ),
        contentType: null,
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('missing or incompatible content-type'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });
  });

  group('BatchImportExternalPokemonSpeciesUseCase', () {
    test('imports a batch successfully with deterministic ordering', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur', 'ivysaur'],
      );

      expect(
        result.entries.map((entry) => entry.speciesId).toList(),
        <String>['bulbasaur', 'ivysaur'],
      );
      expect(result.successfulCount, 2);
      expect(result.failedCount, 0);
      expect(result.conflictCount, 0);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves a batch but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur'],
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.successfulCount, 2);
      expect(
        result.entries.every(
          (entry) =>
              entry.result != null && entry.result!.hasWritesApplied == false,
        ),
        isTrue,
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
            'data/pokemon/species/0002-ivysaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('reports honest per-species progress during a real batch', () async {
      final progressSnapshots = <PokemonExternalBatchImportProgress>[];

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur'],
        onProgress: progressSnapshots.add,
      );

      expect(result.successfulCount, 2);
      expect(
        progressSnapshots
            .map(
              (progress) => (
                progress.completedCount,
                progress.successfulCount,
                progress.failedCount,
                progress.lastCompletedSpeciesId,
              ),
            )
            .toList(),
        <(int, int, int, String)>[
          (1, 1, 0, 'bulbasaur'),
          (2, 2, 0, 'ivysaur'),
        ],
      );
      expect(
        progressSnapshots.every((progress) => progress.totalCount == 2),
        isTrue,
      );
    });

    test('reports skipped entries when merge policy is skipExisting', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(result.successfulCount, 1);
      expect(result.skippedCount, 1);
      expect(result.conflictCount, 0);
      expect(result.failedCount, 0);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'bulbasaur')
            .isSkipped,
        isTrue,
      );
    });

    test('reports conflicts when merge policy is failOnConflict', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.successfulCount, 1);
      expect(result.skippedCount, 0);
      expect(result.conflictCount, 1);
      expect(result.failedCount, 0);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'bulbasaur')
            .isConflict,
        isTrue,
      );
    });

    test('continues on partial failures and reports them by species', () async {
      externalSourceRepository.showdownSpeciesPayloads.remove('ivysaur');

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
      );

      expect(result.successfulCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'ivysaur')
            .errorMessage,
        'External Showdown species payload not found for species "ivysaur"',
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    required this.showdownSpeciesPayloads,
    required this.pokeApiPokemonSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
    required this.binaryAssets,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;
  final Map<String, PokemonExternalBinaryAsset> binaryAssets;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    return showdownSpeciesPayloads.map(
      (key, value) => MapEntry<String, dynamic>(key, _deepCopy(value)),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) async {
    final payload = pokeApiEvolutionChainPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI evolution chain payload not found for species '
        '"$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) async {
    final payload = showdownSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final asset = binaryAssets[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('External asset not found: $sourceUrl');
    }
    return PokemonExternalBinaryAsset(
      sourceUrl: asset.sourceUrl,
      bytes: Uint8List.fromList(asset.bytes),
      contentType: asset.contentType,
    );
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

/// Repository décorateur volontairement minuscule pour reproduire un échec
/// tardif sur `saveMedia`.
///
/// Ce fake sert uniquement à prouver un invariant de clôture 11A :
/// si l'écriture finale du `media.json` casse, le pipeline ne doit pas laisser
/// d'assets binaires nouvellement créés sans référence locale persistée.
///
/// Non-objectifs explicites :
/// - ne pas changer la sémantique des autres écritures ;
/// - ne pas simuler un filesystem complet ;
/// - ne pas introduire une nouvelle abstraction de prod.
class _ThrowingMediaWriteRepository implements PokemonWriteRepository {
  const _ThrowingMediaWriteRepository({
    required this.delegate,
  });

  final PokemonWriteRepository delegate;

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) {
    return delegate.saveBinaryAsset(
      workspace,
      relativePath: relativePath,
      bytes: bytes,
    );
  }

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) {
    return delegate.saveCatalogByKey(workspace, catalogKey, catalog);
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return delegate.saveEvolution(workspace, evolution);
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return delegate.saveLearnset(workspace, learnset);
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) {
    throw const EditorPersistenceException(
      'Simulated media write failure',
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) {
    return delegate.saveSpecies(workspace, species);
  }
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 0.7,
  "weightkg": 6.9
}
''';

const String _bulbasaurPokemonSpeciesPayload = '''
{
  "name": "bulbasaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Bulbasaur"},
    {"language": {"name": "fr"}, "name": "Bulbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "A strange seed was planted on its back at birth."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurPokemonSpeciesPayload = '''
{
  "name": "ivysaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Ivysaur"},
    {"language": {"name": "fr"}, "name": "Herbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "When the bulb on its back grows large, it appears to lose the ability to stand."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurShowdownPayload = '''
{
  "name": "Ivysaur",
  "num": 2,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 60,
    "atk": 62,
    "def": 63,
    "spa": 80,
    "spd": 80,
    "spe": 60
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 142,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 1.0,
  "weightkg": 13.0
}
''';

const PokemonSpeciesFile _customSlugBulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbizarre-custom',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur Custom'},
  speciesName: <String, String>{},
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
    flavorText: 'Custom slug seed for overwrite proof.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const String _bulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "base_experience": 64,
  "height": 7,
  "weight": 69,
  "sprites": {
    "front_default": "https://assets.example.test/bulbasaur/front.png",
    "back_default": "https://assets.example.test/bulbasaur/back.png",
    "front_shiny": "https://assets.example.test/bulbasaur/front_shiny.png",
    "back_shiny": "https://assets.example.test/bulbasaur/back_shiny.png",
    "other": {
      "official-artwork": {
        "front_default": "https://assets.example.test/bulbasaur/portrait.png"
      }
    }
  },
  "cries": {
    "latest": "https://assets.example.test/bulbasaur/cry.ogg"
  },
  "moves": [
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _legacyBulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _ivysaurPokemonPayload = '''
{
  "name": "ivysaur",
  "base_experience": 142,
  "height": 10,
  "weight": 130,
  "sprites": {
    "front_default": null,
    "back_default": null,
    "front_shiny": null,
    "back_shiny": null,
    "other": {
      "official-artwork": {
        "front_default": null
      }
    }
  },
  "cries": {
    "latest": null
  },
  "moves": [
    {
      "move": {"name": "razor-leaf"},
      "version_group_details": [
        {
          "level_learned_at": 20,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "known_move": {"name": "solar-beam"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';
