# Phase R1 — Lot 4 — Exécution batch + progression + rapport

## 1. Résumé exécutif honnête

Le lot 4 est livré dans le périmètre demandé.

Ce qui est maintenant réellement disponible dans le wizard Pokédex, branche `API externe` :

- un batch réel distinct du dry-run ;
- une exécution explicite depuis la preview batch ;
- une progression honnête basée sur les callbacks réels du use case batch, sans pourcentage simulé ;
- un écran de résultat séparé du dry-run ;
- des compteurs visibles : succès, conflits, erreurs, skips, terminées ;
- un rapport final détaillé par espèce ;
- un refresh du workspace si au moins une espèce a effectivement été écrite ;
- une règle stable de sélection post-batch : première espèce réellement écrite dans l'ordre visible de la sélection batch.

Le lot 4 n'ouvre pas le lot 5 et ne réécrit pas la 11A.
Le mono-espèce et le dry-run batch du lot 3 ont été conservés et retestés.

## 2. État initial audité

Avant modification, l'état réel du repo était :

- lot 1 livré : résolveur de requête externe structuré ;
- lot 2 livré : auto-complétion mono-espèce avec sélection explicite ;
- lot 3 livré : sélection batch + dry-run batch dans le wizard ;
- `BatchImportExternalPokemonSpeciesUseCase` existait déjà et faisait le vrai travail batch, mais ne renvoyait qu'un résultat final global ;
- le wizard affichait une preview batch lot 3, mais refusait explicitement tout import batch réel ;
- le refresh du workspace après import existait déjà pour le mono-espèce via `_openImportFlow`.

Points d'audit identifiés avant implémentation :

1. brancher l'import batch réel sans dupliquer le dry-run ;
2. garder une progression honnête ;
3. éviter qu'une logique métier batch dérive dans l'UI ;
4. préserver le flow mono-espèce existant ;
5. choisir une règle stable pour la sélection après batch réel.

## 3. Périmètre inclus / exclu

### Inclus

- extension minimale du use case batch existant pour exposer une progression honnête ;
- provider DI de batch réel pour le workspace Pokédex ;
- exécution batch réelle depuis le wizard `API externe` ;
- séparation explicite dry-run / import réel ;
- écran de résultat lot 4 séparé de la preview lot 3 ;
- refresh du workspace si écritures réelles ;
- sélection stable post-batch ;
- tests application, wiring, UI et non-régression ;
- mise à jour de la roadmap ;
- report complet de lot.

### Exclu

- retry sélectif ;
- relance partielle depuis le rapport ;
- import en arrière-plan ;
- cancellation complexe ;
- queue d'imports ;
- exécution parallèle ;
- exécution automatique après dry-run ;
- refonte complète du wizard ;
- lot 5 et suivants.

## 4. Décisions d'architecture

### 4.1. Réutilisation stricte du pipeline batch existant

Décision retenue : réutiliser `BatchImportExternalPokemonSpeciesUseCase` comme cœur d'exécution.

Raison :

- le pipeline batch existait déjà ;
- il ne fallait pas créer un second pipeline concurrent ;
- le lot 4 devait prolonger l'existant, pas le contourner.

### 4.2. Extension minimale du use case batch

Décision retenue : ajouter un modèle `PokemonExternalBatchImportProgress` et un callback optionnel `onProgress` au use case batch existant.

Raison :

- l'UI avait besoin d'une progression honnête ;
- le résultat final seul ne suffisait pas ;
- cette extension reste locale au use case existant ;
- aucune nouvelle stack batch n'a été créée.

### 4.3. Séparation stricte dry-run / exécution réelle / résultat final

Décision retenue :

- conserver la preview dry-run lot 3 telle quelle ;
- ajouter un bouton explicite `Exécuter le batch` dans cette preview ;
- afficher ensuite un step de résultat distinct pour l'import réel.

Raison :

- éviter de mélanger lot 3 et lot 4 ;
- garder un flow produit lisible ;
- ne pas transformer la preview dry-run en pseudo-rapport final.

### 4.4. Règle stable de refresh du workspace

Décision retenue :

- refresh seulement si au moins une espèce a effectivement été écrite ;
- sélection de la première espèce écrite dans l'ordre visible de la sélection batch, pas selon l'ordre interne du use case.

Raison :

- le use case batch trie en interne de manière déterministe ;
- l'utilisateur, lui, voit un ordre de sélection dans le wizard ;
- la règle la plus défendable côté UX est de respecter cet ordre visible.

### 4.5. Pas de faux pourcentage

Décision retenue :

- afficher une progression par `terminées / total` et les compteurs réellement remontés ;
- ne pas simuler un pourcentage interne du pipeline ;
- la barre de progression n'utilise que `completedCount / totalCount`.

Raison :

- le prompt interdisait tout faux progrès ;
- le callback de progression donne justement une base suffisante pour rester honnête.

## 5. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `ROADMAP_FANGAME_RECALEE.md`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `packages/map_editor/test/provider_wiring_test.dart`

### Créés

- `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`
- `reports/phase-r1-lot-4-batch-execution-progress-report.md`

### Supprimés

- aucun

## 6. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

Ajout du modèle de progression batch et du callback optionnel `onProgress` sur le use case batch existant.
But : donner au lot 4 une progression honnête sans créer un second orchestrateur.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

Ajout du typedef `PokedexExternalBatchImporter` avec callback de progression.
But : exposer proprement le batch réel au wizard.

### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

Ajout du provider `pokedexExternalBatchImporterProvider`.
But : brancher l'exécution batch réelle sur le use case existant.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

Injection du callback `externalBatchImporter` jusqu'au body.
But : garder le wiring cohérent avec le reste du workspace.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`

Passage du callback de batch réel au flow d'import, et adaptation de la fermeture du wizard à un résultat plus générique.
But : refresh propre du workspace + feedback final sans logique parallèle.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

Ajout du vrai flow lot 4 :

- nouveau step `result` ;
- état d'exécution batch réel ;
- fermeture batch avec feedback générique ;
- règle stable de sélection post-batch ;
- séparation mono / batch réel ;
- conservation du mono-espèce existant.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

Ajout :

- bouton `Exécuter le batch` sur la preview batch ;
- écran de résultat batch réel ;
- compteurs + progression honnête ;
- rapport final par espèce.

### `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

Ajout de tests sur :

- progression réelle par espèce ;
- statut `skipExisting` ;
- statut `failOnConflict`.

### `packages/map_editor/test/provider_wiring_test.dart`

Vérification du provider `pokedexExternalBatchImporterProvider`.

### `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`

Nouveau fichier de tests widget pour le lot 4 :

- séparation dry-run / import réel ;
- affichage du résultat final ;
- refresh du workspace après batch réel ;
- sélection stable de la première espèce écrite.

### `ROADMAP_FANGAME_RECALEE.md`

Mise à jour précise de la roadmap pour marquer le lot 4 comme livré et M1 comme atteint.

## 7. Sub-agents utilisés, conclusions, retenu / rejeté

Le système n'a pas permis de créer de nouveaux sub-agents dans ce tour à cause de la limite de threads. J'ai donc réutilisé honnêtement des threads déjà ouverts via `send_input` / `wait_agent`.

### Sub-agent 1 — Boyle — scope / architecture

Conclusions :

- réutiliser `BatchImportExternalPokemonSpeciesUseCase` ;
- n'ajouter qu'un hook de progression minimal ;
- garder la logique de batch hors UI.

Retenu : oui.
Rejeté : toute idée de nouveau pipeline batch ou de nouveau use case vide purement cosmétique.

### Sub-agent 2 — Avicenna — UX / flow wizard

Conclusions :

- garder un flow explicite `query -> resolve -> dry-run -> import réel -> résultat` ;
- mettre l'import réel sur la preview batch, mais afficher un step de résultat séparé ;
- ne pas fusionner preview et rapport final.

Retenu : oui.
Rejeté : réutiliser la preview lot 3 comme pseudo-rapport final.

### Sub-agent 3 — Mendel — matrice de tests

Conclusions :

- couvrir progression et catégories de résultat côté application ;
- couvrir le wiring du provider batch réel ;
- couvrir l'UI lot 4 + non-régression lot 2 / lot 3.

Retenu : oui.
Rejeté : tests décoratifs sans preuve de séparation dry-run / batch réel.

### Sub-agent 4 — Banach — contradicteur

Conclusions :

- éviter toute ambiguïté entre dry-run et exécution réelle ;
- éviter le faux progrès ;
- éviter un refresh workspace sans critère stable ;
- refuser toute dérive vers le lot 5.

Retenu : oui.
Rejeté : auto-import après dry-run, faux pourcentage, ou création d'une deuxième couche batch UI/métier.

## 8. Commandes réellement exécutées

### Audit / lecture

```text
sed -n '1390,1515p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '200,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '720,980p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
sed -n '1,220p' packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart
sed -n '2020,2105p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,240p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '240,420p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,120p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
python - <<'PY' ... inspection ciblée de pokedex_workspace_page.dart ... PY
rg -n ... sur use case batch, progress, wiring et clés UI
```

### Validation

```text
dart format packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
flutter analyze --no-pub packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart
flutter test test/import_external_pokemon_use_cases_test.dart test/provider_wiring_test.dart test/pokedex_external_batch_execute_ui_test.dart test/pokedex_external_batch_dry_run_ui_test.dart test/pokedex_external_autocomplete_ui_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"
```

### Git état

```text
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 9. Résultats réels

### `dart format`

```text
Formatted packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
Formatted packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
Formatted 9 files (2 changed) in 0.04 seconds.
```

### `flutter analyze --no-pub`

```text
Analyzing 12 items...
No issues found! (ran in 1.9s)
```

### `flutter test` ciblé principal

```text
00:03 +39: All tests passed!
```

### `flutter test` non-régression mono-espèce

```text
00:02 +1: All tests passed!
```

## 10. Incidents rencontrés

### Incident 1 — premier `flutter test` lancé au mauvais niveau du monorepo

Commande fautive :

```text
flutter test packages/map_editor/test/import_external_pokemon_use_cases_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"
```

Sortie :

```text
Error: No pubspec.yaml file found.
This command should be run from the root of your Flutter project.
```

Correction : relance depuis `packages/map_editor`.

### Incident 2 — patch initial trop gros sur `pokedex_import_flow.dart`

Le premier patch global n'a pas matché le contexte exact du fichier.
Correction : reprise par petits patches ciblés pour ne pas casser le flow existant.

### Incident 3 — faux helper de test sur les artefacts écrits

Premier essai : utilisation de `artifact.wasWritten` sur `PokemonExternalImportArtifactResult`.
Correction : comptage basé sur `action == create || action == overwrite`, cohérent avec le modèle existant.

## 11. État git utile

Note : le snapshot git ci-dessous a été capturé juste avant la génération de ce
report, afin d'éviter l'auto-référence du fichier de report lui-même dans ses
propres extraits.

### `git status --short`

```text
 M ROADMAP_FANGAME_RECALEE.md
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
?? packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
```

### `git diff --stat`

```text
 ROADMAP_FANGAME_RECALEE.md                         | 219 +++++++++++-
 .../app/providers/pokedex/pokedex_providers.dart   |  10 +
 .../import_external_pokemon_use_cases.dart         |  64 ++++
 .../pokedex_workspace/pokedex_import_flow.dart     | 212 +++++++++--
 .../pokedex_import_flow_steps.dart                 | 396 ++++++++++++++++++++-
 .../pokedex_workspace/pokedex_workspace_body.dart  |  42 +--
 .../pokedex_workspace/pokedex_workspace_page.dart  |   8 +
 .../src/ui/canvas/pokedex_workspace_loader.dart    |   7 +
 .../import_external_pokemon_use_cases_test.dart    |  80 +++++
 packages/map_editor/test/provider_wiring_test.dart |   1 +
 10 files changed, 982 insertions(+), 57 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
```

## 12. Checklist finale

- [x] pas de pipeline Pokédex parallèle
- [x] pas de réécriture de la 11A
- [x] pas de réouverture des lots 1 à 3
- [x] batch réel distinct du dry-run
- [x] progression honnête, non simulée
- [x] rapport final par espèce
- [x] refresh workspace si écritures réelles
- [x] règle stable de sélection post-batch
- [x] mono-espèce non cassé
- [x] dry-run lot 3 non cassé
- [x] tests ciblés verts
- [x] analyze vert
- [x] roadmap mise à jour
- [x] aucun commit git
- [x] aucun merge / rebase / push / tag / amend / stash

## 13. Annexe — contenu complet de tous les fichiers texte modifiés / créés

Note explicite : pour éviter une récursion infinie, ce report n'inclut pas sa propre source complète dans cette annexe. Tous les autres fichiers texte modifiés / créés sont inclus intégralement ci-dessous.


### `ROADMAP_FANGAME_RECALEE.md`

```text
# Roadmap Maître Recalée — pokemonProject

## 1. But du document

Ce document sert de **roadmap maître recalée** pour la suite du projet.

Il ne repart pas de zéro.
Il part de l'état réel actuel du repo et d'un principe central qui ne doit pas bouger :

**on améliore l'existant, on ne crée aucune stack parallèle.**

Cela implique explicitement :

- pas de nouveau runtime Pokémon parallèle ;
- pas de nouveau save system parallèle ;
- pas de nouveau modèle concurrent à `PlayerPokemon` ;
- pas de nouveau moteur de combat parallèle à `map_battle` ;
- pas de second pipeline Pokédex ;
- pas de logique métier poussée dans les widgets UI ;
- pas de grand refactor transversal "propre" si une extension locale honnête suffit.

Ce document remplace une roadmap trop "domain-first" par une roadmap plus **réaliste, verticale et pilotable**.

## 2. Résumé exécutif

Le projet a déjà dépassé le stade du prototype vide.

Aujourd'hui, le repo dispose déjà de fondations réelles pour :

- la persistance de partie ;
- le Pokédex local et ses imports externes ;
- le catalogue local des moves ;
- l'édition minimale des learnsets ;
- les trainers et les encounter tables ;
- les battle requests runtime ;
- un moteur de combat pur Dart encore minimal ;
- un pattern réel de field move avec Surf.

Le vrai enjeu n'est donc plus de "construire un système Pokémon from scratch".
Le vrai enjeu est de **faire converger les briques existantes vers une boucle fangame complète**.

Le point le plus important de cette version recalée est le suivant :

**le bridge runtime -> battle réel doit arriver tôt**.

On ne doit pas repousser indéfiniment la preuve de la boucle de jeu pendant qu'on peaufine l'authoring.
La bonne stratégie est :

1. rendre le Pokédex auteur vraiment productif ;
2. brancher les références assistées là où elles ont déjà un retour immédiat ;
3. rendre trainers et encounters suffisamment propres pour produire de vraies données ;
4. supprimer le placeholder du handoff runtime -> battle ;
5. obtenir un combat sauvage réel ;
6. obtenir capture + persistance minimale ;
7. seulement ensuite approfondir le moteur de combat et élargir la boucle RPG.

## 3. Ce qui est déjà acquis dans le repo

Cette section ne décrit pas des intentions.
Elle décrit les éléments déjà présents dans l'état actuel du repo et du worktree.

### 3.1. Save et modèle de partie

Le repo a déjà une vraie base persistée :

- `GameState`
- `SaveData`
- `PlayerPokemon`
- `PlayerParty`
- `TrainerProfile`
- `Bag`
- `PlayerProgression`
- migration legacy et persistance runtime

Conclusion :

- on ne crée surtout pas de modèle `OwnedPokemon` concurrent ;
- on ne crée surtout pas un second format de save.

### 3.2. Pokédex et import Pokémon

La phase 11A est considérée comme clôturée.
Le repo a déjà :

- une config Pokémon projet légère dans `ProjectManifest` ;
- un `dataRoot`, des sous-dossiers dédiés (`species`, `learnsets`, `evolutions`, `media`) et des `catalogFiles` explicites ;
- un bootstrap local via `InitializePokemonProjectStorageUseCase` ;
- un pipeline d'import externe Pokémon ;
- un `dryRun` et une preview ;
- une source produit unique côté UI ;
- des mini-fix de cohérence média ;
- une preuve de clôture 11A documentée.

Conclusion :

- on ne rouvre pas artificiellement 11A ;
- on n'écrit pas un deuxième pipeline d'import externe.

### 3.2.1. Avancement réel de la phase R1 déjà livré dans le worktree

Les quatre premiers lots de la phase R1 ont maintenant été livrés dans le
worktree courant. Ils ne sont plus à considérer comme du travail à démarrer,
mais comme du socle acquis à prolonger proprement.

#### Lot 1 — Résolveur de requête externe Pokédex

Ce lot existe maintenant côté application avec :

- un modèle de résolution structuré pour :
  - mono-espèce ;
  - liste explicite ;
  - plage dex ;
  - génération ;
  - requête invalide / ambiguë ;
- un résolveur pur, sans réseau et sans UI ;
- un provider DI dédié dans `map_editor`.

Le contrat déjà livré couvre au minimum :

- `bulbasaur`
- `1`
- `001`
- `0001`
- `1-151`
- `gen 1`
- `generation 2`
- `pikachu, eevee, abra`
- refus explicite des cas ambigus de type `pikachu eevee abra`

#### Lot 2 — Auto-complétion mono-espèce dans le wizard

Ce lot existe maintenant dans la branche `API externe` du wizard Pokédex avec :

- un use case de recherche mono-espèce réutilisant le résolveur du lot 1 ;
- une vraie surface de suggestions ;
- une sélection explicite obligatoire ;
- un blocage de la preview/import tant qu'aucune suggestion réelle n'a été
  choisie ;
- des états propres :
  - vide ;
  - loading ;
  - aucun résultat ;
  - hors-scope ;
  - invalide ;
  - erreur.

Le point important à conserver pour la suite :

- le widget ne parse pas la requête lui-même ;
- la preview/import mono-espèce ne repose pas sur une simple string tapée ;
- seule une suggestion explicitement sélectionnée débloque la suite.

#### Lot 3 — Sélection batch + dry-run batch

Ce lot existe maintenant dans la même branche `API externe` du wizard avec :

- un mode explicite `Mono-espèce` / `Batch dry-run` ;
- un use case dédié de résolution batch, réutilisant le résolveur du lot 1 ;
- la compréhension de trois formes batch :
  - liste explicite ;
  - plage dex ;
  - génération ;
- une liste finale résolue visible avant toute preview ;
- un dry-run batch branché sur le pipeline batch applicatif existant avec
  `dryRun: true` ;
- une preview batch lisible ;
- un blocage explicite de tout import batch réel.

Règles déjà en place à ne pas casser :

- une liste explicite partiellement résolue reste visible mais bloque le
  dry-run ;
- les requêtes par plage dex et génération ne ciblent volontairement que les
  espèces de base ;
- une liste explicite peut encore conserver une forme si elle a été demandée
  explicitement ;
- le dry-run batch n'écrit rien et ne constitue pas encore une exécution lot 4.

Artefacts de preuve déjà présents :

- `reports/phase-r1-lot-1-pokedex-query-resolver-report.md`
- `reports/phase-r1-lot-2-pokedex-external-autocomplete-report.md`
- `reports/phase-r1-lot-3-batch-selection-dry-run-report.md`

#### Lot 4 — Exécution batch + progression + rapport

Ce lot existe maintenant dans le même flow `API externe`, sans réécrire le
pipeline batch applicatif existant.

Ce qui est désormais livré :

- une action explicite d'exécution batch réelle distincte du dry-run ;
- une progression honnête alimentée par les callbacks réels du use case batch ;
- un écran de résultat séparé du dry-run preview ;
- des compteurs visibles :
  - succès ;
  - conflits ;
  - erreurs ;
  - skips ;
  - espèces terminées ;
- un rapport final détaillé par espèce ;
- un refresh du workspace si au moins une espèce a réellement été écrite ;
- une règle stable de sélection post-import :
  - première espèce réellement écrite dans l'ordre visible de la sélection batch
    ;
- conservation stricte du flow mono-espèce et du dry-run du lot 3.

Décisions d'implémentation désormais en place :

- aucun pipeline batch parallèle n'a été créé ;
- `BatchImportExternalPokemonSpeciesUseCase` reste le cœur d'exécution ;
- une extension minimale du use case expose une progression honnête par espèce
  terminée ;
- l'UI ne simule aucun faux pourcentage interne ;
- le rapport final réutilise directement `PokemonExternalBatchImportResult`.

Limites assumées à ce stade :

- pas de retry sélectif ;
- pas de relance partielle depuis le rapport ;
- pas d'import en arrière-plan ;
- pas de cancellation complexe ;
- pas de pagination du rapport final.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-4-batch-execution-progress-report.md`

### 3.3. Catalogues locaux et moves catalog

Le repo n'est plus dans un état "catalogues à inventer".
Il a déjà :

- un scaffold local de catalogues dans l'arborescence Pokémon du projet ;
- des clés catalogue explicites dans la config Pokémon ;
- un import JSON catalogue local ;
- des validations croisées déjà branchées sur certains catalogues ;
- des seeds et jeux de démonstration pour plusieurs familles.

La phase 11B a ensuite fait exister un vrai premier jalon moves dans le worktree courant :

- catalogue local des moves ;
- sync/import depuis source externe ;
- surface minimale côté éditeur ;
- première intégration utile avec le learnset editor.

Le repo valide déjà concrètement :

- `learnset -> moves catalog`
- `species -> types catalog`

et sait déjà basculer certains catalogues manquants vers des warnings explicites plutôt que des comportements opaques.

Conclusion :

- la partie "catalogues" ne repart pas de zéro ;
- la stratégie réaliste est bien **moves-first**, déjà amorcée ;
- le prochain travail doit capitaliser sur ce socle au lieu de le réécrire.

### 3.4. Trainers et encounter tables

Le repo contient déjà :

- `ProjectTrainerEntry` et ses variantes associées ;
- des use cases trainers ;
- des use cases encounter tables ;
- un wiring applicatif déjà exposé dans l'éditeur ;
- des panneaux éditeur existants ;
- la résolution de rencontres côté `map_gameplay`.

Conclusion :

- on améliore ces surfaces ;
- on ne crée pas un second système de trainers ou de rencontres.

### 3.5. Runtime et battle skeleton

Le runtime sait déjà :

- déclencher une demande de combat sauvage ;
- déclencher une demande de combat trainer ;
- produire de vrais `BattleStartRequest` sauvages et trainers ;
- ouvrir un overlay de combat ;
- relayer un flux de retour combat vers l'overworld.

Le moteur `map_battle` existe déjà, mais il reste un MVP.

Le vrai trou actuel est bien le dernier maillon :

- le mapping final vers `BattleSetup` reste encore placeholder ;
- `_toBattleSetup()` injecte encore des espèces, niveaux et moves simplifiés au lieu de consommer complètement les vraies données projet/save.

Conclusion :

- le vrai point critique n'est pas "faire apparaître un combat" ;
- le vrai point critique est de **faire cesser les placeholders métier** entre runtime, données projet et moteur battle.

### 3.6. Field moves

Surf existe déjà comme pattern réel.

Conclusion :

- les futures capacités terrain doivent généraliser ce pattern ;
- elles ne doivent pas le dupliquer en plusieurs sous-systèmes hardcodés.

## 4. Ce qui reste partiel

Cette section couvre les zones déjà entamées mais pas encore suffisamment solides pour être considérées comme "terminées".

### 4.1. Pokédex auteur

Le Pokédex existe, et la phase R1 a déjà avancé dans le worktree :

- la résolution de requête externe existe ;
- l'auto-complétion mono-espèce existe ;
- le flow batch existe maintenant jusqu'au dry-run lisible.

Ce qui manque encore côté Pokédex auteur :

- l'exécution batch réelle avec progression ;
- le retry ciblé ;
- le rapport final d'exécution ;
- la maintenance bulk ergonomique ;
- les outils de revalidation / resync / maintenance globale plus riches.

### 4.2. Catalogues et références assistées

Le catalogue moves existe déjà, mais il reste partiel au niveau produit :

- l'UI learnset doit encore mieux exploiter ce catalogue ;
- les équipes trainers doivent ensuite bénéficier du même socle moves-first ;
- les autres écrans n'en profitent pas encore suffisamment ;
- moves est la priorité actuelle ;
- abilities / items / types / egg groups / growth rates sont encore à traiter de manière progressive.

### 4.3. Trainers et encounters

Le socle est là, mais l'expérience auteur n'est pas encore au bon niveau :

- trop de friction pour authorer une vraie team trainer proprement ;
- encore trop de surfaces peu assistées ;
- les encounter tables ne sont pas encore au niveau d'un vrai workflow "fangame authoring".

### 4.4. Bridge runtime -> battle

C'est aujourd'hui le plus gros point de vérité technique restant :

- le runtime sait lancer le combat ;
- mais le mapping final vers `BattleSetup` reste encore trop placeholder ;
- tant que ça n'est pas traité, la boucle de jeu Pokémon n'est pas vraiment prouvée.

### 4.5. Combat system

Le moteur battle existe, mais la profondeur système reste limitée :

- dégâts encore trop simplifiés ;
- pas encore toute la chaîne type chart / PP / accuracy / switch / statuts ;
- pas encore une boucle Pokémon crédible de bout en bout.

## 5. Ce qui reste réellement à construire

Voici les grands blocs qui restent réellement à construire, en distinguant bien le cœur de boucle du confort plus tardif.

### 5.1. Must-have avant toute ambition "fangame complet"

- Pokédex batch auteur utilisable
- références assistées moves là où elles ont le plus de valeur
- edition trainers/encounters suffisamment propre
- bridge runtime -> battle réel
- combat sauvage réel
- seen/caught persistant
- capture minimale
- trainer battle minimal complet
- heal / whiteout-lite

### 5.2. Should-have après preuve de boucle

- catalogues additionnels progressifs
- battle depth stage 1 puis stage 2
- starter / gifts / static encounters
- shop minimal
- centre Pokémon plus propre
- field abilities généralisées

### 5.3. Later

- tooling auteur plus riche
- recherche globale projet
- dashboard santé étendu
- UX runtime joueur plus ambitieuse
- documentation complète
- projet démo de référence
- packaging / build guide final

## 6. Roadmap maître recalée

La roadmap ci-dessous est le nouveau document de pilotage global.
Elle est volontairement plus compacte que la première version.

### Phase A — Pokédex auteur productif

But :

- rendre l'import, la recherche, le batch et la maintenance Pokédex réellement exploitables à l'échelle.

Contenu :

- résolveur de requête externe ;
- auto-complétion mono-espèce ;
- batch selection ;
- dry-run batch ;
- exécution batch ;
- rapport final ;
- revalidate / reimport / delete / maintenance bulk.

### Phase B — Références assistées progressives, moves-first

But :

- faire disparaître les champs texte bruts là où ils créent le plus de dette.

Ordre recommandé :

1. moves partout où ils débloquent une vraie valeur ;
2. species/forms/items dans trainers et encounters ;
3. autres catalogues seulement quand un écran ou une boucle les exige réellement.

Important :

- cette phase part d'un socle déjà présent ;
- elle ne recrée ni le moves catalog, ni son import, ni sa première surface éditeur ;
- elle prolonge ce qui est déjà livré en 11B.

### Phase C — Authoring trainers / encounters convergent

But :

- permettre à un auteur de produire sans JSON manuel des données directement combatables.

Contenu :

- trainer library minimal mais propre ;
- encounter tables minimales mais propres ;
- validation inline ;
- preview auteur simple.

### Phase D — Bridge runtime -> battle réel

But :

- faire sauter le placeholder entre les données projet/save et le moteur battle.

Contenu :

- mapper la vraie party joueur ;
- mapper les wild encounters réels ;
- mapper les vraies teams trainers ;
- appliquer proprement le résultat de combat au `GameState`.

### Phase E — Boucle Pokémon minimale jouable

But :

- prouver une vraie boucle Pokémon verticale.

Contenu :

- combat sauvage réel ;
- seen/caught ;
- capture minimale ;
- save/load cohérent ;
- combat trainer minimal ;
- heal / whiteout-lite.

### Phase F — Battle depth progressive

But :

- rendre le combat crédible sans bloquer la preuve de boucle.

Découpage recommandé :

- F1 : stats et payloads enrichis
- F2 : dégâts + STAB + type chart
- F3 : accuracy + crit + priorité + PP
- F4 : switch et parties complètes
- F5 : statuts majeurs
- F6 : abilities / items / forms progressifs
- F7 : rewards / IA / hooks de progression

### Phase G — Boucle fangame minimale complète

But :

- dépasser la simple preuve de combat pour obtenir un mini jeu Pokémon jouable.

Contenu :

- starter / gift / static encounter ;
- centre Pokémon ;
- shop minimal ;
- progression terrain généralisée ;
- économie et boucle de survie plus propre.

### Phase H — Tooling auteur, UX runtime et docs

But :

- transformer le repo en vrai produit interne confortable.

Contenu :

- validation actionnable ;
- health dashboard ;
- recherche globale ;
- playtest rapide ;
- rapports exportables ;
- UX runtime joueur enrichie ;
- documentation ;
- projet démo.

## 7. Milestones verticaux recalés

Ces milestones sont les vrais jalons de preuve.
Ils servent à éviter l'effet "beaucoup de lots terminés, peu de boucle réellement jouable".

### M1 — Pokédex auteur utilisable

Ce que ce milestone prouve :

- un auteur peut importer et maintenir des espèces à grande échelle sans bricoler.

Statut actuel :

- livré ;
- lots 1, 2, 3 et 4 livrés ;
- la base Pokédex auteur productif du cycle R1 est maintenant réellement
  atteinte.

Gate de sortie :

- mono-espèce avec auto-complétion ;
- batch sélectionnable ;
- dry-run batch ;
- exécution batch ;
- rapport lisible ;
- pas de parsing batch caché dans l'UI.

### M2 — Données combat authorables correctement

Ce que ce milestone prouve :

- les données qui alimentent le gameplay combatable peuvent être produites proprement dans l'éditeur.

Gate de sortie :

- learnsets profitent réellement du catalogue moves local ;
- trainers authorables sans JSON manuel ;
- encounter tables authorables sans texte libre fragile ;
- erreurs de refs visibles immédiatement ;
- preview auteur minimale disponible là où utile.

### M3 — Handoff combat réel

Ce que ce milestone prouve :

- le runtime ne triche plus entre ses requests, les données projet et `BattleSetup`.

Gate de sortie :

- plus de placeholder métier dans le handoff ;
- vraie party joueur mappée ;
- vraies species wild mappées ;
- vraies teams trainers mappées ;
- tests runtime dédiés.

### M4 — Combat sauvage jouable

Ce que ce milestone prouve :

- la première vraie boucle Pokémon verticale existe.

Gate de sortie :

- déplacement ;
- rencontre sauvage ;
- handoff réel ;
- combat jouable ;
- retour overworld propre ;
- état runtime resynchronisé.

### M5 — Capture et persistance minimale

Ce que ce milestone prouve :

- la boucle de jeu commence à "tenir" comme jeu Pokémon, pas seulement comme démo de combat.

Gate de sortie :

- seen/caught persiste ;
- capture minimale fonctionne ;
- l'équipe ou un fallback minimal est mis à jour proprement ;
- save/load relit correctement ce nouvel état.

### M6 — Combat trainer minimal complet

Ce que ce milestone prouve :

- la seconde grande boucle du RPG Pokémon est présente.

Gate de sortie :

- trainer battle réel ;
- victoire/défaite mappées ;
- anti-retrigger ;
- reward minimal ;
- flags de progression cohérents.

### M7 — Boucle fangame minimale complète

Ce que ce milestone prouve :

- on a un mini fangame Pokémon jouable du début à une petite boucle de progression.

Gate de sortie :

- starter ou gift minimal ;
- wild battle ;
- capture ;
- trainer battle ;
- heal ;
- whiteout-lite ;
- save/load toujours cohérent.

### M8 — Combat crédible v2

Ce que ce milestone prouve :

- le système de combat devient défendable comme vrai combat Pokémon simplifié.

Gate de sortie :

- dégâts crédibles ;
- type chart ;
- précision ;
- PP ;
- switch ;
- statuts stage 1.

### M9 — Tooling auteur de production

Ce que ce milestone prouve :

- le repo est tenable pour une production plus longue sans dette explosive.

Gate de sortie :

- validation actionnable ;
- recherche projet ;
- bulk maintenance ;
- playtest rapide ;
- rapports exploitables.

## 8. Backlog prioritaire recalé

Cette section décrit les **15 prochains lots réalistes**.
Ils sont ordonnés pour maximiser la convergence produit, pas seulement la pureté par domaine.

### Lot 1 — Résolveur de requête externe Pokédex

Priorité : `must-have`
Statut : `livré`

But :

- transformer une requête utilisateur en intention structurée :
  - mono-espèce ;
  - liste ;
  - plage dex ;
  - génération.

Pourquoi maintenant :

- c'est la base de toute l'UX Pokédex moderne.

Done :

- `bulbasaur`, `1-151`, `gen 1`, `pikachu,eevee,abra` sont reconnus correctement ;
- la sortie est structurée et réutilisable en UI ;
- aucun parsing batch métier dans les widgets.

Livré concrètement :

- modèles de résolution structurés dans `map_editor/application/models` ;
- résolveur pur dans `map_editor/application/services` ;
- provider DI dédié ;
- tests unitaires du résolveur ;
- report de lot déjà présent dans `reports/`.

### Lot 2 — Auto-complétion mono-espèce dans le wizard

Priorité : `must-have`
Statut : `livré`

But :

- remplacer la saisie libre fragile par une sélection assistée explicite.

Pourquoi maintenant :

- c'est le plus petit gain produit immédiatement visible.

Done :

- impossible de prévisualiser/importer sans espèce réellement résolue ;
- suggestions clavier/souris ;
- états loading / error / introuvable propres.

Livré concrètement :

- recherche mono-espèce branchée sur le résolveur du lot 1 ;
- sélection explicite obligatoire ;
- blocage de la preview/import sans suggestion choisie ;
- états UI hors-scope / invalide / aucun résultat ;
- tests UI et non-régression du flow mono-espèce ;
- report de lot déjà présent dans `reports/`.

### Lot 3 — Sélection batch + dry-run batch

Priorité : `must-have`
Statut : `livré`

But :

- exposer le batch de manière lisible avant écriture.

Pourquoi maintenant :

- le batch existe déjà côté métier ; il manque surtout le vrai flow auteur.

Done :

- liste finale ciblée visible ;
- doublons supprimés ;
- dry-run sans écriture ;
- preview stable et lisible même sur gros lot.

Livré concrètement :

- mode batch explicite dans le wizard `API externe` ;
- use case de résolution batch dédié ;
- support liste explicite / plage dex / génération ;
- affichage de la liste finale résolue avant preview ;
- blocage du dry-run si la sélection n'est pas propre ;
- dry-run branché sur le batch applicatif existant avec `dryRun: true` ;
- preview batch dédiée ;
- aucun import batch réel ;
- tests application, wiring, UI batch et non-régression mono ;
- report de lot déjà présent dans `reports/`.

Limites connues à garder visibles :

- la preview batch devient dense sur très gros lots ;
- le wizard reste encore raisonnablement maintenable, mais il faudra surveiller
  sa taille au lot 4 ;
- la preuve de non-écriture batch est forte, mais pas encore exhaustive
  artefact par artefact côté learnset/evolution/media/assets.

### Lot 4 — Exécution batch + progression + rapport

Priorité : `must-have`
Statut : `livré`

But :

- rendre le batch réellement productif.

Done :

- progression ;
- compteurs succès / conflit / skip / erreur ;
- rapport final clair.

Livré concrètement :

- bouton d'exécution batch réelle séparé du dry-run ;
- progression honnête branchée sur les callbacks du batch applicatif ;
- résultat final distinct de la preview dry-run ;
- compteurs visibles pendant et après exécution ;
- refresh du workspace si des écritures réelles ont eu lieu ;
- règle stable de sélection post-batch :
  - première espèce réellement écrite dans l'ordre de la sélection résolue ;
- tests application, wiring, UI et non-régression lot 2 / lot 3 ;
- report de lot présent dans `reports/`.

Non-objectifs explicitement conservés :

- pas de retry ;
- pas de relance partielle ;
- pas d'exécution en arrière-plan ;
- pas de cancellation avancée ;
- pas de refonte du wizard complet.

### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Priorité : `must-have`

But :

- faire passer le learnset editor d'une simple garde minimale à une vraie saisie assistée moves-first.

Pourquoi maintenant :

- le socle moves catalog local existe déjà ;
- il faut maintenant l'utiliser davantage.

Done :

- recherche locale de moves dans le learnset editor ;
- sélection assistée ;
- validation plus lisible ;
- affichage honnête des ids legacy hors catalogue.

### Lot 6 — Service de recherche catalogue progressif

Priorité : `must-have`

But :

- créer le contrat commun réutilisable pour les catalogues locaux.

Important :

- le service doit partir du moves catalog déjà présent ;
- il ne doit pas forcer d'emblée abilities/items/types si ces catalogues ne sont pas encore prêts à être productisés.

Done :

- recherche par id/libellé ;
- contrat stable ;
- réutilisable par Pokédex, trainers et encounters.

### Lot 7 — Trainers : surface minimale vraiment exploitable

Priorité : `must-have`

But :

- permettre à un auteur de créer un trainer complet sans JSON.

Done :

- création/édition/suppression trainer ;
- édition propre de la team ;
- species/moves/items/forms assistés là où c'est disponible ;
- erreurs visibles immédiatement ;
- sauvegarde stable ;
- un auteur peut créer un trainer complet sans JSON.

### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Priorité : `must-have`

But :

- permettre à un auteur de configurer une table wild valide sans texte libre fragile.

Done :

- add/edit/delete/reorder d'entrées ;
- species assistée ;
- validation niveau/poids ;
- lisibilité des probabilités ;
- preview auteur simple si le coût reste faible ;
- un auteur peut configurer une table wild valide sans texte libre fragile.

### Lot 9 — Mappers runtime réels vers `BattleSetup`

Priorité : `must-have`

But :

- supprimer les placeholders métier du handoff combat.

Done :

- player party -> `BattleSetup`
- wild encounter -> `BattleSetup`
- trainer team -> `BattleSetup`
- plus aucune espèce/move hardcodée dans le mapping final.

### Lot 10 — Application du résultat de combat au `GameState`

Priorité : `must-have`

But :

- resynchroniser réellement le runtime après combat.

Done :

- HP post-combat appliqués ;
- issues victory/defeat/runaway mappées ;
- trainer defeated flag cohérent ;
- retour overworld propre.

### Lot 11 — Combat sauvage end-to-end jouable

Priorité : `must-have`

But :

- obtenir la première vraie preuve verticale de boucle Pokémon.

Done :

- déplacement -> rencontre -> combat -> retour overworld ;
- plus aucun placeholder métier visible ;
- tests runtime de non-régression.

### Lot 12 — Seen / caught persistants

Priorité : `must-have`

But :

- préparer la boucle Pokémon persistée sans encore ouvrir un chantier capture trop gros d'un seul bloc.

Done :

- état seen/caught sérialisé ;
- save/load cohérent ;
- runtime capable d'en tirer parti.

### Lot 13 — Capture runtime minimale

Priorité : `must-have`

But :

- ajouter la capture comme premier vrai enrichissement de la boucle sauvage.

Done :

- consommation d'une ball ;
- résolution minimale de capture ;
- mise à jour seen/caught ;
- insertion contrôlée dans l'équipe ou fallback minimal.

### Lot 14 — Combat trainer minimal complet

Priorité : `must-have`

But :

- prouver la seconde grande boucle de jeu.

Done :

- trainer battle réel ;
- victoire/défaite stables ;
- anti-retrigger ;
- reward minimal ;
- flags cohérents.

### Lot 15 — Heal / center / whiteout-lite

Priorité : `must-have`

But :

- fermer la boucle de survie minimale du jeu.

Done :

- soin complet ;
- point de reprise minimal ;
- whiteout-lite ;
- save/load toujours cohérent après ces transitions.

## 9. Lots redécoupés / reformulés

Cette section capture explicitement les corrections de forme appliquées à la roadmap précédente.

### 9.1. Catalogues

Ancienne erreur :

- traiter d'un bloc moves + abilities + items + types + egg groups + growth rates.

Décision recalée :

- **moves d'abord** ;
- ensuite seulement les autres catalogues quand un écran ou un workflow les exige réellement.

### 9.2. Trainers

Ancienne erreur :

- "upgrade panel trainer" restait trop abstrait.

Nouvelle définition :

- **un auteur peut créer un trainer complet sans JSON**
- **la team est éditable proprement**
- **les refs invalides sont visibles immédiatement**

### 9.3. Encounter tables

Ancienne erreur :

- "upgrade encounter tables" restait trop vague.

Nouvelle définition :

- **un auteur peut configurer une table wild valide sans texte libre fragile**
- **les probabilités sont lisibles**
- **les erreurs sont visibles avant runtime**

### 9.4. Capture / seen-caught / save-load

Ancienne erreur :

- tout mélanger dans un seul lot trop gros.

Nouvelle décision :

- d'abord seen/caught persistants ;
- ensuite capture runtime minimale ;
- ensuite seulement les raffinements de party overflow, boxes complètes et UX avancée.

### 9.5. Combat depth

Ancienne erreur :

- compacter trop de profondeur battle dans une seule phase.

Nouvelle décision :

- prouver d'abord la boucle verticale avec un moteur encore simple ;
- approfondir ensuite en plusieurs étages clairement séparés.

## 10. Registre de risques mis à jour

### 10.1. Risques techniques

- `PlayableMapGame` peut continuer à grossir trop vite si l'on ne sort pas assez tôt les mappers et l'outcome applier.
- le contrat entre données locales Pokémon, battle setup et moteur combat peut rester incomplet.
- le moteur `map_battle` peut devenir le nouveau goulet si on lui demande trop tôt toute la profondeur système.

### 10.2. Risques de migration

- toute extension de `GameState` / `PlayerPokemon` a un coût réel de migration ;
- si on ouvre trop vite boxes + progression dex + capture + UI runtime complète, le risque de dette de save augmente fortement.

### 10.3. Risques d'UX auteur

- si les champs texte libres restent trop longtemps dans learnsets/trainers/encounters, la dette de données continuera à s'accumuler ;
- si le batch Pokédex devient trop complexe trop tôt, l'outil peut devenir impressionnant mais peu fiable.

### 10.4. Risques produit

- trop de polish auteur avant preuve de boucle de jeu ;
- faux sentiment de progrès si beaucoup d'UI avancent alors que le handoff runtime -> battle reste placeholder ;
- faux sentiment de profondeur si `map_battle` grossit avant d'avoir prouvé la boucle verticale minimale.

### 10.5. Stratégie de mitigation

- garder le bridge runtime très haut dans l'ordre ;
- imposer des gates de sortie par milestone ;
- découper les lots save/capture/combat plus finement ;
- ne productiser les autres catalogues qu'au moment opportun ;
- préférer des tranches verticales prouvées à des lots "impressionnants" mais partiellement intégrés.

## 11. Ordre réaliste recommandé à partir d'aujourd'hui

L'ordre recommandé est le suivant :

1. Lots 1 à 4
   - rendre le Pokédex auteur vraiment productif
2. Lots 5 à 8
   - supprimer la dette de référence là où elle gêne déjà concrètement
3. Lots 9 à 11
   - supprimer les placeholders runtime -> battle et prouver le combat sauvage réel
4. Lots 12 à 15
   - transformer cette première boucle en mini boucle Pokémon persistée
5. Battle depth par étapes
6. Boucle fangame élargie
7. Tooling riche / UX runtime / docs

## 12. Verdict final

La roadmap initiale était **bonne comme vision**.

La version recalée de ce document est meilleure pour trois raisons :

- elle tient compte de ce qui est déjà acquis dans le repo, notamment la clôture 11A et le socle moves catalog 11B ;
- elle reconnaît plus explicitement que les catalogues locaux et une partie de la validation croisée existent déjà ;
- elle remonte le bridge runtime -> battle à la bonne hauteur de priorité ;
- elle remplace une progression trop "par domaine" par une progression plus **verticale, prouvable et jouable**.

La bonne suite réaliste n'est donc pas :

- de réouvrir 11A ;
- de réinventer la stack Pokémon ;
- de lancer immédiatement toute la profondeur battle ;
- ou de multiplier les catalogues d'un coup.

La bonne suite réaliste est :

1. finaliser un **poste de travail Pokédex productif** ;
2. fiabiliser les **références assistées moves-first** ;
3. rendre **trainers et encounters** vraiment authorables ;
4. supprimer les **placeholders runtime -> battle** ;
5. obtenir une **boucle sauvage réelle** ;
6. ajouter **capture + persistance minimale** ;
7. puis seulement approfondir le combat, la progression, l'économie et le tooling.

```


### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```text
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/services/pokemon_external_query_resolver.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart';
import '../../../application/use_cases/search_external_pokemon_species_use_case.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../infrastructure/external/pokeapi_live_source.dart';
import '../../../infrastructure/external/showdown_snapshot_source.dart';
import '../../../infrastructure/repositories/http_pokemon_external_source_repository.dart';
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

final pokemonExternalHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final pokeApiLiveSourceProvider = Provider<PokeApiLiveSource>((ref) {
  return PokeApiLiveSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final showdownSnapshotSourceProvider = Provider<ShowdownSnapshotSource>((ref) {
  return ShowdownSnapshotSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final pokemonExternalSourceRepositoryProvider =
    Provider<PokemonExternalSourceRepository>((ref) {
  return HttpPokemonExternalSourceRepository(
    pokeApiSource: ref.watch(pokeApiLiveSourceProvider),
    showdownSource: ref.watch(showdownSnapshotSourceProvider),
  );
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

/// Résolveur de requête brute -> intention structurée pour l'import externe.
///
/// Ce provider est volontairement minimal pour le lot 1 :
/// - il expose une logique pure ;
/// - il n'ajoute ni réseau, ni preview, ni import ;
/// - il prépare simplement le wiring propre des lots UI suivants.
final pokemonExternalQueryResolverProvider =
    Provider<PokemonExternalQueryResolver>((ref) {
  return const PokemonExternalQueryResolver();
});

/// Recherche mono-espèce appliquée au wizard Pokédex.
///
/// On garde cette couche très petite :
/// - elle réutilise le résolveur du lot 1 ;
/// - elle réutilise le port externe déjà en place ;
/// - elle ne crée pas de pipeline de recherche parallèle.
final searchExternalPokemonSpeciesUseCaseProvider =
    Provider<SearchExternalPokemonSpeciesUseCase>((ref) {
  return SearchExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    queryResolver: ref.watch(pokemonExternalQueryResolverProvider),
  );
});

final pokedexExternalSpeciesSearcherProvider =
    Provider<PokedexExternalSpeciesSearcher>((ref) {
  final useCase = ref.watch(searchExternalPokemonSpeciesUseCaseProvider);
  return useCase.execute;
});

/// Résolution batch structurée pour le wizard `API externe`.
///
/// On reste sur le même pattern que le lot 2 :
/// - résolveur lot 1 réutilisé ;
/// - snapshot externe déjà branché ;
/// - aucune pile batch concurrente dans l'UI.
final resolveExternalPokemonBatchSelectionUseCaseProvider =
    Provider<ResolveExternalPokemonBatchSelectionUseCase>((ref) {
  return ResolveExternalPokemonBatchSelectionUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    queryResolver: ref.watch(pokemonExternalQueryResolverProvider),
  );
});

final pokedexExternalBatchSelectionResolverProvider =
    Provider<PokedexExternalBatchSelectionResolver>((ref) {
  final useCase =
      ref.watch(resolveExternalPokemonBatchSelectionUseCaseProvider);
  return useCase.execute;
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});

final pokedexListProvider = Provider<PokedexEntryLoader>((ref) {
  return ref.watch(pokedexEntryLoaderProvider);
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final deletePokedexSpeciesUseCaseProvider =
    Provider<DeletePokedexSpeciesUseCase>((ref) {
  return DeletePokedexSpeciesUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDeleterProvider = Provider<PokedexSpeciesDeleter>((ref) {
  final useCase = ref.watch(deletePokedexSpeciesUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final importPokemonSpeciesJsonUseCaseProvider =
    Provider<ImportPokemonSpeciesJsonUseCase>((ref) {
  return ImportPokemonSpeciesJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonLearnsetJsonUseCaseProvider =
    Provider<ImportPokemonLearnsetJsonUseCase>((ref) {
  return ImportPokemonLearnsetJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonEvolutionJsonUseCaseProvider =
    Provider<ImportPokemonEvolutionJsonUseCase>((ref) {
  return ImportPokemonEvolutionJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonMediaJsonUseCaseProvider =
    Provider<ImportPokemonMediaJsonUseCase>((ref) {
  return ImportPokemonMediaJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonJsonBundleUseCaseProvider =
    Provider<ImportPokemonJsonBundleUseCase>((ref) {
  return ImportPokemonJsonBundleUseCase(
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
    speciesImportUseCase: ref.watch(importPokemonSpeciesJsonUseCaseProvider),
    learnsetImportUseCase: ref.watch(importPokemonLearnsetJsonUseCaseProvider),
    evolutionImportUseCase:
        ref.watch(importPokemonEvolutionJsonUseCaseProvider),
    mediaImportUseCase: ref.watch(importPokemonMediaJsonUseCaseProvider),
  );
});

final pokedexImportPreviewerProvider = Provider<PokedexImportPreviewer>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final pokedexImporterProvider = Provider<PokedexImporter>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final importExternalPokemonSpeciesUseCaseProvider =
    Provider<ImportExternalPokemonSpeciesUseCase>((ref) {
  return ImportExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final batchImportExternalPokemonSpeciesUseCaseProvider =
    Provider<BatchImportExternalPokemonSpeciesUseCase>((ref) {
  return BatchImportExternalPokemonSpeciesUseCase(
    ref.watch(importExternalPokemonSpeciesUseCaseProvider),
  );
});

final pokedexExternalBatchPreviewerProvider =
    Provider<PokedexExternalBatchPreviewer>((ref) {
  final useCase = ref.watch(batchImportExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesIds) => useCase.execute(
        workspace,
        speciesIds: speciesIds,
        dryRun: true,
      );
});

final pokedexExternalBatchImporterProvider =
    Provider<PokedexExternalBatchImporter>((ref) {
  final useCase = ref.watch(batchImportExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesIds, {onProgress}) => useCase.execute(
        workspace,
        speciesIds: speciesIds,
        onProgress: onProgress,
      );
});

final pokedexExternalImportPreviewerProvider =
    Provider<PokedexExternalImportPreviewer>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
        dryRun: true,
      );
});

final pokedexExternalImporterProvider =
    Provider<PokedexExternalImporter>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
      );
});

final loadPokemonMovesCatalogUseCaseProvider =
    Provider<LoadPokemonMovesCatalogUseCase>((ref) {
  return LoadPokemonMovesCatalogUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final syncExternalPokemonMovesCatalogUseCaseProvider =
    Provider<SyncExternalPokemonMovesCatalogUseCase>((ref) {
  return SyncExternalPokemonMovesCatalogUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexMovesCatalogLoaderProvider =
    Provider<PokedexMovesCatalogLoader>((ref) {
  final useCase = ref.watch(loadPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final pokedexMovesCatalogPreviewerProvider =
    Provider<PokedexMovesCatalogPreviewer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace, dryRun: true);
});

final pokedexMovesCatalogSyncerProvider =
    Provider<PokedexMovesCatalogSyncer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
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

final updatePokedexSpeciesFormsClassificationUseCaseProvider =
    Provider<UpdatePokedexSpeciesFormsClassificationUseCase>((ref) {
  return UpdatePokedexSpeciesFormsClassificationUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesFormsClassificationSaverProvider =
    Provider<PokedexSpeciesFormsClassificationSaver>((ref) {
  final useCase = ref.watch(
    updatePokedexSpeciesFormsClassificationUseCaseProvider,
  );
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesLearnsetUseCaseProvider =
    Provider<UpdatePokedexSpeciesLearnsetUseCase>((ref) {
  return UpdatePokedexSpeciesLearnsetUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesLearnsetSaverProvider =
    Provider<PokedexSpeciesLearnsetSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesLearnsetUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesEvolutionUseCaseProvider =
    Provider<UpdatePokedexSpeciesEvolutionUseCase>((ref) {
  return UpdatePokedexSpeciesEvolutionUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesEvolutionSaverProvider =
    Provider<PokedexSpeciesEvolutionSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesEvolutionUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesMediaUseCaseProvider =
    Provider<UpdatePokedexSpeciesMediaUseCase>((ref) {
  return UpdatePokedexSpeciesMediaUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMediaSaverProvider =
    Provider<PokedexSpeciesMediaSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMediaUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

```


### `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

```text
import 'dart:async';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokeapi_pokemon_species_enricher.dart';
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

/// Disponibilité d'un bloc de données avant import.
///
/// Ce modèle sert à la preview applicative :
/// - il reste volontairement lisible pour le wizard ;
/// - il ne confond pas "artefact source trouvé" et "fichier local écrit" ;
/// - il permet de montrer honnêtement les morceaux best-effort.
class PokemonExternalImportPreviewArtifact {
  const PokemonExternalImportPreviewArtifact({
    required this.label,
    required this.isAvailable,
    this.message,
  });

  final String label;
  final bool isAvailable;
  final String? message;
}

/// Preview applicative d'un import externe.
///
/// Cette preview est produite par le `dryRun` du use case existant.
/// On évite ainsi une seconde logique d'aperçu parallèle dans les providers ou
/// dans l'UI.
class PokemonExternalImportPreview {
  const PokemonExternalImportPreview({
    required this.speciesId,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.learnset,
    required this.evolution,
    required this.media,
    required this.cries,
  });

  final String speciesId;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final PokemonExternalImportPreviewArtifact learnset;
  final PokemonExternalImportPreviewArtifact evolution;
  final PokemonExternalImportPreviewArtifact media;
  final PokemonExternalImportPreviewArtifact cries;
}

/// Rapport d'un asset best-effort téléchargé ou tenté.
///
/// Les images et cries n'entrent pas dans la mécanique de conflit bloquante des
/// quatre JSON métier. On les suit donc séparément, avec un résultat plus
/// explicite pour la QA et le report final.
class PokemonExternalAssetDownloadResult {
  const PokemonExternalAssetDownloadResult({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
    required this.wasWritten,
    this.existedBefore = false,
    this.contentType,
    this.message,
  });

  final String label;
  final String relativePath;
  final String sourceUrl;
  final bool wasWritten;
  final bool existedBefore;
  final String? contentType;
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
    required this.preview,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.downloadedAssets = const <PokemonExternalAssetDownloadResult>[],
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final PokemonExternalImportPreview preview;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<PokemonExternalAssetDownloadResult> downloadedAssets;
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
      // En `failOnConflict`, l'orchestration retourne avant toute écriture
      // réelle dès qu'au moins un artefact est en conflit. Le résultat peut
      // donc encore contenir des actions planifiées `create/overwrite` sur les
      // autres artefacts, mais elles ne représentent pas des écritures
      // effectivement appliquées. Sans cette garde, `hasWritesApplied`
      // raconterait une fausse histoire dans les tests, les warnings ou un
      // éventuel reporting opérateur.
      !hasConflicts &&
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

  bool get importedSpecies => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.species,
      );

  bool get importedLearnset => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.learnset,
      );

  bool get importedEvolution => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.evolution,
      );

  bool get importedMedia => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.media,
      );

  int get downloadedAssetCount =>
      downloadedAssets.where((asset) => asset.wasWritten).length;

  bool _hasAppliedArtifact(PokemonExternalImportArtifactKind kind) {
    return artifacts.any(
      (artifact) =>
          artifact.kind == kind &&
          (artifact.action == PokemonExternalImportArtifactAction.create ||
              artifact.action == PokemonExternalImportArtifactAction.overwrite),
    );
  }
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

/// Progression honnête d'un batch externe en cours.
///
/// Ce modèle n'essaie pas de décrire un "pourcentage magique" interne au
/// pipeline. Il expose uniquement ce que le batch sait réellement après chaque
/// espèce terminée :
/// - combien de cibles étaient prévues ;
/// - combien sont déjà terminées ;
/// - les compteurs par statut déjà observés ;
/// - la dernière espèce réellement terminée.
class PokemonExternalBatchImportProgress {
  const PokemonExternalBatchImportProgress({
    required this.totalCount,
    required this.completedCount,
    required this.successfulCount,
    required this.skippedCount,
    required this.conflictCount,
    required this.failedCount,
    required this.lastCompletedSpeciesId,
  });

  factory PokemonExternalBatchImportProgress.fromEntries({
    required int totalCount,
    required List<PokemonExternalBatchImportEntryResult> entries,
    required String lastCompletedSpeciesId,
  }) {
    final completedCount = entries.length;
    final successfulCount =
        entries.where((entry) => entry.isSuccessful && !entry.isSkipped).length;
    final skippedCount = entries.where((entry) => entry.isSkipped).length;
    final conflictCount = entries.where((entry) => entry.isConflict).length;
    final failedCount = entries.where((entry) => entry.isFailed).length;
    return PokemonExternalBatchImportProgress(
      totalCount: totalCount,
      completedCount: completedCount,
      successfulCount: successfulCount,
      skippedCount: skippedCount,
      conflictCount: conflictCount,
      failedCount: failedCount,
      lastCompletedSpeciesId: lastCompletedSpeciesId,
    );
  }

  final int totalCount;
  final int completedCount;
  final int successfulCount;
  final int skippedCount;
  final int conflictCount;
  final int failedCount;
  final String lastCompletedSpeciesId;

  double get completionRatio =>
      totalCount <= 0 ? 0 : completedCount / totalCount;
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
    this.speciesEnricher = const PokeApiPokemonSpeciesEnricher(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonSpeciesEnricher speciesEnricher;
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

    // La stratégie source de la phase 11A est explicite :
    // - `pokemon-species` sert d'abord à résoudre l'identité canonique ;
    // - Showdown complète ensuite le core species structuré ;
    // - `/pokemon` et `evolution-chain` restent best-effort pour le learnset,
    //   les médias et les évolutions locales.
    final pokeApiSpeciesPayload = await externalSourceRepository
        .fetchPokeApiPokemonSpeciesPayload(requestedSpeciesId);
    final canonicalSpeciesId =
        _resolveCanonicalSpeciesIdFromSpeciesPayload(pokeApiSpeciesPayload);
    final fallbackGeneration =
        _readGenerationNumberFromSpeciesPayload(pokeApiSpeciesPayload);
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(canonicalSpeciesId);
    final pokemonPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiPokemonPayload(
        canonicalSpeciesId,
      ),
      warningContext:
          'Learnset and media payload unavailable for "$canonicalSpeciesId"',
    );
    final evolutionPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiEvolutionChainPayload(
        canonicalSpeciesId,
      ),
      warningContext: 'Evolution chain unavailable for "$canonicalSpeciesId"',
    );

    final species = speciesEnricher.enrich(
      species: speciesConverter.convert(
        showdownPayload,
        fallbackGeneration: fallbackGeneration,
      ),
      pokemonSpeciesPayload: pokeApiSpeciesPayload,
      pokemonPayload: pokemonPayloadRead.payload,
    );
    final learnset = await _tryConvertOptional<PokemonLearnsetFile>(
      () => learnsetConverter.convert(
        speciesId: species.id,
        payload: pokemonPayloadRead.payload!,
      ),
      isEnabled: pokemonPayloadRead.payload != null,
      warningContext: 'Learnset conversion skipped for "${species.id}"',
    );
    final evolution = await _tryConvertOptional<PokemonEvolutionFile>(
      () => evolutionConverter.convert(
        speciesId: species.id,
        payload: evolutionPayloadRead.payload!,
      ),
      isEnabled: evolutionPayloadRead.payload != null,
      warningContext: 'Evolution conversion skipped for "${species.id}"',
    );
    // Le stub média reste utile comme plan de destination locale :
    // - il fournit les chemins cibles canoniques ;
    // - il ne doit surtout pas être persisté tel quel ;
    // - il sert uniquement de plan "optimiste" pour résoudre ensuite un
    //   `PokemonMediaFile` final cohérent avec le disque réel.
    final media = mediaStubGenerator.createStub(species);
    final assetCandidates = _resolveAssetCandidates(
      species: species,
      media: media,
      pokemonPayload: pokemonPayloadRead.payload,
    );

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[
      ...pokemonPayloadRead.warnings,
      ...evolutionPayloadRead.warnings,
      ...learnset.warnings,
      ...evolution.warnings,
    ];
    if (species.id != requestedSpeciesId.trim().toLowerCase()) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }
    final result = _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: warnings,
      assetCandidates: assetCandidates,
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

    final mediaPlan = artifactPlans.firstWhere(
      (plan) => plan.kind == PokemonExternalImportArtifactKind.media,
    );

    // On écrit d'abord les artefacts JSON bloquants / best-effort qui ne
    // dépendent pas de la présence effective d'assets binaires.
    for (final plan in artifactPlans) {
      if (plan.kind == PokemonExternalImportArtifactKind.media) {
        continue;
      }
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

    // Mini-fix 11A-2 :
    // si `media.json` est skippé, aucun nouvel asset binaire média ne doit
    // être écrit. Sinon on créerait des fichiers orphelins que ce run ne peut
    // pas référencer honnêtement, puisque le JSON média conservé n'est pas
    // réécrit.
    //
    // On garde volontairement cette garde ici, au point où l'on connaît à la
    // fois :
    // - la décision de merge sur l'artefact `media.json` ;
    // - la liste des assets candidats à télécharger.
    //
    // Non-objectif explicite :
    // - on ne corrige pas rétroactivement un vieux `media.json` existant ;
    // - on évite seulement d'ajouter du nouveau bruit disque quand le JSON
    //   média reste inchangé.
    final assetBatch =
        mediaPlan.action == PokemonExternalImportArtifactAction.skip
            ? _buildSkippedMediaAssetBatch(
                species: species,
                candidates: assetCandidates,
              )
            : await _downloadBestEffortAssets(
                workspace,
                mergePolicy: mergePolicy,
                candidates: assetCandidates,
              );

    // Mini-fix post-review 11A :
    // le `media.json` final ne doit jamais refléter le plan optimiste des
    // assets, mais uniquement les fichiers garantis présents à la fin :
    // - déjà présents localement et conservés ;
    // - déjà présents localement et toujours là après overwrite raté ;
    // - téléchargés puis écrits avec succès.
    //
    // Toute référence absente sur disque est effacée avant la sérialisation.
    try {
      final resolvedMedia = await _resolvePersistedMediaFromDisk(
        workspace,
        media,
      );

      if (mediaPlan.action == PokemonExternalImportArtifactAction.create ||
          mediaPlan.action == PokemonExternalImportArtifactAction.overwrite) {
        await writeRepository.saveMedia(workspace, resolvedMedia);
      }
    } on Object catch (error, stackTrace) {
      // Audit de clôture 11A :
      // si la phase finale de persistance média casse, on ne veut pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun `media.json`.
      //
      // On nettoie donc uniquement les fichiers :
      // - écrits dans ce run (`wasWritten`) ;
      // - inexistants avant le run (`!existedBefore`).
      //
      // Non-objectifs assumés de ce mini-fix :
      // - on ne tente pas de rollback les JSON déjà écrits plus tôt ;
      // - on ne restaure pas le contenu d'un asset préexistant écrasé avec
      //   succès, car ce cas ne crée pas de ref fantôme ni d'asset orphelin ;
      // - on ne crée pas de transaction globale artificielle pour la 11A.
      await _cleanupNewMediaAssetsAfterPersistenceFailure(
        workspace,
        assetBatch.results,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    return _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: false,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: <String>[
        ...warnings,
        ...assetBatch.warnings,
      ],
      assetCandidates: assetCandidates,
      downloadedAssets: assetBatch.results,
    );
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required _OptionalValue<PokemonLearnsetFile> learnset,
    required _OptionalValue<PokemonEvolutionFile> evolution,
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
      if (learnset.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.learnset,
          relativePath:
              'data/pokemon/learnsets/${learnset.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveLearnset(workspace, learnset.value!),
        ),
      if (evolution.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.evolution,
          relativePath:
              'data/pokemon/evolutions/${evolution.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveEvolution(workspace, evolution.value!),
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

  String _resolveCanonicalSpeciesIdFromSpeciesPayload(
    Map<String, dynamic> payload,
  ) {
    final name = payload['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must expose a non-empty name',
      );
    }
    return name.trim().toLowerCase();
  }

  int? _readGenerationNumberFromSpeciesPayload(Map<String, dynamic> payload) {
    final rawGeneration = payload['generation'];
    if (rawGeneration is! Map) {
      return null;
    }

    final generationName =
        (rawGeneration['name'] as String?)?.trim().toLowerCase();
    return switch (generationName) {
      'generation-i' => 1,
      'generation-ii' => 2,
      'generation-iii' => 3,
      'generation-iv' => 4,
      'generation-v' => 5,
      'generation-vi' => 6,
      'generation-vii' => 7,
      'generation-viii' => 8,
      'generation-ix' => 9,
      _ => null,
    };
  }

  Future<_OptionalPayload<Map<String, dynamic>>> _tryReadOptionalPayload(
    Future<Map<String, dynamic>> Function() action, {
    required String warningContext,
  }) async {
    try {
      return _OptionalPayload<Map<String, dynamic>>(payload: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  Future<_OptionalValue<T>> _tryConvertOptional<T>(
    FutureOr<T> Function() action, {
    required bool isEnabled,
    required String warningContext,
  }) async {
    if (!isEnabled) {
      return _OptionalValue<T>();
    }

    try {
      return _OptionalValue<T>(value: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  PokemonExternalImportResult _buildResult({
    required String requestedSpeciesId,
    required PokemonSpeciesFile species,
    required bool dryRun,
    required PokemonExternalImportMergePolicy mergePolicy,
    required List<_PlannedArtifactWrite> artifactPlans,
    required List<String> warnings,
    required _PokemonExternalAssetCandidateBundle assetCandidates,
    List<PokemonExternalAssetDownloadResult> downloadedAssets =
        const <PokemonExternalAssetDownloadResult>[],
  }) {
    return PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      preview: PokemonExternalImportPreview(
        speciesId: species.id,
        nationalDex: species.nationalDex,
        primaryName: _resolvePrimaryName(species),
        types: _normalizeTypes(species.typing.types),
        learnset: PokemonExternalImportPreviewArtifact(
          label: 'Learnset',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.learnset,
          ),
        ),
        evolution: PokemonExternalImportPreviewArtifact(
          label: 'Évolutions',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.evolution,
          ),
        ),
        media: PokemonExternalImportPreviewArtifact(
          label: 'Médias',
          isAvailable: assetCandidates.hasMediaSource,
        ),
        cries: PokemonExternalImportPreviewArtifact(
          label: 'Cri',
          isAvailable: assetCandidates.hasCrySource,
        ),
      ),
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
      downloadedAssets: downloadedAssets,
      warnings: warnings,
    );
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    final english = species.names['en']?.trim();
    if (english != null && english.isNotEmpty) {
      return english;
    }
    final french = species.names['fr']?.trim();
    if (french != null && french.isNotEmpty) {
      return french;
    }
    for (final value in species.names.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return species.id;
  }

  List<String> _normalizeTypes(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  _PokemonExternalAssetCandidateBundle _resolveAssetCandidates({
    required PokemonSpeciesFile species,
    required PokemonMediaFile media,
    required Map<String, dynamic>? pokemonPayload,
  }) {
    final defaultVariant = media.variants[media.defaultFormId];
    if (defaultVariant == null || pokemonPayload == null) {
      return const _PokemonExternalAssetCandidateBundle();
    }

    final portraitUrl = _readNestedString(
          pokemonPayload,
          const <String>[
            'sprites',
            'other',
            'official-artwork',
            'front_default'
          ],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'other', 'home', 'front_default'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'front_default'],
        );
    final frontUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_default'],
    );
    final backUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_default'],
    );
    final frontShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_shiny'],
    );
    final backShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_shiny'],
    );
    final cryUrl = _readNestedString(
          pokemonPayload,
          const <String>['cries', 'latest'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['cries', 'legacy'],
        );

    return _PokemonExternalAssetCandidateBundle(
      candidates: <_PokemonExternalAssetCandidate>[
        if (defaultVariant.portrait?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Portrait',
            relativePath: defaultVariant.portrait!.trim(),
            sourceUrl: portraitUrl,
          ),
        if (defaultVariant.frontStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite face',
            relativePath: defaultVariant.frontStatic!.trim(),
            sourceUrl: frontUrl,
          ),
        if (defaultVariant.backStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite dos',
            relativePath: defaultVariant.backStatic!.trim(),
            sourceUrl: backUrl,
          ),
        if (defaultVariant.frontShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny face',
            relativePath: defaultVariant.frontShinyStatic!.trim(),
            sourceUrl: frontShinyUrl,
          ),
        if (defaultVariant.backShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny dos',
            relativePath: defaultVariant.backShinyStatic!.trim(),
            sourceUrl: backShinyUrl,
          ),
        if (defaultVariant.cry?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Cri',
            relativePath: defaultVariant.cry!.trim(),
            sourceUrl: cryUrl,
          ),
      ],
      speciesId: species.id,
    );
  }

  Future<_DownloadedAssetBatch> _downloadBestEffortAssets(
    ProjectWorkspace workspace, {
    required PokemonExternalImportMergePolicy mergePolicy,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) async {
    final warnings = <String>[];
    final results = <PokemonExternalAssetDownloadResult>[];

    for (final candidate in candidates.candidates) {
      final absolutePath =
          workspace.resolveProjectRelativePath(candidate.relativePath);
      final existedBefore = await workspace.fileExists(absolutePath);
      final sourceUrl = candidate.sourceUrl?.trim();
      if (sourceUrl == null || sourceUrl.isEmpty) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} has no external source; the existing local asset was kept.'
            : '${candidate.label} has no external source and no local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: '',
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
        continue;
      }
      if (_looksLikeGif(sourceUrl)) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} ignored because GIF assets are explicitly excluded; the existing local asset was kept.'
            : '${candidate.label} ignored because GIF assets are explicitly excluded and no local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
        continue;
      }
      if (existedBefore &&
          mergePolicy != PokemonExternalImportMergePolicy.overwriteExisting) {
        final message =
            '${candidate.label} left untouched because the local asset already exists.';
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: true,
            message: message,
          ),
        );
        warnings.add(message);
        continue;
      }

      try {
        final asset =
            await externalSourceRepository.fetchBinaryAsset(sourceUrl);
        if (asset.bytes.isEmpty) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} download returned no bytes; the existing local asset was kept.'
              : '${candidate.label} download returned no bytes and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (_looksLikeGif(asset.sourceUrl) ||
            _isGifContentType(asset.contentType)) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} ignored because GIF assets are not allowed in local media; the existing local asset was kept.'
              : '${candidate.label} ignored because GIF assets are not allowed in local media and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (!_isCompatibleBinaryAsset(candidate, asset)) {
          final localExistsAfter = await workspace.fileExists(absolutePath);
          final message = localExistsAfter
              ? '${candidate.label} download used a missing or incompatible content-type (${asset.contentType ?? 'unknown'}); the existing local asset was kept.'
              : '${candidate.label} download used a missing or incompatible content-type (${asset.contentType ?? 'unknown'}) and no local asset exists; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }

        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: candidate.relativePath,
          bytes: asset.bytes,
        );
        final existsAfterWrite = await workspace.fileExists(absolutePath);
        if (!existsAfterWrite) {
          final message =
              '${candidate.label} download completed but no local file was found afterwards; the media ref will be omitted.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: true,
            existedBefore: existedBefore,
            contentType: asset.contentType,
          ),
        );
      } on EditorApplicationException catch (error) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} download failed: ${error.message}. The existing local asset was kept.'
            : '${candidate.label} download failed: ${error.message}. No local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      } catch (error) {
        final localExistsAfter = await workspace.fileExists(absolutePath);
        final message = localExistsAfter
            ? '${candidate.label} download failed: $error. The existing local asset was kept.'
            : '${candidate.label} download failed: $error. No local asset exists; the media ref will be omitted.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      }
    }

    return _DownloadedAssetBatch(
      results: results,
      warnings: warnings,
    );
  }

  // Nettoie uniquement les binaires créés par ce run si la persistance finale
  // du `media.json` échoue.
  //
  // Cette garde reste volontairement petite et locale :
  // - elle évite les assets orphelins ;
  // - elle ne change pas la sémantique des autres artefacts ;
  // - elle ne transforme pas le use case en moteur transactionnel global.
  Future<void> _cleanupNewMediaAssetsAfterPersistenceFailure(
    ProjectWorkspace workspace,
    List<PokemonExternalAssetDownloadResult> results,
  ) async {
    for (final result in results) {
      if (!result.wasWritten || result.existedBefore) {
        continue;
      }

      try {
        await workspace.deleteRelativeFile(result.relativePath);
      } catch (_) {
        // Best effort uniquement : on ne masque jamais l'erreur initiale de
        // persistance média avec une erreur secondaire de cleanup.
      }
    }
  }

  _DownloadedAssetBatch _buildSkippedMediaAssetBatch({
    required PokemonSpeciesFile species,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) {
    if (candidates.candidates.isEmpty) {
      return const _DownloadedAssetBatch(
        results: <PokemonExternalAssetDownloadResult>[],
        warnings: <String>[],
      );
    }

    // Ce warning global est volontairement plus utile qu'une pseudo-liste de
    // téléchargements "non tentés" :
    // - il explique pourquoi rien n'a été écrit ;
    // - il rappelle l'invariant anti-assets-orphelins ;
    // - il évite de faire croire que chaque asset a été validé puis refusé.
    final message =
        'Existing media.json for "${species.id}" was kept because merge policy is skip_existing; no new binary media assets were downloaded in this run to avoid orphan files.';
    return _DownloadedAssetBatch(
      results: const <PokemonExternalAssetDownloadResult>[],
      warnings: <String>[message],
    );
  }

  // Construit le `PokemonMediaFile` effectivement persistant à partir du disque.
  //
  // Invariant du mini-fix :
  // - un chemin n'est gardé que si le fichier existe réellement à la fin ;
  // - le stub média ne sert que de plan de destinations potentielles ;
  // - les animations suivent la même règle que les images et le cry, pour
  //   éviter des refs fantômes de sheets.
  Future<PokemonMediaFile> _resolvePersistedMediaFromDisk(
    ProjectWorkspace workspace,
    PokemonMediaFile plannedMedia,
  ) async {
    final resolvedVariants = <String, PokemonMediaVariant>{};

    for (final entry in plannedMedia.variants.entries) {
      resolvedVariants[entry.key] = await _resolvePersistedMediaVariantFromDisk(
        workspace,
        entry.value,
      );
    }

    return PokemonMediaFile(
      speciesId: plannedMedia.speciesId,
      defaultFormId: plannedMedia.defaultFormId,
      variants: resolvedVariants,
    );
  }

  Future<PokemonMediaVariant> _resolvePersistedMediaVariantFromDisk(
    ProjectWorkspace workspace,
    PokemonMediaVariant plannedVariant,
  ) async {
    return PokemonMediaVariant(
      frontStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.frontStatic,
      ),
      backStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.backStatic,
      ),
      frontShinyStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.frontShinyStatic,
      ),
      backShinyStatic: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.backShinyStatic,
      ),
      icon: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.icon,
      ),
      party: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.party,
      ),
      overworld: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.overworld,
      ),
      portrait: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.portrait,
      ),
      cry: await _resolveGuaranteedLocalAssetPath(
        workspace,
        plannedVariant.cry,
      ),
      animations: await _resolvePersistedAnimationsFromDisk(
        workspace,
        plannedVariant.animations,
      ),
    );
  }

  Future<Map<String, PokemonMediaAnimationRef>>
      _resolvePersistedAnimationsFromDisk(
    ProjectWorkspace workspace,
    Map<String, PokemonMediaAnimationRef> animations,
  ) async {
    final resolved = <String, PokemonMediaAnimationRef>{};

    for (final entry in animations.entries) {
      final sheet = await _resolveGuaranteedLocalAssetPath(
        workspace,
        entry.value.sheet,
      );
      if (sheet == null) {
        continue;
      }
      resolved[entry.key] = PokemonMediaAnimationRef(
        sheet: sheet,
        animationId: entry.value.animationId,
      );
    }

    return resolved;
  }

  Future<String?> _resolveGuaranteedLocalAssetPath(
    ProjectWorkspace workspace,
    String? relativePath,
  ) async {
    final trimmed = relativePath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final exists = await workspace.fileExists(
      workspace.resolveProjectRelativePath(trimmed),
    );
    return exists ? trimmed : null;
  }

  String? _readNestedString(
    Map<String, dynamic> payload,
    List<String> path,
  ) {
    Object? current = payload;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    final value = current as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _looksLikeGif(String url) {
    return url.toLowerCase().contains('.gif');
  }

  bool _looksLikePngBytes(List<int> bytes) {
    if (bytes.length < 8) {
      return false;
    }
    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var index = 0; index < pngSignature.length; index++) {
      if (bytes[index] != pngSignature[index]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeOggBytes(List<int> bytes) {
    if (bytes.length < 4) {
      return false;
    }
    return bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53;
  }

  bool _isGifContentType(String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized.contains('image/gif');
  }

  bool _isCompatibleBinaryAsset(
    _PokemonExternalAssetCandidate candidate,
    PokemonExternalBinaryAsset asset,
  ) {
    final normalized = asset.contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      // On n'accepte plus silencieusement un binaire "sans identité".
      // Quand le serveur oublie le `content-type`, on exige au minimum une
      // signature binaire compatible avec le format attendu :
      // - PNG pour les images ;
      // - OGG pour les cries.
      return candidate.label == 'Cri'
          ? _looksLikeOggBytes(asset.bytes)
          : _looksLikePngBytes(asset.bytes);
    }

    if (candidate.label == 'Cri') {
      return normalized.contains('audio/ogg') ||
          normalized.contains('application/ogg');
    }

    return normalized.contains('image/png');
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
    void Function(PokemonExternalBatchImportProgress progress)? onProgress,
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

    final totalCount = normalizedSpeciesIds.length;
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

      onProgress?.call(
        PokemonExternalBatchImportProgress.fromEntries(
          totalCount: totalCount,
          entries: entryResults,
          lastCompletedSpeciesId: speciesId,
        ),
      );
    }

    return PokemonExternalBatchImportResult(
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      entries: entryResults,
    );
  }
}

class _OptionalPayload<T> {
  const _OptionalPayload({
    this.payload,
    this.warnings = const <String>[],
  });

  final T? payload;
  final List<String> warnings;
}

class _OptionalValue<T> {
  const _OptionalValue({
    this.value,
    this.warnings = const <String>[],
  });

  final T? value;
  final List<String> warnings;
}

class _PokemonExternalAssetCandidate {
  const _PokemonExternalAssetCandidate({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
  });

  final String label;
  final String relativePath;
  final String? sourceUrl;
}

class _PokemonExternalAssetCandidateBundle {
  const _PokemonExternalAssetCandidateBundle({
    this.candidates = const <_PokemonExternalAssetCandidate>[],
    this.speciesId,
  });

  final List<_PokemonExternalAssetCandidate> candidates;
  final String? speciesId;

  bool get hasMediaSource => candidates.any(
        (candidate) =>
            candidate.label != 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );

  bool get hasCrySource => candidates.any(
        (candidate) =>
            candidate.label == 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );
}

class _DownloadedAssetBatch {
  const _DownloadedAssetBatch({
    required this.results,
    required this.warnings,
  });

  final List<PokemonExternalAssetDownloadResult> results;
  final List<String> warnings;
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


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

```text
part of 'pokedex_workspace_page.dart';

// Orchestration unique du flow d'import Pokédex.
//
// Cette feuille modale reste volontairement la seule porte d'entrée UI pour
// les imports Pokédex :
// - source locale JSON ;
// - source produit `API externe` ;
// - aperçu avant write ;
// - confirmation finale.
//
// Toute la logique métier reste hors des widgets :
// - l'UI choisit une source et affiche un résumé ;
// - les providers injectés appellent les use cases existants ;
// - aucun parsing JSON ou HTTP ne vit ici.

Future<_CompletedPokedexImportFlowResult?> _showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  required PokedexExternalSpeciesSearcher searchExternalSpecies,
  required PokedexExternalBatchSelectionResolver resolveExternalBatchSelection,
  required PokedexExternalImportPreviewer previewExternalImport,
  required PokedexExternalBatchPreviewer previewExternalBatchImport,
  required PokedexExternalBatchImporter importExternalBatch,
  required PokedexExternalImporter importExternalPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  return showMacosEditorTallSheet<_CompletedPokedexImportFlowResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
      searchExternalSpecies: searchExternalSpecies,
      resolveExternalBatchSelection: resolveExternalBatchSelection,
      previewExternalImport: previewExternalImport,
      previewExternalBatchImport: previewExternalBatchImport,
      importExternalBatch: importExternalBatch,
      importExternalPokemon: importExternalPokemon,
      pickJsonSourceFile: pickJsonSourceFile ?? _pickPokedexJsonSourceFile,
    ),
  );
}

Future<String?> _pickPokedexJsonSourceFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: false,
  );
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) {
    return null;
  }
  await _beginPokedexImportBundleAccessIfNeeded(pickedPath);
  return pickedPath;
}

Future<void> _beginPokedexImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only.
  }
}

Future<void> _endPokedexImportBundleAccessIfNeeded() async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'endImportBundleAccess',
    );
  } catch (_) {
    // Best effort only.
  }
}

enum _PokedexImportSourceKind {
  jsonLocal,
  externalApi,
}

enum _PokedexExternalImportMode {
  singleSpecies,
  batchDryRun,
}

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  externalQuery,
  preview,
  result,
}

class _CompletedPokedexImportFlowResult {
  const _CompletedPokedexImportFlowResult({
    required this.feedbackMessage,
    required this.feedbackIsError,
    this.selectedSpeciesId,
    this.shouldRefreshWorkspace = false,
  });

  final String feedbackMessage;
  final bool feedbackIsError;
  final String? selectedSpeciesId;
  final bool shouldRefreshWorkspace;
}

// Le wizard reste séquentiel et local à la présentation.
//
// On ne crée pas de route dédiée ni de state container global :
// - un petit état d'écran pour la progression du modal ;
// - des callbacks injectés pour les use cases ;
// - une seule source de vérité métier dans les résultats applicatifs.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.searchExternalSpecies,
    required this.resolveExternalBatchSelection,
    required this.previewExternalImport,
    required this.previewExternalBatchImport,
    required this.importExternalBatch,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalSpeciesSearcher searchExternalSpecies;
  final PokedexExternalBatchSelectionResolver resolveExternalBatchSelection;
  final PokedexExternalImportPreviewer previewExternalImport;
  final PokedexExternalBatchPreviewer previewExternalBatchImport;
  final PokedexExternalBatchImporter importExternalBatch;
  final PokedexExternalImporter importExternalPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  _PokedexImportSourceKind _selectedSource = _PokedexImportSourceKind.jsonLocal;
  _PokedexExternalImportMode _externalImportMode =
      _PokedexExternalImportMode.singleSpecies;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _jsonPreview;
  PokemonExternalImportResult? _externalPreview;
  PokemonExternalBatchImportResult? _externalBatchPreview;
  PokemonExternalBatchImportResult? _externalBatchImportResult;
  PokemonExternalBatchImportProgress? _externalBatchImportProgress;
  bool _isBusy = false;
  bool _isSearchingExternalSpecies = false;
  bool _isResolvingExternalBatch = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;
  late final FocusNode _externalQueryFocusNode;
  Timer? _externalQueryDebounceTimer;
  int _externalQuerySearchRequestId = 0;
  PokemonExternalSpeciesSearchResult _externalSpeciesSearchResult =
      const PokemonExternalSpeciesSearchResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalBatchSelectionResult _externalBatchSelectionResult =
      PokemonExternalBatchSelectionResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalSpeciesSuggestion? _selectedExternalSuggestion;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
    _externalQueryFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _externalQueryDebounceTimer?.cancel();
    _externalQueryController.dispose();
    _externalQueryFocusNode.dispose();
    unawaited(_endPokedexImportBundleAccessIfNeeded());
    super.dispose();
  }

  Future<void> _pickJsonSource() async {
    final pickedPath = await widget.pickJsonSourceFile();
    if (!mounted || pickedPath == null) {
      return;
    }
    setState(() {
      _selectedJsonSourcePath = pickedPath;
      _errorMessage = null;
    });
  }

  void _handleExternalModeChanged(_PokedexExternalImportMode mode) {
    if (_externalImportMode == mode) {
      return;
    }

    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _externalImportMode = mode;
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      _errorMessage = null;
      _isSearchingExternalSpecies = false;
      _isResolvingExternalBatch = false;
      if (mode == _PokedexExternalImportMode.singleSpecies) {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: _externalQueryController.text,
          normalizedQuery: _externalQueryController.text.trim(),
        );
      } else {
        _externalSpeciesSearchResult =
            const PokemonExternalSpeciesSearchResult.empty(
          rawQuery: '',
          normalizedQuery: '',
        );
      }
    });

    _handleExternalQueryChanged(_externalQueryController.text);
  }

  void _handleExternalQueryChanged(String rawQuery) {
    _externalQueryDebounceTimer?.cancel();
    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _selectedExternalSuggestion = null;
        _isSearchingExternalSpecies = false;
        _isResolvingExternalBatch = false;
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalPreview = null;
        _externalBatchPreview = null;
        _externalBatchImportResult = null;
        _externalBatchImportProgress = null;
        _errorMessage = null;
      });
      return;
    }

    final requestId = ++_externalQuerySearchRequestId;
    setState(() {
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      _isSearchingExternalSpecies =
          _externalImportMode == _PokedexExternalImportMode.singleSpecies;
      _isResolvingExternalBatch =
          _externalImportMode == _PokedexExternalImportMode.batchDryRun;
      if (_externalImportMode == _PokedexExternalImportMode.singleSpecies) {
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      } else {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      }
      _errorMessage = null;
    });

    final requestedMode = _externalImportMode;

    // Un petit debounce UI suffit ici :
    // - il évite de re-solliciter la résolution à chaque caractère ;
    // - il ne déplace aucune logique métier dans l'UI ;
    // - le vrai contrat reste porté par les use cases injectés.
    _externalQueryDebounceTimer =
        Timer(const Duration(milliseconds: 180), () async {
      if (requestedMode == _PokedexExternalImportMode.singleSpecies) {
        final result = await widget.searchExternalSpecies(rawQuery);
        if (!mounted || requestId != _externalQuerySearchRequestId) {
          return;
        }
        setState(() {
          _isSearchingExternalSpecies = false;
          _externalSpeciesSearchResult = result;
        });
        return;
      }

      final result = await widget.resolveExternalBatchSelection(rawQuery);
      if (!mounted || requestId != _externalQuerySearchRequestId) {
        return;
      }
      setState(() {
        _isResolvingExternalBatch = false;
        _externalBatchSelectionResult = result;
      });
    });
  }

  void _handleExternalSuggestionSelected(
    PokemonExternalSpeciesSuggestion suggestion,
  ) {
    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _selectedExternalSuggestion = suggestion;
      _isSearchingExternalSpecies = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final preview = await widget.previewImport(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _jsonPreview = preview;
            _externalPreview = null;
            _externalBatchImportResult = null;
            _externalBatchImportProgress = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant de prévisualiser.',
                );
              }
              final preview = await widget.previewExternalImport(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalPreview = preview;
                _externalBatchPreview = null;
                _externalBatchImportResult = null;
                _externalBatchImportProgress = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
            case _PokedexExternalImportMode.batchDryRun:
              final selection = _externalBatchSelectionResult;
              if (!selection.canDryRun) {
                throw const EditorValidationException(
                  'Résolvez d’abord une sélection batch valide avant de lancer le dry-run.',
                );
              }
              final preview = await widget.previewExternalBatchImport(
                widget.workspace,
                selection.resolvedSpeciesIds,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalBatchPreview = preview;
                _externalPreview = null;
                _externalBatchImportResult = null;
                _externalBatchImportProgress = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final result = await widget.importPokemon(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(
            _CompletedPokedexImportFlowResult(
              selectedSpeciesId: result.preview.speciesId,
              shouldRefreshWorkspace: true,
              feedbackMessage: _buildSingleImportFeedback(
                primaryName: result.preview.primaryName,
                importedLearnset: result.importedLearnset,
                importedEvolution: result.importedEvolution,
                importedMedia: result.importedMedia,
              ),
              feedbackIsError: false,
            ),
          );
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant d’importer.',
                );
              }
              final result = await widget.importExternalPokemon(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              if (result.hasConflicts) {
                setState(() {
                  _isBusy = false;
                  _externalPreview = result;
                  _errorMessage =
                      'Des fichiers existent déjà pour cette espèce. L’import externe reste volontairement prudent et ne remplace rien dans cette phase.';
                });
                return;
              }
              Navigator.of(context).pop(
                _CompletedPokedexImportFlowResult(
                  selectedSpeciesId: result.preview.speciesId,
                  shouldRefreshWorkspace: true,
                  feedbackMessage: _buildSingleImportFeedback(
                    primaryName: result.preview.primaryName,
                    importedLearnset: result.importedLearnset,
                    importedEvolution: result.importedEvolution,
                    importedMedia: result.importedMedia,
                    downloadedAssetCount: result.downloadedAssetCount,
                  ),
                  feedbackIsError: false,
                ),
              );
              break;
            case _PokedexExternalImportMode.batchDryRun:
              throw const EditorValidationException(
                'Utilisez l’action dédiée du lot 4 pour exécuter le batch réel depuis la prévisualisation batch.',
              );
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _executeExternalBatchImport() async {
    final selection = _externalBatchSelectionResult;
    if (!selection.canDryRun) {
      setState(() {
        _errorMessage =
            'Résolvez d’abord une sélection batch valide avant d’exécuter l’import.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isBusy = true;
      _externalBatchImportResult = null;
      _externalBatchImportProgress = null;
      // Le lot 4 sépare explicitement la preview dry-run du résultat réel :
      // au clic sur "Exécuter", on bascule immédiatement sur l'écran de
      // résultat, puis on y alimente une progression honnête au fil des
      // callbacks applicatifs.
      _step = _PokedexImportWizardStep.result;
    });

    try {
      final result = await widget.importExternalBatch(
        widget.workspace,
        selection.resolvedSpeciesIds,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _externalBatchImportProgress = progress;
          });
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _externalBatchImportResult = result;
        _externalBatchImportProgress ??= PokemonExternalBatchImportProgress(
          totalCount: selection.targets.length,
          completedCount: result.entries.length,
          successfulCount: result.successfulCount,
          skippedCount: result.skippedCount,
          conflictCount: result.conflictCount,
          failedCount: result.failedCount,
          lastCompletedSpeciesId:
              result.entries.isEmpty ? '' : result.entries.last.speciesId,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _externalBatchImportResult = null;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  void _closeBatchResult() {
    final result = _externalBatchImportResult;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }

    final selectedSpeciesId = _selectBatchImportedSpeciesId(
      selection: _externalBatchSelectionResult,
      result: result,
    );
    final importedAnySpecies = selectedSpeciesId != null;
    Navigator.of(context).pop(
      _CompletedPokedexImportFlowResult(
        selectedSpeciesId: selectedSpeciesId,
        shouldRefreshWorkspace: importedAnySpecies,
        feedbackMessage: _buildBatchImportFeedback(result),
        feedbackIsError: !importedAnySpecies && result.failedCount > 0,
      ),
    );
  }

  String? _selectBatchImportedSpeciesId({
    required PokemonExternalBatchSelectionResult selection,
    required PokemonExternalBatchImportResult result,
  }) {
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry in result.entries) entry.speciesId: entry,
    };
    // Règle produit stable retenue pour le refresh du workspace :
    // on choisit la première espèce réellement écrite en respectant l'ordre
    // visible de la sélection batch, pas l'ordre interne du use case.
    for (final target in selection.targets) {
      final entry = entriesBySpeciesId[target.speciesId];
      if (entry?.result?.hasWritesApplied == true) {
        return target.speciesId;
      }
    }
    return null;
  }

  String _buildSingleImportFeedback({
    required String primaryName,
    required bool importedLearnset,
    required bool importedEvolution,
    required bool importedMedia,
    int downloadedAssetCount = 0,
  }) {
    final importedArtifacts = <String>[
      'espèce',
      if (importedLearnset) 'learnset',
      if (importedEvolution) 'évolutions',
      if (importedMedia) 'médias',
    ];
    if (downloadedAssetCount > 0) {
      importedArtifacts.add('$downloadedAssetCount assets');
    }
    return 'Import terminé pour $primaryName · ${importedArtifacts.join(', ')}';
  }

  String _buildBatchImportFeedback(PokemonExternalBatchImportResult result) {
    return 'Batch terminé · ${result.successfulCount} succès, '
        '${result.conflictCount} conflits, ${result.failedCount} erreurs, '
        '${result.skippedCount} skips';
  }

  void _continueFromSource() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  void _goBackFromPreview() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le sheet macOS fournit le cadre général, mais pas de marge interne forte.
    // On ajoute donc ici un padding commun à tout le wizard :
    // - même respiration sur chaque étape ;
    // - aucun besoin de répéter des `Padding` différents dans chaque widget ;
    // - correction purement visuelle, sans toucher à la logique du flow.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: switch (_step) {
        _PokedexImportWizardStep.source => _PokedexImportSourceStep(
            selectedSource: _selectedSource,
            onSourceSelected: (value) {
              setState(() {
                _selectedSource = value;
                _errorMessage = null;
              });
            },
            onContinue: _continueFromSource,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.jsonFile => _PokedexImportJsonFileStep(
            selectedJsonSourcePath: _selectedJsonSourcePath,
            isBusy: _isBusy,
            errorMessage: _errorMessage,
            onPickJsonSource: _pickJsonSource,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.externalQuery =>
          _PokedexImportExternalQueryStep(
            externalImportMode: _externalImportMode,
            controller: _externalQueryController,
            focusNode: _externalQueryFocusNode,
            isBusy: _isBusy,
            isSearching: _isSearchingExternalSpecies,
            isResolvingBatch: _isResolvingExternalBatch,
            errorMessage: _errorMessage,
            searchResult: _externalSpeciesSearchResult,
            batchSelectionResult: _externalBatchSelectionResult,
            selectedSuggestion: _selectedExternalSuggestion,
            onModeChanged: _handleExternalModeChanged,
            onQueryChanged: _handleExternalQueryChanged,
            onSuggestionSelected: _handleExternalSuggestionSelected,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.preview => switch (_selectedSource) {
            _PokedexImportSourceKind.jsonLocal => _PokedexImportPreviewStep(
                preview: _jsonPreview!,
                isBusy: _isBusy,
                errorMessage: _errorMessage,
                onBack: _goBackFromPreview,
                onImport: _confirmImport,
              ),
            _PokedexImportSourceKind.externalApi => switch (
                  _externalImportMode) {
                _PokedexExternalImportMode.singleSpecies =>
                  _PokedexExternalImportPreviewStep(
                    preview: _externalPreview!,
                    isBusy: _isBusy,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onImport: _confirmImport,
                  ),
                _PokedexExternalImportMode.batchDryRun =>
                  _PokedexExternalBatchPreviewStep(
                    selection: _externalBatchSelectionResult,
                    preview: _externalBatchPreview!,
                    isBusy: _isBusy,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onImport: _executeExternalBatchImport,
                    onClose: () => Navigator.of(context).pop(),
                  ),
              },
          },
        _PokedexImportWizardStep.result =>
          _PokedexExternalBatchExecutionResultStep(
            selection: _externalBatchSelectionResult,
            progress: _externalBatchImportProgress,
            result: _externalBatchImportResult,
            isBusy: _isBusy,
            errorMessage: _errorMessage,
            onClose: _closeBatchResult,
          ),
      },
    );
  }
}

```


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

```text
part of 'pokedex_workspace_page.dart';

// Étapes visuelles du wizard d'import.
//
// Chaque widget ici reste strictement présentation :
// - aucun accès disque ;
// - aucun accès HTTP ;
// - aucune validation métier ;
// - seulement du wording, de la hiérarchie visuelle et des callbacks.

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.selectedSource,
    required this.onSourceSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexImportSourceKind selectedSource;
  final ValueChanged<_PokedexImportSourceKind> onSourceSelected;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez la source qui vous convient. Le parcours reste volontairement simple : une source, un aperçu honnête, puis un import dans le projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.jsonLocal,
          onPressed: () => onSourceSelected(_PokedexImportSourceKind.jsonLocal),
        ),
        const SizedBox(height: 10),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-external-api-source-card'),
          title: 'API externe',
          icon: CupertinoIcons.cloud_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.externalApi,
          trailingLabel: 'Live',
          onPressed: () =>
              onSourceSelected(_PokedexImportSourceKind.externalApi),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: subtle,
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le fichier espèce à importer. L’aperçu vous montrera ensuite ce qui sera ajouté au projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir un fichier',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportExternalQueryStep extends StatelessWidget {
  const _PokedexImportExternalQueryStep({
    required this.externalImportMode,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.isResolvingBatch,
    required this.errorMessage,
    required this.searchResult,
    required this.batchSelectionResult,
    required this.selectedSuggestion,
    required this.onModeChanged,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexExternalImportMode externalImportMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final bool isResolvingBatch;
  final String? errorMessage;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalBatchSelectionResult batchSelectionResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<_PokedexExternalImportMode> onModeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-external-query-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis API externe',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'La source produit reste “API externe”. Choisissez ensuite explicitement un mode mono-espèce ou batch dry-run selon le besoin.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Mode de requête',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexExternalImportModeSegmentedControl(
          selectedMode: externalImportMode,
          onModeChanged: isBusy ? null : onModeChanged,
        ),
        const SizedBox(height: 20),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Pokémon à importer'
              : 'Sélection batch à prévisualiser',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        if (externalImportMode == _PokedexExternalImportMode.singleSpecies)
          _PokedexExternalSpeciesAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isSearching: isSearching,
            searchResult: searchResult,
            selectedSuggestion: selectedSuggestion,
            onQueryChanged: onQueryChanged,
            onSuggestionSelected: onSuggestionSelected,
          )
        else
          _PokedexExternalBatchSelectionField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isResolving: isResolvingBatch,
            selectionResult: batchSelectionResult,
            onQueryChanged: onQueryChanged,
          ),
        const SizedBox(height: 10),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Les détails techniques PokeAPI / Showdown restent internes au pipeline. La prévisualisation reste bloquée tant qu’une suggestion n’a pas été sélectionnée explicitement.'
              : 'Le dry-run batch reste strictement non destructif dans ce lot. La liste finale résolue doit être lisible avant toute prévisualisation, et aucun import batch réel n’est encore proposé.',
          style: helperStyle,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: Key(
                externalImportMode == _PokedexExternalImportMode.singleSpecies
                    ? 'pokedex-import-external-preview-button'
                    : 'pokedex-import-external-batch-preview-button',
              ),
              controlSize: ControlSize.large,
              onPressed: _resolveContinueState(),
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : Text(
                      externalImportMode ==
                              _PokedexExternalImportMode.singleSpecies
                          ? 'Prévisualiser'
                          : 'Dry-run batch',
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> Function()? _resolveContinueState() {
    if (isBusy) {
      return null;
    }

    return switch (externalImportMode) {
      _PokedexExternalImportMode.singleSpecies =>
        isSearching || selectedSuggestion == null ? null : onContinue,
      _PokedexExternalImportMode.batchDryRun =>
        isResolvingBatch || !batchSelectionResult.canDryRun ? null : onContinue,
    };
  }
}

class _PokedexExternalImportModeSegmentedControl extends StatelessWidget {
  const _PokedexExternalImportModeSegmentedControl({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final _PokedexExternalImportMode selectedMode;
  final ValueChanged<_PokedexExternalImportMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<_PokedexExternalImportMode>(
      key: const Key('pokedex-import-external-mode-segmented-control'),
      groupValue: selectedMode,
      onValueChanged: (value) {
        if (value != null && onModeChanged != null) {
          onModeChanged!(value);
        }
      },
      thumbColor: EditorChrome.accentJade.withValues(alpha: 0.28),
      backgroundColor: EditorChrome.islandFillElevated(context),
      children: const <_PokedexExternalImportMode, Widget>{
        _PokedexExternalImportMode.singleSpecies: Padding(
          key: Key('pokedex-import-external-mode-mono-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Mono-espèce',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        _PokedexExternalImportMode.batchDryRun: Padding(
          key: Key('pokedex-import-external-mode-batch-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Batch dry-run',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      },
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez rapidement l’espèce et les fichiers trouvés avant de lancer l’import.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  label: preview.learnset.label,
                  isFound: preview.learnset.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  label: preview.evolution.label,
                  isFound: preview.evolution.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  label: preview.media.label,
                  isFound: preview.media.isFound,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalImportPreviewStep extends StatelessWidget {
  const _PokedexExternalImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonExternalImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final previewData = preview.preview;

    return Column(
      key: const Key('pokedex-import-external-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez l’espèce, les données trouvées et les warnings avant d’ajouter ce Pokémon au projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: preview.hasConflicts
                  ? EditorChrome.inspectorJoyCoral
                  : EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${previewData.nationalDex.toString().padLeft(3, '0')} ${previewData.primaryName}',
                  key: const Key('pokedex-import-external-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${previewData.types.join(' / ')}',
                  key: const Key('pokedex-import-external-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-learnset-status'),
                  label: previewData.learnset.label,
                  isFound: previewData.learnset.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-evolution-status'),
                  label: previewData.evolution.label,
                  isFound: previewData.evolution.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-media-status'),
                  label: previewData.media.label,
                  isFound: previewData.media.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-cries-status'),
                  label: previewData.cries.label,
                  isFound: previewData.cries.isAvailable,
                ),
                const SizedBox(height: 16),
                Text(
                  preview.hasConflicts
                      ? 'Politique actuelle : bloquer en cas de conflit'
                      : 'Politique actuelle : import local prudent',
                  style: helperStyle,
                ),
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final warning in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $warning',
                        key: Key(
                          'pokedex-import-external-warning-${warning.hashCode}',
                        ),
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-external-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy || preview.hasConflicts ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewStep extends StatelessWidget {
  const _PokedexExternalBatchPreviewStep({
    required this.selection,
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
    required this.onClose,
  });

  final PokemonExternalBatchSelectionResult selection;
  final PokemonExternalBatchImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onImport;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry in preview.entries) entry.speciesId: entry,
    };

    return Column(
      key: const Key('pokedex-import-external-batch-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dry-run batch API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Ce lot reste volontairement non destructif : ce dry-run montre uniquement ce qui serait ciblé et les conflits éventuels, sans rien écrire dans le projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-targets'),
                  label: 'Cibles',
                  value: selection.targets.length.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key('pokedex-import-external-batch-summary-ready'),
                  label: 'Prêtes',
                  value: preview.successfulCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-conflicts'),
                  label: 'Conflits',
                  value: preview.conflictCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key:
                      const Key('pokedex-import-external-batch-summary-failed'),
                  label: 'Erreurs',
                  value: preview.failedCount.toString(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Résultat détaillé du dry-run',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: const Key('pokedex-import-external-batch-preview-list'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EditorChrome.accentJade.withValues(alpha: 0.25),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: selection.targets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final target = selection.targets[index];
                final entry = entriesBySpeciesId[target.speciesId];
                return _PokedexExternalBatchPreviewEntryCard(
                  target: target,
                  entry: entry,
                );
              },
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key(
                  'pokedex-import-external-batch-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key(
                'pokedex-import-external-batch-execute-button',
              ),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: const Text('Exécuter le batch'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key(
                'pokedex-import-external-batch-preview-close-button',
              ),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onClose,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalBatchExecutionResultStep extends StatelessWidget {
  const _PokedexExternalBatchExecutionResultStep({
    required this.selection,
    required this.progress,
    required this.result,
    required this.isBusy,
    required this.errorMessage,
    required this.onClose,
  });

  final PokemonExternalBatchSelectionResult selection;
  final PokemonExternalBatchImportProgress? progress;
  final PokemonExternalBatchImportResult? result;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final currentProgress = progress;
    final totalCount = selection.targets.length;
    final completedCount = currentProgress?.completedCount ?? 0;
    final successfulCount =
        result?.successfulCount ?? currentProgress?.successfulCount ?? 0;
    final skippedCount =
        result?.skippedCount ?? currentProgress?.skippedCount ?? 0;
    final conflictCount =
        result?.conflictCount ?? currentProgress?.conflictCount ?? 0;
    final failedCount =
        result?.failedCount ?? currentProgress?.failedCount ?? 0;
    final completionRatio = totalCount <= 0 ? 0.0 : completedCount / totalCount;
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry
          in result?.entries ?? const <PokemonExternalBatchImportEntryResult>[])
        entry.speciesId: entry,
    };
    // Le lot 4 n'affiche volontairement aucune "fausse" progression :
    // l'état visible dépend uniquement des callbacks réellement remontés par le
    // batch applicatif existant après chaque espèce terminée.

    return Column(
      key: const Key('pokedex-import-external-batch-result-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import batch API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          isBusy
              ? 'Le batch réel est en cours. La progression ci-dessous reflète uniquement les espèces effectivement terminées par le pipeline existant.'
              : 'Le batch réel est terminé. Ce rapport reprend le résultat détaillé renvoyé par le pipeline existant, espèce par espèce.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentJade.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-total',
                      ),
                      label: 'Cibles',
                      value: totalCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-completed',
                      ),
                      label: 'Terminées',
                      value: completedCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-success',
                      ),
                      label: 'Succès',
                      value: successfulCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-skips',
                      ),
                      label: 'Skips',
                      value: skippedCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-conflicts',
                      ),
                      label: 'Conflits',
                      value: conflictCount.toString(),
                    ),
                    _PokedexBatchSummaryMetric(
                      key: const Key(
                        'pokedex-import-external-batch-result-summary-failed',
                      ),
                      label: 'Erreurs',
                      value: failedCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    key: const Key(
                      'pokedex-import-external-batch-result-progress-track',
                    ),
                    height: 8,
                    color: EditorChrome.subtleSeparator(context),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: completionRatio.clamp(0.0, 1.0),
                        child: Container(
                          color: EditorChrome.accentJade,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Progression observée : $completedCount / $totalCount espèces terminées.',
                  key: const Key(
                    'pokedex-import-external-batch-result-progress-label',
                  ),
                  style: helperStyle,
                ),
                if ((currentProgress?.lastCompletedSpeciesId ?? '')
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dernière espèce terminée : ${currentProgress!.lastCompletedSpeciesId}',
                    key: const Key(
                      'pokedex-import-external-batch-result-last-completed',
                    ),
                    style: helperStyle.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isBusy ? 'Résultat en construction' : 'Rapport final',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: const Key('pokedex-import-external-batch-result-list'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EditorChrome.accentJade.withValues(alpha: 0.25),
              ),
            ),
            child: result == null
                ? Center(
                    child: Text(
                      isBusy
                          ? 'L’exécution batch est en cours. Le rapport final apparaîtra ici au fil des espèces terminées.'
                          : 'Aucun rapport final disponible.',
                      style: helperStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: selection.targets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final target = selection.targets[index];
                      final entry = entriesBySpeciesId[target.speciesId];
                      return _PokedexExternalBatchExecutionEntryCard(
                        target: target,
                        entry: entry,
                      );
                    },
                  ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key:
                const Key('pokedex-import-external-batch-result-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key(
                  'pokedex-import-external-batch-result-close-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onClose,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexBatchSummaryMetric extends StatelessWidget {
  const _PokedexBatchSummaryMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewEntryCard extends StatelessWidget {
  const _PokedexExternalBatchPreviewEntryCard({
    required this.target,
    required this.entry,
  });

  final PokemonExternalBatchSelectionTarget target;
  final PokemonExternalBatchImportEntryResult? entry;

  @override
  Widget build(BuildContext context) {
    final batchEntry = entry;
    final isFailed = batchEntry?.isFailed ?? true;
    final isConflict = batchEntry?.isConflict ?? false;
    final isSkipped = batchEntry?.isSkipped ?? false;
    final hasPreview = batchEntry?.result != null;
    final statusLabel = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => 'Erreur dry-run',
      (_, true, _) => 'Conflit détecté',
      (_, _, true) => 'Espèce skippée',
      _ => hasPreview ? 'Aperçu disponible' : 'Aucun aperçu',
    };
    final accent = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => EditorChrome.inspectorJoyCoral,
      (_, true, _) => EditorChrome.accentWarm,
      (_, _, true) => EditorChrome.accentWarm,
      _ => EditorChrome.accentJade,
    };
    final warnings = batchEntry?.result?.warnings ?? const <String>[];

    return Container(
      key: Key(
          'pokedex-import-external-batch-preview-entry-${target.speciesId}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${target.nationalDex.toString().padLeft(4, '0')} ${target.primaryName} · ${target.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Demandé par : ${target.requestedInputs.join(', ')}',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (batchEntry?.result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Prévisualisation disponible : ${batchEntry!.result!.preview.primaryName} · ${batchEntry.result!.preview.speciesId}',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (batchEntry?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              batchEntry!.errorMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PokedexExternalBatchExecutionEntryCard extends StatelessWidget {
  const _PokedexExternalBatchExecutionEntryCard({
    required this.target,
    required this.entry,
  });

  final PokemonExternalBatchSelectionTarget target;
  final PokemonExternalBatchImportEntryResult? entry;

  @override
  Widget build(BuildContext context) {
    final batchEntry = entry;
    final isFailed = batchEntry?.isFailed ?? true;
    final isConflict = batchEntry?.isConflict ?? false;
    final isSkipped = batchEntry?.isSkipped ?? false;
    final hasWritesApplied = batchEntry?.result?.hasWritesApplied ?? false;
    final statusLabel =
        switch ((isFailed, isConflict, isSkipped, hasWritesApplied)) {
      (true, _, _, _) => 'Erreur',
      (_, true, _, _) => 'Conflit',
      (_, _, true, _) => 'Skippée',
      (_, _, _, true) => 'Import réussi',
      _ => 'Sans écriture',
    };
    final accent =
        switch ((isFailed, isConflict, isSkipped, hasWritesApplied)) {
      (true, _, _, _) => EditorChrome.inspectorJoyCoral,
      (_, true, _, _) => EditorChrome.accentWarm,
      (_, _, true, _) => EditorChrome.accentWarm,
      (_, _, _, true) => EditorChrome.accentJade,
      _ => EditorChrome.subtleLabel(context),
    };
    final warnings = batchEntry?.result?.warnings ?? const <String>[];
    final result = batchEntry?.result;

    return Container(
      key: Key(
        'pokedex-import-external-batch-result-entry-${target.speciesId}',
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${target.nationalDex.toString().padLeft(4, '0')} ${target.primaryName} · ${target.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Demandé par : ${target.requestedInputs.join(', ')}',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Résolu en : ${result.preview.primaryName} · ${result.preview.speciesId}',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Artifacts écrits : ${result.artifacts.where((artifact) => artifact.action == PokemonExternalImportArtifactAction.create || artifact.action == PokemonExternalImportArtifactAction.overwrite).length} · Assets téléchargés : ${result.downloadedAssetCount}',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (batchEntry?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              batchEntry!.errorMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

```


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`

```text
part of 'pokedex_workspace_page.dart';

// État principal du workspace.
//
// Cette partie porte seulement l'état d'écran local : recherche, filtres,
// sélection, feedback et chargement de la fiche détail. Elle ne remplace
// aucun provider métier et ne maintient aucun cache parallèle.

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  bool _filtersExpanded = false;
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
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
      _filtersExpanded = false;
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
                projectRootPath: projectRootPath,
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                onImportRequested: () => _openImportFlow(workspace),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                filtersExpanded: _filtersExpanded,
                onToggleFiltersExpanded: _toggleFiltersExpanded,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                feedbackMessage: _feedbackMessage,
                feedbackIsError: _feedbackIsError,
                emptyStateChild: entries.isEmpty
                    ? PokedexWorkspaceImportEmptyState(
                        onImportRequested: () => _openImportFlow(workspace),
                      )
                    : null,
                emptyResultsChild: entries.isNotEmpty && filteredEntries.isEmpty
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
                onDeleteSpecies: _deleteSpecies,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
                onLoadMovesCatalog: _loadMovesCatalog,
                onPreviewMovesCatalogSync: _previewMovesCatalogSync,
                onSyncMovesCatalog: _syncMovesCatalog,
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

  void _toggleFiltersExpanded() {
    setState(() => _filtersExpanded = !_filtersExpanded);
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

  void _showFeedback(String message, {required bool isError}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _openImportFlow(ProjectFileSystem workspace) async {
    final result = await _showPokedexImportFlowSheet(
      context: context,
      workspace: workspace,
      previewImport: widget.importPreviewer,
      importPokemon: widget.importer,
      searchExternalSpecies: widget.externalSpeciesSearcher,
      resolveExternalBatchSelection: widget.externalBatchSelectionResolver,
      previewExternalImport: widget.externalImportPreviewer,
      previewExternalBatchImport: widget.externalBatchPreviewer,
      importExternalBatch: widget.externalBatchImporter,
      importExternalPokemon: widget.externalImporter,
      pickJsonSourceFile: widget.pickJsonImportFile,
    );
    if (!mounted || result == null) {
      return;
    }

    final selectedSpeciesId = result.selectedSpeciesId?.trim();
    if (result.shouldRefreshWorkspace &&
        selectedSpeciesId != null &&
        selectedSpeciesId.isNotEmpty) {
      setState(() {
        _entriesFuture = _buildEntriesFuture();
        _searchQuery = '';
        _filtersExpanded = false;
        _selectedType = _allTypesFilterValue;
        _selectedGeneration = _allGenerationsFilterValue;
        _selectedStatus = _allStatusesFilterValue;
        _selectedSpeciesId = selectedSpeciesId;
        _selectedDetailTabId = _overviewTabId;
        _detailFuture = widget.detailLoader(workspace, selectedSpeciesId);
      });
    }

    _showFeedback(
      result.feedbackMessage,
      isError: result.feedbackIsError,
    );
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
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.metadataSaver(workspace, request),
    );
  }

  Future<void> _saveFormsClassification(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) =>
          widget.formsClassificationSaver(workspace, request),
    );
  }

  Future<void> _saveLearnset(
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.learnsetSaver(workspace, request),
    );
  }

  Future<void> _saveEvolution(
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.evolutionSaver(workspace, request),
    );
  }

  Future<void> _saveMedia(
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.mediaSaver(workspace, request),
    );
  }

  Future<PokemonMovesCatalogView> _loadMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot load the local moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogLoader(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _previewMovesCatalogSync() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot preview the moves catalog sync without a loaded project',
      );
    }

    return widget.movesCatalogPreviewer(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _syncMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot sync the moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogSyncer(ProjectFileSystem(projectRootPath));
  }

  Future<void> _deleteSpecies(PokemonDatabaseIndexEntry entry) async {
    final confirmed = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer cette espèce ?',
      message:
          'Supprimer ${entry.primaryName} effacera l’espèce locale et ses fichiers Pokédex associés (learnset, évolutions, médias référencés). Cette action ne touche pas au runtime ni à project.json.',
      primaryLabel: 'Supprimer',
      secondaryLabel: 'Annuler',
      primaryIsDestructive: true,
      icon: CupertinoIcons.delete_solid,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot delete local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    try {
      final result = await widget.deleteSpecies(workspace, entry.id);
      if (!mounted) {
        return;
      }

      // La suppression doit recharger la liste depuis la même source de vérité
      // disque que le reste du workspace.
      //
      // On ne tente pas d'enlever la ligne "à la main" dans l'état local,
      // parce que cela créerait immédiatement un cache parallèle fragile.
      setState(() {
        _entriesFuture = _buildEntriesFuture();
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
      _showFeedback(
        '${result.primaryName} a été supprimé du Pokédex local.',
        isError: false,
      );
    } on EditorApplicationException catch (error) {
      if (!mounted) {
        return;
      }
      _showFeedback(error.message, isError: true);
    }
  }

  Future<void> _runLocalPokemonSave({
    required String speciesId,
    required Future<void> Function(ProjectFileSystem workspace) saveOperation,
  }) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await saveOperation(workspace);
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
      if (_selectedSpeciesId == speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, speciesId);
      }
    });
  }
}

```


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

```text
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_external_batch_selection.dart';
import '../../../application/models/pokemon_external_species_search_result.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_external_batch_field.dart';
part 'pokedex_external_search_field.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_moves_catalog_section.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';
const MethodChannel _macOsImportFileAccessChannel =
    MethodChannel('map_editor/file_access');

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
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
    this.importPreviewer,
    this.importer,
    this.externalImportPreviewer,
    this.externalImporter,
    this.externalSpeciesSearcher,
    this.externalBatchSelectionResolver,
    this.externalBatchPreviewer,
    this.externalBatchImporter,
    this.pickJsonImportFile,
    this.deleteSpecies,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
    this.movesCatalogLoader,
    this.movesCatalogPreviewer,
    this.movesCatalogSyncer,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final PokedexExternalImportPreviewer? externalImportPreviewer;
  final PokedexExternalImporter? externalImporter;
  final PokedexExternalSpeciesSearcher? externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver? externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer? externalBatchPreviewer;
  final PokedexExternalBatchImporter? externalBatchImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter? deleteSpecies;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;
  final PokedexMovesCatalogLoader? movesCatalogLoader;
  final PokedexMovesCatalogPreviewer? movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer? movesCatalogSyncer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexExternalImportPreviewer resolvedExternalImportPreviewer =
        externalImportPreviewer ??
            ref.watch(pokedexExternalImportPreviewerProvider);
    final PokedexExternalImporter resolvedExternalImporter =
        externalImporter ?? ref.watch(pokedexExternalImporterProvider);
    final PokedexExternalSpeciesSearcher resolvedExternalSpeciesSearcher =
        externalSpeciesSearcher ??
            ref.watch(pokedexExternalSpeciesSearcherProvider);
    final PokedexExternalBatchSelectionResolver
        resolvedExternalBatchSelectionResolver =
        externalBatchSelectionResolver ??
            ref.watch(pokedexExternalBatchSelectionResolverProvider);
    final PokedexExternalBatchPreviewer resolvedExternalBatchPreviewer =
        externalBatchPreviewer ??
            ref.watch(pokedexExternalBatchPreviewerProvider);
    final PokedexExternalBatchImporter resolvedExternalBatchImporter =
        externalBatchImporter ??
            ref.watch(pokedexExternalBatchImporterProvider);
    final PokedexSpeciesDeleter resolvedDeleteSpecies =
        deleteSpecies ?? ref.watch(pokedexSpeciesDeleterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);
    final PokedexMovesCatalogLoader resolvedMovesCatalogLoader =
        movesCatalogLoader ?? ref.watch(pokedexMovesCatalogLoaderProvider);
    final PokedexMovesCatalogPreviewer resolvedMovesCatalogPreviewer =
        movesCatalogPreviewer ??
            ref.watch(pokedexMovesCatalogPreviewerProvider);
    final PokedexMovesCatalogSyncer resolvedMovesCatalogSyncer =
        movesCatalogSyncer ?? ref.watch(pokedexMovesCatalogSyncerProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      externalSpeciesSearcher: resolvedExternalSpeciesSearcher,
      externalBatchSelectionResolver: resolvedExternalBatchSelectionResolver,
      externalBatchPreviewer: resolvedExternalBatchPreviewer,
      externalBatchImporter: resolvedExternalBatchImporter,
      pickJsonImportFile: pickJsonImportFile,
      deleteSpecies: resolvedDeleteSpecies,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
      movesCatalogLoader: resolvedMovesCatalogLoader,
      movesCatalogPreviewer: resolvedMovesCatalogPreviewer,
      movesCatalogSyncer: resolvedMovesCatalogSyncer,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.externalImportPreviewer,
    required this.externalImporter,
    required this.externalSpeciesSearcher,
    required this.externalBatchSelectionResolver,
    required this.externalBatchPreviewer,
    required this.externalBatchImporter,
    required this.pickJsonImportFile,
    required this.deleteSpecies,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
    required this.movesCatalogLoader,
    required this.movesCatalogPreviewer,
    required this.movesCatalogSyncer,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final PokedexExternalSpeciesSearcher externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer externalBatchPreviewer;
  final PokedexExternalBatchImporter externalBatchImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter deleteSpecies;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;
  final PokedexMovesCatalogLoader movesCatalogLoader;
  final PokedexMovesCatalogPreviewer movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer movesCatalogSyncer;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

```


### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```text
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_external_batch_selection.dart';
import '../../application/models/pokemon_external_species_search_result.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../domain/repositories/repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

typedef PokedexSpeciesDetailLoader = Future<PokedexSpeciesDetail> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

typedef PokedexImportPreviewer = Future<PokemonJsonImportPreview> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexImporter = Future<PokemonJsonImportResult> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexExternalImportPreviewer = Future<PokemonExternalImportResult>
    Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalImporter = Future<PokemonExternalImportResult> Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalSpeciesSearcher
    = Future<PokemonExternalSpeciesSearchResult> Function(
  String rawQuery,
);

typedef PokedexExternalBatchSelectionResolver
    = Future<PokemonExternalBatchSelectionResult> Function(
  String rawQuery,
);

typedef PokedexExternalBatchPreviewer = Future<PokemonExternalBatchImportResult>
    Function(
  ProjectWorkspace workspace,
  List<String> speciesIds,
);

typedef PokedexExternalBatchImporter = Future<PokemonExternalBatchImportResult>
    Function(
  ProjectWorkspace workspace,
  List<String> speciesIds, {
  void Function(PokemonExternalBatchImportProgress progress)? onProgress,
});

typedef PokedexMovesCatalogLoader = Future<PokemonMovesCatalogView> Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogPreviewer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogSyncer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

/// Construit un chargeur d'entrées Pokédex à partir de dépendances injectées.
///
/// Ce helper reste volontairement petit :
/// - l'UI ne compose plus directement l'infrastructure ;
/// - la logique produit locale du workspace Pokédex reste centralisée ;
/// - les tests peuvent injecter des dépendances concrètes ou fake sans devoir
///   reconstruire tout le wiring applicatif.
///
/// Important :
/// - la logique "species absent => liste vide" est traitée ici de façon
///   explicite, avant l'appel au service ;
/// - on ne dépend donc plus d'un `contains(...)` sur le message d'une
///   exception ;
/// - le service applicatif d'indexation garde sa responsabilité actuelle ;
/// - ce helper ne fait que l'adapter au besoin UI local.
PokedexEntryLoader createPokedexEntryLoader({
  required ProjectRepository projectRepository,
  required PokemonDatabaseIndex databaseIndex,
}) {
  return (ProjectWorkspace workspace) async {
    final project =
        await projectRepository.loadProject(workspace.projectManifestPath);
    final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

    // On garde volontairement la validation "speciesDir vide" au niveau du
    // service du lot 11. Ici, on ne pré-traite qu'un seul cas produit très
    // précis du lot 13 : un dossier `species/` simplement absent dans un
    // projet encore vide doit rendre un état vide honnête, pas une erreur
    // technique.
    if (speciesDirectoryRelativePath.isNotEmpty) {
      final speciesDirectoryPath = workspace.resolveProjectRelativePath(
        speciesDirectoryRelativePath,
      );
      if (!await Directory(speciesDirectoryPath).exists()) {
        return const <PokemonDatabaseIndexEntry>[];
      }
    }

    return databaseIndex.build(workspace);
  };
}

```


### `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```text
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/ports/pokemon_write_repository.dart';
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
      pokeApiPokemonSpeciesPayloads: <String, Map<String, dynamic>>{
        '1':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        '2': jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
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
      binaryAssets: <String, PokemonExternalBinaryAsset>{
        'https://assets.example.test/bulbasaur/portrait.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front.png',
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back.png',
          bytes: Uint8List.fromList(<int>[9, 10, 11, 12]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front_shiny.png',
          bytes: Uint8List.fromList(<int>[13, 14, 15, 16]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back_shiny.png',
          bytes: Uint8List.fromList(<int>[17, 18, 19, 20]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/cry.ogg':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
          bytes: Uint8List.fromList(<int>[21, 22, 23, 24]),
          contentType: 'audio/ogg',
        ),
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

      final result = await singleUseCase.execute(workspace, speciesId: '1');

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(result.preview.primaryName, 'Bulbasaur');
      expect(result.preview.cries.isAvailable, isTrue);
      expect(result.downloadedAssetCount, 6);
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
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.progression.growthRateId, 'medium_slow');
      expect(species.progression.baseFriendship, 50);
      expect(species.dexContent.color, 'green');
      expect(species.dexContent.flavorText,
          'A strange seed was planted on its back at birth.');
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isTrue,
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
      expect(result.downloadedAssetCount, 0);
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
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
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
        'fail_on_conflict stays atomic even when only one artefact already exists',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // On provoque ici le cas le plus intéressant du point de vue produit :
      // un conflit partiel. Si l'atomicité promise par le use case casse,
      // l'import pourrait écrire learnset/evolution/media alors que l'espèce
      // principale est en conflit, ce qui rendrait le résultat trompeur.
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.species,
            )
            .action,
        PokemonExternalImportArtifactAction.conflict,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
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
      externalSourceRepository.pokeApiPokemonSpeciesPayloads
          .remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon-species payload not found for species "bulbasaur"',
          ),
        ),
      );
    });

    test('continues when optional pokemon payload is unavailable', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.hasConflicts, isFalse);
      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isFalse);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);
      expect(result.preview.learnset.isAvailable, isFalse);
      expect(result.preview.media.isAvailable, isFalse);
      expect(result.preview.cries.isAvailable, isFalse);
      expect(
        result.warnings.join('\n'),
        contains('Learnset and media payload unavailable for "bulbasaur"'),
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
        isFalse,
      );
    });

    test(
        'omits a missing media asset ref from media.json while keeping the rest coherent',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(baseVariant.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('Portrait download failed'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'keeps species learnset and evolution when all media downloads fail and writes no ghost refs',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets.clear();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.downloadedAssetCount, 0);
      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic, isNull);
      expect(baseVariant.backStatic, isNull);
      expect(baseVariant.frontShinyStatic, isNull);
      expect(baseVariant.backShinyStatic, isNull);
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.cry, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(result.warnings.join('\n'), contains('download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing does not download new assets when media.json is already skipped',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // Ce cas verrouille précisément le coin restant du mini-fix 2 :
      // - `media.json` existe déjà, donc l'artefact media doit être `skip` ;
      // - aucun asset local n'existe encore ;
      // - si le pipeline continue malgré tout à télécharger les binaires,
      //   ils deviennent orphelins parce que le `media.json` conservé ne sera
      //   jamais réécrit dans ce run.
      //
      // On prépare donc volontairement un `media.json` minimal qui ne référence
      // aucun asset. Si l'import écrit ensuite des portraits/sprites/cries alors
      // que le JSON média est skippé, le bug est réel et reproductible.
      await writeRepository.saveMedia(
        workspace,
        const PokemonMediaFile(
          speciesId: 'bulbasaur',
          defaultFormId: 'base',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(),
          },
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.media,
            )
            .action,
        PokemonExternalImportArtifactAction.skip,
      );
      expect(result.downloadedAssetCount, 0);
      expect(result.downloadedAssets, isEmpty);
      expect(media.variants['base']?.portrait, isNull);
      expect(media.variants['base']?.frontStatic, isNull);
      expect(media.variants['base']?.backStatic, isNull);
      expect(media.variants['base']?.cry, isNull);
      expect(
        result.warnings.join('\n'),
        contains('media.json'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing keeps a pre-existing local asset ref without re-downloading it',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[200, 201, 202]);

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final portraitResult = result.downloadedAssets.firstWhere(
        (asset) => asset.label == 'Portrait',
      );

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[200, 201, 202]);
      expect(portraitResult.wasWritten, isFalse);
      expect(portraitResult.existedBefore, isTrue);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps an existing local asset ref when redownload fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[77, 88, 99]);
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[77, 88, 99]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible image content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[9, 9, 9, 9]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps a local image when redownload content-type is incompatible',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[17, 18, 19]);
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[17, 18, 19]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible cry content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository
              .binaryAssets['https://assets.example.test/bulbasaur/cry.ogg'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
        bytes: Uint8List.fromList(<int>[4, 4, 4, 4]),
        contentType: 'audio/mpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (audio/mpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('refuses GIF assets without persisting a ghost media ref', () async {
      final beforeProjectJson = await projectFile.readAsString();
      final payload =
          jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>;
      final sprites = payload['sprites'] as Map<String, dynamic>;
      final other = sprites['other'] as Map<String, dynamic>;
      final officialArtwork = other['official-artwork'] as Map<String, dynamic>;
      officialArtwork['front_default'] =
          'https://assets.example.test/bulbasaur/portrait.gif';
      externalSourceRepository.pokeApiPokemonPayloads['bulbasaur'] = payload;

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('GIF assets are explicitly excluded'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('applies the same no-ghost rule to cries', () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/cry.ogg');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(result.warnings.join('\n'), contains('Cri download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('cleans up newly written media assets if media.json persistence fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final useCase = ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalSourceRepository,
        writeRepository: _ThrowingMediaWriteRepository(
          delegate: writeRepository,
        ),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Simulated media write failure'),
          ),
        ),
      );

      // Ce test verrouille un invariant subtil de clôture 11A :
      // si le `media.json` final ne peut pas être écrit, on ne doit pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun JSON local.
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );

      // Le mini-fix ne touche pas à `project.json`. On le reverrouille ici
      // même sur un échec tardif du pipeline.
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects a headerless incompatible image payload without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        // Signature JPEG volontairement incompatible.
        bytes: Uint8List.fromList(
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46],
        ),
        contentType: null,
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('missing or incompatible content-type'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
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

    test('dry-run resolves a batch but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur'],
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.successfulCount, 2);
      expect(
        result.entries.every(
          (entry) =>
              entry.result != null && entry.result!.hasWritesApplied == false,
        ),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0002-ivysaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('reports honest per-species progress during a real batch', () async {
      final progressSnapshots = <PokemonExternalBatchImportProgress>[];

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur'],
        onProgress: progressSnapshots.add,
      );

      expect(result.successfulCount, 2);
      expect(
        progressSnapshots
            .map(
              (progress) => (
                progress.completedCount,
                progress.successfulCount,
                progress.failedCount,
                progress.lastCompletedSpeciesId,
              ),
            )
            .toList(),
        <(int, int, int, String)>[
          (1, 1, 0, 'bulbasaur'),
          (2, 2, 0, 'ivysaur'),
        ],
      );
      expect(
        progressSnapshots.every((progress) => progress.totalCount == 2),
        isTrue,
      );
    });

    test('reports skipped entries when merge policy is skipExisting', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(result.successfulCount, 1);
      expect(result.skippedCount, 1);
      expect(result.conflictCount, 0);
      expect(result.failedCount, 0);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'bulbasaur')
            .isSkipped,
        isTrue,
      );
    });

    test('reports conflicts when merge policy is failOnConflict', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.successfulCount, 1);
      expect(result.skippedCount, 0);
      expect(result.conflictCount, 1);
      expect(result.failedCount, 0);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'bulbasaur')
            .isConflict,
        isTrue,
      );
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
    required this.pokeApiPokemonSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
    required this.binaryAssets,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;
  final Map<String, PokemonExternalBinaryAsset> binaryAssets;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    return showdownSpeciesPayloads.map(
      (key, value) => MapEntry<String, dynamic>(key, _deepCopy(value)),
    );
  }

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
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon-species payload not found for species "$speciesId"',
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

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final asset = binaryAssets[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('External asset not found: $sourceUrl');
    }
    return PokemonExternalBinaryAsset(
      sourceUrl: asset.sourceUrl,
      bytes: Uint8List.fromList(asset.bytes),
      contentType: asset.contentType,
    );
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

/// Repository décorateur volontairement minuscule pour reproduire un échec
/// tardif sur `saveMedia`.
///
/// Ce fake sert uniquement à prouver un invariant de clôture 11A :
/// si l'écriture finale du `media.json` casse, le pipeline ne doit pas laisser
/// d'assets binaires nouvellement créés sans référence locale persistée.
///
/// Non-objectifs explicites :
/// - ne pas changer la sémantique des autres écritures ;
/// - ne pas simuler un filesystem complet ;
/// - ne pas introduire une nouvelle abstraction de prod.
class _ThrowingMediaWriteRepository implements PokemonWriteRepository {
  const _ThrowingMediaWriteRepository({
    required this.delegate,
  });

  final PokemonWriteRepository delegate;

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) {
    return delegate.saveBinaryAsset(
      workspace,
      relativePath: relativePath,
      bytes: bytes,
    );
  }

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) {
    return delegate.saveCatalogByKey(workspace, catalogKey, catalog);
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return delegate.saveEvolution(workspace, evolution);
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return delegate.saveLearnset(workspace, learnset);
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) {
    throw const EditorPersistenceException(
      'Simulated media write failure',
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) {
    return delegate.saveSpecies(workspace, species);
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

const String _bulbasaurPokemonSpeciesPayload = '''
{
  "name": "bulbasaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Bulbasaur"},
    {"language": {"name": "fr"}, "name": "Bulbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "A strange seed was planted on its back at birth."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurPokemonSpeciesPayload = '''
{
  "name": "ivysaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Ivysaur"},
    {"language": {"name": "fr"}, "name": "Herbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "When the bulb on its back grows large, it appears to lose the ability to stand."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
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
  "base_experience": 64,
  "height": 7,
  "weight": 69,
  "sprites": {
    "front_default": "https://assets.example.test/bulbasaur/front.png",
    "back_default": "https://assets.example.test/bulbasaur/back.png",
    "front_shiny": "https://assets.example.test/bulbasaur/front_shiny.png",
    "back_shiny": "https://assets.example.test/bulbasaur/back_shiny.png",
    "other": {
      "official-artwork": {
        "front_default": "https://assets.example.test/bulbasaur/portrait.png"
      }
    }
  },
  "cries": {
    "latest": "https://assets.example.test/bulbasaur/cry.ogg"
  },
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
  "base_experience": 142,
  "height": 10,
  "weight": 130,
  "sprites": {
    "front_default": null,
    "back_default": null,
    "front_shiny": null,
    "back_shiny": null,
    "other": {
      "official-artwork": {
        "front_default": null
      }
    }
  },
  "cries": {
    "latest": null
  },
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


### `packages/map_editor/test/provider_wiring_test.dart`

```text
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/content_studio_providers.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('provider wiring', () {
    test('resolves thematic controllers from a ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(projectRepositoryProvider), isNotNull);
      expect(container.read(terrainPresetResolverProvider), isNotNull);
      expect(container.read(createProjectDialogueUseCaseProvider), isNotNull);
      expect(container.read(pokemonDatabaseIndexProvider), isNotNull);
      expect(container.read(pokeApiLiveSourceProvider), isNotNull);
      expect(container.read(showdownSnapshotSourceProvider), isNotNull);
      expect(
          container.read(pokemonExternalSourceRepositoryProvider), isNotNull);
      expect(container.read(pokemonExternalQueryResolverProvider), isNotNull);
      expect(
        container.read(searchExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalSpeciesSearcherProvider), isNotNull);
      expect(
        container.read(resolveExternalPokemonBatchSelectionUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(pokedexExternalBatchSelectionResolverProvider),
        isNotNull,
      );
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(batchImportExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalBatchPreviewerProvider), isNotNull);
      expect(container.read(pokedexExternalBatchImporterProvider), isNotNull);
      expect(
        container.read(loadPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(syncExternalPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexMovesCatalogLoaderProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogPreviewerProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogSyncerProvider), isNotNull);
      expect(container.read(deletePokedexSpeciesUseCaseProvider), isNotNull);
      expect(container.read(pokedexSpeciesDeleterProvider), isNotNull);
      expect(container.read(pokedexExternalImportPreviewerProvider), isNotNull);
      expect(container.read(pokedexExternalImporterProvider), isNotNull);
      expect(container.read(editorWorkspaceControllerProvider), isNotNull);
      expect(container.read(projectContentControllerProvider), isNotNull);
    });

    test('derives selected narrative summaries from controller + projection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_intro',
              name: 'Global Intro',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'step.professor_intro',
                'step.name': 'Rencontrer le professeur',
              },
            ),
            ScenarioAsset(
              id: 'local_intro',
              name: 'Local Intro',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              declaredOutcomes: <String>['story.started'],
            ),
          ],
        ),
      );

      final narrativeNotifier =
          container.read(narrativeWorkspaceControllerProvider.notifier);
      narrativeNotifier.openGlobalStory(scenarioId: 'global_intro');
      narrativeNotifier.openStep(
        stepId: 'step.professor_intro',
        globalScenarioId: 'global_intro',
      );
      narrativeNotifier.openCutscene(cutsceneScenarioId: 'local_intro');
      narrativeNotifier.selectOutcome('story.started');

      expect(
        container.read(selectedGlobalStorySummaryProvider)?.id,
        'global_intro',
      );
      expect(
        container.read(selectedCutsceneSummaryProvider)?.id,
        'local_intro',
      );
      expect(
        container.read(selectedNarrativeStepSummaryProvider)?.id,
        'step.professor_intro',
      );
      expect(
        container.read(selectedNarrativeOutcomeSummaryProvider)?.id,
        'story.started',
      );
    });
  });
}

```


### `packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart`

```text
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_external_batch_execute_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MacosApp(
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

  Future<void> openBatchPreview(
    WidgetTester tester, {
    required String query,
  }) async {
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-api-source-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-mode-batch-option')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      query,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-preview-button')),
    );
    await tester.pumpAndSettle();
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalBatchSelectionResult> Function(
      String rawQuery,
    ) externalBatchSelectionResolver,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds,
    ) externalBatchPreviewer,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds, {
      void Function(PokemonExternalBatchImportProgress progress)? onProgress,
    }) externalBatchImporter,
    required Future<List<PokemonDatabaseIndexEntry>> Function(
      ProjectWorkspace workspace,
    ) loader,
    required Future<PokedexSpeciesDetail> Function(
      ProjectWorkspace workspace,
      String speciesId,
    ) detailLoader,
  }) {
    return PokedexWorkspace(
      loader: loader,
      detailLoader: detailLoader,
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: (rawQuery) async =>
          const PokemonExternalSpeciesSearchResult.empty(
        rawQuery: '',
        normalizedQuery: '',
      ),
      externalBatchSelectionResolver: externalBatchSelectionResolver,
      externalBatchPreviewer: externalBatchPreviewer,
      externalBatchImporter: externalBatchImporter,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets(
      'keeps dry-run and batch execution separate and shows a final report',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var previewCallCount = 0;
    var importCallCount = 0;
    final executedSpeciesIds = <List<String>>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
        detailLoader: (_, __) async => _buildDetail(
          id: 'pikachu',
          nationalDex: 25,
          primaryName: 'Pikachu',
          types: const <String>['electric'],
        ),
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, speciesIds) async {
          previewCallCount += 1;
          expect(speciesIds, <String>['pikachu', 'bulbasaur']);
          return _sampleBatchDryRunPreview();
        },
        externalBatchImporter: (_, speciesIds, {onProgress}) async {
          importCallCount += 1;
          executedSpeciesIds.add(List<String>.from(speciesIds));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 1,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'pikachu',
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 1,
              skippedCount: 0,
              conflictCount: 1,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );

    expect(previewCallCount, 1);
    expect(importCallCount, 0);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-preview-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pump();

    expect(importCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Progression observée : 1 / 2'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(previewCallCount, 1);
    expect(
      executedSpeciesIds,
      <List<String>>[
        <String>['pikachu', 'bulbasaur'],
      ],
    );
    expect(
      find.textContaining('Progression observée : 2 / 2'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-pikachu'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-result-entry-bulbasaur'),
      ),
      findsOneWidget,
    );
    expect(find.text('Import réussi'), findsOneWidget);
    expect(find.text('Conflit'), findsOneWidget);
  });

  testWidgets(
      'refreshes the workspace and selects the first imported species after a real batch',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    final detailRequests = <String>[];
    var entries = <PokemonDatabaseIndexEntry>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_execute_workspace_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async {
          detailRequests.add(speciesId);
          return importedDetailsById[speciesId]!;
        },
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
        externalBatchImporter: (_, __, {onProgress}) async {
          importedDetailsById['pikachu'] = _buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          );
          importedDetailsById['bulbasaur'] = _buildDetail(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          );
          entries = <PokemonDatabaseIndexEntry>[
            _buildEntry(
              id: 'bulbasaur',
              nationalDex: 1,
              primaryName: 'Bulbasaur',
              types: const <String>['grass', 'poison'],
            ),
            _buildEntry(
              id: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: const <String>['electric'],
            ),
          ];
          onProgress?.call(
            const PokemonExternalBatchImportProgress(
              totalCount: 2,
              completedCount: 2,
              successfulCount: 2,
              skippedCount: 0,
              conflictCount: 0,
              failedCount: 0,
              lastCompletedSpeciesId: 'bulbasaur',
            ),
          );
          return _sampleBatchImportResult(
            orderedEntries: <PokemonExternalBatchImportEntryResult>[
              _successfulBatchEntry(
                speciesId: 'bulbasaur',
                nationalDex: 1,
                primaryName: 'Bulbasaur',
                types: const <String>['grass', 'poison'],
              ),
              _successfulBatchEntry(
                speciesId: 'pikachu',
                nationalDex: 25,
                primaryName: 'Pikachu',
                types: const <String>['electric'],
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openBatchPreview(
      tester,
      query: 'pikachu, 25, bulbasaur',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-execute-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-batch-result-step')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
          const Key('pokedex-import-external-batch-result-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-row-bulbasaur')), findsOneWidget);
    expect(detailRequests, contains('pikachu'));
    expect(
      find.byKey(const Key('pokedex-feedback-banner')),
      findsOneWidget,
    );
    expect(
      find.text('Batch terminé · 2 succès, 0 conflits, 0 erreurs, 0 skips'),
      findsOneWidget,
    );
  });
}

PokemonExternalBatchSelectionResult _resolvedBatchSelection() {
  return PokemonExternalBatchSelectionResult.resolved(
    rawQuery: 'pikachu, 25, bulbasaur',
    normalizedQuery: 'pikachu, 25, bulbasaur',
    resolution: PokemonExternalExplicitListQueryResolution(
      rawQuery: 'pikachu, 25, bulbasaur',
      normalizedQuery: 'pikachu, 25, bulbasaur',
      queries: const <PokemonExternalSingleQuery>[
        PokemonExternalSingleQuery.species(
          rawValue: 'pikachu',
          normalizedValue: 'pikachu',
        ),
        PokemonExternalSingleQuery.nationalDex(
          rawValue: '25',
          nationalDex: 25,
        ),
        PokemonExternalSingleQuery.species(
          rawValue: 'bulbasaur',
          normalizedValue: 'bulbasaur',
        ),
      ],
    ),
    targets: <PokemonExternalBatchSelectionTarget>[
      PokemonExternalBatchSelectionTarget(
        speciesId: 'pikachu',
        primaryName: 'Pikachu',
        nationalDex: 25,
        generation: 1,
        requestedInputs: const <String>['pikachu', '25'],
      ),
      PokemonExternalBatchSelectionTarget(
        speciesId: 'bulbasaur',
        primaryName: 'Bulbasaur',
        nationalDex: 1,
        generation: 1,
        requestedInputs: const <String>['bulbasaur'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchDryRunPreview() {
  return PokemonExternalBatchImportResult(
    dryRun: true,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      _successfulBatchEntry(
        speciesId: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        types: const <String>['electric'],
        dryRun: true,
      ),
      _conflictBatchEntry(
        speciesId: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        types: const <String>['grass', 'poison'],
        dryRun: true,
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchImportResult({
  List<PokemonExternalBatchImportEntryResult>? orderedEntries,
}) {
  return PokemonExternalBatchImportResult(
    dryRun: false,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: orderedEntries ??
        <PokemonExternalBatchImportEntryResult>[
          _successfulBatchEntry(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          ),
          _conflictBatchEntry(
            speciesId: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
          ),
        ],
  );
}

PokemonExternalBatchImportEntryResult _successfulBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: dryRun
              ? PokemonExternalImportArtifactAction.create
              : PokemonExternalImportArtifactAction.create,
          existedBefore: false,
        ),
      ],
      downloadedAssets: dryRun
          ? const <PokemonExternalAssetDownloadResult>[]
          : <PokemonExternalAssetDownloadResult>[
              PokemonExternalAssetDownloadResult(
                label: 'Portrait',
                relativePath: 'assets/pokemon/portraits/$speciesId.png',
                sourceUrl: 'https://assets.example.test/$speciesId.png',
                wasWritten: true,
              ),
            ],
      warnings: const <String>[
        'Import best-effort.',
      ],
    ),
  );
}

PokemonExternalBatchImportEntryResult _conflictBatchEntry({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  bool dryRun = false,
}) {
  return PokemonExternalBatchImportEntryResult(
    speciesId: speciesId,
    result: PokemonExternalImportResult(
      requestedSpeciesId: speciesId,
      importedSpeciesId: speciesId,
      preview: _previewFor(
        speciesId: speciesId,
        nationalDex: nationalDex,
        primaryName: primaryName,
        types: types,
      ),
      dryRun: dryRun,
      mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      artifacts: <PokemonExternalImportArtifactResult>[
        PokemonExternalImportArtifactResult(
          kind: PokemonExternalImportArtifactKind.species,
          relativePath:
              'data/pokemon/species/${nationalDex.toString().padLeft(4, '0')}-$speciesId.json',
          action: PokemonExternalImportArtifactAction.conflict,
          existedBefore: true,
        ),
      ],
    ),
  );
}

PokemonExternalImportPreview _previewFor({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalImportPreview(
    speciesId: speciesId,
    nationalDex: nationalDex,
    primaryName: primaryName,
    types: types,
    learnset: const PokemonExternalImportPreviewArtifact(
      label: 'Learnset',
      isAvailable: true,
    ),
    evolution: const PokemonExternalImportPreviewArtifact(
      label: 'Evolution',
      isAvailable: true,
    ),
    media: const PokemonExternalImportPreviewArtifact(
      label: 'Media',
      isAvailable: true,
    ),
    cries: const PokemonExternalImportPreviewArtifact(
      label: 'Cries',
      isAvailable: true,
    ),
  );
}

PokemonDatabaseIndexEntry _buildEntry({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonDatabaseIndexEntry(
    id: id,
    nationalDex: nationalDex,
    primaryName: primaryName,
    genIntroduced: 1,
    types: types,
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: id,
      evolution: id,
      media: id,
    ),
  );
}

PokedexSpeciesDetail _buildDetail({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: nationalDex,
      names: <String, String>{
        'fr': primaryName,
        'en': primaryName,
      },
      speciesName: const <String, String>{
        'fr': 'Pokémon test',
        'en': 'Test Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: types),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'static'),
      breeding: const PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.5, 'female': 0.5},
        eggGroups: <String>['field'],
        hatchCycles: 20,
      ),
      progression: const PokemonSpeciesProgression(
        growthRateId: 'medium_fast',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: id,
        isBaseForm: true,
        formId: 'base',
        otherForms: const <String>[],
      ),
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'yellow',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: id,
    ),
    evolution: PokemonEvolutionFile(
      speciesId: id,
    ),
    media: PokemonMediaFile(
      speciesId: id,
      defaultFormId: 'base',
      variants: const <String, PokemonMediaVariant>{
        'base': PokemonMediaVariant(),
      },
    ),
  );
}

```

## 14. Note git explicite

Aucun commit git n'a été fait.
Aucun merge, rebase, push, tag, amend, stash ou reset n'a été fait.
