# Narrative Studio Storylines Roadmap

## 1. Purpose

Cette roadmap est le fichier vivant de référence du chantier `Narrative Studio / Storylines V0`.

Elle sert à :

- remplacer progressivement l'ancien `Global Story Studio v1` ;
- préparer une UI proche des cibles `1 - global storyline.png` et `2 - chapitres.png` ;
- commencer par un read model / data contract avant toute refonte UI ;
- éviter les données fake ;
- imposer le design system PokeMap à chaque lot Storylines.

Chaque futur lot Storylines doit lire, respecter et mettre à jour ce fichier.

## 2. Canonical context

Contexte fermé :

```text
NS-HOME / Narrative Studio Aperçu V0 : fermé
```

Audit fondateur :

```text
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
```

Constats canoniques :

- l'écran actuel est encore l'ancien `GlobalStoryStudioWorkspace` ;
- il ne faut pas commencer par une refonte UI directe ;
- il faut d'abord définir un read model / data contract ;
- beaucoup de données visibles dans la cible seraient fake aujourd'hui ;
- la séparation `ProjectExplorerPanel` global / `NarrativeStudioSidebar` interne reste obligatoire ;
- le design system PokeMap est obligatoire.

Architecture canonique :

```text
ProjectExplorerPanel = sidebar globale PokeMap
NarrativeStudioSidebar = sidebar interne Narrative Studio
```

## 3. Non-negotiable guardrails

- Ne pas rouvrir ou repolir la page `Aperçu`.
- Ne pas transformer `ProjectExplorerPanel` en sidebar Storylines.
- Ne pas déplacer `NarrativeStudioSidebar` dans `ProjectExplorerPanel`.
- Ne pas modifier `map_runtime`, `map_gameplay`, `map_battle` pour Storylines V0.
- Ne pas utiliser `GameState` runtime comme source d'authoring.
- Ne pas activer `Nouvelle storyline` sans vrai modèle et flow.
- Ne pas activer `Valider` sans validation globale réelle.
- Ne pas créer de recherche, notification, badge, tags, facts, world rules ou activité récente fake.
- Ne pas copier les données de l'image cible dans le code produit.

Données explicitement interdites en hardcode feature :

```text
Histoire globale
La brume du phare
Le port
Les marais
Le phare
Les cristaux de sel
Le Goélise du port
La cabane du phare
Mystère
Exploration
Phare
Côtiers
5 chapitres
27 scènes
412 dialogues
18 facts
3 problèmes
activité récente
world rules affectées
```

Si une démo riche est nécessaire plus tard, elle doit être un lot dédié, une fixture explicite, isolée, testée et non mélangée au code produit.

## 4. Design System Guardrails

Règle d'or :

```text
Toute UI Storylines doit utiliser le design system PokeMap.
```

Interdit :

- widget générique ad hoc dans Storylines ;
- mini design system caché dans la feature ;
- duplication locale de cards, pills, tabs, panels, icon tiles, inspector sections ou KPI cards ;
- `Color(0x...)` ajouté dans une feature ;
- `Colors.*` ajouté dans une feature ;
- couleur locale hardcodée.

Autorisé :

- primitives PokeMap existantes ;
- primitives editor partagées existantes ;
- nouvelle primitive uniquement si créée/étendue dans le design system avant usage feature.

Primitives stables observées :

- `PokeMapColorTokens`
- `PokeMapTheme`
- `EditorChrome`
- `EditorPaneSurface`
- `EditorSidebarSectionTitle`
- `EditorSidebarListRow`
- `EditorHorizontalDivider`
- `EditorVerticalDivider`
- `EditorToolbarIconButton`
- `EditorVisualTokens`

Primitives design-system observées dans le worktree local au bootstrap, à revérifier au début de chaque lot car elles sont préexistantes/non trackées ou en cours :

- `PokeMapTone`
- `PokeMapToneColors`
- `PokeMapPageSurface`
- `PokeMapIconTile`
- `PokeMapMetricCard`
- `PokeMapModuleCard`
- `PokeMapStatusTile`
- `PokeMapInspectorPanel`
- `PokeMapSegmentedTab`
- `PokeMapSegmentedTabs`

Chemins demandés mais absents exactement :

```text
packages/map_editor/lib/src/ui/shared/pokemap_tone.dart
packages/map_editor/lib/src/ui/shared/pokemap_dashboard_primitives.dart
```

Équivalents observés :

```text
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
```

### Design System Gate

Chaque lot UI Storylines doit confirmer :

```text
- [ ] Aucun Color(0x...) ajouté dans une feature.
- [ ] Aucun Colors.* ajouté dans une feature.
- [ ] Aucun composant générique local ajouté dans Storylines.
- [ ] Primitives PokeMap existantes utilisées quand disponibles.
- [ ] Nouvelle primitive éventuelle créée dans le design system, pas dans la feature.
- [ ] Tons via PokeMapTone / tokens / context.pokeMapColors.
- [ ] Surfaces via EditorChrome / PokeMap tokens / composants partagés.
- [ ] Tests design-system pertinents lancés ou skip justifié.
- [ ] Rapport inclut un mini audit design system.
```

Si ce gate ne peut pas être respecté, le lot doit s'arrêter et recommander un lot design-system préalable.

## 5. Current state summary

État réel actuel :

```text
EditorWorkspaceMode.globalStory
→ NarrativeWorkspaceCanvas
→ NarrativeStudioShell
→ GlobalStoryStudioWorkspace
→ GlobalStoryStudioShell
```

UI actuelle :

- `Global Story Workspace` ;
- panel `STRUCTURE / Votre récit` ;
- canvas `FIL NARRATIF / Progression globale` ;
- inspecteur `DÉTAIL DE L'ÉTAPE` ;
- un seul global story ;
- logique chapters + steps ;
- beaucoup de vide ;
- inspecteur centré sur la step, pas sur la storyline.

Données réellement disponibles ou partielles :

- `ProjectManifest.scenarios`
- `ScenarioAsset(scope == globalStory)`
- `ScenarioAsset(scope == localEventFlow)`
- `ScenarioAsset.name`
- `ScenarioAsset.description`
- `ScenarioAsset.nodes`
- `ScenarioAsset.edges`
- `ScenarioAsset.metadata`
- `GlobalStoryStudioDocument`
- `GlobalStoryChapter`
- `GlobalStoryStepNode`
- `GlobalStoryStepLink`
- `StepStudioDocument`
- `StepStudioStep`
- `StepStudioCutsceneLink`
- `StepStudioOutcomeDefinition`
- `StepStudioWorldChange`
- `ProjectManifest.dialogues`
- `ProjectManifest.scripts`
- `NarrativeWorkspaceProjection`

Données absentes ou trop risquées :

- liste de storylines multiples ;
- type de storyline ;
- priorité ;
- statut storyline fiable ;
- quêtes annexes ;
- tags ;
- facts modifiés ;
- world rules affectées ;
- activité récente ;
- validation globale Storylines ;
- statistiques Storylines ;
- tests Storylines ;
- graph riche avec mini-map et zoom.

## 6. Target state summary

Cible Graph :

- panneau secondaire Storylines ;
- breadcrumb `Narrative Studio > Storylines > Histoire globale` ;
- header storyline ;
- tabs `Graph`, `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` ;
- KPI ;
- graph macro ;
- quêtes annexes liées ;
- mini-map ;
- légende ;
- zoom controls ;
- inspecteur de storyline ;
- tags ;
- world rules affectées ;
- dernière activité.

Cible Chapitres :

- liste de chapitres ;
- chapitre sélectionné ;
- scènes du chapitre ;
- recherche / filtre / tri ;
- bouton `Nouveau chapitre` ;
- inspecteur de chapitre ;
- ordre des scènes ;
- contenu lié ;
- statut éditorial.

Interprétation V0 :

- afficher seulement ce qui est disponible ou dérivable ;
- rendre le reste absent, disabled ou explicitement à venir ;
- ne pas simuler une densité projet avec des données hardcodées ;
- préparer les futurs flows sans les activer.

## 7. Data readiness summary

| Data target | Current readiness | Decision |
|---|---|---|
| Storyline title | Available via `ScenarioAsset.name` | Safe read-only. |
| Storyline description | Available via `ScenarioAsset.description` | Safe read-only. |
| Single global story | Available via `ScenarioScope.globalStory` | Safe read-only. |
| Chapters | Available via `GlobalStoryStudioDocument.chapters` | Safe read-only. |
| Steps | Available via `StepStudioDocument.steps` | Safe read-only, wording prudent. |
| Step links | Partial via `GlobalStoryStepLink` | Safe for limited graph. |
| Cutscenes linked to steps | Available via `StepStudioCutsceneLink` | Safe read-only. |
| Dialogues linked | Partial | Needs read model. |
| Multiple storylines | Missing | Do not fake. |
| Side quests | Missing | Do not fake. |
| Tags | Missing | Do not fake. |
| Priority | Missing | Do not fake. |
| Facts modified | Partial / fake risk | Keep disabled. |
| World rules affected | Partial / fake risk | Keep disabled. |
| Recent activity | Missing | Do not fake. |
| Validation issues | Partial | Use only existing diagnostics. |
| Graph minimap / zoom | Missing UI contract | Later after graph model. |

## 8. Roadmap overview

| Lot | Title | Type | Status | Next |
|---|---|---|---|---|
| NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
| NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | DONE | NS-STORYLINES-03 |
| NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | DONE | NS-STORYLINES-04 |
| NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | DONE | NS-STORYLINES-05 |
| NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | DONE | NS-STORYLINES-06 |
| NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | TODO | NS-STORYLINES-07 |
| NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | TODO | NS-STORYLINES-08 |
| NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | TODO | NS-STORYLINES-09 |
| NS-STORYLINES-09 | Chapters Inspector / Scene Ordering Read-only V0 | editor UI | TODO | NS-STORYLINES-10 |
| NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | TODO | NS-STORYLINES-11 |
| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | TODO | NS-STORYLINES-CHECKPOINT |
| NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | TODO | TBD |

## 9. Detailed lots

### NS-STORYLINES-01 — Storylines Read Model / Data Contract V0

- Type : core/design.
- Objectif : définir le read model Storylines V0 ; mapper chaque donnée cible ; décider le vocabulaire `Storyline`, `Chapter`, `Step`, `Scene`, `Quest`, `Map`.
- Fichiers probables : rapport data contract ; éventuellement tests de contrat si prompt autorise du code.
- Non-objectifs : pas d'UI, pas de widget, pas de graph, pas de création storyline.
- Dépendances : NS-STORYLINES-00, cette roadmap.
- Critères d'acceptation : matrice complète, fake risks explicites, décision Maps documentée.
- Tests attendus : aucun si rapport-only ; tests unitaires si read model codé dans un prompt futur.
- Analyse attendue : `git diff --check`; analyze seulement si code.
- Visual Gate : non.
- Risques : inférer trop de données depuis des noms ; confondre `ScenarioAsset` et `Storyline`.
- Design system impact : rappel du gate, pas de code UI.
- Statut : DONE.
- Résultat NS-STORYLINES-01 : contrat de données Storylines V0 documenté dans `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Code : aucun fichier Dart modifié.
- Tests/analyze : non lancés, car lot documentation-only / no-code / no-test-change.
- Design System Gate : confirmé pour les futurs lots UI ; aucune couleur hardcodée ajoutée.
- Fake data : aucune donnée cible ou fixture Selbrume ajoutée ; les champs `Missing` / `Fake risk` restent disabled, cachés ou reportés.
- Prochain lot attendu : NS-STORYLINES-02.

### NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0

- Type : test/audit.
- Objectif : verrouiller l'ancien écran et prouver que les données viennent du manifest / metadata.
- Fichiers probables : tests `global_story_studio_*`, rapport de caractérisation.
- Non-objectifs : pas de refonte UI, pas de nouveau modèle, pas de fixtures cible.
- Dépendances : NS-STORYLINES-01.
- Critères d'acceptation : comportements actuels caractérisés, anti-fake explicite.
- Tests attendus : tests Global Story existants + navigation/shell pertinents.
- Analyse attendue : `flutter analyze` ciblé si code/tests touchés ; `git diff --check`.
- Visual Gate : optionnel.
- Risques : figer une UI destinée à être remplacée.
- Design system impact : aucun nouveau composant local.
- Statut : DONE.
- Résultat NS-STORYLINES-02 : ajout d'un test de caractérisation anti-fake qui verrouille l'ancien Global Story Studio sans toucher au code production.
- Fichiers créés : `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md`.
- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Code production : aucun fichier `packages/map_editor/lib`, `map_core`, `map_runtime`, `map_gameplay` ou `map_battle` modifié.
- Tests exécutés : `flutter test test/storylines_current_global_story_characterization_test.dart`, régression groupée Global Story / Projection.
- Analyse exécutée : `flutter analyze test/storylines_current_global_story_characterization_test.dart`.
- Design System Gate : confirmé ; aucun widget production, aucune couleur, aucune primitive design system modifiée.
- Fake data : aucune donnée cible ajoutée ; les chaînes cible sont assertées absentes quand la fixture neutre ne les contient pas.
- Prochain lot attendu : NS-STORYLINES-03.

### NS-STORYLINES-03 — Storylines Workspace Shell Layout V0

- Type : editor UI.
- Objectif : poser le layout Storylines V0 : secondary list panel, main area, inspector.
- Fichiers probables : `narrative_workspace_canvas.dart`, widgets Storylines, tests UI, rapport.
- Non-objectifs : pas de graph riche, pas de création storyline, pas de validation globale.
- Dépendances : NS-STORYLINES-01, NS-STORYLINES-02.
- Critères d'acceptation : layout visible, `ProjectExplorerPanel` global, `NarrativeStudioSidebar` interne, Design System Gate respecté.
- Tests attendus : widget tests shell, navigation, disabled states, absence de fake.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + focus.
- Risques : créer un shell visuel sans source de données.
- Design system impact : fort ; bloquer si primitive manquante.
- Statut : DONE.
- Résultat NS-STORYLINES-03 : premier shell Storylines V0 livré et branché sur `EditorWorkspaceMode.globalStory`, avec panneau secondaire, zone centrale et inspecteur placeholder.
- Fichiers créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures Visual Gate sous `reports/narrativeStudio/storylines/screenshots/`.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Données : `ScenarioAsset.name`, `ScenarioAsset.description`, nombre réel de global stories et nombre dérivé de steps affichés ; aucune donnée cible hardcodée.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/global_story_studio_workspace_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze` global lancé et échoué sur dette préexistante ; analyse ciblée des fichiers touchés propre.
- Visual Gate : `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
- Design System Gate : confirmé ; primitives `PokeMapPageSurface`, `PokeMapInspectorPanel`, `PokeMapStatusTile`, `PokeMapIconTile`, `PokeMapTone` utilisées ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
- Fake data : aucune donnée Selbrume/cible ajoutée ; actions futures affichées disabled/read-only.
- Bis NS-STORYLINES-03-bis : test des actions futures durci avec présence obligatoire, `PokeMapButton.onPressed == null`, non-mutation du projet/workspace/sélection ; harness Visual Gate passé sur `PokeMapTheme.dark()`.
- Prochain lot attendu : NS-STORYLINES-04.

### NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0

- Type : editor UI.
- Objectif : afficher un panneau secondaire Storylines read-only basé sur le read model.
- Fichiers probables : widgets Storylines, read model, tests de rendu.
- Non-objectifs : pas de quête annexe fake, pas de recherche active.
- Dépendances : NS-STORYLINES-03.
- Critères d'acceptation : liste réelle ou empty state honnête, aucun item cible fake.
- Tests attendus : rendu liste, disabled interactions, absence de données cible.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + focus.
- Risques : faire croire à des storylines multiples.
- Design system impact : utiliser `PokeMapPanel`, `PokeMapSidebarItem`, `EditorSidebarListRow` ou équivalent.
- Statut : DONE.
- Résultat NS-STORYLINES-04 : panneau secondaire Storylines structuré en read-only avec header, action `+` disabled, recherche à venir, section `Histoire principale`, liste des `ScenarioAsset globalStory` réels, nombre d'étapes dérivé et section `Quêtes annexes` explicitement non branchée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md`, captures Visual Gate `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif via harness NS-STORYLINES-03-bis ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapButton`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible ajoutée ; `localEventFlow` reste absent de la liste et les quêtes annexes restent à venir.
- Prochain lot attendu : NS-STORYLINES-05.

### NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0

- Type : editor UI.
- Objectif : créer header Storyline V0, tabs read-only/disabled, KPI honnêtes.
- Fichiers probables : widgets header/tabs/KPI, `PokeMapSegmentedTabs`, read model, tests.
- Non-objectifs : pas de statistiques fake, pas d'onglet Tests actif, pas de bouton Nouvelle storyline actif.
- Dépendances : NS-STORYLINES-04.
- Critères d'acceptation : header lisible, tabs cohérents, KPI sourcés.
- Tests attendus : active tab, disabled tabs, KPI no fake, actions disabled.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : focus header.
- Risques : copier les chiffres cible.
- Design system impact : utiliser `PokeMapMetricCard`, `PokeMapSegmentedTabs` si disponibles.
- Statut : DONE.
- Résultat NS-STORYLINES-05 : header central Storyline V0, tabs Storyline read-only et KPI honnêtes livrés dans la zone centrale haute.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`, captures Visual Gate `ns_storylines_05_header_tabs_kpi_desktop.png`, `ns_storylines_05_header_tabs_kpi_focus.png`, `ns_storylines_05_header_tabs_kpi_center.png`.
- Données : `ScenarioAsset.name`, `ScenarioAsset.description`, `projection.globalStories.length`, steps filtrées par `globalScenarioId` et cutscenes liées dérivées des steps ; chapitres et diagnostics restent `À venir` faute de source branchée dans le widget.
- Tabs : `Graph` visible comme tab principal ; `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` visibles mais non mutantes / non branchées.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif via harness NS-STORYLINES-03-bis ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPanel`, `PokeMapPageSurface`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible hardcodée ; aucun `localEventFlow` affiché comme quête / storyline / KPI ; actions futures restent disabled ou non mutantes.
- Prochain lot attendu : NS-STORYLINES-06.

### NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0

- Type : editor UI / visual gate.
- Objectif : remplacer le vide central par un graph ou placeholder read-only honnête.
- Fichiers probables : graph Storylines read-only, layout helpers, tests.
- Non-objectifs : pas de drag/drop, pas d'édition liens, pas de quêtes annexes fake.
- Dépendances : NS-STORYLINES-05.
- Critères d'acceptation : graph limité ou empty state honnête, Visual Gate produit.
- Tests attendus : rendu minimal, empty state, absence de side quests fake.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + graph focus.
- Risques : dessiner un faux graph premium.
- Design system impact : graph générique dans design system ou composant spécifique non réutilisable.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-07.

### NS-STORYLINES-07 — Storyline Inspector Read-only V0

- Type : editor UI.
- Objectif : créer l'inspecteur `Détails de la storyline` read-only.
- Fichiers probables : inspector Storylines, read model, tests inspector.
- Non-objectifs : pas de tags fake, pas de world rules fake, pas d'activité récente fake.
- Dépendances : NS-STORYLINES-06.
- Critères d'acceptation : inspecteur storyline, sections absentes/disabled honnêtes.
- Tests attendus : description présente/absente, disabled missing data.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : inspector focus.
- Risques : afficher priorité/statut sans source.
- Design system impact : utiliser `PokeMapInspectorPanel` ou primitive partagée.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-08.

### NS-STORYLINES-08 — Chapters Tab Read-only V0

- Type : editor UI.
- Objectif : créer l'onglet `Chapitres` read-only avec chapters et steps réels.
- Fichiers probables : tab chapters, tests chapters, rapport.
- Non-objectifs : pas de création chapitre, pas de drag/drop, pas de scènes fake.
- Dépendances : NS-STORYLINES-07.
- Critères d'acceptation : liste chapitres visible, sélection read-only, wording `Scènes` prudent.
- Tests attendus : rendu chapters, empty state, sélection read-only.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : chapters desktop/focus.
- Risques : confondre steps et scènes finales.
- Design system impact : cards/list rows partagés.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-09.

### NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0

- Type : editor UI.
- Objectif : créer inspecteur chapitre et ordre steps/scènes read-only.
- Fichiers probables : inspector chapitre, read model chapters, tests.
- Non-objectifs : pas de réordonnancement, pas d'ajout scène, pas de statut éditorial fake.
- Dépendances : NS-STORYLINES-08.
- Critères d'acceptation : détails chapitre lisibles, données absentes marquées à venir.
- Tests attendus : selected chapter, no selection, disabled controls.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : chapters inspector focus.
- Risques : vendre un ordre de scènes si seules des steps existent.
- Design system impact : inspector design-system obligatoire.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-10.

### NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0

- Type : visual gate.
- Objectif : harmoniser contre les deux cibles sans ajouter de feature.
- Fichiers probables : widgets Storylines existants, rapport, screenshots.
- Non-objectifs : pas de donnée fake, pas de pixel-perfect.
- Dépendances : NS-STORYLINES-09.
- Critères d'acceptation : Visual Gate complet, comparaison honnête, disabled states lisibles.
- Tests attendus : régression UI/storylines, tests design-system si tokens/surfaces touchés.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : Graph desktop, Graph focus, Chapters desktop, medium.
- Risques : polir au lieu de corriger une source manquante.
- Design system impact : très fort ; mini audit obligatoire.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-11.

### NS-STORYLINES-11 — Storylines Interaction Wiring V0

- Type : editor UI / test.
- Objectif : brancher uniquement les interactions honnêtes.
- Fichiers probables : widgets Storylines, `NarrativeWorkspaceCanvas`, tests interaction.
- Non-objectifs : pas de création Storyline, pas de validation globale, pas de graph editing.
- Dépendances : NS-STORYLINES-10.
- Critères d'acceptation : interactions réelles fonctionnent, futures disabled, aucune mutation non prévue.
- Tests attendus : tabs, list selection, inspector, disabled actions.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : interaction focus.
- Risques : activer trop tôt Nouvelle storyline, Valider, search ou graph.
- Design system impact : préserver composants existants.
- Statut : TODO.
- Prochain lot attendu : NS-STORYLINES-CHECKPOINT.

### NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint

- Type : checkpoint.
- Objectif : décider si Storylines V0 est acceptable et documenter les limites V1.
- Fichiers probables : rapport checkpoint.
- Non-objectifs : pas de code, pas de tests modifiés, pas de polish.
- Dépendances : NS-STORYLINES-11.
- Critères d'acceptation : verdict clair, checklist V0, limites V1, recommandation de suite.
- Tests attendus : aucun si audit-only.
- Analyse attendue : commandes Git read-only, `git diff --check`.
- Visual Gate : inspecter screenshots finaux existants.
- Risques : transformer le checkpoint en nouveau chantier.
- Design system impact : confirmer respect du gate.
- Statut : TODO.
- Prochain lot attendu : TBD.

## 10. Update protocol for every future lot

Chaque futur lot Storylines doit :

1. lire `road_map_storylines.md` avant toute modification ;
2. lire le rapport du lot précédent ;
3. respecter le lot courant exact ;
4. ne pas démarrer le lot suivant ;
5. mettre à jour `road_map_storylines.md` à la fin ;
6. marquer le lot courant avec son statut réel ;
7. ajouter un court résumé du résultat ;
8. lister les fichiers modifiés / créés ;
9. lister les tests et analyze exécutés ;
10. lister les limites et dettes ;
11. confirmer le prochain lot recommandé ;
12. confirmer le respect des règles design system ;
13. confirmer l'absence de couleurs hardcodées ;
14. confirmer l'absence de données fake ;
15. confirmer que les actions futures restent disabled si non supportées.

Bloc standard futur :

```text
Avant modification :
- lire reports/narrativeStudio/storylines/road_map_storylines.md ;
- lire le rapport du lot précédent ;
- capturer git status initial ;
- confirmer les changements préexistants.

Après modification :
- mettre à jour road_map_storylines.md ;
- marquer le lot courant TODO / IN PROGRESS / DONE / BLOCKED / SKIPPED ;
- ajouter résumé, fichiers, tests, analyze, limites ;
- confirmer Design System Gate ;
- confirmer absence de fake data ;
- confirmer prochain lot ;
- capturer git status final, diff stat, diff name-only, diff check.
```

## 11. Definition of Done

Un lot Storylines V0 est `DONE` seulement si :

- son objectif exact est atteint ;
- aucun non-objectif n'a été implémenté ;
- les fichiers modifiés sont dans le périmètre autorisé ;
- les tests attendus passent ou les skips sont justifiés ;
- `flutter analyze` ou analyse ciblée est propre si code touché ;
- `git diff --check` est propre ;
- aucun fake data n'est ajouté ;
- aucune action future n'est activée sans source réelle ;
- Design System Gate est respecté ;
- rapport de lot complet ;
- roadmap mise à jour.

Un lot doit rester `BLOCKED` si :

- une décision produit manque ;
- une primitive design system manque et ne peut pas être créée dans le lot ;
- une source de données manque et l'UI serait fake ;
- un changement hors périmètre serait nécessaire.

## 12. Open decisions

### Maps dans la sidebar Narrative Studio

État :

- NS-HOME a retiré `Maps` de la sidebar interne ;
- les nouvelles cibles montrent `Maps` ;
- l'architecture canonique sépare Project Explorer global et sidebar interne.

Décision actuelle :

- ne pas réintroduire `Maps` dans la sidebar interne sans décision explicite.

Option recommandée :

- traiter les cartes liées comme `Lieux liés` ou `Cartes liées` dans l'inspecteur Storyline / Chapter ;
- garder `Maps` global dans `ProjectExplorerPanel` ou dans le workspace Maps existant ;
- ne pas casser la séparation des deux sidebars.

### Storyline comme modèle core

Question :

- faut-il un `StorylineAsset` ou un read model editor suffit-il pour V0 ?

Décision temporaire :

- commencer par read model / data contract ;
- ne pas modifier `map_core` sans preuve.

### Scènes vs Steps

Question :

- la cible `Scènes` représente-t-elle des steps narratives, des cutscenes, ou un futur concept ?

Décision temporaire :

- utiliser un wording prudent jusqu'à clarification.

### Quêtes annexes

Question :

- side quests sont-elles des storylines secondaires, des chapters, des scenarios, ou un futur modèle ?

Décision temporaire :

- ne pas les afficher comme données réelles tant que le modèle manque.

## 13. Current status

```text
Roadmap status: ACTIVE
Current lot: NS-STORYLINES-05
Current lot status: DONE
Next recommended lot: NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0
```

| Lot | Status | Last update | Notes |
|---|---|---|---|
| NS-STORYLINES-00 | DONE | 2026-05-27 | Audit actuel/cible produit. |
| NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
| NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
| NS-STORYLINES-02 | DONE | 2026-05-27 | Tests de caractérisation anti-fake ajoutés ; ancien Global Story Studio verrouillé sans code production. |
| NS-STORYLINES-03 | DONE | 2026-05-28 | Shell Storylines V0 read-only livré avec layout 3 zones, anti-fake, captures Visual Gate et tests ciblés. |
| NS-STORYLINES-04 | DONE | 2026-05-28 | Panneau secondaire read-only structuré sur les globalStory réelles ; recherche / création / quêtes annexes disabled. |
| NS-STORYLINES-05 | DONE | 2026-05-28 | Header/tabs/KPI read-only livrés avec KPI sourcés ou disabled. |
| NS-STORYLINES-06 | TODO | 2026-05-27 | Graph read-only placeholder. |
| NS-STORYLINES-07 | TODO | 2026-05-27 | Inspector storyline. |
| NS-STORYLINES-08 | TODO | 2026-05-27 | Chapters tab. |
| NS-STORYLINES-09 | TODO | 2026-05-27 | Chapters inspector/order. |
| NS-STORYLINES-10 | TODO | 2026-05-27 | Visual harmonization. |
| NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
| NS-STORYLINES-CHECKPOINT | TODO | 2026-05-27 | Acceptance checkpoint. |

## 14. Changelog

### 2026-05-28 — NS-STORYLINES-05

- Ajout du header central Storyline V0 avec titre réel, description réelle, type prudent `Storyline principale`, état `Lecture seule`, source réelle et mode `Storylines V0`.
- Ajout de tabs Storyline visibles via `PokeMapSegmentedTabs` : `Graph` principal, `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` non branchés / non mutants.
- Ajout de KPI read-only avec `PokeMapMetricCard` : `Storylines globales`, `Étapes narratives`, `Cutscenes liées` sourcés ; `Chapitres` et `Avertissements structurels` restent `À venir`.
- Conservation du panneau secondaire NS-STORYLINES-04 et du layout trois zones ; aucun graph riche, inspector final ou onglet Chapitres actif n'a été ajouté.
- Adaptation des tests Storylines et caractérisation ; vérification de la non-mutation des tabs futures et de l'absence de données cible fake.
- Production des captures Visual Gate dark `ns_storylines_05_header_tabs_kpi_desktop.png`, `ns_storylines_05_header_tabs_kpi_focus.png`, `ns_storylines_05_header_tabs_kpi_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucun `localEventFlow` promu en quête/storyline/KPI, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0`.

### 2026-05-28 — NS-STORYLINES-04

- Transformation du panneau secondaire placeholder en liste Storylines read-only structurée.
- Affichage des `ScenarioAsset globalStory` réels avec nom, description, type prudent `Storyline principale`, nombre d'étapes dérivé, et mention `Read-only / Source réelle`.
- Ajout d'une action `+` visible mais disabled/non mutante et d'une recherche `Recherche à venir`.
- Ajout d'une section `Quêtes annexes` explicitement à venir ; aucun `localEventFlow` n'est présenté comme quête annexe.
- Rendu du panneau secondaire scrollable via `PokeMapPanel(expandChild: true)` pour éviter l'overflow medium.
- Adaptation des tests Storylines et caractérisation NS-STORYLINES-02 ; les données réelles peuvent désormais apparaître à la fois dans le panneau secondaire et la zone centrale.
- Production des captures Visual Gate dark `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0`.

### 2026-05-28 — NS-STORYLINES-03

- Création de `StorylinesWorkspace`, premier shell Storylines V0 read-only.
- Branchement de `EditorWorkspaceMode.globalStory` vers le shell Storylines V0 dans `NarrativeWorkspaceCanvas`.
- Conservation des anciens fichiers Global Story Studio sans suppression.
- Adaptation du test de caractérisation NS-STORYLINES-02 pour préserver les garanties anti-fake sur le nouveau shell.
- Ajout de `storylines_workspace_shell_test.dart` couvrant le shell, les données réelles, les actions disabled, l'absence de Maps et le gate anti-couleurs.
- Production des captures Visual Gate desktop, focus et medium/panels.
- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
- Tests ciblés Storylines / Global Story / Projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

### 2026-05-28 — NS-STORYLINES-03-bis

- Durcissement du test `keeps future header actions disabled and non-mutating`.
- Vérification explicite que `Nouvelle storyline` et `Valider` existent, que leurs `PokeMapButton.onPressed` sont `null`, et qu'un tap ne modifie ni workspace, ni projet, ni scénario sélectionné.
- Suppression du tap silencieux `warnIfMissed: false` dans le test.
- Application de `PokeMapTheme.light()`, `PokeMapTheme.dark()` et `ThemeMode.dark` dans le harness Visual Gate.
- Régénération des trois screenshots `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
- Aucun code production, aucune UI, aucun modèle et aucune primitive design system modifiés.
- Prochain lot recommandé inchangé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

### 2026-05-27 — NS-STORYLINES-02

- Ajout du test `storylines_current_global_story_characterization_test.dart`.
- Vérification que `EditorWorkspaceMode.globalStory` rend encore `NarrativeWorkspaceCanvas > NarrativeStudioShell > GlobalStoryStudioWorkspace`.
- Vérification que les données visibles viennent du `ScenarioAsset globalStory` et des metadata `GlobalStoryStudioDocument` / `StepStudioDocument`.
- Vérification anti-fake : données cible Storylines (`La brume du phare`, quêtes annexes cible, tags cible, `412`, `18`, etc.) absentes avec une fixture neutre.
- Vérification que `localEventFlow` n'est pas affiché comme quête annexe Storylines.
- Vérification que `Maps` reste absent de la sidebar interne Narrative Studio.
- Régressions Global Story / Projection passées et analyse ciblée clean.
- Aucun code production, modèle, widget ou design system modifié.
- Prochain lot recommandé : `NS-STORYLINES-03 — Storylines Workspace Shell Layout V0`.

### 2026-05-27 — NS-STORYLINES-01

- Création du contrat de données Storylines V0.
- Clarification du mapping `Storyline = ScenarioAsset globalStory` en V0.
- Clarification `Chapter = GlobalStoryChapter`.
- Clarification `Step = Étape narrative` et prudence sur le terme `Scène`.
- Documentation des KPI affichables, disabled ou fake risk.
- Documentation du graph V0 read-only et de l'inspecteur V0.
- Confirmation que `Maps` reste absent de la sidebar interne en V0.
- Aucun code, test, modèle, widget ou provider modifié.
- Prochain lot recommandé : `NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0`.

### 2026-05-27 — NS-STORYLINES-ROADMAP-00

- Création de la roadmap Storylines.
- Ajout des garde-fous design system.
- Ajout du Design System Gate obligatoire.
- Ajout des lots Storylines V0 de `NS-STORYLINES-01` à `NS-STORYLINES-CHECKPOINT`.
- Ajout du protocole de mise à jour obligatoire pour les futurs lots.
- Documentation de la tension `Maps` / sidebar.
- Prochain lot recommandé : `NS-STORYLINES-01 — Storylines Read Model / Data Contract V0`.
