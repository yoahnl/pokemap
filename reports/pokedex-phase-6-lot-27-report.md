# Pokédex Phase 6 / Lot 27 — Import manuel d’un catalogue global interne

## 1. Résumé exécutif honnête

Le lot 27 est maintenant implémenté.

Ce qui a été ajouté :
- un use case applicatif dédié pour importer un seul fichier JSON de catalogue global déjà au format interne ;
- une validation structurelle minimale, locale et explicite ;
- une suite de tests ciblés couvrant le chemin heureux et les erreurs attendues ;
- un export du use case dans le barrel applicatif existant.

Ce qui n’a pas été fait volontairement :
- aucune UI ;
- aucun import batch ;
- aucune merge policy ;
- aucun dry-run ;
- aucune validation croisée riche avec espèces, learnsets, évolutions ou médias ;
- aucun chantier de lot 28.

## 2. Périmètre inclus

- `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart`
- `reports/pokedex-phase-6-lot-27-report.md`

## 3. Périmètre exclu

- UI Pokédex
- boutons d’import
- providers / notifiers / state objects
- runtime
- save
- `project.json`
- import d’espèce
- import de learnset
- import d’évolution
- import de média
- import externe Showdown / PokeAPI
- import batch
- merge policy
- dry-run
- validation croisée riche
- nettoyage opportuniste hors scope
- lot 28

## 4. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart`

Pourquoi touché :
- c’est la brique exacte du lot 27.

Ce qui a été fait :
- lecture du chemin source ;
- refus du `catalogKey` vide ;
- refus du chemin vide ;
- refus du fichier absent ;
- refus d’une extension non `.json` ;
- décodage JSON ;
- refus d’une racine non objet ;
- parsing vers `PokemonCatalogFile` ;
- transformation des erreurs de structure/type en erreur applicative claire ;
- validation structurelle minimale locale ;
- sauvegarde via `PokemonWriteRepository.saveCatalogByKey(...)`.

Pourquoi c’est le plus petit changement raisonnable :
- même pattern que les lots 23 à 26 ;
- aucune abstraction générique nouvelle ;
- aucune logique UI, batch ou import externe ;
- la cohérence simple `catalogKey` / payload réutilise le contrat déjà porté par le repository existant.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Pourquoi touché :
- pour exposer le nouveau use case via le barrel applicatif existant.

Ce qui a été fait :
- ajout d’un export unique.

Pourquoi c’est minimal :
- pas de refactor du barrel ;
- une seule ligne utile.

### `packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart`

Pourquoi touché :
- pour verrouiller les critères d’acceptation du lot 27.

Ce qui a été fait :
- test d’import valide ;
- test `catalogKey` vide ;
- test chemin vide ;
- test fichier absent ;
- test mauvaise extension ;
- test JSON invalide ;
- test racine non objet ;
- test structure invalide / type invalide ;
- test catalogue structurellement invalide ;
- test catalogue sans entrées ;
- test entrée sans `id` exploitable ;
- test mismatch simple entre `catalogKey` demandé et payload ;
- test clé de catalogue non supportée par le storage ;
- vérification que `project.json` n’est pas modifié sur import valide.

Pourquoi c’est minimal :
- aucun harness global nouveau ;
- tests concentrés sur le use case ;
- aucune couverture décorative hors périmètre.

### `reports/pokedex-phase-6-lot-27-report.md`

Pourquoi créé :
- pour documenter ce lot de manière reviewable, avec les vraies commandes, les vraies sorties et le contenu complet des fichiers touchés.

## 5. Commandes réellement exécutées

### Audit ciblé

```bash
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_evolution_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart
sed -n '1,160p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart
rg -n "class PokemonCatalogFile|class PokemonDataMeta|catalogs|catalogKey|saveCatalogByKey|readCatalogByKey|listCatalog" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/project_workspace.dart
sed -n '1,180p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '250,310p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
rg -n "saveCatalogByKey|readCatalogByKey|catalogKey" /Users/karim/Project/pokemonProject/packages/map_editor/test | head -n 200
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_species_json_use_case_test.dart
sed -n '100,220p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '500,560p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '140,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '360,430p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
rg -n "readCatalogByKey\\(|catalog key|catalog read path|Pokemon catalog" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '1,180p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '180,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
rg -n "_movesCatalog\\(|PokemonCatalogFile\\(" /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_*
sed -n '697,760p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
rg -n "catalog': '|\\\"catalog\\\": \\\"|entries': <Map<String, dynamic>>\\[|entries\\\": \\[\" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart | head -n 200
rg -n "'id':|\\\"id\\\":" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart | head -n 120
```

### Validation finale

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_catalog_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_catalog_json_use_case_test.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_catalog_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_catalog_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart reports/pokedex-phase-6-lot-27-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart reports/pokedex-phase-6-lot-27-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart reports/pokedex-phase-6-lot-27-report.md
```

## 6. Résultats réels

### Première passe `dart format ...`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
Formatted 3 files (2 changed) in 0.05 seconds.
```

### Première passe `flutter test test/import_pokemon_catalog_json_use_case_test.dart`

```text
00:02 +12 -1: Some tests failed.
```

Lecture honnête :
- cette première passe a échoué parce qu’un test supposait à tort que `data/pokemon/catalogs/moves.json` n’existait pas forcément après initialisation ;
- le code applicatif n’était pas en cause ;
- le test a été corrigé pour comparer l’état avant/après du fichier cible au lieu de supposer une absence disque.

### Première passe `flutter analyze --no-pub ...`

```text
No issues found! (ran in 1.3s)
```

### Deuxième passe `dart format ...`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

### Deuxième passe `flutter test test/import_pokemon_catalog_json_use_case_test.dart`

```text
00:01 +13: All tests passed!
```

### Deuxième passe `flutter analyze --no-pub ...`

```text
No issues found! (ran in 1.0s)
```

### `git status --short -- ...` avant création du rapport

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
?? packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
```

### `git diff --stat -- ...` avant création du rapport

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

### `git ls-files --others --exclude-standard -- ...` avant création du rapport

```text
packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
```

Remarque honnête :
- ces trois commandes Git ont été exécutées avant création du présent rapport ;
- l’état Git final est actualisé plus bas après création du fichier de rapport ;
- comme dans les lots précédents, `git diff --stat` n’affiche que les fichiers déjà suivis, tandis que `git ls-files --others --exclude-standard` montre les nouveaux fichiers non suivis.

### `git status --short -- ...` final

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
?? packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
?? reports/pokedex-phase-6-lot-27-report.md
```

### `git diff --stat -- ...` final

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

### `git ls-files --others --exclude-standard -- ...` final

```text
packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart
reports/pokedex-phase-6-lot-27-report.md
```

## 7. État git utile

État final utile constaté pour ce lot :
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart` : nouveau fichier non suivi ;
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart` : fichier suivi modifié ;
- `packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart` : nouveau fichier non suivi ;
- `reports/pokedex-phase-6-lot-27-report.md` : nouveau fichier non suivi.

Ce rapport documente uniquement l’état Git ciblé de ce lot, pas l’intégralité du working tree du monorepo.

## 8. Limites restantes

Ce lot reste volontairement petit.

Il ne fait pas :
- de validation croisée riche entre catalogues ;
- de vérification des références des espèces ou learnsets contre le catalogue importé ;
- de gestion de conflit ;
- de remplacement contrôlé ;
- de batch import ;
- de support UI ;
- d’import externe.

Ces points relèvent explicitement des lots suivants ou d’autres chantiers.

## 9. Contenu complet de tous les fichiers touchés

### 9.1 `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart`

```dart
import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un catalogue Pokémon global déjà au format JSON interne du projet.
///
/// Ce lot 27 reste volontairement très petit, comme les lots 23 à 26 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonCatalogFile] ;
/// - on applique seulement une validation structurelle minimale ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// Non-objectifs explicites :
/// - pas d'UI ;
/// - pas de batch import ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de validation croisée riche avec espèces, learnsets ou médias ;
/// - pas de pipeline générique "préparé pour la suite".
class ImportPokemonCatalogJsonUseCase {
  const ImportPokemonCatalogJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonCatalogFile> execute(
    ProjectWorkspace workspace, {
    required String catalogKey,
    required String absoluteSourcePath,
  }) async {
    final trimmedCatalogKey = catalogKey.trim();
    if (trimmedCatalogKey.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog key cannot be empty',
      );
    }

    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon catalog source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon catalog import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final catalog = _parseCatalog(decoded);
    _validateCatalog(trimmedCatalogKey, catalog);

    await writeRepository.saveCatalogByKey(
        workspace, trimmedCatalogKey, catalog);
    return catalog;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon catalog JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon catalog JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonCatalogFile _parseCatalog(Map<String, dynamic> decoded) {
    try {
      return PokemonCatalogFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon catalog JSON structure is invalid: $error',
      );
    }
  }

  void _validateCatalog(String catalogKey, PokemonCatalogFile catalog) {
    // On reste volontairement sur une validation très locale.
    // Le but est de rejeter les catalogues qui sont immédiatement
    // inutilisables pour le storage Pokédex, sans dupliquer ici la logique
    // d'un validateur métier global sur tous les référentiels.
    if (catalog.schemaVersion <= 0) {
      throw const EditorValidationException(
        'Pokemon catalog schemaVersion must be positive',
      );
    }
    if (catalog.kind.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog kind cannot be empty',
      );
    }
    if (catalog.catalog.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog name cannot be empty',
      );
    }

    // Ce lot importe un catalogue interne déjà normalisé. On attend donc le
    // kind de catalogue actuellement utilisé dans le projet, sans commencer à
    // gérer ici d'autres familles de payloads.
    if (catalog.kind.trim() != 'pokemon_catalog') {
      throw const EditorValidationException(
        'Pokemon catalog kind must be pokemon_catalog',
      );
    }

    // Une incohérence simple entre la clé demandée et le contenu du fichier
    // est déjà une erreur structurelle exploitable en review. On la signale
    // ici avec le même message que le repository pour garder un comportement
    // stable et lisible côté tests.
    if (catalog.catalog.trim() != catalogKey) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$catalogKey" but payload is '
        '"${catalog.catalog.trim()}"',
      );
    }

    if (catalog.meta.description.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog meta.description cannot be empty',
      );
    }
    if (catalog.entries.isEmpty) {
      throw const EditorValidationException(
        'Pokemon catalog entries cannot be empty',
      );
    }

    // Les catalogues globaux existants du projet sont tous indexés par `id`.
    // On vérifie donc seulement ce contrat minimal, sans sur-typer chaque
    // forme d'entrée ni reconstruire ici la validation spécifique par catalogue.
    for (final entry in catalog.entries) {
      final id = (entry['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        throw const EditorValidationException(
          'Pokemon catalog entries must define a non-empty id',
        );
      }
    }
  }
}
```

### 9.2 `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'import_pokemon_catalog_json_use_case.dart';
export 'import_pokemon_evolution_json_use_case.dart';
export 'import_pokemon_learnset_json_use_case.dart';
export 'import_pokemon_media_json_use_case.dart';
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

### 9.3 `packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_catalog_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonCatalogJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_catalog_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_catalog_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonCatalogJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Catalog Import Project',
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

  group('ImportPokemonCatalogJsonUseCase', () {
    test('imports one internal catalog json into the local catalogs directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'moves.json',
        _movesCatalog.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        catalogKey: 'moves',
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.catalog, 'moves');
      expect(imported.entries, hasLength(2));

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readCatalogByKey(workspace, 'moves');
      expect(readBack.catalog, 'moves');
      expect(
        readBack.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl']),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fails clearly when the catalog key is empty', () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'moves.json',
        _movesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: '   ',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog key cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the source path is empty', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: '   ',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog source path cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the source file does not exist', () async {
      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: '${tempImportRoot.path}/missing.json',
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog source file not found',
          ),
        ),
      );
    });

    test('fails clearly when the source file is not a json file', () async {
      final sourceFile = File('${tempImportRoot.path}/moves.txt');
      await sourceFile.writeAsString('not a json import');

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog import expects a .json file',
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
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog JSON is invalid'),
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
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _movesCatalog.toJson()
        ..['meta'] = <Object?>['not', 'a', 'map'];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'wrong-types.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed catalog is structurally invalid',
        () async {
      final brokenJson = _movesCatalog.toJson()
        ..['schemaVersion'] = 0
        ..['entries'] = <Object?>[];
      final targetFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      final beforeExists = await targetFile.exists();
      final beforeContents =
          beforeExists ? await targetFile.readAsString() : null;
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-catalog.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog schemaVersion must be positive',
          ),
        ),
      );

      expect(await targetFile.exists(), beforeExists);
      if (beforeContents != null) {
        expect(await targetFile.readAsString(), beforeContents);
      }
    });

    test('fails clearly when the catalog has no entries', () async {
      final brokenJson = _movesCatalog.toJson()..['entries'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-entries.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog entries cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the catalog entry id is missing', () async {
      final brokenJson = _movesCatalog.toJson()
        ..['entries'] = <Object?>[
          <String, Object?>{
            'id': ' ',
            'name': 'Broken',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-entry-id.json',
        brokenJson,
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog entries must define a non-empty id',
          ),
        ),
      );
    });

    test('fails clearly when the catalog key does not match the payload',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'abilities.json',
        _abilitiesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'moves',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog key mismatch: requested "moves" but payload is '
                '"abilities"',
          ),
        ),
      );
    });

    test('fails clearly when the catalog key is not supported by storage',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'berries.json',
        _berriesCatalog.toJson(),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          catalogKey: 'berries',
          absoluteSourcePath: sourceFile.path,
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'Pokemon catalog write path not declared for key: berries',
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

const PokemonCatalogFile _movesCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Move catalog for the local Pokemon project database.',
    sourcePriority: <String>['internal'],
    notes: <String>['Import catalog integration test data.'],
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'tackle',
      'name': 'Tackle',
      'type': 'normal',
    },
    <String, dynamic>{
      'id': 'growl',
      'name': 'Growl',
      'type': 'normal',
    },
  ],
);

const PokemonCatalogFile _abilitiesCatalog = PokemonCatalogFile(
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

const PokemonCatalogFile _berriesCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'berries',
  meta: PokemonDataMeta(
    description: 'Unsupported catalog for storage-key test.',
    sourcePriority: <String>['internal'],
    notes: <String>[],
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
    },
  ],
);
```

### 9.4 `reports/pokedex-phase-6-lot-27-report.md`

Le contenu complet de ce fichier est le document que vous lisez actuellement.

## 10. Checklist d’autocontrôle finale

- [x] J’ai implémenté uniquement le lot 27
- [x] Je n’ai pas commencé le lot 28
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state inutile
- [x] Je n’ai pas créé de pipeline générique spéculatif
- [x] J’ai réutilisé le repository local existant
- [x] Le use case reste petit et local
- [x] Le chemin vide est géré
- [x] Le fichier absent est géré
- [x] La mauvaise extension est gérée
- [x] Le JSON invalide est géré
- [x] La racine non objet est gérée
- [x] Les erreurs de structure sont claires
- [x] La validation structurelle minimale est en place
- [x] `project.json` n’est pas modifié
- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le rapport markdown a été créé
- [x] Le rapport contient les commandes réellement exécutées
- [x] Le rapport contient les résultats réels
- [x] Le rapport contient le contenu COMPLET de tous les fichiers touchés
- [x] Aucune commande Git d’écriture n’a été exécutée
