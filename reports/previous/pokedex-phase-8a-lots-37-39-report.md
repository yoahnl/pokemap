# Pokédex Phase 8A / Lots 37 à 39 — Activation locale, filtre de statut, édition locale simple
## 1. Résumé exécutif honnête
La phase 8A est implémentée sur un périmètre strict et cohérent.

Ce qui a été fait :
- lot 37 : activation / désactivation d’une espèce via la source de vérité locale `PokemonSpeciesFile.classification.isEnabledInProject` ;
- lot 38 : ajout d’un filtre liste `Toutes / Activées / Désactivées` reposant sur la donnée persistée, pas sur un état UI parallèle ;
- lot 39 : ajout d’un mode lecture / édition / enregistrer / annuler dans la fiche détail pour des métadonnées simples uniquement ;
- réutilisation du writer espèce existant via un use case local dédié ;
- extension ciblée de la couverture applicative et UI ;
- zéro modification de `project.json` ;
- zéro démarrage des lots 40+.

Ce qui n’a pas été fait volontairement :
- aucune UI d’import ;
- aucune édition learnset / évolution / média ;
- aucune édition de formes riches ;
- aucune édition de classification lourde hors `isEnabledInProject` ;
- aucun nouveau framework générique ;
- aucun notifier global Pokédex ;
- aucune écriture Git.
## 2. Périmètre exact inclus
Inclus :
- `classification.isEnabledInProject` comme unique source de vérité du statut projet ;
- projection de ce statut dans l’index local léger ;
- filtre UI `Toutes / Activées / Désactivées` ;
- édition locale de `names`, `dexContent.flavorText`, `gameplayFlags.{starterEligible,giftOnly,tradeOnly}` ;
- persistance via `PokemonWriteRepository.saveSpecies(...)` ;
- rechargement liste + détail après sauvegarde ;
- tests applicatifs et UI ciblés.
## 3. Périmètre exact exclu
Exclu :
- lots 40 à 43 et tout lot suivant ;
- édition learnset / évolution / média ;
- édition des formes riches ;
- édition de la classification lourde autre que `isEnabledInProject` ;
- UI d’import ;
- providers/notifiers d’état Pokédex supplémentaires ;
- `project.json` ;
- refonte d’architecture Pokédex ;
- toute écriture Git.
## 4. Design retenu
### Lot 37
- La source de vérité est `PokemonSpeciesFile.classification.isEnabledInProject`.
- Aucun second flag n’a été créé.
- La persistance passe par un unique use case applicatif : `UpdatePokedexSpeciesMetadataUseCase`.

### Lot 38
- `PokemonDatabaseIndexEntry` a été étendu avec un seul booléen : `isEnabledInProject`.
- Ce booléen est alimenté depuis l’espèce déjà parsée par le reader d’index local.
- Le filtre UI reste purement local à la liste déjà chargée ; aucun chargement de fiche détail n’est nécessaire pour filtrer.

### Lot 39
- La fiche détail garde une seule page et ajoute un bloc local `Métadonnées locales` dans l’overview.
- Deux modes existent : lecture / édition.
- Le flux est volontairement simple : `Modifier` → changements locaux → `Enregistrer` ou `Annuler`.
- `Enregistrer` relit / réécrit l’espèce via le repository existant et recharge ensuite l’index + la fiche.
- `Annuler` jette le draft local et n’écrit rien.

### Pourquoi c’est le plus petit changement raisonnable
- un seul use case de persistance pour les lots 37 et 39 ;
- une seule extension minimale de la projection liste pour le lot 38 ;
- aucun nouveau système d’état global ;
- aucune duplication de la donnée `enabled` ;
- aucune seconde voie de lecture ni d’écriture.
## 5. Utilisation des sub-agents
Sub-agents effectivement utilisés (threads existants réutilisés, car la création de nouveaux threads a échoué à cause de la limite max déjà atteinte) :

- Sous-agent A — audit architecture / état actuel
  - retenu : `classification.isEnabledInProject` comme source de vérité, enrichissement minimal de `PokemonDatabaseIndexEntry`, persistance via `saveSpecies(...)`.
- Sous-agent B — design minimal des lots 37-38
  - retenu : booléen `isEnabledInProject` dans l’index et filtre local simple dans le workspace.
  - rejeté : création d’un second use case séparé seulement pour le toggle ; la version finale garde un seul use case commun 37+39 pour éviter deux chemins d’écriture.
- Sous-agent C — design minimal du lot 39
  - retenu : limiter l’édition à `names`, `flavorText` et `gameplayFlags`.
  - rejeté : laisser toute la classification strictement non éditable ; la version finale édite uniquement `isEnabledInProject` parce que le lot 37 l’exige explicitement, sans ouvrir le reste de la classification.
- Sous-agent D — review tests / anti-régression
  - retenu : un vrai test applicatif de persistance + des tests UI `save / cancel / filtre statut / non-régression de sélection`.

Confirmation de discipline :
- aucune variante concurrente n’a été gardée ;
- aucun fichier alternatif issu des sub-agents n’a été laissé dans le working tree ;
- une seule implémentation finale a été intégrée.
## 6. Liste exacte des fichiers touchés
### Modifiés
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_database_index_test.dart`

### Créés
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`
- `packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`
- `reports/pokedex-phase-8a-lots-37-39-report.md`

### Supprimés
- Aucun.

### Audités mais non touchés
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/models/pokedex_species_detail.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `packages/map_editor/test/pokemon_project_data_reader_test.dart`
- `reports/pokedex-phase-7b-species-overwrite-final-fix-report.md`

## 7. Justification fichier par fichier
### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

- Wiring minimal du writer et du use case de sauvegarde pour que la UI puisse rester branchée via les providers existants.
### `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

- Ajout du seul booléen `isEnabledInProject` nécessaire au filtre de statut de liste, sans embarquer toute la classification dans l’index léger.
### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

- Export minimal du nouveau use case applicatif.
### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

- Ajout du filtre de statut, de l’injection du saver, et du rechargement liste+détail après sauvegarde sans notifier global.
### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

- Ajout de la UI du filtre `Toutes / Activées / Désactivées` et du bloc local lecture/édition/enregistrement/annulation dans la fiche détail.
### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

- Extension ciblée des tests UI pour le filtre de statut, le mode édition, `save / cancel`, la persistance visible, et la non-régression de sélection/filtres.
### `packages/map_editor/test/pokemon_database_index_test.dart`

- Extension ciblée des tests d’index pour verrouiller la projection de `isEnabledInProject`.
### `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`

- Nouveau use case local unique de persistance pour 37+39 ; il relit l’espèce existante, ne modifie que les champs autorisés, puis délègue l’écriture au writer existant.
### `packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`

- Nouveaux tests applicatifs ciblés pour la persistance réelle, la préservation des refs, `project.json` inchangé et la non-régression du chemin species.
### `reports/pokedex-phase-8a-lots-37-39-report.md`

- Rapport complet demandé, incluant les commandes réellement exécutées, les résultats réels, les incidents et le contenu complet des fichiers touchés.

## 8. Commandes réellement exécutées
```bash
find /Users/karim/Project/pokemonProject/packages -path '*/AGENTS.md' -print
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '321,760p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '761,1280p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '1281,1640p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '1,360p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
sed -n '1,280p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '281,680p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '681,1160p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1161,1600p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_species_detail.dart
sed -n '420,720p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
rg -n "PokemonDatabaseIndexEntry\(" /Users/karim/Project/pokemonProject/packages/map_editor/lib /Users/karim/Project/pokemonProject/packages/map_editor/test -g '*.dart'
sed -n '130,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
rg -n "saveSpecies\(|saveLearnset\(|class FilePokemonWriteRepository|_resolveSpeciesWritePath" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '246,430p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,360p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '361,820p' /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart
sed -n '260,520p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart
git -C /Users/karim/Project/pokemonProject status --short -- packages/map_editor/lib/src/application/models/pokemon_database_index.dart packages/map_editor/lib/src/application/use_cases packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/pokedex_workspace_ui_test.dart packages/map_editor/test/pokemon_database_index_test.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart reports/pokedex-phase-8a-lots-37-39-report.md
git -C /Users/karim/Project/pokemonProject diff --stat -- packages/map_editor/lib/src/application/models/pokemon_database_index.dart packages/map_editor/lib/src/application/use_cases packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/pokedex_workspace_ui_test.dart packages/map_editor/test/pokemon_database_index_test.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart reports/pokedex-phase-8a-lots-37-39-report.md
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokemon_database_index_test.dart test/pokedex_workspace_ui_test.dart
rg -n "String\? _pickPrimaryName|_pickPrimaryName\(" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1080,1108p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokemon_database_index_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/models/pokemon_database_index.dart lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart lib/src/application/use_cases/use_cases.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/update_pokedex_species_metadata_use_case_test.dart test/pokemon_database_index_test.dart test/pokedex_workspace_ui_test.dart
nl -ba /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart | sed -n '1,40p'
nl -ba /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart | sed -n '1276,1295p'
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/models/pokemon_database_index.dart lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart lib/src/application/use_cases/use_cases.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/update_pokedex_species_metadata_use_case_test.dart test/pokemon_database_index_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/update_pokedex_species_metadata_use_case_test.dart test/pokemon_database_index_test.dart test/pokedex_workspace_ui_test.dart
git -C /Users/karim/Project/pokemonProject status --short -- packages/map_editor/lib/src/application/models/pokemon_database_index.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart packages/map_editor/test/pokemon_database_index_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-phase-8a-lots-37-39-report.md
git -C /Users/karim/Project/pokemonProject diff --stat -- packages/map_editor/lib/src/application/models/pokemon_database_index.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart packages/map_editor/test/pokemon_database_index_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-phase-8a-lots-37-39-report.md
git -C /Users/karim/Project/pokemonProject ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart reports/pokedex-phase-8a-lots-37-39-report.md
```
## 9. Résultats réels
### `dart format`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
Formatted 9 files (5 changed) in 0.04 seconds.
```
Passe(s) de finition supplémentaire(s) :

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
Formatted 2 files (0 changed) in 0.02 seconds.
```
### `flutter test`

Premières passes :
- Première passe `flutter test ...` : échec.
- Cause réelle : les nouveaux contrôles d’édition (`Modifier`, puis les switches) étaient en dehors du viewport de test ; les taps rataient car la fiche détail est scrollable dans une fenêtre de test plus petite que l’éditeur réel.
- Correction appliquée : `tester.ensureVisible(...)` avant les interactions sur les contrôles d’édition et de sauvegarde.

- Deuxième passe `flutter test ...` : échec d’un seul test.
- Cause réelle : le test supposait que le nom principal de liste privilégiait `fr`, alors que le repo privilégie `en` puis `fr` via `_pickPrimaryName(...)`.
- Correction appliquée : le test a été réaligné sur le vrai contrat du repo, et la sauvegarde UI modifie aussi `en` pour prouver que la liste reflète un champ effectivement visible.

Passe finale :

```text
00:04 +41: All tests passed!
```
### `flutter analyze --no-pub`

Première passe :
- Première passe `flutter analyze --no-pub ...` : échec léger.
- Points remontés :
  - une constante locale `_disabledStatusFilterValue` devenue inutilisée dans `pokedex_workspace.dart` ;
  - un `const` manquant pour un `TextStyle` d’erreur locale dans `pokedex_workspace_views.dart`.
- Correction appliquée : suppression de la constante inutile et ajout du `const` manquant.

Passe finale :

```text
No issues found! (ran in 1.1s)
```
### `git status --short -- ...`

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_database_index_test.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
?? packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
?? reports/pokedex-phase-8a-lots-37-39-report.md
```
### `git diff --stat -- ...`

```text
.../app/providers/pokedex/pokedex_providers.dart   |   20 +
.../application/models/pokemon_database_index.dart |   17 +
.../lib/src/application/use_cases/use_cases.dart   |    1 +
.../lib/src/ui/canvas/pokedex_workspace.dart       |   62 +-
.../lib/src/ui/canvas/pokedex_workspace_views.dart | 1092 +++++++++++++++-----
.../map_editor/test/pokedex_workspace_ui_test.dart |  487 ++++++++-
.../test/pokemon_database_index_test.dart          |   94 ++
7 files changed, 1474 insertions(+), 299 deletions(-)
```
### `git ls-files --others --exclude-standard -- ...`

```text
packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
reports/pokedex-phase-8a-lots-37-39-report.md
```
## 10. Incidents rencontrés
- `spawn_agent` n’a pas pu créer de nouveaux sous-agents à cause de la limite de threads déjà atteinte ; j’ai réutilisé proprement des threads d’agents existants via `send_input`, puis j’ai centralisé l’intégration finale.
- La première passe de tests UI a échoué parce que les nouveaux contrôles d’édition étaient hors viewport dans la fenêtre de test. Ce n’était pas un bug produit, mais un vrai bug de test. Correction : `ensureVisible(...)`.
- Une autre passe de tests UI a échoué parce qu’un test supposait à tort que le nom principal de liste favorisait `fr`. Le repo favorise `en` puis `fr`. Le test a été corrigé pour coller au contrat réel.
- Une première passe d’analyse a signalé une constante devenue inutile et un `const` manquant. Correction locale immédiate.
- Aucun incident n’a nécessité de toucher un fichier hors scope ou d’élargir le périmètre fonctionnel.
## 11. État Git utile final
```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_database_index_test.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
?? packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
?? reports/pokedex-phase-8a-lots-37-39-report.md
```
```text
.../app/providers/pokedex/pokedex_providers.dart   |   20 +
.../application/models/pokemon_database_index.dart |   17 +
.../lib/src/application/use_cases/use_cases.dart   |    1 +
.../lib/src/ui/canvas/pokedex_workspace.dart       |   62 +-
.../lib/src/ui/canvas/pokedex_workspace_views.dart | 1092 +++++++++++++++-----
.../map_editor/test/pokedex_workspace_ui_test.dart |  487 ++++++++-
.../test/pokemon_database_index_test.dart          |   94 ++
7 files changed, 1474 insertions(+), 299 deletions(-)
```
```text
packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
reports/pokedex-phase-8a-lots-37-39-report.md
```
## 12. Limites restantes
- Le mode édition locale de cette phase reste limité à `names`, `flavorText`, `gameplayFlags` et `isEnabledInProject`.
- Aucune édition de learnset, évolution, média, formes riches ou classification lourde n’est ouverte ici.
- Il n’y a pas encore de dialogue de confirmation si l’utilisateur abandonne un draft en changeant d’espèce ; aujourd’hui, le changement de sélection recharge proprement la vérité locale et jette le draft.
- Le filtre de statut reste volontairement simple : `Toutes / Activées / Désactivées`, sans combinaisons avancées supplémentaires.
## 13. Contenu complet de tous les fichiers touchés
### 13.1 `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../ui/canvas/pokedex_workspace_loader.dart';
import '../core/repository_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.
final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonWriteRepositoryProvider = Provider<PokemonWriteRepository>((ref) {
  return const FilePokemonWriteRepository();
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final updatePokedexSpeciesMetadataUseCaseProvider =
    Provider<UpdatePokedexSpeciesMetadataUseCase>((ref) {
  return UpdatePokedexSpeciesMetadataUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMetadataSaverProvider =
    Provider<PokedexSpeciesMetadataSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMetadataUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

```
### 13.2 `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

```dart
import 'pokemon_project_data_models.dart';

/// References legeres exposees par l'index local Pokemon.
///
/// On regroupe ici uniquement les refs deja presentes dans le JSON espece.
/// Le but n'est pas d'introduire un nouveau contrat metier ; on fournit juste
/// une forme stable et lisible pour les prochains lots qui voudront afficher
/// une liste d'especes puis ouvrir des details ciblés.
class PokemonDatabaseIndexRefs {
  const PokemonDatabaseIndexRefs({
    required this.learnset,
    required this.evolution,
    required this.media,
  });

  final String learnset;
  final String evolution;
  final String media;
}

/// Projection minimale d'une espece pour une future liste Pokédex.
///
/// Cette entree reste volontairement plus petite que `PokemonSpeciesFile` :
/// - pas de stats ;
/// - pas d'abilities ;
/// - pas de learnset charge ;
/// - pas de media detaille charge.
///
/// Le lot 11 ne cherche pas a remplacer les models de lecture existants.
/// Il pose seulement une projection liste, rapide a calculer, stable et
/// suffisamment explicite pour un futur outil no-code.
class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.genIntroduced,
    required this.types,
    required this.isEnabledInProject,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final int genIntroduced;
  final List<String> types;

  /// Le lot 38 a besoin d'un filtre activée/désactivée directement sur la
  /// projection légère de liste.
  ///
  /// On expose donc uniquement le booléen déjà présent dans
  /// `PokemonSpeciesClassification.isEnabledInProject`, sans embarquer toute la
  /// classification détaillée dans l'index.
  final bool isEnabledInProject;
  final PokemonDatabaseIndexRefs refs;

  /// Construit l'entree specifique au lot 11 a partir d'une source de vérité
  /// déjà existante.
  ///
  /// Le mini-fix 11b retire volontairement le mini parsing parallèle du JSON :
  /// - `PokemonSpeciesIndexEntry` fournit déjà `id`, `nationalDex` et
  ///   `primaryName` ;
  /// - `PokemonSpeciesFile` reste la source de vérité pour les refs.
  ///
  /// Cette factory ne décide donc plus comment parser le JSON ni comment
  /// calculer le nom principal. Elle assemble seulement une projection plus
  /// petite destinée à une future liste locale.
  ///
  /// Le lot 13 ajoute `types` à cette projection légère.
  /// Pourquoi ici :
  /// - la liste Pokédex simple doit montrer les types ;
  /// - `PokemonSpeciesIndexEntry` les possède déjà sans nouvelle lecture disque ;
  /// - les propager ici évite d’inventer un second pipeline UI parallèle.
  ///
  /// Le lot 15 ajoute `genIntroduced` à la même projection légère.
  /// Pourquoi ce petit élargissement reste légitime :
  /// - le filtre génération a été demandé sur la liste existante ;
  /// - `PokemonSpeciesFile` expose déjà `genIntroduced` comme donnée locale
  ///   lecture seule ;
  /// - on continue à réutiliser le pipeline d’index courant au lieu de créer une
  ///   nouvelle façade ou de relire autre chose depuis la UI.
  ///
  /// Le lot 38 ajoute `isEnabledInProject` à la même projection légère.
  /// Pourquoi ce booléen précis est légitime ici :
  /// - la liste Pokédex doit filtrer "Toutes / Activées / Désactivées" ;
  /// - la source de vérité existe déjà dans `PokemonSpeciesFile.classification`;
  /// - on évite ainsi de charger la fiche détail juste pour un filtre liste ;
  /// - on n'introduit toujours aucun second état parallèle pour le statut.
  ///
  /// Le scope reste strict :
  /// - on ne charge toujours ni learnsets, ni évolutions, ni médias ;
  /// - on n’ajoute aucun détail riche de fiche Pokémon ;
  /// - on complète seulement la projection minimale utile à la liste locale et
  ///   à ses filtres simples.
  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      genIntroduced: species.genIntroduced,
      types: List<String>.from(speciesIndexEntry.types),
      isEnabledInProject: species.classification.isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: species.refs.learnset.trim(),
        evolution: species.refs.evolution.trim(),
        media: species.refs.media.trim(),
      ),
    );
  }
}

```
### 13.3 `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

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
export 'update_pokedex_species_metadata_use_case.dart';
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';

```
### 13.4 `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';
import 'pokedex_workspace_loader.dart';
import 'pokedex_workspace_views.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';

/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.metadataSaver,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexSpeciesMetadataSaver? metadataSaver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      metadataSaver: resolvedMetadataSaver,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.metadataSaver,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexSpeciesMetadataSaver metadataSaver;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader ||
        oldWidget.detailLoader != widget.detailLoader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = null;
      _detailFuture = null;
      _selectedDetailTabId = _overviewTabId;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        if (entries.isEmpty) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-empty-state'),
            title: 'Pokédex',
            message:
                'Aucune espèce importée pour le moment. Les prochains imports ou seeds rempliront cette liste.',
          );
        }

        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);
        final workspace = ProjectFileSystem(projectRootPath);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        final selectedEntry = _resolveSelectedEntry(filteredEntries);

        // Décision UX explicite du mini-fix :
        // si la sélection courante n'est plus visible dans la liste filtrée,
        // on vide la fiche détail au lieu de garder un élément "fantôme".
        // Le reset d'état est planifié hors build pour rester propre côté
        // Flutter, mais le rendu revient tout de suite à l'état vide car
        // `selectedEntry` est déjà résolu sur la liste visible.
        _clearSelectionIfInvisible(filteredEntries);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: PokedexWorkspaceSpeciesList(
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                emptyResultsChild: filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                        selectedStatus:
                            _selectedStatus == _allStatusesFilterValue
                                ? null
                                : _selectedStatus,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 480,
              child: PokedexWorkspaceDetailPane(
                selectedEntry: selectedEntry,
                selectedTabId: _selectedDetailTabId,
                onTabChanged: _updateSelectedDetailTab,
                detailFuture: _detailFuture,
                onSaveMetadata: _saveMetadata,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedStatus(String value) {
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _selectEntry({
    required ProjectFileSystem workspace,
    required PokemonDatabaseIndexEntry entry,
  }) {
    if (_selectedSpeciesId == entry.id && _detailFuture != null) {
      return;
    }
    setState(() {
      _selectedSpeciesId = entry.id;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, entry.id);
    });
  }

  void _clearSelectionIfInvisible(
    List<PokemonDatabaseIndexEntry> visibleEntries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }

    final stillVisible = visibleEntries.any((entry) => entry.id == selectedId);
    if (stillVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedSpeciesId != selectedId) return;
      setState(() {
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
    });
  }

  Future<void> _saveMetadata(
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save Pokemon species metadata without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await widget.metadataSaver(workspace, request);
    if (!mounted) {
      return;
    }

    // Après une sauvegarde locale, on relit la même source de vérité que le
    // reste du workspace :
    // - l'index léger pour la liste et les filtres ;
    // - la fiche détail complète pour l'espèce sélectionnée.
    //
    // On évite ainsi tout cache parallèle "enabled" ou "draft saved" qui
    // pourrait diverger du JSON réellement persisté.
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      if (_selectedSpeciesId == request.speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, request.speciesId);
      }
    });
  }

  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

    // Le lot 15 demande des filtres simples, pas un moteur de règles :
    // chaque critère local vaut soit "tout", soit une valeur unique exacte.
    final typeFilter = _selectedType.toLowerCase();
    final hasTypeFilter = _selectedType != _allTypesFilterValue;
    final hasGenerationFilter =
        _selectedGeneration != _allGenerationsFilterValue;
    final hasStatusFilter = _selectedStatus != _allStatusesFilterValue;

    return entries.where((entry) {
      final matchesSearch = _matchesSearchQuery(
        entry: entry,
        normalizedQuery: normalizedQuery,
        normalizedTextQuery: normalizedTextQuery,
        normalizedDexQuery: normalizedDexQuery,
        hasExactDexQuery: hasExactDexQuery,
      );

      final matchesType = !hasTypeFilter ||
          entry.types.any((type) => type.toLowerCase() == typeFilter);
      final matchesGeneration = !hasGenerationFilter ||
          entry.genIntroduced.toString() == _selectedGeneration;
      final matchesStatus = !hasStatusFilter ||
          (_selectedStatus == _enabledStatusFilterValue
              ? entry.isEnabledInProject
              : !entry.isEnabledInProject);

      return matchesSearch && matchesType && matchesGeneration && matchesStatus;
    }).toList(growable: false);
  }

  bool _matchesSearchQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedQuery,
    required String normalizedTextQuery,
    required String normalizedDexQuery,
    required bool hasExactDexQuery,
  }) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matchesName =
        entry.primaryName.toLowerCase().contains(normalizedTextQuery);
    final matchesId = entry.id.toLowerCase().contains(normalizedTextQuery);

    // Règle produit explicite du lot 14 :
    // - si la query ressemble à un numéro dex, on ne fait pas un `contains`
    //   numérique ;
    // - on compare exactement `1`, `0001`, `#1`, `#0001` au dex courant ;
    // - cela évite qu'une recherche "1" remonte 10, 11, 21, etc.
    final matchesDex = hasExactDexQuery &&
        _matchesExactDexQuery(
          entry: entry,
          normalizedDexQuery: normalizedDexQuery,
        );

    return matchesName || matchesId || matchesDex;
  }

  List<String> _buildAvailableTypes(List<PokemonDatabaseIndexEntry> entries) {
    final uniqueTypes = entries
        .expand((entry) => entry.types)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    return uniqueTypes;
  }

  List<String> _buildAvailableGenerations(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final uniqueGenerations = entries
        .map((entry) => entry.genIntroduced)
        .toSet()
        .toList(growable: false)
      ..sort();

    return uniqueGenerations
        .map((generation) => generation.toString())
        .toList(growable: false);
  }

  PokemonDatabaseIndexEntry? _resolveSelectedEntry(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeDexQuery(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('#')) {
      return trimmed;
    }
    return trimmed.substring(1).trim();
  }

  bool _matchesExactDexQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedDexQuery,
  }) {
    final rawDex = entry.nationalDex.toString();
    final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
    return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
  }
}

```
### 13.5 `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart'
    show MacosIcon, MacosPopupButton, MacosPopupMenuItem, ProgressCircle;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Vue de chargement minimale du lot 13.
///
/// On garde un état très simple et honnête :
/// - pas d'overlay complexe ;
/// - pas de skeleton list ;
/// - pas de faux comportement "riche" qui préparerait en douce les lots
///   suivants.
class PokedexWorkspaceLoadingState extends StatelessWidget {
  const PokedexWorkspaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      child: const PokedexWorkspaceStateFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ProgressCircle(),
            ),
            SizedBox(height: 14),
            Text(
              'Chargement de la liste Pokédex…',
              key: Key('pokedex-loading-label'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur minimale du lot 13.
///
/// L'objectif n'est pas d'ajouter une UX de récupération riche ; on rend
/// simplement l'erreur lisible, sans masquer qu'un chargement a échoué.
class PokedexWorkspaceErrorState extends StatelessWidget {
  const PokedexWorkspaceErrorState({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final message = switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error?.toString() ?? 'Erreur inconnue',
    };

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-error-state'),
      title: 'Pokédex',
      accent: EditorChrome.inspectorJoyCoral,
      titleStyle: TextStyle(
        color: label,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      message: 'Impossible de charger la liste locale des espèces.\n$message',
      messageStyle: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

/// Etat dédié des lots 14/15 quand les critères locaux ne matchent aucune entrée.
///
/// Il doit rester distinct de l'état "aucune espèce importée" :
/// - ici, la base locale contient des espèces ;
/// - ce sont uniquement les critères courants (recherche et/ou filtres) qui
///   n'ont trouvé aucun match.
/// On garde donc un message sobre, non anxiogène, et différent d'une erreur.
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
    this.selectedType,
    this.selectedGeneration,
    this.selectedStatus,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;
  final String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final normalizedStatus = switch (selectedStatus) {
      _PokedexFilterDropdown.enabledOnlyValue => 'Activées',
      _PokedexFilterDropdown.disabledOnlyValue => 'Désactivées',
      _ => selectedStatus,
    };
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
      if (normalizedStatus != null) 'Statut : $normalizedStatus.',
    ];
    final suffix = activeCriteriaLines.isEmpty
        ? ''
        : '\n${activeCriteriaLines.join('\n')}';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat avec les critères actuels.$suffix',
    );
  }
}

/// Vue succès du lot 13.
///
/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
/// vraie sélection locale de ligne pour ouvrir la fiche détail.
class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.entries,
    required this.selectedSpeciesId,
    required this.onEntrySelected,
    required this.query,
    required this.onQueryChanged,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.emptyResultsChild,
  });

  final List<PokemonDatabaseIndexEntry> entries;
  final String? selectedSpeciesId;
  final ValueChanged<PokemonDatabaseIndexEntry> onEntrySelected;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final Widget? emptyResultsChild;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pokédex',
                style: TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Liste locale des espèces importées dans le projet. La phase 8A ajoute un statut activée/désactivée et une édition locale de métadonnées simples, sans toucher learnset, évolutions ou médias.',
                style: TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              // Lot 14 : recherche texte simple, locale et instantanée.
              //
              // Intention volontairement stricte :
              // - aucun aller-retour disque ;
              // - aucun appel service/repository par frappe ;
              // - aucun faux panneau de filtres ;
              // - aucun outillage avancé des lots suivants.
              _PokedexSearchField(
                query: query,
                onChanged: onQueryChanged,
              ),
              const SizedBox(height: 12),
              // Lot 15 : filtres simples, purement locaux, sur la liste déjà
              // chargée en mémoire.
              //
              // On reste volontairement minimal :
              // - type ;
              // - génération ;
              // - statut activée/désactivée, désormais alimenté par la vraie
              //   donnée persistée `classification.isEnabledInProject`.
              _PokedexSimpleFiltersBar(
                availableTypes: availableTypes,
                selectedType: selectedType,
                onTypeChanged: onTypeChanged,
                availableGenerations: availableGenerations,
                selectedGeneration: selectedGeneration,
                onGenerationChanged: onGenerationChanged,
                selectedStatus: selectedStatus,
                onStatusChanged: onStatusChanged,
              ),
            ],
          ),
        ),
        const _PokedexListHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: emptyResultsChild != null
              ? SingleChildScrollView(child: emptyResultsChild)
              : ListView.separated(
                  key: const Key('pokedex-species-list'),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _PokedexListRow(
                      entry: entry,
                      isSelected: selectedSpeciesId == entry.id,
                      onPressed: () => onEntrySelected(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PokedexSimpleFiltersBar extends StatelessWidget {
  const _PokedexSimpleFiltersBar({
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PokedexFilterDropdown(
          label: 'Type',
          popupKey: const Key('pokedex-type-filter'),
          value: selectedType,
          onChanged: onTypeChanged,
          items: <String>[
            _PokedexFilterDropdown.allTypesValue,
            ...availableTypes,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allTypesValue) {
              return 'Tous types';
            }
            return value;
          },
        ),
        _PokedexFilterDropdown(
          label: 'Génération',
          popupKey: const Key('pokedex-generation-filter'),
          value: selectedGeneration,
          onChanged: onGenerationChanged,
          items: <String>[
            _PokedexFilterDropdown.allGenerationsValue,
            ...availableGenerations,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allGenerationsValue) {
              return 'Toutes gén.';
            }
            return 'Génération $value';
          },
        ),
        _PokedexFilterDropdown(
          label: 'Statut',
          popupKey: const Key('pokedex-status-filter'),
          value: selectedStatus,
          onChanged: onStatusChanged,
          items: const <String>[
            _PokedexFilterDropdown.allStatusesValue,
            _PokedexFilterDropdown.enabledOnlyValue,
            _PokedexFilterDropdown.disabledOnlyValue,
          ],
          itemLabelBuilder: (value) {
            switch (value) {
              case _PokedexFilterDropdown.allStatusesValue:
                return 'Toutes';
              case _PokedexFilterDropdown.enabledOnlyValue:
                return 'Activées';
              case _PokedexFilterDropdown.disabledOnlyValue:
                return 'Désactivées';
            }
            return value;
          },
        ),
      ],
    );
  }
}

class _PokedexSearchField extends StatefulWidget {
  const _PokedexSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_PokedexSearchField> createState() => _PokedexSearchFieldState();
}

class _PokedexSearchFieldState extends State<_PokedexSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _PokedexSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('pokedex-search-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Rechercher par nom, id ou numéro dex',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexFilterDropdown extends StatelessWidget {
  const _PokedexFilterDropdown({
    required this.label,
    required this.popupKey,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.itemLabelBuilder,
  });

  static const String allTypesValue = '__all_types__';
  static const String allGenerationsValue = '__all_generations__';
  static const String allStatusesValue = '__all_statuses__';
  static const String enabledOnlyValue = '__enabled_only__';
  static const String disabledOnlyValue = '__disabled_only__';

  final String label;
  final Key popupKey;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String Function(String value) itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return SizedBox(
      // `MacosPopupButton` réserve de la place pour le libellé et l'icône
      // interne. On donne donc une largeur volontairement confortable pour
      // éviter les overflows de layout, notamment avec les libellés français
      // "Toutes les générations" / "Tous les types".
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                child: MacosPopupButton<String>(
                  key: popupKey,
                  value: value,
                  onChanged: (nextValue) {
                    if (nextValue != null) {
                      onChanged(nextValue);
                    }
                  },
                  items: [
                    for (final item in items)
                      MacosPopupMenuItem<String>(
                        value: item,
                        child: Text(itemLabelBuilder(item)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexListHeader extends StatelessWidget {
  const _PokedexListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              'Numéro',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Nom',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Types',
              style: _headerStyle(subtle),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
    );
  }
}

class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({
    required this.entry,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  '#${entry.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  entry.primaryName,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.id,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.types
                      .map((type) => _PokedexTypeChip(label: type))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexTypeChip extends StatelessWidget {
  const _PokedexTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentJade,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour afficher son overview, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex locale…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
          onSaveMetadata: onSaveMetadata,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.primaryName,
              style: TextStyle(
                color: label,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.types
                  .map((type) => _PokedexTypeChip(label: type))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Overview'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
                onSaveMetadata: onSaveMetadata,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(detail: detail),
      'learnset' => _PokedexLearnsetTab(detail: detail),
      'evolutions' => _PokedexEvolutionTab(detail: detail),
      'media' => _PokedexMediaTab(detail: detail),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}

class _PokedexOverviewTab extends StatelessWidget {
  const _PokedexOverviewTab({
    required this.entry,
    required this.detail,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;

    return SingleChildScrollView(
      key: const Key('pokedex-overview-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Identité',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Nom principal',
                  value: entry.primaryName,
                ),
                _PokedexPropertyLine(label: 'ID', value: species.id),
                _PokedexPropertyLine(
                  label: 'Numéro national',
                  value: species.nationalDex.toString(),
                ),
                _PokedexPropertyLine(
                  label: 'Nom espèce',
                  value: _localizedValue(species.speciesName),
                ),
                _PokedexPropertyLine(
                  label: 'Génération',
                  value: species.genIntroduced.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexEditableMetadataSection(
            species: species,
            onSave: onSaveMetadata,
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Stats',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'HP', value: species.baseStats.hp),
                _StatChip(label: 'ATK', value: species.baseStats.atk),
                _StatChip(label: 'DEF', value: species.baseStats.def),
                _StatChip(label: 'SPA', value: species.baseStats.spa),
                _StatChip(label: 'SPD', value: species.baseStats.spd),
                _StatChip(label: 'SPE', value: species.baseStats.spe),
                _StatChip(label: 'BST', value: species.baseStats.bst),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Talents',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Talent principal',
                  value: species.abilities.primary,
                ),
                _PokedexPropertyLine(
                  label: 'Talent secondaire',
                  value: species.abilities.secondary ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'Talent caché',
                  value: species.abilities.hidden ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Références locales',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Learnset',
                  value: species.refs.learnset,
                ),
                _PokedexPropertyLine(
                  label: 'Évolution',
                  value: species.refs.evolution,
                ),
                _PokedexPropertyLine(
                  label: 'Média',
                  value: species.refs.media,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexEditableMetadataSection extends StatefulWidget {
  const _PokedexEditableMetadataSection({
    required this.species,
    required this.onSave,
  });

  final PokemonSpeciesFile species;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSave;

  @override
  State<_PokedexEditableMetadataSection> createState() =>
      _PokedexEditableMetadataSectionState();
}

class _PokedexEditableMetadataSectionState
    extends State<_PokedexEditableMetadataSection> {
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  late TextEditingController _flavorTextController;
  late List<String> _orderedLocales;
  late bool _isEnabledInProject;
  late bool _starterEligible;
  late bool _giftOnly;
  late bool _tradeOnly;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _flavorTextController = TextEditingController();
    _replaceDraftFromSpecies(widget.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexEditableMetadataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      // Dès qu'une nouvelle espèce est relue depuis le workspace, on considère
      // qu'elle devient la nouvelle vérité locale :
      // - après sélection d'une autre ligne ;
      // - après sauvegarde réussie et rechargement ;
      // - après changement de filtres qui force une nouvelle fiche.
      //
      // On jette donc proprement tout draft local restant.
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _flavorTextController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();

    _orderedLocales = _orderedLocaleKeys(species.names);
    for (final locale in _orderedLocales) {
      _nameControllers[locale] = TextEditingController(
        text: species.names[locale] ?? '',
      );
    }

    _flavorTextController.value = TextEditingValue(
      text: species.dexContent.flavorText ?? '',
      selection: TextSelection.collapsed(
        offset: (species.dexContent.flavorText ?? '').length,
      ),
    );
    _isEnabledInProject = species.classification.isEnabledInProject;
    _starterEligible = species.gameplayFlags.starterEligible;
    _giftOnly = species.gameplayFlags.giftOnly;
    _tradeOnly = species.gameplayFlags.tradeOnly;
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesMetadataRequest(
          speciesId: widget.species.id,
          isEnabledInProject: _isEnabledInProject,
          names: <String, String>{
            for (final locale in _orderedLocales)
              locale: _nameControllers[locale]?.text ?? '',
          },
          flavorText: _flavorTextController.text,
          starterEligible: _starterEligible,
          giftOnly: _giftOnly,
          tradeOnly: _tradeOnly,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };

      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;

    return _PokedexDetailSectionCard(
      title: 'Métadonnées locales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-enabled-switch-row'),
              label: 'Activée dans le projet',
              description:
                  'Le filtre liste et le statut local utilisent ce booléen persistant.',
              value: _isEnabledInProject,
              switchKey: const Key('pokedex-enabled-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isEnabledInProject = value),
            ),
            const SizedBox(height: 12),
            for (final locale in _orderedLocales) ...[
              _PokedexEditorTextField(
                label: 'Nom (${locale.toUpperCase()})',
                fieldKey: Key('pokedex-name-field-$locale'),
                controller: _nameControllers[locale]!,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 10),
            ],
            _PokedexEditorTextField(
              label: 'Texte Pokédex',
              fieldKey: const Key('pokedex-flavor-text-field'),
              controller: _flavorTextController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              placeholder: 'Texte local affiché dans la fiche Pokédex',
            ),
            const SizedBox(height: 12),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-starter-eligible-switch-row'),
              label: 'Starter éligible',
              value: _starterEligible,
              switchKey: const Key('pokedex-starter-eligible-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _starterEligible = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-gift-only-switch-row'),
              label: 'Obtenu par cadeau',
              value: _giftOnly,
              switchKey: const Key('pokedex-gift-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _giftOnly = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-trade-only-switch-row'),
              label: 'Échange uniquement',
              value: _tradeOnly,
              switchKey: const Key('pokedex-trade-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _tradeOnly = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CupertinoButton.filled(
                  key: const Key('pokedex-save-metadata-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: _isSaving ? null : _saveDraft,
                  child: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  key: const Key('pokedex-cancel-metadata-button'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ],
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveErrorMessage!,
                key: const Key('pokedex-metadata-save-error'),
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            _PokedexPropertyLine(
              label: 'Statut projet',
              value: species.classification.isEnabledInProject
                  ? 'Activée'
                  : 'Désactivée',
            ),
            for (final locale in _orderedLocaleKeys(species.names))
              _PokedexPropertyLine(
                label: 'Nom (${locale.toUpperCase()})',
                value: (species.names[locale]?.trim().isNotEmpty ?? false)
                    ? species.names[locale]!.trim()
                    : 'Valeur vide',
              ),
            _PokedexPropertyLine(
              label: 'Texte Pokédex',
              value: species.dexContent.flavorText?.trim().isNotEmpty == true
                  ? species.dexContent.flavorText!.trim()
                  : 'Aucun texte local',
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: species.gameplayFlags.starterEligible
                      ? 'Starter éligible'
                      : 'Starter non éligible',
                ),
                _FlagChip(
                  label: species.gameplayFlags.giftOnly
                      ? 'Obtenu par cadeau'
                      : 'Pas cadeau uniquement',
                ),
                _FlagChip(
                  label: species.gameplayFlags.tradeOnly
                      ? 'Échange uniquement'
                      : 'Pas échange uniquement',
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const Key('pokedex-edit-metadata-button'),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _replaceDraftFromSpecies(widget.species);
                  _isEditing = true;
                  _saveErrorMessage = null;
                });
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexBooleanEditorRow extends StatelessWidget {
  const _PokedexBooleanEditorRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool>? onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PokedexEditorTextField extends StatelessWidget {
  const _PokedexEditorTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.maxLines = 1,
    this.placeholder,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexFormsTab extends StatelessWidget {
  const _PokedexFormsTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme courante',
                  value: forms.formName == null || forms.formName!.isEmpty
                      ? currentFormId
                      : '${forms.formName} ($currentFormId)',
                ),
                _PokedexPropertyLine(
                  label: 'Forme de base',
                  value: baseFormId,
                ),
                _PokedexPropertyLine(
                  label: 'Est la forme de base',
                  value: forms.isBaseForm ? 'Oui' : 'Non',
                ),
                _PokedexPropertyLine(
                  label: 'Autres formes',
                  value: forms.otherForms.isEmpty
                      ? 'Aucune autre forme locale'
                      : forms.otherForms.join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Classification',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: classification.isEnabledInProject
                      ? 'Activée dans le projet'
                      : 'Désactivée dans le projet',
                ),
                _FlagChip(
                  label: classification.isObtainable
                      ? 'Obtenable'
                      : 'Non obtenable',
                ),
                if (classification.isLegendary)
                  const _FlagChip(label: 'Légendaire'),
                if (classification.isMythical)
                  const _FlagChip(label: 'Mythique'),
                if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                if (!classification.isLegendary &&
                    !classification.isMythical &&
                    !classification.isBaby)
                  const _FlagChip(label: 'Aucun flag rare'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexLearnsetTab extends StatelessWidget {
  const _PokedexLearnsetTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final learnset = detail.learnset;
    if (learnset == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-learnset-missing'),
        title: 'Learnset',
        message: 'Aucun learnset local trouvé pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset.transfer),
        ],
      ),
    );
  }
}

class _PokedexEvolutionTab extends StatelessWidget {
  const _PokedexEvolutionTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final evolution = detail.evolution;
    if (evolution == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-evolutions-missing'),
        title: 'Évolutions',
        message: 'Aucune donnée d’évolution locale trouvée pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Pré-évolution',
            child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                ? evolution.preEvolution!
                : 'Aucune'),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Évolutions suivantes',
            child: evolution.evolutions.isEmpty
                ? const Text('Aucune évolution déclarée.')
                : Column(
                    children: evolution.evolutions
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.targetSpeciesId,
                            value: _describeEvolution(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PokedexMediaTab extends StatelessWidget {
  const _PokedexMediaTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final media = detail.media;
    if (media == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-media-missing'),
        title: 'Médias',
        message: 'Aucune donnée média locale trouvée pour cette espèce.',
      );
    }

    final defaultVariant = media.variants[media.defaultFormId];

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Variant par défaut',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme par défaut',
                  value: media.defaultFormId,
                ),
                _PokedexPropertyLine(
                  label: 'front',
                  value: defaultVariant?.frontStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back',
                  value: defaultVariant?.backStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'front shiny',
                  value: defaultVariant?.frontShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back shiny',
                  value: defaultVariant?.backShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'icon',
                  value: defaultVariant?.icon ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'party',
                  value: defaultVariant?.party ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'portrait',
                  value: defaultVariant?.portrait ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'cry',
                  value: defaultVariant?.cry ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Animations',
            child: defaultVariant == null || defaultVariant.animations.isEmpty
                ? const Text('Aucune animation locale déclarée.')
                : Column(
                    children: defaultVariant.animations.entries
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.key,
                            value:
                                '${entry.value.animationId} • ${entry.value.sheet}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          const _PokedexDetailSectionCard(
            title: 'Contrat média',
            child: Text(
              'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnsetMoveSection extends StatelessWidget {
  const _LearnsetMoveSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<PokemonLearnsetMoveEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('Aucune entrée $title.')
          : Column(
              children: entries
                  .map(
                    (entry) => _PokedexPropertyLine(
                      label: entry.moveId,
                      value: entry.versionGroup,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PokedexMissingSection extends StatelessWidget {
  const _PokedexMissingSection({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Text(message),
    );
  }
}

class _PokedexDetailSectionCard extends StatelessWidget {
  const _PokedexDetailSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(
      EditorChrome.islandFillElevated(context),
      CupertinoColors.black,
      0.06,
    )!;
    final border = EditorChrome.accentWarm.withValues(alpha: 0.24);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexPropertyLine extends StatelessWidget {
  const _PokedexPropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final fill = EditorChrome.islandFillElevated(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentWarm,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

List<String> _orderedLocaleKeys(Map<String, String> values) {
  final locales = values.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false);

  // On garde un ordre stable et lisible dans la UI :
  // - `fr` puis `en` si présents, car ce sont les locales déjà privilégiées
  //   ailleurs dans le Pokédex ;
  // - puis le reste en ordre alphabétique pour éviter tout mouvement arbitraire
  //   des champs entre deux rebuilds.
  locales.sort((left, right) {
    final leftPriority = switch (left) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final rightPriority = switch (right) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final priorityCompare = leftPriority.compareTo(rightPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return left.compareTo(right);
  });

  return locales;
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
}

/// Carte de base réutilisée pour "pas de projet", "vide" et "erreur".
///
/// On mutualise uniquement la présentation visuelle commune, sans introduire un
/// système d'état générique plus large que le besoin du lot 13.
class PokedexWorkspaceStateCard extends StatelessWidget {
  const PokedexWorkspaceStateCard({
    super.key,
    required this.title,
    required this.message,
    this.accent = EditorChrome.inspectorJoyAmber,
    this.titleStyle,
    this.messageStyle,
  });

  final String title;
  final String message;
  final Color accent;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return PokedexWorkspaceStateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accent, 0.72)!,
                  Color.lerp(accent, const Color(0xFF1A1408), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.book_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: messageStyle ??
                TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceStateFrame extends StatelessWidget {
  const PokedexWorkspaceStateFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.38),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}

```
### 13.6 `packages/map_editor/test/pokedex_workspace_ui_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PokemonDatabaseIndexEntry buildEntry({
    required String id,
    required int nationalDex,
    required String primaryName,
    required List<String> types,
    required int genIntroduced,
    bool isEnabledInProject = true,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      isEnabledInProject: isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
    );
  }

  PokedexSpeciesDetail buildDetail({
    required String id,
    int nationalDex = 1,
    int genIntroduced = 1,
    List<String> types = const <String>['grass', 'poison'],
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
    bool isEnabledInProject = true,
    Map<String, String> names = const <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    String? flavorText =
        'Une étrange graine a été plantée sur son dos à la naissance.',
    bool starterEligible = true,
    bool giftOnly = false,
    bool tradeOnly = false,
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: nationalDex,
        names: names,
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: genIntroduced,
        typing: PokemonSpeciesTyping(
          types: types,
        ),
        baseStats: const PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: primaryAbility,
          secondary: secondaryAbility,
          hidden: hiddenAbility,
        ),
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
        forms: PokemonSpeciesForms(
          baseFormId: id,
          isBaseForm: true,
          formId: 'base',
          otherForms: otherForms,
        ),
        classification: PokemonSpeciesClassification(
          isEnabledInProject: isEnabledInProject,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: flavorText,
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: starterEligible,
          giftOnly: giftOnly,
          tradeOnly: tradeOnly,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: const PokemonLearnsetFile(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle', 'growl'],
        relearnMoves: <String>['vine_whip'],
        levelUp: <PokemonLearnsetLevelUpEntry>[
          PokemonLearnsetLevelUpEntry(
            moveId: 'vine_whip',
            level: 7,
            source: 'level_up',
            versionGroup: 'scarlet-violet',
          ),
        ],
        tm: <PokemonLearnsetMoveEntry>[
          PokemonLearnsetMoveEntry(
            moveId: 'protect',
            versionGroup: 'scarlet-violet',
          ),
        ],
      ),
      evolution: const PokemonEvolutionFile(
        speciesId: 'bulbasaur',
        preEvolution: null,
        evolutions: <PokemonEvolutionEntry>[
          PokemonEvolutionEntry(
            targetSpeciesId: 'ivysaur',
            method: 'level_up',
            minLevel: 16,
            conditionText: <String, String>{
              'fr': 'Évolue au niveau 16',
              'en': 'Evolves at level 16',
            },
          ),
        ],
      ),
      media: const PokemonMediaFile(
        speciesId: 'bulbasaur',
        defaultFormId: 'base',
        variants: <String, PokemonMediaVariant>{
          'base': PokemonMediaVariant(
            frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
            backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
            frontShinyStatic:
                'assets/pokemon/sprites/bulbasaur/front_shiny.png',
            backShinyStatic: 'assets/pokemon/sprites/bulbasaur/back_shiny.png',
            icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
            party: 'assets/pokemon/sprites/bulbasaur/party.png',
            portrait: 'assets/pokemon/sprites/bulbasaur/portrait.png',
            cry: 'assets/pokemon/cries/bulbasaur.ogg',
            animations: <String, PokemonMediaAnimationRef>{
              'battleFront': PokemonMediaAnimationRef(
                sheet:
                    'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
                animationId: 'battle_front',
              ),
            },
          ),
        },
      ),
    );
  }

  Future<void> selectPopupFilter(
    WidgetTester tester, {
    required Key popupKey,
    required String itemLabel,
  }) async {
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  PokemonDatabaseIndexEntry buildEntryFromSpecies(PokemonSpeciesFile species) {
    final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
      species,
      relativePath:
          'data/pokemon/species/${species.nationalDex.toString().padLeft(4, '0')}-${species.slug}.json',
    );
    return PokemonDatabaseIndexEntry.fromSpeciesEntry(
      speciesIndexEntry: speciesIndexEntry,
      species: species,
    );
  }

  PokemonSpeciesFile applyMetadataUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) {
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: Map<String, String>.from(request.names),
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: species.classification.isLegendary,
        isMythical: species.classification.isMythical,
        isBaby: species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: species.dexContent.heightM,
        weightKg: species.dexContent.weightKg,
        color: species.dexContent.color,
        flavorText: request.flavorText?.trim().isEmpty ?? true
            ? null
            : request.flavorText?.trim(),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: species.sourceMeta,
    );
  }

  _FakePokedexWorkspaceStore buildStore({
    required List<PokedexSpeciesDetail> details,
  }) {
    return _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        for (final detail in details) detail.species.id: detail,
      },
      entryBuilder: buildEntryFromSpecies,
      updater: applyMetadataUpdate,
    );
  }

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ce test verrouille seulement la présence de l'entrée UI dans l'éditeur.
    // Il reste volontairement purement en mémoire pour éviter tout bruit
    // filesystem inutile dans un contrôle aussi simple.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.textContaining('Species list only'), findsOneWidget);
  });

  testWidgets(
      'uses the provider-backed loader by default when no explicit loader is injected',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: const PokedexWorkspace(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('treecko'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
  });

  testWidgets(
      'prefers the explicitly injected loader over the provider-backed default',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Torchic'), findsOneWidget);
    expect(find.text('torchic'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);
    expect(find.text('treecko'), findsNothing);
  });

  testWidgets(
      'renders the simple species list with only number name id and types',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);

    // Le mini-fix ne doit surtout pas transformer l'écran en lot 14 déguisé.
    expect(find.textContaining('Search'), findsNothing);
    expect(find.textContaining('Filter'), findsNothing);
    expect(find.textContaining('Details'), findsNothing);
    expect(find.textContaining('Import'), findsNothing);
    expect(find.textContaining('Generation'), findsNothing);
    expect(find.textContaining('Edit'), findsNothing);
    expect(find.textContaining('Delete'), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

  testWidgets('selects a species row and shows the overview detail pane',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.text('Nom principal'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Talent principal'), findsOneWidget);
    expect(find.text('overgrow'), findsOneWidget);
    expect(find.text('Références locales'), findsOneWidget);
    expect(find.text('bulbasaur'), findsWidgets);
  });

  testWidgets('switches to forms learnset evolutions and media tabs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(
          id: speciesId,
          otherForms: const <String>['mega'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-forms-tab')), findsOneWidget);
    expect(find.text('Forme courante'), findsOneWidget);
    expect(find.textContaining('mega'), findsOneWidget);
    expect(find.text('Classification'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);
    expect(find.text('vine_whip • niveau 7'), findsOneWidget);
    expect(find.text('scarlet-violet • source level_up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-evolutions-tab')), findsOneWidget);
    expect(find.text('Pré-évolution'), findsOneWidget);
    expect(find.text('Évolue au niveau 16'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);
    expect(
      find.text('assets/pokemon/sprites/bulbasaur/front.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battle_front'), findsWidgets);
    expect(find.textContaining('battle_front_sheet.png'), findsWidgets);
  });

  testWidgets(
      'clears the selection and resets the detail pane when search hides it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-media-tab')), findsNothing);
  });

  testWidgets(
      'clears the selection and resets the detail pane when filters hide it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsNothing);
  });

  testWidgets(
      'shows the search field and simple filters in the Pokédex workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(
      find.text('Rechercher par nom, id ou numéro dex'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-status-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by species primary name', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by species id', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'bulb',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('filters instantly by dex number with exact matching only',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 10,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '#0001',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('empty query restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
  });

  testWidgets('shows a dedicated no results state when search matches nothing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(
      find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recherche actuelle : "zzz"'), findsOneWidget);
    // Le champ reste visible pour corriger immédiatement la query.
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
  });

  testWidgets('filters instantly by type', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'charmander',
            nationalDex: 4,
            primaryName: 'Charmander',
            types: <String>['fire'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'fire',
    );

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by generation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('combines text search with simple filters', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'bellsprout',
            nationalDex: 69,
            primaryName: 'Bellsprout',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'tree',
    );
    await tester.pump();
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Bellsprout'), findsNothing);
  });

  testWidgets('combines simple filters together', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Torchic'), findsNothing);
  });

  testWidgets('clearing all filters restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets('shows no results when simple filters eliminate the list',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'poison',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(find.textContaining('Aucun résultat avec les critères actuels.'),
        findsOneWidget);
    expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
    expect(find.textContaining('Type : poison.'), findsOneWidget);
    expect(find.textContaining('Génération : 1.'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by enabled status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
            isEnabledInProject: true,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
            isEnabledInProject: false,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Désactivées',
    );

    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets(
      'enters edit mode saves simple metadata and keeps generation filtering stable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
          starterEligible: true,
        ),
        buildDetail(
          id: 'treecko',
          nationalDex: 252,
          genIntroduced: 3,
          types: const <String>['grass'],
          names: const <String, String>{
            'fr': 'Arcko',
            'en': 'Treecko',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Projet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      'Bulbasaur Project',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Texte édité depuis la fiche locale.',
    );
    await tester.tap(find.byKey(const Key('pokedex-gift-only-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 1);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre Projet');
    expect(store.speciesById('bulbasaur').names['en'], 'Bulbasaur Project');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Texte édité depuis la fiche locale.',
    );
    expect(store.speciesById('bulbasaur').gameplayFlags.giftOnly, isTrue);

    expect(find.text('Bulbasaur Project'), findsWidgets);
    expect(find.text('Treecko'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsNothing);
    expect(find.text('Désactivée'), findsWidgets);
  });

  testWidgets('cancel discards metadata changes without writing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Temporaire',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Changement non enregistré.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 0);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isTrue);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Une étrange graine a été plantée sur son dos à la naissance.',
    );
    expect(find.text('Bulbizarre Temporaire'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
  });

  testWidgets(
      'saving a disable under the enabled filter clears the current selection cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsNothing);
  });

  testWidgets('shows a loading state before the species list resolves',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<List<PokemonDatabaseIndexEntry>>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_loading_test',
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-loading-label')), findsOneWidget);

    // On prouve l'existence de l'état loading, puis on résout explicitement le
    // future avant teardown pour éviter de laisser un timer autoDispose Riverpod
    // en attente à la fin du test.
    completer.complete(const <PokemonDatabaseIndexEntry>[]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows an empty state when no species files are present',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    expect(find.textContaining('Aucune espèce importée'), findsOneWidget);
  });

  testWidgets('shows an error state when species loading fails',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => Future<List<PokemonDatabaseIndexEntry>>.error(
          const EditorPersistenceException(
            'Invalid JSON in Pokemon species file',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-error-state')), findsOneWidget);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
  });

  test(
    'returns an empty list when the configured species directory does not exist yet',
    () async {
      final tempProjectRoot =
          await Directory.systemTemp.createTemp('pokedex_loader_test_');
      try {
        final workspace = ProjectFileSystem(tempProjectRoot.path);
        final createProjectUseCase = CreateProjectUseCase(
          FileProjectRepository(),
          const FileProjectWorkspaceFactory(),
        );

        await createProjectUseCase.execute(
          'Pokedex Loader Project',
          tempProjectRoot.path,
        );

        final loader = createPokedexEntryLoader(
          projectRepository: FileProjectRepository(),
          databaseIndex: PokemonDatabaseIndex(
            projectRepository: FileProjectRepository(),
            pokemonReadRepository: const FilePokemonReadRepository(),
          ),
        );

        // Ce test verrouille le vrai nettoyage du mini-fix :
        // l'absence du dossier `species/` doit produire une liste vide
        // explicitement, sans dépendre du texte d'une exception remontée.
        final entries = await loader(workspace);
        expect(entries, isEmpty);
      } finally {
        if (await tempProjectRoot.exists()) {
          await tempProjectRoot.delete(recursive: true);
        }
      }
    },
  );
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
    required this.entryBuilder,
    required this.updater,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;
  final PokemonDatabaseIndexEntry Function(PokemonSpeciesFile species)
      entryBuilder;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) updater;

  int saveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = _detailsById.values
        .map((detail) => entryBuilder(detail.species))
        .toList(growable: false)
      ..sort((left, right) {
        final dexCompare = left.nationalDex.compareTo(right.nationalDex);
        if (dexCompare != 0) {
          return dexCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> save(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    saveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = updater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  PokemonSpeciesFile speciesById(String speciesId) {
    return _detailsById[speciesId]!.species;
  }
}

```
### 13.7 `packages/map_editor/test/pokemon_database_index_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late FileProjectRepository projectRepository;
  late FilePokemonReadRepository pokemonReadRepository;
  late PokemonDatabaseIndex indexService;
  late CreateProjectUseCase createProjectUseCase;
  late SeedPokemonDemoDataUseCase seedUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_index_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    projectRepository = FileProjectRepository();
    pokemonReadRepository = const FilePokemonReadRepository();
    indexService = PokemonDatabaseIndex(
      projectRepository: projectRepository,
      pokemonReadRepository: pokemonReadRepository,
    );
    createProjectUseCase = CreateProjectUseCase(
      projectRepository,
      const FileProjectWorkspaceFactory(),
    );
    seedUseCase = const SeedPokemonDemoDataUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonSpeciesIndexEntry.fromJson', () {
    test('keeps the historical lightweight projection local to the model', () {
      // Ce test verrouille explicitement la retenue demandee pour le mini-fix
      // final du lot 11 :
      // - la projection legacy continue de lire du JSON brut ;
      // - elle ne depend pas du contrat complet de `PokemonSpeciesFile` ;
      // - le durcissement du lot 11 reste local au pipeline
      //   `PokemonDatabaseIndex`, pas a ce modele historique.
      final entry = PokemonSpeciesIndexEntry.fromJson(
        <String, dynamic>{
          'id': 'bulbasaur',
          'nationalDex': 1,
          'names': <String, String>{'en': 'Bulbasaur'},
          'typing': <String, dynamic>{
            'types': <String>['grass', 'poison'],
          },
        },
        relativePath: 'data/pokemon/species/0001-bulbasaur.json',
      );

      expect(entry.id, 'bulbasaur');
      expect(entry.nationalDex, 1);
      expect(entry.primaryName, 'Bulbasaur');
      expect(entry.types, <String>['grass', 'poison']);
      expect(entry.relativePath, 'data/pokemon/species/0001-bulbasaur.json');
    });
  });

  group('PokemonDatabaseIndex', () {
    test('indexes seeded species with the minimal list projection', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final entries = await indexService.build(workspace);
      final speciesIndexEntries =
          await pokemonReadRepository.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final bulbasaurSpeciesIndex = speciesIndexEntries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      // Lot 13 : on réutilise l'index local du lot 11 pour alimenter la liste
      // Pokédex simple. On y expose donc aussi les types, déjà disponibles dans
      // la projection légère d'espèce, sans créer un pipeline parallèle.
      expect(bulbasaur.types, <String>['grass', 'poison']);
      // Lot 15 : la génération est déjà lisible dans `PokemonSpeciesFile`.
      // L'exposer ici permet un filtre UI local sans inventer un nouveau
      // pipeline ni relire autrement les species depuis le workspace Pokédex.
      expect(bulbasaur.genIntroduced, 1);
      // Lot 38 : le filtre Activées / Désactivées repose sur le même index
      // léger. On y projette donc le booléen déjà stocké dans l'espèce locale,
      // sans charger la fiche détail ni créer un second état.
      expect(bulbasaur.isEnabledInProject, isTrue);
      expect(bulbasaur.id, bulbasaurSpeciesIndex.id);
      expect(bulbasaur.nationalDex, bulbasaurSpeciesIndex.nationalDex);
      expect(bulbasaur.primaryName, bulbasaurSpeciesIndex.primaryName);
      expect(bulbasaur.types, bulbasaurSpeciesIndex.types);
      expect(
        bulbasaur.refs,
        isA<PokemonDatabaseIndexRefs>()
            .having((refs) => refs.learnset, 'learnset', 'bulbasaur')
            .having((refs) => refs.evolution, 'evolution', 'bulbasaur')
            .having((refs) => refs.media, 'media', 'bulbasaur'),
      );
    });

    test('projects a disabled species into the lightweight index', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('''
{
  "id": "bulbasaur",
  "slug": "bulbasaur",
  "nationalDex": 1,
  "names": {
    "en": "Bulbasaur"
  },
  "speciesName": {
    "en": "Seed Pokemon"
  },
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
  "abilities": {
    "primary": "overgrow",
    "hidden": "chlorophyll"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": ["monster", "grass"],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 64,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "classification": {
    "isEnabledInProject": false,
    "isObtainable": true,
    "isLegendary": false,
    "isMythical": false,
    "isBaby": false
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
    "flavorText": "Disabled projection test."
  },
  "gameplayFlags": {
    "starterEligible": true,
    "giftOnly": false,
    "tradeOnly": false
  },
  "sourceMeta": {
    "seededBy": "test",
    "seedVersion": 99
  }
}
''');

      final entries = await indexService.build(workspace);
      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      expect(bulbasaur.isEnabledInProject, isFalse);
    });

    test(
        'fails explicitly when a species json is syntactically valid but structurally invalid',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Structurally Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);
      await File(
        p.join(speciesDir.path, '0001-invalid.json'),
      ).writeAsString('''
{
  "id": "",
  "nationalDex": 0,
  "names": {},
  "typing": {"types": ["grass"]},
  "refs": {
    "learnset": "",
    "evolution": "",
    "media": ""
  }
}
''');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('non-empty id'),
          ),
        ),
      );
    });

    test('uses the project pokemon speciesDir instead of a hardcoded path',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final originalManifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/custom_species';

      // On deplace seulement les species pour prouver que le service lit la
      // config projet, pas le chemin historique hardcode de la couche legacy.
      final originalSpeciesDir = Directory(
        workspace
            .resolveProjectRelativePath(originalManifest.pokemon.speciesDir),
      );
      final targetSpeciesDir = Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      );
      await targetSpeciesDir.create(recursive: true);

      await for (final entity in originalSpeciesDir.list(recursive: false)) {
        if (entity is File) {
          await entity
              .rename(p.join(targetSpeciesDir.path, p.basename(entity.path)));
        }
      }

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).create(recursive: true);
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "refs": {
    "learnset": "decoy",
    "evolution": "decoy",
    "media": "decoy"
  }
}
''');

      final updatedManifest = originalManifest.copyWith(
        pokemon: originalManifest.pokemon.copyWith(
          speciesDir: customSpeciesDir,
        ),
      );
      await projectRepository.saveProject(
        updatedManifest,
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(
          entries.map((entry) => entry.id),
          containsAll(<String>[
            'bulbasaur',
            'ivysaur',
          ]));
      expect(entries.map((entry) => entry.id), isNot(contains('decoy')));
    });

    test(
        'returns an empty index when the configured species directory is empty',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Empty Index Project',
        tempProjectRoot.path,
      );

      final manifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/empty_species';
      await Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      ).create(recursive: true);
      await projectRepository.saveProject(
        manifest.copyWith(
          pokemon: manifest.pokemon.copyWith(speciesDir: customSpeciesDir),
        ),
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(entries, isEmpty);
    });

    test('fails explicitly when a species json file is invalid', () async {
      await createProjectUseCase.execute(
        'Pokemon Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final invalidSpeciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await invalidSpeciesDir.create(recursive: true);
      await File(
        p.join(invalidSpeciesDir.path, '0001-bulbasaur.json'),
      ).writeAsString('{ invalid json');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('does not load learnsets evolutions or media during indexing',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');

      await Directory(
        workspace.resolveProjectRelativePath('data/pokemon/media'),
      ).create(recursive: true);
      await File(
        workspace
            .resolveProjectRelativePath('data/pokemon/media/bulbasaur.json'),
      ).writeAsString('{ invalid json');

      final entries = await indexService.build(workspace);

      expect(entries.map((entry) => entry.id), contains('bulbasaur'));
      expect(entries.map((entry) => entry.id), contains('ivysaur'));
    });

    test('reads from the workspace project and not Directory.current',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final decoy =
          await Directory.systemTemp.createTemp('pokemon_index_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "refs": {
    "learnset": "decoy",
    "evolution": "decoy",
    "media": "decoy"
  }
}
''');

        Directory.current = decoy.path;

        final entries = await indexService.build(workspace);

        expect(entries.any((entry) => entry.id == 'decoy'), isFalse);
        expect(entries.any((entry) => entry.id == 'bulbasaur'), isTrue);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await indexService.build(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await indexService.build(workspace);

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

Future<void> _createProjectAndSeedDemoData(
  CreateProjectUseCase createProjectUseCase,
  SeedPokemonDemoDataUseCase seedUseCase,
  ProjectFileSystem workspace,
  String projectRootPath,
) async {
  await createProjectUseCase.execute(
    'Pokemon Database Index Project',
    projectRootPath,
  );
  await seedUseCase.execute(workspace);
}

```
### 13.8 `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Représente la seule surface d'édition Pokédex autorisée en phase 8A.
///
/// Le périmètre est volontairement serré :
/// - `classification.isEnabledInProject` pour le lot 37 ;
/// - quelques métadonnées simples pour le lot 39 ;
/// - aucun learnset ;
/// - aucune évolution ;
/// - aucun média ;
/// - aucune ref locale ;
/// - aucune forme riche ;
/// - aucune classification avancée hors du flag `isEnabledInProject`.
class UpdatePokedexSpeciesMetadataRequest {
  const UpdatePokedexSpeciesMetadataRequest({
    required this.speciesId,
    required this.isEnabledInProject,
    required this.names,
    required this.flavorText,
    required this.starterEligible,
    required this.giftOnly,
    required this.tradeOnly,
  });

  final String speciesId;
  final bool isEnabledInProject;
  final Map<String, String> names;
  final String? flavorText;
  final bool starterEligible;
  final bool giftOnly;
  final bool tradeOnly;
}

typedef PokedexSpeciesMetadataSaver = Future<PokemonSpeciesFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesMetadataRequest request,
);

/// Réécrit une espèce locale en ne touchant qu'aux métadonnées simples déjà
/// supportées par le modèle courant.
///
/// Pourquoi un use case dédié :
/// - la UI ne doit pas reconstruire elle-même un `PokemonSpeciesFile` complet ;
/// - l'espèce locale reste la source de vérité unique ;
/// - on relit l'espèce existante puis on ne remplace que les champs autorisés ;
/// - on délègue l'écriture au repository existant pour préserver le vrai chemin
///   du fichier espèce déjà présent.
class UpdatePokedexSpeciesMetadataUseCase {
  const UpdatePokedexSpeciesMetadataUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonSpeciesFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );

    // On ne reconstruit jamais l'espèce "depuis zéro" dans la UI.
    // Le but est précisément de préserver :
    // - les refs ;
    // - les formes ;
    // - la classification lourde ;
    // - les stats et autres blocs hors périmètre.
    final updatedSpecies = PokemonSpeciesFile(
      id: currentSpecies.id,
      slug: currentSpecies.slug,
      nationalDex: currentSpecies.nationalDex,
      names: _normalizeLocalizedValues(request.names),
      speciesName: currentSpecies.speciesName,
      genIntroduced: currentSpecies.genIntroduced,
      typing: currentSpecies.typing,
      baseStats: currentSpecies.baseStats,
      abilities: currentSpecies.abilities,
      breeding: currentSpecies.breeding,
      progression: currentSpecies.progression,
      forms: currentSpecies.forms,
      classification: PokemonSpeciesClassification(
        // Lot 37 : c'est l'unique source de vérité du statut projet.
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: currentSpecies.classification.isObtainable,
        isLegendary: currentSpecies.classification.isLegendary,
        isMythical: currentSpecies.classification.isMythical,
        isBaby: currentSpecies.classification.isBaby,
      ),
      // On préserve les refs à l'identique : lot 39 ne doit pas casser
      // learnset / évolution / média au passage.
      refs: currentSpecies.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: currentSpecies.dexContent.heightM,
        weightKg: currentSpecies.dexContent.weightKg,
        color: currentSpecies.dexContent.color,
        flavorText: _normalizeOptionalText(request.flavorText),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: currentSpecies.sourceMeta,
    );

    await writeRepository.saveSpecies(workspace, updatedSpecies);
    return updatedSpecies;
  }

  Map<String, String> _normalizeLocalizedValues(Map<String, String> values) {
    final normalized = <String, String>{};

    // On reste volontairement permissif ici :
    // - pas de nouvelle règle métier sur les locales ;
    // - pas de suppression implicite d'une clé ;
    // - on trim seulement les clés et valeurs pour éviter de persister du bruit.
    //
    // La UI de la phase 8A n'ajoute ni ne retire de locales ; elle ne modifie
    // que les valeurs déjà présentes. Cette normalisation minimale suffit donc.
    for (final entry in values.entries) {
      final locale = entry.key.trim();
      if (locale.isEmpty) {
        continue;
      }
      normalized[locale] = entry.value.trim();
    }

    return normalized;
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

```
### 13.9 `packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesMetadataUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_metadata_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesMetadataUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Metadata Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('UpdatePokedexSpeciesMetadataUseCase', () {
    test(
        'persists enabled state and simple metadata while keeping refs and project.json unchanged',
        () async {
      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies);

      final projectFile = File(workspace.projectManifestPath);
      final beforeProjectJson = await projectFile.readAsString();

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: false,
          names: <String, String>{
            'fr': 'Bulbizarre Projet',
            'en': 'Bulbasaur Project',
          },
          flavorText: 'Texte Pokédex édité localement.',
          starterEligible: false,
          giftOnly: true,
          tradeOnly: true,
        ),
      );

      final readBack =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(readBack.classification.isEnabledInProject, isFalse);
      expect(readBack.names['fr'], 'Bulbizarre Projet');
      expect(readBack.names['en'], 'Bulbasaur Project');
      expect(readBack.dexContent.flavorText, 'Texte Pokédex édité localement.');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.gameplayFlags.giftOnly, isTrue);
      expect(readBack.gameplayFlags.tradeOnly, isTrue);

      // On verrouille explicitement le point le plus fragile de cette phase :
      // l'édition simple ne doit jamais casser les refs déjà branchées.
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
      expect(readBack.forms.baseFormId, 'bulbasaur');
      expect(readBack.sourceMeta.seededBy, 'test');
      expect(readBack.sourceMeta.seedVersion, 1);

      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'reuses an existing non-canonical species path instead of creating a canonical duplicate during metadata updates',
        () async {
      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);

      final customFile = File(
        p.join(speciesDir.path, '0001-bulbizarre-custom.json'),
      );
      await customFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_bulbasaurSpecies.toJson()),
      );

      await useCase.execute(
        workspace,
        const UpdatePokedexSpeciesMetadataRequest(
          speciesId: 'bulbasaur',
          isEnabledInProject: true,
          names: <String, String>{
            'fr': 'Bulbizarre Mis à Jour',
            'en': 'Bulbasaur Refreshed',
          },
          flavorText: 'Le writer doit réutiliser le chemin déjà présent.',
          starterEligible: true,
          giftOnly: false,
          tradeOnly: false,
        ),
      );

      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);

      final speciesFiles = await speciesDir
          .list(recursive: false)
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
      expect(readBack.names['en'], 'Bulbasaur Refreshed');
      expect(
        readBack.dexContent.flavorText,
        'Le writer doit réutiliser le chemin déjà présent.',
      );
      expect(readBack.refs.learnset, 'bulbasaur');
      expect(readBack.refs.evolution, 'bulbasaur');
      expect(readBack.refs.media, 'bulbasaur');
    });
  });
}

const PokemonSpeciesFile _bulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
  speciesName: <String, String>{'fr': 'Pokémon Graine', 'en': 'Seed Pokemon'},
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
    flavorText: 'Une étrange graine a été plantée sur son dos à la naissance.',
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
### 13.10 `reports/pokedex-phase-8a-lots-37-39-report.md`

Le contenu complet de ce fichier est le présent document. Il s’agit du rapport lui-même ; par définition, le texte que tu lis ici en est déjà la reproduction intégrale.

## 14. Checklist finale d’autocontrôle
- [x] J’ai bien utilisé des sub-agents
- [x] Je n’ai gardé qu’une seule implémentation finale
- [x] Je n’ai pas touché les lots 40+
- [x] Je n’ai pas créé de second flag “enabled”
- [x] Je réutilise `classification.isEnabledInProject` comme source de vérité
- [x] Je n’ai pas touché `project.json`
- [x] Le filtre “Toutes / Activées / Désactivées” existe et fonctionne
- [x] La donnée du filtre repose sur la vraie donnée persistée
- [x] L’édition locale est limitée aux métadonnées simples
- [x] Je n’ai pas ouvert l’édition learnset / évolution / média
- [x] Je n’ai pas ouvert l’édition formes/classification lourde
- [x] Enregistrer persiste réellement
- [x] Annuler n’écrit rien
- [x] Les refs restent intactes après édition
- [x] Les tests ciblés passent
- [x] flutter analyze passe
- [x] Je n’ai exécuté aucune commande Git d’écriture
- [x] Le rapport contient le contenu complet de tous les fichiers touchés
- [x] Le rapport documente honnêtement tout incident réel
