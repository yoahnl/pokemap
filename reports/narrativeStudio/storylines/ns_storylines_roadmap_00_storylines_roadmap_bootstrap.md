# NS-STORYLINES-ROADMAP-00 — Storylines Roadmap Bootstrap V0

## 1. Executive summary

Lot exécuté :

```text
NS-STORYLINES-ROADMAP-00 — Storylines Roadmap Bootstrap V0
```

Résultat :

- création de `reports/narrativeStudio/storylines/road_map_storylines.md` ;
- création du présent rapport bootstrap ;
- aucune modification de code ;
- aucun widget créé ;
- aucun modèle ajouté ;
- aucun test modifié ;
- aucun test/analyze lancé, conformément au périmètre documentation-only ;
- Design System Gate strict ajouté ;
- prochain lot recommandé : `NS-STORYLINES-01 — Storylines Read Model / Data Contract V0`.

Le worktree était non clean avant ce lot. Les changements préexistants sont documentés et n'ont pas été modifiés.

## 2. Inputs read

Fichiers obligatoires lus :

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md
reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md
```

Fichiers optionnels / équivalents inspectés :

```text
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
```

Fichiers demandés mais absents au chemin exact :

```text
packages/map_editor/lib/src/ui/shared/pokemap_tone.dart
packages/map_editor/lib/src/ui/shared/pokemap_dashboard_primitives.dart
```

Équivalents trouvés :

```text
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
```

Skill consulté :

```text
superpowers:writing-plans
```

Adaptation : le skill recommande par défaut `docs/superpowers/plans`, mais la demande utilisateur impose `reports/narrativeStudio/storylines/`. La demande utilisateur prime.

## 3. Roadmap file created

Fichier créé :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Rôle :

- fichier vivant de référence pour les futurs lots Storylines ;
- source de vérité du découpage V0 ;
- garde-fou anti-fake-data ;
- garde-fou design system ;
- protocole de mise à jour obligatoire.

## 4. Roadmap structure

La roadmap contient :

```text
# Narrative Studio Storylines Roadmap

## 1. Purpose
## 2. Canonical context
## 3. Non-negotiable guardrails
## 4. Design System Guardrails
## 5. Current state summary
## 6. Target state summary
## 7. Data readiness summary
## 8. Roadmap overview
## 9. Detailed lots
## 10. Update protocol for every future lot
## 11. Definition of Done
## 12. Open decisions
## 13. Current status
## 14. Changelog
```

Lots inclus :

```text
NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0
NS-STORYLINES-03 — Storylines Workspace Shell Layout V0
NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0
NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0
NS-STORYLINES-07 — Storyline Inspector Read-only V0
NS-STORYLINES-08 — Chapters Tab Read-only V0
NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0
NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0
NS-STORYLINES-11 — Storylines Interaction Wiring V0
NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint
```

## 5. Key decisions

- Démarrer par `NS-STORYLINES-01 — Storylines Read Model / Data Contract V0`.
- Ne pas commencer par une refonte UI directe.
- Garder `ProjectExplorerPanel` global.
- Garder `NarrativeStudioSidebar` interne.
- Ne pas réintroduire `Maps` dans la sidebar interne sans décision explicite.
- Traiter les cartes liées comme `Lieux liés` / `Cartes liées` dans un inspecteur futur si nécessaire.
- Ne pas activer `Nouvelle storyline`, `Valider`, recherche, notifications ou settings sans vraie logique.
- Ne pas créer de quêtes annexes, tags, facts, world rules ou activité récente fake.
- Imposer un update de la roadmap à chaque futur lot.

## 6. Design System Guardrails added

La roadmap ajoute un `Design System Gate` obligatoire :

- aucun `Color(0x...)` ajouté dans une feature ;
- aucun `Colors.*` ajouté dans une feature ;
- aucun composant générique créé localement dans Storylines ;
- primitives existantes utilisées si disponibles ;
- si une primitive manque, créer ou étendre une primitive design system avant usage feature ;
- tons via `PokeMapTone`, `PokeMapToneColors`, `context.pokeMapColors`, `PokeMapColorTokens` ou équivalent ;
- surfaces via tokens / surfaces existantes ;
- tests design-system pertinents si impact UI / thème ;
- mini audit design system dans chaque rapport UI.

Primitives vérifiées avant citation :

```text
PokeMapColorTokens
PokeMapTheme
EditorChrome
EditorPaneSurface
EditorSidebarSectionTitle
EditorSidebarListRow
EditorHorizontalDivider
EditorVerticalDivider
EditorToolbarIconButton
EditorVisualTokens
PokeMapTone
PokeMapToneColors
PokeMapPageSurface
PokeMapIconTile
PokeMapMetricCard
PokeMapModuleCard
PokeMapStatusTile
PokeMapInspectorPanel
PokeMapSegmentedTab
PokeMapSegmentedTabs
```

Note : `PokeMapTone` et les primitives dashboard sont présentes dans le worktree local sous `packages/map_editor/lib/src/ui/design_system/` au moment du bootstrap, mais elles apparaissent comme changements préexistants. Les futurs lots doivent revérifier leur statut avant usage.

## 7. Git / worktree handling

Le worktree initial n'était pas clean.

Changements préexistants observés :

- fichiers design-system modifiés ;
- fichiers thème modifiés ;
- tests design-system/thème modifiés ;
- `PokeMapTone` et `PokeMapDashboardPrimitives` présents en fichiers non trackés ;
- audit NS-STORYLINES-00 présent en fichier non tracké.

Ce lot n'a pas modifié ces fichiers.

Fichiers créés par ce lot :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_roadmap_00_storylines_roadmap_bootstrap.md
```

## 8. Next lot recommendation

Prochain lot recommandé :

```text
NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
```

Raison :

- la cible Storylines contient trop de données absentes ou partielles ;
- commencer par l'UI pousserait au fake ;
- le read model doit décider ce qui est affichable, dérivable, disabled ou hors scope ;
- il doit aussi trancher le vocabulaire Storyline / Chapter / Step / Scene / Quest / Map.

## 9. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
 M packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/design_system/design_system.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
 M packages/map_editor/test/design_system_guardrail_test.dart
 M packages/map_editor/test/theme/pokemap_theme_test.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
?? reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
```

### Git diff --stat initial

```text
 .../lib/src/theme/pokemap_color_tokens.dart        | 165 ++++++++++--
 .../lib/src/ui/canvas/narrative_studio_header.dart | 129 +++------
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 298 ++++++++-------------
 .../lib/src/ui/design_system/design_system.dart    |   4 +-
 .../lib/src/ui/design_system/pokemap_button.dart   |  37 ++-
 .../lib/src/ui/design_system/pokemap_card.dart     |   8 +-
 .../src/ui/design_system/pokemap_icon_button.dart  |  22 +-
 .../lib/src/ui/design_system/pokemap_panel.dart    |  10 +-
 .../src/ui/design_system/pokemap_sidebar_item.dart |  57 +++-
 .../ui/design_system/pokemap_toolbar_surface.dart  |   5 +-
 .../src/ui/shared/cupertino_editor_widgets.dart    |  91 +++----
 .../lib/src/ui/shared/editor_visual_tokens.dart    |  24 +-
 .../test/design_system_guardrail_test.dart         |  94 ++++++-
 .../map_editor/test/theme/pokemap_theme_test.dart  |  19 +-
 14 files changed, 529 insertions(+), 434 deletions(-)
```

### Git diff --name-only initial

```text
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
packages/map_editor/test/design_system_guardrail_test.dart
packages/map_editor/test/theme/pokemap_theme_test.dart
```

### Git diff --check initial

```text

```

### Git status final exact

```text
 M packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/design_system/design_system.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
 M packages/map_editor/test/design_system_guardrail_test.dart
 M packages/map_editor/test/theme/pokemap_theme_test.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
?? reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
?? reports/narrativeStudio/storylines/ns_storylines_roadmap_00_storylines_roadmap_bootstrap.md
?? reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --stat final

```text
 .../lib/src/theme/pokemap_color_tokens.dart        | 167 ++++++++++--
 .../lib/src/ui/canvas/narrative_studio_header.dart | 128 ++-------
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 297 ++++++++-------------
 .../lib/src/ui/design_system/design_system.dart    |   4 +-
 .../lib/src/ui/design_system/pokemap_button.dart   |  37 ++-
 .../lib/src/ui/design_system/pokemap_card.dart     |   8 +-
 .../src/ui/design_system/pokemap_icon_button.dart  |  22 +-
 .../lib/src/ui/design_system/pokemap_panel.dart    |  10 +-
 .../src/ui/design_system/pokemap_sidebar_item.dart |  57 +++-
 .../ui/design_system/pokemap_toolbar_surface.dart  |   5 +-
 .../src/ui/shared/cupertino_editor_widgets.dart    |  91 +++----
 .../lib/src/ui/shared/editor_visual_tokens.dart    |  24 +-
 .../test/design_system_guardrail_test.dart         |  94 ++++++-
 .../map_editor/test/theme/pokemap_theme_test.dart  |  19 +-
 14 files changed, 528 insertions(+), 435 deletions(-)
```

Note : les deux fichiers créés par ce lot sont non trackés ; `git diff --stat` ne les liste pas.

### Git diff --name-only final

```text
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
packages/map_editor/test/design_system_guardrail_test.dart
packages/map_editor/test/theme/pokemap_theme_test.dart
```

Note : `git diff --name-only` ne liste pas les fichiers non trackés. Les fichiers créés par ce lot sont listés dans `git status final`.

### Git diff --check final

```text

```

### Contenu complet de road_map_storylines.md

````markdown
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
| NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | TODO | NS-STORYLINES-02 |
| NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | TODO | NS-STORYLINES-03 |
| NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | TODO | NS-STORYLINES-04 |
| NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | TODO | NS-STORYLINES-05 |
| NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | TODO | NS-STORYLINES-06 |
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
- Statut : TODO.
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
- Statut : TODO.
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
- Statut : TODO.
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
- Statut : TODO.
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
- Statut : TODO.
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
Roadmap status: BOOTSTRAPPED
Current lot: NS-STORYLINES-ROADMAP-00
Current lot status: DONE
Next recommended lot: NS-STORYLINES-01 — Storylines Read Model / Data Contract V0
```

| Lot | Status | Last update | Notes |
|---|---|---|---|
| NS-STORYLINES-00 | DONE | 2026-05-27 | Audit actuel/cible produit. |
| NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
| NS-STORYLINES-01 | TODO | 2026-05-27 | Prochain lot recommandé. |
| NS-STORYLINES-02 | TODO | 2026-05-27 | À lancer après data contract. |
| NS-STORYLINES-03 | TODO | 2026-05-27 | UI shell après contrat/tests. |
| NS-STORYLINES-04 | TODO | 2026-05-27 | Secondary list read-only. |
| NS-STORYLINES-05 | TODO | 2026-05-27 | Header/tabs/KPI read-only. |
| NS-STORYLINES-06 | TODO | 2026-05-27 | Graph read-only placeholder. |
| NS-STORYLINES-07 | TODO | 2026-05-27 | Inspector storyline. |
| NS-STORYLINES-08 | TODO | 2026-05-27 | Chapters tab. |
| NS-STORYLINES-09 | TODO | 2026-05-27 | Chapters inspector/order. |
| NS-STORYLINES-10 | TODO | 2026-05-27 | Visual harmonization. |
| NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
| NS-STORYLINES-CHECKPOINT | TODO | 2026-05-27 | Acceptance checkpoint. |

## 14. Changelog

### 2026-05-27 — NS-STORYLINES-ROADMAP-00

- Création de la roadmap Storylines.
- Ajout des garde-fous design system.
- Ajout du Design System Gate obligatoire.
- Ajout des lots Storylines V0 de `NS-STORYLINES-01` à `NS-STORYLINES-CHECKPOINT`.
- Ajout du protocole de mise à jour obligatoire pour les futurs lots.
- Documentation de la tension `Maps` / sidebar.
- Prochain lot recommandé : `NS-STORYLINES-01 — Storylines Read Model / Data Contract V0`.
````

### Contenu complet du rapport créé

Le rapport créé est le présent fichier. Une auto-inclusion intégrale récursive rendrait le document infini ; le contenu complet auditable est donc ce fichier lui-même, avec le contenu complet de `road_map_storylines.md` reproduit ci-dessus.

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md
reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
```

### Liste des fichiers absents mais attendus

```text
packages/map_editor/lib/src/ui/shared/pokemap_tone.dart
packages/map_editor/lib/src/ui/shared/pokemap_dashboard_primitives.dart
```

### Tests / analyze

```text
Non lancés : documentation-only, aucun code modifié.
```

## 10. Self-review

Checklist critique :

- seuls deux fichiers Markdown ont été créés par ce lot ;
- aucun fichier de code n'a été modifié par ce lot ;
- aucun test n'a été modifié par ce lot ;
- aucun widget n'a été créé ;
- aucun modèle n'a été ajouté ;
- la roadmap impose sa mise à jour à chaque futur lot ;
- le Design System Gate est strict ;
- les couleurs hardcodées sont interdites dans les features ;
- les composants UI hors design system sont interdits ;
- la tension `Maps` / sidebar est documentée ;
- les données fake de la cible sont interdites ;
- le prochain lot recommandé est clair ;
- le worktree non clean initial est documenté comme préexistant.

Limite :

- `PokeMapTone` et `PokeMapDashboardPrimitives` existent dans le worktree local mais sont non trackés au moment de ce rapport ; la roadmap demande donc aux futurs lots de revérifier leur statut avant usage.
