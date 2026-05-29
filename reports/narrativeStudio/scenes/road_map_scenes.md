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
| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | DONE | Contrat produit Scene V1 formalise : definitions Scene/Graph/Node/Edge/Port/Outcome, taxonomie nodes/edges, payloads minimaux/interdits, diagnostics et runtime intents. |
| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | DONE | Decision retenue : `SceneAsset` authoring dedie + `ProjectManifest.scenes` futur, avec `ScenarioAsset` conserve comme legacy/runtime bridge temporaire et sans migration automatique. |
| NS-SCENES-V1-03 — Scene Core Model V0 | TODO | Ajouter le modele core `SceneAsset`, graph/layout value objects, `ProjectManifest.scenes`, exports et tests JSON/core. |
| NS-SCENES-V1-04 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
| NS-SCENES-V1-05 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles depuis `ProjectManifest.scenes`, sans fake fallback. |
| NS-SCENES-V1-06 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
| NS-SCENES-V1-07 — Node Inspector Read-only | TODO | Inspecteur contextuel pour node selectionne, conditions, sorties et notes. |
| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
| NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
| NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
| NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |

## Prochain lot recommande

`NS-SCENES-V1-03 — Scene Core Model V0`

Raison : la decision storage/IDs/read models est tranchee ; une UI Scenes sans modele core creerait du faux. Le prochain lot doit poser `SceneAsset`, `ProjectManifest.scenes`, graph/layout et tests core avant le shell editor.

## Decisions V1-02

- Option retenue : `SceneAsset` authoring dedie + `ScenarioAsset` runtime bridge temporaire.
- Futur storage canonique : `ProjectManifest.scenes`, absent/null compatible vers `[]`.
- `ProjectManifest.scenarios` reste supporte comme legacy ; aucune suppression.
- Aucune migration automatique `ScenarioAsset -> SceneAsset`.
- Layout persiste dans un `SceneGraphLayout` separe du graph logique ; runtime ignore le layout.
- IDs stables : jamais derives du nom utilisateur, du texte Yarn, de la position visuelle ou de Selbrume.
- Read models separes : authoring model, editor read model, diagnostics, runtime executable model.

## Limites V1-02

- Aucun `SceneAsset` code.
- Aucun `ProjectManifest.scenes` code.
- Aucun codec JSON.
- Aucun build_runner.
- Aucun workspace UI.
- Aucun runtime Scene.
- Aucun sceneLink Storylines.

## Decisions V1-01

- Scene V1 = graph d'orchestration, pas Storyline, Event, Cinematic, Yarn, Fact ou World Rule.
- `YarnDialogueNode` est le node dialogue V1 unique ; pas de `DialogueNode` generique tant qu'un autre moteur n'existe pas.
- Les transitions sont explicites : aucune logique ne vient de la proximite visuelle des nodes.
- Les conditions restent portees par `ConditionNode`, pas par des expressions libres sur edges.
- Les payloads doivent etre types ; `metadata` ne doit porter aucune logique critique.
- Les positions de nodes sont necessaires a l'editor, mais le runtime ne doit pas dependre du layout.
- Aucun modele Dart, storage, widget, runtime, fixture Selbrume ou sceneLink n'a ete cree.

## Limites V1-01

- Storage final non tranche.
- `SceneAsset` non cree.
- `ProjectManifest.scenes` non ajoute.
- Compatibilite `ScenarioAsset` non tranchee.
- Scene Builder UI non demarre.
- StorylineStep -> Scene non branche.

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
