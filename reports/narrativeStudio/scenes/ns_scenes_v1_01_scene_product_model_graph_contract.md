# NS-SCENES-V1-01 — Scene Product Model / Graph Contract

## 1. Executive summary

Verdict produit : Scene V1 doit etre definie comme un graphe d'orchestration authorable, distinct de Storylines, Events, Cinematics, Yarn, Facts et World Rules.

Definition courte : une Scene V1 est une sequence logique composee de nodes types et de transitions explicites. Elle orchestre dialogue Yarn, conditions, actions, combats, cinematiques lineaires, branches par outcome et fin de scene.

Decision sur le perimetre du graph :

- Le graph porte la logique d'orchestration.
- Les positions visuelles sont un besoin editor, mais ne doivent pas devenir le coeur runtime.
- Les transitions sont explicites : aucune transition ne nait de la proximite visuelle de deux nodes.
- Le graph ne stocke pas tout le jeu dans `metadata`.
- Le graph ne remplace pas Storyline/Chapter/StoryStep.

Risques majeurs :

- Deguiser l'ancien `ScenarioAsset` en Scene V1 sans decision de storage.
- Confondre Scene et Cinematic.
- Laisser Yarn piloter la progression globale.
- Exposer des flags techniques comme UX principale.
- Creer des payloads libres trop puissants.

Prochain lot recommande : `NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision`.

## 2. Definitions canoniques

### Scene

Responsabilite : orchestrer une sequence narrative/logique executable depuis un declencheur explicite.

Exemple utilisateur : "Rencontre rival" lance un dialogue Yarn, branche selon un outcome, joue une cinematique courte, lance un combat, puis emet un resultat de scene.

Equivalent technique futur possible : `SceneAsset`, ou adapter/wrapper autour de `ScenarioAsset` si V1-02 le decide.

Ne doit pas faire :

- Ne pas etre une storyline complete.
- Ne pas stocker le texte Yarn complet.
- Ne pas etre une cinematic lineaire.
- Ne pas porter le declencheur Event complet.
- Ne pas persister directement tout l'etat du monde sans action explicite.

Relations :

- Est lancee par un Event.
- Peut etre liee plus tard a un StorylineStep.
- Appelle Yarn, Cinematic, Battle et Actions.
- Peut emettre un SceneOutcome.

### SceneGraph

Responsabilite : decrire la structure interne d'une Scene sous forme de nodes, ports et edges.

Exemple utilisateur : Start -> Dialogue Yarn -> Branch by outcome -> Battle -> End.

Equivalent technique futur possible : champ `graph` d'un futur `SceneAsset`, ou read model issu d'un adapter legacy.

Ne doit pas faire :

- Ne pas stocker la bibliotheque de scenes.
- Ne pas definir le storage ProjectManifest.
- Ne pas inclure des widgets Flutter.
- Ne pas encoder des transitions implicites par position.

Relations :

- Appartient a une Scene.
- Contient SceneNodes et SceneEdges.
- Expose declaredOutcomes et diagnostics derives.

### SceneNode

Responsabilite : representer une etape d'orchestration typee dans le graph.

Exemple utilisateur : un node "Dialogue Yarn" pointe vers un dialogue et expose les sorties `completed`, `outcome:panic`, `outcome:reassure`.

Equivalent technique futur possible : union type, sealed model, ou node read model.

Ne doit pas faire :

- Ne pas porter un payload libre non valide.
- Ne pas cacher une mutation runtime dans une note.
- Ne pas combiner plusieurs responsabilites contradictoires.

Relations :

- Appartient a un SceneGraph.
- Possede des ports d'entree/sortie.
- Est connecte par SceneEdges.
- Produit une SceneExecutionIntent au runtime.

### SceneEdge

Responsabilite : representer une transition explicite entre un port source et un node/port cible.

Exemple utilisateur : sortie `battleVictory` du BattleNode vers ActionNode "Donner recompense".

Equivalent technique futur possible : edge serialise, runtime transition, ou read model editor.

Ne doit pas faire :

- Ne pas porter une condition complexe si un ConditionNode doit la porter.
- Ne pas etre cree implicitement par layout.
- Ne pas relier des ports incompatibles.

Relations :

- Source : SceneNode + ScenePort.
- Cible : SceneNode, avec port d'entree implicite ou explicite.
- Valide par SceneDiagnostic.

### ScenePort

Responsabilite : nommer une sortie ou une entree connectable d'un node.

Exemple utilisateur : `true` et `false` pour ConditionNode ; `outcome:panic` pour YarnDialogueNode.

Equivalent technique futur possible : enum de ports par node kind, ou port id type.

Ne doit pas faire :

- Ne pas etre un label purement visuel sans contrat.
- Ne pas accepter n'importe quel edge kind.

Relations :

- Declare par un SceneNode.
- Reference par SceneEdge.
- Affiche par l'UI sous forme de sorties visibles.

### SceneOutcome

Responsabilite : resultat explicite emis par une Scene.

Exemple utilisateur : `rival_defeated`, `crowd_reassured`, `scene_cancelled`.

Equivalent technique futur possible : liste `declaredOutcomes` d'une Scene.

Ne doit pas faire :

- Ne pas etre automatiquement persistant.
- Ne pas etre un Fact.
- Ne pas etre un StoryStep completed.
- Ne pas etre un battle outcome brut.

Relations :

- Peut etre emis par SceneEndNode ou ActionNode explicite.
- Peut etre consomme par Event/future World Rule/future Storyline link.
- Peut devenir Fact seulement via action explicite.

### SceneDiagnostic

Responsabilite : decrire un probleme ou une information derivee du graph.

Exemple utilisateur : "La sortie `outcome:panic` du dialogue n'est pas reliee."

Equivalent technique futur possible : diagnostic core/editor derive, jamais source de verite.

Ne doit pas faire :

- Ne pas muter le graph.
- Ne pas cacher un fix automatique non demande.

Relations :

- Derive de SceneGraph.
- Affiche par inspector, canvas, tree et validator.

### SceneExecutionIntent

Responsabilite : decrire ce que le runtime doit faire quand il visite un node, sans exposer Flutter/UI.

Exemple utilisateur : ouvrir un dialogue Yarn, attendre un outcome, lancer un combat, jouer une cinematic, executer une action.

Equivalent technique futur possible : runtime executable read model, adapter vers `ScenarioRuntimeExecutor`, ou nouvel executor Scene.

Ne doit pas faire :

- Ne pas contenir layout UI.
- Ne pas dependre de widgets.
- Ne pas exposer des callbacks editor.

Relations :

- Produit par SceneNode.
- Consomme par runtime Scene.
- Peut etre mappe vers scripts/scenario runtime existants si V1-02/V1-09 le decide.

### SceneAuthoringState

Responsabilite : qualifier l'etat d'authoring d'une Scene ou d'un node.

Exemple utilisateur : draft, incomplete, valid, blocked, legacyImported.

Equivalent technique futur possible : enum de statut ou diagnostic summary.

Ne doit pas faire :

- Ne pas remplacer les diagnostics detailles.
- Ne pas devenir un statut fake sans validation.

Relations :

- Derive des diagnostics et donnees authoring.
- Affiche par tree, inspector, badges et validation panel.

## 3. Scene V1 — responsabilite exacte

Une Scene V1 doit faire :

- Orchestrer une sequence logique.
- Appeler un dialogue Yarn.
- Lire un outcome de dialogue.
- Brancher selon cet outcome.
- Tester une condition.
- Lancer une cinematic lineaire.
- Lancer un combat.
- Declencher une action typee.
- Emettre un SceneOutcome.
- Terminer proprement.

Une Scene V1 ne doit pas faire :

- Ne pas etre une Storyline.
- Ne pas etre un Chapter.
- Ne pas etre une Story Step.
- Ne pas etre un Event.
- Ne pas etre une Cinematic.
- Ne pas etre un fichier Yarn.
- Ne pas etre un Fact registry.
- Ne pas etre une World Rule.
- Ne pas etre un `ScriptAsset` brut.
- Ne pas stocker tout le jeu dans `metadata`.

Frontiere cle :

- Event = quand et ou la scene demarre.
- Scene = ce qui se passe apres demarrage.
- Cinematic = sequence visuelle lineaire appelee par la Scene.
- Yarn = contenu de dialogue et choix, avec outcomes.
- Fact = etat persistant lisible par l'auteur.

## 4. SceneGraph contract

Contrat conceptuel minimal :

| Champ | Role | Obligatoire | Notes |
|---|---|---|---|
| `sceneId` | Identite de la Scene parente. | oui | L'ID stable exact sera decide en V1-02. |
| `graphId` | Identite du graph si versioning/layout separe. | ouvert | Decision storage V1-02. |
| `startNodeId` | Point d'entree du graph. | oui | Un seul start node actif. |
| `nodes` | Liste des SceneNodes. | oui | Types explicites. |
| `edges` | Liste des SceneEdges. | oui | Transitions explicites. |
| `declaredOutcomes` | Outcomes que la scene peut emettre. | oui | Distincts des dialogue/battle outcomes. |
| `authoringMetadata` | Notes non critiques. | optionnel | Ne doit pas changer la logique. |
| `diagnostics` | Problemes derives. | derive | Pas source de verite. |
| `layout` | Positions editor. | separe recommande | Voir decision ci-dessous. |

Decision sur les positions visuelles :

- Les positions sont necessaires pour l'UI Scene Builder.
- Elles ne doivent pas faire partie du coeur runtime.
- Elles peuvent faire partie d'un sous-objet `SceneGraphLayout` ou d'un read model editor-only.
- V1-02 doit decider storage exact : inline dans Scene, sidecar layout, ou read model derive.

Justification :

- Le runtime n'a pas besoin de `x/y`.
- Le graph editor a besoin de positions stables.
- Melanger logique et layout rendrait les diffs, validations et migrations plus fragiles.

Non-decision volontaire :

- Ce lot ne decide pas si le stockage final est `ProjectManifest.scenes`, `ProjectManifest.scenarios` adapte, ou hybride.

## 5. SceneNode taxonomy

Decision DialogueNode/YarnDialogueNode :

`YarnDialogueNode` est le seul concept V1. Il ne faut pas creer un `DialogueNode` generique maintenant.

Raison :

- Le runtime et le projet parlent deja de Yarn/dialogues.
- Un node generique ajouterait une abstraction vide.
- Si un autre moteur de dialogue arrive plus tard, il pourra etre ajoute comme autre node kind ou comme payload variant.

### SceneStartNode

Role : point d'entree unique de la Scene.

Input ports : aucun.

Output ports : `default`.

Payload minimal :

- titre optionnel ;
- notes auteur optionnelles.

Payload interdit :

- event source map ;
- conditions d'activation ;
- action runtime ;
- mutations.

Diagnostics possibles :

- `missingStartNode`
- `multipleStartNodes`
- `missingRequiredOutput`

Runtime intent : `beginScene`.

Exemple utilisateur : "Debut de la rencontre rival".

Risques UX : l'utilisateur peut confondre Start avec l'Event qui declenche la scene.

### SceneEndNode

Role : terminer une branche de scene.

Input ports : `in`.

Output ports : aucun.

Payload minimal :

- `sceneOutcomeId` optionnel ;
- label de fin ;
- notes optionnelles.

Payload interdit :

- mutation cachee de Fact ;
- completion directe de StoryStep sans action explicite ;
- branche sortante.

Diagnostics possibles :

- `missingEndNode`
- `undeclaredOutcome`
- `unreachableNode`

Runtime intent : `endScene`, optionnellement `emitSceneOutcome`.

Exemple utilisateur : "Fin : rival battu".

Risques UX : transformer la fin en action fourre-tout.

### YarnDialogueNode

Role : ouvrir un dialogue Yarn, attendre sa fin et exposer ses outcomes attendus.

Input ports : `in`.

Output ports :

- `completed`
- `outcome:<id>`
- `invalid`

Payload minimal :

- `dialogueId`
- `startNodeId` ou `yarnNodeName`
- `expectedOutcomes`
- speaker hints optionnels

Payload interdit :

- texte Yarn complet inline ;
- mutation directe de StoryStep ;
- mutation directe de WorldRule ;
- flags techniques arbitraires ;
- recompenses gameplay.

Diagnostics possibles :

- `unknownDialogueRef`
- `undeclaredOutcome`
- `unhandledOutcome`
- `missingRequiredOutput`

Runtime intent :

- `openYarnDialogue`
- `waitForDialogueOutcome`

Exemple utilisateur : "Dialogue avec Mael".

Risques UX : faire croire que Yarn gere la progression globale.

### ConditionNode

Role : tester une condition auteur et brancher true/false.

Input ports : `in`.

Output ports :

- `true`
- `false`
- `invalid`

Payload minimal :

- `conditionDraft` ou `conditionRef`
- label humain
- future `compiledCondition`

Payload interdit :

- expression brute non validee ;
- metadata libre qui change la logique ;
- actions dans la condition.

Diagnostics possibles :

- `unknownConditionRef`
- `missingRequiredOutput`
- `metadataLogicSmell`

Runtime intent : `evaluateCondition`.

Exemple utilisateur : "Si le joueur a deja obtenu la cle".

Risques UX : exposer `flagIsSet` comme langage principal.

### ActionNode

Role : executer une action typee.

Input ports : `in`.

Output ports :

- `completed`
- `failed` si action peut echouer ;
- `invalid`

Payload minimal :

- `actionKind`
- parameters types
- label humain

Payload interdit :

- script brut non type par defaut ;
- blob JSON arbitraire ;
- mutation masquee de progression ;
- code runtime inline.

Diagnostics possibles :

- `unknownActionKind`
- `unknownNodeReference`
- `metadataLogicSmell`

Runtime intent : `runAction`.

Exemple utilisateur : "Donner une potion", "Activer un fait", "Deplacer un PNJ".

Risques UX : recreer une console de scripts au lieu d'un no-code guide.

### BattleNode

Role : lancer un combat et brancher selon son resultat.

Input ports : `in`.

Output ports :

- `victory`
- `defeat`
- `interrupted` futur ;
- `invalid`

Payload minimal :

- `battleKind`
- `trainerId` ou `battleTemplateId`
- `npcEntityId` optionnel
- declared outcomes battle locaux

Payload interdit :

- hardcode Selbrume ;
- combat complet inline ;
- logique interne battle engine ;
- recompenses cachees sans ActionNode.

Diagnostics possibles :

- `unknownBattleRef`
- `missingRequiredOutput`
- `unhandledOutcome`

Runtime intent : `startTrainerBattle`.

Exemple utilisateur : "Combat contre le rival".

Risques UX : confondre resultat de combat et SceneOutcome persistant.

### CinematicNode

Role : jouer une cinematic lineaire et continuer une fois terminee.

Input ports : `in`.

Output ports :

- `completed`
- `invalid`

Payload minimal :

- `cinematicId`
- expected completion

Payload interdit :

- branches internes ;
- graph complet de scene ;
- outcomes persistants caches ;
- conditions de progression.

Diagnostics possibles :

- `unknownCinematicRef`
- `missingRequiredOutput`

Runtime intent : `playCinematic`.

Exemple utilisateur : "Camera vers le phare".

Risques UX : reutiliser l'ancien Cutscene Studio branchant comme cinematic.

### BranchByOutcomeNode

Role : router explicitement selon un outcome deja produit par un node precedent ou un contexte declare.

Input ports : `in`.

Output ports :

- `outcome:<id>` pour chaque outcome declare ;
- `fallback` optionnel ;
- `invalid`

Payload minimal :

- `sourceNodeId` ou `sourceOutcomeSetRef`
- mapping outcomes -> ports
- fallback policy

Payload interdit :

- outcomes non declares ;
- mapping cache dans label ;
- branche implicite.

Diagnostics possibles :

- `undeclaredOutcome`
- `unhandledOutcome`
- `missingRequiredOutput`
- `invalidPortReference`

Runtime intent : `branchByOutcome`.

Exemple utilisateur : "Si Yarn retourne `panic`, jouer cinematic panic ; sinon continuer".

Risques UX : dupliquer le role de YarnDialogueNode si les outputs du dialogue suffisent.

### MergeNode

Decision : `MergeNode` est autorise mais non obligatoire.

Role : rendre explicite une convergence apres branches.

Input ports : `in:*`.

Output ports : `default`.

Payload minimal :

- label ;
- notes optionnelles.

Payload interdit :

- attente temporelle ;
- action runtime ;
- mutation.

Diagnostics possibles :

- `unreachableNode`
- `cycleWithoutExit`

Runtime intent : `merge`.

Exemple utilisateur : deux branches reviennent vers "Suite commune".

Risques UX : creer des nodes de merge partout par automatisme.

## 6. SceneEdge taxonomy

Principe absolu :

Une transition ne doit jamais etre implicite uniquement parce que deux nodes sont proches visuellement.

| Edge kind | Producteur autorise | Receveur autorise | Condition portee par edge ? | Notes |
|---|---|---|---|---|
| `default` | Start, Merge, generic completed nodes | Tout node sauf Start | non | Transition normale. |
| `conditionTrue` | ConditionNode | Tout node sauf Start | non | La condition vit dans le node. |
| `conditionFalse` | ConditionNode | Tout node sauf Start | non | Pair attendu de true. |
| `dialogueOutcome` | YarnDialogueNode | Tout node sauf Start | non | Edge lie a un port `outcome:<id>`. |
| `battleVictory` | BattleNode | Tout node sauf Start | non | Label de port/resultat battle. |
| `battleDefeat` | BattleNode | Tout node sauf Start | non | Ne pas inventer si runtime ne supporte pas. |
| `cinematicCompleted` | CinematicNode | Tout node sauf Start | non | Equivalent specialise de completed. |
| `actionCompleted` | ActionNode | Tout node sauf Start | non | Action terminee. |
| `branchOutcome` | BranchByOutcomeNode | Tout node sauf Start | non | Mapping explicit d'outcome. |
| `error` | Nodes pouvant echouer | Handler/End/diagnostic future | non en V1 | Peut rester diagnostic-only au debut. |
| `blocked` | Nodes pouvant bloquer | Handler/End/diagnostic future | non en V1 | Peut rester diagnostic-only au debut. |

Decision sur conditions :

- Les conditions doivent vivre dans ConditionNode.
- Les edges peuvent porter un label ou une reference de port, pas une expression logique complexe en V1.
- Une condition edge-level peut etre reconsideree plus tard, mais elle augmente le risque de branches invisibles.

Comment eviter les branches implicites :

- Chaque output requis doit avoir un port visible.
- Chaque edge doit referencer un port source valide.
- Le validator doit signaler output requis non relie.
- Le canvas ne doit pas inferer d'ordre par proximite.

## 7. Scene ports / outputs

### YarnDialogueNode outputs

- `completed`
- `outcome:<id>`
- `invalid`

UI :

- Afficher les outcomes attendus comme ports nommes.
- Montrer les ports non relies avec badge warning/error selon criticite.
- Permettre un fallback explicite si le contrat V1 le permet.

### ConditionNode outputs

- `true`
- `false`
- `invalid`

UI :

- Ports true/false visibles.
- Libelle condition lisible dans le node.

### BattleNode outputs

- `victory`
- `defeat`
- `interrupted` futur
- `invalid`

UI :

- Victoire/defaite visibles comme sorties.
- Si le runtime ne supporte pas encore un port, le port doit etre disabled ou diagnostic.

### CinematicNode outputs

- `completed`
- `invalid`

UI :

- Sortie completed unique.
- Pas de ports de branches internes.

### ActionNode outputs

- `completed`
- `failed` si applicable
- `invalid`

UI :

- Action simple : completed seulement.
- Action risquee : failed visible si le runtime/contrat le supporte.

### Validator ports

Doit detecter :

- output non relie ;
- output requis manquant ;
- outcome inconnu ;
- edge incompatible ;
- branche jamais atteignable ;
- port reference inexistant ;
- node cible invalide ;
- cycle sans sortie.

## 8. Payload contracts par node

### SceneStartNode

Payload minimal :

```text
title
notes
```

Interdit :

```text
event source
condition runtime
actionKind
storyStep completion
```

### SceneEndNode

Payload minimal :

```text
endLabel
sceneOutcomeId optional
notes
```

Interdit :

```text
fact mutation cachee
world rule mutation cachee
dialogue text
battle data
```

### YarnDialogueNode

Payload minimal :

```text
dialogueId
startNodeId ou yarnNodeName
expectedOutcomes
speakerHints optional
```

Interdit :

```text
texte Yarn complet inline
mutation directe de StoryStep
mutation directe de WorldRule
flags techniques arbitraires
```

### ConditionNode

Payload minimal :

```text
conditionDraft ou conditionRef
humanReadableLabel
compiledCondition future
```

Interdit :

```text
expression brute non validee
metadata libre qui change la logique
action runtime
```

### ActionNode

Payload minimal :

```text
actionKind
typedParameters
successOutput
failureOutput optional
```

Interdit :

```text
script brut non type par defaut
blob JSON arbitraire
mutation masquee de progression
```

### BattleNode

Payload minimal :

```text
battleKind
trainerId ou battleTemplateId
npcEntityId optional
declaredOutcomes
```

Interdit :

```text
hardcode Selbrume
combat complet inline
logique interne battle engine
```

### CinematicNode

Payload minimal :

```text
cinematicId
expectedCompletion
```

Interdit :

```text
branches internes
graph complet de scene
outcomes persistants caches
```

### BranchByOutcomeNode

Payload minimal :

```text
sourceNodeId ou sourceOutcomeSetRef
outcomeMappings
fallbackPolicy optional
```

Interdit :

```text
outcomes non declares
conditions cachees
mutation runtime
```

### MergeNode

Payload minimal :

```text
label
notes optional
```

Interdit :

```text
waitMs
actionKind
conditionDraft
```

## 9. Outcome model

### DialogueOutcome

Produit par Yarn. Local a l'interaction dialogue. Il peut influencer la Scene, mais ne doit pas persister la progression globale directement.

### BattleOutcome

Produit par le combat. Il represente victoire/defaite/autres resultats battle. Il peut etre transforme en SceneOutcome ou Fact via action explicite.

### SceneOutcome

Produit par la Scene. Il resume une issue de l'orchestration. Il n'est pas automatiquement persistant.

### EventOutcome

Resultat du declenchement Event/Scene a l'echelle runtime. Il peut etre utilise pour decider une consequence autour de l'Event.

### Fact

Etat du monde persistant, lisible par l'auteur. Exemple : "Le rival a ete battu au port". Un Fact peut etre pose par une action explicite.

### StoryStep completion

Progression narrative d'une Storyline. Elle ne doit pas etre confondue avec un outcome local. Elle sera liee a Scene plus tard, quand Scene V1 sera stable.

Regles :

- Un outcome local n'est pas forcement persistant.
- Un Fact est persistant.
- Un StoryStep est une progression narrative.
- Une Scene peut emettre un SceneOutcome.
- Un Event ou une action explicite peut decider de persister un Fact.
- Yarn ne doit pas devenir proprietaire de la progression globale.

## 10. Scene diagnostics

| Diagnostic | Gravite | Message utilisateur | Correction suggeree | Lot futur probable |
|---|---|---|---|---|
| `missingStartNode` | error | La scene n'a pas de debut. | Ajouter un node Debut. | V1-08 |
| `multipleStartNodes` | error | La scene a plusieurs debuts. | Garder un seul node Debut. | V1-08 |
| `missingEndNode` | error | La scene n'a pas de fin. | Ajouter au moins un node Fin. | V1-08 |
| `unreachableNode` | warning | Ce node n'est jamais atteint. | Relier le node depuis une sortie valide ou le supprimer. | V1-08 |
| `danglingEdge` | error | Un lien pointe vers une extremite absente. | Reconnecter ou supprimer le lien. | V1-08 |
| `unknownNodeReference` | error | Une reference de node est inconnue. | Choisir un node existant. | V1-08 |
| `invalidPortReference` | error | Une sortie referencee n'existe pas sur ce node. | Choisir une sortie valide. | V1-08 |
| `missingRequiredOutput` | error | Une sortie obligatoire n'est pas reliee. | Relier la sortie ou definir un fallback. | V1-08 |
| `unknownDialogueRef` | error | Le dialogue reference est introuvable. | Choisir un dialogue existant. | V1-06/V1-08 |
| `unknownCinematicRef` | error | La cinematic referencee est introuvable. | Choisir une cinematic existante ou laisser le node incomplet. | Cinematics V1 / V1-08 |
| `unknownBattleRef` | error | Le combat ou trainer reference est introuvable. | Choisir un trainer/battle valide. | V1-08 |
| `unknownActionKind` | error | Cette action n'est pas supportee. | Choisir une action supportee. | V1-07/V1-08 |
| `unknownConditionRef` | error | La condition referencee est introuvable ou invalide. | Corriger la condition. | V1-08 |
| `undeclaredOutcome` | error | Cet outcome n'est pas declare. | Declarer l'outcome ou le retirer. | V1-08 |
| `unhandledOutcome` | warning | Un outcome possible n'a pas de branche. | Ajouter un lien ou un fallback. | V1-08 |
| `cycleWithoutExit` | error | Une boucle ne peut pas atteindre une fin. | Ajouter une sortie vers un node Fin. | V1-08 |
| `metadataLogicSmell` | warning | De la logique semble cachee dans metadata. | Migrer vers payload type. | V1-02/V1-08 |
| `legacyScenarioLeak` | warning | Cette scene depend d'un contrat legacy non stabilise. | Adapter ou migrer selon decision V1-02. | V1-02/V1-09 |

## 11. Runtime intent model

Intentions runtime minimales :

```text
beginScene
openYarnDialogue
waitForDialogueOutcome
evaluateCondition
playCinematic
startTrainerBattle
runAction
branchByOutcome
merge
emitSceneOutcome
endScene
blockAsInvalid
```

Distinctions :

- Authoring graph : structure editee par l'auteur.
- Read model editor : projection optimisee pour UI, validation, selection et layout.
- Runtime executable model : representation stable, sans widgets, consommee par runtime.
- Runtime effects : dialogue, battle, action, transition, fact mutation, save, etc.

Regle :

- Le runtime ne depend jamais de widgets, positions de canvas ou design system.
- Le layout UI ne doit jamais changer la logique runtime.
- L'editor peut avoir un read model plus riche que le runtime.

## 12. UI implications from contract

Besoins UI futurs :

- Scene tree : liste/arborescence de scenes, status, diagnostics.
- Graph canvas : nodes/edges explicites, grille, selection.
- Node palette : Start, Yarn Dialogue, Condition, Branch, Battle, Cinematic, Action, End, Merge si autorise.
- Node inspector : payload type, refs, validation.
- Ports visibles : sorties nommees et connectables.
- Edge labels : outcome, true/false, victory/defeat, completed.
- Validation status : badges node/edge/scene.
- Mini-map : possible plus tard, pas obligatoire au premier graph.
- Zoom : necessaire a terme, pas dans le contrat produit de V1-01.
- Selected node details : tabs General / Conditions / Sorties / Notes.
- Empty states honnetes : aucune scene, scene sans node, node incomplet.
- Disabled states honnetes : actions visibles seulement si supportees.

Donnees que l'UI devra recevoir :

- Scene list summary.
- SceneGraph read model.
- Node kind, title, subtitle, ports.
- Edge kind, labels, source/target ports.
- Diagnostics par scene/node/edge.
- Authoring state derive.
- Layout positions editor si stockees ou derivees.

Interdits UI :

- Fallback "Annonce au port" hardcode.
- Selbrume hardcode.
- Boutons actifs sans mutation reelle.
- Scene fake quand aucune donnee n'existe.

## 13. Relation avec l'existant legacy

| Item | Position V1-01 | Recommandation |
|---|---|---|
| `ScenarioAsset` | Adaptable/wrappable, dangereux comme modele produit par defaut. | V1-02 doit trancher nouveau SceneAsset vs adapter. |
| `ScenarioNode` | Inspiration technique, trop generique. | Ne pas exposer tel quel dans l'UX Scene Builder. |
| `ScenarioEdge` | Inspiration technique. | Revoir port/source/target semantics. |
| `ScriptAsset` | Backend d'actions possible. | Ne pas faire de ScriptAsset l'UX principale. |
| `ScriptCommand` | Backend runtime. | Mapper depuis ActionNode type. |
| `ScriptCondition` | Backend condition possible. | Wrapper par condition authoring lisible. |
| `MapEventDefinition` | Base Event possible. | Event doit declencher Scene, pas devenir Scene. |
| Cutscene Studio | Inspiration UI/palette/compilation. | Dangereux car scene-like orchestration deja dans "cutscene". |
| Cutscene Runtime | Backend possible pour cinematic/action sequence. | A clarifier : Cinematic lineaire seulement. |
| `ScenarioRuntimeExecutor` | Bridge runtime utile. | Ne pas l'appeler contrat Scene V1 sans adapter. |

Sujet V1-02 :

- Decider la compat/migration avec `ProjectManifest.scenarios`.
- Decider si `ScenarioAsset` reste runtime executable intermediaire ou legacy side-by-side.

## 14. Questions ouvertes pour NS-SCENES-V1-02

- Creer un nouveau `SceneAsset` ou adapter `ScenarioAsset` ?
- Stocker scenes dans `ProjectManifest.scenes` ?
- Separer `SceneGraph` et `SceneGraphLayout` ?
- Quels IDs stables pour scene, graph, node, edge, port et outcome ?
- Comment migrer ou coexister avec `ProjectManifest.scenarios` ?
- Comment exporter l'API publique dans `map_core.dart` si nouveau modele ?
- Quelle strategie JSON et compat anciens projets ?
- Quel read model editor ?
- Quel modele runtime executable ?
- Quelle compatibilite avec Cutscene Studio ?
- Les cinematiques doivent-elles avoir un modele separe avant `CinematicNode` complet ?
- Les Facts doivent-ils etre definis avant ActionNode "set fact" ?
- Comment eviter une migration automatique destructive ?

## 15. Recommendation for next lot

Prochain lot attendu :

`NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision`

V1-02 devra faire :

- Decider si Scene V1 a un nouveau modele ou un adapter legacy.
- Decider le storage dans ou hors `ProjectManifest.scenes`.
- Decider la strategie d'IDs.
- Decider ou vit le layout.
- Decider les read models editor/runtime.
- Decider comment coexister avec `ProjectManifest.scenarios`.
- Documenter les migrations futures sans les coder si le lot reste design-only.

V1-02 ne doit pas faire a la place de V1-03+ :

- Creer un workspace UI complet.
- Brancher Storylines.
- Executer runtime Scene.
- Importer Selbrume scenes.

## 16. Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
4acf8c3f feat(storylines): add Selbrume storylines demo seed v0
b26ae424 docs(storylines): reorganize v1 screenshots and add checkpoint acceptance report
63a005e3 feat(storylines): add visual graph enrichment v1.12
db1bc6e3 docs(storylines): reorganize v1 screenshots and reports for side quest attachment
6554ad0f feat(storylines): add side quest attachment graph integration v0
```

### Commandes principales executees

```text
pwd; git branch --show-current; git status --short --untracked-files=all; git diff --stat; git log --oneline -n 10
python3 file existence check for mandatory files
python3 heading summaries for V1-00, roadmap, narrative_studio
python3 class/enum extraction for core models
python3 class/enum/constant extraction for runtime/editor legacy scene files
python3 roadmap line location check
```

### Fichiers inspectes

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
reports/narrativeStudio/scenes/road_map_scenes.md
MVP Selbrume/narrative_studio.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
```

### Fichiers absents

```text
Sortie : <vide>
```

### git status final exact

```text
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md
```

### git diff --stat final

```text
 reports/narrativeStudio/scenes/road_map_scenes.md | 25 ++++++++++++++++++++---
 1 file changed, 22 insertions(+), 3 deletions(-)
```

### git diff --name-only final

```text
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

### Contenu complet du rapport cree

Le present fichier est le rapport cree pour `NS-SCENES-V1-01`. Son contenu complet est constitue par toutes les sections de ce document.

### Diff complet de `road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 084f42d7..c168de48 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -37,7 +37,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | Lot | Statut | Objectif |
 |---|---|---|
 | NS-SCENES-V1-00 — Scene System Scope / Current State Audit | DONE | Audit documentaire de l'existant, definition Scene V1, frontieres produit et roadmap. |
-| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | TODO | Formaliser le contrat produit SceneGraph/SceneNode/SceneEdge, sans code model si le lot reste documentaire. |
+| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | DONE | Contrat produit Scene V1 formalise : definitions Scene/Graph/Node/Edge/Port/Outcome, taxonomie nodes/edges, payloads minimaux/interdits, diagnostics et runtime intents. |
 | NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | TODO | Decider ou stocker les Scenes, quels IDs, quels read models, et la strategie de migration/compat legacy. |
 | NS-SCENES-V1-03 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
 | NS-SCENES-V1-04 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles ou fixtures explicites, sans fake fallback. |
@@ -50,9 +50,28 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr

 ## Prochain lot recommande

-`NS-SCENES-V1-01 — Scene Product Model / Graph Contract`
+`NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision`

-Raison : avant de creer un modele, un widget ou une migration, il faut verrouiller le vocabulaire exact du graph Scene V1, les types de nodes, les transitions et ce qui reste hors scope.
+Raison : le contrat produit SceneGraph est pose ; le prochain blocage est maintenant de decider storage, IDs stables, layout, read model editor/runtime et coexistence avec `ProjectManifest.scenarios`.
+
+## Decisions V1-01
+
+- Scene V1 = graph d'orchestration, pas Storyline, Event, Cinematic, Yarn, Fact ou World Rule.
+- `YarnDialogueNode` est le node dialogue V1 unique ; pas de `DialogueNode` generique tant qu'un autre moteur n'existe pas.
+- Les transitions sont explicites : aucune logique ne vient de la proximite visuelle des nodes.
+- Les conditions restent portees par `ConditionNode`, pas par des expressions libres sur edges.
+- Les payloads doivent etre types ; `metadata` ne doit porter aucune logique critique.
+- Les positions de nodes sont necessaires a l'editor, mais le runtime ne doit pas dependre du layout.
+- Aucun modele Dart, storage, widget, runtime, fixture Selbrume ou sceneLink n'a ete cree.
+
+## Limites V1-01
+
+- Storage final non tranche.
+- `SceneAsset` non cree.
+- `ProjectManifest.scenes` non ajoute.
+- Compatibilite `ScenarioAsset` non tranchee.
+- Scene Builder UI non demarre.
+- StorylineStep -> Scene non branche.

 ## Dependances
```

### Tests / analyze

```text
Non executes : lot documentation-only, no-code, no-test-change. Aucun test/analyze requis.
```

### Auto-review critique

- Le contrat tranche fortement contre les transitions implicites et contre les payloads libres ; c'est volontaire pour proteger le futur Scene Builder.
- Le rapport ne choisit pas encore `SceneAsset` vs adapter `ScenarioAsset` ; cette abstention est necessaire car V1-02 porte precisement la decision storage/read model.
- Le choix `YarnDialogueNode` unique simplifie V1, mais devra etre reconsidere si PokeMap supporte plusieurs moteurs de dialogue.
- Le `MergeNode` reste autorise mais optionnel pour eviter une UX trop verbeuse.

### Regard critique sur le prompt

- Le prompt demande un contrat produit precis mais liste aussi des concepts proches du modele technique ; le rapport garde ces concepts comme contrat documentaire, pas comme classes Dart.
- Les edge kinds `dialogueOutcome` et `branchOutcome` peuvent sembler redondants ; ils sont gardes car l'un sort directement de Yarn, l'autre route un outcome deja disponible.
- La direction UI est utile, mais le lot ne doit pas specifier de pixel-perfect ni creer de fixture "Annonce au port".
