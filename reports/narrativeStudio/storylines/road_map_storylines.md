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
| NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | DONE | NS-STORYLINES-07 |
| NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | DONE | NS-STORYLINES-08 |
| NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | DONE | NS-STORYLINES-09 |
| NS-STORYLINES-09 | Chapters Inspector / Step Ordering Read-only V0 | editor UI | DONE | NS-STORYLINES-10 |
| NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | DONE | NS-STORYLINES-11 |
| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
| NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | DONE | NS-STORYLINES-V1-00 |
| NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
| NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
| NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
| NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
| NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
| NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | DONE | NS-STORYLINES-V1-06 |
| NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | DONE | NS-STORYLINES-V1-07 |
| NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-07-bis |
| NS-STORYLINES-V1-07-bis | Storylines Workspace Cleanup / Dead Legacy Removal | editor UI cleanup | DONE | NS-STORYLINES-V1-08 |
| NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | DONE | NS-STORYLINES-V1-09 |
| NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-10 |
| NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | DONE | NS-STORYLINES-V1-11 |
| NS-STORYLINES-V1-11 | Side Quest Attachment + Graph Integration V0 | editor graph | DONE | NS-STORYLINES-V1-12 |
| NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | DONE | NS-STORYLINES-V1-CHECKPOINT |
| NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | DONE | NS-SCENES-V1 |

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
- Statut : DONE.
- Résultat NS-STORYLINES-06 : zone graph read-only livrée avec titre, source, relation détaillée à venir, noeuds d'étapes narratives réelles et empty state honnête.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`, captures Visual Gate `ns_storylines_06_graph_placeholder_desktop.png`, `ns_storylines_06_graph_placeholder_focus.png`, `ns_storylines_06_graph_placeholder_center.png`.
- Données : steps filtrées par `globalScenarioId`, `NarrativeStepSummary.name`, `NarrativeStepSummary.description`, compteur réel de steps ; aucune relation complexe inventée.
- Empty state : document Step Studio explicitement vide couvert par test ; wording `Aucune étape narrative disponible pour cette storyline.`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPageSurface`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune quête annexe, branche riche, mini-map, zoom control, chiffre cible ou donnée Selbrume ajouté ; `localEventFlow` reste absent du graph.
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
- Statut : DONE.
- Résultat NS-STORYLINES-07 : inspecteur droit remplacé par un panneau `Détails de la storyline` read-only, sourcé par la storyline sélectionnée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`, captures Visual Gate `ns_storylines_07_inspector_desktop.png`, `ns_storylines_07_inspector_focus.png`, `ns_storylines_07_inspector_panel.png`.
- Données : nom et description réels via `NarrativeScenarioSummary`, type prudent `Storyline principale`, source `ScenarioAsset globalStory`, compteurs d'étapes et cutscenes liées dérivés des steps filtrées.
- Sections futures : `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées` affichées uniquement comme `À venir`, `Non branché` ou `Modèle absent en V0`.
- Empty state : absence de globalStory couverte par test avec `Aucune storyline sélectionnée.`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et panel produites.
- Design System Gate : confirmé ; `PokeMapInspectorPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun tag réel, world rule, fact, activité récente, priorité, statut `Active`, niveau `Haute`, donnée Selbrume ou chiffre cible ajouté ; `localEventFlow` reste absent de l'inspecteur.
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
- Statut : DONE.
- Résultat NS-STORYLINES-08 : onglet `Chapitres` read-only livré avec état local de tab, chapitres réels issus de `GlobalStoryStudioDocument.chapters`, étapes liées résolues depuis `NarrativeStepSummary`, et empty state honnête.
- Fichiers modifiés : `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`, `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/narrative_workspace_projection_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`, captures Visual Gate `ns_storylines_08_chapters_tab_desktop.png`, `ns_storylines_08_chapters_tab_focus.png`, `ns_storylines_08_chapters_tab_center.png`.
- Données : `NarrativeChapterSummary` editor-side avec id, scenario id, nom, description, ordre, step ids normalisés, steps résolues et step ids manquants détectés depuis la metadata brute.
- Interactions : `Graph` et `Chapitres` changent uniquement l'état UI local ; `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non branchés / non mutants ; `Nouveau chapitre` est disabled.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites sur l'onglet `Chapitres`.
- Design System Gate : confirmé ; `PokeMapPageSurface`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapButton`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun statut éditorial, scène, quête annexe, donnée Selbrume, world rule, fact, activité récente ou chiffre cible ajouté ; `localEventFlow` reste absent de la tab Chapitres.
- Prochain lot attendu : NS-STORYLINES-09.

#### NS-STORYLINES-08-bis — Graph Tab Target Alignment / Default View V0

- Statut : DONE, sans changer le statut de `NS-STORYLINES-08`.
- Résultat : l'onglet `Graph` reste la vue par défaut et devient une vue canvas plus dominante, avec grille subtile, flux principal, nodes de chapitres réels et previews de steps réelles.
- Source : nodes macro depuis les `NarrativeChapterSummary` disponibles ; fallback read-only par steps si aucun chapitre ; empty state honnête si aucune step.
- Image cible : utilisée comme référence visuelle/layout uniquement, jamais comme source de données.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md`, captures Visual Gate `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites pour le Graph aligné cible.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; surfaces et accents via primitives PokeMap et `context.pokeMapColors`.
- Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
- Prochain lot recommandé inchangé : NS-STORYLINES-09.

#### NS-STORYLINES-08-ter — True Graph Geometry / Spatial Canvas V0

- Statut : DONE, sans changer le statut de `NS-STORYLINES-08`.
- Résultat : l'onglet `Graph` reste la vue par défaut et passe d'un flow `Wrap` à un vrai canvas spatial read-only avec nodes positionnés, layer d'edges, grille et légende compacte.
- Géométrie : positions calculées depuis la taille du canvas et le nombre de nodes ; flow `Début de lecture` -> chapitres réels -> `Relations à venir`, avec fallback steps si aucun chapitre.
- Edges : `CustomPainter` feature-specific, couleurs injectées via `context.pokeMapColors`, aucune relation métier inventée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md`, captures Visual Gate `ns_storylines_08_ter_true_graph_desktop.png`, `ns_storylines_08_ter_true_graph_focus.png`, `ns_storylines_08_ter_true_graph_center.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites pour le canvas spatial.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; graph composé avec primitives PokeMap et tokens `context.pokeMapColors`.
- Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
- Prochain lot recommandé inchangé : NS-STORYLINES-09.

### NS-STORYLINES-09 — Chapters Inspector / Step Ordering Read-only V0

- Type : editor UI.
- Objectif : créer inspecteur chapitre et ordre des étapes narratives read-only.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md`, captures Visual Gate NS09.
- Non-objectifs : pas de réordonnancement, pas d'ajout scène, pas de statut éditorial fake.
- Dépendances : NS-STORYLINES-08.
- Résumé : la tab `Chapitres` affiche maintenant une liste de chapitres avec sélection locale, un inspecteur chapitre read-only, l'ordre des étapes narratives réelles, et les données futures marquées à venir.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
- Design System Gate : confirmé ; composants feature-specific composés avec primitives PokeMap ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun wording `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre/step.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-10.

### NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0

- Type : visual gate.
- Objectif : harmoniser contre les deux cibles sans ajouter de feature.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`, captures Visual Gate NS10.
- Non-objectifs : pas de donnée fake, pas de pixel-perfect.
- Dépendances : NS-STORYLINES-09.
- Résumé : harmonisation visuelle V0 du graph et de la tab Chapitres, avec canvas plus dominant, nodes plus compacts, edges plus lisibles, légende/contrôles plus discrets et rows d'étapes plus denses.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : captures Graph et Chapitres desktop/focus/center produites en dark theme.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; couleurs via tokens / primitives PokeMap.
- Fake data : aucune donnée cible Selbrume, aucune quête annexe, aucun tag/world rule/fact/activité, aucune action future activée.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-11.

### NS-STORYLINES-11 — Storylines Interaction Wiring V0

- Type : editor UI / test.
- Objectif : brancher uniquement les interactions honnêtes.
- Résultat : sélection locale de `globalStory` existante, synchronisation des zones read-only, actions futures non mutantes, V1 Creation Readiness documenté.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md`, captures Visual Gate NS11.
- Non-objectifs respectés : pas de création Storyline, pas de validation globale, pas de graph editing, pas de modèle `StorylineAsset`, pas de quête annexe fake.
- Dépendances : NS-STORYLINES-10.
- Critères d'acceptation : interactions réelles fonctionnent, futures disabled, aucune mutation non prévue.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : analyse ciblée Storylines avec `flutter analyze --no-fatal-infos`.
- Visual Gate : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
- Design System Gate : confirmé, aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible, aucune quête annexe fake, aucun `localEventFlow` promu.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-CHECKPOINT.

### NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint

- Type : checkpoint.
- Objectif : décider si Storylines V0 est acceptable et documenter les limites V1.
- Résultat : Storylines V0 accepté avec limites V1 documentées.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Non-objectifs : pas de code, pas de tests modifiés, pas de polish.
- Dépendances : NS-STORYLINES-11.
- Critères d'acceptation : verdict clair, checklist V0, limites V1, recommandation de suite.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : analyse ciblée Storylines avec `flutter analyze --no-fatal-infos`.
- Visual Gate : inventaire des screenshots finaux NS10/NS11 inspecté ; captures utiles pour structure/theme/overflow, limitées par Ahem.
- Design system impact : gate confirmé, aucun `Color(0x...)` / `Colors.*`.
- Verdict : ACCEPTED V0 WITH V1 LIMITATIONS.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract.

### NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract

- Type : product-contract / design-only / documentation-only.
- Objectif : clarifier le modèle produit Storylines V1 avant toute nouvelle implémentation.
- Résultat : contrat sémantique créé ; boundaries Storyline / Chapter / Story Step / Scene clarifiées ; Graph et Structure définis ; triage UI V1 documenté.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Non-objectifs respectés : aucun code, widget, modèle, test, screenshot ou bouton activé.
- Dépendances : NS-STORYLINES-CHECKPOINT.
- Critères d'acceptation : contrat produit clair, matrices obligatoires, actions V1 utiles définies, `localEventFlow` exclu comme `sideQuest` par défaut.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Note produit : le problème principal était sémantique / produit, pas technique ; Storylines V0 reste une fondation valide mais V1 doit rendre la création et l'organisation réellement utilisables.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-01 — Storyline Authoring Model Decision.

### NS-STORYLINES-V1-01 — Storyline Authoring Model Decision

- Type : model decision / product architecture.
- Objectif : décider le modèle durable pour créer et relier Storylines, Chapters, Story Steps et Scenes.
- Résultat : décision hybride retenue.
- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
- Rôle `StorylineAsset` : structure produit auteur, types de storyline, chapters, story steps, scene links, outcomes, relationships, side quest availability, validation issues.
- Rôle `ScenarioAsset` : flow exécutable, scènes/orchestrations runtime, graph local, outcomes déclarés et conditions.
- Décisions clés : Structure est source d'authoring ; Graph est généré/read-only en V1 initial ; `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Risques : migration douce de `ScenarioAsset globalStory`, duplication temporaire pendant transition, besoin d'un contrat précis pour scene placeholders/outcomes.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Non-objectifs respectés : aucun code, modèle core, widget, test, screenshot ou bouton activé.
- Dépendances : NS-STORYLINES-V1-00.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract.

### NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract

- Type : data-contract / architecture.
- Objectif : transformer la décision V1-01 en contrat de données précis avant implémentation.
- Résultat : data shape conceptuelle livrée pour `StorylineAsset`, enums, chapters, steps, scene links, outcome links, relationships, conditions/effects, JSON, invariants, validations, migration legacy et tests futurs.
- Décisions majeures : `ProjectManifest.storylines: List<StorylineAsset>` futur avec `[]` par défaut ; chapters/steps/scene links inline dans `StorylineAsset`; outcome links au niveau scene link ; relationships au niveau projet recommandé plus tard ; legacy import preview non destructif.
- Risques : schéma JSON à implémenter avec compatibilité vieux projets ; wrappers no-code au-dessus de `ScriptCondition` à préciser en code ; relation side quest disponible mais UI de création encore future.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Non-objectifs : pas d'UI de création avant contrat data shape.
- Dépendances : NS-STORYLINES-V1-01.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0.

### NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0

- Type : core model / pure Dart / tests.
- Objectif : implémenter le modèle pur `StorylineAsset` V0 et ses sous-objets essentiels, sans codec JSON, sans `ProjectManifest.storylines`, sans migration legacy et sans UI.
- Résultat : modèle pur livré dans `map_core`, export public ajouté et tests unitaires ciblés ajoutés.
- Modèle livré : enums Storylines V1, `StorylineAsset`, chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
- Validations : ids/titres non vides, unicité locale, références internes chapter/step, règles d'état placeholder/linkedScenario/brokenLink/needsImplementation, source relationship inline.
- Immutabilité : champs `final`, collections copiées défensivement et exposées en non modifiable, equality/hashCode/toString manuels.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/lib/map_core.dart`, `packages/map_core/test/storyline_asset_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart`.
- Non-objectifs confirmés : aucun JSON `toJson/fromJson`, aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Dépendances : NS-STORYLINES-V1-02.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.

### NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0

- Type : core codec / manual JSON / pure Dart / tests.
- Objectif : ajouter un codec JSON manuel pour `StorylineAsset` et ses sous-objets, sans intégration `ProjectManifest.storylines`.
- Résultat : `StorylineAsset` peut faire `model -> toJson() -> fromJson(...) -> model équivalent`.
- JSON : enums encodés en strings lowerCamel stables via `.name`, listes/maps présentes en `[]` / `{}`, champs optionnels null omis.
- Decode : defaults `schemaVersion = 1`, `status = draft`, `chapters = []`, `sceneLinks = []`, `relationships = []`, `metadata = {}` ; erreurs de forme en `FormatException`, invariants via constructeurs / `ValidationException`.
- ScriptCondition : codec officiel existant réutilisé (`ScriptCondition.fromJson` / `toJson` générés), sans nouveau langage conditionnel.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/test/storyline_asset_test.dart`, `packages/map_core/test/storyline_asset_json_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart`.
- Non-objectifs confirmés : aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Dépendances : NS-STORYLINES-V1-03.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.

### NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0

- Type : core manifest / JSON compatibility / pure Dart / tests.
- Objectif : intégrer `StorylineAsset` dans `ProjectManifest.storylines`, sans migration legacy, sans UI et sans runtime.
- Résultat : `ProjectManifest` porte désormais `storylines: List<StorylineAsset>` avec default `[]`, roundtrip JSON et compatibilité vieux projets sans champ `storylines`.
- JSON : `storylines` est sérialisé via `StorylineAsset.toJson()` et désérialisé via `StorylineAsset.fromJson(...)`; champ absent ou `null` donne `[]`.
- Compatibilité : les anciens `ScenarioAsset(scope == globalStory)` restent dans `ProjectManifest.scenarios`; aucune `StorylineAsset` n'est créée automatiquement.
- Non-promotion : `ScenarioAsset(scope == localEventFlow)` reste un scénario local et n'est jamais promu en `sideQuest`.
- Generated files : `ProjectManifest` utilise Freezed/json_serializable ; build_runner limité à `packages/map_core` a régénéré uniquement les fichiers générés du manifest.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/project_manifest.dart`, `packages/map_core/lib/src/models/project_manifest.freezed.dart`, `packages/map_core/lib/src/models/project_manifest.g.dart`, `packages/map_core/test/project_manifest_storylines_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/project_manifest.dart test/project_manifest_storylines_test.dart`.
- Non-objectifs confirmés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune migration legacy, aucun import globalStory, aucune UI, aucun runtime.
- Dépendances : NS-STORYLINES-V1-04.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0.

### NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0

- Type : core authoring / pure Dart / legacy preview / tests.
- Objectif : proposer une preview non destructive de conversion des anciens `ScenarioAsset(scope == globalStory)` vers des `StorylineAsset(type: main)` drafts.
- Résultat : API pure `buildLegacyGlobalStoryImportPreview(ProjectManifest)` livrée dans `map_core`.
- Mapping : chaque `globalStory` legacy produit un candidat draft `StorylineAsset` avec id déterministe `legacy_<scenario.id>`, type `main`, status `draft`, titre/description issus du scénario et `legacySource.kind = scenario.globalStory`.
- Metadata legacy : chapitres et steps sont importés quand les metadata `authoring.globalStoryStudioDocument` et `authoring.stepStudioDocument` sont lisibles ; sinon le candidat reste minimal avec issues stables.
- Diagnostics : issues stables via `StorylineValidationIssue` pour aucun globalStory, multiples globalStory, storylines existantes, collision d'id, metadata absente/invalide, step manquante, step non assignée, outcomes non mappés et `localEventFlow` ignoré.
- Non-mutation : la preview ne modifie jamais `ProjectManifest`, `ProjectManifest.storylines`, `ProjectManifest.scenarios` ou les assets existants.
- Non-promotion : `ScenarioAsset(scope == localEventFlow)` est explicitement ignoré et ne devient jamais une `sideQuest`.
- Fichiers créés/modifiés : `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`, `packages/map_core/test/storyline_legacy_import_preview_test.dart`, `packages/map_core/lib/map_core.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_legacy_import_preview_test.dart`, `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_legacy_import_preview_test.dart`.
- Non-objectifs confirmés : aucun `ProjectManifest` modifié, aucun `StorylineAsset` modifié, aucun `ScenarioAsset` modifié, aucun build_runner, aucune UI, aucun runtime, aucun import/apply mutateur.
- Dépendances : NS-STORYLINES-V1-05.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-07 — Create Main Storyline Flow V0.

### NS-STORYLINES-V1-07 — Create Main Storyline Flow V0 / Storylines UI Usability Reset

- Type : editor UI / authoring flow / tests / visual gate.
- Objectif : rendre Storylines utile en créant une vraie Storyline principale dans `ProjectManifest.storylines`.
- Résultat : flow `Nouvelle storyline` livré avec formulaire minimal, type `main` verrouillé, titre obligatoire, description optionnelle, id slugifié unique, mutation contrôlée du manifest et sélection de la storyline créée.
- Source de vérité : `ProjectManifest.storylines` devient la source V1 authoring ; le legacy `ScenarioAsset.globalStory` reste visible uniquement comme information non importée et non sélectionnable.
- UI reset : tabs principales limitées à `Graph` / `Structure`, panneau secondaire simplifié, recherche fake retirée, side quests fake absentes, CTA secondaire `+` supprimé/non actif, `Nouveau chapitre` reste disabled / bientôt.
- Graph : read-only honnête depuis `StorylineAsset`; si la storyline n'a pas de chapitre, affiche un node/storyline vide avec instruction d'ajouter des chapitres dans Structure.
- Structure : affiche titre, description, type, status draft, sections vides `Chapitres`, `Étapes narratives`, `Scènes liées`, avec création de chapitre reportée.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`, captures Visual Gate V1-07.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : `ns_storylines_v1_07_empty_storylines_desktop.png`, `ns_storylines_v1_07_create_main_dialog.png`, `ns_storylines_v1_07_created_main_graph.png`, `ns_storylines_v1_07_created_main_structure.png`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Non-objectifs confirmés : aucun `map_core` modifié, aucune sideQuest, aucun chapter, aucune step, aucune scene placeholder, aucun import legacy automatique, aucun `localEventFlow` promu, aucun runtime/gameplay/battle modifié.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.

### NS-STORYLINES-V1-07-bis — Storylines Workspace Cleanup / Dead Legacy Removal

- Type : editor UI cleanup / technical debt / tests / visual regression.
- Objectif : nettoyer la dette laissée par V1-07 sans changer le comportement produit.
- Résultat : suppression de l'état `_selectedGlobalStoryId` mort, confirmation que `_LegacyStorylinesWorkspaceState` et `_StorylineContentTab.chapters` sont absents, et remplacement du tap silencieux `warnIfMissed: false` par une assertion explicite sur le CTA `Nouveau chapitre — bientôt` désactivé.
- Comportement préservé : `Nouvelle storyline` crée toujours une main `StorylineAsset(type: main, status: draft)`, les tabs principales restent `Graph` / `Structure`, aucun import legacy automatique, aucun `localEventFlow` promu, aucune sideQuest/chapter/step/scene créée.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`, captures Visual Gate V1-07 régénérées.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` dans les fichiers touchés.
- Non-objectifs confirmés : aucun `map_core`, runtime, gameplay, battle, modèle core, generated file ou build_runner modifié/lancé.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.

### NS-STORYLINES-V1-08 — Structure Tab Authoring V0

- Type : editor UI / authoring flow / structure tab / tests / visual gate.
- Objectif : rendre l'onglet Structure utilisable pour créer des chapitres et des étapes narratives dans une `StorylineAsset` existante.
- Résultat : `Nouveau chapitre` ouvre un formulaire minimal, crée un `StorylineChapter` draft avec id slugifié unique, ordre calculé et sélection locale du chapitre créé.
- Résultat : `Nouvelle étape narrative` ouvre un formulaire minimal depuis un chapitre sélectionné, crée une `StorylineStep` avec id slugifié unique à l'échelle de la storyline, ordre calculé dans le chapitre, puis l'affiche dans Structure.
- Structure : affiche résumé storyline, liste des chapitres, détail du chapitre sélectionné, liste des étapes narratives et section `Scènes liées` désactivée.
- Graph : reste minimal et read-only ; après création de chapitres/steps il affiche un résumé réel et le message que le graph détaillé viendra au lot `Graph From StorylineAsset`.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`, captures Visual Gate V1-08.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` dans les fichiers touchés.
- Non-objectifs confirmés : aucune sideQuest, aucun scene placeholder, aucun sceneLink, aucun import legacy automatique, aucun `localEventFlow` promu, aucun `map_core`, runtime, gameplay ou battle modifié.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-09 — Create Side Quest Flow V0.

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
Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
Current lot: NS-STORYLINES-V1-CHECKPOINT
Current lot status: DONE
Next recommended lot: NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation
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
| NS-STORYLINES-06 | DONE | 2026-05-28 | Graph read-only placeholder livré avec steps réelles et empty state. |
| NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
| NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment et ter canvas spatial livrés sans changer le statut NS08. |
| NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
| NS-STORYLINES-10 | DONE | 2026-05-28 | Visual harmonization Graph/Chapitres et Visual Gate complet livrés sans nouvelle feature. |
| NS-STORYLINES-11 | DONE | 2026-05-28 | Interaction wiring V0 livré : sélection locale de globalStory existante, synchronisation zones read-only, actions futures non mutantes, notes V1 Creation Readiness. |
| NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 semantic/product contract. |
| NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
| NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
| NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
| NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
| NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
| NS-STORYLINES-V1-05 | DONE | 2026-05-28 | ProjectManifest.storylines Integration V0 livré avec compatibilité vieux JSON et sans migration legacy. |
| NS-STORYLINES-V1-06 | DONE | 2026-05-28 | Legacy GlobalStory Import Preview V0 livré : candidats non destructifs depuis `globalStory`, issues stables, `localEventFlow` ignoré. |
| NS-STORYLINES-V1-07 | DONE | 2026-05-28 | Create Main Storyline Flow V0 livré : création main `StorylineAsset`, Graph/Structure seulement, aucun import legacy automatique. |
| NS-STORYLINES-V1-07-bis | DONE | 2026-05-28 | Cleanup technique Storylines livré sans changement produit : legacy mort absent, tap silencieux supprimé, Visual Gate V1-07 régénéré. |
| NS-STORYLINES-V1-08 | DONE | 2026-05-29 | Structure Tab Authoring V0 livré : création de chapitres et steps, Graph minimal honnête, aucun sceneLink/sideQuest/import legacy. |
| NS-STORYLINES-V1-09 | DONE | 2026-05-29 | Create Side Quest Flow V0 livré : création réelle de `StorylineAsset(type: sideQuest, status: draft)`, liste main/sideQuest séparée, Structure réutilisée, aucune relationship/availability/sceneLink/import legacy. |
| NS-STORYLINES-V1-10 | DONE | 2026-05-29 | Graph From StorylineAsset V0 livré : graph read-only généré depuis la StorylineAsset sélectionnée, nodes storyline/chapter/step, edges d'ordre auteur, sideQuest autonome non intégrée au graph principal. |

## 14. V1 Creation Readiness Notes

NS-STORYLINES-11 reste un lot V0 : aucune création de storyline, aucun `StorylineAsset`, aucune quête annexe fake et aucune mutation projet.

Pré-requis recommandés pour activer la création Storylines V1 :

- Décision modèle : choisir entre un `StorylineAsset` dédié ou un `ScenarioAsset` enrichi, avec contrat editor/runtime explicite.
- Types de storyline : prévoir au minimum `main`, `sideQuest`, `tutorial`, `epilogue`, `episode`, sans les inférer depuis `localEventFlow`.
- Storyline principale : définir une règle d'unicité éventuelle, le comportement si une principale existe déjà, et le flow de remplacement ou migration.
- Flow auteur : création no-code guidée avec titre, type, source, chapitre initial éventuel, validation immédiate et preview read-only avant sauvegarde.
- Validation anti-duplicate : empêcher les ids/titres conflictuels, les types incompatibles et les liens de steps orphelins.
- Compatibilité : décider comment migrer ou projeter le `ScenarioAsset globalStory` actuel sans casser les projets existants.
- Quêtes annexes : les afficher uniquement quand le modèle existe ; `localEventFlow` ne suffit pas et ne doit jamais devenir une quête annexe par défaut.
- Création : storyline principale et quête annexe prévues pour V1 uniquement, pas en V0.
- Boutons activables plus tard : `Nouvelle storyline`, `+`, `Nouveau chapitre`, validation narrative et création de quête annexe après contrat modèle + tests anti-fake.

Suite V1 documentaire recommandée :

- `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
- `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
- `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
- `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`
- `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`
- `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`
- `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`
- `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`
- `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`
- `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`
- `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`
- `NS-STORYLINES-V1-11 — Side Quest Attachment + Graph Integration V0`
- `NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment`
- `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`

## 15. Changelog

### 2026-05-29 — NS-STORYLINES-V1-CHECKPOINT

- Storylines V1 Acceptance Checkpoint livré en audit-only / documentation-only.
- Verdict : `ACCEPTED WITH LIMITATIONS`.
- Storylines V1 est fermé comme atelier auteur initial : modèle, JSON, `ProjectManifest.storylines`, preview legacy, création main/sideQuest, chapters/steps, attachement sideQuest explicite, graph read-only et polish V1 sont couverts par tests ciblés.
- Limites acceptées : pas encore de scene placeholder, sceneLink, Scene Outcome branch, facts/world rules, validation narrative globale, edit/delete/reorder avancé, import legacy appliqué ou runtime execution.
- Limite d'évidence : les rapports V1-00 à V1-11 et les captures V1-07 à V1-11 attendus sont absents du repo courant ; les tests et le rapport V1-12 restent présents.
- Prochaine phase recommandée : `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.

### 2026-05-29 — NS-STORYLINES-V1-12

- V1 Visual Graph Enrichment livré côté editor : le graph read-only est plus lisible sans ajouter de comportement produit.
- Améliorations visuelles : légende compacte, hiérarchie des nodes storyline/chapter/step/sideQuest, canvas plus dense, sideQuest attachée plus distincte.
- Edges clarifiés : ordre auteur en ligne principale, disponibilité de quête annexe en ligne secondaire pointillée via tokens du design system.
- Visual-only confirmé : aucune donnée métier créée, aucune mutation de `ProjectManifest`, aucune création de relationship/availability/sceneLink/scene placeholder dans ce lot.
- `Structure` reste la source d'authoring ; le graph reste read-only ; aucun import legacy automatique ; `localEventFlow` reste exclu.
- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace_shell_test.dart`, captures V1-12, rapport V1-12.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs, `rg` contrôle features interdites.
- Prochain lot recommandé : `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`.

### 2026-05-29 — NS-STORYLINES-V1-11

- Side Quest Attachment + Graph Integration V0 livré côté editor : une sideQuest peut être attachée explicitement à une main storyline depuis Structure.
- L'attachement crée une vraie `StorylineRelationship(kind: sideQuestAvailableDuring)` inline sur la sideQuest, avec `SideQuestAvailability.startAnchor` sur un chapitre ou une étape de la main storyline.
- Le graph principal affiche une sideQuest seulement quand cette relation existe ; les sideQuests non attachées restent absentes du graph principal.
- Le graph sideQuest indique l'état attaché/non attaché sans devenir éditeur interactif.
- Aucun `map_core` modifié ; aucun `StorylineSceneLink`, scene placeholder, outcome, fact, world rule, import legacy automatique ou `localEventFlow` promu.
- Fichiers créés/modifiés : `storylines_workspace.dart`, `storylines_graph_model.dart`, `storylines_graph_view.dart`, `storylines_workspace_shell_test.dart`, captures V1-11, rapport V1-11.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment`.

### 2026-05-29 — NS-STORYLINES-V1-10

- Graph From StorylineAsset V0 livré côté editor : le Graph affiche un canvas read-only généré depuis la `StorylineAsset` sélectionnée.
- Nodes réels : storyline racine, chapitres triés par `order`, steps triées par `order`, empty states honnêtes pour storyline sans chapitre et chapitre sans step.
- Edges visibles : uniquement ordre auteur racine -> premier chapitre puis chapitre -> chapitre suivant ; aucune branche narrative, availability, outcome ou convergence fake.
- SideQuest sélectionnée : graph autonome avec badge `Quête annexe indépendante`, sans lien vers la main storyline.
- Main sélectionnée avec sideQuests existantes : note d'intégration future, aucune sideQuest injectée comme node/branche du graph principal.
- Structure reste source d'authoring ; le graph ne crée ni chapter, ni step, ni relationship, ni `SideQuestAvailability`, ni scene placeholder, ni `StorylineSceneLink`.
- Aucun import legacy automatique ; `localEventFlow` reste exclu.
- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace.dart`, `storylines_workspace_shell_test.dart`, captures V1-10, rapport V1-10.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`.

### 2026-05-29 — NS-STORYLINES-V1-09

- Create Side Quest Flow V0 livré côté editor : `Nouvelle storyline` peut créer une vraie `StorylineAsset(type: sideQuest, status: draft)` après existence d'une main storyline.
- Le dialog de création choisit entre `Histoire principale` et `Quête annexe` ; la main reste unique et la sideQuest est sélectionnée après création.
- Le panneau secondaire sépare `Histoire principale` et `Quêtes annexes`, avec compteurs réels depuis `ProjectManifest.storylines`.
- Structure réutilise le même authoring chapters/steps pour une sideQuest sans modifier la main storyline.
- Graph reste minimal et honnête : une sideQuest sélectionnée indique qu'elle n'est pas reliée au graph principal ; aucune `StorylineRelationship`, `SideQuestAvailability`, scene placeholder ou `StorylineSceneLink` n'est créée.
- Aucun import legacy automatique ; `localEventFlow` reste exclu.
- Visual Gate V1-09 produit en dark theme.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures V1-09, rapport V1-09.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`.

### 2026-05-29 — NS-STORYLINES-V1-08

- Structure Tab Authoring V0 livré côté editor : création de chapitres et d'étapes narratives dans `ProjectManifest.storylines`.
- Mutations immuables via le notifier editor existant ; aucun modèle `map_core` modifié.
- IDs `chapter_...` et `step_...` slugifiés, stables et collision-safe ; ordre chapitre/step calculé depuis les données existantes.
- Graph minimal mis à jour pour afficher les vrais compteurs chapitres/steps sans branches ou edges fake.
- Visual Gate V1-08 produit en dark theme.
- Prochain lot recommandé : `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`.

### 2026-05-28 — NS-STORYLINES-V1-07-bis

- Cleanup technique sans changement produit sur `storylines_workspace.dart`.
- Suppression de l'état local mort `_selectedGlobalStoryId`; confirmation que `_LegacyStorylinesWorkspaceState` et `_StorylineContentTab.chapters` ne sont plus présents.
- Suppression du `warnIfMissed: false` restant dans le test shell ; le CTA `Nouveau chapitre — bientôt` est maintenant asserté présent et désactivé.
- Tests ciblés, analyse ciblée, Design System Gate et Visual Gate V1-07 validés.
- Prochain lot recommandé : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.

### 2026-05-28 — NS-STORYLINES-V1-07

- Create Main Storyline Flow V0 livré côté editor : `Nouvelle storyline` ouvre un formulaire minimal, crée une `StorylineAsset(type: main, status: draft)` dans `ProjectManifest.storylines`, puis sélectionne la storyline créée.
- UI Storylines reset vers deux tabs principales seulement : `Graph` et `Structure`.
- Graph et Structure se synchronisent sur `ProjectManifest.storylines`; le legacy `globalStory` reste non importé automatiquement.
- Aucun `map_core`, runtime, gameplay, battle, sideQuest, chapter, step ou scene placeholder modifié/créé.
- Visual Gate V1-07 produit en dark theme.
- Prochain lot recommandé : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.

### 2026-05-28 — NS-STORYLINES-V1-06

- Preview d'import legacy livrée dans `map_core` via `buildLegacyGlobalStoryImportPreview(ProjectManifest)`.
- Les `ScenarioAsset(scope == globalStory)` produisent des candidats `StorylineAsset(type: main, status: draft)` sans mutation du manifest.
- Les metadata legacy Global Story / Step Studio sont importées quand elles sont lisibles ; sinon des issues stables signalent les limites.
- `localEventFlow` est explicitement ignoré et n'est jamais promu en `sideQuest`.
- Tests ajoutés pour aucun / un / plusieurs globalStory, existing storylines, collision d'id, import chapters/steps, missing step, outcomes non mappés, invalid metadata et no-mutation JSON.
- Non-objectifs respectés : aucun `ProjectManifest`, `StorylineAsset`, `ScenarioAsset`, generated file, build_runner, UI ou runtime modifié.
- Prochain lot recommandé : `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`.

### 2026-05-28 — NS-STORYLINES-V1-05

- `ProjectManifest.storylines: List<StorylineAsset>` intégré dans `map_core`.
- Compatibilité vieux projets confirmée : absence du champ `storylines` décodée en `[]`.
- Roundtrip JSON `ProjectManifest` avec storylines couvert par tests.
- Aucune migration legacy : `ScenarioAsset.globalStory` reste dans `scenarios` et ne crée pas automatiquement de `StorylineAsset`.
- `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Non-objectifs respectés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune UI, aucun runtime.
- Prochain lot recommandé : `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`.

### 2026-05-28 — NS-STORYLINES-V1-04

- Codec JSON manuel livré pour `StorylineAsset` et ses sous-objets essentiels.
- Enums Storylines sérialisés en strings lowerCamel stables, jamais en index.
- Decode strict : erreurs de forme en `FormatException`, invariants métiers préservés par les constructeurs.
- `ScriptCondition` sérialisé via le codec officiel existant ; aucun langage conditionnel local ajouté.
- Tests JSON ajoutés : roundtrip minimal/complet, defaults, enums, invalid JSON et validations au decode.
- Non-objectifs respectés : aucun `ProjectManifest.storylines`, aucune migration legacy, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Prochain lot recommandé : `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`.

### 2026-05-28 — NS-STORYLINES-V1-03

- Premier modèle pur Storylines V1 livré dans `map_core`.
- `StorylineAsset` et sous-objets essentiels ajoutés : chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
- Enums Storylines V1 ajoutés pour type, status, scene link state/role, relationship kind, validation severity, effect type, anchor kind et scene ref kind.
- Tests ciblés ajoutés pour constructions valides, validations locales, références internes, règles d'état, immutabilité, equality/hashCode et absence de JSON codec.
- Non-objectifs respectés : aucun `toJson/fromJson`, aucun `ProjectManifest.storylines`, aucune migration legacy, aucune UI, aucun generated file.
- Prochain lot recommandé : `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`.

### 2026-05-28 — NS-STORYLINES-V1-02

- Contrat de données Storylines V1 livré.
- Data shape conceptuelle définie pour `StorylineAsset`, `StorylineType`, `StorylineStatus`, chapters, steps, scene links, outcome links, relationships, availability et validation issues.
- Décision : `StorylineAsset` stockera chapters/steps/scene links inline ; `ProjectManifest.storylines` futur devra décoder les vieux projets en `[]`.
- Décision : `StorylineSceneLink` V1 initial démarre avec `placeholder` et `linkedScenario`; dialogue/cinematic/battle restent dans le `ScenarioAsset` exécutable.
- Décision : outcome links V1 initial activent/complètent des `StorylineStep`; facts/world rules réservés à plus tard.
- Migration : legacy import preview non destructif depuis `ScenarioAsset.globalStory`; `localEventFlow` jamais promu automatiquement.
- Prochain lot recommandé : `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`.

### 2026-05-28 — NS-STORYLINES-V1-01

- Décision d'architecture Storylines V1 livrée.
- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
- `StorylineAsset` devient la source produit pour Storylines, Chapters, Story Steps, scene links, outcomes, relationships, side quest availability et validation issues.
- `ScenarioAsset` reste le modèle exécutable pour les scènes/flows runtime et n'est pas enrichi comme conteneur produit Storyline.
- `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Décision Graph : `Structure` est source d'authoring ; `Graph` est généré/read-only en V1 initial, édition limitée plus tard.
- Prochain lot recommandé : `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`.

### 2026-05-28 — NS-STORYLINES-V1-00

- Reset sémantique produit Storylines V1 livré.
- Clarification : le problème principal n'était pas technique mais sémantique / produit.
- Storylines V0 reste valide comme fondation, mais V1 doit rendre la création et l'organisation réellement utilisables.
- Contrat canonique documenté : Storyline, Chapter, Story Step, Scene, Scene inputs/outputs/outcomes, Side Quest, Event/Scene/Map chain.
- Décision produit recommandée : deux onglets principaux `Graph` et `Structure`; pas d'onglets globaux `Étapes` ou `Scènes`.
- Prochain lot recommandé : `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`.

### 2026-05-28 — NS-STORYLINES-CHECKPOINT

- Storylines V0 accepté avec limites V1 documentées.
- Vérifications ciblées passées : Storylines shell, caractérisation anti-fake, projection narrative et analyse ciblée.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*`.
- Visual Gate final inventorié : captures NS10 et NS11 recommandées pour structure/theme/overflow, avec limite Ahem.
- Limites V0 actées : pas de création storyline, pas de quête annexe, pas de modèle `StorylineAsset`, pas de graph editing, pas de scène métier finale.
- Prochain lot recommandé : `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`.

### 2026-05-28 — NS-STORYLINES-11-bis

- Correction de cohérence documentaire de la roadmap.
- `NS-STORYLINES-11` est maintenant `DONE` dans toutes les sections structurantes.
- Le prochain lot reste `NS-STORYLINES-CHECKPOINT`.
- Aucun code, test, screenshot ou modèle modifié.

### 2026-05-28 — NS-STORYLINES-11

- Câblage d'une sélection locale de `globalStory` existante depuis le panneau secondaire Storylines.
- Synchronisation read-only du header, des KPI dérivés, du graph, de l'inspecteur Storyline et de la tab `Chapitres` avec la storyline sélectionnée.
- Conservation des tabs réellement branchées à `Graph` / `Chapitres`; `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non mutantes.
- Réinitialisation prudente de la sélection de chapitre lorsque la storyline effective change.
- Actions futures conservées disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`, recherche.
- Visual Gate dark interaction produit : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; wiring via primitives PokeMap existantes.
- Fake data : aucune donnée cible Selbrume, aucune quête annexe fake, aucun `localEventFlow` promu en storyline/quête/chapter/node.
- V1 Creation Readiness documenté : modèle, types, unicité, flow auteur, validation et migration à décider avant création.
- Prochain lot recommandé : `NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint`.

### 2026-05-28 — NS-STORYLINES-10

- Harmonisation visuelle V0 du workspace Storylines sans ajout de feature métier.
- Vue `Graph` : canvas plus dominant, header plus compact, nodes plus compacts, edge layer plus lisible, légende et contrôles read-only plus discrets.
- Vue `Chapitres` : proportion liste/inspecteur stabilisée, cards de chapitres et rows d'étapes narratives compactées, inspecteur chapitre mieux équilibré.
- Visual Gate dark complet produit : `ns_storylines_10_graph_desktop.png`, `ns_storylines_10_graph_focus.png`, `ns_storylines_10_graph_center.png`, `ns_storylines_10_chapters_desktop.png`, `ns_storylines_10_chapters_focus.png`, `ns_storylines_10_chapters_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; harmonisation via primitives PokeMap et `context.pokeMapColors`.
- Fake data : aucune donnée cible Selbrume, aucun tag/world rule/fact/activité, aucune quête annexe fake, aucune action future activée.
- Prochain lot recommandé : `NS-STORYLINES-11 — Storylines Interaction Wiring V0`.

### 2026-05-28 — NS-STORYLINES-09

- Livraison de l'onglet `Chapitres` avec sélection locale de chapitre : premier chapitre réel sélectionné par défaut, clic sur un autre chapitre limité à l'état UI local.
- Ajout d'un inspecteur chapitre read-only avec titre, description, ordre, source `Global Story Studio`, mode `Lecture seule` et compteur d'étapes narratives.
- Ajout de l'ordre des étapes narratives depuis les vraies `NarrativeStepSummary`, sans drag/drop, édition, navigation ou mutation projet.
- Conservation des protections NS08-ter : graph spatial par défaut, tab `Chapitres` accessible, tabs futures non mutantes, actions futures disabled / non mutantes.
- Visual Gate dark produit : `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; composants Storylines feature-specific composés avec primitives PokeMap.
- Fake data : aucun `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre ou étape.
- Prochain lot recommandé : `NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0`.

### 2026-05-28 — NS-STORYLINES-08-ter

- Transformation du graph en vrai canvas spatial read-only : nodes positionnés dans un `Stack`, layer d'edges `CustomPainter`, grille conservée et légende compacte.
- Conservation stricte des données réelles : `NarrativeChapterSummary` comme nodes macro, previews compactes de `NarrativeStepSummary`, fallback steps et empty state existants.
- Aucun changement métier : pas de création, édition, drag/drop, mini-map active, zoom actif, quêtes annexes, tags, world rules, facts ou activité récente.
- Tests Storylines renforcés avec clés `storylines-graph-spatial-layer`, `storylines-graph-edge-layer`, `storylines-graph-node-start`, nodes de chapters et note read-only.
- Visual Gate dark produit : `ns_storylines_08_ter_true_graph_desktop.png`, `ns_storylines_08_ter_true_graph_focus.png`, `ns_storylines_08_ter_true_graph_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; couleurs des edges et surfaces via `context.pokeMapColors`.
- Prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-08-bis

- Réalignement visuel de l'onglet `Graph` avec l'image cible principale, utilisée uniquement comme référence de composition.
- Conservation de `Graph` comme vue par défaut.
- Remplacement de la lecture graph trop verticale par un canvas sombre avec grille tokenisée, flux principal, nodes macro de chapitres réels et previews de steps réelles.
- Conservation de la tab `Chapitres` NS-STORYLINES-08 et des tabs futures non mutantes.
- Conservation des actions futures disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`.
- Aucun changement métier, aucun modèle core, aucun provider, aucun runtime/gameplay/battle.
- Production des captures Visual Gate dark `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune quête annexe fake, aucune mini-map / zoom actif, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-08

- Ajout d'un read model editor-side `NarrativeChapterSummary` dans la projection narrative.
- Extraction des chapitres depuis `GlobalStoryStudioDocument.chapters`, avec ordre conservé, steps résolues, step ids manquants détectés depuis la metadata brute, et exclusion des `localEventFlow`.
- Ajout d'un état UI local pour basculer uniquement entre `Graph` et `Chapitres` sans mutation projet ou état narratif persistant.
- Ajout du contenu `Chapitres` read-only : source `Global Story Studio`, liste ordonnée, description réelle, compteur d'étapes narratives, aperçu des étapes liées, bouton `Nouveau chapitre` disabled et empty state honnête.
- Conservation du panneau secondaire NS-STORYLINES-04, du header/tabs/KPI NS-STORYLINES-05, du graph NS-STORYLINES-06 et de l'inspecteur NS-STORYLINES-07.
- Adaptation des tests Storylines et projection ; vérification des tabs futures non mutantes, de l'absence de `localEventFlow`, de l'absence de `Scènes du chapitre` et de l'absence de statuts éditoriaux fake.
- Production des captures Visual Gate dark `ns_storylines_08_chapters_tab_desktop.png`, `ns_storylines_08_chapters_tab_focus.png`, `ns_storylines_08_chapters_tab_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune création/édition/suppression/réorganisation active, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-07

- Remplacement de l'inspecteur placeholder droit par un panneau `Détails de la storyline` read-only.
- Affichage des données réelles de la storyline sélectionnée : titre, description, type prudent `Storyline principale`, source `ScenarioAsset globalStory`, compteur d'étapes narratives et compteur de cutscenes liées.
- Ajout de sections futures explicitement non branchées : `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées`.
- Ajout d'un empty state honnête `Aucune storyline sélectionnée.` lorsqu'aucune globalStory n'est disponible.
- Conservation du panneau secondaire NS-STORYLINES-04, du header/tabs/KPI NS-STORYLINES-05 et du graph placeholder NS-STORYLINES-06.
- Adaptation des tests Storylines et caractérisation ; vérification que `localEventFlow` ne devient pas une donnée d'inspecteur.
- Production des captures Visual Gate dark `ns_storylines_07_inspector_desktop.png`, `ns_storylines_07_inspector_focus.png`, `ns_storylines_07_inspector_panel.png`.
- Confirmation : aucune donnée cible hardcodée, aucune section future active, aucune action mutante, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-08 — Chapters Tab Read-only V0`.

### 2026-05-28 — NS-STORYLINES-06

- Remplacement du placeholder `Graph — à venir / Placeholder read-only` par une zone `Graph read-only`.
- Affichage des étapes narratives réelles de la storyline sélectionnée via `NarrativeStepSummary`.
- Ajout d'un état vide honnête pour une storyline avec document Step Studio explicitement vide.
- Les relations détaillées restent `à venir` ; aucun réseau de branches, quête annexe, mini-map, zoom control ou interaction graph n'a été ajouté.
- Conservation du header/tabs/KPI NS-STORYLINES-05, du panneau secondaire NS-STORYLINES-04 et de l'inspecteur placeholder.
- Adaptation des tests Storylines et caractérisation ; vérification de l'absence de `localEventFlow` dans le graph.
- Production des captures Visual Gate dark `ns_storylines_06_graph_placeholder_desktop.png`, `ns_storylines_06_graph_placeholder_focus.png`, `ns_storylines_06_graph_placeholder_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune branche imaginaire, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-07 — Storyline Inspector Read-only V0`.

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
