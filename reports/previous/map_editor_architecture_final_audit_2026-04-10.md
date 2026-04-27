# Audit final de `map_editor` après les 16 lots

Date: 2026-04-10  
Périmètre principal: [`/Users/karim/Project/pokemonProject/packages/map_editor`](/Users/karim/Project/pokemonProject/packages/map_editor)  
Référence avant chantier: [`map_editor_architecture_audit_2026-04-10.md`](/Users/karim/Project/pokemonProject/reports/map_editor_architecture_audit_2026-04-10.md)  
Référence exécution chantier: [`map_editor_refactor_masterplan_2026-04-10.md`](/Users/karim/Project/pokemonProject/reports/map_editor_refactor_masterplan_2026-04-10.md)

## Résumé exécutif

Oui, la note a augmenté. Pas artificiellement, pas “sur le papier”, mais sur des points tangibles:
- la taille de plusieurs surfaces critiques a fortement baissé;
- la couche providers est mieux rangée et plus lisible;
- Riverpod est utilisé de manière plus ciblée sur plusieurs racines UI;
- `EditorState` est devenu nettement plus petit et plus cartographié;
- une partie de `EditorNotifier` a réellement été sortie vers des contrôleurs et services mieux bornés.

Le verdict honnête reste cependant le même sur le fond: **l’application n’est toujours pas une Clean Architecture stricte**. Elle est désormais **sensiblement meilleure**, plus reviewable, plus testable, plus composable, mais elle garde encore:
- un `EditorNotifier` beaucoup trop central;
- des widgets UI qui font encore du disque/parsing local;
- plusieurs usages de Riverpod encore plus proches d’un store global que d’un graphe d’état moderne et finement composé.

En clair:
- avant chantier: base exploitable, mais structure trompeuse et déjà en pente d’entropie;
- après chantier: base nettement plus saine, avec plusieurs vrais seams, mais pas encore “architecture senior finale”.

Si je devais résumer en une phrase: **on est passé d’une architecture fragile et encombrée à une architecture sérieusement assainie, mais encore incomplètement réalignée**.

## Note globale argumentée

### Avant / après

| Axe | Avant | Après | Delta | Commentaire |
| --- | ---: | ---: | ---: | --- |
| Clean Architecture | 5.0 | 6.3 | +1.3 | Les frontières ont progressé, mais `EditorNotifier` et plusieurs widgets gardent des fuites franches. |
| Usage de Riverpod | 4.5 | 6.4 | +1.9 | Les selectors/snapshots et la réorganisation des providers sont de vrais progrès. Le write-side reste trop monolithique. |
| Séparation des responsabilités | 4.0 | 6.0 | +2.0 | Grosse amélioration grâce aux extractions hors notifier et à la décomposition UI. |
| Maintenabilité | 4.5 | 6.7 | +2.2 | Les gros fichiers critiques ont beaucoup reculé, le blast radius a diminué. |
| Robustesse | 5.5 | 6.1 | +0.6 | Les gains sont réels mais plus modestes; trop de robustesse dépend encore du centre global. |
| Scalabilité | 4.0 | 5.8 | +1.8 | L’app tiendra mieux qu’avant, mais le modèle de croissance reste limité par `EditorNotifier`. |
| Lisibilité | 4.0 | 6.8 | +2.8 | C’est la progression la plus visible. Plusieurs surfaces sont redevenues lisibles. |
| Cohérence globale | 5.0 | 6.4 | +1.4 | La doctrine est plus claire qu’avant, même si elle n’est pas encore appliquée partout. |

### Verdict de note

La note monte **franchement**. Le gain n’est pas marginal.  
Mais elle ne monte pas jusqu’à “excellent” ou “sans concession”, parce que les deux dettes structurelles majeures ne sont pas encore soldées:

1. [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) reste le point de gravité dominant à **6214 lignes**.  
2. Plusieurs surfaces UI lisent encore le disque ou interprètent elles-mêmes des données documentaires.

## Ce qui s’est objectivement amélioré

### 1. Les gros fichiers les plus dangereux ont vraiment reculé

Tailles constatées maintenant:

| Fichier | Taille actuelle |
| --- | ---: |
| [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) | 6214 lignes |
| [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart) | 112 lignes |
| [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart) | 486 lignes |
| [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart) | 510 lignes |
| [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart) | 1594 lignes |
| [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart) | 4290 lignes |
| [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart) | 672 lignes |
| [`entity_properties_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart) | 2324 lignes |
| [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart) | 1704 lignes |
| [`step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart) | 2534 lignes |
| [`global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) | 1130 lignes |
| [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) | 2444 lignes |

Ce n’est pas juste un “déplacement de lignes”. Sur les fichiers les plus exposés à la revue humaine:
- [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart) est redevenu un shell;
- [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart) est redevenu un shell;
- [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart) a retrouvé une taille saine;
- [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart) reste gros, mais beaucoup moins illisible qu’avant.

### 2. `EditorState` a été drastiquement assaini

Le contraste est fort. [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart) ne fait plus l’effet d’un sac de données incontrôlé.  
Le fichier exporte maintenant ses groupes et ses modes via:
- [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart#L9)
- [`editor_state_groups.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart)
- [`editor_ui_modes.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/models/editor_ui_modes.dart)
- [`editor_workspace_mode.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart)

Le gain ici est architectural, pas seulement esthétique:
- on comprend mieux les familles d’état;
- les helpers de lecture/copie sont mieux bornés;
- le notifier central n’a plus besoin de manipuler autant de champs plats sans structure.

### 3. Riverpod est mieux utilisé sur les racines UI

Le vrai progrès Riverpod du chantier est dans [`editor_selectors.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart).

Les snapshots ciblés y sont maintenant explicites:
- [`editorShellSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L117)
- [`editorToolbarSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L173)
- [`editorProjectExplorerSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L200)
- [`editorTerrainLibrarySnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L216)
- [`editorTilesetPaletteSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L234)

Ces snapshots sont réellement consommés par les surfaces principales:
- [`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart#L75)
- [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart#L60)
- [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart#L42)
- [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart#L32)
- [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart#L318)

Avant, Riverpod était souvent présent mais trop large.  
Maintenant, sur ces racines, on voit une vraie tentative de consommation ciblée de l’état.

### 4. La composition root est plus lisible

L’ancien gros fichier de wiring a été remplacé par un découpage thématique plus sain:
- [`core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart)
- [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart)
- [`repository_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core/repository_providers.dart)
- [`map_use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart)
- [`project_use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/project_use_case_providers.dart)
- [`editing_service_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/editing_service_providers.dart)
- [`workspace_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/workspace_providers.dart)

Le gain est net:
- meilleur scan humain;
- meilleure séparation par thème;
- moins d’effet “container central tentaculaire”.

### 5. `EditorNotifier` n’est plus le seul endroit où tout vit

Le gros problème n’est pas soldé, mais il a commencé à être attaqué correctement.

On a maintenant des briques spécifiques hors du notifier:
- [`project_session_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart)
- [`map_editing_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart)
- [`map_selection_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart)
- [`editor_workspace_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart)
- [`project_content_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/project_content_controller.dart)

Ce ne sont pas des abstractions décoratives. Elles réduisent vraiment la responsabilité du notifier central sur plusieurs flux.

## Ce qui reste bon

### 1. Le découpage package-level reste sain

La séparation monorepo entre `map_core`, `map_editor`, `map_runtime` reste une vraie force.  
Ce chantier n’a pas dégradé ce point. Il l’a plutôt rendu plus exploitable.

### 2. `ProjectWorkspace` reste un seam utile

Le contrat [`project_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/project_workspace.dart) reste une bonne fondation.  
Beaucoup de use cases passent par lui plutôt que par `Directory.current` ou des chemins hardcodés.

### 3. Le sous-système Pokémon reste plus propre que le legacy éditeur

Le chantier UI n’a pas abîmé les bonnes choses introduites plus récemment:
- readers/writers Pokémon;
- validation locale Pokémon;
- index Pokémon;
- config légère Pokémon dans `project.json`.

Ce sous-système reste l’un des meilleurs indices de ce à quoi pourrait ressembler un `map_editor` plus discipliné.

## Ce qui est acceptable mais encore perfectible

### 1. La composition root est meilleure, mais encore un peu sur-providerisée

Le rangement est meilleur.  
La doctrine reste cependant un peu trop généreuse en providers “constructeurs simples”, par exemple dans:
- [`map_use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart)
- [`project_use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/project_use_case_providers.dart)

Ce n’est pas dramatique. C’est surtout du bruit structurel.  
Le problème n’est plus la lisibilité brute, mais le fait que tout n’a pas besoin d’être un provider autonome.

### 2. Les snapshots Riverpod sont bons, mais encore trop larges par endroits

Exemple:
- [`editorShellSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L117) transporte encore `activeMap` pour dériver des infos d’en-tête;
- [`editorToolbarSnapshotProvider`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart#L173) embarque encore `project`, `activeMap` et `activeLayer` complets.

Ça reste une amélioration claire.  
Mais ce n’est pas encore le niveau “ultra fin” qu’on attendrait d’un Riverpod très moderne sur une app qui va continuer à grossir.

### 3. Quelques grands widgets sont sortis de la zone rouge, mais restent lourds

Cas acceptable mais sous surveillance:
- [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart)
- [`global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart)

Ils ne sont plus les urgences absolues, mais il faut éviter de les ré-enfler.

## Ce qui reste problématique

### 1. `EditorNotifier` reste un god object

C’est toujours **le** problème numéro un.

Preuves:
- taille: [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) fait encore **6214 lignes**;
- dépendances multiples dès le haut du fichier:
  - [`editor_notifier.dart:10`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L10)
  - [`editor_notifier.dart:52`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L52)
- mélange de:
  - routing de workspace;
  - orchestration projet;
  - save/load;
  - I/O de session locale;
  - intégration macOS via `MethodChannel`;
  - mutations d’état global.

Et il importe encore `dart:io`:
- [`editor_notifier.dart:2`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart#L2)

Il a maigri conceptuellement, mais il n’a pas encore changé de nature.

### 2. La présentation fait encore du disque et du parsing

C’est l’autre dette majeure.

Exemples nets:
- [`dialogue_studio_workspace.dart:11`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L11)
- [`dialogue_studio_workspace.dart:142`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L142)
- [`entity_properties_dialogue_support.dart:19`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_dialogue_support.dart#L19)
- [`tileset_palette_panel.dart:3229`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart#L3229)
- [`tileset_palette_preview.dart:247`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart#L247)
- [`terrain_mapping_workspace.dart:1245`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart#L1245)
- [`pokedex_workspace.dart:99`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart#L99)

Il faut distinguer deux cas:
- lire une image en local pour preview UI: acceptable à court terme;
- lire et interpréter un document métier depuis le widget: beaucoup moins acceptable.

Le cas le plus problématique est clairement `DialogueStudioWorkspace`.

### 3. `PokemonProjectDataReader` n’est pas encore à la bonne couche

[`pokemon_project_data_reader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart) reste dans `application/services`, mais importe encore `dart:io`:
- [`pokemon_project_data_reader.dart:2`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart#L2)

Il reconstruit encore des `Directory` / `File`:
- [`pokemon_project_data_reader.dart:358`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart#L358)
- [`pokemon_project_data_reader.dart:369`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart#L369)
- [`pokemon_project_data_reader.dart:410`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart#L410)

Ce n’est pas catastrophique dans l’usage courant, mais ce n’est pas aligné avec une Clean Architecture stricte.

### 4. Riverpod reste encore trop centré sur un store global

Malgré les snapshots ciblés, beaucoup de widgets regardent encore directement tout le state:
- [`map_canvas.dart:90`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart#L90)
- [`status_bar.dart:13`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/status_bar.dart#L13)
- [`map_inspector_panel.dart:51`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart#L51)
- [`entity_properties_panel.dart:133`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart#L133)
- [`dialogue_studio_workspace.dart:167`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart#L167)

On a donc amélioré le haut de l’arbre, mais pas encore toutes les surfaces secondaires.

### 5. Les gros workspaces narratifs restent lourds

Ils sont mieux qu’avant, mais encore trop volumineux:
- [`step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart)
- [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart)
- [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart)

Le code n’est pas nécessairement “mauvais” ligne à ligne.  
Le problème est le coût cognitif, la densité de responsabilités et la difficulté de faire évoluer ces surfaces sans régression.

## Audit détaillé par axe

### A. Vision d’ensemble de l’architecture

L’architecture est plus honnête qu’avant.  
Elle ressemble maintenant à une architecture “application-heavy mais disciplinée”, alors qu’avant elle ressemblait souvent à une architecture “nommée proprement mais pratiquée de façon opportuniste”.

Ce qui a gagné:
- meilleure lisibilité des providers;
- meilleurs seams internes;
- meilleure séparation de plusieurs surfaces UI.

Ce qui empêche encore de parler de vraie Clean Architecture:
- `EditorNotifier` reste trop central;
- la présentation contient encore des effets d’intégration;
- l’application n’est pas complètement pure côté I/O.

### B. Clean Architecture détaillée

Le domaine pur n’est toujours pas le centre réel du système.  
Le centre réel reste l’application, puis un gros noyau d’orchestration dans `features/editor/state`.

Améliorations réelles:
- plus de contrôleurs et coordinators hors notifier;
- plus de ports explicites côté workspace et Pokémon;
- moins de mélange direct dans plusieurs surfaces UI.

Limite:
- les dépendances globales n’ont pas encore été suffisamment “tirées vers le bas”.

### C. Riverpod

Avant:
- Riverpod servait beaucoup de conteneur global et de service locator typé.

Après:
- Riverpod sert aussi à dériver des snapshots UI utiles et ciblés;
- la couche providers est moins massive et plus thématique.

Mais:
- le write-side reste trop centralisé;
- trop de widgets secondaires restent branchés directement sur `editorNotifierProvider`;
- les événements transitoires (`statusMessage`, `errorMessage`) restent mélangés au state durable.

### D. DI / composition root / bootstrap

La DI est meilleure qu’avant:
- [`core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart)
- [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart)

Le bootstrap reste cependant partiellement absorbé par le notifier:
- restauration du dernier projet;
- mémoire de session locale;
- accès macOS.

Ça devrait être plus clairement extrait à terme.

### E. États et modèles

Très nette amélioration sur:
- cartographie de `EditorState`;
- groupes d’état;
- types de modes.

Point encore faible:
- le state central contient encore des signaux transitoires UI et des sélections hétérogènes nombreuses.

### F. Présentation

Les shells principaux se sont beaucoup améliorés:
- toolbar;
- explorer;
- terrain;
- palette;
- canvas.

Les surfaces encore problématiques:
- dialogue;
- step;
- cutscene;
- entity properties.

### G. Navigation / routing

Toujours hors sujet ou minimal dans ce package.  
Aucun changement majeur sur cet axe.  
Ce n’est pas un point de dette prioritaire ici.

### H. Data / infrastructure / persistance

L’infrastructure filesystem locale reste globalement correcte.  
Le vrai problème n’est pas tant l’infra elle-même que le fait qu’elle fuit encore jusqu’aux widgets et à certains services application.

### I. Qualité de code / maintenabilité / cohérence

Très nette hausse.  
C’est probablement l’axe où le chantier a eu l’effet le plus visible.

Pourquoi:
- moins de fichiers monstres au premier plan;
- plus de sous-dossiers par thème;
- meilleurs shells;
- meilleur coût de revue.

### J. Performance / rebuilds / coût runtime

Amélioration nette, mais pas encore finie.

Progrès:
- snapshots ciblés sur plusieurs racines;
- état local conservé localement sur certaines surfaces interactives.

Limites:
- widgets secondaires encore branchés au state global complet;
- quelques snapshots encore trop riches;
- gros workspaces encore lourds à reconstruire.

### K. Robustesse / production-readiness

Elle progresse un peu, mais moins que la lisibilité.

Pourquoi:
- plusieurs comportements sont mieux bornés;
- plus de tests smoke/non-régression sur des surfaces importantes.

Mais:
- trop de flows dépendent encore du notifier central;
- trop de lecture disque existe encore dans la présentation;
- certains `catch` restent défensifs mais silencieux.

### L. Dette technique et trajectoire d’évolution

La trajectoire est meilleure qu’avant.  
Avant, la croissance du projet promettait surtout plus d’entropie.  
Maintenant, elle promet plutôt un coût de refactor restant, mais sur une base beaucoup plus récupérable.

Le système ne s’auto-condamne plus autant qu’avant.  
En revanche, si on arrête ici trop longtemps, la dette peut recommencer à s’accumuler autour des mêmes points restants.

## Problèmes classés par gravité

### Critique

1. [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) reste un god object à 6214 lignes, avec I/O, session, orchestration et intégration plateforme.
2. [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart) mélange encore UI, lecture disque, parsing documentaire et orchestration.
3. Des surfaces UI continuent de lire/interpréter des fichiers directement, ce qui casse les frontières d’architecture.

### Important

1. [`pokemon_project_data_reader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart) est encore mal placé architecturalement.
2. Plusieurs widgets secondaires regardent encore `editorNotifierProvider` en entier.
3. Les signaux transitoires UI sont encore stockés dans le state global.
4. Les workspaces narratifs `step` et `cutscene` restent trop gros.
5. [`entity_properties_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart) reste trop lourd et trop chargé en sync UI cachée.

### Amélioration

1. Réduire encore la taille des snapshots `shell` et `toolbar`.
2. Rationaliser les providers purement constructeurs.
3. Continuer à empêcher les widgets UI de reprendre de la masse après les lots de découpage.

## Focus spécial Riverpod

### Ce qui est moderne maintenant

- snapshots ciblés via `select(...)`;
- providers thématiques mieux rangés;
- séparation `watch` pour la data / `read` pour les commandes sur plusieurs surfaces;
- pas de sur-utilisation de state global pour les micro-états purement visuels.

### Ce qui ne l’est pas encore

- un seul `AutoDisposeNotifier` central qui porte encore presque tout le write-side;
- trop de consommation directe de `editorNotifierProvider` complet dans les surfaces secondaires;
- événements de toast/statut couplés au state durable;
- providers parfois utilisés surtout comme usine à objets.

### Ce qui devrait être migré en priorité

1. Diminuer encore le périmètre de `EditorNotifier`.
2. Remplacer les watchers larges restants par des selectors spécifiques.
3. Séparer les événements transitoires du state persistant.
4. Éviter de recréer certains controllers dans des getters du notifier quand un provider dédié existe déjà.

### Ce qui devrait rester

- les snapshots déjà introduits;
- l’organisation par thème dans `app/providers`;
- le choix de garder de l’état purement UI en local quand il est réellement local.

## Refactors recommandés

### Refactor 1

- Objectif: sortir définitivement la session locale / bootstrap plateforme hors `EditorNotifier`.
- Pourquoi: c’est la partie la moins légitime dans un notifier UI.
- Bénéfices: notifier plus pur, meilleure testabilité, meilleure séparation app/platform.
- Coût: moyen.
- Priorité: haute.
- Risques: faible si fait sans changer les flux utilisateur.
- Design cible: service/bootstrap dédié + provider d’initialisation + notifier recentré sur l’état éditeur.

### Refactor 2

- Objectif: sortir la lecture/parsing documentaire de `DialogueStudioWorkspace`.
- Pourquoi: c’est la fuite de couches la plus visible côté UI.
- Bénéfices: meilleure réutilisabilité, meilleure testabilité, UI plus mince.
- Coût: moyen à élevé.
- Priorité: haute.
- Risques: modérés, parce que ce workspace est dense.
- Design cible: loader/service applicatif dédié + widget consommateur d’un modèle déjà résolu.

### Refactor 3

- Objectif: finir la granularité Riverpod sur les panneaux secondaires.
- Pourquoi: les grosses racines ont été traitées, mais pas la queue longue.
- Bénéfices: moins de rebuilds, moins de couplage au state global.
- Coût: moyen.
- Priorité: moyenne-haute.
- Risques: faibles si fait progressivement.
- Design cible: selectors ciblés par panneau / sous-panneau.

### Refactor 4

- Objectif: sortir les événements transitoires du state global.
- Pourquoi: `statusMessage` / `errorMessage` ne sont pas du vrai state durable.
- Bénéfices: modèle d’état plus propre, side effects mieux bornés.
- Coût: moyen.
- Priorité: moyenne.
- Risques: faibles.
- Design cible: event stream/provider dédié pour les toasts et notifications transitoires.

### Refactor 5

- Objectif: réaligner `PokemonProjectDataReader` sur une vraie frontière infra.
- Pourquoi: l’application fait encore un peu trop de disque.
- Bénéfices: cohérence architecturale, meilleure doctrine pour les futurs lots.
- Coût: faible à moyen.
- Priorité: moyenne.
- Risques: faibles.
- Design cible: implémentation concrète derrière port explicite, application sans `dart:io`.

## Roadmap priorisée

### Quick wins

1. Introduire des selectors pour `StatusBar`, `MapInspectorPanel`, `EntityPropertiesPanel`, `DialogueStudioWorkspace`.
2. Réduire la taille des snapshots `shell` et `toolbar`.
3. Éviter les recréations de petits controllers dans des getters du notifier quand un provider dédié existe déjà.

### Refactors intermédiaires

1. Sortir le bootstrap/session locale de `EditorNotifier`.
2. Créer un loader/document service pour `DialogueStudioWorkspace`.
3. Éclater encore `EntityPropertiesPanel`.

### Refactors structurants

1. Réduire fortement `EditorNotifier` en le recentrant sur coordination d’état et dispatch.
2. Déplacer les lectures disque résiduelles hors des widgets.
3. Normaliser les ports/services qui exposent encore une interface trop filesystem-shaped.

### Chantier idéal long terme

1. Un write-side Riverpod plus modulaire, par domaine de travail.
2. Une doctrine explicite: widgets = rendu/orchestration légère, services/use cases = lecture/écriture/interprétation, infra = disque.
3. Un `map_editor` capable de grandir sans recréer un nouveau “centre monolithique”.

## Conclusion franche

### Est-ce que cette app respecte réellement la Clean Architecture ?

**Mieux qu’avant, mais toujours pas strictement.**

Elle a maintenant davantage de comportements qui respectent l’architecture au lieu de simplement en reprendre le vocabulaire.  
Mais elle n’a pas encore soldé ses principales contradictions.

### Est-ce que l’usage de Riverpod est bon, moyen ou mauvais ?

**Aujourd’hui: moyen à bon, avec vraie progression.**

Avant, je l’aurais qualifié de moyen-faible.  
Maintenant, je le qualifierais de **correct et en progrès net**, mais encore pas assez moderne/fin sur le write-side et sur plusieurs surfaces secondaires.

### Est-ce que la base est saine ou trompeuse ?

**Elle est désormais plus saine que trompeuse.**

Avant, la structure donnait plus de promesses qu’elle n’en tenait.  
Maintenant, elle commence à tenir davantage de ses promesses, même si ce n’est pas encore complet.

### Est-ce que je recommanderais cette architecture à une équipe senior en production ?

**Pas encore comme état final.**

En revanche, je recommanderais beaucoup plus facilement cette base qu’avant, parce qu’elle montre maintenant:
- une vraie direction;
- des seams crédibles;
- une capacité à être refactorée sans tout casser.

Autrement dit:
- avant: je recommanderais une refonte urgente avant croissance sérieuse;
- maintenant: je recommanderais de continuer sur la trajectoire actuelle, avec un dernier cycle ciblé sur `EditorNotifier`, les lectures disque UI et la granularité Riverpod secondaire.

## Tableau récapitulatif

| Sujet | Verdict | Gravité | Action recommandée |
| --- | --- | --- | --- |
| Clean Architecture réelle | Améliorée mais encore incomplète | Critique | Réduire `EditorNotifier` et sortir les lectures disque UI |
| `EditorNotifier` | Toujours trop central | Critique | Le casser encore par domaines et sortir bootstrap/session |
| Riverpod sur les racines UI | Vraie amélioration | Important | Conserver le pattern snapshots/selectors |
| Riverpod sur les surfaces secondaires | Encore trop global | Important | Ajouter des selectors ciblés panneau par panneau |
| Composition root | Beaucoup plus lisible | Amélioration | Continuer à éviter le retour d’un container massif |
| `EditorState` | Très fortement amélioré | Amélioration | Garder la cartographie par groupes et éviter le ré-enflement |
| `TopToolbar` | Redevenu sain | Amélioration | Le garder comme shell, ne pas le regrossir |
| `ProjectExplorerPanel` | Redevenu sain | Amélioration | Même discipline: shell + sous-dossiers thématiques |
| `TilesetPalettePanel` | Mieux, mais encore lourd | Important | Continuer à surveiller son périmètre fonctionnel |
| `DialogueStudioWorkspace` | Encore trop chargé | Critique | Extraire chargement/parsing hors UI |
| `EntityPropertiesPanel` | Encore trop gros | Important | Continuer le découpage et sortir la sync cachée |
| `PokemonProjectDataReader` | Mal placé architecturalement | Important | Le réaligner derrière une vraie frontière infra |
| Robustesse globale | En hausse mais modérée | Important | Retirer les dépendances silencieuses au centre global |
| Trajectoire long terme | Nettement meilleure | Amélioration | Poursuivre un dernier cycle structurant ciblé |
