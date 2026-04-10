# Audit technique complet de `map_editor`

Date: 2026-04-10
Périmètre principal: [`/Users/karim/Project/pokemonProject/packages/map_editor`](/Users/karim/Project/pokemonProject/packages/map_editor)
Périmètre secondaire: [`/Users/karim/Project/pokemonProject/packages/map_core`](/Users/karim/Project/pokemonProject/packages/map_core), [`/Users/karim/Project/pokemonProject/packages/map_runtime`](/Users/karim/Project/pokemonProject/packages/map_runtime), [`/Users/karim/Project/pokemonProject/examples/playable_runtime_host`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host)

## Résumé exécutif

L’application ne respecte pas réellement une Clean Architecture stricte, même si elle en reprend le vocabulaire et certains seams. La base est exploitable et contient plusieurs bonnes décisions locales, mais le centre de gravité réel du code est aujourd’hui un éditeur desktop fortement orchestré autour d’un `EditorNotifier` massif, d’un `EditorState` trop large et d’une présentation qui absorbe encore beaucoup de logique d’intégration.

Les forces majeures sont:
- une vraie séparation package-level entre `map_core`, `map_editor` et `map_runtime`;
- quelques frontières utiles et concrètes, notamment `ProjectWorkspace`, les repositories filesystem, et les briques Pokémon récentes mieux encapsulées;
- un usage généralisé de l’immuabilité côté état principal via Freezed;
- une partie du code d’édition qui reste testable parce qu’elle s’appuie sur des opérations pures venant de `map_core`.

Les faiblesses majeures sont:
- `EditorNotifier` joue à la fois le rôle de store global, façade applicative, orchestrateur d’I/O, coordinateur de session, gestionnaire de messages UI et point de mutation quasi universel;
- Riverpod est utilisé surtout comme conteneur de wiring et service locator typé, beaucoup moins comme graphe d’état réactif idiomatique;
- la présentation possède encore des responsabilités applicatives et infrastructurelles franches;
- l’application mélange une vraie DI propre à la racine avec des contournements directs depuis les widgets;
- les gros fichiers UI et le watch très large du state feront mal à mesure que le produit grossira.

Verdict franc: la base n’est pas “mauvaise”, mais elle est déjà engagée dans une pente d’entropie. Je ne recommanderais pas cette architecture telle quelle à une équipe senior en production sans plan explicite de refonte ciblée sur l’orchestration d’état, la granularité Riverpod et l’extraction des side effects hors widgets.

## Note globale argumentée

| Axe | Note / 10 | Commentaire |
| --- | --- | --- |
| Clean Architecture | 5.0 | Le vocabulaire des couches existe, mais les dépendances réelles et les fuites de responsabilités cassent la promesse. |
| Usage de Riverpod | 4.5 | Riverpod est présent partout, mais souvent comme service locator et non comme système de composition d’état moderne. |
| Séparation des responsabilités | 4.0 | Les frontières existent sur le papier, mais l’orchestration fuit vers `EditorNotifier` et plusieurs widgets. |
| Maintenabilité | 4.5 | Les très gros fichiers et la centralisation excessive rendent le coût de changement déjà élevé. |
| Robustesse | 5.5 | Le projet résiste à plusieurs cas d’erreur simples, mais une part trop grande de la robustesse dépend de conventions implicites et de catches silencieux. |
| Scalabilité | 4.0 | Le design actuel passera mal à l’échelle en nombre de workspaces, d’outils et de flows asynchrones. |
| Lisibilité | 4.0 | Plusieurs îlots sont lisibles, mais l’ensemble souffre de fichiers géants, de wiring massif et de responsabilités superposées. |
| Cohérence globale | 5.0 | La direction produit est claire, mais l’implémentation actuelle mélange plusieurs styles architecturaux sans doctrine assez ferme. |

## Ce qui est bon

### 1. Le découpage package-level est sain

Le monorepo a une séparation utile entre authoring, runtime et modèles partagés.

Exemples:
- [`packages/map_editor/lib/main.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/main.dart)
- [`packages/map_core/lib/src/models/project_manifest.dart`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart)
- [`packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart)

Cette séparation est une vraie force. Elle évite déjà plusieurs couplages qui auraient sinon été catastrophiques.

### 2. La racine DI minimale est propre

[`core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart) est l’une des zones les plus saines du projet:
- les repositories concrets y sont câblés simplement;
- `ProjectWorkspaceFactory` y est exposé proprement;
- il n’y a pas de mélange `get_it` / Riverpod;
- le container global n’est pas “magique” à cet endroit.

Ce fichier montre ce que le projet pourrait être s’il appliquait cette discipline plus loin.

### 3. `ProjectWorkspace` est un bon seam

Le contrat [`project_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/project_workspace.dart) et son implémentation [`project_filesystem.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart) sont une bonne idée:
- ils ancrent le travail dans le workspace projet;
- ils évitent de tout reconstruire depuis `Directory.current`;
- ils rendent testable une part importante du code auteur.

Le seam n’est pas encore utilisé partout avec rigueur, mais lui-même est bon.

### 4. Les lots Pokémon récents sont globalement plus propres que le legacy éditeur

Le lecteur local Pokémon et certains use cases récents sont plus disciplinés que le reste:
- [`pokemon_project_data_reader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart)
- [`pokemon_read_repository.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart)
- [`pokemon_database_index.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart)
- [`list_pokedex_entries_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart)
- [`pokemon_project_validator.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart)

Ce sous-système n’est pas parfait, mais il montre une architecture plus contrôlée: port, impl infrastructure, service/use case ciblé, invariants workspace explicites.

### 5. Certaines décisions UI sont bonnes localement

Exemple utile: [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart) garde le hover local au widget plutôt que de publier chaque mouvement via Riverpod. C’est le bon instinct pour un état purement visuel à haute fréquence.

## Ce qui est acceptable mais perfectible

### 1. Les repositories filesystem valident et migrent

[`file_repositories.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart) fait à la fois:
- lecture/écriture disque;
- migration legacy;
- validation.

Ce n’est pas idéal, mais ce n’est pas absurde non plus pour un éditeur local. Le vrai problème n’est pas ici en premier; le vrai problème est l’absence de frontière systématique plus haut.

### 2. Le use case layer n’est pas entièrement inutile

Il y a deux familles de use cases:

Les utiles:
- [`map_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/map_use_cases.dart) orchestre vraiment repo + workspace + modèle.

Les anémiques:
- [`entity_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart) encapsule surtout des fonctions `map_core` avec validation.

Ce n’est pas forcément un bug d’avoir des use cases minces, mais le mélange brouille la doctrine: parfois “use case” signifie vraie orchestration, parfois simple wrapper nominal.

### 3. La séparation de l’état narratif hors `EditorState` est une bonne intuition

[`narrative_workspace_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart) évite d’ajouter encore plus de champs au state principal. C’est la bonne direction.

Le problème est que cette séparation est incomplète:
- le controller reste global au `ProviderScope` racine;
- la projection dépend du projet actif mais le controller, lui, n’est pas scoped au projet.

## Ce qui est problématique

### 1. La Clean Architecture est surtout nominale, pas réellement respectée

#### Le domain n’est pas la seule source de contrats

Les repositories “historiques” vivent dans:
- [`domain/repositories/repositories.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/domain/repositories/repositories.dart)

Mais d’autres frontières analogues vivent dans:
- [`application/ports/project_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/project_workspace.dart)
- [`application/ports/pokemon_read_repository.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart)

Ce n’est pas forcément faux, mais cela révèle que le “domain” n’est pas le cœur architectural unifié. Le centre de gravité réel est l’application, pas le domain.

#### L’application dépend de la présentation

[`terrain_preset_selection_coordinator.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart#L1) importe [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L1) pour utiliser `TerrainSelectionMode`.

Concrètement:
- `application/services/terrain_preset_selection_coordinator.dart:3`
- dépend de `features/editor/state/editor_state.dart`

Ce n’est pas un détail. Cela inverse la direction de dépendance attendue et prouve que les types “UI/workspace state” contaminent l’application.

#### L’application dépend de Flutter / `dart:ui`

[`entity_editor_element_visual.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart#L1) expose:
- `ui.Image`
- `Rect`

et importe:
- `dart:ui`
- `flutter/painting`

Le fichier a donc une responsabilité de rendu/image au sens Flutter dans la couche application. C’est une violation claire des frontières.

#### Des use cases applicatifs font du filesystem direct

Exemples:
- [`project_dialogue_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#L1)
- [`dialogue_disk_path_support.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/dialogue_disk_path_support.dart#L1)
- [`initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart#L1)
- [`seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart#L1)

Le cas le plus net:
- [`project_dialogue_use_cases.dart:89-92`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#L89)
- [`project_dialogue_use_cases.dart:295-296`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#L295)

Ces use cases passent directement par `File` alors qu’un seam `ProjectWorkspace` existe déjà.

Verdict: la Clean Architecture du projet est partielle et parfois contredite par le code concret.

### 2. `EditorNotifier` est un god object

Le constat principal du projet est là.

Preuves:
- taille: [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) fait **6951 lignes**
- wiring provider massif: [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart) fait **972 lignes**

Au début du notifier:
- [`editor_notifier.dart:45-79`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L45)

on trouve une longue liste de getters `ref.read(...)` qui transforment le notifier en point d’accès universel à:
- coordinators
- services
- use cases
- workspace factory
- repositories indirectement

Plus loin, presque toutes les actions utilisateur importantes vont lire un use case depuis `ref.read(...)`, par exemple:
- [`editor_notifier.dart:4682`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L4682)
- [`editor_notifier.dart:5512`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L5512)
- [`editor_notifier.dart:6542`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L6542)

Conséquences:
- testabilité dégradée;
- coût cognitif énorme;
- faible localité des changements;
- tout nouveau flow tend naturellement à finir ici;
- Riverpod devient un backend de ce god object au lieu d’une architecture d’état.

Ce n’est plus un notifier. C’est une couche application entière compressée dans un seul objet mutable.

### 3. `EditorState` mélange trop de natures d’état

[`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L62) agrège:
- contexte projet;
- workspace mode;
- map active;
- tool actif;
- sélections multiples;
- état viewport (`zoom`, `panOffset`);
- undo/redo;
- dirty/saving;
- messages UI (`statusMessage`, `errorMessage`);
- sélections Pokémon/dialogues/narrative/tileset/etc.

Exemples:
- [`editor_state.dart:67-75`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L67)
- [`editor_state.dart:118-126`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L118)
- [`editor_state.dart:128-147`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L128)

Ce design crée:
- un très large blast radius de rebuild;
- des états impossibles ou au moins douteux;
- un couplage artificiel entre état métier, état session, état purement UI, messages temporaires et viewport.

Le symptôme le plus concret est que `pan` et `zoom` modifient le même state global que celui regardé par le shell, la toolbar et les panels:
- [`editor_notifier.dart:6327-6333`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L6327)

### 4. Riverpod est sous-exploité et souvent utilisé comme service locator

#### Il y a très peu de vraie modélisation asynchrone Riverpod

Recherche structurelle dans `map_editor/lib`:
- un `AutoDisposeNotifierProvider` généré pour `EditorNotifier`
- un `StateNotifierProvider` manuel pour le workspace narratif
- pas de `FutureProvider`
- pas de `StreamProvider`
- pas d’`AsyncNotifier` structurant les flows asynchrones du projet

Concrètement, les flows async sont gérés:
- dans `EditorNotifier` à la main;
- dans les widgets via `FutureBuilder`;
- dans des `ConsumerStatefulWidget` avec `setState`, `ref.listen`, `postFrameCallback`.

Ce n’est pas idiomatique avec Riverpod moderne pour une app de cette taille.

#### Les widgets regardent trop souvent tout `EditorState`

Exemples:
- [`editor_shell_page.dart:74`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L74)
- [`top_toolbar.dart:56`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart#L56)
- [`status_bar.dart:13`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/status_bar.dart#L13)
- [`editor_canvas_host.dart:16`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart#L16)
- [`project_explorer_panel.dart:376`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart#L376)
- [`terrain_editor_panel.dart:28`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart#L28)
- [`tileset_palette_panel.dart:309`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart#L309)

Le problème n’est pas Riverpod. Le problème est la granularité choisie.

#### `ref.listen` et side effects dans `build`

[`editor_shell_page.dart:110-122`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L110) installe des `ref.listen(...)` pour `errorMessage` et `statusMessage` directement dans `build`.

Riverpod le supporte, mais ce pattern reste fragile quand il se multiplie, surtout dans un shell déjà très central.

#### Le wiring provider devient un container massif

[`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart) agrège une quantité énorme de câblage. Ce n’est pas encore un anti-pattern fatal, mais c’est déjà une DI centralisée trop volumineuse et peu feature-scoped.

Verdict Riverpod: usage globalement sérieux dans l’intention, mais pas encore moderne ni assez idiomatique pour une app qui grossit.

### 5. La présentation orchestre trop

#### `EditorShellPage` est plus qu’un shell

[`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart) gère:
- auto-restore du dernier projet via post-frame callback: [`editor_shell_page.dart:37-50`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L37)
- toasts temporisés: [`editor_shell_page.dart:59-70`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L59)
- écoute des messages globaux notifier -> toast: [`editor_shell_page.dart:110-122`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L110)
- dispatch de raccourcis globaux et comportement applicatif: [`editor_shell_page.dart:133-171`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L133)

Ce widget est déjà un mini app coordinator.

#### `DialogueStudioWorkspace` est un controller déguisé en widget

Le cas est franchement problématique.

Exemples:
- lecture disque directe et parsing Yarn: [`dialogue_studio_workspace.dart:107-158`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L107)
- `ref.listen` dans `build`: [`dialogue_studio_workspace.dart:166-174`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L166)
- fallback `postFrameCallback` dans `build`: [`dialogue_studio_workspace.dart:176-180`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L176)
- orchestration IA et client HTTP directement dans le widget: [`dialogue_studio_workspace.dart:1506-1553`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L1506), [`dialogue_studio_workspace.dart:1556-1642`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L1556)
- import via `FilePicker` piloté depuis le widget: [`dialogue_studio_workspace.dart:1851-1880`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L1851)

Ce widget cumule vue, orchestration, I/O disque, intégration réseau et gestion locale d’état riche. C’est trop.

#### D’autres workspaces narratifs suivent le même motif

Les workspaces `step`, `global story`, `cutscene` gèrent eux aussi de l’hydratation et de la synchronisation applicative dans l’état widget. Ce n’est pas aussi problématique que Dialogue Studio, mais la tendance est la même.

### 6. La DI est propre à la racine, puis contournée

Le projet a une composition root correcte dans `core_providers.dart`, mais elle n’est pas respectée de bout en bout.

Cas net:
- [`pokedex_workspace_loader.dart:32-33`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart#L32) crée `FileProjectRepository()` et `FilePokemonReadRepository()` dans un helper UI
- [`pokedex_workspace.dart:96-97`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart#L96) crée `ProjectFileSystem(projectRootPath)` dans un widget

Autres exemples de lecture disque directe en UI:
- [`character_library_panel.dart:23-38`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/character_library_panel.dart#L23)
- [`entity_properties_panel.dart:31-43`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart#L31)
- [`map_canvas.dart:2615`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart#L2615)

Cela ruine la cohérence du câblage global et multiplie les endroits à mocker/tester.

### 7. Les gros fichiers ne sont plus seulement un problème esthétique

Tailles relevées:
- [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart): 6951 lignes
- [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart): 972 lignes
- [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart): 2354 lignes
- [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart): 5105 lignes
- [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart): 7573 lignes
- [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart): 2013 lignes

À ce niveau, le problème n’est plus “le style”. Le problème est:
- la review devient superficielle;
- les regressions se cachent dans des fichiers saturés;
- les responsabilités s’entremêlent mécaniquement;
- personne ne peut tenir ces fichiers proprement à long terme.

### 8. La couche infra/réseau est inégale

#### Infra locale filesystem: plutôt propre

Les repositories locaux et `ProjectFileSystem` sont globalement honnêtes et lisibles:
- [`file_repositories.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart)
- [`project_filesystem.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart)

#### Intégration réseau: minimale et non industrialisée

L’unique vraie intégration HTTP côté éditeur est:
- [`mistral_dialogue_client.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart)

Problèmes:
- client instancié directement dans le widget, pas derrière un seam applicatif stable;
- pas de timeout explicite;
- pas de retry;
- pas de cancellation;
- pas d’observabilité structurée;
- gestion d’erreur minimale;
- clé API potentiellement stockée dans `project.json`.

Le commentaire de [`project_manifest.dart:91-95`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart#L91) reconnaît lui-même le risque:
- `mistralApiKey` stockée dans `project.json`

Ce n’est pas acceptable tel quel pour un produit distribué ou collaboratif.

## Ce qui est franchement une erreur d’architecture

### 1. Application -> presentation dependency

[`terrain_preset_selection_coordinator.dart:3`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart#L3) important un type de `editor_state.dart` n’est pas un simple compromis pragmatique. C’est une erreur de direction de dépendance.

### 2. Application -> Flutter rendering types

[`entity_editor_element_visual.dart:1-5`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart#L1) place des `ui.Image` dans l’application. C’est une erreur de frontière claire.

### 3. UI qui instancie directement l’infrastructure malgré un composition root existant

[`pokedex_workspace_loader.dart:32-33`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart#L32) et [`pokedex_workspace.dart:96`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart#L96) sont des contournements explicites du système d’injection déjà en place. Ici aussi, ce n’est pas qu’une question de goût.

## Audit détaillé par couche

### Présentation

Verdict: la présentation respecte partiellement son rôle sur les surfaces simples, mais plusieurs widgets sont devenus des mini-couches applicatives.

Constats:
- `ConsumerWidget` / `ConsumerStatefulWidget` bien répartis, mais trop souvent branchés sur le state global complet.
- beaucoup de logique dans `initState`, `didUpdateWidget`, `postFrameCallback`, `ref.listen`, `setState`.
- l’UI narrative et Dialogue Studio possède encore de la lecture disque, du parsing, de la synchronisation et de l’intégration IA.

Points concrets:
- shell: [`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart)
- canvas map: [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart)
- dialogue: [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart)
- panels énormes: [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart), [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)

### Application

Verdict: c’est la couche la plus encombrée du projet.

Elle contient:
- des use cases utiles;
- des coordinators et services valables;
- des ports pertinents;
- mais aussi du `dart:io`, du `dart:ui`, des dépendances à la présentation et des conventions de persistance.

Elle n’est donc pas une couche application propre au sens strict. Elle sert souvent de zone tampon fourre-tout.

### Domain

Verdict: pur localement, mais trop mince pour jouer le rôle central d’une vraie Clean Architecture.

Le `domain` dans `map_editor` contient surtout des interfaces repositories très simples:
- [`repositories.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/domain/repositories/repositories.dart)

Le vrai métier pur est davantage dans `map_core`:
- modèles
- opérations
- validateurs

Donc la structure “domain/application/infrastructure” de `map_editor` n’est pas fausse, mais elle ne reflète pas vraiment le centre réel de la logique.

### Infrastructure

Verdict: généralement la couche la plus disciplinée.

Elle fait ce qu’on attend:
- filesystem;
- JSON;
- lecture/écriture locale.

Le problème principal n’est pas dans l’infra, mais dans les contournements depuis l’application et l’UI.

## Focus spécial Riverpod

### Ce qui est moderne

- usage de `ProviderScope` simple à la racine: [`main.dart:22-24`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/main.dart#L22)
- génération `@riverpod` pour une grande partie du wiring
- emploi ponctuel de `select`, par exemple:
  - [`narrative_workspace_providers.dart:13`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart#L13)
  - [`pokedex_workspace.dart:38`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart#L38)

### Ce qui est legacy dans l’esprit

- un énorme notifier central qui sert de façade globale à toute l’app;
- des flows async gérés manuellement plutôt que modélisés via `AsyncValue`;
- des widgets qui orchestrent des effets, écoutent des providers et mutent leur état local pour gérer des charges de travail applicatives;
- un fichier `use_case_providers.dart` qui ressemble plus à un container applicatif massif qu’à une composition modulaire.

### Ce qui est encore acceptable

- garder `EditorNotifier` en `Notifier` plutôt qu’en `AsyncNotifier` n’est pas le vrai problème;
- certains états purement UI gardés localement sont une bonne chose;
- un provider manuel `StateNotifierProvider` n’est pas dramatique en soi.

### Ce qui doit être refactoré en priorité

1. Réduire la surface de `editorNotifierProvider`
- créer des providers sélecteurs ou view models ciblés pour shell, toolbar, status bar, explorer, palette, narrative;
- éviter de faire regarder `EditorState` complet à des widgets qui n’en consomment que 5%.

2. Extraire les sous-flux async
- Dialogue Studio;
- chargement Pokédex;
- hydratation narrative;
- chargement d’assets/aperçus;
- éventuellement auto-restore projet.

3. Arrêter les contournements de DI
- aucun widget ne devrait construire directement `FileProjectRepository`, `FilePokemonReadRepository` ou `ProjectFileSystem`.

4. Clarifier les rôles
- `Notifier` pour état session/orchestration;
- `Provider` dérivés pour lecture locale sélectionnée;
- `FutureProvider`/`AsyncNotifier` pour sous-flux asynchrones identifiables;
- état UI purement visuel conservé localement quand haute fréquence.

### Forme cible recommandée

Pour ce projet, la forme cible réaliste n’est pas “tout réécrire”.

Je recommande:
- un `EditorSessionNotifier` plus petit, centré session projet + map active + commandes haut niveau;
- des controllers/providers feature-scoped pour:
  - dialogue studio,
  - narrative workspace,
  - pokedex workspace,
  - tileset palette,
  - project explorer;
- des providers de lecture ciblée, pas un watch global du state;
- une DI toujours via Riverpod, mais avec wiring réparti par feature au lieu d’un seul bloc de 972 lignes.

## Navigation / routing

Verdict: **pas de vrai router** dans `map_editor`.

Constat réel:
- `main.dart` instancie directement `EditorShellPage` via `MacosApp.home`
- aucun `go_router`
- aucun `MaterialApp.router`
- pas de redirects auth

Ce n’est pas forcément un défaut pour un éditeur desktop mono-shell. En revanche:
- la navigation intra-app est gérée de façon ad hoc par `EditorWorkspaceMode` et l’état global;
- la scalabilité future en deep linking ou restauration fine de workspace sera limitée.

Le point important est surtout de ne pas faire semblant: ici, il n’y a pas d’architecture router à auditer, juste un shell + des modes.

## Data / réseau / persistance

### Ce qui est absent ou limité

Dans `map_editor`, je n’ai pas trouvé de stack `Dio`, auth, refresh token, Firebase, analytics, secure storage ou notifications push. Ces sujets ne sont donc pas audités comme s’ils existaient.

### Ce qui existe réellement

- persistance locale JSON via filesystem;
- migration legacy des manifests;
- un client HTTP minimal Mistral pour Dialogue Studio.

### Appréciation

- persistance locale: globalement propre dans l’infrastructure;
- migration legacy: pragmatique, parfois dense, mais cohérente avec un outil auteur;
- réseau: insuffisamment industrialisé, mais encore localisé.

## Performance / rebuilds / coût runtime

### Rebuilds inutiles

Le vrai point chaud est simple:
- `pan` et `zoom` mutent `EditorState` global: [`editor_notifier.dart:6327-6333`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L6327)
- shell, toolbar, status bar, explorer, panels regardent ce state global.

Résultat probable:
- rebuilds bien plus larges que nécessaire pendant la navigation canvas;
- coût inutile sur les chrome widgets et panels.

### Side effects au frame ordering

Exemples:
- [`editor_shell_page.dart:42-50`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L42)
- [`map_canvas.dart:106-110`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart#L106)
- [`map_canvas.dart:139-144`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart#L139)
- [`dialogue_studio_workspace.dart:176-180`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L176)

Ces patterns sont encore “gérables”, mais ils rendent la correction dépendante de l’ordre de frame plutôt que d’un flow d’état explicite.

### I/O et images dans les widgets

Exemples:
- [`character_library_panel.dart:23-38`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/character_library_panel.dart#L23)
- [`dialogue_studio_workspace.dart:138`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L138)

Cela tend à disséminer les coûts et à rendre l’optimisation future plus difficile.

## Robustesse / sécurité / production-readiness

### Ce qui est plutôt bon

- plusieurs flows d’erreur ne crashent pas brutalement l’éditeur;
- certains comportements best-effort sont assumés, par exemple l’auto-restore projet.

### Ce qui est fragile

- beaucoup de `catch (_) {}` silencieux, notamment dans les widgets;
- fragmentation du handling d’erreurs entre notifier, widgets et use cases;
- I/O en UI qui rend les erreurs moins uniformes;
- client Mistral sans timeout/réessai/cancelation.

### Ce qui est préoccupant

[`project_manifest.dart:91-95`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart#L91) documente explicitement une clé API Mistral potentiellement stockée dans `project.json`.

Pour un vrai produit:
- ce n’est pas une stratégie satisfaisante de secret management;
- au minimum, il faudrait une politique explicite de sécurité et un mode de stockage séparé si la fonctionnalité doit survivre.

## Problèmes classés par gravité

### Critique

1. `EditorNotifier` centralise trop de responsabilités
2. `EditorState` mélange état session, état UI et viewport à une granularité trop large
3. `DialogueStudioWorkspace` orchestre disque, parsing, IA et UI dans le widget
4. Riverpod est utilisé surtout comme service locator + store global, pas comme graphe d’état moderne

### Important

1. Dépendances de l’application vers la présentation (`terrain_preset_selection_coordinator.dart`)
2. Dépendances de l’application vers Flutter rendering (`entity_editor_element_visual.dart`)
3. `dart:io` dans plusieurs use cases applicatifs
4. Widgets qui contournent la DI et instancient l’infrastructure
5. Fichiers géants qui empêchent une review et une maintenance saines
6. Scope narratif global non lié au projet
7. Stockage possible de la clé Mistral dans `project.json`
8. Rebuilds trop larges à cause du watch complet de `EditorState`

### Amélioration

1. Uniformiser la doctrine des ports/repositories entre `domain` et `application`
2. Répartir le wiring providers par feature
3. Réduire les `postFrameCallback` au profit de transitions d’état explicites
4. Clarifier la différence entre use case anémique et orchestration réelle

## Refactors recommandés

### Refactor 1 — Démonter progressivement `EditorNotifier`

Objectif:
- réduire `EditorNotifier` à la session éditeur et aux commandes transverses.

Pourquoi:
- c’est le premier facteur de couplage, de rebuild large et de dette.

Bénéfices:
- meilleure testabilité;
- responsabilités lisibles;
- Riverpod plus idiomatique;
- blast radius réduit.

Coût:
- élevé

Priorité:
- critique

Risques:
- régression si tenté en big bang

Design cible:
- un notifier de session réduit;
- des controllers/features dédiés pour dialogue, narrative, pokedex, tileset/workspace spécifiques;
- des providers dérivés étroits pour la lecture UI.

### Refactor 2 — Sortir les side effects des widgets

Objectif:
- faire des widgets de vrais renderers/orchestrateurs fins, pas des mini-controllers.

Pourquoi:
- aujourd’hui la présentation porte trop de logique d’intégration.

Bénéfices:
- testabilité;
- robustesse;
- comportement asynchrone plus déterministe.

Coût:
- moyen à élevé

Priorité:
- critique

Risques:
- peut créer trop d’abstractions si mal fait

Design cible:
- extraire des controllers/services/providers pour Dialogue Studio, narrative hydration, pokedex loader.

### Refactor 3 — Introduire des providers UI-facing granulaire

Objectif:
- réduire les rebuilds et clarifier ce que chaque widget consomme.

Pourquoi:
- le watch complet de `EditorState` est trop large.

Bénéfices:
- performance;
- lisibilité;
- sécurité des évolutions.

Coût:
- faible à moyen

Priorité:
- importante, quick win

Risques:
- faible

Design cible:
- `Provider`/`select` dédiés pour shell chrome, toolbar model, status model, explorer model, active canvas mode.

### Refactor 4 — Réaligner strictement les frontières d’architecture

Objectif:
- retirer les dépendances application -> presentation / Flutter.

Pourquoi:
- ce sont des violations nettes, pas des préférences.

Bénéfices:
- architecture crédible;
- meilleur découplage;
- évolution plus sûre.

Coût:
- moyen

Priorité:
- importante

Risques:
- faible si traité localement

Design cible:
- types de sélection déplacés hors présentation;
- services de visuel d’éditeur ramenés côté présentation ou adapter spécifique;
- disque derrière `ProjectWorkspace` ou repositories partout.

### Refactor 5 — Rendre la DI feature-scoped

Objectif:
- éviter un `use_case_providers.dart` monolithique.

Pourquoi:
- le wiring actuel est déjà trop centralisé.

Bénéfices:
- meilleure lisibilité;
- meilleure évolutivité par feature;
- moins de friction en review.

Coût:
- moyen

Priorité:
- amélioration forte

Risques:
- dispersion si fait sans conventions

Design cible:
- providers par feature/domaine fonctionnel, avec root providers minimaux.

## Roadmap de refonte priorisée

### Quick wins

1. Introduire des providers sélecteurs pour shell / toolbar / status / explorer / panels
2. Retirer les instanciations directes `FileProjectRepository`, `FilePokemonReadRepository`, `ProjectFileSystem` de la UI
3. Déplacer les `ref.listen` sensibles et les post-frame side effects hors `build` quand c’est possible
4. Standardiser Riverpod codegen là où le manuel n’apporte rien

### Refactors intermédiaires

1. Extraire Dialogue Studio derrière un controller/provider dédié
2. Extraire l’hydratation narrative des widgets
3. Scoper/réinitialiser l’état narratif par projet actif
4. Segmenter `use_case_providers.dart`

### Refactors structurants

1. Réduire drastiquement `EditorNotifier`
2. Repenser `EditorState` en plusieurs états cohérents
3. Réaligner les frontières application / présentation / infrastructure

### Chantier idéal long terme

1. Feature modules plus nets
2. UI pilotée par petits view models/providers dédiés
3. Architecture Riverpod orientée data flow réel, pas store global unique
4. Contrats d’infrastructure homogènes sur tout l’éditeur

## Conclusion franche

### Est-ce que cette app respecte réellement la Clean Architecture ?

Partiellement seulement. Les packages et certains ports donnent l’apparence d’une Clean Architecture, mais les dépendances réelles et les responsabilités montrent un système application-heavy avec plusieurs fuites franches.

### Est-ce que l’usage de Riverpod est bon, moyen ou mauvais ?

Moyen à faible.

Riverpod n’est pas mal utilisé au point d’être toxique, mais il n’est pas utilisé de manière moderne et idiomatique pour un codebase de cette taille. Aujourd’hui il sert surtout à câbler un gros orchestrateur central.

### Est-ce que la base est saine ou trompeuse ?

Elle est **mixte**:
- saine dans certaines fondations;
- trompeuse si on lit seulement l’arborescence et les noms de couches.

### Est-ce que je recommanderais cette architecture à une équipe senior en production ?

Pas en l’état. Je recommanderais plutôt:
- de conserver les bons seams existants;
- de lancer vite une refonte ciblée sur l’état, Riverpod, les side effects UI et les frontières d’architecture;
- de ne surtout pas continuer à accumuler des features dans `EditorNotifier` et les gros widgets.

## Audit par fichier / pattern marquant

### Composition root et DI

- [`main.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/main.dart): simple, sans router, propre pour un shell desktop.
- [`core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart): bon wiring de base.
- [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart): trop massif, non feature-scoped.

### Orchestration centrale

- [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart): centre réel de l’application, trop gros, trop transversal.
- [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart): state cohérent localement, mais trop agrégé globalement.

### Présentation

- [`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart): shell + bootstrap + toasts + shortcuts.
- [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart): widget le plus problématique côté orchestration.
- [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart): bon instinct sur l’état local haute fréquence, mais side effects post-frame et watch global.
- [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart): très branché sur le state global.
- [`status_bar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/status_bar.dart): lit tout le state pour quelques champs.

### Frontières infra

- [`file_repositories.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart): infra honnête.
- [`project_filesystem.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart): bon seam workspace.
- [`pokedex_workspace_loader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart): exemple concret de bypass du composition root.

## Thèmes absents ou non applicables

Les sujets suivants sont absents ou très limités dans `map_editor` et je ne les ai donc pas “sur-audités”:
- vrai router Flutter moderne
- auth / refresh token
- Dio / ApiClient structuré
- Firebase
- analytics
- secure storage dédié
- notifications push

La seule vraie intégration HTTP repérée côté éditeur est Mistral dans Dialogue Studio.

## Commandes réellement exécutées

Exploration structurelle et lecture:

```bash
rg --files packages/map_editor/lib packages/map_core/lib packages/map_runtime/lib examples/playable_runtime_host/lib
rg -n "ProviderScope|@riverpod|NotifierProvider|AsyncNotifierProvider|StateNotifierProvider|ConsumerWidget|ConsumerStatefulWidget|ref\.watch\(|ref\.read\(|ref\.listen\(|dart:io|dart:ui|MaterialApp\.router|GoRouter|go_router|Dio|ApiClient|Firebase|SharedPreferences|secure storage|flutter_secure_storage|Directory\.|File\(" packages/map_editor/lib packages/map_core/lib packages/map_runtime/lib examples/playable_runtime_host/lib
wc -l packages/map_editor/lib/src/app/providers/use_case_providers.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/features/editor/state/editor_state.dart packages/map_editor/lib/src/ui/editor_shell_page.dart packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
git status --short
```

Lectures ciblées de fichiers:

```bash
sed -n '1,220p' packages/map_editor/lib/main.dart
sed -n '1,220p' packages/map_editor/lib/src/app/providers/core_providers.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/use_case_providers.dart
sed -n '1,260p' packages/map_editor/lib/src/features/editor/state/editor_state.dart
sed -n '1,260p' packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
nl -ba packages/map_editor/lib/src/ui/editor_shell_page.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart | sed -n '1,260p'
nl -ba packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart | sed -n '1,240p'
nl -ba packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart | sed -n '1,360p'
nl -ba packages/map_editor/lib/src/domain/repositories/repositories.dart | sed -n '1,260p'
nl -ba packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart | sed -n '1,240p'
nl -ba packages/map_editor/lib/src/application/ports/project_workspace.dart | sed -n '1,220p'
nl -ba packages/map_core/lib/src/models/project_manifest.dart | sed -n '1,320p'
nl -ba packages/map_core/lib/src/io/legacy_editor_json_compat.dart | sed -n '1,280p'
nl -ba packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart | sed -n '1,420p'
nl -ba packages/map_editor/lib/src/ui/shared/top_toolbar.dart | sed -n '1,140p'
nl -ba packages/map_editor/lib/src/ui/shared/status_bar.dart | sed -n '1,120p'
nl -ba packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart | sed -n '1,140p'
nl -ba packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart | sed -n '90,220p'
nl -ba packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart | sed -n '1490,1885p'
nl -ba packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart | sed -n '1,240p'
nl -ba packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart | sed -n '1,220p'
nl -ba packages/map_editor/lib/src/application/models/pokemon_validation_report.dart | sed -n '1,220p'
```

## Résultats réels des commandes

### Taille des points chauds

```text
972   packages/map_editor/lib/src/app/providers/use_case_providers.dart
6951  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
154   packages/map_editor/lib/src/features/editor/state/editor_state.dart
711   packages/map_editor/lib/src/ui/editor_shell_page.dart
2354  packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
7573  packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
5105  packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
2013  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
```

### État Git observé pendant l’audit

```text
 M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_database_index_test.dart
?? reports/lot-15-pokedex-simple-filters-report.md
```

Important:
- cet arbre de travail n’est pas dû à cet audit;
- il reflète des changements déjà présents avant mon intervention;
- mon audit n’a pas modifié le code applicatif.

## Périmètre inclus

- audit d’architecture réel de `map_editor`
- lecture secondaire de `map_core` et `map_runtime` uniquement pour les frontières
- focus Riverpod / Clean Architecture / DI / présentation / robustesse / performance / trajectoire

## Périmètre exclu

- aucune modification de code applicatif
- aucune écriture de tests
- aucun refactor
- aucun audit fictif de features absentes
- aucun jugement “marketing” sur le produit

## Limites / hors périmètre

- Je n’ai pas transformé cet audit en `flutter analyze` global, car cela aurait produit surtout une liste de warnings statiques, pas un diagnostic architectural.
- Je n’ai pas audité en profondeur `map_runtime` comme produit autonome, seulement ses frontières avec l’éditeur.
- Je n’ai pas audité la qualité UX visuelle en tant que design critique; j’ai seulement évalué son couplage structurel.

## Tableau récapitulatif

| Sujet | Verdict | Gravité | Action recommandée |
| --- | --- | --- | --- |
| Clean Architecture réelle | Partielle, souvent nominale | Critique | Réaligner les dépendances et retirer les fuites app -> UI / Flutter / I/O |
| `EditorNotifier` | God object central | Critique | Le découper par sessions/features et réduire sa surface |
| `EditorState` | Trop agrégé | Critique | Séparer état session, viewport, messages UI et sous-domaines feature |
| Riverpod | Sérieux mais peu idiomatique moderne | Critique | Introduire providers plus granulaires et de vrais flows async Riverpod |
| `use_case_providers.dart` | Composition root trop massive | Important | Répartir le wiring par feature |
| Présentation | Trop orchestratrice | Critique | Sortir disque, parsing et réseau des widgets |
| Dialogue Studio | Widget-controller très couplé | Critique | Extraire un controller/service dédié |
| DI réelle | Bonne à la racine, contournée ensuite | Important | Interdire les instanciations infra depuis l’UI |
| Application layer | Polluée par `dart:io` et `dart:ui` | Important | Recentrer l’application sur de vraies frontières |
| Rebuilds / performance | Trop de watch larges | Important | Introduire des selectors/view models ciblés |
| Sécurité Mistral | Risque explicite sur la clé API | Important | Définir une politique de secret management |
| Sous-système Pokémon récent | Plutôt sain localement | Amélioration positive | Le prendre comme référence pour les prochains lots |

