# NS-STORYLINES-00 — Storylines Workspace Scope / Current State & Target Gap Audit

## 1. Executive summary

NS-STORYLINES-00 est un audit sans code de l'état actuel du workspace Storylines / Global Story et de l'écart avec les deux cibles fournies par Karim :

- image actuelle inspectée : `Screenshot 2026-05-27 at 22.11.51.png` ;
- cible Graph inspectée : `1 - global storyline.png` ;
- cible Chapitres inspectée : `2 - chapitres.png`.

Verdict court :

- l'écran actuel affiché par le screenshot est le workspace `EditorWorkspaceMode.globalStory`, rendu par `NarrativeWorkspaceCanvas` puis `GlobalStoryStudioWorkspace` / `GlobalStoryStudioShell` ;
- il est déjà placé dans la bonne architecture NS-HOME : `ProjectExplorerPanel` global distinct, `NarrativeStudioShell` interne, `NarrativeStudioSidebar` interne, `NarrativeStudioHeader` interne ;
- le contenu central Storylines reste une ancienne expérience `Global Story Studio v1`, très orientée structure technique de chapters + steps, avec beaucoup de vide et un inspecteur de step ;
- le code ne possède pas encore un vrai modèle métier `Storyline` riche comme dans la cible ; il possède surtout `ScenarioAsset`, un scénario `scope == globalStory`, des scénarios `localEventFlow`, et des documents d'authoring stockés en metadata ;
- les données nécessaires au design cible sont partiellement disponibles pour les chapitres, steps, liens macro et cutscenes, mais la plupart des informations riches de la cible restent absentes ou à risque de fake : quêtes annexes, type de storyline, priorité, tags, facts modifiés, world rules affectées, activité récente, validation globale, graph riche multi-storylines ;
- le prochain lot doit être un read model / data contract, pas une implémentation UI directe.

Recommandation :

```text
NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
```

Ce lot doit définir ce qui est réellement affichable, dérivable, absent ou disabled avant toute refonte visuelle. Le risque majeur serait de copier la cible avec des données Selbrume, chiffres, tags, activités ou relations hardcodés.

Point de garde-fou design system : toute future UI Storylines doit utiliser le design system PokeMap (`EditorChrome`, `EditorPaneSurface`, composants de sidebar, panels, boutons et tokens existants ou extensions design-system). Aucun écran Storylines ne doit recréer une palette locale ou des primitives ad hoc pour copier l'image cible.

## 2. Files inspected

### Fichiers de gouvernance et rapports

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md`
- `reports/narrativeStudio/ui/ns_home_23_narrative_overview_final_micro_polish.md`
- `reports/narrativeStudio/ui/ns_home_22_target_gap_audit_final_polish_plan.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`

Constats importants :

- NS-HOME est fermé en V0 avec limites V1 documentées.
- `ProjectExplorerPanel` reste la sidebar globale PokeMap.
- `NarrativeStudioSidebar` reste la sidebar interne Narrative Studio.
- `Maps` a été explicitement retiré de la sidebar interne NS-HOME.
- `Aperçu` est fermé ; ce chantier ne doit pas rouvrir le dashboard Overview.
- `AGENTS.md` impose un usage strict du design system PokeMap pour les primitives UI editor et interdit les couleurs hardcodées dans les features.

### Fichiers UI audités

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`

### Fichiers de modèles narratifs / core audités

- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`

### Tests consultés comme preuve de comportement actuel

- `packages/map_editor/test/global_story_studio_workspace_test.dart`
- `packages/map_editor/test/global_story_studio_ux_test.dart`
- `packages/map_editor/test/global_story_studio_authoring_test.dart`
- `packages/map_editor/test/global_story_studio_behavior_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`

### Fichiers attendus mais absents

- `packages/map_editor/lib/src/ui/canvas/narrative_library_panel.dart` : absent.
- `reports/narrativeStudio/storylines/` : absent avant ce lot ; créé uniquement pour ce rapport.

## 3. Current Storylines UI architecture

### Chemin de rendu réel

L'écran actuel du screenshot est rendu par la chaîne suivante :

```text
EditorShellPage
→ EditorCanvasHost
→ NarrativeWorkspaceCanvas
→ NarrativeStudioShell
   ├─ NarrativeStudioSidebar
   └─ main area
      ├─ NarrativeStudioHeader
      └─ GlobalStoryStudioWorkspace
         └─ GlobalStoryStudioShell
            ├─ GlobalStoryStudioTopBar
            ├─ GlobalStoryNavPanel
            ├─ GlobalStoryFlowPanel
            └─ GlobalStoryStepDetailPanel
```

`NarrativeWorkspaceCanvas` choisit le contenu central selon `EditorWorkspaceMode`. Pour `EditorWorkspaceMode.globalStory`, il instancie `GlobalStoryStudioWorkspace` avec :

- `editorNotifier`;
- `project`;
- `projection`;
- `selectedGlobalStoryId`;
- `selectedStepId`;
- callbacks `onSelectGlobalStory`, `onSelectStep`, `onOpenStepStudio`.

### Widget qui affiche l'ancien écran

Le widget principal est :

```text
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
→ GlobalStoryStudioWorkspace
```

Ce widget hydrate deux documents d'authoring depuis le scénario global :

- `StepStudioDocument`;
- `GlobalStoryStudioDocument`.

Il délègue ensuite l'assemblage visuel à :

```text
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
→ GlobalStoryStudioShell
```

### Navigation interne actuelle

Il y a deux niveaux de navigation visibles :

1. Navigation interne Narrative Studio V0 :
   - widget : `NarrativeStudioSidebar`;
   - entrées actives : `Aperçu`, `Storylines`, `Scènes`, `Cinématiques`, `Dialogues`;
   - entrées disabled : `Facts`, `Règles du monde`, `Validateur`;
   - `Maps` absent.

2. Navigation locale de l'ancien Global Story Studio :
   - widget : `GlobalStoryStudioTopBar`;
   - libellés visibles : `Studio narratif`, `Histoire globale`, `Global Story`;
   - actions visibles : `Réinitialiser`, `Tester`, `Valider`, `+ Nouvelle étape`;
   - panel gauche local : `GlobalStoryNavPanel`.

Cette superposition explique la confusion observée dans le screenshot : l'écran dit à la fois `Storylines`, `Global Story Workspace`, `Global Story`, `Histoire globale`, `Structure`, `Votre récit`, `Progression globale`.

### Panneau Structure

Le panneau `STRUCTURE / Votre récit` est rendu par :

```text
GlobalStoryNavPanel
```

Il affiche les chapitres et steps issus du `GlobalStoryStudioDocument` et du `StepStudioDocument`.

### Canvas central

Le canvas central `FIL NARRATIF / Progression globale` est rendu par :

```text
GlobalStoryFlowPanel
```

Il s'appuie sur :

```text
buildGlobalStoryFlowBlocks(...)
```

Ce n'est pas encore le graph macro de la cible. C'est une représentation linéaire / structurée de steps avec embranchements limités.

### Inspecteur droit

L'inspecteur droit `DÉTAIL DE L'ÉTAPE` est rendu par :

```text
GlobalStoryStepDetailPanel
```

Il inspecte une step, pas une storyline. La cible Graph demande plutôt un inspecteur `Détails de la storyline`. La cible Chapitres demande un inspecteur `Détails du chapitre`.

### Éléments hardcodés ou génériques dans l'UI actuelle

Éléments de vocabulaire / fallback dans le code :

- `Global Story Workspace`;
- `Global Story`;
- `Aucun Global Story`;
- `Le produit fonctionne avec un scenario global unique...`;
- `_defaultChapterId = 'chapter_main'`;
- `_defaultChapterName = 'Histoire principale'`;
- textes de shell : `STRUCTURE`, `Votre récit`, `FIL NARRATIF`, `Progression globale`, `DÉTAIL DE L'ÉTAPE`;
- actions locales : `Réinitialiser`, `Tester`, `Valider`, `+ Nouvelle étape`, `Nouveau chapitre`.

Les textes Selbrume visibles dans les screenshots ne doivent pas être copiés dans le code. Ils appartiennent à l'image cible ou à un projet de démonstration, pas au contrat métier Storylines V0.

### Éléments venant réellement du projet ou des providers

Sont réellement issus du projet / provider :

- `ProjectManifest.scenarios`;
- `ScenarioAsset.scope == ScenarioScope.globalStory`;
- `ScenarioAsset.scope == ScenarioScope.localEventFlow`;
- `ScenarioAsset.name`;
- `ScenarioAsset.description`;
- `ScenarioAsset.nodes`;
- `ScenarioAsset.edges`;
- `ScenarioAsset.metadata`;
- `ProjectManifest.dialogues`;
- `ProjectManifest.scripts`;
- `NarrativeWorkspaceProjection.globalStories`;
- `NarrativeWorkspaceProjection.localEventFlows`;
- `NarrativeWorkspaceProjection.steps`;
- `NarrativeWorkspaceProjection.dialogues`;
- `NarrativeWorkspaceState.selectedGlobalStoryId`;
- `NarrativeWorkspaceState.selectedStepId`;
- `NarrativeWorkspaceState.selectedCutsceneId`.

## 4. Current narrative data model

### Global Story

`Global Story` existe surtout comme :

- workspace : `EditorWorkspaceMode.globalStory`;
- scénario core : `ScenarioAsset` avec `scope == ScenarioScope.globalStory`;
- document d'authoring metadata : `GlobalStoryStudioDocument`;
- écran UI : `GlobalStoryStudioWorkspace`.

Le code documente explicitement qu'il n'y a aujourd'hui qu'un seul scénario global pour le jeu. Cela ne correspond pas encore à la cible qui montre une liste de storylines principales, quêtes annexes, tutoriel, épilogue, etc.

### Storyline

`Storyline` n'existe pas comme modèle métier core riche.

Présences actuelles :

- libellé UI `Storylines` dans `NarrativeStudioSidebar`;
- `storylineChoices` dans `GlobalStoryStudioShell`, avec commentaire indiquant que c'est souvent un seul item aujourd'hui ;
- concept produit implicite autour de `ScenarioAsset(scope: globalStory)`.

Absences :

- pas de `StorylineAsset`;
- pas de type `main / side quest / tutorial / epilogue`;
- pas de statut éditorial de storyline ;
- pas de priorité storyline ;
- pas de tags storyline ;
- pas de lien formalisé storyline ↔ quêtes annexes ;
- pas de liste de storylines persistée comme telle.

### Chapter

`Chapter` existe dans l'authoring editor via :

```text
GlobalStoryChapter
```

Il est stocké dans `GlobalStoryStudioDocument.chapters`, lui-même persisté dans `ScenarioAsset.metadata['authoring.globalStoryStudioDocument']`.

Ce n'est pas encore un modèle `map_core` public dédié. C'est un document d'authoring editor.

### Story Step

`Story Step` existe via :

```text
StepStudioStep
```

Il est stocké dans `StepStudioDocument`, lui-même persisté dans `ScenarioAsset.metadata['authoring.stepStudioDocument']`.

Il contient des éléments utiles :

- `id`;
- `name`;
- `description`;
- `order`;
- `activation`;
- `completion`;
- `cutscenes`;
- `outcomes`;
- `worldChanges`;
- annotations auteur / flow labels.

Mais il ne suffit pas à afficher toutes les données cible : tags, activité récente, validation globale, graph multi-storylines, relations quêtes, facts modifiés.

### ScenarioAsset

`ScenarioAsset` couvre une partie importante du besoin :

- `id`;
- `name`;
- `description`;
- `scope`;
- `entryNodeId`;
- `declaredOutcomes`;
- `activationCondition`;
- `nodes`;
- `edges`;
- `metadata`.

`ScenarioScope` sépare :

- `globalStory` : progression centrale ;
- `localEventFlow` : hooks monde locaux / cutscenes.

C'est une base réelle, mais pas encore un modèle Storyline auteur au sens de la cible.

### ScriptAsset et dialogues

`ScriptAsset` couvre les scripts / dialogues au niveau projet, et `ProjectManifest` contient :

- `dialogueFolders`;
- `dialogues`;
- `scripts`.

Le lien vers Storylines est encore partiel. On peut compter ou référencer des dialogues selon les projections existantes, mais on ne peut pas encore afficher honnêtement les détails riches de la cible sans read model dédié.

### Scene

`Scene` n'existe pas comme modèle distinct stabilisé dans le sens de la cible. Le vocabulaire actuel mélange :

- steps narratives ;
- cutscenes / local event flows ;
- scripts / dialogues ;
- scènes dans la cible UI.

Il faut clarifier dans NS-STORYLINES-01 si `Scènes` signifie :

- steps narratives ;
- cutscenes ;
- scènes auteur transversales ;
- ou un read model composite.

### Cutscene

`Cutscene` est reliée à :

- `ScenarioAsset(scope: localEventFlow)`;
- `StepStudioCutsceneLink`;
- workspace `EditorWorkspaceMode.cutscene`;
- `CutsceneStudioWorkspace`.

La distinction `step != cutscene` est déjà documentée dans `StepStudioCutsceneRole` et dans les commentaires du Global Story Studio.

### Facts et World Rules

Il n'y a pas encore de workspace Facts / World Rules réel branché dans le Narrative Studio.

Éléments partiels :

- `ScriptCondition`;
- `ScriptConditionFactory.flagIsSet`;
- outcomes de step avec scope `world`;
- `StepStudioWorldChange`;
- règles de présence liées à des steps ;
- `narrative_validator` dans `map_core` pour certains diagnostics.

Mais :

- pas de modèle `Fact` auteur stabilisé ;
- pas de modèle `WorldRule` auteur complet ;
- pas de liste de facts modifiés par storyline ;
- pas d'écran Facts / World Rules actif ;
- pas de validation globale UI honnête.

### GameState

`GameState` est une donnée runtime. Il ne doit pas devenir la source de vérité de l'éditeur Storylines. Les informations comme `completedStepIds`, `completedCutsceneIds` ou `storyFlags` peuvent aider le runtime / debug, mais ne doivent pas piloter la page d'authoring Storylines V0.

## 5. Current data availability matrix

| Target UI data | Current source | Status | Safe for V0? | Notes |
|---|---|---:|---|---|
| Liste de storylines | `ProjectManifest.scenarios.where(scope == globalStory)` + `storylineChoices` local | Partial | no, sauf read-only prudent | Le code vise un scénario global unique ; la cible montre plusieurs storylines / quêtes. |
| Type de storyline : principale / quête annexe / tutoriel / épilogue | Aucun modèle dédié | Missing | no | À définir dans un contrat Storylines, pas à inférer depuis le titre. |
| Titre de storyline | `ScenarioAsset.name` | Available | yes | Peut alimenter un header read-only. |
| Description de storyline | `ScenarioAsset.description` | Available | yes | Peut alimenter l'inspecteur si non vide. |
| Statut Active / Défini / Brouillon / En cours | Pas de statut storyline ; quelques statuts overview / chapter ailleurs | Partial | no | Ne pas afficher `Active` ou `Défini` sans source dédiée. |
| Priorité | Aucun champ identifié | Missing | no | La priorité cible serait fake aujourd'hui. |
| Chapitres | `GlobalStoryStudioDocument.chapters` | Available | yes | Source editor réelle en metadata. |
| Nombre de chapitres | `GlobalStoryStudioDocument.chapters.length` | Derived | yes | Dérivable, à condition de gérer fallback/default honnêtement. |
| Steps / scènes associées | `StepStudioDocument.steps`, `GlobalStoryChapter.stepIds` | Partial | yes avec vocabulaire prudent | Disponible pour steps ; le mot `scènes` doit être clarifié. |
| Ordre des scènes dans un chapitre | `GlobalStoryChapter.stepIds` + `StepStudioStep.order` | Partial | yes avec prudence | Disponible pour steps ; pas forcément des scènes auteur finales. |
| Quêtes liées | Aucun modèle de quête / side storyline dédié | Missing | no | Les quêtes annexes de la cible seraient fake. |
| Dialogues liés | `ProjectManifest.dialogues`, `ProjectManifest.scripts`, éventuellement bindings scenarios | Partial | limited | Comptage / liens doivent être définis par read model, pas estimés visuellement. |
| Cutscenes liées | `StepStudioCutsceneLink`, `ScenarioAsset(scope == localEventFlow)` | Available | yes | Source réelle pour liens de steps vers cutscenes. |
| Facts modifiés | `ScriptCondition`, outcomes, flags, validators partiels | Partial | no | Trop indirect ; dangereux à présenter comme facts métier. |
| World rules affectées | `StepStudioWorldChange`, presence rules, conditions | Partial | no | Présence de règles techniques, pas de world rules produit. |
| Dernière activité | Aucun journal d'activité identifié | Missing | no | À ne pas faker. |
| Tags | Aucun champ tags storyline identifié | Missing | no | Les tags cible (`Mystère`, etc.) ne doivent pas être copiés. |
| Problèmes de validation | `computeGlobalStoryStudioDiagnostics`, `narrative_validator` partiel | Partial | yes, mais limité | Peut afficher des warnings techniques existants, pas un validateur global. |
| Graph macro | `GlobalStoryStudioDocument.nodes`, `GlobalStoryStepLink`, `buildGlobalStoryFlowBlocks` | Partial | yes, read-only limité | Base réelle, mais pas encore le graph riche de la cible avec quêtes annexes. |
| Liens entre chapitres | Dérivable indirectement depuis steps + links | Partial | limited | Pas de relation chapter-to-chapter dédiée. |
| Liens entre quêtes annexes et storyline principale | Aucun modèle | Missing | no | À concevoir. |
| Mini-map du graph | Aucun composant actuel dédié | Missing | no | Possible seulement après graph read model/layout. |
| Légende du graph | Aucun contrat cible actuel | Missing | no | Doit venir d'un design-system component + read model. |
| Contrôles de zoom | Pas pour Storylines target | Missing | no | Ne pas créer sans graph réel. |
| Tests tab | Aucun workspace Tests Storylines | Missing | no | Doit rester disabled ou absent. |
| Statistiques tab | Pas de stats storyline dédiées | Missing | no | Dérivation à spécifier. |
| Bouton Nouvelle storyline | Use cases scénario existent mais pas flow Storyline | Partial | no | Ne pas activer sans modèle + UX + validation. |
| Bouton Valider | Diagnostics partiels, pas validation globale | Partial | no | Ne pas vendre une validation globale. |
| Recherche Storylines | Aucun index/search Storylines | Missing | no | À venir. |

## 6. Target UI interpretation

### Cible 1 — Global Storyline / Graph

La cible `1 - global storyline.png` montre une surface Storylines complète :

- shell global PokeMap ;
- sidebar Narrative Studio avec `Aperçu`, `Storylines`, `Maps`, `Scènes`, `Cinématiques`, `Dialogues`, `Facts`, `World Rules`, `Validateur` ;
- panneau secondaire `Storylines` avec recherche, histoire principale, quêtes annexes et autres ;
- breadcrumb `Narrative Studio > Storylines > Histoire globale` ;
- header `Histoire globale` avec statut et description ;
- actions hautes `Nouvelle storyline`, `Aperçu`, `Valider`, recherche, notifications, settings ;
- onglets `Graph`, `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` ;
- KPI cards ;
- grand graph macro ;
- quêtes annexes rattachées visuellement ;
- mini-map ;
- légende ;
- contrôles de zoom ;
- inspecteur droit `Détails de la storyline` ;
- tags ;
- world rules affectées ;
- dernière activité.

Interprétation prudente : c'est une direction UX forte, mais elle suppose des données et contrats que le repo ne possède pas encore pleinement.

### Cible 2 — Chapitres

La cible `2 - chapitres.png` montre :

- le même shell global ;
- le même panneau secondaire Storylines ;
- onglet `Chapitres` actif ;
- liste de chapitres ordonnée ;
- chapitre sélectionné ;
- scènes du chapitre ;
- recherche / filtre / tri ;
- bouton `Nouveau chapitre` ;
- inspecteur `Détails du chapitre` ;
- ordre des scènes ;
- contenu lié ;
- statut éditorial.

Interprétation prudente : cette cible est plus proche des données actuelles que la cible Graph, car `GlobalStoryStudioDocument.chapters` et `StepStudioDocument.steps` existent déjà. Mais il manque encore le statut éditorial fiable, les scènes comme concept cible, les dialogues liés et l'inspecteur chapter dédié.

### Contraintes design system

Les futures implémentations doivent :

- utiliser les composants PokeMap existants (`EditorPaneSurface`, `EditorSidebarListRow`, `EditorToolbarIconButton`, helpers `EditorChrome`, tokens `PokeMapColorTokens`, `context.pokeMapColors`) ;
- créer ou étendre des composants design-system si une primitive manque ;
- éviter les couleurs hardcodées dans les features ;
- éviter un clone pixel-perfect local de l'image cible ;
- préserver les états disabled honnêtes.

## 7. Current UI → Target UI gap analysis

| Zone | Current UI | Target UI | Gap | Sévérité | Décision |
|---|---|---|---|---|---|
| Layout général | Shell moderne autour d'une ancienne surface Global Story, grand vide central | Surface dense avec secondaire Storylines, graph, inspector storyline | Refonte du contenu Storylines nécessaire | à corriger avant chantier UI | Commencer par read model. |
| Top bar globale | PokeMap global chrome existant | Cible plus premium, mais même rôle | Pas bloquant | acceptable V0 | Ne pas toucher dans Storylines-00. |
| Sidebar principale | `NarrativeStudioSidebar` interne sans `Maps` | Cible affiche `Maps` | Tension produit | décision requise | Garder architecture propre ; voir section 8. |
| Project Explorer global | Réductible depuis NS-HOME | Cible ne montre pas de large Project Explorer | OK pour V0 | acceptable V0 | Ne pas transformer en sidebar Storylines. |
| Sidebar Storylines secondaire | Absente comme panneau moderne ; seul `GlobalStoryNavPanel` structure chapters/steps | Liste storylines + quêtes + recherche | Manquante | à corriger | Lot secondaire list panel après data contract. |
| Header Storyline | `Global Story Workspace`, puis header interne `Narrative Studio / Section : Storylines` | `Histoire globale`, statut, description, breadcrumb clair | Redondant et ancien | à corriger | Header Storylines dédié. |
| Onglets | Aucun vrai tab Graph/Chapitres/Étapes/Scènes/Stats/Tests | Tabs clairs | Manquant | à corriger | À créer read-only après contrat. |
| KPI cards | Absentes dans Global Story | 5 KPI Storyline | Données partiellement absentes | à corriger prudemment | KPI read-only seulement si sources réelles. |
| Graph canvas | `GlobalStoryFlowPanel` linéaire / très vide | Graph macro riche avec nodes, quêtes annexes, branches | Gros écart | à corriger | Graph placeholder/read-only basé sur données réelles, pas fake. |
| Mini-map | Absente | Présente | Manquante | report après graph | Pas avant graph layout réel. |
| Légende | Absente | Présente | Manquante | report après graph | Lier à types de nodes réels. |
| Zoom controls | Absents | Présents | Manquants | report après graph | Ne pas ajouter sans canvas zoomable. |
| Inspector droit | Inspecteur de step | Inspecteur de storyline ou chapitre | Mauvais niveau d'objet | à corriger | Dédier un inspector Storyline puis Chapter. |
| Onglet Chapitres | Ancien panneau structure gauche | Liste centrale de chapitres avec scènes | Données proches mais UI absente | lot dédié | Bon candidat après shell/list/header. |
| États vides | Texte technique `Aucun Global Story`, `Chargez un projet...` | Empty states produit | Rugueux | à corriger | Design-system empty states. |
| Actions | `Réinitialiser`, `Tester`, `Valider`, `+ Nouvelle étape` locales | `Nouvelle storyline`, `Valider`, filtres, recherche | Actuellement trop mutateur pour refonte read-only | à sécuriser | V0 read-only ; actions futures disabled. |
| Disabled states | Partiels, `Tester` disabled, NS sidebar disabled | Cible montre actions actives mais V0 doit être honnête | Risque de fausse promesse | critique | Garder disabled tant que modèle absent. |
| Données Selbrume | Visibles dans cible et screenshot | Données produit cible | À ne pas copier | critique | Fixtures seulement si explicitement dédiées et nommées comme telles. |

## 8. Sidebar architecture tension

### Tension observée

NS-HOME a établi :

```text
ProjectExplorerPanel = sidebar globale PokeMap
NarrativeStudioSidebar = sidebar interne Narrative Studio
```

Et Karim a ensuite confirmé que `Maps` ne servait pas dans la sidebar interne de la page Overview. `Maps` a donc été retiré de `NarrativeStudioSidebar`.

Les nouvelles images Storylines montrent pourtant `Maps` dans la navigation de gauche, avec les autres entrées Narrative Studio.

### Interprétations possibles

1. L'image cible mélange volontairement navigation globale et navigation Narrative Studio.
2. L'image cible utilise une sidebar produit finale unifiée qui n'est pas encore tranchée côté architecture.
3. `Maps` y signifie non pas le Project Explorer global, mais une future surface narrative de cartes liées.
4. `Maps` est un reste visuel du template et ne doit pas être réintroduit.

### Recommandation

Ne pas réintroduire `Maps` dans `NarrativeStudioSidebar` sans décision produit explicite.

Préserver la séparation :

```text
ProjectExplorerPanel / global PokeMap
→ cartes, assets globaux, projet, catalogues

NarrativeStudioSidebar / interne Narrative Studio
→ Aperçu, Storylines, Scènes, Cinématiques, Dialogues, Facts, World Rules, Validateur
```

Si Storylines doit montrer des cartes, le bon vocabulaire V0 serait plutôt :

- `Lieux liés`;
- `Cartes liées`;
- `Handoff vers Maps`;
- ou une section dans l'inspecteur Storyline / Chapter.

Et non une entrée interne `Maps` active qui ferait croire à un workspace narratif Maps final.

Décision recommandée pour NS-STORYLINES-01 : documenter explicitement si `Maps` reste global ou devient une destination narrative. En attendant, garder `Maps` absent de la sidebar interne et mentionner la tension dans le data contract.

## 9. What must stay read-only in V0

Pour les premiers lots Storylines, doivent rester read-only ou disabled :

- création de storyline ;
- création de quête annexe ;
- validation globale ;
- recherche globale Storylines ;
- notifications ;
- settings narratifs ;
- graph macro interactif si les relations ne sont pas modélisées ;
- tags ;
- facts modifiés ;
- world rules affectées ;
- activité récente ;
- statistiques globales ;
- tests ;
- édition des liens entre quêtes annexes et storyline principale ;
- édition de statuts éditoriaux si aucun modèle dédié n'existe ;
- affichage de priorité si aucun champ dédié n'existe.

Même si l'ancien `GlobalStoryStudioWorkspace` contient déjà des actions mutatrices (`+ Nouvelle étape`, `Nouveau chapitre`, `Valider`), la refonte Storylines ne doit pas activer de nouvelles surfaces produit tant que le modèle et les tests ne sont pas définis.

## 10. What would be fake if implemented now

Seraient fake ou dangereux si implémentés maintenant :

- une liste de storylines multiples copiée de l'image cible ;
- les noms Selbrume / Histoire globale / Le port / Les marais / Le phare hardcodés ;
- les chiffres 5 / 27 / 412 / 18 / 3 copiés de la cible ;
- les quêtes annexes `Les cristaux de sel`, `Le Goélise du port`, `La cabane du phare` ;
- les tags `Mystère`, `Exploration`, `Phare`, `Côtiers` ;
- le statut `Active` sans champ source ;
- la priorité `Haute` sans champ source ;
- les world rules affectées ;
- l'activité récente ;
- les badges de notifications ;
- un vrai bouton `Nouvelle storyline`;
- un vrai bouton `Valider`;
- un graph interactif de quêtes annexes si les liens ne sont pas persistés ;
- un onglet `Tests` actif ;
- un onglet `Statistiques` actif sans contrat de métriques ;
- une entrée `Maps` dans la sidebar interne sans décision produit.

## 11. Recommended Storylines implementation roadmap

Roadmap courte recommandée, limitée aux fondations Storylines V0 :

### NS-STORYLINES-01 — Storylines Read Model / Data Contract V0

Objectif :

- définir un read model Storylines V0 ;
- mapper chaque champ cible vers `Available`, `Derived`, `Partial`, `Missing`, `Fake risk` ;
- décider du vocabulaire `Storyline`, `Chapter`, `Step`, `Scene`, `Quest`, `Map`.

Non-objectifs :

- pas d'UI cible ;
- pas de nouveau modèle core ;
- pas de fake data.

### NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0

Objectif :

- verrouiller le comportement actuel avant remplacement ;
- prouver que `GlobalStoryStudioWorkspace` reste accessible ;
- prouver que les données réelles viennent du manifest / metadata.

Non-objectifs :

- pas de refonte visuelle.

### NS-STORYLINES-03 — Storylines Workspace Shell Layout V0

Objectif :

- introduire le layout cible interne : panneau secondaire Storylines + main area + inspector ;
- garder les actions futures disabled ;
- utiliser uniquement le design system PokeMap.

Non-objectifs :

- pas de graph riche ;
- pas de création de storyline.

### NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0

Objectif :

- afficher une liste read-only basée sur le read model ;
- distinguer `Histoire principale` réelle et placeholders disabled si données absentes ;
- ne pas afficher de quêtes annexes fake.

### NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0

Objectif :

- créer header Storyline V0 ;
- tabs `Graph` / `Chapitres` read-only ;
- KPI uniquement si source réelle ou dérivée ;
- tabs `Statistiques` / `Tests` disabled ou absents.

### NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0

Objectif :

- remplacer le grand vide central par un graph read-only honnête ;
- utiliser `GlobalStoryStudioDocument.nodes` / links si présents ;
- afficher empty state design-system si trop peu de données.

Non-objectifs :

- pas de mini-map / zoom si le graph n'est pas encore un vrai canvas.

### NS-STORYLINES-07 — Storyline Inspector Read-only V0

Objectif :

- inspecteur de storyline basé sur `ScenarioAsset` + read model ;
- sections disabled pour tags, world rules, activity si absentes ;
- aucune donnée cible hardcodée.

### NS-STORYLINES-08 — Chapters Tab Read-only V0

Objectif :

- exploiter `GlobalStoryStudioDocument.chapters` et `StepStudioDocument.steps` ;
- afficher une liste de chapitres et steps/scènes en read-only ;
- inspector chapitre V0.

### NS-STORYLINES-09 — Target Visual Harmonization / Visual Gate V0

Objectif :

- harmoniser contre les deux images cibles ;
- produire screenshots desktop/focus/medium ;
- vérifier design-system, disabled states et absence de fake data.

Cette roadmap reste volontairement courte. Elle évite de lancer Facts / World Rules / Validateur ou une création de storyline avant contrat de données.

## 12. Recommended next lot

Prochain lot recommandé :

```text
NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
```

Justification :

- la cible UI dépend de données qui ne sont pas encore clairement disponibles ;
- l'écran actuel contient déjà un document macro, mais il n'est pas équivalent à un modèle `Storyline` produit ;
- les risques de fake sont élevés si on commence par l'UI ;
- il faut décider officiellement ce que `Scènes`, `Quêtes annexes`, `Facts`, `World Rules`, `Maps`, `Statistiques` et `Tests` signifient en V0 ;
- il faut préserver le design system dès la première ligne de UI future.

## 13. Risks and guardrails

### Risques principaux

- Copier les données Selbrume de la cible dans le code.
- Hardcoder les chiffres de la cible.
- Faire croire que les relations de graph existent déjà.
- Mélanger `Storyline` et `ScenarioAsset`.
- Mélanger `Story Step`, `Scene` et `Cutscene`.
- Utiliser `GameState` runtime comme source d'authoring.
- Réintroduire une architecture confuse de sidebars.
- Activer `Nouvelle storyline` sans vrai flow.
- Activer `Valider` sans validateur global.
- Ajouter `Maps` dans la sidebar interne sans décision produit.
- Créer des composants visuels hors design system pour aller vite.

### Garde-fous

- Préserver `ProjectExplorerPanel` comme global.
- Préserver `NarrativeStudioSidebar` comme interne.
- Garder `Maps` absent tant qu'aucune décision produit n'est prise.
- Garder Facts / World Rules / Validateur disabled tant que les modèles / flows manquent.
- Ne pas utiliser les images cibles comme source métier.
- Ne pas faire de pixel-perfect.
- Ne pas créer de données fake.
- Utiliser exclusivement les primitives et tokens du design system PokeMap, ou étendre le design system avant toute primitive nouvelle.
- Démarrer par un read model auditable.

## 14. Evidence Pack

### Commandes de lecture exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
rg -n "..." AGENTS.md agent_rules.md skills/README.md reports/narrativeStudio/ui/*.md
rg -n "..." packages/map_editor packages/map_core
file "<screenshots>"
stat -f '%Sm %z' "<screenshots>"
find reports/narrativeStudio/storylines -maxdepth 2 -type f -print
```

Aucun test n'a été lancé : le lot est audit-only et ne modifie pas de code.

### Git status initial exact

```text
 M packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
 M packages/map_editor/lib/src/theme/pokemap_macos_compatibility_bridge.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/test/design_system_guardrail_test.dart
 M packages/map_editor/test/theme/pokemap_theme_test.dart
```

### Git branch initial

```text
main
```

### Git diff --stat initial

```text
 .../lib/src/theme/pokemap_color_tokens.dart        | 168 ++++++-----
 .../theme/pokemap_macos_compatibility_bridge.dart  |  16 +-
 .../src/ui/shared/cupertino_editor_widgets.dart    |  52 ++--
 .../test/design_system_guardrail_test.dart         | 322 +++++++++++++++++++--
 .../map_editor/test/theme/pokemap_theme_test.dart  |  42 ++-
 5 files changed, 451 insertions(+), 149 deletions(-)
```

### Git diff --name-only initial

```text
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/theme/pokemap_macos_compatibility_bridge.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/test/design_system_guardrail_test.dart
packages/map_editor/test/theme/pokemap_theme_test.dart
```

### Git diff --check initial

```text

```

### Screenshots inspectés

```text
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/TemporaryItems/NSIRD_screencaptureui_lCmuXG/Screenshot 2026-05-27 at 22.11.51.png
/Users/karim/Desktop/assets/pokeMap/définitive/1 - storyline/1 - global storyline.png
/Users/karim/Desktop/assets/pokeMap/définitive/1 - storyline/2 - chapitres.png
```

Metadata :

```text
Screenshot 2026-05-27 at 22.11.51.png: PNG image data, 1920 x 1080, 8-bit/color RGBA, non-interlaced
1 - global storyline.png: PNG image data, 1672 x 941, 8-bit/color RGB, non-interlaced
2 - chapitres.png: PNG image data, 1672 x 941, 8-bit/color RGB, non-interlaced
```

### Fichiers créés

```text
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
```

Le dossier `reports/narrativeStudio/storylines/` n'existait pas avant ce lot.

### Fichiers de code modifiés par ce lot

```text
Aucun.
```

### Tests modifiés par ce lot

```text
Aucun.
```

### Widgets créés par ce lot

```text
Aucun.
```

### Modèles métier modifiés par ce lot

```text
Aucun.
```

### map_core / runtime / gameplay / battle modifiés par ce lot

```text
Aucun.
```

### Git status final exact

```text
?? reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
```

### Git diff --stat final

```text

```

Note : `git diff --stat` ne liste pas les fichiers non trackés. Le rapport créé est donc compensé par la ligne `git status final` ci-dessus et par le contenu complet du présent fichier.

### Git diff --name-only final

```text

```

Note : `git diff --name-only` ne liste pas les fichiers non trackés.

### Git diff --check final

```text

```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est le présent fichier, de la section 1 à la section 15. Il n'y a pas d'annexe externe. Une copie intégrale imbriquée du même fichier créerait une auto-référence récursive et n'ajouterait pas d'information auditable.

## 15. Self-review

Checklist critique :

- aucun code de production n'a été modifié ;
- aucun test n'a été modifié ;
- aucun widget n'a été créé ;
- aucun modèle métier n'a été ajouté ;
- le widget actuel responsable de l'écran a été identifié : `GlobalStoryStudioWorkspace` / `GlobalStoryStudioShell` ;
- la navigation interne et l'ancienne navigation locale ont été distinguées ;
- les données réelles (`ScenarioAsset`, `StepStudioDocument`, `GlobalStoryStudioDocument`, projection narrative) ont été séparées des données cible absentes ;
- la tension `Maps` a été documentée sans décision de code ;
- le besoin design system a été rappelé comme garde-fou strict ;
- la roadmap recommandée reste courte et commence par un read model ;
- aucun test n'a été lancé, conformément au caractère audit-only.

Limite de l'audit :

- je n'ai pas exécuté l'application ni produit de nouveau screenshot ; les images fournies et les screenshots existants suffisent pour ce lot audit-only ;
- certaines données visibles dans le screenshot actuel peuvent venir du projet chargé localement, mais le présent audit ne lit pas les fichiers projet sur disque et ne doit pas les transformer en contrat produit ;
- le rapport ne tranche pas définitivement la question `Maps`, il recommande une décision produit explicite dans NS-STORYLINES-01.
