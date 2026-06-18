# NS-EVENT-25 — Outcomes / Reactions / Consequences Contract Alignment Audit

Statut : DONE — audit documentaire uniquement.

Fichier créé : `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`

## 1. Résumé exécutif

NS-EVENT-25 tranche la frontière canonique entre Event, Scene, outcomes, réactions, conséquences, Facts, Story Steps et World Rules.

Verdict :

```text
Option recommandée : Option C — Contrat hybride lifecycle strict.
```

Définition retenue :

```text
Event possède :
- source / déclencheur ;
- conditions d’entrée simples ;
- Scene cible ;
- intention lifecycle : oneShot / reusable ;
- diagnostics indiquant si cette intention est réellement couverte.

Scene possède :
- orchestration dialogue / battle / cinematic ;
- outcomes ;
- branches / ports ;
- conséquences persistantes directes ;
- réactions narratives par branche ou par outcome.

Runtime possède :
- exécution transactionnelle de Scene ;
- staging puis commit des SceneConsequence ;
- projection des outcomes runtime vers ports de Scene ;
- écriture GameState.

World Rule possède :
- projection passive du GameState vers le monde visible.
```

Décision ferme :

```text
L’Event Builder ne doit PAS déclarer ses propres outcomes.
L’Event Builder ne doit PAS devenir propriétaire des réactions post-outcome.
L’Event Builder doit afficher Résultats / Réactions / Monde en lecture, depuis la Scene liée et les projections existantes.
```

Point de risque majeur :

```text
EventBuilderReusePolicy.oneShot est aujourd’hui une intention authoring.
L’exécution runtime “event consumed” dépend encore de SceneConsequence.markEventConsumed.
```

Conséquence :

```text
Le prochain lot ne doit pas ajouter de réactions authorables.
Il doit d’abord rendre cette frontière visible et vérifiable en read model.
```

Prochain lot recommandé :

```text
NS-EVENT-26 — Event Builder Scene Outcomes / Lifecycle Projection Read Model V0
```

Objectif : projeter en lecture seule, dans le read model Event Builder, les outcomes déclarés de la Scene liée et le statut lifecycle oneShot réellement couvert / non couvert, sans authoring de réactions.

## 2. Méthode et sous-agents utilisés

Le prompt impose plusieurs sous-agents. L’outil multi-agent a été utilisé avec cinq explorateurs spécialisés, puis l’orchestrateur principal a recoupé les preuves.

Sous-agents utilisés :

| Sous-agent | ID | Rôle | Verdict synthétique |
|---|---|---|---|
| A — Core Domain Contracts | `019edc88-111b-7b12-9fa8-386d66e2c549` | Contrats map_core Event / Scene / outcomes / conséquences | Scene possède outcomes et conséquences ; Event reste trigger/conditions/sceneTarget. |
| B — Runtime Pipeline | `019edc88-301a-7e31-8a70-779052fb7f86` | Event -> Scene -> runtime -> GameState | Pipeline Scene réel ; `markEventConsumed` cible un event explicite, pas l’event appelant. |
| C — Editor / Authoring Surfaces | `019edc88-584a-70b3-9214-5e4d6c51c00d` | Surfaces UI/read model/editor | Event Builder authoring borné ; Résultats/Réactions/Monde restent display-only/à venir. |
| D — Tests / Evidence / Compatibility | `019edc88-7493-75c3-a236-5be538e8c190` | Inventaire de preuves | SceneConsequences, battle outcomes, persistence, world rules prouvés ; Event Builder end-to-end complet encore partiel. |
| E — Product Boundary Reviewer | `019edc88-9070-78d2-b04b-0617f740bfb4` | Reviewer contradictoire | Rejette Option B ; recommande Option C stricte ; alerte sur le wording oneShot/Changements du monde. |

Arbitrage orchestrateur :

- les constats Core, Runtime et Reviewer convergent contre un Event propriétaire de réactions ;
- la seule tension utile est la phrase produit “Une seule fois” : elle est authorable, mais pas encore une garantie runtime autonome ;
- la solution la plus sûre est donc de rendre le lifecycle observable et diagnostiqué avant d’ajouter toute nouvelle authoring surface.

## 3. État actuel des contrats

### Event / MapEventDefinition

`MapEventDefinition` porte l’événement de map :

- identité ;
- titre ;
- type ;
- position ;
- pages ;
- metadata ;
- `MapEventPage.condition` ;
- `MapEventPage.sceneTarget` ;
- surfaces legacy `script` / `message`.

Preuve :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/authoring/event_builder_contract.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
```

Le contrat Event Builder lit et écrit uniquement le sous-ensemble MVP :

```text
source
trigger
conditions
sceneAction
behavior
worldImpactPreviews
diagnostics
legacyConditionToPreserve
```

Il ne contient pas :

```text
declaredOutcomes
outcomeBranches
reactions
consequences
worldRules
battle rewards
story step completions
```

### Scene / SceneAsset

`SceneAsset` porte :

- `declaredOutcomes` ;
- `SceneEndPayload.sceneOutcomeId` ;
- payloads dialogue / battle / cinematic ;
- `SceneActionPayload.consequence` ;
- graph nodes / edges / layout.

Preuve :

```text
packages/map_core/lib/src/models/scene_asset.dart

SceneAsset.declaredOutcomes
SceneOutcome
SceneEndPayload.sceneOutcomeId
SceneBattlePayload.declaredOutcomes
SceneBranchByOutcomePayload
SceneActionPayload.consequence
```

### SceneConsequence

`SceneConsequence` ne supporte réellement que deux kinds :

```text
setFact
markEventConsumed
```

Preuve exacte :

```text
packages/map_core/lib/src/models/scene_consequence.dart

enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
}
```

Il n’existe pas encore :

```text
giveItem
completeStep
unlockQuest
enableElement
disableElement
changeDialogue
addMoney
startBattle
worldRuleMutation
```

## 4. Pipeline runtime actuel

Pipeline actuel :

```text
MapEventPage.sceneTarget
-> SceneEventRuntimeHook.runForEventPage
-> diagnoseSceneAgainstProject
-> buildSceneRuntimePlan
-> SceneRuntimeExecutor.execute
-> callbacks dialogue / battle / cinematic / consequence
-> pendingConsequences
-> SceneConsequenceRuntimeWriter.applyAll
-> updated GameState
```

Points prouvés :

- une page sans `sceneTarget` retourne `notHandled` ;
- une Scene manquante échoue clairement ;
- les diagnostics bloquants empêchent l’exécution ;
- le plan runtime bloque `branchByOutcome` aujourd’hui ;
- les conséquences sont stagées pendant l’exécution ;
- elles ne sont committées qu’après completion réussie de la Scene ;
- un échec dialogue / battle / cinematic discarde les conséquences ;
- `setFact` et `markEventConsumed` sont appliqués via `SceneConsequenceRuntimeWriter`.

Preuves :

```text
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
```

Port supportés par l’exécuteur :

```text
condition      -> true / false
dialogue       -> completed
battle         -> victory / defeat
cinematic      -> completed
consequence    -> completed
```

Limite importante :

```text
SceneBranchByOutcomePayload existe dans le modèle, mais buildSceneRuntimePlan le bloque encore :
"BranchByOutcome attend un mapping outcome -> edge futur."
```

Donc les outcomes existent bien, mais le branchByOutcome générique n’est pas encore runtime-ready.

## 5. État authoring actuel

Event Builder peut authorer aujourd’hui :

- création de brouillon ;
- position explicite ;
- activation/ouverture map ;
- titre humain ;
- type déclencheur PNJ / objet / zone ;
- action principale Scene ;
- behavior oneShot / reusable ;
- conditions Fact true / false ;
- conditions Event consumed / not consumed ;
- retrait de conditions supportées ;
- diagnostics et statuts.

Event Builder affiche mais ne possède pas encore :

- résultats ;
- réactions ;
- changements du monde riches ;
- battle action ;
- rewards ;
- Story Step condition/action ;
- World Rule authoring inline ;
- drag/drop.

Preuves UI :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
```

La bibliothèque déclare :

```text
Résultats -> Victoire -> available: false
Réactions -> Définir un Fact -> available: false
Monde -> Activer élément -> available: false
```

Le bloc central `Changements du monde` dit explicitement :

```text
Piloté par les conséquences de scène.
```

## 6. Outcomes : source de vérité

Questions obligatoires :

### Où un outcome est-il déclaré aujourd’hui ?

Dans `SceneAsset.declaredOutcomes`.

Preuves :

```text
SceneAsset.declaredOutcomes
SceneOutcome(id, label, description)
SceneRuntimePlan.declaredOutcomes
SceneEndPayload.sceneOutcomeId
SceneBattlePayload.declaredOutcomes
```

### `SceneAsset.declaredOutcomes` est-il la source canonique ?

Oui pour Scene V1.

Nuance :

- battle runtime produit des ports `victory` / `defeat` ;
- dialogue runtime awaitable produit seulement `completed` aujourd’hui ;
- `expectedOutcomes` dialogue est porté par l’intent mais non consommé pour brancher des ports arbitraires ;
- `SceneEndPayload.sceneOutcomeId` expose le résultat final de Scene ;
- `BranchByOutcome` reste model-only / blocked runtime.

### Les outcomes Yarn, battle et cinematic sont-ils normalisés ?

Partiellement.

| Source | Statut | Commentaire |
|---|---|---|
| Battle | PARTIAL_READY | Adapter normalise `victory` / `defeat`. |
| Dialogue Yarn | PARTIAL | Adapter attend seulement `completed`; il n’invente pas de choix/outcomes Yarn. |
| Cinematic | MINIMAL | Adapter attend completion ; pas de résultat multiple. |
| Scene final outcome | MODEL_READY | `SceneEndPayload.sceneOutcomeId`, mais pas encore utilisé comme mapping Event reactions. |

### Un outcome est-il un résultat de Scene ou un résultat d’Event ?

Décision :

```text
Un outcome est un résultat de Scene.
```

Un Event peut afficher les outcomes de sa Scene cible, mais ne les possède pas.

### L’Event Builder doit-il déclarer ses propres outcomes ?

Non.

Raison :

- `MapEventDefinition` n’a pas de surface outcome ;
- Scene possède déjà le contrat ;
- Event outcomes dupliqueraient `SceneAsset.declaredOutcomes` ;
- le runtime commit les conséquences de Scene, pas des réactions Event ;
- une Scene peut être réutilisée par plusieurs Events.

## 7. Réactions : ownership

Réponse ferme :

```text
Les réactions narratives post-outcome appartiennent à la Scene.
```

Pourquoi :

- les branches battle `victory` / `defeat` mènent déjà à des noeuds de Scene ;
- les conséquences typées sont portées par `SceneActionPayload.consequence` ;
- `SceneEventRuntimeHook` stage les conséquences pendant la Scene ;
- `SceneConsequenceRuntimeWriter` commit après réussite ;
- Event-owned reactions créeraient un second moteur de branchement.

Peut-on attacher aujourd’hui différentes conséquences à victory et defeat ?

Oui, dans une Scene, via des edges battle `victory` / `defeat` menant à des action nodes distincts.

Preuve test :

```text
packages/map_runtime/test/scene_event_runtime_hook_test.dart

battle victory follows victory branch and commits consequence
battle defeat follows defeat branch and commits consequence
```

Les conséquences actuelles sont-elles globales à la Scene ou branchées par outcome ?

Les deux sont possibles selon la position du noeud action dans le graph :

- une conséquence sur le chemin commun est globale à la Scene ;
- une conséquence après un port `victory` ou `defeat` est branchée par résultat ;
- il n’existe pas encore de table déclarative `outcome -> consequences` hors graph.

Décision :

```text
Event Builder doit lire et résumer ces réactions depuis la Scene liée.
Il ne doit pas les authorer dans Event.
```

## 8. SceneConsequences : capacités et limites

Kinds réels :

```text
SceneConsequenceKind.setFact
SceneConsequenceKind.markEventConsumed
```

Suffisants pour le MVP ?

```text
Suffisants pour le MVP Event -> Scene -> Fact / Event consumed.
Insuffisants pour une V1 complète proche de l’image cible.
```

Manquants pour V1/V2 :

| Besoin image cible | Statut actuel | Décision |
|---|---|---|
| Donner argent | Absent de SceneConsequence | Future consequence Scene/gameplay, pas Event. |
| Donner objet | `GameStateMutations.giveItem` existe, pas SceneConsequence | Future extension SceneConsequence. |
| Compléter Step | `GameStateMutations.completeStep` existe, pas SceneConsequence | Future extension SceneConsequence ou contrat runtime dédié. |
| Débloquer quête | Pas de primitive directe | Probablement Fact/Step + World Rule, pas Event direct. |
| Changer dialogue PNJ | WorldRule `npcDialogueOverride` existe | Projection/règle monde, pas réaction Event directe. |
| Activer/Désactiver élément | WorldRule event/entity visible/hidden/enabled/disabled | Projection passive depuis Fact/Step/Event consumed. |

Faut-il enrichir SceneConsequence ?

Oui plus tard, mais pas dans Event Builder directement.

Décision :

```text
Les futures mutations persistantes doivent d’abord entrer dans un contrat de conséquence commun,
probablement SceneConsequence ou un successeur compatible Scene runtime.
L’Event Builder n’ajoute pas un modèle parallèle.
```

## 9. Event consumed : décision canonique

Question obligatoire :

```text
Qui doit marquer l’Event comme consommé ?
```

Décision canonique :

```text
L’event appelant doit être consommé par le lifecycle Event/runtime hook,
pas par une Scene réutilisable codée avec un eventId fixe.
```

État actuel :

- `EventBuilderReusePolicy.oneShot` est stocké dans `page.metadata` ;
- `_buildWorldImpactPreviews` annonce un impact `consumedEvent` pour oneShot ;
- l’exécution réelle ne consomme un event que si la Scene contient `SceneConsequence.markEventConsumed(mapId, eventId)`.

Problème :

```text
SceneConsequence.markEventConsumed cible un mapId/eventId explicite.
Si plusieurs Events appellent la même Scene, la Scene peut consommer le mauvais Event.
```

Réponse ferme au cas Scene partagée :

```text
Une Scene partagée ne doit pas porter une conséquence "consommer l’Event appelant" avec un eventId fixe.
Le runtime Event doit produire une lifecycleMutation scoped sur l’Event appelant après réussite de la Scene,
si l’Event est oneShot.
```

Compatibilité :

- `SceneConsequence.markEventConsumed` peut rester pour des cas explicites/legacy/avancés où l’auteur veut consommer un event précis ;
- le workflow no-code Event Builder ne doit pas demander à l’utilisateur de poser cette conséquence dans la Scene pour que oneShot fonctionne ;
- le read model doit diagnostiquer la différence entre intention oneShot et exécution réellement couverte.

Décision :

```text
Event consumed canonique Event Builder = lifecycle de l’Event appelant.
SceneConsequence.markEventConsumed = mutation explicite avancée / compatibilité.
```

## 10. Facts / Steps / World Rules

### Facts

Facts sont des vérités persistantes.

État actuel :

- `NarrativeFactDefinition` existe ;
- `SceneConsequence.setFact` écrit un Fact dans `GameState.storyFlags` ;
- Event Builder conditions Fact true/false compilent en `ScriptCondition.flagIsSet/flagIsUnset` ;
- Facts Manager suit les usages.

Décision :

```text
L’Event Builder peut utiliser les Facts comme conditions d’entrée.
Les mutations Fact doivent rester des conséquences de Scene.
```

### Story Steps

État actuel :

- `GameStateMutations.completeStep` existe ;
- `WorldRuleSourceKind.storyStepCompletion` existe ;
- Event Builder possède des bindings Story Step typés mais non compilés ;
- `SceneConsequence.completeStep` n’existe pas.

Décision :

```text
Story Step completion ne doit pas être ajoutée dans l’Event Builder comme réaction directe.
Le prochain contrat doit enrichir SceneConsequence ou un writer commun.
```

### World Rules

World Rule est une projection passive :

```text
Fact / Step / Event consumed
-> WorldRule
-> changement visible du monde
```

Preuve produit :

```text
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
World Rule = projection passive du GameState.
```

Décision :

```text
Event Builder ne crée pas de World Rule inline.
Il affiche au mieux les World Rules potentiellement impactées par les mutations directes.
```

Le bloc `Changements du monde` doit distinguer :

| Type | Exemple | Ownership |
|---|---|---|
| Mutation directe | setFact, completeStep futur, lifecycle event consumed | Scene / Event lifecycle |
| Projection passive | entity hidden, event disabled, dialogue override | WorldRule |
| Inférence UI | “ce Fact peut cacher un PNJ” | Read model / projection |
| Simulation runtime | état final exact après exécution | Runtime/smoke futur, pas Event Builder V0.75 |

## 11. Comparaison des options A / B / C

### Option A — Event mince, Scene propriétaire

Description :

```text
Event possède trigger, conditions, Scene cible, behavior.
Scene possède outcomes, branches, actions, conséquences.
Event Builder affiche outcomes/conséquences Scene en lecture.
```

Avantages :

- très compatible avec le code actuel ;
- évite le second moteur narratif ;
- respecte “Event déclenche, Scene orchestre” ;
- testable par projection read-only.

Limites :

- ne règle pas complètement le lifecycle oneShot ;
- laisse `EventBuilderReusePolicy.oneShot` comme intention tant qu’un runtime lifecycle dédié n’existe pas ;
- peut faire croire que l’Event n’a aucun rôle après Scene.

### Option B — Event propriétaire des réactions post-Scene

Description :

```text
Event possède mapping Scene outcome -> Event reactions.
Event possède mutations persistantes post-Scene.
```

Avantages :

- ressemble davantage à l’image cible “Réactions” dans Event Builder ;
- peut rendre un Event auto-contenu à court terme.

Risques bloquants :

- duplique Scene graph / SceneConsequence ;
- contourne la transaction Scene actuelle ;
- complique les Scenes réutilisées ;
- crée deux lieux pour écrire setFact/markEventConsumed ;
- demande un nouveau runtime bridge ;
- rend les diagnostics Event/Scene ambigus.

Décision :

```text
Option B rejetée.
```

### Option C — Contrat hybride lifecycle

Description :

```text
Event possède trigger, conditions, Scene cible et lifecycle intent.
Scene possède outcomes/réactions/conséquences narratives.
Runtime Event possède lifecycle mutation scoped sur l’event appelant.
Event Builder affiche Scene outcomes/consequences/World impacts en lecture.
```

Avantages :

- conserve la frontière Event/Scene ;
- règle le problème oneShot sans mettre eventId fixe dans une Scene partagée ;
- évite un moteur Event parallèle ;
- permet une UI proche de l’image cible en lecture/projection ;
- laisse l’authoring riche dans Scene Builder.

Risques :

- nécessite un futur petit contrat runtime lifecycle ;
- impose de reformuler certains labels UI ;
- demande un read model de projection plus riche.

Décision :

```text
Option C recommandée.
```

## 12. Décision architecturale recommandée

Recommandation canonique :

```text
Option C — Contrat hybride lifecycle strict.
```

Frontière :

| Concept | Owner canonique | Event Builder |
|---|---|---|
| Trigger | Event | Authorable |
| Conditions d’entrée | Event / MapEventPage.condition | Authorable pour subset no-code |
| Scene cible | Event / MapEventPage.sceneTarget | Authorable |
| Reuse policy | Event Builder metadata puis lifecycle runtime | Authorable comme intention |
| Outcomes | Scene | Read-only projection |
| Branches | Scene | Read-only / lien vers Scene Builder |
| Réactions | Scene | Read-only projection |
| setFact | SceneConsequence | Read-only projection / authoring dans Scene |
| markEventConsumed explicite | SceneConsequence compat avancée | Read-only / déconseillé pour caller lifecycle |
| event consumed caller | Event lifecycle runtime futur | Diagnostic/projection Event |
| completeStep | Future consequence/runtime contract | Pas authorable Event V0 |
| World Rule | World Rules Manager | Read-only projection / lien |

## 13. Contrat conceptuel proposé

Schéma conceptuel, sans implémentation :

```text
EventDefinition
- id
- title
- trigger
- entryConditions
- sceneTarget
- reusePolicy
- lifecyclePolicy

SceneAsset
- graph
- declaredOutcomes
- runtimePorts
- branchEdges
- consequences

SceneExecutionResult
- status
- sceneId
- finalNodeId
- sceneOutcomeId
- stagedConsequences
- diagnostics

EventExecutionResult
- eventId
- sceneResult
- lifecycleMutation
- updatedGameState
- diagnostics

WorldRuleProjection
- sourceState
- matchingRules
- projectedEffects
```

Règle de cohérence :

```text
SceneExecutionResult ne doit pas savoir quel Event l’a appelée, sauf via un contexte runtime.
EventExecutionResult sait quel Event a appelé la Scene et peut appliquer la lifecycle mutation oneShot.
```

## 14. Projection précise dans l’UI Event Builder

### Résultats possibles

Décision :

```text
read-only depuis la Scene liée
```

Comportement recommandé :

- afficher les `SceneAsset.declaredOutcomes` ;
- indiquer si la Scene ne déclare aucun outcome ;
- afficher battle `victory/defeat` seulement s’ils sont déclarés/portés par la Scene ;
- ne pas permettre “Ajouter Victoire/Défaite” depuis Event Builder ;
- proposer “Configurer dans la Scene” plus tard.

### Réactions

Décision :

```text
Scene-owned, read-only dans Event Builder.
```

Comportement recommandé :

- afficher les conséquences de la Scene liée ;
- plus tard, grouper par chemin/outcome si le read model Scene sait l’inférer ;
- ne pas authorer `Définir un Fact` dans Event Builder ;
- ne pas créer un mapping Event outcome -> reactions.

### Changements du monde

Décision :

```text
projection de mutations directes + World Rules impactées, pas authoring inline.
```

Comportement recommandé :

- afficher mutations directes : setFact, event consumed lifecycle, completeStep futur ;
- afficher projections passives : World Rules impactées par Fact / Step / consumed Event ;
- libeller clairement “Conséquences de la scène liée” ou “Effets attendus” plutôt que laisser croire que l’Event Builder modifie directement le monde ;
- distinguer “prouvé par le graphe Scene” et “possible via World Rule”.

## 15. Bibliothèque d’éléments : décisions

| Élément cible | Décision | Raison |
|---|---|---|
| Victoire | Lecture seule | Outcome battle/Scene, pas Event. |
| Défaite | Lecture seule | Outcome battle/Scene, pas Event. |
| Échec | À venir / Scene-owned | Pas de port runtime générique aujourd’hui. |
| Définir un Fact | Déplacé vers Scene Builder | Déjà `SceneConsequence.setFact`. |
| Compléter une Step | À venir SceneConsequence/runtime | `GameStateMutations.completeStep` existe mais pas SceneConsequence. |
| Donner un objet | À venir Scene/gameplay consequence | `giveItem` existe côté gameplay, pas SceneConsequence. |
| Débloquer une quête | À modéliser via Step/Fact | Ne doit pas être un bouton Event direct. |
| Activer élément | World Rule projection | Pas mutation directe Event. |
| Désactiver élément | World Rule projection | Pas mutation directe Event. |
| Changer dialogue | World Rule `npcDialogueOverride` | Manager World Rules reste owner. |
| Combat | À configurer dans Scene | Event Builder ne lance pas Battle directement en MVP. |

## 16. Risques et migrations

Risques majeurs :

1. `oneShot` peut mentir si le runtime ne consomme pas l’event appelant.
2. `markEventConsumed` stocke un `eventId` nu dans `GameState.consumedEventIds`.
3. Deux maps avec le même eventId peuvent entrer en collision.
4. Une Scene partagée peut consommer le mauvais Event si elle porte un eventId fixe.
5. `Changements du monde` peut sonner authorable alors qu’il est projection/read-only.
6. `BranchByOutcome` existe dans le modèle mais reste bloqué au plan runtime.
7. Dialogue outcomes Yarn ne sont pas encore branchés comme ports arbitraires.

Migrations à éviter maintenant :

- créer `EventOutcome` dans `MapEventDefinition` ;
- créer `EventReaction` local ;
- écrire des mutations GameState depuis l’Event Builder UI ;
- convertir les World Rules en conséquences directes ;
- déplacer les conséquences hors Scene sans runtime contract.

## 17. Plan de lots recommandé

### NS-EVENT-26 — Event Builder Scene Outcomes / Lifecycle Projection Read Model V0

Type : code read model + tests core/editor si nécessaire.

Objectif :

```text
Projeter en lecture seule, pour l’Event Builder, les outcomes de la Scene liée
et le statut lifecycle oneShot réellement couvert / non couvert.
```

Fichiers probables :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/test/event_builder_read_model_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Non-objectifs :

- pas d’authoring de réactions ;
- pas de runtime lifecycle ;
- pas de drag/drop ;
- pas de nouveaux SceneConsequence kinds.

Critères :

- `SceneAsset.declaredOutcomes` visible dans un sous-objet read model ;
- Scene manquante diagnostiquée ;
- oneShot sans preuve de consommation affiché comme intention non garantie ;
- Scene réutilisable ne force pas markEventConsumed.

### NS-EVENT-27 — Event Builder Results Read-only UI V0

Objectif : afficher le bloc `Résultats possibles` depuis la projection NS-EVENT-26.

Non-objectifs : aucun bouton “Ajouter victoire/défaite”.

### NS-EVENT-28 — Event Builder Linked Scene Consequences Projection V0

Objectif : lister en lecture les `SceneConsequence` de la Scene liée.

Non-objectifs : pas d’édition depuis Event Builder.

### NS-EVENT-29 — Event Lifecycle Consumption Runtime Contract V0

Objectif : décider/implémenter le lifecycle runtime “consume caller event when oneShot Scene succeeds”.

Non-objectifs : ne pas supprimer `SceneConsequence.markEventConsumed`.

### NS-EVENT-30 — World Impact Projection From Scene Consequences V0

Objectif : afficher les World Rules potentiellement impactées par setFact/event consumed.

Non-objectifs : pas d’édition World Rules inline.

### NS-EVENT-31 — SceneConsequence Extension Prep: completeStep / giveItem Decision Audit

Objectif : cadrer les futures conséquences persistantes non couvertes.

### NS-EVENT-32 — Event Builder Reactions Read-only Grouping V0

Objectif : regrouper les conséquences par chemin/outcome si le read model Scene peut le prouver.

### NS-EVENT-33+ — Authoring Scene Consequences / World Changes In Scene Builder

Objectif : ouvrir l’authoring riche là où il appartient : Scene Builder, pas Event Builder.

## 18. Prochain lot exact

Prochain lot recommandé :

```text
NS-EVENT-26 — Event Builder Scene Outcomes / Lifecycle Projection Read Model V0
```

Pourquoi maintenant :

- il transforme la décision NS-EVENT-25 en surface vérifiable ;
- il garde l’Event Builder read-only pour Résultats/Réactions/Monde ;
- il expose le trou oneShot sans créer de runtime prématuré ;
- il prépare l’UI NS-EVENT-27 sans dupliquer Scene.

Pourquoi ne pas faire drag/drop maintenant :

```text
Drag/drop déplacerait des éléments dont l’ownership n’est pas encore projeté correctement.
```

Pourquoi ne pas authorer réactions maintenant :

```text
Cela créerait un second Scene Builder.
```

## 19. Conclusions des sous-agents

### Sub-agent A — Core Domain Contracts

Conclusions :

- outcomes vivent dans `SceneAsset`, pas dans `MapEventDefinition` ;
- `SceneConsequence` est la surface de mutation persistante typée ;
- `MapEventDefinition` possède trigger/page/sceneTarget, pas reaction graph ;
- Facts/World Rules/Story Steps forment une couche state/projection distincte.

Verdict :

```text
Event Builder peut orchestrer et afficher, mais ne doit pas inventer event-local outcomes/reactions.
```

### Sub-agent B — Runtime Pipeline

Conclusions :

- `SceneEventRuntimeHook` exécute la Scene ciblée par event page ;
- consequences sont stagées puis committées seulement à la completion ;
- dialogue = completed seulement ;
- battle = victory/defeat ;
- branchByOutcome générique bloqué ;
- `markEventConsumed` écrit seulement `eventId`, même s’il valide `mapId`.

Verdict :

```text
Le risque majeur est Scene partagée + markEventConsumed eventId fixe.
```

### Sub-agent C — Editor / Authoring Surfaces

Conclusions :

- Event Builder authoring actuel est borné ;
- Résultats/Réactions/Monde sont placeholders/read-only ;
- GlobalKey bibliothèque -> détail est acceptable mais fragile à terme ;
- Scene Builder possède déjà l’authoring plus riche ;
- Facts/World Rules Manager reste une surface séparée.

Verdict :

```text
Garder Résultats/Réactions/Monde en lecture/projection.
```

### Sub-agent D — Tests / Evidence / Compatibility

Classification :

| Comportement | Statut |
|---|---|
| Scene outcomes | PROUVÉ |
| Dialogue outcomes | PARTIEL |
| Battle victory/defeat | PROUVÉ |
| SceneConsequences | PROUVÉ |
| Persistence | PROUVÉ |
| Event consumed | PROUVÉ |
| Facts | PROUVÉ |
| World Rules | PROUVÉ |
| Event Builder end-to-end complet | PARTIEL |

Verdict :

```text
Les briques sont testées, mais il manque un smoke unique Event Builder-authored event -> Scene -> outcome -> consequence -> save/load -> World Rules.
```

### Sub-agent E — Product Boundary Reviewer

Conclusions :

- Option B est dangereuse ;
- Option C est recommandée ;
- `oneShot` peut mentir à l’utilisateur si non diagnostiqué ;
- `Changements du monde` est un titre risqué s’il n’indique pas assez son statut projection/read-only ;
- Event Builder ne doit pas devenir un second Scene Builder.

Verdict :

```text
Option C hybrid lifecycle stricte.
```

## 20. Contradictions entre sous-agents et arbitrages

### Contradiction 1 — “Event consumed appartient à Scene” vs “Event lifecycle”

Constat :

- Core/runtime actuels prouvent `SceneConsequence.markEventConsumed` ;
- reviewer signale qu’une Scene partagée peut consommer le mauvais event.

Arbitrage :

```text
Le modèle actuel reste valide comme mutation explicite.
Le contrat canonique Event Builder doit évoluer vers lifecycle caller event.
```

### Contradiction 2 — “Changements du monde” section existante vs ownership World Rules

Constat :

- Event Builder affiche déjà `Changements du monde` ;
- World Rules sont une projection passive séparée.

Arbitrage :

```text
Conserver le bloc, mais le remplir en projection/read-only et clarifier le wording.
```

### Contradiction 3 — Roadmap Validator signalée par Sub-agent C

Constat :

- Sub-agent C a noté qu’une roadmap future associe NS-EVENT-25 à Validator Global Integration V1.
- Le prompt courant définit explicitement NS-EVENT-25 comme audit ownership outcomes/reactions/consequences.

Arbitrage :

```text
Suivre le prompt courant, car il est explicite, documentaire et cohérent avec le risque produit immédiat.
Le Validator redevient un lot ultérieur.
```

### Contradiction 4 — Dialogue outcomes

Constat :

- modèle porte `expectedOutcomes` ;
- adapter runtime dialogue ne branche que `completed`.

Arbitrage :

```text
Ne pas afficher les outcomes Yarn comme supportés runtime tant que le bridge ne les produit pas.
```

## 21. Evidence Pack

### Gate 0 exact

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie :

```text
pwd
/Users/karim/Project/pokemonProject

branch
main

status

diff-stat

diff-name-only

log
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
```

### Règles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/015c0dff/skills/dispatching-parallel-agents/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/015c0dff/skills/verification-before-completion/SKILL.md
```

Note : les premiers chemins de cache superpowers issus du contexte étaient obsolètes ; les fichiers réels ont été localisés via `find /Users/karim/.codex -path '*.../SKILL.md'`.

### Fichiers lus / audités

Règles :

```text
AGENTS.md
agent_rules.md
codex_rule.md
```

Rapports Event Builder :

```text
reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md
reports/narrativeStudio/events/ns_event_02_event_builder_core_contract_typed_authoring_bindings.md
reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
reports/narrativeStudio/events/ns_event_20_event_inspector_split_v0.md
reports/narrativeStudio/events/ns_event_21_element_library_readonly_v0.md
reports/narrativeStudio/events/ns_event_22_add_by_click_from_library_v0.md
reports/narrativeStudio/events/ns_event_23_actions_conditions_block_polish_v0.md
reports/narrativeStudio/events/ns_event_24_mvp_ux_closure_visual_gate.md
reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
```

Contrats et code :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/authoring/event_builder_contract.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests audités :

```text
packages/map_core/test/scene_consequence_model_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
packages/map_core/test/scene_asset_json_test.dart
packages/map_core/test/event_builder_contract_test.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
packages/map_core/test/event_builder_read_model_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart
packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart
packages/map_runtime/test/outcome_scene_branch_readiness_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Commandes de recherche principales

```bash
rg -n "declaredOutcomes|SceneOutcome|outcome|SceneConsequence|markEventConsumed|setFact|completeStep|WorldRule|fact" packages/map_core/lib/src/models packages/map_core/lib/src/runtime packages/map_core/lib/src/authoring packages/map_core/lib/src/read_models
rg -n "SceneConsequence|markEventConsumed|setFact|dialogue|battle|outcome|victory|defeat|consumed|GameState|WorldRule" packages/map_runtime/lib/src/application/scene_runtime packages/map_gameplay/lib/src packages/map_core/lib/src/runtime
rg -n "EventBuilder|Résultats|Réactions|Monde|WorldImpact|outcome|reaction|library|sceneTarget|reusePolicy|eventConsumed|factIs" packages/map_core/lib/src/authoring packages/map_core/lib/src/read_models packages/map_editor/lib/src/ui/canvas/events packages/map_editor/test/event_builder_workspace_test.dart
rg --files packages/map_core/test packages/map_runtime/test packages/map_gameplay/test packages/map_editor/test | rg -i "scene|consequence|outcome|dialogue|battle|event|world|fact|story|runtime"
rg -n "SceneConsequence|markEventConsumed|setFact|declaredOutcomes|BranchByOutcome|branchByOutcome|completeStep|WorldRule|one-shot|oneShot|Changements du monde|Résultats|Réactions" reports/narrativeStudio/scenes reports/narrativeStudio/events reports/roadmap/phase_1
```

### Test exécuté

Ce lot est documentaire. Une caractérisation ciblée core a néanmoins été relancée pour vérifier le contrat SceneConsequence.

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/scene_consequence_model_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_consequence_model_test.dart
00:00 +0: SceneConsequence V0 setFact stores factId and value
00:00 +1: SceneConsequence V0 setFact stores factId and value
00:00 +1: SceneConsequence V0 markEventConsumed stores mapId and eventId
00:00 +2: SceneConsequence V0 markEventConsumed stores mapId and eventId
00:00 +2: SceneConsequence V0 setFact JSON round-trips
00:00 +3: SceneConsequence V0 setFact JSON round-trips
00:00 +3: SceneConsequence V0 markEventConsumed JSON round-trips
00:00 +4: SceneConsequence V0 markEventConsumed JSON round-trips
00:00 +4: SceneConsequence V0 rejects unknown consequence kind
00:00 +5: SceneConsequence V0 rejects unknown consequence kind
00:00 +5: SceneActionPayload typed consequences can carry typed setFact consequence
00:00 +6: SceneActionPayload typed consequences can carry typed setFact consequence
00:00 +6: SceneActionPayload typed consequences can carry typed markEventConsumed consequence
00:00 +7: SceneActionPayload typed consequences can carry typed markEventConsumed consequence
00:00 +7: SceneActionPayload typed consequences legacy actionKind payload still deserializes
00:00 +8: SceneActionPayload typed consequences legacy actionKind payload still deserializes
00:00 +8: All tests passed!
```

Tests non exécutés :

```text
flutter test suites complètes
dart analyze
flutter analyze
build macOS
```

Raison :

```text
Le lot est documentaire et ne modifie aucun code applicatif.
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md
```

### Fichiers applicatifs modifiés

```text
<aucun>
```

### Preuves principales par symbole

| Symbole | Preuve |
|---|---|
| `SceneAsset.declaredOutcomes` | Source canonical Scene outcomes. |
| `SceneOutcome` | ID/label/description typed outcome. |
| `SceneEndPayload.sceneOutcomeId` | Résultat final Scene. |
| `SceneBattlePayload.declaredOutcomes` | Outcomes battle portés par payload Scene. |
| `SceneConsequenceKind` | `setFact`, `markEventConsumed` seulement. |
| `SceneEventRuntimeHook.runForEventPage` | Entrée runtime Event -> Scene. |
| `SceneConsequenceRuntimeWriter.applyAll` | Commit séquentiel/all-or-nothing côté caller. |
| `EventBuilderContractView.worldImpactPreviews` | Projection Event Builder, pas authoring. |
| `EventBuilderElementLibrary` | Résultats/Réactions/Monde encore à venir. |
| `WorldRuleDefinition` | Projection passive Fact/Step/Event consumed. |

### Gate final exact

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie exacte :

```text
status
?? reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md

diff-stat

diff-name-only

diff-check
```

Commande anti-scope :

```bash
git diff --name-only -- packages examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
<vide>
```

## 22. Auto-review critique

Checklist :

- Le lot n’ajoute aucune feature : oui.
- Aucun code applicatif modifié : oui.
- Les sous-agents obligatoires ont été utilisés : oui, cinq sous-agents spécialisés.
- Les contradictions ont été arbitrées : oui.
- Une option canonique unique est recommandée : oui, Option C.
- Event/Scene/Runtime/World Rule boundaries sont distinguées : oui.
- Le cas Scene partagée entre plusieurs Events reçoit une réponse ferme : oui.
- Event consumed ownership est clarifié : oui, lifecycle de l’event appelant.
- Résultats/Réactions/Monde sont projetés sans authoring : oui.
- Drag/drop n’est pas lancé : oui.
- Le prochain lot est exact : oui.

Réserves :

- Le rapport s’appuie surtout sur audit code/tests et un test core ciblé. Il ne relance pas les suites Flutter/runtimes complètes, car le lot est doc-only.
- Les sous-agents ont parfois rapporté un `git status` clean dans leur contexte ; l’orchestrateur a conservé son propre Gate 0 comme source principale.
- Le futur NS-EVENT-26 devra vérifier plus précisément comment charger la Scene liée dans le read model Event Builder sans coupler `map_core` à une surface editor.
- Le wording UI “Changements du monde” reste à traiter dans un lot de projection/UX, pas dans cet audit.

Critique du prompt :

- Le prompt est large mais justifié : il évite une erreur chère, ajouter des réactions Event avant de savoir qui possède quoi.
- L’exigence de sous-agents est pertinente ici ; les risques core/runtime/editor/tests sont réellement indépendants.
- Le prompt aurait pu préciser que `oneShot` actuel n’est peut-être pas runtime-enforced ; l’audit l’a découvert et en fait le risque principal.
- Il ne faut pas transformer la suite en lot drag/drop : la prochaine étape doit être read model/projection.
