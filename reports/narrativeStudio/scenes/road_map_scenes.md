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
| NS-SCENES-V1-07 — Node Inspector Read-only | DONE | Selection locale de node dans le graph read-only, inspecteur read-only du payload et des edges entrants/sortants, sans authoring ni mutation. |
| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | DONE | Creation d'une SceneAsset draft minimale depuis le workspace Scenes, ajout en memoire dans `ProjectManifest.scenes`, selection auto et graph/inspector read-only. |
| NS-SCENES-V1-09 — Scene Validation Diagnostics | DONE | Diagnostics Scene V1 purs dans `map_core` et affichage editor : erreurs/warnings de graph, layout et outcomes, sans mutation ni correction automatique. |
| NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
| NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment | DONE | Roadmap reconcilee : priorite au Scene Builder Blueprint-like, runtime plan conserve mais decale apres authoring graph minimal. |
| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | DONE | Strategie retenue : activer seulement Condition, Merge et Fin en V0 ; garder Start unique et desactiver Yarn/Action/Battle/Cinematic/Branch tant que les refs/payloads ne sont pas honnetes. |
| NS-SCENES-V1-12 — Node Authoring V0 | DONE | Operation pure `addSceneNodeDraft` et palette editor V0 : ajout Condition / Merge / Fin en memoire, selection auto, aucun edge automatique ni fake ref. |
| NS-SCENES-V1-13 — Edge Authoring V0 | DONE | Operation pure `addSceneEdgeDraft` et UI de connexion V0 : ports explicites start.completed, condition.true/false, merge.completed, edge kind derive, mise a jour memoire sans runtime. |
| NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0 | DONE | Canvas Blueprint-like de base : grille, zoom local par boutons et pinch trackpad, pan local, deplacement de nodes, persistence memoire de `SceneGraphLayout`, edges qui suivent, sans impact runtime. |
| NS-SCENES-V1-15 — Visual Port Connection UX V0 | DONE | Ports visuels V0, drag depuis output, preview wire, highlight/snap des inputs compatibles, drop valide cree un edge via les regles V1-13, drop vide annule. |
| NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0 | DONE | Selection locale d'edge, highlight visuel, inspecteur de lien et suppression d'edge en memoire via operation pure, sans runtime ni reconnexion avancee. |
| NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review | DONE | Revue architecture/roadmap : refuser une Condition V0 textuelle magique, cadrer sources metier, Facts, World Rules et consequences avant authoring payload. |
| NS-SCENES-V1-16 — Condition Sources Contract V0 | DONE | Contrat no-code des sources de condition : sources V0 autorisees, sources reportees, mapping technique, operateurs, pickers et diagnostics, sans code ni UI. |
| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | TODO | Configurer un `ConditionNode` V0 uniquement avec des sources existantes et honnetes, sans texte magique ni refs inventees. |
| NS-SCENES-V1-18 — Fact Registry V0 | TODO | Ajouter une registry authoring de Facts lisibles, bool-first, preparant les pickers no-code et le mapping runtime vers l'etat persistant. |
| NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions, sans encore brancher tout le runtime. |
| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier authoring/validation de World Rules controlees : visibilite, dialogue, portes/collisions ou map state selon contrat. |
| NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
| NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
| NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
| NS-SCENES-V1-24 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume. |
| NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
| NS-SCENES-V1-26 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
| NS-SCENES-V1-27 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers et runtime MVP stabilises. |

## Prochain lot recommande

`NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`

Raison : V1-16 fixe maintenant le contrat no-code des sources conditionnelles. Le prochain lot peut coder l'authoring d'un `ConditionNode` limite aux sources V0 autorisees, sans expression libre, sans Fact Registry, sans World Rules et sans runtime.

## Decisions V1-16

- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
- Sources V0 autorisees : fait existant technique (`storyFlag` fact-like), step complete/non complete, event consomme/non consomme.
- Sources V0 reportees : step active, inventory/item possession, party/move state, script variables, trainer defeated dedie, dialogue outcome local, battle outcome local, world state / World Rule.
- Le contrat conceptuel retient une forme `sourceKind`, `sourceId`, `field`, `operator`, `value`, `label`, `debugTechnicalLabel`, sans creer de classe Dart dans ce lot.
- V0 = une condition simple par `ConditionNode`; pas de AND/OR libre. La composition se fait par le graph avec nodes et edges.
- Operateurs V0 : `isTrue`, `isFalse`, et `equals` limite aux statuts enumeres supportes.
- Les sources temporaires fact-like doivent etre presentees comme "faits existants techniques" et migrees/wrappees par `Fact Registry V0`.
- Les diagnostics contractuels prioritaires sont : source manquante/inconnue, operateur manquant/non supporte, valeur manquante, source future, picker requis, id technique brut.
- Prochain lot : coder seulement l'authoring des sources autorisees, avec diagnostics et refus runtime futur si erreur.

## Limites V1-16

- Pas de `FactRegistry`.
- Pas de `WorldRule`.
- Pas de modification `SceneAsset` ou `ProjectManifest`.
- Pas de Condition UI codee.
- Pas de payload picker code.
- Pas de runtime Scene.
- Pas de StorylineStep link, Event -> Scene ou donnee Selbrume.

## Tests V1-16

- Dart analyze non requis : lot documentation-only.
- Flutter analyze non requis : lot documentation-only.
- Dart test non requis : lot documentation-only.
- Flutter test non requis : lot documentation-only.
- Verification requise : `git diff --check`.

## Decisions V1-16-prep

- Le lot est documentation-only : aucun code, widget, modele, runtime, test ou fixture n'est modifie.
- `Condition Authoring V0` immediat avec label/draft textuel est rejete : il recreerait un editeur de flags techniques.
- Option retenue : hybride pragmatique. Inserer `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
- Les Conditions Scene V1 devront lire des sources metier explicites : Facts, StorySteps, resultats locaux de dialogue/combat, inventaire, party, map/event state, variables authoring et World State.
- Un Fact PokeMap est un fait lisible du monde, pas seulement un flag brut. V0 doit etre bool-first, mappe au runtime via `GameState.storyFlags` ou equivalent, puis evoluer vers types number/text/enum avec registry.
- Une World Rule est une regle visible/efficace du monde derivee de Facts/Steps/conditions ; elle doit etre cadree avant le golden slice Selbrume, mais ne bloque pas un Condition Authoring V0 limite aux sources existantes.
- Les actions/consequences doivent rester explicites : un SceneOutcome local ne devient Fact, Step completed ou World Rule que via une action/consequence authorisee.
- `Event -> Scene` reste prioritaire sur `StorylineStep -> Scene`; `StorylineStep.sceneLinkIds` reste repousse apres builder, triggers, runtime MVP et golden slice.

## Limites V1-16-prep

- Pas de Fact Registry codee.
- Pas de World Rule codee.
- Pas de Condition UI codee.
- Pas de nouveau payload, JSON, Freezed ou build_runner.
- Pas de runtime, Event -> Scene, StorylineStep link ou donnee Selbrume.

## Tests V1-16-prep

- Dart analyze non requis : lot documentation-only.
- Flutter analyze non requis : lot documentation-only.
- Dart test non requis : lot documentation-only.
- Flutter test non requis : lot documentation-only.
- Verification requise : `git diff --check`.

## Decisions V1-15-bis

- Operation pure ajoutee : `removeSceneEdgeDraft(SceneAsset, edgeId)`.
- L'operation refuse un edge inconnu, supprime uniquement l'edge cible, conserve les nodes, outcomes, tags, metadata, description, storylineId et chapterId.
- Les `SceneEdgeLayout` du lien supprime sont retires par necessite de validation du modele ; les layouts des autres edges et des nodes restent preserves.
- Cote editor, un edge peut etre selectionne depuis son badge canvas.
- L'edge selectionne est mis en evidence visuellement dans le canvas.
- L'inspecteur affiche `Edge ID`, source node, source port, target node, kind, label et l'action `Supprimer le lien`.
- La suppression met a jour uniquement `ProjectManifest.scenes` en memoire et reset la selection d'edge.
- La creation visuelle V1-15 reste fonctionnelle apres suppression.
- Aucun runtime, aucun StorylineStep link, aucune fake ref.

## Limites V1-15-bis

- Pas de reconnexion avancee.
- Pas de suppression de node.
- Pas de payload picker.
- Pas d'edition de condition.
- Pas de confirmation modale pour la suppression d'un lien V0.

## Tests V1-15-bis

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-15

- Ports visuels ajoutes sur les nodes V0 : input `in` sur condition/merge/end, outputs `completed`, `true`, `false` selon les ports V1-13.
- Drag depuis un output authorable cree un etat local de connexion visuelle.
- Preview wire dessine un cable temporaire qui suit le pointeur.
- Les ports d'entree compatibles sont mis en evidence ; le port le plus proche est snappe dans un rayon borne.
- Drop sur un input compatible appelle l'operation V1-13 existante via le callback editor, donc `SceneEdge.kind`, duplicate source port, self-loop et ports invalides restent valides par le core.
- Drop hors cible annule sans mutation.
- Les outputs deja utilises restent visibles mais non actifs.
- Aucun runtime, aucun StorylineStep link, aucune fake ref.

## Limites V1-15

- Pas de suppression ni reconnexion avancee.
- Pas de port visuel pour Yarn/Action/Battle/Cinematic/Branch.
- Pas d'edition de payload.
- L'ancien toolbar de connexion reste disponible comme fallback, mais la voie Blueprint-like est maintenant le drag visuel des ports.

## Tests V1-15

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-14

- Operation pure ajoutee : `updateSceneNodeLayout(SceneAsset, nodeId, x, y)`.
- L'operation met a jour ou cree uniquement le `SceneNodeLayout` du node cible.
- `SceneGraph.nodes`, `SceneGraph.edges`, `declaredOutcomes`, tags, metadata, description, storylineId et chapterId sont preserves.
- Cote editor, le canvas Scene affiche une grille tokenisee, un zoom local 50 % / 200 % par boutons et pinch trackpad, un reset 100 %, un pan local et le deplacement des nodes.
- Le zoom et le pan restent locaux et ne modifient pas `ProjectManifest`.
- Le deplacement d'un node persiste en memoire uniquement `ProjectManifest.scenes[*].layout.nodeLayouts`.
- Les edges utilisent les positions courantes des nodes et suivent donc les deplacements.
- La selection locale de node et l'inspecteur restent coherents apres drag.
- La connexion V1-13 reste disponible ; pendant le mode connexion, le drag node est desactive pour eviter les gestes ambigus.
- Aucun runtime, aucun StorylineStep link, aucune donnee Selbrume, aucune fake ref.

## Limites V1-14

- Pas encore de ports visuels connectables sur les cards.
- Pas de cable Blueprint tire a la souris ni preview line de connexion.
- Pas de suppression/reconnexion avancee.
- Pas de minimap ni auto-layout complet.
- Pas de persistence disque explicite.

## Tests V1-14

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-13

- Operation pure ajoutee : `addSceneEdgeDraft(SceneAsset, fromNodeId, fromPortId, toNodeId, label?)`.
- Source de verite pure ajoutee : `authorableSceneOutputPortsForNode` / `authorableSceneOutputPortsForKind`.
- Ports supportes V0 :
  - `start.completed` -> `SceneEdgeKind.defaultFlow` ;
  - `condition.true` -> `SceneEdgeKind.conditionTrue` ;
  - `condition.false` -> `SceneEdgeKind.conditionFalse` ;
  - `merge.completed` -> `SceneEdgeKind.defaultFlow`.
- `fromPortId` est toujours explicite et `edge.kind` est derive du port, jamais choisi librement par l'utilisateur.
- `end`, `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` ne proposent aucune sortie authorable V0.
- Les edges depuis source inconnue, vers cible inconnue, depuis port inconnu, depuis `end`, depuis node source desactive, les self-loops et le deuxieme edge sortant depuis un meme `fromNodeId/fromPortId` sont refuses.
- Les IDs d'edge sont stables : `edge_<fromNodeId>_<fromPortId>_<toNodeId>` avec suffixe numerique en collision.
- Cote editor, le mode connexion est local : selection node source -> bouton port -> clic node cible -> mise a jour en memoire de `ProjectManifest.scenes`.
- Apres creation, la selection reste sur le node source pour permettre de connecter `condition.true` puis `condition.false`.
- Aucun edge automatique, aucun drag and drop, aucune suppression/reconnexion avancee, aucun runtime.

## Limites V1-13

- Pas de layout authoring interactif.
- Pas de suppression d'edge.
- Pas de preview line pendant le mode connexion.
- Pas de ports graphiques connectables complexes.
- Pas de diagnostics `missingRequiredOutput`; ils restent pour Diagnostics Expansion.
- Pas de Yarn/Action/Battle/Cinematic/Branch authoring actif.

## Tests V1-13

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-12

- Operation pure ajoutee : `addSceneNodeDraft(SceneAsset, kind, title?, afterNodeId?)`.
- Nodes supportes : `condition`, `merge`, `end`.
- Nodes refuses : `start`, `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome`.
- Generation d'IDs stable : `node_condition`, `node_merge`, `node_end_2`, avec suffixe numerique en collision.
- Layout initial stable : a droite du node cible si layout disponible, sinon a droite du node le plus a droite, sinon fallback par index.
- Les edges existants, declared outcomes, tags, metadata, storylineId/chapterId et description sont preserves.
- L'operation ne mute jamais la scene originale.
- Cote editor, `ProjectManifest.scenes` est remplace en memoire uniquement pour la scene cible.
- La palette affiche Condition / Merge / Fin actifs, et les autres node kinds desactives avec raison courte.
- Le node ajoute est selectionne automatiquement et l'inspector affiche ce node.
- Aucun edge automatique, aucun payload picker, aucun runtime.

## Limites V1-12

- Pas de diagnostics draft payload supplementaires ; `conditionIncomplete` reste pour V1-17.
- Pas d'edge authoring ni ports connectables.
- Pas de layout authoring interactif.
- Pas de Yarn/Action/Battle/Cinematic/Branch actif.
- Pas d'Event -> Scene ni `StorylineStep.sceneLinkIds`.

## Decisions V1-11

- Strategie retenue : `SceneAsset` reste le modele authoring canonique et peut porter certains drafts incomplets, mais seulement quand le payload est honnete et diagnostiquable.
- Option B retenue avec garde-fous : pas de modele `SceneDraft` separe en V1, pas de wizard obligatoire pour chaque node, mais pas de reference factice.
- Nodes ajoutables en V0 : `condition`, `merge`, `end`.
- Nodes desactives en V0 : `start` (unique), `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome`.
- `condition` peut etre ajoute avec payload vide et diagnostic `conditionIncomplete` futur ; il expose `true` / `false`.
- `merge` peut etre ajoute avec payload vide ; il sert a rejoindre plusieurs branches et expose `completed/default`.
- `end` peut etre ajoute avec `SceneEndPayload` vide ; plusieurs fins sont autorisees.
- `yarnDialogue`, `battle`, `cinematic` attendent des pickers ou une strategie explicite de payload draft.
- `action` attend un registre/action picker ou un `actionKind` draft officiel, pas une chaine bidon.
- `branchByOutcome` attend une strategie de source outcome et de mappings, meme si le modele accepte un payload vide.
- Les diagnostics futurs devront bloquer l'execution runtime si un node draft reste incomplet.
- Le prochain lot code seulement l'ajout de nodes draft V0 et la palette correspondante.

## Limites V1-11

- Documentation-only : aucun code, widget, modele ou test.
- Aucune palette n'est codee.
- Aucune operation d'authoring n'est codee.
- Aucun diagnostic supplementaire n'est code.
- Aucun runtime, event trigger ou StorylineStep link n'est branche.

## Decisions V1-10-bis

- Option recommandee : roadmap hybride orientee Blueprint-like.
- Ne pas continuer directement vers `StorylineStep to Scene Link`.
- Ne pas faire `SceneRuntimePlan V0` immediatement si le builder ne sait toujours pas creer de graph utile.
- Inserer d'abord `Scene Graph Draft Node Strategy`, puis `Node Authoring V0`, `Edge Authoring V0`, `Layout Authoring V0`.
- Conserver `SceneRuntimePlan V0` tot dans la suite, mais apres les premiers lots d'authoring graph.
- Placer `Event -> Scene Trigger Prep` avant `StorylineStep -> Scene Link`, car Selbrume demarre surtout les scenes depuis des events de map.
- Garder `StorylineStep.sceneLinkIds` desactive jusqu'a builder + triggers + runtime MVP stabilises.
- La roadmap detaillee Blueprint-like vit aussi dans `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

## Limites V1-10-bis

- Documentation-only : aucun code, widget, modele ou runtime.
- Aucun node authoring n'est ajoute.
- Aucun event trigger n'est branche.
- Aucun seed Selbrume ni scene de reference n'est cree.

## Decisions V1-10

- Decision principale : ne pas brancher encore le runtime Scene V1.
- Prochain objet technique recommande : `SceneRuntimePlan` pur cote `map_core`, derive de `SceneAsset` + `diagnoseScene`.
- `SceneRuntimePlan` doit ignorer completement `SceneGraphLayout`.
- Les scenes avec diagnostics `error` ne doivent pas etre executables ; elles doivent produire une erreur runtime/authoring lisible.
- `ScenarioRuntimeExecutor` reste supporte comme runtime legacy et source d'inspiration, mais ne devient pas le contrat Scene V1.
- Pas de conversion automatique `SceneAsset -> ScenarioAsset` au save, ni migration destructive.
- Le mapping cible est `SceneNodeKind -> SceneRuntimeIntent`, puis un futur adapter `map_runtime` executera ces intents.
- Les outcomes locaux restent non persistants par defaut ; seule une action explicite pourra persister un Fact, flag ou StoryStep.
- Le lien `StorylineStep -> Scene` est repousse apres `SceneRuntimePlan V0`.

## Limites V1-10

- Documentation-only : aucun modele runtime code n'est cree.
- Pas de tests/analyze requis hors `git diff --check`.
- Pas de modification `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle`.
- Pas de hook runtime map/event, pas d'ouverture Yarn, pas de battle handoff Scene V1, pas de cinematic playback Scene V1.

## Decisions V1-09

- Les diagnostics Scene V1 vivent dans `map_core/lib/src/diagnostics/scene_diagnostics.dart`.
- `diagnoseScene` est pur, deterministe et ne mute jamais `SceneAsset`.
- Les diagnostics couvrent start, end, edges, layout, outcomes declares/emis et graph quasi vide.
- Les cas start/edge/layout inconnus restent surtout documentaires car les constructeurs `SceneGraph` / `SceneAsset` les refusent deja.
- Le workspace Scenes affiche les compteurs dans l'arborescence et les messages dans l'inspecteur read-only.
- Aucun bouton de correction automatique ni authoring supplementaire n'est ajoute.

## Limites V1-09

- Pas de Validator global.
- Pas de diagnostics runtime, Yarn, Battle ou Cinematic resolus.
- Pas de correction automatique.
- Pas d'edition de node, edge, payload ou layout.

## Decisions V1-08

- Le bouton `Créer une scène` ouvre un dialog minimal nom + description optionnelle.
- Le bouton est place dans la barre de l'arborescence pour garder le graph dominant.
- Le nom vide est refuse dans le dialog.
- La creation passe par `createSceneDraftInProject`, operation pure `map_core`.
- Les ids de scene sont slugifies avec prefixe `scene_` et suffixe numerique en cas de collision.
- La scene draft contient uniquement `node_start`, `node_end`, `edge_start_end`, layout start/end et aucune metadata metier.
- La mutation touche uniquement `ProjectManifest.scenes` en memoire via `EditorNotifier.applyInMemoryProjectManifest`.
- La scene creee est selectionnee, puis `node_start` est selectionne dans l'inspecteur read-only.
- Aucun authoring de node, edge, payload, layout, runtime ou Storylines n'est ajoute.

## Limites V1-08

- Pas d'edition de scene existante.
- Pas d'ajout ou edition de node/edge.
- Pas de drag and drop layout.
- Pas de persistence disque explicite.
- Pas de diagnostics Scene V1 avant V1-09.

## Decisions V1-07

- Le graph read-only accepte une selection locale de node par clic.
- Le start node est selectionne automatiquement quand il existe, sinon le premier node reel.
- La selection de node est recalculee quand la scene locale change.
- L'inspecteur read-only affiche kind, id, titre, description, payload summary et edges entrants/sortants.
- Les payloads `start`, `end`, `yarnDialogue`, `condition`, `action`, `battle`, `cinematic`, `branchByOutcome` et `merge` ont un resume dedie.
- Aucun `TextField`, bouton sauver/supprimer/dupliquer, drag and drop, runtime ou mutation `ProjectManifest` n'est ajoute.

## Limites V1-07

- Pas d'edition de node, payload, edge ou layout.
- Pas de diagnostics avances.
- Pas de resolution des references Yarn, combat ou cinematic.
- Pas de StorylineStep.sceneLink.

## Decisions V1-06

- Le placeholder `Graph — bientôt` est remplace par `SceneGraphReadOnlyView`.
- Le graph lit `scene.graph.nodes`, `scene.graph.edges` et `scene.layout.nodeLayouts`.
- Un layout persiste complet est utilise tel quel.
- Si le layout est absent ou incomplet, un layout derive deterministe est calcule en memoire et non persiste.
- Les edges sont dessines par un `CustomPainter` read-only avec couleurs injectees depuis le theme.
- Les labels d'edges viennent de `SceneEdge.label` ou du couple `kind/fromPortId`.
- Aucun node inspector, drag and drop, edition de node/edge ou runtime n'est ajoute.

## Decisions V1-06-bis

- NS-SCENES-V1-06-bis — fallback layout hardening : DONE.
- Le layout derive utilise maintenant un parcours borne avec `visited`.
- Les cycles et composants deconnectes ne peuvent plus bloquer le rendu read-only.
- Le layout persiste complet reste prioritaire et aucun `SceneAsset.layout` n'est mute.
- Le prochain lot reste `NS-SCENES-V1-07 — Node Inspector Read-only`.

## Limites V1-06

- Layout derive simple et borne, suffisant pour V1-06-bis mais pas un moteur de graph final.
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
