# Pokédex Phase 7B — Species Overwrite Final Fix Report

## 1. Résumé exécutif honnête

Le faux positif restant existait bien.

Le mini-fix précédent avait corrigé un cas réel de réutilisation de chemin non canonique, mais la résolution `resolveSpeciesRelativePathById(...)` gardait encore un biais conceptuel : un fichier pouvait être compté trop tôt comme match à cause de son basename, avant vérification de son `id` réel dans le JSON.

Exemple problématique :
- chemin : `data/pokemon/species/9999-bulbasaur.json`
- contenu réel : `{ "id": "something_else", ... }`

Ce fichier ne devait pas compter comme match pour `bulbasaur`.

Le correctif final applique maintenant la règle stricte attendue :
- la vérité est le JSON ;
- un fichier ne matche que si son JSON déclare réellement l’`id` demandé ;
- les fichiers invalides / non objets / sans `id` exploitable / portant un autre `id` sont ignorés ;
- un conflit n’est levé que si plusieurs fichiers déclarent réellement le même `id`.

Le scope est resté strict :
- aucun changement UI ;
- aucun changement `project.json` ;
- aucun changement dans les use cases 34-36 ;
- aucun changement dans les convertisseurs 28-33 ;
- aucun fichier hors scope touché.

## 2. Diagnostic précis

### 2.1 Où le faux positif existait encore

Dans `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`, la méthode :

- `resolveSpeciesRelativePathById(...)`

utilisait encore un fast-path basé sur le basename :
- `basename == '<id>.json'`
- ou `basename.endsWith('-<id>.json')`

Puis ajoutait immédiatement ce fichier à la liste des matches, sans vérifier son `id` réel dans le JSON.

Donc un fichier trompeur comme :
- `data/pokemon/species/9999-bulbasaur.json`

était compté comme match même si son contenu déclarait en réalité :

```json
{ "id": "something_else" }
```

### 2.2 Pourquoi c’était un vrai bug métier

Le contrat métier recherché ici n’est pas :
- “trouver un nom de fichier qui ressemble à l’id”

mais bien :
- “retrouver le fichier qui stocke réellement l’espèce d’id donné”

Pour un overwrite species, la décision correcte ne peut donc pas reposer sur le basename, car :
- le slug peut diverger ;
- le nom de fichier peut être historique ou custom ;
- un fichier peut porter un nom trompeur ;
- seul le JSON dit quelle espèce il représente vraiment.

### 2.3 Pourquoi l’ancien test de conflit était intellectuellement faux

L’ancien test de conflit dans `file_pokemon_write_repository_test.dart` fabriquait :
- un fichier nommé comme s’il matchait `bulbasaur`
- mais avec un JSON portant `"id": "something_else"`

Puis il attendait un conflit.

Ce test était incorrect au niveau du contrat métier :
- il testait un faux positif de nommage ;
- pas un vrai doublon d’identité Pokémon ;
- il transformait donc un bug de résolution en comportement attendu.

Le vrai test de conflit doit au contraire vérifier :
- deux fichiers différents
- déclarant tous les deux réellement `"id": "bulbasaur"`

### 2.4 Pourquoi la correction devait être portée par le reader

Le bug devait être corrigé dans le reader parce que :
- `FilePokemonWriteRepository.saveSpecies(...)` délègue déjà la résolution du chemin existant au reader ;
- l’orchestration d’import externe utilise aussi cette résolution ;
- corriger uniquement le writer ou uniquement le use case externe aurait laissé une incohérence ailleurs ;
- le reader est la vraie source commune de la décision “quel fichier représente déjà cette espèce ?”.

Donc la correction la plus petite et la plus propre était :
- corriger le reader ;
- laisser le writer et l’import externe inchangés.

## 3. Correctif exact appliqué

### Règle finale

`resolveSpeciesRelativePathById(...)` :
- scanne les `.json` de `data/pokemon/species`
- lit chaque JSON
- extrait l’`id` déclaré
- ignore les fichiers invalides / non objets / sans `id` String non vide
- ne compte comme match que les fichiers dont l’`id` réel est exactement celui demandé
- renvoie :
  - `null` si aucun match réel
  - le chemin unique si un seul match réel
  - `EditorConflictException` si plusieurs fichiers déclarent réellement le même `id`

### Pourquoi ce correctif est volontairement conservateur

J’ai retiré la décision par basename.

Le but ici n’est pas l’optimisation maximale, mais la correction maximale avec le plus petit diff de comportement utile :
- pas de faux positif ;
- pas de conflit artificiel ;
- pas de blocage si un autre fichier du dossier est invalide ou mal nommé ;
- cohérence totale entre reader, writer et import externe.

## 4. Justification fichier par fichier

### 4.1 Modifié — `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

Pourquoi :
- c’est la racine du faux positif ;
- la résolution du chemin existant devait être corrigée à cet endroit, pas ailleurs.

Ce qui a changé :
- suppression du fast-path décisionnel par basename ;
- lecture du JSON comme source de vérité ;
- ajout de commentaires explicites sur :
  - pourquoi le basename ne suffit pas ;
  - pourquoi le JSON est la vérité ;
  - pourquoi les fichiers invalides non liés sont ignorés ;
  - pourquoi le conflit doit rester réservé aux vrais doublons d’`id`.

### 4.2 Modifié — `packages/map_editor/test/file_pokemon_write_repository_test.dart`

Pourquoi :
- il fallait corriger le faux test de conflit ;
- il fallait prouver la régression writer sur le bon contrat.

Ce qui a changé :
- conservation du test utile de réutilisation du chemin non canonique ;
- ajout d’un test où un basename trompeur avec un autre `id` ne bloque plus l’overwrite ;
- remplacement du faux conflit par un vrai conflit fondé sur deux JSON déclarant réellement le même `id`.

### 4.3 Modifié — `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

Pourquoi :
- il fallait prouver que l’orchestration `overwriteExisting` reste cohérente avec cette règle finale.

Ce qui a changé :
- conservation du test d’overwrite sur chemin non canonique ;
- ajout d’un test externe avec un fichier trompeur `9999-bulbasaur.json` mais un autre `id` JSON ;
- vérification que le vrai fichier existant est toujours choisi ;
- vérification qu’aucun fichier canonique parasite n’est créé ;
- vérification que `project.json` reste inchangé.

### 4.4 Créé — `reports/pokedex-phase-7b-species-overwrite-final-fix-report.md`

Pourquoi :
- pour documenter le diagnostic final, le correctif, les validations réelles et le contenu complet des fichiers touchés.

## 5. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

### Créé
- `reports/pokedex-phase-7b-species-overwrite-final-fix-report.md`

### Supprimé
- aucun

## 6. Commandes réellement exécutées

### Audit

```bash
sed -n '200,320p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '240,420p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '220,360p' /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
rg -n "Multiple Pokemon species files match the id|conflict when multiple species files|9999-bulbasaur|something_else" /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart -S
sed -n '420,560p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '560,640p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
rg -n "_sanitizeSpeciesFileSegment\\(" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src -S
sed -n '1,120p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '226,290p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
```

### Format

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
```

### Tests

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/file_pokemon_write_repository_test.dart test/import_external_pokemon_use_cases_test.dart
```

### Analyse

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart test/file_pokemon_write_repository_test.dart test/import_external_pokemon_use_cases_test.dart
```

### Git lecture seule

```bash
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/file_pokemon_write_repository_test.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/pokedex-phase-7b-species-overwrite-final-fix-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/file_pokemon_write_repository_test.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/pokedex-phase-7b-species-overwrite-final-fix-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- reports/pokedex-phase-7b-species-overwrite-final-fix-report.md
```

## 7. Résultats réels

### `dart format`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
Formatted 3 files (1 changed) in 0.02 seconds.
```

### `flutter test`

```text
00:01 +24: All tests passed!
```

### `flutter analyze --no-pub`

```text
No issues found! (ran in 1.6s)
```

## 8. État Git utile

État après correctif et avant création du rapport :

```text
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/test/file_pokemon_write_repository_test.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
```

État utile attendu après création du rapport :
- les trois fichiers ci-dessus modifiés ;
- le rapport final nouveau fichier non suivi.

## 9. Limites restantes

Ce mini-fix reste volontairement minuscule.

Il ne fait pas :
- de renommage automatique des species files mal nommés ;
- de nettoyage automatique de doublons déjà présents ;
- de changement de convention de nommage ;
- de refactor du writer ;
- de changement des lots 34 à 36 au-delà de cette correction ciblée ;
- de changement UI.

## 10. Contenu complet de tous les fichiers modifiés / créés

### 10.1 `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/project_workspace.dart';

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  const PokemonProjectDataReader();

  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) async {
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    final manifest = await readManifest(workspace);
    final relativePath = manifest.catalogFiles[catalogKey];
    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in manifest: $catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/$relativePath',
      label: 'Pokemon catalog "$catalogKey"',
    );
    return PokemonCatalogFile.fromJson(json);
  }

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
          'Pokemon species id cannot be empty');
    }

    final speciesPathEntry =
        await _resolveSpeciesIndexEntryById(workspace, trimmedId);
    final species = await _readSpeciesAtRelativePath(
      workspace,
      speciesPathEntry.relativePath,
    );
    if (species.id != trimmedId) {
      throw EditorPersistenceException(
        'Pokemon species file id mismatch for "$trimmedId": '
        '${speciesPathEntry.relativePath} contains "${species.id}"',
      );
    }
    return species;
  }

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/learnsets/$trimmedId.json',
      label: 'Pokemon learnset "$trimmedId"',
    );
    return PokemonLearnsetFile.fromJson(json);
  }

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/evolutions/$trimmedId.json',
      label: 'Pokemon evolution "$trimmedId"',
    );
    return PokemonEvolutionFile.fromJson(json);
  }

  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/media/$trimmedId.json',
      label: 'Pokemon media "$trimmedId"',
    );
    return PokemonMediaFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    return _listJsonRelativePaths(
      workspace,
      'data/pokemon/species',
      label: 'Pokemon species directory',
    );
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
  }

  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) async {
    final trimmedDirectory = speciesDirectoryRelativePath.trim();
    if (trimmedDirectory.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species directory cannot be empty',
      );
    }

    final entries = <PokemonDatabaseIndexEntry>[];
    for (final relativePath in await _listJsonRelativePaths(
      workspace,
      trimmedDirectory,
      label: 'Pokemon species directory',
    )) {
      final species = await _readSpeciesAtRelativePath(
        workspace,
        relativePath,
      );
      final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
        species,
        relativePath: relativePath,
      );

      // Le lot 11 ne doit plus accepter silencieusement une espèce parseable
      // mais inutilisable pour la future liste. On vérifie donc ici le contrat
      // minimal exact de l'index local.
      _validateSpeciesForDatabaseIndex(
        species: species,
        speciesIndexEntry: speciesIndexEntry,
        relativePath: relativePath,
      );

      entries.add(
        PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: speciesIndexEntry,
          species: species,
        ),
      );
    }

    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });

    return entries;
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return _readSpeciesAtRelativePath(workspace, relativePath);
  }

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/learnsets',
      label: 'Pokemon learnsets directory',
    );
  }

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/evolutions',
      label: 'Pokemon evolutions directory',
    );
  }

  Future<List<String>> listMediaIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/media',
      label: 'Pokemon media directory',
    );
  }

  Future<String?> resolveSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
          'Pokemon species id cannot be empty');
    }

    final speciesDir = _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      return null;
    }

    final matches = <String>[];

    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      final relativePath =
          p.normalize(p.relative(entity.path, from: workspace.projectRoot));

      // Le basename ne suffit pas ici : un fichier peut s'appeler
      // `9999-bulbasaur.json` tout en déclarant en réalité `"id": "ivysaur"`.
      // Pour la résolution d'un overwrite species, la seule source de vérité
      // acceptable est donc l'id réellement stocké dans le JSON.
      //
      // On choisit volontairement la correction la plus sûre :
      // - on lit chaque JSON species ;
      // - on ignore silencieusement les fichiers invalides / non objets /
      //   sans `id` exploitable ;
      // - on ne compte comme match que les fichiers qui déclarent exactement
      //   l'id demandé.
      //
      // Cette approche évite les faux positifs de basename et garde le writer
      // ainsi que l'import externe cohérents avec la merge policy annoncée.
      final declaredId = await _readDeclaredSpeciesId(entity);
      if (declaredId == trimmedId) {
        matches.add(relativePath);
      }
    }

    matches.sort();
    final uniqueMatches = matches.toSet().toList(growable: false)..sort();

    if (uniqueMatches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "$trimmedId": '
        '${uniqueMatches.join(', ')}',
      );
    }

    if (uniqueMatches.isEmpty) {
      return null;
    }

    return uniqueMatches.single;
  }

  Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = <PokemonSpeciesIndexEntry>[];
    for (final relativePath in await listSpeciesFiles(workspace)) {
      final species = await _readSpeciesAtRelativePath(workspace, relativePath);
      entries.add(
        PokemonSpeciesIndexEntry.fromSpeciesFile(
          species,
          relativePath: relativePath,
        ),
      );
    }
    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });
    return entries;
  }

  Future<PokemonSpeciesFile> _readSpeciesAtRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon species file',
    );
    return PokemonSpeciesFile.fromJson(json);
  }

  void _validateSpeciesForDatabaseIndex({
    required PokemonSpeciesFile species,
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required String relativePath,
  }) {
    // Cette validation reste volontairement petite. Elle ne remplace pas le
    // validateur Pokémon global : elle protège seulement le contrat minimal
    // exigé par l'index local du lot 11.
    if (speciesIndexEntry.id.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty id: $relativePath',
      );
    }

    if (speciesIndexEntry.nationalDex <= 0) {
      throw EditorPersistenceException(
        'Pokemon species index file must define nationalDex > 0: $relativePath',
      );
    }

    if (speciesIndexEntry.primaryName.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define an exploitable primary name: '
        '$relativePath',
      );
    }

    _validateDatabaseIndexRef(
      value: species.refs.learnset,
      refName: 'refs.learnset',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.refs.evolution,
      refName: 'refs.evolution',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.refs.media,
      refName: 'refs.media',
      relativePath: relativePath,
    );
  }

  void _validateDatabaseIndexRef({
    required String value,
    required String refName,
    required String relativePath,
  }) {
    if (value.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty $refName: '
        '$relativePath',
      );
    }
  }

  Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final matches = (await _buildSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == speciesId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$speciesId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    return matches.single;
  }

  Directory _speciesDirectory(ProjectWorkspace workspace) {
    return Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
  }

  Future<List<String>> _listJsonRelativePaths(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final directory = Directory(
      workspace.resolveProjectRelativePath(relativeDirectory),
    );
    if (!await directory.exists()) {
      throw EditorNotFoundException('$label not found in project workspace');
    }

    final relativePaths = <String>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      relativePaths.add(
        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
      );
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<String>> _listJsonFileStemIds(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final relativePaths = await _listJsonRelativePaths(
      workspace,
      relativeDirectory,
      label: label,
    );
    return relativePaths
        .map((relativePath) => p.basenameWithoutExtension(relativePath))
        .toList(growable: false);
  }

  Future<String?> _readDeclaredSpeciesId(File file) async {
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final declaredId = decoded['id'];
      if (declaredId is! String) {
        return null;
      }

      final trimmedId = declaredId.trim();
      if (trimmedId.isEmpty) {
        return null;
      }

      // Un fichier mal formé ou non concerné ne doit pas bloquer la résolution
      // d'une autre espèce. On remonte seulement les vrais doublons d'id.
      return trimmedId;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>> _readJsonFile(
    ProjectWorkspace workspace,
    String relativePath, {
    required String label,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw EditorNotFoundException('$label not found: $relativePath');
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          '$label is not a JSON object: $relativePath',
        );
      }
      return decoded;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read $label at $relativePath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in $label at $relativePath: $error',
      );
    }
  }
}
```

### 10.2 `packages/map_editor/test/file_pokemon_write_repository_test.dart`

```dart
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
```

### 10.3 `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
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

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
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
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon payload not found for species "bulbasaur"',
          ),
        ),
      );
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
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;

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

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
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
```

### 10.4 `reports/pokedex-phase-7b-species-overwrite-final-fix-report.md`

Le contenu complet de ce fichier est précisément ce document.

## 11. Checklist finale

- [x] Je n’ai corrigé que le faux positif restant de résolution species
- [x] Je n’ai pas commencé les lots 37+
- [x] Je n’ai pas touché l’UI
- [x] Je n’ai pas touché `project.json`
- [x] Je n’ai pas modifié de fichiers hors scope sans justification forte
- [x] La résolution finale repose sur l’id JSON réel, pas sur le basename
- [x] Un fichier mal nommé avec un autre id n’est plus compté comme match
- [x] Un vrai doublon d’id déclenche bien un conflit
- [x] `saveSpecies()` réutilise toujours le bon chemin existant
- [x] `overwriteExisting` ne crée plus de doublon canonique parasite
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le code est formaté
- [x] Le rapport markdown a été créé
- [x] Le rapport contient le contenu complet de tous les fichiers touchés
- [x] Aucune commande Git d’écriture n’a été exécutée
