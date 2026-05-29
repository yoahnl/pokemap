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
| NS-SCENES-V1-03 — Scene Core Model V0 | DONE | Modele core `SceneAsset` ajoute dans `map_core` avec `SceneGraph`, `SceneGraphLayout`, nodes/edges/outcomes, `ProjectManifest.scenes`, export public et tests core/JSON/manifest. |
| NS-SCENES-V1-04 — Workspace Shell Scenes | DONE | Shell editor `Scenes` branche dans Narrative Studio, lecture read-only de `ProjectManifest.scenes`, empty state honnete, actions non supportees desactivees. |
| NS-SCENES-V1-05 — Scene Tree Panel Read-only | DONE | Arborescence read-only des scenes reelles, selection locale, resume central, header Scenes compacte, aucun graph ni mutation. |
| NS-SCENES-V1-06 — Graph Read-only Skeleton | DONE | Graph Scene V1 read-only depuis le `SceneAsset` selectionne : nodes, edges, labels, layout persiste ou layout derive non persiste. |
| NS-SCENES-V1-07 — Node Inspector Read-only | TODO | Inspecteur contextuel pour node selectionne, conditions, sorties et notes. |
| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
| NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
| NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
| NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |

## Prochain lot recommande

`NS-SCENES-V1-07 — Node Inspector Read-only`

Raison : le workspace Scenes affiche maintenant un graph read-only reel pour la scene selectionnee. Le prochain lot peut ajouter un inspecteur read-only du node selectionne, sans authoring ni runtime.

## Decisions V1-06

- Le placeholder `Graph — bientôt` est remplace par `SceneGraphReadOnlyView`.
- Le graph lit `scene.graph.nodes`, `scene.graph.edges` et `scene.layout.nodeLayouts`.
- Un layout persiste complet est utilise tel quel.
- Si le layout est absent ou incomplet, un layout derive deterministe est calcule en memoire et non persiste.
- Les edges sont dessines par un `CustomPainter` read-only avec couleurs injectees depuis le theme.
- Les labels d'edges viennent de `SceneEdge.label` ou du couple `kind/fromPortId`.
- Aucun node inspector, drag and drop, edition de node/edge ou runtime n'est ajoute.

## Limites V1-06

- Layout derive simple, suffisant pour V1-06 mais pas un moteur de graph final.
- Pas de zoom/pan/minimap.
- Pas de selection de node.
- Pas de payload detaille.
- Pas d'inspecteur read-only avant V1-07.

## Decisions V1-05

- `ScenesWorkspace` devient un workspace read-only structure : header compact, panneau gauche d'arborescence, zone centrale de resume.
- La selection de scene est locale au widget et ne modifie pas `ProjectManifest`.
- Les scenes sont groupees par `storylineId` puis `chapterId` quand ces champs existent ; sinon elles restent sous `Sans storyline` / `Sans chapitre`.
- Le resume central affiche nom, description, IDs, tags, nodes, edges et outcomes declares.
- Le graph reste explicitement absent : seul un placeholder read-only annonce V1-06.
- Aucun bouton d'authoring actif n'est ajoute.

## Limites V1-05

- Pas de rendu SceneGraph.
- Pas de Scene Tree editable.
- Pas de Node Inspector.
- Pas de creation, edition, suppression, duplication ou import de scene.
- Pas de runtime Scene.
- Pas de branchement Storylines `sceneLinkIds`.

## Decisions V1-04

- Nouvelle entree `Scenes` ajoutee au mode workspace editor et a la navigation interne Narrative Studio.
- L'ancien mode `step` reste distinct et libelle `Etapes`.
- `ScenesWorkspace` affiche un shell read-only : titre, explication, metriques scenes/nodes/outcomes et empty state si `ProjectManifest.scenes` est vide.
- Les scenes affichees viennent uniquement de `ProjectManifest.scenes` via la projection narrative.
- Les actions `Creer une scene` et `Builder` sont desactivees et honnetes.
- Aucun seed, aucune scene de demonstration et aucune donnee Selbrume ne sont crees.
- Le panneau droit est volontairement absent pour le mode `Scenes` en V1-04.

## Limites V1-04

- Pas de Scene Tree Panel complet.
- Pas de SceneGraph read-only.
- Pas de Node Inspector.
- Pas de creation, edition, suppression ou duplication de scene.
- Pas de runtime Scene.
- Pas de branchement Storylines `sceneLinkIds`.
- `flutter analyze --no-fatal-infos` global reste bloque par une dette preexistante hors Scenes dans `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`; l'analyse ciblee du lot passe.

## Decisions V1-03

- `SceneAsset` est le modele authoring Scene V1 dedie.
- `SceneGraph` contient `startNodeId`, nodes et edges ; il ne contient pas le layout.
- `SceneGraphLayout` est separe et editor-only : node layouts et edge layouts peuvent etre ignores par le runtime.
- `SceneNodeKind` couvre `start`, `end`, `yarnDialogue`, `condition`, `action`, `battle`, `cinematic`, `branchByOutcome`, `merge`.
- `SceneEdge` porte un `fromPortId` explicite ; le kind JSON `default` est expose via l'enum Dart `defaultFlow` pour eviter le mot-cle Dart.
- Les payloads de nodes sont types ; aucun `Map<String, dynamic>` global ne porte la logique.
- `ProjectManifest.scenes` est ajoute sans supprimer ni migrer `ProjectManifest.scenarios`.
- `map_core.dart` exporte `scene_asset.dart`.

## Limites V1-03

- Aucun workspace UI Scenes.
- Aucun runtime Scene.
- Aucun adapter `SceneAsset -> ScenarioAsset` ou `ScenarioAsset -> SceneAsset`.
- Aucun diagnostic avance de graph.
- Aucun authoring operation.
- Aucun seed Selbrume ni scene de demonstration.
- Aucun branchement `StorylineStep.sceneLinkIds`.

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
- Decision storage Scene V1 tranchee dans V1-02 et modele core pose dans V1-03.

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
