# Phase 7 Roadmap — Narrative Studio Modern UI Productization

## Statut de la phase

Phase 7 ouverte par le checkpoint Phase 6.

Statut : 🟡 active

Roadmap source précédente :

```text
MVP Selbrume/road_map_phase_6.md
```

Lot courant : ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design

Prochain lot exact : P7-03 — Narrative Studio First Screen / Golden Path UX Design

Légende :

- ✅ terminé
- ➡️ prochain lot exact
- ⏳ à venir
- 🧭 checkpoint
- ⏭️ reporté

## Décision P7-00

P7-00 recadre Phase 7 autour de la demande utilisateur :

```text
Je veux avancer vers une nouvelle belle UI pour le Narrative Studio.
```

Priorité initiale actée :

```text
Modern App Shell
Narrative Studio moderne
workflows no-code guidés
navigation produit claire
validation visible
expérience créateur compréhensible
```

Les menus runtime restent importants, mais ils ne sont pas le premier axe de
Phase 7 :

```text
Runtime save/load UX
Runtime party / bag UX
Runtime battle / encounter UX
Boot Flow / title / slots
```

Ces sujets sont reportés dans un backlog UX runtime à cadrer après les décisions
Shell + Narrative Studio.

## Objectif Phase 7

Transformer les preuves techniques et le golden slice Selbrume en expérience
produit utilisable pour un créateur : une UI moderne, lisible, guidée, qui rend
les concepts narratifs manipulables sans forcer l'édition JSON ni masquer les
limites runtime.

Phase 7 doit partir des preuves Phase 6 :

```text
Selbrume repo-local chargeable
start map Selbrume / spawn prouvé
party/bag initial seedé
interaction narrative technique
Route 1 encounter / capture
trainer battle Grant
reward minimal
save/load disque réel
validator bêta strict
PlayableMapGame smoke Level B
```

## État UI / Narrative Studio au bootstrap P7

Constats P7-00 :

```text
les concepts narratifs existent déjà dans le code et les rapports
Step Studio, Global Story Studio, Cutscene Studio et Dialogue editor existent par morceaux
des read models narratifs existent côté map_core
des validations et diagnostics existent côté map_core
le shell/editor possède déjà des notions de workspace, panels et providers
la preuve Selbrume P6 reste surtout technique et test-only
l'expérience créateur unifiée Narrative Studio n'est pas encore productisée
```

Risque principal :

```text
partir trop vite sur des menus runtime isolés ou une refonte cosmétique massive
avant d'avoir cadré l'architecture d'information du Narrative Studio.
```

## Non-objectifs Phase 7 initiaux

```text
ne pas réécrire le moteur
ne pas rouvrir la parité Pokémon complète
ne pas créer toute la campagne Selbrume finale
ne pas créer tous les assets finaux
ne pas traiter l'audio complet sauf décision dédiée
ne pas créer une refonte cosmétique massive sans audit UX
ne pas démarrer par les menus runtime secondaires
```

## Réserves héritées de Phase 6 à convertir en décisions UX

```text
session joueur interactive complète non prouvée
Boot Flow non prouvé
écran titre / slots UI non prouvés
UI save/load non prouvée
UI party / bag non prouvée
Battle UI et capture UI finales non prouvées
victoire battle engine complète non prouvée
état disque P6-06 complet non injecté dans PlayableMapGame
campagne Selbrume finale non prouvée
parité Pokémon complète non prouvée
audio runtime complet non prouvé
```

## Suivi des lots

- ✅ P7-00 — Phase 7 Roadmap Bootstrap / Narrative Studio Modern UI Scope Audit
- ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit
- ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design
- ➡️ P7-03 — Narrative Studio First Screen / Golden Path UX Design
- ⏳ P7-04 — Narrative Studio Interaction Model / No-Code Authoring Controls V0
- ⏳ P7-05 — Validator & Diagnostics UI Integration Design
- ⏳ P7-06 — Narrative Studio Visual System / Component Rules V0
- ⏳ P7-07 — Narrative Studio Minimal Interactive Prototype V0
- ⏳ P7-08 — Runtime UX Backlog Triage / Deferred Menus Scope
- 🧭 P7-CHECKPOINT-01 — Narrative Studio Modern UI Readiness Review

P7-00 : ✅ terminé

P7-01 : ✅ terminé

P7-02 : ✅ terminé

P7-03 : ➡️ prochain lot exact

Prochain lot exact :

```text
P7-03 — Narrative Studio First Screen / Golden Path UX Design
```

## Roadmap

### ✅ P7-00 — Phase 7 Roadmap Bootstrap / Narrative Studio Modern UI Scope Audit

Statut : terminé.

But :

```text
relire Phase 6, auditer les surfaces UI existantes et recadrer Phase 7 autour
du shell moderne et du Narrative Studio.
```

Preuve :

```text
reports/roadmap/phase_7/p7_00_phase_7_roadmap_bootstrap_narrative_studio_modern_ui_scope_audit.md
```

### ✅ P7-01 — Modern App Shell & Narrative Studio UX Inventory Audit

Statut : terminé.

But :

```text
inventorier l'UI editor actuelle, le shell, la navigation, les workspaces et les
surfaces Narrative Studio existantes pour identifier les douleurs produit avant
design ou code.
```

Livrables attendus :

```text
inventaire des écrans et workspaces existants
cartographie Shell -> Narrative Studio -> sous-studios
liste des surfaces obsolètes ou trop techniques
priorités UX créateur
prochain lot design strict
```

Résultat P7-01 :

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

Décision :

```text
garder les briques existantes comme matière première
ne pas remplacer le shell sans architecture d'information
ne pas coder de nouvelle UI avant P7-02
préparer une IA Narrative Studio qui clarifie Storyline, Chapter, Step,
Events, Scenes, Dialogues, Conditions, Facts, World Rules, Outcomes,
Validator et previews.
```

### ✅ P7-02 — Narrative Studio Information Architecture / Creator Journey Design

Statut : terminé.

But :

```text
définir l'architecture d'information moderne du Narrative Studio : Storyline,
Chapter, Story Step, Event, Scene, Dialogue, Fact, World Rule, Validator.
```

Résultat P7-02 :

```text
Architecture recommandée : un Narrative Studio unique avec sections internes,
fondé sur un hub Storyline Dashboard et une navigation interne persistante.

Modèle mental retenu : Story Map, Scenes & Dialogue, Logic & World,
Consequences, Validation & Preview.

Les sous-studios existants restent des vues spécialisées réutilisables :
Global Story Studio, Step Studio, Cutscene Studio et Dialogue Studio ne sont
pas supprimés, mais repositionnés derrière une IA créateur plus claire.

Vocabulaire UI : masquer le jargon moteur en remplaçant scenario/local event
flow/node/entry/outcomeId/flag/predicate par récit, scène, étape, résultat,
condition, état du monde, problème à corriger et aperçu.
```

Décision pour P7-03 :

```text
P7-03 doit concevoir le premier écran du Narrative Studio : Storyline Dashboard
+ Golden Path. Il doit montrer la structure de l'histoire, les prochaines
actions créateur, les problèmes à corriger et l'accès preview, sans afficher
les détails bas niveau des flows, IDs, predicates ou diagnostics bruts.
```

### ➡️ P7-03 — Narrative Studio First Screen / Golden Path UX Design

Statut : prochain lot exact.

But :

But :

```text
concevoir le premier écran et le parcours créateur minimal qui rend le golden
slice narratif compréhensible.
```

### ⏳ P7-04 — Narrative Studio Interaction Model / No-Code Authoring Controls V0

But :

```text
cadrer les contrôles no-code nécessaires : pickers, panneaux d'édition, états,
prévisualisations, diagnostics et feedback utilisateur.
```

### ⏳ P7-05 — Validator & Diagnostics UI Integration Design

But :

```text
intégrer les diagnostics validator dans l'expérience Narrative Studio sans les
masquer et sans ajouter d'auto-fix prématuré.
```

### ⏳ P7-06 — Narrative Studio Visual System / Component Rules V0

But :

```text
définir les règles visuelles et composants nécessaires au Narrative Studio
moderne, en cohérence avec le shell et les workflows créateur.
```

### ⏳ P7-07 — Narrative Studio Minimal Interactive Prototype V0

But :

```text
produire une première preuve interactive bornée du Narrative Studio moderne,
après les audits et designs.
```

### ⏳ P7-08 — Runtime UX Backlog Triage / Deferred Menus Scope

But :

```text
reclasser save/load, party/bag, battle/encounter, Boot Flow et autres menus
runtime après cadrage Narrative Studio, sans les laisser disparaître.
```

### 🧭 P7-CHECKPOINT-01 — Narrative Studio Modern UI Readiness Review

But :

```text
décider si la modernisation UI Narrative Studio est suffisamment cadrée ou
prototypée pour passer à une phase de build plus large.
```

## Reports explicites

Reportés hors premier axe Phase 7 sauf décision dédiée :

```text
campagne Selbrume finale complète
parité Pokémon complète
audio runtime complet
tous les assets finaux
runtime save/load UI comme priorité 1
runtime party/bag UI comme priorité 1
runtime battle/capture UI comme priorité 1
Boot Flow complet comme priorité 1
refonte totale non guidée par audit
```
