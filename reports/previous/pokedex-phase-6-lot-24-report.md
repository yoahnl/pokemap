# Pokédex Phase 6 / Lot 24 — Import manuel d’un learnset interne

## 1. Résumé exécutif honnête

Le lot 24 est maintenant implémenté.

Ce qui a été ajouté :
- un use case applicatif dédié pour importer un seul fichier JSON de learnset déjà au format interne ;
- une validation structurelle minimale, locale et explicite ;
- une suite de tests ciblés couvrant le chemin heureux et les erreurs attendues ;
- un export du use case dans le barrel applicatif existant.

Ce qui n’a pas été fait volontairement :
- aucune UI ;
- aucun import batch ;
- aucun import d’évolution, de média ou de catalogue ;
- aucune merge policy ;
- aucun dry-run ;
- aucune validation catalogue croisée riche ;
- aucun chantier de lot 25, 26 ou 27.

## 2. Périmètre inclus

- `packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart`
- `reports/pokedex-phase-6-lot-24-report.md`

## 3. Périmètre exclu

- UI
- providers / notifiers / state
- runtime
- `project.json`
- import d’évolution
- import de média
- import de catalogue
- lot 25
- lot 26
- lot 27
- tout lot suivant
- refactor large
- pipeline générique d’import

## 4. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart`

Pourquoi touché :
- c’est la brique exacte du lot 24.

Ce qui a été fait :
- lecture du chemin source ;
- refus du chemin vide ;
- refus du fichier absent ;
- refus d’une extension non `.json` ;
- décodage JSON ;
- refus d’une racine non objet ;
- parsing vers `PokemonLearnsetFile` ;
- transformation des erreurs de structure/type en erreur applicative claire ;
- validation structurelle minimale ;
- sauvegarde via `PokemonWriteRepository.saveLearnset(...)`.

Pourquoi c’est le plus petit changement raisonnable :
- même pattern que le lot 23 ;
- aucune abstraction générique nouvelle ;
- aucune logique hors use case local.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Pourquoi touché :
- pour exposer le nouveau use case comme les autres use cases applicatifs déjà existants.

Ce qui a été fait :
- ajout d’un export unique.

Pourquoi c’est minimal :
- pas de refactor du barrel ;
- une ligne utile.

### `packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart`

Pourquoi touché :
- pour verrouiller les critères d’acceptation du lot.

Ce qui a été fait :
- test d’import valide ;
- test chemin vide ;
- test fichier absent ;
- test mauvaise extension ;
- test JSON invalide ;
- test racine non objet ;
- test structure invalide / type invalide ;
- test learnset structurellement invalide ;
- test learnset vide ;
- test entrée `levelUp` incomplète ;
- test entrée `tm` incomplète.

Pourquoi c’est minimal :
- aucun harness global nouveau ;
- tests concentrés sur le use case ;
- aucune couverture décorative UI.

### `reports/pokedex-phase-6-lot-24-report.md`

Pourquoi créé :
- pour documenter ce lot de manière reviewable, avec les vraies commandes, les vraies sorties et le contenu complet des fichiers touchés.

## 5. Commandes réellement exécutées

```bash
sed -n '840,980p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1,120p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
sed -n '486,575p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
sed -n '1,120p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_learnset_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_learnset_json_use_case_test.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_pokemon_learnset_json_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart lib/src/application/use_cases/use_cases.dart test/import_pokemon_learnset_json_use_case_test.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
sed -n '1,120p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart
sed -n '1,420p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
```

## 6. Résultats réels

### `dart format ...`

Première passe :

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
Formatted 3 files (2 changed) in 0.01 seconds.
```

Deuxième passe après correction du test de type invalide :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### `flutter test test/import_pokemon_learnset_json_use_case_test.dart`

Passe finale :

```text
00:01 +11: All tests passed!
```

### `flutter analyze --no-pub ...`

Passe finale :

```text
No issues found! (ran in 0.9s)
```

### Relecture parallèle de scope

Résultat utile :
- pas de fuite de scope au-delà du lot 24 ;
- pas de gap majeur d’acceptation ;
- seule suggestion non bloquante : ajouter encore plus de couverture sur `startingMoves` / `relearnMoves`, laissée hors ajout parce que le lot est déjà correctement couvert.

## 7. État Git utile

État ciblé utile après implémentation du code, avant création de ce rapport :

```text
 M packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart
```

Remarque honnête :
- le repo peut contenir d’autres changements non commit hors du périmètre du lot ;
- ce rapport ne prétend pas fournir un `git status` global du monorepo ;
- il documente uniquement l’état utile ciblé pour ce lot.

## 8. Limites restantes

Ce lot reste volontairement petit.

Il ne fait pas :
- de vérification que les `moveId` existent vraiment dans les catalogues ;
- de validation croisée riche avec l’espèce ;
- de gestion de conflit ;
- de remplacement contrôlé ;
- de batch import ;
- de support UI.

Ces points sont explicitement hors scope.

## 9. Contenu complet de tous les fichiers touchés

### 9.1 `packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart`

```dart
import 'dart:convert';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Importe un learnset Pokémon déjà au format JSON interne du projet.
///
/// Ce use case reste volontairement petit pour le lot 24 :
/// - on lit un seul fichier JSON source ;
/// - on parse directement vers [PokemonLearnsetFile] ;
/// - on applique seulement une validation structurelle minimale ;
/// - on délègue ensuite l'écriture au repository local existant.
///
/// Non-objectifs explicites de ce lot :
/// - pas d'UI ;
/// - pas de batch import ;
/// - pas de merge policy ;
/// - pas de dry-run ;
/// - pas de validation catalogue croisée complète ;
/// - pas de pipeline générique "pour préparer la suite".
class ImportPokemonLearnsetJsonUseCase {
  const ImportPokemonLearnsetJsonUseCase(this.writeRepository);

  final PokemonWriteRepository writeRepository;

  Future<PokemonLearnsetFile> execute(
    ProjectWorkspace workspace, {
    required String absoluteSourcePath,
  }) async {
    final sourcePath = absoluteSourcePath.trim();
    if (sourcePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset source path cannot be empty',
      );
    }
    if (!await workspace.fileExists(sourcePath)) {
      throw const EditorValidationException(
        'Pokemon learnset source file not found',
      );
    }
    if (!sourcePath.toLowerCase().endsWith('.json')) {
      throw const EditorValidationException(
        'Pokemon learnset import expects a .json file',
      );
    }

    final raw = await workspace.readTextFile(sourcePath);
    final decoded = _decodeJsonRoot(raw);
    final learnset = _parseLearnset(decoded);
    _validateLearnset(learnset);

    await writeRepository.saveLearnset(workspace, learnset);
    return learnset;
  }

  Map<String, dynamic> _decodeJsonRoot(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Pokemon learnset JSON is invalid: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw const EditorPersistenceException(
        'Pokemon learnset JSON root must be an object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  PokemonLearnsetFile _parseLearnset(Map<String, dynamic> decoded) {
    try {
      return PokemonLearnsetFile.fromJson(decoded);
    } catch (error) {
      throw EditorPersistenceException(
        'Pokemon learnset JSON structure is invalid: $error',
      );
    }
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    // On reste sur une validation structurelle minimale.
    // Le but est de refuser les learnsets inutilisables dès l'import, sans
    // réimplémenter ici tout le validateur projet plus riche.
    if (learnset.speciesId.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }

    // Un learnset totalement vide serait techniquement sérialisable, mais il
    // n'apporte rien au pipeline Pokédex actuel. On le refuse donc dès ce lot
    // pour garder un import unitaire utile et prévisible.
    final hasAnySection = learnset.startingMoves.isNotEmpty ||
        learnset.relearnMoves.isNotEmpty ||
        learnset.levelUp.isNotEmpty ||
        learnset.tm.isNotEmpty ||
        learnset.tutor.isNotEmpty ||
        learnset.egg.isNotEmpty ||
        learnset.event.isNotEmpty ||
        learnset.transfer.isNotEmpty;
    if (!hasAnySection) {
      throw const EditorValidationException(
        'Pokemon learnset must contain at least one move section',
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset startingMoves cannot contain empty move ids',
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset relearnMoves cannot contain empty move ids',
        );
      }
    }

    // Les entrées level-up sont les plus structurées du modèle courant.
    // On exige donc explicitement leurs champs minimaux au lieu de laisser
    // passer des objets partiellement vides qui casseraient ensuite l'affichage.
    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp moveId cannot be empty',
        );
      }
      if (entry.level <= 0) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp level must be positive',
        );
      }
      if (entry.source.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp source cannot be empty',
        );
      }
      if (entry.versionGroup.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp versionGroup cannot be empty',
        );
      }
    }

    // Les autres familles partagent un format plus simple : move + versionGroup.
    // On reste donc très local et on valide seulement ces deux champs.
    void validateMoveEntries(
      List<PokemonLearnsetMoveEntry> entries,
      String label,
    ) {
      for (final entry in entries) {
        if (entry.moveId.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label moveId cannot be empty',
          );
        }
        if (entry.versionGroup.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label versionGroup cannot be empty',
          );
        }
      }
    }

    validateMoveEntries(learnset.tm, 'tm');
    validateMoveEntries(learnset.tutor, 'tutor');
    validateMoveEntries(learnset.egg, 'egg');
    validateMoveEntries(learnset.event, 'event');
    validateMoveEntries(learnset.transfer, 'transfer');
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
export 'import_pokemon_learnset_json_use_case.dart';
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

### 9.3 `packages/map_editor/test/import_pokemon_learnset_json_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_learnset_json_use_case.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late Directory tempImportRoot;
  late ProjectFileSystem workspace;
  late ImportPokemonLearnsetJsonUseCase useCase;
  late FilePokemonReadRepository readRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_learnset_import_project_',
    );
    tempImportRoot = await Directory.systemTemp.createTemp(
      'pokemon_learnset_import_source_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const ImportPokemonLearnsetJsonUseCase(
      FilePokemonWriteRepository(),
    );
    readRepository = const FilePokemonReadRepository();

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon Learnset Import Project',
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

  group('ImportPokemonLearnsetJsonUseCase', () {
    test(
        'imports one internal learnset json into the local learnsets directory',
        () async {
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'bulbasaur.json',
        _bulbasaurLearnset.toJson(),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final imported = await useCase.execute(
        workspace,
        absoluteSourcePath: sourceFile.path,
      );

      expect(imported.speciesId, 'bulbasaur');
      expect(imported.levelUp, hasLength(2));

      final savedFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      expect(await savedFile.exists(), isTrue);

      final readBack =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.tm.single.moveId, 'protect');
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
            'Pokemon learnset source path cannot be empty',
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
            'Pokemon learnset source file not found',
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
            'Pokemon learnset import expects a .json file',
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
            contains('Pokemon learnset JSON is invalid'),
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
            'Pokemon learnset JSON root must be an object',
          ),
        ),
      );
    });

    test('fails clearly when the source json has wrong field types', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['levelUp'] = <Object?>[
          <String, Object?>{
            'moveId': 'tackle',
            'level': 'oops',
            'source': 'level-up',
            'versionGroup': 'scarlet-violet',
          },
        ];
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
            contains('Pokemon learnset JSON structure is invalid'),
          ),
        ),
      );
    });

    test('fails clearly when the parsed learnset is structurally invalid',
        () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['speciesId'] = '  '
        ..['startingMoves'] = <String>[]
        ..['relearnMoves'] = <String>[]
        ..['levelUp'] = <Object?>[]
        ..['tm'] = <Object?>[]
        ..['tutor'] = <Object?>[]
        ..['egg'] = <Object?>[]
        ..['event'] = <Object?>[]
        ..['transfer'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-learnset.json',
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
            'Pokemon learnset speciesId cannot be empty',
          ),
        ),
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

    test('fails clearly when the learnset has no move section', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['startingMoves'] = <String>[]
        ..['relearnMoves'] = <String>[]
        ..['levelUp'] = <Object?>[]
        ..['tm'] = <Object?>[]
        ..['tutor'] = <Object?>[]
        ..['egg'] = <Object?>[]
        ..['event'] = <Object?>[]
        ..['transfer'] = <Object?>[];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'empty-learnset.json',
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
            'Pokemon learnset must contain at least one move section',
          ),
        ),
      );
    });

    test('fails clearly when a level-up entry is incomplete', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['levelUp'] = <Object?>[
          <String, Object?>{
            'moveId': 'vine-whip',
            'level': 7,
            'source': 'level-up',
            'versionGroup': '',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-level-up.json',
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
            'Pokemon learnset levelUp versionGroup cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when a move-entry section is incomplete', () async {
      final brokenJson = _bulbasaurLearnset.toJson()
        ..['tm'] = <Object?>[
          <String, Object?>{
            'moveId': 'protect',
            'versionGroup': ' ',
          },
        ];
      final sourceFile = await _writeSourceJson(
        tempImportRoot,
        'broken-tm.json',
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
            'Pokemon learnset tm versionGroup cannot be empty',
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

const PokemonLearnsetFile _bulbasaurLearnset = PokemonLearnsetFile(
  speciesId: 'bulbasaur',
  startingMoves: <String>['tackle', 'growl'],
  relearnMoves: <String>['tackle', 'growl', 'vine-whip'],
  levelUp: <PokemonLearnsetLevelUpEntry>[
    PokemonLearnsetLevelUpEntry(
      moveId: 'tackle',
      level: 1,
      source: 'level-up',
      versionGroup: 'scarlet-violet',
    ),
    PokemonLearnsetLevelUpEntry(
      moveId: 'vine-whip',
      level: 7,
      source: 'level-up',
      versionGroup: 'scarlet-violet',
    ),
  ],
  tm: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'protect',
      versionGroup: 'scarlet-violet',
    ),
  ],
  tutor: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'seed-bomb',
      versionGroup: 'scarlet-violet',
    ),
  ],
  egg: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'petal-dance',
      versionGroup: 'scarlet-violet',
    ),
  ],
  event: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'celebrate',
      versionGroup: 'scarlet-violet',
    ),
  ],
  transfer: <PokemonLearnsetMoveEntry>[
    PokemonLearnsetMoveEntry(
      moveId: 'toxic',
      versionGroup: 'scarlet-violet',
    ),
  ],
);
```

### 9.4 `reports/pokedex-phase-6-lot-24-report.md`

Le contenu complet de ce fichier est le document que tu es en train de lire. Je n’ai touché aucun autre fichier de rapport pour ce lot.

## 10. Checklist d’autocontrôle finale

- [x] J’ai implémenté uniquement le lot 24
- [x] Je n’ai pas commencé le lot 25
- [x] Je n’ai pas commencé le lot 26
- [x] Je n’ai pas commencé le lot 27
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state inutile
- [x] Je n’ai pas recréé de pipeline parallèle
- [x] Je réutilise le repository local existant
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

