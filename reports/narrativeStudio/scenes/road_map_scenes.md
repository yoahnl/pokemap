# NS-SCENES-V1 — Roadmap Scenes

## Objectif produit

Construire le futur systeme de Scenes V1 du Narrative Studio : un Scene Builder no-code capable de modeliser une sequence logique executable sous forme de graphe, sans confondre Scene, Event, Cinematic, Dialogue Yarn, StorylineStep, Fact ou World Rule.

La Scene V1 doit devenir le coeur d'orchestration entre les declencheurs de map/runtime, les dialogues, les cinematiques, les combats, les actions, les consequences, les facts, les world rules et la progression narrative.

## Etat actuel

Storylines V1/V1.1 est ferme avec limitations. Le workspace Storylines sait creer une storyline principale, des quetes annexes, des chapitres, des etapes narratives, des attachements sideQuest explicites, un graph read-only et une Structure en accordions pleine largeur.

Le systeme actuel contient deja des briques narratives legacy ou transitoires :

- `ScenarioAsset` : graphe executable generique avec scopes `globalStory` et `localEventFlow`.
- `ScriptAsset` : sequence de commandes runtime bas niveau.
- `ScriptCondition` : langage pur de conditions.
- `MapEventDefinition` : evenements de map a pages conditionnelles.
- Cutscene Studio : authoring guide compile vers `ScenarioAsset`.
- Scenario runtime : bridge MVP capable de declencher dialogue, script, message, actions, combat trainer et outcomes.

Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propre. Le principal risque est de brancher les StorylineStep sur l'ancien systeme avant de stabiliser le contrat Scene.

## Regles non negociables

- Ne pas brancher `StorylineStep.sceneLinkIds` vers l'ancien systeme tant que Scene V1 n'est pas stable.
- Ne pas faire de `ScenarioAsset.localEventFlow` le modele produit final de Scene V1 sans decision explicite.
- Ne pas confondre Scene et Cinematic.
- Ne pas faire de Yarn le moteur de progression globale.
- Ne pas exposer les flags techniques comme experience principale.
- Ne pas hardcoder Selbrume ou des scenes de reference dans le code produit.
- Ne pas creer de scene placeholder automatique depuis Storylines.
- Ne pas modifier runtime/gameplay/battle depuis les lots documentaires.

## Lots

| Lot | Statut | Objectif |
|---|---|---|
| NS-SCENES-V1-00 — Scene System Scope / Current State Audit | DONE | Audit documentaire de l'existant, definition Scene V1, frontieres produit et roadmap. |
| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | TODO | Formaliser le contrat produit SceneGraph/SceneNode/SceneEdge, sans code model si le lot reste documentaire. |
| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | TODO | Decider ou stocker les Scenes, quels IDs, quels read models, et la strategie de migration/compat legacy. |
| NS-SCENES-V1-03 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
| NS-SCENES-V1-04 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles ou fixtures explicites, sans fake fallback. |
| NS-SCENES-V1-05 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
| NS-SCENES-V1-06 — Node Inspector Read-only | TODO | Inspecteur contextuel read-only pour node selectionne, conditions, sorties et notes. |
| NS-SCENES-V1-07 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
| NS-SCENES-V1-08 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
| NS-SCENES-V1-09 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
| NS-SCENES-V1-10 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |

## Prochain lot recommande

`NS-SCENES-V1-01 — Scene Product Model / Graph Contract`

Raison : avant de creer un modele, un widget ou une migration, il faut verrouiller le vocabulaire exact du graph Scene V1, les types de nodes, les transitions et ce qui reste hors scope.

## Dependances

- Storylines V1/V1.1 ferme avec limitations.
- `ProjectManifest.storylines` existant et stable.
- `ScenarioAsset`, `ScriptAsset`, `ScriptCondition`, `MapEventDefinition` audites comme legacy/adaptables.
- Runtime scenario/script/cutscene audite a haut niveau.
- Decision storage Scene V1 a venir dans V1-02.

## Non-objectifs globaux

- Pas de runtime complet dans V1-00 a V1-08.
- Pas de branchement `StorylineStep -> Scene` avant V1-10.
- Pas de validation narrative globale avant un lot dedie.
- Pas de facts/world rules productises avant contrat dedie.
- Pas de cinematique lineaire refondue dans le meme lot que SceneGraph.
- Pas de hardcode de Selbrume dans l'UI produit.

## Decisions canoniques

- Storylines V1/V1.1 est ferme avec limitations et ne doit pas etre rouvert par NS-SCENES-V1-00.
- `StorylineStep.sceneLinkIds` reste desactive/honnete cote UI tant que Scene V1 n'est pas stable.
- Aucun lien avec l'ancien systeme de scene/scenario ne doit etre branche avant Scene V1 stable.
- Scene V1 est un graph d'orchestration.
- Cinematic V1 doit rester une sequence visuelle lineaire.
- Dialogue Yarn porte le texte et les choix de dialogue, puis produit des outcomes lisibles.
- Event porte le declencheur local/runtime.
- Fact porte l'etat du monde persistant lisible par l'auteur.
- World Rule porte les changements visibles/actifs du monde selon facts, steps ou conditions.
