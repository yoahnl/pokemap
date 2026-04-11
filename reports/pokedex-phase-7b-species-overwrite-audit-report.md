# Pokédex Phase 7B — Species Overwrite Audit Report

## 1. Résumé exécutif honnête

Le bug existe vraiment.

`FilePokemonWriteRepository.saveSpecies(...)` tente bien de réutiliser le chemin existant d'une espèce déjà présente. Le problème venait du lookup sous-jacent : `PokemonProjectDataReader.resolveSpeciesRelativePathById(...)` ne reconnaissait que certains noms de fichiers compatibles avec le pattern canonique.

Conséquence concrète avant correctif :
- l'import externe en `overwriteExisting` annonçait correctement un overwrite sur l'espèce ;
- mais si l'espèce existait déjà dans un fichier au nom non canonique, le lookup ne retrouvait pas ce fichier ;
- le writer recalculait alors un chemin canonique neuf ;
- un second fichier espèce était créé ;
- on obtenait ensuite un conflit de lecture avec deux fichiers partageant le même `id`.

Le correctif appliqué est minimal :
- aucun changement dans l'API publique ;
- aucun changement dans `project.json` ;
- aucun changement dans l'UI ;
- aucun changement dans les convertisseurs 28 à 33 ;
- correction localisée dans le reader utilisé par le writer et par l'orchestration d'import externe ;
- ajout de deux tests ciblés de preuve.

## 2. Diagnostic précis

### 2.1 Ce que fait réellement `saveSpecies()`

Audit réel :
- `FilePokemonWriteRepository.saveSpecies(...)` appelle `_resolveSpeciesWritePath(...)`.
- `_resolveSpeciesWritePath(...)` appelle `reader.resolveSpeciesRelativePathById(workspace, trimmedId)`.
- si ce reader renvoie un chemin existant, le writer le réutilise ;
- sinon le writer retombe sur le chemin canonique `data/pokemon/species/<dex>-<slug>.json`.

Donc :
- `saveSpecies()` ne recalcule pas aveuglément un chemin canonique ;
- il essaie d'abord de réutiliser l'existant ;
- la fidélité de la merge policy dépend entièrement de la qualité du lookup par id.

### 2.2 Le vrai défaut

`PokemonProjectDataReader.resolveSpeciesRelativePathById(...)` ne regardait initialement que le basename du fichier :
- `basename == <id>.json`
- ou `basename.endsWith(-<id>.json)`

Ce comportement rate un cas réel :
- fichier existant : `data/pokemon/species/0001-bulbizarre-custom.json`
- contenu JSON : `"id": "bulbasaur"`

Dans ce cas :
- le reader renvoie `null` ;
- l'import externe planifie alors `data/pokemon/species/0001-bulbasaur.json` ;
- `saveSpecies()` suit la même logique et écrit aussi dans ce nouveau chemin ;
- le fichier existant non canonique reste en place ;
- on se retrouve avec deux fichiers différents pour `bulbasaur`.

### 2.3 Preuve réelle observée

Le nouveau test ciblé ajouté dans `import_external_pokemon_use_cases_test.dart` a d'abord échoué avec l'erreur suivante :

```text
Multiple Pokemon species files share the same id "bulbasaur": data/pokemon/species/0001-bulbasaur.json, data/pokemon/species/0001-bulbizarre-custom.json
```

Conclusion :
- le bug est réel ;
- la merge policy `overwriteExisting` n'était pas pleinement fidèle dans ce cas non canonique ;
- le défaut n'était pas dans le contrat annoncé, mais dans la résolution incomplète du chemin existant.

## 3. Conclusion claire

Conclusion finale : **bug réel confirmé et réparé**.

Après correctif :
- `saveSpecies()` réutilise bien un fichier déjà présent même si son slug/filename n'est pas canonique, tant que le JSON déclaré porte bien le même `id` ;
- aucun fichier canonique parasite n'est créé dans ce cas ;
- le comportement de création d'une espèce absente reste inchangé ;
- le flux d'import externe `overwriteExisting` devient cohérent avec ce qu'il annonce.

## 4. Justification fichier par fichier

### 4.1 Modifié — `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

Pourquoi touché :
- c'est la vraie source du bug ;
- le writer et l'import externe s'appuient tous deux dessus pour résoudre le chemin courant d'une espèce.

Ce qui a changé :
- conservation du fast-path historique par nom de fichier canonique ;
- ajout d'un fallback minimal qui lit le JSON pour comparer l'`id` réel quand le nom de fichier ne suffit pas ;
- fallback volontairement tolérant aux JSON invalides / hors contrat pour ne pas casser les réécritures en présence de fichiers non liés corrompus ;
- déduplication et détection explicite des conflits si plusieurs fichiers déclarent le même `id`.

Pourquoi c'est le plus petit correctif raisonnable :
- aucune API nouvelle ;
- pas de changement dans `saveSpecies()` ;
- pas de changement dans l'orchestration externe ;
- correction de la racine du problème au point commun des deux chemins de code.

### 4.2 Modifié — `packages/map_editor/test/file_pokemon_write_repository_test.dart`

Pourquoi touché :
- il fallait prouver le comportement du writer lui-même, indépendamment de l'orchestration externe.

Ce qui a été ajouté :
- un test qui prépare un fichier existant non canonique ;
- un appel direct à `saveSpecies()` ;
- une vérification que le chemin existant est réutilisé ;
- une vérification qu'aucun second fichier canonique n'est créé.

### 4.3 Modifié — `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

Pourquoi touché :
- il fallait prouver le comportement applicatif réellement annoncé par la merge policy Phase 7B.

Ce qui a été ajouté :
- un test `overwriteExisting` avec une espèce déjà présente dans un chemin non canonique ;
- une vérification que l'artefact reporté pointe bien vers le vrai fichier existant ;
- une vérification qu'aucun doublon canonique n'est créé ;
- une vérification que `project.json` reste inchangé.

### 4.4 Créé — `reports/pokedex-phase-7b-species-overwrite-audit-report.md`

Pourquoi créé :
- pour documenter honnêtement l'audit, la preuve du bug, le correctif minimal, les commandes exécutées et le contenu complet des fichiers touchés.

### 4.5 Audités mais non touchés

Ces fichiers ont été lus pour établir le diagnostic, mais n'ont pas été modifiés :
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

Pourquoi ils n'ont pas été modifiés :
- le bug n'était pas dans leur logique principale ;
- ils faisaient déjà confiance au reader pour résoudre le chemin existant ;
- corriger le reader suffisait à rendre leur comportement cohérent.

## 5. Liste exacte des fichiers modifiés / créés / non touchés

### Modifiés
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

### Créé
- `reports/pokedex-phase-7b-species-overwrite-audit-report.md`

### Audités mais non touchés
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

## 6. Commandes réellement exécutées

### Audit initial

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '240,430p' lib/src/infrastructure/repositories/file_repositories.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '180,340p' lib/src/application/use_cases/import_external_pokemon_use_cases.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,340p' test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,320p' test/file_pokemon_write_repository_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '260,520p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
rg -n "resolveSpeciesRelativePathById|Multiple Pokemon species files match the id|does not create duplicate when species slug changes|bulbizarre-custom" /Users/karim/Project/pokemonProject/packages/map_editor/test /Users/karim/Project/pokemonProject/packages/map_editor/lib/src -S
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '260,380p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
```

### Format / validation intermédiaires

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/file_pokemon_write_repository_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub test/import_external_pokemon_use_cases_test.dart
```

### Correctif + format final

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/file_pokemon_write_repository_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart test/import_external_pokemon_use_cases_test.dart test/file_pokemon_write_repository_test.dart
```

### État Git utile

```bash
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/file_pokemon_write_repository_test.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/pokedex-phase-7b-species-overwrite-audit-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/file_pokemon_write_repository_test.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart reports/pokedex-phase-7b-species-overwrite-audit-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- reports/pokedex-phase-7b-species-overwrite-audit-report.md
```

## 7. Résultats réels

### 7.1 `dart format` intermédiaire sur le test externe

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

### 7.2 Première passe de tests — preuve du bug

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/file_pokemon_write_repository_test.dart
```

Résultat utile :
- la nouvelle preuve d'overwrite non canonique a échoué ;
- l'échec montrait que deux fichiers species existaient désormais pour `bulbasaur`.

Message clé observé :

```text
Multiple Pokemon species files share the same id "bulbasaur": data/pokemon/species/0001-bulbasaur.json, data/pokemon/species/0001-bulbizarre-custom.json
```

### 7.3 Analyse intermédiaire

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub test/import_external_pokemon_use_cases_test.dart
```

Résultat :

```text
No issues found! (ran in 1.5s)
```

### 7.4 `dart format` final

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
Formatted 3 files (1 changed) in 0.02 seconds.
```

### 7.5 `flutter test` final

```text
00:01 +22: All tests passed!
```

### 7.6 `flutter analyze --no-pub` final

```text
No issues found! (ran in 0.9s)
```

## 8. Incidents rencontrés

### Incident réel

Le nouveau test de preuve a échoué avant le correctif.

Ce n'était pas un faux négatif :
- il démontrait exactement le défaut soupçonné ;
- le writer écrivait bien un second fichier canonique quand le fichier déjà existant portait un nom non canonique ;
- la lecture par `id` devenait ensuite conflictuelle.

### Correction appliquée

Au lieu de modifier le writer ou l'orchestrateur externe, le correctif a été appliqué dans la résolution du chemin existant :
- fast-path inchangé sur les basenames canoniques ;
- fallback minimal sur l'`id` réel déclaré dans le JSON ;
- tolérance aux fichiers invalides non liés pour ne pas casser d'autres cas déjà couverts.

## 9. État Git utile

L'état Git utile final est documenté après création de ce rapport.

## 10. Limites restantes

Ce mini-fix reste volontairement petit.

Ce qu'il ne fait pas :
- il ne renomme pas les fichiers existants non canoniques ;
- il ne lance aucun nettoyage automatique des doublons déjà présents dans un workspace ;
- il ne change pas la convention de nommage des species ;
- il ne touche pas à la merge policy elle-même, seulement à la fidélité de sa résolution de chemin ;
- il ne modifie pas les lots 28 à 33 ni 37+.

## 11. Contenu complet de tous les fichiers modifiés / créés

### 11.1 `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

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

    final normalizedId = _sanitizeSpeciesFileSegment(trimmedId);
    final matches = <String>[];

    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;

      final relativePath =
          p.normalize(p.relative(entity.path, from: workspace.projectRoot));
      final basename = p.basename(entity.path).toLowerCase();

      // Chemin rapide historique : si le nom de fichier suit déjà la
      // convention attendue, on peut le reconnaître sans relire son contenu.
      if (basename == '$normalizedId.json' ||
          basename.endsWith('-$normalizedId.json')) {
        matches.add(relativePath);
        continue;
      }

      // Le writer et l'import externe doivent aussi respecter un fichier déjà
      // présent quand son slug a divergé du nom canonique courant.
      // On ne peut donc pas se limiter au basename : on lit alors le JSON pour
      // comparer l'id réel stocké. Cette lecture reste volontairement tolérante
      // : un fichier JSON invalide ou hors contrat ne doit pas empêcher
      // l'écrasement d'une espèce valide déjà présente ailleurs.
      if (await _speciesFileDeclaresId(entity, trimmedId)) {
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

  String _sanitizeSpeciesFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<bool> _speciesFileDeclaresId(File file, String speciesId) async {
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final declaredId = decoded['id'];
      return declaredId is String && declaredId.trim() == speciesId;
    } on FileSystemException {
      return false;
    } on FormatException {
      return false;
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

### 11.2 `packages/map_editor/test/file_pokemon_write_repository_test.dart`

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
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await conflictingFile.parent.create(recursive: true);
      await conflictingFile.writeAsString('''
{
  "id": "something_else"
}
''');

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

### 11.3 `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

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

### 11.4 `reports/pokedex-phase-7b-species-overwrite-audit-report.md`

Le contenu complet de ce fichier est exactement ce document.

## 12. Checklist finale

- [x] Je n’ai pas commencé les lots 37+
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state UI
- [x] Je n’ai pas touché `project.json`
- [x] Je n’ai pas créé de framework générique spéculatif
- [x] J’ai audité le vrai comportement de `saveSpecies()`
- [x] J’ai audité la façon dont l’import externe appelle ce comportement
- [x] J’ai confirmé un bug réel au lieu d’une hypothèse
- [x] J’ai appliqué le plus petit correctif raisonnable
- [x] Je n’ai touché aucun fichier hors besoin strict sans le documenter
- [x] J’ai ajouté des tests ciblés utiles
- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Je n’ai exécuté aucune commande Git d’écriture
- [x] Le rapport final contient le contenu complet de tous les fichiers touchés
