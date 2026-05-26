# P7-02 — Narrative Studio Information Architecture / Creator Journey Design

## 1. Résumé exécutif

P7-02 transforme l'inventaire P7-01 en décision d'architecture d'information.

Architecture recommandée :

```text
Option A — Un seul Narrative Studio avec sections internes.
```

Forme cible :

```text
Narrative Studio unique
  -> Story Map
  -> Scenes & Dialogue
  -> Logic & World
  -> Consequences
  -> Validation & Preview
```

Cette option garde les briques existantes, mais change le modèle mental visible. Les sous-studios actuels ne sont pas supprimés : Global Story Studio, Step Studio, Cutscene Studio et Dialogue Studio deviennent des vues spécialisées derrière une expérience Narrative Studio unifiée.

Premier écran recommandé pour P7-03 :

```text
Storyline Dashboard / Golden Path
```

Ce premier écran doit aider le créateur à comprendre l'histoire, choisir une prochaine action, voir les problèmes à corriger, lancer une preview, sans exposer les IDs, nodes, predicates ou diagnostics bruts.

## 2. Sources lues

Sources de gouvernance :

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_7.md
reports/roadmap/phase_7/p7_00_phase_7_roadmap_bootstrap_narrative_studio_modern_ui_scope_audit.md
reports/roadmap/phase_7/p7_01_modern_app_shell_narrative_studio_ux_inventory_audit.md
reports/roadmap/phase_6/p6_checkpoint_01_selbrume_beta_slice_readiness_review.md
```

Fichiers UI / Narrative Studio relus en lecture seule :

```text
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
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
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
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
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
90899d37 Ajoute P6-05 : Selbrume First Trainer Battle Golden Slice (test et rapport)
107feb9e Ajoute P6-04-ter : Selbrume Grant Reconciliation P6-03 Regression Fix (rapport et mises à jour)
248711b9 Ajoute P6-04-bis : Selbrume Git Worktree Attribution (rapport)
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

## 4. Problème produit à résoudre

P7-01 a montré que le Narrative Studio existe déjà en morceaux :

```text
Global Story Studio
Step Studio
Cutscene Studio
Dialogue Studio
Narrative Inspector / Library
Entity conditional dialogue bindings
Validator / diagnostics
```

Le problème produit n'est donc pas : "faut-il créer un Narrative Studio ?"

Le problème est :

```text
comment rendre ces briques compréhensibles comme une seule expérience créateur,
avec une entrée claire, une navigation claire, des termes non techniques,
une validation visible et un chemin court pour créer une première séquence.
```

Risques à éviter :

```text
remplacer trop tôt les studios existants
créer une maquette finale sans IA
faire de P7-03 un écran décoratif
laisser le créateur manipuler scenario IDs, nodes, entry nodes, outcomes,
flags, predicates et diagnostics comme concepts principaux
```

## 5. Modèle mental cible du Narrative Studio

Modèle mental retenu :

```text
Narrative Studio = organiser l'histoire, construire des moments, définir la logique, vérifier et prévisualiser.
```

Regroupement cible :

```text
Story Map
  -> Storyline
  -> Chapters
  -> Story Steps

Scenes & Dialogue
  -> Events
  -> Scenes
  -> Cinematics
  -> Dialogues

Logic & World
  -> Conditions
  -> Facts
  -> World Rules

Consequences
  -> Outcomes
  -> Battle references
  -> Progression markers

Validation & Preview
  -> Diagnostics
  -> Broken references
  -> Playability readiness
  -> Dialogue preview
  -> Scene preview
```

Règle de langage :

```text
Le créateur voit des intentions produit.
Le moteur garde les IDs et primitives techniques en interne.
```

## 6. Options d’architecture étudiées

### Option A — Un seul Narrative Studio avec sections internes

Description :

```text
Le shell expose une entrée principale Narrative Studio.
À l'intérieur, une navigation persistante organise Story Map, Scenes & Dialogue,
Logic & World, Consequences, Validation & Preview.
Les sous-studios existants deviennent des vues spécialisées.
```

Avantages :

```text
meilleure lisibilité créateur
réduit la fragmentation P7-01
compatible avec NarrativeWorkspaceCanvas
permet une première belle UI cohérente
met le validator et la preview dans le parcours auteur
```

Inconvénients :

```text
demande une IA claire avant tout code
risque de trop charger le premier écran si P7-03 n'est pas strict
nécessite de traduire les termes moteur
```

Décision :

```text
Recommandée.
```

### Option B — Studios séparés mais regroupés dans un hub commun

Description :

```text
Un hub Narrative Studio présente des cartes vers Global Story, Step, Cutscene
et Dialogue Studio, sans modifier fortement leur séparation mentale.
```

Avantages :

```text
très compatible avec l'existant
moins risqué côté code futur
facile à expliquer aux développeurs
```

Inconvénients :

```text
ne réduit pas assez la fragmentation
garde le créateur face à plusieurs studios
risque de produire seulement un menu de lancement
ne clarifie pas assez Events / Scenes / Dialogue / Conditions / Outcomes
```

Décision :

```text
Non retenue comme architecture cible, mais utile comme stratégie de transition.
```

### Option C — Workflow guidé par action

Description :

```text
L'interface part de grandes actions : créer une scène, créer une étape,
ajouter un dialogue, définir une condition, valider.
```

Avantages :

```text
excellent pour le golden path
réduit l'intimidation initiale
peut servir P7-03
```

Inconvénients :

```text
peut masquer la structure globale de l'histoire
risque de faire perdre la vue Storyline / Chapter / Step
peut devenir un assistant rigide si utilisé comme seule IA
```

Décision :

```text
À intégrer dans Option A comme golden path, pas comme architecture principale.
```

## 7. Architecture d’information recommandée

Architecture recommandée :

```text
Option A avec un golden path issu de l'Option C.
```

Structure cible :

```text
App Shell
  -> Narrative Studio
      -> Storyline Dashboard
      -> Story Map
      -> Scenes & Dialogue
      -> Logic & World
      -> Consequences
      -> Validation & Preview
```

Décisions :

```text
Storyline Dashboard devient l'entrée P7-03.
Global Story Studio nourrit Story Map.
Step Studio nourrit Story Steps et Consequences.
Cutscene Studio nourrit Scenes.
Dialogue Studio nourrit Dialogues.
Entity conditional dialogues deviennent un lien contextualisé vers Conditions.
Validator devient Validation & Preview, pas une page de logs.
```

Structure visuelle cible, sans maquette finale :

```text
hybride dashboard + sidebar interne + détail contextuel
```

Raisons :

```text
dashboard : donne une vue d'ensemble et un point d'entrée beau/compréhensible
sidebar interne : rend les sections Narrative Studio stables
détail contextuel : réutilise les inspectors existants sans exposer le moteur
```

## 8. Parcours créateur minimal

Parcours cible pour créer une première séquence narrative simple :

```text
1. ouvrir Narrative Studio depuis App Shell
2. sélectionner ou créer une Storyline
3. sélectionner ou créer un Chapter
4. créer un Story Step
5. choisir un déclencheur Event
6. attacher une Scene ou une interaction
7. ajouter un Dialogue
8. définir des Conditions si nécessaire
9. définir les Outcomes / conséquences
10. lancer Validation
11. lancer Preview
```

Ce qui existe déjà techniquement :

```text
workspace Narrative Studio
Global Story / Chapters / Steps
Step Studio authoring
Cutscene Studio
Dialogue Studio
dialogue preview runner
outcomes et projections
conditions / dialogues conditionnels
validator projet
runtime proof P6-03/P6-07/P6-08
```

Ce qui n'existe pas encore comme produit :

```text
Storyline Dashboard
golden path créateur en un seul écran
vocabulaire UI unifié
placement clair des Conditions / Facts / World Rules
Validation & Preview intégrés au parcours
```

Ce qui doit rester design-only en P7-02 :

```text
structure IA
parcours créateur
vocabulaire
préparation du premier écran P7-03
```

Ce qui est reporté :

```text
implémentation Flutter
maquette finale
runtime save/load UX
party/bag UI
battle UI
Boot Flow
```

## 9. Vocabulaire UI recommandé

Règle :

```text
Les termes moteur restent en interne.
L'UI affiche des termes d'intention créateur.
```

Table de traduction dans la matrice 13.3.

Termes à privilégier dans P7-03 :

```text
Récit
Chapitre
Étape d'histoire
Déclencheur
Scène
Dialogue
Condition
État du monde
Conséquence
Résultat
Problème à corriger
Aperçu
Prêt à jouer
```

Termes à éviter dans le premier écran :

```text
ScenarioAsset
local event flow
node
entry node
outcomeId
predicate
sourceEntityInteract
trainer_defeated
raw flag
```

## 10. Navigation interne cible

Entrée depuis App Shell :

```text
ProjectExplorerPanel / App Shell expose Narrative Studio comme entrée principale.
Le premier écran Narrative Studio devient Storyline Dashboard.
```

Navigation interne cible :

```text
Narrative Studio
  Overview
  Story Map
  Scenes & Dialogue
  Logic & World
  Consequences
  Validation & Preview
```

Structure d'écran cible :

```text
left internal sidebar : sections narratives stables
center : overview, list, flow ou golden path selon section
right detail panel : détails de sélection, problèmes et actions contextuelles
top local actions : create step, add scene, add dialogue, validate, preview
```

Patterns retenus :

```text
dashboard + sidebar interne + tree/detail + cartes actionnables
```

Patterns non retenus comme structure principale :

```text
kanban seul
flow horizontal seul
liste de studios séparés seule
assistant linéaire obligatoire
```

## 11. Place du Validator et des diagnostics

Décision :

```text
Le Validator ne doit pas être seulement une destination séparée.
Il doit apparaître comme un signal intégré au Narrative Studio.
```

Placement cible :

```text
Storyline Dashboard
  -> bloc "À corriger"
  -> état "Prêt à tester"

Chaque section narrative
  -> diagnostics contextuels
  -> action de correction

Validation & Preview
  -> vue détaillée des problèmes
  -> readiness du golden slice
```

Langage UI recommandé :

```text
Problème à corriger
Référence manquante
Dialogue introuvable
Condition incomplète
Étape sans conséquence
Prêt à tester
```

À garder interne :

```text
diagnostic kind
severity enum
validator diagnostic raw object
schema IDs
```

## 12. Place de la Preview

Décision :

```text
Preview doit être visible dès le premier écran, mais limitée.
```

Types de preview :

```text
Dialogue preview : disponible tôt, lié à Dialogue Studio.
Scene preview : objectif de design, pas forcément implémenté immédiatement.
Runtime handoff : à garder comme étape ultérieure, car P6-08 prouve seulement
PlayableMapGame Level B et pas une session interactive complète.
```

Placement cible :

```text
Storyline Dashboard : bouton "Aperçu rapide" désactivable si diagnostics bloquants.
Scenes & Dialogue : preview locale d'une scène ou conversation.
Validation & Preview : vue de readiness et lancement contrôlé plus tard.
```

Limite :

```text
P7-02 ne prouve pas de nouvelle preview runtime et ne crée aucune UI.
```

## 13. Matrices de décision

### 13.1 Matrice concepts → zones UI

| Concept | Rôle créateur | Zone UI recommandée | Existant technique | Terme UI recommandé | Décision |
|---|---|---|---|---|---|
| Storyline | Vue d'ensemble du récit | Storyline Dashboard / Story Map | Global Story scenario | Récit | Visible |
| Chapter | Regrouper les étapes | Story Map | Global Story Studio metadata | Chapitre | Visible |
| Story Step | Moment jouable ou narratif | Story Map + détail | Step Studio | Étape d'histoire | Visible |
| Event | Déclencheur d'une étape/scène | Scenes & Dialogue | scenario source / entity interact | Déclencheur | Visible |
| Scene | Moment scénarisé local | Scenes & Dialogue | Cutscene Studio / local event flow | Scène | Visible |
| Cinematic | Séquence mise en scène | Scenes & Dialogue | Cutscene Studio | Mise en scène | Visible avec prudence |
| Dialogue | Conversation / texte | Scenes & Dialogue | Dialogue Studio / Yarn | Dialogue | Visible |
| Fact | État connu du monde | Logic & World | story flags / progression | Fait du monde | Visible après P7-03 |
| World Rule | Règle conditionnelle | Logic & World | world rules / predicates | Règle du monde | Visible après P7-03 |
| Condition | Condition d'apparition/progression | Logic & World | predicates / conditional dialogues | Condition | Visible |
| Outcome | Résultat d'une étape/scène | Consequences | outcomes / emit outcome | Résultat | Visible |
| Battle reference | Lien vers combat | Consequences | trainer references / battle outcomes | Combat lié | Visible contextualisé |
| Validator | Vérifier cohérence | Validation & Preview | pokemon_project_validator | Vérification | Visible |
| Preview | Tester sans quitter le flux | Validation & Preview | dialogue preview runner / P6-08 smoke | Aperçu | Visible |

### 13.2 Matrice options d’architecture

| Option | Description | Avantages | Inconvénients | Compatibilité existant | Risque | Décision |
|---|---|---|---|---|---|---|
| A | Un Narrative Studio avec sections internes | Cohérent, clair, modernisable, réduit fragmentation | Demande IA stricte | Forte : NarrativeWorkspaceCanvas existe déjà | Premier écran trop chargé | Recommandée |
| B | Studios séparés dans hub commun | Transition facile, peu risqué | Fragmentation persiste | Très forte | Hub de boutons sans parcours | Non retenue comme cible |
| C | Workflow guidé par action | Excellent golden path | Masque structure globale | Moyenne | Assistant rigide | À intégrer dans A |

### 13.3 Matrice vocabulaire

| Terme technique | Problème UX | Terme UI recommandé | Visible dans UI ? | Rester interne ? |
|---|---|---|---|---|
| ScenarioAsset | Objet moteur abstrait | Récit / Scène selon contexte | Non | Oui |
| scenario | Trop générique | Récit, étape ou scène | Non brut | Oui |
| local event flow | Jargon moteur | Scène | Non | Oui |
| cutscene | Peut sembler cinématique finale | Scène / Mise en scène | Rarement | Oui |
| sourceEntityInteract | Incompréhensible créateur | Déclencheur : interaction | Non | Oui |
| outcome | Trop technique en anglais | Résultat | Oui traduit | Oui |
| outcomeId | ID technique | Résultat sélectionné | Non | Oui |
| flag | Terme moteur | État du monde | Non | Oui |
| story flag | Terme moteur | Fait du monde | Non | Oui |
| completed step | État technique | Étape terminée | Oui traduit | Oui |
| predicate | Jargon logique | Condition | Non | Oui |
| world rule | Terme acceptable si clarifié | Règle du monde | Oui | Oui |
| fact | Court mais abstrait | Fait du monde | Oui | Oui |
| node | Graphe technique | Bloc de scène / réplique | Non brut | Oui |
| entry node | Jargon graphe | Début de la scène | Non | Oui |
| flowEntry | Jargon Step Studio | Début de l'étape | Non | Oui |
| dialogue node | Jargon Yarn | Passage de dialogue | Non brut | Oui |
| trainer_defeated | Flag runtime | Combat gagné | Non | Oui |
| validator diagnostic | Technique | Problème à corriger | Non brut | Oui |

### 13.4 Matrice parcours créateur

| Étape créateur | Objectif | Surface UI | Donnée technique sous-jacente | Risque | Preuve attendue plus tard |
|---|---|---|---|---|---|
| Ouvrir Narrative Studio | Entrer dans l'espace récit | App Shell / Storyline Dashboard | EditorWorkspaceMode narrative | Entrée noyée dans explorer | P7-03 premier écran |
| Choisir Storyline | Définir le récit actif | Story Map | globalStory scenario | Storyline floue | P7-03 |
| Choisir Chapter | Organiser le récit | Story Map | globalStory metadata | Chapitres cachés | P7-03 |
| Créer Story Step | Ajouter un moment | Story Map / détail | Step Studio document | IDs visibles | P7-04 |
| Choisir Event | Définir déclencheur | Scenes & Dialogue | scenario source | sourceEntityInteract visible | P7-04 |
| Attacher Scene | Créer contenu local | Scenes & Dialogue | local event flow / cutscene | Cutscene vs event flou | P7-04 |
| Ajouter Dialogue | Écrire texte | Dialogue section | Yarn/dialogue document | Yarn exposé trop tôt | P7-04 |
| Définir Conditions | Contrôler apparition/progression | Logic & World | predicates / flags | Logique trop technique | P7-04/P7-05 |
| Définir Outcomes | Dire ce qui change | Consequences | outcomes / progression | outcomeId visible | P7-04 |
| Valider | Corriger les problèmes | Validation & Preview | validator diagnostics | Logs bruts | P7-05 |
| Preview | Vérifier le résultat | Validation & Preview | dialogue preview / runtime later | Survente runtime | P7-03/P7-07 |

### 13.5 Matrice décisions pour P7-03

| Décision | Impact sur premier écran | Risque si non décidé | Entrée pour P7-03 |
|---|---|---|---|
| Premier écran = Storyline Dashboard / Golden Path | Donne une entrée claire et belle | P7-03 ferait une page décorative | Concevoir dashboard |
| IA = Narrative Studio unique avec sections | Évite hub de studios fragmenté | Navigation confuse | Sidebar interne |
| Story Map en haut de hiérarchie | Rend Storyline / Chapter / Step visibles | Step Studio reste isolé | Bloc structure histoire |
| Scenes & Dialogue comme second pilier | Relie Cutscene et Dialogue | Dialogue reste asset isolé | Bloc créer scène/dialogue |
| Logic & World séparé | Conditions/facts ne polluent pas le premier écran | Jargon predicate visible | Bloc secondaire / détails |
| Consequences séparé | Outcomes et battle refs deviennent lisibles | outcomeId visible | Bloc conséquences |
| Validator intégré | Diagnostics actionnables | Erreurs découvertes tard | Bloc À corriger |
| Preview limitée mais visible | Encourage test rapide | Survente runtime complet | Bouton aperçu prudent |
| Jargon moteur masqué | UI plus accessible | No-code affaibli | Glossaire P7-03 |

## 14. Recommandation pour P7-03

P7-03 doit concevoir :

```text
Narrative Studio First Screen / Golden Path UX Design
```

Premier écran recommandé :

```text
Storyline Dashboard
```

Blocs à faire apparaître :

```text
Récit actif
Chapitres et étapes principales
Prochaine action recommandée
Créer une étape
Ajouter une scène
Ajouter un dialogue
Problèmes à corriger
État "Prêt à tester"
Aperçu rapide
Accès aux sections Story Map, Scenes & Dialogue, Logic & World, Consequences,
Validation & Preview
```

Contenus à ne pas afficher dans le premier écran :

```text
raw ScenarioAsset
local event flow
node graph détaillé
entry node
outcomeId
predicate brut
flag brut
diagnostics techniques complets
Battle UI
Runtime save/load UX
Party/bag UI
Boot Flow
```

Questions ouvertes pour P7-03 :

```text
Le dashboard est-il centré sur une Storyline unique ou sur plusieurs récits ?
Combien d'actions rapides afficher sans densifier l'écran ?
Le premier écran doit-il montrer une mini timeline, une liste de chapitres ou des cartes ?
Quelle preview est affichée si le projet n'a pas encore de scène ?
```

## 15. Roadmap Phase 7 mise à jour

Fichier modifié :

```text
MVP Selbrume/road_map_phase_7.md
```

Sections mises à jour :

```text
Lot courant : ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
Prochain lot exact : P7-03 — Narrative Studio First Screen / Golden Path UX Design

- ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
- ➡️ P7-03 — Narrative Studio First Screen / Golden Path UX Design

P7-02 : ✅ terminé
P7-03 : ➡️ prochain lot exact
```

Résumé ajouté :

```text
Architecture recommandée : un Narrative Studio unique avec sections internes,
fondé sur un hub Storyline Dashboard et une navigation interne persistante.

Modèle mental retenu : Story Map, Scenes & Dialogue, Logic & World,
Consequences, Validation & Preview.

Les sous-studios existants restent des vues spécialisées réutilisables :
Global Story Studio, Step Studio, Cutscene Studio et Dialogue Studio ne sont
pas supprimés, mais repositionnés derrière une IA créateur plus claire.
```

## 16. Prochain lot exact

```text
P7-03 — Narrative Studio First Screen / Golden Path UX Design
```

## 17. Ce qui n’a pas été fait

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
pas de UI validator codée
pas de P7-03
```

Tests/analyze :

```text
Commande non lancée : aucun test/analyze lancé, car P7-02 est strictement documentaire et ne modifie aucun code.
```

## 18. Evidence Pack

### 18.1 Gate 0

Les sorties Gate 0 exactes sont incluses en section 3.

### 18.2 Liste des fichiers P7-01 relus

```text
reports/roadmap/phase_7/p7_01_modern_app_shell_narrative_studio_ux_inventory_audit.md
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
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
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
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

### 18.3 Recherches rg utilisées

Commande :

```bash
rg -n "globalStory|step|cutscene|dialogue|NarrativeWorkspaceCanvas|GlobalStory|StepStudio|CutsceneStudio|DialogueStudio|WorldRule|Fact|Outcome|Validator|Scenario|Storyline|Chapter" packages/map_editor packages/map_core packages/map_runtime --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Résultat exploité :

```text
Présence confirmée des surfaces Global Story, Step Studio, Cutscene Studio,
Dialogue Studio, Outcome, Validator, Scenario, Chapters, world rules,
conditions/dialogues conditionnels et projections narratives.
```

### 18.4 Sections modifiées de road_map_phase_7.md

```text
Lot courant : ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
Prochain lot exact : P7-03 — Narrative Studio First Screen / Golden Path UX Design

- ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
- ➡️ P7-03 — Narrative Studio First Screen / Golden Path UX Design

P7-02 : ✅ terminé
P7-03 : ➡️ prochain lot exact

### ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
Statut : terminé.

### ➡️ P7-03 — Narrative Studio First Screen / Golden Path UX Design
Statut : prochain lot exact.
```

### 18.5 Final git diff --check

```text
Sortie : <vide>
```

### 18.6 Final git diff --stat

```text
 MVP Selbrume/road_map_phase_7.md | 51 +++++++++++++++++++++++++++++++++-------
 1 file changed, 42 insertions(+), 9 deletions(-)
```

### 18.7 Final git diff --name-only

```text
MVP Selbrume/road_map_phase_7.md
```

### 18.8 Final git status

```text
 M "MVP Selbrume/road_map_phase_7.md"
?? reports/roadmap/phase_7/p7_02_narrative_studio_information_architecture_creator_journey_design.md
```

Commande :

```bash
git status --short --untracked-files=all -- selbrume
```

Sortie :

```text
Sortie : <vide>
```

### 18.9 Confirmations

```text
Aucun code modifié.
Aucun test modifié.
Aucun fichier selbrume/ modifié.
P7-03 non lancé.
```

## 19. Auto-review critique

Ai-je évité de coder ?

```text
Oui. P7-02 est documentaire.
```

Ai-je évité de modifier `selbrume/` ?

```text
Oui. Aucun fichier selbrume/ n'a été modifié.
```

Ai-je évité de modifier `packages/` ou `examples/` ?

```text
Oui. Ces zones ont été relues en lecture seule uniquement.
```

Ai-je évité de lancer P7-03 ?

```text
Oui. P7-03 est fixé comme prochain lot exact, sans démarrage.
```

Ai-je choisi une architecture recommandée claire ?

```text
Oui. Option A avec golden path issu de l'Option C.
```

Ai-je évité le "ça dépend" ?

```text
Oui. Option A est recommandée, Option B non retenue comme cible, Option C intégrée comme parcours.
```

Ai-je réduit le jargon moteur visible ?

```text
Oui. Une matrice de vocabulaire remplace les termes techniques par des termes UI.
```

Ai-je préparé concrètement P7-03 ?

```text
Oui. P7-03 doit concevoir Storyline Dashboard / Golden Path avec blocs inclus et exclus.
```

Ai-je fixé un prochain lot exact unique ?

```text
Oui : P7-03 — Narrative Studio First Screen / Golden Path UX Design.
```
