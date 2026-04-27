# Pokédex Phase 6 — Lot 23 Report

## Résumé exécutif

Hypothèse retenue :
- `lot 6` = **Phase 6 / Lot 23** du plan Pokédex, c’est-à-dire l’**import manuel d’une espèce depuis un JSON interne**.

Ce lot est maintenant implémenté dans un périmètre strict :
- import unitaire d’un fichier JSON espèce déjà au format interne ;
- validation structurelle minimale avant écriture ;
- écriture dans `data/pokemon/species/` via le repository local existant ;
- aucun changement UI ;
- aucun import learnset, évolution ou média ;
- aucun batch ;
- aucune merge policy ;
- aucun impact sur `project.json`.

Le point de robustesse principal ajouté pendant l’implémentation :
- les JSON syntaxiquement valides mais structurellement mal typés remontent maintenant une erreur claire et stable, au lieu de laisser fuiter une exception de cast/type plus basse couche.

## Périmètre exact

Inclus :
- lecture d’un fichier source `.json` déjà au format interne ;
- parsing en `PokemonSpeciesFile` ;
- validation structurelle minimale ;
- sauvegarde locale via `PokemonWriteRepository.saveSpecies(...)`.

Exclus volontairement :
- UI d’import ;
- learnsets ;
- évolutions ;
- médias ;
- catalogues ;
- batch import ;
- dry-run ;
- merge policy ;
- toute logique de lots suivants.

## Design retenu

Le lot ajoute un use case très petit :
- `ImportPokemonSpeciesJsonUseCase`

Contrat retenu :
- entrée : `ProjectWorkspace` + `absoluteSourcePath`
- sortie : `PokemonSpeciesFile` importé

Comportement :
1. vérifier que le chemin n’est pas vide ;
2. vérifier que le fichier existe ;
3. vérifier l’extension `.json` ;
4. lire le texte ;
5. décoder le JSON ;
6. refuser une racine non objet ;
7. parser vers `PokemonSpeciesFile` ;
8. transformer les erreurs de structure/type en `EditorPersistenceException` lisible ;
9. appliquer une validation structurelle minimale ;
10. sauvegarder via le repository d’écriture existant.

Pourquoi ce design est le plus petit changement raisonnable :
- il réutilise la frontière de persistance déjà en place ;
- il n’introduit ni nouveau service global, ni nouveau provider, ni nouveau repository ;
- il ne duplique pas la logique d’écriture de fichiers ;
- il reste conforme au critère du lot : **un import unitaire interne, avec validation et erreurs claires**.

## Fichiers modifiés

Modifiés :
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Créés :
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`
- `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`
- `reports/pokedex-phase-6-lot-23-report.md`

Non touchés volontairement :
- tout le reste du workspace ;
- toute la UI Pokédex ;
- tout `project.json` ;
- toute la couche d’import externe.

## Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`

Pourquoi :
- c’est la brique applicative exacte du lot 23.

Ce qui a été fait :
- ajout du use case d’import unitaire ;
- ajout d’une validation minimale locale ;
- ajout d’un wrapping propre des erreurs JSON et des erreurs de structure.

Pourquoi c’est minimal :
- un seul point d’entrée ;
- aucune dépendance nouvelle hors boundaries existantes ;
- aucune logique UI.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Pourquoi :
- pour exposer le nouveau use case au même niveau que les autres use cases applicatifs.

Ce qui a été fait :
- un simple export supplémentaire.

Pourquoi c’est minimal :
- 1 ligne utile ;
- pas de refactor du fichier.

### `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`

Pourquoi :
- verrouiller précisément les critères d’acceptation du lot.

Ce qui a été fait :
- test heureux d’import ;
- tests d’erreurs claires :
  - fichier absent ;
  - mauvaise extension ;
  - JSON invalide ;
  - racine non objet ;
  - structure mal typée ;
  - espèce structurellement invalide ;
  - noms vides ;
  - types absents.

Pourquoi c’est minimal :
- tests ciblés sur le use case ;
- pas de sur-couverture UI ;
- pas de snapshot inutile.

## Commandes réellement exécutées

```bash
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
sed -n '261,520p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
sed -n '1,120p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_species_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_species_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports/pokedex-phase-6-lot-23-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports/pokedex-phase-6-lot-23-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart packages/map_editor/test/import_pokemon_species_json_use_case_test.dart reports/pokedex-phase-6-lot-23-report.md
```

## Résultats réels

### `dart format`

```text
Formatted 3 files (0 changed) in 0.02 seconds.
```

### `flutter test test/import_pokemon_species_json_use_case_test.dart`

```text
00:01 +9: All tests passed!
```

### `flutter analyze --no-pub ...`

```text
No issues found! (ran in 2.1s)
```

### `git status --short -- ...`

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
?? packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
```

Remarque :
- le rapport lui-même est un nouveau fichier non suivi ; il n’apparaissait pas encore dans cette première capture car la commande a été exécutée avant la création du rapport.

### `git diff --stat -- ...`

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 2 ++
 1 file changed, 2 insertions(+)
```

Remarque :
- `git diff --stat` ne montre ici que le fichier déjà suivi ;
- les nouveaux fichiers du lot sont encore `untracked`, donc absents de cette sortie.

### `git ls-files --others --exclude-standard ...`

```text
packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
```

Remarque :
- cette commande a aussi été exécutée avant la création du rapport lui-même.

## Relecture parallèle

Une relecture ciblée par sous-agent a bien été lancée pendant le lot.

Constat utile remonté :
- le premier jet couvrait bien le scope du lot ;
- mais il laissait encore fuiter certaines erreurs de type/structure au moment du `fromJson`.

Correction appliquée après cette relecture :
- ajout de `_parseSpecies(...)` dans le use case ;
- wrapping systématique en `EditorPersistenceException('Pokemon species JSON structure is invalid: ...')` ;
- ajout d’un test dédié sur un champ mal typé.

Donc le point soulevé par la relecture a bien été corrigé dans l’état final.

## Contenu complet des fichiers touchés

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart`

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
  }
}
```

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'import_pokemon_species_json_use_case.dart';
export 'layer_use_cases.dart';
export 'list_pokedex_entries_use_case.dart';
export 'load_pokedex_species_detail_use_case.dart';
export 'map_use_cases.dart';
export 'paint_use_cases.dart';
export 'path_layer_use_cases.dart';
export 'project_element_use_cases.dart';
export 'project_group_use_cases.dart';
export 'project_management_use_cases.dart';
export 'project_scenario_use_cases.dart';
export 'project_tileset_use_cases.dart';
export 'seed_pokemon_demo_data_use_case.dart';
export 'terrain_preset_use_cases.dart';
export 'terrain_use_cases.dart';
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';
```

### `packages/map_editor/test/import_pokemon_species_json_use_case_test.dart`

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

## Lecture honnête du résultat

Ce qui est maintenant bon :
- le lot 23 existe réellement ;
- l’import unitaire interne d’une espèce est en place ;
- les erreurs d’entrée les plus importantes sont claires ;
- `project.json` n’est pas pollué ;
- le scope reste strictement applicatif, sans UI.

Ce qui est volontairement intact :
- aucune UI d’import ;
- aucun lot d’import learnset/évolution/média ;
- aucune logique batch ;
- aucune politique de merge ;
- aucune validation catalogue croisée riche.

Ce qui pourrait être amélioré plus tard, mais n’a pas été touché :
- brancher une UI d’import dédiée ;
- ajouter l’import des autres fichiers annexes ;
- ajouter des rapports utilisateur plus riches ;
- gérer le remplacement contrôlé ou les conflits.

## Checklist d’autocontrôle

- [x] Je n’ai traité que le lot demandé.
- [x] Je n’ai pas ouvert d’UI d’import.
- [x] Je n’ai pas commencé le batch import.
- [x] Je n’ai pas ajouté de merge policy.
- [x] Je n’ai pas touché `project.json`.
- [x] Le use case reste petit et local.
- [x] Les erreurs syntaxiques JSON sont claires.
- [x] Les erreurs de structure/type JSON sont claires.
- [x] Les validations structurelles minimales sont testées.
- [x] L’écriture passe par le repository existant.
- [x] Le code est formaté.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée passe.
- [x] Aucune commande Git d’écriture n’a été utilisée.

