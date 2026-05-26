# NS-HOME-00 — Narrative Studio Overview Roadmap Proposal

## 1. Résumé exécutif

L'image `1 - page d'accueil.png` décrit une bonne direction produit pour PokeMap : ouvrir le Narrative Studio sur un tableau de bord créateur, dense, moderne, orienté authoring, et non sur un écran runtime joueur.

Le repo contient déjà une base réelle à exploiter :

- un shell editor avec top toolbar, sidebar, canvas central, inspecteur droit et status bar ;
- un `NarrativeWorkspaceCanvas` branché depuis le shell ;
- des sous-workspaces `Global Story`, `Step Studio`, `Cutscene Studio` et `Dialogue Studio` ;
- une projection narrative existante qui sait déjà résumer global stories, local event flows, steps et outcomes ;
- des modèles et use cases pour `ScenarioAsset`, dialogues, metadata Global Story / Step / Cutscene, validation narrative et pickers.

Mais la page d'accueil cible ne doit pas être implémentée en copiant les nombres de l'image. Plusieurs métriques visibles dans l'image ne sont pas encore des données produit fiables : quêtes, facts, statuts éditoriaux, activité récente, notifications et certains tags globaux. La meilleure approche est donc progressive : d'abord définir un contrat de données honnête, ensuite créer une projection/read model, puis construire l'UI section par section avec empty states explicites.

Premier lot recommandé après NS-HOME-00 :

```text
NS-HOME-01 — Narrative Overview Data Contract / Metric Semantics V0
```

Raison : ce lot protège la future belle UI contre les compteurs faux, les mocks trompeurs et le mélange authoring/runtime.

## 2. Fichiers audités

### Références demandées

- `AGENTS.md`
- `agent_rules.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- Image : `/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png`

`agent_rules.md` existe et a été lu par recherche ciblée.

### UI / shell editor audités

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`

### Narrative Studio / authoring audités

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_focus.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_palette.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio/widgets/library/dialogue_library_tree.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart`
- `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_runtime_advisories.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart`
- `packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`

### Modèles / read models / validation audités

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart`
- `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/validation/beta_playability_validator.dart`
- `packages/map_core/lib/src/validation/dialogue_validation.dart`

### Runtime audité en lecture seule

- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/lib/src/application/dialogue_runtime_models.dart`
- `packages/map_runtime/lib/src/application/load_dialogue_content.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Ces fichiers runtime sont utiles pour comprendre les frontières, mais le dashboard cible est une surface `map_editor`. Le runtime ne doit pas devenir une dépendance de l'overview.

### Fichiers non audités en détail

- Fichiers générés `*.g.dart` et `*.freezed.dart` : exclus car les sources manuelles suffisent pour l'audit produit.
- Tout `build/` et `.dart_tool/` : exclus car artifacts.
- Toutes les sources runtime Flame détaillées hors scénarios/dialogues : hors scope du dashboard auteur.
- Tous les écrans Pokédex/Path/Environment hors éléments de shell : utiles pour style et patterns, mais secondaires pour cette page.

## 3. État actuel du Narrative Studio

### Branchement actuel

Le Narrative Studio est branché dans le shell editor par le mode de workspace :

- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` définit `globalStory`, `step`, `cutscene`, `dialogue`.
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` route ces quatre modes vers `NarrativeWorkspaceCanvas`.
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` choisit ensuite le sous-workspace actif.
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` expose une carte `Narrative Studio` dans la sidebar actuelle.
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart` offre une navigation embarquée vers Global Story, Step, Cutscene, Dialogue et Outcomes.
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart` expose un inspecteur droit contextuel.

### Widgets / workspaces existants

| Surface | Chemin | État | Commentaire |
|---|---|---|---|
| Shell global editor | `packages/map_editor/lib/src/ui/editor_shell_page.dart` | UI réutilisable partiellement | Structure desktop solide : toolbar, sidebar, content area, inspector, status bar. Trop orientée tool général pour l'image cible. |
| Top toolbar | `packages/map_editor/lib/src/ui/shared/top_toolbar.dart` | UI réutilisable partiellement | Actions projet/map/workspace existantes ; pas encore la top bar Narrative Overview de l'image. |
| Project explorer | `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | UI réutilisable partiellement | Carte `Narrative Studio` déjà présente ; navigation trop “modules editor” pour la sidebar cible. |
| Canvas host | `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` | UI déjà exploitable | Route correctement vers `NarrativeWorkspaceCanvas`. |
| Narrative canvas | `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | UI déjà exploitable | Centre les sous-studios ; manque une vue `Aperçu`. |
| Global Story workspace | `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart` | UI réutilisable partiellement | Source réelle pour storyline/chapitres/steps ; doit être résumé, pas affiché tel quel en accueil. |
| Step Studio | `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart` | UI réutilisable partiellement | Source réelle pour steps, conditions, outcomes, world changes ; encore trop détaillée pour l'accueil. |
| Cutscene Studio | `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart` | UI réutilisable partiellement | Source pour cinématiques/local event flows ; ne doit pas être confondu avec “Scènes” si la définition n'est pas figée. |
| Dialogue Studio | `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart` | UI déjà exploitable | Gère bibliothèque, canvas visuel, preview, Yarn ; source réelle pour dialogues. |
| Narrative inspector | `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart` | À remplacer pour cette page | Inspecteur technique/contextuel ; l'image demande un panneau “Structure narrative” global. |
| Narrative library | `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart` | À repositionner | Utile pour navigation, mais expose encore `nodes`, `emitters`, `consumers`, outcomes bruts. |
| Status bar | `packages/map_editor/lib/src/ui/shared/status_bar.dart` | À utiliser avec prudence | Aujourd'hui statut save/dirty ; ne doit pas devenir un statut runtime ni être confondu avec Project Health. |

### Écrans correspondant aux sections de l'image

| Section image | État repo actuel |
|---|---|
| Aperçu | Absent. Aucun `Narrative Overview` dashboard dédié identifié. |
| Storylines | Partiellement présent via `GlobalStoryStudioWorkspace` et `ScenarioAsset.scope == globalStory`. |
| Maps | Présent via `MapCanvas`, `ProjectExplorerPanel`, `ProjectManifest.maps`. |
| Scènes | Concept à clarifier. Peut être approché via steps, local event flows ou cutscene blocks, mais pas un modèle `Scene` dédié. |
| Cinématiques | Présent via Cutscene Studio sur `ScenarioAsset.scope == localEventFlow` + metadata cutscene. |
| Dialogues | Présent via `ProjectDialogueEntry`, Dialogue Studio, Yarn codec et dialogue library. |
| Facts | Pas de modèle first-class `Fact` identifié. Des références/predicates existent, mais pas une encyclopédie/lore authorée. |
| World Rules | Partiellement présent via predicates, `worldChanges`, visibility rules et adapters authoring, mais pas un registre produit complet. |
| Validateur | Présent côté `ProjectValidator`, `BetaPlayabilityValidator`, `NarrativeValidatorAuthoringAdapter`, mais pas encore en UI dashboard overview. |

### Logique métier existante

- `ProjectManifest.scenarios`, `ProjectManifest.dialogues`, `ProjectManifest.maps`.
- `ScenarioAsset` avec `scope`, `declaredOutcomes`, `activationCondition`, nodes, edges, metadata.
- `GlobalStoryStudioDocument` avec chapters et structure macro.
- `StepStudioDocument` avec activation, completion, cutscenes, outcomes, world changes.
- `CutsceneStudioDocument` / flow metadata et compilation vers `ScenarioAsset`.
- `DialogueEditorDocument` et Yarn codec.
- `NarrativeWorkspaceProjection` qui projette global stories, local event flows, steps, outcomes.
- `NarrativeReferencePickerReadModels` dans `map_core` pour pickers scénarios, steps, event sources, predicates, battles.
- `NarrativeValidatorAuthoringAdapter` pour rendre des diagnostics plus orientés auteur.

### Logique absente ou insuffisante pour l'accueil

- Read model `NarrativeOverviewReadModel`.
- Définition stable de `Scene` distincte de cutscene, step ou local event flow.
- Modèle de quêtes authorées.
- Modèle first-class de facts/lore.
- Statuts éditoriaux `Défini`, `En cours`, `Brouillon`, `À revoir`, `Bloquant`.
- Activité récente d'authoring persistée.
- Notifications editor réelles pour le dashboard.
- Project Health global non confondu avec sauvegarde ou dirty state.
- Tags globaux d'univers narratif, sauf tags ponctuels sur certains modèles comme dialogues/maps/groups.

### Mocks et données hardcodées

Aucun écran d'accueil Narrative Overview codé n'a été identifié, donc aucun mock de cette page n'existe actuellement. Les nombres visibles dans l'image (`5`, `42`, `18`, `24`, `1 236`, `12`) doivent rester une référence visuelle, pas une donnée à recopier.

Points dangereux déjà visibles côté UI actuelle :

- `NarrativeLibraryPanel` affiche encore `${nodeCount} nodes`, `emitters`, `consumers`, outcome IDs.
- `NarrativeInspectorPanel` affiche `Local Event Flows / Cutscenes`, `Outcomes`, `projected`.
- `TopToolbar` est encore orientée outils/workspaces et pas dashboard auteur.
- `StatusBar` expose dirty/sync ; le dashboard cible ne doit pas afficher “Tous les changements enregistrés” ni une progression runtime.

## 4. Analyse de l'image cible

L'image est une référence d'architecture produit, pas une maquette pixel-perfect à cloner. Elle propose :

- un seul shell premium desktop ;
- une sidebar Narrative Studio claire ;
- une vue d'ensemble centrale ;
- des KPI authoring ;
- une carte Histoire principale ;
- une grille de modules narratifs ;
- une activité récente ;
- un panneau droit Structure narrative ;
- des statuts éditoriaux ;
- des actions de création, aperçu et validation.

Décision produit : cette page doit parler de contenu auteur, pas de sauvegarde joueur.

À garder :

- “Aperçu” comme entrée de dashboard.
- `Chapitres`, `Scènes`, `Cinématiques`, `Dialogues`, `Problèmes ouverts`.
- “Conditions narratives” au lieu de “États du monde”.
- “En cours” comme statut éditorial, pas “Jouable”.
- `Project Health` uniquement comme synthèse diagnostics/projet.

À refuser :

- pourcentage de progression de partie ;
- barre de completion runtime ;
- état de sauvegarde ;
- activité récente inventée ;
- compteurs hardcodés ;
- confusion entre quêtes authorées et variables `quest.step` ;
- `Facts` affichés comme compteur réel tant qu'il n'existe pas de source fiable.

## 5. Mapping image → architecture repo

| Zone image | Données nécessaires | Source actuelle | Widget existant / nouveau probable | Package | Niveau | Risques / dépendances |
|---|---|---|---|---|---|---|
| Top bar globale | App name, project, workspace, actions | `EditorState.project`, `TopToolbarBrand` | Réutiliser tokens/brand, créer variante Narrative shell | `map_editor` | V1 | Ne pas casser la toolbar map existante. |
| Sélecteur de projet | Nom projet, miniature optionnelle, chemin | `ProjectManifest.name`, `projectRootPath` | Adaptation de toolbar/dialog project open | `map_editor` | V0 | Miniature projet non modélisée ; fallback icône. |
| Breadcrumb | Home, Narrative Studio, Aperçu | `EditorWorkspaceMode` + future route overview | Nouveau petit widget | `map_editor` | V0 | Ne pas créer un router global si non nécessaire. |
| Actions globales | Nouvelle storyline, Aperçu, Valider | Scenarios + validator | Nouveaux boutons shell overview | `map_editor` | V1 | `Nouvelle storyline` doit appeler un vrai use case ou rester désactivé/empty en V0. |
| Actions secondaires | Search, notifications, settings | Settings existe ; search/notifications non globales | Nouveaux boutons, notifications later | `map_editor` | Plus tard | Notifications non réelles aujourd'hui. |
| Sidebar | Aperçu, Storylines, Maps, Scènes, Cinématiques, Dialogues, Facts, World Rules, Validateur | Modes existants partiels | Nouvelle sidebar Narrative Studio ou adaptation ProjectExplorer | `map_editor` | V0/V1 | Ne pas dupliquer tout l'app shell. |
| Project Health | Synthèse diagnostics | Validators existants, pas agrégat dashboard | Nouveau `NarrativeProjectHealthSummary` | `map_editor` ou `map_core` pur | V1 | Ne pas afficher un statut save/runtime. |
| Titre / sous-titre | Project name + libellé univers | `ProjectManifest.name`, description globale absente | Nouveau heading | `map_editor` | V0 | Sous-titre peut être générique si description absente. |
| KPI cards | Counts authoring fiables | Scenarios/dialogues/projection/validator partiels | Nouveau composant UI + read model | `map_editor` | V1 | Faux compteurs si pas de contrat. |
| Carte Histoire principale | Global story, synopsis, linked scenes, dialogues, issues | Global Story + Step/Cutscene/Dialogues partiels | Nouveau widget | `map_editor` | V1 | Synopsis/tags/status absents. |
| Chips chapitres | Chapters ordonnés + statut | `GlobalStoryStudioDocument.chapters` | Nouveau chip row | `map_editor` | V1 | Statuts éditoriaux absents. |
| Grille modules narratifs | Module summaries | Projection partielle | Nouveau widget | `map_editor` | V1 | Quêtes/Facts/World Rules pas tous first-class. |
| Activité récente | Authoring event log | Absente | Empty state ou exclusion V0 | `map_editor` | Plus tard | Ne pas inventer un historique. |
| Panneau droit Structure narrative | Résumé structure + counters + chapters | Projection + read model | Remplacer `NarrativeInspectorPanel` dans overview | `map_editor` | V1 | Panneau actuel trop technique. |
| Description | Synopsis univers / histoire | `ScenarioAsset.description` partiel, project description absente | Champ read-only V0 si disponible | `map_editor` | V1 | Ne pas hardcoder “Selbrume”. |
| Tags | Tags univers | Dialogues/maps ont tags ; univers global absent | Empty state V0 | `map_editor` | Plus tard | Tags projet à définir avant édition. |
| Liste chapitres | Chapters + editorial state | Chapters oui, état non | Nouveau list widget | `map_editor` | V1 | Statut à calculer/conventionner. |
| Statut éditorial | validé/à revoir/bloquant | Diagnostics disponibles partiellement | `EditorialStatusSummary` | `map_editor` ou `map_core` pur | V1 | Ne pas masquer diagnostics. |
| Footer | Projet, locale, version | Projet oui, locale/version app à clarifier | Réutiliser/adapt `StatusBar` ou footer dédié | `map_editor` | V0 | Pas de message save/runtime. |

## 6. Mapping UI → données métier

| UI cible | Donnée métier | Statut réel | Source proposée | Décision |
|---|---|---|---|---|
| Chapitres | Chapters authorés | Calculable après read model | `GlobalStoryStudioDocument.chapters` | Afficher en V1 avec source réelle. |
| Scènes | Scènes narratives | À définir | Peut-être steps, cutscene blocks ou local event flows | Ne pas afficher comme compteur réel avant contrat. |
| Cinématiques | Local event flows/cutscenes | Calculable après read model | `ScenarioAsset.scope == localEventFlow` + cutscene metadata | Afficher avec libellé clair. |
| Quêtes | Quêtes authorées | Modèle absent | Aucun modèle first-class | Empty state ou hors V0. |
| Dialogues | Dialogues et lignes | Calculable après read model | `ProjectManifest.dialogues` + fichiers Yarn | Afficher nombre de dialogues en V0, lignes en V1 après lecture disque. |
| Problèmes ouverts | Diagnostics | Calculable après read model | `ProjectValidator`, narrative diagnostics, beta validator selon contexte | Afficher seulement les diagnostics réellement lancés. |
| Conditions narratives | Predicates / activation / completion | Calculable après read model | `StepStudioActivationRule`, `StepStudioCompletionRule`, `MapEntityRuntimePredicate`, picker predicates | Afficher si sémantique documentée. |
| World Rules | Règles du monde authorées | Partiel | `worldChanges`, predicates, visibility rules | V1 comme résumé, pas registre final. |
| Facts | Lore/facts authorés | Modèle absent | Aucun registre fact identifié | Empty state V0. |
| Tags | Tags narratifs globaux | Partiel | `ProjectDialogueEntry.tags`, map/group tags ; pas univers global | Ne pas afficher un tag global fake. |
| Statuts éditoriaux | Draft/en cours/défini | Convention absente | Metadata future ou dérivation diagnostics | Empty state V0 ou “Non classé”. |
| Activité récente | Log authoring | Absent | Aucun journal persistant | Exclure V0 ou empty state. |
| Project Health | Santé projet | Calculable partiellement | Validators + issue severity | V1 après agrégateur. |
| Notifications | Notifications dashboard | Absentes | Aucun modèle editor persistant | Plus tard. |

Activité récente : elle ne peut pas être réelle aujourd'hui avec les éléments audités. Les `statusMessage` et `lastOpenedProjectManifestPath` ne constituent pas un historique d'authoring fiable. Recommandation : ne pas afficher d'items d'activité en V0 ; afficher un empty state “Aucune activité enregistrée pour l'instant” uniquement si le produit accepte un historique encore absent.

## 7. Données disponibles / manquantes / à éviter

| Donnée | Classification | Pourquoi | Risque si affichée trop tôt |
|---|---|---|---|
| Chapitres | Calculable après création d'un read model | `GlobalStoryChapter` existe dans metadata Global Story. | Statuts éditoriaux faux. |
| Scènes | Nécessite une convention | Le repo a steps/cutscenes/local flows, pas un modèle `Scene` stable. | Compteur ambigu. |
| Cinématiques | Calculable après read model | Cutscene Studio compile/stocke des flows sur `ScenarioAsset`. | Mélanger cutscene authoring et event flow runtime. |
| Quêtes | Nécessite un nouveau modèle ou convention | Pas de modèle Quest first-class ; seulement traces `questGated`/variables. | Faux sentiment de feature complète. |
| Dialogues | Calculable maintenant partiellement ; lignes après lecture disque | `ProjectDialogueEntry` existe ; ligne count demande Yarn parse. | `1 236 lignes` hardcodé serait trompeur. |
| Problèmes ouverts | Calculable après read model | Validators et adapters existent. | Badge “3” faux si validator non exécuté. |
| Conditions narratives | Calculable après read model | Conditions, predicates, activation/completion et visibility rules existent. | Confusion avec état sauvegardé joueur. |
| World Rules | Partiel / nécessite convention | `worldChanges` et predicates existent, pas registry complet. | Présenter comme système final. |
| Facts | À afficher en empty state V0 | Pas de fact/lore registry identifié. | Compteur `312` totalement faux. |
| Tags | Partiel / nouveau modèle pour tags globaux | Tags existent sur certains entries, pas univers narratif. | Tags Selbrume hardcodés. |
| Statuts éditoriaux | Nouveau modèle ou convention | Pas de champ draft/en cours/défini global. | Mauvaise priorisation du travail auteur. |
| Activité récente | Empty state ou exclusion V0 | Pas d'event log authoring. | Activité inventée. |
| Project Health | Calculable après read model | Diagnostics existent mais pas agrégat dashboard. | Confusion avec “sauvegardé/synchronisé”. |
| Notifications | Hors scope V0 | Pas de système de notifications dashboard. | Badge inventé. |

Compteurs à refuser explicitement en V0 s'ils ne sont pas calculés :

- `42 scènes`
- `24 quêtes`
- `1 236 lignes écrites`
- `312 facts`
- `12 problèmes ouverts`
- `3 notifications`
- toute progression ou pourcentage runtime.

## 8. Read models recommandés

Recommandation générale : commencer dans `map_editor`, sous une zone application/projection dédiée, parce que l'overview est une surface produit editor. Migrer vers `map_core` seulement si un read model devient réellement partagé et pur.

### `NarrativeOverviewReadModel`

- Package recommandé : `map_editor`
- Responsabilité : agrégation racine de la page Aperçu.
- Champs :
  - `projectName`
  - `subtitle`
  - `metrics`
  - `mainStory`
  - `modules`
  - `structure`
  - `projectHealth`
  - `recentActivity`
  - `emptyStateWarnings`
- Sources :
  - `ProjectManifest`
  - `NarrativeWorkspaceProjection`
  - validators/adapters existants
  - lecture optionnelle des fichiers dialogue pour les lignes en V1
- Tests futurs :
  - projet vide ;
  - projet avec Global Story + chapters ;
  - projet avec dialogues ;
  - absence de quests/facts/activity ;
  - aucun compteur hardcodé.
- Raison : l'UI doit consommer un seul objet stable.
- Limites V0 : pas d'activité récente réelle, pas de notifications.

### `NarrativeOverviewMetrics`

- Package recommandé : `map_editor`, pur Dart testable.
- Responsabilité : produire les KPI authoring.
- Champs :
  - `chapterCount`
  - `sceneCount`
  - `cutsceneCount`
  - `questCount`
  - `dialogueCount`
  - `dialogueLineCount`
  - `openIssueCount`
  - `conditionCount`
  - `worldRuleCount`
  - `factCount`
  - indicateurs `isReal` / `sourceStatus` par métrique.
- Sources :
  - chapters : Global Story metadata ;
  - cutscenes : local event flows/cutscene metadata ;
  - dialogues : manifest/dialogue files ;
  - issues : validators.
- Tests futurs :
  - chaque métrique absente doit produire un empty state, pas `0` trompeur si le modèle n'existe pas.
- Limites V0 :
  - `questCount`, `factCount`, `recentActivity` non réels.

### `MainStoryOverviewSummary`

- Package recommandé : `map_editor`.
- Responsabilité : carte “Histoire principale”.
- Champs :
  - `storyId`
  - `title`
  - `description`
  - `chapterSummaries`
  - `linkedSceneCount`
  - `linkedDialogueCount`
  - `openIssueCount`
  - `editorialStatus`
  - `hasRealSynopsis`
- Sources :
  - premier `ScenarioAsset.scope == globalStory` ;
  - `GlobalStoryStudioDocument` ;
  - `StepStudioDocument`.
- Tests futurs :
  - aucun global story ;
  - plusieurs global stories ;
  - fallback chapitre par défaut ;
  - description absente.
- Limites V0 :
  - pas de tags/story favorite tant que non modélisés.

### `NarrativeModuleSummary`

- Package recommandé : `map_editor`.
- Responsabilité : une carte de module narratif.
- Champs :
  - `moduleId`
  - `title`
  - `description`
  - `count`
  - `secondaryStats`
  - `sourceStatus`
  - `targetWorkspaceMode`
  - `emptyReason`
- Sources :
  - projection narrative ;
  - manifest dialogues/maps ;
  - future model quests/facts.
- Tests futurs :
  - module branchable ;
  - module empty state ;
  - module non disponible.
- Limites V0 :
  - modules Quêtes/Facts en empty/hors V0.

### `NarrativeStructureInspectorSummary`

- Package recommandé : `map_editor`.
- Responsabilité : panneau droit “Structure narrative”.
- Champs :
  - `universeTitle`
  - `description`
  - `tags`
  - `counterRows`
  - `chapters`
  - `editorialStatus`
  - `isPinned`
- Sources :
  - project name ;
  - Global Story metadata ;
  - metrics ;
  - future project narrative metadata.
- Tests futurs :
  - description absente ;
  - tags absents ;
  - chapters ordonnés.
- Limites V0 :
  - tags globaux et statut éditorial à empty state.

### `EditorialStatusSummary`

- Package recommandé : `map_editor`, puis `map_core` si la logique est pure et partagée.
- Responsabilité : traduire diagnostics et conventions editor en `À jour`, `À revoir`, `Bloquant`.
- Champs :
  - `validCount`
  - `reviewCount`
  - `blockingCount`
  - `hasErrors`
  - `hasWarnings`
  - `diagnosticSources`
- Sources :
  - `ProjectValidator`
  - `NarrativeValidatorAuthoringAdapter`
  - `BetaPlayabilityValidator` uniquement si le dashboard choisit un mode projet complet.
- Tests futurs :
  - error -> bloquant ;
  - warning -> à revoir ;
  - aucune diag -> à jour ;
  - validator non lancé -> statut inconnu, pas validé.
- Limites V0 :
  - ne pas afficher “Validé” si aucun validator n'a tourné.

### `RecentNarrativeActivitySummary`

- Package recommandé : ne pas implémenter en V0.
- Responsabilité future : résumer un vrai journal d'authoring.
- Champs futurs :
  - `activityId`
  - `kind`
  - `title`
  - `targetLabel`
  - `timestamp`
  - `actor`
- Sources :
  - aucune source fiable aujourd'hui.
- Tests futurs :
  - ordre temporel ;
  - activité par type ;
  - empty state.
- Décision : modèle à reporter tant qu'aucun event log n'existe.

### `NarrativeProjectHealthSummary`

- Package recommandé : `map_editor`.
- Responsabilité : Project Health authoring.
- Champs :
  - `status`
  - `openIssueCount`
  - `blockingIssueCount`
  - `lastValidationState`
  - `sourceStatus`
- Sources :
  - validators ;
  - dirty state seulement comme méta editor, pas comme santé narrative.
- Tests futurs :
  - diagnostic error ;
  - diagnostic warning ;
  - validator non disponible ;
  - dirty state n'écrase pas health.
- Limites V0 :
  - peut afficher “Non évalué” au lieu d'un point vert.

## 9. Roadmap proposée par phases et lots

### Phase 0 — Audit / décisions

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-00 — Narrative Studio Overview Roadmap Proposal | Produire cette roadmap d'implémentation. | `reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md` | Code/UI/read model. | Aucun test. | Roadmap trop large. | Rapport créé, sources auditées, prochain lot clair. | Image + repo. | audit/design/planning |
| NS-HOME-01 — Narrative Overview Data Contract / Metric Semantics V0 | Figer les définitions de chaque compteur et empty state. | Rapport + éventuellement spec sous `reports/narrativeStudio/ui/` | Widget, model production. | Aucun ou tests non requis. | Définir trop tôt un modèle lourd. | Chaque KPI a une source, une formule, un statut V0. | NS-HOME-00. | design/audit |

### Phase 1 — Read models / données

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-02 — NarrativeOverviewReadModel V0 | Créer la projection racine sans UI finale. | `packages/map_editor/lib/src/features/narrative/application/overview/*` | Flutter widget, design polish. | Unit tests Dart/Flutter package ciblés. | Coupler au runtime ou hardcoder Selbrume. | Projet vide + projet narratif donnent des summaries honnêtes. | NS-HOME-01. | code/tests |
| NS-HOME-03 — Narrative Metrics Computation V0 | Calculer chapitres, cutscenes, dialogues, issues disponibles. | Même zone overview + tests. | Quêtes/Facts réels si modèle absent. | Tests sur fixtures manifest. | Compteurs ambigus. | Les métriques non supportées sortent empty/unavailable. | NS-HOME-02. | code/tests |
| NS-HOME-04 — Narrative Health / Editorial Status Adapter V0 | Adapter diagnostics en statut éditorial. | Overview application + validator adapter. | UI validator complète. | Tests severity -> status. | Afficher “validé” sans validation. | `nonEvaluated`, `ok`, `review`, `blocking` distingués. | NS-HOME-02. | code/tests |

### Phase 2 — Shell UI

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-05 — Narrative Overview Workspace Route V0 | Ajouter une entrée `Aperçu` sans casser les sous-studios. | `editor_workspace_mode.dart`, `editor_canvas_host.dart`, nouveaux fichiers overview UI | Refactor global shell. | Widget/smoke ciblé. | Modifier trop largement la navigation. | `Aperçu` charge un écran overview vide/honnête. | NS-HOME-02. | code/UI/tests |
| NS-HOME-06 — Narrative Sidebar Alignment V0 | Aligner la sidebar Narrative Studio sur Aperçu/Storylines/Maps/etc. | `project_explorer_panel.dart` ou nouveau panel dédié | Supprimer anciens panels. | Widget test navigation. | Duplication de navigation. | Les sous-studios restent accessibles, Aperçu visible. | NS-HOME-05. | UI/tests |
| NS-HOME-07 — Narrative Top Bar Actions V0 | Ajouter actions visibles mais honnêtes. | Toolbar narrative locale ou shell header. | Notifications/search complètes. | Widget tests disabled/enabled states. | Boutons morts ou faux. | `Nouvelle storyline`, `Aperçu`, `Valider` ont état réel/désactivé clair. | NS-HOME-05. | UI/tests |

### Phase 3 — Contenu central

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-08 — Narrative KPI Cards V0 | Afficher KPI réels ou empty state. | Overview widgets + read model. | Compteurs hardcodés. | Widget tests par métrique. | Faux chiffres. | Chaque card indique source réelle ou indisponible. | NS-HOME-03. | UI/tests |
| NS-HOME-09 — Main Story Overview Card V0 | Afficher histoire principale, synopsis si réel, chapter chips. | Overview widgets. | Edition complète story. | Tests projet sans/avec Global Story. | Hardcoder Selbrume. | Fallbacks honnêtes, aucune progression joueur. | NS-HOME-03. | UI/tests |
| NS-HOME-10 — Narrative Module Grid V0 | Afficher modules branchés et modules reportés. | Overview widgets. | Implémenter Quests/Facts. | Tests modules available/unavailable. | Faire croire que tout existe. | Quêtes/Facts en empty state si modèle absent. | NS-HOME-03. | UI/tests |

### Phase 4 — Panneau droit

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-11 — Narrative Structure Inspector V0 | Remplacer l'inspecteur technique par une structure globale dans l'overview. | Overview right panel widget. | Remplacer tous les inspecteurs narrative. | Widget tests chapters/counters/tags absent. | Perdre l'inspecteur contextuel existant. | Panneau droit visible seulement dans overview ou mode adapté. | NS-HOME-09. | UI/tests |
| NS-HOME-12 — Editorial Status Panel V0 | Afficher statut éditorial réel. | Overview status widgets. | UI validator complète. | Tests diagnostics. | Simuler validation. | Statut inconnu si validator non lancé. | NS-HOME-04. | UI/tests |

### Phase 5 — Actions / navigation / validation

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-13 — Overview Navigation Wiring V0 | Brancher cards vers sous-studios existants. | Overview widgets + editor notifier. | Créer nouveaux sous-studios. | Widget tests tap -> workspace mode. | Navigation circulaire/confuse. | Cards ouvrent Global Story/Step/Cutscene/Dialogue existants. | NS-HOME-10. | UI/tests |
| NS-HOME-14 — Validation Action Wiring V0 | Bouton Valider vers diagnostics réels. | Overview actions + validator adapter. | Validation complète nouvelle. | Tests action/summary. | Diagnostics cachés. | Résultats affichés, pas de badge fake. | NS-HOME-04. | UI/tests |
| NS-HOME-15 — Honest Empty States V0 | Définir les empty states pour données absentes. | Overview empty widgets. | Faux placeholder décoratif. | Widget tests messages. | UX trop vide. | Chaque donnée absente est expliquée sobrement. | NS-HOME-08/10/11. | UI/tests |

### Phase 6 — Tests / polish / golden slice

| Lot | Objectif | Fichiers probables | Non-objectifs | Tests attendus | Risques | Critères d'acceptation | Dépendances | Type |
|---|---|---|---|---|---|---|---|---|
| NS-HOME-16 — Overview Golden Widget Tests V0 | Verrouiller rendu V0 sur projet fixture. | `packages/map_editor/test/...` | Pixel-perfect absolu. | Widget tests + overflow checks. | Tests fragiles. | Desktop width cible sans overflow, données réelles. | UI V0 complète. | tests |
| NS-HOME-17 — Responsive / Overflow Polish V0 | Polir densité et overflow. | Overview widgets/style. | Refonte visuelle globale. | Widget tests tailles. | One-off visuel. | Layout lisible à large/medium widths. | NS-HOME-16. | polish/tests |
| NS-HOME-18 — Narrative Overview Internal Demo Slice V0 | Démo interne avec projet réel, sans mock trompeur. | Test/fixture editor. | Contenu Selbrume final. | Smoke widget + read model. | Données démo confondues avec produit. | Demo documentée comme fixture. | NS-HOME-17. | tests/polish |

## 10. Premier lot recommandé

```text
NS-HOME-01 — Narrative Overview Data Contract / Metric Semantics V0
```

Objectif :

Définir précisément chaque donnée de l'image avant le moindre widget : formule, source, disponibilité V0, empty state, risque, dépendance.

Pourquoi c'est le bon prochain lot :

- l'image contient des compteurs séduisants mais non tous branchables aujourd'hui ;
- le repo a assez de logique pour calculer une partie des données, mais pas tout ;
- la priorité est d'éviter une belle UI débranchée ;
- ce lot prépare des tests simples pour les read models ;
- il évite de créer des champs `map_core` trop tôt.

Critères d'acceptation proposés :

- une table de sémantique pour chaque KPI ;
- aucune donnée Selbrume hardcodée ;
- décision explicite pour Quêtes, Facts, Tags, Activité récente, Notifications ;
- formule réelle pour chapters/cutscenes/dialogues/issues quand possible ;
- liste d'empty states V0 ;
- emplacement recommandé des futurs read models.

## 11. Risques et garde-fous

### Garde-fous contre le big bang UI

- Ajouter l'overview comme route/workspace limité, pas réécrire tout `EditorShellPage`.
- Réutiliser le shell existant tant que possible.
- Construire les widgets en petites sections : KPIs, main story card, module grid, right panel.
- Ajouter des tests à chaque section.

### Garde-fous contre les faux mocks

- Aucun compteur affiché sans `sourceStatus`.
- Les nombres de l'image ne doivent jamais entrer en code.
- Les modules non modélisés affichent un empty state ou sont masqués.
- Les fixtures de tests doivent être nommées comme fixtures, pas comme vérité Selbrume.

### Garde-fous contre les données Selbrume hardcodées

- `Selbrume Demo`, `La brume du phare`, `Port Selbrume`, tags et compteurs ne doivent venir que d'un projet chargé ou d'une fixture test.
- Le dashboard doit fonctionner sur un projet vide.
- Le dashboard doit fonctionner sur un projet non-Selbrume.

### Garde-fous contre le couplage runtime inutile

- `map_runtime` ne doit pas alimenter le dashboard.
- Les métriques authoring viennent du manifest, des metadata d'authoring et des validators.
- Les états de partie, sauvegardes, battle runtime et progression joueur restent hors scope.

### Garde-fous contre les modèles métier trop tôt

- D'abord read model editor.
- Ne créer un modèle `map_core` que si plusieurs surfaces doivent partager une convention.
- Ne pas inventer `Quest`, `Fact` ou `EditorialStatus` dans ce lot.

### Garde-fous contre la duplication

- L'overview résume et navigue.
- Storylines, Scènes, Cinématiques, Dialogues restent les lieux d'édition détaillée.
- La carte Histoire principale ne doit pas devenir un second Global Story Studio.
- Le panneau droit ne doit pas remplacer le validator détaillé.

### Ce qui reste explicitement hors scope de cette page

- runtime player ;
- save slots ;
- New Game ;
- battle runtime ;
- progression joueur ;
- map painting ;
- cinematic builder détaillé ;
- dialogue editor détaillé ;
- édition complète des storylines ;
- validation complète si elle n'est pas encore branchable ;
- activité récente tant qu'il n'existe pas de log réel ;
- notifications tant qu'il n'existe pas de source réelle.

## 12. Evidence Pack

### Image

Chemin vérifié :

```text
/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png
```

Sortie :

```text
image reference exists
```

### `git branch --show-current`

```text
main
```

### `git status --short --untracked-files=all` initial

Sortie : `<vide>`

### `git diff --stat` initial

Sortie : `<vide>`

### `git diff --name-only` initial

Sortie : `<vide>`

### `git log --oneline -n 10`

```text
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
```

### Commandes de recherche / inspection utilisées

```text
rg -n "Narrative|Studio|Phase|UI|UX|no-code|roadmap|P7|Selbrume|authoring|éditeur|creator|créateur" AGENTS.md agent_rules.md "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md"
find packages/map_editor/lib/src -type f | sort | rg "editor_shell|top_toolbar|editor_canvas_host|narrative_workspace|global_story|step_studio|cutscene_studio|dialogue_studio|narrative_inspector|narrative_library|entity_properties|project_explorer|pokemon_project_validator|project_scenario|project_dialogue|workspace_mode|workspace_providers|editor_workspace"
rg -n "EditorWorkspaceMode|NarrativeWorkspaceCanvas|GlobalStoryStudioWorkspace|StepStudioWorkspace|CutsceneStudioWorkspace|DialogueStudioWorkspace|NarrativeInspectorPanel|NarrativeLibraryPanel|ProjectExplorerPanel|Validator|ProjectHealth|Health|Recent|Activity|Storyline|Chapter|WorldRule|Fact|Outcome|ScenarioAsset" packages/map_editor packages/map_core packages/map_runtime --glob '!**/build/**' --glob '!**/.dart_tool/**'
rg -n "Quest|Quête|quête|quests|quest" packages/map_core/lib/src packages/map_editor/lib/src packages/map_runtime/lib/src --glob '!**/*.g.dart' --glob '!**/*.freezed.dart' --glob '!**/build/**' --glob '!**/.dart_tool/**'
rg -n "FactDescriptor|WorldRule|world rule|worldRule|worldChanges|Predicate|predicate|Fact|fact" packages/map_core/lib/src packages/map_editor/lib/src --glob '!**/*.g.dart' --glob '!**/*.freezed.dart' --glob '!**/build/**' --glob '!**/.dart_tool/**'
rg -n "ProjectHealth|Project Health|Notifications|notifications|recent activity|Activité récente|recent projects|lastOpened|statusMessage|isProjectDirty" packages/map_editor/lib/src packages/map_core/lib/src --glob '!**/*.g.dart' --glob '!**/*.freezed.dart' --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

### Chemins exacts Narrative Studio identifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart
```

### Changements préexistants

Au Gate 0 de cette exécution NS-HOME-00, le worktree était propre.

### Changements introduits par NS-HOME-00

```text
reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
```

### `git status --short --untracked-files=all` final

```text
?? reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
```

### `git diff --stat` final

Sortie : `<vide>`

### `git diff --name-only` final

Sortie : `<vide>`

### `git diff --check` final

Sortie : `<vide>`

### Tests / analyse

Commande non lancée : ce lot est audit-only/design-only/planning-only et ne modifie aucun code.

### Confirmations

- Aucun code de production n'a été modifié.
- Aucun fichier `packages/` n'a été modifié.
- Aucun fichier `map_core`, `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` n'a été modifié.
- Aucun widget Flutter n'a été créé.
- Aucun modèle/read model n'a été créé.
- Aucune donnée hardcodée n'a été introduite.

## 13. Auto-review critique

- Ai-je exécuté uniquement NS-HOME-00 ? Oui.
- Ai-je codé l'écran ? Non.
- Ai-je créé un widget Flutter ? Non.
- Ai-je créé un modèle/read model ? Non.
- Ai-je modifié `map_core` ? Non.
- Ai-je modifié `map_editor` hors rapport ? Non.
- Ai-je modifié `map_runtime`, `map_gameplay`, `map_battle` ? Non.
- Ai-je basé la proposition sur l'image et la description ? Oui.
- Ai-je audité l'état réel du repo ? Oui, via fichiers shell, Narrative Studio, modèles et validators.
- Ai-je identifié les vrais chemins existants ? Oui.
- Ai-je refusé les compteurs hardcodés ? Oui.
- Ai-je distingué authoring et runtime joueur ? Oui.
- Ai-je proposé une roadmap progressive ? Oui.
- Ai-je recommandé un premier lot exact ? Oui : `NS-HOME-01 — Narrative Overview Data Contract / Metric Semantics V0`.

## 14. Regard critique sur le prompt

Le prompt est très bon sur l'intention produit : il insiste correctement sur le dashboard auteur, les données réelles, les read models et les garde-fous anti-mock.

Le point à surveiller est que l'image contient des nombres et modules très séduisants (`42 scènes`, `24 quêtes`, `312 facts`, activité récente, badge notifications). Ces éléments sont utiles comme direction de design, mais dangereux comme spec d'implémentation directe. Le repo ne porte pas encore toutes ces données comme modèles métier fiables.

La bonne lecture du prompt est donc :

- oui à la direction visuelle et au modèle mental ;
- oui à une page `Aperçu` Narrative Studio ;
- non à un clone pixel-perfect immédiat ;
- non aux compteurs inventés ;
- oui à une roadmap qui commence par le contrat de données.
