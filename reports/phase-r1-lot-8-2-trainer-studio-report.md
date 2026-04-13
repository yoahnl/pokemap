# Phase R1 — Lot 8-2 — Trainer Studio principal + refonte UX/UI complète du trainer authoring

## 1. Résumé exécutif honnête

Le lot 8-2 est livré.

Le code réel confirmait qu'il n'existait pas encore de vrai workspace principal pour les trainers : la surface détaillée d'édition vivait toujours dans `TrainerLibraryPanel`, y compris quand ce panneau était rendu dans la sidebar. Le corrective pass lot 7 avait amélioré la maintenabilité locale du panel, mais il n'avait pas encore promu le trainer authoring dans l'espace central de travail.

La solution retenue est restée strictement locale et sans stack parallèle :

- ajout d'un mode de workspace central `EditorWorkspaceMode.trainer` ;
- réutilisation du **même** `TrainerLibraryPanel` comme surface canonique ;
- transformation de la version `embedded: true` en launcher / résumé ;
- transformation de la version centrale en vrai `Trainer Studio` à trois zones ;
- amélioration des sélecteurs guidés `species` / `moves` / `items` pour qu'ils parlent d'abord en noms lisibles, avec les IDs bruts conservés comme fallback ;
- adaptation responsive minimale pour éviter que le shell étroit ne fasse déborder le studio.

Je n'ai pas créé de deuxième pipeline CRUD trainer, pas de deuxième source de vérité, pas de nouveau repository / provider / notifier trainer, et je n'ai pas rouvert les lots 5 à 8 au-delà de ce qui était nécessaire pour cette promotion du trainer authoring.

## 2. État initial audité réel

Source de vérité utilisée : le code réel du worktree courant.

Constats confirmés à l'audit :

- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart` existait déjà comme surface riche de trainer authoring, découpée en `part` files voisins ;
- la logique métier trainer persistait via les use cases existants et `EditorNotifier` ;
- les lookups locaux `species`, `moves` et `items` existaient déjà et étaient branchés ;
- il n'existait pas encore de mode de workspace central dédié aux trainers dans `EditorWorkspaceMode` ;
- la sidebar affichait encore la surface d'édition détaillée, ce qui allait à l'encontre du besoin produit d'un vrai studio principal ;
- l'UI trainer restait encore trop orientée “inspecteur/panneau” et pas assez “workspace principal” ;
- le terme produit autour de la recherche locale restait trop technique / vague par endroits.

Constats non confirmés :

- pas besoin de nouveau repository trainer ;
- pas besoin de nouveau notifier trainer ;
- pas besoin de nouveau use case trainer ;
- pas besoin d'un framework générique de formulaires ;
- pas besoin d'une nouvelle plateforme de lookup catalogue ;
- pas besoin de toucher `trainer_use_cases.dart` pour le contrat métier principal ;
- pas besoin de toucher le runtime / battle / save.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés

1. Le trainer authoring détaillé n'avait pas encore de vrai workspace principal.
2. La sidebar restait la surface d'édition complète, ce qui tassait l'UX.
3. Le vocabulaire produit n'était pas assez orienté auteur non technique.
4. Le shell ne savait pas encore afficher un studio trainer central.
5. Une fois le studio central branché, le layout débordait dans le shell quand l'espace horizontal devenait trop étroit.

### Problèmes non confirmés

1. Besoin d'un second pipeline trainer : non.
2. Besoin de dupliquer `TrainerLibraryPanel` : non.
3. Besoin d'un nouveau modèle trainer : non.
4. Besoin d'un nouveau système de lookup global : non.
5. Besoin d'un chantier lot 9 / runtime -> battle : non.

### Churn explicitement rejeté

- refonte complète des use cases trainers ;
- nouvelle architecture de “Trainer Studio framework” ;
- deuxième UI trainer concurrente ;
- suppression des champs bruts ;
- généralisation anticipée des catalogues au-delà de `species` / `moves` / `items` ;
- modification gratuite des surfaces encounters / Pokédex.

## 4. Décisions retenues / rejetées

### Retenues

1. Ajouter un workspace central `trainer` au shell éditeur.
2. Réutiliser `TrainerLibraryPanel` comme unique surface canonique de trainer authoring.
3. Faire de `TrainerLibraryPanel(embedded: true)` un launcher / résumé, et de `TrainerLibraryPanel()` le vrai studio principal.
4. Introduire un layout `Trainer Studio` en trois zones : roster, détail trainer, éditeur guidé Pokémon.
5. Conserver les données persistées existantes (`speciesId`, `moves`, `heldItemId`, `formId`, etc.) et ne changer que la façade auteur.
6. Garder les IDs bruts comme fallback explicite, non comme façade principale.
7. Ajouter un repli responsive local pour le shell étroit, sans nouvelle couche d'UI.
8. Ajouter uniquement les tests utiles pour ce changement de surface.
9. Mettre la roadmap en cohérence avec la livraison réelle du lot 8-2 et le statut de M2.

### Rejetées

1. Créer un deuxième panel trainer spécifique au workspace central.
2. Créer un store/notifier trainer dédié au studio.
3. Introduire un nouveau repository / service trainer purement pour la façade centrale.
4. Cacher complètement les IDs techniques.
5. Ouvrir le lot 9 ou retoucher le runtime / battle.

## 5. Wireframe cible retenu

Wireframe conceptuel effectivement retenu dans le code :

```text
+--------------------------------------------------------------------------------+
| Trainer Studio                                                                 |
| Création et édition des dresseurs du projet                                    |
+--------------------------------------------------------------------------------+
| Roster trainers        | Trainer detail                    | Guided Pokémon    |
| - recherche            | - nom / classe / refs            | editor             |
| - cartes trainers      | - tags / refs optionnelles       | - species search   |
| - aperçu équipe        | - équipe visible                 | - level/gender     |
|                        | - add/edit/delete Pokémon        | - move slots 1..4  |
|                        |                                  | - item / form      |
|                        |                                  | - save / cancel    |
+--------------------------------------------------------------------------------+
```

Principes appliqués :

- la sidebar ne porte plus l'édition détaillée ;
- le roster, le détail et l'éditeur sont visibles ensemble ;
- les noms lisibles passent avant les IDs ;
- les IDs bruts restent disponibles comme fallback honnête ;
- l'espace central respire davantage que l'ancien panneau latéral.

## 6. Conclusions détaillées des reviewers / sous-agents

Les reviewers ont été réutilisés via les threads existants disponibles dans l'environnement, pas via de nouveaux agents créés depuis zéro.

### Reviewer A — architecture / scope

Conclusion : promouvoir les trainers dans un vrai workspace principal est légitime si on réutilise `TrainerLibraryPanel` comme source de vérité unique. Il faut ajouter un mode de workspace, un bouton d'accès, et convertir la sidebar en résumé / launcher. Il ne faut pas toucher au pipeline CRUD trainer.

Retenu : oui.

Rejeté : toute solution avec une deuxième surface trainer concurrente ou un nouveau store.

### Reviewer B — UX / wireframe / design produit

Conclusion : la surface actuelle est encore trop “inspecteur”. Il faut une structure lisible en trois zones : roster, détail trainer, éditeur Pokémon. Les sélecteurs `species` et `moves` doivent parler d'abord en noms lisibles et présenter l'ID en secondaire.

Retenu : oui.

Rejeté : wizard multi-étapes, sélecteurs trop compacts, ou simple agrandissement cosmétique du panneau latéral.

### Reviewer C — data contract / behavior

Conclusion : les contrats persistés existants sont suffisants. Le bon chemin consiste à conserver `trainer_use_cases.dart` comme autorité métier, `EditorNotifier` comme orchestrateur, et la validation inline légère dans l'UI. Les fallbacks `species/moves/items/forms` doivent rester honnêtes.

Retenu : oui.

Rejeté : toute logique métier dupliquée dans les widgets ou tout nouveau contrat de persistance trainer.

### Reviewer D — test matrix / QA

Conclusion : il faut une matrice courte mais solide : tests widget trainer studio, tests de shell/workspace, tests de lookups utiles, et quelques non-régressions croisées.

Retenu : oui.

Rejeté : tests décoratifs de rendu ou explosion artificielle du nombre de tests.

### Reviewer E — contradicteur anti-sur-ingénierie

Conclusion : le lot doit rester local. La bonne solution est de réutiliser le panel trainer existant comme surface canonique, pas d'ajouter un “trainer framework” ou une “catalog platform”.

Retenu : oui.

Rejeté : deuxième arbre de widgets complet, nouvelles couches de services, ou “future-proofing” abstrait.

## 7. Périmètre inclus / exclu

### Inclus

- promotion du trainer authoring dans le workspace central ;
- ajout du mode de workspace trainer dans le shell ;
- transformation de la sidebar trainer en launcher / résumé ;
- nouveau layout principal `Trainer Studio` ;
- wording plus compréhensible des recherches locales ;
- amélioration lisible des sélecteurs `species` / `moves` / `items` ;
- layout responsive local du studio ;
- tests widget / smoke / selectors / toolbar / lookup item ;
- mise à jour honnête de la roadmap.

### Exclu

- lot 9 ;
- runtime / battle / save ;
- nouveau pipeline trainer ;
- nouveau provider / repository / use case trainer ;
- suppression des champs bruts techniques ;
- généralisation globale des catalogues ;
- nouvelle UI encounters ;
- refonte cosmétique des lots 5/6/7.

## 8. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `ROADMAP_FANGAME_RECALEE.md`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_workspace_controller_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`

### Créés

- `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`
- `packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart`
- `reports/phase-r1-lot-8-2-trainer-studio-report.md`

### Supprimés

- aucun.

## 9. Justification fichier par fichier

- `ROADMAP_FANGAME_RECALEE.md` : mise en cohérence honnête du statut du lot 8-2 et de M2.
- `editor_workspace_mode.dart` : ajout du mode `trainer`.
- `editor_workspace_controller.dart` : ajout du contrôleur de sélection du workspace trainer.
- `editor_notifier.dart` : exposition d'une action locale `selectTrainerWorkspace()` ; le pipeline trainer n'est pas réécrit.
- `editor_selectors.dart` : labels/sous-titres du shell pour `Trainer Studio`.
- `editor_canvas_host.dart` : routage du workspace central vers `TrainerLibraryPanel()`.
- `editor_shell_page.dart` : intégration du nouveau mode dans le shell et son chrome.
- `project_explorer_panel.dart` : la section trainer devient un launcher / résumé vers le studio central.
- `trainer_library_panel.dart` : orchestrateur unique, branche `embedded` vs centrale, listeners et handlers locaux.
- `trainer_library_panel_support.dart` : helper de recherche de roster.
- `trainer_library_panel_trainer_widgets.dart` : wording et libellés plus lisibles côté authoring trainer.
- `trainer_library_panel_pokemon_widgets.dart` : façade guidée plus lisible pour `species` / `moves` / `items`, avec IDs en fallback.
- `trainer_library_panel_workspace_widgets.dart` : nouvelle composition du Trainer Studio principal + layout responsive local.
- `top_toolbar.dart` : accès direct au workspace trainer et libellé de toolbar cohérent.
- `editor_selectors_test.dart` : preuve des labels trainer du shell.
- `editor_shell_page_smoke_test.dart` : smoke du shell avec le workspace trainer.
- `editor_workspace_controller_test.dart` : preuve du contrôleur de sélection trainer.
- `top_toolbar_test.dart` : preuve du label trainer côté toolbar.
- `trainer_library_panel_test.dart` : preuve du launcher embedded et de la surface trainer centrale guidée.
- `pokemon_items_catalog_lookup_service_test.dart` : couverture dédiée du lookup items local réutilisé dans le studio.

## 10. Commandes réellement exécutées

Commandes d'audit et lecture :

- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `find . -name AGENTS.md -print`
- `rg -n "encounter|Encounter|Trainer Studio|trainer-library|Show optional" ...`
- `sed -n ...` sur les fichiers trainers, shell, selectors et roadmap

Commandes de validation :

- `/opt/homebrew/bin/dart format lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart test/trainer_library_panel_test.dart`
- `/opt/homebrew/bin/dart format test/editor_shell_page_smoke_test.dart test/trainer_library_panel_test.dart`
- `/opt/homebrew/bin/flutter analyze --no-pub lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/ui/panels/trainer_library_panel.dart lib/src/ui/panels/trainer_library_panel_support.dart lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart test/trainer_library_panel_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/editor_workspace_controller_test.dart test/editor_selectors_test.dart test/top_toolbar_test.dart test/editor_shell_page_smoke_test.dart`
- `/opt/homebrew/bin/flutter test test/trainer_library_panel_test.dart test/editor_shell_page_smoke_test.dart`
- `/opt/homebrew/bin/flutter test test/trainer_library_panel_test.dart test/trainer_use_cases_test.dart test/editor_workspace_controller_test.dart test/editor_selectors_test.dart test/top_toolbar_test.dart test/editor_shell_page_smoke_test.dart test/pokemon_species_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokemon_items_catalog_lookup_service_test.dart test/local_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart`

## 11. Résultats réels

- `dart format` : OK
- `flutter analyze --no-pub` : `No issues found!`
- `flutter test test/trainer_library_panel_test.dart test/editor_shell_page_smoke_test.dart` : `All tests passed!`
- matrice complète `flutter test ...` : `All tests passed!`

## 12. Incidents rencontrés

1. Première relance de tests :
   - import manquant de `Key` dans `editor_shell_page_smoke_test.dart` ;
   - tests trainer encore alignés sur l'ancien libellé `Show optional refs` ;
   - ciblage de scroll devenu faux après passage à l'éditeur central.
   - Correction : ajustement des tests, pas du produit.

2. Deuxième relance de tests :
   - overflow réel du `Trainer Studio` dans le shell étroit ;
   - preuve que le layout trois colonnes était trop rigide.
   - Correction : ajout d'un repli responsive local dans `trainer_library_panel_workspace_widgets.dart`.

3. Dernier test fragile :
   - une assertion lisait le résumé de team sans se remettre dans le bon scroll après save ;
   - le comportement produit était bon, le test était fragile.
   - Correction : test ajusté pour viser le bon scroll de détail.

## 13. État git utile

### `git status --short`

```text
 M ROADMAP_FANGAME_RECALEE.md
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
?? packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart
?? packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart
?? reports/phase-r1-lot-8-2-trainer-studio-report.md
```

### `git diff --stat`

```text
 ROADMAP_FANGAME_RECALEE.md                         |  53 +++
 .../application/editor_workspace_controller.dart   |  16 +-
 .../src/features/editor/state/editor_notifier.dart |  11 +
 .../features/editor/state/editor_selectors.dart    |   6 +-
 .../editor/state/models/editor_workspace_mode.dart |   1 +
 .../lib/src/ui/canvas/editor_canvas_host.dart      |   2 +
 .../map_editor/lib/src/ui/editor_shell_page.dart   |  11 +-
 .../lib/src/ui/panels/project_explorer_panel.dart  |   6 +-
 .../lib/src/ui/panels/trainer_library_panel.dart   | 478 +++++----------------
 .../trainer_library_panel_pokemon_widgets.dart     | 167 ++++---
 .../ui/panels/trainer_library_panel_support.dart   |  22 +
 .../trainer_library_panel_trainer_widgets.dart     |  12 +-
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |   9 +
 .../map_editor/test/editor_selectors_test.dart     |  33 +-
 .../test/editor_shell_page_smoke_test.dart         |  22 +
 .../test/editor_workspace_controller_test.dart     |  13 +
 packages/map_editor/test/top_toolbar_test.dart     |  14 +
 .../test/trainer_library_panel_test.dart           | 124 +++++-
 18 files changed, 544 insertions(+), 456 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart
packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart
reports/phase-r1-lot-8-2-trainer-studio-report.md
```

## 14. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports
- [x] je n'ai pas créé de stack parallèle
- [x] le trainer authoring principal est maintenant dans le workspace central
- [x] la sidebar n'est plus la vraie surface d'édition détaillée
- [x] la liste des trainers est lisible
- [x] l'équipe de chaque trainer est visible proprement
- [x] le choix des Pokémon est guidé et lisible
- [x] le choix des attaques est guidé et lisible
- [x] les IDs bruts ne sont plus la façade principale
- [x] le wording “assistance locale” a été remplacé par quelque chose de compréhensible
- [x] les états dégradés species/moves/items/forms restent honnêtes
- [x] je n'ai touché notifier/use cases que si nécessaire
- [x] j'ai exécuté format
- [x] j'ai exécuté analyze
- [x] j'ai exécuté les tests utiles
- [x] je n'ai fait aucune écriture git interdite
- [x] j'ai créé un report markdown ultra complet
- [x] j'y ai inclus le contenu complet de tous les fichiers texte touchés (section annexe ajoutée plus bas dans ce report)

## 15. Conclusion honnête

Le lot 8-2 est livré honnêtement.

Ce qui a réellement changé : le trainer authoring a été promu dans un vrai workspace principal, sans deuxième pipeline ni deuxième UI concurrente, avec une façade auteur plus lisible et plus guidée. La sidebar trainer a été ramenée à un rôle de launcher / résumé rapide, ce qui aligne mieux l'outil avec sa vocation no-code guidée.

Ce qui n'a pas été fait volontairement :

- pas de lot 9 ;
- pas de runtime -> battle ;
- pas de nouveau pipeline trainer ;
- pas de refonte des use cases ;
- pas de framework générique supplémentaire.

À l'issue de ce diff et des validations exécutées, le lot 8-2 est bien livrable dans son scope.

## 16. Annexe — contenu complet des fichiers texte modifiés / créés / supprimés

Note : cette annexe inclut le contenu complet de tous les fichiers texte touchés par ce lot, **sauf ce report lui-même**, explicitement exclu pour éviter une récursion infinie.


### Fichier: `ROADMAP_FANGAME_RECALEE.md`

```markdown
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

Les sept premiers lots de la phase R1 ont maintenant été livrés dans le
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
- `reports/phase-r1-lot-4-mini-fix-no-write-feedback-report.md`

Mini-fix déjà livré à conserver :

- le feedback final batch est maintenant aligné sur les écritures réelles ;
- un batch avec `0` écriture réelle ne remonte plus comme un succès silencieux ;
- le critère produit global s'aligne sur `hasWritesApplied`, exactement comme le
  refresh du workspace.

#### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Ce lot existe maintenant dans le learnset editor du Pokédex, sans créer de
deuxième éditeur ni de deuxième contrat de learnset.

Ce qui est désormais livré :

- une recherche locale assistée dans le catalogue `moves` par :
  - `id` ;
  - `name` ;
  - alias pertinents quand ils sont présents dans les données déjà chargées ;
- une sélection explicite de move depuis l'éditeur au lieu d'une saisie brute
  systématique d'ids ;
- une assistance concrète pour les sections de learnset existantes :
  - `startingMoves` ;
  - `relearnMoves` ;
  - `levelUp` ;
  - `tm` ;
  - `tutor` ;
  - `egg` ;
  - `event` ;
  - `transfer` ;
- un affichage honnête des ids legacy / inconnus :
  - l'entrée reste visible ;
  - elle n'est pas détruite silencieusement ;
  - elle est signalée comme absente du catalogue local quand c'est le cas ;
- une validation plus lisible autour des moves manquants et des incohérences
  évidentes, sans déplacer le cœur métier dans l'UI.

Décision importante déjà en place :

- le texte brut reste le contrat d'édition réel du learnset ;
- l'assistance moves-first vient au-dessus pour sécuriser et accélérer la
  saisie, mais ne masque pas les données ni ne crée une UI concurrente.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-5-moves-first-learnset-report.md`

#### Lot 6 — Service de recherche catalogue progressif

Ce lot existe maintenant côté `map_editor/application/services` et ne recrée
pas de deuxième système de lookup `moves`.

Ce qui est désormais livré :

- un petit contrat stable de recherche locale en mémoire pour les catalogues ;
- une base concrète réutilisable :
  - `ProgressiveLocalCatalogLookupService<TEntry>` ;
- une convergence du service lot 5 vers ce socle au lieu de dupliquer la
  logique ;
- une implémentation réellement branchée sur `moves` via
  `PokemonMovesCatalogLookupService` ;
- des tests dédiés du contrat progressif et de la non-régression côté moves.

Décisions d'architecture désormais en place :

- pas d'interface "enterprise" supplémentaire ;
- pas de provider décoratif ajouté juste pour la forme ;
- pas de moteur multi-catalogues théorique ;
- un petit socle concret, utilisé tout de suite par `moves`, et crédible pour
  les futurs besoins trainers / encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-6-progressive-catalog-search-report.md`

#### Lot 7 — Trainers : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface trainers existante, sans réécrire le
CRUD trainer déjà présent ni introduire de système parallèle.

Ce qui est désormais livré :

- création / édition / suppression trainer depuis l'UI sans passer par le JSON
  ;
- édition d'une team trainer réellement exploitable ;
- ajout et édition de Pokémon de team avec les champs déjà présents côté métier
  :
  - species ;
  - level ;
  - moves ;
  - held item ;
  - form ;
  - gender ;
  - shiny ;
- assistance locale branchée là où elle existe honnêtement :
  - species via l'index Pokédex local ;
  - moves via le catalogue local `moves` ;
  - items via le catalogue local `items` quand il est disponible ;
  - forms via les données locales de l'espèce sélectionnée ;
- conservation explicite de la saisie brute quand une source locale n'existe
  pas ou n'est pas prête ;
- validation inline plus lisible avant save ;
- sauvegarde stable via les use cases trainers existants.

Micro-vérification lot 6 intégrée dans ce lot :

- le socle `ProgressiveLocalCatalogLookupService<TEntry>` a été conservé tel
  quel ;
- aucun renommage cosmétique n'a été fait ;
- la réutilisation est restée locale et progressive via :
  - `PokemonSpeciesLookupService` ;
  - `PokemonItemsCatalogLookupService` ;
  - `PokemonMovesCatalogLookupService` existant.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-7-trainers-minimal-authoring-report.md`

#### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface `EncounterTablesPanel` déjà présente,
sans créer de deuxième éditeur, de deuxième pipeline encounter ni de nouvelle
stack de persistance.

Ce qui est désormais livré :

- création / édition / suppression de tables de rencontres depuis l'UI ;
- ajout / édition / suppression d'entrées de rencontre depuis la même surface ;
- assistance locale `species` réutilisant l'index Pokédex déjà présent ;
- validation inline lisible sur :
  - `species` ;
  - `minLevel` ;
  - `maxLevel` ;
  - `weight` ;
- distinction honnête entre trois états auteur :
  - espèce résolue localement ;
  - espèce absente du Pokédex local ;
  - vérification impossible parce que les données locales sont indisponibles ;
- conservation de la saisie brute quand la vérification locale n'est pas
  possible ;
- lisibilité réelle des poids avec part relative dérivée de la table courante ;
- fermeture des formulaires uniquement sur succès réel du pipeline existant ;
- sauvegarde stable via les use cases encounter déjà présents.

Décisions explicitement retenues :

- aucun reorder n'a été ajouté :
  - le runtime sélectionne déjà par poids, pas par ordre ;
  - ce n'était donc pas un prérequis honnête pour franchir le seuil auteur M2 ;
- aucun provider/use case/repository encounter parallèle n'a été créé ;
- `EditorNotifier` a seulement été réaligné sur le contrat de succès/échec
  déjà utilisé côté trainers pour garder les formulaires ouverts en cas d'échec
  ;
- le support local reste strictement `species-first` pour les encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-8-encounters-m2-report.md`

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
- la stratégie réaliste est bien **moves-first**, déjà amorcée puis renforcée ;
- le prochain travail doit réutiliser ce socle et son contrat progressif au
  lieu de les réécrire.

### 3.4. Trainers et encounter tables

Le repo contient déjà :

- `ProjectTrainerEntry` et ses variantes associées ;
- des use cases trainers ;
- des use cases encounter tables ;
- un wiring applicatif déjà exposé dans l'éditeur ;
- des panneaux éditeur existants ;
- la résolution de rencontres côté `map_gameplay`.

Conclusion :

- la surface trainers a maintenant franchi le seuil "vraiment exploitable" pour
  un auteur ;
- la surface encounters a maintenant rejoint ce même seuil minimal
  d'exploitabilité ;
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

Le Pokédex existe, et la phase R1 a déjà fortement avancé dans le worktree :

- la résolution de requête externe existe ;
- l'auto-complétion mono-espèce existe ;
- le flow batch existe maintenant jusqu'à l'exécution réelle avec rapport ;
- l'assistance moves-first du learnset editor est réellement branchée ;
- un socle progressif de recherche catalogue locale existe maintenant pour
  préparer la suite sans recréer de deuxième système.

Ce qui manque encore côté Pokédex auteur :

- la maintenance bulk ergonomique plus riche ;
- les outils de revalidation / resync / maintenance globale ;
- l'extension du socle moves-first aux surfaces futures qui en ont réellement
  besoin ;
- le confort auteur sur gros volumes de données.

### 4.2. Catalogues et références assistées

Le catalogue moves n'est plus seulement présent au niveau technique ; il est
maintenant réellement exploité au niveau produit dans le learnset editor, et il
dispose désormais d'un premier contrat progressif de recherche locale.

Ce qui reste encore partiel :

- les trainers bénéficient maintenant d'une première exploitation réelle du
  socle progressif pour species / moves / items ;
- les autres écrans n'en profitent pas encore suffisamment ;
- moves reste la priorité avant toute généralisation plus large ;
- abilities / items / types / egg groups / growth rates sont encore à traiter
  de manière progressive.

### 4.3. Trainers et encounters

Le socle n'est plus au même stade des deux côtés :

- trainers :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut créer un trainer complet sans JSON ;
  - il reste du confort plus tardif, mais le seuil produit du lot 7 est atteint
    ;
- encounters :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut configurer une table wild valide sans JSON manuel fragile ;
  - il reste du confort plus tardif, mais le seuil produit du lot 8 est
    atteint.

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

- maintenance Pokédex bulk plus riche
- extension progressive du socle moves-first aux surfaces suivantes utiles
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

Avancement réel à date :

- lot 5 livré :
  - learnset editor moves-first réellement assisté ;
- lot 6 livré :
  - contrat progressif de recherche catalogue locale branché sur `moves`.
- lot 7 livré :
  - trainers branchés sur ce socle de manière locale et non parallèle pour
    species / moves / items / forms quand ces données sont réellement
    disponibles.

### Phase C — Authoring trainers / encounters convergent

But :

- permettre à un auteur de produire sans JSON manuel des données directement combatables.

Contenu :

- trainer library minimal mais propre ;
- encounter tables minimales mais propres ;
- validation inline ;
- preview auteur simple.

Avancement réel à date :

- lot 7 livré :
  - la partie trainers du milestone est atteinte ;
- lot 8 livré :
  - encounter tables minimales mais propres ;
  - assistance locale `species` branchée sur le Pokédex local ;
  - validation inline lisible sur species / niveaux / poids ;
  - surface suffisante pour authorer une table wild sans texte libre fragile.
- lot 8-2 livré :
  - le trainer authoring détaillé vit maintenant dans un vrai workspace
    principal `Trainer Studio` ;
  - la sidebar trainer n'est plus la surface d'édition complète, mais un
    launcher / résumé rapide ;
  - la liste de trainers, le détail trainer et l'éditeur guidé du Pokémon
    vivent ensemble dans une surface centrale plus lisible ;
  - les sélecteurs `species` / `moves` / `items` parlent d'abord en noms
    lisibles, avec les IDs bruts conservés comme fallback honnête.

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

Statut actuel :

- livré ;
- lot 5 livré :
  - learnsets profitent réellement du catalogue moves local ;
- lot 6 livré :
  - le socle de recherche catalogue locale est maintenant prêt pour être
    réutilisé ;
- lot 7 livré :
  - trainers authorables sans JSON manuel ;
  - édition de team assistée là où les données locales existent ;
- lot 8 livré :
  - encounter tables authorables sans texte libre fragile ;
  - validation inline lisible sur species / niveaux / poids ;
  - poids et parts relatives lisibles pour l'auteur ;
  - états dégradés honnêtes quand le Pokédex local est indisponible.
- lot 8-2 livré :
  - `Trainer Studio` promu dans le workspace central ;
  - roster trainer, détail trainer et édition guidée des Pokémon visibles
    simultanément ;
  - selectors guidés `species` / `moves` / `items` plus lisibles pour un
    auteur non technique ;
  - IDs bruts toujours possibles, mais plus en façade principale.

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

Cette section décrit les **15 lots prioritaires** du plan recalé et leur statut
courant.
Ils sont ordonnés pour maximiser la convergence produit, pas seulement la
pureté par domaine.

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
  sa taille sur les lots suivants ;
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
Statut : `livré`

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

Livré concrètement :

- assistance locale branchée sur le catalogue `moves` déjà présent ;
- ajout assisté pour les sections de learnset existantes ;
- conservation explicite des ids legacy / inconnus ;
- amélioration de la lisibilité de validation sans créer un deuxième éditeur ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 6 — Service de recherche catalogue progressif

Priorité : `must-have`
Statut : `livré`

But :

- créer le contrat commun réutilisable pour les catalogues locaux.

Important :

- le service doit partir du moves catalog déjà présent ;
- il ne doit pas forcer d'emblée abilities/items/types si ces catalogues ne sont pas encore prêts à être productisés.

Done :

- recherche par id/libellé ;
- contrat stable ;
- réutilisable par Pokédex, trainers et encounters.

Livré concrètement :

- petit socle générique en mémoire pour la recherche catalogue locale ;
- convergence de `PokemonMovesCatalogLookupService` sur ce socle ;
- aucun second système concurrent de lookup `moves` ;
- réutilisation immédiate par le travail moves-first déjà livré ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 7 — Trainers : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de créer un trainer complet sans JSON.

Done :

- création/édition/suppression trainer ;
- édition propre de la team ;
- species/moves/items/forms assistés là où c'est disponible ;
- erreurs visibles immédiatement ;
- sauvegarde stable ;
- un auteur peut créer un trainer complet sans JSON.

Livré concrètement :

- surface `TrainerLibraryPanel` enrichie sans second éditeur ;
- refs assistées pour :
  - species ;
  - moves ;
  - items quand le catalogue local existe ;
  - forms via les données locales d'espèce ;
- champs bruts conservés honnêtement quand une aide locale n'existe pas encore
  ;
- validation inline lisible avant save ;
- use cases trainers étendus minimalement pour normaliser tags / moves / champs
  optionnels ;
- `EditorNotifier` mis à jour pour garder les formulaires ouverts seulement en
  cas d'échec et fermer proprement sur succès ;
- tests applicatifs, widget et wiring dédiés ;
- report de lot présent dans `reports/`.

### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de configurer une table wild valide sans texte libre fragile.

Done :

- add/edit/delete d'entrées ;
- species assistée ;
- validation niveau/poids ;
- lisibilité des probabilités ;
- preview auteur simple si le coût reste faible ;
- un auteur peut configurer une table wild valide sans texte libre fragile.

Livré concrètement :

- surface `EncounterTablesPanel` enrichie sans second éditeur ;
- recherche locale `species` par id / nom / numéro Pokédex via l'index local ;
- distinction explicite :
  - résolu localement ;
  - absent du Pokédex local ;
  - vérification impossible ;
- validation inline lisible avant save ;
- fermeture des formulaires uniquement sur succès réel ;
- poids totaux et pourcentages dérivés visibles dans la table ;
- tests applicatifs + widget + non-régressions dédiés ;
- report de lot présent dans `reports/`.

### Lot 8-2 — Trainer Studio principal + refonte UX/UI du trainer authoring

Priorité : `must-have`
Statut : `livré`

But :

- faire du trainer authoring un vrai workspace principal lisible, sans créer
  un second pipeline trainer.

Done :

- trainer studio central ;
- sidebar trainer réduite à un launcher / résumé ;
- liste de trainers lisible ;
- détail trainer visible ;
- édition guidée des Pokémon avec vrais slots de moves ;
- sélecteurs lisibles basés sur les noms avant les IDs ;
- wording produit plus compréhensible ;
- fallbacks honnêtes quand les données locales sont indisponibles.

Livré concrètement :

- surface principale `TrainerLibraryPanel` réutilisée comme `Trainer Studio`
  dans le workspace central, sans seconde UI concurrente ;
- roster trainer à gauche, détail trainer au centre, éditeur guidé du Pokémon
  à droite ;
- sélection `species` via le Pokédex local, avec nom, id, numéro Pokédex et
  types en secondaire ;
- sélection de moves par slots `Move 1..4` avec recherche guidée dans le
  catalogue local des attaques ;
- sélection d'item plus lisible quand le catalogue local existe ;
- champs bruts conservés comme fallback honnête au lieu d'être la façade
  principale ;
- tests widget + smoke shell + non-régressions utiles dédiés ;
- report de lot présent dans `reports/`.

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


### Fichier: `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`

```dart
import '../state/editor_state.dart';

/// Routeur pur des workspaces centraux de l'éditeur.
///
/// Pourquoi cette classe existe :
/// - `EditorNotifier` n'a pas besoin de porter lui-même tous les changements
///   de mode "simples" ;
/// - ces transitions ne lisent ni le disque ni Riverpod ;
/// - cela prépare un notifier plus fin, sans recréer un second store.
///
/// Frontière volontaire :
/// - on ne gère ici que les bascules de workspace triviales ;
/// - `selectTilesetWorkspace` reste dans le notifier, car il valide un id et
///   réinitialise un contexte spécifique tileset.
class EditorWorkspaceController {
  const EditorWorkspaceController();

  EditorState selectMapWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.map);
  }

  EditorState selectPokedexWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.pokedex);
  }

  EditorState selectTrainerWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.trainer);
  }

  EditorState selectGlobalStoryWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.globalStory);
  }

  EditorState selectStepWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.step);
  }

  EditorState selectCutsceneWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.cutscene);
  }

  EditorState selectDialogueWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.dialogue);
  }

  /// Normalise les transitions de workspace :
  /// - on conserve tout l'état métier courant ;
  /// - on bascule seulement la surface centrale active ;
  /// - on efface l'erreur courante pour éviter de laisser un message obsolète
  ///   d'un autre workflow polluer le nouvel espace.
  EditorState _openWorkspace(
    EditorState current,
    EditorWorkspaceMode workspaceMode,
  ) {
    return current
        .copyWithProjectSession(
          current.projectSession.copyWith(workspaceMode: workspaceMode),
        )
        .copyWithDocumentStatus(
          current.documentStatus.copyWith(errorMessage: null),
        );
  }
}

```


### Fichier: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "$name" created successfully',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "${manifest.name}" loaded',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(errorMessage: 'Failed to load project: $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Map "${map.id}" saved',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Map "$id" created successfully',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Map "${map.id}" loaded',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Map renamed to "$newId"',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Map "$mapId" deleted',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'No tileset selected');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    required ElementPresetKind presetKind,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tileset path not found');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(errorMessage: 'No project filesystem available');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'No active map loaded');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'No warp selected');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Layer renamed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename layer: $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Layer deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'All layers removed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Layer shown' : 'Layer hidden',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update layer: $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update layer opacity: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Path preset not found');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create terrain preset: $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Terrain preset not found: $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update terrain preset: $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete terrain preset: $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Path preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create path preset: $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Path preset not found: $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update path preset: $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation triggers updated',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update animation triggers: $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation mode updated',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update animation mode: $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete path preset: $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}

```


### Fichier: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../tools/editor_tool.dart';
import 'editor_notifier.dart';
import 'editor_state.dart';

/// Snapshot léger du shell.
///
/// On évite ainsi de faire rebuild le shell entier sur chaque champ de
/// `EditorState`, tout en gardant un contrat lisible côté UI.
typedef EditorShellSnapshot = ({
  EditorWorkspaceMode workspaceMode,
  String workspaceTitle,
  String workspaceSubtitle,
  bool canUndoMap,
  bool canRedoMap,
  bool isSaving,
  bool canSaveMap,
});

/// Snapshot ciblé pour la toolbar.
///
/// Il contient uniquement les champs réellement lus par `TopToolbar`.
typedef EditorToolbarSnapshot = ({
  ProjectManifest? project,
  String? projectRootPath,
  ProjectSettings settings,
  MapData? activeMap,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  MapLayer? activeLayer,
  EditorToolType activeTool,
  TerrainSelectionMode terrainSelectionMode,
  TerrainType selectedTerrainType,
  MapEntityKind selectedEntityKind,
  CollisionBrushSizeMode collisionBrushSizeMode,
  bool isSaving,
  bool isDirty,
  bool canUndoMap,
  bool canRedoMap,
  String? statusMessage,
});

/// Snapshot ciblé pour le Project Explorer.
typedef EditorProjectExplorerSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? activeMapId,
});

/// Snapshot léger pour les racines des panneaux terrain/path.
typedef EditorTerrainLibrarySnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  List<ProjectTilesetEntry> tilesets,
  TerrainType selectedTerrainType,
  Map<TerrainType, String> selectedTerrainPresetByType,
  String? selectedTerrainPresetId,
  String? selectedPathPresetId,
});

/// Snapshot léger pour la racine du panneau palette tileset.
typedef EditorTilesetPaletteSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  MapData? activeMap,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? projectRootPath,
  String? activeLayerId,
  EditorBrush activeBrush,
  PaletteCategory? paletteCategoryFilter,
  String? selectedTilesetElementGroupId,
  TilesElementsPanelMode tilesElementsPanelMode,
  String? selectedPlacedElementInstanceId,
});

final editorWorkspaceModeProvider = Provider<EditorWorkspaceMode>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));
});

final editorProjectManifestProvider = Provider<ProjectManifest?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.project));
});

final editorProjectRootPathProvider = Provider<String?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
});

final editorSelectedTilesetEntryProvider =
    Provider<ProjectTilesetEntry?>((ref) {
  return ref.watch(
    editorNotifierProvider.select(_resolveSelectedTilesetEntryFromState),
  );
});

final editorActiveLayerProvider = Provider<MapLayer?>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final map = state.activeMap;
      final activeLayerId = state.activeLayerId;
      if (map == null || activeLayerId == null) {
        return null;
      }
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          return layer;
        }
      }
      return null;
    }),
  );
});

final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
  final workspaceMode = ref.watch(editorWorkspaceModeProvider);
  final activeMap = ref.watch(
    editorNotifierProvider.select((s) => s.activeMap),
  );
  final selectedTileset = ref.watch(editorSelectedTilesetEntryProvider);
  final canUndoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canUndoMap),
  );
  final canRedoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canRedoMap),
  );
  final isSaving = ref.watch(
    editorNotifierProvider.select((s) => s.isSaving),
  );

  final workspaceTitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap?.name ?? 'Map Workspace',
    EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    EditorWorkspaceMode.trainer => 'Trainer Studio',
    EditorWorkspaceMode.pokedex => 'Pokédex',
    EditorWorkspaceMode.globalStory => 'Global Story Workspace',
    EditorWorkspaceMode.step => 'Step Studio',
    EditorWorkspaceMode.cutscene => 'Cutscene Studio',
    EditorWorkspaceMode.dialogue => 'Dialogue Studio',
  };

  final workspaceSubtitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap == null
        ? 'Open a map to start building your world.'
        : '${activeMap.size.width} x ${activeMap.size.height} tiles  •  ${activeMap.layers.length} layers',
    EditorWorkspaceMode.tileset => selectedTileset == null
        ? 'Select a tileset to browse and curate your library.'
        : 'Visual library editing for tiles, elements and groups.',
    EditorWorkspaceMode.trainer =>
      'Create trainers, teams and battle-ready rosters without editing raw JSON.',
    EditorWorkspaceMode.pokedex =>
      'Simple species list from local project data: number, name, id and types.',
    EditorWorkspaceMode.globalStory =>
      'Macro narrative progression: arcs, milestones and high-level branches.',
    EditorWorkspaceMode.step =>
      'Step logic workspace: progression rules, expected outcomes, linked cutscenes.',
    EditorWorkspaceMode.cutscene =>
      'Scene execution workspace: dialogue, movement, waits, local branching.',
    EditorWorkspaceMode.dialogue =>
      'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
  };

  return (
    workspaceMode: workspaceMode,
    workspaceTitle: workspaceTitle,
    workspaceSubtitle: workspaceSubtitle,
    canUndoMap: canUndoMap,
    canRedoMap: canRedoMap,
    isSaving: isSaving,
    canSaveMap: activeMap != null && !isSaving,
  );
});

final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        projectRootPath: state.projectRootPath,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeLayer: _resolveActiveLayerFromState(state),
        activeTool: state.activeTool,
        terrainSelectionMode: state.terrainSelectionMode,
        selectedTerrainType: state.selectedTerrainType,
        selectedEntityKind: state.selectedEntityKind,
        collisionBrushSizeMode: state.collisionBrushSizeMode,
        isSaving: state.isSaving,
        isDirty: state.isDirty,
        canUndoMap: state.canUndoMap,
        canRedoMap: state.canRedoMap,
        statusMessage: state.statusMessage,
      );
    }),
  );
});

final editorProjectExplorerSnapshotProvider =
    Provider<EditorProjectExplorerSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeMapId: state.activeMap?.id,
      );
    }),
  );
});

final editorTerrainLibrarySnapshotProvider =
    Provider<EditorTerrainLibrarySnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        tilesets: project?.tilesets ?? const <ProjectTilesetEntry>[],
        selectedTerrainType: state.selectedTerrainType,
        selectedTerrainPresetByType: state.selectedTerrainPresetByType,
        selectedTerrainPresetId: state.selectedTerrainPresetId,
        selectedPathPresetId: state.selectedPathPresetId,
      );
    }),
  );
});

final editorTilesetPaletteSnapshotProvider =
    Provider<EditorTilesetPaletteSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        projectRootPath: state.projectRootPath,
        activeLayerId: state.activeLayerId,
        activeBrush: state.activeBrush,
        paletteCategoryFilter: state.paletteCategoryFilter,
        selectedTilesetElementGroupId: state.selectedTilesetElementGroupId,
        tilesElementsPanelMode: state.tilesElementsPanelMode,
        selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      );
    }),
  );
});

MapLayer? _resolveActiveLayerFromState(EditorState state) {
  final map = state.activeMap;
  final activeLayerId = state.activeLayerId;
  if (map == null || activeLayerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == activeLayerId) {
      return layer;
    }
  }
  return null;
}

ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  final project = state.project;
  if (project == null) {
    return null;
  }

  final selectedId = state.selectedTilesetEditorId;
  if (selectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedId) {
        return tileset;
      }
    }
  }

  final activeLayer = _resolveActiveLayerFromState(state);
  if (activeLayer is TileLayer) {
    final layerTilesetId = activeLayer.tilesetId?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          return tileset;
        }
      }
    }
  }

  final brushTilesetId = _resolveActiveBrushTilesetId(state, project);
  if (brushTilesetId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == brushTilesetId) {
        return tileset;
      }
    }
  }

  if (project.tilesets.isEmpty) {
    return null;
  }
  return project.tilesets.first;
}

String? _resolveActiveBrushTilesetId(
  EditorState state,
  ProjectManifest project,
) {
  final brush = state.activeBrush;
  if (brush is TileEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is PaletteEntryEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is ProjectElementEditorBrush) {
    for (final element in project.elements) {
      if (element.id == brush.elementId) {
        return element.tilesetId;
      }
    }
  }
  return null;
}

```


### Fichier: `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`

```dart
/// Workspace central actuellement affiché dans l'éditeur.
///
/// Ce type reste simple et orienté UI/session. Le déplacer hors de
/// `editor_state.dart` réduit le bruit du fichier racine et prépare une
/// décomposition plus propre des slices d'état dans les prochains lots.
enum EditorWorkspaceMode {
  map,
  tileset,
  trainer,

  // Workspace Pokédex minimal branché dans l'éditeur.
  //
  // Intention produit:
  // - rendre visible une vraie entree Pokédex dans l'editeur ;
  // - ouvrir un workspace central dedie ;
  // - permettre d'afficher une liste simple des especes importees.
  //
  // Important:
  // ce mode reste volontairement limite :
  // - pas de recherche ;
  // - pas de filtres ;
  // - pas de fiche detail ;
  // - pas d'edition.
  pokedex,

  // Workspaces narratifs centraux.
  //
  // Intention produit (non négociable):
  // - ces surfaces vivent dans l'îlot central, comme des workspaces de
  //   premier plan (pas comme des "petits panneaux" latéraux).
  // - la colonne gauche sert à naviguer/ouvrir.
  // - la colonne droite sert à inspecter le contexte sélectionné.
  globalStory,
  step,
  cutscene,

  /// Studio de conversation (dialogues `.yarn` en blocs visuels).
  dialogue,
}

```


### Fichier: `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokedex_workspace.dart';
import 'tileset_editor_canvas.dart';
import '../panels/trainer_library_panel.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
      // Lot 13: on remplace le placeholder vide du lot 12 par une première
      // vraie liste simple, toujours en lecture seule et sans logique riche.
      EditorWorkspaceMode.pokedex => const PokedexWorkspace(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}

```


### Fichier: `packages/map_editor/lib/src/ui/editor_shell_page.dart`

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_selectors.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerStatefulWidget {
  const EditorShellPage({super.key});

  @override
  ConsumerState<EditorShellPage> createState() => _EditorShellPageState();
}

class _EditorShellPageState extends ConsumerState<EditorShellPage> {
  Timer? _toastTimer;
  String? _toastMessage;
  bool _toastIsError = false;
  bool _didAttemptProjectAutoRestore = false;

  /// When false, the right ResizablePane (map / tileset / narrative inspector) is omitted so the center stage uses full width.
  bool _rightInspectorVisible = true;

  @override
  void initState() {
    super.initState();
    // Provider mutations are intentionally deferred after the first frame:
    // auto-restore loads a project (state mutation), and Riverpod disallows
    // mutating providers during build/init lifecycle phases.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAttemptProjectAutoRestore) {
        return;
      }
      _didAttemptProjectAutoRestore = true;
      await ref
          .read(editorNotifierProvider.notifier)
          .restoreLastOpenedProjectIfAny();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _flashToast(String message, {required bool isError}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(editorShellSnapshotProvider);
    final workspaceMode = shell.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: true);
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: false);
      }
    });

    final isNarrativeWorkspace = switch (workspaceMode) {
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        true,
      _ => false,
    };

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canUndoMap) return null;
              notifier.undoMap();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canRedoMap) return null;
              notifier.redoMap();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canSaveMap) return null;
              notifier.saveActiveMap();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: EditorChrome.appRootDecoration(context),
                child: Stack(
                  children: [
                    const Positioned(
                      left: -120,
                      top: -120,
                      child: _AmbientGlow(
                        size: 460,
                        color: EditorChrome.accentPrimary,
                        opacity: 0.14,
                      ),
                    ),
                    const Positioned(
                      right: -100,
                      top: 40,
                      child: _AmbientGlow(
                        size: 400,
                        color: EditorChrome.accentLilac,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: -120,
                      top: 90,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentWarm,
                        opacity: 0.13,
                      ),
                    ),
                    const Positioned(
                      left: 140,
                      bottom: -160,
                      child: _AmbientGlow(
                        size: 520,
                        color: EditorChrome.accentJade,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: 220,
                      bottom: -140,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentCoral,
                        opacity: 0.09,
                      ),
                    ),
                    MacosWindow(
                      child: MacosScaffold(
                        backgroundColor: const Color(0x00000000),
                        toolBar: buildMapEditorToolbar(context, ref),
                        children: [
                          ResizablePane.noScrollBar(
                            key: ValueKey<bool>(isNarrativeWorkspace),
                            resizableSide: ResizableSide.right,
                            minSize: isNarrativeWorkspace ? 200 : 240,
                            maxSize: isNarrativeWorkspace ? 460 : 520,
                            startSize: isNarrativeWorkspace ? 268 : 344,
                            decoration: const BoxDecoration(
                              color: MacosColors.transparent,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isNarrativeWorkspace ? 12 : 16,
                                isNarrativeWorkspace ? 16 : 18,
                                isNarrativeWorkspace ? 10 : 12,
                                isNarrativeWorkspace ? 16 : 18,
                              ),
                              child: const ProjectExplorerPanel(),
                            ),
                          ),
                          ContentArea(
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 12 : 18,
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 6 : 8,
                                      ),
                                      child: EditorIsland(
                                        radius: 36,
                                        tint: EditorChrome.islandCoolTint,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 10 : 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _WorkspaceStageHeader(
                                                title: shell.workspaceTitle,
                                                subtitle:
                                                    shell.workspaceSubtitle,
                                                workspaceMode: workspaceMode,
                                                rightPanelVisible:
                                                    _rightInspectorVisible,
                                                onToggleRightPanel: () {
                                                  setState(() {
                                                    _rightInspectorVisible =
                                                        !_rightInspectorVisible;
                                                  });
                                                },
                                              ),
                                              SizedBox(
                                                height: isNarrativeWorkspace
                                                    ? 12
                                                    : 18,
                                              ),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(26),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      isNarrativeWorkspace
                                                          ? 8
                                                          : 14,
                                                    ),
                                                    child:
                                                        const EditorCanvasHost(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const StatusBar(),
                                ],
                              );
                            },
                          ),
                          if (_rightInspectorVisible)
                            ResizablePane.noScrollBar(
                              key: ValueKey<String>(
                                'editor_right_${isNarrativeWorkspace ? 'n' : 'm'}',
                              ),
                              resizableSide: ResizableSide.left,
                              minSize: isNarrativeWorkspace ? 220 : 240,
                              maxSize: 620,
                              startSize: isNarrativeWorkspace ? 292 : 336,
                              decoration: const BoxDecoration(
                                color: MacosColors.transparent,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 18, 16, 18),
                                child: EditorIsland(
                                  radius: 32,
                                  tint: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.tileset =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.trainer =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.pokedex =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.globalStory =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.step =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.cutscene =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.dialogue =>
                                      EditorChrome.islandCoolTint,
                                  },
                                  child: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      const MapInspectorPanel(),
                                    EditorWorkspaceMode.tileset =>
                                      const TilesetPalettePanel(),
                                    EditorWorkspaceMode.trainer =>
                                      const _EmptyWorkspaceInspector(),
                                    // Le Pokédex du lot 13 n'a toujours pas de
                                    // panneau d'inspection dédié :
                                    // pas de détail espèce, pas d'édition.
                                    // On réutilise donc un panneau neutre vide
                                    // pour éviter d'introduire une nouvelle
                                    // structure latérale ou une fausse logique.
                                    EditorWorkspaceMode.pokedex =>
                                      const _EmptyWorkspaceInspector(),
                                    EditorWorkspaceMode.globalStory ||
                                    EditorWorkspaceMode.step ||
                                    EditorWorkspaceMode.cutscene ||
                                    EditorWorkspaceMode.dialogue =>
                                      const NarrativeInspectorPanel(),
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_toastMessage != null)
                Positioned(
                  right: 24,
                  bottom: 72,
                  child: _EditorToastBanner(
                    message: _toastMessage!,
                    isError: _toastIsError,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToastBanner extends StatelessWidget {
  const _EditorToastBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError
        ? EditorChrome.errorTint(context)
        : EditorChrome.statusTint(context);
    final accent = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyMint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorIsland(
        radius: 18,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, accent, 0.75)!,
                      Color.lerp(accent, const Color(0xFF102010), 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.88),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceStageHeader extends StatelessWidget {
  const _WorkspaceStageHeader({
    required this.title,
    required this.subtitle,
    required this.workspaceMode,
    required this.rightPanelVisible,
    required this.onToggleRightPanel,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;
  final bool rightPanelVisible;
  final VoidCallback onToggleRightPanel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final chipFill = EditorChrome.chipFill(context);
    final chipAccent = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyHoney,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyLilac,
      EditorWorkspaceMode.trainer => EditorChrome.accentCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.inspectorJoyAmber,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
    };
    final chipAccent2 = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyPlum,
      EditorWorkspaceMode.trainer => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.accentWarm,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.step => EditorChrome.accentJade,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
    };

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(CupertinoColors.white, chipAccent, 0.72)!,
                Color.lerp(chipAccent2, const Color(0xFF1A0A08), 0.38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.88),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => CupertinoIcons.map,
              EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
              EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
              EditorWorkspaceMode.pokedex => CupertinoIcons.book,
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
            },
            color: CupertinoColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        MacosTooltip(
          message: rightPanelVisible ? 'Hide right panel' : 'Show right panel',
          child: MacosIconButton(
            semanticLabel:
                rightPanelVisible ? 'Hide right panel' : 'Show right panel',
            icon: MacosIcon(
              rightPanelVisible ? Icons.open_in_full : Icons.close_fullscreen,
              color: label.withValues(alpha: 0.85),
              size: 18,
            ),
            backgroundColor: CupertinoColors.transparent,
            hoverColor: chipAccent.withValues(alpha: 0.12),
            onPressed: onToggleRightPanel,
            boxConstraints: const BoxConstraints(
              minWidth: 34,
              maxWidth: 34,
              minHeight: 34,
              maxHeight: 34,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Color.lerp(chipFill, chipAccent, 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: Text(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => 'Scene',
              EditorWorkspaceMode.tileset => 'Library',
              EditorWorkspaceMode.trainer => 'Trainer',
              EditorWorkspaceMode.pokedex => 'Pokedex',
              EditorWorkspaceMode.globalStory => 'Global',
              EditorWorkspaceMode.step => 'Step',
              EditorWorkspaceMode.cutscene => 'Cutscene',
              EditorWorkspaceMode.dialogue => 'Dialogue',
            },
            style: TextStyle(
              color: chipAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Panneau droit volontairement neutre pour les workspaces qui n'ont pas
/// encore d'inspecteur réel.
///
/// Pour le lot 12, cela permet de garder la structure visuelle existante de
/// l'éditeur sans inventer un inspecteur Pokédex artificiel, ni brancher une
/// logique future avant l'heure.
class _EmptyWorkspaceInspector extends StatelessWidget {
  const _EmptyWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cette section n’a pas encore d’inspecteur dédié.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

bool _isTextInputFocused() {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) return false;
  return focusedContext.widget is EditableText ||
      focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

```


### Fichier: `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'project_explorer/dialogs/import_tileset_dialog.dart';
import 'project_explorer/dialogs/tileset_library_dialogs.dart';
import 'project_explorer/dialogs/world_group_dialogs.dart';
import 'project_explorer/widgets/sidebar_header_action.dart';
import 'project_explorer/widgets/tree/tileset_tree_nodes.dart';
import 'project_explorer/widgets/tree/world_tree_nodes.dart';
import 'character_library_panel.dart';
import 'narrative_library_panel.dart';
import 'terrain_editor_panel.dart';
import 'trainer_library_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({super.key});

  @override
  ConsumerState<ProjectExplorerPanel> createState() =>
      _ProjectExplorerPanelState();
}

class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
  bool _expandTileLib = true;
  bool _expandPokedex = true;
  bool _expandNarrative = true;
  bool _expandWorld = true;
  bool _expandTerrains = true;
  bool _expandPaths = true;
  bool _expandTrainers = false;
  bool _expandCharacters = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorProjectExplorerSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = snapshot.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: project == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Open a project to browse your world, maps and tilesets.',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.inspectorJoyCyan;
    const explorerDeep = EditorChrome.inspectorJoyPlum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, explorerAccent, 0.78)!,
                  Color.lerp(explorerDeep, const Color(0xFF140818), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explorerAccent.withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => GroupNode(
          group: g,
          project: project,
          snapshot: snapshot,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => MapNode(
            map: m,
            snapshot: snapshot,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    final screenH = MediaQuery.sizeOf(context).height;
    final hTileset = (screenH * 0.30).clamp(240.0, 400.0);
    final hPokedex = (screenH * 0.22).clamp(180.0, 260.0);
    final hNarrative = (screenH * 0.34).clamp(260.0, 460.0);
    final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
    final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
    final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
    final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
    final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
    const explorerTileRadius = 28.0;
    final actionIcon = CupertinoColors.white.withValues(alpha: 0.92);
    final actionHover = CupertinoColors.white.withValues(alpha: 0.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Tileset Library',
          subtitle: 'Folders, imports, and map painting',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: EditorChrome.inspectorJoyBlue,
          badgeText: '${project.tilesets.length}',
          expanded: _expandTileLib,
          onToggle: () => setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.photo_on_rectangle,
                tooltip: 'Import tileset',
                onPressed: () =>
                    showImportTilesetDialog(context, snapshot, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
              const SizedBox(width: 6),
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.plus_circle_fill,
                tooltip: 'New folder',
                onPressed: () => promptNewTilesetLibraryFolder(
                  context,
                  notifier,
                ),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildTilesetsIsland(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Pokédex',
          subtitle:
              'Simple local species list (lot 13: number, name, id, types)',
          icon: CupertinoIcons.book_fill,
          accentColor: EditorChrome.inspectorJoyAmber,
          // Pas de compteur ni de résumé riche ici :
          // le lot 13 doit rester une porte d'entrée sobre vers la liste
          // simple, sans glisser vers les futurs lots d'édition ou de détail.
          expanded: _expandPokedex,
          onToggle: () => setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokedexPlaceholderCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Narrative Studio',
          subtitle:
              'Global Story, Steps, Cutscenes and outcomes (opens central workspaces)',
          icon: CupertinoIcons.link_circle_fill,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.scenarios.length}',
          expanded: _expandNarrative,
          onToggle: () => setState(() => _expandNarrative = !_expandNarrative),
          expandedHeight: hNarrative,
          child: const NarrativeLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'World Maps',
          subtitle:
              'Maps jouables et contenu monde (events, entités, warps, triggers)',
          icon: CupertinoIcons.map_fill,
          accentColor: EditorChrome.inspectorJoyPlum,
          badgeText: '${project.maps.length}',
          expanded: _expandWorld,
          onToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New root group',
                onPressed: () => showCreateGroupDialog(context, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildWorldIslandBody(context, worldChildren),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Terrain Library',
          subtitle: 'Base ground presets',
          icon: CupertinoIcons.map,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.terrainPresets.length}',
          expanded: _expandTerrains,
          onToggle: () => setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Path Library',
          subtitle: 'Surface overlays: roads, water, tall grass...',
          icon: CupertinoIcons.arrow_branch,
          accentColor: EditorChrome.accentWarm,
          badgeText: '${project.pathPresets.length}',
          expanded: _expandPaths,
          onToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: const PathLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Trainer Studio',
          subtitle: 'Battle rosters and teams (opens the central workspace)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: EditorChrome.accentCoral,
          badgeText: '${project.trainers.length}',
          expanded: _expandTrainers,
          onToggle: () => setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Character Library',
          subtitle: 'Overworld sprites for the player and NPCs',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.characters.length}',
          expanded: _expandCharacters,
          onToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildTilesetsSection(context, project, snapshot, notifier),
    );
  }

  Widget _buildPokedexPlaceholderCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selected = snapshot.workspaceMode == EditorWorkspaceMode.pokedex;
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On reutilise le pattern de ligne cliquable du navigateur existant.
          // C'est le point d'integration le plus petit possible pour rendre
          // Pokédex visible et ouvrable, sans inventer une nouvelle convention.
          EditorSidebarListRow(
            key: const Key('pokedex-explorer-entry'),
            selected: selected,
            onTap: notifier.selectPokedexWorkspace,
            leading: const MacosIcon(CupertinoIcons.book),
            title: const Text('Pokédex'),
            subtitle: const Text(
              'Recherche, import, détail et édition locale des espèces',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text(
              'Cette entrée ouvre le workspace Pokédex du projet : import local JSON, recherche, filtres, détail et édition locale des espèces importées.',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldIslandBody(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: worldChildren,
      ),
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId = snapshot.selectedTilesetEntry?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilesetLibraryRootDropStrip(project: project, notifier: notifier),
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}

```


### Fichier: `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

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
          'Impossible de charger les espèces locales. La saisie brute reste possible.\n$error';
    }

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.\n$error',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.\n$error',
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


### Fichier: `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

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

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            widget.speciesController.text,
          )
        : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;

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
              title: 'Search the local Pokédex',
              description: speciesCatalogReady
                  ? 'Search by species name, local id or Pokédex number.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              searchPlaceholder: 'Search a project species',
              subtitleBuilder: (entry) => [
                '#${entry.nationalDex.toString().padLeft(4, '0')}',
                entry.types.join('/'),
                entry.id,
              ].join(' • '),
              onSelected: (entry) {
                widget.speciesController.text = entry.id;
              },
            ),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Raw species ID (fallback)',
              fieldKey: const Key('trainer-library-pokemon-species-field'),
              controller: widget.speciesController,
              placeholder: 'pikachu',
            ),
            const SizedBox(height: 6),
            Text(
              resolvedSpecies == null
                  ? speciesCatalogReady
                      ? 'Raw species ID not resolved in the local Pokédex.'
                      : 'La validation d’espèce reste limitée tant que l’index local est indisponible.'
                  : 'Selected species: ${resolvedSpecies.primaryName} • #${resolvedSpecies.nationalDex.toString().padLeft(4, '0')} • ${resolvedSpecies.id}',
              style: TextStyle(
                color: resolvedSpecies == null
                    ? EditorChrome.inspectorJoyCoral
                    : subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
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
            const InspectorEmbeddedSectionLabel('MOVES'),
            const SizedBox(height: 8),
            for (var i = 0; i < widget.moveControllers.length; i++) ...[
              _TrainerMoveSlotEditor(
                slotIndex: i,
                controller: widget.moveControllers[i],
                catalogView: widget.references.movesCatalogView,
              ),
              if (i != widget.moveControllers.length - 1)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const InspectorEmbeddedSectionLabel('ITEM / FORM'),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonItemCatalogEntryView>(
              keyPrefix: 'trainer-library-pokemon-item',
              title: 'Search the local item catalog',
              description: widget.references.itemsCatalogView.isAvailable
                  ? 'Search by item name or local id.'
                  : widget.references.itemsCatalogView.message ??
                      widget.references.itemsCatalogView.description,
              entries: widget.references.itemsCatalogView.entries,
              lookupService: _itemsLookupService,
              enabled: widget.references.itemsCatalogView.isAvailable,
              searchPlaceholder: 'Search a project item',
              subtitleBuilder: (entry) => entry.id,
              onSelected: (entry) {
                widget.itemController.text = entry.id;
              },
            ),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Raw held item ID (fallback)',
              fieldKey: const Key('trainer-library-pokemon-item-field'),
              controller: widget.itemController,
              placeholder: 'oran_berry',
            ),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Raw form ID (fallback)',
              fieldKey: const Key('trainer-library-pokemon-form-field'),
              controller: widget.formController,
              placeholder: 'base / alternate form id',
            ),
            const SizedBox(height: 8),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              widget.speciesController.text.trim().isNotEmpty
                          ? 'Chargement des formes locales pour cette espèce…'
                          : widget.speciesController.text.trim().isEmpty
                              ? 'Renseignez une espèce pour vérifier les formes locales.'
                              : detail == null
                                  ? 'Impossible de vérifier les formes locales pour cette espèce. La saisie brute reste possible.'
                                  : availableForms.isEmpty
                                      ? 'Aucune suggestion de forme locale disponible pour cette espèce. La saisie brute reste possible.'
                                      : 'Suggestions de formes locales :',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;

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
          title: 'Search move slot ${slotIndex + 1}',
          description: catalogView.isAvailable
              ? 'Search by move name or local id.'
              : catalogView.message ?? catalogView.description,
          entries: catalogView.entries,
          lookupService: _movesLookupService,
          enabled: catalogView.isAvailable,
          searchPlaceholder: 'Search a move',
          subtitleBuilder: (entry) => [
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.power != null) 'Power ${entry.power}',
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
        ),
        const SizedBox(height: 6),
        _TrainerInlineField(
          label: 'Raw move ID ${slotIndex + 1} (fallback)',
          fieldKey: Key('trainer-library-pokemon-move-$slotIndex-field'),
          controller: controller,
          placeholder: 'move id',
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
    required this.searchPlaceholder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String keyPrefix;
  final String title;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String searchPlaceholder;
  final ValueChanged<T> onSelected;
  final String Function(T entry)? subtitleBuilder;

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
              : 'Local search unavailable',
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


### Fichier: `packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

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

```


### Fichier: `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`

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
                  : references.movesCatalogView.message ??
                      references.movesCatalogView.description,
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
                  : references.itemsCatalogView.message ??
                      references.itemsCatalogView.description,
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


### Fichier: `packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

// Trainer Studio lot 8-2 keeps a single source of truth:
// - the sidebar (`embedded: true`) is now only a launcher / summary surface;
// - the central workspace (`embedded: false`) owns the real authoring UI;
// - both views still reuse the same local state, notifier calls and lookup
//   services from `TrainerLibraryPanel`.
extension _TrainerLibraryWorkspaceRendering on _TrainerLibraryPanelState {
  Widget _buildEmbeddedTrainerLibrary({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final selectedTrainer = _selectedTrainerForWorkspace(project, state);
    final totalTeamPokemon = project.trainers.fold<int>(
      0,
      (sum, trainer) => sum + trainer.team.length,
    );
    final subtle = EditorChrome.subtleLabel(context);

    void openStudio() {
      if (selectedTrainer != null) {
        notifier.selectTrainer(selectedTrainer.id);
      }
      notifier.selectTrainerWorkspace();
    }

    return ListView(
      padding: kInspectorTileBodyPadding,
      children: [
        EditorSidebarListRow(
          key: const Key('trainer-library-studio-entry'),
          selected: state.workspaceMode == EditorWorkspaceMode.trainer,
          onTap: openStudio,
          leading: const MacosIcon(CupertinoIcons.person_3_fill),
          title: const Text('Trainer Studio'),
          subtitle: const Text(
            'Open the main workspace to create trainers, teams and battle rosters.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EditorChrome.accentCoral.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${project.trainers.length} trainers • $totalTeamPokemon team Pokémon',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedTrainer == null
                      ? 'No trainer selected yet. Open Trainer Studio to create your first roster.'
                      : 'Current focus: ${selectedTrainer.name} • ${selectedTrainer.trainerClass}\n'
                          '${_buildRosterPreview(selectedTrainer, references)}',
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
        ),
        const SizedBox(height: 10),
        CupertinoButton.filled(
          key: const Key('trainer-library-open-studio-button'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: openStudio,
          child: const Text('Open Trainer Studio'),
        ),
        const SizedBox(height: 8),
        Text(
          'Detailed editing now lives in the center workspace so trainers, team cards and guided selectors all stay visible together.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerStudioWorkspace({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
  }) {
    final visibleTrainer = _selectedTrainerForWorkspace(project, state);
    final workspace = _workspaceForState(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rosterWidth = constraints.maxWidth >= 1440 ? 320.0 : 280.0;
        final editorWidth = constraints.maxWidth >= 1440 ? 430.0 : 390.0;
        // The main shell can shrink the center stage a lot once both side
        // panels are visible. When that happens, keeping the original
        // three-column layout would crush the detail pane down to unusable
        // widths. We keep the same authoring surface, but fold it into a
        // stacked layout so the central workspace stays readable instead of
        // silently overflowing.
        final useCompactLayout =
            constraints.maxWidth < rosterWidth + editorWidth + 360;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TrainerStudioHeaderCard(
                onNewTrainer: _openCreateTrainerForm,
                referencesBanner: _TrainerReferencesBanner(
                  references: references,
                  onRefresh: () => _refreshReferenceData(state),
                ),
                operationBanner: (state.errorMessage ?? '').trim().isEmpty &&
                        (state.statusMessage ?? '').trim().isEmpty
                    ? null
                    : _TrainerOperationBanner(
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: useCompactLayout
                    ? _buildCompactTrainerStudioBody(
                        context: context,
                        state: state,
                        project: project,
                        notifier: notifier,
                        references: references,
                        visibleTrainer: visibleTrainer,
                        workspace: workspace,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: rosterWidth,
                            child: _buildTrainerRosterPane(
                              context: context,
                              state: state,
                              project: project,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTrainerDetailWorkspacePane(
                              context: context,
                              project: project,
                              notifier: notifier,
                              references: references,
                              visibleTrainer: visibleTrainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: editorWidth,
                            child: _buildTrainerEditorWorkspacePane(
                              context: context,
                              workspace: workspace,
                              visibleTrainer: visibleTrainer,
                              references: references,
                              notifier: notifier,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTrainerStudioBody({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
    required ProjectWorkspace? workspace,
  }) {
    // This is intentionally a stacked version of the same three surfaces.
    // We do not create a second trainer editor; we only reflow the existing
    // roster/detail/editor panes so the workspace remains usable inside the
    // narrower center shell.
    final detailHeight = _showCreateForm || _editingTrainerId != null
        ? 560.0
        : visibleTrainer == null
            ? 320.0
            : 500.0;
    final editorHeight = _activePokemonTrainerId == visibleTrainer?.id
        ? 760.0
        : visibleTrainer == null
            ? 260.0
            : 320.0;

    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: _buildTrainerRosterPane(
            context: context,
            state: state,
            project: project,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: detailHeight,
          child: _buildTrainerDetailWorkspacePane(
            context: context,
            project: project,
            notifier: notifier,
            references: references,
            visibleTrainer: visibleTrainer,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: editorHeight,
          child: _buildTrainerEditorWorkspacePane(
            context: context,
            workspace: workspace,
            visibleTrainer: visibleTrainer,
            references: references,
            notifier: notifier,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerRosterPane({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-roster-pane'),
      title: 'Trainer Roster',
      subtitle: 'Search, browse and pick the trainer you want to author.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key(
              'trainer-library-roster-search-field',
            ),
            controller: _trainerSearchController,
            placeholder: 'Search by name, class, id or tag',
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTrainerRosterList(
              context: context,
              state: state,
              project: project,
              references: references,
              visibleTrainer: visibleTrainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerDetailWorkspacePane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-detail-pane'),
      title: 'Trainer Detail',
      subtitle: 'Identity, optional refs and the current battle team.',
      child: _buildTrainerDetailPane(
        context: context,
        project: project,
        notifier: notifier,
        references: references,
        visibleTrainer: visibleTrainer,
      ),
    );
  }

  Widget _buildTrainerEditorWorkspacePane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    return _TrainerStudioPane(
      key: const Key('trainer-library-editor-pane'),
      title: 'Guided Pokémon Editor',
      subtitle:
          'Pick species, moves, forms and items with local search when available.',
      child: _buildPokemonEditorPane(
        context: context,
        workspace: workspace,
        visibleTrainer: visibleTrainer,
        references: references,
        notifier: notifier,
      ),
    );
  }

  Widget _buildTrainerRosterList({
    required BuildContext context,
    required EditorState state,
    required ProjectManifest project,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    final filtered = project.trainers
        .where(
          (trainer) =>
              _trainerMatchesSearch(trainer, _trainerSearchController.text),
        )
        .toList(growable: false);
    final subtle = EditorChrome.subtleLabel(context);

    if (project.trainers.isEmpty) {
      return Center(
        child: Text(
          'No trainers yet.\nUse the button above to create your first roster.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No trainer matches this search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('trainer-library-roster-scroll'),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trainer = filtered[index];
        return _TrainerStudioRosterCard(
          key: Key('trainer-library-roster-row-${trainer.id}'),
          trainer: trainer,
          selected: visibleTrainer?.id == trainer.id,
          preview: _buildRosterPreview(trainer, references),
          onTap: () => _selectTrainerForWorkspace(trainer.id),
        );
      },
    );
  }

  String _buildRosterPreview(
    ProjectTrainerEntry trainer,
    _TrainerReferenceData references,
  ) {
    if (trainer.team.isEmpty) {
      return 'No Pokémon assigned yet';
    }
    final preview = trainer.team.take(3).map((pokemon) {
      final species = _speciesLookupService.findById(
        references.speciesEntries,
        pokemon.speciesId,
      );
      return species?.primaryName ?? pokemon.speciesId;
    }).join(', ');
    final suffix = trainer.team.length > 3 ? '…' : '';
    return '$preview$suffix';
  }

  Widget _buildTrainerDetailPane({
    required BuildContext context,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required ProjectTrainerEntry? visibleTrainer,
  }) {
    if (_showCreateForm) {
      return ListView(
        key: const Key('trainer-library-detail-scroll'),
        children: [
          _TrainerEditorCard(
            key: const Key('trainer-library-create-card'),
            title: 'NEW TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _newNameController,
            classController: _newClassController,
            portraitController: _newPortraitController,
            battleThemeController: _newBattleThemeController,
            victoryThemeController: _newVictoryThemeController,
            tagsController: _newTagsController,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _newCharacterId,
            validationMessage: _createTrainerValidationMessage,
            showAdvanced: _showCreateAdvanced,
            createMode: true,
            onToggleAdvanced: _toggleCreateAdvanced,
            onSelectCharacter: _setNewCharacterId,
            onCancel: _cancelCreateTrainerDraft,
            onSubmit: () => _handleCreateTrainer(
              notifier: notifier,
              project: project,
            ),
          ),
        ],
      );
    }

    if (visibleTrainer == null) {
      return _TrainerStudioEmptyState(
        title: 'No trainer selected',
        body:
            'Pick a trainer from the roster or create a new one to start authoring a full battle team.',
        actionLabel: 'Create Trainer',
        onAction: _openCreateTrainerForm,
      );
    }

    final subtle = EditorChrome.subtleLabel(context);
    final isEditing = _editingTrainerId == visibleTrainer.id;
    final isAddingPokemon =
        _isAddingPokemon && _activePokemonTrainerId == visibleTrainer.id;

    return ListView(
      key: const Key('trainer-library-detail-scroll'),
      children: [
        if (isEditing)
          _TrainerEditorCard(
            key: Key('trainer-library-edit-card-${visibleTrainer.id}'),
            title: 'EDIT TRAINER',
            accent: EditorChrome.accentCoral,
            nameController: _editNameController,
            classController: _editClassController,
            portraitController: _editPortraitController,
            battleThemeController: _editBattleThemeController,
            victoryThemeController: _editVictoryThemeController,
            tagsController: _editTagsController,
            characters: project.characters,
            elements: project.elements,
            selectedCharacterId: _editCharacterId,
            validationMessage: _editTrainerValidationMessage,
            showAdvanced: _showEditAdvanced,
            createMode: false,
            onToggleAdvanced: _toggleEditAdvanced,
            onSelectCharacter: _setEditCharacterId,
            onCancel: _cancelTrainerEditor,
            onSubmit: () => _handleUpdateTrainer(
              notifier: notifier,
              project: project,
              trainer: visibleTrainer,
            ),
          )
        else
          _TrainerStudioIdentityCard(
            trainer: visibleTrainer,
            onEdit: () => _startEditingTrainer(visibleTrainer),
            onDelete: () => _handleDeleteTrainer(
              notifier: notifier,
              trainer: visibleTrainer,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'TEAM (${visibleTrainer.team.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            CupertinoButton(
              key: Key(
                  'trainer-library-add-pokemon-button-${visibleTrainer.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(1, 32),
              onPressed: () {
                if (isAddingPokemon) {
                  _cancelPokemonEditor();
                } else {
                  _startAddingPokemon(visibleTrainer.id);
                }
              },
              child: Text(
                isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleTrainer.team.isEmpty)
          Text(
            'This trainer has no team yet. You can save the trainer now and add battle Pokémon right after.',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        for (var i = 0; i < visibleTrainer.team.length; i++) ...[
          _TrainerPokemonSummaryRow(
            key: Key('trainer-library-pokemon-row-${visibleTrainer.id}-$i'),
            pokemon: visibleTrainer.team[i],
            speciesEntry: _speciesLookupService.findById(
              references.speciesEntries,
              visibleTrainer.team[i].speciesId,
            ),
            isSpeciesCatalogAvailable: references.isSpeciesAvailable,
            moveCatalogView: references.movesCatalogView,
            itemCatalogView: references.itemsCatalogView,
            onEdit: () => _startEditingPokemon(
                visibleTrainer.id, i, visibleTrainer.team[i]),
            onDelete: () => _handleDeletePokemon(
              notifier: notifier,
              trainerId: visibleTrainer.id,
              pokemonIndex: i,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildPokemonEditorPane({
    required BuildContext context,
    required ProjectWorkspace? workspace,
    required ProjectTrainerEntry? visibleTrainer,
    required _TrainerReferenceData references,
    required EditorNotifier notifier,
  }) {
    final subtle = EditorChrome.subtleLabel(context);

    if (workspace == null) {
      return Center(
        child: Text(
          'Trainer saves need a valid project workspace.\nNo workspace is currently available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (visibleTrainer == null) {
      return Center(
        child: Text(
          'Select a trainer first.\nThe guided Pokémon editor will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }

    if (_activePokemonTrainerId != visibleTrainer.id) {
      return const _TrainerStudioEmptyState(
        title: 'No Pokémon selected',
        body:
            'Choose “Add Pokémon” or edit one of the trainer team cards to open the guided editor here.',
      );
    }

    final editorTitle =
        _editingPokemonIndex == null ? 'NEW TEAM POKÉMON' : 'EDIT TEAM POKÉMON';

    return ListView(
      key: const Key('trainer-library-editor-scroll'),
      children: [
        Text(
          '${visibleTrainer.name} • $editorTitle',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        _TrainerPokemonEditorCard(
          key: _editingPokemonIndex == null
              ? Key('trainer-library-add-pokemon-card-${visibleTrainer.id}')
              : Key(
                  'trainer-library-edit-pokemon-card-${visibleTrainer.id}-${_editingPokemonIndex!}',
                ),
          trainerId: visibleTrainer.id,
          references: references,
          speciesController: _pokemonSpeciesController,
          levelController: _pokemonLevelController,
          itemController: _pokemonItemController,
          formController: _pokemonFormController,
          genderController: _pokemonGenderController,
          moveControllers: _pokemonMoveControllers,
          shiny: _pokemonShiny,
          validationMessage: _pokemonValidationMessage,
          onToggleShiny: _setPokemonShiny,
          onCancel: _cancelPokemonEditor,
          onSave: () => _handleSavePokemonDraft(
            notifier: notifier,
            workspace: workspace,
            references: references,
          ),
          loadSpeciesDetail: (speciesId) =>
              _loadSpeciesDetailIfPossible(workspace, speciesId),
        ),
      ],
    );
  }
}

class _TrainerStudioHeaderCard extends StatelessWidget {
  const _TrainerStudioHeaderCard({
    required this.onNewTrainer,
    required this.referencesBanner,
    required this.operationBanner,
  });

  final VoidCallback onNewTrainer;
  final Widget referencesBanner;
  final Widget? operationBanner;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentCoral.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainer Studio',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and edit project trainers in one readable workspace: roster on the left, team detail in the middle, guided Pokémon editing on the right.',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton.filled(
                  key: const Key('trainer-library-new-trainer-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(1, 34),
                  onPressed: onNewTrainer,
                  child: const Text('New Trainer'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            referencesBanner,
            if (operationBanner != null) ...[
              const SizedBox(height: 10),
              operationBanner!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioPane extends StatelessWidget {
  const _TrainerStudioPane({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TrainerStudioRosterCard extends StatelessWidget {
  const _TrainerStudioRosterCard({
    super.key,
    required this.trainer,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final ProjectTrainerEntry trainer;
  final bool selected;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.accentCoral.withValues(alpha: 0.1),
              )
            : EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? EditorChrome.accentCoral.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trainer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _TrainerStudioMiniBadge(
                  label: '${trainer.team.length} mon',
                  selected: selected,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${trainer.trainerClass} • ${trainer.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _TrainerStudioMiniBadge extends StatelessWidget {
  const _TrainerStudioMiniBadge({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.accentCoral
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrainerStudioIdentityCard extends StatelessWidget {
  const _TrainerStudioIdentityCard({
    required this.trainer,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerEntry trainer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trainer.trainerClass} • ${trainer.id}',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(1, 32),
                  onPressed: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
              ],
            ),
            if (trainer.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in trainer.tags) _TrainerMetaChip(label: tag),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              [
                if ((trainer.characterId ?? '').trim().isNotEmpty)
                  'Character: ${trainer.characterId!.trim()}',
                if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                  'Portrait: ${trainer.portraitElementId!.trim()}',
                if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                  'Battle theme: ${trainer.battleThemeId!.trim()}',
                if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                  'Victory theme: ${trainer.victoryThemeId!.trim()}',
              ].isEmpty
                  ? 'No optional refs configured yet. You can still author a complete battle team right away.'
                  : [
                      if ((trainer.characterId ?? '').trim().isNotEmpty)
                        'Character: ${trainer.characterId!.trim()}',
                      if ((trainer.portraitElementId ?? '').trim().isNotEmpty)
                        'Portrait: ${trainer.portraitElementId!.trim()}',
                      if ((trainer.battleThemeId ?? '').trim().isNotEmpty)
                        'Battle theme: ${trainer.battleThemeId!.trim()}',
                      if ((trainer.victoryThemeId ?? '').trim().isNotEmpty)
                        'Victory theme: ${trainer.victoryThemeId!.trim()}',
                    ].join('\n'),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMetaChip extends StatelessWidget {
  const _TrainerMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentCoral.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrainerStudioEmptyState extends StatelessWidget {
  const _TrainerStudioEmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

```


### Fichier: `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'cupertino_editor_widgets.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'top_toolbar/widgets/toolbar_brand.dart';
import 'top_toolbar/widgets/toolbar_capsules.dart';

/// Exposé pour [MacosScaffold.toolBar], qui attend un [ToolBar] typé (pas un [ConsumerWidget]).
ToolBar buildMapEditorToolbar(BuildContext context, WidgetRef ref) =>
    TopToolbar.buildToolBar(context, ref);

/// Barre d’outils native [macos_ui] pour [MacosScaffold].
class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TopToolbar.buildToolBar(context, ref);

  static List<MacosPulldownMenuEntry> _terrainPulldownItems(
    EditorNotifier notifier,
  ) {
    return TerrainType.values
        .where((t) => t.isBackgroundPaintable)
        .map(
          (terrain) => MacosPulldownMenuItem(
            label: _terrainTypeLabel(terrain),
            title: Text(_terrainTypeLabel(terrain)),
            onTap: () => notifier.selectTerrainType(terrain),
          ),
        )
        .toList();
  }

  static List<MacosPulldownMenuEntry> _entityKindPulldownItems(
    EditorNotifier notifier,
  ) {
    return MapEntityKind.values
        .map(
          (kind) => MacosPulldownMenuItem(
            label: _entityKindLabel(kind),
            title: Text(_entityKindLabel(kind)),
            onTap: () => notifier.selectEntityKind(kind),
          ),
        )
        .toList(growable: false);
  }

  static ToolBar buildToolBar(BuildContext context, WidgetRef ref) {
    final toolbar = ref.watch(editorToolbarSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = toolbar.settings;
    final subtle = EditorChrome.subtleLabel(context);

    final map = toolbar.activeMap;
    final isMapWorkspace = toolbar.workspaceMode == EditorWorkspaceMode.map;
    final hasTilesets = (toolbar.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? toolbar.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;
    final activeLayer = toolbar.activeLayer;

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is TerrainLayer ||
        activeLayer is PathLayer;

    final showTerrainTypePulldown = activeLayer is TerrainLayer &&
        toolbar.activeTool == EditorToolType.terrainPaint &&
        toolbar.terrainSelectionMode == TerrainSelectionMode.terrain;
    final showEntityKindPulldown =
        toolbar.activeTool == EditorToolType.entityPlacement;
    final showContextStrip =
        showWorldTools && (showTerrainTypePulldown || showEntityKindPulldown);

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        (toolbar.activeTool == EditorToolType.collisionPaint ||
            toolbar.activeTool == EditorToolType.eraser);

    final actions = <ToolbarItem>[
      _groupItem(
        context,
        overflowLabel: 'Project',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Project',
            onPressed: () => showTopToolbarNewProjectDialog(
              context,
              notifier,
            ),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_open,
            tooltip: 'Open Project',
            onPressed: () async {
              final selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.placemark,
            tooltip: 'New Map',
            onPressed:
                toolbar.project != null && toolbar.projectRootPath != null
                    ? () => showTopToolbarNewMapDialog(
                          context,
                          notifier,
                          defaultWidth: settings.defaultMapWidth,
                          defaultHeight: settings.defaultMapHeight,
                        )
                    : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.gear,
            tooltip: 'Project Settings',
            onPressed: toolbar.project != null
                ? () => showTopToolbarProjectSettingsDialog(
                      context,
                      notifier,
                      toolbar.project!,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
            tooltip: 'Resize Map',
            onPressed: isMapWorkspace && toolbar.activeMap != null
                ? () => showTopToolbarResizeMapDialog(
                      context,
                      notifier,
                      currentWidth: toolbar.activeMap!.size.width,
                      currentHeight: toolbar.activeMap!.size.height,
                    )
                : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'History',
        children: [
          if (toolbar.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ProgressCircle(),
              ),
            )
          else
            ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: 'Save Map',
              selected: toolbar.isDirty,
              onPressed: toolbar.activeMap != null
                  ? () => notifier.saveActiveMap()
                  : null,
            ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_left,
            tooltip: 'Undo',
            onPressed: toolbar.canUndoMap ? notifier.undoMap : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_right,
            tooltip: 'Redo',
            onPressed: toolbar.canRedoMap ? notifier.redoMap : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'Workspace',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.map,
            tooltip: 'Switch to map workspace',
            selected: isMapWorkspace,
            onPressed: notifier.selectMapWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.square_grid_2x2,
            tooltip: 'Switch to tileset workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.tileset,
            onPressed: hasTilesets
                ? () => notifier.selectTilesetWorkspace(
                      toolbar.selectedTilesetEntry?.id ?? firstTilesetId,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.person_3_fill,
            tooltip: 'Switch to Trainer Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.trainer,
            onPressed: toolbar.project != null
                ? notifier.selectTrainerWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.book,
            tooltip: 'Switch to Pokédex species list',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pokedex,
            // Lot 13: simple navigation UI vers une liste lecture seule.
            // Aucun filtre, aucune recherche ni action d'édition n'est ajouté
            // dans cette toolbar.
            onPressed: toolbar.project != null
                ? notifier.selectPokedexWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.link,
            tooltip: 'Switch to global story workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.globalStory,
            onPressed: notifier.selectGlobalStoryWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.flag,
            tooltip: 'Switch to Step Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.step,
            onPressed: notifier.selectStepWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.play_rectangle,
            tooltip: 'Switch to Cutscene Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.cutscene,
            onPressed: notifier.selectCutsceneWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.text_bubble,
            tooltip: 'Switch to dialogue studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.dialogue,
            onPressed: notifier.selectDialogueWorkspace,
          ),
        ],
      ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Painting Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.selection_pin_in_out,
              tooltip: 'Selection Tool',
              selected: toolbar.activeTool == EditorToolType.selection,
              onPressed: () => notifier.selectTool(EditorToolType.selection),
            ),
            if (activeLayer is TileLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.paintbrush,
                tooltip: 'Tile Paint Tool',
                selected: toolbar.activeTool == EditorToolType.tilePaint,
                onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
              ),
            if (activeLayer is TerrainLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.tree,
                tooltip: 'Terrain Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode ==
                        TerrainSelectionMode.terrain,
                onPressed: () =>
                    notifier.selectTool(EditorToolType.terrainPaint),
              ),
            if (activeLayer is PathLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.map,
                tooltip: 'Path Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode == TerrainSelectionMode.path,
                onPressed: notifier.selectPathPaintMode,
              ),
            if (activeLayer is CollisionLayer) ...[
              ToolbarCapsuleButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Collision Paint Tool',
                selected: toolbar.activeTool == EditorToolType.collisionPaint,
                onPressed: () => notifier.selectTool(
                  EditorToolType.collisionPaint,
                ),
              ),
              if (showCollisionBrushSize)
                ToolbarCapsuleButton(
                  icon: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? CupertinoIcons.number
                      : CupertinoIcons.square_grid_3x2,
                  tooltip: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? 'Collision Brush Size: 1x1'
                      : 'Collision Brush Size: Brush Footprint',
                  selected:
                      toolbar.activeTool == EditorToolType.collisionPaint ||
                          toolbar.activeTool == EditorToolType.eraser,
                  onPressed: notifier.toggleCollisionBrushSizeMode,
                ),
            ],
            if (canEraseOnActiveLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.delete,
                tooltip: 'Eraser Tool',
                selected: toolbar.activeTool == EditorToolType.eraser,
                onPressed: () => notifier.selectTool(EditorToolType.eraser),
              ),
          ],
        ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Gameplay Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.sparkles,
              tooltip: 'Entity Tool',
              selected: toolbar.activeTool == EditorToolType.entityPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.entityPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Event Tool',
              selected: toolbar.activeTool == EditorToolType.eventPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.eventPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.square,
              tooltip: 'Trigger Tool',
              selected: toolbar.activeTool == EditorToolType.triggerPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.triggerPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.arrow_branch,
              tooltip: 'Warp Tool',
              selected: toolbar.activeTool == EditorToolType.warpPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.warpPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              tooltip: 'Gameplay Zone Tool',
              selected:
                  toolbar.activeTool == EditorToolType.gameplayZonePlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.gameplayZonePlacement,
              ),
            ),
          ],
        ),
      if (showContextStrip)
        _groupItem(
          context,
          overflowLabel: 'Context',
          children: [
            if (showTerrainTypePulldown)
              ToolbarCapsulePulldown(
                label: _terrainTypeLabel(toolbar.selectedTerrainType),
                items: _terrainPulldownItems(notifier),
              ),
            if (showEntityKindPulldown)
              ToolbarCapsulePulldown(
                label: _entityKindLabel(toolbar.selectedEntityKind),
                items: _entityKindPulldownItems(notifier),
              ),
          ],
        ),
      _groupItem(
        context,
        overflowLabel: 'View',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.minus_circle,
            tooltip: 'Zoom Out',
            onPressed: () => notifier.zoom(-0.1),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.plus_circle,
            tooltip: 'Zoom In',
            onPressed: () => notifier.zoom(0.1),
          ),
        ],
      ),
      const ToolBarSpacer(spacerUnits: 4),
      if (toolbar.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                EditorChrome.badgeFill(context),
                EditorChrome.chipFill(context),
                0.45,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              toolbar.statusMessage!,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          inOverflowedBuilder: (_) => const ToolbarOverflowMenuItem(
            label: 'Status',
            onPressed: null,
          ),
        ),
    ];

    return ToolBar(
      title: TopToolbarBrand(
        projectName: toolbar.project?.name,
        workspaceLabel: switch (toolbar.workspaceMode) {
          EditorWorkspaceMode.map => 'World Editor',
          EditorWorkspaceMode.tileset => 'Tileset Studio',
          EditorWorkspaceMode.trainer => 'Trainer Studio',
          EditorWorkspaceMode.pokedex => 'Pokédex',
          EditorWorkspaceMode.globalStory => 'Global Story',
          EditorWorkspaceMode.step => 'Step Studio',
          EditorWorkspaceMode.cutscene => 'Cutscene Studio',
          EditorWorkspaceMode.dialogue => 'Dialogue Studio',
        },
      ),
      titleWidth: 236,
      automaticallyImplyLeading: false,
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dividerColor: MacosColors.transparent,
      decoration: BoxDecoration(
        color: EditorChrome.toolbarBarFill(context),
      ),
      actions: actions,
    );
  }

  static CustomToolbarItem _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
  }) {
    return CustomToolbarItem(
      inToolbarBuilder: (_) => ToolbarCapsuleGroup(children: children),
      inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
        label: overflowLabel,
        onPressed: null,
      ),
    );
  }

  static String _terrainTypeLabel(TerrainType type) {
    return switch (type) {
      TerrainType.none => 'None',
      TerrainType.grass => 'Grass Base',
      TerrainType.dirt => 'Dirt Base',
      TerrainType.sand => 'Sand Base',
      TerrainType.rock => 'Rock Base',
      TerrainType.stone => 'Stone Base',
      TerrainType.indoor => 'Indoor Base',
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }
}

```


### Fichier: `packages/map_editor/test/editor_selectors_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('editor selectors', () {
    test('editorShellSnapshotProvider derives map title and save affordance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 12, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        canUndoMap: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Starter Town');
      expect(shell.workspaceSubtitle, contains('12 x 8 tiles'));
      expect(shell.canUndoMap, isTrue);
      expect(shell.canSaveMap, isTrue);
    });

    test('editorToolbarSnapshotProvider resolves selected tileset from layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
      );

      final toolbar = container.read(editorToolbarSnapshotProvider);
      expect(toolbar.selectedTilesetEntry?.id, 'world');
      expect(toolbar.activeLayer, isA<TileLayer>());
    });

    test('editorProjectExplorerSnapshotProvider exposes active map selection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
      );

      final snapshot = container.read(editorProjectExplorerSnapshotProvider);
      expect(snapshot.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(snapshot.activeMapId, 'town');
      expect(snapshot.project?.name, 'demo');
    });

    test('editorShellSnapshotProvider exposes trainer studio labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.trainer,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Trainer Studio');
      expect(
        shell.workspaceSubtitle,
        contains('battle-ready rosters'),
      );
    });

    test('editorTerrainLibrarySnapshotProvider exposes preset selection inputs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        selectedTerrainType: TerrainType.grass,
        selectedTerrainPresetId: 'terrain.grass',
        selectedPathPresetId: 'path.route',
      );

      final snapshot = container.read(editorTerrainLibrarySnapshotProvider);
      expect(snapshot.project?.name, 'demo');
      expect(snapshot.tilesets.map((entry) => entry.id), ['world']);
      expect(snapshot.selectedTerrainPresetId, 'terrain.grass');
      expect(snapshot.selectedPathPresetId, 'path.route');
    });

    test('editorTilesetPaletteSnapshotProvider exposes palette panel state',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        paletteCategoryFilter: PaletteCategory.floors,
        selectedTilesetElementGroupId: 'group_a',
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
        selectedPlacedElementInstanceId: 'instance_1',
      );

      final snapshot = container.read(editorTilesetPaletteSnapshotProvider);
      expect(snapshot.selectedTilesetEntry?.id, 'world');
      expect(snapshot.projectRootPath, '/tmp/project');
      expect(snapshot.activeLayerId, 'ground');
      expect(snapshot.paletteCategoryFilter, PaletteCategory.floors);
      expect(
        snapshot.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      expect(snapshot.selectedPlacedElementInstanceId, 'instance_1');
    });
  });
}

```


### Fichier: `packages/map_editor/test/editor_shell_page_smoke_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}

```


### Fichier: `packages/map_editor/test/editor_workspace_controller_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/editor_workspace_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorWorkspaceController', () {
    const controller = EditorWorkspaceController();

    test('selectPokedexWorkspace switches mode and clears stale errors', () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
      );

      final next = controller.selectPokedexWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, current.statusMessage);
    });

    test('selectTrainerWorkspace switches mode and clears stale errors', () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
      );

      final next = controller.selectTrainerWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.trainer);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, current.statusMessage);
    });

    test('selectDialogueWorkspace keeps project session and only changes mode',
        () {
      const current = EditorState(
        projectRootPath: '/tmp/demo',
        workspaceMode: EditorWorkspaceMode.cutscene,
      );

      final next = controller.selectDialogueWorkspace(current);

      expect(next.projectRootPath, '/tmp/demo');
      expect(next.workspaceMode, EditorWorkspaceMode.dialogue);
    });
  });
}

```


### Fichier: `packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';
import 'package:map_editor/src/application/services/pokemon_items_catalog_lookup_service.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';

void main() {
  const service = PokemonItemsCatalogLookupService();

  group('PokemonItemsCatalogLookupService', () {
    test('reuses the shared progressive local catalog lookup service', () {
      expect(
        service,
        isA<
            ProgressiveLocalCatalogLookupService<
                PokemonItemCatalogEntryView>>(),
      );
    });

    test('finds an item by its exact local id', () {
      final entry = service.findById(_entries, 'oran_berry');

      expect(entry, isNotNull);
      expect(entry!.name, 'Oran Berry');
    });

    test('searches by item label, id and aliases', () {
      final labelResults = service.search(_entries, 'leftovers');
      final idResults = service.search(_entries, 'oran');
      final aliasResults = service.search(_entries, 'berry');

      expect(labelResults.first.id, 'leftovers');
      expect(idResults.first.id, 'oran_berry');
      expect(aliasResults.map((entry) => entry.id), contains('oran_berry'));
    });
  });
}

const List<PokemonItemCatalogEntryView> _entries =
    <PokemonItemCatalogEntryView>[
  PokemonItemCatalogEntryView(
    id: 'oran_berry',
    name: 'Oran Berry',
    aliases: <String>['oran', 'berry'],
    shortDesc: 'Heals 10 HP.',
  ),
  PokemonItemCatalogEntryView(
    id: 'leftovers',
    name: 'Leftovers',
    aliases: <String>['lefties'],
    shortDesc: 'Restores HP every turn.',
  ),
];

```


### Fichier: `packages/map_editor/test/top_toolbar_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Pokédex'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });

    testWidgets('shows the trainer studio label for the trainer workspace',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_trainer',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
    });
  });
}

```


### Fichier: `packages/map_editor/test/trainer_library_panel_test.dart`

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
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-field')),
      'growl',
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
      'oran_berry',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
      'blossom',
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.dragUntilVisible(
      savePokemonButton,
      find.byKey(const Key('trainer-library-editor-scroll')),
      const Offset(0, -220),
    );
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
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.dragUntilVisible(
      savePokemonButton,
      find.byKey(const Key('trainer-library-editor-scroll')),
      const Offset(0, -220),
    );
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
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
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
        'Aucune suggestion de forme locale disponible pour cette espèce. La saisie brute reste possible.',
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

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
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
        'Impossible de vérifier les formes locales pour cette espèce. La saisie brute reste possible.',
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
        'Impossible de charger le catalogue local des attaques.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Impossible de charger le catalogue local des objets.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
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

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.dragUntilVisible(
      savePokemonButton,
      find.byKey(const Key('trainer-library-editor-scroll')),
      const Offset(0, -220),
    );
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
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
    learnset: const PokemonLearnsetFile(
      speciesId: 'bulbasaur',
      startingMoves: <String>['tackle'],
    ),
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
