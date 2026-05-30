# NS-SCENES-V1 — Roadmap Scene Builder Authoring

## Verdict

Roadmap recommandee : **Option C hybride**, avec priorite immediate au Scene Builder Blueprint-like.

Le runtime reste indispensable, mais le prochain blocage produit est plus basique : une personne peut creer une scene draft, mais ne peut pas encore construire visuellement une scene. La suite doit donc poser l'authoring graph avant de brancher Storylines ou d'executer en jeu.

## Prochain lot exact recommande

```text
NS-SCENES-V1-21 — Linked Asset Contracts V0
```

## Principes

- Scene Builder doit devenir un outil Blueprint-like : palette, nodes, ports, edges, payloads, diagnostics.
- Aucun node actif ne doit cacher une fake ref.
- Yarn, battle et cinematic ne deviennent ajoutables que si leur payload draft est honnete ou si un picker existe.
- Runtime ignore toujours `SceneGraphLayout`.
- `ScenarioAsset` reste legacy/bridge, pas modele produit final.
- `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.
- Une Condition no-code doit lire une source metier explicite ; pas de condition textuelle magique ni de flag technique expose comme experience principale.
- Les Facts et World Rules doivent etre cadres avant le golden slice, meme si le premier authoring Condition peut rester limite aux sources existantes.

## Roadmap recommandee

| ID | Titre | Type | Objectif | Non-objectifs | Fichiers probables | Tests attendus | Risques | Criteres d'acceptation | Dependances |
|---|---|---|---|---|---|---|---|---|---|
| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | DONE : Condition, Merge et Fin ajoutables V0 ; Yarn/Action/Battle/Cinematic/Branch desactives jusqu'aux refs/payloads honnetes. | V1-10-bis. |
| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft `condition`, `merge`, `end` dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime, pas de nodes Yarn/Action/Battle/Cinematic/Branch actifs. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si diagnostics trop faibles ; UI trop proche d'un builder complet. | DONE : nodes V0 ajoutables, selection auto, inspector read-only/draft, nodes desactives honnetes, aucun edge automatique. | V1-11. |
| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer des edges simples, valider compatibilite. | Pas de suppression, pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scenes_workspace.dart`, tests. | Tests fromPortId, edge kind derive, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | DONE : edge cree depuis port explicite, no duplicate source port, aucun edge implicite par proximite. | V1-12. |
| NS-SCENES-V1-14 | Blueprint Graph Canvas Foundation / Layout Authoring V0 | core / editor | Ajouter grille, zoom boutons + pinch trackpad, pan, drag node et persistence memoire de `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap, pas de ports graphiques complexes, pas de cable tire a la souris. | `scene_authoring_operations.dart`, graph view, workspace Scenes, widget tests. | Tests update layout, zoom/reset, pinch trackpad non mutant, pan local, drag/persist layout, nodes/edges inchanges, edge visible apres deplacement. | Coupler layout et runtime ; gestes ambigus avec connexion V1-13 ; churn de diffs. | DONE : positions sauvegardees en memoire, zoom/pan locaux, edges suivent les nodes, aucun effet runtime. | V1-13. |
| NS-SCENES-V1-15 | Visual Port Connection UX V0 | editor | Transformer la connexion V1-13 en interaction Blueprint-like : ports visibles, preview wire, highlight/snap, drop sur input. | Pas de runtime, pas de suppression/reconnexion avancee, pas de ports complexes pour nodes desactives. | graph canvas, node cards, connection state tests. | DONE : ports visibles, drag output, preview line, target highlight, drop valide cree edge, drop vide annule. | Reintroduire drag-and-drop trop large ; rendre actifs des nodes sans payload honnete. | DONE : connexion visuelle claire, toujours basee sur ports V0, aucune fake ref. | V1-14. |
| NS-SCENES-V1-15-bis | Edge Selection / Deletion UX V0 | core / editor | Rendre les liens corrigibles : selection locale d'edge, highlight, inspecteur de lien, suppression memoire. | Pas de reconnexion avancee, pas de payload picker, pas de runtime, pas d'edition de condition. | `scene_authoring_operations.dart`, graph view, inspector, workspace Scenes. | Tests remove edge core, selection/highlight inspector, suppression, nodes/layout preserves, creation V1-15 apres suppression. | Supprimer trop large ; casser les ports visuels ou selection node ; confondre edge layout et graph logique. | DONE : edge selectionnable et supprimable, ProjectManifest.scenes mis a jour en memoire, aucune fake ref. | V1-15. |
| NS-SCENES-V1-16-prep | Condition Sources / Facts / World Rules Roadmap Review | doc-only / architecture-review | Decider si Condition Authoring peut commencer sans cadrer Facts, World Rules et sources conditionnelles. | Pas de code, pas de widget, pas de modele, pas de runtime. | rapport V1-16-prep, roadmaps. | `git diff --check` uniquement. | Rester trop abstrait ou bloquer inutilement l'authoring. | DONE : option hybride retenue, prochain lot exact defini, roadmaps ajustees. | V1-15-bis. |
| NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport V1-16, roadmaps. | `git diff --check` uniquement. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | DONE : sources V0 autorisees/reportees, contrat conceptuel, operateurs, diagnostics et pickers definis. | V1-16-prep. |
| NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | DONE : condition configurable via source structuree explicite, diagnostics bloquants si incomplete, picker limite aux refs existantes. | V1-16. |
| NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest`, operations facts, picker Condition, tests serialization/diagnostics. | DONE : tests registry JSON, operations pures, picker Fact, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | DONE : Facts lisibles stockes dans `ProjectManifest.facts`, refs stables, picker prioritaire, fallback technique conserve. | V1-16, V1-17. |
| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
| NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
| NS-SCENES-V1-20-bis | Roadmap Checkpoint Correction | doc-only / roadmap | Corriger l'aiguillage post V1-20 : inserer le checkpoint Narrative Studio demande et eviter de lancer V1-21 automatiquement. | Pas de code, pas de widget, pas de modele, pas de tests, pas de screenshots. | roadmaps + rapport bis. | `git diff --check` uniquement. | Continuer vers runtime sans relire la vision produit ; laisser V1-21 comme prochain implicite. | DONE : V1-20 reste DONE, prochain lot exact devient V1-20-checkpoint, V1-21 reste candidat post-checkpoint, note Facts overview ajoutee. | V1-20. |
| NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite apres World Rules V0. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | DONE : `git diff --check`. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | DONE : Payload Pickers V0 retenu comme V1-21, trajectoire Selbrume revalidee. | V1-20-bis. |
| NS-SCENES-V1-21-prep | Linked Asset Public Contracts Audit | doc-only / architecture-review | Auditer Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et BranchByOutcome avant les pickers. | Pas de code, pas de widget, pas de modele, pas de tests, pas de build_runner. | rapport V1-21-prep, roadmaps. | DONE : `git diff --check`. | Lancer des pickers d'IDs bruts ; confondre contrats publics et implementation interne. | DONE : contrats publics recommandes, node verdicts, V1-21 ajuste vers Linked Asset Contracts V0. | V1-20-checkpoint. |
| NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | Tests contrats/read models purs si code ; sinon `git diff --check`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | Scene Builder sait ce qu'il peut afficher/brancher/diagnostiquer sans lire l'interne complet des assets. | V1-21-prep. |
| NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes en consommant les contrats publics : Yarn, battle, cinematic si contrat pret, action si consequence contract pret. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal. | workspace Scenes, inspector draft controls, projection refs, diagnostics refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes, nodes metier activables seulement avec payload valide. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | Node payloads metier configurables avec vraies refs ou drafts clairement invalides, aucun fake ref. | V1-21. |
| NS-SCENES-V1-23 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link, pas de migration ScenarioAsset. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy ; cibler des scenes incompletes. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-22. |
| NS-SCENES-V1-24 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-22, V1-23 utile. |
| NS-SCENES-V1-25 | Diagnostics / Validator Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions, facts, world rules et Event -> Scene. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, diagnostics world rules/event, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide, erreurs runtime bloquantes explicites. | V1-22, V1-23, V1-24. |
| NS-SCENES-V1-26 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/dialogue/cinematic/battle/action via callbacks limites. | Pas de full bridge ScenarioAsset, pas StorylineStep link, pas de consequences persistantes implicites. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-24, V1-25. |
| NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule pickers, diagnostics. | Tests affichage contextuel, picker target, refs inconnues, overview toujours coherent. | World Rules inutilisables si seulement en overview ; UI trop large. | Les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts. | V1-20, V1-25 utile. |
| NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-22, V1-23, V1-26, V1-27. |
| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28. |

## Options comparees

| Option | Verdict | Raison |
|---|---|---|
| A — Continuer directement RuntimePlan puis StorylineStep | Rejetee | RuntimePlan seul ne rend pas le builder utilisable ; StorylineStep link trop tot confond progression et declencheur. |
| B — Basculer uniquement graph authoring | Rejetee partiellement | Aligne bien Blueprint-like, mais risque de creer des graphes sans contrat runtime. |
| C — Hybride Blueprint + sources metier + runtime plan | Retenue | Garde le builder utilisable, evite les conditions textuelles magiques, puis enchaine Fact/World Rules, runtime plan, Event -> Scene avant StorylineStep. |
| D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |

## Mise a jour V1-11

Statut : `NS-SCENES-V1-11 — Scene Graph Draft Node Strategy` est DONE.

Decision : le premier authoring de nodes doit rester tres strict. En V0, seuls `condition`, `merge` et `end` deviennent ajoutables, car ils peuvent etre crees avec le modele actuel sans reference inventee. `start` reste unique. `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` restent visibles mais desactives dans la future palette tant que leurs refs, source outcomes ou action kinds ne sont pas honnetes.

Prochain lot exact : `NS-SCENES-V1-12 — Node Authoring V0`.

## Mise a jour V1-12

Statut : `NS-SCENES-V1-12 — Node Authoring V0` est DONE.

Decision : V1-12 a code seulement les nodes autorises par V1-11. La palette V0 active `Condition`, `Merge` et `Fin`. Les nodes `Début`, `Dialogue`, `Action`, `Combat`, `Cinématique` et `Branche` restent desactives avec raison courte. Aucun edge n'est cree automatiquement.

Prochain lot exact : `NS-SCENES-V1-13 — Edge Authoring V0`.

## Mise a jour V1-13

Statut : `NS-SCENES-V1-13 — Edge Authoring V0` est DONE.

Decision : V1-13 ajoute seulement la creation explicite d'edges V0. Les ports authorables sont `start.completed`, `condition.true`, `condition.false` et `merge.completed`. `SceneEdge.kind` est derive du port. Le mode connexion editor est local : node source selectionne, bouton de port, clic sur node cible. La selection reste sur la source apres creation pour connecter les branches d'une condition.

Limites : aucun drag and drop, aucune suppression d'edge, aucune reconnexion avancee, aucune preview line, aucun runtime, aucun StorylineStep link.

Prochain lot exact : `NS-SCENES-V1-14 — Layout Authoring V0`.

## Mise a jour V1-14

Statut : `NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0` est DONE.

Decision : V1-14 elargit `Layout Authoring V0` en socle canvas Blueprint-like. Le Scene Builder affiche une grille, des controles zoom/reset, le pinch trackpad MacBook, un pan local et des nodes deplacables. Le drag persiste uniquement `SceneGraphLayout` dans `ProjectManifest.scenes` en memoire ; `SceneGraph.nodes` et `SceneGraph.edges` restent inchanges. Les edges suivent les positions courantes, la selection et l'inspecteur restent coherents, et la connexion V1-13 reste fonctionnelle.

Limites : pas de ports visuels connectables, pas de preview line de connexion, pas de suppression/reconnexion avancee, pas de minimap, pas d'auto-layout, pas de runtime.

Prochain lot exact : `NS-SCENES-V1-15 — Visual Port Connection UX V0`.

## Mise a jour V1-15

Statut : `NS-SCENES-V1-15 — Visual Port Connection UX V0` est DONE.

Decision : les ports visuels V0 sont maintenant presents sur le canvas. L'auteur peut dragger depuis un output authorable, voir un cable de preview, beneficier d'un highlight/snap sur les inputs compatibles, puis dropper sur un input pour creer un edge via la meme operation V1-13. Drop hors cible annule sans mutation.

Limites : pas de suppression/reconnexion, pas de ports actifs pour Yarn/Action/Battle/Cinematic/Branch, pas d'edition de payload, pas de runtime.

Prochain lot exact : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review`.

## Mise a jour V1-15-bis

Statut : `NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0` est DONE.

Decision : V1-15-bis ajoute la correction des liens sans ouvrir la reconnexion avancee. Une operation pure `removeSceneEdgeDraft` supprime l'edge cible et conserve le reste du SceneAsset. Cote editor, l'edge est selectionnable, highlight dans le canvas, visible dans un inspecteur de lien, puis supprimable via `Supprimer le lien`. La selection edge est locale et reset apres suppression.

Limites : pas de reconnexion, pas de suppression node, pas de payload picker, pas de runtime, pas d'edition Condition.

Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

## Mise a jour V1-16

Statut : `NS-SCENES-V1-16 — Condition Sources Contract V0` est DONE.

Decision : le contrat V0 autorise seulement les sources qu'on peut exposer sans inventer de refs : fait existant technique fact-like, step complete/non complete et event consomme/non consomme. `ScriptCondition` reste un backend technique, pas une UX. Les sources inventory, party, script variables, trainer defeated dedie, dialogue/battle outcomes et World Rules sont reportees jusqu'aux pickers, registries ou runtime plans correspondants.

Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune Fact Registry, aucune World Rule.

Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

## Mise a jour V1-16-prep

Statut : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review` est DONE.

Decision : Condition Authoring V0 ne doit pas commencer par un payload texte libre. Le Scene Builder doit d'abord cadrer les sources de condition lisibles, leur mapping vers l'existant (`GameState`, `ScriptCondition`, story progression, map/event state), les pickers requis et les diagnostics. La roadmap insere donc `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis deplace l'authoring effectif en `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

Limites : aucune Fact Registry, World Rule, UI Condition ou runtime n'est code dans V1-16-prep.

Prochain lot exact : `NS-SCENES-V1-16 — Condition Sources Contract V0`.

## Mise a jour V1-17

Statut : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)` est DONE.

Decision : V1-17 code l'authoring no-code d'un `ConditionNode` a source unique. Les sources V0 actives sont `factLikeStoryFlag`, `storyStepCompletion` et `consumedEvent`, selectionnees depuis des refs existantes derivees du projet. Le payload reste structure via `SceneConditionSource`; aucun texte libre, ID fake, runtime ou World Rule n'est introduit. Une condition incomplete devient une erreur authoring, ce qui garde les scenes non executables tant que le payload n'est pas honnete.

Limites : pas de Fact Registry, pas de sources inventory/party/dialogue outcome/battle outcome/script variable/world state, pas de AND/OR, pas de payload picker Yarn/Battle/Cinematic, pas de runtime, pas de StorylineStep link, pas d'Event -> Scene.

Prochain lot exact : `NS-SCENES-V1-18 — Fact Registry V0`.

## Mise a jour V1-18

Statut : `NS-SCENES-V1-18 — Fact Registry V0` est DONE.

Decision : V1-18 ajoute une registry authoring bool-first via `ProjectManifest.facts` et `NarrativeFactDefinition`. Les Facts portent un id stable, un label lisible, une description, une categorie, une valeur par defaut, des tags et un lien optionnel vers un flag legacy. Les operations pures d'ajout, mise a jour et suppression preservent le manifest original, et la suppression refuse les Facts encore references par une condition Scene V1.

Integration Scene Builder : le picker Condition expose les Facts de registry comme source prioritaire `SceneConditionSourceKind.fact`. Les refs fact-like legacy restent disponibles comme fallback technique, sans migration automatique ni conversion destructive.

Limites : bool-only, pas de registry editor dediee, pas de World Rules, pas de runtime, pas de Event -> Scene, pas de StorylineStep link, pas de donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-19 — World Rule Contract V0`.

## Mise a jour V1-19

Statut : `NS-SCENES-V1-19 — World Rule Contract V0` est DONE.

Decision : une World Rule V0 est une regle authoring declarative, inspectable et validable. Elle lit une source metier (`Fact`, `StoryStep completed/notCompleted`, `consumed event`) et projette un effet visible/actif sur une cible explicite du monde. Elle n'est pas un script cache, une action one-shot de Scene, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.

Stockage futur recommande : registry projet canonique avec targets explicites, plus affichage contextuel dans Map Editor/entity inspector. Les implementations existantes `MapEntityNpcVisibilityRule`, `MapEntityConditionalDialogue`, `MapEntityRuntimePredicateEvaluator`, `NpcMapPresencePredicate` et `StepStudioWorldPresenceRule` servent d'inspiration ou de bridge, pas de modele produit final.

Effets V0 recommandes : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si les refs sont validables. Les collisions dynamiques, warps dynamiques, deplacements d'entites et ambiances/map state sont repousses.

Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime et aucune donnee Selbrume ne sont ajoutes.

Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.

## Mise a jour V1-20

Statut : `NS-SCENES-V1-20 — World Rules V0` est DONE.

Decision : V1-20 ajoute une registry canonique `ProjectManifest.worldRules` et un modele `WorldRuleDefinition` declaratif. Les sources V0 supportees sont `Fact`, `StoryStep completion` et `consumed event`. Les targets V0 sont `mapEntity`, `npcDialogue` et `mapEvent`. Les effets V0 sont `entityVisible`, `entityHidden`, `npcDialogueOverride`, `eventEnabled`, `eventDisabled` et `eventHidden`.

Integration : les operations pures `addWorldRule`, `updateWorldRule` et `removeWorldRule` preservent le manifest original et refusent les mismatches. `diagnoseWorldRules` couvre refs inconnues, predicates incompatibles, target/effect mismatch, conflits de priorite et labels techniques. `projectWorldRuleEffects` fournit une projection pure depuis `GameState`, sans mutation ni runtime. L'overview du Narrative Studio affiche compteur, diagnostics et premiers labels World Rules.

Limites : pas d'ecran dedie World Rules, pas de picker map/entity/event/dialogue, pas de runtime Scene, pas d'Event -> Scene, pas de StorylineStep link, pas de collision/warp/tile/ambience dynamique, pas de donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

## Mise a jour V1-20-bis

Statut : `NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction` est DONE.

Decision : V1-20 reste fonctionnellement accepte et DONE. La roadmap ne doit cependant pas lancer automatiquement `NS-SCENES-V1-21 — Scene Runtime Plan V0`. Le prochain lot exact est corrige en `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

Raison : le Scene Builder, les Conditions, la Fact Registry et les World Rules forment maintenant un socle produit assez avance pour relire la vision Narrative Studio avant de choisir le prochain axe. Le checkpoint doit arbitrer entre Runtime Plan, Event -> Scene, World Rules reliees au Map Editor, Payload Pickers, Diagnostics/Validator et trajectoire golden slice Selbrume.

Impact V1-21 : `NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais n'est plus le prochain lot automatique.

Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que `NS-SCENES-V1-18 — Fact Registry V0` existe. Ce polish/alignement UI doit etre traite dans un lot futur ou pendant le checkpoint, sans code dans V1-20-bis.

Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

## Mise a jour V1-20-checkpoint

Statut : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint` est DONE.

Decision : apres relecture de la vision Narrative Studio et du golden slice Selbrume, le prochain lot exact devient `NS-SCENES-V1-21 — Payload Pickers V0`. Le Runtime Plan reste indispensable, mais il est repousse apres la configuration honnete des payloads metier et apres la preparation Event -> Scene, car un plan runtime sur des scenes sans refs Yarn/Cinematic/Battle/Action debloquerait peu de valeur produit.

Comparaison retenue : Event -> Scene est prioritaire pour Selbrume, mais il doit cibler une Scene capable de contenir un dialogue Yarn, une cinematic, un battle et des actions avec de vraies refs. Diagnostics/Validator doit suivre quand ces refs existent. World Rules Map Editor Integration reste necessaire avant le golden slice complet, mais ne bat pas les Payload Pickers comme prochain lot.

Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune donnee Selbrume et aucun StorylineStep link n'est ajoute dans le checkpoint.

Prochain lot exact : `NS-SCENES-V1-21 — Payload Pickers V0`.

## Mise a jour V1-21-prep

Statut : `NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit` est DONE.

Decision : les Payload Pickers ne doivent pas demarrer directement. Le Scene Builder doit stocker des refs stables, mais il doit aussi lire des contrats publics minimaux pour afficher, brancher et diagnostiquer les nodes metier. Ces contrats doivent exposer labels, existence, statut, diagnostics, outputs/outcomes et contraintes sans reveler toute l'implementation interne de Dialogue Yarn, Cinematic/Cutscene, Battle ou Action.

Verdict par famille : Dialogue/Yarn et Battle/Trainer sont les plus proches d'un picker honnete, mais leurs contracts publics doivent etre formalises avant UI. Cinematic/Cutscene reste dangereux tant que Cutscene Studio compile vers `ScenarioAsset` sans vrai contrat cinematic canonique. Action/Consequence reste trop disperse entre ScriptAsset, ScenarioRuntimeExecutor, Facts et World Rules. BranchByOutcome reste disabled tant que les producteurs d'outcomes et les mappings outcome -> edge ne sont pas explicites.

Roadmap : `NS-SCENES-V1-21 — Linked Asset Contracts V0` devient le prochain lot exact. `Payload Pickers V0` est decale en V1-22. `Event -> Scene` reste prioritaire apres que les scenes puissent pointer vers des contenus metier honnetes. `Scene Runtime Plan V0` reste necessaire ensuite. `StorylineStep.sceneLinkIds` reste repousse.

Limites : aucun code, widget, modele, test, build_runner, runtime, Event -> Scene, StorylineStep link, fake data ou donnee Selbrume n'est ajoute.

Prochain lot exact : `NS-SCENES-V1-21 — Linked Asset Contracts V0`.

## Selbrume golden slice

Avant le golden slice, il faut au minimum :

- Node Authoring V0.
- Edge Authoring V0.
- Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
- Linked Asset Contracts V0 avant Payload Pickers, pour eviter que les pickers ne soient de simples selecteurs d'IDs bruts.
- Payload Pickers V0 pour Yarn, battle, cinematic/action.
- Event to Scene Trigger Prep pour relier map/event et Scene V1 sans StorylineStep comme declencheur.
- Scene Runtime Plan V0 pour compiler une Scene valide en intents sans layout.
- Diagnostics Expansion.
- World Rules V0 pour les consequences visibles controlees.
- Narrative Studio Direction Checkpoint pour choisir l'ordre runtime / map events / payloads / validator.
- Scene Runtime Executor MVP.
- World Rules Map Editor Integration V0 pour relire les consequences depuis les cibles map/entity.

Peut attendre apres le slice :

- StorylineStep -> Scene Link complet.
- World Rule editor avance au-dela des effets V0.
- Fact registry avance.
- Cinematic editor avance si une cinematic fixture controlee suffit.
