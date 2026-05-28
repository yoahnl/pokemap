# NS-STORYLINES-01 — Storylines Read Model / Data Contract V0

## 1. Executive summary

Lot exécuté :

```text
NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
```

Verdict court :

- Storylines V0 ne doit pas introduire un modèle métier `Storyline` maintenant.
- La source honnête actuelle est `ScenarioAsset(scope == globalStory)`, enrichie par `GlobalStoryStudioDocument`, `StepStudioDocument` et `NarrativeWorkspaceProjection`.
- Une Storyline principale read-only peut être affichée en V0 si elle est présentée comme une projection auteur du scénario global existant.
- Les chapitres sont utilisables via `GlobalStoryChapter`, mais leurs statuts éditoriaux, tags, priorités et activités restent absents.
- Les steps sont utilisables comme `Étapes narratives`. Les appeler `Scènes` serait ambigu sauf si la UI précise que ce sont des étapes issues de Step Studio.
- Les cutscenes liées sont disponibles via `StepStudioCutsceneLink`; les dialogues liés restent partiels car ils demandent un mapping fiable via scripts, dialogues ou bindings.
- Les quêtes annexes, tags, world rules, facts, activité récente, priorité et graph riche multi-storylines sont `Missing` ou `Fake risk`.
- Le prochain lot recommandé reste `NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0`.

Ce rapport ne crée aucune classe, aucun widget, aucun provider et aucun test. Il définit seulement le contrat de données conceptuel qui devra guider les lots UI suivants.

## 2. Inputs read

### Gouvernance et rapports

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_roadmap_00_storylines_roadmap_bootstrap.md`
- `reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`

### Code audité en lecture seule

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`

### Primitives design system inspectées

- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`

### Fichiers attendus mais absents

Aucun fichier obligatoire de la section NS-STORYLINES-01 n'a été constaté absent pendant l'audit de ce lot.

## 3. Current model interpretation

### Source actuelle principale

La source actuelle la plus proche d'une storyline est :

```text
ProjectManifest.scenarios
→ ScenarioAsset(scope == ScenarioScope.globalStory)
```

`ScenarioAsset` fournit :

- `id` : Available, `Display in V0` uniquement comme identifiant interne ou source technique masquée.
- `name` : Available, `Display in V0` comme titre auteur.
- `description` : Available, `Display in V0` si non vide ; fallback empty state sinon.
- `scope` : Available, `Display in V0` sous forme de type prudent, par exemple `Storyline principale`.
- `entryNodeId` : Available, `Hide in V0` sauf diagnostic technique.
- `declaredOutcomes` : Available, `Disable in V0` pour les KPI riches ; exploitable plus tard pour conditions / conséquences.
- `activationCondition` : Partial, `Hide in V0` pour Storylines ; ce n'est pas un statut éditorial.
- `nodes` / `edges` : Available, `Postpone` pour un graph runtime ; ne pas confondre avec le graph auteur Storylines cible.
- `metadata` : Available, `Display in V0` uniquement via documents authoring typés déjà connus.

### Source authoring macro

`GlobalStoryStudioDocument` est stocké dans `ScenarioAsset.metadata` :

```text
authoring.globalStoryStudioSchema
authoring.globalStoryStudioDocument
```

Il fournit :

- `globalStoryScenarioId` : Available, `Hide in V0`.
- `entryStepId` : Available, `Display in V0` comme noeud d'entrée si la step existe.
- `nodes` : Available, `Display in V0` pour un graph V0 prudent.
- `chapters` : Available, `Display in V0` pour l'onglet Chapitres.
- diagnostics de normalisation : Derived, `Display in V0` seulement comme avertissements existants, pas comme validation globale.

### Source authoring step

`StepStudioDocument` est stocké dans `ScenarioAsset.metadata` :

```text
authoring.stepStudioSchema
authoring.stepStudioDocument
```

Il fournit :

- `StepStudioStep.id` : Available, `Display in V0`.
- `StepStudioStep.name` : Available, `Display in V0`.
- `StepStudioStep.description` : Available, `Display in V0` si non vide.
- `StepStudioStep.order` : Available, `Display in V0`.
- `activation` / `completion` : Available, `Display in V0` comme résumé prudent.
- `cutscenes` : Available, `Display in V0` en tant que liens vers cutscenes.
- `outcomes` : Available, `Display in V0` comme conséquences ou résultats, pas comme facts validés.
- `worldChanges` : Partial, `Disable in V0` pour `World Rules`; afficher éventuellement un compteur technique plus tard sans l'appeler règle du monde.
- `flow*Label` : Partial, `Display in V0` uniquement comme notes auteur, pas comme logique exécutable.

### Projection narrative existante

`NarrativeWorkspaceProjection` consolide déjà :

- `globalStories` : Available, `Display in V0`.
- `localEventFlows` : Available, `Postpone` pour quêtes annexes.
- `steps` : Available, `Display in V0`.
- `outcomes` : Derived, `Display in V0` avec prudence.
- `scenarioById` : Available, `Hide in V0` sauf usage interne.

Cette projection est read-only et correspond bien au principe de contrat V0.

## 4. Product vocabulary decisions

### Storyline

Décision V0 :

```text
Storyline V0 = projection read-only d'un ScenarioAsset globalStory.
```

On ne crée pas de `StorylineAsset` dans ce lot. Un futur `StorylineAsset` peut rester une décision V1 si plusieurs storylines, quêtes annexes riches, types, priorités, tags, activity log ou statuts éditoriaux deviennent nécessaires.

Nom UI recommandé :

- `Storylines` pour l'espace de travail.
- `Storyline principale` ou `Histoire principale` pour le type de la source `globalStory`.
- Le titre affiché doit venir de `ScenarioAsset.name`, jamais d'un hardcode cible.

Afficher une seule storyline principale en V0 est honnête si la UI indique clairement qu'elle vient de l'histoire globale existante et que les storylines secondaires sont `Disable in V0` ou absentes.

### Chapter

Décision V0 :

```text
Chapter V0 = GlobalStoryChapter.
```

Champs fiables :

- `id` : Available, `Hide in V0`.
- `name` : Available, `Display in V0`.
- `description` : Available, `Display in V0` si non vide.
- `stepIds` : Available, `Display in V0` pour compter et ordonner les steps.
- `order` : Available, `Display in V0`.

Champs absents :

- statut éditorial : Missing, `Disable in V0`.
- owner / priorité : Missing, `Hide in V0`.
- tags : Missing, `Hide in V0`.
- activité récente : Missing, `Hide in V0`.

### Step vs Scene

Décision V0 :

```text
Step = Étape narrative.
Scene = terme UI cible à éviter tant que le mapping n'est pas vrai.
```

`StepStudioStep` n'est pas une scène cinématique ni une scène de map. C'est une étape de progression auteur. Le wording recommandé est :

- `Étapes` ou `Étapes narratives` dans Storylines V0.
- `Scènes liées` seulement pour des cutscenes ou scripts effectivement liés.
- Si un libellé cible impose `Scènes`, ajouter un sous-libellé du type `Étapes narratives issues de Step Studio`.

### Quêtes annexes

Décision V0 :

```text
Quêtes annexes = Missing pour Storylines V0.
```

`ScenarioAsset(scope == localEventFlow)` ne suffit pas à prouver une quête annexe. Un local event flow peut être un hook local, une scène, un script ou une condition de monde. L'afficher comme quête annexe serait `Fake risk`.

### KPI

KPI V0 autorisés :

- chapitres : Available via `GlobalStoryStudioDocument.chapters`.
- étapes narratives : Available via `StepStudioDocument.steps` ou `NarrativeWorkspaceProjection.steps`.
- cutscenes liées : Available via `StepStudioCutsceneLink`.
- diagnostics existants : Derived via `computeGlobalStoryStudioDiagnostics`, seulement comme avertissements structurels.
- outcomes / conséquences : Derived via projection, uniquement avec wording prudent.

KPI V0 interdits ou disabled :

- scènes liées si ce chiffre mélange steps, cutscenes et scripts : Fake risk.
- dialogues lignes : Partial, `Disable in V0` tant que le lien exact n'est pas prouvé.
- facts modifiés : Fake risk.
- world rules affectées : Fake risk.
- problèmes de validation globale : Fake risk sauf diagnostics locaux existants.
- quêtes liées : Missing.

### Graph

Décision V0 :

```text
Graph V0 = représentation read-only du GlobalStoryStudioDocument normalisé.
```

Il ne doit pas prétendre être le graph riche de l'image cible. Il peut afficher :

- un noeud d'entrée dérivé de `entryStepId`.
- des noeuds step depuis `GlobalStoryStepNode`.
- des edges depuis `GlobalStoryStepLink`.
- un fallback linéaire si le document normalisé le produit.
- un empty state honnête si aucune step n'existe.

Mini-map, zoom controls, graph multi-storylines, quêtes annexes rattachées et légende riche sont `Postpone`.

### Inspector

Décision V0 :

L'inspecteur Storyline V0 peut afficher :

- titre : Available.
- description : Available.
- type prudent `Storyline principale` : Derived.
- nombre de chapitres : Derived.
- nombre d'étapes : Derived.
- nombre de cutscenes liées : Derived.
- diagnostics structurels existants : Derived.

Il doit cacher ou désactiver :

- priorité : Missing.
- tags : Missing.
- world rules : Fake risk.
- facts : Fake risk.
- activité récente : Missing.
- quêtes liées : Missing.

## 5. Storylines V0 data contract

Règle centrale :

```text
Le read model Storylines V0 est une projection read-only du projet existant.
Il ne crée pas de vérité métier nouvelle.
```

### Données affichables en V0

| Data | Source | Availability | V0 decision | Fallback honnête |
|---|---|---|---|---|
| Titre storyline | `ScenarioAsset.name` | Available | Display in V0 | Afficher l'id seulement si name vide, avec style technique discret |
| Description storyline | `ScenarioAsset.description` | Available | Display in V0 | Empty state `Description non renseignée` |
| Type storyline principale | `ScenarioScope.globalStory` | Derived | Display in V0 | `Storyline principale` |
| Liste storylines principales | `projection.globalStories` | Available | Display in V0 | Empty state si aucune |
| Chapitres | `GlobalStoryStudioDocument.chapters` | Available | Display in V0 | Chapitre par défaut normalisé si document legacy |
| Étapes | `StepStudioDocument.steps` | Available | Display in V0 | Empty state si aucune |
| Liens macro | `GlobalStoryStepNode.links` | Available | Display in V0 | Fallback linéaire normalisé |
| Cutscenes liées | `StepStudioStep.cutscenes` | Available | Display in V0 | 0 liée |
| Outcomes | `StepStudioStep.outcomes` / projection outcomes | Available | Display in V0 | Section `Conséquences` prudente |
| Diagnostics structurels | `computeGlobalStoryStudioDiagnostics` | Derived | Display in V0 | Pas de validation globale |

### Données à désactiver ou cacher

| Data | Source | Availability | V0 decision | Pourquoi |
|---|---|---|---|---|
| Nouvelle storyline | Aucun flow fiable | Missing | Disable in V0 | Créerait une donnée sans modèle dédié |
| Quêtes annexes | Aucun modèle Quest | Missing | Hide in V0 | `localEventFlow` n'est pas une quête |
| Tags storyline | Aucun champ Storyline tag | Missing | Hide in V0 | Copier la cible serait fake |
| Priorité | Aucun champ | Missing | Hide in V0 | Pas de vérité métier |
| Statut Active / Brouillon | Aucun statut éditorial Storyline | Missing | Disable in V0 | Ne pas inventer `Active` |
| Facts modifiés | Pas de modèle Fact | Fake risk | Disable in V0 | Outcomes et worldChanges ne sont pas des facts |
| World rules affectées | Pas de modèle WorldRule | Fake risk | Disable in V0 | `worldChanges` est partiel |
| Activité récente | Pas d'event log | Missing | Hide in V0 | Ne pas simuler |
| Validation globale | Pas de validator global branché | Fake risk | Disable in V0 | Diagnostics locaux seulement |
| Notifications | Pas de source fiable | Missing | Disable in V0 | Aucun badge |

## 6. Read model object contracts

### Data contract object matrix

| Read model object | Purpose | Fields | Source | Safe for V0? | Notes |
|---|---|---|---|---|---|
| `StorylinesWorkspaceReadModel` | État global de l'espace Storylines read-only | `projectName` (Available, Display in V0), `storylines` (Available, Display in V0), `selectedStorylineId` (Derived, Display in V0), `selectedTab` (Derived, Display in V0), `disabledFeatures` (Derived, Display in V0), `emptyState` (Derived, Display in V0) | `ProjectManifest`, projection narrative | yes | Ne contient pas de mutation ni de provider global nouveau. |
| `StorylineSummaryReadModel` | Ligne du panneau secondaire | `id` (Available, Hide in V0), `title` (Available, Display in V0), `description` (Available, Display in V0), `kindLabel` (Derived, Display in V0), `chapterCount` (Derived, Display in V0), `stepCount` (Derived, Display in V0), `statusLabel` (Missing, Disable in V0), `isSelected` (Derived, Display in V0) | `ScenarioAsset`, `GlobalStoryStudioDocument` | yes | `statusLabel` ne doit pas afficher `Active` tant qu'aucune source n'existe. |
| `StorylineDetailReadModel` | Détail principal de la storyline | `title` (Available, Display in V0), `description` (Available, Display in V0), `sourceScenarioId` (Available, Hide in V0), `chapters` (Available, Display in V0), `steps` (Available, Display in V0), `kpis` (Derived, Display in V0), `graph` (Derived, Display in V0), `inspector` (Derived, Display in V0) | `ScenarioAsset`, documents authoring | yes | Source technique masquée par défaut. |
| `StorylineChapterReadModel` | Chapitre / arc narratif | `id` (Available, Hide in V0), `title` (Available, Display in V0), `description` (Available, Display in V0), `order` (Available, Display in V0), `stepIds` (Available, Hide in V0), `stepCount` (Derived, Display in V0), `statusLabel` (Missing, Disable in V0) | `GlobalStoryChapter` | yes | Pas de statut éditorial fake. |
| `StorylineStepReadModel` | Étape narrative dans graph / chapitre | `id` (Available, Hide in V0), `title` (Available, Display in V0), `description` (Available, Display in V0), `order` (Available, Display in V0), `activationSummary` (Available, Display in V0), `completionSummary` (Available, Display in V0), `linkedCutsceneIds` (Available, Display in V0), `outcomes` (Available, Display in V0), `worldChangeCount` (Partial, Disable in V0) | `StepStudioStep`, `NarrativeStepSummary` | yes | Ne pas appeler cette entité une scène sans clarification. |
| `StorylineKpiReadModel` | KPI read-only | `chapterCount` (Derived, Display in V0), `stepCount` (Derived, Display in V0), `linkedCutsceneCount` (Derived, Display in V0), `dialogueCount` (Partial, Disable in V0), `diagnosticCount` (Derived, Display in V0), `factsCount` (Fake risk, Disable in V0) | Documents authoring, projection | yes | Les KPI disabled doivent rester visibles comme non branchés ou absents. |
| `StorylineGraphReadModel` | Graph macro prudent | `nodes` (Derived, Display in V0), `edges` (Derived, Display in V0), `entryNodeId` (Available, Display in V0), `emptyState` (Derived, Display in V0), `legend` (Derived, Display in V0), `minimap` (Missing, Postpone), `zoom` (Missing, Postpone) | `GlobalStoryStudioDocument`, `StepStudioDocument` | yes | Graph read-only, pas de canvas riche fake. |
| `StorylineGraphNodeReadModel` | Noeud graph V0 | `id` (Available, Hide in V0), `label` (Available, Display in V0), `description` (Available, Display in V0), `kind` (Derived, Display in V0), `chapterId` (Derived, Display in V0), `isEntry` (Derived, Display in V0), `status` (Missing, Disable in V0) | `GlobalStoryStepNode`, `StepStudioStep`, chapters | yes | `kind` limité à `entry`, `step`, `missingStepNotice`. |
| `StorylineGraphEdgeReadModel` | Lien graph V0 | `fromNodeId` (Available, Hide in V0), `toNodeId` (Available, Hide in V0), `label` (Partial, Display in V0), `edgeKind` (Derived, Display in V0), `requiredOutcomeId` (Partial, Display in V0) | `GlobalStoryStepLink`, exit mode | yes | Label optionnel ; ne pas inventer un type de branche riche. |
| `StorylineInspectorReadModel` | Panneau droit | `title` (Available, Display in V0), `description` (Available, Display in V0), `typeLabel` (Derived, Display in V0), `chapterCount` (Derived, Display in V0), `stepCount` (Derived, Display in V0), `cutsceneCount` (Derived, Display in V0), `diagnostics` (Derived, Display in V0), `tags` (Missing, Hide in V0), `worldRules` (Fake risk, Disable in V0), `recentActivity` (Missing, Hide in V0) | Détail storyline | yes | Inspector read-only. |
| `StorylinesDisabledFeatureReadModel` | Contrat des actions futures | `featureId` (Derived, Display in V0), `label` (Derived, Display in V0), `reason` (Derived, Display in V0), `state` (Derived, Display in V0) | Décisions produit V0 | yes | Centralise les raisons disabled sans activer. |

### Champs clefs par objet

#### `StorylinesWorkspaceReadModel`

- Objectif : fournir tout le nécessaire à l'espace Storylines sans lire `EditorNotifier` depuis les cards.
- Champs proposés : `projectName`, `storylines`, `selectedStorylineId`, `selectedTab`, `disabledFeatures`, `hasAnyStoryline`, `emptyState`.
- Sources actuelles : `ProjectManifest.name`, `NarrativeWorkspaceProjection.globalStories`, état workspace narratif existant.
- Safe V0 : oui.
- Fake : onglets `Tests`, `Statistiques`, recherche active, nouvelle storyline active.

#### `StorylineSummaryReadModel`

- Objectif : alimenter le panneau secondaire Storylines.
- Champs proposés : `id`, `title`, `description`, `kindLabel`, `chapterCount`, `stepCount`, `isSelected`, `disabledReason`.
- Sources actuelles : `NarrativeScenarioSummary`, `GlobalStoryStudioDocument`.
- Safe V0 : oui.
- Fake : quêtes annexes listées depuis `localEventFlow` sans modèle de quête.

#### `StorylineDetailReadModel`

- Objectif : alimenter l'écran principal d'une storyline.
- Champs proposés : `summary`, `kpis`, `chapters`, `steps`, `graph`, `inspector`, `diagnostics`, `disabledFeatures`.
- Sources actuelles : `ScenarioAsset`, `StepStudioDocument`, `GlobalStoryStudioDocument`.
- Safe V0 : oui.
- Fake : tags, priorité, world rules, activité.

#### `StorylineChapterReadModel`

- Objectif : afficher l'onglet Chapitres et les regroupements du graph.
- Champs proposés : `id`, `title`, `description`, `order`, `stepIds`, `stepCount`, `steps`.
- Sources actuelles : `GlobalStoryChapter`, `StepStudioStep`.
- Safe V0 : oui.
- Fake : statut `Défini`, owner, dates.

#### `StorylineStepReadModel`

- Objectif : afficher une étape narrative dans graph, chapitre ou inspector.
- Champs proposés : `id`, `title`, `description`, `order`, `activationLabel`, `completionLabel`, `linkedCutscenes`, `outcomes`, `authorNotes`.
- Sources actuelles : `StepStudioStep`, `NarrativeStepSummary`.
- Safe V0 : oui avec wording `Étape`.
- Fake : scène de map, scène cinématique, activité runtime.

#### `StorylineKpiReadModel`

- Objectif : fournir des KPI read-only honnêtes.
- Champs proposés : `label`, `value`, `availability`, `decision`, `disabledReason`.
- Sources actuelles : documents authoring et diagnostics.
- Safe V0 : oui si chaque KPI porte sa source.
- Fake : reprendre les chiffres de l'image cible.

#### `StorylineGraphReadModel`

- Objectif : représenter le graph macro sans inventer de relations.
- Champs proposés : `nodes`, `edges`, `entryNodeId`, `emptyState`, `warnings`, `legendItems`.
- Sources actuelles : `GlobalStoryStudioDocument`, `StepStudioDocument`.
- Safe V0 : oui read-only.
- Fake : mini-map active, zoom complexe, side quests raccordées.

#### `StorylineGraphNodeReadModel`

- Objectif : rendre chaque step sous forme de noeud.
- Champs proposés : `id`, `label`, `description`, `kind`, `chapterId`, `isEntry`, `linkedCutsceneCount`, `warning`.
- Sources actuelles : `GlobalStoryStepNode`, `StepStudioStep`, chapters.
- Safe V0 : oui.
- Fake : statut éditorial, priorité.

#### `StorylineGraphEdgeReadModel`

- Objectif : rendre les transitions macro existantes.
- Champs proposés : `fromStepId`, `toStepId`, `label`, `requiredOutcomeId`, `kind`, `isConditional`.
- Sources actuelles : `GlobalStoryStepLink`, `GlobalStoryStepExitMode`.
- Safe V0 : oui.
- Fake : relations quêtes annexes ou liens `optional` non encodés.

#### `StorylineInspectorReadModel`

- Objectif : panneau droit read-only de la storyline sélectionnée.
- Champs proposés : `title`, `description`, `typeLabel`, `counts`, `diagnostics`, `disabledSections`.
- Sources actuelles : détail storyline et documents.
- Safe V0 : oui.
- Fake : tags, world rules, activité récente.

#### `StorylinesDisabledFeatureReadModel`

- Objectif : expliquer les actions non branchées.
- Champs proposés : `featureId`, `label`, `reason`, `decision`.
- Sources actuelles : décisions V0 locales au read model.
- Safe V0 : oui.
- Fake : badge notification, validation globale.

## 7. Source mapping matrix

| Target concept | Proposed V0 field | Current source | Availability | V0 decision | Notes |
|---|---|---|---|---|---|
| Storyline title | `title` | `ScenarioAsset.name` | Available | Display in V0 | Titre projet, pas hardcode cible. |
| Storyline description | `description` | `ScenarioAsset.description` | Available | Display in V0 | Empty state si vide. |
| Storyline type | `kindLabel` | `ScenarioScope.globalStory` | Derived | Display in V0 | `Storyline principale` prudent. |
| Storyline list | `storylines` | `NarrativeWorkspaceProjection.globalStories` | Available | Display in V0 | Peut contenir une seule entrée. |
| Secondary quests | `sideStorylines` | Aucun modèle Quest | Missing | Hide in V0 | Ne pas dériver de `localEventFlow`. |
| Chapter title | `chapter.title` | `GlobalStoryChapter.name` | Available | Display in V0 | Chapitre par défaut possible via normalisation. |
| Chapter description | `chapter.description` | `GlobalStoryChapter.description` | Available | Display in V0 | Empty state si vide. |
| Chapter order | `chapter.order` | `GlobalStoryChapter.order` | Available | Display in V0 | Stable pour read-only. |
| Chapter steps | `chapter.steps` | `GlobalStoryChapter.stepIds` + `StepStudioStep` | Available | Display in V0 | Ordre actuel exploitable. |
| Step title | `step.title` | `StepStudioStep.name` | Available | Display in V0 | Wording `Étape narrative`. |
| Step description | `step.description` | `StepStudioStep.description` | Available | Display in V0 | Empty state si vide. |
| Scene count | `sceneCount` | Ambigu entre steps/cutscenes/scripts | Fake risk | Disable in V0 | Préférer `Étapes`. |
| Linked cutscenes | `linkedCutsceneCount` | `StepStudioStep.cutscenes` | Available | Display in V0 | Comptage par ids liés. |
| Dialogue count | `dialogueCount` | `ProjectManifest.dialogues`, scripts, bindings | Partial | Disable in V0 | Mapping exact à prouver. |
| Facts modified | `factsCount` | Aucun modèle Fact | Fake risk | Disable in V0 | Ne pas confondre outcomes. |
| World rules affected | `worldRules` | `StepStudioWorldChange` partiel | Partial | Disable in V0 | `WorldChange` n'est pas une rule. |
| Validation issues | `diagnosticCount` | `computeGlobalStoryStudioDiagnostics` | Derived | Display in V0 | Diagnostics structurels seulement. |
| Global validation | `validationStatus` | Aucun flow global branché | Missing | Disable in V0 | Pas de statut `À jour`. |
| Tags | `tags` | Aucun champ Storyline tag | Missing | Hide in V0 | Fake si copié depuis cible. |
| Priority | `priority` | Aucun champ | Missing | Hide in V0 | Fake si affiché. |
| Recent activity | `activity` | Aucun event log | Missing | Hide in V0 | Future source nécessaire. |
| Graph nodes | `graph.nodes` | `GlobalStoryStepNode` + `StepStudioStep` | Available | Display in V0 | Read-only. |
| Graph edges | `graph.edges` | `GlobalStoryStepLink` | Available | Display in V0 | Fallback linéaire normalisé. |
| Graph mini-map | `graph.minimap` | Aucun composant/data contract | Missing | Postpone | Après graph UI réel. |
| Zoom controls | `graph.zoomControls` | Aucun contrat V0 | Missing | Postpone | Pas nécessaire au read-only V0. |
| Map links | `relatedMaps` | `StepStudioWorldChange.mapId`, conditions map | Partial | Hide in V0 | Future `Cartes liées`, pas sidebar. |

## 8. UI field matrix

| UI area | Field | Source | Availability | V0 display rule | Fake risk |
|---|---|---|---|---|---|
| Storylines panel | Liste principale | `projection.globalStories` | Available | Display in V0 | Non si titre vient du scénario. |
| Storylines panel | Quêtes annexes | Aucun modèle Quest | Missing | Hide in V0 | Oui. |
| Storylines panel | Recherche | Aucun moteur recherche Storylines | Missing | Disable in V0 | Oui si champ actif. |
| Header | Titre storyline | `ScenarioAsset.name` | Available | Display in V0 | Non. |
| Header | Badge Active | Aucun statut éditorial | Missing | Disable in V0 | Oui. |
| Header | Nouvelle storyline | Aucun flow | Missing | Disable in V0 | Oui si actif. |
| Header | Valider | Pas de validation globale | Missing | Disable in V0 | Oui si actif. |
| Tabs | Graph | `GlobalStoryStudioDocument` | Available | Display in V0 | Non si read-only. |
| Tabs | Chapitres | `GlobalStoryChapter` | Available | Display in V0 | Non. |
| Tabs | Étapes | `StepStudioStep` | Available | Display in V0 | Non. |
| Tabs | Scènes | Mapping ambigu | Partial | Disable in V0 | Oui si alias de step. |
| Tabs | Statistiques | KPI limité | Partial | Disable in V0 | Oui si riche. |
| Tabs | Tests | Aucun runner test Storylines | Missing | Disable in V0 | Oui. |
| KPI | Chapitres | `chapters.length` | Derived | Display in V0 | Non. |
| KPI | Étapes | `steps.length` | Derived | Display in V0 | Non. |
| KPI | Cutscenes liées | `step.cutscenes` | Derived | Display in V0 | Non. |
| KPI | Dialogues | dialogues/scripts/bindings | Partial | Disable in V0 | Oui sans preuve. |
| KPI | Facts | Aucun Fact | Fake risk | Disable in V0 | Oui. |
| KPI | Problèmes | Diagnostics locaux | Derived | Display in V0 | Non si libellé `Avertissements structurels`. |
| Graph | Noeuds step | `GlobalStoryStepNode` | Available | Display in V0 | Non. |
| Graph | Quêtes annexes | Aucun modèle | Missing | Hide in V0 | Oui. |
| Graph | Légende simple | Types V0 dérivés | Derived | Display in V0 | Non. |
| Graph | Mini-map | Aucun contrat | Missing | Postpone | Oui si décorative. |
| Inspector | Détails storyline | `StorylineDetailReadModel` | Derived | Display in V0 | Non. |
| Inspector | Tags | Aucun champ | Missing | Hide in V0 | Oui. |
| Inspector | World rules | Aucun modèle | Fake risk | Disable in V0 | Oui. |
| Inspector | Activité récente | Aucun log | Missing | Hide in V0 | Oui. |
| Chapters tab | Liste chapitres | `GlobalStoryChapter` | Available | Display in V0 | Non. |
| Chapters tab | Ordre des steps | `chapter.stepIds` | Available | Display in V0 | Non. |
| Chapters tab | Statut éditorial | Aucun champ | Missing | Disable in V0 | Oui. |

## 9. Disabled / future feature matrix

| Feature | Why not V0 | Recommended state | Future dependency |
|---|---|---|---|
| Nouvelle storyline | Pas de `StorylineAsset`, pas de flow création fiable | Disable in V0 | Décision modèle + use case création |
| Quêtes annexes | Aucun modèle Quest ou side-storyline | Hide in V0 | Modèle quête/storyline secondaire |
| Recherche Storylines | Aucun index ni flow recherche | Disable in V0 | Search read model / UX |
| Validation globale | Diagnostics locaux seulement | Disable in V0 | Validator narratif global |
| Notifications | Aucune source fiable | Disable in V0 | Event log / notification center |
| Tags | Aucun champ Storyline tag | Hide in V0 | Modèle tags narratifs |
| Priorité | Aucun champ | Hide in V0 | Décision produit priorité |
| Statut Active / Draft | Aucun statut éditorial | Disable in V0 | Statut auteur persistant |
| Facts | Aucun modèle Fact | Disable in V0 | Fact workspace / model |
| World Rules | Aucun modèle WorldRule | Disable in V0 | World Rules workspace / model |
| Activité récente | Aucun journal | Hide in V0 | Activity log editor |
| Mini-map graph | Pas de graph UI contract | Postpone | Graph component stable |
| Zoom graph | Pas nécessaire au placeholder read-only | Postpone | Graph canvas interactif |
| Maps dans sidebar interne | Décision NS-HOME inverse | Hide in V0 | Décision produit explicite |

## 10. Graph V0 contract

### Objectif

Le graph V0 doit montrer la structure macro existante sans donner l'impression que les relations riches de la cible existent déjà.

### Node types autorisés

| Node type | Source | Availability | V0 decision | Notes |
|---|---|---|---|---|
| `entry` | `entryStepId` + step correspondante | Derived | Display in V0 | Variante visuelle du noeud step d'entrée. |
| `step` | `GlobalStoryStepNode.stepId` + `StepStudioStep` | Available | Display in V0 | Noeud principal V0. |
| `missingStepNotice` | diagnostics si référence cassée | Derived | Display in V0 | Avertissement, pas une donnée métier. |
| `sideQuest` | Aucun modèle | Missing | Hide in V0 | Fake risk. |
| `chapterGroup` | `GlobalStoryChapter` | Derived | Display in V0 | Groupe visuel read-only possible. |

### Edge types autorisés

| Edge type | Source | Availability | V0 decision | Notes |
|---|---|---|---|---|
| `linear` | lien normalisé / exit mode | Derived | Display in V0 | Fallback honnête. |
| `conditional` | `GlobalStoryStepLink.requiredOutcomeId` ou `conditionLabel` | Partial | Display in V0 | Libellé prudent si présent. |
| `branchExclusive` | `GlobalStoryStepExitMode.branchExclusive` | Available | Display in V0 | Read-only. |
| `branchConditional` | `GlobalStoryStepExitMode.branchConditional` | Available | Display in V0 | Read-only. |
| `converge` | `GlobalStoryStepExitMode.converge` | Available | Display in V0 | Read-only. |
| `sideQuestAttachment` | Aucun modèle | Missing | Hide in V0 | Fake risk. |

### Empty state

Si aucune step n'existe :

- afficher une surface vide honnête ;
- expliquer que l'histoire globale n'a pas encore d'étape narrative ;
- garder `Nouvelle storyline` disabled ;
- ne pas générer un faux graph.

### Mini-map et zoom

Décision :

```text
mini-map = Postpone
zoom controls = Postpone
```

Ces éléments pourront être ajoutés quand le composant graph read-only sera réel. Les dessiner sans interaction ni besoin serait décoratif et risquerait de copier la cible sans contrat.

## 11. Chapters V0 contract

### Champs affichables

| Field | Source | Availability | V0 decision | Fallback |
|---|---|---|---|---|
| Chapter id | `GlobalStoryChapter.id` | Available | Hide in V0 | Usage interne |
| Title | `GlobalStoryChapter.name` | Available | Display in V0 | `Chapitre sans titre` seulement comme fallback UI |
| Description | `GlobalStoryChapter.description` | Available | Display in V0 | Empty state |
| Order | `GlobalStoryChapter.order` | Available | Display in V0 | Trier par ordre |
| Step ids | `GlobalStoryChapter.stepIds` | Available | Hide in V0 | Usage mapping |
| Step count | `stepIds.length` | Derived | Display in V0 | 0 autorisé |
| Step rows | `StepStudioStep` par id | Available | Display in V0 | Missing step warning si incohérence |

### Champs non affichables

| Field | Availability | V0 decision | Reason |
|---|---|---|---|
| Editorial status | Missing | Disable in V0 | Pas de champ source. |
| Priority | Missing | Hide in V0 | Pas de vérité métier. |
| Tags | Missing | Hide in V0 | Fake risk. |
| Recent edits | Missing | Hide in V0 | Pas d'activity log. |
| Linked side quests | Missing | Hide in V0 | Pas de modèle Quest. |

### Wording recommandé

Utiliser `Chapitres` pour `GlobalStoryChapter`.

Utiliser `Étapes narratives` pour les rows issues de `StepStudioStep`.

Éviter `Scènes du chapitre` tant que `Scene` n'a pas une source fiable. Variante acceptable :

```text
Étapes du chapitre
```

ou :

```text
Étapes narratives liées
```

## 12. Inspector V0 contract

### Sections autorisées

| Section | Fields | Source | Availability | V0 decision |
|---|---|---|---|---|
| Identité | title, description, typeLabel | `ScenarioAsset`, scope | Available | Display in V0 |
| Structure | chapterCount, stepCount, entryStepLabel | documents authoring | Derived | Display in V0 |
| Liens narratifs | linkedCutsceneCount, outcomeCount | `StepStudioStep` | Derived | Display in V0 |
| Diagnostics | warning labels | `computeGlobalStoryStudioDiagnostics` | Derived | Display in V0 |
| Metadata technique | sourceScenarioId | `ScenarioAsset.id` | Available | Hide in V0 |

### Sections disabled ou absentes

| Section | Availability | V0 decision | Reason |
|---|---|---|---|
| Priorité | Missing | Hide in V0 | Aucun champ. |
| Tags | Missing | Hide in V0 | Aucun champ. |
| World rules affectées | Fake risk | Disable in V0 | Pas de modèle. |
| Facts modifiés | Fake risk | Disable in V0 | Pas de modèle. |
| Quêtes liées | Missing | Hide in V0 | Pas de modèle. |
| Dernière activité | Missing | Hide in V0 | Pas d'activity log. |
| Statut Active | Missing | Disable in V0 | Ne pas inventer un statut. |

### Règle de statut

Ne jamais afficher :

```text
Active
À jour
Validé
Brouillon
En cours
```

sauf si un champ source ou un validator réel l'établit. Pour V0, préférer :

```text
Read-only
Source : histoire globale existante
Diagnostics structurels uniquement
```

## 13. Maps / sidebar decision

Décision V0 recommandée :

```text
Maps reste absent de la sidebar interne Narrative Studio.
```

Justification :

- NS-HOME a fermé l'architecture avec `ProjectExplorerPanel = sidebar globale PokeMap`.
- NS-HOME a retiré `Maps` de `NarrativeStudioSidebar`.
- Les nouvelles images cibles montrent `Maps`, mais elles peuvent mélanger navigation globale et navigation narrative.
- Réintroduire `Maps` maintenant casserait la décision canonique sans nouveau besoin fonctionnel prouvé.

Contrat Storylines V0 :

- aucune modification de sidebar dans ce lot ;
- aucune entrée `Maps` dans le read model Storylines ;
- si des cartes liées deviennent nécessaires, les afficher plus tard comme section `Lieux liés` ou `Cartes liées` dans l'inspecteur Storyline / Chapter ;
- ne pas transformer `localEventFlow` ou `mapId` en navigation Maps globale.

## 14. Design system implications

Même si ce lot ne produit pas d'UI, les futurs lots doivent respecter le Design System Gate de la roadmap.

### Design system impact matrix

| Future UI piece | Existing primitive candidate | Missing primitive? | Recommendation |
|---|---|---|---|
| Panneau secondaire Storylines | `PokeMapPanel`, `PokeMapSidebarItem`, `EditorSidebarListRow` | no | Utiliser les rows existantes avant toute customisation. |
| Carte de storyline | `PokeMapModuleCard`, `PokeMapCard` | maybe | Si la cible demande un row-card hybride, créer une primitive design-system, pas locale. |
| Header storyline | `PokeMapPageSurface`, `PokeMapButton`, `PokeMapIconButton` | no | Réutiliser le style NS-HOME. |
| KPI cards | `PokeMapMetricCard` | no | Adapter via props, pas recréer. |
| Tabs Storyline | `PokeMapSegmentedTabs` | no | Garder les tabs disabled honnêtes. |
| Graph placeholder | `PokeMapPageSurface`, `PokeMapCard` | yes | Probable besoin futur d'une primitive `PokeMapGraphSurface` ou équivalent. |
| Graph node | Aucun node graph générique observé | yes | Créer d'abord une primitive design-system si réutilisable. |
| Inspector panel | `PokeMapInspectorPanel` | no | Réutiliser pour détails Storyline/Chapter. |
| Chapter rows | `EditorSidebarListRow`, `PokeMapCard` | maybe | Si besoin de row dense avec ordre, étendre design system. |
| Disabled sections | `PokeMapStatusTile`, `PokeMapButton` disabled | no | Messages explicites, pas de faux badge. |
| Empty states | Primitives dashboard existantes / panels | maybe | Si empty states répétés, créer primitive design-system. |

### Implications concrètes

- Aucun futur lot UI Storylines ne doit ajouter `Color(0x...)` dans une feature.
- Aucun futur lot UI Storylines ne doit ajouter `Colors.*` dans une feature.
- Les tons sémantiques doivent passer par `PokeMapTone` / tokens existants.
- Les surfaces doivent passer par `PokeMapPageSurface`, `PokeMapPanel`, `EditorChrome` ou extension design-system.
- Si le graph exige une grille, des nodes ou une mini-map, créer un lot design-system préalable ou un sous-lot explicitement scoped.

## 15. Fake-data guardrails

Interdits absolus pour les futurs lots Storylines V0 :

- hardcoder les noms de la cible ;
- hardcoder les chiffres de la cible ;
- hardcoder les tags de la cible ;
- hardcoder une activité récente ;
- afficher `Active`, `À jour`, `Validé`, `En cours` sans source ;
- transformer `localEventFlow` en quête annexe sans modèle ;
- transformer `StepStudioWorldChange` en World Rule ;
- transformer `outcome` en Fact ;
- afficher un badge notification ;
- activer `Nouvelle storyline`;
- activer `Valider`;
- réintroduire `Maps` dans la sidebar interne sans décision produit.

### Données cible explicitement non contractuelles

Les éléments suivants sont des exemples visuels, pas des données produit à coder :

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

Si une fixture de démo devient nécessaire plus tard, elle doit être :

- nommée explicitement fixture ;
- isolée du code produit ;
- testée ;
- validée par un lot dédié ;
- jamais mélangée au read model de production.

## 16. Recommended impact on roadmap

Mise à jour recommandée et appliquée à `road_map_storylines.md` :

- `NS-STORYLINES-01` passe à `DONE`.
- Résultat : contrat de données Storylines V0 documenté.
- Aucun code modifié.
- Aucun test modifié.
- Aucun test/analyze lancé, car le lot est documentation-only.
- Design System Gate confirmé.
- Fake data explicitement interdite.
- Prochain lot recommandé : `NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0`.

Impact sur les lots futurs :

- `NS-STORYLINES-02` doit caractériser les sources réelles et empêcher les régressions fake data avant tout remplacement UI.
- `NS-STORYLINES-03` ne doit démarrer l'UI shell qu'après ces tests anti-fake.
- Les lots graph / inspector / chapters doivent rester read-only jusqu'à ce que les flows de création ou validation existent.

## 17. Next lot recommendation

Prochain lot recommandé :

```text
NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0
```

Objectif recommandé :

- écrire des tests de caractérisation sur l'ancien `GlobalStoryStudioWorkspace` ;
- prouver quelles données viennent du manifest / metadata ;
- verrouiller l'absence de données cible hardcodées ;
- verrouiller les disabled states ;
- préparer le remplacement UI sans perdre le comportement existant.

Ne pas démarrer :

- UI cible Storylines ;
- graph riche ;
- création storyline ;
- validation globale ;
- modèles map_core.

## 18. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
?? packages/map_editor/lib/src/theme/pokemap_legacy_color_tokens.dart
```

Note : ce fichier non suivi était présent avant les modifications de ce lot et n'a pas été touché.

### Git diff --stat initial

```text
```

### Git diff --name-only initial

```text
```

### Git diff --check initial

```text
```

### Git status final exact

```text
 M packages/map_editor/lib/src/theme/theme.dart
 M packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/lib/src/theme/pokemap_legacy_color_tokens.dart
?? reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md
```

Note : les modifications Dart listées ci-dessus n'appartiennent pas au lot NS-STORYLINES-01. Elles sont apparues dans le worktree pendant l'exécution du lot et n'ont pas été modifiées par cette intervention. Les seuls fichiers touchés par NS-STORYLINES-01 sont le présent rapport et `road_map_storylines.md`.

### Git diff --stat final

```text
 packages/map_editor/lib/src/theme/theme.dart       |   1 +
 .../src/ui/canvas/dialogue_studio_workspace.dart   | 112 +++++-----
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 240 ++++++++++++---------
 .../ui/panels/element_collision_editor_sheet.dart  | 115 +++++-----
 .../dialogs/terrain_preset_dialogs.dart            |  34 +--
 .../lib/src/ui/panels/terrain_editor_panel.dart    |   1 +
 .../src/ui/shared/cupertino_editor_widgets.dart    | 159 +++++++-------
 .../storylines/road_map_storylines.md              |  33 ++-
 8 files changed, 376 insertions(+), 319 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport NS-STORYLINES-01 non suivi. Le rapport est listé dans `git status final`.

### Git diff --name-only final

```text
packages/map_editor/lib/src/theme/theme.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
```

### Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_roadmap_00_storylines_roadmap_bootstrap.md`
- `reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_flow_layout.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`

### Fichiers absents mais attendus

Aucun fichier obligatoire du prompt NS-STORYLINES-01 n'a été constaté absent.

### Fichiers créés

```text
reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md
```

### Fichiers modifiés

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est le présent fichier Markdown. Une auto-inclusion complète créerait une récursion artificielle ; le fichier lui-même constitue l'artefact auditable.

### Diff complet de road_map_storylines.md modifié

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 46bb55a0..d0ff9a23 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -289,7 +289,7 @@ Interprétation V0 :
 
 | Lot | Title | Type | Status | Next |
 |---|---|---|---|---|
-| NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | TODO | NS-STORYLINES-02 |
+| NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
 | NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | TODO | NS-STORYLINES-03 |
 | NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | TODO | NS-STORYLINES-04 |
 | NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | TODO | NS-STORYLINES-05 |
@@ -317,7 +317,14 @@ Interprétation V0 :
 - Visual Gate : non.
 - Risques : inférer trop de données depuis des noms ; confondre `ScenarioAsset` et `Storyline`.
 - Design system impact : rappel du gate, pas de code UI.
-- Statut : TODO.
+- Statut : DONE.
+- Résultat NS-STORYLINES-01 : contrat de données Storylines V0 documenté dans `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
+- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
+- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Code : aucun fichier Dart modifié.
+- Tests/analyze : non lancés, car lot documentation-only / no-code / no-test-change.
+- Design System Gate : confirmé pour les futurs lots UI ; aucune couleur hardcodée ajoutée.
+- Fake data : aucune donnée cible ou fixture Selbrume ajoutée ; les champs `Missing` / `Fake risk` restent disabled, cachés ou reportés.
 - Prochain lot attendu : NS-STORYLINES-02.
 
 ### NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0
@@ -612,18 +619,18 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: BOOTSTRAPPED
-Current lot: NS-STORYLINES-ROADMAP-00
+Roadmap status: ACTIVE
+Current lot: NS-STORYLINES-01
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
+Next recommended lot: NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0
 ```
 
 | Lot | Status | Last update | Notes |
 |---|---|---|---|
 | NS-STORYLINES-00 | DONE | 2026-05-27 | Audit actuel/cible produit. |
 | NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
-| NS-STORYLINES-01 | TODO | 2026-05-27 | Prochain lot recommandé. |
-| NS-STORYLINES-02 | TODO | 2026-05-27 | À lancer après data contract. |
+| NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
+| NS-STORYLINES-02 | TODO | 2026-05-27 | Prochain lot recommandé : caractérisation et anti-fake tests. |
 | NS-STORYLINES-03 | TODO | 2026-05-27 | UI shell après contrat/tests. |
 | NS-STORYLINES-04 | TODO | 2026-05-27 | Secondary list read-only. |
 | NS-STORYLINES-05 | TODO | 2026-05-27 | Header/tabs/KPI read-only. |
@@ -637,6 +644,18 @@ Next recommended lot: NS-STORYLINES-01 — Storylines Read Model / Data Contract
 
 ## 14. Changelog
 
+### 2026-05-27 — NS-STORYLINES-01
+
+- Création du contrat de données Storylines V0.
+- Clarification du mapping `Storyline = ScenarioAsset globalStory` en V0.
+- Clarification `Chapter = GlobalStoryChapter`.
+- Clarification `Step = Étape narrative` et prudence sur le terme `Scène`.
+- Documentation des KPI affichables, disabled ou fake risk.
+- Documentation du graph V0 read-only et de l'inspecteur V0.
+- Confirmation que `Maps` reste absent de la sidebar interne en V0.
+- Aucun code, test, modèle, widget ou provider modifié.
+- Prochain lot recommandé : `NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0`.
+
 ### 2026-05-27 — NS-STORYLINES-ROADMAP-00
 
 - Création de la roadmap Storylines.
```

### Justification de l'absence de tests

Aucun test n'a été lancé car ce lot est explicitement :

```text
data-contract-only
design-only
audit-driven
documentation-only
no-code
no-widget
no-model-change
no-test-change
```

`flutter test`, `dart test`, `flutter analyze` et `dart analyze` ne sont pas requis sans modification de code ou de test. `git diff --check` est requis et sera capturé final.

### Confirmation no-code

- Aucun fichier Dart modifié.
- Aucun widget créé.
- Aucun provider créé.
- Aucun repository créé.
- Aucun modèle `map_core` modifié.
- Aucun test modifié.
- Aucun fichier runtime/gameplay/battle modifié.

## 19. Self-review

Ce qui est prouvé :

- Le contrat de données V0 est fondé sur les sources existantes : `ScenarioAsset`, `GlobalStoryStudioDocument`, `StepStudioDocument`, `NarrativeWorkspaceProjection`.
- Les données affichables sont séparées des données `Missing`, `Partial` ou `Fake risk`.
- Les décisions `Storyline`, `Chapter`, `Step`, `Scene`, `Quest` et `Maps` sont documentées.
- Le graph V0, l'onglet Chapitres et l'inspecteur V0 ont des limites explicites.
- Le Design System Gate est repris pour les futurs lots UI.

Ce qui n'est pas prouvé :

- Aucun comportement runtime ou UI n'est testé dans ce lot, conformément au scope.
- Le read model n'existe pas encore en Dart.
- Les mappings de dialogues ne sont pas prouvés.
- Les futures primitives graph ne sont pas définies.

Risques restants :

- Les lots UI futurs pourraient être tentés de copier la cible visuelle avec des données fake.
- Le mot `Scènes` reste une tension produit avec `Étapes narratives`.
- Les quêtes annexes demandent une décision modèle avant d'être affichées.
- `Maps` dans la cible doit rester une décision produit, pas une régression d'architecture.

Auto-critique :

- Le contrat privilégie l'honnêteté à la richesse visuelle, ce qui peut rendre la V0 moins spectaculaire que la cible.
- C'est volontaire : l'objectif de NS-STORYLINES-01 est d'empêcher un faux cockpit premium.
