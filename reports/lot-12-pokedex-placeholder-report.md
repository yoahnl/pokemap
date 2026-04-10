# Lot 12 - Tuile Pokédex vide

## A. Résumé exécutif

Ce lot ajoute exactement trois choses dans l'éditeur :

- une entrée UI `Pokédex` visible dans la colonne gauche
- une navigation vers un workspace central dédié
- un écran placeholder honnête et volontairement vide

Ce lot ne fait pas :

- aucune lecture de données Pokémon
- aucun appel à `PokemonDatabaseIndex`
- aucun provider / notifier / controller / state Pokédex
- aucune liste d'espèces
- aucune recherche, filtre, tab, vue détail ou bouton d'import
- aucune modification de `project.json`
- aucune modification des modèles, services ou repositories Pokémon existants

Le scope a été maintenu minimal pour respecter l'objectif exact du lot 12 :
faire exister le point d'entrée Pokédex dans l'UI, puis s'arrêter immédiatement.

## B. Audit de l'existant

### Où la navigation est branchée

L'audit a montré que la navigation principale de l'éditeur repose sur `EditorWorkspaceMode` dans :

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

Le pattern existant est :

- l'état central stocke un `workspaceMode`
- le notifier expose des méthodes `select...Workspace()`
- `EditorCanvasHost` route le contenu central selon le mode
- `EditorShellPage` adapte le titre, le sous-titre et l'habillage selon ce mode
- la toolbar permet aussi de changer de workspace

### Où les tuiles / entrées de l'éditeur sont déclarées

L'audit a montré que la colonne gauche utilise `ProjectExplorerPanel` avec des `InspectorSectionCard` expansibles.

Les grandes entrées déjà présentes sont par exemple :

- `Tileset Library`
- `Narrative Studio`
- `World Maps`
- `Terrain Library`
- `Path Library`
- `Trainer Library`
- `Character Library`

Le pattern interne le plus proche pour une navigation légère est :

- une `InspectorSectionCard`
- un contenu simple
- une ou plusieurs lignes `EditorSidebarListRow`

### Quel pattern a été retenu

Le pattern retenu est :

1. ajouter une nouvelle `InspectorSectionCard` dans `ProjectExplorerPanel`
2. y mettre une seule ligne `EditorSidebarListRow`
3. brancher cette ligne sur une méthode simple `selectPokedexWorkspace()`
4. router le centre vers un widget placeholder dédié

### Pourquoi c'est le bon pattern ici

C'est le bon pattern parce que :

- il est déjà utilisé par l'explorateur existant
- il évite d'inventer une nouvelle convention de navigation
- il garde le Pokédex au même niveau produit que les autres grandes bibliothèques / studios
- il permet un diff petit, lisible et reviewable

### Quels autres patterns ont été écartés

Patterns écartés :

- ajouter un provider Pokédex : rejeté, hors scope
- ajouter un notifier / state dédié : rejeté, hors scope
- brancher une vraie liste vide façon lot 13 : rejeté, faux départ fonctionnel
- créer un nouveau router local : rejeté, abstraction spéculative
- injecter un service Pokémon dans l'UI : rejeté, couplage inutile et interdit par le lot
- réutiliser `NarrativeWorkspaceCanvas` ou un autre canvas existant : rejeté, mauvais sens produit

## C. Périmètre inclus

Implémenté factuellement :

- ajout de `EditorWorkspaceMode.pokedex`
- ajout de `EditorNotifier.selectPokedexWorkspace()`
- ajout d'une tuile `Pokédex` dans `ProjectExplorerPanel`
- ajout d'un bouton de navigation Pokédex dans la toolbar workspace
- ajout d'un placeholder central `PokedexPlaceholderWorkspace`
- adaptation de `EditorCanvasHost` pour router vers ce placeholder
- adaptation de `EditorShellPage` pour afficher titre, sous-titre et habillage cohérents
- ajout de tests widget ciblés sur présence + navigation + indépendance vis-à-vis d'un chargement réel

## D. Périmètre exclu

Volontairement non touché :

- `PokemonDatabaseIndex`
- `PokemonProjectDataReader`
- `PokemonReadRepository`
- `PokemonWriteRepository`
- les modèles Pokémon existants
- les use cases Pokédex existants côté application
- tout import externe
- tout runtime
- toute sauvegarde
- `project.json`
- toute liste réelle d'espèces
- toute logique asynchrone Pokédex
- tout faux écran riche ou pseudo-tableau

## E. Liste exacte des fichiers modifiés

### Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
  - placeholder central du lot 12
- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`
  - tests widget ciblés du lot 12
- `reports/lot-12-pokedex-placeholder-report.md`
  - rapport détaillé de cette intervention

### Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
  - ajout du mode `pokedex`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - ajout de la méthode de navigation `selectPokedexWorkspace()`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
  - routage du mode `pokedex` vers le placeholder
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
  - titre, sous-titre, icône, badge et inspecteur neutre pour le mode `pokedex`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
  - bouton de bascule vers le Pokédex dans la toolbar
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
  - nouvelle tuile Pokédex dans l'explorateur

## F. Justification fichier par fichier

### `editor_state.dart`

Pourquoi touché :

- il fallait un mode de workspace explicite pour brancher une vraie destination UI

Pourquoi c'était nécessaire :

- sans ce mode, il n'existait aucun point d'ancrage cohérent pour la navigation centrale

Pourquoi cela reste dans le lot 12 :

- c'est une simple valeur d'état UI, sans logique métier ni lecture de données

### `editor_notifier.dart`

Pourquoi touché :

- il fallait reproduire le pattern existant `select...Workspace()`

Pourquoi c'était nécessaire :

- la navigation de l'éditeur passe déjà par ce notifier

Pourquoi cela reste dans le lot 12 :

- la méthode ne fait qu'une bascule de mode
- elle n'appelle aucun service Pokémon

### `editor_canvas_host.dart`

Pourquoi touché :

- il fallait afficher quelque chose dans l'îlot central quand `workspaceMode == pokedex`

Pourquoi c'était nécessaire :

- c'est le routeur central déjà en place

Pourquoi cela reste dans le lot 12 :

- le routage cible un placeholder statique, sans logique lourde

### `pokedex_placeholder_workspace.dart`

Pourquoi touché :

- il fallait un écran placeholder explicite, lisible et honnête

Pourquoi c'était nécessaire :

- le lot exige un écran visible et navigable

Pourquoi cela reste dans le lot 12 :

- aucune donnée affichée
- aucune fausse liste
- aucun bouton non branché
- aucun chargement

### `editor_shell_page.dart`

Pourquoi touché :

- le shell central affiche le titre, le sous-titre, l'icône et l'inspecteur droit selon le workspace actif

Pourquoi c'était nécessaire :

- sans cela, le nouveau mode aurait été incohérent ou incomplet visuellement

Pourquoi cela reste dans le lot 12 :

- il s'agit seulement d'habillage et de cohérence du shell
- l'inspecteur ajouté est volontairement neutre, pas un faux inspecteur Pokédex

### `top_toolbar.dart`

Pourquoi touché :

- la toolbar propose déjà des raccourcis de bascule entre workspaces

Pourquoi c'était nécessaire :

- l'audit a montré que ce pattern de navigation existe déjà

Pourquoi cela reste dans le lot 12 :

- simple entrée de navigation supplémentaire
- aucun service ni état dédié

### `project_explorer_panel.dart`

Pourquoi touché :

- c'est l'endroit où vivent déjà les grandes tuiles / sections de l'éditeur

Pourquoi c'était nécessaire :

- la consigne produit demande explicitement une nouvelle entrée visible dans l'éditeur

Pourquoi cela reste dans le lot 12 :

- une seule tuile
- une seule ligne cliquable
- un texte d'explication honnête
- pas de compteur, pas de données, pas de structure future déguisée

### `pokedex_placeholder_ui_test.dart`

Pourquoi touché :

- le lot demandait des tests proportionnés et strictement UI

Pourquoi c'était nécessaire :

- verrouiller la présence de la tuile
- verrouiller la navigation
- verrouiller l'absence de dépendance à un chargement Pokémon réel

Pourquoi cela reste dans le lot 12 :

- aucun test métier Pokémon
- aucun test de repository
- aucun test de service d'index

## G. UX produite

### Où apparaît la tuile

La tuile apparaît dans `ProjectExplorerPanel`, au même niveau que les autres grandes briques de l'éditeur, juste après `Tileset Library`.

### Comment on y navigue

Deux chemins existent :

- via la tuile `Pokédex` dans l'explorateur
- via le bouton `Pokédex` dans la toolbar workspace

### Ce que contient le placeholder

Le placeholder contient :

- un titre clair `Pokédex`
- un texte expliquant que cette section deviendra plus tard le point d'entrée du contenu Pokémon du projet
- une mention explicite que le vrai contenu détaillé arrivera dans les prochains lots

### Pourquoi cette UX est correcte pour un lot vide

Parce qu'elle :

- rend l'entrée visible
- la rend ouvrable
- ne ment pas sur l'état réel du produit
- ne simule pas une feature déjà prête

## H. Tests

Tests ajoutés :

- `ProjectExplorerPanel shows a Pokédex entry tile`
- `tapping the Pokédex entry opens the placeholder workspace`

Pourquoi ils suffisent :

- ils couvrent précisément les critères du lot
- ils prouvent que l'entrée existe
- ils prouvent que la navigation bascule bien de mode
- ils prouvent que le placeholder s'affiche avec un `ProjectManifest` minimal en mémoire, donc sans chargement Pokémon réel

Pourquoi il n'y en a pas plus :

- le lot ne contient pas de logique métier
- le lot ne contient pas de flux de données
- ajouter plus de tests aurait commencé à tester le lot 13 ou des détails de structure internes sans valeur directe

## I. Vérification des critères d'acceptation

- `OK` la tuile existe
- `OK` la navigation fonctionne
- `OK` aucun chargement de données Pokémon n'a été ajouté
- `OK` aucune logique lourde n'a été ajoutée

## J. Commandes réellement exécutées

### Recherches codebase / audit

- `rg "Pok[eé]dex|Pokedex" packages/map_editor --glob "*.dart"`
- `rg "NavigationRail|Drawer|Sidebar|ListTile\\(|GridView|Card\\(|go_router|Navigator\\.|onTap:|route|Route" packages/map_editor/lib --glob "*.dart"`
- `rg "placeholder|EmptyState|empty state|coming soon|TODO|not yet|bientot|prochain|future lot" packages/map_editor/lib --glob "*.dart"`
- `rg "WidgetTester|pumpWidget|tap\\(|find\\.text\\(|find\\.byType\\(|NavigationRail|Navigator" packages/map_editor/test --glob "*.dart"`
- `rg "Dialogue Library|Tileset Library|Trainer Library|Character Library|Encounter|Project Explorer|Cutscene|Global Story|Step Studio|Terrain Editor" packages/map_editor/lib --glob "*.dart"`
- `rg "enum .*View|selected.*Panel|activePanel|selectedSection|workspaceKind|EditorMode|SidebarItem|EditorSidebarListRow" packages/map_editor/lib --glob "*.dart"`
- `rg "selectMapWorkspace|selectTilesetWorkspace|selectGlobalStoryWorkspace|selectStepWorkspace|selectCutsceneWorkspace|selectDialogueWorkspace" packages/map_editor/lib/src/features/editor/state/editor_notifier.dart --glob "*.dart"`
- `rg "NarrativeLibraryPanel\\(|TrainerLibraryPanel\\(|CharacterLibraryPanel\\(|TerrainEditorPanel\\(" packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart --glob "*.dart"`
- `rg "ProviderScope\\(|UncontrolledProviderScope\\(|ProviderContainer\\(|editorNotifierProvider" packages/map_editor/test --glob "*.dart"`
- `rg "EditorShellPage|ProjectExplorerPanel|EditorCanvasHost|workspaceMode" packages/map_editor/test --glob "*.dart"`

### Commandes shell

- `git status --short`
- `ls "/Users/karim/.cursor/projects/Users-karim-Project-pokemonProject/terminals"`
- `ls`
- `dart format "packages/map_editor/lib/src/features/editor/state/editor_state.dart" "packages/map_editor/lib/src/features/editor/state/editor_notifier.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/editor_shell_page.dart" "packages/map_editor/lib/src/ui/shared/top_toolbar.dart" "packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"`
- `flutter test test/pokedex_placeholder_ui_test.dart`
- `flutter analyze lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/pokedex_placeholder_workspace.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/panels/project_explorer_panel.dart test/pokedex_placeholder_ui_test.dart`
- `dart format "packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart" "packages/map_editor/lib/src/ui/shared/top_toolbar.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"`
- `dart format "packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"`
- `git diff --stat`
- `git diff -- "packages/map_editor/lib/src/features/editor/state/editor_state.dart" "packages/map_editor/lib/src/features/editor/state/editor_notifier.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/editor_shell_page.dart" "packages/map_editor/lib/src/ui/shared/top_toolbar.dart" "packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"`

## K. Résultats réels

### Analyse initiale

Première exécution de l'analyse ciblée :

- a remonté un import manquant dans `project_explorer_panel.dart`
- a remonté un `switch` non exhaustif dans `top_toolbar.dart`
- a remonté quelques suggestions `const`

Ces points ont été corrigés immédiatement.

### Première tentative de test

Première exécution de `flutter test` en parallèle avec d'autres commandes :

- a échoué avec un verrou Flutter / problème d'ephemeral :
  `Waiting for another flutter command to release the startup lock...`

Lecture honnête :

- il s'agissait d'un bruit d'outillage lié à l'exécution parallèle
- cela ne provenait pas du code produit

### Deuxième tentative de test

Première exécution séquentielle du test :

- a révélé deux défauts réels de testabilité
- texte `Pokédex` trouvé en double
- tap trop ambigu sur la mauvaise cible

Correction appliquée :

- ajout d'une `Key` locale sur la ligne navigable
- ajout d'une `Key` locale sur le placeholder central

### Résultat final des tests

Commande :

`flutter test test/pokedex_placeholder_ui_test.dart`

Résultat réel :

```text
00:02 +2: All tests passed!
```

### Résultat final de l'analyse

Commande :

`flutter analyze lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/pokedex_placeholder_workspace.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/panels/project_explorer_panel.dart test/pokedex_placeholder_ui_test.dart`

Résultat réel :

```text
Analyzing 8 items...
No issues found! (ran in 1.6s)
```

### Lints IDE

Résultat réel :

- aucun problème de linter IDE sur les fichiers modifiés

## L. État Git

### `git status --short`

Sortie réelle au moment du relevé avant création de ce rapport :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart
?? packages/map_editor/test/pokedex_placeholder_ui_test.dart
```

### `git diff --stat`

Sortie réelle au moment du relevé avant création de ce rapport :

```text
 .../src/features/editor/state/editor_notifier.dart | 16 ++++++
 .../src/features/editor/state/editor_state.dart    | 13 +++++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  5 ++
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 48 ++++++++++++++++
 .../lib/src/ui/panels/project_explorer_panel.dart  | 65 ++++++++++++++++++++++
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 17 +++++-
 6 files changed, 162 insertions(+), 2 deletions(-)
```

Lecture honnête :

- `git diff --stat` n'affiche pas les nouveaux fichiers non suivis
- il faut donc le lire avec `git status --short`
- le diff reste local à la navigation UI, au placeholder et aux tests ciblés
- il n'y a pas de diffusion dans les couches Pokémon métier

## M. Limites restantes

Ce qui relève explicitement du lot 13 ou plus :

- afficher la liste des espèces
- brancher un vrai index de données Pokémon
- afficher numéro / nom / types / refs
- ajouter recherche / filtres / tabs
- ajouter vue détail
- ajouter gestion loading / empty / error liée à de vraies données
- brancher imports / overrides / médias / learnsets / évolutions

Ce qui reste volontairement non traité maintenant :

- tout provider Pokédex
- tout état Pokédex dédié
- tout service Pokédex UI
- toute lecture du filesystem Pokémon
- toute façade applicative UI autour du Pokédex

Ce qu'il ne faut pas faire maintenant :

- transformer le placeholder en pseudo-liste vide
- brancher `PokemonDatabaseIndex` "juste pour préparer la suite"
- créer un faux tableau avec colonnes
- ajouter des boutons d'action non branchés

## N. Conclusion honnête

Le lot 12 a été implémenté comme une entrée UI vide proprement branchée, et rien de plus.

Le résultat final est :

- la tuile `Pokédex` est visible dans l'éditeur
- elle est navigable
- elle ouvre un placeholder central clair
- ce placeholder ne charge rien
- aucune logique Pokémon lourde n'a été introduite

Le diff reste concentré sur :

- point d'entrée UI
- navigation
- placeholder
- tests widget ciblés
- rapport

Le lot 13 n'a pas été commencé.

## Checklist d'auto-contrôle

### Checklist de scope

- `OK` J’ai bien ajouté une entrée Pokédex visible dans l’éditeur
- `OK` Cette entrée est bien navigable
- `OK` Cette navigation ouvre un écran placeholder
- `OK` Le placeholder est sobre, lisible et honnête
- `OK` Je n’ai affiché aucune vraie donnée Pokémon
- `OK` Je n’ai appelé aucun service de lecture Pokémon
- `OK` Je n’ai appelé ni repository Pokémon ni `PokemonDatabaseIndex`
- `OK` Je n’ai ajouté aucun provider / notifier / controller / state dédié au Pokédex
- `OK` Je n’ai pas commencé la liste du lot 13
- `OK` Je n’ai pas ajouté de recherche, filtres, colonnes ou faux tableau
- `OK` Je n’ai pas modifié `project.json`
- `OK` Je n’ai pas modifié les modèles Pokémon existants
- `OK` Je n’ai pas modifié le runtime
- `OK` Je n’ai pas modifié l’import
- `OK` Je n’ai pas modifié la sauvegarde

### Checklist d’architecture

- `OK` J’ai d’abord audité l’existant avant de coder
- `OK` J’ai réutilisé le pattern de navigation déjà en place
- `OK` J’ai réutilisé le pattern UI déjà en place si possible
- `OK` Je n’ai pas inventé de nouvelle abstraction pour ce lot
- `OK` Le diff est resté petit et local

### Checklist de qualité

- `OK` Le code est formaté
- `OK` Les tests ciblés passent
- `OK` L’analyse statique ciblée passe
- `OK` Le rapport markdown a bien été créé
- `OK` Les commentaires dans le code expliquent pourquoi le lot reste minimal
- `OK` Aucune commande Git d’écriture n’a été exécutée

### Checklist d’honnêteté

- `OK` Je n’ai pas survendu le résultat
- `OK` Je n’ai pas prétendu avoir commencé le vrai Pokédex
- `OK` J’ai documenté clairement ce qui relève du lot 13
- `OK` J’ai signalé les limites restantes de façon explicite
