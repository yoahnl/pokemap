# P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit

## 1. Résumé exécutif

P7-01 confirme que l'éditeur PokeMap possède déjà beaucoup de matière pour un Narrative Studio moderne, mais que l'expérience créateur reste fragmentée entre plusieurs surfaces :

```text
Editor shell
Top toolbar
Project Explorer
EditorCanvasHost
NarrativeWorkspaceCanvas
Global Story Studio
Step Studio
Cutscene Studio
Dialogue Studio
Narrative Inspector / Library
Entity properties / conditional dialogue bindings
Validator / diagnostics techniques
```

Décision : P7-02 peut rester le prochain lot exact, mais il doit designer l'architecture d'information du Narrative Studio avant toute nouvelle UI. Le risque principal n'est pas l'absence de code, c'est l'empilement de studios, IDs, outcomes, flags, flow labels et diagnostics sans parcours créateur unifié.

Prochain lot exact :

```text
P7-02 — Narrative Studio Information Architecture / Creator Journey Design
```

## 2. Sources lues

Sources de gouvernance :

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_7.md
reports/roadmap/phase_7/p7_00_phase_7_roadmap_bootstrap_narrative_studio_modern_ui_scope_audit.md
reports/roadmap/phase_6/p6_checkpoint_01_selbrume_beta_slice_readiness_review.md
```

Zones lues en lecture seule :

```text
packages/map_editor/lib/**
packages/map_runtime/lib/**
examples/playable_runtime_host/lib/**
```

Surfaces UI / editor inspectées plus précisément :

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart
packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart
```

## 3. Gate 0

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
9dc21fb7 update sprites
```

Commande :

```bash
test -d "/Users/karim/Project/pokemonProject/selbrume" && echo "REPO_SELBRUME_PROJECT_PATH exists" || echo "REPO_SELBRUME_PROJECT_PATH missing"
```

Sortie :

```text
REPO_SELBRUME_PROJECT_PATH exists
```

Commande :

```bash
test -f "/Users/karim/Project/pokemonProject/selbrume/project.json" && echo "repo-local selbrume/project.json exists" || echo "repo-local selbrume/project.json missing"
```

Sortie :

```text
repo-local selbrume/project.json exists
```

Commande :

```bash
git status --short --untracked-files=all -- selbrume
```

Sortie :

```text
Sortie : <vide>
```

## 4. Inventaire Modern App Shell actuel

Structure actuelle :

```text
EditorShellPage orchestre le shell principal.
TopToolbar porte le chrome projet/workspace/actions.
ProjectExplorerPanel sert de navigation gauche dense.
EditorCanvasHost route le workspace central selon EditorWorkspaceMode.
Un panneau droit peut afficher MapInspectorPanel, TilesetPalettePanel,
NarrativeInspectorPanel ou un inspector vide selon le mode.
EditorWorkspaceController centralise une partie des transitions de workspace.
EditorState / EditorNotifier gardent le projet, le workspace actif, les erreurs,
les sélections et les opérations de sauvegarde/chargement.
```

Points forts :

```text
Le shell existe déjà.
Les workspaces sont routés par un enum explicite.
La zone narrative est déjà groupée dans NarrativeWorkspaceCanvas.
Les panels gauche/centre/droite sont déjà séparés.
Le shell sait réduire sa densité en mode narratif.
La toolbar a déjà une marque projet + workspace.
```

Douleurs observées :

```text
La navigation globale mélange world editing, catalogues, trainer, narrative,
path studio, environment studio et propriétés map.
Le panneau gauche ProjectExplorerPanel contient beaucoup de responsabilités.
Le panneau droit varie fortement selon le workspace et peut afficher un
_EmptyWorkspaceInspector.
Le routing est clair techniquement, mais pas encore exprimé comme parcours
créateur.
La toolbar expose encore des actions de map editing alors que certains
workspaces sont narratifs.
```

Décision :

```text
garder le shell comme base technique
auditer plus finement la navigation avant de remplacer le shell
designer une architecture d'information qui clarifie le passage App Shell ->
Narrative Studio -> sous-studios
```

## 5. Inventaire Narrative Studio actuel

Surfaces narratives identifiées :

```text
NarrativeWorkspaceCanvas
Global Story Studio
Step Studio
Cutscene Studio
Dialogue Studio
Narrative Library Panel
Narrative Inspector Panel
Entity conditional dialogue bindings
Narrative workspace projection
Narrative workspace providers/state
Project scenario/dialogue use cases
Pokemon project validator
```

État actuel :

```text
NarrativeWorkspaceCanvas regroupe Global Story, Step, Cutscene et Dialogue.
Global Story Studio structure l'histoire macro, chapitres et steps.
Step Studio manipule l'identité des steps, activation, cutscene links,
outcomes locaux, world changes, progression outcomes et validation.
Cutscene Studio manipule les event flows/cutscenes, nodes, source kind,
dialogues et advisories runtime.
Dialogue Studio manipule des documents Yarn via modèle, codec, validation et preview.
EntityPropertiesPanel contient les dialogues conditionnels pour les NPC.
NarrativeInspectorPanel affiche un résumé d'état narratif.
NarrativeWorkspaceProjection dérive des résumés de scénarios, steps et outcomes.
```

Points forts :

```text
Les concepts narratifs sont déjà nombreux.
Les studios dédiés existent.
Le lien Cutscene -> Dialogue existe.
Les dialogues conditionnels sont visibles dans l'inspecteur entité.
Des états vides existent : aucun projet chargé, aucun scénario global,
aucune carte, aucune entité.
Des warnings existent pour formats guidés, diagnostics et références.
```

Douleurs observées :

```text
Le Narrative Studio est fragmenté entre plusieurs workspaces.
Les labels visibles mélangent français, anglais et termes moteur.
Des termes comme local event flows, entry node, nodes, outcomeId, flowEntry,
flowValidationLabel, source_outcome ou wait_until_outcome restent proches du moteur.
L'utilisateur créateur doit comprendre le lien entre story/chapter/step,
cutscene/event, dialogue, condition, fact, world rule et outcome.
La validation existe, mais elle n'est pas encore dessinée comme une expérience
guidée dans le geste auteur.
```

Décision :

```text
ne pas remplacer ces studios
les repositionner dans une architecture Narrative Studio unifiée
designer d'abord le langage produit, la hiérarchie et le parcours créateur
```

## 6. Cartographie Shell -> Narrative Studio -> sous-studios

Cartographie fondée sur l'existant :

```text
App Shell
  -> TopToolbar
      -> marque projet
      -> workspace courant
      -> actions projet / sauvegarde / chargement / outils selon workspace
  -> ProjectExplorerPanel
      -> World Explorer
      -> Narrative Studio
      -> Environment Studio
      -> Trainer Studio
      -> catalogues et bibliothèques
  -> EditorCanvasHost
      -> MapCanvas
      -> TilesetEditorCanvas
      -> TrainerLibraryPanel
      -> PokemonCatalogsWorkspace
      -> NarrativeWorkspaceCanvas
      -> PathStudioWorkspace
      -> EnvironmentStudioWorkspace
  -> Right Inspector
      -> MapInspectorPanel
      -> TilesetPalettePanel
      -> NarrativeInspectorPanel
      -> inspector neutre pour certains workspaces

NarrativeWorkspaceCanvas
  -> Global Story Studio
      -> scénario global
      -> chapitres
      -> steps
  -> Step Studio
      -> identité step
      -> activation
      -> cutscene links
      -> local outcomes
      -> world changes
      -> progression outcomes
      -> completion / validation
  -> Cutscene Studio
      -> local event flows / cutscenes
      -> source kind
      -> nodes / entry
      -> dialogue links
      -> runtime advisories
  -> Dialogue Studio
      -> dialogues Yarn
      -> nodes
      -> validation
      -> preview
  -> Entity Properties
      -> conditional dialogues
      -> default dialogue / start node
```

Gaps à ne pas masquer :

```text
Storyline n'est pas encore une surface produit claire.
Chapter existe côté Global Story, mais doit être replacé dans un modèle mental.
Fact et World Rule existent comme concepts à cadrer, mais pas comme expérience
créateur unifiée dans le shell.
Validator et diagnostics existent, mais leur place dans le flux Narrative Studio
reste à designer.
Preview narrative globale reste à cadrer.
```

## 7. Matrice shell actuel

| Surface / fichier | Rôle actuel | Utilisateur concerné | Maturité UX | Problème observé | Décision |
|---|---|---|---|---|---|
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | Shell principal, layout gauche/centre/droite, inspector, stage header | Créateur | Moyenne | Dense, polyvalent, pas encore orienté parcours Narrative Studio | Garder et auditer en P7-02 |
| `packages/map_editor/lib/src/ui/shared/top_toolbar.dart` | Toolbar projet/workspace/actions | Créateur | Moyenne | Actions map et projet cohabitent avec workspaces narratifs | Améliorer après IA |
| `packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart` | Marque projet + workspace | Créateur | Bonne base | Ne suffit pas à expliquer le parcours | Garder |
| `packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart` | Composants d'actions toolbar | Créateur | Bonne base technique | Besoin de règles visuelles P7-06 | Garder |
| `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` | Route workspace central | Créateur | Bonne base technique | Routing technique, pas architecture produit | Garder |
| `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | Navigation gauche / explorer | Créateur | Moyenne | Beaucoup de domaines dans un seul panneau | Améliorer / restructurer |
| `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` | Inspector map | Créateur | Hors priorité narrative | Pas bloquant P7-02 | Auditer plus tard |
| `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart` | Inspector narratif | Créateur | Partielle | Résumé technique, pas encore guidance | Repositionner |
| `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart` | Bibliothèque narrative | Créateur | Partielle | États vides utiles mais surface isolée | Fusionner mentalement dans Narrative Studio |
| `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart` | Propriétés entité, dialogue conditionnel | Créateur | Partielle | Dialogues conditionnels exposés dans inspector entité | Relier au Narrative Studio |
| `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart` | Transitions de workspace | Développeur / créateur indirect | Bonne base technique | Ne porte pas de modèle mental produit | Garder |
| `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` | Enum des workspaces | Développeur / créateur indirect | Bonne base technique | Modes nombreux : map, trainer, globalStory, step, cutscene, dialogue, etc. | Garder, traduire en IA |

## 8. Matrice Narrative Studio actuel

| Surface / fichier | Concept produit | Niveau no-code | Jargon technique exposé | Lien Phase 6 | Pain point | Décision |
|---|---|---|---|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Hub Global Story / Step / Cutscene / Dialogue | Moyen | Local Event Flows, nodes, entry | P6-03 interaction / steps / scenario | Hub utile mais encore segmenté | Garder et repositionner |
| `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart` | Histoire macro, chapitres, steps | Moyen | global scenario id, fallback legacy | P6 story step | Storyline pas assez lisible | Designer IA P7-02 |
| `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart` | Step authoring | Moyen | flowEntry, flowValidationLabel, outcomes, completion | P6 completed step | Trop proche moteur | Renommer / simplifier |
| `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_focus.dart` | Focus de flow Step Studio | Moyen | localOutcome, validationEngine, flowUnlocksStepId | P6 progression | Vocabulaire hybride auteur/moteur | Repositionner |
| `packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_palette.dart` | Palette Step Studio | Bon potentiel | Cutscene link, outcome, world change | P6 interaction / outcome | Bon no-code, mais hiérarchie à clarifier | Garder |
| `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart` | Mise en scène / event flow local | Moyen | scenario, source kind, node, runtime advisory | P6 showMessage / interaction | Cutscene vs event flow à clarifier | Repositionner |
| `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart` | Composition Cutscene Studio | Moyen | nodes / commands | P6 event runtime | Besoin de preview claire | Auditer en P7-02 |
| `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart` | Dialogue authoring | Moyen/bon | Yarn, node title, start node | P6 showMessage / dialogue | Bon candidat visuel, mais relié trop faiblement aux steps | Intégrer |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart` | Codec Yarn | Technique | Yarn headers, title, body | Dialogue P6 | Non visible directement, mais source de jargon possible | Garder en interne |
| `packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart` | Validation dialogue | Technique | erreurs de structure dialogue | Validator P7 | Diagnostics à rendre créateur-friendly | Intégrer P7-05 |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | Projection scénarios/steps/outcomes | Technique | emit_outcome, source_outcome, wait_until_outcome, outcomeId | P6 outcomes / flags | Jargon moteur à ne pas exposer brut | Garder comme couche interne |
| `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart` | Dialogues conditionnels NPC | Moyen | start node, script path, not listed in project | P6 entityInteract | Fonction utile mais loin du Narrative Studio | Relier |
| `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart` | Validator projet | Technique | diagnostics | P6-07 strict pass | Pas encore workflow UX | Repositionner P7-05 |

## 9. Matrice douleurs créateur

| Douleur UX | Indice dans le code / rapport | Impact créateur | Sévérité | Lot recommandé |
|---|---|---|---|---|
| Trop de studios séparés | Modes `globalStory`, `step`, `cutscene`, `dialogue` dans `EditorWorkspaceMode` et `NarrativeWorkspaceCanvas` | Le créateur doit comprendre quand utiliser quel studio | Haute | P7-02 |
| Vocabulaire interne visible | `Local Event Flows / Cutscenes`, `nodes`, `entry`, `outcomeId`, `flowEntry`, `flowValidationLabel` | Risque de transformer l'UI no-code en éditeur moteur | Haute | P7-02 |
| IDs techniques exposés | `selectedStepId`, `selectedCutsceneId`, `globalScenarioId`, `scenario.id` | Difficulté à raisonner en termes histoire/personnage/scène | Haute | P7-02 |
| Lien event / scene / dialogue / outcome flou | Cutscene link dans Step Studio, dialogue dans Cutscene Studio, dialogue conditionnel dans EntityPropertiesPanel | Parcours auteur dispersé | Haute | P7-02 |
| Diagnostics pas intégrés au geste auteur | Validator et validation dialogue/cutscene existent séparément | Le créateur risque de découvrir les erreurs trop tard | Moyenne/haute | P7-05 |
| États vides utiles mais dispersés | Aucun projet chargé, aucun scénario global, aucune carte, aucune entité | Bon début, mais pas un onboarding Narrative Studio | Moyenne | P7-03 |
| Shell dense | EditorShellPage + ProjectExplorerPanel + Inspector + Toolbar | L'entrée Narrative Studio n'est pas assez évidente | Haute | P7-02 |
| Preview narrative encore à cadrer | Dialogue preview runner existe, mais preview globale non identifiée | Difficile de vérifier une scène/histoire sans runtime mental | Moyenne | P7-03/P7-04 |
| Mélange français/anglais | Labels comme Narrative Studio, Global Story, Local Event Flows, DIALOGUES CONDITIONNELS | Manque de langage produit cohérent | Moyenne | P7-02 |
| Runtime menus tentants mais secondaires | P7-00 les a dépriorisés | Risque de quitter la priorité Narrative Studio | Moyenne | P7-08 |

## 10. Matrice décisions pour P7-02

| Sujet à designer | Pourquoi | Entrées disponibles | Question ouverte | Preuve attendue |
|---|---|---|---|---|
| Architecture d'information Narrative Studio | Réduire la fragmentation | Global Story, Step, Cutscene, Dialogue, NarrativeWorkspaceCanvas | Un seul Studio avec onglets ou plusieurs sous-studios ? | IA textuelle validée |
| Navigation interne | Clarifier le chemin créateur | ProjectExplorerPanel, mode strip, workspace controller | Où vit Storyline / Chapter / Step ? | Cartographie navigation |
| Premier écran Narrative Studio | Créer une entrée belle et compréhensible | États vides existants, P6 golden slice | Dashboard histoire ou liste Storyline ? | Description premier écran |
| Termes produit | Masquer jargon moteur | labels existants, flow labels, outcome IDs | Quels termes afficher à Yoahn/créateur ? | Glossaire UI |
| Regroupement Storyline / Chapter / Step | Rendre l'histoire macro compréhensible | Global Story Studio, Step Studio | Storyline est-il un objet visible ? | Modèle mental cible |
| Place des Events / Scenes / Cinematics | Clarifier Cutscene vs Event Flow | Cutscene Studio, source kind, local event flows | Faut-il parler de scène, événement ou cutscene ? | Décision de vocabulaire |
| Place du Dialogue | Relier Dialogue Studio au parcours narratif | Dialogue Studio, Yarn codec, conditional dialogues | Dialogue est-il un sous-onglet ou un asset lié ? | Parcours dialogue |
| Place des Conditions / Facts / World Rules | Donner sens aux prédicats | Entity conditions, story flags, completed steps | Comment rendre les conditions no-code ? | Carte conceptuelle |
| Place des Outcomes / Battle references | Relier gameplay et histoire | outcomes, trainer_defeated, P6-05 | Comment représenter un résultat sans engine jargon ? | Modèle outcome auteur |
| Place du Validator | Validation visible dans le flux | P6-07, pokemon_project_validator, dialogue validation | Validation globale, contextuelle ou les deux ? | Placement diagnostics |
| Place des previews | Réduire l'incertitude auteur | dialogue preview runner, PlayableMapGame smoke P6-08 | Preview narrative locale ou runtime handoff ? | Stratégie preview |

## 11. Recommandation P7-02

P7-02 doit rester :

```text
P7-02 — Narrative Studio Information Architecture / Creator Journey Design
```

Objectif recommandé :

```text
Designer l'architecture d'information du Narrative Studio moderne :
où entrer, comment naviguer, comment regrouper Storyline / Chapter / Step,
où placer Events / Scenes / Dialogue / Conditions / Facts / World Rules /
Outcomes / Validator, et quels termes produit afficher au créateur.
```

P7-02 ne doit toujours pas coder. Il doit produire une décision d'IA et de parcours créateur avant P7-03.

## 12. Roadmap Phase 7 mise à jour

Mise à jour effectuée dans :

```text
MVP Selbrume/road_map_phase_7.md
```

Sections mises à jour :

```text
Lot courant : ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
Prochain lot exact : P7-02 — Narrative Studio Information Architecture / Creator Journey Design

- ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
- ➡️ P7-02 — Narrative Studio Information Architecture / Creator Journey Design

P7-01 : ✅ terminé
P7-02 : ➡️ prochain lot exact
```

Résumé ajouté :

```text
Shell actuel identifié : EditorShellPage, TopToolbar, EditorCanvasHost,
ProjectExplorerPanel, panels/inspectors et workspace controller.

Surfaces Narrative Studio identifiées : NarrativeWorkspaceCanvas,
Global Story Studio, Step Studio, Cutscene Studio, Dialogue Studio,
Narrative Inspector/Library, projection narrative, providers et use cases.

Douleurs créateur principales : shell dense, navigation narrative fragmentée,
vocabulaire technique visible, IDs/outcomes/flow labels exposés, states et
diagnostics à intégrer dans un parcours auteur plus clair.
```

## 13. Prochain lot exact

```text
P7-02 — Narrative Studio Information Architecture / Creator Journey Design
```

## 14. Ce qui n'a pas été fait

```text
pas de code
pas de Flutter widget
pas de refonte visuelle
pas de design system implémenté
pas de maquette finale
pas de modification editor
pas de modification runtime
pas de modification selbrume/
pas de modification tests
pas de Boot Flow
pas de menu save/load
pas de UI party/bag
pas de UI battle
pas de UI validator
pas de P7-02
```

Tests/analyze :

```text
Commande non lancée : aucun test/analyze lancé, car P7-01 est strictement documentaire et ne modifie aucun code.
```

## 15. Evidence Pack

### 15.1 Gate 0

Les sorties Gate 0 exactes sont incluses en section 3.

### 15.2 Commandes rg / find utilisées

Commande :

```bash
rg -n "Shell|AppShell|Scaffold|Navigation|Sidebar|Rail|Drawer|Toolbar|TopBar|TopToolbar|Panel|Inspector|Workspace|Route|Tab|Dashboard|Home" packages/map_editor examples --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Résultat exploité :

```text
EditorShellPage, TopToolbar, EditorCanvasHost, ProjectExplorerPanel,
workspace modes, panels/inspectors et runtime host debug panels identifiés.
```

Commande :

```bash
rg -n "Narrative|Scenario|Story|Dialogue|Event|Scene|Cinematic|Validator|Studio|Storyline|Chapter|Step|Outcome|WorldRule|Fact|Cutscene|Yarn" packages/map_editor packages/map_core packages/map_runtime examples --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Résultat exploité :

```text
NarrativeWorkspaceCanvas, Global Story Studio, Step Studio, Cutscene Studio,
Dialogue Studio, narrative projection, scenario/outcome/predicate models,
validator et dialogue/cutscene reports identifiés.
```

Commande :

```bash
rg -n "Provider|Riverpod|Controller|StateNotifier|Notifier|State|Workspace|Projection|ViewModel|ReadModel" packages/map_editor/lib/src/features packages/map_editor/lib/src --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Résultat exploité :

```text
EditorWorkspaceController, EditorNotifier, EditorState, narrative workspace
state/providers et editor workspace providers identifiés.
```

Commande :

```bash
find packages/map_editor/lib -type f | sort | rg "page|screen|view|widget|panel|toolbar|shell|studio|workspace|inspector|dialogue|narrative|story|cutscene|scenario"
```

Résultat exploité :

```text
liste des pages, panels, workspaces, studios, canvas, toolbars, inspectors et
surfaces dialogue/narrative utilisée pour l'inventaire.
```

### 15.3 Liste des fichiers shell identifiés

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart
packages/map_editor/lib/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart
packages/map_editor/lib/src/app/providers/editor_workspace_providers.dart
packages/map_editor/lib/src/app/providers/editor/workspace_providers.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
```

### 15.4 Liste des fichiers Narrative Studio identifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_canvas.dart
packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_focus.dart
packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_palette.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio_runtime_advisories.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart
packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart
```

### 15.5 Sections modifiées de road_map_phase_7.md

```text
Lot courant : ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
Prochain lot exact : P7-02 — Narrative Studio Information Architecture / Creator Journey Design

- ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
- ➡️ P7-02 — Narrative Studio Information Architecture / Creator Journey Design

P7-01 : ✅ terminé
P7-02 : ➡️ prochain lot exact

### ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
Statut : terminé.

### ➡️ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
Statut : prochain lot exact.
```

### 15.6 Final git diff --check

```text
Sortie : <vide>
```

### 15.7 Final git diff --stat

```text
 MVP Selbrume/road_map_phase_7.md | 48 ++++++++++++++++++++++++++++++++--------
 1 file changed, 39 insertions(+), 9 deletions(-)
```

### 15.8 Final git diff --name-only

```text
MVP Selbrume/road_map_phase_7.md
```

### 15.9 Final git status

```text
 M "MVP Selbrume/road_map_phase_7.md"
?? reports/roadmap/phase_7/p7_01_modern_app_shell_narrative_studio_ux_inventory_audit.md
```

Commande :

```bash
git status --short --untracked-files=all -- selbrume
```

Sortie :

```text
Sortie : <vide>
```

### 15.10 Confirmations

```text
Aucun code modifié.
Aucun test modifié.
Aucun fichier selbrume/ modifié.
P7-02 non lancé.
```

## 16. Auto-review critique

Ai-je évité de coder ?

```text
Oui. P7-01 est documentaire.
```

Ai-je évité de modifier `selbrume/` ?

```text
Oui. Aucun fichier selbrume/ n'a été modifié.
```

Ai-je évité de modifier `packages/` ou `examples/` ?

```text
Oui. Ces zones ont été inspectées en lecture seule uniquement.
```

Ai-je évité de lancer P7-02 ?

```text
Oui. P7-02 est fixé comme prochain lot exact, sans démarrage.
```

Ai-je inventorié le shell actuel ?

```text
Oui. EditorShellPage, TopToolbar, EditorCanvasHost, ProjectExplorerPanel,
panels/inspectors, workspace controller/state/providers ont été inventoriés.
```

Ai-je inventorié le Narrative Studio actuel ?

```text
Oui. NarrativeWorkspaceCanvas, Global Story Studio, Step Studio, Cutscene Studio,
Dialogue Studio, projection/providers/use cases et panels narratifs ont été inventoriés.
```

Ai-je distingué constat existant et architecture future ?

```text
Oui. La cartographie est fondée sur l'existant et les gaps sont explicitement listés.
```

Ai-je identifié les douleurs créateur ?

```text
Oui. Les douleurs sont classées par indice, impact, sévérité et lot recommandé.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P7-02 — Narrative Studio Information Architecture / Creator Journey Design.
```
