# Lot 5 — Lecture Dart des JSON Pokémon depuis le workspace projet

## 1. Résumé exécutif

Ce lot ajoute une première couche Dart de lecture locale des données Pokémon stockées dans le **workspace projet utilisateur**, via `map_editor`.

Ce qui a été fait :

- création de modèles Dart minimaux pour lire le manifeste, les catalogues, les espèces, les learnsets et les évolutions déjà présents dans le dataset de démonstration ;
- création d’un lecteur local `PokemonProjectDataReader` qui résout tous les chemins à partir de `ProjectWorkspace.projectRoot` ;
- ajout de tests ciblés pour la lecture, les références croisées, les erreurs explicites, l’isolation vis-à-vis de `Directory.current`, et l’invariance de `project.json`.

Ce qui n’a pas été fait :

- aucune UI ;
- aucun provider ;
- aucun import Showdown / PokeAPI ;
- aucune modification de `project.json` ;
- aucun changement runtime, combat, équipe, sac ou sauvegarde ;
- aucune nouvelle donnée seed au-delà du mini dataset déjà en place.

## 2. État de départ

Avant ce lot, le projet disposait déjà de :

- un use case d’initialisation du stockage Pokémon dans le workspace projet ;
- un contrat JSON minimal pour le manifeste et les catalogues ;
- un mini dataset de démonstration avec :
  - `species/`
  - `learnsets/`
  - `evolutions/`
  - des catalogues minimums enrichis.

Point fondamental conservé dans ce lot :

- les JSON Pokémon vivent **dans le workspace projet utilisateur** ;
- ils ne vivent **pas** à la racine du monorepo source ;
- la lecture doit donc toujours passer par `ProjectWorkspace`.

## 3. Modèles créés

Fichier créé :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

Rôle de chaque modèle :

- `PokemonDataMeta`
  - métadonnées communes aux fichiers JSON Pokémon locaux (`description`, `sourcePriority`, `notes`) ;
- `PokemonDataManifest`
  - lecture du manifeste racine `data/pokemon/pokemon_data_manifest.json` ;
- `PokemonCatalogFile`
  - lecture générique d’un catalogue JSON (`schemaVersion`, `kind`, `catalog`, `meta`, `entries`) ;
  - `entries` reste volontairement en JSON brut typé `List<Map<String, dynamic>>` pour éviter une sur-modélisation prématurée ;
- `PokemonSpeciesTyping`
  - lecture de `typing.types` ;
- `PokemonSpeciesBaseStats`
  - lecture des stats de base seedées ;
- `PokemonSpeciesAbilities`
  - lecture des talents principaux / secondaires / cachés ;
- `PokemonSpeciesBreeding`
  - lecture minimale des données de reproduction présentes dans le dataset ;
- `PokemonSpeciesProgression`
  - lecture minimale des données de progression présentes dans le dataset ;
- `PokemonSpeciesFile`
  - lecture du contrat espèce réellement seedé ;
- `PokemonLearnsetLevelUpEntry`
  - lecture explicite de `moveId`, `level`, `source`, `versionGroup` ;
- `PokemonLearnsetFile`
  - lecture du learnset minimal séparé ;
- `PokemonEvolutionEntry`
  - lecture d’une entrée d’évolution ;
- `PokemonEvolutionFile`
  - lecture du fichier d’évolution par espèce.

### Extrait clé — modèle learnset

```dart
class PokemonLearnsetLevelUpEntry {
  const PokemonLearnsetLevelUpEntry({
    required this.moveId,
    required this.level,
    required this.source,
    required this.versionGroup,
  });

  final String moveId;
  final int level;
  final String source;
  final String versionGroup;
}
```

Ce point est volontairement explicite, car l’objectif métier du lot est bien de pouvoir lire clairement : **quelle attaque est apprise à quel niveau**.

## 4. Couche de lecture créée

Fichier créé :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

API exposée :

- `readManifest(ProjectWorkspace workspace)`
- `readCatalogByKey(ProjectWorkspace workspace, String catalogKey)`
- `readSpeciesById(ProjectWorkspace workspace, String speciesId)`
- `readLearnsetById(ProjectWorkspace workspace, String speciesId)`
- `readEvolutionById(ProjectWorkspace workspace, String speciesId)`
- `listSpeciesFiles(ProjectWorkspace workspace)`

### Choix de conception

- tous les chemins sont résolus via `workspace.resolveProjectRelativePath(...)` ;
- aucun fallback vers `Directory.current` ;
- aucune lecture à partir de la racine du monorepo ;
- aucune lecture de configuration Pokémon depuis `project.json` ;
- pas de couche d’abstraction supplémentaire inutile ;
- pas de typage excessif des catalogues globaux à ce stade.

### Pourquoi ce n’est pas branché à l’UI

Le lot 5 est volontairement un lot d’infrastructure locale et de lecture Dart.  
Le lecteur est prêt à être consommé plus tard par une UI ou par un service applicatif plus haut niveau, mais ce branchement n’est pas fait ici pour rester strictement dans le périmètre.

### Extrait clé — invariant de lecture

```dart
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites
class PokemonProjectDataReader {
  const PokemonProjectDataReader();
```

### Extrait clé — résolution d’un catalogue depuis le manifeste

```dart
final manifest = await readManifest(workspace);
final relativePath = manifest.catalogFiles[catalogKey];
if (relativePath == null || relativePath.trim().isEmpty) {
  throw EditorNotFoundException(
    'Pokemon catalog not declared in manifest: $catalogKey',
  );
}
```

## 5. Gestion des erreurs

Le lecteur s’appuie sur les erreurs applicatives déjà existantes dans :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/errors/application_errors.dart`

Erreurs réellement levées :

- `EditorValidationException`
  - si un id demandé est vide (`speciesId`, `learnset id`, `evolution id`) ;
- `EditorNotFoundException`
  - si le manifeste est absent ;
  - si un fichier espèce / learnset / évolution est absent ;
  - si un catalogue demandé n’est pas déclaré dans le manifeste ;
  - si le dossier `data/pokemon/species` n’existe pas ;
- `EditorPersistenceException`
  - si un fichier JSON est invalide ;
  - si un fichier JSON n’est pas un objet ;
  - si une lecture fichier échoue côté filesystem.

Le comportement voulu ici est explicite :

- pas de `null` silencieux ;
- pas de fallback implicite ;
- pas de “best effort” ambigu.

## 6. Tests

Fichier créé :

- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`

Cas couverts :

1. lecture du manifeste ;
2. lecture d’une espèce (`bulbasaur`) ;
3. lecture d’un learnset avec niveaux explicites ;
4. lecture d’une évolution ;
5. lecture d’un catalogue (`moves`) ;
6. listage des fichiers espèces ;
7. erreur explicite si espèce absente ;
8. erreur explicite si catalogue inconnu ;
9. erreur explicite si JSON invalide ;
10. garde-fou : la lecture reste ancrée au workspace même si `Directory.current` pointe ailleurs ;
11. vérification que `project.json` reste strictement inchangé après lecture.

### Résultat réel des tests

Commande exécutée :

```bash
flutter test test/pokemon_project_data_reader_test.dart
```

Résultat :

- succès ;
- 11 tests passés ;
- aucune erreur.

## 7. Analyse

Commande exécutée :

```bash
flutter analyze --no-pub \
  lib/src/application/models/pokemon_project_data_models.dart \
  lib/src/application/services/pokemon_project_data_reader.dart \
  test/pokemon_project_data_reader_test.dart
```

Résultat réel :

- `No issues found!`

## 8. Preuves de périmètre

### 8.1 `project.json` reste inchangé

Le test `leaves project.json strictly unchanged after reads` :

- crée un vrai projet via le flux existant ;
- lit le contenu brut de `project.json` ;
- exécute plusieurs lectures Pokémon ;
- relit `project.json` ;
- compare les deux chaînes à l’identique.

Le test passe.

### 8.2 Rien n’est créé à la racine du monorepo

Commande exécutée :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Résultat réel :

- aucune sortie ;
- donc aucun dossier `./data` ou `./assets` n’a été recréé à la racine du repo par ce lot.

### 8.3 La lecture ne dépend pas de `Directory.current`

Le test dédié :

- crée un faux arbre `data/pokemon/species/...` dans un autre dossier temporaire ;
- force `Directory.current` vers ce dossier leurre ;
- vérifie que le lecteur continue à lire uniquement le workspace projet transmis.

Le test passe.

## 9. Fichiers créés / modifiés dans le code

### Fichiers créés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`

### Fichiers non modifiés volontairement

- aucun fichier UI ;
- aucun provider ;
- aucun runtime ;
- aucun `project.json` ;
- aucun use case de seed ou d’initialisation Pokémon ;
- aucun modèle Dart Pokémon exhaustif hors lecture minimale.

## 10. Commandes réellement exécutées

Liste des commandes réellement lancées pour ce lot :

```bash
sed -n '1,260p' packages/map_editor/lib/src/application/errors/application_errors.dart
find packages/map_editor/lib/src -maxdepth 3 -type d | sort
rg -n "fromJson\\(|jsonDecode\\(|JsonEncoder|JsonSerializable|freezed" packages/map_editor/lib/src -g '!**/*.g.dart' -g '!**/*.freezed.dart'
git status --short
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
sed -n '1,360p' packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/use_cases.dart
flutter test test/pokemon_project_data_reader_test.dart
flutter analyze --no-pub lib/src/application/models/pokemon_project_data_models.dart lib/src/application/services/pokemon_project_data_reader.dart test/pokemon_project_data_reader_test.dart
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
git status --short
git diff --stat -- packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/pokemon_project_data_reader_test.dart reports/pokemon-local-readers-lot-5-report.md
git status --short -- packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/pokemon_project_data_reader_test.dart reports/pokemon-local-readers-lot-5-report.md
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/test/pokemon_project_data_reader_test.dart reports/pokemon-local-readers-lot-5-report.md
./review_bundle.sh
cat .review/review-20260408-215056.txt
sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1,320p' packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '1,360p' packages/map_editor/test/pokemon_project_data_reader_test.dart
```

## 11. Git diff / état Git

### `git status --short`

Sortie finale observée après création de ce rapport :

```text
?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart
?? reports/pokemon-local-readers-lot-5-report.md
```

### État Git ciblé du lot

Sortie finale observée après création de ce rapport :

```text
?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart
?? reports/pokemon-local-readers-lot-5-report.md
```

### `git diff --stat`

Commande exécutée :

```bash
git diff --stat -- \
  packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart \
  packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart \
  packages/map_editor/test/pokemon_project_data_reader_test.dart \
  reports/pokemon-local-readers-lot-5-report.md
```

Sortie réelle :

```text

```

Explication honnête :

- `git diff --stat` est vide ici parce que les fichiers du lot étaient encore **non suivis** au moment de la commande ;
- Git ne montre pas de diff standard pour des fichiers untracked dans cette commande ;
- on complète donc volontairement avec `git status --short` et `git ls-files --others --exclude-standard`.

### `git ls-files --others --exclude-standard`

Sortie finale observée après création de ce rapport :

```text
packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
packages/map_editor/test/pokemon_project_data_reader_test.dart
reports/pokemon-local-readers-lot-5-report.md
```

## 12. `./review_bundle.sh`

Commande exécutée :

```bash
./review_bundle.sh
```

Chemin du fichier généré :

- `.review/review-20260408-215056.txt`

Contenu intégral du fichier généré :

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 21:50:56
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: f808d3f994753a0fd443a0b82b338b9cae1ca3ac

## GIT STATUS --SHORT

?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart

## GIT DIFF --STAT


## CHANGED FILES


## RECENT COMMITS

f808d3f Seed Pokémon demo data use case with idempotent JSON generation
c4d2983 Enrich Pokémon JSON storage contract with manifest and minimal catalog structures
e266743 Add use case to initialize Pokémon project storage structure
c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor
5d65444 Add element collision editor UI and rasterization services
e63e6cf Add element collision authoring services and padding-based workflow
5f714b5 Persist last opened project state and add auto-restore support
7a137dd Remove LOT 50 demo scenario and inject logic; add FPS overlay support
13127d3 Implement runtime completion gating for cutscenes in Step Studio

## FULL DIFF
```

Note honnête :

- le bundle reflète uniquement les fichiers connus de Git au moment de son exécution ;
- comme ce lot repose sur des fichiers non suivis, `GIT DIFF --STAT` et `CHANGED FILES` restent vides ;
- le bundle a été généré **avant** l’écriture du présent rapport, donc le rapport lui-même n’y figure pas, même si le relevé Git final ci-dessus l’inclut bien.

## 13. Explication du code

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

Ce fichier introduit des modèles manuels de lecture, volontairement petits, alignés sur le dataset actuel :

- pas de `build_runner` ;
- pas de code généré ;
- pas de schéma spéculatif gigantesque ;
- juste le minimum pour lire proprement les JSON réellement présents.

Le choix important ici est de garder :

- les catalogues en JSON brut typé minimalement ;
- certaines sous-structures d’espèce en `Map<String, dynamic>` quand elles ne sont pas encore utiles à typer davantage.

Cela permet une lecture robuste sans figer trop tôt un modèle qui évoluera encore aux prochains lots.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

Ce fichier fournit la première vraie porte d’entrée Dart vers les données Pokémon locales d’un projet utilisateur.

Choix importants :

- le manifeste pilote l’accès logique aux catalogues ;
- la lecture d’espèce se fait par `id` métier, pas par supposition fragile sur le nom de fichier ;
- les erreurs sont explicites ;
- la résolution des chemins est toujours relative au workspace projet.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`

Ce fichier verrouille le comportement du lot :

- lecture réussie sur le mini dataset ;
- références croisées cohérentes ;
- niveaux de learnset lisibles ;
- erreurs claires si le fichier manque ou si le JSON est cassé ;
- garde-fou contre toute dérive vers `Directory.current` ou la racine du monorepo ;
- preuve que `project.json` n’est pas touché.

## 14. Mini résumé final

### Ce qui a été fait

- modèles Dart minimaux de lecture Pokémon ;
- lecteur local workspace-first ;
- erreurs explicites ;
- tests ciblés ;
- validations ciblées ;
- rapport détaillé.

### Ce qui n’a pas été fait

- aucune UI ;
- aucun provider ;
- aucun import externe ;
- aucun runtime ;
- aucune modification de `project.json` ;
- aucune extension de seed ;
- aucune architecture Pokémon lourde.
