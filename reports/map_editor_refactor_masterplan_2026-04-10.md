# Masterplan de refonte stricte de `map_editor`

Date: 2026-04-10  
Périmètre principal: [`/Users/karim/Project/pokemonProject/packages/map_editor`](/Users/karim/Project/pokemonProject/packages/map_editor)  
Objet: réduire la taille des fichiers, mieux organiser le code par sous-dossiers thématiques, réaligner l’architecture sans élargir le scope fonctionnel, et sécuriser le chantier par des tests de non-régression.

---

## Résumé exécutif

Le problème de `map_editor` n’est plus un problème de fonctionnalités. Le problème est un problème de structure.

Aujourd’hui, le package tient grâce à une base de logique réelle et utile, mais il est freiné par :
- quelques fichiers devenus massifs au point de bloquer la revue et la maintenance ;
- un centre de gravité beaucoup trop concentré dans [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) ;
- une séparation de couches incomplète, avec des fuites UI -> infra et application -> `dart:io` ;
- un usage Riverpod sérieux mais trop centralisé, plus proche d’un store global que d’une composition d’état moderne ;
- une organisation hybride entre `src/ui/*`, `src/application/*` et `src/features/*`, dont certaines branches existent mais ne structurent pas encore réellement le code ;
- un filet de tests inégal : bon sur plusieurs sous-systèmes récents, faible sur le shell, les gros panels et l’orchestration globale.

Le bon chantier n’est donc pas une réécriture, ni un grand ménage cosmétique.  
Le bon chantier est une refonte **par phases**, avec des lots petits, ordonnés, testés, reviewables, sans rien casser et sans aucune extension de scope.

Ce document propose :
- un diagnostic clair des causes de la dette actuelle ;
- une architecture cible pragmatique ;
- une stratégie de tests de non-régression ;
- un découpage en **5 phases** et **16 lots** ;
- pour chaque lot :
  - l’objectif ;
  - les fichiers à modifier ;
  - ce qu’il faut faire dans chaque fichier ;
  - les tests à ajouter ou adapter ;
  - les critères de sortie.

Le but n’est pas juste de “ranger les fichiers”.  
Le but est de rendre le projet :
- lisible ;
- composable ;
- plus idiomatique avec Riverpod ;
- plus simple à tester ;
- et beaucoup plus sûr à faire évoluer.

---

## État d’avancement réel

Statut mis à jour après exécution effective des premiers lots.

### Synthèse par phase

| Phase | Statut | Note |
| --- | --- | --- |
| Phase 1 — Sécuriser les non-régressions | Fait | Lots 1-2 terminés, tests shell/chrome et smoke panels en place |
| Phase 2 — Réparer les frontières d’architecture | Fait | Lots 3-5 terminés |
| Phase 3 — Casser progressivement `EditorNotifier` | Fait | Lots 6-9 terminés |
| Phase 4 — Moderniser Riverpod et la composition root | Fait | Lots 10-11 terminés |
| Phase 5 — Découper et ranger les surfaces UI | En cours | Lots 12-15 terminés, lot 16 engagé ; terrain déjà fortement réduit, première extraction palette faite |

### Statut lot par lot

| Lot | Statut | Commentaire |
| --- | --- | --- |
| Lot 1 | Fait | Filet de sécurité sur `EditorShellPage`, `TopToolbar`, `StatusBar` |
| Lot 2 | Fait | Smoke tests sur `ProjectExplorerPanel`, `TerrainEditorPanel`, `TilesetPalettePanel`, `DialogueStudioWorkspace`, `CutsceneStudioWorkspace` |
| Lot 3 | Fait | Retrait de la fuite UI -> infra Pokédex via providers dédiés |
| Lot 4 | Fait | Retrait du `dart:io` direct des use cases application derrière `ProjectWorkspace` |
| Lot 5 | Fait | Sortie des types UI/platform hors application (`TerrainSelectionMode`, helper visuel entité) |
| Lot 6 | Fait | Première cartographie de `EditorState` avec groupes et helpers cohérents |
| Lot 7 | Fait | Extraction de la tranche session projet / document map hors `EditorNotifier` |
| Lot 8 | Fait | Extraction sélection/outils + mutations map/historique hors `EditorNotifier` |
| Lot 9 | Fait | Extraction des flux secondaires dialogue/cutscene + routeur de workspace + wiring thématique Riverpod |
| Lot 10 | Fait | Sélecteurs ciblés en place sur shell, canvas host, toolbar, project explorer, terrain root et tileset root |
| Lot 11 | Fait | Composition root Riverpod réorganisée par thèmes, avec barrels de compatibilité conservés |
| Lot 12 | Fait | `TopToolbar` et `ProjectExplorerPanel` réduits en shells avec extractions thématiques |
| Lot 13 | Fait | Découpage mécanique des workspaces narratifs avec extraction en fichiers support et nettoyage du legacy non branché |
| Lot 14 | Fait | `dialogue_studio_workspace` réduit en shell avec extraction des dialogs, de l’arbre bibliothèque et des cartes canvas |
| Lot 15 | Fait | `MapCanvas` est devenu un shell lisible, `EntityPropertiesPanel` a perdu ses helpers/drafts/bindings de support |
| Lot 16 | En cours | `terrain_editor_panel` largement découpé et validé ; `tileset_palette_panel` a commencé à être extrait mais garde encore ses warnings historiques |

### Note honnête sur l’état courant

- Les lots 1 à 9 ont bien été exécutés et validés sur leur périmètre ciblé.
- Le lot 10 est maintenant réalisé sur son objectif strict : les grosses surfaces principales n’observent plus `editorNotifierProvider` en bloc quand un snapshot ciblé suffit.
- Le lot 11 est terminé : `app/providers` est désormais organisé par thèmes (`core`, `editor`, `dialogue`, `pokedex`) avec des barrels de compatibilité pour éviter un blast radius inutile.
- Le lot 12 est maintenant terminé sur son périmètre :
  - [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart) est passé d’environ 1160 lignes à environ 486 lignes via extraction des widgets et dialogs ;
  - [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart) est passé d’environ 2013 lignes à environ 510 lignes ;
  - l’arbre monde, les nœuds tilesets, les dialogs d’import/renommage/création et les actions d’entête sont maintenant sortis dans des sous-dossiers dédiés.
- Le lot 13 est maintenant terminé sur son périmètre :
  - [`step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart) reste le plus gros workspace narratif, mais il a déjà perdu ses widgets/supports répétitifs vers `ui/canvas/step_studio/step_studio_workspace_support.dart` ;
  - [`global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) est descendu à environ 1130 lignes après retrait du reliquat legacy non branché et suppression du mini-sous-système de widgets morts ;
  - [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) est descendu à environ 2444 lignes avec extraction du support UI local ;
  - les tests narratifs ciblés repassent au vert après réalignement d’un test `GlobalStoryStudioWorkspace` sur l’UI réellement supportée par le shell actuel.

---

## Ce qui fonde ce masterplan

Ce plan s’appuie sur trois angles d’analyse menés en parallèle :

1. **Audit d’architecture**
   - point principal : le vrai noyau applicatif est aujourd’hui [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart), pas un ensemble de petits use cases bien composés ;
   - autres points forts : fuites de couches, dépendances `dart:io` en application, types UI dans l’application, organisation de dossiers incohérente.

2. **Audit de décomposition UI**
   - point principal : les gros fichiers UI doivent devenir des shells minces ;
   - stratégie : extraire d’abord widgets/dialogs/painters/helpers locaux par thème, sans déplacer prématurément toute l’architecture.

3. **Audit de couverture de tests**
   - point principal : la base de tests protège déjà plusieurs sous-systèmes récents, mais protège mal le shell, les gros panels et l’orchestration centrale ;
   - conséquence : chaque lot de refactor doit embarquer ses tests de non-régression au lieu de compter sur les seuls tests existants.

---

## Problème traité

### Gros fichiers objectivement à traiter

| Fichier | Taille approximative |
| --- | ---: |
| [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart) | 7573 lignes |
| [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) | 6951 lignes |
| [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart) | 1594 lignes |
| [`entity_properties_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart) | 2324 lignes |
| [`step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart) | 2534 lignes |
| [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) | 2444 lignes |
| [`global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) | 1130 lignes |
| [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart) | 672 lignes |
| [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart) | 1704 lignes |
| [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart) | 510 lignes |
| [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart) | 486 lignes |
| [`use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart) | 972 lignes |

### Défauts structurels principaux

1. **Orchestrateur monolithique**
   - [`editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) concentre bootstrap, session, mutations map, narration, dialogue, Pokédex, save/load et effets de bord.

2. **État global trop large**
   - [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart) mélange état métier, session, outil, UI locale, signaux transitoires et informations de workflow.

3. **Rebuild scope trop large**
   - Des surfaces majeures observent l’état global entier au lieu d’observer des sélecteurs ciblés :
     - [`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart)
     - [`editor_canvas_host.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart)
     - [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart)
     - [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart)
     - [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart)
     - [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)

4. **Fuites de couches**
   - UI qui instancie directement l’infrastructure :
     - [`pokedex_workspace_loader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart)
   - application qui dépend de `dart:io` :
     - [`project_dialogue_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart)
     - [`project_dialogue_library_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart)
     - [`dialogue_disk_path_support.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/dialogue_disk_path_support.dart)
     - [`initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
     - [`seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart)

5. **Application polluée par des détails UI/platform**
   - [`entity_editor_element_visual.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart) dépend de `dart:ui` et `flutter/painting`.
   - [`terrain_preset_selection_coordinator.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart) dépend de [`editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart).

6. **Organisation incohérente**
   - coexistence de :
     - `src/ui/*` global ;
     - `src/application/*` global ;
     - `src/features/*` ;
     - et des branches peu exploitées ou vides :
       - [`src/features/editor/ui`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/ui)
       - [`src/features/project`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/project)
       - [`src/features/scenario`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/scenario)

---

## Principes non négociables

### 1. Zéro changement de scope fonctionnel

Le chantier ne doit :
- ni ajouter de fonctionnalités visibles ;
- ni retirer des workflows ;
- ni modifier le comportement métier.

### 2. Pas de rangement cosmétique isolé

On ne déplace pas des fichiers juste pour que l’arborescence “fasse propre”.  
Chaque lot doit diminuer un vrai risque :
- couplage ;
- taille ;
- blast radius ;
- violation de frontière ;
- déficit de testabilité.

### 3. L’ordre des travaux est critique

L’ordre retenu est :
1. sécuriser les tests ;
2. réparer les frontières ;
3. casser le monolithe `EditorNotifier` ;
4. réduire la surface de rebuild Riverpod ;
5. découper et ranger les surfaces UI ;
6. finaliser le réalignement des providers et des dossiers.

### 4. Les gros widgets doivent devenir des shells

Un `*_panel.dart` ou `*_workspace.dart` doit finir comme :
- un shell d’assemblage ;
- pas comme un fourre-tout contenant widgets, dialogs, painters, caches, helpers, I/O et logique de coordination.

### 5. Riverpod doit redevenir une composition d’état

Pas simplement un habillage autour d’un store global et de gros notifiers omniscients.

### 6. Chaque lot embarque ses non-régressions

Pas de “on ajoutera les tests après”.

---

## Architecture cible pragmatique

### Cible de couches

```text
src/
  app/
    bootstrap/
    providers/

  application/
    errors/
    models/
    ports/
    services/
    use_cases/

  domain/
    repositories/

  infrastructure/
    filesystem/
    repositories/

  features/
    editor/
      application/
      state/
      ui/
    dialogue/
      application/
      state/
      ui/
    narrative/
      application/
      state/
      ui/
    pokedex/
      application/
      ui/
    map_entities/
      application/
      ui/
    project/
      ui/
```

### Doctrine de placement

- `app/` : bootstrap et composition root minimale
- `application/` : orchestration transversale, sans Flutter UI, sans `dart:ui`, sans `dart:io` direct quand un port est possible
- `domain/` : contrats et logique métier pure
- `infrastructure/` : filesystem, JSON, implémentations concrètes
- `features/<feature>` : présentation et état feature-scoped

### Sous-dossiers UI cibles

À créer ou enrichir :

- [`packages/map_editor/lib/src/ui/panels/tileset_palette/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/)
- [`packages/map_editor/lib/src/ui/panels/terrain_editor/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/)
- [`packages/map_editor/lib/src/ui/panels/entity_properties/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/)
- [`packages/map_editor/lib/src/ui/panels/project_explorer/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer/)
- [`packages/map_editor/lib/src/ui/shared/top_toolbar/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar/)
- [`packages/map_editor/lib/src/ui/canvas/map_canvas/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/)
- [`packages/map_editor/lib/src/ui/canvas/dialogue_studio/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio/)
- enrichir :
  - [`packages/map_editor/lib/src/ui/canvas/step_studio/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio/)
  - [`packages/map_editor/lib/src/ui/canvas/cutscene_studio/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio/)
  - [`packages/map_editor/lib/src/ui/canvas/global_story_studio/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio/)

Convention interne recommandée :
- `*_panel.dart` ou `*_workspace.dart` : shell principal seulement
- `widgets/` : sous-widgets UI
- `dialogs/` : dialogues, pickers, menus
- `painters/` : `CustomPainter`
- `models/` : petits view models de présentation
- `helpers/` ou `services/` : helpers UI locaux
- `cache/` : caches d’images locaux si on ne peut pas encore les sortir ailleurs

---

## Stratégie de tests de non-régression

### État réel de la base de tests

Constat actuel :
- environ **240 tests**
- environ **201 unitaires**
- environ **39 widget tests**

Conclusion :
- bonne protection sur plusieurs sous-systèmes récents ;
- protection insuffisante sur le shell, les gros panels et l’orchestration centrale.

### Tests existants déjà utiles

#### Orchestration centrale
- [`editor_notifier_map_snapshot_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_map_snapshot_test.dart)
- [`editor_notifier_npc_waypoint_placement_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_npc_waypoint_placement_test.dart)

#### Dialogue
- [`dialogue_studio_explorer_dialogue_widgets_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_studio_explorer_dialogue_widgets_test.dart)
- [`dialogue_editor_validation_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_editor_validation_test.dart)
- [`dialogue_preview_runner_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_preview_runner_test.dart)
- [`dialogue_yarn_codec_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_yarn_codec_test.dart)
- [`dialogue_disk_hierarchy_v13_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart)

#### Narratif
- [`narrative_workspace_projection_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart)
- [`narrative_workspace_state_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_state_test.dart)
- [`step_studio_authoring_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/step_studio_authoring_test.dart)
- [`global_story_studio_authoring_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_authoring_test.dart)
- [`global_story_studio_behavior_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_behavior_test.dart)
- [`cutscene_studio_authoring_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_authoring_test.dart)
- [`cutscene_studio_map_context_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_map_context_test.dart)

#### Widget tests déjà exploitables
- [`step_studio_workspace_regression_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/step_studio_workspace_regression_test.dart)
- [`global_story_studio_workspace_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_workspace_test.dart)
- [`global_story_studio_ux_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_ux_test.dart)
- [`pokedex_workspace_ui_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart)

#### Pokémon et infra locale
- [`pokemon_project_data_reader_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart)
- [`pokemon_database_index_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart)
- [`file_pokemon_read_repository_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart)
- [`file_pokemon_write_repository_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart)
- [`list_pokedex_entries_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart)
- [`validate_pokemon_project_data_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart)
- [`project_pokemon_config_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_pokemon_config_test.dart)

### Surfaces insuffisamment couvertes

Les chantiers suivants doivent recevoir des tests avant ou pendant refactor :
- [`editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart)
- [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart)
- [`status_bar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/status_bar.dart)
- [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
- [`terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart)
- [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart)
- [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart)
- [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart)
- `ProviderContainer` wiring tests autour des providers centraux
- davantage de tests unitaires ciblés sur les sous-domaines sortis de `EditorNotifier`

### Doctrine de tests pour la refonte

Chaque lot doit embarquer :
- ses tests unitaires sur la logique extraite ;
- ses widget tests de smoke ou de régression sur la surface concernée ;
- ses tests de wiring provider si le lot modifie la composition Riverpod.

---

## Découpage recommandé en phases et lots

## Phase 1 — Sécuriser avant de couper

### Lot 1 — Filet de sécurité sur le shell et le chrome éditeur

**Objectif**
- Stabiliser l’UI globale avant toute extraction structurelle.

**Fichiers à modifier**
- [`packages/map_editor/test/editor_shell_page_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart) à créer
- [`packages/map_editor/test/top_toolbar_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart) à créer
- [`packages/map_editor/test/status_bar_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/status_bar_test.dart) à créer
- éventuellement [`packages/map_editor/test/test_app_harness.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/test_app_harness.dart) à créer si un harness commun est nécessaire

**Changements attendus**
- `editor_shell_page_smoke_test.dart`
  - vérifier que le shell se construit avec les dépendances minimales ;
  - verrouiller les zones majeures visibles : toolbar, canvas host, panneaux latéraux, status bar.
- `top_toolbar_test.dart`
  - verrouiller le rendu de base et les actions principales exposées par la toolbar ;
  - s’assurer que les callbacks essentiels restent branchés.
- `status_bar_test.dart`
  - verrouiller les informations visibles essentielles et le comportement de base.
- `test_app_harness.dart`
  - centraliser un `ProviderScope` et les mocks/fakes minimaux pour éviter de copier le wiring dans chaque test.

**Pourquoi ce lot d’abord**
- Sans ce filet, toute extraction de widgets ou réduction des watchers aura un coût de review trop élevé.

**Critère de sortie**
- Le shell et le chrome principal sont couverts par des tests simples mais robustes.

---

### Lot 2 — Filet de sécurité sur les panneaux lourds

**Objectif**
- Ajouter les premiers tests de non-régression là où les fichiers sont les plus gros et les moins sûrs à découper.

**Fichiers à modifier**
- [`packages/map_editor/test/project_explorer_panel_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_explorer_panel_test.dart) à créer
- [`packages/map_editor/test/terrain_editor_panel_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/terrain_editor_panel_smoke_test.dart) à créer
- [`packages/map_editor/test/tileset_palette_panel_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/tileset_palette_panel_smoke_test.dart) à créer
- [`packages/map_editor/test/dialogue_studio_workspace_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/dialogue_studio_workspace_smoke_test.dart) à créer
- [`packages/map_editor/test/cutscene_studio_workspace_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/cutscene_studio_workspace_smoke_test.dart) à créer

**Changements attendus**
- `project_explorer_panel_test.dart`
  - verrouiller l’arbre visible, les zones vides, le comportement de sélection de base.
- `terrain_editor_panel_smoke_test.dart`
  - verrouiller le rendu de base, les sections principales, les callbacks clés.
- `tileset_palette_panel_smoke_test.dart`
  - verrouiller le rendu des zones de palette et de sélection sans tester tous les cas extrêmes.
- `dialogue_studio_workspace_smoke_test.dart`
  - verrouiller le rendu initial et l’absence de crash sur le wiring.
- `cutscene_studio_workspace_smoke_test.dart`
  - verrouiller le rendu de base et les composants majeurs visibles.

**Critère de sortie**
- Les gros panneaux deviennent refactorables sans travailler à l’aveugle.

---

## Phase 2 — Réparer les frontières d’architecture

### Lot 3 — Supprimer les fuites UI -> infrastructure

**Objectif**
- Faire en sorte que l’UI ne construise plus directement des implémentations infra.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart)
- [`packages/map_editor/lib/src/app/providers/core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart)
- [`packages/map_editor/lib/src/app/providers/use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart)
- éventuellement [`packages/map_editor/test/pokedex_workspace_ui_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart)

**Changements attendus**
- `pokedex_workspace_loader.dart`
  - arrêter toute instanciation directe de repository/reader filesystem ;
  - dépendre uniquement de providers applicatifs.
- `core_providers.dart`
  - centraliser l’assemblage des implémentations infra nécessaires à la lecture Pokémon.
- `use_case_providers.dart`
  - exposer proprement les use cases/ports déjà existants au lieu de laisser l’UI câbler elle-même la lecture.
- `pokedex_workspace_ui_test.dart`
  - adapter le test si le wiring passe par provider plutôt que par instanciation directe.

**Critère de sortie**
- Aucun code UI ne construit directement une implémentation filesystem de lecture Pokémon.

---

### Lot 4 — Sortir `dart:io` de la couche application là où un port doit exister

**Objectif**
- Retirer les dépendances filesystem directes des use cases/services applicatifs.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart)
- [`packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart)
- [`packages/map_editor/lib/src/application/use_cases/dialogue_disk_path_support.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/dialogue_disk_path_support.dart)
- [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
- [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart)
- ports ou repositories ciblés sous :
  - [`packages/map_editor/lib/src/application/ports/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/)
  - [`packages/map_editor/lib/src/infrastructure/repositories/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/)
- tests ciblés correspondants

**Changements attendus**
- `project_dialogue_use_cases.dart`
  - remplacer la manipulation directe du disque par un port dialogue/project storage.
- `project_dialogue_library_use_cases.dart`
  - même traitement côté bibliothèque de dialogue.
- `dialogue_disk_path_support.dart`
  - soit déplacer en infrastructure si c’est purement filesystem ;
  - soit le réduire à une logique pure sans `dart:io`.
- `initialize_pokemon_project_storage_use_case.dart`
  - dépendre d’un port d’initialisation de storage.
- `seed_pokemon_demo_data_use_case.dart`
  - dépendre d’un port d’écriture/seed, pas du disque direct.

**Critère de sortie**
- La couche application ne dépend plus de `dart:io` là où la frontière infra est claire.

---

### Lot 5 — Sortir les détails UI/platform de la couche application

**Objectif**
- Arrêter de faire vivre des types Flutter/UI dans `application`.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart)
- [`packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/terrain_preset_selection_coordinator.dart)
- [`packages/map_editor/lib/src/features/editor/state/editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart)
- nouveaux fichiers éventuels sous :
  - [`packages/map_editor/lib/src/ui/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/)
  - ou [`packages/map_editor/lib/src/features/editor/ui/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/ui/)

**Changements attendus**
- `entity_editor_element_visual.dart`
  - déplacer en UI ou presentation helper si le type est purement visuel ;
  - ou scinder en deux : logique pure d’un côté, rendu Flutter de l’autre.
- `terrain_preset_selection_coordinator.dart`
  - ne plus dépendre de `EditorState` ;
  - introduire un petit type applicatif dédié si le besoin est de modéliser un mode de sélection, sans importer l’état global.
- `editor_state.dart`
  - retirer ce qui existe uniquement pour satisfaire un helper applicatif mal placé.

**Critère de sortie**
- `application/` ne contient plus de dépendance Flutter visuelle ni de dépendance vers l’état global d’édition pour des helpers qui devraient être plus purs.

---

## Phase 3 — Casser le monolithe `EditorNotifier`

### Lot 6 — Cartographier puis isoler les responsabilités de `EditorState`

**Objectif**
- Préparer la décomposition de `EditorNotifier` en réduisant l’ambiguïté de `EditorState`.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/features/editor/state/editor_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_state.dart)
- nouveaux types sous :
  - [`packages/map_editor/lib/src/features/editor/state/models/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/models/)
- tests :
  - nouveaux tests unitaires dédiés à `EditorState`

**Changements attendus**
- `editor_state.dart`
  - identifier et extraire des groupes cohérents :
    - session projet ;
    - sélection ;
    - outil/canvas ;
    - panneaux / UI chrome ;
    - éventuels signaux transitoires.
- créer des types imbriqués dédiés pour éviter une structure plate géante.

**Critère de sortie**
- `EditorState` devient lisible, découpé par responsabilités, sans changer les comportements.

---

### Lot 7 — Extraire la logique “session projet / document” hors de `EditorNotifier`

**Objectif**
- Commencer par l’axe le plus transversal : ouverture/fermeture projet, map active, snapshot principal, dirty state.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart)
- nouveaux fichiers à créer :
  - [`packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart)
  - [`packages/map_editor/lib/src/features/editor/application/project_session_models.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/project_session_models.dart)
- tests :
  - [`packages/map_editor/test/editor_project_session_controller_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/editor_project_session_controller_test.dart) à créer
  - adaptation des tests existants sur `editor_notifier`

**Changements attendus**
- `editor_notifier.dart`
  - déléguer les responsabilités session/document au nouveau composant.
- `project_session_controller.dart`
  - encapsuler l’orchestration de session sans dépendre de l’UI.
- `project_session_models.dart`
  - définir les types de résultat utiles si besoin.

**Critère de sortie**
- `EditorNotifier` perd une tranche entière de responsabilités transversales.

---

### Lot 8 — Extraire la logique “édition map / entités / terrain” hors de `EditorNotifier`

**Objectif**
- Sortir le noyau d’édition de map du store global.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart)
- nouveaux fichiers à créer :
  - [`packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart)
  - [`packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart)
- tests à créer :
  - [`packages/map_editor/test/map_editing_controller_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_editing_controller_test.dart)
  - [`packages/map_editor/test/map_selection_controller_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_selection_controller_test.dart)

**Changements attendus**
- `editor_notifier.dart`
  - déléguer mutations map, sélection de tuiles, entités, terrain.
- `map_editing_controller.dart`
  - concentrer les règles d’édition et mutations sur le document actif.
- `map_selection_controller.dart`
  - sortir toute la logique de sélection outillée.

**Critère de sortie**
- `EditorNotifier` cesse d’être le point d’entrée exclusif de tout l’editing map.

---

### Lot 9 — Extraire les flux secondaires encore dans `EditorNotifier`

**Objectif**
- Finir le découpage du notifier en sortant les zones restantes : narration, dialogue, Pokédex, workflow auxiliaire.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart)
- fichiers existants à renforcer :
  - [`packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart)
  - [`packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart)
- fichiers à créer si nécessaire :
  - providers dédiés pour Pokedex et dialogue
- tests :
  - provider wiring tests via `ProviderContainer`

**Changements attendus**
- déplacer hors du notifier central tout ce qui relève déjà d’un sous-système identifié ;
- conserver `EditorNotifier` uniquement comme façade ou coordinateur léger si nécessaire.

**Critère de sortie**
- `EditorNotifier` n’est plus un store global monolithique, mais une façade fine ou un agrégat léger.

---

## Phase 4 — Moderniser Riverpod et la composition root

### Lot 10 — Réduire les watchers globaux et introduire des sélecteurs ciblés

**Objectif**
- Réduire les rebuilds et le couplage UI -> état global.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/editor_shell_page.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/editor_shell_page.dart)
- [`packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart)
- [`packages/map_editor/lib/src/ui/shared/top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart)
- [`packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart)
- [`packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart)
- [`packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
- nouveaux fichiers à créer :
  - `editor_selectors.dart`
  - providers dérivés par surface

**Changements attendus**
- remplacer les `ref.watch(editorNotifierProvider)` globaux par :
  - des providers dérivés ;
  - des `select` ciblés ;
  - des notifiers/sources d’état plus petits.

**Critère de sortie**
- Les grosses surfaces ne rebuildent plus sur l’ensemble de l’état.

**État réel**
- Fait.
- Sélecteurs/snapshots ajoutés pour :
  - le shell global ;
  - le canvas host ;
  - la toolbar ;
  - le project explorer ;
  - les racines `TerrainEditorPanel`, `TerrainLibraryPanel`, `PathLibraryPanel` ;
  - la racine `TilesetPalettePanel`.
- L’effet recherché est atteint sans refonte interne des gros panneaux : on a réduit le scope de rebuild au niveau des racines, tout en conservant la logique métier et UI existante.

---

### Lot 11 — Réorganiser la composition root Riverpod

**Objectif**
- Faire de `app/providers` une vraie composition root lisible, pas un entrepôt massif.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/app/providers/core_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core_providers.dart)
- [`packages/map_editor/lib/src/app/providers/use_case_providers.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/use_case_providers.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/app/providers/core/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/core/)
  - [`packages/map_editor/lib/src/app/providers/dialogue/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/dialogue/)
  - [`packages/map_editor/lib/src/app/providers/narrative/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/narrative/)
  - [`packages/map_editor/lib/src/app/providers/pokedex/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/)
  - [`packages/map_editor/lib/src/app/providers/editor/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/editor/)
- tests :
  - [`packages/map_editor/test/provider_wiring_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/provider_wiring_test.dart) à créer

**Changements attendus**
- `core_providers.dart`
  - ne garder que les providers vraiment transverses.
- `use_case_providers.dart`
  - éclater par thème au lieu d’un seul fichier de près de 1000 lignes.
- `provider_wiring_test.dart`
  - vérifier qu’un `ProviderContainer` peut résoudre les groupes principaux sans couplages cachés.

**Critère de sortie**
- La composition root est lisible et structurée par thème, avec un blast radius réduit.

**État réel**
- Fait.
- `app/providers` est désormais réparti en sous-dossiers thématiques :
  - `core/`
  - `editor/`
  - `dialogue/`
  - `pokedex/`
- Les anciens points d’entrée sont conservés comme barrels de compatibilité, ce qui garde le scope fonctionnel stable pendant la refonte.
- Le wiring principal est couvert par `provider_wiring_test.dart`.

---

## Phase 5 — Découper et ranger les surfaces UI

### Lot 12 — Découper le chrome global : toolbar et explorer projet

**Objectif**
- Réduire immédiatement deux surfaces importantes et relativement accessibles.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/shared/top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart)
- nouveaux fichiers à créer sous :
  - [`packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/)
  - [`packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/)
  - [`packages/map_editor/lib/src/ui/shared/top_toolbar/builders/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar/builders/)
- [`packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart)
- nouveaux fichiers à créer sous :
  - [`packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer/widgets/tree/)
  - [`packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer/dialogs/)
  - [`packages/map_editor/lib/src/ui/panels/project_explorer/dnd/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer/dnd/)
- tests à adapter :
  - `top_toolbar_test.dart`
  - `project_explorer_panel_test.dart`

**Changements attendus**
- `top_toolbar.dart`
  - devenir un shell d’assemblage ;
  - sortir groupes de boutons, dialogs et petits builders.
- `project_explorer_panel.dart`
  - sortir l’arbre, les lignes, les dialogs et le drag-and-drop.

**Critère de sortie**
- Ces deux fichiers doivent passer sous une taille raisonnable et ne plus mêler tout leur sous-système dans un seul fichier.

**État réel**
- Fait.
- [`top_toolbar.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/top_toolbar.dart)
  - devenu un shell d’assemblage ;
  - widgets extraits sous `ui/shared/top_toolbar/widgets/` ;
  - dialogs extraits sous `ui/shared/top_toolbar/dialogs/`.
- [`project_explorer_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart)
  - devenu un shell d’assemblage ;
  - drag-and-drop tilesets extrait sous `ui/panels/project_explorer/dnd/` ;
  - dialogs explorer extraits sous `ui/panels/project_explorer/dialogs/` ;
  - actions d’entête et nœuds d’arbre extraits sous `ui/panels/project_explorer/widgets/`.

---

### Lot 13 — Découper les studios narratifs

**Objectif**
- Stabiliser le sous-système narratif comme un ensemble cohérent.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart)
- [`packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart)
- [`packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart)
- sous-dossiers à enrichir :
  - [`packages/map_editor/lib/src/ui/canvas/step_studio/widgets/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio/widgets/)
  - [`packages/map_editor/lib/src/ui/canvas/cutscene_studio/widgets/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio/widgets/)
  - [`packages/map_editor/lib/src/ui/canvas/cutscene_studio/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio/dialogs/)
  - [`packages/map_editor/lib/src/ui/canvas/global_story_studio/widgets/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio/widgets/)
- tests à adapter :
  - `step_studio_workspace_regression_test.dart`
  - `global_story_studio_workspace_test.dart`
  - `global_story_studio_ux_test.dart`
  - `cutscene_studio_authoring_test.dart`
  - `cutscene_studio_map_context_test.dart`
  - `cutscene_studio_workspace_smoke_test.dart`

**Changements attendus**
- `step_studio_workspace.dart`
  - sortir sections, rows et composants communs.
- `cutscene_studio_workspace.dart`
  - sortir éditeurs par type de bloc, source widgets et dialogs.
- `global_story_studio_workspace.dart`
  - sortir cards, rows, widgets répétitifs.

**Critère de sortie**
- Le sous-système narratif devient navigable et maintenable fichier par fichier.

**État réel**
- Fait.
- [`step_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart)
  - garde le shell et la logique de brouillon ;
  - widgets/supports locaux sortis dans `ui/canvas/step_studio/step_studio_workspace_support.dart`.
- [`global_story_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart)
  - garde l’hydratation, le draft et l’assemblage du shell narratif ;
  - les reliquats legacy non branchés ont été supprimés au lieu d’être simplement “rangés” dans un sous-dossier.
- [`cutscene_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart)
  - conserve le shell et l’orchestration locale ;
  - blocs/supports répétitifs sortis dans `ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart`.
- Tests narratifs ciblés relancés :
  - `step_studio_workspace_regression_test.dart`
  - `global_story_studio_workspace_test.dart`
  - `global_story_studio_behavior_test.dart`
  - `global_story_studio_ux_test.dart`
  - `cutscene_studio_map_context_test.dart`
- Analyse ciblée verte sur les fichiers du lot.

---

### Lot 14 — Découper `dialogue_studio_workspace`

**Objectif**
- Isoler le sous-système dialogue sans le mélanger au reste de la refonte.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/library/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/library/)
  - [`packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/canvas/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/canvas/)
  - [`packages/map_editor/lib/src/ui/canvas/dialogue_studio/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio/dialogs/)
  - [`packages/map_editor/lib/src/ui/canvas/dialogue_studio/helpers/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio/helpers/)
- tests à adapter :
  - `dialogue_studio_workspace_smoke_test.dart`
  - `dialogue_studio_explorer_dialogue_widgets_test.dart`

**Changements attendus**
- garder `dialogue_studio_workspace.dart` comme shell ;
- sortir les sous-zones et helpers UI ;
- si du réseau IA ou de l’I/O reste mêlé au widget, le pousser derrière les couches déjà existantes au lieu de le laisser dans le shell.

**Critère de sortie**
- Le studio dialogue est découpé sans réécrire son produit.

**État réel**
- Fait.
- [`dialogue_studio_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart)
  - garde le shell, le document de travail, l’inspecteur et la logique d’édition locale ;
  - a été réduit à environ 1704 lignes.
- Extraire sans changer le produit :
  - dialogs/prompts dans `ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart`
  - arbre bibliothèque dans `ui/canvas/dialogue_studio/widgets/library/dialogue_library_tree.dart`
  - cartes/nœuds du canvas dans `ui/canvas/dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart`
- Tests ciblés relancés :
  - `dialogue_studio_explorer_dialogue_widgets_test.dart`
  - `ui_panels_smoke_test.dart`
- Analyse ciblée verte sur les fichiers du lot.

---

### Lot 15 — Découper `map_canvas` et `entity_properties_panel`

**Objectif**
- Réduire deux surfaces lourdes qui touchent le cœur d’édition.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/canvas/map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/ui/canvas/map_canvas/painters/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/painters/)
  - [`packages/map_editor/lib/src/ui/canvas/map_canvas/helpers/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/helpers/)
  - [`packages/map_editor/lib/src/ui/canvas/map_canvas/cache/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/cache/)
- [`packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/ui/panels/entity_properties/widgets/sections/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/widgets/sections/)
  - [`packages/map_editor/lib/src/ui/panels/entity_properties/widgets/common/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/widgets/common/)
  - [`packages/map_editor/lib/src/ui/panels/entity_properties/models/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/models/)
  - [`packages/map_editor/lib/src/ui/panels/entity_properties/helpers/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/helpers/)
- tests à créer/adapter :
  - `map_canvas_smoke_test.dart`
  - `entity_properties_panel_test.dart`

**Changements attendus**
- `map_canvas.dart`
  - sortir painters, cache d’images, helpers de collecte/résolution.
- `entity_properties_panel.dart`
  - sortir sections par type d’entité, brouillons locaux et helpers de binding.

**Critère de sortie**
- Le canvas et les propriétés d’entité deviennent lisibles et révisables.

**État réel**
- Fait.
- [`map_canvas.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas.dart)
  - garde désormais le widget principal, le flux d’interaction et la synchronisation locale ;
  - a sorti le cache/chargement image vers [`map_canvas_assets.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart) ;
  - a sorti le gros painter vers [`map_grid_painter.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart) ;
  - est descendu à environ 672 lignes.
- [`entity_properties_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart)
  - garde le shell du panneau et la logique d’édition principale ;
  - a sorti les drafts locaux vers [`entity_properties_drafts.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_drafts.dart) ;
  - a sorti les helpers de support dialogue vers [`entity_properties_dialogue_support.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_dialogue_support.dart) ;
  - a sorti le binding UI dialogue/Yarn vers [`entity_properties_dialogue_bindings.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_dialogue_bindings.dart) ;
  - a sorti le bloc waypoints/mouvement PNJ vers [`entity_properties_npc_runtime.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/entity_properties/entity_properties_npc_runtime.dart) ;
  - est descendu à environ 2324 lignes.
- Test direct ajouté :
  - [`map_canvas_entity_properties_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart)
    - couvre un rendu direct de `MapCanvas` avec `MapData` réel ;
    - couvre un rendu direct de `EntityPropertiesPanel` avec une entité PNJ sélectionnée.
- Validations vertes :
  - `flutter test test/map_canvas_entity_properties_smoke_test.dart test/ui_panels_smoke_test.dart`
  - `flutter analyze --no-pub lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_canvas_assets.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/panels/entity_properties_panel.dart lib/src/ui/panels/entity_properties/entity_properties_dialogue_support.dart lib/src/ui/panels/entity_properties/entity_properties_drafts.dart lib/src/ui/panels/entity_properties/entity_properties_dialogue_bindings.dart lib/src/ui/panels/entity_properties/entity_properties_npc_runtime.dart test/map_canvas_entity_properties_smoke_test.dart test/ui_panels_smoke_test.dart`

---

### Lot 16 — Découper les deux plus gros monstres : terrain et tileset palette

**Objectif**
- Traiter les plus grosses dettes restantes en dernier, quand les frontières, l’état et les tests sont déjà sécurisés.

**État réel**
- En cours.
- La moitié `terrain_editor_panel` est déjà passée de plus de 5000 lignes à environ 1594 lignes.
- Extractions déjà réalisées et validées :
  - [`terrain_editor/dialogs/terrain_preset_dialogs.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart)
  - [`terrain_editor/widgets/terrain_mapping_workspace.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart)
- Première extraction `tileset_palette_panel` déjà posée :
  - [`tileset_palette/widgets/palette/tileset_palette_preview.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/tileset_palette_preview.dart)
- Validations déjà vertes sur cette tranche :
  - `flutter test test/ui_panels_smoke_test.dart`
  - `flutter analyze --no-pub lib/src/ui/panels/terrain_editor_panel.dart lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart test/ui_panels_smoke_test.dart`
- Le sous-lot restant est maintenant concentré sur [`tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart).
- Note honnête :
  - le smoke test palette reste vert ;
  - l’analyse ciblée du panneau palette remonte encore des warnings historiques (`prefer_const_*`, `deprecated_member_use`) déjà présents dans le fichier massif et non traités dans cette tranche.

**Fichiers à modifier**
- [`packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/)
  - [`packages/map_editor/lib/src/ui/panels/terrain_editor/painters/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/painters/)
  - [`packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/library/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/library/)
  - [`packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/path_editor/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/path_editor/)
  - [`packages/map_editor/lib/src/ui/panels/terrain_editor/cache/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor/cache/)
- [`packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
- nouveaux sous-dossiers à créer :
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/dialogs/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/dialogs/)
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/painters/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/painters/)
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/)
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/)
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/palette/)
  - [`packages/map_editor/lib/src/ui/panels/tileset_palette/cache/`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/cache/)
- tests à adapter :
  - `terrain_editor_panel_smoke_test.dart`
  - `tileset_palette_panel_smoke_test.dart`

**Changements attendus**
- `terrain_editor_panel.dart`
  - shell principal uniquement ;
  - sortir dialogs, painters, path editor, bibliothèque, cache.
- `tileset_palette_panel.dart`
  - shell principal uniquement ;
  - sortir dialogs, painters, widgets de collision, widgets de palette, cache.

**Critère de sortie**
- Les deux plus gros fichiers du projet passent sous contrôle, avec une structure lisible par thème.

---

## Ordre recommandé de mise en œuvre

Ordre strict recommandé :
1. Lot 1
2. Lot 2
3. Lot 3
4. Lot 4
5. Lot 5
6. Lot 6
7. Lot 7
8. Lot 8
9. Lot 9
10. Lot 10
11. Lot 11
12. Lot 12
13. Lot 13
14. Lot 14
15. Lot 15
16. Lot 16

Justification :
- déplacer les fichiers avant de casser les fuites de couches et le centre de gravité notifier reviendrait surtout à déplacer la dette ;
- attaquer `terrain_editor_panel.dart` et `tileset_palette_panel.dart` trop tôt coûterait très cher sans filet de tests ni réduction préalable des couplages ;
- le sous-système narratif peut être restructuré plus tôt que le terrain/tileset, car il a déjà un meilleur niveau de structuration et de tests.

---

## Règles de validation pour chaque lot

Chaque lot doit respecter la même discipline :

1. **Scope strict**
   - aucun changement produit ;
   - aucun ajout de feature ;
   - aucun élargissement opportuniste.

2. **Tests**
   - ajout ou adaptation des tests de non-régression du lot ;
   - exécution ciblée des tests concernés ;
   - si un lot modifie le wiring Riverpod, ajout de tests `ProviderContainer`.

3. **Analyse**
   - `flutter analyze --no-pub` ciblé sur les fichiers modifiés.

4. **Architecture**
   - aucune nouvelle fuite de couche ;
   - pas de logique métier rapatriée dans l’UI ;
   - pas de provider utilisé comme service locator déguisé sans justification.

5. **Taille**
   - tout fichier découpé doit finir significativement plus petit ;
   - le shell restant doit être lisible et concentré sur l’assemblage.

---

## Résultat attendu à la fin du programme

À la fin de ces lots, `map_editor` doit avoir :
- un noyau d’édition moins centralisé ;
- des frontières plus propres entre UI, application et infrastructure ;
- une composition Riverpod plus moderne et plus granulaire ;
- des gros widgets transformés en shells lisibles ;
- des sous-dossiers thématiques qui reflètent les responsabilités réelles ;
- un filet de tests qui sécurise enfin la refonte continue.

Le projet ne sera pas “parfait”, mais il redeviendra :
- compréhensible ;
- refactorable ;
- plus sûr à faire évoluer ;
- et beaucoup moins trompeur sur la réalité de son architecture.

---

## Hors périmètre / non traité

Ces sujets sont réels, mais ne doivent pas être absorbés dans ce chantier sans décision explicite :
- refonte produit du runtime ;
- redesign UI/UX ;
- introduction de recherche avancée ou d’index persistant ;
- réécriture complète de la navigation ;
- refonte du package `map_core` ;
- réorganisation inter-packages `map_editor` / `map_runtime` / `map_gameplay` ;
- migration massive vers une architecture entièrement feature-first sur tout le monorepo ;
- ajout de nouvelles fonctionnalités Pokédex ou import externe.

---

## Conclusion honnête

Le bon plan n’est pas “couper les gros fichiers en morceaux” en premier.  
Le bon plan est :
- de sécuriser les surfaces par des tests ;
- de réparer les frontières de couches ;
- de casser le monolithe `EditorNotifier` ;
- de réduire le rebuild scope Riverpod ;
- puis seulement de ranger et découper la présentation par thème.

Si cet ordre n’est pas respecté, le projet risque surtout de se retrouver avec :
- plus de fichiers ;
- mais la même dette ;
- et encore plus de wiring fragile.

Si cet ordre est respecté, alors la réduction de taille des fichiers, l’organisation en sous-dossiers et le respect rigoureux de l’architecture deviennent enfin des effets durables, pas une illusion de propreté.
