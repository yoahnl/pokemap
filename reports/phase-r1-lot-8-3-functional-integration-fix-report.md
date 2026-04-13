# Phase R1 — Lot 8-3 corrective functional pass — Trainer Studio real integration fix

## 1. Résumé exécutif honnête

Cette passe corrective a confirmé deux problèmes réels dans le code et dans l’intégration du vrai workspace projet :

1. le `Trainer Studio` mélangeait encore trop la **recherche espèce en cours** et la **sélection réellement commitée** ;
2. les **moves guidés** pouvaient être indisponibles dans un vrai projet même quand l’index espèces fonctionnait, parce que le reader Pokémon respectait `project.json` pour l’index, mais restait encore partiellement **câblé en dur** sur `data/pokemon/...` et sur `pokemon_data_manifest.json` pour le détail / learnset / catalogues.

Le corrective pass livré reste strictement local :

- aucune stack parallèle ;
- aucun nouveau notifier / provider / repository / use case trainer ;
- aucun lot 9 ;
- aucun changement de contrat du pipeline trainer ;
- aucune réécriture de la surface trainer.

Correctifs réellement livrés :

- `PokemonProjectDataReader` respecte maintenant `project.json -> pokemon.*` pour :
  - le manifest Pokémon local ;
  - les catalogues ;
  - les species files ;
  - les learnsets ;
  - les evolutions ;
  - les media files ;
- `PokemonProjectDataReader` retombe proprement sur les chemins historiques par défaut quand un workspace léger n’a pas encore de `project.json` ;
- le `Trainer Studio` sépare explicitement :
  - la **recherche espèce en cours** ;
  - l’**espèce sélectionnée** ;
- une recherche sans résultat n’efface plus visuellement la sélection active ;
- les messages moves/items indisponibles sont plus compréhensibles côté auteur et n’exposent plus un chemin technique comme message principal ;
- la matrice de tests a été renforcée avec :
  - un test widget sur la séparation recherche espèce / sélection active ;
  - un test repository/use-case plus réaliste qui prouve que détail espèce + learnset + catalogue moves/items chargent bien depuis un workspace temporaire configuré par `project.json` **sans** `pokemon_data_manifest.json`.

Conclusion honnête :

- le corrective pass demandé est **livré** ;
- la correction ne se contente pas de masquer l’erreur UI ;
- les moves guidés sont maintenant branchés sur une source de vérité compatible avec le vrai workspace projet, tant que les données locales existent réellement.

## 2. État initial audité réel

Audit effectué à partir du code et du worktree réels.

### 2.1 État git initial

- `git status --short` : clean
- `git diff --stat` : clean
- `git ls-files --others --exclude-standard` : rien

### 2.2 Fichiers audités en priorité

- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`
- `packages/map_editor/test/pokemon_project_data_reader_test.dart`
- `packages/map_editor/test/file_pokemon_read_repository_test.dart`
- `packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

### 2.3 Diagnostic confirmé avant correction

#### Bug espèces — confirmé

Le bug observé côté utilisateur (`search = pikachu`, `Aucun résultat local`, mais `Selected species: Caterpie`) était réel dans l’UI.

Cause racine confirmée :

- `_TrainerCatalogAssistField` possède son **propre état de recherche transitoire** ;
- la valeur vraiment persistée du draft reste `speciesController.text` ;
- l’UI ne montrait quasiment que l’état commitée, pas l’état de recherche ;
- une recherche vide de résultat laissait donc croire que la sélection affichée correspondait à la requête en cours, alors que ce n’était pas le cas.

Ce n’était pas un deuxième modèle trainer ; c’était un problème d’**honnêteté d’état UI**.

#### Bug liste espèces figée / incohérente — non confirmé comme bug de lookup

Le service de lookup espèces lui-même n’a pas montré de défaut structurel pendant l’audit.

Ce qui a été confirmé :

- le lookup espèces recherche bien sur `id`, `label`, numéro Pokédex et types ;
- l’impression de liste incohérente venait surtout de la confusion entre **recherche courante** et **sélection active** ;
- selon le dataset projet chargé, il est tout à fait possible que peu d’espèces soient indexées.

Donc :

- **pas de bug confirmé** dans `PokemonSpeciesLookupService` ;
- **bug confirmé** dans la manière dont l’UI racontait la relation entre recherche et sélection.

#### Bug moves guidés indisponibles — confirmé

Le message réel de type `Pokemon data manifest not found: data/pokemon/pokemon_data_manifest.json` était cohérent avec un vrai problème d’intégration.

Cause racine confirmée dans `PokemonProjectDataReader` :

- l’index espèces pouvait déjà être construit via `ProjectManifest.pokemon.speciesDir` ;
- mais le lecteur détail / learnset / media / catalogues restait encore partiellement câblé en dur sur :
  - `data/pokemon/species`
  - `data/pokemon/learnsets`
  - `data/pokemon/evolutions`
  - `data/pokemon/media`
  - `data/pokemon/pokemon_data_manifest.json`
- donc, dans un vrai projet :
  - la liste espèces pouvait fonctionner ;
  - mais les détails espèce / learnset / moves catalog pouvaient casser si le projet utilisait `project.json` comme source de vérité avec des chemins configurés, ou si le bootstrap manifest n’existait pas.

Le corrective pass précédent ne le prouvait pas vraiment car il s’appuyait surtout sur des widget tests fortement mockés.

## 3. Bugs confirmés / non confirmés

### 3.1 Confirmés

- ambiguïté UI entre recherche espèce et sélection active ;
- chargement réel moves/learnset cassable par mismatch `project.json` vs chemins hardcodés ;
- exposition trop technique des erreurs côté auteur ;
- absence de preuve suffisamment réaliste dans la matrice précédente.

### 3.2 Non confirmés

- bug structurel du lookup espèces lui-même ;
- besoin d’un nouveau notifier trainer ;
- besoin d’un nouveau provider trainer ;
- besoin de rouvrir `trainer_use_cases.dart` ;
- besoin de rouvrir `EditorNotifier` ;
- besoin d’un deuxième `Trainer Studio` ;
- besoin d’un nouveau moteur générique de formulaires guidés ;
- besoin de rouvrir le lot 9.

### 3.3 Rejetés comme churn

- refonte plus large du `Trainer Studio` ;
- nouvelle couche de chargement Pokémon parallèle ;
- réécriture des messages partout dans la surface trainer ;
- test E2E global shell + trainer + pokédex + runtime.

## 4. Cause racine réelle du bug espèces

Cause racine confirmée : **désynchronisation de visibilité**, pas désynchronisation de persistance.

Détail :

- le champ de recherche espèces du composant `_TrainerCatalogAssistField` est transitoire et privé au widget ;
- la valeur commitée reste dans `speciesController` ;
- l’UI n’expliquait pas clairement qu’une recherche sans résultat n’avait pas modifié la sélection active.

Correction retenue :

- conserver **une seule source de vérité** pour l’espèce (`speciesController`) ;
- exposer séparément en UI :
  - `Current search` ;
  - `Selected species` ;
- ajouter un bouton `Clear` pour la sélection active ;
- ne pas créer un second état métier trainer.

## 5. Cause racine réelle du bug moves

Cause racine confirmée : **mismatch de contrat dans le reader Pokémon local**.

Le pipeline réel était asymétrique :

- `PokemonDatabaseIndex.build()` pouvait déjà utiliser `project.json -> pokemon.speciesDir` ;
- `PokemonProjectDataReader.readSpeciesById()`, `readLearnsetById()`, `readEvolutionById()`, `readMediaById()` et `readCatalogByKey()` restaient encore dépendants de chemins hardcodés et d’un manifest Pokémon local facultatif.

Correction retenue :

- garder le **même** repository / reader / loader ;
- faire converger `PokemonProjectDataReader` vers `project.json -> pokemon.*` ;
- utiliser `project.json` comme fallback honnête quand `pokemon_data_manifest.json` est absent ;
- garder un fallback rétrocompatible vers la config Pokémon par défaut quand un workspace de test n’a pas encore de `project.json`.

## 6. Décisions retenues / rejetées

### 6.1 Retenues

- corriger `PokemonProjectDataReader` au lieu de bricoler le `Trainer Studio` autour d’un faux fallback ;
- garder `TrainerLibraryPanel` comme surface canonique unique ;
- séparer visuellement recherche espèce et sélection active ;
- normaliser localement les messages moves/items indisponibles côté auteur ;
- ajouter une preuve de test plus réaliste via le vrai repository + vrais use cases + workspace temporaire.

### 6.2 Rejetées

- toucher `EditorNotifier` sans bug direct ;
- toucher `trainer_use_cases.dart` sans bug direct ;
- créer un provider / repository / notifier parallèle ;
- masquer le bug moves par un simple wording ;
- créer une surcouche générique de “guided authoring”.

## 7. Conclusions détaillées des reviewers / sous-agents

L’environnement ne permettait plus de créer de nouveaux threads, donc des reviewers existants ont été **réutilisés honnêtement**.

### Reviewer A — architecture / scope (`Feynman`)

Conclusion reçue :
- il n’a pas confirmé le bug reader comme problème de contrat structurel ;
- il recommandait de rester strictement dans la bibliothèque du panel trainer.

Retenu :
- ne pas toucher `EditorNotifier` ;
- ne pas toucher `trainer_use_cases.dart` ;
- garder le corrective pass local et sans stack parallèle.

Rejeté :
- sa conclusion “pas de problème reader réel” a été rejetée parce qu’elle contredisait directement l’audit du code et le bug observé en vrai workspace.

### Reviewer B — UX / no-code (`Meitner`)

Conclusion reçue :
- la surface mélange encore trop recherche transitoire et valeur commitée ;
- il faut rendre visible la valeur réellement sauvée ;
- il ne faut pas construire une deuxième source de vérité.

Retenu :
- séparation explicite `Current search` / `Selected species` ;
- pas de deuxième état trainer ;
- garder les raw IDs seulement en fallback.

### Reviewer C — behavior / data-contract (`Tesla`)

Conclusion reçue :
- le problème guidé moves vient du contrat de lecture : espèce visible ne garantit pas learnset + catalogues disponibles ;
- la surface échoue si `learnset` ou `moves catalog` sont absents ou illisibles.

Retenu :
- correction du reader réel ;
- pas de faux masquage UI ;
- conservation du fallback brut.

### Reviewer D — QA / anti-overengineering (`Hubble`)

Conclusion reçue :
- garder les tests existants rapides ;
- ajouter une preuve plus réaliste, mais sans framework de test dédié ;
- privilégier un test repository/use-case avec vrai workspace temporaire.

Retenu :
- ajout d’un test repository/use-case réel sans manifest Pokémon ;
- pas de harnais générique supplémentaire.

### Reviewer E — product honesty (`Sartre`)

Conclusion reçue :
- les messages doivent parler auteur, pas chemins de fichiers ;
- la valeur brute doit rester possible, mais secondaire ;
- il faut clarifier “la valeur sauvée” vs “la recherche”.

Retenu :
- messages plus honnêtes côté moves/items indisponibles ;
- séparation visuelle claire de la sélection active.

## 8. Périmètre inclus / exclu

### Inclus

- `PokemonProjectDataReader`
- `TrainerLibraryPanel` et ses part files déjà existants
- tests trainer widget ciblés
- tests reader/repository ciblés
- report final

### Exclu

- lot 9
- runtime / battle / save
- nouveau Trainer Studio
- nouveau notifier / provider / repository / use case trainer
- refonte globale du wording
- nouveaux moteurs génériques

## 9. Justification fichier par fichier

### `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

Pourquoi modifié :
- c’est la vraie cause racine du bug moves en vrai workspace.

Ce qui a changé :
- lecture du manifest Pokémon via `project.json -> pokemon.dataRoot` ;
- fallback `catalogFiles` via `project.json` quand `pokemon_data_manifest.json` est absent ;
- chemins `speciesDir`, `learnsetsDir`, `evolutionsDir`, `mediaDir` lus depuis `project.json` ;
- fallback propre vers `ProjectPokemonConfig()` quand `project.json` est absent dans certains workspaces de test.

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

Pourquoi modifié :
- enlever l’interpolation brute des exceptions dans les messages auteur moves/items/species.

Ce qui a changé :
- messages fallback plus propres dans `_loadReferenceData()`.

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

Pourquoi modifié :
- centraliser un petit helper auteur-friendly pour les catalogues locaux indisponibles ;
- rendre la description des moves guidés plus honnête quand le catalogue local échoue.

Ce qui a changé :
- nouveau helper `_buildAuthorFacingCatalogUnavailableMessage()` ;
- utilisation dans `_buildTrainerGuidedMoveSuggestions()`.

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`

Pourquoi modifié :
- éviter d’exposer un message technique brut dans la bannière de références.

Ce qui a changé :
- la bannière références trainer normalise les messages indisponibles moves/items via le helper auteur-friendly.

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

Pourquoi modifié :
- corriger l’ambiguïté entre recherche espèce et espèce sélectionnée.

Ce qui a changé :
- état local `_speciesSearchQuery` ;
- callback `onSearchChanged` dans `_TrainerCatalogAssistField` ;
- affichage séparé de `Current search` et `Selected species` ;
- bouton `Clear` pour la sélection active.

### `packages/map_editor/test/trainer_library_panel_test.dart`

Pourquoi modifié :
- prouver la séparation recherche espèce / sélection active ;
- réaligner un test existant avec le nouveau message auteur-friendly.

Ce qui a changé :
- nouveau test widget sur la séparation recherche / sélection ;
- mise à jour d’un test existant sur l’indisponibilité moves/items.

### `packages/map_editor/test/pokemon_project_data_reader_test.dart`

Pourquoi modifié :
- réaligner l’assertion de message sur le nouveau contrat d’erreur plus large (`manifest or project config`).

### `packages/map_editor/test/file_pokemon_read_repository_test.dart`

Pourquoi modifié :
- fournir une preuve plus réaliste que les mocks initiaux.

Ce qui a changé :
- nouveau test repository/use-case contre un workspace temporaire réel configuré via `project.json` ;
- absence volontaire de `pokemon_data_manifest.json` ;
- validation réelle du chargement :
  - species detail ;
  - learnset ;
  - catalogue moves ;
  - catalogue items.

## 10. Commandes réellement exécutées

### Audit

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
find . -name AGENTS.md -print
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
sed -n '261,620p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
sed -n '1,320p' packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '1,280p' packages/map_editor/test/trainer_library_panel_test.dart
sed -n '281,620p' packages/map_editor/test/trainer_library_panel_test.dart
sed -n '1,280p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
sed -n '1,560p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
sed -n '1,620p' packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '620,980p' packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '1,280p' packages/map_editor/test/pokemon_project_data_reader_test.dart
sed -n '1,260p' packages/map_editor/test/file_pokemon_read_repository_test.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
sed -n '1,220p' packages/map_editor/lib/src/application/services/pokemon_species_lookup_service.dart
```

### Format

```bash
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart packages/map_editor/test/trainer_library_panel_test.dart
/opt/homebrew/bin/dart format packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart packages/map_editor/test/trainer_library_panel_test.dart
/opt/homebrew/bin/dart format packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
/opt/homebrew/bin/dart format packages/map_editor/test/trainer_library_panel_test.dart
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart packages/map_editor/test/trainer_library_panel_test.dart packages/map_editor/test/pokemon_project_data_reader_test.dart packages/map_editor/test/file_pokemon_read_repository_test.dart
```

### Analyze

```bash
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart lib/src/ui/panels/trainer_library_panel.dart lib/src/ui/panels/trainer_library_panel_support.dart lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart test/trainer_library_panel_test.dart
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart lib/src/ui/panels/trainer_library_panel.dart lib/src/ui/panels/trainer_library_panel_support.dart lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart test/trainer_library_panel_test.dart test/pokemon_project_data_reader_test.dart test/file_pokemon_read_repository_test.dart
```

### Tests

```bash
/opt/homebrew/bin/flutter test test/trainer_library_panel_test.dart test/pokemon_project_data_reader_test.dart test/file_pokemon_read_repository_test.dart
/opt/homebrew/bin/flutter test test/trainer_library_panel_test.dart
/opt/homebrew/bin/flutter test test/pokemon_project_data_reader_test.dart test/file_pokemon_read_repository_test.dart
/opt/homebrew/bin/flutter test test/trainer_use_cases_test.dart test/pokemon_species_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/local_catalog_lookup_service_test.dart test/encounter_tables_panel_test.dart test/pokedex_external_batch_execute_ui_test.dart
```

## 11. Résultats réels

### Format

- `dart format` : OK

### Analyze

Résultat final :

- `No issues found!`

### Tests

Résultats finaux :

- `flutter test test/trainer_library_panel_test.dart` : `All tests passed!`
- `flutter test test/pokemon_project_data_reader_test.dart test/file_pokemon_read_repository_test.dart` : `All tests passed!`
- `flutter test test/trainer_use_cases_test.dart test/pokemon_species_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/local_catalog_lookup_service_test.dart test/encounter_tables_panel_test.dart test/pokedex_external_batch_execute_ui_test.dart` : `All tests passed!`

### Tentative intermédiaire échouée

Une première exécution groupée a révélé :

- une assertion de texte à réaligner dans `trainer_library_panel_test.dart` ;
- un test widget “vrai workspace” trop flaky via `pumpAndSettle`.

Décision prise :

- correction du test de wording ;
- remplacement de cette preuve par un test repository/use-case réel plus robuste, sans abandonner l’objectif d’intégration réaliste.

## 12. Incidents rencontrés

1. `flutter analyze` a d’abord signalé :
   - un `const_with_non_const` dans un override de test ;
   - deux suggestions `const` à corriger.
   => corrigé localement.

2. Une exécution groupée des tests a échoué sur :
   - une assertion texte devenue obsolète après normalisation auteur-friendly des messages moves/items.
   => corrigé localement.

3. Un test widget “vrai workspace” a montré une flakiness de settling.
   => remplacé par une preuve plus robuste et toujours réaliste au niveau repository + use cases + workspace temporaire.

## 13. État git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
 M packages/map_editor/test/file_pokemon_read_repository_test.dart
 M packages/map_editor/test/pokemon_project_data_reader_test.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
```

### `git diff --stat`

```text
 .../services/pokemon_project_data_reader.dart      | 184 +++++++++++++--
 .../lib/src/ui/panels/trainer_library_panel.dart   |  14 +-
 .../trainer_library_panel_pokemon_widgets.dart     | 102 +++++++--
 .../ui/panels/trainer_library_panel_support.dart   |  45 +++-
 .../trainer_library_panel_trainer_widgets.dart     |  16 +-
 .../test/file_pokemon_read_repository_test.dart    | 248 +++++++++++++++++++++
 .../test/pokemon_project_data_reader_test.dart     |   2 +-
 .../test/trainer_library_panel_test.dart           | 128 ++++++++++-
 8 files changed, 685 insertions(+), 54 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
```

## 14. Checklist finale

- [x] je me suis basé sur le code réel et le comportement réel
- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas ouvert le lot 9
- [x] j’ai identifié la cause réelle du bug espèces
- [x] j’ai identifié la cause réelle du bug moves
- [x] j’ai corrigé l’intégration réelle, pas seulement l’apparence
- [x] la recherche espèce et la sélection active sont maintenant honnêtes
- [x] les moves guidés fonctionnent réellement quand les données locales existent
- [x] les messages sont plus compréhensibles pour un auteur
- [x] les fallbacks bruts restent possibles mais secondaires
- [x] j’ai ajouté une preuve de test plus réaliste que les mocks initiaux
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture git interdite
- [x] j’ai créé un report ultra complet
- [x] le report contient le contenu complet des fichiers touchés (hors ce report lui-même, exclu pour éviter la récursion)

## 15. Conclusion honnête

Ce corrective pass est **réellement livré**.

Ce qui est corrigé pour de vrai :

- l’UI species ne ment plus sur la relation entre recherche et sélection ;
- le chargement local Pokémon n’est plus cassé dès qu’un projet s’appuie sur `project.json` au lieu d’un bootstrap manifest ;
- les moves guidés peuvent maintenant fonctionner dans le vrai workspace dès lors que :
  - l’espèce existe localement ;
  - son learnset existe localement ;
  - le catalogue moves existe localement ;
  - les chemins sont déclarés dans `project.json`.

Ce qui n’a pas été fait volontairement :

- pas de lot 9 ;
- pas de nouveau moteur guidé ;
- pas de nouveau Trainer Studio ;
- pas de refonte des use cases trainer ;
- pas de provider parallèle.

Verdict :

- corrective pass **terminé** ;
- `Trainer Studio` corrigé sur son intégration fonctionnelle réelle ;
- pas de dette bloquante confirmée pour ce scope précis avant la suite.

## 16. Annexe — contenu complet des fichiers touchés

Le report s’exclut lui-même de sa propre annexe pour éviter la récursion infinie.

### `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
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
      await _pokemonDataManifestRelativePath(workspace),
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    // The local Pokemon bootstrap manifest is useful when it exists, but it is
    // not the only source of truth in real projects. The editor already uses
    // `project.json -> pokemon.*` to index species, so guided moves/items must
    // honor that same config instead of failing just because the optional
    // bootstrap manifest is absent.
    final pokemonConfig = await _readProjectPokemonConfig(workspace);

    String? relativePath;
    try {
      final manifest = await readManifest(workspace);
      final declaredPath = manifest.catalogFiles[catalogKey]?.trim();
      if (declaredPath != null && declaredPath.isNotEmpty) {
        relativePath = _resolvePathWithinPokemonDataRoot(
          pokemonConfig: pokemonConfig,
          rawRelativePath: declaredPath,
        );
      }
    } on EditorNotFoundException {
      // Real projects can still be fully authorable with `project.json`
      // storage paths even when the bootstrap manifest has not been created.
      relativePath = null;
    }

    if (relativePath == null) {
      final configuredPath = pokemonConfig.catalogFiles[catalogKey]?.trim();
      if (configuredPath != null && configuredPath.isNotEmpty) {
        relativePath = p.normalize(configuredPath);
      }
    }

    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in project manifest or project config: '
        '$catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      relativePath,
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
    final learnsetsDirectory = await _learnsetsDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(learnsetsDirectory, '$trimmedId.json'),
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
    final evolutionsDirectory =
        await _evolutionsDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(evolutionsDirectory, '$trimmedId.json'),
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
    final mediaDirectory = await _mediaDirectoryRelativePath(workspace);
    final json = await _readJsonFile(
      workspace,
      p.join(mediaDirectory, '$trimmedId.json'),
      label: 'Pokemon media "$trimmedId"',
    );
    return PokemonMediaFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    final speciesDirectory = await _speciesDirectoryRelativePath(workspace);
    return _listJsonRelativePaths(
      workspace,
      speciesDirectory,
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

      // Le portrait de liste reste volontairement best effort :
      // - si le média local n'existe pas, la liste ne casse pas ;
      // - si le `media.json` est invalide, on n'empêche pas l'espèce de
      //   remonter dans l'éditeur ;
      // - si le fichier portrait n'existe plus sur disque, on omet
      //   simplement l'image décorative.
      //
      // Cela permet d'embellir la liste sans transformer l'index léger en
      // seconde fiche détail ni faire de l'UI une lectrice JSON parallèle.
      final portraitRelativePath = await _resolveOptionalPortraitRelativePath(
        workspace,
        species,
      );

      entries.add(
        PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: speciesIndexEntry,
          species: species,
          portraitRelativePath: portraitRelativePath,
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

  Future<String?> _resolveOptionalPortraitRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final mediaId = species.refs.media.trim();
    if (mediaId.isEmpty) {
      return null;
    }

    try {
      final media = await readMediaById(workspace, mediaId);
      final defaultVariant = media.variants[media.defaultFormId];
      final portraitRelativePath = defaultVariant?.portrait?.trim();
      if (portraitRelativePath == null || portraitRelativePath.isEmpty) {
        return null;
      }

      final exists = await workspace.fileExists(
        workspace.resolveProjectRelativePath(portraitRelativePath),
      );
      return exists ? portraitRelativePath : null;
    } on EditorApplicationException {
      // Important : le portrait de liste est décoratif.
      // Une erreur média locale ne doit pas rendre la liste Pokédex inutilisable
      // si l'espèce elle-même reste lisible et indexable.
      return null;
    } catch (_) {
      // Même philosophie ici : on ne masque pas un problème plus loin dans la
      // stack, mais on n'échoue pas non plus la liste pour un portrait.
      return null;
    }
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return _readSpeciesAtRelativePath(workspace, relativePath);
  }

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
    final learnsetsDirectory = await _learnsetsDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      learnsetsDirectory,
      label: 'Pokemon learnsets directory',
    );
  }

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
    final evolutionsDirectory =
        await _evolutionsDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      evolutionsDirectory,
      label: 'Pokemon evolutions directory',
    );
  }

  Future<List<String>> listMediaIds(ProjectWorkspace workspace) async {
    final mediaDirectory = await _mediaDirectoryRelativePath(workspace);
    return _listJsonFileStemIds(
      workspace,
      mediaDirectory,
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

    final speciesDir = await _speciesDirectory(workspace);
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

  Future<Directory> _speciesDirectory(ProjectWorkspace workspace) async {
    final speciesDirectory = await _speciesDirectoryRelativePath(workspace);
    return Directory(
      workspace.resolveProjectRelativePath(speciesDirectory),
    );
  }

  Future<String> _pokemonDataManifestRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );
    return p.normalize(p.join(dataRoot, 'pokemon_data_manifest.json'));
  }

  Future<String> _speciesDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.speciesDir,
      fallback: 'data/pokemon/species',
    );
  }

  Future<String> _learnsetsDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
  }

  Future<String> _evolutionsDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.evolutionsDir,
      fallback: 'data/pokemon/evolutions',
    );
  }

  Future<String> _mediaDirectoryRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    return _normalizeConfiguredRelativePath(
      pokemonConfig.mediaDir,
      fallback: 'data/pokemon/media',
    );
  }

  Future<ProjectPokemonConfig> _readProjectPokemonConfig(
    ProjectWorkspace workspace,
  ) async {
    final manifestPath = workspace.projectManifestPath;
    try {
      // Real projects always have `project.json`, but a few lightweight tests
      // and temporary workspaces still seed only the Pokemon files. Falling
      // back to the historical default layout keeps those fixtures working
      // while still honoring project-specific paths whenever the manifest is
      // present.
      if (!await workspace.fileExists(manifestPath)) {
        return const ProjectPokemonConfig();
      }

      final raw = await workspace.readTextFile(manifestPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          'Project manifest is not a JSON object: $manifestPath',
        );
      }
      final project = ProjectManifest.fromJson(decoded);
      return project.pokemon;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read project manifest at $manifestPath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in project manifest at $manifestPath: $error',
      );
    } catch (error) {
      throw EditorPersistenceException(
        'Invalid project manifest at $manifestPath: $error',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawRelativePath, {
    required String fallback,
  }) {
    final trimmed = rawRelativePath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolvePathWithinPokemonDataRoot({
    required ProjectPokemonConfig pokemonConfig,
    required String rawRelativePath,
  }) {
    final normalizedPath = p.normalize(rawRelativePath.trim());
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );
    if (normalizedPath == dataRoot || normalizedPath.startsWith('$dataRoot/')) {
      return normalizedPath;
    }
    return p.normalize(p.join(dataRoot, normalizedPath));
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

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/local_catalog_lookup_service.dart';
import '../../application/services/pokemon_items_catalog_lookup_service.dart';
import '../../application/services/pokemon_moves_catalog_lookup_service.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

// Keep the trainer library in one Dart library so we can split the corrective
// pass into neighboring `part` files without changing visibility or adding a
// new trainer-specific architecture.
part 'trainer_library_panel_support.dart';
part 'trainer_library_panel_trainer_widgets.dart';
part 'trainer_library_panel_pokemon_widgets.dart';
part 'trainer_library_panel_workspace_widgets.dart';

const PokemonSpeciesLookupService _speciesLookupService =
    PokemonSpeciesLookupService();
const PokemonMovesCatalogLookupService _movesLookupService =
    PokemonMovesCatalogLookupService();
const PokemonItemsCatalogLookupService _itemsLookupService =
    PokemonItemsCatalogLookupService();
const List<String> _trainerQuickGenderValues = <String>[
  'male',
  'female',
  'any',
];

class TrainerLibraryPanel extends ConsumerStatefulWidget {
  const TrainerLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TrainerLibraryPanel> createState() =>
      _TrainerLibraryPanelState();
}

class _TrainerLibraryPanelState extends ConsumerState<TrainerLibraryPanel> {
  // -------------------------------------------------------------------------
  // Formulaire de création d'un trainer
  // -------------------------------------------------------------------------

  final _newNameController = TextEditingController();
  final _newClassController = TextEditingController();
  final _newPortraitController = TextEditingController();
  final _newBattleThemeController = TextEditingController();
  final _newVictoryThemeController = TextEditingController();
  final _newTagsController = TextEditingController();
  final _trainerSearchController = TextEditingController();
  String? _newCharacterId;
  bool _showCreateForm = false;
  bool _showCreateAdvanced = false;
  String? _createTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Formulaire d'édition du trainer sélectionné
  // -------------------------------------------------------------------------

  String? _editingTrainerId;
  final _editNameController = TextEditingController();
  final _editClassController = TextEditingController();
  final _editPortraitController = TextEditingController();
  final _editBattleThemeController = TextEditingController();
  final _editVictoryThemeController = TextEditingController();
  final _editTagsController = TextEditingController();
  String? _editCharacterId;
  bool _showEditAdvanced = false;
  String? _editTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Draft partagé pour ajout / édition d'un Pokémon de team
  // -------------------------------------------------------------------------

  String? _activePokemonTrainerId;
  int? _editingPokemonIndex;
  final _pokemonSpeciesController = TextEditingController();
  final _pokemonLevelController = TextEditingController(text: '1');
  final _pokemonItemController = TextEditingController();
  final _pokemonFormController = TextEditingController();
  final _pokemonGenderController = TextEditingController();
  late final List<TextEditingController> _pokemonMoveControllers =
      List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _pokemonShiny = false;
  String? _pokemonValidationMessage;

  // -------------------------------------------------------------------------
  // Références locales réutilisées par la surface auteur
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_TrainerReferenceData>? _referenceDataFuture;
  final Map<String, Future<PokedexSpeciesDetail?>> _speciesDetailFutureCache =
      <String, Future<PokedexSpeciesDetail?>>{};

  @override
  void initState() {
    super.initState();
    // The roster filter stays local to the trainer surface. It is not part of
    // editor-wide state and should never leak into the notifier.
    _trainerSearchController.addListener(_handleRosterSearchChanged);
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _newPortraitController.dispose();
    _newBattleThemeController.dispose();
    _newVictoryThemeController.dispose();
    _newTagsController.dispose();
    _trainerSearchController
      ..removeListener(_handleRosterSearchChanged)
      ..dispose();

    _editNameController.dispose();
    _editClassController.dispose();
    _editPortraitController.dispose();
    _editBattleThemeController.dispose();
    _editVictoryThemeController.dispose();
    _editTagsController.dispose();

    _pokemonSpeciesController.dispose();
    _pokemonLevelController.dispose();
    _pokemonItemController.dispose();
    _pokemonFormController.dispose();
    _pokemonGenderController.dispose();
    for (final controller in _pokemonMoveControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _handleRosterSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_TrainerReferenceData>(
            future: _referenceDataFuture,
            initialData: const _TrainerReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _TrainerReferenceData.loading();
              return widget.embedded
                  ? _buildEmbeddedTrainerLibrary(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
                    )
                  : _buildTrainerStudioWorkspace(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
                    );
            },
          );

    if (widget.embedded) {
      return content;
    }
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }

  // -------------------------------------------------------------------------
  // Chargement des références locales
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    _speciesDetailFutureCache.clear();

    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_TrainerReferenceData>.value(
            const _TrainerReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _speciesDetailFutureCache.clear();
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_TrainerReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);
    final movesLoader = ref.read(pokedexMovesCatalogLoaderProvider);
    final itemsLoader = ref.read(loadPokemonItemsCatalogUseCaseProvider);

    List<PokemonDatabaseIndexEntry> speciesEntries = const [];
    String speciesMessage =
        'Aucune espèce locale disponible. La saisie brute reste possible.';
    var isSpeciesAvailable = false;

    try {
      speciesEntries = await speciesLoader(workspace);
      isSpeciesAvailable = speciesEntries.isNotEmpty;
      speciesMessage = speciesEntries.isEmpty
          ? 'Aucune espèce locale n’a encore été indexée. La saisie brute reste possible.'
          : 'Recherche locale active sur ${speciesEntries.length} espèces du projet.';
    } catch (error) {
      speciesMessage =
          'Impossible de charger les espèces locales. La saisie brute reste possible.';
    }

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = const PokemonMovesCatalogView(
        entries: <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = const PokemonItemsCatalogView(
        entries: <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.',
      );
    }

    return _TrainerReferenceData(
      speciesEntries: speciesEntries,
      isSpeciesAvailable: isSpeciesAvailable,
      speciesMessage: speciesMessage,
      movesCatalogView: movesCatalogView,
      itemsCatalogView: itemsCatalogView,
    );
  }

  Future<PokedexSpeciesDetail?> _loadSpeciesDetailIfPossible(
    ProjectWorkspace workspace,
    String rawSpeciesId,
  ) {
    final speciesId = rawSpeciesId.trim();
    if (speciesId.isEmpty) {
      return Future<PokedexSpeciesDetail?>.value(null);
    }

    final existingFuture = _speciesDetailFutureCache[speciesId];
    if (existingFuture != null) {
      return existingFuture;
    }

    final loader = ref.read(pokedexSpeciesDetailLoaderProvider);
    final future = loader(workspace, speciesId)
        .then<PokedexSpeciesDetail?>((detail) => detail)
        .catchError((_) => null);
    _speciesDetailFutureCache[speciesId] = future;
    return future;
  }

  // -------------------------------------------------------------------------
  // Trainer CRUD
  // -------------------------------------------------------------------------

  Future<void> _handleCreateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      portraitElementId: _newPortraitController.text,
    );
    setState(() {
      _createTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.createTrainer(
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      characterId: _newCharacterId,
      portraitElementId: _newPortraitController.text,
      battleThemeId: _newBattleThemeController.text,
      victoryThemeId: _newVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_newTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_resetCreateTrainerDraft);
      return;
    }

    setState(() {
      _createTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create trainer.';
    });
  }

  Future<void> _handleUpdateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ProjectTrainerEntry trainer,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      portraitElementId: _editPortraitController.text,
    );
    setState(() {
      _editTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.updateTrainer(
      trainerId: trainer.id,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      characterId: _editCharacterId,
      portraitElementId: _editPortraitController.text,
      battleThemeId: _editBattleThemeController.text,
      victoryThemeId: _editVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_editTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closeTrainerEditor);
      return;
    }

    setState(() {
      _editTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update trainer.';
    });
  }

  Future<void> _handleDeleteTrainer({
    required EditorNotifier notifier,
    required ProjectTrainerEntry trainer,
  }) async {
    final success = await notifier.deleteTrainer(trainer.id);
    if (!mounted || !success) {
      return;
    }
    setState(() {
      if (_editingTrainerId == trainer.id) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId == trainer.id) {
        _closePokemonEditor();
      }
    });
  }

  String? _validateTrainerDraft({
    required ProjectManifest project,
    required String name,
    required String trainerClass,
    required String portraitElementId,
  }) {
    if (name.trim().isEmpty) {
      return 'Trainer name cannot be empty.';
    }
    if (trainerClass.trim().isEmpty) {
      return 'Trainer class cannot be empty.';
    }

    final portraitId = portraitElementId.trim();
    if (portraitId.isNotEmpty &&
        !project.elements.any((element) => element.id == portraitId)) {
      return 'Portrait element "$portraitId" does not exist in this project.';
    }

    return null;
  }

  void _resetCreateTrainerDraft() {
    _showCreateForm = false;
    _showCreateAdvanced = false;
    _createTrainerValidationMessage = null;
    _newNameController.clear();
    _newClassController.clear();
    _newPortraitController.clear();
    _newBattleThemeController.clear();
    _newVictoryThemeController.clear();
    _newTagsController.clear();
    _newCharacterId = null;
  }

  void _openCreateTrainerForm() {
    setState(() {
      _showCreateForm = true;
      _createTrainerValidationMessage = null;
      _editingTrainerId = null;
      _closePokemonEditor();
    });
  }

  void _toggleCreateAdvanced() {
    setState(() {
      _showCreateAdvanced = !_showCreateAdvanced;
    });
  }

  void _setNewCharacterId(String? characterId) {
    setState(() {
      _newCharacterId = characterId;
    });
  }

  void _cancelCreateTrainerDraft() {
    setState(_resetCreateTrainerDraft);
  }

  ProjectTrainerEntry? _selectedTrainerForWorkspace(
    ProjectManifest project,
    EditorState state,
  ) {
    final selectedTrainerId = state.selectedTrainerId;
    if (selectedTrainerId != null) {
      for (final trainer in project.trainers) {
        if (trainer.id == selectedTrainerId) {
          return trainer;
        }
      }
    }
    return project.trainers.isEmpty ? null : project.trainers.first;
  }

  void _selectTrainerForWorkspace(String? trainerId) {
    // The central workspace owns the detailed trainer authoring experience.
    // Switching roster selection should therefore also clean up any draft that
    // belongs to another trainer, instead of leaving a stale editor visible in
    // the wrong context.
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      if (_showCreateForm && trainerId != null) {
        _resetCreateTrainerDraft();
      }
      if (_editingTrainerId != null && _editingTrainerId != trainerId) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId != null &&
          _activePokemonTrainerId != trainerId) {
        _closePokemonEditor();
      }
    });
  }

  void _startEditingTrainer(ProjectTrainerEntry trainer) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainer.id);
    setState(() {
      _editingTrainerId = trainer.id;
      _editNameController.text = trainer.name;
      _editClassController.text = trainer.trainerClass;
      _editPortraitController.text = trainer.portraitElementId ?? '';
      _editBattleThemeController.text = trainer.battleThemeId ?? '';
      _editVictoryThemeController.text = trainer.victoryThemeId ?? '';
      _editTagsController.text = trainer.tags.join(', ');
      _editCharacterId = trainer.characterId;
      _showEditAdvanced = false;
      _editTrainerValidationMessage = null;
      _showCreateForm = false;
      _closePokemonEditor();
    });
  }

  void _toggleEditAdvanced() {
    setState(() {
      _showEditAdvanced = !_showEditAdvanced;
    });
  }

  void _setEditCharacterId(String? characterId) {
    setState(() {
      _editCharacterId = characterId;
    });
  }

  void _cancelTrainerEditor() {
    setState(_closeTrainerEditor);
  }

  // -------------------------------------------------------------------------
  // Draft Pokémon team
  // -------------------------------------------------------------------------

  bool get _isAddingPokemon =>
      _activePokemonTrainerId != null && _editingPokemonIndex == null;

  bool _isEditingPokemon(
    String trainerId,
    int pokemonIndex,
  ) {
    return _activePokemonTrainerId == trainerId &&
        _editingPokemonIndex == pokemonIndex;
  }

  void _closePokemonEditor() {
    _activePokemonTrainerId = null;
    _editingPokemonIndex = null;
    _resetPokemonDraftFields();
  }

  void _cancelPokemonEditor() {
    setState(_closePokemonEditor);
  }

  void _setPokemonShiny(bool value) {
    setState(() {
      _pokemonShiny = value;
    });
  }

  // Keeping the shared Pokémon draft reset in one place avoids tiny
  // field-reset mismatches between add/edit/cancel flows.
  void _resetPokemonDraftFields() {
    _pokemonValidationMessage = null;
    _pokemonSpeciesController.clear();
    _pokemonLevelController.text = '1';
    _pokemonItemController.clear();
    _pokemonFormController.clear();
    _pokemonGenderController.clear();
    _clearTextControllers(_pokemonMoveControllers);
    _pokemonShiny = false;
  }

  void _startAddingPokemon(String trainerId) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = null;
      _resetPokemonDraftFields();
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  void _startEditingPokemon(
    String trainerId,
    int pokemonIndex,
    ProjectTrainerPokemonEntry pokemon,
  ) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = pokemonIndex;
      _pokemonValidationMessage = null;
      _pokemonSpeciesController.text = pokemon.speciesId;
      _pokemonLevelController.text = pokemon.level.toString();
      _pokemonItemController.text = pokemon.heldItemId ?? '';
      _pokemonFormController.text = pokemon.formId ?? '';
      _pokemonGenderController.text = pokemon.gender ?? '';
      for (var i = 0; i < _pokemonMoveControllers.length; i++) {
        _pokemonMoveControllers[i].text =
            i < pokemon.moves.length ? pokemon.moves[i] : '';
      }
      _pokemonShiny = pokemon.shiny;
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  Future<void> _handleSavePokemonDraft({
    required EditorNotifier notifier,
    required ProjectWorkspace workspace,
    required _TrainerReferenceData references,
  }) async {
    final trainerId = _activePokemonTrainerId;
    if (trainerId == null) {
      return;
    }

    final speciesDetail = await _loadSpeciesDetailIfPossible(
        workspace, _pokemonSpeciesController.text);
    final validation = _validatePokemonDraft(
      references: references,
      speciesDetail: speciesDetail,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _pokemonValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final draft = _buildPokemonDraft();
    if (draft.level == null) {
      setState(() {
        _pokemonValidationMessage = 'Level must be a positive integer.';
      });
      return;
    }

    final success = _editingPokemonIndex == null
        ? await notifier.addTrainerPokemon(
            trainerId: trainerId,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          )
        : await notifier.updateTrainerPokemon(
            trainerId: trainerId,
            pokemonIndex: _editingPokemonIndex!,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closePokemonEditor);
      return;
    }

    setState(() {
      _pokemonValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to save trainer Pokémon.';
    });
  }

  Future<void> _handleDeletePokemon({
    required EditorNotifier notifier,
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final success = await notifier.deleteTrainerPokemon(
      trainerId: trainerId,
      pokemonIndex: pokemonIndex,
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_isEditingPokemon(trainerId, pokemonIndex)) {
        _closePokemonEditor();
      }
    });
  }

  _TrainerPokemonDraft _buildPokemonDraft() {
    return _TrainerPokemonDraft(
      speciesId: _pokemonSpeciesController.text.trim(),
      level: int.tryParse(_pokemonLevelController.text.trim()),
      moves: _pokemonMoveControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      heldItemId: _normalizeOptionalField(_pokemonItemController.text),
      formId: _normalizeOptionalField(_pokemonFormController.text),
      gender: _normalizeOptionalField(_pokemonGenderController.text),
      shiny: _pokemonShiny,
    );
  }

  String? _validatePokemonDraft({
    required _TrainerReferenceData references,
    required PokedexSpeciesDetail? speciesDetail,
  }) {
    final draft = _buildPokemonDraft();
    if (draft.speciesId.isEmpty) {
      return 'Species ID cannot be empty.';
    }

    if (draft.level == null || draft.level! <= 0) {
      return 'Level must be a positive integer.';
    }

    if (references.isSpeciesAvailable &&
        _speciesLookupService.findById(
                references.speciesEntries, draft.speciesId) ==
            null) {
      return 'Species "${draft.speciesId}" is not present in the local Pokédex.';
    }

    if (references.movesCatalogView.isAvailable) {
      for (var i = 0; i < draft.moves.length; i++) {
        final moveId = draft.moves[i];
        if (_movesLookupService.findById(
              references.movesCatalogView.entries,
              moveId,
            ) ==
            null) {
          return 'Move ${i + 1} references an unknown local move: $moveId';
        }
      }
    }

    if (references.itemsCatalogView.isAvailable &&
        draft.heldItemId != null &&
        draft.heldItemId!.isNotEmpty &&
        _itemsLookupService.findById(
              references.itemsCatalogView.entries,
              draft.heldItemId!,
            ) ==
            null) {
      return 'Held item "${draft.heldItemId}" is not present in the local items catalog.';
    }

    final availableForms = speciesDetail == null
        ? const <String>[]
        : _buildSpeciesFormSuggestions(speciesDetail.species);
    if (availableForms.isNotEmpty &&
        draft.formId != null &&
        draft.formId!.isNotEmpty &&
        !availableForms.contains(draft.formId)) {
      return 'Form "${draft.formId}" does not match the selected species.';
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Construction UI
  // -------------------------------------------------------------------------

  // Trainer edition is a presentation concern only. Keeping this reset local
  // avoids pushing UI mode flags into the notifier or the use cases.
  void _closeTrainerEditor() {
    _editingTrainerId = null;
    _editTrainerValidationMessage = null;
    _showEditAdvanced = false;
  }
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.isSpeciesCatalogAvailable,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final bool isSpeciesCatalogAvailable;
  final PokemonMovesCatalogView moveCatalogView;
  final PokemonItemsCatalogView itemCatalogView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedMoveLabels = pokemon.moves.map((moveId) {
      if (!moveCatalogView.isAvailable) {
        return moveId;
      }
      final match = _movesLookupService.findById(
        moveCatalogView.entries,
        moveId,
      );
      return match == null ? '$moveId (?)' : match.name;
    }).toList(growable: false);
    final resolvedItemLabel = pokemon.heldItemId == null ||
            pokemon.heldItemId!.trim().isEmpty ||
            !itemCatalogView.isAvailable
        ? pokemon.heldItemId?.trim()
        : _itemsLookupService
                .findById(itemCatalogView.entries, pokemon.heldItemId!.trim())
                ?.name ??
            '${pokemon.heldItemId!.trim()} (?)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          speciesEntry?.primaryName ?? pokemon.speciesId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          speciesEntry == null
                              ? '${pokemon.speciesId} • Lv.${pokemon.level}'
                              : '#${speciesEntry!.nationalDex.toString().padLeft(4, '0')} • ${pokemon.speciesId} • ${speciesEntry!.types.join('/')} • Lv.${pokemon.level}',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onEdit,
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
              if (speciesEntry == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isSpeciesCatalogAvailable
                        ? 'Species absent from the local Pokédex.'
                        : 'Local species index unavailable. The raw value is kept as-is.',
                    style: const TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (resolvedMoveLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final moveLabel in resolvedMoveLabels)
                      _TrainerSummaryChip(
                        label: moveLabel,
                        accent: EditorChrome.accentWarm,
                      ),
                  ],
                ),
              ],
              if (resolvedItemLabel != null &&
                  resolvedItemLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Item: $resolvedItemLabel',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.formId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Form: ${pokemon.formId!.trim()}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.gender ?? '').trim().isNotEmpty ||
                  pokemon.shiny) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((pokemon.gender ?? '').trim().isNotEmpty)
                      'Gender: ${pokemon.gender!.trim()}',
                    if (pokemon.shiny) 'Shiny',
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerPokemonEditorCard extends StatefulWidget {
  const _TrainerPokemonEditorCard({
    super.key,
    required this.trainerId,
    required this.references,
    required this.speciesController,
    required this.levelController,
    required this.itemController,
    required this.formController,
    required this.genderController,
    required this.moveControllers,
    required this.shiny,
    required this.validationMessage,
    required this.onToggleShiny,
    required this.onCancel,
    required this.onSave,
    required this.loadSpeciesDetail,
  });

  final String trainerId;
  final _TrainerReferenceData references;
  final TextEditingController speciesController;
  final TextEditingController levelController;
  final TextEditingController itemController;
  final TextEditingController formController;
  final TextEditingController genderController;
  final List<TextEditingController> moveControllers;
  final bool shiny;
  final String? validationMessage;
  final ValueChanged<bool> onToggleShiny;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<PokedexSpeciesDetail?> Function(String speciesId)
      loadSpeciesDetail;

  @override
  State<_TrainerPokemonEditorCard> createState() =>
      _TrainerPokemonEditorCardState();
}

class _TrainerPokemonEditorCardState extends State<_TrainerPokemonEditorCard> {
  Future<PokedexSpeciesDetail?>? _speciesDetailFuture;
  String _lastSpeciesId = '';
  bool _showRawFallbacks = false;
  String _speciesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _bindDraftControllers();
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void didUpdateWidget(covariant _TrainerPokemonEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesController != widget.speciesController) {
      oldWidget.speciesController.removeListener(_onDraftFieldChanged);
      widget.speciesController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.levelController != widget.levelController) {
      oldWidget.levelController.removeListener(_onDraftFieldChanged);
      widget.levelController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_onDraftFieldChanged);
      widget.itemController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.formController != widget.formController) {
      oldWidget.formController.removeListener(_onDraftFieldChanged);
      widget.formController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.genderController != widget.genderController) {
      oldWidget.genderController.removeListener(_onDraftFieldChanged);
      widget.genderController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.moveControllers != widget.moveControllers) {
      for (final controller in oldWidget.moveControllers) {
        controller.removeListener(_onDraftFieldChanged);
      }
      for (final controller in widget.moveControllers) {
        controller.addListener(_onDraftFieldChanged);
      }
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void dispose() {
    _unbindDraftControllers();
    super.dispose();
  }

  void _bindDraftControllers() {
    widget.speciesController.addListener(_onDraftFieldChanged);
    widget.levelController.addListener(_onDraftFieldChanged);
    widget.itemController.addListener(_onDraftFieldChanged);
    widget.formController.addListener(_onDraftFieldChanged);
    widget.genderController.addListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.addListener(_onDraftFieldChanged);
    }
  }

  void _unbindDraftControllers() {
    widget.speciesController.removeListener(_onDraftFieldChanged);
    widget.levelController.removeListener(_onDraftFieldChanged);
    widget.itemController.removeListener(_onDraftFieldChanged);
    widget.formController.removeListener(_onDraftFieldChanged);
    widget.genderController.removeListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.removeListener(_onDraftFieldChanged);
    }
  }

  void _onDraftFieldChanged() {
    _refreshSpeciesDetailFuture();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSpeciesDetailFuture({bool force = false}) {
    final speciesId = widget.speciesController.text.trim();
    if (!force && speciesId == _lastSpeciesId) {
      return;
    }
    _lastSpeciesId = speciesId;
    _speciesDetailFuture = widget.loadSpeciesDetail(speciesId);
  }

  void _toggleRawFallbacks() {
    setState(() {
      _showRawFallbacks = !_showRawFallbacks;
    });
  }

  void _handleSpeciesSearchChanged(String rawQuery) {
    if (_speciesSearchQuery == rawQuery) {
      return;
    }
    setState(() {
      // The search box is only a transient query helper. The committed draft
      // still lives in `speciesController`, so we keep both states explicit to
      // avoid implying that a failed search changed the saved species.
      _speciesSearchQuery = rawQuery;
    });
  }

  Widget _buildRawFallbackSection(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Advanced raw ID fallbacks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PushButton(
                  key: const Key(
                    'trainer-library-pokemon-raw-fallback-toggle-button',
                  ),
                  controlSize: ControlSize.small,
                  secondary: _showRawFallbacks,
                  onPressed: _toggleRawFallbacks,
                  child: Text(
                    _showRawFallbacks ? 'Hide raw fields' : 'Show raw fields',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Guided selectors stay primary. Open these raw fields only when local project data cannot suggest the exact value you need.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (_showRawFallbacks) ...[
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw species ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-species-field'),
                controller: widget.speciesController,
                placeholder: 'pikachu',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < widget.moveControllers.length; i++) ...[
                _TrainerInlineField(
                  label: 'Raw move ID ${i + 1} (fallback)',
                  fieldKey: Key('trainer-library-pokemon-move-$i-field'),
                  controller: widget.moveControllers[i],
                  placeholder: 'move id',
                ),
                if (i != widget.moveControllers.length - 1)
                  const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw held item ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-item-field'),
                controller: widget.itemController,
                placeholder: 'oran_berry',
              ),
              const SizedBox(height: 10),
              _TrainerInlineField(
                label: 'Raw form ID (fallback)',
                fieldKey: const Key('trainer-library-pokemon-form-field'),
                controller: widget.formController,
                placeholder: 'base / alternate form id',
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final speciesId = widget.speciesController.text.trim();
    final level = int.tryParse(widget.levelController.text.trim());
    final heldItemId = widget.itemController.text.trim();
    final formId = widget.formController.text.trim();
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            speciesId,
          )
        : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;
    final activeSpeciesSearchQuery = _speciesSearchQuery.trim();
    final speciesSearchResults =
        speciesCatalogReady && activeSpeciesSearchQuery.isNotEmpty
            ? _speciesLookupService.search(
                widget.references.speciesEntries,
                activeSpeciesSearchQuery,
                limit: 8,
              )
            : const <PokemonDatabaseIndexEntry>[];
    final resolvedItem =
        widget.references.itemsCatalogView.isAvailable && heldItemId.isNotEmpty
            ? _itemsLookupService.findById(
                widget.references.itemsCatalogView.entries,
                heldItemId,
              )
            : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorEmbeddedSectionLabel('TRAINER POKÉMON'),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonDatabaseIndexEntry>(
              keyPrefix: 'trainer-library-pokemon-species',
              title: 'Find a species in the local Pokédex',
              description: speciesCatalogReady
                  ? 'Search by species name, local id or Pokédex number.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              disabledPlaceholder: 'Local Pokédex unavailable',
              searchPlaceholder: 'Search a project species',
              onSearchChanged: _handleSpeciesSearchChanged,
              subtitleBuilder: (entry) => [
                '#${entry.nationalDex.toString().padLeft(4, '0')}',
                entry.types.join('/'),
                entry.id,
              ].join(' • '),
              onSelected: (entry) {
                widget.speciesController.text = entry.id;
              },
            ),
            const SizedBox(height: 6),
            if (activeSpeciesSearchQuery.isNotEmpty) ...[
              Text(
                speciesSearchResults.isEmpty
                    ? 'Current search: "$activeSpeciesSearchQuery". No local species found. The current selection stays unchanged.'
                    : 'Current search: "$activeSpeciesSearchQuery". Select a species below to replace the current selection.',
                key: const Key(
                  'trainer-library-pokemon-species-search-status',
                ),
                style: TextStyle(
                  color: speciesSearchResults.isEmpty
                      ? EditorChrome.inspectorJoyCoral
                      : subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    speciesId.isEmpty
                        ? 'No species selected yet.'
                        : resolvedSpecies == null
                            ? speciesCatalogReady
                                ? 'Selected species ID not present in the local Pokédex: $speciesId'
                                : 'Local species verification unavailable. Raw species ID is kept as-is: $speciesId'
                            : 'Selected species: ${resolvedSpecies.primaryName} • #${resolvedSpecies.nationalDex.toString().padLeft(4, '0')} • ${resolvedSpecies.id}',
                    key: const Key(
                      'trainer-library-pokemon-selected-species-status',
                    ),
                    style: TextStyle(
                      color: speciesId.isNotEmpty && resolvedSpecies == null
                          ? EditorChrome.inspectorJoyCoral
                          : subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                if (speciesId.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  CupertinoButton(
                    key: const Key(
                      'trainer-library-pokemon-clear-species-button',
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: () {
                      widget.speciesController.clear();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Level',
                    fieldKey: const Key('trainer-library-pokemon-level-field'),
                    controller: widget.levelController,
                    placeholder: '1',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Gender',
                    fieldKey: const Key('trainer-library-pokemon-gender-field'),
                    controller: widget.genderController,
                    placeholder: 'male / female / any',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final gender in _trainerQuickGenderValues)
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: widget.genderController.text.trim() != gender,
                    onPressed: () {
                      widget.genderController.text = gender;
                    },
                    child: Text(gender),
                  ),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: widget.genderController.text.trim().isNotEmpty,
                  onPressed: () {
                    widget.genderController.clear();
                  },
                  child: const Text('Clear gender'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Shiny',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                MacosSwitch(
                  value: widget.shiny,
                  onChanged: widget.onToggleShiny,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final guidedMoves = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        speciesId.isNotEmpty
                    ? const _TrainerGuidedMoveSuggestions(
                        description:
                            'Loading the local learnset for this species… Guided move suggestions will appear when the data is ready.',
                        disabledPlaceholder: 'Loading local learnset…',
                      )
                    : _buildTrainerGuidedMoveSuggestions(
                        rawSpeciesId: speciesId,
                        level: level,
                        isSpeciesCatalogAvailable: speciesCatalogReady,
                        resolvedSpecies: resolvedSpecies,
                        speciesDetail: detail,
                        movesCatalogView: widget.references.movesCatalogView,
                      );
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);
                final itemStatus = heldItemId.isEmpty
                    ? 'No held item selected.'
                    : resolvedItem == null
                        ? widget.references.itemsCatalogView.isAvailable
                            ? 'The current held item value is not resolved in the local item catalog.'
                            : 'Local item catalog unavailable. The raw value is kept as-is.'
                        : 'Selected item: ${resolvedItem.name} • ${resolvedItem.id}';
                final formStatus = formId.isEmpty
                    ? 'No form override selected.'
                    : availableForms.contains(formId)
                        ? 'Selected form: $formId'
                        : 'Current raw form override: $formId';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InspectorEmbeddedSectionLabel('MOVES'),
                    const SizedBox(height: 8),
                    // Guided move suggestions stay local to this species draft.
                    // We deliberately keep them in the widget layer because
                    // they are a presentational helper over already-loaded
                    // authoring data, not a second trainer domain service.
                    for (var i = 0; i < widget.moveControllers.length; i++) ...[
                      _TrainerMoveSlotEditor(
                        slotIndex: i,
                        controller: widget.moveControllers[i],
                        catalogView: widget.references.movesCatalogView,
                        guidedMoves: guidedMoves,
                      ),
                      if (i != widget.moveControllers.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (guidedMoves.missingCatalogMoveIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Some locally available learnset moves are missing from the local move catalog: ${guidedMoves.missingCatalogMoveIds.join(', ')}.',
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const InspectorEmbeddedSectionLabel('ITEM / FORM'),
                    const SizedBox(height: 8),
                    _TrainerCatalogAssistField<PokemonItemCatalogEntryView>(
                      keyPrefix: 'trainer-library-pokemon-item',
                      title: 'Find an item in the local catalog',
                      description: widget
                              .references.itemsCatalogView.isAvailable
                          ? 'Search by item name or local id.'
                          : widget.references.itemsCatalogView.message ??
                              widget.references.itemsCatalogView.description,
                      entries: widget.references.itemsCatalogView.entries,
                      lookupService: _itemsLookupService,
                      enabled: widget.references.itemsCatalogView.isAvailable,
                      disabledPlaceholder: 'Local item catalog unavailable',
                      searchPlaceholder: 'Search a project item',
                      subtitleBuilder: (entry) => entry.id,
                      onSelected: (entry) {
                        widget.itemController.text = entry.id;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemStatus,
                      style: TextStyle(
                        color: heldItemId.isNotEmpty && resolvedItem == null
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              speciesId.isNotEmpty
                          ? 'Loading local forms for this species…'
                          : speciesId.isEmpty
                              ? 'Choose a species to check local form suggestions.'
                              : detail == null
                                  ? 'Unable to verify local forms for this species right now. The raw fallback remains available.'
                                  : availableForms.isEmpty
                                      ? 'No local form suggestion is available for this species. The raw fallback remains available.'
                                      : 'Local form suggestions:',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formStatus,
                      style: TextStyle(
                        color: formId.isNotEmpty &&
                                availableForms.isNotEmpty &&
                                !availableForms.contains(formId)
                            ? EditorChrome.inspectorJoyCoral
                            : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (availableForms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final formId in availableForms)
                            PushButton(
                              key: Key(
                                'trainer-library-pokemon-form-suggestion-$formId',
                              ),
                              controlSize: ControlSize.small,
                              secondary:
                                  widget.formController.text.trim() != formId,
                              onPressed: () {
                                widget.formController.text = formId;
                              },
                              child: Text(formId),
                            ),
                          PushButton(
                            key: const Key(
                              'trainer-library-pokemon-form-clear-button',
                            ),
                            controlSize: ControlSize.small,
                            secondary:
                                widget.formController.text.trim().isNotEmpty,
                            onPressed: () {
                              widget.formController.clear();
                            },
                            child: const Text('Clear form'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildRawFallbackSection(context),
                  ],
                );
              },
            ),
            if (widget.validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  key: const Key('trainer-library-pokemon-save-button'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onSave,
                  child: const Text(
                    'Save Pokémon',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMoveSlotEditor extends StatelessWidget {
  const _TrainerMoveSlotEditor({
    required this.slotIndex,
    required this.controller,
    required this.catalogView,
    required this.guidedMoves,
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;
  final _TrainerGuidedMoveSuggestions guidedMoves;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final moveId = controller.text.trim();
    final resolvedMove = catalogView.isAvailable
        ? _movesLookupService.findById(catalogView.entries, moveId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainerCatalogAssistField<PokemonMoveCatalogEntryView>(
          keyPrefix: 'trainer-library-pokemon-move-$slotIndex',
          title: 'Move slot ${slotIndex + 1}',
          description: guidedMoves.description,
          entries: guidedMoves.entries,
          lookupService: _movesLookupService,
          enabled: guidedMoves.entries.isNotEmpty,
          disabledPlaceholder: guidedMoves.disabledPlaceholder,
          searchPlaceholder: 'Search an available move',
          subtitleBuilder: (entry) => [
            ...?guidedMoves.sourceLabelsByMoveId[entry.id],
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.power != null) 'Power ${entry.power}',
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
        ),
        const SizedBox(height: 4),
        Text(
          moveId.isEmpty
              ? 'Slot empty.'
              : resolvedMove == null
                  ? catalogView.isAvailable
                      ? 'Raw move ID not resolved in the local move catalog.'
                      : 'Move catalog unavailable: the raw value is kept as-is.'
                  : 'Selected move: ${resolvedMove.name} • ${resolvedMove.id}',
          style: TextStyle(
            color: moveId.isNotEmpty && resolvedMove == null
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// This stays a local trainer widget on purpose: it is a small affordance for
// catalog-backed authoring, not a generic search framework for the editor.
class _TrainerCatalogAssistField<T> extends StatefulWidget {
  const _TrainerCatalogAssistField({
    required this.keyPrefix,
    required this.title,
    required this.description,
    required this.entries,
    required this.lookupService,
    required this.enabled,
    required this.disabledPlaceholder,
    required this.searchPlaceholder,
    required this.onSelected,
    this.subtitleBuilder,
    this.onSearchChanged,
  });

  final String keyPrefix;
  final String title;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String disabledPlaceholder;
  final String searchPlaceholder;
  final ValueChanged<T> onSelected;
  final String Function(T entry)? subtitleBuilder;
  final ValueChanged<String>? onSearchChanged;

  @override
  State<_TrainerCatalogAssistField<T>> createState() =>
      _TrainerCatalogAssistFieldState<T>();
}

class _TrainerCatalogAssistFieldState<T>
    extends State<_TrainerCatalogAssistField<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.onSearchChanged?.call(_searchController.text);
    if (mounted) {
      setState(() {});
    }
  }

  void _selectEntry(T entry) {
    widget.onSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canSearch = widget.enabled && widget.entries.isNotEmpty;
    final suggestions = canSearch
        ? widget.lookupService.search(
            widget.entries,
            _searchController.text,
            limit: 8,
          )
        : List<T>.empty(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: Key('${widget.keyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          placeholder: widget.enabled
              ? widget.searchPlaceholder
              : widget.disabledPlaceholder,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (!canSearch)
            Text(
              'Aucune suggestion locale disponible pour le moment.',
              key: Key('${widget.keyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun résultat local pour cette recherche.',
              key: Key('${widget.keyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.keyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  final title = widget.lookupService.labelOf(entry);
                  final id = widget.lookupService.idOf(entry);
                  final subtitle = widget.subtitleBuilder?.call(entry);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.islandFillElevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentWarm.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: CupertinoButton(
                      key: Key('${widget.keyPrefix}-suggestion-$id'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onPressed: () => _selectEntry(entry),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$title • $id',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: subtle,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _TrainerSummaryChip extends StatelessWidget {
  const _TrainerSummaryChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerInlineField extends StatelessWidget {
  const _TrainerInlineField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Références locales et draft UI
// ---------------------------------------------------------------------------

class _TrainerReferenceData {
  const _TrainerReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
    required this.movesCatalogView,
    required this.itemsCatalogView,
  });

  const _TrainerReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Chargement des références locales… La saisie brute reste possible pendant ce chargement.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des attaques…',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des objets…',
        );

  const _TrainerReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Aucun workspace Pokémon exploitable. La saisie brute reste possible, mais sans assistance locale.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des attaques indisponible.',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des objets indisponible.',
        );

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
  final PokemonMovesCatalogView movesCatalogView;
  final PokemonItemsCatalogView itemsCatalogView;
}

class _TrainerPokemonDraft {
  const _TrainerPokemonDraft({
    required this.speciesId,
    required this.level,
    required this.moves,
    required this.heldItemId,
    required this.formId,
    required this.gender,
    required this.shiny,
  });

  final String speciesId;
  final int? level;
  final List<String> moves;
  final String? heldItemId;
  final String? formId;
  final String? gender;
  final bool shiny;
}

class _TrainerGuidedMoveSuggestions {
  const _TrainerGuidedMoveSuggestions({
    required this.description,
    required this.disabledPlaceholder,
    this.entries = const <PokemonMoveCatalogEntryView>[],
    this.sourceLabelsByMoveId = const <String, List<String>>{},
    this.missingCatalogMoveIds = const <String>[],
  });

  final String description;
  final String disabledPlaceholder;
  final List<PokemonMoveCatalogEntryView> entries;
  final Map<String, List<String>> sourceLabelsByMoveId;
  final List<String> missingCatalogMoveIds;
}

// ---------------------------------------------------------------------------
// Helpers purs
// ---------------------------------------------------------------------------

String? _normalizeOptionalField(String rawValue) {
  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _splitCommaSeparatedValues(String rawValue) {
  return rawValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

void _clearTextControllers(Iterable<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.clear();
  }
}

bool _trainerMatchesSearch(ProjectTrainerEntry trainer, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }

  final searchTerms = <String>[
    trainer.id,
    trainer.name,
    trainer.trainerClass,
    ...trainer.tags,
    ...trainer.team.map((pokemon) => pokemon.speciesId),
  ].map((value) => value.trim().toLowerCase());

  for (final term in searchTerms) {
    if (term.contains(query)) {
      return true;
    }
  }
  return false;
}

List<String> _buildSpeciesFormSuggestions(PokemonSpeciesFile species) {
  // We only expose forms that truly exist in the local species payload.
  // Earlier code synthesized a `base` value when the data did not provide one,
  // which made the assist UI look more certain than it really was.
  final candidates = <String>[
    if (species.forms.formId.trim().isNotEmpty) species.forms.formId.trim(),
    ...species.forms.otherForms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    if (seen.add(candidate)) {
      unique.add(candidate);
    }
  }
  return unique;
}

String _buildAuthorFacingCatalogUnavailableMessage({
  required String subjectLabel,
  required String fallbackMessage,
  String? technicalMessage,
}) {
  final trimmedTechnicalMessage = technicalMessage?.trim() ?? '';

  // The authoring surface should explain the degraded state in product terms
  // first. Raw file paths or manifest jargon belong in logs/tests, not in the
  // primary UI copy that blocks someone from finishing a trainer.
  if (trimmedTechnicalMessage.isEmpty) {
    return 'Unable to load the local $subjectLabel for this project. '
        '$fallbackMessage';
  }

  final normalizedTechnicalMessage = trimmedTechnicalMessage.toLowerCase();
  if (normalizedTechnicalMessage.contains('manifest') ||
      normalizedTechnicalMessage.contains('catalog') ||
      normalizedTechnicalMessage.contains('not found') ||
      normalizedTechnicalMessage.contains('workspace')) {
    return 'Unable to load the local $subjectLabel for this project. '
        '$fallbackMessage';
  }

  final firstLine = trimmedTechnicalMessage.split('\n').first.trim();
  return firstLine.isEmpty
      ? 'Unable to load the local $subjectLabel for this project. '
          '$fallbackMessage'
      : '$firstLine $fallbackMessage';
}

_TrainerGuidedMoveSuggestions _buildTrainerGuidedMoveSuggestions({
  required String rawSpeciesId,
  required int? level,
  required bool isSpeciesCatalogAvailable,
  required PokemonDatabaseIndexEntry? resolvedSpecies,
  required PokedexSpeciesDetail? speciesDetail,
  required PokemonMovesCatalogView movesCatalogView,
}) {
  final speciesId = rawSpeciesId.trim();
  if (speciesId.isEmpty) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Choose a species first. Guided move suggestions depend on the selected Pokémon and its current level.',
      disabledPlaceholder: 'Choose a species first',
    );
  }

  if (level == null || level <= 0) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Enter a valid level first. Guided move suggestions only show attacks already available at the current level.',
      disabledPlaceholder: 'Enter a valid level first',
    );
  }

  if (!movesCatalogView.isAvailable) {
    return _TrainerGuidedMoveSuggestions(
      description: _buildAuthorFacingCatalogUnavailableMessage(
        subjectLabel: 'move data',
        fallbackMessage:
            'Guided suggestions are unavailable, but raw move IDs stay possible below.',
        technicalMessage: movesCatalogView.message,
      ),
      disabledPlaceholder: 'Guided move suggestions unavailable',
    );
  }

  if (resolvedSpecies == null && isSpeciesCatalogAvailable) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'The selected species is not present in the local Pokédex. Guided move suggestions are unavailable for this entry.',
      disabledPlaceholder: 'Unknown local species',
    );
  }

  if (speciesDetail == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'No local species detail is available for this Pokémon right now. Guided move suggestions are unavailable, but raw IDs stay possible.',
      disabledPlaceholder: 'Species detail unavailable',
    );
  }

  final learnset = speciesDetail.learnset;
  if (learnset == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      disabledPlaceholder: 'No local learnset',
    );
  }

  final sourceLabelsByMoveId = <String, List<String>>{};

  void addSource(String moveId, String label) {
    final normalizedMoveId = moveId.trim();
    if (normalizedMoveId.isEmpty) {
      return;
    }
    final labels = sourceLabelsByMoveId.putIfAbsent(
      normalizedMoveId,
      () => <String>[],
    );
    if (!labels.contains(label)) {
      labels.add(label);
    }
  }

  for (final moveId in learnset.startingMoves) {
    addSource(moveId, 'Start');
  }
  for (final moveId in learnset.relearnMoves) {
    addSource(moveId, 'Relearn');
  }
  for (final entry in learnset.levelUp) {
    if (entry.level <= level) {
      addSource(entry.moveId, 'Lv.${entry.level}');
    }
  }

  if (sourceLabelsByMoveId.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'No starting, relearn or level-up moves are available locally for this species at Lv.$level.',
      disabledPlaceholder: 'No guided move available',
    );
  }

  final resolvedEntries = <PokemonMoveCatalogEntryView>[];
  final missingCatalogMoveIds = <String>[];
  for (final moveId in sourceLabelsByMoveId.keys) {
    final entry = _movesLookupService.findById(
      movesCatalogView.entries,
      moveId,
    );
    if (entry == null) {
      missingCatalogMoveIds.add(moveId);
      continue;
    }
    resolvedEntries.add(entry);
  }

  final missingSuffix = missingCatalogMoveIds.isEmpty
      ? ''
      : ' Some learnset moves are missing from the local move catalog: ${missingCatalogMoveIds.join(', ')}.';

  if (resolvedEntries.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'The local learnset for this species does not resolve to any move present in the local move catalog.$missingSuffix Raw IDs stay possible.',
      disabledPlaceholder: 'No guided move available',
      missingCatalogMoveIds: missingCatalogMoveIds,
    );
  }

  return _TrainerGuidedMoveSuggestions(
    description:
        'Showing moves available from starting, relearn and level-up data up to Lv.$level.$missingSuffix',
    disabledPlaceholder: 'Search the moves available now',
    entries: resolvedEntries,
    sourceLabelsByMoveId: sourceLabelsByMoveId,
    missingCatalogMoveIds: missingCatalogMoveIds,
  );
}

```

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Widgets trainer
// ---------------------------------------------------------------------------

class _TrainerReferencesBanner extends StatelessWidget {
  const _TrainerReferencesBanner({
    required this.references,
    required this.onRefresh,
  });

  final _TrainerReferenceData references;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final itemState = references.itemsCatalogView.isAvailable
        ? '${references.itemsCatalogView.entries.length} items'
        : 'items indisponibles';
    final moveState = references.movesCatalogView.isAvailable
        ? '${references.movesCatalogView.entries.length} moves'
        : 'moves indisponibles';
    final speciesState = references.isSpeciesAvailable
        ? '${references.speciesEntries.length} espèces'
        : 'espèces indisponibles';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trainer Studio references · $speciesState · $moveState · $itemState',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('trainer-library-refresh-references-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(1, 28),
                  onPressed: onRefresh,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              references.speciesMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.movesCatalogView.isAvailable
                  ? references.movesCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'move data',
                      fallbackMessage:
                          'Guided move suggestions stay unavailable until the local catalog can be read.',
                      technicalMessage: references.movesCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.itemsCatalogView.isAvailable
                  ? references.itemsCatalogView.description
                  : _buildAuthorFacingCatalogUnavailableMessage(
                      subjectLabel: 'item data',
                      fallbackMessage:
                          'Raw item IDs stay possible while the local catalog is unavailable.',
                      technicalMessage: references.itemsCatalogView.message,
                    ),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOperationBanner extends StatelessWidget {
  const _TrainerOperationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TrainerEditorCard extends StatelessWidget {
  const _TrainerEditorCard({
    super.key,
    required this.title,
    required this.accent,
    required this.nameController,
    required this.classController,
    required this.portraitController,
    required this.battleThemeController,
    required this.victoryThemeController,
    required this.tagsController,
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onSelectCharacter,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final Color accent;
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController portraitController;
  final TextEditingController battleThemeController;
  final TextEditingController victoryThemeController;
  final TextEditingController tagsController;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-name-field'
                  : 'trainer-library-edit-name-field',
            ),
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-class-field'
                  : 'trainer-library-edit-class-field',
            ),
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 24),
            alignment: Alignment.centerLeft,
            onPressed: onToggleAdvanced,
            child: Text(
              showAdvanced
                  ? 'Hide optional references'
                  : 'Show optional references',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (showAdvanced) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-portrait-field'
                    : 'trainer-library-edit-portrait-field',
              ),
              controller: portraitController,
              placeholder: 'Raw portrait element ID (optional)',
            ),
            if (!portraitIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Portrait element ID is not present in the project elements.',
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-battle-theme-field'
                    : 'trainer-library-edit-battle-theme-field',
              ),
              controller: battleThemeController,
              placeholder: 'Raw battle theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-victory-theme-field'
                    : 'trainer-library-edit-victory-theme-field',
              ),
              controller: victoryThemeController,
              placeholder: 'Raw victory theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-tags-field'
                    : 'trainer-library-edit-tags-field',
              ),
              controller: tagsController,
              placeholder: 'Tags (comma separated, optional)',
            ),
            const SizedBox(height: 6),
            Text(
              'Ces refs optionnelles restent brutes pour le moment. Seul le portrait est vérifié contre les éléments du projet ; battle theme, victory theme et tags sont conservés tels quels.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              validationMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onSubmit,
                child: Text(
                  createMode ? 'Create' : 'Save',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
}

```

### `packages/map_editor/test/trainer_library_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

void main() {
  Future<void> pumpTrainerPanel(
    WidgetTester tester,
    ProviderContainer container, {
    bool embedded = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: embedded ? 420 : 1280,
                height: 1800,
                child: embedded
                    ? const TrainerLibraryPanel(embedded: true)
                    : const TrainerLibraryPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('embedded mode acts as a launcher for the main Trainer Studio',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_embedded',
      project: ProjectManifest(
        name: 'trainers_panel_embedded',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container, embedded: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('trainer-library-open-studio-button')),
        findsOneWidget);
    expect(find.byKey(const Key('trainer-library-new-trainer-button')),
        findsNothing);
    expect(find.text('Trainer Studio'), findsWidgets);

    await tester
        .tap(find.byKey(const Key('trainer-library-open-studio-button')));
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.trainer,
    );
    expect(
      container.read(editorNotifierProvider).selectedTrainerId,
      'misty',
    );
  });

  testWidgets(
      'creates a trainer and saves a complete team entry with assisted refs',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );
    await tester.tap(find.text('Show optional references'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-battle-theme-field')),
      'battle_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-victory-theme-field')),
      'victory_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-tags-field')),
      ' rival, gym ',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final trainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.name, 'Misty');
    expect(trainer.battleThemeId, 'battle_misty');
    expect(trainer.victoryThemeId, 'victory_misty');
    expect(trainer.tags, <String>['rival', 'gym']);

    await tester.tap(
      find.byKey(Key('trainer-library-add-pokemon-button-${trainer.id}')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.tap(find.text('female'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'tackle',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-tackle'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-search-field')),
      'growl',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-1-suggestion-growl'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-search-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-search-field')),
      'oran',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-item-suggestion-oran_berry'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-form-suggestion-blossom'),
      ),
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 12);
    expect(pokemon.moves, <String>['tackle', 'growl']);
    expect(pokemon.heldItemId, 'oran_berry');
    expect(pokemon.formId, 'blossom');
    expect(pokemon.gender, 'female');
    expect(pokemon.shiny, isFalse);
    expect(
      find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the active species selection separate from a later empty search query',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => const <PokemonDatabaseIndexEntry>[
            PokemonDatabaseIndexEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              genIntroduced: 1,
              types: <String>['grass', 'poison'],
              isEnabledInProject: true,
              refs: PokemonDatabaseIndexRefs(
                learnset: 'bulbasaur',
                evolution: 'bulbasaur',
                media: 'bulbasaur',
              ),
            ),
            PokemonDatabaseIndexEntry(
              id: 'caterpie',
              nationalDex: 10,
              primaryName: 'Caterpie',
              genIntroduced: 1,
              types: <String>['bug'],
              isEnabledInProject: true,
              refs: PokemonDatabaseIndexRefs(
                learnset: 'caterpie',
                evolution: 'caterpie',
                media: 'caterpie',
              ),
            ),
          ],
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'cater',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-caterpie'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trainer-library-pokemon-selected-species-status')),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'pikachu',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trainer-library-pokemon-species-search-status')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Current search: "pikachu". No local species found. The current selection stays unchanged.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Selected species: Caterpie'), findsOneWidget);
  });

  testWidgets(
      'shows guided move suggestions from the selected learnset and level',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'vine',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-vine_whip'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Lv.7'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'razor',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-razor_leaf'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-empty')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline validation when a move is unknown locally',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Move 1 references an unknown local move: missing_move'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'does not invent a base form suggestion when the local species detail has none',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  forms: const PokemonSpeciesForms(
                    baseFormId: 'bulbasaur',
                    isBaseForm: true,
                    formId: '',
                    otherForms: <String>[],
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local form suggestion is available for this species. The raw fallback remains available.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
      findsNothing,
    );
  });

  testWidgets(
      'keeps species and form messaging honest when local species assistance is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, __) async => throw StateError('detail loader exploded'),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Impossible de charger les espèces locales. La saisie brute reste possible.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify local forms for this species right now. The raw fallback remains available.',
      ),
      findsOneWidget,
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.ensureVisible(savePokemonButton);
    await tester.pumpAndSettle();
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.speciesId, 'bulbasaur');

    await tester.scrollUntilVisible(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Local species index unavailable. The raw value is kept as-is.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => throw StateError('moves loader exploded'),
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogError: StateError('items loader exploded'),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Unable to load the local move data for this project.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Unable to load the local item data for this project.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'mystery_item',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
  });

  testWidgets(
      'keeps raw move fallback available when the local learnset is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(learnset: null)
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No local learnset is available for this species. Guided move suggestions are unavailable, but raw IDs stay possible.',
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('trainer-library-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-raw-fallback-toggle-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'tackle',
    );

    final savePokemonButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('trainer-library-pokemon-save-button')),
    );
    savePokemonButton.onPressed!.call();
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.moves, <String>['tackle']);
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
];

const PokemonMovesCatalogView _movesCatalogView = PokemonMovesCatalogView(
  entries: <PokemonMoveCatalogEntryView>[
    PokemonMoveCatalogEntryView(
      id: 'growl',
      name: 'Growl',
      type: 'normal',
      category: 'status',
      pp: 40,
    ),
    PokemonMoveCatalogEntryView(
      id: 'tackle',
      name: 'Tackle',
      type: 'normal',
      category: 'physical',
      power: 40,
      pp: 35,
    ),
    PokemonMoveCatalogEntryView(
      id: 'vine_whip',
      name: 'Vine Whip',
      type: 'grass',
      category: 'physical',
      power: 45,
      pp: 25,
    ),
    PokemonMoveCatalogEntryView(
      id: 'razor_leaf',
      name: 'Razor Leaf',
      type: 'grass',
      category: 'physical',
      power: 55,
      pp: 25,
    ),
  ],
  isAvailable: true,
  description: 'Catalogue local des attaques.',
);

const PokemonCatalogFile _itemsCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
      'aliases': <String>['oran'],
    },
  ],
);

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{
  'bulbasaur': _buildDetail(),
};

PokedexSpeciesDetail _buildDetail({
  PokemonSpeciesForms forms = const PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
    otherForms: <String>['blossom'],
  ),
  PokemonLearnsetFile? learnset = const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle'],
    relearnMoves: <String>['growl'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level-up',
        versionGroup: 'project',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'razor_leaf',
        level: 20,
        source: 'level-up',
        versionGroup: 'project',
      ),
    ],
  ),
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{'en': 'Bulbasaur'},
      speciesName: <String, String>{'en': 'Seed Pokemon'},
      genIntroduced: 1,
      typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'overgrow'),
      breeding: const PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
        eggGroups: <String>['monster', 'grass'],
        hatchCycles: 20,
      ),
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: forms,
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: const PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
        flavorText: 'A strange seed was planted on its back at birth.',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(starterEligible: true),
      sourceMeta:
          const PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
    ),
    learnset: learnset,
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
    this.catalogError,
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Object? catalogError;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (catalogError != null) {
      throw catalogError!;
    }
    final catalog = catalogByKey[catalogKey];
    if (catalog == null) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    return catalog;
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }
}

```

### `packages/map_editor/test/pokemon_project_data_reader_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late PokemonProjectDataReader reader;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_readers_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    reader = const PokemonProjectDataReader();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonProjectDataReader', () {
    test('reads the manifest from the project workspace', () async {
      await seedUseCase.execute(workspace);

      final manifest = await reader.readManifest(workspace);

      expect(manifest.schemaVersion, 1);
      expect(manifest.kind, 'pokemon_data_manifest');
      expect(
        manifest.catalogFiles['moves'],
        'catalogs/moves.json',
      );
      expect(
        manifest.futureDataFolders['species'],
        'species/',
      );
    });

    test('reads a species file by id', () async {
      await seedUseCase.execute(workspace);

      final species = await reader.readSpeciesById(workspace, 'bulbasaur');

      expect(species.id, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.typing.types, <String>['grass', 'poison']);
      expect(species.refs.learnset, 'bulbasaur');
      expect(species.refs.evolution, 'bulbasaur');
      expect(species.refs.media, 'bulbasaur');
      expect(species.dexContent.heightM, 0.7);
      expect(species.gameplayFlags.starterEligible, isTrue);
      expect(species.sourceMeta.seededBy, 'SeedPokemonDemoDataUseCase');
    });

    test('reads a learnset file with explicit level-up entries', () async {
      await seedUseCase.execute(workspace);

      final learnset = await reader.readLearnsetById(workspace, 'bulbasaur');

      expect(learnset.speciesId, 'bulbasaur');
      expect(learnset.startingMoves, containsAll(<String>['tackle', 'growl']));
      expect(learnset.levelUp, isNotEmpty);
      expect(learnset.levelUp.first.moveId, 'tackle');
      expect(learnset.levelUp.first.level, 1);
      expect(learnset.levelUp.first.source, 'level_up');
      expect(learnset.levelUp.first.versionGroup, 'demo');
    });

    test('reads an evolution file', () async {
      await seedUseCase.execute(workspace);

      final evolution = await reader.readEvolutionById(workspace, 'bulbasaur');

      expect(evolution.speciesId, 'bulbasaur');
      expect(evolution.preEvolution, isNull);
      expect(evolution.evolutions, hasLength(1));
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(evolution.evolutions.single.method, 'level_up');
      expect(evolution.evolutions.single.minLevel, 16);
      expect(
        evolution.evolutions.single.conditionText['en'],
        'Evolves at level 16',
      );
    });

    test('reads a media file', () async {
      await seedUseCase.execute(workspace);

      final media = await reader.readMediaById(workspace, 'bulbasaur');

      expect(media.speciesId, 'bulbasaur');
      expect(media.defaultFormId, 'base');
      expect(media.variants['base']?.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(
        media.variants['base']?.animations['battleFront']?.animationId,
        'battle_front',
      );
    });

    test('reads a catalog by logical key', () async {
      await seedUseCase.execute(workspace);

      final movesCatalog = await reader.readCatalogByKey(workspace, 'moves');

      expect(movesCatalog.catalog, 'moves');
      expect(
        movesCatalog.entries.map((entry) => entry['id']).toSet(),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
    });

    test('lists species files from the workspace project only', () async {
      await seedUseCase.execute(workspace);

      final files = await reader.listSpeciesFiles(workspace);

      expect(
        files,
        <String>[
          'data/pokemon/species/0001-bulbasaur.json',
          'data/pokemon/species/0002-ivysaur.json',
        ],
      );
    });

    test('builds a lightweight species index with stable list data', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.types, <String>['grass', 'poison']);
      expect(
        bulbasaur.relativePath,
        'data/pokemon/species/0001-bulbasaur.json',
      );
    });

    test('uses species id as final primary name fallback instead of filename',
        () async {
      await seedUseCase.execute(workspace);

      final customSpeciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-not-the-display-name.json',
        ),
      );
      await customSpeciesFile.writeAsString('''
{
  "id": "mystery_mon",
  "nationalDex": 9999,
  "names": {},
  "typing": {
    "types": ["grass"]
  }
}
''');

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final mystery = entries.firstWhere((entry) => entry.id == 'mystery_mon');
      final species = await reader.readSpeciesById(workspace, 'mystery_mon');

      expect(mystery.primaryName, 'mystery_mon');
      expect(mystery.relativePath,
          'data/pokemon/species/9999-not-the-display-name.json');
      expect(species.id, 'mystery_mon');
      expect(species.slug, isEmpty);
    });

    test('keeps species lookup coherent with the lightweight index', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final bulbasaurEntry = entries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      final species =
          await reader.readSpeciesById(workspace, bulbasaurEntry.id);

      expect(species.id, bulbasaurEntry.id);
      expect(species.nationalDex, bulbasaurEntry.nationalDex);
      expect(species.names['en'], bulbasaurEntry.primaryName);
      expect(species.typing.types, bulbasaurEntry.types);
    });

    test('throws explicit error when species is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when catalog key is unknown', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readCatalogByKey(workspace, 'berries'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog not declared'),
          ),
        ),
      );
    });

    test('throws explicit error when json is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('fails explicitly when the species projection encounters invalid json',
        () async {
      await seedUseCase.execute(workspace);

      final unrelatedBrokenFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0000-decoy.json',
        ),
      );
      await unrelatedBrokenFile.writeAsString('{ invalid json');

      expect(
        () => reader.listSpeciesIndexEntries(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('throws explicit error when multiple species files resolve to same id',
        () async {
      await seedUseCase.execute(workspace);

      final duplicateFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await duplicateFile.writeAsString('''
{
  "id": "bulbasaur",
  "nationalDex": 9999,
  "names": {
    "en": "Bulbasaur Duplicate"
  },
  "typing": {
    "types": ["grass"]
  }
}
''');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains(
                'Multiple Pokemon species files share the same id "bulbasaur"'),
          ),
        ),
      );
    });

    test('reads from workspace root even if Directory.current points elsewhere',
        () async {
      await seedUseCase.execute(workspace);

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_reader_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('{"id":"decoy","nationalDex":9999}');

        Directory.current = decoy.path;

        final species = await reader.readSpeciesById(workspace, 'bulbasaur');
        final listed = await reader.listSpeciesFiles(workspace);
        final indexed = await reader.listSpeciesIndexEntries(workspace);

        expect(species.id, 'bulbasaur');
        expect(listed, contains('data/pokemon/species/0001-bulbasaur.json'));
        expect(listed.any((path) => path.contains('9999-decoy')), isFalse);
        expect(indexed.any((entry) => entry.id == 'decoy'), isFalse);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged after reads', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Reader Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await reader.readManifest(workspace);
      await reader.readCatalogByKey(workspace, 'moves');
      await reader.readSpeciesById(workspace, 'bulbasaur');
      await reader.readLearnsetById(workspace, 'bulbasaur');
      await reader.readEvolutionById(workspace, 'bulbasaur');
      await reader.listSpeciesFiles(workspace);
      await reader.listSpeciesIndexEntries(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}

```

### `packages/map_editor/test/file_pokemon_read_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/application/use_cases/load_pokedex_species_detail_use_case.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late FilePokemonReadRepository repository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    repository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonReadRepository', () {
    test('reads from the workspace project and not the monorepo root',
        () async {
      await seedUseCase.execute(workspace);

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_repo_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(
              decoy.path, 'data', 'pokemon', 'species', '0003-venusaur.json'),
        ).writeAsString('''
{
  "id": "venusaur",
  "nationalDex": 3,
  "names": {"en": "Venusaur"},
  "typing": {"types": ["grass", "poison"]}
}
''');

        Directory.current = decoy.path;

        final entries = await repository.listSpeciesIndexEntries(workspace);
        final species =
            await repository.readSpeciesById(workspace, 'bulbasaur');

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(species.id, 'bulbasaur');
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('reads the seeded pokemon files through the repository abstraction',
        () async {
      await seedUseCase.execute(workspace);

      final manifest = await repository.readManifest(workspace);
      final species = await repository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await repository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await repository.readEvolutionById(workspace, 'bulbasaur');
      final media = await repository.readMediaById(workspace, 'bulbasaur');
      final moves = await repository.readCatalogByKey(workspace, 'moves');

      expect(manifest.kind, 'pokemon_data_manifest');
      expect(species.id, 'bulbasaur');
      expect(learnset.speciesId, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(media.speciesId, 'bulbasaur');
      expect(media.variants['base']?.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(
        moves.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test(
        'loads species detail and move catalog from project.json-configured paths without pokemon_data_manifest.json',
        () async {
      final customProject = _buildConfiguredPokemonProject();
      await _writeProjectJson(workspace, customProject.toJson());
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/species/0001-bulbasaur.json',
        '''
{
  "id": "bulbasaur",
  "slug": "bulbasaur",
  "nationalDex": 1,
  "names": {"en": "Bulbasaur"},
  "speciesName": {"en": "Seed Pokemon"},
  "genIntroduced": 1,
  "typing": {
    "types": ["grass", "poison"]
  },
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45,
    "bst": 318
  },
  "abilities": {"primary": "overgrow"},
  "breeding": {
    "genderRatio": {"male": 0.875, "female": 0.125},
    "eggGroups": ["monster", "grass"],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 64,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "forms": {
    "baseFormId": "bulbasaur",
    "isBaseForm": true,
    "formId": "base",
    "otherForms": ["blossom"]
  },
  "classification": {
    "isEnabledInProject": true,
    "isObtainable": true
  },
  "refs": {
    "learnset": "bulbasaur",
    "evolution": "bulbasaur",
    "media": "bulbasaur"
  },
  "dexContent": {
    "heightM": 0.7,
    "weightKg": 6.9,
    "color": "green",
    "flavorText": "A strange seed was planted on its back at birth."
  },
  "gameplayFlags": {"starterEligible": true},
  "sourceMeta": {"seededBy": "test", "seedVersion": 1}
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/learnsets/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "startingMoves": ["tackle"],
  "relearnMoves": ["growl"],
  "levelUp": [
    {
      "moveId": "vine_whip",
      "level": 7,
      "source": "level_up",
      "versionGroup": "project"
    },
    {
      "moveId": "razor_leaf",
      "level": 20,
      "source": "level_up",
      "versionGroup": "project"
    }
  ]
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/evolutions/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "evolutions": []
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/media/bulbasaur.json',
        '''
{
  "speciesId": "bulbasaur",
  "defaultFormId": "base",
  "variants": {}
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/catalogs/moves.json',
        '''
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "meta": {
    "description": "Local move catalog."
  },
  "entries": [
    {
      "id": "tackle",
      "name": "Tackle",
      "type": "normal",
      "category": "physical",
      "power": 40,
      "pp": 35
    },
    {
      "id": "growl",
      "name": "Growl",
      "type": "normal",
      "category": "status",
      "pp": 40
    },
    {
      "id": "vine_whip",
      "name": "Vine Whip",
      "type": "grass",
      "category": "physical",
      "power": 45,
      "pp": 25
    }
  ]
}
''',
      );
      await _writeProjectRelativeTextFile(
        workspace,
        'custom/pokemon/catalogs/items.json',
        '''
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "items",
  "meta": {
    "description": "Local item catalog."
  },
  "entries": [
    {
      "id": "oran_berry",
      "name": "Oran Berry",
      "aliases": ["oran"]
    }
  ]
}
''',
      );

      final detailLoader = LoadPokedexSpeciesDetailUseCase(repository);
      final movesLoader = LoadPokemonMovesCatalogUseCase(
        readRepository: repository,
      );
      final itemsLoader = LoadPokemonItemsCatalogUseCase(
        readRepository: repository,
      );

      final detail = await detailLoader.execute(workspace, 'bulbasaur');
      final movesCatalog = await movesLoader.execute(workspace);
      final itemsCatalog = await itemsLoader.execute(workspace);

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset, isNotNull);
      expect(
        detail.learnset!.levelUp.map((entry) => entry.moveId),
        containsAll(<String>['vine_whip', 'razor_leaf']),
      );
      expect(movesCatalog.isAvailable, isTrue);
      expect(
        movesCatalog.entries.map((entry) => entry.id),
        containsAll(<String>['tackle', 'growl', 'vine_whip']),
      );
      expect(itemsCatalog.isAvailable, isTrue);
      expect(
        itemsCatalog.entries.map((entry) => entry.id),
        contains('oran_berry'),
      );
    });

    test('throws explicit error when a species file is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => repository.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when a species json file is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => repository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Repo Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await repository.readSpeciesById(workspace, 'bulbasaur');
      await repository.readCatalogByKey(workspace, 'moves');

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await seedUseCase.execute(workspace);

      await repository.listSpeciesIndexEntries(workspace);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
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

const ProjectManifest _configuredPokemonProject = ProjectManifest(
  name: 'Configured Pokemon Project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  pokemon: ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
      'items': 'custom/pokemon/catalogs/items.json',
    },
  ),
);

ProjectManifest _buildConfiguredPokemonProject() => _configuredPokemonProject;

Future<void> _writeProjectJson(
  ProjectFileSystem workspace,
  Map<String, dynamic> json,
) async {
  await _writeProjectRelativeTextFile(
    workspace,
    'project.json',
    const JsonEncoder.withIndent('  ').convert(json),
  );
}

Future<void> _writeProjectRelativeTextFile(
  ProjectFileSystem workspace,
  String relativePath,
  String contents,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

```
