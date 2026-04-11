# Pokédex Phase 6 / Lot 26 — Import manuel d’un média interne

## 1. Résumé exécutif honnête

Le lot 26 est maintenant implémenté.

Ce qui a été ajouté :
- un use case applicatif dédié pour importer un seul fichier JSON média déjà au format interne ;
- une validation structurelle minimale, locale et explicite ;
- une suite de tests ciblés couvrant le chemin heureux et les erreurs attendues ;
- un export du use case dans le barrel applicatif existant.

Ce qui n’a pas été fait volontairement :
- aucune UI ;
- aucun import batch ;
- aucune merge policy ;
- aucun dry-run ;
- aucune vérification disque des assets référencés ;
- aucune validation croisée riche avec espèces, formes, catalogues ou runtime ;
- aucun chantier de lot 27.

## 2. Objectif exact du lot

Permettre d’importer un seul fichier JSON média Pokémon déjà au format interne du projet vers `data/pokemon/media/`, avec :
- lecture depuis un chemin source absolu ;
- décodage JSON ;
- parsing vers `PokemonMediaFile` ;
- validation structurelle minimale ;
- sauvegarde via le repository local existant ;
- erreurs applicatives claires et stables.

## 3. Périmètre inclus

- `packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/test/import_pokemon_media_json_use_case_test.dart`
- `reports/pokedex-phase-6-lot-26-report.md`

## 4. Périmètre exclu

- UI Pokédex
- boutons d’import
- providers / notifiers / state objects
- runtime
- save
- `project.json`
- import d’espèce
- import de learnset
- import d’évolution
- import de catalogue
- import batch
- merge policy
- dry-run
- validation catalogue croisée riche
- nettoyage opportuniste hors scope
- lot 27

## 5. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart`

Pourquoi touché :
- c’est la brique exacte du lot 26.

Ce qui a été fait :
- lecture du chemin source ;
- refus du chemin vide ;
- refus du fichier absent ;
- refus d’une extension non `.json` ;
- décodage JSON ;
- refus d’une racine non objet ;
- parsing vers `PokemonMediaFile` ;
- transformation des erreurs de structure/type en erreur applicative claire ;
- validation structurelle minimale locale ;
- sauvegarde via `PokemonWriteRepository.saveMedia(...)`.

Pourquoi c’est le plus petit changement raisonnable :
- même pattern que les lots 23, 24 et 25 ;
- aucune abstraction générique nouvelle ;
- aucune logique UI, batch ou catalogue.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Pourquoi touché :
- pour exposer le nouveau use case via le barrel applicatif existant.

Ce qui a été fait :
- ajout d’un export unique.

Pourquoi c’est minimal :
- pas de refactor du barrel ;
- une seule ligne utile.

### `packages/map_editor/test/import_pokemon_media_json_use_case_test.dart`

Pourquoi touché :
- pour verrouiller les critères d’acceptation du lot 26.

Ce qui a été fait :
- test d’import valide ;
- test chemin vide ;
- test fichier absent ;
- test mauvaise extension ;
- test JSON invalide ;
- test racine non objet ;
- test structure invalide / type invalide ;
- test `speciesId` vide ;
- test `defaultFormId` vide ;
- test sans variantes ;
- test `defaultFormId` absent de `variants` ;
- test média sans aucune référence utile ;
- test variante avec animation structurellement inutilisable ;
- vérification que `project.json` n’est pas modifié sur import valide.

Pourquoi c’est minimal :
- aucun harness global nouveau ;
- tests concentrés sur le use case ;
- aucune couverture décorative hors périmètre.

### `reports/pokedex-phase-6-lot-26-report.md`

Pourquoi créé :
- pour documenter ce lot de manière reviewable, avec les vraies commandes, les vraies sorties et le contenu complet des fichiers touchés.

## 6. Commandes réellement exécutées

### Audit ciblé

```bash
rg --files /Users/karim/Project/pokemonProject | rg '(^|/)AGENTS\.md$|(^|/)README\.md$'
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/README.md
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_evolution_json_use_case.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
rg -n "class PokemonMediaFile|class PokemonMediaVariant|class PokemonMediaAnimationRef|class PokemonMedia" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '680,920p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '920,1045p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
rg -n "_validateMedia|media\." /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
sed -n '618,700p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
rg -n "saveMedia\(|readMediaById\(|listMediaIds\(" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '320,365p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_evolution_json_use_case_test.dart
sed -n '1,140p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart
rg -n "PokemonMediaFile\(|defaultFormId|frontStatic|animationId" /Users/karim/Project/pokemonProject/packages/map_editor/test /Users/karim/Project/pokemonProject/packages/map_editor/lib | head -n 200
rg -n "data/pokemon/media|saveMedia\(|readMediaById\(" /Users/karim/Project/pokemonProject/packages/map_editor/test /Users/karim/Project/pokemonProject/packages/map_editor/lib | head -n 200
sed -n '664,712p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
rg -n "String\? _readOptionalTrimmedString|List<String> _readStringList|Map<String, String> _readStringMap" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1050,1115p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
```

### Validation finale

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_media_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_media_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_media_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_media_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_media_json_use_case_test.dart reports/pokedex-phase-6-lot-26-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/import_pokemon_media_json_use_case_test.dart reports/pokedex-phase-6-lot-26-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart packages/map_editor/test/import_pokemon_media_json_use_case_test.dart reports/pokedex-phase-6-lot-26-report.md
```

## 7. Résultats réels

### `dart format ...`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_media_json_use_case_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

### `flutter test test/import_pokemon_media_json_use_case_test.dart`

```text
00:01 +13: All tests passed!
```

### `flutter analyze --no-pub ...`

```text
No issues found! (ran in 1.7s)
```

### `git status --short -- ...` final

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart
?? packages/map_editor/test/import_pokemon_media_json_use_case_test.dart
?? reports/pokedex-phase-6-lot-26-report.md
```

### `git diff --stat -- ...` final

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

### `git ls-files --others --exclude-standard -- ...`

```text
packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart
packages/map_editor/test/import_pokemon_media_json_use_case_test.dart
reports/pokedex-phase-6-lot-26-report.md
```

Remarque honnête :
- `git diff --stat` ne montre ici que le fichier déjà suivi ;
- les nouveaux fichiers du lot restent `untracked` tant qu’aucune opération Git d’écriture n’est faite ;
- `git ls-files --others --exclude-standard` complète donc l’état Git utile en montrant explicitement les nouveaux fichiers.

## 8. État git utile

État final utile constaté pour ce lot :
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart` : nouveau fichier non suivi ;
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart` : fichier suivi modifié ;
- `packages/map_editor/test/import_pokemon_media_json_use_case_test.dart` : nouveau fichier non suivi ;
- `reports/pokedex-phase-6-lot-26-report.md` : nouveau fichier non suivi.

Ce rapport documente uniquement l’état Git ciblé de ce lot, pas l’intégralité du working tree du monorepo.

## 9. Limites restantes

Ce lot reste volontairement petit.

Il ne fait pas :
- de vérification que les assets référencés existent sur disque ;
- de validation croisée riche avec les espèces ou formes locales ;
- de gestion de conflit ;
- de remplacement contrôlé ;
- de batch import ;
- de support UI ;
- d’import de catalogue.

Ces points relèvent explicitement des lots suivants ou d’autres chantiers.

## 10. Contenu complet de tous les fichiers touchés

### 10.1 `packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart`

```dart
import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un fichier média Pokémon déjà au format JSON interne du projet.
///
/// Le lot 26 reste volontairement symétrique avec les lots 23, 24 et 25 :
/// - un seul fichier source ;
/// - parsing direct vers [PokemonMediaFile] ;
/// - validation structurelle minimale, locale et explicite ;
/// - écriture via le repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de batch ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de vérification disque des assets référencés ;
/// - pas de validation croisée riche avec les espèces, formes ou catalogues.
class ImportPokemonMediaJsonUseCase {
  const ImportPokemonMediaJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonMediaFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon media source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon media import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final media = _parseMedia(decoded);
    _validateMedia(media);

    await writeRepository.saveMedia(workspace, media);
    return media;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon media JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon media JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonMediaFile _parseMedia(Map<String, dynamic> decoded) {
    try {
      return PokemonMediaFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon media JSON structure is invalid: $error',
      );
    }
  }

  void _validateMedia(PokemonMediaFile media) {
    // On reste volontairement sur une validation locale.
    // Le but est de rejeter les fichiers média inutilisables dès l'import,
    // sans transformer ce lot en validateur Pokédex global.
    final speciesId = media.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media speciesId cannot be empty',
      );
    }

    final defaultFormId = media.defaultFormId.trim();
    if (defaultFormId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media defaultFormId cannot be empty',
      );
    }

    if (media.variants.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media must define at least one variant',
      );
    }

    // Le pipeline courant s'appuie sur une variante par défaut concrète.
    // On exige donc qu'elle soit bien présente dans la map des variantes.
    if (!media.variants.containsKey(defaultFormId)) {
      throw const EditorValidationException(
        'Pokemon media defaultFormId must exist in variants',
      );
    }

    var hasAnyUsableMediaReference = false;

    for (final entry in media.variants.entries) {
      final variantId = entry.key.trim();
      final variant = entry.value;

      if (variantId.isEmpty) {
        throw const EditorValidationException(
          'Pokemon media variant ids cannot be empty',
        );
      }

      for (final animationEntry in variant.animations.entries) {
        final animationKey = animationEntry.key.trim();
        final animation = animationEntry.value;

        // Une animation déclarée avec une clé vide n'est pas adressable
        // proprement par les vues ou le runtime ; on la refuse ici.
        if (animationKey.isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animation keys cannot be empty',
          );
        }
        if (animation.sheet.trim().isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animation sheet cannot be empty',
          );
        }
        if (animation.animationId.trim().isEmpty) {
          throw const EditorValidationException(
            'Pokemon media animationId cannot be empty',
          );
        }
      }

      if (_variantHasUsableData(variant)) {
        hasAnyUsableMediaReference = true;
      }
    }

    // On ne demande pas que chaque variante soit complète, seulement que le
    // fichier média apporte au moins une référence exploitable au pipeline.
    if (!hasAnyUsableMediaReference) {
      throw const EditorValidationException(
        'Pokemon media must contain at least one media reference',
      );
    }
  }

  bool _variantHasUsableData(PokemonMediaVariant variant) {
    return <String?>[
          variant.frontStatic,
          variant.backStatic,
          variant.frontShinyStatic,
          variant.backShinyStatic,
          variant.icon,
          variant.party,
          variant.overworld,
          variant.portrait,
          variant.cry,
        ].any((value) => value != null && value.trim().isNotEmpty) ||
        variant.animations.isNotEmpty;
  }
}
```

### 10.2 `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
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

### 10.3 `packages/map_editor/test/import_pokemon_media_json_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_media_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonMediaJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_media_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_media_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonMediaJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Media Import Project',
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

  group('ImportPokemonMediaJsonUseCase', () {
    test('imports one internal media json into the local media directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurMedia.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.speciesId, 'bulbasaur');
      expect(imported.defaultFormId, 'base');

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readMediaById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(
        readBack.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(
        readBack.variants['base']?.animations['battleFront']?.animationId,
        'battle_front',
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

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
            'Pokemon media source path cannot be empty',
          ),
        ),
      );
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
            'Pokemon media source file not found',
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
            'Pokemon media import expects a .json file',
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
            contains('Pokemon media JSON is invalid'),
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
            'Pokemon media JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': <String, Object?>{
            'frontStatic': 42,
          },
        };
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
            contains('Pokemon media JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when speciesId is empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()..['speciesId'] = '  ';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-species.json',
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
            'Pokemon media speciesId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when defaultFormId is empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()..['defaultFormId'] = ' ';
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-default-form.json',
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
            'Pokemon media defaultFormId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when no variants are defined', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{};
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-variants.json',
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
            'Pokemon media must define at least one variant',
          ),
        ),
      );
    });

    test('fails clearly when defaultFormId is absent from variants', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['defaultFormId'] = 'mega'
        ..['variants'] = <String, Object?>{
          'base': (_bulbasaurMedia.variants['base']!).toJson(),
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'missing-default-variant.json',
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
            'Pokemon media defaultFormId must exist in variants',
          ),
        ),
      );
    });

    test('fails clearly when all variants are empty', () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': const <String, Object?>{},
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-media.json',
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
            'Pokemon media must contain at least one media reference',
          ),
        ),
      );
    });

    test('fails clearly when an animation ref is structurally unusable',
        () async {
      final brokenJson = _bulbasaurMedia.toJson()
        ..['variants'] = <String, Object?>{
          'base': <String, Object?>{
            'animations': <String, Object?>{
              'battleFront': <String, Object?>{
                'sheet': ' ',
                'animationId': 'battle_front',
              },
            },
          },
        };
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-animation.json',
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
            'Pokemon media animation sheet cannot be empty',
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

const PokemonMediaFile _bulbasaurMedia = PokemonMediaFile(
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
```

### 10.4 `reports/pokedex-phase-6-lot-26-report.md`

Le contenu complet de ce fichier est le document que vous lisez actuellement.

## 11. Checklist d’autocontrôle finale

- [x] J’ai implémenté uniquement le lot 26
- [x] Je n’ai pas commencé le lot 27
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state inutile
- [x] Je n’ai pas créé de pipeline générique d’import
- [x] J’ai réutilisé le repository local existant
- [x] Le use case reste petit et local
- [x] Le chemin vide est géré
- [x] Le fichier absent est géré
- [x] La mauvaise extension est gérée
- [x] Le JSON invalide est géré
- [x] La racine non objet est gérée
- [x] Les erreurs de structure sont claires
- [x] La validation structurelle minimale est en place
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le code est formaté
- [x] Le rapport markdown a été créé
- [x] Le rapport contient les commandes réellement exécutées
- [x] Le rapport contient les résultats réels
- [x] Le rapport contient le contenu complet de tous les fichiers touchés
- [x] Aucune commande Git d’écriture n’a été exécutée
