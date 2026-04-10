# Pokédex Phase 6 / Lot 23 — Mini-fix de robustesse

## 1. Résumé exécutif honnête

Le lot 23 était déjà globalement bon sur son objectif principal :
- import unitaire d’une espèce depuis un JSON interne ;
- parsing vers `PokemonSpeciesFile` ;
- validation minimale ;
- sauvegarde via `PokemonWriteRepository.saveSpecies(...)`.

Le mini-fix appliqué ici est volontairement petit et strict :
- durcissement de la validation structurelle minimale ;
- ajout des tests ciblés manquants ;
- aucun élargissement vers l’UI, les lots suivants, le runtime, les providers, `project.json`, les repositories ou les imports annexes.

Les défauts corrigés :
- `genIntroduced <= 0` n’était pas refusé explicitement ;
- `refs.learnset`, `refs.evolution` et `refs.media` pouvaient encore être vides ou blancs ;
- le cas `absoluteSourcePath` vide n’était pas testé explicitement.

Ce qui a été laissé intact volontairement :
- la forme générale du use case ;
- le parsing JSON ;
- la sauvegarde via le repository existant ;
- toute logique de lot suivant ;
- toute validation croisée plus riche.

## 2. Objectif exact du mini-fix

Rendre le lot 23 plus strict sur les espèces structurellement inexploitables pour le pipeline Pokédex actuel, sans transformer ce use case en framework d’import.

En pratique :
- lecture du fichier source ;
- décodage JSON ;
- parsing ;
- validation structurelle minimale durcie ;
- sauvegarde via le repository d’écriture existant.

## 3. Défauts corrigés exactement

### Validation durcie

Ajout de refus explicites pour :
- `genIntroduced <= 0`
- `refs.learnset` vide ou blanc
- `refs.evolution` vide ou blanc
- `refs.media` vide ou blanc

### Couverture de tests complétée

Ajout de tests explicites pour :
- chemin source vide
- `genIntroduced <= 0`
- `refs.learnset` vide
- `refs.evolution` vide
- `refs.media` vide

## 4. Périmètre inclus

- `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`
- `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`
- `reports/pokedex-phase-6-lot-23-mini-fix-report.md`

## 5. Périmètre exclu

- UI
- runtime
- providers
- `project.json`
- repositories
- imports learnset/evolution/media
- merge policy
- batch import
- tout lot suivant
- tout nettoyage hors scope

## 6. Liste exacte des fichiers modifiés

Modifiés :
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`
- `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`

Créé :
- `reports/pokedex-phase-6-lot-23-mini-fix-report.md`

## 7. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`

Pourquoi touché :
- c’est le point exact où vit la validation structurelle minimale du lot 23.

Ce qui a changé :
- ajout d’une validation explicite sur `genIntroduced` ;
- ajout d’une validation explicite sur `refs.learnset` ;
- ajout d’une validation explicite sur `refs.evolution` ;
- ajout d’une validation explicite sur `refs.media` ;
- ajout de commentaires de review pour expliquer pourquoi ces validations sont légitimes dans ce lot, tout en restant locales et non spéculatives.

Pourquoi c’est le plus petit changement raisonnable :
- aucune nouvelle abstraction ;
- aucune modification de flux ;
- aucune modification du contrat du use case ;
- aucun changement de repository.

### `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`

Pourquoi touché :
- pour verrouiller exactement les cas manquants demandés.

Ce qui a changé :
- ajout d’un test sur chemin vide ;
- ajout d’un test sur `genIntroduced <= 0` ;
- ajout d’un test sur `refs.learnset` vide ;
- ajout d’un test sur `refs.evolution` vide ;
- ajout d’un test sur `refs.media` vide.

Pourquoi c’est le plus petit changement raisonnable :
- on complète la suite de tests existante ;
- on ne crée pas de nouveau harness ;
- on ne touche pas à d’autres couches.

### `reports/pokedex-phase-6-lot-23-mini-fix-report.md`

Pourquoi créé :
- pour documenter précisément ce mini-fix avec les résultats réels et le contenu complet des fichiers touchés.

## 8. Commandes réellement exécutées

```bash
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_species_json_use_case.dart test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '1,420p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
sed -n '421,520p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
```

## 9. Résultats réels des commandes

### `dart format ...`

```text
Formatted 2 files (0 changed) in 0.02 seconds.
```

### `flutter test test/import_pokemon_species_json_use_case_test.dart`

```text
00:03 +14: All tests passed!
```

### `flutter analyze --no-pub ...`

```text
Analyzing 2 items...
No issues found! (ran in 2.4s)
```

### `git status --short -- ...`

```text
 M packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
 M packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
```

### `git diff --stat -- ...`

```text
 .../import_pokemon_species_json_use_case.dart      |  34 ++++++
 .../import_pokemon_species_json_use_case_test.dart | 123 +++++++++++++++++++++
 2 files changed, 157 insertions(+)
```

## 10. État Git utile

Constat utile :
- seuls les deux fichiers de code du lot 23 apparaissent modifiés dans le diff ciblé ;
- ce mini-fix n’a pas touché d’autres zones du repo ;
- aucune commande Git d’écriture n’a été exécutée.

## 11. Limites restantes

Ce mini-fix ne fait volontairement pas plus que demandé :
- il ne vérifie pas l’existence réelle des fichiers learnset/evolution/media ;
- il ne fait pas de validation croisée avec les catalogues ;
- il ne change pas la stratégie d’erreur globale du projet ;
- il ne crée pas d’UI d’import ;
- il ne traite aucun lot suivant.

Ces points sont hors scope ici.

## 12. Contenu complet de tous les fichiers touchés

### 12.1 `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`

```dart
import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe une espèce Pokémon déjà au format JSON interne du projet.
///
/// Le contrat reste volontairement petit pour le lot 23 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonSpeciesFile] ;
/// - on valide seulement les champs structurels indispensables avant écriture ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// On n'introduit ici :
/// - ni merge policy avancée ;
/// - ni import learnset/évolution/média ;
/// - ni orchestration batch ;
/// - ni logique UI.
class ImportPokemonSpeciesJsonUseCase {
  const ImportPokemonSpeciesJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon species source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon species import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final species = _parseSpecies(decoded);
    _validateSpecies(species);

    await writeRepository.saveSpecies(workspace, species);
    return species;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon species JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon species JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonSpeciesFile _parseSpecies(Map<String, dynamic> decoded) {
    try {
      return PokemonSpeciesFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon species JSON structure is invalid: $error',
      );
    }
  }

  void _validateSpecies(PokemonSpeciesFile species) {
    // On reste volontairement sur une validation structurelle minimale.
    // Le but de ce lot n'est pas de reconstruire tout le validateur Pokédex,
    // mais de refuser immédiatement les espèces qui ne peuvent pas alimenter
    // le pipeline actuel de manière sûre et prévisible.
    //
    // Les contrôles catalogue/références croisées plus riches vivent déjà dans
    // le validateur projet dédié et ne doivent pas être dupliqués ici.
    if (species.id.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }
    if (species.slug.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species slug cannot be empty',
      );
    }
    if (species.nationalDex <= 0) {
      throw const EditorValidationException(
        'Pokemon species nationalDex must be positive',
      );
    }
    // Le pipeline Pokédex courant s'appuie déjà sur la génération introduite
    // pour les filtres et la présentation. Une valeur nulle ou négative rend
    // l'entrée structurellement inutilisable dès l'import.
    if (species.genIntroduced <= 0) {
      throw const EditorValidationException(
        'Pokemon species genIntroduced must be positive',
      );
    }
    final hasName =
        species.names.values.any((value) => value.trim().isNotEmpty);
    if (!hasName) {
      throw const EditorValidationException(
        'Pokemon species names cannot be empty',
      );
    }
    final typeIds =
        species.typing.types.where((value) => value.trim().isNotEmpty);
    if (typeIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species must declare at least one type',
      );
    }

    // Contrairement au chargement tolérant des annexes dans la vue détail,
    // ce lot d'import doit refuser une espèce "orpheline" dès l'entrée.
    // Les trois refs sont obligatoires ici parce que le pipeline Pokédex
    // actuel attend une espèce directement raccordable à ses fichiers annexes.
    // On reste volontairement local : on vérifie seulement que les refs
    // existent textuellement, sans ouvrir le chantier de validation croisée.
    if (species.refs.learnset.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.learnset cannot be empty',
      );
    }
    if (species.refs.evolution.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.evolution cannot be empty',
      );
    }
    if (species.refs.media.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species refs.media cannot be empty',
      );
    }
  }
}
```

### 12.2 `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_species_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonSpeciesJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_species_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonSpeciesJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Species Import Project',
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

  group('ImportPokemonSpeciesJsonUseCase', () {
    test('fails clearly when the source path is empty', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: '   ',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species source path cannot be empty',
          ),
        ),
      );
    });

    test('imports one internal species json into the local species directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurSpecies.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.id, 'bulbasaur');
      expect(imported.nationalDex, 1);

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.typing.types, <String>['grass', 'poison']);
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fails clearly when the source file does not exist', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: '${tempImportRoot.path}/missing.json',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species source file not found',
          ),
        ),
      );
    });

    test('fails clearly when the source file is not a json file', () async {
      final sourceFile = File('${tempImportRoot.path}/bulbasaur.txt');
      await sourceFile.writeAsString('not a json import');

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species import expects a .json file',
          ),
        ),
      );
    });

    test('fails clearly when the source json is syntactically invalid',
        () async {
      final sourceFile = File('${tempImportRoot.path}/broken.json');
      await sourceFile.writeAsString('{ this is not valid json');

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species JSON is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the source json root is not an object', () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'array.json',
        <Object?>['not', 'an', 'object'],
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Pokemon species JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['names'] = <Object?>['not', 'a', 'map'];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'wrong-types.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed species is structurally invalid',
        () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['id'] = '   '
        ..['slug'] = '';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-species.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species id cannot be empty',
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
    });

    test('fails clearly when the species has no usable names', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['names'] = <String, String>{'fr': '   ', 'en': ''};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'nameless.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species names cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when genIntroduced is not positive', () async {
      final brokenJson = _bulbasaurSpecies.toJson()..['genIntroduced'] = 0;
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'invalid-generation.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species genIntroduced must be positive',
          ),
        ),
      );
    });

    test('fails clearly when the species has no type declared', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['typing'] = <String, Object?>{'types': <String>[]};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'typeless.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species must declare at least one type',
          ),
        ),
      );
    });

    test('fails clearly when refs.learnset is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': '   ',
          'evolution': 'bulbasaur',
          'media': 'bulbasaur',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-learnset-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.learnset cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when refs.evolution is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': 'bulbasaur',
          'evolution': '',
          'media': 'bulbasaur',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-evolution-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.evolution cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when refs.media is empty', () async {
      final brokenJson = _bulbasaurSpecies.toJson()
        ..['refs'] = <String, Object?>{
          'learnset': 'bulbasaur',
          'evolution': 'bulbasaur',
          'media': ' ',
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-media-ref.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon species refs.media cannot be empty',
          ),
        ),
      );
    });
  });
}

Future<File> _writeSourceJson(
  Directory importRoot,
  String fileName,
  Object payload,
) async {
  final file = File('${importRoot.path}/$fileName');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
  return file;
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{
    'fr': 'Bulbizarre',
    'en': 'Bulbasaur',
  },
  speciesName: <String, String>{
    'fr': 'Pokemon Graine',
    'en': 'Seed Pokemon',
  },
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
```

### 12.3 `reports/pokedex-phase-6-lot-23-mini-fix-report.md`

Le contenu complet de ce fichier est, par définition, le document que tu es en train de lire. Je n’ai touché aucun autre fichier de rapport dans ce mini-fix.

## 13. Checklist d’autocontrôle finale

- [x] J’ai gardé un scope strictement limité au mini-fix du lot 23
- [x] Je n’ai pas commencé un lot suivant
- [x] Je n’ai touché ni à l’UI, ni au runtime, ni à la sauvegarde, ni à `project.json`
- [x] J’ai ajouté la validation sur `genIntroduced`
- [x] J’ai ajouté la validation sur `refs.learnset`
- [x] J’ai ajouté la validation sur `refs.evolution`
- [x] J’ai ajouté la validation sur `refs.media`
- [x] J’ai ajouté un test sur chemin vide
- [x] J’ai ajouté un test sur `genIntroduced <= 0`
- [x] J’ai ajouté un test sur ref learnset vide
- [x] J’ai ajouté un test sur ref evolution vide
- [x] J’ai ajouté un test sur ref media vide
- [x] Je n’ai pas introduit de nouvelle abstraction spéculative
- [x] Je n’ai exécuté aucune commande Git d’écriture
- [x] J’ai inclus dans le rapport le contenu complet de tous les fichiers touchés

