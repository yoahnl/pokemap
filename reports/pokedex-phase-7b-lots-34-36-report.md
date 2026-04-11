# Pokédex Phase 7B — Lots 34 à 36

## 1. Résumé exécutif honnête

La phase 7B est maintenant implémentée sur un périmètre strict :
- lot 34 : import externe unitaire d’une espèce avec `species`, `learnset`, `evolution`, `media`
- lot 35 : import batch de plusieurs espèces avec résultat détaillé par espèce
- lot 36 : `dry-run`, `merge policy`, rapport d’actions/conflits, zéro écriture en mode dry-run

Ce qui a été ajouté :
- un port applicatif minimal pour lire les payloads externes ;
- une orchestration applicative unique et compacte qui réutilise strictement les convertisseurs 28 à 33 ;
- une merge policy minimale et lisible ;
- des résultats structurés pour l’unitaire et le batch ;
- une suite de tests ciblés, sans réseau réel ;
- un rapport complet.

Ce qui n’a pas été fait volontairement :
- aucune UI ;
- aucun provider/notifier/state UI ;
- aucun client HTTP concret ;
- aucun réseau réel dans les tests ;
- aucune écriture dans `project.json` ;
- aucun lot 37+ ;
- aucun framework générique surdimensionné.

## 2. Périmètre exact inclus

- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `reports/pokedex-phase-7b-lots-34-36-report.md`

## 3. Périmètre exact exclu

- UI
- providers / notifiers / state UI
- runtime
- save gameplay
- `project.json`
- clients HTTP concrets
- réseau réel dans les tests
- imports externes de catalogues globaux
- lots 37+
- refactor large des convertisseurs 28-33
- refonte des repositories existants
- batch parallèle

## 4. Architecture retenue

### 4.1 Frontière externe minimale

J’ai ajouté un port unique :
- `PokemonExternalSourceRepository`

Il fournit exactement ce dont l’orchestration a besoin :
- payload Showdown espèce
- payload PokeAPI `/pokemon/{id}` pour le learnset
- payload PokeAPI de chaîne d’évolution

Rien de plus.

Je n’ai pas ajouté :
- de client HTTP concret
- de cache
- de port batch
- de logique réseau

### 4.2 Use cases

J’ai gardé exactement deux use cases publics dans un seul fichier :
- `ImportExternalPokemonSpeciesUseCase`
- `BatchImportExternalPokemonSpeciesUseCase`

Le premier couvre les lots 34 et 36 :
- lecture des payloads externes
- conversion via les services 28-33
- planification des artefacts locaux
- application de la merge policy
- support du dry-run sans écriture

Le second couvre le lot 35 :
- normalisation déterministe de la liste d’ids
- enchaînement séquentiel de l’unitaire
- résultat détaillé par espèce
- succès partiels sans masquer les erreurs

### 4.3 Merge policy

J’ai retenu exactement trois politiques :
- `failOnConflict`
- `skipExisting`
- `overwriteExisting`

Sémantique :
- `failOnConflict` : si au moins une cible existe, l’import unitaire retourne un rapport de conflit et n’écrit rien
- `skipExisting` : les artefacts existants sont signalés `skip`, les artefacts absents sont créés
- `overwriteExisting` : les artefacts existants sont signalés `overwrite` et réécrits

### 4.4 Dry-run

Le dry-run :
- lit vraiment les payloads externes ;
- convertit vraiment les données ;
- résout vraiment les chemins cibles ;
- détecte vraiment les conflits ;
- retourne un vrai rapport d’actions prévues ;
- n’écrit rien du tout sur disque.

### 4.5 Convention de path species

Pour rester cohérent avec `FilePokemonWriteRepository`, l’orchestration :
- réutilise le chemin existant si l’espèce existe déjà ;
- sinon prédit le chemin canonique `<dex>-<slug>.json`

Pour faire cela proprement sans modifier de port existant, j’ai réutilisé `PokemonProjectDataReader.resolveSpeciesRelativePathById(...)` depuis la couche applicative.

## 5. Justification fichier par fichier

### `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`

Pourquoi créé :
- le lot 34 a besoin d’une frontière applicative minimale pour lire les payloads externes ;
- les tests doivent pouvoir faker cette source sans réseau réel.

Pourquoi c’est minimal :
- un seul port ;
- trois méthodes ;
- aucune hypothèse transport.

### `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

Pourquoi créé :
- c’est le cœur des lots 34 à 36 ;
- il fallait une orchestration applicative explicite et locale.

Ce qui est dedans :
- merge policy
- résultats d’import
- use case unitaire
- use case batch

Pourquoi c’est le plus petit changement raisonnable :
- deux use cases publics seulement ;
- un seul fichier pour éviter l’éparpillement ;
- réutilisation stricte des convertisseurs existants ;
- délégation stricte de l’écriture au repository local.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Pourquoi modifié :
- pour exposer le nouveau fichier de use cases au même niveau que les autres use cases du package.

Pourquoi c’est acceptable :
- une seule ligne ;
- cohérent avec la convention déjà présente dans `map_editor`.

### `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

Pourquoi créé :
- pour couvrir le comportement réel des lots 34 à 36 avec un vrai workspace temporaire, un vrai repository d’écriture local et une fausse source externe.

Ce que le test prouve :
- import unitaire heureux
- batch heureux
- dry-run sans écriture
- `fail_on_conflict`
- `skip_existing`
- `overwrite_existing`
- erreur source sur une espèce
- succès partiels
- ordre déterministe du batch
- `project.json` inchangé

### `reports/pokedex-phase-7b-lots-34-36-report.md`

Pourquoi créé :
- pour documenter précisément la phase, les validations exécutées, l’état Git utile, les incidents intermédiaires et le contenu complet des fichiers touchés.

## 6. Commandes réellement exécutées

### Audit local

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/application/ports/pokemon_write_repository.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,240p' lib/src/application/ports/project_workspace.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/application/use_cases/import_pokemon_species_json_use_case.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/infrastructure/repositories/file_repositories.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '260,520p' lib/src/infrastructure/repositories/file_repositories.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,280p' lib/src/application/ports/pokemon_read_repository.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/application/use_cases/import_pokemon_media_json_use_case.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '220,280p' lib/src/application/services/pokemon_project_data_reader.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '1,260p' lib/src/application/use_cases/use_cases.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && rg -n "class Pokemon(CatalogFile|SpeciesFile|LearnsetFile|EvolutionFile|MediaFile|EvolutionEntry|MediaVariant|DataMeta)" lib/src/application/models/pokemon_project_data_models.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && sed -n '840,1320p' lib/src/application/models/pokemon_project_data_models.dart
```

### Validation

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/ports/pokemon_external_source_repository.dart lib/src/application/use_cases/import_external_pokemon_use_cases.dart lib/src/application/use_cases/use_cases.dart test/import_external_pokemon_use_cases_test.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/ports/pokemon_external_source_repository.dart lib/src/application/use_cases/import_external_pokemon_use_cases.dart lib/src/application/use_cases/use_cases.dart test/import_external_pokemon_use_cases_test.dart
```

### Lecture Git utile

```bash
git status --short -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports
git diff --stat -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports
```

## 7. Résultats réels des commandes

### `dart format ...` première passe

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart
Formatted 4 files (2 changed) in 0.02 seconds.
```

### `flutter test ...` première passe

```text
test/import_external_pokemon_use_cases_test.dart:216:15: Error: Couldn't find constructor 'ShowdownPokemonSpeciesConverter'.
test/import_external_pokemon_use_cases_test.dart:243:15: Error: Couldn't find constructor 'PokeApiPokemonLearnsetConverter'.
```

### `flutter analyze ...` première passe

```text
error • The name 'ShowdownPokemonSpeciesConverter' isn't a class • test/import_external_pokemon_use_cases_test.dart:216:15 • creation_with_non_type
error • The name 'PokeApiPokemonLearnsetConverter' isn't a class • test/import_external_pokemon_use_cases_test.dart:243:15 • creation_with_non_type

2 issues found. (ran in 2.2s)
```

### Correction intermédiaire appliquée

J’ai ajouté les imports manquants dans :
- `test/import_external_pokemon_use_cases_test.dart`

### `dart format ...` seconde passe

```text
Formatted 1 file (0 changed) in 0.02 seconds.
```

### `flutter test ...` passe finale

```text
00:01 +8: All tests passed!
```

### `flutter analyze --no-pub ...` passe finale

```text
No issues found! (ran in 1.0s)
```

## 8. État Git utile

### `git status --short -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports`

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
?? packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
?? packages/map_editor/test/import_external_pokemon_use_cases_test.dart
?? reports/pokedex-phase-7b-lots-34-36-report.md
```

### `git diff --stat -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports`

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

### `git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/ports packages/map_editor/lib/src/application/use_cases packages/map_editor/test reports`

```text
packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
packages/map_editor/test/import_external_pokemon_use_cases_test.dart
reports/pokedex-phase-7b-lots-34-36-report.md
```

Remarque honnête :
- le `git diff --stat -- ...` final ne montre qu’un seul fichier suivi, `use_cases.dart` ;
- les nouveaux fichiers du lot apparaissent dans `git ls-files --others --exclude-standard -- ...` parce qu’aucune commande Git d’écriture n’a été exécutée ;
- c’est exactement l’état attendu ici.

## 9. Incidents / corrections intermédiaires honnêtes

- Incident réel 1 :
  le nouveau fichier de test réutilisait deux convertisseurs réels sans importer leurs classes.
  Correction :
  ajout des imports manquants, puis relance de `dart format`, `flutter test` et `flutter analyze`.

- Incident réel 2 :
  `flutter analyze` a temporairement affiché `Waiting for another flutter command to release the startup lock...` parce que test et analyse avaient été lancés en parallèle.
  Correction :
  j’ai simplement laissé le lock se libérer puis attendu le résultat réel ; aucune modification de code n’était nécessaire.

- Sous-agents :
  des sous-agents ont été utilisés pour l’audit architecture, le design minimal, la stratégie de tests et la review de scope.
  Aucune variante concurrente n’a été laissée dans le working tree.

## 10. Limites restantes

- Aucun client HTTP concret n’est fourni dans cette phase.
- Le port externe est volontairement abstrait et les tests n’utilisent que des fakes.
- Le batch est séquentiel ; aucun parallélisme n’a été ajouté.
- La merge policy est volontairement simple et opère au niveau fichier/artefact, pas au niveau champ.
- Les catalogues globaux externes ne sont pas orchestrés dans cette phase 7B, car l’objectif fonctionnel demandé pour 34-36 portait sur `species`, `learnset`, `evolution`, `media`.

## 11. Contenu complet de tous les fichiers modifiés, créés ou supprimés

### 11.1 `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`

```dart
/// Frontière applicative minimale pour lire les payloads Pokémon externes.
///
/// Cette abstraction reste volontairement petite pour les lots 34 à 36 :
/// - une espèce Showdown pour le core species ;
/// - un payload PokeAPI `/pokemon/{id}` pour le learnset ;
/// - une chaîne d'évolution PokeAPI pour les évolutions.
///
/// Non-objectifs explicites :
/// - pas de client HTTP concret ici ;
/// - pas de logique de retry ;
/// - pas de cache ;
/// - pas de batch API ;
/// - pas de détails réseau dans les use cases.
///
/// Les tests utilisent des fakes de ce port. Le lot ne dépend donc d'aucun
/// réseau réel pour rester rapide, stable et reviewable.
abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );
}
```

### 11.2 `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokemon_media_stub_generator.dart';
import '../services/pokemon_project_data_reader.dart';
import '../services/showdown_pokemon_species_converter.dart';

/// Politique minimale de gestion des fichiers déjà présents dans le workspace.
///
/// On garde exactement trois comportements, parce que c'est le minimum
/// raisonnable demandé pour rendre l'import exploitable sans le transformer en
/// framework de synchronisation :
/// - `failOnConflict` : aucun artefact n'est écrit si au moins une cible existe ;
/// - `skipExisting` : les cibles existantes sont laissées intactes ;
/// - `overwriteExisting` : les cibles existantes sont remplacées explicitement.
enum PokemonExternalImportMergePolicy {
  failOnConflict,
  skipExisting,
  overwriteExisting,
}

/// Type d'artefact local produit par un import externe d'espèce.
///
/// L'ordre de déclaration est aussi l'ordre de reporting utilisé par les
/// résultats, pour garder des sorties lisibles et stables.
enum PokemonExternalImportArtifactKind {
  species,
  learnset,
  evolution,
  media,
}

/// Action retenue pour un artefact donné.
///
/// On reste volontairement sur les quatre états réellement utiles au lot :
/// - créer ;
/// - skip ;
/// - overwrite ;
/// - signaler un conflit.
enum PokemonExternalImportArtifactAction {
  create,
  skip,
  overwrite,
  conflict,
}

/// Résultat détaillé pour un artefact local.
///
/// Chaque artefact expose :
/// - son type ;
/// - le chemin relatif ciblé ;
/// - l'action retenue par la merge policy ;
/// - si un fichier existait déjà ;
/// - un message optionnel si une explication locale aide la review.
class PokemonExternalImportArtifactResult {
  const PokemonExternalImportArtifactResult({
    required this.kind,
    required this.relativePath,
    required this.action,
    required this.existedBefore,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final PokemonExternalImportArtifactAction action;
  final bool existedBefore;
  final String? message;
}

/// Résultat détaillé d'un import externe unitaire.
///
/// Le résultat est pensé pour être lisible directement en logs, tests ou futur
/// rapport d'import :
/// - l'espèce réellement produite ;
/// - la merge policy appliquée ;
/// - l'information dry-run ;
/// - les artefacts concernés ;
/// - d'éventuels warnings non bloquants.
class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.requestedSpeciesId,
    required this.importedSpeciesId,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<String> warnings;

  bool get hasConflicts => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.conflict,
      );

  bool get hasSkips => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get hasWritesApplied =>
      !dryRun &&
      artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.create ||
            artifact.action == PokemonExternalImportArtifactAction.overwrite,
      );

  bool get isFullySkipped =>
      artifacts.isNotEmpty &&
      artifacts.every(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );
}

/// Résultat unitaire ou erreur pour une espèce dans un batch.
///
/// On ne masque pas les erreurs : chaque entrée porte soit un résultat détaillé
/// d'import, soit un message d'erreur lisible. Le batch peut ainsi continuer
/// sans perdre la granularité par espèce.
class PokemonExternalBatchImportEntryResult {
  const PokemonExternalBatchImportEntryResult({
    required this.speciesId,
    this.result,
    this.errorMessage,
  });

  final String speciesId;
  final PokemonExternalImportResult? result;
  final String? errorMessage;

  bool get isFailed => errorMessage != null;

  bool get isConflict => !isFailed && (result?.hasConflicts ?? false);

  bool get isSkipped => !isFailed && (result?.isFullySkipped ?? false);

  bool get isSuccessful => !isFailed && !isConflict;
}

/// Résultat global d'un import batch.
///
/// Le résultat reste volontairement compact :
/// - paramètres communs du batch ;
/// - résultats détaillés par espèce ;
/// - compteurs résumés.
class PokemonExternalBatchImportResult {
  const PokemonExternalBatchImportResult({
    required this.dryRun,
    required this.mergePolicy,
    required this.entries,
  });

  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalBatchImportEntryResult> entries;

  int get successfulCount =>
      entries.where((entry) => entry.isSuccessful && !entry.isSkipped).length;

  int get skippedCount => entries.where((entry) => entry.isSkipped).length;

  int get conflictCount => entries.where((entry) => entry.isConflict).length;

  int get failedCount => entries.where((entry) => entry.isFailed).length;
}

/// Use case d'orchestration pour importer une seule espèce depuis les sources
/// externes déjà convertibles.
///
/// Ce use case est la couche applicative des lots 34 et 36 :
/// - il récupère les payloads externes via un port minimal ;
/// - il réutilise strictement les convertisseurs 28 à 33 ;
/// - il applique une merge policy simple ;
/// - il supporte un vrai dry-run sans écrire quoi que ce soit ;
/// - il délègue toute écriture réelle au repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de réseau concret ;
/// - pas de lot 37+ ;
/// - pas de stratégie de fusion "intelligente" par champ ;
/// - pas de validation croisée globale du Pokédex.
class ImportExternalPokemonSpeciesUseCase {
  ImportExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.writeRepository,
    this.speciesConverter = const ShowdownPokemonSpeciesConverter(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonLearnsetConverter learnsetConverter;
  final PokeApiPokemonEvolutionConverter evolutionConverter;
  final PokemonMediaStubGenerator mediaStubGenerator;
  final PokemonProjectDataReader dataReader;

  Future<PokemonExternalImportResult> execute(
    ProjectWorkspace workspace, {
    required String speciesId,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final requestedSpeciesId = speciesId.trim();
    if (requestedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external import speciesId cannot be empty',
      );
    }

    // Les payloads sont lus d'abord. Le dry-run doit effectuer toute la
    // résolution et toute la conversion, donc rien n'est "court-circuité".
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(requestedSpeciesId);
    final pokeApiPokemonPayload = await externalSourceRepository
        .fetchPokeApiPokemonPayload(requestedSpeciesId);
    final evolutionChainPayload = await externalSourceRepository
        .fetchPokeApiEvolutionChainPayload(requestedSpeciesId);

    final species = speciesConverter.convert(showdownPayload);
    final learnset = learnsetConverter.convert(
      speciesId: species.id,
      payload: pokeApiPokemonPayload,
    );
    final evolution = evolutionConverter.convert(
      speciesId: species.id,
      payload: evolutionChainPayload,
    );
    final media = mediaStubGenerator.createStub(species);

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[];
    if (species.id != requestedSpeciesId) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }

    final result = PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifacts: artifactPlans
          .map(
            (plan) => PokemonExternalImportArtifactResult(
              kind: plan.kind,
              relativePath: plan.relativePath,
              action: plan.action,
              existedBefore: plan.existedBefore,
              message: plan.message,
            ),
          )
          .toList(growable: false),
      warnings: warnings,
    );

    // Dry-run : tout a été converti et planifié, mais aucune écriture locale
    // n'est autorisée. Le résultat sert alors de rapport d'actions prévues.
    if (dryRun) {
      return result;
    }

    // La politique fail-on-conflict est volontairement atomique au niveau
    // d'une espèce : si un artefact est en conflit, on n'écrit rien pour
    // éviter une importation partielle ambiguë.
    if (result.hasConflicts) {
      return result;
    }

    for (final plan in artifactPlans) {
      switch (plan.action) {
        case PokemonExternalImportArtifactAction.create:
        case PokemonExternalImportArtifactAction.overwrite:
          await plan.write(workspace, writeRepository);
          break;
        case PokemonExternalImportArtifactAction.skip:
        case PokemonExternalImportArtifactAction.conflict:
          break;
      }
    }

    return result;
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required PokemonLearnsetFile learnset,
    required PokemonEvolutionFile evolution,
    required PokemonMediaFile media,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) async {
    final speciesRelativePath = await _resolveSpeciesRelativePath(
      workspace,
      species,
    );

    return <_PlannedArtifactWrite>[
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.species,
        relativePath: speciesRelativePath,
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveSpecies(workspace, species),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.learnset,
        relativePath: 'data/pokemon/learnsets/${learnset.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveLearnset(workspace, learnset),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.evolution,
        relativePath: 'data/pokemon/evolutions/${evolution.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveEvolution(workspace, evolution),
      ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.media,
        relativePath: 'data/pokemon/media/${media.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveMedia(workspace, media),
      ),
    ];
  }

  Future<_PlannedArtifactWrite> _planArtifact(
    ProjectWorkspace workspace, {
    required PokemonExternalImportArtifactKind kind,
    required String relativePath,
    required PokemonExternalImportMergePolicy mergePolicy,
    required Future<void> Function(
      ProjectWorkspace workspace,
      PokemonWriteRepository repository,
    ) write,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final existedBefore = await workspace.fileExists(absolutePath);
    final action = _resolveAction(
      existedBefore: existedBefore,
      mergePolicy: mergePolicy,
    );

    final message = switch (action) {
      PokemonExternalImportArtifactAction.conflict =>
        'Target already exists and merge policy is fail_on_conflict.',
      PokemonExternalImportArtifactAction.skip =>
        'Target already exists and merge policy is skip_existing.',
      PokemonExternalImportArtifactAction.overwrite =>
        'Target already exists and will be overwritten.',
      PokemonExternalImportArtifactAction.create => null,
    };

    return _PlannedArtifactWrite(
      kind: kind,
      relativePath: relativePath,
      existedBefore: existedBefore,
      action: action,
      message: message,
      writeDelegate: write,
    );
  }

  PokemonExternalImportArtifactAction _resolveAction({
    required bool existedBefore,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) {
    if (!existedBefore) {
      return PokemonExternalImportArtifactAction.create;
    }

    return switch (mergePolicy) {
      PokemonExternalImportMergePolicy.failOnConflict =>
        PokemonExternalImportArtifactAction.conflict,
      PokemonExternalImportMergePolicy.skipExisting =>
        PokemonExternalImportArtifactAction.skip,
      PokemonExternalImportMergePolicy.overwriteExisting =>
        PokemonExternalImportArtifactAction.overwrite,
    };
  }

  Future<String> _resolveSpeciesRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    // On reste aligné sur le repository d'écriture existant :
    // - si l'espèce existe déjà, on réutilise son vrai chemin courant ;
    // - sinon on génère le nom canonique `<dex>-<slug>.json`.
    final existingRelativePath =
        await dataReader.resolveSpeciesRelativePathById(workspace, species.id);
    if (existingRelativePath != null) {
      return existingRelativePath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
      species.slug.isNotEmpty ? species.slug : species.id,
    );
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : trimmed;
  }
}

/// Use case batch pour importer plusieurs espèces.
///
/// Ce lot 35 se contente d'enchaîner proprement l'import unitaire :
/// - l'ordre d'exécution est stabilisé ;
/// - chaque espèce garde son résultat détaillé ;
/// - les erreurs par espèce ne cassent pas le reste du batch.
class BatchImportExternalPokemonSpeciesUseCase {
  const BatchImportExternalPokemonSpeciesUseCase(this.singleImportUseCase);

  final ImportExternalPokemonSpeciesUseCase singleImportUseCase;

  Future<PokemonExternalBatchImportResult> execute(
    ProjectWorkspace workspace, {
    required List<String> speciesIds,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final normalizedSpeciesIds = speciesIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (normalizedSpeciesIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external batch speciesIds cannot be empty',
      );
    }

    final entryResults = <PokemonExternalBatchImportEntryResult>[];
    for (final speciesId in normalizedSpeciesIds) {
      try {
        final result = await singleImportUseCase.execute(
          workspace,
          speciesId: speciesId,
          mergePolicy: mergePolicy,
          dryRun: dryRun,
        );
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            result: result,
          ),
        );
      } on EditorApplicationException catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: error.message,
          ),
        );
      } catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: 'Unexpected batch import error: $error',
          ),
        );
      }
    }

    return PokemonExternalBatchImportResult(
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      entries: entryResults,
    );
  }
}

class _PlannedArtifactWrite {
  const _PlannedArtifactWrite({
    required this.kind,
    required this.relativePath,
    required this.existedBefore,
    required this.action,
    required this.writeDelegate,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final bool existedBefore;
  final PokemonExternalImportArtifactAction action;
  final String? message;
  final Future<void> Function(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) writeDelegate;

  Future<void> write(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) {
    return writeDelegate(workspace, repository);
  }
}
```

### 11.3 `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'import_pokemon_catalog_json_use_case.dart';
export 'import_pokemon_evolution_json_use_case.dart';
export 'import_external_pokemon_use_cases.dart';
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

### 11.4 `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
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

### 11.5 `reports/pokedex-phase-7b-lots-34-36-report.md`

Le contenu complet de ce fichier est le document que tu es en train de lire.

## 12. Checklist d’autocontrôle finale

- [x] J’ai bien traité uniquement les lots 34 à 36
- [x] Je n’ai pas commencé les lots 37+
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state inutile
- [x] Je n’ai pas créé de framework générique spéculatif
- [x] J’ai utilisé des sous-agents pour accélérer sans salir le scope
- [x] J’ai réutilisé les frontières existantes du projet
- [x] Les imports applicatifs ajoutés sont testés
- [x] Il n’y a aucun réseau réel dans les tests
- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le rapport markdown a été créé
- [x] Le rapport contient les commandes réellement exécutées
- [x] Le rapport contient les résultats réels
- [x] Le rapport contient le contenu complet de tous les fichiers modifiés/créés/supprimés
- [x] Aucune commande Git d’écriture n’a été exécutée
